#FROM amazonlinux:2023.1.20230719.0 as build
FROM amazonlinux:2.0.20240109.0 as build

RUN mkdir -p /var/tmp/workdir
WORKDIR /var/tmp/workdir

# install utils
#RUN yum install -y rsync git jq tar zip unzip findutils binutils xz wget
RUN yum install -y rsync git jq tar zip unzip amazon-linux-extras binutils xz wget

# install latest go
RUN curl -LO https://go.dev/dl/go1.20.6.linux-amd64.tar.gz
RUN rm -rf /usr/local/go
RUN tar -C /usr/local -xzf go1.20.6.linux-amd64.tar.gz

ENV PATH="/usr/local/go/bin:${PATH}"
RUN go env -w GOPROXY=direct

# install latest protoc
RUN curl -LO https://github.com/protocolbuffers/protobuf/releases/download/v23.4/protoc-23.4-linux-x86_64.zip
RUN unzip protoc-23.4-linux-x86_64.zip -d /usr/local
RUN chmod 755 /usr/local/bin/protoc
RUN find /usr/local/include -type d -exec chmod 755 {} \;
RUN find /usr/local/include -type f -exec chmod 644 {} \;

# install latest protoc-gen-go, protoc-gen-go-grpc, protoc-gen-openapiv2, and go-swagger
RUN go install google.golang.org/protobuf/cmd/protoc-gen-go@v1.31.0
RUN go install google.golang.org/grpc/cmd/protoc-gen-go-grpc@v1.3.0
RUN go install github.com/grpc-ecosystem/grpc-gateway/v2/protoc-gen-openapiv2@v2.16.2
RUN mv /root/go/bin/protoc-gen-go-grpc /usr/local/bin
RUN mv /root/go/bin/protoc-gen-go /usr/local/bin
RUN mv /root/go/bin/protoc-gen-openapiv2 /usr/local/bin
RUN go install github.com/go-swagger/go-swagger/cmd/swagger@v0.30.5
RUN mv /root/go/bin/swagger /usr/local/bin

# install ghr & gotestsum
RUN go install github.com/tcnksm/ghr@latest
RUN go install gotest.tools/gotestsum@v1.10.1
RUN mv /root/go/bin/gotestsum /usr/local/bin
RUN mv /root/go/bin/ghr /usr/local/bin

# install nodejs
#RUN wget https://nodejs.org/dist/v18.17.0/node-v18.17.0-linux-x64.tar.xz
#RUN tar -Jxvf node-v18.17.0-linux-x64.tar.xz
#RUN mv node-v18.17.0-linux-x64 /usr/local/nodejs
RUN wget https://nodejs.org/dist/v16.17.1/node-v16.17.1-linux-x64.tar.xz
RUN tar -Jxvf node-v16.17.1-linux-x64.tar.xz
RUN mv node-v16.17.1-linux-x64 /usr/local/nodejs

ENV PATH="/usr/local/nodejs/bin:${PATH}"

# install ionic project deps
RUN npm install -g @ionic/cli
RUN npm install -g react-scripts

# copy bopmatic examples
RUN wget https://github.com/bopmatic/examples/archive/refs/tags/v0.13.0.tar.gz
RUN tar -zxvf v0.13.0.tar.gz
RUN mkdir /bopmatic
RUN mv examples-0.13.0 /bopmatic/examples

# cleanup install artifacts
RUN rm go1.20.6.linux-amd64.tar.gz
RUN rm protoc-23.4-linux-x86_64.zip
RUN rm /usr/local/readme.txt

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

#FROM amazonlinux:2023.1.20230719.0
FROM amazonlinux:2.0.20240109.0

#RUN yum install -y rsync git jq tar zip unzip findutils binutils make xz java java-devel which python3 pip gcc hostname
RUN yum install -y rsync git jq tar zip unzip amazon-linux-extras binutils make xz java java-devel which python3 pip3 gcc hostname
#RUN yum install -y docker
RUN amazon-linux-extras install -y docker
#RUN pip install grpcio grpcio-tools pyinstaller
RUN pip3 install grpcio grpcio-tools pyinstaller

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
