/*
Sprite Management System "XSP"
Ver 2.04 by Yosshin
https://github.com/yosshin4004/x68k_xsp
Translation and formatting by Mike Moffitt 2022
*/

#pragma once

// gcc 10 以降では、C の関数呼出し規約を無視して inline __asm__ で関数を実行
#if defined(__GNUC__)
#	if (__GNUC__ >= 10)
#		define XSP_USE_INLINE_ASM (1)
#		define XSP_FORCE_INLINE	static __attribute__((__always_inline__)) inline
#	endif
#endif
#ifndef XSP_FORCE_INLINE
#define XSP_FORCE_INLINE
#endif  // XSP_FORCE_INLINE

// `info` attribute defines.
#define XSP_HF 0x4000
#define XSP_VF 0x8000
#define XSP_PAL(color) ((color)<<8)

#define XSP_PRIO_HIDDEN 0x00
#define XSP_PRIO_BOTTOM 0x10
#define XSP_PRIO_MIDDLE 0x20
#define XSP_PRIO_TOP    0x30

#define XSP_INFO(flip, color, prio) ((flip) | ((color & 0xF) << 8) | (prio))

// xsp_set_st, xobj_set_st の引数構造体
// Argument struct for xsp_set_st and xobj_set_st.
#ifndef __ASSEMBLER__
typedef struct
{
	short x;              // X 座標 Position
	short y;              // Y 座標 Position
	short pt;             // スプライトパターン Sprite pattern no.
	short info;           // 反転コード・色・優先度を表わすデータ
	                      // Reflection code, color, priority data
	/*
      info = 0x****
               ↑↑↑↑
               ││││
               ││└┴────────  Priority level          （0-0x3F）
               ││
               │└──────────  Color Code (palette line)（0-0xF）
               │
               └───────────  Reversal code  0x0：Normal
                                            0x4：Horizontal flip
                                            0x8：Vertical flip
                                            0xC：Both
	*/
} XSP_SET_ARG;
#else
	.struct	0
XSP_SET_ARG.x:			ds.w	1
XSP_SET_ARG.y:			ds.w	1
XSP_SET_ARG.pt:			ds.w	1
XSP_SET_ARG.info:		ds.w	1
XSP_SET_ARG.len:
#endif

// 複合スプライトのフレームデータ構造体
// Composite sprite frame data struct.
#ifndef __ASSEMBLER__
typedef struct
{
	short vx;  // 相対座標データ Relative X coordinate data
	short vy;  // 相対座標データ Relative Y coordinate data
	short pt;  // スプライトパターン Sprite pattern no.
	short rv;  // 反転コード Reflection code
} XOBJ_FRM_DAT;
#else
	.struct	0
XOBJ_FRM_DAT.vx:		ds.w	1
XOBJ_FRM_DAT.vy:		ds.w	1
XOBJ_FRM_DAT.pt:		ds.w	1
XOBJ_FRM_DAT.rv:		ds.w	1
XOBJ_FRM_DAT.len:
#endif

// 複合スプライトのリファレンスデータ構造体
// Composite sprite reference data struct.
#ifndef __ASSEMBLER__
typedef struct
{
	short num;    // 合成スプライト数 Composite sprite FRM data count
	void *ptr;    // 開始位置のポインタ Pointer to start of FRM data
	short unused; //（未使用）(Unused)
} XOBJ_REF_DAT;
#else
	.struct	0
XOBJ_REF_DAT.num:		ds.w	1
XOBJ_REF_DAT.ptr:		ds.l	1
XOBJ_REF_DAT.unused:	ds.w	1
XOBJ_REF_DAT.len:
#endif

// ラスター割り込み処理のタイムチャート
// Raster interrupt processing time chart.
#ifndef __ASSEMBLER__
typedef struct
{
	short ras_no;        // 割り込みラスタナンバー Raster interrupt number
	                     // Use -1 to mark the end of the time chart.
	void (*proc)(void);  // 割り込み処理関数のポインタ
	                     // Raster interrupt routine pointer
} XSP_TIME_CHART;
#else
	.struct	0
XSP_TIME_CHART.ras_no:	ds.w	1
XSP_TIME_CHART.proc:	ds.l	1
XSP_TIME_CHART.len:
#endif

#ifndef __ASSEMBLER__
// Initializes XSP. Previously set V/H int handlers will be cancelled.
void xsp_on();

