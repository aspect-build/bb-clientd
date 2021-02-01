package fuse

import (
	"sort"

	remoteexecution "github.com/bazelbuild/remote-apis/build/bazel/remote/execution/v2"
	re_fuse "github.com/buildbarn/bb-remote-execution/pkg/filesystem/fuse"
	"github.com/buildbarn/bb-storage/pkg/digest"
	"github.com/buildbarn/bb-storage/pkg/filesystem/path"
	"github.com/buildbarn/bb-storage/pkg/util"
	"github.com/hanwen/go-fuse/v2/fuse"
)

// DirectoryContext contains all of the methods that the directory
// created by NewContentAddressableStorageDirectory uses to obtain its
// contents and instantiate inodes for its children.
type DirectoryContext interface {
	GetDirectoryContents() (*remoteexecution.Directory, fuse.Status)
	LogError(err error)

	// Get inode numbers of child directories. These numbers are
	// returned as part of directory listings generated by
	// FUSEReadDir().
	GetDirectoryInodeNumber(digest digest.Digest) uint64

	// Create child directories, in addition to returning their
	// inode numbers. These are performed as part of FUSELookup()
	// and FUSEReadDirPlus().
	LookupDirectory(digest digest.Digest, out *fuse.Attr) re_fuse.Directory

	// Same as the above, but for regular files.
	re_fuse.CASFileFactory
}

type contentAddressableStorageDirectory struct {
	readOnlyDirectory

	directoryContext DirectoryContext
	instanceName     digest.InstanceName
	inodeNumber      uint64
}

// NewContentAddressableStorageDirectory creates an immutable directory
// that is backed by a Directory message stored in the Content
// Addressable Storage (CAS). In order to load the Directory message and
// to instantiate inodes for any of its children, calls are made into a
// DirectoryContext object.
//
// TODO: Reimplement this on top of cas.DirectoryWalker.
func NewContentAddressableStorageDirectory(directoryContext DirectoryContext, instanceName digest.InstanceName, inodeNumber uint64) re_fuse.Directory {
	return &contentAddressableStorageDirectory{
		directoryContext: directoryContext,
		instanceName:     instanceName,
		inodeNumber:      inodeNumber,
	}
}

func (d *contentAddressableStorageDirectory) FUSEAccess(mask uint32) fuse.Status {
	if mask&^(fuse.R_OK|fuse.X_OK) != 0 {
		return fuse.EACCES
	}
	return fuse.OK
}

func (d *contentAddressableStorageDirectory) FUSEGetAttr(out *fuse.Attr) {
	out.Ino = d.inodeNumber
	out.Mode = fuse.S_IFDIR | 0555
	// This should be 2 + nDirectories, but that requires us to load
	// the directory. This is highly inefficient and error prone.
	out.Nlink = re_fuse.ImplicitDirectoryLinkCount
}

func (d *contentAddressableStorageDirectory) FUSELookup(name path.Component, out *fuse.Attr) (re_fuse.Directory, re_fuse.Leaf, fuse.Status) {
	directory, s := d.directoryContext.GetDirectoryContents()
	if s != fuse.OK {
		return nil, nil, s
	}

	// The Remote Execution protocol requires that entries stored in
	// a Directory message are sorted alphabetically. Make use of
	// this fact by performing binary searching when looking up
	// entries. There is no need to explicitly index the entries.
	n := name.String()
	directories := directory.Directories
	if i := sort.Search(len(directories), func(i int) bool { return directories[i].Name >= n }); i < len(directories) && directories[i].Name == n {
		entryDigest, err := d.instanceName.NewDigestFromProto(directories[i].Digest)
		if err != nil {
			d.directoryContext.LogError(util.StatusWrapf(err, "Failed to parse digest for directory %#v", n))
			return nil, nil, fuse.EIO
		}
		return d.directoryContext.LookupDirectory(entryDigest, out), nil, fuse.OK
	}

	files := directory.Files
	if i := sort.Search(len(files), func(i int) bool { return files[i].Name >= n }); i < len(files) && files[i].Name == n {
		entry := files[i]
		entryDigest, err := d.instanceName.NewDigestFromProto(entry.Digest)
		if err != nil {
			d.directoryContext.LogError(util.StatusWrapf(err, "Failed to parse digest for file %#v", n))
			return nil, nil, fuse.EIO
		}
		return nil, d.directoryContext.LookupFile(entryDigest, entry.IsExecutable, out), fuse.OK
	}

	symlinks := directory.Symlinks
	if i := sort.Search(len(symlinks), func(i int) bool { return symlinks[i].Name >= n }); i < len(symlinks) && symlinks[i].Name == n {
		f := re_fuse.NewSymlink(symlinks[i].Target)
		f.FUSEGetAttr(out)
		return nil, f, fuse.OK
	}

	return nil, nil, fuse.ENOENT
}

