# Markdown -> KDP print-PDF pipeline. Everything lives in this image; nothing is
# installed on the host.
FROM pandoc/typst:latest

# Python + PyYAML for the kpc CLI; Liberation Sans (Helvetica-metric) for
# headings; openjdk + unzip for the epubcheck validator. (pandoc and typst
# already ship in the base.)
RUN apk add --no-cache python3 py3-yaml font-liberation openjdk17-jre-headless unzip

# Vendor the wrap-it typst package into the local package cache so typst never
# has to reach out to the network at compile time. Pinned to a specific version
# from the canonical typst/packages repo.
ARG WRAP_IT_VERSION=0.1.1
RUN mkdir -p "/root/.cache/typst/packages/preview/wrap-it/${WRAP_IT_VERSION}" && \
    cd "/root/.cache/typst/packages/preview/wrap-it/${WRAP_IT_VERSION}" && \
    for f in typst.toml wrap-it.typ LICENSE README.md; do \
      wget -q "https://raw.githubusercontent.com/typst/packages/main/packages/preview/wrap-it/${WRAP_IT_VERSION}/$f" -O "$f"; \
    done

# W3C epubcheck - the canonical EPUB validator. KDP runs equivalent checks on
# upload, so failing epubcheck locally catches most KDP rejections. The zip is
# vendored under vendor/ (see vendor/README.md) so the build is offline /
# deterministic and doesn't re-fetch from GitHub on cold cache.
ARG EPUBCHECK_VERSION=5.2.1
COPY vendor/epubcheck-${EPUBCHECK_VERSION}.zip /tmp/epubcheck.zip
RUN cd /opt && \
    unzip -q /tmp/epubcheck.zip && \
    rm /tmp/epubcheck.zip && \
    ln -s "/opt/epubcheck-${EPUBCHECK_VERSION}/epubcheck.jar" /opt/epubcheck.jar && \
    printf '#!/bin/sh\nexec java -jar /opt/epubcheck.jar "$@"\n' > /usr/local/bin/epubcheck && \
    chmod +x /usr/local/bin/epubcheck

COPY kpc /opt/kpc
COPY templates /opt/templates

ENV PYTHONPATH=/opt \
    KPC_TEMPLATES=/opt/templates \
    PYTHONDONTWRITEBYTECODE=1

WORKDIR /work
ENTRYPOINT ["python3", "-m", "kpc"]
