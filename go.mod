module github.com/buildbarn/bb-clientd

go 1.19

// Use the same version as in bb-storage.
replace github.com/golang/mock => github.com/golang/mock v1.6.1-0.20220512030613-73266f9366fc

// Use the same version as in bb-storage.
replace github.com/gordonklaus/ineffassign => github.com/gordonklaus/ineffassign v0.0.0-20201223204552-cba2d2a1d5d9

require (
	github.com/bazelbuild/remote-apis v0.0.0-20221109204407-3a21deee813d
	github.com/buildbarn/bb-remote-execution v0.0.0-20221206100151-9b36fad294bc
	github.com/buildbarn/bb-storage v0.0.0-20221206152342-f247e5488819
	github.com/golang/mock v1.6.0
	github.com/stretchr/testify v1.8.0
	golang.org/x/sync v0.1.0
	google.golang.org/genproto v0.0.0-20230110181048-76db0878b65f
	google.golang.org/grpc v1.53.0
	google.golang.org/protobuf v1.28.1
)

require (
	cloud.google.com/go/compute v1.15.1 // indirect
	cloud.google.com/go/compute/metadata v0.2.3 // indirect
	cloud.google.com/go/longrunning v0.3.0 // indirect
	github.com/aws/aws-sdk-go-v2 v1.17.1 // indirect
	github.com/aws/aws-sdk-go-v2/aws/protocol/eventstream v1.4.9 // indirect
	github.com/aws/aws-sdk-go-v2/config v1.17.10 // indirect
	github.com/aws/aws-sdk-go-v2/credentials v1.12.23 // indirect
	github.com/aws/aws-sdk-go-v2/feature/ec2/imds v1.12.19 // indirect
	github.com/aws/aws-sdk-go-v2/internal/configsources v1.1.25 // indirect
	github.com/aws/aws-sdk-go-v2/internal/endpoints/v2 v2.4.19 // indirect
	github.com/aws/aws-sdk-go-v2/internal/ini v1.3.26 // indirect
	github.com/aws/aws-sdk-go-v2/internal/v4a v1.0.16 // indirect
	github.com/aws/aws-sdk-go-v2/service/internal/accept-encoding v1.9.10 // indirect
	github.com/aws/aws-sdk-go-v2/service/internal/checksum v1.1.20 // indirect
	github.com/aws/aws-sdk-go-v2/service/internal/presigned-url v1.9.19 // indirect
	github.com/aws/aws-sdk-go-v2/service/internal/s3shared v1.13.19 // indirect
	github.com/aws/aws-sdk-go-v2/service/s3 v1.29.1 // indirect
	github.com/aws/aws-sdk-go-v2/service/sso v1.11.25 // indirect
	github.com/aws/aws-sdk-go-v2/service/ssooidc v1.13.8 // indirect
	github.com/aws/aws-sdk-go-v2/service/sts v1.17.1 // indirect
	github.com/aws/smithy-go v1.13.4 // indirect
	github.com/beorn7/perks v1.0.1 // indirect
	github.com/buildbarn/go-xdr v0.0.0-20220927161301-4c5a02fc5078 // indirect
	github.com/cespare/xxhash/v2 v2.2.0 // indirect
	github.com/davecgh/go-spew v1.1.1 // indirect
	github.com/dgryski/go-rendezvous v0.0.0-20200823014737-9f7001d12a5f // indirect
	github.com/go-logr/logr v1.2.3 // indirect
	github.com/go-logr/stdr v1.2.2 // indirect
	github.com/go-redis/redis/extra/rediscmd v0.2.0 // indirect
	github.com/go-redis/redis/extra/redisotel v0.3.0 // indirect
	github.com/go-redis/redis/v8 v8.11.5 // indirect
	github.com/golang/protobuf v1.5.2 // indirect
	github.com/google/go-jsonnet v0.19.1 // indirect
	github.com/google/uuid v1.3.0 // indirect
	github.com/gorilla/mux v1.8.0 // indirect
	github.com/grpc-ecosystem/go-grpc-middleware v1.3.0 // indirect
	github.com/grpc-ecosystem/go-grpc-prometheus v1.2.0 // indirect
	github.com/grpc-ecosystem/grpc-gateway/v2 v2.13.0 // indirect
	github.com/hanwen/go-fuse/v2 v2.1.0 // indirect
	github.com/jmespath/go-jmespath v0.4.0 // indirect
	github.com/kballard/go-shellquote v0.0.0-20180428030007-95032a82bc51 // indirect
	github.com/klauspost/compress v1.15.12 // indirect
	github.com/lazybeaver/xorshift v0.0.0-20170702203709-ce511d4823dd // indirect
	github.com/matttproud/golang_protobuf_extensions v1.0.4 // indirect
	github.com/pmezard/go-difflib v1.0.0 // indirect
	github.com/prometheus/client_golang v1.13.1 // indirect
	github.com/prometheus/client_model v0.3.0 // indirect
	github.com/prometheus/common v0.37.0 // indirect
	github.com/prometheus/procfs v0.8.0 // indirect
	go.opentelemetry.io/contrib/instrumentation/google.golang.org/grpc/otelgrpc v0.36.4 // indirect
	go.opentelemetry.io/contrib/propagators/b3 v1.11.1 // indirect
	go.opentelemetry.io/otel v1.11.1 // indirect
	go.opentelemetry.io/otel/exporters/jaeger v1.11.1 // indirect
	go.opentelemetry.io/otel/exporters/otlp/otlptrace v1.11.1 // indirect
	go.opentelemetry.io/otel/sdk v1.11.1 // indirect
	go.opentelemetry.io/otel/trace v1.11.1 // indirect
	go.opentelemetry.io/proto/otlp v0.19.0 // indirect
	golang.org/x/net v0.5.0 // indirect
	golang.org/x/oauth2 v0.4.0 // indirect
	golang.org/x/sys v0.4.0 // indirect
	golang.org/x/text v0.6.0 // indirect
	google.golang.org/appengine v1.6.7 // indirect
	gopkg.in/yaml.v2 v2.4.0 // indirect
	gopkg.in/yaml.v3 v3.0.1 // indirect
	sigs.k8s.io/yaml v1.3.0 // indirect
)
