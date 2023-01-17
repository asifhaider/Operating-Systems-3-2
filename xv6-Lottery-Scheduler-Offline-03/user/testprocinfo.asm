
user/_testprocinfo:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "kernel/types.h"
#include "kernel/pstat.h"
#include "user/user.h"

int main (int argc, char *argv[])
{
   0:	ad010113          	addi	sp,sp,-1328
   4:	52113423          	sd	ra,1320(sp)
   8:	52813023          	sd	s0,1312(sp)
   c:	50913c23          	sd	s1,1304(sp)
  10:	51213823          	sd	s2,1296(sp)
  14:	51313423          	sd	s3,1288(sp)
  18:	53010413          	addi	s0,sp,1328
    printf("Printing process info (gorib er ps)\n");
  1c:	00001517          	auipc	a0,0x1
  20:	82450513          	addi	a0,a0,-2012 # 840 <malloc+0xee>
  24:	00000097          	auipc	ra,0x0
  28:	676080e7          	jalr	1654(ra) # 69a <printf>
    printf("PID | In Use | Original Tickets | Current Tickets | Time Slices\n");
  2c:	00001517          	auipc	a0,0x1
  30:	83c50513          	addi	a0,a0,-1988 # 868 <malloc+0x116>
  34:	00000097          	auipc	ra,0x0
  38:	666080e7          	jalr	1638(ra) # 69a <printf>
    struct pstat pst;
    getpinfo(&pst);    
  3c:	ad040513          	addi	a0,s0,-1328
  40:	00000097          	auipc	ra,0x0
  44:	358080e7          	jalr	856(ra) # 398 <getpinfo>
    for (int i = 0; i < NPROC; i++) {
  48:	ad040493          	addi	s1,s0,-1328
  4c:	bd040913          	addi	s2,s0,-1072
        if (pst.inuse[i]) {
            printf("%d\t%d\t\t%d\t\t%d\t\t%d\n", pst.pid[i], pst.inuse[i], pst.tickets_original[i], pst.tickets_current[i], pst.time_slices[i]);
  50:	00001997          	auipc	s3,0x1
  54:	86098993          	addi	s3,s3,-1952 # 8b0 <malloc+0x15e>
  58:	a021                	j	60 <main+0x60>
    for (int i = 0; i < NPROC; i++) {
  5a:	0491                	addi	s1,s1,4
  5c:	03248263          	beq	s1,s2,80 <main+0x80>
        if (pst.inuse[i]) {
  60:	1004a603          	lw	a2,256(s1)
  64:	da7d                	beqz	a2,5a <main+0x5a>
            printf("%d\t%d\t\t%d\t\t%d\t\t%d\n", pst.pid[i], pst.inuse[i], pst.tickets_original[i], pst.tickets_current[i], pst.time_slices[i]);
  66:	4004a783          	lw	a5,1024(s1)
  6a:	3004a703          	lw	a4,768(s1)
  6e:	2004a683          	lw	a3,512(s1)
  72:	408c                	lw	a1,0(s1)
  74:	854e                	mv	a0,s3
  76:	00000097          	auipc	ra,0x0
  7a:	624080e7          	jalr	1572(ra) # 69a <printf>
  7e:	bff1                	j	5a <main+0x5a>
        }
    }    
    exit(0);
  80:	4501                	li	a0,0
  82:	00000097          	auipc	ra,0x0
  86:	28e080e7          	jalr	654(ra) # 310 <exit>

000000000000008a <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
  8a:	1141                	addi	sp,sp,-16
  8c:	e406                	sd	ra,8(sp)
  8e:	e022                	sd	s0,0(sp)
  90:	0800                	addi	s0,sp,16
  extern int main();
  main();
  92:	00000097          	auipc	ra,0x0
  96:	f6e080e7          	jalr	-146(ra) # 0 <main>
  exit(0);
  9a:	4501                	li	a0,0
  9c:	00000097          	auipc	ra,0x0
  a0:	274080e7          	jalr	628(ra) # 310 <exit>

00000000000000a4 <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
  a4:	1141                	addi	sp,sp,-16
  a6:	e422                	sd	s0,8(sp)
  a8:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  aa:	87aa                	mv	a5,a0
  ac:	0585                	addi	a1,a1,1
  ae:	0785                	addi	a5,a5,1
  b0:	fff5c703          	lbu	a4,-1(a1)
  b4:	fee78fa3          	sb	a4,-1(a5)
  b8:	fb75                	bnez	a4,ac <strcpy+0x8>
    ;
  return os;
}
  ba:	6422                	ld	s0,8(sp)
  bc:	0141                	addi	sp,sp,16
  be:	8082                	ret

00000000000000c0 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  c0:	1141                	addi	sp,sp,-16
  c2:	e422                	sd	s0,8(sp)
  c4:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
  c6:	00054783          	lbu	a5,0(a0)
  ca:	cb91                	beqz	a5,de <strcmp+0x1e>
  cc:	0005c703          	lbu	a4,0(a1)
  d0:	00f71763          	bne	a4,a5,de <strcmp+0x1e>
    p++, q++;
  d4:	0505                	addi	a0,a0,1
  d6:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
  d8:	00054783          	lbu	a5,0(a0)
  dc:	fbe5                	bnez	a5,cc <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
  de:	0005c503          	lbu	a0,0(a1)
}
  e2:	40a7853b          	subw	a0,a5,a0
  e6:	6422                	ld	s0,8(sp)
  e8:	0141                	addi	sp,sp,16
  ea:	8082                	ret

00000000000000ec <strlen>:

uint
strlen(const char *s)
{
  ec:	1141                	addi	sp,sp,-16
  ee:	e422                	sd	s0,8(sp)
  f0:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
  f2:	00054783          	lbu	a5,0(a0)
  f6:	cf91                	beqz	a5,112 <strlen+0x26>
  f8:	0505                	addi	a0,a0,1
  fa:	87aa                	mv	a5,a0
  fc:	4685                	li	a3,1
  fe:	9e89                	subw	a3,a3,a0
 100:	00f6853b          	addw	a0,a3,a5
 104:	0785                	addi	a5,a5,1
 106:	fff7c703          	lbu	a4,-1(a5)
 10a:	fb7d                	bnez	a4,100 <strlen+0x14>
    ;
  return n;
}
 10c:	6422                	ld	s0,8(sp)
 10e:	0141                	addi	sp,sp,16
 110:	8082                	ret
  for(n = 0; s[n]; n++)
 112:	4501                	li	a0,0
 114:	bfe5                	j	10c <strlen+0x20>

0000000000000116 <memset>:

void*
memset(void *dst, int c, uint n)
{
 116:	1141                	addi	sp,sp,-16
 118:	e422                	sd	s0,8(sp)
 11a:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 11c:	ca19                	beqz	a2,132 <memset+0x1c>
 11e:	87aa                	mv	a5,a0
 120:	1602                	slli	a2,a2,0x20
 122:	9201                	srli	a2,a2,0x20
 124:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 128:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 12c:	0785                	addi	a5,a5,1
 12e:	fee79de3          	bne	a5,a4,128 <memset+0x12>
  }
  return dst;
}
 132:	6422                	ld	s0,8(sp)
 134:	0141                	addi	sp,sp,16
 136:	8082                	ret

