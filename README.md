# XSP for GCC/GAS・XSPのGCC/GASにの移植

This is a hasty conversion of [XSP](https://github.com/yosshin4004/x68k_xsp) V2.04 to GCC/GAS syntax.

適当にGCC/GASの文法に編集しました。　下手くその日本語を許してほしいです。

As always, this is work done with some regex and otherwise done by hand. Absolutely no AI was used.

エディターでregexぐらい利用しましたが、いつも通りAIやLLM使わず自分出やりました。

## License・許諾
All original XSP code or any code derived from it falls under the original license, and I make no claim of ownership of these derived works. If you make use of this adaptation, I would appreciate a word of thanks, but I cannot demand it of you.

当たり前と思いますが、私は元々のXSPと関係がありませんので、このリポジトリーは同じ使用契約になります。　自分のものとして見ていません。
もしこれを使用したらクレジットタイトルにでたらありがたいんですが、そこまでお願いしません。

## Documentation・説明
I translated the original XSP documentation, and have included it as `xsp2lib_en.txt` in this repository.
I've corrected by hand some of the text-art diagrams that use line-drawing characters that may not be available ordinarily.

元々のXSPの説明書を英語に翻訳してみました。　この文が読めばいらないと思いますけどね。


# What was Done・何が変わった

No functional changes have been made; this is purely a syntax conversion. The source files are compatible with regular GCC's assembler with the pre-processor enabled (with `.S` files).

ライブラリーの機能が変わらず文法だけを変えました。　普通のアセンブラー（CPP付き）に使えます (`.S`のファイル）

A Makefile has not been provided, as the small size of this library means it should be trivial to simply assemble it alongside any other code.

こんなに小さいライブラリーだとMakefileが不必要と思っています。　他のコードのとなりにおいて一緒に作成したらいいと思っています。　（ライブラリーではなくて普通のオブジェファイルになります）

All files are now UTF-8 as well, instead of Shift-JIS.

元々のSJISをUTF-8に変更しました。

I have extended the original `xsp2lib.h` considerably to add usage comments and give clearer parameter structs. It should be fully compatible with existing code.

`xsp2lib.h`をかなり更新して、パラメーターのストラクとをわかりやすくしました。　前から存在しているXSP利用中コードはまだ互換のはずです。

# How to Use It・使い方

Assembler invocation:
アセンブラーの呼び方
```
human68k-gcc -c -mcpu=68000 -Wa,--register-prefix-optional -Wa,--bitwise-or -x assembler-with-cpp xspsys.S
```

This is an example. I expect the invocation will change based on your environment and project.
これは例の呼び方です。　環境によって変わります。

## Clobber Convention・潰されているレジスターの注意

It seems on X68000 registers `d0-d2/a0-a2` were clobbered, so when writing C code along side XSP, you should set the following options in the compiler to avoid having a bad time:

当時関数は`d0-d2/a0-a2`を潰していたそうので、もしC言語から呼ぶならコンパイラーにこのフラグを立てください。

```
CFLAGS += -fcall-used-d2 -fcall-used-a2
```