// Terminates XSP. Must be called at shutdown to avoid runaway interrupts.
// Interrupt vectors and other state are restored to their state before.
void xsp_off();

// Registers PCG pattern data and PCG management work memory with XSP.
//      pcg_dat: PCG pattern data pointer
//      pcg_alt: PCG placement work memory
//     alt_size: Length of pcg_alt, in bytes. Should be pattern count + 1.
void xsp_pcgdat_set(const void *pcg_dat, char *pcg_alt, short alt_size);

// Marks an area of PCG for XSP to not used.
//     start_no: Start PCG code number
//       end_no: End PCG code number
void xsp_pcgmask_on(short start_no, short end_no);

// Unmarks an area previously marked for disuse.
//     start_no: Start PCG code number
//       end_no: End PCG code number
void xsp_pcgmask_off(short start_no, short end_no);

// Selects the sprite doubler algorithm.
//      mode_no: Algorithm number.
//               1: Flickering 128 sprites to achieve 384
//               2: Maximum of 512 sprites (default)
//               3: Maximum of 512 sprites, with priority error mitigation
void xsp_mode(short mode_no);

// Specifies composite sprite mapping data.
//      sp_ref: Pointer to XOBJ reference data.
void xsp_objdat_set(const XOBJ_REF_DAT *sp_ref);

// Wait for vertical sync.
//            n: Number of vertical blank intervals to wait.
//               If 0 is specified, a frame of advance processing is done.
//               Advance processing may smooth a choppy game but will incur a
//               frame of latency.
// Returns the number of missed vertical blank periods.
short xsp_vsync(short n);

// Register a single-pattern sprite for display.
//            x: Sprite X coordinate
//            y: Sprite Y coordinate
//           pt: PCG pattern number (0-0x7FFF)
//         info: Attribute info (see readme)
// Returns 0 if the sprite's coordinates were off-screen.
XSP_FORCE_INLINE short xsp_set(short x, short y, short pt, short info);

// Register a composite sprite for display.
//            x: Composite Sprite X coordinate
//            y: Composite Sprite Y coordinate
//           pt: Composite sprite mapping (REF) number (0-0x0FFF)
//         info: Attribute info (see readme)
XSP_FORCE_INLINE void xobj_set(short x, short y, short pt, short info);

// Register a single-pattern sprite for display.
//          arg: Object set argument pointer
// Returns 0 if the sprite's coordinates were off-screen.
XSP_FORCE_INLINE short xsp_set_st(const XSP_SET_ARG *arg);

// Register a composite sprite for display.
//          arg: Object set argument pointer
XSP_FORCE_INLINE void xobj_set_st(const XSP_SET_ARG *arg);

// Displays sprites registered with batch processing.
// Returns the number of registered sprites displayed.
short xsp_out(void);

// Enables or disables vertical / portrait / tate mode.
//    vertical: 1 Vertical mode enabled
//              0 Vertical mode disabled.
void xsp_vertical(short flag);

// Registers a vertical sync interval callback function.
//       proc: Pointer to function (normal, not an int handler).
void xsp_vsyncint_on(void (*proc)(void));

// Clears registration of a vertical sync interval callback function.
void xsp_vsyncint_off(void);

// Registers a table of horizontal sync interupt callback functions.
// time_chart: Pointer to raster callback time chart (see readme).
void xsp_hsyncint_on(const XSP_TIME_CHART *time_chart);

// Clears registration of horizontal sync interval callback function(s).
void xsp_hsyncint_off(void);

// Enables or disables automatic raster division calcluation.
//      flag: 1 Automatic raster division enabled
//            0 Automatic raster division disabled
void xsp_auto_adjust_divy(short flag);

// Specifies a minimum height of raster division blocks.
//         h: height. Valid values are 24, 28, or 32.
void xsp_min_divh_set(short h);

// Returns the minimum raster division height.
//         i: Division block index (0 - 6).
short xsp_divy_get(short i);

// Sets offset value for sprite transfer raster line for 31KHz.
//      offs: Transfer raster line offset
void xsp_raster_ofs_for31khz_set(short ofs);

// Returns the sprite transfer raster line for 31KHz.
short xsp_raster_ofs_for31khz_get(void);

// Sets offset value for sprite transfer raster line for 15KHz.
//      offs: Transfer raster line offset
void xsp_raster_ofs_for15khz_set(short ofs);

