# Markdown -> KDP print-PDF pipeline. Everything lives in this image; nothing is
# installed on the host.
FROM pandoc/typst:latest

# Python + PyYAML for the kpc CLI; Liberation Sans (Helvetica-metric) for
# headings. (pandoc and typst already ship in the base.)
RUN apk add --no-cache python3 py3-yaml font-liberation

# Vendor the wrap-it typst package into the local package cache so typst never
# has to reach out to the network at compile time. Pinned to a specific version
# from the canonical typst/packages repo.
ARG WRAP_IT_VERSION=0.1.1
RUN mkdir -p "/root/.cache/typst/packages/preview/wrap-it/${WRAP_IT_VERSION}" && \
    cd "/root/.cache/typst/packages/preview/wrap-it/${WRAP_IT_VERSION}" && \
    for f in typst.toml wrap-it.typ LICENSE README.md; do \
      wget -q "https://raw.githubusercontent.com/typst/packages/main/packages/preview/wrap-it/${WRAP_IT_VERSION}/$f" -O "$f"; \
    done

COPY kpc /opt/kpc
COPY templates /opt/templates

ENV PYTHONPATH=/opt \
    KPC_TEMPLATES=/opt/templates \
    PYTHONDONTWRITEBYTECODE=1

WORKDIR /work
ENTRYPOINT ["python3", "-m", "kpc"]
