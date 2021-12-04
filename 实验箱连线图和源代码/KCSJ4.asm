I0Y0	EQU  0600H
I0Y1    EQU  0640H

A8254   EQU  I0Y0+00H*2
B8254   EQU  I0Y0+01H*2
C8254   EQU  I0Y0+02H*2
CON8254  EQU  I0Y0+03H*2

A8255	    EQU  I0Y1+00H*2
B8255	    EQU  I0Y1+01H*2
C8255	    EQU  I0Y1+02H*2
CON8255	EQU  I0Y1+03H*2

DATA SEGMENT
	LED         DB   21H,24H,12H,18H
	TIME_LOOP  DB   30H,05H,30H,05H
	TIME_DOWN  DB  25H,05H,25H,05H
	SHUMA    	  DB  3FH,06H,5BH,4FH,
66H,6DH,7DH,07H,7FH,6FH
	TIME_SHOW  DW    30H
	TIME_NOW   DW     ?	           
;用于记录当前倒计时的数
	TIMER	 	DW     01H	       
;为0时表示需重新定时1s
	;TIMER	      DW     00H
	COUNTDOWN  	DB   25
	IS_EMER   	    DB   00H	       
;用于标记紧急情况，为1表示紧急
	DELAY_TIME 	DW  200H       
;延时时间
DATA ENDS

STACK  SEGMENT
         DW      50 DUP(?)
         TOP  LABEL  WORD
STACK  ENDS

CODE SEGMENT
ASSUME  CS:CODE,DS:DATA,SS:STACK
START:
;初始化8254控制端口为计数器0，
方式3，以此来将频率转化为1Hz
	MOV	AX,DATA     
;初始化
	MOV	DS,AX
	MOV	AX,STACK
	MOV	SS,AX
	MOV	SP,TOP

	MOV	DX,CON8254
	MOV	AL,00110110B
	OUT    DX,AL
	
	MOV	DX,A8254
	MOV	AL,00H
	OUT	DX,AL
	
	MOV	AL,24H
	OUT	DX,AL
	
	MOV	AL,88H           
;写入8255控制字,A,B,C口均工作于方式0,
A,B口输出
	MOV	DX,CON8255      
;C口低四位输出,高四位输入
	OUT	DX,AL

	MOV	AL,LED[0]
	MOV	DX,A8255
	OUT	DX,AL	
	JMP	BEGIN
	
ONESECOND  MACRO	      
;1s定时宏指令
 	MOV	DX,CON8254
	MOV	AL,01110001B      
;计数器1工作在方式0
	OUT	DX,AL
	MOV	DX,B8254
	MOV	AL,01H            
;送计数初值的低8位
	OUT	DX,AL
	MOV	AL,00H           
;送计数初值的高8位
	OUT	DX,AL
	ENDM
	
DELAY  MACRO		          
;延时宏指令，使4位数码管动态显示
	LOCAL	LOOPER
	MOV	CX,DELAY_TIME
LOOPER:	LOOP	LOOPER
	ENDM
	
BEGIN:	
	XOR	SI,SI               
;SI清零
	JMP	    REFRESH_LIGHT

REFRESH_LED:	                
;刷新数码管
	MOV		DX,C8255       
;选中数码管1
	MOV		AL,07H
	OUT		DX,AL
	MOV		DX,B8255   
;从SHUMA中选中对应的倒计时
十位数字,予以数码管显示
	LEA		    BX,SHUMA
	MOV		AX,TIME_SHOW
	PUSH	    CX
	MOV		CL,04H
	SHR		    AL,CL
	XLAT
	OUT		DX,AL
	POP		    CX
	DELAY
	
	MOV		DX,C8255           
;选中数码管2
	MOV		AL,0BH
	OUT		DX,AL
	MOV		DX,B8255           
;从SHUMA中倒计时个位数字,予以数码管显示
	LEA		    BX,SHUMA
	MOV		AX,TIME_SHOW
	AND		AL,0FH
	XLAT
	OUT		DX,AL
	DELAY
	
	MOV		DX,C8255   
;选中数码管3
	MOV		AL,0DH
	OUT		DX,AL
	MOV		DX,B8255   
;从SHUMA中选中对应倒计时十位数字,
予以数码管显示
	LEA		BX,SHUMA
	MOV	AX,TIME_SHOW
	PUSH	CX
	XOR	CX,CX
	MOV	CL,04H
	SHR		AL,CL
	XLAT
	OUT	DX,AL
	POP		CX
	DELAY
	
	MOV		DX,C8255          
;选中数码管4
	MOV		AL,0EH
	OUT		DX,AL
	MOV		DX,B8255         
;从SHUMA中选中倒计时个位数字,
予以数码管显示
	MOV		AX,TIME_SHOW
	AND		AL,0FH
	XLAT
	OUT		DX,AL
	DELAY
	
;意外事件
	MOV		DX,C8255
	IN		AL,DX
	AND		AL,20H
	CMP		AL,20H		    
;检测PC6是否输入为低
	JE		EMERGENCY	    
;PC6为高进行紧急情况处理
	JMP		RENORMAL     	
;PC6为低正常运行

EMERGENCY:
	INC	    IS_EMER			 
;标记紧急情况
	MOV	DX,A8255
	MOV	AL,30H			    
;东西、南北方向输出全红
	OUT	DX,AL
	JMP	REFRESH_LED
	
RENORMAL:
	CMP	IS_EMER,00H		
