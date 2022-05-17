FROM golang:1.18-alpine AS builder

WORKDIR /app

COPY go.mod ./
COPY go.sum ./
RUN go mod download

COPY *.go ./

RUN go build .

RUN addgroup -S kuberhealthy && adduser -S kuberhealthy -G kuberhealthy

# Build a small image
FROM scratch
COPY --from=builder /etc/passwd /etc/passwd
USER kuberhealthy
# https://github.com/aws/aws-sdk-go/issues/2322
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /app/namespace ./namespace

CMD ["./namespace"]
