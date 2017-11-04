all: sys.com prelim.com zexdoc.com zexall.com

export PATH := .:$(PATH)

zexdoc.mac: z80exer.pl
	$< --versions > $@

zexdoc.azm: z80exer.pl
	$< --versions --zmac > $@

zexall.mac: z80exer.pl
	$< --versions --all > $@

zexall.azm: z80exer.pl
	$< --versions --zmac --all > $@

%.com: %.azm
	mzmac -z $<
	mv $(@:%.com=%.bin) $@

%.com: %.asm
	zasm -uwy --z80 $< $@

.PHONY: clean
clean:
	rm -f *.lst
	rm -f sys.com
	rm -f prelim.com
	rm -f zexdoc.com
	rm -f zexall.com
