
user/_testticket:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "kernel/types.h"
#include "kernel/stat.h"
#include "user/user.h"

int main(int argc, char *argv[])
{
   0:	1101                	addi	sp,sp,-32
   2:	ec06                	sd	ra,24(sp)
   4:	e822                	sd	s0,16(sp)
   6:	e426                	sd	s1,8(sp)
   8:	1000                	addi	s0,sp,32
    if(argc != 2){
   a:	4789                	li	a5,2
   c:	00f50f63          	beq	a0,a5,2a <main+0x2a>
        printf("Usage: testticket <number of tickets>\n");
  10:	00001517          	auipc	a0,0x1
  14:	84050513          	addi	a0,a0,-1984 # 850 <malloc+0xe6>
  18:	00000097          	auipc	ra,0x0
  1c:	69a080e7          	jalr	1690(ra) # 6b2 <printf>
        exit(1);
  20:	4505                	li	a0,1
  22:	00000097          	auipc	ra,0x0
  26:	306080e7          	jalr	774(ra) # 328 <exit>
  2a:	84ae                	mv	s1,a1
    }
    printf("Setting ticket\n");
  2c:	00001517          	auipc	a0,0x1
  30:	84c50513          	addi	a0,a0,-1972 # 878 <malloc+0x10e>
  34:	00000097          	auipc	ra,0x0
  38:	67e080e7          	jalr	1662(ra) # 6b2 <printf>
    int number = atoi(argv[1]);
  3c:	6488                	ld	a0,8(s1)
  3e:	00000097          	auipc	ra,0x0
  42:	1f0080e7          	jalr	496(ra) # 22e <atoi>
    if(settickets(number)==-1){
  46:	00000097          	auipc	ra,0x0
  4a:	382080e7          	jalr	898(ra) # 3c8 <settickets>
  4e:	57fd                	li	a5,-1
  50:	00f50a63          	beq	a0,a5,64 <main+0x64>
        printf("Error setting ticket\n");
        exit(1);
    }
    int rc = fork();
  54:	00000097          	auipc	ra,0x0
  58:	2cc080e7          	jalr	716(ra) # 320 <fork>
    if(rc<0){
  5c:	02054163          	bltz	a0,7e <main+0x7e>
        printf("Error forking\n");
        exit(1);
    }
    else if(rc==0){
  60:	ed05                	bnez	a0,98 <main+0x98>
        // child process
        while(1){
  62:	a001                	j	62 <main+0x62>
        printf("Error setting ticket\n");
  64:	00001517          	auipc	a0,0x1
  68:	82450513          	addi	a0,a0,-2012 # 888 <malloc+0x11e>
  6c:	00000097          	auipc	ra,0x0
  70:	646080e7          	jalr	1606(ra) # 6b2 <printf>
        exit(1);
  74:	4505                	li	a0,1
  76:	00000097          	auipc	ra,0x0
  7a:	2b2080e7          	jalr	690(ra) # 328 <exit>
        printf("Error forking\n");
  7e:	00001517          	auipc	a0,0x1
  82:	82250513          	addi	a0,a0,-2014 # 8a0 <malloc+0x136>
  86:	00000097          	auipc	ra,0x0
  8a:	62c080e7          	jalr	1580(ra) # 6b2 <printf>
        exit(1);
  8e:	4505                	li	a0,1
  90:	00000097          	auipc	ra,0x0
  94:	298080e7          	jalr	664(ra) # 328 <exit>
            // running
        }
    }
    // while loop to make sure the process is not terminated
    exit(0);
  98:	4501                	li	a0,0
  9a:	00000097          	auipc	ra,0x0
  9e:	28e080e7          	jalr	654(ra) # 328 <exit>

00000000000000a2 <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
  a2:	1141                	addi	sp,sp,-16
  a4:	e406                	sd	ra,8(sp)
  a6:	e022                	sd	s0,0(sp)
  a8:	0800                	addi	s0,sp,16
  extern int main();
  main();
  aa:	00000097          	auipc	ra,0x0
  ae:	f56080e7          	jalr	-170(ra) # 0 <main>
  exit(0);
  b2:	4501                	li	a0,0
  b4:	00000097          	auipc	ra,0x0
  b8:	274080e7          	jalr	628(ra) # 328 <exit>

00000000000000bc <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
  bc:	1141                	addi	sp,sp,-16
  be:	e422                	sd	s0,8(sp)
  c0:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  c2:	87aa                	mv	a5,a0
  c4:	0585                	addi	a1,a1,1
  c6:	0785                	addi	a5,a5,1
  c8:	fff5c703          	lbu	a4,-1(a1)
  cc:	fee78fa3          	sb	a4,-1(a5)
  d0:	fb75                	bnez	a4,c4 <strcpy+0x8>
    ;
  return os;
}
  d2:	6422                	ld	s0,8(sp)
  d4:	0141                	addi	sp,sp,16
  d6:	8082                	ret

00000000000000d8 <strcmp>:

int
strcmp(const char *p, const char *q)
{
  d8:	1141                	addi	sp,sp,-16
  da:	e422                	sd	s0,8(sp)
  dc:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
  de:	00054783          	lbu	a5,0(a0)
  e2:	cb91                	beqz	a5,f6 <strcmp+0x1e>
  e4:	0005c703          	lbu	a4,0(a1)
  e8:	00f71763          	bne	a4,a5,f6 <strcmp+0x1e>
    p++, q++;
  ec:	0505                	addi	a0,a0,1
  ee:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
  f0:	00054783          	lbu	a5,0(a0)
  f4:	fbe5                	bnez	a5,e4 <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
  f6:	0005c503          	lbu	a0,0(a1)
}
  fa:	40a7853b          	subw	a0,a5,a0
  fe:	6422                	ld	s0,8(sp)
 100:	0141                	addi	sp,sp,16
 102:	8082                	ret

