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
li sp,0
add a4,ra,sp
li t2,0
bne a4,t2,fail
test_3:
li gp,3
li ra,1
li sp,1
add a4,ra,sp
li t2,2
bne a4,t2,fail
test_4:
li gp,4
li ra,3
li sp,7
add a4,ra,sp
li t2,10
bne a4,t2,fail
test_5:
li gp,5
li ra,0
lui sp,0xffff8
add a4,ra,sp
lui t2,0xffff8
bne a4,t2,fail
test_6:
li gp,6
lui ra,0x80000
li sp,0
add a4,ra,sp
lui t2,0x80000
bne a4,t2,fail
test_7:
li gp,7
lui ra,0x80000
lui sp,0xffff8
add a4,ra,sp
lui t2,0x7fff8
bne a4,t2,fail
test_8:
li gp,8
li ra,0
lui sp,0x8
addi sp,sp,-1
add a4,ra,sp
lui t2,0x8
addi t2,t2,-1
bne a4,t2,fail
test_9:
li gp,9
lui ra,0x80000
addi ra,ra,-1
li sp,0
add a4,ra,sp
lui t2,0x80000
addi t2,t2,-1
bne a4,t2,fail
test_10:
li gp,10
lui ra,0x80000
addi ra,ra,-1
lui sp,0x8
addi sp,sp,-1
add a4,ra,sp
lui t2,0x80008
addi t2,t2,-2
bne a4,t2,fail
test_11:
li gp,11
lui ra,0x80000
lui sp,0x8
addi sp,sp,-1
add a4,ra,sp
lui t2,0x80008
addi t2,t2,-1
bne a4,t2,fail
test_12:
li gp,12
lui ra,0x80000
addi ra,ra,-1
lui sp,0xffff8
add a4,ra,sp
lui t2,0x7fff8
addi t2,t2,-1
bne a4,t2,fail
test_13:
li gp,13
li ra,0
li sp,-1
add a4,ra,sp
li t2,-1
bne a4,t2,fail
test_14:
li gp,14
li ra,-1
li sp,1
add a4,ra,sp
li t2,0
bne a4,t2,fail
test_15:
li gp,15
li ra,-1
li sp,-1
add a4,ra,sp
li t2,-2
bne a4,t2,fail
test_16:
li gp,16
li ra,1
lui sp,0x80000
addi sp,sp,-1
add a4,ra,sp
lui t2,0x80000
bne a4,t2,fail
test_17:
li gp,17
li ra,13
li sp,11
add ra,ra,sp
li t2,24
bne ra,t2,fail
test_18:
li gp,18
li ra,14
li sp,11
add sp,ra,sp
li t2,25
bne sp,t2,fail
test_19:
li gp,19
li ra,13
add ra,ra,ra
li t2,26
bne ra,t2,fail
test_20:
li gp,20
li tp,0
li ra,13
li sp,11
add a4,ra,sp
mv t1,a4
addi tp,tp,1
li t0,2
bne tp,t0,-24
li t2,24
bne t1,t2,fail
test_21:
li gp,21
li tp,0
li ra,14
li sp,11
add a4,ra,sp
nop
mv t1,a4
addi tp,tp,1
li t0,2
bne tp,t0,-28
li t2,25
bne t1,t2,fail
test_22:
li gp,22
li tp,0
li ra,15
li sp,11
add a4,ra,sp
nop
nop
mv t1,a4
addi tp,tp,1
li t0,2
bne tp,t0,-32
li t2,26
bne t1,t2,fail
test_23:
li gp,23
li tp,0
li ra,13
li sp,11
add a4,ra,sp
addi tp,tp,1
li t0,2
bne tp,t0,-20
li t2,24
bne a4,t2,fail
test_24:
li gp,24
li tp,0
li ra,14
li sp,11
nop
add a4,ra,sp
addi tp,tp,1
li t0,2
bne tp,t0,-24
li t2,25
bne a4,t2,fail
test_25:
li gp,25
li tp,0
li ra,15
li sp,11
nop
nop
add a4,ra,sp
addi tp,tp,1
li t0,2
bne tp,t0,-28
li t2,26
bne a4,t2,fail
test_26:
li gp,26
li tp,0
li ra,13
nop
li sp,11
add a4,ra,sp
addi tp,tp,1
li t0,2
bne tp,t0,-24
li t2,24
bne a4,t2,fail
test_27:
li gp,27
li tp,0
li ra,14
nop
li sp,11
nop
add a4,ra,sp
addi tp,tp,1
li t0,2
bne tp,t0,-28
li t2,25
bne a4,t2,fail
test_28:
li gp,28
li tp,0
li ra,15
nop
nop
li sp,11
add a4,ra,sp
addi tp,tp,1
li t0,2
bne tp,t0,-28
li t2,26
bne a4,t2,fail
test_29:
li gp,29
li tp,0
li sp,11
li ra,13
add a4,ra,sp
addi tp,tp,1
li t0,2
bne tp,t0,-20
li t2,24
bne a4,t2,fail
test_30:
li gp,30
li tp,0
li sp,11
li ra,14
nop
add a4,ra,sp
addi tp,tp,1
li t0,2
bne tp,t0,-24
li t2,25
bne a4,t2,fail
test_31:
li gp,31
li tp,0
li sp,11
li ra,15
nop
nop
add a4,ra,sp
addi tp,tp,1
li t0,2
bne tp,t0,-28
li t2,26
bne a4,t2,fail
test_32:
li gp,32
li tp,0
li sp,11
nop
li ra,13
add a4,ra,sp
addi tp,tp,1
li t0,2
bne tp,t0,-24
li t2,24
bne a4,t2,fail
test_33:
li gp,33
li tp,0
li sp,11
nop
li ra,14
nop
add a4,ra,sp
addi tp,tp,1
li t0,2
bne tp,t0,-28
li t2,25
bne a4,t2,fail
test_34:
li gp,34
li tp,0
li sp,11
nop
nop
li ra,15
add a4,ra,sp
addi tp,tp,1
li t0,2
bne tp,t0,-28
li t2,26
bne a4,t2,fail
test_35:
li gp,35
li ra,15
add sp,zero,ra
li t2,15
bne sp,t2,fail
test_36:
li gp,36
li ra,32
add sp,ra,zero
li t2,32
bne sp,t2,fail
test_37:
li gp,37
add ra,zero,zero
li t2,0
bne ra,t2,fail
test_38:
li gp,38
li ra,16
li sp,30
add zero,ra,sp
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