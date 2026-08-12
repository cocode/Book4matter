## Installing and Building

Book4matter is Pandoc, Typst, Python, an EPUB validator, and a set of book
fonts, working together. There are three ways to get all of that; pick whichever
suits how you like to work:

1. **Pull the ready-made image from Docker Hub** --- the quickest start, and the
   right choice for most people.
2. **Install the pieces directly** on your machine, with no Docker at all.
3. **Build the image yourself** from this repository, if you would rather not
   run a prebuilt one.

The first and third need Docker. The second needs no Docker but a handful of
command-line tools. All three run the same `bf` commands and produce identical
output.

### Option 1: The Docker Hub image

A prebuilt image is published at
[`book4matter/book4matter`](https://hub.docker.com/r/book4matter/book4matter).
This is the fastest way to start: there is nothing to compile and no repository
to clone --- the tool and its templates are baked into the image, and only your
book's files are read from disk.

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

### Option 2: Install directly, without Docker

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
python3 -m bf print my-book/
```

Newer versions of Pandoc and Typst usually work, but 3.9 and 0.14 are the
versions the project builds and tests against. The project's own GitHub Actions
workflow, [`.github/workflows/deploy-web.yml`](https://github.com/cocode/Book4matter/blob/main/.github/workflows/deploy-web.yml),
downloads exactly these binaries and builds every sample book on each commit, so
it is a working, always-current reference for this option.

### Option 3: Build the image yourself

You can also build the Docker image from the `Dockerfile` in this repository
rather than pulling the prebuilt one from Docker Hub. It is more work, but the
image is assembled entirely from sources you can read --- worth doing if you
would rather not run a prebuilt binary you didn't build.

Clone the repository. The bundled `run.sh` builds the image the first time you
use it, then runs the tool with your current directory mounted inside the
container:

```
# Builds the image once, then builds the example book.
./run.sh print example/
```

That first run takes a little longer, while the image is assembled.

The templates and the `bf` command itself are baked into the image. After you
change a template or update the tool, force a rebuild so the change takes
effect:

```
./run.sh --rebuild print example/
```

To rebuild the image without building a book:

```
docker build -t book4matter .
```

Your book's own files --- the Markdown, the YAML, the images --- are *not* baked
in; they are read fresh from disk on every build, so editing a chapter never
needs an image rebuild.

`run.sh` only ever shells into the container. It mounts the current directory at
`/work`, and --- when you pass a file that lives elsewhere, such as a `.docx` in
`~/Documents` --- it mounts that file's folder read-only so the container can
read it. Everything else on your machine is left alone.