0000000000000104 <strlen>:

uint
strlen(const char *s)
{
 104:	1141                	addi	sp,sp,-16
 106:	e422                	sd	s0,8(sp)
 108:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
 10a:	00054783          	lbu	a5,0(a0)
 10e:	cf91                	beqz	a5,12a <strlen+0x26>
 110:	0505                	addi	a0,a0,1
 112:	87aa                	mv	a5,a0
 114:	4685                	li	a3,1
 116:	9e89                	subw	a3,a3,a0
 118:	00f6853b          	addw	a0,a3,a5
 11c:	0785                	addi	a5,a5,1
 11e:	fff7c703          	lbu	a4,-1(a5)
 122:	fb7d                	bnez	a4,118 <strlen+0x14>
    ;
  return n;
}
 124:	6422                	ld	s0,8(sp)
 126:	0141                	addi	sp,sp,16
 128:	8082                	ret
  for(n = 0; s[n]; n++)
 12a:	4501                	li	a0,0
 12c:	bfe5                	j	124 <strlen+0x20>

000000000000012e <memset>:

void*
memset(void *dst, int c, uint n)
{
 12e:	1141                	addi	sp,sp,-16
 130:	e422                	sd	s0,8(sp)
 132:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
 134:	ca19                	beqz	a2,14a <memset+0x1c>
 136:	87aa                	mv	a5,a0
 138:	1602                	slli	a2,a2,0x20
 13a:	9201                	srli	a2,a2,0x20
 13c:	00a60733          	add	a4,a2,a0
    cdst[i] = c;
 140:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
 144:	0785                	addi	a5,a5,1
 146:	fee79de3          	bne	a5,a4,140 <memset+0x12>
  }
  return dst;
}
 14a:	6422                	ld	s0,8(sp)
 14c:	0141                	addi	sp,sp,16
 14e:	8082                	ret

0000000000000150 <strchr>:

char*
strchr(const char *s, char c)
{
 150:	1141                	addi	sp,sp,-16
 152:	e422                	sd	s0,8(sp)
 154:	0800                	addi	s0,sp,16
  for(; *s; s++)
 156:	00054783          	lbu	a5,0(a0)
 15a:	cb99                	beqz	a5,170 <strchr+0x20>
    if(*s == c)
 15c:	00f58763          	beq	a1,a5,16a <strchr+0x1a>
  for(; *s; s++)
 160:	0505                	addi	a0,a0,1
 162:	00054783          	lbu	a5,0(a0)
 166:	fbfd                	bnez	a5,15c <strchr+0xc>
      return (char*)s;
  return 0;
 168:	4501                	li	a0,0
}
 16a:	6422                	ld	s0,8(sp)
 16c:	0141                	addi	sp,sp,16
 16e:	8082                	ret
  return 0;
 170:	4501                	li	a0,0
 172:	bfe5                	j	16a <strchr+0x1a>

0000000000000174 <gets>:

