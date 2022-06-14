FROM golang:1.18-alpine AS builder

WORKDIR /app

RUN addgroup -S kuberhealthy && adduser -S kuberhealthy -G kuberhealthy

COPY go.mod ./
COPY go.sum ./
RUN go mod download

COPY *.go ./

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build .

# Build a small image
FROM scratch

COPY --from=builder /etc/passwd /etc/passwd
# https://github.com/aws/aws-sdk-go/issues/2322
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /app/namespace /app/namespace

USER kuberhealthy

CMD ["/app/namespace"]
