# Minimal kubectl + curl image based on Alpine latest
# Build example:
#   docker build -t yourrepo/kubectl_with_curl:latest .
#   docker run --rm yourrepo/kubectl_with_curl:latest kubectl version --client

FROM alpine:latest

ARG KUBECTL_VERSION=stable
ARG TARGETARCH
ENV TARGETARCH=${TARGETARCH:-amd64}

# Install dependencies
RUN apk add --no-cache curl ca-certificates bash && update-ca-certificates

# Install kubectl (with checksum verification)
RUN set -eux; \
    if [ "$KUBECTL_VERSION" = "stable" ]; then \
      KUBECTL_VERSION="$(curl -sSL https://dl.k8s.io/release/stable.txt)"; \
    fi; \
    echo "Installing kubectl ${KUBECTL_VERSION} for arch ${TARGETARCH}"; \
    curl -sSL -o /usr/local/bin/kubectl "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${TARGETARCH}/kubectl"; \
    curl -sSL -o /tmp/kubectl.sha256 "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/${TARGETARCH}/kubectl.sha256"; \
    echo "$(cat /tmp/kubectl.sha256)  /usr/local/bin/kubectl" | sha256sum -c -; \
    chmod +x /usr/local/bin/kubectl; \
    rm -f /tmp/kubectl.sha256; \
    # sanity check
    kubectl version --client=true --output=yaml || true

# Create non-root user
RUN adduser -D -u 10001 app && \
    mkdir -p /home/app && chown -R app:app /home/app

USER app
WORKDIR /home/app

ENTRYPOINT ["kubectl"]
CMD ["version", "--client=true"]
