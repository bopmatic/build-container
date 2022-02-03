FROM public.ecr.aws/lambda/go:latest
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

# install latest protoc-gen-go & protoc-gen-go-grpc
RUN go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.26
RUN go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.1

# install latest aws cli
RUN curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
RUN unzip awscliv2.zip
RUN ./aws/install

# install latest pulumi cli
RUN curl -LO https://get.pulumi.com/releases/sdk/pulumi-v3.23.2-linux-x64.tar.gz
RUN tar -zxvf pulumi-v3.23.2-linux-x64.tar.gz
RUN mv pulumi /usr/local

# copy bopmatic examples
RUN mkdir /bopmatic
RUN git clone https://github.com/bopmatic/examples.git
RUN mv examples /bopmatic

# cleanup install artifacts
RUN rm go1.17.6.linux-amd64.tar.gz
RUN rm protoc-3.15.8-linux-x86_64.zip
RUN rm -rf ./aws awscliv2.zip
RUN rm pulumi-v3.23.2-linux-x64.tar.gz

# set ENV vars
ENV PATH="/root/go/bin:/usr/local/pulumi:${PATH}"
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
COPY go.mod ./go.mod
COPY pb ./pb
RUN protoc -I ./ --go_out ./ --go_opt paths=source_relative --go-grpc_out ./ --go-grpc_opt paths=source_relative ./pb/stub.proto
RUN go mod vendor
RUN go build
RUN mkdir /bopmatic/cachedeps
RUN mv vendor go.mod go.sum /bopmatic/cachedeps

# remove stub code
RUN rm main.go
RUN rm -f lambdastub.bopmatic.com
RUN rm -rf pb

# clear parent entrypoint
ENTRYPOINT []

CMD /bin/bash
