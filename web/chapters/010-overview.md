# Book4matter

**Write in Markdown. Publish everywhere.** 
Book4matter (Book Formatter) takes in Markdown, or plain text, and formats it for distribution. It uses this one source to produce output in HTML, EPUB, PDF and print versions. (PDF versions have clickable links, print has page references).

It was built to take a manuscript to Amazon KDP without worrying about formatting while you are writing. 

> This webpage is a Book4matter site. It was written in Markdown in
> `web/chapters/`, and rendered to HTML by the same tool it describes.

TBH: Book4matter is not really designed as a website builder. But using it to build its own website seemed reasonable. 

Book4matter is a command line tool, for now. It's best for people who are comfortable with the command line. 

Check back later for a web version.

## Why it exists

Book4matter lets you keep your text, and the formatting separate:

- Your **manuscript** is Markdown you can read, diff, and version in git.
- The **metadata** (title, author, rights) lives in one small YAML file.
- The **style** (trim, margins, fonts) lives in another YAML file.

Point ten books at one style file and restyle them all from a single edit. The
manuscript never changes.
