*==========================================================================
*
*	short xsp_vsync(short n);
*
*==========================================================================

_xsp_vsync:

L_A7ID	EQU	4			;   スタック上 return先アドレス  [ 4 byte ]
					; + 退避レジスタの全バイト数     [ 0 byte ]

	move.w	L_A7ID+arg1_w(sp),d0	; d0.w EQU n（帰線期間数）


*=======[ XSP 組込みチェック ]
	btst.b	#0,XSP_flg(pc)		; XSP は組み込まれているか？（bit0EQU1か？）
	bne.b	.vs_int_wait		; YES なら bra

	moveq	#-1,d0			; XSP が組み込まれていないので、戻り値 EQU -1
	bra.b	xsp_vsync_rts

*=======[ 指定 VSYNC 単位の垂直同期 ]
.vs_int_wait:
	cmp.w	vsync_count(pc),d0
	bhi.b	.vs_int_wait		; vsync_count < arg1（符号無視）ならループ

	move.w	vsync_count(pc),d0	; d0.w EQU 返り値
	clr.w	vsync_count


xsp_vsync_rts:
	rts




*==========================================================================
*
*	void xsp_objdat_set(void *sp_ref);
*
*==========================================================================

_xsp_objdat_set:

;L_A7ID	EQU	4			;   スタック上 return先アドレス  [ 4 byte ]
					; + 退避レジスタの全バイト数     [ 0 byte ]

	move.l	L_A7ID+arg1_l(sp),sp_ref_adr

	rts




*==========================================================================
*
*	void xsp_pcgdat_set(void *pcg_dat, char *pcg_alt, short alt_size);
*
*==========================================================================

_xsp_pcgdat_set:

;L_A7ID	EQU	4			;   スタック上 return先アドレス  [ 4 byte ]
					; + 退避レジスタの全バイト数     [ 0 byte ]

	movea.l	L_A7ID+arg1_l(sp),a0	; a0.l EQU *PCG_DAT
	movea.l	L_A7ID+arg2_l(sp),a1	; a1.l EQU *PCG_ALT
	move.w	L_A7ID+arg3_w(sp),d0	; d0.w EQU  PCG_ALT サイズ

*-------[ まず前回までの帰線期間 PCG 定義が終了するまで WAIT ]
	clr.w	vsync_count
	movem.l	d0-d2/a0-a2,-(sp)	; レジスタ退避
	move.l	#3,-(sp)		; 引数を PUSH
	bsr	_xsp_vsync		; 3 vsync WAIT
	lea	4(sp),sp		; スタック補正
	movem.l	(sp)+,d0-d2/a0-a2	; レジスタ復活

*-------[ 各種ユーザー指定アドレス書込み ]
	move.l	a0,pcg_dat_adr
	addq.w	#1,a1			; 配置管理テーブルの先頭 1 バイトは飛ばす
	move.l	a1,pcg_alt_adr

*-------[ PCG_ALT 初期化 ]
					; a1.l EQU pcg_alt_adr
					; d0.w EQU クリア数 +1
	subq.w	#2,d0			; dbra カウンタとするため補正
.pcgdat_l1:	clr.b	(a1)+
		dbra	d0,.pcgdat_l1

*-------[ PCG_REV_ALT 初期化 ]
	lea	pcg_rev_alt_no_pc,a1
	move.w	#255,d0			; 256.w クリアするための dbra カウンタ
.pcgdat_l2:	move.w	#-1,(a1)+
		dbra	d0,.pcgdat_l2

*-------[ XSP 内部フラグ処理 ]
	bset.b	#1,XSP_flg		; PCG_DAT, PCG_ALT が指定済を示すフラグをセット

	rts




*==========================================================================
*
*	void xsp_pcgmask_on(short start_no, short end_no);
*
*==========================================================================

_xsp_pcgmask_on:

;L_A7ID	EQU	4			;   スタック上 return先アドレス  [ 4 byte ]
					; + 退避レジスタの全バイト数     [ 0 byte ]

	move.w	L_A7ID+arg1_w(sp),d0	; d0.w EQU マスク設定開始ナンバー
	move.w	L_A7ID+arg2_w(sp),d1	; d1.w EQU マスク設定終了ナンバー

