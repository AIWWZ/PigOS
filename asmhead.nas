; PigOS--OS boot asm
; Tab = 4

BOTPAK	EQU		0x00280000
DSKCAC	EQU		0x00100000
DSKCAC0	EQU		0x00008000

; �й�BOOT_INFO
CYLS	EQU		0x0ff0		; �趨������
LEDS	EQU		0x0ff1
VMODE	EQU		0x0ff2		; ������ɫ��Ŀ����Ϣ����ɫ��λ����
SCRNX	EQU		0x0ff4		; �ֱ���X (screen x)
SCRNY	EQU		0x0ff6		; �ֱ���Y (screen y)
VRAM	EQU		0x0ff8		; ͼ�񻺳����Ŀ�ʼ��ַ

	ORG		0xc200
;����ģʽ�趨	
	MOV		BX,0x4101			; VBA�Կ���640*480*8λ��ɫ
	MOV 	AX,0x4f02
	INT		0x10
	MOV		BYTE [VMODE],8	; ��¼����ģʽ
	MOV		WORD [SCRNX],640
	MOV		WORD [SCRNY],480
	MOV		DWORD [VRAM],0xe0000000

; ��BIOSȡ�ü����ϸ���LEDָʾ�Ƶ�״̬
	MOV		AH,0x02
	INT		0x16			; keyboard BIOS
	MOV		[LEDS],AL
	
; PIC�ر�һ���жϣ�����AT���ݻ��Ĺ�����Ҫ��ʼ��PIC
; ������CLI֮ǰ���У� ������ʱ�����������PIC�ĳ�ʼ��

		MOV		AL,0xff
		OUT		0x21,AL
		NOP						; �������ִ��OUTָ���Щ���ֻ��޷���������
		OUT		0xa1,AL
		CLI						; ��ֹCPU������ж�

; �൱������C����
; io_out(PIC0_IMR, 0xff); // ��ֹ��PIC��ȫ���ж�
; io_out(PIC1_IMR, 0xff); // ��ֹ��PIC��ȫ���ж�
; io_cli(); //��ֹCPU������ж�

; Ϊ����CPU�ܷ���1MB���ϵ��ڴ�ռ䣬�趨A20GATE

		CALL	waitkbdout
		MOV		AL,0xd1
		OUT		0x64,AL
		CALL	waitkbdout
		MOV		AL,0xdf			; enable A20
		OUT		0x60,AL
		CALL	waitkbdout

; �൱������C����
; #define KEYCMD_WRITE_OUTPORT		0xd1
; #define KBC_OUTPORT_A20G_ENABLE	0xdf
; //A20GATE���趨
; wait_KBC_sendready();
; io_out8(PORT_KEYCMD, KEYCMD_WRITE_OUTPORT);
; wait_KBC_sendready();
; //��A20GATE�ź��߱��ON��״̬, ʹ�ڴ�1MB���ϵĲ��ֱ�Ϊ��ʹ��״̬��
; io_out8(PORT_KEYCMD, KBC_OUTPORT_A20G_ENABLE); 
; wait_KBC_sendready(); //Ϊ�˵ȴ�A20GATE�Ĵ�����ɣ���ʵ�Ƕ����
		
		
; �л�������ģʽ

[INSTRSET "i486p"]				; ����Ҫʹ��486ָ���������Ϊ����ʹ��386�Ժ��LGDT,EAX,CR0�ȹؼ���

		LGDT	[GDTR0]			; �趨��ʱGDT
		MOV		EAX,CR0
		AND		EAX,0x7fffffff	; �趨bit31Ϊ0��Ϊ�˽�ֹ�̣�
		OR		EAX,0x00000001	; �趨bit0Ϊ1��Ϊ���л�������ģʽ��
		MOV		CR0,EAX
		JMP		pipelineflush
pipelineflush:
		MOV		AX,1*8			;  ���Զ�д�Ķ� 32bit
		MOV		DS,AX
		MOV		ES,AX
		MOV		FS,AX
		MOV		GS,AX
		MOV		SS,AX

; bootpack�Ĵ���

		MOV		ESI,bootpack	; ����Դ
		MOV		EDI,BOTPAK		; ����Ŀ�ĵ�ַ
		MOV		ECX,512*1024/4
		CALL	memcpy

; Ӳ���������մ��͵���������λ��ȥ

; ���ȴ���������ʼ

		MOV		ESI,0x7c00		; ����Դ
		MOV		EDI,DSKCAC		; ����Ŀ�ĵ�ַ
		MOV		ECX,512/4
		CALL	memcpy

; ʣ�µ�ȫ��

		MOV		ESI,DSKCAC0+512	; ����Դ
		MOV		EDI,DSKCAC+512	; ����Ŀ�ĵ�ַ
		MOV		ECX,0
		MOV		CL,BYTE [CYLS]
		IMUL	ECX,512*18*2/4	; ���������任Ϊ�ֽ���/4
		SUB		ECX,512/4		; ��ȥIPL
		CALL	memcpy
		
; �൱������C����
; memcpy(bootpack, BOTPAK, 512*1024/4); //��bootpack�ĵ�ַ��ʼ��512KB���ݸ��Ƶ�0x00280000�ŵ�ַ��ȥ
; memcpy(0x7c00,   DSKCAC, 512/4); //��0x7c00����512�ֽڵ�0x00100000�����������������Ƶ�1MB�Ժ���ڴ���ȥ
; memcpy(DSKCAC0+512, cyls * 512*18*2/4 - 512/4); //��ʼ��0x00008200�Ĵ������ݸ��Ƶ�0x00100200ȥ

; ������asmhead����ɵĹ���������ȫ����ɣ�

;�Ժ����bootpack���Ӱ࣡
; bootpack������

		MOV		EBX,BOTPAK
		MOV		ECX,[EBX+16]
		ADD		ECX,3			; ECX += 3;
		SHR		ECX,2			; ECX /= 4;
		JZ		skip			; û��Ҫ���͵Ķ���ʱ
		MOV		ESI,[EBX+20]	; ����Դ
		ADD		ESI,EBX
		MOV		EDI,[EBX+12]	; ����Ŀ�ĵ�ַ
		CALL	memcpy
skip:
		MOV		ESP,[EBX+12]	; ջ�ĳ�ʼֵ
		JMP		DWORD 2*8:0x0000001b

waitkbdout:
		IN		AL,0x64
		AND		AL,0x02
		IN		AL,0x60			; �ն���Ϊ��������ݽ��ջ������е��������ݣ�
		JNZ		waitkbdout		; AND�Ľ���������0��������waitkbdout
		RET

; �����ڴ�ĳ���
memcpy:
		MOV		EAX,[ESI]
		ADD		ESI,4	; һ�θ���4���ֽ�
		MOV		[EDI],EAX
		ADD		EDI,4
		SUB		ECX,1
		JNZ		memcpy			
		RET


		ALIGNB	16
GDT0:
		RESB	8				; NULL selector
		DW		0xffff,0x0000,0x9200,0x00cf	; �ɶ�д�Ķ�
		DW		0xffff,0x0000,0x9a28,0x0047	; ��ִ�еĶΣ�bootpack�ã�

		DW		0
GDTR0:
		DW		8*3-1
		DD		GDT0

		ALIGNB	16
bootpack:
