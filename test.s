mov r1, #24
mov r2, #28
mov r3, #4
mov r4, #16
mov r6, #0x1a
str r1,[r2,r4]!
str r1,[r2],r4
ldr r1,[r2,#16]
ldr r1,[r2,r3,lsl#2]
ldr r1,[r6,#8]