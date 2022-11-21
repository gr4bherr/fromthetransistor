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
MSR CPSR_fc,#0xF0000000

@MSR   CPSR_all,Rm
@MSR   CPSR_flg,Rm
@MSR   CPSR_flg,#0xA0000000
@MRS Rd,CPSR

@In privileged modes the instructions behave as follows:
@MSR   CPSR_all,Rm
@MSR   CPSR_flg,Rm
@MSR   CPSR_flg,#0x50000000
@MRS   Rd,CPSR
@MSR   SPSR_all,Rm
@MSR   SPSR_flg,Rm
@MSR   SPSR_flg,#0xC0000000
@MRS Rd,SPSR