char*
gets(char *buf, int max)
{
 174:	711d                	addi	sp,sp,-96
 176:	ec86                	sd	ra,88(sp)
 178:	e8a2                	sd	s0,80(sp)
 17a:	e4a6                	sd	s1,72(sp)
 17c:	e0ca                	sd	s2,64(sp)
 17e:	fc4e                	sd	s3,56(sp)
 180:	f852                	sd	s4,48(sp)
 182:	f456                	sd	s5,40(sp)
 184:	f05a                	sd	s6,32(sp)
 186:	ec5e                	sd	s7,24(sp)
 188:	1080                	addi	s0,sp,96
 18a:	8baa                	mv	s7,a0
 18c:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 18e:	892a                	mv	s2,a0
 190:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 192:	4aa9                	li	s5,10
 194:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 196:	89a6                	mv	s3,s1
 198:	2485                	addiw	s1,s1,1
 19a:	0344d863          	bge	s1,s4,1ca <gets+0x56>
    cc = read(0, &c, 1);
 19e:	4605                	li	a2,1
 1a0:	faf40593          	addi	a1,s0,-81
 1a4:	4501                	li	a0,0
 1a6:	00000097          	auipc	ra,0x0
 1aa:	19a080e7          	jalr	410(ra) # 340 <read>
    if(cc < 1)
 1ae:	00a05e63          	blez	a0,1ca <gets+0x56>
    buf[i++] = c;
 1b2:	faf44783          	lbu	a5,-81(s0)
 1b6:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 1ba:	01578763          	beq	a5,s5,1c8 <gets+0x54>
 1be:	0905                	addi	s2,s2,1
 1c0:	fd679be3          	bne	a5,s6,196 <gets+0x22>
  for(i=0; i+1 < max; ){
 1c4:	89a6                	mv	s3,s1
 1c6:	a011                	j	1ca <gets+0x56>
 1c8:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 1ca:	99de                	add	s3,s3,s7
 1cc:	00098023          	sb	zero,0(s3)
  return buf;
}
 1d0:	855e                	mv	a0,s7
 1d2:	60e6                	ld	ra,88(sp)
 1d4:	6446                	ld	s0,80(sp)
 1d6:	64a6                	ld	s1,72(sp)
 1d8:	6906                	ld	s2,64(sp)
 1da:	79e2                	ld	s3,56(sp)
 1dc:	7a42                	ld	s4,48(sp)
 1de:	7aa2                	ld	s5,40(sp)
 1e0:	7b02                	ld	s6,32(sp)
 1e2:	6be2                	ld	s7,24(sp)
 1e4:	6125                	addi	sp,sp,96
 1e6:	8082                	ret

00000000000001e8 <stat>:

int
stat(const char *n, struct stat *st)
{
 1e8:	1101                	addi	sp,sp,-32
 1ea:	ec06                	sd	ra,24(sp)
 1ec:	e822                	sd	s0,16(sp)
 1ee:	e426                	sd	s1,8(sp)
 1f0:	e04a                	sd	s2,0(sp)
 1f2:	1000                	addi	s0,sp,32
 1f4:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 1f6:	4581                	li	a1,0
 1f8:	00000097          	auipc	ra,0x0
 1fc:	170080e7          	jalr	368(ra) # 368 <open>
  if(fd < 0)
 200:	02054563          	bltz	a0,22a <stat+0x42>
 204:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 206:	85ca                	mv	a1,s2
 208:	00000097          	auipc	ra,0x0
 20c:	178080e7          	jalr	376(ra) # 380 <fstat>
 210:	892a                	mv	s2,a0
  close(fd);
 212:	8526                	mv	a0,s1
 214:	00000097          	auipc	ra,0x0
 218:	13c080e7          	jalr	316(ra) # 350 <close>
  return r;
}
 21c:	854a                	mv	a0,s2
 21e:	60e2                	ld	ra,24(sp)
 220:	6442                	ld	s0,16(sp)
 222:	64a2                	ld	s1,8(sp)
 224:	6902                	ld	s2,0(sp)
 226:	6105                	addi	sp,sp,32
 228:	8082                	ret
    return -1;
 22a:	597d                	li	s2,-1
 22c:	bfc5                	j	21c <stat+0x34>

000000000000022e <atoi>:

int
atoi(const char *s)
{
 22e:	1141                	addi	sp,sp,-16
 230:	e422                	sd	s0,8(sp)
 232:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 234:	00054683          	lbu	a3,0(a0)
 238:	fd06879b          	addiw	a5,a3,-48
 23c:	0ff7f793          	zext.b	a5,a5
 240:	4625                	li	a2,9
 242:	02f66863          	bltu	a2,a5,272 <atoi+0x44>
 246:	872a                	mv	a4,a0
  n = 0;
 248:	4501                	li	a0,0
    n = n*10 + *s++ - '0';
 24a:	0705                	addi	a4,a4,1
 24c:	0025179b          	slliw	a5,a0,0x2
 250:	9fa9                	addw	a5,a5,a0
 252:	0017979b          	slliw	a5,a5,0x1
 256:	9fb5                	addw	a5,a5,a3
 258:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 25c:	00074683          	lbu	a3,0(a4)
 260:	fd06879b          	addiw	a5,a3,-48
 264:	0ff7f793          	zext.b	a5,a5
 268:	fef671e3          	bgeu	a2,a5,24a <atoi+0x1c>
  return n;
}
 26c:	6422                	ld	s0,8(sp)
 26e:	0141                	addi	sp,sp,16
 270:	8082                	ret
  n = 0;
 272:	4501                	li	a0,0
 274:	bfe5                	j	26c <atoi+0x3e>

0000000000000276 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 276:	1141                	addi	sp,sp,-16
 278:	e422                	sd	s0,8(sp)
 27a:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 27c:	02b57463          	bgeu	a0,a1,2a4 <memmove+0x2e>
    while(n-- > 0)
 280:	00c05f63          	blez	a2,29e <memmove+0x28>
 284:	1602                	slli	a2,a2,0x20
 286:	9201                	srli	a2,a2,0x20
 288:	00c507b3          	add	a5,a0,a2
  dst = vdst;
 28c:	872a                	mv	a4,a0
      *dst++ = *src++;
 28e:	0585                	addi	a1,a1,1
 290:	0705                	addi	a4,a4,1
 292:	fff5c683          	lbu	a3,-1(a1)
 296:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 29a:	fee79ae3          	bne	a5,a4,28e <memmove+0x18>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 29e:	6422                	ld	s0,8(sp)
 2a0:	0141                	addi	sp,sp,16
 2a2:	8082                	ret
    dst += n;
 2a4:	00c50733          	add	a4,a0,a2
    src += n;
 2a8:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 2aa:	fec05ae3          	blez	a2,29e <memmove+0x28>
 2ae:	fff6079b          	addiw	a5,a2,-1
 2b2:	1782                	slli	a5,a5,0x20
 2b4:	9381                	srli	a5,a5,0x20
 2b6:	fff7c793          	not	a5,a5
 2ba:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 2bc:	15fd                	addi	a1,a1,-1
 2be:	177d                	addi	a4,a4,-1
 2c0:	0005c683          	lbu	a3,0(a1)
 2c4:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 2c8:	fee79ae3          	bne	a5,a4,2bc <memmove+0x46>
 2cc:	bfc9                	j	29e <memmove+0x28>

00000000000002ce <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 2ce:	1141                	addi	sp,sp,-16
 2d0:	e422                	sd	s0,8(sp)
 2d2:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 2d4:	ca05                	beqz	a2,304 <memcmp+0x36>
 2d6:	fff6069b          	addiw	a3,a2,-1
 2da:	1682                	slli	a3,a3,0x20
 2dc:	9281                	srli	a3,a3,0x20
 2de:	0685                	addi	a3,a3,1
 2e0:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 2e2:	00054783          	lbu	a5,0(a0)
 2e6:	0005c703          	lbu	a4,0(a1)
 2ea:	00e79863          	bne	a5,a4,2fa <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 2ee:	0505                	addi	a0,a0,1
    p2++;
 2f0:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 2f2:	fed518e3          	bne	a0,a3,2e2 <memcmp+0x14>
  }
  return 0;
 2f6:	4501                	li	a0,0
 2f8:	a019                	j	2fe <memcmp+0x30>
      return *p1 - *p2;
 2fa:	40e7853b          	subw	a0,a5,a4
}
 2fe:	6422                	ld	s0,8(sp)
 300:	0141                	addi	sp,sp,16
 302:	8082                	ret
  return 0;
 304:	4501                	li	a0,0
 306:	bfe5                	j	2fe <memcmp+0x30>

