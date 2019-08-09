FROM ruby:2.6.3-alpine

#Install pre-requisites for building unf_ext gem
RUN apk --update add --virtual build_deps \
    build-base ruby-dev libc-dev linux-headers

RUN addgroup -g 1000 -S appgroup && \
    adduser -u 1000 -S appuser -G appgroup

WORKDIR /app

COPY Gemfile Gemfile.lock ./

RUN bundle install --without development

COPY bin ./bin

USER 1000

CMD ["ruby", "./bin/iam_assume_role.rb"]
