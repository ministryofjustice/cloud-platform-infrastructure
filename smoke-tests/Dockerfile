FROM ruby:2.6.3-alpine

RUN apk --update add --virtual build_deps \
    build-base ruby-dev libc-dev linux-headers \
    openssl-dev libxml2-dev libxslt-dev

RUN addgroup -g 1000 -S appgroup && \
    adduser -u 1000 -S appuser -G appgroup

WORKDIR /app

COPY Gemfile* ./
RUN bundle install

ENV KUBECTL_VERSION=1.11.10

RUN wget https://storage.googleapis.com/kubernetes-release/release/v${KUBECTL_VERSION}/bin/linux/amd64/kubectl -O /usr/local/bin/kubectl
RUN chmod +x /usr/local/bin/kubectl

COPY . .

USER 1000