0000000000000308 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 308:	1141                	addi	sp,sp,-16
 30a:	e406                	sd	ra,8(sp)
 30c:	e022                	sd	s0,0(sp)
 30e:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 310:	00000097          	auipc	ra,0x0
 314:	f66080e7          	jalr	-154(ra) # 276 <memmove>
}
 318:	60a2                	ld	ra,8(sp)
 31a:	6402                	ld	s0,0(sp)
 31c:	0141                	addi	sp,sp,16
 31e:	8082                	ret

0000000000000320 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 320:	4885                	li	a7,1
 ecall
 322:	00000073          	ecall
 ret
 326:	8082                	ret

0000000000000328 <exit>:
.global exit
exit:
 li a7, SYS_exit
 328:	4889                	li	a7,2
 ecall
 32a:	00000073          	ecall
 ret
 32e:	8082                	ret

0000000000000330 <wait>:
.global wait
wait:
 li a7, SYS_wait
 330:	488d                	li	a7,3
 ecall
 332:	00000073          	ecall
 ret
 336:	8082                	ret

0000000000000338 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 338:	4891                	li	a7,4
 ecall
 33a:	00000073          	ecall
 ret
 33e:	8082                	ret

0000000000000340 <read>:
.global read
read:
 li a7, SYS_read
 340:	4895                	li	a7,5
 ecall
 342:	00000073          	ecall
 ret
 346:	8082                	ret

0000000000000348 <write>:
.global write
write:
 li a7, SYS_write
 348:	48c1                	li	a7,16
 ecall
 34a:	00000073          	ecall
 ret
 34e:	8082                	ret

0000000000000350 <close>:
.global close
close:
 li a7, SYS_close
 350:	48d5                	li	a7,21
 ecall
 352:	00000073          	ecall
 ret
 356:	8082                	ret

0000000000000358 <kill>:
.global kill
kill:
 li a7, SYS_kill
 358:	4899                	li	a7,6
 ecall
 35a:	00000073          	ecall
 ret
 35e:	8082                	ret

0000000000000360 <exec>:
.global exec
exec:
 li a7, SYS_exec
 360:	489d                	li	a7,7
 ecall
 362:	00000073          	ecall
 ret
 366:	8082                	ret

0000000000000368 <open>:
.global open
open:
 li a7, SYS_open
 368:	48bd                	li	a7,15
 ecall
 36a:	00000073          	ecall
 ret
 36e:	8082                	ret

0000000000000370 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 370:	48c5                	li	a7,17
 ecall
 372:	00000073          	ecall
 ret
 376:	8082                	ret

0000000000000378 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 378:	48c9                	li	a7,18
 ecall
 37a:	00000073          	ecall
 ret
 37e:	8082                	ret

0000000000000380 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 380:	48a1                	li	a7,8
 ecall
 382:	00000073          	ecall
 ret
 386:	8082                	ret

0000000000000388 <link>:
.global link
link:
 li a7, SYS_link
 388:	48cd                	li	a7,19
 ecall
 38a:	00000073          	ecall
 ret
 38e:	8082                	ret

0000000000000390 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 390:	48d1                	li	a7,20
 ecall
 392:	00000073          	ecall
 ret
 396:	8082                	ret

0000000000000398 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 398:	48a5                	li	a7,9
 ecall
 39a:	00000073          	ecall
 ret
 39e:	8082                	ret

00000000000003a0 <dup>:
.global dup
dup:
 li a7, SYS_dup
 3a0:	48a9                	li	a7,10
 ecall
 3a2:	00000073          	ecall
 ret
 3a6:	8082                	ret

00000000000003a8 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 3a8:	48ad                	li	a7,11
 ecall
 3aa:	00000073          	ecall
 ret
 3ae:	8082                	ret

00000000000003b0 <getpinfo>:
.global getpinfo
getpinfo:
 li a7, SYS_getpinfo
 3b0:	48dd                	li	a7,23
 ecall
 3b2:	00000073          	ecall
 ret
 3b6:	8082                	ret

00000000000003b8 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 3b8:	48b1                	li	a7,12
 ecall
 3ba:	00000073          	ecall
 ret
 3be:	8082                	ret

00000000000003c0 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 3c0:	48b5                	li	a7,13
 ecall
 3c2:	00000073          	ecall
 ret
 3c6:	8082                	ret

00000000000003c8 <settickets>:
.global settickets
settickets:
 li a7, SYS_settickets
 3c8:	48d9                	li	a7,22
 ecall
 3ca:	00000073          	ecall
 ret
 3ce:	8082                	ret

00000000000003d0 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 3d0:	48b9                	li	a7,14
 ecall
 3d2:	00000073          	ecall
 ret
 3d6:	8082                	ret

00000000000003d8 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 3d8:	1101                	addi	sp,sp,-32
 3da:	ec06                	sd	ra,24(sp)
 3dc:	e822                	sd	s0,16(sp)
 3de:	1000                	addi	s0,sp,32
 3e0:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 3e4:	4605                	li	a2,1
 3e6:	fef40593          	addi	a1,s0,-17
 3ea:	00000097          	auipc	ra,0x0
 3ee:	f5e080e7          	jalr	-162(ra) # 348 <write>
}
 3f2:	60e2                	ld	ra,24(sp)
 3f4:	6442                	ld	s0,16(sp)
 3f6:	6105                	addi	sp,sp,32
 3f8:	8082                	ret

