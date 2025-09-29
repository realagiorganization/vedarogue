FROM debian:bookworm-slim
RUN apt-get update \
 && DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
    latexmk texlive-xetex texlive-latex-recommended texlive-fonts-recommended \
    texlive-lang-english texlive-lang-indic texlive-plain-generic \
    fonts-noto fonts-noto-cjk fonts-freefont-ttf \
 && rm -rf /var/lib/apt/lists/*
WORKDIR /work
ENTRYPOINT ["bash","-lc"]