*-------[ dbra カウンタ初期値設定 ]
	cmpi.w	#256,d0
	bcc.b	xsp_mask_on_ERR		; #256 <EQU d1.w（符号無視）なら bra

	cmpi.w	#256,d1
	bcc.b	xsp_mask_on_ERR		; #256 <EQU d1.w（符号無視）なら bra

	tst.w	d0
	bne.b	.pcgmask_noadd
		addq.w	#1,d0		; マスク設定開始ナンバーが 0 なので、強制的に 1 にする。
.pcgmask_noadd:

	sub.w	d0,d1			; d1.w -EQU d0.w
	bmi.b	xsp_mask_on_ERR		; dbra カウンタ < 0 なら bra

	lea.l	OX_mask_no_pc,a0	; a0.l EQU OX_mask トップアドレス
	adda.w	d0,a0			; a0.l EQU OX_mask 参照開始アドレス

*-------[ マスク加工 ]
	move.l	#255,d0			; d0.b EQU 255（マスクon）

.pcgml1:move.b	d0,(a0)+		; マスク設定
	dbra	d1,.pcgml1		; 指定数処理するまでループ

	move.w	#1,OX_mask_renew	; OX_mask に更新があったことを伝える

*-------[ 正常終了 ]
	rts

*-------[ 引数が不正なので強制終了 ]
xsp_mask_on_ERR:
	rts




*==========================================================================
*
*	void xsp_pcgmask_off(short start_no, short end_no);
*
*==========================================================================

_xsp_pcgmask_off:

;L_A7ID	EQU	4			;   スタック上 return先アドレス  [ 4 byte ]
					; + 退避レジスタの全バイト数     [ 0 byte ]

	move.w	L_A7ID+arg1_w(sp),d0	; d0.w EQU マスク設定開始ナンバー
	move.w	L_A7ID+arg2_w(sp),d1	; d1.w EQU マスク設定終了ナンバー

*-------[ dbra カウンタ初期値設定 ]
	cmpi.w	#256,d0
	bcc.b	xsp_mask_off_ERR	; #256 <EQU d1.w（符号無視）なら bra

	cmpi.w	#256,d1
	bcc.b	xsp_mask_off_ERR	; #256 <EQU d1.w（符号無視）なら bra

	tst.w	d0
	bne.b	.pcgmo_noadd
		addq.w	#1,d0		; マスク設定開始ナンバーが 0 なので、強制的に 1 にする。
.pcgmo_noadd:

	sub.w	d0,d1			; d1.w -EQU d0.w
	bmi.b	xsp_mask_off_ERR	; dbra カウンタ < 0 なら bra

	lea.l	OX_mask_no_pc,a0	; a0.l EQU OX_mask トップアドレス
	adda.w	d0,a0			; a0.l EQU OX_mask 参照開始アドレス

*-------[ マスク加工 ]
	moveq.l	#0,d0			; d0.b EQU 0（マスクoff）

.pcgml2:move.b	d0,(a0)+		; マスク設定
	dbra	d1,.pcgml2		; 指定数処理するまでループ

	move.w	#1,OX_mask_renew	; OX_mask に更新があったことを伝える

*-------[ 正常終了 ]
	rts

*-------[ 引数が不正なので強制終了 ]
xsp_mask_off_ERR:
	rts




*==========================================================================
*
*	void xsp_mode(short mode_no);
*
*==========================================================================

_xsp_mode:

;L_A7ID	EQU	4			;   スタック上 return先アドレス  [ 4 byte ]
					; + 退避レジスタの全バイト数     [ 0 byte ]

	move.w	L_A7ID+arg1_w(sp),d0	; d0.w EQU MODE_No.

*-------[ 無効な値の場合、3 が指定されたものとする ]
	tst.w	d0
	bne.b	.mode_nonzero
	moveq.l	#3,d0
.mode_nonzero:
	cmpi.w	#3,d0
	bls.b	.mode_lte3		; 3 >EQU d0.w なら bra
		moveq.l	#3,d0
.mode_lte3:

	move.w	d0,sp_mode
	rts




*==========================================================================
*
*	void xsp_vertical(short flag);
*
*==========================================================================

_xsp_vertical:

;L_A7ID	EQU	4			;   スタック上 return先アドレス  [ 4 byte ]
					; + 退避レジスタの全バイト数     [ 0 byte ]

	move.w	L_A7ID+arg1_w(sp),vertical_flg
	rts




*==========================================================================
*
*	void xsp_on();
*
*==========================================================================

_xsp_on:

