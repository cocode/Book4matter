## Limitations

> The wonderful thing about standards is that there are so many to choose from.

### Output Formats

#### HTML

HTML is wonderful. The HTML version of this book should work everywhere.

#### PDF

PDFs are likewise very reliable.

#### EPUB

Epub has a lot more issues. Every publisher has slightly different restrictions on things like font encryption, image sizes and more.
Book4matter produces clean books that pass the standard epubcheck. Whether it will work with your epub publisher is something you
will have to check. We value feedback, and strive to make Book4matter more useful. Let us know if you find sharp edges.

#### Print

The *print* option is designed for printing via Amazon KDP, and has been tested there. We have not tested with IngramSpark, Lulu, etc.

Many modern non-print-on-demand printers require PDF/X files, which our tooling doesn't support.
They also may want crop marks, bleed marks, color bars, registration marks, etc. You'll probably (currently!) want another tool for
going to press. Again, let us know if you find specific things we can improve to make your life easier.


### Input Formats

While writing in Markdown is much simpler that writing in Word, there are some challenges. If you are using human editors, the editing
industry largely runs on "Microsoft Word, with track changes". This makes it very easy to have an editor make a lot of changes, and you
can easily accept them individually or as a whole.

This actually works just fine with Markdown, as you can use version control and merge. The issue is that the number of book editors
who are familiar with Git is **much** smaller than the number who know Word.