00000000000003fa <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 3fa:	7139                	addi	sp,sp,-64
 3fc:	fc06                	sd	ra,56(sp)
 3fe:	f822                	sd	s0,48(sp)
 400:	f426                	sd	s1,40(sp)
 402:	f04a                	sd	s2,32(sp)
 404:	ec4e                	sd	s3,24(sp)
 406:	0080                	addi	s0,sp,64
 408:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 40a:	c299                	beqz	a3,410 <printint+0x16>
 40c:	0805c963          	bltz	a1,49e <printint+0xa4>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 410:	2581                	sext.w	a1,a1
  neg = 0;
 412:	4881                	li	a7,0
 414:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 418:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 41a:	2601                	sext.w	a2,a2
 41c:	00000517          	auipc	a0,0x0
 420:	4f450513          	addi	a0,a0,1268 # 910 <digits>
 424:	883a                	mv	a6,a4
 426:	2705                	addiw	a4,a4,1
 428:	02c5f7bb          	remuw	a5,a1,a2
 42c:	1782                	slli	a5,a5,0x20
 42e:	9381                	srli	a5,a5,0x20
 430:	97aa                	add	a5,a5,a0
 432:	0007c783          	lbu	a5,0(a5)
 436:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 43a:	0005879b          	sext.w	a5,a1
 43e:	02c5d5bb          	divuw	a1,a1,a2
 442:	0685                	addi	a3,a3,1
 444:	fec7f0e3          	bgeu	a5,a2,424 <printint+0x2a>
  if(neg)
 448:	00088c63          	beqz	a7,460 <printint+0x66>
    buf[i++] = '-';
 44c:	fd070793          	addi	a5,a4,-48
 450:	00878733          	add	a4,a5,s0
 454:	02d00793          	li	a5,45
 458:	fef70823          	sb	a5,-16(a4)
 45c:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 460:	02e05863          	blez	a4,490 <printint+0x96>
 464:	fc040793          	addi	a5,s0,-64
 468:	00e78933          	add	s2,a5,a4
 46c:	fff78993          	addi	s3,a5,-1
 470:	99ba                	add	s3,s3,a4
 472:	377d                	addiw	a4,a4,-1
 474:	1702                	slli	a4,a4,0x20
 476:	9301                	srli	a4,a4,0x20
 478:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 47c:	fff94583          	lbu	a1,-1(s2)
 480:	8526                	mv	a0,s1
 482:	00000097          	auipc	ra,0x0
 486:	f56080e7          	jalr	-170(ra) # 3d8 <putc>
  while(--i >= 0)
 48a:	197d                	addi	s2,s2,-1
 48c:	ff3918e3          	bne	s2,s3,47c <printint+0x82>
}
 490:	70e2                	ld	ra,56(sp)
 492:	7442                	ld	s0,48(sp)
 494:	74a2                	ld	s1,40(sp)
 496:	7902                	ld	s2,32(sp)
 498:	69e2                	ld	s3,24(sp)
 49a:	6121                	addi	sp,sp,64
 49c:	8082                	ret
    x = -xx;
 49e:	40b005bb          	negw	a1,a1
    neg = 1;
 4a2:	4885                	li	a7,1
    x = -xx;
 4a4:	bf85                	j	414 <printint+0x1a>

