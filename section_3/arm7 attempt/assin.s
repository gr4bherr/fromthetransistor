mov r1, #0xff
MRS R0,CPSR
BIC R0,R0,#0x1F
ORR R0,R0,#3
MSR CPSR,R0
MSR CPSR_flg,#0xF0000000



@movS r1, r0, lsr #2 @0
@movS r1, r0, asr #2 @0 
@movS r1, r0, ror #2 @0
@mov r0, #0xff
@movS r1, r0, lsl #2 @0
@movS r1, r0, lsr #2 @1
@movS r1, r0, asr #2 @1 
@movS r1, r0, ror #2 @1
