# Fetch release artifacts with the existing toolchain's trusted CA bundle.
FROM pandoc/typst:3.9.0.2@sha256:8b88646589ec8aa05afdca02dbe6849fa38f3235fb23559970ba82088a5d8f75 AS downloads
ARG TARGETARCH
WORKDIR /artifacts
RUN set -eu; \
    case "$TARGETARCH" in \
      amd64) cpu=x86_64; pandoc_sha=ce4ac48f48aa7eadc1f5dbdf3449a1739f188ecb8c5421c5adc070fe7479e567; typst_sha=a6044cbad2a954deb921167e257e120ac0a16b20339ec01121194ff9d394996d ;; \
      arm64) cpu=aarch64; pandoc_sha=2e77b311be7d1c3b40b5475c6cd5bd44ba02d7d9683e3eecb3324baebf16e4d8; typst_sha=491b101aa40a3a7ea82a3f8a6232cabb4e6a7e233810082e5ac812d43fdcd47a ;; \
      *) exit 1 ;; \
    esac; \
    wget -qO pandoc.deb "https://github.com/jgm/pandoc/releases/download/3.9.0.2/pandoc-3.9.0.2-1-${TARGETARCH}.deb"; \
    wget -qO typst.tar.xz "https://github.com/typst/typst/releases/download/v0.14.2/typst-${cpu}-unknown-linux-musl.tar.xz"; \
    echo "$pandoc_sha  pandoc.deb" | sha256sum -c -; \
    echo "$typst_sha  typst.tar.xz" | sha256sum -c -; \
    tar -xf typst.tar.xz "typst-${cpu}-unknown-linux-musl/typst"; \
    mv "typst-${cpu}-unknown-linux-musl/typst" typst; \
    wget -qO pypdf.whl https://files.pythonhosted.org/packages/cd/f2/9c9429411c91ac1dd5cd66780f22b6df20c64c3646cdd1e6d67cf38579c4/pypdf-6.4.0-py3-none-any.whl; \
    echo '55ab9837ed97fd7fcc5c131d52fcc2223bc5c6b8a1488bbf7c0e27f1f0023a79  pypdf.whl' | sha256sum -c -; \
    mkdir wrap-it; \
    for f in typst.toml wrap-it.typ LICENSE README.md; do \
      wget -qO "wrap-it/$f" "https://raw.githubusercontent.com/typst/packages/5cc3aea920a51531fa0f038ac48cce6861f4c406/packages/preview/wrap-it/0.1.1/$f"; \
    done

RUN wget -qO epubcheck-5.2.1.zip https://github.com/w3c/epubcheck/releases/download/v5.2.1/epubcheck-5.2.1.zip && \
    echo '0532f6291faa2bb729dd253f958868a2a57dbd2c32f881a97c7c980c5940309e  epubcheck-5.2.1.zip' | sha256sum -c -

# Keep the base digest and both APT snapshots fixed between deliberate upgrades.
FROM debian:bookworm-20261005-slim@sha256:7c7b2c966bc9ee8cedfeef67e0e279108992c77681fa595db4a9d65c06ccc587
# Bootstrap HTTPS before APT can install Debian's certificate bundle.
COPY --from=downloads /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
RUN --mount=type=bind,from=downloads,source=/artifacts,target=/artifacts \
    set -eu; \
    rm /etc/apt/sources.list.d/debian.sources; \
    printf '%s\n' \
      'deb [check-valid-until=no] https://snapshot.debian.org/archive/debian/20261010T000000Z/ bookworm main' \
      'deb [check-valid-until=no] https://snapshot.debian.org/archive/debian-security/20261010T000000Z/ bookworm-security main' \
      > /etc/apt/sources.list; \
    apt-get -o Acquire::Retries=3 update; \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
      /artifacts/pandoc.deb ca-certificates python3 python3-yaml \
      fonts-liberation2 fontconfig openjdk-17-jre unzip; \
    unzip -q /artifacts/pypdf.whl -d /usr/lib/python3/dist-packages; \
    rm -rf /var/lib/apt/lists/*

COPY --from=downloads /artifacts/typst /usr/local/bin/typst
COPY --from=downloads /artifacts/wrap-it /root/.cache/typst/packages/preview/wrap-it/0.1.1/
RUN --mount=type=bind,from=downloads,source=/artifacts,target=/artifacts \
    unzip -q /artifacts/epubcheck-5.2.1.zip -d /opt && \
    printf '#!/bin/sh\nexec java -jar /opt/epubcheck-5.2.1/epubcheck.jar "$@"\n' > /usr/local/bin/epubcheck && \
    chmod +x /usr/local/bin/epubcheck && \
    ln -s /opt/epubcheck-5.2.1/epubcheck.jar /opt/epubcheck.jar

COPY bf /opt/bf
COPY templates /opt/templates
ENV PYTHONPATH=/opt BF_TEMPLATES=/opt/templates PYTHONDONTWRITEBYTECODE=1
WORKDIR /work
ENTRYPOINT ["python3", "-m", "bf"]
