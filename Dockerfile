FROM quay.io/containers/podman:latest AS upstream
FROM alpine:3.17.3

ARG JIB_CLI_VERSION=0.12.0

RUN apk add --update --no-cache bash jq python3 docker-cli docker-compose git curl openssh vim tcpdump ca-certificates coreutils grep sed gettext socat openjdk17-jre-headless podman fuse-overlayfs helm
RUN apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/testing kubectl

RUN curl -sSL -o jib.zip "https://github.com/GoogleContainerTools/jib/releases/download/v${JIB_CLI_VERSION}-cli/jib-jre-${JIB_CLI_VERSION}.zip" \
    && unzip jib.zip  \
    && rm jib.zip \
    && mv "jib-${JIB_CLI_VERSION}" /opt/jib \
    && ln -s /opt/jib/bin/jib /usr/local/bin/jib

COPY --from=upstream /etc/containers/storage.conf /etc/containers/storage.conf

COPY trigger.sh /usr/local/bin/trigger
COPY discover-descriptors.sh /usr/local/bin/discover-descriptors
COPY process-updates.sh /usr/local/bin/process-updates
COPY json-to-env.sh /usr/local/bin/json-to-env
COPY combine-env.sh /usr/local/bin/combine-env
COPY offset-ports.sh /usr/local/bin/offset-ports
COPY content-hash.sh /usr/local/bin/content-hash
COPY replace-variable.sh /usr/local/bin/replace-variable

RUN adduser -S -h /workspace -u 1000 deploy

WORKDIR /workspace

USER deploy

