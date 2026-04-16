FROM gcr.io/kaniko-project/executor:v1.24.0-debug@sha256:2562c4fe551399514277ffff7dcca9a3b1628c4ea38cb017d7286dc6ea52f4cd AS kaniko

FROM docker.io/library/alpine:3.23.4@sha256:5b10f432ef3da1b8d4c7eb6c487f2f5a8f096bc91145e68878dd4a5019afde11

ARG JIB_CLI_VERSION=0.13.0

RUN apk add --update --no-cache bash jq yq python3 docker-cli docker-compose git curl openssh vim tcpdump ca-certificates coreutils grep sed gettext socat openjdk17-jre-headless helm strace podman fuse-overlayfs tar zip moreutils
RUN apk add --no-cache -X http://dl-cdn.alpinelinux.org/alpine/edge/community kubectl

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
COPY git-credential-env.sh /usr/local/bin/git-credential-env

RUN git config --system credential.helper /usr/local/bin/git-credential-env

ENV STORAGE_DRIVER="vfs"

RUN adduser -S -h /workspace -u 1000 deploy \
 && echo "deploy:100000:65536" > /etc/subuid \
 && echo "deploy:100000:65536" > /etc/subgid

WORKDIR /workspace

