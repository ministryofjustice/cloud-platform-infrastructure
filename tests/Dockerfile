FROM golang:1.17-alpine AS builder

ENV CGO_ENABLED=0 \
    GOOS=linux \
    KUBECTL_VERSION=1.20.7

WORKDIR /build

RUN \
  apk add \
    --no-cache \
    --no-progress \
    --update \
    curl \
    unzip

COPY go.mod .
COPY go.sum .
RUN go mod download

COPY . .
RUN cd e2e && go test -c -o e2e-tests 

# Install kubectl
RUN curl -sLo ./kubectl https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl

RUN chmod +x kubectl

FROM alpine:3.14

ENV AWSCLI_VERSION=2.2.41
ENV GLIBC_VER=2.31-r0

RUN apk add --update --no-cache \
  groff \
  bash \
  ca-certificates \
  coreutils \
  findutils \
  git-crypt \
  git \
  gnupg \
  grep \
  openssl

# AWS cli installation taken from https://github.com/aws/aws-cli/issues/4685#issuecomment-941927371
RUN apk add --no-cache --virtual .dependencies binutils curl \
    && curl -sL https://alpine-pkgs.sgerrand.com/sgerrand.rsa.pub -o /etc/apk/keys/sgerrand.rsa.pub \
    && curl -sLO https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VER}/glibc-${GLIBC_VER}.apk \
    && curl -sLO https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VER}/glibc-bin-${GLIBC_VER}.apk \
    && curl -sLO https://github.com/sgerrand/alpine-pkg-glibc/releases/download/${GLIBC_VER}/glibc-i18n-${GLIBC_VER}.apk \
    && apk add --no-cache --virtual .glibc \
        glibc-${GLIBC_VER}.apk \
        glibc-bin-${GLIBC_VER}.apk \
        glibc-i18n-${GLIBC_VER}.apk \
    && /usr/glibc-compat/bin/localedef -i en_US -f UTF-8 en_US.UTF-8 \
    && curl -sL https://awscli.amazonaws.com/awscli-exe-linux-x86_64-${AWSCLI_VERSION}.zip -o awscliv2.zip \
    && unzip awscliv2.zip \
    && aws/install \
    && rm -rf \
        awscliv2.zip \
        aws \
        /usr/local/aws-cli/v2/*/dist/aws_completer \
        /usr/local/aws-cli/v2/*/dist/awscli/data/ac.index \
        /usr/local/aws-cli/v2/*/dist/awscli/examples \
        glibc-*.apk \
    && apk del --purge .dependencies

RUN addgroup -g 1000 -S appgroup && \
    adduser -u 1000 -S appuser -G appgroup

WORKDIR /tests

COPY --from=builder /build/e2e/e2e-tests /usr/bin/
COPY --from=builder /build/config /tests/
COPY --from=builder /build/kubectl /usr/local/bin/kubectl

USER 1000
