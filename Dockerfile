# FROM golang:alpine AS builder

# ENV CGO_ENABLED=0 \
#     GOOS=linux

# WORKDIR /build

# COPY . .

# RUN go mod download
# RUN cd ./test/e2e && go test -c -o cloud-platform-infra-test

# RUN apk update && apk add --no-cache --upgrade curl groff
# RUN rm /var/cache/apk/*

# RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
# RUN chmod 755 kubectl && mv kubectl /usr/bin/kubectl

# # ---------

# FROM ubuntu:latest AS aws

# ENV \
#   AWSCLI_BUNDLE_URL="https://s3.amazonaws.com/aws-cli" \
#   AWSCLI_BUNDLE_FILENAME="awscli-bundle"

# RUN apt-get update

# RUN apt-get -qq install -y \
#   curl \
#   python \
#   unzip

# WORKDIR /tmp

# RUN curl -O "${AWSCLI_BUNDLE_URL}/${AWSCLI_BUNDLE_FILENAME}.zip"

# # ---------

# FROM alpine

# WORKDIR /app
# RUN addgroup -g 1000 -S appgroup && \
#     adduser -u 1000 -S appuser -G appgroup

# # Testing tools
# COPY --from=builder /build/test/e2e/cloud-platform-infra-test /usr/bin/
# COPY --from=builder /build/test/config /app/

# # Tools to interact with cloud-platform infrastructure
# COPY --from=aws /usr/local/aws /usr/local/aws/
# COPY --from=aws /usr/local/bin/aws /usr/local/bin/
# COPY --from=builder /usr/bin/kubectl /usr/local/bin/kubectl

# COPY --from=ministryofjustice/cloud-platform-cli:1.12.6 /usr/local/bin/cloud-platform /usr/local/bin/cloud-platform

# COPY --from=hashicorp/terraform:0.14.8 /bin/terraform /usr/local/bin/terraform

# USER 1000


FROM golang:alpine AS builder

ENV CGO_ENABLED=0 \
    GOOS=linux

WORKDIR /build
COPY . .
COPY go.sum .
RUN go mod download

COPY . .
RUN cd ./test/e2e && go test -c -o ./test/e2e-tests

FROM python:3-alpine3.13 AS installer

ENV AWSCLI_VERSION=2.2.0

RUN apk add --no-cache \
    gcc \
    git \
    libc-dev \
    libffi-dev \
    openssl-dev \
    py3-pip \
    zlib-dev \
    make \
    cmake

RUN git clone --recursive  --depth 1 --branch ${AWSCLI_VERSION} --single-branch https://github.com/aws/aws-cli.git

WORKDIR /aws-cli

# Follow https://github.com/six8/pyinstaller-alpine to install pyinstaller on alpine
RUN pip install --no-cache-dir --upgrade pip \
    && pip install --no-cache-dir pycrypto \
    && git clone --depth 1 --single-branch --branch v$(grep PyInstaller requirements-build.txt | cut -d'=' -f3) https://github.com/pyinstaller/pyinstaller.git /tmp/pyinstaller \
    && cd /tmp/pyinstaller/bootloader \
    && CFLAGS="-Wno-stringop-overflow -Wno-stringop-truncation" python ./waf configure --no-lsb all \
    && pip install .. \
    && rm -Rf /tmp/pyinstaller \
    && cd - \
    && boto_ver=$(grep botocore setup.cfg | cut -d'=' -f3) \
    && git clone --single-branch --branch v2 https://github.com/boto/botocore /tmp/botocore \
    && cd /tmp/botocore \
    && git checkout $(git log --grep $boto_ver --pretty=format:"%h") \
    && pip install . \
    && rm -Rf /tmp/botocore  \
    && cd -

RUN sed -i '/botocore/d' requirements.txt \
    && scripts/installers/make-exe

RUN unzip dist/awscli-exe.zip \
    && ./aws/install --bin-dir /aws-cli-bin

FROM alpine:3.13

RUN apk update && apk add --no-cache --upgrade curl groff
RUN rm /var/cache/apk/*

RUN curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
RUN chmod 755 kubectl && mv kubectl /bin/kubectl

RUN addgroup -g 1000 -S appgroup && \
    adduser -u 1000 -S appuser -G appgroup

WORKDIR /tests

COPY --from=builder /build/e2e/e2e-tests /usr/bin/
COPY --from=builder /build/config /tests/

COPY --from=installer /usr/local/aws-cli/ /usr/local/aws-cli/
COPY --from=installer /aws-cli-bin/ /usr/local/bin/

USER 1000
