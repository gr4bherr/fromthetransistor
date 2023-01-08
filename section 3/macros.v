`define PC 15
`define CPSR 16

`define N 31
`define Z 30
`define C 29
`define V 28

`define LSL 0 // (ASL)
`define LSR 1 
`define ASR 2
`define ROR 3 // (RRX)


`define EQ 0
`define NE 1
`define CS 2
`define CC 3
`define MI 4
`define PL 5
`define VS 6
`define VC 7
`define HI 8
`define LS 9
`define GE 10
`define LT 11
`define GT 12
`define LE 13
`define AL 14

`define AND 0
`define EOR 1
`define SUB 2
`define RSB 3
`define ADD 4
`define ADC 5
`define SBC 6
`define RSC 7
`define TST 8
`define TEQ 9
`define CMP 10
`define CMN 11
`define ORR 12
`define MOV 13
`define BIC 14
`define MVN 15

// CONTROL SIGNALS (ctrl)
// todo reorder and clean up
// memory
`define c_memwrite 0
// address register
`define c_addrwrite 1
`define c_addrin1 2
`define c_addrin2 3
`define c_addrout1 4
`define c_addrout2 5
// address incrementer 
`define c_incrementenable 6
// register bank
`define c_regwrite 8
`define c_regin1 9
`define c_regin2 10
`define c_regpcwrite 11
`define c_memout 12
`define c_instructionRegisterout 13
`define c_instructionRegisterin 14
`define c_dataregin 15
`define c_dataregout 16
`define c_shiftbyimm 17
`define c_shiftvalimm 18
`define c_setflags 19
`define c_pcchange 20