func (d *contentAddressableStorageDirectory) FUSEReadDir() ([]fuse.DirEntry, fuse.Status) {
	directory, s := d.directoryContext.GetDirectoryContents()
	if s != fuse.OK {
		return nil, s
	}

	entries := make([]fuse.DirEntry, 0, len(directory.Directories)+len(directory.Files)+len(directory.Symlinks))

	for _, entry := range directory.Directories {
		entryDigest, err := d.instanceName.NewDigestFromProto(entry.Digest)
		if err != nil {
			d.directoryContext.LogError(util.StatusWrapf(err, "Failed to parse digest for directory %#v", entry.Name))
			return nil, fuse.EIO
		}
		entries = append(entries, fuse.DirEntry{
			Mode: fuse.S_IFDIR,
			Ino:  d.directoryContext.GetDirectoryInodeNumber(entryDigest),
			Name: entry.Name,
		})
	}

	for _, entry := range directory.Files {
		entryDigest, err := d.instanceName.NewDigestFromProto(entry.Digest)
		if err != nil {
			d.directoryContext.LogError(util.StatusWrapf(err, "Failed to parse digest for file %#v", entry.Name))
			return nil, fuse.EIO
		}
		entries = append(entries, fuse.DirEntry{
			Mode: fuse.S_IFREG,
			Ino:  d.directoryContext.GetFileInodeNumber(entryDigest, entry.IsExecutable),
			Name: entry.Name,
		})
	}

	for _, entry := range directory.Symlinks {
		dirEntry := re_fuse.NewSymlink(entry.Target).FUSEGetDirEntry()
		dirEntry.Name = entry.Name
		entries = append(entries, dirEntry)
	}

	return entries, fuse.OK
}

func (d *contentAddressableStorageDirectory) FUSEReadDirPlus() ([]re_fuse.DirectoryDirEntry, []re_fuse.LeafDirEntry, fuse.Status) {
	directory, s := d.directoryContext.GetDirectoryContents()
	if s != fuse.OK {
		return nil, nil, s
	}

	directories := make([]re_fuse.DirectoryDirEntry, 0, len(directory.Directories))
	for _, entry := range directory.Directories {
		entryDigest, err := d.instanceName.NewDigestFromProto(entry.Digest)
		if err != nil {
			d.directoryContext.LogError(util.StatusWrapf(err, "Failed to parse digest for directory %#v", entry.Name))
			return nil, nil, fuse.EIO
		}
		var out fuse.Attr
		child := d.directoryContext.LookupDirectory(entryDigest, &out)
		directories = append(directories, re_fuse.DirectoryDirEntry{
			Child: child,
			DirEntry: fuse.DirEntry{
				Mode: fuse.S_IFDIR,
				Ino:  out.Ino,
				Name: entry.Name,
			},
		})
	}

	leaves := make([]re_fuse.LeafDirEntry, 0, len(directory.Files)+len(directory.Symlinks))
	for _, entry := range directory.Files {
		entryDigest, err := d.instanceName.NewDigestFromProto(entry.Digest)
		if err != nil {
			d.directoryContext.LogError(util.StatusWrapf(err, "Failed to parse digest for file %#v", entry.Name))
			return nil, nil, fuse.EIO
		}
		var out fuse.Attr
		child := d.directoryContext.LookupFile(entryDigest, entry.IsExecutable, &out)
		leaves = append(leaves, re_fuse.LeafDirEntry{
			Child: child,
			DirEntry: fuse.DirEntry{
				Mode: fuse.S_IFREG,
				Ino:  out.Ino,
				Name: entry.Name,
			},
		})
	}
	for _, entry := range directory.Symlinks {
		child := re_fuse.NewSymlink(entry.Target)
		dirEntry := child.FUSEGetDirEntry()
		dirEntry.Name = entry.Name
		leaves = append(leaves, re_fuse.LeafDirEntry{
			Child:    child,
			DirEntry: dirEntry,
		})
	}

	return directories, leaves, fuse.OK
}
