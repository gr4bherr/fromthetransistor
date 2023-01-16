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
li sp,-86
auipc a5,0x0
addi a5,a5,20
sb sp,0(ra)
lb a4,0(ra)
j 4
mv a4,sp
li t2,-86
bne a4,t2,fail
test_3:
li gp,3
auipc ra,0x2
addi ra,ra,-424
li sp,0
auipc a5,0x0
addi a5,a5,20
sb sp,1(ra)
lb a4,1(ra)
j 4
mv a4,sp
li t2,0
bne a4,t2,fail
test_4:
li gp,4
auipc ra,0x2
addi ra,ra,-472
lui sp,0xfffff
addi sp,sp,-96
auipc a5,0x0
addi a5,a5,20
sb sp,2(ra)
lh a4,2(ra)
j 4
mv a4,sp
lui t2,0xfffff
addi t2,t2,-96
bne a4,t2,fail
test_5:
li gp,5
auipc ra,0x2
addi ra,ra,-528
li sp,10
auipc a5,0x0
addi a5,a5,20
sb sp,3(ra)
lb a4,3(ra)
j 4
mv a4,sp
li t2,10
bne a4,t2,fail
test_6:
li gp,6
auipc ra,0x2
addi ra,ra,-569
li sp,-86
auipc a5,0x0
addi a5,a5,20
sb sp,-3(ra)
lb a4,-3(ra)
j 4
mv a4,sp
li t2,-86
bne a4,t2,fail
test_7:
li gp,7
auipc ra,0x2
addi ra,ra,-617
li sp,0
auipc a5,0x0
addi a5,a5,20
sb sp,-2(ra)
lb a4,-2(ra)
j 4
mv a4,sp
li t2,0
bne a4,t2,fail
test_8:
li gp,8
auipc ra,0x2
addi ra,ra,-665
li sp,-96
auipc a5,0x0
addi a5,a5,20
sb sp,-1(ra)
lb a4,-1(ra)
j 4
mv a4,sp
li t2,-96
bne a4,t2,fail
test_9:
li gp,9
auipc ra,0x2
addi ra,ra,-713
li sp,10
auipc a5,0x0
addi a5,a5,20
sb sp,0(ra)
lb a4,0(ra)
j 4
mv a4,sp
li t2,10
bne a4,t2,fail
test_10:
li gp,10
auipc ra,0x2
addi ra,ra,-760
lui sp,0x12345
addi sp,sp,1656
addi tp,ra,-32
sb sp,32(tp)
lb t0,0(ra)
li t2,120
bne t0,t2,fail
test_11:
li gp,11
auipc ra,0x2
addi ra,ra,-800
lui sp,0x3
addi sp,sp,152
addi ra,ra,-6
sb sp,7(ra)
auipc tp,0x2
addi tp,tp,-823
lb t0,0(tp)
li t2,-104
bne t0,t2,fail
test_12:
li gp,12
li tp,0
li ra,-35
auipc sp,0x2
addi sp,sp,-864
sb ra,0(sp)
lb a4,0(sp)
li t2,-35
bne a4,t2,fail
addi tp,tp,1
li t0,2
bne tp,t0,-18
test_13:
li gp,13
li tp,0
li ra,-51
auipc sp,0x2
addi sp,sp,-912
nop
sb ra,1(sp)
lb a4,1(sp)
li t2,-51
bne a4,t2,fail
addi tp,tp,1
li t0,2
bne tp,t0,-20
test_14:
li gp,14
li tp,0
li ra,-52
auipc sp,0x2
addi sp,sp,-964
nop
nop
sb ra,2(sp)
lb a4,2(sp)
li t2,-52
bne a4,t2,fail
addi tp,tp,1
li t0,2
bne tp,t0,-22
test_15:
li gp,15
li tp,0
li ra,-68
nop
auipc sp,0x2
addi sp,sp,-1024
sb ra,3(sp)
lb a4,3(sp)
li t2,-68
bne a4,t2,fail
addi tp,tp,1
li t0,2
bne tp,t0,-20
test_16:
li gp,16
li tp,0
li ra,-69
nop
auipc sp,0x2
addi sp,sp,-1076
nop
sb ra,4(sp)
lb a4,4(sp)
li t2,-69
bne a4,t2,fail
addi tp,tp,1
li t0,2
bne tp,t0,-22
test_17:
li gp,17
li tp,0
li ra,-85
nop
nop
auipc sp,0x2
addi sp,sp,-1136
sb ra,5(sp)
lb a4,5(sp)
li t2,-85
bne a4,t2,fail
addi tp,tp,1
li t0,2
bne tp,t0,-22
test_18:
li gp,18
li tp,0
auipc sp,0x2
addi sp,sp,-1180
li ra,51
sb ra,0(sp)
lb a4,0(sp)
li t2,51
bne a4,t2,fail
addi tp,tp,1
li t0,2
bne tp,t0,-18
test_19:
li gp,19
li tp,0
auipc sp,0x2
addi sp,sp,-1228
li ra,35
nop
sb ra,1(sp)
lb a4,1(sp)
li t2,35
bne a4,t2,fail
addi tp,tp,1
li t0,2
bne tp,t0,-20
test_20:
li gp,20
li tp,0
auipc sp,0x2
addi sp,sp,-1280
li ra,34
nop
nop
sb ra,2(sp)
lb a4,2(sp)
li t2,34
bne a4,t2,fail
addi tp,tp,1
li t0,2
bne tp,t0,-22
test_21:
li gp,21
li tp,0
auipc sp,0x2
addi sp,sp,-1336
nop
li ra,18
sb ra,3(sp)
lb a4,3(sp)
li t2,18
bne a4,t2,fail
addi tp,tp,1
li t0,2
bne tp,t0,-20
test_22:
li gp,22
li tp,0
auipc sp,0x2
addi sp,sp,-1388
nop
li ra,17
nop
sb ra,4(sp)
lb a4,4(sp)
li t2,17
bne a4,t2,fail
addi tp,tp,1
li t0,2
bne tp,t0,-22
test_23:
li gp,23
li tp,0
auipc sp,0x2
addi sp,sp,-1444
nop
nop
li ra,1
sb ra,5(sp)
lb a4,5(sp)
li t2,1
bne a4,t2,fail
addi tp,tp,1
li t0,2
bne tp,t0,-22
li a0,239
auipc a1,0x2
addi a1,a1,-1496
sb a0,3(a1)
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
