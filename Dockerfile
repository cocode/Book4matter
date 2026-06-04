# Markdown -> KDP print-PDF pipeline. Everything lives in this image; nothing is
# installed on the host.
FROM pandoc/typst:latest

# Python + PyYAML for the kpc CLI. (pandoc and typst already ship in the base.)
RUN apk add --no-cache python3 py3-yaml

COPY kpc /opt/kpc
COPY templates /opt/templates

ENV PYTHONPATH=/opt \
    KPC_TEMPLATES=/opt/templates \
    PYTHONDONTWRITEBYTECODE=1

WORKDIR /work
ENTRYPOINT ["python3", "-m", "kpc"]