// Returns the sprite transfer raster line for 15KHz.
short xsp_raster_ofs_for15khz_get(void);

// Inline implementations

#ifdef XSP_USE_INLINE_ASM

XSP_FORCE_INLINE short xsp_set(short x, short y, short pt, short info)
{
	register short reg_d0 __asm__ ("d0") = x;
	register short reg_d1 __asm__ ("d1") = y;
	register short reg_d2 __asm__ ("d2") = pt;
	register short reg_d3 __asm__ ("d3") = info;
	__asm__ __volatile__ (
			"	jbsr	xsp_set_asm\n"
	:	/* 出力 */	"+r"	(reg_d0)	/* in out %0 (入力＆戻り値) */
	:	/* 入力 */	"r"		(reg_d1),	/* in     %1 (入力＆維持) */
					"r"		(reg_d2),	/* in     %2 (入力＆維持) */
					"r"		(reg_d3)	/* in     %3 (入力＆維持) */
	:	/* 破壊 */	"a0"
	);
	return reg_d0;
}

XSP_FORCE_INLINE short xsp_set_st(const XSP_SET_ARG *arg)
{
	register short       reg_d0 __asm__ ("d0");
	register const void *reg_a0 __asm__ ("a0") = arg;
	__asm__ __volatile__ (
			"	jbsr	xsp_set_st_asm\n"
	:	/* 出力 */	"=r"	(reg_d0),	/*    out %0 (戻り値) */
					"+r"	(reg_a0)	/* in out %1 (入力＆破壊) */
	:	/* 入力 */
	:	/* 破壊 */	"memory",			/* メモリバリアを要求 */
					"a1"
	);
	return reg_d0;
}

XSP_FORCE_INLINE void xobj_set(short x, short y, short pt, short info)
{
	register short reg_d0 __asm__ ("d0") = x;
	register short reg_d1 __asm__ ("d1") = y;
	register short reg_d2 __asm__ ("d2") = pt;
	register short reg_d3 __asm__ ("d3") = info;
	__asm__ __volatile__ (
			"	jbsr	xobj_set_asm\n"
	:	/* 出力 */	"+r"	(reg_d0),	/* in out %0 (入力＆破壊) */
					"+r"	(reg_d1),	/* in out %1 (入力＆破壊) */
					"+r"	(reg_d2),	/* in out %2 (入力＆破壊) */
					"+r"	(reg_d3)	/* in out %3 (入力＆破壊) */
	:	/* 入力 */
	:	/* 破壊 */	"d4",
					"a0","a1","a2"
	);
}

XSP_FORCE_INLINE void xobj_set_st(const XSP_SET_ARG *arg)
{
	register short       reg_d0 __asm__ ("d0");
	register const void *reg_a0 __asm__ ("a0") = arg;
	__asm__ __volatile__ (
			"	jbsr	xobj_set_st_asm\n"
	:	/* 出力 */	"=r"	(reg_d0),	/* out %0 (破壊) */
					"+r"	(reg_a0)	/* out %1 (入力＆破壊) */
	:	/* 入力 */
	:	/* 破壊 */	"memory",			/* メモリバリアを要求 */
					"d1","d2","d3","d4",
					"a1","a2"
	);
}

#endif  // XSP_USE_INLINE_ASM

#else

	.extern	xsp_on
	.extern	xsp_off
	.extern	xsp_pcgdat_set
	.extern	xsp_pcgmask_on
	.extern	xsp_pcgmask_off
	.extern	xsp_mode
	.extern	xsp_objdat_set
	.extern	xsp_vsync
	.extern	xsp_set
	.extern	xobj_set
	.extern	xsp_set_st
	.extern	xobj_set_st
	.extern	xsp_out
	.extern	xsp_vertical
	.extern	xsp_vsyncint_on
	.extern	xsp_vsyncint_off
	.extern	xsp_hsyncint_on
	.extern	xsp_hsyncint_off
	.extern	xsp_auto_adjust_divy
	.extern	xsp_min_divh_set
	.extern	xsp_divy_get
	.extern	xsp_raster_ofs_for31khz_set
	.extern	xsp_raster_ofs_for31khz_get
	.extern	xsp_raster_ofs_for15khz_set
	.extern	xsp_raster_ofs_for15khz_get

#endif  // __ASSEMBLER__
