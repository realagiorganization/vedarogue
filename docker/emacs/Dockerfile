FROM debian:bookworm-slim
RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    emacs-nox ca-certificates \
    fonts-noto fonts-noto-cjk fonts-freefont-ttf \
 && rm -rf /var/lib/apt/lists/*
WORKDIR /work
ENTRYPOINT ["emacs"]
