mov r0, #0xff000000
movS r1, r0, lsr #2
movS r1, r0, lsr #0 


@movS r1, r0, lsr #2 @0
@movS r1, r0, asr #2 @0 
@movS r1, r0, ror #2 @0
@mov r0, #0xff
@movS r1, r0, lsl #2 @0
@movS r1, r0, lsr #2 @1
@movS r1, r0, asr #2 @1 
@movS r1, r0, ror #2 @1
