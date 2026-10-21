# XSP for human68k-as

This is a hasty conversion of [XSP](https://github.com/yosshin4004/x68k_xsp) V2.04 to GCC/GAS syntax.

## License
All original XSP code or any code derived from it falls under the original license, and I make no claim of ownership of these derived works.

## Documentation
I translated the original XSP documentation, and have included it as `xsp2lib_en.txt` in this repository.

I've corrected by hand some of the text-art diagrams that use line-drawing characters that may not be available ordinarily.

# What was Done

No functional changes have been made; this is purely a syntax conversion. The source files are compatible with regular GCC's assembler with the pre-processor enabled (with `.S` files).

A Makefile has not been provided, as the small size of this library means it should be trivial to simply assemble it alongside any other code.

All files are now UTF-8 as well, instead of Shift-JIS.

I have extended the original `xsp2lib.h` considerably to add usage comments and give clearer parameter structs. It should be fully compatible with existing code.
