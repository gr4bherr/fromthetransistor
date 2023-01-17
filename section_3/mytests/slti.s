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
li ra,0
slti a4,ra,0
li t2,0
bne a4,t2,fail
test_3:
li gp,3
li ra,1
slti a4,ra,1
li t2,0
bne a4,t2,fail
test_4:
li gp,4
li ra,3
slti a4,ra,7
li t2,1
bne a4,t2,fail
test_5:
li gp,5
li ra,7
slti a4,ra,3
li t2,0
bne a4,t2,fail
test_6:
li gp,6
li ra,0
slti a4,ra,-2048
li t2,0
bne a4,t2,fail
test_7:
li gp,7
lui ra,0x80000
slti a4,ra,0
li t2,1
bne a4,t2,fail
test_8:
li gp,8
lui ra,0x80000
slti a4,ra,-2048
li t2,1
bne a4,t2,fail
test_9:
li gp,9
li ra,0
slti a4,ra,2047
li t2,1
bne a4,t2,fail
test_10:
li gp,10
lui ra,0x80000
addi ra,ra,-1
slti a4,ra,0
li t2,0
bne a4,t2,fail
test_11:
li gp,11
lui ra,0x80000
addi ra,ra,-1
slti a4,ra,2047
li t2,0
bne a4,t2,fail
test_12:
li gp,12
lui ra,0x80000
slti a4,ra,2047
li t2,1
bne a4,t2,fail
test_13:
li gp,13
lui ra,0x80000
addi ra,ra,-1
slti a4,ra,-2048
li t2,0
bne a4,t2,fail
test_14:
li gp,14
li ra,0
slti a4,ra,-1
li t2,0
bne a4,t2,fail
test_15:
li gp,15
li ra,-1
slti a4,ra,1
li t2,1
bne a4,t2,fail
test_16:
li gp,16
li ra,-1
slti a4,ra,-1
li t2,0
bne a4,t2,fail
test_17:
li gp,17
li ra,11
slti ra,ra,13
li t2,1
bne ra,t2,fail
test_18:
li gp,18
li tp,0
li ra,15
slti a4,ra,10
mv t1,a4
addi tp,tp,1
li t0,2
bne tp,t0,-20
li t2,0
bne t1,t2,fail
test_19:
li gp,19
li tp,0
li ra,10
slti a4,ra,16
nop
mv t1,a4
addi tp,tp,1
li t0,2
bne tp,t0,-24
li t2,1
bne t1,t2,fail
test_20:
li gp,20
li tp,0
li ra,16
slti a4,ra,9
nop
nop
mv t1,a4
addi tp,tp,1
li t0,2
bne tp,t0,-28
li t2,0
bne t1,t2,fail
test_21:
li gp,21
li tp,0
li ra,11
slti a4,ra,15
addi tp,tp,1
li t0,2
bne tp,t0,-16
li t2,1
bne a4,t2,fail
test_22:
li gp,22
li tp,0
li ra,17
nop
slti a4,ra,8
addi tp,tp,1
li t0,2
bne tp,t0,-20
li t2,0
bne a4,t2,fail
test_23:
li gp,23
li tp,0
li ra,12
nop
nop
slti a4,ra,14
addi tp,tp,1
li t0,2
bne tp,t0,-24
li t2,1
bne a4,t2,fail
test_24:
li gp,24
slti ra,zero,-1
li t2,0
bne ra,t2,fail
test_25:
li gp,25
lui ra,0xff0
addi ra,ra,255
slti zero,ra,-1
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