0000000000000138 <strchr>:

char*
strchr(const char *s, char c)
{
 138:	1141                	addi	sp,sp,-16
 13a:	e422                	sd	s0,8(sp)
 13c:	0800                	addi	s0,sp,16
  for(; *s; s++)
 13e:	00054783          	lbu	a5,0(a0)
 142:	cb99                	beqz	a5,158 <strchr+0x20>
    if(*s == c)
 144:	00f58763          	beq	a1,a5,152 <strchr+0x1a>
  for(; *s; s++)
 148:	0505                	addi	a0,a0,1
 14a:	00054783          	lbu	a5,0(a0)
 14e:	fbfd                	bnez	a5,144 <strchr+0xc>
      return (char*)s;
  return 0;
 150:	4501                	li	a0,0
}
 152:	6422                	ld	s0,8(sp)
 154:	0141                	addi	sp,sp,16
 156:	8082                	ret
  return 0;
 158:	4501                	li	a0,0
 15a:	bfe5                	j	152 <strchr+0x1a>

000000000000015c <gets>:

char*
gets(char *buf, int max)
{
 15c:	711d                	addi	sp,sp,-96
 15e:	ec86                	sd	ra,88(sp)
 160:	e8a2                	sd	s0,80(sp)
 162:	e4a6                	sd	s1,72(sp)
 164:	e0ca                	sd	s2,64(sp)
 166:	fc4e                	sd	s3,56(sp)
 168:	f852                	sd	s4,48(sp)
 16a:	f456                	sd	s5,40(sp)
 16c:	f05a                	sd	s6,32(sp)
 16e:	ec5e                	sd	s7,24(sp)
 170:	1080                	addi	s0,sp,96
 172:	8baa                	mv	s7,a0
 174:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 176:	892a                	mv	s2,a0
 178:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 17a:	4aa9                	li	s5,10
 17c:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 17e:	89a6                	mv	s3,s1
 180:	2485                	addiw	s1,s1,1
 182:	0344d863          	bge	s1,s4,1b2 <gets+0x56>
    cc = read(0, &c, 1);
 186:	4605                	li	a2,1
 188:	faf40593          	addi	a1,s0,-81
 18c:	4501                	li	a0,0
 18e:	00000097          	auipc	ra,0x0
 192:	19a080e7          	jalr	410(ra) # 328 <read>
    if(cc < 1)
 196:	00a05e63          	blez	a0,1b2 <gets+0x56>
    buf[i++] = c;
 19a:	faf44783          	lbu	a5,-81(s0)
 19e:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 1a2:	01578763          	beq	a5,s5,1b0 <gets+0x54>
 1a6:	0905                	addi	s2,s2,1
 1a8:	fd679be3          	bne	a5,s6,17e <gets+0x22>
  for(i=0; i+1 < max; ){
 1ac:	89a6                	mv	s3,s1
 1ae:	a011                	j	1b2 <gets+0x56>
 1b0:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 1b2:	99de                	add	s3,s3,s7
 1b4:	00098023          	sb	zero,0(s3)
  return buf;
}
 1b8:	855e                	mv	a0,s7
 1ba:	60e6                	ld	ra,88(sp)
 1bc:	6446                	ld	s0,80(sp)
 1be:	64a6                	ld	s1,72(sp)
 1c0:	6906                	ld	s2,64(sp)
 1c2:	79e2                	ld	s3,56(sp)
 1c4:	7a42                	ld	s4,48(sp)
 1c6:	7aa2                	ld	s5,40(sp)
 1c8:	7b02                	ld	s6,32(sp)
 1ca:	6be2                	ld	s7,24(sp)
 1cc:	6125                	addi	sp,sp,96
 1ce:	8082                	ret

00000000000001d0 <stat>:

int
stat(const char *n, struct stat *st)
{
 1d0:	1101                	addi	sp,sp,-32
 1d2:	ec06                	sd	ra,24(sp)
 1d4:	e822                	sd	s0,16(sp)
 1d6:	e426                	sd	s1,8(sp)
 1d8:	e04a                	sd	s2,0(sp)
 1da:	1000                	addi	s0,sp,32
 1dc:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 1de:	4581                	li	a1,0
 1e0:	00000097          	auipc	ra,0x0
 1e4:	170080e7          	jalr	368(ra) # 350 <open>
  if(fd < 0)
 1e8:	02054563          	bltz	a0,212 <stat+0x42>
 1ec:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 1ee:	85ca                	mv	a1,s2
 1f0:	00000097          	auipc	ra,0x0
 1f4:	178080e7          	jalr	376(ra) # 368 <fstat>
 1f8:	892a                	mv	s2,a0
  close(fd);
 1fa:	8526                	mv	a0,s1
 1fc:	00000097          	auipc	ra,0x0
 200:	13c080e7          	jalr	316(ra) # 338 <close>
  return r;
}
 204:	854a                	mv	a0,s2
 206:	60e2                	ld	ra,24(sp)
 208:	6442                	ld	s0,16(sp)
 20a:	64a2                	ld	s1,8(sp)
 20c:	6902                	ld	s2,0(sp)
 20e:	6105                	addi	sp,sp,32
 210:	8082                	ret
    return -1;
 212:	597d                	li	s2,-1
 214:	bfc5                	j	204 <stat+0x34>

0000000000000216 <atoi>:

int
atoi(const char *s)
{
 216:	1141                	addi	sp,sp,-16
 218:	e422                	sd	s0,8(sp)
 21a:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 21c:	00054683          	lbu	a3,0(a0)
 220:	fd06879b          	addiw	a5,a3,-48
 224:	0ff7f793          	zext.b	a5,a5
 228:	4625                	li	a2,9
 22a:	02f66863          	bltu	a2,a5,25a <atoi+0x44>
 22e:	872a                	mv	a4,a0
  n = 0;
 230:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
 232:	0705                	addi	a4,a4,1
 234:	0025179b          	slliw	a5,a0,0x2
 238:	9fa9                	addw	a5,a5,a0
 23a:	0017979b          	slliw	a5,a5,0x1
 23e:	9fb5                	addw	a5,a5,a3
 240:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 244:	00074683          	lbu	a3,0(a4)
 248:	fd06879b          	addiw	a5,a3,-48
 24c:	0ff7f793          	zext.b	a5,a5
 250:	fef671e3          	bgeu	a2,a5,232 <atoi+0x1c>
  return n;
}
 254:	6422                	ld	s0,8(sp)
 256:	0141                	addi	sp,sp,16
 258:	8082                	ret
  n = 0;
 25a:	4501                	li	a0,0
 25c:	bfe5                	j	254 <atoi+0x3e>

000000000000025e <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 25e:	1141                	addi	sp,sp,-16
 260:	e422                	sd	s0,8(sp)
 262:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 264:	02b57463          	bgeu	a0,a1,28c <memmove+0x2e>
    while(n-- > 0)
 268:	00c05f63          	blez	a2,286 <memmove+0x28>
 26c:	1602                	slli	a2,a2,0x20
 26e:	9201                	srli	a2,a2,0x20
 270:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 274:	872a                	mv	a4,a0
      *dst++ = *src++;
 276:	0585                	addi	a1,a1,1
 278:	0705                	addi	a4,a4,1
 27a:	fff5c683          	lbu	a3,-1(a1)
 27e:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 282:	fee79ae3          	bne	a5,a4,276 <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 286:	6422                	ld	s0,8(sp)
 288:	0141                	addi	sp,sp,16
 28a:	8082                	ret
    dst += n;
 28c:	00c50733          	add	a4,a0,a2
    src += n;
 290:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 292:	fec05ae3          	blez	a2,286 <memmove+0x28>
 296:	fff6079b          	addiw	a5,a2,-1
 29a:	1782                	slli	a5,a5,0x20
 29c:	9381                	srli	a5,a5,0x20
 29e:	fff7c793          	not	a5,a5
 2a2:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 2a4:	15fd                	addi	a1,a1,-1
 2a6:	177d                	addi	a4,a4,-1
 2a8:	0005c683          	lbu	a3,0(a1)
 2ac:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 2b0:	fee79ae3          	bne	a5,a4,2a4 <memmove+0x46>
 2b4:	bfc9                	j	286 <memmove+0x28>

00000000000002b6 <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 2b6:	1141                	addi	sp,sp,-16
 2b8:	e422                	sd	s0,8(sp)
 2ba:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 2bc:	ca05                	beqz	a2,2ec <memcmp+0x36>
 2be:	fff6069b          	addiw	a3,a2,-1
 2c2:	1682                	slli	a3,a3,0x20
 2c4:	9281                	srli	a3,a3,0x20
 2c6:	0685                	addi	a3,a3,1
 2c8:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 2ca:	00054783          	lbu	a5,0(a0)
 2ce:	0005c703          	lbu	a4,0(a1)
 2d2:	00e79863          	bne	a5,a4,2e2 <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 2d6:	0505                	addi	a0,a0,1
    p2++;
 2d8:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 2da:	fed518e3          	bne	a0,a3,2ca <memcmp+0x14>
  }
  return 0;
 2de:	4501                	li	a0,0
 2e0:	a019                	j	2e6 <memcmp+0x30>
      return *p1 - *p2;
 2e2:	40e7853b          	subw	a0,a5,a4
}
 2e6:	6422                	ld	s0,8(sp)
 2e8:	0141                	addi	sp,sp,16
 2ea:	8082                	ret
  return 0;
 2ec:	4501                	li	a0,0
 2ee:	bfe5                	j	2e6 <memcmp+0x30>

