## Choose how to use book4matter {#installing-and-building}

There are three ways to use book4matter. Pick whichever suits how you like to work.

1. [Open book4matter web](https://app.book4matter.com/) to format a manuscript in your browser.
2. [Use book4matter cmd with Docker](#option-1-the-docker-hub-image) to run the published image.
3. [Run book4matter cmd from source](#option-2-install-directly-without-docker) to use tools installed on your machine.

### book4matter web

Open the app and drop in a Markdown, plain text, or Word manuscript. Enter your
book details, choose Print PDF, Screen PDF, EPUB, or HTML, and download your
book. If your manuscript uses images or settings in other folders, add the whole
project folder to preserve the file paths. Your files stay in your browser.

For help writing your manuscript, go directly to [Markdown](#markdown),
[table of contents settings](#contents-settings), or [index entries](#an-alphabetical-index-of-terms).

### book4matter cmd with Docker {#option-1-the-docker-hub-image}

A prebuilt image is published at
[`book4matter/book4matter`](https://hub.docker.com/r/book4matter/book4matter).
Pull it once:

```
docker pull book4matter/book4matter
```

Then run the tool with `docker` directly. Mount the directory that holds your
book at `/work`; the image does the rest:

```
docker run --rm -v "$PWD":/work book4matter/book4matter print my-book/
```

The image's entry point is `bf`, so everything after the image name is an
ordinary `bf` command. The other forms work the same way:

```
docker run --rm -v "$PWD":/work book4matter/book4matter pdf  my-book/
docker run --rm -v "$PWD":/work book4matter/book4matter epub my-book/
docker run --rm -v "$PWD":/work book4matter/book4matter html my-book/
docker run --rm -v "$PWD":/work book4matter/book4matter all  my-book/
```

Output lands in `my-book/out/`. If typing the full line each time gets tedious,
wrap it in a shell alias or a short script of your own.

### book4matter cmd from source {#option-2-install-directly-without-docker}

If you would rather not run Docker at all, install the tools on your machine.
Book4matter needs:

- **Pandoc 3.9** --- the document converter.
- **Typst 0.14** --- the PDF typesetter. It bundles the Libertinus Serif body
  font, so there is nothing extra to install for that.
- **Python 3 with PyYAML** --- the `bf` command.
- **The Liberation fonts** --- Liberation Sans is used for headings.

Two more are optional: a Java runtime and
[EPUBCheck](https://github.com/w3c/epubcheck) if you want the EPUB validated
(otherwise build EPUBs with `--no-check`), and Python's `pypdf` if you want the
`impose` command.

Pandoc and Typst both ship self-contained binaries on their release pages, so
the surest way to get the tested versions --- on any operating system, without
a package manager --- is to download them directly:

- Pandoc 3.9: <https://github.com/jgm/pandoc/releases>
- Typst 0.14: <https://github.com/typst/typst/releases>

PyYAML comes from `pip` (`pip install pyyaml`), and the Liberation fonts from
your operating system's font package or the
[project page](https://github.com/liberationfonts/liberation-fonts).

Then clone this repository --- it holds the `bf` command and the templates ---
point `bf` at the templates, and run it as a Python module from the repository
root:

```
export BF_TEMPLATES="$PWD/templates"
python3 -m bf print example/
```

The print interior is in `example/out/`. Substitute your book directory for
`example/` and use `pdf`, `epub`, or `html` for the other formats.

Newer versions of Pandoc and Typst usually work, but 3.9 and 0.14 are the
versions the project builds and tests against. The project's own GitHub Actions
workflow, [`.github/workflows/deploy-web.yml`](https://github.com/cocode/Book4matter/blob/main/.github/workflows/deploy-web.yml),
downloads exactly these binaries and builds every sample book on each commit, so
it is a working, always-current reference for this option.
