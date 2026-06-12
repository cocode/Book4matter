# KindlePandocCreator

./rotary was moved to ~/Documents/Writing/Dance/Why/rotary

Markdown -> print-ready **6x9 KDP paperback interior PDF**, via Pandoc -> Typst,
entirely inside Docker. See [DESIGN.md](DESIGN.md) for the full design and
rationale.

## Requirements

- Docker. Nothing else is installed on the host.

## Usage

Build the bundled example:

```bash
./run.sh print example/          # -> example/out/interior.pdf
```

Build your own book (a directory containing `book.yaml` and `chapters/*.md`):

```bash
./run.sh print path/to/book/
```

Import a Word manuscript (splits into chapters on each Heading 1):

```bash
./run.sh import manuscript.docx path/to/book/
```

The first run builds the Docker image. After changing the template or CLI, force
a rebuild:

```bash
./run.sh --rebuild print example/
```

To rebuild the image without running a build:

```bash
docker build -t kindle-pandoc-creator .
```

## Book layout

- `book.yaml` — title, author, trim size, margins, font.
- `chapters/*.md` — one file per chapter (or list them in a `chapters:` key).
- `media/` — images, referenced as `../media/...` from chapter files.
- `out/interior.pdf` — the build output.