00000000000004a6 <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 4a6:	7119                	addi	sp,sp,-128
 4a8:	fc86                	sd	ra,120(sp)
 4aa:	f8a2                	sd	s0,112(sp)
 4ac:	f4a6                	sd	s1,104(sp)
 4ae:	f0ca                	sd	s2,96(sp)
 4b0:	ecce                	sd	s3,88(sp)
 4b2:	e8d2                	sd	s4,80(sp)
 4b4:	e4d6                	sd	s5,72(sp)
 4b6:	e0da                	sd	s6,64(sp)
 4b8:	fc5e                	sd	s7,56(sp)
 4ba:	f862                	sd	s8,48(sp)
 4bc:	f466                	sd	s9,40(sp)
 4be:	f06a                	sd	s10,32(sp)
 4c0:	ec6e                	sd	s11,24(sp)
 4c2:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 4c4:	0005c903          	lbu	s2,0(a1)
 4c8:	18090f63          	beqz	s2,666 <vprintf+0x1c0>
 4cc:	8aaa                	mv	s5,a0
 4ce:	8b32                	mv	s6,a2
 4d0:	00158493          	addi	s1,a1,1
  state = 0;
 4d4:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 4d6:	02500a13          	li	s4,37
 4da:	4c55                	li	s8,21
 4dc:	00000c97          	auipc	s9,0x0
 4e0:	3dcc8c93          	addi	s9,s9,988 # 8b8 <malloc+0x14e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
        s = va_arg(ap, char*);
        if(s == 0)
          s = "(null)";
        while(*s != 0){
 4e4:	02800d93          	li	s11,40
  putc(fd, 'x');
 4e8:	4d41                	li	s10,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 4ea:	00000b97          	auipc	s7,0x0
 4ee:	426b8b93          	addi	s7,s7,1062 # 910 <digits>
 4f2:	a839                	j	510 <vprintf+0x6a>
        putc(fd, c);
 4f4:	85ca                	mv	a1,s2
 4f6:	8556                	mv	a0,s5
 4f8:	00000097          	auipc	ra,0x0
 4fc:	ee0080e7          	jalr	-288(ra) # 3d8 <putc>
 500:	a019                	j	506 <vprintf+0x60>
    } else if(state == '%'){
 502:	01498d63          	beq	s3,s4,51c <vprintf+0x76>
  for(i = 0; fmt[i]; i++){
 506:	0485                	addi	s1,s1,1
 508:	fff4c903          	lbu	s2,-1(s1)
 50c:	14090d63          	beqz	s2,666 <vprintf+0x1c0>
    if(state == 0){
 510:	fe0999e3          	bnez	s3,502 <vprintf+0x5c>
      if(c == '%'){
 514:	ff4910e3          	bne	s2,s4,4f4 <vprintf+0x4e>
        state = '%';
 518:	89d2                	mv	s3,s4
 51a:	b7f5                	j	506 <vprintf+0x60>
      if(c == 'd'){
 51c:	11490c63          	beq	s2,s4,634 <vprintf+0x18e>
 520:	f9d9079b          	addiw	a5,s2,-99
 524:	0ff7f793          	zext.b	a5,a5
 528:	10fc6e63          	bltu	s8,a5,644 <vprintf+0x19e>
 52c:	f9d9079b          	addiw	a5,s2,-99
 530:	0ff7f713          	zext.b	a4,a5
 534:	10ec6863          	bltu	s8,a4,644 <vprintf+0x19e>
 538:	00271793          	slli	a5,a4,0x2
 53c:	97e6                	add	a5,a5,s9
 53e:	439c                	lw	a5,0(a5)
 540:	97e6                	add	a5,a5,s9
 542:	8782                	jr	a5
        printint(fd, va_arg(ap, int), 10, 1);
 544:	008b0913          	addi	s2,s6,8
 548:	4685                	li	a3,1
 54a:	4629                	li	a2,10
 54c:	000b2583          	lw	a1,0(s6)
 550:	8556                	mv	a0,s5
 552:	00000097          	auipc	ra,0x0
 556:	ea8080e7          	jalr	-344(ra) # 3fa <printint>
 55a:	8b4a                	mv	s6,s2
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
        putc(fd, c);
      }
      state = 0;
 55c:	4981                	li	s3,0
 55e:	b765                	j	506 <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 560:	008b0913          	addi	s2,s6,8
 564:	4681                	li	a3,0
 566:	4629                	li	a2,10
 568:	000b2583          	lw	a1,0(s6)
 56c:	8556                	mv	a0,s5
 56e:	00000097          	auipc	ra,0x0
 572:	e8c080e7          	jalr	-372(ra) # 3fa <printint>
 576:	8b4a                	mv	s6,s2
      state = 0;
 578:	4981                	li	s3,0
 57a:	b771                	j	506 <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 57c:	008b0913          	addi	s2,s6,8
 580:	4681                	li	a3,0
 582:	866a                	mv	a2,s10
 584:	000b2583          	lw	a1,0(s6)
 588:	8556                	mv	a0,s5
 58a:	00000097          	auipc	ra,0x0
 58e:	e70080e7          	jalr	-400(ra) # 3fa <printint>
 592:	8b4a                	mv	s6,s2
      state = 0;
 594:	4981                	li	s3,0
 596:	bf85                	j	506 <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 598:	008b0793          	addi	a5,s6,8
 59c:	f8f43423          	sd	a5,-120(s0)
 5a0:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 5a4:	03000593          	li	a1,48
 5a8:	8556                	mv	a0,s5
 5aa:	00000097          	auipc	ra,0x0
 5ae:	e2e080e7          	jalr	-466(ra) # 3d8 <putc>
  putc(fd, 'x');
 5b2:	07800593          	li	a1,120
 5b6:	8556                	mv	a0,s5
 5b8:	00000097          	auipc	ra,0x0
 5bc:	e20080e7          	jalr	-480(ra) # 3d8 <putc>
 5c0:	896a                	mv	s2,s10
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 5c2:	03c9d793          	srli	a5,s3,0x3c
 5c6:	97de                	add	a5,a5,s7
 5c8:	0007c583          	lbu	a1,0(a5)
 5cc:	8556                	mv	a0,s5
 5ce:	00000097          	auipc	ra,0x0
 5d2:	e0a080e7          	jalr	-502(ra) # 3d8 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 5d6:	0992                	slli	s3,s3,0x4
 5d8:	397d                	addiw	s2,s2,-1
 5da:	fe0914e3          	bnez	s2,5c2 <vprintf+0x11c>
        printptr(fd, va_arg(ap, uint64));
 5de:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 5e2:	4981                	li	s3,0
 5e4:	b70d                	j	506 <vprintf+0x60>
        s = va_arg(ap, char*);
 5e6:	008b0913          	addi	s2,s6,8
 5ea:	000b3983          	ld	s3,0(s6)
        if(s == 0)
 5ee:	02098163          	beqz	s3,610 <vprintf+0x16a>
        while(*s != 0){
 5f2:	0009c583          	lbu	a1,0(s3)
 5f6:	c5ad                	beqz	a1,660 <vprintf+0x1ba>
          putc(fd, *s);
 5f8:	8556                	mv	a0,s5
 5fa:	00000097          	auipc	ra,0x0
 5fe:	dde080e7          	jalr	-546(ra) # 3d8 <putc>
          s++;
 602:	0985                	addi	s3,s3,1
        while(*s != 0){
 604:	0009c583          	lbu	a1,0(s3)
 608:	f9e5                	bnez	a1,5f8 <vprintf+0x152>
        s = va_arg(ap, char*);
 60a:	8b4a                	mv	s6,s2
      state = 0;
 60c:	4981                	li	s3,0
 60e:	bde5                	j	506 <vprintf+0x60>
          s = "(null)";
 610:	00000997          	auipc	s3,0x0
 614:	2a098993          	addi	s3,s3,672 # 8b0 <malloc+0x146>
        while(*s != 0){
 618:	85ee                	mv	a1,s11
 61a:	bff9                	j	5f8 <vprintf+0x152>
        putc(fd, va_arg(ap, uint));
 61c:	008b0913          	addi	s2,s6,8
 620:	000b4583          	lbu	a1,0(s6)
 624:	8556                	mv	a0,s5
 626:	00000097          	auipc	ra,0x0
 62a:	db2080e7          	jalr	-590(ra) # 3d8 <putc>
 62e:	8b4a                	mv	s6,s2
      state = 0;
 630:	4981                	li	s3,0
 632:	bdd1                	j	506 <vprintf+0x60>
        putc(fd, c);
 634:	85d2                	mv	a1,s4
 636:	8556                	mv	a0,s5
 638:	00000097          	auipc	ra,0x0
 63c:	da0080e7          	jalr	-608(ra) # 3d8 <putc>
      state = 0;
 640:	4981                	li	s3,0
 642:	b5d1                	j	506 <vprintf+0x60>
        putc(fd, '%');
 644:	85d2                	mv	a1,s4
 646:	8556                	mv	a0,s5
 648:	00000097          	auipc	ra,0x0
 64c:	d90080e7          	jalr	-624(ra) # 3d8 <putc>
        putc(fd, c);
 650:	85ca                	mv	a1,s2
 652:	8556                	mv	a0,s5
 654:	00000097          	auipc	ra,0x0
 658:	d84080e7          	jalr	-636(ra) # 3d8 <putc>
      state = 0;
 65c:	4981                	li	s3,0
 65e:	b565                	j	506 <vprintf+0x60>
        s = va_arg(ap, char*);
 660:	8b4a                	mv	s6,s2
      state = 0;
 662:	4981                	li	s3,0
 664:	b54d                	j	506 <vprintf+0x60>
    }
  }
}
 666:	70e6                	ld	ra,120(sp)
 668:	7446                	ld	s0,112(sp)
 66a:	74a6                	ld	s1,104(sp)
 66c:	7906                	ld	s2,96(sp)
 66e:	69e6                	ld	s3,88(sp)
 670:	6a46                	ld	s4,80(sp)
 672:	6aa6                	ld	s5,72(sp)
 674:	6b06                	ld	s6,64(sp)
 676:	7be2                	ld	s7,56(sp)
 678:	7c42                	ld	s8,48(sp)
 67a:	7ca2                	ld	s9,40(sp)
 67c:	7d02                	ld	s10,32(sp)
 67e:	6de2                	ld	s11,24(sp)
 680:	6109                	addi	sp,sp,128
 682:	8082                	ret

0000000000000684 <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 684:	715d                	addi	sp,sp,-80
 686:	ec06                	sd	ra,24(sp)
 688:	e822                	sd	s0,16(sp)
 68a:	1000                	addi	s0,sp,32
 68c:	e010                	sd	a2,0(s0)
 68e:	e414                	sd	a3,8(s0)
 690:	e818                	sd	a4,16(s0)
 692:	ec1c                	sd	a5,24(s0)
 694:	03043023          	sd	a6,32(s0)
 698:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 69c:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 6a0:	8622                	mv	a2,s0
 6a2:	00000097          	auipc	ra,0x0
 6a6:	e04080e7          	jalr	-508(ra) # 4a6 <vprintf>
}
 6aa:	60e2                	ld	ra,24(sp)
 6ac:	6442                	ld	s0,16(sp)
 6ae:	6161                	addi	sp,sp,80
 6b0:	8082                	ret

00000000000006b2 <printf>:

void
printf(const char *fmt, ...)
{
 6b2:	711d                	addi	sp,sp,-96
 6b4:	ec06                	sd	ra,24(sp)
 6b6:	e822                	sd	s0,16(sp)
 6b8:	1000                	addi	s0,sp,32
 6ba:	e40c                	sd	a1,8(s0)
 6bc:	e810                	sd	a2,16(s0)
 6be:	ec14                	sd	a3,24(s0)
 6c0:	f018                	sd	a4,32(s0)
 6c2:	f41c                	sd	a5,40(s0)
 6c4:	03043823          	sd	a6,48(s0)
 6c8:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 6cc:	00840613          	addi	a2,s0,8
 6d0:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 6d4:	85aa                	mv	a1,a0
 6d6:	4505                	li	a0,1
 6d8:	00000097          	auipc	ra,0x0
 6dc:	dce080e7          	jalr	-562(ra) # 4a6 <vprintf>
}
 6e0:	60e2                	ld	ra,24(sp)
 6e2:	6442                	ld	s0,16(sp)
 6e4:	6125                	addi	sp,sp,96
 6e6:	8082                	ret

00000000000006e8 <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 6e8:	1141                	addi	sp,sp,-16
 6ea:	e422                	sd	s0,8(sp)
 6ec:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 6ee:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6f2:	00001797          	auipc	a5,0x1
 6f6:	90e7b783          	ld	a5,-1778(a5) # 1000 <freep>
 6fa:	a02d                	j	724 <free+0x3c>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 6fc:	4618                	lw	a4,8(a2)
 6fe:	9f2d                	addw	a4,a4,a1
 700:	fee52c23          	sw	a4,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 704:	6398                	ld	a4,0(a5)
 706:	6310                	ld	a2,0(a4)
 708:	a83d                	j	746 <free+0x5e>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 70a:	ff852703          	lw	a4,-8(a0)
 70e:	9f31                	addw	a4,a4,a2
 710:	c798                	sw	a4,8(a5)
    p->s.ptr = bp->s.ptr;
 712:	ff053683          	ld	a3,-16(a0)
 716:	a091                	j	75a <free+0x72>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 718:	6398                	ld	a4,0(a5)
 71a:	00e7e463          	bltu	a5,a4,722 <free+0x3a>
 71e:	00e6ea63          	bltu	a3,a4,732 <free+0x4a>
{
 722:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 724:	fed7fae3          	bgeu	a5,a3,718 <free+0x30>
 728:	6398                	ld	a4,0(a5)
 72a:	00e6e463          	bltu	a3,a4,732 <free+0x4a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 72e:	fee7eae3          	bltu	a5,a4,722 <free+0x3a>
  if(bp + bp->s.size == p->s.ptr){
 732:	ff852583          	lw	a1,-8(a0)
 736:	6390                	ld	a2,0(a5)
 738:	02059813          	slli	a6,a1,0x20
 73c:	01c85713          	srli	a4,a6,0x1c
 740:	9736                	add	a4,a4,a3
 742:	fae60de3          	beq	a2,a4,6fc <free+0x14>
    bp->s.ptr = p->s.ptr->s.ptr;
 746:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 74a:	4790                	lw	a2,8(a5)
 74c:	02061593          	slli	a1,a2,0x20
 750:	01c5d713          	srli	a4,a1,0x1c
 754:	973e                	add	a4,a4,a5
 756:	fae68ae3          	beq	a3,a4,70a <free+0x22>
    p->s.ptr = bp->s.ptr;
 75a:	e394                	sd	a3,0(a5)
  } else
    p->s.ptr = bp;
  freep = p;
 75c:	00001717          	auipc	a4,0x1
 760:	8af73223          	sd	a5,-1884(a4) # 1000 <freep>
}
 764:	6422                	ld	s0,8(sp)
 766:	0141                	addi	sp,sp,16
 768:	8082                	ret

000000000000076a <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 76a:	7139                	addi	sp,sp,-64
 76c:	fc06                	sd	ra,56(sp)
 76e:	f822                	sd	s0,48(sp)
 770:	f426                	sd	s1,40(sp)
 772:	f04a                	sd	s2,32(sp)
 774:	ec4e                	sd	s3,24(sp)
 776:	e852                	sd	s4,16(sp)
 778:	e456                	sd	s5,8(sp)
 77a:	e05a                	sd	s6,0(sp)
 77c:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 77e:	02051493          	slli	s1,a0,0x20
 782:	9081                	srli	s1,s1,0x20
 784:	04bd                	addi	s1,s1,15
 786:	8091                	srli	s1,s1,0x4
 788:	0014899b          	addiw	s3,s1,1
 78c:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 78e:	00001517          	auipc	a0,0x1
 792:	87253503          	ld	a0,-1934(a0) # 1000 <freep>
 796:	c515                	beqz	a0,7c2 <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 798:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 79a:	4798                	lw	a4,8(a5)
 79c:	02977f63          	bgeu	a4,s1,7da <malloc+0x70>
 7a0:	8a4e                	mv	s4,s3
 7a2:	0009871b          	sext.w	a4,s3
 7a6:	6685                	lui	a3,0x1
 7a8:	00d77363          	bgeu	a4,a3,7ae <malloc+0x44>
 7ac:	6a05                	lui	s4,0x1
 7ae:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 7b2:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 7b6:	00001917          	auipc	s2,0x1
 7ba:	84a90913          	addi	s2,s2,-1974 # 1000 <freep>
  if(p == (char*)-1)
 7be:	5afd                	li	s5,-1
 7c0:	a895                	j	834 <malloc+0xca>
    base.s.ptr = freep = prevp = &base;
 7c2:	00001797          	auipc	a5,0x1
 7c6:	84e78793          	addi	a5,a5,-1970 # 1010 <base>
 7ca:	00001717          	auipc	a4,0x1
 7ce:	82f73b23          	sd	a5,-1994(a4) # 1000 <freep>
 7d2:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 7d4:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 7d8:	b7e1                	j	7a0 <malloc+0x36>
      if(p->s.size == nunits)
 7da:	02e48c63          	beq	s1,a4,812 <malloc+0xa8>
        p->s.size -= nunits;
 7de:	4137073b          	subw	a4,a4,s3
 7e2:	c798                	sw	a4,8(a5)
        p += p->s.size;
 7e4:	02071693          	slli	a3,a4,0x20
 7e8:	01c6d713          	srli	a4,a3,0x1c
 7ec:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 7ee:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 7f2:	00001717          	auipc	a4,0x1
 7f6:	80a73723          	sd	a0,-2034(a4) # 1000 <freep>
      return (void*)(p + 1);
 7fa:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 7fe:	70e2                	ld	ra,56(sp)
 800:	7442                	ld	s0,48(sp)
 802:	74a2                	ld	s1,40(sp)
 804:	7902                	ld	s2,32(sp)
 806:	69e2                	ld	s3,24(sp)
 808:	6a42                	ld	s4,16(sp)
 80a:	6aa2                	ld	s5,8(sp)
 80c:	6b02                	ld	s6,0(sp)
 80e:	6121                	addi	sp,sp,64
 810:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 812:	6398                	ld	a4,0(a5)
 814:	e118                	sd	a4,0(a0)
 816:	bff1                	j	7f2 <malloc+0x88>
  hp->s.size = nu;
 818:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 81c:	0541                	addi	a0,a0,16
 81e:	00000097          	auipc	ra,0x0
 822:	eca080e7          	jalr	-310(ra) # 6e8 <free>
  return freep;
 826:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 82a:	d971                	beqz	a0,7fe <malloc+0x94>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 82c:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 82e:	4798                	lw	a4,8(a5)
 830:	fa9775e3          	bgeu	a4,s1,7da <malloc+0x70>
    if(p == freep)
 834:	00093703          	ld	a4,0(s2)
 838:	853e                	mv	a0,a5
 83a:	fef719e3          	bne	a4,a5,82c <malloc+0xc2>
  p = sbrk(nu * sizeof(Header));
 83e:	8552                	mv	a0,s4
 840:	00000097          	auipc	ra,0x0
 844:	b78080e7          	jalr	-1160(ra) # 3b8 <sbrk>
  if(p == (char*)-1)
 848:	fd5518e3          	bne	a0,s5,818 <malloc+0xae>
        return 0;
 84c:	4501                	li	a0,0
 84e:	bf45                	j	7fe <malloc+0x94>