00000000000002f0 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 2f0:	1141                	addi	sp,sp,-16
 2f2:	e406                	sd	ra,8(sp)
 2f4:	e022                	sd	s0,0(sp)
 2f6:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 2f8:	00000097          	auipc	ra,0x0
 2fc:	f66080e7          	jalr	-154(ra) # 25e <memmove>
}
 300:	60a2                	ld	ra,8(sp)
 302:	6402                	ld	s0,0(sp)
 304:	0141                	addi	sp,sp,16
 306:	8082                	ret

0000000000000308 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 308:	4885                	li	a7,1
 ecall
 30a:	00000073          	ecall
 ret
 30e:	8082                	ret

0000000000000310 <exit>:
.global exit
exit:
 li a7, SYS_exit
 310:	4889                	li	a7,2
 ecall
 312:	00000073          	ecall
 ret
 316:	8082                	ret

0000000000000318 <wait>:
.global wait
wait:
 li a7, SYS_wait
 318:	488d                	li	a7,3
 ecall
 31a:	00000073          	ecall
 ret
 31e:	8082                	ret

0000000000000320 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 320:	4891                	li	a7,4
 ecall
 322:	00000073          	ecall
 ret
 326:	8082                	ret

0000000000000328 <read>:
.global read
read:
 li a7, SYS_read
 328:	4895                	li	a7,5
 ecall
 32a:	00000073          	ecall
 ret
 32e:	8082                	ret

