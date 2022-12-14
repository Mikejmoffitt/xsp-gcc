XSP for human68k-as
===================

About
-----
This repository contains a modification of the XSP sprite management library, created by yosshin4004. The original is located at `https://github.com/yosshin4004/x68k_xsp`.
The original library targets the HAS assembler, which runs natively on the X68000. To facilitate cross-platform development using modern GCC, I created this hacked source so that it will assemble with human68k-as in MRI compatibility mode (-M).
MRI compatibility mode was used so that minimal changes to the code had to be made. Converting to GAS syntax would be a little more painful.

License
-------
All of this code falls under the same license as the original.

Preemptive Apology
------------------
The changes made to the code were quick and crude. I'm not happy with how it looks, and making changes would be uglier than working on the HAS source. It'd be nice to make a converter down the line to automate all of this.
If it is possible to come up with a workable solution that does not involve this repository, I'd be happy to delete it and use only what is offered on the main repository.
I don't want to consider trying to merge them into the master repository for even a moment.

Documentation
-------------
While I was at it I did a full translation of the readme. There are now two files:

* readme_e.txt: XSP documentation in English
* readme_j.txt: XSP documentation in Japanese, as UTF-8.

I've corrected by hand some of the text-art diagrams that use line-drawing characters.

What was Done
-------------

No functional changes have been made. In short, with the assembler in MRI mode, most things typical of any 68000 assembler worked as-is, but a few features differed.

* Build process

A minimal Makefile is included that will build both an xsp2lib.o and xsp2lib.a file; the latter may be useful in case you do not wish to include this as a git submodule in a project. I do not recommend carrying around an old object file if an archive is available.

* Filenames and organization

I placed all the source files in the `src/` directory, and the Makefile will place everything emitted in `out/`.

* xsp2lib.h

I've added english comments to xsp2lib.h, and also added very brief descriptions of the functions and parameters.

* Binary constants

Unfortunately, the very legible #%xxxx_xxxx syntax of the original code had to be replaced with #$XX as a binary radix did not present itself for constants.

* No ORG???

The ORG psuedo-op does not work *even within a section*! Luckily for me, XSP only uses it early on to help define some structs with data space psuedo-ops (e.g. `ds.w`) so I was able to "solve" this by replacing this nice clean code with disgusting manually-defined offset values.

* No .rept

If GAS with MRI has a repeat macro, I don't know about it. What am I going to do, look at the "documentation", which just tells me to find the manual for an ancient assembler? Good luck! I just copied and pasted the code while muttering to myself in lieu of the repeat macro.

* Anonymous Labels

In HAS, an anonymous label can be defined as many times as desired with `@@`. The monikers `@F` and `@B` can then refer to the next or previous `@@` definition. *This is true even across global labels!*
GAS, in MRI mode, follows the conventions of an older assembler for which I have trouble finding docs. If there's something similar, I didn't find it. For this, I ended up creating new labels by hand for every branch done with this sort of label. This harms both the maintainability and 

* Macros

GAS macros start with `macro` and end with `endm`, whereas HAS uses `.macro` and `.endm`. This is fine, and is a straightforward adjustment. However, HAS supports declaring local labels within a macro. GAS-MRI on the other hand supports generation of both local labels with an `LL` prefix and generation of text unique to a macro with `\@`; together, I was able to replace the local labels with these.

* UTF-8

The original source is in Shift-JIS, as is appropriate for HAS. On a modern computer, depending on the operating system, locale settings, text editor, time of day, orientation to the north pole, temperature, and current frame count, this may show up properly as Japanese text, or illegible garbage.
I've converted the source files to UTF-8 using `iconv`.

* Original doscall and iocs macros

The original doscall.mac and iocs.mac files from the HAS distribution are here, with changes to work with this assembler.
