```{=html}
<nav class="site-nav" aria-label="Book4matter navigation">
<a href="https://book4matter.com/" aria-current="page">Home</a>
<a href="https://book4matter.com/examples/docs/book4matter.html">User Manual</a>
<a href="#examples">Examples</a>
<a href="https://app.book4matter.com/">Web app</a>
<a href="https://github.com/cocode/Book4matter/">GitHub</a>
</nav>
```

## ![](../media/book4matter-logo.png){width="1.5em" style="vertical-align: middle"} Book4matter Home Page {.unnumbered}

**Write in Markdown. Publish everywhere.** 
Book4matter (Book Formatter) takes in Markdown, or plain text, and formats it for distribution. It uses this one source to produce output in HTML, EPUB, PDF and print versions. (PDF versions have clickable links, print has page references).

It was built to take a manuscript to Amazon KDP without worrying about formatting while you are writing. 



Book4matter is available as a web app, a prebuilt docker container and as source. 

The web version is at [app.book4matter.com](http://app.book4matter.com).

Source for web version: [Book4matter-web GitHub](https://github.com/cocode/book4matter-web).

You can get a docker container for Book4matter with

```docker pull book4matter/book4matter```

Or just pull the source, and install it locally. 
Source for command line version: [Book4matter GitHub](https://github.com/cocode/Book4matter/)

Read the [full user manual](https://book4matter.com/examples/docs/book4matter.html).

 This webpage is rendered by Book4matter. It was written in Markdown.

> TBH, Book4matter is not really designed to be a website builder. But using it to build its own website seemed reasonable. 

# Overview

## Why it exists

Book4matter lets you keep your text, and the formatting separate:

- You can write your manuscript in Markdown or text, without worrying about formatting
- - You can read, diff, and version these text files in git.
- The **metadata** (title, author, rights) lives in [one small YAML file](https://book4matter.com/examples/docs/book4matter.html#the-book_metadata.yaml-file).
- The **style** (trim, margins, fonts) lives in [another YAML file](https://book4matter.com/examples/docs/book4matter.html#the-book_style.yaml-file).

Point ten books at one style file and restyle them all from a single edit. The manuscript never changes.