0000000000000330 <write>:
.global write
write:
 li a7, SYS_write
 330:	48c1                	li	a7,16
 ecall
 332:	00000073          	ecall
 ret
 336:	8082                	ret

0000000000000338 <close>:
.global close
close:
 li a7, SYS_close
 338:	48d5                	li	a7,21
 ecall
 33a:	00000073          	ecall
 ret
 33e:	8082                	ret

0000000000000340 <kill>:
.global kill
kill:
 li a7, SYS_kill
 340:	4899                	li	a7,6
 ecall
 342:	00000073          	ecall
 ret
 346:	8082                	ret

0000000000000348 <exec>:
.global exec
exec:
 li a7, SYS_exec
 348:	489d                	li	a7,7
 ecall
 34a:	00000073          	ecall
 ret
 34e:	8082                	ret

0000000000000350 <open>:
.global open
open:
 li a7, SYS_open
 350:	48bd                	li	a7,15
 ecall
 352:	00000073          	ecall
 ret
 356:	8082                	ret

0000000000000358 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 358:	48c5                	li	a7,17
 ecall
 35a:	00000073          	ecall
 ret
 35e:	8082                	ret

0000000000000360 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 360:	48c9                	li	a7,18
 ecall
 362:	00000073          	ecall
 ret
 366:	8082                	ret

0000000000000368 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 368:	48a1                	li	a7,8
 ecall
 36a:	00000073          	ecall
 ret
 36e:	8082                	ret

0000000000000370 <link>:
.global link
link:
 li a7, SYS_link
 370:	48cd                	li	a7,19
 ecall
 372:	00000073          	ecall
 ret
 376:	8082                	ret

0000000000000378 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 378:	48d1                	li	a7,20
 ecall
 37a:	00000073          	ecall
 ret
 37e:	8082                	ret

0000000000000380 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 380:	48a5                	li	a7,9
 ecall
 382:	00000073          	ecall
 ret
 386:	8082                	ret

0000000000000388 <dup>:
.global dup
dup:
 li a7, SYS_dup
 388:	48a9                	li	a7,10
 ecall
 38a:	00000073          	ecall
 ret
 38e:	8082                	ret

0000000000000390 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 390:	48ad                	li	a7,11
 ecall
 392:	00000073          	ecall
 ret
 396:	8082                	ret

0000000000000398 <getpinfo>:
.global getpinfo
getpinfo:
 li a7, SYS_getpinfo
 398:	48dd                	li	a7,23
 ecall
 39a:	00000073          	ecall
 ret
 39e:	8082                	ret

00000000000003a0 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 3a0:	48b1                	li	a7,12
 ecall
 3a2:	00000073          	ecall
 ret
 3a6:	8082                	ret

00000000000003a8 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 3a8:	48b5                	li	a7,13
 ecall
 3aa:	00000073          	ecall
 ret
 3ae:	8082                	ret

00000000000003b0 <settickets>:
.global settickets
settickets:
 li a7, SYS_settickets
 3b0:	48d9                	li	a7,22
 ecall
 3b2:	00000073          	ecall
 ret
 3b6:	8082                	ret

00000000000003b8 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 3b8:	48b9                	li	a7,14
 ecall
 3ba:	00000073          	ecall
 ret
 3be:	8082                	ret

00000000000003c0 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 3c0:	1101                	addi	sp,sp,-32
 3c2:	ec06                	sd	ra,24(sp)
 3c4:	e822                	sd	s0,16(sp)
 3c6:	1000                	addi	s0,sp,32
 3c8:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 3cc:	4605                	li	a2,1
 3ce:	fef40593          	addi	a1,s0,-17
 3d2:	00000097          	auipc	ra,0x0
 3d6:	f5e080e7          	jalr	-162(ra) # 330 <write>
}
 3da:	60e2                	ld	ra,24(sp)
 3dc:	6442                	ld	s0,16(sp)
 3de:	6105                	addi	sp,sp,32
 3e0:	8082                	ret

