
user/_strace:     file format elf64-littleriscv


Disassembly of section .text:

0000000000000000 <main>:
#include "user.h"
#include "../kernel/types.h"
#include "../kernel/stat.h"

int main(int fir,char **sec)
{
   0:	1101                	addi	sp,sp,-32
   2:	ec06                	sd	ra,24(sp)
   4:	e822                	sd	s0,16(sp)
   6:	e426                	sd	s1,8(sp)
   8:	1000                	addi	s0,sp,32
   a:	84ae                	mv	s1,a1
    trace(atoi(sec[1]));
   c:	6588                	ld	a0,8(a1)
   e:	00000097          	auipc	ra,0x0
  12:	1ba080e7          	jalr	442(ra) # 1c8 <atoi>
  16:	00000097          	auipc	ra,0x0
  1a:	362080e7          	jalr	866(ra) # 378 <trace>
    exec(sec[2],&sec[2]);
  1e:	01048593          	addi	a1,s1,16
  22:	6888                	ld	a0,16(s1)
  24:	00000097          	auipc	ra,0x0
  28:	2dc080e7          	jalr	732(ra) # 300 <exec>
    return 0;
  2c:	4501                	li	a0,0
  2e:	60e2                	ld	ra,24(sp)
  30:	6442                	ld	s0,16(sp)
  32:	64a2                	ld	s1,8(sp)
  34:	6105                	addi	sp,sp,32
  36:	8082                	ret

0000000000000038 <_main>:
//
// wrapper so that it's OK if main() does not call exit().
//
void
_main()
{
  38:	1141                	addi	sp,sp,-16
  3a:	e406                	sd	ra,8(sp)
  3c:	e022                	sd	s0,0(sp)
  3e:	0800                	addi	s0,sp,16
  extern int main();
  main();
  40:	00000097          	auipc	ra,0x0
  44:	fc0080e7          	jalr	-64(ra) # 0 <main>
  exit(0);
  48:	4501                	li	a0,0
  4a:	00000097          	auipc	ra,0x0
  4e:	27e080e7          	jalr	638(ra) # 2c8 <exit>

0000000000000052 <strcpy>:
}

char*
strcpy(char *s, const char *t)
{
  52:	1141                	addi	sp,sp,-16
  54:	e422                	sd	s0,8(sp)
  56:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while((*s++ = *t++) != 0)
  58:	87aa                	mv	a5,a0
  5a:	0585                	addi	a1,a1,1
  5c:	0785                	addi	a5,a5,1
  5e:	fff5c703          	lbu	a4,-1(a1)
  62:	fee78fa3          	sb	a4,-1(a5)
  66:	fb75                	bnez	a4,5a <strcpy+0x8>
    ;
  return os;
}
  68:	6422                	ld	s0,8(sp)
  6a:	0141                	addi	sp,sp,16
  6c:	8082                	ret

000000000000006e <strcmp>:

int
strcmp(const char *p, const char *q)
{
  6e:	1141                	addi	sp,sp,-16
  70:	e422                	sd	s0,8(sp)
  72:	0800                	addi	s0,sp,16
  while(*p && *p == *q)
  74:	00054783          	lbu	a5,0(a0)
  78:	cb91                	beqz	a5,8c <strcmp+0x1e>
  7a:	0005c703          	lbu	a4,0(a1)
  7e:	00f71763          	bne	a4,a5,8c <strcmp+0x1e>
    p++, q++;
  82:	0505                	addi	a0,a0,1
  84:	0585                	addi	a1,a1,1
  while(*p && *p == *q)
  86:	00054783          	lbu	a5,0(a0)
  8a:	fbe5                	bnez	a5,7a <strcmp+0xc>
  return (uchar)*p - (uchar)*q;
  8c:	0005c503          	lbu	a0,0(a1)
}
  90:	40a7853b          	subw	a0,a5,a0
  94:	6422                	ld	s0,8(sp)
  96:	0141                	addi	sp,sp,16
  98:	8082                	ret

000000000000009a <strlen>:

uint
strlen(const char *s)
{
  9a:	1141                	addi	sp,sp,-16
  9c:	e422                	sd	s0,8(sp)
  9e:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
  a0:	00054783          	lbu	a5,0(a0)
  a4:	cf91                	beqz	a5,c0 <strlen+0x26>
  a6:	0505                	addi	a0,a0,1
  a8:	87aa                	mv	a5,a0
  aa:	4685                	li	a3,1
  ac:	9e89                	subw	a3,a3,a0
  ae:	00f6853b          	addw	a0,a3,a5
  b2:	0785                	addi	a5,a5,1
  b4:	fff7c703          	lbu	a4,-1(a5)
  b8:	fb7d                	bnez	a4,ae <strlen+0x14>
    ;
  return n;
}
  ba:	6422                	ld	s0,8(sp)
  bc:	0141                	addi	sp,sp,16
  be:	8082                	ret
  for(n = 0; s[n]; n++)
  c0:	4501                	li	a0,0
  c2:	bfe5                	j	ba <strlen+0x20>

00000000000000c4 <memset>:

void*
memset(void *dst, int c, uint n)
{
  c4:	1141                	addi	sp,sp,-16
  c6:	e422                	sd	s0,8(sp)
  c8:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
  ca:	ce09                	beqz	a2,e4 <memset+0x20>
  cc:	87aa                	mv	a5,a0
  ce:	fff6071b          	addiw	a4,a2,-1
  d2:	1702                	slli	a4,a4,0x20
  d4:	9301                	srli	a4,a4,0x20
  d6:	0705                	addi	a4,a4,1
  d8:	972a                	add	a4,a4,a0
    cdst[i] = c;
  da:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
  de:	0785                	addi	a5,a5,1
  e0:	fee79de3          	bne	a5,a4,da <memset+0x16>
  }
  return dst;
}
  e4:	6422                	ld	s0,8(sp)
  e6:	0141                	addi	sp,sp,16
  e8:	8082                	ret

00000000000000ea <strchr>:

char*
strchr(const char *s, char c)
{
  ea:	1141                	addi	sp,sp,-16
  ec:	e422                	sd	s0,8(sp)
  ee:	0800                	addi	s0,sp,16
  for(; *s; s++)
  f0:	00054783          	lbu	a5,0(a0)
  f4:	cb99                	beqz	a5,10a <strchr+0x20>
    if(*s == c)
  f6:	00f58763          	beq	a1,a5,104 <strchr+0x1a>
  for(; *s; s++)
  fa:	0505                	addi	a0,a0,1
  fc:	00054783          	lbu	a5,0(a0)
 100:	fbfd                	bnez	a5,f6 <strchr+0xc>
      return (char*)s;
  return 0;
 102:	4501                	li	a0,0
}
 104:	6422                	ld	s0,8(sp)
 106:	0141                	addi	sp,sp,16
 108:	8082                	ret
  return 0;
 10a:	4501                	li	a0,0
 10c:	bfe5                	j	104 <strchr+0x1a>

