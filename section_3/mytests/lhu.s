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
beqz t5,8
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
bltz a0,24
fence
li gp,1
li a7,93
li a0,0
ecall
li t0,0
beqz t0,20
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
li a5,255
auipc ra,0x2
addi ra,ra,-380
lhu a4,0(ra)
li t2,255
bne a4,t2,fail
test_3:
li gp,3
lui a5,0x10
addi a5,a5,-256
auipc ra,0x2
addi ra,ra,-412
lhu a4,2(ra)
lui t2,0x10
addi t2,t2,-256
bne a4,t2,fail
test_4:
li gp,4
lui a5,0x1
addi a5,a5,-16
auipc ra,0x2
addi ra,ra,-448
lhu a4,4(ra)
lui t2,0x1
addi t2,t2,-16
bne a4,t2,fail
test_5:
li gp,5
lui a5,0xf
addi a5,a5,15
auipc ra,0x2
addi ra,ra,-484
lhu a4,6(ra)
lui t2,0xf
addi t2,t2,15
bne a4,t2,fail
test_6:
li gp,6
li a5,255
auipc ra,0x2
addi ra,ra,-510
lhu a4,-6(ra)
li t2,255
bne a4,t2,fail
test_7:
li gp,7
lui a5,0x10
addi a5,a5,-256
auipc ra,0x2
addi ra,ra,-542
lhu a4,-4(ra)
lui t2,0x10
addi t2,t2,-256
bne a4,t2,fail
test_8:
li gp,8
lui a5,0x1
addi a5,a5,-16
auipc ra,0x2
addi ra,ra,-578
lhu a4,-2(ra)
lui t2,0x1
addi t2,t2,-16
bne a4,t2,fail
test_9:
li gp,9
lui a5,0xf
addi a5,a5,15
auipc ra,0x2
addi ra,ra,-614
lhu a4,0(ra)
lui t2,0xf
addi t2,t2,15
bne a4,t2,fail
test_10:
li gp,10
auipc ra,0x2
addi ra,ra,-648
addi ra,ra,-32
lhu t0,32(ra)
li t2,255
bne t0,t2,fail
test_11:
li gp,11
auipc ra,0x2
addi ra,ra,-676
addi ra,ra,-5
lhu t0,7(ra)
lui t2,0x10
addi t2,t2,-256
bne t0,t2,fail
test_12:
li gp,12
li tp,0
auipc ra,0x2
addi ra,ra,-710
lhu a4,2(ra)
mv t1,a4
lui t2,0x1
addi t2,t2,-16
bne t1,t2,fail
addi tp,tp,1
li t0,2
bne tp,t0,-36
test_13:
li gp,13
li tp,0
auipc ra,0x2
addi ra,ra,-756
lhu a4,2(ra)
nop
mv t1,a4
lui t2,0xf
addi t2,t2,15
bne t1,t2,fail
addi tp,tp,1
li t0,2
bne tp,t0,-40
test_14:
li gp,14
li tp,0
auipc ra,0x2
addi ra,ra,-812
lhu a4,2(ra)
nop
nop
mv t1,a4
lui t2,0x10
addi t2,t2,-256
bne t1,t2,fail
addi tp,tp,1
li t0,2
bne tp,t0,-44
test_15:
li gp,15
li tp,0
auipc ra,0x2
addi ra,ra,-866
lhu a4,2(ra)
lui t2,0x1
addi t2,t2,-16
bne a4,t2,fail
addi tp,tp,1
li t0,2
bne tp,t0,-32
test_16:
li gp,16
li tp,0
auipc ra,0x2
addi ra,ra,-908
nop
lhu a4,2(ra)
lui t2,0xf
addi t2,t2,15
bne a4,t2,fail
addi tp,tp,1
li t0,2
bne tp,t0,-36
test_17:
li gp,17
li tp,0
auipc ra,0x2
addi ra,ra,-960
nop
nop
lhu a4,2(ra)
lui t2,0x10
addi t2,t2,-256
bne a4,t2,fail
addi tp,tp,1
li t0,2
bne tp,t0,-40
test_18:
li gp,18
auipc t0,0x2
addi t0,t0,-1008
lhu sp,0(t0)
li sp,2
li t2,2
bne sp,t2,fail
test_19:
li gp,19
auipc t0,0x2
addi t0,t0,-1036
lhu sp,0(t0)
nop
li sp,2
li t2,2
bne sp,t2,fail
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