00000000000003e2 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 3e2:	7139                	addi	sp,sp,-64
 3e4:	fc06                	sd	ra,56(sp)
 3e6:	f822                	sd	s0,48(sp)
 3e8:	f426                	sd	s1,40(sp)
 3ea:	f04a                	sd	s2,32(sp)
 3ec:	ec4e                	sd	s3,24(sp)
 3ee:	0080                	addi	s0,sp,64
 3f0:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 3f2:	c299                	beqz	a3,3f8 <printint+0x16>
 3f4:	0805c963          	bltz	a1,486 <printint+0xa4>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 3f8:	2581                	sext.w	a1,a1
  neg = 0;
 3fa:	4881                	li	a7,0
 3fc:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 400:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 402:	2601                	sext.w	a2,a2
 404:	00000517          	auipc	a0,0x0
 408:	52450513          	addi	a0,a0,1316 # 928 <digits>
 40c:	883a                	mv	a6,a4
 40e:	2705                	addiw	a4,a4,1
 410:	02c5f7bb          	remuw	a5,a1,a2
 414:	1782                	slli	a5,a5,0x20
 416:	9381                	srli	a5,a5,0x20
 418:	97aa                	add	a5,a5,a0
 41a:	0007c783          	lbu	a5,0(a5)
 41e:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 422:	0005879b          	sext.w	a5,a1
 426:	02c5d5bb          	divuw	a1,a1,a2
 42a:	0685                	addi	a3,a3,1
 42c:	fec7f0e3          	bgeu	a5,a2,40c <printint+0x2a>
  if(neg)
 430:	00088c63          	beqz	a7,448 <printint+0x66>
    buf[i++] = '-';
 434:	fd070793          	addi	a5,a4,-48
 438:	00878733          	add	a4,a5,s0
 43c:	02d00793          	li	a5,45
 440:	fef70823          	sb	a5,-16(a4)
 444:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 448:	02e05863          	blez	a4,478 <printint+0x96>
 44c:	fc040793          	addi	a5,s0,-64
 450:	00e78933          	add	s2,a5,a4
 454:	fff78993          	addi	s3,a5,-1
 458:	99ba                	add	s3,s3,a4
 45a:	377d                	addiw	a4,a4,-1
 45c:	1702                	slli	a4,a4,0x20
 45e:	9301                	srli	a4,a4,0x20
 460:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 464:	fff94583          	lbu	a1,-1(s2)
 468:	8526                	mv	a0,s1
 46a:	00000097          	auipc	ra,0x0
 46e:	f56080e7          	jalr	-170(ra) # 3c0 <putc>
  while(--i >= 0)
 472:	197d                	addi	s2,s2,-1
 474:	ff3918e3          	bne	s2,s3,464 <printint+0x82>
}
 478:	70e2                	ld	ra,56(sp)
 47a:	7442                	ld	s0,48(sp)
 47c:	74a2                	ld	s1,40(sp)
 47e:	7902                	ld	s2,32(sp)
 480:	69e2                	ld	s3,24(sp)
 482:	6121                	addi	sp,sp,64
 484:	8082                	ret
    x = -xx;
 486:	40b005bb          	negw	a1,a1
    neg = 1;
 48a:	4885                	li	a7,1
    x = -xx;
 48c:	bf85                	j	3fc <printint+0x1a>

