local cluster_backend = 'remote-cache-9e85d2169ed596f9.elb.us-east-2.amazonaws.com';

local grpcClient(hostname, authorizationHeader, proxyURL) = {
  address: hostname + ':8980',
  [if authorizationHeader != null then 'addMetadata']: [
    { header: 'authorization', values: [authorizationHeader] },
  ],
  addMetadataJmespathExpression: '{"build.bazel.remote.execution.v2.requestmetadata-bin": incomingGRPCMetadata."build.bazel.remote.execution.v2.requestmetadata-bin"}',
  // Enable gRPC keepalives. Make sure to tune these settings based on
  // what your cluster permits.
  keepalive: {
    time: '60s',
    timeout: '30s',
  },
  proxyUrl: proxyURL,
};

local homeDirectory = std.extVar('HOME');
local cacheDirectory = homeDirectory + '/.cache/bb_clientd';

{
  // Options that users can override.
  casKeyLocationMapSizeBytes:: 512 * 1024 * 1024,
  casBlocksSizeBytes:: 100 * 1024 * 1024 * 1024,
  filePoolSizeBytes:: 100 * 1024 * 1024 * 1024,

  // Maximum supported Protobuf message size.
  maximumMessageSizeBytes: 16 * 1024 * 1024,
  maximumTreeSizeBytes: 256 * 1024 * 1024,

  // When set, don't forward credentials from Bazel to clusters and
  // office caches. Instead, use a static credentials in the form of a
  // HTTP "Authorization" header.
  authorizationHeader:: null,

  // HTTP proxy to use for all outgoing requests not going to office caches.
  proxyURL:: '',

  // If enabled, use NFSv4 instead of FUSE.
  useNFSv4:: std.extVar('OS') == 'Darwin',

  // Backends for the Action Cache and Content Addressable Storage.
  blobstore: {
    actionCache: {
      grpc: grpcClient(cluster_backend, $.authorizationHeader, $.proxyURL),
    },
    contentAddressableStorage: { withLabels: {
      backend: {
        readCaching: {
          slow: {
            existenceCaching: {
              backend: { label: 'clustersCAS' },
              // Assume that if FindMissingBlobs() reports a blob as being
              // present, it's going to stay around for five more minutes.
              // This significantly reduces the combined size of
              // FindMissingBlobs() calls generated by Bazel.
              existenceCache: {
                cacheSize: 1000 * 1000,
                cacheDuration: '300s',
                cacheReplacementPolicy: 'LEAST_RECENTLY_USED',
              },
            },
          },
          // On-disk cache to speed up access to recently used objects.
          fast: { label: 'localCAS' },
          replicator: {
            deduplicating: {
              // Bazel's -j flag not only affects the number of actions
              // executed concurrently, it also influences the concurrency
              // of ByteStream requests. Prevent starvation by limiting
              // the number of requests that are forwarded when cache
              // misses occur.
              concurrencyLimiting: {
                base: { 'local': {} },
                maximumConcurrency: 100,
              },
            },
          },
        },
      },
      labels: {
        // Let the local CAS consume up to 100 GiB of disk space. A 64
        // MiB index is large enough to accomodate approximately one
        // million objects.
        localCAS: { 'local': {
          keyLocationMapOnBlockDevice: { file: {
            path: cacheDirectory + '/cas/key_location_map',
            sizeBytes: $.casKeyLocationMapSizeBytes,
          } },
          keyLocationMapMaximumGetAttempts: 8,
          keyLocationMapMaximumPutAttempts: 32,
          oldBlocks: 1,
          currentBlocks: 5,
          newBlocks: 1,
          blocksOnBlockDevice: {
            source: { file: {
              path: cacheDirectory + '/cas/blocks',
              sizeBytes: $.casBlocksSizeBytes,
            } },
            spareBlocks: 1,
            dataIntegrityValidationCache: {
              cacheSize: 100000,
              cacheDuration: '14400s',
              cacheReplacementPolicy: 'LEAST_RECENTLY_USED',
            },
          },
          persistent: {
            stateDirectoryPath: cacheDirectory + '/cas/persistent_state',
            minimumEpochInterval: '300s',
          },
        } },
        clustersCAS: { grpc: grpcClient(cluster_backend, $.authorizationHeader, $.proxyURL) },
      },
    } },
  },

  // Schedulers to which to route execution requests. This uses the same
  // routing policy as the storage configuration above.
  schedulers: {
    '': { endpoint: grpcClient(cluster_backend, $.authorizationHeader, $.proxyURL) },
  },

  // A gRPC server to which Bazel can send requests, as opposed to
  // contacting clusters directly. This allows bb_clientd to capture
  // credentials.
  grpcServers: [{
    listenPaths: [cacheDirectory + '/grpc'],
    authenticationPolicy: { allow: {} },
  }],

  // The FUSE or NFSv4 file system through which data stored in the
  // Content Addressable Storage can be loaded lazily. This file system
  // relies on credentials captured through gRPC.
  mount: if $.useNFSv4 then {
    mountPath: homeDirectory + '/bb_clientd',
    nfsv4: {
      enforcedLeaseTime: '120s',
      announcedLeaseTime: '60s',
      darwin: {
        minimumDirectoriesAttributeCacheTimeout: '0s',
        maximumDirectoriesAttributeCacheTimeout: '0s',
      },
    },
  } else {
    mountPath: homeDirectory + '/bb_clientd',
    fuse: {
      directoryEntryValidity: '300s',
      inodeAttributeValidity: '300s',
      // Enabling this option may be necessary if you want to permit
      // super-user access to the FUSE file system. It is strongly
      // recommended that the permissions on the parent directory of the
      // FUSE file system are locked down before enabling this option.
      allowOther: true,
    },
  },

  // The location where locally created files in the "scratch" and
  // "outputs" directories of the FUSE file system are stored. These
  // files are not necessarily backed by remote storage.
  filePool: { blockDevice: { file: {
    path: cacheDirectory + '/filepool',
    sizeBytes: $.filePoolSizeBytes,
  } } },

  // The location where contents of the "outputs" are stored, so that
  // they may be restored after restarts of bb_clientd. Because data is
  // stored densely, and only the metadata of files is stored (i.e.,
  // REv2 digests), these files tend to be small.
  outputPathPersistency: {
    stateDirectoryPath: cacheDirectory + '/outputs',
    maximumStateFileSizeBytes: 1024 * 1024 * 1024,
    maximumStateFileAge: '604800s',
  },

  // Keep a small number of unmarshaled REv2 Directory objects in memory
  // to speed up their instantiation under "outputs".
  directoryCache: {
    maximumCount: 10000,
    maximumSizeBytes: 1024 * self.maximumCount,
    cacheReplacementPolicy: 'LEAST_RECENTLY_USED',
  },

  // Retry read operations performed through the virtual file system.
  // This prevents EIO errors in case of transient network issues.
  maximumFileSystemRetryDelay: '300s',

  global: {
    // Multiplex logs into a file. That way they remain accessible, even
    // if bb_clientd is run through a system that doesn't maintain logs
    // for us.
    logPaths: [cacheDirectory + '/log'],

    // Attach credentials provided by Bazel to all outgoing gRPC calls.
    [if $.authorizationHeader == null then 'grpcForwardAndReuseMetadata']: ['authorization'],

    // Optional: create a HTTP server that exposes Prometheus metrics
    // and allows debugging using pprof. Make sure to only enable it
    // when you need it, or at least make sure that access is limited.
    /*
    diagnosticsHttpServer: {
      listenAddress: '127.0.0.1:12345',
      enablePrometheus: true,
      enablePprof: true,
      enableActiveSpans: true,
    },
    */
  },
}
