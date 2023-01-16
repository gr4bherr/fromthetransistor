_start:
j reset_vector
trap_vector:
csrr t5,mcause
li t6,8
beq t5,t6,write_tohost
li t6,9
beq t5,t6,write_tohost
li t6,11
beq t5,t6,write_tohost
li t5,0
beqz t5,4
jr t5
csrr t5,mcause
bgez t5,handle_exception
j handle_exception
handle_exception:
ori gp,gp,1337
write_tohost:
auipc t5,0x1
sw gp,-60(t5)
j write_tohost
reset_vector:
li ra,0
li sp,0
li gp,0
li tp,0
li t0,0
li t1,0
li t2,0
li s0,0
li s1,0
li a0,0
li a1,0
li a2,0
li a3,0
li a4,0
li a5,0
li a6,0
li a7,0
li s2,0
li s3,0
li s4,0
li s5,0
li s6,0
li s7,0
li s8,0
li s9,0
li s10,0
li s11,0
li t3,0
li t4,0
li t5,0
li t6,0
csrr a0,mhartid
bnez a0,0
auipc t0,0x0
addi t0,t0,16
csrw mtvec,t0
csrwi satp,0
auipc t0,0x0
addi t0,t0,32
csrw mtvec,t0
lui t0,0x80000
addi t0,t0,-1
csrw pmpaddr0,t0
li t0,31
csrw pmpcfg0,t0
csrwi mie,0
auipc t0,0x0
addi t0,t0,20
csrw mtvec,t0
csrwi medeleg,0
csrwi mideleg,0
li gp,0
auipc t0,0x0
addi t0,t0,-276
csrw mtvec,t0
li a0,1
slli a0,a0,0x1f
bltz a0,12
fence
li gp,1
li a7,93
li a0,0
ecall
li t0,0
beqz t0,10
csrw stvec,t0
lui t0,0xb
addi t0,t0,265
csrw medeleg,t0
csrwi mstatus,0
auipc t0,0x0
addi t0,t0,20
csrw mepc,t0
csrr a0,mhartid
mret
test_2:
li gp,2
auipc ra,0x2
addi ra,ra,-376
li sp,170
auipc a5,0x0
addi a5,a5,20
sh sp,0(ra)
lh a4,0(ra)
j 4
mv a4,sp
li t2,170
bne a4,t2,fail
test_3:
li gp,3
auipc ra,0x2
addi ra,ra,-424
lui sp,0xffffb
addi sp,sp,-1536
auipc a5,0x0
addi a5,a5,20
sh sp,2(ra)
lh a4,2(ra)
j 4
mv a4,sp
lui t2,0xffffb
addi t2,t2,-1536
bne a4,t2,fail
test_4:
li gp,4
auipc ra,0x2
addi ra,ra,-480
lui sp,0xbeef1
addi sp,sp,-1376
auipc a5,0x0
addi a5,a5,20
sh sp,4(ra)
lw a4,4(ra)
j 4
mv a4,sp
lui t2,0xbeef1
addi t2,t2,-1376
bne a4,t2,fail
test_5:
li gp,5
auipc ra,0x2
addi ra,ra,-536
lui sp,0xffffa
addi sp,sp,10
auipc a5,0x0
addi a5,a5,20
sh sp,6(ra)
lh a4,6(ra)
j 4
mv a4,sp
lui t2,0xffffa
addi t2,t2,10
bne a4,t2,fail
test_6:
li gp,6
auipc ra,0x2
addi ra,ra,-578
li sp,170
auipc a5,0x0
addi a5,a5,20
sh sp,-6(ra)
lh a4,-6(ra)
j 4
mv a4,sp
li t2,170
bne a4,t2,fail
test_7:
li gp,7
auipc ra,0x2
addi ra,ra,-626
lui sp,0xffffb
addi sp,sp,-1536
auipc a5,0x0
addi a5,a5,20
sh sp,-4(ra)
lh a4,-4(ra)
j 4
mv a4,sp
lui t2,0xffffb
addi t2,t2,-1536
bne a4,t2,fail
test_8:
li gp,8
auipc ra,0x2
addi ra,ra,-682
lui sp,0x1
addi sp,sp,-1376
auipc a5,0x0
addi a5,a5,20
sh sp,-2(ra)
lh a4,-2(ra)
j 4
mv a4,sp
lui t2,0x1
addi t2,t2,-1376
bne a4,t2,fail
test_9:
li gp,9
auipc ra,0x2
addi ra,ra,-738
lui sp,0xffffa
addi sp,sp,10
auipc a5,0x0
addi a5,a5,20
sh sp,0(ra)
lh a4,0(ra)
j 4
mv a4,sp
lui t2,0xffffa
addi t2,t2,10
bne a4,t2,fail
test_10:
li gp,10
auipc ra,0x2
addi ra,ra,-792
lui sp,0x12345
addi sp,sp,1656
addi tp,ra,-32
sh sp,32(tp)
lh t0,0(ra)
lui t2,0x5
addi t2,t2,1656
bne t0,t2,fail
test_11:
li gp,11
auipc ra,0x2
addi ra,ra,-836
lui sp,0x3
addi sp,sp,152
addi ra,ra,-5
sh sp,7(ra)
auipc tp,0x2
addi tp,tp,-858
lh t0,0(tp)
lui t2,0x3
addi t2,t2,152
bne t0,t2,fail
test_12:
li gp,12
li tp,0
lui ra,0xffffd
addi ra,ra,-803
auipc sp,0x2
addi sp,sp,-916
sh ra,0(sp)
lh a4,0(sp)
lui t2,0xffffd
addi t2,t2,-803
bne a4,t2,fail
addi tp,tp,1
li t0,2
bne tp,t0,-22
test_13:
li gp,13
li tp,0
lui ra,0xffffc
addi ra,ra,-819
auipc sp,0x2
addi sp,sp,-972
nop
sh ra,2(sp)
lh a4,2(sp)
lui t2,0xffffc
addi t2,t2,-819
bne a4,t2,fail
addi tp,tp,1
li t0,2
bne tp,t0,-24
test_14:
li gp,14
li tp,0
lui ra,0xffffc
addi ra,ra,-1076
auipc sp,0x2
addi sp,sp,-1032
nop
nop
sh ra,4(sp)
lh a4,4(sp)
lui t2,0xffffc
addi t2,t2,-1076
bne a4,t2,fail
addi tp,tp,1
li t0,2
bne tp,t0,-26
test_15:
li gp,15
li tp,0
lui ra,0xffffb
addi ra,ra,-1092
nop
auipc sp,0x2
addi sp,sp,-1100
sh ra,6(sp)
lh a4,6(sp)
lui t2,0xffffb
addi t2,t2,-1092
bne a4,t2,fail
addi tp,tp,1
li t0,2
bne tp,t0,-24
test_16:
li gp,16
li tp,0
lui ra,0xffffb
addi ra,ra,-1349
nop
auipc sp,0x2
addi sp,sp,-1160
nop
sh ra,8(sp)
lh a4,8(sp)
lui t2,0xffffb
addi t2,t2,-1349
bne a4,t2,fail
addi tp,tp,1
li t0,2
bne tp,t0,-26
test_17:
li gp,17
li tp,0
lui ra,0xffffe
addi ra,ra,-1365
nop
nop
auipc sp,0x2
addi sp,sp,-1228
sh ra,10(sp)
lh a4,10(sp)
lui t2,0xffffe
addi t2,t2,-1365
bne a4,t2,fail
addi tp,tp,1
li t0,2
bne tp,t0,-26
test_18:
li gp,18
li tp,0
auipc sp,0x2
addi sp,sp,-1276
lui ra,0x2
addi ra,ra,563
sh ra,0(sp)
lh a4,0(sp)
lui t2,0x2
addi t2,t2,563
bne a4,t2,fail
addi tp,tp,1
li t0,2
bne tp,t0,-22
test_19:
li gp,19
li tp,0
auipc sp,0x2
addi sp,sp,-1332
lui ra,0x1
addi ra,ra,547
nop
sh ra,2(sp)
lh a4,2(sp)
lui t2,0x1
addi t2,t2,547
bne a4,t2,fail
addi tp,tp,1
li t0,2
bne tp,t0,-24
test_20:
li gp,20
li tp,0
auipc sp,0x2
addi sp,sp,-1392
lui ra,0x1
addi ra,ra,290
nop
nop
sh ra,4(sp)
lh a4,4(sp)
lui t2,0x1
addi t2,t2,290
bne a4,t2,fail
addi tp,tp,1
li t0,2
bne tp,t0,-26
test_21:
li gp,21
li tp,0
auipc sp,0x2
addi sp,sp,-1456
nop
li ra,274
sh ra,6(sp)
lh a4,6(sp)
li t2,274
bne a4,t2,fail
addi tp,tp,1
li t0,2
bne tp,t0,-20
test_22:
li gp,22
li tp,0
auipc sp,0x2
addi sp,sp,-1508
nop
li ra,17
nop
sh ra,8(sp)
lh a4,8(sp)
li t2,17
bne a4,t2,fail
addi tp,tp,1
li t0,2
bne tp,t0,-22
test_23:
li gp,23
li tp,0
auipc sp,0x2
addi sp,sp,-1564
nop
nop
lui ra,0x3
addi ra,ra,1
sh ra,10(sp)
lh a4,10(sp)
lui t2,0x3
addi t2,t2,1
bne a4,t2,fail
addi tp,tp,1
li t0,2
bne tp,t0,-26
lui a0,0xc
addi a0,a0,-273
auipc a1,0x2
addi a1,a1,-1628
sh a0,6(a1)
bne zero,gp,pass
fail:
fence
beqz gp,0
slli gp,gp,0x1
ori gp,gp,1
li a7,93
mv a0,gp
ecall
pass:
fence
li gp,1
li a7,93
li a0,0
ecall
unimp
