@ data processing
ADDEQ R2, R4, R5
TEQS R4, #3
SUB R4,R5,R7,LSR R2
SUB R4,R5,R7,LSL #4
MOV PC, R14
MOVS PC, R14
SUB R4,R5,R7,LSL #4
SUB R4,R5,R7,ASL #4
ADD R2,R1,R3,ROR #3
ADD R2,R1,R3,RRX

@ psr transfer
MRS R0,CPSR
BIC R0,R0,#0x1F
ORR R0,R0,#3
MSR CPSR,R0
MSR CPSR_flg,#0xF0000000

@ multiply
MUL         R1,R2,R3
MLAEQS      R1,R2,R3,R4

@ multiply long
UMULL R1,R4,R2,R3 
UMLALS R1,R5,R2,R3

@ single data transfer
STR R1, [R2,R4]!
STR R1, [R2],R4
LDR R1, [R2,#16]
LDR R1, [R2,R3, LSL#2] 
LDREQB R1, [R6,#5]
@ halfword and signed data transfer
LDRH R1, [R2,-R3]!
STRH R3, [R4,#14]
LDRSB R8, [R2],#-223
LDRNESH R11, [R0]

@ block data transfer
LDMFD SP!, {R0, R1,R2} 
STMIA R0, {R0-R15} 
LDMFD SP!, {R15} 
LDMFD SP!, {R15}^
STMFD R13, {R0-R14}^
STMED SP!, {R0-R3,R14}
LDMED SP!,{R0-R3,R15}

@ single data swap
SWP   R0,R1,[R2]
SWPB  R2,R3,[R4]
SWPEQ R0,R0,[R1]

@ software interrupt
SWINE 0

@ branch and exchange
BX R0
BXEQ R5

@ branch and branch with link