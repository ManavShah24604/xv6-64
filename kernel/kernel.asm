
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	a9013103          	ld	sp,-1392(sp) # 80008a90 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

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
    80000026:	0007869b          	sext.w	a3,a5

  // ask the CLINT for a timer interrupt.
  int interval = 1000000; // cycles; about 1/10th second in qemu.
  *(uint64*)CLINT_MTIMECMP(id) = *(uint64*)CLINT_MTIME + interval;
    8000002a:	0037979b          	slliw	a5,a5,0x3
    8000002e:	02004737          	lui	a4,0x2004
    80000032:	97ba                	add	a5,a5,a4
    80000034:	0200c737          	lui	a4,0x200c
    80000038:	ff873583          	ld	a1,-8(a4) # 200bff8 <_entry-0x7dff4008>
    8000003c:	000f4637          	lui	a2,0xf4
    80000040:	24060613          	addi	a2,a2,576 # f4240 <_entry-0x7ff0bdc0>
    80000044:	95b2                	add	a1,a1,a2
    80000046:	e38c                	sd	a1,0(a5)

  // prepare information in scratch[] for timervec.
  // scratch[0..2] : space for timervec to save registers.
  // scratch[3] : address of CLINT MTIMECMP register.
  // scratch[4] : desired interval (in cycles) between timer interrupts.
  uint64 *scratch = &timer_scratch[id][0];
    80000048:	00269713          	slli	a4,a3,0x2
    8000004c:	9736                	add	a4,a4,a3
    8000004e:	00371693          	slli	a3,a4,0x3
    80000052:	00009717          	auipc	a4,0x9
    80000056:	aae70713          	addi	a4,a4,-1362 # 80008b00 <timer_scratch>
    8000005a:	9736                	add	a4,a4,a3
  scratch[3] = CLINT_MTIMECMP(id);
    8000005c:	ef1c                	sd	a5,24(a4)
  scratch[4] = interval;
    8000005e:	f310                	sd	a2,32(a4)
}

static inline void 
w_mscratch(uint64 x)
{
  asm volatile("csrw mscratch, %0" : : "r" (x));
    80000060:	34071073          	csrw	mscratch,a4
  asm volatile("csrw mtvec, %0" : : "r" (x));
    80000064:	00007797          	auipc	a5,0x7
    80000068:	82c78793          	addi	a5,a5,-2004 # 80006890 <timervec>
    8000006c:	30579073          	csrw	mtvec,a5
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000070:	300027f3          	csrr	a5,mstatus

  // set the machine-mode trap handler.
  w_mtvec((uint64)timervec);

  // enable machine-mode interrupts.
  w_mstatus(r_mstatus() | MSTATUS_MIE);
    80000074:	0087e793          	ori	a5,a5,8
  asm volatile("csrw mstatus, %0" : : "r" (x));
    80000078:	30079073          	csrw	mstatus,a5
  asm volatile("csrr %0, mie" : "=r" (x) );
    8000007c:	304027f3          	csrr	a5,mie

  // enable machine-mode timer interrupts.
  w_mie(r_mie() | MIE_MTIE);
    80000080:	0807e793          	ori	a5,a5,128
  asm volatile("csrw mie, %0" : : "r" (x));
    80000084:	30479073          	csrw	mie,a5
}
    80000088:	6422                	ld	s0,8(sp)
    8000008a:	0141                	addi	sp,sp,16
    8000008c:	8082                	ret

000000008000008e <start>:
{
    8000008e:	1141                	addi	sp,sp,-16
    80000090:	e406                	sd	ra,8(sp)
    80000092:	e022                	sd	s0,0(sp)
    80000094:	0800                	addi	s0,sp,16
  asm volatile("csrr %0, mstatus" : "=r" (x) );
    80000096:	300027f3          	csrr	a5,mstatus
  x &= ~MSTATUS_MPP_MASK;
    8000009a:	7779                	lui	a4,0xffffe
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7fdba6ef>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	0a878793          	addi	a5,a5,168 # 80001156 <main>
    800000b6:	34179073          	csrw	mepc,a5
  asm volatile("csrw satp, %0" : : "r" (x));
    800000ba:	4781                	li	a5,0
    800000bc:	18079073          	csrw	satp,a5
  asm volatile("csrw medeleg, %0" : : "r" (x));
    800000c0:	67c1                	lui	a5,0x10
    800000c2:	17fd                	addi	a5,a5,-1
    800000c4:	30279073          	csrw	medeleg,a5
  asm volatile("csrw mideleg, %0" : : "r" (x));
    800000c8:	30379073          	csrw	mideleg,a5
  asm volatile("csrr %0, sie" : "=r" (x) );
    800000cc:	104027f3          	csrr	a5,sie
  w_sie(r_sie() | SIE_SEIE | SIE_STIE | SIE_SSIE);
    800000d0:	2227e793          	ori	a5,a5,546
  asm volatile("csrw sie, %0" : : "r" (x));
    800000d4:	10479073          	csrw	sie,a5
  asm volatile("csrw pmpaddr0, %0" : : "r" (x));
    800000d8:	57fd                	li	a5,-1
    800000da:	83a9                	srli	a5,a5,0xa
    800000dc:	3b079073          	csrw	pmpaddr0,a5
  asm volatile("csrw pmpcfg0, %0" : : "r" (x));
    800000e0:	47bd                	li	a5,15
    800000e2:	3a079073          	csrw	pmpcfg0,a5
  timerinit();
    800000e6:	00000097          	auipc	ra,0x0
    800000ea:	f36080e7          	jalr	-202(ra) # 8000001c <timerinit>
  asm volatile("csrr %0, mhartid" : "=r" (x) );
    800000ee:	f14027f3          	csrr	a5,mhartid
  w_tp(id);
    800000f2:	2781                	sext.w	a5,a5
}

static inline void 
w_tp(uint64 x)
{
  asm volatile("mv tp, %0" : : "r" (x));
    800000f4:	823e                	mv	tp,a5
  asm volatile("mret");
    800000f6:	30200073          	mret
}
    800000fa:	60a2                	ld	ra,8(sp)
    800000fc:	6402                	ld	s0,0(sp)
    800000fe:	0141                	addi	sp,sp,16
    80000100:	8082                	ret

0000000080000102 <consolewrite>:
//
// user write()s to the console go here.
//
int
consolewrite(int user_src, uint64 src, int n)
{
    80000102:	715d                	addi	sp,sp,-80
    80000104:	e486                	sd	ra,72(sp)
    80000106:	e0a2                	sd	s0,64(sp)
    80000108:	fc26                	sd	s1,56(sp)
    8000010a:	f84a                	sd	s2,48(sp)
    8000010c:	f44e                	sd	s3,40(sp)
    8000010e:	f052                	sd	s4,32(sp)
    80000110:	ec56                	sd	s5,24(sp)
    80000112:	0880                	addi	s0,sp,80
  int i;

  for(i = 0; i < n; i++){
    80000114:	04c05663          	blez	a2,80000160 <consolewrite+0x5e>
    80000118:	8a2a                	mv	s4,a0
    8000011a:	84ae                	mv	s1,a1
    8000011c:	89b2                	mv	s3,a2
    8000011e:	4901                	li	s2,0
    char c;
    if(either_copyin(&c, user_src, src+i, 1) == -1)
    80000120:	5afd                	li	s5,-1
    80000122:	4685                	li	a3,1
    80000124:	8626                	mv	a2,s1
    80000126:	85d2                	mv	a1,s4
    80000128:	fbf40513          	addi	a0,s0,-65
    8000012c:	00003097          	auipc	ra,0x3
    80000130:	99c080e7          	jalr	-1636(ra) # 80002ac8 <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	794080e7          	jalr	1940(ra) # 800008d0 <uartputc>
  for(i = 0; i < n; i++){
    80000144:	2905                	addiw	s2,s2,1
    80000146:	0485                	addi	s1,s1,1
    80000148:	fd299de3          	bne	s3,s2,80000122 <consolewrite+0x20>
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
    80000162:	b7ed                	j	8000014c <consolewrite+0x4a>

0000000080000164 <consoleread>:
// user_dist indicates whether dst is a user
// or kernel address.
//
int
consoleread(int user_dst, uint64 dst, int n)
{
    80000164:	7119                	addi	sp,sp,-128
    80000166:	fc86                	sd	ra,120(sp)
    80000168:	f8a2                	sd	s0,112(sp)
    8000016a:	f4a6                	sd	s1,104(sp)
    8000016c:	f0ca                	sd	s2,96(sp)
    8000016e:	ecce                	sd	s3,88(sp)
    80000170:	e8d2                	sd	s4,80(sp)
    80000172:	e4d6                	sd	s5,72(sp)
    80000174:	e0da                	sd	s6,64(sp)
    80000176:	fc5e                	sd	s7,56(sp)
    80000178:	f862                	sd	s8,48(sp)
    8000017a:	f466                	sd	s9,40(sp)
    8000017c:	f06a                	sd	s10,32(sp)
    8000017e:	ec6e                	sd	s11,24(sp)
    80000180:	0100                	addi	s0,sp,128
    80000182:	8b2a                	mv	s6,a0
    80000184:	8aae                	mv	s5,a1
    80000186:	8a32                	mv	s4,a2
  uint target;
  int c;
  char cbuf;

  target = n;
    80000188:	00060b9b          	sext.w	s7,a2
  acquire(&cons.lock);
    8000018c:	00011517          	auipc	a0,0x11
    80000190:	ab450513          	addi	a0,a0,-1356 # 80010c40 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	d18080e7          	jalr	-744(ra) # 80000eac <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	aa448493          	addi	s1,s1,-1372 # 80010c40 <cons>
      if(killed(myproc())){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	b3290913          	addi	s2,s2,-1230 # 80010cd8 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];

    if(c == C('D')){  // end-of-file
    800001ae:	4c91                	li	s9,4
      break;
    }

    // copy the input byte to the user-space buffer.
    cbuf = c;
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    800001b0:	5d7d                	li	s10,-1
      break;

    dst++;
    --n;

    if(c == '\n'){
    800001b2:	4da9                	li	s11,10
  while(n > 0){
    800001b4:	07405b63          	blez	s4,8000022a <consoleread+0xc6>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71763          	bne	a4,a5,800001ee <consoleread+0x8a>
      if(killed(myproc())){
    800001c4:	00002097          	auipc	ra,0x2
    800001c8:	b36080e7          	jalr	-1226(ra) # 80001cfa <myproc>
    800001cc:	00002097          	auipc	ra,0x2
    800001d0:	746080e7          	jalr	1862(ra) # 80002912 <killed>
    800001d4:	e535                	bnez	a0,80000240 <consoleread+0xdc>
      sleep(&cons.r, &cons.lock);
    800001d6:	85ce                	mv	a1,s3
    800001d8:	854a                	mv	a0,s2
    800001da:	00002097          	auipc	ra,0x2
    800001de:	484080e7          	jalr	1156(ra) # 8000265e <sleep>
    while(cons.r == cons.w){
    800001e2:	0984a783          	lw	a5,152(s1)
    800001e6:	09c4a703          	lw	a4,156(s1)
    800001ea:	fcf70de3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF_SIZE];
    800001ee:	0017871b          	addiw	a4,a5,1
    800001f2:	08e4ac23          	sw	a4,152(s1)
    800001f6:	07f7f713          	andi	a4,a5,127
    800001fa:	9726                	add	a4,a4,s1
    800001fc:	01874703          	lbu	a4,24(a4)
    80000200:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    80000204:	079c0663          	beq	s8,s9,80000270 <consoleread+0x10c>
    cbuf = c;
    80000208:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    8000020c:	4685                	li	a3,1
    8000020e:	f8f40613          	addi	a2,s0,-113
    80000212:	85d6                	mv	a1,s5
    80000214:	855a                	mv	a0,s6
    80000216:	00003097          	auipc	ra,0x3
    8000021a:	85c080e7          	jalr	-1956(ra) # 80002a72 <either_copyout>
    8000021e:	01a50663          	beq	a0,s10,8000022a <consoleread+0xc6>
    dst++;
    80000222:	0a85                	addi	s5,s5,1
    --n;
    80000224:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000226:	f9bc17e3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    8000022a:	00011517          	auipc	a0,0x11
    8000022e:	a1650513          	addi	a0,a0,-1514 # 80010c40 <cons>
    80000232:	00001097          	auipc	ra,0x1
    80000236:	d2e080e7          	jalr	-722(ra) # 80000f60 <release>

  return target - n;
    8000023a:	414b853b          	subw	a0,s7,s4
    8000023e:	a811                	j	80000252 <consoleread+0xee>
        release(&cons.lock);
    80000240:	00011517          	auipc	a0,0x11
    80000244:	a0050513          	addi	a0,a0,-1536 # 80010c40 <cons>
    80000248:	00001097          	auipc	ra,0x1
    8000024c:	d18080e7          	jalr	-744(ra) # 80000f60 <release>
        return -1;
    80000250:	557d                	li	a0,-1
}
    80000252:	70e6                	ld	ra,120(sp)
    80000254:	7446                	ld	s0,112(sp)
    80000256:	74a6                	ld	s1,104(sp)
    80000258:	7906                	ld	s2,96(sp)
    8000025a:	69e6                	ld	s3,88(sp)
    8000025c:	6a46                	ld	s4,80(sp)
    8000025e:	6aa6                	ld	s5,72(sp)
    80000260:	6b06                	ld	s6,64(sp)
    80000262:	7be2                	ld	s7,56(sp)
    80000264:	7c42                	ld	s8,48(sp)
    80000266:	7ca2                	ld	s9,40(sp)
    80000268:	7d02                	ld	s10,32(sp)
    8000026a:	6de2                	ld	s11,24(sp)
    8000026c:	6109                	addi	sp,sp,128
    8000026e:	8082                	ret
      if(n < target){
    80000270:	000a071b          	sext.w	a4,s4
    80000274:	fb777be3          	bgeu	a4,s7,8000022a <consoleread+0xc6>
        cons.r--;
    80000278:	00011717          	auipc	a4,0x11
    8000027c:	a6f72023          	sw	a5,-1440(a4) # 80010cd8 <cons+0x98>
    80000280:	b76d                	j	8000022a <consoleread+0xc6>

0000000080000282 <consputc>:
{
    80000282:	1141                	addi	sp,sp,-16
    80000284:	e406                	sd	ra,8(sp)
    80000286:	e022                	sd	s0,0(sp)
    80000288:	0800                	addi	s0,sp,16
  if(c == BACKSPACE){
    8000028a:	10000793          	li	a5,256
    8000028e:	00f50a63          	beq	a0,a5,800002a2 <consputc+0x20>
    uartputc_sync(c);
    80000292:	00000097          	auipc	ra,0x0
    80000296:	564080e7          	jalr	1380(ra) # 800007f6 <uartputc_sync>
}
    8000029a:	60a2                	ld	ra,8(sp)
    8000029c:	6402                	ld	s0,0(sp)
    8000029e:	0141                	addi	sp,sp,16
    800002a0:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    800002a2:	4521                	li	a0,8
    800002a4:	00000097          	auipc	ra,0x0
    800002a8:	552080e7          	jalr	1362(ra) # 800007f6 <uartputc_sync>
    800002ac:	02000513          	li	a0,32
    800002b0:	00000097          	auipc	ra,0x0
    800002b4:	546080e7          	jalr	1350(ra) # 800007f6 <uartputc_sync>
    800002b8:	4521                	li	a0,8
    800002ba:	00000097          	auipc	ra,0x0
    800002be:	53c080e7          	jalr	1340(ra) # 800007f6 <uartputc_sync>
    800002c2:	bfe1                	j	8000029a <consputc+0x18>

00000000800002c4 <consoleintr>:
// do erase/kill processing, append to cons.buf,
// wake up consoleread() if a whole line has arrived.
//
void
consoleintr(int c)
{
    800002c4:	1101                	addi	sp,sp,-32
    800002c6:	ec06                	sd	ra,24(sp)
    800002c8:	e822                	sd	s0,16(sp)
    800002ca:	e426                	sd	s1,8(sp)
    800002cc:	e04a                	sd	s2,0(sp)
    800002ce:	1000                	addi	s0,sp,32
    800002d0:	84aa                	mv	s1,a0
  acquire(&cons.lock);
    800002d2:	00011517          	auipc	a0,0x11
    800002d6:	96e50513          	addi	a0,a0,-1682 # 80010c40 <cons>
    800002da:	00001097          	auipc	ra,0x1
    800002de:	bd2080e7          	jalr	-1070(ra) # 80000eac <acquire>

  switch(c){
    800002e2:	47d5                	li	a5,21
    800002e4:	0af48663          	beq	s1,a5,80000390 <consoleintr+0xcc>
    800002e8:	0297ca63          	blt	a5,s1,8000031c <consoleintr+0x58>
    800002ec:	47a1                	li	a5,8
    800002ee:	0ef48763          	beq	s1,a5,800003dc <consoleintr+0x118>
    800002f2:	47c1                	li	a5,16
    800002f4:	10f49a63          	bne	s1,a5,80000408 <consoleintr+0x144>
  case C('P'):  // Print process list.
    procdump();
    800002f8:	00003097          	auipc	ra,0x3
    800002fc:	826080e7          	jalr	-2010(ra) # 80002b1e <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    80000300:	00011517          	auipc	a0,0x11
    80000304:	94050513          	addi	a0,a0,-1728 # 80010c40 <cons>
    80000308:	00001097          	auipc	ra,0x1
    8000030c:	c58080e7          	jalr	-936(ra) # 80000f60 <release>
}
    80000310:	60e2                	ld	ra,24(sp)
    80000312:	6442                	ld	s0,16(sp)
    80000314:	64a2                	ld	s1,8(sp)
    80000316:	6902                	ld	s2,0(sp)
    80000318:	6105                	addi	sp,sp,32
    8000031a:	8082                	ret
  switch(c){
    8000031c:	07f00793          	li	a5,127
    80000320:	0af48e63          	beq	s1,a5,800003dc <consoleintr+0x118>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000324:	00011717          	auipc	a4,0x11
    80000328:	91c70713          	addi	a4,a4,-1764 # 80010c40 <cons>
    8000032c:	0a072783          	lw	a5,160(a4)
    80000330:	09872703          	lw	a4,152(a4)
    80000334:	9f99                	subw	a5,a5,a4
    80000336:	07f00713          	li	a4,127
    8000033a:	fcf763e3          	bltu	a4,a5,80000300 <consoleintr+0x3c>
      c = (c == '\r') ? '\n' : c;
    8000033e:	47b5                	li	a5,13
    80000340:	0cf48763          	beq	s1,a5,8000040e <consoleintr+0x14a>
      consputc(c);
    80000344:	8526                	mv	a0,s1
    80000346:	00000097          	auipc	ra,0x0
    8000034a:	f3c080e7          	jalr	-196(ra) # 80000282 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    8000034e:	00011797          	auipc	a5,0x11
    80000352:	8f278793          	addi	a5,a5,-1806 # 80010c40 <cons>
    80000356:	0a07a683          	lw	a3,160(a5)
    8000035a:	0016871b          	addiw	a4,a3,1
    8000035e:	0007061b          	sext.w	a2,a4
    80000362:	0ae7a023          	sw	a4,160(a5)
    80000366:	07f6f693          	andi	a3,a3,127
    8000036a:	97b6                	add	a5,a5,a3
    8000036c:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e-cons.r == INPUT_BUF_SIZE){
    80000370:	47a9                	li	a5,10
    80000372:	0cf48563          	beq	s1,a5,8000043c <consoleintr+0x178>
    80000376:	4791                	li	a5,4
    80000378:	0cf48263          	beq	s1,a5,8000043c <consoleintr+0x178>
    8000037c:	00011797          	auipc	a5,0x11
    80000380:	95c7a783          	lw	a5,-1700(a5) # 80010cd8 <cons+0x98>
    80000384:	9f1d                	subw	a4,a4,a5
    80000386:	08000793          	li	a5,128
    8000038a:	f6f71be3          	bne	a4,a5,80000300 <consoleintr+0x3c>
    8000038e:	a07d                	j	8000043c <consoleintr+0x178>
    while(cons.e != cons.w &&
    80000390:	00011717          	auipc	a4,0x11
    80000394:	8b070713          	addi	a4,a4,-1872 # 80010c40 <cons>
    80000398:	0a072783          	lw	a5,160(a4)
    8000039c:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003a0:	00011497          	auipc	s1,0x11
    800003a4:	8a048493          	addi	s1,s1,-1888 # 80010c40 <cons>
    while(cons.e != cons.w &&
    800003a8:	4929                	li	s2,10
    800003aa:	f4f70be3          	beq	a4,a5,80000300 <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF_SIZE] != '\n'){
    800003ae:	37fd                	addiw	a5,a5,-1
    800003b0:	07f7f713          	andi	a4,a5,127
    800003b4:	9726                	add	a4,a4,s1
    while(cons.e != cons.w &&
    800003b6:	01874703          	lbu	a4,24(a4)
    800003ba:	f52703e3          	beq	a4,s2,80000300 <consoleintr+0x3c>
      cons.e--;
    800003be:	0af4a023          	sw	a5,160(s1)
      consputc(BACKSPACE);
    800003c2:	10000513          	li	a0,256
    800003c6:	00000097          	auipc	ra,0x0
    800003ca:	ebc080e7          	jalr	-324(ra) # 80000282 <consputc>
    while(cons.e != cons.w &&
    800003ce:	0a04a783          	lw	a5,160(s1)
    800003d2:	09c4a703          	lw	a4,156(s1)
    800003d6:	fcf71ce3          	bne	a4,a5,800003ae <consoleintr+0xea>
    800003da:	b71d                	j	80000300 <consoleintr+0x3c>
    if(cons.e != cons.w){
    800003dc:	00011717          	auipc	a4,0x11
    800003e0:	86470713          	addi	a4,a4,-1948 # 80010c40 <cons>
    800003e4:	0a072783          	lw	a5,160(a4)
    800003e8:	09c72703          	lw	a4,156(a4)
    800003ec:	f0f70ae3          	beq	a4,a5,80000300 <consoleintr+0x3c>
      cons.e--;
    800003f0:	37fd                	addiw	a5,a5,-1
    800003f2:	00011717          	auipc	a4,0x11
    800003f6:	8ef72723          	sw	a5,-1810(a4) # 80010ce0 <cons+0xa0>
      consputc(BACKSPACE);
    800003fa:	10000513          	li	a0,256
    800003fe:	00000097          	auipc	ra,0x0
    80000402:	e84080e7          	jalr	-380(ra) # 80000282 <consputc>
    80000406:	bded                	j	80000300 <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF_SIZE){
    80000408:	ee048ce3          	beqz	s1,80000300 <consoleintr+0x3c>
    8000040c:	bf21                	j	80000324 <consoleintr+0x60>
      consputc(c);
    8000040e:	4529                	li	a0,10
    80000410:	00000097          	auipc	ra,0x0
    80000414:	e72080e7          	jalr	-398(ra) # 80000282 <consputc>
      cons.buf[cons.e++ % INPUT_BUF_SIZE] = c;
    80000418:	00011797          	auipc	a5,0x11
    8000041c:	82878793          	addi	a5,a5,-2008 # 80010c40 <cons>
    80000420:	0a07a703          	lw	a4,160(a5)
    80000424:	0017069b          	addiw	a3,a4,1
    80000428:	0006861b          	sext.w	a2,a3
    8000042c:	0ad7a023          	sw	a3,160(a5)
    80000430:	07f77713          	andi	a4,a4,127
    80000434:	97ba                	add	a5,a5,a4
    80000436:	4729                	li	a4,10
    80000438:	00e78c23          	sb	a4,24(a5)
        cons.w = cons.e;
    8000043c:	00011797          	auipc	a5,0x11
    80000440:	8ac7a023          	sw	a2,-1888(a5) # 80010cdc <cons+0x9c>
        wakeup(&cons.r);
    80000444:	00011517          	auipc	a0,0x11
    80000448:	89450513          	addi	a0,a0,-1900 # 80010cd8 <cons+0x98>
    8000044c:	00002097          	auipc	ra,0x2
    80000450:	276080e7          	jalr	630(ra) # 800026c2 <wakeup>
    80000454:	b575                	j	80000300 <consoleintr+0x3c>

0000000080000456 <consoleinit>:

void
consoleinit(void)
{
    80000456:	1141                	addi	sp,sp,-16
    80000458:	e406                	sd	ra,8(sp)
    8000045a:	e022                	sd	s0,0(sp)
    8000045c:	0800                	addi	s0,sp,16
  initlock(&cons.lock, "cons");
    8000045e:	00008597          	auipc	a1,0x8
    80000462:	bb258593          	addi	a1,a1,-1102 # 80008010 <etext+0x10>
    80000466:	00010517          	auipc	a0,0x10
    8000046a:	7da50513          	addi	a0,a0,2010 # 80010c40 <cons>
    8000046e:	00001097          	auipc	ra,0x1
    80000472:	9ae080e7          	jalr	-1618(ra) # 80000e1c <initlock>

  uartinit();
    80000476:	00000097          	auipc	ra,0x0
    8000047a:	330080e7          	jalr	816(ra) # 800007a6 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    8000047e:	00243797          	auipc	a5,0x243
    80000482:	afa78793          	addi	a5,a5,-1286 # 80242f78 <devsw>
    80000486:	00000717          	auipc	a4,0x0
    8000048a:	cde70713          	addi	a4,a4,-802 # 80000164 <consoleread>
    8000048e:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    80000490:	00000717          	auipc	a4,0x0
    80000494:	c7270713          	addi	a4,a4,-910 # 80000102 <consolewrite>
    80000498:	ef98                	sd	a4,24(a5)
}
    8000049a:	60a2                	ld	ra,8(sp)
    8000049c:	6402                	ld	s0,0(sp)
    8000049e:	0141                	addi	sp,sp,16
    800004a0:	8082                	ret

00000000800004a2 <printint>:

static char digits[] = "0123456789abcdef";

static void
printint(int xx, int base, int sign)
{
    800004a2:	7179                	addi	sp,sp,-48
    800004a4:	f406                	sd	ra,40(sp)
    800004a6:	f022                	sd	s0,32(sp)
    800004a8:	ec26                	sd	s1,24(sp)
    800004aa:	e84a                	sd	s2,16(sp)
    800004ac:	1800                	addi	s0,sp,48
  char buf[16];
  int i;
  uint x;

  if(sign && (sign = xx < 0))
    800004ae:	c219                	beqz	a2,800004b4 <printint+0x12>
    800004b0:	08054663          	bltz	a0,8000053c <printint+0x9a>
    x = -xx;
  else
    x = xx;
    800004b4:	2501                	sext.w	a0,a0
    800004b6:	4881                	li	a7,0
    800004b8:	fd040693          	addi	a3,s0,-48

  i = 0;
    800004bc:	4701                	li	a4,0
  do {
    buf[i++] = digits[x % base];
    800004be:	2581                	sext.w	a1,a1
    800004c0:	00008617          	auipc	a2,0x8
    800004c4:	b8060613          	addi	a2,a2,-1152 # 80008040 <digits>
    800004c8:	883a                	mv	a6,a4
    800004ca:	2705                	addiw	a4,a4,1
    800004cc:	02b577bb          	remuw	a5,a0,a1
    800004d0:	1782                	slli	a5,a5,0x20
    800004d2:	9381                	srli	a5,a5,0x20
    800004d4:	97b2                	add	a5,a5,a2
    800004d6:	0007c783          	lbu	a5,0(a5)
    800004da:	00f68023          	sb	a5,0(a3)
  } while((x /= base) != 0);
    800004de:	0005079b          	sext.w	a5,a0
    800004e2:	02b5553b          	divuw	a0,a0,a1
    800004e6:	0685                	addi	a3,a3,1
    800004e8:	feb7f0e3          	bgeu	a5,a1,800004c8 <printint+0x26>

  if(sign)
    800004ec:	00088b63          	beqz	a7,80000502 <printint+0x60>
    buf[i++] = '-';
    800004f0:	fe040793          	addi	a5,s0,-32
    800004f4:	973e                	add	a4,a4,a5
    800004f6:	02d00793          	li	a5,45
    800004fa:	fef70823          	sb	a5,-16(a4)
    800004fe:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    80000502:	02e05763          	blez	a4,80000530 <printint+0x8e>
    80000506:	fd040793          	addi	a5,s0,-48
    8000050a:	00e784b3          	add	s1,a5,a4
    8000050e:	fff78913          	addi	s2,a5,-1
    80000512:	993a                	add	s2,s2,a4
    80000514:	377d                	addiw	a4,a4,-1
    80000516:	1702                	slli	a4,a4,0x20
    80000518:	9301                	srli	a4,a4,0x20
    8000051a:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    8000051e:	fff4c503          	lbu	a0,-1(s1)
    80000522:	00000097          	auipc	ra,0x0
    80000526:	d60080e7          	jalr	-672(ra) # 80000282 <consputc>
  while(--i >= 0)
    8000052a:	14fd                	addi	s1,s1,-1
    8000052c:	ff2499e3          	bne	s1,s2,8000051e <printint+0x7c>
}
    80000530:	70a2                	ld	ra,40(sp)
    80000532:	7402                	ld	s0,32(sp)
    80000534:	64e2                	ld	s1,24(sp)
    80000536:	6942                	ld	s2,16(sp)
    80000538:	6145                	addi	sp,sp,48
    8000053a:	8082                	ret
    x = -xx;
    8000053c:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    80000540:	4885                	li	a7,1
    x = -xx;
    80000542:	bf9d                	j	800004b8 <printint+0x16>

0000000080000544 <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    80000544:	1101                	addi	sp,sp,-32
    80000546:	ec06                	sd	ra,24(sp)
    80000548:	e822                	sd	s0,16(sp)
    8000054a:	e426                	sd	s1,8(sp)
    8000054c:	1000                	addi	s0,sp,32
    8000054e:	84aa                	mv	s1,a0
  pr.locking = 0;
    80000550:	00010797          	auipc	a5,0x10
    80000554:	7a07a823          	sw	zero,1968(a5) # 80010d00 <pr+0x18>
  printf("panic: ");
    80000558:	00008517          	auipc	a0,0x8
    8000055c:	ac050513          	addi	a0,a0,-1344 # 80008018 <etext+0x18>
    80000560:	00000097          	auipc	ra,0x0
    80000564:	02e080e7          	jalr	46(ra) # 8000058e <printf>
  printf(s);
    80000568:	8526                	mv	a0,s1
    8000056a:	00000097          	auipc	ra,0x0
    8000056e:	024080e7          	jalr	36(ra) # 8000058e <printf>
  printf("\n");
    80000572:	00008517          	auipc	a0,0x8
    80000576:	b8e50513          	addi	a0,a0,-1138 # 80008100 <digits+0xc0>
    8000057a:	00000097          	auipc	ra,0x0
    8000057e:	014080e7          	jalr	20(ra) # 8000058e <printf>
  panicked = 1; // freeze uart output from other CPUs
    80000582:	4785                	li	a5,1
    80000584:	00008717          	auipc	a4,0x8
    80000588:	52f72623          	sw	a5,1324(a4) # 80008ab0 <panicked>
  for(;;)
    8000058c:	a001                	j	8000058c <panic+0x48>

000000008000058e <printf>:
{
    8000058e:	7131                	addi	sp,sp,-192
    80000590:	fc86                	sd	ra,120(sp)
    80000592:	f8a2                	sd	s0,112(sp)
    80000594:	f4a6                	sd	s1,104(sp)
    80000596:	f0ca                	sd	s2,96(sp)
    80000598:	ecce                	sd	s3,88(sp)
    8000059a:	e8d2                	sd	s4,80(sp)
    8000059c:	e4d6                	sd	s5,72(sp)
    8000059e:	e0da                	sd	s6,64(sp)
    800005a0:	fc5e                	sd	s7,56(sp)
    800005a2:	f862                	sd	s8,48(sp)
    800005a4:	f466                	sd	s9,40(sp)
    800005a6:	f06a                	sd	s10,32(sp)
    800005a8:	ec6e                	sd	s11,24(sp)
    800005aa:	0100                	addi	s0,sp,128
    800005ac:	8a2a                	mv	s4,a0
    800005ae:	e40c                	sd	a1,8(s0)
    800005b0:	e810                	sd	a2,16(s0)
    800005b2:	ec14                	sd	a3,24(s0)
    800005b4:	f018                	sd	a4,32(s0)
    800005b6:	f41c                	sd	a5,40(s0)
    800005b8:	03043823          	sd	a6,48(s0)
    800005bc:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005c0:	00010d97          	auipc	s11,0x10
    800005c4:	740dad83          	lw	s11,1856(s11) # 80010d00 <pr+0x18>
  if(locking)
    800005c8:	020d9b63          	bnez	s11,800005fe <printf+0x70>
  if (fmt == 0)
    800005cc:	040a0263          	beqz	s4,80000610 <printf+0x82>
  va_start(ap, fmt);
    800005d0:	00840793          	addi	a5,s0,8
    800005d4:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d8:	000a4503          	lbu	a0,0(s4)
    800005dc:	16050263          	beqz	a0,80000740 <printf+0x1b2>
    800005e0:	4481                	li	s1,0
    if(c != '%'){
    800005e2:	02500a93          	li	s5,37
    switch(c){
    800005e6:	07000b13          	li	s6,112
  consputc('x');
    800005ea:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005ec:	00008b97          	auipc	s7,0x8
    800005f0:	a54b8b93          	addi	s7,s7,-1452 # 80008040 <digits>
    switch(c){
    800005f4:	07300c93          	li	s9,115
    800005f8:	06400c13          	li	s8,100
    800005fc:	a82d                	j	80000636 <printf+0xa8>
    acquire(&pr.lock);
    800005fe:	00010517          	auipc	a0,0x10
    80000602:	6ea50513          	addi	a0,a0,1770 # 80010ce8 <pr>
    80000606:	00001097          	auipc	ra,0x1
    8000060a:	8a6080e7          	jalr	-1882(ra) # 80000eac <acquire>
    8000060e:	bf7d                	j	800005cc <printf+0x3e>
    panic("null fmt");
    80000610:	00008517          	auipc	a0,0x8
    80000614:	a1850513          	addi	a0,a0,-1512 # 80008028 <etext+0x28>
    80000618:	00000097          	auipc	ra,0x0
    8000061c:	f2c080e7          	jalr	-212(ra) # 80000544 <panic>
      consputc(c);
    80000620:	00000097          	auipc	ra,0x0
    80000624:	c62080e7          	jalr	-926(ra) # 80000282 <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000628:	2485                	addiw	s1,s1,1
    8000062a:	009a07b3          	add	a5,s4,s1
    8000062e:	0007c503          	lbu	a0,0(a5)
    80000632:	10050763          	beqz	a0,80000740 <printf+0x1b2>
    if(c != '%'){
    80000636:	ff5515e3          	bne	a0,s5,80000620 <printf+0x92>
    c = fmt[++i] & 0xff;
    8000063a:	2485                	addiw	s1,s1,1
    8000063c:	009a07b3          	add	a5,s4,s1
    80000640:	0007c783          	lbu	a5,0(a5)
    80000644:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000648:	cfe5                	beqz	a5,80000740 <printf+0x1b2>
    switch(c){
    8000064a:	05678a63          	beq	a5,s6,8000069e <printf+0x110>
    8000064e:	02fb7663          	bgeu	s6,a5,8000067a <printf+0xec>
    80000652:	09978963          	beq	a5,s9,800006e4 <printf+0x156>
    80000656:	07800713          	li	a4,120
    8000065a:	0ce79863          	bne	a5,a4,8000072a <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    8000065e:	f8843783          	ld	a5,-120(s0)
    80000662:	00878713          	addi	a4,a5,8
    80000666:	f8e43423          	sd	a4,-120(s0)
    8000066a:	4605                	li	a2,1
    8000066c:	85ea                	mv	a1,s10
    8000066e:	4388                	lw	a0,0(a5)
    80000670:	00000097          	auipc	ra,0x0
    80000674:	e32080e7          	jalr	-462(ra) # 800004a2 <printint>
      break;
    80000678:	bf45                	j	80000628 <printf+0x9a>
    switch(c){
    8000067a:	0b578263          	beq	a5,s5,8000071e <printf+0x190>
    8000067e:	0b879663          	bne	a5,s8,8000072a <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    80000682:	f8843783          	ld	a5,-120(s0)
    80000686:	00878713          	addi	a4,a5,8
    8000068a:	f8e43423          	sd	a4,-120(s0)
    8000068e:	4605                	li	a2,1
    80000690:	45a9                	li	a1,10
    80000692:	4388                	lw	a0,0(a5)
    80000694:	00000097          	auipc	ra,0x0
    80000698:	e0e080e7          	jalr	-498(ra) # 800004a2 <printint>
      break;
    8000069c:	b771                	j	80000628 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    8000069e:	f8843783          	ld	a5,-120(s0)
    800006a2:	00878713          	addi	a4,a5,8
    800006a6:	f8e43423          	sd	a4,-120(s0)
    800006aa:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006ae:	03000513          	li	a0,48
    800006b2:	00000097          	auipc	ra,0x0
    800006b6:	bd0080e7          	jalr	-1072(ra) # 80000282 <consputc>
  consputc('x');
    800006ba:	07800513          	li	a0,120
    800006be:	00000097          	auipc	ra,0x0
    800006c2:	bc4080e7          	jalr	-1084(ra) # 80000282 <consputc>
    800006c6:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c8:	03c9d793          	srli	a5,s3,0x3c
    800006cc:	97de                	add	a5,a5,s7
    800006ce:	0007c503          	lbu	a0,0(a5)
    800006d2:	00000097          	auipc	ra,0x0
    800006d6:	bb0080e7          	jalr	-1104(ra) # 80000282 <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006da:	0992                	slli	s3,s3,0x4
    800006dc:	397d                	addiw	s2,s2,-1
    800006de:	fe0915e3          	bnez	s2,800006c8 <printf+0x13a>
    800006e2:	b799                	j	80000628 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006e4:	f8843783          	ld	a5,-120(s0)
    800006e8:	00878713          	addi	a4,a5,8
    800006ec:	f8e43423          	sd	a4,-120(s0)
    800006f0:	0007b903          	ld	s2,0(a5)
    800006f4:	00090e63          	beqz	s2,80000710 <printf+0x182>
      for(; *s; s++)
    800006f8:	00094503          	lbu	a0,0(s2)
    800006fc:	d515                	beqz	a0,80000628 <printf+0x9a>
        consputc(*s);
    800006fe:	00000097          	auipc	ra,0x0
    80000702:	b84080e7          	jalr	-1148(ra) # 80000282 <consputc>
      for(; *s; s++)
    80000706:	0905                	addi	s2,s2,1
    80000708:	00094503          	lbu	a0,0(s2)
    8000070c:	f96d                	bnez	a0,800006fe <printf+0x170>
    8000070e:	bf29                	j	80000628 <printf+0x9a>
        s = "(null)";
    80000710:	00008917          	auipc	s2,0x8
    80000714:	91090913          	addi	s2,s2,-1776 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000718:	02800513          	li	a0,40
    8000071c:	b7cd                	j	800006fe <printf+0x170>
      consputc('%');
    8000071e:	8556                	mv	a0,s5
    80000720:	00000097          	auipc	ra,0x0
    80000724:	b62080e7          	jalr	-1182(ra) # 80000282 <consputc>
      break;
    80000728:	b701                	j	80000628 <printf+0x9a>
      consputc('%');
    8000072a:	8556                	mv	a0,s5
    8000072c:	00000097          	auipc	ra,0x0
    80000730:	b56080e7          	jalr	-1194(ra) # 80000282 <consputc>
      consputc(c);
    80000734:	854a                	mv	a0,s2
    80000736:	00000097          	auipc	ra,0x0
    8000073a:	b4c080e7          	jalr	-1204(ra) # 80000282 <consputc>
      break;
    8000073e:	b5ed                	j	80000628 <printf+0x9a>
  if(locking)
    80000740:	020d9163          	bnez	s11,80000762 <printf+0x1d4>
}
    80000744:	70e6                	ld	ra,120(sp)
    80000746:	7446                	ld	s0,112(sp)
    80000748:	74a6                	ld	s1,104(sp)
    8000074a:	7906                	ld	s2,96(sp)
    8000074c:	69e6                	ld	s3,88(sp)
    8000074e:	6a46                	ld	s4,80(sp)
    80000750:	6aa6                	ld	s5,72(sp)
    80000752:	6b06                	ld	s6,64(sp)
    80000754:	7be2                	ld	s7,56(sp)
    80000756:	7c42                	ld	s8,48(sp)
    80000758:	7ca2                	ld	s9,40(sp)
    8000075a:	7d02                	ld	s10,32(sp)
    8000075c:	6de2                	ld	s11,24(sp)
    8000075e:	6129                	addi	sp,sp,192
    80000760:	8082                	ret
    release(&pr.lock);
    80000762:	00010517          	auipc	a0,0x10
    80000766:	58650513          	addi	a0,a0,1414 # 80010ce8 <pr>
    8000076a:	00000097          	auipc	ra,0x0
    8000076e:	7f6080e7          	jalr	2038(ra) # 80000f60 <release>
}
    80000772:	bfc9                	j	80000744 <printf+0x1b6>

0000000080000774 <printfinit>:
    ;
}

void
printfinit(void)
{
    80000774:	1101                	addi	sp,sp,-32
    80000776:	ec06                	sd	ra,24(sp)
    80000778:	e822                	sd	s0,16(sp)
    8000077a:	e426                	sd	s1,8(sp)
    8000077c:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    8000077e:	00010497          	auipc	s1,0x10
    80000782:	56a48493          	addi	s1,s1,1386 # 80010ce8 <pr>
    80000786:	00008597          	auipc	a1,0x8
    8000078a:	8b258593          	addi	a1,a1,-1870 # 80008038 <etext+0x38>
    8000078e:	8526                	mv	a0,s1
    80000790:	00000097          	auipc	ra,0x0
    80000794:	68c080e7          	jalr	1676(ra) # 80000e1c <initlock>
  pr.locking = 1;
    80000798:	4785                	li	a5,1
    8000079a:	cc9c                	sw	a5,24(s1)
}
    8000079c:	60e2                	ld	ra,24(sp)
    8000079e:	6442                	ld	s0,16(sp)
    800007a0:	64a2                	ld	s1,8(sp)
    800007a2:	6105                	addi	sp,sp,32
    800007a4:	8082                	ret

00000000800007a6 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a6:	1141                	addi	sp,sp,-16
    800007a8:	e406                	sd	ra,8(sp)
    800007aa:	e022                	sd	s0,0(sp)
    800007ac:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007ae:	100007b7          	lui	a5,0x10000
    800007b2:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b6:	f8000713          	li	a4,-128
    800007ba:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007be:	470d                	li	a4,3
    800007c0:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007c4:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c8:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007cc:	469d                	li	a3,7
    800007ce:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007d2:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d6:	00008597          	auipc	a1,0x8
    800007da:	88258593          	addi	a1,a1,-1918 # 80008058 <digits+0x18>
    800007de:	00010517          	auipc	a0,0x10
    800007e2:	52a50513          	addi	a0,a0,1322 # 80010d08 <uart_tx_lock>
    800007e6:	00000097          	auipc	ra,0x0
    800007ea:	636080e7          	jalr	1590(ra) # 80000e1c <initlock>
}
    800007ee:	60a2                	ld	ra,8(sp)
    800007f0:	6402                	ld	s0,0(sp)
    800007f2:	0141                	addi	sp,sp,16
    800007f4:	8082                	ret

00000000800007f6 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f6:	1101                	addi	sp,sp,-32
    800007f8:	ec06                	sd	ra,24(sp)
    800007fa:	e822                	sd	s0,16(sp)
    800007fc:	e426                	sd	s1,8(sp)
    800007fe:	1000                	addi	s0,sp,32
    80000800:	84aa                	mv	s1,a0
  push_off();
    80000802:	00000097          	auipc	ra,0x0
    80000806:	65e080e7          	jalr	1630(ra) # 80000e60 <push_off>

  if(panicked){
    8000080a:	00008797          	auipc	a5,0x8
    8000080e:	2a67a783          	lw	a5,678(a5) # 80008ab0 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000812:	10000737          	lui	a4,0x10000
  if(panicked){
    80000816:	c391                	beqz	a5,8000081a <uartputc_sync+0x24>
    for(;;)
    80000818:	a001                	j	80000818 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000081a:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    8000081e:	0ff7f793          	andi	a5,a5,255
    80000822:	0207f793          	andi	a5,a5,32
    80000826:	dbf5                	beqz	a5,8000081a <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000828:	0ff4f793          	andi	a5,s1,255
    8000082c:	10000737          	lui	a4,0x10000
    80000830:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    80000834:	00000097          	auipc	ra,0x0
    80000838:	6cc080e7          	jalr	1740(ra) # 80000f00 <pop_off>
}
    8000083c:	60e2                	ld	ra,24(sp)
    8000083e:	6442                	ld	s0,16(sp)
    80000840:	64a2                	ld	s1,8(sp)
    80000842:	6105                	addi	sp,sp,32
    80000844:	8082                	ret

0000000080000846 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000846:	00008717          	auipc	a4,0x8
    8000084a:	27273703          	ld	a4,626(a4) # 80008ab8 <uart_tx_r>
    8000084e:	00008797          	auipc	a5,0x8
    80000852:	2727b783          	ld	a5,626(a5) # 80008ac0 <uart_tx_w>
    80000856:	06e78c63          	beq	a5,a4,800008ce <uartstart+0x88>
{
    8000085a:	7139                	addi	sp,sp,-64
    8000085c:	fc06                	sd	ra,56(sp)
    8000085e:	f822                	sd	s0,48(sp)
    80000860:	f426                	sd	s1,40(sp)
    80000862:	f04a                	sd	s2,32(sp)
    80000864:	ec4e                	sd	s3,24(sp)
    80000866:	e852                	sd	s4,16(sp)
    80000868:	e456                	sd	s5,8(sp)
    8000086a:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    8000086c:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000870:	00010a17          	auipc	s4,0x10
    80000874:	498a0a13          	addi	s4,s4,1176 # 80010d08 <uart_tx_lock>
    uart_tx_r += 1;
    80000878:	00008497          	auipc	s1,0x8
    8000087c:	24048493          	addi	s1,s1,576 # 80008ab8 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    80000880:	00008997          	auipc	s3,0x8
    80000884:	24098993          	addi	s3,s3,576 # 80008ac0 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000888:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    8000088c:	0ff7f793          	andi	a5,a5,255
    80000890:	0207f793          	andi	a5,a5,32
    80000894:	c785                	beqz	a5,800008bc <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000896:	01f77793          	andi	a5,a4,31
    8000089a:	97d2                	add	a5,a5,s4
    8000089c:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    800008a0:	0705                	addi	a4,a4,1
    800008a2:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    800008a4:	8526                	mv	a0,s1
    800008a6:	00002097          	auipc	ra,0x2
    800008aa:	e1c080e7          	jalr	-484(ra) # 800026c2 <wakeup>
    
    WriteReg(THR, c);
    800008ae:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008b2:	6098                	ld	a4,0(s1)
    800008b4:	0009b783          	ld	a5,0(s3)
    800008b8:	fce798e3          	bne	a5,a4,80000888 <uartstart+0x42>
  }
}
    800008bc:	70e2                	ld	ra,56(sp)
    800008be:	7442                	ld	s0,48(sp)
    800008c0:	74a2                	ld	s1,40(sp)
    800008c2:	7902                	ld	s2,32(sp)
    800008c4:	69e2                	ld	s3,24(sp)
    800008c6:	6a42                	ld	s4,16(sp)
    800008c8:	6aa2                	ld	s5,8(sp)
    800008ca:	6121                	addi	sp,sp,64
    800008cc:	8082                	ret
    800008ce:	8082                	ret

00000000800008d0 <uartputc>:
{
    800008d0:	7179                	addi	sp,sp,-48
    800008d2:	f406                	sd	ra,40(sp)
    800008d4:	f022                	sd	s0,32(sp)
    800008d6:	ec26                	sd	s1,24(sp)
    800008d8:	e84a                	sd	s2,16(sp)
    800008da:	e44e                	sd	s3,8(sp)
    800008dc:	e052                	sd	s4,0(sp)
    800008de:	1800                	addi	s0,sp,48
    800008e0:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008e2:	00010517          	auipc	a0,0x10
    800008e6:	42650513          	addi	a0,a0,1062 # 80010d08 <uart_tx_lock>
    800008ea:	00000097          	auipc	ra,0x0
    800008ee:	5c2080e7          	jalr	1474(ra) # 80000eac <acquire>
  if(panicked){
    800008f2:	00008797          	auipc	a5,0x8
    800008f6:	1be7a783          	lw	a5,446(a5) # 80008ab0 <panicked>
    800008fa:	e7c9                	bnez	a5,80000984 <uartputc+0xb4>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008fc:	00008797          	auipc	a5,0x8
    80000900:	1c47b783          	ld	a5,452(a5) # 80008ac0 <uart_tx_w>
    80000904:	00008717          	auipc	a4,0x8
    80000908:	1b473703          	ld	a4,436(a4) # 80008ab8 <uart_tx_r>
    8000090c:	02070713          	addi	a4,a4,32
    sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00010a17          	auipc	s4,0x10
    80000914:	3f8a0a13          	addi	s4,s4,1016 # 80010d08 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	1a048493          	addi	s1,s1,416 # 80008ab8 <uart_tx_r>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	1a090913          	addi	s2,s2,416 # 80008ac0 <uart_tx_w>
    80000928:	00f71f63          	bne	a4,a5,80000946 <uartputc+0x76>
    sleep(&uart_tx_r, &uart_tx_lock);
    8000092c:	85d2                	mv	a1,s4
    8000092e:	8526                	mv	a0,s1
    80000930:	00002097          	auipc	ra,0x2
    80000934:	d2e080e7          	jalr	-722(ra) # 8000265e <sleep>
  while(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000938:	00093783          	ld	a5,0(s2)
    8000093c:	6098                	ld	a4,0(s1)
    8000093e:	02070713          	addi	a4,a4,32
    80000942:	fef705e3          	beq	a4,a5,8000092c <uartputc+0x5c>
  uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000946:	00010497          	auipc	s1,0x10
    8000094a:	3c248493          	addi	s1,s1,962 # 80010d08 <uart_tx_lock>
    8000094e:	01f7f713          	andi	a4,a5,31
    80000952:	9726                	add	a4,a4,s1
    80000954:	01370c23          	sb	s3,24(a4)
  uart_tx_w += 1;
    80000958:	0785                	addi	a5,a5,1
    8000095a:	00008717          	auipc	a4,0x8
    8000095e:	16f73323          	sd	a5,358(a4) # 80008ac0 <uart_tx_w>
  uartstart();
    80000962:	00000097          	auipc	ra,0x0
    80000966:	ee4080e7          	jalr	-284(ra) # 80000846 <uartstart>
  release(&uart_tx_lock);
    8000096a:	8526                	mv	a0,s1
    8000096c:	00000097          	auipc	ra,0x0
    80000970:	5f4080e7          	jalr	1524(ra) # 80000f60 <release>
}
    80000974:	70a2                	ld	ra,40(sp)
    80000976:	7402                	ld	s0,32(sp)
    80000978:	64e2                	ld	s1,24(sp)
    8000097a:	6942                	ld	s2,16(sp)
    8000097c:	69a2                	ld	s3,8(sp)
    8000097e:	6a02                	ld	s4,0(sp)
    80000980:	6145                	addi	sp,sp,48
    80000982:	8082                	ret
    for(;;)
    80000984:	a001                	j	80000984 <uartputc+0xb4>

0000000080000986 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000986:	1141                	addi	sp,sp,-16
    80000988:	e422                	sd	s0,8(sp)
    8000098a:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    8000098c:	100007b7          	lui	a5,0x10000
    80000990:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    80000994:	8b85                	andi	a5,a5,1
    80000996:	cb91                	beqz	a5,800009aa <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000998:	100007b7          	lui	a5,0x10000
    8000099c:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    800009a0:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    800009a4:	6422                	ld	s0,8(sp)
    800009a6:	0141                	addi	sp,sp,16
    800009a8:	8082                	ret
    return -1;
    800009aa:	557d                	li	a0,-1
    800009ac:	bfe5                	j	800009a4 <uartgetc+0x1e>

00000000800009ae <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from devintr().
void
uartintr(void)
{
    800009ae:	1101                	addi	sp,sp,-32
    800009b0:	ec06                	sd	ra,24(sp)
    800009b2:	e822                	sd	s0,16(sp)
    800009b4:	e426                	sd	s1,8(sp)
    800009b6:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b8:	54fd                	li	s1,-1
    int c = uartgetc();
    800009ba:	00000097          	auipc	ra,0x0
    800009be:	fcc080e7          	jalr	-52(ra) # 80000986 <uartgetc>
    if(c == -1)
    800009c2:	00950763          	beq	a0,s1,800009d0 <uartintr+0x22>
      break;
    consoleintr(c);
    800009c6:	00000097          	auipc	ra,0x0
    800009ca:	8fe080e7          	jalr	-1794(ra) # 800002c4 <consoleintr>
  while(1){
    800009ce:	b7f5                	j	800009ba <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009d0:	00010497          	auipc	s1,0x10
    800009d4:	33848493          	addi	s1,s1,824 # 80010d08 <uart_tx_lock>
    800009d8:	8526                	mv	a0,s1
    800009da:	00000097          	auipc	ra,0x0
    800009de:	4d2080e7          	jalr	1234(ra) # 80000eac <acquire>
  uartstart();
    800009e2:	00000097          	auipc	ra,0x0
    800009e6:	e64080e7          	jalr	-412(ra) # 80000846 <uartstart>
  release(&uart_tx_lock);
    800009ea:	8526                	mv	a0,s1
    800009ec:	00000097          	auipc	ra,0x0
    800009f0:	574080e7          	jalr	1396(ra) # 80000f60 <release>
}
    800009f4:	60e2                	ld	ra,24(sp)
    800009f6:	6442                	ld	s0,16(sp)
    800009f8:	64a2                	ld	s1,8(sp)
    800009fa:	6105                	addi	sp,sp,32
    800009fc:	8082                	ret

00000000800009fe <init_page_ref>:
struct {
  struct spinlock lock;
  int count[PGROUNDUP(PHYSTOP)>>12];
} page_ref;

void init_page_ref(){
    800009fe:	1141                	addi	sp,sp,-16
    80000a00:	e406                	sd	ra,8(sp)
    80000a02:	e022                	sd	s0,0(sp)
    80000a04:	0800                	addi	s0,sp,16
  initlock(&page_ref.lock, "page_ref");
    80000a06:	00007597          	auipc	a1,0x7
    80000a0a:	65a58593          	addi	a1,a1,1626 # 80008060 <digits+0x20>
    80000a0e:	00010517          	auipc	a0,0x10
    80000a12:	35250513          	addi	a0,a0,850 # 80010d60 <page_ref>
    80000a16:	00000097          	auipc	ra,0x0
    80000a1a:	406080e7          	jalr	1030(ra) # 80000e1c <initlock>
  acquire(&page_ref.lock);
    80000a1e:	00010517          	auipc	a0,0x10
    80000a22:	34250513          	addi	a0,a0,834 # 80010d60 <page_ref>
    80000a26:	00000097          	auipc	ra,0x0
    80000a2a:	486080e7          	jalr	1158(ra) # 80000eac <acquire>
  for(int i=0;i<(PGROUNDUP(PHYSTOP)>>12);++i)
    80000a2e:	00010797          	auipc	a5,0x10
    80000a32:	34a78793          	addi	a5,a5,842 # 80010d78 <page_ref+0x18>
    80000a36:	00230717          	auipc	a4,0x230
    80000a3a:	34270713          	addi	a4,a4,834 # 80230d78 <pid_lock>
    page_ref.count[i]=0;
    80000a3e:	0007a023          	sw	zero,0(a5)
  for(int i=0;i<(PGROUNDUP(PHYSTOP)>>12);++i)
    80000a42:	0791                	addi	a5,a5,4
    80000a44:	fee79de3          	bne	a5,a4,80000a3e <init_page_ref+0x40>
  release(&page_ref.lock);
    80000a48:	00010517          	auipc	a0,0x10
    80000a4c:	31850513          	addi	a0,a0,792 # 80010d60 <page_ref>
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	510080e7          	jalr	1296(ra) # 80000f60 <release>
}
    80000a58:	60a2                	ld	ra,8(sp)
    80000a5a:	6402                	ld	s0,0(sp)
    80000a5c:	0141                	addi	sp,sp,16
    80000a5e:	8082                	ret

0000000080000a60 <dec_page_ref>:


void dec_page_ref(void*pa){
    80000a60:	1101                	addi	sp,sp,-32
    80000a62:	ec06                	sd	ra,24(sp)
    80000a64:	e822                	sd	s0,16(sp)
    80000a66:	e426                	sd	s1,8(sp)
    80000a68:	1000                	addi	s0,sp,32
    80000a6a:	84aa                	mv	s1,a0
  acquire(&page_ref.lock);
    80000a6c:	00010517          	auipc	a0,0x10
    80000a70:	2f450513          	addi	a0,a0,756 # 80010d60 <page_ref>
    80000a74:	00000097          	auipc	ra,0x0
    80000a78:	438080e7          	jalr	1080(ra) # 80000eac <acquire>
  if(page_ref.count[(uint64)pa>>12]<=0){
    80000a7c:	00c4d793          	srli	a5,s1,0xc
    80000a80:	00478713          	addi	a4,a5,4
    80000a84:	00271693          	slli	a3,a4,0x2
    80000a88:	00010717          	auipc	a4,0x10
    80000a8c:	2d870713          	addi	a4,a4,728 # 80010d60 <page_ref>
    80000a90:	9736                	add	a4,a4,a3
    80000a92:	4718                	lw	a4,8(a4)
    80000a94:	02e05463          	blez	a4,80000abc <dec_page_ref+0x5c>
    panic("dec_page_ref");
  }
  page_ref.count[(uint64)pa>>12]-=1;
    80000a98:	00010517          	auipc	a0,0x10
    80000a9c:	2c850513          	addi	a0,a0,712 # 80010d60 <page_ref>
    80000aa0:	0791                	addi	a5,a5,4
    80000aa2:	078a                	slli	a5,a5,0x2
    80000aa4:	97aa                	add	a5,a5,a0
    80000aa6:	377d                	addiw	a4,a4,-1
    80000aa8:	c798                	sw	a4,8(a5)
  release(&page_ref.lock);
    80000aaa:	00000097          	auipc	ra,0x0
    80000aae:	4b6080e7          	jalr	1206(ra) # 80000f60 <release>
}
    80000ab2:	60e2                	ld	ra,24(sp)
    80000ab4:	6442                	ld	s0,16(sp)
    80000ab6:	64a2                	ld	s1,8(sp)
    80000ab8:	6105                	addi	sp,sp,32
    80000aba:	8082                	ret
    panic("dec_page_ref");
    80000abc:	00007517          	auipc	a0,0x7
    80000ac0:	5b450513          	addi	a0,a0,1460 # 80008070 <digits+0x30>
    80000ac4:	00000097          	auipc	ra,0x0
    80000ac8:	a80080e7          	jalr	-1408(ra) # 80000544 <panic>

0000000080000acc <inc_page_ref>:

void inc_page_ref(void*pa){
    80000acc:	1101                	addi	sp,sp,-32
    80000ace:	ec06                	sd	ra,24(sp)
    80000ad0:	e822                	sd	s0,16(sp)
    80000ad2:	e426                	sd	s1,8(sp)
    80000ad4:	1000                	addi	s0,sp,32
    80000ad6:	84aa                	mv	s1,a0
  acquire(&page_ref.lock);
    80000ad8:	00010517          	auipc	a0,0x10
    80000adc:	28850513          	addi	a0,a0,648 # 80010d60 <page_ref>
    80000ae0:	00000097          	auipc	ra,0x0
    80000ae4:	3cc080e7          	jalr	972(ra) # 80000eac <acquire>
  if(page_ref.count[(uint64)pa>>12]<0){
    80000ae8:	00c4d793          	srli	a5,s1,0xc
    80000aec:	00478713          	addi	a4,a5,4
    80000af0:	00271693          	slli	a3,a4,0x2
    80000af4:	00010717          	auipc	a4,0x10
    80000af8:	26c70713          	addi	a4,a4,620 # 80010d60 <page_ref>
    80000afc:	9736                	add	a4,a4,a3
    80000afe:	4718                	lw	a4,8(a4)
    80000b00:	02074463          	bltz	a4,80000b28 <inc_page_ref+0x5c>
    panic("inc_page_ref");
  }
  page_ref.count[(uint64)pa>>12]+=1;
    80000b04:	00010517          	auipc	a0,0x10
    80000b08:	25c50513          	addi	a0,a0,604 # 80010d60 <page_ref>
    80000b0c:	0791                	addi	a5,a5,4
    80000b0e:	078a                	slli	a5,a5,0x2
    80000b10:	97aa                	add	a5,a5,a0
    80000b12:	2705                	addiw	a4,a4,1
    80000b14:	c798                	sw	a4,8(a5)
  release(&page_ref.lock);
    80000b16:	00000097          	auipc	ra,0x0
    80000b1a:	44a080e7          	jalr	1098(ra) # 80000f60 <release>
}
    80000b1e:	60e2                	ld	ra,24(sp)
    80000b20:	6442                	ld	s0,16(sp)
    80000b22:	64a2                	ld	s1,8(sp)
    80000b24:	6105                	addi	sp,sp,32
    80000b26:	8082                	ret
    panic("inc_page_ref");
    80000b28:	00007517          	auipc	a0,0x7
    80000b2c:	55850513          	addi	a0,a0,1368 # 80008080 <digits+0x40>
    80000b30:	00000097          	auipc	ra,0x0
    80000b34:	a14080e7          	jalr	-1516(ra) # 80000544 <panic>

0000000080000b38 <get_page_ref>:

int get_page_ref(void*pa){
    80000b38:	1101                	addi	sp,sp,-32
    80000b3a:	ec06                	sd	ra,24(sp)
    80000b3c:	e822                	sd	s0,16(sp)
    80000b3e:	e426                	sd	s1,8(sp)
    80000b40:	1000                	addi	s0,sp,32
    80000b42:	84aa                	mv	s1,a0
  acquire(&page_ref.lock);
    80000b44:	00010517          	auipc	a0,0x10
    80000b48:	21c50513          	addi	a0,a0,540 # 80010d60 <page_ref>
    80000b4c:	00000097          	auipc	ra,0x0
    80000b50:	360080e7          	jalr	864(ra) # 80000eac <acquire>
  int res = page_ref.count[(uint64)pa>>12];
    80000b54:	80b1                	srli	s1,s1,0xc
    80000b56:	0491                	addi	s1,s1,4
    80000b58:	048a                	slli	s1,s1,0x2
    80000b5a:	00010797          	auipc	a5,0x10
    80000b5e:	20678793          	addi	a5,a5,518 # 80010d60 <page_ref>
    80000b62:	94be                	add	s1,s1,a5
    80000b64:	4484                	lw	s1,8(s1)
  if(page_ref.count[(uint64)pa>>12]<0){
    80000b66:	0204c063          	bltz	s1,80000b86 <get_page_ref+0x4e>
    panic("get_page_ref");
  }
  release(&page_ref.lock);
    80000b6a:	00010517          	auipc	a0,0x10
    80000b6e:	1f650513          	addi	a0,a0,502 # 80010d60 <page_ref>
    80000b72:	00000097          	auipc	ra,0x0
    80000b76:	3ee080e7          	jalr	1006(ra) # 80000f60 <release>
  return res;
}
    80000b7a:	8526                	mv	a0,s1
    80000b7c:	60e2                	ld	ra,24(sp)
    80000b7e:	6442                	ld	s0,16(sp)
    80000b80:	64a2                	ld	s1,8(sp)
    80000b82:	6105                	addi	sp,sp,32
    80000b84:	8082                	ret
    panic("get_page_ref");
    80000b86:	00007517          	auipc	a0,0x7
    80000b8a:	50a50513          	addi	a0,a0,1290 # 80008090 <digits+0x50>
    80000b8e:	00000097          	auipc	ra,0x0
    80000b92:	9b6080e7          	jalr	-1610(ra) # 80000544 <panic>

0000000080000b96 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000b96:	1101                	addi	sp,sp,-32
    80000b98:	ec06                	sd	ra,24(sp)
    80000b9a:	e822                	sd	s0,16(sp)
    80000b9c:	e426                	sd	s1,8(sp)
    80000b9e:	e04a                	sd	s2,0(sp)
    80000ba0:	1000                	addi	s0,sp,32
    80000ba2:	84aa                	mv	s1,a0
  struct run *r;

  // if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
  //   panic("kfree");

    acquire(&page_ref.lock);
    80000ba4:	00010517          	auipc	a0,0x10
    80000ba8:	1bc50513          	addi	a0,a0,444 # 80010d60 <page_ref>
    80000bac:	00000097          	auipc	ra,0x0
    80000bb0:	300080e7          	jalr	768(ra) # 80000eac <acquire>
  if(page_ref.count[(uint64)pa>>12]<=0){
    80000bb4:	00c4d793          	srli	a5,s1,0xc
    80000bb8:	00478713          	addi	a4,a5,4
    80000bbc:	00271693          	slli	a3,a4,0x2
    80000bc0:	00010717          	auipc	a4,0x10
    80000bc4:	1a070713          	addi	a4,a4,416 # 80010d60 <page_ref>
    80000bc8:	9736                	add	a4,a4,a3
    80000bca:	4718                	lw	a4,8(a4)
    80000bcc:	06e05763          	blez	a4,80000c3a <kfree+0xa4>
    panic("dec_page_ref");
  }
  page_ref.count[(uint64)pa>>12]-=1;
    80000bd0:	377d                	addiw	a4,a4,-1
    80000bd2:	0007061b          	sext.w	a2,a4
    80000bd6:	0791                	addi	a5,a5,4
    80000bd8:	078a                	slli	a5,a5,0x2
    80000bda:	00010697          	auipc	a3,0x10
    80000bde:	18668693          	addi	a3,a3,390 # 80010d60 <page_ref>
    80000be2:	97b6                	add	a5,a5,a3
    80000be4:	c798                	sw	a4,8(a5)
  if(page_ref.count[(uint64)pa>>12]>0){
    80000be6:	06c04263          	bgtz	a2,80000c4a <kfree+0xb4>
    release(&page_ref.lock);
    return;
  }
  release(&page_ref.lock);
    80000bea:	00010517          	auipc	a0,0x10
    80000bee:	17650513          	addi	a0,a0,374 # 80010d60 <page_ref>
    80000bf2:	00000097          	auipc	ra,0x0
    80000bf6:	36e080e7          	jalr	878(ra) # 80000f60 <release>

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000bfa:	6605                	lui	a2,0x1
    80000bfc:	4585                	li	a1,1
    80000bfe:	8526                	mv	a0,s1
    80000c00:	00000097          	auipc	ra,0x0
    80000c04:	3a8080e7          	jalr	936(ra) # 80000fa8 <memset>

  r = (struct run*)pa;

  acquire(&kmem.lock);
    80000c08:	00010917          	auipc	s2,0x10
    80000c0c:	13890913          	addi	s2,s2,312 # 80010d40 <kmem>
    80000c10:	854a                	mv	a0,s2
    80000c12:	00000097          	auipc	ra,0x0
    80000c16:	29a080e7          	jalr	666(ra) # 80000eac <acquire>
  r->next = kmem.freelist;
    80000c1a:	01893783          	ld	a5,24(s2)
    80000c1e:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000c20:	00993c23          	sd	s1,24(s2)
  release(&kmem.lock);
    80000c24:	854a                	mv	a0,s2
    80000c26:	00000097          	auipc	ra,0x0
    80000c2a:	33a080e7          	jalr	826(ra) # 80000f60 <release>
}
    80000c2e:	60e2                	ld	ra,24(sp)
    80000c30:	6442                	ld	s0,16(sp)
    80000c32:	64a2                	ld	s1,8(sp)
    80000c34:	6902                	ld	s2,0(sp)
    80000c36:	6105                	addi	sp,sp,32
    80000c38:	8082                	ret
    panic("dec_page_ref");
    80000c3a:	00007517          	auipc	a0,0x7
    80000c3e:	43650513          	addi	a0,a0,1078 # 80008070 <digits+0x30>
    80000c42:	00000097          	auipc	ra,0x0
    80000c46:	902080e7          	jalr	-1790(ra) # 80000544 <panic>
    release(&page_ref.lock);
    80000c4a:	8536                	mv	a0,a3
    80000c4c:	00000097          	auipc	ra,0x0
    80000c50:	314080e7          	jalr	788(ra) # 80000f60 <release>
    return;
    80000c54:	bfe9                	j	80000c2e <kfree+0x98>

0000000080000c56 <freerange>:
{
    80000c56:	7139                	addi	sp,sp,-64
    80000c58:	fc06                	sd	ra,56(sp)
    80000c5a:	f822                	sd	s0,48(sp)
    80000c5c:	f426                	sd	s1,40(sp)
    80000c5e:	f04a                	sd	s2,32(sp)
    80000c60:	ec4e                	sd	s3,24(sp)
    80000c62:	e852                	sd	s4,16(sp)
    80000c64:	e456                	sd	s5,8(sp)
    80000c66:	0080                	addi	s0,sp,64
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000c68:	6785                	lui	a5,0x1
    80000c6a:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000c6e:	94aa                	add	s1,s1,a0
    80000c70:	757d                	lui	a0,0xfffff
    80000c72:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE){
    80000c74:	94be                	add	s1,s1,a5
    80000c76:	0295e463          	bltu	a1,s1,80000c9e <freerange+0x48>
    80000c7a:	89ae                	mv	s3,a1
    80000c7c:	7afd                	lui	s5,0xfffff
    80000c7e:	6a05                	lui	s4,0x1
    80000c80:	01548933          	add	s2,s1,s5
   inc_page_ref(p);
    80000c84:	854a                	mv	a0,s2
    80000c86:	00000097          	auipc	ra,0x0
    80000c8a:	e46080e7          	jalr	-442(ra) # 80000acc <inc_page_ref>
     kfree(p);
    80000c8e:	854a                	mv	a0,s2
    80000c90:	00000097          	auipc	ra,0x0
    80000c94:	f06080e7          	jalr	-250(ra) # 80000b96 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE){
    80000c98:	94d2                	add	s1,s1,s4
    80000c9a:	fe99f3e3          	bgeu	s3,s1,80000c80 <freerange+0x2a>
}
    80000c9e:	70e2                	ld	ra,56(sp)
    80000ca0:	7442                	ld	s0,48(sp)
    80000ca2:	74a2                	ld	s1,40(sp)
    80000ca4:	7902                	ld	s2,32(sp)
    80000ca6:	69e2                	ld	s3,24(sp)
    80000ca8:	6a42                	ld	s4,16(sp)
    80000caa:	6aa2                	ld	s5,8(sp)
    80000cac:	6121                	addi	sp,sp,64
    80000cae:	8082                	ret

0000000080000cb0 <kinit>:
{
    80000cb0:	1141                	addi	sp,sp,-16
    80000cb2:	e406                	sd	ra,8(sp)
    80000cb4:	e022                	sd	s0,0(sp)
    80000cb6:	0800                	addi	s0,sp,16
  init_page_ref();
    80000cb8:	00000097          	auipc	ra,0x0
    80000cbc:	d46080e7          	jalr	-698(ra) # 800009fe <init_page_ref>
  initlock(&kmem.lock, "kmem");
    80000cc0:	00007597          	auipc	a1,0x7
    80000cc4:	3e058593          	addi	a1,a1,992 # 800080a0 <digits+0x60>
    80000cc8:	00010517          	auipc	a0,0x10
    80000ccc:	07850513          	addi	a0,a0,120 # 80010d40 <kmem>
    80000cd0:	00000097          	auipc	ra,0x0
    80000cd4:	14c080e7          	jalr	332(ra) # 80000e1c <initlock>
  freerange(end, (void*)PHYSTOP);
    80000cd8:	45c5                	li	a1,17
    80000cda:	05ee                	slli	a1,a1,0x1b
    80000cdc:	00243517          	auipc	a0,0x243
    80000ce0:	43450513          	addi	a0,a0,1076 # 80244110 <end>
    80000ce4:	00000097          	auipc	ra,0x0
    80000ce8:	f72080e7          	jalr	-142(ra) # 80000c56 <freerange>
}
    80000cec:	60a2                	ld	ra,8(sp)
    80000cee:	6402                	ld	s0,0(sp)
    80000cf0:	0141                	addi	sp,sp,16
    80000cf2:	8082                	ret

0000000080000cf4 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000cf4:	1101                	addi	sp,sp,-32
    80000cf6:	ec06                	sd	ra,24(sp)
    80000cf8:	e822                	sd	s0,16(sp)
    80000cfa:	e426                	sd	s1,8(sp)
    80000cfc:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000cfe:	00010497          	auipc	s1,0x10
    80000d02:	04248493          	addi	s1,s1,66 # 80010d40 <kmem>
    80000d06:	8526                	mv	a0,s1
    80000d08:	00000097          	auipc	ra,0x0
    80000d0c:	1a4080e7          	jalr	420(ra) # 80000eac <acquire>
  r = kmem.freelist;
    80000d10:	6c84                	ld	s1,24(s1)
  if(r)
    80000d12:	cc8d                	beqz	s1,80000d4c <kalloc+0x58>
    kmem.freelist = r->next;
    80000d14:	609c                	ld	a5,0(s1)
    80000d16:	00010517          	auipc	a0,0x10
    80000d1a:	02a50513          	addi	a0,a0,42 # 80010d40 <kmem>
    80000d1e:	ed1c                	sd	a5,24(a0)
  release(&kmem.lock);
    80000d20:	00000097          	auipc	ra,0x0
    80000d24:	240080e7          	jalr	576(ra) # 80000f60 <release>

  // if(r)
  //   memset((char*)r, 5, PGSIZE); // fill with junk
   if(r){
     memset((char*)r, 5, PGSIZE); // fill with junk
    80000d28:	6605                	lui	a2,0x1
    80000d2a:	4595                	li	a1,5
    80000d2c:	8526                	mv	a0,s1
    80000d2e:	00000097          	auipc	ra,0x0
    80000d32:	27a080e7          	jalr	634(ra) # 80000fa8 <memset>
    inc_page_ref((void*)r);
    80000d36:	8526                	mv	a0,s1
    80000d38:	00000097          	auipc	ra,0x0
    80000d3c:	d94080e7          	jalr	-620(ra) # 80000acc <inc_page_ref>
  }
  return (void*)r;
}
    80000d40:	8526                	mv	a0,s1
    80000d42:	60e2                	ld	ra,24(sp)
    80000d44:	6442                	ld	s0,16(sp)
    80000d46:	64a2                	ld	s1,8(sp)
    80000d48:	6105                	addi	sp,sp,32
    80000d4a:	8082                	ret
  release(&kmem.lock);
    80000d4c:	00010517          	auipc	a0,0x10
    80000d50:	ff450513          	addi	a0,a0,-12 # 80010d40 <kmem>
    80000d54:	00000097          	auipc	ra,0x0
    80000d58:	20c080e7          	jalr	524(ra) # 80000f60 <release>
   if(r){
    80000d5c:	b7d5                	j	80000d40 <kalloc+0x4c>

0000000080000d5e <page_fault_handler>:


int page_fault_handler(void*va,pagetable_t pagetable){
    80000d5e:	7179                	addi	sp,sp,-48
    80000d60:	f406                	sd	ra,40(sp)
    80000d62:	f022                	sd	s0,32(sp)
    80000d64:	ec26                	sd	s1,24(sp)
    80000d66:	e84a                	sd	s2,16(sp)
    80000d68:	e44e                	sd	s3,8(sp)
    80000d6a:	e052                	sd	s4,0(sp)
    80000d6c:	1800                	addi	s0,sp,48
    80000d6e:	84aa                	mv	s1,a0
    80000d70:	892e                	mv	s2,a1
 
  struct proc* p = myproc();
    80000d72:	00001097          	auipc	ra,0x1
    80000d76:	f88080e7          	jalr	-120(ra) # 80001cfa <myproc>
  if((uint64)va>=MAXVA||((uint64)va>=PGROUNDDOWN(p->trapframe->sp)-PGSIZE&&(uint64)va<=PGROUNDDOWN(p->trapframe->sp))){
    80000d7a:	57fd                	li	a5,-1
    80000d7c:	83e9                	srli	a5,a5,0x1a
    80000d7e:	0897e563          	bltu	a5,s1,80000e08 <page_fault_handler+0xaa>
    80000d82:	7138                	ld	a4,96(a0)
    80000d84:	77fd                	lui	a5,0xfffff
    80000d86:	7b18                	ld	a4,48(a4)
    80000d88:	8f7d                	and	a4,a4,a5
    80000d8a:	97ba                	add	a5,a5,a4
    80000d8c:	00f4e463          	bltu	s1,a5,80000d94 <page_fault_handler+0x36>
    80000d90:	06977e63          	bgeu	a4,s1,80000e0c <page_fault_handler+0xae>

  pte_t *pte;
  uint64 pa;
  uint flags;
  va = (void*)PGROUNDDOWN((uint64)va);
  pte = walk(pagetable,(uint64)va,0);
    80000d94:	4601                	li	a2,0
    80000d96:	75fd                	lui	a1,0xfffff
    80000d98:	8de5                	and	a1,a1,s1
    80000d9a:	854a                	mv	a0,s2
    80000d9c:	00000097          	auipc	ra,0x0
    80000da0:	4f8080e7          	jalr	1272(ra) # 80001294 <walk>
    80000da4:	892a                	mv	s2,a0
  if(pte == 0){
    80000da6:	c52d                	beqz	a0,80000e10 <page_fault_handler+0xb2>
    return -1;
  }
  pa = PTE2PA(*pte);
    80000da8:	611c                	ld	a5,0(a0)
    80000daa:	00a7d993          	srli	s3,a5,0xa
    80000dae:	09b2                	slli	s3,s3,0xc
  if(pa == 0){
    80000db0:	06098263          	beqz	s3,80000e14 <page_fault_handler+0xb6>
    return -1;
  }
  flags = PTE_FLAGS(*pte);
    80000db4:	2781                	sext.w	a5,a5
  if(flags&PTE_C){
    80000db6:	0207f713          	andi	a4,a5,32
    memmove(mem,(void*)pa,PGSIZE); 
    *pte = PA2PTE(mem)|flags;
    kfree((void*)pa);
    return 0;
  }
  return 0;
    80000dba:	4501                	li	a0,0
  if(flags&PTE_C){
    80000dbc:	eb09                	bnez	a4,80000dce <page_fault_handler+0x70>
    80000dbe:	70a2                	ld	ra,40(sp)
    80000dc0:	7402                	ld	s0,32(sp)
    80000dc2:	64e2                	ld	s1,24(sp)
    80000dc4:	6942                	ld	s2,16(sp)
    80000dc6:	69a2                	ld	s3,8(sp)
    80000dc8:	6a02                	ld	s4,0(sp)
    80000dca:	6145                	addi	sp,sp,48
    80000dcc:	8082                	ret
    flags = (flags|PTE_W)&(~PTE_C);
    80000dce:	3df7f793          	andi	a5,a5,991
    80000dd2:	0047e493          	ori	s1,a5,4
    mem = kalloc();
    80000dd6:	00000097          	auipc	ra,0x0
    80000dda:	f1e080e7          	jalr	-226(ra) # 80000cf4 <kalloc>
    80000dde:	8a2a                	mv	s4,a0
    if(mem==0){
    80000de0:	cd05                	beqz	a0,80000e18 <page_fault_handler+0xba>
    memmove(mem,(void*)pa,PGSIZE); 
    80000de2:	6605                	lui	a2,0x1
    80000de4:	85ce                	mv	a1,s3
    80000de6:	00000097          	auipc	ra,0x0
    80000dea:	222080e7          	jalr	546(ra) # 80001008 <memmove>
    *pte = PA2PTE(mem)|flags;
    80000dee:	00ca5793          	srli	a5,s4,0xc
    80000df2:	07aa                	slli	a5,a5,0xa
    80000df4:	8fc5                	or	a5,a5,s1
    80000df6:	00f93023          	sd	a5,0(s2)
    kfree((void*)pa);
    80000dfa:	854e                	mv	a0,s3
    80000dfc:	00000097          	auipc	ra,0x0
    80000e00:	d9a080e7          	jalr	-614(ra) # 80000b96 <kfree>
    return 0;
    80000e04:	4501                	li	a0,0
    80000e06:	bf65                	j	80000dbe <page_fault_handler+0x60>
    return -2;
    80000e08:	5579                	li	a0,-2
    80000e0a:	bf55                	j	80000dbe <page_fault_handler+0x60>
    80000e0c:	5579                	li	a0,-2
    80000e0e:	bf45                	j	80000dbe <page_fault_handler+0x60>
    return -1;
    80000e10:	557d                	li	a0,-1
    80000e12:	b775                	j	80000dbe <page_fault_handler+0x60>
    return -1;
    80000e14:	557d                	li	a0,-1
    80000e16:	b765                	j	80000dbe <page_fault_handler+0x60>
      return -1;
    80000e18:	557d                	li	a0,-1
    80000e1a:	b755                	j	80000dbe <page_fault_handler+0x60>

0000000080000e1c <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000e1c:	1141                	addi	sp,sp,-16
    80000e1e:	e422                	sd	s0,8(sp)
    80000e20:	0800                	addi	s0,sp,16
  lk->name = name;
    80000e22:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000e24:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000e28:	00053823          	sd	zero,16(a0)
}
    80000e2c:	6422                	ld	s0,8(sp)
    80000e2e:	0141                	addi	sp,sp,16
    80000e30:	8082                	ret

0000000080000e32 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000e32:	411c                	lw	a5,0(a0)
    80000e34:	e399                	bnez	a5,80000e3a <holding+0x8>
    80000e36:	4501                	li	a0,0
  return r;
}
    80000e38:	8082                	ret
{
    80000e3a:	1101                	addi	sp,sp,-32
    80000e3c:	ec06                	sd	ra,24(sp)
    80000e3e:	e822                	sd	s0,16(sp)
    80000e40:	e426                	sd	s1,8(sp)
    80000e42:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000e44:	6904                	ld	s1,16(a0)
    80000e46:	00001097          	auipc	ra,0x1
    80000e4a:	e92080e7          	jalr	-366(ra) # 80001cd8 <mycpu>
    80000e4e:	40a48533          	sub	a0,s1,a0
    80000e52:	00153513          	seqz	a0,a0
}
    80000e56:	60e2                	ld	ra,24(sp)
    80000e58:	6442                	ld	s0,16(sp)
    80000e5a:	64a2                	ld	s1,8(sp)
    80000e5c:	6105                	addi	sp,sp,32
    80000e5e:	8082                	ret

0000000080000e60 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000e60:	1101                	addi	sp,sp,-32
    80000e62:	ec06                	sd	ra,24(sp)
    80000e64:	e822                	sd	s0,16(sp)
    80000e66:	e426                	sd	s1,8(sp)
    80000e68:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000e6a:	100024f3          	csrr	s1,sstatus
    80000e6e:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000e72:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000e74:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000e78:	00001097          	auipc	ra,0x1
    80000e7c:	e60080e7          	jalr	-416(ra) # 80001cd8 <mycpu>
    80000e80:	5d3c                	lw	a5,120(a0)
    80000e82:	cf89                	beqz	a5,80000e9c <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000e84:	00001097          	auipc	ra,0x1
    80000e88:	e54080e7          	jalr	-428(ra) # 80001cd8 <mycpu>
    80000e8c:	5d3c                	lw	a5,120(a0)
    80000e8e:	2785                	addiw	a5,a5,1
    80000e90:	dd3c                	sw	a5,120(a0)
}
    80000e92:	60e2                	ld	ra,24(sp)
    80000e94:	6442                	ld	s0,16(sp)
    80000e96:	64a2                	ld	s1,8(sp)
    80000e98:	6105                	addi	sp,sp,32
    80000e9a:	8082                	ret
    mycpu()->intena = old;
    80000e9c:	00001097          	auipc	ra,0x1
    80000ea0:	e3c080e7          	jalr	-452(ra) # 80001cd8 <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000ea4:	8085                	srli	s1,s1,0x1
    80000ea6:	8885                	andi	s1,s1,1
    80000ea8:	dd64                	sw	s1,124(a0)
    80000eaa:	bfe9                	j	80000e84 <push_off+0x24>

0000000080000eac <acquire>:
{
    80000eac:	1101                	addi	sp,sp,-32
    80000eae:	ec06                	sd	ra,24(sp)
    80000eb0:	e822                	sd	s0,16(sp)
    80000eb2:	e426                	sd	s1,8(sp)
    80000eb4:	1000                	addi	s0,sp,32
    80000eb6:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000eb8:	00000097          	auipc	ra,0x0
    80000ebc:	fa8080e7          	jalr	-88(ra) # 80000e60 <push_off>
  if(holding(lk))
    80000ec0:	8526                	mv	a0,s1
    80000ec2:	00000097          	auipc	ra,0x0
    80000ec6:	f70080e7          	jalr	-144(ra) # 80000e32 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000eca:	4705                	li	a4,1
  if(holding(lk))
    80000ecc:	e115                	bnez	a0,80000ef0 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000ece:	87ba                	mv	a5,a4
    80000ed0:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000ed4:	2781                	sext.w	a5,a5
    80000ed6:	ffe5                	bnez	a5,80000ece <acquire+0x22>
  __sync_synchronize();
    80000ed8:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000edc:	00001097          	auipc	ra,0x1
    80000ee0:	dfc080e7          	jalr	-516(ra) # 80001cd8 <mycpu>
    80000ee4:	e888                	sd	a0,16(s1)
}
    80000ee6:	60e2                	ld	ra,24(sp)
    80000ee8:	6442                	ld	s0,16(sp)
    80000eea:	64a2                	ld	s1,8(sp)
    80000eec:	6105                	addi	sp,sp,32
    80000eee:	8082                	ret
    panic("acquire");
    80000ef0:	00007517          	auipc	a0,0x7
    80000ef4:	1b850513          	addi	a0,a0,440 # 800080a8 <digits+0x68>
    80000ef8:	fffff097          	auipc	ra,0xfffff
    80000efc:	64c080e7          	jalr	1612(ra) # 80000544 <panic>

0000000080000f00 <pop_off>:

void
pop_off(void)
{
    80000f00:	1141                	addi	sp,sp,-16
    80000f02:	e406                	sd	ra,8(sp)
    80000f04:	e022                	sd	s0,0(sp)
    80000f06:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000f08:	00001097          	auipc	ra,0x1
    80000f0c:	dd0080e7          	jalr	-560(ra) # 80001cd8 <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000f10:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000f14:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000f16:	e78d                	bnez	a5,80000f40 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000f18:	5d3c                	lw	a5,120(a0)
    80000f1a:	02f05b63          	blez	a5,80000f50 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000f1e:	37fd                	addiw	a5,a5,-1
    80000f20:	0007871b          	sext.w	a4,a5
    80000f24:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000f26:	eb09                	bnez	a4,80000f38 <pop_off+0x38>
    80000f28:	5d7c                	lw	a5,124(a0)
    80000f2a:	c799                	beqz	a5,80000f38 <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000f2c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000f30:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000f34:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000f38:	60a2                	ld	ra,8(sp)
    80000f3a:	6402                	ld	s0,0(sp)
    80000f3c:	0141                	addi	sp,sp,16
    80000f3e:	8082                	ret
    panic("pop_off - interruptible");
    80000f40:	00007517          	auipc	a0,0x7
    80000f44:	17050513          	addi	a0,a0,368 # 800080b0 <digits+0x70>
    80000f48:	fffff097          	auipc	ra,0xfffff
    80000f4c:	5fc080e7          	jalr	1532(ra) # 80000544 <panic>
    panic("pop_off");
    80000f50:	00007517          	auipc	a0,0x7
    80000f54:	17850513          	addi	a0,a0,376 # 800080c8 <digits+0x88>
    80000f58:	fffff097          	auipc	ra,0xfffff
    80000f5c:	5ec080e7          	jalr	1516(ra) # 80000544 <panic>

0000000080000f60 <release>:
{
    80000f60:	1101                	addi	sp,sp,-32
    80000f62:	ec06                	sd	ra,24(sp)
    80000f64:	e822                	sd	s0,16(sp)
    80000f66:	e426                	sd	s1,8(sp)
    80000f68:	1000                	addi	s0,sp,32
    80000f6a:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000f6c:	00000097          	auipc	ra,0x0
    80000f70:	ec6080e7          	jalr	-314(ra) # 80000e32 <holding>
    80000f74:	c115                	beqz	a0,80000f98 <release+0x38>
  lk->cpu = 0;
    80000f76:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000f7a:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000f7e:	0f50000f          	fence	iorw,ow
    80000f82:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000f86:	00000097          	auipc	ra,0x0
    80000f8a:	f7a080e7          	jalr	-134(ra) # 80000f00 <pop_off>
}
    80000f8e:	60e2                	ld	ra,24(sp)
    80000f90:	6442                	ld	s0,16(sp)
    80000f92:	64a2                	ld	s1,8(sp)
    80000f94:	6105                	addi	sp,sp,32
    80000f96:	8082                	ret
    panic("release");
    80000f98:	00007517          	auipc	a0,0x7
    80000f9c:	13850513          	addi	a0,a0,312 # 800080d0 <digits+0x90>
    80000fa0:	fffff097          	auipc	ra,0xfffff
    80000fa4:	5a4080e7          	jalr	1444(ra) # 80000544 <panic>

0000000080000fa8 <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000fa8:	1141                	addi	sp,sp,-16
    80000faa:	e422                	sd	s0,8(sp)
    80000fac:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000fae:	ce09                	beqz	a2,80000fc8 <memset+0x20>
    80000fb0:	87aa                	mv	a5,a0
    80000fb2:	fff6071b          	addiw	a4,a2,-1
    80000fb6:	1702                	slli	a4,a4,0x20
    80000fb8:	9301                	srli	a4,a4,0x20
    80000fba:	0705                	addi	a4,a4,1
    80000fbc:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000fbe:	00b78023          	sb	a1,0(a5) # fffffffffffff000 <end+0xffffffff7fdbaef0>
  for(i = 0; i < n; i++){
    80000fc2:	0785                	addi	a5,a5,1
    80000fc4:	fee79de3          	bne	a5,a4,80000fbe <memset+0x16>
  }
  return dst;
}
    80000fc8:	6422                	ld	s0,8(sp)
    80000fca:	0141                	addi	sp,sp,16
    80000fcc:	8082                	ret

0000000080000fce <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000fce:	1141                	addi	sp,sp,-16
    80000fd0:	e422                	sd	s0,8(sp)
    80000fd2:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000fd4:	ca05                	beqz	a2,80001004 <memcmp+0x36>
    80000fd6:	fff6069b          	addiw	a3,a2,-1
    80000fda:	1682                	slli	a3,a3,0x20
    80000fdc:	9281                	srli	a3,a3,0x20
    80000fde:	0685                	addi	a3,a3,1
    80000fe0:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000fe2:	00054783          	lbu	a5,0(a0)
    80000fe6:	0005c703          	lbu	a4,0(a1) # fffffffffffff000 <end+0xffffffff7fdbaef0>
    80000fea:	00e79863          	bne	a5,a4,80000ffa <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000fee:	0505                	addi	a0,a0,1
    80000ff0:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000ff2:	fed518e3          	bne	a0,a3,80000fe2 <memcmp+0x14>
  }

  return 0;
    80000ff6:	4501                	li	a0,0
    80000ff8:	a019                	j	80000ffe <memcmp+0x30>
      return *s1 - *s2;
    80000ffa:	40e7853b          	subw	a0,a5,a4
}
    80000ffe:	6422                	ld	s0,8(sp)
    80001000:	0141                	addi	sp,sp,16
    80001002:	8082                	ret
  return 0;
    80001004:	4501                	li	a0,0
    80001006:	bfe5                	j	80000ffe <memcmp+0x30>

0000000080001008 <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80001008:	1141                	addi	sp,sp,-16
    8000100a:	e422                	sd	s0,8(sp)
    8000100c:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    8000100e:	ca0d                	beqz	a2,80001040 <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80001010:	00a5f963          	bgeu	a1,a0,80001022 <memmove+0x1a>
    80001014:	02061693          	slli	a3,a2,0x20
    80001018:	9281                	srli	a3,a3,0x20
    8000101a:	00d58733          	add	a4,a1,a3
    8000101e:	02e56463          	bltu	a0,a4,80001046 <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80001022:	fff6079b          	addiw	a5,a2,-1
    80001026:	1782                	slli	a5,a5,0x20
    80001028:	9381                	srli	a5,a5,0x20
    8000102a:	0785                	addi	a5,a5,1
    8000102c:	97ae                	add	a5,a5,a1
    8000102e:	872a                	mv	a4,a0
      *d++ = *s++;
    80001030:	0585                	addi	a1,a1,1
    80001032:	0705                	addi	a4,a4,1
    80001034:	fff5c683          	lbu	a3,-1(a1)
    80001038:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    8000103c:	fef59ae3          	bne	a1,a5,80001030 <memmove+0x28>

  return dst;
}
    80001040:	6422                	ld	s0,8(sp)
    80001042:	0141                	addi	sp,sp,16
    80001044:	8082                	ret
    d += n;
    80001046:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80001048:	fff6079b          	addiw	a5,a2,-1
    8000104c:	1782                	slli	a5,a5,0x20
    8000104e:	9381                	srli	a5,a5,0x20
    80001050:	fff7c793          	not	a5,a5
    80001054:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80001056:	177d                	addi	a4,a4,-1
    80001058:	16fd                	addi	a3,a3,-1
    8000105a:	00074603          	lbu	a2,0(a4)
    8000105e:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80001062:	fef71ae3          	bne	a4,a5,80001056 <memmove+0x4e>
    80001066:	bfe9                	j	80001040 <memmove+0x38>

0000000080001068 <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    80001068:	1141                	addi	sp,sp,-16
    8000106a:	e406                	sd	ra,8(sp)
    8000106c:	e022                	sd	s0,0(sp)
    8000106e:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80001070:	00000097          	auipc	ra,0x0
    80001074:	f98080e7          	jalr	-104(ra) # 80001008 <memmove>
}
    80001078:	60a2                	ld	ra,8(sp)
    8000107a:	6402                	ld	s0,0(sp)
    8000107c:	0141                	addi	sp,sp,16
    8000107e:	8082                	ret

0000000080001080 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80001080:	1141                	addi	sp,sp,-16
    80001082:	e422                	sd	s0,8(sp)
    80001084:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80001086:	ce11                	beqz	a2,800010a2 <strncmp+0x22>
    80001088:	00054783          	lbu	a5,0(a0)
    8000108c:	cf89                	beqz	a5,800010a6 <strncmp+0x26>
    8000108e:	0005c703          	lbu	a4,0(a1)
    80001092:	00f71a63          	bne	a4,a5,800010a6 <strncmp+0x26>
    n--, p++, q++;
    80001096:	367d                	addiw	a2,a2,-1
    80001098:	0505                	addi	a0,a0,1
    8000109a:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    8000109c:	f675                	bnez	a2,80001088 <strncmp+0x8>
  if(n == 0)
    return 0;
    8000109e:	4501                	li	a0,0
    800010a0:	a809                	j	800010b2 <strncmp+0x32>
    800010a2:	4501                	li	a0,0
    800010a4:	a039                	j	800010b2 <strncmp+0x32>
  if(n == 0)
    800010a6:	ca09                	beqz	a2,800010b8 <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    800010a8:	00054503          	lbu	a0,0(a0)
    800010ac:	0005c783          	lbu	a5,0(a1)
    800010b0:	9d1d                	subw	a0,a0,a5
}
    800010b2:	6422                	ld	s0,8(sp)
    800010b4:	0141                	addi	sp,sp,16
    800010b6:	8082                	ret
    return 0;
    800010b8:	4501                	li	a0,0
    800010ba:	bfe5                	j	800010b2 <strncmp+0x32>

00000000800010bc <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    800010bc:	1141                	addi	sp,sp,-16
    800010be:	e422                	sd	s0,8(sp)
    800010c0:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    800010c2:	872a                	mv	a4,a0
    800010c4:	8832                	mv	a6,a2
    800010c6:	367d                	addiw	a2,a2,-1
    800010c8:	01005963          	blez	a6,800010da <strncpy+0x1e>
    800010cc:	0705                	addi	a4,a4,1
    800010ce:	0005c783          	lbu	a5,0(a1)
    800010d2:	fef70fa3          	sb	a5,-1(a4)
    800010d6:	0585                	addi	a1,a1,1
    800010d8:	f7f5                	bnez	a5,800010c4 <strncpy+0x8>
    ;
  while(n-- > 0)
    800010da:	00c05d63          	blez	a2,800010f4 <strncpy+0x38>
    800010de:	86ba                	mv	a3,a4
    *s++ = 0;
    800010e0:	0685                	addi	a3,a3,1
    800010e2:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    800010e6:	fff6c793          	not	a5,a3
    800010ea:	9fb9                	addw	a5,a5,a4
    800010ec:	010787bb          	addw	a5,a5,a6
    800010f0:	fef048e3          	bgtz	a5,800010e0 <strncpy+0x24>
  return os;
}
    800010f4:	6422                	ld	s0,8(sp)
    800010f6:	0141                	addi	sp,sp,16
    800010f8:	8082                	ret

00000000800010fa <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    800010fa:	1141                	addi	sp,sp,-16
    800010fc:	e422                	sd	s0,8(sp)
    800010fe:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    80001100:	02c05363          	blez	a2,80001126 <safestrcpy+0x2c>
    80001104:	fff6069b          	addiw	a3,a2,-1
    80001108:	1682                	slli	a3,a3,0x20
    8000110a:	9281                	srli	a3,a3,0x20
    8000110c:	96ae                	add	a3,a3,a1
    8000110e:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    80001110:	00d58963          	beq	a1,a3,80001122 <safestrcpy+0x28>
    80001114:	0585                	addi	a1,a1,1
    80001116:	0785                	addi	a5,a5,1
    80001118:	fff5c703          	lbu	a4,-1(a1)
    8000111c:	fee78fa3          	sb	a4,-1(a5)
    80001120:	fb65                	bnez	a4,80001110 <safestrcpy+0x16>
    ;
  *s = 0;
    80001122:	00078023          	sb	zero,0(a5)
  return os;
}
    80001126:	6422                	ld	s0,8(sp)
    80001128:	0141                	addi	sp,sp,16
    8000112a:	8082                	ret

000000008000112c <strlen>:

int
strlen(const char *s)
{
    8000112c:	1141                	addi	sp,sp,-16
    8000112e:	e422                	sd	s0,8(sp)
    80001130:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    80001132:	00054783          	lbu	a5,0(a0)
    80001136:	cf91                	beqz	a5,80001152 <strlen+0x26>
    80001138:	0505                	addi	a0,a0,1
    8000113a:	87aa                	mv	a5,a0
    8000113c:	4685                	li	a3,1
    8000113e:	9e89                	subw	a3,a3,a0
    80001140:	00f6853b          	addw	a0,a3,a5
    80001144:	0785                	addi	a5,a5,1
    80001146:	fff7c703          	lbu	a4,-1(a5)
    8000114a:	fb7d                	bnez	a4,80001140 <strlen+0x14>
    ;
  return n;
}
    8000114c:	6422                	ld	s0,8(sp)
    8000114e:	0141                	addi	sp,sp,16
    80001150:	8082                	ret
  for(n = 0; s[n]; n++)
    80001152:	4501                	li	a0,0
    80001154:	bfe5                	j	8000114c <strlen+0x20>

0000000080001156 <main>:
volatile static int started = 0;
// start() jumps here in supervisor mode on all CPUs.
extern pde_t *kpgdir;
void
main()
{
    80001156:	1141                	addi	sp,sp,-16
    80001158:	e406                	sd	ra,8(sp)
    8000115a:	e022                	sd	s0,0(sp)
    8000115c:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    8000115e:	00001097          	auipc	ra,0x1
    80001162:	b6a080e7          	jalr	-1174(ra) # 80001cc8 <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80001166:	00008717          	auipc	a4,0x8
    8000116a:	96270713          	addi	a4,a4,-1694 # 80008ac8 <started>
  if(cpuid() == 0){
    8000116e:	c139                	beqz	a0,800011b4 <main+0x5e>
    while(started == 0)
    80001170:	431c                	lw	a5,0(a4)
    80001172:	2781                	sext.w	a5,a5
    80001174:	dff5                	beqz	a5,80001170 <main+0x1a>
      ;
    __sync_synchronize();
    80001176:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    8000117a:	00001097          	auipc	ra,0x1
    8000117e:	b4e080e7          	jalr	-1202(ra) # 80001cc8 <cpuid>
    80001182:	85aa                	mv	a1,a0
    80001184:	00007517          	auipc	a0,0x7
    80001188:	f6c50513          	addi	a0,a0,-148 # 800080f0 <digits+0xb0>
    8000118c:	fffff097          	auipc	ra,0xfffff
    80001190:	402080e7          	jalr	1026(ra) # 8000058e <printf>
    kvminithart();    // turn on paging
    80001194:	00000097          	auipc	ra,0x0
    80001198:	0d8080e7          	jalr	216(ra) # 8000126c <kvminithart>
    trapinithart();   // install kernel trap vector
    8000119c:	00002097          	auipc	ra,0x2
    800011a0:	cb4080e7          	jalr	-844(ra) # 80002e50 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    800011a4:	00005097          	auipc	ra,0x5
    800011a8:	72c080e7          	jalr	1836(ra) # 800068d0 <plicinithart>
  }

  scheduler();        
    800011ac:	00001097          	auipc	ra,0x1
    800011b0:	2fe080e7          	jalr	766(ra) # 800024aa <scheduler>
    consoleinit();
    800011b4:	fffff097          	auipc	ra,0xfffff
    800011b8:	2a2080e7          	jalr	674(ra) # 80000456 <consoleinit>
    printfinit();
    800011bc:	fffff097          	auipc	ra,0xfffff
    800011c0:	5b8080e7          	jalr	1464(ra) # 80000774 <printfinit>
    printf("\n");
    800011c4:	00007517          	auipc	a0,0x7
    800011c8:	f3c50513          	addi	a0,a0,-196 # 80008100 <digits+0xc0>
    800011cc:	fffff097          	auipc	ra,0xfffff
    800011d0:	3c2080e7          	jalr	962(ra) # 8000058e <printf>
    printf("xv6 kernel is booting\n");
    800011d4:	00007517          	auipc	a0,0x7
    800011d8:	f0450513          	addi	a0,a0,-252 # 800080d8 <digits+0x98>
    800011dc:	fffff097          	auipc	ra,0xfffff
    800011e0:	3b2080e7          	jalr	946(ra) # 8000058e <printf>
    printf("\n");
    800011e4:	00007517          	auipc	a0,0x7
    800011e8:	f1c50513          	addi	a0,a0,-228 # 80008100 <digits+0xc0>
    800011ec:	fffff097          	auipc	ra,0xfffff
    800011f0:	3a2080e7          	jalr	930(ra) # 8000058e <printf>
    kinit();         // physical page allocator
    800011f4:	00000097          	auipc	ra,0x0
    800011f8:	abc080e7          	jalr	-1348(ra) # 80000cb0 <kinit>
    kvminit();       // create kernel page table
    800011fc:	00000097          	auipc	ra,0x0
    80001200:	326080e7          	jalr	806(ra) # 80001522 <kvminit>
    kvminithart();   // turn on paging
    80001204:	00000097          	auipc	ra,0x0
    80001208:	068080e7          	jalr	104(ra) # 8000126c <kvminithart>
    procinit();      // process table
    8000120c:	00001097          	auipc	ra,0x1
    80001210:	a08080e7          	jalr	-1528(ra) # 80001c14 <procinit>
    trapinit();      // trap vectors
    80001214:	00002097          	auipc	ra,0x2
    80001218:	c54080e7          	jalr	-940(ra) # 80002e68 <trapinit>
    trapinithart();  // install kernel trap vector
    8000121c:	00002097          	auipc	ra,0x2
    80001220:	c34080e7          	jalr	-972(ra) # 80002e50 <trapinithart>
    plicinit();      // set up interrupt controller
    80001224:	00005097          	auipc	ra,0x5
    80001228:	696080e7          	jalr	1686(ra) # 800068ba <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    8000122c:	00005097          	auipc	ra,0x5
    80001230:	6a4080e7          	jalr	1700(ra) # 800068d0 <plicinithart>
    binit();         // buffer cache
    80001234:	00003097          	auipc	ra,0x3
    80001238:	854080e7          	jalr	-1964(ra) # 80003a88 <binit>
    iinit();         // inode table
    8000123c:	00003097          	auipc	ra,0x3
    80001240:	ef8080e7          	jalr	-264(ra) # 80004134 <iinit>
    fileinit();      // file table
    80001244:	00004097          	auipc	ra,0x4
    80001248:	e96080e7          	jalr	-362(ra) # 800050da <fileinit>
    virtio_disk_init(); // emulated hard disk
    8000124c:	00005097          	auipc	ra,0x5
    80001250:	78c080e7          	jalr	1932(ra) # 800069d8 <virtio_disk_init>
    userinit();      // first user process
    80001254:	00001097          	auipc	ra,0x1
    80001258:	f1c080e7          	jalr	-228(ra) # 80002170 <userinit>
    __sync_synchronize();
    8000125c:	0ff0000f          	fence
    started = 1;
    80001260:	4785                	li	a5,1
    80001262:	00008717          	auipc	a4,0x8
    80001266:	86f72323          	sw	a5,-1946(a4) # 80008ac8 <started>
    8000126a:	b789                	j	800011ac <main+0x56>

000000008000126c <kvminithart>:
}

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void kvminithart()
{
    8000126c:	1141                	addi	sp,sp,-16
    8000126e:	e422                	sd	s0,8(sp)
    80001270:	0800                	addi	s0,sp,16
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80001272:	12000073          	sfence.vma
  // wait for any previous writes to the page table memory to finish.
  sfence_vma();

  w_satp(MAKE_SATP(kernel_pagetable));
    80001276:	00008797          	auipc	a5,0x8
    8000127a:	85a7b783          	ld	a5,-1958(a5) # 80008ad0 <kernel_pagetable>
    8000127e:	83b1                	srli	a5,a5,0xc
    80001280:	577d                	li	a4,-1
    80001282:	177e                	slli	a4,a4,0x3f
    80001284:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001286:	18079073          	csrw	satp,a5
  asm volatile("sfence.vma zero, zero");
    8000128a:	12000073          	sfence.vma

  // flush stale entries from the TLB.
  sfence_vma();
}
    8000128e:	6422                	ld	s0,8(sp)
    80001290:	0141                	addi	sp,sp,16
    80001292:	8082                	ret

0000000080001294 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001294:	7139                	addi	sp,sp,-64
    80001296:	fc06                	sd	ra,56(sp)
    80001298:	f822                	sd	s0,48(sp)
    8000129a:	f426                	sd	s1,40(sp)
    8000129c:	f04a                	sd	s2,32(sp)
    8000129e:	ec4e                	sd	s3,24(sp)
    800012a0:	e852                	sd	s4,16(sp)
    800012a2:	e456                	sd	s5,8(sp)
    800012a4:	e05a                	sd	s6,0(sp)
    800012a6:	0080                	addi	s0,sp,64
    800012a8:	84aa                	mv	s1,a0
    800012aa:	89ae                	mv	s3,a1
    800012ac:	8ab2                	mv	s5,a2
  if (va >= MAXVA)
    800012ae:	57fd                	li	a5,-1
    800012b0:	83e9                	srli	a5,a5,0x1a
    800012b2:	4a79                	li	s4,30
    panic("walk");

  for (int level = 2; level > 0; level--)
    800012b4:	4b31                	li	s6,12
  if (va >= MAXVA)
    800012b6:	04b7f263          	bgeu	a5,a1,800012fa <walk+0x66>
    panic("walk");
    800012ba:	00007517          	auipc	a0,0x7
    800012be:	e4e50513          	addi	a0,a0,-434 # 80008108 <digits+0xc8>
    800012c2:	fffff097          	auipc	ra,0xfffff
    800012c6:	282080e7          	jalr	642(ra) # 80000544 <panic>
    {
      pagetable = (pagetable_t)PTE2PA(*pte);
    }
    else
    {
      if (!alloc || (pagetable = (pde_t *)kalloc()) == 0)
    800012ca:	060a8663          	beqz	s5,80001336 <walk+0xa2>
    800012ce:	00000097          	auipc	ra,0x0
    800012d2:	a26080e7          	jalr	-1498(ra) # 80000cf4 <kalloc>
    800012d6:	84aa                	mv	s1,a0
    800012d8:	c529                	beqz	a0,80001322 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    800012da:	6605                	lui	a2,0x1
    800012dc:	4581                	li	a1,0
    800012de:	00000097          	auipc	ra,0x0
    800012e2:	cca080e7          	jalr	-822(ra) # 80000fa8 <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    800012e6:	00c4d793          	srli	a5,s1,0xc
    800012ea:	07aa                	slli	a5,a5,0xa
    800012ec:	0017e793          	ori	a5,a5,1
    800012f0:	00f93023          	sd	a5,0(s2)
  for (int level = 2; level > 0; level--)
    800012f4:	3a5d                	addiw	s4,s4,-9
    800012f6:	036a0063          	beq	s4,s6,80001316 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    800012fa:	0149d933          	srl	s2,s3,s4
    800012fe:	1ff97913          	andi	s2,s2,511
    80001302:	090e                	slli	s2,s2,0x3
    80001304:	9926                	add	s2,s2,s1
    if (*pte & PTE_V)
    80001306:	00093483          	ld	s1,0(s2)
    8000130a:	0014f793          	andi	a5,s1,1
    8000130e:	dfd5                	beqz	a5,800012ca <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    80001310:	80a9                	srli	s1,s1,0xa
    80001312:	04b2                	slli	s1,s1,0xc
    80001314:	b7c5                	j	800012f4 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    80001316:	00c9d513          	srli	a0,s3,0xc
    8000131a:	1ff57513          	andi	a0,a0,511
    8000131e:	050e                	slli	a0,a0,0x3
    80001320:	9526                	add	a0,a0,s1
}
    80001322:	70e2                	ld	ra,56(sp)
    80001324:	7442                	ld	s0,48(sp)
    80001326:	74a2                	ld	s1,40(sp)
    80001328:	7902                	ld	s2,32(sp)
    8000132a:	69e2                	ld	s3,24(sp)
    8000132c:	6a42                	ld	s4,16(sp)
    8000132e:	6aa2                	ld	s5,8(sp)
    80001330:	6b02                	ld	s6,0(sp)
    80001332:	6121                	addi	sp,sp,64
    80001334:	8082                	ret
        return 0;
    80001336:	4501                	li	a0,0
    80001338:	b7ed                	j	80001322 <walk+0x8e>

000000008000133a <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if (va >= MAXVA)
    8000133a:	57fd                	li	a5,-1
    8000133c:	83e9                	srli	a5,a5,0x1a
    8000133e:	00b7f463          	bgeu	a5,a1,80001346 <walkaddr+0xc>
    return 0;
    80001342:	4501                	li	a0,0
    return 0;
  if ((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    80001344:	8082                	ret
{
    80001346:	1141                	addi	sp,sp,-16
    80001348:	e406                	sd	ra,8(sp)
    8000134a:	e022                	sd	s0,0(sp)
    8000134c:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    8000134e:	4601                	li	a2,0
    80001350:	00000097          	auipc	ra,0x0
    80001354:	f44080e7          	jalr	-188(ra) # 80001294 <walk>
  if (pte == 0)
    80001358:	c105                	beqz	a0,80001378 <walkaddr+0x3e>
  if ((*pte & PTE_V) == 0)
    8000135a:	611c                	ld	a5,0(a0)
  if ((*pte & PTE_U) == 0)
    8000135c:	0117f693          	andi	a3,a5,17
    80001360:	4745                	li	a4,17
    return 0;
    80001362:	4501                	li	a0,0
  if ((*pte & PTE_U) == 0)
    80001364:	00e68663          	beq	a3,a4,80001370 <walkaddr+0x36>
}
    80001368:	60a2                	ld	ra,8(sp)
    8000136a:	6402                	ld	s0,0(sp)
    8000136c:	0141                	addi	sp,sp,16
    8000136e:	8082                	ret
  pa = PTE2PA(*pte);
    80001370:	00a7d513          	srli	a0,a5,0xa
    80001374:	0532                	slli	a0,a0,0xc
  return pa;
    80001376:	bfcd                	j	80001368 <walkaddr+0x2e>
    return 0;
    80001378:	4501                	li	a0,0
    8000137a:	b7fd                	j	80001368 <walkaddr+0x2e>

000000008000137c <mappages>:
// Create PTEs for virtual addresses starting at va that refer to
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000137c:	715d                	addi	sp,sp,-80
    8000137e:	e486                	sd	ra,72(sp)
    80001380:	e0a2                	sd	s0,64(sp)
    80001382:	fc26                	sd	s1,56(sp)
    80001384:	f84a                	sd	s2,48(sp)
    80001386:	f44e                	sd	s3,40(sp)
    80001388:	f052                	sd	s4,32(sp)
    8000138a:	ec56                	sd	s5,24(sp)
    8000138c:	e85a                	sd	s6,16(sp)
    8000138e:	e45e                	sd	s7,8(sp)
    80001390:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if (size == 0)
    80001392:	c205                	beqz	a2,800013b2 <mappages+0x36>
    80001394:	8aaa                	mv	s5,a0
    80001396:	8b3a                	mv	s6,a4
    panic("mappages: size");

  a = PGROUNDDOWN(va);
    80001398:	77fd                	lui	a5,0xfffff
    8000139a:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    8000139e:	15fd                	addi	a1,a1,-1
    800013a0:	00c589b3          	add	s3,a1,a2
    800013a4:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    800013a8:	8952                	mv	s2,s4
    800013aa:	41468a33          	sub	s4,a3,s4
    if (*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if (a == last)
      break;
    a += PGSIZE;
    800013ae:	6b85                	lui	s7,0x1
    800013b0:	a015                	j	800013d4 <mappages+0x58>
    panic("mappages: size");
    800013b2:	00007517          	auipc	a0,0x7
    800013b6:	d5e50513          	addi	a0,a0,-674 # 80008110 <digits+0xd0>
    800013ba:	fffff097          	auipc	ra,0xfffff
    800013be:	18a080e7          	jalr	394(ra) # 80000544 <panic>
      panic("mappages: remap");
    800013c2:	00007517          	auipc	a0,0x7
    800013c6:	d5e50513          	addi	a0,a0,-674 # 80008120 <digits+0xe0>
    800013ca:	fffff097          	auipc	ra,0xfffff
    800013ce:	17a080e7          	jalr	378(ra) # 80000544 <panic>
    a += PGSIZE;
    800013d2:	995e                	add	s2,s2,s7
  for (;;)
    800013d4:	012a04b3          	add	s1,s4,s2
    if ((pte = walk(pagetable, a, 1)) == 0)
    800013d8:	4605                	li	a2,1
    800013da:	85ca                	mv	a1,s2
    800013dc:	8556                	mv	a0,s5
    800013de:	00000097          	auipc	ra,0x0
    800013e2:	eb6080e7          	jalr	-330(ra) # 80001294 <walk>
    800013e6:	cd19                	beqz	a0,80001404 <mappages+0x88>
    if (*pte & PTE_V)
    800013e8:	611c                	ld	a5,0(a0)
    800013ea:	8b85                	andi	a5,a5,1
    800013ec:	fbf9                	bnez	a5,800013c2 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    800013ee:	80b1                	srli	s1,s1,0xc
    800013f0:	04aa                	slli	s1,s1,0xa
    800013f2:	0164e4b3          	or	s1,s1,s6
    800013f6:	0014e493          	ori	s1,s1,1
    800013fa:	e104                	sd	s1,0(a0)
    if (a == last)
    800013fc:	fd391be3          	bne	s2,s3,800013d2 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    80001400:	4501                	li	a0,0
    80001402:	a011                	j	80001406 <mappages+0x8a>
      return -1;
    80001404:	557d                	li	a0,-1
}
    80001406:	60a6                	ld	ra,72(sp)
    80001408:	6406                	ld	s0,64(sp)
    8000140a:	74e2                	ld	s1,56(sp)
    8000140c:	7942                	ld	s2,48(sp)
    8000140e:	79a2                	ld	s3,40(sp)
    80001410:	7a02                	ld	s4,32(sp)
    80001412:	6ae2                	ld	s5,24(sp)
    80001414:	6b42                	ld	s6,16(sp)
    80001416:	6ba2                	ld	s7,8(sp)
    80001418:	6161                	addi	sp,sp,80
    8000141a:	8082                	ret

000000008000141c <kvmmap>:
{
    8000141c:	1141                	addi	sp,sp,-16
    8000141e:	e406                	sd	ra,8(sp)
    80001420:	e022                	sd	s0,0(sp)
    80001422:	0800                	addi	s0,sp,16
    80001424:	87b6                	mv	a5,a3
  if (mappages(kpgtbl, va, sz, pa, perm) != 0)
    80001426:	86b2                	mv	a3,a2
    80001428:	863e                	mv	a2,a5
    8000142a:	00000097          	auipc	ra,0x0
    8000142e:	f52080e7          	jalr	-174(ra) # 8000137c <mappages>
    80001432:	e509                	bnez	a0,8000143c <kvmmap+0x20>
}
    80001434:	60a2                	ld	ra,8(sp)
    80001436:	6402                	ld	s0,0(sp)
    80001438:	0141                	addi	sp,sp,16
    8000143a:	8082                	ret
    panic("kvmmap");
    8000143c:	00007517          	auipc	a0,0x7
    80001440:	cf450513          	addi	a0,a0,-780 # 80008130 <digits+0xf0>
    80001444:	fffff097          	auipc	ra,0xfffff
    80001448:	100080e7          	jalr	256(ra) # 80000544 <panic>

000000008000144c <kvmmake>:
{
    8000144c:	1101                	addi	sp,sp,-32
    8000144e:	ec06                	sd	ra,24(sp)
    80001450:	e822                	sd	s0,16(sp)
    80001452:	e426                	sd	s1,8(sp)
    80001454:	e04a                	sd	s2,0(sp)
    80001456:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t)kalloc();
    80001458:	00000097          	auipc	ra,0x0
    8000145c:	89c080e7          	jalr	-1892(ra) # 80000cf4 <kalloc>
    80001460:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001462:	6605                	lui	a2,0x1
    80001464:	4581                	li	a1,0
    80001466:	00000097          	auipc	ra,0x0
    8000146a:	b42080e7          	jalr	-1214(ra) # 80000fa8 <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000146e:	4719                	li	a4,6
    80001470:	6685                	lui	a3,0x1
    80001472:	10000637          	lui	a2,0x10000
    80001476:	100005b7          	lui	a1,0x10000
    8000147a:	8526                	mv	a0,s1
    8000147c:	00000097          	auipc	ra,0x0
    80001480:	fa0080e7          	jalr	-96(ra) # 8000141c <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001484:	4719                	li	a4,6
    80001486:	6685                	lui	a3,0x1
    80001488:	10001637          	lui	a2,0x10001
    8000148c:	100015b7          	lui	a1,0x10001
    80001490:	8526                	mv	a0,s1
    80001492:	00000097          	auipc	ra,0x0
    80001496:	f8a080e7          	jalr	-118(ra) # 8000141c <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    8000149a:	4719                	li	a4,6
    8000149c:	004006b7          	lui	a3,0x400
    800014a0:	0c000637          	lui	a2,0xc000
    800014a4:	0c0005b7          	lui	a1,0xc000
    800014a8:	8526                	mv	a0,s1
    800014aa:	00000097          	auipc	ra,0x0
    800014ae:	f72080e7          	jalr	-142(ra) # 8000141c <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext - KERNBASE, PTE_R | PTE_X);
    800014b2:	00007917          	auipc	s2,0x7
    800014b6:	b4e90913          	addi	s2,s2,-1202 # 80008000 <etext>
    800014ba:	4729                	li	a4,10
    800014bc:	80007697          	auipc	a3,0x80007
    800014c0:	b4468693          	addi	a3,a3,-1212 # 8000 <_entry-0x7fff8000>
    800014c4:	4605                	li	a2,1
    800014c6:	067e                	slli	a2,a2,0x1f
    800014c8:	85b2                	mv	a1,a2
    800014ca:	8526                	mv	a0,s1
    800014cc:	00000097          	auipc	ra,0x0
    800014d0:	f50080e7          	jalr	-176(ra) # 8000141c <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP - (uint64)etext, PTE_R | PTE_W);
    800014d4:	4719                	li	a4,6
    800014d6:	46c5                	li	a3,17
    800014d8:	06ee                	slli	a3,a3,0x1b
    800014da:	412686b3          	sub	a3,a3,s2
    800014de:	864a                	mv	a2,s2
    800014e0:	85ca                	mv	a1,s2
    800014e2:	8526                	mv	a0,s1
    800014e4:	00000097          	auipc	ra,0x0
    800014e8:	f38080e7          	jalr	-200(ra) # 8000141c <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    800014ec:	4729                	li	a4,10
    800014ee:	6685                	lui	a3,0x1
    800014f0:	00006617          	auipc	a2,0x6
    800014f4:	b1060613          	addi	a2,a2,-1264 # 80007000 <_trampoline>
    800014f8:	040005b7          	lui	a1,0x4000
    800014fc:	15fd                	addi	a1,a1,-1
    800014fe:	05b2                	slli	a1,a1,0xc
    80001500:	8526                	mv	a0,s1
    80001502:	00000097          	auipc	ra,0x0
    80001506:	f1a080e7          	jalr	-230(ra) # 8000141c <kvmmap>
  proc_mapstacks(kpgtbl);
    8000150a:	8526                	mv	a0,s1
    8000150c:	00000097          	auipc	ra,0x0
    80001510:	672080e7          	jalr	1650(ra) # 80001b7e <proc_mapstacks>
}
    80001514:	8526                	mv	a0,s1
    80001516:	60e2                	ld	ra,24(sp)
    80001518:	6442                	ld	s0,16(sp)
    8000151a:	64a2                	ld	s1,8(sp)
    8000151c:	6902                	ld	s2,0(sp)
    8000151e:	6105                	addi	sp,sp,32
    80001520:	8082                	ret

0000000080001522 <kvminit>:
{
    80001522:	1141                	addi	sp,sp,-16
    80001524:	e406                	sd	ra,8(sp)
    80001526:	e022                	sd	s0,0(sp)
    80001528:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    8000152a:	00000097          	auipc	ra,0x0
    8000152e:	f22080e7          	jalr	-222(ra) # 8000144c <kvmmake>
    80001532:	00007797          	auipc	a5,0x7
    80001536:	58a7bf23          	sd	a0,1438(a5) # 80008ad0 <kernel_pagetable>
}
    8000153a:	60a2                	ld	ra,8(sp)
    8000153c:	6402                	ld	s0,0(sp)
    8000153e:	0141                	addi	sp,sp,16
    80001540:	8082                	ret

0000000080001542 <uvmunmap>:

// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    80001542:	715d                	addi	sp,sp,-80
    80001544:	e486                	sd	ra,72(sp)
    80001546:	e0a2                	sd	s0,64(sp)
    80001548:	fc26                	sd	s1,56(sp)
    8000154a:	f84a                	sd	s2,48(sp)
    8000154c:	f44e                	sd	s3,40(sp)
    8000154e:	f052                	sd	s4,32(sp)
    80001550:	ec56                	sd	s5,24(sp)
    80001552:	e85a                	sd	s6,16(sp)
    80001554:	e45e                	sd	s7,8(sp)
    80001556:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if ((va % PGSIZE) != 0)
    80001558:	03459793          	slli	a5,a1,0x34
    8000155c:	e795                	bnez	a5,80001588 <uvmunmap+0x46>
    8000155e:	8a2a                	mv	s4,a0
    80001560:	892e                	mv	s2,a1
    80001562:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for (a = va; a < va + npages * PGSIZE; a += PGSIZE)
    80001564:	0632                	slli	a2,a2,0xc
    80001566:	00b609b3          	add	s3,a2,a1
  {
    if ((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if ((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if (PTE_FLAGS(*pte) == PTE_V)
    8000156a:	4b85                	li	s7,1
  for (a = va; a < va + npages * PGSIZE; a += PGSIZE)
    8000156c:	6b05                	lui	s6,0x1
    8000156e:	0735e863          	bltu	a1,s3,800015de <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void *)pa);
    }
    *pte = 0;
  }
}
    80001572:	60a6                	ld	ra,72(sp)
    80001574:	6406                	ld	s0,64(sp)
    80001576:	74e2                	ld	s1,56(sp)
    80001578:	7942                	ld	s2,48(sp)
    8000157a:	79a2                	ld	s3,40(sp)
    8000157c:	7a02                	ld	s4,32(sp)
    8000157e:	6ae2                	ld	s5,24(sp)
    80001580:	6b42                	ld	s6,16(sp)
    80001582:	6ba2                	ld	s7,8(sp)
    80001584:	6161                	addi	sp,sp,80
    80001586:	8082                	ret
    panic("uvmunmap: not aligned");
    80001588:	00007517          	auipc	a0,0x7
    8000158c:	bb050513          	addi	a0,a0,-1104 # 80008138 <digits+0xf8>
    80001590:	fffff097          	auipc	ra,0xfffff
    80001594:	fb4080e7          	jalr	-76(ra) # 80000544 <panic>
      panic("uvmunmap: walk");
    80001598:	00007517          	auipc	a0,0x7
    8000159c:	bb850513          	addi	a0,a0,-1096 # 80008150 <digits+0x110>
    800015a0:	fffff097          	auipc	ra,0xfffff
    800015a4:	fa4080e7          	jalr	-92(ra) # 80000544 <panic>
      panic("uvmunmap: not mapped");
    800015a8:	00007517          	auipc	a0,0x7
    800015ac:	bb850513          	addi	a0,a0,-1096 # 80008160 <digits+0x120>
    800015b0:	fffff097          	auipc	ra,0xfffff
    800015b4:	f94080e7          	jalr	-108(ra) # 80000544 <panic>
      panic("uvmunmap: not a leaf");
    800015b8:	00007517          	auipc	a0,0x7
    800015bc:	bc050513          	addi	a0,a0,-1088 # 80008178 <digits+0x138>
    800015c0:	fffff097          	auipc	ra,0xfffff
    800015c4:	f84080e7          	jalr	-124(ra) # 80000544 <panic>
      uint64 pa = PTE2PA(*pte);
    800015c8:	8129                	srli	a0,a0,0xa
      kfree((void *)pa);
    800015ca:	0532                	slli	a0,a0,0xc
    800015cc:	fffff097          	auipc	ra,0xfffff
    800015d0:	5ca080e7          	jalr	1482(ra) # 80000b96 <kfree>
    *pte = 0;
    800015d4:	0004b023          	sd	zero,0(s1)
  for (a = va; a < va + npages * PGSIZE; a += PGSIZE)
    800015d8:	995a                	add	s2,s2,s6
    800015da:	f9397ce3          	bgeu	s2,s3,80001572 <uvmunmap+0x30>
    if ((pte = walk(pagetable, a, 0)) == 0)
    800015de:	4601                	li	a2,0
    800015e0:	85ca                	mv	a1,s2
    800015e2:	8552                	mv	a0,s4
    800015e4:	00000097          	auipc	ra,0x0
    800015e8:	cb0080e7          	jalr	-848(ra) # 80001294 <walk>
    800015ec:	84aa                	mv	s1,a0
    800015ee:	d54d                	beqz	a0,80001598 <uvmunmap+0x56>
    if ((*pte & PTE_V) == 0)
    800015f0:	6108                	ld	a0,0(a0)
    800015f2:	00157793          	andi	a5,a0,1
    800015f6:	dbcd                	beqz	a5,800015a8 <uvmunmap+0x66>
    if (PTE_FLAGS(*pte) == PTE_V)
    800015f8:	3ff57793          	andi	a5,a0,1023
    800015fc:	fb778ee3          	beq	a5,s7,800015b8 <uvmunmap+0x76>
    if (do_free)
    80001600:	fc0a8ae3          	beqz	s5,800015d4 <uvmunmap+0x92>
    80001604:	b7d1                	j	800015c8 <uvmunmap+0x86>

0000000080001606 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    80001606:	1101                	addi	sp,sp,-32
    80001608:	ec06                	sd	ra,24(sp)
    8000160a:	e822                	sd	s0,16(sp)
    8000160c:	e426                	sd	s1,8(sp)
    8000160e:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t)kalloc();
    80001610:	fffff097          	auipc	ra,0xfffff
    80001614:	6e4080e7          	jalr	1764(ra) # 80000cf4 <kalloc>
    80001618:	84aa                	mv	s1,a0
  if (pagetable == 0)
    8000161a:	c519                	beqz	a0,80001628 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    8000161c:	6605                	lui	a2,0x1
    8000161e:	4581                	li	a1,0
    80001620:	00000097          	auipc	ra,0x0
    80001624:	988080e7          	jalr	-1656(ra) # 80000fa8 <memset>
  return pagetable;
}
    80001628:	8526                	mv	a0,s1
    8000162a:	60e2                	ld	ra,24(sp)
    8000162c:	6442                	ld	s0,16(sp)
    8000162e:	64a2                	ld	s1,8(sp)
    80001630:	6105                	addi	sp,sp,32
    80001632:	8082                	ret

0000000080001634 <uvmfirst>:

// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void uvmfirst(pagetable_t pagetable, uchar *src, uint sz)
{
    80001634:	7179                	addi	sp,sp,-48
    80001636:	f406                	sd	ra,40(sp)
    80001638:	f022                	sd	s0,32(sp)
    8000163a:	ec26                	sd	s1,24(sp)
    8000163c:	e84a                	sd	s2,16(sp)
    8000163e:	e44e                	sd	s3,8(sp)
    80001640:	e052                	sd	s4,0(sp)
    80001642:	1800                	addi	s0,sp,48
  char *mem;

  if (sz >= PGSIZE)
    80001644:	6785                	lui	a5,0x1
    80001646:	04f67863          	bgeu	a2,a5,80001696 <uvmfirst+0x62>
    8000164a:	8a2a                	mv	s4,a0
    8000164c:	89ae                	mv	s3,a1
    8000164e:	84b2                	mv	s1,a2
    panic("uvmfirst: more than a page");
  mem = kalloc();
    80001650:	fffff097          	auipc	ra,0xfffff
    80001654:	6a4080e7          	jalr	1700(ra) # 80000cf4 <kalloc>
    80001658:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    8000165a:	6605                	lui	a2,0x1
    8000165c:	4581                	li	a1,0
    8000165e:	00000097          	auipc	ra,0x0
    80001662:	94a080e7          	jalr	-1718(ra) # 80000fa8 <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W | PTE_R | PTE_X | PTE_U);
    80001666:	4779                	li	a4,30
    80001668:	86ca                	mv	a3,s2
    8000166a:	6605                	lui	a2,0x1
    8000166c:	4581                	li	a1,0
    8000166e:	8552                	mv	a0,s4
    80001670:	00000097          	auipc	ra,0x0
    80001674:	d0c080e7          	jalr	-756(ra) # 8000137c <mappages>
  memmove(mem, src, sz);
    80001678:	8626                	mv	a2,s1
    8000167a:	85ce                	mv	a1,s3
    8000167c:	854a                	mv	a0,s2
    8000167e:	00000097          	auipc	ra,0x0
    80001682:	98a080e7          	jalr	-1654(ra) # 80001008 <memmove>
}
    80001686:	70a2                	ld	ra,40(sp)
    80001688:	7402                	ld	s0,32(sp)
    8000168a:	64e2                	ld	s1,24(sp)
    8000168c:	6942                	ld	s2,16(sp)
    8000168e:	69a2                	ld	s3,8(sp)
    80001690:	6a02                	ld	s4,0(sp)
    80001692:	6145                	addi	sp,sp,48
    80001694:	8082                	ret
    panic("uvmfirst: more than a page");
    80001696:	00007517          	auipc	a0,0x7
    8000169a:	afa50513          	addi	a0,a0,-1286 # 80008190 <digits+0x150>
    8000169e:	fffff097          	auipc	ra,0xfffff
    800016a2:	ea6080e7          	jalr	-346(ra) # 80000544 <panic>

00000000800016a6 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    800016a6:	1101                	addi	sp,sp,-32
    800016a8:	ec06                	sd	ra,24(sp)
    800016aa:	e822                	sd	s0,16(sp)
    800016ac:	e426                	sd	s1,8(sp)
    800016ae:	1000                	addi	s0,sp,32
  if (newsz >= oldsz)
    return oldsz;
    800016b0:	84ae                	mv	s1,a1
  if (newsz >= oldsz)
    800016b2:	00b67d63          	bgeu	a2,a1,800016cc <uvmdealloc+0x26>
    800016b6:	84b2                	mv	s1,a2

  if (PGROUNDUP(newsz) < PGROUNDUP(oldsz))
    800016b8:	6785                	lui	a5,0x1
    800016ba:	17fd                	addi	a5,a5,-1
    800016bc:	00f60733          	add	a4,a2,a5
    800016c0:	767d                	lui	a2,0xfffff
    800016c2:	8f71                	and	a4,a4,a2
    800016c4:	97ae                	add	a5,a5,a1
    800016c6:	8ff1                	and	a5,a5,a2
    800016c8:	00f76863          	bltu	a4,a5,800016d8 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    800016cc:	8526                	mv	a0,s1
    800016ce:	60e2                	ld	ra,24(sp)
    800016d0:	6442                	ld	s0,16(sp)
    800016d2:	64a2                	ld	s1,8(sp)
    800016d4:	6105                	addi	sp,sp,32
    800016d6:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    800016d8:	8f99                	sub	a5,a5,a4
    800016da:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    800016dc:	4685                	li	a3,1
    800016de:	0007861b          	sext.w	a2,a5
    800016e2:	85ba                	mv	a1,a4
    800016e4:	00000097          	auipc	ra,0x0
    800016e8:	e5e080e7          	jalr	-418(ra) # 80001542 <uvmunmap>
    800016ec:	b7c5                	j	800016cc <uvmdealloc+0x26>

00000000800016ee <uvmalloc>:
  if (newsz < oldsz)
    800016ee:	0ab66563          	bltu	a2,a1,80001798 <uvmalloc+0xaa>
{
    800016f2:	7139                	addi	sp,sp,-64
    800016f4:	fc06                	sd	ra,56(sp)
    800016f6:	f822                	sd	s0,48(sp)
    800016f8:	f426                	sd	s1,40(sp)
    800016fa:	f04a                	sd	s2,32(sp)
    800016fc:	ec4e                	sd	s3,24(sp)
    800016fe:	e852                	sd	s4,16(sp)
    80001700:	e456                	sd	s5,8(sp)
    80001702:	e05a                	sd	s6,0(sp)
    80001704:	0080                	addi	s0,sp,64
    80001706:	8aaa                	mv	s5,a0
    80001708:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    8000170a:	6985                	lui	s3,0x1
    8000170c:	19fd                	addi	s3,s3,-1
    8000170e:	95ce                	add	a1,a1,s3
    80001710:	79fd                	lui	s3,0xfffff
    80001712:	0135f9b3          	and	s3,a1,s3
  for (a = oldsz; a < newsz; a += PGSIZE)
    80001716:	08c9f363          	bgeu	s3,a2,8000179c <uvmalloc+0xae>
    8000171a:	894e                	mv	s2,s3
    if (mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R | PTE_U | xperm) != 0)
    8000171c:	0126eb13          	ori	s6,a3,18
    mem = kalloc();
    80001720:	fffff097          	auipc	ra,0xfffff
    80001724:	5d4080e7          	jalr	1492(ra) # 80000cf4 <kalloc>
    80001728:	84aa                	mv	s1,a0
    if (mem == 0)
    8000172a:	c51d                	beqz	a0,80001758 <uvmalloc+0x6a>
    memset(mem, 0, PGSIZE);
    8000172c:	6605                	lui	a2,0x1
    8000172e:	4581                	li	a1,0
    80001730:	00000097          	auipc	ra,0x0
    80001734:	878080e7          	jalr	-1928(ra) # 80000fa8 <memset>
    if (mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_R | PTE_U | xperm) != 0)
    80001738:	875a                	mv	a4,s6
    8000173a:	86a6                	mv	a3,s1
    8000173c:	6605                	lui	a2,0x1
    8000173e:	85ca                	mv	a1,s2
    80001740:	8556                	mv	a0,s5
    80001742:	00000097          	auipc	ra,0x0
    80001746:	c3a080e7          	jalr	-966(ra) # 8000137c <mappages>
    8000174a:	e90d                	bnez	a0,8000177c <uvmalloc+0x8e>
  for (a = oldsz; a < newsz; a += PGSIZE)
    8000174c:	6785                	lui	a5,0x1
    8000174e:	993e                	add	s2,s2,a5
    80001750:	fd4968e3          	bltu	s2,s4,80001720 <uvmalloc+0x32>
  return newsz;
    80001754:	8552                	mv	a0,s4
    80001756:	a809                	j	80001768 <uvmalloc+0x7a>
      uvmdealloc(pagetable, a, oldsz);
    80001758:	864e                	mv	a2,s3
    8000175a:	85ca                	mv	a1,s2
    8000175c:	8556                	mv	a0,s5
    8000175e:	00000097          	auipc	ra,0x0
    80001762:	f48080e7          	jalr	-184(ra) # 800016a6 <uvmdealloc>
      return 0;
    80001766:	4501                	li	a0,0
}
    80001768:	70e2                	ld	ra,56(sp)
    8000176a:	7442                	ld	s0,48(sp)
    8000176c:	74a2                	ld	s1,40(sp)
    8000176e:	7902                	ld	s2,32(sp)
    80001770:	69e2                	ld	s3,24(sp)
    80001772:	6a42                	ld	s4,16(sp)
    80001774:	6aa2                	ld	s5,8(sp)
    80001776:	6b02                	ld	s6,0(sp)
    80001778:	6121                	addi	sp,sp,64
    8000177a:	8082                	ret
      kfree(mem);
    8000177c:	8526                	mv	a0,s1
    8000177e:	fffff097          	auipc	ra,0xfffff
    80001782:	418080e7          	jalr	1048(ra) # 80000b96 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    80001786:	864e                	mv	a2,s3
    80001788:	85ca                	mv	a1,s2
    8000178a:	8556                	mv	a0,s5
    8000178c:	00000097          	auipc	ra,0x0
    80001790:	f1a080e7          	jalr	-230(ra) # 800016a6 <uvmdealloc>
      return 0;
    80001794:	4501                	li	a0,0
    80001796:	bfc9                	j	80001768 <uvmalloc+0x7a>
    return oldsz;
    80001798:	852e                	mv	a0,a1
}
    8000179a:	8082                	ret
  return newsz;
    8000179c:	8532                	mv	a0,a2
    8000179e:	b7e9                	j	80001768 <uvmalloc+0x7a>

00000000800017a0 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void freewalk(pagetable_t pagetable)
{
    800017a0:	7179                	addi	sp,sp,-48
    800017a2:	f406                	sd	ra,40(sp)
    800017a4:	f022                	sd	s0,32(sp)
    800017a6:	ec26                	sd	s1,24(sp)
    800017a8:	e84a                	sd	s2,16(sp)
    800017aa:	e44e                	sd	s3,8(sp)
    800017ac:	e052                	sd	s4,0(sp)
    800017ae:	1800                	addi	s0,sp,48
    800017b0:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for (int i = 0; i < 512; i++)
    800017b2:	84aa                	mv	s1,a0
    800017b4:	6905                	lui	s2,0x1
    800017b6:	992a                	add	s2,s2,a0
  {
    pte_t pte = pagetable[i];
    if ((pte & PTE_V) && (pte & (PTE_R | PTE_W | PTE_X)) == 0)
    800017b8:	4985                	li	s3,1
    800017ba:	a821                	j	800017d2 <freewalk+0x32>
    {
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    800017bc:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    800017be:	0532                	slli	a0,a0,0xc
    800017c0:	00000097          	auipc	ra,0x0
    800017c4:	fe0080e7          	jalr	-32(ra) # 800017a0 <freewalk>
      pagetable[i] = 0;
    800017c8:	0004b023          	sd	zero,0(s1)
  for (int i = 0; i < 512; i++)
    800017cc:	04a1                	addi	s1,s1,8
    800017ce:	03248163          	beq	s1,s2,800017f0 <freewalk+0x50>
    pte_t pte = pagetable[i];
    800017d2:	6088                	ld	a0,0(s1)
    if ((pte & PTE_V) && (pte & (PTE_R | PTE_W | PTE_X)) == 0)
    800017d4:	00f57793          	andi	a5,a0,15
    800017d8:	ff3782e3          	beq	a5,s3,800017bc <freewalk+0x1c>
    }
    else if (pte & PTE_V)
    800017dc:	8905                	andi	a0,a0,1
    800017de:	d57d                	beqz	a0,800017cc <freewalk+0x2c>
    {
      panic("freewalk: leaf");
    800017e0:	00007517          	auipc	a0,0x7
    800017e4:	9d050513          	addi	a0,a0,-1584 # 800081b0 <digits+0x170>
    800017e8:	fffff097          	auipc	ra,0xfffff
    800017ec:	d5c080e7          	jalr	-676(ra) # 80000544 <panic>
    }
  }
  kfree((void *)pagetable);
    800017f0:	8552                	mv	a0,s4
    800017f2:	fffff097          	auipc	ra,0xfffff
    800017f6:	3a4080e7          	jalr	932(ra) # 80000b96 <kfree>
}
    800017fa:	70a2                	ld	ra,40(sp)
    800017fc:	7402                	ld	s0,32(sp)
    800017fe:	64e2                	ld	s1,24(sp)
    80001800:	6942                	ld	s2,16(sp)
    80001802:	69a2                	ld	s3,8(sp)
    80001804:	6a02                	ld	s4,0(sp)
    80001806:	6145                	addi	sp,sp,48
    80001808:	8082                	ret

000000008000180a <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void uvmfree(pagetable_t pagetable, uint64 sz)
{
    8000180a:	1101                	addi	sp,sp,-32
    8000180c:	ec06                	sd	ra,24(sp)
    8000180e:	e822                	sd	s0,16(sp)
    80001810:	e426                	sd	s1,8(sp)
    80001812:	1000                	addi	s0,sp,32
    80001814:	84aa                	mv	s1,a0
  if (sz > 0)
    80001816:	e999                	bnez	a1,8000182c <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz) / PGSIZE, 1);
  freewalk(pagetable);
    80001818:	8526                	mv	a0,s1
    8000181a:	00000097          	auipc	ra,0x0
    8000181e:	f86080e7          	jalr	-122(ra) # 800017a0 <freewalk>
}
    80001822:	60e2                	ld	ra,24(sp)
    80001824:	6442                	ld	s0,16(sp)
    80001826:	64a2                	ld	s1,8(sp)
    80001828:	6105                	addi	sp,sp,32
    8000182a:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz) / PGSIZE, 1);
    8000182c:	6605                	lui	a2,0x1
    8000182e:	167d                	addi	a2,a2,-1
    80001830:	962e                	add	a2,a2,a1
    80001832:	4685                	li	a3,1
    80001834:	8231                	srli	a2,a2,0xc
    80001836:	4581                	li	a1,0
    80001838:	00000097          	auipc	ra,0x0
    8000183c:	d0a080e7          	jalr	-758(ra) # 80001542 <uvmunmap>
    80001840:	bfe1                	j	80001818 <uvmfree+0xe>

0000000080001842 <uvmcopy>:
  uint flags;
  // char *mem;

  int ok=1;

  for (i = 0; i < sz; i += PGSIZE)
    80001842:	ca69                	beqz	a2,80001914 <uvmcopy+0xd2>
{
    80001844:	7139                	addi	sp,sp,-64
    80001846:	fc06                	sd	ra,56(sp)
    80001848:	f822                	sd	s0,48(sp)
    8000184a:	f426                	sd	s1,40(sp)
    8000184c:	f04a                	sd	s2,32(sp)
    8000184e:	ec4e                	sd	s3,24(sp)
    80001850:	e852                	sd	s4,16(sp)
    80001852:	e456                	sd	s5,8(sp)
    80001854:	e05a                	sd	s6,0(sp)
    80001856:	0080                	addi	s0,sp,64
    80001858:	8aaa                	mv	s5,a0
    8000185a:	8a2e                	mv	s4,a1
    8000185c:	89b2                	mv	s3,a2
  for (i = 0; i < sz; i += PGSIZE)
    8000185e:	4481                	li	s1,0
    pa = PTE2PA(*pte);

    if (flags & PTE_W)
    {
      flags = (flags & (~PTE_W)) | PTE_C;
      *pte = PA2PTE(pa) | flags;
    80001860:	7b7d                	lui	s6,0xfffff
    80001862:	002b5b13          	srli	s6,s6,0x2
    80001866:	a099                	j	800018ac <uvmcopy+0x6a>
      panic("uvmcopy: pte should exist");
    80001868:	00007517          	auipc	a0,0x7
    8000186c:	95850513          	addi	a0,a0,-1704 # 800081c0 <digits+0x180>
    80001870:	fffff097          	auipc	ra,0xfffff
    80001874:	cd4080e7          	jalr	-812(ra) # 80000544 <panic>
      panic("uvmcopy: page not present");
    80001878:	00007517          	auipc	a0,0x7
    8000187c:	96850513          	addi	a0,a0,-1688 # 800081e0 <digits+0x1a0>
    80001880:	fffff097          	auipc	ra,0xfffff
    80001884:	cc4080e7          	jalr	-828(ra) # 80000544 <panic>
    }
    if (mappages(new, i, PGSIZE, pa, flags) != 0)
    80001888:	86ca                	mv	a3,s2
    8000188a:	6605                	lui	a2,0x1
    8000188c:	85a6                	mv	a1,s1
    8000188e:	8552                	mv	a0,s4
    80001890:	00000097          	auipc	ra,0x0
    80001894:	aec080e7          	jalr	-1300(ra) # 8000137c <mappages>
    80001898:	e921                	bnez	a0,800018e8 <uvmcopy+0xa6>
    {
      ok=0;
      break;
    }
    inc_page_ref((void*)pa);
    8000189a:	854a                	mv	a0,s2
    8000189c:	fffff097          	auipc	ra,0xfffff
    800018a0:	230080e7          	jalr	560(ra) # 80000acc <inc_page_ref>
  for (i = 0; i < sz; i += PGSIZE)
    800018a4:	6785                	lui	a5,0x1
    800018a6:	94be                	add	s1,s1,a5
    800018a8:	0534fb63          	bgeu	s1,s3,800018fe <uvmcopy+0xbc>
    if ((pte = walk(old, i, 0)) == 0)
    800018ac:	4601                	li	a2,0
    800018ae:	85a6                	mv	a1,s1
    800018b0:	8556                	mv	a0,s5
    800018b2:	00000097          	auipc	ra,0x0
    800018b6:	9e2080e7          	jalr	-1566(ra) # 80001294 <walk>
    800018ba:	d55d                	beqz	a0,80001868 <uvmcopy+0x26>
    if ((*pte & PTE_V) == 0)
    800018bc:	611c                	ld	a5,0(a0)
    800018be:	0017f713          	andi	a4,a5,1
    800018c2:	db5d                	beqz	a4,80001878 <uvmcopy+0x36>
    flags = PTE_FLAGS(*pte);
    800018c4:	0007869b          	sext.w	a3,a5
    800018c8:	3ff7f713          	andi	a4,a5,1023
    pa = PTE2PA(*pte);
    800018cc:	00a7d913          	srli	s2,a5,0xa
    800018d0:	0932                	slli	s2,s2,0xc
    if (flags & PTE_W)
    800018d2:	8a91                	andi	a3,a3,4
    800018d4:	dad5                	beqz	a3,80001888 <uvmcopy+0x46>
      flags = (flags & (~PTE_W)) | PTE_C;
    800018d6:	fdb77693          	andi	a3,a4,-37
    800018da:	0206e713          	ori	a4,a3,32
      *pte = PA2PTE(pa) | flags;
    800018de:	0167f7b3          	and	a5,a5,s6
    800018e2:	8fd9                	or	a5,a5,a4
    800018e4:	e11c                	sd	a5,0(a0)
    800018e6:	b74d                	j	80001888 <uvmcopy+0x46>
  }
  if(ok)
  return 0;

  uvmunmap(new, 0, i / PGSIZE, 1);
    800018e8:	4685                	li	a3,1
    800018ea:	00c4d613          	srli	a2,s1,0xc
    800018ee:	4581                	li	a1,0
    800018f0:	8552                	mv	a0,s4
    800018f2:	00000097          	auipc	ra,0x0
    800018f6:	c50080e7          	jalr	-944(ra) # 80001542 <uvmunmap>
  return -1;
    800018fa:	557d                	li	a0,-1
    800018fc:	a011                	j	80001900 <uvmcopy+0xbe>
  return 0;
    800018fe:	4501                	li	a0,0
}
    80001900:	70e2                	ld	ra,56(sp)
    80001902:	7442                	ld	s0,48(sp)
    80001904:	74a2                	ld	s1,40(sp)
    80001906:	7902                	ld	s2,32(sp)
    80001908:	69e2                	ld	s3,24(sp)
    8000190a:	6a42                	ld	s4,16(sp)
    8000190c:	6aa2                	ld	s5,8(sp)
    8000190e:	6b02                	ld	s6,0(sp)
    80001910:	6121                	addi	sp,sp,64
    80001912:	8082                	ret
  return 0;
    80001914:	4501                	li	a0,0
}
    80001916:	8082                	ret

0000000080001918 <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void uvmclear(pagetable_t pagetable, uint64 va)
{
    80001918:	1141                	addi	sp,sp,-16
    8000191a:	e406                	sd	ra,8(sp)
    8000191c:	e022                	sd	s0,0(sp)
    8000191e:	0800                	addi	s0,sp,16
  pte_t *pte;

  pte = walk(pagetable, va, 0);
    80001920:	4601                	li	a2,0
    80001922:	00000097          	auipc	ra,0x0
    80001926:	972080e7          	jalr	-1678(ra) # 80001294 <walk>
  if (pte == 0)
    8000192a:	c901                	beqz	a0,8000193a <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    8000192c:	611c                	ld	a5,0(a0)
    8000192e:	9bbd                	andi	a5,a5,-17
    80001930:	e11c                	sd	a5,0(a0)
}
    80001932:	60a2                	ld	ra,8(sp)
    80001934:	6402                	ld	s0,0(sp)
    80001936:	0141                	addi	sp,sp,16
    80001938:	8082                	ret
    panic("uvmclear");
    8000193a:	00007517          	auipc	a0,0x7
    8000193e:	8c650513          	addi	a0,a0,-1850 # 80008200 <digits+0x1c0>
    80001942:	fffff097          	auipc	ra,0xfffff
    80001946:	c02080e7          	jalr	-1022(ra) # 80000544 <panic>

000000008000194a <copyout>:

int copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0, flags;
  pte_t *pte;
  while (len > 0)
    8000194a:	c2d5                	beqz	a3,800019ee <copyout+0xa4>
{
    8000194c:	711d                	addi	sp,sp,-96
    8000194e:	ec86                	sd	ra,88(sp)
    80001950:	e8a2                	sd	s0,80(sp)
    80001952:	e4a6                	sd	s1,72(sp)
    80001954:	e0ca                	sd	s2,64(sp)
    80001956:	fc4e                	sd	s3,56(sp)
    80001958:	f852                	sd	s4,48(sp)
    8000195a:	f456                	sd	s5,40(sp)
    8000195c:	f05a                	sd	s6,32(sp)
    8000195e:	ec5e                	sd	s7,24(sp)
    80001960:	e862                	sd	s8,16(sp)
    80001962:	e466                	sd	s9,8(sp)
    80001964:	1080                	addi	s0,sp,96
    80001966:	8baa                	mv	s7,a0
    80001968:	89ae                	mv	s3,a1
    8000196a:	8b32                	mv	s6,a2
    8000196c:	8ab6                	mv	s5,a3
  {
    va0 = PGROUNDDOWN(dstva);
    8000196e:	7cfd                	lui	s9,0xfffff
    if (flags & PTE_C)
    {
      page_fault_handler((void *)va0, pagetable);
      pa0 = walkaddr(pagetable, va0);
    }
    n = PGSIZE - (dstva - va0);
    80001970:	6c05                	lui	s8,0x1
    80001972:	a081                	j	800019b2 <copyout+0x68>
      page_fault_handler((void *)va0, pagetable);
    80001974:	85de                	mv	a1,s7
    80001976:	854a                	mv	a0,s2
    80001978:	fffff097          	auipc	ra,0xfffff
    8000197c:	3e6080e7          	jalr	998(ra) # 80000d5e <page_fault_handler>
      pa0 = walkaddr(pagetable, va0);
    80001980:	85ca                	mv	a1,s2
    80001982:	855e                	mv	a0,s7
    80001984:	00000097          	auipc	ra,0x0
    80001988:	9b6080e7          	jalr	-1610(ra) # 8000133a <walkaddr>
    8000198c:	8a2a                	mv	s4,a0
    8000198e:	a0b9                	j	800019dc <copyout+0x92>
    if (n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001990:	41298533          	sub	a0,s3,s2
    80001994:	0004861b          	sext.w	a2,s1
    80001998:	85da                	mv	a1,s6
    8000199a:	9552                	add	a0,a0,s4
    8000199c:	fffff097          	auipc	ra,0xfffff
    800019a0:	66c080e7          	jalr	1644(ra) # 80001008 <memmove>

    len -= n;
    800019a4:	409a8ab3          	sub	s5,s5,s1
    src += n;
    800019a8:	9b26                	add	s6,s6,s1
    dstva = va0 + PGSIZE;
    800019aa:	018909b3          	add	s3,s2,s8
  while (len > 0)
    800019ae:	020a8e63          	beqz	s5,800019ea <copyout+0xa0>
    va0 = PGROUNDDOWN(dstva);
    800019b2:	0199f933          	and	s2,s3,s9
    pa0 = walkaddr(pagetable, va0);
    800019b6:	85ca                	mv	a1,s2
    800019b8:	855e                	mv	a0,s7
    800019ba:	00000097          	auipc	ra,0x0
    800019be:	980080e7          	jalr	-1664(ra) # 8000133a <walkaddr>
    800019c2:	8a2a                	mv	s4,a0
    if (pa0 == 0)
    800019c4:	c51d                	beqz	a0,800019f2 <copyout+0xa8>
    pte = walk(pagetable, va0, 0);
    800019c6:	4601                	li	a2,0
    800019c8:	85ca                	mv	a1,s2
    800019ca:	855e                	mv	a0,s7
    800019cc:	00000097          	auipc	ra,0x0
    800019d0:	8c8080e7          	jalr	-1848(ra) # 80001294 <walk>
    if (flags & PTE_C)
    800019d4:	611c                	ld	a5,0(a0)
    800019d6:	0207f793          	andi	a5,a5,32
    800019da:	ffc9                	bnez	a5,80001974 <copyout+0x2a>
    n = PGSIZE - (dstva - va0);
    800019dc:	413904b3          	sub	s1,s2,s3
    800019e0:	94e2                	add	s1,s1,s8
    if (n > len)
    800019e2:	fa9af7e3          	bgeu	s5,s1,80001990 <copyout+0x46>
    800019e6:	84d6                	mv	s1,s5
    800019e8:	b765                	j	80001990 <copyout+0x46>
  }
  return 0;
    800019ea:	4501                	li	a0,0
    800019ec:	a021                	j	800019f4 <copyout+0xaa>
    800019ee:	4501                	li	a0,0
}
    800019f0:	8082                	ret
      return -1;
    800019f2:	557d                	li	a0,-1
}
    800019f4:	60e6                	ld	ra,88(sp)
    800019f6:	6446                	ld	s0,80(sp)
    800019f8:	64a6                	ld	s1,72(sp)
    800019fa:	6906                	ld	s2,64(sp)
    800019fc:	79e2                	ld	s3,56(sp)
    800019fe:	7a42                	ld	s4,48(sp)
    80001a00:	7aa2                	ld	s5,40(sp)
    80001a02:	7b02                	ld	s6,32(sp)
    80001a04:	6be2                	ld	s7,24(sp)
    80001a06:	6c42                	ld	s8,16(sp)
    80001a08:	6ca2                	ld	s9,8(sp)
    80001a0a:	6125                	addi	sp,sp,96
    80001a0c:	8082                	ret

0000000080001a0e <copyin>:
// Return 0 on success, -1 on error.
int copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while (len > 0)
    80001a0e:	c6bd                	beqz	a3,80001a7c <copyin+0x6e>
{
    80001a10:	715d                	addi	sp,sp,-80
    80001a12:	e486                	sd	ra,72(sp)
    80001a14:	e0a2                	sd	s0,64(sp)
    80001a16:	fc26                	sd	s1,56(sp)
    80001a18:	f84a                	sd	s2,48(sp)
    80001a1a:	f44e                	sd	s3,40(sp)
    80001a1c:	f052                	sd	s4,32(sp)
    80001a1e:	ec56                	sd	s5,24(sp)
    80001a20:	e85a                	sd	s6,16(sp)
    80001a22:	e45e                	sd	s7,8(sp)
    80001a24:	e062                	sd	s8,0(sp)
    80001a26:	0880                	addi	s0,sp,80
    80001a28:	8b2a                	mv	s6,a0
    80001a2a:	8a2e                	mv	s4,a1
    80001a2c:	8c32                	mv	s8,a2
    80001a2e:	89b6                	mv	s3,a3
  {
    va0 = PGROUNDDOWN(srcva);
    80001a30:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if (pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001a32:	6a85                	lui	s5,0x1
    80001a34:	a015                	j	80001a58 <copyin+0x4a>
    if (n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001a36:	9562                	add	a0,a0,s8
    80001a38:	0004861b          	sext.w	a2,s1
    80001a3c:	412505b3          	sub	a1,a0,s2
    80001a40:	8552                	mv	a0,s4
    80001a42:	fffff097          	auipc	ra,0xfffff
    80001a46:	5c6080e7          	jalr	1478(ra) # 80001008 <memmove>

    len -= n;
    80001a4a:	409989b3          	sub	s3,s3,s1
    dst += n;
    80001a4e:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    80001a50:	01590c33          	add	s8,s2,s5
  while (len > 0)
    80001a54:	02098263          	beqz	s3,80001a78 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    80001a58:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    80001a5c:	85ca                	mv	a1,s2
    80001a5e:	855a                	mv	a0,s6
    80001a60:	00000097          	auipc	ra,0x0
    80001a64:	8da080e7          	jalr	-1830(ra) # 8000133a <walkaddr>
    if (pa0 == 0)
    80001a68:	cd01                	beqz	a0,80001a80 <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    80001a6a:	418904b3          	sub	s1,s2,s8
    80001a6e:	94d6                	add	s1,s1,s5
    if (n > len)
    80001a70:	fc99f3e3          	bgeu	s3,s1,80001a36 <copyin+0x28>
    80001a74:	84ce                	mv	s1,s3
    80001a76:	b7c1                	j	80001a36 <copyin+0x28>
  }
  return 0;
    80001a78:	4501                	li	a0,0
    80001a7a:	a021                	j	80001a82 <copyin+0x74>
    80001a7c:	4501                	li	a0,0
}
    80001a7e:	8082                	ret
      return -1;
    80001a80:	557d                	li	a0,-1
}
    80001a82:	60a6                	ld	ra,72(sp)
    80001a84:	6406                	ld	s0,64(sp)
    80001a86:	74e2                	ld	s1,56(sp)
    80001a88:	7942                	ld	s2,48(sp)
    80001a8a:	79a2                	ld	s3,40(sp)
    80001a8c:	7a02                	ld	s4,32(sp)
    80001a8e:	6ae2                	ld	s5,24(sp)
    80001a90:	6b42                	ld	s6,16(sp)
    80001a92:	6ba2                	ld	s7,8(sp)
    80001a94:	6c02                	ld	s8,0(sp)
    80001a96:	6161                	addi	sp,sp,80
    80001a98:	8082                	ret

0000000080001a9a <copyinstr>:
int copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while (got_null == 0 && max > 0)
    80001a9a:	c6c5                	beqz	a3,80001b42 <copyinstr+0xa8>
{
    80001a9c:	715d                	addi	sp,sp,-80
    80001a9e:	e486                	sd	ra,72(sp)
    80001aa0:	e0a2                	sd	s0,64(sp)
    80001aa2:	fc26                	sd	s1,56(sp)
    80001aa4:	f84a                	sd	s2,48(sp)
    80001aa6:	f44e                	sd	s3,40(sp)
    80001aa8:	f052                	sd	s4,32(sp)
    80001aaa:	ec56                	sd	s5,24(sp)
    80001aac:	e85a                	sd	s6,16(sp)
    80001aae:	e45e                	sd	s7,8(sp)
    80001ab0:	0880                	addi	s0,sp,80
    80001ab2:	8a2a                	mv	s4,a0
    80001ab4:	8b2e                	mv	s6,a1
    80001ab6:	8bb2                	mv	s7,a2
    80001ab8:	84b6                	mv	s1,a3
  {
    va0 = PGROUNDDOWN(srcva);
    80001aba:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if (pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001abc:	6985                	lui	s3,0x1
    80001abe:	a035                	j	80001aea <copyinstr+0x50>
    char *p = (char *)(pa0 + (srcva - va0));
    while (n > 0)
    {
      if (*p == '\0')
      {
        *dst = '\0';
    80001ac0:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001ac4:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if (got_null)
    80001ac6:	0017b793          	seqz	a5,a5
    80001aca:	40f00533          	neg	a0,a5
  }
  else
  {
    return -1;
  }
}
    80001ace:	60a6                	ld	ra,72(sp)
    80001ad0:	6406                	ld	s0,64(sp)
    80001ad2:	74e2                	ld	s1,56(sp)
    80001ad4:	7942                	ld	s2,48(sp)
    80001ad6:	79a2                	ld	s3,40(sp)
    80001ad8:	7a02                	ld	s4,32(sp)
    80001ada:	6ae2                	ld	s5,24(sp)
    80001adc:	6b42                	ld	s6,16(sp)
    80001ade:	6ba2                	ld	s7,8(sp)
    80001ae0:	6161                	addi	sp,sp,80
    80001ae2:	8082                	ret
    srcva = va0 + PGSIZE;
    80001ae4:	01390bb3          	add	s7,s2,s3
  while (got_null == 0 && max > 0)
    80001ae8:	c8a9                	beqz	s1,80001b3a <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    80001aea:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001aee:	85ca                	mv	a1,s2
    80001af0:	8552                	mv	a0,s4
    80001af2:	00000097          	auipc	ra,0x0
    80001af6:	848080e7          	jalr	-1976(ra) # 8000133a <walkaddr>
    if (pa0 == 0)
    80001afa:	c131                	beqz	a0,80001b3e <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    80001afc:	41790833          	sub	a6,s2,s7
    80001b00:	984e                	add	a6,a6,s3
    if (n > max)
    80001b02:	0104f363          	bgeu	s1,a6,80001b08 <copyinstr+0x6e>
    80001b06:	8826                	mv	a6,s1
    char *p = (char *)(pa0 + (srcva - va0));
    80001b08:	955e                	add	a0,a0,s7
    80001b0a:	41250533          	sub	a0,a0,s2
    while (n > 0)
    80001b0e:	fc080be3          	beqz	a6,80001ae4 <copyinstr+0x4a>
    80001b12:	985a                	add	a6,a6,s6
    80001b14:	87da                	mv	a5,s6
      if (*p == '\0')
    80001b16:	41650633          	sub	a2,a0,s6
    80001b1a:	14fd                	addi	s1,s1,-1
    80001b1c:	9b26                	add	s6,s6,s1
    80001b1e:	00f60733          	add	a4,a2,a5
    80001b22:	00074703          	lbu	a4,0(a4)
    80001b26:	df49                	beqz	a4,80001ac0 <copyinstr+0x26>
        *dst = *p;
    80001b28:	00e78023          	sb	a4,0(a5)
      --max;
    80001b2c:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001b30:	0785                	addi	a5,a5,1
    while (n > 0)
    80001b32:	ff0796e3          	bne	a5,a6,80001b1e <copyinstr+0x84>
      dst++;
    80001b36:	8b42                	mv	s6,a6
    80001b38:	b775                	j	80001ae4 <copyinstr+0x4a>
    80001b3a:	4781                	li	a5,0
    80001b3c:	b769                	j	80001ac6 <copyinstr+0x2c>
      return -1;
    80001b3e:	557d                	li	a0,-1
    80001b40:	b779                	j	80001ace <copyinstr+0x34>
  int got_null = 0;
    80001b42:	4781                	li	a5,0
  if (got_null)
    80001b44:	0017b793          	seqz	a5,a5
    80001b48:	40f00533          	neg	a0,a5
}
    80001b4c:	8082                	ret

0000000080001b4e <my_max>:
#ifdef MLFQ
struct Queue mlfq[NMLFQ];
#endif

int my_max(int a, int b)
{
    80001b4e:	1141                	addi	sp,sp,-16
    80001b50:	e422                	sd	s0,8(sp)
    80001b52:	0800                	addi	s0,sp,16
  if (a > b)
    80001b54:	87aa                	mv	a5,a0
    80001b56:	00b55363          	bge	a0,a1,80001b5c <my_max+0xe>
    80001b5a:	87ae                	mv	a5,a1
    return a;
  return b;
}
    80001b5c:	0007851b          	sext.w	a0,a5
    80001b60:	6422                	ld	s0,8(sp)
    80001b62:	0141                	addi	sp,sp,16
    80001b64:	8082                	ret

0000000080001b66 <mine_min>:
int mine_min(int a, int b)
{
    80001b66:	1141                	addi	sp,sp,-16
    80001b68:	e422                	sd	s0,8(sp)
    80001b6a:	0800                	addi	s0,sp,16
  if (a < b)
    80001b6c:	87aa                	mv	a5,a0
    80001b6e:	00a5d363          	bge	a1,a0,80001b74 <mine_min+0xe>
    80001b72:	87ae                	mv	a5,a1
    return a;
  return b;
}
    80001b74:	0007851b          	sext.w	a0,a5
    80001b78:	6422                	ld	s0,8(sp)
    80001b7a:	0141                	addi	sp,sp,16
    80001b7c:	8082                	ret

0000000080001b7e <proc_mapstacks>:
//   p->nice_pro1 = n;
//   all_tickets += p->nice_pro1;
// }

void proc_mapstacks(pagetable_t kpgtbl)
{
    80001b7e:	7139                	addi	sp,sp,-64
    80001b80:	fc06                	sd	ra,56(sp)
    80001b82:	f822                	sd	s0,48(sp)
    80001b84:	f426                	sd	s1,40(sp)
    80001b86:	f04a                	sd	s2,32(sp)
    80001b88:	ec4e                	sd	s3,24(sp)
    80001b8a:	e852                	sd	s4,16(sp)
    80001b8c:	e456                	sd	s5,8(sp)
    80001b8e:	e05a                	sd	s6,0(sp)
    80001b90:	0080                	addi	s0,sp,64
    80001b92:	89aa                	mv	s3,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80001b94:	0022f497          	auipc	s1,0x22f
    80001b98:	21448493          	addi	s1,s1,532 # 80230da8 <proc>
  {
    char *pa = kalloc();
    if (pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int)(p - proc));
    80001b9c:	8b26                	mv	s6,s1
    80001b9e:	00006a97          	auipc	s5,0x6
    80001ba2:	462a8a93          	addi	s5,s5,1122 # 80008000 <etext>
    80001ba6:	04000937          	lui	s2,0x4000
    80001baa:	197d                	addi	s2,s2,-1
    80001bac:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001bae:	00236a17          	auipc	s4,0x236
    80001bb2:	5faa0a13          	addi	s4,s4,1530 # 802381a8 <cpus>
    char *pa = kalloc();
    80001bb6:	fffff097          	auipc	ra,0xfffff
    80001bba:	13e080e7          	jalr	318(ra) # 80000cf4 <kalloc>
    80001bbe:	862a                	mv	a2,a0
    if (pa == 0)
    80001bc0:	c131                	beqz	a0,80001c04 <proc_mapstacks+0x86>
    uint64 va = KSTACK((int)(p - proc));
    80001bc2:	416485b3          	sub	a1,s1,s6
    80001bc6:	8591                	srai	a1,a1,0x4
    80001bc8:	000ab783          	ld	a5,0(s5)
    80001bcc:	02f585b3          	mul	a1,a1,a5
    80001bd0:	2585                	addiw	a1,a1,1
    80001bd2:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001bd6:	4719                	li	a4,6
    80001bd8:	6685                	lui	a3,0x1
    80001bda:	40b905b3          	sub	a1,s2,a1
    80001bde:	854e                	mv	a0,s3
    80001be0:	00000097          	auipc	ra,0x0
    80001be4:	83c080e7          	jalr	-1988(ra) # 8000141c <kvmmap>
  for (p = proc; p < &proc[NPROC]; p++)
    80001be8:	1d048493          	addi	s1,s1,464
    80001bec:	fd4495e3          	bne	s1,s4,80001bb6 <proc_mapstacks+0x38>
  }
}
    80001bf0:	70e2                	ld	ra,56(sp)
    80001bf2:	7442                	ld	s0,48(sp)
    80001bf4:	74a2                	ld	s1,40(sp)
    80001bf6:	7902                	ld	s2,32(sp)
    80001bf8:	69e2                	ld	s3,24(sp)
    80001bfa:	6a42                	ld	s4,16(sp)
    80001bfc:	6aa2                	ld	s5,8(sp)
    80001bfe:	6b02                	ld	s6,0(sp)
    80001c00:	6121                	addi	sp,sp,64
    80001c02:	8082                	ret
      panic("kalloc");
    80001c04:	00006517          	auipc	a0,0x6
    80001c08:	60c50513          	addi	a0,a0,1548 # 80008210 <digits+0x1d0>
    80001c0c:	fffff097          	auipc	ra,0xfffff
    80001c10:	938080e7          	jalr	-1736(ra) # 80000544 <panic>

0000000080001c14 <procinit>:

// initialize the proc table.
void procinit(void)
{
    80001c14:	7139                	addi	sp,sp,-64
    80001c16:	fc06                	sd	ra,56(sp)
    80001c18:	f822                	sd	s0,48(sp)
    80001c1a:	f426                	sd	s1,40(sp)
    80001c1c:	f04a                	sd	s2,32(sp)
    80001c1e:	ec4e                	sd	s3,24(sp)
    80001c20:	e852                	sd	s4,16(sp)
    80001c22:	e456                	sd	s5,8(sp)
    80001c24:	e05a                	sd	s6,0(sp)
    80001c26:	0080                	addi	s0,sp,64
  struct proc *p;

  initlock(&pid_lock, "nextpid");
    80001c28:	00006597          	auipc	a1,0x6
    80001c2c:	5f058593          	addi	a1,a1,1520 # 80008218 <digits+0x1d8>
    80001c30:	0022f517          	auipc	a0,0x22f
    80001c34:	14850513          	addi	a0,a0,328 # 80230d78 <pid_lock>
    80001c38:	fffff097          	auipc	ra,0xfffff
    80001c3c:	1e4080e7          	jalr	484(ra) # 80000e1c <initlock>
  initlock(&wait_lock, "wait_lock");
    80001c40:	00006597          	auipc	a1,0x6
    80001c44:	5e058593          	addi	a1,a1,1504 # 80008220 <digits+0x1e0>
    80001c48:	0022f517          	auipc	a0,0x22f
    80001c4c:	14850513          	addi	a0,a0,328 # 80230d90 <wait_lock>
    80001c50:	fffff097          	auipc	ra,0xfffff
    80001c54:	1cc080e7          	jalr	460(ra) # 80000e1c <initlock>
  for (p = proc; p < &proc[NPROC]; p++)
    80001c58:	0022f497          	auipc	s1,0x22f
    80001c5c:	15048493          	addi	s1,s1,336 # 80230da8 <proc>
  {
    initlock(&p->lock, "proc");
    80001c60:	00006b17          	auipc	s6,0x6
    80001c64:	5d0b0b13          	addi	s6,s6,1488 # 80008230 <digits+0x1f0>
    p->state = UNUSED;
    p->kstack = KSTACK((int)(p - proc));
    80001c68:	8aa6                	mv	s5,s1
    80001c6a:	00006a17          	auipc	s4,0x6
    80001c6e:	396a0a13          	addi	s4,s4,918 # 80008000 <etext>
    80001c72:	04000937          	lui	s2,0x4000
    80001c76:	197d                	addi	s2,s2,-1
    80001c78:	0932                	slli	s2,s2,0xc
  for (p = proc; p < &proc[NPROC]; p++)
    80001c7a:	00236997          	auipc	s3,0x236
    80001c7e:	52e98993          	addi	s3,s3,1326 # 802381a8 <cpus>
    initlock(&p->lock, "proc");
    80001c82:	85da                	mv	a1,s6
    80001c84:	8526                	mv	a0,s1
    80001c86:	fffff097          	auipc	ra,0xfffff
    80001c8a:	196080e7          	jalr	406(ra) # 80000e1c <initlock>
    p->state = UNUSED;
    80001c8e:	0004ac23          	sw	zero,24(s1)
    p->kstack = KSTACK((int)(p - proc));
    80001c92:	415487b3          	sub	a5,s1,s5
    80001c96:	8791                	srai	a5,a5,0x4
    80001c98:	000a3703          	ld	a4,0(s4)
    80001c9c:	02e787b3          	mul	a5,a5,a4
    80001ca0:	2785                	addiw	a5,a5,1
    80001ca2:	00d7979b          	slliw	a5,a5,0xd
    80001ca6:	40f907b3          	sub	a5,s2,a5
    80001caa:	e4bc                	sd	a5,72(s1)
  for (p = proc; p < &proc[NPROC]; p++)
    80001cac:	1d048493          	addi	s1,s1,464
    80001cb0:	fd3499e3          	bne	s1,s3,80001c82 <procinit+0x6e>
    mlfq[i].size = 0;
    mlfq[i].head = 0;
    mlfq[i].tail = 0;
  }
#endif
}
    80001cb4:	70e2                	ld	ra,56(sp)
    80001cb6:	7442                	ld	s0,48(sp)
    80001cb8:	74a2                	ld	s1,40(sp)
    80001cba:	7902                	ld	s2,32(sp)
    80001cbc:	69e2                	ld	s3,24(sp)
    80001cbe:	6a42                	ld	s4,16(sp)
    80001cc0:	6aa2                	ld	s5,8(sp)
    80001cc2:	6b02                	ld	s6,0(sp)
    80001cc4:	6121                	addi	sp,sp,64
    80001cc6:	8082                	ret

0000000080001cc8 <cpuid>:

// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int cpuid()
{
    80001cc8:	1141                	addi	sp,sp,-16
    80001cca:	e422                	sd	s0,8(sp)
    80001ccc:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001cce:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001cd0:	2501                	sext.w	a0,a0
    80001cd2:	6422                	ld	s0,8(sp)
    80001cd4:	0141                	addi	sp,sp,16
    80001cd6:	8082                	ret

0000000080001cd8 <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu *
mycpu(void)
{
    80001cd8:	1141                	addi	sp,sp,-16
    80001cda:	e422                	sd	s0,8(sp)
    80001cdc:	0800                	addi	s0,sp,16
    80001cde:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001ce0:	2781                	sext.w	a5,a5
    80001ce2:	15800513          	li	a0,344
    80001ce6:	02a787b3          	mul	a5,a5,a0
  return c;
}
    80001cea:	00236517          	auipc	a0,0x236
    80001cee:	4be50513          	addi	a0,a0,1214 # 802381a8 <cpus>
    80001cf2:	953e                	add	a0,a0,a5
    80001cf4:	6422                	ld	s0,8(sp)
    80001cf6:	0141                	addi	sp,sp,16
    80001cf8:	8082                	ret

0000000080001cfa <myproc>:

// Return the current struct proc *, or zero if none.
struct proc *
myproc(void)
{
    80001cfa:	1101                	addi	sp,sp,-32
    80001cfc:	ec06                	sd	ra,24(sp)
    80001cfe:	e822                	sd	s0,16(sp)
    80001d00:	e426                	sd	s1,8(sp)
    80001d02:	1000                	addi	s0,sp,32
  push_off();
    80001d04:	fffff097          	auipc	ra,0xfffff
    80001d08:	15c080e7          	jalr	348(ra) # 80000e60 <push_off>
    80001d0c:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001d0e:	2781                	sext.w	a5,a5
    80001d10:	15800713          	li	a4,344
    80001d14:	02e787b3          	mul	a5,a5,a4
    80001d18:	00236717          	auipc	a4,0x236
    80001d1c:	49070713          	addi	a4,a4,1168 # 802381a8 <cpus>
    80001d20:	97ba                	add	a5,a5,a4
    80001d22:	6384                	ld	s1,0(a5)
  pop_off();
    80001d24:	fffff097          	auipc	ra,0xfffff
    80001d28:	1dc080e7          	jalr	476(ra) # 80000f00 <pop_off>
  return p;
}
    80001d2c:	8526                	mv	a0,s1
    80001d2e:	60e2                	ld	ra,24(sp)
    80001d30:	6442                	ld	s0,16(sp)
    80001d32:	64a2                	ld	s1,8(sp)
    80001d34:	6105                	addi	sp,sp,32
    80001d36:	8082                	ret

0000000080001d38 <forkret>:
}

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void forkret(void)
{
    80001d38:	1141                	addi	sp,sp,-16
    80001d3a:	e406                	sd	ra,8(sp)
    80001d3c:	e022                	sd	s0,0(sp)
    80001d3e:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001d40:	00000097          	auipc	ra,0x0
    80001d44:	fba080e7          	jalr	-70(ra) # 80001cfa <myproc>
    80001d48:	fffff097          	auipc	ra,0xfffff
    80001d4c:	218080e7          	jalr	536(ra) # 80000f60 <release>

  if (first)
    80001d50:	00007797          	auipc	a5,0x7
    80001d54:	cf07a783          	lw	a5,-784(a5) # 80008a40 <first.1837>
    80001d58:	eb89                	bnez	a5,80001d6a <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001d5a:	00001097          	auipc	ra,0x1
    80001d5e:	136080e7          	jalr	310(ra) # 80002e90 <usertrapret>
}
    80001d62:	60a2                	ld	ra,8(sp)
    80001d64:	6402                	ld	s0,0(sp)
    80001d66:	0141                	addi	sp,sp,16
    80001d68:	8082                	ret
    first = 0;
    80001d6a:	00007797          	auipc	a5,0x7
    80001d6e:	cc07ab23          	sw	zero,-810(a5) # 80008a40 <first.1837>
    fsinit(ROOTDEV);
    80001d72:	4505                	li	a0,1
    80001d74:	00002097          	auipc	ra,0x2
    80001d78:	340080e7          	jalr	832(ra) # 800040b4 <fsinit>
    80001d7c:	bff9                	j	80001d5a <forkret+0x22>

0000000080001d7e <allocpid>:
{
    80001d7e:	1101                	addi	sp,sp,-32
    80001d80:	ec06                	sd	ra,24(sp)
    80001d82:	e822                	sd	s0,16(sp)
    80001d84:	e426                	sd	s1,8(sp)
    80001d86:	e04a                	sd	s2,0(sp)
    80001d88:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001d8a:	0022f917          	auipc	s2,0x22f
    80001d8e:	fee90913          	addi	s2,s2,-18 # 80230d78 <pid_lock>
    80001d92:	854a                	mv	a0,s2
    80001d94:	fffff097          	auipc	ra,0xfffff
    80001d98:	118080e7          	jalr	280(ra) # 80000eac <acquire>
  pid = nextpid;
    80001d9c:	00007797          	auipc	a5,0x7
    80001da0:	ca878793          	addi	a5,a5,-856 # 80008a44 <nextpid>
    80001da4:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001da6:	0014871b          	addiw	a4,s1,1
    80001daa:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001dac:	854a                	mv	a0,s2
    80001dae:	fffff097          	auipc	ra,0xfffff
    80001db2:	1b2080e7          	jalr	434(ra) # 80000f60 <release>
}
    80001db6:	8526                	mv	a0,s1
    80001db8:	60e2                	ld	ra,24(sp)
    80001dba:	6442                	ld	s0,16(sp)
    80001dbc:	64a2                	ld	s1,8(sp)
    80001dbe:	6902                	ld	s2,0(sp)
    80001dc0:	6105                	addi	sp,sp,32
    80001dc2:	8082                	ret

0000000080001dc4 <proc_priority>:
{
    80001dc4:	1141                	addi	sp,sp,-16
    80001dc6:	e422                	sd	s0,8(sp)
    80001dc8:	0800                	addi	s0,sp,16
  if (process->ticks_last_scheduled != 0) // if the process hasnt been scheduled yet before
    80001dca:	1a852703          	lw	a4,424(a0)
  int nice = 5;
    80001dce:	4795                	li	a5,5
  if (process->ticks_last_scheduled != 0) // if the process hasnt been scheduled yet before
    80001dd0:	c31d                	beqz	a4,80001df6 <proc_priority+0x32>
    if (process->num_run != 0)
    80001dd2:	1a452703          	lw	a4,420(a0)
    80001dd6:	c305                	beqz	a4,80001df6 <proc_priority+0x32>
      int time_diff = process->last_run + process->last_sleep;
    80001dd8:	1b052683          	lw	a3,432(a0)
    80001ddc:	1ac52703          	lw	a4,428(a0)
    80001de0:	9f35                	addw	a4,a4,a3
    80001de2:	0007061b          	sext.w	a2,a4
      if (time_diff != 0)
    80001de6:	ca01                	beqz	a2,80001df6 <proc_priority+0x32>
        nice = ((sleeping) / (time_diff)) * 10;
    80001de8:	02e6c73b          	divw	a4,a3,a4
    80001dec:	0027179b          	slliw	a5,a4,0x2
    80001df0:	9fb9                	addw	a5,a5,a4
    80001df2:	0017979b          	slliw	a5,a5,0x1
  if (mine_min(process->priority - nice + 5, 1001) > 0)
    80001df6:	1a052503          	lw	a0,416(a0)
    80001dfa:	2515                	addiw	a0,a0,5
    80001dfc:	9d1d                	subw	a0,a0,a5
    80001dfe:	0005071b          	sext.w	a4,a0
    80001e02:	06400793          	li	a5,100
    80001e06:	00e7d463          	bge	a5,a4,80001e0e <proc_priority+0x4a>
    80001e0a:	06400513          	li	a0,100
    80001e0e:	0005079b          	sext.w	a5,a0
    80001e12:	fff7c793          	not	a5,a5
    80001e16:	97fd                	srai	a5,a5,0x3f
    80001e18:	8d7d                	and	a0,a0,a5
}
    80001e1a:	2501                	sext.w	a0,a0
    80001e1c:	6422                	ld	s0,8(sp)
    80001e1e:	0141                	addi	sp,sp,16
    80001e20:	8082                	ret

0000000080001e22 <set_priority>:
{
    80001e22:	7179                	addi	sp,sp,-48
    80001e24:	f406                	sd	ra,40(sp)
    80001e26:	f022                	sd	s0,32(sp)
    80001e28:	ec26                	sd	s1,24(sp)
    80001e2a:	e84a                	sd	s2,16(sp)
    80001e2c:	e44e                	sd	s3,8(sp)
    80001e2e:	e052                	sd	s4,0(sp)
    80001e30:	1800                	addi	s0,sp,48
  if (new_static_priority < 0)
    80001e32:	04054c63          	bltz	a0,80001e8a <set_priority+0x68>
    80001e36:	8a2a                	mv	s4,a0
    80001e38:	892e                	mv	s2,a1
  if (new_static_priority > 100)
    80001e3a:	06400793          	li	a5,100
  p = proc;
    80001e3e:	0022f497          	auipc	s1,0x22f
    80001e42:	f6a48493          	addi	s1,s1,-150 # 80230da8 <proc>
  while (p < &proc[NPROC])
    80001e46:	00236997          	auipc	s3,0x236
    80001e4a:	36298993          	addi	s3,s3,866 # 802381a8 <cpus>
  if (new_static_priority > 100)
    80001e4e:	04a7c863          	blt	a5,a0,80001e9e <set_priority+0x7c>
    acquire(&p->lock);
    80001e52:	8526                	mv	a0,s1
    80001e54:	fffff097          	auipc	ra,0xfffff
    80001e58:	058080e7          	jalr	88(ra) # 80000eac <acquire>
    if (p->pid == proc_pid)
    80001e5c:	589c                	lw	a5,48(s1)
    80001e5e:	05278a63          	beq	a5,s2,80001eb2 <set_priority+0x90>
    release(&p->lock);
    80001e62:	8526                	mv	a0,s1
    80001e64:	fffff097          	auipc	ra,0xfffff
    80001e68:	0fc080e7          	jalr	252(ra) # 80000f60 <release>
    p++;
    80001e6c:	1d048493          	addi	s1,s1,464
  while (p < &proc[NPROC])
    80001e70:	ff3491e3          	bne	s1,s3,80001e52 <set_priority+0x30>
    printf("no process with pid : %d exists\n", proc_pid);
    80001e74:	85ca                	mv	a1,s2
    80001e76:	00006517          	auipc	a0,0x6
    80001e7a:	43250513          	addi	a0,a0,1074 # 800082a8 <digits+0x268>
    80001e7e:	ffffe097          	auipc	ra,0xffffe
    80001e82:	710080e7          	jalr	1808(ra) # 8000058e <printf>
  int old_static_priority = -1;
    80001e86:	59fd                	li	s3,-1
    80001e88:	a899                	j	80001ede <set_priority+0xbc>
    printf("<new_static_priority> should be in range [0 - 100]\n");
    80001e8a:	00006517          	auipc	a0,0x6
    80001e8e:	3ae50513          	addi	a0,a0,942 # 80008238 <digits+0x1f8>
    80001e92:	ffffe097          	auipc	ra,0xffffe
    80001e96:	6fc080e7          	jalr	1788(ra) # 8000058e <printf>
    return -1;
    80001e9a:	59fd                	li	s3,-1
    80001e9c:	a089                	j	80001ede <set_priority+0xbc>
    printf("<new_static_priority> should be in range [0 - 100]\n");
    80001e9e:	00006517          	auipc	a0,0x6
    80001ea2:	39a50513          	addi	a0,a0,922 # 80008238 <digits+0x1f8>
    80001ea6:	ffffe097          	auipc	ra,0xffffe
    80001eaa:	6e8080e7          	jalr	1768(ra) # 8000058e <printf>
    return -1;
    80001eae:	59fd                	li	s3,-1
    80001eb0:	a03d                	j	80001ede <set_priority+0xbc>
      old_static_priority = p->priority;
    80001eb2:	1a04a983          	lw	s3,416(s1)
      p->priority = new_static_priority;
    80001eb6:	1b44a023          	sw	s4,416(s1)
    printf("priority of proc wit pid : %d changed from %d to %d \n", p->pid, old_static_priority, new_static_priority);
    80001eba:	86d2                	mv	a3,s4
    80001ebc:	864e                	mv	a2,s3
    80001ebe:	85ca                	mv	a1,s2
    80001ec0:	00006517          	auipc	a0,0x6
    80001ec4:	3b050513          	addi	a0,a0,944 # 80008270 <digits+0x230>
    80001ec8:	ffffe097          	auipc	ra,0xffffe
    80001ecc:	6c6080e7          	jalr	1734(ra) # 8000058e <printf>
    release(&p->lock);
    80001ed0:	8526                	mv	a0,s1
    80001ed2:	fffff097          	auipc	ra,0xfffff
    80001ed6:	08e080e7          	jalr	142(ra) # 80000f60 <release>
    if (old_static_priority < new_static_priority)
    80001eda:	0149cb63          	blt	s3,s4,80001ef0 <set_priority+0xce>
}
    80001ede:	854e                	mv	a0,s3
    80001ee0:	70a2                	ld	ra,40(sp)
    80001ee2:	7402                	ld	s0,32(sp)
    80001ee4:	64e2                	ld	s1,24(sp)
    80001ee6:	6942                	ld	s2,16(sp)
    80001ee8:	69a2                	ld	s3,8(sp)
    80001eea:	6a02                	ld	s4,0(sp)
    80001eec:	6145                	addi	sp,sp,48
    80001eee:	8082                	ret
      p->last_run = 0;
    80001ef0:	1a04a623          	sw	zero,428(s1)
      p->last_sleep = 0;
    80001ef4:	1a04a823          	sw	zero,432(s1)
    80001ef8:	b7dd                	j	80001ede <set_priority+0xbc>

0000000080001efa <proc_pagetable>:
{
    80001efa:	1101                	addi	sp,sp,-32
    80001efc:	ec06                	sd	ra,24(sp)
    80001efe:	e822                	sd	s0,16(sp)
    80001f00:	e426                	sd	s1,8(sp)
    80001f02:	e04a                	sd	s2,0(sp)
    80001f04:	1000                	addi	s0,sp,32
    80001f06:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001f08:	fffff097          	auipc	ra,0xfffff
    80001f0c:	6fe080e7          	jalr	1790(ra) # 80001606 <uvmcreate>
    80001f10:	84aa                	mv	s1,a0
  if (pagetable == 0)
    80001f12:	c121                	beqz	a0,80001f52 <proc_pagetable+0x58>
  if (mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001f14:	4729                	li	a4,10
    80001f16:	00005697          	auipc	a3,0x5
    80001f1a:	0ea68693          	addi	a3,a3,234 # 80007000 <_trampoline>
    80001f1e:	6605                	lui	a2,0x1
    80001f20:	040005b7          	lui	a1,0x4000
    80001f24:	15fd                	addi	a1,a1,-1
    80001f26:	05b2                	slli	a1,a1,0xc
    80001f28:	fffff097          	auipc	ra,0xfffff
    80001f2c:	454080e7          	jalr	1108(ra) # 8000137c <mappages>
    80001f30:	02054863          	bltz	a0,80001f60 <proc_pagetable+0x66>
  if (mappages(pagetable, TRAPFRAME, PGSIZE,
    80001f34:	4719                	li	a4,6
    80001f36:	06093683          	ld	a3,96(s2)
    80001f3a:	6605                	lui	a2,0x1
    80001f3c:	020005b7          	lui	a1,0x2000
    80001f40:	15fd                	addi	a1,a1,-1
    80001f42:	05b6                	slli	a1,a1,0xd
    80001f44:	8526                	mv	a0,s1
    80001f46:	fffff097          	auipc	ra,0xfffff
    80001f4a:	436080e7          	jalr	1078(ra) # 8000137c <mappages>
    80001f4e:	02054163          	bltz	a0,80001f70 <proc_pagetable+0x76>
}
    80001f52:	8526                	mv	a0,s1
    80001f54:	60e2                	ld	ra,24(sp)
    80001f56:	6442                	ld	s0,16(sp)
    80001f58:	64a2                	ld	s1,8(sp)
    80001f5a:	6902                	ld	s2,0(sp)
    80001f5c:	6105                	addi	sp,sp,32
    80001f5e:	8082                	ret
    uvmfree(pagetable, 0);
    80001f60:	4581                	li	a1,0
    80001f62:	8526                	mv	a0,s1
    80001f64:	00000097          	auipc	ra,0x0
    80001f68:	8a6080e7          	jalr	-1882(ra) # 8000180a <uvmfree>
    return 0;
    80001f6c:	4481                	li	s1,0
    80001f6e:	b7d5                	j	80001f52 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001f70:	4681                	li	a3,0
    80001f72:	4605                	li	a2,1
    80001f74:	040005b7          	lui	a1,0x4000
    80001f78:	15fd                	addi	a1,a1,-1
    80001f7a:	05b2                	slli	a1,a1,0xc
    80001f7c:	8526                	mv	a0,s1
    80001f7e:	fffff097          	auipc	ra,0xfffff
    80001f82:	5c4080e7          	jalr	1476(ra) # 80001542 <uvmunmap>
    uvmfree(pagetable, 0);
    80001f86:	4581                	li	a1,0
    80001f88:	8526                	mv	a0,s1
    80001f8a:	00000097          	auipc	ra,0x0
    80001f8e:	880080e7          	jalr	-1920(ra) # 8000180a <uvmfree>
    return 0;
    80001f92:	4481                	li	s1,0
    80001f94:	bf7d                	j	80001f52 <proc_pagetable+0x58>

0000000080001f96 <proc_freepagetable>:
{
    80001f96:	1101                	addi	sp,sp,-32
    80001f98:	ec06                	sd	ra,24(sp)
    80001f9a:	e822                	sd	s0,16(sp)
    80001f9c:	e426                	sd	s1,8(sp)
    80001f9e:	e04a                	sd	s2,0(sp)
    80001fa0:	1000                	addi	s0,sp,32
    80001fa2:	84aa                	mv	s1,a0
    80001fa4:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001fa6:	4681                	li	a3,0
    80001fa8:	4605                	li	a2,1
    80001faa:	040005b7          	lui	a1,0x4000
    80001fae:	15fd                	addi	a1,a1,-1
    80001fb0:	05b2                	slli	a1,a1,0xc
    80001fb2:	fffff097          	auipc	ra,0xfffff
    80001fb6:	590080e7          	jalr	1424(ra) # 80001542 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001fba:	4681                	li	a3,0
    80001fbc:	4605                	li	a2,1
    80001fbe:	020005b7          	lui	a1,0x2000
    80001fc2:	15fd                	addi	a1,a1,-1
    80001fc4:	05b6                	slli	a1,a1,0xd
    80001fc6:	8526                	mv	a0,s1
    80001fc8:	fffff097          	auipc	ra,0xfffff
    80001fcc:	57a080e7          	jalr	1402(ra) # 80001542 <uvmunmap>
  uvmfree(pagetable, sz);
    80001fd0:	85ca                	mv	a1,s2
    80001fd2:	8526                	mv	a0,s1
    80001fd4:	00000097          	auipc	ra,0x0
    80001fd8:	836080e7          	jalr	-1994(ra) # 8000180a <uvmfree>
}
    80001fdc:	60e2                	ld	ra,24(sp)
    80001fde:	6442                	ld	s0,16(sp)
    80001fe0:	64a2                	ld	s1,8(sp)
    80001fe2:	6902                	ld	s2,0(sp)
    80001fe4:	6105                	addi	sp,sp,32
    80001fe6:	8082                	ret

0000000080001fe8 <freeproc>:
{
    80001fe8:	1101                	addi	sp,sp,-32
    80001fea:	ec06                	sd	ra,24(sp)
    80001fec:	e822                	sd	s0,16(sp)
    80001fee:	e426                	sd	s1,8(sp)
    80001ff0:	1000                	addi	s0,sp,32
    80001ff2:	84aa                	mv	s1,a0
  if (p->trapframe)
    80001ff4:	7128                	ld	a0,96(a0)
    80001ff6:	c509                	beqz	a0,80002000 <freeproc+0x18>
    kfree((void *)p->trapframe);
    80001ff8:	fffff097          	auipc	ra,0xfffff
    80001ffc:	b9e080e7          	jalr	-1122(ra) # 80000b96 <kfree>
  if (p->trapframe_copy)
    80002000:	1884b503          	ld	a0,392(s1)
    80002004:	c509                	beqz	a0,8000200e <freeproc+0x26>
    kfree((void *)p->trapframe_copy);
    80002006:	fffff097          	auipc	ra,0xfffff
    8000200a:	b90080e7          	jalr	-1136(ra) # 80000b96 <kfree>
  p->trapframe = 0;
    8000200e:	0604b023          	sd	zero,96(s1)
  if (p->pagetable)
    80002012:	6ca8                	ld	a0,88(s1)
    80002014:	c511                	beqz	a0,80002020 <freeproc+0x38>
    proc_freepagetable(p->pagetable, p->sz);
    80002016:	68ac                	ld	a1,80(s1)
    80002018:	00000097          	auipc	ra,0x0
    8000201c:	f7e080e7          	jalr	-130(ra) # 80001f96 <proc_freepagetable>
  p->pagetable = 0;
    80002020:	0404bc23          	sd	zero,88(s1)
  p->sz = 0;
    80002024:	0404b823          	sd	zero,80(s1)
  p->pid = 0;
    80002028:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    8000202c:	0404b023          	sd	zero,64(s1)
  p->name[0] = 0;
    80002030:	16048023          	sb	zero,352(s1)
  p->chan = 0;
    80002034:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80002038:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    8000203c:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80002040:	0004ac23          	sw	zero,24(s1)
}
    80002044:	60e2                	ld	ra,24(sp)
    80002046:	6442                	ld	s0,16(sp)
    80002048:	64a2                	ld	s1,8(sp)
    8000204a:	6105                	addi	sp,sp,32
    8000204c:	8082                	ret

000000008000204e <allocproc>:
{
    8000204e:	1101                	addi	sp,sp,-32
    80002050:	ec06                	sd	ra,24(sp)
    80002052:	e822                	sd	s0,16(sp)
    80002054:	e426                	sd	s1,8(sp)
    80002056:	e04a                	sd	s2,0(sp)
    80002058:	1000                	addi	s0,sp,32
  p = proc;
    8000205a:	0022f497          	auipc	s1,0x22f
    8000205e:	d4e48493          	addi	s1,s1,-690 # 80230da8 <proc>
  while (p < &proc[NPROC])
    80002062:	00236917          	auipc	s2,0x236
    80002066:	14690913          	addi	s2,s2,326 # 802381a8 <cpus>
    acquire(&p->lock);
    8000206a:	8526                	mv	a0,s1
    8000206c:	fffff097          	auipc	ra,0xfffff
    80002070:	e40080e7          	jalr	-448(ra) # 80000eac <acquire>
    if (p->state == UNUSED)
    80002074:	4c9c                	lw	a5,24(s1)
    80002076:	cbb9                	beqz	a5,800020cc <allocproc+0x7e>
      release(&p->lock);
    80002078:	8526                	mv	a0,s1
    8000207a:	fffff097          	auipc	ra,0xfffff
    8000207e:	ee6080e7          	jalr	-282(ra) # 80000f60 <release>
    p++;
    80002082:	1d048493          	addi	s1,s1,464
  while (p < &proc[NPROC])
    80002086:	ff2492e3          	bne	s1,s2,8000206a <allocproc+0x1c>
    return 0;
    8000208a:	4481                	li	s1,0
    8000208c:	a8d9                	j	80002162 <allocproc+0x114>
    freeproc(p);
    8000208e:	8526                	mv	a0,s1
    80002090:	00000097          	auipc	ra,0x0
    80002094:	f58080e7          	jalr	-168(ra) # 80001fe8 <freeproc>
    release(&p->lock);
    80002098:	8526                	mv	a0,s1
    8000209a:	fffff097          	auipc	ra,0xfffff
    8000209e:	ec6080e7          	jalr	-314(ra) # 80000f60 <release>
  return 0;
    800020a2:	84ca                	mv	s1,s2
    800020a4:	a87d                	j	80002162 <allocproc+0x114>
      freeproc(p);
    800020a6:	8526                	mv	a0,s1
    800020a8:	00000097          	auipc	ra,0x0
    800020ac:	f40080e7          	jalr	-192(ra) # 80001fe8 <freeproc>
      release(&p->lock);
    800020b0:	8526                	mv	a0,s1
    800020b2:	fffff097          	auipc	ra,0xfffff
    800020b6:	eae080e7          	jalr	-338(ra) # 80000f60 <release>
      return 0;
    800020ba:	84ca                	mv	s1,s2
    800020bc:	a05d                	j	80002162 <allocproc+0x114>
      release(&p->lock);
    800020be:	8526                	mv	a0,s1
    800020c0:	fffff097          	auipc	ra,0xfffff
    800020c4:	ea0080e7          	jalr	-352(ra) # 80000f60 <release>
      return 0;
    800020c8:	84ca                	mv	s1,s2
    800020ca:	a861                	j	80002162 <allocproc+0x114>
  p->pid = allocpid();
    800020cc:	00000097          	auipc	ra,0x0
    800020d0:	cb2080e7          	jalr	-846(ra) # 80001d7e <allocpid>
    800020d4:	d888                	sw	a0,48(s1)
  p->state = USED;
    800020d6:	4785                	li	a5,1
    800020d8:	cc9c                	sw	a5,24(s1)
  p->priority = 60;
    800020da:	03c00793          	li	a5,60
    800020de:	1af4a023          	sw	a5,416(s1)
  p->tick = 0;
    800020e2:	1a04ac23          	sw	zero,440(s1)
  p->ticket = InitialTickets; // initially
    800020e6:	4795                	li	a5,5
    800020e8:	1af4aa23          	sw	a5,436(s1)
  if ((p->trapframe = (struct trapframe *)kalloc()) == 0)
    800020ec:	fffff097          	auipc	ra,0xfffff
    800020f0:	c08080e7          	jalr	-1016(ra) # 80000cf4 <kalloc>
    800020f4:	892a                	mv	s2,a0
    800020f6:	f0a8                	sd	a0,96(s1)
    800020f8:	d959                	beqz	a0,8000208e <allocproc+0x40>
    p->pagetable = proc_pagetable(p);
    800020fa:	8526                	mv	a0,s1
    800020fc:	00000097          	auipc	ra,0x0
    80002100:	dfe080e7          	jalr	-514(ra) # 80001efa <proc_pagetable>
    80002104:	892a                	mv	s2,a0
    80002106:	eca8                	sd	a0,88(s1)
    if (p->pagetable == 0)
    80002108:	dd59                	beqz	a0,800020a6 <allocproc+0x58>
    if ((p->trapframe_copy = (struct trapframe *)kalloc()) == 0)
    8000210a:	fffff097          	auipc	ra,0xfffff
    8000210e:	bea080e7          	jalr	-1046(ra) # 80000cf4 <kalloc>
    80002112:	892a                	mv	s2,a0
    80002114:	18a4b423          	sd	a0,392(s1)
    80002118:	d15d                	beqz	a0,800020be <allocproc+0x70>
    p->handler = 0;
    8000211a:	1804b023          	sd	zero,384(s1)
    p->is_sigalarm = 0;
    8000211e:	1604a823          	sw	zero,368(s1)
    p->now_ticks = 0;
    80002122:	1604ac23          	sw	zero,376(s1)
    p->ticks = 0;
    80002126:	1604aa23          	sw	zero,372(s1)
    memset(&p->context, 0, sizeof(p->context));
    8000212a:	07000613          	li	a2,112
    8000212e:	4581                	li	a1,0
    80002130:	06848513          	addi	a0,s1,104
    80002134:	fffff097          	auipc	ra,0xfffff
    80002138:	e74080e7          	jalr	-396(ra) # 80000fa8 <memset>
    p->context.ra = (uint64)forkret;
    8000213c:	00000797          	auipc	a5,0x0
    80002140:	bfc78793          	addi	a5,a5,-1028 # 80001d38 <forkret>
    80002144:	f4bc                	sd	a5,104(s1)
    p->etime = 0;
    80002146:	1c04a423          	sw	zero,456(s1)
    p->ctime = ticks;
    8000214a:	00007797          	auipc	a5,0x7
    8000214e:	99e7a783          	lw	a5,-1634(a5) # 80008ae8 <ticks>
    80002152:	1cf4a223          	sw	a5,452(s1)
    p->context.sp = p->kstack + PGSIZE;
    80002156:	64bc                	ld	a5,72(s1)
    80002158:	6705                	lui	a4,0x1
    8000215a:	97ba                	add	a5,a5,a4
    8000215c:	f8bc                	sd	a5,112(s1)
    p->rtime = 0;
    8000215e:	1c04a023          	sw	zero,448(s1)
}
    80002162:	8526                	mv	a0,s1
    80002164:	60e2                	ld	ra,24(sp)
    80002166:	6442                	ld	s0,16(sp)
    80002168:	64a2                	ld	s1,8(sp)
    8000216a:	6902                	ld	s2,0(sp)
    8000216c:	6105                	addi	sp,sp,32
    8000216e:	8082                	ret

0000000080002170 <userinit>:
{
    80002170:	1101                	addi	sp,sp,-32
    80002172:	ec06                	sd	ra,24(sp)
    80002174:	e822                	sd	s0,16(sp)
    80002176:	e426                	sd	s1,8(sp)
    80002178:	1000                	addi	s0,sp,32
  p = allocproc();
    8000217a:	00000097          	auipc	ra,0x0
    8000217e:	ed4080e7          	jalr	-300(ra) # 8000204e <allocproc>
    80002182:	84aa                	mv	s1,a0
  initproc = p;
    80002184:	00007797          	auipc	a5,0x7
    80002188:	94a7be23          	sd	a0,-1700(a5) # 80008ae0 <initproc>
  uvmfirst(p->pagetable, initcode, sizeof(initcode));
    8000218c:	03400613          	li	a2,52
    80002190:	00007597          	auipc	a1,0x7
    80002194:	8c058593          	addi	a1,a1,-1856 # 80008a50 <initcode>
    80002198:	6d28                	ld	a0,88(a0)
    8000219a:	fffff097          	auipc	ra,0xfffff
    8000219e:	49a080e7          	jalr	1178(ra) # 80001634 <uvmfirst>
  p->sz = PGSIZE;
    800021a2:	6785                	lui	a5,0x1
    800021a4:	e8bc                	sd	a5,80(s1)
  p->trapframe->epc = 0;     // user program counter
    800021a6:	70b8                	ld	a4,96(s1)
    800021a8:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE; // user stack pointer
    800021ac:	70b8                	ld	a4,96(s1)
    800021ae:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    800021b0:	4641                	li	a2,16
    800021b2:	00006597          	auipc	a1,0x6
    800021b6:	11e58593          	addi	a1,a1,286 # 800082d0 <digits+0x290>
    800021ba:	16048513          	addi	a0,s1,352
    800021be:	fffff097          	auipc	ra,0xfffff
    800021c2:	f3c080e7          	jalr	-196(ra) # 800010fa <safestrcpy>
  p->cwd = namei("/");
    800021c6:	00006517          	auipc	a0,0x6
    800021ca:	11a50513          	addi	a0,a0,282 # 800082e0 <digits+0x2a0>
    800021ce:	00003097          	auipc	ra,0x3
    800021d2:	908080e7          	jalr	-1784(ra) # 80004ad6 <namei>
    800021d6:	14a4bc23          	sd	a0,344(s1)
  p->state = RUNNABLE;
    800021da:	478d                	li	a5,3
    800021dc:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    800021de:	8526                	mv	a0,s1
    800021e0:	fffff097          	auipc	ra,0xfffff
    800021e4:	d80080e7          	jalr	-640(ra) # 80000f60 <release>
}
    800021e8:	60e2                	ld	ra,24(sp)
    800021ea:	6442                	ld	s0,16(sp)
    800021ec:	64a2                	ld	s1,8(sp)
    800021ee:	6105                	addi	sp,sp,32
    800021f0:	8082                	ret

00000000800021f2 <growproc>:
{
    800021f2:	1101                	addi	sp,sp,-32
    800021f4:	ec06                	sd	ra,24(sp)
    800021f6:	e822                	sd	s0,16(sp)
    800021f8:	e426                	sd	s1,8(sp)
    800021fa:	e04a                	sd	s2,0(sp)
    800021fc:	1000                	addi	s0,sp,32
    800021fe:	892a                	mv	s2,a0
  struct proc *p = myproc();
    80002200:	00000097          	auipc	ra,0x0
    80002204:	afa080e7          	jalr	-1286(ra) # 80001cfa <myproc>
    80002208:	84aa                	mv	s1,a0
  sz = p->sz;
    8000220a:	692c                	ld	a1,80(a0)
  if (n > 0)
    8000220c:	01204c63          	bgtz	s2,80002224 <growproc+0x32>
  else if (n < 0)
    80002210:	02094663          	bltz	s2,8000223c <growproc+0x4a>
  p->sz = sz;
    80002214:	e8ac                	sd	a1,80(s1)
  return 0;
    80002216:	4501                	li	a0,0
}
    80002218:	60e2                	ld	ra,24(sp)
    8000221a:	6442                	ld	s0,16(sp)
    8000221c:	64a2                	ld	s1,8(sp)
    8000221e:	6902                	ld	s2,0(sp)
    80002220:	6105                	addi	sp,sp,32
    80002222:	8082                	ret
    if ((sz = uvmalloc(p->pagetable, sz, sz + n, PTE_W)) == 0)
    80002224:	4691                	li	a3,4
    80002226:	00b90633          	add	a2,s2,a1
    8000222a:	6d28                	ld	a0,88(a0)
    8000222c:	fffff097          	auipc	ra,0xfffff
    80002230:	4c2080e7          	jalr	1218(ra) # 800016ee <uvmalloc>
    80002234:	85aa                	mv	a1,a0
    80002236:	fd79                	bnez	a0,80002214 <growproc+0x22>
      return -1;
    80002238:	557d                	li	a0,-1
    8000223a:	bff9                	j	80002218 <growproc+0x26>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    8000223c:	00b90633          	add	a2,s2,a1
    80002240:	6d28                	ld	a0,88(a0)
    80002242:	fffff097          	auipc	ra,0xfffff
    80002246:	464080e7          	jalr	1124(ra) # 800016a6 <uvmdealloc>
    8000224a:	85aa                	mv	a1,a0
    8000224c:	b7e1                	j	80002214 <growproc+0x22>

000000008000224e <fork>:
{
    8000224e:	7179                	addi	sp,sp,-48
    80002250:	f406                	sd	ra,40(sp)
    80002252:	f022                	sd	s0,32(sp)
    80002254:	ec26                	sd	s1,24(sp)
    80002256:	e84a                	sd	s2,16(sp)
    80002258:	e44e                	sd	s3,8(sp)
    8000225a:	e052                	sd	s4,0(sp)
    8000225c:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    8000225e:	00000097          	auipc	ra,0x0
    80002262:	a9c080e7          	jalr	-1380(ra) # 80001cfa <myproc>
    80002266:	892a                	mv	s2,a0
  if ((np = allocproc()) == 0)
    80002268:	00000097          	auipc	ra,0x0
    8000226c:	de6080e7          	jalr	-538(ra) # 8000204e <allocproc>
    80002270:	10050f63          	beqz	a0,8000238e <fork+0x140>
    80002274:	89aa                	mv	s3,a0
  if (uvmcopy(p->pagetable, np->pagetable, p->sz) < 0)
    80002276:	05093603          	ld	a2,80(s2)
    8000227a:	6d2c                	ld	a1,88(a0)
    8000227c:	05893503          	ld	a0,88(s2)
    80002280:	fffff097          	auipc	ra,0xfffff
    80002284:	5c2080e7          	jalr	1474(ra) # 80001842 <uvmcopy>
    80002288:	04054a63          	bltz	a0,800022dc <fork+0x8e>
  np->sz = p->sz;
    8000228c:	05093783          	ld	a5,80(s2)
    80002290:	04f9b823          	sd	a5,80(s3)
  np->ticket = p->ticket;
    80002294:	1b492783          	lw	a5,436(s2)
    80002298:	1af9aa23          	sw	a5,436(s3)
  *(np->trapframe) = *(p->trapframe);
    8000229c:	06093683          	ld	a3,96(s2)
    800022a0:	87b6                	mv	a5,a3
    800022a2:	0609b703          	ld	a4,96(s3)
    800022a6:	12068693          	addi	a3,a3,288
    800022aa:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    800022ae:	6788                	ld	a0,8(a5)
    800022b0:	6b8c                	ld	a1,16(a5)
    800022b2:	6f90                	ld	a2,24(a5)
    800022b4:	01073023          	sd	a6,0(a4)
    800022b8:	e708                	sd	a0,8(a4)
    800022ba:	eb0c                	sd	a1,16(a4)
    800022bc:	ef10                	sd	a2,24(a4)
    800022be:	02078793          	addi	a5,a5,32
    800022c2:	02070713          	addi	a4,a4,32
    800022c6:	fed792e3          	bne	a5,a3,800022aa <fork+0x5c>
  np->trapframe->a0 = 0;
    800022ca:	0609b783          	ld	a5,96(s3)
    800022ce:	0607b823          	sd	zero,112(a5)
    800022d2:	0d800493          	li	s1,216
  for (i = 0; i < NOFILE; i++)
    800022d6:	15800a13          	li	s4,344
    800022da:	a03d                	j	80002308 <fork+0xba>
    freeproc(np);
    800022dc:	854e                	mv	a0,s3
    800022de:	00000097          	auipc	ra,0x0
    800022e2:	d0a080e7          	jalr	-758(ra) # 80001fe8 <freeproc>
    release(&np->lock);
    800022e6:	854e                	mv	a0,s3
    800022e8:	fffff097          	auipc	ra,0xfffff
    800022ec:	c78080e7          	jalr	-904(ra) # 80000f60 <release>
    return -1;
    800022f0:	5a7d                	li	s4,-1
    800022f2:	a069                	j	8000237c <fork+0x12e>
      np->ofile[i] = filedup(p->ofile[i]);
    800022f4:	00003097          	auipc	ra,0x3
    800022f8:	e78080e7          	jalr	-392(ra) # 8000516c <filedup>
    800022fc:	009987b3          	add	a5,s3,s1
    80002300:	e388                	sd	a0,0(a5)
  for (i = 0; i < NOFILE; i++)
    80002302:	04a1                	addi	s1,s1,8
    80002304:	01448763          	beq	s1,s4,80002312 <fork+0xc4>
    if (p->ofile[i])
    80002308:	009907b3          	add	a5,s2,s1
    8000230c:	6388                	ld	a0,0(a5)
    8000230e:	f17d                	bnez	a0,800022f4 <fork+0xa6>
    80002310:	bfcd                	j	80002302 <fork+0xb4>
  np->cwd = idup(p->cwd);
    80002312:	15893503          	ld	a0,344(s2)
    80002316:	00002097          	auipc	ra,0x2
    8000231a:	fdc080e7          	jalr	-36(ra) # 800042f2 <idup>
    8000231e:	14a9bc23          	sd	a0,344(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    80002322:	4641                	li	a2,16
    80002324:	16090593          	addi	a1,s2,352
    80002328:	16098513          	addi	a0,s3,352
    8000232c:	fffff097          	auipc	ra,0xfffff
    80002330:	dce080e7          	jalr	-562(ra) # 800010fa <safestrcpy>
  pid = np->pid;
    80002334:	0309aa03          	lw	s4,48(s3)
  release(&np->lock);
    80002338:	854e                	mv	a0,s3
    8000233a:	fffff097          	auipc	ra,0xfffff
    8000233e:	c26080e7          	jalr	-986(ra) # 80000f60 <release>
  acquire(&wait_lock);
    80002342:	0022f497          	auipc	s1,0x22f
    80002346:	a4e48493          	addi	s1,s1,-1458 # 80230d90 <wait_lock>
    8000234a:	8526                	mv	a0,s1
    8000234c:	fffff097          	auipc	ra,0xfffff
    80002350:	b60080e7          	jalr	-1184(ra) # 80000eac <acquire>
  np->parent = p;
    80002354:	0529b023          	sd	s2,64(s3)
  release(&wait_lock);
    80002358:	8526                	mv	a0,s1
    8000235a:	fffff097          	auipc	ra,0xfffff
    8000235e:	c06080e7          	jalr	-1018(ra) # 80000f60 <release>
  acquire(&np->lock);
    80002362:	854e                	mv	a0,s3
    80002364:	fffff097          	auipc	ra,0xfffff
    80002368:	b48080e7          	jalr	-1208(ra) # 80000eac <acquire>
  np->state = RUNNABLE;
    8000236c:	478d                	li	a5,3
    8000236e:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80002372:	854e                	mv	a0,s3
    80002374:	fffff097          	auipc	ra,0xfffff
    80002378:	bec080e7          	jalr	-1044(ra) # 80000f60 <release>
}
    8000237c:	8552                	mv	a0,s4
    8000237e:	70a2                	ld	ra,40(sp)
    80002380:	7402                	ld	s0,32(sp)
    80002382:	64e2                	ld	s1,24(sp)
    80002384:	6942                	ld	s2,16(sp)
    80002386:	69a2                	ld	s3,8(sp)
    80002388:	6a02                	ld	s4,0(sp)
    8000238a:	6145                	addi	sp,sp,48
    8000238c:	8082                	ret
    return -1;
    8000238e:	5a7d                	li	s4,-1
    80002390:	b7f5                	j	8000237c <fork+0x12e>

0000000080002392 <getpinfo>:
{
    80002392:	7179                	addi	sp,sp,-48
    80002394:	f406                	sd	ra,40(sp)
    80002396:	f022                	sd	s0,32(sp)
    80002398:	ec26                	sd	s1,24(sp)
    8000239a:	e84a                	sd	s2,16(sp)
    8000239c:	e44e                	sd	s3,8(sp)
    8000239e:	1800                	addi	s0,sp,48
    800023a0:	892a                	mv	s2,a0
  for (p = proc; p < &proc[NPROC]; p++)
    800023a2:	0022f497          	auipc	s1,0x22f
    800023a6:	a0648493          	addi	s1,s1,-1530 # 80230da8 <proc>
    800023aa:	00236997          	auipc	s3,0x236
    800023ae:	dfe98993          	addi	s3,s3,-514 # 802381a8 <cpus>
    acquire(&p->lock);
    800023b2:	8526                	mv	a0,s1
    800023b4:	fffff097          	auipc	ra,0xfffff
    800023b8:	af8080e7          	jalr	-1288(ra) # 80000eac <acquire>
    ps->pid[i] = p->pid;
    800023bc:	589c                	lw	a5,48(s1)
    800023be:	20f92023          	sw	a5,512(s2)
    ps->inuse[i] = p->state != UNUSED;
    800023c2:	4c9c                	lw	a5,24(s1)
    800023c4:	00f037b3          	snez	a5,a5
    800023c8:	00f92023          	sw	a5,0(s2)
    ps->ticket[i] = p->ticket;
    800023cc:	1b44a783          	lw	a5,436(s1)
    800023d0:	10f92023          	sw	a5,256(s2)
    ps->tick[i] = p->tick;
    800023d4:	1b84a783          	lw	a5,440(s1)
    800023d8:	30f92023          	sw	a5,768(s2)
    release(&p->lock);
    800023dc:	8526                	mv	a0,s1
    800023de:	fffff097          	auipc	ra,0xfffff
    800023e2:	b82080e7          	jalr	-1150(ra) # 80000f60 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800023e6:	1d048493          	addi	s1,s1,464
    800023ea:	0911                	addi	s2,s2,4
    800023ec:	fd3493e3          	bne	s1,s3,800023b2 <getpinfo+0x20>
}
    800023f0:	4501                	li	a0,0
    800023f2:	70a2                	ld	ra,40(sp)
    800023f4:	7402                	ld	s0,32(sp)
    800023f6:	64e2                	ld	s1,24(sp)
    800023f8:	6942                	ld	s2,16(sp)
    800023fa:	69a2                	ld	s3,8(sp)
    800023fc:	6145                	addi	sp,sp,48
    800023fe:	8082                	ret

0000000080002400 <getRunnableProcTickets>:
{
    80002400:	1141                	addi	sp,sp,-16
    80002402:	e422                	sd	s0,8(sp)
    80002404:	0800                	addi	s0,sp,16
  int total = 0;
    80002406:	4501                	li	a0,0
  for (p = proc; p < &proc[NPROC]; p++)
    80002408:	0022f797          	auipc	a5,0x22f
    8000240c:	9a078793          	addi	a5,a5,-1632 # 80230da8 <proc>
    if (p->state == RUNNABLE)
    80002410:	460d                	li	a2,3
  for (p = proc; p < &proc[NPROC]; p++)
    80002412:	00236697          	auipc	a3,0x236
    80002416:	d9668693          	addi	a3,a3,-618 # 802381a8 <cpus>
    8000241a:	a029                	j	80002424 <getRunnableProcTickets+0x24>
    8000241c:	1d078793          	addi	a5,a5,464
    80002420:	00d78963          	beq	a5,a3,80002432 <getRunnableProcTickets+0x32>
    if (p->state == RUNNABLE)
    80002424:	4f98                	lw	a4,24(a5)
    80002426:	fec71be3          	bne	a4,a2,8000241c <getRunnableProcTickets+0x1c>
      total += p->ticket;
    8000242a:	1b47a703          	lw	a4,436(a5)
    8000242e:	9d39                	addw	a0,a0,a4
    80002430:	b7f5                	j	8000241c <getRunnableProcTickets+0x1c>
}
    80002432:	6422                	ld	s0,8(sp)
    80002434:	0141                	addi	sp,sp,16
    80002436:	8082                	ret

0000000080002438 <settickets>:
{
    80002438:	7179                	addi	sp,sp,-48
    8000243a:	f406                	sd	ra,40(sp)
    8000243c:	f022                	sd	s0,32(sp)
    8000243e:	ec26                	sd	s1,24(sp)
    80002440:	e84a                	sd	s2,16(sp)
    80002442:	e44e                	sd	s3,8(sp)
    80002444:	e052                	sd	s4,0(sp)
    80002446:	1800                	addi	s0,sp,48
    80002448:	8a2a                	mv	s4,a0
  struct proc *pr = myproc();
    8000244a:	00000097          	auipc	ra,0x0
    8000244e:	8b0080e7          	jalr	-1872(ra) # 80001cfa <myproc>
  int pid = pr->pid;
    80002452:	03052903          	lw	s2,48(a0)
  for (p = proc; p < &proc[NPROC]; p++)
    80002456:	0022f497          	auipc	s1,0x22f
    8000245a:	95248493          	addi	s1,s1,-1710 # 80230da8 <proc>
    8000245e:	00236997          	auipc	s3,0x236
    80002462:	d4a98993          	addi	s3,s3,-694 # 802381a8 <cpus>
    acquire(&p->lock);
    80002466:	8526                	mv	a0,s1
    80002468:	fffff097          	auipc	ra,0xfffff
    8000246c:	a44080e7          	jalr	-1468(ra) # 80000eac <acquire>
    if (p->pid == pid)
    80002470:	589c                	lw	a5,48(s1)
    80002472:	01278c63          	beq	a5,s2,8000248a <settickets+0x52>
    release(&p->lock);
    80002476:	8526                	mv	a0,s1
    80002478:	fffff097          	auipc	ra,0xfffff
    8000247c:	ae8080e7          	jalr	-1304(ra) # 80000f60 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002480:	1d048493          	addi	s1,s1,464
    80002484:	ff3491e3          	bne	s1,s3,80002466 <settickets+0x2e>
    80002488:	a801                	j	80002498 <settickets+0x60>
      p->ticket = number; // assigining alloted ticket for a process
    8000248a:	1b44aa23          	sw	s4,436(s1)
      release(&p->lock);
    8000248e:	8526                	mv	a0,s1
    80002490:	fffff097          	auipc	ra,0xfffff
    80002494:	ad0080e7          	jalr	-1328(ra) # 80000f60 <release>
}
    80002498:	4501                	li	a0,0
    8000249a:	70a2                	ld	ra,40(sp)
    8000249c:	7402                	ld	s0,32(sp)
    8000249e:	64e2                	ld	s1,24(sp)
    800024a0:	6942                	ld	s2,16(sp)
    800024a2:	69a2                	ld	s3,8(sp)
    800024a4:	6a02                	ld	s4,0(sp)
    800024a6:	6145                	addi	sp,sp,48
    800024a8:	8082                	ret

00000000800024aa <scheduler>:
{
    800024aa:	7139                	addi	sp,sp,-64
    800024ac:	fc06                	sd	ra,56(sp)
    800024ae:	f822                	sd	s0,48(sp)
    800024b0:	f426                	sd	s1,40(sp)
    800024b2:	f04a                	sd	s2,32(sp)
    800024b4:	ec4e                	sd	s3,24(sp)
    800024b6:	e852                	sd	s4,16(sp)
    800024b8:	e456                	sd	s5,8(sp)
    800024ba:	e05a                	sd	s6,0(sp)
    800024bc:	0080                	addi	s0,sp,64
    800024be:	8792                	mv	a5,tp
  int id = r_tp();
    800024c0:	2781                	sext.w	a5,a5
  c->proc = 0;
    800024c2:	00236a97          	auipc	s5,0x236
    800024c6:	ce6a8a93          	addi	s5,s5,-794 # 802381a8 <cpus>
    800024ca:	15800713          	li	a4,344
    800024ce:	02e78733          	mul	a4,a5,a4
    800024d2:	00ea86b3          	add	a3,s5,a4
    800024d6:	0006b023          	sd	zero,0(a3)
        swtch(&c->context, &p->context);
    800024da:	0721                	addi	a4,a4,8
    800024dc:	9aba                	add	s5,s5,a4
        p->state = RUNNING;
    800024de:	4b11                	li	s6,4
        c->proc = p;
    800024e0:	8a36                	mv	s4,a3
    for (p = proc; p < &proc[NPROC]; p++)
    800024e2:	00236997          	auipc	s3,0x236
    800024e6:	cc698993          	addi	s3,s3,-826 # 802381a8 <cpus>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800024ea:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800024ee:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800024f2:	10079073          	csrw	sstatus,a5
    800024f6:	0022f497          	auipc	s1,0x22f
    800024fa:	8b248493          	addi	s1,s1,-1870 # 80230da8 <proc>
      if (p->state == RUNNABLE)
    800024fe:	490d                	li	s2,3
    80002500:	a03d                	j	8000252e <scheduler+0x84>
        p->state = RUNNING;
    80002502:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80002506:	009a3023          	sd	s1,0(s4)
        swtch(&c->context, &p->context);
    8000250a:	06848593          	addi	a1,s1,104
    8000250e:	8556                	mv	a0,s5
    80002510:	00001097          	auipc	ra,0x1
    80002514:	8d6080e7          	jalr	-1834(ra) # 80002de6 <swtch>
        c->proc = 0;
    80002518:	000a3023          	sd	zero,0(s4)
      release(&p->lock);
    8000251c:	8526                	mv	a0,s1
    8000251e:	fffff097          	auipc	ra,0xfffff
    80002522:	a42080e7          	jalr	-1470(ra) # 80000f60 <release>
    for (p = proc; p < &proc[NPROC]; p++)
    80002526:	1d048493          	addi	s1,s1,464
    8000252a:	fd3480e3          	beq	s1,s3,800024ea <scheduler+0x40>
      acquire(&p->lock);
    8000252e:	8526                	mv	a0,s1
    80002530:	fffff097          	auipc	ra,0xfffff
    80002534:	97c080e7          	jalr	-1668(ra) # 80000eac <acquire>
      if (p->state == RUNNABLE)
    80002538:	4c9c                	lw	a5,24(s1)
    8000253a:	ff2791e3          	bne	a5,s2,8000251c <scheduler+0x72>
    8000253e:	b7d1                	j	80002502 <scheduler+0x58>

0000000080002540 <sched>:
{
    80002540:	7179                	addi	sp,sp,-48
    80002542:	f406                	sd	ra,40(sp)
    80002544:	f022                	sd	s0,32(sp)
    80002546:	ec26                	sd	s1,24(sp)
    80002548:	e84a                	sd	s2,16(sp)
    8000254a:	e44e                	sd	s3,8(sp)
    8000254c:	e052                	sd	s4,0(sp)
    8000254e:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80002550:	fffff097          	auipc	ra,0xfffff
    80002554:	7aa080e7          	jalr	1962(ra) # 80001cfa <myproc>
    80002558:	84aa                	mv	s1,a0
  if (!holding(&p->lock))
    8000255a:	fffff097          	auipc	ra,0xfffff
    8000255e:	8d8080e7          	jalr	-1832(ra) # 80000e32 <holding>
    80002562:	c141                	beqz	a0,800025e2 <sched+0xa2>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002564:	8792                	mv	a5,tp
  if (mycpu()->noff != 1)
    80002566:	2781                	sext.w	a5,a5
    80002568:	15800713          	li	a4,344
    8000256c:	02e787b3          	mul	a5,a5,a4
    80002570:	00236717          	auipc	a4,0x236
    80002574:	c3870713          	addi	a4,a4,-968 # 802381a8 <cpus>
    80002578:	97ba                	add	a5,a5,a4
    8000257a:	5fb8                	lw	a4,120(a5)
    8000257c:	4785                	li	a5,1
    8000257e:	06f71a63          	bne	a4,a5,800025f2 <sched+0xb2>
  if (p->state == RUNNING)
    80002582:	4c98                	lw	a4,24(s1)
    80002584:	4791                	li	a5,4
    80002586:	06f70e63          	beq	a4,a5,80002602 <sched+0xc2>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000258a:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    8000258e:	8b89                	andi	a5,a5,2
  if (intr_get())
    80002590:	e3c9                	bnez	a5,80002612 <sched+0xd2>
  asm volatile("mv %0, tp" : "=r" (x) );
    80002592:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    80002594:	00236917          	auipc	s2,0x236
    80002598:	c1490913          	addi	s2,s2,-1004 # 802381a8 <cpus>
    8000259c:	2781                	sext.w	a5,a5
    8000259e:	15800993          	li	s3,344
    800025a2:	033787b3          	mul	a5,a5,s3
    800025a6:	97ca                	add	a5,a5,s2
    800025a8:	07c7aa03          	lw	s4,124(a5)
    800025ac:	8592                	mv	a1,tp
  swtch(&p->context, &mycpu()->context);
    800025ae:	2581                	sext.w	a1,a1
    800025b0:	033585b3          	mul	a1,a1,s3
    800025b4:	05a1                	addi	a1,a1,8
    800025b6:	95ca                	add	a1,a1,s2
    800025b8:	06848513          	addi	a0,s1,104
    800025bc:	00001097          	auipc	ra,0x1
    800025c0:	82a080e7          	jalr	-2006(ra) # 80002de6 <swtch>
    800025c4:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    800025c6:	2781                	sext.w	a5,a5
    800025c8:	033787b3          	mul	a5,a5,s3
    800025cc:	993e                	add	s2,s2,a5
    800025ce:	07492e23          	sw	s4,124(s2)
}
    800025d2:	70a2                	ld	ra,40(sp)
    800025d4:	7402                	ld	s0,32(sp)
    800025d6:	64e2                	ld	s1,24(sp)
    800025d8:	6942                	ld	s2,16(sp)
    800025da:	69a2                	ld	s3,8(sp)
    800025dc:	6a02                	ld	s4,0(sp)
    800025de:	6145                	addi	sp,sp,48
    800025e0:	8082                	ret
    panic("sched p->lock");
    800025e2:	00006517          	auipc	a0,0x6
    800025e6:	d0650513          	addi	a0,a0,-762 # 800082e8 <digits+0x2a8>
    800025ea:	ffffe097          	auipc	ra,0xffffe
    800025ee:	f5a080e7          	jalr	-166(ra) # 80000544 <panic>
    panic("sched locks");
    800025f2:	00006517          	auipc	a0,0x6
    800025f6:	d0650513          	addi	a0,a0,-762 # 800082f8 <digits+0x2b8>
    800025fa:	ffffe097          	auipc	ra,0xffffe
    800025fe:	f4a080e7          	jalr	-182(ra) # 80000544 <panic>
    panic("sched running");
    80002602:	00006517          	auipc	a0,0x6
    80002606:	d0650513          	addi	a0,a0,-762 # 80008308 <digits+0x2c8>
    8000260a:	ffffe097          	auipc	ra,0xffffe
    8000260e:	f3a080e7          	jalr	-198(ra) # 80000544 <panic>
    panic("sched interruptible");
    80002612:	00006517          	auipc	a0,0x6
    80002616:	d0650513          	addi	a0,a0,-762 # 80008318 <digits+0x2d8>
    8000261a:	ffffe097          	auipc	ra,0xffffe
    8000261e:	f2a080e7          	jalr	-214(ra) # 80000544 <panic>

0000000080002622 <yield>:
{
    80002622:	1101                	addi	sp,sp,-32
    80002624:	ec06                	sd	ra,24(sp)
    80002626:	e822                	sd	s0,16(sp)
    80002628:	e426                	sd	s1,8(sp)
    8000262a:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    8000262c:	fffff097          	auipc	ra,0xfffff
    80002630:	6ce080e7          	jalr	1742(ra) # 80001cfa <myproc>
    80002634:	84aa                	mv	s1,a0
  acquire(&p->lock);
    80002636:	fffff097          	auipc	ra,0xfffff
    8000263a:	876080e7          	jalr	-1930(ra) # 80000eac <acquire>
  p->state = RUNNABLE;
    8000263e:	478d                	li	a5,3
    80002640:	cc9c                	sw	a5,24(s1)
  sched();
    80002642:	00000097          	auipc	ra,0x0
    80002646:	efe080e7          	jalr	-258(ra) # 80002540 <sched>
  release(&p->lock);
    8000264a:	8526                	mv	a0,s1
    8000264c:	fffff097          	auipc	ra,0xfffff
    80002650:	914080e7          	jalr	-1772(ra) # 80000f60 <release>
}
    80002654:	60e2                	ld	ra,24(sp)
    80002656:	6442                	ld	s0,16(sp)
    80002658:	64a2                	ld	s1,8(sp)
    8000265a:	6105                	addi	sp,sp,32
    8000265c:	8082                	ret

000000008000265e <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void sleep(void *chan, struct spinlock *lk)
{
    8000265e:	7179                	addi	sp,sp,-48
    80002660:	f406                	sd	ra,40(sp)
    80002662:	f022                	sd	s0,32(sp)
    80002664:	ec26                	sd	s1,24(sp)
    80002666:	e84a                	sd	s2,16(sp)
    80002668:	e44e                	sd	s3,8(sp)
    8000266a:	1800                	addi	s0,sp,48
    8000266c:	89aa                	mv	s3,a0
    8000266e:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002670:	fffff097          	auipc	ra,0xfffff
    80002674:	68a080e7          	jalr	1674(ra) # 80001cfa <myproc>
    80002678:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock); // DOC: sleeplock1
    8000267a:	fffff097          	auipc	ra,0xfffff
    8000267e:	832080e7          	jalr	-1998(ra) # 80000eac <acquire>
  release(lk);
    80002682:	854a                	mv	a0,s2
    80002684:	fffff097          	auipc	ra,0xfffff
    80002688:	8dc080e7          	jalr	-1828(ra) # 80000f60 <release>

  // Go to sleep.
  p->chan = chan;
    8000268c:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002690:	4789                	li	a5,2
    80002692:	cc9c                	sw	a5,24(s1)

  sched();
    80002694:	00000097          	auipc	ra,0x0
    80002698:	eac080e7          	jalr	-340(ra) # 80002540 <sched>

  // Tidy up.
  p->chan = 0;
    8000269c:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    800026a0:	8526                	mv	a0,s1
    800026a2:	fffff097          	auipc	ra,0xfffff
    800026a6:	8be080e7          	jalr	-1858(ra) # 80000f60 <release>
  acquire(lk);
    800026aa:	854a                	mv	a0,s2
    800026ac:	fffff097          	auipc	ra,0xfffff
    800026b0:	800080e7          	jalr	-2048(ra) # 80000eac <acquire>
}
    800026b4:	70a2                	ld	ra,40(sp)
    800026b6:	7402                	ld	s0,32(sp)
    800026b8:	64e2                	ld	s1,24(sp)
    800026ba:	6942                	ld	s2,16(sp)
    800026bc:	69a2                	ld	s3,8(sp)
    800026be:	6145                	addi	sp,sp,48
    800026c0:	8082                	ret

00000000800026c2 <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void wakeup(void *chan)
{
    800026c2:	7139                	addi	sp,sp,-64
    800026c4:	fc06                	sd	ra,56(sp)
    800026c6:	f822                	sd	s0,48(sp)
    800026c8:	f426                	sd	s1,40(sp)
    800026ca:	f04a                	sd	s2,32(sp)
    800026cc:	ec4e                	sd	s3,24(sp)
    800026ce:	e852                	sd	s4,16(sp)
    800026d0:	e456                	sd	s5,8(sp)
    800026d2:	0080                	addi	s0,sp,64
    800026d4:	8a2a                	mv	s4,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    800026d6:	0022e497          	auipc	s1,0x22e
    800026da:	6d248493          	addi	s1,s1,1746 # 80230da8 <proc>
  {
    if (p != myproc())
    {
      acquire(&p->lock);
      if (p->state == SLEEPING && p->chan == chan)
    800026de:	4989                	li	s3,2
      {
        p->state = RUNNABLE;
    800026e0:	4a8d                	li	s5,3
  for (p = proc; p < &proc[NPROC]; p++)
    800026e2:	00236917          	auipc	s2,0x236
    800026e6:	ac690913          	addi	s2,s2,-1338 # 802381a8 <cpus>
    800026ea:	a821                	j	80002702 <wakeup+0x40>
        p->state = RUNNABLE;
    800026ec:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    800026f0:	8526                	mv	a0,s1
    800026f2:	fffff097          	auipc	ra,0xfffff
    800026f6:	86e080e7          	jalr	-1938(ra) # 80000f60 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800026fa:	1d048493          	addi	s1,s1,464
    800026fe:	03248463          	beq	s1,s2,80002726 <wakeup+0x64>
    if (p != myproc())
    80002702:	fffff097          	auipc	ra,0xfffff
    80002706:	5f8080e7          	jalr	1528(ra) # 80001cfa <myproc>
    8000270a:	fea488e3          	beq	s1,a0,800026fa <wakeup+0x38>
      acquire(&p->lock);
    8000270e:	8526                	mv	a0,s1
    80002710:	ffffe097          	auipc	ra,0xffffe
    80002714:	79c080e7          	jalr	1948(ra) # 80000eac <acquire>
      if (p->state == SLEEPING && p->chan == chan)
    80002718:	4c9c                	lw	a5,24(s1)
    8000271a:	fd379be3          	bne	a5,s3,800026f0 <wakeup+0x2e>
    8000271e:	709c                	ld	a5,32(s1)
    80002720:	fd4798e3          	bne	a5,s4,800026f0 <wakeup+0x2e>
    80002724:	b7e1                	j	800026ec <wakeup+0x2a>
    }
  }
}
    80002726:	70e2                	ld	ra,56(sp)
    80002728:	7442                	ld	s0,48(sp)
    8000272a:	74a2                	ld	s1,40(sp)
    8000272c:	7902                	ld	s2,32(sp)
    8000272e:	69e2                	ld	s3,24(sp)
    80002730:	6a42                	ld	s4,16(sp)
    80002732:	6aa2                	ld	s5,8(sp)
    80002734:	6121                	addi	sp,sp,64
    80002736:	8082                	ret

0000000080002738 <reparent>:
{
    80002738:	7179                	addi	sp,sp,-48
    8000273a:	f406                	sd	ra,40(sp)
    8000273c:	f022                	sd	s0,32(sp)
    8000273e:	ec26                	sd	s1,24(sp)
    80002740:	e84a                	sd	s2,16(sp)
    80002742:	e44e                	sd	s3,8(sp)
    80002744:	e052                	sd	s4,0(sp)
    80002746:	1800                	addi	s0,sp,48
    80002748:	892a                	mv	s2,a0
  for (pp = proc; pp < &proc[NPROC]; pp++)
    8000274a:	0022e497          	auipc	s1,0x22e
    8000274e:	65e48493          	addi	s1,s1,1630 # 80230da8 <proc>
      pp->parent = initproc;
    80002752:	00006a17          	auipc	s4,0x6
    80002756:	38ea0a13          	addi	s4,s4,910 # 80008ae0 <initproc>
  for (pp = proc; pp < &proc[NPROC]; pp++)
    8000275a:	00236997          	auipc	s3,0x236
    8000275e:	a4e98993          	addi	s3,s3,-1458 # 802381a8 <cpus>
    80002762:	a029                	j	8000276c <reparent+0x34>
    80002764:	1d048493          	addi	s1,s1,464
    80002768:	01348d63          	beq	s1,s3,80002782 <reparent+0x4a>
    if (pp->parent == p)
    8000276c:	60bc                	ld	a5,64(s1)
    8000276e:	ff279be3          	bne	a5,s2,80002764 <reparent+0x2c>
      pp->parent = initproc;
    80002772:	000a3503          	ld	a0,0(s4)
    80002776:	e0a8                	sd	a0,64(s1)
      wakeup(initproc);
    80002778:	00000097          	auipc	ra,0x0
    8000277c:	f4a080e7          	jalr	-182(ra) # 800026c2 <wakeup>
    80002780:	b7d5                	j	80002764 <reparent+0x2c>
}
    80002782:	70a2                	ld	ra,40(sp)
    80002784:	7402                	ld	s0,32(sp)
    80002786:	64e2                	ld	s1,24(sp)
    80002788:	6942                	ld	s2,16(sp)
    8000278a:	69a2                	ld	s3,8(sp)
    8000278c:	6a02                	ld	s4,0(sp)
    8000278e:	6145                	addi	sp,sp,48
    80002790:	8082                	ret

0000000080002792 <exit>:
{
    80002792:	7179                	addi	sp,sp,-48
    80002794:	f406                	sd	ra,40(sp)
    80002796:	f022                	sd	s0,32(sp)
    80002798:	ec26                	sd	s1,24(sp)
    8000279a:	e84a                	sd	s2,16(sp)
    8000279c:	e44e                	sd	s3,8(sp)
    8000279e:	e052                	sd	s4,0(sp)
    800027a0:	1800                	addi	s0,sp,48
    800027a2:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    800027a4:	fffff097          	auipc	ra,0xfffff
    800027a8:	556080e7          	jalr	1366(ra) # 80001cfa <myproc>
    800027ac:	89aa                	mv	s3,a0
  if (p == initproc)
    800027ae:	00006797          	auipc	a5,0x6
    800027b2:	3327b783          	ld	a5,818(a5) # 80008ae0 <initproc>
    800027b6:	0d850493          	addi	s1,a0,216
    800027ba:	15850913          	addi	s2,a0,344
    800027be:	02a79363          	bne	a5,a0,800027e4 <exit+0x52>
    panic("init exiting");
    800027c2:	00006517          	auipc	a0,0x6
    800027c6:	b6e50513          	addi	a0,a0,-1170 # 80008330 <digits+0x2f0>
    800027ca:	ffffe097          	auipc	ra,0xffffe
    800027ce:	d7a080e7          	jalr	-646(ra) # 80000544 <panic>
      fileclose(f);
    800027d2:	00003097          	auipc	ra,0x3
    800027d6:	9ec080e7          	jalr	-1556(ra) # 800051be <fileclose>
      p->ofile[fd] = 0;
    800027da:	0004b023          	sd	zero,0(s1)
  for (int fd = 0; fd < NOFILE; fd++)
    800027de:	04a1                	addi	s1,s1,8
    800027e0:	01248563          	beq	s1,s2,800027ea <exit+0x58>
    if (p->ofile[fd])
    800027e4:	6088                	ld	a0,0(s1)
    800027e6:	f575                	bnez	a0,800027d2 <exit+0x40>
    800027e8:	bfdd                	j	800027de <exit+0x4c>
  begin_op();
    800027ea:	00002097          	auipc	ra,0x2
    800027ee:	508080e7          	jalr	1288(ra) # 80004cf2 <begin_op>
  iput(p->cwd);
    800027f2:	1589b503          	ld	a0,344(s3)
    800027f6:	00002097          	auipc	ra,0x2
    800027fa:	cf4080e7          	jalr	-780(ra) # 800044ea <iput>
  end_op();
    800027fe:	00002097          	auipc	ra,0x2
    80002802:	574080e7          	jalr	1396(ra) # 80004d72 <end_op>
  p->cwd = 0;
    80002806:	1409bc23          	sd	zero,344(s3)
  acquire(&wait_lock);
    8000280a:	0022e497          	auipc	s1,0x22e
    8000280e:	58648493          	addi	s1,s1,1414 # 80230d90 <wait_lock>
    80002812:	8526                	mv	a0,s1
    80002814:	ffffe097          	auipc	ra,0xffffe
    80002818:	698080e7          	jalr	1688(ra) # 80000eac <acquire>
  reparent(p);
    8000281c:	854e                	mv	a0,s3
    8000281e:	00000097          	auipc	ra,0x0
    80002822:	f1a080e7          	jalr	-230(ra) # 80002738 <reparent>
  wakeup(p->parent);
    80002826:	0409b503          	ld	a0,64(s3)
    8000282a:	00000097          	auipc	ra,0x0
    8000282e:	e98080e7          	jalr	-360(ra) # 800026c2 <wakeup>
  acquire(&p->lock);
    80002832:	854e                	mv	a0,s3
    80002834:	ffffe097          	auipc	ra,0xffffe
    80002838:	678080e7          	jalr	1656(ra) # 80000eac <acquire>
  p->xstate = status;
    8000283c:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    80002840:	4795                	li	a5,5
    80002842:	00f9ac23          	sw	a5,24(s3)
  p->etime = ticks;
    80002846:	00006797          	auipc	a5,0x6
    8000284a:	2a27a783          	lw	a5,674(a5) # 80008ae8 <ticks>
    8000284e:	1cf9a423          	sw	a5,456(s3)
  release(&wait_lock);
    80002852:	8526                	mv	a0,s1
    80002854:	ffffe097          	auipc	ra,0xffffe
    80002858:	70c080e7          	jalr	1804(ra) # 80000f60 <release>
  sched();
    8000285c:	00000097          	auipc	ra,0x0
    80002860:	ce4080e7          	jalr	-796(ra) # 80002540 <sched>
  panic("zombie exit");
    80002864:	00006517          	auipc	a0,0x6
    80002868:	adc50513          	addi	a0,a0,-1316 # 80008340 <digits+0x300>
    8000286c:	ffffe097          	auipc	ra,0xffffe
    80002870:	cd8080e7          	jalr	-808(ra) # 80000544 <panic>

0000000080002874 <kill>:

// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int kill(int pid)
{
    80002874:	7179                	addi	sp,sp,-48
    80002876:	f406                	sd	ra,40(sp)
    80002878:	f022                	sd	s0,32(sp)
    8000287a:	ec26                	sd	s1,24(sp)
    8000287c:	e84a                	sd	s2,16(sp)
    8000287e:	e44e                	sd	s3,8(sp)
    80002880:	1800                	addi	s0,sp,48
    80002882:	892a                	mv	s2,a0
  struct proc *p;

  for (p = proc; p < &proc[NPROC]; p++)
    80002884:	0022e497          	auipc	s1,0x22e
    80002888:	52448493          	addi	s1,s1,1316 # 80230da8 <proc>
    8000288c:	00236997          	auipc	s3,0x236
    80002890:	91c98993          	addi	s3,s3,-1764 # 802381a8 <cpus>
  {
    acquire(&p->lock);
    80002894:	8526                	mv	a0,s1
    80002896:	ffffe097          	auipc	ra,0xffffe
    8000289a:	616080e7          	jalr	1558(ra) # 80000eac <acquire>
    if (p->pid == pid)
    8000289e:	589c                	lw	a5,48(s1)
    800028a0:	01278d63          	beq	a5,s2,800028ba <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    800028a4:	8526                	mv	a0,s1
    800028a6:	ffffe097          	auipc	ra,0xffffe
    800028aa:	6ba080e7          	jalr	1722(ra) # 80000f60 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    800028ae:	1d048493          	addi	s1,s1,464
    800028b2:	ff3491e3          	bne	s1,s3,80002894 <kill+0x20>
  }
  return -1;
    800028b6:	557d                	li	a0,-1
    800028b8:	a829                	j	800028d2 <kill+0x5e>
      p->killed = 1;
    800028ba:	4785                	li	a5,1
    800028bc:	d49c                	sw	a5,40(s1)
      if (p->state == SLEEPING)
    800028be:	4c98                	lw	a4,24(s1)
    800028c0:	4789                	li	a5,2
    800028c2:	00f70f63          	beq	a4,a5,800028e0 <kill+0x6c>
      release(&p->lock);
    800028c6:	8526                	mv	a0,s1
    800028c8:	ffffe097          	auipc	ra,0xffffe
    800028cc:	698080e7          	jalr	1688(ra) # 80000f60 <release>
      return 0;
    800028d0:	4501                	li	a0,0
}
    800028d2:	70a2                	ld	ra,40(sp)
    800028d4:	7402                	ld	s0,32(sp)
    800028d6:	64e2                	ld	s1,24(sp)
    800028d8:	6942                	ld	s2,16(sp)
    800028da:	69a2                	ld	s3,8(sp)
    800028dc:	6145                	addi	sp,sp,48
    800028de:	8082                	ret
        p->state = RUNNABLE;
    800028e0:	478d                	li	a5,3
    800028e2:	cc9c                	sw	a5,24(s1)
    800028e4:	b7cd                	j	800028c6 <kill+0x52>

00000000800028e6 <setkilled>:

void setkilled(struct proc *p)
{
    800028e6:	1101                	addi	sp,sp,-32
    800028e8:	ec06                	sd	ra,24(sp)
    800028ea:	e822                	sd	s0,16(sp)
    800028ec:	e426                	sd	s1,8(sp)
    800028ee:	1000                	addi	s0,sp,32
    800028f0:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800028f2:	ffffe097          	auipc	ra,0xffffe
    800028f6:	5ba080e7          	jalr	1466(ra) # 80000eac <acquire>
  p->killed = 1;
    800028fa:	4785                	li	a5,1
    800028fc:	d49c                	sw	a5,40(s1)
  release(&p->lock);
    800028fe:	8526                	mv	a0,s1
    80002900:	ffffe097          	auipc	ra,0xffffe
    80002904:	660080e7          	jalr	1632(ra) # 80000f60 <release>
}
    80002908:	60e2                	ld	ra,24(sp)
    8000290a:	6442                	ld	s0,16(sp)
    8000290c:	64a2                	ld	s1,8(sp)
    8000290e:	6105                	addi	sp,sp,32
    80002910:	8082                	ret

0000000080002912 <killed>:

int killed(struct proc *p)
{
    80002912:	1101                	addi	sp,sp,-32
    80002914:	ec06                	sd	ra,24(sp)
    80002916:	e822                	sd	s0,16(sp)
    80002918:	e426                	sd	s1,8(sp)
    8000291a:	e04a                	sd	s2,0(sp)
    8000291c:	1000                	addi	s0,sp,32
    8000291e:	84aa                	mv	s1,a0
  int k;

  acquire(&p->lock);
    80002920:	ffffe097          	auipc	ra,0xffffe
    80002924:	58c080e7          	jalr	1420(ra) # 80000eac <acquire>
  k = p->killed;
    80002928:	0284a903          	lw	s2,40(s1)
  release(&p->lock);
    8000292c:	8526                	mv	a0,s1
    8000292e:	ffffe097          	auipc	ra,0xffffe
    80002932:	632080e7          	jalr	1586(ra) # 80000f60 <release>
  return k;
}
    80002936:	854a                	mv	a0,s2
    80002938:	60e2                	ld	ra,24(sp)
    8000293a:	6442                	ld	s0,16(sp)
    8000293c:	64a2                	ld	s1,8(sp)
    8000293e:	6902                	ld	s2,0(sp)
    80002940:	6105                	addi	sp,sp,32
    80002942:	8082                	ret

0000000080002944 <wait>:
{
    80002944:	715d                	addi	sp,sp,-80
    80002946:	e486                	sd	ra,72(sp)
    80002948:	e0a2                	sd	s0,64(sp)
    8000294a:	fc26                	sd	s1,56(sp)
    8000294c:	f84a                	sd	s2,48(sp)
    8000294e:	f44e                	sd	s3,40(sp)
    80002950:	f052                	sd	s4,32(sp)
    80002952:	ec56                	sd	s5,24(sp)
    80002954:	e85a                	sd	s6,16(sp)
    80002956:	e45e                	sd	s7,8(sp)
    80002958:	e062                	sd	s8,0(sp)
    8000295a:	0880                	addi	s0,sp,80
    8000295c:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    8000295e:	fffff097          	auipc	ra,0xfffff
    80002962:	39c080e7          	jalr	924(ra) # 80001cfa <myproc>
    80002966:	892a                	mv	s2,a0
  acquire(&wait_lock);
    80002968:	0022e517          	auipc	a0,0x22e
    8000296c:	42850513          	addi	a0,a0,1064 # 80230d90 <wait_lock>
    80002970:	ffffe097          	auipc	ra,0xffffe
    80002974:	53c080e7          	jalr	1340(ra) # 80000eac <acquire>
    havekids = 0;
    80002978:	4b81                	li	s7,0
        if (pp->state == ZOMBIE)
    8000297a:	4a15                	li	s4,5
    for (pp = proc; pp < &proc[NPROC]; pp++)
    8000297c:	00236997          	auipc	s3,0x236
    80002980:	82c98993          	addi	s3,s3,-2004 # 802381a8 <cpus>
        havekids = 1;
    80002984:	4a85                	li	s5,1
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002986:	0022ec17          	auipc	s8,0x22e
    8000298a:	40ac0c13          	addi	s8,s8,1034 # 80230d90 <wait_lock>
    havekids = 0;
    8000298e:	875e                	mv	a4,s7
    for (pp = proc; pp < &proc[NPROC]; pp++)
    80002990:	0022e497          	auipc	s1,0x22e
    80002994:	41848493          	addi	s1,s1,1048 # 80230da8 <proc>
    80002998:	a0bd                	j	80002a06 <wait+0xc2>
          pid = pp->pid;
    8000299a:	0304a983          	lw	s3,48(s1)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&pp->xstate,
    8000299e:	000b0e63          	beqz	s6,800029ba <wait+0x76>
    800029a2:	4691                	li	a3,4
    800029a4:	02c48613          	addi	a2,s1,44
    800029a8:	85da                	mv	a1,s6
    800029aa:	05893503          	ld	a0,88(s2)
    800029ae:	fffff097          	auipc	ra,0xfffff
    800029b2:	f9c080e7          	jalr	-100(ra) # 8000194a <copyout>
    800029b6:	02054563          	bltz	a0,800029e0 <wait+0x9c>
          freeproc(pp);
    800029ba:	8526                	mv	a0,s1
    800029bc:	fffff097          	auipc	ra,0xfffff
    800029c0:	62c080e7          	jalr	1580(ra) # 80001fe8 <freeproc>
          release(&pp->lock);
    800029c4:	8526                	mv	a0,s1
    800029c6:	ffffe097          	auipc	ra,0xffffe
    800029ca:	59a080e7          	jalr	1434(ra) # 80000f60 <release>
          release(&wait_lock);
    800029ce:	0022e517          	auipc	a0,0x22e
    800029d2:	3c250513          	addi	a0,a0,962 # 80230d90 <wait_lock>
    800029d6:	ffffe097          	auipc	ra,0xffffe
    800029da:	58a080e7          	jalr	1418(ra) # 80000f60 <release>
          return pid;
    800029de:	a0b5                	j	80002a4a <wait+0x106>
            release(&pp->lock);
    800029e0:	8526                	mv	a0,s1
    800029e2:	ffffe097          	auipc	ra,0xffffe
    800029e6:	57e080e7          	jalr	1406(ra) # 80000f60 <release>
            release(&wait_lock);
    800029ea:	0022e517          	auipc	a0,0x22e
    800029ee:	3a650513          	addi	a0,a0,934 # 80230d90 <wait_lock>
    800029f2:	ffffe097          	auipc	ra,0xffffe
    800029f6:	56e080e7          	jalr	1390(ra) # 80000f60 <release>
            return -1;
    800029fa:	59fd                	li	s3,-1
    800029fc:	a0b9                	j	80002a4a <wait+0x106>
    for (pp = proc; pp < &proc[NPROC]; pp++)
    800029fe:	1d048493          	addi	s1,s1,464
    80002a02:	03348463          	beq	s1,s3,80002a2a <wait+0xe6>
      if (pp->parent == p)
    80002a06:	60bc                	ld	a5,64(s1)
    80002a08:	ff279be3          	bne	a5,s2,800029fe <wait+0xba>
        acquire(&pp->lock);
    80002a0c:	8526                	mv	a0,s1
    80002a0e:	ffffe097          	auipc	ra,0xffffe
    80002a12:	49e080e7          	jalr	1182(ra) # 80000eac <acquire>
        if (pp->state == ZOMBIE)
    80002a16:	4c9c                	lw	a5,24(s1)
    80002a18:	f94781e3          	beq	a5,s4,8000299a <wait+0x56>
        release(&pp->lock);
    80002a1c:	8526                	mv	a0,s1
    80002a1e:	ffffe097          	auipc	ra,0xffffe
    80002a22:	542080e7          	jalr	1346(ra) # 80000f60 <release>
        havekids = 1;
    80002a26:	8756                	mv	a4,s5
    80002a28:	bfd9                	j	800029fe <wait+0xba>
    if (!havekids || killed(p))
    80002a2a:	c719                	beqz	a4,80002a38 <wait+0xf4>
    80002a2c:	854a                	mv	a0,s2
    80002a2e:	00000097          	auipc	ra,0x0
    80002a32:	ee4080e7          	jalr	-284(ra) # 80002912 <killed>
    80002a36:	c51d                	beqz	a0,80002a64 <wait+0x120>
      release(&wait_lock);
    80002a38:	0022e517          	auipc	a0,0x22e
    80002a3c:	35850513          	addi	a0,a0,856 # 80230d90 <wait_lock>
    80002a40:	ffffe097          	auipc	ra,0xffffe
    80002a44:	520080e7          	jalr	1312(ra) # 80000f60 <release>
      return -1;
    80002a48:	59fd                	li	s3,-1
}
    80002a4a:	854e                	mv	a0,s3
    80002a4c:	60a6                	ld	ra,72(sp)
    80002a4e:	6406                	ld	s0,64(sp)
    80002a50:	74e2                	ld	s1,56(sp)
    80002a52:	7942                	ld	s2,48(sp)
    80002a54:	79a2                	ld	s3,40(sp)
    80002a56:	7a02                	ld	s4,32(sp)
    80002a58:	6ae2                	ld	s5,24(sp)
    80002a5a:	6b42                	ld	s6,16(sp)
    80002a5c:	6ba2                	ld	s7,8(sp)
    80002a5e:	6c02                	ld	s8,0(sp)
    80002a60:	6161                	addi	sp,sp,80
    80002a62:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002a64:	85e2                	mv	a1,s8
    80002a66:	854a                	mv	a0,s2
    80002a68:	00000097          	auipc	ra,0x0
    80002a6c:	bf6080e7          	jalr	-1034(ra) # 8000265e <sleep>
    havekids = 0;
    80002a70:	bf39                	j	8000298e <wait+0x4a>

0000000080002a72 <either_copyout>:

// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002a72:	7179                	addi	sp,sp,-48
    80002a74:	f406                	sd	ra,40(sp)
    80002a76:	f022                	sd	s0,32(sp)
    80002a78:	ec26                	sd	s1,24(sp)
    80002a7a:	e84a                	sd	s2,16(sp)
    80002a7c:	e44e                	sd	s3,8(sp)
    80002a7e:	e052                	sd	s4,0(sp)
    80002a80:	1800                	addi	s0,sp,48
    80002a82:	84aa                	mv	s1,a0
    80002a84:	892e                	mv	s2,a1
    80002a86:	89b2                	mv	s3,a2
    80002a88:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002a8a:	fffff097          	auipc	ra,0xfffff
    80002a8e:	270080e7          	jalr	624(ra) # 80001cfa <myproc>
  if (user_dst)
    80002a92:	c08d                	beqz	s1,80002ab4 <either_copyout+0x42>
  {
    return copyout(p->pagetable, dst, src, len);
    80002a94:	86d2                	mv	a3,s4
    80002a96:	864e                	mv	a2,s3
    80002a98:	85ca                	mv	a1,s2
    80002a9a:	6d28                	ld	a0,88(a0)
    80002a9c:	fffff097          	auipc	ra,0xfffff
    80002aa0:	eae080e7          	jalr	-338(ra) # 8000194a <copyout>
  else
  {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    80002aa4:	70a2                	ld	ra,40(sp)
    80002aa6:	7402                	ld	s0,32(sp)
    80002aa8:	64e2                	ld	s1,24(sp)
    80002aaa:	6942                	ld	s2,16(sp)
    80002aac:	69a2                	ld	s3,8(sp)
    80002aae:	6a02                	ld	s4,0(sp)
    80002ab0:	6145                	addi	sp,sp,48
    80002ab2:	8082                	ret
    memmove((char *)dst, src, len);
    80002ab4:	000a061b          	sext.w	a2,s4
    80002ab8:	85ce                	mv	a1,s3
    80002aba:	854a                	mv	a0,s2
    80002abc:	ffffe097          	auipc	ra,0xffffe
    80002ac0:	54c080e7          	jalr	1356(ra) # 80001008 <memmove>
    return 0;
    80002ac4:	8526                	mv	a0,s1
    80002ac6:	bff9                	j	80002aa4 <either_copyout+0x32>

0000000080002ac8 <either_copyin>:

// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    80002ac8:	7179                	addi	sp,sp,-48
    80002aca:	f406                	sd	ra,40(sp)
    80002acc:	f022                	sd	s0,32(sp)
    80002ace:	ec26                	sd	s1,24(sp)
    80002ad0:	e84a                	sd	s2,16(sp)
    80002ad2:	e44e                	sd	s3,8(sp)
    80002ad4:	e052                	sd	s4,0(sp)
    80002ad6:	1800                	addi	s0,sp,48
    80002ad8:	892a                	mv	s2,a0
    80002ada:	84ae                	mv	s1,a1
    80002adc:	89b2                	mv	s3,a2
    80002ade:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    80002ae0:	fffff097          	auipc	ra,0xfffff
    80002ae4:	21a080e7          	jalr	538(ra) # 80001cfa <myproc>
  if (user_src)
    80002ae8:	c08d                	beqz	s1,80002b0a <either_copyin+0x42>
  {
    return copyin(p->pagetable, dst, src, len);
    80002aea:	86d2                	mv	a3,s4
    80002aec:	864e                	mv	a2,s3
    80002aee:	85ca                	mv	a1,s2
    80002af0:	6d28                	ld	a0,88(a0)
    80002af2:	fffff097          	auipc	ra,0xfffff
    80002af6:	f1c080e7          	jalr	-228(ra) # 80001a0e <copyin>
  else
  {
    memmove(dst, (char *)src, len);
    return 0;
  }
}
    80002afa:	70a2                	ld	ra,40(sp)
    80002afc:	7402                	ld	s0,32(sp)
    80002afe:	64e2                	ld	s1,24(sp)
    80002b00:	6942                	ld	s2,16(sp)
    80002b02:	69a2                	ld	s3,8(sp)
    80002b04:	6a02                	ld	s4,0(sp)
    80002b06:	6145                	addi	sp,sp,48
    80002b08:	8082                	ret
    memmove(dst, (char *)src, len);
    80002b0a:	000a061b          	sext.w	a2,s4
    80002b0e:	85ce                	mv	a1,s3
    80002b10:	854a                	mv	a0,s2
    80002b12:	ffffe097          	auipc	ra,0xffffe
    80002b16:	4f6080e7          	jalr	1270(ra) # 80001008 <memmove>
    return 0;
    80002b1a:	8526                	mv	a0,s1
    80002b1c:	bff9                	j	80002afa <either_copyin+0x32>

0000000080002b1e <procdump>:

// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void procdump(void)
{
    80002b1e:	715d                	addi	sp,sp,-80
    80002b20:	e486                	sd	ra,72(sp)
    80002b22:	e0a2                	sd	s0,64(sp)
    80002b24:	fc26                	sd	s1,56(sp)
    80002b26:	f84a                	sd	s2,48(sp)
    80002b28:	f44e                	sd	s3,40(sp)
    80002b2a:	f052                	sd	s4,32(sp)
    80002b2c:	ec56                	sd	s5,24(sp)
    80002b2e:	e85a                	sd	s6,16(sp)
    80002b30:	e45e                	sd	s7,8(sp)
    80002b32:	0880                	addi	s0,sp,80
      [RUNNABLE] "runble",
      [RUNNING] "run   ",
      [ZOMBIE] "zombie"};
  char *state;

  printf("\n");
    80002b34:	00005517          	auipc	a0,0x5
    80002b38:	5cc50513          	addi	a0,a0,1484 # 80008100 <digits+0xc0>
    80002b3c:	ffffe097          	auipc	ra,0xffffe
    80002b40:	a52080e7          	jalr	-1454(ra) # 8000058e <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002b44:	0022e497          	auipc	s1,0x22e
    80002b48:	3c448493          	addi	s1,s1,964 # 80230f08 <proc+0x160>
    80002b4c:	00235917          	auipc	s2,0x235
    80002b50:	7bc90913          	addi	s2,s2,1980 # 80238308 <cpus+0x160>
  {
    if (p->state == UNUSED)
      continue;
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002b54:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    80002b56:	00005997          	auipc	s3,0x5
    80002b5a:	7fa98993          	addi	s3,s3,2042 # 80008350 <digits+0x310>
    printf("%d %s %s", p->pid, state, p->name);
    80002b5e:	00005a97          	auipc	s5,0x5
    80002b62:	7faa8a93          	addi	s5,s5,2042 # 80008358 <digits+0x318>
#endif
#ifdef MLFQ
    int wtime = ticks - p->qitime;
    printf("%d %d %s %d %d %d %d %d %d %d %d", p->pid, p->priority, state, p->rtime, wtime, p->nrun, p->qrtime[0], p->qrtime[1], p->qrtime[2], p->qrtime[3], p->qrtime[4]);
#endif
    printf("\n");
    80002b66:	00005a17          	auipc	s4,0x5
    80002b6a:	59aa0a13          	addi	s4,s4,1434 # 80008100 <digits+0xc0>
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002b6e:	00006b97          	auipc	s7,0x6
    80002b72:	822b8b93          	addi	s7,s7,-2014 # 80008390 <states.1882>
    80002b76:	a00d                	j	80002b98 <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    80002b78:	ed06a583          	lw	a1,-304(a3)
    80002b7c:	8556                	mv	a0,s5
    80002b7e:	ffffe097          	auipc	ra,0xffffe
    80002b82:	a10080e7          	jalr	-1520(ra) # 8000058e <printf>
    printf("\n");
    80002b86:	8552                	mv	a0,s4
    80002b88:	ffffe097          	auipc	ra,0xffffe
    80002b8c:	a06080e7          	jalr	-1530(ra) # 8000058e <printf>
  for (p = proc; p < &proc[NPROC]; p++)
    80002b90:	1d048493          	addi	s1,s1,464
    80002b94:	03248163          	beq	s1,s2,80002bb6 <procdump+0x98>
    if (p->state == UNUSED)
    80002b98:	86a6                	mv	a3,s1
    80002b9a:	eb84a783          	lw	a5,-328(s1)
    80002b9e:	dbed                	beqz	a5,80002b90 <procdump+0x72>
      state = "???";
    80002ba0:	864e                	mv	a2,s3
    if (p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002ba2:	fcfb6be3          	bltu	s6,a5,80002b78 <procdump+0x5a>
    80002ba6:	1782                	slli	a5,a5,0x20
    80002ba8:	9381                	srli	a5,a5,0x20
    80002baa:	078e                	slli	a5,a5,0x3
    80002bac:	97de                	add	a5,a5,s7
    80002bae:	6390                	ld	a2,0(a5)
    80002bb0:	f661                	bnez	a2,80002b78 <procdump+0x5a>
      state = "???";
    80002bb2:	864e                	mv	a2,s3
    80002bb4:	b7d1                	j	80002b78 <procdump+0x5a>
  }
}
    80002bb6:	60a6                	ld	ra,72(sp)
    80002bb8:	6406                	ld	s0,64(sp)
    80002bba:	74e2                	ld	s1,56(sp)
    80002bbc:	7942                	ld	s2,48(sp)
    80002bbe:	79a2                	ld	s3,40(sp)
    80002bc0:	7a02                	ld	s4,32(sp)
    80002bc2:	6ae2                	ld	s5,24(sp)
    80002bc4:	6b42                	ld	s6,16(sp)
    80002bc6:	6ba2                	ld	s7,8(sp)
    80002bc8:	6161                	addi	sp,sp,80
    80002bca:	8082                	ret

0000000080002bcc <waitx>:

// Wait for a child process to exit and return its pid.
// Return -1 if this process has no children.
int waitx(uint64 addr, uint *wtime, uint *rtime)
{
    80002bcc:	711d                	addi	sp,sp,-96
    80002bce:	ec86                	sd	ra,88(sp)
    80002bd0:	e8a2                	sd	s0,80(sp)
    80002bd2:	e4a6                	sd	s1,72(sp)
    80002bd4:	e0ca                	sd	s2,64(sp)
    80002bd6:	fc4e                	sd	s3,56(sp)
    80002bd8:	f852                	sd	s4,48(sp)
    80002bda:	f456                	sd	s5,40(sp)
    80002bdc:	f05a                	sd	s6,32(sp)
    80002bde:	ec5e                	sd	s7,24(sp)
    80002be0:	e862                	sd	s8,16(sp)
    80002be2:	e466                	sd	s9,8(sp)
    80002be4:	e06a                	sd	s10,0(sp)
    80002be6:	1080                	addi	s0,sp,96
    80002be8:	8b2a                	mv	s6,a0
    80002bea:	8bae                	mv	s7,a1
    80002bec:	8c32                	mv	s8,a2
  struct proc *np;
  int havekids, pid;
  struct proc *p = myproc();
    80002bee:	fffff097          	auipc	ra,0xfffff
    80002bf2:	10c080e7          	jalr	268(ra) # 80001cfa <myproc>
    80002bf6:	892a                	mv	s2,a0

  acquire(&wait_lock);
    80002bf8:	0022e517          	auipc	a0,0x22e
    80002bfc:	19850513          	addi	a0,a0,408 # 80230d90 <wait_lock>
    80002c00:	ffffe097          	auipc	ra,0xffffe
    80002c04:	2ac080e7          	jalr	684(ra) # 80000eac <acquire>

  for (;;)
  {
    // Scan through table looking for exited children.
    havekids = 0;
    80002c08:	4c81                	li	s9,0
      {
        // make sure the child isn't still in exit() or swtch().
        acquire(&np->lock);

        havekids = 1;
        if (np->state == ZOMBIE)
    80002c0a:	4a15                	li	s4,5
    for (np = proc; np < &proc[NPROC]; np++)
    80002c0c:	00235997          	auipc	s3,0x235
    80002c10:	59c98993          	addi	s3,s3,1436 # 802381a8 <cpus>
        havekids = 1;
    80002c14:	4a85                	li	s5,1
      release(&wait_lock);
      return -1;
    }

    // Wait for a child to exit.
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002c16:	0022ed17          	auipc	s10,0x22e
    80002c1a:	17ad0d13          	addi	s10,s10,378 # 80230d90 <wait_lock>
    havekids = 0;
    80002c1e:	8766                	mv	a4,s9
    for (np = proc; np < &proc[NPROC]; np++)
    80002c20:	0022e497          	auipc	s1,0x22e
    80002c24:	18848493          	addi	s1,s1,392 # 80230da8 <proc>
    80002c28:	a059                	j	80002cae <waitx+0xe2>
          pid = np->pid;
    80002c2a:	0304a983          	lw	s3,48(s1)
          *rtime = np->rtime;
    80002c2e:	1c04a703          	lw	a4,448(s1)
    80002c32:	00ec2023          	sw	a4,0(s8)
          *wtime = np->etime - np->ctime - np->rtime;
    80002c36:	1c44a783          	lw	a5,452(s1)
    80002c3a:	9f3d                	addw	a4,a4,a5
    80002c3c:	1c84a783          	lw	a5,456(s1)
    80002c40:	9f99                	subw	a5,a5,a4
    80002c42:	00fba023          	sw	a5,0(s7)
          if (addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    80002c46:	000b0e63          	beqz	s6,80002c62 <waitx+0x96>
    80002c4a:	4691                	li	a3,4
    80002c4c:	02c48613          	addi	a2,s1,44
    80002c50:	85da                	mv	a1,s6
    80002c52:	05893503          	ld	a0,88(s2)
    80002c56:	fffff097          	auipc	ra,0xfffff
    80002c5a:	cf4080e7          	jalr	-780(ra) # 8000194a <copyout>
    80002c5e:	02054563          	bltz	a0,80002c88 <waitx+0xbc>
          freeproc(np);
    80002c62:	8526                	mv	a0,s1
    80002c64:	fffff097          	auipc	ra,0xfffff
    80002c68:	384080e7          	jalr	900(ra) # 80001fe8 <freeproc>
          release(&np->lock);
    80002c6c:	8526                	mv	a0,s1
    80002c6e:	ffffe097          	auipc	ra,0xffffe
    80002c72:	2f2080e7          	jalr	754(ra) # 80000f60 <release>
          release(&wait_lock);
    80002c76:	0022e517          	auipc	a0,0x22e
    80002c7a:	11a50513          	addi	a0,a0,282 # 80230d90 <wait_lock>
    80002c7e:	ffffe097          	auipc	ra,0xffffe
    80002c82:	2e2080e7          	jalr	738(ra) # 80000f60 <release>
          return pid;
    80002c86:	a09d                	j	80002cec <waitx+0x120>
            release(&np->lock);
    80002c88:	8526                	mv	a0,s1
    80002c8a:	ffffe097          	auipc	ra,0xffffe
    80002c8e:	2d6080e7          	jalr	726(ra) # 80000f60 <release>
            release(&wait_lock);
    80002c92:	0022e517          	auipc	a0,0x22e
    80002c96:	0fe50513          	addi	a0,a0,254 # 80230d90 <wait_lock>
    80002c9a:	ffffe097          	auipc	ra,0xffffe
    80002c9e:	2c6080e7          	jalr	710(ra) # 80000f60 <release>
            return -1;
    80002ca2:	59fd                	li	s3,-1
    80002ca4:	a0a1                	j	80002cec <waitx+0x120>
    for (np = proc; np < &proc[NPROC]; np++)
    80002ca6:	1d048493          	addi	s1,s1,464
    80002caa:	03348463          	beq	s1,s3,80002cd2 <waitx+0x106>
      if (np->parent == p)
    80002cae:	60bc                	ld	a5,64(s1)
    80002cb0:	ff279be3          	bne	a5,s2,80002ca6 <waitx+0xda>
        acquire(&np->lock);
    80002cb4:	8526                	mv	a0,s1
    80002cb6:	ffffe097          	auipc	ra,0xffffe
    80002cba:	1f6080e7          	jalr	502(ra) # 80000eac <acquire>
        if (np->state == ZOMBIE)
    80002cbe:	4c9c                	lw	a5,24(s1)
    80002cc0:	f74785e3          	beq	a5,s4,80002c2a <waitx+0x5e>
        release(&np->lock);
    80002cc4:	8526                	mv	a0,s1
    80002cc6:	ffffe097          	auipc	ra,0xffffe
    80002cca:	29a080e7          	jalr	666(ra) # 80000f60 <release>
        havekids = 1;
    80002cce:	8756                	mv	a4,s5
    80002cd0:	bfd9                	j	80002ca6 <waitx+0xda>
    if (!havekids || p->killed)
    80002cd2:	c701                	beqz	a4,80002cda <waitx+0x10e>
    80002cd4:	02892783          	lw	a5,40(s2)
    80002cd8:	cb8d                	beqz	a5,80002d0a <waitx+0x13e>
      release(&wait_lock);
    80002cda:	0022e517          	auipc	a0,0x22e
    80002cde:	0b650513          	addi	a0,a0,182 # 80230d90 <wait_lock>
    80002ce2:	ffffe097          	auipc	ra,0xffffe
    80002ce6:	27e080e7          	jalr	638(ra) # 80000f60 <release>
      return -1;
    80002cea:	59fd                	li	s3,-1
  }
}
    80002cec:	854e                	mv	a0,s3
    80002cee:	60e6                	ld	ra,88(sp)
    80002cf0:	6446                	ld	s0,80(sp)
    80002cf2:	64a6                	ld	s1,72(sp)
    80002cf4:	6906                	ld	s2,64(sp)
    80002cf6:	79e2                	ld	s3,56(sp)
    80002cf8:	7a42                	ld	s4,48(sp)
    80002cfa:	7aa2                	ld	s5,40(sp)
    80002cfc:	7b02                	ld	s6,32(sp)
    80002cfe:	6be2                	ld	s7,24(sp)
    80002d00:	6c42                	ld	s8,16(sp)
    80002d02:	6ca2                	ld	s9,8(sp)
    80002d04:	6d02                	ld	s10,0(sp)
    80002d06:	6125                	addi	sp,sp,96
    80002d08:	8082                	ret
    sleep(p, &wait_lock); // DOC: wait-sleep
    80002d0a:	85ea                	mv	a1,s10
    80002d0c:	854a                	mv	a0,s2
    80002d0e:	00000097          	auipc	ra,0x0
    80002d12:	950080e7          	jalr	-1712(ra) # 8000265e <sleep>
    havekids = 0;
    80002d16:	b721                	j	80002c1e <waitx+0x52>

0000000080002d18 <sys_sigalarm>:

uint64 sys_sigalarm(void)
{
    80002d18:	1101                	addi	sp,sp,-32
    80002d1a:	ec06                	sd	ra,24(sp)
    80002d1c:	e822                	sd	s0,16(sp)
    80002d1e:	1000                	addi	s0,sp,32
  int ticks;
  uint64 handler;
  argint(0, &ticks);
    80002d20:	fec40593          	addi	a1,s0,-20
    80002d24:	4501                	li	a0,0
    80002d26:	00000097          	auipc	ra,0x0
    80002d2a:	66e080e7          	jalr	1646(ra) # 80003394 <argint>
  argaddr(1, &handler);
    80002d2e:	fe040593          	addi	a1,s0,-32
    80002d32:	4505                	li	a0,1
    80002d34:	00000097          	auipc	ra,0x0
    80002d38:	680080e7          	jalr	1664(ra) # 800033b4 <argaddr>
  if (ticks < 0 || handler < 0)
    80002d3c:	fec42783          	lw	a5,-20(s0)
    return -1;
    80002d40:	557d                	li	a0,-1
  if (ticks < 0 || handler < 0)
    80002d42:	0207cf63          	bltz	a5,80002d80 <sys_sigalarm+0x68>
  myproc()->handler = handler;
    80002d46:	fffff097          	auipc	ra,0xfffff
    80002d4a:	fb4080e7          	jalr	-76(ra) # 80001cfa <myproc>
    80002d4e:	fe043783          	ld	a5,-32(s0)
    80002d52:	18f53023          	sd	a5,384(a0)
  myproc()->ticks = ticks;
    80002d56:	fffff097          	auipc	ra,0xfffff
    80002d5a:	fa4080e7          	jalr	-92(ra) # 80001cfa <myproc>
    80002d5e:	fec42783          	lw	a5,-20(s0)
    80002d62:	16f52a23          	sw	a5,372(a0)
  myproc()->is_sigalarm = 0;
    80002d66:	fffff097          	auipc	ra,0xfffff
    80002d6a:	f94080e7          	jalr	-108(ra) # 80001cfa <myproc>
    80002d6e:	16052823          	sw	zero,368(a0)
  myproc()->now_ticks = 0;
    80002d72:	fffff097          	auipc	ra,0xfffff
    80002d76:	f88080e7          	jalr	-120(ra) # 80001cfa <myproc>
    80002d7a:	16052c23          	sw	zero,376(a0)
  return 0;
    80002d7e:	4501                	li	a0,0
}
    80002d80:	60e2                	ld	ra,24(sp)
    80002d82:	6442                	ld	s0,16(sp)
    80002d84:	6105                	addi	sp,sp,32
    80002d86:	8082                	ret

0000000080002d88 <update_time>:

void update_time()
{
    80002d88:	7179                	addi	sp,sp,-48
    80002d8a:	f406                	sd	ra,40(sp)
    80002d8c:	f022                	sd	s0,32(sp)
    80002d8e:	ec26                	sd	s1,24(sp)
    80002d90:	e84a                	sd	s2,16(sp)
    80002d92:	e44e                	sd	s3,8(sp)
    80002d94:	1800                	addi	s0,sp,48
    release(&p->lock);
  }
#endif
#ifndef MLFQ
  struct proc *p;
  for (p = proc; p < &proc[NPROC]; p++)
    80002d96:	0022e497          	auipc	s1,0x22e
    80002d9a:	01248493          	addi	s1,s1,18 # 80230da8 <proc>
  {
    acquire(&p->lock);
    if (p->state == RUNNING)
    80002d9e:	4991                	li	s3,4
  for (p = proc; p < &proc[NPROC]; p++)
    80002da0:	00235917          	auipc	s2,0x235
    80002da4:	40890913          	addi	s2,s2,1032 # 802381a8 <cpus>
    80002da8:	a811                	j	80002dbc <update_time+0x34>
    {
      p->rtime++;
    }
    release(&p->lock);
    80002daa:	8526                	mv	a0,s1
    80002dac:	ffffe097          	auipc	ra,0xffffe
    80002db0:	1b4080e7          	jalr	436(ra) # 80000f60 <release>
  for (p = proc; p < &proc[NPROC]; p++)
    80002db4:	1d048493          	addi	s1,s1,464
    80002db8:	03248063          	beq	s1,s2,80002dd8 <update_time+0x50>
    acquire(&p->lock);
    80002dbc:	8526                	mv	a0,s1
    80002dbe:	ffffe097          	auipc	ra,0xffffe
    80002dc2:	0ee080e7          	jalr	238(ra) # 80000eac <acquire>
    if (p->state == RUNNING)
    80002dc6:	4c9c                	lw	a5,24(s1)
    80002dc8:	ff3791e3          	bne	a5,s3,80002daa <update_time+0x22>
      p->rtime++;
    80002dcc:	1c04a783          	lw	a5,448(s1)
    80002dd0:	2785                	addiw	a5,a5,1
    80002dd2:	1cf4a023          	sw	a5,448(s1)
    80002dd6:	bfd1                	j	80002daa <update_time+0x22>
  }
#endif
}
    80002dd8:	70a2                	ld	ra,40(sp)
    80002dda:	7402                	ld	s0,32(sp)
    80002ddc:	64e2                	ld	s1,24(sp)
    80002dde:	6942                	ld	s2,16(sp)
    80002de0:	69a2                	ld	s3,8(sp)
    80002de2:	6145                	addi	sp,sp,48
    80002de4:	8082                	ret

0000000080002de6 <swtch>:
    80002de6:	00153023          	sd	ra,0(a0)
    80002dea:	00253423          	sd	sp,8(a0)
    80002dee:	e900                	sd	s0,16(a0)
    80002df0:	ed04                	sd	s1,24(a0)
    80002df2:	03253023          	sd	s2,32(a0)
    80002df6:	03353423          	sd	s3,40(a0)
    80002dfa:	03453823          	sd	s4,48(a0)
    80002dfe:	03553c23          	sd	s5,56(a0)
    80002e02:	05653023          	sd	s6,64(a0)
    80002e06:	05753423          	sd	s7,72(a0)
    80002e0a:	05853823          	sd	s8,80(a0)
    80002e0e:	05953c23          	sd	s9,88(a0)
    80002e12:	07a53023          	sd	s10,96(a0)
    80002e16:	07b53423          	sd	s11,104(a0)
    80002e1a:	0005b083          	ld	ra,0(a1)
    80002e1e:	0085b103          	ld	sp,8(a1)
    80002e22:	6980                	ld	s0,16(a1)
    80002e24:	6d84                	ld	s1,24(a1)
    80002e26:	0205b903          	ld	s2,32(a1)
    80002e2a:	0285b983          	ld	s3,40(a1)
    80002e2e:	0305ba03          	ld	s4,48(a1)
    80002e32:	0385ba83          	ld	s5,56(a1)
    80002e36:	0405bb03          	ld	s6,64(a1)
    80002e3a:	0485bb83          	ld	s7,72(a1)
    80002e3e:	0505bc03          	ld	s8,80(a1)
    80002e42:	0585bc83          	ld	s9,88(a1)
    80002e46:	0605bd03          	ld	s10,96(a1)
    80002e4a:	0685bd83          	ld	s11,104(a1)
    80002e4e:	8082                	ret

0000000080002e50 <trapinithart>:
#ifdef MLFQ
extern struct Queue mlfq[NMLFQ];
#endif

void trapinithart(void)
{
    80002e50:	1141                	addi	sp,sp,-16
    80002e52:	e422                	sd	s0,8(sp)
    80002e54:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002e56:	00004797          	auipc	a5,0x4
    80002e5a:	9aa78793          	addi	a5,a5,-1622 # 80006800 <kernelvec>
    80002e5e:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002e62:	6422                	ld	s0,8(sp)
    80002e64:	0141                	addi	sp,sp,16
    80002e66:	8082                	ret

0000000080002e68 <trapinit>:

void trapinit(void)
{
    80002e68:	1141                	addi	sp,sp,-16
    80002e6a:	e406                	sd	ra,8(sp)
    80002e6c:	e022                	sd	s0,0(sp)
    80002e6e:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002e70:	00005597          	auipc	a1,0x5
    80002e74:	55058593          	addi	a1,a1,1360 # 800083c0 <states.1882+0x30>
    80002e78:	00236517          	auipc	a0,0x236
    80002e7c:	df050513          	addi	a0,a0,-528 # 80238c68 <tickslock>
    80002e80:	ffffe097          	auipc	ra,0xffffe
    80002e84:	f9c080e7          	jalr	-100(ra) # 80000e1c <initlock>
}
    80002e88:	60a2                	ld	ra,8(sp)
    80002e8a:	6402                	ld	s0,0(sp)
    80002e8c:	0141                	addi	sp,sp,16
    80002e8e:	8082                	ret

0000000080002e90 <usertrapret>:

//
// return to user space
//
void usertrapret(void)
{
    80002e90:	1141                	addi	sp,sp,-16
    80002e92:	e406                	sd	ra,8(sp)
    80002e94:	e022                	sd	s0,0(sp)
    80002e96:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002e98:	fffff097          	auipc	ra,0xfffff
    80002e9c:	e62080e7          	jalr	-414(ra) # 80001cfa <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002ea0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80002ea4:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ea6:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to uservec in trampoline.S
  uint64 trampoline_uservec = TRAMPOLINE + (uservec - trampoline);
    80002eaa:	00004617          	auipc	a2,0x4
    80002eae:	15660613          	addi	a2,a2,342 # 80007000 <_trampoline>
    80002eb2:	00004697          	auipc	a3,0x4
    80002eb6:	14e68693          	addi	a3,a3,334 # 80007000 <_trampoline>
    80002eba:	8e91                	sub	a3,a3,a2
    80002ebc:	040007b7          	lui	a5,0x4000
    80002ec0:	17fd                	addi	a5,a5,-1
    80002ec2:	07b2                	slli	a5,a5,0xc
    80002ec4:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002ec6:	10569073          	csrw	stvec,a3
  w_stvec(trampoline_uservec);

  // set up trapframe values that uservec will need when
  // the process next traps into the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    80002eca:	7138                	ld	a4,96(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    80002ecc:	180026f3          	csrr	a3,satp
    80002ed0:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    80002ed2:	7138                	ld	a4,96(a0)
    80002ed4:	6534                	ld	a3,72(a0)
    80002ed6:	6585                	lui	a1,0x1
    80002ed8:	96ae                	add	a3,a3,a1
    80002eda:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    80002edc:	7138                	ld	a4,96(a0)
    80002ede:	00000697          	auipc	a3,0x0
    80002ee2:	13e68693          	addi	a3,a3,318 # 8000301c <usertrap>
    80002ee6:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp(); // hartid for cpuid()
    80002ee8:	7138                	ld	a4,96(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    80002eea:	8692                	mv	a3,tp
    80002eec:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002eee:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.

  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    80002ef2:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    80002ef6:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002efa:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    80002efe:	7138                	ld	a4,96(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002f00:	6f18                	ld	a4,24(a4)
    80002f02:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002f06:	6d28                	ld	a0,88(a0)
    80002f08:	8131                	srli	a0,a0,0xc

  // jump to userret in trampoline.S at the top of memory, which
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 trampoline_userret = TRAMPOLINE + (userret - trampoline);
    80002f0a:	00004717          	auipc	a4,0x4
    80002f0e:	19270713          	addi	a4,a4,402 # 8000709c <userret>
    80002f12:	8f11                	sub	a4,a4,a2
    80002f14:	97ba                	add	a5,a5,a4
  ((void (*)(uint64))trampoline_userret)(satp);
    80002f16:	577d                	li	a4,-1
    80002f18:	177e                	slli	a4,a4,0x3f
    80002f1a:	8d59                	or	a0,a0,a4
    80002f1c:	9782                	jalr	a5
}
    80002f1e:	60a2                	ld	ra,8(sp)
    80002f20:	6402                	ld	s0,0(sp)
    80002f22:	0141                	addi	sp,sp,16
    80002f24:	8082                	ret

0000000080002f26 <clockintr>:
  w_sepc(sepc);
  w_sstatus(sstatus);
}

void clockintr()
{
    80002f26:	1101                	addi	sp,sp,-32
    80002f28:	ec06                	sd	ra,24(sp)
    80002f2a:	e822                	sd	s0,16(sp)
    80002f2c:	e426                	sd	s1,8(sp)
    80002f2e:	e04a                	sd	s2,0(sp)
    80002f30:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002f32:	00236917          	auipc	s2,0x236
    80002f36:	d3690913          	addi	s2,s2,-714 # 80238c68 <tickslock>
    80002f3a:	854a                	mv	a0,s2
    80002f3c:	ffffe097          	auipc	ra,0xffffe
    80002f40:	f70080e7          	jalr	-144(ra) # 80000eac <acquire>
  ticks++;
    80002f44:	00006497          	auipc	s1,0x6
    80002f48:	ba448493          	addi	s1,s1,-1116 # 80008ae8 <ticks>
    80002f4c:	409c                	lw	a5,0(s1)
    80002f4e:	2785                	addiw	a5,a5,1
    80002f50:	c09c                	sw	a5,0(s1)
  update_time();
    80002f52:	00000097          	auipc	ra,0x0
    80002f56:	e36080e7          	jalr	-458(ra) # 80002d88 <update_time>
  wakeup(&ticks);
    80002f5a:	8526                	mv	a0,s1
    80002f5c:	fffff097          	auipc	ra,0xfffff
    80002f60:	766080e7          	jalr	1894(ra) # 800026c2 <wakeup>
  release(&tickslock);
    80002f64:	854a                	mv	a0,s2
    80002f66:	ffffe097          	auipc	ra,0xffffe
    80002f6a:	ffa080e7          	jalr	-6(ra) # 80000f60 <release>
}
    80002f6e:	60e2                	ld	ra,24(sp)
    80002f70:	6442                	ld	s0,16(sp)
    80002f72:	64a2                	ld	s1,8(sp)
    80002f74:	6902                	ld	s2,0(sp)
    80002f76:	6105                	addi	sp,sp,32
    80002f78:	8082                	ret

0000000080002f7a <devintr>:
// and handle it.
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int devintr()
{
    80002f7a:	1101                	addi	sp,sp,-32
    80002f7c:	ec06                	sd	ra,24(sp)
    80002f7e:	e822                	sd	s0,16(sp)
    80002f80:	e426                	sd	s1,8(sp)
    80002f82:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002f84:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if ((scause & 0x8000000000000000L) &&
    80002f88:	00074d63          	bltz	a4,80002fa2 <devintr+0x28>
    if (irq)
      plic_complete(irq);

    return 1;
  }
  else if (scause == 0x8000000000000001L)
    80002f8c:	57fd                	li	a5,-1
    80002f8e:	17fe                	slli	a5,a5,0x3f
    80002f90:	0785                	addi	a5,a5,1

    return 2;
  }
  else
  {
    return 0;
    80002f92:	4501                	li	a0,0
  else if (scause == 0x8000000000000001L)
    80002f94:	06f70363          	beq	a4,a5,80002ffa <devintr+0x80>
  }
}
    80002f98:	60e2                	ld	ra,24(sp)
    80002f9a:	6442                	ld	s0,16(sp)
    80002f9c:	64a2                	ld	s1,8(sp)
    80002f9e:	6105                	addi	sp,sp,32
    80002fa0:	8082                	ret
      (scause & 0xff) == 9)
    80002fa2:	0ff77793          	andi	a5,a4,255
  if ((scause & 0x8000000000000000L) &&
    80002fa6:	46a5                	li	a3,9
    80002fa8:	fed792e3          	bne	a5,a3,80002f8c <devintr+0x12>
    int irq = plic_claim();
    80002fac:	00004097          	auipc	ra,0x4
    80002fb0:	95c080e7          	jalr	-1700(ra) # 80006908 <plic_claim>
    80002fb4:	84aa                	mv	s1,a0
    if (irq == UART0_IRQ)
    80002fb6:	47a9                	li	a5,10
    80002fb8:	02f50763          	beq	a0,a5,80002fe6 <devintr+0x6c>
    else if (irq == VIRTIO0_IRQ)
    80002fbc:	4785                	li	a5,1
    80002fbe:	02f50963          	beq	a0,a5,80002ff0 <devintr+0x76>
    return 1;
    80002fc2:	4505                	li	a0,1
    else if (irq)
    80002fc4:	d8f1                	beqz	s1,80002f98 <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    80002fc6:	85a6                	mv	a1,s1
    80002fc8:	00005517          	auipc	a0,0x5
    80002fcc:	40050513          	addi	a0,a0,1024 # 800083c8 <states.1882+0x38>
    80002fd0:	ffffd097          	auipc	ra,0xffffd
    80002fd4:	5be080e7          	jalr	1470(ra) # 8000058e <printf>
      plic_complete(irq);
    80002fd8:	8526                	mv	a0,s1
    80002fda:	00004097          	auipc	ra,0x4
    80002fde:	952080e7          	jalr	-1710(ra) # 8000692c <plic_complete>
    return 1;
    80002fe2:	4505                	li	a0,1
    80002fe4:	bf55                	j	80002f98 <devintr+0x1e>
      uartintr();
    80002fe6:	ffffe097          	auipc	ra,0xffffe
    80002fea:	9c8080e7          	jalr	-1592(ra) # 800009ae <uartintr>
    80002fee:	b7ed                	j	80002fd8 <devintr+0x5e>
      virtio_disk_intr();
    80002ff0:	00004097          	auipc	ra,0x4
    80002ff4:	e66080e7          	jalr	-410(ra) # 80006e56 <virtio_disk_intr>
    80002ff8:	b7c5                	j	80002fd8 <devintr+0x5e>
    if (cpuid() == 0)
    80002ffa:	fffff097          	auipc	ra,0xfffff
    80002ffe:	cce080e7          	jalr	-818(ra) # 80001cc8 <cpuid>
    80003002:	c901                	beqz	a0,80003012 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    80003004:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    80003008:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    8000300a:	14479073          	csrw	sip,a5
    return 2;
    8000300e:	4509                	li	a0,2
    80003010:	b761                	j	80002f98 <devintr+0x1e>
      clockintr();
    80003012:	00000097          	auipc	ra,0x0
    80003016:	f14080e7          	jalr	-236(ra) # 80002f26 <clockintr>
    8000301a:	b7ed                	j	80003004 <devintr+0x8a>

000000008000301c <usertrap>:
{
    8000301c:	1101                	addi	sp,sp,-32
    8000301e:	ec06                	sd	ra,24(sp)
    80003020:	e822                	sd	s0,16(sp)
    80003022:	e426                	sd	s1,8(sp)
    80003024:	e04a                	sd	s2,0(sp)
    80003026:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    80003028:	fffff097          	auipc	ra,0xfffff
    8000302c:	cd2080e7          	jalr	-814(ra) # 80001cfa <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80003030:	100027f3          	csrr	a5,sstatus
  if ((r_sstatus() & SSTATUS_SPP) != 0)
    80003034:	1007f793          	andi	a5,a5,256
    80003038:	e3bd                	bnez	a5,8000309e <usertrap+0x82>
    8000303a:	84aa                	mv	s1,a0
  asm volatile("csrw stvec, %0" : : "r" (x));
    8000303c:	00003797          	auipc	a5,0x3
    80003040:	7c478793          	addi	a5,a5,1988 # 80006800 <kernelvec>
    80003044:	10579073          	csrw	stvec,a5
  p->trapframe->epc = r_sepc();
    80003048:	713c                	ld	a5,96(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    8000304a:	14102773          	csrr	a4,sepc
    8000304e:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003050:	14202773          	csrr	a4,scause
  if (r_scause() == 8)
    80003054:	47a1                	li	a5,8
    80003056:	04f70c63          	beq	a4,a5,800030ae <usertrap+0x92>
  else if ((which_dev = devintr()) != 0)
    8000305a:	00000097          	auipc	ra,0x0
    8000305e:	f20080e7          	jalr	-224(ra) # 80002f7a <devintr>
    80003062:	892a                	mv	s2,a0
    80003064:	e979                	bnez	a0,8000313a <usertrap+0x11e>
    80003066:	14202773          	csrr	a4,scause
  else if (r_scause() == 15 || r_scause() == 13)
    8000306a:	47bd                	li	a5,15
    8000306c:	00f70763          	beq	a4,a5,8000307a <usertrap+0x5e>
    80003070:	14202773          	csrr	a4,scause
    80003074:	47b5                	li	a5,13
    80003076:	08f71563          	bne	a4,a5,80003100 <usertrap+0xe4>
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000307a:	143027f3          	csrr	a5,stval
    if (r_stval() == 0)
    8000307e:	e399                	bnez	a5,80003084 <usertrap+0x68>
      p->killed = 1;
    80003080:	4785                	li	a5,1
    80003082:	d49c                	sw	a5,40(s1)
    80003084:	14302573          	csrr	a0,stval
    int res = page_fault_handler((void *)r_stval(), p->pagetable);
    80003088:	6cac                	ld	a1,88(s1)
    8000308a:	ffffe097          	auipc	ra,0xffffe
    8000308e:	cd4080e7          	jalr	-812(ra) # 80000d5e <page_fault_handler>
    if (res == -1 || res == -2)
    80003092:	2509                	addiw	a0,a0,2
    80003094:	4785                	li	a5,1
    80003096:	02a7ef63          	bltu	a5,a0,800030d4 <usertrap+0xb8>
      p->killed = 1;
    8000309a:	d49c                	sw	a5,40(s1)
    8000309c:	a825                	j	800030d4 <usertrap+0xb8>
    panic("usertrap: not from user mode");
    8000309e:	00005517          	auipc	a0,0x5
    800030a2:	34a50513          	addi	a0,a0,842 # 800083e8 <states.1882+0x58>
    800030a6:	ffffd097          	auipc	ra,0xffffd
    800030aa:	49e080e7          	jalr	1182(ra) # 80000544 <panic>
    if (killed(p))
    800030ae:	00000097          	auipc	ra,0x0
    800030b2:	864080e7          	jalr	-1948(ra) # 80002912 <killed>
    800030b6:	ed1d                	bnez	a0,800030f4 <usertrap+0xd8>
    p->trapframe->epc += 4;
    800030b8:	70b8                	ld	a4,96(s1)
    800030ba:	6f1c                	ld	a5,24(a4)
    800030bc:	0791                	addi	a5,a5,4
    800030be:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800030c0:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    800030c4:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800030c8:	10079073          	csrw	sstatus,a5
    syscall();
    800030cc:	00000097          	auipc	ra,0x0
    800030d0:	340080e7          	jalr	832(ra) # 8000340c <syscall>
  if (killed(p))
    800030d4:	8526                	mv	a0,s1
    800030d6:	00000097          	auipc	ra,0x0
    800030da:	83c080e7          	jalr	-1988(ra) # 80002912 <killed>
    800030de:	e52d                	bnez	a0,80003148 <usertrap+0x12c>
  usertrapret();
    800030e0:	00000097          	auipc	ra,0x0
    800030e4:	db0080e7          	jalr	-592(ra) # 80002e90 <usertrapret>
}
    800030e8:	60e2                	ld	ra,24(sp)
    800030ea:	6442                	ld	s0,16(sp)
    800030ec:	64a2                	ld	s1,8(sp)
    800030ee:	6902                	ld	s2,0(sp)
    800030f0:	6105                	addi	sp,sp,32
    800030f2:	8082                	ret
      exit(-1);
    800030f4:	557d                	li	a0,-1
    800030f6:	fffff097          	auipc	ra,0xfffff
    800030fa:	69c080e7          	jalr	1692(ra) # 80002792 <exit>
    800030fe:	bf6d                	j	800030b8 <usertrap+0x9c>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80003100:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80003104:	5890                	lw	a2,48(s1)
    80003106:	00005517          	auipc	a0,0x5
    8000310a:	30250513          	addi	a0,a0,770 # 80008408 <states.1882+0x78>
    8000310e:	ffffd097          	auipc	ra,0xffffd
    80003112:	480080e7          	jalr	1152(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003116:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    8000311a:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000311e:	00005517          	auipc	a0,0x5
    80003122:	31a50513          	addi	a0,a0,794 # 80008438 <states.1882+0xa8>
    80003126:	ffffd097          	auipc	ra,0xffffd
    8000312a:	468080e7          	jalr	1128(ra) # 8000058e <printf>
    setkilled(p);
    8000312e:	8526                	mv	a0,s1
    80003130:	fffff097          	auipc	ra,0xfffff
    80003134:	7b6080e7          	jalr	1974(ra) # 800028e6 <setkilled>
    80003138:	bf71                	j	800030d4 <usertrap+0xb8>
  if (killed(p))
    8000313a:	8526                	mv	a0,s1
    8000313c:	fffff097          	auipc	ra,0xfffff
    80003140:	7d6080e7          	jalr	2006(ra) # 80002912 <killed>
    80003144:	c901                	beqz	a0,80003154 <usertrap+0x138>
    80003146:	a011                	j	8000314a <usertrap+0x12e>
    80003148:	4901                	li	s2,0
    exit(-1);
    8000314a:	557d                	li	a0,-1
    8000314c:	fffff097          	auipc	ra,0xfffff
    80003150:	646080e7          	jalr	1606(ra) # 80002792 <exit>
  if (which_dev == 2)
    80003154:	4789                	li	a5,2
    80003156:	f8f915e3          	bne	s2,a5,800030e0 <usertrap+0xc4>
    p->now_ticks += 1;
    8000315a:	1784a783          	lw	a5,376(s1)
    8000315e:	2785                	addiw	a5,a5,1
    80003160:	0007871b          	sext.w	a4,a5
    80003164:	16f4ac23          	sw	a5,376(s1)
    if (p->ticks > 0 && p->now_ticks >= p->ticks && !p->is_sigalarm)
    80003168:	1744a783          	lw	a5,372(s1)
    8000316c:	04f05663          	blez	a5,800031b8 <usertrap+0x19c>
    80003170:	04f74463          	blt	a4,a5,800031b8 <usertrap+0x19c>
    80003174:	1704a783          	lw	a5,368(s1)
    80003178:	e3a1                	bnez	a5,800031b8 <usertrap+0x19c>
      p->now_ticks = 0;
    8000317a:	1604ac23          	sw	zero,376(s1)
      p->is_sigalarm = 1;
    8000317e:	4785                	li	a5,1
    80003180:	16f4a823          	sw	a5,368(s1)
      *(p->trapframe_copy) = *(p->trapframe);
    80003184:	70b4                	ld	a3,96(s1)
    80003186:	87b6                	mv	a5,a3
    80003188:	1884b703          	ld	a4,392(s1)
    8000318c:	12068693          	addi	a3,a3,288
    80003190:	0007b803          	ld	a6,0(a5)
    80003194:	6788                	ld	a0,8(a5)
    80003196:	6b8c                	ld	a1,16(a5)
    80003198:	6f90                	ld	a2,24(a5)
    8000319a:	01073023          	sd	a6,0(a4)
    8000319e:	e708                	sd	a0,8(a4)
    800031a0:	eb0c                	sd	a1,16(a4)
    800031a2:	ef10                	sd	a2,24(a4)
    800031a4:	02078793          	addi	a5,a5,32
    800031a8:	02070713          	addi	a4,a4,32
    800031ac:	fed792e3          	bne	a5,a3,80003190 <usertrap+0x174>
      p->trapframe->epc = p->handler;
    800031b0:	70bc                	ld	a5,96(s1)
    800031b2:	1804b703          	ld	a4,384(s1)
    800031b6:	ef98                	sd	a4,24(a5)
    yield();
    800031b8:	fffff097          	auipc	ra,0xfffff
    800031bc:	46a080e7          	jalr	1130(ra) # 80002622 <yield>
    800031c0:	b705                	j	800030e0 <usertrap+0xc4>

00000000800031c2 <kerneltrap>:
{
    800031c2:	7179                	addi	sp,sp,-48
    800031c4:	f406                	sd	ra,40(sp)
    800031c6:	f022                	sd	s0,32(sp)
    800031c8:	ec26                	sd	s1,24(sp)
    800031ca:	e84a                	sd	s2,16(sp)
    800031cc:	e44e                	sd	s3,8(sp)
    800031ce:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    800031d0:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800031d4:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    800031d8:	142029f3          	csrr	s3,scause
  if ((sstatus & SSTATUS_SPP) == 0)
    800031dc:	1004f793          	andi	a5,s1,256
    800031e0:	cb85                	beqz	a5,80003210 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800031e2:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    800031e6:	8b89                	andi	a5,a5,2
  if (intr_get() != 0)
    800031e8:	ef85                	bnez	a5,80003220 <kerneltrap+0x5e>
  if ((which_dev = devintr()) == 0)
    800031ea:	00000097          	auipc	ra,0x0
    800031ee:	d90080e7          	jalr	-624(ra) # 80002f7a <devintr>
    800031f2:	cd1d                	beqz	a0,80003230 <kerneltrap+0x6e>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    800031f4:	4789                	li	a5,2
    800031f6:	06f50a63          	beq	a0,a5,8000326a <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    800031fa:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800031fe:	10049073          	csrw	sstatus,s1
}
    80003202:	70a2                	ld	ra,40(sp)
    80003204:	7402                	ld	s0,32(sp)
    80003206:	64e2                	ld	s1,24(sp)
    80003208:	6942                	ld	s2,16(sp)
    8000320a:	69a2                	ld	s3,8(sp)
    8000320c:	6145                	addi	sp,sp,48
    8000320e:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80003210:	00005517          	auipc	a0,0x5
    80003214:	24850513          	addi	a0,a0,584 # 80008458 <states.1882+0xc8>
    80003218:	ffffd097          	auipc	ra,0xffffd
    8000321c:	32c080e7          	jalr	812(ra) # 80000544 <panic>
    panic("kerneltrap: interrupts enabled");
    80003220:	00005517          	auipc	a0,0x5
    80003224:	26050513          	addi	a0,a0,608 # 80008480 <states.1882+0xf0>
    80003228:	ffffd097          	auipc	ra,0xffffd
    8000322c:	31c080e7          	jalr	796(ra) # 80000544 <panic>
    printf("scause %p\n", scause);
    80003230:	85ce                	mv	a1,s3
    80003232:	00005517          	auipc	a0,0x5
    80003236:	26e50513          	addi	a0,a0,622 # 800084a0 <states.1882+0x110>
    8000323a:	ffffd097          	auipc	ra,0xffffd
    8000323e:	354080e7          	jalr	852(ra) # 8000058e <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80003242:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80003246:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    8000324a:	00005517          	auipc	a0,0x5
    8000324e:	26650513          	addi	a0,a0,614 # 800084b0 <states.1882+0x120>
    80003252:	ffffd097          	auipc	ra,0xffffd
    80003256:	33c080e7          	jalr	828(ra) # 8000058e <printf>
    panic("kerneltrap");
    8000325a:	00005517          	auipc	a0,0x5
    8000325e:	26e50513          	addi	a0,a0,622 # 800084c8 <states.1882+0x138>
    80003262:	ffffd097          	auipc	ra,0xffffd
    80003266:	2e2080e7          	jalr	738(ra) # 80000544 <panic>
  if (which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    8000326a:	fffff097          	auipc	ra,0xfffff
    8000326e:	a90080e7          	jalr	-1392(ra) # 80001cfa <myproc>
    80003272:	d541                	beqz	a0,800031fa <kerneltrap+0x38>
    80003274:	fffff097          	auipc	ra,0xfffff
    80003278:	a86080e7          	jalr	-1402(ra) # 80001cfa <myproc>
    8000327c:	4d18                	lw	a4,24(a0)
    8000327e:	4791                	li	a5,4
    80003280:	f6f71de3          	bne	a4,a5,800031fa <kerneltrap+0x38>
    yield();
    80003284:	fffff097          	auipc	ra,0xfffff
    80003288:	39e080e7          	jalr	926(ra) # 80002622 <yield>
    8000328c:	b7bd                	j	800031fa <kerneltrap+0x38>

000000008000328e <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    8000328e:	1101                	addi	sp,sp,-32
    80003290:	ec06                	sd	ra,24(sp)
    80003292:	e822                	sd	s0,16(sp)
    80003294:	e426                	sd	s1,8(sp)
    80003296:	1000                	addi	s0,sp,32
    80003298:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    8000329a:	fffff097          	auipc	ra,0xfffff
    8000329e:	a60080e7          	jalr	-1440(ra) # 80001cfa <myproc>
  switch (n) {
    800032a2:	4795                	li	a5,5
    800032a4:	0497e163          	bltu	a5,s1,800032e6 <argraw+0x58>
    800032a8:	048a                	slli	s1,s1,0x2
    800032aa:	00005717          	auipc	a4,0x5
    800032ae:	36670713          	addi	a4,a4,870 # 80008610 <states.1882+0x280>
    800032b2:	94ba                	add	s1,s1,a4
    800032b4:	409c                	lw	a5,0(s1)
    800032b6:	97ba                	add	a5,a5,a4
    800032b8:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    800032ba:	713c                	ld	a5,96(a0)
    800032bc:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    800032be:	60e2                	ld	ra,24(sp)
    800032c0:	6442                	ld	s0,16(sp)
    800032c2:	64a2                	ld	s1,8(sp)
    800032c4:	6105                	addi	sp,sp,32
    800032c6:	8082                	ret
    return p->trapframe->a1;
    800032c8:	713c                	ld	a5,96(a0)
    800032ca:	7fa8                	ld	a0,120(a5)
    800032cc:	bfcd                	j	800032be <argraw+0x30>
    return p->trapframe->a2;
    800032ce:	713c                	ld	a5,96(a0)
    800032d0:	63c8                	ld	a0,128(a5)
    800032d2:	b7f5                	j	800032be <argraw+0x30>
    return p->trapframe->a3;
    800032d4:	713c                	ld	a5,96(a0)
    800032d6:	67c8                	ld	a0,136(a5)
    800032d8:	b7dd                	j	800032be <argraw+0x30>
    return p->trapframe->a4;
    800032da:	713c                	ld	a5,96(a0)
    800032dc:	6bc8                	ld	a0,144(a5)
    800032de:	b7c5                	j	800032be <argraw+0x30>
    return p->trapframe->a5;
    800032e0:	713c                	ld	a5,96(a0)
    800032e2:	6fc8                	ld	a0,152(a5)
    800032e4:	bfe9                	j	800032be <argraw+0x30>
  panic("argraw");
    800032e6:	00005517          	auipc	a0,0x5
    800032ea:	1f250513          	addi	a0,a0,498 # 800084d8 <states.1882+0x148>
    800032ee:	ffffd097          	auipc	ra,0xffffd
    800032f2:	256080e7          	jalr	598(ra) # 80000544 <panic>

00000000800032f6 <fetchaddr>:
{
    800032f6:	1101                	addi	sp,sp,-32
    800032f8:	ec06                	sd	ra,24(sp)
    800032fa:	e822                	sd	s0,16(sp)
    800032fc:	e426                	sd	s1,8(sp)
    800032fe:	e04a                	sd	s2,0(sp)
    80003300:	1000                	addi	s0,sp,32
    80003302:	84aa                	mv	s1,a0
    80003304:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80003306:	fffff097          	auipc	ra,0xfffff
    8000330a:	9f4080e7          	jalr	-1548(ra) # 80001cfa <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz) // both tests needed, in case of overflow
    8000330e:	693c                	ld	a5,80(a0)
    80003310:	02f4f863          	bgeu	s1,a5,80003340 <fetchaddr+0x4a>
    80003314:	00848713          	addi	a4,s1,8
    80003318:	02e7e663          	bltu	a5,a4,80003344 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    8000331c:	46a1                	li	a3,8
    8000331e:	8626                	mv	a2,s1
    80003320:	85ca                	mv	a1,s2
    80003322:	6d28                	ld	a0,88(a0)
    80003324:	ffffe097          	auipc	ra,0xffffe
    80003328:	6ea080e7          	jalr	1770(ra) # 80001a0e <copyin>
    8000332c:	00a03533          	snez	a0,a0
    80003330:	40a00533          	neg	a0,a0
}
    80003334:	60e2                	ld	ra,24(sp)
    80003336:	6442                	ld	s0,16(sp)
    80003338:	64a2                	ld	s1,8(sp)
    8000333a:	6902                	ld	s2,0(sp)
    8000333c:	6105                	addi	sp,sp,32
    8000333e:	8082                	ret
    return -1;
    80003340:	557d                	li	a0,-1
    80003342:	bfcd                	j	80003334 <fetchaddr+0x3e>
    80003344:	557d                	li	a0,-1
    80003346:	b7fd                	j	80003334 <fetchaddr+0x3e>

0000000080003348 <fetchstr>:
{
    80003348:	7179                	addi	sp,sp,-48
    8000334a:	f406                	sd	ra,40(sp)
    8000334c:	f022                	sd	s0,32(sp)
    8000334e:	ec26                	sd	s1,24(sp)
    80003350:	e84a                	sd	s2,16(sp)
    80003352:	e44e                	sd	s3,8(sp)
    80003354:	1800                	addi	s0,sp,48
    80003356:	892a                	mv	s2,a0
    80003358:	84ae                	mv	s1,a1
    8000335a:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    8000335c:	fffff097          	auipc	ra,0xfffff
    80003360:	99e080e7          	jalr	-1634(ra) # 80001cfa <myproc>
  if(copyinstr(p->pagetable, buf, addr, max) < 0)
    80003364:	86ce                	mv	a3,s3
    80003366:	864a                	mv	a2,s2
    80003368:	85a6                	mv	a1,s1
    8000336a:	6d28                	ld	a0,88(a0)
    8000336c:	ffffe097          	auipc	ra,0xffffe
    80003370:	72e080e7          	jalr	1838(ra) # 80001a9a <copyinstr>
    80003374:	00054e63          	bltz	a0,80003390 <fetchstr+0x48>
  return strlen(buf);
    80003378:	8526                	mv	a0,s1
    8000337a:	ffffe097          	auipc	ra,0xffffe
    8000337e:	db2080e7          	jalr	-590(ra) # 8000112c <strlen>
}
    80003382:	70a2                	ld	ra,40(sp)
    80003384:	7402                	ld	s0,32(sp)
    80003386:	64e2                	ld	s1,24(sp)
    80003388:	6942                	ld	s2,16(sp)
    8000338a:	69a2                	ld	s3,8(sp)
    8000338c:	6145                	addi	sp,sp,48
    8000338e:	8082                	ret
    return -1;
    80003390:	557d                	li	a0,-1
    80003392:	bfc5                	j	80003382 <fetchstr+0x3a>

0000000080003394 <argint>:

// Fetch the nth 32-bit system call argument.
void
argint(int n, int *ip)
{
    80003394:	1101                	addi	sp,sp,-32
    80003396:	ec06                	sd	ra,24(sp)
    80003398:	e822                	sd	s0,16(sp)
    8000339a:	e426                	sd	s1,8(sp)
    8000339c:	1000                	addi	s0,sp,32
    8000339e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800033a0:	00000097          	auipc	ra,0x0
    800033a4:	eee080e7          	jalr	-274(ra) # 8000328e <argraw>
    800033a8:	c088                	sw	a0,0(s1)
}
    800033aa:	60e2                	ld	ra,24(sp)
    800033ac:	6442                	ld	s0,16(sp)
    800033ae:	64a2                	ld	s1,8(sp)
    800033b0:	6105                	addi	sp,sp,32
    800033b2:	8082                	ret

00000000800033b4 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
void
argaddr(int n, uint64 *ip)
{
    800033b4:	1101                	addi	sp,sp,-32
    800033b6:	ec06                	sd	ra,24(sp)
    800033b8:	e822                	sd	s0,16(sp)
    800033ba:	e426                	sd	s1,8(sp)
    800033bc:	1000                	addi	s0,sp,32
    800033be:	84ae                	mv	s1,a1
  *ip = argraw(n);
    800033c0:	00000097          	auipc	ra,0x0
    800033c4:	ece080e7          	jalr	-306(ra) # 8000328e <argraw>
    800033c8:	e088                	sd	a0,0(s1)
}
    800033ca:	60e2                	ld	ra,24(sp)
    800033cc:	6442                	ld	s0,16(sp)
    800033ce:	64a2                	ld	s1,8(sp)
    800033d0:	6105                	addi	sp,sp,32
    800033d2:	8082                	ret

00000000800033d4 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    800033d4:	7179                	addi	sp,sp,-48
    800033d6:	f406                	sd	ra,40(sp)
    800033d8:	f022                	sd	s0,32(sp)
    800033da:	ec26                	sd	s1,24(sp)
    800033dc:	e84a                	sd	s2,16(sp)
    800033de:	1800                	addi	s0,sp,48
    800033e0:	84ae                	mv	s1,a1
    800033e2:	8932                	mv	s2,a2
  uint64 addr;
  argaddr(n, &addr);
    800033e4:	fd840593          	addi	a1,s0,-40
    800033e8:	00000097          	auipc	ra,0x0
    800033ec:	fcc080e7          	jalr	-52(ra) # 800033b4 <argaddr>
  return fetchstr(addr, buf, max);
    800033f0:	864a                	mv	a2,s2
    800033f2:	85a6                	mv	a1,s1
    800033f4:	fd843503          	ld	a0,-40(s0)
    800033f8:	00000097          	auipc	ra,0x0
    800033fc:	f50080e7          	jalr	-176(ra) # 80003348 <fetchstr>
}
    80003400:	70a2                	ld	ra,40(sp)
    80003402:	7402                	ld	s0,32(sp)
    80003404:	64e2                	ld	s1,24(sp)
    80003406:	6942                	ld	s2,16(sp)
    80003408:	6145                	addi	sp,sp,48
    8000340a:	8082                	ret

000000008000340c <syscall>:
[SYS_waitx] sys_waitx,
};

void
syscall(void)
{
    8000340c:	7139                	addi	sp,sp,-64
    8000340e:	fc06                	sd	ra,56(sp)
    80003410:	f822                	sd	s0,48(sp)
    80003412:	f426                	sd	s1,40(sp)
    80003414:	f04a                	sd	s2,32(sp)
    80003416:	ec4e                	sd	s3,24(sp)
    80003418:	e852                	sd	s4,16(sp)
    8000341a:	e456                	sd	s5,8(sp)
    8000341c:	e05a                	sd	s6,0(sp)
    8000341e:	0080                	addi	s0,sp,64

arguments[1]=0;
    80003420:	00236797          	auipc	a5,0x236
    80003424:	86078793          	addi	a5,a5,-1952 # 80238c80 <arguments>
    80003428:	0007a223          	sw	zero,4(a5)
arguments[2]=1;
    8000342c:	4705                	li	a4,1
    8000342e:	c798                	sw	a4,8(a5)
arguments[3]=1;
    80003430:	c7d8                	sw	a4,12(a5)
arguments[4]=0;
    80003432:	0007a823          	sw	zero,16(a5)
arguments[5]=3;
    80003436:	460d                	li	a2,3
    80003438:	cbd0                	sw	a2,20(a5)
arguments[6]=2;
    8000343a:	4689                	li	a3,2
    8000343c:	cf94                	sw	a3,24(a5)
arguments[7]=2;
    8000343e:	cfd4                	sw	a3,28(a5)
arguments[8]=1;
    80003440:	d398                	sw	a4,32(a5)
arguments[9]=1;
    80003442:	d3d8                	sw	a4,36(a5)
arguments[10]=1;
    80003444:	d798                	sw	a4,40(a5)
arguments[11]=0;
    80003446:	0207a623          	sw	zero,44(a5)
arguments[12]=1;
    8000344a:	db98                	sw	a4,48(a5)
arguments[13]=1;
    8000344c:	dbd8                	sw	a4,52(a5)
arguments[14]=0;
    8000344e:	0207ac23          	sw	zero,56(a5)
arguments[15]=2;
    80003452:	dfd4                	sw	a3,60(a5)
arguments[16]=3;
    80003454:	c3b0                	sw	a2,64(a5)
arguments[17]=3;
    80003456:	c3f0                	sw	a2,68(a5)
arguments[18]=1;
    80003458:	c7b8                	sw	a4,72(a5)
arguments[19]=2;
    8000345a:	c7f4                	sw	a3,76(a5)
arguments[20]=1;
    8000345c:	cbb8                	sw	a4,80(a5)
arguments[21]=1;
    8000345e:	cbf8                	sw	a4,84(a5)
arguments[24]=1;
    80003460:	d3b8                	sw	a4,96(a5)
arguments[22]=2;
    80003462:	cfb4                	sw	a3,88(a5)
arguments[23]=2;
    80003464:	cff4                	sw	a3,92(a5)
arguments[25]=2;
    80003466:	d3f4                	sw	a3,100(a5)
arguments[26]=3;
    80003468:	d7b0                	sw	a2,104(a5)

char *temp;

  int num;
  struct proc *p = myproc();
    8000346a:	fffff097          	auipc	ra,0xfffff
    8000346e:	890080e7          	jalr	-1904(ra) # 80001cfa <myproc>
    80003472:	892a                	mv	s2,a0

  num = p->trapframe->a7;
    80003474:	713c                	ld	a5,96(a0)
    80003476:	77dc                	ld	a5,168(a5)
    80003478:	0007849b          	sext.w	s1,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    8000347c:	37fd                	addiw	a5,a5,-1
    8000347e:	4765                	li	a4,25
    80003480:	22f76663          	bltu	a4,a5,800036ac <syscall+0x2a0>
    80003484:	00349713          	slli	a4,s1,0x3
    80003488:	00005797          	auipc	a5,0x5
    8000348c:	1a078793          	addi	a5,a5,416 # 80008628 <syscalls>
    80003490:	97ba                	add	a5,a5,a4
    80003492:	0007ba03          	ld	s4,0(a5)
    80003496:	200a0b63          	beqz	s4,800036ac <syscall+0x2a0>
    // Use num to lookup the system call function for num, call it,
    // and store its return value in p->trapframe->a0

  if(num==1) temp="fork";
  if(num==2) temp="exit";
    8000349a:	4789                	li	a5,2
    8000349c:	0ef48963          	beq	s1,a5,8000358e <syscall+0x182>
  if(num==3) temp="wait";
    800034a0:	478d                	li	a5,3
    800034a2:	00005997          	auipc	s3,0x5
    800034a6:	04e98993          	addi	s3,s3,78 # 800084f0 <states.1882+0x160>
    800034aa:	06f49463          	bne	s1,a5,80003512 <syscall+0x106>
  if(num==4) temp="pipe";
  if(num==5) temp="read";
  if(num==6) temp="kill";
    800034ae:	4799                	li	a5,6
    800034b0:	06f49863          	bne	s1,a5,80003520 <syscall+0x114>
    800034b4:	00005997          	auipc	s3,0x5
    800034b8:	04c98993          	addi	s3,s3,76 # 80008500 <states.1882+0x170>
  if(num==7) temp="exec";
  if(num==8) temp="fstat";
  if(num==9) temp="chdir";
    800034bc:	47a5                	li	a5,9
    800034be:	06f49863          	bne	s1,a5,8000352e <syscall+0x122>
    800034c2:	00005997          	auipc	s3,0x5
    800034c6:	05698993          	addi	s3,s3,86 # 80008518 <states.1882+0x188>
  if(num==10) temp="dup";
  if(num==11) temp="getpid";
  if(num==12) temp="sbrk";
    800034ca:	47b1                	li	a5,12
    800034cc:	06f49863          	bne	s1,a5,8000353c <syscall+0x130>
    800034d0:	00005997          	auipc	s3,0x5
    800034d4:	06098993          	addi	s3,s3,96 # 80008530 <states.1882+0x1a0>
  if(num==13) temp="sleep";
  if(num==14) temp="uptime";
  if(num==15) temp="open";
    800034d8:	47bd                	li	a5,15
    800034da:	06f49863          	bne	s1,a5,8000354a <syscall+0x13e>
    800034de:	00005997          	auipc	s3,0x5
    800034e2:	06a98993          	addi	s3,s3,106 # 80008548 <states.1882+0x1b8>
  if(num==16) temp="write";
  if(num==17) temp="mknod";
  if(num==18) temp="unlink";
    800034e6:	47c9                	li	a5,18
    800034e8:	06f49863          	bne	s1,a5,80003558 <syscall+0x14c>
    800034ec:	00005997          	auipc	s3,0x5
    800034f0:	07498993          	addi	s3,s3,116 # 80008560 <states.1882+0x1d0>
  if(num==19) temp="link";
  if(num==20) temp="mkdir";
  if(num==21) temp="close";
    800034f4:	47d5                	li	a5,21
    800034f6:	06f49863          	bne	s1,a5,80003566 <syscall+0x15a>
    800034fa:	00005997          	auipc	s3,0x5
    800034fe:	07e98993          	addi	s3,s3,126 # 80008578 <states.1882+0x1e8>
  if(num==22) temp="sigalarm";
  if(num==23) temp="sigreturn";
  if(num==24) temp="trace";
    80003502:	47e1                	li	a5,24
    80003504:	06f49863          	bne	s1,a5,80003574 <syscall+0x168>
    80003508:	00005997          	auipc	s3,0x5
    8000350c:	09898993          	addi	s3,s3,152 # 800085a0 <states.1882+0x210>
    80003510:	a8dd                	j	80003606 <syscall+0x1fa>
  if(num==4) temp="pipe";
    80003512:	4791                	li	a5,4
    80003514:	00005997          	auipc	s3,0x5
    80003518:	fe498993          	addi	s3,s3,-28 # 800084f8 <states.1882+0x168>
    8000351c:	06f49463          	bne	s1,a5,80003584 <syscall+0x178>
  if(num==7) temp="exec";
    80003520:	479d                	li	a5,7
    80003522:	08f49163          	bne	s1,a5,800035a4 <syscall+0x198>
    80003526:	00005997          	auipc	s3,0x5
    8000352a:	fe298993          	addi	s3,s3,-30 # 80008508 <states.1882+0x178>
  if(num==10) temp="dup";
    8000352e:	47a9                	li	a5,10
    80003530:	08f49163          	bne	s1,a5,800035b2 <syscall+0x1a6>
    80003534:	00005997          	auipc	s3,0x5
    80003538:	fec98993          	addi	s3,s3,-20 # 80008520 <states.1882+0x190>
  if(num==13) temp="sleep";
    8000353c:	47b5                	li	a5,13
    8000353e:	08f49163          	bne	s1,a5,800035c0 <syscall+0x1b4>
    80003542:	00005997          	auipc	s3,0x5
    80003546:	ff698993          	addi	s3,s3,-10 # 80008538 <states.1882+0x1a8>
  if(num==16) temp="write";
    8000354a:	47c1                	li	a5,16
    8000354c:	08f49163          	bne	s1,a5,800035ce <syscall+0x1c2>
    80003550:	00005997          	auipc	s3,0x5
    80003554:	00098993          	mv	s3,s3
  if(num==19) temp="link";
    80003558:	47cd                	li	a5,19
    8000355a:	08f49163          	bne	s1,a5,800035dc <syscall+0x1d0>
    8000355e:	00005997          	auipc	s3,0x5
    80003562:	00a98993          	addi	s3,s3,10 # 80008568 <states.1882+0x1d8>
  if(num==22) temp="sigalarm";
    80003566:	47d9                	li	a5,22
    80003568:	08f49163          	bne	s1,a5,800035ea <syscall+0x1de>
    8000356c:	00005997          	auipc	s3,0x5
    80003570:	01498993          	addi	s3,s3,20 # 80008580 <states.1882+0x1f0>
  if(num==25) temp="set_priority";
    80003574:	47e5                	li	a5,25
    80003576:	08f49163          	bne	s1,a5,800035f8 <syscall+0x1ec>
    8000357a:	00005997          	auipc	s3,0x5
    8000357e:	02e98993          	addi	s3,s3,46 # 800085a8 <states.1882+0x218>
    80003582:	a051                	j	80003606 <syscall+0x1fa>
    80003584:	00005997          	auipc	s3,0x5
    80003588:	f6498993          	addi	s3,s3,-156 # 800084e8 <states.1882+0x158>
    8000358c:	a029                	j	80003596 <syscall+0x18a>
  if(num==2) temp="exit";
    8000358e:	00005997          	auipc	s3,0x5
    80003592:	f5298993          	addi	s3,s3,-174 # 800084e0 <states.1882+0x150>
  if(num==5) temp="read";
    80003596:	4795                	li	a5,5
    80003598:	f0f49be3          	bne	s1,a5,800034ae <syscall+0xa2>
    8000359c:	00005997          	auipc	s3,0x5
    800035a0:	28498993          	addi	s3,s3,644 # 80008820 <syscalls+0x1f8>
  if(num==8) temp="fstat";
    800035a4:	47a1                	li	a5,8
    800035a6:	f0f49be3          	bne	s1,a5,800034bc <syscall+0xb0>
    800035aa:	00005997          	auipc	s3,0x5
    800035ae:	f6698993          	addi	s3,s3,-154 # 80008510 <states.1882+0x180>
  if(num==11) temp="getpid";
    800035b2:	47ad                	li	a5,11
    800035b4:	f0f49be3          	bne	s1,a5,800034ca <syscall+0xbe>
    800035b8:	00005997          	auipc	s3,0x5
    800035bc:	f7098993          	addi	s3,s3,-144 # 80008528 <states.1882+0x198>
  if(num==14) temp="uptime";
    800035c0:	47b9                	li	a5,14
    800035c2:	f0f49be3          	bne	s1,a5,800034d8 <syscall+0xcc>
    800035c6:	00005997          	auipc	s3,0x5
    800035ca:	f7a98993          	addi	s3,s3,-134 # 80008540 <states.1882+0x1b0>
  if(num==17) temp="mknod";
    800035ce:	47c5                	li	a5,17
    800035d0:	f0f49be3          	bne	s1,a5,800034e6 <syscall+0xda>
    800035d4:	00005997          	auipc	s3,0x5
    800035d8:	f8498993          	addi	s3,s3,-124 # 80008558 <states.1882+0x1c8>
  if(num==20) temp="mkdir";
    800035dc:	47d1                	li	a5,20
    800035de:	f0f49be3          	bne	s1,a5,800034f4 <syscall+0xe8>
    800035e2:	00005997          	auipc	s3,0x5
    800035e6:	f8e98993          	addi	s3,s3,-114 # 80008570 <states.1882+0x1e0>
  if(num==23) temp="sigreturn";
    800035ea:	47dd                	li	a5,23
    800035ec:	f0f49be3          	bne	s1,a5,80003502 <syscall+0xf6>
    800035f0:	00005997          	auipc	s3,0x5
    800035f4:	fa098993          	addi	s3,s3,-96 # 80008590 <states.1882+0x200>
  if(num==26) temp="waitx";
    800035f8:	47e9                	li	a5,26
    800035fa:	00f49663          	bne	s1,a5,80003606 <syscall+0x1fa>
    800035fe:	00005997          	auipc	s3,0x5
    80003602:	fba98993          	addi	s3,s3,-70 # 800085b8 <states.1882+0x228>
  

  if(flag==1)
    80003606:	00005717          	auipc	a4,0x5
    8000360a:	4e672703          	lw	a4,1254(a4) # 80008aec <flag>
    8000360e:	4785                	li	a5,1
    80003610:	00f70863          	beq	a4,a5,80003620 <syscall+0x214>
      for(int i=0;i<arguments[num];i++)
      printf("%d ",argraw(i));
      printf(") -> %d\n",p->trapframe->a0);
    }
  }
    p->trapframe->a0 = syscalls[num]();
    80003614:	06093903          	ld	s2,96(s2)
    80003618:	9a02                	jalr	s4
    8000361a:	06a93823          	sd	a0,112(s2)
    8000361e:	a845                	j	800036ce <syscall+0x2c2>
    if(uni_mask&(1<<num))
    80003620:	00005797          	auipc	a5,0x5
    80003624:	4d07a783          	lw	a5,1232(a5) # 80008af0 <uni_mask>
    80003628:	4097d7bb          	sraw	a5,a5,s1
    8000362c:	8b85                	andi	a5,a5,1
    8000362e:	d3fd                	beqz	a5,80003614 <syscall+0x208>
      printf("%d: syscall %s ( ",sys_getpid(),temp);
    80003630:	00000097          	auipc	ra,0x0
    80003634:	0ee080e7          	jalr	238(ra) # 8000371e <sys_getpid>
    80003638:	85aa                	mv	a1,a0
    8000363a:	864e                	mv	a2,s3
    8000363c:	00005517          	auipc	a0,0x5
    80003640:	f8450513          	addi	a0,a0,-124 # 800085c0 <states.1882+0x230>
    80003644:	ffffd097          	auipc	ra,0xffffd
    80003648:	f4a080e7          	jalr	-182(ra) # 8000058e <printf>
      for(int i=0;i<arguments[num];i++)
    8000364c:	00249713          	slli	a4,s1,0x2
    80003650:	00235797          	auipc	a5,0x235
    80003654:	63078793          	addi	a5,a5,1584 # 80238c80 <arguments>
    80003658:	97ba                	add	a5,a5,a4
    8000365a:	439c                	lw	a5,0(a5)
    8000365c:	02f05c63          	blez	a5,80003694 <syscall+0x288>
    80003660:	4981                	li	s3,0
      printf("%d ",argraw(i));
    80003662:	00005b17          	auipc	s6,0x5
    80003666:	f76b0b13          	addi	s6,s6,-138 # 800085d8 <states.1882+0x248>
      for(int i=0;i<arguments[num];i++)
    8000366a:	00235a97          	auipc	s5,0x235
    8000366e:	616a8a93          	addi	s5,s5,1558 # 80238c80 <arguments>
    80003672:	9aba                	add	s5,s5,a4
      printf("%d ",argraw(i));
    80003674:	854e                	mv	a0,s3
    80003676:	00000097          	auipc	ra,0x0
    8000367a:	c18080e7          	jalr	-1000(ra) # 8000328e <argraw>
    8000367e:	85aa                	mv	a1,a0
    80003680:	855a                	mv	a0,s6
    80003682:	ffffd097          	auipc	ra,0xffffd
    80003686:	f0c080e7          	jalr	-244(ra) # 8000058e <printf>
      for(int i=0;i<arguments[num];i++)
    8000368a:	2985                	addiw	s3,s3,1
    8000368c:	000aa783          	lw	a5,0(s5)
    80003690:	fef9c2e3          	blt	s3,a5,80003674 <syscall+0x268>
      printf(") -> %d\n",p->trapframe->a0);
    80003694:	06093783          	ld	a5,96(s2)
    80003698:	7bac                	ld	a1,112(a5)
    8000369a:	00005517          	auipc	a0,0x5
    8000369e:	f4650513          	addi	a0,a0,-186 # 800085e0 <states.1882+0x250>
    800036a2:	ffffd097          	auipc	ra,0xffffd
    800036a6:	eec080e7          	jalr	-276(ra) # 8000058e <printf>
    800036aa:	b7ad                	j	80003614 <syscall+0x208>
  } else {
    printf("%d %s: unknown sys call %d\n",
    800036ac:	86a6                	mv	a3,s1
    800036ae:	16090613          	addi	a2,s2,352
    800036b2:	03092583          	lw	a1,48(s2)
    800036b6:	00005517          	auipc	a0,0x5
    800036ba:	f3a50513          	addi	a0,a0,-198 # 800085f0 <states.1882+0x260>
    800036be:	ffffd097          	auipc	ra,0xffffd
    800036c2:	ed0080e7          	jalr	-304(ra) # 8000058e <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    800036c6:	06093783          	ld	a5,96(s2)
    800036ca:	577d                	li	a4,-1
    800036cc:	fbb8                	sd	a4,112(a5)
  }
  if(num==3) flag=0;
    800036ce:	478d                	li	a5,3
    800036d0:	00f48c63          	beq	s1,a5,800036e8 <syscall+0x2dc>
    800036d4:	70e2                	ld	ra,56(sp)
    800036d6:	7442                	ld	s0,48(sp)
    800036d8:	74a2                	ld	s1,40(sp)
    800036da:	7902                	ld	s2,32(sp)
    800036dc:	69e2                	ld	s3,24(sp)
    800036de:	6a42                	ld	s4,16(sp)
    800036e0:	6aa2                	ld	s5,8(sp)
    800036e2:	6b02                	ld	s6,0(sp)
    800036e4:	6121                	addi	sp,sp,64
    800036e6:	8082                	ret
  if(num==3) flag=0;
    800036e8:	00005797          	auipc	a5,0x5
    800036ec:	4007a223          	sw	zero,1028(a5) # 80008aec <flag>
    800036f0:	b7d5                	j	800036d4 <syscall+0x2c8>

00000000800036f2 <sys_exit>:
int uni_mask=0;
int flag=0;

uint64
sys_exit(void)
{
    800036f2:	1101                	addi	sp,sp,-32
    800036f4:	ec06                	sd	ra,24(sp)
    800036f6:	e822                	sd	s0,16(sp)
    800036f8:	1000                	addi	s0,sp,32
  int n;
  argint(0, &n);
    800036fa:	fec40593          	addi	a1,s0,-20
    800036fe:	4501                	li	a0,0
    80003700:	00000097          	auipc	ra,0x0
    80003704:	c94080e7          	jalr	-876(ra) # 80003394 <argint>
  exit(n);
    80003708:	fec42503          	lw	a0,-20(s0)
    8000370c:	fffff097          	auipc	ra,0xfffff
    80003710:	086080e7          	jalr	134(ra) # 80002792 <exit>
  return 0;  // not reached
}
    80003714:	4501                	li	a0,0
    80003716:	60e2                	ld	ra,24(sp)
    80003718:	6442                	ld	s0,16(sp)
    8000371a:	6105                	addi	sp,sp,32
    8000371c:	8082                	ret

000000008000371e <sys_getpid>:

uint64
sys_getpid(void)
{
    8000371e:	1141                	addi	sp,sp,-16
    80003720:	e406                	sd	ra,8(sp)
    80003722:	e022                	sd	s0,0(sp)
    80003724:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80003726:	ffffe097          	auipc	ra,0xffffe
    8000372a:	5d4080e7          	jalr	1492(ra) # 80001cfa <myproc>
}
    8000372e:	5908                	lw	a0,48(a0)
    80003730:	60a2                	ld	ra,8(sp)
    80003732:	6402                	ld	s0,0(sp)
    80003734:	0141                	addi	sp,sp,16
    80003736:	8082                	ret

0000000080003738 <sys_fork>:

uint64
sys_fork(void)
{
    80003738:	1141                	addi	sp,sp,-16
    8000373a:	e406                	sd	ra,8(sp)
    8000373c:	e022                	sd	s0,0(sp)
    8000373e:	0800                	addi	s0,sp,16
  return fork();
    80003740:	fffff097          	auipc	ra,0xfffff
    80003744:	b0e080e7          	jalr	-1266(ra) # 8000224e <fork>
}
    80003748:	60a2                	ld	ra,8(sp)
    8000374a:	6402                	ld	s0,0(sp)
    8000374c:	0141                	addi	sp,sp,16
    8000374e:	8082                	ret

0000000080003750 <sys_wait>:

uint64
sys_wait(void)
{
    80003750:	1101                	addi	sp,sp,-32
    80003752:	ec06                	sd	ra,24(sp)
    80003754:	e822                	sd	s0,16(sp)
    80003756:	1000                	addi	s0,sp,32
  uint64 p;
  argaddr(0, &p);
    80003758:	fe840593          	addi	a1,s0,-24
    8000375c:	4501                	li	a0,0
    8000375e:	00000097          	auipc	ra,0x0
    80003762:	c56080e7          	jalr	-938(ra) # 800033b4 <argaddr>
  return wait(p);
    80003766:	fe843503          	ld	a0,-24(s0)
    8000376a:	fffff097          	auipc	ra,0xfffff
    8000376e:	1da080e7          	jalr	474(ra) # 80002944 <wait>
}
    80003772:	60e2                	ld	ra,24(sp)
    80003774:	6442                	ld	s0,16(sp)
    80003776:	6105                	addi	sp,sp,32
    80003778:	8082                	ret

000000008000377a <sys_sbrk>:

uint64
sys_sbrk(void)
{
    8000377a:	7179                	addi	sp,sp,-48
    8000377c:	f406                	sd	ra,40(sp)
    8000377e:	f022                	sd	s0,32(sp)
    80003780:	ec26                	sd	s1,24(sp)
    80003782:	1800                	addi	s0,sp,48
  uint64 addr;
  int n;

  argint(0, &n);
    80003784:	fdc40593          	addi	a1,s0,-36
    80003788:	4501                	li	a0,0
    8000378a:	00000097          	auipc	ra,0x0
    8000378e:	c0a080e7          	jalr	-1014(ra) # 80003394 <argint>
  addr = myproc()->sz;
    80003792:	ffffe097          	auipc	ra,0xffffe
    80003796:	568080e7          	jalr	1384(ra) # 80001cfa <myproc>
    8000379a:	6924                	ld	s1,80(a0)
  if(growproc(n) < 0)
    8000379c:	fdc42503          	lw	a0,-36(s0)
    800037a0:	fffff097          	auipc	ra,0xfffff
    800037a4:	a52080e7          	jalr	-1454(ra) # 800021f2 <growproc>
    800037a8:	00054863          	bltz	a0,800037b8 <sys_sbrk+0x3e>
    return -1;
  return addr;
}
    800037ac:	8526                	mv	a0,s1
    800037ae:	70a2                	ld	ra,40(sp)
    800037b0:	7402                	ld	s0,32(sp)
    800037b2:	64e2                	ld	s1,24(sp)
    800037b4:	6145                	addi	sp,sp,48
    800037b6:	8082                	ret
    return -1;
    800037b8:	54fd                	li	s1,-1
    800037ba:	bfcd                	j	800037ac <sys_sbrk+0x32>

00000000800037bc <sys_sleep>:

uint64
sys_sleep(void)
{
    800037bc:	7139                	addi	sp,sp,-64
    800037be:	fc06                	sd	ra,56(sp)
    800037c0:	f822                	sd	s0,48(sp)
    800037c2:	f426                	sd	s1,40(sp)
    800037c4:	f04a                	sd	s2,32(sp)
    800037c6:	ec4e                	sd	s3,24(sp)
    800037c8:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  argint(0, &n);
    800037ca:	fcc40593          	addi	a1,s0,-52
    800037ce:	4501                	li	a0,0
    800037d0:	00000097          	auipc	ra,0x0
    800037d4:	bc4080e7          	jalr	-1084(ra) # 80003394 <argint>
  acquire(&tickslock);
    800037d8:	00235517          	auipc	a0,0x235
    800037dc:	49050513          	addi	a0,a0,1168 # 80238c68 <tickslock>
    800037e0:	ffffd097          	auipc	ra,0xffffd
    800037e4:	6cc080e7          	jalr	1740(ra) # 80000eac <acquire>
  ticks0 = ticks;
    800037e8:	00005917          	auipc	s2,0x5
    800037ec:	30092903          	lw	s2,768(s2) # 80008ae8 <ticks>
  while(ticks - ticks0 < n){
    800037f0:	fcc42783          	lw	a5,-52(s0)
    800037f4:	cf9d                	beqz	a5,80003832 <sys_sleep+0x76>
    if(killed(myproc())){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    800037f6:	00235997          	auipc	s3,0x235
    800037fa:	47298993          	addi	s3,s3,1138 # 80238c68 <tickslock>
    800037fe:	00005497          	auipc	s1,0x5
    80003802:	2ea48493          	addi	s1,s1,746 # 80008ae8 <ticks>
    if(killed(myproc())){
    80003806:	ffffe097          	auipc	ra,0xffffe
    8000380a:	4f4080e7          	jalr	1268(ra) # 80001cfa <myproc>
    8000380e:	fffff097          	auipc	ra,0xfffff
    80003812:	104080e7          	jalr	260(ra) # 80002912 <killed>
    80003816:	ed15                	bnez	a0,80003852 <sys_sleep+0x96>
    sleep(&ticks, &tickslock);
    80003818:	85ce                	mv	a1,s3
    8000381a:	8526                	mv	a0,s1
    8000381c:	fffff097          	auipc	ra,0xfffff
    80003820:	e42080e7          	jalr	-446(ra) # 8000265e <sleep>
  while(ticks - ticks0 < n){
    80003824:	409c                	lw	a5,0(s1)
    80003826:	412787bb          	subw	a5,a5,s2
    8000382a:	fcc42703          	lw	a4,-52(s0)
    8000382e:	fce7ece3          	bltu	a5,a4,80003806 <sys_sleep+0x4a>
  }
  release(&tickslock);
    80003832:	00235517          	auipc	a0,0x235
    80003836:	43650513          	addi	a0,a0,1078 # 80238c68 <tickslock>
    8000383a:	ffffd097          	auipc	ra,0xffffd
    8000383e:	726080e7          	jalr	1830(ra) # 80000f60 <release>
  return 0;
    80003842:	4501                	li	a0,0
}
    80003844:	70e2                	ld	ra,56(sp)
    80003846:	7442                	ld	s0,48(sp)
    80003848:	74a2                	ld	s1,40(sp)
    8000384a:	7902                	ld	s2,32(sp)
    8000384c:	69e2                	ld	s3,24(sp)
    8000384e:	6121                	addi	sp,sp,64
    80003850:	8082                	ret
      release(&tickslock);
    80003852:	00235517          	auipc	a0,0x235
    80003856:	41650513          	addi	a0,a0,1046 # 80238c68 <tickslock>
    8000385a:	ffffd097          	auipc	ra,0xffffd
    8000385e:	706080e7          	jalr	1798(ra) # 80000f60 <release>
      return -1;
    80003862:	557d                	li	a0,-1
    80003864:	b7c5                	j	80003844 <sys_sleep+0x88>

0000000080003866 <sys_kill>:

uint64
sys_kill(void)
{
    80003866:	1101                	addi	sp,sp,-32
    80003868:	ec06                	sd	ra,24(sp)
    8000386a:	e822                	sd	s0,16(sp)
    8000386c:	1000                	addi	s0,sp,32
  int pid;

  argint(0, &pid);
    8000386e:	fec40593          	addi	a1,s0,-20
    80003872:	4501                	li	a0,0
    80003874:	00000097          	auipc	ra,0x0
    80003878:	b20080e7          	jalr	-1248(ra) # 80003394 <argint>
  return kill(pid);
    8000387c:	fec42503          	lw	a0,-20(s0)
    80003880:	fffff097          	auipc	ra,0xfffff
    80003884:	ff4080e7          	jalr	-12(ra) # 80002874 <kill>
}
    80003888:	60e2                	ld	ra,24(sp)
    8000388a:	6442                	ld	s0,16(sp)
    8000388c:	6105                	addi	sp,sp,32
    8000388e:	8082                	ret

0000000080003890 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    80003890:	1101                	addi	sp,sp,-32
    80003892:	ec06                	sd	ra,24(sp)
    80003894:	e822                	sd	s0,16(sp)
    80003896:	e426                	sd	s1,8(sp)
    80003898:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    8000389a:	00235517          	auipc	a0,0x235
    8000389e:	3ce50513          	addi	a0,a0,974 # 80238c68 <tickslock>
    800038a2:	ffffd097          	auipc	ra,0xffffd
    800038a6:	60a080e7          	jalr	1546(ra) # 80000eac <acquire>
  xticks = ticks;
    800038aa:	00005497          	auipc	s1,0x5
    800038ae:	23e4a483          	lw	s1,574(s1) # 80008ae8 <ticks>
  release(&tickslock);
    800038b2:	00235517          	auipc	a0,0x235
    800038b6:	3b650513          	addi	a0,a0,950 # 80238c68 <tickslock>
    800038ba:	ffffd097          	auipc	ra,0xffffd
    800038be:	6a6080e7          	jalr	1702(ra) # 80000f60 <release>
  return xticks;
}
    800038c2:	02049513          	slli	a0,s1,0x20
    800038c6:	9101                	srli	a0,a0,0x20
    800038c8:	60e2                	ld	ra,24(sp)
    800038ca:	6442                	ld	s0,16(sp)
    800038cc:	64a2                	ld	s1,8(sp)
    800038ce:	6105                	addi	sp,sp,32
    800038d0:	8082                	ret

00000000800038d2 <sys_trace>:

uint64 sys_trace(void)
{
    800038d2:	1101                	addi	sp,sp,-32
    800038d4:	ec06                	sd	ra,24(sp)
    800038d6:	e822                	sd	s0,16(sp)
    800038d8:	1000                	addi	s0,sp,32
  int mask;
  argint(0,&mask);
    800038da:	fec40593          	addi	a1,s0,-20
    800038de:	4501                	li	a0,0
    800038e0:	00000097          	auipc	ra,0x0
    800038e4:	ab4080e7          	jalr	-1356(ra) # 80003394 <argint>
  uni_mask=mask;
    800038e8:	fec42503          	lw	a0,-20(s0)
    800038ec:	00005797          	auipc	a5,0x5
    800038f0:	20a7a223          	sw	a0,516(a5) # 80008af0 <uni_mask>
  flag=1;
    800038f4:	4785                	li	a5,1
    800038f6:	00005717          	auipc	a4,0x5
    800038fa:	1ef72b23          	sw	a5,502(a4) # 80008aec <flag>
  return mask;
}
    800038fe:	60e2                	ld	ra,24(sp)
    80003900:	6442                	ld	s0,16(sp)
    80003902:	6105                	addi	sp,sp,32
    80003904:	8082                	ret

0000000080003906 <restore>:

void restore(){
    80003906:	1141                	addi	sp,sp,-16
    80003908:	e406                	sd	ra,8(sp)
    8000390a:	e022                	sd	s0,0(sp)
    8000390c:	0800                	addi	s0,sp,16
  struct proc*p=myproc();
    8000390e:	ffffe097          	auipc	ra,0xffffe
    80003912:	3ec080e7          	jalr	1004(ra) # 80001cfa <myproc>

  p->trapframe_copy->kernel_trap = p->trapframe->kernel_trap;
    80003916:	18853783          	ld	a5,392(a0)
    8000391a:	7138                	ld	a4,96(a0)
    8000391c:	6b18                	ld	a4,16(a4)
    8000391e:	eb98                	sd	a4,16(a5)
  p->trapframe_copy->kernel_hartid = p->trapframe->kernel_hartid;
    80003920:	18853783          	ld	a5,392(a0)
    80003924:	7138                	ld	a4,96(a0)
    80003926:	7318                	ld	a4,32(a4)
    80003928:	f398                	sd	a4,32(a5)
  p->trapframe_copy->kernel_sp = p->trapframe->kernel_sp;
    8000392a:	18853783          	ld	a5,392(a0)
    8000392e:	7138                	ld	a4,96(a0)
    80003930:	6718                	ld	a4,8(a4)
    80003932:	e798                	sd	a4,8(a5)
  p->trapframe_copy->kernel_satp = p->trapframe->kernel_satp;
    80003934:	18853783          	ld	a5,392(a0)
    80003938:	7138                	ld	a4,96(a0)
    8000393a:	6318                	ld	a4,0(a4)
    8000393c:	e398                	sd	a4,0(a5)
  *(p->trapframe) = *(p->trapframe_copy);
    8000393e:	18853683          	ld	a3,392(a0)
    80003942:	87b6                	mv	a5,a3
    80003944:	7138                	ld	a4,96(a0)
    80003946:	12068693          	addi	a3,a3,288
    8000394a:	0007b803          	ld	a6,0(a5)
    8000394e:	6788                	ld	a0,8(a5)
    80003950:	6b8c                	ld	a1,16(a5)
    80003952:	6f90                	ld	a2,24(a5)
    80003954:	01073023          	sd	a6,0(a4)
    80003958:	e708                	sd	a0,8(a4)
    8000395a:	eb0c                	sd	a1,16(a4)
    8000395c:	ef10                	sd	a2,24(a4)
    8000395e:	02078793          	addi	a5,a5,32
    80003962:	02070713          	addi	a4,a4,32
    80003966:	fed792e3          	bne	a5,a3,8000394a <restore+0x44>
}
    8000396a:	60a2                	ld	ra,8(sp)
    8000396c:	6402                	ld	s0,0(sp)
    8000396e:	0141                	addi	sp,sp,16
    80003970:	8082                	ret

0000000080003972 <sys_sigreturn>:

uint64 sys_sigreturn(void){
    80003972:	1141                	addi	sp,sp,-16
    80003974:	e406                	sd	ra,8(sp)
    80003976:	e022                	sd	s0,0(sp)
    80003978:	0800                	addi	s0,sp,16
  restore();
    8000397a:	00000097          	auipc	ra,0x0
    8000397e:	f8c080e7          	jalr	-116(ra) # 80003906 <restore>
  myproc()->is_sigalarm = 0;
    80003982:	ffffe097          	auipc	ra,0xffffe
    80003986:	378080e7          	jalr	888(ra) # 80001cfa <myproc>
    8000398a:	16052823          	sw	zero,368(a0)

  usertrapret();
    8000398e:	fffff097          	auipc	ra,0xfffff
    80003992:	502080e7          	jalr	1282(ra) # 80002e90 <usertrapret>
  
  return 0;
}
    80003996:	4501                	li	a0,0
    80003998:	60a2                	ld	ra,8(sp)
    8000399a:	6402                	ld	s0,0(sp)
    8000399c:	0141                	addi	sp,sp,16
    8000399e:	8082                	ret

00000000800039a0 <sys_waitx>:

uint64
sys_waitx(void)
{
    800039a0:	7139                	addi	sp,sp,-64
    800039a2:	fc06                	sd	ra,56(sp)
    800039a4:	f822                	sd	s0,48(sp)
    800039a6:	f426                	sd	s1,40(sp)
    800039a8:	f04a                	sd	s2,32(sp)
    800039aa:	0080                	addi	s0,sp,64
  uint64 addr, addr1, addr2;
  uint wtime, rtime;
  argaddr(0, &addr);
    800039ac:	fd840593          	addi	a1,s0,-40
    800039b0:	4501                	li	a0,0
    800039b2:	00000097          	auipc	ra,0x0
    800039b6:	a02080e7          	jalr	-1534(ra) # 800033b4 <argaddr>
  argaddr(1, &addr1); // user virtual memory
    800039ba:	fd040593          	addi	a1,s0,-48
    800039be:	4505                	li	a0,1
    800039c0:	00000097          	auipc	ra,0x0
    800039c4:	9f4080e7          	jalr	-1548(ra) # 800033b4 <argaddr>
  argaddr(2, &addr2);
    800039c8:	fc840593          	addi	a1,s0,-56
    800039cc:	4509                	li	a0,2
    800039ce:	00000097          	auipc	ra,0x0
    800039d2:	9e6080e7          	jalr	-1562(ra) # 800033b4 <argaddr>
  int ret = waitx(addr, &wtime, &rtime);
    800039d6:	fc040613          	addi	a2,s0,-64
    800039da:	fc440593          	addi	a1,s0,-60
    800039de:	fd843503          	ld	a0,-40(s0)
    800039e2:	fffff097          	auipc	ra,0xfffff
    800039e6:	1ea080e7          	jalr	490(ra) # 80002bcc <waitx>
    800039ea:	892a                	mv	s2,a0
  struct proc* p = myproc();
    800039ec:	ffffe097          	auipc	ra,0xffffe
    800039f0:	30e080e7          	jalr	782(ra) # 80001cfa <myproc>
    800039f4:	84aa                	mv	s1,a0
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)
    800039f6:	4691                	li	a3,4
    800039f8:	fc440613          	addi	a2,s0,-60
    800039fc:	fd043583          	ld	a1,-48(s0)
    80003a00:	6d28                	ld	a0,88(a0)
    80003a02:	ffffe097          	auipc	ra,0xffffe
    80003a06:	f48080e7          	jalr	-184(ra) # 8000194a <copyout>
    return -1;
    80003a0a:	57fd                	li	a5,-1
  if (copyout(p->pagetable, addr1,(char*)&wtime, sizeof(int)) < 0)
    80003a0c:	00054f63          	bltz	a0,80003a2a <sys_waitx+0x8a>
  if (copyout(p->pagetable, addr2,(char*)&rtime, sizeof(int)) < 0)
    80003a10:	4691                	li	a3,4
    80003a12:	fc040613          	addi	a2,s0,-64
    80003a16:	fc843583          	ld	a1,-56(s0)
    80003a1a:	6ca8                	ld	a0,88(s1)
    80003a1c:	ffffe097          	auipc	ra,0xffffe
    80003a20:	f2e080e7          	jalr	-210(ra) # 8000194a <copyout>
    80003a24:	00054a63          	bltz	a0,80003a38 <sys_waitx+0x98>
    return -1;
  return ret;
    80003a28:	87ca                	mv	a5,s2
}
    80003a2a:	853e                	mv	a0,a5
    80003a2c:	70e2                	ld	ra,56(sp)
    80003a2e:	7442                	ld	s0,48(sp)
    80003a30:	74a2                	ld	s1,40(sp)
    80003a32:	7902                	ld	s2,32(sp)
    80003a34:	6121                	addi	sp,sp,64
    80003a36:	8082                	ret
    return -1;
    80003a38:	57fd                	li	a5,-1
    80003a3a:	bfc5                	j	80003a2a <sys_waitx+0x8a>

0000000080003a3c <sys_set_priority>:

uint64
sys_set_priority(void)
{
    80003a3c:	1101                	addi	sp,sp,-32
    80003a3e:	ec06                	sd	ra,24(sp)
    80003a40:	e822                	sd	s0,16(sp)
    80003a42:	1000                	addi	s0,sp,32
  int new_static_priority;

  argint(0, &new_static_priority);
    80003a44:	fec40593          	addi	a1,s0,-20
    80003a48:	4501                	li	a0,0
    80003a4a:	00000097          	auipc	ra,0x0
    80003a4e:	94a080e7          	jalr	-1718(ra) # 80003394 <argint>

  if (new_static_priority < 0)
    80003a52:	fec42783          	lw	a5,-20(s0)
    return -1;
    80003a56:	557d                	li	a0,-1
  if (new_static_priority < 0)
    80003a58:	0207c463          	bltz	a5,80003a80 <sys_set_priority+0x44>

  int proc_pid;
  argint(1, &proc_pid);
    80003a5c:	fe840593          	addi	a1,s0,-24
    80003a60:	4505                	li	a0,1
    80003a62:	00000097          	auipc	ra,0x0
    80003a66:	932080e7          	jalr	-1742(ra) # 80003394 <argint>

  if (proc_pid < 0)
    80003a6a:	fe842583          	lw	a1,-24(s0)
    return -1;
    80003a6e:	557d                	li	a0,-1
  if (proc_pid < 0)
    80003a70:	0005c863          	bltz	a1,80003a80 <sys_set_priority+0x44>

  return set_priority(new_static_priority, proc_pid);
    80003a74:	fec42503          	lw	a0,-20(s0)
    80003a78:	ffffe097          	auipc	ra,0xffffe
    80003a7c:	3aa080e7          	jalr	938(ra) # 80001e22 <set_priority>
}
    80003a80:	60e2                	ld	ra,24(sp)
    80003a82:	6442                	ld	s0,16(sp)
    80003a84:	6105                	addi	sp,sp,32
    80003a86:	8082                	ret

0000000080003a88 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003a88:	7179                	addi	sp,sp,-48
    80003a8a:	f406                	sd	ra,40(sp)
    80003a8c:	f022                	sd	s0,32(sp)
    80003a8e:	ec26                	sd	s1,24(sp)
    80003a90:	e84a                	sd	s2,16(sp)
    80003a92:	e44e                	sd	s3,8(sp)
    80003a94:	e052                	sd	s4,0(sp)
    80003a96:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003a98:	00005597          	auipc	a1,0x5
    80003a9c:	c6858593          	addi	a1,a1,-920 # 80008700 <syscalls+0xd8>
    80003aa0:	00235517          	auipc	a0,0x235
    80003aa4:	2a850513          	addi	a0,a0,680 # 80238d48 <bcache>
    80003aa8:	ffffd097          	auipc	ra,0xffffd
    80003aac:	374080e7          	jalr	884(ra) # 80000e1c <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    80003ab0:	0023d797          	auipc	a5,0x23d
    80003ab4:	29878793          	addi	a5,a5,664 # 80240d48 <bcache+0x8000>
    80003ab8:	0023d717          	auipc	a4,0x23d
    80003abc:	4f870713          	addi	a4,a4,1272 # 80240fb0 <bcache+0x8268>
    80003ac0:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003ac4:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003ac8:	00235497          	auipc	s1,0x235
    80003acc:	29848493          	addi	s1,s1,664 # 80238d60 <bcache+0x18>
    b->next = bcache.head.next;
    80003ad0:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003ad2:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003ad4:	00005a17          	auipc	s4,0x5
    80003ad8:	c34a0a13          	addi	s4,s4,-972 # 80008708 <syscalls+0xe0>
    b->next = bcache.head.next;
    80003adc:	2b893783          	ld	a5,696(s2)
    80003ae0:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003ae2:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003ae6:	85d2                	mv	a1,s4
    80003ae8:	01048513          	addi	a0,s1,16
    80003aec:	00001097          	auipc	ra,0x1
    80003af0:	4c4080e7          	jalr	1220(ra) # 80004fb0 <initsleeplock>
    bcache.head.next->prev = b;
    80003af4:	2b893783          	ld	a5,696(s2)
    80003af8:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003afa:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003afe:	45848493          	addi	s1,s1,1112
    80003b02:	fd349de3          	bne	s1,s3,80003adc <binit+0x54>
  }
}
    80003b06:	70a2                	ld	ra,40(sp)
    80003b08:	7402                	ld	s0,32(sp)
    80003b0a:	64e2                	ld	s1,24(sp)
    80003b0c:	6942                	ld	s2,16(sp)
    80003b0e:	69a2                	ld	s3,8(sp)
    80003b10:	6a02                	ld	s4,0(sp)
    80003b12:	6145                	addi	sp,sp,48
    80003b14:	8082                	ret

0000000080003b16 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    80003b16:	7179                	addi	sp,sp,-48
    80003b18:	f406                	sd	ra,40(sp)
    80003b1a:	f022                	sd	s0,32(sp)
    80003b1c:	ec26                	sd	s1,24(sp)
    80003b1e:	e84a                	sd	s2,16(sp)
    80003b20:	e44e                	sd	s3,8(sp)
    80003b22:	1800                	addi	s0,sp,48
    80003b24:	89aa                	mv	s3,a0
    80003b26:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    80003b28:	00235517          	auipc	a0,0x235
    80003b2c:	22050513          	addi	a0,a0,544 # 80238d48 <bcache>
    80003b30:	ffffd097          	auipc	ra,0xffffd
    80003b34:	37c080e7          	jalr	892(ra) # 80000eac <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    80003b38:	0023d497          	auipc	s1,0x23d
    80003b3c:	4c84b483          	ld	s1,1224(s1) # 80241000 <bcache+0x82b8>
    80003b40:	0023d797          	auipc	a5,0x23d
    80003b44:	47078793          	addi	a5,a5,1136 # 80240fb0 <bcache+0x8268>
    80003b48:	02f48f63          	beq	s1,a5,80003b86 <bread+0x70>
    80003b4c:	873e                	mv	a4,a5
    80003b4e:	a021                	j	80003b56 <bread+0x40>
    80003b50:	68a4                	ld	s1,80(s1)
    80003b52:	02e48a63          	beq	s1,a4,80003b86 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    80003b56:	449c                	lw	a5,8(s1)
    80003b58:	ff379ce3          	bne	a5,s3,80003b50 <bread+0x3a>
    80003b5c:	44dc                	lw	a5,12(s1)
    80003b5e:	ff2799e3          	bne	a5,s2,80003b50 <bread+0x3a>
      b->refcnt++;
    80003b62:	40bc                	lw	a5,64(s1)
    80003b64:	2785                	addiw	a5,a5,1
    80003b66:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003b68:	00235517          	auipc	a0,0x235
    80003b6c:	1e050513          	addi	a0,a0,480 # 80238d48 <bcache>
    80003b70:	ffffd097          	auipc	ra,0xffffd
    80003b74:	3f0080e7          	jalr	1008(ra) # 80000f60 <release>
      acquiresleep(&b->lock);
    80003b78:	01048513          	addi	a0,s1,16
    80003b7c:	00001097          	auipc	ra,0x1
    80003b80:	46e080e7          	jalr	1134(ra) # 80004fea <acquiresleep>
      return b;
    80003b84:	a8b9                	j	80003be2 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003b86:	0023d497          	auipc	s1,0x23d
    80003b8a:	4724b483          	ld	s1,1138(s1) # 80240ff8 <bcache+0x82b0>
    80003b8e:	0023d797          	auipc	a5,0x23d
    80003b92:	42278793          	addi	a5,a5,1058 # 80240fb0 <bcache+0x8268>
    80003b96:	00f48863          	beq	s1,a5,80003ba6 <bread+0x90>
    80003b9a:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    80003b9c:	40bc                	lw	a5,64(s1)
    80003b9e:	cf81                	beqz	a5,80003bb6 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003ba0:	64a4                	ld	s1,72(s1)
    80003ba2:	fee49de3          	bne	s1,a4,80003b9c <bread+0x86>
  panic("bget: no buffers");
    80003ba6:	00005517          	auipc	a0,0x5
    80003baa:	b6a50513          	addi	a0,a0,-1174 # 80008710 <syscalls+0xe8>
    80003bae:	ffffd097          	auipc	ra,0xffffd
    80003bb2:	996080e7          	jalr	-1642(ra) # 80000544 <panic>
      b->dev = dev;
    80003bb6:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003bba:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    80003bbe:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003bc2:	4785                	li	a5,1
    80003bc4:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003bc6:	00235517          	auipc	a0,0x235
    80003bca:	18250513          	addi	a0,a0,386 # 80238d48 <bcache>
    80003bce:	ffffd097          	auipc	ra,0xffffd
    80003bd2:	392080e7          	jalr	914(ra) # 80000f60 <release>
      acquiresleep(&b->lock);
    80003bd6:	01048513          	addi	a0,s1,16
    80003bda:	00001097          	auipc	ra,0x1
    80003bde:	410080e7          	jalr	1040(ra) # 80004fea <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003be2:	409c                	lw	a5,0(s1)
    80003be4:	cb89                	beqz	a5,80003bf6 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003be6:	8526                	mv	a0,s1
    80003be8:	70a2                	ld	ra,40(sp)
    80003bea:	7402                	ld	s0,32(sp)
    80003bec:	64e2                	ld	s1,24(sp)
    80003bee:	6942                	ld	s2,16(sp)
    80003bf0:	69a2                	ld	s3,8(sp)
    80003bf2:	6145                	addi	sp,sp,48
    80003bf4:	8082                	ret
    virtio_disk_rw(b, 0);
    80003bf6:	4581                	li	a1,0
    80003bf8:	8526                	mv	a0,s1
    80003bfa:	00003097          	auipc	ra,0x3
    80003bfe:	fce080e7          	jalr	-50(ra) # 80006bc8 <virtio_disk_rw>
    b->valid = 1;
    80003c02:	4785                	li	a5,1
    80003c04:	c09c                	sw	a5,0(s1)
  return b;
    80003c06:	b7c5                	j	80003be6 <bread+0xd0>

0000000080003c08 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003c08:	1101                	addi	sp,sp,-32
    80003c0a:	ec06                	sd	ra,24(sp)
    80003c0c:	e822                	sd	s0,16(sp)
    80003c0e:	e426                	sd	s1,8(sp)
    80003c10:	1000                	addi	s0,sp,32
    80003c12:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003c14:	0541                	addi	a0,a0,16
    80003c16:	00001097          	auipc	ra,0x1
    80003c1a:	46e080e7          	jalr	1134(ra) # 80005084 <holdingsleep>
    80003c1e:	cd01                	beqz	a0,80003c36 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    80003c20:	4585                	li	a1,1
    80003c22:	8526                	mv	a0,s1
    80003c24:	00003097          	auipc	ra,0x3
    80003c28:	fa4080e7          	jalr	-92(ra) # 80006bc8 <virtio_disk_rw>
}
    80003c2c:	60e2                	ld	ra,24(sp)
    80003c2e:	6442                	ld	s0,16(sp)
    80003c30:	64a2                	ld	s1,8(sp)
    80003c32:	6105                	addi	sp,sp,32
    80003c34:	8082                	ret
    panic("bwrite");
    80003c36:	00005517          	auipc	a0,0x5
    80003c3a:	af250513          	addi	a0,a0,-1294 # 80008728 <syscalls+0x100>
    80003c3e:	ffffd097          	auipc	ra,0xffffd
    80003c42:	906080e7          	jalr	-1786(ra) # 80000544 <panic>

0000000080003c46 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    80003c46:	1101                	addi	sp,sp,-32
    80003c48:	ec06                	sd	ra,24(sp)
    80003c4a:	e822                	sd	s0,16(sp)
    80003c4c:	e426                	sd	s1,8(sp)
    80003c4e:	e04a                	sd	s2,0(sp)
    80003c50:	1000                	addi	s0,sp,32
    80003c52:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    80003c54:	01050913          	addi	s2,a0,16
    80003c58:	854a                	mv	a0,s2
    80003c5a:	00001097          	auipc	ra,0x1
    80003c5e:	42a080e7          	jalr	1066(ra) # 80005084 <holdingsleep>
    80003c62:	c92d                	beqz	a0,80003cd4 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    80003c64:	854a                	mv	a0,s2
    80003c66:	00001097          	auipc	ra,0x1
    80003c6a:	3da080e7          	jalr	986(ra) # 80005040 <releasesleep>

  acquire(&bcache.lock);
    80003c6e:	00235517          	auipc	a0,0x235
    80003c72:	0da50513          	addi	a0,a0,218 # 80238d48 <bcache>
    80003c76:	ffffd097          	auipc	ra,0xffffd
    80003c7a:	236080e7          	jalr	566(ra) # 80000eac <acquire>
  b->refcnt--;
    80003c7e:	40bc                	lw	a5,64(s1)
    80003c80:	37fd                	addiw	a5,a5,-1
    80003c82:	0007871b          	sext.w	a4,a5
    80003c86:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003c88:	eb05                	bnez	a4,80003cb8 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003c8a:	68bc                	ld	a5,80(s1)
    80003c8c:	64b8                	ld	a4,72(s1)
    80003c8e:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    80003c90:	64bc                	ld	a5,72(s1)
    80003c92:	68b8                	ld	a4,80(s1)
    80003c94:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003c96:	0023d797          	auipc	a5,0x23d
    80003c9a:	0b278793          	addi	a5,a5,178 # 80240d48 <bcache+0x8000>
    80003c9e:	2b87b703          	ld	a4,696(a5)
    80003ca2:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003ca4:	0023d717          	auipc	a4,0x23d
    80003ca8:	30c70713          	addi	a4,a4,780 # 80240fb0 <bcache+0x8268>
    80003cac:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    80003cae:	2b87b703          	ld	a4,696(a5)
    80003cb2:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003cb4:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003cb8:	00235517          	auipc	a0,0x235
    80003cbc:	09050513          	addi	a0,a0,144 # 80238d48 <bcache>
    80003cc0:	ffffd097          	auipc	ra,0xffffd
    80003cc4:	2a0080e7          	jalr	672(ra) # 80000f60 <release>
}
    80003cc8:	60e2                	ld	ra,24(sp)
    80003cca:	6442                	ld	s0,16(sp)
    80003ccc:	64a2                	ld	s1,8(sp)
    80003cce:	6902                	ld	s2,0(sp)
    80003cd0:	6105                	addi	sp,sp,32
    80003cd2:	8082                	ret
    panic("brelse");
    80003cd4:	00005517          	auipc	a0,0x5
    80003cd8:	a5c50513          	addi	a0,a0,-1444 # 80008730 <syscalls+0x108>
    80003cdc:	ffffd097          	auipc	ra,0xffffd
    80003ce0:	868080e7          	jalr	-1944(ra) # 80000544 <panic>

0000000080003ce4 <bpin>:

void
bpin(struct buf *b) {
    80003ce4:	1101                	addi	sp,sp,-32
    80003ce6:	ec06                	sd	ra,24(sp)
    80003ce8:	e822                	sd	s0,16(sp)
    80003cea:	e426                	sd	s1,8(sp)
    80003cec:	1000                	addi	s0,sp,32
    80003cee:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003cf0:	00235517          	auipc	a0,0x235
    80003cf4:	05850513          	addi	a0,a0,88 # 80238d48 <bcache>
    80003cf8:	ffffd097          	auipc	ra,0xffffd
    80003cfc:	1b4080e7          	jalr	436(ra) # 80000eac <acquire>
  b->refcnt++;
    80003d00:	40bc                	lw	a5,64(s1)
    80003d02:	2785                	addiw	a5,a5,1
    80003d04:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003d06:	00235517          	auipc	a0,0x235
    80003d0a:	04250513          	addi	a0,a0,66 # 80238d48 <bcache>
    80003d0e:	ffffd097          	auipc	ra,0xffffd
    80003d12:	252080e7          	jalr	594(ra) # 80000f60 <release>
}
    80003d16:	60e2                	ld	ra,24(sp)
    80003d18:	6442                	ld	s0,16(sp)
    80003d1a:	64a2                	ld	s1,8(sp)
    80003d1c:	6105                	addi	sp,sp,32
    80003d1e:	8082                	ret

0000000080003d20 <bunpin>:

void
bunpin(struct buf *b) {
    80003d20:	1101                	addi	sp,sp,-32
    80003d22:	ec06                	sd	ra,24(sp)
    80003d24:	e822                	sd	s0,16(sp)
    80003d26:	e426                	sd	s1,8(sp)
    80003d28:	1000                	addi	s0,sp,32
    80003d2a:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    80003d2c:	00235517          	auipc	a0,0x235
    80003d30:	01c50513          	addi	a0,a0,28 # 80238d48 <bcache>
    80003d34:	ffffd097          	auipc	ra,0xffffd
    80003d38:	178080e7          	jalr	376(ra) # 80000eac <acquire>
  b->refcnt--;
    80003d3c:	40bc                	lw	a5,64(s1)
    80003d3e:	37fd                	addiw	a5,a5,-1
    80003d40:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003d42:	00235517          	auipc	a0,0x235
    80003d46:	00650513          	addi	a0,a0,6 # 80238d48 <bcache>
    80003d4a:	ffffd097          	auipc	ra,0xffffd
    80003d4e:	216080e7          	jalr	534(ra) # 80000f60 <release>
}
    80003d52:	60e2                	ld	ra,24(sp)
    80003d54:	6442                	ld	s0,16(sp)
    80003d56:	64a2                	ld	s1,8(sp)
    80003d58:	6105                	addi	sp,sp,32
    80003d5a:	8082                	ret

0000000080003d5c <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    80003d5c:	1101                	addi	sp,sp,-32
    80003d5e:	ec06                	sd	ra,24(sp)
    80003d60:	e822                	sd	s0,16(sp)
    80003d62:	e426                	sd	s1,8(sp)
    80003d64:	e04a                	sd	s2,0(sp)
    80003d66:	1000                	addi	s0,sp,32
    80003d68:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    80003d6a:	00d5d59b          	srliw	a1,a1,0xd
    80003d6e:	0023d797          	auipc	a5,0x23d
    80003d72:	6b67a783          	lw	a5,1718(a5) # 80241424 <sb+0x1c>
    80003d76:	9dbd                	addw	a1,a1,a5
    80003d78:	00000097          	auipc	ra,0x0
    80003d7c:	d9e080e7          	jalr	-610(ra) # 80003b16 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    80003d80:	0074f713          	andi	a4,s1,7
    80003d84:	4785                	li	a5,1
    80003d86:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003d8a:	14ce                	slli	s1,s1,0x33
    80003d8c:	90d9                	srli	s1,s1,0x36
    80003d8e:	00950733          	add	a4,a0,s1
    80003d92:	05874703          	lbu	a4,88(a4)
    80003d96:	00e7f6b3          	and	a3,a5,a4
    80003d9a:	c69d                	beqz	a3,80003dc8 <bfree+0x6c>
    80003d9c:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    80003d9e:	94aa                	add	s1,s1,a0
    80003da0:	fff7c793          	not	a5,a5
    80003da4:	8ff9                	and	a5,a5,a4
    80003da6:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003daa:	00001097          	auipc	ra,0x1
    80003dae:	120080e7          	jalr	288(ra) # 80004eca <log_write>
  brelse(bp);
    80003db2:	854a                	mv	a0,s2
    80003db4:	00000097          	auipc	ra,0x0
    80003db8:	e92080e7          	jalr	-366(ra) # 80003c46 <brelse>
}
    80003dbc:	60e2                	ld	ra,24(sp)
    80003dbe:	6442                	ld	s0,16(sp)
    80003dc0:	64a2                	ld	s1,8(sp)
    80003dc2:	6902                	ld	s2,0(sp)
    80003dc4:	6105                	addi	sp,sp,32
    80003dc6:	8082                	ret
    panic("freeing free block");
    80003dc8:	00005517          	auipc	a0,0x5
    80003dcc:	97050513          	addi	a0,a0,-1680 # 80008738 <syscalls+0x110>
    80003dd0:	ffffc097          	auipc	ra,0xffffc
    80003dd4:	774080e7          	jalr	1908(ra) # 80000544 <panic>

0000000080003dd8 <balloc>:
{
    80003dd8:	711d                	addi	sp,sp,-96
    80003dda:	ec86                	sd	ra,88(sp)
    80003ddc:	e8a2                	sd	s0,80(sp)
    80003dde:	e4a6                	sd	s1,72(sp)
    80003de0:	e0ca                	sd	s2,64(sp)
    80003de2:	fc4e                	sd	s3,56(sp)
    80003de4:	f852                	sd	s4,48(sp)
    80003de6:	f456                	sd	s5,40(sp)
    80003de8:	f05a                	sd	s6,32(sp)
    80003dea:	ec5e                	sd	s7,24(sp)
    80003dec:	e862                	sd	s8,16(sp)
    80003dee:	e466                	sd	s9,8(sp)
    80003df0:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003df2:	0023d797          	auipc	a5,0x23d
    80003df6:	61a7a783          	lw	a5,1562(a5) # 8024140c <sb+0x4>
    80003dfa:	10078163          	beqz	a5,80003efc <balloc+0x124>
    80003dfe:	8baa                	mv	s7,a0
    80003e00:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    80003e02:	0023db17          	auipc	s6,0x23d
    80003e06:	606b0b13          	addi	s6,s6,1542 # 80241408 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003e0a:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003e0c:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003e0e:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    80003e10:	6c89                	lui	s9,0x2
    80003e12:	a061                	j	80003e9a <balloc+0xc2>
        bp->data[bi/8] |= m;  // Mark block in use.
    80003e14:	974a                	add	a4,a4,s2
    80003e16:	8fd5                	or	a5,a5,a3
    80003e18:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003e1c:	854a                	mv	a0,s2
    80003e1e:	00001097          	auipc	ra,0x1
    80003e22:	0ac080e7          	jalr	172(ra) # 80004eca <log_write>
        brelse(bp);
    80003e26:	854a                	mv	a0,s2
    80003e28:	00000097          	auipc	ra,0x0
    80003e2c:	e1e080e7          	jalr	-482(ra) # 80003c46 <brelse>
  bp = bread(dev, bno);
    80003e30:	85a6                	mv	a1,s1
    80003e32:	855e                	mv	a0,s7
    80003e34:	00000097          	auipc	ra,0x0
    80003e38:	ce2080e7          	jalr	-798(ra) # 80003b16 <bread>
    80003e3c:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003e3e:	40000613          	li	a2,1024
    80003e42:	4581                	li	a1,0
    80003e44:	05850513          	addi	a0,a0,88
    80003e48:	ffffd097          	auipc	ra,0xffffd
    80003e4c:	160080e7          	jalr	352(ra) # 80000fa8 <memset>
  log_write(bp);
    80003e50:	854a                	mv	a0,s2
    80003e52:	00001097          	auipc	ra,0x1
    80003e56:	078080e7          	jalr	120(ra) # 80004eca <log_write>
  brelse(bp);
    80003e5a:	854a                	mv	a0,s2
    80003e5c:	00000097          	auipc	ra,0x0
    80003e60:	dea080e7          	jalr	-534(ra) # 80003c46 <brelse>
}
    80003e64:	8526                	mv	a0,s1
    80003e66:	60e6                	ld	ra,88(sp)
    80003e68:	6446                	ld	s0,80(sp)
    80003e6a:	64a6                	ld	s1,72(sp)
    80003e6c:	6906                	ld	s2,64(sp)
    80003e6e:	79e2                	ld	s3,56(sp)
    80003e70:	7a42                	ld	s4,48(sp)
    80003e72:	7aa2                	ld	s5,40(sp)
    80003e74:	7b02                	ld	s6,32(sp)
    80003e76:	6be2                	ld	s7,24(sp)
    80003e78:	6c42                	ld	s8,16(sp)
    80003e7a:	6ca2                	ld	s9,8(sp)
    80003e7c:	6125                	addi	sp,sp,96
    80003e7e:	8082                	ret
    brelse(bp);
    80003e80:	854a                	mv	a0,s2
    80003e82:	00000097          	auipc	ra,0x0
    80003e86:	dc4080e7          	jalr	-572(ra) # 80003c46 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    80003e8a:	015c87bb          	addw	a5,s9,s5
    80003e8e:	00078a9b          	sext.w	s5,a5
    80003e92:	004b2703          	lw	a4,4(s6)
    80003e96:	06eaf363          	bgeu	s5,a4,80003efc <balloc+0x124>
    bp = bread(dev, BBLOCK(b, sb));
    80003e9a:	41fad79b          	sraiw	a5,s5,0x1f
    80003e9e:	0137d79b          	srliw	a5,a5,0x13
    80003ea2:	015787bb          	addw	a5,a5,s5
    80003ea6:	40d7d79b          	sraiw	a5,a5,0xd
    80003eaa:	01cb2583          	lw	a1,28(s6)
    80003eae:	9dbd                	addw	a1,a1,a5
    80003eb0:	855e                	mv	a0,s7
    80003eb2:	00000097          	auipc	ra,0x0
    80003eb6:	c64080e7          	jalr	-924(ra) # 80003b16 <bread>
    80003eba:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003ebc:	004b2503          	lw	a0,4(s6)
    80003ec0:	000a849b          	sext.w	s1,s5
    80003ec4:	8662                	mv	a2,s8
    80003ec6:	faa4fde3          	bgeu	s1,a0,80003e80 <balloc+0xa8>
      m = 1 << (bi % 8);
    80003eca:	41f6579b          	sraiw	a5,a2,0x1f
    80003ece:	01d7d69b          	srliw	a3,a5,0x1d
    80003ed2:	00c6873b          	addw	a4,a3,a2
    80003ed6:	00777793          	andi	a5,a4,7
    80003eda:	9f95                	subw	a5,a5,a3
    80003edc:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003ee0:	4037571b          	sraiw	a4,a4,0x3
    80003ee4:	00e906b3          	add	a3,s2,a4
    80003ee8:	0586c683          	lbu	a3,88(a3)
    80003eec:	00d7f5b3          	and	a1,a5,a3
    80003ef0:	d195                	beqz	a1,80003e14 <balloc+0x3c>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003ef2:	2605                	addiw	a2,a2,1
    80003ef4:	2485                	addiw	s1,s1,1
    80003ef6:	fd4618e3          	bne	a2,s4,80003ec6 <balloc+0xee>
    80003efa:	b759                	j	80003e80 <balloc+0xa8>
  printf("balloc: out of blocks\n");
    80003efc:	00005517          	auipc	a0,0x5
    80003f00:	85450513          	addi	a0,a0,-1964 # 80008750 <syscalls+0x128>
    80003f04:	ffffc097          	auipc	ra,0xffffc
    80003f08:	68a080e7          	jalr	1674(ra) # 8000058e <printf>
  return 0;
    80003f0c:	4481                	li	s1,0
    80003f0e:	bf99                	j	80003e64 <balloc+0x8c>

0000000080003f10 <bmap>:
// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
// returns 0 if out of disk space.
static uint
bmap(struct inode *ip, uint bn)
{
    80003f10:	7179                	addi	sp,sp,-48
    80003f12:	f406                	sd	ra,40(sp)
    80003f14:	f022                	sd	s0,32(sp)
    80003f16:	ec26                	sd	s1,24(sp)
    80003f18:	e84a                	sd	s2,16(sp)
    80003f1a:	e44e                	sd	s3,8(sp)
    80003f1c:	e052                	sd	s4,0(sp)
    80003f1e:	1800                	addi	s0,sp,48
    80003f20:	89aa                	mv	s3,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    80003f22:	47ad                	li	a5,11
    80003f24:	02b7e763          	bltu	a5,a1,80003f52 <bmap+0x42>
    if((addr = ip->addrs[bn]) == 0){
    80003f28:	02059493          	slli	s1,a1,0x20
    80003f2c:	9081                	srli	s1,s1,0x20
    80003f2e:	048a                	slli	s1,s1,0x2
    80003f30:	94aa                	add	s1,s1,a0
    80003f32:	0504a903          	lw	s2,80(s1)
    80003f36:	06091e63          	bnez	s2,80003fb2 <bmap+0xa2>
      addr = balloc(ip->dev);
    80003f3a:	4108                	lw	a0,0(a0)
    80003f3c:	00000097          	auipc	ra,0x0
    80003f40:	e9c080e7          	jalr	-356(ra) # 80003dd8 <balloc>
    80003f44:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003f48:	06090563          	beqz	s2,80003fb2 <bmap+0xa2>
        return 0;
      ip->addrs[bn] = addr;
    80003f4c:	0524a823          	sw	s2,80(s1)
    80003f50:	a08d                	j	80003fb2 <bmap+0xa2>
    }
    return addr;
  }
  bn -= NDIRECT;
    80003f52:	ff45849b          	addiw	s1,a1,-12
    80003f56:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    80003f5a:	0ff00793          	li	a5,255
    80003f5e:	08e7e563          	bltu	a5,a4,80003fe8 <bmap+0xd8>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0){
    80003f62:	08052903          	lw	s2,128(a0)
    80003f66:	00091d63          	bnez	s2,80003f80 <bmap+0x70>
      addr = balloc(ip->dev);
    80003f6a:	4108                	lw	a0,0(a0)
    80003f6c:	00000097          	auipc	ra,0x0
    80003f70:	e6c080e7          	jalr	-404(ra) # 80003dd8 <balloc>
    80003f74:	0005091b          	sext.w	s2,a0
      if(addr == 0)
    80003f78:	02090d63          	beqz	s2,80003fb2 <bmap+0xa2>
        return 0;
      ip->addrs[NDIRECT] = addr;
    80003f7c:	0929a023          	sw	s2,128(s3)
    }
    bp = bread(ip->dev, addr);
    80003f80:	85ca                	mv	a1,s2
    80003f82:	0009a503          	lw	a0,0(s3)
    80003f86:	00000097          	auipc	ra,0x0
    80003f8a:	b90080e7          	jalr	-1136(ra) # 80003b16 <bread>
    80003f8e:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    80003f90:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    80003f94:	02049593          	slli	a1,s1,0x20
    80003f98:	9181                	srli	a1,a1,0x20
    80003f9a:	058a                	slli	a1,a1,0x2
    80003f9c:	00b784b3          	add	s1,a5,a1
    80003fa0:	0004a903          	lw	s2,0(s1)
    80003fa4:	02090063          	beqz	s2,80003fc4 <bmap+0xb4>
      if(addr){
        a[bn] = addr;
        log_write(bp);
      }
    }
    brelse(bp);
    80003fa8:	8552                	mv	a0,s4
    80003faa:	00000097          	auipc	ra,0x0
    80003fae:	c9c080e7          	jalr	-868(ra) # 80003c46 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    80003fb2:	854a                	mv	a0,s2
    80003fb4:	70a2                	ld	ra,40(sp)
    80003fb6:	7402                	ld	s0,32(sp)
    80003fb8:	64e2                	ld	s1,24(sp)
    80003fba:	6942                	ld	s2,16(sp)
    80003fbc:	69a2                	ld	s3,8(sp)
    80003fbe:	6a02                	ld	s4,0(sp)
    80003fc0:	6145                	addi	sp,sp,48
    80003fc2:	8082                	ret
      addr = balloc(ip->dev);
    80003fc4:	0009a503          	lw	a0,0(s3)
    80003fc8:	00000097          	auipc	ra,0x0
    80003fcc:	e10080e7          	jalr	-496(ra) # 80003dd8 <balloc>
    80003fd0:	0005091b          	sext.w	s2,a0
      if(addr){
    80003fd4:	fc090ae3          	beqz	s2,80003fa8 <bmap+0x98>
        a[bn] = addr;
    80003fd8:	0124a023          	sw	s2,0(s1)
        log_write(bp);
    80003fdc:	8552                	mv	a0,s4
    80003fde:	00001097          	auipc	ra,0x1
    80003fe2:	eec080e7          	jalr	-276(ra) # 80004eca <log_write>
    80003fe6:	b7c9                	j	80003fa8 <bmap+0x98>
  panic("bmap: out of range");
    80003fe8:	00004517          	auipc	a0,0x4
    80003fec:	78050513          	addi	a0,a0,1920 # 80008768 <syscalls+0x140>
    80003ff0:	ffffc097          	auipc	ra,0xffffc
    80003ff4:	554080e7          	jalr	1364(ra) # 80000544 <panic>

0000000080003ff8 <iget>:
{
    80003ff8:	7179                	addi	sp,sp,-48
    80003ffa:	f406                	sd	ra,40(sp)
    80003ffc:	f022                	sd	s0,32(sp)
    80003ffe:	ec26                	sd	s1,24(sp)
    80004000:	e84a                	sd	s2,16(sp)
    80004002:	e44e                	sd	s3,8(sp)
    80004004:	e052                	sd	s4,0(sp)
    80004006:	1800                	addi	s0,sp,48
    80004008:	89aa                	mv	s3,a0
    8000400a:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    8000400c:	0023d517          	auipc	a0,0x23d
    80004010:	41c50513          	addi	a0,a0,1052 # 80241428 <itable>
    80004014:	ffffd097          	auipc	ra,0xffffd
    80004018:	e98080e7          	jalr	-360(ra) # 80000eac <acquire>
  empty = 0;
    8000401c:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    8000401e:	0023d497          	auipc	s1,0x23d
    80004022:	42248493          	addi	s1,s1,1058 # 80241440 <itable+0x18>
    80004026:	0023f697          	auipc	a3,0x23f
    8000402a:	eaa68693          	addi	a3,a3,-342 # 80242ed0 <log>
    8000402e:	a039                	j	8000403c <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80004030:	02090b63          	beqz	s2,80004066 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80004034:	08848493          	addi	s1,s1,136
    80004038:	02d48a63          	beq	s1,a3,8000406c <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    8000403c:	449c                	lw	a5,8(s1)
    8000403e:	fef059e3          	blez	a5,80004030 <iget+0x38>
    80004042:	4098                	lw	a4,0(s1)
    80004044:	ff3716e3          	bne	a4,s3,80004030 <iget+0x38>
    80004048:	40d8                	lw	a4,4(s1)
    8000404a:	ff4713e3          	bne	a4,s4,80004030 <iget+0x38>
      ip->ref++;
    8000404e:	2785                	addiw	a5,a5,1
    80004050:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    80004052:	0023d517          	auipc	a0,0x23d
    80004056:	3d650513          	addi	a0,a0,982 # 80241428 <itable>
    8000405a:	ffffd097          	auipc	ra,0xffffd
    8000405e:	f06080e7          	jalr	-250(ra) # 80000f60 <release>
      return ip;
    80004062:	8926                	mv	s2,s1
    80004064:	a03d                	j	80004092 <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    80004066:	f7f9                	bnez	a5,80004034 <iget+0x3c>
    80004068:	8926                	mv	s2,s1
    8000406a:	b7e9                	j	80004034 <iget+0x3c>
  if(empty == 0)
    8000406c:	02090c63          	beqz	s2,800040a4 <iget+0xac>
  ip->dev = dev;
    80004070:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    80004074:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    80004078:	4785                	li	a5,1
    8000407a:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    8000407e:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    80004082:	0023d517          	auipc	a0,0x23d
    80004086:	3a650513          	addi	a0,a0,934 # 80241428 <itable>
    8000408a:	ffffd097          	auipc	ra,0xffffd
    8000408e:	ed6080e7          	jalr	-298(ra) # 80000f60 <release>
}
    80004092:	854a                	mv	a0,s2
    80004094:	70a2                	ld	ra,40(sp)
    80004096:	7402                	ld	s0,32(sp)
    80004098:	64e2                	ld	s1,24(sp)
    8000409a:	6942                	ld	s2,16(sp)
    8000409c:	69a2                	ld	s3,8(sp)
    8000409e:	6a02                	ld	s4,0(sp)
    800040a0:	6145                	addi	sp,sp,48
    800040a2:	8082                	ret
    panic("iget: no inodes");
    800040a4:	00004517          	auipc	a0,0x4
    800040a8:	6dc50513          	addi	a0,a0,1756 # 80008780 <syscalls+0x158>
    800040ac:	ffffc097          	auipc	ra,0xffffc
    800040b0:	498080e7          	jalr	1176(ra) # 80000544 <panic>

00000000800040b4 <fsinit>:
fsinit(int dev) {
    800040b4:	7179                	addi	sp,sp,-48
    800040b6:	f406                	sd	ra,40(sp)
    800040b8:	f022                	sd	s0,32(sp)
    800040ba:	ec26                	sd	s1,24(sp)
    800040bc:	e84a                	sd	s2,16(sp)
    800040be:	e44e                	sd	s3,8(sp)
    800040c0:	1800                	addi	s0,sp,48
    800040c2:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    800040c4:	4585                	li	a1,1
    800040c6:	00000097          	auipc	ra,0x0
    800040ca:	a50080e7          	jalr	-1456(ra) # 80003b16 <bread>
    800040ce:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    800040d0:	0023d997          	auipc	s3,0x23d
    800040d4:	33898993          	addi	s3,s3,824 # 80241408 <sb>
    800040d8:	02000613          	li	a2,32
    800040dc:	05850593          	addi	a1,a0,88
    800040e0:	854e                	mv	a0,s3
    800040e2:	ffffd097          	auipc	ra,0xffffd
    800040e6:	f26080e7          	jalr	-218(ra) # 80001008 <memmove>
  brelse(bp);
    800040ea:	8526                	mv	a0,s1
    800040ec:	00000097          	auipc	ra,0x0
    800040f0:	b5a080e7          	jalr	-1190(ra) # 80003c46 <brelse>
  if(sb.magic != FSMAGIC)
    800040f4:	0009a703          	lw	a4,0(s3)
    800040f8:	102037b7          	lui	a5,0x10203
    800040fc:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    80004100:	02f71263          	bne	a4,a5,80004124 <fsinit+0x70>
  initlog(dev, &sb);
    80004104:	0023d597          	auipc	a1,0x23d
    80004108:	30458593          	addi	a1,a1,772 # 80241408 <sb>
    8000410c:	854a                	mv	a0,s2
    8000410e:	00001097          	auipc	ra,0x1
    80004112:	b40080e7          	jalr	-1216(ra) # 80004c4e <initlog>
}
    80004116:	70a2                	ld	ra,40(sp)
    80004118:	7402                	ld	s0,32(sp)
    8000411a:	64e2                	ld	s1,24(sp)
    8000411c:	6942                	ld	s2,16(sp)
    8000411e:	69a2                	ld	s3,8(sp)
    80004120:	6145                	addi	sp,sp,48
    80004122:	8082                	ret
    panic("invalid file system");
    80004124:	00004517          	auipc	a0,0x4
    80004128:	66c50513          	addi	a0,a0,1644 # 80008790 <syscalls+0x168>
    8000412c:	ffffc097          	auipc	ra,0xffffc
    80004130:	418080e7          	jalr	1048(ra) # 80000544 <panic>

0000000080004134 <iinit>:
{
    80004134:	7179                	addi	sp,sp,-48
    80004136:	f406                	sd	ra,40(sp)
    80004138:	f022                	sd	s0,32(sp)
    8000413a:	ec26                	sd	s1,24(sp)
    8000413c:	e84a                	sd	s2,16(sp)
    8000413e:	e44e                	sd	s3,8(sp)
    80004140:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    80004142:	00004597          	auipc	a1,0x4
    80004146:	66658593          	addi	a1,a1,1638 # 800087a8 <syscalls+0x180>
    8000414a:	0023d517          	auipc	a0,0x23d
    8000414e:	2de50513          	addi	a0,a0,734 # 80241428 <itable>
    80004152:	ffffd097          	auipc	ra,0xffffd
    80004156:	cca080e7          	jalr	-822(ra) # 80000e1c <initlock>
  for(i = 0; i < NINODE; i++) {
    8000415a:	0023d497          	auipc	s1,0x23d
    8000415e:	2f648493          	addi	s1,s1,758 # 80241450 <itable+0x28>
    80004162:	0023f997          	auipc	s3,0x23f
    80004166:	d7e98993          	addi	s3,s3,-642 # 80242ee0 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    8000416a:	00004917          	auipc	s2,0x4
    8000416e:	64690913          	addi	s2,s2,1606 # 800087b0 <syscalls+0x188>
    80004172:	85ca                	mv	a1,s2
    80004174:	8526                	mv	a0,s1
    80004176:	00001097          	auipc	ra,0x1
    8000417a:	e3a080e7          	jalr	-454(ra) # 80004fb0 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    8000417e:	08848493          	addi	s1,s1,136
    80004182:	ff3498e3          	bne	s1,s3,80004172 <iinit+0x3e>
}
    80004186:	70a2                	ld	ra,40(sp)
    80004188:	7402                	ld	s0,32(sp)
    8000418a:	64e2                	ld	s1,24(sp)
    8000418c:	6942                	ld	s2,16(sp)
    8000418e:	69a2                	ld	s3,8(sp)
    80004190:	6145                	addi	sp,sp,48
    80004192:	8082                	ret

0000000080004194 <ialloc>:
{
    80004194:	715d                	addi	sp,sp,-80
    80004196:	e486                	sd	ra,72(sp)
    80004198:	e0a2                	sd	s0,64(sp)
    8000419a:	fc26                	sd	s1,56(sp)
    8000419c:	f84a                	sd	s2,48(sp)
    8000419e:	f44e                	sd	s3,40(sp)
    800041a0:	f052                	sd	s4,32(sp)
    800041a2:	ec56                	sd	s5,24(sp)
    800041a4:	e85a                	sd	s6,16(sp)
    800041a6:	e45e                	sd	s7,8(sp)
    800041a8:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    800041aa:	0023d717          	auipc	a4,0x23d
    800041ae:	26a72703          	lw	a4,618(a4) # 80241414 <sb+0xc>
    800041b2:	4785                	li	a5,1
    800041b4:	04e7fa63          	bgeu	a5,a4,80004208 <ialloc+0x74>
    800041b8:	8aaa                	mv	s5,a0
    800041ba:	8bae                	mv	s7,a1
    800041bc:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    800041be:	0023da17          	auipc	s4,0x23d
    800041c2:	24aa0a13          	addi	s4,s4,586 # 80241408 <sb>
    800041c6:	00048b1b          	sext.w	s6,s1
    800041ca:	0044d593          	srli	a1,s1,0x4
    800041ce:	018a2783          	lw	a5,24(s4)
    800041d2:	9dbd                	addw	a1,a1,a5
    800041d4:	8556                	mv	a0,s5
    800041d6:	00000097          	auipc	ra,0x0
    800041da:	940080e7          	jalr	-1728(ra) # 80003b16 <bread>
    800041de:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    800041e0:	05850993          	addi	s3,a0,88
    800041e4:	00f4f793          	andi	a5,s1,15
    800041e8:	079a                	slli	a5,a5,0x6
    800041ea:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    800041ec:	00099783          	lh	a5,0(s3)
    800041f0:	c3a1                	beqz	a5,80004230 <ialloc+0x9c>
    brelse(bp);
    800041f2:	00000097          	auipc	ra,0x0
    800041f6:	a54080e7          	jalr	-1452(ra) # 80003c46 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    800041fa:	0485                	addi	s1,s1,1
    800041fc:	00ca2703          	lw	a4,12(s4)
    80004200:	0004879b          	sext.w	a5,s1
    80004204:	fce7e1e3          	bltu	a5,a4,800041c6 <ialloc+0x32>
  printf("ialloc: no inodes\n");
    80004208:	00004517          	auipc	a0,0x4
    8000420c:	5b050513          	addi	a0,a0,1456 # 800087b8 <syscalls+0x190>
    80004210:	ffffc097          	auipc	ra,0xffffc
    80004214:	37e080e7          	jalr	894(ra) # 8000058e <printf>
  return 0;
    80004218:	4501                	li	a0,0
}
    8000421a:	60a6                	ld	ra,72(sp)
    8000421c:	6406                	ld	s0,64(sp)
    8000421e:	74e2                	ld	s1,56(sp)
    80004220:	7942                	ld	s2,48(sp)
    80004222:	79a2                	ld	s3,40(sp)
    80004224:	7a02                	ld	s4,32(sp)
    80004226:	6ae2                	ld	s5,24(sp)
    80004228:	6b42                	ld	s6,16(sp)
    8000422a:	6ba2                	ld	s7,8(sp)
    8000422c:	6161                	addi	sp,sp,80
    8000422e:	8082                	ret
      memset(dip, 0, sizeof(*dip));
    80004230:	04000613          	li	a2,64
    80004234:	4581                	li	a1,0
    80004236:	854e                	mv	a0,s3
    80004238:	ffffd097          	auipc	ra,0xffffd
    8000423c:	d70080e7          	jalr	-656(ra) # 80000fa8 <memset>
      dip->type = type;
    80004240:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    80004244:	854a                	mv	a0,s2
    80004246:	00001097          	auipc	ra,0x1
    8000424a:	c84080e7          	jalr	-892(ra) # 80004eca <log_write>
      brelse(bp);
    8000424e:	854a                	mv	a0,s2
    80004250:	00000097          	auipc	ra,0x0
    80004254:	9f6080e7          	jalr	-1546(ra) # 80003c46 <brelse>
      return iget(dev, inum);
    80004258:	85da                	mv	a1,s6
    8000425a:	8556                	mv	a0,s5
    8000425c:	00000097          	auipc	ra,0x0
    80004260:	d9c080e7          	jalr	-612(ra) # 80003ff8 <iget>
    80004264:	bf5d                	j	8000421a <ialloc+0x86>

0000000080004266 <iupdate>:
{
    80004266:	1101                	addi	sp,sp,-32
    80004268:	ec06                	sd	ra,24(sp)
    8000426a:	e822                	sd	s0,16(sp)
    8000426c:	e426                	sd	s1,8(sp)
    8000426e:	e04a                	sd	s2,0(sp)
    80004270:	1000                	addi	s0,sp,32
    80004272:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80004274:	415c                	lw	a5,4(a0)
    80004276:	0047d79b          	srliw	a5,a5,0x4
    8000427a:	0023d597          	auipc	a1,0x23d
    8000427e:	1a65a583          	lw	a1,422(a1) # 80241420 <sb+0x18>
    80004282:	9dbd                	addw	a1,a1,a5
    80004284:	4108                	lw	a0,0(a0)
    80004286:	00000097          	auipc	ra,0x0
    8000428a:	890080e7          	jalr	-1904(ra) # 80003b16 <bread>
    8000428e:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80004290:	05850793          	addi	a5,a0,88
    80004294:	40c8                	lw	a0,4(s1)
    80004296:	893d                	andi	a0,a0,15
    80004298:	051a                	slli	a0,a0,0x6
    8000429a:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    8000429c:	04449703          	lh	a4,68(s1)
    800042a0:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    800042a4:	04649703          	lh	a4,70(s1)
    800042a8:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    800042ac:	04849703          	lh	a4,72(s1)
    800042b0:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    800042b4:	04a49703          	lh	a4,74(s1)
    800042b8:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    800042bc:	44f8                	lw	a4,76(s1)
    800042be:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    800042c0:	03400613          	li	a2,52
    800042c4:	05048593          	addi	a1,s1,80
    800042c8:	0531                	addi	a0,a0,12
    800042ca:	ffffd097          	auipc	ra,0xffffd
    800042ce:	d3e080e7          	jalr	-706(ra) # 80001008 <memmove>
  log_write(bp);
    800042d2:	854a                	mv	a0,s2
    800042d4:	00001097          	auipc	ra,0x1
    800042d8:	bf6080e7          	jalr	-1034(ra) # 80004eca <log_write>
  brelse(bp);
    800042dc:	854a                	mv	a0,s2
    800042de:	00000097          	auipc	ra,0x0
    800042e2:	968080e7          	jalr	-1688(ra) # 80003c46 <brelse>
}
    800042e6:	60e2                	ld	ra,24(sp)
    800042e8:	6442                	ld	s0,16(sp)
    800042ea:	64a2                	ld	s1,8(sp)
    800042ec:	6902                	ld	s2,0(sp)
    800042ee:	6105                	addi	sp,sp,32
    800042f0:	8082                	ret

00000000800042f2 <idup>:
{
    800042f2:	1101                	addi	sp,sp,-32
    800042f4:	ec06                	sd	ra,24(sp)
    800042f6:	e822                	sd	s0,16(sp)
    800042f8:	e426                	sd	s1,8(sp)
    800042fa:	1000                	addi	s0,sp,32
    800042fc:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800042fe:	0023d517          	auipc	a0,0x23d
    80004302:	12a50513          	addi	a0,a0,298 # 80241428 <itable>
    80004306:	ffffd097          	auipc	ra,0xffffd
    8000430a:	ba6080e7          	jalr	-1114(ra) # 80000eac <acquire>
  ip->ref++;
    8000430e:	449c                	lw	a5,8(s1)
    80004310:	2785                	addiw	a5,a5,1
    80004312:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80004314:	0023d517          	auipc	a0,0x23d
    80004318:	11450513          	addi	a0,a0,276 # 80241428 <itable>
    8000431c:	ffffd097          	auipc	ra,0xffffd
    80004320:	c44080e7          	jalr	-956(ra) # 80000f60 <release>
}
    80004324:	8526                	mv	a0,s1
    80004326:	60e2                	ld	ra,24(sp)
    80004328:	6442                	ld	s0,16(sp)
    8000432a:	64a2                	ld	s1,8(sp)
    8000432c:	6105                	addi	sp,sp,32
    8000432e:	8082                	ret

0000000080004330 <ilock>:
{
    80004330:	1101                	addi	sp,sp,-32
    80004332:	ec06                	sd	ra,24(sp)
    80004334:	e822                	sd	s0,16(sp)
    80004336:	e426                	sd	s1,8(sp)
    80004338:	e04a                	sd	s2,0(sp)
    8000433a:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    8000433c:	c115                	beqz	a0,80004360 <ilock+0x30>
    8000433e:	84aa                	mv	s1,a0
    80004340:	451c                	lw	a5,8(a0)
    80004342:	00f05f63          	blez	a5,80004360 <ilock+0x30>
  acquiresleep(&ip->lock);
    80004346:	0541                	addi	a0,a0,16
    80004348:	00001097          	auipc	ra,0x1
    8000434c:	ca2080e7          	jalr	-862(ra) # 80004fea <acquiresleep>
  if(ip->valid == 0){
    80004350:	40bc                	lw	a5,64(s1)
    80004352:	cf99                	beqz	a5,80004370 <ilock+0x40>
}
    80004354:	60e2                	ld	ra,24(sp)
    80004356:	6442                	ld	s0,16(sp)
    80004358:	64a2                	ld	s1,8(sp)
    8000435a:	6902                	ld	s2,0(sp)
    8000435c:	6105                	addi	sp,sp,32
    8000435e:	8082                	ret
    panic("ilock");
    80004360:	00004517          	auipc	a0,0x4
    80004364:	47050513          	addi	a0,a0,1136 # 800087d0 <syscalls+0x1a8>
    80004368:	ffffc097          	auipc	ra,0xffffc
    8000436c:	1dc080e7          	jalr	476(ra) # 80000544 <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    80004370:	40dc                	lw	a5,4(s1)
    80004372:	0047d79b          	srliw	a5,a5,0x4
    80004376:	0023d597          	auipc	a1,0x23d
    8000437a:	0aa5a583          	lw	a1,170(a1) # 80241420 <sb+0x18>
    8000437e:	9dbd                	addw	a1,a1,a5
    80004380:	4088                	lw	a0,0(s1)
    80004382:	fffff097          	auipc	ra,0xfffff
    80004386:	794080e7          	jalr	1940(ra) # 80003b16 <bread>
    8000438a:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    8000438c:	05850593          	addi	a1,a0,88
    80004390:	40dc                	lw	a5,4(s1)
    80004392:	8bbd                	andi	a5,a5,15
    80004394:	079a                	slli	a5,a5,0x6
    80004396:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80004398:	00059783          	lh	a5,0(a1)
    8000439c:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    800043a0:	00259783          	lh	a5,2(a1)
    800043a4:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    800043a8:	00459783          	lh	a5,4(a1)
    800043ac:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    800043b0:	00659783          	lh	a5,6(a1)
    800043b4:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    800043b8:	459c                	lw	a5,8(a1)
    800043ba:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    800043bc:	03400613          	li	a2,52
    800043c0:	05b1                	addi	a1,a1,12
    800043c2:	05048513          	addi	a0,s1,80
    800043c6:	ffffd097          	auipc	ra,0xffffd
    800043ca:	c42080e7          	jalr	-958(ra) # 80001008 <memmove>
    brelse(bp);
    800043ce:	854a                	mv	a0,s2
    800043d0:	00000097          	auipc	ra,0x0
    800043d4:	876080e7          	jalr	-1930(ra) # 80003c46 <brelse>
    ip->valid = 1;
    800043d8:	4785                	li	a5,1
    800043da:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    800043dc:	04449783          	lh	a5,68(s1)
    800043e0:	fbb5                	bnez	a5,80004354 <ilock+0x24>
      panic("ilock: no type");
    800043e2:	00004517          	auipc	a0,0x4
    800043e6:	3f650513          	addi	a0,a0,1014 # 800087d8 <syscalls+0x1b0>
    800043ea:	ffffc097          	auipc	ra,0xffffc
    800043ee:	15a080e7          	jalr	346(ra) # 80000544 <panic>

00000000800043f2 <iunlock>:
{
    800043f2:	1101                	addi	sp,sp,-32
    800043f4:	ec06                	sd	ra,24(sp)
    800043f6:	e822                	sd	s0,16(sp)
    800043f8:	e426                	sd	s1,8(sp)
    800043fa:	e04a                	sd	s2,0(sp)
    800043fc:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    800043fe:	c905                	beqz	a0,8000442e <iunlock+0x3c>
    80004400:	84aa                	mv	s1,a0
    80004402:	01050913          	addi	s2,a0,16
    80004406:	854a                	mv	a0,s2
    80004408:	00001097          	auipc	ra,0x1
    8000440c:	c7c080e7          	jalr	-900(ra) # 80005084 <holdingsleep>
    80004410:	cd19                	beqz	a0,8000442e <iunlock+0x3c>
    80004412:	449c                	lw	a5,8(s1)
    80004414:	00f05d63          	blez	a5,8000442e <iunlock+0x3c>
  releasesleep(&ip->lock);
    80004418:	854a                	mv	a0,s2
    8000441a:	00001097          	auipc	ra,0x1
    8000441e:	c26080e7          	jalr	-986(ra) # 80005040 <releasesleep>
}
    80004422:	60e2                	ld	ra,24(sp)
    80004424:	6442                	ld	s0,16(sp)
    80004426:	64a2                	ld	s1,8(sp)
    80004428:	6902                	ld	s2,0(sp)
    8000442a:	6105                	addi	sp,sp,32
    8000442c:	8082                	ret
    panic("iunlock");
    8000442e:	00004517          	auipc	a0,0x4
    80004432:	3ba50513          	addi	a0,a0,954 # 800087e8 <syscalls+0x1c0>
    80004436:	ffffc097          	auipc	ra,0xffffc
    8000443a:	10e080e7          	jalr	270(ra) # 80000544 <panic>

000000008000443e <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    8000443e:	7179                	addi	sp,sp,-48
    80004440:	f406                	sd	ra,40(sp)
    80004442:	f022                	sd	s0,32(sp)
    80004444:	ec26                	sd	s1,24(sp)
    80004446:	e84a                	sd	s2,16(sp)
    80004448:	e44e                	sd	s3,8(sp)
    8000444a:	e052                	sd	s4,0(sp)
    8000444c:	1800                	addi	s0,sp,48
    8000444e:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80004450:	05050493          	addi	s1,a0,80
    80004454:	08050913          	addi	s2,a0,128
    80004458:	a021                	j	80004460 <itrunc+0x22>
    8000445a:	0491                	addi	s1,s1,4
    8000445c:	01248d63          	beq	s1,s2,80004476 <itrunc+0x38>
    if(ip->addrs[i]){
    80004460:	408c                	lw	a1,0(s1)
    80004462:	dde5                	beqz	a1,8000445a <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80004464:	0009a503          	lw	a0,0(s3)
    80004468:	00000097          	auipc	ra,0x0
    8000446c:	8f4080e7          	jalr	-1804(ra) # 80003d5c <bfree>
      ip->addrs[i] = 0;
    80004470:	0004a023          	sw	zero,0(s1)
    80004474:	b7dd                	j	8000445a <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80004476:	0809a583          	lw	a1,128(s3)
    8000447a:	e185                	bnez	a1,8000449a <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    8000447c:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80004480:	854e                	mv	a0,s3
    80004482:	00000097          	auipc	ra,0x0
    80004486:	de4080e7          	jalr	-540(ra) # 80004266 <iupdate>
}
    8000448a:	70a2                	ld	ra,40(sp)
    8000448c:	7402                	ld	s0,32(sp)
    8000448e:	64e2                	ld	s1,24(sp)
    80004490:	6942                	ld	s2,16(sp)
    80004492:	69a2                	ld	s3,8(sp)
    80004494:	6a02                	ld	s4,0(sp)
    80004496:	6145                	addi	sp,sp,48
    80004498:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    8000449a:	0009a503          	lw	a0,0(s3)
    8000449e:	fffff097          	auipc	ra,0xfffff
    800044a2:	678080e7          	jalr	1656(ra) # 80003b16 <bread>
    800044a6:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    800044a8:	05850493          	addi	s1,a0,88
    800044ac:	45850913          	addi	s2,a0,1112
    800044b0:	a811                	j	800044c4 <itrunc+0x86>
        bfree(ip->dev, a[j]);
    800044b2:	0009a503          	lw	a0,0(s3)
    800044b6:	00000097          	auipc	ra,0x0
    800044ba:	8a6080e7          	jalr	-1882(ra) # 80003d5c <bfree>
    for(j = 0; j < NINDIRECT; j++){
    800044be:	0491                	addi	s1,s1,4
    800044c0:	01248563          	beq	s1,s2,800044ca <itrunc+0x8c>
      if(a[j])
    800044c4:	408c                	lw	a1,0(s1)
    800044c6:	dde5                	beqz	a1,800044be <itrunc+0x80>
    800044c8:	b7ed                	j	800044b2 <itrunc+0x74>
    brelse(bp);
    800044ca:	8552                	mv	a0,s4
    800044cc:	fffff097          	auipc	ra,0xfffff
    800044d0:	77a080e7          	jalr	1914(ra) # 80003c46 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    800044d4:	0809a583          	lw	a1,128(s3)
    800044d8:	0009a503          	lw	a0,0(s3)
    800044dc:	00000097          	auipc	ra,0x0
    800044e0:	880080e7          	jalr	-1920(ra) # 80003d5c <bfree>
    ip->addrs[NDIRECT] = 0;
    800044e4:	0809a023          	sw	zero,128(s3)
    800044e8:	bf51                	j	8000447c <itrunc+0x3e>

00000000800044ea <iput>:
{
    800044ea:	1101                	addi	sp,sp,-32
    800044ec:	ec06                	sd	ra,24(sp)
    800044ee:	e822                	sd	s0,16(sp)
    800044f0:	e426                	sd	s1,8(sp)
    800044f2:	e04a                	sd	s2,0(sp)
    800044f4:	1000                	addi	s0,sp,32
    800044f6:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    800044f8:	0023d517          	auipc	a0,0x23d
    800044fc:	f3050513          	addi	a0,a0,-208 # 80241428 <itable>
    80004500:	ffffd097          	auipc	ra,0xffffd
    80004504:	9ac080e7          	jalr	-1620(ra) # 80000eac <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004508:	4498                	lw	a4,8(s1)
    8000450a:	4785                	li	a5,1
    8000450c:	02f70363          	beq	a4,a5,80004532 <iput+0x48>
  ip->ref--;
    80004510:	449c                	lw	a5,8(s1)
    80004512:	37fd                	addiw	a5,a5,-1
    80004514:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80004516:	0023d517          	auipc	a0,0x23d
    8000451a:	f1250513          	addi	a0,a0,-238 # 80241428 <itable>
    8000451e:	ffffd097          	auipc	ra,0xffffd
    80004522:	a42080e7          	jalr	-1470(ra) # 80000f60 <release>
}
    80004526:	60e2                	ld	ra,24(sp)
    80004528:	6442                	ld	s0,16(sp)
    8000452a:	64a2                	ld	s1,8(sp)
    8000452c:	6902                	ld	s2,0(sp)
    8000452e:	6105                	addi	sp,sp,32
    80004530:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80004532:	40bc                	lw	a5,64(s1)
    80004534:	dff1                	beqz	a5,80004510 <iput+0x26>
    80004536:	04a49783          	lh	a5,74(s1)
    8000453a:	fbf9                	bnez	a5,80004510 <iput+0x26>
    acquiresleep(&ip->lock);
    8000453c:	01048913          	addi	s2,s1,16
    80004540:	854a                	mv	a0,s2
    80004542:	00001097          	auipc	ra,0x1
    80004546:	aa8080e7          	jalr	-1368(ra) # 80004fea <acquiresleep>
    release(&itable.lock);
    8000454a:	0023d517          	auipc	a0,0x23d
    8000454e:	ede50513          	addi	a0,a0,-290 # 80241428 <itable>
    80004552:	ffffd097          	auipc	ra,0xffffd
    80004556:	a0e080e7          	jalr	-1522(ra) # 80000f60 <release>
    itrunc(ip);
    8000455a:	8526                	mv	a0,s1
    8000455c:	00000097          	auipc	ra,0x0
    80004560:	ee2080e7          	jalr	-286(ra) # 8000443e <itrunc>
    ip->type = 0;
    80004564:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80004568:	8526                	mv	a0,s1
    8000456a:	00000097          	auipc	ra,0x0
    8000456e:	cfc080e7          	jalr	-772(ra) # 80004266 <iupdate>
    ip->valid = 0;
    80004572:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80004576:	854a                	mv	a0,s2
    80004578:	00001097          	auipc	ra,0x1
    8000457c:	ac8080e7          	jalr	-1336(ra) # 80005040 <releasesleep>
    acquire(&itable.lock);
    80004580:	0023d517          	auipc	a0,0x23d
    80004584:	ea850513          	addi	a0,a0,-344 # 80241428 <itable>
    80004588:	ffffd097          	auipc	ra,0xffffd
    8000458c:	924080e7          	jalr	-1756(ra) # 80000eac <acquire>
    80004590:	b741                	j	80004510 <iput+0x26>

0000000080004592 <iunlockput>:
{
    80004592:	1101                	addi	sp,sp,-32
    80004594:	ec06                	sd	ra,24(sp)
    80004596:	e822                	sd	s0,16(sp)
    80004598:	e426                	sd	s1,8(sp)
    8000459a:	1000                	addi	s0,sp,32
    8000459c:	84aa                	mv	s1,a0
  iunlock(ip);
    8000459e:	00000097          	auipc	ra,0x0
    800045a2:	e54080e7          	jalr	-428(ra) # 800043f2 <iunlock>
  iput(ip);
    800045a6:	8526                	mv	a0,s1
    800045a8:	00000097          	auipc	ra,0x0
    800045ac:	f42080e7          	jalr	-190(ra) # 800044ea <iput>
}
    800045b0:	60e2                	ld	ra,24(sp)
    800045b2:	6442                	ld	s0,16(sp)
    800045b4:	64a2                	ld	s1,8(sp)
    800045b6:	6105                	addi	sp,sp,32
    800045b8:	8082                	ret

00000000800045ba <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    800045ba:	1141                	addi	sp,sp,-16
    800045bc:	e422                	sd	s0,8(sp)
    800045be:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    800045c0:	411c                	lw	a5,0(a0)
    800045c2:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    800045c4:	415c                	lw	a5,4(a0)
    800045c6:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    800045c8:	04451783          	lh	a5,68(a0)
    800045cc:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    800045d0:	04a51783          	lh	a5,74(a0)
    800045d4:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    800045d8:	04c56783          	lwu	a5,76(a0)
    800045dc:	e99c                	sd	a5,16(a1)
}
    800045de:	6422                	ld	s0,8(sp)
    800045e0:	0141                	addi	sp,sp,16
    800045e2:	8082                	ret

00000000800045e4 <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800045e4:	457c                	lw	a5,76(a0)
    800045e6:	0ed7e963          	bltu	a5,a3,800046d8 <readi+0xf4>
{
    800045ea:	7159                	addi	sp,sp,-112
    800045ec:	f486                	sd	ra,104(sp)
    800045ee:	f0a2                	sd	s0,96(sp)
    800045f0:	eca6                	sd	s1,88(sp)
    800045f2:	e8ca                	sd	s2,80(sp)
    800045f4:	e4ce                	sd	s3,72(sp)
    800045f6:	e0d2                	sd	s4,64(sp)
    800045f8:	fc56                	sd	s5,56(sp)
    800045fa:	f85a                	sd	s6,48(sp)
    800045fc:	f45e                	sd	s7,40(sp)
    800045fe:	f062                	sd	s8,32(sp)
    80004600:	ec66                	sd	s9,24(sp)
    80004602:	e86a                	sd	s10,16(sp)
    80004604:	e46e                	sd	s11,8(sp)
    80004606:	1880                	addi	s0,sp,112
    80004608:	8b2a                	mv	s6,a0
    8000460a:	8bae                	mv	s7,a1
    8000460c:	8a32                	mv	s4,a2
    8000460e:	84b6                	mv	s1,a3
    80004610:	8aba                	mv	s5,a4
  if(off > ip->size || off + n < off)
    80004612:	9f35                	addw	a4,a4,a3
    return 0;
    80004614:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80004616:	0ad76063          	bltu	a4,a3,800046b6 <readi+0xd2>
  if(off + n > ip->size)
    8000461a:	00e7f463          	bgeu	a5,a4,80004622 <readi+0x3e>
    n = ip->size - off;
    8000461e:	40d78abb          	subw	s5,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80004622:	0a0a8963          	beqz	s5,800046d4 <readi+0xf0>
    80004626:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80004628:	40000c93          	li	s9,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    8000462c:	5c7d                	li	s8,-1
    8000462e:	a82d                	j	80004668 <readi+0x84>
    80004630:	020d1d93          	slli	s11,s10,0x20
    80004634:	020ddd93          	srli	s11,s11,0x20
    80004638:	05890613          	addi	a2,s2,88
    8000463c:	86ee                	mv	a3,s11
    8000463e:	963a                	add	a2,a2,a4
    80004640:	85d2                	mv	a1,s4
    80004642:	855e                	mv	a0,s7
    80004644:	ffffe097          	auipc	ra,0xffffe
    80004648:	42e080e7          	jalr	1070(ra) # 80002a72 <either_copyout>
    8000464c:	05850d63          	beq	a0,s8,800046a6 <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80004650:	854a                	mv	a0,s2
    80004652:	fffff097          	auipc	ra,0xfffff
    80004656:	5f4080e7          	jalr	1524(ra) # 80003c46 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    8000465a:	013d09bb          	addw	s3,s10,s3
    8000465e:	009d04bb          	addw	s1,s10,s1
    80004662:	9a6e                	add	s4,s4,s11
    80004664:	0559f763          	bgeu	s3,s5,800046b2 <readi+0xce>
    uint addr = bmap(ip, off/BSIZE);
    80004668:	00a4d59b          	srliw	a1,s1,0xa
    8000466c:	855a                	mv	a0,s6
    8000466e:	00000097          	auipc	ra,0x0
    80004672:	8a2080e7          	jalr	-1886(ra) # 80003f10 <bmap>
    80004676:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    8000467a:	cd85                	beqz	a1,800046b2 <readi+0xce>
    bp = bread(ip->dev, addr);
    8000467c:	000b2503          	lw	a0,0(s6)
    80004680:	fffff097          	auipc	ra,0xfffff
    80004684:	496080e7          	jalr	1174(ra) # 80003b16 <bread>
    80004688:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000468a:	3ff4f713          	andi	a4,s1,1023
    8000468e:	40ec87bb          	subw	a5,s9,a4
    80004692:	413a86bb          	subw	a3,s5,s3
    80004696:	8d3e                	mv	s10,a5
    80004698:	2781                	sext.w	a5,a5
    8000469a:	0006861b          	sext.w	a2,a3
    8000469e:	f8f679e3          	bgeu	a2,a5,80004630 <readi+0x4c>
    800046a2:	8d36                	mv	s10,a3
    800046a4:	b771                	j	80004630 <readi+0x4c>
      brelse(bp);
    800046a6:	854a                	mv	a0,s2
    800046a8:	fffff097          	auipc	ra,0xfffff
    800046ac:	59e080e7          	jalr	1438(ra) # 80003c46 <brelse>
      tot = -1;
    800046b0:	59fd                	li	s3,-1
  }
  return tot;
    800046b2:	0009851b          	sext.w	a0,s3
}
    800046b6:	70a6                	ld	ra,104(sp)
    800046b8:	7406                	ld	s0,96(sp)
    800046ba:	64e6                	ld	s1,88(sp)
    800046bc:	6946                	ld	s2,80(sp)
    800046be:	69a6                	ld	s3,72(sp)
    800046c0:	6a06                	ld	s4,64(sp)
    800046c2:	7ae2                	ld	s5,56(sp)
    800046c4:	7b42                	ld	s6,48(sp)
    800046c6:	7ba2                	ld	s7,40(sp)
    800046c8:	7c02                	ld	s8,32(sp)
    800046ca:	6ce2                	ld	s9,24(sp)
    800046cc:	6d42                	ld	s10,16(sp)
    800046ce:	6da2                	ld	s11,8(sp)
    800046d0:	6165                	addi	sp,sp,112
    800046d2:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    800046d4:	89d6                	mv	s3,s5
    800046d6:	bff1                	j	800046b2 <readi+0xce>
    return 0;
    800046d8:	4501                	li	a0,0
}
    800046da:	8082                	ret

00000000800046dc <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    800046dc:	457c                	lw	a5,76(a0)
    800046de:	10d7e863          	bltu	a5,a3,800047ee <writei+0x112>
{
    800046e2:	7159                	addi	sp,sp,-112
    800046e4:	f486                	sd	ra,104(sp)
    800046e6:	f0a2                	sd	s0,96(sp)
    800046e8:	eca6                	sd	s1,88(sp)
    800046ea:	e8ca                	sd	s2,80(sp)
    800046ec:	e4ce                	sd	s3,72(sp)
    800046ee:	e0d2                	sd	s4,64(sp)
    800046f0:	fc56                	sd	s5,56(sp)
    800046f2:	f85a                	sd	s6,48(sp)
    800046f4:	f45e                	sd	s7,40(sp)
    800046f6:	f062                	sd	s8,32(sp)
    800046f8:	ec66                	sd	s9,24(sp)
    800046fa:	e86a                	sd	s10,16(sp)
    800046fc:	e46e                	sd	s11,8(sp)
    800046fe:	1880                	addi	s0,sp,112
    80004700:	8aaa                	mv	s5,a0
    80004702:	8bae                	mv	s7,a1
    80004704:	8a32                	mv	s4,a2
    80004706:	8936                	mv	s2,a3
    80004708:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    8000470a:	00e687bb          	addw	a5,a3,a4
    8000470e:	0ed7e263          	bltu	a5,a3,800047f2 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80004712:	00043737          	lui	a4,0x43
    80004716:	0ef76063          	bltu	a4,a5,800047f6 <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000471a:	0c0b0863          	beqz	s6,800047ea <writei+0x10e>
    8000471e:	4981                	li	s3,0
    uint addr = bmap(ip, off/BSIZE);
    if(addr == 0)
      break;
    bp = bread(ip->dev, addr);
    m = min(n - tot, BSIZE - off%BSIZE);
    80004720:	40000c93          	li	s9,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80004724:	5c7d                	li	s8,-1
    80004726:	a091                	j	8000476a <writei+0x8e>
    80004728:	020d1d93          	slli	s11,s10,0x20
    8000472c:	020ddd93          	srli	s11,s11,0x20
    80004730:	05848513          	addi	a0,s1,88
    80004734:	86ee                	mv	a3,s11
    80004736:	8652                	mv	a2,s4
    80004738:	85de                	mv	a1,s7
    8000473a:	953a                	add	a0,a0,a4
    8000473c:	ffffe097          	auipc	ra,0xffffe
    80004740:	38c080e7          	jalr	908(ra) # 80002ac8 <either_copyin>
    80004744:	07850263          	beq	a0,s8,800047a8 <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80004748:	8526                	mv	a0,s1
    8000474a:	00000097          	auipc	ra,0x0
    8000474e:	780080e7          	jalr	1920(ra) # 80004eca <log_write>
    brelse(bp);
    80004752:	8526                	mv	a0,s1
    80004754:	fffff097          	auipc	ra,0xfffff
    80004758:	4f2080e7          	jalr	1266(ra) # 80003c46 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    8000475c:	013d09bb          	addw	s3,s10,s3
    80004760:	012d093b          	addw	s2,s10,s2
    80004764:	9a6e                	add	s4,s4,s11
    80004766:	0569f663          	bgeu	s3,s6,800047b2 <writei+0xd6>
    uint addr = bmap(ip, off/BSIZE);
    8000476a:	00a9559b          	srliw	a1,s2,0xa
    8000476e:	8556                	mv	a0,s5
    80004770:	fffff097          	auipc	ra,0xfffff
    80004774:	7a0080e7          	jalr	1952(ra) # 80003f10 <bmap>
    80004778:	0005059b          	sext.w	a1,a0
    if(addr == 0)
    8000477c:	c99d                	beqz	a1,800047b2 <writei+0xd6>
    bp = bread(ip->dev, addr);
    8000477e:	000aa503          	lw	a0,0(s5)
    80004782:	fffff097          	auipc	ra,0xfffff
    80004786:	394080e7          	jalr	916(ra) # 80003b16 <bread>
    8000478a:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    8000478c:	3ff97713          	andi	a4,s2,1023
    80004790:	40ec87bb          	subw	a5,s9,a4
    80004794:	413b06bb          	subw	a3,s6,s3
    80004798:	8d3e                	mv	s10,a5
    8000479a:	2781                	sext.w	a5,a5
    8000479c:	0006861b          	sext.w	a2,a3
    800047a0:	f8f674e3          	bgeu	a2,a5,80004728 <writei+0x4c>
    800047a4:	8d36                	mv	s10,a3
    800047a6:	b749                	j	80004728 <writei+0x4c>
      brelse(bp);
    800047a8:	8526                	mv	a0,s1
    800047aa:	fffff097          	auipc	ra,0xfffff
    800047ae:	49c080e7          	jalr	1180(ra) # 80003c46 <brelse>
  }

  if(off > ip->size)
    800047b2:	04caa783          	lw	a5,76(s5)
    800047b6:	0127f463          	bgeu	a5,s2,800047be <writei+0xe2>
    ip->size = off;
    800047ba:	052aa623          	sw	s2,76(s5)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    800047be:	8556                	mv	a0,s5
    800047c0:	00000097          	auipc	ra,0x0
    800047c4:	aa6080e7          	jalr	-1370(ra) # 80004266 <iupdate>

  return tot;
    800047c8:	0009851b          	sext.w	a0,s3
}
    800047cc:	70a6                	ld	ra,104(sp)
    800047ce:	7406                	ld	s0,96(sp)
    800047d0:	64e6                	ld	s1,88(sp)
    800047d2:	6946                	ld	s2,80(sp)
    800047d4:	69a6                	ld	s3,72(sp)
    800047d6:	6a06                	ld	s4,64(sp)
    800047d8:	7ae2                	ld	s5,56(sp)
    800047da:	7b42                	ld	s6,48(sp)
    800047dc:	7ba2                	ld	s7,40(sp)
    800047de:	7c02                	ld	s8,32(sp)
    800047e0:	6ce2                	ld	s9,24(sp)
    800047e2:	6d42                	ld	s10,16(sp)
    800047e4:	6da2                	ld	s11,8(sp)
    800047e6:	6165                	addi	sp,sp,112
    800047e8:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    800047ea:	89da                	mv	s3,s6
    800047ec:	bfc9                	j	800047be <writei+0xe2>
    return -1;
    800047ee:	557d                	li	a0,-1
}
    800047f0:	8082                	ret
    return -1;
    800047f2:	557d                	li	a0,-1
    800047f4:	bfe1                	j	800047cc <writei+0xf0>
    return -1;
    800047f6:	557d                	li	a0,-1
    800047f8:	bfd1                	j	800047cc <writei+0xf0>

00000000800047fa <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    800047fa:	1141                	addi	sp,sp,-16
    800047fc:	e406                	sd	ra,8(sp)
    800047fe:	e022                	sd	s0,0(sp)
    80004800:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80004802:	4639                	li	a2,14
    80004804:	ffffd097          	auipc	ra,0xffffd
    80004808:	87c080e7          	jalr	-1924(ra) # 80001080 <strncmp>
}
    8000480c:	60a2                	ld	ra,8(sp)
    8000480e:	6402                	ld	s0,0(sp)
    80004810:	0141                	addi	sp,sp,16
    80004812:	8082                	ret

0000000080004814 <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80004814:	7139                	addi	sp,sp,-64
    80004816:	fc06                	sd	ra,56(sp)
    80004818:	f822                	sd	s0,48(sp)
    8000481a:	f426                	sd	s1,40(sp)
    8000481c:	f04a                	sd	s2,32(sp)
    8000481e:	ec4e                	sd	s3,24(sp)
    80004820:	e852                	sd	s4,16(sp)
    80004822:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80004824:	04451703          	lh	a4,68(a0)
    80004828:	4785                	li	a5,1
    8000482a:	00f71a63          	bne	a4,a5,8000483e <dirlookup+0x2a>
    8000482e:	892a                	mv	s2,a0
    80004830:	89ae                	mv	s3,a1
    80004832:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80004834:	457c                	lw	a5,76(a0)
    80004836:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80004838:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000483a:	e79d                	bnez	a5,80004868 <dirlookup+0x54>
    8000483c:	a8a5                	j	800048b4 <dirlookup+0xa0>
    panic("dirlookup not DIR");
    8000483e:	00004517          	auipc	a0,0x4
    80004842:	fb250513          	addi	a0,a0,-78 # 800087f0 <syscalls+0x1c8>
    80004846:	ffffc097          	auipc	ra,0xffffc
    8000484a:	cfe080e7          	jalr	-770(ra) # 80000544 <panic>
      panic("dirlookup read");
    8000484e:	00004517          	auipc	a0,0x4
    80004852:	fba50513          	addi	a0,a0,-70 # 80008808 <syscalls+0x1e0>
    80004856:	ffffc097          	auipc	ra,0xffffc
    8000485a:	cee080e7          	jalr	-786(ra) # 80000544 <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    8000485e:	24c1                	addiw	s1,s1,16
    80004860:	04c92783          	lw	a5,76(s2)
    80004864:	04f4f763          	bgeu	s1,a5,800048b2 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004868:	4741                	li	a4,16
    8000486a:	86a6                	mv	a3,s1
    8000486c:	fc040613          	addi	a2,s0,-64
    80004870:	4581                	li	a1,0
    80004872:	854a                	mv	a0,s2
    80004874:	00000097          	auipc	ra,0x0
    80004878:	d70080e7          	jalr	-656(ra) # 800045e4 <readi>
    8000487c:	47c1                	li	a5,16
    8000487e:	fcf518e3          	bne	a0,a5,8000484e <dirlookup+0x3a>
    if(de.inum == 0)
    80004882:	fc045783          	lhu	a5,-64(s0)
    80004886:	dfe1                	beqz	a5,8000485e <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80004888:	fc240593          	addi	a1,s0,-62
    8000488c:	854e                	mv	a0,s3
    8000488e:	00000097          	auipc	ra,0x0
    80004892:	f6c080e7          	jalr	-148(ra) # 800047fa <namecmp>
    80004896:	f561                	bnez	a0,8000485e <dirlookup+0x4a>
      if(poff)
    80004898:	000a0463          	beqz	s4,800048a0 <dirlookup+0x8c>
        *poff = off;
    8000489c:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    800048a0:	fc045583          	lhu	a1,-64(s0)
    800048a4:	00092503          	lw	a0,0(s2)
    800048a8:	fffff097          	auipc	ra,0xfffff
    800048ac:	750080e7          	jalr	1872(ra) # 80003ff8 <iget>
    800048b0:	a011                	j	800048b4 <dirlookup+0xa0>
  return 0;
    800048b2:	4501                	li	a0,0
}
    800048b4:	70e2                	ld	ra,56(sp)
    800048b6:	7442                	ld	s0,48(sp)
    800048b8:	74a2                	ld	s1,40(sp)
    800048ba:	7902                	ld	s2,32(sp)
    800048bc:	69e2                	ld	s3,24(sp)
    800048be:	6a42                	ld	s4,16(sp)
    800048c0:	6121                	addi	sp,sp,64
    800048c2:	8082                	ret

00000000800048c4 <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    800048c4:	711d                	addi	sp,sp,-96
    800048c6:	ec86                	sd	ra,88(sp)
    800048c8:	e8a2                	sd	s0,80(sp)
    800048ca:	e4a6                	sd	s1,72(sp)
    800048cc:	e0ca                	sd	s2,64(sp)
    800048ce:	fc4e                	sd	s3,56(sp)
    800048d0:	f852                	sd	s4,48(sp)
    800048d2:	f456                	sd	s5,40(sp)
    800048d4:	f05a                	sd	s6,32(sp)
    800048d6:	ec5e                	sd	s7,24(sp)
    800048d8:	e862                	sd	s8,16(sp)
    800048da:	e466                	sd	s9,8(sp)
    800048dc:	1080                	addi	s0,sp,96
    800048de:	84aa                	mv	s1,a0
    800048e0:	8b2e                	mv	s6,a1
    800048e2:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    800048e4:	00054703          	lbu	a4,0(a0)
    800048e8:	02f00793          	li	a5,47
    800048ec:	02f70363          	beq	a4,a5,80004912 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    800048f0:	ffffd097          	auipc	ra,0xffffd
    800048f4:	40a080e7          	jalr	1034(ra) # 80001cfa <myproc>
    800048f8:	15853503          	ld	a0,344(a0)
    800048fc:	00000097          	auipc	ra,0x0
    80004900:	9f6080e7          	jalr	-1546(ra) # 800042f2 <idup>
    80004904:	89aa                	mv	s3,a0
  while(*path == '/')
    80004906:	02f00913          	li	s2,47
  len = path - s;
    8000490a:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    8000490c:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    8000490e:	4c05                	li	s8,1
    80004910:	a865                	j	800049c8 <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80004912:	4585                	li	a1,1
    80004914:	4505                	li	a0,1
    80004916:	fffff097          	auipc	ra,0xfffff
    8000491a:	6e2080e7          	jalr	1762(ra) # 80003ff8 <iget>
    8000491e:	89aa                	mv	s3,a0
    80004920:	b7dd                	j	80004906 <namex+0x42>
      iunlockput(ip);
    80004922:	854e                	mv	a0,s3
    80004924:	00000097          	auipc	ra,0x0
    80004928:	c6e080e7          	jalr	-914(ra) # 80004592 <iunlockput>
      return 0;
    8000492c:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    8000492e:	854e                	mv	a0,s3
    80004930:	60e6                	ld	ra,88(sp)
    80004932:	6446                	ld	s0,80(sp)
    80004934:	64a6                	ld	s1,72(sp)
    80004936:	6906                	ld	s2,64(sp)
    80004938:	79e2                	ld	s3,56(sp)
    8000493a:	7a42                	ld	s4,48(sp)
    8000493c:	7aa2                	ld	s5,40(sp)
    8000493e:	7b02                	ld	s6,32(sp)
    80004940:	6be2                	ld	s7,24(sp)
    80004942:	6c42                	ld	s8,16(sp)
    80004944:	6ca2                	ld	s9,8(sp)
    80004946:	6125                	addi	sp,sp,96
    80004948:	8082                	ret
      iunlock(ip);
    8000494a:	854e                	mv	a0,s3
    8000494c:	00000097          	auipc	ra,0x0
    80004950:	aa6080e7          	jalr	-1370(ra) # 800043f2 <iunlock>
      return ip;
    80004954:	bfe9                	j	8000492e <namex+0x6a>
      iunlockput(ip);
    80004956:	854e                	mv	a0,s3
    80004958:	00000097          	auipc	ra,0x0
    8000495c:	c3a080e7          	jalr	-966(ra) # 80004592 <iunlockput>
      return 0;
    80004960:	89d2                	mv	s3,s4
    80004962:	b7f1                	j	8000492e <namex+0x6a>
  len = path - s;
    80004964:	40b48633          	sub	a2,s1,a1
    80004968:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    8000496c:	094cd463          	bge	s9,s4,800049f4 <namex+0x130>
    memmove(name, s, DIRSIZ);
    80004970:	4639                	li	a2,14
    80004972:	8556                	mv	a0,s5
    80004974:	ffffc097          	auipc	ra,0xffffc
    80004978:	694080e7          	jalr	1684(ra) # 80001008 <memmove>
  while(*path == '/')
    8000497c:	0004c783          	lbu	a5,0(s1)
    80004980:	01279763          	bne	a5,s2,8000498e <namex+0xca>
    path++;
    80004984:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004986:	0004c783          	lbu	a5,0(s1)
    8000498a:	ff278de3          	beq	a5,s2,80004984 <namex+0xc0>
    ilock(ip);
    8000498e:	854e                	mv	a0,s3
    80004990:	00000097          	auipc	ra,0x0
    80004994:	9a0080e7          	jalr	-1632(ra) # 80004330 <ilock>
    if(ip->type != T_DIR){
    80004998:	04499783          	lh	a5,68(s3)
    8000499c:	f98793e3          	bne	a5,s8,80004922 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    800049a0:	000b0563          	beqz	s6,800049aa <namex+0xe6>
    800049a4:	0004c783          	lbu	a5,0(s1)
    800049a8:	d3cd                	beqz	a5,8000494a <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    800049aa:	865e                	mv	a2,s7
    800049ac:	85d6                	mv	a1,s5
    800049ae:	854e                	mv	a0,s3
    800049b0:	00000097          	auipc	ra,0x0
    800049b4:	e64080e7          	jalr	-412(ra) # 80004814 <dirlookup>
    800049b8:	8a2a                	mv	s4,a0
    800049ba:	dd51                	beqz	a0,80004956 <namex+0x92>
    iunlockput(ip);
    800049bc:	854e                	mv	a0,s3
    800049be:	00000097          	auipc	ra,0x0
    800049c2:	bd4080e7          	jalr	-1068(ra) # 80004592 <iunlockput>
    ip = next;
    800049c6:	89d2                	mv	s3,s4
  while(*path == '/')
    800049c8:	0004c783          	lbu	a5,0(s1)
    800049cc:	05279763          	bne	a5,s2,80004a1a <namex+0x156>
    path++;
    800049d0:	0485                	addi	s1,s1,1
  while(*path == '/')
    800049d2:	0004c783          	lbu	a5,0(s1)
    800049d6:	ff278de3          	beq	a5,s2,800049d0 <namex+0x10c>
  if(*path == 0)
    800049da:	c79d                	beqz	a5,80004a08 <namex+0x144>
    path++;
    800049dc:	85a6                	mv	a1,s1
  len = path - s;
    800049de:	8a5e                	mv	s4,s7
    800049e0:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    800049e2:	01278963          	beq	a5,s2,800049f4 <namex+0x130>
    800049e6:	dfbd                	beqz	a5,80004964 <namex+0xa0>
    path++;
    800049e8:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    800049ea:	0004c783          	lbu	a5,0(s1)
    800049ee:	ff279ce3          	bne	a5,s2,800049e6 <namex+0x122>
    800049f2:	bf8d                	j	80004964 <namex+0xa0>
    memmove(name, s, len);
    800049f4:	2601                	sext.w	a2,a2
    800049f6:	8556                	mv	a0,s5
    800049f8:	ffffc097          	auipc	ra,0xffffc
    800049fc:	610080e7          	jalr	1552(ra) # 80001008 <memmove>
    name[len] = 0;
    80004a00:	9a56                	add	s4,s4,s5
    80004a02:	000a0023          	sb	zero,0(s4)
    80004a06:	bf9d                	j	8000497c <namex+0xb8>
  if(nameiparent){
    80004a08:	f20b03e3          	beqz	s6,8000492e <namex+0x6a>
    iput(ip);
    80004a0c:	854e                	mv	a0,s3
    80004a0e:	00000097          	auipc	ra,0x0
    80004a12:	adc080e7          	jalr	-1316(ra) # 800044ea <iput>
    return 0;
    80004a16:	4981                	li	s3,0
    80004a18:	bf19                	j	8000492e <namex+0x6a>
  if(*path == 0)
    80004a1a:	d7fd                	beqz	a5,80004a08 <namex+0x144>
  while(*path != '/' && *path != 0)
    80004a1c:	0004c783          	lbu	a5,0(s1)
    80004a20:	85a6                	mv	a1,s1
    80004a22:	b7d1                	j	800049e6 <namex+0x122>

0000000080004a24 <dirlink>:
{
    80004a24:	7139                	addi	sp,sp,-64
    80004a26:	fc06                	sd	ra,56(sp)
    80004a28:	f822                	sd	s0,48(sp)
    80004a2a:	f426                	sd	s1,40(sp)
    80004a2c:	f04a                	sd	s2,32(sp)
    80004a2e:	ec4e                	sd	s3,24(sp)
    80004a30:	e852                	sd	s4,16(sp)
    80004a32:	0080                	addi	s0,sp,64
    80004a34:	892a                	mv	s2,a0
    80004a36:	8a2e                	mv	s4,a1
    80004a38:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    80004a3a:	4601                	li	a2,0
    80004a3c:	00000097          	auipc	ra,0x0
    80004a40:	dd8080e7          	jalr	-552(ra) # 80004814 <dirlookup>
    80004a44:	e93d                	bnez	a0,80004aba <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004a46:	04c92483          	lw	s1,76(s2)
    80004a4a:	c49d                	beqz	s1,80004a78 <dirlink+0x54>
    80004a4c:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004a4e:	4741                	li	a4,16
    80004a50:	86a6                	mv	a3,s1
    80004a52:	fc040613          	addi	a2,s0,-64
    80004a56:	4581                	li	a1,0
    80004a58:	854a                	mv	a0,s2
    80004a5a:	00000097          	auipc	ra,0x0
    80004a5e:	b8a080e7          	jalr	-1142(ra) # 800045e4 <readi>
    80004a62:	47c1                	li	a5,16
    80004a64:	06f51163          	bne	a0,a5,80004ac6 <dirlink+0xa2>
    if(de.inum == 0)
    80004a68:	fc045783          	lhu	a5,-64(s0)
    80004a6c:	c791                	beqz	a5,80004a78 <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80004a6e:	24c1                	addiw	s1,s1,16
    80004a70:	04c92783          	lw	a5,76(s2)
    80004a74:	fcf4ede3          	bltu	s1,a5,80004a4e <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    80004a78:	4639                	li	a2,14
    80004a7a:	85d2                	mv	a1,s4
    80004a7c:	fc240513          	addi	a0,s0,-62
    80004a80:	ffffc097          	auipc	ra,0xffffc
    80004a84:	63c080e7          	jalr	1596(ra) # 800010bc <strncpy>
  de.inum = inum;
    80004a88:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004a8c:	4741                	li	a4,16
    80004a8e:	86a6                	mv	a3,s1
    80004a90:	fc040613          	addi	a2,s0,-64
    80004a94:	4581                	li	a1,0
    80004a96:	854a                	mv	a0,s2
    80004a98:	00000097          	auipc	ra,0x0
    80004a9c:	c44080e7          	jalr	-956(ra) # 800046dc <writei>
    80004aa0:	1541                	addi	a0,a0,-16
    80004aa2:	00a03533          	snez	a0,a0
    80004aa6:	40a00533          	neg	a0,a0
}
    80004aaa:	70e2                	ld	ra,56(sp)
    80004aac:	7442                	ld	s0,48(sp)
    80004aae:	74a2                	ld	s1,40(sp)
    80004ab0:	7902                	ld	s2,32(sp)
    80004ab2:	69e2                	ld	s3,24(sp)
    80004ab4:	6a42                	ld	s4,16(sp)
    80004ab6:	6121                	addi	sp,sp,64
    80004ab8:	8082                	ret
    iput(ip);
    80004aba:	00000097          	auipc	ra,0x0
    80004abe:	a30080e7          	jalr	-1488(ra) # 800044ea <iput>
    return -1;
    80004ac2:	557d                	li	a0,-1
    80004ac4:	b7dd                	j	80004aaa <dirlink+0x86>
      panic("dirlink read");
    80004ac6:	00004517          	auipc	a0,0x4
    80004aca:	d5250513          	addi	a0,a0,-686 # 80008818 <syscalls+0x1f0>
    80004ace:	ffffc097          	auipc	ra,0xffffc
    80004ad2:	a76080e7          	jalr	-1418(ra) # 80000544 <panic>

0000000080004ad6 <namei>:

struct inode*
namei(char *path)
{
    80004ad6:	1101                	addi	sp,sp,-32
    80004ad8:	ec06                	sd	ra,24(sp)
    80004ada:	e822                	sd	s0,16(sp)
    80004adc:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004ade:	fe040613          	addi	a2,s0,-32
    80004ae2:	4581                	li	a1,0
    80004ae4:	00000097          	auipc	ra,0x0
    80004ae8:	de0080e7          	jalr	-544(ra) # 800048c4 <namex>
}
    80004aec:	60e2                	ld	ra,24(sp)
    80004aee:	6442                	ld	s0,16(sp)
    80004af0:	6105                	addi	sp,sp,32
    80004af2:	8082                	ret

0000000080004af4 <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    80004af4:	1141                	addi	sp,sp,-16
    80004af6:	e406                	sd	ra,8(sp)
    80004af8:	e022                	sd	s0,0(sp)
    80004afa:	0800                	addi	s0,sp,16
    80004afc:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004afe:	4585                	li	a1,1
    80004b00:	00000097          	auipc	ra,0x0
    80004b04:	dc4080e7          	jalr	-572(ra) # 800048c4 <namex>
}
    80004b08:	60a2                	ld	ra,8(sp)
    80004b0a:	6402                	ld	s0,0(sp)
    80004b0c:	0141                	addi	sp,sp,16
    80004b0e:	8082                	ret

0000000080004b10 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004b10:	1101                	addi	sp,sp,-32
    80004b12:	ec06                	sd	ra,24(sp)
    80004b14:	e822                	sd	s0,16(sp)
    80004b16:	e426                	sd	s1,8(sp)
    80004b18:	e04a                	sd	s2,0(sp)
    80004b1a:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    80004b1c:	0023e917          	auipc	s2,0x23e
    80004b20:	3b490913          	addi	s2,s2,948 # 80242ed0 <log>
    80004b24:	01892583          	lw	a1,24(s2)
    80004b28:	02892503          	lw	a0,40(s2)
    80004b2c:	fffff097          	auipc	ra,0xfffff
    80004b30:	fea080e7          	jalr	-22(ra) # 80003b16 <bread>
    80004b34:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    80004b36:	02c92683          	lw	a3,44(s2)
    80004b3a:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    80004b3c:	02d05763          	blez	a3,80004b6a <write_head+0x5a>
    80004b40:	0023e797          	auipc	a5,0x23e
    80004b44:	3c078793          	addi	a5,a5,960 # 80242f00 <log+0x30>
    80004b48:	05c50713          	addi	a4,a0,92
    80004b4c:	36fd                	addiw	a3,a3,-1
    80004b4e:	1682                	slli	a3,a3,0x20
    80004b50:	9281                	srli	a3,a3,0x20
    80004b52:	068a                	slli	a3,a3,0x2
    80004b54:	0023e617          	auipc	a2,0x23e
    80004b58:	3b060613          	addi	a2,a2,944 # 80242f04 <log+0x34>
    80004b5c:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    80004b5e:	4390                	lw	a2,0(a5)
    80004b60:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    80004b62:	0791                	addi	a5,a5,4
    80004b64:	0711                	addi	a4,a4,4
    80004b66:	fed79ce3          	bne	a5,a3,80004b5e <write_head+0x4e>
  }
  bwrite(buf);
    80004b6a:	8526                	mv	a0,s1
    80004b6c:	fffff097          	auipc	ra,0xfffff
    80004b70:	09c080e7          	jalr	156(ra) # 80003c08 <bwrite>
  brelse(buf);
    80004b74:	8526                	mv	a0,s1
    80004b76:	fffff097          	auipc	ra,0xfffff
    80004b7a:	0d0080e7          	jalr	208(ra) # 80003c46 <brelse>
}
    80004b7e:	60e2                	ld	ra,24(sp)
    80004b80:	6442                	ld	s0,16(sp)
    80004b82:	64a2                	ld	s1,8(sp)
    80004b84:	6902                	ld	s2,0(sp)
    80004b86:	6105                	addi	sp,sp,32
    80004b88:	8082                	ret

0000000080004b8a <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004b8a:	0023e797          	auipc	a5,0x23e
    80004b8e:	3727a783          	lw	a5,882(a5) # 80242efc <log+0x2c>
    80004b92:	0af05d63          	blez	a5,80004c4c <install_trans+0xc2>
{
    80004b96:	7139                	addi	sp,sp,-64
    80004b98:	fc06                	sd	ra,56(sp)
    80004b9a:	f822                	sd	s0,48(sp)
    80004b9c:	f426                	sd	s1,40(sp)
    80004b9e:	f04a                	sd	s2,32(sp)
    80004ba0:	ec4e                	sd	s3,24(sp)
    80004ba2:	e852                	sd	s4,16(sp)
    80004ba4:	e456                	sd	s5,8(sp)
    80004ba6:	e05a                	sd	s6,0(sp)
    80004ba8:	0080                	addi	s0,sp,64
    80004baa:	8b2a                	mv	s6,a0
    80004bac:	0023ea97          	auipc	s5,0x23e
    80004bb0:	354a8a93          	addi	s5,s5,852 # 80242f00 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004bb4:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004bb6:	0023e997          	auipc	s3,0x23e
    80004bba:	31a98993          	addi	s3,s3,794 # 80242ed0 <log>
    80004bbe:	a035                	j	80004bea <install_trans+0x60>
      bunpin(dbuf);
    80004bc0:	8526                	mv	a0,s1
    80004bc2:	fffff097          	auipc	ra,0xfffff
    80004bc6:	15e080e7          	jalr	350(ra) # 80003d20 <bunpin>
    brelse(lbuf);
    80004bca:	854a                	mv	a0,s2
    80004bcc:	fffff097          	auipc	ra,0xfffff
    80004bd0:	07a080e7          	jalr	122(ra) # 80003c46 <brelse>
    brelse(dbuf);
    80004bd4:	8526                	mv	a0,s1
    80004bd6:	fffff097          	auipc	ra,0xfffff
    80004bda:	070080e7          	jalr	112(ra) # 80003c46 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004bde:	2a05                	addiw	s4,s4,1
    80004be0:	0a91                	addi	s5,s5,4
    80004be2:	02c9a783          	lw	a5,44(s3)
    80004be6:	04fa5963          	bge	s4,a5,80004c38 <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004bea:	0189a583          	lw	a1,24(s3)
    80004bee:	014585bb          	addw	a1,a1,s4
    80004bf2:	2585                	addiw	a1,a1,1
    80004bf4:	0289a503          	lw	a0,40(s3)
    80004bf8:	fffff097          	auipc	ra,0xfffff
    80004bfc:	f1e080e7          	jalr	-226(ra) # 80003b16 <bread>
    80004c00:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004c02:	000aa583          	lw	a1,0(s5)
    80004c06:	0289a503          	lw	a0,40(s3)
    80004c0a:	fffff097          	auipc	ra,0xfffff
    80004c0e:	f0c080e7          	jalr	-244(ra) # 80003b16 <bread>
    80004c12:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    80004c14:	40000613          	li	a2,1024
    80004c18:	05890593          	addi	a1,s2,88
    80004c1c:	05850513          	addi	a0,a0,88
    80004c20:	ffffc097          	auipc	ra,0xffffc
    80004c24:	3e8080e7          	jalr	1000(ra) # 80001008 <memmove>
    bwrite(dbuf);  // write dst to disk
    80004c28:	8526                	mv	a0,s1
    80004c2a:	fffff097          	auipc	ra,0xfffff
    80004c2e:	fde080e7          	jalr	-34(ra) # 80003c08 <bwrite>
    if(recovering == 0)
    80004c32:	f80b1ce3          	bnez	s6,80004bca <install_trans+0x40>
    80004c36:	b769                	j	80004bc0 <install_trans+0x36>
}
    80004c38:	70e2                	ld	ra,56(sp)
    80004c3a:	7442                	ld	s0,48(sp)
    80004c3c:	74a2                	ld	s1,40(sp)
    80004c3e:	7902                	ld	s2,32(sp)
    80004c40:	69e2                	ld	s3,24(sp)
    80004c42:	6a42                	ld	s4,16(sp)
    80004c44:	6aa2                	ld	s5,8(sp)
    80004c46:	6b02                	ld	s6,0(sp)
    80004c48:	6121                	addi	sp,sp,64
    80004c4a:	8082                	ret
    80004c4c:	8082                	ret

0000000080004c4e <initlog>:
{
    80004c4e:	7179                	addi	sp,sp,-48
    80004c50:	f406                	sd	ra,40(sp)
    80004c52:	f022                	sd	s0,32(sp)
    80004c54:	ec26                	sd	s1,24(sp)
    80004c56:	e84a                	sd	s2,16(sp)
    80004c58:	e44e                	sd	s3,8(sp)
    80004c5a:	1800                	addi	s0,sp,48
    80004c5c:	892a                	mv	s2,a0
    80004c5e:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    80004c60:	0023e497          	auipc	s1,0x23e
    80004c64:	27048493          	addi	s1,s1,624 # 80242ed0 <log>
    80004c68:	00004597          	auipc	a1,0x4
    80004c6c:	bc058593          	addi	a1,a1,-1088 # 80008828 <syscalls+0x200>
    80004c70:	8526                	mv	a0,s1
    80004c72:	ffffc097          	auipc	ra,0xffffc
    80004c76:	1aa080e7          	jalr	426(ra) # 80000e1c <initlock>
  log.start = sb->logstart;
    80004c7a:	0149a583          	lw	a1,20(s3)
    80004c7e:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004c80:	0109a783          	lw	a5,16(s3)
    80004c84:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    80004c86:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004c8a:	854a                	mv	a0,s2
    80004c8c:	fffff097          	auipc	ra,0xfffff
    80004c90:	e8a080e7          	jalr	-374(ra) # 80003b16 <bread>
  log.lh.n = lh->n;
    80004c94:	4d3c                	lw	a5,88(a0)
    80004c96:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    80004c98:	02f05563          	blez	a5,80004cc2 <initlog+0x74>
    80004c9c:	05c50713          	addi	a4,a0,92
    80004ca0:	0023e697          	auipc	a3,0x23e
    80004ca4:	26068693          	addi	a3,a3,608 # 80242f00 <log+0x30>
    80004ca8:	37fd                	addiw	a5,a5,-1
    80004caa:	1782                	slli	a5,a5,0x20
    80004cac:	9381                	srli	a5,a5,0x20
    80004cae:	078a                	slli	a5,a5,0x2
    80004cb0:	06050613          	addi	a2,a0,96
    80004cb4:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    80004cb6:	4310                	lw	a2,0(a4)
    80004cb8:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004cba:	0711                	addi	a4,a4,4
    80004cbc:	0691                	addi	a3,a3,4
    80004cbe:	fef71ce3          	bne	a4,a5,80004cb6 <initlog+0x68>
  brelse(buf);
    80004cc2:	fffff097          	auipc	ra,0xfffff
    80004cc6:	f84080e7          	jalr	-124(ra) # 80003c46 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004cca:	4505                	li	a0,1
    80004ccc:	00000097          	auipc	ra,0x0
    80004cd0:	ebe080e7          	jalr	-322(ra) # 80004b8a <install_trans>
  log.lh.n = 0;
    80004cd4:	0023e797          	auipc	a5,0x23e
    80004cd8:	2207a423          	sw	zero,552(a5) # 80242efc <log+0x2c>
  write_head(); // clear the log
    80004cdc:	00000097          	auipc	ra,0x0
    80004ce0:	e34080e7          	jalr	-460(ra) # 80004b10 <write_head>
}
    80004ce4:	70a2                	ld	ra,40(sp)
    80004ce6:	7402                	ld	s0,32(sp)
    80004ce8:	64e2                	ld	s1,24(sp)
    80004cea:	6942                	ld	s2,16(sp)
    80004cec:	69a2                	ld	s3,8(sp)
    80004cee:	6145                	addi	sp,sp,48
    80004cf0:	8082                	ret

0000000080004cf2 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004cf2:	1101                	addi	sp,sp,-32
    80004cf4:	ec06                	sd	ra,24(sp)
    80004cf6:	e822                	sd	s0,16(sp)
    80004cf8:	e426                	sd	s1,8(sp)
    80004cfa:	e04a                	sd	s2,0(sp)
    80004cfc:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004cfe:	0023e517          	auipc	a0,0x23e
    80004d02:	1d250513          	addi	a0,a0,466 # 80242ed0 <log>
    80004d06:	ffffc097          	auipc	ra,0xffffc
    80004d0a:	1a6080e7          	jalr	422(ra) # 80000eac <acquire>
  while(1){
    if(log.committing){
    80004d0e:	0023e497          	auipc	s1,0x23e
    80004d12:	1c248493          	addi	s1,s1,450 # 80242ed0 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004d16:	4979                	li	s2,30
    80004d18:	a039                	j	80004d26 <begin_op+0x34>
      sleep(&log, &log.lock);
    80004d1a:	85a6                	mv	a1,s1
    80004d1c:	8526                	mv	a0,s1
    80004d1e:	ffffe097          	auipc	ra,0xffffe
    80004d22:	940080e7          	jalr	-1728(ra) # 8000265e <sleep>
    if(log.committing){
    80004d26:	50dc                	lw	a5,36(s1)
    80004d28:	fbed                	bnez	a5,80004d1a <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    80004d2a:	509c                	lw	a5,32(s1)
    80004d2c:	0017871b          	addiw	a4,a5,1
    80004d30:	0007069b          	sext.w	a3,a4
    80004d34:	0027179b          	slliw	a5,a4,0x2
    80004d38:	9fb9                	addw	a5,a5,a4
    80004d3a:	0017979b          	slliw	a5,a5,0x1
    80004d3e:	54d8                	lw	a4,44(s1)
    80004d40:	9fb9                	addw	a5,a5,a4
    80004d42:	00f95963          	bge	s2,a5,80004d54 <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    80004d46:	85a6                	mv	a1,s1
    80004d48:	8526                	mv	a0,s1
    80004d4a:	ffffe097          	auipc	ra,0xffffe
    80004d4e:	914080e7          	jalr	-1772(ra) # 8000265e <sleep>
    80004d52:	bfd1                	j	80004d26 <begin_op+0x34>
    } else {
      log.outstanding += 1;
    80004d54:	0023e517          	auipc	a0,0x23e
    80004d58:	17c50513          	addi	a0,a0,380 # 80242ed0 <log>
    80004d5c:	d114                	sw	a3,32(a0)
      release(&log.lock);
    80004d5e:	ffffc097          	auipc	ra,0xffffc
    80004d62:	202080e7          	jalr	514(ra) # 80000f60 <release>
      break;
    }
  }
}
    80004d66:	60e2                	ld	ra,24(sp)
    80004d68:	6442                	ld	s0,16(sp)
    80004d6a:	64a2                	ld	s1,8(sp)
    80004d6c:	6902                	ld	s2,0(sp)
    80004d6e:	6105                	addi	sp,sp,32
    80004d70:	8082                	ret

0000000080004d72 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    80004d72:	7139                	addi	sp,sp,-64
    80004d74:	fc06                	sd	ra,56(sp)
    80004d76:	f822                	sd	s0,48(sp)
    80004d78:	f426                	sd	s1,40(sp)
    80004d7a:	f04a                	sd	s2,32(sp)
    80004d7c:	ec4e                	sd	s3,24(sp)
    80004d7e:	e852                	sd	s4,16(sp)
    80004d80:	e456                	sd	s5,8(sp)
    80004d82:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    80004d84:	0023e497          	auipc	s1,0x23e
    80004d88:	14c48493          	addi	s1,s1,332 # 80242ed0 <log>
    80004d8c:	8526                	mv	a0,s1
    80004d8e:	ffffc097          	auipc	ra,0xffffc
    80004d92:	11e080e7          	jalr	286(ra) # 80000eac <acquire>
  log.outstanding -= 1;
    80004d96:	509c                	lw	a5,32(s1)
    80004d98:	37fd                	addiw	a5,a5,-1
    80004d9a:	0007891b          	sext.w	s2,a5
    80004d9e:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004da0:	50dc                	lw	a5,36(s1)
    80004da2:	efb9                	bnez	a5,80004e00 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    80004da4:	06091663          	bnez	s2,80004e10 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    80004da8:	0023e497          	auipc	s1,0x23e
    80004dac:	12848493          	addi	s1,s1,296 # 80242ed0 <log>
    80004db0:	4785                	li	a5,1
    80004db2:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    80004db4:	8526                	mv	a0,s1
    80004db6:	ffffc097          	auipc	ra,0xffffc
    80004dba:	1aa080e7          	jalr	426(ra) # 80000f60 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004dbe:	54dc                	lw	a5,44(s1)
    80004dc0:	06f04763          	bgtz	a5,80004e2e <end_op+0xbc>
    acquire(&log.lock);
    80004dc4:	0023e497          	auipc	s1,0x23e
    80004dc8:	10c48493          	addi	s1,s1,268 # 80242ed0 <log>
    80004dcc:	8526                	mv	a0,s1
    80004dce:	ffffc097          	auipc	ra,0xffffc
    80004dd2:	0de080e7          	jalr	222(ra) # 80000eac <acquire>
    log.committing = 0;
    80004dd6:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004dda:	8526                	mv	a0,s1
    80004ddc:	ffffe097          	auipc	ra,0xffffe
    80004de0:	8e6080e7          	jalr	-1818(ra) # 800026c2 <wakeup>
    release(&log.lock);
    80004de4:	8526                	mv	a0,s1
    80004de6:	ffffc097          	auipc	ra,0xffffc
    80004dea:	17a080e7          	jalr	378(ra) # 80000f60 <release>
}
    80004dee:	70e2                	ld	ra,56(sp)
    80004df0:	7442                	ld	s0,48(sp)
    80004df2:	74a2                	ld	s1,40(sp)
    80004df4:	7902                	ld	s2,32(sp)
    80004df6:	69e2                	ld	s3,24(sp)
    80004df8:	6a42                	ld	s4,16(sp)
    80004dfa:	6aa2                	ld	s5,8(sp)
    80004dfc:	6121                	addi	sp,sp,64
    80004dfe:	8082                	ret
    panic("log.committing");
    80004e00:	00004517          	auipc	a0,0x4
    80004e04:	a3050513          	addi	a0,a0,-1488 # 80008830 <syscalls+0x208>
    80004e08:	ffffb097          	auipc	ra,0xffffb
    80004e0c:	73c080e7          	jalr	1852(ra) # 80000544 <panic>
    wakeup(&log);
    80004e10:	0023e497          	auipc	s1,0x23e
    80004e14:	0c048493          	addi	s1,s1,192 # 80242ed0 <log>
    80004e18:	8526                	mv	a0,s1
    80004e1a:	ffffe097          	auipc	ra,0xffffe
    80004e1e:	8a8080e7          	jalr	-1880(ra) # 800026c2 <wakeup>
  release(&log.lock);
    80004e22:	8526                	mv	a0,s1
    80004e24:	ffffc097          	auipc	ra,0xffffc
    80004e28:	13c080e7          	jalr	316(ra) # 80000f60 <release>
  if(do_commit){
    80004e2c:	b7c9                	j	80004dee <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004e2e:	0023ea97          	auipc	s5,0x23e
    80004e32:	0d2a8a93          	addi	s5,s5,210 # 80242f00 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    80004e36:	0023ea17          	auipc	s4,0x23e
    80004e3a:	09aa0a13          	addi	s4,s4,154 # 80242ed0 <log>
    80004e3e:	018a2583          	lw	a1,24(s4)
    80004e42:	012585bb          	addw	a1,a1,s2
    80004e46:	2585                	addiw	a1,a1,1
    80004e48:	028a2503          	lw	a0,40(s4)
    80004e4c:	fffff097          	auipc	ra,0xfffff
    80004e50:	cca080e7          	jalr	-822(ra) # 80003b16 <bread>
    80004e54:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    80004e56:	000aa583          	lw	a1,0(s5)
    80004e5a:	028a2503          	lw	a0,40(s4)
    80004e5e:	fffff097          	auipc	ra,0xfffff
    80004e62:	cb8080e7          	jalr	-840(ra) # 80003b16 <bread>
    80004e66:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    80004e68:	40000613          	li	a2,1024
    80004e6c:	05850593          	addi	a1,a0,88
    80004e70:	05848513          	addi	a0,s1,88
    80004e74:	ffffc097          	auipc	ra,0xffffc
    80004e78:	194080e7          	jalr	404(ra) # 80001008 <memmove>
    bwrite(to);  // write the log
    80004e7c:	8526                	mv	a0,s1
    80004e7e:	fffff097          	auipc	ra,0xfffff
    80004e82:	d8a080e7          	jalr	-630(ra) # 80003c08 <bwrite>
    brelse(from);
    80004e86:	854e                	mv	a0,s3
    80004e88:	fffff097          	auipc	ra,0xfffff
    80004e8c:	dbe080e7          	jalr	-578(ra) # 80003c46 <brelse>
    brelse(to);
    80004e90:	8526                	mv	a0,s1
    80004e92:	fffff097          	auipc	ra,0xfffff
    80004e96:	db4080e7          	jalr	-588(ra) # 80003c46 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004e9a:	2905                	addiw	s2,s2,1
    80004e9c:	0a91                	addi	s5,s5,4
    80004e9e:	02ca2783          	lw	a5,44(s4)
    80004ea2:	f8f94ee3          	blt	s2,a5,80004e3e <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    80004ea6:	00000097          	auipc	ra,0x0
    80004eaa:	c6a080e7          	jalr	-918(ra) # 80004b10 <write_head>
    install_trans(0); // Now install writes to home locations
    80004eae:	4501                	li	a0,0
    80004eb0:	00000097          	auipc	ra,0x0
    80004eb4:	cda080e7          	jalr	-806(ra) # 80004b8a <install_trans>
    log.lh.n = 0;
    80004eb8:	0023e797          	auipc	a5,0x23e
    80004ebc:	0407a223          	sw	zero,68(a5) # 80242efc <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004ec0:	00000097          	auipc	ra,0x0
    80004ec4:	c50080e7          	jalr	-944(ra) # 80004b10 <write_head>
    80004ec8:	bdf5                	j	80004dc4 <end_op+0x52>

0000000080004eca <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004eca:	1101                	addi	sp,sp,-32
    80004ecc:	ec06                	sd	ra,24(sp)
    80004ece:	e822                	sd	s0,16(sp)
    80004ed0:	e426                	sd	s1,8(sp)
    80004ed2:	e04a                	sd	s2,0(sp)
    80004ed4:	1000                	addi	s0,sp,32
    80004ed6:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    80004ed8:	0023e917          	auipc	s2,0x23e
    80004edc:	ff890913          	addi	s2,s2,-8 # 80242ed0 <log>
    80004ee0:	854a                	mv	a0,s2
    80004ee2:	ffffc097          	auipc	ra,0xffffc
    80004ee6:	fca080e7          	jalr	-54(ra) # 80000eac <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004eea:	02c92603          	lw	a2,44(s2)
    80004eee:	47f5                	li	a5,29
    80004ef0:	06c7c563          	blt	a5,a2,80004f5a <log_write+0x90>
    80004ef4:	0023e797          	auipc	a5,0x23e
    80004ef8:	ff87a783          	lw	a5,-8(a5) # 80242eec <log+0x1c>
    80004efc:	37fd                	addiw	a5,a5,-1
    80004efe:	04f65e63          	bge	a2,a5,80004f5a <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004f02:	0023e797          	auipc	a5,0x23e
    80004f06:	fee7a783          	lw	a5,-18(a5) # 80242ef0 <log+0x20>
    80004f0a:	06f05063          	blez	a5,80004f6a <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004f0e:	4781                	li	a5,0
    80004f10:	06c05563          	blez	a2,80004f7a <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004f14:	44cc                	lw	a1,12(s1)
    80004f16:	0023e717          	auipc	a4,0x23e
    80004f1a:	fea70713          	addi	a4,a4,-22 # 80242f00 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    80004f1e:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    80004f20:	4314                	lw	a3,0(a4)
    80004f22:	04b68c63          	beq	a3,a1,80004f7a <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    80004f26:	2785                	addiw	a5,a5,1
    80004f28:	0711                	addi	a4,a4,4
    80004f2a:	fef61be3          	bne	a2,a5,80004f20 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    80004f2e:	0621                	addi	a2,a2,8
    80004f30:	060a                	slli	a2,a2,0x2
    80004f32:	0023e797          	auipc	a5,0x23e
    80004f36:	f9e78793          	addi	a5,a5,-98 # 80242ed0 <log>
    80004f3a:	963e                	add	a2,a2,a5
    80004f3c:	44dc                	lw	a5,12(s1)
    80004f3e:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    80004f40:	8526                	mv	a0,s1
    80004f42:	fffff097          	auipc	ra,0xfffff
    80004f46:	da2080e7          	jalr	-606(ra) # 80003ce4 <bpin>
    log.lh.n++;
    80004f4a:	0023e717          	auipc	a4,0x23e
    80004f4e:	f8670713          	addi	a4,a4,-122 # 80242ed0 <log>
    80004f52:	575c                	lw	a5,44(a4)
    80004f54:	2785                	addiw	a5,a5,1
    80004f56:	d75c                	sw	a5,44(a4)
    80004f58:	a835                	j	80004f94 <log_write+0xca>
    panic("too big a transaction");
    80004f5a:	00004517          	auipc	a0,0x4
    80004f5e:	8e650513          	addi	a0,a0,-1818 # 80008840 <syscalls+0x218>
    80004f62:	ffffb097          	auipc	ra,0xffffb
    80004f66:	5e2080e7          	jalr	1506(ra) # 80000544 <panic>
    panic("log_write outside of trans");
    80004f6a:	00004517          	auipc	a0,0x4
    80004f6e:	8ee50513          	addi	a0,a0,-1810 # 80008858 <syscalls+0x230>
    80004f72:	ffffb097          	auipc	ra,0xffffb
    80004f76:	5d2080e7          	jalr	1490(ra) # 80000544 <panic>
  log.lh.block[i] = b->blockno;
    80004f7a:	00878713          	addi	a4,a5,8
    80004f7e:	00271693          	slli	a3,a4,0x2
    80004f82:	0023e717          	auipc	a4,0x23e
    80004f86:	f4e70713          	addi	a4,a4,-178 # 80242ed0 <log>
    80004f8a:	9736                	add	a4,a4,a3
    80004f8c:	44d4                	lw	a3,12(s1)
    80004f8e:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004f90:	faf608e3          	beq	a2,a5,80004f40 <log_write+0x76>
  }
  release(&log.lock);
    80004f94:	0023e517          	auipc	a0,0x23e
    80004f98:	f3c50513          	addi	a0,a0,-196 # 80242ed0 <log>
    80004f9c:	ffffc097          	auipc	ra,0xffffc
    80004fa0:	fc4080e7          	jalr	-60(ra) # 80000f60 <release>
}
    80004fa4:	60e2                	ld	ra,24(sp)
    80004fa6:	6442                	ld	s0,16(sp)
    80004fa8:	64a2                	ld	s1,8(sp)
    80004faa:	6902                	ld	s2,0(sp)
    80004fac:	6105                	addi	sp,sp,32
    80004fae:	8082                	ret

0000000080004fb0 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004fb0:	1101                	addi	sp,sp,-32
    80004fb2:	ec06                	sd	ra,24(sp)
    80004fb4:	e822                	sd	s0,16(sp)
    80004fb6:	e426                	sd	s1,8(sp)
    80004fb8:	e04a                	sd	s2,0(sp)
    80004fba:	1000                	addi	s0,sp,32
    80004fbc:	84aa                	mv	s1,a0
    80004fbe:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004fc0:	00004597          	auipc	a1,0x4
    80004fc4:	8b858593          	addi	a1,a1,-1864 # 80008878 <syscalls+0x250>
    80004fc8:	0521                	addi	a0,a0,8
    80004fca:	ffffc097          	auipc	ra,0xffffc
    80004fce:	e52080e7          	jalr	-430(ra) # 80000e1c <initlock>
  lk->name = name;
    80004fd2:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    80004fd6:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004fda:	0204a423          	sw	zero,40(s1)
}
    80004fde:	60e2                	ld	ra,24(sp)
    80004fe0:	6442                	ld	s0,16(sp)
    80004fe2:	64a2                	ld	s1,8(sp)
    80004fe4:	6902                	ld	s2,0(sp)
    80004fe6:	6105                	addi	sp,sp,32
    80004fe8:	8082                	ret

0000000080004fea <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004fea:	1101                	addi	sp,sp,-32
    80004fec:	ec06                	sd	ra,24(sp)
    80004fee:	e822                	sd	s0,16(sp)
    80004ff0:	e426                	sd	s1,8(sp)
    80004ff2:	e04a                	sd	s2,0(sp)
    80004ff4:	1000                	addi	s0,sp,32
    80004ff6:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    80004ff8:	00850913          	addi	s2,a0,8
    80004ffc:	854a                	mv	a0,s2
    80004ffe:	ffffc097          	auipc	ra,0xffffc
    80005002:	eae080e7          	jalr	-338(ra) # 80000eac <acquire>
  while (lk->locked) {
    80005006:	409c                	lw	a5,0(s1)
    80005008:	cb89                	beqz	a5,8000501a <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    8000500a:	85ca                	mv	a1,s2
    8000500c:	8526                	mv	a0,s1
    8000500e:	ffffd097          	auipc	ra,0xffffd
    80005012:	650080e7          	jalr	1616(ra) # 8000265e <sleep>
  while (lk->locked) {
    80005016:	409c                	lw	a5,0(s1)
    80005018:	fbed                	bnez	a5,8000500a <acquiresleep+0x20>
  }
  lk->locked = 1;
    8000501a:	4785                	li	a5,1
    8000501c:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    8000501e:	ffffd097          	auipc	ra,0xffffd
    80005022:	cdc080e7          	jalr	-804(ra) # 80001cfa <myproc>
    80005026:	591c                	lw	a5,48(a0)
    80005028:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    8000502a:	854a                	mv	a0,s2
    8000502c:	ffffc097          	auipc	ra,0xffffc
    80005030:	f34080e7          	jalr	-204(ra) # 80000f60 <release>
}
    80005034:	60e2                	ld	ra,24(sp)
    80005036:	6442                	ld	s0,16(sp)
    80005038:	64a2                	ld	s1,8(sp)
    8000503a:	6902                	ld	s2,0(sp)
    8000503c:	6105                	addi	sp,sp,32
    8000503e:	8082                	ret

0000000080005040 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    80005040:	1101                	addi	sp,sp,-32
    80005042:	ec06                	sd	ra,24(sp)
    80005044:	e822                	sd	s0,16(sp)
    80005046:	e426                	sd	s1,8(sp)
    80005048:	e04a                	sd	s2,0(sp)
    8000504a:	1000                	addi	s0,sp,32
    8000504c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000504e:	00850913          	addi	s2,a0,8
    80005052:	854a                	mv	a0,s2
    80005054:	ffffc097          	auipc	ra,0xffffc
    80005058:	e58080e7          	jalr	-424(ra) # 80000eac <acquire>
  lk->locked = 0;
    8000505c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80005060:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    80005064:	8526                	mv	a0,s1
    80005066:	ffffd097          	auipc	ra,0xffffd
    8000506a:	65c080e7          	jalr	1628(ra) # 800026c2 <wakeup>
  release(&lk->lk);
    8000506e:	854a                	mv	a0,s2
    80005070:	ffffc097          	auipc	ra,0xffffc
    80005074:	ef0080e7          	jalr	-272(ra) # 80000f60 <release>
}
    80005078:	60e2                	ld	ra,24(sp)
    8000507a:	6442                	ld	s0,16(sp)
    8000507c:	64a2                	ld	s1,8(sp)
    8000507e:	6902                	ld	s2,0(sp)
    80005080:	6105                	addi	sp,sp,32
    80005082:	8082                	ret

0000000080005084 <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    80005084:	7179                	addi	sp,sp,-48
    80005086:	f406                	sd	ra,40(sp)
    80005088:	f022                	sd	s0,32(sp)
    8000508a:	ec26                	sd	s1,24(sp)
    8000508c:	e84a                	sd	s2,16(sp)
    8000508e:	e44e                	sd	s3,8(sp)
    80005090:	1800                	addi	s0,sp,48
    80005092:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    80005094:	00850913          	addi	s2,a0,8
    80005098:	854a                	mv	a0,s2
    8000509a:	ffffc097          	auipc	ra,0xffffc
    8000509e:	e12080e7          	jalr	-494(ra) # 80000eac <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    800050a2:	409c                	lw	a5,0(s1)
    800050a4:	ef99                	bnez	a5,800050c2 <holdingsleep+0x3e>
    800050a6:	4481                	li	s1,0
  release(&lk->lk);
    800050a8:	854a                	mv	a0,s2
    800050aa:	ffffc097          	auipc	ra,0xffffc
    800050ae:	eb6080e7          	jalr	-330(ra) # 80000f60 <release>
  return r;
}
    800050b2:	8526                	mv	a0,s1
    800050b4:	70a2                	ld	ra,40(sp)
    800050b6:	7402                	ld	s0,32(sp)
    800050b8:	64e2                	ld	s1,24(sp)
    800050ba:	6942                	ld	s2,16(sp)
    800050bc:	69a2                	ld	s3,8(sp)
    800050be:	6145                	addi	sp,sp,48
    800050c0:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    800050c2:	0284a983          	lw	s3,40(s1)
    800050c6:	ffffd097          	auipc	ra,0xffffd
    800050ca:	c34080e7          	jalr	-972(ra) # 80001cfa <myproc>
    800050ce:	5904                	lw	s1,48(a0)
    800050d0:	413484b3          	sub	s1,s1,s3
    800050d4:	0014b493          	seqz	s1,s1
    800050d8:	bfc1                	j	800050a8 <holdingsleep+0x24>

00000000800050da <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    800050da:	1141                	addi	sp,sp,-16
    800050dc:	e406                	sd	ra,8(sp)
    800050de:	e022                	sd	s0,0(sp)
    800050e0:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    800050e2:	00003597          	auipc	a1,0x3
    800050e6:	7a658593          	addi	a1,a1,1958 # 80008888 <syscalls+0x260>
    800050ea:	0023e517          	auipc	a0,0x23e
    800050ee:	f2e50513          	addi	a0,a0,-210 # 80243018 <ftable>
    800050f2:	ffffc097          	auipc	ra,0xffffc
    800050f6:	d2a080e7          	jalr	-726(ra) # 80000e1c <initlock>
}
    800050fa:	60a2                	ld	ra,8(sp)
    800050fc:	6402                	ld	s0,0(sp)
    800050fe:	0141                	addi	sp,sp,16
    80005100:	8082                	ret

0000000080005102 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80005102:	1101                	addi	sp,sp,-32
    80005104:	ec06                	sd	ra,24(sp)
    80005106:	e822                	sd	s0,16(sp)
    80005108:	e426                	sd	s1,8(sp)
    8000510a:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    8000510c:	0023e517          	auipc	a0,0x23e
    80005110:	f0c50513          	addi	a0,a0,-244 # 80243018 <ftable>
    80005114:	ffffc097          	auipc	ra,0xffffc
    80005118:	d98080e7          	jalr	-616(ra) # 80000eac <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    8000511c:	0023e497          	auipc	s1,0x23e
    80005120:	f1448493          	addi	s1,s1,-236 # 80243030 <ftable+0x18>
    80005124:	0023f717          	auipc	a4,0x23f
    80005128:	eac70713          	addi	a4,a4,-340 # 80243fd0 <disk>
    if(f->ref == 0){
    8000512c:	40dc                	lw	a5,4(s1)
    8000512e:	cf99                	beqz	a5,8000514c <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    80005130:	02848493          	addi	s1,s1,40
    80005134:	fee49ce3          	bne	s1,a4,8000512c <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    80005138:	0023e517          	auipc	a0,0x23e
    8000513c:	ee050513          	addi	a0,a0,-288 # 80243018 <ftable>
    80005140:	ffffc097          	auipc	ra,0xffffc
    80005144:	e20080e7          	jalr	-480(ra) # 80000f60 <release>
  return 0;
    80005148:	4481                	li	s1,0
    8000514a:	a819                	j	80005160 <filealloc+0x5e>
      f->ref = 1;
    8000514c:	4785                	li	a5,1
    8000514e:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    80005150:	0023e517          	auipc	a0,0x23e
    80005154:	ec850513          	addi	a0,a0,-312 # 80243018 <ftable>
    80005158:	ffffc097          	auipc	ra,0xffffc
    8000515c:	e08080e7          	jalr	-504(ra) # 80000f60 <release>
}
    80005160:	8526                	mv	a0,s1
    80005162:	60e2                	ld	ra,24(sp)
    80005164:	6442                	ld	s0,16(sp)
    80005166:	64a2                	ld	s1,8(sp)
    80005168:	6105                	addi	sp,sp,32
    8000516a:	8082                	ret

000000008000516c <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    8000516c:	1101                	addi	sp,sp,-32
    8000516e:	ec06                	sd	ra,24(sp)
    80005170:	e822                	sd	s0,16(sp)
    80005172:	e426                	sd	s1,8(sp)
    80005174:	1000                	addi	s0,sp,32
    80005176:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    80005178:	0023e517          	auipc	a0,0x23e
    8000517c:	ea050513          	addi	a0,a0,-352 # 80243018 <ftable>
    80005180:	ffffc097          	auipc	ra,0xffffc
    80005184:	d2c080e7          	jalr	-724(ra) # 80000eac <acquire>
  if(f->ref < 1)
    80005188:	40dc                	lw	a5,4(s1)
    8000518a:	02f05263          	blez	a5,800051ae <filedup+0x42>
    panic("filedup");
  f->ref++;
    8000518e:	2785                	addiw	a5,a5,1
    80005190:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80005192:	0023e517          	auipc	a0,0x23e
    80005196:	e8650513          	addi	a0,a0,-378 # 80243018 <ftable>
    8000519a:	ffffc097          	auipc	ra,0xffffc
    8000519e:	dc6080e7          	jalr	-570(ra) # 80000f60 <release>
  return f;
}
    800051a2:	8526                	mv	a0,s1
    800051a4:	60e2                	ld	ra,24(sp)
    800051a6:	6442                	ld	s0,16(sp)
    800051a8:	64a2                	ld	s1,8(sp)
    800051aa:	6105                	addi	sp,sp,32
    800051ac:	8082                	ret
    panic("filedup");
    800051ae:	00003517          	auipc	a0,0x3
    800051b2:	6e250513          	addi	a0,a0,1762 # 80008890 <syscalls+0x268>
    800051b6:	ffffb097          	auipc	ra,0xffffb
    800051ba:	38e080e7          	jalr	910(ra) # 80000544 <panic>

00000000800051be <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    800051be:	7139                	addi	sp,sp,-64
    800051c0:	fc06                	sd	ra,56(sp)
    800051c2:	f822                	sd	s0,48(sp)
    800051c4:	f426                	sd	s1,40(sp)
    800051c6:	f04a                	sd	s2,32(sp)
    800051c8:	ec4e                	sd	s3,24(sp)
    800051ca:	e852                	sd	s4,16(sp)
    800051cc:	e456                	sd	s5,8(sp)
    800051ce:	0080                	addi	s0,sp,64
    800051d0:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    800051d2:	0023e517          	auipc	a0,0x23e
    800051d6:	e4650513          	addi	a0,a0,-442 # 80243018 <ftable>
    800051da:	ffffc097          	auipc	ra,0xffffc
    800051de:	cd2080e7          	jalr	-814(ra) # 80000eac <acquire>
  if(f->ref < 1)
    800051e2:	40dc                	lw	a5,4(s1)
    800051e4:	06f05163          	blez	a5,80005246 <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    800051e8:	37fd                	addiw	a5,a5,-1
    800051ea:	0007871b          	sext.w	a4,a5
    800051ee:	c0dc                	sw	a5,4(s1)
    800051f0:	06e04363          	bgtz	a4,80005256 <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    800051f4:	0004a903          	lw	s2,0(s1)
    800051f8:	0094ca83          	lbu	s5,9(s1)
    800051fc:	0104ba03          	ld	s4,16(s1)
    80005200:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    80005204:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    80005208:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    8000520c:	0023e517          	auipc	a0,0x23e
    80005210:	e0c50513          	addi	a0,a0,-500 # 80243018 <ftable>
    80005214:	ffffc097          	auipc	ra,0xffffc
    80005218:	d4c080e7          	jalr	-692(ra) # 80000f60 <release>

  if(ff.type == FD_PIPE){
    8000521c:	4785                	li	a5,1
    8000521e:	04f90d63          	beq	s2,a5,80005278 <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    80005222:	3979                	addiw	s2,s2,-2
    80005224:	4785                	li	a5,1
    80005226:	0527e063          	bltu	a5,s2,80005266 <fileclose+0xa8>
    begin_op();
    8000522a:	00000097          	auipc	ra,0x0
    8000522e:	ac8080e7          	jalr	-1336(ra) # 80004cf2 <begin_op>
    iput(ff.ip);
    80005232:	854e                	mv	a0,s3
    80005234:	fffff097          	auipc	ra,0xfffff
    80005238:	2b6080e7          	jalr	694(ra) # 800044ea <iput>
    end_op();
    8000523c:	00000097          	auipc	ra,0x0
    80005240:	b36080e7          	jalr	-1226(ra) # 80004d72 <end_op>
    80005244:	a00d                	j	80005266 <fileclose+0xa8>
    panic("fileclose");
    80005246:	00003517          	auipc	a0,0x3
    8000524a:	65250513          	addi	a0,a0,1618 # 80008898 <syscalls+0x270>
    8000524e:	ffffb097          	auipc	ra,0xffffb
    80005252:	2f6080e7          	jalr	758(ra) # 80000544 <panic>
    release(&ftable.lock);
    80005256:	0023e517          	auipc	a0,0x23e
    8000525a:	dc250513          	addi	a0,a0,-574 # 80243018 <ftable>
    8000525e:	ffffc097          	auipc	ra,0xffffc
    80005262:	d02080e7          	jalr	-766(ra) # 80000f60 <release>
  }
}
    80005266:	70e2                	ld	ra,56(sp)
    80005268:	7442                	ld	s0,48(sp)
    8000526a:	74a2                	ld	s1,40(sp)
    8000526c:	7902                	ld	s2,32(sp)
    8000526e:	69e2                	ld	s3,24(sp)
    80005270:	6a42                	ld	s4,16(sp)
    80005272:	6aa2                	ld	s5,8(sp)
    80005274:	6121                	addi	sp,sp,64
    80005276:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    80005278:	85d6                	mv	a1,s5
    8000527a:	8552                	mv	a0,s4
    8000527c:	00000097          	auipc	ra,0x0
    80005280:	34c080e7          	jalr	844(ra) # 800055c8 <pipeclose>
    80005284:	b7cd                	j	80005266 <fileclose+0xa8>

0000000080005286 <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    80005286:	715d                	addi	sp,sp,-80
    80005288:	e486                	sd	ra,72(sp)
    8000528a:	e0a2                	sd	s0,64(sp)
    8000528c:	fc26                	sd	s1,56(sp)
    8000528e:	f84a                	sd	s2,48(sp)
    80005290:	f44e                	sd	s3,40(sp)
    80005292:	0880                	addi	s0,sp,80
    80005294:	84aa                	mv	s1,a0
    80005296:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    80005298:	ffffd097          	auipc	ra,0xffffd
    8000529c:	a62080e7          	jalr	-1438(ra) # 80001cfa <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    800052a0:	409c                	lw	a5,0(s1)
    800052a2:	37f9                	addiw	a5,a5,-2
    800052a4:	4705                	li	a4,1
    800052a6:	04f76763          	bltu	a4,a5,800052f4 <filestat+0x6e>
    800052aa:	892a                	mv	s2,a0
    ilock(f->ip);
    800052ac:	6c88                	ld	a0,24(s1)
    800052ae:	fffff097          	auipc	ra,0xfffff
    800052b2:	082080e7          	jalr	130(ra) # 80004330 <ilock>
    stati(f->ip, &st);
    800052b6:	fb840593          	addi	a1,s0,-72
    800052ba:	6c88                	ld	a0,24(s1)
    800052bc:	fffff097          	auipc	ra,0xfffff
    800052c0:	2fe080e7          	jalr	766(ra) # 800045ba <stati>
    iunlock(f->ip);
    800052c4:	6c88                	ld	a0,24(s1)
    800052c6:	fffff097          	auipc	ra,0xfffff
    800052ca:	12c080e7          	jalr	300(ra) # 800043f2 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    800052ce:	46e1                	li	a3,24
    800052d0:	fb840613          	addi	a2,s0,-72
    800052d4:	85ce                	mv	a1,s3
    800052d6:	05893503          	ld	a0,88(s2)
    800052da:	ffffc097          	auipc	ra,0xffffc
    800052de:	670080e7          	jalr	1648(ra) # 8000194a <copyout>
    800052e2:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    800052e6:	60a6                	ld	ra,72(sp)
    800052e8:	6406                	ld	s0,64(sp)
    800052ea:	74e2                	ld	s1,56(sp)
    800052ec:	7942                	ld	s2,48(sp)
    800052ee:	79a2                	ld	s3,40(sp)
    800052f0:	6161                	addi	sp,sp,80
    800052f2:	8082                	ret
  return -1;
    800052f4:	557d                	li	a0,-1
    800052f6:	bfc5                	j	800052e6 <filestat+0x60>

00000000800052f8 <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    800052f8:	7179                	addi	sp,sp,-48
    800052fa:	f406                	sd	ra,40(sp)
    800052fc:	f022                	sd	s0,32(sp)
    800052fe:	ec26                	sd	s1,24(sp)
    80005300:	e84a                	sd	s2,16(sp)
    80005302:	e44e                	sd	s3,8(sp)
    80005304:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    80005306:	00854783          	lbu	a5,8(a0)
    8000530a:	c3d5                	beqz	a5,800053ae <fileread+0xb6>
    8000530c:	84aa                	mv	s1,a0
    8000530e:	89ae                	mv	s3,a1
    80005310:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80005312:	411c                	lw	a5,0(a0)
    80005314:	4705                	li	a4,1
    80005316:	04e78963          	beq	a5,a4,80005368 <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    8000531a:	470d                	li	a4,3
    8000531c:	04e78d63          	beq	a5,a4,80005376 <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    80005320:	4709                	li	a4,2
    80005322:	06e79e63          	bne	a5,a4,8000539e <fileread+0xa6>
    ilock(f->ip);
    80005326:	6d08                	ld	a0,24(a0)
    80005328:	fffff097          	auipc	ra,0xfffff
    8000532c:	008080e7          	jalr	8(ra) # 80004330 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    80005330:	874a                	mv	a4,s2
    80005332:	5094                	lw	a3,32(s1)
    80005334:	864e                	mv	a2,s3
    80005336:	4585                	li	a1,1
    80005338:	6c88                	ld	a0,24(s1)
    8000533a:	fffff097          	auipc	ra,0xfffff
    8000533e:	2aa080e7          	jalr	682(ra) # 800045e4 <readi>
    80005342:	892a                	mv	s2,a0
    80005344:	00a05563          	blez	a0,8000534e <fileread+0x56>
      f->off += r;
    80005348:	509c                	lw	a5,32(s1)
    8000534a:	9fa9                	addw	a5,a5,a0
    8000534c:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    8000534e:	6c88                	ld	a0,24(s1)
    80005350:	fffff097          	auipc	ra,0xfffff
    80005354:	0a2080e7          	jalr	162(ra) # 800043f2 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    80005358:	854a                	mv	a0,s2
    8000535a:	70a2                	ld	ra,40(sp)
    8000535c:	7402                	ld	s0,32(sp)
    8000535e:	64e2                	ld	s1,24(sp)
    80005360:	6942                	ld	s2,16(sp)
    80005362:	69a2                	ld	s3,8(sp)
    80005364:	6145                	addi	sp,sp,48
    80005366:	8082                	ret
    r = piperead(f->pipe, addr, n);
    80005368:	6908                	ld	a0,16(a0)
    8000536a:	00000097          	auipc	ra,0x0
    8000536e:	3ce080e7          	jalr	974(ra) # 80005738 <piperead>
    80005372:	892a                	mv	s2,a0
    80005374:	b7d5                	j	80005358 <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    80005376:	02451783          	lh	a5,36(a0)
    8000537a:	03079693          	slli	a3,a5,0x30
    8000537e:	92c1                	srli	a3,a3,0x30
    80005380:	4725                	li	a4,9
    80005382:	02d76863          	bltu	a4,a3,800053b2 <fileread+0xba>
    80005386:	0792                	slli	a5,a5,0x4
    80005388:	0023e717          	auipc	a4,0x23e
    8000538c:	bf070713          	addi	a4,a4,-1040 # 80242f78 <devsw>
    80005390:	97ba                	add	a5,a5,a4
    80005392:	639c                	ld	a5,0(a5)
    80005394:	c38d                	beqz	a5,800053b6 <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80005396:	4505                	li	a0,1
    80005398:	9782                	jalr	a5
    8000539a:	892a                	mv	s2,a0
    8000539c:	bf75                	j	80005358 <fileread+0x60>
    panic("fileread");
    8000539e:	00003517          	auipc	a0,0x3
    800053a2:	50a50513          	addi	a0,a0,1290 # 800088a8 <syscalls+0x280>
    800053a6:	ffffb097          	auipc	ra,0xffffb
    800053aa:	19e080e7          	jalr	414(ra) # 80000544 <panic>
    return -1;
    800053ae:	597d                	li	s2,-1
    800053b0:	b765                	j	80005358 <fileread+0x60>
      return -1;
    800053b2:	597d                	li	s2,-1
    800053b4:	b755                	j	80005358 <fileread+0x60>
    800053b6:	597d                	li	s2,-1
    800053b8:	b745                	j	80005358 <fileread+0x60>

00000000800053ba <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    800053ba:	715d                	addi	sp,sp,-80
    800053bc:	e486                	sd	ra,72(sp)
    800053be:	e0a2                	sd	s0,64(sp)
    800053c0:	fc26                	sd	s1,56(sp)
    800053c2:	f84a                	sd	s2,48(sp)
    800053c4:	f44e                	sd	s3,40(sp)
    800053c6:	f052                	sd	s4,32(sp)
    800053c8:	ec56                	sd	s5,24(sp)
    800053ca:	e85a                	sd	s6,16(sp)
    800053cc:	e45e                	sd	s7,8(sp)
    800053ce:	e062                	sd	s8,0(sp)
    800053d0:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    800053d2:	00954783          	lbu	a5,9(a0)
    800053d6:	10078663          	beqz	a5,800054e2 <filewrite+0x128>
    800053da:	892a                	mv	s2,a0
    800053dc:	8aae                	mv	s5,a1
    800053de:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    800053e0:	411c                	lw	a5,0(a0)
    800053e2:	4705                	li	a4,1
    800053e4:	02e78263          	beq	a5,a4,80005408 <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800053e8:	470d                	li	a4,3
    800053ea:	02e78663          	beq	a5,a4,80005416 <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    800053ee:	4709                	li	a4,2
    800053f0:	0ee79163          	bne	a5,a4,800054d2 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    800053f4:	0ac05d63          	blez	a2,800054ae <filewrite+0xf4>
    int i = 0;
    800053f8:	4981                	li	s3,0
    800053fa:	6b05                	lui	s6,0x1
    800053fc:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80005400:	6b85                	lui	s7,0x1
    80005402:	c00b8b9b          	addiw	s7,s7,-1024
    80005406:	a861                	j	8000549e <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80005408:	6908                	ld	a0,16(a0)
    8000540a:	00000097          	auipc	ra,0x0
    8000540e:	22e080e7          	jalr	558(ra) # 80005638 <pipewrite>
    80005412:	8a2a                	mv	s4,a0
    80005414:	a045                	j	800054b4 <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80005416:	02451783          	lh	a5,36(a0)
    8000541a:	03079693          	slli	a3,a5,0x30
    8000541e:	92c1                	srli	a3,a3,0x30
    80005420:	4725                	li	a4,9
    80005422:	0cd76263          	bltu	a4,a3,800054e6 <filewrite+0x12c>
    80005426:	0792                	slli	a5,a5,0x4
    80005428:	0023e717          	auipc	a4,0x23e
    8000542c:	b5070713          	addi	a4,a4,-1200 # 80242f78 <devsw>
    80005430:	97ba                	add	a5,a5,a4
    80005432:	679c                	ld	a5,8(a5)
    80005434:	cbdd                	beqz	a5,800054ea <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80005436:	4505                	li	a0,1
    80005438:	9782                	jalr	a5
    8000543a:	8a2a                	mv	s4,a0
    8000543c:	a8a5                	j	800054b4 <filewrite+0xfa>
    8000543e:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80005442:	00000097          	auipc	ra,0x0
    80005446:	8b0080e7          	jalr	-1872(ra) # 80004cf2 <begin_op>
      ilock(f->ip);
    8000544a:	01893503          	ld	a0,24(s2)
    8000544e:	fffff097          	auipc	ra,0xfffff
    80005452:	ee2080e7          	jalr	-286(ra) # 80004330 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80005456:	8762                	mv	a4,s8
    80005458:	02092683          	lw	a3,32(s2)
    8000545c:	01598633          	add	a2,s3,s5
    80005460:	4585                	li	a1,1
    80005462:	01893503          	ld	a0,24(s2)
    80005466:	fffff097          	auipc	ra,0xfffff
    8000546a:	276080e7          	jalr	630(ra) # 800046dc <writei>
    8000546e:	84aa                	mv	s1,a0
    80005470:	00a05763          	blez	a0,8000547e <filewrite+0xc4>
        f->off += r;
    80005474:	02092783          	lw	a5,32(s2)
    80005478:	9fa9                	addw	a5,a5,a0
    8000547a:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    8000547e:	01893503          	ld	a0,24(s2)
    80005482:	fffff097          	auipc	ra,0xfffff
    80005486:	f70080e7          	jalr	-144(ra) # 800043f2 <iunlock>
      end_op();
    8000548a:	00000097          	auipc	ra,0x0
    8000548e:	8e8080e7          	jalr	-1816(ra) # 80004d72 <end_op>

      if(r != n1){
    80005492:	009c1f63          	bne	s8,s1,800054b0 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80005496:	013489bb          	addw	s3,s1,s3
    while(i < n){
    8000549a:	0149db63          	bge	s3,s4,800054b0 <filewrite+0xf6>
      int n1 = n - i;
    8000549e:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    800054a2:	84be                	mv	s1,a5
    800054a4:	2781                	sext.w	a5,a5
    800054a6:	f8fb5ce3          	bge	s6,a5,8000543e <filewrite+0x84>
    800054aa:	84de                	mv	s1,s7
    800054ac:	bf49                	j	8000543e <filewrite+0x84>
    int i = 0;
    800054ae:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    800054b0:	013a1f63          	bne	s4,s3,800054ce <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    800054b4:	8552                	mv	a0,s4
    800054b6:	60a6                	ld	ra,72(sp)
    800054b8:	6406                	ld	s0,64(sp)
    800054ba:	74e2                	ld	s1,56(sp)
    800054bc:	7942                	ld	s2,48(sp)
    800054be:	79a2                	ld	s3,40(sp)
    800054c0:	7a02                	ld	s4,32(sp)
    800054c2:	6ae2                	ld	s5,24(sp)
    800054c4:	6b42                	ld	s6,16(sp)
    800054c6:	6ba2                	ld	s7,8(sp)
    800054c8:	6c02                	ld	s8,0(sp)
    800054ca:	6161                	addi	sp,sp,80
    800054cc:	8082                	ret
    ret = (i == n ? n : -1);
    800054ce:	5a7d                	li	s4,-1
    800054d0:	b7d5                	j	800054b4 <filewrite+0xfa>
    panic("filewrite");
    800054d2:	00003517          	auipc	a0,0x3
    800054d6:	3e650513          	addi	a0,a0,998 # 800088b8 <syscalls+0x290>
    800054da:	ffffb097          	auipc	ra,0xffffb
    800054de:	06a080e7          	jalr	106(ra) # 80000544 <panic>
    return -1;
    800054e2:	5a7d                	li	s4,-1
    800054e4:	bfc1                	j	800054b4 <filewrite+0xfa>
      return -1;
    800054e6:	5a7d                	li	s4,-1
    800054e8:	b7f1                	j	800054b4 <filewrite+0xfa>
    800054ea:	5a7d                	li	s4,-1
    800054ec:	b7e1                	j	800054b4 <filewrite+0xfa>

00000000800054ee <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    800054ee:	7179                	addi	sp,sp,-48
    800054f0:	f406                	sd	ra,40(sp)
    800054f2:	f022                	sd	s0,32(sp)
    800054f4:	ec26                	sd	s1,24(sp)
    800054f6:	e84a                	sd	s2,16(sp)
    800054f8:	e44e                	sd	s3,8(sp)
    800054fa:	e052                	sd	s4,0(sp)
    800054fc:	1800                	addi	s0,sp,48
    800054fe:	84aa                	mv	s1,a0
    80005500:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80005502:	0005b023          	sd	zero,0(a1)
    80005506:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    8000550a:	00000097          	auipc	ra,0x0
    8000550e:	bf8080e7          	jalr	-1032(ra) # 80005102 <filealloc>
    80005512:	e088                	sd	a0,0(s1)
    80005514:	c551                	beqz	a0,800055a0 <pipealloc+0xb2>
    80005516:	00000097          	auipc	ra,0x0
    8000551a:	bec080e7          	jalr	-1044(ra) # 80005102 <filealloc>
    8000551e:	00aa3023          	sd	a0,0(s4)
    80005522:	c92d                	beqz	a0,80005594 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80005524:	ffffb097          	auipc	ra,0xffffb
    80005528:	7d0080e7          	jalr	2000(ra) # 80000cf4 <kalloc>
    8000552c:	892a                	mv	s2,a0
    8000552e:	c125                	beqz	a0,8000558e <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80005530:	4985                	li	s3,1
    80005532:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80005536:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    8000553a:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    8000553e:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80005542:	00003597          	auipc	a1,0x3
    80005546:	fb658593          	addi	a1,a1,-74 # 800084f8 <states.1882+0x168>
    8000554a:	ffffc097          	auipc	ra,0xffffc
    8000554e:	8d2080e7          	jalr	-1838(ra) # 80000e1c <initlock>
  (*f0)->type = FD_PIPE;
    80005552:	609c                	ld	a5,0(s1)
    80005554:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80005558:	609c                	ld	a5,0(s1)
    8000555a:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    8000555e:	609c                	ld	a5,0(s1)
    80005560:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80005564:	609c                	ld	a5,0(s1)
    80005566:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    8000556a:	000a3783          	ld	a5,0(s4)
    8000556e:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80005572:	000a3783          	ld	a5,0(s4)
    80005576:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    8000557a:	000a3783          	ld	a5,0(s4)
    8000557e:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80005582:	000a3783          	ld	a5,0(s4)
    80005586:	0127b823          	sd	s2,16(a5)
  return 0;
    8000558a:	4501                	li	a0,0
    8000558c:	a025                	j	800055b4 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    8000558e:	6088                	ld	a0,0(s1)
    80005590:	e501                	bnez	a0,80005598 <pipealloc+0xaa>
    80005592:	a039                	j	800055a0 <pipealloc+0xb2>
    80005594:	6088                	ld	a0,0(s1)
    80005596:	c51d                	beqz	a0,800055c4 <pipealloc+0xd6>
    fileclose(*f0);
    80005598:	00000097          	auipc	ra,0x0
    8000559c:	c26080e7          	jalr	-986(ra) # 800051be <fileclose>
  if(*f1)
    800055a0:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    800055a4:	557d                	li	a0,-1
  if(*f1)
    800055a6:	c799                	beqz	a5,800055b4 <pipealloc+0xc6>
    fileclose(*f1);
    800055a8:	853e                	mv	a0,a5
    800055aa:	00000097          	auipc	ra,0x0
    800055ae:	c14080e7          	jalr	-1004(ra) # 800051be <fileclose>
  return -1;
    800055b2:	557d                	li	a0,-1
}
    800055b4:	70a2                	ld	ra,40(sp)
    800055b6:	7402                	ld	s0,32(sp)
    800055b8:	64e2                	ld	s1,24(sp)
    800055ba:	6942                	ld	s2,16(sp)
    800055bc:	69a2                	ld	s3,8(sp)
    800055be:	6a02                	ld	s4,0(sp)
    800055c0:	6145                	addi	sp,sp,48
    800055c2:	8082                	ret
  return -1;
    800055c4:	557d                	li	a0,-1
    800055c6:	b7fd                	j	800055b4 <pipealloc+0xc6>

00000000800055c8 <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    800055c8:	1101                	addi	sp,sp,-32
    800055ca:	ec06                	sd	ra,24(sp)
    800055cc:	e822                	sd	s0,16(sp)
    800055ce:	e426                	sd	s1,8(sp)
    800055d0:	e04a                	sd	s2,0(sp)
    800055d2:	1000                	addi	s0,sp,32
    800055d4:	84aa                	mv	s1,a0
    800055d6:	892e                	mv	s2,a1
  acquire(&pi->lock);
    800055d8:	ffffc097          	auipc	ra,0xffffc
    800055dc:	8d4080e7          	jalr	-1836(ra) # 80000eac <acquire>
  if(writable){
    800055e0:	02090d63          	beqz	s2,8000561a <pipeclose+0x52>
    pi->writeopen = 0;
    800055e4:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    800055e8:	21848513          	addi	a0,s1,536
    800055ec:	ffffd097          	auipc	ra,0xffffd
    800055f0:	0d6080e7          	jalr	214(ra) # 800026c2 <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    800055f4:	2204b783          	ld	a5,544(s1)
    800055f8:	eb95                	bnez	a5,8000562c <pipeclose+0x64>
    release(&pi->lock);
    800055fa:	8526                	mv	a0,s1
    800055fc:	ffffc097          	auipc	ra,0xffffc
    80005600:	964080e7          	jalr	-1692(ra) # 80000f60 <release>
    kfree((char*)pi);
    80005604:	8526                	mv	a0,s1
    80005606:	ffffb097          	auipc	ra,0xffffb
    8000560a:	590080e7          	jalr	1424(ra) # 80000b96 <kfree>
  } else
    release(&pi->lock);
}
    8000560e:	60e2                	ld	ra,24(sp)
    80005610:	6442                	ld	s0,16(sp)
    80005612:	64a2                	ld	s1,8(sp)
    80005614:	6902                	ld	s2,0(sp)
    80005616:	6105                	addi	sp,sp,32
    80005618:	8082                	ret
    pi->readopen = 0;
    8000561a:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    8000561e:	21c48513          	addi	a0,s1,540
    80005622:	ffffd097          	auipc	ra,0xffffd
    80005626:	0a0080e7          	jalr	160(ra) # 800026c2 <wakeup>
    8000562a:	b7e9                	j	800055f4 <pipeclose+0x2c>
    release(&pi->lock);
    8000562c:	8526                	mv	a0,s1
    8000562e:	ffffc097          	auipc	ra,0xffffc
    80005632:	932080e7          	jalr	-1742(ra) # 80000f60 <release>
}
    80005636:	bfe1                	j	8000560e <pipeclose+0x46>

0000000080005638 <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80005638:	7159                	addi	sp,sp,-112
    8000563a:	f486                	sd	ra,104(sp)
    8000563c:	f0a2                	sd	s0,96(sp)
    8000563e:	eca6                	sd	s1,88(sp)
    80005640:	e8ca                	sd	s2,80(sp)
    80005642:	e4ce                	sd	s3,72(sp)
    80005644:	e0d2                	sd	s4,64(sp)
    80005646:	fc56                	sd	s5,56(sp)
    80005648:	f85a                	sd	s6,48(sp)
    8000564a:	f45e                	sd	s7,40(sp)
    8000564c:	f062                	sd	s8,32(sp)
    8000564e:	ec66                	sd	s9,24(sp)
    80005650:	1880                	addi	s0,sp,112
    80005652:	84aa                	mv	s1,a0
    80005654:	8aae                	mv	s5,a1
    80005656:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80005658:	ffffc097          	auipc	ra,0xffffc
    8000565c:	6a2080e7          	jalr	1698(ra) # 80001cfa <myproc>
    80005660:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80005662:	8526                	mv	a0,s1
    80005664:	ffffc097          	auipc	ra,0xffffc
    80005668:	848080e7          	jalr	-1976(ra) # 80000eac <acquire>
  while(i < n){
    8000566c:	0d405463          	blez	s4,80005734 <pipewrite+0xfc>
    80005670:	8ba6                	mv	s7,s1
  int i = 0;
    80005672:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005674:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80005676:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    8000567a:	21c48c13          	addi	s8,s1,540
    8000567e:	a08d                	j	800056e0 <pipewrite+0xa8>
      release(&pi->lock);
    80005680:	8526                	mv	a0,s1
    80005682:	ffffc097          	auipc	ra,0xffffc
    80005686:	8de080e7          	jalr	-1826(ra) # 80000f60 <release>
      return -1;
    8000568a:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    8000568c:	854a                	mv	a0,s2
    8000568e:	70a6                	ld	ra,104(sp)
    80005690:	7406                	ld	s0,96(sp)
    80005692:	64e6                	ld	s1,88(sp)
    80005694:	6946                	ld	s2,80(sp)
    80005696:	69a6                	ld	s3,72(sp)
    80005698:	6a06                	ld	s4,64(sp)
    8000569a:	7ae2                	ld	s5,56(sp)
    8000569c:	7b42                	ld	s6,48(sp)
    8000569e:	7ba2                	ld	s7,40(sp)
    800056a0:	7c02                	ld	s8,32(sp)
    800056a2:	6ce2                	ld	s9,24(sp)
    800056a4:	6165                	addi	sp,sp,112
    800056a6:	8082                	ret
      wakeup(&pi->nread);
    800056a8:	8566                	mv	a0,s9
    800056aa:	ffffd097          	auipc	ra,0xffffd
    800056ae:	018080e7          	jalr	24(ra) # 800026c2 <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    800056b2:	85de                	mv	a1,s7
    800056b4:	8562                	mv	a0,s8
    800056b6:	ffffd097          	auipc	ra,0xffffd
    800056ba:	fa8080e7          	jalr	-88(ra) # 8000265e <sleep>
    800056be:	a839                	j	800056dc <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    800056c0:	21c4a783          	lw	a5,540(s1)
    800056c4:	0017871b          	addiw	a4,a5,1
    800056c8:	20e4ae23          	sw	a4,540(s1)
    800056cc:	1ff7f793          	andi	a5,a5,511
    800056d0:	97a6                	add	a5,a5,s1
    800056d2:	f9f44703          	lbu	a4,-97(s0)
    800056d6:	00e78c23          	sb	a4,24(a5)
      i++;
    800056da:	2905                	addiw	s2,s2,1
  while(i < n){
    800056dc:	05495063          	bge	s2,s4,8000571c <pipewrite+0xe4>
    if(pi->readopen == 0 || killed(pr)){
    800056e0:	2204a783          	lw	a5,544(s1)
    800056e4:	dfd1                	beqz	a5,80005680 <pipewrite+0x48>
    800056e6:	854e                	mv	a0,s3
    800056e8:	ffffd097          	auipc	ra,0xffffd
    800056ec:	22a080e7          	jalr	554(ra) # 80002912 <killed>
    800056f0:	f941                	bnez	a0,80005680 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    800056f2:	2184a783          	lw	a5,536(s1)
    800056f6:	21c4a703          	lw	a4,540(s1)
    800056fa:	2007879b          	addiw	a5,a5,512
    800056fe:	faf705e3          	beq	a4,a5,800056a8 <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80005702:	4685                	li	a3,1
    80005704:	01590633          	add	a2,s2,s5
    80005708:	f9f40593          	addi	a1,s0,-97
    8000570c:	0589b503          	ld	a0,88(s3)
    80005710:	ffffc097          	auipc	ra,0xffffc
    80005714:	2fe080e7          	jalr	766(ra) # 80001a0e <copyin>
    80005718:	fb6514e3          	bne	a0,s6,800056c0 <pipewrite+0x88>
  wakeup(&pi->nread);
    8000571c:	21848513          	addi	a0,s1,536
    80005720:	ffffd097          	auipc	ra,0xffffd
    80005724:	fa2080e7          	jalr	-94(ra) # 800026c2 <wakeup>
  release(&pi->lock);
    80005728:	8526                	mv	a0,s1
    8000572a:	ffffc097          	auipc	ra,0xffffc
    8000572e:	836080e7          	jalr	-1994(ra) # 80000f60 <release>
  return i;
    80005732:	bfa9                	j	8000568c <pipewrite+0x54>
  int i = 0;
    80005734:	4901                	li	s2,0
    80005736:	b7dd                	j	8000571c <pipewrite+0xe4>

0000000080005738 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80005738:	715d                	addi	sp,sp,-80
    8000573a:	e486                	sd	ra,72(sp)
    8000573c:	e0a2                	sd	s0,64(sp)
    8000573e:	fc26                	sd	s1,56(sp)
    80005740:	f84a                	sd	s2,48(sp)
    80005742:	f44e                	sd	s3,40(sp)
    80005744:	f052                	sd	s4,32(sp)
    80005746:	ec56                	sd	s5,24(sp)
    80005748:	e85a                	sd	s6,16(sp)
    8000574a:	0880                	addi	s0,sp,80
    8000574c:	84aa                	mv	s1,a0
    8000574e:	892e                	mv	s2,a1
    80005750:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80005752:	ffffc097          	auipc	ra,0xffffc
    80005756:	5a8080e7          	jalr	1448(ra) # 80001cfa <myproc>
    8000575a:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    8000575c:	8b26                	mv	s6,s1
    8000575e:	8526                	mv	a0,s1
    80005760:	ffffb097          	auipc	ra,0xffffb
    80005764:	74c080e7          	jalr	1868(ra) # 80000eac <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005768:	2184a703          	lw	a4,536(s1)
    8000576c:	21c4a783          	lw	a5,540(s1)
    if(killed(pr)){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80005770:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005774:	02f71763          	bne	a4,a5,800057a2 <piperead+0x6a>
    80005778:	2244a783          	lw	a5,548(s1)
    8000577c:	c39d                	beqz	a5,800057a2 <piperead+0x6a>
    if(killed(pr)){
    8000577e:	8552                	mv	a0,s4
    80005780:	ffffd097          	auipc	ra,0xffffd
    80005784:	192080e7          	jalr	402(ra) # 80002912 <killed>
    80005788:	e941                	bnez	a0,80005818 <piperead+0xe0>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    8000578a:	85da                	mv	a1,s6
    8000578c:	854e                	mv	a0,s3
    8000578e:	ffffd097          	auipc	ra,0xffffd
    80005792:	ed0080e7          	jalr	-304(ra) # 8000265e <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80005796:	2184a703          	lw	a4,536(s1)
    8000579a:	21c4a783          	lw	a5,540(s1)
    8000579e:	fcf70de3          	beq	a4,a5,80005778 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800057a2:	09505263          	blez	s5,80005826 <piperead+0xee>
    800057a6:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800057a8:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    800057aa:	2184a783          	lw	a5,536(s1)
    800057ae:	21c4a703          	lw	a4,540(s1)
    800057b2:	02f70d63          	beq	a4,a5,800057ec <piperead+0xb4>
    ch = pi->data[pi->nread++ % PIPESIZE];
    800057b6:	0017871b          	addiw	a4,a5,1
    800057ba:	20e4ac23          	sw	a4,536(s1)
    800057be:	1ff7f793          	andi	a5,a5,511
    800057c2:	97a6                	add	a5,a5,s1
    800057c4:	0187c783          	lbu	a5,24(a5)
    800057c8:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    800057cc:	4685                	li	a3,1
    800057ce:	fbf40613          	addi	a2,s0,-65
    800057d2:	85ca                	mv	a1,s2
    800057d4:	058a3503          	ld	a0,88(s4)
    800057d8:	ffffc097          	auipc	ra,0xffffc
    800057dc:	172080e7          	jalr	370(ra) # 8000194a <copyout>
    800057e0:	01650663          	beq	a0,s6,800057ec <piperead+0xb4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    800057e4:	2985                	addiw	s3,s3,1
    800057e6:	0905                	addi	s2,s2,1
    800057e8:	fd3a91e3          	bne	s5,s3,800057aa <piperead+0x72>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    800057ec:	21c48513          	addi	a0,s1,540
    800057f0:	ffffd097          	auipc	ra,0xffffd
    800057f4:	ed2080e7          	jalr	-302(ra) # 800026c2 <wakeup>
  release(&pi->lock);
    800057f8:	8526                	mv	a0,s1
    800057fa:	ffffb097          	auipc	ra,0xffffb
    800057fe:	766080e7          	jalr	1894(ra) # 80000f60 <release>
  return i;
}
    80005802:	854e                	mv	a0,s3
    80005804:	60a6                	ld	ra,72(sp)
    80005806:	6406                	ld	s0,64(sp)
    80005808:	74e2                	ld	s1,56(sp)
    8000580a:	7942                	ld	s2,48(sp)
    8000580c:	79a2                	ld	s3,40(sp)
    8000580e:	7a02                	ld	s4,32(sp)
    80005810:	6ae2                	ld	s5,24(sp)
    80005812:	6b42                	ld	s6,16(sp)
    80005814:	6161                	addi	sp,sp,80
    80005816:	8082                	ret
      release(&pi->lock);
    80005818:	8526                	mv	a0,s1
    8000581a:	ffffb097          	auipc	ra,0xffffb
    8000581e:	746080e7          	jalr	1862(ra) # 80000f60 <release>
      return -1;
    80005822:	59fd                	li	s3,-1
    80005824:	bff9                	j	80005802 <piperead+0xca>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80005826:	4981                	li	s3,0
    80005828:	b7d1                	j	800057ec <piperead+0xb4>

000000008000582a <flags2perm>:
#include "elf.h"

static int loadseg(pde_t *, uint64, struct inode *, uint, uint);

int flags2perm(int flags)
{
    8000582a:	1141                	addi	sp,sp,-16
    8000582c:	e422                	sd	s0,8(sp)
    8000582e:	0800                	addi	s0,sp,16
    80005830:	87aa                	mv	a5,a0
    int perm = 0;
    if(flags & 0x1)
    80005832:	8905                	andi	a0,a0,1
    80005834:	c111                	beqz	a0,80005838 <flags2perm+0xe>
      perm = PTE_X;
    80005836:	4521                	li	a0,8
    if(flags & 0x2)
    80005838:	8b89                	andi	a5,a5,2
    8000583a:	c399                	beqz	a5,80005840 <flags2perm+0x16>
      perm |= PTE_W;
    8000583c:	00456513          	ori	a0,a0,4
    return perm;
}
    80005840:	6422                	ld	s0,8(sp)
    80005842:	0141                	addi	sp,sp,16
    80005844:	8082                	ret

0000000080005846 <exec>:

int
exec(char *path, char **argv)
{
    80005846:	df010113          	addi	sp,sp,-528
    8000584a:	20113423          	sd	ra,520(sp)
    8000584e:	20813023          	sd	s0,512(sp)
    80005852:	ffa6                	sd	s1,504(sp)
    80005854:	fbca                	sd	s2,496(sp)
    80005856:	f7ce                	sd	s3,488(sp)
    80005858:	f3d2                	sd	s4,480(sp)
    8000585a:	efd6                	sd	s5,472(sp)
    8000585c:	ebda                	sd	s6,464(sp)
    8000585e:	e7de                	sd	s7,456(sp)
    80005860:	e3e2                	sd	s8,448(sp)
    80005862:	ff66                	sd	s9,440(sp)
    80005864:	fb6a                	sd	s10,432(sp)
    80005866:	f76e                	sd	s11,424(sp)
    80005868:	0c00                	addi	s0,sp,528
    8000586a:	84aa                	mv	s1,a0
    8000586c:	dea43c23          	sd	a0,-520(s0)
    80005870:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    80005874:	ffffc097          	auipc	ra,0xffffc
    80005878:	486080e7          	jalr	1158(ra) # 80001cfa <myproc>
    8000587c:	892a                	mv	s2,a0

  begin_op();
    8000587e:	fffff097          	auipc	ra,0xfffff
    80005882:	474080e7          	jalr	1140(ra) # 80004cf2 <begin_op>

  if((ip = namei(path)) == 0){
    80005886:	8526                	mv	a0,s1
    80005888:	fffff097          	auipc	ra,0xfffff
    8000588c:	24e080e7          	jalr	590(ra) # 80004ad6 <namei>
    80005890:	c92d                	beqz	a0,80005902 <exec+0xbc>
    80005892:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    80005894:	fffff097          	auipc	ra,0xfffff
    80005898:	a9c080e7          	jalr	-1380(ra) # 80004330 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    8000589c:	04000713          	li	a4,64
    800058a0:	4681                	li	a3,0
    800058a2:	e5040613          	addi	a2,s0,-432
    800058a6:	4581                	li	a1,0
    800058a8:	8526                	mv	a0,s1
    800058aa:	fffff097          	auipc	ra,0xfffff
    800058ae:	d3a080e7          	jalr	-710(ra) # 800045e4 <readi>
    800058b2:	04000793          	li	a5,64
    800058b6:	00f51a63          	bne	a0,a5,800058ca <exec+0x84>
    goto bad;

  if(elf.magic != ELF_MAGIC)
    800058ba:	e5042703          	lw	a4,-432(s0)
    800058be:	464c47b7          	lui	a5,0x464c4
    800058c2:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    800058c6:	04f70463          	beq	a4,a5,8000590e <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    800058ca:	8526                	mv	a0,s1
    800058cc:	fffff097          	auipc	ra,0xfffff
    800058d0:	cc6080e7          	jalr	-826(ra) # 80004592 <iunlockput>
    end_op();
    800058d4:	fffff097          	auipc	ra,0xfffff
    800058d8:	49e080e7          	jalr	1182(ra) # 80004d72 <end_op>
  }
  return -1;
    800058dc:	557d                	li	a0,-1
}
    800058de:	20813083          	ld	ra,520(sp)
    800058e2:	20013403          	ld	s0,512(sp)
    800058e6:	74fe                	ld	s1,504(sp)
    800058e8:	795e                	ld	s2,496(sp)
    800058ea:	79be                	ld	s3,488(sp)
    800058ec:	7a1e                	ld	s4,480(sp)
    800058ee:	6afe                	ld	s5,472(sp)
    800058f0:	6b5e                	ld	s6,464(sp)
    800058f2:	6bbe                	ld	s7,456(sp)
    800058f4:	6c1e                	ld	s8,448(sp)
    800058f6:	7cfa                	ld	s9,440(sp)
    800058f8:	7d5a                	ld	s10,432(sp)
    800058fa:	7dba                	ld	s11,424(sp)
    800058fc:	21010113          	addi	sp,sp,528
    80005900:	8082                	ret
    end_op();
    80005902:	fffff097          	auipc	ra,0xfffff
    80005906:	470080e7          	jalr	1136(ra) # 80004d72 <end_op>
    return -1;
    8000590a:	557d                	li	a0,-1
    8000590c:	bfc9                	j	800058de <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    8000590e:	854a                	mv	a0,s2
    80005910:	ffffc097          	auipc	ra,0xffffc
    80005914:	5ea080e7          	jalr	1514(ra) # 80001efa <proc_pagetable>
    80005918:	8baa                	mv	s7,a0
    8000591a:	d945                	beqz	a0,800058ca <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000591c:	e7042983          	lw	s3,-400(s0)
    80005920:	e8845783          	lhu	a5,-376(s0)
    80005924:	c7ad                	beqz	a5,8000598e <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005926:	4a01                	li	s4,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005928:	4b01                	li	s6,0
    if(ph.vaddr % PGSIZE != 0)
    8000592a:	6c85                	lui	s9,0x1
    8000592c:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    80005930:	def43823          	sd	a5,-528(s0)
    80005934:	ac0d                	j	80005b66 <exec+0x320>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005936:	00003517          	auipc	a0,0x3
    8000593a:	f9250513          	addi	a0,a0,-110 # 800088c8 <syscalls+0x2a0>
    8000593e:	ffffb097          	auipc	ra,0xffffb
    80005942:	c06080e7          	jalr	-1018(ra) # 80000544 <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005946:	8756                	mv	a4,s5
    80005948:	012d86bb          	addw	a3,s11,s2
    8000594c:	4581                	li	a1,0
    8000594e:	8526                	mv	a0,s1
    80005950:	fffff097          	auipc	ra,0xfffff
    80005954:	c94080e7          	jalr	-876(ra) # 800045e4 <readi>
    80005958:	2501                	sext.w	a0,a0
    8000595a:	1aaa9a63          	bne	s5,a0,80005b0e <exec+0x2c8>
  for(i = 0; i < sz; i += PGSIZE){
    8000595e:	6785                	lui	a5,0x1
    80005960:	0127893b          	addw	s2,a5,s2
    80005964:	77fd                	lui	a5,0xfffff
    80005966:	01478a3b          	addw	s4,a5,s4
    8000596a:	1f897563          	bgeu	s2,s8,80005b54 <exec+0x30e>
    pa = walkaddr(pagetable, va + i);
    8000596e:	02091593          	slli	a1,s2,0x20
    80005972:	9181                	srli	a1,a1,0x20
    80005974:	95ea                	add	a1,a1,s10
    80005976:	855e                	mv	a0,s7
    80005978:	ffffc097          	auipc	ra,0xffffc
    8000597c:	9c2080e7          	jalr	-1598(ra) # 8000133a <walkaddr>
    80005980:	862a                	mv	a2,a0
    if(pa == 0)
    80005982:	d955                	beqz	a0,80005936 <exec+0xf0>
      n = PGSIZE;
    80005984:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    80005986:	fd9a70e3          	bgeu	s4,s9,80005946 <exec+0x100>
      n = sz - i;
    8000598a:	8ad2                	mv	s5,s4
    8000598c:	bf6d                	j	80005946 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    8000598e:	4a01                	li	s4,0
  iunlockput(ip);
    80005990:	8526                	mv	a0,s1
    80005992:	fffff097          	auipc	ra,0xfffff
    80005996:	c00080e7          	jalr	-1024(ra) # 80004592 <iunlockput>
  end_op();
    8000599a:	fffff097          	auipc	ra,0xfffff
    8000599e:	3d8080e7          	jalr	984(ra) # 80004d72 <end_op>
  p = myproc();
    800059a2:	ffffc097          	auipc	ra,0xffffc
    800059a6:	358080e7          	jalr	856(ra) # 80001cfa <myproc>
    800059aa:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    800059ac:	05053d03          	ld	s10,80(a0)
  sz = PGROUNDUP(sz);
    800059b0:	6785                	lui	a5,0x1
    800059b2:	17fd                	addi	a5,a5,-1
    800059b4:	9a3e                	add	s4,s4,a5
    800059b6:	757d                	lui	a0,0xfffff
    800059b8:	00aa77b3          	and	a5,s4,a0
    800059bc:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800059c0:	4691                	li	a3,4
    800059c2:	6609                	lui	a2,0x2
    800059c4:	963e                	add	a2,a2,a5
    800059c6:	85be                	mv	a1,a5
    800059c8:	855e                	mv	a0,s7
    800059ca:	ffffc097          	auipc	ra,0xffffc
    800059ce:	d24080e7          	jalr	-732(ra) # 800016ee <uvmalloc>
    800059d2:	8b2a                	mv	s6,a0
  ip = 0;
    800059d4:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE, PTE_W)) == 0)
    800059d6:	12050c63          	beqz	a0,80005b0e <exec+0x2c8>
  uvmclear(pagetable, sz-2*PGSIZE);
    800059da:	75f9                	lui	a1,0xffffe
    800059dc:	95aa                	add	a1,a1,a0
    800059de:	855e                	mv	a0,s7
    800059e0:	ffffc097          	auipc	ra,0xffffc
    800059e4:	f38080e7          	jalr	-200(ra) # 80001918 <uvmclear>
  stackbase = sp - PGSIZE;
    800059e8:	7c7d                	lui	s8,0xfffff
    800059ea:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    800059ec:	e0043783          	ld	a5,-512(s0)
    800059f0:	6388                	ld	a0,0(a5)
    800059f2:	c535                	beqz	a0,80005a5e <exec+0x218>
    800059f4:	e9040993          	addi	s3,s0,-368
    800059f8:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    800059fc:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    800059fe:	ffffb097          	auipc	ra,0xffffb
    80005a02:	72e080e7          	jalr	1838(ra) # 8000112c <strlen>
    80005a06:	2505                	addiw	a0,a0,1
    80005a08:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005a0c:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    80005a10:	13896663          	bltu	s2,s8,80005b3c <exec+0x2f6>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    80005a14:	e0043d83          	ld	s11,-512(s0)
    80005a18:	000dba03          	ld	s4,0(s11)
    80005a1c:	8552                	mv	a0,s4
    80005a1e:	ffffb097          	auipc	ra,0xffffb
    80005a22:	70e080e7          	jalr	1806(ra) # 8000112c <strlen>
    80005a26:	0015069b          	addiw	a3,a0,1
    80005a2a:	8652                	mv	a2,s4
    80005a2c:	85ca                	mv	a1,s2
    80005a2e:	855e                	mv	a0,s7
    80005a30:	ffffc097          	auipc	ra,0xffffc
    80005a34:	f1a080e7          	jalr	-230(ra) # 8000194a <copyout>
    80005a38:	10054663          	bltz	a0,80005b44 <exec+0x2fe>
    ustack[argc] = sp;
    80005a3c:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    80005a40:	0485                	addi	s1,s1,1
    80005a42:	008d8793          	addi	a5,s11,8
    80005a46:	e0f43023          	sd	a5,-512(s0)
    80005a4a:	008db503          	ld	a0,8(s11)
    80005a4e:	c911                	beqz	a0,80005a62 <exec+0x21c>
    if(argc >= MAXARG)
    80005a50:	09a1                	addi	s3,s3,8
    80005a52:	fb3c96e3          	bne	s9,s3,800059fe <exec+0x1b8>
  sz = sz1;
    80005a56:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005a5a:	4481                	li	s1,0
    80005a5c:	a84d                	j	80005b0e <exec+0x2c8>
  sp = sz;
    80005a5e:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    80005a60:	4481                	li	s1,0
  ustack[argc] = 0;
    80005a62:	00349793          	slli	a5,s1,0x3
    80005a66:	f9040713          	addi	a4,s0,-112
    80005a6a:	97ba                	add	a5,a5,a4
    80005a6c:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    80005a70:	00148693          	addi	a3,s1,1
    80005a74:	068e                	slli	a3,a3,0x3
    80005a76:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    80005a7a:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    80005a7e:	01897663          	bgeu	s2,s8,80005a8a <exec+0x244>
  sz = sz1;
    80005a82:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005a86:	4481                	li	s1,0
    80005a88:	a059                	j	80005b0e <exec+0x2c8>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    80005a8a:	e9040613          	addi	a2,s0,-368
    80005a8e:	85ca                	mv	a1,s2
    80005a90:	855e                	mv	a0,s7
    80005a92:	ffffc097          	auipc	ra,0xffffc
    80005a96:	eb8080e7          	jalr	-328(ra) # 8000194a <copyout>
    80005a9a:	0a054963          	bltz	a0,80005b4c <exec+0x306>
  p->trapframe->a1 = sp;
    80005a9e:	060ab783          	ld	a5,96(s5)
    80005aa2:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    80005aa6:	df843783          	ld	a5,-520(s0)
    80005aaa:	0007c703          	lbu	a4,0(a5)
    80005aae:	cf11                	beqz	a4,80005aca <exec+0x284>
    80005ab0:	0785                	addi	a5,a5,1
    if(*s == '/')
    80005ab2:	02f00693          	li	a3,47
    80005ab6:	a039                	j	80005ac4 <exec+0x27e>
      last = s+1;
    80005ab8:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    80005abc:	0785                	addi	a5,a5,1
    80005abe:	fff7c703          	lbu	a4,-1(a5)
    80005ac2:	c701                	beqz	a4,80005aca <exec+0x284>
    if(*s == '/')
    80005ac4:	fed71ce3          	bne	a4,a3,80005abc <exec+0x276>
    80005ac8:	bfc5                	j	80005ab8 <exec+0x272>
  safestrcpy(p->name, last, sizeof(p->name));
    80005aca:	4641                	li	a2,16
    80005acc:	df843583          	ld	a1,-520(s0)
    80005ad0:	160a8513          	addi	a0,s5,352
    80005ad4:	ffffb097          	auipc	ra,0xffffb
    80005ad8:	626080e7          	jalr	1574(ra) # 800010fa <safestrcpy>
  oldpagetable = p->pagetable;
    80005adc:	058ab503          	ld	a0,88(s5)
  p->pagetable = pagetable;
    80005ae0:	057abc23          	sd	s7,88(s5)
  p->sz = sz;
    80005ae4:	056ab823          	sd	s6,80(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005ae8:	060ab783          	ld	a5,96(s5)
    80005aec:	e6843703          	ld	a4,-408(s0)
    80005af0:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    80005af2:	060ab783          	ld	a5,96(s5)
    80005af6:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005afa:	85ea                	mv	a1,s10
    80005afc:	ffffc097          	auipc	ra,0xffffc
    80005b00:	49a080e7          	jalr	1178(ra) # 80001f96 <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    80005b04:	0004851b          	sext.w	a0,s1
    80005b08:	bbd9                	j	800058de <exec+0x98>
    80005b0a:	e1443423          	sd	s4,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005b0e:	e0843583          	ld	a1,-504(s0)
    80005b12:	855e                	mv	a0,s7
    80005b14:	ffffc097          	auipc	ra,0xffffc
    80005b18:	482080e7          	jalr	1154(ra) # 80001f96 <proc_freepagetable>
  if(ip){
    80005b1c:	da0497e3          	bnez	s1,800058ca <exec+0x84>
  return -1;
    80005b20:	557d                	li	a0,-1
    80005b22:	bb75                	j	800058de <exec+0x98>
    80005b24:	e1443423          	sd	s4,-504(s0)
    80005b28:	b7dd                	j	80005b0e <exec+0x2c8>
    80005b2a:	e1443423          	sd	s4,-504(s0)
    80005b2e:	b7c5                	j	80005b0e <exec+0x2c8>
    80005b30:	e1443423          	sd	s4,-504(s0)
    80005b34:	bfe9                	j	80005b0e <exec+0x2c8>
    80005b36:	e1443423          	sd	s4,-504(s0)
    80005b3a:	bfd1                	j	80005b0e <exec+0x2c8>
  sz = sz1;
    80005b3c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005b40:	4481                	li	s1,0
    80005b42:	b7f1                	j	80005b0e <exec+0x2c8>
  sz = sz1;
    80005b44:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005b48:	4481                	li	s1,0
    80005b4a:	b7d1                	j	80005b0e <exec+0x2c8>
  sz = sz1;
    80005b4c:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005b50:	4481                	li	s1,0
    80005b52:	bf75                	j	80005b0e <exec+0x2c8>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005b54:	e0843a03          	ld	s4,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005b58:	2b05                	addiw	s6,s6,1
    80005b5a:	0389899b          	addiw	s3,s3,56
    80005b5e:	e8845783          	lhu	a5,-376(s0)
    80005b62:	e2fb57e3          	bge	s6,a5,80005990 <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    80005b66:	2981                	sext.w	s3,s3
    80005b68:	03800713          	li	a4,56
    80005b6c:	86ce                	mv	a3,s3
    80005b6e:	e1840613          	addi	a2,s0,-488
    80005b72:	4581                	li	a1,0
    80005b74:	8526                	mv	a0,s1
    80005b76:	fffff097          	auipc	ra,0xfffff
    80005b7a:	a6e080e7          	jalr	-1426(ra) # 800045e4 <readi>
    80005b7e:	03800793          	li	a5,56
    80005b82:	f8f514e3          	bne	a0,a5,80005b0a <exec+0x2c4>
    if(ph.type != ELF_PROG_LOAD)
    80005b86:	e1842783          	lw	a5,-488(s0)
    80005b8a:	4705                	li	a4,1
    80005b8c:	fce796e3          	bne	a5,a4,80005b58 <exec+0x312>
    if(ph.memsz < ph.filesz)
    80005b90:	e4043903          	ld	s2,-448(s0)
    80005b94:	e3843783          	ld	a5,-456(s0)
    80005b98:	f8f966e3          	bltu	s2,a5,80005b24 <exec+0x2de>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    80005b9c:	e2843783          	ld	a5,-472(s0)
    80005ba0:	993e                	add	s2,s2,a5
    80005ba2:	f8f964e3          	bltu	s2,a5,80005b2a <exec+0x2e4>
    if(ph.vaddr % PGSIZE != 0)
    80005ba6:	df043703          	ld	a4,-528(s0)
    80005baa:	8ff9                	and	a5,a5,a4
    80005bac:	f3d1                	bnez	a5,80005b30 <exec+0x2ea>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz, flags2perm(ph.flags))) == 0)
    80005bae:	e1c42503          	lw	a0,-484(s0)
    80005bb2:	00000097          	auipc	ra,0x0
    80005bb6:	c78080e7          	jalr	-904(ra) # 8000582a <flags2perm>
    80005bba:	86aa                	mv	a3,a0
    80005bbc:	864a                	mv	a2,s2
    80005bbe:	85d2                	mv	a1,s4
    80005bc0:	855e                	mv	a0,s7
    80005bc2:	ffffc097          	auipc	ra,0xffffc
    80005bc6:	b2c080e7          	jalr	-1236(ra) # 800016ee <uvmalloc>
    80005bca:	e0a43423          	sd	a0,-504(s0)
    80005bce:	d525                	beqz	a0,80005b36 <exec+0x2f0>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    80005bd0:	e2843d03          	ld	s10,-472(s0)
    80005bd4:	e2042d83          	lw	s11,-480(s0)
    80005bd8:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005bdc:	f60c0ce3          	beqz	s8,80005b54 <exec+0x30e>
    80005be0:	8a62                	mv	s4,s8
    80005be2:	4901                	li	s2,0
    80005be4:	b369                	j	8000596e <exec+0x128>

0000000080005be6 <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    80005be6:	7179                	addi	sp,sp,-48
    80005be8:	f406                	sd	ra,40(sp)
    80005bea:	f022                	sd	s0,32(sp)
    80005bec:	ec26                	sd	s1,24(sp)
    80005bee:	e84a                	sd	s2,16(sp)
    80005bf0:	1800                	addi	s0,sp,48
    80005bf2:	892e                	mv	s2,a1
    80005bf4:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  argint(n, &fd);
    80005bf6:	fdc40593          	addi	a1,s0,-36
    80005bfa:	ffffd097          	auipc	ra,0xffffd
    80005bfe:	79a080e7          	jalr	1946(ra) # 80003394 <argint>
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    80005c02:	fdc42703          	lw	a4,-36(s0)
    80005c06:	47bd                	li	a5,15
    80005c08:	02e7eb63          	bltu	a5,a4,80005c3e <argfd+0x58>
    80005c0c:	ffffc097          	auipc	ra,0xffffc
    80005c10:	0ee080e7          	jalr	238(ra) # 80001cfa <myproc>
    80005c14:	fdc42703          	lw	a4,-36(s0)
    80005c18:	01a70793          	addi	a5,a4,26
    80005c1c:	078e                	slli	a5,a5,0x3
    80005c1e:	953e                	add	a0,a0,a5
    80005c20:	651c                	ld	a5,8(a0)
    80005c22:	c385                	beqz	a5,80005c42 <argfd+0x5c>
    return -1;
  if(pfd)
    80005c24:	00090463          	beqz	s2,80005c2c <argfd+0x46>
    *pfd = fd;
    80005c28:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005c2c:	4501                	li	a0,0
  if(pf)
    80005c2e:	c091                	beqz	s1,80005c32 <argfd+0x4c>
    *pf = f;
    80005c30:	e09c                	sd	a5,0(s1)
}
    80005c32:	70a2                	ld	ra,40(sp)
    80005c34:	7402                	ld	s0,32(sp)
    80005c36:	64e2                	ld	s1,24(sp)
    80005c38:	6942                	ld	s2,16(sp)
    80005c3a:	6145                	addi	sp,sp,48
    80005c3c:	8082                	ret
    return -1;
    80005c3e:	557d                	li	a0,-1
    80005c40:	bfcd                	j	80005c32 <argfd+0x4c>
    80005c42:	557d                	li	a0,-1
    80005c44:	b7fd                	j	80005c32 <argfd+0x4c>

0000000080005c46 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005c46:	1101                	addi	sp,sp,-32
    80005c48:	ec06                	sd	ra,24(sp)
    80005c4a:	e822                	sd	s0,16(sp)
    80005c4c:	e426                	sd	s1,8(sp)
    80005c4e:	1000                	addi	s0,sp,32
    80005c50:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005c52:	ffffc097          	auipc	ra,0xffffc
    80005c56:	0a8080e7          	jalr	168(ra) # 80001cfa <myproc>
    80005c5a:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    80005c5c:	0d850793          	addi	a5,a0,216 # fffffffffffff0d8 <end+0xffffffff7fdbafc8>
    80005c60:	4501                	li	a0,0
    80005c62:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005c64:	6398                	ld	a4,0(a5)
    80005c66:	cb19                	beqz	a4,80005c7c <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005c68:	2505                	addiw	a0,a0,1
    80005c6a:	07a1                	addi	a5,a5,8
    80005c6c:	fed51ce3          	bne	a0,a3,80005c64 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    80005c70:	557d                	li	a0,-1
}
    80005c72:	60e2                	ld	ra,24(sp)
    80005c74:	6442                	ld	s0,16(sp)
    80005c76:	64a2                	ld	s1,8(sp)
    80005c78:	6105                	addi	sp,sp,32
    80005c7a:	8082                	ret
      p->ofile[fd] = f;
    80005c7c:	01a50793          	addi	a5,a0,26
    80005c80:	078e                	slli	a5,a5,0x3
    80005c82:	963e                	add	a2,a2,a5
    80005c84:	e604                	sd	s1,8(a2)
      return fd;
    80005c86:	b7f5                	j	80005c72 <fdalloc+0x2c>

0000000080005c88 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    80005c88:	715d                	addi	sp,sp,-80
    80005c8a:	e486                	sd	ra,72(sp)
    80005c8c:	e0a2                	sd	s0,64(sp)
    80005c8e:	fc26                	sd	s1,56(sp)
    80005c90:	f84a                	sd	s2,48(sp)
    80005c92:	f44e                	sd	s3,40(sp)
    80005c94:	f052                	sd	s4,32(sp)
    80005c96:	ec56                	sd	s5,24(sp)
    80005c98:	e85a                	sd	s6,16(sp)
    80005c9a:	0880                	addi	s0,sp,80
    80005c9c:	8b2e                	mv	s6,a1
    80005c9e:	89b2                	mv	s3,a2
    80005ca0:	8936                	mv	s2,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    80005ca2:	fb040593          	addi	a1,s0,-80
    80005ca6:	fffff097          	auipc	ra,0xfffff
    80005caa:	e4e080e7          	jalr	-434(ra) # 80004af4 <nameiparent>
    80005cae:	84aa                	mv	s1,a0
    80005cb0:	16050063          	beqz	a0,80005e10 <create+0x188>
    return 0;

  ilock(dp);
    80005cb4:	ffffe097          	auipc	ra,0xffffe
    80005cb8:	67c080e7          	jalr	1660(ra) # 80004330 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    80005cbc:	4601                	li	a2,0
    80005cbe:	fb040593          	addi	a1,s0,-80
    80005cc2:	8526                	mv	a0,s1
    80005cc4:	fffff097          	auipc	ra,0xfffff
    80005cc8:	b50080e7          	jalr	-1200(ra) # 80004814 <dirlookup>
    80005ccc:	8aaa                	mv	s5,a0
    80005cce:	c931                	beqz	a0,80005d22 <create+0x9a>
    iunlockput(dp);
    80005cd0:	8526                	mv	a0,s1
    80005cd2:	fffff097          	auipc	ra,0xfffff
    80005cd6:	8c0080e7          	jalr	-1856(ra) # 80004592 <iunlockput>
    ilock(ip);
    80005cda:	8556                	mv	a0,s5
    80005cdc:	ffffe097          	auipc	ra,0xffffe
    80005ce0:	654080e7          	jalr	1620(ra) # 80004330 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005ce4:	000b059b          	sext.w	a1,s6
    80005ce8:	4789                	li	a5,2
    80005cea:	02f59563          	bne	a1,a5,80005d14 <create+0x8c>
    80005cee:	044ad783          	lhu	a5,68(s5)
    80005cf2:	37f9                	addiw	a5,a5,-2
    80005cf4:	17c2                	slli	a5,a5,0x30
    80005cf6:	93c1                	srli	a5,a5,0x30
    80005cf8:	4705                	li	a4,1
    80005cfa:	00f76d63          	bltu	a4,a5,80005d14 <create+0x8c>
  ip->nlink = 0;
  iupdate(ip);
  iunlockput(ip);
  iunlockput(dp);
  return 0;
}
    80005cfe:	8556                	mv	a0,s5
    80005d00:	60a6                	ld	ra,72(sp)
    80005d02:	6406                	ld	s0,64(sp)
    80005d04:	74e2                	ld	s1,56(sp)
    80005d06:	7942                	ld	s2,48(sp)
    80005d08:	79a2                	ld	s3,40(sp)
    80005d0a:	7a02                	ld	s4,32(sp)
    80005d0c:	6ae2                	ld	s5,24(sp)
    80005d0e:	6b42                	ld	s6,16(sp)
    80005d10:	6161                	addi	sp,sp,80
    80005d12:	8082                	ret
    iunlockput(ip);
    80005d14:	8556                	mv	a0,s5
    80005d16:	fffff097          	auipc	ra,0xfffff
    80005d1a:	87c080e7          	jalr	-1924(ra) # 80004592 <iunlockput>
    return 0;
    80005d1e:	4a81                	li	s5,0
    80005d20:	bff9                	j	80005cfe <create+0x76>
  if((ip = ialloc(dp->dev, type)) == 0){
    80005d22:	85da                	mv	a1,s6
    80005d24:	4088                	lw	a0,0(s1)
    80005d26:	ffffe097          	auipc	ra,0xffffe
    80005d2a:	46e080e7          	jalr	1134(ra) # 80004194 <ialloc>
    80005d2e:	8a2a                	mv	s4,a0
    80005d30:	c921                	beqz	a0,80005d80 <create+0xf8>
  ilock(ip);
    80005d32:	ffffe097          	auipc	ra,0xffffe
    80005d36:	5fe080e7          	jalr	1534(ra) # 80004330 <ilock>
  ip->major = major;
    80005d3a:	053a1323          	sh	s3,70(s4)
  ip->minor = minor;
    80005d3e:	052a1423          	sh	s2,72(s4)
  ip->nlink = 1;
    80005d42:	4785                	li	a5,1
    80005d44:	04fa1523          	sh	a5,74(s4)
  iupdate(ip);
    80005d48:	8552                	mv	a0,s4
    80005d4a:	ffffe097          	auipc	ra,0xffffe
    80005d4e:	51c080e7          	jalr	1308(ra) # 80004266 <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    80005d52:	000b059b          	sext.w	a1,s6
    80005d56:	4785                	li	a5,1
    80005d58:	02f58b63          	beq	a1,a5,80005d8e <create+0x106>
  if(dirlink(dp, name, ip->inum) < 0)
    80005d5c:	004a2603          	lw	a2,4(s4)
    80005d60:	fb040593          	addi	a1,s0,-80
    80005d64:	8526                	mv	a0,s1
    80005d66:	fffff097          	auipc	ra,0xfffff
    80005d6a:	cbe080e7          	jalr	-834(ra) # 80004a24 <dirlink>
    80005d6e:	06054f63          	bltz	a0,80005dec <create+0x164>
  iunlockput(dp);
    80005d72:	8526                	mv	a0,s1
    80005d74:	fffff097          	auipc	ra,0xfffff
    80005d78:	81e080e7          	jalr	-2018(ra) # 80004592 <iunlockput>
  return ip;
    80005d7c:	8ad2                	mv	s5,s4
    80005d7e:	b741                	j	80005cfe <create+0x76>
    iunlockput(dp);
    80005d80:	8526                	mv	a0,s1
    80005d82:	fffff097          	auipc	ra,0xfffff
    80005d86:	810080e7          	jalr	-2032(ra) # 80004592 <iunlockput>
    return 0;
    80005d8a:	8ad2                	mv	s5,s4
    80005d8c:	bf8d                	j	80005cfe <create+0x76>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    80005d8e:	004a2603          	lw	a2,4(s4)
    80005d92:	00003597          	auipc	a1,0x3
    80005d96:	b5658593          	addi	a1,a1,-1194 # 800088e8 <syscalls+0x2c0>
    80005d9a:	8552                	mv	a0,s4
    80005d9c:	fffff097          	auipc	ra,0xfffff
    80005da0:	c88080e7          	jalr	-888(ra) # 80004a24 <dirlink>
    80005da4:	04054463          	bltz	a0,80005dec <create+0x164>
    80005da8:	40d0                	lw	a2,4(s1)
    80005daa:	00003597          	auipc	a1,0x3
    80005dae:	b4658593          	addi	a1,a1,-1210 # 800088f0 <syscalls+0x2c8>
    80005db2:	8552                	mv	a0,s4
    80005db4:	fffff097          	auipc	ra,0xfffff
    80005db8:	c70080e7          	jalr	-912(ra) # 80004a24 <dirlink>
    80005dbc:	02054863          	bltz	a0,80005dec <create+0x164>
  if(dirlink(dp, name, ip->inum) < 0)
    80005dc0:	004a2603          	lw	a2,4(s4)
    80005dc4:	fb040593          	addi	a1,s0,-80
    80005dc8:	8526                	mv	a0,s1
    80005dca:	fffff097          	auipc	ra,0xfffff
    80005dce:	c5a080e7          	jalr	-934(ra) # 80004a24 <dirlink>
    80005dd2:	00054d63          	bltz	a0,80005dec <create+0x164>
    dp->nlink++;  // for ".."
    80005dd6:	04a4d783          	lhu	a5,74(s1)
    80005dda:	2785                	addiw	a5,a5,1
    80005ddc:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005de0:	8526                	mv	a0,s1
    80005de2:	ffffe097          	auipc	ra,0xffffe
    80005de6:	484080e7          	jalr	1156(ra) # 80004266 <iupdate>
    80005dea:	b761                	j	80005d72 <create+0xea>
  ip->nlink = 0;
    80005dec:	040a1523          	sh	zero,74(s4)
  iupdate(ip);
    80005df0:	8552                	mv	a0,s4
    80005df2:	ffffe097          	auipc	ra,0xffffe
    80005df6:	474080e7          	jalr	1140(ra) # 80004266 <iupdate>
  iunlockput(ip);
    80005dfa:	8552                	mv	a0,s4
    80005dfc:	ffffe097          	auipc	ra,0xffffe
    80005e00:	796080e7          	jalr	1942(ra) # 80004592 <iunlockput>
  iunlockput(dp);
    80005e04:	8526                	mv	a0,s1
    80005e06:	ffffe097          	auipc	ra,0xffffe
    80005e0a:	78c080e7          	jalr	1932(ra) # 80004592 <iunlockput>
  return 0;
    80005e0e:	bdc5                	j	80005cfe <create+0x76>
    return 0;
    80005e10:	8aaa                	mv	s5,a0
    80005e12:	b5f5                	j	80005cfe <create+0x76>

0000000080005e14 <sys_dup>:
{
    80005e14:	7179                	addi	sp,sp,-48
    80005e16:	f406                	sd	ra,40(sp)
    80005e18:	f022                	sd	s0,32(sp)
    80005e1a:	ec26                	sd	s1,24(sp)
    80005e1c:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005e1e:	fd840613          	addi	a2,s0,-40
    80005e22:	4581                	li	a1,0
    80005e24:	4501                	li	a0,0
    80005e26:	00000097          	auipc	ra,0x0
    80005e2a:	dc0080e7          	jalr	-576(ra) # 80005be6 <argfd>
    return -1;
    80005e2e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    80005e30:	02054363          	bltz	a0,80005e56 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    80005e34:	fd843503          	ld	a0,-40(s0)
    80005e38:	00000097          	auipc	ra,0x0
    80005e3c:	e0e080e7          	jalr	-498(ra) # 80005c46 <fdalloc>
    80005e40:	84aa                	mv	s1,a0
    return -1;
    80005e42:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    80005e44:	00054963          	bltz	a0,80005e56 <sys_dup+0x42>
  filedup(f);
    80005e48:	fd843503          	ld	a0,-40(s0)
    80005e4c:	fffff097          	auipc	ra,0xfffff
    80005e50:	320080e7          	jalr	800(ra) # 8000516c <filedup>
  return fd;
    80005e54:	87a6                	mv	a5,s1
}
    80005e56:	853e                	mv	a0,a5
    80005e58:	70a2                	ld	ra,40(sp)
    80005e5a:	7402                	ld	s0,32(sp)
    80005e5c:	64e2                	ld	s1,24(sp)
    80005e5e:	6145                	addi	sp,sp,48
    80005e60:	8082                	ret

0000000080005e62 <sys_read>:
{
    80005e62:	7179                	addi	sp,sp,-48
    80005e64:	f406                	sd	ra,40(sp)
    80005e66:	f022                	sd	s0,32(sp)
    80005e68:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005e6a:	fd840593          	addi	a1,s0,-40
    80005e6e:	4505                	li	a0,1
    80005e70:	ffffd097          	auipc	ra,0xffffd
    80005e74:	544080e7          	jalr	1348(ra) # 800033b4 <argaddr>
  argint(2, &n);
    80005e78:	fe440593          	addi	a1,s0,-28
    80005e7c:	4509                	li	a0,2
    80005e7e:	ffffd097          	auipc	ra,0xffffd
    80005e82:	516080e7          	jalr	1302(ra) # 80003394 <argint>
  if(argfd(0, 0, &f) < 0)
    80005e86:	fe840613          	addi	a2,s0,-24
    80005e8a:	4581                	li	a1,0
    80005e8c:	4501                	li	a0,0
    80005e8e:	00000097          	auipc	ra,0x0
    80005e92:	d58080e7          	jalr	-680(ra) # 80005be6 <argfd>
    80005e96:	87aa                	mv	a5,a0
    return -1;
    80005e98:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005e9a:	0007cc63          	bltz	a5,80005eb2 <sys_read+0x50>
  return fileread(f, p, n);
    80005e9e:	fe442603          	lw	a2,-28(s0)
    80005ea2:	fd843583          	ld	a1,-40(s0)
    80005ea6:	fe843503          	ld	a0,-24(s0)
    80005eaa:	fffff097          	auipc	ra,0xfffff
    80005eae:	44e080e7          	jalr	1102(ra) # 800052f8 <fileread>
}
    80005eb2:	70a2                	ld	ra,40(sp)
    80005eb4:	7402                	ld	s0,32(sp)
    80005eb6:	6145                	addi	sp,sp,48
    80005eb8:	8082                	ret

0000000080005eba <sys_write>:
{
    80005eba:	7179                	addi	sp,sp,-48
    80005ebc:	f406                	sd	ra,40(sp)
    80005ebe:	f022                	sd	s0,32(sp)
    80005ec0:	1800                	addi	s0,sp,48
  argaddr(1, &p);
    80005ec2:	fd840593          	addi	a1,s0,-40
    80005ec6:	4505                	li	a0,1
    80005ec8:	ffffd097          	auipc	ra,0xffffd
    80005ecc:	4ec080e7          	jalr	1260(ra) # 800033b4 <argaddr>
  argint(2, &n);
    80005ed0:	fe440593          	addi	a1,s0,-28
    80005ed4:	4509                	li	a0,2
    80005ed6:	ffffd097          	auipc	ra,0xffffd
    80005eda:	4be080e7          	jalr	1214(ra) # 80003394 <argint>
  if(argfd(0, 0, &f) < 0)
    80005ede:	fe840613          	addi	a2,s0,-24
    80005ee2:	4581                	li	a1,0
    80005ee4:	4501                	li	a0,0
    80005ee6:	00000097          	auipc	ra,0x0
    80005eea:	d00080e7          	jalr	-768(ra) # 80005be6 <argfd>
    80005eee:	87aa                	mv	a5,a0
    return -1;
    80005ef0:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005ef2:	0007cc63          	bltz	a5,80005f0a <sys_write+0x50>
  return filewrite(f, p, n);
    80005ef6:	fe442603          	lw	a2,-28(s0)
    80005efa:	fd843583          	ld	a1,-40(s0)
    80005efe:	fe843503          	ld	a0,-24(s0)
    80005f02:	fffff097          	auipc	ra,0xfffff
    80005f06:	4b8080e7          	jalr	1208(ra) # 800053ba <filewrite>
}
    80005f0a:	70a2                	ld	ra,40(sp)
    80005f0c:	7402                	ld	s0,32(sp)
    80005f0e:	6145                	addi	sp,sp,48
    80005f10:	8082                	ret

0000000080005f12 <sys_close>:
{
    80005f12:	1101                	addi	sp,sp,-32
    80005f14:	ec06                	sd	ra,24(sp)
    80005f16:	e822                	sd	s0,16(sp)
    80005f18:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005f1a:	fe040613          	addi	a2,s0,-32
    80005f1e:	fec40593          	addi	a1,s0,-20
    80005f22:	4501                	li	a0,0
    80005f24:	00000097          	auipc	ra,0x0
    80005f28:	cc2080e7          	jalr	-830(ra) # 80005be6 <argfd>
    return -1;
    80005f2c:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005f2e:	02054463          	bltz	a0,80005f56 <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005f32:	ffffc097          	auipc	ra,0xffffc
    80005f36:	dc8080e7          	jalr	-568(ra) # 80001cfa <myproc>
    80005f3a:	fec42783          	lw	a5,-20(s0)
    80005f3e:	07e9                	addi	a5,a5,26
    80005f40:	078e                	slli	a5,a5,0x3
    80005f42:	97aa                	add	a5,a5,a0
    80005f44:	0007b423          	sd	zero,8(a5)
  fileclose(f);
    80005f48:	fe043503          	ld	a0,-32(s0)
    80005f4c:	fffff097          	auipc	ra,0xfffff
    80005f50:	272080e7          	jalr	626(ra) # 800051be <fileclose>
  return 0;
    80005f54:	4781                	li	a5,0
}
    80005f56:	853e                	mv	a0,a5
    80005f58:	60e2                	ld	ra,24(sp)
    80005f5a:	6442                	ld	s0,16(sp)
    80005f5c:	6105                	addi	sp,sp,32
    80005f5e:	8082                	ret

0000000080005f60 <sys_fstat>:
{
    80005f60:	1101                	addi	sp,sp,-32
    80005f62:	ec06                	sd	ra,24(sp)
    80005f64:	e822                	sd	s0,16(sp)
    80005f66:	1000                	addi	s0,sp,32
  argaddr(1, &st);
    80005f68:	fe040593          	addi	a1,s0,-32
    80005f6c:	4505                	li	a0,1
    80005f6e:	ffffd097          	auipc	ra,0xffffd
    80005f72:	446080e7          	jalr	1094(ra) # 800033b4 <argaddr>
  if(argfd(0, 0, &f) < 0)
    80005f76:	fe840613          	addi	a2,s0,-24
    80005f7a:	4581                	li	a1,0
    80005f7c:	4501                	li	a0,0
    80005f7e:	00000097          	auipc	ra,0x0
    80005f82:	c68080e7          	jalr	-920(ra) # 80005be6 <argfd>
    80005f86:	87aa                	mv	a5,a0
    return -1;
    80005f88:	557d                	li	a0,-1
  if(argfd(0, 0, &f) < 0)
    80005f8a:	0007ca63          	bltz	a5,80005f9e <sys_fstat+0x3e>
  return filestat(f, st);
    80005f8e:	fe043583          	ld	a1,-32(s0)
    80005f92:	fe843503          	ld	a0,-24(s0)
    80005f96:	fffff097          	auipc	ra,0xfffff
    80005f9a:	2f0080e7          	jalr	752(ra) # 80005286 <filestat>
}
    80005f9e:	60e2                	ld	ra,24(sp)
    80005fa0:	6442                	ld	s0,16(sp)
    80005fa2:	6105                	addi	sp,sp,32
    80005fa4:	8082                	ret

0000000080005fa6 <sys_link>:
{
    80005fa6:	7169                	addi	sp,sp,-304
    80005fa8:	f606                	sd	ra,296(sp)
    80005faa:	f222                	sd	s0,288(sp)
    80005fac:	ee26                	sd	s1,280(sp)
    80005fae:	ea4a                	sd	s2,272(sp)
    80005fb0:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005fb2:	08000613          	li	a2,128
    80005fb6:	ed040593          	addi	a1,s0,-304
    80005fba:	4501                	li	a0,0
    80005fbc:	ffffd097          	auipc	ra,0xffffd
    80005fc0:	418080e7          	jalr	1048(ra) # 800033d4 <argstr>
    return -1;
    80005fc4:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005fc6:	10054e63          	bltz	a0,800060e2 <sys_link+0x13c>
    80005fca:	08000613          	li	a2,128
    80005fce:	f5040593          	addi	a1,s0,-176
    80005fd2:	4505                	li	a0,1
    80005fd4:	ffffd097          	auipc	ra,0xffffd
    80005fd8:	400080e7          	jalr	1024(ra) # 800033d4 <argstr>
    return -1;
    80005fdc:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    80005fde:	10054263          	bltz	a0,800060e2 <sys_link+0x13c>
  begin_op();
    80005fe2:	fffff097          	auipc	ra,0xfffff
    80005fe6:	d10080e7          	jalr	-752(ra) # 80004cf2 <begin_op>
  if((ip = namei(old)) == 0){
    80005fea:	ed040513          	addi	a0,s0,-304
    80005fee:	fffff097          	auipc	ra,0xfffff
    80005ff2:	ae8080e7          	jalr	-1304(ra) # 80004ad6 <namei>
    80005ff6:	84aa                	mv	s1,a0
    80005ff8:	c551                	beqz	a0,80006084 <sys_link+0xde>
  ilock(ip);
    80005ffa:	ffffe097          	auipc	ra,0xffffe
    80005ffe:	336080e7          	jalr	822(ra) # 80004330 <ilock>
  if(ip->type == T_DIR){
    80006002:	04449703          	lh	a4,68(s1)
    80006006:	4785                	li	a5,1
    80006008:	08f70463          	beq	a4,a5,80006090 <sys_link+0xea>
  ip->nlink++;
    8000600c:	04a4d783          	lhu	a5,74(s1)
    80006010:	2785                	addiw	a5,a5,1
    80006012:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80006016:	8526                	mv	a0,s1
    80006018:	ffffe097          	auipc	ra,0xffffe
    8000601c:	24e080e7          	jalr	590(ra) # 80004266 <iupdate>
  iunlock(ip);
    80006020:	8526                	mv	a0,s1
    80006022:	ffffe097          	auipc	ra,0xffffe
    80006026:	3d0080e7          	jalr	976(ra) # 800043f2 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    8000602a:	fd040593          	addi	a1,s0,-48
    8000602e:	f5040513          	addi	a0,s0,-176
    80006032:	fffff097          	auipc	ra,0xfffff
    80006036:	ac2080e7          	jalr	-1342(ra) # 80004af4 <nameiparent>
    8000603a:	892a                	mv	s2,a0
    8000603c:	c935                	beqz	a0,800060b0 <sys_link+0x10a>
  ilock(dp);
    8000603e:	ffffe097          	auipc	ra,0xffffe
    80006042:	2f2080e7          	jalr	754(ra) # 80004330 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80006046:	00092703          	lw	a4,0(s2)
    8000604a:	409c                	lw	a5,0(s1)
    8000604c:	04f71d63          	bne	a4,a5,800060a6 <sys_link+0x100>
    80006050:	40d0                	lw	a2,4(s1)
    80006052:	fd040593          	addi	a1,s0,-48
    80006056:	854a                	mv	a0,s2
    80006058:	fffff097          	auipc	ra,0xfffff
    8000605c:	9cc080e7          	jalr	-1588(ra) # 80004a24 <dirlink>
    80006060:	04054363          	bltz	a0,800060a6 <sys_link+0x100>
  iunlockput(dp);
    80006064:	854a                	mv	a0,s2
    80006066:	ffffe097          	auipc	ra,0xffffe
    8000606a:	52c080e7          	jalr	1324(ra) # 80004592 <iunlockput>
  iput(ip);
    8000606e:	8526                	mv	a0,s1
    80006070:	ffffe097          	auipc	ra,0xffffe
    80006074:	47a080e7          	jalr	1146(ra) # 800044ea <iput>
  end_op();
    80006078:	fffff097          	auipc	ra,0xfffff
    8000607c:	cfa080e7          	jalr	-774(ra) # 80004d72 <end_op>
  return 0;
    80006080:	4781                	li	a5,0
    80006082:	a085                	j	800060e2 <sys_link+0x13c>
    end_op();
    80006084:	fffff097          	auipc	ra,0xfffff
    80006088:	cee080e7          	jalr	-786(ra) # 80004d72 <end_op>
    return -1;
    8000608c:	57fd                	li	a5,-1
    8000608e:	a891                	j	800060e2 <sys_link+0x13c>
    iunlockput(ip);
    80006090:	8526                	mv	a0,s1
    80006092:	ffffe097          	auipc	ra,0xffffe
    80006096:	500080e7          	jalr	1280(ra) # 80004592 <iunlockput>
    end_op();
    8000609a:	fffff097          	auipc	ra,0xfffff
    8000609e:	cd8080e7          	jalr	-808(ra) # 80004d72 <end_op>
    return -1;
    800060a2:	57fd                	li	a5,-1
    800060a4:	a83d                	j	800060e2 <sys_link+0x13c>
    iunlockput(dp);
    800060a6:	854a                	mv	a0,s2
    800060a8:	ffffe097          	auipc	ra,0xffffe
    800060ac:	4ea080e7          	jalr	1258(ra) # 80004592 <iunlockput>
  ilock(ip);
    800060b0:	8526                	mv	a0,s1
    800060b2:	ffffe097          	auipc	ra,0xffffe
    800060b6:	27e080e7          	jalr	638(ra) # 80004330 <ilock>
  ip->nlink--;
    800060ba:	04a4d783          	lhu	a5,74(s1)
    800060be:	37fd                	addiw	a5,a5,-1
    800060c0:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800060c4:	8526                	mv	a0,s1
    800060c6:	ffffe097          	auipc	ra,0xffffe
    800060ca:	1a0080e7          	jalr	416(ra) # 80004266 <iupdate>
  iunlockput(ip);
    800060ce:	8526                	mv	a0,s1
    800060d0:	ffffe097          	auipc	ra,0xffffe
    800060d4:	4c2080e7          	jalr	1218(ra) # 80004592 <iunlockput>
  end_op();
    800060d8:	fffff097          	auipc	ra,0xfffff
    800060dc:	c9a080e7          	jalr	-870(ra) # 80004d72 <end_op>
  return -1;
    800060e0:	57fd                	li	a5,-1
}
    800060e2:	853e                	mv	a0,a5
    800060e4:	70b2                	ld	ra,296(sp)
    800060e6:	7412                	ld	s0,288(sp)
    800060e8:	64f2                	ld	s1,280(sp)
    800060ea:	6952                	ld	s2,272(sp)
    800060ec:	6155                	addi	sp,sp,304
    800060ee:	8082                	ret

00000000800060f0 <sys_unlink>:
{
    800060f0:	7151                	addi	sp,sp,-240
    800060f2:	f586                	sd	ra,232(sp)
    800060f4:	f1a2                	sd	s0,224(sp)
    800060f6:	eda6                	sd	s1,216(sp)
    800060f8:	e9ca                	sd	s2,208(sp)
    800060fa:	e5ce                	sd	s3,200(sp)
    800060fc:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    800060fe:	08000613          	li	a2,128
    80006102:	f3040593          	addi	a1,s0,-208
    80006106:	4501                	li	a0,0
    80006108:	ffffd097          	auipc	ra,0xffffd
    8000610c:	2cc080e7          	jalr	716(ra) # 800033d4 <argstr>
    80006110:	18054163          	bltz	a0,80006292 <sys_unlink+0x1a2>
  begin_op();
    80006114:	fffff097          	auipc	ra,0xfffff
    80006118:	bde080e7          	jalr	-1058(ra) # 80004cf2 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000611c:	fb040593          	addi	a1,s0,-80
    80006120:	f3040513          	addi	a0,s0,-208
    80006124:	fffff097          	auipc	ra,0xfffff
    80006128:	9d0080e7          	jalr	-1584(ra) # 80004af4 <nameiparent>
    8000612c:	84aa                	mv	s1,a0
    8000612e:	c979                	beqz	a0,80006204 <sys_unlink+0x114>
  ilock(dp);
    80006130:	ffffe097          	auipc	ra,0xffffe
    80006134:	200080e7          	jalr	512(ra) # 80004330 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80006138:	00002597          	auipc	a1,0x2
    8000613c:	7b058593          	addi	a1,a1,1968 # 800088e8 <syscalls+0x2c0>
    80006140:	fb040513          	addi	a0,s0,-80
    80006144:	ffffe097          	auipc	ra,0xffffe
    80006148:	6b6080e7          	jalr	1718(ra) # 800047fa <namecmp>
    8000614c:	14050a63          	beqz	a0,800062a0 <sys_unlink+0x1b0>
    80006150:	00002597          	auipc	a1,0x2
    80006154:	7a058593          	addi	a1,a1,1952 # 800088f0 <syscalls+0x2c8>
    80006158:	fb040513          	addi	a0,s0,-80
    8000615c:	ffffe097          	auipc	ra,0xffffe
    80006160:	69e080e7          	jalr	1694(ra) # 800047fa <namecmp>
    80006164:	12050e63          	beqz	a0,800062a0 <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80006168:	f2c40613          	addi	a2,s0,-212
    8000616c:	fb040593          	addi	a1,s0,-80
    80006170:	8526                	mv	a0,s1
    80006172:	ffffe097          	auipc	ra,0xffffe
    80006176:	6a2080e7          	jalr	1698(ra) # 80004814 <dirlookup>
    8000617a:	892a                	mv	s2,a0
    8000617c:	12050263          	beqz	a0,800062a0 <sys_unlink+0x1b0>
  ilock(ip);
    80006180:	ffffe097          	auipc	ra,0xffffe
    80006184:	1b0080e7          	jalr	432(ra) # 80004330 <ilock>
  if(ip->nlink < 1)
    80006188:	04a91783          	lh	a5,74(s2)
    8000618c:	08f05263          	blez	a5,80006210 <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    80006190:	04491703          	lh	a4,68(s2)
    80006194:	4785                	li	a5,1
    80006196:	08f70563          	beq	a4,a5,80006220 <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    8000619a:	4641                	li	a2,16
    8000619c:	4581                	li	a1,0
    8000619e:	fc040513          	addi	a0,s0,-64
    800061a2:	ffffb097          	auipc	ra,0xffffb
    800061a6:	e06080e7          	jalr	-506(ra) # 80000fa8 <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800061aa:	4741                	li	a4,16
    800061ac:	f2c42683          	lw	a3,-212(s0)
    800061b0:	fc040613          	addi	a2,s0,-64
    800061b4:	4581                	li	a1,0
    800061b6:	8526                	mv	a0,s1
    800061b8:	ffffe097          	auipc	ra,0xffffe
    800061bc:	524080e7          	jalr	1316(ra) # 800046dc <writei>
    800061c0:	47c1                	li	a5,16
    800061c2:	0af51563          	bne	a0,a5,8000626c <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800061c6:	04491703          	lh	a4,68(s2)
    800061ca:	4785                	li	a5,1
    800061cc:	0af70863          	beq	a4,a5,8000627c <sys_unlink+0x18c>
  iunlockput(dp);
    800061d0:	8526                	mv	a0,s1
    800061d2:	ffffe097          	auipc	ra,0xffffe
    800061d6:	3c0080e7          	jalr	960(ra) # 80004592 <iunlockput>
  ip->nlink--;
    800061da:	04a95783          	lhu	a5,74(s2)
    800061de:	37fd                	addiw	a5,a5,-1
    800061e0:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    800061e4:	854a                	mv	a0,s2
    800061e6:	ffffe097          	auipc	ra,0xffffe
    800061ea:	080080e7          	jalr	128(ra) # 80004266 <iupdate>
  iunlockput(ip);
    800061ee:	854a                	mv	a0,s2
    800061f0:	ffffe097          	auipc	ra,0xffffe
    800061f4:	3a2080e7          	jalr	930(ra) # 80004592 <iunlockput>
  end_op();
    800061f8:	fffff097          	auipc	ra,0xfffff
    800061fc:	b7a080e7          	jalr	-1158(ra) # 80004d72 <end_op>
  return 0;
    80006200:	4501                	li	a0,0
    80006202:	a84d                	j	800062b4 <sys_unlink+0x1c4>
    end_op();
    80006204:	fffff097          	auipc	ra,0xfffff
    80006208:	b6e080e7          	jalr	-1170(ra) # 80004d72 <end_op>
    return -1;
    8000620c:	557d                	li	a0,-1
    8000620e:	a05d                	j	800062b4 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80006210:	00002517          	auipc	a0,0x2
    80006214:	6e850513          	addi	a0,a0,1768 # 800088f8 <syscalls+0x2d0>
    80006218:	ffffa097          	auipc	ra,0xffffa
    8000621c:	32c080e7          	jalr	812(ra) # 80000544 <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80006220:	04c92703          	lw	a4,76(s2)
    80006224:	02000793          	li	a5,32
    80006228:	f6e7f9e3          	bgeu	a5,a4,8000619a <sys_unlink+0xaa>
    8000622c:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80006230:	4741                	li	a4,16
    80006232:	86ce                	mv	a3,s3
    80006234:	f1840613          	addi	a2,s0,-232
    80006238:	4581                	li	a1,0
    8000623a:	854a                	mv	a0,s2
    8000623c:	ffffe097          	auipc	ra,0xffffe
    80006240:	3a8080e7          	jalr	936(ra) # 800045e4 <readi>
    80006244:	47c1                	li	a5,16
    80006246:	00f51b63          	bne	a0,a5,8000625c <sys_unlink+0x16c>
    if(de.inum != 0)
    8000624a:	f1845783          	lhu	a5,-232(s0)
    8000624e:	e7a1                	bnez	a5,80006296 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80006250:	29c1                	addiw	s3,s3,16
    80006252:	04c92783          	lw	a5,76(s2)
    80006256:	fcf9ede3          	bltu	s3,a5,80006230 <sys_unlink+0x140>
    8000625a:	b781                	j	8000619a <sys_unlink+0xaa>
      panic("isdirempty: readi");
    8000625c:	00002517          	auipc	a0,0x2
    80006260:	6b450513          	addi	a0,a0,1716 # 80008910 <syscalls+0x2e8>
    80006264:	ffffa097          	auipc	ra,0xffffa
    80006268:	2e0080e7          	jalr	736(ra) # 80000544 <panic>
    panic("unlink: writei");
    8000626c:	00002517          	auipc	a0,0x2
    80006270:	6bc50513          	addi	a0,a0,1724 # 80008928 <syscalls+0x300>
    80006274:	ffffa097          	auipc	ra,0xffffa
    80006278:	2d0080e7          	jalr	720(ra) # 80000544 <panic>
    dp->nlink--;
    8000627c:	04a4d783          	lhu	a5,74(s1)
    80006280:	37fd                	addiw	a5,a5,-1
    80006282:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80006286:	8526                	mv	a0,s1
    80006288:	ffffe097          	auipc	ra,0xffffe
    8000628c:	fde080e7          	jalr	-34(ra) # 80004266 <iupdate>
    80006290:	b781                	j	800061d0 <sys_unlink+0xe0>
    return -1;
    80006292:	557d                	li	a0,-1
    80006294:	a005                	j	800062b4 <sys_unlink+0x1c4>
    iunlockput(ip);
    80006296:	854a                	mv	a0,s2
    80006298:	ffffe097          	auipc	ra,0xffffe
    8000629c:	2fa080e7          	jalr	762(ra) # 80004592 <iunlockput>
  iunlockput(dp);
    800062a0:	8526                	mv	a0,s1
    800062a2:	ffffe097          	auipc	ra,0xffffe
    800062a6:	2f0080e7          	jalr	752(ra) # 80004592 <iunlockput>
  end_op();
    800062aa:	fffff097          	auipc	ra,0xfffff
    800062ae:	ac8080e7          	jalr	-1336(ra) # 80004d72 <end_op>
  return -1;
    800062b2:	557d                	li	a0,-1
}
    800062b4:	70ae                	ld	ra,232(sp)
    800062b6:	740e                	ld	s0,224(sp)
    800062b8:	64ee                	ld	s1,216(sp)
    800062ba:	694e                	ld	s2,208(sp)
    800062bc:	69ae                	ld	s3,200(sp)
    800062be:	616d                	addi	sp,sp,240
    800062c0:	8082                	ret

00000000800062c2 <sys_open>:

uint64
sys_open(void)
{
    800062c2:	7131                	addi	sp,sp,-192
    800062c4:	fd06                	sd	ra,184(sp)
    800062c6:	f922                	sd	s0,176(sp)
    800062c8:	f526                	sd	s1,168(sp)
    800062ca:	f14a                	sd	s2,160(sp)
    800062cc:	ed4e                	sd	s3,152(sp)
    800062ce:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  argint(1, &omode);
    800062d0:	f4c40593          	addi	a1,s0,-180
    800062d4:	4505                	li	a0,1
    800062d6:	ffffd097          	auipc	ra,0xffffd
    800062da:	0be080e7          	jalr	190(ra) # 80003394 <argint>
  if((n = argstr(0, path, MAXPATH)) < 0)
    800062de:	08000613          	li	a2,128
    800062e2:	f5040593          	addi	a1,s0,-176
    800062e6:	4501                	li	a0,0
    800062e8:	ffffd097          	auipc	ra,0xffffd
    800062ec:	0ec080e7          	jalr	236(ra) # 800033d4 <argstr>
    800062f0:	87aa                	mv	a5,a0
    return -1;
    800062f2:	557d                	li	a0,-1
  if((n = argstr(0, path, MAXPATH)) < 0)
    800062f4:	0a07c963          	bltz	a5,800063a6 <sys_open+0xe4>

  begin_op();
    800062f8:	fffff097          	auipc	ra,0xfffff
    800062fc:	9fa080e7          	jalr	-1542(ra) # 80004cf2 <begin_op>

  if(omode & O_CREATE){
    80006300:	f4c42783          	lw	a5,-180(s0)
    80006304:	2007f793          	andi	a5,a5,512
    80006308:	cfc5                	beqz	a5,800063c0 <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    8000630a:	4681                	li	a3,0
    8000630c:	4601                	li	a2,0
    8000630e:	4589                	li	a1,2
    80006310:	f5040513          	addi	a0,s0,-176
    80006314:	00000097          	auipc	ra,0x0
    80006318:	974080e7          	jalr	-1676(ra) # 80005c88 <create>
    8000631c:	84aa                	mv	s1,a0
    if(ip == 0){
    8000631e:	c959                	beqz	a0,800063b4 <sys_open+0xf2>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80006320:	04449703          	lh	a4,68(s1)
    80006324:	478d                	li	a5,3
    80006326:	00f71763          	bne	a4,a5,80006334 <sys_open+0x72>
    8000632a:	0464d703          	lhu	a4,70(s1)
    8000632e:	47a5                	li	a5,9
    80006330:	0ce7ed63          	bltu	a5,a4,8000640a <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80006334:	fffff097          	auipc	ra,0xfffff
    80006338:	dce080e7          	jalr	-562(ra) # 80005102 <filealloc>
    8000633c:	89aa                	mv	s3,a0
    8000633e:	10050363          	beqz	a0,80006444 <sys_open+0x182>
    80006342:	00000097          	auipc	ra,0x0
    80006346:	904080e7          	jalr	-1788(ra) # 80005c46 <fdalloc>
    8000634a:	892a                	mv	s2,a0
    8000634c:	0e054763          	bltz	a0,8000643a <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80006350:	04449703          	lh	a4,68(s1)
    80006354:	478d                	li	a5,3
    80006356:	0cf70563          	beq	a4,a5,80006420 <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    8000635a:	4789                	li	a5,2
    8000635c:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80006360:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80006364:	0099bc23          	sd	s1,24(s3)
  f->readable = !(omode & O_WRONLY);
    80006368:	f4c42783          	lw	a5,-180(s0)
    8000636c:	0017c713          	xori	a4,a5,1
    80006370:	8b05                	andi	a4,a4,1
    80006372:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80006376:	0037f713          	andi	a4,a5,3
    8000637a:	00e03733          	snez	a4,a4
    8000637e:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80006382:	4007f793          	andi	a5,a5,1024
    80006386:	c791                	beqz	a5,80006392 <sys_open+0xd0>
    80006388:	04449703          	lh	a4,68(s1)
    8000638c:	4789                	li	a5,2
    8000638e:	0af70063          	beq	a4,a5,8000642e <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80006392:	8526                	mv	a0,s1
    80006394:	ffffe097          	auipc	ra,0xffffe
    80006398:	05e080e7          	jalr	94(ra) # 800043f2 <iunlock>
  end_op();
    8000639c:	fffff097          	auipc	ra,0xfffff
    800063a0:	9d6080e7          	jalr	-1578(ra) # 80004d72 <end_op>

  return fd;
    800063a4:	854a                	mv	a0,s2
}
    800063a6:	70ea                	ld	ra,184(sp)
    800063a8:	744a                	ld	s0,176(sp)
    800063aa:	74aa                	ld	s1,168(sp)
    800063ac:	790a                	ld	s2,160(sp)
    800063ae:	69ea                	ld	s3,152(sp)
    800063b0:	6129                	addi	sp,sp,192
    800063b2:	8082                	ret
      end_op();
    800063b4:	fffff097          	auipc	ra,0xfffff
    800063b8:	9be080e7          	jalr	-1602(ra) # 80004d72 <end_op>
      return -1;
    800063bc:	557d                	li	a0,-1
    800063be:	b7e5                	j	800063a6 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    800063c0:	f5040513          	addi	a0,s0,-176
    800063c4:	ffffe097          	auipc	ra,0xffffe
    800063c8:	712080e7          	jalr	1810(ra) # 80004ad6 <namei>
    800063cc:	84aa                	mv	s1,a0
    800063ce:	c905                	beqz	a0,800063fe <sys_open+0x13c>
    ilock(ip);
    800063d0:	ffffe097          	auipc	ra,0xffffe
    800063d4:	f60080e7          	jalr	-160(ra) # 80004330 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    800063d8:	04449703          	lh	a4,68(s1)
    800063dc:	4785                	li	a5,1
    800063de:	f4f711e3          	bne	a4,a5,80006320 <sys_open+0x5e>
    800063e2:	f4c42783          	lw	a5,-180(s0)
    800063e6:	d7b9                	beqz	a5,80006334 <sys_open+0x72>
      iunlockput(ip);
    800063e8:	8526                	mv	a0,s1
    800063ea:	ffffe097          	auipc	ra,0xffffe
    800063ee:	1a8080e7          	jalr	424(ra) # 80004592 <iunlockput>
      end_op();
    800063f2:	fffff097          	auipc	ra,0xfffff
    800063f6:	980080e7          	jalr	-1664(ra) # 80004d72 <end_op>
      return -1;
    800063fa:	557d                	li	a0,-1
    800063fc:	b76d                	j	800063a6 <sys_open+0xe4>
      end_op();
    800063fe:	fffff097          	auipc	ra,0xfffff
    80006402:	974080e7          	jalr	-1676(ra) # 80004d72 <end_op>
      return -1;
    80006406:	557d                	li	a0,-1
    80006408:	bf79                	j	800063a6 <sys_open+0xe4>
    iunlockput(ip);
    8000640a:	8526                	mv	a0,s1
    8000640c:	ffffe097          	auipc	ra,0xffffe
    80006410:	186080e7          	jalr	390(ra) # 80004592 <iunlockput>
    end_op();
    80006414:	fffff097          	auipc	ra,0xfffff
    80006418:	95e080e7          	jalr	-1698(ra) # 80004d72 <end_op>
    return -1;
    8000641c:	557d                	li	a0,-1
    8000641e:	b761                	j	800063a6 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80006420:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80006424:	04649783          	lh	a5,70(s1)
    80006428:	02f99223          	sh	a5,36(s3)
    8000642c:	bf25                	j	80006364 <sys_open+0xa2>
    itrunc(ip);
    8000642e:	8526                	mv	a0,s1
    80006430:	ffffe097          	auipc	ra,0xffffe
    80006434:	00e080e7          	jalr	14(ra) # 8000443e <itrunc>
    80006438:	bfa9                	j	80006392 <sys_open+0xd0>
      fileclose(f);
    8000643a:	854e                	mv	a0,s3
    8000643c:	fffff097          	auipc	ra,0xfffff
    80006440:	d82080e7          	jalr	-638(ra) # 800051be <fileclose>
    iunlockput(ip);
    80006444:	8526                	mv	a0,s1
    80006446:	ffffe097          	auipc	ra,0xffffe
    8000644a:	14c080e7          	jalr	332(ra) # 80004592 <iunlockput>
    end_op();
    8000644e:	fffff097          	auipc	ra,0xfffff
    80006452:	924080e7          	jalr	-1756(ra) # 80004d72 <end_op>
    return -1;
    80006456:	557d                	li	a0,-1
    80006458:	b7b9                	j	800063a6 <sys_open+0xe4>

000000008000645a <sys_mkdir>:

uint64
sys_mkdir(void)
{
    8000645a:	7175                	addi	sp,sp,-144
    8000645c:	e506                	sd	ra,136(sp)
    8000645e:	e122                	sd	s0,128(sp)
    80006460:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80006462:	fffff097          	auipc	ra,0xfffff
    80006466:	890080e7          	jalr	-1904(ra) # 80004cf2 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    8000646a:	08000613          	li	a2,128
    8000646e:	f7040593          	addi	a1,s0,-144
    80006472:	4501                	li	a0,0
    80006474:	ffffd097          	auipc	ra,0xffffd
    80006478:	f60080e7          	jalr	-160(ra) # 800033d4 <argstr>
    8000647c:	02054963          	bltz	a0,800064ae <sys_mkdir+0x54>
    80006480:	4681                	li	a3,0
    80006482:	4601                	li	a2,0
    80006484:	4585                	li	a1,1
    80006486:	f7040513          	addi	a0,s0,-144
    8000648a:	fffff097          	auipc	ra,0xfffff
    8000648e:	7fe080e7          	jalr	2046(ra) # 80005c88 <create>
    80006492:	cd11                	beqz	a0,800064ae <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006494:	ffffe097          	auipc	ra,0xffffe
    80006498:	0fe080e7          	jalr	254(ra) # 80004592 <iunlockput>
  end_op();
    8000649c:	fffff097          	auipc	ra,0xfffff
    800064a0:	8d6080e7          	jalr	-1834(ra) # 80004d72 <end_op>
  return 0;
    800064a4:	4501                	li	a0,0
}
    800064a6:	60aa                	ld	ra,136(sp)
    800064a8:	640a                	ld	s0,128(sp)
    800064aa:	6149                	addi	sp,sp,144
    800064ac:	8082                	ret
    end_op();
    800064ae:	fffff097          	auipc	ra,0xfffff
    800064b2:	8c4080e7          	jalr	-1852(ra) # 80004d72 <end_op>
    return -1;
    800064b6:	557d                	li	a0,-1
    800064b8:	b7fd                	j	800064a6 <sys_mkdir+0x4c>

00000000800064ba <sys_mknod>:

uint64
sys_mknod(void)
{
    800064ba:	7135                	addi	sp,sp,-160
    800064bc:	ed06                	sd	ra,152(sp)
    800064be:	e922                	sd	s0,144(sp)
    800064c0:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    800064c2:	fffff097          	auipc	ra,0xfffff
    800064c6:	830080e7          	jalr	-2000(ra) # 80004cf2 <begin_op>
  argint(1, &major);
    800064ca:	f6c40593          	addi	a1,s0,-148
    800064ce:	4505                	li	a0,1
    800064d0:	ffffd097          	auipc	ra,0xffffd
    800064d4:	ec4080e7          	jalr	-316(ra) # 80003394 <argint>
  argint(2, &minor);
    800064d8:	f6840593          	addi	a1,s0,-152
    800064dc:	4509                	li	a0,2
    800064de:	ffffd097          	auipc	ra,0xffffd
    800064e2:	eb6080e7          	jalr	-330(ra) # 80003394 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    800064e6:	08000613          	li	a2,128
    800064ea:	f7040593          	addi	a1,s0,-144
    800064ee:	4501                	li	a0,0
    800064f0:	ffffd097          	auipc	ra,0xffffd
    800064f4:	ee4080e7          	jalr	-284(ra) # 800033d4 <argstr>
    800064f8:	02054b63          	bltz	a0,8000652e <sys_mknod+0x74>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    800064fc:	f6841683          	lh	a3,-152(s0)
    80006500:	f6c41603          	lh	a2,-148(s0)
    80006504:	458d                	li	a1,3
    80006506:	f7040513          	addi	a0,s0,-144
    8000650a:	fffff097          	auipc	ra,0xfffff
    8000650e:	77e080e7          	jalr	1918(ra) # 80005c88 <create>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80006512:	cd11                	beqz	a0,8000652e <sys_mknod+0x74>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80006514:	ffffe097          	auipc	ra,0xffffe
    80006518:	07e080e7          	jalr	126(ra) # 80004592 <iunlockput>
  end_op();
    8000651c:	fffff097          	auipc	ra,0xfffff
    80006520:	856080e7          	jalr	-1962(ra) # 80004d72 <end_op>
  return 0;
    80006524:	4501                	li	a0,0
}
    80006526:	60ea                	ld	ra,152(sp)
    80006528:	644a                	ld	s0,144(sp)
    8000652a:	610d                	addi	sp,sp,160
    8000652c:	8082                	ret
    end_op();
    8000652e:	fffff097          	auipc	ra,0xfffff
    80006532:	844080e7          	jalr	-1980(ra) # 80004d72 <end_op>
    return -1;
    80006536:	557d                	li	a0,-1
    80006538:	b7fd                	j	80006526 <sys_mknod+0x6c>

000000008000653a <sys_chdir>:

uint64
sys_chdir(void)
{
    8000653a:	7135                	addi	sp,sp,-160
    8000653c:	ed06                	sd	ra,152(sp)
    8000653e:	e922                	sd	s0,144(sp)
    80006540:	e526                	sd	s1,136(sp)
    80006542:	e14a                	sd	s2,128(sp)
    80006544:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80006546:	ffffb097          	auipc	ra,0xffffb
    8000654a:	7b4080e7          	jalr	1972(ra) # 80001cfa <myproc>
    8000654e:	892a                	mv	s2,a0
  
  begin_op();
    80006550:	ffffe097          	auipc	ra,0xffffe
    80006554:	7a2080e7          	jalr	1954(ra) # 80004cf2 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80006558:	08000613          	li	a2,128
    8000655c:	f6040593          	addi	a1,s0,-160
    80006560:	4501                	li	a0,0
    80006562:	ffffd097          	auipc	ra,0xffffd
    80006566:	e72080e7          	jalr	-398(ra) # 800033d4 <argstr>
    8000656a:	04054b63          	bltz	a0,800065c0 <sys_chdir+0x86>
    8000656e:	f6040513          	addi	a0,s0,-160
    80006572:	ffffe097          	auipc	ra,0xffffe
    80006576:	564080e7          	jalr	1380(ra) # 80004ad6 <namei>
    8000657a:	84aa                	mv	s1,a0
    8000657c:	c131                	beqz	a0,800065c0 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    8000657e:	ffffe097          	auipc	ra,0xffffe
    80006582:	db2080e7          	jalr	-590(ra) # 80004330 <ilock>
  if(ip->type != T_DIR){
    80006586:	04449703          	lh	a4,68(s1)
    8000658a:	4785                	li	a5,1
    8000658c:	04f71063          	bne	a4,a5,800065cc <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80006590:	8526                	mv	a0,s1
    80006592:	ffffe097          	auipc	ra,0xffffe
    80006596:	e60080e7          	jalr	-416(ra) # 800043f2 <iunlock>
  iput(p->cwd);
    8000659a:	15893503          	ld	a0,344(s2)
    8000659e:	ffffe097          	auipc	ra,0xffffe
    800065a2:	f4c080e7          	jalr	-180(ra) # 800044ea <iput>
  end_op();
    800065a6:	ffffe097          	auipc	ra,0xffffe
    800065aa:	7cc080e7          	jalr	1996(ra) # 80004d72 <end_op>
  p->cwd = ip;
    800065ae:	14993c23          	sd	s1,344(s2)
  return 0;
    800065b2:	4501                	li	a0,0
}
    800065b4:	60ea                	ld	ra,152(sp)
    800065b6:	644a                	ld	s0,144(sp)
    800065b8:	64aa                	ld	s1,136(sp)
    800065ba:	690a                	ld	s2,128(sp)
    800065bc:	610d                	addi	sp,sp,160
    800065be:	8082                	ret
    end_op();
    800065c0:	ffffe097          	auipc	ra,0xffffe
    800065c4:	7b2080e7          	jalr	1970(ra) # 80004d72 <end_op>
    return -1;
    800065c8:	557d                	li	a0,-1
    800065ca:	b7ed                	j	800065b4 <sys_chdir+0x7a>
    iunlockput(ip);
    800065cc:	8526                	mv	a0,s1
    800065ce:	ffffe097          	auipc	ra,0xffffe
    800065d2:	fc4080e7          	jalr	-60(ra) # 80004592 <iunlockput>
    end_op();
    800065d6:	ffffe097          	auipc	ra,0xffffe
    800065da:	79c080e7          	jalr	1948(ra) # 80004d72 <end_op>
    return -1;
    800065de:	557d                	li	a0,-1
    800065e0:	bfd1                	j	800065b4 <sys_chdir+0x7a>

00000000800065e2 <sys_exec>:

uint64
sys_exec(void)
{
    800065e2:	7145                	addi	sp,sp,-464
    800065e4:	e786                	sd	ra,456(sp)
    800065e6:	e3a2                	sd	s0,448(sp)
    800065e8:	ff26                	sd	s1,440(sp)
    800065ea:	fb4a                	sd	s2,432(sp)
    800065ec:	f74e                	sd	s3,424(sp)
    800065ee:	f352                	sd	s4,416(sp)
    800065f0:	ef56                	sd	s5,408(sp)
    800065f2:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  argaddr(1, &uargv);
    800065f4:	e3840593          	addi	a1,s0,-456
    800065f8:	4505                	li	a0,1
    800065fa:	ffffd097          	auipc	ra,0xffffd
    800065fe:	dba080e7          	jalr	-582(ra) # 800033b4 <argaddr>
  if(argstr(0, path, MAXPATH) < 0) {
    80006602:	08000613          	li	a2,128
    80006606:	f4040593          	addi	a1,s0,-192
    8000660a:	4501                	li	a0,0
    8000660c:	ffffd097          	auipc	ra,0xffffd
    80006610:	dc8080e7          	jalr	-568(ra) # 800033d4 <argstr>
    80006614:	87aa                	mv	a5,a0
    return -1;
    80006616:	557d                	li	a0,-1
  if(argstr(0, path, MAXPATH) < 0) {
    80006618:	0c07c263          	bltz	a5,800066dc <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    8000661c:	10000613          	li	a2,256
    80006620:	4581                	li	a1,0
    80006622:	e4040513          	addi	a0,s0,-448
    80006626:	ffffb097          	auipc	ra,0xffffb
    8000662a:	982080e7          	jalr	-1662(ra) # 80000fa8 <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    8000662e:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80006632:	89a6                	mv	s3,s1
    80006634:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80006636:	02000a13          	li	s4,32
    8000663a:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    8000663e:	00391513          	slli	a0,s2,0x3
    80006642:	e3040593          	addi	a1,s0,-464
    80006646:	e3843783          	ld	a5,-456(s0)
    8000664a:	953e                	add	a0,a0,a5
    8000664c:	ffffd097          	auipc	ra,0xffffd
    80006650:	caa080e7          	jalr	-854(ra) # 800032f6 <fetchaddr>
    80006654:	02054a63          	bltz	a0,80006688 <sys_exec+0xa6>
      goto bad;
    }
    if(uarg == 0){
    80006658:	e3043783          	ld	a5,-464(s0)
    8000665c:	c3b9                	beqz	a5,800066a2 <sys_exec+0xc0>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    8000665e:	ffffa097          	auipc	ra,0xffffa
    80006662:	696080e7          	jalr	1686(ra) # 80000cf4 <kalloc>
    80006666:	85aa                	mv	a1,a0
    80006668:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    8000666c:	cd11                	beqz	a0,80006688 <sys_exec+0xa6>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    8000666e:	6605                	lui	a2,0x1
    80006670:	e3043503          	ld	a0,-464(s0)
    80006674:	ffffd097          	auipc	ra,0xffffd
    80006678:	cd4080e7          	jalr	-812(ra) # 80003348 <fetchstr>
    8000667c:	00054663          	bltz	a0,80006688 <sys_exec+0xa6>
    if(i >= NELEM(argv)){
    80006680:	0905                	addi	s2,s2,1
    80006682:	09a1                	addi	s3,s3,8
    80006684:	fb491be3          	bne	s2,s4,8000663a <sys_exec+0x58>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006688:	10048913          	addi	s2,s1,256
    8000668c:	6088                	ld	a0,0(s1)
    8000668e:	c531                	beqz	a0,800066da <sys_exec+0xf8>
    kfree(argv[i]);
    80006690:	ffffa097          	auipc	ra,0xffffa
    80006694:	506080e7          	jalr	1286(ra) # 80000b96 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80006698:	04a1                	addi	s1,s1,8
    8000669a:	ff2499e3          	bne	s1,s2,8000668c <sys_exec+0xaa>
  return -1;
    8000669e:	557d                	li	a0,-1
    800066a0:	a835                	j	800066dc <sys_exec+0xfa>
      argv[i] = 0;
    800066a2:	0a8e                	slli	s5,s5,0x3
    800066a4:	fc040793          	addi	a5,s0,-64
    800066a8:	9abe                	add	s5,s5,a5
    800066aa:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    800066ae:	e4040593          	addi	a1,s0,-448
    800066b2:	f4040513          	addi	a0,s0,-192
    800066b6:	fffff097          	auipc	ra,0xfffff
    800066ba:	190080e7          	jalr	400(ra) # 80005846 <exec>
    800066be:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800066c0:	10048993          	addi	s3,s1,256
    800066c4:	6088                	ld	a0,0(s1)
    800066c6:	c901                	beqz	a0,800066d6 <sys_exec+0xf4>
    kfree(argv[i]);
    800066c8:	ffffa097          	auipc	ra,0xffffa
    800066cc:	4ce080e7          	jalr	1230(ra) # 80000b96 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    800066d0:	04a1                	addi	s1,s1,8
    800066d2:	ff3499e3          	bne	s1,s3,800066c4 <sys_exec+0xe2>
  return ret;
    800066d6:	854a                	mv	a0,s2
    800066d8:	a011                	j	800066dc <sys_exec+0xfa>
  return -1;
    800066da:	557d                	li	a0,-1
}
    800066dc:	60be                	ld	ra,456(sp)
    800066de:	641e                	ld	s0,448(sp)
    800066e0:	74fa                	ld	s1,440(sp)
    800066e2:	795a                	ld	s2,432(sp)
    800066e4:	79ba                	ld	s3,424(sp)
    800066e6:	7a1a                	ld	s4,416(sp)
    800066e8:	6afa                	ld	s5,408(sp)
    800066ea:	6179                	addi	sp,sp,464
    800066ec:	8082                	ret

00000000800066ee <sys_pipe>:

uint64
sys_pipe(void)
{
    800066ee:	7139                	addi	sp,sp,-64
    800066f0:	fc06                	sd	ra,56(sp)
    800066f2:	f822                	sd	s0,48(sp)
    800066f4:	f426                	sd	s1,40(sp)
    800066f6:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    800066f8:	ffffb097          	auipc	ra,0xffffb
    800066fc:	602080e7          	jalr	1538(ra) # 80001cfa <myproc>
    80006700:	84aa                	mv	s1,a0

  argaddr(0, &fdarray);
    80006702:	fd840593          	addi	a1,s0,-40
    80006706:	4501                	li	a0,0
    80006708:	ffffd097          	auipc	ra,0xffffd
    8000670c:	cac080e7          	jalr	-852(ra) # 800033b4 <argaddr>
  if(pipealloc(&rf, &wf) < 0)
    80006710:	fc840593          	addi	a1,s0,-56
    80006714:	fd040513          	addi	a0,s0,-48
    80006718:	fffff097          	auipc	ra,0xfffff
    8000671c:	dd6080e7          	jalr	-554(ra) # 800054ee <pipealloc>
    return -1;
    80006720:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80006722:	0c054463          	bltz	a0,800067ea <sys_pipe+0xfc>
  fd0 = -1;
    80006726:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    8000672a:	fd043503          	ld	a0,-48(s0)
    8000672e:	fffff097          	auipc	ra,0xfffff
    80006732:	518080e7          	jalr	1304(ra) # 80005c46 <fdalloc>
    80006736:	fca42223          	sw	a0,-60(s0)
    8000673a:	08054b63          	bltz	a0,800067d0 <sys_pipe+0xe2>
    8000673e:	fc843503          	ld	a0,-56(s0)
    80006742:	fffff097          	auipc	ra,0xfffff
    80006746:	504080e7          	jalr	1284(ra) # 80005c46 <fdalloc>
    8000674a:	fca42023          	sw	a0,-64(s0)
    8000674e:	06054863          	bltz	a0,800067be <sys_pipe+0xd0>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006752:	4691                	li	a3,4
    80006754:	fc440613          	addi	a2,s0,-60
    80006758:	fd843583          	ld	a1,-40(s0)
    8000675c:	6ca8                	ld	a0,88(s1)
    8000675e:	ffffb097          	auipc	ra,0xffffb
    80006762:	1ec080e7          	jalr	492(ra) # 8000194a <copyout>
    80006766:	02054063          	bltz	a0,80006786 <sys_pipe+0x98>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    8000676a:	4691                	li	a3,4
    8000676c:	fc040613          	addi	a2,s0,-64
    80006770:	fd843583          	ld	a1,-40(s0)
    80006774:	0591                	addi	a1,a1,4
    80006776:	6ca8                	ld	a0,88(s1)
    80006778:	ffffb097          	auipc	ra,0xffffb
    8000677c:	1d2080e7          	jalr	466(ra) # 8000194a <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80006780:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80006782:	06055463          	bgez	a0,800067ea <sys_pipe+0xfc>
    p->ofile[fd0] = 0;
    80006786:	fc442783          	lw	a5,-60(s0)
    8000678a:	07e9                	addi	a5,a5,26
    8000678c:	078e                	slli	a5,a5,0x3
    8000678e:	97a6                	add	a5,a5,s1
    80006790:	0007b423          	sd	zero,8(a5)
    p->ofile[fd1] = 0;
    80006794:	fc042503          	lw	a0,-64(s0)
    80006798:	0569                	addi	a0,a0,26
    8000679a:	050e                	slli	a0,a0,0x3
    8000679c:	94aa                	add	s1,s1,a0
    8000679e:	0004b423          	sd	zero,8(s1)
    fileclose(rf);
    800067a2:	fd043503          	ld	a0,-48(s0)
    800067a6:	fffff097          	auipc	ra,0xfffff
    800067aa:	a18080e7          	jalr	-1512(ra) # 800051be <fileclose>
    fileclose(wf);
    800067ae:	fc843503          	ld	a0,-56(s0)
    800067b2:	fffff097          	auipc	ra,0xfffff
    800067b6:	a0c080e7          	jalr	-1524(ra) # 800051be <fileclose>
    return -1;
    800067ba:	57fd                	li	a5,-1
    800067bc:	a03d                	j	800067ea <sys_pipe+0xfc>
    if(fd0 >= 0)
    800067be:	fc442783          	lw	a5,-60(s0)
    800067c2:	0007c763          	bltz	a5,800067d0 <sys_pipe+0xe2>
      p->ofile[fd0] = 0;
    800067c6:	07e9                	addi	a5,a5,26
    800067c8:	078e                	slli	a5,a5,0x3
    800067ca:	94be                	add	s1,s1,a5
    800067cc:	0004b423          	sd	zero,8(s1)
    fileclose(rf);
    800067d0:	fd043503          	ld	a0,-48(s0)
    800067d4:	fffff097          	auipc	ra,0xfffff
    800067d8:	9ea080e7          	jalr	-1558(ra) # 800051be <fileclose>
    fileclose(wf);
    800067dc:	fc843503          	ld	a0,-56(s0)
    800067e0:	fffff097          	auipc	ra,0xfffff
    800067e4:	9de080e7          	jalr	-1570(ra) # 800051be <fileclose>
    return -1;
    800067e8:	57fd                	li	a5,-1
}
    800067ea:	853e                	mv	a0,a5
    800067ec:	70e2                	ld	ra,56(sp)
    800067ee:	7442                	ld	s0,48(sp)
    800067f0:	74a2                	ld	s1,40(sp)
    800067f2:	6121                	addi	sp,sp,64
    800067f4:	8082                	ret
	...

0000000080006800 <kernelvec>:
    80006800:	7111                	addi	sp,sp,-256
    80006802:	e006                	sd	ra,0(sp)
    80006804:	e40a                	sd	sp,8(sp)
    80006806:	e80e                	sd	gp,16(sp)
    80006808:	ec12                	sd	tp,24(sp)
    8000680a:	f016                	sd	t0,32(sp)
    8000680c:	f41a                	sd	t1,40(sp)
    8000680e:	f81e                	sd	t2,48(sp)
    80006810:	fc22                	sd	s0,56(sp)
    80006812:	e0a6                	sd	s1,64(sp)
    80006814:	e4aa                	sd	a0,72(sp)
    80006816:	e8ae                	sd	a1,80(sp)
    80006818:	ecb2                	sd	a2,88(sp)
    8000681a:	f0b6                	sd	a3,96(sp)
    8000681c:	f4ba                	sd	a4,104(sp)
    8000681e:	f8be                	sd	a5,112(sp)
    80006820:	fcc2                	sd	a6,120(sp)
    80006822:	e146                	sd	a7,128(sp)
    80006824:	e54a                	sd	s2,136(sp)
    80006826:	e94e                	sd	s3,144(sp)
    80006828:	ed52                	sd	s4,152(sp)
    8000682a:	f156                	sd	s5,160(sp)
    8000682c:	f55a                	sd	s6,168(sp)
    8000682e:	f95e                	sd	s7,176(sp)
    80006830:	fd62                	sd	s8,184(sp)
    80006832:	e1e6                	sd	s9,192(sp)
    80006834:	e5ea                	sd	s10,200(sp)
    80006836:	e9ee                	sd	s11,208(sp)
    80006838:	edf2                	sd	t3,216(sp)
    8000683a:	f1f6                	sd	t4,224(sp)
    8000683c:	f5fa                	sd	t5,232(sp)
    8000683e:	f9fe                	sd	t6,240(sp)
    80006840:	983fc0ef          	jal	ra,800031c2 <kerneltrap>
    80006844:	6082                	ld	ra,0(sp)
    80006846:	6122                	ld	sp,8(sp)
    80006848:	61c2                	ld	gp,16(sp)
    8000684a:	7282                	ld	t0,32(sp)
    8000684c:	7322                	ld	t1,40(sp)
    8000684e:	73c2                	ld	t2,48(sp)
    80006850:	7462                	ld	s0,56(sp)
    80006852:	6486                	ld	s1,64(sp)
    80006854:	6526                	ld	a0,72(sp)
    80006856:	65c6                	ld	a1,80(sp)
    80006858:	6666                	ld	a2,88(sp)
    8000685a:	7686                	ld	a3,96(sp)
    8000685c:	7726                	ld	a4,104(sp)
    8000685e:	77c6                	ld	a5,112(sp)
    80006860:	7866                	ld	a6,120(sp)
    80006862:	688a                	ld	a7,128(sp)
    80006864:	692a                	ld	s2,136(sp)
    80006866:	69ca                	ld	s3,144(sp)
    80006868:	6a6a                	ld	s4,152(sp)
    8000686a:	7a8a                	ld	s5,160(sp)
    8000686c:	7b2a                	ld	s6,168(sp)
    8000686e:	7bca                	ld	s7,176(sp)
    80006870:	7c6a                	ld	s8,184(sp)
    80006872:	6c8e                	ld	s9,192(sp)
    80006874:	6d2e                	ld	s10,200(sp)
    80006876:	6dce                	ld	s11,208(sp)
    80006878:	6e6e                	ld	t3,216(sp)
    8000687a:	7e8e                	ld	t4,224(sp)
    8000687c:	7f2e                	ld	t5,232(sp)
    8000687e:	7fce                	ld	t6,240(sp)
    80006880:	6111                	addi	sp,sp,256
    80006882:	10200073          	sret
    80006886:	00000013          	nop
    8000688a:	00000013          	nop
    8000688e:	0001                	nop

0000000080006890 <timervec>:
    80006890:	34051573          	csrrw	a0,mscratch,a0
    80006894:	e10c                	sd	a1,0(a0)
    80006896:	e510                	sd	a2,8(a0)
    80006898:	e914                	sd	a3,16(a0)
    8000689a:	6d0c                	ld	a1,24(a0)
    8000689c:	7110                	ld	a2,32(a0)
    8000689e:	6194                	ld	a3,0(a1)
    800068a0:	96b2                	add	a3,a3,a2
    800068a2:	e194                	sd	a3,0(a1)
    800068a4:	4589                	li	a1,2
    800068a6:	14459073          	csrw	sip,a1
    800068aa:	6914                	ld	a3,16(a0)
    800068ac:	6510                	ld	a2,8(a0)
    800068ae:	610c                	ld	a1,0(a0)
    800068b0:	34051573          	csrrw	a0,mscratch,a0
    800068b4:	30200073          	mret
	...

00000000800068ba <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800068ba:	1141                	addi	sp,sp,-16
    800068bc:	e422                	sd	s0,8(sp)
    800068be:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800068c0:	0c0007b7          	lui	a5,0xc000
    800068c4:	4705                	li	a4,1
    800068c6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800068c8:	c3d8                	sw	a4,4(a5)
}
    800068ca:	6422                	ld	s0,8(sp)
    800068cc:	0141                	addi	sp,sp,16
    800068ce:	8082                	ret

00000000800068d0 <plicinithart>:

void
plicinithart(void)
{
    800068d0:	1141                	addi	sp,sp,-16
    800068d2:	e406                	sd	ra,8(sp)
    800068d4:	e022                	sd	s0,0(sp)
    800068d6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800068d8:	ffffb097          	auipc	ra,0xffffb
    800068dc:	3f0080e7          	jalr	1008(ra) # 80001cc8 <cpuid>
  
  // set enable bits for this hart's S-mode
  // for the uart and virtio disk.
  *(uint32*)PLIC_SENABLE(hart) = (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800068e0:	0085171b          	slliw	a4,a0,0x8
    800068e4:	0c0027b7          	lui	a5,0xc002
    800068e8:	97ba                	add	a5,a5,a4
    800068ea:	40200713          	li	a4,1026
    800068ee:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    800068f2:	00d5151b          	slliw	a0,a0,0xd
    800068f6:	0c2017b7          	lui	a5,0xc201
    800068fa:	953e                	add	a0,a0,a5
    800068fc:	00052023          	sw	zero,0(a0)
}
    80006900:	60a2                	ld	ra,8(sp)
    80006902:	6402                	ld	s0,0(sp)
    80006904:	0141                	addi	sp,sp,16
    80006906:	8082                	ret

0000000080006908 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006908:	1141                	addi	sp,sp,-16
    8000690a:	e406                	sd	ra,8(sp)
    8000690c:	e022                	sd	s0,0(sp)
    8000690e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006910:	ffffb097          	auipc	ra,0xffffb
    80006914:	3b8080e7          	jalr	952(ra) # 80001cc8 <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006918:	00d5179b          	slliw	a5,a0,0xd
    8000691c:	0c201537          	lui	a0,0xc201
    80006920:	953e                	add	a0,a0,a5
  return irq;
}
    80006922:	4148                	lw	a0,4(a0)
    80006924:	60a2                	ld	ra,8(sp)
    80006926:	6402                	ld	s0,0(sp)
    80006928:	0141                	addi	sp,sp,16
    8000692a:	8082                	ret

000000008000692c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000692c:	1101                	addi	sp,sp,-32
    8000692e:	ec06                	sd	ra,24(sp)
    80006930:	e822                	sd	s0,16(sp)
    80006932:	e426                	sd	s1,8(sp)
    80006934:	1000                	addi	s0,sp,32
    80006936:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006938:	ffffb097          	auipc	ra,0xffffb
    8000693c:	390080e7          	jalr	912(ra) # 80001cc8 <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006940:	00d5151b          	slliw	a0,a0,0xd
    80006944:	0c2017b7          	lui	a5,0xc201
    80006948:	97aa                	add	a5,a5,a0
    8000694a:	c3c4                	sw	s1,4(a5)
}
    8000694c:	60e2                	ld	ra,24(sp)
    8000694e:	6442                	ld	s0,16(sp)
    80006950:	64a2                	ld	s1,8(sp)
    80006952:	6105                	addi	sp,sp,32
    80006954:	8082                	ret

0000000080006956 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006956:	1141                	addi	sp,sp,-16
    80006958:	e406                	sd	ra,8(sp)
    8000695a:	e022                	sd	s0,0(sp)
    8000695c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000695e:	479d                	li	a5,7
    80006960:	04a7cc63          	blt	a5,a0,800069b8 <free_desc+0x62>
    panic("free_desc 1");
  if(disk.free[i])
    80006964:	0023d797          	auipc	a5,0x23d
    80006968:	66c78793          	addi	a5,a5,1644 # 80243fd0 <disk>
    8000696c:	97aa                	add	a5,a5,a0
    8000696e:	0187c783          	lbu	a5,24(a5)
    80006972:	ebb9                	bnez	a5,800069c8 <free_desc+0x72>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    80006974:	00451613          	slli	a2,a0,0x4
    80006978:	0023d797          	auipc	a5,0x23d
    8000697c:	65878793          	addi	a5,a5,1624 # 80243fd0 <disk>
    80006980:	6394                	ld	a3,0(a5)
    80006982:	96b2                	add	a3,a3,a2
    80006984:	0006b023          	sd	zero,0(a3)
  disk.desc[i].len = 0;
    80006988:	6398                	ld	a4,0(a5)
    8000698a:	9732                	add	a4,a4,a2
    8000698c:	00072423          	sw	zero,8(a4)
  disk.desc[i].flags = 0;
    80006990:	00071623          	sh	zero,12(a4)
  disk.desc[i].next = 0;
    80006994:	00071723          	sh	zero,14(a4)
  disk.free[i] = 1;
    80006998:	953e                	add	a0,a0,a5
    8000699a:	4785                	li	a5,1
    8000699c:	00f50c23          	sb	a5,24(a0) # c201018 <_entry-0x73dfefe8>
  wakeup(&disk.free[0]);
    800069a0:	0023d517          	auipc	a0,0x23d
    800069a4:	64850513          	addi	a0,a0,1608 # 80243fe8 <disk+0x18>
    800069a8:	ffffc097          	auipc	ra,0xffffc
    800069ac:	d1a080e7          	jalr	-742(ra) # 800026c2 <wakeup>
}
    800069b0:	60a2                	ld	ra,8(sp)
    800069b2:	6402                	ld	s0,0(sp)
    800069b4:	0141                	addi	sp,sp,16
    800069b6:	8082                	ret
    panic("free_desc 1");
    800069b8:	00002517          	auipc	a0,0x2
    800069bc:	f8050513          	addi	a0,a0,-128 # 80008938 <syscalls+0x310>
    800069c0:	ffffa097          	auipc	ra,0xffffa
    800069c4:	b84080e7          	jalr	-1148(ra) # 80000544 <panic>
    panic("free_desc 2");
    800069c8:	00002517          	auipc	a0,0x2
    800069cc:	f8050513          	addi	a0,a0,-128 # 80008948 <syscalls+0x320>
    800069d0:	ffffa097          	auipc	ra,0xffffa
    800069d4:	b74080e7          	jalr	-1164(ra) # 80000544 <panic>

00000000800069d8 <virtio_disk_init>:
{
    800069d8:	1101                	addi	sp,sp,-32
    800069da:	ec06                	sd	ra,24(sp)
    800069dc:	e822                	sd	s0,16(sp)
    800069de:	e426                	sd	s1,8(sp)
    800069e0:	e04a                	sd	s2,0(sp)
    800069e2:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    800069e4:	00002597          	auipc	a1,0x2
    800069e8:	f7458593          	addi	a1,a1,-140 # 80008958 <syscalls+0x330>
    800069ec:	0023d517          	auipc	a0,0x23d
    800069f0:	70c50513          	addi	a0,a0,1804 # 802440f8 <disk+0x128>
    800069f4:	ffffa097          	auipc	ra,0xffffa
    800069f8:	428080e7          	jalr	1064(ra) # 80000e1c <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    800069fc:	100017b7          	lui	a5,0x10001
    80006a00:	4398                	lw	a4,0(a5)
    80006a02:	2701                	sext.w	a4,a4
    80006a04:	747277b7          	lui	a5,0x74727
    80006a08:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006a0c:	14f71e63          	bne	a4,a5,80006b68 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006a10:	100017b7          	lui	a5,0x10001
    80006a14:	43dc                	lw	a5,4(a5)
    80006a16:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006a18:	4709                	li	a4,2
    80006a1a:	14e79763          	bne	a5,a4,80006b68 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006a1e:	100017b7          	lui	a5,0x10001
    80006a22:	479c                	lw	a5,8(a5)
    80006a24:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 2 ||
    80006a26:	14e79163          	bne	a5,a4,80006b68 <virtio_disk_init+0x190>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006a2a:	100017b7          	lui	a5,0x10001
    80006a2e:	47d8                	lw	a4,12(a5)
    80006a30:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006a32:	554d47b7          	lui	a5,0x554d4
    80006a36:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006a3a:	12f71763          	bne	a4,a5,80006b68 <virtio_disk_init+0x190>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006a3e:	100017b7          	lui	a5,0x10001
    80006a42:	0607a823          	sw	zero,112(a5) # 10001070 <_entry-0x6fffef90>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006a46:	4705                	li	a4,1
    80006a48:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006a4a:	470d                	li	a4,3
    80006a4c:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006a4e:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006a50:	c7ffe737          	lui	a4,0xc7ffe
    80006a54:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff47dba64f>
    80006a58:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006a5a:	2701                	sext.w	a4,a4
    80006a5c:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006a5e:	472d                	li	a4,11
    80006a60:	dbb8                	sw	a4,112(a5)
  status = *R(VIRTIO_MMIO_STATUS);
    80006a62:	0707a903          	lw	s2,112(a5)
    80006a66:	2901                	sext.w	s2,s2
  if(!(status & VIRTIO_CONFIG_S_FEATURES_OK))
    80006a68:	00897793          	andi	a5,s2,8
    80006a6c:	10078663          	beqz	a5,80006b78 <virtio_disk_init+0x1a0>
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006a70:	100017b7          	lui	a5,0x10001
    80006a74:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  if(*R(VIRTIO_MMIO_QUEUE_READY))
    80006a78:	43fc                	lw	a5,68(a5)
    80006a7a:	2781                	sext.w	a5,a5
    80006a7c:	10079663          	bnez	a5,80006b88 <virtio_disk_init+0x1b0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006a80:	100017b7          	lui	a5,0x10001
    80006a84:	5bdc                	lw	a5,52(a5)
    80006a86:	2781                	sext.w	a5,a5
  if(max == 0)
    80006a88:	10078863          	beqz	a5,80006b98 <virtio_disk_init+0x1c0>
  if(max < NUM)
    80006a8c:	471d                	li	a4,7
    80006a8e:	10f77d63          	bgeu	a4,a5,80006ba8 <virtio_disk_init+0x1d0>
  disk.desc = kalloc();
    80006a92:	ffffa097          	auipc	ra,0xffffa
    80006a96:	262080e7          	jalr	610(ra) # 80000cf4 <kalloc>
    80006a9a:	0023d497          	auipc	s1,0x23d
    80006a9e:	53648493          	addi	s1,s1,1334 # 80243fd0 <disk>
    80006aa2:	e088                	sd	a0,0(s1)
  disk.avail = kalloc();
    80006aa4:	ffffa097          	auipc	ra,0xffffa
    80006aa8:	250080e7          	jalr	592(ra) # 80000cf4 <kalloc>
    80006aac:	e488                	sd	a0,8(s1)
  disk.used = kalloc();
    80006aae:	ffffa097          	auipc	ra,0xffffa
    80006ab2:	246080e7          	jalr	582(ra) # 80000cf4 <kalloc>
    80006ab6:	87aa                	mv	a5,a0
    80006ab8:	e888                	sd	a0,16(s1)
  if(!disk.desc || !disk.avail || !disk.used)
    80006aba:	6088                	ld	a0,0(s1)
    80006abc:	cd75                	beqz	a0,80006bb8 <virtio_disk_init+0x1e0>
    80006abe:	0023d717          	auipc	a4,0x23d
    80006ac2:	51a73703          	ld	a4,1306(a4) # 80243fd8 <disk+0x8>
    80006ac6:	cb6d                	beqz	a4,80006bb8 <virtio_disk_init+0x1e0>
    80006ac8:	cbe5                	beqz	a5,80006bb8 <virtio_disk_init+0x1e0>
  memset(disk.desc, 0, PGSIZE);
    80006aca:	6605                	lui	a2,0x1
    80006acc:	4581                	li	a1,0
    80006ace:	ffffa097          	auipc	ra,0xffffa
    80006ad2:	4da080e7          	jalr	1242(ra) # 80000fa8 <memset>
  memset(disk.avail, 0, PGSIZE);
    80006ad6:	0023d497          	auipc	s1,0x23d
    80006ada:	4fa48493          	addi	s1,s1,1274 # 80243fd0 <disk>
    80006ade:	6605                	lui	a2,0x1
    80006ae0:	4581                	li	a1,0
    80006ae2:	6488                	ld	a0,8(s1)
    80006ae4:	ffffa097          	auipc	ra,0xffffa
    80006ae8:	4c4080e7          	jalr	1220(ra) # 80000fa8 <memset>
  memset(disk.used, 0, PGSIZE);
    80006aec:	6605                	lui	a2,0x1
    80006aee:	4581                	li	a1,0
    80006af0:	6888                	ld	a0,16(s1)
    80006af2:	ffffa097          	auipc	ra,0xffffa
    80006af6:	4b6080e7          	jalr	1206(ra) # 80000fa8 <memset>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    80006afa:	100017b7          	lui	a5,0x10001
    80006afe:	4721                	li	a4,8
    80006b00:	df98                	sw	a4,56(a5)
  *R(VIRTIO_MMIO_QUEUE_DESC_LOW) = (uint64)disk.desc;
    80006b02:	4098                	lw	a4,0(s1)
    80006b04:	08e7a023          	sw	a4,128(a5) # 10001080 <_entry-0x6fffef80>
  *R(VIRTIO_MMIO_QUEUE_DESC_HIGH) = (uint64)disk.desc >> 32;
    80006b08:	40d8                	lw	a4,4(s1)
    80006b0a:	08e7a223          	sw	a4,132(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_LOW) = (uint64)disk.avail;
    80006b0e:	6498                	ld	a4,8(s1)
    80006b10:	0007069b          	sext.w	a3,a4
    80006b14:	08d7a823          	sw	a3,144(a5)
  *R(VIRTIO_MMIO_DRIVER_DESC_HIGH) = (uint64)disk.avail >> 32;
    80006b18:	9701                	srai	a4,a4,0x20
    80006b1a:	08e7aa23          	sw	a4,148(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_LOW) = (uint64)disk.used;
    80006b1e:	6898                	ld	a4,16(s1)
    80006b20:	0007069b          	sext.w	a3,a4
    80006b24:	0ad7a023          	sw	a3,160(a5)
  *R(VIRTIO_MMIO_DEVICE_DESC_HIGH) = (uint64)disk.used >> 32;
    80006b28:	9701                	srai	a4,a4,0x20
    80006b2a:	0ae7a223          	sw	a4,164(a5)
  *R(VIRTIO_MMIO_QUEUE_READY) = 0x1;
    80006b2e:	4685                	li	a3,1
    80006b30:	c3f4                	sw	a3,68(a5)
    disk.free[i] = 1;
    80006b32:	4705                	li	a4,1
    80006b34:	00d48c23          	sb	a3,24(s1)
    80006b38:	00e48ca3          	sb	a4,25(s1)
    80006b3c:	00e48d23          	sb	a4,26(s1)
    80006b40:	00e48da3          	sb	a4,27(s1)
    80006b44:	00e48e23          	sb	a4,28(s1)
    80006b48:	00e48ea3          	sb	a4,29(s1)
    80006b4c:	00e48f23          	sb	a4,30(s1)
    80006b50:	00e48fa3          	sb	a4,31(s1)
  status |= VIRTIO_CONFIG_S_DRIVER_OK;
    80006b54:	00496913          	ori	s2,s2,4
  *R(VIRTIO_MMIO_STATUS) = status;
    80006b58:	0727a823          	sw	s2,112(a5)
}
    80006b5c:	60e2                	ld	ra,24(sp)
    80006b5e:	6442                	ld	s0,16(sp)
    80006b60:	64a2                	ld	s1,8(sp)
    80006b62:	6902                	ld	s2,0(sp)
    80006b64:	6105                	addi	sp,sp,32
    80006b66:	8082                	ret
    panic("could not find virtio disk");
    80006b68:	00002517          	auipc	a0,0x2
    80006b6c:	e0050513          	addi	a0,a0,-512 # 80008968 <syscalls+0x340>
    80006b70:	ffffa097          	auipc	ra,0xffffa
    80006b74:	9d4080e7          	jalr	-1580(ra) # 80000544 <panic>
    panic("virtio disk FEATURES_OK unset");
    80006b78:	00002517          	auipc	a0,0x2
    80006b7c:	e1050513          	addi	a0,a0,-496 # 80008988 <syscalls+0x360>
    80006b80:	ffffa097          	auipc	ra,0xffffa
    80006b84:	9c4080e7          	jalr	-1596(ra) # 80000544 <panic>
    panic("virtio disk should not be ready");
    80006b88:	00002517          	auipc	a0,0x2
    80006b8c:	e2050513          	addi	a0,a0,-480 # 800089a8 <syscalls+0x380>
    80006b90:	ffffa097          	auipc	ra,0xffffa
    80006b94:	9b4080e7          	jalr	-1612(ra) # 80000544 <panic>
    panic("virtio disk has no queue 0");
    80006b98:	00002517          	auipc	a0,0x2
    80006b9c:	e3050513          	addi	a0,a0,-464 # 800089c8 <syscalls+0x3a0>
    80006ba0:	ffffa097          	auipc	ra,0xffffa
    80006ba4:	9a4080e7          	jalr	-1628(ra) # 80000544 <panic>
    panic("virtio disk max queue too short");
    80006ba8:	00002517          	auipc	a0,0x2
    80006bac:	e4050513          	addi	a0,a0,-448 # 800089e8 <syscalls+0x3c0>
    80006bb0:	ffffa097          	auipc	ra,0xffffa
    80006bb4:	994080e7          	jalr	-1644(ra) # 80000544 <panic>
    panic("virtio disk kalloc");
    80006bb8:	00002517          	auipc	a0,0x2
    80006bbc:	e5050513          	addi	a0,a0,-432 # 80008a08 <syscalls+0x3e0>
    80006bc0:	ffffa097          	auipc	ra,0xffffa
    80006bc4:	984080e7          	jalr	-1660(ra) # 80000544 <panic>

0000000080006bc8 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006bc8:	7159                	addi	sp,sp,-112
    80006bca:	f486                	sd	ra,104(sp)
    80006bcc:	f0a2                	sd	s0,96(sp)
    80006bce:	eca6                	sd	s1,88(sp)
    80006bd0:	e8ca                	sd	s2,80(sp)
    80006bd2:	e4ce                	sd	s3,72(sp)
    80006bd4:	e0d2                	sd	s4,64(sp)
    80006bd6:	fc56                	sd	s5,56(sp)
    80006bd8:	f85a                	sd	s6,48(sp)
    80006bda:	f45e                	sd	s7,40(sp)
    80006bdc:	f062                	sd	s8,32(sp)
    80006bde:	ec66                	sd	s9,24(sp)
    80006be0:	e86a                	sd	s10,16(sp)
    80006be2:	1880                	addi	s0,sp,112
    80006be4:	892a                	mv	s2,a0
    80006be6:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006be8:	00c52c83          	lw	s9,12(a0)
    80006bec:	001c9c9b          	slliw	s9,s9,0x1
    80006bf0:	1c82                	slli	s9,s9,0x20
    80006bf2:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006bf6:	0023d517          	auipc	a0,0x23d
    80006bfa:	50250513          	addi	a0,a0,1282 # 802440f8 <disk+0x128>
    80006bfe:	ffffa097          	auipc	ra,0xffffa
    80006c02:	2ae080e7          	jalr	686(ra) # 80000eac <acquire>
  for(int i = 0; i < 3; i++){
    80006c06:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006c08:	4ba1                	li	s7,8
      disk.free[i] = 0;
    80006c0a:	0023db17          	auipc	s6,0x23d
    80006c0e:	3c6b0b13          	addi	s6,s6,966 # 80243fd0 <disk>
  for(int i = 0; i < 3; i++){
    80006c12:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006c14:	8a4e                	mv	s4,s3
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006c16:	0023dc17          	auipc	s8,0x23d
    80006c1a:	4e2c0c13          	addi	s8,s8,1250 # 802440f8 <disk+0x128>
    80006c1e:	a8b5                	j	80006c9a <virtio_disk_rw+0xd2>
      disk.free[i] = 0;
    80006c20:	00fb06b3          	add	a3,s6,a5
    80006c24:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    80006c28:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    80006c2a:	0207c563          	bltz	a5,80006c54 <virtio_disk_rw+0x8c>
  for(int i = 0; i < 3; i++){
    80006c2e:	2485                	addiw	s1,s1,1
    80006c30:	0711                	addi	a4,a4,4
    80006c32:	1f548a63          	beq	s1,s5,80006e26 <virtio_disk_rw+0x25e>
    idx[i] = alloc_desc();
    80006c36:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    80006c38:	0023d697          	auipc	a3,0x23d
    80006c3c:	39868693          	addi	a3,a3,920 # 80243fd0 <disk>
    80006c40:	87d2                	mv	a5,s4
    if(disk.free[i]){
    80006c42:	0186c583          	lbu	a1,24(a3)
    80006c46:	fde9                	bnez	a1,80006c20 <virtio_disk_rw+0x58>
  for(int i = 0; i < NUM; i++){
    80006c48:	2785                	addiw	a5,a5,1
    80006c4a:	0685                	addi	a3,a3,1
    80006c4c:	ff779be3          	bne	a5,s7,80006c42 <virtio_disk_rw+0x7a>
    idx[i] = alloc_desc();
    80006c50:	57fd                	li	a5,-1
    80006c52:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    80006c54:	02905a63          	blez	s1,80006c88 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    80006c58:	f9042503          	lw	a0,-112(s0)
    80006c5c:	00000097          	auipc	ra,0x0
    80006c60:	cfa080e7          	jalr	-774(ra) # 80006956 <free_desc>
      for(int j = 0; j < i; j++)
    80006c64:	4785                	li	a5,1
    80006c66:	0297d163          	bge	a5,s1,80006c88 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    80006c6a:	f9442503          	lw	a0,-108(s0)
    80006c6e:	00000097          	auipc	ra,0x0
    80006c72:	ce8080e7          	jalr	-792(ra) # 80006956 <free_desc>
      for(int j = 0; j < i; j++)
    80006c76:	4789                	li	a5,2
    80006c78:	0097d863          	bge	a5,s1,80006c88 <virtio_disk_rw+0xc0>
        free_desc(idx[j]);
    80006c7c:	f9842503          	lw	a0,-104(s0)
    80006c80:	00000097          	auipc	ra,0x0
    80006c84:	cd6080e7          	jalr	-810(ra) # 80006956 <free_desc>
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006c88:	85e2                	mv	a1,s8
    80006c8a:	0023d517          	auipc	a0,0x23d
    80006c8e:	35e50513          	addi	a0,a0,862 # 80243fe8 <disk+0x18>
    80006c92:	ffffc097          	auipc	ra,0xffffc
    80006c96:	9cc080e7          	jalr	-1588(ra) # 8000265e <sleep>
  for(int i = 0; i < 3; i++){
    80006c9a:	f9040713          	addi	a4,s0,-112
    80006c9e:	84ce                	mv	s1,s3
    80006ca0:	bf59                	j	80006c36 <virtio_disk_rw+0x6e>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006ca2:	00a60793          	addi	a5,a2,10 # 100a <_entry-0x7fffeff6>
    80006ca6:	00479693          	slli	a3,a5,0x4
    80006caa:	0023d797          	auipc	a5,0x23d
    80006cae:	32678793          	addi	a5,a5,806 # 80243fd0 <disk>
    80006cb2:	97b6                	add	a5,a5,a3
    80006cb4:	4685                	li	a3,1
    80006cb6:	c794                	sw	a3,8(a5)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    80006cb8:	0023d597          	auipc	a1,0x23d
    80006cbc:	31858593          	addi	a1,a1,792 # 80243fd0 <disk>
    80006cc0:	00a60793          	addi	a5,a2,10
    80006cc4:	0792                	slli	a5,a5,0x4
    80006cc6:	97ae                	add	a5,a5,a1
    80006cc8:	0007a623          	sw	zero,12(a5)
  buf0->sector = sector;
    80006ccc:	0197b823          	sd	s9,16(a5)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006cd0:	f6070693          	addi	a3,a4,-160
    80006cd4:	619c                	ld	a5,0(a1)
    80006cd6:	97b6                	add	a5,a5,a3
    80006cd8:	e388                	sd	a0,0(a5)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006cda:	6188                	ld	a0,0(a1)
    80006cdc:	96aa                	add	a3,a3,a0
    80006cde:	47c1                	li	a5,16
    80006ce0:	c69c                	sw	a5,8(a3)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    80006ce2:	4785                	li	a5,1
    80006ce4:	00f69623          	sh	a5,12(a3)
  disk.desc[idx[0]].next = idx[1];
    80006ce8:	f9442783          	lw	a5,-108(s0)
    80006cec:	00f69723          	sh	a5,14(a3)

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006cf0:	0792                	slli	a5,a5,0x4
    80006cf2:	953e                	add	a0,a0,a5
    80006cf4:	05890693          	addi	a3,s2,88
    80006cf8:	e114                	sd	a3,0(a0)
  disk.desc[idx[1]].len = BSIZE;
    80006cfa:	6188                	ld	a0,0(a1)
    80006cfc:	97aa                	add	a5,a5,a0
    80006cfe:	40000693          	li	a3,1024
    80006d02:	c794                	sw	a3,8(a5)
  if(write)
    80006d04:	100d0d63          	beqz	s10,80006e1e <virtio_disk_rw+0x256>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    80006d08:	00079623          	sh	zero,12(a5)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    80006d0c:	00c7d683          	lhu	a3,12(a5)
    80006d10:	0016e693          	ori	a3,a3,1
    80006d14:	00d79623          	sh	a3,12(a5)
  disk.desc[idx[1]].next = idx[2];
    80006d18:	f9842583          	lw	a1,-104(s0)
    80006d1c:	00b79723          	sh	a1,14(a5)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    80006d20:	0023d697          	auipc	a3,0x23d
    80006d24:	2b068693          	addi	a3,a3,688 # 80243fd0 <disk>
    80006d28:	00260793          	addi	a5,a2,2
    80006d2c:	0792                	slli	a5,a5,0x4
    80006d2e:	97b6                	add	a5,a5,a3
    80006d30:	587d                	li	a6,-1
    80006d32:	01078823          	sb	a6,16(a5)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    80006d36:	0592                	slli	a1,a1,0x4
    80006d38:	952e                	add	a0,a0,a1
    80006d3a:	f9070713          	addi	a4,a4,-112
    80006d3e:	9736                	add	a4,a4,a3
    80006d40:	e118                	sd	a4,0(a0)
  disk.desc[idx[2]].len = 1;
    80006d42:	6298                	ld	a4,0(a3)
    80006d44:	972e                	add	a4,a4,a1
    80006d46:	4585                	li	a1,1
    80006d48:	c70c                	sw	a1,8(a4)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    80006d4a:	4509                	li	a0,2
    80006d4c:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[2]].next = 0;
    80006d50:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006d54:	00b92223          	sw	a1,4(s2)
  disk.info[idx[0]].b = b;
    80006d58:	0127b423          	sd	s2,8(a5)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006d5c:	6698                	ld	a4,8(a3)
    80006d5e:	00275783          	lhu	a5,2(a4)
    80006d62:	8b9d                	andi	a5,a5,7
    80006d64:	0786                	slli	a5,a5,0x1
    80006d66:	97ba                	add	a5,a5,a4
    80006d68:	00c79223          	sh	a2,4(a5)

  __sync_synchronize();
    80006d6c:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    80006d70:	6698                	ld	a4,8(a3)
    80006d72:	00275783          	lhu	a5,2(a4)
    80006d76:	2785                	addiw	a5,a5,1
    80006d78:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006d7c:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    80006d80:	100017b7          	lui	a5,0x10001
    80006d84:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006d88:	00492703          	lw	a4,4(s2)
    80006d8c:	4785                	li	a5,1
    80006d8e:	02f71163          	bne	a4,a5,80006db0 <virtio_disk_rw+0x1e8>
    sleep(b, &disk.vdisk_lock);
    80006d92:	0023d997          	auipc	s3,0x23d
    80006d96:	36698993          	addi	s3,s3,870 # 802440f8 <disk+0x128>
  while(b->disk == 1) {
    80006d9a:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006d9c:	85ce                	mv	a1,s3
    80006d9e:	854a                	mv	a0,s2
    80006da0:	ffffc097          	auipc	ra,0xffffc
    80006da4:	8be080e7          	jalr	-1858(ra) # 8000265e <sleep>
  while(b->disk == 1) {
    80006da8:	00492783          	lw	a5,4(s2)
    80006dac:	fe9788e3          	beq	a5,s1,80006d9c <virtio_disk_rw+0x1d4>
  }

  disk.info[idx[0]].b = 0;
    80006db0:	f9042903          	lw	s2,-112(s0)
    80006db4:	00290793          	addi	a5,s2,2
    80006db8:	00479713          	slli	a4,a5,0x4
    80006dbc:	0023d797          	auipc	a5,0x23d
    80006dc0:	21478793          	addi	a5,a5,532 # 80243fd0 <disk>
    80006dc4:	97ba                	add	a5,a5,a4
    80006dc6:	0007b423          	sd	zero,8(a5)
    int flag = disk.desc[i].flags;
    80006dca:	0023d997          	auipc	s3,0x23d
    80006dce:	20698993          	addi	s3,s3,518 # 80243fd0 <disk>
    80006dd2:	00491713          	slli	a4,s2,0x4
    80006dd6:	0009b783          	ld	a5,0(s3)
    80006dda:	97ba                	add	a5,a5,a4
    80006ddc:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    80006de0:	854a                	mv	a0,s2
    80006de2:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    80006de6:	00000097          	auipc	ra,0x0
    80006dea:	b70080e7          	jalr	-1168(ra) # 80006956 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    80006dee:	8885                	andi	s1,s1,1
    80006df0:	f0ed                	bnez	s1,80006dd2 <virtio_disk_rw+0x20a>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    80006df2:	0023d517          	auipc	a0,0x23d
    80006df6:	30650513          	addi	a0,a0,774 # 802440f8 <disk+0x128>
    80006dfa:	ffffa097          	auipc	ra,0xffffa
    80006dfe:	166080e7          	jalr	358(ra) # 80000f60 <release>
}
    80006e02:	70a6                	ld	ra,104(sp)
    80006e04:	7406                	ld	s0,96(sp)
    80006e06:	64e6                	ld	s1,88(sp)
    80006e08:	6946                	ld	s2,80(sp)
    80006e0a:	69a6                	ld	s3,72(sp)
    80006e0c:	6a06                	ld	s4,64(sp)
    80006e0e:	7ae2                	ld	s5,56(sp)
    80006e10:	7b42                	ld	s6,48(sp)
    80006e12:	7ba2                	ld	s7,40(sp)
    80006e14:	7c02                	ld	s8,32(sp)
    80006e16:	6ce2                	ld	s9,24(sp)
    80006e18:	6d42                	ld	s10,16(sp)
    80006e1a:	6165                	addi	sp,sp,112
    80006e1c:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    80006e1e:	4689                	li	a3,2
    80006e20:	00d79623          	sh	a3,12(a5)
    80006e24:	b5e5                	j	80006d0c <virtio_disk_rw+0x144>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    80006e26:	f9042603          	lw	a2,-112(s0)
    80006e2a:	00a60713          	addi	a4,a2,10
    80006e2e:	0712                	slli	a4,a4,0x4
    80006e30:	0023d517          	auipc	a0,0x23d
    80006e34:	1a850513          	addi	a0,a0,424 # 80243fd8 <disk+0x8>
    80006e38:	953a                	add	a0,a0,a4
  if(write)
    80006e3a:	e60d14e3          	bnez	s10,80006ca2 <virtio_disk_rw+0xda>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006e3e:	00a60793          	addi	a5,a2,10
    80006e42:	00479693          	slli	a3,a5,0x4
    80006e46:	0023d797          	auipc	a5,0x23d
    80006e4a:	18a78793          	addi	a5,a5,394 # 80243fd0 <disk>
    80006e4e:	97b6                	add	a5,a5,a3
    80006e50:	0007a423          	sw	zero,8(a5)
    80006e54:	b595                	j	80006cb8 <virtio_disk_rw+0xf0>

0000000080006e56 <virtio_disk_intr>:

void
virtio_disk_intr()
{
    80006e56:	1101                	addi	sp,sp,-32
    80006e58:	ec06                	sd	ra,24(sp)
    80006e5a:	e822                	sd	s0,16(sp)
    80006e5c:	e426                	sd	s1,8(sp)
    80006e5e:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006e60:	0023d497          	auipc	s1,0x23d
    80006e64:	17048493          	addi	s1,s1,368 # 80243fd0 <disk>
    80006e68:	0023d517          	auipc	a0,0x23d
    80006e6c:	29050513          	addi	a0,a0,656 # 802440f8 <disk+0x128>
    80006e70:	ffffa097          	auipc	ra,0xffffa
    80006e74:	03c080e7          	jalr	60(ra) # 80000eac <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006e78:	10001737          	lui	a4,0x10001
    80006e7c:	533c                	lw	a5,96(a4)
    80006e7e:	8b8d                	andi	a5,a5,3
    80006e80:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006e82:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006e86:	689c                	ld	a5,16(s1)
    80006e88:	0204d703          	lhu	a4,32(s1)
    80006e8c:	0027d783          	lhu	a5,2(a5)
    80006e90:	04f70863          	beq	a4,a5,80006ee0 <virtio_disk_intr+0x8a>
    __sync_synchronize();
    80006e94:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006e98:	6898                	ld	a4,16(s1)
    80006e9a:	0204d783          	lhu	a5,32(s1)
    80006e9e:	8b9d                	andi	a5,a5,7
    80006ea0:	078e                	slli	a5,a5,0x3
    80006ea2:	97ba                	add	a5,a5,a4
    80006ea4:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    80006ea6:	00278713          	addi	a4,a5,2
    80006eaa:	0712                	slli	a4,a4,0x4
    80006eac:	9726                	add	a4,a4,s1
    80006eae:	01074703          	lbu	a4,16(a4) # 10001010 <_entry-0x6fffeff0>
    80006eb2:	e721                	bnez	a4,80006efa <virtio_disk_intr+0xa4>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    80006eb4:	0789                	addi	a5,a5,2
    80006eb6:	0792                	slli	a5,a5,0x4
    80006eb8:	97a6                	add	a5,a5,s1
    80006eba:	6788                	ld	a0,8(a5)
    b->disk = 0;   // disk is done with buf
    80006ebc:	00052223          	sw	zero,4(a0)
    wakeup(b);
    80006ec0:	ffffc097          	auipc	ra,0xffffc
    80006ec4:	802080e7          	jalr	-2046(ra) # 800026c2 <wakeup>

    disk.used_idx += 1;
    80006ec8:	0204d783          	lhu	a5,32(s1)
    80006ecc:	2785                	addiw	a5,a5,1
    80006ece:	17c2                	slli	a5,a5,0x30
    80006ed0:	93c1                	srli	a5,a5,0x30
    80006ed2:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    80006ed6:	6898                	ld	a4,16(s1)
    80006ed8:	00275703          	lhu	a4,2(a4)
    80006edc:	faf71ce3          	bne	a4,a5,80006e94 <virtio_disk_intr+0x3e>
  }

  release(&disk.vdisk_lock);
    80006ee0:	0023d517          	auipc	a0,0x23d
    80006ee4:	21850513          	addi	a0,a0,536 # 802440f8 <disk+0x128>
    80006ee8:	ffffa097          	auipc	ra,0xffffa
    80006eec:	078080e7          	jalr	120(ra) # 80000f60 <release>
}
    80006ef0:	60e2                	ld	ra,24(sp)
    80006ef2:	6442                	ld	s0,16(sp)
    80006ef4:	64a2                	ld	s1,8(sp)
    80006ef6:	6105                	addi	sp,sp,32
    80006ef8:	8082                	ret
      panic("virtio_disk_intr status");
    80006efa:	00002517          	auipc	a0,0x2
    80006efe:	b2650513          	addi	a0,a0,-1242 # 80008a20 <syscalls+0x3f8>
    80006f02:	ffff9097          	auipc	ra,0xffff9
    80006f06:	642080e7          	jalr	1602(ra) # 80000544 <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051073          	csrw	sscratch,a0
    80007004:	02000537          	lui	a0,0x2000
    80007008:	357d                	addiw	a0,a0,-1
    8000700a:	0536                	slli	a0,a0,0xd
    8000700c:	02153423          	sd	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
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
    800070ac:	357d                	addiw	a0,a0,-1
    800070ae:	0536                	slli	a0,a0,0xd
    800070b0:	02853083          	ld	ra,40(a0) # 2000028 <_entry-0x7dffffd8>
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
