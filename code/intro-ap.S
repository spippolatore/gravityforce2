�����<�7�<�7  g�<�7�<�7�<�7�<�7�<�7�<�7
	section	uleprog,code

ProgStart:
	move.w	#$20,$dff096
	move.l	a1,-(sp)

	lea	bild,a0
	bsr	DEPACK

	move.l	(sp)+,a1
	move.l	a1,d0
	add.l	#64,d0
	lea	bplptr,a0
	moveq	#4,d7
.l:	move.w	d0,6(a0)
	swap	d0
	move.w	d0,2(a0)
	swap	d0
	addq.l	#8,a0
	add.l	#10240,d0
	dbf	d7,.l

	lea	cols,a0
	move.l	a1,a2
	move.w	#$180,d0
	moveq	#31,d7
.ll:	move.w	d0,(a0)+
	move.w	(a1)+,(a0)+
	add.w	#2,d0
	dbf	d7,.ll

	move.w	#$20,$dff096

.q:	tst.b	$dff006
	bne.s	.q
	btst	#0,$dff005
	bne.s	.q

	move.l	#copper,$dff080
	move.w	#$83c0,$dff096	;bpl,cop,blt enable
	move.w	#$20,$dff096
	rts


;Autodoc to the DEPACK routine:
;	a0 - pointer to packed file
;	a1 - pointer to buffer for depacked file
;	bsr	DEPACK

;struct for packed file:
;	dc.l	"BPCK"	;id for depack routine
;	dc.b	k1	;control byte #1
;	dc.b	k2	;control byte #2
;	dc.w	0	;!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
;	dc.l	Size	;Unpacked size
;	...data...

;dc.b	k1,5,6		; = 5 times "chr$(6)"
;dc.b	k1,255		; = chr$(k1)
;dc.b	k2,5,6,7	; = (5*256 + 6) times "chr$(7)"
;dc.b	k2,255		; = chr$(k2)

;------------- DEPACK ROUTINE

DEPACK:
	cmp.w	#'BP',(a0)+	;BPxx (xx=CK / xx=CC)
	bne.L	exit_np		;not packed!
	add.l	#2,a0
	move.b	(a0)+,k1+3
	move.b	(a0)+,k2+3
	cmp.w	#0,(a0)+
	bne.w	exit_np
	move.l	(a0)+,d7	;FILESIZE,unpacked
	subq.l	#1,d7
unpack:
;flash!
;	move.w	$dff006,$dff180

	move.b	(a0)+,d0
	cmp.b	k1+3,d0
	beq.s	kontroll1
	cmp.b	k2+3,d0
	beq.s	kontroll2
	move.b	d0,(a1)+
	subq.l	#1,d7
	bpl.s	unpack
	bra.L	depack_ready
kontroll1:
	moveq	#0,d1
	move.b	(a0)+,d1
	cmp.b	#255,d1
	bne.s	not_kontrbyte1
	move.b	d0,(a1)+
	subq.l	#1,d7
	bpl.s	unpack
	bra.L	depack_ready
not_kontrbyte1:
	move.b	(a0)+,d2
	and.l	#$FF,d1
	move.l	d1,temp_d1

	add.l	#1,d7
	cmp.l	d1,d7
	bmi.w	depack_crash
	sub.l	#1,d7

	bsr	unpack_it

	move.l	temp_d1,d1
	sub.l	d1,d7
	bpl.s	unpack
	bra.w	depack_ready
kontroll2:
	moveq	#0,d1
	move.b	(a0)+,d1
	cmp.b	#255,d1
	bne.s	not_kontrbyte2
	move.b	d0,(a1)+
	subq.l	#1,d7
	bpl.s	unpack
	bra.s	depack_ready
not_kontrbyte2:
	asl.w	#8,d1
	move.b	(a0)+,d1	;d1=# of d2s,d1=word
	move.b	(a0)+,d2
	move.l	d1,temp_d1

bp_noblt:
	add.l	#1,d7
	cmp.l	d1,d7
	bmi.s	depack_crash
	sub.l	#1,d7

	bsr	unpack_it

	move.l	temp_d1,d1
	sub.l	d1,d7
	bpl.w	unpack
	bra.s	depack_ready

unpack_it: 	move.l	a1,d6
	btst	#0,d6		;even adr?
	beq.s	bp_evenadr
	move.b	d2,(a1)+	;no? fix it!
	subq.w	#1,d1
bp_evenadr:
	moveq	#0,d3
	move.b	d2,d3
	divu	#4,d1
	lsl.l	#8,d3
	move.b	d2,d3
	move.w	d3,d2
	swap	d3
	move.w	d2,d3	
	bra.s	bpfl_el
bpfl:	move.l	d3,(a1)+
bpfl_el:dbf	d1,bpfl
	swap	d1		;even up the last bytes
no_longs:
	and.l	#$ff,d3
	bra.s	bpfl_n
bpfl_l:	move.b	d3,(a1)+
bpfl_n:	dbf	d1,bpfl_l
	rts

depack_ready:
	moveq	#0,d0
	rts			;depack ready,no errors

depack_crash:
	moveq	#-2,d0
	rts
exit_np:
	move.l	#-1,d0
	rts			;depack routine error



	section mydata,data_c   ; keep data & code seperate!

copper:
	dc.w	$008e,$2020	;r$20 c$20
	dc.w	$0090,$50ef	;r$150c$1ef
	dc.w	$0092,$0038	;vmarg=$38
	dc.w	$0094,$00d0	;hmarg=$d0
	dc.w	$0100,$0200	;bpl
	dc.w	$0102,$0	;scroll=0
	dc.w	$0104,$0	;sprpri
	dc.w	$0106,$0	;AGA compability
	dc.w	$0108,$0	;odd mod-0
	dc.w	$010a,$0	;even m-0

Cols:	blk.l	32,0

bplptr:	dc.w	$e0,0,$e2,0,$e4,0,$e6,0
	dc.w	$e8,0,$ea,0,$ec,0,$ee,0
	dc.w	$f0,0,$f2,0,$f4,0,$f6,0

	dc.w	$2a07,$fffe,$100,$5200
	dc.w	$ffdf,-2
	dc.w	$2a07,$fffe,$100,$0200
	dc.w	$ffff,-2

k1:	ds.l	1
k2:	ds.l	1
temp_d1:	ds.l	1

	section	spy_ule,data

Bild:	incbin "dh1:gfx/gf2/GF2_logo.bmap"