000000000000010e <gets>:

char*
gets(char *buf, int max)
{
 10e:	711d                	addi	sp,sp,-96
 110:	ec86                	sd	ra,88(sp)
 112:	e8a2                	sd	s0,80(sp)
 114:	e4a6                	sd	s1,72(sp)
 116:	e0ca                	sd	s2,64(sp)
 118:	fc4e                	sd	s3,56(sp)
 11a:	f852                	sd	s4,48(sp)
 11c:	f456                	sd	s5,40(sp)
 11e:	f05a                	sd	s6,32(sp)
 120:	ec5e                	sd	s7,24(sp)
 122:	1080                	addi	s0,sp,96
 124:	8baa                	mv	s7,a0
 126:	8a2e                	mv	s4,a1
  int i, cc;
  char c;

  for(i=0; i+1 < max; ){
 128:	892a                	mv	s2,a0
 12a:	4481                	li	s1,0
    cc = read(0, &c, 1);
    if(cc < 1)
      break;
    buf[i++] = c;
    if(c == '\n' || c == '\r')
 12c:	4aa9                	li	s5,10
 12e:	4b35                	li	s6,13
  for(i=0; i+1 < max; ){
 130:	89a6                	mv	s3,s1
 132:	2485                	addiw	s1,s1,1
 134:	0344d863          	bge	s1,s4,164 <gets+0x56>
    cc = read(0, &c, 1);
 138:	4605                	li	a2,1
 13a:	faf40593          	addi	a1,s0,-81
 13e:	4501                	li	a0,0
 140:	00000097          	auipc	ra,0x0
 144:	1a0080e7          	jalr	416(ra) # 2e0 <read>
    if(cc < 1)
 148:	00a05e63          	blez	a0,164 <gets+0x56>
    buf[i++] = c;
 14c:	faf44783          	lbu	a5,-81(s0)
 150:	00f90023          	sb	a5,0(s2)
    if(c == '\n' || c == '\r')
 154:	01578763          	beq	a5,s5,162 <gets+0x54>
 158:	0905                	addi	s2,s2,1
 15a:	fd679be3          	bne	a5,s6,130 <gets+0x22>
  for(i=0; i+1 < max; ){
 15e:	89a6                	mv	s3,s1
 160:	a011                	j	164 <gets+0x56>
 162:	89a6                	mv	s3,s1
      break;
  }
  buf[i] = '\0';
 164:	99de                	add	s3,s3,s7
 166:	00098023          	sb	zero,0(s3)
  return buf;
}
 16a:	855e                	mv	a0,s7
 16c:	60e6                	ld	ra,88(sp)
 16e:	6446                	ld	s0,80(sp)
 170:	64a6                	ld	s1,72(sp)
 172:	6906                	ld	s2,64(sp)
 174:	79e2                	ld	s3,56(sp)
 176:	7a42                	ld	s4,48(sp)
 178:	7aa2                	ld	s5,40(sp)
 17a:	7b02                	ld	s6,32(sp)
 17c:	6be2                	ld	s7,24(sp)
 17e:	6125                	addi	sp,sp,96
 180:	8082                	ret

0000000000000182 <stat>:

int
stat(const char *n, struct stat *st)
{
 182:	1101                	addi	sp,sp,-32
 184:	ec06                	sd	ra,24(sp)
 186:	e822                	sd	s0,16(sp)
 188:	e426                	sd	s1,8(sp)
 18a:	e04a                	sd	s2,0(sp)
 18c:	1000                	addi	s0,sp,32
 18e:	892e                	mv	s2,a1
  int fd;
  int r;

  fd = open(n, O_RDONLY);
 190:	4581                	li	a1,0
 192:	00000097          	auipc	ra,0x0
 196:	176080e7          	jalr	374(ra) # 308 <open>
  if(fd < 0)
 19a:	02054563          	bltz	a0,1c4 <stat+0x42>
 19e:	84aa                	mv	s1,a0
    return -1;
  r = fstat(fd, st);
 1a0:	85ca                	mv	a1,s2
 1a2:	00000097          	auipc	ra,0x0
 1a6:	17e080e7          	jalr	382(ra) # 320 <fstat>
 1aa:	892a                	mv	s2,a0
  close(fd);
 1ac:	8526                	mv	a0,s1
 1ae:	00000097          	auipc	ra,0x0
 1b2:	142080e7          	jalr	322(ra) # 2f0 <close>
  return r;
}
 1b6:	854a                	mv	a0,s2
 1b8:	60e2                	ld	ra,24(sp)
 1ba:	6442                	ld	s0,16(sp)
 1bc:	64a2                	ld	s1,8(sp)
 1be:	6902                	ld	s2,0(sp)
 1c0:	6105                	addi	sp,sp,32
 1c2:	8082                	ret
    return -1;
 1c4:	597d                	li	s2,-1
 1c6:	bfc5                	j	1b6 <stat+0x34>

00000000000001c8 <atoi>:

int
atoi(const char *s)
{
 1c8:	1141                	addi	sp,sp,-16
 1ca:	e422                	sd	s0,8(sp)
 1cc:	0800                	addi	s0,sp,16
  int n;

  n = 0;
  while('0' <= *s && *s <= '9')
 1ce:	00054603          	lbu	a2,0(a0)
 1d2:	fd06079b          	addiw	a5,a2,-48
 1d6:	0ff7f793          	andi	a5,a5,255
 1da:	4725                	li	a4,9
 1dc:	02f76963          	bltu	a4,a5,20e <atoi+0x46>
 1e0:	86aa                	mv	a3,a0
  n = 0;
 1e2:	4501                	li	a0,0
  while('0' <= *s && *s <= '9')
 1e4:	45a5                	li	a1,9
    n = n*10 + *s++ - '0';
 1e6:	0685                	addi	a3,a3,1
 1e8:	0025179b          	slliw	a5,a0,0x2
 1ec:	9fa9                	addw	a5,a5,a0
 1ee:	0017979b          	slliw	a5,a5,0x1
 1f2:	9fb1                	addw	a5,a5,a2
 1f4:	fd07851b          	addiw	a0,a5,-48
  while('0' <= *s && *s <= '9')
 1f8:	0006c603          	lbu	a2,0(a3)
 1fc:	fd06071b          	addiw	a4,a2,-48
 200:	0ff77713          	andi	a4,a4,255
 204:	fee5f1e3          	bgeu	a1,a4,1e6 <atoi+0x1e>
  return n;
}
 208:	6422                	ld	s0,8(sp)
 20a:	0141                	addi	sp,sp,16
 20c:	8082                	ret
  n = 0;
 20e:	4501                	li	a0,0
 210:	bfe5                	j	208 <atoi+0x40>

0000000000000212 <memmove>:

void*
memmove(void *vdst, const void *vsrc, int n)
{
 212:	1141                	addi	sp,sp,-16
 214:	e422                	sd	s0,8(sp)
 216:	0800                	addi	s0,sp,16
  char *dst;
  const char *src;

  dst = vdst;
  src = vsrc;
  if (src > dst) {
 218:	02b57663          	bgeu	a0,a1,244 <memmove+0x32>
    while(n-- > 0)
 21c:	02c05163          	blez	a2,23e <memmove+0x2c>
 220:	fff6079b          	addiw	a5,a2,-1
 224:	1782                	slli	a5,a5,0x20
 226:	9381                	srli	a5,a5,0x20
 228:	0785                	addi	a5,a5,1
 22a:	97aa                	add	a5,a5,a0
  dst = vdst;
 22c:	872a                	mv	a4,a0
      *dst++ = *src++;
 22e:	0585                	addi	a1,a1,1
 230:	0705                	addi	a4,a4,1
 232:	fff5c683          	lbu	a3,-1(a1)
 236:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
 23a:	fee79ae3          	bne	a5,a4,22e <memmove+0x1c>
    src += n;
    while(n-- > 0)
      *--dst = *--src;
  }
  return vdst;
}
 23e:	6422                	ld	s0,8(sp)
 240:	0141                	addi	sp,sp,16
 242:	8082                	ret
    dst += n;
 244:	00c50733          	add	a4,a0,a2
    src += n;
 248:	95b2                	add	a1,a1,a2
    while(n-- > 0)
 24a:	fec05ae3          	blez	a2,23e <memmove+0x2c>
 24e:	fff6079b          	addiw	a5,a2,-1
 252:	1782                	slli	a5,a5,0x20
 254:	9381                	srli	a5,a5,0x20
 256:	fff7c793          	not	a5,a5
 25a:	97ba                	add	a5,a5,a4
      *--dst = *--src;
 25c:	15fd                	addi	a1,a1,-1
 25e:	177d                	addi	a4,a4,-1
 260:	0005c683          	lbu	a3,0(a1)
 264:	00d70023          	sb	a3,0(a4)
    while(n-- > 0)
 268:	fee79ae3          	bne	a5,a4,25c <memmove+0x4a>
 26c:	bfc9                	j	23e <memmove+0x2c>

000000000000026e <memcmp>:

int
memcmp(const void *s1, const void *s2, uint n)
{
 26e:	1141                	addi	sp,sp,-16
 270:	e422                	sd	s0,8(sp)
 272:	0800                	addi	s0,sp,16
  const char *p1 = s1, *p2 = s2;
  while (n-- > 0) {
 274:	ca05                	beqz	a2,2a4 <memcmp+0x36>
 276:	fff6069b          	addiw	a3,a2,-1
 27a:	1682                	slli	a3,a3,0x20
 27c:	9281                	srli	a3,a3,0x20
 27e:	0685                	addi	a3,a3,1
 280:	96aa                	add	a3,a3,a0
    if (*p1 != *p2) {
 282:	00054783          	lbu	a5,0(a0)
 286:	0005c703          	lbu	a4,0(a1)
 28a:	00e79863          	bne	a5,a4,29a <memcmp+0x2c>
      return *p1 - *p2;
    }
    p1++;
 28e:	0505                	addi	a0,a0,1
    p2++;
 290:	0585                	addi	a1,a1,1
  while (n-- > 0) {
 292:	fed518e3          	bne	a0,a3,282 <memcmp+0x14>
  }
  return 0;
 296:	4501                	li	a0,0
 298:	a019                	j	29e <memcmp+0x30>
      return *p1 - *p2;
 29a:	40e7853b          	subw	a0,a5,a4
}
 29e:	6422                	ld	s0,8(sp)
 2a0:	0141                	addi	sp,sp,16
 2a2:	8082                	ret
  return 0;
 2a4:	4501                	li	a0,0
 2a6:	bfe5                	j	29e <memcmp+0x30>

00000000000002a8 <memcpy>:

void *
memcpy(void *dst, const void *src, uint n)
{
 2a8:	1141                	addi	sp,sp,-16
 2aa:	e406                	sd	ra,8(sp)
 2ac:	e022                	sd	s0,0(sp)
 2ae:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
 2b0:	00000097          	auipc	ra,0x0
 2b4:	f62080e7          	jalr	-158(ra) # 212 <memmove>
}
 2b8:	60a2                	ld	ra,8(sp)
 2ba:	6402                	ld	s0,0(sp)
 2bc:	0141                	addi	sp,sp,16
 2be:	8082                	ret

00000000000002c0 <fork>:
# generated by usys.pl - do not edit
#include "kernel/syscall.h"
.global fork
fork:
 li a7, SYS_fork
 2c0:	4885                	li	a7,1
 ecall
 2c2:	00000073          	ecall
 ret
 2c6:	8082                	ret

00000000000002c8 <exit>:
.global exit
exit:
 li a7, SYS_exit
 2c8:	4889                	li	a7,2
 ecall
 2ca:	00000073          	ecall
 ret
 2ce:	8082                	ret

00000000000002d0 <wait>:
.global wait
wait:
 li a7, SYS_wait
 2d0:	488d                	li	a7,3
 ecall
 2d2:	00000073          	ecall
 ret
 2d6:	8082                	ret

00000000000002d8 <pipe>:
.global pipe
pipe:
 li a7, SYS_pipe
 2d8:	4891                	li	a7,4
 ecall
 2da:	00000073          	ecall
 ret
 2de:	8082                	ret

00000000000002e0 <read>:
.global read
read:
 li a7, SYS_read
 2e0:	4895                	li	a7,5
 ecall
 2e2:	00000073          	ecall
 ret
 2e6:	8082                	ret

00000000000002e8 <write>:
.global write
write:
 li a7, SYS_write
 2e8:	48c1                	li	a7,16
 ecall
 2ea:	00000073          	ecall
 ret
 2ee:	8082                	ret

00000000000002f0 <close>:
.global close
close:
 li a7, SYS_close
 2f0:	48d5                	li	a7,21
 ecall
 2f2:	00000073          	ecall
 ret
 2f6:	8082                	ret

00000000000002f8 <kill>:
.global kill
kill:
 li a7, SYS_kill
 2f8:	4899                	li	a7,6
 ecall
 2fa:	00000073          	ecall
 ret
 2fe:	8082                	ret

0000000000000300 <exec>:
.global exec
exec:
 li a7, SYS_exec
 300:	489d                	li	a7,7
 ecall
 302:	00000073          	ecall
 ret
 306:	8082                	ret

0000000000000308 <open>:
.global open
open:
 li a7, SYS_open
 308:	48bd                	li	a7,15
 ecall
 30a:	00000073          	ecall
 ret
 30e:	8082                	ret

0000000000000310 <mknod>:
.global mknod
mknod:
 li a7, SYS_mknod
 310:	48c5                	li	a7,17
 ecall
 312:	00000073          	ecall
 ret
 316:	8082                	ret

0000000000000318 <unlink>:
.global unlink
unlink:
 li a7, SYS_unlink
 318:	48c9                	li	a7,18
 ecall
 31a:	00000073          	ecall
 ret
 31e:	8082                	ret

0000000000000320 <fstat>:
.global fstat
fstat:
 li a7, SYS_fstat
 320:	48a1                	li	a7,8
 ecall
 322:	00000073          	ecall
 ret
 326:	8082                	ret

0000000000000328 <link>:
.global link
link:
 li a7, SYS_link
 328:	48cd                	li	a7,19
 ecall
 32a:	00000073          	ecall
 ret
 32e:	8082                	ret

0000000000000330 <mkdir>:
.global mkdir
mkdir:
 li a7, SYS_mkdir
 330:	48d1                	li	a7,20
 ecall
 332:	00000073          	ecall
 ret
 336:	8082                	ret

0000000000000338 <chdir>:
.global chdir
chdir:
 li a7, SYS_chdir
 338:	48a5                	li	a7,9
 ecall
 33a:	00000073          	ecall
 ret
 33e:	8082                	ret

0000000000000340 <dup>:
.global dup
dup:
 li a7, SYS_dup
 340:	48a9                	li	a7,10
 ecall
 342:	00000073          	ecall
 ret
 346:	8082                	ret

0000000000000348 <getpid>:
.global getpid
getpid:
 li a7, SYS_getpid
 348:	48ad                	li	a7,11
 ecall
 34a:	00000073          	ecall
 ret
 34e:	8082                	ret

0000000000000350 <sbrk>:
.global sbrk
sbrk:
 li a7, SYS_sbrk
 350:	48b1                	li	a7,12
 ecall
 352:	00000073          	ecall
 ret
 356:	8082                	ret

0000000000000358 <sleep>:
.global sleep
sleep:
 li a7, SYS_sleep
 358:	48b5                	li	a7,13
 ecall
 35a:	00000073          	ecall
 ret
 35e:	8082                	ret

0000000000000360 <uptime>:
.global uptime
uptime:
 li a7, SYS_uptime
 360:	48b9                	li	a7,14
 ecall
 362:	00000073          	ecall
 ret
 366:	8082                	ret

0000000000000368 <sigreturn>:
.global sigreturn
sigreturn:
 li a7, SYS_sigreturn
 368:	48dd                	li	a7,23
 ecall
 36a:	00000073          	ecall
 ret
 36e:	8082                	ret

0000000000000370 <sigalarm>:
.global sigalarm
sigalarm:
 li a7, SYS_sigalarm
 370:	48d9                	li	a7,22
 ecall
 372:	00000073          	ecall
 ret
 376:	8082                	ret

0000000000000378 <trace>:
.global trace
trace:
 li a7, SYS_trace
 378:	48e1                	li	a7,24
 ecall
 37a:	00000073          	ecall
 ret
 37e:	8082                	ret

0000000000000380 <waitx>:
.global waitx
waitx:
 li a7, SYS_waitx
 380:	48e9                	li	a7,26
 ecall
 382:	00000073          	ecall
 ret
 386:	8082                	ret

0000000000000388 <set_priority>:
.global set_priority
set_priority:
 li a7, SYS_set_priority
 388:	48e5                	li	a7,25
 ecall
 38a:	00000073          	ecall
 ret
 38e:	8082                	ret

0000000000000390 <putc>:

static char digits[] = "0123456789ABCDEF";

static void
putc(int fd, char c)
{
 390:	1101                	addi	sp,sp,-32
 392:	ec06                	sd	ra,24(sp)
 394:	e822                	sd	s0,16(sp)
 396:	1000                	addi	s0,sp,32
 398:	feb407a3          	sb	a1,-17(s0)
  write(fd, &c, 1);
 39c:	4605                	li	a2,1
 39e:	fef40593          	addi	a1,s0,-17
 3a2:	00000097          	auipc	ra,0x0
 3a6:	f46080e7          	jalr	-186(ra) # 2e8 <write>
}
 3aa:	60e2                	ld	ra,24(sp)
 3ac:	6442                	ld	s0,16(sp)
 3ae:	6105                	addi	sp,sp,32
 3b0:	8082                	ret

00000000000003b2 <printint>:

static void
printint(int fd, int xx, int base, int sgn)
{
 3b2:	7139                	addi	sp,sp,-64
 3b4:	fc06                	sd	ra,56(sp)
 3b6:	f822                	sd	s0,48(sp)
 3b8:	f426                	sd	s1,40(sp)
 3ba:	f04a                	sd	s2,32(sp)
 3bc:	ec4e                	sd	s3,24(sp)
 3be:	0080                	addi	s0,sp,64
 3c0:	84aa                	mv	s1,a0
  char buf[16];
  int i, neg;
  uint x;

  neg = 0;
  if(sgn && xx < 0){
 3c2:	c299                	beqz	a3,3c8 <printint+0x16>
 3c4:	0805c863          	bltz	a1,454 <printint+0xa2>
    neg = 1;
    x = -xx;
  } else {
    x = xx;
 3c8:	2581                	sext.w	a1,a1
  neg = 0;
 3ca:	4881                	li	a7,0
 3cc:	fc040693          	addi	a3,s0,-64
  }

  i = 0;
 3d0:	4701                	li	a4,0
  do{
    buf[i++] = digits[x % base];
 3d2:	2601                	sext.w	a2,a2
 3d4:	00000517          	auipc	a0,0x0
 3d8:	44450513          	addi	a0,a0,1092 # 818 <digits>
 3dc:	883a                	mv	a6,a4
 3de:	2705                	addiw	a4,a4,1
 3e0:	02c5f7bb          	remuw	a5,a1,a2
 3e4:	1782                	slli	a5,a5,0x20
 3e6:	9381                	srli	a5,a5,0x20
 3e8:	97aa                	add	a5,a5,a0
 3ea:	0007c783          	lbu	a5,0(a5)
 3ee:	00f68023          	sb	a5,0(a3)
  }while((x /= base) != 0);
 3f2:	0005879b          	sext.w	a5,a1
 3f6:	02c5d5bb          	divuw	a1,a1,a2
 3fa:	0685                	addi	a3,a3,1
 3fc:	fec7f0e3          	bgeu	a5,a2,3dc <printint+0x2a>
  if(neg)
 400:	00088b63          	beqz	a7,416 <printint+0x64>
    buf[i++] = '-';
 404:	fd040793          	addi	a5,s0,-48
 408:	973e                	add	a4,a4,a5
 40a:	02d00793          	li	a5,45
 40e:	fef70823          	sb	a5,-16(a4)
 412:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
 416:	02e05863          	blez	a4,446 <printint+0x94>
 41a:	fc040793          	addi	a5,s0,-64
 41e:	00e78933          	add	s2,a5,a4
 422:	fff78993          	addi	s3,a5,-1
 426:	99ba                	add	s3,s3,a4
 428:	377d                	addiw	a4,a4,-1
 42a:	1702                	slli	a4,a4,0x20
 42c:	9301                	srli	a4,a4,0x20
 42e:	40e989b3          	sub	s3,s3,a4
    putc(fd, buf[i]);
 432:	fff94583          	lbu	a1,-1(s2)
 436:	8526                	mv	a0,s1
 438:	00000097          	auipc	ra,0x0
 43c:	f58080e7          	jalr	-168(ra) # 390 <putc>
  while(--i >= 0)
 440:	197d                	addi	s2,s2,-1
 442:	ff3918e3          	bne	s2,s3,432 <printint+0x80>
}
 446:	70e2                	ld	ra,56(sp)
 448:	7442                	ld	s0,48(sp)
 44a:	74a2                	ld	s1,40(sp)
 44c:	7902                	ld	s2,32(sp)
 44e:	69e2                	ld	s3,24(sp)
 450:	6121                	addi	sp,sp,64
 452:	8082                	ret
    x = -xx;
 454:	40b005bb          	negw	a1,a1
    neg = 1;
 458:	4885                	li	a7,1
    x = -xx;
 45a:	bf8d                	j	3cc <printint+0x1a>

000000000000045c <vprintf>:
}

// Print to the given fd. Only understands %d, %x, %p, %s.
void
vprintf(int fd, const char *fmt, va_list ap)
{
 45c:	7119                	addi	sp,sp,-128
 45e:	fc86                	sd	ra,120(sp)
 460:	f8a2                	sd	s0,112(sp)
 462:	f4a6                	sd	s1,104(sp)
 464:	f0ca                	sd	s2,96(sp)
 466:	ecce                	sd	s3,88(sp)
 468:	e8d2                	sd	s4,80(sp)
 46a:	e4d6                	sd	s5,72(sp)
 46c:	e0da                	sd	s6,64(sp)
 46e:	fc5e                	sd	s7,56(sp)
 470:	f862                	sd	s8,48(sp)
 472:	f466                	sd	s9,40(sp)
 474:	f06a                	sd	s10,32(sp)
 476:	ec6e                	sd	s11,24(sp)
 478:	0100                	addi	s0,sp,128
  char *s;
  int c, i, state;

  state = 0;
  for(i = 0; fmt[i]; i++){
 47a:	0005c903          	lbu	s2,0(a1)
 47e:	18090f63          	beqz	s2,61c <vprintf+0x1c0>
 482:	8aaa                	mv	s5,a0
 484:	8b32                	mv	s6,a2
 486:	00158493          	addi	s1,a1,1
  state = 0;
 48a:	4981                	li	s3,0
      if(c == '%'){
        state = '%';
      } else {
        putc(fd, c);
      }
    } else if(state == '%'){
 48c:	02500a13          	li	s4,37
      if(c == 'd'){
 490:	06400c13          	li	s8,100
        printint(fd, va_arg(ap, int), 10, 1);
      } else if(c == 'l') {
 494:	06c00c93          	li	s9,108
        printint(fd, va_arg(ap, uint64), 10, 0);
      } else if(c == 'x') {
 498:	07800d13          	li	s10,120
        printint(fd, va_arg(ap, int), 16, 0);
      } else if(c == 'p') {
 49c:	07000d93          	li	s11,112
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 4a0:	00000b97          	auipc	s7,0x0
 4a4:	378b8b93          	addi	s7,s7,888 # 818 <digits>
 4a8:	a839                	j	4c6 <vprintf+0x6a>
        putc(fd, c);
 4aa:	85ca                	mv	a1,s2
 4ac:	8556                	mv	a0,s5
 4ae:	00000097          	auipc	ra,0x0
 4b2:	ee2080e7          	jalr	-286(ra) # 390 <putc>
 4b6:	a019                	j	4bc <vprintf+0x60>
    } else if(state == '%'){
 4b8:	01498f63          	beq	s3,s4,4d6 <vprintf+0x7a>
  for(i = 0; fmt[i]; i++){
 4bc:	0485                	addi	s1,s1,1
 4be:	fff4c903          	lbu	s2,-1(s1)
 4c2:	14090d63          	beqz	s2,61c <vprintf+0x1c0>
    c = fmt[i] & 0xff;
 4c6:	0009079b          	sext.w	a5,s2
    if(state == 0){
 4ca:	fe0997e3          	bnez	s3,4b8 <vprintf+0x5c>
      if(c == '%'){
 4ce:	fd479ee3          	bne	a5,s4,4aa <vprintf+0x4e>
        state = '%';
 4d2:	89be                	mv	s3,a5
 4d4:	b7e5                	j	4bc <vprintf+0x60>
      if(c == 'd'){
 4d6:	05878063          	beq	a5,s8,516 <vprintf+0xba>
      } else if(c == 'l') {
 4da:	05978c63          	beq	a5,s9,532 <vprintf+0xd6>
      } else if(c == 'x') {
 4de:	07a78863          	beq	a5,s10,54e <vprintf+0xf2>
      } else if(c == 'p') {
 4e2:	09b78463          	beq	a5,s11,56a <vprintf+0x10e>
        printptr(fd, va_arg(ap, uint64));
      } else if(c == 's'){
 4e6:	07300713          	li	a4,115
 4ea:	0ce78663          	beq	a5,a4,5b6 <vprintf+0x15a>
          s = "(null)";
        while(*s != 0){
          putc(fd, *s);
          s++;
        }
      } else if(c == 'c'){
 4ee:	06300713          	li	a4,99
 4f2:	0ee78e63          	beq	a5,a4,5ee <vprintf+0x192>
        putc(fd, va_arg(ap, uint));
      } else if(c == '%'){
 4f6:	11478863          	beq	a5,s4,606 <vprintf+0x1aa>
        putc(fd, c);
      } else {
        // Unknown % sequence.  Print it to draw attention.
        putc(fd, '%');
 4fa:	85d2                	mv	a1,s4
 4fc:	8556                	mv	a0,s5
 4fe:	00000097          	auipc	ra,0x0
 502:	e92080e7          	jalr	-366(ra) # 390 <putc>
        putc(fd, c);
 506:	85ca                	mv	a1,s2
 508:	8556                	mv	a0,s5
 50a:	00000097          	auipc	ra,0x0
 50e:	e86080e7          	jalr	-378(ra) # 390 <putc>
      }
      state = 0;
 512:	4981                	li	s3,0
 514:	b765                	j	4bc <vprintf+0x60>
        printint(fd, va_arg(ap, int), 10, 1);
 516:	008b0913          	addi	s2,s6,8
 51a:	4685                	li	a3,1
 51c:	4629                	li	a2,10
 51e:	000b2583          	lw	a1,0(s6)
 522:	8556                	mv	a0,s5
 524:	00000097          	auipc	ra,0x0
 528:	e8e080e7          	jalr	-370(ra) # 3b2 <printint>
 52c:	8b4a                	mv	s6,s2
      state = 0;
 52e:	4981                	li	s3,0
 530:	b771                	j	4bc <vprintf+0x60>
        printint(fd, va_arg(ap, uint64), 10, 0);
 532:	008b0913          	addi	s2,s6,8
 536:	4681                	li	a3,0
 538:	4629                	li	a2,10
 53a:	000b2583          	lw	a1,0(s6)
 53e:	8556                	mv	a0,s5
 540:	00000097          	auipc	ra,0x0
 544:	e72080e7          	jalr	-398(ra) # 3b2 <printint>
 548:	8b4a                	mv	s6,s2
      state = 0;
 54a:	4981                	li	s3,0
 54c:	bf85                	j	4bc <vprintf+0x60>
        printint(fd, va_arg(ap, int), 16, 0);
 54e:	008b0913          	addi	s2,s6,8
 552:	4681                	li	a3,0
 554:	4641                	li	a2,16
 556:	000b2583          	lw	a1,0(s6)
 55a:	8556                	mv	a0,s5
 55c:	00000097          	auipc	ra,0x0
 560:	e56080e7          	jalr	-426(ra) # 3b2 <printint>
 564:	8b4a                	mv	s6,s2
      state = 0;
 566:	4981                	li	s3,0
 568:	bf91                	j	4bc <vprintf+0x60>
        printptr(fd, va_arg(ap, uint64));
 56a:	008b0793          	addi	a5,s6,8
 56e:	f8f43423          	sd	a5,-120(s0)
 572:	000b3983          	ld	s3,0(s6)
  putc(fd, '0');
 576:	03000593          	li	a1,48
 57a:	8556                	mv	a0,s5
 57c:	00000097          	auipc	ra,0x0
 580:	e14080e7          	jalr	-492(ra) # 390 <putc>
  putc(fd, 'x');
 584:	85ea                	mv	a1,s10
 586:	8556                	mv	a0,s5
 588:	00000097          	auipc	ra,0x0
 58c:	e08080e7          	jalr	-504(ra) # 390 <putc>
 590:	4941                	li	s2,16
    putc(fd, digits[x >> (sizeof(uint64) * 8 - 4)]);
 592:	03c9d793          	srli	a5,s3,0x3c
 596:	97de                	add	a5,a5,s7
 598:	0007c583          	lbu	a1,0(a5)
 59c:	8556                	mv	a0,s5
 59e:	00000097          	auipc	ra,0x0
 5a2:	df2080e7          	jalr	-526(ra) # 390 <putc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
 5a6:	0992                	slli	s3,s3,0x4
 5a8:	397d                	addiw	s2,s2,-1
 5aa:	fe0914e3          	bnez	s2,592 <vprintf+0x136>
        printptr(fd, va_arg(ap, uint64));
 5ae:	f8843b03          	ld	s6,-120(s0)
      state = 0;
 5b2:	4981                	li	s3,0
 5b4:	b721                	j	4bc <vprintf+0x60>
        s = va_arg(ap, char*);
 5b6:	008b0993          	addi	s3,s6,8
 5ba:	000b3903          	ld	s2,0(s6)
        if(s == 0)
 5be:	02090163          	beqz	s2,5e0 <vprintf+0x184>
        while(*s != 0){
 5c2:	00094583          	lbu	a1,0(s2)
 5c6:	c9a1                	beqz	a1,616 <vprintf+0x1ba>
          putc(fd, *s);
 5c8:	8556                	mv	a0,s5
 5ca:	00000097          	auipc	ra,0x0
 5ce:	dc6080e7          	jalr	-570(ra) # 390 <putc>
          s++;
 5d2:	0905                	addi	s2,s2,1
        while(*s != 0){
 5d4:	00094583          	lbu	a1,0(s2)
 5d8:	f9e5                	bnez	a1,5c8 <vprintf+0x16c>
        s = va_arg(ap, char*);
 5da:	8b4e                	mv	s6,s3
      state = 0;
 5dc:	4981                	li	s3,0
 5de:	bdf9                	j	4bc <vprintf+0x60>
          s = "(null)";
 5e0:	00000917          	auipc	s2,0x0
 5e4:	23090913          	addi	s2,s2,560 # 810 <malloc+0xea>
        while(*s != 0){
 5e8:	02800593          	li	a1,40
 5ec:	bff1                	j	5c8 <vprintf+0x16c>
        putc(fd, va_arg(ap, uint));
 5ee:	008b0913          	addi	s2,s6,8
 5f2:	000b4583          	lbu	a1,0(s6)
 5f6:	8556                	mv	a0,s5
 5f8:	00000097          	auipc	ra,0x0
 5fc:	d98080e7          	jalr	-616(ra) # 390 <putc>
 600:	8b4a                	mv	s6,s2
      state = 0;
 602:	4981                	li	s3,0
 604:	bd65                	j	4bc <vprintf+0x60>
        putc(fd, c);
 606:	85d2                	mv	a1,s4
 608:	8556                	mv	a0,s5
 60a:	00000097          	auipc	ra,0x0
 60e:	d86080e7          	jalr	-634(ra) # 390 <putc>
      state = 0;
 612:	4981                	li	s3,0
 614:	b565                	j	4bc <vprintf+0x60>
        s = va_arg(ap, char*);
 616:	8b4e                	mv	s6,s3
      state = 0;
 618:	4981                	li	s3,0
 61a:	b54d                	j	4bc <vprintf+0x60>
    }
  }
}
 61c:	70e6                	ld	ra,120(sp)
 61e:	7446                	ld	s0,112(sp)
 620:	74a6                	ld	s1,104(sp)
 622:	7906                	ld	s2,96(sp)
 624:	69e6                	ld	s3,88(sp)
 626:	6a46                	ld	s4,80(sp)
 628:	6aa6                	ld	s5,72(sp)
 62a:	6b06                	ld	s6,64(sp)
 62c:	7be2                	ld	s7,56(sp)
 62e:	7c42                	ld	s8,48(sp)
 630:	7ca2                	ld	s9,40(sp)
 632:	7d02                	ld	s10,32(sp)
 634:	6de2                	ld	s11,24(sp)
 636:	6109                	addi	sp,sp,128
 638:	8082                	ret

000000000000063a <fprintf>:

void
fprintf(int fd, const char *fmt, ...)
{
 63a:	715d                	addi	sp,sp,-80
 63c:	ec06                	sd	ra,24(sp)
 63e:	e822                	sd	s0,16(sp)
 640:	1000                	addi	s0,sp,32
 642:	e010                	sd	a2,0(s0)
 644:	e414                	sd	a3,8(s0)
 646:	e818                	sd	a4,16(s0)
 648:	ec1c                	sd	a5,24(s0)
 64a:	03043023          	sd	a6,32(s0)
 64e:	03143423          	sd	a7,40(s0)
  va_list ap;

  va_start(ap, fmt);
 652:	fe843423          	sd	s0,-24(s0)
  vprintf(fd, fmt, ap);
 656:	8622                	mv	a2,s0
 658:	00000097          	auipc	ra,0x0
 65c:	e04080e7          	jalr	-508(ra) # 45c <vprintf>
}
 660:	60e2                	ld	ra,24(sp)
 662:	6442                	ld	s0,16(sp)
 664:	6161                	addi	sp,sp,80
 666:	8082                	ret

0000000000000668 <printf>:

void
printf(const char *fmt, ...)
{
 668:	711d                	addi	sp,sp,-96
 66a:	ec06                	sd	ra,24(sp)
 66c:	e822                	sd	s0,16(sp)
 66e:	1000                	addi	s0,sp,32
 670:	e40c                	sd	a1,8(s0)
 672:	e810                	sd	a2,16(s0)
 674:	ec14                	sd	a3,24(s0)
 676:	f018                	sd	a4,32(s0)
 678:	f41c                	sd	a5,40(s0)
 67a:	03043823          	sd	a6,48(s0)
 67e:	03143c23          	sd	a7,56(s0)
  va_list ap;

  va_start(ap, fmt);
 682:	00840613          	addi	a2,s0,8
 686:	fec43423          	sd	a2,-24(s0)
  vprintf(1, fmt, ap);
 68a:	85aa                	mv	a1,a0
 68c:	4505                	li	a0,1
 68e:	00000097          	auipc	ra,0x0
 692:	dce080e7          	jalr	-562(ra) # 45c <vprintf>
}
 696:	60e2                	ld	ra,24(sp)
 698:	6442                	ld	s0,16(sp)
 69a:	6125                	addi	sp,sp,96
 69c:	8082                	ret

000000000000069e <free>:
static Header base;
static Header *freep;

void
free(void *ap)
{
 69e:	1141                	addi	sp,sp,-16
 6a0:	e422                	sd	s0,8(sp)
 6a2:	0800                	addi	s0,sp,16
  Header *bp, *p;

  bp = (Header*)ap - 1;
 6a4:	ff050693          	addi	a3,a0,-16
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6a8:	00001797          	auipc	a5,0x1
 6ac:	9587b783          	ld	a5,-1704(a5) # 1000 <freep>
 6b0:	a805                	j	6e0 <free+0x42>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
      break;
  if(bp + bp->s.size == p->s.ptr){
    bp->s.size += p->s.ptr->s.size;
 6b2:	4618                	lw	a4,8(a2)
 6b4:	9db9                	addw	a1,a1,a4
 6b6:	feb52c23          	sw	a1,-8(a0)
    bp->s.ptr = p->s.ptr->s.ptr;
 6ba:	6398                	ld	a4,0(a5)
 6bc:	6318                	ld	a4,0(a4)
 6be:	fee53823          	sd	a4,-16(a0)
 6c2:	a091                	j	706 <free+0x68>
  } else
    bp->s.ptr = p->s.ptr;
  if(p + p->s.size == bp){
    p->s.size += bp->s.size;
 6c4:	ff852703          	lw	a4,-8(a0)
 6c8:	9e39                	addw	a2,a2,a4
 6ca:	c790                	sw	a2,8(a5)
    p->s.ptr = bp->s.ptr;
 6cc:	ff053703          	ld	a4,-16(a0)
 6d0:	e398                	sd	a4,0(a5)
 6d2:	a099                	j	718 <free+0x7a>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 6d4:	6398                	ld	a4,0(a5)
 6d6:	00e7e463          	bltu	a5,a4,6de <free+0x40>
 6da:	00e6ea63          	bltu	a3,a4,6ee <free+0x50>
{
 6de:	87ba                	mv	a5,a4
  for(p = freep; !(bp > p && bp < p->s.ptr); p = p->s.ptr)
 6e0:	fed7fae3          	bgeu	a5,a3,6d4 <free+0x36>
 6e4:	6398                	ld	a4,0(a5)
 6e6:	00e6e463          	bltu	a3,a4,6ee <free+0x50>
    if(p >= p->s.ptr && (bp > p || bp < p->s.ptr))
 6ea:	fee7eae3          	bltu	a5,a4,6de <free+0x40>
  if(bp + bp->s.size == p->s.ptr){
 6ee:	ff852583          	lw	a1,-8(a0)
 6f2:	6390                	ld	a2,0(a5)
 6f4:	02059713          	slli	a4,a1,0x20
 6f8:	9301                	srli	a4,a4,0x20
 6fa:	0712                	slli	a4,a4,0x4
 6fc:	9736                	add	a4,a4,a3
 6fe:	fae60ae3          	beq	a2,a4,6b2 <free+0x14>
    bp->s.ptr = p->s.ptr;
 702:	fec53823          	sd	a2,-16(a0)
  if(p + p->s.size == bp){
 706:	4790                	lw	a2,8(a5)
 708:	02061713          	slli	a4,a2,0x20
 70c:	9301                	srli	a4,a4,0x20
 70e:	0712                	slli	a4,a4,0x4
 710:	973e                	add	a4,a4,a5
 712:	fae689e3          	beq	a3,a4,6c4 <free+0x26>
  } else
    p->s.ptr = bp;
 716:	e394                	sd	a3,0(a5)
  freep = p;
 718:	00001717          	auipc	a4,0x1
 71c:	8ef73423          	sd	a5,-1816(a4) # 1000 <freep>
}
 720:	6422                	ld	s0,8(sp)
 722:	0141                	addi	sp,sp,16
 724:	8082                	ret

0000000000000726 <malloc>:
  return freep;
}

void*
malloc(uint nbytes)
{
 726:	7139                	addi	sp,sp,-64
 728:	fc06                	sd	ra,56(sp)
 72a:	f822                	sd	s0,48(sp)
 72c:	f426                	sd	s1,40(sp)
 72e:	f04a                	sd	s2,32(sp)
 730:	ec4e                	sd	s3,24(sp)
 732:	e852                	sd	s4,16(sp)
 734:	e456                	sd	s5,8(sp)
 736:	e05a                	sd	s6,0(sp)
 738:	0080                	addi	s0,sp,64
  Header *p, *prevp;
  uint nunits;

  nunits = (nbytes + sizeof(Header) - 1)/sizeof(Header) + 1;
 73a:	02051493          	slli	s1,a0,0x20
 73e:	9081                	srli	s1,s1,0x20
 740:	04bd                	addi	s1,s1,15
 742:	8091                	srli	s1,s1,0x4
 744:	0014899b          	addiw	s3,s1,1
 748:	0485                	addi	s1,s1,1
  if((prevp = freep) == 0){
 74a:	00001517          	auipc	a0,0x1
 74e:	8b653503          	ld	a0,-1866(a0) # 1000 <freep>
 752:	c515                	beqz	a0,77e <malloc+0x58>
    base.s.ptr = freep = prevp = &base;
    base.s.size = 0;
  }
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 754:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 756:	4798                	lw	a4,8(a5)
 758:	02977f63          	bgeu	a4,s1,796 <malloc+0x70>
 75c:	8a4e                	mv	s4,s3
 75e:	0009871b          	sext.w	a4,s3
 762:	6685                	lui	a3,0x1
 764:	00d77363          	bgeu	a4,a3,76a <malloc+0x44>
 768:	6a05                	lui	s4,0x1
 76a:	000a0b1b          	sext.w	s6,s4
  p = sbrk(nu * sizeof(Header));
 76e:	004a1a1b          	slliw	s4,s4,0x4
        p->s.size = nunits;
      }
      freep = prevp;
      return (void*)(p + 1);
    }
    if(p == freep)
 772:	00001917          	auipc	s2,0x1
 776:	88e90913          	addi	s2,s2,-1906 # 1000 <freep>
  if(p == (char*)-1)
 77a:	5afd                	li	s5,-1
 77c:	a88d                	j	7ee <malloc+0xc8>
    base.s.ptr = freep = prevp = &base;
 77e:	00001797          	auipc	a5,0x1
 782:	89278793          	addi	a5,a5,-1902 # 1010 <base>
 786:	00001717          	auipc	a4,0x1
 78a:	86f73d23          	sd	a5,-1926(a4) # 1000 <freep>
 78e:	e39c                	sd	a5,0(a5)
    base.s.size = 0;
 790:	0007a423          	sw	zero,8(a5)
    if(p->s.size >= nunits){
 794:	b7e1                	j	75c <malloc+0x36>
      if(p->s.size == nunits)
 796:	02e48b63          	beq	s1,a4,7cc <malloc+0xa6>
        p->s.size -= nunits;
 79a:	4137073b          	subw	a4,a4,s3
 79e:	c798                	sw	a4,8(a5)
        p += p->s.size;
 7a0:	1702                	slli	a4,a4,0x20
 7a2:	9301                	srli	a4,a4,0x20
 7a4:	0712                	slli	a4,a4,0x4
 7a6:	97ba                	add	a5,a5,a4
        p->s.size = nunits;
 7a8:	0137a423          	sw	s3,8(a5)
      freep = prevp;
 7ac:	00001717          	auipc	a4,0x1
 7b0:	84a73a23          	sd	a0,-1964(a4) # 1000 <freep>
      return (void*)(p + 1);
 7b4:	01078513          	addi	a0,a5,16
      if((p = morecore(nunits)) == 0)
        return 0;
  }
}
 7b8:	70e2                	ld	ra,56(sp)
 7ba:	7442                	ld	s0,48(sp)
 7bc:	74a2                	ld	s1,40(sp)
 7be:	7902                	ld	s2,32(sp)
 7c0:	69e2                	ld	s3,24(sp)
 7c2:	6a42                	ld	s4,16(sp)
 7c4:	6aa2                	ld	s5,8(sp)
 7c6:	6b02                	ld	s6,0(sp)
 7c8:	6121                	addi	sp,sp,64
 7ca:	8082                	ret
        prevp->s.ptr = p->s.ptr;
 7cc:	6398                	ld	a4,0(a5)
 7ce:	e118                	sd	a4,0(a0)
 7d0:	bff1                	j	7ac <malloc+0x86>
  hp->s.size = nu;
 7d2:	01652423          	sw	s6,8(a0)
  free((void*)(hp + 1));
 7d6:	0541                	addi	a0,a0,16
 7d8:	00000097          	auipc	ra,0x0
 7dc:	ec6080e7          	jalr	-314(ra) # 69e <free>
  return freep;
 7e0:	00093503          	ld	a0,0(s2)
      if((p = morecore(nunits)) == 0)
 7e4:	d971                	beqz	a0,7b8 <malloc+0x92>
  for(p = prevp->s.ptr; ; prevp = p, p = p->s.ptr){
 7e6:	611c                	ld	a5,0(a0)
    if(p->s.size >= nunits){
 7e8:	4798                	lw	a4,8(a5)
 7ea:	fa9776e3          	bgeu	a4,s1,796 <malloc+0x70>
    if(p == freep)
 7ee:	00093703          	ld	a4,0(s2)
 7f2:	853e                	mv	a0,a5
 7f4:	fef719e3          	bne	a4,a5,7e6 <malloc+0xc0>
  p = sbrk(nu * sizeof(Header));
 7f8:	8552                	mv	a0,s4
 7fa:	00000097          	auipc	ra,0x0
 7fe:	b56080e7          	jalr	-1194(ra) # 350 <sbrk>
  if(p == (char*)-1)
 802:	fd5518e3          	bne	a0,s5,7d2 <malloc+0xac>
        return 0;
 806:	4501                	li	a0,0
 808:	bf45                	j	7b8 <malloc+0x92>
