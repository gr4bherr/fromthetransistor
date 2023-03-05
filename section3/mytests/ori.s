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
lui ra,0xff010
addi ra,ra,-256
ori a4,ra,-241
li t2,-241
bne a4,t2,fail
test_3:
li gp,3
lui ra,0xff01
addi ra,ra,-16
ori a4,ra,240
lui t2,0xff01
addi t2,t2,-16
bne a4,t2,fail
test_4:
li gp,4
lui ra,0xff0
addi ra,ra,255
ori a4,ra,1807
lui t2,0xff0
addi t2,t2,2047
bne a4,t2,fail
test_5:
li gp,5
lui ra,0xf00ff
addi ra,ra,15
ori a4,ra,240
lui t2,0xf00ff
addi t2,t2,255
bne a4,t2,fail
test_6:
li gp,6
lui ra,0xff010
addi ra,ra,-256
ori ra,ra,240
lui t2,0xff010
addi t2,t2,-16
bne ra,t2,fail
test_7:
li gp,7
li tp,0
lui ra,0xff01
addi ra,ra,-16
ori a4,ra,240
mv t1,a4
addi tp,tp,1
li t0,2
bne tp,t0,-24
lui t2,0xff01
addi t2,t2,-16
bne t1,t2,fail
test_8:
li gp,8
li tp,0
lui ra,0xff0
addi ra,ra,255
ori a4,ra,1807
nop
mv t1,a4
addi tp,tp,1
li t0,2
bne tp,t0,-28
lui t2,0xff0
addi t2,t2,2047
bne t1,t2,fail
test_9:
li gp,9
li tp,0
lui ra,0xf00ff
addi ra,ra,15
ori a4,ra,240
nop
nop
mv t1,a4
addi tp,tp,1
li t0,2
bne tp,t0,-32
lui t2,0xf00ff
addi t2,t2,255
bne t1,t2,fail
test_10:
li gp,10
li tp,0
lui ra,0xff01
addi ra,ra,-16
ori a4,ra,240
addi tp,tp,1
li t0,2
bne tp,t0,-20
lui t2,0xff01
addi t2,t2,-16
bne a4,t2,fail
test_11:
li gp,11
li tp,0
lui ra,0xff0
addi ra,ra,255
nop
ori a4,ra,-241
addi tp,tp,1
li t0,2
bne tp,t0,-24
li t2,-1
bne a4,t2,fail
test_12:
li gp,12
li tp,0
lui ra,0xf00ff
addi ra,ra,15
nop
nop
ori a4,ra,240
addi tp,tp,1
li t0,2
bne tp,t0,-28
lui t2,0xf00ff
addi t2,t2,255
bne a4,t2,fail
test_13:
li gp,13
ori ra,zero,240
li t2,240
bne ra,t2,fail
test_14:
li gp,14
lui ra,0xff0
addi ra,ra,255
ori zero,ra,1807
li t2,0
bne zero,t2,fail
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