;L_A7ID	EQU	4+15*4			;   スタック上 return先アドレス  [ 4 byte ]
					; + 退避レジスタの全バイト数     [ 15*4 byte ]
	movem.l	d0-d7/a0-a6,-(sp)	; レジスタ退避


*=======[ XSP 組み込みチェック ]
	bset.b	#0,XSP_flg		; 組み込み状態か？（チェックと同時にフラグセット）
	beq.b	.xsp_inactive		; 0(EQUNO) なら組込み処理へ bra
		bra	xsp_on_rts	; 既に組み込まれているので、共通終了処理へ
.xsp_inactive

*=======[ バッファ初期化 ]
	bsr	XSP_BUFF_INIT		; 全内部バッファ初期化（帰線期間転送バッファは除く）

*=======[ スーパーバイザーモードへ ]
	suba.l	a1,a1
	iocs	_B_SUPER		; スーパーバイザーモードへ
	move.l	d0,usp_bak		;（もともとスーパーバイザーモードなら d0.lEQU-1）


*=======[ XSP 組込み処理 ]
	ori.w	#$0700,sr		; 割り込み off
	bsr	WAIT			; 68030 対策

*-------[ MFP のバックアップを取る ]
	movea.l	#$e88000,a0		; a0.l EQU MFPアドレス
	lea.l	MFP_bak(pc),a1		; a1.l EQU MFP保存先アドレス

	move.b	AER(a0),AER(a1)		;  AER 保存
	move.b	IERA(a0),IERA(a1)	; IERA 保存
	move.b	IERB(a0),IERB(a1)	; IERB 保存
	move.b	IMRA(a0),IMRA(a1)	; IMRA 保存
	move.b	IMRB(a0),IMRB(a1)	; IMRB 保存

	move.l	$118,vektor_118_bak	; 変更前の V-disp ベクタ
	move.l	$138,vektor_138_bak	; 変更前の CRT-IRQ ベクタ
	move.w	$E80012,raster_No_bak	; 変更前の CRT-IRQ ラスタ No.

*-------[ V-DISP 割り込み設定 ]
	move.l	#VSYNC_INT,$118		; V-disp ベクタ書換え
	bclr.b	#4,AER(a0)		; 帰線期間と同時に割り込む
	bset.b	#6,IMRB(a0)		; マスクをはがす
	bset.b	#6,IERB(a0)		; 割り込み許可

*-------[ H-SYNC 割り込み設定 ]
	move.w	#1023,$E80012		; 割り込みラスタナンバー（まだ割り込み off）
	move.l	#RAS_INT,$138		; CRT-IRQ ベクタ書換え
	bclr.b	#6,AER(a0)		; 割り込み要求と同時に割り込む
	bset.b	#6,IMRA(a0)		; マスクをはがす
	bset.b	#6,IERA(a0)		; 割り込み許可

*------------------------------
	bsr	WAIT			; 68030 対策
	andi.w	#$f8ff,sr		; 割り込み on


*=======[ ユーザーモードへ ]
	move.l	usp_bak(pc),d0
	bmi.b	.init_no_usr			; スーパーバイザーモードから実行されていたら戻す必要無し
		movea.l	d0,a1
		iocs	_B_SUPER	; ユーザーモードへ
.init_no_usr:

*-------[ 終了 ]
xsp_on_rts:
	movem.l	(sp)+,d0-d7/a0-a6	; レジスタ復活
	rts




*==========================================================================
*
*	void xsp_off();
*
*==========================================================================

_xsp_off:

;L_A7ID	EQU	4+15*4			;   スタック上 return先アドレス  [ 4 byte ]
					; + 退避レジスタの全バイト数     [ 15*4 byte ]
	movem.l	d0-d7/a0-a6,-(sp)	; レジスタ退避


*=======[ XSP 組み込みチェック ]
	bclr.b	#0,XSP_flg		; 組み込み状態か？（チェックと同時にフラグクリア）
	bne.b	.xsp_active		; 1(EQUYES) なら組込み解除処理へ bra
		bra	xsp_off_rts	; もともと組み込まれていないので、共通終了処理へ
.xsp_active:


*=======[ スーパーバイザーモードへ ]
	suba.l	a1,a1
	iocs	_B_SUPER		; スーパーバイザーモードへ
	move.l	d0,usp_bak		;（もともとスーパーバイザーモードなら d0.lEQU-1）


