# Quick start

Book4matter runs entirely inside a Docker image, so there is nothing to install
on your machine but Docker itself — no pandoc, no Typst, no fonts to hunt down.

## Install Docker. 
https://docs.docker.com/engine/install/

## Get book4matter

Pull the image from Docker Hub:

    docker pull book4matter/book4matter

Or clone the repository and let the bundled `run.sh` build the image for you the
first time you use it.

## Make a book

A book is just a directory:

    my-book/
      book_metadata.yaml    # title, author, rights
      book_style.yaml       # trim, margins, fonts
      chapters/
        010-first.md
        020-second.md

Chapters are combined in filename order, so a numeric prefix controls the
sequence.

## Build it

    ./run.sh print my-book/     # KDP print interior PDF
    ./run.sh pdf   my-book/     # shareable PDF with live links
    ./run.sh epub  my-book/     # validated EPUB
    ./run.sh html  my-book/     # single-page website

Each command writes into `my-book/out/`. Your sources are mounted read-only —
the tool can never modify your manuscript.
