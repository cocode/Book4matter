# Quick start

The quickest way to run Book4matter is the prebuilt Docker image: nothing to
clone, and nothing to install but Docker itself — no pandoc, no Typst, no fonts
to hunt down. (Prefer to install the tools directly, or build the image
yourself? The [manual](https://book4matter.com/examples/docs/book4matter.html)
covers all three ways.)

## Install Docker
https://docs.docker.com/engine/install/

## Get book4matter

Pull the image from Docker Hub:

    docker pull book4matter/book4matter

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

Mount the folder that holds your book at `/work` and name the form you want.
Everything after the image name is an ordinary `bf` command:

    docker run --rm -v "$PWD":/work book4matter/book4matter print my-book/   # KDP print interior PDF
    docker run --rm -v "$PWD":/work book4matter/book4matter pdf   my-book/   # shareable PDF with live links
    docker run --rm -v "$PWD":/work book4matter/book4matter epub  my-book/   # validated EPUB
    docker run --rm -v "$PWD":/work book4matter/book4matter html  my-book/   # single-page website

Each command writes into `my-book/out/`; the tool only ever writes there, never
back over your manuscript.
