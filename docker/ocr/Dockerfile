FROM debian:bookworm-slim
RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    ocrmypdf tesseract-ocr tesseract-ocr-eng tesseract-ocr-san ghostscript \
 && rm -rf /var/lib/apt/lists/*
WORKDIR /work
ENTRYPOINT ["ocrmypdf"]
