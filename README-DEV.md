# Building the Docker image for development

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

## Building the manual with the repository image

From the repository root:

```
# This manual, as a 6x9 print interior PDF.
./run.sh print docs/
# The same pages as a digital PDF, with live links.
./run.sh pdf docs/
# The same book as an EPUB.
./run.sh epub docs/
# The same book as one HTML page.
./run.sh html docs/

# The same book, four pages per sheet, formatted for folding and binding.
./run.sh impose docs/out/book4matter-interior.pdf
```

## Publishing to Docker Hub

Sign in with `docker login` using an account with push access to
`book4matter/book4matter`, then run `./push-docker.sh`. The script rebuilds
both AMD64 and ARM64 images from the committed source with the build cache
disabled, then publishes them under both `latest` and the full commit hash.
Commit or stash staged changes and edits to tracked files first. Untracked
files can stay in your checkout and are excluded from the build.
