
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	a8013103          	ld	sp,-1408(sp) # 80008a80 <_GLOBAL_OFFSET_TABLE_+0x8>
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
    80000054:	a9070713          	addi	a4,a4,-1392 # 80008ae0 <timer_scratch>
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
    80000066:	c8e78793          	addi	a5,a5,-882 # 80005cf0 <timervec>
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
    8000009a:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7ffdc8af>
    8000009e:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a0:	6705                	lui	a4,0x1
    800000a2:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a6:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000a8:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ac:	00001797          	auipc	a5,0x1
    800000b0:	e1678793          	addi	a5,a5,-490 # 80000ec2 <main>
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
    8000012e:	3d6080e7          	jalr	982(ra) # 80002500 <either_copyin>
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
    8000018e:	a9650513          	addi	a0,a0,-1386 # 80010c20 <cons>
    80000192:	00001097          	auipc	ra,0x1
    80000196:	a8e080e7          	jalr	-1394(ra) # 80000c20 <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019a:	00011497          	auipc	s1,0x11
    8000019e:	a8648493          	addi	s1,s1,-1402 # 80010c20 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a2:	00011917          	auipc	s2,0x11
    800001a6:	b1690913          	addi	s2,s2,-1258 # 80010cb8 <cons+0x98>
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
    800001c0:	00002097          	auipc	ra,0x2
    800001c4:	836080e7          	jalr	-1994(ra) # 800019f6 <myproc>
    800001c8:	00002097          	auipc	ra,0x2
    800001cc:	182080e7          	jalr	386(ra) # 8000234a <killed>
    800001d0:	e535                	bnez	a0,8000023c <consoleread+0xd8>
      sleep(&cons.r, &cons.lock);
    800001d2:	85a6                	mv	a1,s1
    800001d4:	854a                	mv	a0,s2
    800001d6:	00002097          	auipc	ra,0x2
    800001da:	ecc080e7          	jalr	-308(ra) # 800020a2 <sleep>
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
    80000216:	298080e7          	jalr	664(ra) # 800024aa <either_copyout>
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
    8000022a:	9fa50513          	addi	a0,a0,-1542 # 80010c20 <cons>
    8000022e:	00001097          	auipc	ra,0x1
    80000232:	aa6080e7          	jalr	-1370(ra) # 80000cd4 <release>

  return target - n;
    80000236:	413b053b          	subw	a0,s6,s3
    8000023a:	a811                	j	8000024e <consoleread+0xea>
        release(&cons.lock);
    8000023c:	00011517          	auipc	a0,0x11
    80000240:	9e450513          	addi	a0,a0,-1564 # 80010c20 <cons>
    80000244:	00001097          	auipc	ra,0x1
    80000248:	a90080e7          	jalr	-1392(ra) # 80000cd4 <release>
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
    80000276:	a4f72323          	sw	a5,-1466(a4) # 80010cb8 <cons+0x98>
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
    800002cc:	00011517          	auipc	a0,0x11
    800002d0:	95450513          	addi	a0,a0,-1708 # 80010c20 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	94c080e7          	jalr	-1716(ra) # 80000c20 <acquire>

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
    800002f6:	264080e7          	jalr	612(ra) # 80002556 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	92650513          	addi	a0,a0,-1754 # 80010c20 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	9d2080e7          	jalr	-1582(ra) # 80000cd4 <release>
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
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	90270713          	addi	a4,a4,-1790 # 80010c20 <cons>
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
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	8d878793          	addi	a5,a5,-1832 # 80010c20 <cons>
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
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	9427a783          	lw	a5,-1726(a5) # 80010cb8 <cons+0x98>
    8000037e:	9f1d                	subw	a4,a4,a5
    80000380:	08000793          	li	a5,128
    80000384:	f6f71be3          	bne	a4,a5,800002fa <consoleintr+0x3c>
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	89670713          	addi	a4,a4,-1898 # 80010c20 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	88648493          	addi	s1,s1,-1914 # 80010c20 <cons>
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
    800003d6:	00011717          	auipc	a4,0x11
    800003da:	84a70713          	addi	a4,a4,-1974 # 80010c20 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	8cf72a23          	sw	a5,-1836(a4) # 80010cc0 <cons+0xa0>
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
    80000412:	00011797          	auipc	a5,0x11
    80000416:	80e78793          	addi	a5,a5,-2034 # 80010c20 <cons>
    8000041a:	0a07a703          	lw	a4,160(a5)
    8000041e:	0017069b          	addiw	a3,a4,1
    80000422:	0006861b          	sext.w	a2,a3
    80000426:	0ad7a023          	sw	a3,160(a5)
    8000042a:	07f77713          	andi	a4,a4,127
    8000042e:	97ba                	add	a5,a5,a4
    80000430:	4729                	li	a4,10
    80000432:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    80000436:	00011797          	auipc	a5,0x11
    8000043a:	88c7a323          	sw	a2,-1914(a5) # 80010cbc <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	87a50513          	addi	a0,a0,-1926 # 80010cb8 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	cc0080e7          	jalr	-832(ra) # 80002106 <wakeup>
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
    80000464:	7c050513          	addi	a0,a0,1984 # 80010c20 <cons>
    80000468:	00000097          	auipc	ra,0x0
    8000046c:	728080e7          	jalr	1832(ra) # 80000b90 <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	32c080e7          	jalr	812(ra) # 8000079c <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	00021797          	auipc	a5,0x21
    8000047c:	94078793          	addi	a5,a5,-1728 # 80020db8 <devsw>
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
    80000550:	7807aa23          	sw	zero,1940(a5) # 80010ce0 <pr+0x18>
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
    80000584:	52f72023          	sw	a5,1312(a4) # 80008aa0 <panicked>
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
    800005c0:	724dad83          	lw	s11,1828(s11) # 80010ce0 <pr+0x18>
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
    800005fe:	6ce50513          	addi	a0,a0,1742 # 80010cc8 <pr>
    80000602:	00000097          	auipc	ra,0x0
    80000606:	61e080e7          	jalr	1566(ra) # 80000c20 <acquire>
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
    8000075c:	57050513          	addi	a0,a0,1392 # 80010cc8 <pr>
    80000760:	00000097          	auipc	ra,0x0
    80000764:	574080e7          	jalr	1396(ra) # 80000cd4 <release>
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
    80000778:	55448493          	addi	s1,s1,1364 # 80010cc8 <pr>
    8000077c:	00008597          	auipc	a1,0x8
    80000780:	8bc58593          	addi	a1,a1,-1860 # 80008038 <etext+0x38>
    80000784:	8526                	mv	a0,s1
    80000786:	00000097          	auipc	ra,0x0
    8000078a:	40a080e7          	jalr	1034(ra) # 80000b90 <initlock>
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
    800007d8:	51450513          	addi	a0,a0,1300 # 80010ce8 <uart_tx_lock>
    800007dc:	00000097          	auipc	ra,0x0
    800007e0:	3b4080e7          	jalr	948(ra) # 80000b90 <initlock>
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
    800007fc:	3dc080e7          	jalr	988(ra) # 80000bd4 <push_off>

  if(panicked){
    80000800:	00008797          	auipc	a5,0x8
    80000804:	2a07a783          	lw	a5,672(a5) # 80008aa0 <panicked>
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
    8000082a:	44e080e7          	jalr	1102(ra) # 80000c74 <pop_off>
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
    8000083c:	2707b783          	ld	a5,624(a5) # 80008aa8 <uart_tx_r>
    80000840:	00008717          	auipc	a4,0x8
    80000844:	27073703          	ld	a4,624(a4) # 80008ab0 <uart_tx_w>
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
    80000866:	486a0a13          	addi	s4,s4,1158 # 80010ce8 <uart_tx_lock>
    uart_tx_r += 1;
    8000086a:	00008497          	auipc	s1,0x8
    8000086e:	23e48493          	addi	s1,s1,574 # 80008aa8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000872:	00008997          	auipc	s3,0x8
    80000876:	23e98993          	addi	s3,s3,574 # 80008ab0 <uart_tx_w>
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
    80000898:	872080e7          	jalr	-1934(ra) # 80002106 <wakeup>
    
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
    800008d4:	41850513          	addi	a0,a0,1048 # 80010ce8 <uart_tx_lock>
    800008d8:	00000097          	auipc	ra,0x0
    800008dc:	348080e7          	jalr	840(ra) # 80000c20 <acquire>
  if(panicked){
    800008e0:	00008797          	auipc	a5,0x8
    800008e4:	1c07a783          	lw	a5,448(a5) # 80008aa0 <panicked>
    800008e8:	e7c9                	bnez	a5,80000972 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008ea:	00008717          	auipc	a4,0x8
    800008ee:	1c673703          	ld	a4,454(a4) # 80008ab0 <uart_tx_w>
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	1b67b783          	ld	a5,438(a5) # 80008aa8 <uart_tx_r>
    800008fa:	02078793          	addi	a5,a5,32
    sleep(&uart_tx_r, &uart_tx_lock);
    800008fe:	00010997          	auipc	s3,0x10
    80000902:	3ea98993          	addi	s3,s3,1002 # 80010ce8 <uart_tx_lock>
    80000906:	00008497          	auipc	s1,0x8
    8000090a:	1a248493          	addi	s1,s1,418 # 80008aa8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    8000090e:	00008917          	auipc	s2,0x8
    80000912:	1a290913          	addi	s2,s2,418 # 80008ab0 <uart_tx_w>
    80000916:	00e79f63          	bne	a5,a4,80000934 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000091a:	85ce                	mv	a1,s3
    8000091c:	8526                	mv	a0,s1
    8000091e:	00001097          	auipc	ra,0x1
    80000922:	784080e7          	jalr	1924(ra) # 800020a2 <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000926:	00093703          	ld	a4,0(s2)
    8000092a:	609c                	ld	a5,0(s1)
    8000092c:	02078793          	addi	a5,a5,32
    80000930:	fee785e3          	beq	a5,a4,8000091a <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000934:	00010497          	auipc	s1,0x10
    80000938:	3b448493          	addi	s1,s1,948 # 80010ce8 <uart_tx_lock>
    8000093c:	01f77793          	andi	a5,a4,31
    80000940:	97a6                	add	a5,a5,s1
    80000942:	01478c23          	sb	s4,24(a5)
  uart_tx_w += 1;
    80000946:	0705                	addi	a4,a4,1
    80000948:	00008797          	auipc	a5,0x8
    8000094c:	16e7b423          	sd	a4,360(a5) # 80008ab0 <uart_tx_w>
  uartstart();
    80000950:	00000097          	auipc	ra,0x0
    80000954:	ee8080e7          	jalr	-280(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    80000958:	8526                	mv	a0,s1
    8000095a:	00000097          	auipc	ra,0x0
    8000095e:	37a080e7          	jalr	890(ra) # 80000cd4 <release>
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
    800009be:	32e48493          	addi	s1,s1,814 # 80010ce8 <uart_tx_lock>
    800009c2:	8526                	mv	a0,s1
    800009c4:	00000097          	auipc	ra,0x0
    800009c8:	25c080e7          	jalr	604(ra) # 80000c20 <acquire>
  uartstart();
    800009cc:	00000097          	auipc	ra,0x0
    800009d0:	e6c080e7          	jalr	-404(ra) # 80000838 <uartstart>
  release(&uart_tx_lock);
    800009d4:	8526                	mv	a0,s1
    800009d6:	00000097          	auipc	ra,0x0
    800009da:	2fe080e7          	jalr	766(ra) # 80000cd4 <release>
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
    80000a00:	55478793          	addi	a5,a5,1364 # 80021f50 <end>
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
    80000a18:	308080e7          	jalr	776(ra) # 80000d1c <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000a1c:	00010917          	auipc	s2,0x10
    80000a20:	30490913          	addi	s2,s2,772 # 80010d20 <kmem>
    80000a24:	854a                	mv	a0,s2
    80000a26:	00000097          	auipc	ra,0x0
    80000a2a:	1fa080e7          	jalr	506(ra) # 80000c20 <acquire>
  r->next = kmem.freelist;
    80000a2e:	01893783          	ld	a5,24(s2)
    80000a32:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a34:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000a38:	854a                	mv	a0,s2
    80000a3a:	00000097          	auipc	ra,0x0
    80000a3e:	29a080e7          	jalr	666(ra) # 80000cd4 <release>
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
    80000abe:	26650513          	addi	a0,a0,614 # 80010d20 <kmem>
    80000ac2:	00000097          	auipc	ra,0x0
    80000ac6:	0ce080e7          	jalr	206(ra) # 80000b90 <initlock>
  freerange(end, (void*)PHYSTOP);
    80000aca:	45c5                	li	a1,17
    80000acc:	05ee                	slli	a1,a1,0x1b
    80000ace:	00021517          	auipc	a0,0x21
    80000ad2:	48250513          	addi	a0,a0,1154 # 80021f50 <end>
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
    80000af4:	23048493          	addi	s1,s1,560 # 80010d20 <kmem>
    80000af8:	8526                	mv	a0,s1
    80000afa:	00000097          	auipc	ra,0x0
    80000afe:	126080e7          	jalr	294(ra) # 80000c20 <acquire>
  r = kmem.freelist;
    80000b02:	6c84                	ld	s1,24(s1)
  if(r)
    80000b04:	c885                	beqz	s1,80000b34 <kalloc+0x4e>
    kmem.freelist = r->next;
    80000b06:	609c                	ld	a5,0(s1)
    80000b08:	00010517          	auipc	a0,0x10
    80000b0c:	21850513          	addi	a0,a0,536 # 80010d20 <kmem>
    80000b10:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000b12:	00000097          	auipc	ra,0x0
    80000b16:	1c2080e7          	jalr	450(ra) # 80000cd4 <release>

  if(r)
    memset((char*)r, 5, PGSIZE); // fill with junk
    80000b1a:	6605                	lui	a2,0x1
    80000b1c:	4595                	li	a1,5
    80000b1e:	8526                	mv	a0,s1
    80000b20:	00000097          	auipc	ra,0x0
    80000b24:	1fc080e7          	jalr	508(ra) # 80000d1c <memset>
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
    80000b38:	1ec50513          	addi	a0,a0,492 # 80010d20 <kmem>
    80000b3c:	00000097          	auipc	ra,0x0
    80000b40:	198080e7          	jalr	408(ra) # 80000cd4 <release>
  if(r)
    80000b44:	b7d5                	j	80000b28 <kalloc+0x42>

0000000080000b46 <freemem>:

// free memory list traversing
int
freemem(void)
{
    80000b46:	1101                	addi	sp,sp,-32
    80000b48:	ec06                	sd	ra,24(sp)
    80000b4a:	e822                	sd	s0,16(sp)
    80000b4c:	e426                	sd	s1,8(sp)
    80000b4e:	1000                	addi	s0,sp,32
  int n = 0;
  struct run *r;
  acquire(&kmem.lock);
    80000b50:	00010497          	auipc	s1,0x10
    80000b54:	1d048493          	addi	s1,s1,464 # 80010d20 <kmem>
    80000b58:	8526                	mv	a0,s1
    80000b5a:	00000097          	auipc	ra,0x0
    80000b5e:	0c6080e7          	jalr	198(ra) # 80000c20 <acquire>

  for(r = kmem.freelist; r; r = r->next)
    80000b62:	6c9c                	ld	a5,24(s1)
    80000b64:	c785                	beqz	a5,80000b8c <freemem+0x46>
  int n = 0;
    80000b66:	4481                	li	s1,0
    n++;
    80000b68:	2485                	addiw	s1,s1,1
  for(r = kmem.freelist; r; r = r->next)
    80000b6a:	639c                	ld	a5,0(a5)
    80000b6c:	fff5                	bnez	a5,80000b68 <freemem+0x22>
  release(&kmem.lock);
    80000b6e:	00010517          	auipc	a0,0x10
    80000b72:	1b250513          	addi	a0,a0,434 # 80010d20 <kmem>
    80000b76:	00000097          	auipc	ra,0x0
    80000b7a:	15e080e7          	jalr	350(ra) # 80000cd4 <release>

  return n * PGSIZE;
}
    80000b7e:	00c4951b          	slliw	a0,s1,0xc
    80000b82:	60e2                	ld	ra,24(sp)
    80000b84:	6442                	ld	s0,16(sp)
    80000b86:	64a2                	ld	s1,8(sp)
    80000b88:	6105                	addi	sp,sp,32
    80000b8a:	8082                	ret
  int n = 0;
    80000b8c:	4481                	li	s1,0
    80000b8e:	b7c5                	j	80000b6e <freemem+0x28>

0000000080000b90 <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000b90:	1141                	addi	sp,sp,-16
    80000b92:	e422                	sd	s0,8(sp)
    80000b94:	0800                	addi	s0,sp,16
  lk->name = name;
    80000b96:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000b98:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000b9c:	00053823          	sd	zero,16(a0)
}
    80000ba0:	6422                	ld	s0,8(sp)
    80000ba2:	0141                	addi	sp,sp,16
    80000ba4:	8082                	ret

0000000080000ba6 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000ba6:	411c                	lw	a5,0(a0)
    80000ba8:	e399                	bnez	a5,80000bae <holding+0x8>
    80000baa:	4501                	li	a0,0
  return r;
}
    80000bac:	8082                	ret
{
    80000bae:	1101                	addi	sp,sp,-32
    80000bb0:	ec06                	sd	ra,24(sp)
    80000bb2:	e822                	sd	s0,16(sp)
    80000bb4:	e426                	sd	s1,8(sp)
    80000bb6:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000bb8:	6904                	ld	s1,16(a0)
    80000bba:	00001097          	auipc	ra,0x1
    80000bbe:	e20080e7          	jalr	-480(ra) # 800019da <mycpu>
    80000bc2:	40a48533          	sub	a0,s1,a0
    80000bc6:	00153513          	seqz	a0,a0
}
    80000bca:	60e2                	ld	ra,24(sp)
    80000bcc:	6442                	ld	s0,16(sp)
    80000bce:	64a2                	ld	s1,8(sp)
    80000bd0:	6105                	addi	sp,sp,32
    80000bd2:	8082                	ret

0000000080000bd4 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000bd4:	1101                	addi	sp,sp,-32
    80000bd6:	ec06                	sd	ra,24(sp)
    80000bd8:	e822                	sd	s0,16(sp)
    80000bda:	e426                	sd	s1,8(sp)
    80000bdc:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000bde:	100024f3          	csrr	s1,sstatus
    80000be2:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000be6:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000be8:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000bec:	00001097          	auipc	ra,0x1
    80000bf0:	dee080e7          	jalr	-530(ra) # 800019da <mycpu>
    80000bf4:	5d3c                	lw	a5,120(a0)
    80000bf6:	cf89                	beqz	a5,80000c10 <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000bf8:	00001097          	auipc	ra,0x1
    80000bfc:	de2080e7          	jalr	-542(ra) # 800019da <mycpu>
    80000c00:	5d3c                	lw	a5,120(a0)
    80000c02:	2785                	addiw	a5,a5,1
    80000c04:	dd3c                	sw	a5,120(a0)
}
    80000c06:	60e2                	ld	ra,24(sp)
    80000c08:	6442                	ld	s0,16(sp)
    80000c0a:	64a2                	ld	s1,8(sp)
    80000c0c:	6105                	addi	sp,sp,32
    80000c0e:	8082                	ret
    mycpu()->intena = old;
    80000c10:	00001097          	auipc	ra,0x1
    80000c14:	dca080e7          	jalr	-566(ra) # 800019da <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000c18:	8085                	srli	s1,s1,0x1
    80000c1a:	8885                	andi	s1,s1,1
    80000c1c:	dd64                	sw	s1,124(a0)
    80000c1e:	bfe9                	j	80000bf8 <push_off+0x24>

0000000080000c20 <acquire>:
{
    80000c20:	1101                	addi	sp,sp,-32
    80000c22:	ec06                	sd	ra,24(sp)
    80000c24:	e822                	sd	s0,16(sp)
    80000c26:	e426                	sd	s1,8(sp)
    80000c28:	1000                	addi	s0,sp,32
    80000c2a:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000c2c:	00000097          	auipc	ra,0x0
    80000c30:	fa8080e7          	jalr	-88(ra) # 80000bd4 <push_off>
  if(holding(lk))
    80000c34:	8526                	mv	a0,s1
    80000c36:	00000097          	auipc	ra,0x0
    80000c3a:	f70080e7          	jalr	-144(ra) # 80000ba6 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c3e:	4705                	li	a4,1
  if(holding(lk))
    80000c40:	e115                	bnez	a0,80000c64 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000c42:	87ba                	mv	a5,a4
    80000c44:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000c48:	2781                	sext.w	a5,a5
    80000c4a:	ffe5                	bnez	a5,80000c42 <acquire+0x22>
  __sync_synchronize();
    80000c4c:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000c50:	00001097          	auipc	ra,0x1
    80000c54:	d8a080e7          	jalr	-630(ra) # 800019da <mycpu>
    80000c58:	e888                	sd	a0,16(s1)
}
    80000c5a:	60e2                	ld	ra,24(sp)
    80000c5c:	6442                	ld	s0,16(sp)
    80000c5e:	64a2                	ld	s1,8(sp)
    80000c60:	6105                	addi	sp,sp,32
    80000c62:	8082                	ret
    panic("acquire");
    80000c64:	00007517          	auipc	a0,0x7
    80000c68:	40c50513          	addi	a0,a0,1036 # 80008070 <digits+0x30>
    80000c6c:	00000097          	auipc	ra,0x0
    80000c70:	8d4080e7          	jalr	-1836(ra) # 80000540 <panic>

0000000080000c74 <pop_off>:

void
pop_off(void)
{
    80000c74:	1141                	addi	sp,sp,-16
    80000c76:	e406                	sd	ra,8(sp)
    80000c78:	e022                	sd	s0,0(sp)
    80000c7a:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000c7c:	00001097          	auipc	ra,0x1
    80000c80:	d5e080e7          	jalr	-674(ra) # 800019da <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000c84:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000c88:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000c8a:	e78d                	bnez	a5,80000cb4 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000c8c:	5d3c                	lw	a5,120(a0)
    80000c8e:	02f05b63          	blez	a5,80000cc4 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000c92:	37fd                	addiw	a5,a5,-1
    80000c94:	0007871b          	sext.w	a4,a5
    80000c98:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000c9a:	eb09                	bnez	a4,80000cac <pop_off+0x38>
    80000c9c:	5d7c                	lw	a5,124(a0)
    80000c9e:	c799                	beqz	a5,80000cac <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ca0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000ca4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000ca8:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000cac:	60a2                	ld	ra,8(sp)
    80000cae:	6402                	ld	s0,0(sp)
    80000cb0:	0141                	addi	sp,sp,16
    80000cb2:	8082                	ret
    panic("pop_off - interruptible");
    80000cb4:	00007517          	auipc	a0,0x7
    80000cb8:	3c450513          	addi	a0,a0,964 # 80008078 <digits+0x38>
    80000cbc:	00000097          	auipc	ra,0x0
    80000cc0:	884080e7          	jalr	-1916(ra) # 80000540 <panic>
    panic("pop_off");
    80000cc4:	00007517          	auipc	a0,0x7
    80000cc8:	3cc50513          	addi	a0,a0,972 # 80008090 <digits+0x50>
    80000ccc:	00000097          	auipc	ra,0x0
    80000cd0:	874080e7          	jalr	-1932(ra) # 80000540 <panic>

0000000080000cd4 <release>:
{
    80000cd4:	1101                	addi	sp,sp,-32
    80000cd6:	ec06                	sd	ra,24(sp)
    80000cd8:	e822                	sd	s0,16(sp)
    80000cda:	e426                	sd	s1,8(sp)
    80000cdc:	1000                	addi	s0,sp,32
    80000cde:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000ce0:	00000097          	auipc	ra,0x0
    80000ce4:	ec6080e7          	jalr	-314(ra) # 80000ba6 <holding>
    80000ce8:	c115                	beqz	a0,80000d0c <release+0x38>
  lk->cpu = 0;
    80000cea:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000cee:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000cf2:	0f50000f          	fence	iorw,ow
    80000cf6:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000cfa:	00000097          	auipc	ra,0x0
    80000cfe:	f7a080e7          	jalr	-134(ra) # 80000c74 <pop_off>
}
    80000d02:	60e2                	ld	ra,24(sp)
    80000d04:	6442                	ld	s0,16(sp)
    80000d06:	64a2                	ld	s1,8(sp)
    80000d08:	6105                	addi	sp,sp,32
    80000d0a:	8082                	ret
    panic("release");
    80000d0c:	00007517          	auipc	a0,0x7
    80000d10:	38c50513          	addi	a0,a0,908 # 80008098 <digits+0x58>
    80000d14:	00000097          	auipc	ra,0x0
    80000d18:	82c080e7          	jalr	-2004(ra) # 80000540 <panic>

0000000080000d1c <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000d1c:	1141                	addi	sp,sp,-16
    80000d1e:	e422                	sd	s0,8(sp)
    80000d20:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000d22:	ca19                	beqz	a2,80000d38 <memset+0x1c>
    80000d24:	87aa                	mv	a5,a0
    80000d26:	1602                	slli	a2,a2,0x20
    80000d28:	9201                	srli	a2,a2,0x20
    80000d2a:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
    80000d2e:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000d32:	0785                	addi	a5,a5,1
    80000d34:	fee79de3          	bne	a5,a4,80000d2e <memset+0x12>
  }
  return dst;
}
    80000d38:	6422                	ld	s0,8(sp)
    80000d3a:	0141                	addi	sp,sp,16
    80000d3c:	8082                	ret

0000000080000d3e <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000d3e:	1141                	addi	sp,sp,-16
    80000d40:	e422                	sd	s0,8(sp)
    80000d42:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000d44:	ca05                	beqz	a2,80000d74 <memcmp+0x36>
    80000d46:	fff6069b          	addiw	a3,a2,-1 # fff <_entry-0x7ffff001>
    80000d4a:	1682                	slli	a3,a3,0x20
    80000d4c:	9281                	srli	a3,a3,0x20
    80000d4e:	0685                	addi	a3,a3,1
    80000d50:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000d52:	00054783          	lbu	a5,0(a0)
    80000d56:	0005c703          	lbu	a4,0(a1)
    80000d5a:	00e79863          	bne	a5,a4,80000d6a <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000d5e:	0505                	addi	a0,a0,1
    80000d60:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000d62:	fed518e3          	bne	a0,a3,80000d52 <memcmp+0x14>
  }

  return 0;
    80000d66:	4501                	li	a0,0
    80000d68:	a019                	j	80000d6e <memcmp+0x30>
      return *s1 - *s2;
    80000d6a:	40e7853b          	subw	a0,a5,a4
}
    80000d6e:	6422                	ld	s0,8(sp)
    80000d70:	0141                	addi	sp,sp,16
    80000d72:	8082                	ret
  return 0;
    80000d74:	4501                	li	a0,0
    80000d76:	bfe5                	j	80000d6e <memcmp+0x30>

0000000080000d78 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000d78:	1141                	addi	sp,sp,-16
    80000d7a:	e422                	sd	s0,8(sp)
    80000d7c:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000d7e:	c205                	beqz	a2,80000d9e <memmove+0x26>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000d80:	02a5e263          	bltu	a1,a0,80000da4 <memmove+0x2c>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000d84:	1602                	slli	a2,a2,0x20
    80000d86:	9201                	srli	a2,a2,0x20
    80000d88:	00c587b3          	add	a5,a1,a2
{
    80000d8c:	872a                	mv	a4,a0
      *d++ = *s++;
    80000d8e:	0585                	addi	a1,a1,1
    80000d90:	0705                	addi	a4,a4,1 # fffffffffffff001 <end+0xffffffff7ffdd0b1>
    80000d92:	fff5c683          	lbu	a3,-1(a1)
    80000d96:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000d9a:	fef59ae3          	bne	a1,a5,80000d8e <memmove+0x16>

  return dst;
}
    80000d9e:	6422                	ld	s0,8(sp)
    80000da0:	0141                	addi	sp,sp,16
    80000da2:	8082                	ret
  if(s < d && s + n > d){
    80000da4:	02061693          	slli	a3,a2,0x20
    80000da8:	9281                	srli	a3,a3,0x20
    80000daa:	00d58733          	add	a4,a1,a3
    80000dae:	fce57be3          	bgeu	a0,a4,80000d84 <memmove+0xc>
    d += n;
    80000db2:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000db4:	fff6079b          	addiw	a5,a2,-1
    80000db8:	1782                	slli	a5,a5,0x20
    80000dba:	9381                	srli	a5,a5,0x20
    80000dbc:	fff7c793          	not	a5,a5
    80000dc0:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000dc2:	177d                	addi	a4,a4,-1
    80000dc4:	16fd                	addi	a3,a3,-1
    80000dc6:	00074603          	lbu	a2,0(a4)
    80000dca:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80000dce:	fee79ae3          	bne	a5,a4,80000dc2 <memmove+0x4a>
    80000dd2:	b7f1                	j	80000d9e <memmove+0x26>

0000000080000dd4 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80000dd4:	1141                	addi	sp,sp,-16
    80000dd6:	e406                	sd	ra,8(sp)
    80000dd8:	e022                	sd	s0,0(sp)
    80000dda:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80000ddc:	00000097          	auipc	ra,0x0
    80000de0:	f9c080e7          	jalr	-100(ra) # 80000d78 <memmove>
}
    80000de4:	60a2                	ld	ra,8(sp)
    80000de6:	6402                	ld	s0,0(sp)
    80000de8:	0141                	addi	sp,sp,16
    80000dea:	8082                	ret

0000000080000dec <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80000dec:	1141                	addi	sp,sp,-16
    80000dee:	e422                	sd	s0,8(sp)
    80000df0:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80000df2:	ce11                	beqz	a2,80000e0e <strncmp+0x22>
    80000df4:	00054783          	lbu	a5,0(a0)
    80000df8:	cf89                	beqz	a5,80000e12 <strncmp+0x26>
    80000dfa:	0005c703          	lbu	a4,0(a1)
    80000dfe:	00f71a63          	bne	a4,a5,80000e12 <strncmp+0x26>
    n--, p++, q++;
    80000e02:	367d                	addiw	a2,a2,-1
    80000e04:	0505                	addi	a0,a0,1
    80000e06:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    80000e08:	f675                	bnez	a2,80000df4 <strncmp+0x8>
  if(n == 0)
    return 0;
    80000e0a:	4501                	li	a0,0
    80000e0c:	a809                	j	80000e1e <strncmp+0x32>
    80000e0e:	4501                	li	a0,0
    80000e10:	a039                	j	80000e1e <strncmp+0x32>
  if(n == 0)
    80000e12:	ca09                	beqz	a2,80000e24 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    80000e14:	00054503          	lbu	a0,0(a0)
    80000e18:	0005c783          	lbu	a5,0(a1)
    80000e1c:	9d1d                	subw	a0,a0,a5
}
    80000e1e:	6422                	ld	s0,8(sp)
    80000e20:	0141                	addi	sp,sp,16
    80000e22:	8082                	ret
    return 0;
    80000e24:	4501                	li	a0,0
    80000e26:	bfe5                	j	80000e1e <strncmp+0x32>

0000000080000e28 <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    80000e28:	1141                	addi	sp,sp,-16
    80000e2a:	e422                	sd	s0,8(sp)
    80000e2c:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80000e2e:	872a                	mv	a4,a0
    80000e30:	8832                	mv	a6,a2
    80000e32:	367d                	addiw	a2,a2,-1
    80000e34:	01005963          	blez	a6,80000e46 <strncpy+0x1e>
    80000e38:	0705                	addi	a4,a4,1
    80000e3a:	0005c783          	lbu	a5,0(a1)
    80000e3e:	fef70fa3          	sb	a5,-1(a4)
    80000e42:	0585                	addi	a1,a1,1
    80000e44:	f7f5                	bnez	a5,80000e30 <strncpy+0x8>
    ;
  while(n-- > 0)
    80000e46:	86ba                	mv	a3,a4
    80000e48:	00c05c63          	blez	a2,80000e60 <strncpy+0x38>
    *s++ = 0;
    80000e4c:	0685                	addi	a3,a3,1
    80000e4e:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80000e52:	40d707bb          	subw	a5,a4,a3
    80000e56:	37fd                	addiw	a5,a5,-1
    80000e58:	010787bb          	addw	a5,a5,a6
    80000e5c:	fef048e3          	bgtz	a5,80000e4c <strncpy+0x24>
  return os;
}
    80000e60:	6422                	ld	s0,8(sp)
    80000e62:	0141                	addi	sp,sp,16
    80000e64:	8082                	ret

0000000080000e66 <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    80000e66:	1141                	addi	sp,sp,-16
    80000e68:	e422                	sd	s0,8(sp)
    80000e6a:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80000e6c:	02c05363          	blez	a2,80000e92 <safestrcpy+0x2c>
    80000e70:	fff6069b          	addiw	a3,a2,-1
    80000e74:	1682                	slli	a3,a3,0x20
    80000e76:	9281                	srli	a3,a3,0x20
    80000e78:	96ae                	add	a3,a3,a1
    80000e7a:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80000e7c:	00d58963          	beq	a1,a3,80000e8e <safestrcpy+0x28>
    80000e80:	0585                	addi	a1,a1,1
    80000e82:	0785                	addi	a5,a5,1
    80000e84:	fff5c703          	lbu	a4,-1(a1)
    80000e88:	fee78fa3          	sb	a4,-1(a5)
    80000e8c:	fb65                	bnez	a4,80000e7c <safestrcpy+0x16>
    ;
  *s = 0;
    80000e8e:	00078023          	sb	zero,0(a5)
  return os;
}
    80000e92:	6422                	ld	s0,8(sp)
    80000e94:	0141                	addi	sp,sp,16
    80000e96:	8082                	ret

0000000080000e98 <strlen>:

int
strlen(const char *s)
{
    80000e98:	1141                	addi	sp,sp,-16
    80000e9a:	e422                	sd	s0,8(sp)
    80000e9c:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80000e9e:	00054783          	lbu	a5,0(a0)
    80000ea2:	cf91                	beqz	a5,80000ebe <strlen+0x26>
    80000ea4:	0505                	addi	a0,a0,1
    80000ea6:	87aa                	mv	a5,a0
    80000ea8:	4685                	li	a3,1
    80000eaa:	9e89                	subw	a3,a3,a0
    80000eac:	00f6853b          	addw	a0,a3,a5
    80000eb0:	0785                	addi	a5,a5,1
    80000eb2:	fff7c703          	lbu	a4,-1(a5)
    80000eb6:	fb7d                	bnez	a4,80000eac <strlen+0x14>
    ;
  return n;
}
    80000eb8:	6422                	ld	s0,8(sp)
    80000eba:	0141                	addi	sp,sp,16
    80000ebc:	8082                	ret
  for(n = 0; s[n]; n++)
    80000ebe:	4501                	li	a0,0
    80000ec0:	bfe5                	j	80000eb8 <strlen+0x20>

0000000080000ec2 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    80000ec2:	1141                	addi	sp,sp,-16
    80000ec4:	e406                	sd	ra,8(sp)
    80000ec6:	e022                	sd	s0,0(sp)
    80000ec8:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80000eca:	00001097          	auipc	ra,0x1
    80000ece:	b00080e7          	jalr	-1280(ra) # 800019ca <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80000ed2:	00008717          	auipc	a4,0x8
    80000ed6:	be670713          	addi	a4,a4,-1050 # 80008ab8 <started>
  if(cpuid() == 0){
    80000eda:	c139                	beqz	a0,80000f20 <main+0x5e>
    while(started == 0)
    80000edc:	431c                	lw	a5,0(a4)
    80000ede:	2781                	sext.w	a5,a5
    80000ee0:	dff5                	beqz	a5,80000edc <main+0x1a>
      ;
    __sync_synchronize();
    80000ee2:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    80000ee6:	00001097          	auipc	ra,0x1
    80000eea:	ae4080e7          	jalr	-1308(ra) # 800019ca <cpuid>
    80000eee:	85aa                	mv	a1,a0
    80000ef0:	00007517          	auipc	a0,0x7
    80000ef4:	1c850513          	addi	a0,a0,456 # 800080b8 <digits+0x78>
    80000ef8:	fffff097          	auipc	ra,0xfffff
    80000efc:	692080e7          	jalr	1682(ra) # 8000058a <printf>
    kvminithart();    // turn on paging
    80000f00:	00000097          	auipc	ra,0x0
    80000f04:	0d8080e7          	jalr	216(ra) # 80000fd8 <kvminithart>
    trapinithart();   // install kernel trap vector
    80000f08:	00001097          	auipc	ra,0x1
    80000f0c:	7e6080e7          	jalr	2022(ra) # 800026ee <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80000f10:	00005097          	auipc	ra,0x5
    80000f14:	e20080e7          	jalr	-480(ra) # 80005d30 <plicinithart>
  }

  scheduler();        
    80000f18:	00001097          	auipc	ra,0x1
    80000f1c:	fd8080e7          	jalr	-40(ra) # 80001ef0 <scheduler>
    consoleinit();
    80000f20:	fffff097          	auipc	ra,0xfffff
    80000f24:	530080e7          	jalr	1328(ra) # 80000450 <consoleinit>
    printfinit();
    80000f28:	00000097          	auipc	ra,0x0
    80000f2c:	842080e7          	jalr	-1982(ra) # 8000076a <printfinit>
    printf("\n");
    80000f30:	00007517          	auipc	a0,0x7
    80000f34:	19850513          	addi	a0,a0,408 # 800080c8 <digits+0x88>
    80000f38:	fffff097          	auipc	ra,0xfffff
    80000f3c:	652080e7          	jalr	1618(ra) # 8000058a <printf>
    printf("xv6 kernel is booting\n");
    80000f40:	00007517          	auipc	a0,0x7
    80000f44:	16050513          	addi	a0,a0,352 # 800080a0 <digits+0x60>
    80000f48:	fffff097          	auipc	ra,0xfffff
    80000f4c:	642080e7          	jalr	1602(ra) # 8000058a <printf>
    printf("\n");
    80000f50:	00007517          	auipc	a0,0x7
    80000f54:	17850513          	addi	a0,a0,376 # 800080c8 <digits+0x88>
    80000f58:	fffff097          	auipc	ra,0xfffff
    80000f5c:	632080e7          	jalr	1586(ra) # 8000058a <printf>
    kinit();         // physical page allocator
    80000f60:	00000097          	auipc	ra,0x0
    80000f64:	b4a080e7          	jalr	-1206(ra) # 80000aaa <kinit>
    kvminit();       // create kernel page table
    80000f68:	00000097          	auipc	ra,0x0
    80000f6c:	326080e7          	jalr	806(ra) # 8000128e <kvminit>
    kvminithart();   // turn on paging
    80000f70:	00000097          	auipc	ra,0x0
    80000f74:	068080e7          	jalr	104(ra) # 80000fd8 <kvminithart>
    procinit();      // process table
    80000f78:	00001097          	auipc	ra,0x1
    80000f7c:	99e080e7          	jalr	-1634(ra) # 80001916 <procinit>
    trapinit();      // trap vectors
    80000f80:	00001097          	auipc	ra,0x1
    80000f84:	746080e7          	jalr	1862(ra) # 800026c6 <trapinit>
    trapinithart();  // install kernel trap vector
    80000f88:	00001097          	auipc	ra,0x1
    80000f8c:	766080e7          	jalr	1894(ra) # 800026ee <trapinithart>
    plicinit();      // set up interrupt controller
    80000f90:	00005097          	auipc	ra,0x5
    80000f94:	d8a080e7          	jalr	-630(ra) # 80005d1a <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    80000f98:	00005097          	auipc	ra,0x5
    80000f9c:	d98080e7          	jalr	-616(ra) # 80005d30 <plicinithart>
    binit();         // buffer cache
    80000fa0:	00002097          	auipc	ra,0x2
    80000fa4:	f3a080e7          	jalr	-198(ra) # 80002eda <binit>
    iinit();         // inode table
    80000fa8:	00002097          	auipc	ra,0x2
    80000fac:	5da080e7          	jalr	1498(ra) # 80003582 <iinit>
    fileinit();      // file table
    80000fb0:	00003097          	auipc	ra,0x3
    80000fb4:	580080e7          	jalr	1408(ra) # 80004530 <fileinit>
    virtio_disk_init(); // emulated hard disk
    80000fb8:	00005097          	auipc	ra,0x5
    80000fbc:	e80080e7          	jalr	-384(ra) # 80005e38 <virtio_disk_init>
    userinit();      // first user process
    80000fc0:	00001097          	auipc	ra,0x1
    80000fc4:	d12080e7          	jalr	-750(ra) # 80001cd2 <userinit>
    __sync_synchronize();
    80000fc8:	0ff0000f          	fence
    started = 1;
    80000fcc:	4785                	li	a5,1
    80000fce:	00008717          	auipc	a4,0x8
    80000fd2:	aef72523          	sw	a5,-1302(a4) # 80008ab8 <started>
    80000fd6:	b789                	j	80000f18 <main+0x56>

0000000080000fd8 <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    80000fd8:	1141                	addi	sp,sp,-16
    80000fda:	e422                	sd	s0,8(sp)
    80000fdc:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80000fde:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80000fe2:	00008797          	auipc	a5,0x8
    80000fe6:	ade7b783          	ld	a5,-1314(a5) # 80008ac0 <kernel_pagetable>
    80000fea:	83b1                	srli	a5,a5,0xc
    80000fec:	577d                	li	a4,-1
    80000fee:	177e                	slli	a4,a4,0x3f
    80000ff0:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80000ff2:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    80000ff6:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    80000ffa:	6422                	ld	s0,8(sp)
    80000ffc:	0141                	addi	sp,sp,16
    80000ffe:	8082                	ret

0000000080001000 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001000:	7139                	addi	sp,sp,-64
    80001002:	fc06                	sd	ra,56(sp)
    80001004:	f822                	sd	s0,48(sp)
    80001006:	f426                	sd	s1,40(sp)
    80001008:	f04a                	sd	s2,32(sp)
    8000100a:	ec4e                	sd	s3,24(sp)
    8000100c:	e852                	sd	s4,16(sp)
    8000100e:	e456                	sd	s5,8(sp)
    80001010:	e05a                	sd	s6,0(sp)
    80001012:	0080                	addi	s0,sp,64
    80001014:	84aa                	mv	s1,a0
    80001016:	89ae                	mv	s3,a1
    80001018:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    8000101a:	57fd                	li	a5,-1
    8000101c:	83e9                	srli	a5,a5,0x1a
    8000101e:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001020:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001022:	04b7f263          	bgeu	a5,a1,80001066 <walk+0x66>
    panic("walk");
    80001026:	00007517          	auipc	a0,0x7
    8000102a:	0aa50513          	addi	a0,a0,170 # 800080d0 <digits+0x90>
    8000102e:	fffff097          	auipc	ra,0xfffff
    80001032:	512080e7          	jalr	1298(ra) # 80000540 <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001036:	060a8663          	beqz	s5,800010a2 <walk+0xa2>
    8000103a:	00000097          	auipc	ra,0x0
    8000103e:	aac080e7          	jalr	-1364(ra) # 80000ae6 <kalloc>
    80001042:	84aa                	mv	s1,a0
    80001044:	c529                	beqz	a0,8000108e <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001046:	6605                	lui	a2,0x1
    80001048:	4581                	li	a1,0
    8000104a:	00000097          	auipc	ra,0x0
    8000104e:	cd2080e7          	jalr	-814(ra) # 80000d1c <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001052:	00c4d793          	srli	a5,s1,0xc
    80001056:	07aa                	slli	a5,a5,0xa
    80001058:	0017e793          	ori	a5,a5,1
    8000105c:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001060:	3a5d                	addiw	s4,s4,-9 # ffffffffffffeff7 <end+0xffffffff7ffdd0a7>
    80001062:	036a0063          	beq	s4,s6,80001082 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001066:	0149d933          	srl	s2,s3,s4
    8000106a:	1ff97913          	andi	s2,s2,511
    8000106e:	090e                	slli	s2,s2,0x3
    80001070:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    80001072:	00093483          	ld	s1,0(s2)
    80001076:	0014f793          	andi	a5,s1,1
    8000107a:	dfd5                	beqz	a5,80001036 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    8000107c:	80a9                	srli	s1,s1,0xa
    8000107e:	04b2                	slli	s1,s1,0xc
    80001080:	b7c5                	j	80001060 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001082:	00c9d513          	srli	a0,s3,0xc
    80001086:	1ff57513          	andi	a0,a0,511
    8000108a:	050e                	slli	a0,a0,0x3
    8000108c:	9526                	add	a0,a0,s1
}
    8000108e:	70e2                	ld	ra,56(sp)
    80001090:	7442                	ld	s0,48(sp)
    80001092:	74a2                	ld	s1,40(sp)
    80001094:	7902                	ld	s2,32(sp)
    80001096:	69e2                	ld	s3,24(sp)
    80001098:	6a42                	ld	s4,16(sp)
    8000109a:	6aa2                	ld	s5,8(sp)
    8000109c:	6b02                	ld	s6,0(sp)
    8000109e:	6121                	addi	sp,sp,64
    800010a0:	8082                	ret
        return 0;
    800010a2:	4501                	li	a0,0
    800010a4:	b7ed                	j	8000108e <walk+0x8e>

00000000800010a6 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800010a6:	57fd                	li	a5,-1
    800010a8:	83e9                	srli	a5,a5,0x1a
    800010aa:	00b7f463          	bgeu	a5,a1,800010b2 <walkaddr+0xc>
    return 0;
    800010ae:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800010b0:	8082                	ret
{
    800010b2:	1141                	addi	sp,sp,-16
    800010b4:	e406                	sd	ra,8(sp)
    800010b6:	e022                	sd	s0,0(sp)
    800010b8:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800010ba:	4601                	li	a2,0
    800010bc:	00000097          	auipc	ra,0x0
    800010c0:	f44080e7          	jalr	-188(ra) # 80001000 <walk>
  if(pte == 0)
    800010c4:	c105                	beqz	a0,800010e4 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800010c6:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800010c8:	0117f693          	andi	a3,a5,17
    800010cc:	4745                	li	a4,17
    return 0;
    800010ce:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    800010d0:	00e68663          	beq	a3,a4,800010dc <walkaddr+0x36>
}
    800010d4:	60a2                	ld	ra,8(sp)
    800010d6:	6402                	ld	s0,0(sp)
    800010d8:	0141                	addi	sp,sp,16
    800010da:	8082                	ret
  pa = PTE2PA(*pte);
    800010dc:	83a9                	srli	a5,a5,0xa
    800010de:	00c79513          	slli	a0,a5,0xc
  return pa;
    800010e2:	bfcd                	j	800010d4 <walkaddr+0x2e>
    return 0;
    800010e4:	4501                	li	a0,0
    800010e6:	b7fd                	j	800010d4 <walkaddr+0x2e>

00000000800010e8 <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    800010e8:	715d                	addi	sp,sp,-80
    800010ea:	e486                	sd	ra,72(sp)
    800010ec:	e0a2                	sd	s0,64(sp)
    800010ee:	fc26                	sd	s1,56(sp)
    800010f0:	f84a                	sd	s2,48(sp)
    800010f2:	f44e                	sd	s3,40(sp)
    800010f4:	f052                	sd	s4,32(sp)
    800010f6:	ec56                	sd	s5,24(sp)
    800010f8:	e85a                	sd	s6,16(sp)
    800010fa:	e45e                	sd	s7,8(sp)
    800010fc:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    800010fe:	c639                	beqz	a2,8000114c <mappages+0x64>
    80001100:	8aaa                	mv	s5,a0
    80001102:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    80001104:	777d                	lui	a4,0xfffff
    80001106:	00e5f7b3          	and	a5,a1,a4
  last = PGROUNDDOWN(va + size - 1);
    8000110a:	fff58993          	addi	s3,a1,-1
    8000110e:	99b2                	add	s3,s3,a2
    80001110:	00e9f9b3          	and	s3,s3,a4
  a = PGROUNDDOWN(va);
    80001114:	893e                	mv	s2,a5
    80001116:	40f68a33          	sub	s4,a3,a5
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    8000111a:	6b85                	lui	s7,0x1
    8000111c:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001120:	4605                	li	a2,1
    80001122:	85ca                	mv	a1,s2
    80001124:	8556                	mv	a0,s5
    80001126:	00000097          	auipc	ra,0x0
    8000112a:	eda080e7          	jalr	-294(ra) # 80001000 <walk>
    8000112e:	cd1d                	beqz	a0,8000116c <mappages+0x84>
    if(*pte & PTE_V)
    80001130:	611c                	ld	a5,0(a0)
    80001132:	8b85                	andi	a5,a5,1
    80001134:	e785                	bnez	a5,8000115c <mappages+0x74>
    *pte = PA2PTE(pa) | perm | PTE_V;
    80001136:	80b1                	srli	s1,s1,0xc
    80001138:	04aa                	slli	s1,s1,0xa
    8000113a:	0164e4b3          	or	s1,s1,s6
    8000113e:	0014e493          	ori	s1,s1,1
    80001142:	e104                	sd	s1,0(a0)
    if(a == last)
    80001144:	05390063          	beq	s2,s3,80001184 <mappages+0x9c>
    a += PGSIZE;
    80001148:	995e                	add	s2,s2,s7
    if((pte = walk(pagetable, a, 1)) == 0)
    8000114a:	bfc9                	j	8000111c <mappages+0x34>
    panic("mappages: size");
    8000114c:	00007517          	auipc	a0,0x7
    80001150:	f8c50513          	addi	a0,a0,-116 # 800080d8 <digits+0x98>
    80001154:	fffff097          	auipc	ra,0xfffff
    80001158:	3ec080e7          	jalr	1004(ra) # 80000540 <panic>
      panic("mappages: remap");
    8000115c:	00007517          	auipc	a0,0x7
    80001160:	f8c50513          	addi	a0,a0,-116 # 800080e8 <digits+0xa8>
    80001164:	fffff097          	auipc	ra,0xfffff
    80001168:	3dc080e7          	jalr	988(ra) # 80000540 <panic>
      return -1;
    8000116c:	557d                	li	a0,-1
    pa += PGSIZE;
  }
  return 0;
}
    8000116e:	60a6                	ld	ra,72(sp)
    80001170:	6406                	ld	s0,64(sp)
    80001172:	74e2                	ld	s1,56(sp)
    80001174:	7942                	ld	s2,48(sp)
    80001176:	79a2                	ld	s3,40(sp)
    80001178:	7a02                	ld	s4,32(sp)
    8000117a:	6ae2                	ld	s5,24(sp)
    8000117c:	6b42                	ld	s6,16(sp)
    8000117e:	6ba2                	ld	s7,8(sp)
    80001180:	6161                	addi	sp,sp,80
    80001182:	8082                	ret
  return 0;
    80001184:	4501                	li	a0,0
    80001186:	b7e5                	j	8000116e <mappages+0x86>

0000000080001188 <kvmmap>:
{
    80001188:	1141                	addi	sp,sp,-16
    8000118a:	e406                	sd	ra,8(sp)
    8000118c:	e022                	sd	s0,0(sp)
    8000118e:	0800                	addi	s0,sp,16
    80001190:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001192:	86b2                	mv	a3,a2
    80001194:	863e                	mv	a2,a5
    80001196:	00000097          	auipc	ra,0x0
    8000119a:	f52080e7          	jalr	-174(ra) # 800010e8 <mappages>
    8000119e:	e509                	bnez	a0,800011a8 <kvmmap+0x20>
}
    800011a0:	60a2                	ld	ra,8(sp)
    800011a2:	6402                	ld	s0,0(sp)
    800011a4:	0141                	addi	sp,sp,16
    800011a6:	8082                	ret
    panic("kvmmap");
    800011a8:	00007517          	auipc	a0,0x7
    800011ac:	f5050513          	addi	a0,a0,-176 # 800080f8 <digits+0xb8>
    800011b0:	fffff097          	auipc	ra,0xfffff
    800011b4:	390080e7          	jalr	912(ra) # 80000540 <panic>

00000000800011b8 <kvmmake>:
{
    800011b8:	1101                	addi	sp,sp,-32
    800011ba:	ec06                	sd	ra,24(sp)
    800011bc:	e822                	sd	s0,16(sp)
    800011be:	e426                	sd	s1,8(sp)
    800011c0:	e04a                	sd	s2,0(sp)
    800011c2:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    800011c4:	00000097          	auipc	ra,0x0
    800011c8:	922080e7          	jalr	-1758(ra) # 80000ae6 <kalloc>
    800011cc:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    800011ce:	6605                	lui	a2,0x1
    800011d0:	4581                	li	a1,0
    800011d2:	00000097          	auipc	ra,0x0
    800011d6:	b4a080e7          	jalr	-1206(ra) # 80000d1c <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    800011da:	4719                	li	a4,6
    800011dc:	6685                	lui	a3,0x1
    800011de:	10000637          	lui	a2,0x10000
    800011e2:	100005b7          	lui	a1,0x10000
    800011e6:	8526                	mv	a0,s1
    800011e8:	00000097          	auipc	ra,0x0
    800011ec:	fa0080e7          	jalr	-96(ra) # 80001188 <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    800011f0:	4719                	li	a4,6
    800011f2:	6685                	lui	a3,0x1
    800011f4:	10001637          	lui	a2,0x10001
    800011f8:	100015b7          	lui	a1,0x10001
    800011fc:	8526                	mv	a0,s1
    800011fe:	00000097          	auipc	ra,0x0
    80001202:	f8a080e7          	jalr	-118(ra) # 80001188 <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001206:	4719                	li	a4,6
    80001208:	004006b7          	lui	a3,0x400
    8000120c:	0c000637          	lui	a2,0xc000
    80001210:	0c0005b7          	lui	a1,0xc000
    80001214:	8526                	mv	a0,s1
    80001216:	00000097          	auipc	ra,0x0
    8000121a:	f72080e7          	jalr	-142(ra) # 80001188 <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    8000121e:	00007917          	auipc	s2,0x7
    80001222:	de290913          	addi	s2,s2,-542 # 80008000 <etext>
    80001226:	4729                	li	a4,10
    80001228:	80007697          	auipc	a3,0x80007
    8000122c:	dd868693          	addi	a3,a3,-552 # 8000 <_entry-0x7fff8000>
    80001230:	4605                	li	a2,1
    80001232:	067e                	slli	a2,a2,0x1f
    80001234:	85b2                	mv	a1,a2
    80001236:	8526                	mv	a0,s1
    80001238:	00000097          	auipc	ra,0x0
    8000123c:	f50080e7          	jalr	-176(ra) # 80001188 <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001240:	4719                	li	a4,6
    80001242:	46c5                	li	a3,17
    80001244:	06ee                	slli	a3,a3,0x1b
    80001246:	412686b3          	sub	a3,a3,s2
    8000124a:	864a                	mv	a2,s2
    8000124c:	85ca                	mv	a1,s2
    8000124e:	8526                	mv	a0,s1
    80001250:	00000097          	auipc	ra,0x0
    80001254:	f38080e7          	jalr	-200(ra) # 80001188 <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    80001258:	4729                	li	a4,10
    8000125a:	6685                	lui	a3,0x1
    8000125c:	00006617          	auipc	a2,0x6
    80001260:	da460613          	addi	a2,a2,-604 # 80007000 <_trampoline>
    80001264:	040005b7          	lui	a1,0x4000
    80001268:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    8000126a:	05b2                	slli	a1,a1,0xc
    8000126c:	8526                	mv	a0,s1
    8000126e:	00000097          	auipc	ra,0x0
    80001272:	f1a080e7          	jalr	-230(ra) # 80001188 <kvmmap>
  proc_mapstacks(kpgtbl);
    80001276:	8526                	mv	a0,s1
    80001278:	00000097          	auipc	ra,0x0
    8000127c:	608080e7          	jalr	1544(ra) # 80001880 <proc_mapstacks>
}
    80001280:	8526                	mv	a0,s1
    80001282:	60e2                	ld	ra,24(sp)
    80001284:	6442                	ld	s0,16(sp)
    80001286:	64a2                	ld	s1,8(sp)
    80001288:	6902                	ld	s2,0(sp)
    8000128a:	6105                	addi	sp,sp,32
    8000128c:	8082                	ret

000000008000128e <kvminit>:
{
    8000128e:	1141                	addi	sp,sp,-16
    80001290:	e406                	sd	ra,8(sp)
    80001292:	e022                	sd	s0,0(sp)
    80001294:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    80001296:	00000097          	auipc	ra,0x0
    8000129a:	f22080e7          	jalr	-222(ra) # 800011b8 <kvmmake>
    8000129e:	00008797          	auipc	a5,0x8
    800012a2:	82a7b123          	sd	a0,-2014(a5) # 80008ac0 <kernel_pagetable>
}
    800012a6:	60a2                	ld	ra,8(sp)
    800012a8:	6402                	ld	s0,0(sp)
    800012aa:	0141                	addi	sp,sp,16
    800012ac:	8082                	ret

00000000800012ae <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800012ae:	715d                	addi	sp,sp,-80
    800012b0:	e486                	sd	ra,72(sp)
    800012b2:	e0a2                	sd	s0,64(sp)
    800012b4:	fc26                	sd	s1,56(sp)
    800012b6:	f84a                	sd	s2,48(sp)
    800012b8:	f44e                	sd	s3,40(sp)
    800012ba:	f052                	sd	s4,32(sp)
    800012bc:	ec56                	sd	s5,24(sp)
    800012be:	e85a                	sd	s6,16(sp)
    800012c0:	e45e                	sd	s7,8(sp)
    800012c2:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800012c4:	03459793          	slli	a5,a1,0x34
    800012c8:	e795                	bnez	a5,800012f4 <uvmunmap+0x46>
    800012ca:	8a2a                	mv	s4,a0
    800012cc:	892e                	mv	s2,a1
    800012ce:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012d0:	0632                	slli	a2,a2,0xc
    800012d2:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    800012d6:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    800012d8:	6b05                	lui	s6,0x1
    800012da:	0735e263          	bltu	a1,s3,8000133e <uvmunmap+0x90>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    800012de:	60a6                	ld	ra,72(sp)
    800012e0:	6406                	ld	s0,64(sp)
    800012e2:	74e2                	ld	s1,56(sp)
    800012e4:	7942                	ld	s2,48(sp)
    800012e6:	79a2                	ld	s3,40(sp)
    800012e8:	7a02                	ld	s4,32(sp)
    800012ea:	6ae2                	ld	s5,24(sp)
    800012ec:	6b42                	ld	s6,16(sp)
    800012ee:	6ba2                	ld	s7,8(sp)
    800012f0:	6161                	addi	sp,sp,80
    800012f2:	8082                	ret
    panic("uvmunmap: not aligned");
    800012f4:	00007517          	auipc	a0,0x7
    800012f8:	e0c50513          	addi	a0,a0,-500 # 80008100 <digits+0xc0>
    800012fc:	fffff097          	auipc	ra,0xfffff
    80001300:	244080e7          	jalr	580(ra) # 80000540 <panic>
      panic("uvmunmap: walk");
    80001304:	00007517          	auipc	a0,0x7
    80001308:	e1450513          	addi	a0,a0,-492 # 80008118 <digits+0xd8>
    8000130c:	fffff097          	auipc	ra,0xfffff
    80001310:	234080e7          	jalr	564(ra) # 80000540 <panic>
      panic("uvmunmap: not mapped");
    80001314:	00007517          	auipc	a0,0x7
    80001318:	e1450513          	addi	a0,a0,-492 # 80008128 <digits+0xe8>
    8000131c:	fffff097          	auipc	ra,0xfffff
    80001320:	224080e7          	jalr	548(ra) # 80000540 <panic>
      panic("uvmunmap: not a leaf");
    80001324:	00007517          	auipc	a0,0x7
    80001328:	e1c50513          	addi	a0,a0,-484 # 80008140 <digits+0x100>
    8000132c:	fffff097          	auipc	ra,0xfffff
    80001330:	214080e7          	jalr	532(ra) # 80000540 <panic>
    *pte = 0;
    80001334:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001338:	995a                	add	s2,s2,s6
    8000133a:	fb3972e3          	bgeu	s2,s3,800012de <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    8000133e:	4601                	li	a2,0
    80001340:	85ca                	mv	a1,s2
    80001342:	8552                	mv	a0,s4
    80001344:	00000097          	auipc	ra,0x0
    80001348:	cbc080e7          	jalr	-836(ra) # 80001000 <walk>
    8000134c:	84aa                	mv	s1,a0
    8000134e:	d95d                	beqz	a0,80001304 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    80001350:	6108                	ld	a0,0(a0)
    80001352:	00157793          	andi	a5,a0,1
    80001356:	dfdd                	beqz	a5,80001314 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001358:	3ff57793          	andi	a5,a0,1023
    8000135c:	fd7784e3          	beq	a5,s7,80001324 <uvmunmap+0x76>
    if(do_free){
    80001360:	fc0a8ae3          	beqz	s5,80001334 <uvmunmap+0x86>
      uint64 pa = PTE2PA(*pte);
    80001364:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001366:	0532                	slli	a0,a0,0xc
    80001368:	fffff097          	auipc	ra,0xfffff
    8000136c:	680080e7          	jalr	1664(ra) # 800009e8 <kfree>
    80001370:	b7d1                	j	80001334 <uvmunmap+0x86>

0000000080001372 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001372:	1101                	addi	sp,sp,-32
    80001374:	ec06                	sd	ra,24(sp)
    80001376:	e822                	sd	s0,16(sp)
    80001378:	e426                	sd	s1,8(sp)
    8000137a:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    8000137c:	fffff097          	auipc	ra,0xfffff
    80001380:	76a080e7          	jalr	1898(ra) # 80000ae6 <kalloc>
    80001384:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001386:	c519                	beqz	a0,80001394 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    80001388:	6605                	lui	a2,0x1
    8000138a:	4581                	li	a1,0
    8000138c:	00000097          	auipc	ra,0x0
    80001390:	990080e7          	jalr	-1648(ra) # 80000d1c <memset>
  return pagetable;
}
    80001394:	8526                	mv	a0,s1
    80001396:	60e2                	ld	ra,24(sp)
    80001398:	6442                	ld	s0,16(sp)
    8000139a:	64a2                	ld	s1,8(sp)
    8000139c:	6105                	addi	sp,sp,32
    8000139e:	8082                	ret

00000000800013a0 <uvmfirst>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    800013a0:	7179                	addi	sp,sp,-48
    800013a2:	f406                	sd	ra,40(sp)
    800013a4:	f022                	sd	s0,32(sp)
    800013a6:	ec26                	sd	s1,24(sp)
    800013a8:	e84a                	sd	s2,16(sp)
    800013aa:	e44e                	sd	s3,8(sp)
    800013ac:	e052                	sd	s4,0(sp)
    800013ae:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800013b0:	6785                	lui	a5,0x1
    800013b2:	04f67863          	bgeu	a2,a5,80001402 <uvmfirst+0x62>
    800013b6:	8a2a                	mv	s4,a0
    800013b8:	89ae                	mv	s3,a1
    800013ba:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    800013bc:	fffff097          	auipc	ra,0xfffff
    800013c0:	72a080e7          	jalr	1834(ra) # 80000ae6 <kalloc>
    800013c4:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800013c6:	6605                	lui	a2,0x1
    800013c8:	4581                	li	a1,0
    800013ca:	00000097          	auipc	ra,0x0
    800013ce:	952080e7          	jalr	-1710(ra) # 80000d1c <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    800013d2:	4779                	li	a4,30
    800013d4:	86ca                	mv	a3,s2
    800013d6:	6605                	lui	a2,0x1
    800013d8:	4581                	li	a1,0
    800013da:	8552                	mv	a0,s4
    800013dc:	00000097          	auipc	ra,0x0
    800013e0:	d0c080e7          	jalr	-756(ra) # 800010e8 <mappages>
  memmove(mem, src, sz);
    800013e4:	8626                	mv	a2,s1
    800013e6:	85ce                	mv	a1,s3
    800013e8:	854a                	mv	a0,s2
    800013ea:	00000097          	auipc	ra,0x0
    800013ee:	98e080e7          	jalr	-1650(ra) # 80000d78 <memmove>
}
    800013f2:	70a2                	ld	ra,40(sp)
    800013f4:	7402                	ld	s0,32(sp)
    800013f6:	64e2                	ld	s1,24(sp)
    800013f8:	6942                	ld	s2,16(sp)
    800013fa:	69a2                	ld	s3,8(sp)
    800013fc:	6a02                	ld	s4,0(sp)
    800013fe:	6145                	addi	sp,sp,48
    80001400:	8082                	ret
    panic("uvmfirst: more than a page");
    80001402:	00007517          	auipc	a0,0x7
    80001406:	d5650513          	addi	a0,a0,-682 # 80008158 <digits+0x118>
    8000140a:	fffff097          	auipc	ra,0xfffff
    8000140e:	136080e7          	jalr	310(ra) # 80000540 <panic>

0000000080001412 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001412:	1101                	addi	sp,sp,-32
    80001414:	ec06                	sd	ra,24(sp)
    80001416:	e822                	sd	s0,16(sp)
    80001418:	e426                	sd	s1,8(sp)
    8000141a:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000141c:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    8000141e:	00b67d63          	bgeu	a2,a1,80001438 <uvmdealloc+0x26>
    80001422:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001424:	6785                	lui	a5,0x1
    80001426:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80001428:	00f60733          	add	a4,a2,a5
    8000142c:	76fd                	lui	a3,0xfffff
    8000142e:	8f75                	and	a4,a4,a3
    80001430:	97ae                	add	a5,a5,a1
    80001432:	8ff5                	and	a5,a5,a3
    80001434:	00f76863          	bltu	a4,a5,80001444 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    80001438:	8526                	mv	a0,s1
    8000143a:	60e2                	ld	ra,24(sp)
    8000143c:	6442                	ld	s0,16(sp)
    8000143e:	64a2                	ld	s1,8(sp)
    80001440:	6105                	addi	sp,sp,32
    80001442:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001444:	8f99                	sub	a5,a5,a4
    80001446:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    80001448:	4685                	li	a3,1
    8000144a:	0007861b          	sext.w	a2,a5
    8000144e:	85ba                	mv	a1,a4
    80001450:	00000097          	auipc	ra,0x0
    80001454:	e5e080e7          	jalr	-418(ra) # 800012ae <uvmunmap>
    80001458:	b7c5                	j	80001438 <uvmdealloc+0x26>

000000008000145a <uvmalloc>:
  if(newsz < oldsz)
    8000145a:	0ab66563          	bltu	a2,a1,80001504 <uvmalloc+0xaa>
{
    8000145e:	7139                	addi	sp,sp,-64
    80001460:	fc06                	sd	ra,56(sp)
    80001462:	f822                	sd	s0,48(sp)
    80001464:	f426                	sd	s1,40(sp)
    80001466:	f04a                	sd	s2,32(sp)
    80001468:	ec4e                	sd	s3,24(sp)
    8000146a:	e852                	sd	s4,16(sp)
    8000146c:	e456                	sd	s5,8(sp)
    8000146e:	e05a                	sd	s6,0(sp)
    80001470:	0080                	addi	s0,sp,64
    80001472:	8aaa                	mv	s5,a0
    80001474:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    80001476:	6785                	lui	a5,0x1
    80001478:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000147a:	95be                	add	a1,a1,a5
    8000147c:	77fd                	lui	a5,0xfffff
    8000147e:	00f5f9b3          	and	s3,a1,a5
  for(a = oldsz; a < newsz; a += PGSIZE){
    80001482:	08c9f363          	bgeu	s3,a2,80001508 <uvmalloc+0xae>
    80001486:	894e                	mv	s2,s3
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    80001488:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    8000148c:	fffff097          	auipc	ra,0xfffff
    80001490:	65a080e7          	jalr	1626(ra) # 80000ae6 <kalloc>
    80001494:	84aa                	mv	s1,a0
    if(mem == 0){
    80001496:	c51d                	beqz	a0,800014c4 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    80001498:	6605                	lui	a2,0x1
    8000149a:	4581                	li	a1,0
    8000149c:	00000097          	auipc	ra,0x0
    800014a0:	880080e7          	jalr	-1920(ra) # 80000d1c <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R|PTE_U|xperm) != 0){
    800014a4:	875a                	mv	a4,s6
    800014a6:	86a6                	mv	a3,s1
    800014a8:	6605                	lui	a2,0x1
    800014aa:	85ca                	mv	a1,s2
    800014ac:	8556                	mv	a0,s5
    800014ae:	00000097          	auipc	ra,0x0
    800014b2:	c3a080e7          	jalr	-966(ra) # 800010e8 <mappages>
    800014b6:	e90d                	bnez	a0,800014e8 <uvmalloc+0x8e>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800014b8:	6785                	lui	a5,0x1
    800014ba:	993e                	add	s2,s2,a5
    800014bc:	fd4968e3          	bltu	s2,s4,8000148c <uvmalloc+0x32>
  return newsz;
    800014c0:	8552                	mv	a0,s4
    800014c2:	a809                	j	800014d4 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    800014c4:	864e                	mv	a2,s3
    800014c6:	85ca                	mv	a1,s2
    800014c8:	8556                	mv	a0,s5
    800014ca:	00000097          	auipc	ra,0x0
    800014ce:	f48080e7          	jalr	-184(ra) # 80001412 <uvmdealloc>
      return 0;
    800014d2:	4501                	li	a0,0
}
    800014d4:	70e2                	ld	ra,56(sp)
    800014d6:	7442                	ld	s0,48(sp)
    800014d8:	74a2                	ld	s1,40(sp)
    800014da:	7902                	ld	s2,32(sp)
    800014dc:	69e2                	ld	s3,24(sp)
    800014de:	6a42                	ld	s4,16(sp)
    800014e0:	6aa2                	ld	s5,8(sp)
    800014e2:	6b02                	ld	s6,0(sp)
    800014e4:	6121                	addi	sp,sp,64
    800014e6:	8082                	ret
      kfree(mem);
    800014e8:	8526                	mv	a0,s1
    800014ea:	fffff097          	auipc	ra,0xfffff
    800014ee:	4fe080e7          	jalr	1278(ra) # 800009e8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    800014f2:	864e                	mv	a2,s3
    800014f4:	85ca                	mv	a1,s2
    800014f6:	8556                	mv	a0,s5
    800014f8:	00000097          	auipc	ra,0x0
    800014fc:	f1a080e7          	jalr	-230(ra) # 80001412 <uvmdealloc>
      return 0;
    80001500:	4501                	li	a0,0
    80001502:	bfc9                	j	800014d4 <uvmalloc+0x7a>
    return oldsz;
    80001504:	852e                	mv	a0,a1
}
    80001506:	8082                	ret
  return newsz;
    80001508:	8532                	mv	a0,a2
    8000150a:	b7e9                	j	800014d4 <uvmalloc+0x7a>

000000008000150c <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    8000150c:	7179                	addi	sp,sp,-48
    8000150e:	f406                	sd	ra,40(sp)
    80001510:	f022                	sd	s0,32(sp)
    80001512:	ec26                	sd	s1,24(sp)
    80001514:	e84a                	sd	s2,16(sp)
    80001516:	e44e                	sd	s3,8(sp)
    80001518:	e052                	sd	s4,0(sp)
    8000151a:	1800                	addi	s0,sp,48
    8000151c:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    8000151e:	84aa                	mv	s1,a0
    80001520:	6905                	lui	s2,0x1
    80001522:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001524:	4985                	li	s3,1
    80001526:	a829                	j	80001540 <freewalk+0x34>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001528:	83a9                	srli	a5,a5,0xa
      freewalk((pagetable_t)child);
    8000152a:	00c79513          	slli	a0,a5,0xc
    8000152e:	00000097          	auipc	ra,0x0
    80001532:	fde080e7          	jalr	-34(ra) # 8000150c <freewalk>
      pagetable[i] = 0;
    80001536:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    8000153a:	04a1                	addi	s1,s1,8
    8000153c:	03248163          	beq	s1,s2,8000155e <freewalk+0x52>
    pte_t pte = pagetable[i];
    80001540:	609c                	ld	a5,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    80001542:	00f7f713          	andi	a4,a5,15
    80001546:	ff3701e3          	beq	a4,s3,80001528 <freewalk+0x1c>
    } else if(pte & PTE_V){
    8000154a:	8b85                	andi	a5,a5,1
    8000154c:	d7fd                	beqz	a5,8000153a <freewalk+0x2e>
      panic("freewalk: leaf");
    8000154e:	00007517          	auipc	a0,0x7
    80001552:	c2a50513          	addi	a0,a0,-982 # 80008178 <digits+0x138>
    80001556:	fffff097          	auipc	ra,0xfffff
    8000155a:	fea080e7          	jalr	-22(ra) # 80000540 <panic>
    }
  }
  kfree((void*)pagetable);
    8000155e:	8552                	mv	a0,s4
    80001560:	fffff097          	auipc	ra,0xfffff
    80001564:	488080e7          	jalr	1160(ra) # 800009e8 <kfree>
}
    80001568:	70a2                	ld	ra,40(sp)
    8000156a:	7402                	ld	s0,32(sp)
    8000156c:	64e2                	ld	s1,24(sp)
    8000156e:	6942                	ld	s2,16(sp)
    80001570:	69a2                	ld	s3,8(sp)
    80001572:	6a02                	ld	s4,0(sp)
    80001574:	6145                	addi	sp,sp,48
    80001576:	8082                	ret

0000000080001578 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    80001578:	1101                	addi	sp,sp,-32
    8000157a:	ec06                	sd	ra,24(sp)
    8000157c:	e822                	sd	s0,16(sp)
    8000157e:	e426                	sd	s1,8(sp)
    80001580:	1000                	addi	s0,sp,32
    80001582:	84aa                	mv	s1,a0
  if(sz > 0)
    80001584:	e999                	bnez	a1,8000159a <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    80001586:	8526                	mv	a0,s1
    80001588:	00000097          	auipc	ra,0x0
    8000158c:	f84080e7          	jalr	-124(ra) # 8000150c <freewalk>
}
    80001590:	60e2                	ld	ra,24(sp)
    80001592:	6442                	ld	s0,16(sp)
    80001594:	64a2                	ld	s1,8(sp)
    80001596:	6105                	addi	sp,sp,32
    80001598:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    8000159a:	6785                	lui	a5,0x1
    8000159c:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    8000159e:	95be                	add	a1,a1,a5
    800015a0:	4685                	li	a3,1
    800015a2:	00c5d613          	srli	a2,a1,0xc
    800015a6:	4581                	li	a1,0
    800015a8:	00000097          	auipc	ra,0x0
    800015ac:	d06080e7          	jalr	-762(ra) # 800012ae <uvmunmap>
    800015b0:	bfd9                	j	80001586 <uvmfree+0xe>

00000000800015b2 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800015b2:	c679                	beqz	a2,80001680 <uvmcopy+0xce>
{
    800015b4:	715d                	addi	sp,sp,-80
    800015b6:	e486                	sd	ra,72(sp)
    800015b8:	e0a2                	sd	s0,64(sp)
    800015ba:	fc26                	sd	s1,56(sp)
    800015bc:	f84a                	sd	s2,48(sp)
    800015be:	f44e                	sd	s3,40(sp)
    800015c0:	f052                	sd	s4,32(sp)
    800015c2:	ec56                	sd	s5,24(sp)
    800015c4:	e85a                	sd	s6,16(sp)
    800015c6:	e45e                	sd	s7,8(sp)
    800015c8:	0880                	addi	s0,sp,80
    800015ca:	8b2a                	mv	s6,a0
    800015cc:	8aae                	mv	s5,a1
    800015ce:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800015d0:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800015d2:	4601                	li	a2,0
    800015d4:	85ce                	mv	a1,s3
    800015d6:	855a                	mv	a0,s6
    800015d8:	00000097          	auipc	ra,0x0
    800015dc:	a28080e7          	jalr	-1496(ra) # 80001000 <walk>
    800015e0:	c531                	beqz	a0,8000162c <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    800015e2:	6118                	ld	a4,0(a0)
    800015e4:	00177793          	andi	a5,a4,1
    800015e8:	cbb1                	beqz	a5,8000163c <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    800015ea:	00a75593          	srli	a1,a4,0xa
    800015ee:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    800015f2:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    800015f6:	fffff097          	auipc	ra,0xfffff
    800015fa:	4f0080e7          	jalr	1264(ra) # 80000ae6 <kalloc>
    800015fe:	892a                	mv	s2,a0
    80001600:	c939                	beqz	a0,80001656 <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001602:	6605                	lui	a2,0x1
    80001604:	85de                	mv	a1,s7
    80001606:	fffff097          	auipc	ra,0xfffff
    8000160a:	772080e7          	jalr	1906(ra) # 80000d78 <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    8000160e:	8726                	mv	a4,s1
    80001610:	86ca                	mv	a3,s2
    80001612:	6605                	lui	a2,0x1
    80001614:	85ce                	mv	a1,s3
    80001616:	8556                	mv	a0,s5
    80001618:	00000097          	auipc	ra,0x0
    8000161c:	ad0080e7          	jalr	-1328(ra) # 800010e8 <mappages>
    80001620:	e515                	bnez	a0,8000164c <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    80001622:	6785                	lui	a5,0x1
    80001624:	99be                	add	s3,s3,a5
    80001626:	fb49e6e3          	bltu	s3,s4,800015d2 <uvmcopy+0x20>
    8000162a:	a081                	j	8000166a <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    8000162c:	00007517          	auipc	a0,0x7
    80001630:	b5c50513          	addi	a0,a0,-1188 # 80008188 <digits+0x148>
    80001634:	fffff097          	auipc	ra,0xfffff
    80001638:	f0c080e7          	jalr	-244(ra) # 80000540 <panic>
      panic("uvmcopy: page not present");
    8000163c:	00007517          	auipc	a0,0x7
    80001640:	b6c50513          	addi	a0,a0,-1172 # 800081a8 <digits+0x168>
    80001644:	fffff097          	auipc	ra,0xfffff
    80001648:	efc080e7          	jalr	-260(ra) # 80000540 <panic>
      kfree(mem);
    8000164c:	854a                	mv	a0,s2
    8000164e:	fffff097          	auipc	ra,0xfffff
    80001652:	39a080e7          	jalr	922(ra) # 800009e8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    80001656:	4685                	li	a3,1
    80001658:	00c9d613          	srli	a2,s3,0xc
    8000165c:	4581                	li	a1,0
    8000165e:	8556                	mv	a0,s5
    80001660:	00000097          	auipc	ra,0x0
    80001664:	c4e080e7          	jalr	-946(ra) # 800012ae <uvmunmap>
  return -1;
    80001668:	557d                	li	a0,-1
}
    8000166a:	60a6                	ld	ra,72(sp)
    8000166c:	6406                	ld	s0,64(sp)
    8000166e:	74e2                	ld	s1,56(sp)
    80001670:	7942                	ld	s2,48(sp)
    80001672:	79a2                	ld	s3,40(sp)
    80001674:	7a02                	ld	s4,32(sp)
    80001676:	6ae2                	ld	s5,24(sp)
    80001678:	6b42                	ld	s6,16(sp)
    8000167a:	6ba2                	ld	s7,8(sp)
    8000167c:	6161                	addi	sp,sp,80
    8000167e:	8082                	ret
  return 0;
    80001680:	4501                	li	a0,0
}
    80001682:	8082                	ret

0000000080001684 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    80001684:	1141                	addi	sp,sp,-16
    80001686:	e406                	sd	ra,8(sp)
    80001688:	e022                	sd	s0,0(sp)
    8000168a:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    8000168c:	4601                	li	a2,0
    8000168e:	00000097          	auipc	ra,0x0
    80001692:	972080e7          	jalr	-1678(ra) # 80001000 <walk>
  if(pte == 0)
    80001696:	c901                	beqz	a0,800016a6 <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    80001698:	611c                	ld	a5,0(a0)
    8000169a:	9bbd                	andi	a5,a5,-17
    8000169c:	e11c                	sd	a5,0(a0)
}
    8000169e:	60a2                	ld	ra,8(sp)
    800016a0:	6402                	ld	s0,0(sp)
    800016a2:	0141                	addi	sp,sp,16
    800016a4:	8082                	ret
    panic("uvmclear");
    800016a6:	00007517          	auipc	a0,0x7
    800016aa:	b2250513          	addi	a0,a0,-1246 # 800081c8 <digits+0x188>
    800016ae:	fffff097          	auipc	ra,0xfffff
    800016b2:	e92080e7          	jalr	-366(ra) # 80000540 <panic>

00000000800016b6 <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800016b6:	c6bd                	beqz	a3,80001724 <copyout+0x6e>
{
    800016b8:	715d                	addi	sp,sp,-80
    800016ba:	e486                	sd	ra,72(sp)
    800016bc:	e0a2                	sd	s0,64(sp)
    800016be:	fc26                	sd	s1,56(sp)
    800016c0:	f84a                	sd	s2,48(sp)
    800016c2:	f44e                	sd	s3,40(sp)
    800016c4:	f052                	sd	s4,32(sp)
    800016c6:	ec56                	sd	s5,24(sp)
    800016c8:	e85a                	sd	s6,16(sp)
    800016ca:	e45e                	sd	s7,8(sp)
    800016cc:	e062                	sd	s8,0(sp)
    800016ce:	0880                	addi	s0,sp,80
    800016d0:	8b2a                	mv	s6,a0
    800016d2:	8c2e                	mv	s8,a1
    800016d4:	8a32                	mv	s4,a2
    800016d6:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800016d8:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    800016da:	6a85                	lui	s5,0x1
    800016dc:	a015                	j	80001700 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    800016de:	9562                	add	a0,a0,s8
    800016e0:	0004861b          	sext.w	a2,s1
    800016e4:	85d2                	mv	a1,s4
    800016e6:	41250533          	sub	a0,a0,s2
    800016ea:	fffff097          	auipc	ra,0xfffff
    800016ee:	68e080e7          	jalr	1678(ra) # 80000d78 <memmove>

    len -= n;
    800016f2:	409989b3          	sub	s3,s3,s1
    src += n;
    800016f6:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    800016f8:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800016fc:	02098263          	beqz	s3,80001720 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001700:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001704:	85ca                	mv	a1,s2
    80001706:	855a                	mv	a0,s6
    80001708:	00000097          	auipc	ra,0x0
    8000170c:	99e080e7          	jalr	-1634(ra) # 800010a6 <walkaddr>
    if(pa0 == 0)
    80001710:	cd01                	beqz	a0,80001728 <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001712:	418904b3          	sub	s1,s2,s8
    80001716:	94d6                	add	s1,s1,s5
    80001718:	fc99f3e3          	bgeu	s3,s1,800016de <copyout+0x28>
    8000171c:	84ce                	mv	s1,s3
    8000171e:	b7c1                	j	800016de <copyout+0x28>
  }
  return 0;
    80001720:	4501                	li	a0,0
    80001722:	a021                	j	8000172a <copyout+0x74>
    80001724:	4501                	li	a0,0
}
    80001726:	8082                	ret
      return -1;
    80001728:	557d                	li	a0,-1
}
    8000172a:	60a6                	ld	ra,72(sp)
    8000172c:	6406                	ld	s0,64(sp)
    8000172e:	74e2                	ld	s1,56(sp)
    80001730:	7942                	ld	s2,48(sp)
    80001732:	79a2                	ld	s3,40(sp)
    80001734:	7a02                	ld	s4,32(sp)
    80001736:	6ae2                	ld	s5,24(sp)
    80001738:	6b42                	ld	s6,16(sp)
    8000173a:	6ba2                	ld	s7,8(sp)
    8000173c:	6c02                	ld	s8,0(sp)
    8000173e:	6161                	addi	sp,sp,80
    80001740:	8082                	ret

0000000080001742 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001742:	caa5                	beqz	a3,800017b2 <copyin+0x70>
{
    80001744:	715d                	addi	sp,sp,-80
    80001746:	e486                	sd	ra,72(sp)
    80001748:	e0a2                	sd	s0,64(sp)
    8000174a:	fc26                	sd	s1,56(sp)
    8000174c:	f84a                	sd	s2,48(sp)
    8000174e:	f44e                	sd	s3,40(sp)
    80001750:	f052                	sd	s4,32(sp)
    80001752:	ec56                	sd	s5,24(sp)
    80001754:	e85a                	sd	s6,16(sp)
    80001756:	e45e                	sd	s7,8(sp)
    80001758:	e062                	sd	s8,0(sp)
    8000175a:	0880                	addi	s0,sp,80
    8000175c:	8b2a                	mv	s6,a0
    8000175e:	8a2e                	mv	s4,a1
    80001760:	8c32                	mv	s8,a2
    80001762:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    80001764:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001766:	6a85                	lui	s5,0x1
    80001768:	a01d                	j	8000178e <copyin+0x4c>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    8000176a:	018505b3          	add	a1,a0,s8
    8000176e:	0004861b          	sext.w	a2,s1
    80001772:	412585b3          	sub	a1,a1,s2
    80001776:	8552                	mv	a0,s4
    80001778:	fffff097          	auipc	ra,0xfffff
    8000177c:	600080e7          	jalr	1536(ra) # 80000d78 <memmove>

    len -= n;
    80001780:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001784:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001786:	01590c33          	add	s8,s2,s5
  while(len > 0){
    8000178a:	02098263          	beqz	s3,800017ae <copyin+0x6c>
    va0 = PGROUNDDOWN(srcva);
    8000178e:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001792:	85ca                	mv	a1,s2
    80001794:	855a                	mv	a0,s6
    80001796:	00000097          	auipc	ra,0x0
    8000179a:	910080e7          	jalr	-1776(ra) # 800010a6 <walkaddr>
    if(pa0 == 0)
    8000179e:	cd01                	beqz	a0,800017b6 <copyin+0x74>
    n = PGSIZE - (srcva - va0);
    800017a0:	418904b3          	sub	s1,s2,s8
    800017a4:	94d6                	add	s1,s1,s5
    800017a6:	fc99f2e3          	bgeu	s3,s1,8000176a <copyin+0x28>
    800017aa:	84ce                	mv	s1,s3
    800017ac:	bf7d                	j	8000176a <copyin+0x28>
  }
  return 0;
    800017ae:	4501                	li	a0,0
    800017b0:	a021                	j	800017b8 <copyin+0x76>
    800017b2:	4501                	li	a0,0
}
    800017b4:	8082                	ret
      return -1;
    800017b6:	557d                	li	a0,-1
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
    800017ca:	6c02                	ld	s8,0(sp)
    800017cc:	6161                	addi	sp,sp,80
    800017ce:	8082                	ret

00000000800017d0 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800017d0:	c2dd                	beqz	a3,80001876 <copyinstr+0xa6>
{
    800017d2:	715d                	addi	sp,sp,-80
    800017d4:	e486                	sd	ra,72(sp)
    800017d6:	e0a2                	sd	s0,64(sp)
    800017d8:	fc26                	sd	s1,56(sp)
    800017da:	f84a                	sd	s2,48(sp)
    800017dc:	f44e                	sd	s3,40(sp)
    800017de:	f052                	sd	s4,32(sp)
    800017e0:	ec56                	sd	s5,24(sp)
    800017e2:	e85a                	sd	s6,16(sp)
    800017e4:	e45e                	sd	s7,8(sp)
    800017e6:	0880                	addi	s0,sp,80
    800017e8:	8a2a                	mv	s4,a0
    800017ea:	8b2e                	mv	s6,a1
    800017ec:	8bb2                	mv	s7,a2
    800017ee:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    800017f0:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    800017f2:	6985                	lui	s3,0x1
    800017f4:	a02d                	j	8000181e <copyinstr+0x4e>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    800017f6:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    800017fa:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    800017fc:	37fd                	addiw	a5,a5,-1
    800017fe:	0007851b          	sext.w	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001802:	60a6                	ld	ra,72(sp)
    80001804:	6406                	ld	s0,64(sp)
    80001806:	74e2                	ld	s1,56(sp)
    80001808:	7942                	ld	s2,48(sp)
    8000180a:	79a2                	ld	s3,40(sp)
    8000180c:	7a02                	ld	s4,32(sp)
    8000180e:	6ae2                	ld	s5,24(sp)
    80001810:	6b42                	ld	s6,16(sp)
    80001812:	6ba2                	ld	s7,8(sp)
    80001814:	6161                	addi	sp,sp,80
    80001816:	8082                	ret
    srcva = va0 + PGSIZE;
    80001818:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    8000181c:	c8a9                	beqz	s1,8000186e <copyinstr+0x9e>
    va0 = PGROUNDDOWN(srcva);
    8000181e:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001822:	85ca                	mv	a1,s2
    80001824:	8552                	mv	a0,s4
    80001826:	00000097          	auipc	ra,0x0
    8000182a:	880080e7          	jalr	-1920(ra) # 800010a6 <walkaddr>
    if(pa0 == 0)
    8000182e:	c131                	beqz	a0,80001872 <copyinstr+0xa2>
    n = PGSIZE - (srcva - va0);
    80001830:	417906b3          	sub	a3,s2,s7
    80001834:	96ce                	add	a3,a3,s3
    80001836:	00d4f363          	bgeu	s1,a3,8000183c <copyinstr+0x6c>
    8000183a:	86a6                	mv	a3,s1
    char *p = (char *) (pa0 + (srcva - va0));
    8000183c:	955e                	add	a0,a0,s7
    8000183e:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001842:	daf9                	beqz	a3,80001818 <copyinstr+0x48>
    80001844:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001846:	41650633          	sub	a2,a0,s6
    8000184a:	fff48593          	addi	a1,s1,-1
    8000184e:	95da                	add	a1,a1,s6
    while(n > 0){
    80001850:	96da                	add	a3,a3,s6
      if(*p == '\0'){
    80001852:	00f60733          	add	a4,a2,a5
    80001856:	00074703          	lbu	a4,0(a4) # fffffffffffff000 <end+0xffffffff7ffdd0b0>
    8000185a:	df51                	beqz	a4,800017f6 <copyinstr+0x26>
        *dst = *p;
    8000185c:	00e78023          	sb	a4,0(a5)
      --max;
    80001860:	40f584b3          	sub	s1,a1,a5
      dst++;
    80001864:	0785                	addi	a5,a5,1
    while(n > 0){
    80001866:	fed796e3          	bne	a5,a3,80001852 <copyinstr+0x82>
      dst++;
    8000186a:	8b3e                	mv	s6,a5
    8000186c:	b775                	j	80001818 <copyinstr+0x48>
    8000186e:	4781                	li	a5,0
    80001870:	b771                	j	800017fc <copyinstr+0x2c>
      return -1;
    80001872:	557d                	li	a0,-1
    80001874:	b779                	j	80001802 <copyinstr+0x32>
  int got_null = 0;
    80001876:	4781                	li	a5,0
  if(got_null){
    80001878:	37fd                	addiw	a5,a5,-1
    8000187a:	0007851b          	sext.w	a0,a5
}
    8000187e:	8082                	ret

0000000080001880 <proc_mapstacks>:
// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl)
{
    80001880:	7139                	addi	sp,sp,-64
    80001882:	fc06                	sd	ra,56(sp)
    80001884:	f822                	sd	s0,48(sp)
    80001886:	f426                	sd	s1,40(sp)
    80001888:	f04a                	sd	s2,32(sp)
    8000188a:	ec4e                	sd	s3,24(sp)
    8000188c:	e852                	sd	s4,16(sp)
    8000188e:	e456                	sd	s5,8(sp)
    80001890:	e05a                	sd	s6,0(sp)
    80001892:	0080                	addi	s0,sp,64
    80001894:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001896:	00010497          	auipc	s1,0x10
    8000189a:	8da48493          	addi	s1,s1,-1830 # 80011170 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    8000189e:	8b26                	mv	s6,s1
    800018a0:	00006a97          	auipc	s5,0x6
    800018a4:	760a8a93          	addi	s5,s5,1888 # 80008000 <etext>
    800018a8:	04000937          	lui	s2,0x4000
    800018ac:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    800018ae:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    800018b0:	00015a17          	auipc	s4,0x15
    800018b4:	2c0a0a13          	addi	s4,s4,704 # 80016b70 <tickslock>
    char *pa = kalloc();
    800018b8:	fffff097          	auipc	ra,0xfffff
    800018bc:	22e080e7          	jalr	558(ra) # 80000ae6 <kalloc>
    800018c0:	862a                	mv	a2,a0
    if(pa == 0)
    800018c2:	c131                	beqz	a0,80001906 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    800018c4:	416485b3          	sub	a1,s1,s6
    800018c8:	858d                	srai	a1,a1,0x3
    800018ca:	000ab783          	ld	a5,0(s5)
    800018ce:	02f585b3          	mul	a1,a1,a5
    800018d2:	2585                	addiw	a1,a1,1
    800018d4:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    800018d8:	4719                	li	a4,6
    800018da:	6685                	lui	a3,0x1
    800018dc:	40b905b3          	sub	a1,s2,a1
    800018e0:	854e                	mv	a0,s3
    800018e2:	00000097          	auipc	ra,0x0
    800018e6:	8a6080e7          	jalr	-1882(ra) # 80001188 <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    800018ea:	16848493          	addi	s1,s1,360
    800018ee:	fd4495e3          	bne	s1,s4,800018b8 <proc_mapstacks+0x38>
  }
}
    800018f2:	70e2                	ld	ra,56(sp)
    800018f4:	7442                	ld	s0,48(sp)
    800018f6:	74a2                	ld	s1,40(sp)
    800018f8:	7902                	ld	s2,32(sp)
    800018fa:	69e2                	ld	s3,24(sp)
    800018fc:	6a42                	ld	s4,16(sp)
    800018fe:	6aa2                	ld	s5,8(sp)
    80001900:	6b02                	ld	s6,0(sp)
    80001902:	6121                	addi	sp,sp,64
    80001904:	8082                	ret
      panic("kalloc");
    80001906:	00007517          	auipc	a0,0x7
    8000190a:	8d250513          	addi	a0,a0,-1838 # 800081d8 <digits+0x198>
    8000190e:	fffff097          	auipc	ra,0xfffff
    80001912:	c32080e7          	jalr	-974(ra) # 80000540 <panic>

0000000080001916 <procinit>:

// initialize the proc table.
void
procinit(void)
{
    80001916:	7139                	addi	sp,sp,-64
    80001918:	fc06                	sd	ra,56(sp)
    8000191a:	f822                	sd	s0,48(sp)
    8000191c:	f426                	sd	s1,40(sp)
    8000191e:	f04a                	sd	s2,32(sp)
    80001920:	ec4e                	sd	s3,24(sp)
    80001922:	e852                	sd	s4,16(sp)
    80001924:	e456                	sd	s5,8(sp)
    80001926:	e05a                	sd	s6,0(sp)
    80001928:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    8000192a:	00007597          	auipc	a1,0x7
    8000192e:	8b658593          	addi	a1,a1,-1866 # 800081e0 <digits+0x1a0>
    80001932:	0000f517          	auipc	a0,0xf
    80001936:	40e50513          	addi	a0,a0,1038 # 80010d40 <pid_lock>
    8000193a:	fffff097          	auipc	ra,0xfffff
    8000193e:	256080e7          	jalr	598(ra) # 80000b90 <initlock>
  initlock(&wait_lock, "wait_lock");
    80001942:	00007597          	auipc	a1,0x7
    80001946:	8a658593          	addi	a1,a1,-1882 # 800081e8 <digits+0x1a8>
    8000194a:	0000f517          	auipc	a0,0xf
    8000194e:	40e50513          	addi	a0,a0,1038 # 80010d58 <wait_lock>
    80001952:	fffff097          	auipc	ra,0xfffff
    80001956:	23e080e7          	jalr	574(ra) # 80000b90 <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000195a:	00010497          	auipc	s1,0x10
    8000195e:	81648493          	addi	s1,s1,-2026 # 80011170 <proc>
      initlock(&p->lock, "proc");
    80001962:	00007b17          	auipc	s6,0x7
    80001966:	896b0b13          	addi	s6,s6,-1898 # 800081f8 <digits+0x1b8>
      p->state = UNUSED;
      p->kstack = KSTACK((int) (p - proc));
    8000196a:	8aa6                	mv	s5,s1
    8000196c:	00006a17          	auipc	s4,0x6
    80001970:	694a0a13          	addi	s4,s4,1684 # 80008000 <etext>
    80001974:	04000937          	lui	s2,0x4000
    80001978:	197d                	addi	s2,s2,-1 # 3ffffff <_entry-0x7c000001>
    8000197a:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    8000197c:	00015997          	auipc	s3,0x15
    80001980:	1f498993          	addi	s3,s3,500 # 80016b70 <tickslock>
      initlock(&p->lock, "proc");
    80001984:	85da                	mv	a1,s6
    80001986:	8526                	mv	a0,s1
    80001988:	fffff097          	auipc	ra,0xfffff
    8000198c:	208080e7          	jalr	520(ra) # 80000b90 <initlock>
      p->state = UNUSED;
    80001990:	0004ac23          	sw	zero,24(s1)
      p->kstack = KSTACK((int) (p - proc));
    80001994:	415487b3          	sub	a5,s1,s5
    80001998:	878d                	srai	a5,a5,0x3
    8000199a:	000a3703          	ld	a4,0(s4)
    8000199e:	02e787b3          	mul	a5,a5,a4
    800019a2:	2785                	addiw	a5,a5,1
    800019a4:	00d7979b          	slliw	a5,a5,0xd
    800019a8:	40f907b3          	sub	a5,s2,a5
    800019ac:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    800019ae:	16848493          	addi	s1,s1,360
    800019b2:	fd3499e3          	bne	s1,s3,80001984 <procinit+0x6e>
  }
}
    800019b6:	70e2                	ld	ra,56(sp)
    800019b8:	7442                	ld	s0,48(sp)
    800019ba:	74a2                	ld	s1,40(sp)
    800019bc:	7902                	ld	s2,32(sp)
    800019be:	69e2                	ld	s3,24(sp)
    800019c0:	6a42                	ld	s4,16(sp)
    800019c2:	6aa2                	ld	s5,8(sp)
    800019c4:	6b02                	ld	s6,0(sp)
    800019c6:	6121                	addi	sp,sp,64
    800019c8:	8082                	ret

00000000800019ca <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    800019ca:	1141                	addi	sp,sp,-16
    800019cc:	e422                	sd	s0,8(sp)
    800019ce:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    800019d0:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    800019d2:	2501                	sext.w	a0,a0
    800019d4:	6422                	ld	s0,8(sp)
    800019d6:	0141                	addi	sp,sp,16
    800019d8:	8082                	ret

00000000800019da <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void)
{
    800019da:	1141                	addi	sp,sp,-16
    800019dc:	e422                	sd	s0,8(sp)
    800019de:	0800                	addi	s0,sp,16
    800019e0:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    800019e2:	2781                	sext.w	a5,a5
    800019e4:	079e                	slli	a5,a5,0x7
  return c;
}
    800019e6:	0000f517          	auipc	a0,0xf
    800019ea:	38a50513          	addi	a0,a0,906 # 80010d70 <cpus>
    800019ee:	953e                	add	a0,a0,a5
    800019f0:	6422                	ld	s0,8(sp)
    800019f2:	0141                	addi	sp,sp,16
    800019f4:	8082                	ret

00000000800019f6 <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void)
{
    800019f6:	1101                	addi	sp,sp,-32
    800019f8:	ec06                	sd	ra,24(sp)
    800019fa:	e822                	sd	s0,16(sp)
    800019fc:	e426                	sd	s1,8(sp)
    800019fe:	1000                	addi	s0,sp,32
  push_off();
    80001a00:	fffff097          	auipc	ra,0xfffff
    80001a04:	1d4080e7          	jalr	468(ra) # 80000bd4 <push_off>
    80001a08:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001a0a:	2781                	sext.w	a5,a5
    80001a0c:	079e                	slli	a5,a5,0x7
    80001a0e:	0000f717          	auipc	a4,0xf
    80001a12:	33270713          	addi	a4,a4,818 # 80010d40 <pid_lock>
    80001a16:	97ba                	add	a5,a5,a4
    80001a18:	7b84                	ld	s1,48(a5)
  pop_off();
    80001a1a:	fffff097          	auipc	ra,0xfffff
    80001a1e:	25a080e7          	jalr	602(ra) # 80000c74 <pop_off>
  return p;
}
    80001a22:	8526                	mv	a0,s1
    80001a24:	60e2                	ld	ra,24(sp)
    80001a26:	6442                	ld	s0,16(sp)
    80001a28:	64a2                	ld	s1,8(sp)
    80001a2a:	6105                	addi	sp,sp,32
    80001a2c:	8082                	ret

0000000080001a2e <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001a2e:	1141                	addi	sp,sp,-16
    80001a30:	e406                	sd	ra,8(sp)
    80001a32:	e022                	sd	s0,0(sp)
    80001a34:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001a36:	00000097          	auipc	ra,0x0
    80001a3a:	fc0080e7          	jalr	-64(ra) # 800019f6 <myproc>
    80001a3e:	fffff097          	auipc	ra,0xfffff
    80001a42:	296080e7          	jalr	662(ra) # 80000cd4 <release>

  if (first) {
    80001a46:	00007797          	auipc	a5,0x7
    80001a4a:	f2a7a783          	lw	a5,-214(a5) # 80008970 <first.1>
    80001a4e:	eb89                	bnez	a5,80001a60 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001a50:	00001097          	auipc	ra,0x1
    80001a54:	cb6080e7          	jalr	-842(ra) # 80002706 <usertrapret>
}
    80001a58:	60a2                	ld	ra,8(sp)
    80001a5a:	6402                	ld	s0,0(sp)
    80001a5c:	0141                	addi	sp,sp,16
    80001a5e:	8082                	ret
    first = 0;
    80001a60:	00007797          	auipc	a5,0x7
    80001a64:	f007a823          	sw	zero,-240(a5) # 80008970 <first.1>
    fsinit(ROOTDEV);
    80001a68:	4505                	li	a0,1
    80001a6a:	00002097          	auipc	ra,0x2
    80001a6e:	a98080e7          	jalr	-1384(ra) # 80003502 <fsinit>
    80001a72:	bff9                	j	80001a50 <forkret+0x22>

0000000080001a74 <allocpid>:
{
    80001a74:	1101                	addi	sp,sp,-32
    80001a76:	ec06                	sd	ra,24(sp)
    80001a78:	e822                	sd	s0,16(sp)
    80001a7a:	e426                	sd	s1,8(sp)
    80001a7c:	e04a                	sd	s2,0(sp)
    80001a7e:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001a80:	0000f917          	auipc	s2,0xf
    80001a84:	2c090913          	addi	s2,s2,704 # 80010d40 <pid_lock>
    80001a88:	854a                	mv	a0,s2
    80001a8a:	fffff097          	auipc	ra,0xfffff
    80001a8e:	196080e7          	jalr	406(ra) # 80000c20 <acquire>
  pid = nextpid;
    80001a92:	00007797          	auipc	a5,0x7
    80001a96:	ee278793          	addi	a5,a5,-286 # 80008974 <nextpid>
    80001a9a:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001a9c:	0014871b          	addiw	a4,s1,1
    80001aa0:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001aa2:	854a                	mv	a0,s2
    80001aa4:	fffff097          	auipc	ra,0xfffff
    80001aa8:	230080e7          	jalr	560(ra) # 80000cd4 <release>
}
    80001aac:	8526                	mv	a0,s1
    80001aae:	60e2                	ld	ra,24(sp)
    80001ab0:	6442                	ld	s0,16(sp)
    80001ab2:	64a2                	ld	s1,8(sp)
    80001ab4:	6902                	ld	s2,0(sp)
    80001ab6:	6105                	addi	sp,sp,32
    80001ab8:	8082                	ret

0000000080001aba <proc_pagetable>:
{
    80001aba:	1101                	addi	sp,sp,-32
    80001abc:	ec06                	sd	ra,24(sp)
    80001abe:	e822                	sd	s0,16(sp)
    80001ac0:	e426                	sd	s1,8(sp)
    80001ac2:	e04a                	sd	s2,0(sp)
    80001ac4:	1000                	addi	s0,sp,32
    80001ac6:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001ac8:	00000097          	auipc	ra,0x0
    80001acc:	8aa080e7          	jalr	-1878(ra) # 80001372 <uvmcreate>
    80001ad0:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001ad2:	c121                	beqz	a0,80001b12 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001ad4:	4729                	li	a4,10
    80001ad6:	00005697          	auipc	a3,0x5
    80001ada:	52a68693          	addi	a3,a3,1322 # 80007000 <_trampoline>
    80001ade:	6605                	lui	a2,0x1
    80001ae0:	040005b7          	lui	a1,0x4000
    80001ae4:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001ae6:	05b2                	slli	a1,a1,0xc
    80001ae8:	fffff097          	auipc	ra,0xfffff
    80001aec:	600080e7          	jalr	1536(ra) # 800010e8 <mappages>
    80001af0:	02054863          	bltz	a0,80001b20 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001af4:	4719                	li	a4,6
    80001af6:	05893683          	ld	a3,88(s2)
    80001afa:	6605                	lui	a2,0x1
    80001afc:	020005b7          	lui	a1,0x2000
    80001b00:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b02:	05b6                	slli	a1,a1,0xd
    80001b04:	8526                	mv	a0,s1
    80001b06:	fffff097          	auipc	ra,0xfffff
    80001b0a:	5e2080e7          	jalr	1506(ra) # 800010e8 <mappages>
    80001b0e:	02054163          	bltz	a0,80001b30 <proc_pagetable+0x76>
}
    80001b12:	8526                	mv	a0,s1
    80001b14:	60e2                	ld	ra,24(sp)
    80001b16:	6442                	ld	s0,16(sp)
    80001b18:	64a2                	ld	s1,8(sp)
    80001b1a:	6902                	ld	s2,0(sp)
    80001b1c:	6105                	addi	sp,sp,32
    80001b1e:	8082                	ret
    uvmfree(pagetable, 0);
    80001b20:	4581                	li	a1,0
    80001b22:	8526                	mv	a0,s1
    80001b24:	00000097          	auipc	ra,0x0
    80001b28:	a54080e7          	jalr	-1452(ra) # 80001578 <uvmfree>
    return 0;
    80001b2c:	4481                	li	s1,0
    80001b2e:	b7d5                	j	80001b12 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b30:	4681                	li	a3,0
    80001b32:	4605                	li	a2,1
    80001b34:	040005b7          	lui	a1,0x4000
    80001b38:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b3a:	05b2                	slli	a1,a1,0xc
    80001b3c:	8526                	mv	a0,s1
    80001b3e:	fffff097          	auipc	ra,0xfffff
    80001b42:	770080e7          	jalr	1904(ra) # 800012ae <uvmunmap>
    uvmfree(pagetable, 0);
    80001b46:	4581                	li	a1,0
    80001b48:	8526                	mv	a0,s1
    80001b4a:	00000097          	auipc	ra,0x0
    80001b4e:	a2e080e7          	jalr	-1490(ra) # 80001578 <uvmfree>
    return 0;
    80001b52:	4481                	li	s1,0
    80001b54:	bf7d                	j	80001b12 <proc_pagetable+0x58>

0000000080001b56 <proc_freepagetable>:
{
    80001b56:	1101                	addi	sp,sp,-32
    80001b58:	ec06                	sd	ra,24(sp)
    80001b5a:	e822                	sd	s0,16(sp)
    80001b5c:	e426                	sd	s1,8(sp)
    80001b5e:	e04a                	sd	s2,0(sp)
    80001b60:	1000                	addi	s0,sp,32
    80001b62:	84aa                	mv	s1,a0
    80001b64:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001b66:	4681                	li	a3,0
    80001b68:	4605                	li	a2,1
    80001b6a:	040005b7          	lui	a1,0x4000
    80001b6e:	15fd                	addi	a1,a1,-1 # 3ffffff <_entry-0x7c000001>
    80001b70:	05b2                	slli	a1,a1,0xc
    80001b72:	fffff097          	auipc	ra,0xfffff
    80001b76:	73c080e7          	jalr	1852(ra) # 800012ae <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001b7a:	4681                	li	a3,0
    80001b7c:	4605                	li	a2,1
    80001b7e:	020005b7          	lui	a1,0x2000
    80001b82:	15fd                	addi	a1,a1,-1 # 1ffffff <_entry-0x7e000001>
    80001b84:	05b6                	slli	a1,a1,0xd
    80001b86:	8526                	mv	a0,s1
    80001b88:	fffff097          	auipc	ra,0xfffff
    80001b8c:	726080e7          	jalr	1830(ra) # 800012ae <uvmunmap>
  uvmfree(pagetable, sz);
    80001b90:	85ca                	mv	a1,s2
    80001b92:	8526                	mv	a0,s1
    80001b94:	00000097          	auipc	ra,0x0
    80001b98:	9e4080e7          	jalr	-1564(ra) # 80001578 <uvmfree>
}
    80001b9c:	60e2                	ld	ra,24(sp)
    80001b9e:	6442                	ld	s0,16(sp)
    80001ba0:	64a2                	ld	s1,8(sp)
    80001ba2:	6902                	ld	s2,0(sp)
    80001ba4:	6105                	addi	sp,sp,32
    80001ba6:	8082                	ret

0000000080001ba8 <freeproc>:
{
    80001ba8:	1101                	addi	sp,sp,-32
    80001baa:	ec06                	sd	ra,24(sp)
    80001bac:	e822                	sd	s0,16(sp)
    80001bae:	e426                	sd	s1,8(sp)
    80001bb0:	1000                	addi	s0,sp,32
    80001bb2:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001bb4:	6d28                	ld	a0,88(a0)
    80001bb6:	c509                	beqz	a0,80001bc0 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001bb8:	fffff097          	auipc	ra,0xfffff
    80001bbc:	e30080e7          	jalr	-464(ra) # 800009e8 <kfree>
  p->trapframe = 0;
    80001bc0:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001bc4:	68a8                	ld	a0,80(s1)
    80001bc6:	c511                	beqz	a0,80001bd2 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001bc8:	64ac                	ld	a1,72(s1)
    80001bca:	00000097          	auipc	ra,0x0
    80001bce:	f8c080e7          	jalr	-116(ra) # 80001b56 <proc_freepagetable>
  p->pagetable = 0;
    80001bd2:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001bd6:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001bda:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001bde:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001be2:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001be6:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001bea:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001bee:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001bf2:	0004ac23          	sw	zero,24(s1)
  p->tracer = 0;  // setting invalid value while freeing
    80001bf6:	0204aa23          	sw	zero,52(s1)
}
    80001bfa:	60e2                	ld	ra,24(sp)
    80001bfc:	6442                	ld	s0,16(sp)
    80001bfe:	64a2                	ld	s1,8(sp)
    80001c00:	6105                	addi	sp,sp,32
    80001c02:	8082                	ret

0000000080001c04 <allocproc>:
{
    80001c04:	1101                	addi	sp,sp,-32
    80001c06:	ec06                	sd	ra,24(sp)
    80001c08:	e822                	sd	s0,16(sp)
    80001c0a:	e426                	sd	s1,8(sp)
    80001c0c:	e04a                	sd	s2,0(sp)
    80001c0e:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c10:	0000f497          	auipc	s1,0xf
    80001c14:	56048493          	addi	s1,s1,1376 # 80011170 <proc>
    80001c18:	00015917          	auipc	s2,0x15
    80001c1c:	f5890913          	addi	s2,s2,-168 # 80016b70 <tickslock>
    acquire(&p->lock);
    80001c20:	8526                	mv	a0,s1
    80001c22:	fffff097          	auipc	ra,0xfffff
    80001c26:	ffe080e7          	jalr	-2(ra) # 80000c20 <acquire>
    if(p->state == UNUSED) {
    80001c2a:	4c9c                	lw	a5,24(s1)
    80001c2c:	cf81                	beqz	a5,80001c44 <allocproc+0x40>
      release(&p->lock);
    80001c2e:	8526                	mv	a0,s1
    80001c30:	fffff097          	auipc	ra,0xfffff
    80001c34:	0a4080e7          	jalr	164(ra) # 80000cd4 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001c38:	16848493          	addi	s1,s1,360
    80001c3c:	ff2492e3          	bne	s1,s2,80001c20 <allocproc+0x1c>
  return 0;
    80001c40:	4481                	li	s1,0
    80001c42:	a889                	j	80001c94 <allocproc+0x90>
  p->pid = allocpid();
    80001c44:	00000097          	auipc	ra,0x0
    80001c48:	e30080e7          	jalr	-464(ra) # 80001a74 <allocpid>
    80001c4c:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001c4e:	4785                	li	a5,1
    80001c50:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001c52:	fffff097          	auipc	ra,0xfffff
    80001c56:	e94080e7          	jalr	-364(ra) # 80000ae6 <kalloc>
    80001c5a:	892a                	mv	s2,a0
    80001c5c:	eca8                	sd	a0,88(s1)
    80001c5e:	c131                	beqz	a0,80001ca2 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001c60:	8526                	mv	a0,s1
    80001c62:	00000097          	auipc	ra,0x0
    80001c66:	e58080e7          	jalr	-424(ra) # 80001aba <proc_pagetable>
    80001c6a:	892a                	mv	s2,a0
    80001c6c:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001c6e:	c531                	beqz	a0,80001cba <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001c70:	07000613          	li	a2,112
    80001c74:	4581                	li	a1,0
    80001c76:	06048513          	addi	a0,s1,96
    80001c7a:	fffff097          	auipc	ra,0xfffff
    80001c7e:	0a2080e7          	jalr	162(ra) # 80000d1c <memset>
  p->context.ra = (uint64)forkret;
    80001c82:	00000797          	auipc	a5,0x0
    80001c86:	dac78793          	addi	a5,a5,-596 # 80001a2e <forkret>
    80001c8a:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001c8c:	60bc                	ld	a5,64(s1)
    80001c8e:	6705                	lui	a4,0x1
    80001c90:	97ba                	add	a5,a5,a4
    80001c92:	f4bc                	sd	a5,104(s1)
}
    80001c94:	8526                	mv	a0,s1
    80001c96:	60e2                	ld	ra,24(sp)
    80001c98:	6442                	ld	s0,16(sp)
    80001c9a:	64a2                	ld	s1,8(sp)
    80001c9c:	6902                	ld	s2,0(sp)
    80001c9e:	6105                	addi	sp,sp,32
    80001ca0:	8082                	ret
    freeproc(p);
    80001ca2:	8526                	mv	a0,s1
    80001ca4:	00000097          	auipc	ra,0x0
    80001ca8:	f04080e7          	jalr	-252(ra) # 80001ba8 <freeproc>
    release(&p->lock);
    80001cac:	8526                	mv	a0,s1
    80001cae:	fffff097          	auipc	ra,0xfffff
    80001cb2:	026080e7          	jalr	38(ra) # 80000cd4 <release>
    return 0;
    80001cb6:	84ca                	mv	s1,s2
    80001cb8:	bff1                	j	80001c94 <allocproc+0x90>
    freeproc(p);
    80001cba:	8526                	mv	a0,s1
    80001cbc:	00000097          	auipc	ra,0x0
    80001cc0:	eec080e7          	jalr	-276(ra) # 80001ba8 <freeproc>
    release(&p->lock);
    80001cc4:	8526                	mv	a0,s1
    80001cc6:	fffff097          	auipc	ra,0xfffff
    80001cca:	00e080e7          	jalr	14(ra) # 80000cd4 <release>
    return 0;
    80001cce:	84ca                	mv	s1,s2
    80001cd0:	b7d1                	j	80001c94 <allocproc+0x90>

0000000080001cd2 <userinit>:
{
    80001cd2:	1101                	addi	sp,sp,-32
    80001cd4:	ec06                	sd	ra,24(sp)
    80001cd6:	e822                	sd	s0,16(sp)
    80001cd8:	e426                	sd	s1,8(sp)
    80001cda:	1000                	addi	s0,sp,32
  p = allocproc();
    80001cdc:	00000097          	auipc	ra,0x0
    80001ce0:	f28080e7          	jalr	-216(ra) # 80001c04 <allocproc>
    80001ce4:	84aa                	mv	s1,a0
  initproc = p;
    80001ce6:	00007797          	auipc	a5,0x7
    80001cea:	dea7b123          	sd	a0,-542(a5) # 80008ac8 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    80001cee:	03400613          	li	a2,52
    80001cf2:	00007597          	auipc	a1,0x7
    80001cf6:	c8e58593          	addi	a1,a1,-882 # 80008980 <initcode>
    80001cfa:	6928                	ld	a0,80(a0)
    80001cfc:	fffff097          	auipc	ra,0xfffff
    80001d00:	6a4080e7          	jalr	1700(ra) # 800013a0 <uvmfirst>
  p->sz = PGSIZE;
    80001d04:	6785                	lui	a5,0x1
    80001d06:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001d08:	6cb8                	ld	a4,88(s1)
    80001d0a:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001d0e:	6cb8                	ld	a4,88(s1)
    80001d10:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001d12:	4641                	li	a2,16
    80001d14:	00006597          	auipc	a1,0x6
    80001d18:	4ec58593          	addi	a1,a1,1260 # 80008200 <digits+0x1c0>
    80001d1c:	15848513          	addi	a0,s1,344
    80001d20:	fffff097          	auipc	ra,0xfffff
    80001d24:	146080e7          	jalr	326(ra) # 80000e66 <safestrcpy>
  p->cwd = namei("/");
    80001d28:	00006517          	auipc	a0,0x6
    80001d2c:	4e850513          	addi	a0,a0,1256 # 80008210 <digits+0x1d0>
    80001d30:	00002097          	auipc	ra,0x2
    80001d34:	1fc080e7          	jalr	508(ra) # 80003f2c <namei>
    80001d38:	14a4b823          	sd	a0,336(s1)
  p->state = RUNNABLE;
    80001d3c:	478d                	li	a5,3
    80001d3e:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001d40:	8526                	mv	a0,s1
    80001d42:	fffff097          	auipc	ra,0xfffff
    80001d46:	f92080e7          	jalr	-110(ra) # 80000cd4 <release>
}
    80001d4a:	60e2                	ld	ra,24(sp)
    80001d4c:	6442                	ld	s0,16(sp)
    80001d4e:	64a2                	ld	s1,8(sp)
    80001d50:	6105                	addi	sp,sp,32
    80001d52:	8082                	ret

0000000080001d54 <growproc>:
{
    80001d54:	1101                	addi	sp,sp,-32
    80001d56:	ec06                	sd	ra,24(sp)
    80001d58:	e822                	sd	s0,16(sp)
    80001d5a:	e426                	sd	s1,8(sp)
    80001d5c:	e04a                	sd	s2,0(sp)
    80001d5e:	1000                	addi	s0,sp,32
    80001d60:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80001d62:	00000097          	auipc	ra,0x0
    80001d66:	c94080e7          	jalr	-876(ra) # 800019f6 <myproc>
    80001d6a:	84aa                	mv	s1,a0
  sz = p->sz;
    80001d6c:	652c                	ld	a1,72(a0)
  if(n > 0){
    80001d6e:	01204c63          	bgtz	s2,80001d86 <growproc+0x32>
  } else if(n < 0){
    80001d72:	02094663          	bltz	s2,80001d9e <growproc+0x4a>
  p->sz = sz;
    80001d76:	e4ac                	sd	a1,72(s1)
  return 0;
    80001d78:	4501                	li	a0,0
}
    80001d7a:	60e2                	ld	ra,24(sp)
    80001d7c:	6442                	ld	s0,16(sp)
    80001d7e:	64a2                	ld	s1,8(sp)
    80001d80:	6902                	ld	s2,0(sp)
    80001d82:	6105                	addi	sp,sp,32
    80001d84:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0) {
    80001d86:	4691                	li	a3,4
    80001d88:	00b90633          	add	a2,s2,a1
    80001d8c:	6928                	ld	a0,80(a0)
    80001d8e:	fffff097          	auipc	ra,0xfffff
    80001d92:	6cc080e7          	jalr	1740(ra) # 8000145a <uvmalloc>
    80001d96:	85aa                	mv	a1,a0
    80001d98:	fd79                	bnez	a0,80001d76 <growproc+0x22>
      return -1;
    80001d9a:	557d                	li	a0,-1
    80001d9c:	bff9                	j	80001d7a <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001d9e:	00b90633          	add	a2,s2,a1
    80001da2:	6928                	ld	a0,80(a0)
    80001da4:	fffff097          	auipc	ra,0xfffff
    80001da8:	66e080e7          	jalr	1646(ra) # 80001412 <uvmdealloc>
    80001dac:	85aa                	mv	a1,a0
    80001dae:	b7e1                	j	80001d76 <growproc+0x22>

0000000080001db0 <fork>:
{
    80001db0:	7139                	addi	sp,sp,-64
    80001db2:	fc06                	sd	ra,56(sp)
    80001db4:	f822                	sd	s0,48(sp)
    80001db6:	f426                	sd	s1,40(sp)
    80001db8:	f04a                	sd	s2,32(sp)
    80001dba:	ec4e                	sd	s3,24(sp)
    80001dbc:	e852                	sd	s4,16(sp)
    80001dbe:	e456                	sd	s5,8(sp)
    80001dc0:	0080                	addi	s0,sp,64
  struct proc *p = myproc();
    80001dc2:	00000097          	auipc	ra,0x0
    80001dc6:	c34080e7          	jalr	-972(ra) # 800019f6 <myproc>
    80001dca:	8aaa                	mv	s5,a0
  if((np = allocproc()) == 0){
    80001dcc:	00000097          	auipc	ra,0x0
    80001dd0:	e38080e7          	jalr	-456(ra) # 80001c04 <allocproc>
    80001dd4:	10050c63          	beqz	a0,80001eec <fork+0x13c>
    80001dd8:	8a2a                	mv	s4,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80001dda:	048ab603          	ld	a2,72(s5)
    80001dde:	692c                	ld	a1,80(a0)
    80001de0:	050ab503          	ld	a0,80(s5)
    80001de4:	fffff097          	auipc	ra,0xfffff
    80001de8:	7ce080e7          	jalr	1998(ra) # 800015b2 <uvmcopy>
    80001dec:	04054863          	bltz	a0,80001e3c <fork+0x8c>
  np->sz = p->sz;
    80001df0:	048ab783          	ld	a5,72(s5)
    80001df4:	04fa3423          	sd	a5,72(s4)
  *(np->trapframe) = *(p->trapframe);
    80001df8:	058ab683          	ld	a3,88(s5)
    80001dfc:	87b6                	mv	a5,a3
    80001dfe:	058a3703          	ld	a4,88(s4)
    80001e02:	12068693          	addi	a3,a3,288
    80001e06:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80001e0a:	6788                	ld	a0,8(a5)
    80001e0c:	6b8c                	ld	a1,16(a5)
    80001e0e:	6f90                	ld	a2,24(a5)
    80001e10:	01073023          	sd	a6,0(a4)
    80001e14:	e708                	sd	a0,8(a4)
    80001e16:	eb0c                	sd	a1,16(a4)
    80001e18:	ef10                	sd	a2,24(a4)
    80001e1a:	02078793          	addi	a5,a5,32
    80001e1e:	02070713          	addi	a4,a4,32
    80001e22:	fed792e3          	bne	a5,a3,80001e06 <fork+0x56>
  np->trapframe->a0 = 0;
    80001e26:	058a3783          	ld	a5,88(s4)
    80001e2a:	0607b823          	sd	zero,112(a5)
  for(i = 0; i < NOFILE; i++)
    80001e2e:	0d0a8493          	addi	s1,s5,208
    80001e32:	0d0a0913          	addi	s2,s4,208
    80001e36:	150a8993          	addi	s3,s5,336
    80001e3a:	a00d                	j	80001e5c <fork+0xac>
    freeproc(np);
    80001e3c:	8552                	mv	a0,s4
    80001e3e:	00000097          	auipc	ra,0x0
    80001e42:	d6a080e7          	jalr	-662(ra) # 80001ba8 <freeproc>
    release(&np->lock);
    80001e46:	8552                	mv	a0,s4
    80001e48:	fffff097          	auipc	ra,0xfffff
    80001e4c:	e8c080e7          	jalr	-372(ra) # 80000cd4 <release>
    return -1;
    80001e50:	597d                	li	s2,-1
    80001e52:	a059                	j	80001ed8 <fork+0x128>
  for(i = 0; i < NOFILE; i++)
    80001e54:	04a1                	addi	s1,s1,8
    80001e56:	0921                	addi	s2,s2,8
    80001e58:	01348b63          	beq	s1,s3,80001e6e <fork+0xbe>
    if(p->ofile[i])
    80001e5c:	6088                	ld	a0,0(s1)
    80001e5e:	d97d                	beqz	a0,80001e54 <fork+0xa4>
      np->ofile[i] = filedup(p->ofile[i]);
    80001e60:	00002097          	auipc	ra,0x2
    80001e64:	762080e7          	jalr	1890(ra) # 800045c2 <filedup>
    80001e68:	00a93023          	sd	a0,0(s2)
    80001e6c:	b7e5                	j	80001e54 <fork+0xa4>
  np->cwd = idup(p->cwd);
    80001e6e:	150ab503          	ld	a0,336(s5)
    80001e72:	00002097          	auipc	ra,0x2
    80001e76:	8d0080e7          	jalr	-1840(ra) # 80003742 <idup>
    80001e7a:	14aa3823          	sd	a0,336(s4)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80001e7e:	4641                	li	a2,16
    80001e80:	158a8593          	addi	a1,s5,344
    80001e84:	158a0513          	addi	a0,s4,344
    80001e88:	fffff097          	auipc	ra,0xfffff
    80001e8c:	fde080e7          	jalr	-34(ra) # 80000e66 <safestrcpy>
  pid = np->pid;
    80001e90:	030a2903          	lw	s2,48(s4)
  release(&np->lock);
    80001e94:	8552                	mv	a0,s4
    80001e96:	fffff097          	auipc	ra,0xfffff
    80001e9a:	e3e080e7          	jalr	-450(ra) # 80000cd4 <release>
  acquire(&wait_lock);
    80001e9e:	0000f497          	auipc	s1,0xf
    80001ea2:	eba48493          	addi	s1,s1,-326 # 80010d58 <wait_lock>
    80001ea6:	8526                	mv	a0,s1
    80001ea8:	fffff097          	auipc	ra,0xfffff
    80001eac:	d78080e7          	jalr	-648(ra) # 80000c20 <acquire>
  np->parent = p;
    80001eb0:	035a3c23          	sd	s5,56(s4)
  release(&wait_lock);
    80001eb4:	8526                	mv	a0,s1
    80001eb6:	fffff097          	auipc	ra,0xfffff
    80001eba:	e1e080e7          	jalr	-482(ra) # 80000cd4 <release>
  acquire(&np->lock);
    80001ebe:	8552                	mv	a0,s4
    80001ec0:	fffff097          	auipc	ra,0xfffff
    80001ec4:	d60080e7          	jalr	-672(ra) # 80000c20 <acquire>
  np->state = RUNNABLE;
    80001ec8:	478d                	li	a5,3
    80001eca:	00fa2c23          	sw	a5,24(s4)
  release(&np->lock);
    80001ece:	8552                	mv	a0,s4
    80001ed0:	fffff097          	auipc	ra,0xfffff
    80001ed4:	e04080e7          	jalr	-508(ra) # 80000cd4 <release>
}
    80001ed8:	854a                	mv	a0,s2
    80001eda:	70e2                	ld	ra,56(sp)
    80001edc:	7442                	ld	s0,48(sp)
    80001ede:	74a2                	ld	s1,40(sp)
    80001ee0:	7902                	ld	s2,32(sp)
    80001ee2:	69e2                	ld	s3,24(sp)
    80001ee4:	6a42                	ld	s4,16(sp)
    80001ee6:	6aa2                	ld	s5,8(sp)
    80001ee8:	6121                	addi	sp,sp,64
    80001eea:	8082                	ret
    return -1;
    80001eec:	597d                	li	s2,-1
    80001eee:	b7ed                	j	80001ed8 <fork+0x128>

0000000080001ef0 <scheduler>:
{
    80001ef0:	7139                	addi	sp,sp,-64
    80001ef2:	fc06                	sd	ra,56(sp)
    80001ef4:	f822                	sd	s0,48(sp)
    80001ef6:	f426                	sd	s1,40(sp)
    80001ef8:	f04a                	sd	s2,32(sp)
    80001efa:	ec4e                	sd	s3,24(sp)
    80001efc:	e852                	sd	s4,16(sp)
    80001efe:	e456                	sd	s5,8(sp)
    80001f00:	e05a                	sd	s6,0(sp)
    80001f02:	0080                	addi	s0,sp,64
    80001f04:	8792                	mv	a5,tp
  int id = r_tp();
    80001f06:	2781                	sext.w	a5,a5
  c->proc = 0;
    80001f08:	00779a93          	slli	s5,a5,0x7
    80001f0c:	0000f717          	auipc	a4,0xf
    80001f10:	e3470713          	addi	a4,a4,-460 # 80010d40 <pid_lock>
    80001f14:	9756                	add	a4,a4,s5
    80001f16:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    80001f1a:	0000f717          	auipc	a4,0xf
    80001f1e:	e5e70713          	addi	a4,a4,-418 # 80010d78 <cpus+0x8>
    80001f22:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80001f24:	498d                	li	s3,3
        p->state = RUNNING;
    80001f26:	4b11                	li	s6,4
        c->proc = p;
    80001f28:	079e                	slli	a5,a5,0x7
    80001f2a:	0000fa17          	auipc	s4,0xf
    80001f2e:	e16a0a13          	addi	s4,s4,-490 # 80010d40 <pid_lock>
    80001f32:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f34:	00015917          	auipc	s2,0x15
    80001f38:	c3c90913          	addi	s2,s2,-964 # 80016b70 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001f3c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80001f40:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80001f44:	10079073          	csrw	sstatus,a5
    80001f48:	0000f497          	auipc	s1,0xf
    80001f4c:	22848493          	addi	s1,s1,552 # 80011170 <proc>
    80001f50:	a811                	j	80001f64 <scheduler+0x74>
      release(&p->lock);
    80001f52:	8526                	mv	a0,s1
    80001f54:	fffff097          	auipc	ra,0xfffff
    80001f58:	d80080e7          	jalr	-640(ra) # 80000cd4 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    80001f5c:	16848493          	addi	s1,s1,360
    80001f60:	fd248ee3          	beq	s1,s2,80001f3c <scheduler+0x4c>
      acquire(&p->lock);
    80001f64:	8526                	mv	a0,s1
    80001f66:	fffff097          	auipc	ra,0xfffff
    80001f6a:	cba080e7          	jalr	-838(ra) # 80000c20 <acquire>
      if(p->state == RUNNABLE) {
    80001f6e:	4c9c                	lw	a5,24(s1)
    80001f70:	ff3791e3          	bne	a5,s3,80001f52 <scheduler+0x62>
        p->state = RUNNING;
    80001f74:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80001f78:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    80001f7c:	06048593          	addi	a1,s1,96
    80001f80:	8556                	mv	a0,s5
    80001f82:	00000097          	auipc	ra,0x0
    80001f86:	6da080e7          	jalr	1754(ra) # 8000265c <swtch>
        c->proc = 0;
    80001f8a:	020a3823          	sd	zero,48(s4)
    80001f8e:	b7d1                	j	80001f52 <scheduler+0x62>

0000000080001f90 <sched>:
{
    80001f90:	7179                	addi	sp,sp,-48
    80001f92:	f406                	sd	ra,40(sp)
    80001f94:	f022                	sd	s0,32(sp)
    80001f96:	ec26                	sd	s1,24(sp)
    80001f98:	e84a                	sd	s2,16(sp)
    80001f9a:	e44e                	sd	s3,8(sp)
    80001f9c:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001f9e:	00000097          	auipc	ra,0x0
    80001fa2:	a58080e7          	jalr	-1448(ra) # 800019f6 <myproc>
    80001fa6:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    80001fa8:	fffff097          	auipc	ra,0xfffff
    80001fac:	bfe080e7          	jalr	-1026(ra) # 80000ba6 <holding>
    80001fb0:	c93d                	beqz	a0,80002026 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fb2:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    80001fb4:	2781                	sext.w	a5,a5
    80001fb6:	079e                	slli	a5,a5,0x7
    80001fb8:	0000f717          	auipc	a4,0xf
    80001fbc:	d8870713          	addi	a4,a4,-632 # 80010d40 <pid_lock>
    80001fc0:	97ba                	add	a5,a5,a4
    80001fc2:	0a87a703          	lw	a4,168(a5)
    80001fc6:	4785                	li	a5,1
    80001fc8:	06f71763          	bne	a4,a5,80002036 <sched+0xa6>
  if(p->state == RUNNING)
    80001fcc:	4c98                	lw	a4,24(s1)
    80001fce:	4791                	li	a5,4
    80001fd0:	06f70b63          	beq	a4,a5,80002046 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80001fd4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80001fd8:	8b89                	andi	a5,a5,2
  if(intr_get())
    80001fda:	efb5                	bnez	a5,80002056 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    80001fdc:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80001fde:	0000f917          	auipc	s2,0xf
    80001fe2:	d6290913          	addi	s2,s2,-670 # 80010d40 <pid_lock>
    80001fe6:	2781                	sext.w	a5,a5
    80001fe8:	079e                	slli	a5,a5,0x7
    80001fea:	97ca                	add	a5,a5,s2
    80001fec:	0ac7a983          	lw	s3,172(a5)
    80001ff0:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80001ff2:	2781                	sext.w	a5,a5
    80001ff4:	079e                	slli	a5,a5,0x7
    80001ff6:	0000f597          	auipc	a1,0xf
    80001ffa:	d8258593          	addi	a1,a1,-638 # 80010d78 <cpus+0x8>
    80001ffe:	95be                	add	a1,a1,a5
    80002000:	06048513          	addi	a0,s1,96
    80002004:	00000097          	auipc	ra,0x0
    80002008:	658080e7          	jalr	1624(ra) # 8000265c <swtch>
    8000200c:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000200e:	2781                	sext.w	a5,a5
    80002010:	079e                	slli	a5,a5,0x7
    80002012:	993e                	add	s2,s2,a5
    80002014:	0b392623          	sw	s3,172(s2)
}
    80002018:	70a2                	ld	ra,40(sp)
    8000201a:	7402                	ld	s0,32(sp)
    8000201c:	64e2                	ld	s1,24(sp)
    8000201e:	6942                	ld	s2,16(sp)
    80002020:	69a2                	ld	s3,8(sp)
    80002022:	6145                	addi	sp,sp,48
    80002024:	8082                	ret
    panic("sched p->lock");
    80002026:	00006517          	auipc	a0,0x6
    8000202a:	1f250513          	addi	a0,a0,498 # 80008218 <digits+0x1d8>
    8000202e:	ffffe097          	auipc	ra,0xffffe
    80002032:	512080e7          	jalr	1298(ra) # 80000540 <panic>
    panic("sched locks");
    80002036:	00006517          	auipc	a0,0x6
    8000203a:	1f250513          	addi	a0,a0,498 # 80008228 <digits+0x1e8>
    8000203e:	ffffe097          	auipc	ra,0xffffe
    80002042:	502080e7          	jalr	1282(ra) # 80000540 <panic>
    panic("sched running");
    80002046:	00006517          	auipc	a0,0x6
    8000204a:	1f250513          	addi	a0,a0,498 # 80008238 <digits+0x1f8>
    8000204e:	ffffe097          	auipc	ra,0xffffe
    80002052:	4f2080e7          	jalr	1266(ra) # 80000540 <panic>
    panic("sched interruptible");
    80002056:	00006517          	auipc	a0,0x6
    8000205a:	1f250513          	addi	a0,a0,498 # 80008248 <digits+0x208>
    8000205e:	ffffe097          	auipc	ra,0xffffe
    80002062:	4e2080e7          	jalr	1250(ra) # 80000540 <panic>

0000000080002066 <yield>:
{
    80002066:	1101                	addi	sp,sp,-32
    80002068:	ec06                	sd	ra,24(sp)
    8000206a:	e822                	sd	s0,16(sp)
    8000206c:	e426                	sd	s1,8(sp)
    8000206e:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80002070:	00000097          	auipc	ra,0x0
    80002074:	986080e7          	jalr	-1658(ra) # 800019f6 <myproc>
    80002078:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000207a:	fffff097          	auipc	ra,0xfffff
    8000207e:	ba6080e7          	jalr	-1114(ra) # 80000c20 <acquire>
  p->state = RUNNABLE;
    80002082:	478d                	li	a5,3
    80002084:	cc9c                	sw	a5,24(s1)
  sched();
    80002086:	00000097          	auipc	ra,0x0
    8000208a:	f0a080e7          	jalr	-246(ra) # 80001f90 <sched>
  release(&p->lock);
    8000208e:	8526                	mv	a0,s1
    80002090:	fffff097          	auipc	ra,0xfffff
    80002094:	c44080e7          	jalr	-956(ra) # 80000cd4 <release>
}
    80002098:	60e2                	ld	ra,24(sp)
    8000209a:	6442                	ld	s0,16(sp)
    8000209c:	64a2                	ld	s1,8(sp)
    8000209e:	6105                	addi	sp,sp,32
    800020a0:	8082                	ret

00000000800020a2 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800020a2:	7179                	addi	sp,sp,-48
    800020a4:	f406                	sd	ra,40(sp)
    800020a6:	f022                	sd	s0,32(sp)
    800020a8:	ec26                	sd	s1,24(sp)
    800020aa:	e84a                	sd	s2,16(sp)
    800020ac:	e44e                	sd	s3,8(sp)
    800020ae:	1800                	addi	s0,sp,48
    800020b0:	89aa                	mv	s3,a0
    800020b2:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800020b4:	00000097          	auipc	ra,0x0
    800020b8:	942080e7          	jalr	-1726(ra) # 800019f6 <myproc>
    800020bc:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    800020be:	fffff097          	auipc	ra,0xfffff
    800020c2:	b62080e7          	jalr	-1182(ra) # 80000c20 <acquire>
  release(lk);
    800020c6:	854a                	mv	a0,s2
    800020c8:	fffff097          	auipc	ra,0xfffff
    800020cc:	c0c080e7          	jalr	-1012(ra) # 80000cd4 <release>

  // Go to sleep.
  p->chan = chan;
    800020d0:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    800020d4:	4789                	li	a5,2
    800020d6:	cc9c                	sw	a5,24(s1)

  sched();
    800020d8:	00000097          	auipc	ra,0x0
    800020dc:	eb8080e7          	jalr	-328(ra) # 80001f90 <sched>

  // Tidy up.
  p->chan = 0;
    800020e0:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800020e4:	8526                	mv	a0,s1
    800020e6:	fffff097          	auipc	ra,0xfffff
    800020ea:	bee080e7          	jalr	-1042(ra) # 80000cd4 <release>
  acquire(lk);
    800020ee:	854a                	mv	a0,s2
    800020f0:	fffff097          	auipc	ra,0xfffff
    800020f4:	b30080e7          	jalr	-1232(ra) # 80000c20 <acquire>
}
    800020f8:	70a2                	ld	ra,40(sp)
    800020fa:	7402                	ld	s0,32(sp)
    800020fc:	64e2                	ld	s1,24(sp)
    800020fe:	6942                	ld	s2,16(sp)
    80002100:	69a2                	ld	s3,8(sp)
    80002102:	6145                	addi	sp,sp,48
    80002104:	8082                	ret

0000000080002106 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    80002106:	7139                	addi	sp,sp,-64
    80002108:	fc06                	sd	ra,56(sp)
    8000210a:	f822                	sd	s0,48(sp)
    8000210c:	f426                	sd	s1,40(sp)
    8000210e:	f04a                	sd	s2,32(sp)
    80002110:	ec4e                	sd	s3,24(sp)
    80002112:	e852                	sd	s4,16(sp)
    80002114:	e456                	sd	s5,8(sp)
    80002116:	0080                	addi	s0,sp,64
    80002118:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    8000211a:	0000f497          	auipc	s1,0xf
    8000211e:	05648493          	addi	s1,s1,86 # 80011170 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    80002122:	4989                	li	s3,2
        p->state = RUNNABLE;
    80002124:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    80002126:	00015917          	auipc	s2,0x15
    8000212a:	a4a90913          	addi	s2,s2,-1462 # 80016b70 <tickslock>
    8000212e:	a811                	j	80002142 <wakeup+0x3c>
      }
      release(&p->lock);
    80002130:	8526                	mv	a0,s1
    80002132:	fffff097          	auipc	ra,0xfffff
    80002136:	ba2080e7          	jalr	-1118(ra) # 80000cd4 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    8000213a:	16848493          	addi	s1,s1,360
    8000213e:	03248663          	beq	s1,s2,8000216a <wakeup+0x64>
    if(p != myproc()){
    80002142:	00000097          	auipc	ra,0x0
    80002146:	8b4080e7          	jalr	-1868(ra) # 800019f6 <myproc>
    8000214a:	fea488e3          	beq	s1,a0,8000213a <wakeup+0x34>
      acquire(&p->lock);
    8000214e:	8526                	mv	a0,s1
    80002150:	fffff097          	auipc	ra,0xfffff
    80002154:	ad0080e7          	jalr	-1328(ra) # 80000c20 <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    80002158:	4c9c                	lw	a5,24(s1)
    8000215a:	fd379be3          	bne	a5,s3,80002130 <wakeup+0x2a>
    8000215e:	709c                	ld	a5,32(s1)
    80002160:	fd4798e3          	bne	a5,s4,80002130 <wakeup+0x2a>
        p->state = RUNNABLE;
    80002164:	0154ac23          	sw	s5,24(s1)
    80002168:	b7e1                	j	80002130 <wakeup+0x2a>
    }
  }
}
    8000216a:	70e2                	ld	ra,56(sp)
    8000216c:	7442                	ld	s0,48(sp)
    8000216e:	74a2                	ld	s1,40(sp)
    80002170:	7902                	ld	s2,32(sp)
    80002172:	69e2                	ld	s3,24(sp)
    80002174:	6a42                	ld	s4,16(sp)
    80002176:	6aa2                	ld	s5,8(sp)
    80002178:	6121                	addi	sp,sp,64
    8000217a:	8082                	ret

000000008000217c <reparent>:
{
    8000217c:	7179                	addi	sp,sp,-48
    8000217e:	f406                	sd	ra,40(sp)
    80002180:	f022                	sd	s0,32(sp)
    80002182:	ec26                	sd	s1,24(sp)
    80002184:	e84a                	sd	s2,16(sp)
    80002186:	e44e                	sd	s3,8(sp)
    80002188:	e052                	sd	s4,0(sp)
    8000218a:	1800                	addi	s0,sp,48
    8000218c:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000218e:	0000f497          	auipc	s1,0xf
    80002192:	fe248493          	addi	s1,s1,-30 # 80011170 <proc>
      pp->parent = initproc;
    80002196:	00007a17          	auipc	s4,0x7
    8000219a:	932a0a13          	addi	s4,s4,-1742 # 80008ac8 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    8000219e:	00015997          	auipc	s3,0x15
    800021a2:	9d298993          	addi	s3,s3,-1582 # 80016b70 <tickslock>
    800021a6:	a029                	j	800021b0 <reparent+0x34>
    800021a8:	16848493          	addi	s1,s1,360
    800021ac:	01348d63          	beq	s1,s3,800021c6 <reparent+0x4a>
    if(pp->parent == p){
    800021b0:	7c9c                	ld	a5,56(s1)
    800021b2:	ff279be3          	bne	a5,s2,800021a8 <reparent+0x2c>
      pp->parent = initproc;
    800021b6:	000a3503          	ld	a0,0(s4)
    800021ba:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    800021bc:	00000097          	auipc	ra,0x0
    800021c0:	f4a080e7          	jalr	-182(ra) # 80002106 <wakeup>
    800021c4:	b7d5                	j	800021a8 <reparent+0x2c>
}
    800021c6:	70a2                	ld	ra,40(sp)
    800021c8:	7402                	ld	s0,32(sp)
    800021ca:	64e2                	ld	s1,24(sp)
    800021cc:	6942                	ld	s2,16(sp)
    800021ce:	69a2                	ld	s3,8(sp)
    800021d0:	6a02                	ld	s4,0(sp)
    800021d2:	6145                	addi	sp,sp,48
    800021d4:	8082                	ret

00000000800021d6 <exit>:
{
    800021d6:	7179                	addi	sp,sp,-48
    800021d8:	f406                	sd	ra,40(sp)
    800021da:	f022                	sd	s0,32(sp)
    800021dc:	ec26                	sd	s1,24(sp)
    800021de:	e84a                	sd	s2,16(sp)
    800021e0:	e44e                	sd	s3,8(sp)
    800021e2:	e052                	sd	s4,0(sp)
    800021e4:	1800                	addi	s0,sp,48
    800021e6:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800021e8:	00000097          	auipc	ra,0x0
    800021ec:	80e080e7          	jalr	-2034(ra) # 800019f6 <myproc>
    800021f0:	89aa                	mv	s3,a0
  if(p == initproc)
    800021f2:	00007797          	auipc	a5,0x7
    800021f6:	8d67b783          	ld	a5,-1834(a5) # 80008ac8 <initproc>
    800021fa:	0d050493          	addi	s1,a0,208
    800021fe:	15050913          	addi	s2,a0,336
    80002202:	02a79363          	bne	a5,a0,80002228 <exit+0x52>
    panic("init exiting");
    80002206:	00006517          	auipc	a0,0x6
    8000220a:	05a50513          	addi	a0,a0,90 # 80008260 <digits+0x220>
    8000220e:	ffffe097          	auipc	ra,0xffffe
    80002212:	332080e7          	jalr	818(ra) # 80000540 <panic>
      fileclose(f);
    80002216:	00002097          	auipc	ra,0x2
    8000221a:	3fe080e7          	jalr	1022(ra) # 80004614 <fileclose>
      p->ofile[fd] = 0;
    8000221e:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    80002222:	04a1                	addi	s1,s1,8
    80002224:	01248563          	beq	s1,s2,8000222e <exit+0x58>
    if(p->ofile[fd]){
    80002228:	6088                	ld	a0,0(s1)
    8000222a:	f575                	bnez	a0,80002216 <exit+0x40>
    8000222c:	bfdd                	j	80002222 <exit+0x4c>
  begin_op();
    8000222e:	00002097          	auipc	ra,0x2
    80002232:	f1e080e7          	jalr	-226(ra) # 8000414c <begin_op>
  iput(p->cwd);
    80002236:	1509b503          	ld	a0,336(s3)
    8000223a:	00001097          	auipc	ra,0x1
    8000223e:	700080e7          	jalr	1792(ra) # 8000393a <iput>
  end_op();
    80002242:	00002097          	auipc	ra,0x2
    80002246:	f88080e7          	jalr	-120(ra) # 800041ca <end_op>
  p->cwd = 0;
    8000224a:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    8000224e:	0000f497          	auipc	s1,0xf
    80002252:	b0a48493          	addi	s1,s1,-1270 # 80010d58 <wait_lock>
    80002256:	8526                	mv	a0,s1
    80002258:	fffff097          	auipc	ra,0xfffff
    8000225c:	9c8080e7          	jalr	-1592(ra) # 80000c20 <acquire>
  reparent(p);
    80002260:	854e                	mv	a0,s3
    80002262:	00000097          	auipc	ra,0x0
    80002266:	f1a080e7          	jalr	-230(ra) # 8000217c <reparent>
  wakeup(p->parent);
    8000226a:	0389b503          	ld	a0,56(s3)
    8000226e:	00000097          	auipc	ra,0x0
    80002272:	e98080e7          	jalr	-360(ra) # 80002106 <wakeup>
  acquire(&p->lock);
    80002276:	854e                	mv	a0,s3
    80002278:	fffff097          	auipc	ra,0xfffff
    8000227c:	9a8080e7          	jalr	-1624(ra) # 80000c20 <acquire>
  p->xstate = status;
    80002280:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002284:	4795                	li	a5,5
    80002286:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    8000228a:	8526                	mv	a0,s1
    8000228c:	fffff097          	auipc	ra,0xfffff
    80002290:	a48080e7          	jalr	-1464(ra) # 80000cd4 <release>
  sched();
    80002294:	00000097          	auipc	ra,0x0
    80002298:	cfc080e7          	jalr	-772(ra) # 80001f90 <sched>
  panic("zombie exit");
    8000229c:	00006517          	auipc	a0,0x6
    800022a0:	fd450513          	addi	a0,a0,-44 # 80008270 <digits+0x230>
    800022a4:	ffffe097          	auipc	ra,0xffffe
    800022a8:	29c080e7          	jalr	668(ra) # 80000540 <panic>

00000000800022ac <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    800022ac:	7179                	addi	sp,sp,-48
    800022ae:	f406                	sd	ra,40(sp)
    800022b0:	f022                	sd	s0,32(sp)
    800022b2:	ec26                	sd	s1,24(sp)
    800022b4:	e84a                	sd	s2,16(sp)
    800022b6:	e44e                	sd	s3,8(sp)
    800022b8:	1800                	addi	s0,sp,48
    800022ba:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    800022bc:	0000f497          	auipc	s1,0xf
    800022c0:	eb448493          	addi	s1,s1,-332 # 80011170 <proc>
    800022c4:	00015997          	auipc	s3,0x15
    800022c8:	8ac98993          	addi	s3,s3,-1876 # 80016b70 <tickslock>
    acquire(&p->lock);
    800022cc:	8526                	mv	a0,s1
    800022ce:	fffff097          	auipc	ra,0xfffff
    800022d2:	952080e7          	jalr	-1710(ra) # 80000c20 <acquire>
    if(p->pid == pid){
    800022d6:	589c                	lw	a5,48(s1)
    800022d8:	01278d63          	beq	a5,s2,800022f2 <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800022dc:	8526                	mv	a0,s1
    800022de:	fffff097          	auipc	ra,0xfffff
    800022e2:	9f6080e7          	jalr	-1546(ra) # 80000cd4 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    800022e6:	16848493          	addi	s1,s1,360
    800022ea:	ff3491e3          	bne	s1,s3,800022cc <kill+0x20>
  }
  return -1;
    800022ee:	557d                	li	a0,-1
    800022f0:	a829                	j	8000230a <kill+0x5e>
      p->killed = 1;
    800022f2:	4785                	li	a5,1
    800022f4:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    800022f6:	4c98                	lw	a4,24(s1)
    800022f8:	4789                	li	a5,2
    800022fa:	00f70f63          	beq	a4,a5,80002318 <kill+0x6c>
      release(&p->lock);
    800022fe:	8526                	mv	a0,s1
    80002300:	fffff097          	auipc	ra,0xfffff
    80002304:	9d4080e7          	jalr	-1580(ra) # 80000cd4 <release>
      return 0;
    80002308:	4501                	li	a0,0
}
    8000230a:	70a2                	ld	ra,40(sp)
    8000230c:	7402                	ld	s0,32(sp)
    8000230e:	64e2                	ld	s1,24(sp)
    80002310:	6942                	ld	s2,16(sp)
    80002312:	69a2                	ld	s3,8(sp)
    80002314:	6145                	addi	sp,sp,48
    80002316:	8082                	ret
        p->state = RUNNABLE;
    80002318:	478d                	li	a5,3
    8000231a:	cc9c                	sw	a5,24(s1)
    8000231c:	b7cd                	j	800022fe <kill+0x52>

000000008000231e <setkilled>:

void
setkilled(struct proc *p)
{
    8000231e:	1101                	addi	sp,sp,-32
    80002320:	ec06                	sd	ra,24(sp)
    80002322:	e822                	sd	s0,16(sp)
    80002324:	e426                	sd	s1,8(sp)
    80002326:	1000                	addi	s0,sp,32
    80002328:	84aa                	mv	s1,a0
  acquire(&p->lock);
    8000232a:	fffff097          	auipc	ra,0xfffff
    8000232e:	8f6080e7          	jalr	-1802(ra) # 80000c20 <acquire>
  p->killed = 1;
    80002332:	4785                	li	a5,1
    80002334:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    80002336:	8526                	mv	a0,s1
    80002338:	fffff097          	auipc	ra,0xfffff
    8000233c:	99c080e7          	jalr	-1636(ra) # 80000cd4 <release>
}
    80002340:	60e2                	ld	ra,24(sp)
    80002342:	6442                	ld	s0,16(sp)
    80002344:	64a2                	ld	s1,8(sp)
    80002346:	6105                	addi	sp,sp,32
    80002348:	8082                	ret

000000008000234a <killed>:

int
killed(struct proc *p)
{
    8000234a:	1101                	addi	sp,sp,-32
    8000234c:	ec06                	sd	ra,24(sp)
    8000234e:	e822                	sd	s0,16(sp)
    80002350:	e426                	sd	s1,8(sp)
    80002352:	e04a                	sd	s2,0(sp)
    80002354:	1000                	addi	s0,sp,32
    80002356:	84aa                	mv	s1,a0
  int k;
  
  acquire(&p->lock);
    80002358:	fffff097          	auipc	ra,0xfffff
    8000235c:	8c8080e7          	jalr	-1848(ra) # 80000c20 <acquire>
  k = p->killed;
    80002360:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    80002364:	8526                	mv	a0,s1
    80002366:	fffff097          	auipc	ra,0xfffff
    8000236a:	96e080e7          	jalr	-1682(ra) # 80000cd4 <release>
  return k;
}
    8000236e:	854a                	mv	a0,s2
    80002370:	60e2                	ld	ra,24(sp)
    80002372:	6442                	ld	s0,16(sp)
    80002374:	64a2                	ld	s1,8(sp)
    80002376:	6902                	ld	s2,0(sp)
    80002378:	6105                	addi	sp,sp,32
    8000237a:	8082                	ret

000000008000237c <wait>:
{
    8000237c:	715d                	addi	sp,sp,-80
    8000237e:	e486                	sd	ra,72(sp)
    80002380:	e0a2                	sd	s0,64(sp)
    80002382:	fc26                	sd	s1,56(sp)
    80002384:	f84a                	sd	s2,48(sp)
    80002386:	f44e                	sd	s3,40(sp)
    80002388:	f052                	sd	s4,32(sp)
    8000238a:	ec56                	sd	s5,24(sp)
    8000238c:	e85a                	sd	s6,16(sp)
    8000238e:	e45e                	sd	s7,8(sp)
    80002390:	e062                	sd	s8,0(sp)
    80002392:	0880                	addi	s0,sp,80
    80002394:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002396:	fffff097          	auipc	ra,0xfffff
    8000239a:	660080e7          	jalr	1632(ra) # 800019f6 <myproc>
    8000239e:	892a                	mv	s2,a0
  acquire(&wait_lock);
    800023a0:	0000f517          	auipc	a0,0xf
    800023a4:	9b850513          	addi	a0,a0,-1608 # 80010d58 <wait_lock>
    800023a8:	fffff097          	auipc	ra,0xfffff
    800023ac:	878080e7          	jalr	-1928(ra) # 80000c20 <acquire>
    havekids = 0;
    800023b0:	4b81                	li	s7,0
        if(pp->state == ZOMBIE){
    800023b2:	4a15                	li	s4,5
        havekids = 1;
    800023b4:	4a85                	li	s5,1
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800023b6:	00014997          	auipc	s3,0x14
    800023ba:	7ba98993          	addi	s3,s3,1978 # 80016b70 <tickslock>
    sleep(p, &wait_lock);  //DOC: wait-sleep
    800023be:	0000fc17          	auipc	s8,0xf
    800023c2:	99ac0c13          	addi	s8,s8,-1638 # 80010d58 <wait_lock>
    havekids = 0;
    800023c6:	875e                	mv	a4,s7
    for(pp = proc; pp < &proc[NPROC]; pp++){
    800023c8:	0000f497          	auipc	s1,0xf
    800023cc:	da848493          	addi	s1,s1,-600 # 80011170 <proc>
    800023d0:	a0bd                	j	8000243e <wait+0xc2>
          pid = pp->pid;
    800023d2:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    800023d6:	000b0e63          	beqz	s6,800023f2 <wait+0x76>
    800023da:	4691                	li	a3,4
    800023dc:	02c48613          	addi	a2,s1,44
    800023e0:	85da                	mv	a1,s6
    800023e2:	05093503          	ld	a0,80(s2)
    800023e6:	fffff097          	auipc	ra,0xfffff
    800023ea:	2d0080e7          	jalr	720(ra) # 800016b6 <copyout>
    800023ee:	02054563          	bltz	a0,80002418 <wait+0x9c>
          freeproc(pp);
    800023f2:	8526                	mv	a0,s1
    800023f4:	fffff097          	auipc	ra,0xfffff
    800023f8:	7b4080e7          	jalr	1972(ra) # 80001ba8 <freeproc>
          release(&pp->lock);
    800023fc:	8526                	mv	a0,s1
    800023fe:	fffff097          	auipc	ra,0xfffff
    80002402:	8d6080e7          	jalr	-1834(ra) # 80000cd4 <release>
          release(&wait_lock);
    80002406:	0000f517          	auipc	a0,0xf
    8000240a:	95250513          	addi	a0,a0,-1710 # 80010d58 <wait_lock>
    8000240e:	fffff097          	auipc	ra,0xfffff
    80002412:	8c6080e7          	jalr	-1850(ra) # 80000cd4 <release>
          return pid;
    80002416:	a0b5                	j	80002482 <wait+0x106>
            release(&pp->lock);
    80002418:	8526                	mv	a0,s1
    8000241a:	fffff097          	auipc	ra,0xfffff
    8000241e:	8ba080e7          	jalr	-1862(ra) # 80000cd4 <release>
            release(&wait_lock);
    80002422:	0000f517          	auipc	a0,0xf
    80002426:	93650513          	addi	a0,a0,-1738 # 80010d58 <wait_lock>
    8000242a:	fffff097          	auipc	ra,0xfffff
    8000242e:	8aa080e7          	jalr	-1878(ra) # 80000cd4 <release>
            return -1;
    80002432:	59fd                	li	s3,-1
    80002434:	a0b9                	j	80002482 <wait+0x106>
    for(pp = proc; pp < &proc[NPROC]; pp++){
    80002436:	16848493          	addi	s1,s1,360
    8000243a:	03348463          	beq	s1,s3,80002462 <wait+0xe6>
      if(pp->parent == p){
    8000243e:	7c9c                	ld	a5,56(s1)
    80002440:	ff279be3          	bne	a5,s2,80002436 <wait+0xba>
        acquire(&pp->lock);
    80002444:	8526                	mv	a0,s1
    80002446:	ffffe097          	auipc	ra,0xffffe
    8000244a:	7da080e7          	jalr	2010(ra) # 80000c20 <acquire>
        if(pp->state == ZOMBIE){
    8000244e:	4c9c                	lw	a5,24(s1)
    80002450:	f94781e3          	beq	a5,s4,800023d2 <wait+0x56>
        release(&pp->lock);
    80002454:	8526                	mv	a0,s1
    80002456:	fffff097          	auipc	ra,0xfffff
    8000245a:	87e080e7          	jalr	-1922(ra) # 80000cd4 <release>
        havekids = 1;
    8000245e:	8756                	mv	a4,s5
    80002460:	bfd9                	j	80002436 <wait+0xba>
    if(!havekids || killed(p)){
    80002462:	c719                	beqz	a4,80002470 <wait+0xf4>
    80002464:	854a                	mv	a0,s2
    80002466:	00000097          	auipc	ra,0x0
    8000246a:	ee4080e7          	jalr	-284(ra) # 8000234a <killed>
    8000246e:	c51d                	beqz	a0,8000249c <wait+0x120>
      release(&wait_lock);
    80002470:	0000f517          	auipc	a0,0xf
    80002474:	8e850513          	addi	a0,a0,-1816 # 80010d58 <wait_lock>
    80002478:	fffff097          	auipc	ra,0xfffff
    8000247c:	85c080e7          	jalr	-1956(ra) # 80000cd4 <release>
      return -1;
    80002480:	59fd                	li	s3,-1
}
    80002482:	854e                	mv	a0,s3
    80002484:	60a6                	ld	ra,72(sp)
    80002486:	6406                	ld	s0,64(sp)
    80002488:	74e2                	ld	s1,56(sp)
    8000248a:	7942                	ld	s2,48(sp)
    8000248c:	79a2                	ld	s3,40(sp)
    8000248e:	7a02                	ld	s4,32(sp)
    80002490:	6ae2                	ld	s5,24(sp)
    80002492:	6b42                	ld	s6,16(sp)
    80002494:	6ba2                	ld	s7,8(sp)
    80002496:	6c02                	ld	s8,0(sp)
    80002498:	6161                	addi	sp,sp,80
    8000249a:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    8000249c:	85e2                	mv	a1,s8
    8000249e:	854a                	mv	a0,s2
    800024a0:	00000097          	auipc	ra,0x0
    800024a4:	c02080e7          	jalr	-1022(ra) # 800020a2 <sleep>
    havekids = 0;
    800024a8:	bf39                	j	800023c6 <wait+0x4a>

00000000800024aa <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    800024aa:	7179                	addi	sp,sp,-48
    800024ac:	f406                	sd	ra,40(sp)
    800024ae:	f022                	sd	s0,32(sp)
    800024b0:	ec26                	sd	s1,24(sp)
    800024b2:	e84a                	sd	s2,16(sp)
    800024b4:	e44e                	sd	s3,8(sp)
    800024b6:	e052                	sd	s4,0(sp)
    800024b8:	1800                	addi	s0,sp,48
    800024ba:	84aa                	mv	s1,a0
    800024bc:	892e                	mv	s2,a1
    800024be:	89b2                	mv	s3,a2
    800024c0:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800024c2:	fffff097          	auipc	ra,0xfffff
    800024c6:	534080e7          	jalr	1332(ra) # 800019f6 <myproc>
  if(user_dst){
    800024ca:	c08d                	beqz	s1,800024ec <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800024cc:	86d2                	mv	a3,s4
    800024ce:	864e                	mv	a2,s3
    800024d0:	85ca                	mv	a1,s2
    800024d2:	6928                	ld	a0,80(a0)
    800024d4:	fffff097          	auipc	ra,0xfffff
    800024d8:	1e2080e7          	jalr	482(ra) # 800016b6 <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800024dc:	70a2                	ld	ra,40(sp)
    800024de:	7402                	ld	s0,32(sp)
    800024e0:	64e2                	ld	s1,24(sp)
    800024e2:	6942                	ld	s2,16(sp)
    800024e4:	69a2                	ld	s3,8(sp)
    800024e6:	6a02                	ld	s4,0(sp)
    800024e8:	6145                	addi	sp,sp,48
    800024ea:	8082                	ret
    memmove((char *)dst, src, len);
    800024ec:	000a061b          	sext.w	a2,s4
    800024f0:	85ce                	mv	a1,s3
    800024f2:	854a                	mv	a0,s2
    800024f4:	fffff097          	auipc	ra,0xfffff
    800024f8:	884080e7          	jalr	-1916(ra) # 80000d78 <memmove>
    return 0;
    800024fc:	8526                	mv	a0,s1
    800024fe:	bff9                	j	800024dc <either_copyout+0x32>

0000000080002500 <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002500:	7179                	addi	sp,sp,-48
    80002502:	f406                	sd	ra,40(sp)
    80002504:	f022                	sd	s0,32(sp)
    80002506:	ec26                	sd	s1,24(sp)
    80002508:	e84a                	sd	s2,16(sp)
    8000250a:	e44e                	sd	s3,8(sp)
    8000250c:	e052                	sd	s4,0(sp)
    8000250e:	1800                	addi	s0,sp,48
    80002510:	892a                	mv	s2,a0
    80002512:	84ae                	mv	s1,a1
    80002514:	89b2                	mv	s3,a2
    80002516:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002518:	fffff097          	auipc	ra,0xfffff
    8000251c:	4de080e7          	jalr	1246(ra) # 800019f6 <myproc>
  if(user_src){
    80002520:	c08d                	beqz	s1,80002542 <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    80002522:	86d2                	mv	a3,s4
    80002524:	864e                	mv	a2,s3
    80002526:	85ca                	mv	a1,s2
    80002528:	6928                	ld	a0,80(a0)
    8000252a:	fffff097          	auipc	ra,0xfffff
    8000252e:	218080e7          	jalr	536(ra) # 80001742 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    80002532:	70a2                	ld	ra,40(sp)
    80002534:	7402                	ld	s0,32(sp)
    80002536:	64e2                	ld	s1,24(sp)
    80002538:	6942                	ld	s2,16(sp)
    8000253a:	69a2                	ld	s3,8(sp)
    8000253c:	6a02                	ld	s4,0(sp)
    8000253e:	6145                	addi	sp,sp,48
    80002540:	8082                	ret
    memmove(dst, (char*)src, len);
    80002542:	000a061b          	sext.w	a2,s4
    80002546:	85ce                	mv	a1,s3
    80002548:	854a                	mv	a0,s2
    8000254a:	fffff097          	auipc	ra,0xfffff
    8000254e:	82e080e7          	jalr	-2002(ra) # 80000d78 <memmove>
    return 0;
    80002552:	8526                	mv	a0,s1
    80002554:	bff9                	j	80002532 <either_copyin+0x32>

0000000080002556 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002556:	715d                	addi	sp,sp,-80
    80002558:	e486                	sd	ra,72(sp)
    8000255a:	e0a2                	sd	s0,64(sp)
    8000255c:	fc26                	sd	s1,56(sp)
    8000255e:	f84a                	sd	s2,48(sp)
    80002560:	f44e                	sd	s3,40(sp)
    80002562:	f052                	sd	s4,32(sp)
    80002564:	ec56                	sd	s5,24(sp)
    80002566:	e85a                	sd	s6,16(sp)
    80002568:	e45e                	sd	s7,8(sp)
    8000256a:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    8000256c:	00006517          	auipc	a0,0x6
    80002570:	b5c50513          	addi	a0,a0,-1188 # 800080c8 <digits+0x88>
    80002574:	ffffe097          	auipc	ra,0xffffe
    80002578:	016080e7          	jalr	22(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    8000257c:	0000f497          	auipc	s1,0xf
    80002580:	d4c48493          	addi	s1,s1,-692 # 800112c8 <proc+0x158>
    80002584:	00014917          	auipc	s2,0x14
    80002588:	74490913          	addi	s2,s2,1860 # 80016cc8 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    8000258c:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000258e:	00006997          	auipc	s3,0x6
    80002592:	cf298993          	addi	s3,s3,-782 # 80008280 <digits+0x240>
    printf("%d %s %s", p->pid, state, p->name);
    80002596:	00006a97          	auipc	s5,0x6
    8000259a:	cf2a8a93          	addi	s5,s5,-782 # 80008288 <digits+0x248>
    printf("\n");
    8000259e:	00006a17          	auipc	s4,0x6
    800025a2:	b2aa0a13          	addi	s4,s4,-1238 # 800080c8 <digits+0x88>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025a6:	00006b97          	auipc	s7,0x6
    800025aa:	d22b8b93          	addi	s7,s7,-734 # 800082c8 <states.0>
    800025ae:	a00d                	j	800025d0 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    800025b0:	ed86a583          	lw	a1,-296(a3)
    800025b4:	8556                	mv	a0,s5
    800025b6:	ffffe097          	auipc	ra,0xffffe
    800025ba:	fd4080e7          	jalr	-44(ra) # 8000058a <printf>
    printf("\n");
    800025be:	8552                	mv	a0,s4
    800025c0:	ffffe097          	auipc	ra,0xffffe
    800025c4:	fca080e7          	jalr	-54(ra) # 8000058a <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800025c8:	16848493          	addi	s1,s1,360
    800025cc:	03248263          	beq	s1,s2,800025f0 <procdump+0x9a>
    if(p->state == UNUSED)
    800025d0:	86a6                	mv	a3,s1
    800025d2:	ec04a783          	lw	a5,-320(s1)
    800025d6:	dbed                	beqz	a5,800025c8 <procdump+0x72>
      state = "???";
    800025d8:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800025da:	fcfb6be3          	bltu	s6,a5,800025b0 <procdump+0x5a>
    800025de:	02079713          	slli	a4,a5,0x20
    800025e2:	01d75793          	srli	a5,a4,0x1d
    800025e6:	97de                	add	a5,a5,s7
    800025e8:	6390                	ld	a2,0(a5)
    800025ea:	f279                	bnez	a2,800025b0 <procdump+0x5a>
      state = "???";
    800025ec:	864e                	mv	a2,s3
    800025ee:	b7c9                	j	800025b0 <procdump+0x5a>
  }
}
    800025f0:	60a6                	ld	ra,72(sp)
    800025f2:	6406                	ld	s0,64(sp)
    800025f4:	74e2                	ld	s1,56(sp)
    800025f6:	7942                	ld	s2,48(sp)
    800025f8:	79a2                	ld	s3,40(sp)
    800025fa:	7a02                	ld	s4,32(sp)
    800025fc:	6ae2                	ld	s5,24(sp)
    800025fe:	6b42                	ld	s6,16(sp)
    80002600:	6ba2                	ld	s7,8(sp)
    80002602:	6161                	addi	sp,sp,80
    80002604:	8082                	ret

0000000080002606 <aliveproc>:

// tracking existing procedure count
int
aliveproc(void)
{
    80002606:	7179                	addi	sp,sp,-48
    80002608:	f406                	sd	ra,40(sp)
    8000260a:	f022                	sd	s0,32(sp)
    8000260c:	ec26                	sd	s1,24(sp)
    8000260e:	e84a                	sd	s2,16(sp)
    80002610:	e44e                	sd	s3,8(sp)
    80002612:	1800                	addi	s0,sp,48
  int n = 0;
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002614:	0000f497          	auipc	s1,0xf
    80002618:	b5c48493          	addi	s1,s1,-1188 # 80011170 <proc>
  int n = 0;
    8000261c:	4901                	li	s2,0
  for (p = proc; p < &proc[NPROC]; p++)
    8000261e:	00014997          	auipc	s3,0x14
    80002622:	55298993          	addi	s3,s3,1362 # 80016b70 <tickslock>
    80002626:	a811                	j	8000263a <aliveproc+0x34>
  {
    acquire(&p->lock);
    if(p->state != UNUSED)
      n++;
    release(&p->lock);
    80002628:	8526                	mv	a0,s1
    8000262a:	ffffe097          	auipc	ra,0xffffe
    8000262e:	6aa080e7          	jalr	1706(ra) # 80000cd4 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002632:	16848493          	addi	s1,s1,360
    80002636:	01348b63          	beq	s1,s3,8000264c <aliveproc+0x46>
    acquire(&p->lock);
    8000263a:	8526                	mv	a0,s1
    8000263c:	ffffe097          	auipc	ra,0xffffe
    80002640:	5e4080e7          	jalr	1508(ra) # 80000c20 <acquire>
    if(p->state != UNUSED)
    80002644:	4c9c                	lw	a5,24(s1)
    80002646:	d3ed                	beqz	a5,80002628 <aliveproc+0x22>
      n++;
    80002648:	2905                	addiw	s2,s2,1
    8000264a:	bff9                	j	80002628 <aliveproc+0x22>
  }
  return n;
}
    8000264c:	854a                	mv	a0,s2
    8000264e:	70a2                	ld	ra,40(sp)
    80002650:	7402                	ld	s0,32(sp)
    80002652:	64e2                	ld	s1,24(sp)
    80002654:	6942                	ld	s2,16(sp)
    80002656:	69a2                	ld	s3,8(sp)
    80002658:	6145                	addi	sp,sp,48
    8000265a:	8082                	ret

000000008000265c <swtch>:
    8000265c:	00153023          	sd	ra,0(a0)
    80002660:	00253423          	sd	sp,8(a0)
    80002664:	e900                	sd	s0,16(a0)
    80002666:	ed04                	sd	s1,24(a0)
    80002668:	03253023          	sd	s2,32(a0)
    8000266c:	03353423          	sd	s3,40(a0)
    80002670:	03453823          	sd	s4,48(a0)
    80002674:	03553c23          	sd	s5,56(a0)
    80002678:	05653023          	sd	s6,64(a0)
    8000267c:	05753423          	sd	s7,72(a0)
    80002680:	05853823          	sd	s8,80(a0)
    80002684:	05953c23          	sd	s9,88(a0)
    80002688:	07a53023          	sd	s10,96(a0)
    8000268c:	07b53423          	sd	s11,104(a0)
    80002690:	0005b083          	ld	ra,0(a1)
    80002694:	0085b103          	ld	sp,8(a1)
    80002698:	6980                	ld	s0,16(a1)
    8000269a:	6d84                	ld	s1,24(a1)
    8000269c:	0205b903          	ld	s2,32(a1)
    800026a0:	0285b983          	ld	s3,40(a1)
    800026a4:	0305ba03          	ld	s4,48(a1)
    800026a8:	0385ba83          	ld	s5,56(a1)
    800026ac:	0405bb03          	ld	s6,64(a1)
    800026b0:	0485bb83          	ld	s7,72(a1)
    800026b4:	0505bc03          	ld	s8,80(a1)
    800026b8:	0585bc83          	ld	s9,88(a1)
    800026bc:	0605bd03          	ld	s10,96(a1)
    800026c0:	0685bd83          	ld	s11,104(a1)
    800026c4:	8082                	ret

00000000800026c6 <trapinit>:

extern int devintr();

void
trapinit(void)
{
    800026c6:	1141                	addi	sp,sp,-16
    800026c8:	e406                	sd	ra,8(sp)
    800026ca:	e022                	sd	s0,0(sp)
    800026cc:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    800026ce:	00006597          	auipc	a1,0x6
    800026d2:	c2a58593          	addi	a1,a1,-982 # 800082f8 <states.0+0x30>
    800026d6:	00014517          	auipc	a0,0x14
    800026da:	49a50513          	addi	a0,a0,1178 # 80016b70 <tickslock>
    800026de:	ffffe097          	auipc	ra,0xffffe
    800026e2:	4b2080e7          	jalr	1202(ra) # 80000b90 <initlock>
}
    800026e6:	60a2                	ld	ra,8(sp)
    800026e8:	6402                	ld	s0,0(sp)
    800026ea:	0141                	addi	sp,sp,16
    800026ec:	8082                	ret

00000000800026ee <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    800026ee:	1141                	addi	sp,sp,-16
    800026f0:	e422                	sd	s0,8(sp)
    800026f2:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    800026f4:	00003797          	auipc	a5,0x3
    800026f8:	56c78793          	addi	a5,a5,1388 # 80005c60 <kernelvec>
    800026fc:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002700:	6422                	ld	s0,8(sp)
    80002702:	0141                	addi	sp,sp,16
    80002704:	8082                	ret

0000000080002706 <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    80002706:	1141                	addi	sp,sp,-16
    80002708:	e406                	sd	ra,8(sp)
    8000270a:	e022                	sd	s0,0(sp)
    8000270c:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    8000270e:	fffff097          	auipc	ra,0xfffff
    80002712:	2e8080e7          	jalr	744(ra) # 800019f6 <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002716:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000271a:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    8000271c:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002720:	00005697          	auipc	a3,0x5
    80002724:	8e068693          	addi	a3,a3,-1824 # 80007000 <_trampoline>
    80002728:	00005717          	auipc	a4,0x5
    8000272c:	8d870713          	addi	a4,a4,-1832 # 80007000 <_trampoline>
    80002730:	8f15                	sub	a4,a4,a3
    80002732:	040007b7          	lui	a5,0x4000
    80002736:	17fd                	addi	a5,a5,-1 # 3ffffff <_entry-0x7c000001>
    80002738:	07b2                	slli	a5,a5,0xc
    8000273a:	973e                	add	a4,a4,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000273c:	10571073          	csrw	stvec,a4
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002740:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002742:	18002673          	csrr	a2,satp
    80002746:	e310                	sd	a2,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002748:	6d30                	ld	a2,88(a0)
    8000274a:	6138                	ld	a4,64(a0)
    8000274c:	6585                	lui	a1,0x1
    8000274e:	972e                	add	a4,a4,a1
    80002750:	e618                	sd	a4,8(a2)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002752:	6d38                	ld	a4,88(a0)
    80002754:	00000617          	auipc	a2,0x0
    80002758:	13060613          	addi	a2,a2,304 # 80002884 <usertrap>
    8000275c:	eb10                	sd	a2,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    8000275e:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002760:	8612                	mv	a2,tp
    80002762:	f310                	sd	a2,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002764:	10002773          	csrr	a4,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002768:	eff77713          	andi	a4,a4,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    8000276c:	02076713          	ori	a4,a4,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002770:	10071073          	csrw	sstatus,a4
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002774:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002776:	6f18                	ld	a4,24(a4)
    80002778:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    8000277c:	6928                	ld	a0,80(a0)
    8000277e:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002780:	00005717          	auipc	a4,0x5
    80002784:	91c70713          	addi	a4,a4,-1764 # 8000709c <userret>
    80002788:	8f15                	sub	a4,a4,a3
    8000278a:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    8000278c:	577d                	li	a4,-1
    8000278e:	177e                	slli	a4,a4,0x3f
    80002790:	8d59                	or	a0,a0,a4
    80002792:	9782                	jalr	a5
}
    80002794:	60a2                	ld	ra,8(sp)
    80002796:	6402                	ld	s0,0(sp)
    80002798:	0141                	addi	sp,sp,16
    8000279a:	8082                	ret

000000008000279c <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    8000279c:	1101                	addi	sp,sp,-32
    8000279e:	ec06                	sd	ra,24(sp)
    800027a0:	e822                	sd	s0,16(sp)
    800027a2:	e426                	sd	s1,8(sp)
    800027a4:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    800027a6:	00014497          	auipc	s1,0x14
    800027aa:	3ca48493          	addi	s1,s1,970 # 80016b70 <tickslock>
    800027ae:	8526                	mv	a0,s1
    800027b0:	ffffe097          	auipc	ra,0xffffe
    800027b4:	470080e7          	jalr	1136(ra) # 80000c20 <acquire>
  ticks++;
    800027b8:	00006517          	auipc	a0,0x6
    800027bc:	31850513          	addi	a0,a0,792 # 80008ad0 <ticks>
    800027c0:	411c                	lw	a5,0(a0)
    800027c2:	2785                	addiw	a5,a5,1
    800027c4:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    800027c6:	00000097          	auipc	ra,0x0
    800027ca:	940080e7          	jalr	-1728(ra) # 80002106 <wakeup>
  release(&tickslock);
    800027ce:	8526                	mv	a0,s1
    800027d0:	ffffe097          	auipc	ra,0xffffe
    800027d4:	504080e7          	jalr	1284(ra) # 80000cd4 <release>
}
    800027d8:	60e2                	ld	ra,24(sp)
    800027da:	6442                	ld	s0,16(sp)
    800027dc:	64a2                	ld	s1,8(sp)
    800027de:	6105                	addi	sp,sp,32
    800027e0:	8082                	ret

00000000800027e2 <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    800027e2:	1101                	addi	sp,sp,-32
    800027e4:	ec06                	sd	ra,24(sp)
    800027e6:	e822                	sd	s0,16(sp)
    800027e8:	e426                	sd	s1,8(sp)
    800027ea:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    800027ec:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    800027f0:	00074d63          	bltz	a4,8000280a <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    800027f4:	57fd                	li	a5,-1
    800027f6:	17fe                	slli	a5,a5,0x3f
    800027f8:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    800027fa:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    800027fc:	06f70363          	beq	a4,a5,80002862 <devintr+0x80>
  }
}
    80002800:	60e2                	ld	ra,24(sp)
    80002802:	6442                	ld	s0,16(sp)
    80002804:	64a2                	ld	s1,8(sp)
    80002806:	6105                	addi	sp,sp,32
    80002808:	8082                	ret
     (scause & 0xff) == 9){
    8000280a:	0ff77793          	zext.b	a5,a4
  if((scause & 0x8000000000000000L) &&
    8000280e:	46a5                	li	a3,9
    80002810:	fed792e3          	bne	a5,a3,800027f4 <devintr+0x12>
    int irq = plic_claim();
    80002814:	00003097          	auipc	ra,0x3
    80002818:	554080e7          	jalr	1364(ra) # 80005d68 <plic_claim>
    8000281c:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    8000281e:	47a9                	li	a5,10
    80002820:	02f50763          	beq	a0,a5,8000284e <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    80002824:	4785                	li	a5,1
    80002826:	02f50963          	beq	a0,a5,80002858 <devintr+0x76>
    return 1;
    8000282a:	4505                	li	a0,1
    } else if(irq){
    8000282c:	d8f1                	beqz	s1,80002800 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    8000282e:	85a6                	mv	a1,s1
    80002830:	00006517          	auipc	a0,0x6
    80002834:	ad050513          	addi	a0,a0,-1328 # 80008300 <states.0+0x38>
    80002838:	ffffe097          	auipc	ra,0xffffe
    8000283c:	d52080e7          	jalr	-686(ra) # 8000058a <printf>
      plic_complete(irq);
    80002840:	8526                	mv	a0,s1
    80002842:	00003097          	auipc	ra,0x3
    80002846:	54a080e7          	jalr	1354(ra) # 80005d8c <plic_complete>
    return 1;
    8000284a:	4505                	li	a0,1
    8000284c:	bf55                	j	80002800 <devintr+0x1e>
      uartintr();
    8000284e:	ffffe097          	auipc	ra,0xffffe
    80002852:	14a080e7          	jalr	330(ra) # 80000998 <uartintr>
    80002856:	b7ed                	j	80002840 <devintr+0x5e>
      virtio_disk_intr();
    80002858:	00004097          	auipc	ra,0x4
    8000285c:	9fc080e7          	jalr	-1540(ra) # 80006254 <virtio_disk_intr>
    80002860:	b7c5                	j	80002840 <devintr+0x5e>
    if(cpuid() == 0){
    80002862:	fffff097          	auipc	ra,0xfffff
    80002866:	168080e7          	jalr	360(ra) # 800019ca <cpuid>
    8000286a:	c901                	beqz	a0,8000287a <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    8000286c:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80002870:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    80002872:	14479073          	csrw	sip,a5
    return 2;
    80002876:	4509                	li	a0,2
    80002878:	b761                	j	80002800 <devintr+0x1e>
      clockintr();
    8000287a:	00000097          	auipc	ra,0x0
    8000287e:	f22080e7          	jalr	-222(ra) # 8000279c <clockintr>
    80002882:	b7ed                	j	8000286c <devintr+0x8a>

0000000080002884 <usertrap>:
{
    80002884:	1101                	addi	sp,sp,-32
    80002886:	ec06                	sd	ra,24(sp)
    80002888:	e822                	sd	s0,16(sp)
    8000288a:	e426                	sd	s1,8(sp)
    8000288c:	e04a                	sd	s2,0(sp)
    8000288e:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002890:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002894:	1007f793          	andi	a5,a5,256
    80002898:	e3b1                	bnez	a5,800028dc <usertrap+0x58>
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000289a:	00003797          	auipc	a5,0x3
    8000289e:	3c678793          	addi	a5,a5,966 # 80005c60 <kernelvec>
    800028a2:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    800028a6:	fffff097          	auipc	ra,0xfffff
    800028aa:	150080e7          	jalr	336(ra) # 800019f6 <myproc>
    800028ae:	84aa                	mv	s1,a0
  p->trapframe->epc = r_sepc();
    800028b0:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800028b2:	14102773          	csrr	a4,sepc
    800028b6:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    800028b8:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    800028bc:	47a1                	li	a5,8
    800028be:	02f70763          	beq	a4,a5,800028ec <usertrap+0x68>
  } else if((which_dev = devintr()) != 0){
    800028c2:	00000097          	auipc	ra,0x0
    800028c6:	f20080e7          	jalr	-224(ra) # 800027e2 <devintr>
    800028ca:	892a                	mv	s2,a0
    800028cc:	c151                	beqz	a0,80002950 <usertrap+0xcc>
  if(killed(p))
    800028ce:	8526                	mv	a0,s1
    800028d0:	00000097          	auipc	ra,0x0
    800028d4:	a7a080e7          	jalr	-1414(ra) # 8000234a <killed>
    800028d8:	c929                	beqz	a0,8000292a <usertrap+0xa6>
    800028da:	a099                	j	80002920 <usertrap+0x9c>
    panic("usertrap: not from user mode");
    800028dc:	00006517          	auipc	a0,0x6
    800028e0:	a4450513          	addi	a0,a0,-1468 # 80008320 <states.0+0x58>
    800028e4:	ffffe097          	auipc	ra,0xffffe
    800028e8:	c5c080e7          	jalr	-932(ra) # 80000540 <panic>
    if(killed(p))
    800028ec:	00000097          	auipc	ra,0x0
    800028f0:	a5e080e7          	jalr	-1442(ra) # 8000234a <killed>
    800028f4:	e921                	bnez	a0,80002944 <usertrap+0xc0>
    p->trapframe->epc += 4;
    800028f6:	6cb8                	ld	a4,88(s1)
    800028f8:	6f1c                	ld	a5,24(a4)
    800028fa:	0791                	addi	a5,a5,4
    800028fc:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028fe:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002902:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002906:	10079073          	csrw	sstatus,a5
    syscall();
    8000290a:	00000097          	auipc	ra,0x0
    8000290e:	2d4080e7          	jalr	724(ra) # 80002bde <syscall>
  if(killed(p))
    80002912:	8526                	mv	a0,s1
    80002914:	00000097          	auipc	ra,0x0
    80002918:	a36080e7          	jalr	-1482(ra) # 8000234a <killed>
    8000291c:	c911                	beqz	a0,80002930 <usertrap+0xac>
    8000291e:	4901                	li	s2,0
    exit(-1);
    80002920:	557d                	li	a0,-1
    80002922:	00000097          	auipc	ra,0x0
    80002926:	8b4080e7          	jalr	-1868(ra) # 800021d6 <exit>
  if(which_dev == 2)
    8000292a:	4789                	li	a5,2
    8000292c:	04f90f63          	beq	s2,a5,8000298a <usertrap+0x106>
  usertrapret();
    80002930:	00000097          	auipc	ra,0x0
    80002934:	dd6080e7          	jalr	-554(ra) # 80002706 <usertrapret>
}
    80002938:	60e2                	ld	ra,24(sp)
    8000293a:	6442                	ld	s0,16(sp)
    8000293c:	64a2                	ld	s1,8(sp)
    8000293e:	6902                	ld	s2,0(sp)
    80002940:	6105                	addi	sp,sp,32
    80002942:	8082                	ret
      exit(-1);
    80002944:	557d                	li	a0,-1
    80002946:	00000097          	auipc	ra,0x0
    8000294a:	890080e7          	jalr	-1904(ra) # 800021d6 <exit>
    8000294e:	b765                	j	800028f6 <usertrap+0x72>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002950:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002954:	5890                	lw	a2,48(s1)
    80002956:	00006517          	auipc	a0,0x6
    8000295a:	9ea50513          	addi	a0,a0,-1558 # 80008340 <states.0+0x78>
    8000295e:	ffffe097          	auipc	ra,0xffffe
    80002962:	c2c080e7          	jalr	-980(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002966:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000296a:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000296e:	00006517          	auipc	a0,0x6
    80002972:	a0250513          	addi	a0,a0,-1534 # 80008370 <states.0+0xa8>
    80002976:	ffffe097          	auipc	ra,0xffffe
    8000297a:	c14080e7          	jalr	-1004(ra) # 8000058a <printf>
    setkilled(p);
    8000297e:	8526                	mv	a0,s1
    80002980:	00000097          	auipc	ra,0x0
    80002984:	99e080e7          	jalr	-1634(ra) # 8000231e <setkilled>
    80002988:	b769                	j	80002912 <usertrap+0x8e>
    yield();
    8000298a:	fffff097          	auipc	ra,0xfffff
    8000298e:	6dc080e7          	jalr	1756(ra) # 80002066 <yield>
    80002992:	bf79                	j	80002930 <usertrap+0xac>

0000000080002994 <kerneltrap>:
{
    80002994:	7179                	addi	sp,sp,-48
    80002996:	f406                	sd	ra,40(sp)
    80002998:	f022                	sd	s0,32(sp)
    8000299a:	ec26                	sd	s1,24(sp)
    8000299c:	e84a                	sd	s2,16(sp)
    8000299e:	e44e                	sd	s3,8(sp)
    800029a0:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800029a2:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029a6:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800029aa:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    800029ae:	1004f793          	andi	a5,s1,256
    800029b2:	cb85                	beqz	a5,800029e2 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800029b4:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800029b8:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    800029ba:	ef85                	bnez	a5,800029f2 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    800029bc:	00000097          	auipc	ra,0x0
    800029c0:	e26080e7          	jalr	-474(ra) # 800027e2 <devintr>
    800029c4:	cd1d                	beqz	a0,80002a02 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800029c6:	4789                	li	a5,2
    800029c8:	06f50a63          	beq	a0,a5,80002a3c <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800029cc:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800029d0:	10049073          	csrw	sstatus,s1
}
    800029d4:	70a2                	ld	ra,40(sp)
    800029d6:	7402                	ld	s0,32(sp)
    800029d8:	64e2                	ld	s1,24(sp)
    800029da:	6942                	ld	s2,16(sp)
    800029dc:	69a2                	ld	s3,8(sp)
    800029de:	6145                	addi	sp,sp,48
    800029e0:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    800029e2:	00006517          	auipc	a0,0x6
    800029e6:	9ae50513          	addi	a0,a0,-1618 # 80008390 <states.0+0xc8>
    800029ea:	ffffe097          	auipc	ra,0xffffe
    800029ee:	b56080e7          	jalr	-1194(ra) # 80000540 <panic>
    panic("kerneltrap: interrupts enabled");
    800029f2:	00006517          	auipc	a0,0x6
    800029f6:	9c650513          	addi	a0,a0,-1594 # 800083b8 <states.0+0xf0>
    800029fa:	ffffe097          	auipc	ra,0xffffe
    800029fe:	b46080e7          	jalr	-1210(ra) # 80000540 <panic>
    printf("scause %p\n", scause);
    80002a02:	85ce                	mv	a1,s3
    80002a04:	00006517          	auipc	a0,0x6
    80002a08:	9d450513          	addi	a0,a0,-1580 # 800083d8 <states.0+0x110>
    80002a0c:	ffffe097          	auipc	ra,0xffffe
    80002a10:	b7e080e7          	jalr	-1154(ra) # 8000058a <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a14:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002a18:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002a1c:	00006517          	auipc	a0,0x6
    80002a20:	9cc50513          	addi	a0,a0,-1588 # 800083e8 <states.0+0x120>
    80002a24:	ffffe097          	auipc	ra,0xffffe
    80002a28:	b66080e7          	jalr	-1178(ra) # 8000058a <printf>
    panic("kerneltrap");
    80002a2c:	00006517          	auipc	a0,0x6
    80002a30:	9d450513          	addi	a0,a0,-1580 # 80008400 <states.0+0x138>
    80002a34:	ffffe097          	auipc	ra,0xffffe
    80002a38:	b0c080e7          	jalr	-1268(ra) # 80000540 <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002a3c:	fffff097          	auipc	ra,0xfffff
    80002a40:	fba080e7          	jalr	-70(ra) # 800019f6 <myproc>
    80002a44:	d541                	beqz	a0,800029cc <kerneltrap+0x38>
    80002a46:	fffff097          	auipc	ra,0xfffff
    80002a4a:	fb0080e7          	jalr	-80(ra) # 800019f6 <myproc>
    80002a4e:	4d18                	lw	a4,24(a0)
    80002a50:	4791                	li	a5,4
    80002a52:	f6f71de3          	bne	a4,a5,800029cc <kerneltrap+0x38>
    yield();
    80002a56:	fffff097          	auipc	ra,0xfffff
    80002a5a:	610080e7          	jalr	1552(ra) # 80002066 <yield>
    80002a5e:	b7bd                	j	800029cc <kerneltrap+0x38>

0000000080002a60 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002a60:	1101                	addi	sp,sp,-32
    80002a62:	ec06                	sd	ra,24(sp)
    80002a64:	e822                	sd	s0,16(sp)
    80002a66:	e426                	sd	s1,8(sp)
    80002a68:	1000                	addi	s0,sp,32
    80002a6a:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002a6c:	fffff097          	auipc	ra,0xfffff
    80002a70:	f8a080e7          	jalr	-118(ra) # 800019f6 <myproc>
  switch (n) {
    80002a74:	4795                	li	a5,5
    80002a76:	0497e163          	bltu	a5,s1,80002ab8 <argraw+0x58>
    80002a7a:	048a                	slli	s1,s1,0x2
    80002a7c:	00006717          	auipc	a4,0x6
    80002a80:	a9470713          	addi	a4,a4,-1388 # 80008510 <states.0+0x248>
    80002a84:	94ba                	add	s1,s1,a4
    80002a86:	409c                	lw	a5,0(s1)
    80002a88:	97ba                	add	a5,a5,a4
    80002a8a:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002a8c:	6d3c                	ld	a5,88(a0)
    80002a8e:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002a90:	60e2                	ld	ra,24(sp)
    80002a92:	6442                	ld	s0,16(sp)
    80002a94:	64a2                	ld	s1,8(sp)
    80002a96:	6105                	addi	sp,sp,32
    80002a98:	8082                	ret
    return p->trapframe->a1;
    80002a9a:	6d3c                	ld	a5,88(a0)
    80002a9c:	7fa8                	ld	a0,120(a5)
    80002a9e:	bfcd                	j	80002a90 <argraw+0x30>
    return p->trapframe->a2;
    80002aa0:	6d3c                	ld	a5,88(a0)
    80002aa2:	63c8                	ld	a0,128(a5)
    80002aa4:	b7f5                	j	80002a90 <argraw+0x30>
    return p->trapframe->a3;
    80002aa6:	6d3c                	ld	a5,88(a0)
    80002aa8:	67c8                	ld	a0,136(a5)
    80002aaa:	b7dd                	j	80002a90 <argraw+0x30>
    return p->trapframe->a4;
    80002aac:	6d3c                	ld	a5,88(a0)
    80002aae:	6bc8                	ld	a0,144(a5)
    80002ab0:	b7c5                	j	80002a90 <argraw+0x30>
    return p->trapframe->a5;
    80002ab2:	6d3c                	ld	a5,88(a0)
    80002ab4:	6fc8                	ld	a0,152(a5)
    80002ab6:	bfe9                	j	80002a90 <argraw+0x30>
  panic("argraw");
    80002ab8:	00006517          	auipc	a0,0x6
    80002abc:	95850513          	addi	a0,a0,-1704 # 80008410 <states.0+0x148>
    80002ac0:	ffffe097          	auipc	ra,0xffffe
    80002ac4:	a80080e7          	jalr	-1408(ra) # 80000540 <panic>

0000000080002ac8 <fetchaddr>:
{
    80002ac8:	1101                	addi	sp,sp,-32
    80002aca:	ec06                	sd	ra,24(sp)
    80002acc:	e822                	sd	s0,16(sp)
    80002ace:	e426                	sd	s1,8(sp)
    80002ad0:	e04a                	sd	s2,0(sp)
    80002ad2:	1000                	addi	s0,sp,32
    80002ad4:	84aa                	mv	s1,a0
    80002ad6:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002ad8:	fffff097          	auipc	ra,0xfffff
    80002adc:	f1e080e7          	jalr	-226(ra) # 800019f6 <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    80002ae0:	653c                	ld	a5,72(a0)
    80002ae2:	02f4f863          	bgeu	s1,a5,80002b12 <fetchaddr+0x4a>
    80002ae6:	00848713          	addi	a4,s1,8
    80002aea:	02e7e663          	bltu	a5,a4,80002b16 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002aee:	46a1                	li	a3,8
    80002af0:	8626                	mv	a2,s1
    80002af2:	85ca                	mv	a1,s2
    80002af4:	6928                	ld	a0,80(a0)
    80002af6:	fffff097          	auipc	ra,0xfffff
    80002afa:	c4c080e7          	jalr	-948(ra) # 80001742 <copyin>
    80002afe:	00a03533          	snez	a0,a0
    80002b02:	40a00533          	neg	a0,a0
}
    80002b06:	60e2                	ld	ra,24(sp)
    80002b08:	6442                	ld	s0,16(sp)
    80002b0a:	64a2                	ld	s1,8(sp)
    80002b0c:	6902                	ld	s2,0(sp)
    80002b0e:	6105                	addi	sp,sp,32
    80002b10:	8082                	ret
    return -1;
    80002b12:	557d                	li	a0,-1
    80002b14:	bfcd                	j	80002b06 <fetchaddr+0x3e>
    80002b16:	557d                	li	a0,-1
    80002b18:	b7fd                	j	80002b06 <fetchaddr+0x3e>

0000000080002b1a <fetchstr>:
{
    80002b1a:	7179                	addi	sp,sp,-48
    80002b1c:	f406                	sd	ra,40(sp)
    80002b1e:	f022                	sd	s0,32(sp)
    80002b20:	ec26                	sd	s1,24(sp)
    80002b22:	e84a                	sd	s2,16(sp)
    80002b24:	e44e                	sd	s3,8(sp)
    80002b26:	1800                	addi	s0,sp,48
    80002b28:	892a                	mv	s2,a0
    80002b2a:	84ae                	mv	s1,a1
    80002b2c:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002b2e:	fffff097          	auipc	ra,0xfffff
    80002b32:	ec8080e7          	jalr	-312(ra) # 800019f6 <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80002b36:	86ce                	mv	a3,s3
    80002b38:	864a                	mv	a2,s2
    80002b3a:	85a6                	mv	a1,s1
    80002b3c:	6928                	ld	a0,80(a0)
    80002b3e:	fffff097          	auipc	ra,0xfffff
    80002b42:	c92080e7          	jalr	-878(ra) # 800017d0 <copyinstr>
    80002b46:	00054e63          	bltz	a0,80002b62 <fetchstr+0x48>
  return strlen(buf);
    80002b4a:	8526                	mv	a0,s1
    80002b4c:	ffffe097          	auipc	ra,0xffffe
    80002b50:	34c080e7          	jalr	844(ra) # 80000e98 <strlen>
}
    80002b54:	70a2                	ld	ra,40(sp)
    80002b56:	7402                	ld	s0,32(sp)
    80002b58:	64e2                	ld	s1,24(sp)
    80002b5a:	6942                	ld	s2,16(sp)
    80002b5c:	69a2                	ld	s3,8(sp)
    80002b5e:	6145                	addi	sp,sp,48
    80002b60:	8082                	ret
    return -1;
    80002b62:	557d                	li	a0,-1
    80002b64:	bfc5                	j	80002b54 <fetchstr+0x3a>

0000000080002b66 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80002b66:	1101                	addi	sp,sp,-32
    80002b68:	ec06                	sd	ra,24(sp)
    80002b6a:	e822                	sd	s0,16(sp)
    80002b6c:	e426                	sd	s1,8(sp)
    80002b6e:	1000                	addi	s0,sp,32
    80002b70:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b72:	00000097          	auipc	ra,0x0
    80002b76:	eee080e7          	jalr	-274(ra) # 80002a60 <argraw>
    80002b7a:	c088                	sw	a0,0(s1)
}
    80002b7c:	60e2                	ld	ra,24(sp)
    80002b7e:	6442                	ld	s0,16(sp)
    80002b80:	64a2                	ld	s1,8(sp)
    80002b82:	6105                	addi	sp,sp,32
    80002b84:	8082                	ret

0000000080002b86 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    80002b86:	1101                	addi	sp,sp,-32
    80002b88:	ec06                	sd	ra,24(sp)
    80002b8a:	e822                	sd	s0,16(sp)
    80002b8c:	e426                	sd	s1,8(sp)
    80002b8e:	1000                	addi	s0,sp,32
    80002b90:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002b92:	00000097          	auipc	ra,0x0
    80002b96:	ece080e7          	jalr	-306(ra) # 80002a60 <argraw>
    80002b9a:	e088                	sd	a0,0(s1)
}
    80002b9c:	60e2                	ld	ra,24(sp)
    80002b9e:	6442                	ld	s0,16(sp)
    80002ba0:	64a2                	ld	s1,8(sp)
    80002ba2:	6105                	addi	sp,sp,32
    80002ba4:	8082                	ret

0000000080002ba6 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002ba6:	7179                	addi	sp,sp,-48
    80002ba8:	f406                	sd	ra,40(sp)
    80002baa:	f022                	sd	s0,32(sp)
    80002bac:	ec26                	sd	s1,24(sp)
    80002bae:	e84a                	sd	s2,16(sp)
    80002bb0:	1800                	addi	s0,sp,48
    80002bb2:	84ae                	mv	s1,a1
    80002bb4:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    80002bb6:	fd840593          	addi	a1,s0,-40
    80002bba:	00000097          	auipc	ra,0x0
    80002bbe:	fcc080e7          	jalr	-52(ra) # 80002b86 <argaddr>
  return fetchstr(addr, buf, max);
    80002bc2:	864a                	mv	a2,s2
    80002bc4:	85a6                	mv	a1,s1
    80002bc6:	fd843503          	ld	a0,-40(s0)
    80002bca:	00000097          	auipc	ra,0x0
    80002bce:	f50080e7          	jalr	-176(ra) # 80002b1a <fetchstr>
}
    80002bd2:	70a2                	ld	ra,40(sp)
    80002bd4:	7402                	ld	s0,32(sp)
    80002bd6:	64e2                	ld	s1,24(sp)
    80002bd8:	6942                	ld	s2,16(sp)
    80002bda:	6145                	addi	sp,sp,48
    80002bdc:	8082                	ret

0000000080002bde <syscall>:
[SYS_sysinfo] "sysinfo", // added later
};

void
syscall(void)
{
    80002bde:	7179                	addi	sp,sp,-48
    80002be0:	f406                	sd	ra,40(sp)
    80002be2:	f022                	sd	s0,32(sp)
    80002be4:	ec26                	sd	s1,24(sp)
    80002be6:	e84a                	sd	s2,16(sp)
    80002be8:	e44e                	sd	s3,8(sp)
    80002bea:	1800                	addi	s0,sp,48
  int num;
  struct proc *p = myproc();
    80002bec:	fffff097          	auipc	ra,0xfffff
    80002bf0:	e0a080e7          	jalr	-502(ra) # 800019f6 <myproc>
    80002bf4:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002bf6:	05853983          	ld	s3,88(a0)
    80002bfa:	0a89b783          	ld	a5,168(s3)
    80002bfe:	0007891b          	sext.w	s2,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002c02:	37fd                	addiw	a5,a5,-1
    80002c04:	4759                	li	a4,22
    80002c06:	00f76f63          	bltu	a4,a5,80002c24 <syscall+0x46>
    80002c0a:	00391713          	slli	a4,s2,0x3
    80002c0e:	00006797          	auipc	a5,0x6
    80002c12:	91a78793          	addi	a5,a5,-1766 # 80008528 <syscalls>
    80002c16:	97ba                	add	a5,a5,a4
    80002c18:	639c                	ld	a5,0(a5)
    80002c1a:	c789                	beqz	a5,80002c24 <syscall+0x46>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0
    p->trapframe->a0 = syscalls[num]();
    80002c1c:	9782                	jalr	a5
    80002c1e:	06a9b823          	sd	a0,112(s3)
    80002c22:	a005                	j	80002c42 <syscall+0x64>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002c24:	86ca                	mv	a3,s2
    80002c26:	15848613          	addi	a2,s1,344
    80002c2a:	588c                	lw	a1,48(s1)
    80002c2c:	00005517          	auipc	a0,0x5
    80002c30:	7ec50513          	addi	a0,a0,2028 # 80008418 <states.0+0x150>
    80002c34:	ffffe097          	auipc	ra,0xffffe
    80002c38:	956080e7          	jalr	-1706(ra) # 8000058a <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002c3c:	6cbc                	ld	a5,88(s1)
    80002c3e:	577d                	li	a4,-1
    80002c40:	fbb8                	sd	a4,112(a5)
  }

  // added for tracing system call
  if (p->tracer == num){
    80002c42:	58dc                	lw	a5,52(s1)
    80002c44:	01278963          	beq	a5,s2,80002c56 <syscall+0x78>
    printf("pid: %d, syscall: %s, return value: %d\n",p->pid, syscalltitles[num], p->trapframe->a0);
  }
}
    80002c48:	70a2                	ld	ra,40(sp)
    80002c4a:	7402                	ld	s0,32(sp)
    80002c4c:	64e2                	ld	s1,24(sp)
    80002c4e:	6942                	ld	s2,16(sp)
    80002c50:	69a2                	ld	s3,8(sp)
    80002c52:	6145                	addi	sp,sp,48
    80002c54:	8082                	ret
    printf("pid: %d, syscall: %s, return value: %d\n",p->pid, syscalltitles[num], p->trapframe->a0);
    80002c56:	6cb8                	ld	a4,88(s1)
    80002c58:	090e                	slli	s2,s2,0x3
    80002c5a:	00006797          	auipc	a5,0x6
    80002c5e:	d5e78793          	addi	a5,a5,-674 # 800089b8 <syscalltitles>
    80002c62:	97ca                	add	a5,a5,s2
    80002c64:	7b34                	ld	a3,112(a4)
    80002c66:	6390                	ld	a2,0(a5)
    80002c68:	588c                	lw	a1,48(s1)
    80002c6a:	00005517          	auipc	a0,0x5
    80002c6e:	7ce50513          	addi	a0,a0,1998 # 80008438 <states.0+0x170>
    80002c72:	ffffe097          	auipc	ra,0xffffe
    80002c76:	918080e7          	jalr	-1768(ra) # 8000058a <printf>
}
    80002c7a:	b7f9                	j	80002c48 <syscall+0x6a>

0000000080002c7c <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002c7c:	1101                	addi	sp,sp,-32
    80002c7e:	ec06                	sd	ra,24(sp)
    80002c80:	e822                	sd	s0,16(sp)
    80002c82:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    80002c84:	fec40593          	addi	a1,s0,-20
    80002c88:	4501                	li	a0,0
    80002c8a:	00000097          	auipc	ra,0x0
    80002c8e:	edc080e7          	jalr	-292(ra) # 80002b66 <argint>
  exit(n);
    80002c92:	fec42503          	lw	a0,-20(s0)
    80002c96:	fffff097          	auipc	ra,0xfffff
    80002c9a:	540080e7          	jalr	1344(ra) # 800021d6 <exit>
  return 0;  // not reached
}
    80002c9e:	4501                	li	a0,0
    80002ca0:	60e2                	ld	ra,24(sp)
    80002ca2:	6442                	ld	s0,16(sp)
    80002ca4:	6105                	addi	sp,sp,32
    80002ca6:	8082                	ret

0000000080002ca8 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002ca8:	1141                	addi	sp,sp,-16
    80002caa:	e406                	sd	ra,8(sp)
    80002cac:	e022                	sd	s0,0(sp)
    80002cae:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002cb0:	fffff097          	auipc	ra,0xfffff
    80002cb4:	d46080e7          	jalr	-698(ra) # 800019f6 <myproc>
}
    80002cb8:	5908                	lw	a0,48(a0)
    80002cba:	60a2                	ld	ra,8(sp)
    80002cbc:	6402                	ld	s0,0(sp)
    80002cbe:	0141                	addi	sp,sp,16
    80002cc0:	8082                	ret

0000000080002cc2 <sys_fork>:

uint64
sys_fork(void)
{
    80002cc2:	1141                	addi	sp,sp,-16
    80002cc4:	e406                	sd	ra,8(sp)
    80002cc6:	e022                	sd	s0,0(sp)
    80002cc8:	0800                	addi	s0,sp,16
  return fork();
    80002cca:	fffff097          	auipc	ra,0xfffff
    80002cce:	0e6080e7          	jalr	230(ra) # 80001db0 <fork>
}
    80002cd2:	60a2                	ld	ra,8(sp)
    80002cd4:	6402                	ld	s0,0(sp)
    80002cd6:	0141                	addi	sp,sp,16
    80002cd8:	8082                	ret

0000000080002cda <sys_wait>:

uint64
sys_wait(void)
{
    80002cda:	1101                	addi	sp,sp,-32
    80002cdc:	ec06                	sd	ra,24(sp)
    80002cde:	e822                	sd	s0,16(sp)
    80002ce0:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80002ce2:	fe840593          	addi	a1,s0,-24
    80002ce6:	4501                	li	a0,0
    80002ce8:	00000097          	auipc	ra,0x0
    80002cec:	e9e080e7          	jalr	-354(ra) # 80002b86 <argaddr>
  return wait(p);
    80002cf0:	fe843503          	ld	a0,-24(s0)
    80002cf4:	fffff097          	auipc	ra,0xfffff
    80002cf8:	688080e7          	jalr	1672(ra) # 8000237c <wait>
}
    80002cfc:	60e2                	ld	ra,24(sp)
    80002cfe:	6442                	ld	s0,16(sp)
    80002d00:	6105                	addi	sp,sp,32
    80002d02:	8082                	ret

0000000080002d04 <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002d04:	7179                	addi	sp,sp,-48
    80002d06:	f406                	sd	ra,40(sp)
    80002d08:	f022                	sd	s0,32(sp)
    80002d0a:	ec26                	sd	s1,24(sp)
    80002d0c:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80002d0e:	fdc40593          	addi	a1,s0,-36
    80002d12:	4501                	li	a0,0
    80002d14:	00000097          	auipc	ra,0x0
    80002d18:	e52080e7          	jalr	-430(ra) # 80002b66 <argint>
  addr = myproc()->sz;
    80002d1c:	fffff097          	auipc	ra,0xfffff
    80002d20:	cda080e7          	jalr	-806(ra) # 800019f6 <myproc>
    80002d24:	6524                	ld	s1,72(a0)
  if(growproc(n) < 0)
    80002d26:	fdc42503          	lw	a0,-36(s0)
    80002d2a:	fffff097          	auipc	ra,0xfffff
    80002d2e:	02a080e7          	jalr	42(ra) # 80001d54 <growproc>
    80002d32:	00054863          	bltz	a0,80002d42 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    80002d36:	8526                	mv	a0,s1
    80002d38:	70a2                	ld	ra,40(sp)
    80002d3a:	7402                	ld	s0,32(sp)
    80002d3c:	64e2                	ld	s1,24(sp)
    80002d3e:	6145                	addi	sp,sp,48
    80002d40:	8082                	ret
    return -1;
    80002d42:	54fd                	li	s1,-1
    80002d44:	bfcd                	j	80002d36 <sys_sbrk+0x32>

0000000080002d46 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002d46:	7139                	addi	sp,sp,-64
    80002d48:	fc06                	sd	ra,56(sp)
    80002d4a:	f822                	sd	s0,48(sp)
    80002d4c:	f426                	sd	s1,40(sp)
    80002d4e:	f04a                	sd	s2,32(sp)
    80002d50:	ec4e                	sd	s3,24(sp)
    80002d52:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    80002d54:	fcc40593          	addi	a1,s0,-52
    80002d58:	4501                	li	a0,0
    80002d5a:	00000097          	auipc	ra,0x0
    80002d5e:	e0c080e7          	jalr	-500(ra) # 80002b66 <argint>
  acquire(&tickslock);
    80002d62:	00014517          	auipc	a0,0x14
    80002d66:	e0e50513          	addi	a0,a0,-498 # 80016b70 <tickslock>
    80002d6a:	ffffe097          	auipc	ra,0xffffe
    80002d6e:	eb6080e7          	jalr	-330(ra) # 80000c20 <acquire>
  ticks0 = ticks;
    80002d72:	00006917          	auipc	s2,0x6
    80002d76:	d5e92903          	lw	s2,-674(s2) # 80008ad0 <ticks>
  while(ticks - ticks0 < n){
    80002d7a:	fcc42783          	lw	a5,-52(s0)
    80002d7e:	cf9d                	beqz	a5,80002dbc <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80002d80:	00014997          	auipc	s3,0x14
    80002d84:	df098993          	addi	s3,s3,-528 # 80016b70 <tickslock>
    80002d88:	00006497          	auipc	s1,0x6
    80002d8c:	d4848493          	addi	s1,s1,-696 # 80008ad0 <ticks>
    if(killed(myproc())){
    80002d90:	fffff097          	auipc	ra,0xfffff
    80002d94:	c66080e7          	jalr	-922(ra) # 800019f6 <myproc>
    80002d98:	fffff097          	auipc	ra,0xfffff
    80002d9c:	5b2080e7          	jalr	1458(ra) # 8000234a <killed>
    80002da0:	ed15                	bnez	a0,80002ddc <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80002da2:	85ce                	mv	a1,s3
    80002da4:	8526                	mv	a0,s1
    80002da6:	fffff097          	auipc	ra,0xfffff
    80002daa:	2fc080e7          	jalr	764(ra) # 800020a2 <sleep>
  while(ticks - ticks0 < n){
    80002dae:	409c                	lw	a5,0(s1)
    80002db0:	412787bb          	subw	a5,a5,s2
    80002db4:	fcc42703          	lw	a4,-52(s0)
    80002db8:	fce7ece3          	bltu	a5,a4,80002d90 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80002dbc:	00014517          	auipc	a0,0x14
    80002dc0:	db450513          	addi	a0,a0,-588 # 80016b70 <tickslock>
    80002dc4:	ffffe097          	auipc	ra,0xffffe
    80002dc8:	f10080e7          	jalr	-240(ra) # 80000cd4 <release>
  return 0;
    80002dcc:	4501                	li	a0,0
}
    80002dce:	70e2                	ld	ra,56(sp)
    80002dd0:	7442                	ld	s0,48(sp)
    80002dd2:	74a2                	ld	s1,40(sp)
    80002dd4:	7902                	ld	s2,32(sp)
    80002dd6:	69e2                	ld	s3,24(sp)
    80002dd8:	6121                	addi	sp,sp,64
    80002dda:	8082                	ret
      release(&tickslock);
    80002ddc:	00014517          	auipc	a0,0x14
    80002de0:	d9450513          	addi	a0,a0,-620 # 80016b70 <tickslock>
    80002de4:	ffffe097          	auipc	ra,0xffffe
    80002de8:	ef0080e7          	jalr	-272(ra) # 80000cd4 <release>
      return -1;
    80002dec:	557d                	li	a0,-1
    80002dee:	b7c5                	j	80002dce <sys_sleep+0x88>

0000000080002df0 <sys_kill>:

uint64
sys_kill(void)
{
    80002df0:	1101                	addi	sp,sp,-32
    80002df2:	ec06                	sd	ra,24(sp)
    80002df4:	e822                	sd	s0,16(sp)
    80002df6:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    80002df8:	fec40593          	addi	a1,s0,-20
    80002dfc:	4501                	li	a0,0
    80002dfe:	00000097          	auipc	ra,0x0
    80002e02:	d68080e7          	jalr	-664(ra) # 80002b66 <argint>
  return kill(pid);
    80002e06:	fec42503          	lw	a0,-20(s0)
    80002e0a:	fffff097          	auipc	ra,0xfffff
    80002e0e:	4a2080e7          	jalr	1186(ra) # 800022ac <kill>
}
    80002e12:	60e2                	ld	ra,24(sp)
    80002e14:	6442                	ld	s0,16(sp)
    80002e16:	6105                	addi	sp,sp,32
    80002e18:	8082                	ret

0000000080002e1a <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80002e1a:	1101                	addi	sp,sp,-32
    80002e1c:	ec06                	sd	ra,24(sp)
    80002e1e:	e822                	sd	s0,16(sp)
    80002e20:	e426                	sd	s1,8(sp)
    80002e22:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    80002e24:	00014517          	auipc	a0,0x14
    80002e28:	d4c50513          	addi	a0,a0,-692 # 80016b70 <tickslock>
    80002e2c:	ffffe097          	auipc	ra,0xffffe
    80002e30:	df4080e7          	jalr	-524(ra) # 80000c20 <acquire>
  xticks = ticks;
    80002e34:	00006497          	auipc	s1,0x6
    80002e38:	c9c4a483          	lw	s1,-868(s1) # 80008ad0 <ticks>
  release(&tickslock);
    80002e3c:	00014517          	auipc	a0,0x14
    80002e40:	d3450513          	addi	a0,a0,-716 # 80016b70 <tickslock>
    80002e44:	ffffe097          	auipc	ra,0xffffe
    80002e48:	e90080e7          	jalr	-368(ra) # 80000cd4 <release>
  return xticks;
}
    80002e4c:	02049513          	slli	a0,s1,0x20
    80002e50:	9101                	srli	a0,a0,0x20
    80002e52:	60e2                	ld	ra,24(sp)
    80002e54:	6442                	ld	s0,16(sp)
    80002e56:	64a2                	ld	s1,8(sp)
    80002e58:	6105                	addi	sp,sp,32
    80002e5a:	8082                	ret

0000000080002e5c <sys_trace>:

// setting the tracer value
uint64
sys_trace(void)
{
    80002e5c:	1141                	addi	sp,sp,-16
    80002e5e:	e406                	sd	ra,8(sp)
    80002e60:	e022                	sd	s0,0(sp)
    80002e62:	0800                	addi	s0,sp,16
  argint(0, &myproc()->tracer);
    80002e64:	fffff097          	auipc	ra,0xfffff
    80002e68:	b92080e7          	jalr	-1134(ra) # 800019f6 <myproc>
    80002e6c:	03450593          	addi	a1,a0,52
    80002e70:	4501                	li	a0,0
    80002e72:	00000097          	auipc	ra,0x0
    80002e76:	cf4080e7          	jalr	-780(ra) # 80002b66 <argint>
  return 0;
}
    80002e7a:	4501                	li	a0,0
    80002e7c:	60a2                	ld	ra,8(sp)
    80002e7e:	6402                	ld	s0,0(sp)
    80002e80:	0141                	addi	sp,sp,16
    80002e82:	8082                	ret

0000000080002e84 <sys_sysinfo>:

// printing system info to the console
uint64
sys_sysinfo(void)
{
    80002e84:	1141                	addi	sp,sp,-16
    80002e86:	e406                	sd	ra,8(sp)
    80002e88:	e022                	sd	s0,0(sp)
    80002e8a:	0800                	addi	s0,sp,16
  printf("\nsysinfo system call prints:\n");
    80002e8c:	00005517          	auipc	a0,0x5
    80002e90:	75c50513          	addi	a0,a0,1884 # 800085e8 <syscalls+0xc0>
    80002e94:	ffffd097          	auipc	ra,0xffffd
    80002e98:	6f6080e7          	jalr	1782(ra) # 8000058a <printf>
  printf("free-memory: %d bytes\n", freemem());
    80002e9c:	ffffe097          	auipc	ra,0xffffe
    80002ea0:	caa080e7          	jalr	-854(ra) # 80000b46 <freemem>
    80002ea4:	85aa                	mv	a1,a0
    80002ea6:	00005517          	auipc	a0,0x5
    80002eaa:	76250513          	addi	a0,a0,1890 # 80008608 <syscalls+0xe0>
    80002eae:	ffffd097          	auipc	ra,0xffffd
    80002eb2:	6dc080e7          	jalr	1756(ra) # 8000058a <printf>
  printf("n_proc  : %d\n\n", aliveproc());
    80002eb6:	fffff097          	auipc	ra,0xfffff
    80002eba:	750080e7          	jalr	1872(ra) # 80002606 <aliveproc>
    80002ebe:	85aa                	mv	a1,a0
    80002ec0:	00005517          	auipc	a0,0x5
    80002ec4:	76050513          	addi	a0,a0,1888 # 80008620 <syscalls+0xf8>
    80002ec8:	ffffd097          	auipc	ra,0xffffd
    80002ecc:	6c2080e7          	jalr	1730(ra) # 8000058a <printf>
  return 0;
}
    80002ed0:	4501                	li	a0,0
    80002ed2:	60a2                	ld	ra,8(sp)
    80002ed4:	6402                	ld	s0,0(sp)
    80002ed6:	0141                	addi	sp,sp,16
    80002ed8:	8082                	ret

0000000080002eda <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80002eda:	7179                	addi	sp,sp,-48
    80002edc:	f406                	sd	ra,40(sp)
    80002ede:	f022                	sd	s0,32(sp)
    80002ee0:	ec26                	sd	s1,24(sp)
    80002ee2:	e84a                	sd	s2,16(sp)
    80002ee4:	e44e                	sd	s3,8(sp)
    80002ee6:	e052                	sd	s4,0(sp)
    80002ee8:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80002eea:	00005597          	auipc	a1,0x5
    80002eee:	74658593          	addi	a1,a1,1862 # 80008630 <syscalls+0x108>
    80002ef2:	00014517          	auipc	a0,0x14
    80002ef6:	c9650513          	addi	a0,a0,-874 # 80016b88 <bcache>
    80002efa:	ffffe097          	auipc	ra,0xffffe
    80002efe:	c96080e7          	jalr	-874(ra) # 80000b90 <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80002f02:	0001c797          	auipc	a5,0x1c
    80002f06:	c8678793          	addi	a5,a5,-890 # 8001eb88 <bcache+0x8000>
    80002f0a:	0001c717          	auipc	a4,0x1c
    80002f0e:	ee670713          	addi	a4,a4,-282 # 8001edf0 <bcache+0x8268>
    80002f12:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80002f16:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f1a:	00014497          	auipc	s1,0x14
    80002f1e:	c8648493          	addi	s1,s1,-890 # 80016ba0 <bcache+0x18>
    b->next = bcache.head.next;
    80002f22:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80002f24:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80002f26:	00005a17          	auipc	s4,0x5
    80002f2a:	712a0a13          	addi	s4,s4,1810 # 80008638 <syscalls+0x110>
    b->next = bcache.head.next;
    80002f2e:	2b893783          	ld	a5,696(s2)
    80002f32:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80002f34:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80002f38:	85d2                	mv	a1,s4
    80002f3a:	01048513          	addi	a0,s1,16
    80002f3e:	00001097          	auipc	ra,0x1
    80002f42:	4c8080e7          	jalr	1224(ra) # 80004406 <initsleeplock>
    bcache.head.next->prev = b;
    80002f46:	2b893783          	ld	a5,696(s2)
    80002f4a:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80002f4c:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80002f50:	45848493          	addi	s1,s1,1112
    80002f54:	fd349de3          	bne	s1,s3,80002f2e <binit+0x54>
  }
}
    80002f58:	70a2                	ld	ra,40(sp)
    80002f5a:	7402                	ld	s0,32(sp)
    80002f5c:	64e2                	ld	s1,24(sp)
    80002f5e:	6942                	ld	s2,16(sp)
    80002f60:	69a2                	ld	s3,8(sp)
    80002f62:	6a02                	ld	s4,0(sp)
    80002f64:	6145                	addi	sp,sp,48
    80002f66:	8082                	ret

0000000080002f68 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80002f68:	7179                	addi	sp,sp,-48
    80002f6a:	f406                	sd	ra,40(sp)
    80002f6c:	f022                	sd	s0,32(sp)
    80002f6e:	ec26                	sd	s1,24(sp)
    80002f70:	e84a                	sd	s2,16(sp)
    80002f72:	e44e                	sd	s3,8(sp)
    80002f74:	1800                	addi	s0,sp,48
    80002f76:	892a                	mv	s2,a0
    80002f78:	89ae                	mv	s3,a1
  acquire(&bcache.lock);
    80002f7a:	00014517          	auipc	a0,0x14
    80002f7e:	c0e50513          	addi	a0,a0,-1010 # 80016b88 <bcache>
    80002f82:	ffffe097          	auipc	ra,0xffffe
    80002f86:	c9e080e7          	jalr	-866(ra) # 80000c20 <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80002f8a:	0001c497          	auipc	s1,0x1c
    80002f8e:	eb64b483          	ld	s1,-330(s1) # 8001ee40 <bcache+0x82b8>
    80002f92:	0001c797          	auipc	a5,0x1c
    80002f96:	e5e78793          	addi	a5,a5,-418 # 8001edf0 <bcache+0x8268>
    80002f9a:	02f48f63          	beq	s1,a5,80002fd8 <bread+0x70>
    80002f9e:	873e                	mv	a4,a5
    80002fa0:	a021                	j	80002fa8 <bread+0x40>
    80002fa2:	68a4                	ld	s1,80(s1)
    80002fa4:	02e48a63          	beq	s1,a4,80002fd8 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80002fa8:	449c                	lw	a5,8(s1)
    80002faa:	ff279ce3          	bne	a5,s2,80002fa2 <bread+0x3a>
    80002fae:	44dc                	lw	a5,12(s1)
    80002fb0:	ff3799e3          	bne	a5,s3,80002fa2 <bread+0x3a>
      b->refcnt++;
    80002fb4:	40bc                	lw	a5,64(s1)
    80002fb6:	2785                	addiw	a5,a5,1
    80002fb8:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80002fba:	00014517          	auipc	a0,0x14
    80002fbe:	bce50513          	addi	a0,a0,-1074 # 80016b88 <bcache>
    80002fc2:	ffffe097          	auipc	ra,0xffffe
    80002fc6:	d12080e7          	jalr	-750(ra) # 80000cd4 <release>
      acquiresleep(&b->lock);
    80002fca:	01048513          	addi	a0,s1,16
    80002fce:	00001097          	auipc	ra,0x1
    80002fd2:	472080e7          	jalr	1138(ra) # 80004440 <acquiresleep>
      return b;
    80002fd6:	a8b9                	j	80003034 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002fd8:	0001c497          	auipc	s1,0x1c
    80002fdc:	e604b483          	ld	s1,-416(s1) # 8001ee38 <bcache+0x82b0>
    80002fe0:	0001c797          	auipc	a5,0x1c
    80002fe4:	e1078793          	addi	a5,a5,-496 # 8001edf0 <bcache+0x8268>
    80002fe8:	00f48863          	beq	s1,a5,80002ff8 <bread+0x90>
    80002fec:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80002fee:	40bc                	lw	a5,64(s1)
    80002ff0:	cf81                	beqz	a5,80003008 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80002ff2:	64a4                	ld	s1,72(s1)
    80002ff4:	fee49de3          	bne	s1,a4,80002fee <bread+0x86>
  panic("bget: no buffers");
    80002ff8:	00005517          	auipc	a0,0x5
    80002ffc:	64850513          	addi	a0,a0,1608 # 80008640 <syscalls+0x118>
    80003000:	ffffd097          	auipc	ra,0xffffd
    80003004:	540080e7          	jalr	1344(ra) # 80000540 <panic>
      b->dev = dev;
    80003008:	0124a423          	sw	s2,8(s1)
      b->blockno = blockno;
    8000300c:	0134a623          	sw	s3,12(s1)
      b->valid = 0;
    80003010:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003014:	4785                	li	a5,1
    80003016:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003018:	00014517          	auipc	a0,0x14
    8000301c:	b7050513          	addi	a0,a0,-1168 # 80016b88 <bcache>
    80003020:	ffffe097          	auipc	ra,0xffffe
    80003024:	cb4080e7          	jalr	-844(ra) # 80000cd4 <release>
      acquiresleep(&b->lock);
    80003028:	01048513          	addi	a0,s1,16
    8000302c:	00001097          	auipc	ra,0x1
    80003030:	414080e7          	jalr	1044(ra) # 80004440 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003034:	409c                	lw	a5,0(s1)
    80003036:	cb89                	beqz	a5,80003048 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003038:	8526                	mv	a0,s1
    8000303a:	70a2                	ld	ra,40(sp)
    8000303c:	7402                	ld	s0,32(sp)
    8000303e:	64e2                	ld	s1,24(sp)
    80003040:	6942                	ld	s2,16(sp)
    80003042:	69a2                	ld	s3,8(sp)
    80003044:	6145                	addi	sp,sp,48
    80003046:	8082                	ret
    virtio_disk_rw(b, 0);
    80003048:	4581                	li	a1,0
    8000304a:	8526                	mv	a0,s1
    8000304c:	00003097          	auipc	ra,0x3
    80003050:	fd6080e7          	jalr	-42(ra) # 80006022 <virtio_disk_rw>
    b->valid = 1;
    80003054:	4785                	li	a5,1
    80003056:	c09c                	sw	a5,0(s1)
  return b;
    80003058:	b7c5                	j	80003038 <bread+0xd0>

000000008000305a <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    8000305a:	1101                	addi	sp,sp,-32
    8000305c:	ec06                	sd	ra,24(sp)
    8000305e:	e822                	sd	s0,16(sp)
    80003060:	e426                	sd	s1,8(sp)
    80003062:	1000                	addi	s0,sp,32
    80003064:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003066:	0541                	addi	a0,a0,16
    80003068:	00001097          	auipc	ra,0x1
    8000306c:	472080e7          	jalr	1138(ra) # 800044da <holdingsleep>
    80003070:	cd01                	beqz	a0,80003088 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003072:	4585                	li	a1,1
    80003074:	8526                	mv	a0,s1
    80003076:	00003097          	auipc	ra,0x3
    8000307a:	fac080e7          	jalr	-84(ra) # 80006022 <virtio_disk_rw>
}
    8000307e:	60e2                	ld	ra,24(sp)
    80003080:	6442                	ld	s0,16(sp)
    80003082:	64a2                	ld	s1,8(sp)
    80003084:	6105                	addi	sp,sp,32
    80003086:	8082                	ret
    panic("bwrite");
    80003088:	00005517          	auipc	a0,0x5
    8000308c:	5d050513          	addi	a0,a0,1488 # 80008658 <syscalls+0x130>
    80003090:	ffffd097          	auipc	ra,0xffffd
    80003094:	4b0080e7          	jalr	1200(ra) # 80000540 <panic>

0000000080003098 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003098:	1101                	addi	sp,sp,-32
    8000309a:	ec06                	sd	ra,24(sp)
    8000309c:	e822                	sd	s0,16(sp)
    8000309e:	e426                	sd	s1,8(sp)
    800030a0:	e04a                	sd	s2,0(sp)
    800030a2:	1000                	addi	s0,sp,32
    800030a4:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800030a6:	01050913          	addi	s2,a0,16
    800030aa:	854a                	mv	a0,s2
    800030ac:	00001097          	auipc	ra,0x1
    800030b0:	42e080e7          	jalr	1070(ra) # 800044da <holdingsleep>
    800030b4:	c92d                	beqz	a0,80003126 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800030b6:	854a                	mv	a0,s2
    800030b8:	00001097          	auipc	ra,0x1
    800030bc:	3de080e7          	jalr	990(ra) # 80004496 <releasesleep>

  acquire(&bcache.lock);
    800030c0:	00014517          	auipc	a0,0x14
    800030c4:	ac850513          	addi	a0,a0,-1336 # 80016b88 <bcache>
    800030c8:	ffffe097          	auipc	ra,0xffffe
    800030cc:	b58080e7          	jalr	-1192(ra) # 80000c20 <acquire>
  b->refcnt--;
    800030d0:	40bc                	lw	a5,64(s1)
    800030d2:	37fd                	addiw	a5,a5,-1
    800030d4:	0007871b          	sext.w	a4,a5
    800030d8:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    800030da:	eb05                	bnez	a4,8000310a <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    800030dc:	68bc                	ld	a5,80(s1)
    800030de:	64b8                	ld	a4,72(s1)
    800030e0:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    800030e2:	64bc                	ld	a5,72(s1)
    800030e4:	68b8                	ld	a4,80(s1)
    800030e6:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    800030e8:	0001c797          	auipc	a5,0x1c
    800030ec:	aa078793          	addi	a5,a5,-1376 # 8001eb88 <bcache+0x8000>
    800030f0:	2b87b703          	ld	a4,696(a5)
    800030f4:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    800030f6:	0001c717          	auipc	a4,0x1c
    800030fa:	cfa70713          	addi	a4,a4,-774 # 8001edf0 <bcache+0x8268>
    800030fe:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003100:	2b87b703          	ld	a4,696(a5)
    80003104:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003106:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    8000310a:	00014517          	auipc	a0,0x14
    8000310e:	a7e50513          	addi	a0,a0,-1410 # 80016b88 <bcache>
    80003112:	ffffe097          	auipc	ra,0xffffe
    80003116:	bc2080e7          	jalr	-1086(ra) # 80000cd4 <release>
}
    8000311a:	60e2                	ld	ra,24(sp)
    8000311c:	6442                	ld	s0,16(sp)
    8000311e:	64a2                	ld	s1,8(sp)
    80003120:	6902                	ld	s2,0(sp)
    80003122:	6105                	addi	sp,sp,32
    80003124:	8082                	ret
    panic("brelse");
    80003126:	00005517          	auipc	a0,0x5
    8000312a:	53a50513          	addi	a0,a0,1338 # 80008660 <syscalls+0x138>
    8000312e:	ffffd097          	auipc	ra,0xffffd
    80003132:	412080e7          	jalr	1042(ra) # 80000540 <panic>

0000000080003136 <bpin>:

void
bpin(struct buf *b) {
    80003136:	1101                	addi	sp,sp,-32
    80003138:	ec06                	sd	ra,24(sp)
    8000313a:	e822                	sd	s0,16(sp)
    8000313c:	e426                	sd	s1,8(sp)
    8000313e:	1000                	addi	s0,sp,32
    80003140:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003142:	00014517          	auipc	a0,0x14
    80003146:	a4650513          	addi	a0,a0,-1466 # 80016b88 <bcache>
    8000314a:	ffffe097          	auipc	ra,0xffffe
    8000314e:	ad6080e7          	jalr	-1322(ra) # 80000c20 <acquire>
  b->refcnt++;
    80003152:	40bc                	lw	a5,64(s1)
    80003154:	2785                	addiw	a5,a5,1
    80003156:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003158:	00014517          	auipc	a0,0x14
    8000315c:	a3050513          	addi	a0,a0,-1488 # 80016b88 <bcache>
    80003160:	ffffe097          	auipc	ra,0xffffe
    80003164:	b74080e7          	jalr	-1164(ra) # 80000cd4 <release>
}
    80003168:	60e2                	ld	ra,24(sp)
    8000316a:	6442                	ld	s0,16(sp)
    8000316c:	64a2                	ld	s1,8(sp)
    8000316e:	6105                	addi	sp,sp,32
    80003170:	8082                	ret

0000000080003172 <bunpin>:

void
bunpin(struct buf *b) {
    80003172:	1101                	addi	sp,sp,-32
    80003174:	ec06                	sd	ra,24(sp)
    80003176:	e822                	sd	s0,16(sp)
    80003178:	e426                	sd	s1,8(sp)
    8000317a:	1000                	addi	s0,sp,32
    8000317c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000317e:	00014517          	auipc	a0,0x14
    80003182:	a0a50513          	addi	a0,a0,-1526 # 80016b88 <bcache>
    80003186:	ffffe097          	auipc	ra,0xffffe
    8000318a:	a9a080e7          	jalr	-1382(ra) # 80000c20 <acquire>
  b->refcnt--;
    8000318e:	40bc                	lw	a5,64(s1)
    80003190:	37fd                	addiw	a5,a5,-1
    80003192:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003194:	00014517          	auipc	a0,0x14
    80003198:	9f450513          	addi	a0,a0,-1548 # 80016b88 <bcache>
    8000319c:	ffffe097          	auipc	ra,0xffffe
    800031a0:	b38080e7          	jalr	-1224(ra) # 80000cd4 <release>
}
    800031a4:	60e2                	ld	ra,24(sp)
    800031a6:	6442                	ld	s0,16(sp)
    800031a8:	64a2                	ld	s1,8(sp)
    800031aa:	6105                	addi	sp,sp,32
    800031ac:	8082                	ret

00000000800031ae <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800031ae:	1101                	addi	sp,sp,-32
    800031b0:	ec06                	sd	ra,24(sp)
    800031b2:	e822                	sd	s0,16(sp)
    800031b4:	e426                	sd	s1,8(sp)
    800031b6:	e04a                	sd	s2,0(sp)
    800031b8:	1000                	addi	s0,sp,32
    800031ba:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800031bc:	00d5d59b          	srliw	a1,a1,0xd
    800031c0:	0001c797          	auipc	a5,0x1c
    800031c4:	0a47a783          	lw	a5,164(a5) # 8001f264 <sb+0x1c>
    800031c8:	9dbd                	addw	a1,a1,a5
    800031ca:	00000097          	auipc	ra,0x0
    800031ce:	d9e080e7          	jalr	-610(ra) # 80002f68 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    800031d2:	0074f713          	andi	a4,s1,7
    800031d6:	4785                	li	a5,1
    800031d8:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    800031dc:	14ce                	slli	s1,s1,0x33
    800031de:	90d9                	srli	s1,s1,0x36
    800031e0:	00950733          	add	a4,a0,s1
    800031e4:	05874703          	lbu	a4,88(a4)
    800031e8:	00e7f6b3          	and	a3,a5,a4
    800031ec:	c69d                	beqz	a3,8000321a <bfree+0x6c>
    800031ee:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    800031f0:	94aa                	add	s1,s1,a0
    800031f2:	fff7c793          	not	a5,a5
    800031f6:	8f7d                	and	a4,a4,a5
    800031f8:	04e48c23          	sb	a4,88(s1)
  log_write(bp);
    800031fc:	00001097          	auipc	ra,0x1
    80003200:	126080e7          	jalr	294(ra) # 80004322 <log_write>
  brelse(bp);
    80003204:	854a                	mv	a0,s2
    80003206:	00000097          	auipc	ra,0x0
    8000320a:	e92080e7          	jalr	-366(ra) # 80003098 <brelse>
}
    8000320e:	60e2                	ld	ra,24(sp)
    80003210:	6442                	ld	s0,16(sp)
    80003212:	64a2                	ld	s1,8(sp)
    80003214:	6902                	ld	s2,0(sp)
    80003216:	6105                	addi	sp,sp,32
    80003218:	8082                	ret
    panic("freeing free block");
    8000321a:	00005517          	auipc	a0,0x5
    8000321e:	44e50513          	addi	a0,a0,1102 # 80008668 <syscalls+0x140>
    80003222:	ffffd097          	auipc	ra,0xffffd
    80003226:	31e080e7          	jalr	798(ra) # 80000540 <panic>

000000008000322a <balloc>:
{
    8000322a:	711d                	addi	sp,sp,-96
    8000322c:	ec86                	sd	ra,88(sp)
    8000322e:	e8a2                	sd	s0,80(sp)
    80003230:	e4a6                	sd	s1,72(sp)
    80003232:	e0ca                	sd	s2,64(sp)
    80003234:	fc4e                	sd	s3,56(sp)
    80003236:	f852                	sd	s4,48(sp)
    80003238:	f456                	sd	s5,40(sp)
    8000323a:	f05a                	sd	s6,32(sp)
    8000323c:	ec5e                	sd	s7,24(sp)
    8000323e:	e862                	sd	s8,16(sp)
    80003240:	e466                	sd	s9,8(sp)
    80003242:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003244:	0001c797          	auipc	a5,0x1c
    80003248:	0087a783          	lw	a5,8(a5) # 8001f24c <sb+0x4>
    8000324c:	cff5                	beqz	a5,80003348 <balloc+0x11e>
    8000324e:	8baa                	mv	s7,a0
    80003250:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003252:	0001cb17          	auipc	s6,0x1c
    80003256:	ff6b0b13          	addi	s6,s6,-10 # 8001f248 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000325a:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    8000325c:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000325e:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003260:	6c89                	lui	s9,0x2
    80003262:	a061                	j	800032ea <balloc+0xc0>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003264:	97ca                	add	a5,a5,s2
    80003266:	8e55                	or	a2,a2,a3
    80003268:	04c78c23          	sb	a2,88(a5)
        log_write(bp);
    8000326c:	854a                	mv	a0,s2
    8000326e:	00001097          	auipc	ra,0x1
    80003272:	0b4080e7          	jalr	180(ra) # 80004322 <log_write>
        brelse(bp);
    80003276:	854a                	mv	a0,s2
    80003278:	00000097          	auipc	ra,0x0
    8000327c:	e20080e7          	jalr	-480(ra) # 80003098 <brelse>
  bp = bread(dev, bno);
    80003280:	85a6                	mv	a1,s1
    80003282:	855e                	mv	a0,s7
    80003284:	00000097          	auipc	ra,0x0
    80003288:	ce4080e7          	jalr	-796(ra) # 80002f68 <bread>
    8000328c:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    8000328e:	40000613          	li	a2,1024
    80003292:	4581                	li	a1,0
    80003294:	05850513          	addi	a0,a0,88
    80003298:	ffffe097          	auipc	ra,0xffffe
    8000329c:	a84080e7          	jalr	-1404(ra) # 80000d1c <memset>
  log_write(bp);
    800032a0:	854a                	mv	a0,s2
    800032a2:	00001097          	auipc	ra,0x1
    800032a6:	080080e7          	jalr	128(ra) # 80004322 <log_write>
  brelse(bp);
    800032aa:	854a                	mv	a0,s2
    800032ac:	00000097          	auipc	ra,0x0
    800032b0:	dec080e7          	jalr	-532(ra) # 80003098 <brelse>
}
    800032b4:	8526                	mv	a0,s1
    800032b6:	60e6                	ld	ra,88(sp)
    800032b8:	6446                	ld	s0,80(sp)
    800032ba:	64a6                	ld	s1,72(sp)
    800032bc:	6906                	ld	s2,64(sp)
    800032be:	79e2                	ld	s3,56(sp)
    800032c0:	7a42                	ld	s4,48(sp)
    800032c2:	7aa2                	ld	s5,40(sp)
    800032c4:	7b02                	ld	s6,32(sp)
    800032c6:	6be2                	ld	s7,24(sp)
    800032c8:	6c42                	ld	s8,16(sp)
    800032ca:	6ca2                	ld	s9,8(sp)
    800032cc:	6125                	addi	sp,sp,96
    800032ce:	8082                	ret
    brelse(bp);
    800032d0:	854a                	mv	a0,s2
    800032d2:	00000097          	auipc	ra,0x0
    800032d6:	dc6080e7          	jalr	-570(ra) # 80003098 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800032da:	015c87bb          	addw	a5,s9,s5
    800032de:	00078a9b          	sext.w	s5,a5
    800032e2:	004b2703          	lw	a4,4(s6)
    800032e6:	06eaf163          	bgeu	s5,a4,80003348 <balloc+0x11e>
    bp = bread(dev, BBLOCK(b, sb));
    800032ea:	41fad79b          	sraiw	a5,s5,0x1f
    800032ee:	0137d79b          	srliw	a5,a5,0x13
    800032f2:	015787bb          	addw	a5,a5,s5
    800032f6:	40d7d79b          	sraiw	a5,a5,0xd
    800032fa:	01cb2583          	lw	a1,28(s6)
    800032fe:	9dbd                	addw	a1,a1,a5
    80003300:	855e                	mv	a0,s7
    80003302:	00000097          	auipc	ra,0x0
    80003306:	c66080e7          	jalr	-922(ra) # 80002f68 <bread>
    8000330a:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000330c:	004b2503          	lw	a0,4(s6)
    80003310:	000a849b          	sext.w	s1,s5
    80003314:	8762                	mv	a4,s8
    80003316:	faa4fde3          	bgeu	s1,a0,800032d0 <balloc+0xa6>
      m = 1 << (bi % 8);
    8000331a:	00777693          	andi	a3,a4,7
    8000331e:	00d996bb          	sllw	a3,s3,a3
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003322:	41f7579b          	sraiw	a5,a4,0x1f
    80003326:	01d7d79b          	srliw	a5,a5,0x1d
    8000332a:	9fb9                	addw	a5,a5,a4
    8000332c:	4037d79b          	sraiw	a5,a5,0x3
    80003330:	00f90633          	add	a2,s2,a5
    80003334:	05864603          	lbu	a2,88(a2)
    80003338:	00c6f5b3          	and	a1,a3,a2
    8000333c:	d585                	beqz	a1,80003264 <balloc+0x3a>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000333e:	2705                	addiw	a4,a4,1
    80003340:	2485                	addiw	s1,s1,1
    80003342:	fd471ae3          	bne	a4,s4,80003316 <balloc+0xec>
    80003346:	b769                	j	800032d0 <balloc+0xa6>
  printf("balloc: out of blocks\n");
    80003348:	00005517          	auipc	a0,0x5
    8000334c:	33850513          	addi	a0,a0,824 # 80008680 <syscalls+0x158>
    80003350:	ffffd097          	auipc	ra,0xffffd
    80003354:	23a080e7          	jalr	570(ra) # 8000058a <printf>
  return 0;
    80003358:	4481                	li	s1,0
    8000335a:	bfa9                	j	800032b4 <balloc+0x8a>

000000008000335c <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    8000335c:	7179                	addi	sp,sp,-48
    8000335e:	f406                	sd	ra,40(sp)
    80003360:	f022                	sd	s0,32(sp)
    80003362:	ec26                	sd	s1,24(sp)
    80003364:	e84a                	sd	s2,16(sp)
    80003366:	e44e                	sd	s3,8(sp)
    80003368:	e052                	sd	s4,0(sp)
    8000336a:	1800                	addi	s0,sp,48
    8000336c:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    8000336e:	47ad                	li	a5,11
    80003370:	02b7e863          	bltu	a5,a1,800033a0 <bmap+0x44>
    if((addr = ip->addrs[bn]) == 0){
    80003374:	02059793          	slli	a5,a1,0x20
    80003378:	01e7d593          	srli	a1,a5,0x1e
    8000337c:	00b504b3          	add	s1,a0,a1
    80003380:	0504a903          	lw	s2,80(s1)
    80003384:	06091e63          	bnez	s2,80003400 <bmap+0xa4>
      addr = balloc(ip->dev);
    80003388:	4108                	lw	a0,0(a0)
    8000338a:	00000097          	auipc	ra,0x0
    8000338e:	ea0080e7          	jalr	-352(ra) # 8000322a <balloc>
    80003392:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003396:	06090563          	beqz	s2,80003400 <bmap+0xa4>
        return 0;
      ip->addrs[bn] = addr;
    8000339a:	0524a823          	sw	s2,80(s1)
    8000339e:	a08d                	j	80003400 <bmap+0xa4>
    }
    return addr;
  }
  bn -= NDIRECT;
    800033a0:	ff45849b          	addiw	s1,a1,-12
    800033a4:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800033a8:	0ff00793          	li	a5,255
    800033ac:	08e7e563          	bltu	a5,a4,80003436 <bmap+0xda>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    800033b0:	08052903          	lw	s2,128(a0)
    800033b4:	00091d63          	bnez	s2,800033ce <bmap+0x72>
      addr = balloc(ip->dev);
    800033b8:	4108                	lw	a0,0(a0)
    800033ba:	00000097          	auipc	ra,0x0
    800033be:	e70080e7          	jalr	-400(ra) # 8000322a <balloc>
    800033c2:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    800033c6:	02090d63          	beqz	s2,80003400 <bmap+0xa4>
        return 0;
      ip->addrs[NDIRECT] = addr;
    800033ca:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    800033ce:	85ca                	mv	a1,s2
    800033d0:	0009a503          	lw	a0,0(s3)
    800033d4:	00000097          	auipc	ra,0x0
    800033d8:	b94080e7          	jalr	-1132(ra) # 80002f68 <bread>
    800033dc:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800033de:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800033e2:	02049713          	slli	a4,s1,0x20
    800033e6:	01e75593          	srli	a1,a4,0x1e
    800033ea:	00b784b3          	add	s1,a5,a1
    800033ee:	0004a903          	lw	s2,0(s1)
    800033f2:	02090063          	beqz	s2,80003412 <bmap+0xb6>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    800033f6:	8552                	mv	a0,s4
    800033f8:	00000097          	auipc	ra,0x0
    800033fc:	ca0080e7          	jalr	-864(ra) # 80003098 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003400:	854a                	mv	a0,s2
    80003402:	70a2                	ld	ra,40(sp)
    80003404:	7402                	ld	s0,32(sp)
    80003406:	64e2                	ld	s1,24(sp)
    80003408:	6942                	ld	s2,16(sp)
    8000340a:	69a2                	ld	s3,8(sp)
    8000340c:	6a02                	ld	s4,0(sp)
    8000340e:	6145                	addi	sp,sp,48
    80003410:	8082                	ret
      addr = balloc(ip->dev);
    80003412:	0009a503          	lw	a0,0(s3)
    80003416:	00000097          	auipc	ra,0x0
    8000341a:	e14080e7          	jalr	-492(ra) # 8000322a <balloc>
    8000341e:	0005091b          	sext.w	s2,a0
      if(addr){
    80003422:	fc090ae3          	beqz	s2,800033f6 <bmap+0x9a>
        a[bn] = addr;
    80003426:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    8000342a:	8552                	mv	a0,s4
    8000342c:	00001097          	auipc	ra,0x1
    80003430:	ef6080e7          	jalr	-266(ra) # 80004322 <log_write>
    80003434:	b7c9                	j	800033f6 <bmap+0x9a>
  panic("bmap: out of range");
    80003436:	00005517          	auipc	a0,0x5
    8000343a:	26250513          	addi	a0,a0,610 # 80008698 <syscalls+0x170>
    8000343e:	ffffd097          	auipc	ra,0xffffd
    80003442:	102080e7          	jalr	258(ra) # 80000540 <panic>

0000000080003446 <iget>:
{
    80003446:	7179                	addi	sp,sp,-48
    80003448:	f406                	sd	ra,40(sp)
    8000344a:	f022                	sd	s0,32(sp)
    8000344c:	ec26                	sd	s1,24(sp)
    8000344e:	e84a                	sd	s2,16(sp)
    80003450:	e44e                	sd	s3,8(sp)
    80003452:	e052                	sd	s4,0(sp)
    80003454:	1800                	addi	s0,sp,48
    80003456:	89aa                	mv	s3,a0
    80003458:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000345a:	0001c517          	auipc	a0,0x1c
    8000345e:	e0e50513          	addi	a0,a0,-498 # 8001f268 <itable>
    80003462:	ffffd097          	auipc	ra,0xffffd
    80003466:	7be080e7          	jalr	1982(ra) # 80000c20 <acquire>
  empty = 0;
    8000346a:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000346c:	0001c497          	auipc	s1,0x1c
    80003470:	e1448493          	addi	s1,s1,-492 # 8001f280 <itable+0x18>
    80003474:	0001e697          	auipc	a3,0x1e
    80003478:	89c68693          	addi	a3,a3,-1892 # 80020d10 <log>
    8000347c:	a039                	j	8000348a <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    8000347e:	02090b63          	beqz	s2,800034b4 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003482:	08848493          	addi	s1,s1,136
    80003486:	02d48a63          	beq	s1,a3,800034ba <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000348a:	449c                	lw	a5,8(s1)
    8000348c:	fef059e3          	blez	a5,8000347e <iget+0x38>
    80003490:	4098                	lw	a4,0(s1)
    80003492:	ff3716e3          	bne	a4,s3,8000347e <iget+0x38>
    80003496:	40d8                	lw	a4,4(s1)
    80003498:	ff4713e3          	bne	a4,s4,8000347e <iget+0x38>
      ip->ref++;
    8000349c:	2785                	addiw	a5,a5,1
    8000349e:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800034a0:	0001c517          	auipc	a0,0x1c
    800034a4:	dc850513          	addi	a0,a0,-568 # 8001f268 <itable>
    800034a8:	ffffe097          	auipc	ra,0xffffe
    800034ac:	82c080e7          	jalr	-2004(ra) # 80000cd4 <release>
      return ip;
    800034b0:	8926                	mv	s2,s1
    800034b2:	a03d                	j	800034e0 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800034b4:	f7f9                	bnez	a5,80003482 <iget+0x3c>
    800034b6:	8926                	mv	s2,s1
    800034b8:	b7e9                	j	80003482 <iget+0x3c>
  if(empty == 0)
    800034ba:	02090c63          	beqz	s2,800034f2 <iget+0xac>
  ip->dev = dev;
    800034be:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800034c2:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800034c6:	4785                	li	a5,1
    800034c8:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800034cc:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800034d0:	0001c517          	auipc	a0,0x1c
    800034d4:	d9850513          	addi	a0,a0,-616 # 8001f268 <itable>
    800034d8:	ffffd097          	auipc	ra,0xffffd
    800034dc:	7fc080e7          	jalr	2044(ra) # 80000cd4 <release>
}
    800034e0:	854a                	mv	a0,s2
    800034e2:	70a2                	ld	ra,40(sp)
    800034e4:	7402                	ld	s0,32(sp)
    800034e6:	64e2                	ld	s1,24(sp)
    800034e8:	6942                	ld	s2,16(sp)
    800034ea:	69a2                	ld	s3,8(sp)
    800034ec:	6a02                	ld	s4,0(sp)
    800034ee:	6145                	addi	sp,sp,48
    800034f0:	8082                	ret
    panic("iget: no inodes");
    800034f2:	00005517          	auipc	a0,0x5
    800034f6:	1be50513          	addi	a0,a0,446 # 800086b0 <syscalls+0x188>
    800034fa:	ffffd097          	auipc	ra,0xffffd
    800034fe:	046080e7          	jalr	70(ra) # 80000540 <panic>

0000000080003502 <fsinit>:
fsinit(int dev) {
    80003502:	7179                	addi	sp,sp,-48
    80003504:	f406                	sd	ra,40(sp)
    80003506:	f022                	sd	s0,32(sp)
    80003508:	ec26                	sd	s1,24(sp)
    8000350a:	e84a                	sd	s2,16(sp)
    8000350c:	e44e                	sd	s3,8(sp)
    8000350e:	1800                	addi	s0,sp,48
    80003510:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    80003512:	4585                	li	a1,1
    80003514:	00000097          	auipc	ra,0x0
    80003518:	a54080e7          	jalr	-1452(ra) # 80002f68 <bread>
    8000351c:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000351e:	0001c997          	auipc	s3,0x1c
    80003522:	d2a98993          	addi	s3,s3,-726 # 8001f248 <sb>
    80003526:	02000613          	li	a2,32
    8000352a:	05850593          	addi	a1,a0,88
    8000352e:	854e                	mv	a0,s3
    80003530:	ffffe097          	auipc	ra,0xffffe
    80003534:	848080e7          	jalr	-1976(ra) # 80000d78 <memmove>
  brelse(bp);
    80003538:	8526                	mv	a0,s1
    8000353a:	00000097          	auipc	ra,0x0
    8000353e:	b5e080e7          	jalr	-1186(ra) # 80003098 <brelse>
  if(sb.magic != FSMAGIC)
    80003542:	0009a703          	lw	a4,0(s3)
    80003546:	102037b7          	lui	a5,0x10203
    8000354a:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000354e:	02f71263          	bne	a4,a5,80003572 <fsinit+0x70>
  initlog(dev, &sb);
    80003552:	0001c597          	auipc	a1,0x1c
    80003556:	cf658593          	addi	a1,a1,-778 # 8001f248 <sb>
    8000355a:	854a                	mv	a0,s2
    8000355c:	00001097          	auipc	ra,0x1
    80003560:	b4a080e7          	jalr	-1206(ra) # 800040a6 <initlog>
}
    80003564:	70a2                	ld	ra,40(sp)
    80003566:	7402                	ld	s0,32(sp)
    80003568:	64e2                	ld	s1,24(sp)
    8000356a:	6942                	ld	s2,16(sp)
    8000356c:	69a2                	ld	s3,8(sp)
    8000356e:	6145                	addi	sp,sp,48
    80003570:	8082                	ret
    panic("invalid file system");
    80003572:	00005517          	auipc	a0,0x5
    80003576:	14e50513          	addi	a0,a0,334 # 800086c0 <syscalls+0x198>
    8000357a:	ffffd097          	auipc	ra,0xffffd
    8000357e:	fc6080e7          	jalr	-58(ra) # 80000540 <panic>

0000000080003582 <iinit>:
{
    80003582:	7179                	addi	sp,sp,-48
    80003584:	f406                	sd	ra,40(sp)
    80003586:	f022                	sd	s0,32(sp)
    80003588:	ec26                	sd	s1,24(sp)
    8000358a:	e84a                	sd	s2,16(sp)
    8000358c:	e44e                	sd	s3,8(sp)
    8000358e:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80003590:	00005597          	auipc	a1,0x5
    80003594:	14858593          	addi	a1,a1,328 # 800086d8 <syscalls+0x1b0>
    80003598:	0001c517          	auipc	a0,0x1c
    8000359c:	cd050513          	addi	a0,a0,-816 # 8001f268 <itable>
    800035a0:	ffffd097          	auipc	ra,0xffffd
    800035a4:	5f0080e7          	jalr	1520(ra) # 80000b90 <initlock>
  for(i = 0; i < NINODE; i++) {
    800035a8:	0001c497          	auipc	s1,0x1c
    800035ac:	ce848493          	addi	s1,s1,-792 # 8001f290 <itable+0x28>
    800035b0:	0001d997          	auipc	s3,0x1d
    800035b4:	77098993          	addi	s3,s3,1904 # 80020d20 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800035b8:	00005917          	auipc	s2,0x5
    800035bc:	12890913          	addi	s2,s2,296 # 800086e0 <syscalls+0x1b8>
    800035c0:	85ca                	mv	a1,s2
    800035c2:	8526                	mv	a0,s1
    800035c4:	00001097          	auipc	ra,0x1
    800035c8:	e42080e7          	jalr	-446(ra) # 80004406 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800035cc:	08848493          	addi	s1,s1,136
    800035d0:	ff3498e3          	bne	s1,s3,800035c0 <iinit+0x3e>
}
    800035d4:	70a2                	ld	ra,40(sp)
    800035d6:	7402                	ld	s0,32(sp)
    800035d8:	64e2                	ld	s1,24(sp)
    800035da:	6942                	ld	s2,16(sp)
    800035dc:	69a2                	ld	s3,8(sp)
    800035de:	6145                	addi	sp,sp,48
    800035e0:	8082                	ret

00000000800035e2 <ialloc>:
{
    800035e2:	715d                	addi	sp,sp,-80
    800035e4:	e486                	sd	ra,72(sp)
    800035e6:	e0a2                	sd	s0,64(sp)
    800035e8:	fc26                	sd	s1,56(sp)
    800035ea:	f84a                	sd	s2,48(sp)
    800035ec:	f44e                	sd	s3,40(sp)
    800035ee:	f052                	sd	s4,32(sp)
    800035f0:	ec56                	sd	s5,24(sp)
    800035f2:	e85a                	sd	s6,16(sp)
    800035f4:	e45e                	sd	s7,8(sp)
    800035f6:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800035f8:	0001c717          	auipc	a4,0x1c
    800035fc:	c5c72703          	lw	a4,-932(a4) # 8001f254 <sb+0xc>
    80003600:	4785                	li	a5,1
    80003602:	04e7fa63          	bgeu	a5,a4,80003656 <ialloc+0x74>
    80003606:	8aaa                	mv	s5,a0
    80003608:	8bae                	mv	s7,a1
    8000360a:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    8000360c:	0001ca17          	auipc	s4,0x1c
    80003610:	c3ca0a13          	addi	s4,s4,-964 # 8001f248 <sb>
    80003614:	00048b1b          	sext.w	s6,s1
    80003618:	0044d593          	srli	a1,s1,0x4
    8000361c:	018a2783          	lw	a5,24(s4)
    80003620:	9dbd                	addw	a1,a1,a5
    80003622:	8556                	mv	a0,s5
    80003624:	00000097          	auipc	ra,0x0
    80003628:	944080e7          	jalr	-1724(ra) # 80002f68 <bread>
    8000362c:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000362e:	05850993          	addi	s3,a0,88
    80003632:	00f4f793          	andi	a5,s1,15
    80003636:	079a                	slli	a5,a5,0x6
    80003638:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    8000363a:	00099783          	lh	a5,0(s3)
    8000363e:	c3a1                	beqz	a5,8000367e <ialloc+0x9c>
    brelse(bp);
    80003640:	00000097          	auipc	ra,0x0
    80003644:	a58080e7          	jalr	-1448(ra) # 80003098 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003648:	0485                	addi	s1,s1,1
    8000364a:	00ca2703          	lw	a4,12(s4)
    8000364e:	0004879b          	sext.w	a5,s1
    80003652:	fce7e1e3          	bltu	a5,a4,80003614 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80003656:	00005517          	auipc	a0,0x5
    8000365a:	09250513          	addi	a0,a0,146 # 800086e8 <syscalls+0x1c0>
    8000365e:	ffffd097          	auipc	ra,0xffffd
    80003662:	f2c080e7          	jalr	-212(ra) # 8000058a <printf>
  return 0;
    80003666:	4501                	li	a0,0
}
    80003668:	60a6                	ld	ra,72(sp)
    8000366a:	6406                	ld	s0,64(sp)
    8000366c:	74e2                	ld	s1,56(sp)
    8000366e:	7942                	ld	s2,48(sp)
    80003670:	79a2                	ld	s3,40(sp)
    80003672:	7a02                	ld	s4,32(sp)
    80003674:	6ae2                	ld	s5,24(sp)
    80003676:	6b42                	ld	s6,16(sp)
    80003678:	6ba2                	ld	s7,8(sp)
    8000367a:	6161                	addi	sp,sp,80
    8000367c:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    8000367e:	04000613          	li	a2,64
    80003682:	4581                	li	a1,0
    80003684:	854e                	mv	a0,s3
    80003686:	ffffd097          	auipc	ra,0xffffd
    8000368a:	696080e7          	jalr	1686(ra) # 80000d1c <memset>
      dip->type = type;
    8000368e:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80003692:	854a                	mv	a0,s2
    80003694:	00001097          	auipc	ra,0x1
    80003698:	c8e080e7          	jalr	-882(ra) # 80004322 <log_write>
      brelse(bp);
    8000369c:	854a                	mv	a0,s2
    8000369e:	00000097          	auipc	ra,0x0
    800036a2:	9fa080e7          	jalr	-1542(ra) # 80003098 <brelse>
      return iget(dev, inum);
    800036a6:	85da                	mv	a1,s6
    800036a8:	8556                	mv	a0,s5
    800036aa:	00000097          	auipc	ra,0x0
    800036ae:	d9c080e7          	jalr	-612(ra) # 80003446 <iget>
    800036b2:	bf5d                	j	80003668 <ialloc+0x86>

00000000800036b4 <iupdate>:
{
    800036b4:	1101                	addi	sp,sp,-32
    800036b6:	ec06                	sd	ra,24(sp)
    800036b8:	e822                	sd	s0,16(sp)
    800036ba:	e426                	sd	s1,8(sp)
    800036bc:	e04a                	sd	s2,0(sp)
    800036be:	1000                	addi	s0,sp,32
    800036c0:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800036c2:	415c                	lw	a5,4(a0)
    800036c4:	0047d79b          	srliw	a5,a5,0x4
    800036c8:	0001c597          	auipc	a1,0x1c
    800036cc:	b985a583          	lw	a1,-1128(a1) # 8001f260 <sb+0x18>
    800036d0:	9dbd                	addw	a1,a1,a5
    800036d2:	4108                	lw	a0,0(a0)
    800036d4:	00000097          	auipc	ra,0x0
    800036d8:	894080e7          	jalr	-1900(ra) # 80002f68 <bread>
    800036dc:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    800036de:	05850793          	addi	a5,a0,88
    800036e2:	40d8                	lw	a4,4(s1)
    800036e4:	8b3d                	andi	a4,a4,15
    800036e6:	071a                	slli	a4,a4,0x6
    800036e8:	97ba                	add	a5,a5,a4
  dip->type = ip->type;
    800036ea:	04449703          	lh	a4,68(s1)
    800036ee:	00e79023          	sh	a4,0(a5)
  dip->major = ip->major;
    800036f2:	04649703          	lh	a4,70(s1)
    800036f6:	00e79123          	sh	a4,2(a5)
  dip->minor = ip->minor;
    800036fa:	04849703          	lh	a4,72(s1)
    800036fe:	00e79223          	sh	a4,4(a5)
  dip->nlink = ip->nlink;
    80003702:	04a49703          	lh	a4,74(s1)
    80003706:	00e79323          	sh	a4,6(a5)
  dip->size = ip->size;
    8000370a:	44f8                	lw	a4,76(s1)
    8000370c:	c798                	sw	a4,8(a5)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    8000370e:	03400613          	li	a2,52
    80003712:	05048593          	addi	a1,s1,80
    80003716:	00c78513          	addi	a0,a5,12
    8000371a:	ffffd097          	auipc	ra,0xffffd
    8000371e:	65e080e7          	jalr	1630(ra) # 80000d78 <memmove>
  log_write(bp);
    80003722:	854a                	mv	a0,s2
    80003724:	00001097          	auipc	ra,0x1
    80003728:	bfe080e7          	jalr	-1026(ra) # 80004322 <log_write>
  brelse(bp);
    8000372c:	854a                	mv	a0,s2
    8000372e:	00000097          	auipc	ra,0x0
    80003732:	96a080e7          	jalr	-1686(ra) # 80003098 <brelse>
}
    80003736:	60e2                	ld	ra,24(sp)
    80003738:	6442                	ld	s0,16(sp)
    8000373a:	64a2                	ld	s1,8(sp)
    8000373c:	6902                	ld	s2,0(sp)
    8000373e:	6105                	addi	sp,sp,32
    80003740:	8082                	ret

0000000080003742 <idup>:
{
    80003742:	1101                	addi	sp,sp,-32
    80003744:	ec06                	sd	ra,24(sp)
    80003746:	e822                	sd	s0,16(sp)
    80003748:	e426                	sd	s1,8(sp)
    8000374a:	1000                	addi	s0,sp,32
    8000374c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    8000374e:	0001c517          	auipc	a0,0x1c
    80003752:	b1a50513          	addi	a0,a0,-1254 # 8001f268 <itable>
    80003756:	ffffd097          	auipc	ra,0xffffd
    8000375a:	4ca080e7          	jalr	1226(ra) # 80000c20 <acquire>
  ip->ref++;
    8000375e:	449c                	lw	a5,8(s1)
    80003760:	2785                	addiw	a5,a5,1
    80003762:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003764:	0001c517          	auipc	a0,0x1c
    80003768:	b0450513          	addi	a0,a0,-1276 # 8001f268 <itable>
    8000376c:	ffffd097          	auipc	ra,0xffffd
    80003770:	568080e7          	jalr	1384(ra) # 80000cd4 <release>
}
    80003774:	8526                	mv	a0,s1
    80003776:	60e2                	ld	ra,24(sp)
    80003778:	6442                	ld	s0,16(sp)
    8000377a:	64a2                	ld	s1,8(sp)
    8000377c:	6105                	addi	sp,sp,32
    8000377e:	8082                	ret

0000000080003780 <ilock>:
{
    80003780:	1101                	addi	sp,sp,-32
    80003782:	ec06                	sd	ra,24(sp)
    80003784:	e822                	sd	s0,16(sp)
    80003786:	e426                	sd	s1,8(sp)
    80003788:	e04a                	sd	s2,0(sp)
    8000378a:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000378c:	c115                	beqz	a0,800037b0 <ilock+0x30>
    8000378e:	84aa                	mv	s1,a0
    80003790:	451c                	lw	a5,8(a0)
    80003792:	00f05f63          	blez	a5,800037b0 <ilock+0x30>
  acquiresleep(&ip->lock);
    80003796:	0541                	addi	a0,a0,16
    80003798:	00001097          	auipc	ra,0x1
    8000379c:	ca8080e7          	jalr	-856(ra) # 80004440 <acquiresleep>
  if(ip->valid == 0){
    800037a0:	40bc                	lw	a5,64(s1)
    800037a2:	cf99                	beqz	a5,800037c0 <ilock+0x40>
}
    800037a4:	60e2                	ld	ra,24(sp)
    800037a6:	6442                	ld	s0,16(sp)
    800037a8:	64a2                	ld	s1,8(sp)
    800037aa:	6902                	ld	s2,0(sp)
    800037ac:	6105                	addi	sp,sp,32
    800037ae:	8082                	ret
    panic("ilock");
    800037b0:	00005517          	auipc	a0,0x5
    800037b4:	f5050513          	addi	a0,a0,-176 # 80008700 <syscalls+0x1d8>
    800037b8:	ffffd097          	auipc	ra,0xffffd
    800037bc:	d88080e7          	jalr	-632(ra) # 80000540 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800037c0:	40dc                	lw	a5,4(s1)
    800037c2:	0047d79b          	srliw	a5,a5,0x4
    800037c6:	0001c597          	auipc	a1,0x1c
    800037ca:	a9a5a583          	lw	a1,-1382(a1) # 8001f260 <sb+0x18>
    800037ce:	9dbd                	addw	a1,a1,a5
    800037d0:	4088                	lw	a0,0(s1)
    800037d2:	fffff097          	auipc	ra,0xfffff
    800037d6:	796080e7          	jalr	1942(ra) # 80002f68 <bread>
    800037da:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    800037dc:	05850593          	addi	a1,a0,88
    800037e0:	40dc                	lw	a5,4(s1)
    800037e2:	8bbd                	andi	a5,a5,15
    800037e4:	079a                	slli	a5,a5,0x6
    800037e6:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    800037e8:	00059783          	lh	a5,0(a1)
    800037ec:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800037f0:	00259783          	lh	a5,2(a1)
    800037f4:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800037f8:	00459783          	lh	a5,4(a1)
    800037fc:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003800:	00659783          	lh	a5,6(a1)
    80003804:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003808:	459c                	lw	a5,8(a1)
    8000380a:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    8000380c:	03400613          	li	a2,52
    80003810:	05b1                	addi	a1,a1,12
    80003812:	05048513          	addi	a0,s1,80
    80003816:	ffffd097          	auipc	ra,0xffffd
    8000381a:	562080e7          	jalr	1378(ra) # 80000d78 <memmove>
    brelse(bp);
    8000381e:	854a                	mv	a0,s2
    80003820:	00000097          	auipc	ra,0x0
    80003824:	878080e7          	jalr	-1928(ra) # 80003098 <brelse>
    ip->valid = 1;
    80003828:	4785                	li	a5,1
    8000382a:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    8000382c:	04449783          	lh	a5,68(s1)
    80003830:	fbb5                	bnez	a5,800037a4 <ilock+0x24>
      panic("ilock: no type");
    80003832:	00005517          	auipc	a0,0x5
    80003836:	ed650513          	addi	a0,a0,-298 # 80008708 <syscalls+0x1e0>
    8000383a:	ffffd097          	auipc	ra,0xffffd
    8000383e:	d06080e7          	jalr	-762(ra) # 80000540 <panic>

0000000080003842 <iunlock>:
{
    80003842:	1101                	addi	sp,sp,-32
    80003844:	ec06                	sd	ra,24(sp)
    80003846:	e822                	sd	s0,16(sp)
    80003848:	e426                	sd	s1,8(sp)
    8000384a:	e04a                	sd	s2,0(sp)
    8000384c:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    8000384e:	c905                	beqz	a0,8000387e <iunlock+0x3c>
    80003850:	84aa                	mv	s1,a0
    80003852:	01050913          	addi	s2,a0,16
    80003856:	854a                	mv	a0,s2
    80003858:	00001097          	auipc	ra,0x1
    8000385c:	c82080e7          	jalr	-894(ra) # 800044da <holdingsleep>
    80003860:	cd19                	beqz	a0,8000387e <iunlock+0x3c>
    80003862:	449c                	lw	a5,8(s1)
    80003864:	00f05d63          	blez	a5,8000387e <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003868:	854a                	mv	a0,s2
    8000386a:	00001097          	auipc	ra,0x1
    8000386e:	c2c080e7          	jalr	-980(ra) # 80004496 <releasesleep>
}
    80003872:	60e2                	ld	ra,24(sp)
    80003874:	6442                	ld	s0,16(sp)
    80003876:	64a2                	ld	s1,8(sp)
    80003878:	6902                	ld	s2,0(sp)
    8000387a:	6105                	addi	sp,sp,32
    8000387c:	8082                	ret
    panic("iunlock");
    8000387e:	00005517          	auipc	a0,0x5
    80003882:	e9a50513          	addi	a0,a0,-358 # 80008718 <syscalls+0x1f0>
    80003886:	ffffd097          	auipc	ra,0xffffd
    8000388a:	cba080e7          	jalr	-838(ra) # 80000540 <panic>

000000008000388e <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000388e:	7179                	addi	sp,sp,-48
    80003890:	f406                	sd	ra,40(sp)
    80003892:	f022                	sd	s0,32(sp)
    80003894:	ec26                	sd	s1,24(sp)
    80003896:	e84a                	sd	s2,16(sp)
    80003898:	e44e                	sd	s3,8(sp)
    8000389a:	e052                	sd	s4,0(sp)
    8000389c:	1800                	addi	s0,sp,48
    8000389e:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    800038a0:	05050493          	addi	s1,a0,80
    800038a4:	08050913          	addi	s2,a0,128
    800038a8:	a021                	j	800038b0 <itrunc+0x22>
    800038aa:	0491                	addi	s1,s1,4
    800038ac:	01248d63          	beq	s1,s2,800038c6 <itrunc+0x38>
    if(ip->addrs[i]){
    800038b0:	408c                	lw	a1,0(s1)
    800038b2:	dde5                	beqz	a1,800038aa <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    800038b4:	0009a503          	lw	a0,0(s3)
    800038b8:	00000097          	auipc	ra,0x0
    800038bc:	8f6080e7          	jalr	-1802(ra) # 800031ae <bfree>
      ip->addrs[i] = 0;
    800038c0:	0004a023          	sw	zero,0(s1)
    800038c4:	b7dd                	j	800038aa <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    800038c6:	0809a583          	lw	a1,128(s3)
    800038ca:	e185                	bnez	a1,800038ea <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    800038cc:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    800038d0:	854e                	mv	a0,s3
    800038d2:	00000097          	auipc	ra,0x0
    800038d6:	de2080e7          	jalr	-542(ra) # 800036b4 <iupdate>
}
    800038da:	70a2                	ld	ra,40(sp)
    800038dc:	7402                	ld	s0,32(sp)
    800038de:	64e2                	ld	s1,24(sp)
    800038e0:	6942                	ld	s2,16(sp)
    800038e2:	69a2                	ld	s3,8(sp)
    800038e4:	6a02                	ld	s4,0(sp)
    800038e6:	6145                	addi	sp,sp,48
    800038e8:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    800038ea:	0009a503          	lw	a0,0(s3)
    800038ee:	fffff097          	auipc	ra,0xfffff
    800038f2:	67a080e7          	jalr	1658(ra) # 80002f68 <bread>
    800038f6:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800038f8:	05850493          	addi	s1,a0,88
    800038fc:	45850913          	addi	s2,a0,1112
    80003900:	a021                	j	80003908 <itrunc+0x7a>
    80003902:	0491                	addi	s1,s1,4
    80003904:	01248b63          	beq	s1,s2,8000391a <itrunc+0x8c>
      if(a[j])
    80003908:	408c                	lw	a1,0(s1)
    8000390a:	dde5                	beqz	a1,80003902 <itrunc+0x74>
        bfree(ip->dev, a[j]);
    8000390c:	0009a503          	lw	a0,0(s3)
    80003910:	00000097          	auipc	ra,0x0
    80003914:	89e080e7          	jalr	-1890(ra) # 800031ae <bfree>
    80003918:	b7ed                	j	80003902 <itrunc+0x74>
    brelse(bp);
    8000391a:	8552                	mv	a0,s4
    8000391c:	fffff097          	auipc	ra,0xfffff
    80003920:	77c080e7          	jalr	1916(ra) # 80003098 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003924:	0809a583          	lw	a1,128(s3)
    80003928:	0009a503          	lw	a0,0(s3)
    8000392c:	00000097          	auipc	ra,0x0
    80003930:	882080e7          	jalr	-1918(ra) # 800031ae <bfree>
    ip->addrs[NDIRECT] = 0;
    80003934:	0809a023          	sw	zero,128(s3)
    80003938:	bf51                	j	800038cc <itrunc+0x3e>

000000008000393a <iput>:
{
    8000393a:	1101                	addi	sp,sp,-32
    8000393c:	ec06                	sd	ra,24(sp)
    8000393e:	e822                	sd	s0,16(sp)
    80003940:	e426                	sd	s1,8(sp)
    80003942:	e04a                	sd	s2,0(sp)
    80003944:	1000                	addi	s0,sp,32
    80003946:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003948:	0001c517          	auipc	a0,0x1c
    8000394c:	92050513          	addi	a0,a0,-1760 # 8001f268 <itable>
    80003950:	ffffd097          	auipc	ra,0xffffd
    80003954:	2d0080e7          	jalr	720(ra) # 80000c20 <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003958:	4498                	lw	a4,8(s1)
    8000395a:	4785                	li	a5,1
    8000395c:	02f70363          	beq	a4,a5,80003982 <iput+0x48>
  ip->ref--;
    80003960:	449c                	lw	a5,8(s1)
    80003962:	37fd                	addiw	a5,a5,-1
    80003964:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003966:	0001c517          	auipc	a0,0x1c
    8000396a:	90250513          	addi	a0,a0,-1790 # 8001f268 <itable>
    8000396e:	ffffd097          	auipc	ra,0xffffd
    80003972:	366080e7          	jalr	870(ra) # 80000cd4 <release>
}
    80003976:	60e2                	ld	ra,24(sp)
    80003978:	6442                	ld	s0,16(sp)
    8000397a:	64a2                	ld	s1,8(sp)
    8000397c:	6902                	ld	s2,0(sp)
    8000397e:	6105                	addi	sp,sp,32
    80003980:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003982:	40bc                	lw	a5,64(s1)
    80003984:	dff1                	beqz	a5,80003960 <iput+0x26>
    80003986:	04a49783          	lh	a5,74(s1)
    8000398a:	fbf9                	bnez	a5,80003960 <iput+0x26>
    acquiresleep(&ip->lock);
    8000398c:	01048913          	addi	s2,s1,16
    80003990:	854a                	mv	a0,s2
    80003992:	00001097          	auipc	ra,0x1
    80003996:	aae080e7          	jalr	-1362(ra) # 80004440 <acquiresleep>
    release(&itable.lock);
    8000399a:	0001c517          	auipc	a0,0x1c
    8000399e:	8ce50513          	addi	a0,a0,-1842 # 8001f268 <itable>
    800039a2:	ffffd097          	auipc	ra,0xffffd
    800039a6:	332080e7          	jalr	818(ra) # 80000cd4 <release>
    itrunc(ip);
    800039aa:	8526                	mv	a0,s1
    800039ac:	00000097          	auipc	ra,0x0
    800039b0:	ee2080e7          	jalr	-286(ra) # 8000388e <itrunc>
    ip->type = 0;
    800039b4:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    800039b8:	8526                	mv	a0,s1
    800039ba:	00000097          	auipc	ra,0x0
    800039be:	cfa080e7          	jalr	-774(ra) # 800036b4 <iupdate>
    ip->valid = 0;
    800039c2:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    800039c6:	854a                	mv	a0,s2
    800039c8:	00001097          	auipc	ra,0x1
    800039cc:	ace080e7          	jalr	-1330(ra) # 80004496 <releasesleep>
    acquire(&itable.lock);
    800039d0:	0001c517          	auipc	a0,0x1c
    800039d4:	89850513          	addi	a0,a0,-1896 # 8001f268 <itable>
    800039d8:	ffffd097          	auipc	ra,0xffffd
    800039dc:	248080e7          	jalr	584(ra) # 80000c20 <acquire>
    800039e0:	b741                	j	80003960 <iput+0x26>

00000000800039e2 <iunlockput>:
{
    800039e2:	1101                	addi	sp,sp,-32
    800039e4:	ec06                	sd	ra,24(sp)
    800039e6:	e822                	sd	s0,16(sp)
    800039e8:	e426                	sd	s1,8(sp)
    800039ea:	1000                	addi	s0,sp,32
    800039ec:	84aa                	mv	s1,a0
  iunlock(ip);
    800039ee:	00000097          	auipc	ra,0x0
    800039f2:	e54080e7          	jalr	-428(ra) # 80003842 <iunlock>
  iput(ip);
    800039f6:	8526                	mv	a0,s1
    800039f8:	00000097          	auipc	ra,0x0
    800039fc:	f42080e7          	jalr	-190(ra) # 8000393a <iput>
}
    80003a00:	60e2                	ld	ra,24(sp)
    80003a02:	6442                	ld	s0,16(sp)
    80003a04:	64a2                	ld	s1,8(sp)
    80003a06:	6105                	addi	sp,sp,32
    80003a08:	8082                	ret

0000000080003a0a <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003a0a:	1141                	addi	sp,sp,-16
    80003a0c:	e422                	sd	s0,8(sp)
    80003a0e:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003a10:	411c                	lw	a5,0(a0)
    80003a12:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003a14:	415c                	lw	a5,4(a0)
    80003a16:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003a18:	04451783          	lh	a5,68(a0)
    80003a1c:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003a20:	04a51783          	lh	a5,74(a0)
    80003a24:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003a28:	04c56783          	lwu	a5,76(a0)
    80003a2c:	e99c                	sd	a5,16(a1)
}
    80003a2e:	6422                	ld	s0,8(sp)
    80003a30:	0141                	addi	sp,sp,16
    80003a32:	8082                	ret

0000000080003a34 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003a34:	457c                	lw	a5,76(a0)
    80003a36:	0ed7e963          	bltu	a5,a3,80003b28 <readi+0xf4>
{
    80003a3a:	7159                	addi	sp,sp,-112
    80003a3c:	f486                	sd	ra,104(sp)
    80003a3e:	f0a2                	sd	s0,96(sp)
    80003a40:	eca6                	sd	s1,88(sp)
    80003a42:	e8ca                	sd	s2,80(sp)
    80003a44:	e4ce                	sd	s3,72(sp)
    80003a46:	e0d2                	sd	s4,64(sp)
    80003a48:	fc56                	sd	s5,56(sp)
    80003a4a:	f85a                	sd	s6,48(sp)
    80003a4c:	f45e                	sd	s7,40(sp)
    80003a4e:	f062                	sd	s8,32(sp)
    80003a50:	ec66                	sd	s9,24(sp)
    80003a52:	e86a                	sd	s10,16(sp)
    80003a54:	e46e                	sd	s11,8(sp)
    80003a56:	1880                	addi	s0,sp,112
    80003a58:	8b2a                	mv	s6,a0
    80003a5a:	8bae                	mv	s7,a1
    80003a5c:	8a32                	mv	s4,a2
    80003a5e:	84b6                	mv	s1,a3
    80003a60:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80003a62:	9f35                	addw	a4,a4,a3
    return 0;
    80003a64:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003a66:	0ad76063          	bltu	a4,a3,80003b06 <readi+0xd2>
  if(off + n > ip->size)
    80003a6a:	00e7f463          	bgeu	a5,a4,80003a72 <readi+0x3e>
    n = ip->size - off;
    80003a6e:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003a72:	0a0a8963          	beqz	s5,80003b24 <readi+0xf0>
    80003a76:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003a78:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003a7c:	5c7d                	li	s8,-1
    80003a7e:	a82d                	j	80003ab8 <readi+0x84>
    80003a80:	020d1d93          	slli	s11,s10,0x20
    80003a84:	020ddd93          	srli	s11,s11,0x20
    80003a88:	05890613          	addi	a2,s2,88
    80003a8c:	86ee                	mv	a3,s11
    80003a8e:	963a                	add	a2,a2,a4
    80003a90:	85d2                	mv	a1,s4
    80003a92:	855e                	mv	a0,s7
    80003a94:	fffff097          	auipc	ra,0xfffff
    80003a98:	a16080e7          	jalr	-1514(ra) # 800024aa <either_copyout>
    80003a9c:	05850d63          	beq	a0,s8,80003af6 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003aa0:	854a                	mv	a0,s2
    80003aa2:	fffff097          	auipc	ra,0xfffff
    80003aa6:	5f6080e7          	jalr	1526(ra) # 80003098 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003aaa:	013d09bb          	addw	s3,s10,s3
    80003aae:	009d04bb          	addw	s1,s10,s1
    80003ab2:	9a6e                	add	s4,s4,s11
    80003ab4:	0559f763          	bgeu	s3,s5,80003b02 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80003ab8:	00a4d59b          	srliw	a1,s1,0xa
    80003abc:	855a                	mv	a0,s6
    80003abe:	00000097          	auipc	ra,0x0
    80003ac2:	89e080e7          	jalr	-1890(ra) # 8000335c <bmap>
    80003ac6:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003aca:	cd85                	beqz	a1,80003b02 <readi+0xce>
    bp = bread(ip->dev, addr);
    80003acc:	000b2503          	lw	a0,0(s6)
    80003ad0:	fffff097          	auipc	ra,0xfffff
    80003ad4:	498080e7          	jalr	1176(ra) # 80002f68 <bread>
    80003ad8:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003ada:	3ff4f713          	andi	a4,s1,1023
    80003ade:	40ec87bb          	subw	a5,s9,a4
    80003ae2:	413a86bb          	subw	a3,s5,s3
    80003ae6:	8d3e                	mv	s10,a5
    80003ae8:	2781                	sext.w	a5,a5
    80003aea:	0006861b          	sext.w	a2,a3
    80003aee:	f8f679e3          	bgeu	a2,a5,80003a80 <readi+0x4c>
    80003af2:	8d36                	mv	s10,a3
    80003af4:	b771                	j	80003a80 <readi+0x4c>
      brelse(bp);
    80003af6:	854a                	mv	a0,s2
    80003af8:	fffff097          	auipc	ra,0xfffff
    80003afc:	5a0080e7          	jalr	1440(ra) # 80003098 <brelse>
      tot = -1;
    80003b00:	59fd                	li	s3,-1
  }
  return tot;
    80003b02:	0009851b          	sext.w	a0,s3
}
    80003b06:	70a6                	ld	ra,104(sp)
    80003b08:	7406                	ld	s0,96(sp)
    80003b0a:	64e6                	ld	s1,88(sp)
    80003b0c:	6946                	ld	s2,80(sp)
    80003b0e:	69a6                	ld	s3,72(sp)
    80003b10:	6a06                	ld	s4,64(sp)
    80003b12:	7ae2                	ld	s5,56(sp)
    80003b14:	7b42                	ld	s6,48(sp)
    80003b16:	7ba2                	ld	s7,40(sp)
    80003b18:	7c02                	ld	s8,32(sp)
    80003b1a:	6ce2                	ld	s9,24(sp)
    80003b1c:	6d42                	ld	s10,16(sp)
    80003b1e:	6da2                	ld	s11,8(sp)
    80003b20:	6165                	addi	sp,sp,112
    80003b22:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003b24:	89d6                	mv	s3,s5
    80003b26:	bff1                	j	80003b02 <readi+0xce>
    return 0;
    80003b28:	4501                	li	a0,0
}
    80003b2a:	8082                	ret

0000000080003b2c <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003b2c:	457c                	lw	a5,76(a0)
    80003b2e:	10d7e863          	bltu	a5,a3,80003c3e <writei+0x112>
{
    80003b32:	7159                	addi	sp,sp,-112
    80003b34:	f486                	sd	ra,104(sp)
    80003b36:	f0a2                	sd	s0,96(sp)
    80003b38:	eca6                	sd	s1,88(sp)
    80003b3a:	e8ca                	sd	s2,80(sp)
    80003b3c:	e4ce                	sd	s3,72(sp)
    80003b3e:	e0d2                	sd	s4,64(sp)
    80003b40:	fc56                	sd	s5,56(sp)
    80003b42:	f85a                	sd	s6,48(sp)
    80003b44:	f45e                	sd	s7,40(sp)
    80003b46:	f062                	sd	s8,32(sp)
    80003b48:	ec66                	sd	s9,24(sp)
    80003b4a:	e86a                	sd	s10,16(sp)
    80003b4c:	e46e                	sd	s11,8(sp)
    80003b4e:	1880                	addi	s0,sp,112
    80003b50:	8aaa                	mv	s5,a0
    80003b52:	8bae                	mv	s7,a1
    80003b54:	8a32                	mv	s4,a2
    80003b56:	8936                	mv	s2,a3
    80003b58:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003b5a:	00e687bb          	addw	a5,a3,a4
    80003b5e:	0ed7e263          	bltu	a5,a3,80003c42 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003b62:	00043737          	lui	a4,0x43
    80003b66:	0ef76063          	bltu	a4,a5,80003c46 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003b6a:	0c0b0863          	beqz	s6,80003c3a <writei+0x10e>
    80003b6e:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80003b70:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003b74:	5c7d                	li	s8,-1
    80003b76:	a091                	j	80003bba <writei+0x8e>
    80003b78:	020d1d93          	slli	s11,s10,0x20
    80003b7c:	020ddd93          	srli	s11,s11,0x20
    80003b80:	05848513          	addi	a0,s1,88
    80003b84:	86ee                	mv	a3,s11
    80003b86:	8652                	mv	a2,s4
    80003b88:	85de                	mv	a1,s7
    80003b8a:	953a                	add	a0,a0,a4
    80003b8c:	fffff097          	auipc	ra,0xfffff
    80003b90:	974080e7          	jalr	-1676(ra) # 80002500 <either_copyin>
    80003b94:	07850263          	beq	a0,s8,80003bf8 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003b98:	8526                	mv	a0,s1
    80003b9a:	00000097          	auipc	ra,0x0
    80003b9e:	788080e7          	jalr	1928(ra) # 80004322 <log_write>
    brelse(bp);
    80003ba2:	8526                	mv	a0,s1
    80003ba4:	fffff097          	auipc	ra,0xfffff
    80003ba8:	4f4080e7          	jalr	1268(ra) # 80003098 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003bac:	013d09bb          	addw	s3,s10,s3
    80003bb0:	012d093b          	addw	s2,s10,s2
    80003bb4:	9a6e                	add	s4,s4,s11
    80003bb6:	0569f663          	bgeu	s3,s6,80003c02 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    80003bba:	00a9559b          	srliw	a1,s2,0xa
    80003bbe:	8556                	mv	a0,s5
    80003bc0:	fffff097          	auipc	ra,0xfffff
    80003bc4:	79c080e7          	jalr	1948(ra) # 8000335c <bmap>
    80003bc8:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    80003bcc:	c99d                	beqz	a1,80003c02 <writei+0xd6>
    bp = bread(ip->dev, addr);
    80003bce:	000aa503          	lw	a0,0(s5)
    80003bd2:	fffff097          	auipc	ra,0xfffff
    80003bd6:	396080e7          	jalr	918(ra) # 80002f68 <bread>
    80003bda:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003bdc:	3ff97713          	andi	a4,s2,1023
    80003be0:	40ec87bb          	subw	a5,s9,a4
    80003be4:	413b06bb          	subw	a3,s6,s3
    80003be8:	8d3e                	mv	s10,a5
    80003bea:	2781                	sext.w	a5,a5
    80003bec:	0006861b          	sext.w	a2,a3
    80003bf0:	f8f674e3          	bgeu	a2,a5,80003b78 <writei+0x4c>
    80003bf4:	8d36                	mv	s10,a3
    80003bf6:	b749                	j	80003b78 <writei+0x4c>
      brelse(bp);
    80003bf8:	8526                	mv	a0,s1
    80003bfa:	fffff097          	auipc	ra,0xfffff
    80003bfe:	49e080e7          	jalr	1182(ra) # 80003098 <brelse>
  }

  if(off > ip->size)
    80003c02:	04caa783          	lw	a5,76(s5)
    80003c06:	0127f463          	bgeu	a5,s2,80003c0e <writei+0xe2>
    ip->size = off;
    80003c0a:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003c0e:	8556                	mv	a0,s5
    80003c10:	00000097          	auipc	ra,0x0
    80003c14:	aa4080e7          	jalr	-1372(ra) # 800036b4 <iupdate>

  return tot;
    80003c18:	0009851b          	sext.w	a0,s3
}
    80003c1c:	70a6                	ld	ra,104(sp)
    80003c1e:	7406                	ld	s0,96(sp)
    80003c20:	64e6                	ld	s1,88(sp)
    80003c22:	6946                	ld	s2,80(sp)
    80003c24:	69a6                	ld	s3,72(sp)
    80003c26:	6a06                	ld	s4,64(sp)
    80003c28:	7ae2                	ld	s5,56(sp)
    80003c2a:	7b42                	ld	s6,48(sp)
    80003c2c:	7ba2                	ld	s7,40(sp)
    80003c2e:	7c02                	ld	s8,32(sp)
    80003c30:	6ce2                	ld	s9,24(sp)
    80003c32:	6d42                	ld	s10,16(sp)
    80003c34:	6da2                	ld	s11,8(sp)
    80003c36:	6165                	addi	sp,sp,112
    80003c38:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003c3a:	89da                	mv	s3,s6
    80003c3c:	bfc9                	j	80003c0e <writei+0xe2>
    return -1;
    80003c3e:	557d                	li	a0,-1
}
    80003c40:	8082                	ret
    return -1;
    80003c42:	557d                	li	a0,-1
    80003c44:	bfe1                	j	80003c1c <writei+0xf0>
    return -1;
    80003c46:	557d                	li	a0,-1
    80003c48:	bfd1                	j	80003c1c <writei+0xf0>

0000000080003c4a <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003c4a:	1141                	addi	sp,sp,-16
    80003c4c:	e406                	sd	ra,8(sp)
    80003c4e:	e022                	sd	s0,0(sp)
    80003c50:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003c52:	4639                	li	a2,14
    80003c54:	ffffd097          	auipc	ra,0xffffd
    80003c58:	198080e7          	jalr	408(ra) # 80000dec <strncmp>
}
    80003c5c:	60a2                	ld	ra,8(sp)
    80003c5e:	6402                	ld	s0,0(sp)
    80003c60:	0141                	addi	sp,sp,16
    80003c62:	8082                	ret

0000000080003c64 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003c64:	7139                	addi	sp,sp,-64
    80003c66:	fc06                	sd	ra,56(sp)
    80003c68:	f822                	sd	s0,48(sp)
    80003c6a:	f426                	sd	s1,40(sp)
    80003c6c:	f04a                	sd	s2,32(sp)
    80003c6e:	ec4e                	sd	s3,24(sp)
    80003c70:	e852                	sd	s4,16(sp)
    80003c72:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003c74:	04451703          	lh	a4,68(a0)
    80003c78:	4785                	li	a5,1
    80003c7a:	00f71a63          	bne	a4,a5,80003c8e <dirlookup+0x2a>
    80003c7e:	892a                	mv	s2,a0
    80003c80:	89ae                	mv	s3,a1
    80003c82:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c84:	457c                	lw	a5,76(a0)
    80003c86:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003c88:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003c8a:	e79d                	bnez	a5,80003cb8 <dirlookup+0x54>
    80003c8c:	a8a5                	j	80003d04 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003c8e:	00005517          	auipc	a0,0x5
    80003c92:	a9250513          	addi	a0,a0,-1390 # 80008720 <syscalls+0x1f8>
    80003c96:	ffffd097          	auipc	ra,0xffffd
    80003c9a:	8aa080e7          	jalr	-1878(ra) # 80000540 <panic>
      panic("dirlookup read");
    80003c9e:	00005517          	auipc	a0,0x5
    80003ca2:	a9a50513          	addi	a0,a0,-1382 # 80008738 <syscalls+0x210>
    80003ca6:	ffffd097          	auipc	ra,0xffffd
    80003caa:	89a080e7          	jalr	-1894(ra) # 80000540 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003cae:	24c1                	addiw	s1,s1,16
    80003cb0:	04c92783          	lw	a5,76(s2)
    80003cb4:	04f4f763          	bgeu	s1,a5,80003d02 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003cb8:	4741                	li	a4,16
    80003cba:	86a6                	mv	a3,s1
    80003cbc:	fc040613          	addi	a2,s0,-64
    80003cc0:	4581                	li	a1,0
    80003cc2:	854a                	mv	a0,s2
    80003cc4:	00000097          	auipc	ra,0x0
    80003cc8:	d70080e7          	jalr	-656(ra) # 80003a34 <readi>
    80003ccc:	47c1                	li	a5,16
    80003cce:	fcf518e3          	bne	a0,a5,80003c9e <dirlookup+0x3a>
    if(de.inum == 0)
    80003cd2:	fc045783          	lhu	a5,-64(s0)
    80003cd6:	dfe1                	beqz	a5,80003cae <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003cd8:	fc240593          	addi	a1,s0,-62
    80003cdc:	854e                	mv	a0,s3
    80003cde:	00000097          	auipc	ra,0x0
    80003ce2:	f6c080e7          	jalr	-148(ra) # 80003c4a <namecmp>
    80003ce6:	f561                	bnez	a0,80003cae <dirlookup+0x4a>
      if(poff)
    80003ce8:	000a0463          	beqz	s4,80003cf0 <dirlookup+0x8c>
        *poff = off;
    80003cec:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003cf0:	fc045583          	lhu	a1,-64(s0)
    80003cf4:	00092503          	lw	a0,0(s2)
    80003cf8:	fffff097          	auipc	ra,0xfffff
    80003cfc:	74e080e7          	jalr	1870(ra) # 80003446 <iget>
    80003d00:	a011                	j	80003d04 <dirlookup+0xa0>
  return 0;
    80003d02:	4501                	li	a0,0
}
    80003d04:	70e2                	ld	ra,56(sp)
    80003d06:	7442                	ld	s0,48(sp)
    80003d08:	74a2                	ld	s1,40(sp)
    80003d0a:	7902                	ld	s2,32(sp)
    80003d0c:	69e2                	ld	s3,24(sp)
    80003d0e:	6a42                	ld	s4,16(sp)
    80003d10:	6121                	addi	sp,sp,64
    80003d12:	8082                	ret

0000000080003d14 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003d14:	711d                	addi	sp,sp,-96
    80003d16:	ec86                	sd	ra,88(sp)
    80003d18:	e8a2                	sd	s0,80(sp)
    80003d1a:	e4a6                	sd	s1,72(sp)
    80003d1c:	e0ca                	sd	s2,64(sp)
    80003d1e:	fc4e                	sd	s3,56(sp)
    80003d20:	f852                	sd	s4,48(sp)
    80003d22:	f456                	sd	s5,40(sp)
    80003d24:	f05a                	sd	s6,32(sp)
    80003d26:	ec5e                	sd	s7,24(sp)
    80003d28:	e862                	sd	s8,16(sp)
    80003d2a:	e466                	sd	s9,8(sp)
    80003d2c:	e06a                	sd	s10,0(sp)
    80003d2e:	1080                	addi	s0,sp,96
    80003d30:	84aa                	mv	s1,a0
    80003d32:	8b2e                	mv	s6,a1
    80003d34:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003d36:	00054703          	lbu	a4,0(a0)
    80003d3a:	02f00793          	li	a5,47
    80003d3e:	02f70363          	beq	a4,a5,80003d64 <namex+0x50>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003d42:	ffffe097          	auipc	ra,0xffffe
    80003d46:	cb4080e7          	jalr	-844(ra) # 800019f6 <myproc>
    80003d4a:	15053503          	ld	a0,336(a0)
    80003d4e:	00000097          	auipc	ra,0x0
    80003d52:	9f4080e7          	jalr	-1548(ra) # 80003742 <idup>
    80003d56:	8a2a                	mv	s4,a0
  while(*path == '/')
    80003d58:	02f00913          	li	s2,47
  if(len >= DIRSIZ)
    80003d5c:	4cb5                	li	s9,13
  len = path - s;
    80003d5e:	4b81                	li	s7,0

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003d60:	4c05                	li	s8,1
    80003d62:	a87d                	j	80003e20 <namex+0x10c>
    ip = iget(ROOTDEV, ROOTINO);
    80003d64:	4585                	li	a1,1
    80003d66:	4505                	li	a0,1
    80003d68:	fffff097          	auipc	ra,0xfffff
    80003d6c:	6de080e7          	jalr	1758(ra) # 80003446 <iget>
    80003d70:	8a2a                	mv	s4,a0
    80003d72:	b7dd                	j	80003d58 <namex+0x44>
      iunlockput(ip);
    80003d74:	8552                	mv	a0,s4
    80003d76:	00000097          	auipc	ra,0x0
    80003d7a:	c6c080e7          	jalr	-916(ra) # 800039e2 <iunlockput>
      return 0;
    80003d7e:	4a01                	li	s4,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003d80:	8552                	mv	a0,s4
    80003d82:	60e6                	ld	ra,88(sp)
    80003d84:	6446                	ld	s0,80(sp)
    80003d86:	64a6                	ld	s1,72(sp)
    80003d88:	6906                	ld	s2,64(sp)
    80003d8a:	79e2                	ld	s3,56(sp)
    80003d8c:	7a42                	ld	s4,48(sp)
    80003d8e:	7aa2                	ld	s5,40(sp)
    80003d90:	7b02                	ld	s6,32(sp)
    80003d92:	6be2                	ld	s7,24(sp)
    80003d94:	6c42                	ld	s8,16(sp)
    80003d96:	6ca2                	ld	s9,8(sp)
    80003d98:	6d02                	ld	s10,0(sp)
    80003d9a:	6125                	addi	sp,sp,96
    80003d9c:	8082                	ret
      iunlock(ip);
    80003d9e:	8552                	mv	a0,s4
    80003da0:	00000097          	auipc	ra,0x0
    80003da4:	aa2080e7          	jalr	-1374(ra) # 80003842 <iunlock>
      return ip;
    80003da8:	bfe1                	j	80003d80 <namex+0x6c>
      iunlockput(ip);
    80003daa:	8552                	mv	a0,s4
    80003dac:	00000097          	auipc	ra,0x0
    80003db0:	c36080e7          	jalr	-970(ra) # 800039e2 <iunlockput>
      return 0;
    80003db4:	8a4e                	mv	s4,s3
    80003db6:	b7e9                	j	80003d80 <namex+0x6c>
  len = path - s;
    80003db8:	40998633          	sub	a2,s3,s1
    80003dbc:	00060d1b          	sext.w	s10,a2
  if(len >= DIRSIZ)
    80003dc0:	09acd863          	bge	s9,s10,80003e50 <namex+0x13c>
    memmove(name, s, DIRSIZ);
    80003dc4:	4639                	li	a2,14
    80003dc6:	85a6                	mv	a1,s1
    80003dc8:	8556                	mv	a0,s5
    80003dca:	ffffd097          	auipc	ra,0xffffd
    80003dce:	fae080e7          	jalr	-82(ra) # 80000d78 <memmove>
    80003dd2:	84ce                	mv	s1,s3
  while(*path == '/')
    80003dd4:	0004c783          	lbu	a5,0(s1)
    80003dd8:	01279763          	bne	a5,s2,80003de6 <namex+0xd2>
    path++;
    80003ddc:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003dde:	0004c783          	lbu	a5,0(s1)
    80003de2:	ff278de3          	beq	a5,s2,80003ddc <namex+0xc8>
    ilock(ip);
    80003de6:	8552                	mv	a0,s4
    80003de8:	00000097          	auipc	ra,0x0
    80003dec:	998080e7          	jalr	-1640(ra) # 80003780 <ilock>
    if(ip->type != T_DIR){
    80003df0:	044a1783          	lh	a5,68(s4)
    80003df4:	f98790e3          	bne	a5,s8,80003d74 <namex+0x60>
    if(nameiparent && *path == '\0'){
    80003df8:	000b0563          	beqz	s6,80003e02 <namex+0xee>
    80003dfc:	0004c783          	lbu	a5,0(s1)
    80003e00:	dfd9                	beqz	a5,80003d9e <namex+0x8a>
    if((next = dirlookup(ip, name, 0)) == 0){
    80003e02:	865e                	mv	a2,s7
    80003e04:	85d6                	mv	a1,s5
    80003e06:	8552                	mv	a0,s4
    80003e08:	00000097          	auipc	ra,0x0
    80003e0c:	e5c080e7          	jalr	-420(ra) # 80003c64 <dirlookup>
    80003e10:	89aa                	mv	s3,a0
    80003e12:	dd41                	beqz	a0,80003daa <namex+0x96>
    iunlockput(ip);
    80003e14:	8552                	mv	a0,s4
    80003e16:	00000097          	auipc	ra,0x0
    80003e1a:	bcc080e7          	jalr	-1076(ra) # 800039e2 <iunlockput>
    ip = next;
    80003e1e:	8a4e                	mv	s4,s3
  while(*path == '/')
    80003e20:	0004c783          	lbu	a5,0(s1)
    80003e24:	01279763          	bne	a5,s2,80003e32 <namex+0x11e>
    path++;
    80003e28:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003e2a:	0004c783          	lbu	a5,0(s1)
    80003e2e:	ff278de3          	beq	a5,s2,80003e28 <namex+0x114>
  if(*path == 0)
    80003e32:	cb9d                	beqz	a5,80003e68 <namex+0x154>
  while(*path != '/' && *path != 0)
    80003e34:	0004c783          	lbu	a5,0(s1)
    80003e38:	89a6                	mv	s3,s1
  len = path - s;
    80003e3a:	8d5e                	mv	s10,s7
    80003e3c:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80003e3e:	01278963          	beq	a5,s2,80003e50 <namex+0x13c>
    80003e42:	dbbd                	beqz	a5,80003db8 <namex+0xa4>
    path++;
    80003e44:	0985                	addi	s3,s3,1
  while(*path != '/' && *path != 0)
    80003e46:	0009c783          	lbu	a5,0(s3)
    80003e4a:	ff279ce3          	bne	a5,s2,80003e42 <namex+0x12e>
    80003e4e:	b7ad                	j	80003db8 <namex+0xa4>
    memmove(name, s, len);
    80003e50:	2601                	sext.w	a2,a2
    80003e52:	85a6                	mv	a1,s1
    80003e54:	8556                	mv	a0,s5
    80003e56:	ffffd097          	auipc	ra,0xffffd
    80003e5a:	f22080e7          	jalr	-222(ra) # 80000d78 <memmove>
    name[len] = 0;
    80003e5e:	9d56                	add	s10,s10,s5
    80003e60:	000d0023          	sb	zero,0(s10)
    80003e64:	84ce                	mv	s1,s3
    80003e66:	b7bd                	j	80003dd4 <namex+0xc0>
  if(nameiparent){
    80003e68:	f00b0ce3          	beqz	s6,80003d80 <namex+0x6c>
    iput(ip);
    80003e6c:	8552                	mv	a0,s4
    80003e6e:	00000097          	auipc	ra,0x0
    80003e72:	acc080e7          	jalr	-1332(ra) # 8000393a <iput>
    return 0;
    80003e76:	4a01                	li	s4,0
    80003e78:	b721                	j	80003d80 <namex+0x6c>

0000000080003e7a <dirlink>:
{
    80003e7a:	7139                	addi	sp,sp,-64
    80003e7c:	fc06                	sd	ra,56(sp)
    80003e7e:	f822                	sd	s0,48(sp)
    80003e80:	f426                	sd	s1,40(sp)
    80003e82:	f04a                	sd	s2,32(sp)
    80003e84:	ec4e                	sd	s3,24(sp)
    80003e86:	e852                	sd	s4,16(sp)
    80003e88:	0080                	addi	s0,sp,64
    80003e8a:	892a                	mv	s2,a0
    80003e8c:	8a2e                	mv	s4,a1
    80003e8e:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80003e90:	4601                	li	a2,0
    80003e92:	00000097          	auipc	ra,0x0
    80003e96:	dd2080e7          	jalr	-558(ra) # 80003c64 <dirlookup>
    80003e9a:	e93d                	bnez	a0,80003f10 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003e9c:	04c92483          	lw	s1,76(s2)
    80003ea0:	c49d                	beqz	s1,80003ece <dirlink+0x54>
    80003ea2:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ea4:	4741                	li	a4,16
    80003ea6:	86a6                	mv	a3,s1
    80003ea8:	fc040613          	addi	a2,s0,-64
    80003eac:	4581                	li	a1,0
    80003eae:	854a                	mv	a0,s2
    80003eb0:	00000097          	auipc	ra,0x0
    80003eb4:	b84080e7          	jalr	-1148(ra) # 80003a34 <readi>
    80003eb8:	47c1                	li	a5,16
    80003eba:	06f51163          	bne	a0,a5,80003f1c <dirlink+0xa2>
    if(de.inum == 0)
    80003ebe:	fc045783          	lhu	a5,-64(s0)
    80003ec2:	c791                	beqz	a5,80003ece <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ec4:	24c1                	addiw	s1,s1,16
    80003ec6:	04c92783          	lw	a5,76(s2)
    80003eca:	fcf4ede3          	bltu	s1,a5,80003ea4 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80003ece:	4639                	li	a2,14
    80003ed0:	85d2                	mv	a1,s4
    80003ed2:	fc240513          	addi	a0,s0,-62
    80003ed6:	ffffd097          	auipc	ra,0xffffd
    80003eda:	f52080e7          	jalr	-174(ra) # 80000e28 <strncpy>
  de.inum = inum;
    80003ede:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ee2:	4741                	li	a4,16
    80003ee4:	86a6                	mv	a3,s1
    80003ee6:	fc040613          	addi	a2,s0,-64
    80003eea:	4581                	li	a1,0
    80003eec:	854a                	mv	a0,s2
    80003eee:	00000097          	auipc	ra,0x0
    80003ef2:	c3e080e7          	jalr	-962(ra) # 80003b2c <writei>
    80003ef6:	1541                	addi	a0,a0,-16
    80003ef8:	00a03533          	snez	a0,a0
    80003efc:	40a00533          	neg	a0,a0
}
    80003f00:	70e2                	ld	ra,56(sp)
    80003f02:	7442                	ld	s0,48(sp)
    80003f04:	74a2                	ld	s1,40(sp)
    80003f06:	7902                	ld	s2,32(sp)
    80003f08:	69e2                	ld	s3,24(sp)
    80003f0a:	6a42                	ld	s4,16(sp)
    80003f0c:	6121                	addi	sp,sp,64
    80003f0e:	8082                	ret
    iput(ip);
    80003f10:	00000097          	auipc	ra,0x0
    80003f14:	a2a080e7          	jalr	-1494(ra) # 8000393a <iput>
    return -1;
    80003f18:	557d                	li	a0,-1
    80003f1a:	b7dd                	j	80003f00 <dirlink+0x86>
      panic("dirlink read");
    80003f1c:	00005517          	auipc	a0,0x5
    80003f20:	82c50513          	addi	a0,a0,-2004 # 80008748 <syscalls+0x220>
    80003f24:	ffffc097          	auipc	ra,0xffffc
    80003f28:	61c080e7          	jalr	1564(ra) # 80000540 <panic>

0000000080003f2c <namei>:

struct inode*
namei(char *path)
{
    80003f2c:	1101                	addi	sp,sp,-32
    80003f2e:	ec06                	sd	ra,24(sp)
    80003f30:	e822                	sd	s0,16(sp)
    80003f32:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80003f34:	fe040613          	addi	a2,s0,-32
    80003f38:	4581                	li	a1,0
    80003f3a:	00000097          	auipc	ra,0x0
    80003f3e:	dda080e7          	jalr	-550(ra) # 80003d14 <namex>
}
    80003f42:	60e2                	ld	ra,24(sp)
    80003f44:	6442                	ld	s0,16(sp)
    80003f46:	6105                	addi	sp,sp,32
    80003f48:	8082                	ret

0000000080003f4a <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80003f4a:	1141                	addi	sp,sp,-16
    80003f4c:	e406                	sd	ra,8(sp)
    80003f4e:	e022                	sd	s0,0(sp)
    80003f50:	0800                	addi	s0,sp,16
    80003f52:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80003f54:	4585                	li	a1,1
    80003f56:	00000097          	auipc	ra,0x0
    80003f5a:	dbe080e7          	jalr	-578(ra) # 80003d14 <namex>
}
    80003f5e:	60a2                	ld	ra,8(sp)
    80003f60:	6402                	ld	s0,0(sp)
    80003f62:	0141                	addi	sp,sp,16
    80003f64:	8082                	ret

0000000080003f66 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80003f66:	1101                	addi	sp,sp,-32
    80003f68:	ec06                	sd	ra,24(sp)
    80003f6a:	e822                	sd	s0,16(sp)
    80003f6c:	e426                	sd	s1,8(sp)
    80003f6e:	e04a                	sd	s2,0(sp)
    80003f70:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80003f72:	0001d917          	auipc	s2,0x1d
    80003f76:	d9e90913          	addi	s2,s2,-610 # 80020d10 <log>
    80003f7a:	01892583          	lw	a1,24(s2)
    80003f7e:	02892503          	lw	a0,40(s2)
    80003f82:	fffff097          	auipc	ra,0xfffff
    80003f86:	fe6080e7          	jalr	-26(ra) # 80002f68 <bread>
    80003f8a:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80003f8c:	02c92683          	lw	a3,44(s2)
    80003f90:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80003f92:	02d05863          	blez	a3,80003fc2 <write_head+0x5c>
    80003f96:	0001d797          	auipc	a5,0x1d
    80003f9a:	daa78793          	addi	a5,a5,-598 # 80020d40 <log+0x30>
    80003f9e:	05c50713          	addi	a4,a0,92
    80003fa2:	36fd                	addiw	a3,a3,-1
    80003fa4:	02069613          	slli	a2,a3,0x20
    80003fa8:	01e65693          	srli	a3,a2,0x1e
    80003fac:	0001d617          	auipc	a2,0x1d
    80003fb0:	d9860613          	addi	a2,a2,-616 # 80020d44 <log+0x34>
    80003fb4:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80003fb6:	4390                	lw	a2,0(a5)
    80003fb8:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80003fba:	0791                	addi	a5,a5,4
    80003fbc:	0711                	addi	a4,a4,4 # 43004 <_entry-0x7ffbcffc>
    80003fbe:	fed79ce3          	bne	a5,a3,80003fb6 <write_head+0x50>
  }
  bwrite(buf);
    80003fc2:	8526                	mv	a0,s1
    80003fc4:	fffff097          	auipc	ra,0xfffff
    80003fc8:	096080e7          	jalr	150(ra) # 8000305a <bwrite>
  brelse(buf);
    80003fcc:	8526                	mv	a0,s1
    80003fce:	fffff097          	auipc	ra,0xfffff
    80003fd2:	0ca080e7          	jalr	202(ra) # 80003098 <brelse>
}
    80003fd6:	60e2                	ld	ra,24(sp)
    80003fd8:	6442                	ld	s0,16(sp)
    80003fda:	64a2                	ld	s1,8(sp)
    80003fdc:	6902                	ld	s2,0(sp)
    80003fde:	6105                	addi	sp,sp,32
    80003fe0:	8082                	ret

0000000080003fe2 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80003fe2:	0001d797          	auipc	a5,0x1d
    80003fe6:	d5a7a783          	lw	a5,-678(a5) # 80020d3c <log+0x2c>
    80003fea:	0af05d63          	blez	a5,800040a4 <install_trans+0xc2>
{
    80003fee:	7139                	addi	sp,sp,-64
    80003ff0:	fc06                	sd	ra,56(sp)
    80003ff2:	f822                	sd	s0,48(sp)
    80003ff4:	f426                	sd	s1,40(sp)
    80003ff6:	f04a                	sd	s2,32(sp)
    80003ff8:	ec4e                	sd	s3,24(sp)
    80003ffa:	e852                	sd	s4,16(sp)
    80003ffc:	e456                	sd	s5,8(sp)
    80003ffe:	e05a                	sd	s6,0(sp)
    80004000:	0080                	addi	s0,sp,64
    80004002:	8b2a                	mv	s6,a0
    80004004:	0001da97          	auipc	s5,0x1d
    80004008:	d3ca8a93          	addi	s5,s5,-708 # 80020d40 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000400c:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000400e:	0001d997          	auipc	s3,0x1d
    80004012:	d0298993          	addi	s3,s3,-766 # 80020d10 <log>
    80004016:	a00d                	j	80004038 <install_trans+0x56>
    brelse(lbuf);
    80004018:	854a                	mv	a0,s2
    8000401a:	fffff097          	auipc	ra,0xfffff
    8000401e:	07e080e7          	jalr	126(ra) # 80003098 <brelse>
    brelse(dbuf);
    80004022:	8526                	mv	a0,s1
    80004024:	fffff097          	auipc	ra,0xfffff
    80004028:	074080e7          	jalr	116(ra) # 80003098 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000402c:	2a05                	addiw	s4,s4,1
    8000402e:	0a91                	addi	s5,s5,4
    80004030:	02c9a783          	lw	a5,44(s3)
    80004034:	04fa5e63          	bge	s4,a5,80004090 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004038:	0189a583          	lw	a1,24(s3)
    8000403c:	014585bb          	addw	a1,a1,s4
    80004040:	2585                	addiw	a1,a1,1
    80004042:	0289a503          	lw	a0,40(s3)
    80004046:	fffff097          	auipc	ra,0xfffff
    8000404a:	f22080e7          	jalr	-222(ra) # 80002f68 <bread>
    8000404e:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004050:	000aa583          	lw	a1,0(s5)
    80004054:	0289a503          	lw	a0,40(s3)
    80004058:	fffff097          	auipc	ra,0xfffff
    8000405c:	f10080e7          	jalr	-240(ra) # 80002f68 <bread>
    80004060:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004062:	40000613          	li	a2,1024
    80004066:	05890593          	addi	a1,s2,88
    8000406a:	05850513          	addi	a0,a0,88
    8000406e:	ffffd097          	auipc	ra,0xffffd
    80004072:	d0a080e7          	jalr	-758(ra) # 80000d78 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004076:	8526                	mv	a0,s1
    80004078:	fffff097          	auipc	ra,0xfffff
    8000407c:	fe2080e7          	jalr	-30(ra) # 8000305a <bwrite>
    if(recovering == 0)
    80004080:	f80b1ce3          	bnez	s6,80004018 <install_trans+0x36>
      bunpin(dbuf);
    80004084:	8526                	mv	a0,s1
    80004086:	fffff097          	auipc	ra,0xfffff
    8000408a:	0ec080e7          	jalr	236(ra) # 80003172 <bunpin>
    8000408e:	b769                	j	80004018 <install_trans+0x36>
}
    80004090:	70e2                	ld	ra,56(sp)
    80004092:	7442                	ld	s0,48(sp)
    80004094:	74a2                	ld	s1,40(sp)
    80004096:	7902                	ld	s2,32(sp)
    80004098:	69e2                	ld	s3,24(sp)
    8000409a:	6a42                	ld	s4,16(sp)
    8000409c:	6aa2                	ld	s5,8(sp)
    8000409e:	6b02                	ld	s6,0(sp)
    800040a0:	6121                	addi	sp,sp,64
    800040a2:	8082                	ret
    800040a4:	8082                	ret

00000000800040a6 <initlog>:
{
    800040a6:	7179                	addi	sp,sp,-48
    800040a8:	f406                	sd	ra,40(sp)
    800040aa:	f022                	sd	s0,32(sp)
    800040ac:	ec26                	sd	s1,24(sp)
    800040ae:	e84a                	sd	s2,16(sp)
    800040b0:	e44e                	sd	s3,8(sp)
    800040b2:	1800                	addi	s0,sp,48
    800040b4:	892a                	mv	s2,a0
    800040b6:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800040b8:	0001d497          	auipc	s1,0x1d
    800040bc:	c5848493          	addi	s1,s1,-936 # 80020d10 <log>
    800040c0:	00004597          	auipc	a1,0x4
    800040c4:	69858593          	addi	a1,a1,1688 # 80008758 <syscalls+0x230>
    800040c8:	8526                	mv	a0,s1
    800040ca:	ffffd097          	auipc	ra,0xffffd
    800040ce:	ac6080e7          	jalr	-1338(ra) # 80000b90 <initlock>
  log.start = sb->logstart;
    800040d2:	0149a583          	lw	a1,20(s3)
    800040d6:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    800040d8:	0109a783          	lw	a5,16(s3)
    800040dc:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    800040de:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    800040e2:	854a                	mv	a0,s2
    800040e4:	fffff097          	auipc	ra,0xfffff
    800040e8:	e84080e7          	jalr	-380(ra) # 80002f68 <bread>
  log.lh.n = lh->n;
    800040ec:	4d34                	lw	a3,88(a0)
    800040ee:	d4d4                	sw	a3,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    800040f0:	02d05663          	blez	a3,8000411c <initlog+0x76>
    800040f4:	05c50793          	addi	a5,a0,92
    800040f8:	0001d717          	auipc	a4,0x1d
    800040fc:	c4870713          	addi	a4,a4,-952 # 80020d40 <log+0x30>
    80004100:	36fd                	addiw	a3,a3,-1
    80004102:	02069613          	slli	a2,a3,0x20
    80004106:	01e65693          	srli	a3,a2,0x1e
    8000410a:	06050613          	addi	a2,a0,96
    8000410e:	96b2                	add	a3,a3,a2
    log.lh.block[i] = lh->block[i];
    80004110:	4390                	lw	a2,0(a5)
    80004112:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004114:	0791                	addi	a5,a5,4
    80004116:	0711                	addi	a4,a4,4
    80004118:	fed79ce3          	bne	a5,a3,80004110 <initlog+0x6a>
  brelse(buf);
    8000411c:	fffff097          	auipc	ra,0xfffff
    80004120:	f7c080e7          	jalr	-132(ra) # 80003098 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004124:	4505                	li	a0,1
    80004126:	00000097          	auipc	ra,0x0
    8000412a:	ebc080e7          	jalr	-324(ra) # 80003fe2 <install_trans>
  log.lh.n = 0;
    8000412e:	0001d797          	auipc	a5,0x1d
    80004132:	c007a723          	sw	zero,-1010(a5) # 80020d3c <log+0x2c>
  write_head(); // clear the log
    80004136:	00000097          	auipc	ra,0x0
    8000413a:	e30080e7          	jalr	-464(ra) # 80003f66 <write_head>
}
    8000413e:	70a2                	ld	ra,40(sp)
    80004140:	7402                	ld	s0,32(sp)
    80004142:	64e2                	ld	s1,24(sp)
    80004144:	6942                	ld	s2,16(sp)
    80004146:	69a2                	ld	s3,8(sp)
    80004148:	6145                	addi	sp,sp,48
    8000414a:	8082                	ret

000000008000414c <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    8000414c:	1101                	addi	sp,sp,-32
    8000414e:	ec06                	sd	ra,24(sp)
    80004150:	e822                	sd	s0,16(sp)
    80004152:	e426                	sd	s1,8(sp)
    80004154:	e04a                	sd	s2,0(sp)
    80004156:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004158:	0001d517          	auipc	a0,0x1d
    8000415c:	bb850513          	addi	a0,a0,-1096 # 80020d10 <log>
    80004160:	ffffd097          	auipc	ra,0xffffd
    80004164:	ac0080e7          	jalr	-1344(ra) # 80000c20 <acquire>
  while(1){
    if(log.committing){
    80004168:	0001d497          	auipc	s1,0x1d
    8000416c:	ba848493          	addi	s1,s1,-1112 # 80020d10 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004170:	4979                	li	s2,30
    80004172:	a039                	j	80004180 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004174:	85a6                	mv	a1,s1
    80004176:	8526                	mv	a0,s1
    80004178:	ffffe097          	auipc	ra,0xffffe
    8000417c:	f2a080e7          	jalr	-214(ra) # 800020a2 <sleep>
    if(log.committing){
    80004180:	50dc                	lw	a5,36(s1)
    80004182:	fbed                	bnez	a5,80004174 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004184:	5098                	lw	a4,32(s1)
    80004186:	2705                	addiw	a4,a4,1
    80004188:	0007069b          	sext.w	a3,a4
    8000418c:	0027179b          	slliw	a5,a4,0x2
    80004190:	9fb9                	addw	a5,a5,a4
    80004192:	0017979b          	slliw	a5,a5,0x1
    80004196:	54d8                	lw	a4,44(s1)
    80004198:	9fb9                	addw	a5,a5,a4
    8000419a:	00f95963          	bge	s2,a5,800041ac <begin_op+0x60>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    8000419e:	85a6                	mv	a1,s1
    800041a0:	8526                	mv	a0,s1
    800041a2:	ffffe097          	auipc	ra,0xffffe
    800041a6:	f00080e7          	jalr	-256(ra) # 800020a2 <sleep>
    800041aa:	bfd9                	j	80004180 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800041ac:	0001d517          	auipc	a0,0x1d
    800041b0:	b6450513          	addi	a0,a0,-1180 # 80020d10 <log>
    800041b4:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800041b6:	ffffd097          	auipc	ra,0xffffd
    800041ba:	b1e080e7          	jalr	-1250(ra) # 80000cd4 <release>
      break;
    }
  }
}
    800041be:	60e2                	ld	ra,24(sp)
    800041c0:	6442                	ld	s0,16(sp)
    800041c2:	64a2                	ld	s1,8(sp)
    800041c4:	6902                	ld	s2,0(sp)
    800041c6:	6105                	addi	sp,sp,32
    800041c8:	8082                	ret

00000000800041ca <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800041ca:	7139                	addi	sp,sp,-64
    800041cc:	fc06                	sd	ra,56(sp)
    800041ce:	f822                	sd	s0,48(sp)
    800041d0:	f426                	sd	s1,40(sp)
    800041d2:	f04a                	sd	s2,32(sp)
    800041d4:	ec4e                	sd	s3,24(sp)
    800041d6:	e852                	sd	s4,16(sp)
    800041d8:	e456                	sd	s5,8(sp)
    800041da:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    800041dc:	0001d497          	auipc	s1,0x1d
    800041e0:	b3448493          	addi	s1,s1,-1228 # 80020d10 <log>
    800041e4:	8526                	mv	a0,s1
    800041e6:	ffffd097          	auipc	ra,0xffffd
    800041ea:	a3a080e7          	jalr	-1478(ra) # 80000c20 <acquire>
  log.outstanding -= 1;
    800041ee:	509c                	lw	a5,32(s1)
    800041f0:	37fd                	addiw	a5,a5,-1
    800041f2:	0007891b          	sext.w	s2,a5
    800041f6:	d09c                	sw	a5,32(s1)
  if(log.committing)
    800041f8:	50dc                	lw	a5,36(s1)
    800041fa:	e7b9                	bnez	a5,80004248 <end_op+0x7e>
    panic("log.committing");
  if(log.outstanding == 0){
    800041fc:	04091e63          	bnez	s2,80004258 <end_op+0x8e>
    do_commit = 1;
    log.committing = 1;
    80004200:	0001d497          	auipc	s1,0x1d
    80004204:	b1048493          	addi	s1,s1,-1264 # 80020d10 <log>
    80004208:	4785                	li	a5,1
    8000420a:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000420c:	8526                	mv	a0,s1
    8000420e:	ffffd097          	auipc	ra,0xffffd
    80004212:	ac6080e7          	jalr	-1338(ra) # 80000cd4 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004216:	54dc                	lw	a5,44(s1)
    80004218:	06f04763          	bgtz	a5,80004286 <end_op+0xbc>
    acquire(&log.lock);
    8000421c:	0001d497          	auipc	s1,0x1d
    80004220:	af448493          	addi	s1,s1,-1292 # 80020d10 <log>
    80004224:	8526                	mv	a0,s1
    80004226:	ffffd097          	auipc	ra,0xffffd
    8000422a:	9fa080e7          	jalr	-1542(ra) # 80000c20 <acquire>
    log.committing = 0;
    8000422e:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004232:	8526                	mv	a0,s1
    80004234:	ffffe097          	auipc	ra,0xffffe
    80004238:	ed2080e7          	jalr	-302(ra) # 80002106 <wakeup>
    release(&log.lock);
    8000423c:	8526                	mv	a0,s1
    8000423e:	ffffd097          	auipc	ra,0xffffd
    80004242:	a96080e7          	jalr	-1386(ra) # 80000cd4 <release>
}
    80004246:	a03d                	j	80004274 <end_op+0xaa>
    panic("log.committing");
    80004248:	00004517          	auipc	a0,0x4
    8000424c:	51850513          	addi	a0,a0,1304 # 80008760 <syscalls+0x238>
    80004250:	ffffc097          	auipc	ra,0xffffc
    80004254:	2f0080e7          	jalr	752(ra) # 80000540 <panic>
    wakeup(&log);
    80004258:	0001d497          	auipc	s1,0x1d
    8000425c:	ab848493          	addi	s1,s1,-1352 # 80020d10 <log>
    80004260:	8526                	mv	a0,s1
    80004262:	ffffe097          	auipc	ra,0xffffe
    80004266:	ea4080e7          	jalr	-348(ra) # 80002106 <wakeup>
  release(&log.lock);
    8000426a:	8526                	mv	a0,s1
    8000426c:	ffffd097          	auipc	ra,0xffffd
    80004270:	a68080e7          	jalr	-1432(ra) # 80000cd4 <release>
}
    80004274:	70e2                	ld	ra,56(sp)
    80004276:	7442                	ld	s0,48(sp)
    80004278:	74a2                	ld	s1,40(sp)
    8000427a:	7902                	ld	s2,32(sp)
    8000427c:	69e2                	ld	s3,24(sp)
    8000427e:	6a42                	ld	s4,16(sp)
    80004280:	6aa2                	ld	s5,8(sp)
    80004282:	6121                	addi	sp,sp,64
    80004284:	8082                	ret
  for (tail = 0; tail < log.lh.n; tail++) {
    80004286:	0001da97          	auipc	s5,0x1d
    8000428a:	abaa8a93          	addi	s5,s5,-1350 # 80020d40 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    8000428e:	0001da17          	auipc	s4,0x1d
    80004292:	a82a0a13          	addi	s4,s4,-1406 # 80020d10 <log>
    80004296:	018a2583          	lw	a1,24(s4)
    8000429a:	012585bb          	addw	a1,a1,s2
    8000429e:	2585                	addiw	a1,a1,1
    800042a0:	028a2503          	lw	a0,40(s4)
    800042a4:	fffff097          	auipc	ra,0xfffff
    800042a8:	cc4080e7          	jalr	-828(ra) # 80002f68 <bread>
    800042ac:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800042ae:	000aa583          	lw	a1,0(s5)
    800042b2:	028a2503          	lw	a0,40(s4)
    800042b6:	fffff097          	auipc	ra,0xfffff
    800042ba:	cb2080e7          	jalr	-846(ra) # 80002f68 <bread>
    800042be:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800042c0:	40000613          	li	a2,1024
    800042c4:	05850593          	addi	a1,a0,88
    800042c8:	05848513          	addi	a0,s1,88
    800042cc:	ffffd097          	auipc	ra,0xffffd
    800042d0:	aac080e7          	jalr	-1364(ra) # 80000d78 <memmove>
    bwrite(to);  // write the log
    800042d4:	8526                	mv	a0,s1
    800042d6:	fffff097          	auipc	ra,0xfffff
    800042da:	d84080e7          	jalr	-636(ra) # 8000305a <bwrite>
    brelse(from);
    800042de:	854e                	mv	a0,s3
    800042e0:	fffff097          	auipc	ra,0xfffff
    800042e4:	db8080e7          	jalr	-584(ra) # 80003098 <brelse>
    brelse(to);
    800042e8:	8526                	mv	a0,s1
    800042ea:	fffff097          	auipc	ra,0xfffff
    800042ee:	dae080e7          	jalr	-594(ra) # 80003098 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    800042f2:	2905                	addiw	s2,s2,1
    800042f4:	0a91                	addi	s5,s5,4
    800042f6:	02ca2783          	lw	a5,44(s4)
    800042fa:	f8f94ee3          	blt	s2,a5,80004296 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    800042fe:	00000097          	auipc	ra,0x0
    80004302:	c68080e7          	jalr	-920(ra) # 80003f66 <write_head>
    install_trans(0); // Now install writes to home locations
    80004306:	4501                	li	a0,0
    80004308:	00000097          	auipc	ra,0x0
    8000430c:	cda080e7          	jalr	-806(ra) # 80003fe2 <install_trans>
    log.lh.n = 0;
    80004310:	0001d797          	auipc	a5,0x1d
    80004314:	a207a623          	sw	zero,-1492(a5) # 80020d3c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004318:	00000097          	auipc	ra,0x0
    8000431c:	c4e080e7          	jalr	-946(ra) # 80003f66 <write_head>
    80004320:	bdf5                	j	8000421c <end_op+0x52>

0000000080004322 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004322:	1101                	addi	sp,sp,-32
    80004324:	ec06                	sd	ra,24(sp)
    80004326:	e822                	sd	s0,16(sp)
    80004328:	e426                	sd	s1,8(sp)
    8000432a:	e04a                	sd	s2,0(sp)
    8000432c:	1000                	addi	s0,sp,32
    8000432e:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004330:	0001d917          	auipc	s2,0x1d
    80004334:	9e090913          	addi	s2,s2,-1568 # 80020d10 <log>
    80004338:	854a                	mv	a0,s2
    8000433a:	ffffd097          	auipc	ra,0xffffd
    8000433e:	8e6080e7          	jalr	-1818(ra) # 80000c20 <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004342:	02c92603          	lw	a2,44(s2)
    80004346:	47f5                	li	a5,29
    80004348:	06c7c563          	blt	a5,a2,800043b2 <log_write+0x90>
    8000434c:	0001d797          	auipc	a5,0x1d
    80004350:	9e07a783          	lw	a5,-1568(a5) # 80020d2c <log+0x1c>
    80004354:	37fd                	addiw	a5,a5,-1
    80004356:	04f65e63          	bge	a2,a5,800043b2 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    8000435a:	0001d797          	auipc	a5,0x1d
    8000435e:	9d67a783          	lw	a5,-1578(a5) # 80020d30 <log+0x20>
    80004362:	06f05063          	blez	a5,800043c2 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004366:	4781                	li	a5,0
    80004368:	06c05563          	blez	a2,800043d2 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000436c:	44cc                	lw	a1,12(s1)
    8000436e:	0001d717          	auipc	a4,0x1d
    80004372:	9d270713          	addi	a4,a4,-1582 # 80020d40 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004376:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004378:	4314                	lw	a3,0(a4)
    8000437a:	04b68c63          	beq	a3,a1,800043d2 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    8000437e:	2785                	addiw	a5,a5,1
    80004380:	0711                	addi	a4,a4,4
    80004382:	fef61be3          	bne	a2,a5,80004378 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004386:	0621                	addi	a2,a2,8
    80004388:	060a                	slli	a2,a2,0x2
    8000438a:	0001d797          	auipc	a5,0x1d
    8000438e:	98678793          	addi	a5,a5,-1658 # 80020d10 <log>
    80004392:	97b2                	add	a5,a5,a2
    80004394:	44d8                	lw	a4,12(s1)
    80004396:	cb98                	sw	a4,16(a5)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004398:	8526                	mv	a0,s1
    8000439a:	fffff097          	auipc	ra,0xfffff
    8000439e:	d9c080e7          	jalr	-612(ra) # 80003136 <bpin>
    log.lh.n++;
    800043a2:	0001d717          	auipc	a4,0x1d
    800043a6:	96e70713          	addi	a4,a4,-1682 # 80020d10 <log>
    800043aa:	575c                	lw	a5,44(a4)
    800043ac:	2785                	addiw	a5,a5,1
    800043ae:	d75c                	sw	a5,44(a4)
    800043b0:	a82d                	j	800043ea <log_write+0xc8>
    panic("too big a transaction");
    800043b2:	00004517          	auipc	a0,0x4
    800043b6:	3be50513          	addi	a0,a0,958 # 80008770 <syscalls+0x248>
    800043ba:	ffffc097          	auipc	ra,0xffffc
    800043be:	186080e7          	jalr	390(ra) # 80000540 <panic>
    panic("log_write outside of trans");
    800043c2:	00004517          	auipc	a0,0x4
    800043c6:	3c650513          	addi	a0,a0,966 # 80008788 <syscalls+0x260>
    800043ca:	ffffc097          	auipc	ra,0xffffc
    800043ce:	176080e7          	jalr	374(ra) # 80000540 <panic>
  log.lh.block[i] = b->blockno;
    800043d2:	00878693          	addi	a3,a5,8
    800043d6:	068a                	slli	a3,a3,0x2
    800043d8:	0001d717          	auipc	a4,0x1d
    800043dc:	93870713          	addi	a4,a4,-1736 # 80020d10 <log>
    800043e0:	9736                	add	a4,a4,a3
    800043e2:	44d4                	lw	a3,12(s1)
    800043e4:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    800043e6:	faf609e3          	beq	a2,a5,80004398 <log_write+0x76>
  }
  release(&log.lock);
    800043ea:	0001d517          	auipc	a0,0x1d
    800043ee:	92650513          	addi	a0,a0,-1754 # 80020d10 <log>
    800043f2:	ffffd097          	auipc	ra,0xffffd
    800043f6:	8e2080e7          	jalr	-1822(ra) # 80000cd4 <release>
}
    800043fa:	60e2                	ld	ra,24(sp)
    800043fc:	6442                	ld	s0,16(sp)
    800043fe:	64a2                	ld	s1,8(sp)
    80004400:	6902                	ld	s2,0(sp)
    80004402:	6105                	addi	sp,sp,32
    80004404:	8082                	ret

0000000080004406 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004406:	1101                	addi	sp,sp,-32
    80004408:	ec06                	sd	ra,24(sp)
    8000440a:	e822                	sd	s0,16(sp)
    8000440c:	e426                	sd	s1,8(sp)
    8000440e:	e04a                	sd	s2,0(sp)
    80004410:	1000                	addi	s0,sp,32
    80004412:	84aa                	mv	s1,a0
    80004414:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004416:	00004597          	auipc	a1,0x4
    8000441a:	39258593          	addi	a1,a1,914 # 800087a8 <syscalls+0x280>
    8000441e:	0521                	addi	a0,a0,8
    80004420:	ffffc097          	auipc	ra,0xffffc
    80004424:	770080e7          	jalr	1904(ra) # 80000b90 <initlock>
  lk->name = name;
    80004428:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000442c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004430:	0204a423          	sw	zero,40(s1)
}
    80004434:	60e2                	ld	ra,24(sp)
    80004436:	6442                	ld	s0,16(sp)
    80004438:	64a2                	ld	s1,8(sp)
    8000443a:	6902                	ld	s2,0(sp)
    8000443c:	6105                	addi	sp,sp,32
    8000443e:	8082                	ret

0000000080004440 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004440:	1101                	addi	sp,sp,-32
    80004442:	ec06                	sd	ra,24(sp)
    80004444:	e822                	sd	s0,16(sp)
    80004446:	e426                	sd	s1,8(sp)
    80004448:	e04a                	sd	s2,0(sp)
    8000444a:	1000                	addi	s0,sp,32
    8000444c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000444e:	00850913          	addi	s2,a0,8
    80004452:	854a                	mv	a0,s2
    80004454:	ffffc097          	auipc	ra,0xffffc
    80004458:	7cc080e7          	jalr	1996(ra) # 80000c20 <acquire>
  while (lk->locked) {
    8000445c:	409c                	lw	a5,0(s1)
    8000445e:	cb89                	beqz	a5,80004470 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004460:	85ca                	mv	a1,s2
    80004462:	8526                	mv	a0,s1
    80004464:	ffffe097          	auipc	ra,0xffffe
    80004468:	c3e080e7          	jalr	-962(ra) # 800020a2 <sleep>
  while (lk->locked) {
    8000446c:	409c                	lw	a5,0(s1)
    8000446e:	fbed                	bnez	a5,80004460 <acquiresleep+0x20>
  }
  lk->locked = 1;
    80004470:	4785                	li	a5,1
    80004472:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    80004474:	ffffd097          	auipc	ra,0xffffd
    80004478:	582080e7          	jalr	1410(ra) # 800019f6 <myproc>
    8000447c:	591c                	lw	a5,48(a0)
    8000447e:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    80004480:	854a                	mv	a0,s2
    80004482:	ffffd097          	auipc	ra,0xffffd
    80004486:	852080e7          	jalr	-1966(ra) # 80000cd4 <release>
}
    8000448a:	60e2                	ld	ra,24(sp)
    8000448c:	6442                	ld	s0,16(sp)
    8000448e:	64a2                	ld	s1,8(sp)
    80004490:	6902                	ld	s2,0(sp)
    80004492:	6105                	addi	sp,sp,32
    80004494:	8082                	ret

0000000080004496 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80004496:	1101                	addi	sp,sp,-32
    80004498:	ec06                	sd	ra,24(sp)
    8000449a:	e822                	sd	s0,16(sp)
    8000449c:	e426                	sd	s1,8(sp)
    8000449e:	e04a                	sd	s2,0(sp)
    800044a0:	1000                	addi	s0,sp,32
    800044a2:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800044a4:	00850913          	addi	s2,a0,8
    800044a8:	854a                	mv	a0,s2
    800044aa:	ffffc097          	auipc	ra,0xffffc
    800044ae:	776080e7          	jalr	1910(ra) # 80000c20 <acquire>
  lk->locked = 0;
    800044b2:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800044b6:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800044ba:	8526                	mv	a0,s1
    800044bc:	ffffe097          	auipc	ra,0xffffe
    800044c0:	c4a080e7          	jalr	-950(ra) # 80002106 <wakeup>
  release(&lk->lk);
    800044c4:	854a                	mv	a0,s2
    800044c6:	ffffd097          	auipc	ra,0xffffd
    800044ca:	80e080e7          	jalr	-2034(ra) # 80000cd4 <release>
}
    800044ce:	60e2                	ld	ra,24(sp)
    800044d0:	6442                	ld	s0,16(sp)
    800044d2:	64a2                	ld	s1,8(sp)
    800044d4:	6902                	ld	s2,0(sp)
    800044d6:	6105                	addi	sp,sp,32
    800044d8:	8082                	ret

00000000800044da <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    800044da:	7179                	addi	sp,sp,-48
    800044dc:	f406                	sd	ra,40(sp)
    800044de:	f022                	sd	s0,32(sp)
    800044e0:	ec26                	sd	s1,24(sp)
    800044e2:	e84a                	sd	s2,16(sp)
    800044e4:	e44e                	sd	s3,8(sp)
    800044e6:	1800                	addi	s0,sp,48
    800044e8:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    800044ea:	00850913          	addi	s2,a0,8
    800044ee:	854a                	mv	a0,s2
    800044f0:	ffffc097          	auipc	ra,0xffffc
    800044f4:	730080e7          	jalr	1840(ra) # 80000c20 <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800044f8:	409c                	lw	a5,0(s1)
    800044fa:	ef99                	bnez	a5,80004518 <holdingsleep+0x3e>
    800044fc:	4481                	li	s1,0
  release(&lk->lk);
    800044fe:	854a                	mv	a0,s2
    80004500:	ffffc097          	auipc	ra,0xffffc
    80004504:	7d4080e7          	jalr	2004(ra) # 80000cd4 <release>
  return r;
}
    80004508:	8526                	mv	a0,s1
    8000450a:	70a2                	ld	ra,40(sp)
    8000450c:	7402                	ld	s0,32(sp)
    8000450e:	64e2                	ld	s1,24(sp)
    80004510:	6942                	ld	s2,16(sp)
    80004512:	69a2                	ld	s3,8(sp)
    80004514:	6145                	addi	sp,sp,48
    80004516:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004518:	0284a983          	lw	s3,40(s1)
    8000451c:	ffffd097          	auipc	ra,0xffffd
    80004520:	4da080e7          	jalr	1242(ra) # 800019f6 <myproc>
    80004524:	5904                	lw	s1,48(a0)
    80004526:	413484b3          	sub	s1,s1,s3
    8000452a:	0014b493          	seqz	s1,s1
    8000452e:	bfc1                	j	800044fe <holdingsleep+0x24>

0000000080004530 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004530:	1141                	addi	sp,sp,-16
    80004532:	e406                	sd	ra,8(sp)
    80004534:	e022                	sd	s0,0(sp)
    80004536:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004538:	00004597          	auipc	a1,0x4
    8000453c:	28058593          	addi	a1,a1,640 # 800087b8 <syscalls+0x290>
    80004540:	0001d517          	auipc	a0,0x1d
    80004544:	91850513          	addi	a0,a0,-1768 # 80020e58 <ftable>
    80004548:	ffffc097          	auipc	ra,0xffffc
    8000454c:	648080e7          	jalr	1608(ra) # 80000b90 <initlock>
}
    80004550:	60a2                	ld	ra,8(sp)
    80004552:	6402                	ld	s0,0(sp)
    80004554:	0141                	addi	sp,sp,16
    80004556:	8082                	ret

0000000080004558 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004558:	1101                	addi	sp,sp,-32
    8000455a:	ec06                	sd	ra,24(sp)
    8000455c:	e822                	sd	s0,16(sp)
    8000455e:	e426                	sd	s1,8(sp)
    80004560:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004562:	0001d517          	auipc	a0,0x1d
    80004566:	8f650513          	addi	a0,a0,-1802 # 80020e58 <ftable>
    8000456a:	ffffc097          	auipc	ra,0xffffc
    8000456e:	6b6080e7          	jalr	1718(ra) # 80000c20 <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004572:	0001d497          	auipc	s1,0x1d
    80004576:	8fe48493          	addi	s1,s1,-1794 # 80020e70 <ftable+0x18>
    8000457a:	0001e717          	auipc	a4,0x1e
    8000457e:	89670713          	addi	a4,a4,-1898 # 80021e10 <disk>
    if(f->ref == 0){
    80004582:	40dc                	lw	a5,4(s1)
    80004584:	cf99                	beqz	a5,800045a2 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80004586:	02848493          	addi	s1,s1,40
    8000458a:	fee49ce3          	bne	s1,a4,80004582 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    8000458e:	0001d517          	auipc	a0,0x1d
    80004592:	8ca50513          	addi	a0,a0,-1846 # 80020e58 <ftable>
    80004596:	ffffc097          	auipc	ra,0xffffc
    8000459a:	73e080e7          	jalr	1854(ra) # 80000cd4 <release>
  return 0;
    8000459e:	4481                	li	s1,0
    800045a0:	a819                	j	800045b6 <filealloc+0x5e>
      f->ref = 1;
    800045a2:	4785                	li	a5,1
    800045a4:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800045a6:	0001d517          	auipc	a0,0x1d
    800045aa:	8b250513          	addi	a0,a0,-1870 # 80020e58 <ftable>
    800045ae:	ffffc097          	auipc	ra,0xffffc
    800045b2:	726080e7          	jalr	1830(ra) # 80000cd4 <release>
}
    800045b6:	8526                	mv	a0,s1
    800045b8:	60e2                	ld	ra,24(sp)
    800045ba:	6442                	ld	s0,16(sp)
    800045bc:	64a2                	ld	s1,8(sp)
    800045be:	6105                	addi	sp,sp,32
    800045c0:	8082                	ret

00000000800045c2 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800045c2:	1101                	addi	sp,sp,-32
    800045c4:	ec06                	sd	ra,24(sp)
    800045c6:	e822                	sd	s0,16(sp)
    800045c8:	e426                	sd	s1,8(sp)
    800045ca:	1000                	addi	s0,sp,32
    800045cc:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800045ce:	0001d517          	auipc	a0,0x1d
    800045d2:	88a50513          	addi	a0,a0,-1910 # 80020e58 <ftable>
    800045d6:	ffffc097          	auipc	ra,0xffffc
    800045da:	64a080e7          	jalr	1610(ra) # 80000c20 <acquire>
  if(f->ref < 1)
    800045de:	40dc                	lw	a5,4(s1)
    800045e0:	02f05263          	blez	a5,80004604 <filedup+0x42>
    panic("filedup");
  f->ref++;
    800045e4:	2785                	addiw	a5,a5,1
    800045e6:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    800045e8:	0001d517          	auipc	a0,0x1d
    800045ec:	87050513          	addi	a0,a0,-1936 # 80020e58 <ftable>
    800045f0:	ffffc097          	auipc	ra,0xffffc
    800045f4:	6e4080e7          	jalr	1764(ra) # 80000cd4 <release>
  return f;
}
    800045f8:	8526                	mv	a0,s1
    800045fa:	60e2                	ld	ra,24(sp)
    800045fc:	6442                	ld	s0,16(sp)
    800045fe:	64a2                	ld	s1,8(sp)
    80004600:	6105                	addi	sp,sp,32
    80004602:	8082                	ret
    panic("filedup");
    80004604:	00004517          	auipc	a0,0x4
    80004608:	1bc50513          	addi	a0,a0,444 # 800087c0 <syscalls+0x298>
    8000460c:	ffffc097          	auipc	ra,0xffffc
    80004610:	f34080e7          	jalr	-204(ra) # 80000540 <panic>

0000000080004614 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004614:	7139                	addi	sp,sp,-64
    80004616:	fc06                	sd	ra,56(sp)
    80004618:	f822                	sd	s0,48(sp)
    8000461a:	f426                	sd	s1,40(sp)
    8000461c:	f04a                	sd	s2,32(sp)
    8000461e:	ec4e                	sd	s3,24(sp)
    80004620:	e852                	sd	s4,16(sp)
    80004622:	e456                	sd	s5,8(sp)
    80004624:	0080                	addi	s0,sp,64
    80004626:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004628:	0001d517          	auipc	a0,0x1d
    8000462c:	83050513          	addi	a0,a0,-2000 # 80020e58 <ftable>
    80004630:	ffffc097          	auipc	ra,0xffffc
    80004634:	5f0080e7          	jalr	1520(ra) # 80000c20 <acquire>
  if(f->ref < 1)
    80004638:	40dc                	lw	a5,4(s1)
    8000463a:	06f05163          	blez	a5,8000469c <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000463e:	37fd                	addiw	a5,a5,-1
    80004640:	0007871b          	sext.w	a4,a5
    80004644:	c0dc                	sw	a5,4(s1)
    80004646:	06e04363          	bgtz	a4,800046ac <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000464a:	0004a903          	lw	s2,0(s1)
    8000464e:	0094ca83          	lbu	s5,9(s1)
    80004652:	0104ba03          	ld	s4,16(s1)
    80004656:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000465a:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000465e:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004662:	0001c517          	auipc	a0,0x1c
    80004666:	7f650513          	addi	a0,a0,2038 # 80020e58 <ftable>
    8000466a:	ffffc097          	auipc	ra,0xffffc
    8000466e:	66a080e7          	jalr	1642(ra) # 80000cd4 <release>

  if(ff.type == FD_PIPE){
    80004672:	4785                	li	a5,1
    80004674:	04f90d63          	beq	s2,a5,800046ce <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80004678:	3979                	addiw	s2,s2,-2
    8000467a:	4785                	li	a5,1
    8000467c:	0527e063          	bltu	a5,s2,800046bc <fileclose+0xa8>
    begin_op();
    80004680:	00000097          	auipc	ra,0x0
    80004684:	acc080e7          	jalr	-1332(ra) # 8000414c <begin_op>
    iput(ff.ip);
    80004688:	854e                	mv	a0,s3
    8000468a:	fffff097          	auipc	ra,0xfffff
    8000468e:	2b0080e7          	jalr	688(ra) # 8000393a <iput>
    end_op();
    80004692:	00000097          	auipc	ra,0x0
    80004696:	b38080e7          	jalr	-1224(ra) # 800041ca <end_op>
    8000469a:	a00d                	j	800046bc <fileclose+0xa8>
    panic("fileclose");
    8000469c:	00004517          	auipc	a0,0x4
    800046a0:	12c50513          	addi	a0,a0,300 # 800087c8 <syscalls+0x2a0>
    800046a4:	ffffc097          	auipc	ra,0xffffc
    800046a8:	e9c080e7          	jalr	-356(ra) # 80000540 <panic>
    release(&ftable.lock);
    800046ac:	0001c517          	auipc	a0,0x1c
    800046b0:	7ac50513          	addi	a0,a0,1964 # 80020e58 <ftable>
    800046b4:	ffffc097          	auipc	ra,0xffffc
    800046b8:	620080e7          	jalr	1568(ra) # 80000cd4 <release>
  }
}
    800046bc:	70e2                	ld	ra,56(sp)
    800046be:	7442                	ld	s0,48(sp)
    800046c0:	74a2                	ld	s1,40(sp)
    800046c2:	7902                	ld	s2,32(sp)
    800046c4:	69e2                	ld	s3,24(sp)
    800046c6:	6a42                	ld	s4,16(sp)
    800046c8:	6aa2                	ld	s5,8(sp)
    800046ca:	6121                	addi	sp,sp,64
    800046cc:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800046ce:	85d6                	mv	a1,s5
    800046d0:	8552                	mv	a0,s4
    800046d2:	00000097          	auipc	ra,0x0
    800046d6:	34c080e7          	jalr	844(ra) # 80004a1e <pipeclose>
    800046da:	b7cd                	j	800046bc <fileclose+0xa8>

00000000800046dc <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    800046dc:	715d                	addi	sp,sp,-80
    800046de:	e486                	sd	ra,72(sp)
    800046e0:	e0a2                	sd	s0,64(sp)
    800046e2:	fc26                	sd	s1,56(sp)
    800046e4:	f84a                	sd	s2,48(sp)
    800046e6:	f44e                	sd	s3,40(sp)
    800046e8:	0880                	addi	s0,sp,80
    800046ea:	84aa                	mv	s1,a0
    800046ec:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    800046ee:	ffffd097          	auipc	ra,0xffffd
    800046f2:	308080e7          	jalr	776(ra) # 800019f6 <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800046f6:	409c                	lw	a5,0(s1)
    800046f8:	37f9                	addiw	a5,a5,-2
    800046fa:	4705                	li	a4,1
    800046fc:	04f76763          	bltu	a4,a5,8000474a <filestat+0x6e>
    80004700:	892a                	mv	s2,a0
    ilock(f->ip);
    80004702:	6c88                	ld	a0,24(s1)
    80004704:	fffff097          	auipc	ra,0xfffff
    80004708:	07c080e7          	jalr	124(ra) # 80003780 <ilock>
    stati(f->ip, &st);
    8000470c:	fb840593          	addi	a1,s0,-72
    80004710:	6c88                	ld	a0,24(s1)
    80004712:	fffff097          	auipc	ra,0xfffff
    80004716:	2f8080e7          	jalr	760(ra) # 80003a0a <stati>
    iunlock(f->ip);
    8000471a:	6c88                	ld	a0,24(s1)
    8000471c:	fffff097          	auipc	ra,0xfffff
    80004720:	126080e7          	jalr	294(ra) # 80003842 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004724:	46e1                	li	a3,24
    80004726:	fb840613          	addi	a2,s0,-72
    8000472a:	85ce                	mv	a1,s3
    8000472c:	05093503          	ld	a0,80(s2)
    80004730:	ffffd097          	auipc	ra,0xffffd
    80004734:	f86080e7          	jalr	-122(ra) # 800016b6 <copyout>
    80004738:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000473c:	60a6                	ld	ra,72(sp)
    8000473e:	6406                	ld	s0,64(sp)
    80004740:	74e2                	ld	s1,56(sp)
    80004742:	7942                	ld	s2,48(sp)
    80004744:	79a2                	ld	s3,40(sp)
    80004746:	6161                	addi	sp,sp,80
    80004748:	8082                	ret
  return -1;
    8000474a:	557d                	li	a0,-1
    8000474c:	bfc5                	j	8000473c <filestat+0x60>

000000008000474e <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000474e:	7179                	addi	sp,sp,-48
    80004750:	f406                	sd	ra,40(sp)
    80004752:	f022                	sd	s0,32(sp)
    80004754:	ec26                	sd	s1,24(sp)
    80004756:	e84a                	sd	s2,16(sp)
    80004758:	e44e                	sd	s3,8(sp)
    8000475a:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000475c:	00854783          	lbu	a5,8(a0)
    80004760:	c3d5                	beqz	a5,80004804 <fileread+0xb6>
    80004762:	84aa                	mv	s1,a0
    80004764:	89ae                	mv	s3,a1
    80004766:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004768:	411c                	lw	a5,0(a0)
    8000476a:	4705                	li	a4,1
    8000476c:	04e78963          	beq	a5,a4,800047be <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004770:	470d                	li	a4,3
    80004772:	04e78d63          	beq	a5,a4,800047cc <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80004776:	4709                	li	a4,2
    80004778:	06e79e63          	bne	a5,a4,800047f4 <fileread+0xa6>
    ilock(f->ip);
    8000477c:	6d08                	ld	a0,24(a0)
    8000477e:	fffff097          	auipc	ra,0xfffff
    80004782:	002080e7          	jalr	2(ra) # 80003780 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80004786:	874a                	mv	a4,s2
    80004788:	5094                	lw	a3,32(s1)
    8000478a:	864e                	mv	a2,s3
    8000478c:	4585                	li	a1,1
    8000478e:	6c88                	ld	a0,24(s1)
    80004790:	fffff097          	auipc	ra,0xfffff
    80004794:	2a4080e7          	jalr	676(ra) # 80003a34 <readi>
    80004798:	892a                	mv	s2,a0
    8000479a:	00a05563          	blez	a0,800047a4 <fileread+0x56>
      f->off += r;
    8000479e:	509c                	lw	a5,32(s1)
    800047a0:	9fa9                	addw	a5,a5,a0
    800047a2:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800047a4:	6c88                	ld	a0,24(s1)
    800047a6:	fffff097          	auipc	ra,0xfffff
    800047aa:	09c080e7          	jalr	156(ra) # 80003842 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800047ae:	854a                	mv	a0,s2
    800047b0:	70a2                	ld	ra,40(sp)
    800047b2:	7402                	ld	s0,32(sp)
    800047b4:	64e2                	ld	s1,24(sp)
    800047b6:	6942                	ld	s2,16(sp)
    800047b8:	69a2                	ld	s3,8(sp)
    800047ba:	6145                	addi	sp,sp,48
    800047bc:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800047be:	6908                	ld	a0,16(a0)
    800047c0:	00000097          	auipc	ra,0x0
    800047c4:	3c6080e7          	jalr	966(ra) # 80004b86 <piperead>
    800047c8:	892a                	mv	s2,a0
    800047ca:	b7d5                	j	800047ae <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800047cc:	02451783          	lh	a5,36(a0)
    800047d0:	03079693          	slli	a3,a5,0x30
    800047d4:	92c1                	srli	a3,a3,0x30
    800047d6:	4725                	li	a4,9
    800047d8:	02d76863          	bltu	a4,a3,80004808 <fileread+0xba>
    800047dc:	0792                	slli	a5,a5,0x4
    800047de:	0001c717          	auipc	a4,0x1c
    800047e2:	5da70713          	addi	a4,a4,1498 # 80020db8 <devsw>
    800047e6:	97ba                	add	a5,a5,a4
    800047e8:	639c                	ld	a5,0(a5)
    800047ea:	c38d                	beqz	a5,8000480c <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    800047ec:	4505                	li	a0,1
    800047ee:	9782                	jalr	a5
    800047f0:	892a                	mv	s2,a0
    800047f2:	bf75                	j	800047ae <fileread+0x60>
    panic("fileread");
    800047f4:	00004517          	auipc	a0,0x4
    800047f8:	fe450513          	addi	a0,a0,-28 # 800087d8 <syscalls+0x2b0>
    800047fc:	ffffc097          	auipc	ra,0xffffc
    80004800:	d44080e7          	jalr	-700(ra) # 80000540 <panic>
    return -1;
    80004804:	597d                	li	s2,-1
    80004806:	b765                	j	800047ae <fileread+0x60>
      return -1;
    80004808:	597d                	li	s2,-1
    8000480a:	b755                	j	800047ae <fileread+0x60>
    8000480c:	597d                	li	s2,-1
    8000480e:	b745                	j	800047ae <fileread+0x60>

0000000080004810 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004810:	715d                	addi	sp,sp,-80
    80004812:	e486                	sd	ra,72(sp)
    80004814:	e0a2                	sd	s0,64(sp)
    80004816:	fc26                	sd	s1,56(sp)
    80004818:	f84a                	sd	s2,48(sp)
    8000481a:	f44e                	sd	s3,40(sp)
    8000481c:	f052                	sd	s4,32(sp)
    8000481e:	ec56                	sd	s5,24(sp)
    80004820:	e85a                	sd	s6,16(sp)
    80004822:	e45e                	sd	s7,8(sp)
    80004824:	e062                	sd	s8,0(sp)
    80004826:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004828:	00954783          	lbu	a5,9(a0)
    8000482c:	10078663          	beqz	a5,80004938 <filewrite+0x128>
    80004830:	892a                	mv	s2,a0
    80004832:	8b2e                	mv	s6,a1
    80004834:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004836:	411c                	lw	a5,0(a0)
    80004838:	4705                	li	a4,1
    8000483a:	02e78263          	beq	a5,a4,8000485e <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000483e:	470d                	li	a4,3
    80004840:	02e78663          	beq	a5,a4,8000486c <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004844:	4709                	li	a4,2
    80004846:	0ee79163          	bne	a5,a4,80004928 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    8000484a:	0ac05d63          	blez	a2,80004904 <filewrite+0xf4>
    int i = 0;
    8000484e:	4981                	li	s3,0
    80004850:	6b85                	lui	s7,0x1
    80004852:	c00b8b93          	addi	s7,s7,-1024 # c00 <_entry-0x7ffff400>
    80004856:	6c05                	lui	s8,0x1
    80004858:	c00c0c1b          	addiw	s8,s8,-1024 # c00 <_entry-0x7ffff400>
    8000485c:	a861                	j	800048f4 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    8000485e:	6908                	ld	a0,16(a0)
    80004860:	00000097          	auipc	ra,0x0
    80004864:	22e080e7          	jalr	558(ra) # 80004a8e <pipewrite>
    80004868:	8a2a                	mv	s4,a0
    8000486a:	a045                	j	8000490a <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    8000486c:	02451783          	lh	a5,36(a0)
    80004870:	03079693          	slli	a3,a5,0x30
    80004874:	92c1                	srli	a3,a3,0x30
    80004876:	4725                	li	a4,9
    80004878:	0cd76263          	bltu	a4,a3,8000493c <filewrite+0x12c>
    8000487c:	0792                	slli	a5,a5,0x4
    8000487e:	0001c717          	auipc	a4,0x1c
    80004882:	53a70713          	addi	a4,a4,1338 # 80020db8 <devsw>
    80004886:	97ba                	add	a5,a5,a4
    80004888:	679c                	ld	a5,8(a5)
    8000488a:	cbdd                	beqz	a5,80004940 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    8000488c:	4505                	li	a0,1
    8000488e:	9782                	jalr	a5
    80004890:	8a2a                	mv	s4,a0
    80004892:	a8a5                	j	8000490a <filewrite+0xfa>
    80004894:	00048a9b          	sext.w	s5,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004898:	00000097          	auipc	ra,0x0
    8000489c:	8b4080e7          	jalr	-1868(ra) # 8000414c <begin_op>
      ilock(f->ip);
    800048a0:	01893503          	ld	a0,24(s2)
    800048a4:	fffff097          	auipc	ra,0xfffff
    800048a8:	edc080e7          	jalr	-292(ra) # 80003780 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    800048ac:	8756                	mv	a4,s5
    800048ae:	02092683          	lw	a3,32(s2)
    800048b2:	01698633          	add	a2,s3,s6
    800048b6:	4585                	li	a1,1
    800048b8:	01893503          	ld	a0,24(s2)
    800048bc:	fffff097          	auipc	ra,0xfffff
    800048c0:	270080e7          	jalr	624(ra) # 80003b2c <writei>
    800048c4:	84aa                	mv	s1,a0
    800048c6:	00a05763          	blez	a0,800048d4 <filewrite+0xc4>
        f->off += r;
    800048ca:	02092783          	lw	a5,32(s2)
    800048ce:	9fa9                	addw	a5,a5,a0
    800048d0:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    800048d4:	01893503          	ld	a0,24(s2)
    800048d8:	fffff097          	auipc	ra,0xfffff
    800048dc:	f6a080e7          	jalr	-150(ra) # 80003842 <iunlock>
      end_op();
    800048e0:	00000097          	auipc	ra,0x0
    800048e4:	8ea080e7          	jalr	-1814(ra) # 800041ca <end_op>

      if(r != n1){
    800048e8:	009a9f63          	bne	s5,s1,80004906 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    800048ec:	013489bb          	addw	s3,s1,s3
    while(i < n){
    800048f0:	0149db63          	bge	s3,s4,80004906 <filewrite+0xf6>
      int n1 = n - i;
    800048f4:	413a04bb          	subw	s1,s4,s3
    800048f8:	0004879b          	sext.w	a5,s1
    800048fc:	f8fbdce3          	bge	s7,a5,80004894 <filewrite+0x84>
    80004900:	84e2                	mv	s1,s8
    80004902:	bf49                	j	80004894 <filewrite+0x84>
    int i = 0;
    80004904:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004906:	013a1f63          	bne	s4,s3,80004924 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    8000490a:	8552                	mv	a0,s4
    8000490c:	60a6                	ld	ra,72(sp)
    8000490e:	6406                	ld	s0,64(sp)
    80004910:	74e2                	ld	s1,56(sp)
    80004912:	7942                	ld	s2,48(sp)
    80004914:	79a2                	ld	s3,40(sp)
    80004916:	7a02                	ld	s4,32(sp)
    80004918:	6ae2                	ld	s5,24(sp)
    8000491a:	6b42                	ld	s6,16(sp)
    8000491c:	6ba2                	ld	s7,8(sp)
    8000491e:	6c02                	ld	s8,0(sp)
    80004920:	6161                	addi	sp,sp,80
    80004922:	8082                	ret
    ret = (i == n ? n : -1);
    80004924:	5a7d                	li	s4,-1
    80004926:	b7d5                	j	8000490a <filewrite+0xfa>
    panic("filewrite");
    80004928:	00004517          	auipc	a0,0x4
    8000492c:	ec050513          	addi	a0,a0,-320 # 800087e8 <syscalls+0x2c0>
    80004930:	ffffc097          	auipc	ra,0xffffc
    80004934:	c10080e7          	jalr	-1008(ra) # 80000540 <panic>
    return -1;
    80004938:	5a7d                	li	s4,-1
    8000493a:	bfc1                	j	8000490a <filewrite+0xfa>
      return -1;
    8000493c:	5a7d                	li	s4,-1
    8000493e:	b7f1                	j	8000490a <filewrite+0xfa>
    80004940:	5a7d                	li	s4,-1
    80004942:	b7e1                	j	8000490a <filewrite+0xfa>

0000000080004944 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004944:	7179                	addi	sp,sp,-48
    80004946:	f406                	sd	ra,40(sp)
    80004948:	f022                	sd	s0,32(sp)
    8000494a:	ec26                	sd	s1,24(sp)
    8000494c:	e84a                	sd	s2,16(sp)
    8000494e:	e44e                	sd	s3,8(sp)
    80004950:	e052                	sd	s4,0(sp)
    80004952:	1800                	addi	s0,sp,48
    80004954:	84aa                	mv	s1,a0
    80004956:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004958:	0005b023          	sd	zero,0(a1)
    8000495c:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004960:	00000097          	auipc	ra,0x0
    80004964:	bf8080e7          	jalr	-1032(ra) # 80004558 <filealloc>
    80004968:	e088                	sd	a0,0(s1)
    8000496a:	c551                	beqz	a0,800049f6 <pipealloc+0xb2>
    8000496c:	00000097          	auipc	ra,0x0
    80004970:	bec080e7          	jalr	-1044(ra) # 80004558 <filealloc>
    80004974:	00aa3023          	sd	a0,0(s4)
    80004978:	c92d                	beqz	a0,800049ea <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    8000497a:	ffffc097          	auipc	ra,0xffffc
    8000497e:	16c080e7          	jalr	364(ra) # 80000ae6 <kalloc>
    80004982:	892a                	mv	s2,a0
    80004984:	c125                	beqz	a0,800049e4 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004986:	4985                	li	s3,1
    80004988:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    8000498c:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004990:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004994:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004998:	00004597          	auipc	a1,0x4
    8000499c:	ae058593          	addi	a1,a1,-1312 # 80008478 <states.0+0x1b0>
    800049a0:	ffffc097          	auipc	ra,0xffffc
    800049a4:	1f0080e7          	jalr	496(ra) # 80000b90 <initlock>
  (*f0)->type = FD_PIPE;
    800049a8:	609c                	ld	a5,0(s1)
    800049aa:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    800049ae:	609c                	ld	a5,0(s1)
    800049b0:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    800049b4:	609c                	ld	a5,0(s1)
    800049b6:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    800049ba:	609c                	ld	a5,0(s1)
    800049bc:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    800049c0:	000a3783          	ld	a5,0(s4)
    800049c4:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    800049c8:	000a3783          	ld	a5,0(s4)
    800049cc:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    800049d0:	000a3783          	ld	a5,0(s4)
    800049d4:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    800049d8:	000a3783          	ld	a5,0(s4)
    800049dc:	0127b823          	sd	s2,16(a5)
  return 0;
    800049e0:	4501                	li	a0,0
    800049e2:	a025                	j	80004a0a <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    800049e4:	6088                	ld	a0,0(s1)
    800049e6:	e501                	bnez	a0,800049ee <pipealloc+0xaa>
    800049e8:	a039                	j	800049f6 <pipealloc+0xb2>
    800049ea:	6088                	ld	a0,0(s1)
    800049ec:	c51d                	beqz	a0,80004a1a <pipealloc+0xd6>
    fileclose(*f0);
    800049ee:	00000097          	auipc	ra,0x0
    800049f2:	c26080e7          	jalr	-986(ra) # 80004614 <fileclose>
  if(*f1)
    800049f6:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800049fa:	557d                	li	a0,-1
  if(*f1)
    800049fc:	c799                	beqz	a5,80004a0a <pipealloc+0xc6>
    fileclose(*f1);
    800049fe:	853e                	mv	a0,a5
    80004a00:	00000097          	auipc	ra,0x0
    80004a04:	c14080e7          	jalr	-1004(ra) # 80004614 <fileclose>
  return -1;
    80004a08:	557d                	li	a0,-1
}
    80004a0a:	70a2                	ld	ra,40(sp)
    80004a0c:	7402                	ld	s0,32(sp)
    80004a0e:	64e2                	ld	s1,24(sp)
    80004a10:	6942                	ld	s2,16(sp)
    80004a12:	69a2                	ld	s3,8(sp)
    80004a14:	6a02                	ld	s4,0(sp)
    80004a16:	6145                	addi	sp,sp,48
    80004a18:	8082                	ret
  return -1;
    80004a1a:	557d                	li	a0,-1
    80004a1c:	b7fd                	j	80004a0a <pipealloc+0xc6>

0000000080004a1e <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004a1e:	1101                	addi	sp,sp,-32
    80004a20:	ec06                	sd	ra,24(sp)
    80004a22:	e822                	sd	s0,16(sp)
    80004a24:	e426                	sd	s1,8(sp)
    80004a26:	e04a                	sd	s2,0(sp)
    80004a28:	1000                	addi	s0,sp,32
    80004a2a:	84aa                	mv	s1,a0
    80004a2c:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004a2e:	ffffc097          	auipc	ra,0xffffc
    80004a32:	1f2080e7          	jalr	498(ra) # 80000c20 <acquire>
  if(writable){
    80004a36:	02090d63          	beqz	s2,80004a70 <pipeclose+0x52>
    pi->writeopen = 0;
    80004a3a:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004a3e:	21848513          	addi	a0,s1,536
    80004a42:	ffffd097          	auipc	ra,0xffffd
    80004a46:	6c4080e7          	jalr	1732(ra) # 80002106 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004a4a:	2204b783          	ld	a5,544(s1)
    80004a4e:	eb95                	bnez	a5,80004a82 <pipeclose+0x64>
    release(&pi->lock);
    80004a50:	8526                	mv	a0,s1
    80004a52:	ffffc097          	auipc	ra,0xffffc
    80004a56:	282080e7          	jalr	642(ra) # 80000cd4 <release>
    kfree((char*)pi);
    80004a5a:	8526                	mv	a0,s1
    80004a5c:	ffffc097          	auipc	ra,0xffffc
    80004a60:	f8c080e7          	jalr	-116(ra) # 800009e8 <kfree>
  } else
    release(&pi->lock);
}
    80004a64:	60e2                	ld	ra,24(sp)
    80004a66:	6442                	ld	s0,16(sp)
    80004a68:	64a2                	ld	s1,8(sp)
    80004a6a:	6902                	ld	s2,0(sp)
    80004a6c:	6105                	addi	sp,sp,32
    80004a6e:	8082                	ret
    pi->readopen = 0;
    80004a70:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004a74:	21c48513          	addi	a0,s1,540
    80004a78:	ffffd097          	auipc	ra,0xffffd
    80004a7c:	68e080e7          	jalr	1678(ra) # 80002106 <wakeup>
    80004a80:	b7e9                	j	80004a4a <pipeclose+0x2c>
    release(&pi->lock);
    80004a82:	8526                	mv	a0,s1
    80004a84:	ffffc097          	auipc	ra,0xffffc
    80004a88:	250080e7          	jalr	592(ra) # 80000cd4 <release>
}
    80004a8c:	bfe1                	j	80004a64 <pipeclose+0x46>

0000000080004a8e <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004a8e:	711d                	addi	sp,sp,-96
    80004a90:	ec86                	sd	ra,88(sp)
    80004a92:	e8a2                	sd	s0,80(sp)
    80004a94:	e4a6                	sd	s1,72(sp)
    80004a96:	e0ca                	sd	s2,64(sp)
    80004a98:	fc4e                	sd	s3,56(sp)
    80004a9a:	f852                	sd	s4,48(sp)
    80004a9c:	f456                	sd	s5,40(sp)
    80004a9e:	f05a                	sd	s6,32(sp)
    80004aa0:	ec5e                	sd	s7,24(sp)
    80004aa2:	e862                	sd	s8,16(sp)
    80004aa4:	1080                	addi	s0,sp,96
    80004aa6:	84aa                	mv	s1,a0
    80004aa8:	8aae                	mv	s5,a1
    80004aaa:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004aac:	ffffd097          	auipc	ra,0xffffd
    80004ab0:	f4a080e7          	jalr	-182(ra) # 800019f6 <myproc>
    80004ab4:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004ab6:	8526                	mv	a0,s1
    80004ab8:	ffffc097          	auipc	ra,0xffffc
    80004abc:	168080e7          	jalr	360(ra) # 80000c20 <acquire>
  while(i < n){
    80004ac0:	0b405663          	blez	s4,80004b6c <pipewrite+0xde>
  int i = 0;
    80004ac4:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ac6:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004ac8:	21848c13          	addi	s8,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004acc:	21c48b93          	addi	s7,s1,540
    80004ad0:	a089                	j	80004b12 <pipewrite+0x84>
      release(&pi->lock);
    80004ad2:	8526                	mv	a0,s1
    80004ad4:	ffffc097          	auipc	ra,0xffffc
    80004ad8:	200080e7          	jalr	512(ra) # 80000cd4 <release>
      return -1;
    80004adc:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004ade:	854a                	mv	a0,s2
    80004ae0:	60e6                	ld	ra,88(sp)
    80004ae2:	6446                	ld	s0,80(sp)
    80004ae4:	64a6                	ld	s1,72(sp)
    80004ae6:	6906                	ld	s2,64(sp)
    80004ae8:	79e2                	ld	s3,56(sp)
    80004aea:	7a42                	ld	s4,48(sp)
    80004aec:	7aa2                	ld	s5,40(sp)
    80004aee:	7b02                	ld	s6,32(sp)
    80004af0:	6be2                	ld	s7,24(sp)
    80004af2:	6c42                	ld	s8,16(sp)
    80004af4:	6125                	addi	sp,sp,96
    80004af6:	8082                	ret
      wakeup(&pi->nread);
    80004af8:	8562                	mv	a0,s8
    80004afa:	ffffd097          	auipc	ra,0xffffd
    80004afe:	60c080e7          	jalr	1548(ra) # 80002106 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004b02:	85a6                	mv	a1,s1
    80004b04:	855e                	mv	a0,s7
    80004b06:	ffffd097          	auipc	ra,0xffffd
    80004b0a:	59c080e7          	jalr	1436(ra) # 800020a2 <sleep>
  while(i < n){
    80004b0e:	07495063          	bge	s2,s4,80004b6e <pipewrite+0xe0>
    if(pi->readopen == 0 || killed(pr)){
    80004b12:	2204a783          	lw	a5,544(s1)
    80004b16:	dfd5                	beqz	a5,80004ad2 <pipewrite+0x44>
    80004b18:	854e                	mv	a0,s3
    80004b1a:	ffffe097          	auipc	ra,0xffffe
    80004b1e:	830080e7          	jalr	-2000(ra) # 8000234a <killed>
    80004b22:	f945                	bnez	a0,80004ad2 <pipewrite+0x44>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004b24:	2184a783          	lw	a5,536(s1)
    80004b28:	21c4a703          	lw	a4,540(s1)
    80004b2c:	2007879b          	addiw	a5,a5,512
    80004b30:	fcf704e3          	beq	a4,a5,80004af8 <pipewrite+0x6a>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004b34:	4685                	li	a3,1
    80004b36:	01590633          	add	a2,s2,s5
    80004b3a:	faf40593          	addi	a1,s0,-81
    80004b3e:	0509b503          	ld	a0,80(s3)
    80004b42:	ffffd097          	auipc	ra,0xffffd
    80004b46:	c00080e7          	jalr	-1024(ra) # 80001742 <copyin>
    80004b4a:	03650263          	beq	a0,s6,80004b6e <pipewrite+0xe0>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004b4e:	21c4a783          	lw	a5,540(s1)
    80004b52:	0017871b          	addiw	a4,a5,1
    80004b56:	20e4ae23          	sw	a4,540(s1)
    80004b5a:	1ff7f793          	andi	a5,a5,511
    80004b5e:	97a6                	add	a5,a5,s1
    80004b60:	faf44703          	lbu	a4,-81(s0)
    80004b64:	00e78c23          	sb	a4,24(a5)
      i++;
    80004b68:	2905                	addiw	s2,s2,1
    80004b6a:	b755                	j	80004b0e <pipewrite+0x80>
  int i = 0;
    80004b6c:	4901                	li	s2,0
  wakeup(&pi->nread);
    80004b6e:	21848513          	addi	a0,s1,536
    80004b72:	ffffd097          	auipc	ra,0xffffd
    80004b76:	594080e7          	jalr	1428(ra) # 80002106 <wakeup>
  release(&pi->lock);
    80004b7a:	8526                	mv	a0,s1
    80004b7c:	ffffc097          	auipc	ra,0xffffc
    80004b80:	158080e7          	jalr	344(ra) # 80000cd4 <release>
  return i;
    80004b84:	bfa9                	j	80004ade <pipewrite+0x50>

0000000080004b86 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004b86:	715d                	addi	sp,sp,-80
    80004b88:	e486                	sd	ra,72(sp)
    80004b8a:	e0a2                	sd	s0,64(sp)
    80004b8c:	fc26                	sd	s1,56(sp)
    80004b8e:	f84a                	sd	s2,48(sp)
    80004b90:	f44e                	sd	s3,40(sp)
    80004b92:	f052                	sd	s4,32(sp)
    80004b94:	ec56                	sd	s5,24(sp)
    80004b96:	e85a                	sd	s6,16(sp)
    80004b98:	0880                	addi	s0,sp,80
    80004b9a:	84aa                	mv	s1,a0
    80004b9c:	892e                	mv	s2,a1
    80004b9e:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004ba0:	ffffd097          	auipc	ra,0xffffd
    80004ba4:	e56080e7          	jalr	-426(ra) # 800019f6 <myproc>
    80004ba8:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004baa:	8526                	mv	a0,s1
    80004bac:	ffffc097          	auipc	ra,0xffffc
    80004bb0:	074080e7          	jalr	116(ra) # 80000c20 <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bb4:	2184a703          	lw	a4,536(s1)
    80004bb8:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004bbc:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004bc0:	02f71763          	bne	a4,a5,80004bee <piperead+0x68>
    80004bc4:	2244a783          	lw	a5,548(s1)
    80004bc8:	c39d                	beqz	a5,80004bee <piperead+0x68>
    if(killed(pr)){
    80004bca:	8552                	mv	a0,s4
    80004bcc:	ffffd097          	auipc	ra,0xffffd
    80004bd0:	77e080e7          	jalr	1918(ra) # 8000234a <killed>
    80004bd4:	e949                	bnez	a0,80004c66 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004bd6:	85a6                	mv	a1,s1
    80004bd8:	854e                	mv	a0,s3
    80004bda:	ffffd097          	auipc	ra,0xffffd
    80004bde:	4c8080e7          	jalr	1224(ra) # 800020a2 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004be2:	2184a703          	lw	a4,536(s1)
    80004be6:	21c4a783          	lw	a5,540(s1)
    80004bea:	fcf70de3          	beq	a4,a5,80004bc4 <piperead+0x3e>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004bee:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004bf0:	5b7d                	li	s6,-1
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004bf2:	05505463          	blez	s5,80004c3a <piperead+0xb4>
    if(pi->nread == pi->nwrite)
    80004bf6:	2184a783          	lw	a5,536(s1)
    80004bfa:	21c4a703          	lw	a4,540(s1)
    80004bfe:	02f70e63          	beq	a4,a5,80004c3a <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    80004c02:	0017871b          	addiw	a4,a5,1
    80004c06:	20e4ac23          	sw	a4,536(s1)
    80004c0a:	1ff7f793          	andi	a5,a5,511
    80004c0e:	97a6                	add	a5,a5,s1
    80004c10:	0187c783          	lbu	a5,24(a5)
    80004c14:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80004c18:	4685                	li	a3,1
    80004c1a:	fbf40613          	addi	a2,s0,-65
    80004c1e:	85ca                	mv	a1,s2
    80004c20:	050a3503          	ld	a0,80(s4)
    80004c24:	ffffd097          	auipc	ra,0xffffd
    80004c28:	a92080e7          	jalr	-1390(ra) # 800016b6 <copyout>
    80004c2c:	01650763          	beq	a0,s6,80004c3a <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004c30:	2985                	addiw	s3,s3,1
    80004c32:	0905                	addi	s2,s2,1
    80004c34:	fd3a91e3          	bne	s5,s3,80004bf6 <piperead+0x70>
    80004c38:	89d6                	mv	s3,s5
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80004c3a:	21c48513          	addi	a0,s1,540
    80004c3e:	ffffd097          	auipc	ra,0xffffd
    80004c42:	4c8080e7          	jalr	1224(ra) # 80002106 <wakeup>
  release(&pi->lock);
    80004c46:	8526                	mv	a0,s1
    80004c48:	ffffc097          	auipc	ra,0xffffc
    80004c4c:	08c080e7          	jalr	140(ra) # 80000cd4 <release>
  return i;
}
    80004c50:	854e                	mv	a0,s3
    80004c52:	60a6                	ld	ra,72(sp)
    80004c54:	6406                	ld	s0,64(sp)
    80004c56:	74e2                	ld	s1,56(sp)
    80004c58:	7942                	ld	s2,48(sp)
    80004c5a:	79a2                	ld	s3,40(sp)
    80004c5c:	7a02                	ld	s4,32(sp)
    80004c5e:	6ae2                	ld	s5,24(sp)
    80004c60:	6b42                	ld	s6,16(sp)
    80004c62:	6161                	addi	sp,sp,80
    80004c64:	8082                	ret
      release(&pi->lock);
    80004c66:	8526                	mv	a0,s1
    80004c68:	ffffc097          	auipc	ra,0xffffc
    80004c6c:	06c080e7          	jalr	108(ra) # 80000cd4 <release>
      return -1;
    80004c70:	59fd                	li	s3,-1
    80004c72:	bff9                	j	80004c50 <piperead+0xca>

0000000080004c74 <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    80004c74:	1141                	addi	sp,sp,-16
    80004c76:	e422                	sd	s0,8(sp)
    80004c78:	0800                	addi	s0,sp,16
    80004c7a:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80004c7c:	8905                	andi	a0,a0,1
    80004c7e:	050e                	slli	a0,a0,0x3
      perm = PTE_X;
    if(flags & 0x2)
    80004c80:	8b89                	andi	a5,a5,2
    80004c82:	c399                	beqz	a5,80004c88 <flags2perm+0x14>
      perm |= PTE_W;
    80004c84:	00456513          	ori	a0,a0,4
    return perm;
}
    80004c88:	6422                	ld	s0,8(sp)
    80004c8a:	0141                	addi	sp,sp,16
    80004c8c:	8082                	ret

0000000080004c8e <exec>:

int
exec(char *path, char **argv)
{
    80004c8e:	de010113          	addi	sp,sp,-544
    80004c92:	20113c23          	sd	ra,536(sp)
    80004c96:	20813823          	sd	s0,528(sp)
    80004c9a:	20913423          	sd	s1,520(sp)
    80004c9e:	21213023          	sd	s2,512(sp)
    80004ca2:	ffce                	sd	s3,504(sp)
    80004ca4:	fbd2                	sd	s4,496(sp)
    80004ca6:	f7d6                	sd	s5,488(sp)
    80004ca8:	f3da                	sd	s6,480(sp)
    80004caa:	efde                	sd	s7,472(sp)
    80004cac:	ebe2                	sd	s8,464(sp)
    80004cae:	e7e6                	sd	s9,456(sp)
    80004cb0:	e3ea                	sd	s10,448(sp)
    80004cb2:	ff6e                	sd	s11,440(sp)
    80004cb4:	1400                	addi	s0,sp,544
    80004cb6:	892a                	mv	s2,a0
    80004cb8:	dea43423          	sd	a0,-536(s0)
    80004cbc:	deb43823          	sd	a1,-528(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80004cc0:	ffffd097          	auipc	ra,0xffffd
    80004cc4:	d36080e7          	jalr	-714(ra) # 800019f6 <myproc>
    80004cc8:	84aa                	mv	s1,a0

  begin_op();
    80004cca:	fffff097          	auipc	ra,0xfffff
    80004cce:	482080e7          	jalr	1154(ra) # 8000414c <begin_op>

  if((ip = namei(path)) == 0){
    80004cd2:	854a                	mv	a0,s2
    80004cd4:	fffff097          	auipc	ra,0xfffff
    80004cd8:	258080e7          	jalr	600(ra) # 80003f2c <namei>
    80004cdc:	c93d                	beqz	a0,80004d52 <exec+0xc4>
    80004cde:	8aaa                	mv	s5,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80004ce0:	fffff097          	auipc	ra,0xfffff
    80004ce4:	aa0080e7          	jalr	-1376(ra) # 80003780 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    80004ce8:	04000713          	li	a4,64
    80004cec:	4681                	li	a3,0
    80004cee:	e5040613          	addi	a2,s0,-432
    80004cf2:	4581                	li	a1,0
    80004cf4:	8556                	mv	a0,s5
    80004cf6:	fffff097          	auipc	ra,0xfffff
    80004cfa:	d3e080e7          	jalr	-706(ra) # 80003a34 <readi>
    80004cfe:	04000793          	li	a5,64
    80004d02:	00f51a63          	bne	a0,a5,80004d16 <exec+0x88>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    80004d06:	e5042703          	lw	a4,-432(s0)
    80004d0a:	464c47b7          	lui	a5,0x464c4
    80004d0e:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80004d12:	04f70663          	beq	a4,a5,80004d5e <exec+0xd0>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80004d16:	8556                	mv	a0,s5
    80004d18:	fffff097          	auipc	ra,0xfffff
    80004d1c:	cca080e7          	jalr	-822(ra) # 800039e2 <iunlockput>
    end_op();
    80004d20:	fffff097          	auipc	ra,0xfffff
    80004d24:	4aa080e7          	jalr	1194(ra) # 800041ca <end_op>
  }
  return -1;
    80004d28:	557d                	li	a0,-1
}
    80004d2a:	21813083          	ld	ra,536(sp)
    80004d2e:	21013403          	ld	s0,528(sp)
    80004d32:	20813483          	ld	s1,520(sp)
    80004d36:	20013903          	ld	s2,512(sp)
    80004d3a:	79fe                	ld	s3,504(sp)
    80004d3c:	7a5e                	ld	s4,496(sp)
    80004d3e:	7abe                	ld	s5,488(sp)
    80004d40:	7b1e                	ld	s6,480(sp)
    80004d42:	6bfe                	ld	s7,472(sp)
    80004d44:	6c5e                	ld	s8,464(sp)
    80004d46:	6cbe                	ld	s9,456(sp)
    80004d48:	6d1e                	ld	s10,448(sp)
    80004d4a:	7dfa                	ld	s11,440(sp)
    80004d4c:	22010113          	addi	sp,sp,544
    80004d50:	8082                	ret
    end_op();
    80004d52:	fffff097          	auipc	ra,0xfffff
    80004d56:	478080e7          	jalr	1144(ra) # 800041ca <end_op>
    return -1;
    80004d5a:	557d                	li	a0,-1
    80004d5c:	b7f9                	j	80004d2a <exec+0x9c>
  if((pagetable = proc_pagetable(p)) == 0)
    80004d5e:	8526                	mv	a0,s1
    80004d60:	ffffd097          	auipc	ra,0xffffd
    80004d64:	d5a080e7          	jalr	-678(ra) # 80001aba <proc_pagetable>
    80004d68:	8b2a                	mv	s6,a0
    80004d6a:	d555                	beqz	a0,80004d16 <exec+0x88>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d6c:	e7042783          	lw	a5,-400(s0)
    80004d70:	e8845703          	lhu	a4,-376(s0)
    80004d74:	c735                	beqz	a4,80004de0 <exec+0x152>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004d76:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004d78:	e0043423          	sd	zero,-504(s0)
    if(ph.vaddr % PGSIZE != 0)
    80004d7c:	6a05                	lui	s4,0x1
    80004d7e:	fffa0713          	addi	a4,s4,-1 # fff <_entry-0x7ffff001>
    80004d82:	dee43023          	sd	a4,-544(s0)
loadseg(pagetable_t pagetable, uint64 va, struct inode *ip, uint offset, uint sz)
{
  uint i, n;
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    80004d86:	6d85                	lui	s11,0x1
    80004d88:	7d7d                	lui	s10,0xfffff
    80004d8a:	ac3d                	j	80004fc8 <exec+0x33a>
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80004d8c:	00004517          	auipc	a0,0x4
    80004d90:	a6c50513          	addi	a0,a0,-1428 # 800087f8 <syscalls+0x2d0>
    80004d94:	ffffb097          	auipc	ra,0xffffb
    80004d98:	7ac080e7          	jalr	1964(ra) # 80000540 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80004d9c:	874a                	mv	a4,s2
    80004d9e:	009c86bb          	addw	a3,s9,s1
    80004da2:	4581                	li	a1,0
    80004da4:	8556                	mv	a0,s5
    80004da6:	fffff097          	auipc	ra,0xfffff
    80004daa:	c8e080e7          	jalr	-882(ra) # 80003a34 <readi>
    80004dae:	2501                	sext.w	a0,a0
    80004db0:	1aa91963          	bne	s2,a0,80004f62 <exec+0x2d4>
  for(i = 0; i < sz; i += PGSIZE){
    80004db4:	009d84bb          	addw	s1,s11,s1
    80004db8:	013d09bb          	addw	s3,s10,s3
    80004dbc:	1f74f663          	bgeu	s1,s7,80004fa8 <exec+0x31a>
    pa = walkaddr(pagetable, va + i);
    80004dc0:	02049593          	slli	a1,s1,0x20
    80004dc4:	9181                	srli	a1,a1,0x20
    80004dc6:	95e2                	add	a1,a1,s8
    80004dc8:	855a                	mv	a0,s6
    80004dca:	ffffc097          	auipc	ra,0xffffc
    80004dce:	2dc080e7          	jalr	732(ra) # 800010a6 <walkaddr>
    80004dd2:	862a                	mv	a2,a0
    if(pa == 0)
    80004dd4:	dd45                	beqz	a0,80004d8c <exec+0xfe>
      n = PGSIZE;
    80004dd6:	8952                	mv	s2,s4
    if(sz - i < PGSIZE)
    80004dd8:	fd49f2e3          	bgeu	s3,s4,80004d9c <exec+0x10e>
      n = sz - i;
    80004ddc:	894e                	mv	s2,s3
    80004dde:	bf7d                	j	80004d9c <exec+0x10e>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80004de0:	4901                	li	s2,0
  iunlockput(ip);
    80004de2:	8556                	mv	a0,s5
    80004de4:	fffff097          	auipc	ra,0xfffff
    80004de8:	bfe080e7          	jalr	-1026(ra) # 800039e2 <iunlockput>
  end_op();
    80004dec:	fffff097          	auipc	ra,0xfffff
    80004df0:	3de080e7          	jalr	990(ra) # 800041ca <end_op>
  p = myproc();
    80004df4:	ffffd097          	auipc	ra,0xffffd
    80004df8:	c02080e7          	jalr	-1022(ra) # 800019f6 <myproc>
    80004dfc:	8baa                	mv	s7,a0
  uint64 oldsz = p->sz;
    80004dfe:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    80004e02:	6785                	lui	a5,0x1
    80004e04:	17fd                	addi	a5,a5,-1 # fff <_entry-0x7ffff001>
    80004e06:	97ca                	add	a5,a5,s2
    80004e08:	777d                	lui	a4,0xfffff
    80004e0a:	8ff9                	and	a5,a5,a4
    80004e0c:	def43c23          	sd	a5,-520(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004e10:	4691                	li	a3,4
    80004e12:	6609                	lui	a2,0x2
    80004e14:	963e                	add	a2,a2,a5
    80004e16:	85be                	mv	a1,a5
    80004e18:	855a                	mv	a0,s6
    80004e1a:	ffffc097          	auipc	ra,0xffffc
    80004e1e:	640080e7          	jalr	1600(ra) # 8000145a <uvmalloc>
    80004e22:	8c2a                	mv	s8,a0
  ip = 0;
    80004e24:	4a81                	li	s5,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    80004e26:	12050e63          	beqz	a0,80004f62 <exec+0x2d4>
  uvmclear(pagetable, sz-2*PGSIZE);
    80004e2a:	75f9                	lui	a1,0xffffe
    80004e2c:	95aa                	add	a1,a1,a0
    80004e2e:	855a                	mv	a0,s6
    80004e30:	ffffd097          	auipc	ra,0xffffd
    80004e34:	854080e7          	jalr	-1964(ra) # 80001684 <uvmclear>
  stackbase = sp - PGSIZE;
    80004e38:	7afd                	lui	s5,0xfffff
    80004e3a:	9ae2                	add	s5,s5,s8
  for(argc = 0; argv[argc]; argc++) {
    80004e3c:	df043783          	ld	a5,-528(s0)
    80004e40:	6388                	ld	a0,0(a5)
    80004e42:	c925                	beqz	a0,80004eb2 <exec+0x224>
    80004e44:	e9040993          	addi	s3,s0,-368
    80004e48:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80004e4c:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004e4e:	4481                	li	s1,0
    sp -= strlen(argv[argc]) + 1;
    80004e50:	ffffc097          	auipc	ra,0xffffc
    80004e54:	048080e7          	jalr	72(ra) # 80000e98 <strlen>
    80004e58:	0015079b          	addiw	a5,a0,1
    80004e5c:	40f907b3          	sub	a5,s2,a5
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80004e60:	ff07f913          	andi	s2,a5,-16
    if(sp < stackbase)
    80004e64:	13596663          	bltu	s2,s5,80004f90 <exec+0x302>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80004e68:	df043d83          	ld	s11,-528(s0)
    80004e6c:	000dba03          	ld	s4,0(s11) # 1000 <_entry-0x7ffff000>
    80004e70:	8552                	mv	a0,s4
    80004e72:	ffffc097          	auipc	ra,0xffffc
    80004e76:	026080e7          	jalr	38(ra) # 80000e98 <strlen>
    80004e7a:	0015069b          	addiw	a3,a0,1
    80004e7e:	8652                	mv	a2,s4
    80004e80:	85ca                	mv	a1,s2
    80004e82:	855a                	mv	a0,s6
    80004e84:	ffffd097          	auipc	ra,0xffffd
    80004e88:	832080e7          	jalr	-1998(ra) # 800016b6 <copyout>
    80004e8c:	10054663          	bltz	a0,80004f98 <exec+0x30a>
    ustack[argc] = sp;
    80004e90:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80004e94:	0485                	addi	s1,s1,1
    80004e96:	008d8793          	addi	a5,s11,8
    80004e9a:	def43823          	sd	a5,-528(s0)
    80004e9e:	008db503          	ld	a0,8(s11)
    80004ea2:	c911                	beqz	a0,80004eb6 <exec+0x228>
    if(argc >= MAXARG)
    80004ea4:	09a1                	addi	s3,s3,8
    80004ea6:	fb3c95e3          	bne	s9,s3,80004e50 <exec+0x1c2>
  sz = sz1;
    80004eaa:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004eae:	4a81                	li	s5,0
    80004eb0:	a84d                	j	80004f62 <exec+0x2d4>
  sp = sz;
    80004eb2:	8962                	mv	s2,s8
  for(argc = 0; argv[argc]; argc++) {
    80004eb4:	4481                	li	s1,0
  ustack[argc] = 0;
    80004eb6:	00349793          	slli	a5,s1,0x3
    80004eba:	f9078793          	addi	a5,a5,-112
    80004ebe:	97a2                	add	a5,a5,s0
    80004ec0:	f007b023          	sd	zero,-256(a5)
  sp -= (argc+1) * sizeof(uint64);
    80004ec4:	00148693          	addi	a3,s1,1
    80004ec8:	068e                	slli	a3,a3,0x3
    80004eca:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80004ece:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80004ed2:	01597663          	bgeu	s2,s5,80004ede <exec+0x250>
  sz = sz1;
    80004ed6:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004eda:	4a81                	li	s5,0
    80004edc:	a059                	j	80004f62 <exec+0x2d4>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80004ede:	e9040613          	addi	a2,s0,-368
    80004ee2:	85ca                	mv	a1,s2
    80004ee4:	855a                	mv	a0,s6
    80004ee6:	ffffc097          	auipc	ra,0xffffc
    80004eea:	7d0080e7          	jalr	2000(ra) # 800016b6 <copyout>
    80004eee:	0a054963          	bltz	a0,80004fa0 <exec+0x312>
  p->trapframe->a1 = sp;
    80004ef2:	058bb783          	ld	a5,88(s7)
    80004ef6:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80004efa:	de843783          	ld	a5,-536(s0)
    80004efe:	0007c703          	lbu	a4,0(a5)
    80004f02:	cf11                	beqz	a4,80004f1e <exec+0x290>
    80004f04:	0785                	addi	a5,a5,1
    if(*s == '/')
    80004f06:	02f00693          	li	a3,47
    80004f0a:	a039                	j	80004f18 <exec+0x28a>
      last = s+1;
    80004f0c:	def43423          	sd	a5,-536(s0)
  for(last=s=path; *s; s++)
    80004f10:	0785                	addi	a5,a5,1
    80004f12:	fff7c703          	lbu	a4,-1(a5)
    80004f16:	c701                	beqz	a4,80004f1e <exec+0x290>
    if(*s == '/')
    80004f18:	fed71ce3          	bne	a4,a3,80004f10 <exec+0x282>
    80004f1c:	bfc5                	j	80004f0c <exec+0x27e>
  safestrcpy(p->name, last, sizeof(p->name));
    80004f1e:	4641                	li	a2,16
    80004f20:	de843583          	ld	a1,-536(s0)
    80004f24:	158b8513          	addi	a0,s7,344
    80004f28:	ffffc097          	auipc	ra,0xffffc
    80004f2c:	f3e080e7          	jalr	-194(ra) # 80000e66 <safestrcpy>
  oldpagetable = p->pagetable;
    80004f30:	050bb503          	ld	a0,80(s7)
  p->pagetable = pagetable;
    80004f34:	056bb823          	sd	s6,80(s7)
  p->sz = sz;
    80004f38:	058bb423          	sd	s8,72(s7)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80004f3c:	058bb783          	ld	a5,88(s7)
    80004f40:	e6843703          	ld	a4,-408(s0)
    80004f44:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80004f46:	058bb783          	ld	a5,88(s7)
    80004f4a:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80004f4e:	85ea                	mv	a1,s10
    80004f50:	ffffd097          	auipc	ra,0xffffd
    80004f54:	c06080e7          	jalr	-1018(ra) # 80001b56 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80004f58:	0004851b          	sext.w	a0,s1
    80004f5c:	b3f9                	j	80004d2a <exec+0x9c>
    80004f5e:	df243c23          	sd	s2,-520(s0)
    proc_freepagetable(pagetable, sz);
    80004f62:	df843583          	ld	a1,-520(s0)
    80004f66:	855a                	mv	a0,s6
    80004f68:	ffffd097          	auipc	ra,0xffffd
    80004f6c:	bee080e7          	jalr	-1042(ra) # 80001b56 <proc_freepagetable>
  if(ip){
    80004f70:	da0a93e3          	bnez	s5,80004d16 <exec+0x88>
  return -1;
    80004f74:	557d                	li	a0,-1
    80004f76:	bb55                	j	80004d2a <exec+0x9c>
    80004f78:	df243c23          	sd	s2,-520(s0)
    80004f7c:	b7dd                	j	80004f62 <exec+0x2d4>
    80004f7e:	df243c23          	sd	s2,-520(s0)
    80004f82:	b7c5                	j	80004f62 <exec+0x2d4>
    80004f84:	df243c23          	sd	s2,-520(s0)
    80004f88:	bfe9                	j	80004f62 <exec+0x2d4>
    80004f8a:	df243c23          	sd	s2,-520(s0)
    80004f8e:	bfd1                	j	80004f62 <exec+0x2d4>
  sz = sz1;
    80004f90:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f94:	4a81                	li	s5,0
    80004f96:	b7f1                	j	80004f62 <exec+0x2d4>
  sz = sz1;
    80004f98:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004f9c:	4a81                	li	s5,0
    80004f9e:	b7d1                	j	80004f62 <exec+0x2d4>
  sz = sz1;
    80004fa0:	df843c23          	sd	s8,-520(s0)
  ip = 0;
    80004fa4:	4a81                	li	s5,0
    80004fa6:	bf75                	j	80004f62 <exec+0x2d4>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80004fa8:	df843903          	ld	s2,-520(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80004fac:	e0843783          	ld	a5,-504(s0)
    80004fb0:	0017869b          	addiw	a3,a5,1
    80004fb4:	e0d43423          	sd	a3,-504(s0)
    80004fb8:	e0043783          	ld	a5,-512(s0)
    80004fbc:	0387879b          	addiw	a5,a5,56
    80004fc0:	e8845703          	lhu	a4,-376(s0)
    80004fc4:	e0e6dfe3          	bge	a3,a4,80004de2 <exec+0x154>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80004fc8:	2781                	sext.w	a5,a5
    80004fca:	e0f43023          	sd	a5,-512(s0)
    80004fce:	03800713          	li	a4,56
    80004fd2:	86be                	mv	a3,a5
    80004fd4:	e1840613          	addi	a2,s0,-488
    80004fd8:	4581                	li	a1,0
    80004fda:	8556                	mv	a0,s5
    80004fdc:	fffff097          	auipc	ra,0xfffff
    80004fe0:	a58080e7          	jalr	-1448(ra) # 80003a34 <readi>
    80004fe4:	03800793          	li	a5,56
    80004fe8:	f6f51be3          	bne	a0,a5,80004f5e <exec+0x2d0>
    if(ph.type != ELF_PROG_LOAD)
    80004fec:	e1842783          	lw	a5,-488(s0)
    80004ff0:	4705                	li	a4,1
    80004ff2:	fae79de3          	bne	a5,a4,80004fac <exec+0x31e>
    if(ph.memsz < ph.filesz)
    80004ff6:	e4043483          	ld	s1,-448(s0)
    80004ffa:	e3843783          	ld	a5,-456(s0)
    80004ffe:	f6f4ede3          	bltu	s1,a5,80004f78 <exec+0x2ea>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005002:	e2843783          	ld	a5,-472(s0)
    80005006:	94be                	add	s1,s1,a5
    80005008:	f6f4ebe3          	bltu	s1,a5,80004f7e <exec+0x2f0>
    if(ph.vaddr % PGSIZE != 0)
    8000500c:	de043703          	ld	a4,-544(s0)
    80005010:	8ff9                	and	a5,a5,a4
    80005012:	fbad                	bnez	a5,80004f84 <exec+0x2f6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005014:	e1c42503          	lw	a0,-484(s0)
    80005018:	00000097          	auipc	ra,0x0
    8000501c:	c5c080e7          	jalr	-932(ra) # 80004c74 <flags2perm>
    80005020:	86aa                	mv	a3,a0
    80005022:	8626                	mv	a2,s1
    80005024:	85ca                	mv	a1,s2
    80005026:	855a                	mv	a0,s6
    80005028:	ffffc097          	auipc	ra,0xffffc
    8000502c:	432080e7          	jalr	1074(ra) # 8000145a <uvmalloc>
    80005030:	dea43c23          	sd	a0,-520(s0)
    80005034:	d939                	beqz	a0,80004f8a <exec+0x2fc>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005036:	e2843c03          	ld	s8,-472(s0)
    8000503a:	e2042c83          	lw	s9,-480(s0)
    8000503e:	e3842b83          	lw	s7,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005042:	f60b83e3          	beqz	s7,80004fa8 <exec+0x31a>
    80005046:	89de                	mv	s3,s7
    80005048:	4481                	li	s1,0
    8000504a:	bb9d                	j	80004dc0 <exec+0x132>

000000008000504c <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000504c:	7179                	addi	sp,sp,-48
    8000504e:	f406                	sd	ra,40(sp)
    80005050:	f022                	sd	s0,32(sp)
    80005052:	ec26                	sd	s1,24(sp)
    80005054:	e84a                	sd	s2,16(sp)
    80005056:	1800                	addi	s0,sp,48
    80005058:	892e                	mv	s2,a1
    8000505a:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    8000505c:	fdc40593          	addi	a1,s0,-36
    80005060:	ffffe097          	auipc	ra,0xffffe
    80005064:	b06080e7          	jalr	-1274(ra) # 80002b66 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005068:	fdc42703          	lw	a4,-36(s0)
    8000506c:	47bd                	li	a5,15
    8000506e:	02e7eb63          	bltu	a5,a4,800050a4 <argfd+0x58>
    80005072:	ffffd097          	auipc	ra,0xffffd
    80005076:	984080e7          	jalr	-1660(ra) # 800019f6 <myproc>
    8000507a:	fdc42703          	lw	a4,-36(s0)
    8000507e:	01a70793          	addi	a5,a4,26 # fffffffffffff01a <end+0xffffffff7ffdd0ca>
    80005082:	078e                	slli	a5,a5,0x3
    80005084:	953e                	add	a0,a0,a5
    80005086:	611c                	ld	a5,0(a0)
    80005088:	c385                	beqz	a5,800050a8 <argfd+0x5c>
    return -1;
  if(pfd)
    8000508a:	00090463          	beqz	s2,80005092 <argfd+0x46>
    *pfd = fd;
    8000508e:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005092:	4501                	li	a0,0
  if(pf)
    80005094:	c091                	beqz	s1,80005098 <argfd+0x4c>
    *pf = f;
    80005096:	e09c                	sd	a5,0(s1)
}
    80005098:	70a2                	ld	ra,40(sp)
    8000509a:	7402                	ld	s0,32(sp)
    8000509c:	64e2                	ld	s1,24(sp)
    8000509e:	6942                	ld	s2,16(sp)
    800050a0:	6145                	addi	sp,sp,48
    800050a2:	8082                	ret
    return -1;
    800050a4:	557d                	li	a0,-1
    800050a6:	bfcd                	j	80005098 <argfd+0x4c>
    800050a8:	557d                	li	a0,-1
    800050aa:	b7fd                	j	80005098 <argfd+0x4c>

00000000800050ac <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    800050ac:	1101                	addi	sp,sp,-32
    800050ae:	ec06                	sd	ra,24(sp)
    800050b0:	e822                	sd	s0,16(sp)
    800050b2:	e426                	sd	s1,8(sp)
    800050b4:	1000                	addi	s0,sp,32
    800050b6:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    800050b8:	ffffd097          	auipc	ra,0xffffd
    800050bc:	93e080e7          	jalr	-1730(ra) # 800019f6 <myproc>
    800050c0:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    800050c2:	0d050793          	addi	a5,a0,208
    800050c6:	4501                	li	a0,0
    800050c8:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    800050ca:	6398                	ld	a4,0(a5)
    800050cc:	cb19                	beqz	a4,800050e2 <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    800050ce:	2505                	addiw	a0,a0,1
    800050d0:	07a1                	addi	a5,a5,8
    800050d2:	fed51ce3          	bne	a0,a3,800050ca <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    800050d6:	557d                	li	a0,-1
}
    800050d8:	60e2                	ld	ra,24(sp)
    800050da:	6442                	ld	s0,16(sp)
    800050dc:	64a2                	ld	s1,8(sp)
    800050de:	6105                	addi	sp,sp,32
    800050e0:	8082                	ret
      p->ofile[fd] = f;
    800050e2:	01a50793          	addi	a5,a0,26
    800050e6:	078e                	slli	a5,a5,0x3
    800050e8:	963e                	add	a2,a2,a5
    800050ea:	e204                	sd	s1,0(a2)
      return fd;
    800050ec:	b7f5                	j	800050d8 <fdalloc+0x2c>

00000000800050ee <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800050ee:	715d                	addi	sp,sp,-80
    800050f0:	e486                	sd	ra,72(sp)
    800050f2:	e0a2                	sd	s0,64(sp)
    800050f4:	fc26                	sd	s1,56(sp)
    800050f6:	f84a                	sd	s2,48(sp)
    800050f8:	f44e                	sd	s3,40(sp)
    800050fa:	f052                	sd	s4,32(sp)
    800050fc:	ec56                	sd	s5,24(sp)
    800050fe:	e85a                	sd	s6,16(sp)
    80005100:	0880                	addi	s0,sp,80
    80005102:	8b2e                	mv	s6,a1
    80005104:	89b2                	mv	s3,a2
    80005106:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005108:	fb040593          	addi	a1,s0,-80
    8000510c:	fffff097          	auipc	ra,0xfffff
    80005110:	e3e080e7          	jalr	-450(ra) # 80003f4a <nameiparent>
    80005114:	84aa                	mv	s1,a0
    80005116:	14050f63          	beqz	a0,80005274 <create+0x186>
    return 0;

  ilock(dp);
    8000511a:	ffffe097          	auipc	ra,0xffffe
    8000511e:	666080e7          	jalr	1638(ra) # 80003780 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005122:	4601                	li	a2,0
    80005124:	fb040593          	addi	a1,s0,-80
    80005128:	8526                	mv	a0,s1
    8000512a:	fffff097          	auipc	ra,0xfffff
    8000512e:	b3a080e7          	jalr	-1222(ra) # 80003c64 <dirlookup>
    80005132:	8aaa                	mv	s5,a0
    80005134:	c931                	beqz	a0,80005188 <create+0x9a>
    iunlockput(dp);
    80005136:	8526                	mv	a0,s1
    80005138:	fffff097          	auipc	ra,0xfffff
    8000513c:	8aa080e7          	jalr	-1878(ra) # 800039e2 <iunlockput>
    ilock(ip);
    80005140:	8556                	mv	a0,s5
    80005142:	ffffe097          	auipc	ra,0xffffe
    80005146:	63e080e7          	jalr	1598(ra) # 80003780 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    8000514a:	000b059b          	sext.w	a1,s6
    8000514e:	4789                	li	a5,2
    80005150:	02f59563          	bne	a1,a5,8000517a <create+0x8c>
    80005154:	044ad783          	lhu	a5,68(s5) # fffffffffffff044 <end+0xffffffff7ffdd0f4>
    80005158:	37f9                	addiw	a5,a5,-2
    8000515a:	17c2                	slli	a5,a5,0x30
    8000515c:	93c1                	srli	a5,a5,0x30
    8000515e:	4705                	li	a4,1
    80005160:	00f76d63          	bltu	a4,a5,8000517a <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005164:	8556                	mv	a0,s5
    80005166:	60a6                	ld	ra,72(sp)
    80005168:	6406                	ld	s0,64(sp)
    8000516a:	74e2                	ld	s1,56(sp)
    8000516c:	7942                	ld	s2,48(sp)
    8000516e:	79a2                	ld	s3,40(sp)
    80005170:	7a02                	ld	s4,32(sp)
    80005172:	6ae2                	ld	s5,24(sp)
    80005174:	6b42                	ld	s6,16(sp)
    80005176:	6161                	addi	sp,sp,80
    80005178:	8082                	ret
    iunlockput(ip);
    8000517a:	8556                	mv	a0,s5
    8000517c:	fffff097          	auipc	ra,0xfffff
    80005180:	866080e7          	jalr	-1946(ra) # 800039e2 <iunlockput>
    return 0;
    80005184:	4a81                	li	s5,0
    80005186:	bff9                	j	80005164 <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005188:	85da                	mv	a1,s6
    8000518a:	4088                	lw	a0,0(s1)
    8000518c:	ffffe097          	auipc	ra,0xffffe
    80005190:	456080e7          	jalr	1110(ra) # 800035e2 <ialloc>
    80005194:	8a2a                	mv	s4,a0
    80005196:	c539                	beqz	a0,800051e4 <create+0xf6>
  ilock(ip);
    80005198:	ffffe097          	auipc	ra,0xffffe
    8000519c:	5e8080e7          	jalr	1512(ra) # 80003780 <ilock>
  ip->major = major;
    800051a0:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    800051a4:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    800051a8:	4905                	li	s2,1
    800051aa:	052a1523          	sh	s2,74(s4)
  iupdate(ip);
    800051ae:	8552                	mv	a0,s4
    800051b0:	ffffe097          	auipc	ra,0xffffe
    800051b4:	504080e7          	jalr	1284(ra) # 800036b4 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    800051b8:	000b059b          	sext.w	a1,s6
    800051bc:	03258b63          	beq	a1,s2,800051f2 <create+0x104>
  if(dirlink(dp, name, ip->inum) < 0)
    800051c0:	004a2603          	lw	a2,4(s4)
    800051c4:	fb040593          	addi	a1,s0,-80
    800051c8:	8526                	mv	a0,s1
    800051ca:	fffff097          	auipc	ra,0xfffff
    800051ce:	cb0080e7          	jalr	-848(ra) # 80003e7a <dirlink>
    800051d2:	06054f63          	bltz	a0,80005250 <create+0x162>
  iunlockput(dp);
    800051d6:	8526                	mv	a0,s1
    800051d8:	fffff097          	auipc	ra,0xfffff
    800051dc:	80a080e7          	jalr	-2038(ra) # 800039e2 <iunlockput>
  return ip;
    800051e0:	8ad2                	mv	s5,s4
    800051e2:	b749                	j	80005164 <create+0x76>
    iunlockput(dp);
    800051e4:	8526                	mv	a0,s1
    800051e6:	ffffe097          	auipc	ra,0xffffe
    800051ea:	7fc080e7          	jalr	2044(ra) # 800039e2 <iunlockput>
    return 0;
    800051ee:	8ad2                	mv	s5,s4
    800051f0:	bf95                	j	80005164 <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800051f2:	004a2603          	lw	a2,4(s4)
    800051f6:	00003597          	auipc	a1,0x3
    800051fa:	62258593          	addi	a1,a1,1570 # 80008818 <syscalls+0x2f0>
    800051fe:	8552                	mv	a0,s4
    80005200:	fffff097          	auipc	ra,0xfffff
    80005204:	c7a080e7          	jalr	-902(ra) # 80003e7a <dirlink>
    80005208:	04054463          	bltz	a0,80005250 <create+0x162>
    8000520c:	40d0                	lw	a2,4(s1)
    8000520e:	00003597          	auipc	a1,0x3
    80005212:	61258593          	addi	a1,a1,1554 # 80008820 <syscalls+0x2f8>
    80005216:	8552                	mv	a0,s4
    80005218:	fffff097          	auipc	ra,0xfffff
    8000521c:	c62080e7          	jalr	-926(ra) # 80003e7a <dirlink>
    80005220:	02054863          	bltz	a0,80005250 <create+0x162>
  if(dirlink(dp, name, ip->inum) < 0)
    80005224:	004a2603          	lw	a2,4(s4)
    80005228:	fb040593          	addi	a1,s0,-80
    8000522c:	8526                	mv	a0,s1
    8000522e:	fffff097          	auipc	ra,0xfffff
    80005232:	c4c080e7          	jalr	-948(ra) # 80003e7a <dirlink>
    80005236:	00054d63          	bltz	a0,80005250 <create+0x162>
    dp->nlink++;  // for ".."
    8000523a:	04a4d783          	lhu	a5,74(s1)
    8000523e:	2785                	addiw	a5,a5,1
    80005240:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005244:	8526                	mv	a0,s1
    80005246:	ffffe097          	auipc	ra,0xffffe
    8000524a:	46e080e7          	jalr	1134(ra) # 800036b4 <iupdate>
    8000524e:	b761                	j	800051d6 <create+0xe8>
  ip->nlink = 0;
    80005250:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005254:	8552                	mv	a0,s4
    80005256:	ffffe097          	auipc	ra,0xffffe
    8000525a:	45e080e7          	jalr	1118(ra) # 800036b4 <iupdate>
  iunlockput(ip);
    8000525e:	8552                	mv	a0,s4
    80005260:	ffffe097          	auipc	ra,0xffffe
    80005264:	782080e7          	jalr	1922(ra) # 800039e2 <iunlockput>
  iunlockput(dp);
    80005268:	8526                	mv	a0,s1
    8000526a:	ffffe097          	auipc	ra,0xffffe
    8000526e:	778080e7          	jalr	1912(ra) # 800039e2 <iunlockput>
  return 0;
    80005272:	bdcd                	j	80005164 <create+0x76>
    return 0;
    80005274:	8aaa                	mv	s5,a0
    80005276:	b5fd                	j	80005164 <create+0x76>

0000000080005278 <sys_dup>:
{
    80005278:	7179                	addi	sp,sp,-48
    8000527a:	f406                	sd	ra,40(sp)
    8000527c:	f022                	sd	s0,32(sp)
    8000527e:	ec26                	sd	s1,24(sp)
    80005280:	e84a                	sd	s2,16(sp)
    80005282:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005284:	fd840613          	addi	a2,s0,-40
    80005288:	4581                	li	a1,0
    8000528a:	4501                	li	a0,0
    8000528c:	00000097          	auipc	ra,0x0
    80005290:	dc0080e7          	jalr	-576(ra) # 8000504c <argfd>
    return -1;
    80005294:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005296:	02054363          	bltz	a0,800052bc <sys_dup+0x44>
  if((fd=fdalloc(f)) < 0)
    8000529a:	fd843903          	ld	s2,-40(s0)
    8000529e:	854a                	mv	a0,s2
    800052a0:	00000097          	auipc	ra,0x0
    800052a4:	e0c080e7          	jalr	-500(ra) # 800050ac <fdalloc>
    800052a8:	84aa                	mv	s1,a0
    return -1;
    800052aa:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    800052ac:	00054863          	bltz	a0,800052bc <sys_dup+0x44>
  filedup(f);
    800052b0:	854a                	mv	a0,s2
    800052b2:	fffff097          	auipc	ra,0xfffff
    800052b6:	310080e7          	jalr	784(ra) # 800045c2 <filedup>
  return fd;
    800052ba:	87a6                	mv	a5,s1
}
    800052bc:	853e                	mv	a0,a5
    800052be:	70a2                	ld	ra,40(sp)
    800052c0:	7402                	ld	s0,32(sp)
    800052c2:	64e2                	ld	s1,24(sp)
    800052c4:	6942                	ld	s2,16(sp)
    800052c6:	6145                	addi	sp,sp,48
    800052c8:	8082                	ret

00000000800052ca <sys_read>:
{
    800052ca:	7179                	addi	sp,sp,-48
    800052cc:	f406                	sd	ra,40(sp)
    800052ce:	f022                	sd	s0,32(sp)
    800052d0:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    800052d2:	fd840593          	addi	a1,s0,-40
    800052d6:	4505                	li	a0,1
    800052d8:	ffffe097          	auipc	ra,0xffffe
    800052dc:	8ae080e7          	jalr	-1874(ra) # 80002b86 <argaddr>
  argint(2, &n);
    800052e0:	fe440593          	addi	a1,s0,-28
    800052e4:	4509                	li	a0,2
    800052e6:	ffffe097          	auipc	ra,0xffffe
    800052ea:	880080e7          	jalr	-1920(ra) # 80002b66 <argint>
  if(argfd(0, 0, &f) < 0)
    800052ee:	fe840613          	addi	a2,s0,-24
    800052f2:	4581                	li	a1,0
    800052f4:	4501                	li	a0,0
    800052f6:	00000097          	auipc	ra,0x0
    800052fa:	d56080e7          	jalr	-682(ra) # 8000504c <argfd>
    800052fe:	87aa                	mv	a5,a0
    return -1;
    80005300:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005302:	0007cc63          	bltz	a5,8000531a <sys_read+0x50>
  return fileread(f, p, n);
    80005306:	fe442603          	lw	a2,-28(s0)
    8000530a:	fd843583          	ld	a1,-40(s0)
    8000530e:	fe843503          	ld	a0,-24(s0)
    80005312:	fffff097          	auipc	ra,0xfffff
    80005316:	43c080e7          	jalr	1084(ra) # 8000474e <fileread>
}
    8000531a:	70a2                	ld	ra,40(sp)
    8000531c:	7402                	ld	s0,32(sp)
    8000531e:	6145                	addi	sp,sp,48
    80005320:	8082                	ret

0000000080005322 <sys_write>:
{
    80005322:	7179                	addi	sp,sp,-48
    80005324:	f406                	sd	ra,40(sp)
    80005326:	f022                	sd	s0,32(sp)
    80005328:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    8000532a:	fd840593          	addi	a1,s0,-40
    8000532e:	4505                	li	a0,1
    80005330:	ffffe097          	auipc	ra,0xffffe
    80005334:	856080e7          	jalr	-1962(ra) # 80002b86 <argaddr>
  argint(2, &n);
    80005338:	fe440593          	addi	a1,s0,-28
    8000533c:	4509                	li	a0,2
    8000533e:	ffffe097          	auipc	ra,0xffffe
    80005342:	828080e7          	jalr	-2008(ra) # 80002b66 <argint>
  if(argfd(0, 0, &f) < 0)
    80005346:	fe840613          	addi	a2,s0,-24
    8000534a:	4581                	li	a1,0
    8000534c:	4501                	li	a0,0
    8000534e:	00000097          	auipc	ra,0x0
    80005352:	cfe080e7          	jalr	-770(ra) # 8000504c <argfd>
    80005356:	87aa                	mv	a5,a0
    return -1;
    80005358:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    8000535a:	0007cc63          	bltz	a5,80005372 <sys_write+0x50>
  return filewrite(f, p, n);
    8000535e:	fe442603          	lw	a2,-28(s0)
    80005362:	fd843583          	ld	a1,-40(s0)
    80005366:	fe843503          	ld	a0,-24(s0)
    8000536a:	fffff097          	auipc	ra,0xfffff
    8000536e:	4a6080e7          	jalr	1190(ra) # 80004810 <filewrite>
}
    80005372:	70a2                	ld	ra,40(sp)
    80005374:	7402                	ld	s0,32(sp)
    80005376:	6145                	addi	sp,sp,48
    80005378:	8082                	ret

000000008000537a <sys_close>:
{
    8000537a:	1101                	addi	sp,sp,-32
    8000537c:	ec06                	sd	ra,24(sp)
    8000537e:	e822                	sd	s0,16(sp)
    80005380:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005382:	fe040613          	addi	a2,s0,-32
    80005386:	fec40593          	addi	a1,s0,-20
    8000538a:	4501                	li	a0,0
    8000538c:	00000097          	auipc	ra,0x0
    80005390:	cc0080e7          	jalr	-832(ra) # 8000504c <argfd>
    return -1;
    80005394:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005396:	02054463          	bltz	a0,800053be <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    8000539a:	ffffc097          	auipc	ra,0xffffc
    8000539e:	65c080e7          	jalr	1628(ra) # 800019f6 <myproc>
    800053a2:	fec42783          	lw	a5,-20(s0)
    800053a6:	07e9                	addi	a5,a5,26
    800053a8:	078e                	slli	a5,a5,0x3
    800053aa:	953e                	add	a0,a0,a5
    800053ac:	00053023          	sd	zero,0(a0)
  fileclose(f);
    800053b0:	fe043503          	ld	a0,-32(s0)
    800053b4:	fffff097          	auipc	ra,0xfffff
    800053b8:	260080e7          	jalr	608(ra) # 80004614 <fileclose>
  return 0;
    800053bc:	4781                	li	a5,0
}
    800053be:	853e                	mv	a0,a5
    800053c0:	60e2                	ld	ra,24(sp)
    800053c2:	6442                	ld	s0,16(sp)
    800053c4:	6105                	addi	sp,sp,32
    800053c6:	8082                	ret

00000000800053c8 <sys_fstat>:
{
    800053c8:	1101                	addi	sp,sp,-32
    800053ca:	ec06                	sd	ra,24(sp)
    800053cc:	e822                	sd	s0,16(sp)
    800053ce:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    800053d0:	fe040593          	addi	a1,s0,-32
    800053d4:	4505                	li	a0,1
    800053d6:	ffffd097          	auipc	ra,0xffffd
    800053da:	7b0080e7          	jalr	1968(ra) # 80002b86 <argaddr>
  if(argfd(0, 0, &f) < 0)
    800053de:	fe840613          	addi	a2,s0,-24
    800053e2:	4581                	li	a1,0
    800053e4:	4501                	li	a0,0
    800053e6:	00000097          	auipc	ra,0x0
    800053ea:	c66080e7          	jalr	-922(ra) # 8000504c <argfd>
    800053ee:	87aa                	mv	a5,a0
    return -1;
    800053f0:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    800053f2:	0007ca63          	bltz	a5,80005406 <sys_fstat+0x3e>
  return filestat(f, st);
    800053f6:	fe043583          	ld	a1,-32(s0)
    800053fa:	fe843503          	ld	a0,-24(s0)
    800053fe:	fffff097          	auipc	ra,0xfffff
    80005402:	2de080e7          	jalr	734(ra) # 800046dc <filestat>
}
    80005406:	60e2                	ld	ra,24(sp)
    80005408:	6442                	ld	s0,16(sp)
    8000540a:	6105                	addi	sp,sp,32
    8000540c:	8082                	ret

000000008000540e <sys_link>:
{
    8000540e:	7169                	addi	sp,sp,-304
    80005410:	f606                	sd	ra,296(sp)
    80005412:	f222                	sd	s0,288(sp)
    80005414:	ee26                	sd	s1,280(sp)
    80005416:	ea4a                	sd	s2,272(sp)
    80005418:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000541a:	08000613          	li	a2,128
    8000541e:	ed040593          	addi	a1,s0,-304
    80005422:	4501                	li	a0,0
    80005424:	ffffd097          	auipc	ra,0xffffd
    80005428:	782080e7          	jalr	1922(ra) # 80002ba6 <argstr>
    return -1;
    8000542c:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000542e:	10054e63          	bltz	a0,8000554a <sys_link+0x13c>
    80005432:	08000613          	li	a2,128
    80005436:	f5040593          	addi	a1,s0,-176
    8000543a:	4505                	li	a0,1
    8000543c:	ffffd097          	auipc	ra,0xffffd
    80005440:	76a080e7          	jalr	1898(ra) # 80002ba6 <argstr>
    return -1;
    80005444:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005446:	10054263          	bltz	a0,8000554a <sys_link+0x13c>
  begin_op();
    8000544a:	fffff097          	auipc	ra,0xfffff
    8000544e:	d02080e7          	jalr	-766(ra) # 8000414c <begin_op>
  if((ip = namei(old)) == 0){
    80005452:	ed040513          	addi	a0,s0,-304
    80005456:	fffff097          	auipc	ra,0xfffff
    8000545a:	ad6080e7          	jalr	-1322(ra) # 80003f2c <namei>
    8000545e:	84aa                	mv	s1,a0
    80005460:	c551                	beqz	a0,800054ec <sys_link+0xde>
  ilock(ip);
    80005462:	ffffe097          	auipc	ra,0xffffe
    80005466:	31e080e7          	jalr	798(ra) # 80003780 <ilock>
  if(ip->type == T_DIR){
    8000546a:	04449703          	lh	a4,68(s1)
    8000546e:	4785                	li	a5,1
    80005470:	08f70463          	beq	a4,a5,800054f8 <sys_link+0xea>
  ip->nlink++;
    80005474:	04a4d783          	lhu	a5,74(s1)
    80005478:	2785                	addiw	a5,a5,1
    8000547a:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000547e:	8526                	mv	a0,s1
    80005480:	ffffe097          	auipc	ra,0xffffe
    80005484:	234080e7          	jalr	564(ra) # 800036b4 <iupdate>
  iunlock(ip);
    80005488:	8526                	mv	a0,s1
    8000548a:	ffffe097          	auipc	ra,0xffffe
    8000548e:	3b8080e7          	jalr	952(ra) # 80003842 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005492:	fd040593          	addi	a1,s0,-48
    80005496:	f5040513          	addi	a0,s0,-176
    8000549a:	fffff097          	auipc	ra,0xfffff
    8000549e:	ab0080e7          	jalr	-1360(ra) # 80003f4a <nameiparent>
    800054a2:	892a                	mv	s2,a0
    800054a4:	c935                	beqz	a0,80005518 <sys_link+0x10a>
  ilock(dp);
    800054a6:	ffffe097          	auipc	ra,0xffffe
    800054aa:	2da080e7          	jalr	730(ra) # 80003780 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    800054ae:	00092703          	lw	a4,0(s2)
    800054b2:	409c                	lw	a5,0(s1)
    800054b4:	04f71d63          	bne	a4,a5,8000550e <sys_link+0x100>
    800054b8:	40d0                	lw	a2,4(s1)
    800054ba:	fd040593          	addi	a1,s0,-48
    800054be:	854a                	mv	a0,s2
    800054c0:	fffff097          	auipc	ra,0xfffff
    800054c4:	9ba080e7          	jalr	-1606(ra) # 80003e7a <dirlink>
    800054c8:	04054363          	bltz	a0,8000550e <sys_link+0x100>
  iunlockput(dp);
    800054cc:	854a                	mv	a0,s2
    800054ce:	ffffe097          	auipc	ra,0xffffe
    800054d2:	514080e7          	jalr	1300(ra) # 800039e2 <iunlockput>
  iput(ip);
    800054d6:	8526                	mv	a0,s1
    800054d8:	ffffe097          	auipc	ra,0xffffe
    800054dc:	462080e7          	jalr	1122(ra) # 8000393a <iput>
  end_op();
    800054e0:	fffff097          	auipc	ra,0xfffff
    800054e4:	cea080e7          	jalr	-790(ra) # 800041ca <end_op>
  return 0;
    800054e8:	4781                	li	a5,0
    800054ea:	a085                	j	8000554a <sys_link+0x13c>
    end_op();
    800054ec:	fffff097          	auipc	ra,0xfffff
    800054f0:	cde080e7          	jalr	-802(ra) # 800041ca <end_op>
    return -1;
    800054f4:	57fd                	li	a5,-1
    800054f6:	a891                	j	8000554a <sys_link+0x13c>
    iunlockput(ip);
    800054f8:	8526                	mv	a0,s1
    800054fa:	ffffe097          	auipc	ra,0xffffe
    800054fe:	4e8080e7          	jalr	1256(ra) # 800039e2 <iunlockput>
    end_op();
    80005502:	fffff097          	auipc	ra,0xfffff
    80005506:	cc8080e7          	jalr	-824(ra) # 800041ca <end_op>
    return -1;
    8000550a:	57fd                	li	a5,-1
    8000550c:	a83d                	j	8000554a <sys_link+0x13c>
    iunlockput(dp);
    8000550e:	854a                	mv	a0,s2
    80005510:	ffffe097          	auipc	ra,0xffffe
    80005514:	4d2080e7          	jalr	1234(ra) # 800039e2 <iunlockput>
  ilock(ip);
    80005518:	8526                	mv	a0,s1
    8000551a:	ffffe097          	auipc	ra,0xffffe
    8000551e:	266080e7          	jalr	614(ra) # 80003780 <ilock>
  ip->nlink--;
    80005522:	04a4d783          	lhu	a5,74(s1)
    80005526:	37fd                	addiw	a5,a5,-1
    80005528:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    8000552c:	8526                	mv	a0,s1
    8000552e:	ffffe097          	auipc	ra,0xffffe
    80005532:	186080e7          	jalr	390(ra) # 800036b4 <iupdate>
  iunlockput(ip);
    80005536:	8526                	mv	a0,s1
    80005538:	ffffe097          	auipc	ra,0xffffe
    8000553c:	4aa080e7          	jalr	1194(ra) # 800039e2 <iunlockput>
  end_op();
    80005540:	fffff097          	auipc	ra,0xfffff
    80005544:	c8a080e7          	jalr	-886(ra) # 800041ca <end_op>
  return -1;
    80005548:	57fd                	li	a5,-1
}
    8000554a:	853e                	mv	a0,a5
    8000554c:	70b2                	ld	ra,296(sp)
    8000554e:	7412                	ld	s0,288(sp)
    80005550:	64f2                	ld	s1,280(sp)
    80005552:	6952                	ld	s2,272(sp)
    80005554:	6155                	addi	sp,sp,304
    80005556:	8082                	ret

0000000080005558 <sys_unlink>:
{
    80005558:	7151                	addi	sp,sp,-240
    8000555a:	f586                	sd	ra,232(sp)
    8000555c:	f1a2                	sd	s0,224(sp)
    8000555e:	eda6                	sd	s1,216(sp)
    80005560:	e9ca                	sd	s2,208(sp)
    80005562:	e5ce                	sd	s3,200(sp)
    80005564:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    80005566:	08000613          	li	a2,128
    8000556a:	f3040593          	addi	a1,s0,-208
    8000556e:	4501                	li	a0,0
    80005570:	ffffd097          	auipc	ra,0xffffd
    80005574:	636080e7          	jalr	1590(ra) # 80002ba6 <argstr>
    80005578:	18054163          	bltz	a0,800056fa <sys_unlink+0x1a2>
  begin_op();
    8000557c:	fffff097          	auipc	ra,0xfffff
    80005580:	bd0080e7          	jalr	-1072(ra) # 8000414c <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    80005584:	fb040593          	addi	a1,s0,-80
    80005588:	f3040513          	addi	a0,s0,-208
    8000558c:	fffff097          	auipc	ra,0xfffff
    80005590:	9be080e7          	jalr	-1602(ra) # 80003f4a <nameiparent>
    80005594:	84aa                	mv	s1,a0
    80005596:	c979                	beqz	a0,8000566c <sys_unlink+0x114>
  ilock(dp);
    80005598:	ffffe097          	auipc	ra,0xffffe
    8000559c:	1e8080e7          	jalr	488(ra) # 80003780 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    800055a0:	00003597          	auipc	a1,0x3
    800055a4:	27858593          	addi	a1,a1,632 # 80008818 <syscalls+0x2f0>
    800055a8:	fb040513          	addi	a0,s0,-80
    800055ac:	ffffe097          	auipc	ra,0xffffe
    800055b0:	69e080e7          	jalr	1694(ra) # 80003c4a <namecmp>
    800055b4:	14050a63          	beqz	a0,80005708 <sys_unlink+0x1b0>
    800055b8:	00003597          	auipc	a1,0x3
    800055bc:	26858593          	addi	a1,a1,616 # 80008820 <syscalls+0x2f8>
    800055c0:	fb040513          	addi	a0,s0,-80
    800055c4:	ffffe097          	auipc	ra,0xffffe
    800055c8:	686080e7          	jalr	1670(ra) # 80003c4a <namecmp>
    800055cc:	12050e63          	beqz	a0,80005708 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    800055d0:	f2c40613          	addi	a2,s0,-212
    800055d4:	fb040593          	addi	a1,s0,-80
    800055d8:	8526                	mv	a0,s1
    800055da:	ffffe097          	auipc	ra,0xffffe
    800055de:	68a080e7          	jalr	1674(ra) # 80003c64 <dirlookup>
    800055e2:	892a                	mv	s2,a0
    800055e4:	12050263          	beqz	a0,80005708 <sys_unlink+0x1b0>
  ilock(ip);
    800055e8:	ffffe097          	auipc	ra,0xffffe
    800055ec:	198080e7          	jalr	408(ra) # 80003780 <ilock>
  if(ip->nlink < 1)
    800055f0:	04a91783          	lh	a5,74(s2)
    800055f4:	08f05263          	blez	a5,80005678 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800055f8:	04491703          	lh	a4,68(s2)
    800055fc:	4785                	li	a5,1
    800055fe:	08f70563          	beq	a4,a5,80005688 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    80005602:	4641                	li	a2,16
    80005604:	4581                	li	a1,0
    80005606:	fc040513          	addi	a0,s0,-64
    8000560a:	ffffb097          	auipc	ra,0xffffb
    8000560e:	712080e7          	jalr	1810(ra) # 80000d1c <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005612:	4741                	li	a4,16
    80005614:	f2c42683          	lw	a3,-212(s0)
    80005618:	fc040613          	addi	a2,s0,-64
    8000561c:	4581                	li	a1,0
    8000561e:	8526                	mv	a0,s1
    80005620:	ffffe097          	auipc	ra,0xffffe
    80005624:	50c080e7          	jalr	1292(ra) # 80003b2c <writei>
    80005628:	47c1                	li	a5,16
    8000562a:	0af51563          	bne	a0,a5,800056d4 <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    8000562e:	04491703          	lh	a4,68(s2)
    80005632:	4785                	li	a5,1
    80005634:	0af70863          	beq	a4,a5,800056e4 <sys_unlink+0x18c>
  iunlockput(dp);
    80005638:	8526                	mv	a0,s1
    8000563a:	ffffe097          	auipc	ra,0xffffe
    8000563e:	3a8080e7          	jalr	936(ra) # 800039e2 <iunlockput>
  ip->nlink--;
    80005642:	04a95783          	lhu	a5,74(s2)
    80005646:	37fd                	addiw	a5,a5,-1
    80005648:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    8000564c:	854a                	mv	a0,s2
    8000564e:	ffffe097          	auipc	ra,0xffffe
    80005652:	066080e7          	jalr	102(ra) # 800036b4 <iupdate>
  iunlockput(ip);
    80005656:	854a                	mv	a0,s2
    80005658:	ffffe097          	auipc	ra,0xffffe
    8000565c:	38a080e7          	jalr	906(ra) # 800039e2 <iunlockput>
  end_op();
    80005660:	fffff097          	auipc	ra,0xfffff
    80005664:	b6a080e7          	jalr	-1174(ra) # 800041ca <end_op>
  return 0;
    80005668:	4501                	li	a0,0
    8000566a:	a84d                	j	8000571c <sys_unlink+0x1c4>
    end_op();
    8000566c:	fffff097          	auipc	ra,0xfffff
    80005670:	b5e080e7          	jalr	-1186(ra) # 800041ca <end_op>
    return -1;
    80005674:	557d                	li	a0,-1
    80005676:	a05d                	j	8000571c <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005678:	00003517          	auipc	a0,0x3
    8000567c:	1b050513          	addi	a0,a0,432 # 80008828 <syscalls+0x300>
    80005680:	ffffb097          	auipc	ra,0xffffb
    80005684:	ec0080e7          	jalr	-320(ra) # 80000540 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005688:	04c92703          	lw	a4,76(s2)
    8000568c:	02000793          	li	a5,32
    80005690:	f6e7f9e3          	bgeu	a5,a4,80005602 <sys_unlink+0xaa>
    80005694:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005698:	4741                	li	a4,16
    8000569a:	86ce                	mv	a3,s3
    8000569c:	f1840613          	addi	a2,s0,-232
    800056a0:	4581                	li	a1,0
    800056a2:	854a                	mv	a0,s2
    800056a4:	ffffe097          	auipc	ra,0xffffe
    800056a8:	390080e7          	jalr	912(ra) # 80003a34 <readi>
    800056ac:	47c1                	li	a5,16
    800056ae:	00f51b63          	bne	a0,a5,800056c4 <sys_unlink+0x16c>
    if(de.inum != 0)
    800056b2:	f1845783          	lhu	a5,-232(s0)
    800056b6:	e7a1                	bnez	a5,800056fe <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    800056b8:	29c1                	addiw	s3,s3,16
    800056ba:	04c92783          	lw	a5,76(s2)
    800056be:	fcf9ede3          	bltu	s3,a5,80005698 <sys_unlink+0x140>
    800056c2:	b781                	j	80005602 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    800056c4:	00003517          	auipc	a0,0x3
    800056c8:	17c50513          	addi	a0,a0,380 # 80008840 <syscalls+0x318>
    800056cc:	ffffb097          	auipc	ra,0xffffb
    800056d0:	e74080e7          	jalr	-396(ra) # 80000540 <panic>
    panic("unlink: writei");
    800056d4:	00003517          	auipc	a0,0x3
    800056d8:	18450513          	addi	a0,a0,388 # 80008858 <syscalls+0x330>
    800056dc:	ffffb097          	auipc	ra,0xffffb
    800056e0:	e64080e7          	jalr	-412(ra) # 80000540 <panic>
    dp->nlink--;
    800056e4:	04a4d783          	lhu	a5,74(s1)
    800056e8:	37fd                	addiw	a5,a5,-1
    800056ea:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    800056ee:	8526                	mv	a0,s1
    800056f0:	ffffe097          	auipc	ra,0xffffe
    800056f4:	fc4080e7          	jalr	-60(ra) # 800036b4 <iupdate>
    800056f8:	b781                	j	80005638 <sys_unlink+0xe0>
    return -1;
    800056fa:	557d                	li	a0,-1
    800056fc:	a005                	j	8000571c <sys_unlink+0x1c4>
    iunlockput(ip);
    800056fe:	854a                	mv	a0,s2
    80005700:	ffffe097          	auipc	ra,0xffffe
    80005704:	2e2080e7          	jalr	738(ra) # 800039e2 <iunlockput>
  iunlockput(dp);
    80005708:	8526                	mv	a0,s1
    8000570a:	ffffe097          	auipc	ra,0xffffe
    8000570e:	2d8080e7          	jalr	728(ra) # 800039e2 <iunlockput>
  end_op();
    80005712:	fffff097          	auipc	ra,0xfffff
    80005716:	ab8080e7          	jalr	-1352(ra) # 800041ca <end_op>
  return -1;
    8000571a:	557d                	li	a0,-1
}
    8000571c:	70ae                	ld	ra,232(sp)
    8000571e:	740e                	ld	s0,224(sp)
    80005720:	64ee                	ld	s1,216(sp)
    80005722:	694e                	ld	s2,208(sp)
    80005724:	69ae                	ld	s3,200(sp)
    80005726:	616d                	addi	sp,sp,240
    80005728:	8082                	ret

000000008000572a <sys_open>:

uint64
sys_open(void)
{
    8000572a:	7131                	addi	sp,sp,-192
    8000572c:	fd06                	sd	ra,184(sp)
    8000572e:	f922                	sd	s0,176(sp)
    80005730:	f526                	sd	s1,168(sp)
    80005732:	f14a                	sd	s2,160(sp)
    80005734:	ed4e                	sd	s3,152(sp)
    80005736:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    80005738:	f4c40593          	addi	a1,s0,-180
    8000573c:	4505                	li	a0,1
    8000573e:	ffffd097          	auipc	ra,0xffffd
    80005742:	428080e7          	jalr	1064(ra) # 80002b66 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    80005746:	08000613          	li	a2,128
    8000574a:	f5040593          	addi	a1,s0,-176
    8000574e:	4501                	li	a0,0
    80005750:	ffffd097          	auipc	ra,0xffffd
    80005754:	456080e7          	jalr	1110(ra) # 80002ba6 <argstr>
    80005758:	87aa                	mv	a5,a0
    return -1;
    8000575a:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    8000575c:	0a07c963          	bltz	a5,8000580e <sys_open+0xe4>

  begin_op();
    80005760:	fffff097          	auipc	ra,0xfffff
    80005764:	9ec080e7          	jalr	-1556(ra) # 8000414c <begin_op>

  if(omode & O_CREATE){
    80005768:	f4c42783          	lw	a5,-180(s0)
    8000576c:	2007f793          	andi	a5,a5,512
    80005770:	cfc5                	beqz	a5,80005828 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005772:	4681                	li	a3,0
    80005774:	4601                	li	a2,0
    80005776:	4589                	li	a1,2
    80005778:	f5040513          	addi	a0,s0,-176
    8000577c:	00000097          	auipc	ra,0x0
    80005780:	972080e7          	jalr	-1678(ra) # 800050ee <create>
    80005784:	84aa                	mv	s1,a0
    if(ip == 0){
    80005786:	c959                	beqz	a0,8000581c <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005788:	04449703          	lh	a4,68(s1)
    8000578c:	478d                	li	a5,3
    8000578e:	00f71763          	bne	a4,a5,8000579c <sys_open+0x72>
    80005792:	0464d703          	lhu	a4,70(s1)
    80005796:	47a5                	li	a5,9
    80005798:	0ce7ed63          	bltu	a5,a4,80005872 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    8000579c:	fffff097          	auipc	ra,0xfffff
    800057a0:	dbc080e7          	jalr	-580(ra) # 80004558 <filealloc>
    800057a4:	89aa                	mv	s3,a0
    800057a6:	10050363          	beqz	a0,800058ac <sys_open+0x182>
    800057aa:	00000097          	auipc	ra,0x0
    800057ae:	902080e7          	jalr	-1790(ra) # 800050ac <fdalloc>
    800057b2:	892a                	mv	s2,a0
    800057b4:	0e054763          	bltz	a0,800058a2 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    800057b8:	04449703          	lh	a4,68(s1)
    800057bc:	478d                	li	a5,3
    800057be:	0cf70563          	beq	a4,a5,80005888 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    800057c2:	4789                	li	a5,2
    800057c4:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    800057c8:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    800057cc:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    800057d0:	f4c42783          	lw	a5,-180(s0)
    800057d4:	0017c713          	xori	a4,a5,1
    800057d8:	8b05                	andi	a4,a4,1
    800057da:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    800057de:	0037f713          	andi	a4,a5,3
    800057e2:	00e03733          	snez	a4,a4
    800057e6:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    800057ea:	4007f793          	andi	a5,a5,1024
    800057ee:	c791                	beqz	a5,800057fa <sys_open+0xd0>
    800057f0:	04449703          	lh	a4,68(s1)
    800057f4:	4789                	li	a5,2
    800057f6:	0af70063          	beq	a4,a5,80005896 <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    800057fa:	8526                	mv	a0,s1
    800057fc:	ffffe097          	auipc	ra,0xffffe
    80005800:	046080e7          	jalr	70(ra) # 80003842 <iunlock>
  end_op();
    80005804:	fffff097          	auipc	ra,0xfffff
    80005808:	9c6080e7          	jalr	-1594(ra) # 800041ca <end_op>

  return fd;
    8000580c:	854a                	mv	a0,s2
}
    8000580e:	70ea                	ld	ra,184(sp)
    80005810:	744a                	ld	s0,176(sp)
    80005812:	74aa                	ld	s1,168(sp)
    80005814:	790a                	ld	s2,160(sp)
    80005816:	69ea                	ld	s3,152(sp)
    80005818:	6129                	addi	sp,sp,192
    8000581a:	8082                	ret
      end_op();
    8000581c:	fffff097          	auipc	ra,0xfffff
    80005820:	9ae080e7          	jalr	-1618(ra) # 800041ca <end_op>
      return -1;
    80005824:	557d                	li	a0,-1
    80005826:	b7e5                	j	8000580e <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005828:	f5040513          	addi	a0,s0,-176
    8000582c:	ffffe097          	auipc	ra,0xffffe
    80005830:	700080e7          	jalr	1792(ra) # 80003f2c <namei>
    80005834:	84aa                	mv	s1,a0
    80005836:	c905                	beqz	a0,80005866 <sys_open+0x13c>
    ilock(ip);
    80005838:	ffffe097          	auipc	ra,0xffffe
    8000583c:	f48080e7          	jalr	-184(ra) # 80003780 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005840:	04449703          	lh	a4,68(s1)
    80005844:	4785                	li	a5,1
    80005846:	f4f711e3          	bne	a4,a5,80005788 <sys_open+0x5e>
    8000584a:	f4c42783          	lw	a5,-180(s0)
    8000584e:	d7b9                	beqz	a5,8000579c <sys_open+0x72>
      iunlockput(ip);
    80005850:	8526                	mv	a0,s1
    80005852:	ffffe097          	auipc	ra,0xffffe
    80005856:	190080e7          	jalr	400(ra) # 800039e2 <iunlockput>
      end_op();
    8000585a:	fffff097          	auipc	ra,0xfffff
    8000585e:	970080e7          	jalr	-1680(ra) # 800041ca <end_op>
      return -1;
    80005862:	557d                	li	a0,-1
    80005864:	b76d                	j	8000580e <sys_open+0xe4>
      end_op();
    80005866:	fffff097          	auipc	ra,0xfffff
    8000586a:	964080e7          	jalr	-1692(ra) # 800041ca <end_op>
      return -1;
    8000586e:	557d                	li	a0,-1
    80005870:	bf79                	j	8000580e <sys_open+0xe4>
    iunlockput(ip);
    80005872:	8526                	mv	a0,s1
    80005874:	ffffe097          	auipc	ra,0xffffe
    80005878:	16e080e7          	jalr	366(ra) # 800039e2 <iunlockput>
    end_op();
    8000587c:	fffff097          	auipc	ra,0xfffff
    80005880:	94e080e7          	jalr	-1714(ra) # 800041ca <end_op>
    return -1;
    80005884:	557d                	li	a0,-1
    80005886:	b761                	j	8000580e <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005888:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    8000588c:	04649783          	lh	a5,70(s1)
    80005890:	02f99223          	sh	a5,36(s3)
    80005894:	bf25                	j	800057cc <sys_open+0xa2>
    itrunc(ip);
    80005896:	8526                	mv	a0,s1
    80005898:	ffffe097          	auipc	ra,0xffffe
    8000589c:	ff6080e7          	jalr	-10(ra) # 8000388e <itrunc>
    800058a0:	bfa9                	j	800057fa <sys_open+0xd0>
      fileclose(f);
    800058a2:	854e                	mv	a0,s3
    800058a4:	fffff097          	auipc	ra,0xfffff
    800058a8:	d70080e7          	jalr	-656(ra) # 80004614 <fileclose>
    iunlockput(ip);
    800058ac:	8526                	mv	a0,s1
    800058ae:	ffffe097          	auipc	ra,0xffffe
    800058b2:	134080e7          	jalr	308(ra) # 800039e2 <iunlockput>
    end_op();
    800058b6:	fffff097          	auipc	ra,0xfffff
    800058ba:	914080e7          	jalr	-1772(ra) # 800041ca <end_op>
    return -1;
    800058be:	557d                	li	a0,-1
    800058c0:	b7b9                	j	8000580e <sys_open+0xe4>

00000000800058c2 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    800058c2:	7175                	addi	sp,sp,-144
    800058c4:	e506                	sd	ra,136(sp)
    800058c6:	e122                	sd	s0,128(sp)
    800058c8:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    800058ca:	fffff097          	auipc	ra,0xfffff
    800058ce:	882080e7          	jalr	-1918(ra) # 8000414c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    800058d2:	08000613          	li	a2,128
    800058d6:	f7040593          	addi	a1,s0,-144
    800058da:	4501                	li	a0,0
    800058dc:	ffffd097          	auipc	ra,0xffffd
    800058e0:	2ca080e7          	jalr	714(ra) # 80002ba6 <argstr>
    800058e4:	02054963          	bltz	a0,80005916 <sys_mkdir+0x54>
    800058e8:	4681                	li	a3,0
    800058ea:	4601                	li	a2,0
    800058ec:	4585                	li	a1,1
    800058ee:	f7040513          	addi	a0,s0,-144
    800058f2:	fffff097          	auipc	ra,0xfffff
    800058f6:	7fc080e7          	jalr	2044(ra) # 800050ee <create>
    800058fa:	cd11                	beqz	a0,80005916 <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    800058fc:	ffffe097          	auipc	ra,0xffffe
    80005900:	0e6080e7          	jalr	230(ra) # 800039e2 <iunlockput>
  end_op();
    80005904:	fffff097          	auipc	ra,0xfffff
    80005908:	8c6080e7          	jalr	-1850(ra) # 800041ca <end_op>
  return 0;
    8000590c:	4501                	li	a0,0
}
    8000590e:	60aa                	ld	ra,136(sp)
    80005910:	640a                	ld	s0,128(sp)
    80005912:	6149                	addi	sp,sp,144
    80005914:	8082                	ret
    end_op();
    80005916:	fffff097          	auipc	ra,0xfffff
    8000591a:	8b4080e7          	jalr	-1868(ra) # 800041ca <end_op>
    return -1;
    8000591e:	557d                	li	a0,-1
    80005920:	b7fd                	j	8000590e <sys_mkdir+0x4c>

0000000080005922 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005922:	7135                	addi	sp,sp,-160
    80005924:	ed06                	sd	ra,152(sp)
    80005926:	e922                	sd	s0,144(sp)
    80005928:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    8000592a:	fffff097          	auipc	ra,0xfffff
    8000592e:	822080e7          	jalr	-2014(ra) # 8000414c <begin_op>
  argint(1, &major);
    80005932:	f6c40593          	addi	a1,s0,-148
    80005936:	4505                	li	a0,1
    80005938:	ffffd097          	auipc	ra,0xffffd
    8000593c:	22e080e7          	jalr	558(ra) # 80002b66 <argint>
  argint(2, &minor);
    80005940:	f6840593          	addi	a1,s0,-152
    80005944:	4509                	li	a0,2
    80005946:	ffffd097          	auipc	ra,0xffffd
    8000594a:	220080e7          	jalr	544(ra) # 80002b66 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000594e:	08000613          	li	a2,128
    80005952:	f7040593          	addi	a1,s0,-144
    80005956:	4501                	li	a0,0
    80005958:	ffffd097          	auipc	ra,0xffffd
    8000595c:	24e080e7          	jalr	590(ra) # 80002ba6 <argstr>
    80005960:	02054b63          	bltz	a0,80005996 <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005964:	f6841683          	lh	a3,-152(s0)
    80005968:	f6c41603          	lh	a2,-148(s0)
    8000596c:	458d                	li	a1,3
    8000596e:	f7040513          	addi	a0,s0,-144
    80005972:	fffff097          	auipc	ra,0xfffff
    80005976:	77c080e7          	jalr	1916(ra) # 800050ee <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    8000597a:	cd11                	beqz	a0,80005996 <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    8000597c:	ffffe097          	auipc	ra,0xffffe
    80005980:	066080e7          	jalr	102(ra) # 800039e2 <iunlockput>
  end_op();
    80005984:	fffff097          	auipc	ra,0xfffff
    80005988:	846080e7          	jalr	-1978(ra) # 800041ca <end_op>
  return 0;
    8000598c:	4501                	li	a0,0
}
    8000598e:	60ea                	ld	ra,152(sp)
    80005990:	644a                	ld	s0,144(sp)
    80005992:	610d                	addi	sp,sp,160
    80005994:	8082                	ret
    end_op();
    80005996:	fffff097          	auipc	ra,0xfffff
    8000599a:	834080e7          	jalr	-1996(ra) # 800041ca <end_op>
    return -1;
    8000599e:	557d                	li	a0,-1
    800059a0:	b7fd                	j	8000598e <sys_mknod+0x6c>

00000000800059a2 <sys_chdir>:

uint64
sys_chdir(void)
{
    800059a2:	7135                	addi	sp,sp,-160
    800059a4:	ed06                	sd	ra,152(sp)
    800059a6:	e922                	sd	s0,144(sp)
    800059a8:	e526                	sd	s1,136(sp)
    800059aa:	e14a                	sd	s2,128(sp)
    800059ac:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    800059ae:	ffffc097          	auipc	ra,0xffffc
    800059b2:	048080e7          	jalr	72(ra) # 800019f6 <myproc>
    800059b6:	892a                	mv	s2,a0
  
  begin_op();
    800059b8:	ffffe097          	auipc	ra,0xffffe
    800059bc:	794080e7          	jalr	1940(ra) # 8000414c <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    800059c0:	08000613          	li	a2,128
    800059c4:	f6040593          	addi	a1,s0,-160
    800059c8:	4501                	li	a0,0
    800059ca:	ffffd097          	auipc	ra,0xffffd
    800059ce:	1dc080e7          	jalr	476(ra) # 80002ba6 <argstr>
    800059d2:	04054b63          	bltz	a0,80005a28 <sys_chdir+0x86>
    800059d6:	f6040513          	addi	a0,s0,-160
    800059da:	ffffe097          	auipc	ra,0xffffe
    800059de:	552080e7          	jalr	1362(ra) # 80003f2c <namei>
    800059e2:	84aa                	mv	s1,a0
    800059e4:	c131                	beqz	a0,80005a28 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    800059e6:	ffffe097          	auipc	ra,0xffffe
    800059ea:	d9a080e7          	jalr	-614(ra) # 80003780 <ilock>
  if(ip->type != T_DIR){
    800059ee:	04449703          	lh	a4,68(s1)
    800059f2:	4785                	li	a5,1
    800059f4:	04f71063          	bne	a4,a5,80005a34 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    800059f8:	8526                	mv	a0,s1
    800059fa:	ffffe097          	auipc	ra,0xffffe
    800059fe:	e48080e7          	jalr	-440(ra) # 80003842 <iunlock>
  iput(p->cwd);
    80005a02:	15093503          	ld	a0,336(s2)
    80005a06:	ffffe097          	auipc	ra,0xffffe
    80005a0a:	f34080e7          	jalr	-204(ra) # 8000393a <iput>
  end_op();
    80005a0e:	ffffe097          	auipc	ra,0xffffe
    80005a12:	7bc080e7          	jalr	1980(ra) # 800041ca <end_op>
  p->cwd = ip;
    80005a16:	14993823          	sd	s1,336(s2)
  return 0;
    80005a1a:	4501                	li	a0,0
}
    80005a1c:	60ea                	ld	ra,152(sp)
    80005a1e:	644a                	ld	s0,144(sp)
    80005a20:	64aa                	ld	s1,136(sp)
    80005a22:	690a                	ld	s2,128(sp)
    80005a24:	610d                	addi	sp,sp,160
    80005a26:	8082                	ret
    end_op();
    80005a28:	ffffe097          	auipc	ra,0xffffe
    80005a2c:	7a2080e7          	jalr	1954(ra) # 800041ca <end_op>
    return -1;
    80005a30:	557d                	li	a0,-1
    80005a32:	b7ed                	j	80005a1c <sys_chdir+0x7a>
    iunlockput(ip);
    80005a34:	8526                	mv	a0,s1
    80005a36:	ffffe097          	auipc	ra,0xffffe
    80005a3a:	fac080e7          	jalr	-84(ra) # 800039e2 <iunlockput>
    end_op();
    80005a3e:	ffffe097          	auipc	ra,0xffffe
    80005a42:	78c080e7          	jalr	1932(ra) # 800041ca <end_op>
    return -1;
    80005a46:	557d                	li	a0,-1
    80005a48:	bfd1                	j	80005a1c <sys_chdir+0x7a>

0000000080005a4a <sys_exec>:

uint64
sys_exec(void)
{
    80005a4a:	7145                	addi	sp,sp,-464
    80005a4c:	e786                	sd	ra,456(sp)
    80005a4e:	e3a2                	sd	s0,448(sp)
    80005a50:	ff26                	sd	s1,440(sp)
    80005a52:	fb4a                	sd	s2,432(sp)
    80005a54:	f74e                	sd	s3,424(sp)
    80005a56:	f352                	sd	s4,416(sp)
    80005a58:	ef56                	sd	s5,408(sp)
    80005a5a:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    80005a5c:	e3840593          	addi	a1,s0,-456
    80005a60:	4505                	li	a0,1
    80005a62:	ffffd097          	auipc	ra,0xffffd
    80005a66:	124080e7          	jalr	292(ra) # 80002b86 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80005a6a:	08000613          	li	a2,128
    80005a6e:	f4040593          	addi	a1,s0,-192
    80005a72:	4501                	li	a0,0
    80005a74:	ffffd097          	auipc	ra,0xffffd
    80005a78:	132080e7          	jalr	306(ra) # 80002ba6 <argstr>
    80005a7c:	87aa                	mv	a5,a0
    return -1;
    80005a7e:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80005a80:	0c07c363          	bltz	a5,80005b46 <sys_exec+0xfc>
  }
  memset(argv, 0, sizeof(argv));
    80005a84:	10000613          	li	a2,256
    80005a88:	4581                	li	a1,0
    80005a8a:	e4040513          	addi	a0,s0,-448
    80005a8e:	ffffb097          	auipc	ra,0xffffb
    80005a92:	28e080e7          	jalr	654(ra) # 80000d1c <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005a96:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005a9a:	89a6                	mv	s3,s1
    80005a9c:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005a9e:	02000a13          	li	s4,32
    80005aa2:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005aa6:	00391513          	slli	a0,s2,0x3
    80005aaa:	e3040593          	addi	a1,s0,-464
    80005aae:	e3843783          	ld	a5,-456(s0)
    80005ab2:	953e                	add	a0,a0,a5
    80005ab4:	ffffd097          	auipc	ra,0xffffd
    80005ab8:	014080e7          	jalr	20(ra) # 80002ac8 <fetchaddr>
    80005abc:	02054a63          	bltz	a0,80005af0 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80005ac0:	e3043783          	ld	a5,-464(s0)
    80005ac4:	c3b9                	beqz	a5,80005b0a <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005ac6:	ffffb097          	auipc	ra,0xffffb
    80005aca:	020080e7          	jalr	32(ra) # 80000ae6 <kalloc>
    80005ace:	85aa                	mv	a1,a0
    80005ad0:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005ad4:	cd11                	beqz	a0,80005af0 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005ad6:	6605                	lui	a2,0x1
    80005ad8:	e3043503          	ld	a0,-464(s0)
    80005adc:	ffffd097          	auipc	ra,0xffffd
    80005ae0:	03e080e7          	jalr	62(ra) # 80002b1a <fetchstr>
    80005ae4:	00054663          	bltz	a0,80005af0 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80005ae8:	0905                	addi	s2,s2,1
    80005aea:	09a1                	addi	s3,s3,8
    80005aec:	fb491be3          	bne	s2,s4,80005aa2 <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005af0:	f4040913          	addi	s2,s0,-192
    80005af4:	6088                	ld	a0,0(s1)
    80005af6:	c539                	beqz	a0,80005b44 <sys_exec+0xfa>
    kfree(argv[i]);
    80005af8:	ffffb097          	auipc	ra,0xffffb
    80005afc:	ef0080e7          	jalr	-272(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b00:	04a1                	addi	s1,s1,8
    80005b02:	ff2499e3          	bne	s1,s2,80005af4 <sys_exec+0xaa>
  return -1;
    80005b06:	557d                	li	a0,-1
    80005b08:	a83d                	j	80005b46 <sys_exec+0xfc>
      argv[i] = 0;
    80005b0a:	0a8e                	slli	s5,s5,0x3
    80005b0c:	fc0a8793          	addi	a5,s5,-64
    80005b10:	00878ab3          	add	s5,a5,s0
    80005b14:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005b18:	e4040593          	addi	a1,s0,-448
    80005b1c:	f4040513          	addi	a0,s0,-192
    80005b20:	fffff097          	auipc	ra,0xfffff
    80005b24:	16e080e7          	jalr	366(ra) # 80004c8e <exec>
    80005b28:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b2a:	f4040993          	addi	s3,s0,-192
    80005b2e:	6088                	ld	a0,0(s1)
    80005b30:	c901                	beqz	a0,80005b40 <sys_exec+0xf6>
    kfree(argv[i]);
    80005b32:	ffffb097          	auipc	ra,0xffffb
    80005b36:	eb6080e7          	jalr	-330(ra) # 800009e8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005b3a:	04a1                	addi	s1,s1,8
    80005b3c:	ff3499e3          	bne	s1,s3,80005b2e <sys_exec+0xe4>
  return ret;
    80005b40:	854a                	mv	a0,s2
    80005b42:	a011                	j	80005b46 <sys_exec+0xfc>
  return -1;
    80005b44:	557d                	li	a0,-1
}
    80005b46:	60be                	ld	ra,456(sp)
    80005b48:	641e                	ld	s0,448(sp)
    80005b4a:	74fa                	ld	s1,440(sp)
    80005b4c:	795a                	ld	s2,432(sp)
    80005b4e:	79ba                	ld	s3,424(sp)
    80005b50:	7a1a                	ld	s4,416(sp)
    80005b52:	6afa                	ld	s5,408(sp)
    80005b54:	6179                	addi	sp,sp,464
    80005b56:	8082                	ret

0000000080005b58 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005b58:	7139                	addi	sp,sp,-64
    80005b5a:	fc06                	sd	ra,56(sp)
    80005b5c:	f822                	sd	s0,48(sp)
    80005b5e:	f426                	sd	s1,40(sp)
    80005b60:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005b62:	ffffc097          	auipc	ra,0xffffc
    80005b66:	e94080e7          	jalr	-364(ra) # 800019f6 <myproc>
    80005b6a:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80005b6c:	fd840593          	addi	a1,s0,-40
    80005b70:	4501                	li	a0,0
    80005b72:	ffffd097          	auipc	ra,0xffffd
    80005b76:	014080e7          	jalr	20(ra) # 80002b86 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80005b7a:	fc840593          	addi	a1,s0,-56
    80005b7e:	fd040513          	addi	a0,s0,-48
    80005b82:	fffff097          	auipc	ra,0xfffff
    80005b86:	dc2080e7          	jalr	-574(ra) # 80004944 <pipealloc>
    return -1;
    80005b8a:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005b8c:	0c054463          	bltz	a0,80005c54 <sys_pipe+0xfc>
  fd0 = -1;
    80005b90:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005b94:	fd043503          	ld	a0,-48(s0)
    80005b98:	fffff097          	auipc	ra,0xfffff
    80005b9c:	514080e7          	jalr	1300(ra) # 800050ac <fdalloc>
    80005ba0:	fca42223          	sw	a0,-60(s0)
    80005ba4:	08054b63          	bltz	a0,80005c3a <sys_pipe+0xe2>
    80005ba8:	fc843503          	ld	a0,-56(s0)
    80005bac:	fffff097          	auipc	ra,0xfffff
    80005bb0:	500080e7          	jalr	1280(ra) # 800050ac <fdalloc>
    80005bb4:	fca42023          	sw	a0,-64(s0)
    80005bb8:	06054863          	bltz	a0,80005c28 <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bbc:	4691                	li	a3,4
    80005bbe:	fc440613          	addi	a2,s0,-60
    80005bc2:	fd843583          	ld	a1,-40(s0)
    80005bc6:	68a8                	ld	a0,80(s1)
    80005bc8:	ffffc097          	auipc	ra,0xffffc
    80005bcc:	aee080e7          	jalr	-1298(ra) # 800016b6 <copyout>
    80005bd0:	02054063          	bltz	a0,80005bf0 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005bd4:	4691                	li	a3,4
    80005bd6:	fc040613          	addi	a2,s0,-64
    80005bda:	fd843583          	ld	a1,-40(s0)
    80005bde:	0591                	addi	a1,a1,4
    80005be0:	68a8                	ld	a0,80(s1)
    80005be2:	ffffc097          	auipc	ra,0xffffc
    80005be6:	ad4080e7          	jalr	-1324(ra) # 800016b6 <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005bea:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005bec:	06055463          	bgez	a0,80005c54 <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80005bf0:	fc442783          	lw	a5,-60(s0)
    80005bf4:	07e9                	addi	a5,a5,26
    80005bf6:	078e                	slli	a5,a5,0x3
    80005bf8:	97a6                	add	a5,a5,s1
    80005bfa:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005bfe:	fc042783          	lw	a5,-64(s0)
    80005c02:	07e9                	addi	a5,a5,26
    80005c04:	078e                	slli	a5,a5,0x3
    80005c06:	94be                	add	s1,s1,a5
    80005c08:	0004b023          	sd	zero,0(s1)
    fileclose(rf);
    80005c0c:	fd043503          	ld	a0,-48(s0)
    80005c10:	fffff097          	auipc	ra,0xfffff
    80005c14:	a04080e7          	jalr	-1532(ra) # 80004614 <fileclose>
    fileclose(wf);
    80005c18:	fc843503          	ld	a0,-56(s0)
    80005c1c:	fffff097          	auipc	ra,0xfffff
    80005c20:	9f8080e7          	jalr	-1544(ra) # 80004614 <fileclose>
    return -1;
    80005c24:	57fd                	li	a5,-1
    80005c26:	a03d                	j	80005c54 <sys_pipe+0xfc>
    if(fd0 >= 0)
    80005c28:	fc442783          	lw	a5,-60(s0)
    80005c2c:	0007c763          	bltz	a5,80005c3a <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    80005c30:	07e9                	addi	a5,a5,26
    80005c32:	078e                	slli	a5,a5,0x3
    80005c34:	97a6                	add	a5,a5,s1
    80005c36:	0007b023          	sd	zero,0(a5)
    fileclose(rf);
    80005c3a:	fd043503          	ld	a0,-48(s0)
    80005c3e:	fffff097          	auipc	ra,0xfffff
    80005c42:	9d6080e7          	jalr	-1578(ra) # 80004614 <fileclose>
    fileclose(wf);
    80005c46:	fc843503          	ld	a0,-56(s0)
    80005c4a:	fffff097          	auipc	ra,0xfffff
    80005c4e:	9ca080e7          	jalr	-1590(ra) # 80004614 <fileclose>
    return -1;
    80005c52:	57fd                	li	a5,-1
}
    80005c54:	853e                	mv	a0,a5
    80005c56:	70e2                	ld	ra,56(sp)
    80005c58:	7442                	ld	s0,48(sp)
    80005c5a:	74a2                	ld	s1,40(sp)
    80005c5c:	6121                	addi	sp,sp,64
    80005c5e:	8082                	ret

0000000080005c60 <kernelvec>:
    80005c60:	7111                	addi	sp,sp,-256
    80005c62:	e006                	sd	ra,0(sp)
    80005c64:	e40a                	sd	sp,8(sp)
    80005c66:	e80e                	sd	gp,16(sp)
    80005c68:	ec12                	sd	tp,24(sp)
    80005c6a:	f016                	sd	t0,32(sp)
    80005c6c:	f41a                	sd	t1,40(sp)
    80005c6e:	f81e                	sd	t2,48(sp)
    80005c70:	fc22                	sd	s0,56(sp)
    80005c72:	e0a6                	sd	s1,64(sp)
    80005c74:	e4aa                	sd	a0,72(sp)
    80005c76:	e8ae                	sd	a1,80(sp)
    80005c78:	ecb2                	sd	a2,88(sp)
    80005c7a:	f0b6                	sd	a3,96(sp)
    80005c7c:	f4ba                	sd	a4,104(sp)
    80005c7e:	f8be                	sd	a5,112(sp)
    80005c80:	fcc2                	sd	a6,120(sp)
    80005c82:	e146                	sd	a7,128(sp)
    80005c84:	e54a                	sd	s2,136(sp)
    80005c86:	e94e                	sd	s3,144(sp)
    80005c88:	ed52                	sd	s4,152(sp)
    80005c8a:	f156                	sd	s5,160(sp)
    80005c8c:	f55a                	sd	s6,168(sp)
    80005c8e:	f95e                	sd	s7,176(sp)
    80005c90:	fd62                	sd	s8,184(sp)
    80005c92:	e1e6                	sd	s9,192(sp)
    80005c94:	e5ea                	sd	s10,200(sp)
    80005c96:	e9ee                	sd	s11,208(sp)
    80005c98:	edf2                	sd	t3,216(sp)
    80005c9a:	f1f6                	sd	t4,224(sp)
    80005c9c:	f5fa                	sd	t5,232(sp)
    80005c9e:	f9fe                	sd	t6,240(sp)
    80005ca0:	cf5fc0ef          	jal	ra,80002994 <kerneltrap>
    80005ca4:	6082                	ld	ra,0(sp)
    80005ca6:	6122                	ld	sp,8(sp)
    80005ca8:	61c2                	ld	gp,16(sp)
    80005caa:	7282                	ld	t0,32(sp)
    80005cac:	7322                	ld	t1,40(sp)
    80005cae:	73c2                	ld	t2,48(sp)
    80005cb0:	7462                	ld	s0,56(sp)
    80005cb2:	6486                	ld	s1,64(sp)
    80005cb4:	6526                	ld	a0,72(sp)
    80005cb6:	65c6                	ld	a1,80(sp)
    80005cb8:	6666                	ld	a2,88(sp)
    80005cba:	7686                	ld	a3,96(sp)
    80005cbc:	7726                	ld	a4,104(sp)
    80005cbe:	77c6                	ld	a5,112(sp)
    80005cc0:	7866                	ld	a6,120(sp)
    80005cc2:	688a                	ld	a7,128(sp)
    80005cc4:	692a                	ld	s2,136(sp)
    80005cc6:	69ca                	ld	s3,144(sp)
    80005cc8:	6a6a                	ld	s4,152(sp)
    80005cca:	7a8a                	ld	s5,160(sp)
    80005ccc:	7b2a                	ld	s6,168(sp)
    80005cce:	7bca                	ld	s7,176(sp)
    80005cd0:	7c6a                	ld	s8,184(sp)
    80005cd2:	6c8e                	ld	s9,192(sp)
    80005cd4:	6d2e                	ld	s10,200(sp)
    80005cd6:	6dce                	ld	s11,208(sp)
    80005cd8:	6e6e                	ld	t3,216(sp)
    80005cda:	7e8e                	ld	t4,224(sp)
    80005cdc:	7f2e                	ld	t5,232(sp)
    80005cde:	7fce                	ld	t6,240(sp)
    80005ce0:	6111                	addi	sp,sp,256
    80005ce2:	10200073          	sret
    80005ce6:	00000013          	nop
    80005cea:	00000013          	nop
    80005cee:	0001                	nop

0000000080005cf0 <timervec>:
    80005cf0:	34051573          	csrrw	a0,mscratch,a0
    80005cf4:	e10c                	sd	a1,0(a0)
    80005cf6:	e510                	sd	a2,8(a0)
    80005cf8:	e914                	sd	a3,16(a0)
    80005cfa:	6d0c                	ld	a1,24(a0)
    80005cfc:	7110                	ld	a2,32(a0)
    80005cfe:	6194                	ld	a3,0(a1)
    80005d00:	96b2                	add	a3,a3,a2
    80005d02:	e194                	sd	a3,0(a1)
    80005d04:	4589                	li	a1,2
    80005d06:	14459073          	csrw	sip,a1
    80005d0a:	6914                	ld	a3,16(a0)
    80005d0c:	6510                	ld	a2,8(a0)
    80005d0e:	610c                	ld	a1,0(a0)
    80005d10:	34051573          	csrrw	a0,mscratch,a0
    80005d14:	30200073          	mret
	...

0000000080005d1a <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    80005d1a:	1141                	addi	sp,sp,-16
    80005d1c:	e422                	sd	s0,8(sp)
    80005d1e:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    80005d20:	0c0007b7          	lui	a5,0xc000
    80005d24:	4705                	li	a4,1
    80005d26:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    80005d28:	c3d8                	sw	a4,4(a5)
}
    80005d2a:	6422                	ld	s0,8(sp)
    80005d2c:	0141                	addi	sp,sp,16
    80005d2e:	8082                	ret

0000000080005d30 <plicinithart>:

void
plicinithart(void)
{
    80005d30:	1141                	addi	sp,sp,-16
    80005d32:	e406                	sd	ra,8(sp)
    80005d34:	e022                	sd	s0,0(sp)
    80005d36:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d38:	ffffc097          	auipc	ra,0xffffc
    80005d3c:	c92080e7          	jalr	-878(ra) # 800019ca <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    80005d40:	0085171b          	slliw	a4,a0,0x8
    80005d44:	0c0027b7          	lui	a5,0xc002
    80005d48:	97ba                	add	a5,a5,a4
    80005d4a:	40200713          	li	a4,1026
    80005d4e:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80005d52:	00d5151b          	slliw	a0,a0,0xd
    80005d56:	0c2017b7          	lui	a5,0xc201
    80005d5a:	97aa                	add	a5,a5,a0
    80005d5c:	0007a023          	sw	zero,0(a5) # c201000 <_entry-0x73dff000>
}
    80005d60:	60a2                	ld	ra,8(sp)
    80005d62:	6402                	ld	s0,0(sp)
    80005d64:	0141                	addi	sp,sp,16
    80005d66:	8082                	ret

0000000080005d68 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80005d68:	1141                	addi	sp,sp,-16
    80005d6a:	e406                	sd	ra,8(sp)
    80005d6c:	e022                	sd	s0,0(sp)
    80005d6e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80005d70:	ffffc097          	auipc	ra,0xffffc
    80005d74:	c5a080e7          	jalr	-934(ra) # 800019ca <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80005d78:	00d5151b          	slliw	a0,a0,0xd
    80005d7c:	0c2017b7          	lui	a5,0xc201
    80005d80:	97aa                	add	a5,a5,a0
  return irq;
}
    80005d82:	43c8                	lw	a0,4(a5)
    80005d84:	60a2                	ld	ra,8(sp)
    80005d86:	6402                	ld	s0,0(sp)
    80005d88:	0141                	addi	sp,sp,16
    80005d8a:	8082                	ret

0000000080005d8c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    80005d8c:	1101                	addi	sp,sp,-32
    80005d8e:	ec06                	sd	ra,24(sp)
    80005d90:	e822                	sd	s0,16(sp)
    80005d92:	e426                	sd	s1,8(sp)
    80005d94:	1000                	addi	s0,sp,32
    80005d96:	84aa                	mv	s1,a0
  int hart = cpuid();
    80005d98:	ffffc097          	auipc	ra,0xffffc
    80005d9c:	c32080e7          	jalr	-974(ra) # 800019ca <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80005da0:	00d5151b          	slliw	a0,a0,0xd
    80005da4:	0c2017b7          	lui	a5,0xc201
    80005da8:	97aa                	add	a5,a5,a0
    80005daa:	c3c4                	sw	s1,4(a5)
}
    80005dac:	60e2                	ld	ra,24(sp)
    80005dae:	6442                	ld	s0,16(sp)
    80005db0:	64a2                	ld	s1,8(sp)
    80005db2:	6105                	addi	sp,sp,32
    80005db4:	8082                	ret

0000000080005db6 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80005db6:	1141                	addi	sp,sp,-16
    80005db8:	e406                	sd	ra,8(sp)
    80005dba:	e022                	sd	s0,0(sp)
    80005dbc:	0800                	addi	s0,sp,16
  if(i >= NUM)
    80005dbe:	479d                	li	a5,7
    80005dc0:	04a7cc63          	blt	a5,a0,80005e18 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80005dc4:	0001c797          	auipc	a5,0x1c
    80005dc8:	04c78793          	addi	a5,a5,76 # 80021e10 <disk>
    80005dcc:	97aa                	add	a5,a5,a0
    80005dce:	0187c783          	lbu	a5,24(a5)
    80005dd2:	ebb9                	bnez	a5,80005e28 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80005dd4:	00451693          	slli	a3,a0,0x4
    80005dd8:	0001c797          	auipc	a5,0x1c
    80005ddc:	03878793          	addi	a5,a5,56 # 80021e10 <disk>
    80005de0:	6398                	ld	a4,0(a5)
    80005de2:	9736                	add	a4,a4,a3
    80005de4:	00073023          	sd	zero,0(a4)
  disk.desc[i].len = 0;
    80005de8:	6398                	ld	a4,0(a5)
    80005dea:	9736                	add	a4,a4,a3
    80005dec:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80005df0:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80005df4:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80005df8:	97aa                	add	a5,a5,a0
    80005dfa:	4705                	li	a4,1
    80005dfc:	00e78c23          	sb	a4,24(a5)
  wakeup(&disk.free[0]);
    80005e00:	0001c517          	auipc	a0,0x1c
    80005e04:	02850513          	addi	a0,a0,40 # 80021e28 <disk+0x18>
    80005e08:	ffffc097          	auipc	ra,0xffffc
    80005e0c:	2fe080e7          	jalr	766(ra) # 80002106 <wakeup>
}
    80005e10:	60a2                	ld	ra,8(sp)
    80005e12:	6402                	ld	s0,0(sp)
    80005e14:	0141                	addi	sp,sp,16
    80005e16:	8082                	ret
    panic("free_desc 1");
    80005e18:	00003517          	auipc	a0,0x3
    80005e1c:	a5050513          	addi	a0,a0,-1456 # 80008868 <syscalls+0x340>
    80005e20:	ffffa097          	auipc	ra,0xffffa
    80005e24:	720080e7          	jalr	1824(ra) # 80000540 <panic>
    panic("free_desc 2");
    80005e28:	00003517          	auipc	a0,0x3
    80005e2c:	a5050513          	addi	a0,a0,-1456 # 80008878 <syscalls+0x350>
    80005e30:	ffffa097          	auipc	ra,0xffffa
    80005e34:	710080e7          	jalr	1808(ra) # 80000540 <panic>

0000000080005e38 <virtio_disk_init>:
{
    80005e38:	1101                	addi	sp,sp,-32
    80005e3a:	ec06                	sd	ra,24(sp)
    80005e3c:	e822                	sd	s0,16(sp)
    80005e3e:	e426                	sd	s1,8(sp)
    80005e40:	e04a                	sd	s2,0(sp)
    80005e42:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    80005e44:	00003597          	auipc	a1,0x3
    80005e48:	a4458593          	addi	a1,a1,-1468 # 80008888 <syscalls+0x360>
    80005e4c:	0001c517          	auipc	a0,0x1c
    80005e50:	0ec50513          	addi	a0,a0,236 # 80021f38 <disk+0x128>
    80005e54:	ffffb097          	auipc	ra,0xffffb
    80005e58:	d3c080e7          	jalr	-708(ra) # 80000b90 <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e5c:	100017b7          	lui	a5,0x10001
    80005e60:	4398                	lw	a4,0(a5)
    80005e62:	2701                	sext.w	a4,a4
    80005e64:	747277b7          	lui	a5,0x74727
    80005e68:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80005e6c:	14f71b63          	bne	a4,a5,80005fc2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005e70:	100017b7          	lui	a5,0x10001
    80005e74:	43dc                	lw	a5,4(a5)
    80005e76:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80005e78:	4709                	li	a4,2
    80005e7a:	14e79463          	bne	a5,a4,80005fc2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e7e:	100017b7          	lui	a5,0x10001
    80005e82:	479c                	lw	a5,8(a5)
    80005e84:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80005e86:	12e79e63          	bne	a5,a4,80005fc2 <virtio_disk_init+0x18a>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80005e8a:	100017b7          	lui	a5,0x10001
    80005e8e:	47d8                	lw	a4,12(a5)
    80005e90:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80005e92:	554d47b7          	lui	a5,0x554d4
    80005e96:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80005e9a:	12f71463          	bne	a4,a5,80005fc2 <virtio_disk_init+0x18a>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005e9e:	100017b7          	lui	a5,0x10001
    80005ea2:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ea6:	4705                	li	a4,1
    80005ea8:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005eaa:	470d                	li	a4,3
    80005eac:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80005eae:	4b98                	lw	a4,16(a5)
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80005eb0:	c7ffe6b7          	lui	a3,0xc7ffe
    80005eb4:	75f68693          	addi	a3,a3,1887 # ffffffffc7ffe75f <end+0xffffffff47fdc80f>
    80005eb8:	8f75                	and	a4,a4,a3
    80005eba:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80005ebc:	472d                	li	a4,11
    80005ebe:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80005ec0:	5bbc                	lw	a5,112(a5)
    80005ec2:	0007891b          	sext.w	s2,a5
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80005ec6:	8ba1                	andi	a5,a5,8
    80005ec8:	10078563          	beqz	a5,80005fd2 <virtio_disk_init+0x19a>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80005ecc:	100017b7          	lui	a5,0x10001
    80005ed0:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80005ed4:	43fc                	lw	a5,68(a5)
    80005ed6:	2781                	sext.w	a5,a5
    80005ed8:	10079563          	bnez	a5,80005fe2 <virtio_disk_init+0x1aa>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80005edc:	100017b7          	lui	a5,0x10001
    80005ee0:	5bdc                	lw	a5,52(a5)
    80005ee2:	2781                	sext.w	a5,a5
  if(max == 0)
    80005ee4:	10078763          	beqz	a5,80005ff2 <virtio_disk_init+0x1ba>
  if(max < NUM)
    80005ee8:	471d                	li	a4,7
    80005eea:	10f77c63          	bgeu	a4,a5,80006002 <virtio_disk_init+0x1ca>
  disk.desc = kalloc();
    80005eee:	ffffb097          	auipc	ra,0xffffb
    80005ef2:	bf8080e7          	jalr	-1032(ra) # 80000ae6 <kalloc>
    80005ef6:	0001c497          	auipc	s1,0x1c
    80005efa:	f1a48493          	addi	s1,s1,-230 # 80021e10 <disk>
    80005efe:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80005f00:	ffffb097          	auipc	ra,0xffffb
    80005f04:	be6080e7          	jalr	-1050(ra) # 80000ae6 <kalloc>
    80005f08:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80005f0a:	ffffb097          	auipc	ra,0xffffb
    80005f0e:	bdc080e7          	jalr	-1060(ra) # 80000ae6 <kalloc>
    80005f12:	87aa                	mv	a5,a0
    80005f14:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80005f16:	6088                	ld	a0,0(s1)
    80005f18:	cd6d                	beqz	a0,80006012 <virtio_disk_init+0x1da>
    80005f1a:	0001c717          	auipc	a4,0x1c
    80005f1e:	efe73703          	ld	a4,-258(a4) # 80021e18 <disk+0x8>
    80005f22:	cb65                	beqz	a4,80006012 <virtio_disk_init+0x1da>
    80005f24:	c7fd                	beqz	a5,80006012 <virtio_disk_init+0x1da>
  memset(disk.desc, 0, PGSIZE);
    80005f26:	6605                	lui	a2,0x1
    80005f28:	4581                	li	a1,0
    80005f2a:	ffffb097          	auipc	ra,0xffffb
    80005f2e:	df2080e7          	jalr	-526(ra) # 80000d1c <memset>
  memset(disk.avail, 0, PGSIZE);
    80005f32:	0001c497          	auipc	s1,0x1c
    80005f36:	ede48493          	addi	s1,s1,-290 # 80021e10 <disk>
    80005f3a:	6605                	lui	a2,0x1
    80005f3c:	4581                	li	a1,0
    80005f3e:	6488                	ld	a0,8(s1)
    80005f40:	ffffb097          	auipc	ra,0xffffb
    80005f44:	ddc080e7          	jalr	-548(ra) # 80000d1c <memset>
  memset(disk.used, 0, PGSIZE);
    80005f48:	6605                	lui	a2,0x1
    80005f4a:	4581                	li	a1,0
    80005f4c:	6888                	ld	a0,16(s1)
    80005f4e:	ffffb097          	auipc	ra,0xffffb
    80005f52:	dce080e7          	jalr	-562(ra) # 80000d1c <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80005f56:	100017b7          	lui	a5,0x10001
    80005f5a:	4721                	li	a4,8
    80005f5c:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80005f5e:	4098                	lw	a4,0(s1)
    80005f60:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80005f64:	40d8                	lw	a4,4(s1)
    80005f66:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80005f6a:	6498                	ld	a4,8(s1)
    80005f6c:	0007069b          	sext.w	a3,a4
    80005f70:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80005f74:	9701                	srai	a4,a4,0x20
    80005f76:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80005f7a:	6898                	ld	a4,16(s1)
    80005f7c:	0007069b          	sext.w	a3,a4
    80005f80:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80005f84:	9701                	srai	a4,a4,0x20
    80005f86:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80005f8a:	4705                	li	a4,1
    80005f8c:	c3f8                	sw	a4,68(a5)
    disk.free[i] = 1;
    80005f8e:	00e48c23          	sb	a4,24(s1)
    80005f92:	00e48ca3          	sb	a4,25(s1)
    80005f96:	00e48d23          	sb	a4,26(s1)
    80005f9a:	00e48da3          	sb	a4,27(s1)
    80005f9e:	00e48e23          	sb	a4,28(s1)
    80005fa2:	00e48ea3          	sb	a4,29(s1)
    80005fa6:	00e48f23          	sb	a4,30(s1)
    80005faa:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80005fae:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80005fb2:	0727a823          	sw	s2,112(a5)
}
    80005fb6:	60e2                	ld	ra,24(sp)
    80005fb8:	6442                	ld	s0,16(sp)
    80005fba:	64a2                	ld	s1,8(sp)
    80005fbc:	6902                	ld	s2,0(sp)
    80005fbe:	6105                	addi	sp,sp,32
    80005fc0:	8082                	ret
    panic("could not find virtio disk");
    80005fc2:	00003517          	auipc	a0,0x3
    80005fc6:	8d650513          	addi	a0,a0,-1834 # 80008898 <syscalls+0x370>
    80005fca:	ffffa097          	auipc	ra,0xffffa
    80005fce:	576080e7          	jalr	1398(ra) # 80000540 <panic>
    panic("virtio disk FEATURES_OK unset");
    80005fd2:	00003517          	auipc	a0,0x3
    80005fd6:	8e650513          	addi	a0,a0,-1818 # 800088b8 <syscalls+0x390>
    80005fda:	ffffa097          	auipc	ra,0xffffa
    80005fde:	566080e7          	jalr	1382(ra) # 80000540 <panic>
    panic("virtio disk should not be ready");
    80005fe2:	00003517          	auipc	a0,0x3
    80005fe6:	8f650513          	addi	a0,a0,-1802 # 800088d8 <syscalls+0x3b0>
    80005fea:	ffffa097          	auipc	ra,0xffffa
    80005fee:	556080e7          	jalr	1366(ra) # 80000540 <panic>
    panic("virtio disk has no queue 0");
    80005ff2:	00003517          	auipc	a0,0x3
    80005ff6:	90650513          	addi	a0,a0,-1786 # 800088f8 <syscalls+0x3d0>
    80005ffa:	ffffa097          	auipc	ra,0xffffa
    80005ffe:	546080e7          	jalr	1350(ra) # 80000540 <panic>
    panic("virtio disk max queue too short");
    80006002:	00003517          	auipc	a0,0x3
    80006006:	91650513          	addi	a0,a0,-1770 # 80008918 <syscalls+0x3f0>
    8000600a:	ffffa097          	auipc	ra,0xffffa
    8000600e:	536080e7          	jalr	1334(ra) # 80000540 <panic>
    panic("virtio disk kalloc");
    80006012:	00003517          	auipc	a0,0x3
    80006016:	92650513          	addi	a0,a0,-1754 # 80008938 <syscalls+0x410>
    8000601a:	ffffa097          	auipc	ra,0xffffa
    8000601e:	526080e7          	jalr	1318(ra) # 80000540 <panic>

0000000080006022 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006022:	7119                	addi	sp,sp,-128
    80006024:	fc86                	sd	ra,120(sp)
    80006026:	f8a2                	sd	s0,112(sp)
    80006028:	f4a6                	sd	s1,104(sp)
    8000602a:	f0ca                	sd	s2,96(sp)
    8000602c:	ecce                	sd	s3,88(sp)
    8000602e:	e8d2                	sd	s4,80(sp)
    80006030:	e4d6                	sd	s5,72(sp)
    80006032:	e0da                	sd	s6,64(sp)
    80006034:	fc5e                	sd	s7,56(sp)
    80006036:	f862                	sd	s8,48(sp)
    80006038:	f466                	sd	s9,40(sp)
    8000603a:	f06a                	sd	s10,32(sp)
    8000603c:	ec6e                	sd	s11,24(sp)
    8000603e:	0100                	addi	s0,sp,128
    80006040:	8aaa                	mv	s5,a0
    80006042:	8c2e                	mv	s8,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006044:	00c52d03          	lw	s10,12(a0)
    80006048:	001d1d1b          	slliw	s10,s10,0x1
    8000604c:	1d02                	slli	s10,s10,0x20
    8000604e:	020d5d13          	srli	s10,s10,0x20

  acquire(&disk.vdisk_lock);
    80006052:	0001c517          	auipc	a0,0x1c
    80006056:	ee650513          	addi	a0,a0,-282 # 80021f38 <disk+0x128>
    8000605a:	ffffb097          	auipc	ra,0xffffb
    8000605e:	bc6080e7          	jalr	-1082(ra) # 80000c20 <acquire>
  for(int i = 0; i < 3; i++){
    80006062:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006064:	44a1                	li	s1,8
      disk.free[i] = 0;
    80006066:	0001cb97          	auipc	s7,0x1c
    8000606a:	daab8b93          	addi	s7,s7,-598 # 80021e10 <disk>
  for(int i = 0; i < 3; i++){
    8000606e:	4b0d                	li	s6,3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006070:	0001cc97          	auipc	s9,0x1c
    80006074:	ec8c8c93          	addi	s9,s9,-312 # 80021f38 <disk+0x128>
    80006078:	a08d                	j	800060da <virtio_disk_rw+0xb8>
      disk.free[i] = 0;
    8000607a:	00fb8733          	add	a4,s7,a5
    8000607e:	00070c23          	sb	zero,24(a4)
    idx[i] = alloc_desc();
    80006082:	c19c                	sw	a5,0(a1)
    if(idx[i] < 0){
    80006084:	0207c563          	bltz	a5,800060ae <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    80006088:	2905                	addiw	s2,s2,1
    8000608a:	0611                	addi	a2,a2,4 # 1004 <_entry-0x7fffeffc>
    8000608c:	05690c63          	beq	s2,s6,800060e4 <virtio_disk_rw+0xc2>
    idx[i] = alloc_desc();
    80006090:	85b2                	mv	a1,a2
  for(int i = 0; i < NUM; i++){
    80006092:	0001c717          	auipc	a4,0x1c
    80006096:	d7e70713          	addi	a4,a4,-642 # 80021e10 <disk>
    8000609a:	87ce                	mv	a5,s3
    if(disk.free[i]){
    8000609c:	01874683          	lbu	a3,24(a4)
    800060a0:	fee9                	bnez	a3,8000607a <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    800060a2:	2785                	addiw	a5,a5,1
    800060a4:	0705                	addi	a4,a4,1
    800060a6:	fe979be3          	bne	a5,s1,8000609c <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    800060aa:	57fd                	li	a5,-1
    800060ac:	c19c                	sw	a5,0(a1)
      for(int j = 0; j < i; j++)
    800060ae:	01205d63          	blez	s2,800060c8 <virtio_disk_rw+0xa6>
    800060b2:	8dce                	mv	s11,s3
        free_desc(idx[j]);
    800060b4:	000a2503          	lw	a0,0(s4)
    800060b8:	00000097          	auipc	ra,0x0
    800060bc:	cfe080e7          	jalr	-770(ra) # 80005db6 <free_desc>
      for(int j = 0; j < i; j++)
    800060c0:	2d85                	addiw	s11,s11,1
    800060c2:	0a11                	addi	s4,s4,4
    800060c4:	ff2d98e3          	bne	s11,s2,800060b4 <virtio_disk_rw+0x92>
    sleep(&disk.free[0], &disk.vdisk_lock);
    800060c8:	85e6                	mv	a1,s9
    800060ca:	0001c517          	auipc	a0,0x1c
    800060ce:	d5e50513          	addi	a0,a0,-674 # 80021e28 <disk+0x18>
    800060d2:	ffffc097          	auipc	ra,0xffffc
    800060d6:	fd0080e7          	jalr	-48(ra) # 800020a2 <sleep>
  for(int i = 0; i < 3; i++){
    800060da:	f8040a13          	addi	s4,s0,-128
{
    800060de:	8652                	mv	a2,s4
  for(int i = 0; i < 3; i++){
    800060e0:	894e                	mv	s2,s3
    800060e2:	b77d                	j	80006090 <virtio_disk_rw+0x6e>
  }

  // format the three descriptors.
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800060e4:	f8042503          	lw	a0,-128(s0)
    800060e8:	00a50713          	addi	a4,a0,10
    800060ec:	0712                	slli	a4,a4,0x4

  if(write)
    800060ee:	0001c797          	auipc	a5,0x1c
    800060f2:	d2278793          	addi	a5,a5,-734 # 80021e10 <disk>
    800060f6:	00e786b3          	add	a3,a5,a4
    800060fa:	01803633          	snez	a2,s8
    800060fe:	c690                	sw	a2,8(a3)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006100:	0006a623          	sw	zero,12(a3)
  buf0->sector = sector;
    80006104:	01a6b823          	sd	s10,16(a3)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006108:	f6070613          	addi	a2,a4,-160
    8000610c:	6394                	ld	a3,0(a5)
    8000610e:	96b2                	add	a3,a3,a2
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006110:	00870593          	addi	a1,a4,8
    80006114:	95be                	add	a1,a1,a5
  disk.desc[idx[0]].addr = (uint64) buf0;
    80006116:	e28c                	sd	a1,0(a3)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006118:	0007b803          	ld	a6,0(a5)
    8000611c:	9642                	add	a2,a2,a6
    8000611e:	46c1                	li	a3,16
    80006120:	c614                	sw	a3,8(a2)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006122:	4585                	li	a1,1
    80006124:	00b61623          	sh	a1,12(a2)
  disk.desc[idx[0]].next = idx[1];
    80006128:	f8442683          	lw	a3,-124(s0)
    8000612c:	00d61723          	sh	a3,14(a2)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006130:	0692                	slli	a3,a3,0x4
    80006132:	9836                	add	a6,a6,a3
    80006134:	058a8613          	addi	a2,s5,88
    80006138:	00c83023          	sd	a2,0(a6)
  disk.desc[idx[1]].len = BSIZE;
    8000613c:	0007b803          	ld	a6,0(a5)
    80006140:	96c2                	add	a3,a3,a6
    80006142:	40000613          	li	a2,1024
    80006146:	c690                	sw	a2,8(a3)
  if(write)
    80006148:	001c3613          	seqz	a2,s8
    8000614c:	0016161b          	slliw	a2,a2,0x1
    disk.desc[idx[1]].flags = 0; // device reads b->data
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006150:	00166613          	ori	a2,a2,1
    80006154:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    80006158:	f8842603          	lw	a2,-120(s0)
    8000615c:	00c69723          	sh	a2,14(a3)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006160:	00250693          	addi	a3,a0,2
    80006164:	0692                	slli	a3,a3,0x4
    80006166:	96be                	add	a3,a3,a5
    80006168:	58fd                	li	a7,-1
    8000616a:	01168823          	sb	a7,16(a3)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    8000616e:	0612                	slli	a2,a2,0x4
    80006170:	9832                	add	a6,a6,a2
    80006172:	f9070713          	addi	a4,a4,-112
    80006176:	973e                	add	a4,a4,a5
    80006178:	00e83023          	sd	a4,0(a6)
  disk.desc[idx[2]].len = 1;
    8000617c:	6398                	ld	a4,0(a5)
    8000617e:	9732                	add	a4,a4,a2
    80006180:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006182:	4609                	li	a2,2
    80006184:	00c71623          	sh	a2,12(a4)
  disk.desc[idx[2]].next = 0;
    80006188:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    8000618c:	00baa223          	sw	a1,4(s5)
  disk.info[idx[0]].b = b;
    80006190:	0156b423          	sd	s5,8(a3)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006194:	6794                	ld	a3,8(a5)
    80006196:	0026d703          	lhu	a4,2(a3)
    8000619a:	8b1d                	andi	a4,a4,7
    8000619c:	0706                	slli	a4,a4,0x1
    8000619e:	96ba                	add	a3,a3,a4
    800061a0:	00a69223          	sh	a0,4(a3)

  __sync_synchronize();
    800061a4:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    800061a8:	6798                	ld	a4,8(a5)
    800061aa:	00275783          	lhu	a5,2(a4)
    800061ae:	2785                	addiw	a5,a5,1
    800061b0:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    800061b4:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    800061b8:	100017b7          	lui	a5,0x10001
    800061bc:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    800061c0:	004aa783          	lw	a5,4(s5)
    sleep(b, &disk.vdisk_lock);
    800061c4:	0001c917          	auipc	s2,0x1c
    800061c8:	d7490913          	addi	s2,s2,-652 # 80021f38 <disk+0x128>
  while(b->disk == 1) {
    800061cc:	4485                	li	s1,1
    800061ce:	00b79c63          	bne	a5,a1,800061e6 <virtio_disk_rw+0x1c4>
    sleep(b, &disk.vdisk_lock);
    800061d2:	85ca                	mv	a1,s2
    800061d4:	8556                	mv	a0,s5
    800061d6:	ffffc097          	auipc	ra,0xffffc
    800061da:	ecc080e7          	jalr	-308(ra) # 800020a2 <sleep>
  while(b->disk == 1) {
    800061de:	004aa783          	lw	a5,4(s5)
    800061e2:	fe9788e3          	beq	a5,s1,800061d2 <virtio_disk_rw+0x1b0>
  }

  disk.info[idx[0]].b = 0;
    800061e6:	f8042903          	lw	s2,-128(s0)
    800061ea:	00290713          	addi	a4,s2,2
    800061ee:	0712                	slli	a4,a4,0x4
    800061f0:	0001c797          	auipc	a5,0x1c
    800061f4:	c2078793          	addi	a5,a5,-992 # 80021e10 <disk>
    800061f8:	97ba                	add	a5,a5,a4
    800061fa:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    800061fe:	0001c997          	auipc	s3,0x1c
    80006202:	c1298993          	addi	s3,s3,-1006 # 80021e10 <disk>
    80006206:	00491713          	slli	a4,s2,0x4
    8000620a:	0009b783          	ld	a5,0(s3)
    8000620e:	97ba                	add	a5,a5,a4
    80006210:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006214:	854a                	mv	a0,s2
    80006216:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    8000621a:	00000097          	auipc	ra,0x0
    8000621e:	b9c080e7          	jalr	-1124(ra) # 80005db6 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006222:	8885                	andi	s1,s1,1
    80006224:	f0ed                	bnez	s1,80006206 <virtio_disk_rw+0x1e4>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006226:	0001c517          	auipc	a0,0x1c
    8000622a:	d1250513          	addi	a0,a0,-750 # 80021f38 <disk+0x128>
    8000622e:	ffffb097          	auipc	ra,0xffffb
    80006232:	aa6080e7          	jalr	-1370(ra) # 80000cd4 <release>
}
    80006236:	70e6                	ld	ra,120(sp)
    80006238:	7446                	ld	s0,112(sp)
    8000623a:	74a6                	ld	s1,104(sp)
    8000623c:	7906                	ld	s2,96(sp)
    8000623e:	69e6                	ld	s3,88(sp)
    80006240:	6a46                	ld	s4,80(sp)
    80006242:	6aa6                	ld	s5,72(sp)
    80006244:	6b06                	ld	s6,64(sp)
    80006246:	7be2                	ld	s7,56(sp)
    80006248:	7c42                	ld	s8,48(sp)
    8000624a:	7ca2                	ld	s9,40(sp)
    8000624c:	7d02                	ld	s10,32(sp)
    8000624e:	6de2                	ld	s11,24(sp)
    80006250:	6109                	addi	sp,sp,128
    80006252:	8082                	ret

0000000080006254 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006254:	1101                	addi	sp,sp,-32
    80006256:	ec06                	sd	ra,24(sp)
    80006258:	e822                	sd	s0,16(sp)
    8000625a:	e426                	sd	s1,8(sp)
    8000625c:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    8000625e:	0001c497          	auipc	s1,0x1c
    80006262:	bb248493          	addi	s1,s1,-1102 # 80021e10 <disk>
    80006266:	0001c517          	auipc	a0,0x1c
    8000626a:	cd250513          	addi	a0,a0,-814 # 80021f38 <disk+0x128>
    8000626e:	ffffb097          	auipc	ra,0xffffb
    80006272:	9b2080e7          	jalr	-1614(ra) # 80000c20 <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006276:	10001737          	lui	a4,0x10001
    8000627a:	533c                	lw	a5,96(a4)
    8000627c:	8b8d                	andi	a5,a5,3
    8000627e:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006280:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006284:	689c                	ld	a5,16(s1)
    80006286:	0204d703          	lhu	a4,32(s1)
    8000628a:	0027d783          	lhu	a5,2(a5)
    8000628e:	04f70863          	beq	a4,a5,800062de <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006292:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006296:	6898                	ld	a4,16(s1)
    80006298:	0204d783          	lhu	a5,32(s1)
    8000629c:	8b9d                	andi	a5,a5,7
    8000629e:	078e                	slli	a5,a5,0x3
    800062a0:	97ba                	add	a5,a5,a4
    800062a2:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    800062a4:	00278713          	addi	a4,a5,2
    800062a8:	0712                	slli	a4,a4,0x4
    800062aa:	9726                	add	a4,a4,s1
    800062ac:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    800062b0:	e721                	bnez	a4,800062f8 <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    800062b2:	0789                	addi	a5,a5,2
    800062b4:	0792                	slli	a5,a5,0x4
    800062b6:	97a6                	add	a5,a5,s1
    800062b8:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    800062ba:	00052223          	sw	zero,4(a0)
    wakeup(b);
    800062be:	ffffc097          	auipc	ra,0xffffc
    800062c2:	e48080e7          	jalr	-440(ra) # 80002106 <wakeup>

    disk.used_idx += 1;
    800062c6:	0204d783          	lhu	a5,32(s1)
    800062ca:	2785                	addiw	a5,a5,1
    800062cc:	17c2                	slli	a5,a5,0x30
    800062ce:	93c1                	srli	a5,a5,0x30
    800062d0:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800062d4:	6898                	ld	a4,16(s1)
    800062d6:	00275703          	lhu	a4,2(a4)
    800062da:	faf71ce3          	bne	a4,a5,80006292 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    800062de:	0001c517          	auipc	a0,0x1c
    800062e2:	c5a50513          	addi	a0,a0,-934 # 80021f38 <disk+0x128>
    800062e6:	ffffb097          	auipc	ra,0xffffb
    800062ea:	9ee080e7          	jalr	-1554(ra) # 80000cd4 <release>
}
    800062ee:	60e2                	ld	ra,24(sp)
    800062f0:	6442                	ld	s0,16(sp)
    800062f2:	64a2                	ld	s1,8(sp)
    800062f4:	6105                	addi	sp,sp,32
    800062f6:	8082                	ret
      panic("virtio_disk_intr status");
    800062f8:	00002517          	auipc	a0,0x2
    800062fc:	65850513          	addi	a0,a0,1624 # 80008950 <syscalls+0x428>
    80006300:	ffffa097          	auipc	ra,0xffffa
    80006304:	240080e7          	jalr	576(ra) # 80000540 <panic>
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
