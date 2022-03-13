FROM alpine:3.15.0

RUN apk add --update --no-cache bash jq python3 docker-cli git curl

COPY trigger.sh /usr/local/bin/trigger
COPY discover-descriptors.sh /usr/local/bin/discover-descriptors
COPY process-updates.sh /usr/local/bin/process-updates

