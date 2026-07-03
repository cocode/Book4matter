## Installing and Building

Book4matter runs entirely inside a Docker image. Nothing is installed on your
machine: Pandoc, Typst, Python, the EPUB validator, and the heading fonts all
live in the image. If you have Docker, you have everything you need.

### The first build

The wrapper script `run.sh` builds the image the first time you run it, then
runs the tool with your current directory mounted inside the container:

```
# Builds the image once, then builds the example book.
./run.sh print example/
```

That first run takes a few seconds more, while the image is assembled. 

### Rebuilding the image

The templates and the `bf` command itself are baked into the image. After you
change a template or update the tool, force a rebuild so the change takes effect:

```
./run.sh --rebuild print example/
```

To rebuild the image without building a book:

```
docker build -t book4matter .
```

Your book's own files --- the Markdown, the YAML, the images --- are *not* baked
in; they are read fresh from disk on every build, so editing a chapter never
needs a rebuild.

### Nothing touches your host

`run.sh` only ever shells into the container. It mounts the current directory at
`/work`, and --- when you pass a file that lives elsewhere, such as a `.docx` in
`~/Documents` --- it mounts that file's folder read-only so the container can read
it. Everything else on your machine is left alone.
