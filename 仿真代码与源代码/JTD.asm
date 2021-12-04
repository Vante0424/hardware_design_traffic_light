IOY0         EQU   0600H          ;ƬѡIOY0��Ӧ�Ķ˿�ʼ��ַ
MY8255_A     EQU   IOY0+00H*2     ;8255��A�ڵ�ַ
MY8255_B     EQU   IOY0+01H*2     ;8255��B�ڵ�ַ
MY8255_C     EQU   IOY0+02H*2     ;8255��C�ڵ�ַ
MY8255_MODE  EQU   IOY0+03H*2     ;8255�Ŀ��ƼĴ�����ַ


CODE	SEGMENT
		ASSUME CS:CODE
START:	MOV DX, MY8255_MODE
		MOV AL, 10000001B
		OUT DX, AL       	;8255������д��
		MOV AL,00110000B
		MOV DX,0646H
		OUT DX,AL         	;8254������д��
		MOV DX,0640H
		MOV AL,00H
		OUT	DX,AL
		MOV AL,48H        	;18432HZ��Ӧ������ֵ
		OUT DX,AL          	;�˿�0д�����
GLOB:	MOV	CX,3CH         		;60��
JTD:	MOV DX,MY8255_C
   		IN  AL,DX 		;��ȡ������״̬
   		AND AL,00000001B
   		CMP AL,00000001B   	;�ж�C�ڵ����һλ��״̬���ж�һ���Ƿ񵽴�
   		JC  KEEP
		DEC CX
		MOV DX,0640H
		MOV AL,00H
		OUT	DX,AL
		MOV AL,48H         ;18432HZ��Ӧ������ֵ(ʱ�䵽��1�뼼������ֵ���ã�
		OUT DX,AL   
KEEP:	    
		MOV AL,CL
		CMP AL,1EH			
		JBE	DIS			;С��30�룬�������ʾ
		SUB	AL,1EH
DIS:	XOR AH,AH
		MOV BL,0AH
		DIV BL
		CALL NUMBER
		MOV DX,MY8255_A			;ʮλ�������ʾ����
		OUT DX,AL
		MOV DX,MY8255_C
		MOV AL,01111111B
		OUT DX,AL        		;ѡ��ʮλ���ֵ������
		MOV DX,MY8255_C
		MOV AL,11111111B
		OUT DX,AL   			;�����ȫ��
		MOV AL,AH
		CALL NUMBER
		MOV DX,MY8255_A			;��λ�������ʾ����
		OUT DX,AL
		MOV DX,MY8255_C
		MOV AL,10111111B
		OUT DX,AL        		;ѡ�и�λ���ֵ������
		MOV DX,MY8255_C
		MOV AL,11111111B
		OUT DX,AL   			;�����ȫ��
		CALL LED
		
		OR	CX,CX
		JNZ JTD
		JMP GLOB

	MOV AH,4CH
	INT 21H
		
NUMBER 	PROC 	NEAR
		CMP AL,0AH
		JB	NUM
		SUB AL,0AH
NUM:	CMP AL,00000000B
		JZ ZERO
		CMP AL,00000001B
		JZ ONE
		CMP AL,00000010B
		JZ TWO
		CMP AL,00000011B
		JZ THREE
		CMP AL,00000100B
		JZ FOUR
		CMP AL,00000101B
		JZ FIVE 
		CMP AL,00000110B
		JZ SIX
		CMP AL,00000111B
		JZ SEVEN
		CMP AL,00001000B
		JZ EIGHT
		CMP AL,00001001B
		JZ NINE
		
		
ZERO:	MOV AL,3FH
		JMP PEND
ONE:	MOV AL,06H
		JMP PEND
TWO:	MOV AL,5BH
		JMP PEND
THREE: 	MOV AL,4FH
		JMP PEND
FOUR:	MOV AL,66H
		JMP PEND
FIVE:	MOV AL,6DH
		JMP PEND
SIX:	MOV AL,7DH
		JMP PEND
SEVEN:	MOV AL,07H
		JMP PEND
EIGHT: 	MOV AL,7FH
		JMP PEND
NINE:	MOV AL,6FH

PEND: 	RET
NUMBER ENDP


LED		PROC	NEAR
		
		MOV DX,MY8255_C
   		IN  AL,DX 			;��ȡ������״̬
   		AND AL,00001000B
   		CMP AL,00001000B
		JC  LED5          		;�������	
		
		CMP CX,23H			;�ж��Ƿ�Ϊǰ30����
		JA LED1
		CMP CX,1EH			;�ж���ʱ��Ƶ�
		JA LED2
		CMP CX,05H
		JA LED3
		JMP LED4
			
							
LED1:	MOV DX,MY8255_B			;�����̵�,�ϱ����
		MOV AL,00001100B
		OUT DX,AL
		JMP PEND1
LED2:	MOV DX,MY8255_B			;�����Ƶ�,�ϱ����
		MOV AL,00010100B
		OUT DX,AL
		JMP PEND1
LED3:	MOV DX,MY8255_B			;�ϱ��̵�,�������
		MOV AL,00100001B
		OUT DX,AL
		JMP PEND1
LED4:	MOV DX,MY8255_B			;�ϱ��Ƶ�,�������
		MOV AL,00100010B
		OUT DX,AL
		JMP PEND1
LED5:  MOV DX,MY8255_B         		;���������ȫ�Ǻ��
        MOV AL,00100100B
        OUT DX,AL
PEND1:	RET
LED	ENDP
			
CODE	ENDS
		END  START