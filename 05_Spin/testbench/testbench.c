/*
 * Testbench for the alu
 * (c) Pacito.Sys
 */
#include <stdio.h>
#include <string.h>

#define NUM_VALUES 8
#define MAX_POS    0x7fffffff
#define MAX_NEG    0x80000000
#define MAX_NEG1   0x80000001

char *opcodeName[] = {
"RDBYTE", "RDWORD","RDLONG","HUBOP","UNDEF0","UNDEF1","UNDEF2","UNDEF3",
"ROR","ROL","SHR","SHL","RCR","RCL","SAR","REV",
"MINS", "MAXS", "MIN","MAX","MOVS","MOVD","MOVI","JMPRET",
"AND","ANDN","OR","XOR","MUXC","MUXNC","MUXNZ","MUXZ",
"ADD","SUB","ADDABS","SUBABS","SUMC","SUMNC","SUMZ","SUMNZ",
"MOV","NEG","ABS","ABSNEG","NEGC","NEGZ","NEGNC","NEGNZ",
"CMPS","CMPSX","ADDX","SUBX","ADDS","SUBS","ADDSX","SUBSX",
"CMPSUB","DJNZ","TJNZ","TJZ","WAITPEQ","WAITPNE","WAITCNT","WAITVID" };

#ifdef CSPIN_FLAG
int test_values[NUM_VALUES] = { 0, 1, 2, MAX_POS, MAX_NEG, MAX_NEG1, -2, -1 };
#else
int test_values[] = { 0, 1, 2, 0x7fffffff, 0x80000000, 0x80000001, 0xfffffffe, 0xffffffff };
#endif

int mailbox[4];

void alu(int opcode, int S, int D, int C, int Z, int *alu_q, int *alu_c, int *alu_z)
{
    mailbox[1] = D;
    mailbox[2] = S;
    mailbox[3] = (Z << 1) | C;
    mailbox[0] = opcode;
#ifdef CSPIN_FLAG
    while(mailbox[0]);
#endif
    *alu_q = mailbox[1];
    *alu_c = mailbox[3] & 1;
    *alu_z = (mailbox[3] >> 1) & 1;
}

void writeTest(int opcode)
{
    int testnum = 0;
    int s, d, S, D, C, Z;
    int alu_q, alu_c, alu_z;
    char name[7];
    strcpy(name, "      ");
    memcpy(name, opcodeName[opcode], strlen(opcodeName[opcode]));
    printf("%s", name);
#ifdef PRINT_INPUT_VALUES
    printf(" ---D---- ---S---- CZ = ");
#endif
    printf("---Q---- CZ\n");
    for (s = 0; s < NUM_VALUES; s++)
    {
        S = test_values[s];
        for (d = 0; d < NUM_VALUES; d++)
        {
            D = test_values[d];
            for (C = 0; C <= 1; C++)
            {
                for (Z = 0; Z <= 1; Z++)
                {
                    alu(opcode, S, D, C, Z, &alu_q, &alu_c, &alu_z);
                    printf("%02x %02x", testnum++, opcode);
#ifdef PRINT_INPUT_VALUES
                    printf("  %08x %08x %1x%1x =", D, S, C, Z);
#endif
                    printf(" %08x %1x%1x\n", alu_q, alu_c, alu_z);
                }
            }
        }
    }
}

int main(void)
{
    int j;
#ifdef CSPIN_FLAG
    start_alu();
#endif
    for (j = 8; j < 57; j++)
    {
        if (j == 23) continue;
        writeTest(j);
    }
#ifdef CSPIN_FLAG
    stop_alu();
#endif
    return 0;
}

/* INLINE SPIN
PUB start_alu
  mailbox[0] := 0
  cognew(@cmdloop, @mailbox)

PUB stop_alu
  cogstop(1)
  cogstop(2)

DAT
                        org     0
cmdloop                 rdlong  op, par             wz
        if_z            jmp     #cmdloop
                        shl     op, #3
                        or      op, #7
                        movi    instruct, op
                        mov     addr, par
                        add     addr, #4
                        rdlong  dst, addr
                        add     addr, #4
                        rdlong  src, addr
                        add     addr, #4
                        rdlong  flags, addr
                        shr     flags, #1           wc
                        and     flags, #1
                        xor     flags, #1           wz
instruct                mov     dst, src            wz, wc
        if_nz_and_nc    mov     flags, #0
        if_nz_and_c     mov     flags, #1
        if_z_and_nc     mov     flags, #2
        if_z_and_c      mov     flags, #3
                        wrlong  flags, addr
                        sub     addr, #8
                        wrlong  dst, addr
                        wrlong  zero, par
                        jmp     #cmdloop
op                      long    0
dst                     long    0
src                     long    0
flags                   long    0
addr                    long    0
zero                    long    0
*/