;之前是否处于紧急情况
	JE	    ADJUST_TIME		
;否则跳转到ADJUST
	DEC	SI
	LEA	BX,LED		            
;从LED表中取出各状态东西南北灯
亮的情况
	MOV	AX,SI
	XLAT
	MOV	DX,A8255
	OUT	DX,AL		           
;恢复紧急处理之前灯的状态
	MOV	IS_EMER,00H		   
;取消对紧急处理的标记
	INC	    SI

ADJUST_TIME:				        
;TIME_SHOW和TIME_NOW中的时间用
十六进制存储，当其中数字是F时，应将
其转化为9
	MOV	AX,TIME_SHOW		    
;判断显示的计时个位数是否为0,是则减去6
	PUSH	CX
	MOV	CL,12
	SHL		AX,CL
POP		CX
	SUB		AH,0F0H		            
;TIME_SHOW中的低4位是否为F
	JZ		ADJUST_SHOW		    
;是则进行调整
	
	MOV	AX,TIME_NOW		    
;判断当前倒计时个位数是否为0,是则减去6
	PUSH	CX
	MOV	CL,12
	SHL		AX,CL
	POP		CX
	SUB		AH,0F0H
	JZ		ADJUST_NOW		    
;是则进行调整
	XOR	AX,AX

	DEC	TIMER
	JNZ		NEXT
	ONESECOND		            
;进行1s定时

NEXT:	
	MOV	DX,C8255           
;测试out1的电平是否变高
	IN		AL,DX
	AND	AL,10H
	CMP	AL,10H
	JE		STATUS                 
;变高说明1s倒计时时间到
	JMP		REFRESH_LED           
;否则继续刷新数码管
	
ADJUST_NOW:
	XOR	AX,AX                  
;当前显示计时减6程序
	SUB	TIME_NOW,06H
	JMP	REFRESH_LED		        
;刷新数码管显示的时间

ADJUST_SHOW:
	XOR	AX,AX                  
; 当前到计时减6程序
	SUB	TIME_SHOW,06H
	JMP	ADJUST_TIME		        
;判断时间是否需要调整

STATUS:
	CMP	SI,02H
	JA		STATUS_EW
	JMP		STATUS_SN
	
STATUS_EW:
	;DEC	COUNTDOWN          
;东西方向黄灯闪烁程序
	DEC	TIME_NOW
	CMP	SI,04H
	JE		COUNTDOWN_EW
	JMP		NORM
	
COUNTDOWN_EW:
	;CMP	COUNTDOWN,05H       
;判定是否已到计时最后5秒
	CMP	TIME_NOW,05H
	JNA	TWINKLE_EW
	JMP	NORM

TWINKLE_EW:
	;MOV	AL,COUNTDOWN		
;倒计时5秒,奇数码灭,偶数亮
	MOV	AX,TIME_NOW
	MOV	BL,02H
	DIV	BL
	CMP	AH,00H		            
;判断奇偶
	JE	HIGH_EW
	JMP LOW_EW

LOW_EW:
	MOV	DX,A8255               
;南北方向红灯亮,东西方向熄灭
	MOV	AL,10H
	OUT	DX,AL
	JMP	NORM

HIGH_EW:
	MOV	DX,A8255               
;正常,状态2
	MOV	AL,18H
	OUT	DX,AL
	JMP	NORM
	
NORM:
	MOV	TIMER,01H
	DEC	TIME_SHOW
	;DEC	TIME_NOW
	CMP	TIME_NOW,00H
	JE		REFRESH_LIGHT
	JMP		REFRESH_LED
	
STATUS_SN:
	;DEC	COUNTDOWN          
;南北方向绿灯闪烁程序
	DEC	TIME_NOW
	CMP	SI,02H      		       
;南北绿，东西红为第四状态
	JE	COUNTDOWN_NS
	JMP	NORM
	
COUNTDOWN_NS:
	;CMP	COUNTDOWN,05H      
;判定是否已到计时最后5秒
	CMP	TIME_NOW,05H
	JNA	TWINKLE_SN
	JMP	NORM
	
TWINKLE_SN:			           
;南北方向绿灯闪
	;MOV	AL,COUNTDOWN       
;倒计时5秒,奇数码灭,偶数亮
	MOV	AX,TIME_NOW
	MOV	BL,02H
	DIV	BL
	CMP	AH,00H
	JZ	    HIGH_SN
	JMP   	LOW_SN

LOW_SN:
	MOV	DX,A8255   
;东西方向红灯亮,南北方向熄灭
	MOV	AL,20H
	OUT	DX,AL
	JMP	    NORM

HIGH_SN:
	MOV	DX,A8255   
;正常,状态1
	MOV	AL,24H
	OUT	DX,AL
	JMP	NORM

REFRESH_DATA:
	XOR	SI,SI       
;一次循环结束，各状态复位
	MOV	COUNTDOWN,25

REFRESH_LIGHT:
	LEA		BX,TIME_DOWN
	MOV		AX,SI
	XLAT
	MOV		TIME_NOW,AX
	
	LEA		BX,TIME_LOOP
	MOV	AX,SI
	XLAT
	MOV	TIME_SHOW,AX
	
	LEA		BX,LED
	MOV	AX,SI
	XLAT
	
	MOV	DX,A8255
	OUT	DX,AL
	INC		SI
	MOV	AX,SI
	CMP	AX,05H
	JAE		REFRESH_DATA
	JMP		REFRESH_LED
CODE	ENDS
	END START 