*=======[ XSP 組込み解除処理 ]
	ori.w	#$0700,sr		; 割り込み off
	bsr	WAIT			; 68030 対策

*-------[ MFP の復活 ]
	movea.l	#$e88000,a0		; a0.l EQU MFPアドレス
	lea.l	MFP_bak(pc),a1		; a1.l EQU MFPを保存しておいたアドレス

	move.b	AER(a1),d0
	andi.b	#$50,d0
	andi.b	#$AF,AER(a0)
	or.b	d0,AER(a0)		; AER bit4&6 復活

	move.b	IERA(a1),d0
	andi.b	#$40,d0
	andi.b	#$BF,IERA(a0)
	or.b	d0,IERA(a0)		; IERA bit6 復活

	move.b	IERB(a1),d0
	andi.b	#$40,d0
	andi.b	#$BF,IERB(a0)
	or.b	d0,IERB(a0)		; IERB bit6 復活

	move.b	IMRA(a1),d0
	andi.b	#$40,d0
	andi.b	#$BF,IMRA(a0)
	or.b	d0,IMRA(a0)		; IMRA bit6 復活

	move.b	IMRB(a1),d0
	andi.b	#$40,d0
	andi.b	#$BF,IMRB(a0)
	or.b	d0,IMRB(a0)		; IMRB bit6 復活

	move.l	vektor_118_bak(pc),$118		; V-disp ベクタ復活
	move.l	vektor_138_bak(pc),$138		; CRT-IRQ ベクタ復活
	move.w	raster_No_bak(pc),$E80012	; CRT-IRQ ラスタ No. 復活

*------------------------------
	bsr	WAIT			; 68030 対策
	andi.w	#$f8ff,sr		; 割り込み on


*=======[ ユーザーモードへ ]
	move.l	usp_bak(pc),d0
	bmi.b	.xsp_off_nousp			; スーパーバイザーモードから実行されていたら戻す必要無し
		movea.l	d0,a1
		iocs	_B_SUPER	; ユーザーモードへ
.xsp_off_nousp:

*-------[ 終了 ]
xsp_off_rts:
	movem.l	(sp)+,d0-d7/a0-a6	; レジスタ復活
	rts




*==========================================================================
*
*	void xsp_vsyncint_on(void *proc);
*
*==========================================================================

_xsp_vsyncint_on:

;L_A7ID	EQU	4			;   スタック上 return先アドレス  [ 4 byte ]
					; + 退避レジスタの全バイト数     [ 0 byte ]

	move.l	L_A7ID+arg1_l(sp),vsyncint_sub
	rts




*==========================================================================
*
*	void xsp_vsyncint_off();
*
*==========================================================================

_xsp_vsyncint_off:

;L_A7ID	EQU	4			;   スタック上 return先アドレス  [ 4 byte ]
					; + 退避レジスタの全バイト数     [ 0 byte ]

	move.l	#dummy_proc,vsyncint_sub
	rts




*==========================================================================
*
*	void xsp_hsyncint_on(void *time_chart);
*
*==========================================================================

_xsp_hsyncint_on:

;L_A7ID	EQU	4			;   スタック上 return先アドレス  [ 4 byte ]
					; + 退避レジスタの全バイト数     [ 0 byte ]

	move.l	L_A7ID+arg1_l(sp),usr_chart
	rts




*==========================================================================
*
*	void xsp_hsyncint_off();
*
*==========================================================================

_xsp_hsyncint_off:

;L_A7ID	EQU	4			;   スタック上 return先アドレス  [ 4 byte ]
					; + 退避レジスタの全バイト数     [ 0 byte ]

	move.l	#dummy_chart,usr_chart
	rts



*==========================================================================
*
*	void xsp_auto_adjust_divy(short flag);
*
*==========================================================================

_xsp_auto_adjust_divy:

;L_A7ID	EQU	4			;   スタック上 return先アドレス  [ 4 byte ]
					; + 退避レジスタの全バイト数     [ 0 byte ]

	move.w	L_A7ID+arg1_w(sp),auto_adjust_divy_flg
	rts


*==========================================================================
*
*	short xsp_divy_get(short i);
*
*==========================================================================

_xsp_divy_get:

