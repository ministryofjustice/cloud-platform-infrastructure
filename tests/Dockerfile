FROM golang:1.15-alpine AS builder

ENV GO111MODULE=on \
    CGO_ENABLED=0 \
    GOOS=linux

WORKDIR /build
COPY go.mod .
COPY go.sum .
RUN go mod download

COPY . .
RUN cd e2e && go test -c -o e2e-tests 

FROM alpine:3.13

RUN apk update && apk add --no-cache --upgrade curl python3 py3-pip
RUN pip install awscli

RUN apk --purge -v del py-pip
RUN rm /var/cache/apk/*

RUN curl -LO https://storage.googleapis.com/kubernetes-release/release/v1.15.1/bin/linux/amd64/kubectl
RUN chmod 755 kubectl && mv kubectl /bin/kubectl

RUN addgroup -g 1000 -S appgroup && \
    adduser -u 1000 -S appuser -G appgroup

WORKDIR /tests

COPY --from=builder /build/e2e/e2e-tests /usr/bin/
COPY --from=builder /build/config /tests/

USER 1000
