### simple Dockerfile to build the ext-dns image dwdraju/alpine-curl-jq
ARG DOCKER_BASE_IMAGE=dwdraju/alpine-curl-jq:latest
FROM ${DOCKER_BASE_IMAGE}
## copy dns-*.sh files to /opt
COPY dns-*.sh /opt/
RUN chmod +x /opt/dns-*.sh
WORKDIR /opt
ENTRYPOINT ["/opt/dns-entrypoint.sh"]
