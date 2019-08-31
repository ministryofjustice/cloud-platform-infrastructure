FROM ruby:2.6.3-alpine

ENV KUBECTL_VERSION=1.11.10

RUN \
  apk add \
    --no-cache \
    --no-progress \
    --update \
    --virtual \
    build_deps \
    build-base \
    libc-dev \
    libxml2-dev \
    libxslt-dev \
    linux-headers \
    openssl \
    openssl-dev \
    python3 \
    ruby-dev \
  && pip3 install --upgrade pip \
  && pip3 install awscli \
  && wget https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl -O /usr/local/bin/kubectl \
  && chmod +x /usr/local/bin/kubectl

RUN addgroup -g 1000 -S appgroup && \
    adduser -u 1000 -S appuser -G appgroup

WORKDIR /app

COPY Gemfile* ./
RUN bundle install

COPY . .

USER 1000

