FROM gcr.io/kaniko-project/executor:debug AS kaniko

FROM alpine:edge

RUN apk add --update --no-cache bash jq python3 docker-cli docker-compose git curl openssh vim tcpdump ca-certificates coreutils grep sed
RUN apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/testing kubectl helm

COPY --from=kaniko /kaniko/executor /usr/local/bin/kaniko
COPY --from=kaniko /kaniko/warmer /usr/local/bin/warmer
COPY --from=kaniko /kaniko/docker-credential-* /usr/local/bin/

COPY trigger.sh /usr/local/bin/trigger
COPY discover-descriptors.sh /usr/local/bin/discover-descriptors
COPY process-updates.sh /usr/local/bin/process-updates
COPY json-to-env.sh /usr/local/bin/json-to-env
COPY combine-env.sh /usr/local/bin/combine-env
COPY offset-ports.sh /usr/local/bin/offset-ports

RUN mkdir /workspace
WORKDIR /workspace

