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
  && wget https://amazon-eks.s3-us-west-2.amazonaws.com/1.14.6/2019-08-22/bin/linux/amd64/aws-iam-authenticator -O /usr/local/bin/aws-iam-authenticator \
  && chmod +x /usr/local/bin/kubectl /usr/local/bin/aws-iam-authenticator

RUN addgroup -g 1000 -S appgroup && \
    adduser -u 1000 -S appuser -G appgroup

WORKDIR /app

RUN gem install bundler

COPY Gemfile* ./
RUN bundle install
RUN bundle binstubs bundler --force --path /usr/local/bin
RUN bundle binstubs rspec-core --path /usr/local/bin

COPY . .

USER 1000

