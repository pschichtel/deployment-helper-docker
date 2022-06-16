FROM gcr.io/kaniko-project/executor:v1.8.1-debug AS kaniko

FROM alpine:edge

ARG JIB_CLI_VERSION=0.10.0

RUN apk add --update --no-cache bash jq python3 docker-cli docker-compose git curl openssh vim tcpdump ca-certificates coreutils grep sed gettext socat openjdk17-jre-headless podman
RUN apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/testing kubectl helm

RUN curl -sSL -o jib.zip "https://github.com/GoogleContainerTools/jib/releases/download/v${JIB_CLI_VERSION}-cli/jib-jre-${JIB_CLI_VERSION}.zip" \
    && unzip jib.zip  \
    && rm jib.zip \
    && mv "jib-${JIB_CLI_VERSION}" /opt/jib \
    && ln -s /opt/jib/bin/jib /usr/local/bin/jib

COPY --from=kaniko /kaniko/executor /usr/local/bin/kaniko
COPY --from=kaniko /kaniko/warmer /usr/local/bin/warmer
COPY --from=kaniko /kaniko/docker-credential-* /usr/local/bin/

COPY trigger.sh /usr/local/bin/trigger
COPY discover-descriptors.sh /usr/local/bin/discover-descriptors
COPY process-updates.sh /usr/local/bin/process-updates
COPY json-to-env.sh /usr/local/bin/json-to-env
COPY combine-env.sh /usr/local/bin/combine-env
COPY offset-ports.sh /usr/local/bin/offset-ports
COPY content-hash.sh /usr/local/bin/content-hash
COPY replace-variable.sh /usr/local/bin/replace-variable

RUN mkdir /workspace
WORKDIR /workspace

RUN rm -Rf /var/spool

