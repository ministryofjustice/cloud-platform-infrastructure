FROM alpine:3.18.3

RUN addgroup -g 1000 -S appgroup && \
  adduser -u 1000 -S appuser -G appgroup

RUN apk --no-cache add curl

RUN apk --no-cache add jq

USER 1000

ENTRYPOINT [ "/bin/sh" ]

