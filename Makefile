LIBNAME := xsp2lib

RM := rm
AS := human68k-as
AR := human68k-ar
MKDIR := mkdir

SRCDIR := src
OUTDIR := out

ASFLAGS += -M

SOURCES := $(SRCDIR)/xspmem.s $(SRCDIR)/xspsys.s $(SRCDIR)/xspfnc.s \
           $(SRCDIR)/xspout.s $(SRCDIR)/xspset.s

all: $(OUTDIR)/$(LIBNAME).o $(OUTDIR)/$(LIBNAME).a

$(OUTDIR)/$(LIBNAME).o: $(SOURCES) $(OUTDIR)
	$(AS) $(ASFLAGS) -c $(SOURCES) -o $@

$(OUTDIR)/$(LIBNAME).a: $(OUTDIR)/$(LIBNAME).o
	$(AR) cr $@ $<

$(OUTDIR):
	$(MKDIR) -p $@

clean: $(OUTDIR)
	$(RM) -rf $(OUTDIR)
