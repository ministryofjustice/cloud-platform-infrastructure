FROM golang:1.15-alpine AS cloud_platform_tester

ENV GO111MODULE=on \
    CGO_ENABLED=0 \
    GOOS=linux

WORKDIR /build
COPY go.mod .
COPY go.sum .
RUN go mod download
COPY . .
RUN cd e2e && go test -c -o test 
RUN pwd && ls

