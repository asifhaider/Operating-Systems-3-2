
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	8b013103          	ld	sp,-1872(sp) # 800088b0 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	076000ef          	jal	ra,8000008c <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// at timervec in kernelvec.S,
// which turns them into software interrupts for
// devintr() in trap.c.
void
timerinit()
{
    8000001c:	1141                	addi	sp,sp,-16
    8000001e:	e422                	sd	s0,8(sp)
    80000020:	0800                	addi	s0,sp,16
// which hart (core) is this?
static inline uint64
r_mhartid()
{
  uint64 x;
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    80000022:	f14027f3          	csrr	a5,mhartid
  // each CPU has a separate source of timer interrupts.
  int id = r_mhartid();
    80000026:	0007859b          	sext.w	a1,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873703          	ld	a4,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	9732                	add	a4,a4,a2
    80000046:	e398                	sd	a4,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00259693          	slli	a3,a1,0x2
    8000004c:	96ae                	add	a3,a3,a1
    8000004e:	068e                	slli	a3,a3,0x3
    80000050:	00009717          	auipc	a4,0x9
    80000054:	8c070713          	addi	a4,a4,-1856 # 80008910 <timer_scratch>
    80000058:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005a:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005c:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    8000005e:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000062:	00006797          	auipc	a5,0x6
    80000066:	ebe78793          	addi	a5,a5,-322 # 80005f20 <timervec>
    8000006a:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    8000006e:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000072:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000076:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007a:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    8000007e:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000082:	30479073          	csrw	mie,a5
}
    80000086:	6422                	ld	s0,8(sp)
    80000088:	0141                	addi	sp,sp,16
    8000008a:	8082                	ret

000000008000008c <start>:
{
    8000008c:	1141                	addi	sp,sp,-16
    8000008e:	e406                	sd	ra,8(sp)
    80000090:	e022                	sd	s0,0(sp)
    80000092:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000094:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    80000098:	7779                	lui	a4,0xffffe
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdc87f>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	dcc78793          	addi	a5,a5,-564 # 80000e78 <main>
    800000b4:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000b8:	4781                	li	a5,0
    800000ba:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000be:	67c1                	lui	a5,0x10
    800000c0:	17fd                	addi	a5,a5,-1 # ffff <_entry-0x7fff0001>
    800000c2:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c6:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000ca:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000ce:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d2:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d6:	57fd                	li	a5,-1
    800000d8:	83a9                	srli	a5,a5,0xa
    800000da:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000de:	47bd                	li	a5,15
    800000e0:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e4:	00000097          	auipc	ra,0x0
    800000e8:	f38080e7          	jalr	-200(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ec:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f0:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f2:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f4:	30200073          	mret
}
    800000f8:	60a2                	ld	ra,8(sp)
    800000fa:	6402                	ld	s0,0(sp)
    800000fc:	0141                	addi	sp,sp,16
    800000fe:	8082                	ret

0000000080000100 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000100:	715d                	addi	sp,sp,-80
    80000102:	e486                	sd	ra,72(sp)
    80000104:	e0a2                	sd	s0,64(sp)
    80000106:	fc26                	sd	s1,56(sp)
    80000108:	f84a                	sd	s2,48(sp)
    8000010a:	f44e                	sd	s3,40(sp)
    8000010c:	f052                	sd	s4,32(sp)
    8000010e:	ec56                	sd	s5,24(sp)
    80000110:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000112:	04c05763          	blez	a2,80000160 <consolewrite+0x60>
    80000116:	8a2a                	mv	s4,a0
    80000118:	84ae                	mv	s1,a1
    8000011a:	89b2                	mv	s3,a2
    8000011c:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    8000011e:	5afd                	li	s5,-1
    80000120:	4685                	li	a3,1
    80000122:	8626                	mv	a2,s1
    80000124:	85d2                	mv	a1,s4
    80000126:	fbf40513          	addi	a0,s0,-65
    8000012a:	00002097          	auipc	ra,0x2
    8000012e:	4b4080e7          	jalr	1204(ra) # 800025de <either_copyin>
    80000132:	01550d63          	beq	a0,s5,8000014c <consolewrite+0x4c>
      break;
    uartputc(c);
    80000136:	fbf44503          	lbu	a0,-65(s0)
    8000013a:	00000097          	auipc	ra,0x0
    8000013e:	784080e7          	jalr	1924(ra) # 800008be <uartputc>
  for(i = 0; i < n; i++){
    80000142:	2905                	addiw	s2,s2,1
    80000144:	0485                	addi	s1,s1,1
    80000146:	fd299de3          	bne	s3,s2,80000120 <consolewrite+0x20>
    8000014a:	894e                	mv	s2,s3
  }

  return i;
}
    8000014c:	854a                	mv	a0,s2
    8000014e:	60a6                	ld	ra,72(sp)
    80000150:	6406                	ld	s0,64(sp)
    80000152:	74e2                	ld	s1,56(sp)
    80000154:	7942                	ld	s2,48(sp)
    80000156:	79a2                	ld	s3,40(sp)
    80000158:	7a02                	ld	s4,32(sp)
    8000015a:	6ae2                	ld	s5,24(sp)
    8000015c:	6161                	addi	sp,sp,80
    8000015e:	8082                	ret
  for(i = 0; i < n; i++){
    80000160:	4901                	li	s2,0
    80000162:	b7ed                	j	8000014c <consolewrite+0x4c>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7159                	addi	sp,sp,-112
    80000166:	f486                	sd	ra,104(sp)
    80000168:	f0a2                	sd	s0,96(sp)
    8000016a:	eca6                	sd	s1,88(sp)
    8000016c:	e8ca                	sd	s2,80(sp)
    8000016e:	e4ce                	sd	s3,72(sp)
    80000170:	e0d2                	sd	s4,64(sp)
    80000172:	fc56                	sd	s5,56(sp)
    80000174:	f85a                	sd	s6,48(sp)
    80000176:	f45e                	sd	s7,40(sp)
    80000178:	f062                	sd	s8,32(sp)
    8000017a:	ec66                	sd	s9,24(sp)
    8000017c:	e86a                	sd	s10,16(sp)
    8000017e:	1880                	addi	s0,sp,112
    80000180:	8aaa                	mv	s5,a0
    80000182:	8a2e                	mv	s4,a1
    80000184:	89b2                	mv	s3,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000186:	00060b1b          	sext.w	s6,a2
  acquire(&cons.lock);
    8000018a:	00011517          	auipc	a0,0x11
    8000018e:	8c650513          	addi	a0,a0,-1850 # 80010a50 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a44080e7          	jalr	-1468(ra) # 80000bd6 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	8b648493          	addi	s1,s1,-1866 # 80010a50 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	94690913          	addi	s2,s2,-1722 # 80010ae8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001aa:	4b91                	li	s7,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001ac:	5c7d                	li	s8,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001ae:	4ca9                	li	s9,10
  while(n > 0){
    800001b0:	07305b63          	blez	s3,80000226 <consoleread+0xc2>
    while(cons.r == cons.w){
    800001b4:	0984a783          	lw	a5,152(s1)
    800001b8:	09c4a703          	lw	a4,156(s1)
    800001bc:	02f71763          	bne	a4,a5,800001ea <consoleread+0x86>
      if(killed(myproc())){
    800001c0:	00001097          	auipc	ra,0x1
    800001c4:	7ec080e7          	jalr	2028(ra) # 800019ac <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	260080e7          	jalr	608(ra) # 80002428 <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	faa080e7          	jalr	-86(ra) # 80002180 <sleep>
    while(cons.r == cons.w){
    800001de:	0984a783          	lw	a5,152(s1)
    800001e2:	09c4a703          	lw	a4,156(s1)
    800001e6:	fcf70de3          	beq	a4,a5,800001c0 <consoleread+0x5c>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ea:	0017871b          	addiw	a4,a5,1
    800001ee:	08e4ac23          	sw	a4,152(s1)
    800001f2:	07f7f713          	andi	a4,a5,127
    800001f6:	9726                	add	a4,a4,s1
    800001f8:	01874703          	lbu	a4,24(a4)
    800001fc:	00070d1b          	sext.w	s10,a4
    if(c == C('D')){  // end-of-file
    80000200:	077d0563          	beq	s10,s7,8000026a <consoleread+0x106>
    cbuf = c;
    80000204:	f8e40fa3          	sb	a4,-97(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000208:	4685                	li	a3,1
    8000020a:	f9f40613          	addi	a2,s0,-97
    8000020e:	85d2                	mv	a1,s4
    80000210:	8556                	mv	a0,s5
    80000212:	00002097          	auipc	ra,0x2
    80000216:	376080e7          	jalr	886(ra) # 80002588 <either_copyout>
    8000021a:	01850663          	beq	a0,s8,80000226 <consoleread+0xc2>
    dst++;
    8000021e:	0a05                	addi	s4,s4,1
    --n;
    80000220:	39fd                	addiw	s3,s3,-1
    if(c == '\n'){
    80000222:	f99d17e3          	bne	s10,s9,800001b0 <consoleread+0x4c>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000226:	00011517          	auipc	a0,0x11
    8000022a:	82a50513          	addi	a0,a0,-2006 # 80010a50 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	a5c080e7          	jalr	-1444(ra) # 80000c8a <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	81450513          	addi	a0,a0,-2028 # 80010a50 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	a46080e7          	jalr	-1466(ra) # 80000c8a <release>
        return -1;
    8000024c:	557d                	li	a0,-1
}
    8000024e:	70a6                	ld	ra,104(sp)
    80000250:	7406                	ld	s0,96(sp)
    80000252:	64e6                	ld	s1,88(sp)
    80000254:	6946                	ld	s2,80(sp)
    80000256:	69a6                	ld	s3,72(sp)
    80000258:	6a06                	ld	s4,64(sp)
    8000025a:	7ae2                	ld	s5,56(sp)
    8000025c:	7b42                	ld	s6,48(sp)
    8000025e:	7ba2                	ld	s7,40(sp)
    80000260:	7c02                	ld	s8,32(sp)
    80000262:	6ce2                	ld	s9,24(sp)
    80000264:	6d42                	ld	s10,16(sp)
    80000266:	6165                	addi	sp,sp,112
    80000268:	8082                	ret
      if(n < target){
    8000026a:	0009871b          	sext.w	a4,s3
    8000026e:	fb677ce3          	bgeu	a4,s6,80000226 <consoleread+0xc2>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	86f72b23          	sw	a5,-1930(a4) # 80010ae8 <cons+0x98>
    8000027a:	b775                	j	80000226 <consoleread+0xc2>

000000008000027c <consputc>:
{
    8000027c:	1141                	addi	sp,sp,-16
    8000027e:	e406                	sd	ra,8(sp)
    80000280:	e022                	sd	s0,0(sp)
    80000282:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    80000284:	10000793          	li	a5,256
    80000288:	00f50a63          	beq	a0,a5,8000029c <consputc+0x20>
    uartputc_sync(c);
    8000028c:	00000097          	auipc	ra,0x0
    80000290:	560080e7          	jalr	1376(ra) # 800007ec <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	54e080e7          	jalr	1358(ra) # 800007ec <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	542080e7          	jalr	1346(ra) # 800007ec <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	538080e7          	jalr	1336(ra) # 800007ec <uartputc_sync>
    800002bc:	bfe1                	j	80000294 <consputc+0x18>

00000000800002be <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002be:	1101                	addi	sp,sp,-32
    800002c0:	ec06                	sd	ra,24(sp)
    800002c2:	e822                	sd	s0,16(sp)
    800002c4:	e426                	sd	s1,8(sp)
    800002c6:	e04a                	sd	s2,0(sp)
    800002c8:	1000                	addi	s0,sp,32
    800002ca:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002cc:	00010517          	auipc	a0,0x10
    800002d0:	78450513          	addi	a0,a0,1924 # 80010a50 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	902080e7          	jalr	-1790(ra) # 80000bd6 <acquire>

  switch(c){
    800002dc:	47d5                	li	a5,21
    800002de:	0af48663          	beq	s1,a5,8000038a <consoleintr+0xcc>
    800002e2:	0297ca63          	blt	a5,s1,80000316 <consoleintr+0x58>
    800002e6:	47a1                	li	a5,8
    800002e8:	0ef48763          	beq	s1,a5,800003d6 <consoleintr+0x118>
    800002ec:	47c1                	li	a5,16
    800002ee:	10f49a63          	bne	s1,a5,80000402 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f2:	00002097          	auipc	ra,0x2
    800002f6:	342080e7          	jalr	834(ra) # 80002634 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00010517          	auipc	a0,0x10
    800002fe:	75650513          	addi	a0,a0,1878 # 80010a50 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	988080e7          	jalr	-1656(ra) # 80000c8a <release>
}
    8000030a:	60e2                	ld	ra,24(sp)
    8000030c:	6442                	ld	s0,16(sp)
    8000030e:	64a2                	ld	s1,8(sp)
    80000310:	6902                	ld	s2,0(sp)
    80000312:	6105                	addi	sp,sp,32
    80000314:	8082                	ret
  switch(c){
    80000316:	07f00793          	li	a5,127
    8000031a:	0af48e63          	beq	s1,a5,800003d6 <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    8000031e:	00010717          	auipc	a4,0x10
    80000322:	73270713          	addi	a4,a4,1842 # 80010a50 <cons>
    80000326:	0a072783          	lw	a5,160(a4)
    8000032a:	09872703          	lw	a4,152(a4)
    8000032e:	9f99                	subw	a5,a5,a4
    80000330:	07f00713          	li	a4,127
    80000334:	fcf763e3          	bltu	a4,a5,800002fa <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    80000338:	47b5                	li	a5,13
    8000033a:	0cf48763          	beq	s1,a5,80000408 <consoleintr+0x14a>
      consputc(c);
    8000033e:	8526                	mv	a0,s1
    80000340:	00000097          	auipc	ra,0x0
    80000344:	f3c080e7          	jalr	-196(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000348:	00010797          	auipc	a5,0x10
    8000034c:	70878793          	addi	a5,a5,1800 # 80010a50 <cons>
    80000350:	0a07a683          	lw	a3,160(a5)
    80000354:	0016871b          	addiw	a4,a3,1
    80000358:	0007061b          	sext.w	a2,a4
    8000035c:	0ae7a023          	sw	a4,160(a5)
    80000360:	07f6f693          	andi	a3,a3,127
    80000364:	97b6                	add	a5,a5,a3
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00010797          	auipc	a5,0x10
    8000037a:	7727a783          	lw	a5,1906(a5) # 80010ae8 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00010717          	auipc	a4,0x10
    8000038e:	6c670713          	addi	a4,a4,1734 # 80010a50 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00010497          	auipc	s1,0x10
    8000039e:	6b648493          	addi	s1,s1,1718 # 80010a50 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a8:	37fd                	addiw	a5,a5,-1
    800003aa:	07f7f713          	andi	a4,a5,127
    800003ae:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b0:	01874703          	lbu	a4,24(a4)
    800003b4:	f52703e3          	beq	a4,s2,800002fa <consoleintr+0x3c>
      cons.e--;
    800003b8:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003bc:	10000513          	li	a0,256
    800003c0:	00000097          	auipc	ra,0x0
    800003c4:	ebc080e7          	jalr	-324(ra) # 8000027c <consputc>
    while(cons.e != cons.w &&
    800003c8:	0a04a783          	lw	a5,160(s1)
    800003cc:	09c4a703          	lw	a4,156(s1)
    800003d0:	fcf71ce3          	bne	a4,a5,800003a8 <consoleintr+0xea>
    800003d4:	b71d                	j	800002fa <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003d6:	00010717          	auipc	a4,0x10
    800003da:	67a70713          	addi	a4,a4,1658 # 80010a50 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00010717          	auipc	a4,0x10
    800003f0:	70f72223          	sw	a5,1796(a4) # 80010af0 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000412:	00010797          	auipc	a5,0x10
    80000416:	63e78793          	addi	a5,a5,1598 # 80010a50 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00010797          	auipc	a5,0x10
    8000043a:	6ac7ab23          	sw	a2,1718(a5) # 80010aec <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00010517          	auipc	a0,0x10
    80000442:	6aa50513          	addi	a0,a0,1706 # 80010ae8 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	d9e080e7          	jalr	-610(ra) # 800021e4 <wakeup>
    8000044e:	b575                	j	800002fa <consoleintr+0x3c>

0000000080000450 <consoleinit>:

void
consoleinit(void)
{
    80000450:	1141                	addi	sp,sp,-16
    80000452:	e406                	sd	ra,8(sp)
    80000454:	e022                	sd	s0,0(sp)
    80000456:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    80000458:	00008597          	auipc	a1,0x8
    8000045c:	bb858593          	addi	a1,a1,-1096 # 80008010 <etext+0x10>
    80000460:	00010517          	auipc	a0,0x10
    80000464:	5f050513          	addi	a0,a0,1520 # 80010a50 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	6de080e7          	jalr	1758(ra) # 80000b46 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32c080e7          	jalr	812(ra) # 8000079c <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	97078793          	addi	a5,a5,-1680 # 80020de8 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7670713          	addi	a4,a4,-906 # 80000100 <consolewrite>
    80000492:	ef98                	sd	a4,24(a5)
}
    80000494:	60a2                	ld	ra,8(sp)
    80000496:	6402                	ld	s0,0(sp)
    80000498:	0141                	addi	sp,sp,16
    8000049a:	8082                	ret

000000008000049c <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    8000049c:	7179                	addi	sp,sp,-48
    8000049e:	f406                	sd	ra,40(sp)
    800004a0:	f022                	sd	s0,32(sp)
    800004a2:	ec26                	sd	s1,24(sp)
    800004a4:	e84a                	sd	s2,16(sp)
    800004a6:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004a8:	c219                	beqz	a2,800004ae <printint+0x12>
    800004aa:	08054763          	bltz	a0,80000538 <printint+0x9c>
    x = -xx;
  else
    x = xx;
    800004ae:	2501                	sext.w	a0,a0
    800004b0:	4881                	li	a7,0
    800004b2:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004b6:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004b8:	2581                	sext.w	a1,a1
    800004ba:	00008617          	auipc	a2,0x8
    800004be:	b8660613          	addi	a2,a2,-1146 # 80008040 <digits>
    800004c2:	883a                	mv	a6,a4
    800004c4:	2705                	addiw	a4,a4,1
    800004c6:	02b577bb          	remuw	a5,a0,a1
    800004ca:	1782                	slli	a5,a5,0x20
    800004cc:	9381                	srli	a5,a5,0x20
    800004ce:	97b2                	add	a5,a5,a2
    800004d0:	0007c783          	lbu	a5,0(a5)
    800004d4:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004d8:	0005079b          	sext.w	a5,a0
    800004dc:	02b5553b          	divuw	a0,a0,a1
    800004e0:	0685                	addi	a3,a3,1
    800004e2:	feb7f0e3          	bgeu	a5,a1,800004c2 <printint+0x26>

  if(sign)
    800004e6:	00088c63          	beqz	a7,800004fe <printint+0x62>
    buf[i++] = '-';
    800004ea:	fe070793          	addi	a5,a4,-32
    800004ee:	00878733          	add	a4,a5,s0
    800004f2:	02d00793          	li	a5,45
    800004f6:	fef70823          	sb	a5,-16(a4)
    800004fa:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fe:	02e05763          	blez	a4,8000052c <printint+0x90>
    80000502:	fd040793          	addi	a5,s0,-48
    80000506:	00e784b3          	add	s1,a5,a4
    8000050a:	fff78913          	addi	s2,a5,-1
    8000050e:	993a                	add	s2,s2,a4
    80000510:	377d                	addiw	a4,a4,-1
    80000512:	1702                	slli	a4,a4,0x20
    80000514:	9301                	srli	a4,a4,0x20
    80000516:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051a:	fff4c503          	lbu	a0,-1(s1)
    8000051e:	00000097          	auipc	ra,0x0
    80000522:	d5e080e7          	jalr	-674(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000526:	14fd                	addi	s1,s1,-1
    80000528:	ff2499e3          	bne	s1,s2,8000051a <printint+0x7e>
}
    8000052c:	70a2                	ld	ra,40(sp)
    8000052e:	7402                	ld	s0,32(sp)
    80000530:	64e2                	ld	s1,24(sp)
    80000532:	6942                	ld	s2,16(sp)
    80000534:	6145                	addi	sp,sp,48
    80000536:	8082                	ret
    x = -xx;
    80000538:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053c:	4885                	li	a7,1
    x = -xx;
    8000053e:	bf95                	j	800004b2 <printint+0x16>

0000000080000540 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000540:	1101                	addi	sp,sp,-32
    80000542:	ec06                	sd	ra,24(sp)
    80000544:	e822                	sd	s0,16(sp)
    80000546:	e426                	sd	s1,8(sp)
    80000548:	1000                	addi	s0,sp,32
    8000054a:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054c:	00010797          	auipc	a5,0x10
    80000550:	5c07a223          	sw	zero,1476(a5) # 80010b10 <pr+0x18>
  printf("panic: ");
    80000554:	00008517          	auipc	a0,0x8
    80000558:	ac450513          	addi	a0,a0,-1340 # 80008018 <etext+0x18>
    8000055c:	00000097          	auipc	ra,0x0
    80000560:	02e080e7          	jalr	46(ra) # 8000058a <printf>
  printf(s);
    80000564:	8526                	mv	a0,s1
    80000566:	00000097          	auipc	ra,0x0
    8000056a:	024080e7          	jalr	36(ra) # 8000058a <printf>
  printf("\n");
    8000056e:	00008517          	auipc	a0,0x8
    80000572:	b5a50513          	addi	a0,a0,-1190 # 800080c8 <digits+0x88>
    80000576:	00000097          	auipc	ra,0x0
    8000057a:	014080e7          	jalr	20(ra) # 8000058a <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057e:	4785                	li	a5,1
    80000580:	00008717          	auipc	a4,0x8
    80000584:	34f72823          	sw	a5,848(a4) # 800088d0 <panicked>
  for(;;)
    80000588:	a001                	j	80000588 <panic+0x48>

000000008000058a <printf>:
{
    8000058a:	7131                	addi	sp,sp,-192
    8000058c:	fc86                	sd	ra,120(sp)
    8000058e:	f8a2                	sd	s0,112(sp)
    80000590:	f4a6                	sd	s1,104(sp)
    80000592:	f0ca                	sd	s2,96(sp)
    80000594:	ecce                	sd	s3,88(sp)
    80000596:	e8d2                	sd	s4,80(sp)
    80000598:	e4d6                	sd	s5,72(sp)
    8000059a:	e0da                	sd	s6,64(sp)
    8000059c:	fc5e                	sd	s7,56(sp)
    8000059e:	f862                	sd	s8,48(sp)
    800005a0:	f466                	sd	s9,40(sp)
    800005a2:	f06a                	sd	s10,32(sp)
    800005a4:	ec6e                	sd	s11,24(sp)
    800005a6:	0100                	addi	s0,sp,128
    800005a8:	8a2a                	mv	s4,a0
    800005aa:	e40c                	sd	a1,8(s0)
    800005ac:	e810                	sd	a2,16(s0)
    800005ae:	ec14                	sd	a3,24(s0)
    800005b0:	f018                	sd	a4,32(s0)
    800005b2:	f41c                	sd	a5,40(s0)
    800005b4:	03043823          	sd	a6,48(s0)
    800005b8:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005bc:	00010d97          	auipc	s11,0x10
    800005c0:	554dad83          	lw	s11,1364(s11) # 80010b10 <pr+0x18>
  if(locking)
    800005c4:	020d9b63          	bnez	s11,800005fa <printf+0x70>
  if (fmt == 0)
    800005c8:	040a0263          	beqz	s4,8000060c <printf+0x82>
  va_start(ap, fmt);
    800005cc:	00840793          	addi	a5,s0,8
    800005d0:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d4:	000a4503          	lbu	a0,0(s4)
    800005d8:	14050f63          	beqz	a0,80000736 <printf+0x1ac>
    800005dc:	4981                	li	s3,0
    if(c != '%'){
    800005de:	02500a93          	li	s5,37
    switch(c){
    800005e2:	07000b93          	li	s7,112
  consputc('x');
    800005e6:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e8:	00008b17          	auipc	s6,0x8
    800005ec:	a58b0b13          	addi	s6,s6,-1448 # 80008040 <digits>
    switch(c){
    800005f0:	07300c93          	li	s9,115
    800005f4:	06400c13          	li	s8,100
    800005f8:	a82d                	j	80000632 <printf+0xa8>
    acquire(&pr.lock);
    800005fa:	00010517          	auipc	a0,0x10
    800005fe:	4fe50513          	addi	a0,a0,1278 # 80010af8 <pr>
    80000602:	00000097          	auipc	ra,0x0
    80000606:	5d4080e7          	jalr	1492(ra) # 80000bd6 <acquire>
    8000060a:	bf7d                	j	800005c8 <printf+0x3e>
    panic("null fmt");
    8000060c:	00008517          	auipc	a0,0x8
    80000610:	a1c50513          	addi	a0,a0,-1508 # 80008028 <etext+0x28>
    80000614:	00000097          	auipc	ra,0x0
    80000618:	f2c080e7          	jalr	-212(ra) # 80000540 <panic>
      consputc(c);
    8000061c:	00000097          	auipc	ra,0x0
    80000620:	c60080e7          	jalr	-928(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000624:	2985                	addiw	s3,s3,1
    80000626:	013a07b3          	add	a5,s4,s3
    8000062a:	0007c503          	lbu	a0,0(a5)
    8000062e:	10050463          	beqz	a0,80000736 <printf+0x1ac>
    if(c != '%'){
    80000632:	ff5515e3          	bne	a0,s5,8000061c <printf+0x92>
    c = fmt[++i] & 0xff;
    80000636:	2985                	addiw	s3,s3,1
    80000638:	013a07b3          	add	a5,s4,s3
    8000063c:	0007c783          	lbu	a5,0(a5)
    80000640:	0007849b          	sext.w	s1,a5
    if(c == 0)
    80000644:	cbed                	beqz	a5,80000736 <printf+0x1ac>
    switch(c){
    80000646:	05778a63          	beq	a5,s7,8000069a <printf+0x110>
    8000064a:	02fbf663          	bgeu	s7,a5,80000676 <printf+0xec>
    8000064e:	09978863          	beq	a5,s9,800006de <printf+0x154>
    80000652:	07800713          	li	a4,120
    80000656:	0ce79563          	bne	a5,a4,80000720 <printf+0x196>
      printint(va_arg(ap, int), 16, 1);
    8000065a:	f8843783          	ld	a5,-120(s0)
    8000065e:	00878713          	addi	a4,a5,8
    80000662:	f8e43423          	sd	a4,-120(s0)
    80000666:	4605                	li	a2,1
    80000668:	85ea                	mv	a1,s10
    8000066a:	4388                	lw	a0,0(a5)
    8000066c:	00000097          	auipc	ra,0x0
    80000670:	e30080e7          	jalr	-464(ra) # 8000049c <printint>
      break;
    80000674:	bf45                	j	80000624 <printf+0x9a>
    switch(c){
    80000676:	09578f63          	beq	a5,s5,80000714 <printf+0x18a>
    8000067a:	0b879363          	bne	a5,s8,80000720 <printf+0x196>
      printint(va_arg(ap, int), 10, 1);
    8000067e:	f8843783          	ld	a5,-120(s0)
    80000682:	00878713          	addi	a4,a5,8
    80000686:	f8e43423          	sd	a4,-120(s0)
    8000068a:	4605                	li	a2,1
    8000068c:	45a9                	li	a1,10
    8000068e:	4388                	lw	a0,0(a5)
    80000690:	00000097          	auipc	ra,0x0
    80000694:	e0c080e7          	jalr	-500(ra) # 8000049c <printint>
      break;
    80000698:	b771                	j	80000624 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069a:	f8843783          	ld	a5,-120(s0)
    8000069e:	00878713          	addi	a4,a5,8
    800006a2:	f8e43423          	sd	a4,-120(s0)
    800006a6:	0007b903          	ld	s2,0(a5)
  consputc('0');
    800006aa:	03000513          	li	a0,48
    800006ae:	00000097          	auipc	ra,0x0
    800006b2:	bce080e7          	jalr	-1074(ra) # 8000027c <consputc>
  consputc('x');
    800006b6:	07800513          	li	a0,120
    800006ba:	00000097          	auipc	ra,0x0
    800006be:	bc2080e7          	jalr	-1086(ra) # 8000027c <consputc>
    800006c2:	84ea                	mv	s1,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c4:	03c95793          	srli	a5,s2,0x3c
    800006c8:	97da                	add	a5,a5,s6
    800006ca:	0007c503          	lbu	a0,0(a5)
    800006ce:	00000097          	auipc	ra,0x0
    800006d2:	bae080e7          	jalr	-1106(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d6:	0912                	slli	s2,s2,0x4
    800006d8:	34fd                	addiw	s1,s1,-1
    800006da:	f4ed                	bnez	s1,800006c4 <printf+0x13a>
    800006dc:	b7a1                	j	80000624 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	6384                	ld	s1,0(a5)
    800006ec:	cc89                	beqz	s1,80000706 <printf+0x17c>
      for(; *s; s++)
    800006ee:	0004c503          	lbu	a0,0(s1)
    800006f2:	d90d                	beqz	a0,80000624 <printf+0x9a>
        consputc(*s);
    800006f4:	00000097          	auipc	ra,0x0
    800006f8:	b88080e7          	jalr	-1144(ra) # 8000027c <consputc>
      for(; *s; s++)
    800006fc:	0485                	addi	s1,s1,1
    800006fe:	0004c503          	lbu	a0,0(s1)
    80000702:	f96d                	bnez	a0,800006f4 <printf+0x16a>
    80000704:	b705                	j	80000624 <printf+0x9a>
        s = "(null)";
    80000706:	00008497          	auipc	s1,0x8
    8000070a:	91a48493          	addi	s1,s1,-1766 # 80008020 <etext+0x20>
      for(; *s; s++)
    8000070e:	02800513          	li	a0,40
    80000712:	b7cd                	j	800006f4 <printf+0x16a>
      consputc('%');
    80000714:	8556                	mv	a0,s5
    80000716:	00000097          	auipc	ra,0x0
    8000071a:	b66080e7          	jalr	-1178(ra) # 8000027c <consputc>
      break;
    8000071e:	b719                	j	80000624 <printf+0x9a>
      consputc('%');
    80000720:	8556                	mv	a0,s5
    80000722:	00000097          	auipc	ra,0x0
    80000726:	b5a080e7          	jalr	-1190(ra) # 8000027c <consputc>
      consputc(c);
    8000072a:	8526                	mv	a0,s1
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b50080e7          	jalr	-1200(ra) # 8000027c <consputc>
      break;
    80000734:	bdc5                	j	80000624 <printf+0x9a>
  if(locking)
    80000736:	020d9163          	bnez	s11,80000758 <printf+0x1ce>
}
    8000073a:	70e6                	ld	ra,120(sp)
    8000073c:	7446                	ld	s0,112(sp)
    8000073e:	74a6                	ld	s1,104(sp)
    80000740:	7906                	ld	s2,96(sp)
    80000742:	69e6                	ld	s3,88(sp)
    80000744:	6a46                	ld	s4,80(sp)
    80000746:	6aa6                	ld	s5,72(sp)
    80000748:	6b06                	ld	s6,64(sp)
    8000074a:	7be2                	ld	s7,56(sp)
    8000074c:	7c42                	ld	s8,48(sp)
    8000074e:	7ca2                	ld	s9,40(sp)
    80000750:	7d02                	ld	s10,32(sp)
    80000752:	6de2                	ld	s11,24(sp)
    80000754:	6129                	addi	sp,sp,192
    80000756:	8082                	ret
    release(&pr.lock);
    80000758:	00010517          	auipc	a0,0x10
    8000075c:	3a050513          	addi	a0,a0,928 # 80010af8 <pr>
    80000760:	00000097          	auipc	ra,0x0
    80000764:	52a080e7          	jalr	1322(ra) # 80000c8a <release>
}
    80000768:	bfc9                	j	8000073a <printf+0x1b0>

000000008000076a <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076a:	1101                	addi	sp,sp,-32
    8000076c:	ec06                	sd	ra,24(sp)
    8000076e:	e822                	sd	s0,16(sp)
    80000770:	e426                	sd	s1,8(sp)
    80000772:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000774:	00010497          	auipc	s1,0x10
    80000778:	38448493          	addi	s1,s1,900 # 80010af8 <pr>
    8000077c:	00008597          	auipc	a1,0x8
    80000780:	8bc58593          	addi	a1,a1,-1860 # 80008038 <etext+0x38>
    80000784:	8526                	mv	a0,s1
    80000786:	00000097          	auipc	ra,0x0
    8000078a:	3c0080e7          	jalr	960(ra) # 80000b46 <initlock>
  pr.locking = 1;
    8000078e:	4785                	li	a5,1
    80000790:	cc9c                	sw	a5,24(s1)
}
    80000792:	60e2                	ld	ra,24(sp)
    80000794:	6442                	ld	s0,16(sp)
    80000796:	64a2                	ld	s1,8(sp)
    80000798:	6105                	addi	sp,sp,32
    8000079a:	8082                	ret

000000008000079c <uartinit>:

void uartstart();

void
uartinit(void)
{
    8000079c:	1141                	addi	sp,sp,-16
    8000079e:	e406                	sd	ra,8(sp)
    800007a0:	e022                	sd	s0,0(sp)
    800007a2:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a4:	100007b7          	lui	a5,0x10000
    800007a8:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007ac:	f8000713          	li	a4,-128
    800007b0:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b4:	470d                	li	a4,3
    800007b6:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007ba:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007be:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c2:	469d                	li	a3,7
    800007c4:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007c8:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007cc:	00008597          	auipc	a1,0x8
    800007d0:	88c58593          	addi	a1,a1,-1908 # 80008058 <digits+0x18>
    800007d4:	00010517          	auipc	a0,0x10
    800007d8:	34450513          	addi	a0,a0,836 # 80010b18 <uart_tx_lock>
    800007dc:	00000097          	auipc	ra,0x0
    800007e0:	36a080e7          	jalr	874(ra) # 80000b46 <initlock>
}
    800007e4:	60a2                	ld	ra,8(sp)
    800007e6:	6402                	ld	s0,0(sp)
    800007e8:	0141                	addi	sp,sp,16
    800007ea:	8082                	ret

00000000800007ec <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007ec:	1101                	addi	sp,sp,-32
    800007ee:	ec06                	sd	ra,24(sp)
    800007f0:	e822                	sd	s0,16(sp)
    800007f2:	e426                	sd	s1,8(sp)
    800007f4:	1000                	addi	s0,sp,32
    800007f6:	84aa                	mv	s1,a0
  push_off();
    800007f8:	00000097          	auipc	ra,0x0
    800007fc:	392080e7          	jalr	914(ra) # 80000b8a <push_off>

  if(panicked){
    80000800:	00008797          	auipc	a5,0x8
    80000804:	0d07a783          	lw	a5,208(a5) # 800088d0 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000808:	10000737          	lui	a4,0x10000
  if(panicked){
    8000080c:	c391                	beqz	a5,80000810 <uartputc_sync+0x24>
    for(;;)
    8000080e:	a001                	j	8000080e <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000810:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000814:	0207f793          	andi	a5,a5,32
    80000818:	dfe5                	beqz	a5,80000810 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    8000081a:	0ff4f513          	zext.b	a0,s1
    8000081e:	100007b7          	lui	a5,0x10000
    80000822:	00a78023          	sb	a0,0(a5) # 10000000 <_entry-0x70000000>

  pop_off();
    80000826:	00000097          	auipc	ra,0x0
    8000082a:	404080e7          	jalr	1028(ra) # 80000c2a <pop_off>
}
    8000082e:	60e2                	ld	ra,24(sp)
    80000830:	6442                	ld	s0,16(sp)
    80000832:	64a2                	ld	s1,8(sp)
    80000834:	6105                	addi	sp,sp,32
    80000836:	8082                	ret

0000000080000838 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000838:	00008797          	auipc	a5,0x8
    8000083c:	0a07b783          	ld	a5,160(a5) # 800088d8 <uart_tx_r>
    80000840:	00008717          	auipc	a4,0x8
    80000844:	0a073703          	ld	a4,160(a4) # 800088e0 <uart_tx_w>
    80000848:	06f70a63          	beq	a4,a5,800008bc <uartstart+0x84>
{
    8000084c:	7139                	addi	sp,sp,-64
    8000084e:	fc06                	sd	ra,56(sp)
    80000850:	f822                	sd	s0,48(sp)
    80000852:	f426                	sd	s1,40(sp)
    80000854:	f04a                	sd	s2,32(sp)
    80000856:	ec4e                	sd	s3,24(sp)
    80000858:	e852                	sd	s4,16(sp)
    8000085a:	e456                	sd	s5,8(sp)
    8000085c:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000085e:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000862:	00010a17          	auipc	s4,0x10
    80000866:	2b6a0a13          	addi	s4,s4,694 # 80010b18 <uart_tx_lock>
    uart_tx_r += 1;
    8000086a:	00008497          	auipc	s1,0x8
    8000086e:	06e48493          	addi	s1,s1,110 # 800088d8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000872:	00008997          	auipc	s3,0x8
    80000876:	06e98993          	addi	s3,s3,110 # 800088e0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000087a:	00594703          	lbu	a4,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000087e:	02077713          	andi	a4,a4,32
    80000882:	c705                	beqz	a4,800008aa <uartstart+0x72>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000884:	01f7f713          	andi	a4,a5,31
    80000888:	9752                	add	a4,a4,s4
    8000088a:	01874a83          	lbu	s5,24(a4)
    uart_tx_r += 1;
    8000088e:	0785                	addi	a5,a5,1
    80000890:	e09c                	sd	a5,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    80000892:	8526                	mv	a0,s1
    80000894:	00002097          	auipc	ra,0x2
    80000898:	950080e7          	jalr	-1712(ra) # 800021e4 <wakeup>
    
    WriteReg(THR, c);
    8000089c:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008a0:	609c                	ld	a5,0(s1)
    800008a2:	0009b703          	ld	a4,0(s3)
    800008a6:	fcf71ae3          	bne	a4,a5,8000087a <uartstart+0x42>
  }
}
    800008aa:	70e2                	ld	ra,56(sp)
    800008ac:	7442                	ld	s0,48(sp)
    800008ae:	74a2                	ld	s1,40(sp)
    800008b0:	7902                	ld	s2,32(sp)
    800008b2:	69e2                	ld	s3,24(sp)
    800008b4:	6a42                	ld	s4,16(sp)
    800008b6:	6aa2                	ld	s5,8(sp)
    800008b8:	6121                	addi	sp,sp,64
    800008ba:	8082                	ret
    800008bc:	8082                	ret

00000000800008be <uartputc>:
{
    800008be:	7179                	addi	sp,sp,-48
    800008c0:	f406                	sd	ra,40(sp)
    800008c2:	f022                	sd	s0,32(sp)
    800008c4:	ec26                	sd	s1,24(sp)
    800008c6:	e84a                	sd	s2,16(sp)
    800008c8:	e44e                	sd	s3,8(sp)
    800008ca:	e052                	sd	s4,0(sp)
    800008cc:	1800                	addi	s0,sp,48
    800008ce:	8a2a                	mv	s4,a0
  acquire(&uart_tx_lock);
    800008d0:	00010517          	auipc	a0,0x10
    800008d4:	24850513          	addi	a0,a0,584 # 80010b18 <uart_tx_lock>
    800008d8:	00000097          	auipc	ra,0x0
    800008dc:	2fe080e7          	jalr	766(ra) # 80000bd6 <acquire>
  if(panicked){
    800008e0:	00008797          	auipc	a5,0x8
    800008e4:	ff07a783          	lw	a5,-16(a5) # 800088d0 <panicked>
    800008e8:	e7c9                	bnez	a5,80000972 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008ea:	00008717          	auipc	a4,0x8
    800008ee:	ff673703          	ld	a4,-10(a4) # 800088e0 <uart_tx_w>
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	fe67b783          	ld	a5,-26(a5) # 800088d8 <uart_tx_r>
    800008fa:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fe:	00010997          	auipc	s3,0x10
    80000902:	21a98993          	addi	s3,s3,538 # 80010b18 <uart_tx_lock>
    80000906:	00008497          	auipc	s1,0x8
    8000090a:	fd248493          	addi	s1,s1,-46 # 800088d8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00008917          	auipc	s2,0x8
    80000912:	fd290913          	addi	s2,s2,-46 # 800088e0 <uart_tx_w>
    80000916:	00e79f63          	bne	a5,a4,80000934 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000091a:	85ce                	mv	a1,s3
    8000091c:	8526                	mv	a0,s1
    8000091e:	00002097          	auipc	ra,0x2
    80000922:	862080e7          	jalr	-1950(ra) # 80002180 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000926:	00093703          	ld	a4,0(s2)
    8000092a:	609c                	ld	a5,0(s1)
    8000092c:	02078793          	addi	a5,a5,32
    80000930:	fee785e3          	beq	a5,a4,8000091a <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000934:	00010497          	auipc	s1,0x10
    80000938:	1e448493          	addi	s1,s1,484 # 80010b18 <uart_tx_lock>
    8000093c:	01f77793          	andi	a5,a4,31
    80000940:	97a6                	add	a5,a5,s1
    80000942:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000946:	0705                	addi	a4,a4,1
    80000948:	00008797          	auipc	a5,0x8
    8000094c:	f8e7bc23          	sd	a4,-104(a5) # 800088e0 <uart_tx_w>
  uartstart();
    80000950:	00000097          	auipc	ra,0x0
    80000954:	ee8080e7          	jalr	-280(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    80000958:	8526                	mv	a0,s1
    8000095a:	00000097          	auipc	ra,0x0
    8000095e:	330080e7          	jalr	816(ra) # 80000c8a <release>
}
    80000962:	70a2                	ld	ra,40(sp)
    80000964:	7402                	ld	s0,32(sp)
    80000966:	64e2                	ld	s1,24(sp)
    80000968:	6942                	ld	s2,16(sp)
    8000096a:	69a2                	ld	s3,8(sp)
    8000096c:	6a02                	ld	s4,0(sp)
    8000096e:	6145                	addi	sp,sp,48
    80000970:	8082                	ret
    for(;;)
    80000972:	a001                	j	80000972 <uartputc+0xb4>

0000000080000974 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000974:	1141                	addi	sp,sp,-16
    80000976:	e422                	sd	s0,8(sp)
    80000978:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000097a:	100007b7          	lui	a5,0x10000
    8000097e:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000982:	8b85                	andi	a5,a5,1
    80000984:	cb81                	beqz	a5,80000994 <uartgetc+0x20>
    // input data is ready.
    return ReadReg(RHR);
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
  } else {
    return -1;
  }
}
    8000098e:	6422                	ld	s0,8(sp)
    80000990:	0141                	addi	sp,sp,16
    80000992:	8082                	ret
    return -1;
    80000994:	557d                	li	a0,-1
    80000996:	bfe5                	j	8000098e <uartgetc+0x1a>

0000000080000998 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    80000998:	1101                	addi	sp,sp,-32
    8000099a:	ec06                	sd	ra,24(sp)
    8000099c:	e822                	sd	s0,16(sp)
    8000099e:	e426                	sd	s1,8(sp)
    800009a0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009a2:	54fd                	li	s1,-1
    800009a4:	a029                	j	800009ae <uartintr+0x16>
      break;
    consoleintr(c);
    800009a6:	00000097          	auipc	ra,0x0
    800009aa:	918080e7          	jalr	-1768(ra) # 800002be <consoleintr>
    int c = uartgetc();
    800009ae:	00000097          	auipc	ra,0x0
    800009b2:	fc6080e7          	jalr	-58(ra) # 80000974 <uartgetc>
    if(c == -1)
    800009b6:	fe9518e3          	bne	a0,s1,800009a6 <uartintr+0xe>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ba:	00010497          	auipc	s1,0x10
    800009be:	15e48493          	addi	s1,s1,350 # 80010b18 <uart_tx_lock>
    800009c2:	8526                	mv	a0,s1
    800009c4:	00000097          	auipc	ra,0x0
    800009c8:	212080e7          	jalr	530(ra) # 80000bd6 <acquire>
  uartstart();
    800009cc:	00000097          	auipc	ra,0x0
    800009d0:	e6c080e7          	jalr	-404(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    800009d4:	8526                	mv	a0,s1
    800009d6:	00000097          	auipc	ra,0x0
    800009da:	2b4080e7          	jalr	692(ra) # 80000c8a <release>
}
    800009de:	60e2                	ld	ra,24(sp)
    800009e0:	6442                	ld	s0,16(sp)
    800009e2:	64a2                	ld	s1,8(sp)
    800009e4:	6105                	addi	sp,sp,32
    800009e6:	8082                	ret

00000000800009e8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    800009e8:	1101                	addi	sp,sp,-32
    800009ea:	ec06                	sd	ra,24(sp)
    800009ec:	e822                	sd	s0,16(sp)
    800009ee:	e426                	sd	s1,8(sp)
    800009f0:	e04a                	sd	s2,0(sp)
    800009f2:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    800009f4:	03451793          	slli	a5,a0,0x34
    800009f8:	ebb9                	bnez	a5,80000a4e <kfree+0x66>
    800009fa:	84aa                	mv	s1,a0
    800009fc:	00021797          	auipc	a5,0x21
    80000a00:	58478793          	addi	a5,a5,1412 # 80021f80 <end>
    80000a04:	04f56563          	bltu	a0,a5,80000a4e <kfree+0x66>
    80000a08:	47c5                	li	a5,17
    80000a0a:	07ee                	slli	a5,a5,0x1b
    80000a0c:	04f57163          	bgeu	a0,a5,80000a4e <kfree+0x66>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a10:	6605                	lui	a2,0x1
    80000a12:	4585                	li	a1,1
    80000a14:	00000097          	auipc	ra,0x0
    80000a18:	2be080e7          	jalr	702(ra) # 80000cd2 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1c:	00010917          	auipc	s2,0x10
    80000a20:	13490913          	addi	s2,s2,308 # 80010b50 <kmem>
    80000a24:	854a                	mv	a0,s2
    80000a26:	00000097          	auipc	ra,0x0
    80000a2a:	1b0080e7          	jalr	432(ra) # 80000bd6 <acquire>
  r->next = kmem.freelist;
    80000a2e:	01893783          	ld	a5,24(s2)
    80000a32:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a34:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a38:	854a                	mv	a0,s2
    80000a3a:	00000097          	auipc	ra,0x0
    80000a3e:	250080e7          	jalr	592(ra) # 80000c8a <release>
}
    80000a42:	60e2                	ld	ra,24(sp)
    80000a44:	6442                	ld	s0,16(sp)
    80000a46:	64a2                	ld	s1,8(sp)
    80000a48:	6902                	ld	s2,0(sp)
    80000a4a:	6105                	addi	sp,sp,32
    80000a4c:	8082                	ret
    panic("kfree");
    80000a4e:	00007517          	auipc	a0,0x7
    80000a52:	61250513          	addi	a0,a0,1554 # 80008060 <digits+0x20>
    80000a56:	00000097          	auipc	ra,0x0
    80000a5a:	aea080e7          	jalr	-1302(ra) # 80000540 <panic>

0000000080000a5e <freerange>:
{
    80000a5e:	7179                	addi	sp,sp,-48
    80000a60:	f406                	sd	ra,40(sp)
    80000a62:	f022                	sd	s0,32(sp)
    80000a64:	ec26                	sd	s1,24(sp)
    80000a66:	e84a                	sd	s2,16(sp)
    80000a68:	e44e                	sd	s3,8(sp)
    80000a6a:	e052                	sd	s4,0(sp)
    80000a6c:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a6e:	6785                	lui	a5,0x1
    80000a70:	fff78713          	addi	a4,a5,-1 # fff <_entry-0x7ffff001>
    80000a74:	00e504b3          	add	s1,a0,a4
    80000a78:	777d                	lui	a4,0xfffff
    80000a7a:	8cf9                	and	s1,s1,a4
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a7c:	94be                	add	s1,s1,a5
    80000a7e:	0095ee63          	bltu	a1,s1,80000a9a <freerange+0x3c>
    80000a82:	892e                	mv	s2,a1
    kfree(p);
    80000a84:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a86:	6985                	lui	s3,0x1
    kfree(p);
    80000a88:	01448533          	add	a0,s1,s4
    80000a8c:	00000097          	auipc	ra,0x0
    80000a90:	f5c080e7          	jalr	-164(ra) # 800009e8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a94:	94ce                	add	s1,s1,s3
    80000a96:	fe9979e3          	bgeu	s2,s1,80000a88 <freerange+0x2a>
}
    80000a9a:	70a2                	ld	ra,40(sp)
    80000a9c:	7402                	ld	s0,32(sp)
    80000a9e:	64e2                	ld	s1,24(sp)
    80000aa0:	6942                	ld	s2,16(sp)
    80000aa2:	69a2                	ld	s3,8(sp)
    80000aa4:	6a02                	ld	s4,0(sp)
    80000aa6:	6145                	addi	sp,sp,48
    80000aa8:	8082                	ret

0000000080000aaa <kinit>:
{
    80000aaa:	1141                	addi	sp,sp,-16
    80000aac:	e406                	sd	ra,8(sp)
    80000aae:	e022                	sd	s0,0(sp)
    80000ab0:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ab2:	00007597          	auipc	a1,0x7
    80000ab6:	5b658593          	addi	a1,a1,1462 # 80008068 <digits+0x28>
    80000aba:	00010517          	auipc	a0,0x10
    80000abe:	09650513          	addi	a0,a0,150 # 80010b50 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	084080e7          	jalr	132(ra) # 80000b46 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00021517          	auipc	a0,0x21
    80000ad2:	4b250513          	addi	a0,a0,1202 # 80021f80 <end>
    80000ad6:	00000097          	auipc	ra,0x0
    80000ada:	f88080e7          	jalr	-120(ra) # 80000a5e <freerange>
}
    80000ade:	60a2                	ld	ra,8(sp)
    80000ae0:	6402                	ld	s0,0(sp)
    80000ae2:	0141                	addi	sp,sp,16
    80000ae4:	8082                	ret

0000000080000ae6 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000ae6:	1101                	addi	sp,sp,-32
    80000ae8:	ec06                	sd	ra,24(sp)
    80000aea:	e822                	sd	s0,16(sp)
    80000aec:	e426                	sd	s1,8(sp)
    80000aee:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000af0:	00010497          	auipc	s1,0x10
    80000af4:	06048493          	addi	s1,s1,96 # 80010b50 <kmem>
    80000af8:	8526                	mv	a0,s1
    80000afa:	00000097          	auipc	ra,0x0
    80000afe:	0dc080e7          	jalr	220(ra) # 80000bd6 <acquire>
  r = kmem.freelist;
    80000b02:	6c84                	ld	s1,24(s1)
  if(r)
    80000b04:	c885                	beqz	s1,80000b34 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b06:	609c                	ld	a5,0(s1)
    80000b08:	00010517          	auipc	a0,0x10
    80000b0c:	04850513          	addi	a0,a0,72 # 80010b50 <kmem>
    80000b10:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b12:	00000097          	auipc	ra,0x0
    80000b16:	178080e7          	jalr	376(ra) # 80000c8a <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b1a:	6605                	lui	a2,0x1
    80000b1c:	4595                	li	a1,5
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	1b2080e7          	jalr	434(ra) # 80000cd2 <memset>
  return (void*)r;
}
    80000b28:	8526                	mv	a0,s1
    80000b2a:	60e2                	ld	ra,24(sp)
    80000b2c:	6442                	ld	s0,16(sp)
    80000b2e:	64a2                	ld	s1,8(sp)
    80000b30:	6105                	addi	sp,sp,32
    80000b32:	8082                	ret
  release(&kmem.lock);
    80000b34:	00010517          	auipc	a0,0x10
    80000b38:	01c50513          	addi	a0,a0,28 # 80010b50 <kmem>
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	14e080e7          	jalr	334(ra) # 80000c8a <release>
  if(r)
    80000b44:	b7d5                	j	80000b28 <kalloc+0x42>

0000000080000b46 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b46:	1141                	addi	sp,sp,-16
    80000b48:	e422                	sd	s0,8(sp)
    80000b4a:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b4c:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b4e:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b52:	00053823          	sd	zero,16(a0)
}
    80000b56:	6422                	ld	s0,8(sp)
    80000b58:	0141                	addi	sp,sp,16
    80000b5a:	8082                	ret

0000000080000b5c <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000b5c:	411c                	lw	a5,0(a0)
    80000b5e:	e399                	bnez	a5,80000b64 <holding+0x8>
    80000b60:	4501                	li	a0,0
  return r;
}
    80000b62:	8082                	ret
{
    80000b64:	1101                	addi	sp,sp,-32
    80000b66:	ec06                	sd	ra,24(sp)
    80000b68:	e822                	sd	s0,16(sp)
    80000b6a:	e426                	sd	s1,8(sp)
    80000b6c:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000b6e:	6904                	ld	s1,16(a0)
    80000b70:	00001097          	auipc	ra,0x1
    80000b74:	e20080e7          	jalr	-480(ra) # 80001990 <mycpu>
    80000b78:	40a48533          	sub	a0,s1,a0
    80000b7c:	00153513          	seqz	a0,a0
}
    80000b80:	60e2                	ld	ra,24(sp)
    80000b82:	6442                	ld	s0,16(sp)
    80000b84:	64a2                	ld	s1,8(sp)
    80000b86:	6105                	addi	sp,sp,32
    80000b88:	8082                	ret

0000000080000b8a <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000b8a:	1101                	addi	sp,sp,-32
    80000b8c:	ec06                	sd	ra,24(sp)
    80000b8e:	e822                	sd	s0,16(sp)
    80000b90:	e426                	sd	s1,8(sp)
    80000b92:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000b94:	100024f3          	csrr	s1,sstatus
    80000b98:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000b9c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000b9e:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000ba2:	00001097          	auipc	ra,0x1
    80000ba6:	dee080e7          	jalr	-530(ra) # 80001990 <mycpu>
    80000baa:	5d3c                	lw	a5,120(a0)
    80000bac:	cf89                	beqz	a5,80000bc6 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bae:	00001097          	auipc	ra,0x1
    80000bb2:	de2080e7          	jalr	-542(ra) # 80001990 <mycpu>
    80000bb6:	5d3c                	lw	a5,120(a0)
    80000bb8:	2785                	addiw	a5,a5,1
    80000bba:	dd3c                	sw	a5,120(a0)
}
    80000bbc:	60e2                	ld	ra,24(sp)
    80000bbe:	6442                	ld	s0,16(sp)
    80000bc0:	64a2                	ld	s1,8(sp)
    80000bc2:	6105                	addi	sp,sp,32
    80000bc4:	8082                	ret
    mycpu()->intena = old;
    80000bc6:	00001097          	auipc	ra,0x1
    80000bca:	dca080e7          	jalr	-566(ra) # 80001990 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000bce:	8085                	srli	s1,s1,0x1
    80000bd0:	8885                	andi	s1,s1,1
    80000bd2:	dd64                	sw	s1,124(a0)
    80000bd4:	bfe9                	j	80000bae <push_off+0x24>

0000000080000bd6 <acquire>:
{
    80000bd6:	1101                	addi	sp,sp,-32
    80000bd8:	ec06                	sd	ra,24(sp)
    80000bda:	e822                	sd	s0,16(sp)
    80000bdc:	e426                	sd	s1,8(sp)
    80000bde:	1000                	addi	s0,sp,32
    80000be0:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000be2:	00000097          	auipc	ra,0x0
    80000be6:	fa8080e7          	jalr	-88(ra) # 80000b8a <push_off>
  if(holding(lk))
    80000bea:	8526                	mv	a0,s1
    80000bec:	00000097          	auipc	ra,0x0
    80000bf0:	f70080e7          	jalr	-144(ra) # 80000b5c <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf4:	4705                	li	a4,1
  if(holding(lk))
    80000bf6:	e115                	bnez	a0,80000c1a <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000bf8:	87ba                	mv	a5,a4
    80000bfa:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000bfe:	2781                	sext.w	a5,a5
    80000c00:	ffe5                	bnez	a5,80000bf8 <acquire+0x22>
  __sync_synchronize();
    80000c02:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c06:	00001097          	auipc	ra,0x1
    80000c0a:	d8a080e7          	jalr	-630(ra) # 80001990 <mycpu>
    80000c0e:	e888                	sd	a0,16(s1)
}
    80000c10:	60e2                	ld	ra,24(sp)
    80000c12:	6442                	ld	s0,16(sp)
    80000c14:	64a2                	ld	s1,8(sp)
    80000c16:	6105                	addi	sp,sp,32
    80000c18:	8082                	ret
    panic("acquire");
    80000c1a:	00007517          	auipc	a0,0x7
    80000c1e:	45650513          	addi	a0,a0,1110 # 80008070 <digits+0x30>
    80000c22:	00000097          	auipc	ra,0x0
    80000c26:	91e080e7          	jalr	-1762(ra) # 80000540 <panic>

0000000080000c2a <pop_off>:

void
pop_off(void)
{
    80000c2a:	1141                	addi	sp,sp,-16
    80000c2c:	e406                	sd	ra,8(sp)
    80000c2e:	e022                	sd	s0,0(sp)
    80000c30:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c32:	00001097          	auipc	ra,0x1
    80000c36:	d5e080e7          	jalr	-674(ra) # 80001990 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c3a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c3e:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c40:	e78d                	bnez	a5,80000c6a <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c42:	5d3c                	lw	a5,120(a0)
    80000c44:	02f05b63          	blez	a5,80000c7a <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c48:	37fd                	addiw	a5,a5,-1
    80000c4a:	0007871b          	sext.w	a4,a5
    80000c4e:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c50:	eb09                	bnez	a4,80000c62 <pop_off+0x38>
    80000c52:	5d7c                	lw	a5,124(a0)
    80000c54:	c799                	beqz	a5,80000c62 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c56:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000c5a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000c5e:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000c62:	60a2                	ld	ra,8(sp)
    80000c64:	6402                	ld	s0,0(sp)
    80000c66:	0141                	addi	sp,sp,16
    80000c68:	8082                	ret
    panic("pop_off - interruptible");
    80000c6a:	00007517          	auipc	a0,0x7
    80000c6e:	40e50513          	addi	a0,a0,1038 # 80008078 <digits+0x38>
    80000c72:	00000097          	auipc	ra,0x0
    80000c76:	8ce080e7          	jalr	-1842(ra) # 80000540 <panic>
    panic("pop_off");
    80000c7a:	00007517          	auipc	a0,0x7
    80000c7e:	41650513          	addi	a0,a0,1046 # 80008090 <digits+0x50>
    80000c82:	00000097          	auipc	ra,0x0
    80000c86:	8be080e7          	jalr	-1858(ra) # 80000540 <panic>

0000000080000c8a <release>:
{
    80000c8a:	1101                	addi	sp,sp,-32
    80000c8c:	ec06                	sd	ra,24(sp)
    80000c8e:	e822                	sd	s0,16(sp)
    80000c90:	e426                	sd	s1,8(sp)
    80000c92:	1000                	addi	s0,sp,32
    80000c94:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000c96:	00000097          	auipc	ra,0x0
    80000c9a:	ec6080e7          	jalr	-314(ra) # 80000b5c <holding>
    80000c9e:	c115                	beqz	a0,80000cc2 <release+0x38>
  lk->cpu = 0;
    80000ca0:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000ca4:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000ca8:	0f50000f          	fence	iorw,ow
    80000cac:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cb0:	00000097          	auipc	ra,0x0
    80000cb4:	f7a080e7          	jalr	-134(ra) # 80000c2a <pop_off>
}
    80000cb8:	60e2                	ld	ra,24(sp)
    80000cba:	6442                	ld	s0,16(sp)
    80000cbc:	64a2                	ld	s1,8(sp)
    80000cbe:	6105                	addi	sp,sp,32
    80000cc0:	8082                	ret
    panic("release");
    80000cc2:	00007517          	auipc	a0,0x7
    80000cc6:	3d650513          	addi	a0,a0,982 # 80008098 <digits+0x58>
    80000cca:	00000097          	auipc	ra,0x0
    80000cce:	876080e7          	jalr	-1930(ra) # 80000540 <panic>

0000000080000cd2 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000cd2:	1141                	addi	sp,sp,-16
    80000cd4:	e422                	sd	s0,8(sp)
    80000cd6:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000cd8:	ca19                	beqz	a2,80000cee <memset+0x1c>
    80000cda:	87aa                	mv	a5,a0
    80000cdc:	1602                	slli	a2,a2,0x20
    80000cde:	9201                	srli	a2,a2,0x20
    80000ce0:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000ce4:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000ce8:	0785                	addi	a5,a5,1
    80000cea:	fee79de3          	bne	a5,a4,80000ce4 <memset+0x12>
  }
  return dst;
}
    80000cee:	6422                	ld	s0,8(sp)
    80000cf0:	0141                	addi	sp,sp,16
    80000cf2:	8082                	ret

0000000080000cf4 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000cf4:	1141                	addi	sp,sp,-16
    80000cf6:	e422                	sd	s0,8(sp)
    80000cf8:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000cfa:	ca05                	beqz	a2,80000d2a <memcmp+0x36>
    80000cfc:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000d00:	1682                	slli	a3,a3,0x20
    80000d02:	9281                	srli	a3,a3,0x20
    80000d04:	0685                	addi	a3,a3,1
    80000d06:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d08:	00054783          	lbu	a5,0(a0)
    80000d0c:	0005c703          	lbu	a4,0(a1)
    80000d10:	00e79863          	bne	a5,a4,80000d20 <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d14:	0505                	addi	a0,a0,1
    80000d16:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d18:	fed518e3          	bne	a0,a3,80000d08 <memcmp+0x14>
  }

  return 0;
    80000d1c:	4501                	li	a0,0
    80000d1e:	a019                	j	80000d24 <memcmp+0x30>
      return *s1 - *s2;
    80000d20:	40e7853b          	subw	a0,a5,a4
}
    80000d24:	6422                	ld	s0,8(sp)
    80000d26:	0141                	addi	sp,sp,16
    80000d28:	8082                	ret
  return 0;
    80000d2a:	4501                	li	a0,0
    80000d2c:	bfe5                	j	80000d24 <memcmp+0x30>

0000000080000d2e <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d2e:	1141                	addi	sp,sp,-16
    80000d30:	e422                	sd	s0,8(sp)
    80000d32:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d34:	c205                	beqz	a2,80000d54 <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d36:	02a5e263          	bltu	a1,a0,80000d5a <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d3a:	1602                	slli	a2,a2,0x20
    80000d3c:	9201                	srli	a2,a2,0x20
    80000d3e:	00c587b3          	add	a5,a1,a2
{
    80000d42:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d44:	0585                	addi	a1,a1,1
    80000d46:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdd081>
    80000d48:	fff5c683          	lbu	a3,-1(a1)
    80000d4c:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d50:	fef59ae3          	bne	a1,a5,80000d44 <memmove+0x16>

  return dst;
}
    80000d54:	6422                	ld	s0,8(sp)
    80000d56:	0141                	addi	sp,sp,16
    80000d58:	8082                	ret
  if(s < d && s + n > d){
    80000d5a:	02061693          	slli	a3,a2,0x20
    80000d5e:	9281                	srli	a3,a3,0x20
    80000d60:	00d58733          	add	a4,a1,a3
    80000d64:	fce57be3          	bgeu	a0,a4,80000d3a <memmove+0xc>
    d += n;
    80000d68:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000d6a:	fff6079b          	addiw	a5,a2,-1
    80000d6e:	1782                	slli	a5,a5,0x20
    80000d70:	9381                	srli	a5,a5,0x20
    80000d72:	fff7c793          	not	a5,a5
    80000d76:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000d78:	177d                	addi	a4,a4,-1
    80000d7a:	16fd                	addi	a3,a3,-1
    80000d7c:	00074603          	lbu	a2,0(a4)
    80000d80:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000d84:	fee79ae3          	bne	a5,a4,80000d78 <memmove+0x4a>
    80000d88:	b7f1                	j	80000d54 <memmove+0x26>

0000000080000d8a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000d8a:	1141                	addi	sp,sp,-16
    80000d8c:	e406                	sd	ra,8(sp)
    80000d8e:	e022                	sd	s0,0(sp)
    80000d90:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000d92:	00000097          	auipc	ra,0x0
    80000d96:	f9c080e7          	jalr	-100(ra) # 80000d2e <memmove>
}
    80000d9a:	60a2                	ld	ra,8(sp)
    80000d9c:	6402                	ld	s0,0(sp)
    80000d9e:	0141                	addi	sp,sp,16
    80000da0:	8082                	ret

0000000080000da2 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000da2:	1141                	addi	sp,sp,-16
    80000da4:	e422                	sd	s0,8(sp)
    80000da6:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000da8:	ce11                	beqz	a2,80000dc4 <strncmp+0x22>
    80000daa:	00054783          	lbu	a5,0(a0)
    80000dae:	cf89                	beqz	a5,80000dc8 <strncmp+0x26>
    80000db0:	0005c703          	lbu	a4,0(a1)
    80000db4:	00f71a63          	bne	a4,a5,80000dc8 <strncmp+0x26>
    n--, p++, q++;
    80000db8:	367d                	addiw	a2,a2,-1
    80000dba:	0505                	addi	a0,a0,1
    80000dbc:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000dbe:	f675                	bnez	a2,80000daa <strncmp+0x8>
  if(n == 0)
    return 0;
    80000dc0:	4501                	li	a0,0
    80000dc2:	a809                	j	80000dd4 <strncmp+0x32>
    80000dc4:	4501                	li	a0,0
    80000dc6:	a039                	j	80000dd4 <strncmp+0x32>
  if(n == 0)
    80000dc8:	ca09                	beqz	a2,80000dda <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000dca:	00054503          	lbu	a0,0(a0)
    80000dce:	0005c783          	lbu	a5,0(a1)
    80000dd2:	9d1d                	subw	a0,a0,a5
}
    80000dd4:	6422                	ld	s0,8(sp)
    80000dd6:	0141                	addi	sp,sp,16
    80000dd8:	8082                	ret
    return 0;
    80000dda:	4501                	li	a0,0
    80000ddc:	bfe5                	j	80000dd4 <strncmp+0x32>

0000000080000dde <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000dde:	1141                	addi	sp,sp,-16
    80000de0:	e422                	sd	s0,8(sp)
    80000de2:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000de4:	872a                	mv	a4,a0
    80000de6:	8832                	mv	a6,a2
    80000de8:	367d                	addiw	a2,a2,-1
    80000dea:	01005963          	blez	a6,80000dfc <strncpy+0x1e>
    80000dee:	0705                	addi	a4,a4,1
    80000df0:	0005c783          	lbu	a5,0(a1)
    80000df4:	fef70fa3          	sb	a5,-1(a4)
    80000df8:	0585                	addi	a1,a1,1
    80000dfa:	f7f5                	bnez	a5,80000de6 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000dfc:	86ba                	mv	a3,a4
    80000dfe:	00c05c63          	blez	a2,80000e16 <strncpy+0x38>
    *s++ = 0;
    80000e02:	0685                	addi	a3,a3,1
    80000e04:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e08:	40d707bb          	subw	a5,a4,a3
    80000e0c:	37fd                	addiw	a5,a5,-1
    80000e0e:	010787bb          	addw	a5,a5,a6
    80000e12:	fef048e3          	bgtz	a5,80000e02 <strncpy+0x24>
  return os;
}
    80000e16:	6422                	ld	s0,8(sp)
    80000e18:	0141                	addi	sp,sp,16
    80000e1a:	8082                	ret

0000000080000e1c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e1c:	1141                	addi	sp,sp,-16
    80000e1e:	e422                	sd	s0,8(sp)
    80000e20:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e22:	02c05363          	blez	a2,80000e48 <safestrcpy+0x2c>
    80000e26:	fff6069b          	addiw	a3,a2,-1
    80000e2a:	1682                	slli	a3,a3,0x20
    80000e2c:	9281                	srli	a3,a3,0x20
    80000e2e:	96ae                	add	a3,a3,a1
    80000e30:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e32:	00d58963          	beq	a1,a3,80000e44 <safestrcpy+0x28>
    80000e36:	0585                	addi	a1,a1,1
    80000e38:	0785                	addi	a5,a5,1
    80000e3a:	fff5c703          	lbu	a4,-1(a1)
    80000e3e:	fee78fa3          	sb	a4,-1(a5)
    80000e42:	fb65                	bnez	a4,80000e32 <safestrcpy+0x16>
    ;
  *s = 0;
    80000e44:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e48:	6422                	ld	s0,8(sp)
    80000e4a:	0141                	addi	sp,sp,16
    80000e4c:	8082                	ret

0000000080000e4e <strlen>:

int
strlen(const char *s)
{
    80000e4e:	1141                	addi	sp,sp,-16
    80000e50:	e422                	sd	s0,8(sp)
    80000e52:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e54:	00054783          	lbu	a5,0(a0)
    80000e58:	cf91                	beqz	a5,80000e74 <strlen+0x26>
    80000e5a:	0505                	addi	a0,a0,1
    80000e5c:	87aa                	mv	a5,a0
    80000e5e:	4685                	li	a3,1
    80000e60:	9e89                	subw	a3,a3,a0
    80000e62:	00f6853b          	addw	a0,a3,a5
    80000e66:	0785                	addi	a5,a5,1
    80000e68:	fff7c703          	lbu	a4,-1(a5)
    80000e6c:	fb7d                	bnez	a4,80000e62 <strlen+0x14>
    ;
  return n;
}
    80000e6e:	6422                	ld	s0,8(sp)
    80000e70:	0141                	addi	sp,sp,16
    80000e72:	8082                	ret
  for(n = 0; s[n]; n++)
    80000e74:	4501                	li	a0,0
    80000e76:	bfe5                	j	80000e6e <strlen+0x20>

0000000080000e78 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000e78:	1141                	addi	sp,sp,-16
    80000e7a:	e406                	sd	ra,8(sp)
    80000e7c:	e022                	sd	s0,0(sp)
    80000e7e:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000e80:	00001097          	auipc	ra,0x1
    80000e84:	b00080e7          	jalr	-1280(ra) # 80001980 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000e88:	00008717          	auipc	a4,0x8
    80000e8c:	a6070713          	addi	a4,a4,-1440 # 800088e8 <started>
  if(cpuid() == 0){
    80000e90:	c139                	beqz	a0,80000ed6 <main+0x5e>
    while(started == 0)
    80000e92:	431c                	lw	a5,0(a4)
    80000e94:	2781                	sext.w	a5,a5
    80000e96:	dff5                	beqz	a5,80000e92 <main+0x1a>
      ;
    __sync_synchronize();
    80000e98:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	ae4080e7          	jalr	-1308(ra) # 80001980 <cpuid>
    80000ea4:	85aa                	mv	a1,a0
    80000ea6:	00007517          	auipc	a0,0x7
    80000eaa:	21250513          	addi	a0,a0,530 # 800080b8 <digits+0x78>
    80000eae:	fffff097          	auipc	ra,0xfffff
    80000eb2:	6dc080e7          	jalr	1756(ra) # 8000058a <printf>
    kvminithart();    // turn on paging
    80000eb6:	00000097          	auipc	ra,0x0
    80000eba:	0d8080e7          	jalr	216(ra) # 80000f8e <kvminithart>
    trapinithart();   // install kernel trap vector
    80000ebe:	00002097          	auipc	ra,0x2
    80000ec2:	9dc080e7          	jalr	-1572(ra) # 8000289a <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000ec6:	00005097          	auipc	ra,0x5
    80000eca:	09a080e7          	jalr	154(ra) # 80005f60 <plicinithart>
  }

  scheduler();        
    80000ece:	00001097          	auipc	ra,0x1
    80000ed2:	042080e7          	jalr	66(ra) # 80001f10 <scheduler>
    consoleinit();
    80000ed6:	fffff097          	auipc	ra,0xfffff
    80000eda:	57a080e7          	jalr	1402(ra) # 80000450 <consoleinit>
    printfinit();
    80000ede:	00000097          	auipc	ra,0x0
    80000ee2:	88c080e7          	jalr	-1908(ra) # 8000076a <printfinit>
    printf("\n");
    80000ee6:	00007517          	auipc	a0,0x7
    80000eea:	1e250513          	addi	a0,a0,482 # 800080c8 <digits+0x88>
    80000eee:	fffff097          	auipc	ra,0xfffff
    80000ef2:	69c080e7          	jalr	1692(ra) # 8000058a <printf>
    printf("xv6 kernel is booting\n");
    80000ef6:	00007517          	auipc	a0,0x7
    80000efa:	1aa50513          	addi	a0,a0,426 # 800080a0 <digits+0x60>
    80000efe:	fffff097          	auipc	ra,0xfffff
    80000f02:	68c080e7          	jalr	1676(ra) # 8000058a <printf>
    printf("\n");
    80000f06:	00007517          	auipc	a0,0x7
    80000f0a:	1c250513          	addi	a0,a0,450 # 800080c8 <digits+0x88>
    80000f0e:	fffff097          	auipc	ra,0xfffff
    80000f12:	67c080e7          	jalr	1660(ra) # 8000058a <printf>
    kinit();         // physical page allocator
    80000f16:	00000097          	auipc	ra,0x0
    80000f1a:	b94080e7          	jalr	-1132(ra) # 80000aaa <kinit>
    kvminit();       // create kernel page table
    80000f1e:	00000097          	auipc	ra,0x0
    80000f22:	326080e7          	jalr	806(ra) # 80001244 <kvminit>
    kvminithart();   // turn on paging
    80000f26:	00000097          	auipc	ra,0x0
    80000f2a:	068080e7          	jalr	104(ra) # 80000f8e <kvminithart>
    procinit();      // process table
    80000f2e:	00001097          	auipc	ra,0x1
    80000f32:	99e080e7          	jalr	-1634(ra) # 800018cc <procinit>
    trapinit();      // trap vectors
    80000f36:	00002097          	auipc	ra,0x2
    80000f3a:	93c080e7          	jalr	-1732(ra) # 80002872 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f3e:	00002097          	auipc	ra,0x2
    80000f42:	95c080e7          	jalr	-1700(ra) # 8000289a <trapinithart>
    plicinit();      // set up interrupt controller
    80000f46:	00005097          	auipc	ra,0x5
    80000f4a:	004080e7          	jalr	4(ra) # 80005f4a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f4e:	00005097          	auipc	ra,0x5
    80000f52:	012080e7          	jalr	18(ra) # 80005f60 <plicinithart>
    binit();         // buffer cache
    80000f56:	00002097          	auipc	ra,0x2
    80000f5a:	0d4080e7          	jalr	212(ra) # 8000302a <binit>
    iinit();         // inode table
    80000f5e:	00002097          	auipc	ra,0x2
    80000f62:	774080e7          	jalr	1908(ra) # 800036d2 <iinit>
    fileinit();      // file table
    80000f66:	00003097          	auipc	ra,0x3
    80000f6a:	71a080e7          	jalr	1818(ra) # 80004680 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000f6e:	00005097          	auipc	ra,0x5
    80000f72:	0fa080e7          	jalr	250(ra) # 80006068 <virtio_disk_init>
    userinit();      // first user process
    80000f76:	00001097          	auipc	ra,0x1
    80000f7a:	d0e080e7          	jalr	-754(ra) # 80001c84 <userinit>
    __sync_synchronize();
    80000f7e:	0ff0000f          	fence
    started = 1;
    80000f82:	4785                	li	a5,1
    80000f84:	00008717          	auipc	a4,0x8
    80000f88:	96f72223          	sw	a5,-1692(a4) # 800088e8 <started>
    80000f8c:	b789                	j	80000ece <main+0x56>

0000000080000f8e <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000f8e:	1141                	addi	sp,sp,-16
    80000f90:	e422                	sd	s0,8(sp)
    80000f92:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000f94:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000f98:	00008797          	auipc	a5,0x8
    80000f9c:	9587b783          	ld	a5,-1704(a5) # 800088f0 <kernel_pagetable>
    80000fa0:	83b1                	srli	a5,a5,0xc
    80000fa2:	577d                	li	a4,-1
    80000fa4:	177e                	slli	a4,a4,0x3f
    80000fa6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000fa8:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000fac:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000fb0:	6422                	ld	s0,8(sp)
    80000fb2:	0141                	addi	sp,sp,16
    80000fb4:	8082                	ret

0000000080000fb6 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80000fb6:	7139                	addi	sp,sp,-64
    80000fb8:	fc06                	sd	ra,56(sp)
    80000fba:	f822                	sd	s0,48(sp)
    80000fbc:	f426                	sd	s1,40(sp)
    80000fbe:	f04a                	sd	s2,32(sp)
    80000fc0:	ec4e                	sd	s3,24(sp)
    80000fc2:	e852                	sd	s4,16(sp)
    80000fc4:	e456                	sd	s5,8(sp)
    80000fc6:	e05a                	sd	s6,0(sp)
    80000fc8:	0080                	addi	s0,sp,64
    80000fca:	84aa                	mv	s1,a0
    80000fcc:	89ae                	mv	s3,a1
    80000fce:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    80000fd0:	57fd                	li	a5,-1
    80000fd2:	83e9                	srli	a5,a5,0x1a
    80000fd4:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80000fd6:	4b31                	li	s6,12
  if(va >= MAXVA)
    80000fd8:	04b7f263          	bgeu	a5,a1,8000101c <walk+0x66>
    panic("walk");
    80000fdc:	00007517          	auipc	a0,0x7
    80000fe0:	0f450513          	addi	a0,a0,244 # 800080d0 <digits+0x90>
    80000fe4:	fffff097          	auipc	ra,0xfffff
    80000fe8:	55c080e7          	jalr	1372(ra) # 80000540 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80000fec:	060a8663          	beqz	s5,80001058 <walk+0xa2>
    80000ff0:	00000097          	auipc	ra,0x0
    80000ff4:	af6080e7          	jalr	-1290(ra) # 80000ae6 <kalloc>
    80000ff8:	84aa                	mv	s1,a0
    80000ffa:	c529                	beqz	a0,80001044 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80000ffc:	6605                	lui	a2,0x1
    80000ffe:	4581                	li	a1,0
    80001000:	00000097          	auipc	ra,0x0
    80001004:	cd2080e7          	jalr	-814(ra) # 80000cd2 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001008:	00c4d793          	srli	a5,s1,0xc
    8000100c:	07aa                	slli	a5,a5,0xa
    8000100e:	0017e793          	ori	a5,a5,1
    80001012:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001016:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdd077>
    80001018:	036a0063          	beq	s4,s6,80001038 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    8000101c:	0149d933          	srl	s2,s3,s4
    80001020:	1ff97913          	andi	s2,s2,511
    80001024:	090e                	slli	s2,s2,0x3
    80001026:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001028:	00093483          	ld	s1,0(s2)
    8000102c:	0014f793          	andi	a5,s1,1
    80001030:	dfd5                	beqz	a5,80000fec <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001032:	80a9                	srli	s1,s1,0xa
    80001034:	04b2                	slli	s1,s1,0xc
    80001036:	b7c5                	j	80001016 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001038:	00c9d513          	srli	a0,s3,0xc
    8000103c:	1ff57513          	andi	a0,a0,511
    80001040:	050e                	slli	a0,a0,0x3
    80001042:	9526                	add	a0,a0,s1
}
    80001044:	70e2                	ld	ra,56(sp)
    80001046:	7442                	ld	s0,48(sp)
    80001048:	74a2                	ld	s1,40(sp)
    8000104a:	7902                	ld	s2,32(sp)
    8000104c:	69e2                	ld	s3,24(sp)
    8000104e:	6a42                	ld	s4,16(sp)
    80001050:	6aa2                	ld	s5,8(sp)
    80001052:	6b02                	ld	s6,0(sp)
    80001054:	6121                	addi	sp,sp,64
    80001056:	8082                	ret
        return 0;
    80001058:	4501                	li	a0,0
    8000105a:	b7ed                	j	80001044 <walk+0x8e>

000000008000105c <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    8000105c:	57fd                	li	a5,-1
    8000105e:	83e9                	srli	a5,a5,0x1a
    80001060:	00b7f463          	bgeu	a5,a1,80001068 <walkaddr+0xc>
    return 0;
    80001064:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001066:	8082                	ret
{
    80001068:	1141                	addi	sp,sp,-16
    8000106a:	e406                	sd	ra,8(sp)
    8000106c:	e022                	sd	s0,0(sp)
    8000106e:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    80001070:	4601                	li	a2,0
    80001072:	00000097          	auipc	ra,0x0
    80001076:	f44080e7          	jalr	-188(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000107a:	c105                	beqz	a0,8000109a <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    8000107c:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    8000107e:	0117f693          	andi	a3,a5,17
    80001082:	4745                	li	a4,17
    return 0;
    80001084:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001086:	00e68663          	beq	a3,a4,80001092 <walkaddr+0x36>
}
    8000108a:	60a2                	ld	ra,8(sp)
    8000108c:	6402                	ld	s0,0(sp)
    8000108e:	0141                	addi	sp,sp,16
    80001090:	8082                	ret
  pa = PTE2PA(*pte);
    80001092:	83a9                	srli	a5,a5,0xa
    80001094:	00c79513          	slli	a0,a5,0xc
  return pa;
    80001098:	bfcd                	j	8000108a <walkaddr+0x2e>
    return 0;
    8000109a:	4501                	li	a0,0
    8000109c:	b7fd                	j	8000108a <walkaddr+0x2e>

000000008000109e <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000109e:	715d                	addi	sp,sp,-80
    800010a0:	e486                	sd	ra,72(sp)
    800010a2:	e0a2                	sd	s0,64(sp)
    800010a4:	fc26                	sd	s1,56(sp)
    800010a6:	f84a                	sd	s2,48(sp)
    800010a8:	f44e                	sd	s3,40(sp)
    800010aa:	f052                	sd	s4,32(sp)
    800010ac:	ec56                	sd	s5,24(sp)
    800010ae:	e85a                	sd	s6,16(sp)
    800010b0:	e45e                	sd	s7,8(sp)
    800010b2:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010b4:	c639                	beqz	a2,80001102 <mappages+0x64>
    800010b6:	8aaa                	mv	s5,a0
    800010b8:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    800010ba:	777d                	lui	a4,0xfffff
    800010bc:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    800010c0:	fff58993          	addi	s3,a1,-1
    800010c4:	99b2                	add	s3,s3,a2
    800010c6:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    800010ca:	893e                	mv	s2,a5
    800010cc:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    800010d0:	6b85                	lui	s7,0x1
    800010d2:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    800010d6:	4605                	li	a2,1
    800010d8:	85ca                	mv	a1,s2
    800010da:	8556                	mv	a0,s5
    800010dc:	00000097          	auipc	ra,0x0
    800010e0:	eda080e7          	jalr	-294(ra) # 80000fb6 <walk>
    800010e4:	cd1d                	beqz	a0,80001122 <mappages+0x84>
    if(*pte & PTE_V)
    800010e6:	611c                	ld	a5,0(a0)
    800010e8:	8b85                	andi	a5,a5,1
    800010ea:	e785                	bnez	a5,80001112 <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800010ec:	80b1                	srli	s1,s1,0xc
    800010ee:	04aa                	slli	s1,s1,0xa
    800010f0:	0164e4b3          	or	s1,s1,s6
    800010f4:	0014e493          	ori	s1,s1,1
    800010f8:	e104                	sd	s1,0(a0)
    if(a == last)
    800010fa:	05390063          	beq	s2,s3,8000113a <mappages+0x9c>
    a += PGSIZE;
    800010fe:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    80001100:	bfc9                	j	800010d2 <mappages+0x34>
    panic("mappages: size");
    80001102:	00007517          	auipc	a0,0x7
    80001106:	fd650513          	addi	a0,a0,-42 # 800080d8 <digits+0x98>
    8000110a:	fffff097          	auipc	ra,0xfffff
    8000110e:	436080e7          	jalr	1078(ra) # 80000540 <panic>
      panic("mappages: remap");
    80001112:	00007517          	auipc	a0,0x7
    80001116:	fd650513          	addi	a0,a0,-42 # 800080e8 <digits+0xa8>
    8000111a:	fffff097          	auipc	ra,0xfffff
    8000111e:	426080e7          	jalr	1062(ra) # 80000540 <panic>
      return -1;
    80001122:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    80001124:	60a6                	ld	ra,72(sp)
    80001126:	6406                	ld	s0,64(sp)
    80001128:	74e2                	ld	s1,56(sp)
    8000112a:	7942                	ld	s2,48(sp)
    8000112c:	79a2                	ld	s3,40(sp)
    8000112e:	7a02                	ld	s4,32(sp)
    80001130:	6ae2                	ld	s5,24(sp)
    80001132:	6b42                	ld	s6,16(sp)
    80001134:	6ba2                	ld	s7,8(sp)
    80001136:	6161                	addi	sp,sp,80
    80001138:	8082                	ret
  return 0;
    8000113a:	4501                	li	a0,0
    8000113c:	b7e5                	j	80001124 <mappages+0x86>

000000008000113e <kvmmap>:
{
    8000113e:	1141                	addi	sp,sp,-16
    80001140:	e406                	sd	ra,8(sp)
    80001142:	e022                	sd	s0,0(sp)
    80001144:	0800                	addi	s0,sp,16
    80001146:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001148:	86b2                	mv	a3,a2
    8000114a:	863e                	mv	a2,a5
    8000114c:	00000097          	auipc	ra,0x0
    80001150:	f52080e7          	jalr	-174(ra) # 8000109e <mappages>
    80001154:	e509                	bnez	a0,8000115e <kvmmap+0x20>
}
    80001156:	60a2                	ld	ra,8(sp)
    80001158:	6402                	ld	s0,0(sp)
    8000115a:	0141                	addi	sp,sp,16
    8000115c:	8082                	ret
    panic("kvmmap");
    8000115e:	00007517          	auipc	a0,0x7
    80001162:	f9a50513          	addi	a0,a0,-102 # 800080f8 <digits+0xb8>
    80001166:	fffff097          	auipc	ra,0xfffff
    8000116a:	3da080e7          	jalr	986(ra) # 80000540 <panic>

000000008000116e <kvmmake>:
{
    8000116e:	1101                	addi	sp,sp,-32
    80001170:	ec06                	sd	ra,24(sp)
    80001172:	e822                	sd	s0,16(sp)
    80001174:	e426                	sd	s1,8(sp)
    80001176:	e04a                	sd	s2,0(sp)
    80001178:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    8000117a:	00000097          	auipc	ra,0x0
    8000117e:	96c080e7          	jalr	-1684(ra) # 80000ae6 <kalloc>
    80001182:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001184:	6605                	lui	a2,0x1
    80001186:	4581                	li	a1,0
    80001188:	00000097          	auipc	ra,0x0
    8000118c:	b4a080e7          	jalr	-1206(ra) # 80000cd2 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    80001190:	4719                	li	a4,6
    80001192:	6685                	lui	a3,0x1
    80001194:	10000637          	lui	a2,0x10000
    80001198:	100005b7          	lui	a1,0x10000
    8000119c:	8526                	mv	a0,s1
    8000119e:	00000097          	auipc	ra,0x0
    800011a2:	fa0080e7          	jalr	-96(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011a6:	4719                	li	a4,6
    800011a8:	6685                	lui	a3,0x1
    800011aa:	10001637          	lui	a2,0x10001
    800011ae:	100015b7          	lui	a1,0x10001
    800011b2:	8526                	mv	a0,s1
    800011b4:	00000097          	auipc	ra,0x0
    800011b8:	f8a080e7          	jalr	-118(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    800011bc:	4719                	li	a4,6
    800011be:	004006b7          	lui	a3,0x400
    800011c2:	0c000637          	lui	a2,0xc000
    800011c6:	0c0005b7          	lui	a1,0xc000
    800011ca:	8526                	mv	a0,s1
    800011cc:	00000097          	auipc	ra,0x0
    800011d0:	f72080e7          	jalr	-142(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    800011d4:	00007917          	auipc	s2,0x7
    800011d8:	e2c90913          	addi	s2,s2,-468 # 80008000 <etext>
    800011dc:	4729                	li	a4,10
    800011de:	80007697          	auipc	a3,0x80007
    800011e2:	e2268693          	addi	a3,a3,-478 # 8000 <_entry-0x7fff8000>
    800011e6:	4605                	li	a2,1
    800011e8:	067e                	slli	a2,a2,0x1f
    800011ea:	85b2                	mv	a1,a2
    800011ec:	8526                	mv	a0,s1
    800011ee:	00000097          	auipc	ra,0x0
    800011f2:	f50080e7          	jalr	-176(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    800011f6:	4719                	li	a4,6
    800011f8:	46c5                	li	a3,17
    800011fa:	06ee                	slli	a3,a3,0x1b
    800011fc:	412686b3          	sub	a3,a3,s2
    80001200:	864a                	mv	a2,s2
    80001202:	85ca                	mv	a1,s2
    80001204:	8526                	mv	a0,s1
    80001206:	00000097          	auipc	ra,0x0
    8000120a:	f38080e7          	jalr	-200(ra) # 8000113e <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000120e:	4729                	li	a4,10
    80001210:	6685                	lui	a3,0x1
    80001212:	00006617          	auipc	a2,0x6
    80001216:	dee60613          	addi	a2,a2,-530 # 80007000 <_trampoline>
    8000121a:	040005b7          	lui	a1,0x4000
    8000121e:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001220:	05b2                	slli	a1,a1,0xc
    80001222:	8526                	mv	a0,s1
    80001224:	00000097          	auipc	ra,0x0
    80001228:	f1a080e7          	jalr	-230(ra) # 8000113e <kvmmap>
  proc_mapstacks(kpgtbl);
    8000122c:	8526                	mv	a0,s1
    8000122e:	00000097          	auipc	ra,0x0
    80001232:	608080e7          	jalr	1544(ra) # 80001836 <proc_mapstacks>
}
    80001236:	8526                	mv	a0,s1
    80001238:	60e2                	ld	ra,24(sp)
    8000123a:	6442                	ld	s0,16(sp)
    8000123c:	64a2                	ld	s1,8(sp)
    8000123e:	6902                	ld	s2,0(sp)
    80001240:	6105                	addi	sp,sp,32
    80001242:	8082                	ret

0000000080001244 <kvminit>:
{
    80001244:	1141                	addi	sp,sp,-16
    80001246:	e406                	sd	ra,8(sp)
    80001248:	e022                	sd	s0,0(sp)
    8000124a:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000124c:	00000097          	auipc	ra,0x0
    80001250:	f22080e7          	jalr	-222(ra) # 8000116e <kvmmake>
    80001254:	00007797          	auipc	a5,0x7
    80001258:	68a7be23          	sd	a0,1692(a5) # 800088f0 <kernel_pagetable>
}
    8000125c:	60a2                	ld	ra,8(sp)
    8000125e:	6402                	ld	s0,0(sp)
    80001260:	0141                	addi	sp,sp,16
    80001262:	8082                	ret

0000000080001264 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001264:	715d                	addi	sp,sp,-80
    80001266:	e486                	sd	ra,72(sp)
    80001268:	e0a2                	sd	s0,64(sp)
    8000126a:	fc26                	sd	s1,56(sp)
    8000126c:	f84a                	sd	s2,48(sp)
    8000126e:	f44e                	sd	s3,40(sp)
    80001270:	f052                	sd	s4,32(sp)
    80001272:	ec56                	sd	s5,24(sp)
    80001274:	e85a                	sd	s6,16(sp)
    80001276:	e45e                	sd	s7,8(sp)
    80001278:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    8000127a:	03459793          	slli	a5,a1,0x34
    8000127e:	e795                	bnez	a5,800012aa <uvmunmap+0x46>
    80001280:	8a2a                	mv	s4,a0
    80001282:	892e                	mv	s2,a1
    80001284:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001286:	0632                	slli	a2,a2,0xc
    80001288:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    8000128c:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000128e:	6b05                	lui	s6,0x1
    80001290:	0735e263          	bltu	a1,s3,800012f4 <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001294:	60a6                	ld	ra,72(sp)
    80001296:	6406                	ld	s0,64(sp)
    80001298:	74e2                	ld	s1,56(sp)
    8000129a:	7942                	ld	s2,48(sp)
    8000129c:	79a2                	ld	s3,40(sp)
    8000129e:	7a02                	ld	s4,32(sp)
    800012a0:	6ae2                	ld	s5,24(sp)
    800012a2:	6b42                	ld	s6,16(sp)
    800012a4:	6ba2                	ld	s7,8(sp)
    800012a6:	6161                	addi	sp,sp,80
    800012a8:	8082                	ret
    panic("uvmunmap: not aligned");
    800012aa:	00007517          	auipc	a0,0x7
    800012ae:	e5650513          	addi	a0,a0,-426 # 80008100 <digits+0xc0>
    800012b2:	fffff097          	auipc	ra,0xfffff
    800012b6:	28e080e7          	jalr	654(ra) # 80000540 <panic>
      panic("uvmunmap: walk");
    800012ba:	00007517          	auipc	a0,0x7
    800012be:	e5e50513          	addi	a0,a0,-418 # 80008118 <digits+0xd8>
    800012c2:	fffff097          	auipc	ra,0xfffff
    800012c6:	27e080e7          	jalr	638(ra) # 80000540 <panic>
      panic("uvmunmap: not mapped");
    800012ca:	00007517          	auipc	a0,0x7
    800012ce:	e5e50513          	addi	a0,a0,-418 # 80008128 <digits+0xe8>
    800012d2:	fffff097          	auipc	ra,0xfffff
    800012d6:	26e080e7          	jalr	622(ra) # 80000540 <panic>
      panic("uvmunmap: not a leaf");
    800012da:	00007517          	auipc	a0,0x7
    800012de:	e6650513          	addi	a0,a0,-410 # 80008140 <digits+0x100>
    800012e2:	fffff097          	auipc	ra,0xfffff
    800012e6:	25e080e7          	jalr	606(ra) # 80000540 <panic>
    *pte = 0;
    800012ea:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012ee:	995a                	add	s2,s2,s6
    800012f0:	fb3972e3          	bgeu	s2,s3,80001294 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    800012f4:	4601                	li	a2,0
    800012f6:	85ca                	mv	a1,s2
    800012f8:	8552                	mv	a0,s4
    800012fa:	00000097          	auipc	ra,0x0
    800012fe:	cbc080e7          	jalr	-836(ra) # 80000fb6 <walk>
    80001302:	84aa                	mv	s1,a0
    80001304:	d95d                	beqz	a0,800012ba <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001306:	6108                	ld	a0,0(a0)
    80001308:	00157793          	andi	a5,a0,1
    8000130c:	dfdd                	beqz	a5,800012ca <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    8000130e:	3ff57793          	andi	a5,a0,1023
    80001312:	fd7784e3          	beq	a5,s7,800012da <uvmunmap+0x76>
    if(do_free){
    80001316:	fc0a8ae3          	beqz	s5,800012ea <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    8000131a:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    8000131c:	0532                	slli	a0,a0,0xc
    8000131e:	fffff097          	auipc	ra,0xfffff
    80001322:	6ca080e7          	jalr	1738(ra) # 800009e8 <kfree>
    80001326:	b7d1                	j	800012ea <uvmunmap+0x86>

0000000080001328 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001328:	1101                	addi	sp,sp,-32
    8000132a:	ec06                	sd	ra,24(sp)
    8000132c:	e822                	sd	s0,16(sp)
    8000132e:	e426                	sd	s1,8(sp)
    80001330:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    80001332:	fffff097          	auipc	ra,0xfffff
    80001336:	7b4080e7          	jalr	1972(ra) # 80000ae6 <kalloc>
    8000133a:	84aa                	mv	s1,a0
  if(pagetable == 0)
    8000133c:	c519                	beqz	a0,8000134a <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000133e:	6605                	lui	a2,0x1
    80001340:	4581                	li	a1,0
    80001342:	00000097          	auipc	ra,0x0
    80001346:	990080e7          	jalr	-1648(ra) # 80000cd2 <memset>
  return pagetable;
}
    8000134a:	8526                	mv	a0,s1
    8000134c:	60e2                	ld	ra,24(sp)
    8000134e:	6442                	ld	s0,16(sp)
    80001350:	64a2                	ld	s1,8(sp)
    80001352:	6105                	addi	sp,sp,32
    80001354:	8082                	ret

0000000080001356 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001356:	7179                	addi	sp,sp,-48
    80001358:	f406                	sd	ra,40(sp)
    8000135a:	f022                	sd	s0,32(sp)
    8000135c:	ec26                	sd	s1,24(sp)
    8000135e:	e84a                	sd	s2,16(sp)
    80001360:	e44e                	sd	s3,8(sp)
    80001362:	e052                	sd	s4,0(sp)
    80001364:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    80001366:	6785                	lui	a5,0x1
    80001368:	04f67863          	bgeu	a2,a5,800013b8 <uvmfirst+0x62>
    8000136c:	8a2a                	mv	s4,a0
    8000136e:	89ae                	mv	s3,a1
    80001370:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001372:	fffff097          	auipc	ra,0xfffff
    80001376:	774080e7          	jalr	1908(ra) # 80000ae6 <kalloc>
    8000137a:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000137c:	6605                	lui	a2,0x1
    8000137e:	4581                	li	a1,0
    80001380:	00000097          	auipc	ra,0x0
    80001384:	952080e7          	jalr	-1710(ra) # 80000cd2 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001388:	4779                	li	a4,30
    8000138a:	86ca                	mv	a3,s2
    8000138c:	6605                	lui	a2,0x1
    8000138e:	4581                	li	a1,0
    80001390:	8552                	mv	a0,s4
    80001392:	00000097          	auipc	ra,0x0
    80001396:	d0c080e7          	jalr	-756(ra) # 8000109e <mappages>
  memmove(mem, src, sz);
    8000139a:	8626                	mv	a2,s1
    8000139c:	85ce                	mv	a1,s3
    8000139e:	854a                	mv	a0,s2
    800013a0:	00000097          	auipc	ra,0x0
    800013a4:	98e080e7          	jalr	-1650(ra) # 80000d2e <memmove>
}
    800013a8:	70a2                	ld	ra,40(sp)
    800013aa:	7402                	ld	s0,32(sp)
    800013ac:	64e2                	ld	s1,24(sp)
    800013ae:	6942                	ld	s2,16(sp)
    800013b0:	69a2                	ld	s3,8(sp)
    800013b2:	6a02                	ld	s4,0(sp)
    800013b4:	6145                	addi	sp,sp,48
    800013b6:	8082                	ret
    panic("uvmfirst: more than a page");
    800013b8:	00007517          	auipc	a0,0x7
    800013bc:	da050513          	addi	a0,a0,-608 # 80008158 <digits+0x118>
    800013c0:	fffff097          	auipc	ra,0xfffff
    800013c4:	180080e7          	jalr	384(ra) # 80000540 <panic>

00000000800013c8 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800013c8:	1101                	addi	sp,sp,-32
    800013ca:	ec06                	sd	ra,24(sp)
    800013cc:	e822                	sd	s0,16(sp)
    800013ce:	e426                	sd	s1,8(sp)
    800013d0:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    800013d2:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    800013d4:	00b67d63          	bgeu	a2,a1,800013ee <uvmdealloc+0x26>
    800013d8:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    800013da:	6785                	lui	a5,0x1
    800013dc:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    800013de:	00f60733          	add	a4,a2,a5
    800013e2:	76fd                	lui	a3,0xfffff
    800013e4:	8f75                	and	a4,a4,a3
    800013e6:	97ae                	add	a5,a5,a1
    800013e8:	8ff5                	and	a5,a5,a3
    800013ea:	00f76863          	bltu	a4,a5,800013fa <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800013ee:	8526                	mv	a0,s1
    800013f0:	60e2                	ld	ra,24(sp)
    800013f2:	6442                	ld	s0,16(sp)
    800013f4:	64a2                	ld	s1,8(sp)
    800013f6:	6105                	addi	sp,sp,32
    800013f8:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800013fa:	8f99                	sub	a5,a5,a4
    800013fc:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800013fe:	4685                	li	a3,1
    80001400:	0007861b          	sext.w	a2,a5
    80001404:	85ba                	mv	a1,a4
    80001406:	00000097          	auipc	ra,0x0
    8000140a:	e5e080e7          	jalr	-418(ra) # 80001264 <uvmunmap>
    8000140e:	b7c5                	j	800013ee <uvmdealloc+0x26>

0000000080001410 <uvmalloc>:
  if(newsz < oldsz)
    80001410:	0ab66563          	bltu	a2,a1,800014ba <uvmalloc+0xaa>
{
    80001414:	7139                	addi	sp,sp,-64
    80001416:	fc06                	sd	ra,56(sp)
    80001418:	f822                	sd	s0,48(sp)
    8000141a:	f426                	sd	s1,40(sp)
    8000141c:	f04a                	sd	s2,32(sp)
    8000141e:	ec4e                	sd	s3,24(sp)
    80001420:	e852                	sd	s4,16(sp)
    80001422:	e456                	sd	s5,8(sp)
    80001424:	e05a                	sd	s6,0(sp)
    80001426:	0080                	addi	s0,sp,64
    80001428:	8aaa                	mv	s5,a0
    8000142a:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000142c:	6785                	lui	a5,0x1
    8000142e:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001430:	95be                	add	a1,a1,a5
    80001432:	77fd                	lui	a5,0xfffff
    80001434:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001438:	08c9f363          	bgeu	s3,a2,800014be <uvmalloc+0xae>
    8000143c:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000143e:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001442:	fffff097          	auipc	ra,0xfffff
    80001446:	6a4080e7          	jalr	1700(ra) # 80000ae6 <kalloc>
    8000144a:	84aa                	mv	s1,a0
    if(mem == 0){
    8000144c:	c51d                	beqz	a0,8000147a <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000144e:	6605                	lui	a2,0x1
    80001450:	4581                	li	a1,0
    80001452:	00000097          	auipc	ra,0x0
    80001456:	880080e7          	jalr	-1920(ra) # 80000cd2 <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    8000145a:	875a                	mv	a4,s6
    8000145c:	86a6                	mv	a3,s1
    8000145e:	6605                	lui	a2,0x1
    80001460:	85ca                	mv	a1,s2
    80001462:	8556                	mv	a0,s5
    80001464:	00000097          	auipc	ra,0x0
    80001468:	c3a080e7          	jalr	-966(ra) # 8000109e <mappages>
    8000146c:	e90d                	bnez	a0,8000149e <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    8000146e:	6785                	lui	a5,0x1
    80001470:	993e                	add	s2,s2,a5
    80001472:	fd4968e3          	bltu	s2,s4,80001442 <uvmalloc+0x32>
  return newsz;
    80001476:	8552                	mv	a0,s4
    80001478:	a809                	j	8000148a <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    8000147a:	864e                	mv	a2,s3
    8000147c:	85ca                	mv	a1,s2
    8000147e:	8556                	mv	a0,s5
    80001480:	00000097          	auipc	ra,0x0
    80001484:	f48080e7          	jalr	-184(ra) # 800013c8 <uvmdealloc>
      return 0;
    80001488:	4501                	li	a0,0
}
    8000148a:	70e2                	ld	ra,56(sp)
    8000148c:	7442                	ld	s0,48(sp)
    8000148e:	74a2                	ld	s1,40(sp)
    80001490:	7902                	ld	s2,32(sp)
    80001492:	69e2                	ld	s3,24(sp)
    80001494:	6a42                	ld	s4,16(sp)
    80001496:	6aa2                	ld	s5,8(sp)
    80001498:	6b02                	ld	s6,0(sp)
    8000149a:	6121                	addi	sp,sp,64
    8000149c:	8082                	ret
      kfree(mem);
    8000149e:	8526                	mv	a0,s1
    800014a0:	fffff097          	auipc	ra,0xfffff
    800014a4:	548080e7          	jalr	1352(ra) # 800009e8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014a8:	864e                	mv	a2,s3
    800014aa:	85ca                	mv	a1,s2
    800014ac:	8556                	mv	a0,s5
    800014ae:	00000097          	auipc	ra,0x0
    800014b2:	f1a080e7          	jalr	-230(ra) # 800013c8 <uvmdealloc>
      return 0;
    800014b6:	4501                	li	a0,0
    800014b8:	bfc9                	j	8000148a <uvmalloc+0x7a>
    return oldsz;
    800014ba:	852e                	mv	a0,a1
}
    800014bc:	8082                	ret
  return newsz;
    800014be:	8532                	mv	a0,a2
    800014c0:	b7e9                	j	8000148a <uvmalloc+0x7a>

00000000800014c2 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    800014c2:	7179                	addi	sp,sp,-48
    800014c4:	f406                	sd	ra,40(sp)
    800014c6:	f022                	sd	s0,32(sp)
    800014c8:	ec26                	sd	s1,24(sp)
    800014ca:	e84a                	sd	s2,16(sp)
    800014cc:	e44e                	sd	s3,8(sp)
    800014ce:	e052                	sd	s4,0(sp)
    800014d0:	1800                	addi	s0,sp,48
    800014d2:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    800014d4:	84aa                	mv	s1,a0
    800014d6:	6905                	lui	s2,0x1
    800014d8:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014da:	4985                	li	s3,1
    800014dc:	a829                	j	800014f6 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800014de:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    800014e0:	00c79513          	slli	a0,a5,0xc
    800014e4:	00000097          	auipc	ra,0x0
    800014e8:	fde080e7          	jalr	-34(ra) # 800014c2 <freewalk>
      pagetable[i] = 0;
    800014ec:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    800014f0:	04a1                	addi	s1,s1,8
    800014f2:	03248163          	beq	s1,s2,80001514 <freewalk+0x52>
    pte_t pte = pagetable[i];
    800014f6:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    800014f8:	00f7f713          	andi	a4,a5,15
    800014fc:	ff3701e3          	beq	a4,s3,800014de <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001500:	8b85                	andi	a5,a5,1
    80001502:	d7fd                	beqz	a5,800014f0 <freewalk+0x2e>
      panic("freewalk: leaf");
    80001504:	00007517          	auipc	a0,0x7
    80001508:	c7450513          	addi	a0,a0,-908 # 80008178 <digits+0x138>
    8000150c:	fffff097          	auipc	ra,0xfffff
    80001510:	034080e7          	jalr	52(ra) # 80000540 <panic>
    }
  }
  kfree((void*)pagetable);
    80001514:	8552                	mv	a0,s4
    80001516:	fffff097          	auipc	ra,0xfffff
    8000151a:	4d2080e7          	jalr	1234(ra) # 800009e8 <kfree>
}
    8000151e:	70a2                	ld	ra,40(sp)
    80001520:	7402                	ld	s0,32(sp)
    80001522:	64e2                	ld	s1,24(sp)
    80001524:	6942                	ld	s2,16(sp)
    80001526:	69a2                	ld	s3,8(sp)
    80001528:	6a02                	ld	s4,0(sp)
    8000152a:	6145                	addi	sp,sp,48
    8000152c:	8082                	ret

000000008000152e <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000152e:	1101                	addi	sp,sp,-32
    80001530:	ec06                	sd	ra,24(sp)
    80001532:	e822                	sd	s0,16(sp)
    80001534:	e426                	sd	s1,8(sp)
    80001536:	1000                	addi	s0,sp,32
    80001538:	84aa                	mv	s1,a0
  if(sz > 0)
    8000153a:	e999                	bnez	a1,80001550 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    8000153c:	8526                	mv	a0,s1
    8000153e:	00000097          	auipc	ra,0x0
    80001542:	f84080e7          	jalr	-124(ra) # 800014c2 <freewalk>
}
    80001546:	60e2                	ld	ra,24(sp)
    80001548:	6442                	ld	s0,16(sp)
    8000154a:	64a2                	ld	s1,8(sp)
    8000154c:	6105                	addi	sp,sp,32
    8000154e:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    80001550:	6785                	lui	a5,0x1
    80001552:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001554:	95be                	add	a1,a1,a5
    80001556:	4685                	li	a3,1
    80001558:	00c5d613          	srli	a2,a1,0xc
    8000155c:	4581                	li	a1,0
    8000155e:	00000097          	auipc	ra,0x0
    80001562:	d06080e7          	jalr	-762(ra) # 80001264 <uvmunmap>
    80001566:	bfd9                	j	8000153c <uvmfree+0xe>

0000000080001568 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    80001568:	c679                	beqz	a2,80001636 <uvmcopy+0xce>
{
    8000156a:	715d                	addi	sp,sp,-80
    8000156c:	e486                	sd	ra,72(sp)
    8000156e:	e0a2                	sd	s0,64(sp)
    80001570:	fc26                	sd	s1,56(sp)
    80001572:	f84a                	sd	s2,48(sp)
    80001574:	f44e                	sd	s3,40(sp)
    80001576:	f052                	sd	s4,32(sp)
    80001578:	ec56                	sd	s5,24(sp)
    8000157a:	e85a                	sd	s6,16(sp)
    8000157c:	e45e                	sd	s7,8(sp)
    8000157e:	0880                	addi	s0,sp,80
    80001580:	8b2a                	mv	s6,a0
    80001582:	8aae                	mv	s5,a1
    80001584:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    80001586:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    80001588:	4601                	li	a2,0
    8000158a:	85ce                	mv	a1,s3
    8000158c:	855a                	mv	a0,s6
    8000158e:	00000097          	auipc	ra,0x0
    80001592:	a28080e7          	jalr	-1496(ra) # 80000fb6 <walk>
    80001596:	c531                	beqz	a0,800015e2 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001598:	6118                	ld	a4,0(a0)
    8000159a:	00177793          	andi	a5,a4,1
    8000159e:	cbb1                	beqz	a5,800015f2 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015a0:	00a75593          	srli	a1,a4,0xa
    800015a4:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015a8:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015ac:	fffff097          	auipc	ra,0xfffff
    800015b0:	53a080e7          	jalr	1338(ra) # 80000ae6 <kalloc>
    800015b4:	892a                	mv	s2,a0
    800015b6:	c939                	beqz	a0,8000160c <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    800015b8:	6605                	lui	a2,0x1
    800015ba:	85de                	mv	a1,s7
    800015bc:	fffff097          	auipc	ra,0xfffff
    800015c0:	772080e7          	jalr	1906(ra) # 80000d2e <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    800015c4:	8726                	mv	a4,s1
    800015c6:	86ca                	mv	a3,s2
    800015c8:	6605                	lui	a2,0x1
    800015ca:	85ce                	mv	a1,s3
    800015cc:	8556                	mv	a0,s5
    800015ce:	00000097          	auipc	ra,0x0
    800015d2:	ad0080e7          	jalr	-1328(ra) # 8000109e <mappages>
    800015d6:	e515                	bnez	a0,80001602 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    800015d8:	6785                	lui	a5,0x1
    800015da:	99be                	add	s3,s3,a5
    800015dc:	fb49e6e3          	bltu	s3,s4,80001588 <uvmcopy+0x20>
    800015e0:	a081                	j	80001620 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    800015e2:	00007517          	auipc	a0,0x7
    800015e6:	ba650513          	addi	a0,a0,-1114 # 80008188 <digits+0x148>
    800015ea:	fffff097          	auipc	ra,0xfffff
    800015ee:	f56080e7          	jalr	-170(ra) # 80000540 <panic>
      panic("uvmcopy: page not present");
    800015f2:	00007517          	auipc	a0,0x7
    800015f6:	bb650513          	addi	a0,a0,-1098 # 800081a8 <digits+0x168>
    800015fa:	fffff097          	auipc	ra,0xfffff
    800015fe:	f46080e7          	jalr	-186(ra) # 80000540 <panic>
      kfree(mem);
    80001602:	854a                	mv	a0,s2
    80001604:	fffff097          	auipc	ra,0xfffff
    80001608:	3e4080e7          	jalr	996(ra) # 800009e8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000160c:	4685                	li	a3,1
    8000160e:	00c9d613          	srli	a2,s3,0xc
    80001612:	4581                	li	a1,0
    80001614:	8556                	mv	a0,s5
    80001616:	00000097          	auipc	ra,0x0
    8000161a:	c4e080e7          	jalr	-946(ra) # 80001264 <uvmunmap>
  return -1;
    8000161e:	557d                	li	a0,-1
}
    80001620:	60a6                	ld	ra,72(sp)
    80001622:	6406                	ld	s0,64(sp)
    80001624:	74e2                	ld	s1,56(sp)
    80001626:	7942                	ld	s2,48(sp)
    80001628:	79a2                	ld	s3,40(sp)
    8000162a:	7a02                	ld	s4,32(sp)
    8000162c:	6ae2                	ld	s5,24(sp)
    8000162e:	6b42                	ld	s6,16(sp)
    80001630:	6ba2                	ld	s7,8(sp)
    80001632:	6161                	addi	sp,sp,80
    80001634:	8082                	ret
  return 0;
    80001636:	4501                	li	a0,0
}
    80001638:	8082                	ret

000000008000163a <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    8000163a:	1141                	addi	sp,sp,-16
    8000163c:	e406                	sd	ra,8(sp)
    8000163e:	e022                	sd	s0,0(sp)
    80001640:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    80001642:	4601                	li	a2,0
    80001644:	00000097          	auipc	ra,0x0
    80001648:	972080e7          	jalr	-1678(ra) # 80000fb6 <walk>
  if(pte == 0)
    8000164c:	c901                	beqz	a0,8000165c <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000164e:	611c                	ld	a5,0(a0)
    80001650:	9bbd                	andi	a5,a5,-17
    80001652:	e11c                	sd	a5,0(a0)
}
    80001654:	60a2                	ld	ra,8(sp)
    80001656:	6402                	ld	s0,0(sp)
    80001658:	0141                	addi	sp,sp,16
    8000165a:	8082                	ret
    panic("uvmclear");
    8000165c:	00007517          	auipc	a0,0x7
    80001660:	b6c50513          	addi	a0,a0,-1172 # 800081c8 <digits+0x188>
    80001664:	fffff097          	auipc	ra,0xfffff
    80001668:	edc080e7          	jalr	-292(ra) # 80000540 <panic>

000000008000166c <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    8000166c:	c6bd                	beqz	a3,800016da <copyout+0x6e>
{
    8000166e:	715d                	addi	sp,sp,-80
    80001670:	e486                	sd	ra,72(sp)
    80001672:	e0a2                	sd	s0,64(sp)
    80001674:	fc26                	sd	s1,56(sp)
    80001676:	f84a                	sd	s2,48(sp)
    80001678:	f44e                	sd	s3,40(sp)
    8000167a:	f052                	sd	s4,32(sp)
    8000167c:	ec56                	sd	s5,24(sp)
    8000167e:	e85a                	sd	s6,16(sp)
    80001680:	e45e                	sd	s7,8(sp)
    80001682:	e062                	sd	s8,0(sp)
    80001684:	0880                	addi	s0,sp,80
    80001686:	8b2a                	mv	s6,a0
    80001688:	8c2e                	mv	s8,a1
    8000168a:	8a32                	mv	s4,a2
    8000168c:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    8000168e:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001690:	6a85                	lui	s5,0x1
    80001692:	a015                	j	800016b6 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001694:	9562                	add	a0,a0,s8
    80001696:	0004861b          	sext.w	a2,s1
    8000169a:	85d2                	mv	a1,s4
    8000169c:	41250533          	sub	a0,a0,s2
    800016a0:	fffff097          	auipc	ra,0xfffff
    800016a4:	68e080e7          	jalr	1678(ra) # 80000d2e <memmove>

    len -= n;
    800016a8:	409989b3          	sub	s3,s3,s1
    src += n;
    800016ac:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016ae:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016b2:	02098263          	beqz	s3,800016d6 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    800016b6:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800016ba:	85ca                	mv	a1,s2
    800016bc:	855a                	mv	a0,s6
    800016be:	00000097          	auipc	ra,0x0
    800016c2:	99e080e7          	jalr	-1634(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800016c6:	cd01                	beqz	a0,800016de <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    800016c8:	418904b3          	sub	s1,s2,s8
    800016cc:	94d6                	add	s1,s1,s5
    800016ce:	fc99f3e3          	bgeu	s3,s1,80001694 <copyout+0x28>
    800016d2:	84ce                	mv	s1,s3
    800016d4:	b7c1                	j	80001694 <copyout+0x28>
  }
  return 0;
    800016d6:	4501                	li	a0,0
    800016d8:	a021                	j	800016e0 <copyout+0x74>
    800016da:	4501                	li	a0,0
}
    800016dc:	8082                	ret
      return -1;
    800016de:	557d                	li	a0,-1
}
    800016e0:	60a6                	ld	ra,72(sp)
    800016e2:	6406                	ld	s0,64(sp)
    800016e4:	74e2                	ld	s1,56(sp)
    800016e6:	7942                	ld	s2,48(sp)
    800016e8:	79a2                	ld	s3,40(sp)
    800016ea:	7a02                	ld	s4,32(sp)
    800016ec:	6ae2                	ld	s5,24(sp)
    800016ee:	6b42                	ld	s6,16(sp)
    800016f0:	6ba2                	ld	s7,8(sp)
    800016f2:	6c02                	ld	s8,0(sp)
    800016f4:	6161                	addi	sp,sp,80
    800016f6:	8082                	ret

00000000800016f8 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016f8:	caa5                	beqz	a3,80001768 <copyin+0x70>
{
    800016fa:	715d                	addi	sp,sp,-80
    800016fc:	e486                	sd	ra,72(sp)
    800016fe:	e0a2                	sd	s0,64(sp)
    80001700:	fc26                	sd	s1,56(sp)
    80001702:	f84a                	sd	s2,48(sp)
    80001704:	f44e                	sd	s3,40(sp)
    80001706:	f052                	sd	s4,32(sp)
    80001708:	ec56                	sd	s5,24(sp)
    8000170a:	e85a                	sd	s6,16(sp)
    8000170c:	e45e                	sd	s7,8(sp)
    8000170e:	e062                	sd	s8,0(sp)
    80001710:	0880                	addi	s0,sp,80
    80001712:	8b2a                	mv	s6,a0
    80001714:	8a2e                	mv	s4,a1
    80001716:	8c32                	mv	s8,a2
    80001718:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000171a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000171c:	6a85                	lui	s5,0x1
    8000171e:	a01d                	j	80001744 <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001720:	018505b3          	add	a1,a0,s8
    80001724:	0004861b          	sext.w	a2,s1
    80001728:	412585b3          	sub	a1,a1,s2
    8000172c:	8552                	mv	a0,s4
    8000172e:	fffff097          	auipc	ra,0xfffff
    80001732:	600080e7          	jalr	1536(ra) # 80000d2e <memmove>

    len -= n;
    80001736:	409989b3          	sub	s3,s3,s1
    dst += n;
    8000173a:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    8000173c:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001740:	02098263          	beqz	s3,80001764 <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    80001744:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001748:	85ca                	mv	a1,s2
    8000174a:	855a                	mv	a0,s6
    8000174c:	00000097          	auipc	ra,0x0
    80001750:	910080e7          	jalr	-1776(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    80001754:	cd01                	beqz	a0,8000176c <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    80001756:	418904b3          	sub	s1,s2,s8
    8000175a:	94d6                	add	s1,s1,s5
    8000175c:	fc99f2e3          	bgeu	s3,s1,80001720 <copyin+0x28>
    80001760:	84ce                	mv	s1,s3
    80001762:	bf7d                	j	80001720 <copyin+0x28>
  }
  return 0;
    80001764:	4501                	li	a0,0
    80001766:	a021                	j	8000176e <copyin+0x76>
    80001768:	4501                	li	a0,0
}
    8000176a:	8082                	ret
      return -1;
    8000176c:	557d                	li	a0,-1
}
    8000176e:	60a6                	ld	ra,72(sp)
    80001770:	6406                	ld	s0,64(sp)
    80001772:	74e2                	ld	s1,56(sp)
    80001774:	7942                	ld	s2,48(sp)
    80001776:	79a2                	ld	s3,40(sp)
    80001778:	7a02                	ld	s4,32(sp)
    8000177a:	6ae2                	ld	s5,24(sp)
    8000177c:	6b42                	ld	s6,16(sp)
    8000177e:	6ba2                	ld	s7,8(sp)
    80001780:	6c02                	ld	s8,0(sp)
    80001782:	6161                	addi	sp,sp,80
    80001784:	8082                	ret

0000000080001786 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    80001786:	c2dd                	beqz	a3,8000182c <copyinstr+0xa6>
{
    80001788:	715d                	addi	sp,sp,-80
    8000178a:	e486                	sd	ra,72(sp)
    8000178c:	e0a2                	sd	s0,64(sp)
    8000178e:	fc26                	sd	s1,56(sp)
    80001790:	f84a                	sd	s2,48(sp)
    80001792:	f44e                	sd	s3,40(sp)
    80001794:	f052                	sd	s4,32(sp)
    80001796:	ec56                	sd	s5,24(sp)
    80001798:	e85a                	sd	s6,16(sp)
    8000179a:	e45e                	sd	s7,8(sp)
    8000179c:	0880                	addi	s0,sp,80
    8000179e:	8a2a                	mv	s4,a0
    800017a0:	8b2e                	mv	s6,a1
    800017a2:	8bb2                	mv	s7,a2
    800017a4:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017a6:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017a8:	6985                	lui	s3,0x1
    800017aa:	a02d                	j	800017d4 <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017ac:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017b0:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017b2:	37fd                	addiw	a5,a5,-1
    800017b4:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    800017b8:	60a6                	ld	ra,72(sp)
    800017ba:	6406                	ld	s0,64(sp)
    800017bc:	74e2                	ld	s1,56(sp)
    800017be:	7942                	ld	s2,48(sp)
    800017c0:	79a2                	ld	s3,40(sp)
    800017c2:	7a02                	ld	s4,32(sp)
    800017c4:	6ae2                	ld	s5,24(sp)
    800017c6:	6b42                	ld	s6,16(sp)
    800017c8:	6ba2                	ld	s7,8(sp)
    800017ca:	6161                	addi	sp,sp,80
    800017cc:	8082                	ret
    srcva = va0 + PGSIZE;
    800017ce:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    800017d2:	c8a9                	beqz	s1,80001824 <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    800017d4:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    800017d8:	85ca                	mv	a1,s2
    800017da:	8552                	mv	a0,s4
    800017dc:	00000097          	auipc	ra,0x0
    800017e0:	880080e7          	jalr	-1920(ra) # 8000105c <walkaddr>
    if(pa0 == 0)
    800017e4:	c131                	beqz	a0,80001828 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    800017e6:	417906b3          	sub	a3,s2,s7
    800017ea:	96ce                	add	a3,a3,s3
    800017ec:	00d4f363          	bgeu	s1,a3,800017f2 <copyinstr+0x6c>
    800017f0:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    800017f2:	955e                	add	a0,a0,s7
    800017f4:	41250533          	sub	a0,a0,s2
    while(n > 0){
    800017f8:	daf9                	beqz	a3,800017ce <copyinstr+0x48>
    800017fa:	87da                	mv	a5,s6
      if(*p == '\0'){
    800017fc:	41650633          	sub	a2,a0,s6
    80001800:	fff48593          	addi	a1,s1,-1
    80001804:	95da                	add	a1,a1,s6
    while(n > 0){
    80001806:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    80001808:	00f60733          	add	a4,a2,a5
    8000180c:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdd080>
    80001810:	df51                	beqz	a4,800017ac <copyinstr+0x26>
        *dst = *p;
    80001812:	00e78023          	sb	a4,0(a5)
      --max;
    80001816:	40f584b3          	sub	s1,a1,a5
      dst++;
    8000181a:	0785                	addi	a5,a5,1
    while(n > 0){
    8000181c:	fed796e3          	bne	a5,a3,80001808 <copyinstr+0x82>
      dst++;
    80001820:	8b3e                	mv	s6,a5
    80001822:	b775                	j	800017ce <copyinstr+0x48>
    80001824:	4781                	li	a5,0
    80001826:	b771                	j	800017b2 <copyinstr+0x2c>
      return -1;
    80001828:	557d                	li	a0,-1
    8000182a:	b779                	j	800017b8 <copyinstr+0x32>
  int got_null = 0;
    8000182c:	4781                	li	a5,0
  if(got_null){
    8000182e:	37fd                	addiw	a5,a5,-1
    80001830:	0007851b          	sext.w	a0,a5
}
    80001834:	8082                	ret

0000000080001836 <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    80001836:	7139                	addi	sp,sp,-64
    80001838:	fc06                	sd	ra,56(sp)
    8000183a:	f822                	sd	s0,48(sp)
    8000183c:	f426                	sd	s1,40(sp)
    8000183e:	f04a                	sd	s2,32(sp)
    80001840:	ec4e                	sd	s3,24(sp)
    80001842:	e852                	sd	s4,16(sp)
    80001844:	e456                	sd	s5,8(sp)
    80001846:	e05a                	sd	s6,0(sp)
    80001848:	0080                	addi	s0,sp,64
    8000184a:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    8000184c:	0000f497          	auipc	s1,0xf
    80001850:	75448493          	addi	s1,s1,1876 # 80010fa0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001854:	8b26                	mv	s6,s1
    80001856:	00006a97          	auipc	s5,0x6
    8000185a:	7aaa8a93          	addi	s5,s5,1962 # 80008000 <etext>
    8000185e:	04000937          	lui	s2,0x4000
    80001862:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001864:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001866:	00015a17          	auipc	s4,0x15
    8000186a:	33aa0a13          	addi	s4,s4,826 # 80016ba0 <tickslock>
    char *pa = kalloc();
    8000186e:	fffff097          	auipc	ra,0xfffff
    80001872:	278080e7          	jalr	632(ra) # 80000ae6 <kalloc>
    80001876:	862a                	mv	a2,a0
    if(pa == 0)
    80001878:	c131                	beqz	a0,800018bc <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    8000187a:	416485b3          	sub	a1,s1,s6
    8000187e:	8591                	srai	a1,a1,0x4
    80001880:	000ab783          	ld	a5,0(s5)
    80001884:	02f585b3          	mul	a1,a1,a5
    80001888:	2585                	addiw	a1,a1,1
    8000188a:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    8000188e:	4719                	li	a4,6
    80001890:	6685                	lui	a3,0x1
    80001892:	40b905b3          	sub	a1,s2,a1
    80001896:	854e                	mv	a0,s3
    80001898:	00000097          	auipc	ra,0x0
    8000189c:	8a6080e7          	jalr	-1882(ra) # 8000113e <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018a0:	17048493          	addi	s1,s1,368
    800018a4:	fd4495e3          	bne	s1,s4,8000186e <proc_mapstacks+0x38>
  }
}
    800018a8:	70e2                	ld	ra,56(sp)
    800018aa:	7442                	ld	s0,48(sp)
    800018ac:	74a2                	ld	s1,40(sp)
    800018ae:	7902                	ld	s2,32(sp)
    800018b0:	69e2                	ld	s3,24(sp)
    800018b2:	6a42                	ld	s4,16(sp)
    800018b4:	6aa2                	ld	s5,8(sp)
    800018b6:	6b02                	ld	s6,0(sp)
    800018b8:	6121                	addi	sp,sp,64
    800018ba:	8082                	ret
      panic("kalloc");
    800018bc:	00007517          	auipc	a0,0x7
    800018c0:	91c50513          	addi	a0,a0,-1764 # 800081d8 <digits+0x198>
    800018c4:	fffff097          	auipc	ra,0xfffff
    800018c8:	c7c080e7          	jalr	-900(ra) # 80000540 <panic>

00000000800018cc <procinit>:

// initialize the proc table.
void
procinit(void)
{
    800018cc:	7139                	addi	sp,sp,-64
    800018ce:	fc06                	sd	ra,56(sp)
    800018d0:	f822                	sd	s0,48(sp)
    800018d2:	f426                	sd	s1,40(sp)
    800018d4:	f04a                	sd	s2,32(sp)
    800018d6:	ec4e                	sd	s3,24(sp)
    800018d8:	e852                	sd	s4,16(sp)
    800018da:	e456                	sd	s5,8(sp)
    800018dc:	e05a                	sd	s6,0(sp)
    800018de:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    800018e0:	00007597          	auipc	a1,0x7
    800018e4:	90058593          	addi	a1,a1,-1792 # 800081e0 <digits+0x1a0>
    800018e8:	0000f517          	auipc	a0,0xf
    800018ec:	28850513          	addi	a0,a0,648 # 80010b70 <pid_lock>
    800018f0:	fffff097          	auipc	ra,0xfffff
    800018f4:	256080e7          	jalr	598(ra) # 80000b46 <initlock>
  initlock(&wait_lock, "wait_lock");
    800018f8:	00007597          	auipc	a1,0x7
    800018fc:	8f058593          	addi	a1,a1,-1808 # 800081e8 <digits+0x1a8>
    80001900:	0000f517          	auipc	a0,0xf
    80001904:	28850513          	addi	a0,a0,648 # 80010b88 <wait_lock>
    80001908:	fffff097          	auipc	ra,0xfffff
    8000190c:	23e080e7          	jalr	574(ra) # 80000b46 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001910:	0000f497          	auipc	s1,0xf
    80001914:	69048493          	addi	s1,s1,1680 # 80010fa0 <proc>
      initlock(&p->lock, "proc");
    80001918:	00007b17          	auipc	s6,0x7
    8000191c:	8e0b0b13          	addi	s6,s6,-1824 # 800081f8 <digits+0x1b8>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    80001920:	8aa6                	mv	s5,s1
    80001922:	00006a17          	auipc	s4,0x6
    80001926:	6dea0a13          	addi	s4,s4,1758 # 80008000 <etext>
    8000192a:	04000937          	lui	s2,0x4000
    8000192e:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    80001930:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001932:	00015997          	auipc	s3,0x15
    80001936:	26e98993          	addi	s3,s3,622 # 80016ba0 <tickslock>
      initlock(&p->lock, "proc");
    8000193a:	85da                	mv	a1,s6
    8000193c:	8526                	mv	a0,s1
    8000193e:	fffff097          	auipc	ra,0xfffff
    80001942:	208080e7          	jalr	520(ra) # 80000b46 <initlock>
      p->state = UNUSED;
    80001946:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    8000194a:	415487b3          	sub	a5,s1,s5
    8000194e:	8791                	srai	a5,a5,0x4
    80001950:	000a3703          	ld	a4,0(s4)
    80001954:	02e787b3          	mul	a5,a5,a4
    80001958:	2785                	addiw	a5,a5,1
    8000195a:	00d7979b          	slliw	a5,a5,0xd
    8000195e:	40f907b3          	sub	a5,s2,a5
    80001962:	e4bc                	sd	a5,72(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001964:	17048493          	addi	s1,s1,368
    80001968:	fd3499e3          	bne	s1,s3,8000193a <procinit+0x6e>
  }
}
    8000196c:	70e2                	ld	ra,56(sp)
    8000196e:	7442                	ld	s0,48(sp)
    80001970:	74a2                	ld	s1,40(sp)
    80001972:	7902                	ld	s2,32(sp)
    80001974:	69e2                	ld	s3,24(sp)
    80001976:	6a42                	ld	s4,16(sp)
    80001978:	6aa2                	ld	s5,8(sp)
    8000197a:	6b02                	ld	s6,0(sp)
    8000197c:	6121                	addi	sp,sp,64
    8000197e:	8082                	ret

0000000080001980 <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001980:	1141                	addi	sp,sp,-16
    80001982:	e422                	sd	s0,8(sp)
    80001984:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001986:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001988:	2501                	sext.w	a0,a0
    8000198a:	6422                	ld	s0,8(sp)
    8000198c:	0141                	addi	sp,sp,16
    8000198e:	8082                	ret

0000000080001990 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    80001990:	1141                	addi	sp,sp,-16
    80001992:	e422                	sd	s0,8(sp)
    80001994:	0800                	addi	s0,sp,16
    80001996:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001998:	2781                	sext.w	a5,a5
    8000199a:	079e                	slli	a5,a5,0x7
  return c;
}
    8000199c:	0000f517          	auipc	a0,0xf
    800019a0:	20450513          	addi	a0,a0,516 # 80010ba0 <cpus>
    800019a4:	953e                	add	a0,a0,a5
    800019a6:	6422                	ld	s0,8(sp)
    800019a8:	0141                	addi	sp,sp,16
    800019aa:	8082                	ret

00000000800019ac <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    800019ac:	1101                	addi	sp,sp,-32
    800019ae:	ec06                	sd	ra,24(sp)
    800019b0:	e822                	sd	s0,16(sp)
    800019b2:	e426                	sd	s1,8(sp)
    800019b4:	1000                	addi	s0,sp,32
  push_off();
    800019b6:	fffff097          	auipc	ra,0xfffff
    800019ba:	1d4080e7          	jalr	468(ra) # 80000b8a <push_off>
    800019be:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    800019c0:	2781                	sext.w	a5,a5
    800019c2:	079e                	slli	a5,a5,0x7
    800019c4:	0000f717          	auipc	a4,0xf
    800019c8:	1ac70713          	addi	a4,a4,428 # 80010b70 <pid_lock>
    800019cc:	97ba                	add	a5,a5,a4
    800019ce:	7b84                	ld	s1,48(a5)
  pop_off();
    800019d0:	fffff097          	auipc	ra,0xfffff
    800019d4:	25a080e7          	jalr	602(ra) # 80000c2a <pop_off>
  return p;
}
    800019d8:	8526                	mv	a0,s1
    800019da:	60e2                	ld	ra,24(sp)
    800019dc:	6442                	ld	s0,16(sp)
    800019de:	64a2                	ld	s1,8(sp)
    800019e0:	6105                	addi	sp,sp,32
    800019e2:	8082                	ret

00000000800019e4 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    800019e4:	1141                	addi	sp,sp,-16
    800019e6:	e406                	sd	ra,8(sp)
    800019e8:	e022                	sd	s0,0(sp)
    800019ea:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    800019ec:	00000097          	auipc	ra,0x0
    800019f0:	fc0080e7          	jalr	-64(ra) # 800019ac <myproc>
    800019f4:	fffff097          	auipc	ra,0xfffff
    800019f8:	296080e7          	jalr	662(ra) # 80000c8a <release>

  if (first) {
    800019fc:	00007797          	auipc	a5,0x7
    80001a00:	e547a783          	lw	a5,-428(a5) # 80008850 <first.1>
    80001a04:	eb89                	bnez	a5,80001a16 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a06:	00001097          	auipc	ra,0x1
    80001a0a:	eac080e7          	jalr	-340(ra) # 800028b2 <usertrapret>
}
    80001a0e:	60a2                	ld	ra,8(sp)
    80001a10:	6402                	ld	s0,0(sp)
    80001a12:	0141                	addi	sp,sp,16
    80001a14:	8082                	ret
    first = 0;
    80001a16:	00007797          	auipc	a5,0x7
    80001a1a:	e207ad23          	sw	zero,-454(a5) # 80008850 <first.1>
    fsinit(ROOTDEV);
    80001a1e:	4505                	li	a0,1
    80001a20:	00002097          	auipc	ra,0x2
    80001a24:	c32080e7          	jalr	-974(ra) # 80003652 <fsinit>
    80001a28:	bff9                	j	80001a06 <forkret+0x22>

0000000080001a2a <allocpid>:
{
    80001a2a:	1101                	addi	sp,sp,-32
    80001a2c:	ec06                	sd	ra,24(sp)
    80001a2e:	e822                	sd	s0,16(sp)
    80001a30:	e426                	sd	s1,8(sp)
    80001a32:	e04a                	sd	s2,0(sp)
    80001a34:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a36:	0000f917          	auipc	s2,0xf
    80001a3a:	13a90913          	addi	s2,s2,314 # 80010b70 <pid_lock>
    80001a3e:	854a                	mv	a0,s2
    80001a40:	fffff097          	auipc	ra,0xfffff
    80001a44:	196080e7          	jalr	406(ra) # 80000bd6 <acquire>
  pid = nextpid;
    80001a48:	00007797          	auipc	a5,0x7
    80001a4c:	e0c78793          	addi	a5,a5,-500 # 80008854 <nextpid>
    80001a50:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a52:	0014871b          	addiw	a4,s1,1
    80001a56:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001a58:	854a                	mv	a0,s2
    80001a5a:	fffff097          	auipc	ra,0xfffff
    80001a5e:	230080e7          	jalr	560(ra) # 80000c8a <release>
}
    80001a62:	8526                	mv	a0,s1
    80001a64:	60e2                	ld	ra,24(sp)
    80001a66:	6442                	ld	s0,16(sp)
    80001a68:	64a2                	ld	s1,8(sp)
    80001a6a:	6902                	ld	s2,0(sp)
    80001a6c:	6105                	addi	sp,sp,32
    80001a6e:	8082                	ret

0000000080001a70 <proc_pagetable>:
{
    80001a70:	1101                	addi	sp,sp,-32
    80001a72:	ec06                	sd	ra,24(sp)
    80001a74:	e822                	sd	s0,16(sp)
    80001a76:	e426                	sd	s1,8(sp)
    80001a78:	e04a                	sd	s2,0(sp)
    80001a7a:	1000                	addi	s0,sp,32
    80001a7c:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001a7e:	00000097          	auipc	ra,0x0
    80001a82:	8aa080e7          	jalr	-1878(ra) # 80001328 <uvmcreate>
    80001a86:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001a88:	c121                	beqz	a0,80001ac8 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001a8a:	4729                	li	a4,10
    80001a8c:	00005697          	auipc	a3,0x5
    80001a90:	57468693          	addi	a3,a3,1396 # 80007000 <_trampoline>
    80001a94:	6605                	lui	a2,0x1
    80001a96:	040005b7          	lui	a1,0x4000
    80001a9a:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001a9c:	05b2                	slli	a1,a1,0xc
    80001a9e:	fffff097          	auipc	ra,0xfffff
    80001aa2:	600080e7          	jalr	1536(ra) # 8000109e <mappages>
    80001aa6:	02054863          	bltz	a0,80001ad6 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001aaa:	4719                	li	a4,6
    80001aac:	06093683          	ld	a3,96(s2)
    80001ab0:	6605                	lui	a2,0x1
    80001ab2:	020005b7          	lui	a1,0x2000
    80001ab6:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001ab8:	05b6                	slli	a1,a1,0xd
    80001aba:	8526                	mv	a0,s1
    80001abc:	fffff097          	auipc	ra,0xfffff
    80001ac0:	5e2080e7          	jalr	1506(ra) # 8000109e <mappages>
    80001ac4:	02054163          	bltz	a0,80001ae6 <proc_pagetable+0x76>
}
    80001ac8:	8526                	mv	a0,s1
    80001aca:	60e2                	ld	ra,24(sp)
    80001acc:	6442                	ld	s0,16(sp)
    80001ace:	64a2                	ld	s1,8(sp)
    80001ad0:	6902                	ld	s2,0(sp)
    80001ad2:	6105                	addi	sp,sp,32
    80001ad4:	8082                	ret
    uvmfree(pagetable, 0);
    80001ad6:	4581                	li	a1,0
    80001ad8:	8526                	mv	a0,s1
    80001ada:	00000097          	auipc	ra,0x0
    80001ade:	a54080e7          	jalr	-1452(ra) # 8000152e <uvmfree>
    return 0;
    80001ae2:	4481                	li	s1,0
    80001ae4:	b7d5                	j	80001ac8 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001ae6:	4681                	li	a3,0
    80001ae8:	4605                	li	a2,1
    80001aea:	040005b7          	lui	a1,0x4000
    80001aee:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001af0:	05b2                	slli	a1,a1,0xc
    80001af2:	8526                	mv	a0,s1
    80001af4:	fffff097          	auipc	ra,0xfffff
    80001af8:	770080e7          	jalr	1904(ra) # 80001264 <uvmunmap>
    uvmfree(pagetable, 0);
    80001afc:	4581                	li	a1,0
    80001afe:	8526                	mv	a0,s1
    80001b00:	00000097          	auipc	ra,0x0
    80001b04:	a2e080e7          	jalr	-1490(ra) # 8000152e <uvmfree>
    return 0;
    80001b08:	4481                	li	s1,0
    80001b0a:	bf7d                	j	80001ac8 <proc_pagetable+0x58>

0000000080001b0c <proc_freepagetable>:
{
    80001b0c:	1101                	addi	sp,sp,-32
    80001b0e:	ec06                	sd	ra,24(sp)
    80001b10:	e822                	sd	s0,16(sp)
    80001b12:	e426                	sd	s1,8(sp)
    80001b14:	e04a                	sd	s2,0(sp)
    80001b16:	1000                	addi	s0,sp,32
    80001b18:	84aa                	mv	s1,a0
    80001b1a:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b1c:	4681                	li	a3,0
    80001b1e:	4605                	li	a2,1
    80001b20:	040005b7          	lui	a1,0x4000
    80001b24:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b26:	05b2                	slli	a1,a1,0xc
    80001b28:	fffff097          	auipc	ra,0xfffff
    80001b2c:	73c080e7          	jalr	1852(ra) # 80001264 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b30:	4681                	li	a3,0
    80001b32:	4605                	li	a2,1
    80001b34:	020005b7          	lui	a1,0x2000
    80001b38:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b3a:	05b6                	slli	a1,a1,0xd
    80001b3c:	8526                	mv	a0,s1
    80001b3e:	fffff097          	auipc	ra,0xfffff
    80001b42:	726080e7          	jalr	1830(ra) # 80001264 <uvmunmap>
  uvmfree(pagetable, sz);
    80001b46:	85ca                	mv	a1,s2
    80001b48:	8526                	mv	a0,s1
    80001b4a:	00000097          	auipc	ra,0x0
    80001b4e:	9e4080e7          	jalr	-1564(ra) # 8000152e <uvmfree>
}
    80001b52:	60e2                	ld	ra,24(sp)
    80001b54:	6442                	ld	s0,16(sp)
    80001b56:	64a2                	ld	s1,8(sp)
    80001b58:	6902                	ld	s2,0(sp)
    80001b5a:	6105                	addi	sp,sp,32
    80001b5c:	8082                	ret

0000000080001b5e <freeproc>:
{
    80001b5e:	1101                	addi	sp,sp,-32
    80001b60:	ec06                	sd	ra,24(sp)
    80001b62:	e822                	sd	s0,16(sp)
    80001b64:	e426                	sd	s1,8(sp)
    80001b66:	1000                	addi	s0,sp,32
    80001b68:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001b6a:	7128                	ld	a0,96(a0)
    80001b6c:	c509                	beqz	a0,80001b76 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001b6e:	fffff097          	auipc	ra,0xfffff
    80001b72:	e7a080e7          	jalr	-390(ra) # 800009e8 <kfree>
  p->trapframe = 0;
    80001b76:	0604b023          	sd	zero,96(s1)
  if(p->pagetable)
    80001b7a:	6ca8                	ld	a0,88(s1)
    80001b7c:	c511                	beqz	a0,80001b88 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001b7e:	68ac                	ld	a1,80(s1)
    80001b80:	00000097          	auipc	ra,0x0
    80001b84:	f8c080e7          	jalr	-116(ra) # 80001b0c <proc_freepagetable>
  p->pagetable = 0;
    80001b88:	0404bc23          	sd	zero,88(s1)
  p->sz = 0;
    80001b8c:	0404b823          	sd	zero,80(s1)
  p->pid = 0;
    80001b90:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001b94:	0404b023          	sd	zero,64(s1)
  p->name[0] = 0;
    80001b98:	16048023          	sb	zero,352(s1)
  p->chan = 0;
    80001b9c:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001ba0:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001ba4:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001ba8:	0004ac23          	sw	zero,24(s1)
}
    80001bac:	60e2                	ld	ra,24(sp)
    80001bae:	6442                	ld	s0,16(sp)
    80001bb0:	64a2                	ld	s1,8(sp)
    80001bb2:	6105                	addi	sp,sp,32
    80001bb4:	8082                	ret

0000000080001bb6 <allocproc>:
{
    80001bb6:	1101                	addi	sp,sp,-32
    80001bb8:	ec06                	sd	ra,24(sp)
    80001bba:	e822                	sd	s0,16(sp)
    80001bbc:	e426                	sd	s1,8(sp)
    80001bbe:	e04a                	sd	s2,0(sp)
    80001bc0:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bc2:	0000f497          	auipc	s1,0xf
    80001bc6:	3de48493          	addi	s1,s1,990 # 80010fa0 <proc>
    80001bca:	00015917          	auipc	s2,0x15
    80001bce:	fd690913          	addi	s2,s2,-42 # 80016ba0 <tickslock>
    acquire(&p->lock);
    80001bd2:	8526                	mv	a0,s1
    80001bd4:	fffff097          	auipc	ra,0xfffff
    80001bd8:	002080e7          	jalr	2(ra) # 80000bd6 <acquire>
    if(p->state == UNUSED) {
    80001bdc:	4c9c                	lw	a5,24(s1)
    80001bde:	cf81                	beqz	a5,80001bf6 <allocproc+0x40>
      release(&p->lock);
    80001be0:	8526                	mv	a0,s1
    80001be2:	fffff097          	auipc	ra,0xfffff
    80001be6:	0a8080e7          	jalr	168(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bea:	17048493          	addi	s1,s1,368
    80001bee:	ff2492e3          	bne	s1,s2,80001bd2 <allocproc+0x1c>
  return 0;
    80001bf2:	4481                	li	s1,0
    80001bf4:	a889                	j	80001c46 <allocproc+0x90>
  p->pid = allocpid();
    80001bf6:	00000097          	auipc	ra,0x0
    80001bfa:	e34080e7          	jalr	-460(ra) # 80001a2a <allocpid>
    80001bfe:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c00:	4785                	li	a5,1
    80001c02:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c04:	fffff097          	auipc	ra,0xfffff
    80001c08:	ee2080e7          	jalr	-286(ra) # 80000ae6 <kalloc>
    80001c0c:	892a                	mv	s2,a0
    80001c0e:	f0a8                	sd	a0,96(s1)
    80001c10:	c131                	beqz	a0,80001c54 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001c12:	8526                	mv	a0,s1
    80001c14:	00000097          	auipc	ra,0x0
    80001c18:	e5c080e7          	jalr	-420(ra) # 80001a70 <proc_pagetable>
    80001c1c:	892a                	mv	s2,a0
    80001c1e:	eca8                	sd	a0,88(s1)
  if(p->pagetable == 0){
    80001c20:	c531                	beqz	a0,80001c6c <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c22:	07000613          	li	a2,112
    80001c26:	4581                	li	a1,0
    80001c28:	06848513          	addi	a0,s1,104
    80001c2c:	fffff097          	auipc	ra,0xfffff
    80001c30:	0a6080e7          	jalr	166(ra) # 80000cd2 <memset>
  p->context.ra = (uint64)forkret;
    80001c34:	00000797          	auipc	a5,0x0
    80001c38:	db078793          	addi	a5,a5,-592 # 800019e4 <forkret>
    80001c3c:	f4bc                	sd	a5,104(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c3e:	64bc                	ld	a5,72(s1)
    80001c40:	6705                	lui	a4,0x1
    80001c42:	97ba                	add	a5,a5,a4
    80001c44:	f8bc                	sd	a5,112(s1)
}
    80001c46:	8526                	mv	a0,s1
    80001c48:	60e2                	ld	ra,24(sp)
    80001c4a:	6442                	ld	s0,16(sp)
    80001c4c:	64a2                	ld	s1,8(sp)
    80001c4e:	6902                	ld	s2,0(sp)
    80001c50:	6105                	addi	sp,sp,32
    80001c52:	8082                	ret
    freeproc(p);
    80001c54:	8526                	mv	a0,s1
    80001c56:	00000097          	auipc	ra,0x0
    80001c5a:	f08080e7          	jalr	-248(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001c5e:	8526                	mv	a0,s1
    80001c60:	fffff097          	auipc	ra,0xfffff
    80001c64:	02a080e7          	jalr	42(ra) # 80000c8a <release>
    return 0;
    80001c68:	84ca                	mv	s1,s2
    80001c6a:	bff1                	j	80001c46 <allocproc+0x90>
    freeproc(p);
    80001c6c:	8526                	mv	a0,s1
    80001c6e:	00000097          	auipc	ra,0x0
    80001c72:	ef0080e7          	jalr	-272(ra) # 80001b5e <freeproc>
    release(&p->lock);
    80001c76:	8526                	mv	a0,s1
    80001c78:	fffff097          	auipc	ra,0xfffff
    80001c7c:	012080e7          	jalr	18(ra) # 80000c8a <release>
    return 0;
    80001c80:	84ca                	mv	s1,s2
    80001c82:	b7d1                	j	80001c46 <allocproc+0x90>

0000000080001c84 <userinit>:
{
    80001c84:	1101                	addi	sp,sp,-32
    80001c86:	ec06                	sd	ra,24(sp)
    80001c88:	e822                	sd	s0,16(sp)
    80001c8a:	e426                	sd	s1,8(sp)
    80001c8c:	1000                	addi	s0,sp,32
  p = allocproc();
    80001c8e:	00000097          	auipc	ra,0x0
    80001c92:	f28080e7          	jalr	-216(ra) # 80001bb6 <allocproc>
    80001c96:	84aa                	mv	s1,a0
  initproc = p;
    80001c98:	00007797          	auipc	a5,0x7
    80001c9c:	c6a7b023          	sd	a0,-928(a5) # 800088f8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001ca0:	03400613          	li	a2,52
    80001ca4:	00007597          	auipc	a1,0x7
    80001ca8:	bcc58593          	addi	a1,a1,-1076 # 80008870 <initcode>
    80001cac:	6d28                	ld	a0,88(a0)
    80001cae:	fffff097          	auipc	ra,0xfffff
    80001cb2:	6a8080e7          	jalr	1704(ra) # 80001356 <uvmfirst>
  p->sz = PGSIZE;
    80001cb6:	6785                	lui	a5,0x1
    80001cb8:	e8bc                	sd	a5,80(s1)
  p->trapframe->epc = 0;      // user program counter
    80001cba:	70b8                	ld	a4,96(s1)
    80001cbc:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001cc0:	70b8                	ld	a4,96(s1)
    80001cc2:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001cc4:	4641                	li	a2,16
    80001cc6:	00006597          	auipc	a1,0x6
    80001cca:	53a58593          	addi	a1,a1,1338 # 80008200 <digits+0x1c0>
    80001cce:	16048513          	addi	a0,s1,352
    80001cd2:	fffff097          	auipc	ra,0xfffff
    80001cd6:	14a080e7          	jalr	330(ra) # 80000e1c <safestrcpy>
  p->cwd = namei("/");
    80001cda:	00006517          	auipc	a0,0x6
    80001cde:	53650513          	addi	a0,a0,1334 # 80008210 <digits+0x1d0>
    80001ce2:	00002097          	auipc	ra,0x2
    80001ce6:	39a080e7          	jalr	922(ra) # 8000407c <namei>
    80001cea:	14a4bc23          	sd	a0,344(s1)
  p->state = RUNNABLE;
    80001cee:	478d                	li	a5,3
    80001cf0:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001cf2:	8526                	mv	a0,s1
    80001cf4:	fffff097          	auipc	ra,0xfffff
    80001cf8:	f96080e7          	jalr	-106(ra) # 80000c8a <release>
}
    80001cfc:	60e2                	ld	ra,24(sp)
    80001cfe:	6442                	ld	s0,16(sp)
    80001d00:	64a2                	ld	s1,8(sp)
    80001d02:	6105                	addi	sp,sp,32
    80001d04:	8082                	ret

0000000080001d06 <growproc>:
{
    80001d06:	1101                	addi	sp,sp,-32
    80001d08:	ec06                	sd	ra,24(sp)
    80001d0a:	e822                	sd	s0,16(sp)
    80001d0c:	e426                	sd	s1,8(sp)
    80001d0e:	e04a                	sd	s2,0(sp)
    80001d10:	1000                	addi	s0,sp,32
    80001d12:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d14:	00000097          	auipc	ra,0x0
    80001d18:	c98080e7          	jalr	-872(ra) # 800019ac <myproc>
    80001d1c:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d1e:	692c                	ld	a1,80(a0)
  if(n > 0){
    80001d20:	01204c63          	bgtz	s2,80001d38 <growproc+0x32>
  } else if(n < 0){
    80001d24:	02094663          	bltz	s2,80001d50 <growproc+0x4a>
  p->sz = sz;
    80001d28:	e8ac                	sd	a1,80(s1)
  return 0;
    80001d2a:	4501                	li	a0,0
}
    80001d2c:	60e2                	ld	ra,24(sp)
    80001d2e:	6442                	ld	s0,16(sp)
    80001d30:	64a2                	ld	s1,8(sp)
    80001d32:	6902                	ld	s2,0(sp)
    80001d34:	6105                	addi	sp,sp,32
    80001d36:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001d38:	4691                	li	a3,4
    80001d3a:	00b90633          	add	a2,s2,a1
    80001d3e:	6d28                	ld	a0,88(a0)
    80001d40:	fffff097          	auipc	ra,0xfffff
    80001d44:	6d0080e7          	jalr	1744(ra) # 80001410 <uvmalloc>
    80001d48:	85aa                	mv	a1,a0
    80001d4a:	fd79                	bnez	a0,80001d28 <growproc+0x22>
      return -1;
    80001d4c:	557d                	li	a0,-1
    80001d4e:	bff9                	j	80001d2c <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d50:	00b90633          	add	a2,s2,a1
    80001d54:	6d28                	ld	a0,88(a0)
    80001d56:	fffff097          	auipc	ra,0xfffff
    80001d5a:	672080e7          	jalr	1650(ra) # 800013c8 <uvmdealloc>
    80001d5e:	85aa                	mv	a1,a0
    80001d60:	b7e1                	j	80001d28 <growproc+0x22>

0000000080001d62 <fork>:
{
    80001d62:	7139                	addi	sp,sp,-64
    80001d64:	fc06                	sd	ra,56(sp)
    80001d66:	f822                	sd	s0,48(sp)
    80001d68:	f426                	sd	s1,40(sp)
    80001d6a:	f04a                	sd	s2,32(sp)
    80001d6c:	ec4e                	sd	s3,24(sp)
    80001d6e:	e852                	sd	s4,16(sp)
    80001d70:	e456                	sd	s5,8(sp)
    80001d72:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001d74:	00000097          	auipc	ra,0x0
    80001d78:	c38080e7          	jalr	-968(ra) # 800019ac <myproc>
    80001d7c:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001d7e:	00000097          	auipc	ra,0x0
    80001d82:	e38080e7          	jalr	-456(ra) # 80001bb6 <allocproc>
    80001d86:	12050263          	beqz	a0,80001eaa <fork+0x148>
    80001d8a:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001d8c:	050ab603          	ld	a2,80(s5)
    80001d90:	6d2c                	ld	a1,88(a0)
    80001d92:	058ab503          	ld	a0,88(s5)
    80001d96:	fffff097          	auipc	ra,0xfffff
    80001d9a:	7d2080e7          	jalr	2002(ra) # 80001568 <uvmcopy>
    80001d9e:	04054e63          	bltz	a0,80001dfa <fork+0x98>
  np->sz = p->sz;
    80001da2:	050ab783          	ld	a5,80(s5)
    80001da6:	04f9b823          	sd	a5,80(s3)
  np->initial_tickets = p->initial_tickets;
    80001daa:	034aa783          	lw	a5,52(s5)
    80001dae:	02f9aa23          	sw	a5,52(s3)
  np->current_tickets = p->initial_tickets;
    80001db2:	02f9ac23          	sw	a5,56(s3)
  *(np->trapframe) = *(p->trapframe);
    80001db6:	060ab683          	ld	a3,96(s5)
    80001dba:	87b6                	mv	a5,a3
    80001dbc:	0609b703          	ld	a4,96(s3)
    80001dc0:	12068693          	addi	a3,a3,288
    80001dc4:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001dc8:	6788                	ld	a0,8(a5)
    80001dca:	6b8c                	ld	a1,16(a5)
    80001dcc:	6f90                	ld	a2,24(a5)
    80001dce:	01073023          	sd	a6,0(a4)
    80001dd2:	e708                	sd	a0,8(a4)
    80001dd4:	eb0c                	sd	a1,16(a4)
    80001dd6:	ef10                	sd	a2,24(a4)
    80001dd8:	02078793          	addi	a5,a5,32
    80001ddc:	02070713          	addi	a4,a4,32
    80001de0:	fed792e3          	bne	a5,a3,80001dc4 <fork+0x62>
  np->trapframe->a0 = 0;
    80001de4:	0609b783          	ld	a5,96(s3)
    80001de8:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001dec:	0d8a8493          	addi	s1,s5,216
    80001df0:	0d898913          	addi	s2,s3,216
    80001df4:	158a8a13          	addi	s4,s5,344
    80001df8:	a00d                	j	80001e1a <fork+0xb8>
    freeproc(np);
    80001dfa:	854e                	mv	a0,s3
    80001dfc:	00000097          	auipc	ra,0x0
    80001e00:	d62080e7          	jalr	-670(ra) # 80001b5e <freeproc>
    release(&np->lock);
    80001e04:	854e                	mv	a0,s3
    80001e06:	fffff097          	auipc	ra,0xfffff
    80001e0a:	e84080e7          	jalr	-380(ra) # 80000c8a <release>
    return -1;
    80001e0e:	597d                	li	s2,-1
    80001e10:	a059                	j	80001e96 <fork+0x134>
  for(i = 0; i < NOFILE; i++)
    80001e12:	04a1                	addi	s1,s1,8
    80001e14:	0921                	addi	s2,s2,8
    80001e16:	01448b63          	beq	s1,s4,80001e2c <fork+0xca>
    if(p->ofile[i])
    80001e1a:	6088                	ld	a0,0(s1)
    80001e1c:	d97d                	beqz	a0,80001e12 <fork+0xb0>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e1e:	00003097          	auipc	ra,0x3
    80001e22:	8f4080e7          	jalr	-1804(ra) # 80004712 <filedup>
    80001e26:	00a93023          	sd	a0,0(s2)
    80001e2a:	b7e5                	j	80001e12 <fork+0xb0>
  np->cwd = idup(p->cwd);
    80001e2c:	158ab503          	ld	a0,344(s5)
    80001e30:	00002097          	auipc	ra,0x2
    80001e34:	a62080e7          	jalr	-1438(ra) # 80003892 <idup>
    80001e38:	14a9bc23          	sd	a0,344(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e3c:	4641                	li	a2,16
    80001e3e:	160a8593          	addi	a1,s5,352
    80001e42:	16098513          	addi	a0,s3,352
    80001e46:	fffff097          	auipc	ra,0xfffff
    80001e4a:	fd6080e7          	jalr	-42(ra) # 80000e1c <safestrcpy>
  pid = np->pid;
    80001e4e:	0309a903          	lw	s2,48(s3)
  release(&np->lock);
    80001e52:	854e                	mv	a0,s3
    80001e54:	fffff097          	auipc	ra,0xfffff
    80001e58:	e36080e7          	jalr	-458(ra) # 80000c8a <release>
  acquire(&wait_lock);
    80001e5c:	0000f497          	auipc	s1,0xf
    80001e60:	d2c48493          	addi	s1,s1,-724 # 80010b88 <wait_lock>
    80001e64:	8526                	mv	a0,s1
    80001e66:	fffff097          	auipc	ra,0xfffff
    80001e6a:	d70080e7          	jalr	-656(ra) # 80000bd6 <acquire>
  np->parent = p;
    80001e6e:	0559b023          	sd	s5,64(s3)
  release(&wait_lock);
    80001e72:	8526                	mv	a0,s1
    80001e74:	fffff097          	auipc	ra,0xfffff
    80001e78:	e16080e7          	jalr	-490(ra) # 80000c8a <release>
  acquire(&np->lock);
    80001e7c:	854e                	mv	a0,s3
    80001e7e:	fffff097          	auipc	ra,0xfffff
    80001e82:	d58080e7          	jalr	-680(ra) # 80000bd6 <acquire>
  np->state = RUNNABLE;
    80001e86:	478d                	li	a5,3
    80001e88:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80001e8c:	854e                	mv	a0,s3
    80001e8e:	fffff097          	auipc	ra,0xfffff
    80001e92:	dfc080e7          	jalr	-516(ra) # 80000c8a <release>
}
    80001e96:	854a                	mv	a0,s2
    80001e98:	70e2                	ld	ra,56(sp)
    80001e9a:	7442                	ld	s0,48(sp)
    80001e9c:	74a2                	ld	s1,40(sp)
    80001e9e:	7902                	ld	s2,32(sp)
    80001ea0:	69e2                	ld	s3,24(sp)
    80001ea2:	6a42                	ld	s4,16(sp)
    80001ea4:	6aa2                	ld	s5,8(sp)
    80001ea6:	6121                	addi	sp,sp,64
    80001ea8:	8082                	ret
    return -1;
    80001eaa:	597d                	li	s2,-1
    80001eac:	b7ed                	j	80001e96 <fork+0x134>

0000000080001eae <get_total_runnable_tickets>:
{
    80001eae:	7179                	addi	sp,sp,-48
    80001eb0:	f406                	sd	ra,40(sp)
    80001eb2:	f022                	sd	s0,32(sp)
    80001eb4:	ec26                	sd	s1,24(sp)
    80001eb6:	e84a                	sd	s2,16(sp)
    80001eb8:	e44e                	sd	s3,8(sp)
    80001eba:	e052                	sd	s4,0(sp)
    80001ebc:	1800                	addi	s0,sp,48
  int total_ticket_count = 0;
    80001ebe:	4a01                	li	s4,0
  for(p = proc; p < &proc[NPROC]; p++){
    80001ec0:	0000f497          	auipc	s1,0xf
    80001ec4:	0e048493          	addi	s1,s1,224 # 80010fa0 <proc>
    if(p->state == RUNNABLE){
    80001ec8:	498d                	li	s3,3
  for(p = proc; p < &proc[NPROC]; p++){
    80001eca:	00015917          	auipc	s2,0x15
    80001ece:	cd690913          	addi	s2,s2,-810 # 80016ba0 <tickslock>
    80001ed2:	a811                	j	80001ee6 <get_total_runnable_tickets+0x38>
    release(&p->lock);
    80001ed4:	8526                	mv	a0,s1
    80001ed6:	fffff097          	auipc	ra,0xfffff
    80001eda:	db4080e7          	jalr	-588(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++){
    80001ede:	17048493          	addi	s1,s1,368
    80001ee2:	01248e63          	beq	s1,s2,80001efe <get_total_runnable_tickets+0x50>
    acquire(&p->lock);
    80001ee6:	8526                	mv	a0,s1
    80001ee8:	fffff097          	auipc	ra,0xfffff
    80001eec:	cee080e7          	jalr	-786(ra) # 80000bd6 <acquire>
    if(p->state == RUNNABLE){
    80001ef0:	4c9c                	lw	a5,24(s1)
    80001ef2:	ff3791e3          	bne	a5,s3,80001ed4 <get_total_runnable_tickets+0x26>
      total_ticket_count += p->current_tickets;
    80001ef6:	5c9c                	lw	a5,56(s1)
    80001ef8:	01478a3b          	addw	s4,a5,s4
    80001efc:	bfe1                	j	80001ed4 <get_total_runnable_tickets+0x26>
}
    80001efe:	8552                	mv	a0,s4
    80001f00:	70a2                	ld	ra,40(sp)
    80001f02:	7402                	ld	s0,32(sp)
    80001f04:	64e2                	ld	s1,24(sp)
    80001f06:	6942                	ld	s2,16(sp)
    80001f08:	69a2                	ld	s3,8(sp)
    80001f0a:	6a02                	ld	s4,0(sp)
    80001f0c:	6145                	addi	sp,sp,48
    80001f0e:	8082                	ret

0000000080001f10 <scheduler>:
{
    80001f10:	715d                	addi	sp,sp,-80
    80001f12:	e486                	sd	ra,72(sp)
    80001f14:	e0a2                	sd	s0,64(sp)
    80001f16:	fc26                	sd	s1,56(sp)
    80001f18:	f84a                	sd	s2,48(sp)
    80001f1a:	f44e                	sd	s3,40(sp)
    80001f1c:	f052                	sd	s4,32(sp)
    80001f1e:	ec56                	sd	s5,24(sp)
    80001f20:	e85a                	sd	s6,16(sp)
    80001f22:	e45e                	sd	s7,8(sp)
    80001f24:	e062                	sd	s8,0(sp)
    80001f26:	0880                	addi	s0,sp,80
    80001f28:	8492                	mv	s1,tp
  int id = r_tp();
    80001f2a:	2481                	sext.w	s1,s1
  acquire(&proc->lock);
    80001f2c:	0000f517          	auipc	a0,0xf
    80001f30:	07450513          	addi	a0,a0,116 # 80010fa0 <proc>
    80001f34:	fffff097          	auipc	ra,0xfffff
    80001f38:	ca2080e7          	jalr	-862(ra) # 80000bd6 <acquire>
  proc->initial_tickets = 1;
    80001f3c:	0000f517          	auipc	a0,0xf
    80001f40:	06450513          	addi	a0,a0,100 # 80010fa0 <proc>
    80001f44:	4785                	li	a5,1
    80001f46:	d95c                	sw	a5,52(a0)
  proc->current_tickets = 1;
    80001f48:	dd1c                	sw	a5,56(a0)
  proc->ticks_used = 0;
    80001f4a:	02052e23          	sw	zero,60(a0)
  release(&proc->lock);
    80001f4e:	fffff097          	auipc	ra,0xfffff
    80001f52:	d3c080e7          	jalr	-708(ra) # 80000c8a <release>
  c->proc = 0;
    80001f56:	00749b13          	slli	s6,s1,0x7
    80001f5a:	0000f797          	auipc	a5,0xf
    80001f5e:	c1678793          	addi	a5,a5,-1002 # 80010b70 <pid_lock>
    80001f62:	97da                	add	a5,a5,s6
    80001f64:	0207b823          	sd	zero,48(a5)
      swtch(&c->context, &p->context);
    80001f68:	0000f797          	auipc	a5,0xf
    80001f6c:	c4078793          	addi	a5,a5,-960 # 80010ba8 <cpus+0x8>
    80001f70:	9b3e                	add	s6,s6,a5
        if(p->state == RUNNABLE){
    80001f72:	490d                	li	s2,3
      for(p = proc; p < &proc[NPROC]; p++){
    80001f74:	00015997          	auipc	s3,0x15
    80001f78:	c2c98993          	addi	s3,s3,-980 # 80016ba0 <tickslock>
      p->state = RUNNING;
    80001f7c:	4b91                	li	s7,4
      c->proc = p;
    80001f7e:	049e                	slli	s1,s1,0x7
    80001f80:	0000fa97          	auipc	s5,0xf
    80001f84:	bf0a8a93          	addi	s5,s5,-1040 # 80010b70 <pid_lock>
    80001f88:	9aa6                	add	s5,s5,s1
    80001f8a:	a075                	j	80002036 <scheduler+0x126>
      for(p = proc; p < &proc[NPROC]; p++){
    80001f8c:	0000f497          	auipc	s1,0xf
    80001f90:	01448493          	addi	s1,s1,20 # 80010fa0 <proc>
    80001f94:	a811                	j	80001fa8 <scheduler+0x98>
        release(&p->lock);
    80001f96:	8526                	mv	a0,s1
    80001f98:	fffff097          	auipc	ra,0xfffff
    80001f9c:	cf2080e7          	jalr	-782(ra) # 80000c8a <release>
      for(p = proc; p < &proc[NPROC]; p++){
    80001fa0:	17048493          	addi	s1,s1,368
    80001fa4:	0b348463          	beq	s1,s3,8000204c <scheduler+0x13c>
        acquire(&p->lock);
    80001fa8:	8526                	mv	a0,s1
    80001faa:	fffff097          	auipc	ra,0xfffff
    80001fae:	c2c080e7          	jalr	-980(ra) # 80000bd6 <acquire>
        if(p->state == RUNNABLE){
    80001fb2:	4c9c                	lw	a5,24(s1)
    80001fb4:	ff2791e3          	bne	a5,s2,80001f96 <scheduler+0x86>
          p->current_tickets = p->initial_tickets;
    80001fb8:	58dc                	lw	a5,52(s1)
    80001fba:	dc9c                	sw	a5,56(s1)
    80001fbc:	bfe9                	j	80001f96 <scheduler+0x86>
      release(&p->lock);
    80001fbe:	8526                	mv	a0,s1
    80001fc0:	fffff097          	auipc	ra,0xfffff
    80001fc4:	cca080e7          	jalr	-822(ra) # 80000c8a <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001fc8:	17048493          	addi	s1,s1,368
    80001fcc:	03348463          	beq	s1,s3,80001ff4 <scheduler+0xe4>
      acquire(&p->lock);
    80001fd0:	8526                	mv	a0,s1
    80001fd2:	fffff097          	auipc	ra,0xfffff
    80001fd6:	c04080e7          	jalr	-1020(ra) # 80000bd6 <acquire>
      if(p->state == RUNNABLE) {        
    80001fda:	4c9c                	lw	a5,24(s1)
    80001fdc:	ff2791e3          	bne	a5,s2,80001fbe <scheduler+0xae>
        current_ticket_count += p->current_tickets;
    80001fe0:	5c9c                	lw	a5,56(s1)
    80001fe2:	01478a3b          	addw	s4,a5,s4
        if(current_ticket_count > random_number){
    80001fe6:	fd4c5ce3          	bge	s8,s4,80001fbe <scheduler+0xae>
          release(&p->lock);
    80001fea:	8526                	mv	a0,s1
    80001fec:	fffff097          	auipc	ra,0xfffff
    80001ff0:	c9e080e7          	jalr	-866(ra) # 80000c8a <release>
    acquire(&p->lock);
    80001ff4:	8a26                	mv	s4,s1
    80001ff6:	8526                	mv	a0,s1
    80001ff8:	fffff097          	auipc	ra,0xfffff
    80001ffc:	bde080e7          	jalr	-1058(ra) # 80000bd6 <acquire>
    if(p->state == RUNNABLE){
    80002000:	4c9c                	lw	a5,24(s1)
    80002002:	03279563          	bne	a5,s2,8000202c <scheduler+0x11c>
      p->current_tickets--;
    80002006:	5c9c                	lw	a5,56(s1)
    80002008:	37fd                	addiw	a5,a5,-1
    8000200a:	dc9c                	sw	a5,56(s1)
      p->ticks_used++;
    8000200c:	5cdc                	lw	a5,60(s1)
    8000200e:	2785                	addiw	a5,a5,1
    80002010:	dcdc                	sw	a5,60(s1)
      p->state = RUNNING;
    80002012:	0174ac23          	sw	s7,24(s1)
      c->proc = p;
    80002016:	029ab823          	sd	s1,48(s5)
      swtch(&c->context, &p->context);
    8000201a:	06848593          	addi	a1,s1,104
    8000201e:	855a                	mv	a0,s6
    80002020:	00000097          	auipc	ra,0x0
    80002024:	7e8080e7          	jalr	2024(ra) # 80002808 <swtch>
        c->proc = 0;
    80002028:	020ab823          	sd	zero,48(s5)
    release(&p->lock);
    8000202c:	8552                	mv	a0,s4
    8000202e:	fffff097          	auipc	ra,0xfffff
    80002032:	c5c080e7          	jalr	-932(ra) # 80000c8a <release>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002036:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    8000203a:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000203e:	10079073          	csrw	sstatus,a5
    if(get_total_runnable_tickets() == 0){
    80002042:	00000097          	auipc	ra,0x0
    80002046:	e6c080e7          	jalr	-404(ra) # 80001eae <get_total_runnable_tickets>
    8000204a:	d129                	beqz	a0,80001f8c <scheduler+0x7c>
    total_ticket_count = get_total_runnable_tickets();
    8000204c:	00000097          	auipc	ra,0x0
    80002050:	e62080e7          	jalr	-414(ra) # 80001eae <get_total_runnable_tickets>
    80002054:	85aa                	mv	a1,a0
    int random_number = randomrange(0, total_ticket_count);
    80002056:	4501                	li	a0,0
    80002058:	00003097          	auipc	ra,0x3
    8000205c:	1e2080e7          	jalr	482(ra) # 8000523a <randomrange>
    80002060:	8c2a                	mv	s8,a0
    int current_ticket_count = 0;
    80002062:	4a01                	li	s4,0
    for(p = proc; p < &proc[NPROC]; p++) {
    80002064:	0000f497          	auipc	s1,0xf
    80002068:	f3c48493          	addi	s1,s1,-196 # 80010fa0 <proc>
    8000206c:	b795                	j	80001fd0 <scheduler+0xc0>

000000008000206e <sched>:
{
    8000206e:	7179                	addi	sp,sp,-48
    80002070:	f406                	sd	ra,40(sp)
    80002072:	f022                	sd	s0,32(sp)
    80002074:	ec26                	sd	s1,24(sp)
    80002076:	e84a                	sd	s2,16(sp)
    80002078:	e44e                	sd	s3,8(sp)
    8000207a:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000207c:	00000097          	auipc	ra,0x0
    80002080:	930080e7          	jalr	-1744(ra) # 800019ac <myproc>
    80002084:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80002086:	fffff097          	auipc	ra,0xfffff
    8000208a:	ad6080e7          	jalr	-1322(ra) # 80000b5c <holding>
    8000208e:	c93d                	beqz	a0,80002104 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002090:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80002092:	2781                	sext.w	a5,a5
    80002094:	079e                	slli	a5,a5,0x7
    80002096:	0000f717          	auipc	a4,0xf
    8000209a:	ada70713          	addi	a4,a4,-1318 # 80010b70 <pid_lock>
    8000209e:	97ba                	add	a5,a5,a4
    800020a0:	0a87a703          	lw	a4,168(a5)
    800020a4:	4785                	li	a5,1
    800020a6:	06f71763          	bne	a4,a5,80002114 <sched+0xa6>
  if(p->state == RUNNING)
    800020aa:	4c98                	lw	a4,24(s1)
    800020ac:	4791                	li	a5,4
    800020ae:	06f70b63          	beq	a4,a5,80002124 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800020b2:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800020b6:	8b89                	andi	a5,a5,2
  if(intr_get())
    800020b8:	efb5                	bnez	a5,80002134 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    800020ba:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    800020bc:	0000f917          	auipc	s2,0xf
    800020c0:	ab490913          	addi	s2,s2,-1356 # 80010b70 <pid_lock>
    800020c4:	2781                	sext.w	a5,a5
    800020c6:	079e                	slli	a5,a5,0x7
    800020c8:	97ca                	add	a5,a5,s2
    800020ca:	0ac7a983          	lw	s3,172(a5)
    800020ce:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    800020d0:	2781                	sext.w	a5,a5
    800020d2:	079e                	slli	a5,a5,0x7
    800020d4:	0000f597          	auipc	a1,0xf
    800020d8:	ad458593          	addi	a1,a1,-1324 # 80010ba8 <cpus+0x8>
    800020dc:	95be                	add	a1,a1,a5
    800020de:	06848513          	addi	a0,s1,104
    800020e2:	00000097          	auipc	ra,0x0
    800020e6:	726080e7          	jalr	1830(ra) # 80002808 <swtch>
    800020ea:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800020ec:	2781                	sext.w	a5,a5
    800020ee:	079e                	slli	a5,a5,0x7
    800020f0:	993e                	add	s2,s2,a5
    800020f2:	0b392623          	sw	s3,172(s2)
}
    800020f6:	70a2                	ld	ra,40(sp)
    800020f8:	7402                	ld	s0,32(sp)
    800020fa:	64e2                	ld	s1,24(sp)
    800020fc:	6942                	ld	s2,16(sp)
    800020fe:	69a2                	ld	s3,8(sp)
    80002100:	6145                	addi	sp,sp,48
    80002102:	8082                	ret
    panic("sched p->lock");
    80002104:	00006517          	auipc	a0,0x6
    80002108:	11450513          	addi	a0,a0,276 # 80008218 <digits+0x1d8>
    8000210c:	ffffe097          	auipc	ra,0xffffe
    80002110:	434080e7          	jalr	1076(ra) # 80000540 <panic>
    panic("sched locks");
    80002114:	00006517          	auipc	a0,0x6
    80002118:	11450513          	addi	a0,a0,276 # 80008228 <digits+0x1e8>
    8000211c:	ffffe097          	auipc	ra,0xffffe
    80002120:	424080e7          	jalr	1060(ra) # 80000540 <panic>
    panic("sched running");
    80002124:	00006517          	auipc	a0,0x6
    80002128:	11450513          	addi	a0,a0,276 # 80008238 <digits+0x1f8>
    8000212c:	ffffe097          	auipc	ra,0xffffe
    80002130:	414080e7          	jalr	1044(ra) # 80000540 <panic>
    panic("sched interruptible");
    80002134:	00006517          	auipc	a0,0x6
    80002138:	11450513          	addi	a0,a0,276 # 80008248 <digits+0x208>
    8000213c:	ffffe097          	auipc	ra,0xffffe
    80002140:	404080e7          	jalr	1028(ra) # 80000540 <panic>

0000000080002144 <yield>:
{
    80002144:	1101                	addi	sp,sp,-32
    80002146:	ec06                	sd	ra,24(sp)
    80002148:	e822                	sd	s0,16(sp)
    8000214a:	e426                	sd	s1,8(sp)
    8000214c:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000214e:	00000097          	auipc	ra,0x0
    80002152:	85e080e7          	jalr	-1954(ra) # 800019ac <myproc>
    80002156:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002158:	fffff097          	auipc	ra,0xfffff
    8000215c:	a7e080e7          	jalr	-1410(ra) # 80000bd6 <acquire>
  p->state = RUNNABLE;
    80002160:	478d                	li	a5,3
    80002162:	cc9c                	sw	a5,24(s1)
  sched();
    80002164:	00000097          	auipc	ra,0x0
    80002168:	f0a080e7          	jalr	-246(ra) # 8000206e <sched>
  release(&p->lock);
    8000216c:	8526                	mv	a0,s1
    8000216e:	fffff097          	auipc	ra,0xfffff
    80002172:	b1c080e7          	jalr	-1252(ra) # 80000c8a <release>
}
    80002176:	60e2                	ld	ra,24(sp)
    80002178:	6442                	ld	s0,16(sp)
    8000217a:	64a2                	ld	s1,8(sp)
    8000217c:	6105                	addi	sp,sp,32
    8000217e:	8082                	ret

0000000080002180 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    80002180:	7179                	addi	sp,sp,-48
    80002182:	f406                	sd	ra,40(sp)
    80002184:	f022                	sd	s0,32(sp)
    80002186:	ec26                	sd	s1,24(sp)
    80002188:	e84a                	sd	s2,16(sp)
    8000218a:	e44e                	sd	s3,8(sp)
    8000218c:	1800                	addi	s0,sp,48
    8000218e:	89aa                	mv	s3,a0
    80002190:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002192:	00000097          	auipc	ra,0x0
    80002196:	81a080e7          	jalr	-2022(ra) # 800019ac <myproc>
    8000219a:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    8000219c:	fffff097          	auipc	ra,0xfffff
    800021a0:	a3a080e7          	jalr	-1478(ra) # 80000bd6 <acquire>
  release(lk);
    800021a4:	854a                	mv	a0,s2
    800021a6:	fffff097          	auipc	ra,0xfffff
    800021aa:	ae4080e7          	jalr	-1308(ra) # 80000c8a <release>

  // Go to sleep.
  p->chan = chan;
    800021ae:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800021b2:	4789                	li	a5,2
    800021b4:	cc9c                	sw	a5,24(s1)

  sched();
    800021b6:	00000097          	auipc	ra,0x0
    800021ba:	eb8080e7          	jalr	-328(ra) # 8000206e <sched>

  // Tidy up.
  p->chan = 0;
    800021be:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800021c2:	8526                	mv	a0,s1
    800021c4:	fffff097          	auipc	ra,0xfffff
    800021c8:	ac6080e7          	jalr	-1338(ra) # 80000c8a <release>
  acquire(lk);
    800021cc:	854a                	mv	a0,s2
    800021ce:	fffff097          	auipc	ra,0xfffff
    800021d2:	a08080e7          	jalr	-1528(ra) # 80000bd6 <acquire>
}
    800021d6:	70a2                	ld	ra,40(sp)
    800021d8:	7402                	ld	s0,32(sp)
    800021da:	64e2                	ld	s1,24(sp)
    800021dc:	6942                	ld	s2,16(sp)
    800021de:	69a2                	ld	s3,8(sp)
    800021e0:	6145                	addi	sp,sp,48
    800021e2:	8082                	ret

00000000800021e4 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    800021e4:	7139                	addi	sp,sp,-64
    800021e6:	fc06                	sd	ra,56(sp)
    800021e8:	f822                	sd	s0,48(sp)
    800021ea:	f426                	sd	s1,40(sp)
    800021ec:	f04a                	sd	s2,32(sp)
    800021ee:	ec4e                	sd	s3,24(sp)
    800021f0:	e852                	sd	s4,16(sp)
    800021f2:	e456                	sd	s5,8(sp)
    800021f4:	0080                	addi	s0,sp,64
    800021f6:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    800021f8:	0000f497          	auipc	s1,0xf
    800021fc:	da848493          	addi	s1,s1,-600 # 80010fa0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002200:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002202:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002204:	00015917          	auipc	s2,0x15
    80002208:	99c90913          	addi	s2,s2,-1636 # 80016ba0 <tickslock>
    8000220c:	a811                	j	80002220 <wakeup+0x3c>
      }
      release(&p->lock);
    8000220e:	8526                	mv	a0,s1
    80002210:	fffff097          	auipc	ra,0xfffff
    80002214:	a7a080e7          	jalr	-1414(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80002218:	17048493          	addi	s1,s1,368
    8000221c:	03248663          	beq	s1,s2,80002248 <wakeup+0x64>
    if(p != myproc()){
    80002220:	fffff097          	auipc	ra,0xfffff
    80002224:	78c080e7          	jalr	1932(ra) # 800019ac <myproc>
    80002228:	fea488e3          	beq	s1,a0,80002218 <wakeup+0x34>
      acquire(&p->lock);
    8000222c:	8526                	mv	a0,s1
    8000222e:	fffff097          	auipc	ra,0xfffff
    80002232:	9a8080e7          	jalr	-1624(ra) # 80000bd6 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002236:	4c9c                	lw	a5,24(s1)
    80002238:	fd379be3          	bne	a5,s3,8000220e <wakeup+0x2a>
    8000223c:	709c                	ld	a5,32(s1)
    8000223e:	fd4798e3          	bne	a5,s4,8000220e <wakeup+0x2a>
        p->state = RUNNABLE;
    80002242:	0154ac23          	sw	s5,24(s1)
    80002246:	b7e1                	j	8000220e <wakeup+0x2a>
    }
  }
}
    80002248:	70e2                	ld	ra,56(sp)
    8000224a:	7442                	ld	s0,48(sp)
    8000224c:	74a2                	ld	s1,40(sp)
    8000224e:	7902                	ld	s2,32(sp)
    80002250:	69e2                	ld	s3,24(sp)
    80002252:	6a42                	ld	s4,16(sp)
    80002254:	6aa2                	ld	s5,8(sp)
    80002256:	6121                	addi	sp,sp,64
    80002258:	8082                	ret

000000008000225a <reparent>:
{
    8000225a:	7179                	addi	sp,sp,-48
    8000225c:	f406                	sd	ra,40(sp)
    8000225e:	f022                	sd	s0,32(sp)
    80002260:	ec26                	sd	s1,24(sp)
    80002262:	e84a                	sd	s2,16(sp)
    80002264:	e44e                	sd	s3,8(sp)
    80002266:	e052                	sd	s4,0(sp)
    80002268:	1800                	addi	s0,sp,48
    8000226a:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000226c:	0000f497          	auipc	s1,0xf
    80002270:	d3448493          	addi	s1,s1,-716 # 80010fa0 <proc>
      pp->parent = initproc;
    80002274:	00006a17          	auipc	s4,0x6
    80002278:	684a0a13          	addi	s4,s4,1668 # 800088f8 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000227c:	00015997          	auipc	s3,0x15
    80002280:	92498993          	addi	s3,s3,-1756 # 80016ba0 <tickslock>
    80002284:	a029                	j	8000228e <reparent+0x34>
    80002286:	17048493          	addi	s1,s1,368
    8000228a:	01348d63          	beq	s1,s3,800022a4 <reparent+0x4a>
    if(pp->parent == p){
    8000228e:	60bc                	ld	a5,64(s1)
    80002290:	ff279be3          	bne	a5,s2,80002286 <reparent+0x2c>
      pp->parent = initproc;
    80002294:	000a3503          	ld	a0,0(s4)
    80002298:	e0a8                	sd	a0,64(s1)
      wakeup(initproc);
    8000229a:	00000097          	auipc	ra,0x0
    8000229e:	f4a080e7          	jalr	-182(ra) # 800021e4 <wakeup>
    800022a2:	b7d5                	j	80002286 <reparent+0x2c>
}
    800022a4:	70a2                	ld	ra,40(sp)
    800022a6:	7402                	ld	s0,32(sp)
    800022a8:	64e2                	ld	s1,24(sp)
    800022aa:	6942                	ld	s2,16(sp)
    800022ac:	69a2                	ld	s3,8(sp)
    800022ae:	6a02                	ld	s4,0(sp)
    800022b0:	6145                	addi	sp,sp,48
    800022b2:	8082                	ret

00000000800022b4 <exit>:
{
    800022b4:	7179                	addi	sp,sp,-48
    800022b6:	f406                	sd	ra,40(sp)
    800022b8:	f022                	sd	s0,32(sp)
    800022ba:	ec26                	sd	s1,24(sp)
    800022bc:	e84a                	sd	s2,16(sp)
    800022be:	e44e                	sd	s3,8(sp)
    800022c0:	e052                	sd	s4,0(sp)
    800022c2:	1800                	addi	s0,sp,48
    800022c4:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800022c6:	fffff097          	auipc	ra,0xfffff
    800022ca:	6e6080e7          	jalr	1766(ra) # 800019ac <myproc>
    800022ce:	89aa                	mv	s3,a0
  if(p == initproc)
    800022d0:	00006797          	auipc	a5,0x6
    800022d4:	6287b783          	ld	a5,1576(a5) # 800088f8 <initproc>
    800022d8:	0d850493          	addi	s1,a0,216
    800022dc:	15850913          	addi	s2,a0,344
    800022e0:	02a79363          	bne	a5,a0,80002306 <exit+0x52>
    panic("init exiting");
    800022e4:	00006517          	auipc	a0,0x6
    800022e8:	f7c50513          	addi	a0,a0,-132 # 80008260 <digits+0x220>
    800022ec:	ffffe097          	auipc	ra,0xffffe
    800022f0:	254080e7          	jalr	596(ra) # 80000540 <panic>
      fileclose(f);
    800022f4:	00002097          	auipc	ra,0x2
    800022f8:	470080e7          	jalr	1136(ra) # 80004764 <fileclose>
      p->ofile[fd] = 0;
    800022fc:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002300:	04a1                	addi	s1,s1,8
    80002302:	01248563          	beq	s1,s2,8000230c <exit+0x58>
    if(p->ofile[fd]){
    80002306:	6088                	ld	a0,0(s1)
    80002308:	f575                	bnez	a0,800022f4 <exit+0x40>
    8000230a:	bfdd                	j	80002300 <exit+0x4c>
  begin_op();
    8000230c:	00002097          	auipc	ra,0x2
    80002310:	f90080e7          	jalr	-112(ra) # 8000429c <begin_op>
  iput(p->cwd);
    80002314:	1589b503          	ld	a0,344(s3)
    80002318:	00001097          	auipc	ra,0x1
    8000231c:	772080e7          	jalr	1906(ra) # 80003a8a <iput>
  end_op();
    80002320:	00002097          	auipc	ra,0x2
    80002324:	ffa080e7          	jalr	-6(ra) # 8000431a <end_op>
  p->cwd = 0;
    80002328:	1409bc23          	sd	zero,344(s3)
  acquire(&wait_lock);
    8000232c:	0000f497          	auipc	s1,0xf
    80002330:	85c48493          	addi	s1,s1,-1956 # 80010b88 <wait_lock>
    80002334:	8526                	mv	a0,s1
    80002336:	fffff097          	auipc	ra,0xfffff
    8000233a:	8a0080e7          	jalr	-1888(ra) # 80000bd6 <acquire>
  reparent(p);
    8000233e:	854e                	mv	a0,s3
    80002340:	00000097          	auipc	ra,0x0
    80002344:	f1a080e7          	jalr	-230(ra) # 8000225a <reparent>
  wakeup(p->parent);
    80002348:	0409b503          	ld	a0,64(s3)
    8000234c:	00000097          	auipc	ra,0x0
    80002350:	e98080e7          	jalr	-360(ra) # 800021e4 <wakeup>
  acquire(&p->lock);
    80002354:	854e                	mv	a0,s3
    80002356:	fffff097          	auipc	ra,0xfffff
    8000235a:	880080e7          	jalr	-1920(ra) # 80000bd6 <acquire>
  p->xstate = status;
    8000235e:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002362:	4795                	li	a5,5
    80002364:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    80002368:	8526                	mv	a0,s1
    8000236a:	fffff097          	auipc	ra,0xfffff
    8000236e:	920080e7          	jalr	-1760(ra) # 80000c8a <release>
  sched();
    80002372:	00000097          	auipc	ra,0x0
    80002376:	cfc080e7          	jalr	-772(ra) # 8000206e <sched>
  panic("zombie exit");
    8000237a:	00006517          	auipc	a0,0x6
    8000237e:	ef650513          	addi	a0,a0,-266 # 80008270 <digits+0x230>
    80002382:	ffffe097          	auipc	ra,0xffffe
    80002386:	1be080e7          	jalr	446(ra) # 80000540 <panic>

000000008000238a <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    8000238a:	7179                	addi	sp,sp,-48
    8000238c:	f406                	sd	ra,40(sp)
    8000238e:	f022                	sd	s0,32(sp)
    80002390:	ec26                	sd	s1,24(sp)
    80002392:	e84a                	sd	s2,16(sp)
    80002394:	e44e                	sd	s3,8(sp)
    80002396:	1800                	addi	s0,sp,48
    80002398:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    8000239a:	0000f497          	auipc	s1,0xf
    8000239e:	c0648493          	addi	s1,s1,-1018 # 80010fa0 <proc>
    800023a2:	00014997          	auipc	s3,0x14
    800023a6:	7fe98993          	addi	s3,s3,2046 # 80016ba0 <tickslock>
    acquire(&p->lock);
    800023aa:	8526                	mv	a0,s1
    800023ac:	fffff097          	auipc	ra,0xfffff
    800023b0:	82a080e7          	jalr	-2006(ra) # 80000bd6 <acquire>
    if(p->pid == pid){
    800023b4:	589c                	lw	a5,48(s1)
    800023b6:	01278d63          	beq	a5,s2,800023d0 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800023ba:	8526                	mv	a0,s1
    800023bc:	fffff097          	auipc	ra,0xfffff
    800023c0:	8ce080e7          	jalr	-1842(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800023c4:	17048493          	addi	s1,s1,368
    800023c8:	ff3491e3          	bne	s1,s3,800023aa <kill+0x20>
  }
  return -1;
    800023cc:	557d                	li	a0,-1
    800023ce:	a829                	j	800023e8 <kill+0x5e>
      p->killed = 1;
    800023d0:	4785                	li	a5,1
    800023d2:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800023d4:	4c98                	lw	a4,24(s1)
    800023d6:	4789                	li	a5,2
    800023d8:	00f70f63          	beq	a4,a5,800023f6 <kill+0x6c>
      release(&p->lock);
    800023dc:	8526                	mv	a0,s1
    800023de:	fffff097          	auipc	ra,0xfffff
    800023e2:	8ac080e7          	jalr	-1876(ra) # 80000c8a <release>
      return 0;
    800023e6:	4501                	li	a0,0
}
    800023e8:	70a2                	ld	ra,40(sp)
    800023ea:	7402                	ld	s0,32(sp)
    800023ec:	64e2                	ld	s1,24(sp)
    800023ee:	6942                	ld	s2,16(sp)
    800023f0:	69a2                	ld	s3,8(sp)
    800023f2:	6145                	addi	sp,sp,48
    800023f4:	8082                	ret
        p->state = RUNNABLE;
    800023f6:	478d                	li	a5,3
    800023f8:	cc9c                	sw	a5,24(s1)
    800023fa:	b7cd                	j	800023dc <kill+0x52>

00000000800023fc <setkilled>:

void
setkilled(struct proc *p)
{
    800023fc:	1101                	addi	sp,sp,-32
    800023fe:	ec06                	sd	ra,24(sp)
    80002400:	e822                	sd	s0,16(sp)
    80002402:	e426                	sd	s1,8(sp)
    80002404:	1000                	addi	s0,sp,32
    80002406:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002408:	ffffe097          	auipc	ra,0xffffe
    8000240c:	7ce080e7          	jalr	1998(ra) # 80000bd6 <acquire>
  p->killed = 1;
    80002410:	4785                	li	a5,1
    80002412:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002414:	8526                	mv	a0,s1
    80002416:	fffff097          	auipc	ra,0xfffff
    8000241a:	874080e7          	jalr	-1932(ra) # 80000c8a <release>
}
    8000241e:	60e2                	ld	ra,24(sp)
    80002420:	6442                	ld	s0,16(sp)
    80002422:	64a2                	ld	s1,8(sp)
    80002424:	6105                	addi	sp,sp,32
    80002426:	8082                	ret

0000000080002428 <killed>:

int
killed(struct proc *p)
{
    80002428:	1101                	addi	sp,sp,-32
    8000242a:	ec06                	sd	ra,24(sp)
    8000242c:	e822                	sd	s0,16(sp)
    8000242e:	e426                	sd	s1,8(sp)
    80002430:	e04a                	sd	s2,0(sp)
    80002432:	1000                	addi	s0,sp,32
    80002434:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    80002436:	ffffe097          	auipc	ra,0xffffe
    8000243a:	7a0080e7          	jalr	1952(ra) # 80000bd6 <acquire>
  k = p->killed;
    8000243e:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002442:	8526                	mv	a0,s1
    80002444:	fffff097          	auipc	ra,0xfffff
    80002448:	846080e7          	jalr	-1978(ra) # 80000c8a <release>
  return k;
}
    8000244c:	854a                	mv	a0,s2
    8000244e:	60e2                	ld	ra,24(sp)
    80002450:	6442                	ld	s0,16(sp)
    80002452:	64a2                	ld	s1,8(sp)
    80002454:	6902                	ld	s2,0(sp)
    80002456:	6105                	addi	sp,sp,32
    80002458:	8082                	ret

000000008000245a <wait>:
{
    8000245a:	715d                	addi	sp,sp,-80
    8000245c:	e486                	sd	ra,72(sp)
    8000245e:	e0a2                	sd	s0,64(sp)
    80002460:	fc26                	sd	s1,56(sp)
    80002462:	f84a                	sd	s2,48(sp)
    80002464:	f44e                	sd	s3,40(sp)
    80002466:	f052                	sd	s4,32(sp)
    80002468:	ec56                	sd	s5,24(sp)
    8000246a:	e85a                	sd	s6,16(sp)
    8000246c:	e45e                	sd	s7,8(sp)
    8000246e:	e062                	sd	s8,0(sp)
    80002470:	0880                	addi	s0,sp,80
    80002472:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002474:	fffff097          	auipc	ra,0xfffff
    80002478:	538080e7          	jalr	1336(ra) # 800019ac <myproc>
    8000247c:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000247e:	0000e517          	auipc	a0,0xe
    80002482:	70a50513          	addi	a0,a0,1802 # 80010b88 <wait_lock>
    80002486:	ffffe097          	auipc	ra,0xffffe
    8000248a:	750080e7          	jalr	1872(ra) # 80000bd6 <acquire>
    havekids = 0;
    8000248e:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    80002490:	4a15                	li	s4,5
        havekids = 1;
    80002492:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002494:	00014997          	auipc	s3,0x14
    80002498:	70c98993          	addi	s3,s3,1804 # 80016ba0 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000249c:	0000ec17          	auipc	s8,0xe
    800024a0:	6ecc0c13          	addi	s8,s8,1772 # 80010b88 <wait_lock>
    havekids = 0;
    800024a4:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800024a6:	0000f497          	auipc	s1,0xf
    800024aa:	afa48493          	addi	s1,s1,-1286 # 80010fa0 <proc>
    800024ae:	a0bd                	j	8000251c <wait+0xc2>
          pid = pp->pid;
    800024b0:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800024b4:	000b0e63          	beqz	s6,800024d0 <wait+0x76>
    800024b8:	4691                	li	a3,4
    800024ba:	02c48613          	addi	a2,s1,44
    800024be:	85da                	mv	a1,s6
    800024c0:	05893503          	ld	a0,88(s2)
    800024c4:	fffff097          	auipc	ra,0xfffff
    800024c8:	1a8080e7          	jalr	424(ra) # 8000166c <copyout>
    800024cc:	02054563          	bltz	a0,800024f6 <wait+0x9c>
          freeproc(pp);
    800024d0:	8526                	mv	a0,s1
    800024d2:	fffff097          	auipc	ra,0xfffff
    800024d6:	68c080e7          	jalr	1676(ra) # 80001b5e <freeproc>
          release(&pp->lock);
    800024da:	8526                	mv	a0,s1
    800024dc:	ffffe097          	auipc	ra,0xffffe
    800024e0:	7ae080e7          	jalr	1966(ra) # 80000c8a <release>
          release(&wait_lock);
    800024e4:	0000e517          	auipc	a0,0xe
    800024e8:	6a450513          	addi	a0,a0,1700 # 80010b88 <wait_lock>
    800024ec:	ffffe097          	auipc	ra,0xffffe
    800024f0:	79e080e7          	jalr	1950(ra) # 80000c8a <release>
          return pid;
    800024f4:	a0b5                	j	80002560 <wait+0x106>
            release(&pp->lock);
    800024f6:	8526                	mv	a0,s1
    800024f8:	ffffe097          	auipc	ra,0xffffe
    800024fc:	792080e7          	jalr	1938(ra) # 80000c8a <release>
            release(&wait_lock);
    80002500:	0000e517          	auipc	a0,0xe
    80002504:	68850513          	addi	a0,a0,1672 # 80010b88 <wait_lock>
    80002508:	ffffe097          	auipc	ra,0xffffe
    8000250c:	782080e7          	jalr	1922(ra) # 80000c8a <release>
            return -1;
    80002510:	59fd                	li	s3,-1
    80002512:	a0b9                	j	80002560 <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002514:	17048493          	addi	s1,s1,368
    80002518:	03348463          	beq	s1,s3,80002540 <wait+0xe6>
      if(pp->parent == p){
    8000251c:	60bc                	ld	a5,64(s1)
    8000251e:	ff279be3          	bne	a5,s2,80002514 <wait+0xba>
        acquire(&pp->lock);
    80002522:	8526                	mv	a0,s1
    80002524:	ffffe097          	auipc	ra,0xffffe
    80002528:	6b2080e7          	jalr	1714(ra) # 80000bd6 <acquire>
        if(pp->state == ZOMBIE){
    8000252c:	4c9c                	lw	a5,24(s1)
    8000252e:	f94781e3          	beq	a5,s4,800024b0 <wait+0x56>
        release(&pp->lock);
    80002532:	8526                	mv	a0,s1
    80002534:	ffffe097          	auipc	ra,0xffffe
    80002538:	756080e7          	jalr	1878(ra) # 80000c8a <release>
        havekids = 1;
    8000253c:	8756                	mv	a4,s5
    8000253e:	bfd9                	j	80002514 <wait+0xba>
    if(!havekids || killed(p)){
    80002540:	c719                	beqz	a4,8000254e <wait+0xf4>
    80002542:	854a                	mv	a0,s2
    80002544:	00000097          	auipc	ra,0x0
    80002548:	ee4080e7          	jalr	-284(ra) # 80002428 <killed>
    8000254c:	c51d                	beqz	a0,8000257a <wait+0x120>
      release(&wait_lock);
    8000254e:	0000e517          	auipc	a0,0xe
    80002552:	63a50513          	addi	a0,a0,1594 # 80010b88 <wait_lock>
    80002556:	ffffe097          	auipc	ra,0xffffe
    8000255a:	734080e7          	jalr	1844(ra) # 80000c8a <release>
      return -1;
    8000255e:	59fd                	li	s3,-1
}
    80002560:	854e                	mv	a0,s3
    80002562:	60a6                	ld	ra,72(sp)
    80002564:	6406                	ld	s0,64(sp)
    80002566:	74e2                	ld	s1,56(sp)
    80002568:	7942                	ld	s2,48(sp)
    8000256a:	79a2                	ld	s3,40(sp)
    8000256c:	7a02                	ld	s4,32(sp)
    8000256e:	6ae2                	ld	s5,24(sp)
    80002570:	6b42                	ld	s6,16(sp)
    80002572:	6ba2                	ld	s7,8(sp)
    80002574:	6c02                	ld	s8,0(sp)
    80002576:	6161                	addi	sp,sp,80
    80002578:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000257a:	85e2                	mv	a1,s8
    8000257c:	854a                	mv	a0,s2
    8000257e:	00000097          	auipc	ra,0x0
    80002582:	c02080e7          	jalr	-1022(ra) # 80002180 <sleep>
    havekids = 0;
    80002586:	bf39                	j	800024a4 <wait+0x4a>

0000000080002588 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002588:	7179                	addi	sp,sp,-48
    8000258a:	f406                	sd	ra,40(sp)
    8000258c:	f022                	sd	s0,32(sp)
    8000258e:	ec26                	sd	s1,24(sp)
    80002590:	e84a                	sd	s2,16(sp)
    80002592:	e44e                	sd	s3,8(sp)
    80002594:	e052                	sd	s4,0(sp)
    80002596:	1800                	addi	s0,sp,48
    80002598:	84aa                	mv	s1,a0
    8000259a:	892e                	mv	s2,a1
    8000259c:	89b2                	mv	s3,a2
    8000259e:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800025a0:	fffff097          	auipc	ra,0xfffff
    800025a4:	40c080e7          	jalr	1036(ra) # 800019ac <myproc>
  if(user_dst){
    800025a8:	c08d                	beqz	s1,800025ca <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800025aa:	86d2                	mv	a3,s4
    800025ac:	864e                	mv	a2,s3
    800025ae:	85ca                	mv	a1,s2
    800025b0:	6d28                	ld	a0,88(a0)
    800025b2:	fffff097          	auipc	ra,0xfffff
    800025b6:	0ba080e7          	jalr	186(ra) # 8000166c <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800025ba:	70a2                	ld	ra,40(sp)
    800025bc:	7402                	ld	s0,32(sp)
    800025be:	64e2                	ld	s1,24(sp)
    800025c0:	6942                	ld	s2,16(sp)
    800025c2:	69a2                	ld	s3,8(sp)
    800025c4:	6a02                	ld	s4,0(sp)
    800025c6:	6145                	addi	sp,sp,48
    800025c8:	8082                	ret
    memmove((char *)dst, src, len);
    800025ca:	000a061b          	sext.w	a2,s4
    800025ce:	85ce                	mv	a1,s3
    800025d0:	854a                	mv	a0,s2
    800025d2:	ffffe097          	auipc	ra,0xffffe
    800025d6:	75c080e7          	jalr	1884(ra) # 80000d2e <memmove>
    return 0;
    800025da:	8526                	mv	a0,s1
    800025dc:	bff9                	j	800025ba <either_copyout+0x32>

00000000800025de <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800025de:	7179                	addi	sp,sp,-48
    800025e0:	f406                	sd	ra,40(sp)
    800025e2:	f022                	sd	s0,32(sp)
    800025e4:	ec26                	sd	s1,24(sp)
    800025e6:	e84a                	sd	s2,16(sp)
    800025e8:	e44e                	sd	s3,8(sp)
    800025ea:	e052                	sd	s4,0(sp)
    800025ec:	1800                	addi	s0,sp,48
    800025ee:	892a                	mv	s2,a0
    800025f0:	84ae                	mv	s1,a1
    800025f2:	89b2                	mv	s3,a2
    800025f4:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800025f6:	fffff097          	auipc	ra,0xfffff
    800025fa:	3b6080e7          	jalr	950(ra) # 800019ac <myproc>
  if(user_src){
    800025fe:	c08d                	beqz	s1,80002620 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002600:	86d2                	mv	a3,s4
    80002602:	864e                	mv	a2,s3
    80002604:	85ca                	mv	a1,s2
    80002606:	6d28                	ld	a0,88(a0)
    80002608:	fffff097          	auipc	ra,0xfffff
    8000260c:	0f0080e7          	jalr	240(ra) # 800016f8 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002610:	70a2                	ld	ra,40(sp)
    80002612:	7402                	ld	s0,32(sp)
    80002614:	64e2                	ld	s1,24(sp)
    80002616:	6942                	ld	s2,16(sp)
    80002618:	69a2                	ld	s3,8(sp)
    8000261a:	6a02                	ld	s4,0(sp)
    8000261c:	6145                	addi	sp,sp,48
    8000261e:	8082                	ret
    memmove(dst, (char*)src, len);
    80002620:	000a061b          	sext.w	a2,s4
    80002624:	85ce                	mv	a1,s3
    80002626:	854a                	mv	a0,s2
    80002628:	ffffe097          	auipc	ra,0xffffe
    8000262c:	706080e7          	jalr	1798(ra) # 80000d2e <memmove>
    return 0;
    80002630:	8526                	mv	a0,s1
    80002632:	bff9                	j	80002610 <either_copyin+0x32>

0000000080002634 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002634:	715d                	addi	sp,sp,-80
    80002636:	e486                	sd	ra,72(sp)
    80002638:	e0a2                	sd	s0,64(sp)
    8000263a:	fc26                	sd	s1,56(sp)
    8000263c:	f84a                	sd	s2,48(sp)
    8000263e:	f44e                	sd	s3,40(sp)
    80002640:	f052                	sd	s4,32(sp)
    80002642:	ec56                	sd	s5,24(sp)
    80002644:	e85a                	sd	s6,16(sp)
    80002646:	e45e                	sd	s7,8(sp)
    80002648:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000264a:	00006517          	auipc	a0,0x6
    8000264e:	a7e50513          	addi	a0,a0,-1410 # 800080c8 <digits+0x88>
    80002652:	ffffe097          	auipc	ra,0xffffe
    80002656:	f38080e7          	jalr	-200(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000265a:	0000f497          	auipc	s1,0xf
    8000265e:	aa648493          	addi	s1,s1,-1370 # 80011100 <proc+0x160>
    80002662:	00014917          	auipc	s2,0x14
    80002666:	69e90913          	addi	s2,s2,1694 # 80016d00 <bcache+0x148>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000266a:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000266c:	00006997          	auipc	s3,0x6
    80002670:	c1498993          	addi	s3,s3,-1004 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    80002674:	00006a97          	auipc	s5,0x6
    80002678:	c14a8a93          	addi	s5,s5,-1004 # 80008288 <digits+0x248>
    printf("\n");
    8000267c:	00006a17          	auipc	s4,0x6
    80002680:	a4ca0a13          	addi	s4,s4,-1460 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002684:	00006b97          	auipc	s7,0x6
    80002688:	c44b8b93          	addi	s7,s7,-956 # 800082c8 <states.0>
    8000268c:	a00d                	j	800026ae <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000268e:	ed06a583          	lw	a1,-304(a3)
    80002692:	8556                	mv	a0,s5
    80002694:	ffffe097          	auipc	ra,0xffffe
    80002698:	ef6080e7          	jalr	-266(ra) # 8000058a <printf>
    printf("\n");
    8000269c:	8552                	mv	a0,s4
    8000269e:	ffffe097          	auipc	ra,0xffffe
    800026a2:	eec080e7          	jalr	-276(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800026a6:	17048493          	addi	s1,s1,368
    800026aa:	03248263          	beq	s1,s2,800026ce <procdump+0x9a>
    if(p->state == UNUSED)
    800026ae:	86a6                	mv	a3,s1
    800026b0:	eb84a783          	lw	a5,-328(s1)
    800026b4:	dbed                	beqz	a5,800026a6 <procdump+0x72>
      state = "???";
    800026b6:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800026b8:	fcfb6be3          	bltu	s6,a5,8000268e <procdump+0x5a>
    800026bc:	02079713          	slli	a4,a5,0x20
    800026c0:	01d75793          	srli	a5,a4,0x1d
    800026c4:	97de                	add	a5,a5,s7
    800026c6:	6390                	ld	a2,0(a5)
    800026c8:	f279                	bnez	a2,8000268e <procdump+0x5a>
      state = "???";
    800026ca:	864e                	mv	a2,s3
    800026cc:	b7c9                	j	8000268e <procdump+0x5a>
  }
}
    800026ce:	60a6                	ld	ra,72(sp)
    800026d0:	6406                	ld	s0,64(sp)
    800026d2:	74e2                	ld	s1,56(sp)
    800026d4:	7942                	ld	s2,48(sp)
    800026d6:	79a2                	ld	s3,40(sp)
    800026d8:	7a02                	ld	s4,32(sp)
    800026da:	6ae2                	ld	s5,24(sp)
    800026dc:	6b42                	ld	s6,16(sp)
    800026de:	6ba2                	ld	s7,8(sp)
    800026e0:	6161                	addi	sp,sp,80
    800026e2:	8082                	ret

00000000800026e4 <settickets>:

int 
settickets(int tickets)
{
  if(tickets < 1)
    800026e4:	06a05863          	blez	a0,80002754 <settickets+0x70>
{
    800026e8:	1101                	addi	sp,sp,-32
    800026ea:	ec06                	sd	ra,24(sp)
    800026ec:	e822                	sd	s0,16(sp)
    800026ee:	e426                	sd	s1,8(sp)
    800026f0:	e04a                	sd	s2,0(sp)
    800026f2:	1000                	addi	s0,sp,32
    800026f4:	892a                	mv	s2,a0
    return -1;
  struct proc *p = myproc();
    800026f6:	fffff097          	auipc	ra,0xfffff
    800026fa:	2b6080e7          	jalr	694(ra) # 800019ac <myproc>
  int pid = p->pid;
    800026fe:	5904                	lw	s1,48(a0)
  acquire(&p->lock);
    80002700:	ffffe097          	auipc	ra,0xffffe
    80002704:	4d6080e7          	jalr	1238(ra) # 80000bd6 <acquire>

  // find out the particular process and set the tickets
  for(p = proc; p < &proc[NPROC]; p++){
    80002708:	0000f517          	auipc	a0,0xf
    8000270c:	89850513          	addi	a0,a0,-1896 # 80010fa0 <proc>
    80002710:	00014717          	auipc	a4,0x14
    80002714:	49070713          	addi	a4,a4,1168 # 80016ba0 <tickslock>
    if(p->pid == pid){
    80002718:	591c                	lw	a5,48(a0)
    8000271a:	02978063          	beq	a5,s1,8000273a <settickets+0x56>
  for(p = proc; p < &proc[NPROC]; p++){
    8000271e:	17050513          	addi	a0,a0,368
    80002722:	fee51be3          	bne	a0,a4,80002718 <settickets+0x34>
      p->initial_tickets = tickets;
      release(&p->lock);
      return 0;
    }
  }
  release(&p->lock);
    80002726:	00014517          	auipc	a0,0x14
    8000272a:	47a50513          	addi	a0,a0,1146 # 80016ba0 <tickslock>
    8000272e:	ffffe097          	auipc	ra,0xffffe
    80002732:	55c080e7          	jalr	1372(ra) # 80000c8a <release>
  return 0;
    80002736:	4501                	li	a0,0
    80002738:	a801                	j	80002748 <settickets+0x64>
      p->initial_tickets = tickets;
    8000273a:	03252a23          	sw	s2,52(a0)
      release(&p->lock);
    8000273e:	ffffe097          	auipc	ra,0xffffe
    80002742:	54c080e7          	jalr	1356(ra) # 80000c8a <release>
      return 0;
    80002746:	4501                	li	a0,0
}
    80002748:	60e2                	ld	ra,24(sp)
    8000274a:	6442                	ld	s0,16(sp)
    8000274c:	64a2                	ld	s1,8(sp)
    8000274e:	6902                	ld	s2,0(sp)
    80002750:	6105                	addi	sp,sp,32
    80002752:	8082                	ret
    return -1;
    80002754:	557d                	li	a0,-1
}
    80002756:	8082                	ret

0000000080002758 <getpinfo>:

int 
getpinfo(uint64 pst)
{
    80002758:	ad010113          	addi	sp,sp,-1328
    8000275c:	52113423          	sd	ra,1320(sp)
    80002760:	52813023          	sd	s0,1312(sp)
    80002764:	50913c23          	sd	s1,1304(sp)
    80002768:	51213823          	sd	s2,1296(sp)
    8000276c:	51313423          	sd	s3,1288(sp)
    80002770:	51413023          	sd	s4,1280(sp)
    80002774:	53010413          	addi	s0,sp,1328
    80002778:	8a2a                	mv	s4,a0
  struct proc *p;
  struct pstat temp;
  int i = 0;
  for(p = proc; p < &proc[NPROC]; p++){
    8000277a:	ad040913          	addi	s2,s0,-1328
    8000277e:	0000f497          	auipc	s1,0xf
    80002782:	82248493          	addi	s1,s1,-2014 # 80010fa0 <proc>
    80002786:	00014997          	auipc	s3,0x14
    8000278a:	41a98993          	addi	s3,s3,1050 # 80016ba0 <tickslock>
    acquire(&p->lock);
    8000278e:	8526                	mv	a0,s1
    80002790:	ffffe097          	auipc	ra,0xffffe
    80002794:	446080e7          	jalr	1094(ra) # 80000bd6 <acquire>
    temp.inuse[i] = p->state == UNUSED ? 0 : 1;
    80002798:	4c9c                	lw	a5,24(s1)
    8000279a:	00f037b3          	snez	a5,a5
    8000279e:	10f92023          	sw	a5,256(s2)
    temp.pid[i] = p->pid;
    800027a2:	589c                	lw	a5,48(s1)
    800027a4:	00f92023          	sw	a5,0(s2)
    temp.tickets_original[i] = p->initial_tickets;
    800027a8:	58dc                	lw	a5,52(s1)
    800027aa:	20f92023          	sw	a5,512(s2)
    temp.tickets_current[i] = p->current_tickets;
    800027ae:	5c9c                	lw	a5,56(s1)
    800027b0:	30f92023          	sw	a5,768(s2)
    temp.time_slices[i] = p->ticks_used;
    800027b4:	5cdc                	lw	a5,60(s1)
    800027b6:	40f92023          	sw	a5,1024(s2)
    release(&p->lock);
    800027ba:	8526                	mv	a0,s1
    800027bc:	ffffe097          	auipc	ra,0xffffe
    800027c0:	4ce080e7          	jalr	1230(ra) # 80000c8a <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800027c4:	17048493          	addi	s1,s1,368
    800027c8:	0911                	addi	s2,s2,4
    800027ca:	fd3492e3          	bne	s1,s3,8000278e <getpinfo+0x36>
    i++;
  }
  return copyout(myproc()->pagetable, pst, (char*)&temp, sizeof(temp));
    800027ce:	fffff097          	auipc	ra,0xfffff
    800027d2:	1de080e7          	jalr	478(ra) # 800019ac <myproc>
    800027d6:	50000693          	li	a3,1280
    800027da:	ad040613          	addi	a2,s0,-1328
    800027de:	85d2                	mv	a1,s4
    800027e0:	6d28                	ld	a0,88(a0)
    800027e2:	fffff097          	auipc	ra,0xfffff
    800027e6:	e8a080e7          	jalr	-374(ra) # 8000166c <copyout>
    800027ea:	52813083          	ld	ra,1320(sp)
    800027ee:	52013403          	ld	s0,1312(sp)
    800027f2:	51813483          	ld	s1,1304(sp)
    800027f6:	51013903          	ld	s2,1296(sp)
    800027fa:	50813983          	ld	s3,1288(sp)
    800027fe:	50013a03          	ld	s4,1280(sp)
    80002802:	53010113          	addi	sp,sp,1328
    80002806:	8082                	ret

0000000080002808 <swtch>:
    80002808:	00153023          	sd	ra,0(a0)
    8000280c:	00253423          	sd	sp,8(a0)
    80002810:	e900                	sd	s0,16(a0)
    80002812:	ed04                	sd	s1,24(a0)
    80002814:	03253023          	sd	s2,32(a0)
    80002818:	03353423          	sd	s3,40(a0)
    8000281c:	03453823          	sd	s4,48(a0)
    80002820:	03553c23          	sd	s5,56(a0)
    80002824:	05653023          	sd	s6,64(a0)
    80002828:	05753423          	sd	s7,72(a0)
    8000282c:	05853823          	sd	s8,80(a0)
    80002830:	05953c23          	sd	s9,88(a0)
    80002834:	07a53023          	sd	s10,96(a0)
    80002838:	07b53423          	sd	s11,104(a0)
    8000283c:	0005b083          	ld	ra,0(a1)
    80002840:	0085b103          	ld	sp,8(a1)
    80002844:	6980                	ld	s0,16(a1)
    80002846:	6d84                	ld	s1,24(a1)
    80002848:	0205b903          	ld	s2,32(a1)
    8000284c:	0285b983          	ld	s3,40(a1)
    80002850:	0305ba03          	ld	s4,48(a1)
    80002854:	0385ba83          	ld	s5,56(a1)
    80002858:	0405bb03          	ld	s6,64(a1)
    8000285c:	0485bb83          	ld	s7,72(a1)
    80002860:	0505bc03          	ld	s8,80(a1)
    80002864:	0585bc83          	ld	s9,88(a1)
    80002868:	0605bd03          	ld	s10,96(a1)
    8000286c:	0685bd83          	ld	s11,104(a1)
    80002870:	8082                	ret

0000000080002872 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    80002872:	1141                	addi	sp,sp,-16
    80002874:	e406                	sd	ra,8(sp)
    80002876:	e022                	sd	s0,0(sp)
    80002878:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    8000287a:	00006597          	auipc	a1,0x6
    8000287e:	a7e58593          	addi	a1,a1,-1410 # 800082f8 <states.0+0x30>
    80002882:	00014517          	auipc	a0,0x14
    80002886:	31e50513          	addi	a0,a0,798 # 80016ba0 <tickslock>
    8000288a:	ffffe097          	auipc	ra,0xffffe
    8000288e:	2bc080e7          	jalr	700(ra) # 80000b46 <initlock>
}
    80002892:	60a2                	ld	ra,8(sp)
    80002894:	6402                	ld	s0,0(sp)
    80002896:	0141                	addi	sp,sp,16
    80002898:	8082                	ret

000000008000289a <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    8000289a:	1141                	addi	sp,sp,-16
    8000289c:	e422                	sd	s0,8(sp)
    8000289e:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028a0:	00003797          	auipc	a5,0x3
    800028a4:	5f078793          	addi	a5,a5,1520 # 80005e90 <kernelvec>
    800028a8:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    800028ac:	6422                	ld	s0,8(sp)
    800028ae:	0141                	addi	sp,sp,16
    800028b0:	8082                	ret

00000000800028b2 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    800028b2:	1141                	addi	sp,sp,-16
    800028b4:	e406                	sd	ra,8(sp)
    800028b6:	e022                	sd	s0,0(sp)
    800028b8:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    800028ba:	fffff097          	auipc	ra,0xfffff
    800028be:	0f2080e7          	jalr	242(ra) # 800019ac <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028c2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    800028c6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028c8:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    800028cc:	00004697          	auipc	a3,0x4
    800028d0:	73468693          	addi	a3,a3,1844 # 80007000 <_trampoline>
    800028d4:	00004717          	auipc	a4,0x4
    800028d8:	72c70713          	addi	a4,a4,1836 # 80007000 <_trampoline>
    800028dc:	8f15                	sub	a4,a4,a3
    800028de:	040007b7          	lui	a5,0x4000
    800028e2:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    800028e4:	07b2                	slli	a5,a5,0xc
    800028e6:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028e8:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800028ec:	7138                	ld	a4,96(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800028ee:	18002673          	csrr	a2,satp
    800028f2:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800028f4:	7130                	ld	a2,96(a0)
    800028f6:	6538                	ld	a4,72(a0)
    800028f8:	6585                	lui	a1,0x1
    800028fa:	972e                	add	a4,a4,a1
    800028fc:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800028fe:	7138                	ld	a4,96(a0)
    80002900:	00000617          	auipc	a2,0x0
    80002904:	13060613          	addi	a2,a2,304 # 80002a30 <usertrap>
    80002908:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000290a:	7138                	ld	a4,96(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    8000290c:	8612                	mv	a2,tp
    8000290e:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002910:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002914:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002918:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000291c:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002920:	7138                	ld	a4,96(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002922:	6f18                	ld	a4,24(a4)
    80002924:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002928:	6d28                	ld	a0,88(a0)
    8000292a:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    8000292c:	00004717          	auipc	a4,0x4
    80002930:	77070713          	addi	a4,a4,1904 # 8000709c <userret>
    80002934:	8f15                	sub	a4,a4,a3
    80002936:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002938:	577d                	li	a4,-1
    8000293a:	177e                	slli	a4,a4,0x3f
    8000293c:	8d59                	or	a0,a0,a4
    8000293e:	9782                	jalr	a5
}
    80002940:	60a2                	ld	ra,8(sp)
    80002942:	6402                	ld	s0,0(sp)
    80002944:	0141                	addi	sp,sp,16
    80002946:	8082                	ret

0000000080002948 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002948:	1101                	addi	sp,sp,-32
    8000294a:	ec06                	sd	ra,24(sp)
    8000294c:	e822                	sd	s0,16(sp)
    8000294e:	e426                	sd	s1,8(sp)
    80002950:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002952:	00014497          	auipc	s1,0x14
    80002956:	24e48493          	addi	s1,s1,590 # 80016ba0 <tickslock>
    8000295a:	8526                	mv	a0,s1
    8000295c:	ffffe097          	auipc	ra,0xffffe
    80002960:	27a080e7          	jalr	634(ra) # 80000bd6 <acquire>
  ticks++;
    80002964:	00006517          	auipc	a0,0x6
    80002968:	f9c50513          	addi	a0,a0,-100 # 80008900 <ticks>
    8000296c:	411c                	lw	a5,0(a0)
    8000296e:	2785                	addiw	a5,a5,1
    80002970:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002972:	00000097          	auipc	ra,0x0
    80002976:	872080e7          	jalr	-1934(ra) # 800021e4 <wakeup>
  release(&tickslock);
    8000297a:	8526                	mv	a0,s1
    8000297c:	ffffe097          	auipc	ra,0xffffe
    80002980:	30e080e7          	jalr	782(ra) # 80000c8a <release>
}
    80002984:	60e2                	ld	ra,24(sp)
    80002986:	6442                	ld	s0,16(sp)
    80002988:	64a2                	ld	s1,8(sp)
    8000298a:	6105                	addi	sp,sp,32
    8000298c:	8082                	ret

000000008000298e <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    8000298e:	1101                	addi	sp,sp,-32
    80002990:	ec06                	sd	ra,24(sp)
    80002992:	e822                	sd	s0,16(sp)
    80002994:	e426                	sd	s1,8(sp)
    80002996:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002998:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000299c:	00074d63          	bltz	a4,800029b6 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800029a0:	57fd                	li	a5,-1
    800029a2:	17fe                	slli	a5,a5,0x3f
    800029a4:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800029a6:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800029a8:	06f70363          	beq	a4,a5,80002a0e <devintr+0x80>
  }
}
    800029ac:	60e2                	ld	ra,24(sp)
    800029ae:	6442                	ld	s0,16(sp)
    800029b0:	64a2                	ld	s1,8(sp)
    800029b2:	6105                	addi	sp,sp,32
    800029b4:	8082                	ret
     (scause & 0xff) == 9){
    800029b6:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    800029ba:	46a5                	li	a3,9
    800029bc:	fed792e3          	bne	a5,a3,800029a0 <devintr+0x12>
    int irq = plic_claim();
    800029c0:	00003097          	auipc	ra,0x3
    800029c4:	5d8080e7          	jalr	1496(ra) # 80005f98 <plic_claim>
    800029c8:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800029ca:	47a9                	li	a5,10
    800029cc:	02f50763          	beq	a0,a5,800029fa <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800029d0:	4785                	li	a5,1
    800029d2:	02f50963          	beq	a0,a5,80002a04 <devintr+0x76>
    return 1;
    800029d6:	4505                	li	a0,1
    } else if(irq){
    800029d8:	d8f1                	beqz	s1,800029ac <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800029da:	85a6                	mv	a1,s1
    800029dc:	00006517          	auipc	a0,0x6
    800029e0:	92450513          	addi	a0,a0,-1756 # 80008300 <states.0+0x38>
    800029e4:	ffffe097          	auipc	ra,0xffffe
    800029e8:	ba6080e7          	jalr	-1114(ra) # 8000058a <printf>
      plic_complete(irq);
    800029ec:	8526                	mv	a0,s1
    800029ee:	00003097          	auipc	ra,0x3
    800029f2:	5ce080e7          	jalr	1486(ra) # 80005fbc <plic_complete>
    return 1;
    800029f6:	4505                	li	a0,1
    800029f8:	bf55                	j	800029ac <devintr+0x1e>
      uartintr();
    800029fa:	ffffe097          	auipc	ra,0xffffe
    800029fe:	f9e080e7          	jalr	-98(ra) # 80000998 <uartintr>
    80002a02:	b7ed                	j	800029ec <devintr+0x5e>
      virtio_disk_intr();
    80002a04:	00004097          	auipc	ra,0x4
    80002a08:	a80080e7          	jalr	-1408(ra) # 80006484 <virtio_disk_intr>
    80002a0c:	b7c5                	j	800029ec <devintr+0x5e>
    if(cpuid() == 0){
    80002a0e:	fffff097          	auipc	ra,0xfffff
    80002a12:	f72080e7          	jalr	-142(ra) # 80001980 <cpuid>
    80002a16:	c901                	beqz	a0,80002a26 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80002a18:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002a1c:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002a1e:	14479073          	csrw	sip,a5
    return 2;
    80002a22:	4509                	li	a0,2
    80002a24:	b761                	j	800029ac <devintr+0x1e>
      clockintr();
    80002a26:	00000097          	auipc	ra,0x0
    80002a2a:	f22080e7          	jalr	-222(ra) # 80002948 <clockintr>
    80002a2e:	b7ed                	j	80002a18 <devintr+0x8a>

0000000080002a30 <usertrap>:
{
    80002a30:	1101                	addi	sp,sp,-32
    80002a32:	ec06                	sd	ra,24(sp)
    80002a34:	e822                	sd	s0,16(sp)
    80002a36:	e426                	sd	s1,8(sp)
    80002a38:	e04a                	sd	s2,0(sp)
    80002a3a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a3c:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002a40:	1007f793          	andi	a5,a5,256
    80002a44:	e3b1                	bnez	a5,80002a88 <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a46:	00003797          	auipc	a5,0x3
    80002a4a:	44a78793          	addi	a5,a5,1098 # 80005e90 <kernelvec>
    80002a4e:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002a52:	fffff097          	auipc	ra,0xfffff
    80002a56:	f5a080e7          	jalr	-166(ra) # 800019ac <myproc>
    80002a5a:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    80002a5c:	713c                	ld	a5,96(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a5e:	14102773          	csrr	a4,sepc
    80002a62:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a64:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002a68:	47a1                	li	a5,8
    80002a6a:	02f70763          	beq	a4,a5,80002a98 <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    80002a6e:	00000097          	auipc	ra,0x0
    80002a72:	f20080e7          	jalr	-224(ra) # 8000298e <devintr>
    80002a76:	892a                	mv	s2,a0
    80002a78:	c151                	beqz	a0,80002afc <usertrap+0xcc>
  if(killed(p))
    80002a7a:	8526                	mv	a0,s1
    80002a7c:	00000097          	auipc	ra,0x0
    80002a80:	9ac080e7          	jalr	-1620(ra) # 80002428 <killed>
    80002a84:	c929                	beqz	a0,80002ad6 <usertrap+0xa6>
    80002a86:	a099                	j	80002acc <usertrap+0x9c>
    panic("usertrap: not from user mode");
    80002a88:	00006517          	auipc	a0,0x6
    80002a8c:	89850513          	addi	a0,a0,-1896 # 80008320 <states.0+0x58>
    80002a90:	ffffe097          	auipc	ra,0xffffe
    80002a94:	ab0080e7          	jalr	-1360(ra) # 80000540 <panic>
    if(killed(p))
    80002a98:	00000097          	auipc	ra,0x0
    80002a9c:	990080e7          	jalr	-1648(ra) # 80002428 <killed>
    80002aa0:	e921                	bnez	a0,80002af0 <usertrap+0xc0>
    p->trapframe->epc += 4;
    80002aa2:	70b8                	ld	a4,96(s1)
    80002aa4:	6f1c                	ld	a5,24(a4)
    80002aa6:	0791                	addi	a5,a5,4
    80002aa8:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002aaa:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002aae:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ab2:	10079073          	csrw	sstatus,a5
    syscall();
    80002ab6:	00000097          	auipc	ra,0x0
    80002aba:	2d4080e7          	jalr	724(ra) # 80002d8a <syscall>
  if(killed(p))
    80002abe:	8526                	mv	a0,s1
    80002ac0:	00000097          	auipc	ra,0x0
    80002ac4:	968080e7          	jalr	-1688(ra) # 80002428 <killed>
    80002ac8:	c911                	beqz	a0,80002adc <usertrap+0xac>
    80002aca:	4901                	li	s2,0
    exit(-1);
    80002acc:	557d                	li	a0,-1
    80002ace:	fffff097          	auipc	ra,0xfffff
    80002ad2:	7e6080e7          	jalr	2022(ra) # 800022b4 <exit>
  if(which_dev == 2)
    80002ad6:	4789                	li	a5,2
    80002ad8:	04f90f63          	beq	s2,a5,80002b36 <usertrap+0x106>
  usertrapret();
    80002adc:	00000097          	auipc	ra,0x0
    80002ae0:	dd6080e7          	jalr	-554(ra) # 800028b2 <usertrapret>
}
    80002ae4:	60e2                	ld	ra,24(sp)
    80002ae6:	6442                	ld	s0,16(sp)
    80002ae8:	64a2                	ld	s1,8(sp)
    80002aea:	6902                	ld	s2,0(sp)
    80002aec:	6105                	addi	sp,sp,32
    80002aee:	8082                	ret
      exit(-1);
    80002af0:	557d                	li	a0,-1
    80002af2:	fffff097          	auipc	ra,0xfffff
    80002af6:	7c2080e7          	jalr	1986(ra) # 800022b4 <exit>
    80002afa:	b765                	j	80002aa2 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002afc:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002b00:	5890                	lw	a2,48(s1)
    80002b02:	00006517          	auipc	a0,0x6
    80002b06:	83e50513          	addi	a0,a0,-1986 # 80008340 <states.0+0x78>
    80002b0a:	ffffe097          	auipc	ra,0xffffe
    80002b0e:	a80080e7          	jalr	-1408(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b12:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002b16:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002b1a:	00006517          	auipc	a0,0x6
    80002b1e:	85650513          	addi	a0,a0,-1962 # 80008370 <states.0+0xa8>
    80002b22:	ffffe097          	auipc	ra,0xffffe
    80002b26:	a68080e7          	jalr	-1432(ra) # 8000058a <printf>
    setkilled(p);
    80002b2a:	8526                	mv	a0,s1
    80002b2c:	00000097          	auipc	ra,0x0
    80002b30:	8d0080e7          	jalr	-1840(ra) # 800023fc <setkilled>
    80002b34:	b769                	j	80002abe <usertrap+0x8e>
    yield();
    80002b36:	fffff097          	auipc	ra,0xfffff
    80002b3a:	60e080e7          	jalr	1550(ra) # 80002144 <yield>
    80002b3e:	bf79                	j	80002adc <usertrap+0xac>

0000000080002b40 <kerneltrap>:
{
    80002b40:	7179                	addi	sp,sp,-48
    80002b42:	f406                	sd	ra,40(sp)
    80002b44:	f022                	sd	s0,32(sp)
    80002b46:	ec26                	sd	s1,24(sp)
    80002b48:	e84a                	sd	s2,16(sp)
    80002b4a:	e44e                	sd	s3,8(sp)
    80002b4c:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002b4e:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b52:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002b56:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002b5a:	1004f793          	andi	a5,s1,256
    80002b5e:	cb85                	beqz	a5,80002b8e <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002b60:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002b64:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002b66:	ef85                	bnez	a5,80002b9e <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002b68:	00000097          	auipc	ra,0x0
    80002b6c:	e26080e7          	jalr	-474(ra) # 8000298e <devintr>
    80002b70:	cd1d                	beqz	a0,80002bae <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002b72:	4789                	li	a5,2
    80002b74:	06f50a63          	beq	a0,a5,80002be8 <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002b78:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002b7c:	10049073          	csrw	sstatus,s1
}
    80002b80:	70a2                	ld	ra,40(sp)
    80002b82:	7402                	ld	s0,32(sp)
    80002b84:	64e2                	ld	s1,24(sp)
    80002b86:	6942                	ld	s2,16(sp)
    80002b88:	69a2                	ld	s3,8(sp)
    80002b8a:	6145                	addi	sp,sp,48
    80002b8c:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002b8e:	00006517          	auipc	a0,0x6
    80002b92:	80250513          	addi	a0,a0,-2046 # 80008390 <states.0+0xc8>
    80002b96:	ffffe097          	auipc	ra,0xffffe
    80002b9a:	9aa080e7          	jalr	-1622(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    80002b9e:	00006517          	auipc	a0,0x6
    80002ba2:	81a50513          	addi	a0,a0,-2022 # 800083b8 <states.0+0xf0>
    80002ba6:	ffffe097          	auipc	ra,0xffffe
    80002baa:	99a080e7          	jalr	-1638(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    80002bae:	85ce                	mv	a1,s3
    80002bb0:	00006517          	auipc	a0,0x6
    80002bb4:	82850513          	addi	a0,a0,-2008 # 800083d8 <states.0+0x110>
    80002bb8:	ffffe097          	auipc	ra,0xffffe
    80002bbc:	9d2080e7          	jalr	-1582(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002bc0:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002bc4:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002bc8:	00006517          	auipc	a0,0x6
    80002bcc:	82050513          	addi	a0,a0,-2016 # 800083e8 <states.0+0x120>
    80002bd0:	ffffe097          	auipc	ra,0xffffe
    80002bd4:	9ba080e7          	jalr	-1606(ra) # 8000058a <printf>
    panic("kerneltrap");
    80002bd8:	00006517          	auipc	a0,0x6
    80002bdc:	82850513          	addi	a0,a0,-2008 # 80008400 <states.0+0x138>
    80002be0:	ffffe097          	auipc	ra,0xffffe
    80002be4:	960080e7          	jalr	-1696(ra) # 80000540 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002be8:	fffff097          	auipc	ra,0xfffff
    80002bec:	dc4080e7          	jalr	-572(ra) # 800019ac <myproc>
    80002bf0:	d541                	beqz	a0,80002b78 <kerneltrap+0x38>
    80002bf2:	fffff097          	auipc	ra,0xfffff
    80002bf6:	dba080e7          	jalr	-582(ra) # 800019ac <myproc>
    80002bfa:	4d18                	lw	a4,24(a0)
    80002bfc:	4791                	li	a5,4
    80002bfe:	f6f71de3          	bne	a4,a5,80002b78 <kerneltrap+0x38>
    yield();
    80002c02:	fffff097          	auipc	ra,0xfffff
    80002c06:	542080e7          	jalr	1346(ra) # 80002144 <yield>
    80002c0a:	b7bd                	j	80002b78 <kerneltrap+0x38>

0000000080002c0c <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002c0c:	1101                	addi	sp,sp,-32
    80002c0e:	ec06                	sd	ra,24(sp)
    80002c10:	e822                	sd	s0,16(sp)
    80002c12:	e426                	sd	s1,8(sp)
    80002c14:	1000                	addi	s0,sp,32
    80002c16:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002c18:	fffff097          	auipc	ra,0xfffff
    80002c1c:	d94080e7          	jalr	-620(ra) # 800019ac <myproc>
  switch (n) {
    80002c20:	4795                	li	a5,5
    80002c22:	0497e163          	bltu	a5,s1,80002c64 <argraw+0x58>
    80002c26:	048a                	slli	s1,s1,0x2
    80002c28:	00006717          	auipc	a4,0x6
    80002c2c:	81070713          	addi	a4,a4,-2032 # 80008438 <states.0+0x170>
    80002c30:	94ba                	add	s1,s1,a4
    80002c32:	409c                	lw	a5,0(s1)
    80002c34:	97ba                	add	a5,a5,a4
    80002c36:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002c38:	713c                	ld	a5,96(a0)
    80002c3a:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002c3c:	60e2                	ld	ra,24(sp)
    80002c3e:	6442                	ld	s0,16(sp)
    80002c40:	64a2                	ld	s1,8(sp)
    80002c42:	6105                	addi	sp,sp,32
    80002c44:	8082                	ret
    return p->trapframe->a1;
    80002c46:	713c                	ld	a5,96(a0)
    80002c48:	7fa8                	ld	a0,120(a5)
    80002c4a:	bfcd                	j	80002c3c <argraw+0x30>
    return p->trapframe->a2;
    80002c4c:	713c                	ld	a5,96(a0)
    80002c4e:	63c8                	ld	a0,128(a5)
    80002c50:	b7f5                	j	80002c3c <argraw+0x30>
    return p->trapframe->a3;
    80002c52:	713c                	ld	a5,96(a0)
    80002c54:	67c8                	ld	a0,136(a5)
    80002c56:	b7dd                	j	80002c3c <argraw+0x30>
    return p->trapframe->a4;
    80002c58:	713c                	ld	a5,96(a0)
    80002c5a:	6bc8                	ld	a0,144(a5)
    80002c5c:	b7c5                	j	80002c3c <argraw+0x30>
    return p->trapframe->a5;
    80002c5e:	713c                	ld	a5,96(a0)
    80002c60:	6fc8                	ld	a0,152(a5)
    80002c62:	bfe9                	j	80002c3c <argraw+0x30>
  panic("argraw");
    80002c64:	00005517          	auipc	a0,0x5
    80002c68:	7ac50513          	addi	a0,a0,1964 # 80008410 <states.0+0x148>
    80002c6c:	ffffe097          	auipc	ra,0xffffe
    80002c70:	8d4080e7          	jalr	-1836(ra) # 80000540 <panic>

0000000080002c74 <fetchaddr>:
{
    80002c74:	1101                	addi	sp,sp,-32
    80002c76:	ec06                	sd	ra,24(sp)
    80002c78:	e822                	sd	s0,16(sp)
    80002c7a:	e426                	sd	s1,8(sp)
    80002c7c:	e04a                	sd	s2,0(sp)
    80002c7e:	1000                	addi	s0,sp,32
    80002c80:	84aa                	mv	s1,a0
    80002c82:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002c84:	fffff097          	auipc	ra,0xfffff
    80002c88:	d28080e7          	jalr	-728(ra) # 800019ac <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002c8c:	693c                	ld	a5,80(a0)
    80002c8e:	02f4f863          	bgeu	s1,a5,80002cbe <fetchaddr+0x4a>
    80002c92:	00848713          	addi	a4,s1,8
    80002c96:	02e7e663          	bltu	a5,a4,80002cc2 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002c9a:	46a1                	li	a3,8
    80002c9c:	8626                	mv	a2,s1
    80002c9e:	85ca                	mv	a1,s2
    80002ca0:	6d28                	ld	a0,88(a0)
    80002ca2:	fffff097          	auipc	ra,0xfffff
    80002ca6:	a56080e7          	jalr	-1450(ra) # 800016f8 <copyin>
    80002caa:	00a03533          	snez	a0,a0
    80002cae:	40a00533          	neg	a0,a0
}
    80002cb2:	60e2                	ld	ra,24(sp)
    80002cb4:	6442                	ld	s0,16(sp)
    80002cb6:	64a2                	ld	s1,8(sp)
    80002cb8:	6902                	ld	s2,0(sp)
    80002cba:	6105                	addi	sp,sp,32
    80002cbc:	8082                	ret
    return -1;
    80002cbe:	557d                	li	a0,-1
    80002cc0:	bfcd                	j	80002cb2 <fetchaddr+0x3e>
    80002cc2:	557d                	li	a0,-1
    80002cc4:	b7fd                	j	80002cb2 <fetchaddr+0x3e>

0000000080002cc6 <fetchstr>:
{
    80002cc6:	7179                	addi	sp,sp,-48
    80002cc8:	f406                	sd	ra,40(sp)
    80002cca:	f022                	sd	s0,32(sp)
    80002ccc:	ec26                	sd	s1,24(sp)
    80002cce:	e84a                	sd	s2,16(sp)
    80002cd0:	e44e                	sd	s3,8(sp)
    80002cd2:	1800                	addi	s0,sp,48
    80002cd4:	892a                	mv	s2,a0
    80002cd6:	84ae                	mv	s1,a1
    80002cd8:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002cda:	fffff097          	auipc	ra,0xfffff
    80002cde:	cd2080e7          	jalr	-814(ra) # 800019ac <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002ce2:	86ce                	mv	a3,s3
    80002ce4:	864a                	mv	a2,s2
    80002ce6:	85a6                	mv	a1,s1
    80002ce8:	6d28                	ld	a0,88(a0)
    80002cea:	fffff097          	auipc	ra,0xfffff
    80002cee:	a9c080e7          	jalr	-1380(ra) # 80001786 <copyinstr>
    80002cf2:	00054e63          	bltz	a0,80002d0e <fetchstr+0x48>
  return strlen(buf);
    80002cf6:	8526                	mv	a0,s1
    80002cf8:	ffffe097          	auipc	ra,0xffffe
    80002cfc:	156080e7          	jalr	342(ra) # 80000e4e <strlen>
}
    80002d00:	70a2                	ld	ra,40(sp)
    80002d02:	7402                	ld	s0,32(sp)
    80002d04:	64e2                	ld	s1,24(sp)
    80002d06:	6942                	ld	s2,16(sp)
    80002d08:	69a2                	ld	s3,8(sp)
    80002d0a:	6145                	addi	sp,sp,48
    80002d0c:	8082                	ret
    return -1;
    80002d0e:	557d                	li	a0,-1
    80002d10:	bfc5                	j	80002d00 <fetchstr+0x3a>

0000000080002d12 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002d12:	1101                	addi	sp,sp,-32
    80002d14:	ec06                	sd	ra,24(sp)
    80002d16:	e822                	sd	s0,16(sp)
    80002d18:	e426                	sd	s1,8(sp)
    80002d1a:	1000                	addi	s0,sp,32
    80002d1c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d1e:	00000097          	auipc	ra,0x0
    80002d22:	eee080e7          	jalr	-274(ra) # 80002c0c <argraw>
    80002d26:	c088                	sw	a0,0(s1)
}
    80002d28:	60e2                	ld	ra,24(sp)
    80002d2a:	6442                	ld	s0,16(sp)
    80002d2c:	64a2                	ld	s1,8(sp)
    80002d2e:	6105                	addi	sp,sp,32
    80002d30:	8082                	ret

0000000080002d32 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002d32:	1101                	addi	sp,sp,-32
    80002d34:	ec06                	sd	ra,24(sp)
    80002d36:	e822                	sd	s0,16(sp)
    80002d38:	e426                	sd	s1,8(sp)
    80002d3a:	1000                	addi	s0,sp,32
    80002d3c:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002d3e:	00000097          	auipc	ra,0x0
    80002d42:	ece080e7          	jalr	-306(ra) # 80002c0c <argraw>
    80002d46:	e088                	sd	a0,0(s1)
}
    80002d48:	60e2                	ld	ra,24(sp)
    80002d4a:	6442                	ld	s0,16(sp)
    80002d4c:	64a2                	ld	s1,8(sp)
    80002d4e:	6105                	addi	sp,sp,32
    80002d50:	8082                	ret

0000000080002d52 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002d52:	7179                	addi	sp,sp,-48
    80002d54:	f406                	sd	ra,40(sp)
    80002d56:	f022                	sd	s0,32(sp)
    80002d58:	ec26                	sd	s1,24(sp)
    80002d5a:	e84a                	sd	s2,16(sp)
    80002d5c:	1800                	addi	s0,sp,48
    80002d5e:	84ae                	mv	s1,a1
    80002d60:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002d62:	fd840593          	addi	a1,s0,-40
    80002d66:	00000097          	auipc	ra,0x0
    80002d6a:	fcc080e7          	jalr	-52(ra) # 80002d32 <argaddr>
  return fetchstr(addr, buf, max);
    80002d6e:	864a                	mv	a2,s2
    80002d70:	85a6                	mv	a1,s1
    80002d72:	fd843503          	ld	a0,-40(s0)
    80002d76:	00000097          	auipc	ra,0x0
    80002d7a:	f50080e7          	jalr	-176(ra) # 80002cc6 <fetchstr>
}
    80002d7e:	70a2                	ld	ra,40(sp)
    80002d80:	7402                	ld	s0,32(sp)
    80002d82:	64e2                	ld	s1,24(sp)
    80002d84:	6942                	ld	s2,16(sp)
    80002d86:	6145                	addi	sp,sp,48
    80002d88:	8082                	ret

0000000080002d8a <syscall>:
[SYS_getpinfo] sys_getpinfo,
};

void
syscall(void)
{
    80002d8a:	1101                	addi	sp,sp,-32
    80002d8c:	ec06                	sd	ra,24(sp)
    80002d8e:	e822                	sd	s0,16(sp)
    80002d90:	e426                	sd	s1,8(sp)
    80002d92:	e04a                	sd	s2,0(sp)
    80002d94:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002d96:	fffff097          	auipc	ra,0xfffff
    80002d9a:	c16080e7          	jalr	-1002(ra) # 800019ac <myproc>
    80002d9e:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002da0:	06053903          	ld	s2,96(a0)
    80002da4:	0a893783          	ld	a5,168(s2)
    80002da8:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002dac:	37fd                	addiw	a5,a5,-1
    80002dae:	4759                	li	a4,22
    80002db0:	00f76f63          	bltu	a4,a5,80002dce <syscall+0x44>
    80002db4:	00369713          	slli	a4,a3,0x3
    80002db8:	00005797          	auipc	a5,0x5
    80002dbc:	69878793          	addi	a5,a5,1688 # 80008450 <syscalls>
    80002dc0:	97ba                	add	a5,a5,a4
    80002dc2:	639c                	ld	a5,0(a5)
    80002dc4:	c789                	beqz	a5,80002dce <syscall+0x44>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002dc6:	9782                	jalr	a5
    80002dc8:	06a93823          	sd	a0,112(s2)
    80002dcc:	a839                	j	80002dea <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002dce:	16048613          	addi	a2,s1,352
    80002dd2:	588c                	lw	a1,48(s1)
    80002dd4:	00005517          	auipc	a0,0x5
    80002dd8:	64450513          	addi	a0,a0,1604 # 80008418 <states.0+0x150>
    80002ddc:	ffffd097          	auipc	ra,0xffffd
    80002de0:	7ae080e7          	jalr	1966(ra) # 8000058a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002de4:	70bc                	ld	a5,96(s1)
    80002de6:	577d                	li	a4,-1
    80002de8:	fbb8                	sd	a4,112(a5)
  }
}
    80002dea:	60e2                	ld	ra,24(sp)
    80002dec:	6442                	ld	s0,16(sp)
    80002dee:	64a2                	ld	s1,8(sp)
    80002df0:	6902                	ld	s2,0(sp)
    80002df2:	6105                	addi	sp,sp,32
    80002df4:	8082                	ret

0000000080002df6 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002df6:	1101                	addi	sp,sp,-32
    80002df8:	ec06                	sd	ra,24(sp)
    80002dfa:	e822                	sd	s0,16(sp)
    80002dfc:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002dfe:	fec40593          	addi	a1,s0,-20
    80002e02:	4501                	li	a0,0
    80002e04:	00000097          	auipc	ra,0x0
    80002e08:	f0e080e7          	jalr	-242(ra) # 80002d12 <argint>
  exit(n);
    80002e0c:	fec42503          	lw	a0,-20(s0)
    80002e10:	fffff097          	auipc	ra,0xfffff
    80002e14:	4a4080e7          	jalr	1188(ra) # 800022b4 <exit>
  return 0;  // not reached
}
    80002e18:	4501                	li	a0,0
    80002e1a:	60e2                	ld	ra,24(sp)
    80002e1c:	6442                	ld	s0,16(sp)
    80002e1e:	6105                	addi	sp,sp,32
    80002e20:	8082                	ret

0000000080002e22 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002e22:	1141                	addi	sp,sp,-16
    80002e24:	e406                	sd	ra,8(sp)
    80002e26:	e022                	sd	s0,0(sp)
    80002e28:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002e2a:	fffff097          	auipc	ra,0xfffff
    80002e2e:	b82080e7          	jalr	-1150(ra) # 800019ac <myproc>
}
    80002e32:	5908                	lw	a0,48(a0)
    80002e34:	60a2                	ld	ra,8(sp)
    80002e36:	6402                	ld	s0,0(sp)
    80002e38:	0141                	addi	sp,sp,16
    80002e3a:	8082                	ret

0000000080002e3c <sys_fork>:

uint64
sys_fork(void)
{
    80002e3c:	1141                	addi	sp,sp,-16
    80002e3e:	e406                	sd	ra,8(sp)
    80002e40:	e022                	sd	s0,0(sp)
    80002e42:	0800                	addi	s0,sp,16
  return fork();
    80002e44:	fffff097          	auipc	ra,0xfffff
    80002e48:	f1e080e7          	jalr	-226(ra) # 80001d62 <fork>
}
    80002e4c:	60a2                	ld	ra,8(sp)
    80002e4e:	6402                	ld	s0,0(sp)
    80002e50:	0141                	addi	sp,sp,16
    80002e52:	8082                	ret

0000000080002e54 <sys_wait>:

uint64
sys_wait(void)
{
    80002e54:	1101                	addi	sp,sp,-32
    80002e56:	ec06                	sd	ra,24(sp)
    80002e58:	e822                	sd	s0,16(sp)
    80002e5a:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002e5c:	fe840593          	addi	a1,s0,-24
    80002e60:	4501                	li	a0,0
    80002e62:	00000097          	auipc	ra,0x0
    80002e66:	ed0080e7          	jalr	-304(ra) # 80002d32 <argaddr>
  return wait(p);
    80002e6a:	fe843503          	ld	a0,-24(s0)
    80002e6e:	fffff097          	auipc	ra,0xfffff
    80002e72:	5ec080e7          	jalr	1516(ra) # 8000245a <wait>
}
    80002e76:	60e2                	ld	ra,24(sp)
    80002e78:	6442                	ld	s0,16(sp)
    80002e7a:	6105                	addi	sp,sp,32
    80002e7c:	8082                	ret

0000000080002e7e <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002e7e:	7179                	addi	sp,sp,-48
    80002e80:	f406                	sd	ra,40(sp)
    80002e82:	f022                	sd	s0,32(sp)
    80002e84:	ec26                	sd	s1,24(sp)
    80002e86:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002e88:	fdc40593          	addi	a1,s0,-36
    80002e8c:	4501                	li	a0,0
    80002e8e:	00000097          	auipc	ra,0x0
    80002e92:	e84080e7          	jalr	-380(ra) # 80002d12 <argint>
  addr = myproc()->sz;
    80002e96:	fffff097          	auipc	ra,0xfffff
    80002e9a:	b16080e7          	jalr	-1258(ra) # 800019ac <myproc>
    80002e9e:	6924                	ld	s1,80(a0)
  if(growproc(n) < 0)
    80002ea0:	fdc42503          	lw	a0,-36(s0)
    80002ea4:	fffff097          	auipc	ra,0xfffff
    80002ea8:	e62080e7          	jalr	-414(ra) # 80001d06 <growproc>
    80002eac:	00054863          	bltz	a0,80002ebc <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002eb0:	8526                	mv	a0,s1
    80002eb2:	70a2                	ld	ra,40(sp)
    80002eb4:	7402                	ld	s0,32(sp)
    80002eb6:	64e2                	ld	s1,24(sp)
    80002eb8:	6145                	addi	sp,sp,48
    80002eba:	8082                	ret
    return -1;
    80002ebc:	54fd                	li	s1,-1
    80002ebe:	bfcd                	j	80002eb0 <sys_sbrk+0x32>

0000000080002ec0 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002ec0:	7139                	addi	sp,sp,-64
    80002ec2:	fc06                	sd	ra,56(sp)
    80002ec4:	f822                	sd	s0,48(sp)
    80002ec6:	f426                	sd	s1,40(sp)
    80002ec8:	f04a                	sd	s2,32(sp)
    80002eca:	ec4e                	sd	s3,24(sp)
    80002ecc:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002ece:	fcc40593          	addi	a1,s0,-52
    80002ed2:	4501                	li	a0,0
    80002ed4:	00000097          	auipc	ra,0x0
    80002ed8:	e3e080e7          	jalr	-450(ra) # 80002d12 <argint>
  acquire(&tickslock);
    80002edc:	00014517          	auipc	a0,0x14
    80002ee0:	cc450513          	addi	a0,a0,-828 # 80016ba0 <tickslock>
    80002ee4:	ffffe097          	auipc	ra,0xffffe
    80002ee8:	cf2080e7          	jalr	-782(ra) # 80000bd6 <acquire>
  ticks0 = ticks;
    80002eec:	00006917          	auipc	s2,0x6
    80002ef0:	a1492903          	lw	s2,-1516(s2) # 80008900 <ticks>
  while(ticks - ticks0 < n){
    80002ef4:	fcc42783          	lw	a5,-52(s0)
    80002ef8:	cf9d                	beqz	a5,80002f36 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002efa:	00014997          	auipc	s3,0x14
    80002efe:	ca698993          	addi	s3,s3,-858 # 80016ba0 <tickslock>
    80002f02:	00006497          	auipc	s1,0x6
    80002f06:	9fe48493          	addi	s1,s1,-1538 # 80008900 <ticks>
    if(killed(myproc())){
    80002f0a:	fffff097          	auipc	ra,0xfffff
    80002f0e:	aa2080e7          	jalr	-1374(ra) # 800019ac <myproc>
    80002f12:	fffff097          	auipc	ra,0xfffff
    80002f16:	516080e7          	jalr	1302(ra) # 80002428 <killed>
    80002f1a:	ed15                	bnez	a0,80002f56 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002f1c:	85ce                	mv	a1,s3
    80002f1e:	8526                	mv	a0,s1
    80002f20:	fffff097          	auipc	ra,0xfffff
    80002f24:	260080e7          	jalr	608(ra) # 80002180 <sleep>
  while(ticks - ticks0 < n){
    80002f28:	409c                	lw	a5,0(s1)
    80002f2a:	412787bb          	subw	a5,a5,s2
    80002f2e:	fcc42703          	lw	a4,-52(s0)
    80002f32:	fce7ece3          	bltu	a5,a4,80002f0a <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002f36:	00014517          	auipc	a0,0x14
    80002f3a:	c6a50513          	addi	a0,a0,-918 # 80016ba0 <tickslock>
    80002f3e:	ffffe097          	auipc	ra,0xffffe
    80002f42:	d4c080e7          	jalr	-692(ra) # 80000c8a <release>
  return 0;
    80002f46:	4501                	li	a0,0
}
    80002f48:	70e2                	ld	ra,56(sp)
    80002f4a:	7442                	ld	s0,48(sp)
    80002f4c:	74a2                	ld	s1,40(sp)
    80002f4e:	7902                	ld	s2,32(sp)
    80002f50:	69e2                	ld	s3,24(sp)
    80002f52:	6121                	addi	sp,sp,64
    80002f54:	8082                	ret
      release(&tickslock);
    80002f56:	00014517          	auipc	a0,0x14
    80002f5a:	c4a50513          	addi	a0,a0,-950 # 80016ba0 <tickslock>
    80002f5e:	ffffe097          	auipc	ra,0xffffe
    80002f62:	d2c080e7          	jalr	-724(ra) # 80000c8a <release>
      return -1;
    80002f66:	557d                	li	a0,-1
    80002f68:	b7c5                	j	80002f48 <sys_sleep+0x88>

0000000080002f6a <sys_kill>:

uint64
sys_kill(void)
{
    80002f6a:	1101                	addi	sp,sp,-32
    80002f6c:	ec06                	sd	ra,24(sp)
    80002f6e:	e822                	sd	s0,16(sp)
    80002f70:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002f72:	fec40593          	addi	a1,s0,-20
    80002f76:	4501                	li	a0,0
    80002f78:	00000097          	auipc	ra,0x0
    80002f7c:	d9a080e7          	jalr	-614(ra) # 80002d12 <argint>
  return kill(pid);
    80002f80:	fec42503          	lw	a0,-20(s0)
    80002f84:	fffff097          	auipc	ra,0xfffff
    80002f88:	406080e7          	jalr	1030(ra) # 8000238a <kill>
}
    80002f8c:	60e2                	ld	ra,24(sp)
    80002f8e:	6442                	ld	s0,16(sp)
    80002f90:	6105                	addi	sp,sp,32
    80002f92:	8082                	ret

0000000080002f94 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002f94:	1101                	addi	sp,sp,-32
    80002f96:	ec06                	sd	ra,24(sp)
    80002f98:	e822                	sd	s0,16(sp)
    80002f9a:	e426                	sd	s1,8(sp)
    80002f9c:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002f9e:	00014517          	auipc	a0,0x14
    80002fa2:	c0250513          	addi	a0,a0,-1022 # 80016ba0 <tickslock>
    80002fa6:	ffffe097          	auipc	ra,0xffffe
    80002faa:	c30080e7          	jalr	-976(ra) # 80000bd6 <acquire>
  xticks = ticks;
    80002fae:	00006497          	auipc	s1,0x6
    80002fb2:	9524a483          	lw	s1,-1710(s1) # 80008900 <ticks>
  release(&tickslock);
    80002fb6:	00014517          	auipc	a0,0x14
    80002fba:	bea50513          	addi	a0,a0,-1046 # 80016ba0 <tickslock>
    80002fbe:	ffffe097          	auipc	ra,0xffffe
    80002fc2:	ccc080e7          	jalr	-820(ra) # 80000c8a <release>
  return xticks;
}
    80002fc6:	02049513          	slli	a0,s1,0x20
    80002fca:	9101                	srli	a0,a0,0x20
    80002fcc:	60e2                	ld	ra,24(sp)
    80002fce:	6442                	ld	s0,16(sp)
    80002fd0:	64a2                	ld	s1,8(sp)
    80002fd2:	6105                	addi	sp,sp,32
    80002fd4:	8082                	ret

0000000080002fd6 <sys_settickets>:

uint64
sys_settickets(void)
{
    80002fd6:	1101                	addi	sp,sp,-32
    80002fd8:	ec06                	sd	ra,24(sp)
    80002fda:	e822                	sd	s0,16(sp)
    80002fdc:	1000                	addi	s0,sp,32
  int n;  // number of tickets
  argint(0, &n);  // pass number of tickets
    80002fde:	fec40593          	addi	a1,s0,-20
    80002fe2:	4501                	li	a0,0
    80002fe4:	00000097          	auipc	ra,0x0
    80002fe8:	d2e080e7          	jalr	-722(ra) # 80002d12 <argint>
  return settickets(n);  // set number of tickets
    80002fec:	fec42503          	lw	a0,-20(s0)
    80002ff0:	fffff097          	auipc	ra,0xfffff
    80002ff4:	6f4080e7          	jalr	1780(ra) # 800026e4 <settickets>
}
    80002ff8:	60e2                	ld	ra,24(sp)
    80002ffa:	6442                	ld	s0,16(sp)
    80002ffc:	6105                	addi	sp,sp,32
    80002ffe:	8082                	ret

0000000080003000 <sys_getpinfo>:

uint64
sys_getpinfo(void)
{
    80003000:	1101                	addi	sp,sp,-32
    80003002:	ec06                	sd	ra,24(sp)
    80003004:	e822                	sd	s0,16(sp)
    80003006:	1000                	addi	s0,sp,32
  uint64 temp;
  argaddr(0, &temp);  // pass struct pointer
    80003008:	fe840593          	addi	a1,s0,-24
    8000300c:	4501                	li	a0,0
    8000300e:	00000097          	auipc	ra,0x0
    80003012:	d24080e7          	jalr	-732(ra) # 80002d32 <argaddr>
  return getpinfo(temp);  // get process info
    80003016:	fe843503          	ld	a0,-24(s0)
    8000301a:	fffff097          	auipc	ra,0xfffff
    8000301e:	73e080e7          	jalr	1854(ra) # 80002758 <getpinfo>
    80003022:	60e2                	ld	ra,24(sp)
    80003024:	6442                	ld	s0,16(sp)
    80003026:	6105                	addi	sp,sp,32
    80003028:	8082                	ret

000000008000302a <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    8000302a:	7179                	addi	sp,sp,-48
    8000302c:	f406                	sd	ra,40(sp)
    8000302e:	f022                	sd	s0,32(sp)
    80003030:	ec26                	sd	s1,24(sp)
    80003032:	e84a                	sd	s2,16(sp)
    80003034:	e44e                	sd	s3,8(sp)
    80003036:	e052                	sd	s4,0(sp)
    80003038:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    8000303a:	00005597          	auipc	a1,0x5
    8000303e:	4d658593          	addi	a1,a1,1238 # 80008510 <syscalls+0xc0>
    80003042:	00014517          	auipc	a0,0x14
    80003046:	b7650513          	addi	a0,a0,-1162 # 80016bb8 <bcache>
    8000304a:	ffffe097          	auipc	ra,0xffffe
    8000304e:	afc080e7          	jalr	-1284(ra) # 80000b46 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003052:	0001c797          	auipc	a5,0x1c
    80003056:	b6678793          	addi	a5,a5,-1178 # 8001ebb8 <bcache+0x8000>
    8000305a:	0001c717          	auipc	a4,0x1c
    8000305e:	dc670713          	addi	a4,a4,-570 # 8001ee20 <bcache+0x8268>
    80003062:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003066:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000306a:	00014497          	auipc	s1,0x14
    8000306e:	b6648493          	addi	s1,s1,-1178 # 80016bd0 <bcache+0x18>
    b->next = bcache.head.next;
    80003072:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003074:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003076:	00005a17          	auipc	s4,0x5
    8000307a:	4a2a0a13          	addi	s4,s4,1186 # 80008518 <syscalls+0xc8>
    b->next = bcache.head.next;
    8000307e:	2b893783          	ld	a5,696(s2)
    80003082:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003084:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003088:	85d2                	mv	a1,s4
    8000308a:	01048513          	addi	a0,s1,16
    8000308e:	00001097          	auipc	ra,0x1
    80003092:	4c8080e7          	jalr	1224(ra) # 80004556 <initsleeplock>
    bcache.head.next->prev = b;
    80003096:	2b893783          	ld	a5,696(s2)
    8000309a:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    8000309c:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    800030a0:	45848493          	addi	s1,s1,1112
    800030a4:	fd349de3          	bne	s1,s3,8000307e <binit+0x54>
  }
}
    800030a8:	70a2                	ld	ra,40(sp)
    800030aa:	7402                	ld	s0,32(sp)
    800030ac:	64e2                	ld	s1,24(sp)
    800030ae:	6942                	ld	s2,16(sp)
    800030b0:	69a2                	ld	s3,8(sp)
    800030b2:	6a02                	ld	s4,0(sp)
    800030b4:	6145                	addi	sp,sp,48
    800030b6:	8082                	ret

00000000800030b8 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800030b8:	7179                	addi	sp,sp,-48
    800030ba:	f406                	sd	ra,40(sp)
    800030bc:	f022                	sd	s0,32(sp)
    800030be:	ec26                	sd	s1,24(sp)
    800030c0:	e84a                	sd	s2,16(sp)
    800030c2:	e44e                	sd	s3,8(sp)
    800030c4:	1800                	addi	s0,sp,48
    800030c6:	892a                	mv	s2,a0
    800030c8:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    800030ca:	00014517          	auipc	a0,0x14
    800030ce:	aee50513          	addi	a0,a0,-1298 # 80016bb8 <bcache>
    800030d2:	ffffe097          	auipc	ra,0xffffe
    800030d6:	b04080e7          	jalr	-1276(ra) # 80000bd6 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800030da:	0001c497          	auipc	s1,0x1c
    800030de:	d964b483          	ld	s1,-618(s1) # 8001ee70 <bcache+0x82b8>
    800030e2:	0001c797          	auipc	a5,0x1c
    800030e6:	d3e78793          	addi	a5,a5,-706 # 8001ee20 <bcache+0x8268>
    800030ea:	02f48f63          	beq	s1,a5,80003128 <bread+0x70>
    800030ee:	873e                	mv	a4,a5
    800030f0:	a021                	j	800030f8 <bread+0x40>
    800030f2:	68a4                	ld	s1,80(s1)
    800030f4:	02e48a63          	beq	s1,a4,80003128 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800030f8:	449c                	lw	a5,8(s1)
    800030fa:	ff279ce3          	bne	a5,s2,800030f2 <bread+0x3a>
    800030fe:	44dc                	lw	a5,12(s1)
    80003100:	ff3799e3          	bne	a5,s3,800030f2 <bread+0x3a>
      b->refcnt++;
    80003104:	40bc                	lw	a5,64(s1)
    80003106:	2785                	addiw	a5,a5,1
    80003108:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    8000310a:	00014517          	auipc	a0,0x14
    8000310e:	aae50513          	addi	a0,a0,-1362 # 80016bb8 <bcache>
    80003112:	ffffe097          	auipc	ra,0xffffe
    80003116:	b78080e7          	jalr	-1160(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    8000311a:	01048513          	addi	a0,s1,16
    8000311e:	00001097          	auipc	ra,0x1
    80003122:	472080e7          	jalr	1138(ra) # 80004590 <acquiresleep>
      return b;
    80003126:	a8b9                	j	80003184 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003128:	0001c497          	auipc	s1,0x1c
    8000312c:	d404b483          	ld	s1,-704(s1) # 8001ee68 <bcache+0x82b0>
    80003130:	0001c797          	auipc	a5,0x1c
    80003134:	cf078793          	addi	a5,a5,-784 # 8001ee20 <bcache+0x8268>
    80003138:	00f48863          	beq	s1,a5,80003148 <bread+0x90>
    8000313c:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000313e:	40bc                	lw	a5,64(s1)
    80003140:	cf81                	beqz	a5,80003158 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003142:	64a4                	ld	s1,72(s1)
    80003144:	fee49de3          	bne	s1,a4,8000313e <bread+0x86>
  panic("bget: no buffers");
    80003148:	00005517          	auipc	a0,0x5
    8000314c:	3d850513          	addi	a0,a0,984 # 80008520 <syscalls+0xd0>
    80003150:	ffffd097          	auipc	ra,0xffffd
    80003154:	3f0080e7          	jalr	1008(ra) # 80000540 <panic>
      b->dev = dev;
    80003158:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    8000315c:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003160:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003164:	4785                	li	a5,1
    80003166:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003168:	00014517          	auipc	a0,0x14
    8000316c:	a5050513          	addi	a0,a0,-1456 # 80016bb8 <bcache>
    80003170:	ffffe097          	auipc	ra,0xffffe
    80003174:	b1a080e7          	jalr	-1254(ra) # 80000c8a <release>
      acquiresleep(&b->lock);
    80003178:	01048513          	addi	a0,s1,16
    8000317c:	00001097          	auipc	ra,0x1
    80003180:	414080e7          	jalr	1044(ra) # 80004590 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003184:	409c                	lw	a5,0(s1)
    80003186:	cb89                	beqz	a5,80003198 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003188:	8526                	mv	a0,s1
    8000318a:	70a2                	ld	ra,40(sp)
    8000318c:	7402                	ld	s0,32(sp)
    8000318e:	64e2                	ld	s1,24(sp)
    80003190:	6942                	ld	s2,16(sp)
    80003192:	69a2                	ld	s3,8(sp)
    80003194:	6145                	addi	sp,sp,48
    80003196:	8082                	ret
    virtio_disk_rw(b, 0);
    80003198:	4581                	li	a1,0
    8000319a:	8526                	mv	a0,s1
    8000319c:	00003097          	auipc	ra,0x3
    800031a0:	0b6080e7          	jalr	182(ra) # 80006252 <virtio_disk_rw>
    b->valid = 1;
    800031a4:	4785                	li	a5,1
    800031a6:	c09c                	sw	a5,0(s1)
  return b;
    800031a8:	b7c5                	j	80003188 <bread+0xd0>

00000000800031aa <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    800031aa:	1101                	addi	sp,sp,-32
    800031ac:	ec06                	sd	ra,24(sp)
    800031ae:	e822                	sd	s0,16(sp)
    800031b0:	e426                	sd	s1,8(sp)
    800031b2:	1000                	addi	s0,sp,32
    800031b4:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800031b6:	0541                	addi	a0,a0,16
    800031b8:	00001097          	auipc	ra,0x1
    800031bc:	472080e7          	jalr	1138(ra) # 8000462a <holdingsleep>
    800031c0:	cd01                	beqz	a0,800031d8 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800031c2:	4585                	li	a1,1
    800031c4:	8526                	mv	a0,s1
    800031c6:	00003097          	auipc	ra,0x3
    800031ca:	08c080e7          	jalr	140(ra) # 80006252 <virtio_disk_rw>
}
    800031ce:	60e2                	ld	ra,24(sp)
    800031d0:	6442                	ld	s0,16(sp)
    800031d2:	64a2                	ld	s1,8(sp)
    800031d4:	6105                	addi	sp,sp,32
    800031d6:	8082                	ret
    panic("bwrite");
    800031d8:	00005517          	auipc	a0,0x5
    800031dc:	36050513          	addi	a0,a0,864 # 80008538 <syscalls+0xe8>
    800031e0:	ffffd097          	auipc	ra,0xffffd
    800031e4:	360080e7          	jalr	864(ra) # 80000540 <panic>

00000000800031e8 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800031e8:	1101                	addi	sp,sp,-32
    800031ea:	ec06                	sd	ra,24(sp)
    800031ec:	e822                	sd	s0,16(sp)
    800031ee:	e426                	sd	s1,8(sp)
    800031f0:	e04a                	sd	s2,0(sp)
    800031f2:	1000                	addi	s0,sp,32
    800031f4:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800031f6:	01050913          	addi	s2,a0,16
    800031fa:	854a                	mv	a0,s2
    800031fc:	00001097          	auipc	ra,0x1
    80003200:	42e080e7          	jalr	1070(ra) # 8000462a <holdingsleep>
    80003204:	c92d                	beqz	a0,80003276 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003206:	854a                	mv	a0,s2
    80003208:	00001097          	auipc	ra,0x1
    8000320c:	3de080e7          	jalr	990(ra) # 800045e6 <releasesleep>

  acquire(&bcache.lock);
    80003210:	00014517          	auipc	a0,0x14
    80003214:	9a850513          	addi	a0,a0,-1624 # 80016bb8 <bcache>
    80003218:	ffffe097          	auipc	ra,0xffffe
    8000321c:	9be080e7          	jalr	-1602(ra) # 80000bd6 <acquire>
  b->refcnt--;
    80003220:	40bc                	lw	a5,64(s1)
    80003222:	37fd                	addiw	a5,a5,-1
    80003224:	0007871b          	sext.w	a4,a5
    80003228:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    8000322a:	eb05                	bnez	a4,8000325a <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    8000322c:	68bc                	ld	a5,80(s1)
    8000322e:	64b8                	ld	a4,72(s1)
    80003230:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003232:	64bc                	ld	a5,72(s1)
    80003234:	68b8                	ld	a4,80(s1)
    80003236:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003238:	0001c797          	auipc	a5,0x1c
    8000323c:	98078793          	addi	a5,a5,-1664 # 8001ebb8 <bcache+0x8000>
    80003240:	2b87b703          	ld	a4,696(a5)
    80003244:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003246:	0001c717          	auipc	a4,0x1c
    8000324a:	bda70713          	addi	a4,a4,-1062 # 8001ee20 <bcache+0x8268>
    8000324e:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003250:	2b87b703          	ld	a4,696(a5)
    80003254:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003256:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000325a:	00014517          	auipc	a0,0x14
    8000325e:	95e50513          	addi	a0,a0,-1698 # 80016bb8 <bcache>
    80003262:	ffffe097          	auipc	ra,0xffffe
    80003266:	a28080e7          	jalr	-1496(ra) # 80000c8a <release>
}
    8000326a:	60e2                	ld	ra,24(sp)
    8000326c:	6442                	ld	s0,16(sp)
    8000326e:	64a2                	ld	s1,8(sp)
    80003270:	6902                	ld	s2,0(sp)
    80003272:	6105                	addi	sp,sp,32
    80003274:	8082                	ret
    panic("brelse");
    80003276:	00005517          	auipc	a0,0x5
    8000327a:	2ca50513          	addi	a0,a0,714 # 80008540 <syscalls+0xf0>
    8000327e:	ffffd097          	auipc	ra,0xffffd
    80003282:	2c2080e7          	jalr	706(ra) # 80000540 <panic>

0000000080003286 <bpin>:

void
bpin(struct buf *b) {
    80003286:	1101                	addi	sp,sp,-32
    80003288:	ec06                	sd	ra,24(sp)
    8000328a:	e822                	sd	s0,16(sp)
    8000328c:	e426                	sd	s1,8(sp)
    8000328e:	1000                	addi	s0,sp,32
    80003290:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003292:	00014517          	auipc	a0,0x14
    80003296:	92650513          	addi	a0,a0,-1754 # 80016bb8 <bcache>
    8000329a:	ffffe097          	auipc	ra,0xffffe
    8000329e:	93c080e7          	jalr	-1732(ra) # 80000bd6 <acquire>
  b->refcnt++;
    800032a2:	40bc                	lw	a5,64(s1)
    800032a4:	2785                	addiw	a5,a5,1
    800032a6:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800032a8:	00014517          	auipc	a0,0x14
    800032ac:	91050513          	addi	a0,a0,-1776 # 80016bb8 <bcache>
    800032b0:	ffffe097          	auipc	ra,0xffffe
    800032b4:	9da080e7          	jalr	-1574(ra) # 80000c8a <release>
}
    800032b8:	60e2                	ld	ra,24(sp)
    800032ba:	6442                	ld	s0,16(sp)
    800032bc:	64a2                	ld	s1,8(sp)
    800032be:	6105                	addi	sp,sp,32
    800032c0:	8082                	ret

00000000800032c2 <bunpin>:

void
bunpin(struct buf *b) {
    800032c2:	1101                	addi	sp,sp,-32
    800032c4:	ec06                	sd	ra,24(sp)
    800032c6:	e822                	sd	s0,16(sp)
    800032c8:	e426                	sd	s1,8(sp)
    800032ca:	1000                	addi	s0,sp,32
    800032cc:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800032ce:	00014517          	auipc	a0,0x14
    800032d2:	8ea50513          	addi	a0,a0,-1814 # 80016bb8 <bcache>
    800032d6:	ffffe097          	auipc	ra,0xffffe
    800032da:	900080e7          	jalr	-1792(ra) # 80000bd6 <acquire>
  b->refcnt--;
    800032de:	40bc                	lw	a5,64(s1)
    800032e0:	37fd                	addiw	a5,a5,-1
    800032e2:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800032e4:	00014517          	auipc	a0,0x14
    800032e8:	8d450513          	addi	a0,a0,-1836 # 80016bb8 <bcache>
    800032ec:	ffffe097          	auipc	ra,0xffffe
    800032f0:	99e080e7          	jalr	-1634(ra) # 80000c8a <release>
}
    800032f4:	60e2                	ld	ra,24(sp)
    800032f6:	6442                	ld	s0,16(sp)
    800032f8:	64a2                	ld	s1,8(sp)
    800032fa:	6105                	addi	sp,sp,32
    800032fc:	8082                	ret

00000000800032fe <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800032fe:	1101                	addi	sp,sp,-32
    80003300:	ec06                	sd	ra,24(sp)
    80003302:	e822                	sd	s0,16(sp)
    80003304:	e426                	sd	s1,8(sp)
    80003306:	e04a                	sd	s2,0(sp)
    80003308:	1000                	addi	s0,sp,32
    8000330a:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    8000330c:	00d5d59b          	srliw	a1,a1,0xd
    80003310:	0001c797          	auipc	a5,0x1c
    80003314:	f847a783          	lw	a5,-124(a5) # 8001f294 <sb+0x1c>
    80003318:	9dbd                	addw	a1,a1,a5
    8000331a:	00000097          	auipc	ra,0x0
    8000331e:	d9e080e7          	jalr	-610(ra) # 800030b8 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003322:	0074f713          	andi	a4,s1,7
    80003326:	4785                	li	a5,1
    80003328:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    8000332c:	14ce                	slli	s1,s1,0x33
    8000332e:	90d9                	srli	s1,s1,0x36
    80003330:	00950733          	add	a4,a0,s1
    80003334:	05874703          	lbu	a4,88(a4)
    80003338:	00e7f6b3          	and	a3,a5,a4
    8000333c:	c69d                	beqz	a3,8000336a <bfree+0x6c>
    8000333e:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003340:	94aa                	add	s1,s1,a0
    80003342:	fff7c793          	not	a5,a5
    80003346:	8f7d                	and	a4,a4,a5
    80003348:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    8000334c:	00001097          	auipc	ra,0x1
    80003350:	126080e7          	jalr	294(ra) # 80004472 <log_write>
  brelse(bp);
    80003354:	854a                	mv	a0,s2
    80003356:	00000097          	auipc	ra,0x0
    8000335a:	e92080e7          	jalr	-366(ra) # 800031e8 <brelse>
}
    8000335e:	60e2                	ld	ra,24(sp)
    80003360:	6442                	ld	s0,16(sp)
    80003362:	64a2                	ld	s1,8(sp)
    80003364:	6902                	ld	s2,0(sp)
    80003366:	6105                	addi	sp,sp,32
    80003368:	8082                	ret
    panic("freeing free block");
    8000336a:	00005517          	auipc	a0,0x5
    8000336e:	1de50513          	addi	a0,a0,478 # 80008548 <syscalls+0xf8>
    80003372:	ffffd097          	auipc	ra,0xffffd
    80003376:	1ce080e7          	jalr	462(ra) # 80000540 <panic>

000000008000337a <balloc>:
{
    8000337a:	711d                	addi	sp,sp,-96
    8000337c:	ec86                	sd	ra,88(sp)
    8000337e:	e8a2                	sd	s0,80(sp)
    80003380:	e4a6                	sd	s1,72(sp)
    80003382:	e0ca                	sd	s2,64(sp)
    80003384:	fc4e                	sd	s3,56(sp)
    80003386:	f852                	sd	s4,48(sp)
    80003388:	f456                	sd	s5,40(sp)
    8000338a:	f05a                	sd	s6,32(sp)
    8000338c:	ec5e                	sd	s7,24(sp)
    8000338e:	e862                	sd	s8,16(sp)
    80003390:	e466                	sd	s9,8(sp)
    80003392:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003394:	0001c797          	auipc	a5,0x1c
    80003398:	ee87a783          	lw	a5,-280(a5) # 8001f27c <sb+0x4>
    8000339c:	cff5                	beqz	a5,80003498 <balloc+0x11e>
    8000339e:	8baa                	mv	s7,a0
    800033a0:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    800033a2:	0001cb17          	auipc	s6,0x1c
    800033a6:	ed6b0b13          	addi	s6,s6,-298 # 8001f278 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033aa:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    800033ac:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800033ae:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    800033b0:	6c89                	lui	s9,0x2
    800033b2:	a061                	j	8000343a <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    800033b4:	97ca                	add	a5,a5,s2
    800033b6:	8e55                	or	a2,a2,a3
    800033b8:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    800033bc:	854a                	mv	a0,s2
    800033be:	00001097          	auipc	ra,0x1
    800033c2:	0b4080e7          	jalr	180(ra) # 80004472 <log_write>
        brelse(bp);
    800033c6:	854a                	mv	a0,s2
    800033c8:	00000097          	auipc	ra,0x0
    800033cc:	e20080e7          	jalr	-480(ra) # 800031e8 <brelse>
  bp = bread(dev, bno);
    800033d0:	85a6                	mv	a1,s1
    800033d2:	855e                	mv	a0,s7
    800033d4:	00000097          	auipc	ra,0x0
    800033d8:	ce4080e7          	jalr	-796(ra) # 800030b8 <bread>
    800033dc:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    800033de:	40000613          	li	a2,1024
    800033e2:	4581                	li	a1,0
    800033e4:	05850513          	addi	a0,a0,88
    800033e8:	ffffe097          	auipc	ra,0xffffe
    800033ec:	8ea080e7          	jalr	-1814(ra) # 80000cd2 <memset>
  log_write(bp);
    800033f0:	854a                	mv	a0,s2
    800033f2:	00001097          	auipc	ra,0x1
    800033f6:	080080e7          	jalr	128(ra) # 80004472 <log_write>
  brelse(bp);
    800033fa:	854a                	mv	a0,s2
    800033fc:	00000097          	auipc	ra,0x0
    80003400:	dec080e7          	jalr	-532(ra) # 800031e8 <brelse>
}
    80003404:	8526                	mv	a0,s1
    80003406:	60e6                	ld	ra,88(sp)
    80003408:	6446                	ld	s0,80(sp)
    8000340a:	64a6                	ld	s1,72(sp)
    8000340c:	6906                	ld	s2,64(sp)
    8000340e:	79e2                	ld	s3,56(sp)
    80003410:	7a42                	ld	s4,48(sp)
    80003412:	7aa2                	ld	s5,40(sp)
    80003414:	7b02                	ld	s6,32(sp)
    80003416:	6be2                	ld	s7,24(sp)
    80003418:	6c42                	ld	s8,16(sp)
    8000341a:	6ca2                	ld	s9,8(sp)
    8000341c:	6125                	addi	sp,sp,96
    8000341e:	8082                	ret
    brelse(bp);
    80003420:	854a                	mv	a0,s2
    80003422:	00000097          	auipc	ra,0x0
    80003426:	dc6080e7          	jalr	-570(ra) # 800031e8 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    8000342a:	015c87bb          	addw	a5,s9,s5
    8000342e:	00078a9b          	sext.w	s5,a5
    80003432:	004b2703          	lw	a4,4(s6)
    80003436:	06eaf163          	bgeu	s5,a4,80003498 <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    8000343a:	41fad79b          	sraiw	a5,s5,0x1f
    8000343e:	0137d79b          	srliw	a5,a5,0x13
    80003442:	015787bb          	addw	a5,a5,s5
    80003446:	40d7d79b          	sraiw	a5,a5,0xd
    8000344a:	01cb2583          	lw	a1,28(s6)
    8000344e:	9dbd                	addw	a1,a1,a5
    80003450:	855e                	mv	a0,s7
    80003452:	00000097          	auipc	ra,0x0
    80003456:	c66080e7          	jalr	-922(ra) # 800030b8 <bread>
    8000345a:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000345c:	004b2503          	lw	a0,4(s6)
    80003460:	000a849b          	sext.w	s1,s5
    80003464:	8762                	mv	a4,s8
    80003466:	faa4fde3          	bgeu	s1,a0,80003420 <balloc+0xa6>
      m = 1 << (bi % 8);
    8000346a:	00777693          	andi	a3,a4,7
    8000346e:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003472:	41f7579b          	sraiw	a5,a4,0x1f
    80003476:	01d7d79b          	srliw	a5,a5,0x1d
    8000347a:	9fb9                	addw	a5,a5,a4
    8000347c:	4037d79b          	sraiw	a5,a5,0x3
    80003480:	00f90633          	add	a2,s2,a5
    80003484:	05864603          	lbu	a2,88(a2)
    80003488:	00c6f5b3          	and	a1,a3,a2
    8000348c:	d585                	beqz	a1,800033b4 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000348e:	2705                	addiw	a4,a4,1
    80003490:	2485                	addiw	s1,s1,1
    80003492:	fd471ae3          	bne	a4,s4,80003466 <balloc+0xec>
    80003496:	b769                	j	80003420 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    80003498:	00005517          	auipc	a0,0x5
    8000349c:	0c850513          	addi	a0,a0,200 # 80008560 <syscalls+0x110>
    800034a0:	ffffd097          	auipc	ra,0xffffd
    800034a4:	0ea080e7          	jalr	234(ra) # 8000058a <printf>
  return 0;
    800034a8:	4481                	li	s1,0
    800034aa:	bfa9                	j	80003404 <balloc+0x8a>

00000000800034ac <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    800034ac:	7179                	addi	sp,sp,-48
    800034ae:	f406                	sd	ra,40(sp)
    800034b0:	f022                	sd	s0,32(sp)
    800034b2:	ec26                	sd	s1,24(sp)
    800034b4:	e84a                	sd	s2,16(sp)
    800034b6:	e44e                	sd	s3,8(sp)
    800034b8:	e052                	sd	s4,0(sp)
    800034ba:	1800                	addi	s0,sp,48
    800034bc:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800034be:	47ad                	li	a5,11
    800034c0:	02b7e863          	bltu	a5,a1,800034f0 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    800034c4:	02059793          	slli	a5,a1,0x20
    800034c8:	01e7d593          	srli	a1,a5,0x1e
    800034cc:	00b504b3          	add	s1,a0,a1
    800034d0:	0504a903          	lw	s2,80(s1)
    800034d4:	06091e63          	bnez	s2,80003550 <bmap+0xa4>
      addr = balloc(ip->dev);
    800034d8:	4108                	lw	a0,0(a0)
    800034da:	00000097          	auipc	ra,0x0
    800034de:	ea0080e7          	jalr	-352(ra) # 8000337a <balloc>
    800034e2:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800034e6:	06090563          	beqz	s2,80003550 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    800034ea:	0524a823          	sw	s2,80(s1)
    800034ee:	a08d                	j	80003550 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    800034f0:	ff45849b          	addiw	s1,a1,-12
    800034f4:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800034f8:	0ff00793          	li	a5,255
    800034fc:	08e7e563          	bltu	a5,a4,80003586 <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003500:	08052903          	lw	s2,128(a0)
    80003504:	00091d63          	bnez	s2,8000351e <bmap+0x72>
      addr = balloc(ip->dev);
    80003508:	4108                	lw	a0,0(a0)
    8000350a:	00000097          	auipc	ra,0x0
    8000350e:	e70080e7          	jalr	-400(ra) # 8000337a <balloc>
    80003512:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003516:	02090d63          	beqz	s2,80003550 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    8000351a:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    8000351e:	85ca                	mv	a1,s2
    80003520:	0009a503          	lw	a0,0(s3)
    80003524:	00000097          	auipc	ra,0x0
    80003528:	b94080e7          	jalr	-1132(ra) # 800030b8 <bread>
    8000352c:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    8000352e:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003532:	02049713          	slli	a4,s1,0x20
    80003536:	01e75593          	srli	a1,a4,0x1e
    8000353a:	00b784b3          	add	s1,a5,a1
    8000353e:	0004a903          	lw	s2,0(s1)
    80003542:	02090063          	beqz	s2,80003562 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003546:	8552                	mv	a0,s4
    80003548:	00000097          	auipc	ra,0x0
    8000354c:	ca0080e7          	jalr	-864(ra) # 800031e8 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003550:	854a                	mv	a0,s2
    80003552:	70a2                	ld	ra,40(sp)
    80003554:	7402                	ld	s0,32(sp)
    80003556:	64e2                	ld	s1,24(sp)
    80003558:	6942                	ld	s2,16(sp)
    8000355a:	69a2                	ld	s3,8(sp)
    8000355c:	6a02                	ld	s4,0(sp)
    8000355e:	6145                	addi	sp,sp,48
    80003560:	8082                	ret
      addr = balloc(ip->dev);
    80003562:	0009a503          	lw	a0,0(s3)
    80003566:	00000097          	auipc	ra,0x0
    8000356a:	e14080e7          	jalr	-492(ra) # 8000337a <balloc>
    8000356e:	0005091b          	sext.w	s2,a0
      if(addr){
    80003572:	fc090ae3          	beqz	s2,80003546 <bmap+0x9a>
        a[bn] = addr;
    80003576:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    8000357a:	8552                	mv	a0,s4
    8000357c:	00001097          	auipc	ra,0x1
    80003580:	ef6080e7          	jalr	-266(ra) # 80004472 <log_write>
    80003584:	b7c9                	j	80003546 <bmap+0x9a>
  panic("bmap: out of range");
    80003586:	00005517          	auipc	a0,0x5
    8000358a:	ff250513          	addi	a0,a0,-14 # 80008578 <syscalls+0x128>
    8000358e:	ffffd097          	auipc	ra,0xffffd
    80003592:	fb2080e7          	jalr	-78(ra) # 80000540 <panic>

0000000080003596 <iget>:
{
    80003596:	7179                	addi	sp,sp,-48
    80003598:	f406                	sd	ra,40(sp)
    8000359a:	f022                	sd	s0,32(sp)
    8000359c:	ec26                	sd	s1,24(sp)
    8000359e:	e84a                	sd	s2,16(sp)
    800035a0:	e44e                	sd	s3,8(sp)
    800035a2:	e052                	sd	s4,0(sp)
    800035a4:	1800                	addi	s0,sp,48
    800035a6:	89aa                	mv	s3,a0
    800035a8:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    800035aa:	0001c517          	auipc	a0,0x1c
    800035ae:	cee50513          	addi	a0,a0,-786 # 8001f298 <itable>
    800035b2:	ffffd097          	auipc	ra,0xffffd
    800035b6:	624080e7          	jalr	1572(ra) # 80000bd6 <acquire>
  empty = 0;
    800035ba:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800035bc:	0001c497          	auipc	s1,0x1c
    800035c0:	cf448493          	addi	s1,s1,-780 # 8001f2b0 <itable+0x18>
    800035c4:	0001d697          	auipc	a3,0x1d
    800035c8:	77c68693          	addi	a3,a3,1916 # 80020d40 <log>
    800035cc:	a039                	j	800035da <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800035ce:	02090b63          	beqz	s2,80003604 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800035d2:	08848493          	addi	s1,s1,136
    800035d6:	02d48a63          	beq	s1,a3,8000360a <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800035da:	449c                	lw	a5,8(s1)
    800035dc:	fef059e3          	blez	a5,800035ce <iget+0x38>
    800035e0:	4098                	lw	a4,0(s1)
    800035e2:	ff3716e3          	bne	a4,s3,800035ce <iget+0x38>
    800035e6:	40d8                	lw	a4,4(s1)
    800035e8:	ff4713e3          	bne	a4,s4,800035ce <iget+0x38>
      ip->ref++;
    800035ec:	2785                	addiw	a5,a5,1
    800035ee:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800035f0:	0001c517          	auipc	a0,0x1c
    800035f4:	ca850513          	addi	a0,a0,-856 # 8001f298 <itable>
    800035f8:	ffffd097          	auipc	ra,0xffffd
    800035fc:	692080e7          	jalr	1682(ra) # 80000c8a <release>
      return ip;
    80003600:	8926                	mv	s2,s1
    80003602:	a03d                	j	80003630 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80003604:	f7f9                	bnez	a5,800035d2 <iget+0x3c>
    80003606:	8926                	mv	s2,s1
    80003608:	b7e9                	j	800035d2 <iget+0x3c>
  if(empty == 0)
    8000360a:	02090c63          	beqz	s2,80003642 <iget+0xac>
  ip->dev = dev;
    8000360e:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80003612:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80003616:	4785                	li	a5,1
    80003618:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000361c:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80003620:	0001c517          	auipc	a0,0x1c
    80003624:	c7850513          	addi	a0,a0,-904 # 8001f298 <itable>
    80003628:	ffffd097          	auipc	ra,0xffffd
    8000362c:	662080e7          	jalr	1634(ra) # 80000c8a <release>
}
    80003630:	854a                	mv	a0,s2
    80003632:	70a2                	ld	ra,40(sp)
    80003634:	7402                	ld	s0,32(sp)
    80003636:	64e2                	ld	s1,24(sp)
    80003638:	6942                	ld	s2,16(sp)
    8000363a:	69a2                	ld	s3,8(sp)
    8000363c:	6a02                	ld	s4,0(sp)
    8000363e:	6145                	addi	sp,sp,48
    80003640:	8082                	ret
    panic("iget: no inodes");
    80003642:	00005517          	auipc	a0,0x5
    80003646:	f4e50513          	addi	a0,a0,-178 # 80008590 <syscalls+0x140>
    8000364a:	ffffd097          	auipc	ra,0xffffd
    8000364e:	ef6080e7          	jalr	-266(ra) # 80000540 <panic>

0000000080003652 <fsinit>:
fsinit(int dev) {
    80003652:	7179                	addi	sp,sp,-48
    80003654:	f406                	sd	ra,40(sp)
    80003656:	f022                	sd	s0,32(sp)
    80003658:	ec26                	sd	s1,24(sp)
    8000365a:	e84a                	sd	s2,16(sp)
    8000365c:	e44e                	sd	s3,8(sp)
    8000365e:	1800                	addi	s0,sp,48
    80003660:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003662:	4585                	li	a1,1
    80003664:	00000097          	auipc	ra,0x0
    80003668:	a54080e7          	jalr	-1452(ra) # 800030b8 <bread>
    8000366c:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000366e:	0001c997          	auipc	s3,0x1c
    80003672:	c0a98993          	addi	s3,s3,-1014 # 8001f278 <sb>
    80003676:	02000613          	li	a2,32
    8000367a:	05850593          	addi	a1,a0,88
    8000367e:	854e                	mv	a0,s3
    80003680:	ffffd097          	auipc	ra,0xffffd
    80003684:	6ae080e7          	jalr	1710(ra) # 80000d2e <memmove>
  brelse(bp);
    80003688:	8526                	mv	a0,s1
    8000368a:	00000097          	auipc	ra,0x0
    8000368e:	b5e080e7          	jalr	-1186(ra) # 800031e8 <brelse>
  if(sb.magic != FSMAGIC)
    80003692:	0009a703          	lw	a4,0(s3)
    80003696:	102037b7          	lui	a5,0x10203
    8000369a:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000369e:	02f71263          	bne	a4,a5,800036c2 <fsinit+0x70>
  initlog(dev, &sb);
    800036a2:	0001c597          	auipc	a1,0x1c
    800036a6:	bd658593          	addi	a1,a1,-1066 # 8001f278 <sb>
    800036aa:	854a                	mv	a0,s2
    800036ac:	00001097          	auipc	ra,0x1
    800036b0:	b4a080e7          	jalr	-1206(ra) # 800041f6 <initlog>
}
    800036b4:	70a2                	ld	ra,40(sp)
    800036b6:	7402                	ld	s0,32(sp)
    800036b8:	64e2                	ld	s1,24(sp)
    800036ba:	6942                	ld	s2,16(sp)
    800036bc:	69a2                	ld	s3,8(sp)
    800036be:	6145                	addi	sp,sp,48
    800036c0:	8082                	ret
    panic("invalid file system");
    800036c2:	00005517          	auipc	a0,0x5
    800036c6:	ede50513          	addi	a0,a0,-290 # 800085a0 <syscalls+0x150>
    800036ca:	ffffd097          	auipc	ra,0xffffd
    800036ce:	e76080e7          	jalr	-394(ra) # 80000540 <panic>

00000000800036d2 <iinit>:
{
    800036d2:	7179                	addi	sp,sp,-48
    800036d4:	f406                	sd	ra,40(sp)
    800036d6:	f022                	sd	s0,32(sp)
    800036d8:	ec26                	sd	s1,24(sp)
    800036da:	e84a                	sd	s2,16(sp)
    800036dc:	e44e                	sd	s3,8(sp)
    800036de:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800036e0:	00005597          	auipc	a1,0x5
    800036e4:	ed858593          	addi	a1,a1,-296 # 800085b8 <syscalls+0x168>
    800036e8:	0001c517          	auipc	a0,0x1c
    800036ec:	bb050513          	addi	a0,a0,-1104 # 8001f298 <itable>
    800036f0:	ffffd097          	auipc	ra,0xffffd
    800036f4:	456080e7          	jalr	1110(ra) # 80000b46 <initlock>
  for(i = 0; i < NINODE; i++) {
    800036f8:	0001c497          	auipc	s1,0x1c
    800036fc:	bc848493          	addi	s1,s1,-1080 # 8001f2c0 <itable+0x28>
    80003700:	0001d997          	auipc	s3,0x1d
    80003704:	65098993          	addi	s3,s3,1616 # 80020d50 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    80003708:	00005917          	auipc	s2,0x5
    8000370c:	eb890913          	addi	s2,s2,-328 # 800085c0 <syscalls+0x170>
    80003710:	85ca                	mv	a1,s2
    80003712:	8526                	mv	a0,s1
    80003714:	00001097          	auipc	ra,0x1
    80003718:	e42080e7          	jalr	-446(ra) # 80004556 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000371c:	08848493          	addi	s1,s1,136
    80003720:	ff3498e3          	bne	s1,s3,80003710 <iinit+0x3e>
}
    80003724:	70a2                	ld	ra,40(sp)
    80003726:	7402                	ld	s0,32(sp)
    80003728:	64e2                	ld	s1,24(sp)
    8000372a:	6942                	ld	s2,16(sp)
    8000372c:	69a2                	ld	s3,8(sp)
    8000372e:	6145                	addi	sp,sp,48
    80003730:	8082                	ret

0000000080003732 <ialloc>:
{
    80003732:	715d                	addi	sp,sp,-80
    80003734:	e486                	sd	ra,72(sp)
    80003736:	e0a2                	sd	s0,64(sp)
    80003738:	fc26                	sd	s1,56(sp)
    8000373a:	f84a                	sd	s2,48(sp)
    8000373c:	f44e                	sd	s3,40(sp)
    8000373e:	f052                	sd	s4,32(sp)
    80003740:	ec56                	sd	s5,24(sp)
    80003742:	e85a                	sd	s6,16(sp)
    80003744:	e45e                	sd	s7,8(sp)
    80003746:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003748:	0001c717          	auipc	a4,0x1c
    8000374c:	b3c72703          	lw	a4,-1220(a4) # 8001f284 <sb+0xc>
    80003750:	4785                	li	a5,1
    80003752:	04e7fa63          	bgeu	a5,a4,800037a6 <ialloc+0x74>
    80003756:	8aaa                	mv	s5,a0
    80003758:	8bae                	mv	s7,a1
    8000375a:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000375c:	0001ca17          	auipc	s4,0x1c
    80003760:	b1ca0a13          	addi	s4,s4,-1252 # 8001f278 <sb>
    80003764:	00048b1b          	sext.w	s6,s1
    80003768:	0044d593          	srli	a1,s1,0x4
    8000376c:	018a2783          	lw	a5,24(s4)
    80003770:	9dbd                	addw	a1,a1,a5
    80003772:	8556                	mv	a0,s5
    80003774:	00000097          	auipc	ra,0x0
    80003778:	944080e7          	jalr	-1724(ra) # 800030b8 <bread>
    8000377c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000377e:	05850993          	addi	s3,a0,88
    80003782:	00f4f793          	andi	a5,s1,15
    80003786:	079a                	slli	a5,a5,0x6
    80003788:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000378a:	00099783          	lh	a5,0(s3)
    8000378e:	c3a1                	beqz	a5,800037ce <ialloc+0x9c>
    brelse(bp);
    80003790:	00000097          	auipc	ra,0x0
    80003794:	a58080e7          	jalr	-1448(ra) # 800031e8 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003798:	0485                	addi	s1,s1,1
    8000379a:	00ca2703          	lw	a4,12(s4)
    8000379e:	0004879b          	sext.w	a5,s1
    800037a2:	fce7e1e3          	bltu	a5,a4,80003764 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    800037a6:	00005517          	auipc	a0,0x5
    800037aa:	e2250513          	addi	a0,a0,-478 # 800085c8 <syscalls+0x178>
    800037ae:	ffffd097          	auipc	ra,0xffffd
    800037b2:	ddc080e7          	jalr	-548(ra) # 8000058a <printf>
  return 0;
    800037b6:	4501                	li	a0,0
}
    800037b8:	60a6                	ld	ra,72(sp)
    800037ba:	6406                	ld	s0,64(sp)
    800037bc:	74e2                	ld	s1,56(sp)
    800037be:	7942                	ld	s2,48(sp)
    800037c0:	79a2                	ld	s3,40(sp)
    800037c2:	7a02                	ld	s4,32(sp)
    800037c4:	6ae2                	ld	s5,24(sp)
    800037c6:	6b42                	ld	s6,16(sp)
    800037c8:	6ba2                	ld	s7,8(sp)
    800037ca:	6161                	addi	sp,sp,80
    800037cc:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    800037ce:	04000613          	li	a2,64
    800037d2:	4581                	li	a1,0
    800037d4:	854e                	mv	a0,s3
    800037d6:	ffffd097          	auipc	ra,0xffffd
    800037da:	4fc080e7          	jalr	1276(ra) # 80000cd2 <memset>
      dip->type = type;
    800037de:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800037e2:	854a                	mv	a0,s2
    800037e4:	00001097          	auipc	ra,0x1
    800037e8:	c8e080e7          	jalr	-882(ra) # 80004472 <log_write>
      brelse(bp);
    800037ec:	854a                	mv	a0,s2
    800037ee:	00000097          	auipc	ra,0x0
    800037f2:	9fa080e7          	jalr	-1542(ra) # 800031e8 <brelse>
      return iget(dev, inum);
    800037f6:	85da                	mv	a1,s6
    800037f8:	8556                	mv	a0,s5
    800037fa:	00000097          	auipc	ra,0x0
    800037fe:	d9c080e7          	jalr	-612(ra) # 80003596 <iget>
    80003802:	bf5d                	j	800037b8 <ialloc+0x86>

0000000080003804 <iupdate>:
{
    80003804:	1101                	addi	sp,sp,-32
    80003806:	ec06                	sd	ra,24(sp)
    80003808:	e822                	sd	s0,16(sp)
    8000380a:	e426                	sd	s1,8(sp)
    8000380c:	e04a                	sd	s2,0(sp)
    8000380e:	1000                	addi	s0,sp,32
    80003810:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003812:	415c                	lw	a5,4(a0)
    80003814:	0047d79b          	srliw	a5,a5,0x4
    80003818:	0001c597          	auipc	a1,0x1c
    8000381c:	a785a583          	lw	a1,-1416(a1) # 8001f290 <sb+0x18>
    80003820:	9dbd                	addw	a1,a1,a5
    80003822:	4108                	lw	a0,0(a0)
    80003824:	00000097          	auipc	ra,0x0
    80003828:	894080e7          	jalr	-1900(ra) # 800030b8 <bread>
    8000382c:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000382e:	05850793          	addi	a5,a0,88
    80003832:	40d8                	lw	a4,4(s1)
    80003834:	8b3d                	andi	a4,a4,15
    80003836:	071a                	slli	a4,a4,0x6
    80003838:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    8000383a:	04449703          	lh	a4,68(s1)
    8000383e:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    80003842:	04649703          	lh	a4,70(s1)
    80003846:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    8000384a:	04849703          	lh	a4,72(s1)
    8000384e:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003852:	04a49703          	lh	a4,74(s1)
    80003856:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    8000385a:	44f8                	lw	a4,76(s1)
    8000385c:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000385e:	03400613          	li	a2,52
    80003862:	05048593          	addi	a1,s1,80
    80003866:	00c78513          	addi	a0,a5,12
    8000386a:	ffffd097          	auipc	ra,0xffffd
    8000386e:	4c4080e7          	jalr	1220(ra) # 80000d2e <memmove>
  log_write(bp);
    80003872:	854a                	mv	a0,s2
    80003874:	00001097          	auipc	ra,0x1
    80003878:	bfe080e7          	jalr	-1026(ra) # 80004472 <log_write>
  brelse(bp);
    8000387c:	854a                	mv	a0,s2
    8000387e:	00000097          	auipc	ra,0x0
    80003882:	96a080e7          	jalr	-1686(ra) # 800031e8 <brelse>
}
    80003886:	60e2                	ld	ra,24(sp)
    80003888:	6442                	ld	s0,16(sp)
    8000388a:	64a2                	ld	s1,8(sp)
    8000388c:	6902                	ld	s2,0(sp)
    8000388e:	6105                	addi	sp,sp,32
    80003890:	8082                	ret

0000000080003892 <idup>:
{
    80003892:	1101                	addi	sp,sp,-32
    80003894:	ec06                	sd	ra,24(sp)
    80003896:	e822                	sd	s0,16(sp)
    80003898:	e426                	sd	s1,8(sp)
    8000389a:	1000                	addi	s0,sp,32
    8000389c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000389e:	0001c517          	auipc	a0,0x1c
    800038a2:	9fa50513          	addi	a0,a0,-1542 # 8001f298 <itable>
    800038a6:	ffffd097          	auipc	ra,0xffffd
    800038aa:	330080e7          	jalr	816(ra) # 80000bd6 <acquire>
  ip->ref++;
    800038ae:	449c                	lw	a5,8(s1)
    800038b0:	2785                	addiw	a5,a5,1
    800038b2:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    800038b4:	0001c517          	auipc	a0,0x1c
    800038b8:	9e450513          	addi	a0,a0,-1564 # 8001f298 <itable>
    800038bc:	ffffd097          	auipc	ra,0xffffd
    800038c0:	3ce080e7          	jalr	974(ra) # 80000c8a <release>
}
    800038c4:	8526                	mv	a0,s1
    800038c6:	60e2                	ld	ra,24(sp)
    800038c8:	6442                	ld	s0,16(sp)
    800038ca:	64a2                	ld	s1,8(sp)
    800038cc:	6105                	addi	sp,sp,32
    800038ce:	8082                	ret

00000000800038d0 <ilock>:
{
    800038d0:	1101                	addi	sp,sp,-32
    800038d2:	ec06                	sd	ra,24(sp)
    800038d4:	e822                	sd	s0,16(sp)
    800038d6:	e426                	sd	s1,8(sp)
    800038d8:	e04a                	sd	s2,0(sp)
    800038da:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800038dc:	c115                	beqz	a0,80003900 <ilock+0x30>
    800038de:	84aa                	mv	s1,a0
    800038e0:	451c                	lw	a5,8(a0)
    800038e2:	00f05f63          	blez	a5,80003900 <ilock+0x30>
  acquiresleep(&ip->lock);
    800038e6:	0541                	addi	a0,a0,16
    800038e8:	00001097          	auipc	ra,0x1
    800038ec:	ca8080e7          	jalr	-856(ra) # 80004590 <acquiresleep>
  if(ip->valid == 0){
    800038f0:	40bc                	lw	a5,64(s1)
    800038f2:	cf99                	beqz	a5,80003910 <ilock+0x40>
}
    800038f4:	60e2                	ld	ra,24(sp)
    800038f6:	6442                	ld	s0,16(sp)
    800038f8:	64a2                	ld	s1,8(sp)
    800038fa:	6902                	ld	s2,0(sp)
    800038fc:	6105                	addi	sp,sp,32
    800038fe:	8082                	ret
    panic("ilock");
    80003900:	00005517          	auipc	a0,0x5
    80003904:	ce050513          	addi	a0,a0,-800 # 800085e0 <syscalls+0x190>
    80003908:	ffffd097          	auipc	ra,0xffffd
    8000390c:	c38080e7          	jalr	-968(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80003910:	40dc                	lw	a5,4(s1)
    80003912:	0047d79b          	srliw	a5,a5,0x4
    80003916:	0001c597          	auipc	a1,0x1c
    8000391a:	97a5a583          	lw	a1,-1670(a1) # 8001f290 <sb+0x18>
    8000391e:	9dbd                	addw	a1,a1,a5
    80003920:	4088                	lw	a0,0(s1)
    80003922:	fffff097          	auipc	ra,0xfffff
    80003926:	796080e7          	jalr	1942(ra) # 800030b8 <bread>
    8000392a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000392c:	05850593          	addi	a1,a0,88
    80003930:	40dc                	lw	a5,4(s1)
    80003932:	8bbd                	andi	a5,a5,15
    80003934:	079a                	slli	a5,a5,0x6
    80003936:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003938:	00059783          	lh	a5,0(a1)
    8000393c:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003940:	00259783          	lh	a5,2(a1)
    80003944:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003948:	00459783          	lh	a5,4(a1)
    8000394c:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003950:	00659783          	lh	a5,6(a1)
    80003954:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003958:	459c                	lw	a5,8(a1)
    8000395a:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000395c:	03400613          	li	a2,52
    80003960:	05b1                	addi	a1,a1,12
    80003962:	05048513          	addi	a0,s1,80
    80003966:	ffffd097          	auipc	ra,0xffffd
    8000396a:	3c8080e7          	jalr	968(ra) # 80000d2e <memmove>
    brelse(bp);
    8000396e:	854a                	mv	a0,s2
    80003970:	00000097          	auipc	ra,0x0
    80003974:	878080e7          	jalr	-1928(ra) # 800031e8 <brelse>
    ip->valid = 1;
    80003978:	4785                	li	a5,1
    8000397a:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000397c:	04449783          	lh	a5,68(s1)
    80003980:	fbb5                	bnez	a5,800038f4 <ilock+0x24>
      panic("ilock: no type");
    80003982:	00005517          	auipc	a0,0x5
    80003986:	c6650513          	addi	a0,a0,-922 # 800085e8 <syscalls+0x198>
    8000398a:	ffffd097          	auipc	ra,0xffffd
    8000398e:	bb6080e7          	jalr	-1098(ra) # 80000540 <panic>

0000000080003992 <iunlock>:
{
    80003992:	1101                	addi	sp,sp,-32
    80003994:	ec06                	sd	ra,24(sp)
    80003996:	e822                	sd	s0,16(sp)
    80003998:	e426                	sd	s1,8(sp)
    8000399a:	e04a                	sd	s2,0(sp)
    8000399c:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000399e:	c905                	beqz	a0,800039ce <iunlock+0x3c>
    800039a0:	84aa                	mv	s1,a0
    800039a2:	01050913          	addi	s2,a0,16
    800039a6:	854a                	mv	a0,s2
    800039a8:	00001097          	auipc	ra,0x1
    800039ac:	c82080e7          	jalr	-894(ra) # 8000462a <holdingsleep>
    800039b0:	cd19                	beqz	a0,800039ce <iunlock+0x3c>
    800039b2:	449c                	lw	a5,8(s1)
    800039b4:	00f05d63          	blez	a5,800039ce <iunlock+0x3c>
  releasesleep(&ip->lock);
    800039b8:	854a                	mv	a0,s2
    800039ba:	00001097          	auipc	ra,0x1
    800039be:	c2c080e7          	jalr	-980(ra) # 800045e6 <releasesleep>
}
    800039c2:	60e2                	ld	ra,24(sp)
    800039c4:	6442                	ld	s0,16(sp)
    800039c6:	64a2                	ld	s1,8(sp)
    800039c8:	6902                	ld	s2,0(sp)
    800039ca:	6105                	addi	sp,sp,32
    800039cc:	8082                	ret
    panic("iunlock");
    800039ce:	00005517          	auipc	a0,0x5
    800039d2:	c2a50513          	addi	a0,a0,-982 # 800085f8 <syscalls+0x1a8>
    800039d6:	ffffd097          	auipc	ra,0xffffd
    800039da:	b6a080e7          	jalr	-1174(ra) # 80000540 <panic>

00000000800039de <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    800039de:	7179                	addi	sp,sp,-48
    800039e0:	f406                	sd	ra,40(sp)
    800039e2:	f022                	sd	s0,32(sp)
    800039e4:	ec26                	sd	s1,24(sp)
    800039e6:	e84a                	sd	s2,16(sp)
    800039e8:	e44e                	sd	s3,8(sp)
    800039ea:	e052                	sd	s4,0(sp)
    800039ec:	1800                	addi	s0,sp,48
    800039ee:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800039f0:	05050493          	addi	s1,a0,80
    800039f4:	08050913          	addi	s2,a0,128
    800039f8:	a021                	j	80003a00 <itrunc+0x22>
    800039fa:	0491                	addi	s1,s1,4
    800039fc:	01248d63          	beq	s1,s2,80003a16 <itrunc+0x38>
    if(ip->addrs[i]){
    80003a00:	408c                	lw	a1,0(s1)
    80003a02:	dde5                	beqz	a1,800039fa <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003a04:	0009a503          	lw	a0,0(s3)
    80003a08:	00000097          	auipc	ra,0x0
    80003a0c:	8f6080e7          	jalr	-1802(ra) # 800032fe <bfree>
      ip->addrs[i] = 0;
    80003a10:	0004a023          	sw	zero,0(s1)
    80003a14:	b7dd                	j	800039fa <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003a16:	0809a583          	lw	a1,128(s3)
    80003a1a:	e185                	bnez	a1,80003a3a <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003a1c:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003a20:	854e                	mv	a0,s3
    80003a22:	00000097          	auipc	ra,0x0
    80003a26:	de2080e7          	jalr	-542(ra) # 80003804 <iupdate>
}
    80003a2a:	70a2                	ld	ra,40(sp)
    80003a2c:	7402                	ld	s0,32(sp)
    80003a2e:	64e2                	ld	s1,24(sp)
    80003a30:	6942                	ld	s2,16(sp)
    80003a32:	69a2                	ld	s3,8(sp)
    80003a34:	6a02                	ld	s4,0(sp)
    80003a36:	6145                	addi	sp,sp,48
    80003a38:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003a3a:	0009a503          	lw	a0,0(s3)
    80003a3e:	fffff097          	auipc	ra,0xfffff
    80003a42:	67a080e7          	jalr	1658(ra) # 800030b8 <bread>
    80003a46:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003a48:	05850493          	addi	s1,a0,88
    80003a4c:	45850913          	addi	s2,a0,1112
    80003a50:	a021                	j	80003a58 <itrunc+0x7a>
    80003a52:	0491                	addi	s1,s1,4
    80003a54:	01248b63          	beq	s1,s2,80003a6a <itrunc+0x8c>
      if(a[j])
    80003a58:	408c                	lw	a1,0(s1)
    80003a5a:	dde5                	beqz	a1,80003a52 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    80003a5c:	0009a503          	lw	a0,0(s3)
    80003a60:	00000097          	auipc	ra,0x0
    80003a64:	89e080e7          	jalr	-1890(ra) # 800032fe <bfree>
    80003a68:	b7ed                	j	80003a52 <itrunc+0x74>
    brelse(bp);
    80003a6a:	8552                	mv	a0,s4
    80003a6c:	fffff097          	auipc	ra,0xfffff
    80003a70:	77c080e7          	jalr	1916(ra) # 800031e8 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003a74:	0809a583          	lw	a1,128(s3)
    80003a78:	0009a503          	lw	a0,0(s3)
    80003a7c:	00000097          	auipc	ra,0x0
    80003a80:	882080e7          	jalr	-1918(ra) # 800032fe <bfree>
    ip->addrs[NDIRECT] = 0;
    80003a84:	0809a023          	sw	zero,128(s3)
    80003a88:	bf51                	j	80003a1c <itrunc+0x3e>

0000000080003a8a <iput>:
{
    80003a8a:	1101                	addi	sp,sp,-32
    80003a8c:	ec06                	sd	ra,24(sp)
    80003a8e:	e822                	sd	s0,16(sp)
    80003a90:	e426                	sd	s1,8(sp)
    80003a92:	e04a                	sd	s2,0(sp)
    80003a94:	1000                	addi	s0,sp,32
    80003a96:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003a98:	0001c517          	auipc	a0,0x1c
    80003a9c:	80050513          	addi	a0,a0,-2048 # 8001f298 <itable>
    80003aa0:	ffffd097          	auipc	ra,0xffffd
    80003aa4:	136080e7          	jalr	310(ra) # 80000bd6 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003aa8:	4498                	lw	a4,8(s1)
    80003aaa:	4785                	li	a5,1
    80003aac:	02f70363          	beq	a4,a5,80003ad2 <iput+0x48>
  ip->ref--;
    80003ab0:	449c                	lw	a5,8(s1)
    80003ab2:	37fd                	addiw	a5,a5,-1
    80003ab4:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003ab6:	0001b517          	auipc	a0,0x1b
    80003aba:	7e250513          	addi	a0,a0,2018 # 8001f298 <itable>
    80003abe:	ffffd097          	auipc	ra,0xffffd
    80003ac2:	1cc080e7          	jalr	460(ra) # 80000c8a <release>
}
    80003ac6:	60e2                	ld	ra,24(sp)
    80003ac8:	6442                	ld	s0,16(sp)
    80003aca:	64a2                	ld	s1,8(sp)
    80003acc:	6902                	ld	s2,0(sp)
    80003ace:	6105                	addi	sp,sp,32
    80003ad0:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003ad2:	40bc                	lw	a5,64(s1)
    80003ad4:	dff1                	beqz	a5,80003ab0 <iput+0x26>
    80003ad6:	04a49783          	lh	a5,74(s1)
    80003ada:	fbf9                	bnez	a5,80003ab0 <iput+0x26>
    acquiresleep(&ip->lock);
    80003adc:	01048913          	addi	s2,s1,16
    80003ae0:	854a                	mv	a0,s2
    80003ae2:	00001097          	auipc	ra,0x1
    80003ae6:	aae080e7          	jalr	-1362(ra) # 80004590 <acquiresleep>
    release(&itable.lock);
    80003aea:	0001b517          	auipc	a0,0x1b
    80003aee:	7ae50513          	addi	a0,a0,1966 # 8001f298 <itable>
    80003af2:	ffffd097          	auipc	ra,0xffffd
    80003af6:	198080e7          	jalr	408(ra) # 80000c8a <release>
    itrunc(ip);
    80003afa:	8526                	mv	a0,s1
    80003afc:	00000097          	auipc	ra,0x0
    80003b00:	ee2080e7          	jalr	-286(ra) # 800039de <itrunc>
    ip->type = 0;
    80003b04:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003b08:	8526                	mv	a0,s1
    80003b0a:	00000097          	auipc	ra,0x0
    80003b0e:	cfa080e7          	jalr	-774(ra) # 80003804 <iupdate>
    ip->valid = 0;
    80003b12:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003b16:	854a                	mv	a0,s2
    80003b18:	00001097          	auipc	ra,0x1
    80003b1c:	ace080e7          	jalr	-1330(ra) # 800045e6 <releasesleep>
    acquire(&itable.lock);
    80003b20:	0001b517          	auipc	a0,0x1b
    80003b24:	77850513          	addi	a0,a0,1912 # 8001f298 <itable>
    80003b28:	ffffd097          	auipc	ra,0xffffd
    80003b2c:	0ae080e7          	jalr	174(ra) # 80000bd6 <acquire>
    80003b30:	b741                	j	80003ab0 <iput+0x26>

0000000080003b32 <iunlockput>:
{
    80003b32:	1101                	addi	sp,sp,-32
    80003b34:	ec06                	sd	ra,24(sp)
    80003b36:	e822                	sd	s0,16(sp)
    80003b38:	e426                	sd	s1,8(sp)
    80003b3a:	1000                	addi	s0,sp,32
    80003b3c:	84aa                	mv	s1,a0
  iunlock(ip);
    80003b3e:	00000097          	auipc	ra,0x0
    80003b42:	e54080e7          	jalr	-428(ra) # 80003992 <iunlock>
  iput(ip);
    80003b46:	8526                	mv	a0,s1
    80003b48:	00000097          	auipc	ra,0x0
    80003b4c:	f42080e7          	jalr	-190(ra) # 80003a8a <iput>
}
    80003b50:	60e2                	ld	ra,24(sp)
    80003b52:	6442                	ld	s0,16(sp)
    80003b54:	64a2                	ld	s1,8(sp)
    80003b56:	6105                	addi	sp,sp,32
    80003b58:	8082                	ret

0000000080003b5a <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003b5a:	1141                	addi	sp,sp,-16
    80003b5c:	e422                	sd	s0,8(sp)
    80003b5e:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003b60:	411c                	lw	a5,0(a0)
    80003b62:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003b64:	415c                	lw	a5,4(a0)
    80003b66:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003b68:	04451783          	lh	a5,68(a0)
    80003b6c:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003b70:	04a51783          	lh	a5,74(a0)
    80003b74:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003b78:	04c56783          	lwu	a5,76(a0)
    80003b7c:	e99c                	sd	a5,16(a1)
}
    80003b7e:	6422                	ld	s0,8(sp)
    80003b80:	0141                	addi	sp,sp,16
    80003b82:	8082                	ret

0000000080003b84 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b84:	457c                	lw	a5,76(a0)
    80003b86:	0ed7e963          	bltu	a5,a3,80003c78 <readi+0xf4>
{
    80003b8a:	7159                	addi	sp,sp,-112
    80003b8c:	f486                	sd	ra,104(sp)
    80003b8e:	f0a2                	sd	s0,96(sp)
    80003b90:	eca6                	sd	s1,88(sp)
    80003b92:	e8ca                	sd	s2,80(sp)
    80003b94:	e4ce                	sd	s3,72(sp)
    80003b96:	e0d2                	sd	s4,64(sp)
    80003b98:	fc56                	sd	s5,56(sp)
    80003b9a:	f85a                	sd	s6,48(sp)
    80003b9c:	f45e                	sd	s7,40(sp)
    80003b9e:	f062                	sd	s8,32(sp)
    80003ba0:	ec66                	sd	s9,24(sp)
    80003ba2:	e86a                	sd	s10,16(sp)
    80003ba4:	e46e                	sd	s11,8(sp)
    80003ba6:	1880                	addi	s0,sp,112
    80003ba8:	8b2a                	mv	s6,a0
    80003baa:	8bae                	mv	s7,a1
    80003bac:	8a32                	mv	s4,a2
    80003bae:	84b6                	mv	s1,a3
    80003bb0:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003bb2:	9f35                	addw	a4,a4,a3
    return 0;
    80003bb4:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003bb6:	0ad76063          	bltu	a4,a3,80003c56 <readi+0xd2>
  if(off + n > ip->size)
    80003bba:	00e7f463          	bgeu	a5,a4,80003bc2 <readi+0x3e>
    n = ip->size - off;
    80003bbe:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bc2:	0a0a8963          	beqz	s5,80003c74 <readi+0xf0>
    80003bc6:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bc8:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003bcc:	5c7d                	li	s8,-1
    80003bce:	a82d                	j	80003c08 <readi+0x84>
    80003bd0:	020d1d93          	slli	s11,s10,0x20
    80003bd4:	020ddd93          	srli	s11,s11,0x20
    80003bd8:	05890613          	addi	a2,s2,88
    80003bdc:	86ee                	mv	a3,s11
    80003bde:	963a                	add	a2,a2,a4
    80003be0:	85d2                	mv	a1,s4
    80003be2:	855e                	mv	a0,s7
    80003be4:	fffff097          	auipc	ra,0xfffff
    80003be8:	9a4080e7          	jalr	-1628(ra) # 80002588 <either_copyout>
    80003bec:	05850d63          	beq	a0,s8,80003c46 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003bf0:	854a                	mv	a0,s2
    80003bf2:	fffff097          	auipc	ra,0xfffff
    80003bf6:	5f6080e7          	jalr	1526(ra) # 800031e8 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003bfa:	013d09bb          	addw	s3,s10,s3
    80003bfe:	009d04bb          	addw	s1,s10,s1
    80003c02:	9a6e                	add	s4,s4,s11
    80003c04:	0559f763          	bgeu	s3,s5,80003c52 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003c08:	00a4d59b          	srliw	a1,s1,0xa
    80003c0c:	855a                	mv	a0,s6
    80003c0e:	00000097          	auipc	ra,0x0
    80003c12:	89e080e7          	jalr	-1890(ra) # 800034ac <bmap>
    80003c16:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003c1a:	cd85                	beqz	a1,80003c52 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003c1c:	000b2503          	lw	a0,0(s6)
    80003c20:	fffff097          	auipc	ra,0xfffff
    80003c24:	498080e7          	jalr	1176(ra) # 800030b8 <bread>
    80003c28:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c2a:	3ff4f713          	andi	a4,s1,1023
    80003c2e:	40ec87bb          	subw	a5,s9,a4
    80003c32:	413a86bb          	subw	a3,s5,s3
    80003c36:	8d3e                	mv	s10,a5
    80003c38:	2781                	sext.w	a5,a5
    80003c3a:	0006861b          	sext.w	a2,a3
    80003c3e:	f8f679e3          	bgeu	a2,a5,80003bd0 <readi+0x4c>
    80003c42:	8d36                	mv	s10,a3
    80003c44:	b771                	j	80003bd0 <readi+0x4c>
      brelse(bp);
    80003c46:	854a                	mv	a0,s2
    80003c48:	fffff097          	auipc	ra,0xfffff
    80003c4c:	5a0080e7          	jalr	1440(ra) # 800031e8 <brelse>
      tot = -1;
    80003c50:	59fd                	li	s3,-1
  }
  return tot;
    80003c52:	0009851b          	sext.w	a0,s3
}
    80003c56:	70a6                	ld	ra,104(sp)
    80003c58:	7406                	ld	s0,96(sp)
    80003c5a:	64e6                	ld	s1,88(sp)
    80003c5c:	6946                	ld	s2,80(sp)
    80003c5e:	69a6                	ld	s3,72(sp)
    80003c60:	6a06                	ld	s4,64(sp)
    80003c62:	7ae2                	ld	s5,56(sp)
    80003c64:	7b42                	ld	s6,48(sp)
    80003c66:	7ba2                	ld	s7,40(sp)
    80003c68:	7c02                	ld	s8,32(sp)
    80003c6a:	6ce2                	ld	s9,24(sp)
    80003c6c:	6d42                	ld	s10,16(sp)
    80003c6e:	6da2                	ld	s11,8(sp)
    80003c70:	6165                	addi	sp,sp,112
    80003c72:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c74:	89d6                	mv	s3,s5
    80003c76:	bff1                	j	80003c52 <readi+0xce>
    return 0;
    80003c78:	4501                	li	a0,0
}
    80003c7a:	8082                	ret

0000000080003c7c <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c7c:	457c                	lw	a5,76(a0)
    80003c7e:	10d7e863          	bltu	a5,a3,80003d8e <writei+0x112>
{
    80003c82:	7159                	addi	sp,sp,-112
    80003c84:	f486                	sd	ra,104(sp)
    80003c86:	f0a2                	sd	s0,96(sp)
    80003c88:	eca6                	sd	s1,88(sp)
    80003c8a:	e8ca                	sd	s2,80(sp)
    80003c8c:	e4ce                	sd	s3,72(sp)
    80003c8e:	e0d2                	sd	s4,64(sp)
    80003c90:	fc56                	sd	s5,56(sp)
    80003c92:	f85a                	sd	s6,48(sp)
    80003c94:	f45e                	sd	s7,40(sp)
    80003c96:	f062                	sd	s8,32(sp)
    80003c98:	ec66                	sd	s9,24(sp)
    80003c9a:	e86a                	sd	s10,16(sp)
    80003c9c:	e46e                	sd	s11,8(sp)
    80003c9e:	1880                	addi	s0,sp,112
    80003ca0:	8aaa                	mv	s5,a0
    80003ca2:	8bae                	mv	s7,a1
    80003ca4:	8a32                	mv	s4,a2
    80003ca6:	8936                	mv	s2,a3
    80003ca8:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003caa:	00e687bb          	addw	a5,a3,a4
    80003cae:	0ed7e263          	bltu	a5,a3,80003d92 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003cb2:	00043737          	lui	a4,0x43
    80003cb6:	0ef76063          	bltu	a4,a5,80003d96 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003cba:	0c0b0863          	beqz	s6,80003d8a <writei+0x10e>
    80003cbe:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003cc0:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003cc4:	5c7d                	li	s8,-1
    80003cc6:	a091                	j	80003d0a <writei+0x8e>
    80003cc8:	020d1d93          	slli	s11,s10,0x20
    80003ccc:	020ddd93          	srli	s11,s11,0x20
    80003cd0:	05848513          	addi	a0,s1,88
    80003cd4:	86ee                	mv	a3,s11
    80003cd6:	8652                	mv	a2,s4
    80003cd8:	85de                	mv	a1,s7
    80003cda:	953a                	add	a0,a0,a4
    80003cdc:	fffff097          	auipc	ra,0xfffff
    80003ce0:	902080e7          	jalr	-1790(ra) # 800025de <either_copyin>
    80003ce4:	07850263          	beq	a0,s8,80003d48 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003ce8:	8526                	mv	a0,s1
    80003cea:	00000097          	auipc	ra,0x0
    80003cee:	788080e7          	jalr	1928(ra) # 80004472 <log_write>
    brelse(bp);
    80003cf2:	8526                	mv	a0,s1
    80003cf4:	fffff097          	auipc	ra,0xfffff
    80003cf8:	4f4080e7          	jalr	1268(ra) # 800031e8 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003cfc:	013d09bb          	addw	s3,s10,s3
    80003d00:	012d093b          	addw	s2,s10,s2
    80003d04:	9a6e                	add	s4,s4,s11
    80003d06:	0569f663          	bgeu	s3,s6,80003d52 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003d0a:	00a9559b          	srliw	a1,s2,0xa
    80003d0e:	8556                	mv	a0,s5
    80003d10:	fffff097          	auipc	ra,0xfffff
    80003d14:	79c080e7          	jalr	1948(ra) # 800034ac <bmap>
    80003d18:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003d1c:	c99d                	beqz	a1,80003d52 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003d1e:	000aa503          	lw	a0,0(s5)
    80003d22:	fffff097          	auipc	ra,0xfffff
    80003d26:	396080e7          	jalr	918(ra) # 800030b8 <bread>
    80003d2a:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d2c:	3ff97713          	andi	a4,s2,1023
    80003d30:	40ec87bb          	subw	a5,s9,a4
    80003d34:	413b06bb          	subw	a3,s6,s3
    80003d38:	8d3e                	mv	s10,a5
    80003d3a:	2781                	sext.w	a5,a5
    80003d3c:	0006861b          	sext.w	a2,a3
    80003d40:	f8f674e3          	bgeu	a2,a5,80003cc8 <writei+0x4c>
    80003d44:	8d36                	mv	s10,a3
    80003d46:	b749                	j	80003cc8 <writei+0x4c>
      brelse(bp);
    80003d48:	8526                	mv	a0,s1
    80003d4a:	fffff097          	auipc	ra,0xfffff
    80003d4e:	49e080e7          	jalr	1182(ra) # 800031e8 <brelse>
  }

  if(off > ip->size)
    80003d52:	04caa783          	lw	a5,76(s5)
    80003d56:	0127f463          	bgeu	a5,s2,80003d5e <writei+0xe2>
    ip->size = off;
    80003d5a:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003d5e:	8556                	mv	a0,s5
    80003d60:	00000097          	auipc	ra,0x0
    80003d64:	aa4080e7          	jalr	-1372(ra) # 80003804 <iupdate>

  return tot;
    80003d68:	0009851b          	sext.w	a0,s3
}
    80003d6c:	70a6                	ld	ra,104(sp)
    80003d6e:	7406                	ld	s0,96(sp)
    80003d70:	64e6                	ld	s1,88(sp)
    80003d72:	6946                	ld	s2,80(sp)
    80003d74:	69a6                	ld	s3,72(sp)
    80003d76:	6a06                	ld	s4,64(sp)
    80003d78:	7ae2                	ld	s5,56(sp)
    80003d7a:	7b42                	ld	s6,48(sp)
    80003d7c:	7ba2                	ld	s7,40(sp)
    80003d7e:	7c02                	ld	s8,32(sp)
    80003d80:	6ce2                	ld	s9,24(sp)
    80003d82:	6d42                	ld	s10,16(sp)
    80003d84:	6da2                	ld	s11,8(sp)
    80003d86:	6165                	addi	sp,sp,112
    80003d88:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d8a:	89da                	mv	s3,s6
    80003d8c:	bfc9                	j	80003d5e <writei+0xe2>
    return -1;
    80003d8e:	557d                	li	a0,-1
}
    80003d90:	8082                	ret
    return -1;
    80003d92:	557d                	li	a0,-1
    80003d94:	bfe1                	j	80003d6c <writei+0xf0>
    return -1;
    80003d96:	557d                	li	a0,-1
    80003d98:	bfd1                	j	80003d6c <writei+0xf0>

0000000080003d9a <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003d9a:	1141                	addi	sp,sp,-16
    80003d9c:	e406                	sd	ra,8(sp)
    80003d9e:	e022                	sd	s0,0(sp)
    80003da0:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003da2:	4639                	li	a2,14
    80003da4:	ffffd097          	auipc	ra,0xffffd
    80003da8:	ffe080e7          	jalr	-2(ra) # 80000da2 <strncmp>
}
    80003dac:	60a2                	ld	ra,8(sp)
    80003dae:	6402                	ld	s0,0(sp)
    80003db0:	0141                	addi	sp,sp,16
    80003db2:	8082                	ret

0000000080003db4 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003db4:	7139                	addi	sp,sp,-64
    80003db6:	fc06                	sd	ra,56(sp)
    80003db8:	f822                	sd	s0,48(sp)
    80003dba:	f426                	sd	s1,40(sp)
    80003dbc:	f04a                	sd	s2,32(sp)
    80003dbe:	ec4e                	sd	s3,24(sp)
    80003dc0:	e852                	sd	s4,16(sp)
    80003dc2:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003dc4:	04451703          	lh	a4,68(a0)
    80003dc8:	4785                	li	a5,1
    80003dca:	00f71a63          	bne	a4,a5,80003dde <dirlookup+0x2a>
    80003dce:	892a                	mv	s2,a0
    80003dd0:	89ae                	mv	s3,a1
    80003dd2:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dd4:	457c                	lw	a5,76(a0)
    80003dd6:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003dd8:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dda:	e79d                	bnez	a5,80003e08 <dirlookup+0x54>
    80003ddc:	a8a5                	j	80003e54 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003dde:	00005517          	auipc	a0,0x5
    80003de2:	82250513          	addi	a0,a0,-2014 # 80008600 <syscalls+0x1b0>
    80003de6:	ffffc097          	auipc	ra,0xffffc
    80003dea:	75a080e7          	jalr	1882(ra) # 80000540 <panic>
      panic("dirlookup read");
    80003dee:	00005517          	auipc	a0,0x5
    80003df2:	82a50513          	addi	a0,a0,-2006 # 80008618 <syscalls+0x1c8>
    80003df6:	ffffc097          	auipc	ra,0xffffc
    80003dfa:	74a080e7          	jalr	1866(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003dfe:	24c1                	addiw	s1,s1,16
    80003e00:	04c92783          	lw	a5,76(s2)
    80003e04:	04f4f763          	bgeu	s1,a5,80003e52 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003e08:	4741                	li	a4,16
    80003e0a:	86a6                	mv	a3,s1
    80003e0c:	fc040613          	addi	a2,s0,-64
    80003e10:	4581                	li	a1,0
    80003e12:	854a                	mv	a0,s2
    80003e14:	00000097          	auipc	ra,0x0
    80003e18:	d70080e7          	jalr	-656(ra) # 80003b84 <readi>
    80003e1c:	47c1                	li	a5,16
    80003e1e:	fcf518e3          	bne	a0,a5,80003dee <dirlookup+0x3a>
    if(de.inum == 0)
    80003e22:	fc045783          	lhu	a5,-64(s0)
    80003e26:	dfe1                	beqz	a5,80003dfe <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003e28:	fc240593          	addi	a1,s0,-62
    80003e2c:	854e                	mv	a0,s3
    80003e2e:	00000097          	auipc	ra,0x0
    80003e32:	f6c080e7          	jalr	-148(ra) # 80003d9a <namecmp>
    80003e36:	f561                	bnez	a0,80003dfe <dirlookup+0x4a>
      if(poff)
    80003e38:	000a0463          	beqz	s4,80003e40 <dirlookup+0x8c>
        *poff = off;
    80003e3c:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003e40:	fc045583          	lhu	a1,-64(s0)
    80003e44:	00092503          	lw	a0,0(s2)
    80003e48:	fffff097          	auipc	ra,0xfffff
    80003e4c:	74e080e7          	jalr	1870(ra) # 80003596 <iget>
    80003e50:	a011                	j	80003e54 <dirlookup+0xa0>
  return 0;
    80003e52:	4501                	li	a0,0
}
    80003e54:	70e2                	ld	ra,56(sp)
    80003e56:	7442                	ld	s0,48(sp)
    80003e58:	74a2                	ld	s1,40(sp)
    80003e5a:	7902                	ld	s2,32(sp)
    80003e5c:	69e2                	ld	s3,24(sp)
    80003e5e:	6a42                	ld	s4,16(sp)
    80003e60:	6121                	addi	sp,sp,64
    80003e62:	8082                	ret

0000000080003e64 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003e64:	711d                	addi	sp,sp,-96
    80003e66:	ec86                	sd	ra,88(sp)
    80003e68:	e8a2                	sd	s0,80(sp)
    80003e6a:	e4a6                	sd	s1,72(sp)
    80003e6c:	e0ca                	sd	s2,64(sp)
    80003e6e:	fc4e                	sd	s3,56(sp)
    80003e70:	f852                	sd	s4,48(sp)
    80003e72:	f456                	sd	s5,40(sp)
    80003e74:	f05a                	sd	s6,32(sp)
    80003e76:	ec5e                	sd	s7,24(sp)
    80003e78:	e862                	sd	s8,16(sp)
    80003e7a:	e466                	sd	s9,8(sp)
    80003e7c:	e06a                	sd	s10,0(sp)
    80003e7e:	1080                	addi	s0,sp,96
    80003e80:	84aa                	mv	s1,a0
    80003e82:	8b2e                	mv	s6,a1
    80003e84:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003e86:	00054703          	lbu	a4,0(a0)
    80003e8a:	02f00793          	li	a5,47
    80003e8e:	02f70363          	beq	a4,a5,80003eb4 <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003e92:	ffffe097          	auipc	ra,0xffffe
    80003e96:	b1a080e7          	jalr	-1254(ra) # 800019ac <myproc>
    80003e9a:	15853503          	ld	a0,344(a0)
    80003e9e:	00000097          	auipc	ra,0x0
    80003ea2:	9f4080e7          	jalr	-1548(ra) # 80003892 <idup>
    80003ea6:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003ea8:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003eac:	4cb5                	li	s9,13
  len = path - s;
    80003eae:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003eb0:	4c05                	li	s8,1
    80003eb2:	a87d                	j	80003f70 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80003eb4:	4585                	li	a1,1
    80003eb6:	4505                	li	a0,1
    80003eb8:	fffff097          	auipc	ra,0xfffff
    80003ebc:	6de080e7          	jalr	1758(ra) # 80003596 <iget>
    80003ec0:	8a2a                	mv	s4,a0
    80003ec2:	b7dd                	j	80003ea8 <namex+0x44>
      iunlockput(ip);
    80003ec4:	8552                	mv	a0,s4
    80003ec6:	00000097          	auipc	ra,0x0
    80003eca:	c6c080e7          	jalr	-916(ra) # 80003b32 <iunlockput>
      return 0;
    80003ece:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003ed0:	8552                	mv	a0,s4
    80003ed2:	60e6                	ld	ra,88(sp)
    80003ed4:	6446                	ld	s0,80(sp)
    80003ed6:	64a6                	ld	s1,72(sp)
    80003ed8:	6906                	ld	s2,64(sp)
    80003eda:	79e2                	ld	s3,56(sp)
    80003edc:	7a42                	ld	s4,48(sp)
    80003ede:	7aa2                	ld	s5,40(sp)
    80003ee0:	7b02                	ld	s6,32(sp)
    80003ee2:	6be2                	ld	s7,24(sp)
    80003ee4:	6c42                	ld	s8,16(sp)
    80003ee6:	6ca2                	ld	s9,8(sp)
    80003ee8:	6d02                	ld	s10,0(sp)
    80003eea:	6125                	addi	sp,sp,96
    80003eec:	8082                	ret
      iunlock(ip);
    80003eee:	8552                	mv	a0,s4
    80003ef0:	00000097          	auipc	ra,0x0
    80003ef4:	aa2080e7          	jalr	-1374(ra) # 80003992 <iunlock>
      return ip;
    80003ef8:	bfe1                	j	80003ed0 <namex+0x6c>
      iunlockput(ip);
    80003efa:	8552                	mv	a0,s4
    80003efc:	00000097          	auipc	ra,0x0
    80003f00:	c36080e7          	jalr	-970(ra) # 80003b32 <iunlockput>
      return 0;
    80003f04:	8a4e                	mv	s4,s3
    80003f06:	b7e9                	j	80003ed0 <namex+0x6c>
  len = path - s;
    80003f08:	40998633          	sub	a2,s3,s1
    80003f0c:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80003f10:	09acd863          	bge	s9,s10,80003fa0 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80003f14:	4639                	li	a2,14
    80003f16:	85a6                	mv	a1,s1
    80003f18:	8556                	mv	a0,s5
    80003f1a:	ffffd097          	auipc	ra,0xffffd
    80003f1e:	e14080e7          	jalr	-492(ra) # 80000d2e <memmove>
    80003f22:	84ce                	mv	s1,s3
  while(*path == '/')
    80003f24:	0004c783          	lbu	a5,0(s1)
    80003f28:	01279763          	bne	a5,s2,80003f36 <namex+0xd2>
    path++;
    80003f2c:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f2e:	0004c783          	lbu	a5,0(s1)
    80003f32:	ff278de3          	beq	a5,s2,80003f2c <namex+0xc8>
    ilock(ip);
    80003f36:	8552                	mv	a0,s4
    80003f38:	00000097          	auipc	ra,0x0
    80003f3c:	998080e7          	jalr	-1640(ra) # 800038d0 <ilock>
    if(ip->type != T_DIR){
    80003f40:	044a1783          	lh	a5,68(s4)
    80003f44:	f98790e3          	bne	a5,s8,80003ec4 <namex+0x60>
    if(nameiparent && *path == '\0'){
    80003f48:	000b0563          	beqz	s6,80003f52 <namex+0xee>
    80003f4c:	0004c783          	lbu	a5,0(s1)
    80003f50:	dfd9                	beqz	a5,80003eee <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003f52:	865e                	mv	a2,s7
    80003f54:	85d6                	mv	a1,s5
    80003f56:	8552                	mv	a0,s4
    80003f58:	00000097          	auipc	ra,0x0
    80003f5c:	e5c080e7          	jalr	-420(ra) # 80003db4 <dirlookup>
    80003f60:	89aa                	mv	s3,a0
    80003f62:	dd41                	beqz	a0,80003efa <namex+0x96>
    iunlockput(ip);
    80003f64:	8552                	mv	a0,s4
    80003f66:	00000097          	auipc	ra,0x0
    80003f6a:	bcc080e7          	jalr	-1076(ra) # 80003b32 <iunlockput>
    ip = next;
    80003f6e:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003f70:	0004c783          	lbu	a5,0(s1)
    80003f74:	01279763          	bne	a5,s2,80003f82 <namex+0x11e>
    path++;
    80003f78:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003f7a:	0004c783          	lbu	a5,0(s1)
    80003f7e:	ff278de3          	beq	a5,s2,80003f78 <namex+0x114>
  if(*path == 0)
    80003f82:	cb9d                	beqz	a5,80003fb8 <namex+0x154>
  while(*path != '/' && *path != 0)
    80003f84:	0004c783          	lbu	a5,0(s1)
    80003f88:	89a6                	mv	s3,s1
  len = path - s;
    80003f8a:	8d5e                	mv	s10,s7
    80003f8c:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003f8e:	01278963          	beq	a5,s2,80003fa0 <namex+0x13c>
    80003f92:	dbbd                	beqz	a5,80003f08 <namex+0xa4>
    path++;
    80003f94:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80003f96:	0009c783          	lbu	a5,0(s3)
    80003f9a:	ff279ce3          	bne	a5,s2,80003f92 <namex+0x12e>
    80003f9e:	b7ad                	j	80003f08 <namex+0xa4>
    memmove(name, s, len);
    80003fa0:	2601                	sext.w	a2,a2
    80003fa2:	85a6                	mv	a1,s1
    80003fa4:	8556                	mv	a0,s5
    80003fa6:	ffffd097          	auipc	ra,0xffffd
    80003faa:	d88080e7          	jalr	-632(ra) # 80000d2e <memmove>
    name[len] = 0;
    80003fae:	9d56                	add	s10,s10,s5
    80003fb0:	000d0023          	sb	zero,0(s10)
    80003fb4:	84ce                	mv	s1,s3
    80003fb6:	b7bd                	j	80003f24 <namex+0xc0>
  if(nameiparent){
    80003fb8:	f00b0ce3          	beqz	s6,80003ed0 <namex+0x6c>
    iput(ip);
    80003fbc:	8552                	mv	a0,s4
    80003fbe:	00000097          	auipc	ra,0x0
    80003fc2:	acc080e7          	jalr	-1332(ra) # 80003a8a <iput>
    return 0;
    80003fc6:	4a01                	li	s4,0
    80003fc8:	b721                	j	80003ed0 <namex+0x6c>

0000000080003fca <dirlink>:
{
    80003fca:	7139                	addi	sp,sp,-64
    80003fcc:	fc06                	sd	ra,56(sp)
    80003fce:	f822                	sd	s0,48(sp)
    80003fd0:	f426                	sd	s1,40(sp)
    80003fd2:	f04a                	sd	s2,32(sp)
    80003fd4:	ec4e                	sd	s3,24(sp)
    80003fd6:	e852                	sd	s4,16(sp)
    80003fd8:	0080                	addi	s0,sp,64
    80003fda:	892a                	mv	s2,a0
    80003fdc:	8a2e                	mv	s4,a1
    80003fde:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003fe0:	4601                	li	a2,0
    80003fe2:	00000097          	auipc	ra,0x0
    80003fe6:	dd2080e7          	jalr	-558(ra) # 80003db4 <dirlookup>
    80003fea:	e93d                	bnez	a0,80004060 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003fec:	04c92483          	lw	s1,76(s2)
    80003ff0:	c49d                	beqz	s1,8000401e <dirlink+0x54>
    80003ff2:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ff4:	4741                	li	a4,16
    80003ff6:	86a6                	mv	a3,s1
    80003ff8:	fc040613          	addi	a2,s0,-64
    80003ffc:	4581                	li	a1,0
    80003ffe:	854a                	mv	a0,s2
    80004000:	00000097          	auipc	ra,0x0
    80004004:	b84080e7          	jalr	-1148(ra) # 80003b84 <readi>
    80004008:	47c1                	li	a5,16
    8000400a:	06f51163          	bne	a0,a5,8000406c <dirlink+0xa2>
    if(de.inum == 0)
    8000400e:	fc045783          	lhu	a5,-64(s0)
    80004012:	c791                	beqz	a5,8000401e <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004014:	24c1                	addiw	s1,s1,16
    80004016:	04c92783          	lw	a5,76(s2)
    8000401a:	fcf4ede3          	bltu	s1,a5,80003ff4 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    8000401e:	4639                	li	a2,14
    80004020:	85d2                	mv	a1,s4
    80004022:	fc240513          	addi	a0,s0,-62
    80004026:	ffffd097          	auipc	ra,0xffffd
    8000402a:	db8080e7          	jalr	-584(ra) # 80000dde <strncpy>
  de.inum = inum;
    8000402e:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004032:	4741                	li	a4,16
    80004034:	86a6                	mv	a3,s1
    80004036:	fc040613          	addi	a2,s0,-64
    8000403a:	4581                	li	a1,0
    8000403c:	854a                	mv	a0,s2
    8000403e:	00000097          	auipc	ra,0x0
    80004042:	c3e080e7          	jalr	-962(ra) # 80003c7c <writei>
    80004046:	1541                	addi	a0,a0,-16
    80004048:	00a03533          	snez	a0,a0
    8000404c:	40a00533          	neg	a0,a0
}
    80004050:	70e2                	ld	ra,56(sp)
    80004052:	7442                	ld	s0,48(sp)
    80004054:	74a2                	ld	s1,40(sp)
    80004056:	7902                	ld	s2,32(sp)
    80004058:	69e2                	ld	s3,24(sp)
    8000405a:	6a42                	ld	s4,16(sp)
    8000405c:	6121                	addi	sp,sp,64
    8000405e:	8082                	ret
    iput(ip);
    80004060:	00000097          	auipc	ra,0x0
    80004064:	a2a080e7          	jalr	-1494(ra) # 80003a8a <iput>
    return -1;
    80004068:	557d                	li	a0,-1
    8000406a:	b7dd                	j	80004050 <dirlink+0x86>
      panic("dirlink read");
    8000406c:	00004517          	auipc	a0,0x4
    80004070:	5bc50513          	addi	a0,a0,1468 # 80008628 <syscalls+0x1d8>
    80004074:	ffffc097          	auipc	ra,0xffffc
    80004078:	4cc080e7          	jalr	1228(ra) # 80000540 <panic>

000000008000407c <namei>:

struct inode*
namei(char *path)
{
    8000407c:	1101                	addi	sp,sp,-32
    8000407e:	ec06                	sd	ra,24(sp)
    80004080:	e822                	sd	s0,16(sp)
    80004082:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004084:	fe040613          	addi	a2,s0,-32
    80004088:	4581                	li	a1,0
    8000408a:	00000097          	auipc	ra,0x0
    8000408e:	dda080e7          	jalr	-550(ra) # 80003e64 <namex>
}
    80004092:	60e2                	ld	ra,24(sp)
    80004094:	6442                	ld	s0,16(sp)
    80004096:	6105                	addi	sp,sp,32
    80004098:	8082                	ret

000000008000409a <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000409a:	1141                	addi	sp,sp,-16
    8000409c:	e406                	sd	ra,8(sp)
    8000409e:	e022                	sd	s0,0(sp)
    800040a0:	0800                	addi	s0,sp,16
    800040a2:	862e                	mv	a2,a1
  return namex(path, 1, name);
    800040a4:	4585                	li	a1,1
    800040a6:	00000097          	auipc	ra,0x0
    800040aa:	dbe080e7          	jalr	-578(ra) # 80003e64 <namex>
}
    800040ae:	60a2                	ld	ra,8(sp)
    800040b0:	6402                	ld	s0,0(sp)
    800040b2:	0141                	addi	sp,sp,16
    800040b4:	8082                	ret

00000000800040b6 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    800040b6:	1101                	addi	sp,sp,-32
    800040b8:	ec06                	sd	ra,24(sp)
    800040ba:	e822                	sd	s0,16(sp)
    800040bc:	e426                	sd	s1,8(sp)
    800040be:	e04a                	sd	s2,0(sp)
    800040c0:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800040c2:	0001d917          	auipc	s2,0x1d
    800040c6:	c7e90913          	addi	s2,s2,-898 # 80020d40 <log>
    800040ca:	01892583          	lw	a1,24(s2)
    800040ce:	02892503          	lw	a0,40(s2)
    800040d2:	fffff097          	auipc	ra,0xfffff
    800040d6:	fe6080e7          	jalr	-26(ra) # 800030b8 <bread>
    800040da:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800040dc:	02c92683          	lw	a3,44(s2)
    800040e0:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800040e2:	02d05863          	blez	a3,80004112 <write_head+0x5c>
    800040e6:	0001d797          	auipc	a5,0x1d
    800040ea:	c8a78793          	addi	a5,a5,-886 # 80020d70 <log+0x30>
    800040ee:	05c50713          	addi	a4,a0,92
    800040f2:	36fd                	addiw	a3,a3,-1
    800040f4:	02069613          	slli	a2,a3,0x20
    800040f8:	01e65693          	srli	a3,a2,0x1e
    800040fc:	0001d617          	auipc	a2,0x1d
    80004100:	c7860613          	addi	a2,a2,-904 # 80020d74 <log+0x34>
    80004104:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004106:	4390                	lw	a2,0(a5)
    80004108:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    8000410a:	0791                	addi	a5,a5,4
    8000410c:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    8000410e:	fed79ce3          	bne	a5,a3,80004106 <write_head+0x50>
  }
  bwrite(buf);
    80004112:	8526                	mv	a0,s1
    80004114:	fffff097          	auipc	ra,0xfffff
    80004118:	096080e7          	jalr	150(ra) # 800031aa <bwrite>
  brelse(buf);
    8000411c:	8526                	mv	a0,s1
    8000411e:	fffff097          	auipc	ra,0xfffff
    80004122:	0ca080e7          	jalr	202(ra) # 800031e8 <brelse>
}
    80004126:	60e2                	ld	ra,24(sp)
    80004128:	6442                	ld	s0,16(sp)
    8000412a:	64a2                	ld	s1,8(sp)
    8000412c:	6902                	ld	s2,0(sp)
    8000412e:	6105                	addi	sp,sp,32
    80004130:	8082                	ret

0000000080004132 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004132:	0001d797          	auipc	a5,0x1d
    80004136:	c3a7a783          	lw	a5,-966(a5) # 80020d6c <log+0x2c>
    8000413a:	0af05d63          	blez	a5,800041f4 <install_trans+0xc2>
{
    8000413e:	7139                	addi	sp,sp,-64
    80004140:	fc06                	sd	ra,56(sp)
    80004142:	f822                	sd	s0,48(sp)
    80004144:	f426                	sd	s1,40(sp)
    80004146:	f04a                	sd	s2,32(sp)
    80004148:	ec4e                	sd	s3,24(sp)
    8000414a:	e852                	sd	s4,16(sp)
    8000414c:	e456                	sd	s5,8(sp)
    8000414e:	e05a                	sd	s6,0(sp)
    80004150:	0080                	addi	s0,sp,64
    80004152:	8b2a                	mv	s6,a0
    80004154:	0001da97          	auipc	s5,0x1d
    80004158:	c1ca8a93          	addi	s5,s5,-996 # 80020d70 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000415c:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000415e:	0001d997          	auipc	s3,0x1d
    80004162:	be298993          	addi	s3,s3,-1054 # 80020d40 <log>
    80004166:	a00d                	j	80004188 <install_trans+0x56>
    brelse(lbuf);
    80004168:	854a                	mv	a0,s2
    8000416a:	fffff097          	auipc	ra,0xfffff
    8000416e:	07e080e7          	jalr	126(ra) # 800031e8 <brelse>
    brelse(dbuf);
    80004172:	8526                	mv	a0,s1
    80004174:	fffff097          	auipc	ra,0xfffff
    80004178:	074080e7          	jalr	116(ra) # 800031e8 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000417c:	2a05                	addiw	s4,s4,1
    8000417e:	0a91                	addi	s5,s5,4
    80004180:	02c9a783          	lw	a5,44(s3)
    80004184:	04fa5e63          	bge	s4,a5,800041e0 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004188:	0189a583          	lw	a1,24(s3)
    8000418c:	014585bb          	addw	a1,a1,s4
    80004190:	2585                	addiw	a1,a1,1
    80004192:	0289a503          	lw	a0,40(s3)
    80004196:	fffff097          	auipc	ra,0xfffff
    8000419a:	f22080e7          	jalr	-222(ra) # 800030b8 <bread>
    8000419e:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    800041a0:	000aa583          	lw	a1,0(s5)
    800041a4:	0289a503          	lw	a0,40(s3)
    800041a8:	fffff097          	auipc	ra,0xfffff
    800041ac:	f10080e7          	jalr	-240(ra) # 800030b8 <bread>
    800041b0:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    800041b2:	40000613          	li	a2,1024
    800041b6:	05890593          	addi	a1,s2,88
    800041ba:	05850513          	addi	a0,a0,88
    800041be:	ffffd097          	auipc	ra,0xffffd
    800041c2:	b70080e7          	jalr	-1168(ra) # 80000d2e <memmove>
    bwrite(dbuf);  // write dst to disk
    800041c6:	8526                	mv	a0,s1
    800041c8:	fffff097          	auipc	ra,0xfffff
    800041cc:	fe2080e7          	jalr	-30(ra) # 800031aa <bwrite>
    if(recovering == 0)
    800041d0:	f80b1ce3          	bnez	s6,80004168 <install_trans+0x36>
      bunpin(dbuf);
    800041d4:	8526                	mv	a0,s1
    800041d6:	fffff097          	auipc	ra,0xfffff
    800041da:	0ec080e7          	jalr	236(ra) # 800032c2 <bunpin>
    800041de:	b769                	j	80004168 <install_trans+0x36>
}
    800041e0:	70e2                	ld	ra,56(sp)
    800041e2:	7442                	ld	s0,48(sp)
    800041e4:	74a2                	ld	s1,40(sp)
    800041e6:	7902                	ld	s2,32(sp)
    800041e8:	69e2                	ld	s3,24(sp)
    800041ea:	6a42                	ld	s4,16(sp)
    800041ec:	6aa2                	ld	s5,8(sp)
    800041ee:	6b02                	ld	s6,0(sp)
    800041f0:	6121                	addi	sp,sp,64
    800041f2:	8082                	ret
    800041f4:	8082                	ret

00000000800041f6 <initlog>:
{
    800041f6:	7179                	addi	sp,sp,-48
    800041f8:	f406                	sd	ra,40(sp)
    800041fa:	f022                	sd	s0,32(sp)
    800041fc:	ec26                	sd	s1,24(sp)
    800041fe:	e84a                	sd	s2,16(sp)
    80004200:	e44e                	sd	s3,8(sp)
    80004202:	1800                	addi	s0,sp,48
    80004204:	892a                	mv	s2,a0
    80004206:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004208:	0001d497          	auipc	s1,0x1d
    8000420c:	b3848493          	addi	s1,s1,-1224 # 80020d40 <log>
    80004210:	00004597          	auipc	a1,0x4
    80004214:	42858593          	addi	a1,a1,1064 # 80008638 <syscalls+0x1e8>
    80004218:	8526                	mv	a0,s1
    8000421a:	ffffd097          	auipc	ra,0xffffd
    8000421e:	92c080e7          	jalr	-1748(ra) # 80000b46 <initlock>
  log.start = sb->logstart;
    80004222:	0149a583          	lw	a1,20(s3)
    80004226:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004228:	0109a783          	lw	a5,16(s3)
    8000422c:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000422e:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004232:	854a                	mv	a0,s2
    80004234:	fffff097          	auipc	ra,0xfffff
    80004238:	e84080e7          	jalr	-380(ra) # 800030b8 <bread>
  log.lh.n = lh->n;
    8000423c:	4d34                	lw	a3,88(a0)
    8000423e:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004240:	02d05663          	blez	a3,8000426c <initlog+0x76>
    80004244:	05c50793          	addi	a5,a0,92
    80004248:	0001d717          	auipc	a4,0x1d
    8000424c:	b2870713          	addi	a4,a4,-1240 # 80020d70 <log+0x30>
    80004250:	36fd                	addiw	a3,a3,-1
    80004252:	02069613          	slli	a2,a3,0x20
    80004256:	01e65693          	srli	a3,a2,0x1e
    8000425a:	06050613          	addi	a2,a0,96
    8000425e:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004260:	4390                	lw	a2,0(a5)
    80004262:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004264:	0791                	addi	a5,a5,4
    80004266:	0711                	addi	a4,a4,4
    80004268:	fed79ce3          	bne	a5,a3,80004260 <initlog+0x6a>
  brelse(buf);
    8000426c:	fffff097          	auipc	ra,0xfffff
    80004270:	f7c080e7          	jalr	-132(ra) # 800031e8 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004274:	4505                	li	a0,1
    80004276:	00000097          	auipc	ra,0x0
    8000427a:	ebc080e7          	jalr	-324(ra) # 80004132 <install_trans>
  log.lh.n = 0;
    8000427e:	0001d797          	auipc	a5,0x1d
    80004282:	ae07a723          	sw	zero,-1298(a5) # 80020d6c <log+0x2c>
  write_head(); // clear the log
    80004286:	00000097          	auipc	ra,0x0
    8000428a:	e30080e7          	jalr	-464(ra) # 800040b6 <write_head>
}
    8000428e:	70a2                	ld	ra,40(sp)
    80004290:	7402                	ld	s0,32(sp)
    80004292:	64e2                	ld	s1,24(sp)
    80004294:	6942                	ld	s2,16(sp)
    80004296:	69a2                	ld	s3,8(sp)
    80004298:	6145                	addi	sp,sp,48
    8000429a:	8082                	ret

000000008000429c <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000429c:	1101                	addi	sp,sp,-32
    8000429e:	ec06                	sd	ra,24(sp)
    800042a0:	e822                	sd	s0,16(sp)
    800042a2:	e426                	sd	s1,8(sp)
    800042a4:	e04a                	sd	s2,0(sp)
    800042a6:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    800042a8:	0001d517          	auipc	a0,0x1d
    800042ac:	a9850513          	addi	a0,a0,-1384 # 80020d40 <log>
    800042b0:	ffffd097          	auipc	ra,0xffffd
    800042b4:	926080e7          	jalr	-1754(ra) # 80000bd6 <acquire>
  while(1){
    if(log.committing){
    800042b8:	0001d497          	auipc	s1,0x1d
    800042bc:	a8848493          	addi	s1,s1,-1400 # 80020d40 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800042c0:	4979                	li	s2,30
    800042c2:	a039                	j	800042d0 <begin_op+0x34>
      sleep(&log, &log.lock);
    800042c4:	85a6                	mv	a1,s1
    800042c6:	8526                	mv	a0,s1
    800042c8:	ffffe097          	auipc	ra,0xffffe
    800042cc:	eb8080e7          	jalr	-328(ra) # 80002180 <sleep>
    if(log.committing){
    800042d0:	50dc                	lw	a5,36(s1)
    800042d2:	fbed                	bnez	a5,800042c4 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800042d4:	5098                	lw	a4,32(s1)
    800042d6:	2705                	addiw	a4,a4,1
    800042d8:	0007069b          	sext.w	a3,a4
    800042dc:	0027179b          	slliw	a5,a4,0x2
    800042e0:	9fb9                	addw	a5,a5,a4
    800042e2:	0017979b          	slliw	a5,a5,0x1
    800042e6:	54d8                	lw	a4,44(s1)
    800042e8:	9fb9                	addw	a5,a5,a4
    800042ea:	00f95963          	bge	s2,a5,800042fc <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800042ee:	85a6                	mv	a1,s1
    800042f0:	8526                	mv	a0,s1
    800042f2:	ffffe097          	auipc	ra,0xffffe
    800042f6:	e8e080e7          	jalr	-370(ra) # 80002180 <sleep>
    800042fa:	bfd9                	j	800042d0 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800042fc:	0001d517          	auipc	a0,0x1d
    80004300:	a4450513          	addi	a0,a0,-1468 # 80020d40 <log>
    80004304:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004306:	ffffd097          	auipc	ra,0xffffd
    8000430a:	984080e7          	jalr	-1660(ra) # 80000c8a <release>
      break;
    }
  }
}
    8000430e:	60e2                	ld	ra,24(sp)
    80004310:	6442                	ld	s0,16(sp)
    80004312:	64a2                	ld	s1,8(sp)
    80004314:	6902                	ld	s2,0(sp)
    80004316:	6105                	addi	sp,sp,32
    80004318:	8082                	ret

000000008000431a <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    8000431a:	7139                	addi	sp,sp,-64
    8000431c:	fc06                	sd	ra,56(sp)
    8000431e:	f822                	sd	s0,48(sp)
    80004320:	f426                	sd	s1,40(sp)
    80004322:	f04a                	sd	s2,32(sp)
    80004324:	ec4e                	sd	s3,24(sp)
    80004326:	e852                	sd	s4,16(sp)
    80004328:	e456                	sd	s5,8(sp)
    8000432a:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000432c:	0001d497          	auipc	s1,0x1d
    80004330:	a1448493          	addi	s1,s1,-1516 # 80020d40 <log>
    80004334:	8526                	mv	a0,s1
    80004336:	ffffd097          	auipc	ra,0xffffd
    8000433a:	8a0080e7          	jalr	-1888(ra) # 80000bd6 <acquire>
  log.outstanding -= 1;
    8000433e:	509c                	lw	a5,32(s1)
    80004340:	37fd                	addiw	a5,a5,-1
    80004342:	0007891b          	sext.w	s2,a5
    80004346:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004348:	50dc                	lw	a5,36(s1)
    8000434a:	e7b9                	bnez	a5,80004398 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000434c:	04091e63          	bnez	s2,800043a8 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004350:	0001d497          	auipc	s1,0x1d
    80004354:	9f048493          	addi	s1,s1,-1552 # 80020d40 <log>
    80004358:	4785                	li	a5,1
    8000435a:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000435c:	8526                	mv	a0,s1
    8000435e:	ffffd097          	auipc	ra,0xffffd
    80004362:	92c080e7          	jalr	-1748(ra) # 80000c8a <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004366:	54dc                	lw	a5,44(s1)
    80004368:	06f04763          	bgtz	a5,800043d6 <end_op+0xbc>
    acquire(&log.lock);
    8000436c:	0001d497          	auipc	s1,0x1d
    80004370:	9d448493          	addi	s1,s1,-1580 # 80020d40 <log>
    80004374:	8526                	mv	a0,s1
    80004376:	ffffd097          	auipc	ra,0xffffd
    8000437a:	860080e7          	jalr	-1952(ra) # 80000bd6 <acquire>
    log.committing = 0;
    8000437e:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004382:	8526                	mv	a0,s1
    80004384:	ffffe097          	auipc	ra,0xffffe
    80004388:	e60080e7          	jalr	-416(ra) # 800021e4 <wakeup>
    release(&log.lock);
    8000438c:	8526                	mv	a0,s1
    8000438e:	ffffd097          	auipc	ra,0xffffd
    80004392:	8fc080e7          	jalr	-1796(ra) # 80000c8a <release>
}
    80004396:	a03d                	j	800043c4 <end_op+0xaa>
    panic("log.committing");
    80004398:	00004517          	auipc	a0,0x4
    8000439c:	2a850513          	addi	a0,a0,680 # 80008640 <syscalls+0x1f0>
    800043a0:	ffffc097          	auipc	ra,0xffffc
    800043a4:	1a0080e7          	jalr	416(ra) # 80000540 <panic>
    wakeup(&log);
    800043a8:	0001d497          	auipc	s1,0x1d
    800043ac:	99848493          	addi	s1,s1,-1640 # 80020d40 <log>
    800043b0:	8526                	mv	a0,s1
    800043b2:	ffffe097          	auipc	ra,0xffffe
    800043b6:	e32080e7          	jalr	-462(ra) # 800021e4 <wakeup>
  release(&log.lock);
    800043ba:	8526                	mv	a0,s1
    800043bc:	ffffd097          	auipc	ra,0xffffd
    800043c0:	8ce080e7          	jalr	-1842(ra) # 80000c8a <release>
}
    800043c4:	70e2                	ld	ra,56(sp)
    800043c6:	7442                	ld	s0,48(sp)
    800043c8:	74a2                	ld	s1,40(sp)
    800043ca:	7902                	ld	s2,32(sp)
    800043cc:	69e2                	ld	s3,24(sp)
    800043ce:	6a42                	ld	s4,16(sp)
    800043d0:	6aa2                	ld	s5,8(sp)
    800043d2:	6121                	addi	sp,sp,64
    800043d4:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    800043d6:	0001da97          	auipc	s5,0x1d
    800043da:	99aa8a93          	addi	s5,s5,-1638 # 80020d70 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800043de:	0001da17          	auipc	s4,0x1d
    800043e2:	962a0a13          	addi	s4,s4,-1694 # 80020d40 <log>
    800043e6:	018a2583          	lw	a1,24(s4)
    800043ea:	012585bb          	addw	a1,a1,s2
    800043ee:	2585                	addiw	a1,a1,1
    800043f0:	028a2503          	lw	a0,40(s4)
    800043f4:	fffff097          	auipc	ra,0xfffff
    800043f8:	cc4080e7          	jalr	-828(ra) # 800030b8 <bread>
    800043fc:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800043fe:	000aa583          	lw	a1,0(s5)
    80004402:	028a2503          	lw	a0,40(s4)
    80004406:	fffff097          	auipc	ra,0xfffff
    8000440a:	cb2080e7          	jalr	-846(ra) # 800030b8 <bread>
    8000440e:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004410:	40000613          	li	a2,1024
    80004414:	05850593          	addi	a1,a0,88
    80004418:	05848513          	addi	a0,s1,88
    8000441c:	ffffd097          	auipc	ra,0xffffd
    80004420:	912080e7          	jalr	-1774(ra) # 80000d2e <memmove>
    bwrite(to);  // write the log
    80004424:	8526                	mv	a0,s1
    80004426:	fffff097          	auipc	ra,0xfffff
    8000442a:	d84080e7          	jalr	-636(ra) # 800031aa <bwrite>
    brelse(from);
    8000442e:	854e                	mv	a0,s3
    80004430:	fffff097          	auipc	ra,0xfffff
    80004434:	db8080e7          	jalr	-584(ra) # 800031e8 <brelse>
    brelse(to);
    80004438:	8526                	mv	a0,s1
    8000443a:	fffff097          	auipc	ra,0xfffff
    8000443e:	dae080e7          	jalr	-594(ra) # 800031e8 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004442:	2905                	addiw	s2,s2,1
    80004444:	0a91                	addi	s5,s5,4
    80004446:	02ca2783          	lw	a5,44(s4)
    8000444a:	f8f94ee3          	blt	s2,a5,800043e6 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000444e:	00000097          	auipc	ra,0x0
    80004452:	c68080e7          	jalr	-920(ra) # 800040b6 <write_head>
    install_trans(0); // Now install writes to home locations
    80004456:	4501                	li	a0,0
    80004458:	00000097          	auipc	ra,0x0
    8000445c:	cda080e7          	jalr	-806(ra) # 80004132 <install_trans>
    log.lh.n = 0;
    80004460:	0001d797          	auipc	a5,0x1d
    80004464:	9007a623          	sw	zero,-1780(a5) # 80020d6c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004468:	00000097          	auipc	ra,0x0
    8000446c:	c4e080e7          	jalr	-946(ra) # 800040b6 <write_head>
    80004470:	bdf5                	j	8000436c <end_op+0x52>

0000000080004472 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004472:	1101                	addi	sp,sp,-32
    80004474:	ec06                	sd	ra,24(sp)
    80004476:	e822                	sd	s0,16(sp)
    80004478:	e426                	sd	s1,8(sp)
    8000447a:	e04a                	sd	s2,0(sp)
    8000447c:	1000                	addi	s0,sp,32
    8000447e:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004480:	0001d917          	auipc	s2,0x1d
    80004484:	8c090913          	addi	s2,s2,-1856 # 80020d40 <log>
    80004488:	854a                	mv	a0,s2
    8000448a:	ffffc097          	auipc	ra,0xffffc
    8000448e:	74c080e7          	jalr	1868(ra) # 80000bd6 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004492:	02c92603          	lw	a2,44(s2)
    80004496:	47f5                	li	a5,29
    80004498:	06c7c563          	blt	a5,a2,80004502 <log_write+0x90>
    8000449c:	0001d797          	auipc	a5,0x1d
    800044a0:	8c07a783          	lw	a5,-1856(a5) # 80020d5c <log+0x1c>
    800044a4:	37fd                	addiw	a5,a5,-1
    800044a6:	04f65e63          	bge	a2,a5,80004502 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    800044aa:	0001d797          	auipc	a5,0x1d
    800044ae:	8b67a783          	lw	a5,-1866(a5) # 80020d60 <log+0x20>
    800044b2:	06f05063          	blez	a5,80004512 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    800044b6:	4781                	li	a5,0
    800044b8:	06c05563          	blez	a2,80004522 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    800044bc:	44cc                	lw	a1,12(s1)
    800044be:	0001d717          	auipc	a4,0x1d
    800044c2:	8b270713          	addi	a4,a4,-1870 # 80020d70 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800044c6:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800044c8:	4314                	lw	a3,0(a4)
    800044ca:	04b68c63          	beq	a3,a1,80004522 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800044ce:	2785                	addiw	a5,a5,1
    800044d0:	0711                	addi	a4,a4,4
    800044d2:	fef61be3          	bne	a2,a5,800044c8 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800044d6:	0621                	addi	a2,a2,8
    800044d8:	060a                	slli	a2,a2,0x2
    800044da:	0001d797          	auipc	a5,0x1d
    800044de:	86678793          	addi	a5,a5,-1946 # 80020d40 <log>
    800044e2:	97b2                	add	a5,a5,a2
    800044e4:	44d8                	lw	a4,12(s1)
    800044e6:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800044e8:	8526                	mv	a0,s1
    800044ea:	fffff097          	auipc	ra,0xfffff
    800044ee:	d9c080e7          	jalr	-612(ra) # 80003286 <bpin>
    log.lh.n++;
    800044f2:	0001d717          	auipc	a4,0x1d
    800044f6:	84e70713          	addi	a4,a4,-1970 # 80020d40 <log>
    800044fa:	575c                	lw	a5,44(a4)
    800044fc:	2785                	addiw	a5,a5,1
    800044fe:	d75c                	sw	a5,44(a4)
    80004500:	a82d                	j	8000453a <log_write+0xc8>
    panic("too big a transaction");
    80004502:	00004517          	auipc	a0,0x4
    80004506:	14e50513          	addi	a0,a0,334 # 80008650 <syscalls+0x200>
    8000450a:	ffffc097          	auipc	ra,0xffffc
    8000450e:	036080e7          	jalr	54(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    80004512:	00004517          	auipc	a0,0x4
    80004516:	15650513          	addi	a0,a0,342 # 80008668 <syscalls+0x218>
    8000451a:	ffffc097          	auipc	ra,0xffffc
    8000451e:	026080e7          	jalr	38(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    80004522:	00878693          	addi	a3,a5,8
    80004526:	068a                	slli	a3,a3,0x2
    80004528:	0001d717          	auipc	a4,0x1d
    8000452c:	81870713          	addi	a4,a4,-2024 # 80020d40 <log>
    80004530:	9736                	add	a4,a4,a3
    80004532:	44d4                	lw	a3,12(s1)
    80004534:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004536:	faf609e3          	beq	a2,a5,800044e8 <log_write+0x76>
  }
  release(&log.lock);
    8000453a:	0001d517          	auipc	a0,0x1d
    8000453e:	80650513          	addi	a0,a0,-2042 # 80020d40 <log>
    80004542:	ffffc097          	auipc	ra,0xffffc
    80004546:	748080e7          	jalr	1864(ra) # 80000c8a <release>
}
    8000454a:	60e2                	ld	ra,24(sp)
    8000454c:	6442                	ld	s0,16(sp)
    8000454e:	64a2                	ld	s1,8(sp)
    80004550:	6902                	ld	s2,0(sp)
    80004552:	6105                	addi	sp,sp,32
    80004554:	8082                	ret

0000000080004556 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004556:	1101                	addi	sp,sp,-32
    80004558:	ec06                	sd	ra,24(sp)
    8000455a:	e822                	sd	s0,16(sp)
    8000455c:	e426                	sd	s1,8(sp)
    8000455e:	e04a                	sd	s2,0(sp)
    80004560:	1000                	addi	s0,sp,32
    80004562:	84aa                	mv	s1,a0
    80004564:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004566:	00004597          	auipc	a1,0x4
    8000456a:	12258593          	addi	a1,a1,290 # 80008688 <syscalls+0x238>
    8000456e:	0521                	addi	a0,a0,8
    80004570:	ffffc097          	auipc	ra,0xffffc
    80004574:	5d6080e7          	jalr	1494(ra) # 80000b46 <initlock>
  lk->name = name;
    80004578:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000457c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004580:	0204a423          	sw	zero,40(s1)
}
    80004584:	60e2                	ld	ra,24(sp)
    80004586:	6442                	ld	s0,16(sp)
    80004588:	64a2                	ld	s1,8(sp)
    8000458a:	6902                	ld	s2,0(sp)
    8000458c:	6105                	addi	sp,sp,32
    8000458e:	8082                	ret

0000000080004590 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004590:	1101                	addi	sp,sp,-32
    80004592:	ec06                	sd	ra,24(sp)
    80004594:	e822                	sd	s0,16(sp)
    80004596:	e426                	sd	s1,8(sp)
    80004598:	e04a                	sd	s2,0(sp)
    8000459a:	1000                	addi	s0,sp,32
    8000459c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000459e:	00850913          	addi	s2,a0,8
    800045a2:	854a                	mv	a0,s2
    800045a4:	ffffc097          	auipc	ra,0xffffc
    800045a8:	632080e7          	jalr	1586(ra) # 80000bd6 <acquire>
  while (lk->locked) {
    800045ac:	409c                	lw	a5,0(s1)
    800045ae:	cb89                	beqz	a5,800045c0 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    800045b0:	85ca                	mv	a1,s2
    800045b2:	8526                	mv	a0,s1
    800045b4:	ffffe097          	auipc	ra,0xffffe
    800045b8:	bcc080e7          	jalr	-1076(ra) # 80002180 <sleep>
  while (lk->locked) {
    800045bc:	409c                	lw	a5,0(s1)
    800045be:	fbed                	bnez	a5,800045b0 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800045c0:	4785                	li	a5,1
    800045c2:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800045c4:	ffffd097          	auipc	ra,0xffffd
    800045c8:	3e8080e7          	jalr	1000(ra) # 800019ac <myproc>
    800045cc:	591c                	lw	a5,48(a0)
    800045ce:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800045d0:	854a                	mv	a0,s2
    800045d2:	ffffc097          	auipc	ra,0xffffc
    800045d6:	6b8080e7          	jalr	1720(ra) # 80000c8a <release>
}
    800045da:	60e2                	ld	ra,24(sp)
    800045dc:	6442                	ld	s0,16(sp)
    800045de:	64a2                	ld	s1,8(sp)
    800045e0:	6902                	ld	s2,0(sp)
    800045e2:	6105                	addi	sp,sp,32
    800045e4:	8082                	ret

00000000800045e6 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800045e6:	1101                	addi	sp,sp,-32
    800045e8:	ec06                	sd	ra,24(sp)
    800045ea:	e822                	sd	s0,16(sp)
    800045ec:	e426                	sd	s1,8(sp)
    800045ee:	e04a                	sd	s2,0(sp)
    800045f0:	1000                	addi	s0,sp,32
    800045f2:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800045f4:	00850913          	addi	s2,a0,8
    800045f8:	854a                	mv	a0,s2
    800045fa:	ffffc097          	auipc	ra,0xffffc
    800045fe:	5dc080e7          	jalr	1500(ra) # 80000bd6 <acquire>
  lk->locked = 0;
    80004602:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004606:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    8000460a:	8526                	mv	a0,s1
    8000460c:	ffffe097          	auipc	ra,0xffffe
    80004610:	bd8080e7          	jalr	-1064(ra) # 800021e4 <wakeup>
  release(&lk->lk);
    80004614:	854a                	mv	a0,s2
    80004616:	ffffc097          	auipc	ra,0xffffc
    8000461a:	674080e7          	jalr	1652(ra) # 80000c8a <release>
}
    8000461e:	60e2                	ld	ra,24(sp)
    80004620:	6442                	ld	s0,16(sp)
    80004622:	64a2                	ld	s1,8(sp)
    80004624:	6902                	ld	s2,0(sp)
    80004626:	6105                	addi	sp,sp,32
    80004628:	8082                	ret

000000008000462a <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000462a:	7179                	addi	sp,sp,-48
    8000462c:	f406                	sd	ra,40(sp)
    8000462e:	f022                	sd	s0,32(sp)
    80004630:	ec26                	sd	s1,24(sp)
    80004632:	e84a                	sd	s2,16(sp)
    80004634:	e44e                	sd	s3,8(sp)
    80004636:	1800                	addi	s0,sp,48
    80004638:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000463a:	00850913          	addi	s2,a0,8
    8000463e:	854a                	mv	a0,s2
    80004640:	ffffc097          	auipc	ra,0xffffc
    80004644:	596080e7          	jalr	1430(ra) # 80000bd6 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004648:	409c                	lw	a5,0(s1)
    8000464a:	ef99                	bnez	a5,80004668 <holdingsleep+0x3e>
    8000464c:	4481                	li	s1,0
  release(&lk->lk);
    8000464e:	854a                	mv	a0,s2
    80004650:	ffffc097          	auipc	ra,0xffffc
    80004654:	63a080e7          	jalr	1594(ra) # 80000c8a <release>
  return r;
}
    80004658:	8526                	mv	a0,s1
    8000465a:	70a2                	ld	ra,40(sp)
    8000465c:	7402                	ld	s0,32(sp)
    8000465e:	64e2                	ld	s1,24(sp)
    80004660:	6942                	ld	s2,16(sp)
    80004662:	69a2                	ld	s3,8(sp)
    80004664:	6145                	addi	sp,sp,48
    80004666:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004668:	0284a983          	lw	s3,40(s1)
    8000466c:	ffffd097          	auipc	ra,0xffffd
    80004670:	340080e7          	jalr	832(ra) # 800019ac <myproc>
    80004674:	5904                	lw	s1,48(a0)
    80004676:	413484b3          	sub	s1,s1,s3
    8000467a:	0014b493          	seqz	s1,s1
    8000467e:	bfc1                	j	8000464e <holdingsleep+0x24>

0000000080004680 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004680:	1141                	addi	sp,sp,-16
    80004682:	e406                	sd	ra,8(sp)
    80004684:	e022                	sd	s0,0(sp)
    80004686:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004688:	00004597          	auipc	a1,0x4
    8000468c:	01058593          	addi	a1,a1,16 # 80008698 <syscalls+0x248>
    80004690:	0001c517          	auipc	a0,0x1c
    80004694:	7f850513          	addi	a0,a0,2040 # 80020e88 <ftable>
    80004698:	ffffc097          	auipc	ra,0xffffc
    8000469c:	4ae080e7          	jalr	1198(ra) # 80000b46 <initlock>
}
    800046a0:	60a2                	ld	ra,8(sp)
    800046a2:	6402                	ld	s0,0(sp)
    800046a4:	0141                	addi	sp,sp,16
    800046a6:	8082                	ret

00000000800046a8 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    800046a8:	1101                	addi	sp,sp,-32
    800046aa:	ec06                	sd	ra,24(sp)
    800046ac:	e822                	sd	s0,16(sp)
    800046ae:	e426                	sd	s1,8(sp)
    800046b0:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    800046b2:	0001c517          	auipc	a0,0x1c
    800046b6:	7d650513          	addi	a0,a0,2006 # 80020e88 <ftable>
    800046ba:	ffffc097          	auipc	ra,0xffffc
    800046be:	51c080e7          	jalr	1308(ra) # 80000bd6 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800046c2:	0001c497          	auipc	s1,0x1c
    800046c6:	7de48493          	addi	s1,s1,2014 # 80020ea0 <ftable+0x18>
    800046ca:	0001d717          	auipc	a4,0x1d
    800046ce:	77670713          	addi	a4,a4,1910 # 80021e40 <disk>
    if(f->ref == 0){
    800046d2:	40dc                	lw	a5,4(s1)
    800046d4:	cf99                	beqz	a5,800046f2 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800046d6:	02848493          	addi	s1,s1,40
    800046da:	fee49ce3          	bne	s1,a4,800046d2 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800046de:	0001c517          	auipc	a0,0x1c
    800046e2:	7aa50513          	addi	a0,a0,1962 # 80020e88 <ftable>
    800046e6:	ffffc097          	auipc	ra,0xffffc
    800046ea:	5a4080e7          	jalr	1444(ra) # 80000c8a <release>
  return 0;
    800046ee:	4481                	li	s1,0
    800046f0:	a819                	j	80004706 <filealloc+0x5e>
      f->ref = 1;
    800046f2:	4785                	li	a5,1
    800046f4:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800046f6:	0001c517          	auipc	a0,0x1c
    800046fa:	79250513          	addi	a0,a0,1938 # 80020e88 <ftable>
    800046fe:	ffffc097          	auipc	ra,0xffffc
    80004702:	58c080e7          	jalr	1420(ra) # 80000c8a <release>
}
    80004706:	8526                	mv	a0,s1
    80004708:	60e2                	ld	ra,24(sp)
    8000470a:	6442                	ld	s0,16(sp)
    8000470c:	64a2                	ld	s1,8(sp)
    8000470e:	6105                	addi	sp,sp,32
    80004710:	8082                	ret

0000000080004712 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    80004712:	1101                	addi	sp,sp,-32
    80004714:	ec06                	sd	ra,24(sp)
    80004716:	e822                	sd	s0,16(sp)
    80004718:	e426                	sd	s1,8(sp)
    8000471a:	1000                	addi	s0,sp,32
    8000471c:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    8000471e:	0001c517          	auipc	a0,0x1c
    80004722:	76a50513          	addi	a0,a0,1898 # 80020e88 <ftable>
    80004726:	ffffc097          	auipc	ra,0xffffc
    8000472a:	4b0080e7          	jalr	1200(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    8000472e:	40dc                	lw	a5,4(s1)
    80004730:	02f05263          	blez	a5,80004754 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004734:	2785                	addiw	a5,a5,1
    80004736:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004738:	0001c517          	auipc	a0,0x1c
    8000473c:	75050513          	addi	a0,a0,1872 # 80020e88 <ftable>
    80004740:	ffffc097          	auipc	ra,0xffffc
    80004744:	54a080e7          	jalr	1354(ra) # 80000c8a <release>
  return f;
}
    80004748:	8526                	mv	a0,s1
    8000474a:	60e2                	ld	ra,24(sp)
    8000474c:	6442                	ld	s0,16(sp)
    8000474e:	64a2                	ld	s1,8(sp)
    80004750:	6105                	addi	sp,sp,32
    80004752:	8082                	ret
    panic("filedup");
    80004754:	00004517          	auipc	a0,0x4
    80004758:	f4c50513          	addi	a0,a0,-180 # 800086a0 <syscalls+0x250>
    8000475c:	ffffc097          	auipc	ra,0xffffc
    80004760:	de4080e7          	jalr	-540(ra) # 80000540 <panic>

0000000080004764 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004764:	7139                	addi	sp,sp,-64
    80004766:	fc06                	sd	ra,56(sp)
    80004768:	f822                	sd	s0,48(sp)
    8000476a:	f426                	sd	s1,40(sp)
    8000476c:	f04a                	sd	s2,32(sp)
    8000476e:	ec4e                	sd	s3,24(sp)
    80004770:	e852                	sd	s4,16(sp)
    80004772:	e456                	sd	s5,8(sp)
    80004774:	0080                	addi	s0,sp,64
    80004776:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004778:	0001c517          	auipc	a0,0x1c
    8000477c:	71050513          	addi	a0,a0,1808 # 80020e88 <ftable>
    80004780:	ffffc097          	auipc	ra,0xffffc
    80004784:	456080e7          	jalr	1110(ra) # 80000bd6 <acquire>
  if(f->ref < 1)
    80004788:	40dc                	lw	a5,4(s1)
    8000478a:	06f05163          	blez	a5,800047ec <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000478e:	37fd                	addiw	a5,a5,-1
    80004790:	0007871b          	sext.w	a4,a5
    80004794:	c0dc                	sw	a5,4(s1)
    80004796:	06e04363          	bgtz	a4,800047fc <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000479a:	0004a903          	lw	s2,0(s1)
    8000479e:	0094ca83          	lbu	s5,9(s1)
    800047a2:	0104ba03          	ld	s4,16(s1)
    800047a6:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    800047aa:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    800047ae:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    800047b2:	0001c517          	auipc	a0,0x1c
    800047b6:	6d650513          	addi	a0,a0,1750 # 80020e88 <ftable>
    800047ba:	ffffc097          	auipc	ra,0xffffc
    800047be:	4d0080e7          	jalr	1232(ra) # 80000c8a <release>

  if(ff.type == FD_PIPE){
    800047c2:	4785                	li	a5,1
    800047c4:	04f90d63          	beq	s2,a5,8000481e <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800047c8:	3979                	addiw	s2,s2,-2
    800047ca:	4785                	li	a5,1
    800047cc:	0527e063          	bltu	a5,s2,8000480c <fileclose+0xa8>
    begin_op();
    800047d0:	00000097          	auipc	ra,0x0
    800047d4:	acc080e7          	jalr	-1332(ra) # 8000429c <begin_op>
    iput(ff.ip);
    800047d8:	854e                	mv	a0,s3
    800047da:	fffff097          	auipc	ra,0xfffff
    800047de:	2b0080e7          	jalr	688(ra) # 80003a8a <iput>
    end_op();
    800047e2:	00000097          	auipc	ra,0x0
    800047e6:	b38080e7          	jalr	-1224(ra) # 8000431a <end_op>
    800047ea:	a00d                	j	8000480c <fileclose+0xa8>
    panic("fileclose");
    800047ec:	00004517          	auipc	a0,0x4
    800047f0:	ebc50513          	addi	a0,a0,-324 # 800086a8 <syscalls+0x258>
    800047f4:	ffffc097          	auipc	ra,0xffffc
    800047f8:	d4c080e7          	jalr	-692(ra) # 80000540 <panic>
    release(&ftable.lock);
    800047fc:	0001c517          	auipc	a0,0x1c
    80004800:	68c50513          	addi	a0,a0,1676 # 80020e88 <ftable>
    80004804:	ffffc097          	auipc	ra,0xffffc
    80004808:	486080e7          	jalr	1158(ra) # 80000c8a <release>
  }
}
    8000480c:	70e2                	ld	ra,56(sp)
    8000480e:	7442                	ld	s0,48(sp)
    80004810:	74a2                	ld	s1,40(sp)
    80004812:	7902                	ld	s2,32(sp)
    80004814:	69e2                	ld	s3,24(sp)
    80004816:	6a42                	ld	s4,16(sp)
    80004818:	6aa2                	ld	s5,8(sp)
    8000481a:	6121                	addi	sp,sp,64
    8000481c:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    8000481e:	85d6                	mv	a1,s5
    80004820:	8552                	mv	a0,s4
    80004822:	00000097          	auipc	ra,0x0
    80004826:	34c080e7          	jalr	844(ra) # 80004b6e <pipeclose>
    8000482a:	b7cd                	j	8000480c <fileclose+0xa8>

000000008000482c <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000482c:	715d                	addi	sp,sp,-80
    8000482e:	e486                	sd	ra,72(sp)
    80004830:	e0a2                	sd	s0,64(sp)
    80004832:	fc26                	sd	s1,56(sp)
    80004834:	f84a                	sd	s2,48(sp)
    80004836:	f44e                	sd	s3,40(sp)
    80004838:	0880                	addi	s0,sp,80
    8000483a:	84aa                	mv	s1,a0
    8000483c:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000483e:	ffffd097          	auipc	ra,0xffffd
    80004842:	16e080e7          	jalr	366(ra) # 800019ac <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004846:	409c                	lw	a5,0(s1)
    80004848:	37f9                	addiw	a5,a5,-2
    8000484a:	4705                	li	a4,1
    8000484c:	04f76763          	bltu	a4,a5,8000489a <filestat+0x6e>
    80004850:	892a                	mv	s2,a0
    ilock(f->ip);
    80004852:	6c88                	ld	a0,24(s1)
    80004854:	fffff097          	auipc	ra,0xfffff
    80004858:	07c080e7          	jalr	124(ra) # 800038d0 <ilock>
    stati(f->ip, &st);
    8000485c:	fb840593          	addi	a1,s0,-72
    80004860:	6c88                	ld	a0,24(s1)
    80004862:	fffff097          	auipc	ra,0xfffff
    80004866:	2f8080e7          	jalr	760(ra) # 80003b5a <stati>
    iunlock(f->ip);
    8000486a:	6c88                	ld	a0,24(s1)
    8000486c:	fffff097          	auipc	ra,0xfffff
    80004870:	126080e7          	jalr	294(ra) # 80003992 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004874:	46e1                	li	a3,24
    80004876:	fb840613          	addi	a2,s0,-72
    8000487a:	85ce                	mv	a1,s3
    8000487c:	05893503          	ld	a0,88(s2)
    80004880:	ffffd097          	auipc	ra,0xffffd
    80004884:	dec080e7          	jalr	-532(ra) # 8000166c <copyout>
    80004888:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000488c:	60a6                	ld	ra,72(sp)
    8000488e:	6406                	ld	s0,64(sp)
    80004890:	74e2                	ld	s1,56(sp)
    80004892:	7942                	ld	s2,48(sp)
    80004894:	79a2                	ld	s3,40(sp)
    80004896:	6161                	addi	sp,sp,80
    80004898:	8082                	ret
  return -1;
    8000489a:	557d                	li	a0,-1
    8000489c:	bfc5                	j	8000488c <filestat+0x60>

000000008000489e <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000489e:	7179                	addi	sp,sp,-48
    800048a0:	f406                	sd	ra,40(sp)
    800048a2:	f022                	sd	s0,32(sp)
    800048a4:	ec26                	sd	s1,24(sp)
    800048a6:	e84a                	sd	s2,16(sp)
    800048a8:	e44e                	sd	s3,8(sp)
    800048aa:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    800048ac:	00854783          	lbu	a5,8(a0)
    800048b0:	c3d5                	beqz	a5,80004954 <fileread+0xb6>
    800048b2:	84aa                	mv	s1,a0
    800048b4:	89ae                	mv	s3,a1
    800048b6:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    800048b8:	411c                	lw	a5,0(a0)
    800048ba:	4705                	li	a4,1
    800048bc:	04e78963          	beq	a5,a4,8000490e <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800048c0:	470d                	li	a4,3
    800048c2:	04e78d63          	beq	a5,a4,8000491c <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800048c6:	4709                	li	a4,2
    800048c8:	06e79e63          	bne	a5,a4,80004944 <fileread+0xa6>
    ilock(f->ip);
    800048cc:	6d08                	ld	a0,24(a0)
    800048ce:	fffff097          	auipc	ra,0xfffff
    800048d2:	002080e7          	jalr	2(ra) # 800038d0 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800048d6:	874a                	mv	a4,s2
    800048d8:	5094                	lw	a3,32(s1)
    800048da:	864e                	mv	a2,s3
    800048dc:	4585                	li	a1,1
    800048de:	6c88                	ld	a0,24(s1)
    800048e0:	fffff097          	auipc	ra,0xfffff
    800048e4:	2a4080e7          	jalr	676(ra) # 80003b84 <readi>
    800048e8:	892a                	mv	s2,a0
    800048ea:	00a05563          	blez	a0,800048f4 <fileread+0x56>
      f->off += r;
    800048ee:	509c                	lw	a5,32(s1)
    800048f0:	9fa9                	addw	a5,a5,a0
    800048f2:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800048f4:	6c88                	ld	a0,24(s1)
    800048f6:	fffff097          	auipc	ra,0xfffff
    800048fa:	09c080e7          	jalr	156(ra) # 80003992 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800048fe:	854a                	mv	a0,s2
    80004900:	70a2                	ld	ra,40(sp)
    80004902:	7402                	ld	s0,32(sp)
    80004904:	64e2                	ld	s1,24(sp)
    80004906:	6942                	ld	s2,16(sp)
    80004908:	69a2                	ld	s3,8(sp)
    8000490a:	6145                	addi	sp,sp,48
    8000490c:	8082                	ret
    r = piperead(f->pipe, addr, n);
    8000490e:	6908                	ld	a0,16(a0)
    80004910:	00000097          	auipc	ra,0x0
    80004914:	3c6080e7          	jalr	966(ra) # 80004cd6 <piperead>
    80004918:	892a                	mv	s2,a0
    8000491a:	b7d5                	j	800048fe <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    8000491c:	02451783          	lh	a5,36(a0)
    80004920:	03079693          	slli	a3,a5,0x30
    80004924:	92c1                	srli	a3,a3,0x30
    80004926:	4725                	li	a4,9
    80004928:	02d76863          	bltu	a4,a3,80004958 <fileread+0xba>
    8000492c:	0792                	slli	a5,a5,0x4
    8000492e:	0001c717          	auipc	a4,0x1c
    80004932:	4ba70713          	addi	a4,a4,1210 # 80020de8 <devsw>
    80004936:	97ba                	add	a5,a5,a4
    80004938:	639c                	ld	a5,0(a5)
    8000493a:	c38d                	beqz	a5,8000495c <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    8000493c:	4505                	li	a0,1
    8000493e:	9782                	jalr	a5
    80004940:	892a                	mv	s2,a0
    80004942:	bf75                	j	800048fe <fileread+0x60>
    panic("fileread");
    80004944:	00004517          	auipc	a0,0x4
    80004948:	d7450513          	addi	a0,a0,-652 # 800086b8 <syscalls+0x268>
    8000494c:	ffffc097          	auipc	ra,0xffffc
    80004950:	bf4080e7          	jalr	-1036(ra) # 80000540 <panic>
    return -1;
    80004954:	597d                	li	s2,-1
    80004956:	b765                	j	800048fe <fileread+0x60>
      return -1;
    80004958:	597d                	li	s2,-1
    8000495a:	b755                	j	800048fe <fileread+0x60>
    8000495c:	597d                	li	s2,-1
    8000495e:	b745                	j	800048fe <fileread+0x60>

0000000080004960 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004960:	715d                	addi	sp,sp,-80
    80004962:	e486                	sd	ra,72(sp)
    80004964:	e0a2                	sd	s0,64(sp)
    80004966:	fc26                	sd	s1,56(sp)
    80004968:	f84a                	sd	s2,48(sp)
    8000496a:	f44e                	sd	s3,40(sp)
    8000496c:	f052                	sd	s4,32(sp)
    8000496e:	ec56                	sd	s5,24(sp)
    80004970:	e85a                	sd	s6,16(sp)
    80004972:	e45e                	sd	s7,8(sp)
    80004974:	e062                	sd	s8,0(sp)
    80004976:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004978:	00954783          	lbu	a5,9(a0)
    8000497c:	10078663          	beqz	a5,80004a88 <filewrite+0x128>
    80004980:	892a                	mv	s2,a0
    80004982:	8b2e                	mv	s6,a1
    80004984:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004986:	411c                	lw	a5,0(a0)
    80004988:	4705                	li	a4,1
    8000498a:	02e78263          	beq	a5,a4,800049ae <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000498e:	470d                	li	a4,3
    80004990:	02e78663          	beq	a5,a4,800049bc <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004994:	4709                	li	a4,2
    80004996:	0ee79163          	bne	a5,a4,80004a78 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000499a:	0ac05d63          	blez	a2,80004a54 <filewrite+0xf4>
    int i = 0;
    8000499e:	4981                	li	s3,0
    800049a0:	6b85                	lui	s7,0x1
    800049a2:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    800049a6:	6c05                	lui	s8,0x1
    800049a8:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    800049ac:	a861                	j	80004a44 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    800049ae:	6908                	ld	a0,16(a0)
    800049b0:	00000097          	auipc	ra,0x0
    800049b4:	22e080e7          	jalr	558(ra) # 80004bde <pipewrite>
    800049b8:	8a2a                	mv	s4,a0
    800049ba:	a045                	j	80004a5a <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    800049bc:	02451783          	lh	a5,36(a0)
    800049c0:	03079693          	slli	a3,a5,0x30
    800049c4:	92c1                	srli	a3,a3,0x30
    800049c6:	4725                	li	a4,9
    800049c8:	0cd76263          	bltu	a4,a3,80004a8c <filewrite+0x12c>
    800049cc:	0792                	slli	a5,a5,0x4
    800049ce:	0001c717          	auipc	a4,0x1c
    800049d2:	41a70713          	addi	a4,a4,1050 # 80020de8 <devsw>
    800049d6:	97ba                	add	a5,a5,a4
    800049d8:	679c                	ld	a5,8(a5)
    800049da:	cbdd                	beqz	a5,80004a90 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    800049dc:	4505                	li	a0,1
    800049de:	9782                	jalr	a5
    800049e0:	8a2a                	mv	s4,a0
    800049e2:	a8a5                	j	80004a5a <filewrite+0xfa>
    800049e4:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    800049e8:	00000097          	auipc	ra,0x0
    800049ec:	8b4080e7          	jalr	-1868(ra) # 8000429c <begin_op>
      ilock(f->ip);
    800049f0:	01893503          	ld	a0,24(s2)
    800049f4:	fffff097          	auipc	ra,0xfffff
    800049f8:	edc080e7          	jalr	-292(ra) # 800038d0 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800049fc:	8756                	mv	a4,s5
    800049fe:	02092683          	lw	a3,32(s2)
    80004a02:	01698633          	add	a2,s3,s6
    80004a06:	4585                	li	a1,1
    80004a08:	01893503          	ld	a0,24(s2)
    80004a0c:	fffff097          	auipc	ra,0xfffff
    80004a10:	270080e7          	jalr	624(ra) # 80003c7c <writei>
    80004a14:	84aa                	mv	s1,a0
    80004a16:	00a05763          	blez	a0,80004a24 <filewrite+0xc4>
        f->off += r;
    80004a1a:	02092783          	lw	a5,32(s2)
    80004a1e:	9fa9                	addw	a5,a5,a0
    80004a20:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004a24:	01893503          	ld	a0,24(s2)
    80004a28:	fffff097          	auipc	ra,0xfffff
    80004a2c:	f6a080e7          	jalr	-150(ra) # 80003992 <iunlock>
      end_op();
    80004a30:	00000097          	auipc	ra,0x0
    80004a34:	8ea080e7          	jalr	-1814(ra) # 8000431a <end_op>

      if(r != n1){
    80004a38:	009a9f63          	bne	s5,s1,80004a56 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004a3c:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004a40:	0149db63          	bge	s3,s4,80004a56 <filewrite+0xf6>
      int n1 = n - i;
    80004a44:	413a04bb          	subw	s1,s4,s3
    80004a48:	0004879b          	sext.w	a5,s1
    80004a4c:	f8fbdce3          	bge	s7,a5,800049e4 <filewrite+0x84>
    80004a50:	84e2                	mv	s1,s8
    80004a52:	bf49                	j	800049e4 <filewrite+0x84>
    int i = 0;
    80004a54:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004a56:	013a1f63          	bne	s4,s3,80004a74 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004a5a:	8552                	mv	a0,s4
    80004a5c:	60a6                	ld	ra,72(sp)
    80004a5e:	6406                	ld	s0,64(sp)
    80004a60:	74e2                	ld	s1,56(sp)
    80004a62:	7942                	ld	s2,48(sp)
    80004a64:	79a2                	ld	s3,40(sp)
    80004a66:	7a02                	ld	s4,32(sp)
    80004a68:	6ae2                	ld	s5,24(sp)
    80004a6a:	6b42                	ld	s6,16(sp)
    80004a6c:	6ba2                	ld	s7,8(sp)
    80004a6e:	6c02                	ld	s8,0(sp)
    80004a70:	6161                	addi	sp,sp,80
    80004a72:	8082                	ret
    ret = (i == n ? n : -1);
    80004a74:	5a7d                	li	s4,-1
    80004a76:	b7d5                	j	80004a5a <filewrite+0xfa>
    panic("filewrite");
    80004a78:	00004517          	auipc	a0,0x4
    80004a7c:	c5050513          	addi	a0,a0,-944 # 800086c8 <syscalls+0x278>
    80004a80:	ffffc097          	auipc	ra,0xffffc
    80004a84:	ac0080e7          	jalr	-1344(ra) # 80000540 <panic>
    return -1;
    80004a88:	5a7d                	li	s4,-1
    80004a8a:	bfc1                	j	80004a5a <filewrite+0xfa>
      return -1;
    80004a8c:	5a7d                	li	s4,-1
    80004a8e:	b7f1                	j	80004a5a <filewrite+0xfa>
    80004a90:	5a7d                	li	s4,-1
    80004a92:	b7e1                	j	80004a5a <filewrite+0xfa>

0000000080004a94 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004a94:	7179                	addi	sp,sp,-48
    80004a96:	f406                	sd	ra,40(sp)
    80004a98:	f022                	sd	s0,32(sp)
    80004a9a:	ec26                	sd	s1,24(sp)
    80004a9c:	e84a                	sd	s2,16(sp)
    80004a9e:	e44e                	sd	s3,8(sp)
    80004aa0:	e052                	sd	s4,0(sp)
    80004aa2:	1800                	addi	s0,sp,48
    80004aa4:	84aa                	mv	s1,a0
    80004aa6:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004aa8:	0005b023          	sd	zero,0(a1)
    80004aac:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004ab0:	00000097          	auipc	ra,0x0
    80004ab4:	bf8080e7          	jalr	-1032(ra) # 800046a8 <filealloc>
    80004ab8:	e088                	sd	a0,0(s1)
    80004aba:	c551                	beqz	a0,80004b46 <pipealloc+0xb2>
    80004abc:	00000097          	auipc	ra,0x0
    80004ac0:	bec080e7          	jalr	-1044(ra) # 800046a8 <filealloc>
    80004ac4:	00aa3023          	sd	a0,0(s4)
    80004ac8:	c92d                	beqz	a0,80004b3a <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004aca:	ffffc097          	auipc	ra,0xffffc
    80004ace:	01c080e7          	jalr	28(ra) # 80000ae6 <kalloc>
    80004ad2:	892a                	mv	s2,a0
    80004ad4:	c125                	beqz	a0,80004b34 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004ad6:	4985                	li	s3,1
    80004ad8:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004adc:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004ae0:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004ae4:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004ae8:	00004597          	auipc	a1,0x4
    80004aec:	bf058593          	addi	a1,a1,-1040 # 800086d8 <syscalls+0x288>
    80004af0:	ffffc097          	auipc	ra,0xffffc
    80004af4:	056080e7          	jalr	86(ra) # 80000b46 <initlock>
  (*f0)->type = FD_PIPE;
    80004af8:	609c                	ld	a5,0(s1)
    80004afa:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004afe:	609c                	ld	a5,0(s1)
    80004b00:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004b04:	609c                	ld	a5,0(s1)
    80004b06:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004b0a:	609c                	ld	a5,0(s1)
    80004b0c:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004b10:	000a3783          	ld	a5,0(s4)
    80004b14:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004b18:	000a3783          	ld	a5,0(s4)
    80004b1c:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004b20:	000a3783          	ld	a5,0(s4)
    80004b24:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004b28:	000a3783          	ld	a5,0(s4)
    80004b2c:	0127b823          	sd	s2,16(a5)
  return 0;
    80004b30:	4501                	li	a0,0
    80004b32:	a025                	j	80004b5a <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004b34:	6088                	ld	a0,0(s1)
    80004b36:	e501                	bnez	a0,80004b3e <pipealloc+0xaa>
    80004b38:	a039                	j	80004b46 <pipealloc+0xb2>
    80004b3a:	6088                	ld	a0,0(s1)
    80004b3c:	c51d                	beqz	a0,80004b6a <pipealloc+0xd6>
    fileclose(*f0);
    80004b3e:	00000097          	auipc	ra,0x0
    80004b42:	c26080e7          	jalr	-986(ra) # 80004764 <fileclose>
  if(*f1)
    80004b46:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004b4a:	557d                	li	a0,-1
  if(*f1)
    80004b4c:	c799                	beqz	a5,80004b5a <pipealloc+0xc6>
    fileclose(*f1);
    80004b4e:	853e                	mv	a0,a5
    80004b50:	00000097          	auipc	ra,0x0
    80004b54:	c14080e7          	jalr	-1004(ra) # 80004764 <fileclose>
  return -1;
    80004b58:	557d                	li	a0,-1
}
    80004b5a:	70a2                	ld	ra,40(sp)
    80004b5c:	7402                	ld	s0,32(sp)
    80004b5e:	64e2                	ld	s1,24(sp)
    80004b60:	6942                	ld	s2,16(sp)
    80004b62:	69a2                	ld	s3,8(sp)
    80004b64:	6a02                	ld	s4,0(sp)
    80004b66:	6145                	addi	sp,sp,48
    80004b68:	8082                	ret
  return -1;
    80004b6a:	557d                	li	a0,-1
    80004b6c:	b7fd                	j	80004b5a <pipealloc+0xc6>

0000000080004b6e <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004b6e:	1101                	addi	sp,sp,-32
    80004b70:	ec06                	sd	ra,24(sp)
    80004b72:	e822                	sd	s0,16(sp)
    80004b74:	e426                	sd	s1,8(sp)
    80004b76:	e04a                	sd	s2,0(sp)
    80004b78:	1000                	addi	s0,sp,32
    80004b7a:	84aa                	mv	s1,a0
    80004b7c:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004b7e:	ffffc097          	auipc	ra,0xffffc
    80004b82:	058080e7          	jalr	88(ra) # 80000bd6 <acquire>
  if(writable){
    80004b86:	02090d63          	beqz	s2,80004bc0 <pipeclose+0x52>
    pi->writeopen = 0;
    80004b8a:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004b8e:	21848513          	addi	a0,s1,536
    80004b92:	ffffd097          	auipc	ra,0xffffd
    80004b96:	652080e7          	jalr	1618(ra) # 800021e4 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004b9a:	2204b783          	ld	a5,544(s1)
    80004b9e:	eb95                	bnez	a5,80004bd2 <pipeclose+0x64>
    release(&pi->lock);
    80004ba0:	8526                	mv	a0,s1
    80004ba2:	ffffc097          	auipc	ra,0xffffc
    80004ba6:	0e8080e7          	jalr	232(ra) # 80000c8a <release>
    kfree((char*)pi);
    80004baa:	8526                	mv	a0,s1
    80004bac:	ffffc097          	auipc	ra,0xffffc
    80004bb0:	e3c080e7          	jalr	-452(ra) # 800009e8 <kfree>
  } else
    release(&pi->lock);
}
    80004bb4:	60e2                	ld	ra,24(sp)
    80004bb6:	6442                	ld	s0,16(sp)
    80004bb8:	64a2                	ld	s1,8(sp)
    80004bba:	6902                	ld	s2,0(sp)
    80004bbc:	6105                	addi	sp,sp,32
    80004bbe:	8082                	ret
    pi->readopen = 0;
    80004bc0:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004bc4:	21c48513          	addi	a0,s1,540
    80004bc8:	ffffd097          	auipc	ra,0xffffd
    80004bcc:	61c080e7          	jalr	1564(ra) # 800021e4 <wakeup>
    80004bd0:	b7e9                	j	80004b9a <pipeclose+0x2c>
    release(&pi->lock);
    80004bd2:	8526                	mv	a0,s1
    80004bd4:	ffffc097          	auipc	ra,0xffffc
    80004bd8:	0b6080e7          	jalr	182(ra) # 80000c8a <release>
}
    80004bdc:	bfe1                	j	80004bb4 <pipeclose+0x46>

0000000080004bde <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004bde:	711d                	addi	sp,sp,-96
    80004be0:	ec86                	sd	ra,88(sp)
    80004be2:	e8a2                	sd	s0,80(sp)
    80004be4:	e4a6                	sd	s1,72(sp)
    80004be6:	e0ca                	sd	s2,64(sp)
    80004be8:	fc4e                	sd	s3,56(sp)
    80004bea:	f852                	sd	s4,48(sp)
    80004bec:	f456                	sd	s5,40(sp)
    80004bee:	f05a                	sd	s6,32(sp)
    80004bf0:	ec5e                	sd	s7,24(sp)
    80004bf2:	e862                	sd	s8,16(sp)
    80004bf4:	1080                	addi	s0,sp,96
    80004bf6:	84aa                	mv	s1,a0
    80004bf8:	8aae                	mv	s5,a1
    80004bfa:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004bfc:	ffffd097          	auipc	ra,0xffffd
    80004c00:	db0080e7          	jalr	-592(ra) # 800019ac <myproc>
    80004c04:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004c06:	8526                	mv	a0,s1
    80004c08:	ffffc097          	auipc	ra,0xffffc
    80004c0c:	fce080e7          	jalr	-50(ra) # 80000bd6 <acquire>
  while(i < n){
    80004c10:	0b405663          	blez	s4,80004cbc <pipewrite+0xde>
  int i = 0;
    80004c14:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c16:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004c18:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004c1c:	21c48b93          	addi	s7,s1,540
    80004c20:	a089                	j	80004c62 <pipewrite+0x84>
      release(&pi->lock);
    80004c22:	8526                	mv	a0,s1
    80004c24:	ffffc097          	auipc	ra,0xffffc
    80004c28:	066080e7          	jalr	102(ra) # 80000c8a <release>
      return -1;
    80004c2c:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004c2e:	854a                	mv	a0,s2
    80004c30:	60e6                	ld	ra,88(sp)
    80004c32:	6446                	ld	s0,80(sp)
    80004c34:	64a6                	ld	s1,72(sp)
    80004c36:	6906                	ld	s2,64(sp)
    80004c38:	79e2                	ld	s3,56(sp)
    80004c3a:	7a42                	ld	s4,48(sp)
    80004c3c:	7aa2                	ld	s5,40(sp)
    80004c3e:	7b02                	ld	s6,32(sp)
    80004c40:	6be2                	ld	s7,24(sp)
    80004c42:	6c42                	ld	s8,16(sp)
    80004c44:	6125                	addi	sp,sp,96
    80004c46:	8082                	ret
      wakeup(&pi->nread);
    80004c48:	8562                	mv	a0,s8
    80004c4a:	ffffd097          	auipc	ra,0xffffd
    80004c4e:	59a080e7          	jalr	1434(ra) # 800021e4 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004c52:	85a6                	mv	a1,s1
    80004c54:	855e                	mv	a0,s7
    80004c56:	ffffd097          	auipc	ra,0xffffd
    80004c5a:	52a080e7          	jalr	1322(ra) # 80002180 <sleep>
  while(i < n){
    80004c5e:	07495063          	bge	s2,s4,80004cbe <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004c62:	2204a783          	lw	a5,544(s1)
    80004c66:	dfd5                	beqz	a5,80004c22 <pipewrite+0x44>
    80004c68:	854e                	mv	a0,s3
    80004c6a:	ffffd097          	auipc	ra,0xffffd
    80004c6e:	7be080e7          	jalr	1982(ra) # 80002428 <killed>
    80004c72:	f945                	bnez	a0,80004c22 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004c74:	2184a783          	lw	a5,536(s1)
    80004c78:	21c4a703          	lw	a4,540(s1)
    80004c7c:	2007879b          	addiw	a5,a5,512
    80004c80:	fcf704e3          	beq	a4,a5,80004c48 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004c84:	4685                	li	a3,1
    80004c86:	01590633          	add	a2,s2,s5
    80004c8a:	faf40593          	addi	a1,s0,-81
    80004c8e:	0589b503          	ld	a0,88(s3)
    80004c92:	ffffd097          	auipc	ra,0xffffd
    80004c96:	a66080e7          	jalr	-1434(ra) # 800016f8 <copyin>
    80004c9a:	03650263          	beq	a0,s6,80004cbe <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004c9e:	21c4a783          	lw	a5,540(s1)
    80004ca2:	0017871b          	addiw	a4,a5,1
    80004ca6:	20e4ae23          	sw	a4,540(s1)
    80004caa:	1ff7f793          	andi	a5,a5,511
    80004cae:	97a6                	add	a5,a5,s1
    80004cb0:	faf44703          	lbu	a4,-81(s0)
    80004cb4:	00e78c23          	sb	a4,24(a5)
      i++;
    80004cb8:	2905                	addiw	s2,s2,1
    80004cba:	b755                	j	80004c5e <pipewrite+0x80>
  int i = 0;
    80004cbc:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004cbe:	21848513          	addi	a0,s1,536
    80004cc2:	ffffd097          	auipc	ra,0xffffd
    80004cc6:	522080e7          	jalr	1314(ra) # 800021e4 <wakeup>
  release(&pi->lock);
    80004cca:	8526                	mv	a0,s1
    80004ccc:	ffffc097          	auipc	ra,0xffffc
    80004cd0:	fbe080e7          	jalr	-66(ra) # 80000c8a <release>
  return i;
    80004cd4:	bfa9                	j	80004c2e <pipewrite+0x50>

0000000080004cd6 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004cd6:	715d                	addi	sp,sp,-80
    80004cd8:	e486                	sd	ra,72(sp)
    80004cda:	e0a2                	sd	s0,64(sp)
    80004cdc:	fc26                	sd	s1,56(sp)
    80004cde:	f84a                	sd	s2,48(sp)
    80004ce0:	f44e                	sd	s3,40(sp)
    80004ce2:	f052                	sd	s4,32(sp)
    80004ce4:	ec56                	sd	s5,24(sp)
    80004ce6:	e85a                	sd	s6,16(sp)
    80004ce8:	0880                	addi	s0,sp,80
    80004cea:	84aa                	mv	s1,a0
    80004cec:	892e                	mv	s2,a1
    80004cee:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004cf0:	ffffd097          	auipc	ra,0xffffd
    80004cf4:	cbc080e7          	jalr	-836(ra) # 800019ac <myproc>
    80004cf8:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004cfa:	8526                	mv	a0,s1
    80004cfc:	ffffc097          	auipc	ra,0xffffc
    80004d00:	eda080e7          	jalr	-294(ra) # 80000bd6 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d04:	2184a703          	lw	a4,536(s1)
    80004d08:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d0c:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d10:	02f71763          	bne	a4,a5,80004d3e <piperead+0x68>
    80004d14:	2244a783          	lw	a5,548(s1)
    80004d18:	c39d                	beqz	a5,80004d3e <piperead+0x68>
    if(killed(pr)){
    80004d1a:	8552                	mv	a0,s4
    80004d1c:	ffffd097          	auipc	ra,0xffffd
    80004d20:	70c080e7          	jalr	1804(ra) # 80002428 <killed>
    80004d24:	e949                	bnez	a0,80004db6 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004d26:	85a6                	mv	a1,s1
    80004d28:	854e                	mv	a0,s3
    80004d2a:	ffffd097          	auipc	ra,0xffffd
    80004d2e:	456080e7          	jalr	1110(ra) # 80002180 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004d32:	2184a703          	lw	a4,536(s1)
    80004d36:	21c4a783          	lw	a5,540(s1)
    80004d3a:	fcf70de3          	beq	a4,a5,80004d14 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d3e:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d40:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d42:	05505463          	blez	s5,80004d8a <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004d46:	2184a783          	lw	a5,536(s1)
    80004d4a:	21c4a703          	lw	a4,540(s1)
    80004d4e:	02f70e63          	beq	a4,a5,80004d8a <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004d52:	0017871b          	addiw	a4,a5,1
    80004d56:	20e4ac23          	sw	a4,536(s1)
    80004d5a:	1ff7f793          	andi	a5,a5,511
    80004d5e:	97a6                	add	a5,a5,s1
    80004d60:	0187c783          	lbu	a5,24(a5)
    80004d64:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004d68:	4685                	li	a3,1
    80004d6a:	fbf40613          	addi	a2,s0,-65
    80004d6e:	85ca                	mv	a1,s2
    80004d70:	058a3503          	ld	a0,88(s4)
    80004d74:	ffffd097          	auipc	ra,0xffffd
    80004d78:	8f8080e7          	jalr	-1800(ra) # 8000166c <copyout>
    80004d7c:	01650763          	beq	a0,s6,80004d8a <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004d80:	2985                	addiw	s3,s3,1
    80004d82:	0905                	addi	s2,s2,1
    80004d84:	fd3a91e3          	bne	s5,s3,80004d46 <piperead+0x70>
    80004d88:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004d8a:	21c48513          	addi	a0,s1,540
    80004d8e:	ffffd097          	auipc	ra,0xffffd
    80004d92:	456080e7          	jalr	1110(ra) # 800021e4 <wakeup>
  release(&pi->lock);
    80004d96:	8526                	mv	a0,s1
    80004d98:	ffffc097          	auipc	ra,0xffffc
    80004d9c:	ef2080e7          	jalr	-270(ra) # 80000c8a <release>
  return i;
}
    80004da0:	854e                	mv	a0,s3
    80004da2:	60a6                	ld	ra,72(sp)
    80004da4:	6406                	ld	s0,64(sp)
    80004da6:	74e2                	ld	s1,56(sp)
    80004da8:	7942                	ld	s2,48(sp)
    80004daa:	79a2                	ld	s3,40(sp)
    80004dac:	7a02                	ld	s4,32(sp)
    80004dae:	6ae2                	ld	s5,24(sp)
    80004db0:	6b42                	ld	s6,16(sp)
    80004db2:	6161                	addi	sp,sp,80
    80004db4:	8082                	ret
      release(&pi->lock);
    80004db6:	8526                	mv	a0,s1
    80004db8:	ffffc097          	auipc	ra,0xffffc
    80004dbc:	ed2080e7          	jalr	-302(ra) # 80000c8a <release>
      return -1;
    80004dc0:	59fd                	li	s3,-1
    80004dc2:	bff9                	j	80004da0 <piperead+0xca>

0000000080004dc4 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004dc4:	1141                	addi	sp,sp,-16
    80004dc6:	e422                	sd	s0,8(sp)
    80004dc8:	0800                	addi	s0,sp,16
    80004dca:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004dcc:	8905                	andi	a0,a0,1
    80004dce:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80004dd0:	8b89                	andi	a5,a5,2
    80004dd2:	c399                	beqz	a5,80004dd8 <flags2perm+0x14>
      perm |= PTE_W;
    80004dd4:	00456513          	ori	a0,a0,4
    return perm;
}
    80004dd8:	6422                	ld	s0,8(sp)
    80004dda:	0141                	addi	sp,sp,16
    80004ddc:	8082                	ret

0000000080004dde <exec>:

int
exec(char *path, char **argv)
{
    80004dde:	de010113          	addi	sp,sp,-544
    80004de2:	20113c23          	sd	ra,536(sp)
    80004de6:	20813823          	sd	s0,528(sp)
    80004dea:	20913423          	sd	s1,520(sp)
    80004dee:	21213023          	sd	s2,512(sp)
    80004df2:	ffce                	sd	s3,504(sp)
    80004df4:	fbd2                	sd	s4,496(sp)
    80004df6:	f7d6                	sd	s5,488(sp)
    80004df8:	f3da                	sd	s6,480(sp)
    80004dfa:	efde                	sd	s7,472(sp)
    80004dfc:	ebe2                	sd	s8,464(sp)
    80004dfe:	e7e6                	sd	s9,456(sp)
    80004e00:	e3ea                	sd	s10,448(sp)
    80004e02:	ff6e                	sd	s11,440(sp)
    80004e04:	1400                	addi	s0,sp,544
    80004e06:	892a                	mv	s2,a0
    80004e08:	dea43423          	sd	a0,-536(s0)
    80004e0c:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004e10:	ffffd097          	auipc	ra,0xffffd
    80004e14:	b9c080e7          	jalr	-1124(ra) # 800019ac <myproc>
    80004e18:	84aa                	mv	s1,a0

  begin_op();
    80004e1a:	fffff097          	auipc	ra,0xfffff
    80004e1e:	482080e7          	jalr	1154(ra) # 8000429c <begin_op>

  if((ip = namei(path)) == 0){
    80004e22:	854a                	mv	a0,s2
    80004e24:	fffff097          	auipc	ra,0xfffff
    80004e28:	258080e7          	jalr	600(ra) # 8000407c <namei>
    80004e2c:	c93d                	beqz	a0,80004ea2 <exec+0xc4>
    80004e2e:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004e30:	fffff097          	auipc	ra,0xfffff
    80004e34:	aa0080e7          	jalr	-1376(ra) # 800038d0 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004e38:	04000713          	li	a4,64
    80004e3c:	4681                	li	a3,0
    80004e3e:	e5040613          	addi	a2,s0,-432
    80004e42:	4581                	li	a1,0
    80004e44:	8556                	mv	a0,s5
    80004e46:	fffff097          	auipc	ra,0xfffff
    80004e4a:	d3e080e7          	jalr	-706(ra) # 80003b84 <readi>
    80004e4e:	04000793          	li	a5,64
    80004e52:	00f51a63          	bne	a0,a5,80004e66 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004e56:	e5042703          	lw	a4,-432(s0)
    80004e5a:	464c47b7          	lui	a5,0x464c4
    80004e5e:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004e62:	04f70663          	beq	a4,a5,80004eae <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004e66:	8556                	mv	a0,s5
    80004e68:	fffff097          	auipc	ra,0xfffff
    80004e6c:	cca080e7          	jalr	-822(ra) # 80003b32 <iunlockput>
    end_op();
    80004e70:	fffff097          	auipc	ra,0xfffff
    80004e74:	4aa080e7          	jalr	1194(ra) # 8000431a <end_op>
  }
  return -1;
    80004e78:	557d                	li	a0,-1
}
    80004e7a:	21813083          	ld	ra,536(sp)
    80004e7e:	21013403          	ld	s0,528(sp)
    80004e82:	20813483          	ld	s1,520(sp)
    80004e86:	20013903          	ld	s2,512(sp)
    80004e8a:	79fe                	ld	s3,504(sp)
    80004e8c:	7a5e                	ld	s4,496(sp)
    80004e8e:	7abe                	ld	s5,488(sp)
    80004e90:	7b1e                	ld	s6,480(sp)
    80004e92:	6bfe                	ld	s7,472(sp)
    80004e94:	6c5e                	ld	s8,464(sp)
    80004e96:	6cbe                	ld	s9,456(sp)
    80004e98:	6d1e                	ld	s10,448(sp)
    80004e9a:	7dfa                	ld	s11,440(sp)
    80004e9c:	22010113          	addi	sp,sp,544
    80004ea0:	8082                	ret
    end_op();
    80004ea2:	fffff097          	auipc	ra,0xfffff
    80004ea6:	478080e7          	jalr	1144(ra) # 8000431a <end_op>
    return -1;
    80004eaa:	557d                	li	a0,-1
    80004eac:	b7f9                	j	80004e7a <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004eae:	8526                	mv	a0,s1
    80004eb0:	ffffd097          	auipc	ra,0xffffd
    80004eb4:	bc0080e7          	jalr	-1088(ra) # 80001a70 <proc_pagetable>
    80004eb8:	8b2a                	mv	s6,a0
    80004eba:	d555                	beqz	a0,80004e66 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ebc:	e7042783          	lw	a5,-400(s0)
    80004ec0:	e8845703          	lhu	a4,-376(s0)
    80004ec4:	c735                	beqz	a4,80004f30 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004ec6:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004ec8:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004ecc:	6a05                	lui	s4,0x1
    80004ece:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004ed2:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004ed6:	6d85                	lui	s11,0x1
    80004ed8:	7d7d                	lui	s10,0xfffff
    80004eda:	ac3d                	j	80005118 <exec+0x33a>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004edc:	00004517          	auipc	a0,0x4
    80004ee0:	80450513          	addi	a0,a0,-2044 # 800086e0 <syscalls+0x290>
    80004ee4:	ffffb097          	auipc	ra,0xffffb
    80004ee8:	65c080e7          	jalr	1628(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004eec:	874a                	mv	a4,s2
    80004eee:	009c86bb          	addw	a3,s9,s1
    80004ef2:	4581                	li	a1,0
    80004ef4:	8556                	mv	a0,s5
    80004ef6:	fffff097          	auipc	ra,0xfffff
    80004efa:	c8e080e7          	jalr	-882(ra) # 80003b84 <readi>
    80004efe:	2501                	sext.w	a0,a0
    80004f00:	1aa91963          	bne	s2,a0,800050b2 <exec+0x2d4>
  for(i = 0; i < sz; i += PGSIZE){
    80004f04:	009d84bb          	addw	s1,s11,s1
    80004f08:	013d09bb          	addw	s3,s10,s3
    80004f0c:	1f74f663          	bgeu	s1,s7,800050f8 <exec+0x31a>
    pa = walkaddr(pagetable, va + i);
    80004f10:	02049593          	slli	a1,s1,0x20
    80004f14:	9181                	srli	a1,a1,0x20
    80004f16:	95e2                	add	a1,a1,s8
    80004f18:	855a                	mv	a0,s6
    80004f1a:	ffffc097          	auipc	ra,0xffffc
    80004f1e:	142080e7          	jalr	322(ra) # 8000105c <walkaddr>
    80004f22:	862a                	mv	a2,a0
    if(pa == 0)
    80004f24:	dd45                	beqz	a0,80004edc <exec+0xfe>
      n = PGSIZE;
    80004f26:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004f28:	fd49f2e3          	bgeu	s3,s4,80004eec <exec+0x10e>
      n = sz - i;
    80004f2c:	894e                	mv	s2,s3
    80004f2e:	bf7d                	j	80004eec <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004f30:	4901                	li	s2,0
  iunlockput(ip);
    80004f32:	8556                	mv	a0,s5
    80004f34:	fffff097          	auipc	ra,0xfffff
    80004f38:	bfe080e7          	jalr	-1026(ra) # 80003b32 <iunlockput>
  end_op();
    80004f3c:	fffff097          	auipc	ra,0xfffff
    80004f40:	3de080e7          	jalr	990(ra) # 8000431a <end_op>
  p = myproc();
    80004f44:	ffffd097          	auipc	ra,0xffffd
    80004f48:	a68080e7          	jalr	-1432(ra) # 800019ac <myproc>
    80004f4c:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004f4e:	05053d03          	ld	s10,80(a0)
  sz = PGROUNDUP(sz);
    80004f52:	6785                	lui	a5,0x1
    80004f54:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80004f56:	97ca                	add	a5,a5,s2
    80004f58:	777d                	lui	a4,0xfffff
    80004f5a:	8ff9                	and	a5,a5,a4
    80004f5c:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004f60:	4691                	li	a3,4
    80004f62:	6609                	lui	a2,0x2
    80004f64:	963e                	add	a2,a2,a5
    80004f66:	85be                	mv	a1,a5
    80004f68:	855a                	mv	a0,s6
    80004f6a:	ffffc097          	auipc	ra,0xffffc
    80004f6e:	4a6080e7          	jalr	1190(ra) # 80001410 <uvmalloc>
    80004f72:	8c2a                	mv	s8,a0
  ip = 0;
    80004f74:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004f76:	12050e63          	beqz	a0,800050b2 <exec+0x2d4>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004f7a:	75f9                	lui	a1,0xffffe
    80004f7c:	95aa                	add	a1,a1,a0
    80004f7e:	855a                	mv	a0,s6
    80004f80:	ffffc097          	auipc	ra,0xffffc
    80004f84:	6ba080e7          	jalr	1722(ra) # 8000163a <uvmclear>
  stackbase = sp - PGSIZE;
    80004f88:	7afd                	lui	s5,0xfffff
    80004f8a:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004f8c:	df043783          	ld	a5,-528(s0)
    80004f90:	6388                	ld	a0,0(a5)
    80004f92:	c925                	beqz	a0,80005002 <exec+0x224>
    80004f94:	e9040993          	addi	s3,s0,-368
    80004f98:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004f9c:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004f9e:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004fa0:	ffffc097          	auipc	ra,0xffffc
    80004fa4:	eae080e7          	jalr	-338(ra) # 80000e4e <strlen>
    80004fa8:	0015079b          	addiw	a5,a0,1
    80004fac:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004fb0:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80004fb4:	13596663          	bltu	s2,s5,800050e0 <exec+0x302>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004fb8:	df043d83          	ld	s11,-528(s0)
    80004fbc:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004fc0:	8552                	mv	a0,s4
    80004fc2:	ffffc097          	auipc	ra,0xffffc
    80004fc6:	e8c080e7          	jalr	-372(ra) # 80000e4e <strlen>
    80004fca:	0015069b          	addiw	a3,a0,1
    80004fce:	8652                	mv	a2,s4
    80004fd0:	85ca                	mv	a1,s2
    80004fd2:	855a                	mv	a0,s6
    80004fd4:	ffffc097          	auipc	ra,0xffffc
    80004fd8:	698080e7          	jalr	1688(ra) # 8000166c <copyout>
    80004fdc:	10054663          	bltz	a0,800050e8 <exec+0x30a>
    ustack[argc] = sp;
    80004fe0:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004fe4:	0485                	addi	s1,s1,1
    80004fe6:	008d8793          	addi	a5,s11,8
    80004fea:	def43823          	sd	a5,-528(s0)
    80004fee:	008db503          	ld	a0,8(s11)
    80004ff2:	c911                	beqz	a0,80005006 <exec+0x228>
    if(argc >= MAXARG)
    80004ff4:	09a1                	addi	s3,s3,8
    80004ff6:	fb3c95e3          	bne	s9,s3,80004fa0 <exec+0x1c2>
  sz = sz1;
    80004ffa:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004ffe:	4a81                	li	s5,0
    80005000:	a84d                	j	800050b2 <exec+0x2d4>
  sp = sz;
    80005002:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80005004:	4481                	li	s1,0
  ustack[argc] = 0;
    80005006:	00349793          	slli	a5,s1,0x3
    8000500a:	f9078793          	addi	a5,a5,-112
    8000500e:	97a2                	add	a5,a5,s0
    80005010:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80005014:	00148693          	addi	a3,s1,1
    80005018:	068e                	slli	a3,a3,0x3
    8000501a:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    8000501e:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005022:	01597663          	bgeu	s2,s5,8000502e <exec+0x250>
  sz = sz1;
    80005026:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    8000502a:	4a81                	li	s5,0
    8000502c:	a059                	j	800050b2 <exec+0x2d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    8000502e:	e9040613          	addi	a2,s0,-368
    80005032:	85ca                	mv	a1,s2
    80005034:	855a                	mv	a0,s6
    80005036:	ffffc097          	auipc	ra,0xffffc
    8000503a:	636080e7          	jalr	1590(ra) # 8000166c <copyout>
    8000503e:	0a054963          	bltz	a0,800050f0 <exec+0x312>
  p->trapframe->a1 = sp;
    80005042:	060bb783          	ld	a5,96(s7)
    80005046:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    8000504a:	de843783          	ld	a5,-536(s0)
    8000504e:	0007c703          	lbu	a4,0(a5)
    80005052:	cf11                	beqz	a4,8000506e <exec+0x290>
    80005054:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005056:	02f00693          	li	a3,47
    8000505a:	a039                	j	80005068 <exec+0x28a>
      last = s+1;
    8000505c:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80005060:	0785                	addi	a5,a5,1
    80005062:	fff7c703          	lbu	a4,-1(a5)
    80005066:	c701                	beqz	a4,8000506e <exec+0x290>
    if(*s == '/')
    80005068:	fed71ce3          	bne	a4,a3,80005060 <exec+0x282>
    8000506c:	bfc5                	j	8000505c <exec+0x27e>
  safestrcpy(p->name, last, sizeof(p->name));
    8000506e:	4641                	li	a2,16
    80005070:	de843583          	ld	a1,-536(s0)
    80005074:	160b8513          	addi	a0,s7,352
    80005078:	ffffc097          	auipc	ra,0xffffc
    8000507c:	da4080e7          	jalr	-604(ra) # 80000e1c <safestrcpy>
  oldpagetable = p->pagetable;
    80005080:	058bb503          	ld	a0,88(s7)
  p->pagetable = pagetable;
    80005084:	056bbc23          	sd	s6,88(s7)
  p->sz = sz;
    80005088:	058bb823          	sd	s8,80(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    8000508c:	060bb783          	ld	a5,96(s7)
    80005090:	e6843703          	ld	a4,-408(s0)
    80005094:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005096:	060bb783          	ld	a5,96(s7)
    8000509a:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    8000509e:	85ea                	mv	a1,s10
    800050a0:	ffffd097          	auipc	ra,0xffffd
    800050a4:	a6c080e7          	jalr	-1428(ra) # 80001b0c <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    800050a8:	0004851b          	sext.w	a0,s1
    800050ac:	b3f9                	j	80004e7a <exec+0x9c>
    800050ae:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    800050b2:	df843583          	ld	a1,-520(s0)
    800050b6:	855a                	mv	a0,s6
    800050b8:	ffffd097          	auipc	ra,0xffffd
    800050bc:	a54080e7          	jalr	-1452(ra) # 80001b0c <proc_freepagetable>
  if(ip){
    800050c0:	da0a93e3          	bnez	s5,80004e66 <exec+0x88>
  return -1;
    800050c4:	557d                	li	a0,-1
    800050c6:	bb55                	j	80004e7a <exec+0x9c>
    800050c8:	df243c23          	sd	s2,-520(s0)
    800050cc:	b7dd                	j	800050b2 <exec+0x2d4>
    800050ce:	df243c23          	sd	s2,-520(s0)
    800050d2:	b7c5                	j	800050b2 <exec+0x2d4>
    800050d4:	df243c23          	sd	s2,-520(s0)
    800050d8:	bfe9                	j	800050b2 <exec+0x2d4>
    800050da:	df243c23          	sd	s2,-520(s0)
    800050de:	bfd1                	j	800050b2 <exec+0x2d4>
  sz = sz1;
    800050e0:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800050e4:	4a81                	li	s5,0
    800050e6:	b7f1                	j	800050b2 <exec+0x2d4>
  sz = sz1;
    800050e8:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800050ec:	4a81                	li	s5,0
    800050ee:	b7d1                	j	800050b2 <exec+0x2d4>
  sz = sz1;
    800050f0:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    800050f4:	4a81                	li	s5,0
    800050f6:	bf75                	j	800050b2 <exec+0x2d4>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    800050f8:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    800050fc:	e0843783          	ld	a5,-504(s0)
    80005100:	0017869b          	addiw	a3,a5,1
    80005104:	e0d43423          	sd	a3,-504(s0)
    80005108:	e0043783          	ld	a5,-512(s0)
    8000510c:	0387879b          	addiw	a5,a5,56
    80005110:	e8845703          	lhu	a4,-376(s0)
    80005114:	e0e6dfe3          	bge	a3,a4,80004f32 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005118:	2781                	sext.w	a5,a5
    8000511a:	e0f43023          	sd	a5,-512(s0)
    8000511e:	03800713          	li	a4,56
    80005122:	86be                	mv	a3,a5
    80005124:	e1840613          	addi	a2,s0,-488
    80005128:	4581                	li	a1,0
    8000512a:	8556                	mv	a0,s5
    8000512c:	fffff097          	auipc	ra,0xfffff
    80005130:	a58080e7          	jalr	-1448(ra) # 80003b84 <readi>
    80005134:	03800793          	li	a5,56
    80005138:	f6f51be3          	bne	a0,a5,800050ae <exec+0x2d0>
    if(ph.type != ELF_PROG_LOAD)
    8000513c:	e1842783          	lw	a5,-488(s0)
    80005140:	4705                	li	a4,1
    80005142:	fae79de3          	bne	a5,a4,800050fc <exec+0x31e>
    if(ph.memsz < ph.filesz)
    80005146:	e4043483          	ld	s1,-448(s0)
    8000514a:	e3843783          	ld	a5,-456(s0)
    8000514e:	f6f4ede3          	bltu	s1,a5,800050c8 <exec+0x2ea>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005152:	e2843783          	ld	a5,-472(s0)
    80005156:	94be                	add	s1,s1,a5
    80005158:	f6f4ebe3          	bltu	s1,a5,800050ce <exec+0x2f0>
    if(ph.vaddr % PGSIZE != 0)
    8000515c:	de043703          	ld	a4,-544(s0)
    80005160:	8ff9                	and	a5,a5,a4
    80005162:	fbad                	bnez	a5,800050d4 <exec+0x2f6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005164:	e1c42503          	lw	a0,-484(s0)
    80005168:	00000097          	auipc	ra,0x0
    8000516c:	c5c080e7          	jalr	-932(ra) # 80004dc4 <flags2perm>
    80005170:	86aa                	mv	a3,a0
    80005172:	8626                	mv	a2,s1
    80005174:	85ca                	mv	a1,s2
    80005176:	855a                	mv	a0,s6
    80005178:	ffffc097          	auipc	ra,0xffffc
    8000517c:	298080e7          	jalr	664(ra) # 80001410 <uvmalloc>
    80005180:	dea43c23          	sd	a0,-520(s0)
    80005184:	d939                	beqz	a0,800050da <exec+0x2fc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005186:	e2843c03          	ld	s8,-472(s0)
    8000518a:	e2042c83          	lw	s9,-480(s0)
    8000518e:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005192:	f60b83e3          	beqz	s7,800050f8 <exec+0x31a>
    80005196:	89de                	mv	s3,s7
    80005198:	4481                	li	s1,0
    8000519a:	bb9d                	j	80004f10 <exec+0x132>

000000008000519c <random>:
#include "types.h"

// Return a integer between 0 and ((2^32 - 1) / 2), which is 2147483647.
uint
random(void)
{
    8000519c:	1141                	addi	sp,sp,-16
    8000519e:	e422                	sd	s0,8(sp)
    800051a0:	0800                	addi	s0,sp,16
  // Taken from http://stackoverflow.com/questions/1167253/implementation-of-rand
  // Courtesy: https://github.com/joonlim/xv6/blob/master/random.c
  static unsigned int z1 = 12345, z2 = 12345, z3 = 12345, z4 = 12345;
  unsigned int b;
  b  = ((z1 << 6) ^ z1) >> 13;
    800051a2:	00003697          	auipc	a3,0x3
    800051a6:	6c268693          	addi	a3,a3,1730 # 80008864 <z1.3>
    800051aa:	429c                	lw	a5,0(a3)
    800051ac:	0067971b          	slliw	a4,a5,0x6
    800051b0:	8f3d                	xor	a4,a4,a5
    800051b2:	00d7571b          	srliw	a4,a4,0xd
  z1 = ((z1 & 4294967294U) << 18) ^ b;
    800051b6:	0127951b          	slliw	a0,a5,0x12
    800051ba:	fff807b7          	lui	a5,0xfff80
    800051be:	8d7d                	and	a0,a0,a5
    800051c0:	8d39                	xor	a0,a0,a4
    800051c2:	2501                	sext.w	a0,a0
    800051c4:	c288                	sw	a0,0(a3)
  b  = ((z2 << 2) ^ z2) >> 27; 
    800051c6:	00003717          	auipc	a4,0x3
    800051ca:	69a70713          	addi	a4,a4,1690 # 80008860 <z2.2>
    800051ce:	431c                	lw	a5,0(a4)
    800051d0:	0027969b          	slliw	a3,a5,0x2
    800051d4:	8fb5                	xor	a5,a5,a3
    800051d6:	01b7d79b          	srliw	a5,a5,0x1b
  z2 = ((z2 & 4294967288U) << 2) ^ b;
    800051da:	9a81                	andi	a3,a3,-32
    800051dc:	8ebd                	xor	a3,a3,a5
    800051de:	2681                	sext.w	a3,a3
    800051e0:	c314                	sw	a3,0(a4)
  b  = ((z3 << 13) ^ z3) >> 21;
    800051e2:	00003597          	auipc	a1,0x3
    800051e6:	67a58593          	addi	a1,a1,1658 # 8000885c <z3.1>
    800051ea:	419c                	lw	a5,0(a1)
    800051ec:	00d7961b          	slliw	a2,a5,0xd
    800051f0:	8e3d                	xor	a2,a2,a5
    800051f2:	0156561b          	srliw	a2,a2,0x15
  z3 = ((z3 & 4294967280U) << 7) ^ b;
    800051f6:	0077971b          	slliw	a4,a5,0x7
    800051fa:	80077713          	andi	a4,a4,-2048
    800051fe:	8f31                	xor	a4,a4,a2
    80005200:	2701                	sext.w	a4,a4
    80005202:	c198                	sw	a4,0(a1)
  b  = ((z4 << 3) ^ z4) >> 12;
    80005204:	00003597          	auipc	a1,0x3
    80005208:	65458593          	addi	a1,a1,1620 # 80008858 <z4.0>
    8000520c:	419c                	lw	a5,0(a1)
    8000520e:	0037961b          	slliw	a2,a5,0x3
    80005212:	8e3d                	xor	a2,a2,a5
    80005214:	00c6561b          	srliw	a2,a2,0xc
  z4 = ((z4 & 4294967168U) << 13) ^ b;
    80005218:	00d7979b          	slliw	a5,a5,0xd
    8000521c:	fff00837          	lui	a6,0xfff00
    80005220:	0107f7b3          	and	a5,a5,a6
    80005224:	8fb1                	xor	a5,a5,a2
    80005226:	2781                	sext.w	a5,a5
    80005228:	c19c                	sw	a5,0(a1)

  return (z1 ^ z2 ^ z3 ^ z4) / 2;
    8000522a:	8d35                	xor	a0,a0,a3
    8000522c:	8d39                	xor	a0,a0,a4
    8000522e:	8d3d                	xor	a0,a0,a5
}
    80005230:	0015551b          	srliw	a0,a0,0x1
    80005234:	6422                	ld	s0,8(sp)
    80005236:	0141                	addi	sp,sp,16
    80005238:	8082                	ret

000000008000523a <randomrange>:

// Return a random integer between a given range.
int
randomrange(int lo, int hi)
{
    8000523a:	1101                	addi	sp,sp,-32
    8000523c:	ec06                	sd	ra,24(sp)
    8000523e:	e822                	sd	s0,16(sp)
    80005240:	e426                	sd	s1,8(sp)
    80005242:	e04a                	sd	s2,0(sp)
    80005244:	1000                	addi	s0,sp,32
    80005246:	892a                	mv	s2,a0
    80005248:	84ae                	mv	s1,a1
  if (hi < lo) {
    8000524a:	00a5d463          	bge	a1,a0,80005252 <randomrange+0x18>
    int tmp = lo;
    lo = hi;
    8000524e:	892e                	mv	s2,a1
    hi = tmp;
    80005250:	84aa                	mv	s1,a0
  }
  int range = hi - lo + 1;
  return random() % (range) + lo;
    80005252:	00000097          	auipc	ra,0x0
    80005256:	f4a080e7          	jalr	-182(ra) # 8000519c <random>
  int range = hi - lo + 1;
    8000525a:	412484bb          	subw	s1,s1,s2
    8000525e:	2485                	addiw	s1,s1,1
  return random() % (range) + lo;
    80005260:	0295753b          	remuw	a0,a0,s1
    80005264:	0125053b          	addw	a0,a0,s2
    80005268:	60e2                	ld	ra,24(sp)
    8000526a:	6442                	ld	s0,16(sp)
    8000526c:	64a2                	ld	s1,8(sp)
    8000526e:	6902                	ld	s2,0(sp)
    80005270:	6105                	addi	sp,sp,32
    80005272:	8082                	ret

0000000080005274 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005274:	7179                	addi	sp,sp,-48
    80005276:	f406                	sd	ra,40(sp)
    80005278:	f022                	sd	s0,32(sp)
    8000527a:	ec26                	sd	s1,24(sp)
    8000527c:	e84a                	sd	s2,16(sp)
    8000527e:	1800                	addi	s0,sp,48
    80005280:	892e                	mv	s2,a1
    80005282:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005284:	fdc40593          	addi	a1,s0,-36
    80005288:	ffffe097          	auipc	ra,0xffffe
    8000528c:	a8a080e7          	jalr	-1398(ra) # 80002d12 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005290:	fdc42703          	lw	a4,-36(s0)
    80005294:	47bd                	li	a5,15
    80005296:	02e7eb63          	bltu	a5,a4,800052cc <argfd+0x58>
    8000529a:	ffffc097          	auipc	ra,0xffffc
    8000529e:	712080e7          	jalr	1810(ra) # 800019ac <myproc>
    800052a2:	fdc42703          	lw	a4,-36(s0)
    800052a6:	01a70793          	addi	a5,a4,26
    800052aa:	078e                	slli	a5,a5,0x3
    800052ac:	953e                	add	a0,a0,a5
    800052ae:	651c                	ld	a5,8(a0)
    800052b0:	c385                	beqz	a5,800052d0 <argfd+0x5c>
    return -1;
  if(pfd)
    800052b2:	00090463          	beqz	s2,800052ba <argfd+0x46>
    *pfd = fd;
    800052b6:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    800052ba:	4501                	li	a0,0
  if(pf)
    800052bc:	c091                	beqz	s1,800052c0 <argfd+0x4c>
    *pf = f;
    800052be:	e09c                	sd	a5,0(s1)
}
    800052c0:	70a2                	ld	ra,40(sp)
    800052c2:	7402                	ld	s0,32(sp)
    800052c4:	64e2                	ld	s1,24(sp)
    800052c6:	6942                	ld	s2,16(sp)
    800052c8:	6145                	addi	sp,sp,48
    800052ca:	8082                	ret
    return -1;
    800052cc:	557d                	li	a0,-1
    800052ce:	bfcd                	j	800052c0 <argfd+0x4c>
    800052d0:	557d                	li	a0,-1
    800052d2:	b7fd                	j	800052c0 <argfd+0x4c>

00000000800052d4 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800052d4:	1101                	addi	sp,sp,-32
    800052d6:	ec06                	sd	ra,24(sp)
    800052d8:	e822                	sd	s0,16(sp)
    800052da:	e426                	sd	s1,8(sp)
    800052dc:	1000                	addi	s0,sp,32
    800052de:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800052e0:	ffffc097          	auipc	ra,0xffffc
    800052e4:	6cc080e7          	jalr	1740(ra) # 800019ac <myproc>
    800052e8:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800052ea:	0d850793          	addi	a5,a0,216
    800052ee:	4501                	li	a0,0
    800052f0:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800052f2:	6398                	ld	a4,0(a5)
    800052f4:	cb19                	beqz	a4,8000530a <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800052f6:	2505                	addiw	a0,a0,1
    800052f8:	07a1                	addi	a5,a5,8 # fffffffffff80008 <end+0xffffffff7ff5e088>
    800052fa:	fed51ce3          	bne	a0,a3,800052f2 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800052fe:	557d                	li	a0,-1
}
    80005300:	60e2                	ld	ra,24(sp)
    80005302:	6442                	ld	s0,16(sp)
    80005304:	64a2                	ld	s1,8(sp)
    80005306:	6105                	addi	sp,sp,32
    80005308:	8082                	ret
      p->ofile[fd] = f;
    8000530a:	01a50793          	addi	a5,a0,26
    8000530e:	078e                	slli	a5,a5,0x3
    80005310:	963e                	add	a2,a2,a5
    80005312:	e604                	sd	s1,8(a2)
      return fd;
    80005314:	b7f5                	j	80005300 <fdalloc+0x2c>

0000000080005316 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005316:	715d                	addi	sp,sp,-80
    80005318:	e486                	sd	ra,72(sp)
    8000531a:	e0a2                	sd	s0,64(sp)
    8000531c:	fc26                	sd	s1,56(sp)
    8000531e:	f84a                	sd	s2,48(sp)
    80005320:	f44e                	sd	s3,40(sp)
    80005322:	f052                	sd	s4,32(sp)
    80005324:	ec56                	sd	s5,24(sp)
    80005326:	e85a                	sd	s6,16(sp)
    80005328:	0880                	addi	s0,sp,80
    8000532a:	8b2e                	mv	s6,a1
    8000532c:	89b2                	mv	s3,a2
    8000532e:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005330:	fb040593          	addi	a1,s0,-80
    80005334:	fffff097          	auipc	ra,0xfffff
    80005338:	d66080e7          	jalr	-666(ra) # 8000409a <nameiparent>
    8000533c:	84aa                	mv	s1,a0
    8000533e:	14050f63          	beqz	a0,8000549c <create+0x186>
    return 0;

  ilock(dp);
    80005342:	ffffe097          	auipc	ra,0xffffe
    80005346:	58e080e7          	jalr	1422(ra) # 800038d0 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    8000534a:	4601                	li	a2,0
    8000534c:	fb040593          	addi	a1,s0,-80
    80005350:	8526                	mv	a0,s1
    80005352:	fffff097          	auipc	ra,0xfffff
    80005356:	a62080e7          	jalr	-1438(ra) # 80003db4 <dirlookup>
    8000535a:	8aaa                	mv	s5,a0
    8000535c:	c931                	beqz	a0,800053b0 <create+0x9a>
    iunlockput(dp);
    8000535e:	8526                	mv	a0,s1
    80005360:	ffffe097          	auipc	ra,0xffffe
    80005364:	7d2080e7          	jalr	2002(ra) # 80003b32 <iunlockput>
    ilock(ip);
    80005368:	8556                	mv	a0,s5
    8000536a:	ffffe097          	auipc	ra,0xffffe
    8000536e:	566080e7          	jalr	1382(ra) # 800038d0 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005372:	000b059b          	sext.w	a1,s6
    80005376:	4789                	li	a5,2
    80005378:	02f59563          	bne	a1,a5,800053a2 <create+0x8c>
    8000537c:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdd0c4>
    80005380:	37f9                	addiw	a5,a5,-2
    80005382:	17c2                	slli	a5,a5,0x30
    80005384:	93c1                	srli	a5,a5,0x30
    80005386:	4705                	li	a4,1
    80005388:	00f76d63          	bltu	a4,a5,800053a2 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    8000538c:	8556                	mv	a0,s5
    8000538e:	60a6                	ld	ra,72(sp)
    80005390:	6406                	ld	s0,64(sp)
    80005392:	74e2                	ld	s1,56(sp)
    80005394:	7942                	ld	s2,48(sp)
    80005396:	79a2                	ld	s3,40(sp)
    80005398:	7a02                	ld	s4,32(sp)
    8000539a:	6ae2                	ld	s5,24(sp)
    8000539c:	6b42                	ld	s6,16(sp)
    8000539e:	6161                	addi	sp,sp,80
    800053a0:	8082                	ret
    iunlockput(ip);
    800053a2:	8556                	mv	a0,s5
    800053a4:	ffffe097          	auipc	ra,0xffffe
    800053a8:	78e080e7          	jalr	1934(ra) # 80003b32 <iunlockput>
    return 0;
    800053ac:	4a81                	li	s5,0
    800053ae:	bff9                	j	8000538c <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    800053b0:	85da                	mv	a1,s6
    800053b2:	4088                	lw	a0,0(s1)
    800053b4:	ffffe097          	auipc	ra,0xffffe
    800053b8:	37e080e7          	jalr	894(ra) # 80003732 <ialloc>
    800053bc:	8a2a                	mv	s4,a0
    800053be:	c539                	beqz	a0,8000540c <create+0xf6>
  ilock(ip);
    800053c0:	ffffe097          	auipc	ra,0xffffe
    800053c4:	510080e7          	jalr	1296(ra) # 800038d0 <ilock>
  ip->major = major;
    800053c8:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800053cc:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800053d0:	4905                	li	s2,1
    800053d2:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    800053d6:	8552                	mv	a0,s4
    800053d8:	ffffe097          	auipc	ra,0xffffe
    800053dc:	42c080e7          	jalr	1068(ra) # 80003804 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800053e0:	000b059b          	sext.w	a1,s6
    800053e4:	03258b63          	beq	a1,s2,8000541a <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    800053e8:	004a2603          	lw	a2,4(s4)
    800053ec:	fb040593          	addi	a1,s0,-80
    800053f0:	8526                	mv	a0,s1
    800053f2:	fffff097          	auipc	ra,0xfffff
    800053f6:	bd8080e7          	jalr	-1064(ra) # 80003fca <dirlink>
    800053fa:	06054f63          	bltz	a0,80005478 <create+0x162>
  iunlockput(dp);
    800053fe:	8526                	mv	a0,s1
    80005400:	ffffe097          	auipc	ra,0xffffe
    80005404:	732080e7          	jalr	1842(ra) # 80003b32 <iunlockput>
  return ip;
    80005408:	8ad2                	mv	s5,s4
    8000540a:	b749                	j	8000538c <create+0x76>
    iunlockput(dp);
    8000540c:	8526                	mv	a0,s1
    8000540e:	ffffe097          	auipc	ra,0xffffe
    80005412:	724080e7          	jalr	1828(ra) # 80003b32 <iunlockput>
    return 0;
    80005416:	8ad2                	mv	s5,s4
    80005418:	bf95                	j	8000538c <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    8000541a:	004a2603          	lw	a2,4(s4)
    8000541e:	00003597          	auipc	a1,0x3
    80005422:	2e258593          	addi	a1,a1,738 # 80008700 <syscalls+0x2b0>
    80005426:	8552                	mv	a0,s4
    80005428:	fffff097          	auipc	ra,0xfffff
    8000542c:	ba2080e7          	jalr	-1118(ra) # 80003fca <dirlink>
    80005430:	04054463          	bltz	a0,80005478 <create+0x162>
    80005434:	40d0                	lw	a2,4(s1)
    80005436:	00003597          	auipc	a1,0x3
    8000543a:	2d258593          	addi	a1,a1,722 # 80008708 <syscalls+0x2b8>
    8000543e:	8552                	mv	a0,s4
    80005440:	fffff097          	auipc	ra,0xfffff
    80005444:	b8a080e7          	jalr	-1142(ra) # 80003fca <dirlink>
    80005448:	02054863          	bltz	a0,80005478 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    8000544c:	004a2603          	lw	a2,4(s4)
    80005450:	fb040593          	addi	a1,s0,-80
    80005454:	8526                	mv	a0,s1
    80005456:	fffff097          	auipc	ra,0xfffff
    8000545a:	b74080e7          	jalr	-1164(ra) # 80003fca <dirlink>
    8000545e:	00054d63          	bltz	a0,80005478 <create+0x162>
    dp->nlink++;  // for ".."
    80005462:	04a4d783          	lhu	a5,74(s1)
    80005466:	2785                	addiw	a5,a5,1
    80005468:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    8000546c:	8526                	mv	a0,s1
    8000546e:	ffffe097          	auipc	ra,0xffffe
    80005472:	396080e7          	jalr	918(ra) # 80003804 <iupdate>
    80005476:	b761                	j	800053fe <create+0xe8>
  ip->nlink = 0;
    80005478:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    8000547c:	8552                	mv	a0,s4
    8000547e:	ffffe097          	auipc	ra,0xffffe
    80005482:	386080e7          	jalr	902(ra) # 80003804 <iupdate>
  iunlockput(ip);
    80005486:	8552                	mv	a0,s4
    80005488:	ffffe097          	auipc	ra,0xffffe
    8000548c:	6aa080e7          	jalr	1706(ra) # 80003b32 <iunlockput>
  iunlockput(dp);
    80005490:	8526                	mv	a0,s1
    80005492:	ffffe097          	auipc	ra,0xffffe
    80005496:	6a0080e7          	jalr	1696(ra) # 80003b32 <iunlockput>
  return 0;
    8000549a:	bdcd                	j	8000538c <create+0x76>
    return 0;
    8000549c:	8aaa                	mv	s5,a0
    8000549e:	b5fd                	j	8000538c <create+0x76>

00000000800054a0 <sys_dup>:
{
    800054a0:	7179                	addi	sp,sp,-48
    800054a2:	f406                	sd	ra,40(sp)
    800054a4:	f022                	sd	s0,32(sp)
    800054a6:	ec26                	sd	s1,24(sp)
    800054a8:	e84a                	sd	s2,16(sp)
    800054aa:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    800054ac:	fd840613          	addi	a2,s0,-40
    800054b0:	4581                	li	a1,0
    800054b2:	4501                	li	a0,0
    800054b4:	00000097          	auipc	ra,0x0
    800054b8:	dc0080e7          	jalr	-576(ra) # 80005274 <argfd>
    return -1;
    800054bc:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    800054be:	02054363          	bltz	a0,800054e4 <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    800054c2:	fd843903          	ld	s2,-40(s0)
    800054c6:	854a                	mv	a0,s2
    800054c8:	00000097          	auipc	ra,0x0
    800054cc:	e0c080e7          	jalr	-500(ra) # 800052d4 <fdalloc>
    800054d0:	84aa                	mv	s1,a0
    return -1;
    800054d2:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800054d4:	00054863          	bltz	a0,800054e4 <sys_dup+0x44>
  filedup(f);
    800054d8:	854a                	mv	a0,s2
    800054da:	fffff097          	auipc	ra,0xfffff
    800054de:	238080e7          	jalr	568(ra) # 80004712 <filedup>
  return fd;
    800054e2:	87a6                	mv	a5,s1
}
    800054e4:	853e                	mv	a0,a5
    800054e6:	70a2                	ld	ra,40(sp)
    800054e8:	7402                	ld	s0,32(sp)
    800054ea:	64e2                	ld	s1,24(sp)
    800054ec:	6942                	ld	s2,16(sp)
    800054ee:	6145                	addi	sp,sp,48
    800054f0:	8082                	ret

00000000800054f2 <sys_read>:
{
    800054f2:	7179                	addi	sp,sp,-48
    800054f4:	f406                	sd	ra,40(sp)
    800054f6:	f022                	sd	s0,32(sp)
    800054f8:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800054fa:	fd840593          	addi	a1,s0,-40
    800054fe:	4505                	li	a0,1
    80005500:	ffffe097          	auipc	ra,0xffffe
    80005504:	832080e7          	jalr	-1998(ra) # 80002d32 <argaddr>
  argint(2, &n);
    80005508:	fe440593          	addi	a1,s0,-28
    8000550c:	4509                	li	a0,2
    8000550e:	ffffe097          	auipc	ra,0xffffe
    80005512:	804080e7          	jalr	-2044(ra) # 80002d12 <argint>
  if(argfd(0, 0, &f) < 0)
    80005516:	fe840613          	addi	a2,s0,-24
    8000551a:	4581                	li	a1,0
    8000551c:	4501                	li	a0,0
    8000551e:	00000097          	auipc	ra,0x0
    80005522:	d56080e7          	jalr	-682(ra) # 80005274 <argfd>
    80005526:	87aa                	mv	a5,a0
    return -1;
    80005528:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000552a:	0007cc63          	bltz	a5,80005542 <sys_read+0x50>
  return fileread(f, p, n);
    8000552e:	fe442603          	lw	a2,-28(s0)
    80005532:	fd843583          	ld	a1,-40(s0)
    80005536:	fe843503          	ld	a0,-24(s0)
    8000553a:	fffff097          	auipc	ra,0xfffff
    8000553e:	364080e7          	jalr	868(ra) # 8000489e <fileread>
}
    80005542:	70a2                	ld	ra,40(sp)
    80005544:	7402                	ld	s0,32(sp)
    80005546:	6145                	addi	sp,sp,48
    80005548:	8082                	ret

000000008000554a <sys_write>:
{
    8000554a:	7179                	addi	sp,sp,-48
    8000554c:	f406                	sd	ra,40(sp)
    8000554e:	f022                	sd	s0,32(sp)
    80005550:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005552:	fd840593          	addi	a1,s0,-40
    80005556:	4505                	li	a0,1
    80005558:	ffffd097          	auipc	ra,0xffffd
    8000555c:	7da080e7          	jalr	2010(ra) # 80002d32 <argaddr>
  argint(2, &n);
    80005560:	fe440593          	addi	a1,s0,-28
    80005564:	4509                	li	a0,2
    80005566:	ffffd097          	auipc	ra,0xffffd
    8000556a:	7ac080e7          	jalr	1964(ra) # 80002d12 <argint>
  if(argfd(0, 0, &f) < 0)
    8000556e:	fe840613          	addi	a2,s0,-24
    80005572:	4581                	li	a1,0
    80005574:	4501                	li	a0,0
    80005576:	00000097          	auipc	ra,0x0
    8000557a:	cfe080e7          	jalr	-770(ra) # 80005274 <argfd>
    8000557e:	87aa                	mv	a5,a0
    return -1;
    80005580:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005582:	0007cc63          	bltz	a5,8000559a <sys_write+0x50>
  return filewrite(f, p, n);
    80005586:	fe442603          	lw	a2,-28(s0)
    8000558a:	fd843583          	ld	a1,-40(s0)
    8000558e:	fe843503          	ld	a0,-24(s0)
    80005592:	fffff097          	auipc	ra,0xfffff
    80005596:	3ce080e7          	jalr	974(ra) # 80004960 <filewrite>
}
    8000559a:	70a2                	ld	ra,40(sp)
    8000559c:	7402                	ld	s0,32(sp)
    8000559e:	6145                	addi	sp,sp,48
    800055a0:	8082                	ret

00000000800055a2 <sys_close>:
{
    800055a2:	1101                	addi	sp,sp,-32
    800055a4:	ec06                	sd	ra,24(sp)
    800055a6:	e822                	sd	s0,16(sp)
    800055a8:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    800055aa:	fe040613          	addi	a2,s0,-32
    800055ae:	fec40593          	addi	a1,s0,-20
    800055b2:	4501                	li	a0,0
    800055b4:	00000097          	auipc	ra,0x0
    800055b8:	cc0080e7          	jalr	-832(ra) # 80005274 <argfd>
    return -1;
    800055bc:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    800055be:	02054463          	bltz	a0,800055e6 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    800055c2:	ffffc097          	auipc	ra,0xffffc
    800055c6:	3ea080e7          	jalr	1002(ra) # 800019ac <myproc>
    800055ca:	fec42783          	lw	a5,-20(s0)
    800055ce:	07e9                	addi	a5,a5,26
    800055d0:	078e                	slli	a5,a5,0x3
    800055d2:	953e                	add	a0,a0,a5
    800055d4:	00053423          	sd	zero,8(a0)
  fileclose(f);
    800055d8:	fe043503          	ld	a0,-32(s0)
    800055dc:	fffff097          	auipc	ra,0xfffff
    800055e0:	188080e7          	jalr	392(ra) # 80004764 <fileclose>
  return 0;
    800055e4:	4781                	li	a5,0
}
    800055e6:	853e                	mv	a0,a5
    800055e8:	60e2                	ld	ra,24(sp)
    800055ea:	6442                	ld	s0,16(sp)
    800055ec:	6105                	addi	sp,sp,32
    800055ee:	8082                	ret

00000000800055f0 <sys_fstat>:
{
    800055f0:	1101                	addi	sp,sp,-32
    800055f2:	ec06                	sd	ra,24(sp)
    800055f4:	e822                	sd	s0,16(sp)
    800055f6:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    800055f8:	fe040593          	addi	a1,s0,-32
    800055fc:	4505                	li	a0,1
    800055fe:	ffffd097          	auipc	ra,0xffffd
    80005602:	734080e7          	jalr	1844(ra) # 80002d32 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005606:	fe840613          	addi	a2,s0,-24
    8000560a:	4581                	li	a1,0
    8000560c:	4501                	li	a0,0
    8000560e:	00000097          	auipc	ra,0x0
    80005612:	c66080e7          	jalr	-922(ra) # 80005274 <argfd>
    80005616:	87aa                	mv	a5,a0
    return -1;
    80005618:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000561a:	0007ca63          	bltz	a5,8000562e <sys_fstat+0x3e>
  return filestat(f, st);
    8000561e:	fe043583          	ld	a1,-32(s0)
    80005622:	fe843503          	ld	a0,-24(s0)
    80005626:	fffff097          	auipc	ra,0xfffff
    8000562a:	206080e7          	jalr	518(ra) # 8000482c <filestat>
}
    8000562e:	60e2                	ld	ra,24(sp)
    80005630:	6442                	ld	s0,16(sp)
    80005632:	6105                	addi	sp,sp,32
    80005634:	8082                	ret

0000000080005636 <sys_link>:
{
    80005636:	7169                	addi	sp,sp,-304
    80005638:	f606                	sd	ra,296(sp)
    8000563a:	f222                	sd	s0,288(sp)
    8000563c:	ee26                	sd	s1,280(sp)
    8000563e:	ea4a                	sd	s2,272(sp)
    80005640:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005642:	08000613          	li	a2,128
    80005646:	ed040593          	addi	a1,s0,-304
    8000564a:	4501                	li	a0,0
    8000564c:	ffffd097          	auipc	ra,0xffffd
    80005650:	706080e7          	jalr	1798(ra) # 80002d52 <argstr>
    return -1;
    80005654:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005656:	10054e63          	bltz	a0,80005772 <sys_link+0x13c>
    8000565a:	08000613          	li	a2,128
    8000565e:	f5040593          	addi	a1,s0,-176
    80005662:	4505                	li	a0,1
    80005664:	ffffd097          	auipc	ra,0xffffd
    80005668:	6ee080e7          	jalr	1774(ra) # 80002d52 <argstr>
    return -1;
    8000566c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000566e:	10054263          	bltz	a0,80005772 <sys_link+0x13c>
  begin_op();
    80005672:	fffff097          	auipc	ra,0xfffff
    80005676:	c2a080e7          	jalr	-982(ra) # 8000429c <begin_op>
  if((ip = namei(old)) == 0){
    8000567a:	ed040513          	addi	a0,s0,-304
    8000567e:	fffff097          	auipc	ra,0xfffff
    80005682:	9fe080e7          	jalr	-1538(ra) # 8000407c <namei>
    80005686:	84aa                	mv	s1,a0
    80005688:	c551                	beqz	a0,80005714 <sys_link+0xde>
  ilock(ip);
    8000568a:	ffffe097          	auipc	ra,0xffffe
    8000568e:	246080e7          	jalr	582(ra) # 800038d0 <ilock>
  if(ip->type == T_DIR){
    80005692:	04449703          	lh	a4,68(s1)
    80005696:	4785                	li	a5,1
    80005698:	08f70463          	beq	a4,a5,80005720 <sys_link+0xea>
  ip->nlink++;
    8000569c:	04a4d783          	lhu	a5,74(s1)
    800056a0:	2785                	addiw	a5,a5,1
    800056a2:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800056a6:	8526                	mv	a0,s1
    800056a8:	ffffe097          	auipc	ra,0xffffe
    800056ac:	15c080e7          	jalr	348(ra) # 80003804 <iupdate>
  iunlock(ip);
    800056b0:	8526                	mv	a0,s1
    800056b2:	ffffe097          	auipc	ra,0xffffe
    800056b6:	2e0080e7          	jalr	736(ra) # 80003992 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    800056ba:	fd040593          	addi	a1,s0,-48
    800056be:	f5040513          	addi	a0,s0,-176
    800056c2:	fffff097          	auipc	ra,0xfffff
    800056c6:	9d8080e7          	jalr	-1576(ra) # 8000409a <nameiparent>
    800056ca:	892a                	mv	s2,a0
    800056cc:	c935                	beqz	a0,80005740 <sys_link+0x10a>
  ilock(dp);
    800056ce:	ffffe097          	auipc	ra,0xffffe
    800056d2:	202080e7          	jalr	514(ra) # 800038d0 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800056d6:	00092703          	lw	a4,0(s2)
    800056da:	409c                	lw	a5,0(s1)
    800056dc:	04f71d63          	bne	a4,a5,80005736 <sys_link+0x100>
    800056e0:	40d0                	lw	a2,4(s1)
    800056e2:	fd040593          	addi	a1,s0,-48
    800056e6:	854a                	mv	a0,s2
    800056e8:	fffff097          	auipc	ra,0xfffff
    800056ec:	8e2080e7          	jalr	-1822(ra) # 80003fca <dirlink>
    800056f0:	04054363          	bltz	a0,80005736 <sys_link+0x100>
  iunlockput(dp);
    800056f4:	854a                	mv	a0,s2
    800056f6:	ffffe097          	auipc	ra,0xffffe
    800056fa:	43c080e7          	jalr	1084(ra) # 80003b32 <iunlockput>
  iput(ip);
    800056fe:	8526                	mv	a0,s1
    80005700:	ffffe097          	auipc	ra,0xffffe
    80005704:	38a080e7          	jalr	906(ra) # 80003a8a <iput>
  end_op();
    80005708:	fffff097          	auipc	ra,0xfffff
    8000570c:	c12080e7          	jalr	-1006(ra) # 8000431a <end_op>
  return 0;
    80005710:	4781                	li	a5,0
    80005712:	a085                	j	80005772 <sys_link+0x13c>
    end_op();
    80005714:	fffff097          	auipc	ra,0xfffff
    80005718:	c06080e7          	jalr	-1018(ra) # 8000431a <end_op>
    return -1;
    8000571c:	57fd                	li	a5,-1
    8000571e:	a891                	j	80005772 <sys_link+0x13c>
    iunlockput(ip);
    80005720:	8526                	mv	a0,s1
    80005722:	ffffe097          	auipc	ra,0xffffe
    80005726:	410080e7          	jalr	1040(ra) # 80003b32 <iunlockput>
    end_op();
    8000572a:	fffff097          	auipc	ra,0xfffff
    8000572e:	bf0080e7          	jalr	-1040(ra) # 8000431a <end_op>
    return -1;
    80005732:	57fd                	li	a5,-1
    80005734:	a83d                	j	80005772 <sys_link+0x13c>
    iunlockput(dp);
    80005736:	854a                	mv	a0,s2
    80005738:	ffffe097          	auipc	ra,0xffffe
    8000573c:	3fa080e7          	jalr	1018(ra) # 80003b32 <iunlockput>
  ilock(ip);
    80005740:	8526                	mv	a0,s1
    80005742:	ffffe097          	auipc	ra,0xffffe
    80005746:	18e080e7          	jalr	398(ra) # 800038d0 <ilock>
  ip->nlink--;
    8000574a:	04a4d783          	lhu	a5,74(s1)
    8000574e:	37fd                	addiw	a5,a5,-1
    80005750:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005754:	8526                	mv	a0,s1
    80005756:	ffffe097          	auipc	ra,0xffffe
    8000575a:	0ae080e7          	jalr	174(ra) # 80003804 <iupdate>
  iunlockput(ip);
    8000575e:	8526                	mv	a0,s1
    80005760:	ffffe097          	auipc	ra,0xffffe
    80005764:	3d2080e7          	jalr	978(ra) # 80003b32 <iunlockput>
  end_op();
    80005768:	fffff097          	auipc	ra,0xfffff
    8000576c:	bb2080e7          	jalr	-1102(ra) # 8000431a <end_op>
  return -1;
    80005770:	57fd                	li	a5,-1
}
    80005772:	853e                	mv	a0,a5
    80005774:	70b2                	ld	ra,296(sp)
    80005776:	7412                	ld	s0,288(sp)
    80005778:	64f2                	ld	s1,280(sp)
    8000577a:	6952                	ld	s2,272(sp)
    8000577c:	6155                	addi	sp,sp,304
    8000577e:	8082                	ret

0000000080005780 <sys_unlink>:
{
    80005780:	7151                	addi	sp,sp,-240
    80005782:	f586                	sd	ra,232(sp)
    80005784:	f1a2                	sd	s0,224(sp)
    80005786:	eda6                	sd	s1,216(sp)
    80005788:	e9ca                	sd	s2,208(sp)
    8000578a:	e5ce                	sd	s3,200(sp)
    8000578c:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000578e:	08000613          	li	a2,128
    80005792:	f3040593          	addi	a1,s0,-208
    80005796:	4501                	li	a0,0
    80005798:	ffffd097          	auipc	ra,0xffffd
    8000579c:	5ba080e7          	jalr	1466(ra) # 80002d52 <argstr>
    800057a0:	18054163          	bltz	a0,80005922 <sys_unlink+0x1a2>
  begin_op();
    800057a4:	fffff097          	auipc	ra,0xfffff
    800057a8:	af8080e7          	jalr	-1288(ra) # 8000429c <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    800057ac:	fb040593          	addi	a1,s0,-80
    800057b0:	f3040513          	addi	a0,s0,-208
    800057b4:	fffff097          	auipc	ra,0xfffff
    800057b8:	8e6080e7          	jalr	-1818(ra) # 8000409a <nameiparent>
    800057bc:	84aa                	mv	s1,a0
    800057be:	c979                	beqz	a0,80005894 <sys_unlink+0x114>
  ilock(dp);
    800057c0:	ffffe097          	auipc	ra,0xffffe
    800057c4:	110080e7          	jalr	272(ra) # 800038d0 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800057c8:	00003597          	auipc	a1,0x3
    800057cc:	f3858593          	addi	a1,a1,-200 # 80008700 <syscalls+0x2b0>
    800057d0:	fb040513          	addi	a0,s0,-80
    800057d4:	ffffe097          	auipc	ra,0xffffe
    800057d8:	5c6080e7          	jalr	1478(ra) # 80003d9a <namecmp>
    800057dc:	14050a63          	beqz	a0,80005930 <sys_unlink+0x1b0>
    800057e0:	00003597          	auipc	a1,0x3
    800057e4:	f2858593          	addi	a1,a1,-216 # 80008708 <syscalls+0x2b8>
    800057e8:	fb040513          	addi	a0,s0,-80
    800057ec:	ffffe097          	auipc	ra,0xffffe
    800057f0:	5ae080e7          	jalr	1454(ra) # 80003d9a <namecmp>
    800057f4:	12050e63          	beqz	a0,80005930 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800057f8:	f2c40613          	addi	a2,s0,-212
    800057fc:	fb040593          	addi	a1,s0,-80
    80005800:	8526                	mv	a0,s1
    80005802:	ffffe097          	auipc	ra,0xffffe
    80005806:	5b2080e7          	jalr	1458(ra) # 80003db4 <dirlookup>
    8000580a:	892a                	mv	s2,a0
    8000580c:	12050263          	beqz	a0,80005930 <sys_unlink+0x1b0>
  ilock(ip);
    80005810:	ffffe097          	auipc	ra,0xffffe
    80005814:	0c0080e7          	jalr	192(ra) # 800038d0 <ilock>
  if(ip->nlink < 1)
    80005818:	04a91783          	lh	a5,74(s2)
    8000581c:	08f05263          	blez	a5,800058a0 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80005820:	04491703          	lh	a4,68(s2)
    80005824:	4785                	li	a5,1
    80005826:	08f70563          	beq	a4,a5,800058b0 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000582a:	4641                	li	a2,16
    8000582c:	4581                	li	a1,0
    8000582e:	fc040513          	addi	a0,s0,-64
    80005832:	ffffb097          	auipc	ra,0xffffb
    80005836:	4a0080e7          	jalr	1184(ra) # 80000cd2 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000583a:	4741                	li	a4,16
    8000583c:	f2c42683          	lw	a3,-212(s0)
    80005840:	fc040613          	addi	a2,s0,-64
    80005844:	4581                	li	a1,0
    80005846:	8526                	mv	a0,s1
    80005848:	ffffe097          	auipc	ra,0xffffe
    8000584c:	434080e7          	jalr	1076(ra) # 80003c7c <writei>
    80005850:	47c1                	li	a5,16
    80005852:	0af51563          	bne	a0,a5,800058fc <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    80005856:	04491703          	lh	a4,68(s2)
    8000585a:	4785                	li	a5,1
    8000585c:	0af70863          	beq	a4,a5,8000590c <sys_unlink+0x18c>
  iunlockput(dp);
    80005860:	8526                	mv	a0,s1
    80005862:	ffffe097          	auipc	ra,0xffffe
    80005866:	2d0080e7          	jalr	720(ra) # 80003b32 <iunlockput>
  ip->nlink--;
    8000586a:	04a95783          	lhu	a5,74(s2)
    8000586e:	37fd                	addiw	a5,a5,-1
    80005870:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005874:	854a                	mv	a0,s2
    80005876:	ffffe097          	auipc	ra,0xffffe
    8000587a:	f8e080e7          	jalr	-114(ra) # 80003804 <iupdate>
  iunlockput(ip);
    8000587e:	854a                	mv	a0,s2
    80005880:	ffffe097          	auipc	ra,0xffffe
    80005884:	2b2080e7          	jalr	690(ra) # 80003b32 <iunlockput>
  end_op();
    80005888:	fffff097          	auipc	ra,0xfffff
    8000588c:	a92080e7          	jalr	-1390(ra) # 8000431a <end_op>
  return 0;
    80005890:	4501                	li	a0,0
    80005892:	a84d                	j	80005944 <sys_unlink+0x1c4>
    end_op();
    80005894:	fffff097          	auipc	ra,0xfffff
    80005898:	a86080e7          	jalr	-1402(ra) # 8000431a <end_op>
    return -1;
    8000589c:	557d                	li	a0,-1
    8000589e:	a05d                	j	80005944 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    800058a0:	00003517          	auipc	a0,0x3
    800058a4:	e7050513          	addi	a0,a0,-400 # 80008710 <syscalls+0x2c0>
    800058a8:	ffffb097          	auipc	ra,0xffffb
    800058ac:	c98080e7          	jalr	-872(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800058b0:	04c92703          	lw	a4,76(s2)
    800058b4:	02000793          	li	a5,32
    800058b8:	f6e7f9e3          	bgeu	a5,a4,8000582a <sys_unlink+0xaa>
    800058bc:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800058c0:	4741                	li	a4,16
    800058c2:	86ce                	mv	a3,s3
    800058c4:	f1840613          	addi	a2,s0,-232
    800058c8:	4581                	li	a1,0
    800058ca:	854a                	mv	a0,s2
    800058cc:	ffffe097          	auipc	ra,0xffffe
    800058d0:	2b8080e7          	jalr	696(ra) # 80003b84 <readi>
    800058d4:	47c1                	li	a5,16
    800058d6:	00f51b63          	bne	a0,a5,800058ec <sys_unlink+0x16c>
    if(de.inum != 0)
    800058da:	f1845783          	lhu	a5,-232(s0)
    800058de:	e7a1                	bnez	a5,80005926 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800058e0:	29c1                	addiw	s3,s3,16
    800058e2:	04c92783          	lw	a5,76(s2)
    800058e6:	fcf9ede3          	bltu	s3,a5,800058c0 <sys_unlink+0x140>
    800058ea:	b781                	j	8000582a <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800058ec:	00003517          	auipc	a0,0x3
    800058f0:	e3c50513          	addi	a0,a0,-452 # 80008728 <syscalls+0x2d8>
    800058f4:	ffffb097          	auipc	ra,0xffffb
    800058f8:	c4c080e7          	jalr	-948(ra) # 80000540 <panic>
    panic("unlink: writei");
    800058fc:	00003517          	auipc	a0,0x3
    80005900:	e4450513          	addi	a0,a0,-444 # 80008740 <syscalls+0x2f0>
    80005904:	ffffb097          	auipc	ra,0xffffb
    80005908:	c3c080e7          	jalr	-964(ra) # 80000540 <panic>
    dp->nlink--;
    8000590c:	04a4d783          	lhu	a5,74(s1)
    80005910:	37fd                	addiw	a5,a5,-1
    80005912:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005916:	8526                	mv	a0,s1
    80005918:	ffffe097          	auipc	ra,0xffffe
    8000591c:	eec080e7          	jalr	-276(ra) # 80003804 <iupdate>
    80005920:	b781                	j	80005860 <sys_unlink+0xe0>
    return -1;
    80005922:	557d                	li	a0,-1
    80005924:	a005                	j	80005944 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005926:	854a                	mv	a0,s2
    80005928:	ffffe097          	auipc	ra,0xffffe
    8000592c:	20a080e7          	jalr	522(ra) # 80003b32 <iunlockput>
  iunlockput(dp);
    80005930:	8526                	mv	a0,s1
    80005932:	ffffe097          	auipc	ra,0xffffe
    80005936:	200080e7          	jalr	512(ra) # 80003b32 <iunlockput>
  end_op();
    8000593a:	fffff097          	auipc	ra,0xfffff
    8000593e:	9e0080e7          	jalr	-1568(ra) # 8000431a <end_op>
  return -1;
    80005942:	557d                	li	a0,-1
}
    80005944:	70ae                	ld	ra,232(sp)
    80005946:	740e                	ld	s0,224(sp)
    80005948:	64ee                	ld	s1,216(sp)
    8000594a:	694e                	ld	s2,208(sp)
    8000594c:	69ae                	ld	s3,200(sp)
    8000594e:	616d                	addi	sp,sp,240
    80005950:	8082                	ret

0000000080005952 <sys_open>:

uint64
sys_open(void)
{
    80005952:	7131                	addi	sp,sp,-192
    80005954:	fd06                	sd	ra,184(sp)
    80005956:	f922                	sd	s0,176(sp)
    80005958:	f526                	sd	s1,168(sp)
    8000595a:	f14a                	sd	s2,160(sp)
    8000595c:	ed4e                	sd	s3,152(sp)
    8000595e:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005960:	f4c40593          	addi	a1,s0,-180
    80005964:	4505                	li	a0,1
    80005966:	ffffd097          	auipc	ra,0xffffd
    8000596a:	3ac080e7          	jalr	940(ra) # 80002d12 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000596e:	08000613          	li	a2,128
    80005972:	f5040593          	addi	a1,s0,-176
    80005976:	4501                	li	a0,0
    80005978:	ffffd097          	auipc	ra,0xffffd
    8000597c:	3da080e7          	jalr	986(ra) # 80002d52 <argstr>
    80005980:	87aa                	mv	a5,a0
    return -1;
    80005982:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005984:	0a07c963          	bltz	a5,80005a36 <sys_open+0xe4>

  begin_op();
    80005988:	fffff097          	auipc	ra,0xfffff
    8000598c:	914080e7          	jalr	-1772(ra) # 8000429c <begin_op>

  if(omode & O_CREATE){
    80005990:	f4c42783          	lw	a5,-180(s0)
    80005994:	2007f793          	andi	a5,a5,512
    80005998:	cfc5                	beqz	a5,80005a50 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000599a:	4681                	li	a3,0
    8000599c:	4601                	li	a2,0
    8000599e:	4589                	li	a1,2
    800059a0:	f5040513          	addi	a0,s0,-176
    800059a4:	00000097          	auipc	ra,0x0
    800059a8:	972080e7          	jalr	-1678(ra) # 80005316 <create>
    800059ac:	84aa                	mv	s1,a0
    if(ip == 0){
    800059ae:	c959                	beqz	a0,80005a44 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    800059b0:	04449703          	lh	a4,68(s1)
    800059b4:	478d                	li	a5,3
    800059b6:	00f71763          	bne	a4,a5,800059c4 <sys_open+0x72>
    800059ba:	0464d703          	lhu	a4,70(s1)
    800059be:	47a5                	li	a5,9
    800059c0:	0ce7ed63          	bltu	a5,a4,80005a9a <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    800059c4:	fffff097          	auipc	ra,0xfffff
    800059c8:	ce4080e7          	jalr	-796(ra) # 800046a8 <filealloc>
    800059cc:	89aa                	mv	s3,a0
    800059ce:	10050363          	beqz	a0,80005ad4 <sys_open+0x182>
    800059d2:	00000097          	auipc	ra,0x0
    800059d6:	902080e7          	jalr	-1790(ra) # 800052d4 <fdalloc>
    800059da:	892a                	mv	s2,a0
    800059dc:	0e054763          	bltz	a0,80005aca <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800059e0:	04449703          	lh	a4,68(s1)
    800059e4:	478d                	li	a5,3
    800059e6:	0cf70563          	beq	a4,a5,80005ab0 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800059ea:	4789                	li	a5,2
    800059ec:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800059f0:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800059f4:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    800059f8:	f4c42783          	lw	a5,-180(s0)
    800059fc:	0017c713          	xori	a4,a5,1
    80005a00:	8b05                	andi	a4,a4,1
    80005a02:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005a06:	0037f713          	andi	a4,a5,3
    80005a0a:	00e03733          	snez	a4,a4
    80005a0e:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005a12:	4007f793          	andi	a5,a5,1024
    80005a16:	c791                	beqz	a5,80005a22 <sys_open+0xd0>
    80005a18:	04449703          	lh	a4,68(s1)
    80005a1c:	4789                	li	a5,2
    80005a1e:	0af70063          	beq	a4,a5,80005abe <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005a22:	8526                	mv	a0,s1
    80005a24:	ffffe097          	auipc	ra,0xffffe
    80005a28:	f6e080e7          	jalr	-146(ra) # 80003992 <iunlock>
  end_op();
    80005a2c:	fffff097          	auipc	ra,0xfffff
    80005a30:	8ee080e7          	jalr	-1810(ra) # 8000431a <end_op>

  return fd;
    80005a34:	854a                	mv	a0,s2
}
    80005a36:	70ea                	ld	ra,184(sp)
    80005a38:	744a                	ld	s0,176(sp)
    80005a3a:	74aa                	ld	s1,168(sp)
    80005a3c:	790a                	ld	s2,160(sp)
    80005a3e:	69ea                	ld	s3,152(sp)
    80005a40:	6129                	addi	sp,sp,192
    80005a42:	8082                	ret
      end_op();
    80005a44:	fffff097          	auipc	ra,0xfffff
    80005a48:	8d6080e7          	jalr	-1834(ra) # 8000431a <end_op>
      return -1;
    80005a4c:	557d                	li	a0,-1
    80005a4e:	b7e5                	j	80005a36 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005a50:	f5040513          	addi	a0,s0,-176
    80005a54:	ffffe097          	auipc	ra,0xffffe
    80005a58:	628080e7          	jalr	1576(ra) # 8000407c <namei>
    80005a5c:	84aa                	mv	s1,a0
    80005a5e:	c905                	beqz	a0,80005a8e <sys_open+0x13c>
    ilock(ip);
    80005a60:	ffffe097          	auipc	ra,0xffffe
    80005a64:	e70080e7          	jalr	-400(ra) # 800038d0 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005a68:	04449703          	lh	a4,68(s1)
    80005a6c:	4785                	li	a5,1
    80005a6e:	f4f711e3          	bne	a4,a5,800059b0 <sys_open+0x5e>
    80005a72:	f4c42783          	lw	a5,-180(s0)
    80005a76:	d7b9                	beqz	a5,800059c4 <sys_open+0x72>
      iunlockput(ip);
    80005a78:	8526                	mv	a0,s1
    80005a7a:	ffffe097          	auipc	ra,0xffffe
    80005a7e:	0b8080e7          	jalr	184(ra) # 80003b32 <iunlockput>
      end_op();
    80005a82:	fffff097          	auipc	ra,0xfffff
    80005a86:	898080e7          	jalr	-1896(ra) # 8000431a <end_op>
      return -1;
    80005a8a:	557d                	li	a0,-1
    80005a8c:	b76d                	j	80005a36 <sys_open+0xe4>
      end_op();
    80005a8e:	fffff097          	auipc	ra,0xfffff
    80005a92:	88c080e7          	jalr	-1908(ra) # 8000431a <end_op>
      return -1;
    80005a96:	557d                	li	a0,-1
    80005a98:	bf79                	j	80005a36 <sys_open+0xe4>
    iunlockput(ip);
    80005a9a:	8526                	mv	a0,s1
    80005a9c:	ffffe097          	auipc	ra,0xffffe
    80005aa0:	096080e7          	jalr	150(ra) # 80003b32 <iunlockput>
    end_op();
    80005aa4:	fffff097          	auipc	ra,0xfffff
    80005aa8:	876080e7          	jalr	-1930(ra) # 8000431a <end_op>
    return -1;
    80005aac:	557d                	li	a0,-1
    80005aae:	b761                	j	80005a36 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005ab0:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005ab4:	04649783          	lh	a5,70(s1)
    80005ab8:	02f99223          	sh	a5,36(s3)
    80005abc:	bf25                	j	800059f4 <sys_open+0xa2>
    itrunc(ip);
    80005abe:	8526                	mv	a0,s1
    80005ac0:	ffffe097          	auipc	ra,0xffffe
    80005ac4:	f1e080e7          	jalr	-226(ra) # 800039de <itrunc>
    80005ac8:	bfa9                	j	80005a22 <sys_open+0xd0>
      fileclose(f);
    80005aca:	854e                	mv	a0,s3
    80005acc:	fffff097          	auipc	ra,0xfffff
    80005ad0:	c98080e7          	jalr	-872(ra) # 80004764 <fileclose>
    iunlockput(ip);
    80005ad4:	8526                	mv	a0,s1
    80005ad6:	ffffe097          	auipc	ra,0xffffe
    80005ada:	05c080e7          	jalr	92(ra) # 80003b32 <iunlockput>
    end_op();
    80005ade:	fffff097          	auipc	ra,0xfffff
    80005ae2:	83c080e7          	jalr	-1988(ra) # 8000431a <end_op>
    return -1;
    80005ae6:	557d                	li	a0,-1
    80005ae8:	b7b9                	j	80005a36 <sys_open+0xe4>

0000000080005aea <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005aea:	7175                	addi	sp,sp,-144
    80005aec:	e506                	sd	ra,136(sp)
    80005aee:	e122                	sd	s0,128(sp)
    80005af0:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005af2:	ffffe097          	auipc	ra,0xffffe
    80005af6:	7aa080e7          	jalr	1962(ra) # 8000429c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005afa:	08000613          	li	a2,128
    80005afe:	f7040593          	addi	a1,s0,-144
    80005b02:	4501                	li	a0,0
    80005b04:	ffffd097          	auipc	ra,0xffffd
    80005b08:	24e080e7          	jalr	590(ra) # 80002d52 <argstr>
    80005b0c:	02054963          	bltz	a0,80005b3e <sys_mkdir+0x54>
    80005b10:	4681                	li	a3,0
    80005b12:	4601                	li	a2,0
    80005b14:	4585                	li	a1,1
    80005b16:	f7040513          	addi	a0,s0,-144
    80005b1a:	fffff097          	auipc	ra,0xfffff
    80005b1e:	7fc080e7          	jalr	2044(ra) # 80005316 <create>
    80005b22:	cd11                	beqz	a0,80005b3e <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005b24:	ffffe097          	auipc	ra,0xffffe
    80005b28:	00e080e7          	jalr	14(ra) # 80003b32 <iunlockput>
  end_op();
    80005b2c:	ffffe097          	auipc	ra,0xffffe
    80005b30:	7ee080e7          	jalr	2030(ra) # 8000431a <end_op>
  return 0;
    80005b34:	4501                	li	a0,0
}
    80005b36:	60aa                	ld	ra,136(sp)
    80005b38:	640a                	ld	s0,128(sp)
    80005b3a:	6149                	addi	sp,sp,144
    80005b3c:	8082                	ret
    end_op();
    80005b3e:	ffffe097          	auipc	ra,0xffffe
    80005b42:	7dc080e7          	jalr	2012(ra) # 8000431a <end_op>
    return -1;
    80005b46:	557d                	li	a0,-1
    80005b48:	b7fd                	j	80005b36 <sys_mkdir+0x4c>

0000000080005b4a <sys_mknod>:

uint64
sys_mknod(void)
{
    80005b4a:	7135                	addi	sp,sp,-160
    80005b4c:	ed06                	sd	ra,152(sp)
    80005b4e:	e922                	sd	s0,144(sp)
    80005b50:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005b52:	ffffe097          	auipc	ra,0xffffe
    80005b56:	74a080e7          	jalr	1866(ra) # 8000429c <begin_op>
  argint(1, &major);
    80005b5a:	f6c40593          	addi	a1,s0,-148
    80005b5e:	4505                	li	a0,1
    80005b60:	ffffd097          	auipc	ra,0xffffd
    80005b64:	1b2080e7          	jalr	434(ra) # 80002d12 <argint>
  argint(2, &minor);
    80005b68:	f6840593          	addi	a1,s0,-152
    80005b6c:	4509                	li	a0,2
    80005b6e:	ffffd097          	auipc	ra,0xffffd
    80005b72:	1a4080e7          	jalr	420(ra) # 80002d12 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005b76:	08000613          	li	a2,128
    80005b7a:	f7040593          	addi	a1,s0,-144
    80005b7e:	4501                	li	a0,0
    80005b80:	ffffd097          	auipc	ra,0xffffd
    80005b84:	1d2080e7          	jalr	466(ra) # 80002d52 <argstr>
    80005b88:	02054b63          	bltz	a0,80005bbe <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005b8c:	f6841683          	lh	a3,-152(s0)
    80005b90:	f6c41603          	lh	a2,-148(s0)
    80005b94:	458d                	li	a1,3
    80005b96:	f7040513          	addi	a0,s0,-144
    80005b9a:	fffff097          	auipc	ra,0xfffff
    80005b9e:	77c080e7          	jalr	1916(ra) # 80005316 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005ba2:	cd11                	beqz	a0,80005bbe <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005ba4:	ffffe097          	auipc	ra,0xffffe
    80005ba8:	f8e080e7          	jalr	-114(ra) # 80003b32 <iunlockput>
  end_op();
    80005bac:	ffffe097          	auipc	ra,0xffffe
    80005bb0:	76e080e7          	jalr	1902(ra) # 8000431a <end_op>
  return 0;
    80005bb4:	4501                	li	a0,0
}
    80005bb6:	60ea                	ld	ra,152(sp)
    80005bb8:	644a                	ld	s0,144(sp)
    80005bba:	610d                	addi	sp,sp,160
    80005bbc:	8082                	ret
    end_op();
    80005bbe:	ffffe097          	auipc	ra,0xffffe
    80005bc2:	75c080e7          	jalr	1884(ra) # 8000431a <end_op>
    return -1;
    80005bc6:	557d                	li	a0,-1
    80005bc8:	b7fd                	j	80005bb6 <sys_mknod+0x6c>

0000000080005bca <sys_chdir>:

uint64
sys_chdir(void)
{
    80005bca:	7135                	addi	sp,sp,-160
    80005bcc:	ed06                	sd	ra,152(sp)
    80005bce:	e922                	sd	s0,144(sp)
    80005bd0:	e526                	sd	s1,136(sp)
    80005bd2:	e14a                	sd	s2,128(sp)
    80005bd4:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005bd6:	ffffc097          	auipc	ra,0xffffc
    80005bda:	dd6080e7          	jalr	-554(ra) # 800019ac <myproc>
    80005bde:	892a                	mv	s2,a0
  
  begin_op();
    80005be0:	ffffe097          	auipc	ra,0xffffe
    80005be4:	6bc080e7          	jalr	1724(ra) # 8000429c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005be8:	08000613          	li	a2,128
    80005bec:	f6040593          	addi	a1,s0,-160
    80005bf0:	4501                	li	a0,0
    80005bf2:	ffffd097          	auipc	ra,0xffffd
    80005bf6:	160080e7          	jalr	352(ra) # 80002d52 <argstr>
    80005bfa:	04054b63          	bltz	a0,80005c50 <sys_chdir+0x86>
    80005bfe:	f6040513          	addi	a0,s0,-160
    80005c02:	ffffe097          	auipc	ra,0xffffe
    80005c06:	47a080e7          	jalr	1146(ra) # 8000407c <namei>
    80005c0a:	84aa                	mv	s1,a0
    80005c0c:	c131                	beqz	a0,80005c50 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005c0e:	ffffe097          	auipc	ra,0xffffe
    80005c12:	cc2080e7          	jalr	-830(ra) # 800038d0 <ilock>
  if(ip->type != T_DIR){
    80005c16:	04449703          	lh	a4,68(s1)
    80005c1a:	4785                	li	a5,1
    80005c1c:	04f71063          	bne	a4,a5,80005c5c <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005c20:	8526                	mv	a0,s1
    80005c22:	ffffe097          	auipc	ra,0xffffe
    80005c26:	d70080e7          	jalr	-656(ra) # 80003992 <iunlock>
  iput(p->cwd);
    80005c2a:	15893503          	ld	a0,344(s2)
    80005c2e:	ffffe097          	auipc	ra,0xffffe
    80005c32:	e5c080e7          	jalr	-420(ra) # 80003a8a <iput>
  end_op();
    80005c36:	ffffe097          	auipc	ra,0xffffe
    80005c3a:	6e4080e7          	jalr	1764(ra) # 8000431a <end_op>
  p->cwd = ip;
    80005c3e:	14993c23          	sd	s1,344(s2)
  return 0;
    80005c42:	4501                	li	a0,0
}
    80005c44:	60ea                	ld	ra,152(sp)
    80005c46:	644a                	ld	s0,144(sp)
    80005c48:	64aa                	ld	s1,136(sp)
    80005c4a:	690a                	ld	s2,128(sp)
    80005c4c:	610d                	addi	sp,sp,160
    80005c4e:	8082                	ret
    end_op();
    80005c50:	ffffe097          	auipc	ra,0xffffe
    80005c54:	6ca080e7          	jalr	1738(ra) # 8000431a <end_op>
    return -1;
    80005c58:	557d                	li	a0,-1
    80005c5a:	b7ed                	j	80005c44 <sys_chdir+0x7a>
    iunlockput(ip);
    80005c5c:	8526                	mv	a0,s1
    80005c5e:	ffffe097          	auipc	ra,0xffffe
    80005c62:	ed4080e7          	jalr	-300(ra) # 80003b32 <iunlockput>
    end_op();
    80005c66:	ffffe097          	auipc	ra,0xffffe
    80005c6a:	6b4080e7          	jalr	1716(ra) # 8000431a <end_op>
    return -1;
    80005c6e:	557d                	li	a0,-1
    80005c70:	bfd1                	j	80005c44 <sys_chdir+0x7a>

0000000080005c72 <sys_exec>:

uint64
sys_exec(void)
{
    80005c72:	7145                	addi	sp,sp,-464
    80005c74:	e786                	sd	ra,456(sp)
    80005c76:	e3a2                	sd	s0,448(sp)
    80005c78:	ff26                	sd	s1,440(sp)
    80005c7a:	fb4a                	sd	s2,432(sp)
    80005c7c:	f74e                	sd	s3,424(sp)
    80005c7e:	f352                	sd	s4,416(sp)
    80005c80:	ef56                	sd	s5,408(sp)
    80005c82:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005c84:	e3840593          	addi	a1,s0,-456
    80005c88:	4505                	li	a0,1
    80005c8a:	ffffd097          	auipc	ra,0xffffd
    80005c8e:	0a8080e7          	jalr	168(ra) # 80002d32 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005c92:	08000613          	li	a2,128
    80005c96:	f4040593          	addi	a1,s0,-192
    80005c9a:	4501                	li	a0,0
    80005c9c:	ffffd097          	auipc	ra,0xffffd
    80005ca0:	0b6080e7          	jalr	182(ra) # 80002d52 <argstr>
    80005ca4:	87aa                	mv	a5,a0
    return -1;
    80005ca6:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005ca8:	0c07c363          	bltz	a5,80005d6e <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005cac:	10000613          	li	a2,256
    80005cb0:	4581                	li	a1,0
    80005cb2:	e4040513          	addi	a0,s0,-448
    80005cb6:	ffffb097          	auipc	ra,0xffffb
    80005cba:	01c080e7          	jalr	28(ra) # 80000cd2 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005cbe:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005cc2:	89a6                	mv	s3,s1
    80005cc4:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005cc6:	02000a13          	li	s4,32
    80005cca:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005cce:	00391513          	slli	a0,s2,0x3
    80005cd2:	e3040593          	addi	a1,s0,-464
    80005cd6:	e3843783          	ld	a5,-456(s0)
    80005cda:	953e                	add	a0,a0,a5
    80005cdc:	ffffd097          	auipc	ra,0xffffd
    80005ce0:	f98080e7          	jalr	-104(ra) # 80002c74 <fetchaddr>
    80005ce4:	02054a63          	bltz	a0,80005d18 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005ce8:	e3043783          	ld	a5,-464(s0)
    80005cec:	c3b9                	beqz	a5,80005d32 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005cee:	ffffb097          	auipc	ra,0xffffb
    80005cf2:	df8080e7          	jalr	-520(ra) # 80000ae6 <kalloc>
    80005cf6:	85aa                	mv	a1,a0
    80005cf8:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005cfc:	cd11                	beqz	a0,80005d18 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005cfe:	6605                	lui	a2,0x1
    80005d00:	e3043503          	ld	a0,-464(s0)
    80005d04:	ffffd097          	auipc	ra,0xffffd
    80005d08:	fc2080e7          	jalr	-62(ra) # 80002cc6 <fetchstr>
    80005d0c:	00054663          	bltz	a0,80005d18 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005d10:	0905                	addi	s2,s2,1
    80005d12:	09a1                	addi	s3,s3,8
    80005d14:	fb491be3          	bne	s2,s4,80005cca <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d18:	f4040913          	addi	s2,s0,-192
    80005d1c:	6088                	ld	a0,0(s1)
    80005d1e:	c539                	beqz	a0,80005d6c <sys_exec+0xfa>
    kfree(argv[i]);
    80005d20:	ffffb097          	auipc	ra,0xffffb
    80005d24:	cc8080e7          	jalr	-824(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d28:	04a1                	addi	s1,s1,8
    80005d2a:	ff2499e3          	bne	s1,s2,80005d1c <sys_exec+0xaa>
  return -1;
    80005d2e:	557d                	li	a0,-1
    80005d30:	a83d                	j	80005d6e <sys_exec+0xfc>
      argv[i] = 0;
    80005d32:	0a8e                	slli	s5,s5,0x3
    80005d34:	fc0a8793          	addi	a5,s5,-64
    80005d38:	00878ab3          	add	s5,a5,s0
    80005d3c:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005d40:	e4040593          	addi	a1,s0,-448
    80005d44:	f4040513          	addi	a0,s0,-192
    80005d48:	fffff097          	auipc	ra,0xfffff
    80005d4c:	096080e7          	jalr	150(ra) # 80004dde <exec>
    80005d50:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d52:	f4040993          	addi	s3,s0,-192
    80005d56:	6088                	ld	a0,0(s1)
    80005d58:	c901                	beqz	a0,80005d68 <sys_exec+0xf6>
    kfree(argv[i]);
    80005d5a:	ffffb097          	auipc	ra,0xffffb
    80005d5e:	c8e080e7          	jalr	-882(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005d62:	04a1                	addi	s1,s1,8
    80005d64:	ff3499e3          	bne	s1,s3,80005d56 <sys_exec+0xe4>
  return ret;
    80005d68:	854a                	mv	a0,s2
    80005d6a:	a011                	j	80005d6e <sys_exec+0xfc>
  return -1;
    80005d6c:	557d                	li	a0,-1
}
    80005d6e:	60be                	ld	ra,456(sp)
    80005d70:	641e                	ld	s0,448(sp)
    80005d72:	74fa                	ld	s1,440(sp)
    80005d74:	795a                	ld	s2,432(sp)
    80005d76:	79ba                	ld	s3,424(sp)
    80005d78:	7a1a                	ld	s4,416(sp)
    80005d7a:	6afa                	ld	s5,408(sp)
    80005d7c:	6179                	addi	sp,sp,464
    80005d7e:	8082                	ret

0000000080005d80 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005d80:	7139                	addi	sp,sp,-64
    80005d82:	fc06                	sd	ra,56(sp)
    80005d84:	f822                	sd	s0,48(sp)
    80005d86:	f426                	sd	s1,40(sp)
    80005d88:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005d8a:	ffffc097          	auipc	ra,0xffffc
    80005d8e:	c22080e7          	jalr	-990(ra) # 800019ac <myproc>
    80005d92:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005d94:	fd840593          	addi	a1,s0,-40
    80005d98:	4501                	li	a0,0
    80005d9a:	ffffd097          	auipc	ra,0xffffd
    80005d9e:	f98080e7          	jalr	-104(ra) # 80002d32 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005da2:	fc840593          	addi	a1,s0,-56
    80005da6:	fd040513          	addi	a0,s0,-48
    80005daa:	fffff097          	auipc	ra,0xfffff
    80005dae:	cea080e7          	jalr	-790(ra) # 80004a94 <pipealloc>
    return -1;
    80005db2:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005db4:	0c054463          	bltz	a0,80005e7c <sys_pipe+0xfc>
  fd0 = -1;
    80005db8:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005dbc:	fd043503          	ld	a0,-48(s0)
    80005dc0:	fffff097          	auipc	ra,0xfffff
    80005dc4:	514080e7          	jalr	1300(ra) # 800052d4 <fdalloc>
    80005dc8:	fca42223          	sw	a0,-60(s0)
    80005dcc:	08054b63          	bltz	a0,80005e62 <sys_pipe+0xe2>
    80005dd0:	fc843503          	ld	a0,-56(s0)
    80005dd4:	fffff097          	auipc	ra,0xfffff
    80005dd8:	500080e7          	jalr	1280(ra) # 800052d4 <fdalloc>
    80005ddc:	fca42023          	sw	a0,-64(s0)
    80005de0:	06054863          	bltz	a0,80005e50 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005de4:	4691                	li	a3,4
    80005de6:	fc440613          	addi	a2,s0,-60
    80005dea:	fd843583          	ld	a1,-40(s0)
    80005dee:	6ca8                	ld	a0,88(s1)
    80005df0:	ffffc097          	auipc	ra,0xffffc
    80005df4:	87c080e7          	jalr	-1924(ra) # 8000166c <copyout>
    80005df8:	02054063          	bltz	a0,80005e18 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005dfc:	4691                	li	a3,4
    80005dfe:	fc040613          	addi	a2,s0,-64
    80005e02:	fd843583          	ld	a1,-40(s0)
    80005e06:	0591                	addi	a1,a1,4
    80005e08:	6ca8                	ld	a0,88(s1)
    80005e0a:	ffffc097          	auipc	ra,0xffffc
    80005e0e:	862080e7          	jalr	-1950(ra) # 8000166c <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005e12:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005e14:	06055463          	bgez	a0,80005e7c <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005e18:	fc442783          	lw	a5,-60(s0)
    80005e1c:	07e9                	addi	a5,a5,26
    80005e1e:	078e                	slli	a5,a5,0x3
    80005e20:	97a6                	add	a5,a5,s1
    80005e22:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80005e26:	fc042783          	lw	a5,-64(s0)
    80005e2a:	07e9                	addi	a5,a5,26
    80005e2c:	078e                	slli	a5,a5,0x3
    80005e2e:	94be                	add	s1,s1,a5
    80005e30:	0004b423          	sd	zero,8(s1)
    fileclose(rf);
    80005e34:	fd043503          	ld	a0,-48(s0)
    80005e38:	fffff097          	auipc	ra,0xfffff
    80005e3c:	92c080e7          	jalr	-1748(ra) # 80004764 <fileclose>
    fileclose(wf);
    80005e40:	fc843503          	ld	a0,-56(s0)
    80005e44:	fffff097          	auipc	ra,0xfffff
    80005e48:	920080e7          	jalr	-1760(ra) # 80004764 <fileclose>
    return -1;
    80005e4c:	57fd                	li	a5,-1
    80005e4e:	a03d                	j	80005e7c <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005e50:	fc442783          	lw	a5,-60(s0)
    80005e54:	0007c763          	bltz	a5,80005e62 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005e58:	07e9                	addi	a5,a5,26
    80005e5a:	078e                	slli	a5,a5,0x3
    80005e5c:	97a6                	add	a5,a5,s1
    80005e5e:	0007b423          	sd	zero,8(a5)
    fileclose(rf);
    80005e62:	fd043503          	ld	a0,-48(s0)
    80005e66:	fffff097          	auipc	ra,0xfffff
    80005e6a:	8fe080e7          	jalr	-1794(ra) # 80004764 <fileclose>
    fileclose(wf);
    80005e6e:	fc843503          	ld	a0,-56(s0)
    80005e72:	fffff097          	auipc	ra,0xfffff
    80005e76:	8f2080e7          	jalr	-1806(ra) # 80004764 <fileclose>
    return -1;
    80005e7a:	57fd                	li	a5,-1
}
    80005e7c:	853e                	mv	a0,a5
    80005e7e:	70e2                	ld	ra,56(sp)
    80005e80:	7442                	ld	s0,48(sp)
    80005e82:	74a2                	ld	s1,40(sp)
    80005e84:	6121                	addi	sp,sp,64
    80005e86:	8082                	ret
	...

0000000080005e90 <kernelvec>:
    80005e90:	7111                	addi	sp,sp,-256
    80005e92:	e006                	sd	ra,0(sp)
    80005e94:	e40a                	sd	sp,8(sp)
    80005e96:	e80e                	sd	gp,16(sp)
    80005e98:	ec12                	sd	tp,24(sp)
    80005e9a:	f016                	sd	t0,32(sp)
    80005e9c:	f41a                	sd	t1,40(sp)
    80005e9e:	f81e                	sd	t2,48(sp)
    80005ea0:	fc22                	sd	s0,56(sp)
    80005ea2:	e0a6                	sd	s1,64(sp)
    80005ea4:	e4aa                	sd	a0,72(sp)
    80005ea6:	e8ae                	sd	a1,80(sp)
    80005ea8:	ecb2                	sd	a2,88(sp)
    80005eaa:	f0b6                	sd	a3,96(sp)
    80005eac:	f4ba                	sd	a4,104(sp)
    80005eae:	f8be                	sd	a5,112(sp)
    80005eb0:	fcc2                	sd	a6,120(sp)
    80005eb2:	e146                	sd	a7,128(sp)
    80005eb4:	e54a                	sd	s2,136(sp)
    80005eb6:	e94e                	sd	s3,144(sp)
    80005eb8:	ed52                	sd	s4,152(sp)
    80005eba:	f156                	sd	s5,160(sp)
    80005ebc:	f55a                	sd	s6,168(sp)
    80005ebe:	f95e                	sd	s7,176(sp)
    80005ec0:	fd62                	sd	s8,184(sp)
    80005ec2:	e1e6                	sd	s9,192(sp)
    80005ec4:	e5ea                	sd	s10,200(sp)
    80005ec6:	e9ee                	sd	s11,208(sp)
    80005ec8:	edf2                	sd	t3,216(sp)
    80005eca:	f1f6                	sd	t4,224(sp)
    80005ecc:	f5fa                	sd	t5,232(sp)
    80005ece:	f9fe                	sd	t6,240(sp)
    80005ed0:	c71fc0ef          	jal	ra,80002b40 <kerneltrap>
    80005ed4:	6082                	ld	ra,0(sp)
    80005ed6:	6122                	ld	sp,8(sp)
    80005ed8:	61c2                	ld	gp,16(sp)
    80005eda:	7282                	ld	t0,32(sp)
    80005edc:	7322                	ld	t1,40(sp)
    80005ede:	73c2                	ld	t2,48(sp)
    80005ee0:	7462                	ld	s0,56(sp)
    80005ee2:	6486                	ld	s1,64(sp)
    80005ee4:	6526                	ld	a0,72(sp)
    80005ee6:	65c6                	ld	a1,80(sp)
    80005ee8:	6666                	ld	a2,88(sp)
    80005eea:	7686                	ld	a3,96(sp)
    80005eec:	7726                	ld	a4,104(sp)
    80005eee:	77c6                	ld	a5,112(sp)
    80005ef0:	7866                	ld	a6,120(sp)
    80005ef2:	688a                	ld	a7,128(sp)
    80005ef4:	692a                	ld	s2,136(sp)
    80005ef6:	69ca                	ld	s3,144(sp)
    80005ef8:	6a6a                	ld	s4,152(sp)
    80005efa:	7a8a                	ld	s5,160(sp)
    80005efc:	7b2a                	ld	s6,168(sp)
    80005efe:	7bca                	ld	s7,176(sp)
    80005f00:	7c6a                	ld	s8,184(sp)
    80005f02:	6c8e                	ld	s9,192(sp)
    80005f04:	6d2e                	ld	s10,200(sp)
    80005f06:	6dce                	ld	s11,208(sp)
    80005f08:	6e6e                	ld	t3,216(sp)
    80005f0a:	7e8e                	ld	t4,224(sp)
    80005f0c:	7f2e                	ld	t5,232(sp)
    80005f0e:	7fce                	ld	t6,240(sp)
    80005f10:	6111                	addi	sp,sp,256
    80005f12:	10200073          	sret
    80005f16:	00000013          	nop
    80005f1a:	00000013          	nop
    80005f1e:	0001                	nop

0000000080005f20 <timervec>:
    80005f20:	34051573          	csrrw	a0,mscratch,a0
    80005f24:	e10c                	sd	a1,0(a0)
    80005f26:	e510                	sd	a2,8(a0)
    80005f28:	e914                	sd	a3,16(a0)
    80005f2a:	6d0c                	ld	a1,24(a0)
    80005f2c:	7110                	ld	a2,32(a0)
    80005f2e:	6194                	ld	a3,0(a1)
    80005f30:	96b2                	add	a3,a3,a2
    80005f32:	e194                	sd	a3,0(a1)
    80005f34:	4589                	li	a1,2
    80005f36:	14459073          	csrw	sip,a1
    80005f3a:	6914                	ld	a3,16(a0)
    80005f3c:	6510                	ld	a2,8(a0)
    80005f3e:	610c                	ld	a1,0(a0)
    80005f40:	34051573          	csrrw	a0,mscratch,a0
    80005f44:	30200073          	mret
	...

0000000080005f4a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005f4a:	1141                	addi	sp,sp,-16
    80005f4c:	e422                	sd	s0,8(sp)
    80005f4e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005f50:	0c0007b7          	lui	a5,0xc000
    80005f54:	4705                	li	a4,1
    80005f56:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005f58:	c3d8                	sw	a4,4(a5)
}
    80005f5a:	6422                	ld	s0,8(sp)
    80005f5c:	0141                	addi	sp,sp,16
    80005f5e:	8082                	ret

0000000080005f60 <plicinithart>:

void
plicinithart(void)
{
    80005f60:	1141                	addi	sp,sp,-16
    80005f62:	e406                	sd	ra,8(sp)
    80005f64:	e022                	sd	s0,0(sp)
    80005f66:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005f68:	ffffc097          	auipc	ra,0xffffc
    80005f6c:	a18080e7          	jalr	-1512(ra) # 80001980 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005f70:	0085171b          	slliw	a4,a0,0x8
    80005f74:	0c0027b7          	lui	a5,0xc002
    80005f78:	97ba                	add	a5,a5,a4
    80005f7a:	40200713          	li	a4,1026
    80005f7e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005f82:	00d5151b          	slliw	a0,a0,0xd
    80005f86:	0c2017b7          	lui	a5,0xc201
    80005f8a:	97aa                	add	a5,a5,a0
    80005f8c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005f90:	60a2                	ld	ra,8(sp)
    80005f92:	6402                	ld	s0,0(sp)
    80005f94:	0141                	addi	sp,sp,16
    80005f96:	8082                	ret

0000000080005f98 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005f98:	1141                	addi	sp,sp,-16
    80005f9a:	e406                	sd	ra,8(sp)
    80005f9c:	e022                	sd	s0,0(sp)
    80005f9e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005fa0:	ffffc097          	auipc	ra,0xffffc
    80005fa4:	9e0080e7          	jalr	-1568(ra) # 80001980 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005fa8:	00d5151b          	slliw	a0,a0,0xd
    80005fac:	0c2017b7          	lui	a5,0xc201
    80005fb0:	97aa                	add	a5,a5,a0
  return irq;
}
    80005fb2:	43c8                	lw	a0,4(a5)
    80005fb4:	60a2                	ld	ra,8(sp)
    80005fb6:	6402                	ld	s0,0(sp)
    80005fb8:	0141                	addi	sp,sp,16
    80005fba:	8082                	ret

0000000080005fbc <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005fbc:	1101                	addi	sp,sp,-32
    80005fbe:	ec06                	sd	ra,24(sp)
    80005fc0:	e822                	sd	s0,16(sp)
    80005fc2:	e426                	sd	s1,8(sp)
    80005fc4:	1000                	addi	s0,sp,32
    80005fc6:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005fc8:	ffffc097          	auipc	ra,0xffffc
    80005fcc:	9b8080e7          	jalr	-1608(ra) # 80001980 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005fd0:	00d5151b          	slliw	a0,a0,0xd
    80005fd4:	0c2017b7          	lui	a5,0xc201
    80005fd8:	97aa                	add	a5,a5,a0
    80005fda:	c3c4                	sw	s1,4(a5)
}
    80005fdc:	60e2                	ld	ra,24(sp)
    80005fde:	6442                	ld	s0,16(sp)
    80005fe0:	64a2                	ld	s1,8(sp)
    80005fe2:	6105                	addi	sp,sp,32
    80005fe4:	8082                	ret

0000000080005fe6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005fe6:	1141                	addi	sp,sp,-16
    80005fe8:	e406                	sd	ra,8(sp)
    80005fea:	e022                	sd	s0,0(sp)
    80005fec:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005fee:	479d                	li	a5,7
    80005ff0:	04a7cc63          	blt	a5,a0,80006048 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005ff4:	0001c797          	auipc	a5,0x1c
    80005ff8:	e4c78793          	addi	a5,a5,-436 # 80021e40 <disk>
    80005ffc:	97aa                	add	a5,a5,a0
    80005ffe:	0187c783          	lbu	a5,24(a5)
    80006002:	ebb9                	bnez	a5,80006058 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006004:	00451693          	slli	a3,a0,0x4
    80006008:	0001c797          	auipc	a5,0x1c
    8000600c:	e3878793          	addi	a5,a5,-456 # 80021e40 <disk>
    80006010:	6398                	ld	a4,0(a5)
    80006012:	9736                	add	a4,a4,a3
    80006014:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80006018:	6398                	ld	a4,0(a5)
    8000601a:	9736                	add	a4,a4,a3
    8000601c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006020:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006024:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006028:	97aa                	add	a5,a5,a0
    8000602a:	4705                	li	a4,1
    8000602c:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80006030:	0001c517          	auipc	a0,0x1c
    80006034:	e2850513          	addi	a0,a0,-472 # 80021e58 <disk+0x18>
    80006038:	ffffc097          	auipc	ra,0xffffc
    8000603c:	1ac080e7          	jalr	428(ra) # 800021e4 <wakeup>
}
    80006040:	60a2                	ld	ra,8(sp)
    80006042:	6402                	ld	s0,0(sp)
    80006044:	0141                	addi	sp,sp,16
    80006046:	8082                	ret
    panic("free_desc 1");
    80006048:	00002517          	auipc	a0,0x2
    8000604c:	70850513          	addi	a0,a0,1800 # 80008750 <syscalls+0x300>
    80006050:	ffffa097          	auipc	ra,0xffffa
    80006054:	4f0080e7          	jalr	1264(ra) # 80000540 <panic>
    panic("free_desc 2");
    80006058:	00002517          	auipc	a0,0x2
    8000605c:	70850513          	addi	a0,a0,1800 # 80008760 <syscalls+0x310>
    80006060:	ffffa097          	auipc	ra,0xffffa
    80006064:	4e0080e7          	jalr	1248(ra) # 80000540 <panic>

0000000080006068 <virtio_disk_init>:
{
    80006068:	1101                	addi	sp,sp,-32
    8000606a:	ec06                	sd	ra,24(sp)
    8000606c:	e822                	sd	s0,16(sp)
    8000606e:	e426                	sd	s1,8(sp)
    80006070:	e04a                	sd	s2,0(sp)
    80006072:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80006074:	00002597          	auipc	a1,0x2
    80006078:	6fc58593          	addi	a1,a1,1788 # 80008770 <syscalls+0x320>
    8000607c:	0001c517          	auipc	a0,0x1c
    80006080:	eec50513          	addi	a0,a0,-276 # 80021f68 <disk+0x128>
    80006084:	ffffb097          	auipc	ra,0xffffb
    80006088:	ac2080e7          	jalr	-1342(ra) # 80000b46 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    8000608c:	100017b7          	lui	a5,0x10001
    80006090:	4398                	lw	a4,0(a5)
    80006092:	2701                	sext.w	a4,a4
    80006094:	747277b7          	lui	a5,0x74727
    80006098:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    8000609c:	14f71b63          	bne	a4,a5,800061f2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800060a0:	100017b7          	lui	a5,0x10001
    800060a4:	43dc                	lw	a5,4(a5)
    800060a6:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800060a8:	4709                	li	a4,2
    800060aa:	14e79463          	bne	a5,a4,800061f2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800060ae:	100017b7          	lui	a5,0x10001
    800060b2:	479c                	lw	a5,8(a5)
    800060b4:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    800060b6:	12e79e63          	bne	a5,a4,800061f2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    800060ba:	100017b7          	lui	a5,0x10001
    800060be:	47d8                	lw	a4,12(a5)
    800060c0:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    800060c2:	554d47b7          	lui	a5,0x554d4
    800060c6:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    800060ca:	12f71463          	bne	a4,a5,800061f2 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    800060ce:	100017b7          	lui	a5,0x10001
    800060d2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    800060d6:	4705                	li	a4,1
    800060d8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060da:	470d                	li	a4,3
    800060dc:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    800060de:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    800060e0:	c7ffe6b7          	lui	a3,0xc7ffe
    800060e4:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc7df>
    800060e8:	8f75                	and	a4,a4,a3
    800060ea:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    800060ec:	472d                	li	a4,11
    800060ee:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    800060f0:	5bbc                	lw	a5,112(a5)
    800060f2:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    800060f6:	8ba1                	andi	a5,a5,8
    800060f8:	10078563          	beqz	a5,80006202 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    800060fc:	100017b7          	lui	a5,0x10001
    80006100:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006104:	43fc                	lw	a5,68(a5)
    80006106:	2781                	sext.w	a5,a5
    80006108:	10079563          	bnez	a5,80006212 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    8000610c:	100017b7          	lui	a5,0x10001
    80006110:	5bdc                	lw	a5,52(a5)
    80006112:	2781                	sext.w	a5,a5
  if(max == 0)
    80006114:	10078763          	beqz	a5,80006222 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80006118:	471d                	li	a4,7
    8000611a:	10f77c63          	bgeu	a4,a5,80006232 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    8000611e:	ffffb097          	auipc	ra,0xffffb
    80006122:	9c8080e7          	jalr	-1592(ra) # 80000ae6 <kalloc>
    80006126:	0001c497          	auipc	s1,0x1c
    8000612a:	d1a48493          	addi	s1,s1,-742 # 80021e40 <disk>
    8000612e:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006130:	ffffb097          	auipc	ra,0xffffb
    80006134:	9b6080e7          	jalr	-1610(ra) # 80000ae6 <kalloc>
    80006138:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    8000613a:	ffffb097          	auipc	ra,0xffffb
    8000613e:	9ac080e7          	jalr	-1620(ra) # 80000ae6 <kalloc>
    80006142:	87aa                	mv	a5,a0
    80006144:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006146:	6088                	ld	a0,0(s1)
    80006148:	cd6d                	beqz	a0,80006242 <virtio_disk_init+0x1da>
    8000614a:	0001c717          	auipc	a4,0x1c
    8000614e:	cfe73703          	ld	a4,-770(a4) # 80021e48 <disk+0x8>
    80006152:	cb65                	beqz	a4,80006242 <virtio_disk_init+0x1da>
    80006154:	c7fd                	beqz	a5,80006242 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80006156:	6605                	lui	a2,0x1
    80006158:	4581                	li	a1,0
    8000615a:	ffffb097          	auipc	ra,0xffffb
    8000615e:	b78080e7          	jalr	-1160(ra) # 80000cd2 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006162:	0001c497          	auipc	s1,0x1c
    80006166:	cde48493          	addi	s1,s1,-802 # 80021e40 <disk>
    8000616a:	6605                	lui	a2,0x1
    8000616c:	4581                	li	a1,0
    8000616e:	6488                	ld	a0,8(s1)
    80006170:	ffffb097          	auipc	ra,0xffffb
    80006174:	b62080e7          	jalr	-1182(ra) # 80000cd2 <memset>
  memset(disk.used, 0, PGSIZE);
    80006178:	6605                	lui	a2,0x1
    8000617a:	4581                	li	a1,0
    8000617c:	6888                	ld	a0,16(s1)
    8000617e:	ffffb097          	auipc	ra,0xffffb
    80006182:	b54080e7          	jalr	-1196(ra) # 80000cd2 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006186:	100017b7          	lui	a5,0x10001
    8000618a:	4721                	li	a4,8
    8000618c:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    8000618e:	4098                	lw	a4,0(s1)
    80006190:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006194:	40d8                	lw	a4,4(s1)
    80006196:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    8000619a:	6498                	ld	a4,8(s1)
    8000619c:	0007069b          	sext.w	a3,a4
    800061a0:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    800061a4:	9701                	srai	a4,a4,0x20
    800061a6:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    800061aa:	6898                	ld	a4,16(s1)
    800061ac:	0007069b          	sext.w	a3,a4
    800061b0:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    800061b4:	9701                	srai	a4,a4,0x20
    800061b6:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    800061ba:	4705                	li	a4,1
    800061bc:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    800061be:	00e48c23          	sb	a4,24(s1)
    800061c2:	00e48ca3          	sb	a4,25(s1)
    800061c6:	00e48d23          	sb	a4,26(s1)
    800061ca:	00e48da3          	sb	a4,27(s1)
    800061ce:	00e48e23          	sb	a4,28(s1)
    800061d2:	00e48ea3          	sb	a4,29(s1)
    800061d6:	00e48f23          	sb	a4,30(s1)
    800061da:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    800061de:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    800061e2:	0727a823          	sw	s2,112(a5)
}
    800061e6:	60e2                	ld	ra,24(sp)
    800061e8:	6442                	ld	s0,16(sp)
    800061ea:	64a2                	ld	s1,8(sp)
    800061ec:	6902                	ld	s2,0(sp)
    800061ee:	6105                	addi	sp,sp,32
    800061f0:	8082                	ret
    panic("could not find virtio disk");
    800061f2:	00002517          	auipc	a0,0x2
    800061f6:	58e50513          	addi	a0,a0,1422 # 80008780 <syscalls+0x330>
    800061fa:	ffffa097          	auipc	ra,0xffffa
    800061fe:	346080e7          	jalr	838(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006202:	00002517          	auipc	a0,0x2
    80006206:	59e50513          	addi	a0,a0,1438 # 800087a0 <syscalls+0x350>
    8000620a:	ffffa097          	auipc	ra,0xffffa
    8000620e:	336080e7          	jalr	822(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    80006212:	00002517          	auipc	a0,0x2
    80006216:	5ae50513          	addi	a0,a0,1454 # 800087c0 <syscalls+0x370>
    8000621a:	ffffa097          	auipc	ra,0xffffa
    8000621e:	326080e7          	jalr	806(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    80006222:	00002517          	auipc	a0,0x2
    80006226:	5be50513          	addi	a0,a0,1470 # 800087e0 <syscalls+0x390>
    8000622a:	ffffa097          	auipc	ra,0xffffa
    8000622e:	316080e7          	jalr	790(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    80006232:	00002517          	auipc	a0,0x2
    80006236:	5ce50513          	addi	a0,a0,1486 # 80008800 <syscalls+0x3b0>
    8000623a:	ffffa097          	auipc	ra,0xffffa
    8000623e:	306080e7          	jalr	774(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    80006242:	00002517          	auipc	a0,0x2
    80006246:	5de50513          	addi	a0,a0,1502 # 80008820 <syscalls+0x3d0>
    8000624a:	ffffa097          	auipc	ra,0xffffa
    8000624e:	2f6080e7          	jalr	758(ra) # 80000540 <panic>

0000000080006252 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006252:	7119                	addi	sp,sp,-128
    80006254:	fc86                	sd	ra,120(sp)
    80006256:	f8a2                	sd	s0,112(sp)
    80006258:	f4a6                	sd	s1,104(sp)
    8000625a:	f0ca                	sd	s2,96(sp)
    8000625c:	ecce                	sd	s3,88(sp)
    8000625e:	e8d2                	sd	s4,80(sp)
    80006260:	e4d6                	sd	s5,72(sp)
    80006262:	e0da                	sd	s6,64(sp)
    80006264:	fc5e                	sd	s7,56(sp)
    80006266:	f862                	sd	s8,48(sp)
    80006268:	f466                	sd	s9,40(sp)
    8000626a:	f06a                	sd	s10,32(sp)
    8000626c:	ec6e                	sd	s11,24(sp)
    8000626e:	0100                	addi	s0,sp,128
    80006270:	8aaa                	mv	s5,a0
    80006272:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006274:	00c52d03          	lw	s10,12(a0)
    80006278:	001d1d1b          	slliw	s10,s10,0x1
    8000627c:	1d02                	slli	s10,s10,0x20
    8000627e:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80006282:	0001c517          	auipc	a0,0x1c
    80006286:	ce650513          	addi	a0,a0,-794 # 80021f68 <disk+0x128>
    8000628a:	ffffb097          	auipc	ra,0xffffb
    8000628e:	94c080e7          	jalr	-1716(ra) # 80000bd6 <acquire>
  for(int i = 0; i < 3; i++){
    80006292:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006294:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006296:	0001cb97          	auipc	s7,0x1c
    8000629a:	baab8b93          	addi	s7,s7,-1110 # 80021e40 <disk>
  for(int i = 0; i < 3; i++){
    8000629e:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    800062a0:	0001cc97          	auipc	s9,0x1c
    800062a4:	cc8c8c93          	addi	s9,s9,-824 # 80021f68 <disk+0x128>
    800062a8:	a08d                	j	8000630a <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    800062aa:	00fb8733          	add	a4,s7,a5
    800062ae:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    800062b2:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    800062b4:	0207c563          	bltz	a5,800062de <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    800062b8:	2905                	addiw	s2,s2,1
    800062ba:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    800062bc:	05690c63          	beq	s2,s6,80006314 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    800062c0:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    800062c2:	0001c717          	auipc	a4,0x1c
    800062c6:	b7e70713          	addi	a4,a4,-1154 # 80021e40 <disk>
    800062ca:	87ce                	mv	a5,s3
    if(disk.free[i]){
    800062cc:	01874683          	lbu	a3,24(a4)
    800062d0:	fee9                	bnez	a3,800062aa <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    800062d2:	2785                	addiw	a5,a5,1
    800062d4:	0705                	addi	a4,a4,1
    800062d6:	fe979be3          	bne	a5,s1,800062cc <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    800062da:	57fd                	li	a5,-1
    800062dc:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    800062de:	01205d63          	blez	s2,800062f8 <virtio_disk_rw+0xa6>
    800062e2:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    800062e4:	000a2503          	lw	a0,0(s4)
    800062e8:	00000097          	auipc	ra,0x0
    800062ec:	cfe080e7          	jalr	-770(ra) # 80005fe6 <free_desc>
      for(int j = 0; j < i; j++)
    800062f0:	2d85                	addiw	s11,s11,1
    800062f2:	0a11                	addi	s4,s4,4
    800062f4:	ff2d98e3          	bne	s11,s2,800062e4 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    800062f8:	85e6                	mv	a1,s9
    800062fa:	0001c517          	auipc	a0,0x1c
    800062fe:	b5e50513          	addi	a0,a0,-1186 # 80021e58 <disk+0x18>
    80006302:	ffffc097          	auipc	ra,0xffffc
    80006306:	e7e080e7          	jalr	-386(ra) # 80002180 <sleep>
  for(int i = 0; i < 3; i++){
    8000630a:	f8040a13          	addi	s4,s0,-128
{
    8000630e:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    80006310:	894e                	mv	s2,s3
    80006312:	b77d                	j	800062c0 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006314:	f8042503          	lw	a0,-128(s0)
    80006318:	00a50713          	addi	a4,a0,10
    8000631c:	0712                	slli	a4,a4,0x4

  if(write)
    8000631e:	0001c797          	auipc	a5,0x1c
    80006322:	b2278793          	addi	a5,a5,-1246 # 80021e40 <disk>
    80006326:	00e786b3          	add	a3,a5,a4
    8000632a:	01803633          	snez	a2,s8
    8000632e:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006330:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006334:	01a6b823          	sd	s10,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006338:	f6070613          	addi	a2,a4,-160
    8000633c:	6394                	ld	a3,0(a5)
    8000633e:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006340:	00870593          	addi	a1,a4,8
    80006344:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006346:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006348:	0007b803          	ld	a6,0(a5)
    8000634c:	9642                	add	a2,a2,a6
    8000634e:	46c1                	li	a3,16
    80006350:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006352:	4585                	li	a1,1
    80006354:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80006358:	f8442683          	lw	a3,-124(s0)
    8000635c:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006360:	0692                	slli	a3,a3,0x4
    80006362:	9836                	add	a6,a6,a3
    80006364:	058a8613          	addi	a2,s5,88
    80006368:	00c83023          	sd	a2,0(a6) # fffffffffff00000 <end+0xffffffff7fede080>
  disk.desc[idx[1]].len = BSIZE;
    8000636c:	0007b803          	ld	a6,0(a5)
    80006370:	96c2                	add	a3,a3,a6
    80006372:	40000613          	li	a2,1024
    80006376:	c690                	sw	a2,8(a3)
  if(write)
    80006378:	001c3613          	seqz	a2,s8
    8000637c:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006380:	00166613          	ori	a2,a2,1
    80006384:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006388:	f8842603          	lw	a2,-120(s0)
    8000638c:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006390:	00250693          	addi	a3,a0,2
    80006394:	0692                	slli	a3,a3,0x4
    80006396:	96be                	add	a3,a3,a5
    80006398:	58fd                	li	a7,-1
    8000639a:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000639e:	0612                	slli	a2,a2,0x4
    800063a0:	9832                	add	a6,a6,a2
    800063a2:	f9070713          	addi	a4,a4,-112
    800063a6:	973e                	add	a4,a4,a5
    800063a8:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    800063ac:	6398                	ld	a4,0(a5)
    800063ae:	9732                	add	a4,a4,a2
    800063b0:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800063b2:	4609                	li	a2,2
    800063b4:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    800063b8:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    800063bc:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    800063c0:	0156b423          	sd	s5,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    800063c4:	6794                	ld	a3,8(a5)
    800063c6:	0026d703          	lhu	a4,2(a3)
    800063ca:	8b1d                	andi	a4,a4,7
    800063cc:	0706                	slli	a4,a4,0x1
    800063ce:	96ba                	add	a3,a3,a4
    800063d0:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    800063d4:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800063d8:	6798                	ld	a4,8(a5)
    800063da:	00275783          	lhu	a5,2(a4)
    800063de:	2785                	addiw	a5,a5,1
    800063e0:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800063e4:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800063e8:	100017b7          	lui	a5,0x10001
    800063ec:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800063f0:	004aa783          	lw	a5,4(s5)
    sleep(b, &disk.vdisk_lock);
    800063f4:	0001c917          	auipc	s2,0x1c
    800063f8:	b7490913          	addi	s2,s2,-1164 # 80021f68 <disk+0x128>
  while(b->disk == 1) {
    800063fc:	4485                	li	s1,1
    800063fe:	00b79c63          	bne	a5,a1,80006416 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    80006402:	85ca                	mv	a1,s2
    80006404:	8556                	mv	a0,s5
    80006406:	ffffc097          	auipc	ra,0xffffc
    8000640a:	d7a080e7          	jalr	-646(ra) # 80002180 <sleep>
  while(b->disk == 1) {
    8000640e:	004aa783          	lw	a5,4(s5)
    80006412:	fe9788e3          	beq	a5,s1,80006402 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    80006416:	f8042903          	lw	s2,-128(s0)
    8000641a:	00290713          	addi	a4,s2,2
    8000641e:	0712                	slli	a4,a4,0x4
    80006420:	0001c797          	auipc	a5,0x1c
    80006424:	a2078793          	addi	a5,a5,-1504 # 80021e40 <disk>
    80006428:	97ba                	add	a5,a5,a4
    8000642a:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    8000642e:	0001c997          	auipc	s3,0x1c
    80006432:	a1298993          	addi	s3,s3,-1518 # 80021e40 <disk>
    80006436:	00491713          	slli	a4,s2,0x4
    8000643a:	0009b783          	ld	a5,0(s3)
    8000643e:	97ba                	add	a5,a5,a4
    80006440:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006444:	854a                	mv	a0,s2
    80006446:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000644a:	00000097          	auipc	ra,0x0
    8000644e:	b9c080e7          	jalr	-1124(ra) # 80005fe6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006452:	8885                	andi	s1,s1,1
    80006454:	f0ed                	bnez	s1,80006436 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006456:	0001c517          	auipc	a0,0x1c
    8000645a:	b1250513          	addi	a0,a0,-1262 # 80021f68 <disk+0x128>
    8000645e:	ffffb097          	auipc	ra,0xffffb
    80006462:	82c080e7          	jalr	-2004(ra) # 80000c8a <release>
}
    80006466:	70e6                	ld	ra,120(sp)
    80006468:	7446                	ld	s0,112(sp)
    8000646a:	74a6                	ld	s1,104(sp)
    8000646c:	7906                	ld	s2,96(sp)
    8000646e:	69e6                	ld	s3,88(sp)
    80006470:	6a46                	ld	s4,80(sp)
    80006472:	6aa6                	ld	s5,72(sp)
    80006474:	6b06                	ld	s6,64(sp)
    80006476:	7be2                	ld	s7,56(sp)
    80006478:	7c42                	ld	s8,48(sp)
    8000647a:	7ca2                	ld	s9,40(sp)
    8000647c:	7d02                	ld	s10,32(sp)
    8000647e:	6de2                	ld	s11,24(sp)
    80006480:	6109                	addi	sp,sp,128
    80006482:	8082                	ret

0000000080006484 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006484:	1101                	addi	sp,sp,-32
    80006486:	ec06                	sd	ra,24(sp)
    80006488:	e822                	sd	s0,16(sp)
    8000648a:	e426                	sd	s1,8(sp)
    8000648c:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000648e:	0001c497          	auipc	s1,0x1c
    80006492:	9b248493          	addi	s1,s1,-1614 # 80021e40 <disk>
    80006496:	0001c517          	auipc	a0,0x1c
    8000649a:	ad250513          	addi	a0,a0,-1326 # 80021f68 <disk+0x128>
    8000649e:	ffffa097          	auipc	ra,0xffffa
    800064a2:	738080e7          	jalr	1848(ra) # 80000bd6 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    800064a6:	10001737          	lui	a4,0x10001
    800064aa:	533c                	lw	a5,96(a4)
    800064ac:	8b8d                	andi	a5,a5,3
    800064ae:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    800064b0:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    800064b4:	689c                	ld	a5,16(s1)
    800064b6:	0204d703          	lhu	a4,32(s1)
    800064ba:	0027d783          	lhu	a5,2(a5)
    800064be:	04f70863          	beq	a4,a5,8000650e <virtio_disk_intr+0x8a>
    __sync_synchronize();
    800064c2:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    800064c6:	6898                	ld	a4,16(s1)
    800064c8:	0204d783          	lhu	a5,32(s1)
    800064cc:	8b9d                	andi	a5,a5,7
    800064ce:	078e                	slli	a5,a5,0x3
    800064d0:	97ba                	add	a5,a5,a4
    800064d2:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800064d4:	00278713          	addi	a4,a5,2
    800064d8:	0712                	slli	a4,a4,0x4
    800064da:	9726                	add	a4,a4,s1
    800064dc:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    800064e0:	e721                	bnez	a4,80006528 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800064e2:	0789                	addi	a5,a5,2
    800064e4:	0792                	slli	a5,a5,0x4
    800064e6:	97a6                	add	a5,a5,s1
    800064e8:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    800064ea:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800064ee:	ffffc097          	auipc	ra,0xffffc
    800064f2:	cf6080e7          	jalr	-778(ra) # 800021e4 <wakeup>

    disk.used_idx += 1;
    800064f6:	0204d783          	lhu	a5,32(s1)
    800064fa:	2785                	addiw	a5,a5,1
    800064fc:	17c2                	slli	a5,a5,0x30
    800064fe:	93c1                	srli	a5,a5,0x30
    80006500:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006504:	6898                	ld	a4,16(s1)
    80006506:	00275703          	lhu	a4,2(a4)
    8000650a:	faf71ce3          	bne	a4,a5,800064c2 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    8000650e:	0001c517          	auipc	a0,0x1c
    80006512:	a5a50513          	addi	a0,a0,-1446 # 80021f68 <disk+0x128>
    80006516:	ffffa097          	auipc	ra,0xffffa
    8000651a:	774080e7          	jalr	1908(ra) # 80000c8a <release>
}
    8000651e:	60e2                	ld	ra,24(sp)
    80006520:	6442                	ld	s0,16(sp)
    80006522:	64a2                	ld	s1,8(sp)
    80006524:	6105                	addi	sp,sp,32
    80006526:	8082                	ret
      panic("virtio_disk_intr status");
    80006528:	00002517          	auipc	a0,0x2
    8000652c:	31050513          	addi	a0,a0,784 # 80008838 <syscalls+0x3e8>
    80006530:	ffffa097          	auipc	ra,0xffffa
    80006534:	010080e7          	jalr	16(ra) # 80000540 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0)
    80007010:	02253823          	sd	sp,48(a0)
    80007014:	02353c23          	sd	gp,56(a0)
    80007018:	04453023          	sd	tp,64(a0)
    8000701c:	04553423          	sd	t0,72(a0)
    80007020:	04653823          	sd	t1,80(a0)
    80007024:	04753c23          	sd	t2,88(a0)
    80007028:	f120                	sd	s0,96(a0)
    8000702a:	f524                	sd	s1,104(a0)
    8000702c:	fd2c                	sd	a1,120(a0)
    8000702e:	e150                	sd	a2,128(a0)
    80007030:	e554                	sd	a3,136(a0)
    80007032:	e958                	sd	a4,144(a0)
    80007034:	ed5c                	sd	a5,152(a0)
    80007036:	0b053023          	sd	a6,160(a0)
    8000703a:	0b153423          	sd	a7,168(a0)
    8000703e:	0b253823          	sd	s2,176(a0)
    80007042:	0b353c23          	sd	s3,184(a0)
    80007046:	0d453023          	sd	s4,192(a0)
    8000704a:	0d553423          	sd	s5,200(a0)
    8000704e:	0d653823          	sd	s6,208(a0)
    80007052:	0d753c23          	sd	s7,216(a0)
    80007056:	0f853023          	sd	s8,224(a0)
    8000705a:	0f953423          	sd	s9,232(a0)
    8000705e:	0fa53823          	sd	s10,240(a0)
    80007062:	0fb53c23          	sd	s11,248(a0)
    80007066:	11c53023          	sd	t3,256(a0)
    8000706a:	11d53423          	sd	t4,264(a0)
    8000706e:	11e53823          	sd	t5,272(a0)
    80007072:	11f53c23          	sd	t6,280(a0)
    80007076:	140022f3          	csrr	t0,sscratch
    8000707a:	06553823          	sd	t0,112(a0)
    8000707e:	00853103          	ld	sp,8(a0)
    80007082:	02053203          	ld	tp,32(a0)
    80007086:	01053283          	ld	t0,16(a0)
    8000708a:	00053303          	ld	t1,0(a0)
    8000708e:	12000073          	sfence.vma
    80007092:	18031073          	csrw	satp,t1
    80007096:	12000073          	sfence.vma
    8000709a:	8282                	jr	t0

000000008000709c <userret>:
    8000709c:	12000073          	sfence.vma
    800070a0:	18051073          	csrw	satp,a0
    800070a4:	12000073          	sfence.vma
    800070a8:	02000537          	lui	a0,0x2000
    800070ac:	357d                	addiw	a0,a0,-1 # 1ffffff <_entry-0x7e000001>
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0)
    800070b4:	03053103          	ld	sp,48(a0)
    800070b8:	03853183          	ld	gp,56(a0)
    800070bc:	04053203          	ld	tp,64(a0)
    800070c0:	04853283          	ld	t0,72(a0)
    800070c4:	05053303          	ld	t1,80(a0)
    800070c8:	05853383          	ld	t2,88(a0)
    800070cc:	7120                	ld	s0,96(a0)
    800070ce:	7524                	ld	s1,104(a0)
    800070d0:	7d2c                	ld	a1,120(a0)
    800070d2:	6150                	ld	a2,128(a0)
    800070d4:	6554                	ld	a3,136(a0)
    800070d6:	6958                	ld	a4,144(a0)
    800070d8:	6d5c                	ld	a5,152(a0)
    800070da:	0a053803          	ld	a6,160(a0)
    800070de:	0a853883          	ld	a7,168(a0)
    800070e2:	0b053903          	ld	s2,176(a0)
    800070e6:	0b853983          	ld	s3,184(a0)
    800070ea:	0c053a03          	ld	s4,192(a0)
    800070ee:	0c853a83          	ld	s5,200(a0)
    800070f2:	0d053b03          	ld	s6,208(a0)
    800070f6:	0d853b83          	ld	s7,216(a0)
    800070fa:	0e053c03          	ld	s8,224(a0)
    800070fe:	0e853c83          	ld	s9,232(a0)
    80007102:	0f053d03          	ld	s10,240(a0)
    80007106:	0f853d83          	ld	s11,248(a0)
    8000710a:	10053e03          	ld	t3,256(a0)
    8000710e:	10853e83          	ld	t4,264(a0)
    80007112:	11053f03          	ld	t5,272(a0)
    80007116:	11853f83          	ld	t6,280(a0)
    8000711a:	7928                	ld	a0,112(a0)
    8000711c:	10200073          	sret
	...
