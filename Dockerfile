FROM amazonlinux:2023 as build

RUN mkdir -p /var/tmp/workdir
WORKDIR /var/tmp/workdir

# install utils
RUN yum install -y rsync git jq tar zip unzip findutils binutils xz wget

# install latest go
RUN curl -LO https://go.dev/dl/go1.23.4.linux-amd64.tar.gz
RUN rm -rf /usr/local/go
RUN tar -C /usr/local -xzf go1.23.4.linux-amd64.tar.gz

ENV PATH="/usr/local/go/bin:${PATH}"
RUN go env -w GOPROXY=direct

# install latest protoc
RUN curl -LO https://github.com/protocolbuffers/protobuf/releases/download/v29.1/protoc-29.1-linux-x86_64.zip
RUN unzip protoc-29.1-linux-x86_64.zip -d /usr/local
RUN chmod 755 /usr/local/bin/protoc
RUN find /usr/local/include -type d -exec chmod 755 {} \;
RUN find /usr/local/include -type f -exec chmod 644 {} \;

# install latest protoc-gen-go, protoc-gen-go-grpc, protoc-gen-openapiv2, and go-swagger
RUN go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.35.2
RUN go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@latest
RUN go install github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-openapiv2@v2.24.0
RUN mv /root/go/bin/protoc-gen-go-grpc /usr/local/bin
RUN mv /root/go/bin/protoc-gen-go /usr/local/bin
RUN mv /root/go/bin/protoc-gen-openapiv2 /usr/local/bin
RUN go install github.com/go-swagger/go-swagger/cmd/swagger@v0.30.5
RUN mv /root/go/bin/swagger /usr/local/bin

# install ghr & gotestsum
RUN go install github.com/tcnksm/ghr@latest
RUN go install gotest.tools/gotestsum@latest
RUN mv /root/go/bin/gotestsum /usr/local/bin
RUN mv /root/go/bin/ghr /usr/local/bin

# install nodejs
RUN wget https://nodejs.org/dist/v22.12.0/node-v22.12.0-linux-x64.tar.xz
RUN tar -Jxvf node-v22.12.0-linux-x64.tar.xz
RUN mv node-v22.12.0-linux-x64 /usr/local/nodejs

ENV PATH="/usr/local/nodejs/bin:${PATH}"

# install ionic project deps
RUN npm install -g @ionic/cli
RUN npm install -g react-scripts

# install grpc-tools
RUN npm install -g grpc-tools

# copy bopmatic examples
RUN wget https://github.com/bopmatic/examples/archive/refs/tags/v0.17.1.tar.gz
RUN tar -zxvf v0.17.1.tar.gz
RUN mkdir /bopmatic
RUN mv examples-0.17.1 /bopmatic/examples
#COPY examples /bopmatic/examples

# set ENV vars
ENV GO111MODULE=on
ENV GOFLAGS=-mod=vendor

# sanity checks
RUN go version
RUN protoc --version
RUN node --version
RUN ionic --version
RUN ls /bopmatic/examples/golang

# set these because when the go binary is run under a UID that doesn't exist in
# /etc/passwd it will try to write at the root instead
ENV GOPATH=/var/tmp/gopath
ENV GOCACHE=/var/tmp/gocache
ENV GOMODCACHE=/var/tmp/gomodcache
ENV PATH="${GOPATH}/bin:${PATH}"

# clear parent entrypoint
ENTRYPOINT []

CMD /bin/bash

FROM amazonlinux:2023

RUN yum install --allowerasing -y rsync git jq tar zip unzip findutils binutils make xz java java-devel which python3 pip gcc hostname docker gnupg2-full
RUN pip install grpcio grpcio-tools pyinstaller

COPY --from=build /usr/local/go /usr/local/go
COPY --from=build /usr/local/nodejs /usr/local/nodejs
COPY --from=build /usr/local/bin /usr/local/bin
COPY --from=build /usr/local/include /usr/local/include
COPY --from=build /bopmatic /bopmatic

ENV GOPATH=/var/tmp/gopath
ENV GOCACHE=/var/tmp/gocache
ENV GOMODCACHE=/var/tmp/gomodcache
ENV PATH="${GOPATH}/bin:/usr/local/go/bin:/usr/local/nodejs/bin:${PATH}"
ENV GO111MODULE=on
ENV GOFLAGS=-mod=vendor

ENTRYPOINT []
CMD /bin/bash
