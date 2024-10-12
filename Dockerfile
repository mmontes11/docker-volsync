ARG VERSION
FROM docker.io/library/golang:1.23-alpine as volsync
ARG VERSION
ARG TARGETOS
ARG TARGETARCH
ARG TARGETVARIANT=""
ARG TARGETPLATFORM
ENV CGO_ENABLED=0 \
  GOOS=${TARGETOS} \
  GOARCH=${TARGETARCH} \
  GOARM=${TARGETVARIANT}
RUN go install -a -ldflags "-X=main.volsyncVersion=${VERSION}" github.com/backube/volsync@${VERSION}

FROM docker.io/library/alpine:3.20.3
ARG TARGETPLATFORM
ARG VERSION
ARG CHANNEL

RUN apk add --no-cache \
  acl \
  bash \
  ca-certificates \
  curl \
  coreutils \
  tzdata \
  rsync \
  stunnel \
  && echo "Packages installed successfully" \
  && curl -fsSL "https://github.com/backube/volsync/archive/refs/tags/${VERSION}.tar.gz" -o /tmp/volsync.tar.gz \
  && echo "Downloaded VolSync version ${VERSION}" \
  && tar xzf /tmp/volsync.tar.gz -C /tmp --strip-components=1 \
  && echo "Extracted VolSync files" \
  && mkdir -p /mover-rsync-tls \
  && cp /tmp/mover-rsync-tls/*.sh /mover-rsync-tls/ || echo "Failed to copy rsync scripts" \
  && chmod a+rx /mover-rsync-tls/*.sh || echo "Failed to chmod rsync scripts" \
  && mkdir -p /mover-rclone \
  && cp /tmp/mover-rclone/active.sh /mover-rclone/ || echo "Failed to copy rclone scripts" \
  && chmod a+rx /mover-rclone/*.sh || echo "Failed to chmod rclone scripts" \
  && mkdir -p /mover-restic \
  && cp /tmp/mover-restic/entry.sh /mover-restic/ || echo "Failed to copy restic scripts" \
  && chmod a+rx /mover-restic/*.sh || echo "Failed to chmod restic scripts" \
  && rm -rf /tmp/*

COPY --from=docker.io/rclone/rclone:1.68.1 /usr/local/bin/rclone /usr/local/bin/rclone
COPY --from=docker.io/restic/restic:0.17.1 /usr/bin/restic /usr/local/bin/restic
COPY --from=volsync /go/bin/volsync /manager

ENTRYPOINT ["/bin/bash"]

LABEL org.opencontainers.image.source="https://github.com/backube/volsync"