;L_A7ID	EQU	4			;   スタック上 return先アドレス  [ 4 byte ]
					; + 退避レジスタの全バイト数     [ 0 byte ]

	move.w	L_A7ID+arg1_w(sp),d0	; d0 EQU i
	bmi	.divy_get_bad_arg			; i < 0 なら bra
	cmp #6,d0
	bgt	.divy_get_bad_arg			; 6 < i なら bra
	;-----[ 0 <EQU i <EQU 6 ]
		add.w	d0,d0			; d0 EQU i * 2
		lea.l	divy_AB(pc),a0		; a0.l EQU #divy_AB
		move.w	(a0,d0.w),d0		; dl.w EQU *(short *)(#divy_AB + i * 2)
		rts

.divy_get_bad_arg:
	move.w	#-1,d0			; 無効な引数の場合はエラーとして -1 を返す
	rts


*==========================================================================
*
*	void xsp_min_divh_set(short h);
*
*==========================================================================
_xsp_min_divh_set:

;L_A7ID	EQU	4			;   スタック上 return先アドレス  [ 4 byte ]
					; + 退避レジスタの全バイト数     [ 0 byte ]

	move.w	L_A7ID+arg1_w(sp),d0	; d0.w EQU h

	cmp #MIN_DIVH_MIN,d0
	bge .divh_min_ok		; #MIN_DIVH_MIN <EQU h なら bra
	;-----[ MIN_DIVH_MIN > h ]
		moveq.l #MIN_DIVH_MIN,d0	; h EQU MIN_DIVH_MIN
.divh_min_ok:
	cmp #MIN_DIVH_MAX,d0
	ble .divh_max_ok		; #MIN_DIVH_MAX >EQU h なら bra
	;-----[ MIN_DIVH_MAX < h ]
		moveq.l #MIN_DIVH_MAX,d0	; h EQU MIN_DIVH_MAX
.divh_max_ok:

	move.w	d0,min_divh		; min_divh 設定

	rts


*==========================================================================
*
*	void xsp_raster_ofs_for31khz_set(short ofs);
*
*==========================================================================
_xsp_raster_ofs_for31khz_set:

;L_A7ID	EQU	4			;   スタック上 return先アドレス  [ 4 byte ]
					; + 退避レジスタの全バイト数     [ 0 byte ]

	move.w	L_A7ID+arg1_w(sp),raster_ofs_for31khz


*-------[ 全バッファのスプライト転送ラスタの再計算（31KHz 用）]
	moveq.l	#2,d2
	lea.l	XSP_STRUCT_no_pc,a0
.raster_ofs_31_copytop:
		bsr	UPDATE_INT_RASTER_NUMBER_FOR_31KHZ	; 破壊 d0-d1/a1
	lea.l	STRUCT_SIZE(a0),a0			; 次の構造体要素へ
	dbra	d2,.raster_ofs_31_copytop		; 指定数処理するまでループ

	rts


*==========================================================================
*
*	short xsp_raster_ofs_for31khz_get();
*
*==========================================================================
_xsp_raster_ofs_for31khz_get:

;L_A7ID	EQU	4			;   スタック上 return先アドレス  [ 4 byte ]
					; + 退避レジスタの全バイト数     [ 0 byte ]

	move.w	raster_ofs_for31khz(pc),d0

	rts


*==========================================================================
*
*	void xsp_raster_ofs_for15khz_set(short ofs);
*
*==========================================================================
_xsp_raster_ofs_for15khz_set:

;L_A7ID	EQU	4			;   スタック上 return先アドレス  [ 4 byte ]
					; + 退避レジスタの全バイト数     [ 0 byte ]

	move.w	L_A7ID+arg1_w(sp),raster_ofs_for15khz

*-------[ 全バッファのスプライト転送ラスタの再計算（15KHz 用）]
	moveq.l	#2,d2
	lea.l	XSP_STRUCT_no_pc,a0
.raster_ofs_15_copytop:
		bsr	UPDATE_INT_RASTER_NUMBER_FOR_15KHZ	; 破壊 d0-d1/a1
	lea.l	STRUCT_SIZE(a0),a0			; 次の構造体要素へ
	dbra	d2,.raster_ofs_15_copytop		; 指定数処理するまでループ

	rts


*==========================================================================
*
*	short xsp_raster_ofs_for15khz_get();
*
*==========================================================================
_xsp_raster_ofs_for15khz_get:

;L_A7ID	EQU	4			;   スタック上 return先アドレス  [ 4 byte ]
					; + 退避レジスタの全バイト数     [ 0 byte ]

	move.w	raster_ofs_for15khz(pc),d0

	rts

