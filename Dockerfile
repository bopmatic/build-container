FROM public.ecr.aws/lambda/go:latest as build
#FROM public.ecr.aws/amazonlinux/amazonlinux:latest
#FROM public.ecr.aws/lambda/provided:al2

# install utils
RUN yum install -y rsync git jq tar zip unzip

# install latest go
RUN curl -LO https://go.dev/dl/go1.17.6.linux-amd64.tar.gz
RUN rm -rf /usr/local/go
RUN tar -C /usr/local -xzf go1.17.6.linux-amd64.tar.gz

ENV PATH="/usr/local/go/bin:${PATH}"
RUN go env -w GOPROXY=direct

# install latest protoc
RUN curl -LO https://github.com/protocolbuffers/protobuf/releases/download/v3.15.8/protoc-3.15.8-linux-x86_64.zip
RUN unzip protoc-3.15.8-linux-x86_64.zip -d /usr/local
RUN chmod 755 /usr/local/bin/protoc
RUN find /usr/local/include -type d -exec chmod 755 {} \;
RUN find /usr/local/include -type f -exec chmod 644 {} \;

# install latest protoc-gen-go, protoc-gen-go-grpc, protoc-gen-openapiv2, and go-swagger
RUN go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.26
RUN go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.1
RUN go install github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-openapiv2@v2.7.3
RUN mv /root/go/bin/protoc-gen-go-grpc /usr/local/bin
RUN mv /root/go/bin/protoc-gen-go /usr/local/bin
RUN mv /root/go/bin/protoc-gen-openapiv2 /usr/local/bin
RUN go install github.com/go-swagger/go-swagger/cmd/swagger@v0.29.0
RUN mv /root/go/bin/swagger /usr/local/bin

# install latest aws cli
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
RUN unzip awscliv2.zip
RUN ./aws/install

# install latest pulumi cli
RUN curl -LO https://get.pulumi.com/releases/sdk/pulumi-v3.23.2-linux-x64.tar.gz
RUN tar -zxvf pulumi-v3.23.2-linux-x64.tar.gz
RUN mv pulumi /usr/local

# setup go directories
RUN mkdir -p /bopmatic/cachedeps

# copy bopmatic examples
RUN git clone https://github.com/bopmatic/examples.git
RUN mv examples /bopmatic

# cleanup install artifacts
RUN rm go1.17.6.linux-amd64.tar.gz
RUN rm protoc-3.15.8-linux-x86_64.zip
RUN rm -rf ./aws awscliv2.zip
RUN rm pulumi-v3.23.2-linux-x64.tar.gz
RUN rm /usr/local/readme.txt

# set ENV vars
ENV PATH="/usr/local/pulumi:${PATH}"
ENV GO111MODULE=on
ENV GOFLAGS=-mod=vendor

# sanity checks
RUN go version
RUN protoc --version
RUN aws --version
RUN pulumi version
RUN ls /bopmatic/examples

# cache module dependencies
COPY main.go ./main.go
COPY pb ./pb
RUN protoc -I ./ --go_out ./ --go_opt paths=source_relative --go-grpc_out ./ --go-grpc_opt paths=source_relative ./pb/stub.proto
RUN go mod init lambdastub.bopmatic.com
RUN go mod vendor
RUN go mod tidy
RUN go build
RUN mv vendor go.mod go.sum /bopmatic/cachedeps
RUN chmod -R u+r /bopmatic/cachedeps

# set these because when the go binary is run under a UID that doesn't exist in
# /etc/passwd it will try to write at the root instead
ENV GOPATH=/var/tmp/gopath
ENV GOCACHE=/var/tmp/gocache
ENV GOMODCACHE=/var/tmp/gomodcache
ENV PATH="${GOPATH}/bin:${PATH}"

# remove stub code
RUN rm main.go
RUN rm -f lambdastub.bopmatic.com
RUN rm -rf pb

# clear parent entrypoint
ENTRYPOINT []

CMD /bin/bash

FROM public.ecr.aws/lambda/provided:al2
RUN yum install -y rsync git jq tar zip unzip
COPY --from=build /usr/local/go /usr/local/go
COPY --from=build /usr/local/pulumi /usr/local/pulumi
COPY --from=build /usr/local/bin /usr/local/bin
COPY --from=build /usr/local/include /usr/local/include
COPY --from=build /bopmatic /bopmatic
COPY --from=build /usr/local/aws-cli /usr/local/aws-cli
ENV GOPATH=/var/tmp/gopath
ENV GOCACHE=/var/tmp/gocache
ENV GOMODCACHE=/var/tmp/gomodcache
ENV PATH="${GOPATH}/bin:/usr/local/pulumi:/usr/local/go/bin:${PATH}"
ENV GO111MODULE=on
ENV GOFLAGS=-mod=vendor
ENTRYPOINT []
CMD /bin/bash