000000000000048e <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 48e:	7119                	addi	sp,sp,-128
 490:	fc86                	sd	ra,120(sp)
 492:	f8a2                	sd	s0,112(sp)
 494:	f4a6                	sd	s1,104(sp)
 496:	f0ca                	sd	s2,96(sp)
 498:	ecce                	sd	s3,88(sp)
 49a:	e8d2                	sd	s4,80(sp)
 49c:	e4d6                	sd	s5,72(sp)
 49e:	e0da                	sd	s6,64(sp)
 4a0:	fc5e                	sd	s7,56(sp)
 4a2:	f862                	sd	s8,48(sp)
 4a4:	f466                	sd	s9,40(sp)
 4a6:	f06a                	sd	s10,32(sp)
 4a8:	ec6e                	sd	s11,24(sp)
 4aa:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 4ac:	0005c903          	lbu	s2,0(a1)
 4b0:	18090f63          	beqz	s2,64e <vprintf+0x1c0>
 4b4:	8aaa                	mv	s5,a0
 4b6:	8b32                	mv	s6,a2
 4b8:	00158493          	addi	s1,a1,1
  state = 0;
 4bc:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 4be:	02500a13          	li	s4,37
 4c2:	4c55                	li	s8,21
 4c4:	00000c97          	auipc	s9,0x0
 4c8:	40cc8c93          	addi	s9,s9,1036 # 8d0 <malloc+0x17e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
        s = va_arg(ap, char*);
        if(s == 0)
          s = "(null)";
        while(*s != 0){
 4cc:	02800d93          	li	s11,40
  putc(fd, 'x');
 4d0:	4d41                	li	s10,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 4d2:	00000b97          	auipc	s7,0x0
 4d6:	456b8b93          	addi	s7,s7,1110 # 928 <digits>
 4da:	a839                	j	4f8 <vprintf+0x6a>
        putc(fd, c);
 4dc:	85ca                	mv	a1,s2
 4de:	8556                	mv	a0,s5
 4e0:	00000097          	auipc	ra,0x0
 4e4:	ee0080e7          	jalr	-288(ra) # 3c0 <putc>
 4e8:	a019                	j	4ee <vprintf+0x60>
    } else if(state == '%'){
 4ea:	01498d63          	beq	s3,s4,504 <vprintf+0x76>
  for(i = 0; fmt[i]; i++){
 4ee:	0485                	addi	s1,s1,1
 4f0:	fff4c903          	lbu	s2,-1(s1)
 4f4:	14090d63          	beqz	s2,64e <vprintf+0x1c0>
    if(state == 0){
 4f8:	fe0999e3          	bnez	s3,4ea <vprintf+0x5c>
      if(c == '%'){
 4fc:	ff4910e3          	bne	s2,s4,4dc <vprintf+0x4e>
        state = '%';
 500:	89d2                	mv	s3,s4
 502:	b7f5                	j	4ee <vprintf+0x60>
      if(c == 'd'){
 504:	11490c63          	beq	s2,s4,61c <vprintf+0x18e>
 508:	f9d9079b          	addiw	a5,s2,-99
 50c:	0ff7f793          	zext.b	a5,a5
 510:	10fc6e63          	bltu	s8,a5,62c <vprintf+0x19e>
 514:	f9d9079b          	addiw	a5,s2,-99
 518:	0ff7f713          	zext.b	a4,a5
 51c:	10ec6863          	bltu	s8,a4,62c <vprintf+0x19e>
 520:	00271793          	slli	a5,a4,0x2
 524:	97e6                	add	a5,a5,s9
 526:	439c                	lw	a5,0(a5)
 528:	97e6                	add	a5,a5,s9
 52a:	8782                	jr	a5
        printint(fd, va_arg(ap, int), 10, 1);
 52c:	008b0913          	addi	s2,s6,8
 530:	4685                	li	a3,1
 532:	4629                	li	a2,10
 534:	000b2583          	lw	a1,0(s6)
 538:	8556                	mv	a0,s5
 53a:	00000097          	auipc	ra,0x0
 53e:	ea8080e7          	jalr	-344(ra) # 3e2 <printint>
 542:	8b4a                	mv	s6,s2
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c);
      }
      state = 0;
 544:	4981                	li	s3,0
 546:	b765                	j	4ee <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 548:	008b0913          	addi	s2,s6,8
 54c:	4681                	li	a3,0
 54e:	4629                	li	a2,10
 550:	000b2583          	lw	a1,0(s6)
 554:	8556                	mv	a0,s5
 556:	00000097          	auipc	ra,0x0
 55a:	e8c080e7          	jalr	-372(ra) # 3e2 <printint>
 55e:	8b4a                	mv	s6,s2
      state = 0;
 560:	4981                	li	s3,0
 562:	b771                	j	4ee <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 564:	008b0913          	addi	s2,s6,8
 568:	4681                	li	a3,0
 56a:	866a                	mv	a2,s10
 56c:	000b2583          	lw	a1,0(s6)
 570:	8556                	mv	a0,s5
 572:	00000097          	auipc	ra,0x0
 576:	e70080e7          	jalr	-400(ra) # 3e2 <printint>
 57a:	8b4a                	mv	s6,s2
      state = 0;
 57c:	4981                	li	s3,0
 57e:	bf85                	j	4ee <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 580:	008b0793          	addi	a5,s6,8
 584:	f8f43423          	sd	a5,-120(s0)
 588:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 58c:	03000593          	li	a1,48
 590:	8556                	mv	a0,s5
 592:	00000097          	auipc	ra,0x0
 596:	e2e080e7          	jalr	-466(ra) # 3c0 <putc>
  putc(fd, 'x');
 59a:	07800593          	li	a1,120
 59e:	8556                	mv	a0,s5
 5a0:	00000097          	auipc	ra,0x0
 5a4:	e20080e7          	jalr	-480(ra) # 3c0 <putc>
 5a8:	896a                	mv	s2,s10
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 5aa:	03c9d793          	srli	a5,s3,0x3c
 5ae:	97de                	add	a5,a5,s7
 5b0:	0007c583          	lbu	a1,0(a5)
 5b4:	8556                	mv	a0,s5
 5b6:	00000097          	auipc	ra,0x0
 5ba:	e0a080e7          	jalr	-502(ra) # 3c0 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 5be:	0992                	slli	s3,s3,0x4
 5c0:	397d                	addiw	s2,s2,-1
 5c2:	fe0914e3          	bnez	s2,5aa <vprintf+0x11c>
        printptr(fd, va_arg(ap, uint64));
 5c6:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 5ca:	4981                	li	s3,0
 5cc:	b70d                	j	4ee <vprintf+0x60>
        s = va_arg(ap, char*);
 5ce:	008b0913          	addi	s2,s6,8
 5d2:	000b3983          	ld	s3,0(s6)
        if(s == 0)
 5d6:	02098163          	beqz	s3,5f8 <vprintf+0x16a>
        while(*s != 0){
 5da:	0009c583          	lbu	a1,0(s3)
 5de:	c5ad                	beqz	a1,648 <vprintf+0x1ba>
          putc(fd, *s);
 5e0:	8556                	mv	a0,s5
 5e2:	00000097          	auipc	ra,0x0
 5e6:	dde080e7          	jalr	-546(ra) # 3c0 <putc>
          s++;
 5ea:	0985                	addi	s3,s3,1
        while(*s != 0){
 5ec:	0009c583          	lbu	a1,0(s3)
 5f0:	f9e5                	bnez	a1,5e0 <vprintf+0x152>
        s = va_arg(ap, char*);
 5f2:	8b4a                	mv	s6,s2
      state = 0;
 5f4:	4981                	li	s3,0
 5f6:	bde5                	j	4ee <vprintf+0x60>
          s = "(null)";
 5f8:	00000997          	auipc	s3,0x0
 5fc:	2d098993          	addi	s3,s3,720 # 8c8 <malloc+0x176>
        while(*s != 0){
 600:	85ee                	mv	a1,s11
 602:	bff9                	j	5e0 <vprintf+0x152>
        putc(fd, va_arg(ap, uint));
 604:	008b0913          	addi	s2,s6,8
 608:	000b4583          	lbu	a1,0(s6)
 60c:	8556                	mv	a0,s5
 60e:	00000097          	auipc	ra,0x0
 612:	db2080e7          	jalr	-590(ra) # 3c0 <putc>
 616:	8b4a                	mv	s6,s2
      state = 0;
 618:	4981                	li	s3,0
 61a:	bdd1                	j	4ee <vprintf+0x60>
        putc(fd, c);
 61c:	85d2                	mv	a1,s4
 61e:	8556                	mv	a0,s5
 620:	00000097          	auipc	ra,0x0
 624:	da0080e7          	jalr	-608(ra) # 3c0 <putc>
      state = 0;
 628:	4981                	li	s3,0
 62a:	b5d1                	j	4ee <vprintf+0x60>
        putc(fd, '%');
 62c:	85d2                	mv	a1,s4
 62e:	8556                	mv	a0,s5
 630:	00000097          	auipc	ra,0x0
 634:	d90080e7          	jalr	-624(ra) # 3c0 <putc>
        putc(fd, c);
 638:	85ca                	mv	a1,s2
 63a:	8556                	mv	a0,s5
 63c:	00000097          	auipc	ra,0x0
 640:	d84080e7          	jalr	-636(ra) # 3c0 <putc>
      state = 0;
 644:	4981                	li	s3,0
 646:	b565                	j	4ee <vprintf+0x60>
        s = va_arg(ap, char*);
 648:	8b4a                	mv	s6,s2
      state = 0;
 64a:	4981                	li	s3,0
 64c:	b54d                	j	4ee <vprintf+0x60>
    }
  }
}
 64e:	70e6                	ld	ra,120(sp)
 650:	7446                	ld	s0,112(sp)
 652:	74a6                	ld	s1,104(sp)
 654:	7906                	ld	s2,96(sp)
 656:	69e6                	ld	s3,88(sp)
 658:	6a46                	ld	s4,80(sp)
 65a:	6aa6                	ld	s5,72(sp)
 65c:	6b06                	ld	s6,64(sp)
 65e:	7be2                	ld	s7,56(sp)
 660:	7c42                	ld	s8,48(sp)
 662:	7ca2                	ld	s9,40(sp)
 664:	7d02                	ld	s10,32(sp)
 666:	6de2                	ld	s11,24(sp)
 668:	6109                	addi	sp,sp,128
 66a:	8082                	ret

000000000000066c <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 66c:	715d                	addi	sp,sp,-80
 66e:	ec06                	sd	ra,24(sp)
 670:	e822                	sd	s0,16(sp)
 672:	1000                	addi	s0,sp,32
 674:	e010                	sd	a2,0(s0)
 676:	e414                	sd	a3,8(s0)
 678:	e818                	sd	a4,16(s0)
 67a:	ec1c                	sd	a5,24(s0)
 67c:	03043023          	sd	a6,32(s0)
 680:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 684:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 688:	8622                	mv	a2,s0
 68a:	00000097          	auipc	ra,0x0
 68e:	e04080e7          	jalr	-508(ra) # 48e <vprintf>
}
 692:	60e2                	ld	ra,24(sp)
 694:	6442                	ld	s0,16(sp)
 696:	6161                	addi	sp,sp,80
 698:	8082                	ret

000000000000069a <printf>:

void
printf(const char *fmt, ...)
{
 69a:	711d                	addi	sp,sp,-96
 69c:	ec06                	sd	ra,24(sp)
 69e:	e822                	sd	s0,16(sp)
 6a0:	1000                	addi	s0,sp,32
 6a2:	e40c                	sd	a1,8(s0)
 6a4:	e810                	sd	a2,16(s0)
 6a6:	ec14                	sd	a3,24(s0)
 6a8:	f018                	sd	a4,32(s0)
 6aa:	f41c                	sd	a5,40(s0)
 6ac:	03043823          	sd	a6,48(s0)
 6b0:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 6b4:	00840613          	addi	a2,s0,8
 6b8:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 6bc:	85aa                	mv	a1,a0
 6be:	4505                	li	a0,1
 6c0:	00000097          	auipc	ra,0x0
 6c4:	dce080e7          	jalr	-562(ra) # 48e <vprintf>
}
 6c8:	60e2                	ld	ra,24(sp)
 6ca:	6442                	ld	s0,16(sp)
 6cc:	6125                	addi	sp,sp,96
 6ce:	8082                	ret

00000000000006d0 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 6d0:	1141                	addi	sp,sp,-16
 6d2:	e422                	sd	s0,8(sp)
 6d4:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 6d6:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6da:	00001797          	auipc	a5,0x1
 6de:	9267b783          	ld	a5,-1754(a5) # 1000 <freep>
 6e2:	a02d                	j	70c <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 6e4:	4618                	lw	a4,8(a2)
 6e6:	9f2d                	addw	a4,a4,a1
 6e8:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 6ec:	6398                	ld	a4,0(a5)
 6ee:	6310                	ld	a2,0(a4)
 6f0:	a83d                	j	72e <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 6f2:	ff852703          	lw	a4,-8(a0)
 6f6:	9f31                	addw	a4,a4,a2
 6f8:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 6fa:	ff053683          	ld	a3,-16(a0)
 6fe:	a091                	j	742 <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 700:	6398                	ld	a4,0(a5)
 702:	00e7e463          	bltu	a5,a4,70a <free+0x3a>
 706:	00e6ea63          	bltu	a3,a4,71a <free+0x4a>
{
 70a:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 70c:	fed7fae3          	bgeu	a5,a3,700 <free+0x30>
 710:	6398                	ld	a4,0(a5)
 712:	00e6e463          	bltu	a3,a4,71a <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 716:	fee7eae3          	bltu	a5,a4,70a <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 71a:	ff852583          	lw	a1,-8(a0)
 71e:	6390                	ld	a2,0(a5)
 720:	02059813          	slli	a6,a1,0x20
 724:	01c85713          	srli	a4,a6,0x1c
 728:	9736                	add	a4,a4,a3
 72a:	fae60de3          	beq	a2,a4,6e4 <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 72e:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 732:	4790                	lw	a2,8(a5)
 734:	02061593          	slli	a1,a2,0x20
 738:	01c5d713          	srli	a4,a1,0x1c
 73c:	973e                	add	a4,a4,a5
 73e:	fae68ae3          	beq	a3,a4,6f2 <free+0x22>
    p->s.ptr = bp->s.ptr;
 742:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 744:	00001717          	auipc	a4,0x1
 748:	8af73e23          	sd	a5,-1860(a4) # 1000 <freep>
}
 74c:	6422                	ld	s0,8(sp)
 74e:	0141                	addi	sp,sp,16
 750:	8082                	ret

0000000000000752 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 752:	7139                	addi	sp,sp,-64
 754:	fc06                	sd	ra,56(sp)
 756:	f822                	sd	s0,48(sp)
 758:	f426                	sd	s1,40(sp)
 75a:	f04a                	sd	s2,32(sp)
 75c:	ec4e                	sd	s3,24(sp)
 75e:	e852                	sd	s4,16(sp)
 760:	e456                	sd	s5,8(sp)
 762:	e05a                	sd	s6,0(sp)
 764:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 766:	02051493          	slli	s1,a0,0x20
 76a:	9081                	srli	s1,s1,0x20
 76c:	04bd                	addi	s1,s1,15
 76e:	8091                	srli	s1,s1,0x4
 770:	0014899b          	addiw	s3,s1,1
 774:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 776:	00001517          	auipc	a0,0x1
 77a:	88a53503          	ld	a0,-1910(a0) # 1000 <freep>
 77e:	c515                	beqz	a0,7aa <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 780:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 782:	4798                	lw	a4,8(a5)
 784:	02977f63          	bgeu	a4,s1,7c2 <malloc+0x70>
 788:	8a4e                	mv	s4,s3
 78a:	0009871b          	sext.w	a4,s3
 78e:	6685                	lui	a3,0x1
 790:	00d77363          	bgeu	a4,a3,796 <malloc+0x44>
 794:	6a05                	lui	s4,0x1
 796:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 79a:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 79e:	00001917          	auipc	s2,0x1
 7a2:	86290913          	addi	s2,s2,-1950 # 1000 <freep>
  if(p == (char*)-1)
 7a6:	5afd                	li	s5,-1
 7a8:	a895                	j	81c <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 7aa:	00001797          	auipc	a5,0x1
 7ae:	86678793          	addi	a5,a5,-1946 # 1010 <base>
 7b2:	00001717          	auipc	a4,0x1
 7b6:	84f73723          	sd	a5,-1970(a4) # 1000 <freep>
 7ba:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 7bc:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 7c0:	b7e1                	j	788 <malloc+0x36>
      if(p->s.size == nunits)
 7c2:	02e48c63          	beq	s1,a4,7fa <malloc+0xa8>
        p->s.size -= nunits;
 7c6:	4137073b          	subw	a4,a4,s3
 7ca:	c798                	sw	a4,8(a5)
        p += p->s.size;
 7cc:	02071693          	slli	a3,a4,0x20
 7d0:	01c6d713          	srli	a4,a3,0x1c
 7d4:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 7d6:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 7da:	00001717          	auipc	a4,0x1
 7de:	82a73323          	sd	a0,-2010(a4) # 1000 <freep>
      return (void*)(p + 1);
 7e2:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 7e6:	70e2                	ld	ra,56(sp)
 7e8:	7442                	ld	s0,48(sp)
 7ea:	74a2                	ld	s1,40(sp)
 7ec:	7902                	ld	s2,32(sp)
 7ee:	69e2                	ld	s3,24(sp)
 7f0:	6a42                	ld	s4,16(sp)
 7f2:	6aa2                	ld	s5,8(sp)
 7f4:	6b02                	ld	s6,0(sp)
 7f6:	6121                	addi	sp,sp,64
 7f8:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 7fa:	6398                	ld	a4,0(a5)
 7fc:	e118                	sd	a4,0(a0)
 7fe:	bff1                	j	7da <malloc+0x88>
  hp->s.size = nu;
 800:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 804:	0541                	addi	a0,a0,16
 806:	00000097          	auipc	ra,0x0
 80a:	eca080e7          	jalr	-310(ra) # 6d0 <free>
  return freep;
 80e:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 812:	d971                	beqz	a0,7e6 <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 814:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 816:	4798                	lw	a4,8(a5)
 818:	fa9775e3          	bgeu	a4,s1,7c2 <malloc+0x70>
    if(p == freep)
 81c:	00093703          	ld	a4,0(s2)
 820:	853e                	mv	a0,a5
 822:	fef719e3          	bne	a4,a5,814 <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 826:	8552                	mv	a0,s4
 828:	00000097          	auipc	ra,0x0
 82c:	b78080e7          	jalr	-1160(ra) # 3a0 <sbrk>
  if(p == (char*)-1)
 830:	fd5518e3          	bne	a0,s5,800 <malloc+0xae>
        return 0;
 834:	4501                	li	a0,0
 836:	bf45                	j	7e6 <malloc+0x94>
