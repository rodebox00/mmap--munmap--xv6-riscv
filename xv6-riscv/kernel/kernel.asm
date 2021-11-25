
kernel/kernel:     file format elf64-littleriscv


Disassembly of section .text:

0000000080000000 <_entry>:
    80000000:	00009117          	auipc	sp,0x9
    80000004:	96013103          	ld	sp,-1696(sp) # 80008960 <_GLOBAL_OFFSET_TABLE_+0x8>
    80000008:	6505                	lui	a0,0x1
    8000000a:	f14025f3          	csrr	a1,mhartid
    8000000e:	0585                	addi	a1,a1,1
    80000010:	02b50533          	mul	a0,a0,a1
    80000014:	912a                	add	sp,sp,a0
    80000016:	078000ef          	jal	ra,8000008e <start>

000000008000001a <spin>:
    8000001a:	a001                	j	8000001a <spin>

000000008000001c <timerinit>:
// which arrive at timervec in kernelvec.S,
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
    80000056:	fee70713          	addi	a4,a4,-18 # 80009040 <timer_scratch>
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
    80000064:	00006797          	auipc	a5,0x6
    80000068:	13c78793          	addi	a5,a5,316 # 800061a0 <timervec>
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
    8000009c:	7ff70713          	addi	a4,a4,2047 # ffffffffffffe7ff <end+0xffffffff7f7587ff>
    800000a0:	8ff9                	and	a5,a5,a4
  x |= MSTATUS_MPP_S;
    800000a2:	6705                	lui	a4,0x1
    800000a4:	80070713          	addi	a4,a4,-2048 # 800 <_entry-0x7ffff800>
    800000a8:	8fd9                	or	a5,a5,a4
  asm volatile("csrw mstatus, %0" : : "r" (x));
    800000aa:	30079073          	csrw	mstatus,a5
  asm volatile("csrw mepc, %0" : : "r" (x));
    800000ae:	00001797          	auipc	a5,0x1
    800000b2:	04a78793          	addi	a5,a5,74 # 800010f8 <main>
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
    8000012c:	00002097          	auipc	ra,0x2
    80000130:	5b0080e7          	jalr	1456(ra) # 800026dc <either_copyin>
    80000134:	01550c63          	beq	a0,s5,8000014c <consolewrite+0x4a>
      break;
    uartputc(c);
    80000138:	fbf44503          	lbu	a0,-65(s0)
    8000013c:	00000097          	auipc	ra,0x0
    80000140:	78e080e7          	jalr	1934(ra) # 800008ca <uartputc>
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
    80000190:	ff450513          	addi	a0,a0,-12 # 80011180 <cons>
    80000194:	00001097          	auipc	ra,0x1
    80000198:	cba080e7          	jalr	-838(ra) # 80000e4e <acquire>
  while(n > 0){
    // wait until interrupt handler has put some
    // input into cons.buffer.
    while(cons.r == cons.w){
    8000019c:	00011497          	auipc	s1,0x11
    800001a0:	fe448493          	addi	s1,s1,-28 # 80011180 <cons>
      if(myproc()->killed){
        release(&cons.lock);
        return -1;
      }
      sleep(&cons.r, &cons.lock);
    800001a4:	89a6                	mv	s3,s1
    800001a6:	00011917          	auipc	s2,0x11
    800001aa:	07290913          	addi	s2,s2,114 # 80011218 <cons+0x98>
    }

    c = cons.buf[cons.r++ % INPUT_BUF];

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
    800001b4:	07405863          	blez	s4,80000224 <consoleread+0xc0>
    while(cons.r == cons.w){
    800001b8:	0984a783          	lw	a5,152(s1)
    800001bc:	09c4a703          	lw	a4,156(s1)
    800001c0:	02f71463          	bne	a4,a5,800001e8 <consoleread+0x84>
      if(myproc()->killed){
    800001c4:	00002097          	auipc	ra,0x2
    800001c8:	a56080e7          	jalr	-1450(ra) # 80001c1a <myproc>
    800001cc:	551c                	lw	a5,40(a0)
    800001ce:	e7b5                	bnez	a5,8000023a <consoleread+0xd6>
      sleep(&cons.r, &cons.lock);
    800001d0:	85ce                	mv	a1,s3
    800001d2:	854a                	mv	a0,s2
    800001d4:	00002097          	auipc	ra,0x2
    800001d8:	10e080e7          	jalr	270(ra) # 800022e2 <sleep>
    while(cons.r == cons.w){
    800001dc:	0984a783          	lw	a5,152(s1)
    800001e0:	09c4a703          	lw	a4,156(s1)
    800001e4:	fef700e3          	beq	a4,a5,800001c4 <consoleread+0x60>
    c = cons.buf[cons.r++ % INPUT_BUF];
    800001e8:	0017871b          	addiw	a4,a5,1
    800001ec:	08e4ac23          	sw	a4,152(s1)
    800001f0:	07f7f713          	andi	a4,a5,127
    800001f4:	9726                	add	a4,a4,s1
    800001f6:	01874703          	lbu	a4,24(a4)
    800001fa:	00070c1b          	sext.w	s8,a4
    if(c == C('D')){  // end-of-file
    800001fe:	079c0663          	beq	s8,s9,8000026a <consoleread+0x106>
    cbuf = c;
    80000202:	f8e407a3          	sb	a4,-113(s0)
    if(either_copyout(user_dst, dst, &cbuf, 1) == -1)
    80000206:	4685                	li	a3,1
    80000208:	f8f40613          	addi	a2,s0,-113
    8000020c:	85d6                	mv	a1,s5
    8000020e:	855a                	mv	a0,s6
    80000210:	00002097          	auipc	ra,0x2
    80000214:	476080e7          	jalr	1142(ra) # 80002686 <either_copyout>
    80000218:	01a50663          	beq	a0,s10,80000224 <consoleread+0xc0>
    dst++;
    8000021c:	0a85                	addi	s5,s5,1
    --n;
    8000021e:	3a7d                	addiw	s4,s4,-1
    if(c == '\n'){
    80000220:	f9bc1ae3          	bne	s8,s11,800001b4 <consoleread+0x50>
      // a whole line has arrived, return to
      // the user-level read().
      break;
    }
  }
  release(&cons.lock);
    80000224:	00011517          	auipc	a0,0x11
    80000228:	f5c50513          	addi	a0,a0,-164 # 80011180 <cons>
    8000022c:	00001097          	auipc	ra,0x1
    80000230:	cd6080e7          	jalr	-810(ra) # 80000f02 <release>

  return target - n;
    80000234:	414b853b          	subw	a0,s7,s4
    80000238:	a811                	j	8000024c <consoleread+0xe8>
        release(&cons.lock);
    8000023a:	00011517          	auipc	a0,0x11
    8000023e:	f4650513          	addi	a0,a0,-186 # 80011180 <cons>
    80000242:	00001097          	auipc	ra,0x1
    80000246:	cc0080e7          	jalr	-832(ra) # 80000f02 <release>
        return -1;
    8000024a:	557d                	li	a0,-1
}
    8000024c:	70e6                	ld	ra,120(sp)
    8000024e:	7446                	ld	s0,112(sp)
    80000250:	74a6                	ld	s1,104(sp)
    80000252:	7906                	ld	s2,96(sp)
    80000254:	69e6                	ld	s3,88(sp)
    80000256:	6a46                	ld	s4,80(sp)
    80000258:	6aa6                	ld	s5,72(sp)
    8000025a:	6b06                	ld	s6,64(sp)
    8000025c:	7be2                	ld	s7,56(sp)
    8000025e:	7c42                	ld	s8,48(sp)
    80000260:	7ca2                	ld	s9,40(sp)
    80000262:	7d02                	ld	s10,32(sp)
    80000264:	6de2                	ld	s11,24(sp)
    80000266:	6109                	addi	sp,sp,128
    80000268:	8082                	ret
      if(n < target){
    8000026a:	000a071b          	sext.w	a4,s4
    8000026e:	fb777be3          	bgeu	a4,s7,80000224 <consoleread+0xc0>
        cons.r--;
    80000272:	00011717          	auipc	a4,0x11
    80000276:	faf72323          	sw	a5,-90(a4) # 80011218 <cons+0x98>
    8000027a:	b76d                	j	80000224 <consoleread+0xc0>

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
    80000290:	564080e7          	jalr	1380(ra) # 800007f0 <uartputc_sync>
}
    80000294:	60a2                	ld	ra,8(sp)
    80000296:	6402                	ld	s0,0(sp)
    80000298:	0141                	addi	sp,sp,16
    8000029a:	8082                	ret
    uartputc_sync('\b'); uartputc_sync(' '); uartputc_sync('\b');
    8000029c:	4521                	li	a0,8
    8000029e:	00000097          	auipc	ra,0x0
    800002a2:	552080e7          	jalr	1362(ra) # 800007f0 <uartputc_sync>
    800002a6:	02000513          	li	a0,32
    800002aa:	00000097          	auipc	ra,0x0
    800002ae:	546080e7          	jalr	1350(ra) # 800007f0 <uartputc_sync>
    800002b2:	4521                	li	a0,8
    800002b4:	00000097          	auipc	ra,0x0
    800002b8:	53c080e7          	jalr	1340(ra) # 800007f0 <uartputc_sync>
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
    800002d0:	eb450513          	addi	a0,a0,-332 # 80011180 <cons>
    800002d4:	00001097          	auipc	ra,0x1
    800002d8:	b7a080e7          	jalr	-1158(ra) # 80000e4e <acquire>

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
    800002f6:	440080e7          	jalr	1088(ra) # 80002732 <procdump>
      }
    }
    break;
  }
  
  release(&cons.lock);
    800002fa:	00011517          	auipc	a0,0x11
    800002fe:	e8650513          	addi	a0,a0,-378 # 80011180 <cons>
    80000302:	00001097          	auipc	ra,0x1
    80000306:	c00080e7          	jalr	-1024(ra) # 80000f02 <release>
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
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    8000031e:	00011717          	auipc	a4,0x11
    80000322:	e6270713          	addi	a4,a4,-414 # 80011180 <cons>
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
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000348:	00011797          	auipc	a5,0x11
    8000034c:	e3878793          	addi	a5,a5,-456 # 80011180 <cons>
    80000350:	0a07a703          	lw	a4,160(a5)
    80000354:	0017069b          	addiw	a3,a4,1
    80000358:	0006861b          	sext.w	a2,a3
    8000035c:	0ad7a023          	sw	a3,160(a5)
    80000360:	07f77713          	andi	a4,a4,127
    80000364:	97ba                	add	a5,a5,a4
    80000366:	00978c23          	sb	s1,24(a5)
      if(c == '\n' || c == C('D') || cons.e == cons.r+INPUT_BUF){
    8000036a:	47a9                	li	a5,10
    8000036c:	0cf48563          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000370:	4791                	li	a5,4
    80000372:	0cf48263          	beq	s1,a5,80000436 <consoleintr+0x178>
    80000376:	00011797          	auipc	a5,0x11
    8000037a:	ea27a783          	lw	a5,-350(a5) # 80011218 <cons+0x98>
    8000037e:	0807879b          	addiw	a5,a5,128
    80000382:	f6f61ce3          	bne	a2,a5,800002fa <consoleintr+0x3c>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000386:	863e                	mv	a2,a5
    80000388:	a07d                	j	80000436 <consoleintr+0x178>
    while(cons.e != cons.w &&
    8000038a:	00011717          	auipc	a4,0x11
    8000038e:	df670713          	addi	a4,a4,-522 # 80011180 <cons>
    80000392:	0a072783          	lw	a5,160(a4)
    80000396:	09c72703          	lw	a4,156(a4)
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
    8000039a:	00011497          	auipc	s1,0x11
    8000039e:	de648493          	addi	s1,s1,-538 # 80011180 <cons>
    while(cons.e != cons.w &&
    800003a2:	4929                	li	s2,10
    800003a4:	f4f70be3          	beq	a4,a5,800002fa <consoleintr+0x3c>
          cons.buf[(cons.e-1) % INPUT_BUF] != '\n'){
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
    800003da:	daa70713          	addi	a4,a4,-598 # 80011180 <cons>
    800003de:	0a072783          	lw	a5,160(a4)
    800003e2:	09c72703          	lw	a4,156(a4)
    800003e6:	f0f70ae3          	beq	a4,a5,800002fa <consoleintr+0x3c>
      cons.e--;
    800003ea:	37fd                	addiw	a5,a5,-1
    800003ec:	00011717          	auipc	a4,0x11
    800003f0:	e2f72a23          	sw	a5,-460(a4) # 80011220 <cons+0xa0>
      consputc(BACKSPACE);
    800003f4:	10000513          	li	a0,256
    800003f8:	00000097          	auipc	ra,0x0
    800003fc:	e84080e7          	jalr	-380(ra) # 8000027c <consputc>
    80000400:	bded                	j	800002fa <consoleintr+0x3c>
    if(c != 0 && cons.e-cons.r < INPUT_BUF){
    80000402:	ee048ce3          	beqz	s1,800002fa <consoleintr+0x3c>
    80000406:	bf21                	j	8000031e <consoleintr+0x60>
      consputc(c);
    80000408:	4529                	li	a0,10
    8000040a:	00000097          	auipc	ra,0x0
    8000040e:	e72080e7          	jalr	-398(ra) # 8000027c <consputc>
      cons.buf[cons.e++ % INPUT_BUF] = c;
    80000412:	00011797          	auipc	a5,0x11
    80000416:	d6e78793          	addi	a5,a5,-658 # 80011180 <cons>
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
    8000043a:	dec7a323          	sw	a2,-538(a5) # 8001121c <cons+0x9c>
        wakeup(&cons.r);
    8000043e:	00011517          	auipc	a0,0x11
    80000442:	dda50513          	addi	a0,a0,-550 # 80011218 <cons+0x98>
    80000446:	00002097          	auipc	ra,0x2
    8000044a:	028080e7          	jalr	40(ra) # 8000246e <wakeup>
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
    80000460:	00011517          	auipc	a0,0x11
    80000464:	d2050513          	addi	a0,a0,-736 # 80011180 <cons>
    80000468:	00001097          	auipc	ra,0x1
    8000046c:	956080e7          	jalr	-1706(ra) # 80000dbe <initlock>

  uartinit();
    80000470:	00000097          	auipc	ra,0x0
    80000474:	330080e7          	jalr	816(ra) # 800007a0 <uartinit>

  // connect read and write system calls
  // to consoleread and consolewrite.
  devsw[CONSOLE].read = consoleread;
    80000478:	008a1797          	auipc	a5,0x8a1
    8000047c:	2a078793          	addi	a5,a5,672 # 808a1718 <devsw>
    80000480:	00000717          	auipc	a4,0x0
    80000484:	ce470713          	addi	a4,a4,-796 # 80000164 <consoleread>
    80000488:	eb98                	sd	a4,16(a5)
  devsw[CONSOLE].write = consolewrite;
    8000048a:	00000717          	auipc	a4,0x0
    8000048e:	c7870713          	addi	a4,a4,-904 # 80000102 <consolewrite>
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
    800004aa:	08054663          	bltz	a0,80000536 <printint+0x9a>
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
    800004e6:	00088b63          	beqz	a7,800004fc <printint+0x60>
    buf[i++] = '-';
    800004ea:	fe040793          	addi	a5,s0,-32
    800004ee:	973e                	add	a4,a4,a5
    800004f0:	02d00793          	li	a5,45
    800004f4:	fef70823          	sb	a5,-16(a4)
    800004f8:	0028071b          	addiw	a4,a6,2

  while(--i >= 0)
    800004fc:	02e05763          	blez	a4,8000052a <printint+0x8e>
    80000500:	fd040793          	addi	a5,s0,-48
    80000504:	00e784b3          	add	s1,a5,a4
    80000508:	fff78913          	addi	s2,a5,-1
    8000050c:	993a                	add	s2,s2,a4
    8000050e:	377d                	addiw	a4,a4,-1
    80000510:	1702                	slli	a4,a4,0x20
    80000512:	9301                	srli	a4,a4,0x20
    80000514:	40e90933          	sub	s2,s2,a4
    consputc(buf[i]);
    80000518:	fff4c503          	lbu	a0,-1(s1)
    8000051c:	00000097          	auipc	ra,0x0
    80000520:	d60080e7          	jalr	-672(ra) # 8000027c <consputc>
  while(--i >= 0)
    80000524:	14fd                	addi	s1,s1,-1
    80000526:	ff2499e3          	bne	s1,s2,80000518 <printint+0x7c>
}
    8000052a:	70a2                	ld	ra,40(sp)
    8000052c:	7402                	ld	s0,32(sp)
    8000052e:	64e2                	ld	s1,24(sp)
    80000530:	6942                	ld	s2,16(sp)
    80000532:	6145                	addi	sp,sp,48
    80000534:	8082                	ret
    x = -xx;
    80000536:	40a0053b          	negw	a0,a0
  if(sign && (sign = xx < 0))
    8000053a:	4885                	li	a7,1
    x = -xx;
    8000053c:	bf9d                	j	800004b2 <printint+0x16>

000000008000053e <panic>:
    release(&pr.lock);
}

void
panic(char *s)
{
    8000053e:	1101                	addi	sp,sp,-32
    80000540:	ec06                	sd	ra,24(sp)
    80000542:	e822                	sd	s0,16(sp)
    80000544:	e426                	sd	s1,8(sp)
    80000546:	1000                	addi	s0,sp,32
    80000548:	84aa                	mv	s1,a0
  pr.locking = 0;
    8000054a:	00011797          	auipc	a5,0x11
    8000054e:	ce07ab23          	sw	zero,-778(a5) # 80011240 <pr+0x18>
  printf("panic: ");
    80000552:	00008517          	auipc	a0,0x8
    80000556:	ac650513          	addi	a0,a0,-1338 # 80008018 <etext+0x18>
    8000055a:	00000097          	auipc	ra,0x0
    8000055e:	02e080e7          	jalr	46(ra) # 80000588 <printf>
  printf(s);
    80000562:	8526                	mv	a0,s1
    80000564:	00000097          	auipc	ra,0x0
    80000568:	024080e7          	jalr	36(ra) # 80000588 <printf>
  printf("\n");
    8000056c:	00008517          	auipc	a0,0x8
    80000570:	2ec50513          	addi	a0,a0,748 # 80008858 <syscalls+0x338>
    80000574:	00000097          	auipc	ra,0x0
    80000578:	014080e7          	jalr	20(ra) # 80000588 <printf>
  panicked = 1; // freeze uart output from other CPUs
    8000057c:	4785                	li	a5,1
    8000057e:	00009717          	auipc	a4,0x9
    80000582:	a8f72123          	sw	a5,-1406(a4) # 80009000 <panicked>
  for(;;)
    80000586:	a001                	j	80000586 <panic+0x48>

0000000080000588 <printf>:
{
    80000588:	7131                	addi	sp,sp,-192
    8000058a:	fc86                	sd	ra,120(sp)
    8000058c:	f8a2                	sd	s0,112(sp)
    8000058e:	f4a6                	sd	s1,104(sp)
    80000590:	f0ca                	sd	s2,96(sp)
    80000592:	ecce                	sd	s3,88(sp)
    80000594:	e8d2                	sd	s4,80(sp)
    80000596:	e4d6                	sd	s5,72(sp)
    80000598:	e0da                	sd	s6,64(sp)
    8000059a:	fc5e                	sd	s7,56(sp)
    8000059c:	f862                	sd	s8,48(sp)
    8000059e:	f466                	sd	s9,40(sp)
    800005a0:	f06a                	sd	s10,32(sp)
    800005a2:	ec6e                	sd	s11,24(sp)
    800005a4:	0100                	addi	s0,sp,128
    800005a6:	8a2a                	mv	s4,a0
    800005a8:	e40c                	sd	a1,8(s0)
    800005aa:	e810                	sd	a2,16(s0)
    800005ac:	ec14                	sd	a3,24(s0)
    800005ae:	f018                	sd	a4,32(s0)
    800005b0:	f41c                	sd	a5,40(s0)
    800005b2:	03043823          	sd	a6,48(s0)
    800005b6:	03143c23          	sd	a7,56(s0)
  locking = pr.locking;
    800005ba:	00011d97          	auipc	s11,0x11
    800005be:	c86dad83          	lw	s11,-890(s11) # 80011240 <pr+0x18>
  if(locking)
    800005c2:	020d9b63          	bnez	s11,800005f8 <printf+0x70>
  if (fmt == 0)
    800005c6:	040a0263          	beqz	s4,8000060a <printf+0x82>
  va_start(ap, fmt);
    800005ca:	00840793          	addi	a5,s0,8
    800005ce:	f8f43423          	sd	a5,-120(s0)
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    800005d2:	000a4503          	lbu	a0,0(s4)
    800005d6:	16050263          	beqz	a0,8000073a <printf+0x1b2>
    800005da:	4481                	li	s1,0
    if(c != '%'){
    800005dc:	02500a93          	li	s5,37
    switch(c){
    800005e0:	07000b13          	li	s6,112
  consputc('x');
    800005e4:	4d41                	li	s10,16
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800005e6:	00008b97          	auipc	s7,0x8
    800005ea:	a5ab8b93          	addi	s7,s7,-1446 # 80008040 <digits>
    switch(c){
    800005ee:	07300c93          	li	s9,115
    800005f2:	06400c13          	li	s8,100
    800005f6:	a82d                	j	80000630 <printf+0xa8>
    acquire(&pr.lock);
    800005f8:	00011517          	auipc	a0,0x11
    800005fc:	c3050513          	addi	a0,a0,-976 # 80011228 <pr>
    80000600:	00001097          	auipc	ra,0x1
    80000604:	84e080e7          	jalr	-1970(ra) # 80000e4e <acquire>
    80000608:	bf7d                	j	800005c6 <printf+0x3e>
    panic("null fmt");
    8000060a:	00008517          	auipc	a0,0x8
    8000060e:	a1e50513          	addi	a0,a0,-1506 # 80008028 <etext+0x28>
    80000612:	00000097          	auipc	ra,0x0
    80000616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
      consputc(c);
    8000061a:	00000097          	auipc	ra,0x0
    8000061e:	c62080e7          	jalr	-926(ra) # 8000027c <consputc>
  for(i = 0; (c = fmt[i] & 0xff) != 0; i++){
    80000622:	2485                	addiw	s1,s1,1
    80000624:	009a07b3          	add	a5,s4,s1
    80000628:	0007c503          	lbu	a0,0(a5)
    8000062c:	10050763          	beqz	a0,8000073a <printf+0x1b2>
    if(c != '%'){
    80000630:	ff5515e3          	bne	a0,s5,8000061a <printf+0x92>
    c = fmt[++i] & 0xff;
    80000634:	2485                	addiw	s1,s1,1
    80000636:	009a07b3          	add	a5,s4,s1
    8000063a:	0007c783          	lbu	a5,0(a5)
    8000063e:	0007891b          	sext.w	s2,a5
    if(c == 0)
    80000642:	cfe5                	beqz	a5,8000073a <printf+0x1b2>
    switch(c){
    80000644:	05678a63          	beq	a5,s6,80000698 <printf+0x110>
    80000648:	02fb7663          	bgeu	s6,a5,80000674 <printf+0xec>
    8000064c:	09978963          	beq	a5,s9,800006de <printf+0x156>
    80000650:	07800713          	li	a4,120
    80000654:	0ce79863          	bne	a5,a4,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 16, 1);
    80000658:	f8843783          	ld	a5,-120(s0)
    8000065c:	00878713          	addi	a4,a5,8
    80000660:	f8e43423          	sd	a4,-120(s0)
    80000664:	4605                	li	a2,1
    80000666:	85ea                	mv	a1,s10
    80000668:	4388                	lw	a0,0(a5)
    8000066a:	00000097          	auipc	ra,0x0
    8000066e:	e32080e7          	jalr	-462(ra) # 8000049c <printint>
      break;
    80000672:	bf45                	j	80000622 <printf+0x9a>
    switch(c){
    80000674:	0b578263          	beq	a5,s5,80000718 <printf+0x190>
    80000678:	0b879663          	bne	a5,s8,80000724 <printf+0x19c>
      printint(va_arg(ap, int), 10, 1);
    8000067c:	f8843783          	ld	a5,-120(s0)
    80000680:	00878713          	addi	a4,a5,8
    80000684:	f8e43423          	sd	a4,-120(s0)
    80000688:	4605                	li	a2,1
    8000068a:	45a9                	li	a1,10
    8000068c:	4388                	lw	a0,0(a5)
    8000068e:	00000097          	auipc	ra,0x0
    80000692:	e0e080e7          	jalr	-498(ra) # 8000049c <printint>
      break;
    80000696:	b771                	j	80000622 <printf+0x9a>
      printptr(va_arg(ap, uint64));
    80000698:	f8843783          	ld	a5,-120(s0)
    8000069c:	00878713          	addi	a4,a5,8
    800006a0:	f8e43423          	sd	a4,-120(s0)
    800006a4:	0007b983          	ld	s3,0(a5)
  consputc('0');
    800006a8:	03000513          	li	a0,48
    800006ac:	00000097          	auipc	ra,0x0
    800006b0:	bd0080e7          	jalr	-1072(ra) # 8000027c <consputc>
  consputc('x');
    800006b4:	07800513          	li	a0,120
    800006b8:	00000097          	auipc	ra,0x0
    800006bc:	bc4080e7          	jalr	-1084(ra) # 8000027c <consputc>
    800006c0:	896a                	mv	s2,s10
    consputc(digits[x >> (sizeof(uint64) * 8 - 4)]);
    800006c2:	03c9d793          	srli	a5,s3,0x3c
    800006c6:	97de                	add	a5,a5,s7
    800006c8:	0007c503          	lbu	a0,0(a5)
    800006cc:	00000097          	auipc	ra,0x0
    800006d0:	bb0080e7          	jalr	-1104(ra) # 8000027c <consputc>
  for (i = 0; i < (sizeof(uint64) * 2); i++, x <<= 4)
    800006d4:	0992                	slli	s3,s3,0x4
    800006d6:	397d                	addiw	s2,s2,-1
    800006d8:	fe0915e3          	bnez	s2,800006c2 <printf+0x13a>
    800006dc:	b799                	j	80000622 <printf+0x9a>
      if((s = va_arg(ap, char*)) == 0)
    800006de:	f8843783          	ld	a5,-120(s0)
    800006e2:	00878713          	addi	a4,a5,8
    800006e6:	f8e43423          	sd	a4,-120(s0)
    800006ea:	0007b903          	ld	s2,0(a5)
    800006ee:	00090e63          	beqz	s2,8000070a <printf+0x182>
      for(; *s; s++)
    800006f2:	00094503          	lbu	a0,0(s2)
    800006f6:	d515                	beqz	a0,80000622 <printf+0x9a>
        consputc(*s);
    800006f8:	00000097          	auipc	ra,0x0
    800006fc:	b84080e7          	jalr	-1148(ra) # 8000027c <consputc>
      for(; *s; s++)
    80000700:	0905                	addi	s2,s2,1
    80000702:	00094503          	lbu	a0,0(s2)
    80000706:	f96d                	bnez	a0,800006f8 <printf+0x170>
    80000708:	bf29                	j	80000622 <printf+0x9a>
        s = "(null)";
    8000070a:	00008917          	auipc	s2,0x8
    8000070e:	91690913          	addi	s2,s2,-1770 # 80008020 <etext+0x20>
      for(; *s; s++)
    80000712:	02800513          	li	a0,40
    80000716:	b7cd                	j	800006f8 <printf+0x170>
      consputc('%');
    80000718:	8556                	mv	a0,s5
    8000071a:	00000097          	auipc	ra,0x0
    8000071e:	b62080e7          	jalr	-1182(ra) # 8000027c <consputc>
      break;
    80000722:	b701                	j	80000622 <printf+0x9a>
      consputc('%');
    80000724:	8556                	mv	a0,s5
    80000726:	00000097          	auipc	ra,0x0
    8000072a:	b56080e7          	jalr	-1194(ra) # 8000027c <consputc>
      consputc(c);
    8000072e:	854a                	mv	a0,s2
    80000730:	00000097          	auipc	ra,0x0
    80000734:	b4c080e7          	jalr	-1204(ra) # 8000027c <consputc>
      break;
    80000738:	b5ed                	j	80000622 <printf+0x9a>
  if(locking)
    8000073a:	020d9163          	bnez	s11,8000075c <printf+0x1d4>
}
    8000073e:	70e6                	ld	ra,120(sp)
    80000740:	7446                	ld	s0,112(sp)
    80000742:	74a6                	ld	s1,104(sp)
    80000744:	7906                	ld	s2,96(sp)
    80000746:	69e6                	ld	s3,88(sp)
    80000748:	6a46                	ld	s4,80(sp)
    8000074a:	6aa6                	ld	s5,72(sp)
    8000074c:	6b06                	ld	s6,64(sp)
    8000074e:	7be2                	ld	s7,56(sp)
    80000750:	7c42                	ld	s8,48(sp)
    80000752:	7ca2                	ld	s9,40(sp)
    80000754:	7d02                	ld	s10,32(sp)
    80000756:	6de2                	ld	s11,24(sp)
    80000758:	6129                	addi	sp,sp,192
    8000075a:	8082                	ret
    release(&pr.lock);
    8000075c:	00011517          	auipc	a0,0x11
    80000760:	acc50513          	addi	a0,a0,-1332 # 80011228 <pr>
    80000764:	00000097          	auipc	ra,0x0
    80000768:	79e080e7          	jalr	1950(ra) # 80000f02 <release>
}
    8000076c:	bfc9                	j	8000073e <printf+0x1b6>

000000008000076e <printfinit>:
    ;
}

void
printfinit(void)
{
    8000076e:	1101                	addi	sp,sp,-32
    80000770:	ec06                	sd	ra,24(sp)
    80000772:	e822                	sd	s0,16(sp)
    80000774:	e426                	sd	s1,8(sp)
    80000776:	1000                	addi	s0,sp,32
  initlock(&pr.lock, "pr");
    80000778:	00011497          	auipc	s1,0x11
    8000077c:	ab048493          	addi	s1,s1,-1360 # 80011228 <pr>
    80000780:	00008597          	auipc	a1,0x8
    80000784:	8b858593          	addi	a1,a1,-1864 # 80008038 <etext+0x38>
    80000788:	8526                	mv	a0,s1
    8000078a:	00000097          	auipc	ra,0x0
    8000078e:	634080e7          	jalr	1588(ra) # 80000dbe <initlock>
  pr.locking = 1;
    80000792:	4785                	li	a5,1
    80000794:	cc9c                	sw	a5,24(s1)
}
    80000796:	60e2                	ld	ra,24(sp)
    80000798:	6442                	ld	s0,16(sp)
    8000079a:	64a2                	ld	s1,8(sp)
    8000079c:	6105                	addi	sp,sp,32
    8000079e:	8082                	ret

00000000800007a0 <uartinit>:

void uartstart();

void
uartinit(void)
{
    800007a0:	1141                	addi	sp,sp,-16
    800007a2:	e406                	sd	ra,8(sp)
    800007a4:	e022                	sd	s0,0(sp)
    800007a6:	0800                	addi	s0,sp,16
  // disable interrupts.
  WriteReg(IER, 0x00);
    800007a8:	100007b7          	lui	a5,0x10000
    800007ac:	000780a3          	sb	zero,1(a5) # 10000001 <_entry-0x6fffffff>

  // special mode to set baud rate.
  WriteReg(LCR, LCR_BAUD_LATCH);
    800007b0:	f8000713          	li	a4,-128
    800007b4:	00e781a3          	sb	a4,3(a5)

  // LSB for baud rate of 38.4K.
  WriteReg(0, 0x03);
    800007b8:	470d                	li	a4,3
    800007ba:	00e78023          	sb	a4,0(a5)

  // MSB for baud rate of 38.4K.
  WriteReg(1, 0x00);
    800007be:	000780a3          	sb	zero,1(a5)

  // leave set-baud mode,
  // and set word length to 8 bits, no parity.
  WriteReg(LCR, LCR_EIGHT_BITS);
    800007c2:	00e781a3          	sb	a4,3(a5)

  // reset and enable FIFOs.
  WriteReg(FCR, FCR_FIFO_ENABLE | FCR_FIFO_CLEAR);
    800007c6:	469d                	li	a3,7
    800007c8:	00d78123          	sb	a3,2(a5)

  // enable transmit and receive interrupts.
  WriteReg(IER, IER_TX_ENABLE | IER_RX_ENABLE);
    800007cc:	00e780a3          	sb	a4,1(a5)

  initlock(&uart_tx_lock, "uart");
    800007d0:	00008597          	auipc	a1,0x8
    800007d4:	88858593          	addi	a1,a1,-1912 # 80008058 <digits+0x18>
    800007d8:	00011517          	auipc	a0,0x11
    800007dc:	a7050513          	addi	a0,a0,-1424 # 80011248 <uart_tx_lock>
    800007e0:	00000097          	auipc	ra,0x0
    800007e4:	5de080e7          	jalr	1502(ra) # 80000dbe <initlock>
}
    800007e8:	60a2                	ld	ra,8(sp)
    800007ea:	6402                	ld	s0,0(sp)
    800007ec:	0141                	addi	sp,sp,16
    800007ee:	8082                	ret

00000000800007f0 <uartputc_sync>:
// use interrupts, for use by kernel printf() and
// to echo characters. it spins waiting for the uart's
// output register to be empty.
void
uartputc_sync(int c)
{
    800007f0:	1101                	addi	sp,sp,-32
    800007f2:	ec06                	sd	ra,24(sp)
    800007f4:	e822                	sd	s0,16(sp)
    800007f6:	e426                	sd	s1,8(sp)
    800007f8:	1000                	addi	s0,sp,32
    800007fa:	84aa                	mv	s1,a0
  push_off();
    800007fc:	00000097          	auipc	ra,0x0
    80000800:	606080e7          	jalr	1542(ra) # 80000e02 <push_off>

  if(panicked){
    80000804:	00008797          	auipc	a5,0x8
    80000808:	7fc7a783          	lw	a5,2044(a5) # 80009000 <panicked>
    for(;;)
      ;
  }

  // wait for Transmit Holding Empty to be set in LSR.
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    8000080c:	10000737          	lui	a4,0x10000
  if(panicked){
    80000810:	c391                	beqz	a5,80000814 <uartputc_sync+0x24>
    for(;;)
    80000812:	a001                	j	80000812 <uartputc_sync+0x22>
  while((ReadReg(LSR) & LSR_TX_IDLE) == 0)
    80000814:	00574783          	lbu	a5,5(a4) # 10000005 <_entry-0x6ffffffb>
    80000818:	0ff7f793          	andi	a5,a5,255
    8000081c:	0207f793          	andi	a5,a5,32
    80000820:	dbf5                	beqz	a5,80000814 <uartputc_sync+0x24>
    ;
  WriteReg(THR, c);
    80000822:	0ff4f793          	andi	a5,s1,255
    80000826:	10000737          	lui	a4,0x10000
    8000082a:	00f70023          	sb	a5,0(a4) # 10000000 <_entry-0x70000000>

  pop_off();
    8000082e:	00000097          	auipc	ra,0x0
    80000832:	674080e7          	jalr	1652(ra) # 80000ea2 <pop_off>
}
    80000836:	60e2                	ld	ra,24(sp)
    80000838:	6442                	ld	s0,16(sp)
    8000083a:	64a2                	ld	s1,8(sp)
    8000083c:	6105                	addi	sp,sp,32
    8000083e:	8082                	ret

0000000080000840 <uartstart>:
// called from both the top- and bottom-half.
void
uartstart()
{
  while(1){
    if(uart_tx_w == uart_tx_r){
    80000840:	00008717          	auipc	a4,0x8
    80000844:	7c873703          	ld	a4,1992(a4) # 80009008 <uart_tx_r>
    80000848:	00008797          	auipc	a5,0x8
    8000084c:	7c87b783          	ld	a5,1992(a5) # 80009010 <uart_tx_w>
    80000850:	06e78c63          	beq	a5,a4,800008c8 <uartstart+0x88>
{
    80000854:	7139                	addi	sp,sp,-64
    80000856:	fc06                	sd	ra,56(sp)
    80000858:	f822                	sd	s0,48(sp)
    8000085a:	f426                	sd	s1,40(sp)
    8000085c:	f04a                	sd	s2,32(sp)
    8000085e:	ec4e                	sd	s3,24(sp)
    80000860:	e852                	sd	s4,16(sp)
    80000862:	e456                	sd	s5,8(sp)
    80000864:	0080                	addi	s0,sp,64
      // transmit buffer is empty.
      return;
    }
    
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000866:	10000937          	lui	s2,0x10000
      // so we cannot give it another byte.
      // it will interrupt when it's ready for a new byte.
      return;
    }
    
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    8000086a:	00011a17          	auipc	s4,0x11
    8000086e:	9dea0a13          	addi	s4,s4,-1570 # 80011248 <uart_tx_lock>
    uart_tx_r += 1;
    80000872:	00008497          	auipc	s1,0x8
    80000876:	79648493          	addi	s1,s1,1942 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r){
    8000087a:	00008997          	auipc	s3,0x8
    8000087e:	79698993          	addi	s3,s3,1942 # 80009010 <uart_tx_w>
    if((ReadReg(LSR) & LSR_TX_IDLE) == 0){
    80000882:	00594783          	lbu	a5,5(s2) # 10000005 <_entry-0x6ffffffb>
    80000886:	0ff7f793          	andi	a5,a5,255
    8000088a:	0207f793          	andi	a5,a5,32
    8000088e:	c785                	beqz	a5,800008b6 <uartstart+0x76>
    int c = uart_tx_buf[uart_tx_r % UART_TX_BUF_SIZE];
    80000890:	01f77793          	andi	a5,a4,31
    80000894:	97d2                	add	a5,a5,s4
    80000896:	0187ca83          	lbu	s5,24(a5)
    uart_tx_r += 1;
    8000089a:	0705                	addi	a4,a4,1
    8000089c:	e098                	sd	a4,0(s1)
    
    // maybe uartputc() is waiting for space in the buffer.
    wakeup(&uart_tx_r);
    8000089e:	8526                	mv	a0,s1
    800008a0:	00002097          	auipc	ra,0x2
    800008a4:	bce080e7          	jalr	-1074(ra) # 8000246e <wakeup>
    
    WriteReg(THR, c);
    800008a8:	01590023          	sb	s5,0(s2)
    if(uart_tx_w == uart_tx_r){
    800008ac:	6098                	ld	a4,0(s1)
    800008ae:	0009b783          	ld	a5,0(s3)
    800008b2:	fce798e3          	bne	a5,a4,80000882 <uartstart+0x42>
  }
}
    800008b6:	70e2                	ld	ra,56(sp)
    800008b8:	7442                	ld	s0,48(sp)
    800008ba:	74a2                	ld	s1,40(sp)
    800008bc:	7902                	ld	s2,32(sp)
    800008be:	69e2                	ld	s3,24(sp)
    800008c0:	6a42                	ld	s4,16(sp)
    800008c2:	6aa2                	ld	s5,8(sp)
    800008c4:	6121                	addi	sp,sp,64
    800008c6:	8082                	ret
    800008c8:	8082                	ret

00000000800008ca <uartputc>:
{
    800008ca:	7179                	addi	sp,sp,-48
    800008cc:	f406                	sd	ra,40(sp)
    800008ce:	f022                	sd	s0,32(sp)
    800008d0:	ec26                	sd	s1,24(sp)
    800008d2:	e84a                	sd	s2,16(sp)
    800008d4:	e44e                	sd	s3,8(sp)
    800008d6:	e052                	sd	s4,0(sp)
    800008d8:	1800                	addi	s0,sp,48
    800008da:	89aa                	mv	s3,a0
  acquire(&uart_tx_lock);
    800008dc:	00011517          	auipc	a0,0x11
    800008e0:	96c50513          	addi	a0,a0,-1684 # 80011248 <uart_tx_lock>
    800008e4:	00000097          	auipc	ra,0x0
    800008e8:	56a080e7          	jalr	1386(ra) # 80000e4e <acquire>
  if(panicked){
    800008ec:	00008797          	auipc	a5,0x8
    800008f0:	7147a783          	lw	a5,1812(a5) # 80009000 <panicked>
    800008f4:	c391                	beqz	a5,800008f8 <uartputc+0x2e>
    for(;;)
    800008f6:	a001                	j	800008f6 <uartputc+0x2c>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    800008f8:	00008797          	auipc	a5,0x8
    800008fc:	7187b783          	ld	a5,1816(a5) # 80009010 <uart_tx_w>
    80000900:	00008717          	auipc	a4,0x8
    80000904:	70873703          	ld	a4,1800(a4) # 80009008 <uart_tx_r>
    80000908:	02070713          	addi	a4,a4,32
    8000090c:	02f71b63          	bne	a4,a5,80000942 <uartputc+0x78>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000910:	00011a17          	auipc	s4,0x11
    80000914:	938a0a13          	addi	s4,s4,-1736 # 80011248 <uart_tx_lock>
    80000918:	00008497          	auipc	s1,0x8
    8000091c:	6f048493          	addi	s1,s1,1776 # 80009008 <uart_tx_r>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000920:	00008917          	auipc	s2,0x8
    80000924:	6f090913          	addi	s2,s2,1776 # 80009010 <uart_tx_w>
      sleep(&uart_tx_r, &uart_tx_lock);
    80000928:	85d2                	mv	a1,s4
    8000092a:	8526                	mv	a0,s1
    8000092c:	00002097          	auipc	ra,0x2
    80000930:	9b6080e7          	jalr	-1610(ra) # 800022e2 <sleep>
    if(uart_tx_w == uart_tx_r + UART_TX_BUF_SIZE){
    80000934:	00093783          	ld	a5,0(s2)
    80000938:	6098                	ld	a4,0(s1)
    8000093a:	02070713          	addi	a4,a4,32
    8000093e:	fef705e3          	beq	a4,a5,80000928 <uartputc+0x5e>
      uart_tx_buf[uart_tx_w % UART_TX_BUF_SIZE] = c;
    80000942:	00011497          	auipc	s1,0x11
    80000946:	90648493          	addi	s1,s1,-1786 # 80011248 <uart_tx_lock>
    8000094a:	01f7f713          	andi	a4,a5,31
    8000094e:	9726                	add	a4,a4,s1
    80000950:	01370c23          	sb	s3,24(a4)
      uart_tx_w += 1;
    80000954:	0785                	addi	a5,a5,1
    80000956:	00008717          	auipc	a4,0x8
    8000095a:	6af73d23          	sd	a5,1722(a4) # 80009010 <uart_tx_w>
      uartstart();
    8000095e:	00000097          	auipc	ra,0x0
    80000962:	ee2080e7          	jalr	-286(ra) # 80000840 <uartstart>
      release(&uart_tx_lock);
    80000966:	8526                	mv	a0,s1
    80000968:	00000097          	auipc	ra,0x0
    8000096c:	59a080e7          	jalr	1434(ra) # 80000f02 <release>
}
    80000970:	70a2                	ld	ra,40(sp)
    80000972:	7402                	ld	s0,32(sp)
    80000974:	64e2                	ld	s1,24(sp)
    80000976:	6942                	ld	s2,16(sp)
    80000978:	69a2                	ld	s3,8(sp)
    8000097a:	6a02                	ld	s4,0(sp)
    8000097c:	6145                	addi	sp,sp,48
    8000097e:	8082                	ret

0000000080000980 <uartgetc>:

// read one input character from the UART.
// return -1 if none is waiting.
int
uartgetc(void)
{
    80000980:	1141                	addi	sp,sp,-16
    80000982:	e422                	sd	s0,8(sp)
    80000984:	0800                	addi	s0,sp,16
  if(ReadReg(LSR) & 0x01){
    80000986:	100007b7          	lui	a5,0x10000
    8000098a:	0057c783          	lbu	a5,5(a5) # 10000005 <_entry-0x6ffffffb>
    8000098e:	8b85                	andi	a5,a5,1
    80000990:	cb91                	beqz	a5,800009a4 <uartgetc+0x24>
    // input data is ready.
    return ReadReg(RHR);
    80000992:	100007b7          	lui	a5,0x10000
    80000996:	0007c503          	lbu	a0,0(a5) # 10000000 <_entry-0x70000000>
    8000099a:	0ff57513          	andi	a0,a0,255
  } else {
    return -1;
  }
}
    8000099e:	6422                	ld	s0,8(sp)
    800009a0:	0141                	addi	sp,sp,16
    800009a2:	8082                	ret
    return -1;
    800009a4:	557d                	li	a0,-1
    800009a6:	bfe5                	j	8000099e <uartgetc+0x1e>

00000000800009a8 <uartintr>:
// handle a uart interrupt, raised because input has
// arrived, or the uart is ready for more output, or
// both. called from trap.c.
void
uartintr(void)
{
    800009a8:	1101                	addi	sp,sp,-32
    800009aa:	ec06                	sd	ra,24(sp)
    800009ac:	e822                	sd	s0,16(sp)
    800009ae:	e426                	sd	s1,8(sp)
    800009b0:	1000                	addi	s0,sp,32
  // read and process incoming characters.
  while(1){
    int c = uartgetc();
    if(c == -1)
    800009b2:	54fd                	li	s1,-1
    int c = uartgetc();
    800009b4:	00000097          	auipc	ra,0x0
    800009b8:	fcc080e7          	jalr	-52(ra) # 80000980 <uartgetc>
    if(c == -1)
    800009bc:	00950763          	beq	a0,s1,800009ca <uartintr+0x22>
      break;
    consoleintr(c);
    800009c0:	00000097          	auipc	ra,0x0
    800009c4:	8fe080e7          	jalr	-1794(ra) # 800002be <consoleintr>
  while(1){
    800009c8:	b7f5                	j	800009b4 <uartintr+0xc>
  }

  // send buffered characters.
  acquire(&uart_tx_lock);
    800009ca:	00011497          	auipc	s1,0x11
    800009ce:	87e48493          	addi	s1,s1,-1922 # 80011248 <uart_tx_lock>
    800009d2:	8526                	mv	a0,s1
    800009d4:	00000097          	auipc	ra,0x0
    800009d8:	47a080e7          	jalr	1146(ra) # 80000e4e <acquire>
  uartstart();
    800009dc:	00000097          	auipc	ra,0x0
    800009e0:	e64080e7          	jalr	-412(ra) # 80000840 <uartstart>
  release(&uart_tx_lock);
    800009e4:	8526                	mv	a0,s1
    800009e6:	00000097          	auipc	ra,0x0
    800009ea:	51c080e7          	jalr	1308(ra) # 80000f02 <release>
}
    800009ee:	60e2                	ld	ra,24(sp)
    800009f0:	6442                	ld	s0,16(sp)
    800009f2:	64a2                	ld	s1,8(sp)
    800009f4:	6105                	addi	sp,sp,32
    800009f6:	8082                	ret

00000000800009f8 <_kfree>:
}

// Called by _freerange, which is only called by kinit.
void
_kfree(void *pa)
{
    800009f8:	1101                	addi	sp,sp,-32
    800009fa:	ec06                	sd	ra,24(sp)
    800009fc:	e822                	sd	s0,16(sp)
    800009fe:	e426                	sd	s1,8(sp)
    80000a00:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000a02:	03451793          	slli	a5,a0,0x34
    80000a06:	efb1                	bnez	a5,80000a62 <_kfree+0x6a>
    80000a08:	84aa                	mv	s1,a0
    80000a0a:	008a5797          	auipc	a5,0x8a5
    80000a0e:	5f678793          	addi	a5,a5,1526 # 808a6000 <end>
    80000a12:	04f56863          	bltu	a0,a5,80000a62 <_kfree+0x6a>
    80000a16:	47c5                	li	a5,17
    80000a18:	07ee                	slli	a5,a5,0x1b
    80000a1a:	04f57463          	bgeu	a0,a5,80000a62 <_kfree+0x6a>
    panic("_kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000a1e:	6605                	lui	a2,0x1
    80000a20:	4585                	li	a1,1
    80000a22:	00000097          	auipc	ra,0x0
    80000a26:	528080e7          	jalr	1320(ra) # 80000f4a <memset>

  r = &kmem.runs[(uint64)pa / PGSIZE];
    80000a2a:	80b1                	srli	s1,s1,0xc

  acquire(&kmem.lock);
    80000a2c:	00011517          	auipc	a0,0x11
    80000a30:	85450513          	addi	a0,a0,-1964 # 80011280 <kmem>
    80000a34:	00000097          	auipc	ra,0x0
    80000a38:	41a080e7          	jalr	1050(ra) # 80000e4e <acquire>
  r->next = kmem.freelist;
    80000a3c:	00011517          	auipc	a0,0x11
    80000a40:	84450513          	addi	a0,a0,-1980 # 80011280 <kmem>
    80000a44:	0489                	addi	s1,s1,2
    80000a46:	0492                	slli	s1,s1,0x4
    80000a48:	94aa                	add	s1,s1,a0
    80000a4a:	6d1c                	ld	a5,24(a0)
    80000a4c:	e09c                	sd	a5,0(s1)
  kmem.freelist = r;
    80000a4e:	ed04                	sd	s1,24(a0)
  release(&kmem.lock);
    80000a50:	00000097          	auipc	ra,0x0
    80000a54:	4b2080e7          	jalr	1202(ra) # 80000f02 <release>
}
    80000a58:	60e2                	ld	ra,24(sp)
    80000a5a:	6442                	ld	s0,16(sp)
    80000a5c:	64a2                	ld	s1,8(sp)
    80000a5e:	6105                	addi	sp,sp,32
    80000a60:	8082                	ret
    panic("_kfree");
    80000a62:	00007517          	auipc	a0,0x7
    80000a66:	5fe50513          	addi	a0,a0,1534 # 80008060 <digits+0x20>
    80000a6a:	00000097          	auipc	ra,0x0
    80000a6e:	ad4080e7          	jalr	-1324(ra) # 8000053e <panic>

0000000080000a72 <_freerange>:
{
    80000a72:	7179                	addi	sp,sp,-48
    80000a74:	f406                	sd	ra,40(sp)
    80000a76:	f022                	sd	s0,32(sp)
    80000a78:	ec26                	sd	s1,24(sp)
    80000a7a:	e84a                	sd	s2,16(sp)
    80000a7c:	e44e                	sd	s3,8(sp)
    80000a7e:	e052                	sd	s4,0(sp)
    80000a80:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000a82:	6785                	lui	a5,0x1
    80000a84:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000a88:	94aa                	add	s1,s1,a0
    80000a8a:	757d                	lui	a0,0xfffff
    80000a8c:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a8e:	94be                	add	s1,s1,a5
    80000a90:	0095ee63          	bltu	a1,s1,80000aac <_freerange+0x3a>
    80000a94:	892e                	mv	s2,a1
    _kfree(p);
    80000a96:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000a98:	6985                	lui	s3,0x1
    _kfree(p);
    80000a9a:	01448533          	add	a0,s1,s4
    80000a9e:	00000097          	auipc	ra,0x0
    80000aa2:	f5a080e7          	jalr	-166(ra) # 800009f8 <_kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000aa6:	94ce                	add	s1,s1,s3
    80000aa8:	fe9979e3          	bgeu	s2,s1,80000a9a <_freerange+0x28>
}
    80000aac:	70a2                	ld	ra,40(sp)
    80000aae:	7402                	ld	s0,32(sp)
    80000ab0:	64e2                	ld	s1,24(sp)
    80000ab2:	6942                	ld	s2,16(sp)
    80000ab4:	69a2                	ld	s3,8(sp)
    80000ab6:	6a02                	ld	s4,0(sp)
    80000ab8:	6145                	addi	sp,sp,48
    80000aba:	8082                	ret

0000000080000abc <kinit>:
{
    80000abc:	1141                	addi	sp,sp,-16
    80000abe:	e406                	sd	ra,8(sp)
    80000ac0:	e022                	sd	s0,0(sp)
    80000ac2:	0800                	addi	s0,sp,16
  initlock(&kmem.lock, "kmem");
    80000ac4:	00007597          	auipc	a1,0x7
    80000ac8:	5a458593          	addi	a1,a1,1444 # 80008068 <digits+0x28>
    80000acc:	00010517          	auipc	a0,0x10
    80000ad0:	7b450513          	addi	a0,a0,1972 # 80011280 <kmem>
    80000ad4:	00000097          	auipc	ra,0x0
    80000ad8:	2ea080e7          	jalr	746(ra) # 80000dbe <initlock>
  _freerange(end, (void*)PHYSTOP);
    80000adc:	45c5                	li	a1,17
    80000ade:	05ee                	slli	a1,a1,0x1b
    80000ae0:	008a5517          	auipc	a0,0x8a5
    80000ae4:	52050513          	addi	a0,a0,1312 # 808a6000 <end>
    80000ae8:	00000097          	auipc	ra,0x0
    80000aec:	f8a080e7          	jalr	-118(ra) # 80000a72 <_freerange>
}
    80000af0:	60a2                	ld	ra,8(sp)
    80000af2:	6402                	ld	s0,0(sp)
    80000af4:	0141                	addi	sp,sp,16
    80000af6:	8082                	ret

0000000080000af8 <kfree>:
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void
kfree(void *pa)
{
    80000af8:	1101                	addi	sp,sp,-32
    80000afa:	ec06                	sd	ra,24(sp)
    80000afc:	e822                	sd	s0,16(sp)
    80000afe:	e426                	sd	s1,8(sp)
    80000b00:	e04a                	sd	s2,0(sp)
    80000b02:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000b04:	03451793          	slli	a5,a0,0x34
    80000b08:	efb5                	bnez	a5,80000b84 <kfree+0x8c>
    80000b0a:	84aa                	mv	s1,a0
    80000b0c:	008a5797          	auipc	a5,0x8a5
    80000b10:	4f478793          	addi	a5,a5,1268 # 808a6000 <end>
    80000b14:	06f56863          	bltu	a0,a5,80000b84 <kfree+0x8c>
    80000b18:	47c5                	li	a5,17
    80000b1a:	07ee                	slli	a5,a5,0x1b
    80000b1c:	06f57463          	bgeu	a0,a5,80000b84 <kfree+0x8c>
    panic("kfree");

  // Fill with junk to catch dangling refs.
  memset(pa, 1, PGSIZE);
    80000b20:	6605                	lui	a2,0x1
    80000b22:	4585                	li	a1,1
    80000b24:	00000097          	auipc	ra,0x0
    80000b28:	426080e7          	jalr	1062(ra) # 80000f4a <memset>

  r = &kmem.runs[(uint64)pa / PGSIZE];
    80000b2c:	80b1                	srli	s1,s1,0xc
    80000b2e:	00248913          	addi	s2,s1,2
    80000b32:	0912                	slli	s2,s2,0x4
    80000b34:	00010797          	auipc	a5,0x10
    80000b38:	74c78793          	addi	a5,a5,1868 # 80011280 <kmem>
    80000b3c:	993e                	add	s2,s2,a5
  if (r->ref != 1) {
    80000b3e:	00892703          	lw	a4,8(s2)
    80000b42:	4785                	li	a5,1
    80000b44:	04f71863          	bne	a4,a5,80000b94 <kfree+0x9c>
    printf("kfree: assert ref == 1 failed\n");
    printf("0x%x %d\n", r, r->ref);
    exit(-1);
  }
  
  acquire(&kmem.lock);
    80000b48:	00010517          	auipc	a0,0x10
    80000b4c:	73850513          	addi	a0,a0,1848 # 80011280 <kmem>
    80000b50:	00000097          	auipc	ra,0x0
    80000b54:	2fe080e7          	jalr	766(ra) # 80000e4e <acquire>
  r->next = kmem.freelist;
    80000b58:	00010517          	auipc	a0,0x10
    80000b5c:	72850513          	addi	a0,a0,1832 # 80011280 <kmem>
    80000b60:	00248793          	addi	a5,s1,2
    80000b64:	0792                	slli	a5,a5,0x4
    80000b66:	97aa                	add	a5,a5,a0
    80000b68:	6d18                	ld	a4,24(a0)
    80000b6a:	e398                	sd	a4,0(a5)
  kmem.freelist = r;
    80000b6c:	01253c23          	sd	s2,24(a0)
  release(&kmem.lock);
    80000b70:	00000097          	auipc	ra,0x0
    80000b74:	392080e7          	jalr	914(ra) # 80000f02 <release>
}
    80000b78:	60e2                	ld	ra,24(sp)
    80000b7a:	6442                	ld	s0,16(sp)
    80000b7c:	64a2                	ld	s1,8(sp)
    80000b7e:	6902                	ld	s2,0(sp)
    80000b80:	6105                	addi	sp,sp,32
    80000b82:	8082                	ret
    panic("kfree");
    80000b84:	00007517          	auipc	a0,0x7
    80000b88:	4ec50513          	addi	a0,a0,1260 # 80008070 <digits+0x30>
    80000b8c:	00000097          	auipc	ra,0x0
    80000b90:	9b2080e7          	jalr	-1614(ra) # 8000053e <panic>
    printf("kfree: assert ref == 1 failed\n");
    80000b94:	00007517          	auipc	a0,0x7
    80000b98:	4e450513          	addi	a0,a0,1252 # 80008078 <digits+0x38>
    80000b9c:	00000097          	auipc	ra,0x0
    80000ba0:	9ec080e7          	jalr	-1556(ra) # 80000588 <printf>
    printf("0x%x %d\n", r, r->ref);
    80000ba4:	00892603          	lw	a2,8(s2)
    80000ba8:	85ca                	mv	a1,s2
    80000baa:	00007517          	auipc	a0,0x7
    80000bae:	4ee50513          	addi	a0,a0,1262 # 80008098 <digits+0x58>
    80000bb2:	00000097          	auipc	ra,0x0
    80000bb6:	9d6080e7          	jalr	-1578(ra) # 80000588 <printf>
    exit(-1);
    80000bba:	557d                	li	a0,-1
    80000bbc:	00002097          	auipc	ra,0x2
    80000bc0:	982080e7          	jalr	-1662(ra) # 8000253e <exit>
    80000bc4:	b751                	j	80000b48 <kfree+0x50>

0000000080000bc6 <freerange>:
{
    80000bc6:	7179                	addi	sp,sp,-48
    80000bc8:	f406                	sd	ra,40(sp)
    80000bca:	f022                	sd	s0,32(sp)
    80000bcc:	ec26                	sd	s1,24(sp)
    80000bce:	e84a                	sd	s2,16(sp)
    80000bd0:	e44e                	sd	s3,8(sp)
    80000bd2:	e052                	sd	s4,0(sp)
    80000bd4:	1800                	addi	s0,sp,48
  p = (char*)PGROUNDUP((uint64)pa_start);
    80000bd6:	6785                	lui	a5,0x1
    80000bd8:	fff78493          	addi	s1,a5,-1 # fff <_entry-0x7ffff001>
    80000bdc:	94aa                	add	s1,s1,a0
    80000bde:	757d                	lui	a0,0xfffff
    80000be0:	8ce9                	and	s1,s1,a0
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000be2:	94be                	add	s1,s1,a5
    80000be4:	0095ee63          	bltu	a1,s1,80000c00 <freerange+0x3a>
    80000be8:	892e                	mv	s2,a1
    kfree(p);
    80000bea:	7a7d                	lui	s4,0xfffff
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000bec:	6985                	lui	s3,0x1
    kfree(p);
    80000bee:	01448533          	add	a0,s1,s4
    80000bf2:	00000097          	auipc	ra,0x0
    80000bf6:	f06080e7          	jalr	-250(ra) # 80000af8 <kfree>
  for(; p + PGSIZE <= (char*)pa_end; p += PGSIZE)
    80000bfa:	94ce                	add	s1,s1,s3
    80000bfc:	fe9979e3          	bgeu	s2,s1,80000bee <freerange+0x28>
}
    80000c00:	70a2                	ld	ra,40(sp)
    80000c02:	7402                	ld	s0,32(sp)
    80000c04:	64e2                	ld	s1,24(sp)
    80000c06:	6942                	ld	s2,16(sp)
    80000c08:	69a2                	ld	s3,8(sp)
    80000c0a:	6a02                	ld	s4,0(sp)
    80000c0c:	6145                	addi	sp,sp,48
    80000c0e:	8082                	ret

0000000080000c10 <kalloc>:
// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
    80000c10:	1101                	addi	sp,sp,-32
    80000c12:	ec06                	sd	ra,24(sp)
    80000c14:	e822                	sd	s0,16(sp)
    80000c16:	e426                	sd	s1,8(sp)
    80000c18:	1000                	addi	s0,sp,32
  struct run *r;

  acquire(&kmem.lock);
    80000c1a:	00010517          	auipc	a0,0x10
    80000c1e:	66650513          	addi	a0,a0,1638 # 80011280 <kmem>
    80000c22:	00000097          	auipc	ra,0x0
    80000c26:	22c080e7          	jalr	556(ra) # 80000e4e <acquire>
  r = kmem.freelist;
    80000c2a:	00010497          	auipc	s1,0x10
    80000c2e:	66e4b483          	ld	s1,1646(s1) # 80011298 <kmem+0x18>
  if(r){
    80000c32:	c4b1                	beqz	s1,80000c7e <kalloc+0x6e>
    r->ref = 1;
    80000c34:	4785                	li	a5,1
    80000c36:	c49c                	sw	a5,8(s1)
    kmem.freelist = r->next;
    80000c38:	609c                	ld	a5,0(s1)
    80000c3a:	00010517          	auipc	a0,0x10
    80000c3e:	64650513          	addi	a0,a0,1606 # 80011280 <kmem>
    80000c42:	ed1c                	sd	a5,24(a0)
  }
  release(&kmem.lock);
    80000c44:	00000097          	auipc	ra,0x0
    80000c48:	2be080e7          	jalr	702(ra) # 80000f02 <release>

  if(r)
    memset((char*)((r - kmem.runs) * PGSIZE), 5, PGSIZE); // fill with junk
    80000c4c:	00010517          	auipc	a0,0x10
    80000c50:	65450513          	addi	a0,a0,1620 # 800112a0 <kmem+0x20>
    80000c54:	40a48533          	sub	a0,s1,a0
    80000c58:	6605                	lui	a2,0x1
    80000c5a:	4595                	li	a1,5
    80000c5c:	0522                	slli	a0,a0,0x8
    80000c5e:	00000097          	auipc	ra,0x0
    80000c62:	2ec080e7          	jalr	748(ra) # 80000f4a <memset>
  return (void*)((r - kmem.runs) * PGSIZE);
    80000c66:	00010517          	auipc	a0,0x10
    80000c6a:	63a50513          	addi	a0,a0,1594 # 800112a0 <kmem+0x20>
    80000c6e:	40a48533          	sub	a0,s1,a0
    80000c72:	0522                	slli	a0,a0,0x8
}
    80000c74:	60e2                	ld	ra,24(sp)
    80000c76:	6442                	ld	s0,16(sp)
    80000c78:	64a2                	ld	s1,8(sp)
    80000c7a:	6105                	addi	sp,sp,32
    80000c7c:	8082                	ret
  release(&kmem.lock);
    80000c7e:	00010517          	auipc	a0,0x10
    80000c82:	60250513          	addi	a0,a0,1538 # 80011280 <kmem>
    80000c86:	00000097          	auipc	ra,0x0
    80000c8a:	27c080e7          	jalr	636(ra) # 80000f02 <release>
  if(r)
    80000c8e:	bfe1                	j	80000c66 <kalloc+0x56>

0000000080000c90 <incref>:
/**
 * Increment the reference count of a page descriptor.
 */
void
incref(void *pa)
{
    80000c90:	1101                	addi	sp,sp,-32
    80000c92:	ec06                	sd	ra,24(sp)
    80000c94:	e822                	sd	s0,16(sp)
    80000c96:	e426                	sd	s1,8(sp)
    80000c98:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000c9a:	03451793          	slli	a5,a0,0x34
    80000c9e:	eba1                	bnez	a5,80000cee <incref+0x5e>
    80000ca0:	84aa                	mv	s1,a0
    80000ca2:	008a5797          	auipc	a5,0x8a5
    80000ca6:	35e78793          	addi	a5,a5,862 # 808a6000 <end>
    80000caa:	04f56263          	bltu	a0,a5,80000cee <incref+0x5e>
    80000cae:	47c5                	li	a5,17
    80000cb0:	07ee                	slli	a5,a5,0x1b
    80000cb2:	02f57e63          	bgeu	a0,a5,80000cee <incref+0x5e>
    panic("incref");

  acquire(&kmem.lock);
    80000cb6:	00010517          	auipc	a0,0x10
    80000cba:	5ca50513          	addi	a0,a0,1482 # 80011280 <kmem>
    80000cbe:	00000097          	auipc	ra,0x0
    80000cc2:	190080e7          	jalr	400(ra) # 80000e4e <acquire>
  r = &kmem.runs[(uint64)pa / PGSIZE];
    80000cc6:	80b1                	srli	s1,s1,0xc
  r->ref++;
    80000cc8:	00010517          	auipc	a0,0x10
    80000ccc:	5b850513          	addi	a0,a0,1464 # 80011280 <kmem>
    80000cd0:	0489                	addi	s1,s1,2
    80000cd2:	0492                	slli	s1,s1,0x4
    80000cd4:	94aa                	add	s1,s1,a0
    80000cd6:	449c                	lw	a5,8(s1)
    80000cd8:	2785                	addiw	a5,a5,1
    80000cda:	c49c                	sw	a5,8(s1)
  release(&kmem.lock);
    80000cdc:	00000097          	auipc	ra,0x0
    80000ce0:	226080e7          	jalr	550(ra) # 80000f02 <release>
}
    80000ce4:	60e2                	ld	ra,24(sp)
    80000ce6:	6442                	ld	s0,16(sp)
    80000ce8:	64a2                	ld	s1,8(sp)
    80000cea:	6105                	addi	sp,sp,32
    80000cec:	8082                	ret
    panic("incref");
    80000cee:	00007517          	auipc	a0,0x7
    80000cf2:	3ba50513          	addi	a0,a0,954 # 800080a8 <digits+0x68>
    80000cf6:	00000097          	auipc	ra,0x0
    80000cfa:	848080e7          	jalr	-1976(ra) # 8000053e <panic>

0000000080000cfe <decref>:
/**
 * Decrement the reference count of a page descriptor.
 */
void
decref(void *pa)
{
    80000cfe:	1101                	addi	sp,sp,-32
    80000d00:	ec06                	sd	ra,24(sp)
    80000d02:	e822                	sd	s0,16(sp)
    80000d04:	e426                	sd	s1,8(sp)
    80000d06:	1000                	addi	s0,sp,32
  struct run *r;

  if(((uint64)pa % PGSIZE) != 0 || (char*)pa < end || (uint64)pa >= PHYSTOP)
    80000d08:	03451793          	slli	a5,a0,0x34
    80000d0c:	eba1                	bnez	a5,80000d5c <decref+0x5e>
    80000d0e:	84aa                	mv	s1,a0
    80000d10:	008a5797          	auipc	a5,0x8a5
    80000d14:	2f078793          	addi	a5,a5,752 # 808a6000 <end>
    80000d18:	04f56263          	bltu	a0,a5,80000d5c <decref+0x5e>
    80000d1c:	47c5                	li	a5,17
    80000d1e:	07ee                	slli	a5,a5,0x1b
    80000d20:	02f57e63          	bgeu	a0,a5,80000d5c <decref+0x5e>
    panic("decref");

  acquire(&kmem.lock);
    80000d24:	00010517          	auipc	a0,0x10
    80000d28:	55c50513          	addi	a0,a0,1372 # 80011280 <kmem>
    80000d2c:	00000097          	auipc	ra,0x0
    80000d30:	122080e7          	jalr	290(ra) # 80000e4e <acquire>
  r = &kmem.runs[(uint64)pa / PGSIZE];
    80000d34:	80b1                	srli	s1,s1,0xc
  r->ref--;
    80000d36:	00010517          	auipc	a0,0x10
    80000d3a:	54a50513          	addi	a0,a0,1354 # 80011280 <kmem>
    80000d3e:	0489                	addi	s1,s1,2
    80000d40:	0492                	slli	s1,s1,0x4
    80000d42:	94aa                	add	s1,s1,a0
    80000d44:	449c                	lw	a5,8(s1)
    80000d46:	37fd                	addiw	a5,a5,-1
    80000d48:	c49c                	sw	a5,8(s1)
  release(&kmem.lock);
    80000d4a:	00000097          	auipc	ra,0x0
    80000d4e:	1b8080e7          	jalr	440(ra) # 80000f02 <release>
}
    80000d52:	60e2                	ld	ra,24(sp)
    80000d54:	6442                	ld	s0,16(sp)
    80000d56:	64a2                	ld	s1,8(sp)
    80000d58:	6105                	addi	sp,sp,32
    80000d5a:	8082                	ret
    panic("decref");
    80000d5c:	00007517          	auipc	a0,0x7
    80000d60:	35450513          	addi	a0,a0,852 # 800080b0 <digits+0x70>
    80000d64:	fffff097          	auipc	ra,0xfffff
    80000d68:	7da080e7          	jalr	2010(ra) # 8000053e <panic>

0000000080000d6c <getref>:
/**
 * Get reference count of a page descriptor.
 */
uint
getref(void *pa)
{
    80000d6c:	1141                	addi	sp,sp,-16
    80000d6e:	e422                	sd	s0,8(sp)
    80000d70:	0800                	addi	s0,sp,16
  struct run *r = &kmem.runs[(uint64)pa / PGSIZE];
    80000d72:	8131                	srli	a0,a0,0xc
  return r->ref;
    80000d74:	0509                	addi	a0,a0,2
    80000d76:	0512                	slli	a0,a0,0x4
    80000d78:	00010797          	auipc	a5,0x10
    80000d7c:	50878793          	addi	a5,a5,1288 # 80011280 <kmem>
    80000d80:	953e                	add	a0,a0,a5
}
    80000d82:	4508                	lw	a0,8(a0)
    80000d84:	6422                	ld	s0,8(sp)
    80000d86:	0141                	addi	sp,sp,16
    80000d88:	8082                	ret

0000000080000d8a <printref>:
/**
 * Print reference count of a page descriptor.
 */
void
printref(char *pa)
{
    80000d8a:	1141                	addi	sp,sp,-16
    80000d8c:	e406                	sd	ra,8(sp)
    80000d8e:	e022                	sd	s0,0(sp)
    80000d90:	0800                	addi	s0,sp,16
  struct run *r = &kmem.runs[(uint64)pa / PGSIZE];
    80000d92:	00c55593          	srli	a1,a0,0xc
  printf("printref: address: 0x%p, ref: %d\n", r, r->ref);
    80000d96:	0589                	addi	a1,a1,2
    80000d98:	0592                	slli	a1,a1,0x4
    80000d9a:	00010797          	auipc	a5,0x10
    80000d9e:	4e678793          	addi	a5,a5,1254 # 80011280 <kmem>
    80000da2:	95be                	add	a1,a1,a5
    80000da4:	4590                	lw	a2,8(a1)
    80000da6:	00007517          	auipc	a0,0x7
    80000daa:	31250513          	addi	a0,a0,786 # 800080b8 <digits+0x78>
    80000dae:	fffff097          	auipc	ra,0xfffff
    80000db2:	7da080e7          	jalr	2010(ra) # 80000588 <printf>
}
    80000db6:	60a2                	ld	ra,8(sp)
    80000db8:	6402                	ld	s0,0(sp)
    80000dba:	0141                	addi	sp,sp,16
    80000dbc:	8082                	ret

0000000080000dbe <initlock>:
#include "proc.h"
#include "defs.h"

void
initlock(struct spinlock *lk, char *name)
{
    80000dbe:	1141                	addi	sp,sp,-16
    80000dc0:	e422                	sd	s0,8(sp)
    80000dc2:	0800                	addi	s0,sp,16
  lk->name = name;
    80000dc4:	e50c                	sd	a1,8(a0)
  lk->locked = 0;
    80000dc6:	00052023          	sw	zero,0(a0)
  lk->cpu = 0;
    80000dca:	00053823          	sd	zero,16(a0)
}
    80000dce:	6422                	ld	s0,8(sp)
    80000dd0:	0141                	addi	sp,sp,16
    80000dd2:	8082                	ret

0000000080000dd4 <holding>:
// Interrupts must be off.
int
holding(struct spinlock *lk)
{
  int r;
  r = (lk->locked && lk->cpu == mycpu());
    80000dd4:	411c                	lw	a5,0(a0)
    80000dd6:	e399                	bnez	a5,80000ddc <holding+0x8>
    80000dd8:	4501                	li	a0,0
  return r;
}
    80000dda:	8082                	ret
{
    80000ddc:	1101                	addi	sp,sp,-32
    80000dde:	ec06                	sd	ra,24(sp)
    80000de0:	e822                	sd	s0,16(sp)
    80000de2:	e426                	sd	s1,8(sp)
    80000de4:	1000                	addi	s0,sp,32
  r = (lk->locked && lk->cpu == mycpu());
    80000de6:	6904                	ld	s1,16(a0)
    80000de8:	00001097          	auipc	ra,0x1
    80000dec:	e16080e7          	jalr	-490(ra) # 80001bfe <mycpu>
    80000df0:	40a48533          	sub	a0,s1,a0
    80000df4:	00153513          	seqz	a0,a0
}
    80000df8:	60e2                	ld	ra,24(sp)
    80000dfa:	6442                	ld	s0,16(sp)
    80000dfc:	64a2                	ld	s1,8(sp)
    80000dfe:	6105                	addi	sp,sp,32
    80000e00:	8082                	ret

0000000080000e02 <push_off>:
// it takes two pop_off()s to undo two push_off()s.  Also, if interrupts
// are initially off, then push_off, pop_off leaves them off.

void
push_off(void)
{
    80000e02:	1101                	addi	sp,sp,-32
    80000e04:	ec06                	sd	ra,24(sp)
    80000e06:	e822                	sd	s0,16(sp)
    80000e08:	e426                	sd	s1,8(sp)
    80000e0a:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000e0c:	100024f3          	csrr	s1,sstatus
    80000e10:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    80000e14:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000e16:	10079073          	csrw	sstatus,a5
  int old = intr_get();

  intr_off();
  if(mycpu()->noff == 0)
    80000e1a:	00001097          	auipc	ra,0x1
    80000e1e:	de4080e7          	jalr	-540(ra) # 80001bfe <mycpu>
    80000e22:	5d3c                	lw	a5,120(a0)
    80000e24:	cf89                	beqz	a5,80000e3e <push_off+0x3c>
    mycpu()->intena = old;
  mycpu()->noff += 1;
    80000e26:	00001097          	auipc	ra,0x1
    80000e2a:	dd8080e7          	jalr	-552(ra) # 80001bfe <mycpu>
    80000e2e:	5d3c                	lw	a5,120(a0)
    80000e30:	2785                	addiw	a5,a5,1
    80000e32:	dd3c                	sw	a5,120(a0)
}
    80000e34:	60e2                	ld	ra,24(sp)
    80000e36:	6442                	ld	s0,16(sp)
    80000e38:	64a2                	ld	s1,8(sp)
    80000e3a:	6105                	addi	sp,sp,32
    80000e3c:	8082                	ret
    mycpu()->intena = old;
    80000e3e:	00001097          	auipc	ra,0x1
    80000e42:	dc0080e7          	jalr	-576(ra) # 80001bfe <mycpu>
  return (x & SSTATUS_SIE) != 0;
    80000e46:	8085                	srli	s1,s1,0x1
    80000e48:	8885                	andi	s1,s1,1
    80000e4a:	dd64                	sw	s1,124(a0)
    80000e4c:	bfe9                	j	80000e26 <push_off+0x24>

0000000080000e4e <acquire>:
{
    80000e4e:	1101                	addi	sp,sp,-32
    80000e50:	ec06                	sd	ra,24(sp)
    80000e52:	e822                	sd	s0,16(sp)
    80000e54:	e426                	sd	s1,8(sp)
    80000e56:	1000                	addi	s0,sp,32
    80000e58:	84aa                	mv	s1,a0
  push_off(); // disable interrupts to avoid deadlock.
    80000e5a:	00000097          	auipc	ra,0x0
    80000e5e:	fa8080e7          	jalr	-88(ra) # 80000e02 <push_off>
  if(holding(lk))
    80000e62:	8526                	mv	a0,s1
    80000e64:	00000097          	auipc	ra,0x0
    80000e68:	f70080e7          	jalr	-144(ra) # 80000dd4 <holding>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000e6c:	4705                	li	a4,1
  if(holding(lk))
    80000e6e:	e115                	bnez	a0,80000e92 <acquire+0x44>
  while(__sync_lock_test_and_set(&lk->locked, 1) != 0)
    80000e70:	87ba                	mv	a5,a4
    80000e72:	0cf4a7af          	amoswap.w.aq	a5,a5,(s1)
    80000e76:	2781                	sext.w	a5,a5
    80000e78:	ffe5                	bnez	a5,80000e70 <acquire+0x22>
  __sync_synchronize();
    80000e7a:	0ff0000f          	fence
  lk->cpu = mycpu();
    80000e7e:	00001097          	auipc	ra,0x1
    80000e82:	d80080e7          	jalr	-640(ra) # 80001bfe <mycpu>
    80000e86:	e888                	sd	a0,16(s1)
}
    80000e88:	60e2                	ld	ra,24(sp)
    80000e8a:	6442                	ld	s0,16(sp)
    80000e8c:	64a2                	ld	s1,8(sp)
    80000e8e:	6105                	addi	sp,sp,32
    80000e90:	8082                	ret
    panic("acquire");
    80000e92:	00007517          	auipc	a0,0x7
    80000e96:	24e50513          	addi	a0,a0,590 # 800080e0 <digits+0xa0>
    80000e9a:	fffff097          	auipc	ra,0xfffff
    80000e9e:	6a4080e7          	jalr	1700(ra) # 8000053e <panic>

0000000080000ea2 <pop_off>:

void
pop_off(void)
{
    80000ea2:	1141                	addi	sp,sp,-16
    80000ea4:	e406                	sd	ra,8(sp)
    80000ea6:	e022                	sd	s0,0(sp)
    80000ea8:	0800                	addi	s0,sp,16
  struct cpu *c = mycpu();
    80000eaa:	00001097          	auipc	ra,0x1
    80000eae:	d54080e7          	jalr	-684(ra) # 80001bfe <mycpu>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000eb2:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80000eb6:	8b89                	andi	a5,a5,2
  if(intr_get())
    80000eb8:	e78d                	bnez	a5,80000ee2 <pop_off+0x40>
    panic("pop_off - interruptible");
  if(c->noff < 1)
    80000eba:	5d3c                	lw	a5,120(a0)
    80000ebc:	02f05b63          	blez	a5,80000ef2 <pop_off+0x50>
    panic("pop_off");
  c->noff -= 1;
    80000ec0:	37fd                	addiw	a5,a5,-1
    80000ec2:	0007871b          	sext.w	a4,a5
    80000ec6:	dd3c                	sw	a5,120(a0)
  if(c->noff == 0 && c->intena)
    80000ec8:	eb09                	bnez	a4,80000eda <pop_off+0x38>
    80000eca:	5d7c                	lw	a5,124(a0)
    80000ecc:	c799                	beqz	a5,80000eda <pop_off+0x38>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80000ece:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80000ed2:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80000ed6:	10079073          	csrw	sstatus,a5
    intr_on();
}
    80000eda:	60a2                	ld	ra,8(sp)
    80000edc:	6402                	ld	s0,0(sp)
    80000ede:	0141                	addi	sp,sp,16
    80000ee0:	8082                	ret
    panic("pop_off - interruptible");
    80000ee2:	00007517          	auipc	a0,0x7
    80000ee6:	20650513          	addi	a0,a0,518 # 800080e8 <digits+0xa8>
    80000eea:	fffff097          	auipc	ra,0xfffff
    80000eee:	654080e7          	jalr	1620(ra) # 8000053e <panic>
    panic("pop_off");
    80000ef2:	00007517          	auipc	a0,0x7
    80000ef6:	20e50513          	addi	a0,a0,526 # 80008100 <digits+0xc0>
    80000efa:	fffff097          	auipc	ra,0xfffff
    80000efe:	644080e7          	jalr	1604(ra) # 8000053e <panic>

0000000080000f02 <release>:
{
    80000f02:	1101                	addi	sp,sp,-32
    80000f04:	ec06                	sd	ra,24(sp)
    80000f06:	e822                	sd	s0,16(sp)
    80000f08:	e426                	sd	s1,8(sp)
    80000f0a:	1000                	addi	s0,sp,32
    80000f0c:	84aa                	mv	s1,a0
  if(!holding(lk))
    80000f0e:	00000097          	auipc	ra,0x0
    80000f12:	ec6080e7          	jalr	-314(ra) # 80000dd4 <holding>
    80000f16:	c115                	beqz	a0,80000f3a <release+0x38>
  lk->cpu = 0;
    80000f18:	0004b823          	sd	zero,16(s1)
  __sync_synchronize();
    80000f1c:	0ff0000f          	fence
  __sync_lock_release(&lk->locked);
    80000f20:	0f50000f          	fence	iorw,ow
    80000f24:	0804a02f          	amoswap.w	zero,zero,(s1)
  pop_off();
    80000f28:	00000097          	auipc	ra,0x0
    80000f2c:	f7a080e7          	jalr	-134(ra) # 80000ea2 <pop_off>
}
    80000f30:	60e2                	ld	ra,24(sp)
    80000f32:	6442                	ld	s0,16(sp)
    80000f34:	64a2                	ld	s1,8(sp)
    80000f36:	6105                	addi	sp,sp,32
    80000f38:	8082                	ret
    panic("release");
    80000f3a:	00007517          	auipc	a0,0x7
    80000f3e:	1ce50513          	addi	a0,a0,462 # 80008108 <digits+0xc8>
    80000f42:	fffff097          	auipc	ra,0xfffff
    80000f46:	5fc080e7          	jalr	1532(ra) # 8000053e <panic>

0000000080000f4a <memset>:
#include "types.h"

void*
memset(void *dst, int c, uint n)
{
    80000f4a:	1141                	addi	sp,sp,-16
    80000f4c:	e422                	sd	s0,8(sp)
    80000f4e:	0800                	addi	s0,sp,16
  char *cdst = (char *) dst;
  int i;
  for(i = 0; i < n; i++){
    80000f50:	ce09                	beqz	a2,80000f6a <memset+0x20>
    80000f52:	87aa                	mv	a5,a0
    80000f54:	fff6071b          	addiw	a4,a2,-1
    80000f58:	1702                	slli	a4,a4,0x20
    80000f5a:	9301                	srli	a4,a4,0x20
    80000f5c:	0705                	addi	a4,a4,1
    80000f5e:	972a                	add	a4,a4,a0
    cdst[i] = c;
    80000f60:	00b78023          	sb	a1,0(a5)
  for(i = 0; i < n; i++){
    80000f64:	0785                	addi	a5,a5,1
    80000f66:	fee79de3          	bne	a5,a4,80000f60 <memset+0x16>
  }
  return dst;
}
    80000f6a:	6422                	ld	s0,8(sp)
    80000f6c:	0141                	addi	sp,sp,16
    80000f6e:	8082                	ret

0000000080000f70 <memcmp>:

int
memcmp(const void *v1, const void *v2, uint n)
{
    80000f70:	1141                	addi	sp,sp,-16
    80000f72:	e422                	sd	s0,8(sp)
    80000f74:	0800                	addi	s0,sp,16
  const uchar *s1, *s2;

  s1 = v1;
  s2 = v2;
  while(n-- > 0){
    80000f76:	ca05                	beqz	a2,80000fa6 <memcmp+0x36>
    80000f78:	fff6069b          	addiw	a3,a2,-1
    80000f7c:	1682                	slli	a3,a3,0x20
    80000f7e:	9281                	srli	a3,a3,0x20
    80000f80:	0685                	addi	a3,a3,1
    80000f82:	96aa                	add	a3,a3,a0
    if(*s1 != *s2)
    80000f84:	00054783          	lbu	a5,0(a0)
    80000f88:	0005c703          	lbu	a4,0(a1)
    80000f8c:	00e79863          	bne	a5,a4,80000f9c <memcmp+0x2c>
      return *s1 - *s2;
    s1++, s2++;
    80000f90:	0505                	addi	a0,a0,1
    80000f92:	0585                	addi	a1,a1,1
  while(n-- > 0){
    80000f94:	fed518e3          	bne	a0,a3,80000f84 <memcmp+0x14>
  }

  return 0;
    80000f98:	4501                	li	a0,0
    80000f9a:	a019                	j	80000fa0 <memcmp+0x30>
      return *s1 - *s2;
    80000f9c:	40e7853b          	subw	a0,a5,a4
}
    80000fa0:	6422                	ld	s0,8(sp)
    80000fa2:	0141                	addi	sp,sp,16
    80000fa4:	8082                	ret
  return 0;
    80000fa6:	4501                	li	a0,0
    80000fa8:	bfe5                	j	80000fa0 <memcmp+0x30>

0000000080000faa <memmove>:

void*
memmove(void *dst, const void *src, uint n)
{
    80000faa:	1141                	addi	sp,sp,-16
    80000fac:	e422                	sd	s0,8(sp)
    80000fae:	0800                	addi	s0,sp,16
  const char *s;
  char *d;

  if(n == 0)
    80000fb0:	ca0d                	beqz	a2,80000fe2 <memmove+0x38>
    return dst;
  
  s = src;
  d = dst;
  if(s < d && s + n > d){
    80000fb2:	00a5f963          	bgeu	a1,a0,80000fc4 <memmove+0x1a>
    80000fb6:	02061693          	slli	a3,a2,0x20
    80000fba:	9281                	srli	a3,a3,0x20
    80000fbc:	00d58733          	add	a4,a1,a3
    80000fc0:	02e56463          	bltu	a0,a4,80000fe8 <memmove+0x3e>
    s += n;
    d += n;
    while(n-- > 0)
      *--d = *--s;
  } else
    while(n-- > 0)
    80000fc4:	fff6079b          	addiw	a5,a2,-1
    80000fc8:	1782                	slli	a5,a5,0x20
    80000fca:	9381                	srli	a5,a5,0x20
    80000fcc:	0785                	addi	a5,a5,1
    80000fce:	97ae                	add	a5,a5,a1
    80000fd0:	872a                	mv	a4,a0
      *d++ = *s++;
    80000fd2:	0585                	addi	a1,a1,1
    80000fd4:	0705                	addi	a4,a4,1
    80000fd6:	fff5c683          	lbu	a3,-1(a1)
    80000fda:	fed70fa3          	sb	a3,-1(a4)
    while(n-- > 0)
    80000fde:	fef59ae3          	bne	a1,a5,80000fd2 <memmove+0x28>

  return dst;
}
    80000fe2:	6422                	ld	s0,8(sp)
    80000fe4:	0141                	addi	sp,sp,16
    80000fe6:	8082                	ret
    d += n;
    80000fe8:	96aa                	add	a3,a3,a0
    while(n-- > 0)
    80000fea:	fff6079b          	addiw	a5,a2,-1
    80000fee:	1782                	slli	a5,a5,0x20
    80000ff0:	9381                	srli	a5,a5,0x20
    80000ff2:	fff7c793          	not	a5,a5
    80000ff6:	97ba                	add	a5,a5,a4
      *--d = *--s;
    80000ff8:	177d                	addi	a4,a4,-1
    80000ffa:	16fd                	addi	a3,a3,-1
    80000ffc:	00074603          	lbu	a2,0(a4)
    80001000:	00c68023          	sb	a2,0(a3)
    while(n-- > 0)
    80001004:	fef71ae3          	bne	a4,a5,80000ff8 <memmove+0x4e>
    80001008:	bfe9                	j	80000fe2 <memmove+0x38>

000000008000100a <memcpy>:

// memcpy exists to placate GCC.  Use memmove.
void*
memcpy(void *dst, const void *src, uint n)
{
    8000100a:	1141                	addi	sp,sp,-16
    8000100c:	e406                	sd	ra,8(sp)
    8000100e:	e022                	sd	s0,0(sp)
    80001010:	0800                	addi	s0,sp,16
  return memmove(dst, src, n);
    80001012:	00000097          	auipc	ra,0x0
    80001016:	f98080e7          	jalr	-104(ra) # 80000faa <memmove>
}
    8000101a:	60a2                	ld	ra,8(sp)
    8000101c:	6402                	ld	s0,0(sp)
    8000101e:	0141                	addi	sp,sp,16
    80001020:	8082                	ret

0000000080001022 <strncmp>:

int
strncmp(const char *p, const char *q, uint n)
{
    80001022:	1141                	addi	sp,sp,-16
    80001024:	e422                	sd	s0,8(sp)
    80001026:	0800                	addi	s0,sp,16
  while(n > 0 && *p && *p == *q)
    80001028:	ce11                	beqz	a2,80001044 <strncmp+0x22>
    8000102a:	00054783          	lbu	a5,0(a0)
    8000102e:	cf89                	beqz	a5,80001048 <strncmp+0x26>
    80001030:	0005c703          	lbu	a4,0(a1)
    80001034:	00f71a63          	bne	a4,a5,80001048 <strncmp+0x26>
    n--, p++, q++;
    80001038:	367d                	addiw	a2,a2,-1
    8000103a:	0505                	addi	a0,a0,1
    8000103c:	0585                	addi	a1,a1,1
  while(n > 0 && *p && *p == *q)
    8000103e:	f675                	bnez	a2,8000102a <strncmp+0x8>
  if(n == 0)
    return 0;
    80001040:	4501                	li	a0,0
    80001042:	a809                	j	80001054 <strncmp+0x32>
    80001044:	4501                	li	a0,0
    80001046:	a039                	j	80001054 <strncmp+0x32>
  if(n == 0)
    80001048:	ca09                	beqz	a2,8000105a <strncmp+0x38>
  return (uchar)*p - (uchar)*q;
    8000104a:	00054503          	lbu	a0,0(a0)
    8000104e:	0005c783          	lbu	a5,0(a1)
    80001052:	9d1d                	subw	a0,a0,a5
}
    80001054:	6422                	ld	s0,8(sp)
    80001056:	0141                	addi	sp,sp,16
    80001058:	8082                	ret
    return 0;
    8000105a:	4501                	li	a0,0
    8000105c:	bfe5                	j	80001054 <strncmp+0x32>

000000008000105e <strncpy>:

char*
strncpy(char *s, const char *t, int n)
{
    8000105e:	1141                	addi	sp,sp,-16
    80001060:	e422                	sd	s0,8(sp)
    80001062:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  while(n-- > 0 && (*s++ = *t++) != 0)
    80001064:	872a                	mv	a4,a0
    80001066:	8832                	mv	a6,a2
    80001068:	367d                	addiw	a2,a2,-1
    8000106a:	01005963          	blez	a6,8000107c <strncpy+0x1e>
    8000106e:	0705                	addi	a4,a4,1
    80001070:	0005c783          	lbu	a5,0(a1)
    80001074:	fef70fa3          	sb	a5,-1(a4)
    80001078:	0585                	addi	a1,a1,1
    8000107a:	f7f5                	bnez	a5,80001066 <strncpy+0x8>
    ;
  while(n-- > 0)
    8000107c:	00c05d63          	blez	a2,80001096 <strncpy+0x38>
    80001080:	86ba                	mv	a3,a4
    *s++ = 0;
    80001082:	0685                	addi	a3,a3,1
    80001084:	fe068fa3          	sb	zero,-1(a3)
  while(n-- > 0)
    80001088:	fff6c793          	not	a5,a3
    8000108c:	9fb9                	addw	a5,a5,a4
    8000108e:	010787bb          	addw	a5,a5,a6
    80001092:	fef048e3          	bgtz	a5,80001082 <strncpy+0x24>
  return os;
}
    80001096:	6422                	ld	s0,8(sp)
    80001098:	0141                	addi	sp,sp,16
    8000109a:	8082                	ret

000000008000109c <safestrcpy>:

// Like strncpy but guaranteed to NUL-terminate.
char*
safestrcpy(char *s, const char *t, int n)
{
    8000109c:	1141                	addi	sp,sp,-16
    8000109e:	e422                	sd	s0,8(sp)
    800010a0:	0800                	addi	s0,sp,16
  char *os;

  os = s;
  if(n <= 0)
    800010a2:	02c05363          	blez	a2,800010c8 <safestrcpy+0x2c>
    800010a6:	fff6069b          	addiw	a3,a2,-1
    800010aa:	1682                	slli	a3,a3,0x20
    800010ac:	9281                	srli	a3,a3,0x20
    800010ae:	96ae                	add	a3,a3,a1
    800010b0:	87aa                	mv	a5,a0
    return os;
  while(--n > 0 && (*s++ = *t++) != 0)
    800010b2:	00d58963          	beq	a1,a3,800010c4 <safestrcpy+0x28>
    800010b6:	0585                	addi	a1,a1,1
    800010b8:	0785                	addi	a5,a5,1
    800010ba:	fff5c703          	lbu	a4,-1(a1)
    800010be:	fee78fa3          	sb	a4,-1(a5)
    800010c2:	fb65                	bnez	a4,800010b2 <safestrcpy+0x16>
    ;
  *s = 0;
    800010c4:	00078023          	sb	zero,0(a5)
  return os;
}
    800010c8:	6422                	ld	s0,8(sp)
    800010ca:	0141                	addi	sp,sp,16
    800010cc:	8082                	ret

00000000800010ce <strlen>:

int
strlen(const char *s)
{
    800010ce:	1141                	addi	sp,sp,-16
    800010d0:	e422                	sd	s0,8(sp)
    800010d2:	0800                	addi	s0,sp,16
  int n;

  for(n = 0; s[n]; n++)
    800010d4:	00054783          	lbu	a5,0(a0)
    800010d8:	cf91                	beqz	a5,800010f4 <strlen+0x26>
    800010da:	0505                	addi	a0,a0,1
    800010dc:	87aa                	mv	a5,a0
    800010de:	4685                	li	a3,1
    800010e0:	9e89                	subw	a3,a3,a0
    800010e2:	00f6853b          	addw	a0,a3,a5
    800010e6:	0785                	addi	a5,a5,1
    800010e8:	fff7c703          	lbu	a4,-1(a5)
    800010ec:	fb7d                	bnez	a4,800010e2 <strlen+0x14>
    ;
  return n;
}
    800010ee:	6422                	ld	s0,8(sp)
    800010f0:	0141                	addi	sp,sp,16
    800010f2:	8082                	ret
  for(n = 0; s[n]; n++)
    800010f4:	4501                	li	a0,0
    800010f6:	bfe5                	j	800010ee <strlen+0x20>

00000000800010f8 <main>:
volatile static int started = 0;

// start() jumps here in supervisor mode on all CPUs.
void
main()
{
    800010f8:	1141                	addi	sp,sp,-16
    800010fa:	e406                	sd	ra,8(sp)
    800010fc:	e022                	sd	s0,0(sp)
    800010fe:	0800                	addi	s0,sp,16
  if(cpuid() == 0){
    80001100:	00001097          	auipc	ra,0x1
    80001104:	aee080e7          	jalr	-1298(ra) # 80001bee <cpuid>
    virtio_disk_init(); // emulated hard disk
    userinit();      // first user process
    __sync_synchronize();
    started = 1;
  } else {
    while(started == 0)
    80001108:	00008717          	auipc	a4,0x8
    8000110c:	f1070713          	addi	a4,a4,-240 # 80009018 <started>
  if(cpuid() == 0){
    80001110:	c139                	beqz	a0,80001156 <main+0x5e>
    while(started == 0)
    80001112:	431c                	lw	a5,0(a4)
    80001114:	2781                	sext.w	a5,a5
    80001116:	dff5                	beqz	a5,80001112 <main+0x1a>
      ;
    __sync_synchronize();
    80001118:	0ff0000f          	fence
    printf("hart %d starting\n", cpuid());
    8000111c:	00001097          	auipc	ra,0x1
    80001120:	ad2080e7          	jalr	-1326(ra) # 80001bee <cpuid>
    80001124:	85aa                	mv	a1,a0
    80001126:	00007517          	auipc	a0,0x7
    8000112a:	00250513          	addi	a0,a0,2 # 80008128 <digits+0xe8>
    8000112e:	fffff097          	auipc	ra,0xfffff
    80001132:	45a080e7          	jalr	1114(ra) # 80000588 <printf>
    kvminithart();    // turn on paging
    80001136:	00000097          	auipc	ra,0x0
    8000113a:	0d8080e7          	jalr	216(ra) # 8000120e <kvminithart>
    trapinithart();   // install kernel trap vector
    8000113e:	00001097          	auipc	ra,0x1
    80001142:	734080e7          	jalr	1844(ra) # 80002872 <trapinithart>
    plicinithart();   // ask PLIC for device interrupts
    80001146:	00005097          	auipc	ra,0x5
    8000114a:	09a080e7          	jalr	154(ra) # 800061e0 <plicinithart>
  }

  scheduler();        
    8000114e:	00001097          	auipc	ra,0x1
    80001152:	fe2080e7          	jalr	-30(ra) # 80002130 <scheduler>
    consoleinit();
    80001156:	fffff097          	auipc	ra,0xfffff
    8000115a:	2fa080e7          	jalr	762(ra) # 80000450 <consoleinit>
    printfinit();
    8000115e:	fffff097          	auipc	ra,0xfffff
    80001162:	610080e7          	jalr	1552(ra) # 8000076e <printfinit>
    printf("\n");
    80001166:	00007517          	auipc	a0,0x7
    8000116a:	6f250513          	addi	a0,a0,1778 # 80008858 <syscalls+0x338>
    8000116e:	fffff097          	auipc	ra,0xfffff
    80001172:	41a080e7          	jalr	1050(ra) # 80000588 <printf>
    printf("xv6 kernel is booting\n");
    80001176:	00007517          	auipc	a0,0x7
    8000117a:	f9a50513          	addi	a0,a0,-102 # 80008110 <digits+0xd0>
    8000117e:	fffff097          	auipc	ra,0xfffff
    80001182:	40a080e7          	jalr	1034(ra) # 80000588 <printf>
    printf("\n");
    80001186:	00007517          	auipc	a0,0x7
    8000118a:	6d250513          	addi	a0,a0,1746 # 80008858 <syscalls+0x338>
    8000118e:	fffff097          	auipc	ra,0xfffff
    80001192:	3fa080e7          	jalr	1018(ra) # 80000588 <printf>
    kinit();         // physical page allocator
    80001196:	00000097          	auipc	ra,0x0
    8000119a:	926080e7          	jalr	-1754(ra) # 80000abc <kinit>
    kvminit();       // create kernel page table
    8000119e:	00000097          	auipc	ra,0x0
    800011a2:	322080e7          	jalr	802(ra) # 800014c0 <kvminit>
    kvminithart();   // turn on paging
    800011a6:	00000097          	auipc	ra,0x0
    800011aa:	068080e7          	jalr	104(ra) # 8000120e <kvminithart>
    procinit();      // process table
    800011ae:	00001097          	auipc	ra,0x1
    800011b2:	990080e7          	jalr	-1648(ra) # 80001b3e <procinit>
    trapinit();      // trap vectors
    800011b6:	00001097          	auipc	ra,0x1
    800011ba:	694080e7          	jalr	1684(ra) # 8000284a <trapinit>
    trapinithart();  // install kernel trap vector
    800011be:	00001097          	auipc	ra,0x1
    800011c2:	6b4080e7          	jalr	1716(ra) # 80002872 <trapinithart>
    plicinit();      // set up interrupt controller
    800011c6:	00005097          	auipc	ra,0x5
    800011ca:	004080e7          	jalr	4(ra) # 800061ca <plicinit>
    plicinithart();  // ask PLIC for device interrupts
    800011ce:	00005097          	auipc	ra,0x5
    800011d2:	012080e7          	jalr	18(ra) # 800061e0 <plicinithart>
    binit();         // buffer cache
    800011d6:	00002097          	auipc	ra,0x2
    800011da:	f40080e7          	jalr	-192(ra) # 80003116 <binit>
    iinit();         // inode table
    800011de:	00002097          	auipc	ra,0x2
    800011e2:	5d0080e7          	jalr	1488(ra) # 800037ae <iinit>
    fileinit();      // file table
    800011e6:	00003097          	auipc	ra,0x3
    800011ea:	57a080e7          	jalr	1402(ra) # 80004760 <fileinit>
    virtio_disk_init(); // emulated hard disk
    800011ee:	00005097          	auipc	ra,0x5
    800011f2:	114080e7          	jalr	276(ra) # 80006302 <virtio_disk_init>
    userinit();      // first user process
    800011f6:	00001097          	auipc	ra,0x1
    800011fa:	cfc080e7          	jalr	-772(ra) # 80001ef2 <userinit>
    __sync_synchronize();
    800011fe:	0ff0000f          	fence
    started = 1;
    80001202:	4785                	li	a5,1
    80001204:	00008717          	auipc	a4,0x8
    80001208:	e0f72a23          	sw	a5,-492(a4) # 80009018 <started>
    8000120c:	b789                	j	8000114e <main+0x56>

000000008000120e <kvminithart>:

// Switch h/w page table register to the kernel's page table,
// and enable paging.
void
kvminithart()
{
    8000120e:	1141                	addi	sp,sp,-16
    80001210:	e422                	sd	s0,8(sp)
    80001212:	0800                	addi	s0,sp,16
  w_satp(MAKE_SATP(kernel_pagetable));
    80001214:	00008797          	auipc	a5,0x8
    80001218:	e0c7b783          	ld	a5,-500(a5) # 80009020 <kernel_pagetable>
    8000121c:	83b1                	srli	a5,a5,0xc
    8000121e:	577d                	li	a4,-1
    80001220:	177e                	slli	a4,a4,0x3f
    80001222:	8fd9                	or	a5,a5,a4
  asm volatile("csrw satp, %0" : : "r" (x));
    80001224:	18079073          	csrw	satp,a5
// flush the TLB.
static inline void
sfence_vma()
{
  // the zero, zero means flush all TLB entries.
  asm volatile("sfence.vma zero, zero");
    80001228:	12000073          	sfence.vma
  sfence_vma();
}
    8000122c:	6422                	ld	s0,8(sp)
    8000122e:	0141                	addi	sp,sp,16
    80001230:	8082                	ret

0000000080001232 <walk>:
//   21..29 -- 9 bits of level-1 index.
//   12..20 -- 9 bits of level-0 index.
//    0..11 -- 12 bits of byte offset within the page.
pte_t *
walk(pagetable_t pagetable, uint64 va, int alloc)
{
    80001232:	7139                	addi	sp,sp,-64
    80001234:	fc06                	sd	ra,56(sp)
    80001236:	f822                	sd	s0,48(sp)
    80001238:	f426                	sd	s1,40(sp)
    8000123a:	f04a                	sd	s2,32(sp)
    8000123c:	ec4e                	sd	s3,24(sp)
    8000123e:	e852                	sd	s4,16(sp)
    80001240:	e456                	sd	s5,8(sp)
    80001242:	e05a                	sd	s6,0(sp)
    80001244:	0080                	addi	s0,sp,64
    80001246:	84aa                	mv	s1,a0
    80001248:	89ae                	mv	s3,a1
    8000124a:	8ab2                	mv	s5,a2
  if(va >= MAXVA)
    8000124c:	57fd                	li	a5,-1
    8000124e:	83e9                	srli	a5,a5,0x1a
    80001250:	4a79                	li	s4,30
    panic("walk");

  for(int level = 2; level > 0; level--) {
    80001252:	4b31                	li	s6,12
  if(va >= MAXVA)
    80001254:	04b7f263          	bgeu	a5,a1,80001298 <walk+0x66>
    panic("walk");
    80001258:	00007517          	auipc	a0,0x7
    8000125c:	ee850513          	addi	a0,a0,-280 # 80008140 <digits+0x100>
    80001260:	fffff097          	auipc	ra,0xfffff
    80001264:	2de080e7          	jalr	734(ra) # 8000053e <panic>
    pte_t *pte = &pagetable[PX(level, va)];
    if(*pte & PTE_V) {
      pagetable = (pagetable_t)PTE2PA(*pte);
    } else {
      if(!alloc || (pagetable = (pde_t*)kalloc()) == 0)
    80001268:	060a8663          	beqz	s5,800012d4 <walk+0xa2>
    8000126c:	00000097          	auipc	ra,0x0
    80001270:	9a4080e7          	jalr	-1628(ra) # 80000c10 <kalloc>
    80001274:	84aa                	mv	s1,a0
    80001276:	c529                	beqz	a0,800012c0 <walk+0x8e>
        return 0;
      memset(pagetable, 0, PGSIZE);
    80001278:	6605                	lui	a2,0x1
    8000127a:	4581                	li	a1,0
    8000127c:	00000097          	auipc	ra,0x0
    80001280:	cce080e7          	jalr	-818(ra) # 80000f4a <memset>
      *pte = PA2PTE(pagetable) | PTE_V;
    80001284:	00c4d793          	srli	a5,s1,0xc
    80001288:	07aa                	slli	a5,a5,0xa
    8000128a:	0017e793          	ori	a5,a5,1
    8000128e:	00f93023          	sd	a5,0(s2)
  for(int level = 2; level > 0; level--) {
    80001292:	3a5d                	addiw	s4,s4,-9
    80001294:	036a0063          	beq	s4,s6,800012b4 <walk+0x82>
    pte_t *pte = &pagetable[PX(level, va)];
    80001298:	0149d933          	srl	s2,s3,s4
    8000129c:	1ff97913          	andi	s2,s2,511
    800012a0:	090e                	slli	s2,s2,0x3
    800012a2:	9926                	add	s2,s2,s1
    if(*pte & PTE_V) {
    800012a4:	00093483          	ld	s1,0(s2)
    800012a8:	0014f793          	andi	a5,s1,1
    800012ac:	dfd5                	beqz	a5,80001268 <walk+0x36>
      pagetable = (pagetable_t)PTE2PA(*pte);
    800012ae:	80a9                	srli	s1,s1,0xa
    800012b0:	04b2                	slli	s1,s1,0xc
    800012b2:	b7c5                	j	80001292 <walk+0x60>
    }
  }
  return &pagetable[PX(0, va)];
    800012b4:	00c9d513          	srli	a0,s3,0xc
    800012b8:	1ff57513          	andi	a0,a0,511
    800012bc:	050e                	slli	a0,a0,0x3
    800012be:	9526                	add	a0,a0,s1
}
    800012c0:	70e2                	ld	ra,56(sp)
    800012c2:	7442                	ld	s0,48(sp)
    800012c4:	74a2                	ld	s1,40(sp)
    800012c6:	7902                	ld	s2,32(sp)
    800012c8:	69e2                	ld	s3,24(sp)
    800012ca:	6a42                	ld	s4,16(sp)
    800012cc:	6aa2                	ld	s5,8(sp)
    800012ce:	6b02                	ld	s6,0(sp)
    800012d0:	6121                	addi	sp,sp,64
    800012d2:	8082                	ret
        return 0;
    800012d4:	4501                	li	a0,0
    800012d6:	b7ed                	j	800012c0 <walk+0x8e>

00000000800012d8 <walkaddr>:
walkaddr(pagetable_t pagetable, uint64 va)
{
  pte_t *pte;
  uint64 pa;

  if(va >= MAXVA)
    800012d8:	57fd                	li	a5,-1
    800012da:	83e9                	srli	a5,a5,0x1a
    800012dc:	00b7f463          	bgeu	a5,a1,800012e4 <walkaddr+0xc>
    return 0;
    800012e0:	4501                	li	a0,0
    return 0;
  if((*pte & PTE_U) == 0)
    return 0;
  pa = PTE2PA(*pte);
  return pa;
}
    800012e2:	8082                	ret
{
    800012e4:	1141                	addi	sp,sp,-16
    800012e6:	e406                	sd	ra,8(sp)
    800012e8:	e022                	sd	s0,0(sp)
    800012ea:	0800                	addi	s0,sp,16
  pte = walk(pagetable, va, 0);
    800012ec:	4601                	li	a2,0
    800012ee:	00000097          	auipc	ra,0x0
    800012f2:	f44080e7          	jalr	-188(ra) # 80001232 <walk>
  if(pte == 0)
    800012f6:	c105                	beqz	a0,80001316 <walkaddr+0x3e>
  if((*pte & PTE_V) == 0)
    800012f8:	611c                	ld	a5,0(a0)
  if((*pte & PTE_U) == 0)
    800012fa:	0117f693          	andi	a3,a5,17
    800012fe:	4745                	li	a4,17
    return 0;
    80001300:	4501                	li	a0,0
  if((*pte & PTE_U) == 0)
    80001302:	00e68663          	beq	a3,a4,8000130e <walkaddr+0x36>
}
    80001306:	60a2                	ld	ra,8(sp)
    80001308:	6402                	ld	s0,0(sp)
    8000130a:	0141                	addi	sp,sp,16
    8000130c:	8082                	ret
  pa = PTE2PA(*pte);
    8000130e:	00a7d513          	srli	a0,a5,0xa
    80001312:	0532                	slli	a0,a0,0xc
  return pa;
    80001314:	bfcd                	j	80001306 <walkaddr+0x2e>
    return 0;
    80001316:	4501                	li	a0,0
    80001318:	b7fd                	j	80001306 <walkaddr+0x2e>

000000008000131a <mappages>:
// physical addresses starting at pa. va and size might not
// be page-aligned. Returns 0 on success, -1 if walk() couldn't
// allocate a needed page-table page.
int
mappages(pagetable_t pagetable, uint64 va, uint64 size, uint64 pa, int perm)
{
    8000131a:	715d                	addi	sp,sp,-80
    8000131c:	e486                	sd	ra,72(sp)
    8000131e:	e0a2                	sd	s0,64(sp)
    80001320:	fc26                	sd	s1,56(sp)
    80001322:	f84a                	sd	s2,48(sp)
    80001324:	f44e                	sd	s3,40(sp)
    80001326:	f052                	sd	s4,32(sp)
    80001328:	ec56                	sd	s5,24(sp)
    8000132a:	e85a                	sd	s6,16(sp)
    8000132c:	e45e                	sd	s7,8(sp)
    8000132e:	0880                	addi	s0,sp,80
  uint64 a, last;
  pte_t *pte;

  if(size == 0)
    80001330:	c205                	beqz	a2,80001350 <mappages+0x36>
    80001332:	8aaa                	mv	s5,a0
    80001334:	8b3a                	mv	s6,a4
    panic("mappages: size");
  
  a = PGROUNDDOWN(va);
    80001336:	77fd                	lui	a5,0xfffff
    80001338:	00f5fa33          	and	s4,a1,a5
  last = PGROUNDDOWN(va + size - 1);
    8000133c:	15fd                	addi	a1,a1,-1
    8000133e:	00c589b3          	add	s3,a1,a2
    80001342:	00f9f9b3          	and	s3,s3,a5
  a = PGROUNDDOWN(va);
    80001346:	8952                	mv	s2,s4
    80001348:	41468a33          	sub	s4,a3,s4
    if(*pte & PTE_V)
      panic("mappages: remap");
    *pte = PA2PTE(pa) | perm | PTE_V;
    if(a == last)
      break;
    a += PGSIZE;
    8000134c:	6b85                	lui	s7,0x1
    8000134e:	a015                	j	80001372 <mappages+0x58>
    panic("mappages: size");
    80001350:	00007517          	auipc	a0,0x7
    80001354:	df850513          	addi	a0,a0,-520 # 80008148 <digits+0x108>
    80001358:	fffff097          	auipc	ra,0xfffff
    8000135c:	1e6080e7          	jalr	486(ra) # 8000053e <panic>
      panic("mappages: remap");
    80001360:	00007517          	auipc	a0,0x7
    80001364:	df850513          	addi	a0,a0,-520 # 80008158 <digits+0x118>
    80001368:	fffff097          	auipc	ra,0xfffff
    8000136c:	1d6080e7          	jalr	470(ra) # 8000053e <panic>
    a += PGSIZE;
    80001370:	995e                	add	s2,s2,s7
  for(;;){
    80001372:	012a04b3          	add	s1,s4,s2
    if((pte = walk(pagetable, a, 1)) == 0)
    80001376:	4605                	li	a2,1
    80001378:	85ca                	mv	a1,s2
    8000137a:	8556                	mv	a0,s5
    8000137c:	00000097          	auipc	ra,0x0
    80001380:	eb6080e7          	jalr	-330(ra) # 80001232 <walk>
    80001384:	cd19                	beqz	a0,800013a2 <mappages+0x88>
    if(*pte & PTE_V)
    80001386:	611c                	ld	a5,0(a0)
    80001388:	8b85                	andi	a5,a5,1
    8000138a:	fbf9                	bnez	a5,80001360 <mappages+0x46>
    *pte = PA2PTE(pa) | perm | PTE_V;
    8000138c:	80b1                	srli	s1,s1,0xc
    8000138e:	04aa                	slli	s1,s1,0xa
    80001390:	0164e4b3          	or	s1,s1,s6
    80001394:	0014e493          	ori	s1,s1,1
    80001398:	e104                	sd	s1,0(a0)
    if(a == last)
    8000139a:	fd391be3          	bne	s2,s3,80001370 <mappages+0x56>
    pa += PGSIZE;
  }
  return 0;
    8000139e:	4501                	li	a0,0
    800013a0:	a011                	j	800013a4 <mappages+0x8a>
      return -1;
    800013a2:	557d                	li	a0,-1
}
    800013a4:	60a6                	ld	ra,72(sp)
    800013a6:	6406                	ld	s0,64(sp)
    800013a8:	74e2                	ld	s1,56(sp)
    800013aa:	7942                	ld	s2,48(sp)
    800013ac:	79a2                	ld	s3,40(sp)
    800013ae:	7a02                	ld	s4,32(sp)
    800013b0:	6ae2                	ld	s5,24(sp)
    800013b2:	6b42                	ld	s6,16(sp)
    800013b4:	6ba2                	ld	s7,8(sp)
    800013b6:	6161                	addi	sp,sp,80
    800013b8:	8082                	ret

00000000800013ba <kvmmap>:
{
    800013ba:	1141                	addi	sp,sp,-16
    800013bc:	e406                	sd	ra,8(sp)
    800013be:	e022                	sd	s0,0(sp)
    800013c0:	0800                	addi	s0,sp,16
    800013c2:	87b6                	mv	a5,a3
  if(mappages(kpgtbl, va, sz, pa, perm) != 0)
    800013c4:	86b2                	mv	a3,a2
    800013c6:	863e                	mv	a2,a5
    800013c8:	00000097          	auipc	ra,0x0
    800013cc:	f52080e7          	jalr	-174(ra) # 8000131a <mappages>
    800013d0:	e509                	bnez	a0,800013da <kvmmap+0x20>
}
    800013d2:	60a2                	ld	ra,8(sp)
    800013d4:	6402                	ld	s0,0(sp)
    800013d6:	0141                	addi	sp,sp,16
    800013d8:	8082                	ret
    panic("kvmmap");
    800013da:	00007517          	auipc	a0,0x7
    800013de:	d8e50513          	addi	a0,a0,-626 # 80008168 <digits+0x128>
    800013e2:	fffff097          	auipc	ra,0xfffff
    800013e6:	15c080e7          	jalr	348(ra) # 8000053e <panic>

00000000800013ea <kvmmake>:
{
    800013ea:	1101                	addi	sp,sp,-32
    800013ec:	ec06                	sd	ra,24(sp)
    800013ee:	e822                	sd	s0,16(sp)
    800013f0:	e426                	sd	s1,8(sp)
    800013f2:	e04a                	sd	s2,0(sp)
    800013f4:	1000                	addi	s0,sp,32
  kpgtbl = (pagetable_t) kalloc();
    800013f6:	00000097          	auipc	ra,0x0
    800013fa:	81a080e7          	jalr	-2022(ra) # 80000c10 <kalloc>
    800013fe:	84aa                	mv	s1,a0
  memset(kpgtbl, 0, PGSIZE);
    80001400:	6605                	lui	a2,0x1
    80001402:	4581                	li	a1,0
    80001404:	00000097          	auipc	ra,0x0
    80001408:	b46080e7          	jalr	-1210(ra) # 80000f4a <memset>
  kvmmap(kpgtbl, UART0, UART0, PGSIZE, PTE_R | PTE_W);
    8000140c:	4719                	li	a4,6
    8000140e:	6685                	lui	a3,0x1
    80001410:	10000637          	lui	a2,0x10000
    80001414:	100005b7          	lui	a1,0x10000
    80001418:	8526                	mv	a0,s1
    8000141a:	00000097          	auipc	ra,0x0
    8000141e:	fa0080e7          	jalr	-96(ra) # 800013ba <kvmmap>
  kvmmap(kpgtbl, VIRTIO0, VIRTIO0, PGSIZE, PTE_R | PTE_W);
    80001422:	4719                	li	a4,6
    80001424:	6685                	lui	a3,0x1
    80001426:	10001637          	lui	a2,0x10001
    8000142a:	100015b7          	lui	a1,0x10001
    8000142e:	8526                	mv	a0,s1
    80001430:	00000097          	auipc	ra,0x0
    80001434:	f8a080e7          	jalr	-118(ra) # 800013ba <kvmmap>
  kvmmap(kpgtbl, PLIC, PLIC, 0x400000, PTE_R | PTE_W);
    80001438:	4719                	li	a4,6
    8000143a:	004006b7          	lui	a3,0x400
    8000143e:	0c000637          	lui	a2,0xc000
    80001442:	0c0005b7          	lui	a1,0xc000
    80001446:	8526                	mv	a0,s1
    80001448:	00000097          	auipc	ra,0x0
    8000144c:	f72080e7          	jalr	-142(ra) # 800013ba <kvmmap>
  kvmmap(kpgtbl, KERNBASE, KERNBASE, (uint64)etext-KERNBASE, PTE_R | PTE_X);
    80001450:	00007917          	auipc	s2,0x7
    80001454:	bb090913          	addi	s2,s2,-1104 # 80008000 <etext>
    80001458:	4729                	li	a4,10
    8000145a:	80007697          	auipc	a3,0x80007
    8000145e:	ba668693          	addi	a3,a3,-1114 # 8000 <_entry-0x7fff8000>
    80001462:	4605                	li	a2,1
    80001464:	067e                	slli	a2,a2,0x1f
    80001466:	85b2                	mv	a1,a2
    80001468:	8526                	mv	a0,s1
    8000146a:	00000097          	auipc	ra,0x0
    8000146e:	f50080e7          	jalr	-176(ra) # 800013ba <kvmmap>
  kvmmap(kpgtbl, (uint64)etext, (uint64)etext, PHYSTOP-(uint64)etext, PTE_R | PTE_W);
    80001472:	4719                	li	a4,6
    80001474:	46c5                	li	a3,17
    80001476:	06ee                	slli	a3,a3,0x1b
    80001478:	412686b3          	sub	a3,a3,s2
    8000147c:	864a                	mv	a2,s2
    8000147e:	85ca                	mv	a1,s2
    80001480:	8526                	mv	a0,s1
    80001482:	00000097          	auipc	ra,0x0
    80001486:	f38080e7          	jalr	-200(ra) # 800013ba <kvmmap>
  kvmmap(kpgtbl, TRAMPOLINE, (uint64)trampoline, PGSIZE, PTE_R | PTE_X);
    8000148a:	4729                	li	a4,10
    8000148c:	6685                	lui	a3,0x1
    8000148e:	00006617          	auipc	a2,0x6
    80001492:	b7260613          	addi	a2,a2,-1166 # 80007000 <_trampoline>
    80001496:	040005b7          	lui	a1,0x4000
    8000149a:	15fd                	addi	a1,a1,-1
    8000149c:	05b2                	slli	a1,a1,0xc
    8000149e:	8526                	mv	a0,s1
    800014a0:	00000097          	auipc	ra,0x0
    800014a4:	f1a080e7          	jalr	-230(ra) # 800013ba <kvmmap>
  proc_mapstacks(kpgtbl);
    800014a8:	8526                	mv	a0,s1
    800014aa:	00000097          	auipc	ra,0x0
    800014ae:	5fe080e7          	jalr	1534(ra) # 80001aa8 <proc_mapstacks>
}
    800014b2:	8526                	mv	a0,s1
    800014b4:	60e2                	ld	ra,24(sp)
    800014b6:	6442                	ld	s0,16(sp)
    800014b8:	64a2                	ld	s1,8(sp)
    800014ba:	6902                	ld	s2,0(sp)
    800014bc:	6105                	addi	sp,sp,32
    800014be:	8082                	ret

00000000800014c0 <kvminit>:
{
    800014c0:	1141                	addi	sp,sp,-16
    800014c2:	e406                	sd	ra,8(sp)
    800014c4:	e022                	sd	s0,0(sp)
    800014c6:	0800                	addi	s0,sp,16
  kernel_pagetable = kvmmake();
    800014c8:	00000097          	auipc	ra,0x0
    800014cc:	f22080e7          	jalr	-222(ra) # 800013ea <kvmmake>
    800014d0:	00008797          	auipc	a5,0x8
    800014d4:	b4a7b823          	sd	a0,-1200(a5) # 80009020 <kernel_pagetable>
}
    800014d8:	60a2                	ld	ra,8(sp)
    800014da:	6402                	ld	s0,0(sp)
    800014dc:	0141                	addi	sp,sp,16
    800014de:	8082                	ret

00000000800014e0 <uvmunmap>:
// Remove npages of mappings starting from va. va must be
// page-aligned. The mappings must exist.
// Optionally free the physical memory.
void
uvmunmap(pagetable_t pagetable, uint64 va, uint64 npages, int do_free)
{
    800014e0:	715d                	addi	sp,sp,-80
    800014e2:	e486                	sd	ra,72(sp)
    800014e4:	e0a2                	sd	s0,64(sp)
    800014e6:	fc26                	sd	s1,56(sp)
    800014e8:	f84a                	sd	s2,48(sp)
    800014ea:	f44e                	sd	s3,40(sp)
    800014ec:	f052                	sd	s4,32(sp)
    800014ee:	ec56                	sd	s5,24(sp)
    800014f0:	e85a                	sd	s6,16(sp)
    800014f2:	e45e                	sd	s7,8(sp)
    800014f4:	0880                	addi	s0,sp,80
  uint64 a;
  pte_t *pte;

  if((va % PGSIZE) != 0)
    800014f6:	03459793          	slli	a5,a1,0x34
    800014fa:	e795                	bnez	a5,80001526 <uvmunmap+0x46>
    800014fc:	8a2a                	mv	s4,a0
    800014fe:	892e                	mv	s2,a1
    80001500:	8ab6                	mv	s5,a3
    panic("uvmunmap: not aligned");

  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001502:	0632                	slli	a2,a2,0xc
    80001504:	00b609b3          	add	s3,a2,a1
    if((pte = walk(pagetable, a, 0)) == 0)
      panic("uvmunmap: walk");
    if((*pte & PTE_V) == 0)
      panic("uvmunmap: not mapped");
    if(PTE_FLAGS(*pte) == PTE_V)
    80001508:	4b85                	li	s7,1
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    8000150a:	6b05                	lui	s6,0x1
    8000150c:	0735e863          	bltu	a1,s3,8000157c <uvmunmap+0x9c>
      uint64 pa = PTE2PA(*pte);
      kfree((void*)pa);
    }
    *pte = 0;
  }
}
    80001510:	60a6                	ld	ra,72(sp)
    80001512:	6406                	ld	s0,64(sp)
    80001514:	74e2                	ld	s1,56(sp)
    80001516:	7942                	ld	s2,48(sp)
    80001518:	79a2                	ld	s3,40(sp)
    8000151a:	7a02                	ld	s4,32(sp)
    8000151c:	6ae2                	ld	s5,24(sp)
    8000151e:	6b42                	ld	s6,16(sp)
    80001520:	6ba2                	ld	s7,8(sp)
    80001522:	6161                	addi	sp,sp,80
    80001524:	8082                	ret
    panic("uvmunmap: not aligned");
    80001526:	00007517          	auipc	a0,0x7
    8000152a:	c4a50513          	addi	a0,a0,-950 # 80008170 <digits+0x130>
    8000152e:	fffff097          	auipc	ra,0xfffff
    80001532:	010080e7          	jalr	16(ra) # 8000053e <panic>
      panic("uvmunmap: walk");
    80001536:	00007517          	auipc	a0,0x7
    8000153a:	c5250513          	addi	a0,a0,-942 # 80008188 <digits+0x148>
    8000153e:	fffff097          	auipc	ra,0xfffff
    80001542:	000080e7          	jalr	ra # 8000053e <panic>
      panic("uvmunmap: not mapped");
    80001546:	00007517          	auipc	a0,0x7
    8000154a:	c5250513          	addi	a0,a0,-942 # 80008198 <digits+0x158>
    8000154e:	fffff097          	auipc	ra,0xfffff
    80001552:	ff0080e7          	jalr	-16(ra) # 8000053e <panic>
      panic("uvmunmap: not a leaf");
    80001556:	00007517          	auipc	a0,0x7
    8000155a:	c5a50513          	addi	a0,a0,-934 # 800081b0 <digits+0x170>
    8000155e:	fffff097          	auipc	ra,0xfffff
    80001562:	fe0080e7          	jalr	-32(ra) # 8000053e <panic>
      uint64 pa = PTE2PA(*pte);
    80001566:	8129                	srli	a0,a0,0xa
      kfree((void*)pa);
    80001568:	0532                	slli	a0,a0,0xc
    8000156a:	fffff097          	auipc	ra,0xfffff
    8000156e:	58e080e7          	jalr	1422(ra) # 80000af8 <kfree>
    *pte = 0;
    80001572:	0004b023          	sd	zero,0(s1)
  for(a = va; a < va + npages*PGSIZE; a += PGSIZE){
    80001576:	995a                	add	s2,s2,s6
    80001578:	f9397ce3          	bgeu	s2,s3,80001510 <uvmunmap+0x30>
    if((pte = walk(pagetable, a, 0)) == 0)
    8000157c:	4601                	li	a2,0
    8000157e:	85ca                	mv	a1,s2
    80001580:	8552                	mv	a0,s4
    80001582:	00000097          	auipc	ra,0x0
    80001586:	cb0080e7          	jalr	-848(ra) # 80001232 <walk>
    8000158a:	84aa                	mv	s1,a0
    8000158c:	d54d                	beqz	a0,80001536 <uvmunmap+0x56>
    if((*pte & PTE_V) == 0)
    8000158e:	6108                	ld	a0,0(a0)
    80001590:	00157793          	andi	a5,a0,1
    80001594:	dbcd                	beqz	a5,80001546 <uvmunmap+0x66>
    if(PTE_FLAGS(*pte) == PTE_V)
    80001596:	3ff57793          	andi	a5,a0,1023
    8000159a:	fb778ee3          	beq	a5,s7,80001556 <uvmunmap+0x76>
    if(do_free){
    8000159e:	fc0a8ae3          	beqz	s5,80001572 <uvmunmap+0x92>
    800015a2:	b7d1                	j	80001566 <uvmunmap+0x86>

00000000800015a4 <uvmcreate>:

// create an empty user page table.
// returns 0 if out of memory.
pagetable_t
uvmcreate()
{
    800015a4:	1101                	addi	sp,sp,-32
    800015a6:	ec06                	sd	ra,24(sp)
    800015a8:	e822                	sd	s0,16(sp)
    800015aa:	e426                	sd	s1,8(sp)
    800015ac:	1000                	addi	s0,sp,32
  pagetable_t pagetable;
  pagetable = (pagetable_t) kalloc();
    800015ae:	fffff097          	auipc	ra,0xfffff
    800015b2:	662080e7          	jalr	1634(ra) # 80000c10 <kalloc>
    800015b6:	84aa                	mv	s1,a0
  if(pagetable == 0)
    800015b8:	c519                	beqz	a0,800015c6 <uvmcreate+0x22>
    return 0;
  memset(pagetable, 0, PGSIZE);
    800015ba:	6605                	lui	a2,0x1
    800015bc:	4581                	li	a1,0
    800015be:	00000097          	auipc	ra,0x0
    800015c2:	98c080e7          	jalr	-1652(ra) # 80000f4a <memset>
  return pagetable;
}
    800015c6:	8526                	mv	a0,s1
    800015c8:	60e2                	ld	ra,24(sp)
    800015ca:	6442                	ld	s0,16(sp)
    800015cc:	64a2                	ld	s1,8(sp)
    800015ce:	6105                	addi	sp,sp,32
    800015d0:	8082                	ret

00000000800015d2 <uvminit>:
// Load the user initcode into address 0 of pagetable,
// for the very first process.
// sz must be less than a page.
void
uvminit(pagetable_t pagetable, uchar *src, uint sz)
{
    800015d2:	7179                	addi	sp,sp,-48
    800015d4:	f406                	sd	ra,40(sp)
    800015d6:	f022                	sd	s0,32(sp)
    800015d8:	ec26                	sd	s1,24(sp)
    800015da:	e84a                	sd	s2,16(sp)
    800015dc:	e44e                	sd	s3,8(sp)
    800015de:	e052                	sd	s4,0(sp)
    800015e0:	1800                	addi	s0,sp,48
  char *mem;

  if(sz >= PGSIZE)
    800015e2:	6785                	lui	a5,0x1
    800015e4:	04f67863          	bgeu	a2,a5,80001634 <uvminit+0x62>
    800015e8:	8a2a                	mv	s4,a0
    800015ea:	89ae                	mv	s3,a1
    800015ec:	84b2                	mv	s1,a2
    panic("inituvm: more than a page");
  mem = kalloc();
    800015ee:	fffff097          	auipc	ra,0xfffff
    800015f2:	622080e7          	jalr	1570(ra) # 80000c10 <kalloc>
    800015f6:	892a                	mv	s2,a0
  memset(mem, 0, PGSIZE);
    800015f8:	6605                	lui	a2,0x1
    800015fa:	4581                	li	a1,0
    800015fc:	00000097          	auipc	ra,0x0
    80001600:	94e080e7          	jalr	-1714(ra) # 80000f4a <memset>
  mappages(pagetable, 0, PGSIZE, (uint64)mem, PTE_W|PTE_R|PTE_X|PTE_U);
    80001604:	4779                	li	a4,30
    80001606:	86ca                	mv	a3,s2
    80001608:	6605                	lui	a2,0x1
    8000160a:	4581                	li	a1,0
    8000160c:	8552                	mv	a0,s4
    8000160e:	00000097          	auipc	ra,0x0
    80001612:	d0c080e7          	jalr	-756(ra) # 8000131a <mappages>
  memmove(mem, src, sz);
    80001616:	8626                	mv	a2,s1
    80001618:	85ce                	mv	a1,s3
    8000161a:	854a                	mv	a0,s2
    8000161c:	00000097          	auipc	ra,0x0
    80001620:	98e080e7          	jalr	-1650(ra) # 80000faa <memmove>
}
    80001624:	70a2                	ld	ra,40(sp)
    80001626:	7402                	ld	s0,32(sp)
    80001628:	64e2                	ld	s1,24(sp)
    8000162a:	6942                	ld	s2,16(sp)
    8000162c:	69a2                	ld	s3,8(sp)
    8000162e:	6a02                	ld	s4,0(sp)
    80001630:	6145                	addi	sp,sp,48
    80001632:	8082                	ret
    panic("inituvm: more than a page");
    80001634:	00007517          	auipc	a0,0x7
    80001638:	b9450513          	addi	a0,a0,-1132 # 800081c8 <digits+0x188>
    8000163c:	fffff097          	auipc	ra,0xfffff
    80001640:	f02080e7          	jalr	-254(ra) # 8000053e <panic>

0000000080001644 <uvmdealloc>:
// newsz.  oldsz and newsz need not be page-aligned, nor does newsz
// need to be less than oldsz.  oldsz can be larger than the actual
// process size.  Returns the new process size.
uint64
uvmdealloc(pagetable_t pagetable, uint64 oldsz, uint64 newsz)
{
    80001644:	1101                	addi	sp,sp,-32
    80001646:	ec06                	sd	ra,24(sp)
    80001648:	e822                	sd	s0,16(sp)
    8000164a:	e426                	sd	s1,8(sp)
    8000164c:	1000                	addi	s0,sp,32
  if(newsz >= oldsz)
    return oldsz;
    8000164e:	84ae                	mv	s1,a1
  if(newsz >= oldsz)
    80001650:	00b67d63          	bgeu	a2,a1,8000166a <uvmdealloc+0x26>
    80001654:	84b2                	mv	s1,a2

  if(PGROUNDUP(newsz) < PGROUNDUP(oldsz)){
    80001656:	6785                	lui	a5,0x1
    80001658:	17fd                	addi	a5,a5,-1
    8000165a:	00f60733          	add	a4,a2,a5
    8000165e:	767d                	lui	a2,0xfffff
    80001660:	8f71                	and	a4,a4,a2
    80001662:	97ae                	add	a5,a5,a1
    80001664:	8ff1                	and	a5,a5,a2
    80001666:	00f76863          	bltu	a4,a5,80001676 <uvmdealloc+0x32>
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
  }

  return newsz;
}
    8000166a:	8526                	mv	a0,s1
    8000166c:	60e2                	ld	ra,24(sp)
    8000166e:	6442                	ld	s0,16(sp)
    80001670:	64a2                	ld	s1,8(sp)
    80001672:	6105                	addi	sp,sp,32
    80001674:	8082                	ret
    int npages = (PGROUNDUP(oldsz) - PGROUNDUP(newsz)) / PGSIZE;
    80001676:	8f99                	sub	a5,a5,a4
    80001678:	83b1                	srli	a5,a5,0xc
    uvmunmap(pagetable, PGROUNDUP(newsz), npages, 1);
    8000167a:	4685                	li	a3,1
    8000167c:	0007861b          	sext.w	a2,a5
    80001680:	85ba                	mv	a1,a4
    80001682:	00000097          	auipc	ra,0x0
    80001686:	e5e080e7          	jalr	-418(ra) # 800014e0 <uvmunmap>
    8000168a:	b7c5                	j	8000166a <uvmdealloc+0x26>

000000008000168c <uvmalloc>:
  if(newsz < oldsz)
    8000168c:	0ab66163          	bltu	a2,a1,8000172e <uvmalloc+0xa2>
{
    80001690:	7139                	addi	sp,sp,-64
    80001692:	fc06                	sd	ra,56(sp)
    80001694:	f822                	sd	s0,48(sp)
    80001696:	f426                	sd	s1,40(sp)
    80001698:	f04a                	sd	s2,32(sp)
    8000169a:	ec4e                	sd	s3,24(sp)
    8000169c:	e852                	sd	s4,16(sp)
    8000169e:	e456                	sd	s5,8(sp)
    800016a0:	0080                	addi	s0,sp,64
    800016a2:	8aaa                	mv	s5,a0
    800016a4:	8a32                	mv	s4,a2
  oldsz = PGROUNDUP(oldsz);
    800016a6:	6985                	lui	s3,0x1
    800016a8:	19fd                	addi	s3,s3,-1
    800016aa:	95ce                	add	a1,a1,s3
    800016ac:	79fd                	lui	s3,0xfffff
    800016ae:	0135f9b3          	and	s3,a1,s3
  for(a = oldsz; a < newsz; a += PGSIZE){
    800016b2:	08c9f063          	bgeu	s3,a2,80001732 <uvmalloc+0xa6>
    800016b6:	894e                	mv	s2,s3
    mem = kalloc();
    800016b8:	fffff097          	auipc	ra,0xfffff
    800016bc:	558080e7          	jalr	1368(ra) # 80000c10 <kalloc>
    800016c0:	84aa                	mv	s1,a0
    if(mem == 0){
    800016c2:	c51d                	beqz	a0,800016f0 <uvmalloc+0x64>
    memset(mem, 0, PGSIZE);
    800016c4:	6605                	lui	a2,0x1
    800016c6:	4581                	li	a1,0
    800016c8:	00000097          	auipc	ra,0x0
    800016cc:	882080e7          	jalr	-1918(ra) # 80000f4a <memset>
    if(mappages(pagetable, a, PGSIZE, (uint64)mem, PTE_W|PTE_X|PTE_R|PTE_U) != 0){
    800016d0:	4779                	li	a4,30
    800016d2:	86a6                	mv	a3,s1
    800016d4:	6605                	lui	a2,0x1
    800016d6:	85ca                	mv	a1,s2
    800016d8:	8556                	mv	a0,s5
    800016da:	00000097          	auipc	ra,0x0
    800016de:	c40080e7          	jalr	-960(ra) # 8000131a <mappages>
    800016e2:	e905                	bnez	a0,80001712 <uvmalloc+0x86>
  for(a = oldsz; a < newsz; a += PGSIZE){
    800016e4:	6785                	lui	a5,0x1
    800016e6:	993e                	add	s2,s2,a5
    800016e8:	fd4968e3          	bltu	s2,s4,800016b8 <uvmalloc+0x2c>
  return newsz;
    800016ec:	8552                	mv	a0,s4
    800016ee:	a809                	j	80001700 <uvmalloc+0x74>
      uvmdealloc(pagetable, a, oldsz);
    800016f0:	864e                	mv	a2,s3
    800016f2:	85ca                	mv	a1,s2
    800016f4:	8556                	mv	a0,s5
    800016f6:	00000097          	auipc	ra,0x0
    800016fa:	f4e080e7          	jalr	-178(ra) # 80001644 <uvmdealloc>
      return 0;
    800016fe:	4501                	li	a0,0
}
    80001700:	70e2                	ld	ra,56(sp)
    80001702:	7442                	ld	s0,48(sp)
    80001704:	74a2                	ld	s1,40(sp)
    80001706:	7902                	ld	s2,32(sp)
    80001708:	69e2                	ld	s3,24(sp)
    8000170a:	6a42                	ld	s4,16(sp)
    8000170c:	6aa2                	ld	s5,8(sp)
    8000170e:	6121                	addi	sp,sp,64
    80001710:	8082                	ret
      kfree(mem);
    80001712:	8526                	mv	a0,s1
    80001714:	fffff097          	auipc	ra,0xfffff
    80001718:	3e4080e7          	jalr	996(ra) # 80000af8 <kfree>
      uvmdealloc(pagetable, a, oldsz);
    8000171c:	864e                	mv	a2,s3
    8000171e:	85ca                	mv	a1,s2
    80001720:	8556                	mv	a0,s5
    80001722:	00000097          	auipc	ra,0x0
    80001726:	f22080e7          	jalr	-222(ra) # 80001644 <uvmdealloc>
      return 0;
    8000172a:	4501                	li	a0,0
    8000172c:	bfd1                	j	80001700 <uvmalloc+0x74>
    return oldsz;
    8000172e:	852e                	mv	a0,a1
}
    80001730:	8082                	ret
  return newsz;
    80001732:	8532                	mv	a0,a2
    80001734:	b7f1                	j	80001700 <uvmalloc+0x74>

0000000080001736 <freewalk>:

// Recursively free page-table pages.
// All leaf mappings must already have been removed.
void
freewalk(pagetable_t pagetable)
{
    80001736:	7179                	addi	sp,sp,-48
    80001738:	f406                	sd	ra,40(sp)
    8000173a:	f022                	sd	s0,32(sp)
    8000173c:	ec26                	sd	s1,24(sp)
    8000173e:	e84a                	sd	s2,16(sp)
    80001740:	e44e                	sd	s3,8(sp)
    80001742:	e052                	sd	s4,0(sp)
    80001744:	1800                	addi	s0,sp,48
    80001746:	8a2a                	mv	s4,a0
  // there are 2^9 = 512 PTEs in a page table.
  for(int i = 0; i < 512; i++){
    80001748:	84aa                	mv	s1,a0
    8000174a:	6905                	lui	s2,0x1
    8000174c:	992a                	add	s2,s2,a0
    pte_t pte = pagetable[i];
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000174e:	4985                	li	s3,1
    80001750:	a821                	j	80001768 <freewalk+0x32>
      // this PTE points to a lower-level page table.
      uint64 child = PTE2PA(pte);
    80001752:	8129                	srli	a0,a0,0xa
      freewalk((pagetable_t)child);
    80001754:	0532                	slli	a0,a0,0xc
    80001756:	00000097          	auipc	ra,0x0
    8000175a:	fe0080e7          	jalr	-32(ra) # 80001736 <freewalk>
      pagetable[i] = 0;
    8000175e:	0004b023          	sd	zero,0(s1)
  for(int i = 0; i < 512; i++){
    80001762:	04a1                	addi	s1,s1,8
    80001764:	03248163          	beq	s1,s2,80001786 <freewalk+0x50>
    pte_t pte = pagetable[i];
    80001768:	6088                	ld	a0,0(s1)
    if((pte & PTE_V) && (pte & (PTE_R|PTE_W|PTE_X)) == 0){
    8000176a:	00f57793          	andi	a5,a0,15
    8000176e:	ff3782e3          	beq	a5,s3,80001752 <freewalk+0x1c>
    } else if(pte & PTE_V){
    80001772:	8905                	andi	a0,a0,1
    80001774:	d57d                	beqz	a0,80001762 <freewalk+0x2c>
      panic("freewalk: leaf");
    80001776:	00007517          	auipc	a0,0x7
    8000177a:	a7250513          	addi	a0,a0,-1422 # 800081e8 <digits+0x1a8>
    8000177e:	fffff097          	auipc	ra,0xfffff
    80001782:	dc0080e7          	jalr	-576(ra) # 8000053e <panic>
    }
  }
  kfree((void*)pagetable);
    80001786:	8552                	mv	a0,s4
    80001788:	fffff097          	auipc	ra,0xfffff
    8000178c:	370080e7          	jalr	880(ra) # 80000af8 <kfree>
}
    80001790:	70a2                	ld	ra,40(sp)
    80001792:	7402                	ld	s0,32(sp)
    80001794:	64e2                	ld	s1,24(sp)
    80001796:	6942                	ld	s2,16(sp)
    80001798:	69a2                	ld	s3,8(sp)
    8000179a:	6a02                	ld	s4,0(sp)
    8000179c:	6145                	addi	sp,sp,48
    8000179e:	8082                	ret

00000000800017a0 <uvmfree>:

// Free user memory pages,
// then free page-table pages.
void
uvmfree(pagetable_t pagetable, uint64 sz)
{
    800017a0:	1101                	addi	sp,sp,-32
    800017a2:	ec06                	sd	ra,24(sp)
    800017a4:	e822                	sd	s0,16(sp)
    800017a6:	e426                	sd	s1,8(sp)
    800017a8:	1000                	addi	s0,sp,32
    800017aa:	84aa                	mv	s1,a0
  if(sz > 0)
    800017ac:	e999                	bnez	a1,800017c2 <uvmfree+0x22>
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
  freewalk(pagetable);
    800017ae:	8526                	mv	a0,s1
    800017b0:	00000097          	auipc	ra,0x0
    800017b4:	f86080e7          	jalr	-122(ra) # 80001736 <freewalk>
}
    800017b8:	60e2                	ld	ra,24(sp)
    800017ba:	6442                	ld	s0,16(sp)
    800017bc:	64a2                	ld	s1,8(sp)
    800017be:	6105                	addi	sp,sp,32
    800017c0:	8082                	ret
    uvmunmap(pagetable, 0, PGROUNDUP(sz)/PGSIZE, 1);
    800017c2:	6605                	lui	a2,0x1
    800017c4:	167d                	addi	a2,a2,-1
    800017c6:	962e                	add	a2,a2,a1
    800017c8:	4685                	li	a3,1
    800017ca:	8231                	srli	a2,a2,0xc
    800017cc:	4581                	li	a1,0
    800017ce:	00000097          	auipc	ra,0x0
    800017d2:	d12080e7          	jalr	-750(ra) # 800014e0 <uvmunmap>
    800017d6:	bfe1                	j	800017ae <uvmfree+0xe>

00000000800017d8 <uvmcopy>:
  pte_t *pte;
  uint64 pa, i;
  uint flags;
  char *mem;

  for(i = 0; i < sz; i += PGSIZE){
    800017d8:	c679                	beqz	a2,800018a6 <uvmcopy+0xce>
{
    800017da:	715d                	addi	sp,sp,-80
    800017dc:	e486                	sd	ra,72(sp)
    800017de:	e0a2                	sd	s0,64(sp)
    800017e0:	fc26                	sd	s1,56(sp)
    800017e2:	f84a                	sd	s2,48(sp)
    800017e4:	f44e                	sd	s3,40(sp)
    800017e6:	f052                	sd	s4,32(sp)
    800017e8:	ec56                	sd	s5,24(sp)
    800017ea:	e85a                	sd	s6,16(sp)
    800017ec:	e45e                	sd	s7,8(sp)
    800017ee:	0880                	addi	s0,sp,80
    800017f0:	8b2a                	mv	s6,a0
    800017f2:	8aae                	mv	s5,a1
    800017f4:	8a32                	mv	s4,a2
  for(i = 0; i < sz; i += PGSIZE){
    800017f6:	4981                	li	s3,0
    if((pte = walk(old, i, 0)) == 0)
    800017f8:	4601                	li	a2,0
    800017fa:	85ce                	mv	a1,s3
    800017fc:	855a                	mv	a0,s6
    800017fe:	00000097          	auipc	ra,0x0
    80001802:	a34080e7          	jalr	-1484(ra) # 80001232 <walk>
    80001806:	c531                	beqz	a0,80001852 <uvmcopy+0x7a>
      panic("uvmcopy: pte should exist");
    if((*pte & PTE_V) == 0)
    80001808:	6118                	ld	a4,0(a0)
    8000180a:	00177793          	andi	a5,a4,1
    8000180e:	cbb1                	beqz	a5,80001862 <uvmcopy+0x8a>
      panic("uvmcopy: page not present");
    pa = PTE2PA(*pte);
    80001810:	00a75593          	srli	a1,a4,0xa
    80001814:	00c59b93          	slli	s7,a1,0xc
    flags = PTE_FLAGS(*pte);
    80001818:	3ff77493          	andi	s1,a4,1023
    if((mem = kalloc()) == 0)
    8000181c:	fffff097          	auipc	ra,0xfffff
    80001820:	3f4080e7          	jalr	1012(ra) # 80000c10 <kalloc>
    80001824:	892a                	mv	s2,a0
    80001826:	c939                	beqz	a0,8000187c <uvmcopy+0xa4>
      goto err;
    memmove(mem, (char*)pa, PGSIZE);
    80001828:	6605                	lui	a2,0x1
    8000182a:	85de                	mv	a1,s7
    8000182c:	fffff097          	auipc	ra,0xfffff
    80001830:	77e080e7          	jalr	1918(ra) # 80000faa <memmove>
    if(mappages(new, i, PGSIZE, (uint64)mem, flags) != 0){
    80001834:	8726                	mv	a4,s1
    80001836:	86ca                	mv	a3,s2
    80001838:	6605                	lui	a2,0x1
    8000183a:	85ce                	mv	a1,s3
    8000183c:	8556                	mv	a0,s5
    8000183e:	00000097          	auipc	ra,0x0
    80001842:	adc080e7          	jalr	-1316(ra) # 8000131a <mappages>
    80001846:	e515                	bnez	a0,80001872 <uvmcopy+0x9a>
  for(i = 0; i < sz; i += PGSIZE){
    80001848:	6785                	lui	a5,0x1
    8000184a:	99be                	add	s3,s3,a5
    8000184c:	fb49e6e3          	bltu	s3,s4,800017f8 <uvmcopy+0x20>
    80001850:	a081                	j	80001890 <uvmcopy+0xb8>
      panic("uvmcopy: pte should exist");
    80001852:	00007517          	auipc	a0,0x7
    80001856:	9a650513          	addi	a0,a0,-1626 # 800081f8 <digits+0x1b8>
    8000185a:	fffff097          	auipc	ra,0xfffff
    8000185e:	ce4080e7          	jalr	-796(ra) # 8000053e <panic>
      panic("uvmcopy: page not present");
    80001862:	00007517          	auipc	a0,0x7
    80001866:	9b650513          	addi	a0,a0,-1610 # 80008218 <digits+0x1d8>
    8000186a:	fffff097          	auipc	ra,0xfffff
    8000186e:	cd4080e7          	jalr	-812(ra) # 8000053e <panic>
      kfree(mem);
    80001872:	854a                	mv	a0,s2
    80001874:	fffff097          	auipc	ra,0xfffff
    80001878:	284080e7          	jalr	644(ra) # 80000af8 <kfree>
    }
  }
  return 0;

 err:
  uvmunmap(new, 0, i / PGSIZE, 1);
    8000187c:	4685                	li	a3,1
    8000187e:	00c9d613          	srli	a2,s3,0xc
    80001882:	4581                	li	a1,0
    80001884:	8556                	mv	a0,s5
    80001886:	00000097          	auipc	ra,0x0
    8000188a:	c5a080e7          	jalr	-934(ra) # 800014e0 <uvmunmap>
  return -1;
    8000188e:	557d                	li	a0,-1
}
    80001890:	60a6                	ld	ra,72(sp)
    80001892:	6406                	ld	s0,64(sp)
    80001894:	74e2                	ld	s1,56(sp)
    80001896:	7942                	ld	s2,48(sp)
    80001898:	79a2                	ld	s3,40(sp)
    8000189a:	7a02                	ld	s4,32(sp)
    8000189c:	6ae2                	ld	s5,24(sp)
    8000189e:	6b42                	ld	s6,16(sp)
    800018a0:	6ba2                	ld	s7,8(sp)
    800018a2:	6161                	addi	sp,sp,80
    800018a4:	8082                	ret
  return 0;
    800018a6:	4501                	li	a0,0
}
    800018a8:	8082                	ret

00000000800018aa <uvmclear>:

// mark a PTE invalid for user access.
// used by exec for the user stack guard page.
void
uvmclear(pagetable_t pagetable, uint64 va)
{
    800018aa:	1141                	addi	sp,sp,-16
    800018ac:	e406                	sd	ra,8(sp)
    800018ae:	e022                	sd	s0,0(sp)
    800018b0:	0800                	addi	s0,sp,16
  pte_t *pte;
  
  pte = walk(pagetable, va, 0);
    800018b2:	4601                	li	a2,0
    800018b4:	00000097          	auipc	ra,0x0
    800018b8:	97e080e7          	jalr	-1666(ra) # 80001232 <walk>
  if(pte == 0)
    800018bc:	c901                	beqz	a0,800018cc <uvmclear+0x22>
    panic("uvmclear");
  *pte &= ~PTE_U;
    800018be:	611c                	ld	a5,0(a0)
    800018c0:	9bbd                	andi	a5,a5,-17
    800018c2:	e11c                	sd	a5,0(a0)
}
    800018c4:	60a2                	ld	ra,8(sp)
    800018c6:	6402                	ld	s0,0(sp)
    800018c8:	0141                	addi	sp,sp,16
    800018ca:	8082                	ret
    panic("uvmclear");
    800018cc:	00007517          	auipc	a0,0x7
    800018d0:	96c50513          	addi	a0,a0,-1684 # 80008238 <digits+0x1f8>
    800018d4:	fffff097          	auipc	ra,0xfffff
    800018d8:	c6a080e7          	jalr	-918(ra) # 8000053e <panic>

00000000800018dc <copyout>:
int
copyout(pagetable_t pagetable, uint64 dstva, char *src, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    800018dc:	c6bd                	beqz	a3,8000194a <copyout+0x6e>
{
    800018de:	715d                	addi	sp,sp,-80
    800018e0:	e486                	sd	ra,72(sp)
    800018e2:	e0a2                	sd	s0,64(sp)
    800018e4:	fc26                	sd	s1,56(sp)
    800018e6:	f84a                	sd	s2,48(sp)
    800018e8:	f44e                	sd	s3,40(sp)
    800018ea:	f052                	sd	s4,32(sp)
    800018ec:	ec56                	sd	s5,24(sp)
    800018ee:	e85a                	sd	s6,16(sp)
    800018f0:	e45e                	sd	s7,8(sp)
    800018f2:	e062                	sd	s8,0(sp)
    800018f4:	0880                	addi	s0,sp,80
    800018f6:	8b2a                	mv	s6,a0
    800018f8:	8c2e                	mv	s8,a1
    800018fa:	8a32                	mv	s4,a2
    800018fc:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(dstva);
    800018fe:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (dstva - va0);
    80001900:	6a85                	lui	s5,0x1
    80001902:	a015                	j	80001926 <copyout+0x4a>
    if(n > len)
      n = len;
    memmove((void *)(pa0 + (dstva - va0)), src, n);
    80001904:	9562                	add	a0,a0,s8
    80001906:	0004861b          	sext.w	a2,s1
    8000190a:	85d2                	mv	a1,s4
    8000190c:	41250533          	sub	a0,a0,s2
    80001910:	fffff097          	auipc	ra,0xfffff
    80001914:	69a080e7          	jalr	1690(ra) # 80000faa <memmove>

    len -= n;
    80001918:	409989b3          	sub	s3,s3,s1
    src += n;
    8000191c:	9a26                	add	s4,s4,s1
    dstva = va0 + PGSIZE;
    8000191e:	01590c33          	add	s8,s2,s5
  while(len > 0){
    80001922:	02098263          	beqz	s3,80001946 <copyout+0x6a>
    va0 = PGROUNDDOWN(dstva);
    80001926:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    8000192a:	85ca                	mv	a1,s2
    8000192c:	855a                	mv	a0,s6
    8000192e:	00000097          	auipc	ra,0x0
    80001932:	9aa080e7          	jalr	-1622(ra) # 800012d8 <walkaddr>
    if(pa0 == 0)
    80001936:	cd01                	beqz	a0,8000194e <copyout+0x72>
    n = PGSIZE - (dstva - va0);
    80001938:	418904b3          	sub	s1,s2,s8
    8000193c:	94d6                	add	s1,s1,s5
    if(n > len)
    8000193e:	fc99f3e3          	bgeu	s3,s1,80001904 <copyout+0x28>
    80001942:	84ce                	mv	s1,s3
    80001944:	b7c1                	j	80001904 <copyout+0x28>
  }
  return 0;
    80001946:	4501                	li	a0,0
    80001948:	a021                	j	80001950 <copyout+0x74>
    8000194a:	4501                	li	a0,0
}
    8000194c:	8082                	ret
      return -1;
    8000194e:	557d                	li	a0,-1
}
    80001950:	60a6                	ld	ra,72(sp)
    80001952:	6406                	ld	s0,64(sp)
    80001954:	74e2                	ld	s1,56(sp)
    80001956:	7942                	ld	s2,48(sp)
    80001958:	79a2                	ld	s3,40(sp)
    8000195a:	7a02                	ld	s4,32(sp)
    8000195c:	6ae2                	ld	s5,24(sp)
    8000195e:	6b42                	ld	s6,16(sp)
    80001960:	6ba2                	ld	s7,8(sp)
    80001962:	6c02                	ld	s8,0(sp)
    80001964:	6161                	addi	sp,sp,80
    80001966:	8082                	ret

0000000080001968 <copyin>:
int
copyin(pagetable_t pagetable, char *dst, uint64 srcva, uint64 len)
{
  uint64 n, va0, pa0;

  while(len > 0){
    80001968:	c6bd                	beqz	a3,800019d6 <copyin+0x6e>
{
    8000196a:	715d                	addi	sp,sp,-80
    8000196c:	e486                	sd	ra,72(sp)
    8000196e:	e0a2                	sd	s0,64(sp)
    80001970:	fc26                	sd	s1,56(sp)
    80001972:	f84a                	sd	s2,48(sp)
    80001974:	f44e                	sd	s3,40(sp)
    80001976:	f052                	sd	s4,32(sp)
    80001978:	ec56                	sd	s5,24(sp)
    8000197a:	e85a                	sd	s6,16(sp)
    8000197c:	e45e                	sd	s7,8(sp)
    8000197e:	e062                	sd	s8,0(sp)
    80001980:	0880                	addi	s0,sp,80
    80001982:	8b2a                	mv	s6,a0
    80001984:	8a2e                	mv	s4,a1
    80001986:	8c32                	mv	s8,a2
    80001988:	89b6                	mv	s3,a3
    va0 = PGROUNDDOWN(srcva);
    8000198a:	7bfd                	lui	s7,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    8000198c:	6a85                	lui	s5,0x1
    8000198e:	a015                	j	800019b2 <copyin+0x4a>
    if(n > len)
      n = len;
    memmove(dst, (void *)(pa0 + (srcva - va0)), n);
    80001990:	9562                	add	a0,a0,s8
    80001992:	0004861b          	sext.w	a2,s1
    80001996:	412505b3          	sub	a1,a0,s2
    8000199a:	8552                	mv	a0,s4
    8000199c:	fffff097          	auipc	ra,0xfffff
    800019a0:	60e080e7          	jalr	1550(ra) # 80000faa <memmove>

    len -= n;
    800019a4:	409989b3          	sub	s3,s3,s1
    dst += n;
    800019a8:	9a26                	add	s4,s4,s1
    srcva = va0 + PGSIZE;
    800019aa:	01590c33          	add	s8,s2,s5
  while(len > 0){
    800019ae:	02098263          	beqz	s3,800019d2 <copyin+0x6a>
    va0 = PGROUNDDOWN(srcva);
    800019b2:	017c7933          	and	s2,s8,s7
    pa0 = walkaddr(pagetable, va0);
    800019b6:	85ca                	mv	a1,s2
    800019b8:	855a                	mv	a0,s6
    800019ba:	00000097          	auipc	ra,0x0
    800019be:	91e080e7          	jalr	-1762(ra) # 800012d8 <walkaddr>
    if(pa0 == 0)
    800019c2:	cd01                	beqz	a0,800019da <copyin+0x72>
    n = PGSIZE - (srcva - va0);
    800019c4:	418904b3          	sub	s1,s2,s8
    800019c8:	94d6                	add	s1,s1,s5
    if(n > len)
    800019ca:	fc99f3e3          	bgeu	s3,s1,80001990 <copyin+0x28>
    800019ce:	84ce                	mv	s1,s3
    800019d0:	b7c1                	j	80001990 <copyin+0x28>
  }
  return 0;
    800019d2:	4501                	li	a0,0
    800019d4:	a021                	j	800019dc <copyin+0x74>
    800019d6:	4501                	li	a0,0
}
    800019d8:	8082                	ret
      return -1;
    800019da:	557d                	li	a0,-1
}
    800019dc:	60a6                	ld	ra,72(sp)
    800019de:	6406                	ld	s0,64(sp)
    800019e0:	74e2                	ld	s1,56(sp)
    800019e2:	7942                	ld	s2,48(sp)
    800019e4:	79a2                	ld	s3,40(sp)
    800019e6:	7a02                	ld	s4,32(sp)
    800019e8:	6ae2                	ld	s5,24(sp)
    800019ea:	6b42                	ld	s6,16(sp)
    800019ec:	6ba2                	ld	s7,8(sp)
    800019ee:	6c02                	ld	s8,0(sp)
    800019f0:	6161                	addi	sp,sp,80
    800019f2:	8082                	ret

00000000800019f4 <copyinstr>:
copyinstr(pagetable_t pagetable, char *dst, uint64 srcva, uint64 max)
{
  uint64 n, va0, pa0;
  int got_null = 0;

  while(got_null == 0 && max > 0){
    800019f4:	c6c5                	beqz	a3,80001a9c <copyinstr+0xa8>
{
    800019f6:	715d                	addi	sp,sp,-80
    800019f8:	e486                	sd	ra,72(sp)
    800019fa:	e0a2                	sd	s0,64(sp)
    800019fc:	fc26                	sd	s1,56(sp)
    800019fe:	f84a                	sd	s2,48(sp)
    80001a00:	f44e                	sd	s3,40(sp)
    80001a02:	f052                	sd	s4,32(sp)
    80001a04:	ec56                	sd	s5,24(sp)
    80001a06:	e85a                	sd	s6,16(sp)
    80001a08:	e45e                	sd	s7,8(sp)
    80001a0a:	0880                	addi	s0,sp,80
    80001a0c:	8a2a                	mv	s4,a0
    80001a0e:	8b2e                	mv	s6,a1
    80001a10:	8bb2                	mv	s7,a2
    80001a12:	84b6                	mv	s1,a3
    va0 = PGROUNDDOWN(srcva);
    80001a14:	7afd                	lui	s5,0xfffff
    pa0 = walkaddr(pagetable, va0);
    if(pa0 == 0)
      return -1;
    n = PGSIZE - (srcva - va0);
    80001a16:	6985                	lui	s3,0x1
    80001a18:	a035                	j	80001a44 <copyinstr+0x50>
      n = max;

    char *p = (char *) (pa0 + (srcva - va0));
    while(n > 0){
      if(*p == '\0'){
        *dst = '\0';
    80001a1a:	00078023          	sb	zero,0(a5) # 1000 <_entry-0x7ffff000>
    80001a1e:	4785                	li	a5,1
      dst++;
    }

    srcva = va0 + PGSIZE;
  }
  if(got_null){
    80001a20:	0017b793          	seqz	a5,a5
    80001a24:	40f00533          	neg	a0,a5
    return 0;
  } else {
    return -1;
  }
}
    80001a28:	60a6                	ld	ra,72(sp)
    80001a2a:	6406                	ld	s0,64(sp)
    80001a2c:	74e2                	ld	s1,56(sp)
    80001a2e:	7942                	ld	s2,48(sp)
    80001a30:	79a2                	ld	s3,40(sp)
    80001a32:	7a02                	ld	s4,32(sp)
    80001a34:	6ae2                	ld	s5,24(sp)
    80001a36:	6b42                	ld	s6,16(sp)
    80001a38:	6ba2                	ld	s7,8(sp)
    80001a3a:	6161                	addi	sp,sp,80
    80001a3c:	8082                	ret
    srcva = va0 + PGSIZE;
    80001a3e:	01390bb3          	add	s7,s2,s3
  while(got_null == 0 && max > 0){
    80001a42:	c8a9                	beqz	s1,80001a94 <copyinstr+0xa0>
    va0 = PGROUNDDOWN(srcva);
    80001a44:	015bf933          	and	s2,s7,s5
    pa0 = walkaddr(pagetable, va0);
    80001a48:	85ca                	mv	a1,s2
    80001a4a:	8552                	mv	a0,s4
    80001a4c:	00000097          	auipc	ra,0x0
    80001a50:	88c080e7          	jalr	-1908(ra) # 800012d8 <walkaddr>
    if(pa0 == 0)
    80001a54:	c131                	beqz	a0,80001a98 <copyinstr+0xa4>
    n = PGSIZE - (srcva - va0);
    80001a56:	41790833          	sub	a6,s2,s7
    80001a5a:	984e                	add	a6,a6,s3
    if(n > max)
    80001a5c:	0104f363          	bgeu	s1,a6,80001a62 <copyinstr+0x6e>
    80001a60:	8826                	mv	a6,s1
    char *p = (char *) (pa0 + (srcva - va0));
    80001a62:	955e                	add	a0,a0,s7
    80001a64:	41250533          	sub	a0,a0,s2
    while(n > 0){
    80001a68:	fc080be3          	beqz	a6,80001a3e <copyinstr+0x4a>
    80001a6c:	985a                	add	a6,a6,s6
    80001a6e:	87da                	mv	a5,s6
      if(*p == '\0'){
    80001a70:	41650633          	sub	a2,a0,s6
    80001a74:	14fd                	addi	s1,s1,-1
    80001a76:	9b26                	add	s6,s6,s1
    80001a78:	00f60733          	add	a4,a2,a5
    80001a7c:	00074703          	lbu	a4,0(a4)
    80001a80:	df49                	beqz	a4,80001a1a <copyinstr+0x26>
        *dst = *p;
    80001a82:	00e78023          	sb	a4,0(a5)
      --max;
    80001a86:	40fb04b3          	sub	s1,s6,a5
      dst++;
    80001a8a:	0785                	addi	a5,a5,1
    while(n > 0){
    80001a8c:	ff0796e3          	bne	a5,a6,80001a78 <copyinstr+0x84>
      dst++;
    80001a90:	8b42                	mv	s6,a6
    80001a92:	b775                	j	80001a3e <copyinstr+0x4a>
    80001a94:	4781                	li	a5,0
    80001a96:	b769                	j	80001a20 <copyinstr+0x2c>
      return -1;
    80001a98:	557d                	li	a0,-1
    80001a9a:	b779                	j	80001a28 <copyinstr+0x34>
  int got_null = 0;
    80001a9c:	4781                	li	a5,0
  if(got_null){
    80001a9e:	0017b793          	seqz	a5,a5
    80001aa2:	40f00533          	neg	a0,a5
}
    80001aa6:	8082                	ret

0000000080001aa8 <proc_mapstacks>:

// Allocate a page for each process's kernel stack.
// Map it high in memory, followed by an invalid
// guard page.
void
proc_mapstacks(pagetable_t kpgtbl) {
    80001aa8:	7139                	addi	sp,sp,-64
    80001aaa:	fc06                	sd	ra,56(sp)
    80001aac:	f822                	sd	s0,48(sp)
    80001aae:	f426                	sd	s1,40(sp)
    80001ab0:	f04a                	sd	s2,32(sp)
    80001ab2:	ec4e                	sd	s3,24(sp)
    80001ab4:	e852                	sd	s4,16(sp)
    80001ab6:	e456                	sd	s5,8(sp)
    80001ab8:	e05a                	sd	s6,0(sp)
    80001aba:	0080                	addi	s0,sp,64
    80001abc:	89aa                	mv	s3,a0
  struct proc *p;
  
  for(p = proc; p < &proc[NPROC]; p++) {
    80001abe:	00890497          	auipc	s1,0x890
    80001ac2:	c1248493          	addi	s1,s1,-1006 # 808916d0 <proc>
    char *pa = kalloc();
    if(pa == 0)
      panic("kalloc");
    uint64 va = KSTACK((int) (p - proc));
    80001ac6:	8b26                	mv	s6,s1
    80001ac8:	00006a97          	auipc	s5,0x6
    80001acc:	538a8a93          	addi	s5,s5,1336 # 80008000 <etext>
    80001ad0:	04000937          	lui	s2,0x4000
    80001ad4:	197d                	addi	s2,s2,-1
    80001ad6:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ad8:	00896a17          	auipc	s4,0x896
    80001adc:	9f8a0a13          	addi	s4,s4,-1544 # 808974d0 <tickslock>
    char *pa = kalloc();
    80001ae0:	fffff097          	auipc	ra,0xfffff
    80001ae4:	130080e7          	jalr	304(ra) # 80000c10 <kalloc>
    80001ae8:	862a                	mv	a2,a0
    if(pa == 0)
    80001aea:	c131                	beqz	a0,80001b2e <proc_mapstacks+0x86>
    uint64 va = KSTACK((int) (p - proc));
    80001aec:	416485b3          	sub	a1,s1,s6
    80001af0:	858d                	srai	a1,a1,0x3
    80001af2:	000ab783          	ld	a5,0(s5)
    80001af6:	02f585b3          	mul	a1,a1,a5
    80001afa:	2585                	addiw	a1,a1,1
    80001afc:	00d5959b          	slliw	a1,a1,0xd
    kvmmap(kpgtbl, va, (uint64)pa, PGSIZE, PTE_R | PTE_W);
    80001b00:	4719                	li	a4,6
    80001b02:	6685                	lui	a3,0x1
    80001b04:	40b905b3          	sub	a1,s2,a1
    80001b08:	854e                	mv	a0,s3
    80001b0a:	00000097          	auipc	ra,0x0
    80001b0e:	8b0080e7          	jalr	-1872(ra) # 800013ba <kvmmap>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b12:	17848493          	addi	s1,s1,376
    80001b16:	fd4495e3          	bne	s1,s4,80001ae0 <proc_mapstacks+0x38>
  }
}
    80001b1a:	70e2                	ld	ra,56(sp)
    80001b1c:	7442                	ld	s0,48(sp)
    80001b1e:	74a2                	ld	s1,40(sp)
    80001b20:	7902                	ld	s2,32(sp)
    80001b22:	69e2                	ld	s3,24(sp)
    80001b24:	6a42                	ld	s4,16(sp)
    80001b26:	6aa2                	ld	s5,8(sp)
    80001b28:	6b02                	ld	s6,0(sp)
    80001b2a:	6121                	addi	sp,sp,64
    80001b2c:	8082                	ret
      panic("kalloc");
    80001b2e:	00006517          	auipc	a0,0x6
    80001b32:	71a50513          	addi	a0,a0,1818 # 80008248 <digits+0x208>
    80001b36:	fffff097          	auipc	ra,0xfffff
    80001b3a:	a08080e7          	jalr	-1528(ra) # 8000053e <panic>

0000000080001b3e <procinit>:

// initialize the proc table at boot time.
void
procinit(void)
{
    80001b3e:	7139                	addi	sp,sp,-64
    80001b40:	fc06                	sd	ra,56(sp)
    80001b42:	f822                	sd	s0,48(sp)
    80001b44:	f426                	sd	s1,40(sp)
    80001b46:	f04a                	sd	s2,32(sp)
    80001b48:	ec4e                	sd	s3,24(sp)
    80001b4a:	e852                	sd	s4,16(sp)
    80001b4c:	e456                	sd	s5,8(sp)
    80001b4e:	e05a                	sd	s6,0(sp)
    80001b50:	0080                	addi	s0,sp,64
  struct proc *p;
  
  initlock(&pid_lock, "nextpid");
    80001b52:	00006597          	auipc	a1,0x6
    80001b56:	6fe58593          	addi	a1,a1,1790 # 80008250 <digits+0x210>
    80001b5a:	0088f517          	auipc	a0,0x88f
    80001b5e:	74650513          	addi	a0,a0,1862 # 808912a0 <pid_lock>
    80001b62:	fffff097          	auipc	ra,0xfffff
    80001b66:	25c080e7          	jalr	604(ra) # 80000dbe <initlock>
  initlock(&wait_lock, "wait_lock");
    80001b6a:	00006597          	auipc	a1,0x6
    80001b6e:	6ee58593          	addi	a1,a1,1774 # 80008258 <digits+0x218>
    80001b72:	0088f517          	auipc	a0,0x88f
    80001b76:	74650513          	addi	a0,a0,1862 # 808912b8 <wait_lock>
    80001b7a:	fffff097          	auipc	ra,0xfffff
    80001b7e:	244080e7          	jalr	580(ra) # 80000dbe <initlock>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001b82:	00890497          	auipc	s1,0x890
    80001b86:	b4e48493          	addi	s1,s1,-1202 # 808916d0 <proc>
      initlock(&p->lock, "proc");
    80001b8a:	00006b17          	auipc	s6,0x6
    80001b8e:	6deb0b13          	addi	s6,s6,1758 # 80008268 <digits+0x228>
      p->kstack = KSTACK((int) (p - proc));
    80001b92:	8aa6                	mv	s5,s1
    80001b94:	00006a17          	auipc	s4,0x6
    80001b98:	46ca0a13          	addi	s4,s4,1132 # 80008000 <etext>
    80001b9c:	04000937          	lui	s2,0x4000
    80001ba0:	197d                	addi	s2,s2,-1
    80001ba2:	0932                	slli	s2,s2,0xc
  for(p = proc; p < &proc[NPROC]; p++) {
    80001ba4:	00896997          	auipc	s3,0x896
    80001ba8:	92c98993          	addi	s3,s3,-1748 # 808974d0 <tickslock>
      initlock(&p->lock, "proc");
    80001bac:	85da                	mv	a1,s6
    80001bae:	8526                	mv	a0,s1
    80001bb0:	fffff097          	auipc	ra,0xfffff
    80001bb4:	20e080e7          	jalr	526(ra) # 80000dbe <initlock>
      p->kstack = KSTACK((int) (p - proc));
    80001bb8:	415487b3          	sub	a5,s1,s5
    80001bbc:	878d                	srai	a5,a5,0x3
    80001bbe:	000a3703          	ld	a4,0(s4)
    80001bc2:	02e787b3          	mul	a5,a5,a4
    80001bc6:	2785                	addiw	a5,a5,1
    80001bc8:	00d7979b          	slliw	a5,a5,0xd
    80001bcc:	40f907b3          	sub	a5,s2,a5
    80001bd0:	e0bc                	sd	a5,64(s1)
  for(p = proc; p < &proc[NPROC]; p++) {
    80001bd2:	17848493          	addi	s1,s1,376
    80001bd6:	fd349be3          	bne	s1,s3,80001bac <procinit+0x6e>
  }
}
    80001bda:	70e2                	ld	ra,56(sp)
    80001bdc:	7442                	ld	s0,48(sp)
    80001bde:	74a2                	ld	s1,40(sp)
    80001be0:	7902                	ld	s2,32(sp)
    80001be2:	69e2                	ld	s3,24(sp)
    80001be4:	6a42                	ld	s4,16(sp)
    80001be6:	6aa2                	ld	s5,8(sp)
    80001be8:	6b02                	ld	s6,0(sp)
    80001bea:	6121                	addi	sp,sp,64
    80001bec:	8082                	ret

0000000080001bee <cpuid>:
// Must be called with interrupts disabled,
// to prevent race with process being moved
// to a different CPU.
int
cpuid()
{
    80001bee:	1141                	addi	sp,sp,-16
    80001bf0:	e422                	sd	s0,8(sp)
    80001bf2:	0800                	addi	s0,sp,16
  asm volatile("mv %0, tp" : "=r" (x) );
    80001bf4:	8512                	mv	a0,tp
  int id = r_tp();
  return id;
}
    80001bf6:	2501                	sext.w	a0,a0
    80001bf8:	6422                	ld	s0,8(sp)
    80001bfa:	0141                	addi	sp,sp,16
    80001bfc:	8082                	ret

0000000080001bfe <mycpu>:

// Return this CPU's cpu struct.
// Interrupts must be disabled.
struct cpu*
mycpu(void) {
    80001bfe:	1141                	addi	sp,sp,-16
    80001c00:	e422                	sd	s0,8(sp)
    80001c02:	0800                	addi	s0,sp,16
    80001c04:	8792                	mv	a5,tp
  int id = cpuid();
  struct cpu *c = &cpus[id];
    80001c06:	2781                	sext.w	a5,a5
    80001c08:	079e                	slli	a5,a5,0x7
  return c;
}
    80001c0a:	0088f517          	auipc	a0,0x88f
    80001c0e:	6c650513          	addi	a0,a0,1734 # 808912d0 <cpus>
    80001c12:	953e                	add	a0,a0,a5
    80001c14:	6422                	ld	s0,8(sp)
    80001c16:	0141                	addi	sp,sp,16
    80001c18:	8082                	ret

0000000080001c1a <myproc>:

// Return the current struct proc *, or zero if none.
struct proc*
myproc(void) {
    80001c1a:	1101                	addi	sp,sp,-32
    80001c1c:	ec06                	sd	ra,24(sp)
    80001c1e:	e822                	sd	s0,16(sp)
    80001c20:	e426                	sd	s1,8(sp)
    80001c22:	1000                	addi	s0,sp,32
  push_off();
    80001c24:	fffff097          	auipc	ra,0xfffff
    80001c28:	1de080e7          	jalr	478(ra) # 80000e02 <push_off>
    80001c2c:	8792                	mv	a5,tp
  struct cpu *c = mycpu();
  struct proc *p = c->proc;
    80001c2e:	2781                	sext.w	a5,a5
    80001c30:	079e                	slli	a5,a5,0x7
    80001c32:	0088f717          	auipc	a4,0x88f
    80001c36:	66e70713          	addi	a4,a4,1646 # 808912a0 <pid_lock>
    80001c3a:	97ba                	add	a5,a5,a4
    80001c3c:	7b84                	ld	s1,48(a5)
  pop_off();
    80001c3e:	fffff097          	auipc	ra,0xfffff
    80001c42:	264080e7          	jalr	612(ra) # 80000ea2 <pop_off>
  return p;
}
    80001c46:	8526                	mv	a0,s1
    80001c48:	60e2                	ld	ra,24(sp)
    80001c4a:	6442                	ld	s0,16(sp)
    80001c4c:	64a2                	ld	s1,8(sp)
    80001c4e:	6105                	addi	sp,sp,32
    80001c50:	8082                	ret

0000000080001c52 <forkret>:

// A fork child's very first scheduling by scheduler()
// will swtch to forkret.
void
forkret(void)
{
    80001c52:	1141                	addi	sp,sp,-16
    80001c54:	e406                	sd	ra,8(sp)
    80001c56:	e022                	sd	s0,0(sp)
    80001c58:	0800                	addi	s0,sp,16
  static int first = 1;

  // Still holding p->lock from scheduler.
  release(&myproc()->lock);
    80001c5a:	00000097          	auipc	ra,0x0
    80001c5e:	fc0080e7          	jalr	-64(ra) # 80001c1a <myproc>
    80001c62:	fffff097          	auipc	ra,0xfffff
    80001c66:	2a0080e7          	jalr	672(ra) # 80000f02 <release>

  if (first) {
    80001c6a:	00007797          	auipc	a5,0x7
    80001c6e:	ca67a783          	lw	a5,-858(a5) # 80008910 <first.1675>
    80001c72:	eb89                	bnez	a5,80001c84 <forkret+0x32>
    // be run from main().
    first = 0;
    fsinit(ROOTDEV);
  }

  usertrapret();
    80001c74:	00001097          	auipc	ra,0x1
    80001c78:	c16080e7          	jalr	-1002(ra) # 8000288a <usertrapret>
}
    80001c7c:	60a2                	ld	ra,8(sp)
    80001c7e:	6402                	ld	s0,0(sp)
    80001c80:	0141                	addi	sp,sp,16
    80001c82:	8082                	ret
    first = 0;
    80001c84:	00007797          	auipc	a5,0x7
    80001c88:	c807a623          	sw	zero,-884(a5) # 80008910 <first.1675>
    fsinit(ROOTDEV);
    80001c8c:	4505                	li	a0,1
    80001c8e:	00002097          	auipc	ra,0x2
    80001c92:	aa0080e7          	jalr	-1376(ra) # 8000372e <fsinit>
    80001c96:	bff9                	j	80001c74 <forkret+0x22>

0000000080001c98 <allocpid>:
allocpid() {
    80001c98:	1101                	addi	sp,sp,-32
    80001c9a:	ec06                	sd	ra,24(sp)
    80001c9c:	e822                	sd	s0,16(sp)
    80001c9e:	e426                	sd	s1,8(sp)
    80001ca0:	e04a                	sd	s2,0(sp)
    80001ca2:	1000                	addi	s0,sp,32
  acquire(&pid_lock);
    80001ca4:	0088f917          	auipc	s2,0x88f
    80001ca8:	5fc90913          	addi	s2,s2,1532 # 808912a0 <pid_lock>
    80001cac:	854a                	mv	a0,s2
    80001cae:	fffff097          	auipc	ra,0xfffff
    80001cb2:	1a0080e7          	jalr	416(ra) # 80000e4e <acquire>
  pid = nextpid;
    80001cb6:	00007797          	auipc	a5,0x7
    80001cba:	c5e78793          	addi	a5,a5,-930 # 80008914 <nextpid>
    80001cbe:	4384                	lw	s1,0(a5)
  nextpid = nextpid + 1;
    80001cc0:	0014871b          	addiw	a4,s1,1
    80001cc4:	c398                	sw	a4,0(a5)
  release(&pid_lock);
    80001cc6:	854a                	mv	a0,s2
    80001cc8:	fffff097          	auipc	ra,0xfffff
    80001ccc:	23a080e7          	jalr	570(ra) # 80000f02 <release>
}
    80001cd0:	8526                	mv	a0,s1
    80001cd2:	60e2                	ld	ra,24(sp)
    80001cd4:	6442                	ld	s0,16(sp)
    80001cd6:	64a2                	ld	s1,8(sp)
    80001cd8:	6902                	ld	s2,0(sp)
    80001cda:	6105                	addi	sp,sp,32
    80001cdc:	8082                	ret

0000000080001cde <proc_pagetable>:
{
    80001cde:	1101                	addi	sp,sp,-32
    80001ce0:	ec06                	sd	ra,24(sp)
    80001ce2:	e822                	sd	s0,16(sp)
    80001ce4:	e426                	sd	s1,8(sp)
    80001ce6:	e04a                	sd	s2,0(sp)
    80001ce8:	1000                	addi	s0,sp,32
    80001cea:	892a                	mv	s2,a0
  pagetable = uvmcreate();
    80001cec:	00000097          	auipc	ra,0x0
    80001cf0:	8b8080e7          	jalr	-1864(ra) # 800015a4 <uvmcreate>
    80001cf4:	84aa                	mv	s1,a0
  if(pagetable == 0)
    80001cf6:	c121                	beqz	a0,80001d36 <proc_pagetable+0x58>
  if(mappages(pagetable, TRAMPOLINE, PGSIZE,
    80001cf8:	4729                	li	a4,10
    80001cfa:	00005697          	auipc	a3,0x5
    80001cfe:	30668693          	addi	a3,a3,774 # 80007000 <_trampoline>
    80001d02:	6605                	lui	a2,0x1
    80001d04:	040005b7          	lui	a1,0x4000
    80001d08:	15fd                	addi	a1,a1,-1
    80001d0a:	05b2                	slli	a1,a1,0xc
    80001d0c:	fffff097          	auipc	ra,0xfffff
    80001d10:	60e080e7          	jalr	1550(ra) # 8000131a <mappages>
    80001d14:	02054863          	bltz	a0,80001d44 <proc_pagetable+0x66>
  if(mappages(pagetable, TRAPFRAME, PGSIZE,
    80001d18:	4719                	li	a4,6
    80001d1a:	05893683          	ld	a3,88(s2)
    80001d1e:	6605                	lui	a2,0x1
    80001d20:	020005b7          	lui	a1,0x2000
    80001d24:	15fd                	addi	a1,a1,-1
    80001d26:	05b6                	slli	a1,a1,0xd
    80001d28:	8526                	mv	a0,s1
    80001d2a:	fffff097          	auipc	ra,0xfffff
    80001d2e:	5f0080e7          	jalr	1520(ra) # 8000131a <mappages>
    80001d32:	02054163          	bltz	a0,80001d54 <proc_pagetable+0x76>
}
    80001d36:	8526                	mv	a0,s1
    80001d38:	60e2                	ld	ra,24(sp)
    80001d3a:	6442                	ld	s0,16(sp)
    80001d3c:	64a2                	ld	s1,8(sp)
    80001d3e:	6902                	ld	s2,0(sp)
    80001d40:	6105                	addi	sp,sp,32
    80001d42:	8082                	ret
    uvmfree(pagetable, 0);
    80001d44:	4581                	li	a1,0
    80001d46:	8526                	mv	a0,s1
    80001d48:	00000097          	auipc	ra,0x0
    80001d4c:	a58080e7          	jalr	-1448(ra) # 800017a0 <uvmfree>
    return 0;
    80001d50:	4481                	li	s1,0
    80001d52:	b7d5                	j	80001d36 <proc_pagetable+0x58>
    uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d54:	4681                	li	a3,0
    80001d56:	4605                	li	a2,1
    80001d58:	040005b7          	lui	a1,0x4000
    80001d5c:	15fd                	addi	a1,a1,-1
    80001d5e:	05b2                	slli	a1,a1,0xc
    80001d60:	8526                	mv	a0,s1
    80001d62:	fffff097          	auipc	ra,0xfffff
    80001d66:	77e080e7          	jalr	1918(ra) # 800014e0 <uvmunmap>
    uvmfree(pagetable, 0);
    80001d6a:	4581                	li	a1,0
    80001d6c:	8526                	mv	a0,s1
    80001d6e:	00000097          	auipc	ra,0x0
    80001d72:	a32080e7          	jalr	-1486(ra) # 800017a0 <uvmfree>
    return 0;
    80001d76:	4481                	li	s1,0
    80001d78:	bf7d                	j	80001d36 <proc_pagetable+0x58>

0000000080001d7a <proc_freepagetable>:
{
    80001d7a:	1101                	addi	sp,sp,-32
    80001d7c:	ec06                	sd	ra,24(sp)
    80001d7e:	e822                	sd	s0,16(sp)
    80001d80:	e426                	sd	s1,8(sp)
    80001d82:	e04a                	sd	s2,0(sp)
    80001d84:	1000                	addi	s0,sp,32
    80001d86:	84aa                	mv	s1,a0
    80001d88:	892e                	mv	s2,a1
  uvmunmap(pagetable, TRAMPOLINE, 1, 0);
    80001d8a:	4681                	li	a3,0
    80001d8c:	4605                	li	a2,1
    80001d8e:	040005b7          	lui	a1,0x4000
    80001d92:	15fd                	addi	a1,a1,-1
    80001d94:	05b2                	slli	a1,a1,0xc
    80001d96:	fffff097          	auipc	ra,0xfffff
    80001d9a:	74a080e7          	jalr	1866(ra) # 800014e0 <uvmunmap>
  uvmunmap(pagetable, TRAPFRAME, 1, 0);
    80001d9e:	4681                	li	a3,0
    80001da0:	4605                	li	a2,1
    80001da2:	020005b7          	lui	a1,0x2000
    80001da6:	15fd                	addi	a1,a1,-1
    80001da8:	05b6                	slli	a1,a1,0xd
    80001daa:	8526                	mv	a0,s1
    80001dac:	fffff097          	auipc	ra,0xfffff
    80001db0:	734080e7          	jalr	1844(ra) # 800014e0 <uvmunmap>
  uvmfree(pagetable, sz);
    80001db4:	85ca                	mv	a1,s2
    80001db6:	8526                	mv	a0,s1
    80001db8:	00000097          	auipc	ra,0x0
    80001dbc:	9e8080e7          	jalr	-1560(ra) # 800017a0 <uvmfree>
}
    80001dc0:	60e2                	ld	ra,24(sp)
    80001dc2:	6442                	ld	s0,16(sp)
    80001dc4:	64a2                	ld	s1,8(sp)
    80001dc6:	6902                	ld	s2,0(sp)
    80001dc8:	6105                	addi	sp,sp,32
    80001dca:	8082                	ret

0000000080001dcc <freeproc>:
{
    80001dcc:	1101                	addi	sp,sp,-32
    80001dce:	ec06                	sd	ra,24(sp)
    80001dd0:	e822                	sd	s0,16(sp)
    80001dd2:	e426                	sd	s1,8(sp)
    80001dd4:	1000                	addi	s0,sp,32
    80001dd6:	84aa                	mv	s1,a0
  if(p->trapframe)
    80001dd8:	6d28                	ld	a0,88(a0)
    80001dda:	c509                	beqz	a0,80001de4 <freeproc+0x18>
    kfree((void*)p->trapframe);
    80001ddc:	fffff097          	auipc	ra,0xfffff
    80001de0:	d1c080e7          	jalr	-740(ra) # 80000af8 <kfree>
  p->trapframe = 0;
    80001de4:	0404bc23          	sd	zero,88(s1)
  if(p->pagetable)
    80001de8:	68a8                	ld	a0,80(s1)
    80001dea:	c511                	beqz	a0,80001df6 <freeproc+0x2a>
    proc_freepagetable(p->pagetable, p->sz);
    80001dec:	64ac                	ld	a1,72(s1)
    80001dee:	00000097          	auipc	ra,0x0
    80001df2:	f8c080e7          	jalr	-116(ra) # 80001d7a <proc_freepagetable>
  p->pagetable = 0;
    80001df6:	0404b823          	sd	zero,80(s1)
  p->sz = 0;
    80001dfa:	0404b423          	sd	zero,72(s1)
  p->pid = 0;
    80001dfe:	0204a823          	sw	zero,48(s1)
  p->parent = 0;
    80001e02:	0204bc23          	sd	zero,56(s1)
  p->name[0] = 0;
    80001e06:	14048c23          	sb	zero,344(s1)
  p->chan = 0;
    80001e0a:	0204b023          	sd	zero,32(s1)
  p->killed = 0;
    80001e0e:	0204a423          	sw	zero,40(s1)
  p->xstate = 0;
    80001e12:	0204a623          	sw	zero,44(s1)
  p->state = UNUSED;
    80001e16:	0004ac23          	sw	zero,24(s1)
}
    80001e1a:	60e2                	ld	ra,24(sp)
    80001e1c:	6442                	ld	s0,16(sp)
    80001e1e:	64a2                	ld	s1,8(sp)
    80001e20:	6105                	addi	sp,sp,32
    80001e22:	8082                	ret

0000000080001e24 <allocproc>:
{
    80001e24:	1101                	addi	sp,sp,-32
    80001e26:	ec06                	sd	ra,24(sp)
    80001e28:	e822                	sd	s0,16(sp)
    80001e2a:	e426                	sd	s1,8(sp)
    80001e2c:	e04a                	sd	s2,0(sp)
    80001e2e:	1000                	addi	s0,sp,32
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e30:	00890497          	auipc	s1,0x890
    80001e34:	8a048493          	addi	s1,s1,-1888 # 808916d0 <proc>
    80001e38:	00895917          	auipc	s2,0x895
    80001e3c:	69890913          	addi	s2,s2,1688 # 808974d0 <tickslock>
    acquire(&p->lock);
    80001e40:	8526                	mv	a0,s1
    80001e42:	fffff097          	auipc	ra,0xfffff
    80001e46:	00c080e7          	jalr	12(ra) # 80000e4e <acquire>
    if(p->state == UNUSED) {
    80001e4a:	4c9c                	lw	a5,24(s1)
    80001e4c:	cf81                	beqz	a5,80001e64 <allocproc+0x40>
      release(&p->lock);
    80001e4e:	8526                	mv	a0,s1
    80001e50:	fffff097          	auipc	ra,0xfffff
    80001e54:	0b2080e7          	jalr	178(ra) # 80000f02 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    80001e58:	17848493          	addi	s1,s1,376
    80001e5c:	ff2492e3          	bne	s1,s2,80001e40 <allocproc+0x1c>
  return 0;
    80001e60:	4481                	li	s1,0
    80001e62:	a889                	j	80001eb4 <allocproc+0x90>
  p->pid = allocpid();
    80001e64:	00000097          	auipc	ra,0x0
    80001e68:	e34080e7          	jalr	-460(ra) # 80001c98 <allocpid>
    80001e6c:	d888                	sw	a0,48(s1)
  p->state = USED;
    80001e6e:	4785                	li	a5,1
    80001e70:	cc9c                	sw	a5,24(s1)
  if((p->trapframe = (struct trapframe *)kalloc()) == 0){
    80001e72:	fffff097          	auipc	ra,0xfffff
    80001e76:	d9e080e7          	jalr	-610(ra) # 80000c10 <kalloc>
    80001e7a:	892a                	mv	s2,a0
    80001e7c:	eca8                	sd	a0,88(s1)
    80001e7e:	c131                	beqz	a0,80001ec2 <allocproc+0x9e>
  p->pagetable = proc_pagetable(p);
    80001e80:	8526                	mv	a0,s1
    80001e82:	00000097          	auipc	ra,0x0
    80001e86:	e5c080e7          	jalr	-420(ra) # 80001cde <proc_pagetable>
    80001e8a:	892a                	mv	s2,a0
    80001e8c:	e8a8                	sd	a0,80(s1)
  if(p->pagetable == 0){
    80001e8e:	c531                	beqz	a0,80001eda <allocproc+0xb6>
  memset(&p->context, 0, sizeof(p->context));
    80001e90:	07000613          	li	a2,112
    80001e94:	4581                	li	a1,0
    80001e96:	06048513          	addi	a0,s1,96
    80001e9a:	fffff097          	auipc	ra,0xfffff
    80001e9e:	0b0080e7          	jalr	176(ra) # 80000f4a <memset>
  p->context.ra = (uint64)forkret;
    80001ea2:	00000797          	auipc	a5,0x0
    80001ea6:	db078793          	addi	a5,a5,-592 # 80001c52 <forkret>
    80001eaa:	f0bc                	sd	a5,96(s1)
  p->context.sp = p->kstack + PGSIZE;
    80001eac:	60bc                	ld	a5,64(s1)
    80001eae:	6705                	lui	a4,0x1
    80001eb0:	97ba                	add	a5,a5,a4
    80001eb2:	f4bc                	sd	a5,104(s1)
}
    80001eb4:	8526                	mv	a0,s1
    80001eb6:	60e2                	ld	ra,24(sp)
    80001eb8:	6442                	ld	s0,16(sp)
    80001eba:	64a2                	ld	s1,8(sp)
    80001ebc:	6902                	ld	s2,0(sp)
    80001ebe:	6105                	addi	sp,sp,32
    80001ec0:	8082                	ret
    freeproc(p);
    80001ec2:	8526                	mv	a0,s1
    80001ec4:	00000097          	auipc	ra,0x0
    80001ec8:	f08080e7          	jalr	-248(ra) # 80001dcc <freeproc>
    release(&p->lock);
    80001ecc:	8526                	mv	a0,s1
    80001ece:	fffff097          	auipc	ra,0xfffff
    80001ed2:	034080e7          	jalr	52(ra) # 80000f02 <release>
    return 0;
    80001ed6:	84ca                	mv	s1,s2
    80001ed8:	bff1                	j	80001eb4 <allocproc+0x90>
    freeproc(p);
    80001eda:	8526                	mv	a0,s1
    80001edc:	00000097          	auipc	ra,0x0
    80001ee0:	ef0080e7          	jalr	-272(ra) # 80001dcc <freeproc>
    release(&p->lock);
    80001ee4:	8526                	mv	a0,s1
    80001ee6:	fffff097          	auipc	ra,0xfffff
    80001eea:	01c080e7          	jalr	28(ra) # 80000f02 <release>
    return 0;
    80001eee:	84ca                	mv	s1,s2
    80001ef0:	b7d1                	j	80001eb4 <allocproc+0x90>

0000000080001ef2 <userinit>:
{
    80001ef2:	1101                	addi	sp,sp,-32
    80001ef4:	ec06                	sd	ra,24(sp)
    80001ef6:	e822                	sd	s0,16(sp)
    80001ef8:	e426                	sd	s1,8(sp)
    80001efa:	1000                	addi	s0,sp,32
  p = allocproc();
    80001efc:	00000097          	auipc	ra,0x0
    80001f00:	f28080e7          	jalr	-216(ra) # 80001e24 <allocproc>
    80001f04:	84aa                	mv	s1,a0
  initproc = p;
    80001f06:	00007797          	auipc	a5,0x7
    80001f0a:	12a7b123          	sd	a0,290(a5) # 80009028 <initproc>
  uvminit(p->pagetable, initcode, sizeof(initcode));
    80001f0e:	03400613          	li	a2,52
    80001f12:	00007597          	auipc	a1,0x7
    80001f16:	a0e58593          	addi	a1,a1,-1522 # 80008920 <initcode>
    80001f1a:	6928                	ld	a0,80(a0)
    80001f1c:	fffff097          	auipc	ra,0xfffff
    80001f20:	6b6080e7          	jalr	1718(ra) # 800015d2 <uvminit>
  p->sz = PGSIZE;
    80001f24:	6785                	lui	a5,0x1
    80001f26:	e4bc                	sd	a5,72(s1)
  p->trapframe->epc = 0;      // user program counter
    80001f28:	6cb8                	ld	a4,88(s1)
    80001f2a:	00073c23          	sd	zero,24(a4) # 1018 <_entry-0x7fffefe8>
  p->trapframe->sp = PGSIZE;  // user stack pointer
    80001f2e:	6cb8                	ld	a4,88(s1)
    80001f30:	fb1c                	sd	a5,48(a4)
  safestrcpy(p->name, "initcode", sizeof(p->name));
    80001f32:	4641                	li	a2,16
    80001f34:	00006597          	auipc	a1,0x6
    80001f38:	33c58593          	addi	a1,a1,828 # 80008270 <digits+0x230>
    80001f3c:	15848513          	addi	a0,s1,344
    80001f40:	fffff097          	auipc	ra,0xfffff
    80001f44:	15c080e7          	jalr	348(ra) # 8000109c <safestrcpy>
  p->cwd = namei("/");
    80001f48:	00006517          	auipc	a0,0x6
    80001f4c:	33850513          	addi	a0,a0,824 # 80008280 <digits+0x240>
    80001f50:	00002097          	auipc	ra,0x2
    80001f54:	20c080e7          	jalr	524(ra) # 8000415c <namei>
    80001f58:	14a4b823          	sd	a0,336(s1)
  p->vmas = 0;  //Set vma chain to 0
    80001f5c:	1604b423          	sd	zero,360(s1)
  p->state = RUNNABLE;
    80001f60:	478d                	li	a5,3
    80001f62:	cc9c                	sw	a5,24(s1)
  release(&p->lock);
    80001f64:	8526                	mv	a0,s1
    80001f66:	fffff097          	auipc	ra,0xfffff
    80001f6a:	f9c080e7          	jalr	-100(ra) # 80000f02 <release>
}
    80001f6e:	60e2                	ld	ra,24(sp)
    80001f70:	6442                	ld	s0,16(sp)
    80001f72:	64a2                	ld	s1,8(sp)
    80001f74:	6105                	addi	sp,sp,32
    80001f76:	8082                	ret

0000000080001f78 <growproc>:
{
    80001f78:	1101                	addi	sp,sp,-32
    80001f7a:	ec06                	sd	ra,24(sp)
    80001f7c:	e822                	sd	s0,16(sp)
    80001f7e:	e426                	sd	s1,8(sp)
    80001f80:	e04a                	sd	s2,0(sp)
    80001f82:	1000                	addi	s0,sp,32
    80001f84:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80001f86:	00000097          	auipc	ra,0x0
    80001f8a:	c94080e7          	jalr	-876(ra) # 80001c1a <myproc>
    80001f8e:	892a                	mv	s2,a0
  sz = p->sz;
    80001f90:	652c                	ld	a1,72(a0)
    80001f92:	0005861b          	sext.w	a2,a1
  if(n > 0){
    80001f96:	00904f63          	bgtz	s1,80001fb4 <growproc+0x3c>
  } else if(n < 0){
    80001f9a:	0204cc63          	bltz	s1,80001fd2 <growproc+0x5a>
  p->sz = sz;
    80001f9e:	1602                	slli	a2,a2,0x20
    80001fa0:	9201                	srli	a2,a2,0x20
    80001fa2:	04c93423          	sd	a2,72(s2)
  return 0;
    80001fa6:	4501                	li	a0,0
}
    80001fa8:	60e2                	ld	ra,24(sp)
    80001faa:	6442                	ld	s0,16(sp)
    80001fac:	64a2                	ld	s1,8(sp)
    80001fae:	6902                	ld	s2,0(sp)
    80001fb0:	6105                	addi	sp,sp,32
    80001fb2:	8082                	ret
    if((sz = uvmalloc(p->pagetable, sz, sz + n)) == 0) {
    80001fb4:	9e25                	addw	a2,a2,s1
    80001fb6:	1602                	slli	a2,a2,0x20
    80001fb8:	9201                	srli	a2,a2,0x20
    80001fba:	1582                	slli	a1,a1,0x20
    80001fbc:	9181                	srli	a1,a1,0x20
    80001fbe:	6928                	ld	a0,80(a0)
    80001fc0:	fffff097          	auipc	ra,0xfffff
    80001fc4:	6cc080e7          	jalr	1740(ra) # 8000168c <uvmalloc>
    80001fc8:	0005061b          	sext.w	a2,a0
    80001fcc:	fa69                	bnez	a2,80001f9e <growproc+0x26>
      return -1;
    80001fce:	557d                	li	a0,-1
    80001fd0:	bfe1                	j	80001fa8 <growproc+0x30>
    sz = uvmdealloc(p->pagetable, sz, sz + n);
    80001fd2:	9e25                	addw	a2,a2,s1
    80001fd4:	1602                	slli	a2,a2,0x20
    80001fd6:	9201                	srli	a2,a2,0x20
    80001fd8:	1582                	slli	a1,a1,0x20
    80001fda:	9181                	srli	a1,a1,0x20
    80001fdc:	6928                	ld	a0,80(a0)
    80001fde:	fffff097          	auipc	ra,0xfffff
    80001fe2:	666080e7          	jalr	1638(ra) # 80001644 <uvmdealloc>
    80001fe6:	0005061b          	sext.w	a2,a0
    80001fea:	bf55                	j	80001f9e <growproc+0x26>

0000000080001fec <fork>:
{
    80001fec:	7179                	addi	sp,sp,-48
    80001fee:	f406                	sd	ra,40(sp)
    80001ff0:	f022                	sd	s0,32(sp)
    80001ff2:	ec26                	sd	s1,24(sp)
    80001ff4:	e84a                	sd	s2,16(sp)
    80001ff6:	e44e                	sd	s3,8(sp)
    80001ff8:	e052                	sd	s4,0(sp)
    80001ffa:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    80001ffc:	00000097          	auipc	ra,0x0
    80002000:	c1e080e7          	jalr	-994(ra) # 80001c1a <myproc>
    80002004:	892a                	mv	s2,a0
  if((np = allocproc()) == 0){
    80002006:	00000097          	auipc	ra,0x0
    8000200a:	e1e080e7          	jalr	-482(ra) # 80001e24 <allocproc>
    8000200e:	10050f63          	beqz	a0,8000212c <fork+0x140>
    80002012:	89aa                	mv	s3,a0
  if(uvmcopy(p->pagetable, np->pagetable, p->sz) < 0){
    80002014:	04893603          	ld	a2,72(s2)
    80002018:	692c                	ld	a1,80(a0)
    8000201a:	05093503          	ld	a0,80(s2)
    8000201e:	fffff097          	auipc	ra,0xfffff
    80002022:	7ba080e7          	jalr	1978(ra) # 800017d8 <uvmcopy>
    80002026:	04054663          	bltz	a0,80002072 <fork+0x86>
  np->sz = p->sz;
    8000202a:	04893783          	ld	a5,72(s2)
    8000202e:	04f9b423          	sd	a5,72(s3)
  *(np->trapframe) = *(p->trapframe);
    80002032:	05893683          	ld	a3,88(s2)
    80002036:	87b6                	mv	a5,a3
    80002038:	0589b703          	ld	a4,88(s3)
    8000203c:	12068693          	addi	a3,a3,288
    80002040:	0007b803          	ld	a6,0(a5) # 1000 <_entry-0x7ffff000>
    80002044:	6788                	ld	a0,8(a5)
    80002046:	6b8c                	ld	a1,16(a5)
    80002048:	6f90                	ld	a2,24(a5)
    8000204a:	01073023          	sd	a6,0(a4)
    8000204e:	e708                	sd	a0,8(a4)
    80002050:	eb0c                	sd	a1,16(a4)
    80002052:	ef10                	sd	a2,24(a4)
    80002054:	02078793          	addi	a5,a5,32
    80002058:	02070713          	addi	a4,a4,32
    8000205c:	fed792e3          	bne	a5,a3,80002040 <fork+0x54>
  np->trapframe->a0 = 0;
    80002060:	0589b783          	ld	a5,88(s3)
    80002064:	0607b823          	sd	zero,112(a5)
    80002068:	0d000493          	li	s1,208
  for(i = 0; i < NOFILE; i++)
    8000206c:	15000a13          	li	s4,336
    80002070:	a03d                	j	8000209e <fork+0xb2>
    freeproc(np);
    80002072:	854e                	mv	a0,s3
    80002074:	00000097          	auipc	ra,0x0
    80002078:	d58080e7          	jalr	-680(ra) # 80001dcc <freeproc>
    release(&np->lock);
    8000207c:	854e                	mv	a0,s3
    8000207e:	fffff097          	auipc	ra,0xfffff
    80002082:	e84080e7          	jalr	-380(ra) # 80000f02 <release>
    return -1;
    80002086:	5a7d                	li	s4,-1
    80002088:	a849                	j	8000211a <fork+0x12e>
      np->ofile[i] = filedup(p->ofile[i]);
    8000208a:	00002097          	auipc	ra,0x2
    8000208e:	768080e7          	jalr	1896(ra) # 800047f2 <filedup>
    80002092:	009987b3          	add	a5,s3,s1
    80002096:	e388                	sd	a0,0(a5)
  for(i = 0; i < NOFILE; i++)
    80002098:	04a1                	addi	s1,s1,8
    8000209a:	01448763          	beq	s1,s4,800020a8 <fork+0xbc>
    if(p->ofile[i])
    8000209e:	009907b3          	add	a5,s2,s1
    800020a2:	6388                	ld	a0,0(a5)
    800020a4:	f17d                	bnez	a0,8000208a <fork+0x9e>
    800020a6:	bfcd                	j	80002098 <fork+0xac>
  np->cwd = idup(p->cwd);
    800020a8:	15093503          	ld	a0,336(s2)
    800020ac:	00002097          	auipc	ra,0x2
    800020b0:	8bc080e7          	jalr	-1860(ra) # 80003968 <idup>
    800020b4:	14a9b823          	sd	a0,336(s3)
  safestrcpy(np->name, p->name, sizeof(p->name));
    800020b8:	4641                	li	a2,16
    800020ba:	15890593          	addi	a1,s2,344
    800020be:	15898513          	addi	a0,s3,344
    800020c2:	fffff097          	auipc	ra,0xfffff
    800020c6:	fda080e7          	jalr	-38(ra) # 8000109c <safestrcpy>
  pid = np->pid;
    800020ca:	0309aa03          	lw	s4,48(s3)
  np->vmas = p->vmas;             
    800020ce:	16893783          	ld	a5,360(s2)
    800020d2:	16f9b423          	sd	a5,360(s3)
  release(&np->lock);
    800020d6:	854e                	mv	a0,s3
    800020d8:	fffff097          	auipc	ra,0xfffff
    800020dc:	e2a080e7          	jalr	-470(ra) # 80000f02 <release>
  acquire(&wait_lock);
    800020e0:	0088f497          	auipc	s1,0x88f
    800020e4:	1d848493          	addi	s1,s1,472 # 808912b8 <wait_lock>
    800020e8:	8526                	mv	a0,s1
    800020ea:	fffff097          	auipc	ra,0xfffff
    800020ee:	d64080e7          	jalr	-668(ra) # 80000e4e <acquire>
  np->parent = p;
    800020f2:	0329bc23          	sd	s2,56(s3)
  release(&wait_lock);
    800020f6:	8526                	mv	a0,s1
    800020f8:	fffff097          	auipc	ra,0xfffff
    800020fc:	e0a080e7          	jalr	-502(ra) # 80000f02 <release>
  acquire(&np->lock);
    80002100:	854e                	mv	a0,s3
    80002102:	fffff097          	auipc	ra,0xfffff
    80002106:	d4c080e7          	jalr	-692(ra) # 80000e4e <acquire>
  np->state = RUNNABLE;
    8000210a:	478d                	li	a5,3
    8000210c:	00f9ac23          	sw	a5,24(s3)
  release(&np->lock);
    80002110:	854e                	mv	a0,s3
    80002112:	fffff097          	auipc	ra,0xfffff
    80002116:	df0080e7          	jalr	-528(ra) # 80000f02 <release>
}
    8000211a:	8552                	mv	a0,s4
    8000211c:	70a2                	ld	ra,40(sp)
    8000211e:	7402                	ld	s0,32(sp)
    80002120:	64e2                	ld	s1,24(sp)
    80002122:	6942                	ld	s2,16(sp)
    80002124:	69a2                	ld	s3,8(sp)
    80002126:	6a02                	ld	s4,0(sp)
    80002128:	6145                	addi	sp,sp,48
    8000212a:	8082                	ret
    return -1;
    8000212c:	5a7d                	li	s4,-1
    8000212e:	b7f5                	j	8000211a <fork+0x12e>

0000000080002130 <scheduler>:
{
    80002130:	7139                	addi	sp,sp,-64
    80002132:	fc06                	sd	ra,56(sp)
    80002134:	f822                	sd	s0,48(sp)
    80002136:	f426                	sd	s1,40(sp)
    80002138:	f04a                	sd	s2,32(sp)
    8000213a:	ec4e                	sd	s3,24(sp)
    8000213c:	e852                	sd	s4,16(sp)
    8000213e:	e456                	sd	s5,8(sp)
    80002140:	e05a                	sd	s6,0(sp)
    80002142:	0080                	addi	s0,sp,64
    80002144:	8792                	mv	a5,tp
  int id = r_tp();
    80002146:	2781                	sext.w	a5,a5
  c->proc = 0;
    80002148:	00779a93          	slli	s5,a5,0x7
    8000214c:	0088f717          	auipc	a4,0x88f
    80002150:	15470713          	addi	a4,a4,340 # 808912a0 <pid_lock>
    80002154:	9756                	add	a4,a4,s5
    80002156:	02073823          	sd	zero,48(a4)
        swtch(&c->context, &p->context);
    8000215a:	0088f717          	auipc	a4,0x88f
    8000215e:	17e70713          	addi	a4,a4,382 # 808912d8 <cpus+0x8>
    80002162:	9aba                	add	s5,s5,a4
      if(p->state == RUNNABLE) {
    80002164:	498d                	li	s3,3
        p->state = RUNNING;
    80002166:	4b11                	li	s6,4
        c->proc = p;
    80002168:	079e                	slli	a5,a5,0x7
    8000216a:	0088fa17          	auipc	s4,0x88f
    8000216e:	136a0a13          	addi	s4,s4,310 # 808912a0 <pid_lock>
    80002172:	9a3e                	add	s4,s4,a5
    for(p = proc; p < &proc[NPROC]; p++) {
    80002174:	00895917          	auipc	s2,0x895
    80002178:	35c90913          	addi	s2,s2,860 # 808974d0 <tickslock>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000217c:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002180:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002184:	10079073          	csrw	sstatus,a5
    80002188:	0088f497          	auipc	s1,0x88f
    8000218c:	54848493          	addi	s1,s1,1352 # 808916d0 <proc>
    80002190:	a03d                	j	800021be <scheduler+0x8e>
        p->state = RUNNING;
    80002192:	0164ac23          	sw	s6,24(s1)
        c->proc = p;
    80002196:	029a3823          	sd	s1,48(s4)
        swtch(&c->context, &p->context);
    8000219a:	06048593          	addi	a1,s1,96
    8000219e:	8556                	mv	a0,s5
    800021a0:	00000097          	auipc	ra,0x0
    800021a4:	640080e7          	jalr	1600(ra) # 800027e0 <swtch>
        c->proc = 0;
    800021a8:	020a3823          	sd	zero,48(s4)
      release(&p->lock);
    800021ac:	8526                	mv	a0,s1
    800021ae:	fffff097          	auipc	ra,0xfffff
    800021b2:	d54080e7          	jalr	-684(ra) # 80000f02 <release>
    for(p = proc; p < &proc[NPROC]; p++) {
    800021b6:	17848493          	addi	s1,s1,376
    800021ba:	fd2481e3          	beq	s1,s2,8000217c <scheduler+0x4c>
      acquire(&p->lock);
    800021be:	8526                	mv	a0,s1
    800021c0:	fffff097          	auipc	ra,0xfffff
    800021c4:	c8e080e7          	jalr	-882(ra) # 80000e4e <acquire>
      if(p->state == RUNNABLE) {
    800021c8:	4c9c                	lw	a5,24(s1)
    800021ca:	ff3791e3          	bne	a5,s3,800021ac <scheduler+0x7c>
    800021ce:	b7d1                	j	80002192 <scheduler+0x62>

00000000800021d0 <sched>:
{
    800021d0:	7179                	addi	sp,sp,-48
    800021d2:	f406                	sd	ra,40(sp)
    800021d4:	f022                	sd	s0,32(sp)
    800021d6:	ec26                	sd	s1,24(sp)
    800021d8:	e84a                	sd	s2,16(sp)
    800021da:	e44e                	sd	s3,8(sp)
    800021dc:	1800                	addi	s0,sp,48
  struct proc *p = myproc();
    800021de:	00000097          	auipc	ra,0x0
    800021e2:	a3c080e7          	jalr	-1476(ra) # 80001c1a <myproc>
    800021e6:	84aa                	mv	s1,a0
  if(!holding(&p->lock))
    800021e8:	fffff097          	auipc	ra,0xfffff
    800021ec:	bec080e7          	jalr	-1044(ra) # 80000dd4 <holding>
    800021f0:	c93d                	beqz	a0,80002266 <sched+0x96>
  asm volatile("mv %0, tp" : "=r" (x) );
    800021f2:	8792                	mv	a5,tp
  if(mycpu()->noff != 1)
    800021f4:	2781                	sext.w	a5,a5
    800021f6:	079e                	slli	a5,a5,0x7
    800021f8:	0088f717          	auipc	a4,0x88f
    800021fc:	0a870713          	addi	a4,a4,168 # 808912a0 <pid_lock>
    80002200:	97ba                	add	a5,a5,a4
    80002202:	0a87a703          	lw	a4,168(a5)
    80002206:	4785                	li	a5,1
    80002208:	06f71763          	bne	a4,a5,80002276 <sched+0xa6>
  if(p->state == RUNNING)
    8000220c:	4c98                	lw	a4,24(s1)
    8000220e:	4791                	li	a5,4
    80002210:	06f70b63          	beq	a4,a5,80002286 <sched+0xb6>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002214:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002218:	8b89                	andi	a5,a5,2
  if(intr_get())
    8000221a:	efb5                	bnez	a5,80002296 <sched+0xc6>
  asm volatile("mv %0, tp" : "=r" (x) );
    8000221c:	8792                	mv	a5,tp
  intena = mycpu()->intena;
    8000221e:	0088f917          	auipc	s2,0x88f
    80002222:	08290913          	addi	s2,s2,130 # 808912a0 <pid_lock>
    80002226:	2781                	sext.w	a5,a5
    80002228:	079e                	slli	a5,a5,0x7
    8000222a:	97ca                	add	a5,a5,s2
    8000222c:	0ac7a983          	lw	s3,172(a5)
    80002230:	8792                	mv	a5,tp
  swtch(&p->context, &mycpu()->context);
    80002232:	2781                	sext.w	a5,a5
    80002234:	079e                	slli	a5,a5,0x7
    80002236:	0088f597          	auipc	a1,0x88f
    8000223a:	0a258593          	addi	a1,a1,162 # 808912d8 <cpus+0x8>
    8000223e:	95be                	add	a1,a1,a5
    80002240:	06048513          	addi	a0,s1,96
    80002244:	00000097          	auipc	ra,0x0
    80002248:	59c080e7          	jalr	1436(ra) # 800027e0 <swtch>
    8000224c:	8792                	mv	a5,tp
  mycpu()->intena = intena;
    8000224e:	2781                	sext.w	a5,a5
    80002250:	079e                	slli	a5,a5,0x7
    80002252:	97ca                	add	a5,a5,s2
    80002254:	0b37a623          	sw	s3,172(a5)
}
    80002258:	70a2                	ld	ra,40(sp)
    8000225a:	7402                	ld	s0,32(sp)
    8000225c:	64e2                	ld	s1,24(sp)
    8000225e:	6942                	ld	s2,16(sp)
    80002260:	69a2                	ld	s3,8(sp)
    80002262:	6145                	addi	sp,sp,48
    80002264:	8082                	ret
    panic("sched p->lock");
    80002266:	00006517          	auipc	a0,0x6
    8000226a:	02250513          	addi	a0,a0,34 # 80008288 <digits+0x248>
    8000226e:	ffffe097          	auipc	ra,0xffffe
    80002272:	2d0080e7          	jalr	720(ra) # 8000053e <panic>
    panic("sched locks");
    80002276:	00006517          	auipc	a0,0x6
    8000227a:	02250513          	addi	a0,a0,34 # 80008298 <digits+0x258>
    8000227e:	ffffe097          	auipc	ra,0xffffe
    80002282:	2c0080e7          	jalr	704(ra) # 8000053e <panic>
    panic("sched running");
    80002286:	00006517          	auipc	a0,0x6
    8000228a:	02250513          	addi	a0,a0,34 # 800082a8 <digits+0x268>
    8000228e:	ffffe097          	auipc	ra,0xffffe
    80002292:	2b0080e7          	jalr	688(ra) # 8000053e <panic>
    panic("sched interruptible");
    80002296:	00006517          	auipc	a0,0x6
    8000229a:	02250513          	addi	a0,a0,34 # 800082b8 <digits+0x278>
    8000229e:	ffffe097          	auipc	ra,0xffffe
    800022a2:	2a0080e7          	jalr	672(ra) # 8000053e <panic>

00000000800022a6 <yield>:
{
    800022a6:	1101                	addi	sp,sp,-32
    800022a8:	ec06                	sd	ra,24(sp)
    800022aa:	e822                	sd	s0,16(sp)
    800022ac:	e426                	sd	s1,8(sp)
    800022ae:	1000                	addi	s0,sp,32
  struct proc *p = myproc();
    800022b0:	00000097          	auipc	ra,0x0
    800022b4:	96a080e7          	jalr	-1686(ra) # 80001c1a <myproc>
    800022b8:	84aa                	mv	s1,a0
  acquire(&p->lock);
    800022ba:	fffff097          	auipc	ra,0xfffff
    800022be:	b94080e7          	jalr	-1132(ra) # 80000e4e <acquire>
  p->state = RUNNABLE;
    800022c2:	478d                	li	a5,3
    800022c4:	cc9c                	sw	a5,24(s1)
  sched();
    800022c6:	00000097          	auipc	ra,0x0
    800022ca:	f0a080e7          	jalr	-246(ra) # 800021d0 <sched>
  release(&p->lock);
    800022ce:	8526                	mv	a0,s1
    800022d0:	fffff097          	auipc	ra,0xfffff
    800022d4:	c32080e7          	jalr	-974(ra) # 80000f02 <release>
}
    800022d8:	60e2                	ld	ra,24(sp)
    800022da:	6442                	ld	s0,16(sp)
    800022dc:	64a2                	ld	s1,8(sp)
    800022de:	6105                	addi	sp,sp,32
    800022e0:	8082                	ret

00000000800022e2 <sleep>:

// Atomically release lock and sleep on chan.
// Reacquires lock when awakened.
void
sleep(void *chan, struct spinlock *lk)
{
    800022e2:	7179                	addi	sp,sp,-48
    800022e4:	f406                	sd	ra,40(sp)
    800022e6:	f022                	sd	s0,32(sp)
    800022e8:	ec26                	sd	s1,24(sp)
    800022ea:	e84a                	sd	s2,16(sp)
    800022ec:	e44e                	sd	s3,8(sp)
    800022ee:	1800                	addi	s0,sp,48
    800022f0:	89aa                	mv	s3,a0
    800022f2:	892e                	mv	s2,a1
  struct proc *p = myproc();
    800022f4:	00000097          	auipc	ra,0x0
    800022f8:	926080e7          	jalr	-1754(ra) # 80001c1a <myproc>
    800022fc:	84aa                	mv	s1,a0
  // Once we hold p->lock, we can be
  // guaranteed that we won't miss any wakeup
  // (wakeup locks p->lock),
  // so it's okay to release lk.

  acquire(&p->lock);  //DOC: sleeplock1
    800022fe:	fffff097          	auipc	ra,0xfffff
    80002302:	b50080e7          	jalr	-1200(ra) # 80000e4e <acquire>
  release(lk);
    80002306:	854a                	mv	a0,s2
    80002308:	fffff097          	auipc	ra,0xfffff
    8000230c:	bfa080e7          	jalr	-1030(ra) # 80000f02 <release>

  // Go to sleep.
  p->chan = chan;
    80002310:	0334b023          	sd	s3,32(s1)
  p->state = SLEEPING;
    80002314:	4789                	li	a5,2
    80002316:	cc9c                	sw	a5,24(s1)

  sched();
    80002318:	00000097          	auipc	ra,0x0
    8000231c:	eb8080e7          	jalr	-328(ra) # 800021d0 <sched>

  // Tidy up.
  p->chan = 0;
    80002320:	0204b023          	sd	zero,32(s1)

  // Reacquire original lock.
  release(&p->lock);
    80002324:	8526                	mv	a0,s1
    80002326:	fffff097          	auipc	ra,0xfffff
    8000232a:	bdc080e7          	jalr	-1060(ra) # 80000f02 <release>
  acquire(lk);
    8000232e:	854a                	mv	a0,s2
    80002330:	fffff097          	auipc	ra,0xfffff
    80002334:	b1e080e7          	jalr	-1250(ra) # 80000e4e <acquire>
}
    80002338:	70a2                	ld	ra,40(sp)
    8000233a:	7402                	ld	s0,32(sp)
    8000233c:	64e2                	ld	s1,24(sp)
    8000233e:	6942                	ld	s2,16(sp)
    80002340:	69a2                	ld	s3,8(sp)
    80002342:	6145                	addi	sp,sp,48
    80002344:	8082                	ret

0000000080002346 <wait>:
{
    80002346:	715d                	addi	sp,sp,-80
    80002348:	e486                	sd	ra,72(sp)
    8000234a:	e0a2                	sd	s0,64(sp)
    8000234c:	fc26                	sd	s1,56(sp)
    8000234e:	f84a                	sd	s2,48(sp)
    80002350:	f44e                	sd	s3,40(sp)
    80002352:	f052                	sd	s4,32(sp)
    80002354:	ec56                	sd	s5,24(sp)
    80002356:	e85a                	sd	s6,16(sp)
    80002358:	e45e                	sd	s7,8(sp)
    8000235a:	e062                	sd	s8,0(sp)
    8000235c:	0880                	addi	s0,sp,80
    8000235e:	8b2a                	mv	s6,a0
  struct proc *p = myproc();
    80002360:	00000097          	auipc	ra,0x0
    80002364:	8ba080e7          	jalr	-1862(ra) # 80001c1a <myproc>
    80002368:	892a                	mv	s2,a0
  acquire(&wait_lock);
    8000236a:	0088f517          	auipc	a0,0x88f
    8000236e:	f4e50513          	addi	a0,a0,-178 # 808912b8 <wait_lock>
    80002372:	fffff097          	auipc	ra,0xfffff
    80002376:	adc080e7          	jalr	-1316(ra) # 80000e4e <acquire>
    havekids = 0;
    8000237a:	4b81                	li	s7,0
        if(np->state == ZOMBIE){
    8000237c:	4a15                	li	s4,5
    for(np = proc; np < &proc[NPROC]; np++){
    8000237e:	00895997          	auipc	s3,0x895
    80002382:	15298993          	addi	s3,s3,338 # 808974d0 <tickslock>
        havekids = 1;
    80002386:	4a85                	li	s5,1
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002388:	0088fc17          	auipc	s8,0x88f
    8000238c:	f30c0c13          	addi	s8,s8,-208 # 808912b8 <wait_lock>
    havekids = 0;
    80002390:	875e                	mv	a4,s7
    for(np = proc; np < &proc[NPROC]; np++){
    80002392:	0088f497          	auipc	s1,0x88f
    80002396:	33e48493          	addi	s1,s1,830 # 808916d0 <proc>
    8000239a:	a0bd                	j	80002408 <wait+0xc2>
          pid = np->pid;
    8000239c:	0304a983          	lw	s3,48(s1)
          if(addr != 0 && copyout(p->pagetable, addr, (char *)&np->xstate,
    800023a0:	000b0e63          	beqz	s6,800023bc <wait+0x76>
    800023a4:	4691                	li	a3,4
    800023a6:	02c48613          	addi	a2,s1,44
    800023aa:	85da                	mv	a1,s6
    800023ac:	05093503          	ld	a0,80(s2)
    800023b0:	fffff097          	auipc	ra,0xfffff
    800023b4:	52c080e7          	jalr	1324(ra) # 800018dc <copyout>
    800023b8:	02054563          	bltz	a0,800023e2 <wait+0x9c>
          freeproc(np);
    800023bc:	8526                	mv	a0,s1
    800023be:	00000097          	auipc	ra,0x0
    800023c2:	a0e080e7          	jalr	-1522(ra) # 80001dcc <freeproc>
          release(&np->lock);
    800023c6:	8526                	mv	a0,s1
    800023c8:	fffff097          	auipc	ra,0xfffff
    800023cc:	b3a080e7          	jalr	-1222(ra) # 80000f02 <release>
          release(&wait_lock);
    800023d0:	0088f517          	auipc	a0,0x88f
    800023d4:	ee850513          	addi	a0,a0,-280 # 808912b8 <wait_lock>
    800023d8:	fffff097          	auipc	ra,0xfffff
    800023dc:	b2a080e7          	jalr	-1238(ra) # 80000f02 <release>
          return pid;
    800023e0:	a09d                	j	80002446 <wait+0x100>
            release(&np->lock);
    800023e2:	8526                	mv	a0,s1
    800023e4:	fffff097          	auipc	ra,0xfffff
    800023e8:	b1e080e7          	jalr	-1250(ra) # 80000f02 <release>
            release(&wait_lock);
    800023ec:	0088f517          	auipc	a0,0x88f
    800023f0:	ecc50513          	addi	a0,a0,-308 # 808912b8 <wait_lock>
    800023f4:	fffff097          	auipc	ra,0xfffff
    800023f8:	b0e080e7          	jalr	-1266(ra) # 80000f02 <release>
            return -1;
    800023fc:	59fd                	li	s3,-1
    800023fe:	a0a1                	j	80002446 <wait+0x100>
    for(np = proc; np < &proc[NPROC]; np++){
    80002400:	17848493          	addi	s1,s1,376
    80002404:	03348463          	beq	s1,s3,8000242c <wait+0xe6>
      if(np->parent == p){
    80002408:	7c9c                	ld	a5,56(s1)
    8000240a:	ff279be3          	bne	a5,s2,80002400 <wait+0xba>
        acquire(&np->lock);
    8000240e:	8526                	mv	a0,s1
    80002410:	fffff097          	auipc	ra,0xfffff
    80002414:	a3e080e7          	jalr	-1474(ra) # 80000e4e <acquire>
        if(np->state == ZOMBIE){
    80002418:	4c9c                	lw	a5,24(s1)
    8000241a:	f94781e3          	beq	a5,s4,8000239c <wait+0x56>
        release(&np->lock);
    8000241e:	8526                	mv	a0,s1
    80002420:	fffff097          	auipc	ra,0xfffff
    80002424:	ae2080e7          	jalr	-1310(ra) # 80000f02 <release>
        havekids = 1;
    80002428:	8756                	mv	a4,s5
    8000242a:	bfd9                	j	80002400 <wait+0xba>
    if(!havekids || p->killed){
    8000242c:	c701                	beqz	a4,80002434 <wait+0xee>
    8000242e:	02892783          	lw	a5,40(s2)
    80002432:	c79d                	beqz	a5,80002460 <wait+0x11a>
      release(&wait_lock);
    80002434:	0088f517          	auipc	a0,0x88f
    80002438:	e8450513          	addi	a0,a0,-380 # 808912b8 <wait_lock>
    8000243c:	fffff097          	auipc	ra,0xfffff
    80002440:	ac6080e7          	jalr	-1338(ra) # 80000f02 <release>
      return -1;
    80002444:	59fd                	li	s3,-1
}
    80002446:	854e                	mv	a0,s3
    80002448:	60a6                	ld	ra,72(sp)
    8000244a:	6406                	ld	s0,64(sp)
    8000244c:	74e2                	ld	s1,56(sp)
    8000244e:	7942                	ld	s2,48(sp)
    80002450:	79a2                	ld	s3,40(sp)
    80002452:	7a02                	ld	s4,32(sp)
    80002454:	6ae2                	ld	s5,24(sp)
    80002456:	6b42                	ld	s6,16(sp)
    80002458:	6ba2                	ld	s7,8(sp)
    8000245a:	6c02                	ld	s8,0(sp)
    8000245c:	6161                	addi	sp,sp,80
    8000245e:	8082                	ret
    sleep(p, &wait_lock);  //DOC: wait-sleep
    80002460:	85e2                	mv	a1,s8
    80002462:	854a                	mv	a0,s2
    80002464:	00000097          	auipc	ra,0x0
    80002468:	e7e080e7          	jalr	-386(ra) # 800022e2 <sleep>
    havekids = 0;
    8000246c:	b715                	j	80002390 <wait+0x4a>

000000008000246e <wakeup>:

// Wake up all processes sleeping on chan.
// Must be called without any p->lock.
void
wakeup(void *chan)
{
    8000246e:	7139                	addi	sp,sp,-64
    80002470:	fc06                	sd	ra,56(sp)
    80002472:	f822                	sd	s0,48(sp)
    80002474:	f426                	sd	s1,40(sp)
    80002476:	f04a                	sd	s2,32(sp)
    80002478:	ec4e                	sd	s3,24(sp)
    8000247a:	e852                	sd	s4,16(sp)
    8000247c:	e456                	sd	s5,8(sp)
    8000247e:	0080                	addi	s0,sp,64
    80002480:	8a2a                	mv	s4,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++) {
    80002482:	0088f497          	auipc	s1,0x88f
    80002486:	24e48493          	addi	s1,s1,590 # 808916d0 <proc>
    if(p != myproc()){
      acquire(&p->lock);
      if(p->state == SLEEPING && p->chan == chan) {
    8000248a:	4989                	li	s3,2
        p->state = RUNNABLE;
    8000248c:	4a8d                	li	s5,3
  for(p = proc; p < &proc[NPROC]; p++) {
    8000248e:	00895917          	auipc	s2,0x895
    80002492:	04290913          	addi	s2,s2,66 # 808974d0 <tickslock>
    80002496:	a821                	j	800024ae <wakeup+0x40>
        p->state = RUNNABLE;
    80002498:	0154ac23          	sw	s5,24(s1)
      }
      release(&p->lock);
    8000249c:	8526                	mv	a0,s1
    8000249e:	fffff097          	auipc	ra,0xfffff
    800024a2:	a64080e7          	jalr	-1436(ra) # 80000f02 <release>
  for(p = proc; p < &proc[NPROC]; p++) {
    800024a6:	17848493          	addi	s1,s1,376
    800024aa:	03248463          	beq	s1,s2,800024d2 <wakeup+0x64>
    if(p != myproc()){
    800024ae:	fffff097          	auipc	ra,0xfffff
    800024b2:	76c080e7          	jalr	1900(ra) # 80001c1a <myproc>
    800024b6:	fea488e3          	beq	s1,a0,800024a6 <wakeup+0x38>
      acquire(&p->lock);
    800024ba:	8526                	mv	a0,s1
    800024bc:	fffff097          	auipc	ra,0xfffff
    800024c0:	992080e7          	jalr	-1646(ra) # 80000e4e <acquire>
      if(p->state == SLEEPING && p->chan == chan) {
    800024c4:	4c9c                	lw	a5,24(s1)
    800024c6:	fd379be3          	bne	a5,s3,8000249c <wakeup+0x2e>
    800024ca:	709c                	ld	a5,32(s1)
    800024cc:	fd4798e3          	bne	a5,s4,8000249c <wakeup+0x2e>
    800024d0:	b7e1                	j	80002498 <wakeup+0x2a>
    }
  }
}
    800024d2:	70e2                	ld	ra,56(sp)
    800024d4:	7442                	ld	s0,48(sp)
    800024d6:	74a2                	ld	s1,40(sp)
    800024d8:	7902                	ld	s2,32(sp)
    800024da:	69e2                	ld	s3,24(sp)
    800024dc:	6a42                	ld	s4,16(sp)
    800024de:	6aa2                	ld	s5,8(sp)
    800024e0:	6121                	addi	sp,sp,64
    800024e2:	8082                	ret

00000000800024e4 <reparent>:
{
    800024e4:	7179                	addi	sp,sp,-48
    800024e6:	f406                	sd	ra,40(sp)
    800024e8:	f022                	sd	s0,32(sp)
    800024ea:	ec26                	sd	s1,24(sp)
    800024ec:	e84a                	sd	s2,16(sp)
    800024ee:	e44e                	sd	s3,8(sp)
    800024f0:	e052                	sd	s4,0(sp)
    800024f2:	1800                	addi	s0,sp,48
    800024f4:	892a                	mv	s2,a0
  for(pp = proc; pp < &proc[NPROC]; pp++){
    800024f6:	0088f497          	auipc	s1,0x88f
    800024fa:	1da48493          	addi	s1,s1,474 # 808916d0 <proc>
      pp->parent = initproc;
    800024fe:	00007a17          	auipc	s4,0x7
    80002502:	b2aa0a13          	addi	s4,s4,-1238 # 80009028 <initproc>
  for(pp = proc; pp < &proc[NPROC]; pp++){
    80002506:	00895997          	auipc	s3,0x895
    8000250a:	fca98993          	addi	s3,s3,-54 # 808974d0 <tickslock>
    8000250e:	a029                	j	80002518 <reparent+0x34>
    80002510:	17848493          	addi	s1,s1,376
    80002514:	01348d63          	beq	s1,s3,8000252e <reparent+0x4a>
    if(pp->parent == p){
    80002518:	7c9c                	ld	a5,56(s1)
    8000251a:	ff279be3          	bne	a5,s2,80002510 <reparent+0x2c>
      pp->parent = initproc;
    8000251e:	000a3503          	ld	a0,0(s4)
    80002522:	fc88                	sd	a0,56(s1)
      wakeup(initproc);
    80002524:	00000097          	auipc	ra,0x0
    80002528:	f4a080e7          	jalr	-182(ra) # 8000246e <wakeup>
    8000252c:	b7d5                	j	80002510 <reparent+0x2c>
}
    8000252e:	70a2                	ld	ra,40(sp)
    80002530:	7402                	ld	s0,32(sp)
    80002532:	64e2                	ld	s1,24(sp)
    80002534:	6942                	ld	s2,16(sp)
    80002536:	69a2                	ld	s3,8(sp)
    80002538:	6a02                	ld	s4,0(sp)
    8000253a:	6145                	addi	sp,sp,48
    8000253c:	8082                	ret

000000008000253e <exit>:
{
    8000253e:	7179                	addi	sp,sp,-48
    80002540:	f406                	sd	ra,40(sp)
    80002542:	f022                	sd	s0,32(sp)
    80002544:	ec26                	sd	s1,24(sp)
    80002546:	e84a                	sd	s2,16(sp)
    80002548:	e44e                	sd	s3,8(sp)
    8000254a:	e052                	sd	s4,0(sp)
    8000254c:	1800                	addi	s0,sp,48
    8000254e:	8a2a                	mv	s4,a0
  struct proc *p = myproc();
    80002550:	fffff097          	auipc	ra,0xfffff
    80002554:	6ca080e7          	jalr	1738(ra) # 80001c1a <myproc>
    80002558:	89aa                	mv	s3,a0
  if(p == initproc)
    8000255a:	00007797          	auipc	a5,0x7
    8000255e:	ace7b783          	ld	a5,-1330(a5) # 80009028 <initproc>
    80002562:	0d050493          	addi	s1,a0,208
    80002566:	15050913          	addi	s2,a0,336
    8000256a:	02a79363          	bne	a5,a0,80002590 <exit+0x52>
    panic("init exiting");
    8000256e:	00006517          	auipc	a0,0x6
    80002572:	d6250513          	addi	a0,a0,-670 # 800082d0 <digits+0x290>
    80002576:	ffffe097          	auipc	ra,0xffffe
    8000257a:	fc8080e7          	jalr	-56(ra) # 8000053e <panic>
      fileclose(f);
    8000257e:	00002097          	auipc	ra,0x2
    80002582:	2c6080e7          	jalr	710(ra) # 80004844 <fileclose>
      p->ofile[fd] = 0;
    80002586:	0004b023          	sd	zero,0(s1)
  for(int fd = 0; fd < NOFILE; fd++){
    8000258a:	04a1                	addi	s1,s1,8
    8000258c:	01248563          	beq	s1,s2,80002596 <exit+0x58>
    if(p->ofile[fd]){
    80002590:	6088                	ld	a0,0(s1)
    80002592:	f575                	bnez	a0,8000257e <exit+0x40>
    80002594:	bfdd                	j	8000258a <exit+0x4c>
  begin_op();
    80002596:	00002097          	auipc	ra,0x2
    8000259a:	de2080e7          	jalr	-542(ra) # 80004378 <begin_op>
  iput(p->cwd);
    8000259e:	1509b503          	ld	a0,336(s3)
    800025a2:	00001097          	auipc	ra,0x1
    800025a6:	5be080e7          	jalr	1470(ra) # 80003b60 <iput>
  end_op();
    800025aa:	00002097          	auipc	ra,0x2
    800025ae:	e4e080e7          	jalr	-434(ra) # 800043f8 <end_op>
  p->cwd = 0;
    800025b2:	1409b823          	sd	zero,336(s3)
  acquire(&wait_lock);
    800025b6:	0088f497          	auipc	s1,0x88f
    800025ba:	d0248493          	addi	s1,s1,-766 # 808912b8 <wait_lock>
    800025be:	8526                	mv	a0,s1
    800025c0:	fffff097          	auipc	ra,0xfffff
    800025c4:	88e080e7          	jalr	-1906(ra) # 80000e4e <acquire>
  reparent(p);
    800025c8:	854e                	mv	a0,s3
    800025ca:	00000097          	auipc	ra,0x0
    800025ce:	f1a080e7          	jalr	-230(ra) # 800024e4 <reparent>
  wakeup(p->parent);
    800025d2:	0389b503          	ld	a0,56(s3)
    800025d6:	00000097          	auipc	ra,0x0
    800025da:	e98080e7          	jalr	-360(ra) # 8000246e <wakeup>
  acquire(&p->lock);
    800025de:	854e                	mv	a0,s3
    800025e0:	fffff097          	auipc	ra,0xfffff
    800025e4:	86e080e7          	jalr	-1938(ra) # 80000e4e <acquire>
  p->xstate = status;
    800025e8:	0349a623          	sw	s4,44(s3)
  p->state = ZOMBIE;
    800025ec:	4795                	li	a5,5
    800025ee:	00f9ac23          	sw	a5,24(s3)
  release(&wait_lock);
    800025f2:	8526                	mv	a0,s1
    800025f4:	fffff097          	auipc	ra,0xfffff
    800025f8:	90e080e7          	jalr	-1778(ra) # 80000f02 <release>
  sched();
    800025fc:	00000097          	auipc	ra,0x0
    80002600:	bd4080e7          	jalr	-1068(ra) # 800021d0 <sched>
  panic("zombie exit");
    80002604:	00006517          	auipc	a0,0x6
    80002608:	cdc50513          	addi	a0,a0,-804 # 800082e0 <digits+0x2a0>
    8000260c:	ffffe097          	auipc	ra,0xffffe
    80002610:	f32080e7          	jalr	-206(ra) # 8000053e <panic>

0000000080002614 <kill>:
// Kill the process with the given pid.
// The victim won't exit until it tries to return
// to user space (see usertrap() in trap.c).
int
kill(int pid)
{
    80002614:	7179                	addi	sp,sp,-48
    80002616:	f406                	sd	ra,40(sp)
    80002618:	f022                	sd	s0,32(sp)
    8000261a:	ec26                	sd	s1,24(sp)
    8000261c:	e84a                	sd	s2,16(sp)
    8000261e:	e44e                	sd	s3,8(sp)
    80002620:	1800                	addi	s0,sp,48
    80002622:	892a                	mv	s2,a0
  struct proc *p;

  for(p = proc; p < &proc[NPROC]; p++){
    80002624:	0088f497          	auipc	s1,0x88f
    80002628:	0ac48493          	addi	s1,s1,172 # 808916d0 <proc>
    8000262c:	00895997          	auipc	s3,0x895
    80002630:	ea498993          	addi	s3,s3,-348 # 808974d0 <tickslock>
    acquire(&p->lock);
    80002634:	8526                	mv	a0,s1
    80002636:	fffff097          	auipc	ra,0xfffff
    8000263a:	818080e7          	jalr	-2024(ra) # 80000e4e <acquire>
    if(p->pid == pid){
    8000263e:	589c                	lw	a5,48(s1)
    80002640:	01278d63          	beq	a5,s2,8000265a <kill+0x46>
        p->state = RUNNABLE;
      }
      release(&p->lock);
      return 0;
    }
    release(&p->lock);
    80002644:	8526                	mv	a0,s1
    80002646:	fffff097          	auipc	ra,0xfffff
    8000264a:	8bc080e7          	jalr	-1860(ra) # 80000f02 <release>
  for(p = proc; p < &proc[NPROC]; p++){
    8000264e:	17848493          	addi	s1,s1,376
    80002652:	ff3491e3          	bne	s1,s3,80002634 <kill+0x20>
  }
  return -1;
    80002656:	557d                	li	a0,-1
    80002658:	a829                	j	80002672 <kill+0x5e>
      p->killed = 1;
    8000265a:	4785                	li	a5,1
    8000265c:	d49c                	sw	a5,40(s1)
      if(p->state == SLEEPING){
    8000265e:	4c98                	lw	a4,24(s1)
    80002660:	4789                	li	a5,2
    80002662:	00f70f63          	beq	a4,a5,80002680 <kill+0x6c>
      release(&p->lock);
    80002666:	8526                	mv	a0,s1
    80002668:	fffff097          	auipc	ra,0xfffff
    8000266c:	89a080e7          	jalr	-1894(ra) # 80000f02 <release>
      return 0;
    80002670:	4501                	li	a0,0
}
    80002672:	70a2                	ld	ra,40(sp)
    80002674:	7402                	ld	s0,32(sp)
    80002676:	64e2                	ld	s1,24(sp)
    80002678:	6942                	ld	s2,16(sp)
    8000267a:	69a2                	ld	s3,8(sp)
    8000267c:	6145                	addi	sp,sp,48
    8000267e:	8082                	ret
        p->state = RUNNABLE;
    80002680:	478d                	li	a5,3
    80002682:	cc9c                	sw	a5,24(s1)
    80002684:	b7cd                	j	80002666 <kill+0x52>

0000000080002686 <either_copyout>:
// Copy to either a user address, or kernel address,
// depending on usr_dst.
// Returns 0 on success, -1 on error.
int
either_copyout(int user_dst, uint64 dst, void *src, uint64 len)
{
    80002686:	7179                	addi	sp,sp,-48
    80002688:	f406                	sd	ra,40(sp)
    8000268a:	f022                	sd	s0,32(sp)
    8000268c:	ec26                	sd	s1,24(sp)
    8000268e:	e84a                	sd	s2,16(sp)
    80002690:	e44e                	sd	s3,8(sp)
    80002692:	e052                	sd	s4,0(sp)
    80002694:	1800                	addi	s0,sp,48
    80002696:	84aa                	mv	s1,a0
    80002698:	892e                	mv	s2,a1
    8000269a:	89b2                	mv	s3,a2
    8000269c:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    8000269e:	fffff097          	auipc	ra,0xfffff
    800026a2:	57c080e7          	jalr	1404(ra) # 80001c1a <myproc>
  if(user_dst){
    800026a6:	c08d                	beqz	s1,800026c8 <either_copyout+0x42>
    return copyout(p->pagetable, dst, src, len);
    800026a8:	86d2                	mv	a3,s4
    800026aa:	864e                	mv	a2,s3
    800026ac:	85ca                	mv	a1,s2
    800026ae:	6928                	ld	a0,80(a0)
    800026b0:	fffff097          	auipc	ra,0xfffff
    800026b4:	22c080e7          	jalr	556(ra) # 800018dc <copyout>
  } else {
    memmove((char *)dst, src, len);
    return 0;
  }
}
    800026b8:	70a2                	ld	ra,40(sp)
    800026ba:	7402                	ld	s0,32(sp)
    800026bc:	64e2                	ld	s1,24(sp)
    800026be:	6942                	ld	s2,16(sp)
    800026c0:	69a2                	ld	s3,8(sp)
    800026c2:	6a02                	ld	s4,0(sp)
    800026c4:	6145                	addi	sp,sp,48
    800026c6:	8082                	ret
    memmove((char *)dst, src, len);
    800026c8:	000a061b          	sext.w	a2,s4
    800026cc:	85ce                	mv	a1,s3
    800026ce:	854a                	mv	a0,s2
    800026d0:	fffff097          	auipc	ra,0xfffff
    800026d4:	8da080e7          	jalr	-1830(ra) # 80000faa <memmove>
    return 0;
    800026d8:	8526                	mv	a0,s1
    800026da:	bff9                	j	800026b8 <either_copyout+0x32>

00000000800026dc <either_copyin>:
// Copy from either a user address, or kernel address,
// depending on usr_src.
// Returns 0 on success, -1 on error.
int
either_copyin(void *dst, int user_src, uint64 src, uint64 len)
{
    800026dc:	7179                	addi	sp,sp,-48
    800026de:	f406                	sd	ra,40(sp)
    800026e0:	f022                	sd	s0,32(sp)
    800026e2:	ec26                	sd	s1,24(sp)
    800026e4:	e84a                	sd	s2,16(sp)
    800026e6:	e44e                	sd	s3,8(sp)
    800026e8:	e052                	sd	s4,0(sp)
    800026ea:	1800                	addi	s0,sp,48
    800026ec:	892a                	mv	s2,a0
    800026ee:	84ae                	mv	s1,a1
    800026f0:	89b2                	mv	s3,a2
    800026f2:	8a36                	mv	s4,a3
  struct proc *p = myproc();
    800026f4:	fffff097          	auipc	ra,0xfffff
    800026f8:	526080e7          	jalr	1318(ra) # 80001c1a <myproc>
  if(user_src){
    800026fc:	c08d                	beqz	s1,8000271e <either_copyin+0x42>
    return copyin(p->pagetable, dst, src, len);
    800026fe:	86d2                	mv	a3,s4
    80002700:	864e                	mv	a2,s3
    80002702:	85ca                	mv	a1,s2
    80002704:	6928                	ld	a0,80(a0)
    80002706:	fffff097          	auipc	ra,0xfffff
    8000270a:	262080e7          	jalr	610(ra) # 80001968 <copyin>
  } else {
    memmove(dst, (char*)src, len);
    return 0;
  }
}
    8000270e:	70a2                	ld	ra,40(sp)
    80002710:	7402                	ld	s0,32(sp)
    80002712:	64e2                	ld	s1,24(sp)
    80002714:	6942                	ld	s2,16(sp)
    80002716:	69a2                	ld	s3,8(sp)
    80002718:	6a02                	ld	s4,0(sp)
    8000271a:	6145                	addi	sp,sp,48
    8000271c:	8082                	ret
    memmove(dst, (char*)src, len);
    8000271e:	000a061b          	sext.w	a2,s4
    80002722:	85ce                	mv	a1,s3
    80002724:	854a                	mv	a0,s2
    80002726:	fffff097          	auipc	ra,0xfffff
    8000272a:	884080e7          	jalr	-1916(ra) # 80000faa <memmove>
    return 0;
    8000272e:	8526                	mv	a0,s1
    80002730:	bff9                	j	8000270e <either_copyin+0x32>

0000000080002732 <procdump>:
// Print a process listing to console.  For debugging.
// Runs when user types ^P on console.
// No lock to avoid wedging a stuck machine further.
void
procdump(void)
{
    80002732:	715d                	addi	sp,sp,-80
    80002734:	e486                	sd	ra,72(sp)
    80002736:	e0a2                	sd	s0,64(sp)
    80002738:	fc26                	sd	s1,56(sp)
    8000273a:	f84a                	sd	s2,48(sp)
    8000273c:	f44e                	sd	s3,40(sp)
    8000273e:	f052                	sd	s4,32(sp)
    80002740:	ec56                	sd	s5,24(sp)
    80002742:	e85a                	sd	s6,16(sp)
    80002744:	e45e                	sd	s7,8(sp)
    80002746:	0880                	addi	s0,sp,80
  [ZOMBIE]    "zombie"
  };
  struct proc *p;
  char *state;

  printf("\n");
    80002748:	00006517          	auipc	a0,0x6
    8000274c:	11050513          	addi	a0,a0,272 # 80008858 <syscalls+0x338>
    80002750:	ffffe097          	auipc	ra,0xffffe
    80002754:	e38080e7          	jalr	-456(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    80002758:	0088f497          	auipc	s1,0x88f
    8000275c:	0d048493          	addi	s1,s1,208 # 80891828 <proc+0x158>
    80002760:	00895917          	auipc	s2,0x895
    80002764:	ec890913          	addi	s2,s2,-312 # 80897628 <bcache+0x140>
    if(p->state == UNUSED)
      continue;
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002768:	4b15                	li	s6,5
      state = states[p->state];
    else
      state = "???";
    8000276a:	00006997          	auipc	s3,0x6
    8000276e:	b8698993          	addi	s3,s3,-1146 # 800082f0 <digits+0x2b0>
    printf("%d %s %s", p->pid, state, p->name);
    80002772:	00006a97          	auipc	s5,0x6
    80002776:	b86a8a93          	addi	s5,s5,-1146 # 800082f8 <digits+0x2b8>
    printf("\n");
    8000277a:	00006a17          	auipc	s4,0x6
    8000277e:	0dea0a13          	addi	s4,s4,222 # 80008858 <syscalls+0x338>
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    80002782:	00006b97          	auipc	s7,0x6
    80002786:	baeb8b93          	addi	s7,s7,-1106 # 80008330 <states.1712>
    8000278a:	a00d                	j	800027ac <procdump+0x7a>
    printf("%d %s %s", p->pid, state, p->name);
    8000278c:	ed86a583          	lw	a1,-296(a3)
    80002790:	8556                	mv	a0,s5
    80002792:	ffffe097          	auipc	ra,0xffffe
    80002796:	df6080e7          	jalr	-522(ra) # 80000588 <printf>
    printf("\n");
    8000279a:	8552                	mv	a0,s4
    8000279c:	ffffe097          	auipc	ra,0xffffe
    800027a0:	dec080e7          	jalr	-532(ra) # 80000588 <printf>
  for(p = proc; p < &proc[NPROC]; p++){
    800027a4:	17848493          	addi	s1,s1,376
    800027a8:	03248163          	beq	s1,s2,800027ca <procdump+0x98>
    if(p->state == UNUSED)
    800027ac:	86a6                	mv	a3,s1
    800027ae:	ec04a783          	lw	a5,-320(s1)
    800027b2:	dbed                	beqz	a5,800027a4 <procdump+0x72>
      state = "???";
    800027b4:	864e                	mv	a2,s3
    if(p->state >= 0 && p->state < NELEM(states) && states[p->state])
    800027b6:	fcfb6be3          	bltu	s6,a5,8000278c <procdump+0x5a>
    800027ba:	1782                	slli	a5,a5,0x20
    800027bc:	9381                	srli	a5,a5,0x20
    800027be:	078e                	slli	a5,a5,0x3
    800027c0:	97de                	add	a5,a5,s7
    800027c2:	6390                	ld	a2,0(a5)
    800027c4:	f661                	bnez	a2,8000278c <procdump+0x5a>
      state = "???";
    800027c6:	864e                	mv	a2,s3
    800027c8:	b7d1                	j	8000278c <procdump+0x5a>
  }
}
    800027ca:	60a6                	ld	ra,72(sp)
    800027cc:	6406                	ld	s0,64(sp)
    800027ce:	74e2                	ld	s1,56(sp)
    800027d0:	7942                	ld	s2,48(sp)
    800027d2:	79a2                	ld	s3,40(sp)
    800027d4:	7a02                	ld	s4,32(sp)
    800027d6:	6ae2                	ld	s5,24(sp)
    800027d8:	6b42                	ld	s6,16(sp)
    800027da:	6ba2                	ld	s7,8(sp)
    800027dc:	6161                	addi	sp,sp,80
    800027de:	8082                	ret

00000000800027e0 <swtch>:
    800027e0:	00153023          	sd	ra,0(a0)
    800027e4:	00253423          	sd	sp,8(a0)
    800027e8:	e900                	sd	s0,16(a0)
    800027ea:	ed04                	sd	s1,24(a0)
    800027ec:	03253023          	sd	s2,32(a0)
    800027f0:	03353423          	sd	s3,40(a0)
    800027f4:	03453823          	sd	s4,48(a0)
    800027f8:	03553c23          	sd	s5,56(a0)
    800027fc:	05653023          	sd	s6,64(a0)
    80002800:	05753423          	sd	s7,72(a0)
    80002804:	05853823          	sd	s8,80(a0)
    80002808:	05953c23          	sd	s9,88(a0)
    8000280c:	07a53023          	sd	s10,96(a0)
    80002810:	07b53423          	sd	s11,104(a0)
    80002814:	0005b083          	ld	ra,0(a1)
    80002818:	0085b103          	ld	sp,8(a1)
    8000281c:	6980                	ld	s0,16(a1)
    8000281e:	6d84                	ld	s1,24(a1)
    80002820:	0205b903          	ld	s2,32(a1)
    80002824:	0285b983          	ld	s3,40(a1)
    80002828:	0305ba03          	ld	s4,48(a1)
    8000282c:	0385ba83          	ld	s5,56(a1)
    80002830:	0405bb03          	ld	s6,64(a1)
    80002834:	0485bb83          	ld	s7,72(a1)
    80002838:	0505bc03          	ld	s8,80(a1)
    8000283c:	0585bc83          	ld	s9,88(a1)
    80002840:	0605bd03          	ld	s10,96(a1)
    80002844:	0685bd83          	ld	s11,104(a1)
    80002848:	8082                	ret

000000008000284a <trapinit>:

extern int devintr();

void
trapinit(void)
{
    8000284a:	1141                	addi	sp,sp,-16
    8000284c:	e406                	sd	ra,8(sp)
    8000284e:	e022                	sd	s0,0(sp)
    80002850:	0800                	addi	s0,sp,16
  initlock(&tickslock, "time");
    80002852:	00006597          	auipc	a1,0x6
    80002856:	b0e58593          	addi	a1,a1,-1266 # 80008360 <states.1712+0x30>
    8000285a:	00895517          	auipc	a0,0x895
    8000285e:	c7650513          	addi	a0,a0,-906 # 808974d0 <tickslock>
    80002862:	ffffe097          	auipc	ra,0xffffe
    80002866:	55c080e7          	jalr	1372(ra) # 80000dbe <initlock>
}
    8000286a:	60a2                	ld	ra,8(sp)
    8000286c:	6402                	ld	s0,0(sp)
    8000286e:	0141                	addi	sp,sp,16
    80002870:	8082                	ret

0000000080002872 <trapinithart>:

// set up to take exceptions and traps while in the kernel.
void
trapinithart(void)
{
    80002872:	1141                	addi	sp,sp,-16
    80002874:	e422                	sd	s0,8(sp)
    80002876:	0800                	addi	s0,sp,16
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002878:	00004797          	auipc	a5,0x4
    8000287c:	89878793          	addi	a5,a5,-1896 # 80006110 <kernelvec>
    80002880:	10579073          	csrw	stvec,a5
  w_stvec((uint64)kernelvec);
}
    80002884:	6422                	ld	s0,8(sp)
    80002886:	0141                	addi	sp,sp,16
    80002888:	8082                	ret

000000008000288a <usertrapret>:
//
// return to user space
//
void
usertrapret(void)
{
    8000288a:	1141                	addi	sp,sp,-16
    8000288c:	e406                	sd	ra,8(sp)
    8000288e:	e022                	sd	s0,0(sp)
    80002890:	0800                	addi	s0,sp,16
  struct proc *p = myproc();
    80002892:	fffff097          	auipc	ra,0xfffff
    80002896:	388080e7          	jalr	904(ra) # 80001c1a <myproc>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    8000289a:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() & ~SSTATUS_SIE);
    8000289e:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028a0:	10079073          	csrw	sstatus,a5
  // kerneltrap() to usertrap(), so turn off interrupts until
  // we're back in user space, where usertrap() is correct.
  intr_off();

  // send syscalls, interrupts, and exceptions to trampoline.S
  w_stvec(TRAMPOLINE + (uservec - trampoline));
    800028a4:	00004617          	auipc	a2,0x4
    800028a8:	75c60613          	addi	a2,a2,1884 # 80007000 <_trampoline>
    800028ac:	00004697          	auipc	a3,0x4
    800028b0:	75468693          	addi	a3,a3,1876 # 80007000 <_trampoline>
    800028b4:	8e91                	sub	a3,a3,a2
    800028b6:	040007b7          	lui	a5,0x4000
    800028ba:	17fd                	addi	a5,a5,-1
    800028bc:	07b2                	slli	a5,a5,0xc
    800028be:	96be                	add	a3,a3,a5
  asm volatile("csrw stvec, %0" : : "r" (x));
    800028c0:	10569073          	csrw	stvec,a3

  // set up trapframe values that uservec will need when
  // the process next re-enters the kernel.
  p->trapframe->kernel_satp = r_satp();         // kernel page table
    800028c4:	6d38                	ld	a4,88(a0)
  asm volatile("csrr %0, satp" : "=r" (x) );
    800028c6:	180026f3          	csrr	a3,satp
    800028ca:	e314                	sd	a3,0(a4)
  p->trapframe->kernel_sp = p->kstack + PGSIZE; // process's kernel stack
    800028cc:	6d38                	ld	a4,88(a0)
    800028ce:	6134                	ld	a3,64(a0)
    800028d0:	6585                	lui	a1,0x1
    800028d2:	96ae                	add	a3,a3,a1
    800028d4:	e714                	sd	a3,8(a4)
  p->trapframe->kernel_trap = (uint64)usertrap;
    800028d6:	6d38                	ld	a4,88(a0)
    800028d8:	00000697          	auipc	a3,0x0
    800028dc:	13868693          	addi	a3,a3,312 # 80002a10 <usertrap>
    800028e0:	eb14                	sd	a3,16(a4)
  p->trapframe->kernel_hartid = r_tp();         // hartid for cpuid()
    800028e2:	6d38                	ld	a4,88(a0)
  asm volatile("mv %0, tp" : "=r" (x) );
    800028e4:	8692                	mv	a3,tp
    800028e6:	f314                	sd	a3,32(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    800028e8:	100026f3          	csrr	a3,sstatus
  // set up the registers that trampoline.S's sret will use
  // to get to user space.
  
  // set S Previous Privilege mode to User.
  unsigned long x = r_sstatus();
  x &= ~SSTATUS_SPP; // clear SPP to 0 for user mode
    800028ec:	eff6f693          	andi	a3,a3,-257
  x |= SSTATUS_SPIE; // enable interrupts in user mode
    800028f0:	0206e693          	ori	a3,a3,32
  asm volatile("csrw sstatus, %0" : : "r" (x));
    800028f4:	10069073          	csrw	sstatus,a3
  w_sstatus(x);

  // set S Exception Program Counter to the saved user pc.
  w_sepc(p->trapframe->epc);
    800028f8:	6d38                	ld	a4,88(a0)
  asm volatile("csrw sepc, %0" : : "r" (x));
    800028fa:	6f18                	ld	a4,24(a4)
    800028fc:	14171073          	csrw	sepc,a4

  // tell trampoline.S the user page table to switch to.
  uint64 satp = MAKE_SATP(p->pagetable);
    80002900:	692c                	ld	a1,80(a0)
    80002902:	81b1                	srli	a1,a1,0xc

  // jump to trampoline.S at the top of memory, which 
  // switches to the user page table, restores user registers,
  // and switches to user mode with sret.
  uint64 fn = TRAMPOLINE + (userret - trampoline);
    80002904:	00004717          	auipc	a4,0x4
    80002908:	78c70713          	addi	a4,a4,1932 # 80007090 <userret>
    8000290c:	8f11                	sub	a4,a4,a2
    8000290e:	97ba                	add	a5,a5,a4
  ((void (*)(uint64,uint64))fn)(TRAPFRAME, satp);
    80002910:	577d                	li	a4,-1
    80002912:	177e                	slli	a4,a4,0x3f
    80002914:	8dd9                	or	a1,a1,a4
    80002916:	02000537          	lui	a0,0x2000
    8000291a:	157d                	addi	a0,a0,-1
    8000291c:	0536                	slli	a0,a0,0xd
    8000291e:	9782                	jalr	a5
}
    80002920:	60a2                	ld	ra,8(sp)
    80002922:	6402                	ld	s0,0(sp)
    80002924:	0141                	addi	sp,sp,16
    80002926:	8082                	ret

0000000080002928 <clockintr>:
  w_sstatus(sstatus);
}

void
clockintr()
{
    80002928:	1101                	addi	sp,sp,-32
    8000292a:	ec06                	sd	ra,24(sp)
    8000292c:	e822                	sd	s0,16(sp)
    8000292e:	e426                	sd	s1,8(sp)
    80002930:	1000                	addi	s0,sp,32
  acquire(&tickslock);
    80002932:	00895497          	auipc	s1,0x895
    80002936:	b9e48493          	addi	s1,s1,-1122 # 808974d0 <tickslock>
    8000293a:	8526                	mv	a0,s1
    8000293c:	ffffe097          	auipc	ra,0xffffe
    80002940:	512080e7          	jalr	1298(ra) # 80000e4e <acquire>
  ticks++;
    80002944:	00006517          	auipc	a0,0x6
    80002948:	6ec50513          	addi	a0,a0,1772 # 80009030 <ticks>
    8000294c:	411c                	lw	a5,0(a0)
    8000294e:	2785                	addiw	a5,a5,1
    80002950:	c11c                	sw	a5,0(a0)
  wakeup(&ticks);
    80002952:	00000097          	auipc	ra,0x0
    80002956:	b1c080e7          	jalr	-1252(ra) # 8000246e <wakeup>
  release(&tickslock);
    8000295a:	8526                	mv	a0,s1
    8000295c:	ffffe097          	auipc	ra,0xffffe
    80002960:	5a6080e7          	jalr	1446(ra) # 80000f02 <release>
}
    80002964:	60e2                	ld	ra,24(sp)
    80002966:	6442                	ld	s0,16(sp)
    80002968:	64a2                	ld	s1,8(sp)
    8000296a:	6105                	addi	sp,sp,32
    8000296c:	8082                	ret

000000008000296e <devintr>:
// returns 2 if timer interrupt,
// 1 if other device,
// 0 if not recognized.
int
devintr()
{
    8000296e:	1101                	addi	sp,sp,-32
    80002970:	ec06                	sd	ra,24(sp)
    80002972:	e822                	sd	s0,16(sp)
    80002974:	e426                	sd	s1,8(sp)
    80002976:	1000                	addi	s0,sp,32
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002978:	14202773          	csrr	a4,scause
  uint64 scause = r_scause();

  if((scause & 0x8000000000000000L) &&
    8000297c:	00074d63          	bltz	a4,80002996 <devintr+0x28>
    // now allowed to interrupt again.
    if(irq)
      plic_complete(irq);

    return 1;
  } else if(scause == 0x8000000000000001L){
    80002980:	57fd                	li	a5,-1
    80002982:	17fe                	slli	a5,a5,0x3f
    80002984:	0785                	addi	a5,a5,1
    // the SSIP bit in sip.
    w_sip(r_sip() & ~2);

    return 2;
  } else {
    return 0;
    80002986:	4501                	li	a0,0
  } else if(scause == 0x8000000000000001L){
    80002988:	06f70363          	beq	a4,a5,800029ee <devintr+0x80>
  }
}
    8000298c:	60e2                	ld	ra,24(sp)
    8000298e:	6442                	ld	s0,16(sp)
    80002990:	64a2                	ld	s1,8(sp)
    80002992:	6105                	addi	sp,sp,32
    80002994:	8082                	ret
     (scause & 0xff) == 9){
    80002996:	0ff77793          	andi	a5,a4,255
  if((scause & 0x8000000000000000L) &&
    8000299a:	46a5                	li	a3,9
    8000299c:	fed792e3          	bne	a5,a3,80002980 <devintr+0x12>
    int irq = plic_claim();
    800029a0:	00004097          	auipc	ra,0x4
    800029a4:	878080e7          	jalr	-1928(ra) # 80006218 <plic_claim>
    800029a8:	84aa                	mv	s1,a0
    if(irq == UART0_IRQ){
    800029aa:	47a9                	li	a5,10
    800029ac:	02f50763          	beq	a0,a5,800029da <devintr+0x6c>
    } else if(irq == VIRTIO0_IRQ){
    800029b0:	4785                	li	a5,1
    800029b2:	02f50963          	beq	a0,a5,800029e4 <devintr+0x76>
    return 1;
    800029b6:	4505                	li	a0,1
    } else if(irq){
    800029b8:	d8f1                	beqz	s1,8000298c <devintr+0x1e>
      printf("unexpected interrupt irq=%d\n", irq);
    800029ba:	85a6                	mv	a1,s1
    800029bc:	00006517          	auipc	a0,0x6
    800029c0:	9ac50513          	addi	a0,a0,-1620 # 80008368 <states.1712+0x38>
    800029c4:	ffffe097          	auipc	ra,0xffffe
    800029c8:	bc4080e7          	jalr	-1084(ra) # 80000588 <printf>
      plic_complete(irq);
    800029cc:	8526                	mv	a0,s1
    800029ce:	00004097          	auipc	ra,0x4
    800029d2:	86e080e7          	jalr	-1938(ra) # 8000623c <plic_complete>
    return 1;
    800029d6:	4505                	li	a0,1
    800029d8:	bf55                	j	8000298c <devintr+0x1e>
      uartintr();
    800029da:	ffffe097          	auipc	ra,0xffffe
    800029de:	fce080e7          	jalr	-50(ra) # 800009a8 <uartintr>
    800029e2:	b7ed                	j	800029cc <devintr+0x5e>
      virtio_disk_intr();
    800029e4:	00004097          	auipc	ra,0x4
    800029e8:	d38080e7          	jalr	-712(ra) # 8000671c <virtio_disk_intr>
    800029ec:	b7c5                	j	800029cc <devintr+0x5e>
    if(cpuid() == 0){
    800029ee:	fffff097          	auipc	ra,0xfffff
    800029f2:	200080e7          	jalr	512(ra) # 80001bee <cpuid>
    800029f6:	c901                	beqz	a0,80002a06 <devintr+0x98>
  asm volatile("csrr %0, sip" : "=r" (x) );
    800029f8:	144027f3          	csrr	a5,sip
    w_sip(r_sip() & ~2);
    800029fc:	9bf5                	andi	a5,a5,-3
  asm volatile("csrw sip, %0" : : "r" (x));
    800029fe:	14479073          	csrw	sip,a5
    return 2;
    80002a02:	4509                	li	a0,2
    80002a04:	b761                	j	8000298c <devintr+0x1e>
      clockintr();
    80002a06:	00000097          	auipc	ra,0x0
    80002a0a:	f22080e7          	jalr	-222(ra) # 80002928 <clockintr>
    80002a0e:	b7ed                	j	800029f8 <devintr+0x8a>

0000000080002a10 <usertrap>:
{
    80002a10:	7139                	addi	sp,sp,-64
    80002a12:	fc06                	sd	ra,56(sp)
    80002a14:	f822                	sd	s0,48(sp)
    80002a16:	f426                	sd	s1,40(sp)
    80002a18:	f04a                	sd	s2,32(sp)
    80002a1a:	ec4e                	sd	s3,24(sp)
    80002a1c:	e852                	sd	s4,16(sp)
    80002a1e:	e456                	sd	s5,8(sp)
    80002a20:	0080                	addi	s0,sp,64
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a22:	100027f3          	csrr	a5,sstatus
  if((r_sstatus() & SSTATUS_SPP) != 0)
    80002a26:	1007f793          	andi	a5,a5,256
    80002a2a:	e7bd                	bnez	a5,80002a98 <usertrap+0x88>
  asm volatile("csrw stvec, %0" : : "r" (x));
    80002a2c:	00003797          	auipc	a5,0x3
    80002a30:	6e478793          	addi	a5,a5,1764 # 80006110 <kernelvec>
    80002a34:	10579073          	csrw	stvec,a5
  struct proc *p = myproc();
    80002a38:	fffff097          	auipc	ra,0xfffff
    80002a3c:	1e2080e7          	jalr	482(ra) # 80001c1a <myproc>
    80002a40:	89aa                	mv	s3,a0
  p->trapframe->epc = r_sepc();
    80002a42:	6d3c                	ld	a5,88(a0)
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002a44:	14102773          	csrr	a4,sepc
    80002a48:	ef98                	sd	a4,24(a5)
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002a4a:	14202773          	csrr	a4,scause
  if(r_scause() == 8){
    80002a4e:	47a1                	li	a5,8
    80002a50:	06f71263          	bne	a4,a5,80002ab4 <usertrap+0xa4>
    if(p->killed)
    80002a54:	551c                	lw	a5,40(a0)
    80002a56:	eba9                	bnez	a5,80002aa8 <usertrap+0x98>
    p->trapframe->epc += 4;
    80002a58:	0589b703          	ld	a4,88(s3)
    80002a5c:	6f1c                	ld	a5,24(a4)
    80002a5e:	0791                	addi	a5,a5,4
    80002a60:	ef1c                	sd	a5,24(a4)
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002a62:	100027f3          	csrr	a5,sstatus
  w_sstatus(r_sstatus() | SSTATUS_SIE);
    80002a66:	0027e793          	ori	a5,a5,2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002a6a:	10079073          	csrw	sstatus,a5
    syscall();
    80002a6e:	00000097          	auipc	ra,0x0
    80002a72:	43a080e7          	jalr	1082(ra) # 80002ea8 <syscall>
  if(p->killed)
    80002a76:	0289a783          	lw	a5,40(s3)
    80002a7a:	1c079863          	bnez	a5,80002c4a <usertrap+0x23a>
  usertrapret();
    80002a7e:	00000097          	auipc	ra,0x0
    80002a82:	e0c080e7          	jalr	-500(ra) # 8000288a <usertrapret>
}
    80002a86:	70e2                	ld	ra,56(sp)
    80002a88:	7442                	ld	s0,48(sp)
    80002a8a:	74a2                	ld	s1,40(sp)
    80002a8c:	7902                	ld	s2,32(sp)
    80002a8e:	69e2                	ld	s3,24(sp)
    80002a90:	6a42                	ld	s4,16(sp)
    80002a92:	6aa2                	ld	s5,8(sp)
    80002a94:	6121                	addi	sp,sp,64
    80002a96:	8082                	ret
    panic("usertrap: not from user mode");
    80002a98:	00006517          	auipc	a0,0x6
    80002a9c:	8f050513          	addi	a0,a0,-1808 # 80008388 <states.1712+0x58>
    80002aa0:	ffffe097          	auipc	ra,0xffffe
    80002aa4:	a9e080e7          	jalr	-1378(ra) # 8000053e <panic>
      exit(-1);
    80002aa8:	557d                	li	a0,-1
    80002aaa:	00000097          	auipc	ra,0x0
    80002aae:	a94080e7          	jalr	-1388(ra) # 8000253e <exit>
    80002ab2:	b75d                	j	80002a58 <usertrap+0x48>
  } else if((which_dev = devintr()) != 0){
    80002ab4:	00000097          	auipc	ra,0x0
    80002ab8:	eba080e7          	jalr	-326(ra) # 8000296e <devintr>
    80002abc:	84aa                	mv	s1,a0
    80002abe:	18051263          	bnez	a0,80002c42 <usertrap+0x232>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002ac2:	14202773          	csrr	a4,scause
  }else if(r_scause() == 12 || r_scause() == 13 || r_scause() == 15){
    80002ac6:	47b1                	li	a5,12
    80002ac8:	00f70c63          	beq	a4,a5,80002ae0 <usertrap+0xd0>
    80002acc:	14202773          	csrr	a4,scause
    80002ad0:	47b5                	li	a5,13
    80002ad2:	00f70763          	beq	a4,a5,80002ae0 <usertrap+0xd0>
    80002ad6:	14202773          	csrr	a4,scause
    80002ada:	47bd                	li	a5,15
    80002adc:	12f71763          	bne	a4,a5,80002c0a <usertrap+0x1fa>
    printf("FALLO DE PAGINA\n"); 
    80002ae0:	00006517          	auipc	a0,0x6
    80002ae4:	8c850513          	addi	a0,a0,-1848 # 800083a8 <states.1712+0x78>
    80002ae8:	ffffe097          	auipc	ra,0xffffe
    80002aec:	aa0080e7          	jalr	-1376(ra) # 80000588 <printf>
    if(p->nvma == 0){
    80002af0:	1709a783          	lw	a5,368(s3)
    80002af4:	cf95                	beqz	a5,80002b30 <usertrap+0x120>
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002af6:	14302a73          	csrr	s4,stval
    struct vma *act = p->vmas;  
    80002afa:	1689b903          	ld	s2,360(s3)
    printf("DIRECCION DE FALLO %p\n", f_vaddr);
    80002afe:	85d2                	mv	a1,s4
    80002b00:	00006517          	auipc	a0,0x6
    80002b04:	8c050513          	addi	a0,a0,-1856 # 800083c0 <states.1712+0x90>
    80002b08:	ffffe097          	auipc	ra,0xffffe
    80002b0c:	a80080e7          	jalr	-1408(ra) # 80000588 <printf>
    printf("DIRECCION 1 %p\n", act->addri);
    80002b10:	01893583          	ld	a1,24(s2)
    80002b14:	00006517          	auipc	a0,0x6
    80002b18:	8c450513          	addi	a0,a0,-1852 # 800083d8 <states.1712+0xa8>
    80002b1c:	ffffe097          	auipc	ra,0xffffe
    80002b20:	a6c080e7          	jalr	-1428(ra) # 80000588 <printf>
    for(i = 0; i<p->nvma; i++){ //See if the address fits in any vma    TRATAR FALLOS DE PAGINA QUE NO SEAN DE LA VMA
    80002b24:	1709aa83          	lw	s5,368(s3)
    80002b28:	03504263          	bgtz	s5,80002b4c <usertrap+0x13c>
    80002b2c:	8aa6                	mv	s5,s1
    80002b2e:	a80d                	j	80002b60 <usertrap+0x150>
      p->killed = 1;
    80002b30:	4785                	li	a5,1
    80002b32:	02f9a423          	sw	a5,40(s3)
      exit(-1);
    80002b36:	557d                	li	a0,-1
    80002b38:	00000097          	auipc	ra,0x0
    80002b3c:	a06080e7          	jalr	-1530(ra) # 8000253e <exit>
    80002b40:	bf5d                	j	80002af6 <usertrap+0xe6>
      act = act->next;
    80002b42:	03093903          	ld	s2,48(s2)
    for(i = 0; i<p->nvma; i++){ //See if the address fits in any vma    TRATAR FALLOS DE PAGINA QUE NO SEAN DE LA VMA
    80002b46:	2485                	addiw	s1,s1,1
    80002b48:	01548c63          	beq	s1,s5,80002b60 <usertrap+0x150>
      if(f_vaddr >= act->addri && f_vaddr < act->addri+act->size) break;
    80002b4c:	01893783          	ld	a5,24(s2)
    80002b50:	fefa69e3          	bltu	s4,a5,80002b42 <usertrap+0x132>
    80002b54:	00893703          	ld	a4,8(s2)
    80002b58:	97ba                	add	a5,a5,a4
    80002b5a:	fefa74e3          	bgeu	s4,a5,80002b42 <usertrap+0x132>
    80002b5e:	8aa6                	mv	s5,s1
    printf("DIRECCION DE FALLO %p\n", f_vaddr);
    80002b60:	85d2                	mv	a1,s4
    80002b62:	00006517          	auipc	a0,0x6
    80002b66:	85e50513          	addi	a0,a0,-1954 # 800083c0 <states.1712+0x90>
    80002b6a:	ffffe097          	auipc	ra,0xffffe
    80002b6e:	a1e080e7          	jalr	-1506(ra) # 80000588 <printf>
    if(i == p->nvma){
    80002b72:	1709a783          	lw	a5,368(s3)
    80002b76:	07578d63          	beq	a5,s5,80002bf0 <usertrap+0x1e0>
    printf("1\n");
    80002b7a:	00006517          	auipc	a0,0x6
    80002b7e:	86e50513          	addi	a0,a0,-1938 # 800083e8 <states.1712+0xb8>
    80002b82:	ffffe097          	auipc	ra,0xffffe
    80002b86:	a06080e7          	jalr	-1530(ra) # 80000588 <printf>
    char *paddr = kalloc();    
    80002b8a:	ffffe097          	auipc	ra,0xffffe
    80002b8e:	086080e7          	jalr	134(ra) # 80000c10 <kalloc>
    80002b92:	84aa                	mv	s1,a0
    if(paddr == 0) p->killed = 1;
    80002b94:	c53d                	beqz	a0,80002c02 <usertrap+0x1f2>
    memset(paddr, 0, PGSIZE); //Set all page to 0
    80002b96:	6605                	lui	a2,0x1
    80002b98:	4581                	li	a1,0
    80002b9a:	8526                	mv	a0,s1
    80002b9c:	ffffe097          	auipc	ra,0xffffe
    80002ba0:	3ae080e7          	jalr	942(ra) # 80000f4a <memset>
    printf("Dirección de memoria dada %p\n", paddr);
    80002ba4:	85a6                	mv	a1,s1
    80002ba6:	00006517          	auipc	a0,0x6
    80002baa:	84a50513          	addi	a0,a0,-1974 # 800083f0 <states.1712+0xc0>
    80002bae:	ffffe097          	auipc	ra,0xffffe
    80002bb2:	9da080e7          	jalr	-1574(ra) # 80000588 <printf>
    if(mappages(p->pagetable, f_vaddr, PGSIZE, (uint64)paddr, act->prot | PTE_U) != 0){
    80002bb6:	03892703          	lw	a4,56(s2)
    80002bba:	01076713          	ori	a4,a4,16
    80002bbe:	86a6                	mv	a3,s1
    80002bc0:	6605                	lui	a2,0x1
    80002bc2:	85d2                	mv	a1,s4
    80002bc4:	0509b503          	ld	a0,80(s3)
    80002bc8:	ffffe097          	auipc	ra,0xffffe
    80002bcc:	752080e7          	jalr	1874(ra) # 8000131a <mappages>
    80002bd0:	ea0503e3          	beqz	a0,80002a76 <usertrap+0x66>
      kfree(paddr);
    80002bd4:	8526                	mv	a0,s1
    80002bd6:	ffffe097          	auipc	ra,0xffffe
    80002bda:	f22080e7          	jalr	-222(ra) # 80000af8 <kfree>
      p->killed = 1;
    80002bde:	4785                	li	a5,1
    80002be0:	02f9a423          	sw	a5,40(s3)
      exit(-1);
    80002be4:	557d                	li	a0,-1
    80002be6:	00000097          	auipc	ra,0x0
    80002bea:	958080e7          	jalr	-1704(ra) # 8000253e <exit>
    80002bee:	b561                	j	80002a76 <usertrap+0x66>
      p->killed = 1;
    80002bf0:	4785                	li	a5,1
    80002bf2:	02f9a423          	sw	a5,40(s3)
      exit(-1);
    80002bf6:	557d                	li	a0,-1
    80002bf8:	00000097          	auipc	ra,0x0
    80002bfc:	946080e7          	jalr	-1722(ra) # 8000253e <exit>
    80002c00:	bfad                	j	80002b7a <usertrap+0x16a>
    if(paddr == 0) p->killed = 1;
    80002c02:	4785                	li	a5,1
    80002c04:	02f9a423          	sw	a5,40(s3)
    80002c08:	b779                	j	80002b96 <usertrap+0x186>
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c0a:	142025f3          	csrr	a1,scause
    printf("usertrap(): unexpected scause %p pid=%d\n", r_scause(), p->pid);
    80002c0e:	0309a603          	lw	a2,48(s3)
    80002c12:	00005517          	auipc	a0,0x5
    80002c16:	7fe50513          	addi	a0,a0,2046 # 80008410 <states.1712+0xe0>
    80002c1a:	ffffe097          	auipc	ra,0xffffe
    80002c1e:	96e080e7          	jalr	-1682(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c22:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002c26:	14302673          	csrr	a2,stval
    printf("            sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002c2a:	00006517          	auipc	a0,0x6
    80002c2e:	81650513          	addi	a0,a0,-2026 # 80008440 <states.1712+0x110>
    80002c32:	ffffe097          	auipc	ra,0xffffe
    80002c36:	956080e7          	jalr	-1706(ra) # 80000588 <printf>
    p->killed = 1;
    80002c3a:	4785                	li	a5,1
    80002c3c:	02f9a423          	sw	a5,40(s3)
  if(p->killed)
    80002c40:	a031                	j	80002c4c <usertrap+0x23c>
    80002c42:	0289a783          	lw	a5,40(s3)
    80002c46:	cb81                	beqz	a5,80002c56 <usertrap+0x246>
    80002c48:	a011                	j	80002c4c <usertrap+0x23c>
    80002c4a:	4481                	li	s1,0
    exit(-1);
    80002c4c:	557d                	li	a0,-1
    80002c4e:	00000097          	auipc	ra,0x0
    80002c52:	8f0080e7          	jalr	-1808(ra) # 8000253e <exit>
  if(which_dev == 2)
    80002c56:	4789                	li	a5,2
    80002c58:	e2f493e3          	bne	s1,a5,80002a7e <usertrap+0x6e>
    yield();
    80002c5c:	fffff097          	auipc	ra,0xfffff
    80002c60:	64a080e7          	jalr	1610(ra) # 800022a6 <yield>
    80002c64:	bd29                	j	80002a7e <usertrap+0x6e>

0000000080002c66 <kerneltrap>:
{
    80002c66:	7179                	addi	sp,sp,-48
    80002c68:	f406                	sd	ra,40(sp)
    80002c6a:	f022                	sd	s0,32(sp)
    80002c6c:	ec26                	sd	s1,24(sp)
    80002c6e:	e84a                	sd	s2,16(sp)
    80002c70:	e44e                	sd	s3,8(sp)
    80002c72:	1800                	addi	s0,sp,48
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002c74:	14102973          	csrr	s2,sepc
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c78:	100024f3          	csrr	s1,sstatus
  asm volatile("csrr %0, scause" : "=r" (x) );
    80002c7c:	142029f3          	csrr	s3,scause
  if((sstatus & SSTATUS_SPP) == 0)
    80002c80:	1004f793          	andi	a5,s1,256
    80002c84:	cb85                	beqz	a5,80002cb4 <kerneltrap+0x4e>
  asm volatile("csrr %0, sstatus" : "=r" (x) );
    80002c86:	100027f3          	csrr	a5,sstatus
  return (x & SSTATUS_SIE) != 0;
    80002c8a:	8b89                	andi	a5,a5,2
  if(intr_get() != 0)
    80002c8c:	ef85                	bnez	a5,80002cc4 <kerneltrap+0x5e>
  if((which_dev = devintr()) == 0){
    80002c8e:	00000097          	auipc	ra,0x0
    80002c92:	ce0080e7          	jalr	-800(ra) # 8000296e <devintr>
    80002c96:	cd1d                	beqz	a0,80002cd4 <kerneltrap+0x6e>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002c98:	4789                	li	a5,2
    80002c9a:	06f50a63          	beq	a0,a5,80002d0e <kerneltrap+0xa8>
  asm volatile("csrw sepc, %0" : : "r" (x));
    80002c9e:	14191073          	csrw	sepc,s2
  asm volatile("csrw sstatus, %0" : : "r" (x));
    80002ca2:	10049073          	csrw	sstatus,s1
}
    80002ca6:	70a2                	ld	ra,40(sp)
    80002ca8:	7402                	ld	s0,32(sp)
    80002caa:	64e2                	ld	s1,24(sp)
    80002cac:	6942                	ld	s2,16(sp)
    80002cae:	69a2                	ld	s3,8(sp)
    80002cb0:	6145                	addi	sp,sp,48
    80002cb2:	8082                	ret
    panic("kerneltrap: not from supervisor mode");
    80002cb4:	00005517          	auipc	a0,0x5
    80002cb8:	7ac50513          	addi	a0,a0,1964 # 80008460 <states.1712+0x130>
    80002cbc:	ffffe097          	auipc	ra,0xffffe
    80002cc0:	882080e7          	jalr	-1918(ra) # 8000053e <panic>
    panic("kerneltrap: interrupts enabled");
    80002cc4:	00005517          	auipc	a0,0x5
    80002cc8:	7c450513          	addi	a0,a0,1988 # 80008488 <states.1712+0x158>
    80002ccc:	ffffe097          	auipc	ra,0xffffe
    80002cd0:	872080e7          	jalr	-1934(ra) # 8000053e <panic>
    printf("scause %p\n", scause);
    80002cd4:	85ce                	mv	a1,s3
    80002cd6:	00005517          	auipc	a0,0x5
    80002cda:	7d250513          	addi	a0,a0,2002 # 800084a8 <states.1712+0x178>
    80002cde:	ffffe097          	auipc	ra,0xffffe
    80002ce2:	8aa080e7          	jalr	-1878(ra) # 80000588 <printf>
  asm volatile("csrr %0, sepc" : "=r" (x) );
    80002ce6:	141025f3          	csrr	a1,sepc
  asm volatile("csrr %0, stval" : "=r" (x) );
    80002cea:	14302673          	csrr	a2,stval
    printf("sepc=%p stval=%p\n", r_sepc(), r_stval());
    80002cee:	00005517          	auipc	a0,0x5
    80002cf2:	7ca50513          	addi	a0,a0,1994 # 800084b8 <states.1712+0x188>
    80002cf6:	ffffe097          	auipc	ra,0xffffe
    80002cfa:	892080e7          	jalr	-1902(ra) # 80000588 <printf>
    panic("kerneltrap");
    80002cfe:	00005517          	auipc	a0,0x5
    80002d02:	7d250513          	addi	a0,a0,2002 # 800084d0 <states.1712+0x1a0>
    80002d06:	ffffe097          	auipc	ra,0xffffe
    80002d0a:	838080e7          	jalr	-1992(ra) # 8000053e <panic>
  if(which_dev == 2 && myproc() != 0 && myproc()->state == RUNNING)
    80002d0e:	fffff097          	auipc	ra,0xfffff
    80002d12:	f0c080e7          	jalr	-244(ra) # 80001c1a <myproc>
    80002d16:	d541                	beqz	a0,80002c9e <kerneltrap+0x38>
    80002d18:	fffff097          	auipc	ra,0xfffff
    80002d1c:	f02080e7          	jalr	-254(ra) # 80001c1a <myproc>
    80002d20:	4d18                	lw	a4,24(a0)
    80002d22:	4791                	li	a5,4
    80002d24:	f6f71de3          	bne	a4,a5,80002c9e <kerneltrap+0x38>
    yield();
    80002d28:	fffff097          	auipc	ra,0xfffff
    80002d2c:	57e080e7          	jalr	1406(ra) # 800022a6 <yield>
    80002d30:	b7bd                	j	80002c9e <kerneltrap+0x38>

0000000080002d32 <argraw>:
  return strlen(buf);
}

static uint64
argraw(int n)
{
    80002d32:	1101                	addi	sp,sp,-32
    80002d34:	ec06                	sd	ra,24(sp)
    80002d36:	e822                	sd	s0,16(sp)
    80002d38:	e426                	sd	s1,8(sp)
    80002d3a:	1000                	addi	s0,sp,32
    80002d3c:	84aa                	mv	s1,a0
  struct proc *p = myproc();
    80002d3e:	fffff097          	auipc	ra,0xfffff
    80002d42:	edc080e7          	jalr	-292(ra) # 80001c1a <myproc>
  switch (n) {
    80002d46:	4795                	li	a5,5
    80002d48:	0497e163          	bltu	a5,s1,80002d8a <argraw+0x58>
    80002d4c:	048a                	slli	s1,s1,0x2
    80002d4e:	00005717          	auipc	a4,0x5
    80002d52:	7ba70713          	addi	a4,a4,1978 # 80008508 <states.1712+0x1d8>
    80002d56:	94ba                	add	s1,s1,a4
    80002d58:	409c                	lw	a5,0(s1)
    80002d5a:	97ba                	add	a5,a5,a4
    80002d5c:	8782                	jr	a5
  case 0:
    return p->trapframe->a0;
    80002d5e:	6d3c                	ld	a5,88(a0)
    80002d60:	7ba8                	ld	a0,112(a5)
  case 5:
    return p->trapframe->a5;
  }
  panic("argraw");
  return -1;
}
    80002d62:	60e2                	ld	ra,24(sp)
    80002d64:	6442                	ld	s0,16(sp)
    80002d66:	64a2                	ld	s1,8(sp)
    80002d68:	6105                	addi	sp,sp,32
    80002d6a:	8082                	ret
    return p->trapframe->a1;
    80002d6c:	6d3c                	ld	a5,88(a0)
    80002d6e:	7fa8                	ld	a0,120(a5)
    80002d70:	bfcd                	j	80002d62 <argraw+0x30>
    return p->trapframe->a2;
    80002d72:	6d3c                	ld	a5,88(a0)
    80002d74:	63c8                	ld	a0,128(a5)
    80002d76:	b7f5                	j	80002d62 <argraw+0x30>
    return p->trapframe->a3;
    80002d78:	6d3c                	ld	a5,88(a0)
    80002d7a:	67c8                	ld	a0,136(a5)
    80002d7c:	b7dd                	j	80002d62 <argraw+0x30>
    return p->trapframe->a4;
    80002d7e:	6d3c                	ld	a5,88(a0)
    80002d80:	6bc8                	ld	a0,144(a5)
    80002d82:	b7c5                	j	80002d62 <argraw+0x30>
    return p->trapframe->a5;
    80002d84:	6d3c                	ld	a5,88(a0)
    80002d86:	6fc8                	ld	a0,152(a5)
    80002d88:	bfe9                	j	80002d62 <argraw+0x30>
  panic("argraw");
    80002d8a:	00005517          	auipc	a0,0x5
    80002d8e:	75650513          	addi	a0,a0,1878 # 800084e0 <states.1712+0x1b0>
    80002d92:	ffffd097          	auipc	ra,0xffffd
    80002d96:	7ac080e7          	jalr	1964(ra) # 8000053e <panic>

0000000080002d9a <fetchaddr>:
{
    80002d9a:	1101                	addi	sp,sp,-32
    80002d9c:	ec06                	sd	ra,24(sp)
    80002d9e:	e822                	sd	s0,16(sp)
    80002da0:	e426                	sd	s1,8(sp)
    80002da2:	e04a                	sd	s2,0(sp)
    80002da4:	1000                	addi	s0,sp,32
    80002da6:	84aa                	mv	s1,a0
    80002da8:	892e                	mv	s2,a1
  struct proc *p = myproc();
    80002daa:	fffff097          	auipc	ra,0xfffff
    80002dae:	e70080e7          	jalr	-400(ra) # 80001c1a <myproc>
  if(addr >= p->sz || addr+sizeof(uint64) > p->sz)
    80002db2:	653c                	ld	a5,72(a0)
    80002db4:	02f4f863          	bgeu	s1,a5,80002de4 <fetchaddr+0x4a>
    80002db8:	00848713          	addi	a4,s1,8
    80002dbc:	02e7e663          	bltu	a5,a4,80002de8 <fetchaddr+0x4e>
  if(copyin(p->pagetable, (char *)ip, addr, sizeof(*ip)) != 0)
    80002dc0:	46a1                	li	a3,8
    80002dc2:	8626                	mv	a2,s1
    80002dc4:	85ca                	mv	a1,s2
    80002dc6:	6928                	ld	a0,80(a0)
    80002dc8:	fffff097          	auipc	ra,0xfffff
    80002dcc:	ba0080e7          	jalr	-1120(ra) # 80001968 <copyin>
    80002dd0:	00a03533          	snez	a0,a0
    80002dd4:	40a00533          	neg	a0,a0
}
    80002dd8:	60e2                	ld	ra,24(sp)
    80002dda:	6442                	ld	s0,16(sp)
    80002ddc:	64a2                	ld	s1,8(sp)
    80002dde:	6902                	ld	s2,0(sp)
    80002de0:	6105                	addi	sp,sp,32
    80002de2:	8082                	ret
    return -1;
    80002de4:	557d                	li	a0,-1
    80002de6:	bfcd                	j	80002dd8 <fetchaddr+0x3e>
    80002de8:	557d                	li	a0,-1
    80002dea:	b7fd                	j	80002dd8 <fetchaddr+0x3e>

0000000080002dec <fetchstr>:
{
    80002dec:	7179                	addi	sp,sp,-48
    80002dee:	f406                	sd	ra,40(sp)
    80002df0:	f022                	sd	s0,32(sp)
    80002df2:	ec26                	sd	s1,24(sp)
    80002df4:	e84a                	sd	s2,16(sp)
    80002df6:	e44e                	sd	s3,8(sp)
    80002df8:	1800                	addi	s0,sp,48
    80002dfa:	892a                	mv	s2,a0
    80002dfc:	84ae                	mv	s1,a1
    80002dfe:	89b2                	mv	s3,a2
  struct proc *p = myproc();
    80002e00:	fffff097          	auipc	ra,0xfffff
    80002e04:	e1a080e7          	jalr	-486(ra) # 80001c1a <myproc>
  int err = copyinstr(p->pagetable, buf, addr, max);
    80002e08:	86ce                	mv	a3,s3
    80002e0a:	864a                	mv	a2,s2
    80002e0c:	85a6                	mv	a1,s1
    80002e0e:	6928                	ld	a0,80(a0)
    80002e10:	fffff097          	auipc	ra,0xfffff
    80002e14:	be4080e7          	jalr	-1052(ra) # 800019f4 <copyinstr>
  if(err < 0)
    80002e18:	00054763          	bltz	a0,80002e26 <fetchstr+0x3a>
  return strlen(buf);
    80002e1c:	8526                	mv	a0,s1
    80002e1e:	ffffe097          	auipc	ra,0xffffe
    80002e22:	2b0080e7          	jalr	688(ra) # 800010ce <strlen>
}
    80002e26:	70a2                	ld	ra,40(sp)
    80002e28:	7402                	ld	s0,32(sp)
    80002e2a:	64e2                	ld	s1,24(sp)
    80002e2c:	6942                	ld	s2,16(sp)
    80002e2e:	69a2                	ld	s3,8(sp)
    80002e30:	6145                	addi	sp,sp,48
    80002e32:	8082                	ret

0000000080002e34 <argint>:

// Fetch the nth 32-bit system call argument.
int
argint(int n, int *ip)
{
    80002e34:	1101                	addi	sp,sp,-32
    80002e36:	ec06                	sd	ra,24(sp)
    80002e38:	e822                	sd	s0,16(sp)
    80002e3a:	e426                	sd	s1,8(sp)
    80002e3c:	1000                	addi	s0,sp,32
    80002e3e:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e40:	00000097          	auipc	ra,0x0
    80002e44:	ef2080e7          	jalr	-270(ra) # 80002d32 <argraw>
    80002e48:	c088                	sw	a0,0(s1)
  return 0;
}
    80002e4a:	4501                	li	a0,0
    80002e4c:	60e2                	ld	ra,24(sp)
    80002e4e:	6442                	ld	s0,16(sp)
    80002e50:	64a2                	ld	s1,8(sp)
    80002e52:	6105                	addi	sp,sp,32
    80002e54:	8082                	ret

0000000080002e56 <argaddr>:
// Retrieve an argument as a pointer.
// Doesn't check for legality, since
// copyin/copyout will do that.
int
argaddr(int n, uint64 *ip)
{
    80002e56:	1101                	addi	sp,sp,-32
    80002e58:	ec06                	sd	ra,24(sp)
    80002e5a:	e822                	sd	s0,16(sp)
    80002e5c:	e426                	sd	s1,8(sp)
    80002e5e:	1000                	addi	s0,sp,32
    80002e60:	84ae                	mv	s1,a1
  *ip = argraw(n);
    80002e62:	00000097          	auipc	ra,0x0
    80002e66:	ed0080e7          	jalr	-304(ra) # 80002d32 <argraw>
    80002e6a:	e088                	sd	a0,0(s1)
  return 0;
}
    80002e6c:	4501                	li	a0,0
    80002e6e:	60e2                	ld	ra,24(sp)
    80002e70:	6442                	ld	s0,16(sp)
    80002e72:	64a2                	ld	s1,8(sp)
    80002e74:	6105                	addi	sp,sp,32
    80002e76:	8082                	ret

0000000080002e78 <argstr>:
// Fetch the nth word-sized system call argument as a null-terminated string.
// Copies into buf, at most max.
// Returns string length if OK (including nul), -1 if error.
int
argstr(int n, char *buf, int max)
{
    80002e78:	1101                	addi	sp,sp,-32
    80002e7a:	ec06                	sd	ra,24(sp)
    80002e7c:	e822                	sd	s0,16(sp)
    80002e7e:	e426                	sd	s1,8(sp)
    80002e80:	e04a                	sd	s2,0(sp)
    80002e82:	1000                	addi	s0,sp,32
    80002e84:	84ae                	mv	s1,a1
    80002e86:	8932                	mv	s2,a2
  *ip = argraw(n);
    80002e88:	00000097          	auipc	ra,0x0
    80002e8c:	eaa080e7          	jalr	-342(ra) # 80002d32 <argraw>
  uint64 addr;
  if(argaddr(n, &addr) < 0)
    return -1;
  return fetchstr(addr, buf, max);
    80002e90:	864a                	mv	a2,s2
    80002e92:	85a6                	mv	a1,s1
    80002e94:	00000097          	auipc	ra,0x0
    80002e98:	f58080e7          	jalr	-168(ra) # 80002dec <fetchstr>
}
    80002e9c:	60e2                	ld	ra,24(sp)
    80002e9e:	6442                	ld	s0,16(sp)
    80002ea0:	64a2                	ld	s1,8(sp)
    80002ea2:	6902                	ld	s2,0(sp)
    80002ea4:	6105                	addi	sp,sp,32
    80002ea6:	8082                	ret

0000000080002ea8 <syscall>:
[SYS_munmap]   sys_munmap,
};

void
syscall(void)
{
    80002ea8:	1101                	addi	sp,sp,-32
    80002eaa:	ec06                	sd	ra,24(sp)
    80002eac:	e822                	sd	s0,16(sp)
    80002eae:	e426                	sd	s1,8(sp)
    80002eb0:	e04a                	sd	s2,0(sp)
    80002eb2:	1000                	addi	s0,sp,32
  int num;
  struct proc *p = myproc();
    80002eb4:	fffff097          	auipc	ra,0xfffff
    80002eb8:	d66080e7          	jalr	-666(ra) # 80001c1a <myproc>
    80002ebc:	84aa                	mv	s1,a0

  num = p->trapframe->a7;
    80002ebe:	05853903          	ld	s2,88(a0)
    80002ec2:	0a893783          	ld	a5,168(s2)
    80002ec6:	0007869b          	sext.w	a3,a5
  if(num > 0 && num < NELEM(syscalls) && syscalls[num]) {
    80002eca:	37fd                	addiw	a5,a5,-1
    80002ecc:	4759                	li	a4,22
    80002ece:	00f76f63          	bltu	a4,a5,80002eec <syscall+0x44>
    80002ed2:	00369713          	slli	a4,a3,0x3
    80002ed6:	00005797          	auipc	a5,0x5
    80002eda:	64a78793          	addi	a5,a5,1610 # 80008520 <syscalls>
    80002ede:	97ba                	add	a5,a5,a4
    80002ee0:	639c                	ld	a5,0(a5)
    80002ee2:	c789                	beqz	a5,80002eec <syscall+0x44>
    p->trapframe->a0 = syscalls[num]();
    80002ee4:	9782                	jalr	a5
    80002ee6:	06a93823          	sd	a0,112(s2)
    80002eea:	a839                	j	80002f08 <syscall+0x60>
  } else {
    printf("%d %s: unknown sys call %d\n",
    80002eec:	15848613          	addi	a2,s1,344
    80002ef0:	588c                	lw	a1,48(s1)
    80002ef2:	00005517          	auipc	a0,0x5
    80002ef6:	5f650513          	addi	a0,a0,1526 # 800084e8 <states.1712+0x1b8>
    80002efa:	ffffd097          	auipc	ra,0xffffd
    80002efe:	68e080e7          	jalr	1678(ra) # 80000588 <printf>
            p->pid, p->name, num);
    p->trapframe->a0 = -1;
    80002f02:	6cbc                	ld	a5,88(s1)
    80002f04:	577d                	li	a4,-1
    80002f06:	fbb8                	sd	a4,112(a5)
  }
}
    80002f08:	60e2                	ld	ra,24(sp)
    80002f0a:	6442                	ld	s0,16(sp)
    80002f0c:	64a2                	ld	s1,8(sp)
    80002f0e:	6902                	ld	s2,0(sp)
    80002f10:	6105                	addi	sp,sp,32
    80002f12:	8082                	ret

0000000080002f14 <sys_exit>:
#include "spinlock.h"
#include "proc.h"

uint64
sys_exit(void)
{
    80002f14:	1101                	addi	sp,sp,-32
    80002f16:	ec06                	sd	ra,24(sp)
    80002f18:	e822                	sd	s0,16(sp)
    80002f1a:	1000                	addi	s0,sp,32
  int n;
  if(argint(0, &n) < 0)
    80002f1c:	fec40593          	addi	a1,s0,-20
    80002f20:	4501                	li	a0,0
    80002f22:	00000097          	auipc	ra,0x0
    80002f26:	f12080e7          	jalr	-238(ra) # 80002e34 <argint>
    return -1;
    80002f2a:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80002f2c:	00054963          	bltz	a0,80002f3e <sys_exit+0x2a>
  exit(n);
    80002f30:	fec42503          	lw	a0,-20(s0)
    80002f34:	fffff097          	auipc	ra,0xfffff
    80002f38:	60a080e7          	jalr	1546(ra) # 8000253e <exit>
  return 0;  // not reached
    80002f3c:	4781                	li	a5,0
}
    80002f3e:	853e                	mv	a0,a5
    80002f40:	60e2                	ld	ra,24(sp)
    80002f42:	6442                	ld	s0,16(sp)
    80002f44:	6105                	addi	sp,sp,32
    80002f46:	8082                	ret

0000000080002f48 <sys_getpid>:

uint64
sys_getpid(void)
{
    80002f48:	1141                	addi	sp,sp,-16
    80002f4a:	e406                	sd	ra,8(sp)
    80002f4c:	e022                	sd	s0,0(sp)
    80002f4e:	0800                	addi	s0,sp,16
  return myproc()->pid;
    80002f50:	fffff097          	auipc	ra,0xfffff
    80002f54:	cca080e7          	jalr	-822(ra) # 80001c1a <myproc>
}
    80002f58:	5908                	lw	a0,48(a0)
    80002f5a:	60a2                	ld	ra,8(sp)
    80002f5c:	6402                	ld	s0,0(sp)
    80002f5e:	0141                	addi	sp,sp,16
    80002f60:	8082                	ret

0000000080002f62 <sys_fork>:

uint64
sys_fork(void)
{
    80002f62:	1141                	addi	sp,sp,-16
    80002f64:	e406                	sd	ra,8(sp)
    80002f66:	e022                	sd	s0,0(sp)
    80002f68:	0800                	addi	s0,sp,16
  return fork();
    80002f6a:	fffff097          	auipc	ra,0xfffff
    80002f6e:	082080e7          	jalr	130(ra) # 80001fec <fork>
}
    80002f72:	60a2                	ld	ra,8(sp)
    80002f74:	6402                	ld	s0,0(sp)
    80002f76:	0141                	addi	sp,sp,16
    80002f78:	8082                	ret

0000000080002f7a <sys_wait>:

uint64
sys_wait(void)
{
    80002f7a:	1101                	addi	sp,sp,-32
    80002f7c:	ec06                	sd	ra,24(sp)
    80002f7e:	e822                	sd	s0,16(sp)
    80002f80:	1000                	addi	s0,sp,32
  uint64 p;
  if(argaddr(0, &p) < 0)
    80002f82:	fe840593          	addi	a1,s0,-24
    80002f86:	4501                	li	a0,0
    80002f88:	00000097          	auipc	ra,0x0
    80002f8c:	ece080e7          	jalr	-306(ra) # 80002e56 <argaddr>
    80002f90:	87aa                	mv	a5,a0
    return -1;
    80002f92:	557d                	li	a0,-1
  if(argaddr(0, &p) < 0)
    80002f94:	0007c863          	bltz	a5,80002fa4 <sys_wait+0x2a>
  return wait(p);
    80002f98:	fe843503          	ld	a0,-24(s0)
    80002f9c:	fffff097          	auipc	ra,0xfffff
    80002fa0:	3aa080e7          	jalr	938(ra) # 80002346 <wait>
}
    80002fa4:	60e2                	ld	ra,24(sp)
    80002fa6:	6442                	ld	s0,16(sp)
    80002fa8:	6105                	addi	sp,sp,32
    80002faa:	8082                	ret

0000000080002fac <sys_sbrk>:

uint64
sys_sbrk(void)
{
    80002fac:	7179                	addi	sp,sp,-48
    80002fae:	f406                	sd	ra,40(sp)
    80002fb0:	f022                	sd	s0,32(sp)
    80002fb2:	ec26                	sd	s1,24(sp)
    80002fb4:	1800                	addi	s0,sp,48
  int addr;
  int n;

  if(argint(0, &n) < 0)
    80002fb6:	fdc40593          	addi	a1,s0,-36
    80002fba:	4501                	li	a0,0
    80002fbc:	00000097          	auipc	ra,0x0
    80002fc0:	e78080e7          	jalr	-392(ra) # 80002e34 <argint>
    80002fc4:	87aa                	mv	a5,a0
    return -1;
    80002fc6:	557d                	li	a0,-1
  if(argint(0, &n) < 0)
    80002fc8:	0207c063          	bltz	a5,80002fe8 <sys_sbrk+0x3c>
  addr = myproc()->sz;
    80002fcc:	fffff097          	auipc	ra,0xfffff
    80002fd0:	c4e080e7          	jalr	-946(ra) # 80001c1a <myproc>
    80002fd4:	4524                	lw	s1,72(a0)
  if(growproc(n) < 0)
    80002fd6:	fdc42503          	lw	a0,-36(s0)
    80002fda:	fffff097          	auipc	ra,0xfffff
    80002fde:	f9e080e7          	jalr	-98(ra) # 80001f78 <growproc>
    80002fe2:	00054863          	bltz	a0,80002ff2 <sys_sbrk+0x46>
    return -1;
  return addr;
    80002fe6:	8526                	mv	a0,s1
}
    80002fe8:	70a2                	ld	ra,40(sp)
    80002fea:	7402                	ld	s0,32(sp)
    80002fec:	64e2                	ld	s1,24(sp)
    80002fee:	6145                	addi	sp,sp,48
    80002ff0:	8082                	ret
    return -1;
    80002ff2:	557d                	li	a0,-1
    80002ff4:	bfd5                	j	80002fe8 <sys_sbrk+0x3c>

0000000080002ff6 <sys_sleep>:

uint64
sys_sleep(void)
{
    80002ff6:	7139                	addi	sp,sp,-64
    80002ff8:	fc06                	sd	ra,56(sp)
    80002ffa:	f822                	sd	s0,48(sp)
    80002ffc:	f426                	sd	s1,40(sp)
    80002ffe:	f04a                	sd	s2,32(sp)
    80003000:	ec4e                	sd	s3,24(sp)
    80003002:	0080                	addi	s0,sp,64
  int n;
  uint ticks0;

  if(argint(0, &n) < 0)
    80003004:	fcc40593          	addi	a1,s0,-52
    80003008:	4501                	li	a0,0
    8000300a:	00000097          	auipc	ra,0x0
    8000300e:	e2a080e7          	jalr	-470(ra) # 80002e34 <argint>
    return -1;
    80003012:	57fd                	li	a5,-1
  if(argint(0, &n) < 0)
    80003014:	06054563          	bltz	a0,8000307e <sys_sleep+0x88>
  acquire(&tickslock);
    80003018:	00894517          	auipc	a0,0x894
    8000301c:	4b850513          	addi	a0,a0,1208 # 808974d0 <tickslock>
    80003020:	ffffe097          	auipc	ra,0xffffe
    80003024:	e2e080e7          	jalr	-466(ra) # 80000e4e <acquire>
  ticks0 = ticks;
    80003028:	00006917          	auipc	s2,0x6
    8000302c:	00892903          	lw	s2,8(s2) # 80009030 <ticks>
  while(ticks - ticks0 < n){
    80003030:	fcc42783          	lw	a5,-52(s0)
    80003034:	cf85                	beqz	a5,8000306c <sys_sleep+0x76>
    if(myproc()->killed){
      release(&tickslock);
      return -1;
    }
    sleep(&ticks, &tickslock);
    80003036:	00894997          	auipc	s3,0x894
    8000303a:	49a98993          	addi	s3,s3,1178 # 808974d0 <tickslock>
    8000303e:	00006497          	auipc	s1,0x6
    80003042:	ff248493          	addi	s1,s1,-14 # 80009030 <ticks>
    if(myproc()->killed){
    80003046:	fffff097          	auipc	ra,0xfffff
    8000304a:	bd4080e7          	jalr	-1068(ra) # 80001c1a <myproc>
    8000304e:	551c                	lw	a5,40(a0)
    80003050:	ef9d                	bnez	a5,8000308e <sys_sleep+0x98>
    sleep(&ticks, &tickslock);
    80003052:	85ce                	mv	a1,s3
    80003054:	8526                	mv	a0,s1
    80003056:	fffff097          	auipc	ra,0xfffff
    8000305a:	28c080e7          	jalr	652(ra) # 800022e2 <sleep>
  while(ticks - ticks0 < n){
    8000305e:	409c                	lw	a5,0(s1)
    80003060:	412787bb          	subw	a5,a5,s2
    80003064:	fcc42703          	lw	a4,-52(s0)
    80003068:	fce7efe3          	bltu	a5,a4,80003046 <sys_sleep+0x50>
  }
  release(&tickslock);
    8000306c:	00894517          	auipc	a0,0x894
    80003070:	46450513          	addi	a0,a0,1124 # 808974d0 <tickslock>
    80003074:	ffffe097          	auipc	ra,0xffffe
    80003078:	e8e080e7          	jalr	-370(ra) # 80000f02 <release>
  return 0;
    8000307c:	4781                	li	a5,0
}
    8000307e:	853e                	mv	a0,a5
    80003080:	70e2                	ld	ra,56(sp)
    80003082:	7442                	ld	s0,48(sp)
    80003084:	74a2                	ld	s1,40(sp)
    80003086:	7902                	ld	s2,32(sp)
    80003088:	69e2                	ld	s3,24(sp)
    8000308a:	6121                	addi	sp,sp,64
    8000308c:	8082                	ret
      release(&tickslock);
    8000308e:	00894517          	auipc	a0,0x894
    80003092:	44250513          	addi	a0,a0,1090 # 808974d0 <tickslock>
    80003096:	ffffe097          	auipc	ra,0xffffe
    8000309a:	e6c080e7          	jalr	-404(ra) # 80000f02 <release>
      return -1;
    8000309e:	57fd                	li	a5,-1
    800030a0:	bff9                	j	8000307e <sys_sleep+0x88>

00000000800030a2 <sys_kill>:

uint64
sys_kill(void)
{
    800030a2:	1101                	addi	sp,sp,-32
    800030a4:	ec06                	sd	ra,24(sp)
    800030a6:	e822                	sd	s0,16(sp)
    800030a8:	1000                	addi	s0,sp,32
  int pid;

  if(argint(0, &pid) < 0)
    800030aa:	fec40593          	addi	a1,s0,-20
    800030ae:	4501                	li	a0,0
    800030b0:	00000097          	auipc	ra,0x0
    800030b4:	d84080e7          	jalr	-636(ra) # 80002e34 <argint>
    800030b8:	87aa                	mv	a5,a0
    return -1;
    800030ba:	557d                	li	a0,-1
  if(argint(0, &pid) < 0)
    800030bc:	0007c863          	bltz	a5,800030cc <sys_kill+0x2a>
  return kill(pid);
    800030c0:	fec42503          	lw	a0,-20(s0)
    800030c4:	fffff097          	auipc	ra,0xfffff
    800030c8:	550080e7          	jalr	1360(ra) # 80002614 <kill>
}
    800030cc:	60e2                	ld	ra,24(sp)
    800030ce:	6442                	ld	s0,16(sp)
    800030d0:	6105                	addi	sp,sp,32
    800030d2:	8082                	ret

00000000800030d4 <sys_uptime>:

// return how many clock tick interrupts have occurred
// since start.
uint64
sys_uptime(void)
{
    800030d4:	1101                	addi	sp,sp,-32
    800030d6:	ec06                	sd	ra,24(sp)
    800030d8:	e822                	sd	s0,16(sp)
    800030da:	e426                	sd	s1,8(sp)
    800030dc:	1000                	addi	s0,sp,32
  uint xticks;

  acquire(&tickslock);
    800030de:	00894517          	auipc	a0,0x894
    800030e2:	3f250513          	addi	a0,a0,1010 # 808974d0 <tickslock>
    800030e6:	ffffe097          	auipc	ra,0xffffe
    800030ea:	d68080e7          	jalr	-664(ra) # 80000e4e <acquire>
  xticks = ticks;
    800030ee:	00006497          	auipc	s1,0x6
    800030f2:	f424a483          	lw	s1,-190(s1) # 80009030 <ticks>
  release(&tickslock);
    800030f6:	00894517          	auipc	a0,0x894
    800030fa:	3da50513          	addi	a0,a0,986 # 808974d0 <tickslock>
    800030fe:	ffffe097          	auipc	ra,0xffffe
    80003102:	e04080e7          	jalr	-508(ra) # 80000f02 <release>
  return xticks;
    80003106:	02049513          	slli	a0,s1,0x20
    8000310a:	9101                	srli	a0,a0,0x20
    8000310c:	60e2                	ld	ra,24(sp)
    8000310e:	6442                	ld	s0,16(sp)
    80003110:	64a2                	ld	s1,8(sp)
    80003112:	6105                	addi	sp,sp,32
    80003114:	8082                	ret

0000000080003116 <binit>:
  struct buf head;
} bcache;

void
binit(void)
{
    80003116:	7179                	addi	sp,sp,-48
    80003118:	f406                	sd	ra,40(sp)
    8000311a:	f022                	sd	s0,32(sp)
    8000311c:	ec26                	sd	s1,24(sp)
    8000311e:	e84a                	sd	s2,16(sp)
    80003120:	e44e                	sd	s3,8(sp)
    80003122:	e052                	sd	s4,0(sp)
    80003124:	1800                	addi	s0,sp,48
  struct buf *b;

  initlock(&bcache.lock, "bcache");
    80003126:	00005597          	auipc	a1,0x5
    8000312a:	4ba58593          	addi	a1,a1,1210 # 800085e0 <syscalls+0xc0>
    8000312e:	00894517          	auipc	a0,0x894
    80003132:	3ba50513          	addi	a0,a0,954 # 808974e8 <bcache>
    80003136:	ffffe097          	auipc	ra,0xffffe
    8000313a:	c88080e7          	jalr	-888(ra) # 80000dbe <initlock>

  // Create linked list of buffers
  bcache.head.prev = &bcache.head;
    8000313e:	0089c797          	auipc	a5,0x89c
    80003142:	3aa78793          	addi	a5,a5,938 # 8089f4e8 <bcache+0x8000>
    80003146:	0089c717          	auipc	a4,0x89c
    8000314a:	60a70713          	addi	a4,a4,1546 # 8089f750 <bcache+0x8268>
    8000314e:	2ae7b823          	sd	a4,688(a5)
  bcache.head.next = &bcache.head;
    80003152:	2ae7bc23          	sd	a4,696(a5)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    80003156:	00894497          	auipc	s1,0x894
    8000315a:	3aa48493          	addi	s1,s1,938 # 80897500 <bcache+0x18>
    b->next = bcache.head.next;
    8000315e:	893e                	mv	s2,a5
    b->prev = &bcache.head;
    80003160:	89ba                	mv	s3,a4
    initsleeplock(&b->lock, "buffer");
    80003162:	00005a17          	auipc	s4,0x5
    80003166:	486a0a13          	addi	s4,s4,1158 # 800085e8 <syscalls+0xc8>
    b->next = bcache.head.next;
    8000316a:	2b893783          	ld	a5,696(s2)
    8000316e:	e8bc                	sd	a5,80(s1)
    b->prev = &bcache.head;
    80003170:	0534b423          	sd	s3,72(s1)
    initsleeplock(&b->lock, "buffer");
    80003174:	85d2                	mv	a1,s4
    80003176:	01048513          	addi	a0,s1,16
    8000317a:	00001097          	auipc	ra,0x1
    8000317e:	4bc080e7          	jalr	1212(ra) # 80004636 <initsleeplock>
    bcache.head.next->prev = b;
    80003182:	2b893783          	ld	a5,696(s2)
    80003186:	e7a4                	sd	s1,72(a5)
    bcache.head.next = b;
    80003188:	2a993c23          	sd	s1,696(s2)
  for(b = bcache.buf; b < bcache.buf+NBUF; b++){
    8000318c:	45848493          	addi	s1,s1,1112
    80003190:	fd349de3          	bne	s1,s3,8000316a <binit+0x54>
  }
}
    80003194:	70a2                	ld	ra,40(sp)
    80003196:	7402                	ld	s0,32(sp)
    80003198:	64e2                	ld	s1,24(sp)
    8000319a:	6942                	ld	s2,16(sp)
    8000319c:	69a2                	ld	s3,8(sp)
    8000319e:	6a02                	ld	s4,0(sp)
    800031a0:	6145                	addi	sp,sp,48
    800031a2:	8082                	ret

00000000800031a4 <bread>:
}

// Return a locked buf with the contents of the indicated block.
struct buf*
bread(uint dev, uint blockno)
{
    800031a4:	7179                	addi	sp,sp,-48
    800031a6:	f406                	sd	ra,40(sp)
    800031a8:	f022                	sd	s0,32(sp)
    800031aa:	ec26                	sd	s1,24(sp)
    800031ac:	e84a                	sd	s2,16(sp)
    800031ae:	e44e                	sd	s3,8(sp)
    800031b0:	1800                	addi	s0,sp,48
    800031b2:	89aa                	mv	s3,a0
    800031b4:	892e                	mv	s2,a1
  acquire(&bcache.lock);
    800031b6:	00894517          	auipc	a0,0x894
    800031ba:	33250513          	addi	a0,a0,818 # 808974e8 <bcache>
    800031be:	ffffe097          	auipc	ra,0xffffe
    800031c2:	c90080e7          	jalr	-880(ra) # 80000e4e <acquire>
  for(b = bcache.head.next; b != &bcache.head; b = b->next){
    800031c6:	0089c497          	auipc	s1,0x89c
    800031ca:	5da4b483          	ld	s1,1498(s1) # 8089f7a0 <bcache+0x82b8>
    800031ce:	0089c797          	auipc	a5,0x89c
    800031d2:	58278793          	addi	a5,a5,1410 # 8089f750 <bcache+0x8268>
    800031d6:	02f48f63          	beq	s1,a5,80003214 <bread+0x70>
    800031da:	873e                	mv	a4,a5
    800031dc:	a021                	j	800031e4 <bread+0x40>
    800031de:	68a4                	ld	s1,80(s1)
    800031e0:	02e48a63          	beq	s1,a4,80003214 <bread+0x70>
    if(b->dev == dev && b->blockno == blockno){
    800031e4:	449c                	lw	a5,8(s1)
    800031e6:	ff379ce3          	bne	a5,s3,800031de <bread+0x3a>
    800031ea:	44dc                	lw	a5,12(s1)
    800031ec:	ff2799e3          	bne	a5,s2,800031de <bread+0x3a>
      b->refcnt++;
    800031f0:	40bc                	lw	a5,64(s1)
    800031f2:	2785                	addiw	a5,a5,1
    800031f4:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    800031f6:	00894517          	auipc	a0,0x894
    800031fa:	2f250513          	addi	a0,a0,754 # 808974e8 <bcache>
    800031fe:	ffffe097          	auipc	ra,0xffffe
    80003202:	d04080e7          	jalr	-764(ra) # 80000f02 <release>
      acquiresleep(&b->lock);
    80003206:	01048513          	addi	a0,s1,16
    8000320a:	00001097          	auipc	ra,0x1
    8000320e:	466080e7          	jalr	1126(ra) # 80004670 <acquiresleep>
      return b;
    80003212:	a8b9                	j	80003270 <bread+0xcc>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    80003214:	0089c497          	auipc	s1,0x89c
    80003218:	5844b483          	ld	s1,1412(s1) # 8089f798 <bcache+0x82b0>
    8000321c:	0089c797          	auipc	a5,0x89c
    80003220:	53478793          	addi	a5,a5,1332 # 8089f750 <bcache+0x8268>
    80003224:	00f48863          	beq	s1,a5,80003234 <bread+0x90>
    80003228:	873e                	mv	a4,a5
    if(b->refcnt == 0) {
    8000322a:	40bc                	lw	a5,64(s1)
    8000322c:	cf81                	beqz	a5,80003244 <bread+0xa0>
  for(b = bcache.head.prev; b != &bcache.head; b = b->prev){
    8000322e:	64a4                	ld	s1,72(s1)
    80003230:	fee49de3          	bne	s1,a4,8000322a <bread+0x86>
  panic("bget: no buffers");
    80003234:	00005517          	auipc	a0,0x5
    80003238:	3bc50513          	addi	a0,a0,956 # 800085f0 <syscalls+0xd0>
    8000323c:	ffffd097          	auipc	ra,0xffffd
    80003240:	302080e7          	jalr	770(ra) # 8000053e <panic>
      b->dev = dev;
    80003244:	0134a423          	sw	s3,8(s1)
      b->blockno = blockno;
    80003248:	0124a623          	sw	s2,12(s1)
      b->valid = 0;
    8000324c:	0004a023          	sw	zero,0(s1)
      b->refcnt = 1;
    80003250:	4785                	li	a5,1
    80003252:	c0bc                	sw	a5,64(s1)
      release(&bcache.lock);
    80003254:	00894517          	auipc	a0,0x894
    80003258:	29450513          	addi	a0,a0,660 # 808974e8 <bcache>
    8000325c:	ffffe097          	auipc	ra,0xffffe
    80003260:	ca6080e7          	jalr	-858(ra) # 80000f02 <release>
      acquiresleep(&b->lock);
    80003264:	01048513          	addi	a0,s1,16
    80003268:	00001097          	auipc	ra,0x1
    8000326c:	408080e7          	jalr	1032(ra) # 80004670 <acquiresleep>
  struct buf *b;

  b = bget(dev, blockno);
  if(!b->valid) {
    80003270:	409c                	lw	a5,0(s1)
    80003272:	cb89                	beqz	a5,80003284 <bread+0xe0>
    virtio_disk_rw(b, 0);
    b->valid = 1;
  }
  return b;
}
    80003274:	8526                	mv	a0,s1
    80003276:	70a2                	ld	ra,40(sp)
    80003278:	7402                	ld	s0,32(sp)
    8000327a:	64e2                	ld	s1,24(sp)
    8000327c:	6942                	ld	s2,16(sp)
    8000327e:	69a2                	ld	s3,8(sp)
    80003280:	6145                	addi	sp,sp,48
    80003282:	8082                	ret
    virtio_disk_rw(b, 0);
    80003284:	4581                	li	a1,0
    80003286:	8526                	mv	a0,s1
    80003288:	00003097          	auipc	ra,0x3
    8000328c:	1be080e7          	jalr	446(ra) # 80006446 <virtio_disk_rw>
    b->valid = 1;
    80003290:	4785                	li	a5,1
    80003292:	c09c                	sw	a5,0(s1)
  return b;
    80003294:	b7c5                	j	80003274 <bread+0xd0>

0000000080003296 <bwrite>:

// Write b's contents to disk.  Must be locked.
void
bwrite(struct buf *b)
{
    80003296:	1101                	addi	sp,sp,-32
    80003298:	ec06                	sd	ra,24(sp)
    8000329a:	e822                	sd	s0,16(sp)
    8000329c:	e426                	sd	s1,8(sp)
    8000329e:	1000                	addi	s0,sp,32
    800032a0:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800032a2:	0541                	addi	a0,a0,16
    800032a4:	00001097          	auipc	ra,0x1
    800032a8:	466080e7          	jalr	1126(ra) # 8000470a <holdingsleep>
    800032ac:	cd01                	beqz	a0,800032c4 <bwrite+0x2e>
    panic("bwrite");
  virtio_disk_rw(b, 1);
    800032ae:	4585                	li	a1,1
    800032b0:	8526                	mv	a0,s1
    800032b2:	00003097          	auipc	ra,0x3
    800032b6:	194080e7          	jalr	404(ra) # 80006446 <virtio_disk_rw>
}
    800032ba:	60e2                	ld	ra,24(sp)
    800032bc:	6442                	ld	s0,16(sp)
    800032be:	64a2                	ld	s1,8(sp)
    800032c0:	6105                	addi	sp,sp,32
    800032c2:	8082                	ret
    panic("bwrite");
    800032c4:	00005517          	auipc	a0,0x5
    800032c8:	34450513          	addi	a0,a0,836 # 80008608 <syscalls+0xe8>
    800032cc:	ffffd097          	auipc	ra,0xffffd
    800032d0:	272080e7          	jalr	626(ra) # 8000053e <panic>

00000000800032d4 <brelse>:

// Release a locked buffer.
// Move to the head of the most-recently-used list.
void
brelse(struct buf *b)
{
    800032d4:	1101                	addi	sp,sp,-32
    800032d6:	ec06                	sd	ra,24(sp)
    800032d8:	e822                	sd	s0,16(sp)
    800032da:	e426                	sd	s1,8(sp)
    800032dc:	e04a                	sd	s2,0(sp)
    800032de:	1000                	addi	s0,sp,32
    800032e0:	84aa                	mv	s1,a0
  if(!holdingsleep(&b->lock))
    800032e2:	01050913          	addi	s2,a0,16
    800032e6:	854a                	mv	a0,s2
    800032e8:	00001097          	auipc	ra,0x1
    800032ec:	422080e7          	jalr	1058(ra) # 8000470a <holdingsleep>
    800032f0:	c92d                	beqz	a0,80003362 <brelse+0x8e>
    panic("brelse");

  releasesleep(&b->lock);
    800032f2:	854a                	mv	a0,s2
    800032f4:	00001097          	auipc	ra,0x1
    800032f8:	3d2080e7          	jalr	978(ra) # 800046c6 <releasesleep>

  acquire(&bcache.lock);
    800032fc:	00894517          	auipc	a0,0x894
    80003300:	1ec50513          	addi	a0,a0,492 # 808974e8 <bcache>
    80003304:	ffffe097          	auipc	ra,0xffffe
    80003308:	b4a080e7          	jalr	-1206(ra) # 80000e4e <acquire>
  b->refcnt--;
    8000330c:	40bc                	lw	a5,64(s1)
    8000330e:	37fd                	addiw	a5,a5,-1
    80003310:	0007871b          	sext.w	a4,a5
    80003314:	c0bc                	sw	a5,64(s1)
  if (b->refcnt == 0) {
    80003316:	eb05                	bnez	a4,80003346 <brelse+0x72>
    // no one is waiting for it.
    b->next->prev = b->prev;
    80003318:	68bc                	ld	a5,80(s1)
    8000331a:	64b8                	ld	a4,72(s1)
    8000331c:	e7b8                	sd	a4,72(a5)
    b->prev->next = b->next;
    8000331e:	64bc                	ld	a5,72(s1)
    80003320:	68b8                	ld	a4,80(s1)
    80003322:	ebb8                	sd	a4,80(a5)
    b->next = bcache.head.next;
    80003324:	0089c797          	auipc	a5,0x89c
    80003328:	1c478793          	addi	a5,a5,452 # 8089f4e8 <bcache+0x8000>
    8000332c:	2b87b703          	ld	a4,696(a5)
    80003330:	e8b8                	sd	a4,80(s1)
    b->prev = &bcache.head;
    80003332:	0089c717          	auipc	a4,0x89c
    80003336:	41e70713          	addi	a4,a4,1054 # 8089f750 <bcache+0x8268>
    8000333a:	e4b8                	sd	a4,72(s1)
    bcache.head.next->prev = b;
    8000333c:	2b87b703          	ld	a4,696(a5)
    80003340:	e724                	sd	s1,72(a4)
    bcache.head.next = b;
    80003342:	2a97bc23          	sd	s1,696(a5)
  }
  
  release(&bcache.lock);
    80003346:	00894517          	auipc	a0,0x894
    8000334a:	1a250513          	addi	a0,a0,418 # 808974e8 <bcache>
    8000334e:	ffffe097          	auipc	ra,0xffffe
    80003352:	bb4080e7          	jalr	-1100(ra) # 80000f02 <release>
}
    80003356:	60e2                	ld	ra,24(sp)
    80003358:	6442                	ld	s0,16(sp)
    8000335a:	64a2                	ld	s1,8(sp)
    8000335c:	6902                	ld	s2,0(sp)
    8000335e:	6105                	addi	sp,sp,32
    80003360:	8082                	ret
    panic("brelse");
    80003362:	00005517          	auipc	a0,0x5
    80003366:	2ae50513          	addi	a0,a0,686 # 80008610 <syscalls+0xf0>
    8000336a:	ffffd097          	auipc	ra,0xffffd
    8000336e:	1d4080e7          	jalr	468(ra) # 8000053e <panic>

0000000080003372 <bpin>:

void
bpin(struct buf *b) {
    80003372:	1101                	addi	sp,sp,-32
    80003374:	ec06                	sd	ra,24(sp)
    80003376:	e822                	sd	s0,16(sp)
    80003378:	e426                	sd	s1,8(sp)
    8000337a:	1000                	addi	s0,sp,32
    8000337c:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    8000337e:	00894517          	auipc	a0,0x894
    80003382:	16a50513          	addi	a0,a0,362 # 808974e8 <bcache>
    80003386:	ffffe097          	auipc	ra,0xffffe
    8000338a:	ac8080e7          	jalr	-1336(ra) # 80000e4e <acquire>
  b->refcnt++;
    8000338e:	40bc                	lw	a5,64(s1)
    80003390:	2785                	addiw	a5,a5,1
    80003392:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    80003394:	00894517          	auipc	a0,0x894
    80003398:	15450513          	addi	a0,a0,340 # 808974e8 <bcache>
    8000339c:	ffffe097          	auipc	ra,0xffffe
    800033a0:	b66080e7          	jalr	-1178(ra) # 80000f02 <release>
}
    800033a4:	60e2                	ld	ra,24(sp)
    800033a6:	6442                	ld	s0,16(sp)
    800033a8:	64a2                	ld	s1,8(sp)
    800033aa:	6105                	addi	sp,sp,32
    800033ac:	8082                	ret

00000000800033ae <bunpin>:

void
bunpin(struct buf *b) {
    800033ae:	1101                	addi	sp,sp,-32
    800033b0:	ec06                	sd	ra,24(sp)
    800033b2:	e822                	sd	s0,16(sp)
    800033b4:	e426                	sd	s1,8(sp)
    800033b6:	1000                	addi	s0,sp,32
    800033b8:	84aa                	mv	s1,a0
  acquire(&bcache.lock);
    800033ba:	00894517          	auipc	a0,0x894
    800033be:	12e50513          	addi	a0,a0,302 # 808974e8 <bcache>
    800033c2:	ffffe097          	auipc	ra,0xffffe
    800033c6:	a8c080e7          	jalr	-1396(ra) # 80000e4e <acquire>
  b->refcnt--;
    800033ca:	40bc                	lw	a5,64(s1)
    800033cc:	37fd                	addiw	a5,a5,-1
    800033ce:	c0bc                	sw	a5,64(s1)
  release(&bcache.lock);
    800033d0:	00894517          	auipc	a0,0x894
    800033d4:	11850513          	addi	a0,a0,280 # 808974e8 <bcache>
    800033d8:	ffffe097          	auipc	ra,0xffffe
    800033dc:	b2a080e7          	jalr	-1238(ra) # 80000f02 <release>
}
    800033e0:	60e2                	ld	ra,24(sp)
    800033e2:	6442                	ld	s0,16(sp)
    800033e4:	64a2                	ld	s1,8(sp)
    800033e6:	6105                	addi	sp,sp,32
    800033e8:	8082                	ret

00000000800033ea <bfree>:
}

// Free a disk block.
static void
bfree(int dev, uint b)
{
    800033ea:	1101                	addi	sp,sp,-32
    800033ec:	ec06                	sd	ra,24(sp)
    800033ee:	e822                	sd	s0,16(sp)
    800033f0:	e426                	sd	s1,8(sp)
    800033f2:	e04a                	sd	s2,0(sp)
    800033f4:	1000                	addi	s0,sp,32
    800033f6:	84ae                	mv	s1,a1
  struct buf *bp;
  int bi, m;

  bp = bread(dev, BBLOCK(b, sb));
    800033f8:	00d5d59b          	srliw	a1,a1,0xd
    800033fc:	0089c797          	auipc	a5,0x89c
    80003400:	7c87a783          	lw	a5,1992(a5) # 8089fbc4 <sb+0x1c>
    80003404:	9dbd                	addw	a1,a1,a5
    80003406:	00000097          	auipc	ra,0x0
    8000340a:	d9e080e7          	jalr	-610(ra) # 800031a4 <bread>
  bi = b % BPB;
  m = 1 << (bi % 8);
    8000340e:	0074f713          	andi	a4,s1,7
    80003412:	4785                	li	a5,1
    80003414:	00e797bb          	sllw	a5,a5,a4
  if((bp->data[bi/8] & m) == 0)
    80003418:	14ce                	slli	s1,s1,0x33
    8000341a:	90d9                	srli	s1,s1,0x36
    8000341c:	00950733          	add	a4,a0,s1
    80003420:	05874703          	lbu	a4,88(a4)
    80003424:	00e7f6b3          	and	a3,a5,a4
    80003428:	c69d                	beqz	a3,80003456 <bfree+0x6c>
    8000342a:	892a                	mv	s2,a0
    panic("freeing free block");
  bp->data[bi/8] &= ~m;
    8000342c:	94aa                	add	s1,s1,a0
    8000342e:	fff7c793          	not	a5,a5
    80003432:	8ff9                	and	a5,a5,a4
    80003434:	04f48c23          	sb	a5,88(s1)
  log_write(bp);
    80003438:	00001097          	auipc	ra,0x1
    8000343c:	118080e7          	jalr	280(ra) # 80004550 <log_write>
  brelse(bp);
    80003440:	854a                	mv	a0,s2
    80003442:	00000097          	auipc	ra,0x0
    80003446:	e92080e7          	jalr	-366(ra) # 800032d4 <brelse>
}
    8000344a:	60e2                	ld	ra,24(sp)
    8000344c:	6442                	ld	s0,16(sp)
    8000344e:	64a2                	ld	s1,8(sp)
    80003450:	6902                	ld	s2,0(sp)
    80003452:	6105                	addi	sp,sp,32
    80003454:	8082                	ret
    panic("freeing free block");
    80003456:	00005517          	auipc	a0,0x5
    8000345a:	1c250513          	addi	a0,a0,450 # 80008618 <syscalls+0xf8>
    8000345e:	ffffd097          	auipc	ra,0xffffd
    80003462:	0e0080e7          	jalr	224(ra) # 8000053e <panic>

0000000080003466 <balloc>:
{
    80003466:	711d                	addi	sp,sp,-96
    80003468:	ec86                	sd	ra,88(sp)
    8000346a:	e8a2                	sd	s0,80(sp)
    8000346c:	e4a6                	sd	s1,72(sp)
    8000346e:	e0ca                	sd	s2,64(sp)
    80003470:	fc4e                	sd	s3,56(sp)
    80003472:	f852                	sd	s4,48(sp)
    80003474:	f456                	sd	s5,40(sp)
    80003476:	f05a                	sd	s6,32(sp)
    80003478:	ec5e                	sd	s7,24(sp)
    8000347a:	e862                	sd	s8,16(sp)
    8000347c:	e466                	sd	s9,8(sp)
    8000347e:	1080                	addi	s0,sp,96
  for(b = 0; b < sb.size; b += BPB){
    80003480:	0089c797          	auipc	a5,0x89c
    80003484:	72c7a783          	lw	a5,1836(a5) # 8089fbac <sb+0x4>
    80003488:	cbd1                	beqz	a5,8000351c <balloc+0xb6>
    8000348a:	8baa                	mv	s7,a0
    8000348c:	4a81                	li	s5,0
    bp = bread(dev, BBLOCK(b, sb));
    8000348e:	0089cb17          	auipc	s6,0x89c
    80003492:	71ab0b13          	addi	s6,s6,1818 # 8089fba8 <sb>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003496:	4c01                	li	s8,0
      m = 1 << (bi % 8);
    80003498:	4985                	li	s3,1
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    8000349a:	6a09                	lui	s4,0x2
  for(b = 0; b < sb.size; b += BPB){
    8000349c:	6c89                	lui	s9,0x2
    8000349e:	a831                	j	800034ba <balloc+0x54>
    brelse(bp);
    800034a0:	854a                	mv	a0,s2
    800034a2:	00000097          	auipc	ra,0x0
    800034a6:	e32080e7          	jalr	-462(ra) # 800032d4 <brelse>
  for(b = 0; b < sb.size; b += BPB){
    800034aa:	015c87bb          	addw	a5,s9,s5
    800034ae:	00078a9b          	sext.w	s5,a5
    800034b2:	004b2703          	lw	a4,4(s6)
    800034b6:	06eaf363          	bgeu	s5,a4,8000351c <balloc+0xb6>
    bp = bread(dev, BBLOCK(b, sb));
    800034ba:	41fad79b          	sraiw	a5,s5,0x1f
    800034be:	0137d79b          	srliw	a5,a5,0x13
    800034c2:	015787bb          	addw	a5,a5,s5
    800034c6:	40d7d79b          	sraiw	a5,a5,0xd
    800034ca:	01cb2583          	lw	a1,28(s6)
    800034ce:	9dbd                	addw	a1,a1,a5
    800034d0:	855e                	mv	a0,s7
    800034d2:	00000097          	auipc	ra,0x0
    800034d6:	cd2080e7          	jalr	-814(ra) # 800031a4 <bread>
    800034da:	892a                	mv	s2,a0
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    800034dc:	004b2503          	lw	a0,4(s6)
    800034e0:	000a849b          	sext.w	s1,s5
    800034e4:	8662                	mv	a2,s8
    800034e6:	faa4fde3          	bgeu	s1,a0,800034a0 <balloc+0x3a>
      m = 1 << (bi % 8);
    800034ea:	41f6579b          	sraiw	a5,a2,0x1f
    800034ee:	01d7d69b          	srliw	a3,a5,0x1d
    800034f2:	00c6873b          	addw	a4,a3,a2
    800034f6:	00777793          	andi	a5,a4,7
    800034fa:	9f95                	subw	a5,a5,a3
    800034fc:	00f997bb          	sllw	a5,s3,a5
      if((bp->data[bi/8] & m) == 0){  // Is block free?
    80003500:	4037571b          	sraiw	a4,a4,0x3
    80003504:	00e906b3          	add	a3,s2,a4
    80003508:	0586c683          	lbu	a3,88(a3)
    8000350c:	00d7f5b3          	and	a1,a5,a3
    80003510:	cd91                	beqz	a1,8000352c <balloc+0xc6>
    for(bi = 0; bi < BPB && b + bi < sb.size; bi++){
    80003512:	2605                	addiw	a2,a2,1
    80003514:	2485                	addiw	s1,s1,1
    80003516:	fd4618e3          	bne	a2,s4,800034e6 <balloc+0x80>
    8000351a:	b759                	j	800034a0 <balloc+0x3a>
  panic("balloc: out of blocks");
    8000351c:	00005517          	auipc	a0,0x5
    80003520:	11450513          	addi	a0,a0,276 # 80008630 <syscalls+0x110>
    80003524:	ffffd097          	auipc	ra,0xffffd
    80003528:	01a080e7          	jalr	26(ra) # 8000053e <panic>
        bp->data[bi/8] |= m;  // Mark block in use.
    8000352c:	974a                	add	a4,a4,s2
    8000352e:	8fd5                	or	a5,a5,a3
    80003530:	04f70c23          	sb	a5,88(a4)
        log_write(bp);
    80003534:	854a                	mv	a0,s2
    80003536:	00001097          	auipc	ra,0x1
    8000353a:	01a080e7          	jalr	26(ra) # 80004550 <log_write>
        brelse(bp);
    8000353e:	854a                	mv	a0,s2
    80003540:	00000097          	auipc	ra,0x0
    80003544:	d94080e7          	jalr	-620(ra) # 800032d4 <brelse>
  bp = bread(dev, bno);
    80003548:	85a6                	mv	a1,s1
    8000354a:	855e                	mv	a0,s7
    8000354c:	00000097          	auipc	ra,0x0
    80003550:	c58080e7          	jalr	-936(ra) # 800031a4 <bread>
    80003554:	892a                	mv	s2,a0
  memset(bp->data, 0, BSIZE);
    80003556:	40000613          	li	a2,1024
    8000355a:	4581                	li	a1,0
    8000355c:	05850513          	addi	a0,a0,88
    80003560:	ffffe097          	auipc	ra,0xffffe
    80003564:	9ea080e7          	jalr	-1558(ra) # 80000f4a <memset>
  log_write(bp);
    80003568:	854a                	mv	a0,s2
    8000356a:	00001097          	auipc	ra,0x1
    8000356e:	fe6080e7          	jalr	-26(ra) # 80004550 <log_write>
  brelse(bp);
    80003572:	854a                	mv	a0,s2
    80003574:	00000097          	auipc	ra,0x0
    80003578:	d60080e7          	jalr	-672(ra) # 800032d4 <brelse>
}
    8000357c:	8526                	mv	a0,s1
    8000357e:	60e6                	ld	ra,88(sp)
    80003580:	6446                	ld	s0,80(sp)
    80003582:	64a6                	ld	s1,72(sp)
    80003584:	6906                	ld	s2,64(sp)
    80003586:	79e2                	ld	s3,56(sp)
    80003588:	7a42                	ld	s4,48(sp)
    8000358a:	7aa2                	ld	s5,40(sp)
    8000358c:	7b02                	ld	s6,32(sp)
    8000358e:	6be2                	ld	s7,24(sp)
    80003590:	6c42                	ld	s8,16(sp)
    80003592:	6ca2                	ld	s9,8(sp)
    80003594:	6125                	addi	sp,sp,96
    80003596:	8082                	ret

0000000080003598 <bmap>:

// Return the disk block address of the nth block in inode ip.
// If there is no such block, bmap allocates one.
static uint
bmap(struct inode *ip, uint bn)
{
    80003598:	7179                	addi	sp,sp,-48
    8000359a:	f406                	sd	ra,40(sp)
    8000359c:	f022                	sd	s0,32(sp)
    8000359e:	ec26                	sd	s1,24(sp)
    800035a0:	e84a                	sd	s2,16(sp)
    800035a2:	e44e                	sd	s3,8(sp)
    800035a4:	e052                	sd	s4,0(sp)
    800035a6:	1800                	addi	s0,sp,48
    800035a8:	892a                	mv	s2,a0
  uint addr, *a;
  struct buf *bp;

  if(bn < NDIRECT){
    800035aa:	47ad                	li	a5,11
    800035ac:	04b7fe63          	bgeu	a5,a1,80003608 <bmap+0x70>
    if((addr = ip->addrs[bn]) == 0)
      ip->addrs[bn] = addr = balloc(ip->dev);
    return addr;
  }
  bn -= NDIRECT;
    800035b0:	ff45849b          	addiw	s1,a1,-12
    800035b4:	0004871b          	sext.w	a4,s1

  if(bn < NINDIRECT){
    800035b8:	0ff00793          	li	a5,255
    800035bc:	0ae7e363          	bltu	a5,a4,80003662 <bmap+0xca>
    // Load indirect block, allocating if necessary.
    if((addr = ip->addrs[NDIRECT]) == 0)
    800035c0:	08052583          	lw	a1,128(a0)
    800035c4:	c5ad                	beqz	a1,8000362e <bmap+0x96>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    bp = bread(ip->dev, addr);
    800035c6:	00092503          	lw	a0,0(s2)
    800035ca:	00000097          	auipc	ra,0x0
    800035ce:	bda080e7          	jalr	-1062(ra) # 800031a4 <bread>
    800035d2:	8a2a                	mv	s4,a0
    a = (uint*)bp->data;
    800035d4:	05850793          	addi	a5,a0,88
    if((addr = a[bn]) == 0){
    800035d8:	02049593          	slli	a1,s1,0x20
    800035dc:	9181                	srli	a1,a1,0x20
    800035de:	058a                	slli	a1,a1,0x2
    800035e0:	00b784b3          	add	s1,a5,a1
    800035e4:	0004a983          	lw	s3,0(s1)
    800035e8:	04098d63          	beqz	s3,80003642 <bmap+0xaa>
      a[bn] = addr = balloc(ip->dev);
      log_write(bp);
    }
    brelse(bp);
    800035ec:	8552                	mv	a0,s4
    800035ee:	00000097          	auipc	ra,0x0
    800035f2:	ce6080e7          	jalr	-794(ra) # 800032d4 <brelse>
    return addr;
  }

  panic("bmap: out of range");
}
    800035f6:	854e                	mv	a0,s3
    800035f8:	70a2                	ld	ra,40(sp)
    800035fa:	7402                	ld	s0,32(sp)
    800035fc:	64e2                	ld	s1,24(sp)
    800035fe:	6942                	ld	s2,16(sp)
    80003600:	69a2                	ld	s3,8(sp)
    80003602:	6a02                	ld	s4,0(sp)
    80003604:	6145                	addi	sp,sp,48
    80003606:	8082                	ret
    if((addr = ip->addrs[bn]) == 0)
    80003608:	02059493          	slli	s1,a1,0x20
    8000360c:	9081                	srli	s1,s1,0x20
    8000360e:	048a                	slli	s1,s1,0x2
    80003610:	94aa                	add	s1,s1,a0
    80003612:	0504a983          	lw	s3,80(s1)
    80003616:	fe0990e3          	bnez	s3,800035f6 <bmap+0x5e>
      ip->addrs[bn] = addr = balloc(ip->dev);
    8000361a:	4108                	lw	a0,0(a0)
    8000361c:	00000097          	auipc	ra,0x0
    80003620:	e4a080e7          	jalr	-438(ra) # 80003466 <balloc>
    80003624:	0005099b          	sext.w	s3,a0
    80003628:	0534a823          	sw	s3,80(s1)
    8000362c:	b7e9                	j	800035f6 <bmap+0x5e>
      ip->addrs[NDIRECT] = addr = balloc(ip->dev);
    8000362e:	4108                	lw	a0,0(a0)
    80003630:	00000097          	auipc	ra,0x0
    80003634:	e36080e7          	jalr	-458(ra) # 80003466 <balloc>
    80003638:	0005059b          	sext.w	a1,a0
    8000363c:	08b92023          	sw	a1,128(s2)
    80003640:	b759                	j	800035c6 <bmap+0x2e>
      a[bn] = addr = balloc(ip->dev);
    80003642:	00092503          	lw	a0,0(s2)
    80003646:	00000097          	auipc	ra,0x0
    8000364a:	e20080e7          	jalr	-480(ra) # 80003466 <balloc>
    8000364e:	0005099b          	sext.w	s3,a0
    80003652:	0134a023          	sw	s3,0(s1)
      log_write(bp);
    80003656:	8552                	mv	a0,s4
    80003658:	00001097          	auipc	ra,0x1
    8000365c:	ef8080e7          	jalr	-264(ra) # 80004550 <log_write>
    80003660:	b771                	j	800035ec <bmap+0x54>
  panic("bmap: out of range");
    80003662:	00005517          	auipc	a0,0x5
    80003666:	fe650513          	addi	a0,a0,-26 # 80008648 <syscalls+0x128>
    8000366a:	ffffd097          	auipc	ra,0xffffd
    8000366e:	ed4080e7          	jalr	-300(ra) # 8000053e <panic>

0000000080003672 <iget>:
{
    80003672:	7179                	addi	sp,sp,-48
    80003674:	f406                	sd	ra,40(sp)
    80003676:	f022                	sd	s0,32(sp)
    80003678:	ec26                	sd	s1,24(sp)
    8000367a:	e84a                	sd	s2,16(sp)
    8000367c:	e44e                	sd	s3,8(sp)
    8000367e:	e052                	sd	s4,0(sp)
    80003680:	1800                	addi	s0,sp,48
    80003682:	89aa                	mv	s3,a0
    80003684:	8a2e                	mv	s4,a1
  acquire(&itable.lock);
    80003686:	0089c517          	auipc	a0,0x89c
    8000368a:	54250513          	addi	a0,a0,1346 # 8089fbc8 <itable>
    8000368e:	ffffd097          	auipc	ra,0xffffd
    80003692:	7c0080e7          	jalr	1984(ra) # 80000e4e <acquire>
  empty = 0;
    80003696:	4901                	li	s2,0
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    80003698:	0089c497          	auipc	s1,0x89c
    8000369c:	54848493          	addi	s1,s1,1352 # 8089fbe0 <itable+0x18>
    800036a0:	0089e697          	auipc	a3,0x89e
    800036a4:	fd068693          	addi	a3,a3,-48 # 808a1670 <log>
    800036a8:	a039                	j	800036b6 <iget+0x44>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800036aa:	02090b63          	beqz	s2,800036e0 <iget+0x6e>
  for(ip = &itable.inode[0]; ip < &itable.inode[NINODE]; ip++){
    800036ae:	08848493          	addi	s1,s1,136
    800036b2:	02d48a63          	beq	s1,a3,800036e6 <iget+0x74>
    if(ip->ref > 0 && ip->dev == dev && ip->inum == inum){
    800036b6:	449c                	lw	a5,8(s1)
    800036b8:	fef059e3          	blez	a5,800036aa <iget+0x38>
    800036bc:	4098                	lw	a4,0(s1)
    800036be:	ff3716e3          	bne	a4,s3,800036aa <iget+0x38>
    800036c2:	40d8                	lw	a4,4(s1)
    800036c4:	ff4713e3          	bne	a4,s4,800036aa <iget+0x38>
      ip->ref++;
    800036c8:	2785                	addiw	a5,a5,1
    800036ca:	c49c                	sw	a5,8(s1)
      release(&itable.lock);
    800036cc:	0089c517          	auipc	a0,0x89c
    800036d0:	4fc50513          	addi	a0,a0,1276 # 8089fbc8 <itable>
    800036d4:	ffffe097          	auipc	ra,0xffffe
    800036d8:	82e080e7          	jalr	-2002(ra) # 80000f02 <release>
      return ip;
    800036dc:	8926                	mv	s2,s1
    800036de:	a03d                	j	8000370c <iget+0x9a>
    if(empty == 0 && ip->ref == 0)    // Remember empty slot.
    800036e0:	f7f9                	bnez	a5,800036ae <iget+0x3c>
    800036e2:	8926                	mv	s2,s1
    800036e4:	b7e9                	j	800036ae <iget+0x3c>
  if(empty == 0)
    800036e6:	02090c63          	beqz	s2,8000371e <iget+0xac>
  ip->dev = dev;
    800036ea:	01392023          	sw	s3,0(s2)
  ip->inum = inum;
    800036ee:	01492223          	sw	s4,4(s2)
  ip->ref = 1;
    800036f2:	4785                	li	a5,1
    800036f4:	00f92423          	sw	a5,8(s2)
  ip->valid = 0;
    800036f8:	04092023          	sw	zero,64(s2)
  release(&itable.lock);
    800036fc:	0089c517          	auipc	a0,0x89c
    80003700:	4cc50513          	addi	a0,a0,1228 # 8089fbc8 <itable>
    80003704:	ffffd097          	auipc	ra,0xffffd
    80003708:	7fe080e7          	jalr	2046(ra) # 80000f02 <release>
}
    8000370c:	854a                	mv	a0,s2
    8000370e:	70a2                	ld	ra,40(sp)
    80003710:	7402                	ld	s0,32(sp)
    80003712:	64e2                	ld	s1,24(sp)
    80003714:	6942                	ld	s2,16(sp)
    80003716:	69a2                	ld	s3,8(sp)
    80003718:	6a02                	ld	s4,0(sp)
    8000371a:	6145                	addi	sp,sp,48
    8000371c:	8082                	ret
    panic("iget: no inodes");
    8000371e:	00005517          	auipc	a0,0x5
    80003722:	f4250513          	addi	a0,a0,-190 # 80008660 <syscalls+0x140>
    80003726:	ffffd097          	auipc	ra,0xffffd
    8000372a:	e18080e7          	jalr	-488(ra) # 8000053e <panic>

000000008000372e <fsinit>:
fsinit(int dev) {
    8000372e:	7179                	addi	sp,sp,-48
    80003730:	f406                	sd	ra,40(sp)
    80003732:	f022                	sd	s0,32(sp)
    80003734:	ec26                	sd	s1,24(sp)
    80003736:	e84a                	sd	s2,16(sp)
    80003738:	e44e                	sd	s3,8(sp)
    8000373a:	1800                	addi	s0,sp,48
    8000373c:	892a                	mv	s2,a0
  bp = bread(dev, 1);
    8000373e:	4585                	li	a1,1
    80003740:	00000097          	auipc	ra,0x0
    80003744:	a64080e7          	jalr	-1436(ra) # 800031a4 <bread>
    80003748:	84aa                	mv	s1,a0
  memmove(sb, bp->data, sizeof(*sb));
    8000374a:	0089c997          	auipc	s3,0x89c
    8000374e:	45e98993          	addi	s3,s3,1118 # 8089fba8 <sb>
    80003752:	02000613          	li	a2,32
    80003756:	05850593          	addi	a1,a0,88
    8000375a:	854e                	mv	a0,s3
    8000375c:	ffffe097          	auipc	ra,0xffffe
    80003760:	84e080e7          	jalr	-1970(ra) # 80000faa <memmove>
  brelse(bp);
    80003764:	8526                	mv	a0,s1
    80003766:	00000097          	auipc	ra,0x0
    8000376a:	b6e080e7          	jalr	-1170(ra) # 800032d4 <brelse>
  if(sb.magic != FSMAGIC)
    8000376e:	0009a703          	lw	a4,0(s3)
    80003772:	102037b7          	lui	a5,0x10203
    80003776:	04078793          	addi	a5,a5,64 # 10203040 <_entry-0x6fdfcfc0>
    8000377a:	02f71263          	bne	a4,a5,8000379e <fsinit+0x70>
  initlog(dev, &sb);
    8000377e:	0089c597          	auipc	a1,0x89c
    80003782:	42a58593          	addi	a1,a1,1066 # 8089fba8 <sb>
    80003786:	854a                	mv	a0,s2
    80003788:	00001097          	auipc	ra,0x1
    8000378c:	b4c080e7          	jalr	-1204(ra) # 800042d4 <initlog>
}
    80003790:	70a2                	ld	ra,40(sp)
    80003792:	7402                	ld	s0,32(sp)
    80003794:	64e2                	ld	s1,24(sp)
    80003796:	6942                	ld	s2,16(sp)
    80003798:	69a2                	ld	s3,8(sp)
    8000379a:	6145                	addi	sp,sp,48
    8000379c:	8082                	ret
    panic("invalid file system");
    8000379e:	00005517          	auipc	a0,0x5
    800037a2:	ed250513          	addi	a0,a0,-302 # 80008670 <syscalls+0x150>
    800037a6:	ffffd097          	auipc	ra,0xffffd
    800037aa:	d98080e7          	jalr	-616(ra) # 8000053e <panic>

00000000800037ae <iinit>:
{
    800037ae:	7179                	addi	sp,sp,-48
    800037b0:	f406                	sd	ra,40(sp)
    800037b2:	f022                	sd	s0,32(sp)
    800037b4:	ec26                	sd	s1,24(sp)
    800037b6:	e84a                	sd	s2,16(sp)
    800037b8:	e44e                	sd	s3,8(sp)
    800037ba:	1800                	addi	s0,sp,48
  initlock(&itable.lock, "itable");
    800037bc:	00005597          	auipc	a1,0x5
    800037c0:	ecc58593          	addi	a1,a1,-308 # 80008688 <syscalls+0x168>
    800037c4:	0089c517          	auipc	a0,0x89c
    800037c8:	40450513          	addi	a0,a0,1028 # 8089fbc8 <itable>
    800037cc:	ffffd097          	auipc	ra,0xffffd
    800037d0:	5f2080e7          	jalr	1522(ra) # 80000dbe <initlock>
  for(i = 0; i < NINODE; i++) {
    800037d4:	0089c497          	auipc	s1,0x89c
    800037d8:	41c48493          	addi	s1,s1,1052 # 8089fbf0 <itable+0x28>
    800037dc:	0089e997          	auipc	s3,0x89e
    800037e0:	ea498993          	addi	s3,s3,-348 # 808a1680 <log+0x10>
    initsleeplock(&itable.inode[i].lock, "inode");
    800037e4:	00005917          	auipc	s2,0x5
    800037e8:	eac90913          	addi	s2,s2,-340 # 80008690 <syscalls+0x170>
    800037ec:	85ca                	mv	a1,s2
    800037ee:	8526                	mv	a0,s1
    800037f0:	00001097          	auipc	ra,0x1
    800037f4:	e46080e7          	jalr	-442(ra) # 80004636 <initsleeplock>
  for(i = 0; i < NINODE; i++) {
    800037f8:	08848493          	addi	s1,s1,136
    800037fc:	ff3498e3          	bne	s1,s3,800037ec <iinit+0x3e>
}
    80003800:	70a2                	ld	ra,40(sp)
    80003802:	7402                	ld	s0,32(sp)
    80003804:	64e2                	ld	s1,24(sp)
    80003806:	6942                	ld	s2,16(sp)
    80003808:	69a2                	ld	s3,8(sp)
    8000380a:	6145                	addi	sp,sp,48
    8000380c:	8082                	ret

000000008000380e <ialloc>:
{
    8000380e:	715d                	addi	sp,sp,-80
    80003810:	e486                	sd	ra,72(sp)
    80003812:	e0a2                	sd	s0,64(sp)
    80003814:	fc26                	sd	s1,56(sp)
    80003816:	f84a                	sd	s2,48(sp)
    80003818:	f44e                	sd	s3,40(sp)
    8000381a:	f052                	sd	s4,32(sp)
    8000381c:	ec56                	sd	s5,24(sp)
    8000381e:	e85a                	sd	s6,16(sp)
    80003820:	e45e                	sd	s7,8(sp)
    80003822:	0880                	addi	s0,sp,80
  for(inum = 1; inum < sb.ninodes; inum++){
    80003824:	0089c717          	auipc	a4,0x89c
    80003828:	39072703          	lw	a4,912(a4) # 8089fbb4 <sb+0xc>
    8000382c:	4785                	li	a5,1
    8000382e:	04e7fa63          	bgeu	a5,a4,80003882 <ialloc+0x74>
    80003832:	8aaa                	mv	s5,a0
    80003834:	8bae                	mv	s7,a1
    80003836:	4485                	li	s1,1
    bp = bread(dev, IBLOCK(inum, sb));
    80003838:	0089ca17          	auipc	s4,0x89c
    8000383c:	370a0a13          	addi	s4,s4,880 # 8089fba8 <sb>
    80003840:	00048b1b          	sext.w	s6,s1
    80003844:	0044d593          	srli	a1,s1,0x4
    80003848:	018a2783          	lw	a5,24(s4)
    8000384c:	9dbd                	addw	a1,a1,a5
    8000384e:	8556                	mv	a0,s5
    80003850:	00000097          	auipc	ra,0x0
    80003854:	954080e7          	jalr	-1708(ra) # 800031a4 <bread>
    80003858:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + inum%IPB;
    8000385a:	05850993          	addi	s3,a0,88
    8000385e:	00f4f793          	andi	a5,s1,15
    80003862:	079a                	slli	a5,a5,0x6
    80003864:	99be                	add	s3,s3,a5
    if(dip->type == 0){  // a free inode
    80003866:	00099783          	lh	a5,0(s3)
    8000386a:	c785                	beqz	a5,80003892 <ialloc+0x84>
    brelse(bp);
    8000386c:	00000097          	auipc	ra,0x0
    80003870:	a68080e7          	jalr	-1432(ra) # 800032d4 <brelse>
  for(inum = 1; inum < sb.ninodes; inum++){
    80003874:	0485                	addi	s1,s1,1
    80003876:	00ca2703          	lw	a4,12(s4)
    8000387a:	0004879b          	sext.w	a5,s1
    8000387e:	fce7e1e3          	bltu	a5,a4,80003840 <ialloc+0x32>
  panic("ialloc: no inodes");
    80003882:	00005517          	auipc	a0,0x5
    80003886:	e1650513          	addi	a0,a0,-490 # 80008698 <syscalls+0x178>
    8000388a:	ffffd097          	auipc	ra,0xffffd
    8000388e:	cb4080e7          	jalr	-844(ra) # 8000053e <panic>
      memset(dip, 0, sizeof(*dip));
    80003892:	04000613          	li	a2,64
    80003896:	4581                	li	a1,0
    80003898:	854e                	mv	a0,s3
    8000389a:	ffffd097          	auipc	ra,0xffffd
    8000389e:	6b0080e7          	jalr	1712(ra) # 80000f4a <memset>
      dip->type = type;
    800038a2:	01799023          	sh	s7,0(s3)
      log_write(bp);   // mark it allocated on the disk
    800038a6:	854a                	mv	a0,s2
    800038a8:	00001097          	auipc	ra,0x1
    800038ac:	ca8080e7          	jalr	-856(ra) # 80004550 <log_write>
      brelse(bp);
    800038b0:	854a                	mv	a0,s2
    800038b2:	00000097          	auipc	ra,0x0
    800038b6:	a22080e7          	jalr	-1502(ra) # 800032d4 <brelse>
      return iget(dev, inum);
    800038ba:	85da                	mv	a1,s6
    800038bc:	8556                	mv	a0,s5
    800038be:	00000097          	auipc	ra,0x0
    800038c2:	db4080e7          	jalr	-588(ra) # 80003672 <iget>
}
    800038c6:	60a6                	ld	ra,72(sp)
    800038c8:	6406                	ld	s0,64(sp)
    800038ca:	74e2                	ld	s1,56(sp)
    800038cc:	7942                	ld	s2,48(sp)
    800038ce:	79a2                	ld	s3,40(sp)
    800038d0:	7a02                	ld	s4,32(sp)
    800038d2:	6ae2                	ld	s5,24(sp)
    800038d4:	6b42                	ld	s6,16(sp)
    800038d6:	6ba2                	ld	s7,8(sp)
    800038d8:	6161                	addi	sp,sp,80
    800038da:	8082                	ret

00000000800038dc <iupdate>:
{
    800038dc:	1101                	addi	sp,sp,-32
    800038de:	ec06                	sd	ra,24(sp)
    800038e0:	e822                	sd	s0,16(sp)
    800038e2:	e426                	sd	s1,8(sp)
    800038e4:	e04a                	sd	s2,0(sp)
    800038e6:	1000                	addi	s0,sp,32
    800038e8:	84aa                	mv	s1,a0
  bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800038ea:	415c                	lw	a5,4(a0)
    800038ec:	0047d79b          	srliw	a5,a5,0x4
    800038f0:	0089c597          	auipc	a1,0x89c
    800038f4:	2d05a583          	lw	a1,720(a1) # 8089fbc0 <sb+0x18>
    800038f8:	9dbd                	addw	a1,a1,a5
    800038fa:	4108                	lw	a0,0(a0)
    800038fc:	00000097          	auipc	ra,0x0
    80003900:	8a8080e7          	jalr	-1880(ra) # 800031a4 <bread>
    80003904:	892a                	mv	s2,a0
  dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003906:	05850793          	addi	a5,a0,88
    8000390a:	40c8                	lw	a0,4(s1)
    8000390c:	893d                	andi	a0,a0,15
    8000390e:	051a                	slli	a0,a0,0x6
    80003910:	953e                	add	a0,a0,a5
  dip->type = ip->type;
    80003912:	04449703          	lh	a4,68(s1)
    80003916:	00e51023          	sh	a4,0(a0)
  dip->major = ip->major;
    8000391a:	04649703          	lh	a4,70(s1)
    8000391e:	00e51123          	sh	a4,2(a0)
  dip->minor = ip->minor;
    80003922:	04849703          	lh	a4,72(s1)
    80003926:	00e51223          	sh	a4,4(a0)
  dip->nlink = ip->nlink;
    8000392a:	04a49703          	lh	a4,74(s1)
    8000392e:	00e51323          	sh	a4,6(a0)
  dip->size = ip->size;
    80003932:	44f8                	lw	a4,76(s1)
    80003934:	c518                	sw	a4,8(a0)
  memmove(dip->addrs, ip->addrs, sizeof(ip->addrs));
    80003936:	03400613          	li	a2,52
    8000393a:	05048593          	addi	a1,s1,80
    8000393e:	0531                	addi	a0,a0,12
    80003940:	ffffd097          	auipc	ra,0xffffd
    80003944:	66a080e7          	jalr	1642(ra) # 80000faa <memmove>
  log_write(bp);
    80003948:	854a                	mv	a0,s2
    8000394a:	00001097          	auipc	ra,0x1
    8000394e:	c06080e7          	jalr	-1018(ra) # 80004550 <log_write>
  brelse(bp);
    80003952:	854a                	mv	a0,s2
    80003954:	00000097          	auipc	ra,0x0
    80003958:	980080e7          	jalr	-1664(ra) # 800032d4 <brelse>
}
    8000395c:	60e2                	ld	ra,24(sp)
    8000395e:	6442                	ld	s0,16(sp)
    80003960:	64a2                	ld	s1,8(sp)
    80003962:	6902                	ld	s2,0(sp)
    80003964:	6105                	addi	sp,sp,32
    80003966:	8082                	ret

0000000080003968 <idup>:
{
    80003968:	1101                	addi	sp,sp,-32
    8000396a:	ec06                	sd	ra,24(sp)
    8000396c:	e822                	sd	s0,16(sp)
    8000396e:	e426                	sd	s1,8(sp)
    80003970:	1000                	addi	s0,sp,32
    80003972:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003974:	0089c517          	auipc	a0,0x89c
    80003978:	25450513          	addi	a0,a0,596 # 8089fbc8 <itable>
    8000397c:	ffffd097          	auipc	ra,0xffffd
    80003980:	4d2080e7          	jalr	1234(ra) # 80000e4e <acquire>
  ip->ref++;
    80003984:	449c                	lw	a5,8(s1)
    80003986:	2785                	addiw	a5,a5,1
    80003988:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    8000398a:	0089c517          	auipc	a0,0x89c
    8000398e:	23e50513          	addi	a0,a0,574 # 8089fbc8 <itable>
    80003992:	ffffd097          	auipc	ra,0xffffd
    80003996:	570080e7          	jalr	1392(ra) # 80000f02 <release>
}
    8000399a:	8526                	mv	a0,s1
    8000399c:	60e2                	ld	ra,24(sp)
    8000399e:	6442                	ld	s0,16(sp)
    800039a0:	64a2                	ld	s1,8(sp)
    800039a2:	6105                	addi	sp,sp,32
    800039a4:	8082                	ret

00000000800039a6 <ilock>:
{
    800039a6:	1101                	addi	sp,sp,-32
    800039a8:	ec06                	sd	ra,24(sp)
    800039aa:	e822                	sd	s0,16(sp)
    800039ac:	e426                	sd	s1,8(sp)
    800039ae:	e04a                	sd	s2,0(sp)
    800039b0:	1000                	addi	s0,sp,32
  if(ip == 0 || ip->ref < 1)
    800039b2:	c115                	beqz	a0,800039d6 <ilock+0x30>
    800039b4:	84aa                	mv	s1,a0
    800039b6:	451c                	lw	a5,8(a0)
    800039b8:	00f05f63          	blez	a5,800039d6 <ilock+0x30>
  acquiresleep(&ip->lock);
    800039bc:	0541                	addi	a0,a0,16
    800039be:	00001097          	auipc	ra,0x1
    800039c2:	cb2080e7          	jalr	-846(ra) # 80004670 <acquiresleep>
  if(ip->valid == 0){
    800039c6:	40bc                	lw	a5,64(s1)
    800039c8:	cf99                	beqz	a5,800039e6 <ilock+0x40>
}
    800039ca:	60e2                	ld	ra,24(sp)
    800039cc:	6442                	ld	s0,16(sp)
    800039ce:	64a2                	ld	s1,8(sp)
    800039d0:	6902                	ld	s2,0(sp)
    800039d2:	6105                	addi	sp,sp,32
    800039d4:	8082                	ret
    panic("ilock");
    800039d6:	00005517          	auipc	a0,0x5
    800039da:	cda50513          	addi	a0,a0,-806 # 800086b0 <syscalls+0x190>
    800039de:	ffffd097          	auipc	ra,0xffffd
    800039e2:	b60080e7          	jalr	-1184(ra) # 8000053e <panic>
    bp = bread(ip->dev, IBLOCK(ip->inum, sb));
    800039e6:	40dc                	lw	a5,4(s1)
    800039e8:	0047d79b          	srliw	a5,a5,0x4
    800039ec:	0089c597          	auipc	a1,0x89c
    800039f0:	1d45a583          	lw	a1,468(a1) # 8089fbc0 <sb+0x18>
    800039f4:	9dbd                	addw	a1,a1,a5
    800039f6:	4088                	lw	a0,0(s1)
    800039f8:	fffff097          	auipc	ra,0xfffff
    800039fc:	7ac080e7          	jalr	1964(ra) # 800031a4 <bread>
    80003a00:	892a                	mv	s2,a0
    dip = (struct dinode*)bp->data + ip->inum%IPB;
    80003a02:	05850593          	addi	a1,a0,88
    80003a06:	40dc                	lw	a5,4(s1)
    80003a08:	8bbd                	andi	a5,a5,15
    80003a0a:	079a                	slli	a5,a5,0x6
    80003a0c:	95be                	add	a1,a1,a5
    ip->type = dip->type;
    80003a0e:	00059783          	lh	a5,0(a1)
    80003a12:	04f49223          	sh	a5,68(s1)
    ip->major = dip->major;
    80003a16:	00259783          	lh	a5,2(a1)
    80003a1a:	04f49323          	sh	a5,70(s1)
    ip->minor = dip->minor;
    80003a1e:	00459783          	lh	a5,4(a1)
    80003a22:	04f49423          	sh	a5,72(s1)
    ip->nlink = dip->nlink;
    80003a26:	00659783          	lh	a5,6(a1)
    80003a2a:	04f49523          	sh	a5,74(s1)
    ip->size = dip->size;
    80003a2e:	459c                	lw	a5,8(a1)
    80003a30:	c4fc                	sw	a5,76(s1)
    memmove(ip->addrs, dip->addrs, sizeof(ip->addrs));
    80003a32:	03400613          	li	a2,52
    80003a36:	05b1                	addi	a1,a1,12
    80003a38:	05048513          	addi	a0,s1,80
    80003a3c:	ffffd097          	auipc	ra,0xffffd
    80003a40:	56e080e7          	jalr	1390(ra) # 80000faa <memmove>
    brelse(bp);
    80003a44:	854a                	mv	a0,s2
    80003a46:	00000097          	auipc	ra,0x0
    80003a4a:	88e080e7          	jalr	-1906(ra) # 800032d4 <brelse>
    ip->valid = 1;
    80003a4e:	4785                	li	a5,1
    80003a50:	c0bc                	sw	a5,64(s1)
    if(ip->type == 0)
    80003a52:	04449783          	lh	a5,68(s1)
    80003a56:	fbb5                	bnez	a5,800039ca <ilock+0x24>
      panic("ilock: no type");
    80003a58:	00005517          	auipc	a0,0x5
    80003a5c:	c6050513          	addi	a0,a0,-928 # 800086b8 <syscalls+0x198>
    80003a60:	ffffd097          	auipc	ra,0xffffd
    80003a64:	ade080e7          	jalr	-1314(ra) # 8000053e <panic>

0000000080003a68 <iunlock>:
{
    80003a68:	1101                	addi	sp,sp,-32
    80003a6a:	ec06                	sd	ra,24(sp)
    80003a6c:	e822                	sd	s0,16(sp)
    80003a6e:	e426                	sd	s1,8(sp)
    80003a70:	e04a                	sd	s2,0(sp)
    80003a72:	1000                	addi	s0,sp,32
  if(ip == 0 || !holdingsleep(&ip->lock) || ip->ref < 1)
    80003a74:	c905                	beqz	a0,80003aa4 <iunlock+0x3c>
    80003a76:	84aa                	mv	s1,a0
    80003a78:	01050913          	addi	s2,a0,16
    80003a7c:	854a                	mv	a0,s2
    80003a7e:	00001097          	auipc	ra,0x1
    80003a82:	c8c080e7          	jalr	-884(ra) # 8000470a <holdingsleep>
    80003a86:	cd19                	beqz	a0,80003aa4 <iunlock+0x3c>
    80003a88:	449c                	lw	a5,8(s1)
    80003a8a:	00f05d63          	blez	a5,80003aa4 <iunlock+0x3c>
  releasesleep(&ip->lock);
    80003a8e:	854a                	mv	a0,s2
    80003a90:	00001097          	auipc	ra,0x1
    80003a94:	c36080e7          	jalr	-970(ra) # 800046c6 <releasesleep>
}
    80003a98:	60e2                	ld	ra,24(sp)
    80003a9a:	6442                	ld	s0,16(sp)
    80003a9c:	64a2                	ld	s1,8(sp)
    80003a9e:	6902                	ld	s2,0(sp)
    80003aa0:	6105                	addi	sp,sp,32
    80003aa2:	8082                	ret
    panic("iunlock");
    80003aa4:	00005517          	auipc	a0,0x5
    80003aa8:	c2450513          	addi	a0,a0,-988 # 800086c8 <syscalls+0x1a8>
    80003aac:	ffffd097          	auipc	ra,0xffffd
    80003ab0:	a92080e7          	jalr	-1390(ra) # 8000053e <panic>

0000000080003ab4 <itrunc>:

// Truncate inode (discard contents).
// Caller must hold ip->lock.
void
itrunc(struct inode *ip)
{
    80003ab4:	7179                	addi	sp,sp,-48
    80003ab6:	f406                	sd	ra,40(sp)
    80003ab8:	f022                	sd	s0,32(sp)
    80003aba:	ec26                	sd	s1,24(sp)
    80003abc:	e84a                	sd	s2,16(sp)
    80003abe:	e44e                	sd	s3,8(sp)
    80003ac0:	e052                	sd	s4,0(sp)
    80003ac2:	1800                	addi	s0,sp,48
    80003ac4:	89aa                	mv	s3,a0
  int i, j;
  struct buf *bp;
  uint *a;

  for(i = 0; i < NDIRECT; i++){
    80003ac6:	05050493          	addi	s1,a0,80
    80003aca:	08050913          	addi	s2,a0,128
    80003ace:	a021                	j	80003ad6 <itrunc+0x22>
    80003ad0:	0491                	addi	s1,s1,4
    80003ad2:	01248d63          	beq	s1,s2,80003aec <itrunc+0x38>
    if(ip->addrs[i]){
    80003ad6:	408c                	lw	a1,0(s1)
    80003ad8:	dde5                	beqz	a1,80003ad0 <itrunc+0x1c>
      bfree(ip->dev, ip->addrs[i]);
    80003ada:	0009a503          	lw	a0,0(s3)
    80003ade:	00000097          	auipc	ra,0x0
    80003ae2:	90c080e7          	jalr	-1780(ra) # 800033ea <bfree>
      ip->addrs[i] = 0;
    80003ae6:	0004a023          	sw	zero,0(s1)
    80003aea:	b7dd                	j	80003ad0 <itrunc+0x1c>
    }
  }

  if(ip->addrs[NDIRECT]){
    80003aec:	0809a583          	lw	a1,128(s3)
    80003af0:	e185                	bnez	a1,80003b10 <itrunc+0x5c>
    brelse(bp);
    bfree(ip->dev, ip->addrs[NDIRECT]);
    ip->addrs[NDIRECT] = 0;
  }

  ip->size = 0;
    80003af2:	0409a623          	sw	zero,76(s3)
  iupdate(ip);
    80003af6:	854e                	mv	a0,s3
    80003af8:	00000097          	auipc	ra,0x0
    80003afc:	de4080e7          	jalr	-540(ra) # 800038dc <iupdate>
}
    80003b00:	70a2                	ld	ra,40(sp)
    80003b02:	7402                	ld	s0,32(sp)
    80003b04:	64e2                	ld	s1,24(sp)
    80003b06:	6942                	ld	s2,16(sp)
    80003b08:	69a2                	ld	s3,8(sp)
    80003b0a:	6a02                	ld	s4,0(sp)
    80003b0c:	6145                	addi	sp,sp,48
    80003b0e:	8082                	ret
    bp = bread(ip->dev, ip->addrs[NDIRECT]);
    80003b10:	0009a503          	lw	a0,0(s3)
    80003b14:	fffff097          	auipc	ra,0xfffff
    80003b18:	690080e7          	jalr	1680(ra) # 800031a4 <bread>
    80003b1c:	8a2a                	mv	s4,a0
    for(j = 0; j < NINDIRECT; j++){
    80003b1e:	05850493          	addi	s1,a0,88
    80003b22:	45850913          	addi	s2,a0,1112
    80003b26:	a811                	j	80003b3a <itrunc+0x86>
        bfree(ip->dev, a[j]);
    80003b28:	0009a503          	lw	a0,0(s3)
    80003b2c:	00000097          	auipc	ra,0x0
    80003b30:	8be080e7          	jalr	-1858(ra) # 800033ea <bfree>
    for(j = 0; j < NINDIRECT; j++){
    80003b34:	0491                	addi	s1,s1,4
    80003b36:	01248563          	beq	s1,s2,80003b40 <itrunc+0x8c>
      if(a[j])
    80003b3a:	408c                	lw	a1,0(s1)
    80003b3c:	dde5                	beqz	a1,80003b34 <itrunc+0x80>
    80003b3e:	b7ed                	j	80003b28 <itrunc+0x74>
    brelse(bp);
    80003b40:	8552                	mv	a0,s4
    80003b42:	fffff097          	auipc	ra,0xfffff
    80003b46:	792080e7          	jalr	1938(ra) # 800032d4 <brelse>
    bfree(ip->dev, ip->addrs[NDIRECT]);
    80003b4a:	0809a583          	lw	a1,128(s3)
    80003b4e:	0009a503          	lw	a0,0(s3)
    80003b52:	00000097          	auipc	ra,0x0
    80003b56:	898080e7          	jalr	-1896(ra) # 800033ea <bfree>
    ip->addrs[NDIRECT] = 0;
    80003b5a:	0809a023          	sw	zero,128(s3)
    80003b5e:	bf51                	j	80003af2 <itrunc+0x3e>

0000000080003b60 <iput>:
{
    80003b60:	1101                	addi	sp,sp,-32
    80003b62:	ec06                	sd	ra,24(sp)
    80003b64:	e822                	sd	s0,16(sp)
    80003b66:	e426                	sd	s1,8(sp)
    80003b68:	e04a                	sd	s2,0(sp)
    80003b6a:	1000                	addi	s0,sp,32
    80003b6c:	84aa                	mv	s1,a0
  acquire(&itable.lock);
    80003b6e:	0089c517          	auipc	a0,0x89c
    80003b72:	05a50513          	addi	a0,a0,90 # 8089fbc8 <itable>
    80003b76:	ffffd097          	auipc	ra,0xffffd
    80003b7a:	2d8080e7          	jalr	728(ra) # 80000e4e <acquire>
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003b7e:	4498                	lw	a4,8(s1)
    80003b80:	4785                	li	a5,1
    80003b82:	02f70363          	beq	a4,a5,80003ba8 <iput+0x48>
  ip->ref--;
    80003b86:	449c                	lw	a5,8(s1)
    80003b88:	37fd                	addiw	a5,a5,-1
    80003b8a:	c49c                	sw	a5,8(s1)
  release(&itable.lock);
    80003b8c:	0089c517          	auipc	a0,0x89c
    80003b90:	03c50513          	addi	a0,a0,60 # 8089fbc8 <itable>
    80003b94:	ffffd097          	auipc	ra,0xffffd
    80003b98:	36e080e7          	jalr	878(ra) # 80000f02 <release>
}
    80003b9c:	60e2                	ld	ra,24(sp)
    80003b9e:	6442                	ld	s0,16(sp)
    80003ba0:	64a2                	ld	s1,8(sp)
    80003ba2:	6902                	ld	s2,0(sp)
    80003ba4:	6105                	addi	sp,sp,32
    80003ba6:	8082                	ret
  if(ip->ref == 1 && ip->valid && ip->nlink == 0){
    80003ba8:	40bc                	lw	a5,64(s1)
    80003baa:	dff1                	beqz	a5,80003b86 <iput+0x26>
    80003bac:	04a49783          	lh	a5,74(s1)
    80003bb0:	fbf9                	bnez	a5,80003b86 <iput+0x26>
    acquiresleep(&ip->lock);
    80003bb2:	01048913          	addi	s2,s1,16
    80003bb6:	854a                	mv	a0,s2
    80003bb8:	00001097          	auipc	ra,0x1
    80003bbc:	ab8080e7          	jalr	-1352(ra) # 80004670 <acquiresleep>
    release(&itable.lock);
    80003bc0:	0089c517          	auipc	a0,0x89c
    80003bc4:	00850513          	addi	a0,a0,8 # 8089fbc8 <itable>
    80003bc8:	ffffd097          	auipc	ra,0xffffd
    80003bcc:	33a080e7          	jalr	826(ra) # 80000f02 <release>
    itrunc(ip);
    80003bd0:	8526                	mv	a0,s1
    80003bd2:	00000097          	auipc	ra,0x0
    80003bd6:	ee2080e7          	jalr	-286(ra) # 80003ab4 <itrunc>
    ip->type = 0;
    80003bda:	04049223          	sh	zero,68(s1)
    iupdate(ip);
    80003bde:	8526                	mv	a0,s1
    80003be0:	00000097          	auipc	ra,0x0
    80003be4:	cfc080e7          	jalr	-772(ra) # 800038dc <iupdate>
    ip->valid = 0;
    80003be8:	0404a023          	sw	zero,64(s1)
    releasesleep(&ip->lock);
    80003bec:	854a                	mv	a0,s2
    80003bee:	00001097          	auipc	ra,0x1
    80003bf2:	ad8080e7          	jalr	-1320(ra) # 800046c6 <releasesleep>
    acquire(&itable.lock);
    80003bf6:	0089c517          	auipc	a0,0x89c
    80003bfa:	fd250513          	addi	a0,a0,-46 # 8089fbc8 <itable>
    80003bfe:	ffffd097          	auipc	ra,0xffffd
    80003c02:	250080e7          	jalr	592(ra) # 80000e4e <acquire>
    80003c06:	b741                	j	80003b86 <iput+0x26>

0000000080003c08 <iunlockput>:
{
    80003c08:	1101                	addi	sp,sp,-32
    80003c0a:	ec06                	sd	ra,24(sp)
    80003c0c:	e822                	sd	s0,16(sp)
    80003c0e:	e426                	sd	s1,8(sp)
    80003c10:	1000                	addi	s0,sp,32
    80003c12:	84aa                	mv	s1,a0
  iunlock(ip);
    80003c14:	00000097          	auipc	ra,0x0
    80003c18:	e54080e7          	jalr	-428(ra) # 80003a68 <iunlock>
  iput(ip);
    80003c1c:	8526                	mv	a0,s1
    80003c1e:	00000097          	auipc	ra,0x0
    80003c22:	f42080e7          	jalr	-190(ra) # 80003b60 <iput>
}
    80003c26:	60e2                	ld	ra,24(sp)
    80003c28:	6442                	ld	s0,16(sp)
    80003c2a:	64a2                	ld	s1,8(sp)
    80003c2c:	6105                	addi	sp,sp,32
    80003c2e:	8082                	ret

0000000080003c30 <stati>:

// Copy stat information from inode.
// Caller must hold ip->lock.
void
stati(struct inode *ip, struct stat *st)
{
    80003c30:	1141                	addi	sp,sp,-16
    80003c32:	e422                	sd	s0,8(sp)
    80003c34:	0800                	addi	s0,sp,16
  st->dev = ip->dev;
    80003c36:	411c                	lw	a5,0(a0)
    80003c38:	c19c                	sw	a5,0(a1)
  st->ino = ip->inum;
    80003c3a:	415c                	lw	a5,4(a0)
    80003c3c:	c1dc                	sw	a5,4(a1)
  st->type = ip->type;
    80003c3e:	04451783          	lh	a5,68(a0)
    80003c42:	00f59423          	sh	a5,8(a1)
  st->nlink = ip->nlink;
    80003c46:	04a51783          	lh	a5,74(a0)
    80003c4a:	00f59523          	sh	a5,10(a1)
  st->size = ip->size;
    80003c4e:	04c56783          	lwu	a5,76(a0)
    80003c52:	e99c                	sd	a5,16(a1)
}
    80003c54:	6422                	ld	s0,8(sp)
    80003c56:	0141                	addi	sp,sp,16
    80003c58:	8082                	ret

0000000080003c5a <readi>:
readi(struct inode *ip, int user_dst, uint64 dst, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003c5a:	457c                	lw	a5,76(a0)
    80003c5c:	0ed7e963          	bltu	a5,a3,80003d4e <readi+0xf4>
{
    80003c60:	7159                	addi	sp,sp,-112
    80003c62:	f486                	sd	ra,104(sp)
    80003c64:	f0a2                	sd	s0,96(sp)
    80003c66:	eca6                	sd	s1,88(sp)
    80003c68:	e8ca                	sd	s2,80(sp)
    80003c6a:	e4ce                	sd	s3,72(sp)
    80003c6c:	e0d2                	sd	s4,64(sp)
    80003c6e:	fc56                	sd	s5,56(sp)
    80003c70:	f85a                	sd	s6,48(sp)
    80003c72:	f45e                	sd	s7,40(sp)
    80003c74:	f062                	sd	s8,32(sp)
    80003c76:	ec66                	sd	s9,24(sp)
    80003c78:	e86a                	sd	s10,16(sp)
    80003c7a:	e46e                	sd	s11,8(sp)
    80003c7c:	1880                	addi	s0,sp,112
    80003c7e:	8baa                	mv	s7,a0
    80003c80:	8c2e                	mv	s8,a1
    80003c82:	8ab2                	mv	s5,a2
    80003c84:	84b6                	mv	s1,a3
    80003c86:	8b3a                	mv	s6,a4
  if(off > ip->size || off + n < off)
    80003c88:	9f35                	addw	a4,a4,a3
    return 0;
    80003c8a:	4501                	li	a0,0
  if(off > ip->size || off + n < off)
    80003c8c:	0ad76063          	bltu	a4,a3,80003d2c <readi+0xd2>
  if(off + n > ip->size)
    80003c90:	00e7f463          	bgeu	a5,a4,80003c98 <readi+0x3e>
    n = ip->size - off;
    80003c94:	40d78b3b          	subw	s6,a5,a3

  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003c98:	0a0b0963          	beqz	s6,80003d4a <readi+0xf0>
    80003c9c:	4981                	li	s3,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003c9e:	40000d13          	li	s10,1024
    if(either_copyout(user_dst, dst, bp->data + (off % BSIZE), m) == -1) {
    80003ca2:	5cfd                	li	s9,-1
    80003ca4:	a82d                	j	80003cde <readi+0x84>
    80003ca6:	020a1d93          	slli	s11,s4,0x20
    80003caa:	020ddd93          	srli	s11,s11,0x20
    80003cae:	05890613          	addi	a2,s2,88
    80003cb2:	86ee                	mv	a3,s11
    80003cb4:	963a                	add	a2,a2,a4
    80003cb6:	85d6                	mv	a1,s5
    80003cb8:	8562                	mv	a0,s8
    80003cba:	fffff097          	auipc	ra,0xfffff
    80003cbe:	9cc080e7          	jalr	-1588(ra) # 80002686 <either_copyout>
    80003cc2:	05950d63          	beq	a0,s9,80003d1c <readi+0xc2>
      brelse(bp);
      tot = -1;
      break;
    }
    brelse(bp);
    80003cc6:	854a                	mv	a0,s2
    80003cc8:	fffff097          	auipc	ra,0xfffff
    80003ccc:	60c080e7          	jalr	1548(ra) # 800032d4 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003cd0:	013a09bb          	addw	s3,s4,s3
    80003cd4:	009a04bb          	addw	s1,s4,s1
    80003cd8:	9aee                	add	s5,s5,s11
    80003cda:	0569f763          	bgeu	s3,s6,80003d28 <readi+0xce>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003cde:	000ba903          	lw	s2,0(s7)
    80003ce2:	00a4d59b          	srliw	a1,s1,0xa
    80003ce6:	855e                	mv	a0,s7
    80003ce8:	00000097          	auipc	ra,0x0
    80003cec:	8b0080e7          	jalr	-1872(ra) # 80003598 <bmap>
    80003cf0:	0005059b          	sext.w	a1,a0
    80003cf4:	854a                	mv	a0,s2
    80003cf6:	fffff097          	auipc	ra,0xfffff
    80003cfa:	4ae080e7          	jalr	1198(ra) # 800031a4 <bread>
    80003cfe:	892a                	mv	s2,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d00:	3ff4f713          	andi	a4,s1,1023
    80003d04:	40ed07bb          	subw	a5,s10,a4
    80003d08:	413b06bb          	subw	a3,s6,s3
    80003d0c:	8a3e                	mv	s4,a5
    80003d0e:	2781                	sext.w	a5,a5
    80003d10:	0006861b          	sext.w	a2,a3
    80003d14:	f8f679e3          	bgeu	a2,a5,80003ca6 <readi+0x4c>
    80003d18:	8a36                	mv	s4,a3
    80003d1a:	b771                	j	80003ca6 <readi+0x4c>
      brelse(bp);
    80003d1c:	854a                	mv	a0,s2
    80003d1e:	fffff097          	auipc	ra,0xfffff
    80003d22:	5b6080e7          	jalr	1462(ra) # 800032d4 <brelse>
      tot = -1;
    80003d26:	59fd                	li	s3,-1
  }
  return tot;
    80003d28:	0009851b          	sext.w	a0,s3
}
    80003d2c:	70a6                	ld	ra,104(sp)
    80003d2e:	7406                	ld	s0,96(sp)
    80003d30:	64e6                	ld	s1,88(sp)
    80003d32:	6946                	ld	s2,80(sp)
    80003d34:	69a6                	ld	s3,72(sp)
    80003d36:	6a06                	ld	s4,64(sp)
    80003d38:	7ae2                	ld	s5,56(sp)
    80003d3a:	7b42                	ld	s6,48(sp)
    80003d3c:	7ba2                	ld	s7,40(sp)
    80003d3e:	7c02                	ld	s8,32(sp)
    80003d40:	6ce2                	ld	s9,24(sp)
    80003d42:	6d42                	ld	s10,16(sp)
    80003d44:	6da2                	ld	s11,8(sp)
    80003d46:	6165                	addi	sp,sp,112
    80003d48:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, dst+=m){
    80003d4a:	89da                	mv	s3,s6
    80003d4c:	bff1                	j	80003d28 <readi+0xce>
    return 0;
    80003d4e:	4501                	li	a0,0
}
    80003d50:	8082                	ret

0000000080003d52 <writei>:
writei(struct inode *ip, int user_src, uint64 src, uint off, uint n)
{
  uint tot, m;
  struct buf *bp;

  if(off > ip->size || off + n < off)
    80003d52:	457c                	lw	a5,76(a0)
    80003d54:	10d7e863          	bltu	a5,a3,80003e64 <writei+0x112>
{
    80003d58:	7159                	addi	sp,sp,-112
    80003d5a:	f486                	sd	ra,104(sp)
    80003d5c:	f0a2                	sd	s0,96(sp)
    80003d5e:	eca6                	sd	s1,88(sp)
    80003d60:	e8ca                	sd	s2,80(sp)
    80003d62:	e4ce                	sd	s3,72(sp)
    80003d64:	e0d2                	sd	s4,64(sp)
    80003d66:	fc56                	sd	s5,56(sp)
    80003d68:	f85a                	sd	s6,48(sp)
    80003d6a:	f45e                	sd	s7,40(sp)
    80003d6c:	f062                	sd	s8,32(sp)
    80003d6e:	ec66                	sd	s9,24(sp)
    80003d70:	e86a                	sd	s10,16(sp)
    80003d72:	e46e                	sd	s11,8(sp)
    80003d74:	1880                	addi	s0,sp,112
    80003d76:	8b2a                	mv	s6,a0
    80003d78:	8c2e                	mv	s8,a1
    80003d7a:	8ab2                	mv	s5,a2
    80003d7c:	8936                	mv	s2,a3
    80003d7e:	8bba                	mv	s7,a4
  if(off > ip->size || off + n < off)
    80003d80:	00e687bb          	addw	a5,a3,a4
    80003d84:	0ed7e263          	bltu	a5,a3,80003e68 <writei+0x116>
    return -1;
  if(off + n > MAXFILE*BSIZE)
    80003d88:	00043737          	lui	a4,0x43
    80003d8c:	0ef76063          	bltu	a4,a5,80003e6c <writei+0x11a>
    return -1;

  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003d90:	0c0b8863          	beqz	s7,80003e60 <writei+0x10e>
    80003d94:	4a01                	li	s4,0
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    m = min(n - tot, BSIZE - off%BSIZE);
    80003d96:	40000d13          	li	s10,1024
    if(either_copyin(bp->data + (off % BSIZE), user_src, src, m) == -1) {
    80003d9a:	5cfd                	li	s9,-1
    80003d9c:	a091                	j	80003de0 <writei+0x8e>
    80003d9e:	02099d93          	slli	s11,s3,0x20
    80003da2:	020ddd93          	srli	s11,s11,0x20
    80003da6:	05848513          	addi	a0,s1,88
    80003daa:	86ee                	mv	a3,s11
    80003dac:	8656                	mv	a2,s5
    80003dae:	85e2                	mv	a1,s8
    80003db0:	953a                	add	a0,a0,a4
    80003db2:	fffff097          	auipc	ra,0xfffff
    80003db6:	92a080e7          	jalr	-1750(ra) # 800026dc <either_copyin>
    80003dba:	07950263          	beq	a0,s9,80003e1e <writei+0xcc>
      brelse(bp);
      break;
    }
    log_write(bp);
    80003dbe:	8526                	mv	a0,s1
    80003dc0:	00000097          	auipc	ra,0x0
    80003dc4:	790080e7          	jalr	1936(ra) # 80004550 <log_write>
    brelse(bp);
    80003dc8:	8526                	mv	a0,s1
    80003dca:	fffff097          	auipc	ra,0xfffff
    80003dce:	50a080e7          	jalr	1290(ra) # 800032d4 <brelse>
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003dd2:	01498a3b          	addw	s4,s3,s4
    80003dd6:	0129893b          	addw	s2,s3,s2
    80003dda:	9aee                	add	s5,s5,s11
    80003ddc:	057a7663          	bgeu	s4,s7,80003e28 <writei+0xd6>
    bp = bread(ip->dev, bmap(ip, off/BSIZE));
    80003de0:	000b2483          	lw	s1,0(s6)
    80003de4:	00a9559b          	srliw	a1,s2,0xa
    80003de8:	855a                	mv	a0,s6
    80003dea:	fffff097          	auipc	ra,0xfffff
    80003dee:	7ae080e7          	jalr	1966(ra) # 80003598 <bmap>
    80003df2:	0005059b          	sext.w	a1,a0
    80003df6:	8526                	mv	a0,s1
    80003df8:	fffff097          	auipc	ra,0xfffff
    80003dfc:	3ac080e7          	jalr	940(ra) # 800031a4 <bread>
    80003e00:	84aa                	mv	s1,a0
    m = min(n - tot, BSIZE - off%BSIZE);
    80003e02:	3ff97713          	andi	a4,s2,1023
    80003e06:	40ed07bb          	subw	a5,s10,a4
    80003e0a:	414b86bb          	subw	a3,s7,s4
    80003e0e:	89be                	mv	s3,a5
    80003e10:	2781                	sext.w	a5,a5
    80003e12:	0006861b          	sext.w	a2,a3
    80003e16:	f8f674e3          	bgeu	a2,a5,80003d9e <writei+0x4c>
    80003e1a:	89b6                	mv	s3,a3
    80003e1c:	b749                	j	80003d9e <writei+0x4c>
      brelse(bp);
    80003e1e:	8526                	mv	a0,s1
    80003e20:	fffff097          	auipc	ra,0xfffff
    80003e24:	4b4080e7          	jalr	1204(ra) # 800032d4 <brelse>
  }

  if(off > ip->size)
    80003e28:	04cb2783          	lw	a5,76(s6)
    80003e2c:	0127f463          	bgeu	a5,s2,80003e34 <writei+0xe2>
    ip->size = off;
    80003e30:	052b2623          	sw	s2,76(s6)

  // write the i-node back to disk even if the size didn't change
  // because the loop above might have called bmap() and added a new
  // block to ip->addrs[].
  iupdate(ip);
    80003e34:	855a                	mv	a0,s6
    80003e36:	00000097          	auipc	ra,0x0
    80003e3a:	aa6080e7          	jalr	-1370(ra) # 800038dc <iupdate>

  return tot;
    80003e3e:	000a051b          	sext.w	a0,s4
}
    80003e42:	70a6                	ld	ra,104(sp)
    80003e44:	7406                	ld	s0,96(sp)
    80003e46:	64e6                	ld	s1,88(sp)
    80003e48:	6946                	ld	s2,80(sp)
    80003e4a:	69a6                	ld	s3,72(sp)
    80003e4c:	6a06                	ld	s4,64(sp)
    80003e4e:	7ae2                	ld	s5,56(sp)
    80003e50:	7b42                	ld	s6,48(sp)
    80003e52:	7ba2                	ld	s7,40(sp)
    80003e54:	7c02                	ld	s8,32(sp)
    80003e56:	6ce2                	ld	s9,24(sp)
    80003e58:	6d42                	ld	s10,16(sp)
    80003e5a:	6da2                	ld	s11,8(sp)
    80003e5c:	6165                	addi	sp,sp,112
    80003e5e:	8082                	ret
  for(tot=0; tot<n; tot+=m, off+=m, src+=m){
    80003e60:	8a5e                	mv	s4,s7
    80003e62:	bfc9                	j	80003e34 <writei+0xe2>
    return -1;
    80003e64:	557d                	li	a0,-1
}
    80003e66:	8082                	ret
    return -1;
    80003e68:	557d                	li	a0,-1
    80003e6a:	bfe1                	j	80003e42 <writei+0xf0>
    return -1;
    80003e6c:	557d                	li	a0,-1
    80003e6e:	bfd1                	j	80003e42 <writei+0xf0>

0000000080003e70 <namecmp>:

// Directories

int
namecmp(const char *s, const char *t)
{
    80003e70:	1141                	addi	sp,sp,-16
    80003e72:	e406                	sd	ra,8(sp)
    80003e74:	e022                	sd	s0,0(sp)
    80003e76:	0800                	addi	s0,sp,16
  return strncmp(s, t, DIRSIZ);
    80003e78:	4639                	li	a2,14
    80003e7a:	ffffd097          	auipc	ra,0xffffd
    80003e7e:	1a8080e7          	jalr	424(ra) # 80001022 <strncmp>
}
    80003e82:	60a2                	ld	ra,8(sp)
    80003e84:	6402                	ld	s0,0(sp)
    80003e86:	0141                	addi	sp,sp,16
    80003e88:	8082                	ret

0000000080003e8a <dirlookup>:

// Look for a directory entry in a directory.
// If found, set *poff to byte offset of entry.
struct inode*
dirlookup(struct inode *dp, char *name, uint *poff)
{
    80003e8a:	7139                	addi	sp,sp,-64
    80003e8c:	fc06                	sd	ra,56(sp)
    80003e8e:	f822                	sd	s0,48(sp)
    80003e90:	f426                	sd	s1,40(sp)
    80003e92:	f04a                	sd	s2,32(sp)
    80003e94:	ec4e                	sd	s3,24(sp)
    80003e96:	e852                	sd	s4,16(sp)
    80003e98:	0080                	addi	s0,sp,64
  uint off, inum;
  struct dirent de;

  if(dp->type != T_DIR)
    80003e9a:	04451703          	lh	a4,68(a0)
    80003e9e:	4785                	li	a5,1
    80003ea0:	00f71a63          	bne	a4,a5,80003eb4 <dirlookup+0x2a>
    80003ea4:	892a                	mv	s2,a0
    80003ea6:	89ae                	mv	s3,a1
    80003ea8:	8a32                	mv	s4,a2
    panic("dirlookup not DIR");

  for(off = 0; off < dp->size; off += sizeof(de)){
    80003eaa:	457c                	lw	a5,76(a0)
    80003eac:	4481                	li	s1,0
      inum = de.inum;
      return iget(dp->dev, inum);
    }
  }

  return 0;
    80003eae:	4501                	li	a0,0
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003eb0:	e79d                	bnez	a5,80003ede <dirlookup+0x54>
    80003eb2:	a8a5                	j	80003f2a <dirlookup+0xa0>
    panic("dirlookup not DIR");
    80003eb4:	00005517          	auipc	a0,0x5
    80003eb8:	81c50513          	addi	a0,a0,-2020 # 800086d0 <syscalls+0x1b0>
    80003ebc:	ffffc097          	auipc	ra,0xffffc
    80003ec0:	682080e7          	jalr	1666(ra) # 8000053e <panic>
      panic("dirlookup read");
    80003ec4:	00005517          	auipc	a0,0x5
    80003ec8:	82450513          	addi	a0,a0,-2012 # 800086e8 <syscalls+0x1c8>
    80003ecc:	ffffc097          	auipc	ra,0xffffc
    80003ed0:	672080e7          	jalr	1650(ra) # 8000053e <panic>
  for(off = 0; off < dp->size; off += sizeof(de)){
    80003ed4:	24c1                	addiw	s1,s1,16
    80003ed6:	04c92783          	lw	a5,76(s2)
    80003eda:	04f4f763          	bgeu	s1,a5,80003f28 <dirlookup+0x9e>
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80003ede:	4741                	li	a4,16
    80003ee0:	86a6                	mv	a3,s1
    80003ee2:	fc040613          	addi	a2,s0,-64
    80003ee6:	4581                	li	a1,0
    80003ee8:	854a                	mv	a0,s2
    80003eea:	00000097          	auipc	ra,0x0
    80003eee:	d70080e7          	jalr	-656(ra) # 80003c5a <readi>
    80003ef2:	47c1                	li	a5,16
    80003ef4:	fcf518e3          	bne	a0,a5,80003ec4 <dirlookup+0x3a>
    if(de.inum == 0)
    80003ef8:	fc045783          	lhu	a5,-64(s0)
    80003efc:	dfe1                	beqz	a5,80003ed4 <dirlookup+0x4a>
    if(namecmp(name, de.name) == 0){
    80003efe:	fc240593          	addi	a1,s0,-62
    80003f02:	854e                	mv	a0,s3
    80003f04:	00000097          	auipc	ra,0x0
    80003f08:	f6c080e7          	jalr	-148(ra) # 80003e70 <namecmp>
    80003f0c:	f561                	bnez	a0,80003ed4 <dirlookup+0x4a>
      if(poff)
    80003f0e:	000a0463          	beqz	s4,80003f16 <dirlookup+0x8c>
        *poff = off;
    80003f12:	009a2023          	sw	s1,0(s4)
      return iget(dp->dev, inum);
    80003f16:	fc045583          	lhu	a1,-64(s0)
    80003f1a:	00092503          	lw	a0,0(s2)
    80003f1e:	fffff097          	auipc	ra,0xfffff
    80003f22:	754080e7          	jalr	1876(ra) # 80003672 <iget>
    80003f26:	a011                	j	80003f2a <dirlookup+0xa0>
  return 0;
    80003f28:	4501                	li	a0,0
}
    80003f2a:	70e2                	ld	ra,56(sp)
    80003f2c:	7442                	ld	s0,48(sp)
    80003f2e:	74a2                	ld	s1,40(sp)
    80003f30:	7902                	ld	s2,32(sp)
    80003f32:	69e2                	ld	s3,24(sp)
    80003f34:	6a42                	ld	s4,16(sp)
    80003f36:	6121                	addi	sp,sp,64
    80003f38:	8082                	ret

0000000080003f3a <namex>:
// If parent != 0, return the inode for the parent and copy the final
// path element into name, which must have room for DIRSIZ bytes.
// Must be called inside a transaction since it calls iput().
static struct inode*
namex(char *path, int nameiparent, char *name)
{
    80003f3a:	711d                	addi	sp,sp,-96
    80003f3c:	ec86                	sd	ra,88(sp)
    80003f3e:	e8a2                	sd	s0,80(sp)
    80003f40:	e4a6                	sd	s1,72(sp)
    80003f42:	e0ca                	sd	s2,64(sp)
    80003f44:	fc4e                	sd	s3,56(sp)
    80003f46:	f852                	sd	s4,48(sp)
    80003f48:	f456                	sd	s5,40(sp)
    80003f4a:	f05a                	sd	s6,32(sp)
    80003f4c:	ec5e                	sd	s7,24(sp)
    80003f4e:	e862                	sd	s8,16(sp)
    80003f50:	e466                	sd	s9,8(sp)
    80003f52:	1080                	addi	s0,sp,96
    80003f54:	84aa                	mv	s1,a0
    80003f56:	8b2e                	mv	s6,a1
    80003f58:	8ab2                	mv	s5,a2
  struct inode *ip, *next;

  if(*path == '/')
    80003f5a:	00054703          	lbu	a4,0(a0)
    80003f5e:	02f00793          	li	a5,47
    80003f62:	02f70363          	beq	a4,a5,80003f88 <namex+0x4e>
    ip = iget(ROOTDEV, ROOTINO);
  else
    ip = idup(myproc()->cwd);
    80003f66:	ffffe097          	auipc	ra,0xffffe
    80003f6a:	cb4080e7          	jalr	-844(ra) # 80001c1a <myproc>
    80003f6e:	15053503          	ld	a0,336(a0)
    80003f72:	00000097          	auipc	ra,0x0
    80003f76:	9f6080e7          	jalr	-1546(ra) # 80003968 <idup>
    80003f7a:	89aa                	mv	s3,a0
  while(*path == '/')
    80003f7c:	02f00913          	li	s2,47
  len = path - s;
    80003f80:	4b81                	li	s7,0
  if(len >= DIRSIZ)
    80003f82:	4cb5                	li	s9,13

  while((path = skipelem(path, name)) != 0){
    ilock(ip);
    if(ip->type != T_DIR){
    80003f84:	4c05                	li	s8,1
    80003f86:	a865                	j	8000403e <namex+0x104>
    ip = iget(ROOTDEV, ROOTINO);
    80003f88:	4585                	li	a1,1
    80003f8a:	4505                	li	a0,1
    80003f8c:	fffff097          	auipc	ra,0xfffff
    80003f90:	6e6080e7          	jalr	1766(ra) # 80003672 <iget>
    80003f94:	89aa                	mv	s3,a0
    80003f96:	b7dd                	j	80003f7c <namex+0x42>
      iunlockput(ip);
    80003f98:	854e                	mv	a0,s3
    80003f9a:	00000097          	auipc	ra,0x0
    80003f9e:	c6e080e7          	jalr	-914(ra) # 80003c08 <iunlockput>
      return 0;
    80003fa2:	4981                	li	s3,0
  if(nameiparent){
    iput(ip);
    return 0;
  }
  return ip;
}
    80003fa4:	854e                	mv	a0,s3
    80003fa6:	60e6                	ld	ra,88(sp)
    80003fa8:	6446                	ld	s0,80(sp)
    80003faa:	64a6                	ld	s1,72(sp)
    80003fac:	6906                	ld	s2,64(sp)
    80003fae:	79e2                	ld	s3,56(sp)
    80003fb0:	7a42                	ld	s4,48(sp)
    80003fb2:	7aa2                	ld	s5,40(sp)
    80003fb4:	7b02                	ld	s6,32(sp)
    80003fb6:	6be2                	ld	s7,24(sp)
    80003fb8:	6c42                	ld	s8,16(sp)
    80003fba:	6ca2                	ld	s9,8(sp)
    80003fbc:	6125                	addi	sp,sp,96
    80003fbe:	8082                	ret
      iunlock(ip);
    80003fc0:	854e                	mv	a0,s3
    80003fc2:	00000097          	auipc	ra,0x0
    80003fc6:	aa6080e7          	jalr	-1370(ra) # 80003a68 <iunlock>
      return ip;
    80003fca:	bfe9                	j	80003fa4 <namex+0x6a>
      iunlockput(ip);
    80003fcc:	854e                	mv	a0,s3
    80003fce:	00000097          	auipc	ra,0x0
    80003fd2:	c3a080e7          	jalr	-966(ra) # 80003c08 <iunlockput>
      return 0;
    80003fd6:	89d2                	mv	s3,s4
    80003fd8:	b7f1                	j	80003fa4 <namex+0x6a>
  len = path - s;
    80003fda:	40b48633          	sub	a2,s1,a1
    80003fde:	00060a1b          	sext.w	s4,a2
  if(len >= DIRSIZ)
    80003fe2:	094cd463          	bge	s9,s4,8000406a <namex+0x130>
    memmove(name, s, DIRSIZ);
    80003fe6:	4639                	li	a2,14
    80003fe8:	8556                	mv	a0,s5
    80003fea:	ffffd097          	auipc	ra,0xffffd
    80003fee:	fc0080e7          	jalr	-64(ra) # 80000faa <memmove>
  while(*path == '/')
    80003ff2:	0004c783          	lbu	a5,0(s1)
    80003ff6:	01279763          	bne	a5,s2,80004004 <namex+0xca>
    path++;
    80003ffa:	0485                	addi	s1,s1,1
  while(*path == '/')
    80003ffc:	0004c783          	lbu	a5,0(s1)
    80004000:	ff278de3          	beq	a5,s2,80003ffa <namex+0xc0>
    ilock(ip);
    80004004:	854e                	mv	a0,s3
    80004006:	00000097          	auipc	ra,0x0
    8000400a:	9a0080e7          	jalr	-1632(ra) # 800039a6 <ilock>
    if(ip->type != T_DIR){
    8000400e:	04499783          	lh	a5,68(s3)
    80004012:	f98793e3          	bne	a5,s8,80003f98 <namex+0x5e>
    if(nameiparent && *path == '\0'){
    80004016:	000b0563          	beqz	s6,80004020 <namex+0xe6>
    8000401a:	0004c783          	lbu	a5,0(s1)
    8000401e:	d3cd                	beqz	a5,80003fc0 <namex+0x86>
    if((next = dirlookup(ip, name, 0)) == 0){
    80004020:	865e                	mv	a2,s7
    80004022:	85d6                	mv	a1,s5
    80004024:	854e                	mv	a0,s3
    80004026:	00000097          	auipc	ra,0x0
    8000402a:	e64080e7          	jalr	-412(ra) # 80003e8a <dirlookup>
    8000402e:	8a2a                	mv	s4,a0
    80004030:	dd51                	beqz	a0,80003fcc <namex+0x92>
    iunlockput(ip);
    80004032:	854e                	mv	a0,s3
    80004034:	00000097          	auipc	ra,0x0
    80004038:	bd4080e7          	jalr	-1068(ra) # 80003c08 <iunlockput>
    ip = next;
    8000403c:	89d2                	mv	s3,s4
  while(*path == '/')
    8000403e:	0004c783          	lbu	a5,0(s1)
    80004042:	05279763          	bne	a5,s2,80004090 <namex+0x156>
    path++;
    80004046:	0485                	addi	s1,s1,1
  while(*path == '/')
    80004048:	0004c783          	lbu	a5,0(s1)
    8000404c:	ff278de3          	beq	a5,s2,80004046 <namex+0x10c>
  if(*path == 0)
    80004050:	c79d                	beqz	a5,8000407e <namex+0x144>
    path++;
    80004052:	85a6                	mv	a1,s1
  len = path - s;
    80004054:	8a5e                	mv	s4,s7
    80004056:	865e                	mv	a2,s7
  while(*path != '/' && *path != 0)
    80004058:	01278963          	beq	a5,s2,8000406a <namex+0x130>
    8000405c:	dfbd                	beqz	a5,80003fda <namex+0xa0>
    path++;
    8000405e:	0485                	addi	s1,s1,1
  while(*path != '/' && *path != 0)
    80004060:	0004c783          	lbu	a5,0(s1)
    80004064:	ff279ce3          	bne	a5,s2,8000405c <namex+0x122>
    80004068:	bf8d                	j	80003fda <namex+0xa0>
    memmove(name, s, len);
    8000406a:	2601                	sext.w	a2,a2
    8000406c:	8556                	mv	a0,s5
    8000406e:	ffffd097          	auipc	ra,0xffffd
    80004072:	f3c080e7          	jalr	-196(ra) # 80000faa <memmove>
    name[len] = 0;
    80004076:	9a56                	add	s4,s4,s5
    80004078:	000a0023          	sb	zero,0(s4)
    8000407c:	bf9d                	j	80003ff2 <namex+0xb8>
  if(nameiparent){
    8000407e:	f20b03e3          	beqz	s6,80003fa4 <namex+0x6a>
    iput(ip);
    80004082:	854e                	mv	a0,s3
    80004084:	00000097          	auipc	ra,0x0
    80004088:	adc080e7          	jalr	-1316(ra) # 80003b60 <iput>
    return 0;
    8000408c:	4981                	li	s3,0
    8000408e:	bf19                	j	80003fa4 <namex+0x6a>
  if(*path == 0)
    80004090:	d7fd                	beqz	a5,8000407e <namex+0x144>
  while(*path != '/' && *path != 0)
    80004092:	0004c783          	lbu	a5,0(s1)
    80004096:	85a6                	mv	a1,s1
    80004098:	b7d1                	j	8000405c <namex+0x122>

000000008000409a <dirlink>:
{
    8000409a:	7139                	addi	sp,sp,-64
    8000409c:	fc06                	sd	ra,56(sp)
    8000409e:	f822                	sd	s0,48(sp)
    800040a0:	f426                	sd	s1,40(sp)
    800040a2:	f04a                	sd	s2,32(sp)
    800040a4:	ec4e                	sd	s3,24(sp)
    800040a6:	e852                	sd	s4,16(sp)
    800040a8:	0080                	addi	s0,sp,64
    800040aa:	892a                	mv	s2,a0
    800040ac:	8a2e                	mv	s4,a1
    800040ae:	89b2                	mv	s3,a2
  if((ip = dirlookup(dp, name, 0)) != 0){
    800040b0:	4601                	li	a2,0
    800040b2:	00000097          	auipc	ra,0x0
    800040b6:	dd8080e7          	jalr	-552(ra) # 80003e8a <dirlookup>
    800040ba:	e93d                	bnez	a0,80004130 <dirlink+0x96>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040bc:	04c92483          	lw	s1,76(s2)
    800040c0:	c49d                	beqz	s1,800040ee <dirlink+0x54>
    800040c2:	4481                	li	s1,0
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800040c4:	4741                	li	a4,16
    800040c6:	86a6                	mv	a3,s1
    800040c8:	fc040613          	addi	a2,s0,-64
    800040cc:	4581                	li	a1,0
    800040ce:	854a                	mv	a0,s2
    800040d0:	00000097          	auipc	ra,0x0
    800040d4:	b8a080e7          	jalr	-1142(ra) # 80003c5a <readi>
    800040d8:	47c1                	li	a5,16
    800040da:	06f51163          	bne	a0,a5,8000413c <dirlink+0xa2>
    if(de.inum == 0)
    800040de:	fc045783          	lhu	a5,-64(s0)
    800040e2:	c791                	beqz	a5,800040ee <dirlink+0x54>
  for(off = 0; off < dp->size; off += sizeof(de)){
    800040e4:	24c1                	addiw	s1,s1,16
    800040e6:	04c92783          	lw	a5,76(s2)
    800040ea:	fcf4ede3          	bltu	s1,a5,800040c4 <dirlink+0x2a>
  strncpy(de.name, name, DIRSIZ);
    800040ee:	4639                	li	a2,14
    800040f0:	85d2                	mv	a1,s4
    800040f2:	fc240513          	addi	a0,s0,-62
    800040f6:	ffffd097          	auipc	ra,0xffffd
    800040fa:	f68080e7          	jalr	-152(ra) # 8000105e <strncpy>
  de.inum = inum;
    800040fe:	fd341023          	sh	s3,-64(s0)
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80004102:	4741                	li	a4,16
    80004104:	86a6                	mv	a3,s1
    80004106:	fc040613          	addi	a2,s0,-64
    8000410a:	4581                	li	a1,0
    8000410c:	854a                	mv	a0,s2
    8000410e:	00000097          	auipc	ra,0x0
    80004112:	c44080e7          	jalr	-956(ra) # 80003d52 <writei>
    80004116:	872a                	mv	a4,a0
    80004118:	47c1                	li	a5,16
  return 0;
    8000411a:	4501                	li	a0,0
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    8000411c:	02f71863          	bne	a4,a5,8000414c <dirlink+0xb2>
}
    80004120:	70e2                	ld	ra,56(sp)
    80004122:	7442                	ld	s0,48(sp)
    80004124:	74a2                	ld	s1,40(sp)
    80004126:	7902                	ld	s2,32(sp)
    80004128:	69e2                	ld	s3,24(sp)
    8000412a:	6a42                	ld	s4,16(sp)
    8000412c:	6121                	addi	sp,sp,64
    8000412e:	8082                	ret
    iput(ip);
    80004130:	00000097          	auipc	ra,0x0
    80004134:	a30080e7          	jalr	-1488(ra) # 80003b60 <iput>
    return -1;
    80004138:	557d                	li	a0,-1
    8000413a:	b7dd                	j	80004120 <dirlink+0x86>
      panic("dirlink read");
    8000413c:	00004517          	auipc	a0,0x4
    80004140:	5bc50513          	addi	a0,a0,1468 # 800086f8 <syscalls+0x1d8>
    80004144:	ffffc097          	auipc	ra,0xffffc
    80004148:	3fa080e7          	jalr	1018(ra) # 8000053e <panic>
    panic("dirlink");
    8000414c:	00004517          	auipc	a0,0x4
    80004150:	6bc50513          	addi	a0,a0,1724 # 80008808 <syscalls+0x2e8>
    80004154:	ffffc097          	auipc	ra,0xffffc
    80004158:	3ea080e7          	jalr	1002(ra) # 8000053e <panic>

000000008000415c <namei>:

struct inode*
namei(char *path)
{
    8000415c:	1101                	addi	sp,sp,-32
    8000415e:	ec06                	sd	ra,24(sp)
    80004160:	e822                	sd	s0,16(sp)
    80004162:	1000                	addi	s0,sp,32
  char name[DIRSIZ];
  return namex(path, 0, name);
    80004164:	fe040613          	addi	a2,s0,-32
    80004168:	4581                	li	a1,0
    8000416a:	00000097          	auipc	ra,0x0
    8000416e:	dd0080e7          	jalr	-560(ra) # 80003f3a <namex>
}
    80004172:	60e2                	ld	ra,24(sp)
    80004174:	6442                	ld	s0,16(sp)
    80004176:	6105                	addi	sp,sp,32
    80004178:	8082                	ret

000000008000417a <nameiparent>:

struct inode*
nameiparent(char *path, char *name)
{
    8000417a:	1141                	addi	sp,sp,-16
    8000417c:	e406                	sd	ra,8(sp)
    8000417e:	e022                	sd	s0,0(sp)
    80004180:	0800                	addi	s0,sp,16
    80004182:	862e                	mv	a2,a1
  return namex(path, 1, name);
    80004184:	4585                	li	a1,1
    80004186:	00000097          	auipc	ra,0x0
    8000418a:	db4080e7          	jalr	-588(ra) # 80003f3a <namex>
}
    8000418e:	60a2                	ld	ra,8(sp)
    80004190:	6402                	ld	s0,0(sp)
    80004192:	0141                	addi	sp,sp,16
    80004194:	8082                	ret

0000000080004196 <write_head>:
// Write in-memory log header to disk.
// This is the true point at which the
// current transaction commits.
static void
write_head(void)
{
    80004196:	1101                	addi	sp,sp,-32
    80004198:	ec06                	sd	ra,24(sp)
    8000419a:	e822                	sd	s0,16(sp)
    8000419c:	e426                	sd	s1,8(sp)
    8000419e:	e04a                	sd	s2,0(sp)
    800041a0:	1000                	addi	s0,sp,32
  struct buf *buf = bread(log.dev, log.start);
    800041a2:	0089d917          	auipc	s2,0x89d
    800041a6:	4ce90913          	addi	s2,s2,1230 # 808a1670 <log>
    800041aa:	01892583          	lw	a1,24(s2)
    800041ae:	02892503          	lw	a0,40(s2)
    800041b2:	fffff097          	auipc	ra,0xfffff
    800041b6:	ff2080e7          	jalr	-14(ra) # 800031a4 <bread>
    800041ba:	84aa                	mv	s1,a0
  struct logheader *hb = (struct logheader *) (buf->data);
  int i;
  hb->n = log.lh.n;
    800041bc:	02c92683          	lw	a3,44(s2)
    800041c0:	cd34                	sw	a3,88(a0)
  for (i = 0; i < log.lh.n; i++) {
    800041c2:	02d05763          	blez	a3,800041f0 <write_head+0x5a>
    800041c6:	0089d797          	auipc	a5,0x89d
    800041ca:	4da78793          	addi	a5,a5,1242 # 808a16a0 <log+0x30>
    800041ce:	05c50713          	addi	a4,a0,92
    800041d2:	36fd                	addiw	a3,a3,-1
    800041d4:	1682                	slli	a3,a3,0x20
    800041d6:	9281                	srli	a3,a3,0x20
    800041d8:	068a                	slli	a3,a3,0x2
    800041da:	0089d617          	auipc	a2,0x89d
    800041de:	4ca60613          	addi	a2,a2,1226 # 808a16a4 <log+0x34>
    800041e2:	96b2                	add	a3,a3,a2
    hb->block[i] = log.lh.block[i];
    800041e4:	4390                	lw	a2,0(a5)
    800041e6:	c310                	sw	a2,0(a4)
  for (i = 0; i < log.lh.n; i++) {
    800041e8:	0791                	addi	a5,a5,4
    800041ea:	0711                	addi	a4,a4,4
    800041ec:	fed79ce3          	bne	a5,a3,800041e4 <write_head+0x4e>
  }
  bwrite(buf);
    800041f0:	8526                	mv	a0,s1
    800041f2:	fffff097          	auipc	ra,0xfffff
    800041f6:	0a4080e7          	jalr	164(ra) # 80003296 <bwrite>
  brelse(buf);
    800041fa:	8526                	mv	a0,s1
    800041fc:	fffff097          	auipc	ra,0xfffff
    80004200:	0d8080e7          	jalr	216(ra) # 800032d4 <brelse>
}
    80004204:	60e2                	ld	ra,24(sp)
    80004206:	6442                	ld	s0,16(sp)
    80004208:	64a2                	ld	s1,8(sp)
    8000420a:	6902                	ld	s2,0(sp)
    8000420c:	6105                	addi	sp,sp,32
    8000420e:	8082                	ret

0000000080004210 <install_trans>:
  for (tail = 0; tail < log.lh.n; tail++) {
    80004210:	0089d797          	auipc	a5,0x89d
    80004214:	48c7a783          	lw	a5,1164(a5) # 808a169c <log+0x2c>
    80004218:	0af05d63          	blez	a5,800042d2 <install_trans+0xc2>
{
    8000421c:	7139                	addi	sp,sp,-64
    8000421e:	fc06                	sd	ra,56(sp)
    80004220:	f822                	sd	s0,48(sp)
    80004222:	f426                	sd	s1,40(sp)
    80004224:	f04a                	sd	s2,32(sp)
    80004226:	ec4e                	sd	s3,24(sp)
    80004228:	e852                	sd	s4,16(sp)
    8000422a:	e456                	sd	s5,8(sp)
    8000422c:	e05a                	sd	s6,0(sp)
    8000422e:	0080                	addi	s0,sp,64
    80004230:	8b2a                	mv	s6,a0
    80004232:	0089da97          	auipc	s5,0x89d
    80004236:	46ea8a93          	addi	s5,s5,1134 # 808a16a0 <log+0x30>
  for (tail = 0; tail < log.lh.n; tail++) {
    8000423a:	4a01                	li	s4,0
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    8000423c:	0089d997          	auipc	s3,0x89d
    80004240:	43498993          	addi	s3,s3,1076 # 808a1670 <log>
    80004244:	a035                	j	80004270 <install_trans+0x60>
      bunpin(dbuf);
    80004246:	8526                	mv	a0,s1
    80004248:	fffff097          	auipc	ra,0xfffff
    8000424c:	166080e7          	jalr	358(ra) # 800033ae <bunpin>
    brelse(lbuf);
    80004250:	854a                	mv	a0,s2
    80004252:	fffff097          	auipc	ra,0xfffff
    80004256:	082080e7          	jalr	130(ra) # 800032d4 <brelse>
    brelse(dbuf);
    8000425a:	8526                	mv	a0,s1
    8000425c:	fffff097          	auipc	ra,0xfffff
    80004260:	078080e7          	jalr	120(ra) # 800032d4 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004264:	2a05                	addiw	s4,s4,1
    80004266:	0a91                	addi	s5,s5,4
    80004268:	02c9a783          	lw	a5,44(s3)
    8000426c:	04fa5963          	bge	s4,a5,800042be <install_trans+0xae>
    struct buf *lbuf = bread(log.dev, log.start+tail+1); // read log block
    80004270:	0189a583          	lw	a1,24(s3)
    80004274:	014585bb          	addw	a1,a1,s4
    80004278:	2585                	addiw	a1,a1,1
    8000427a:	0289a503          	lw	a0,40(s3)
    8000427e:	fffff097          	auipc	ra,0xfffff
    80004282:	f26080e7          	jalr	-218(ra) # 800031a4 <bread>
    80004286:	892a                	mv	s2,a0
    struct buf *dbuf = bread(log.dev, log.lh.block[tail]); // read dst
    80004288:	000aa583          	lw	a1,0(s5)
    8000428c:	0289a503          	lw	a0,40(s3)
    80004290:	fffff097          	auipc	ra,0xfffff
    80004294:	f14080e7          	jalr	-236(ra) # 800031a4 <bread>
    80004298:	84aa                	mv	s1,a0
    memmove(dbuf->data, lbuf->data, BSIZE);  // copy block to dst
    8000429a:	40000613          	li	a2,1024
    8000429e:	05890593          	addi	a1,s2,88
    800042a2:	05850513          	addi	a0,a0,88
    800042a6:	ffffd097          	auipc	ra,0xffffd
    800042aa:	d04080e7          	jalr	-764(ra) # 80000faa <memmove>
    bwrite(dbuf);  // write dst to disk
    800042ae:	8526                	mv	a0,s1
    800042b0:	fffff097          	auipc	ra,0xfffff
    800042b4:	fe6080e7          	jalr	-26(ra) # 80003296 <bwrite>
    if(recovering == 0)
    800042b8:	f80b1ce3          	bnez	s6,80004250 <install_trans+0x40>
    800042bc:	b769                	j	80004246 <install_trans+0x36>
}
    800042be:	70e2                	ld	ra,56(sp)
    800042c0:	7442                	ld	s0,48(sp)
    800042c2:	74a2                	ld	s1,40(sp)
    800042c4:	7902                	ld	s2,32(sp)
    800042c6:	69e2                	ld	s3,24(sp)
    800042c8:	6a42                	ld	s4,16(sp)
    800042ca:	6aa2                	ld	s5,8(sp)
    800042cc:	6b02                	ld	s6,0(sp)
    800042ce:	6121                	addi	sp,sp,64
    800042d0:	8082                	ret
    800042d2:	8082                	ret

00000000800042d4 <initlog>:
{
    800042d4:	7179                	addi	sp,sp,-48
    800042d6:	f406                	sd	ra,40(sp)
    800042d8:	f022                	sd	s0,32(sp)
    800042da:	ec26                	sd	s1,24(sp)
    800042dc:	e84a                	sd	s2,16(sp)
    800042de:	e44e                	sd	s3,8(sp)
    800042e0:	1800                	addi	s0,sp,48
    800042e2:	892a                	mv	s2,a0
    800042e4:	89ae                	mv	s3,a1
  initlock(&log.lock, "log");
    800042e6:	0089d497          	auipc	s1,0x89d
    800042ea:	38a48493          	addi	s1,s1,906 # 808a1670 <log>
    800042ee:	00004597          	auipc	a1,0x4
    800042f2:	41a58593          	addi	a1,a1,1050 # 80008708 <syscalls+0x1e8>
    800042f6:	8526                	mv	a0,s1
    800042f8:	ffffd097          	auipc	ra,0xffffd
    800042fc:	ac6080e7          	jalr	-1338(ra) # 80000dbe <initlock>
  log.start = sb->logstart;
    80004300:	0149a583          	lw	a1,20(s3)
    80004304:	cc8c                	sw	a1,24(s1)
  log.size = sb->nlog;
    80004306:	0109a783          	lw	a5,16(s3)
    8000430a:	ccdc                	sw	a5,28(s1)
  log.dev = dev;
    8000430c:	0324a423          	sw	s2,40(s1)
  struct buf *buf = bread(log.dev, log.start);
    80004310:	854a                	mv	a0,s2
    80004312:	fffff097          	auipc	ra,0xfffff
    80004316:	e92080e7          	jalr	-366(ra) # 800031a4 <bread>
  log.lh.n = lh->n;
    8000431a:	4d3c                	lw	a5,88(a0)
    8000431c:	d4dc                	sw	a5,44(s1)
  for (i = 0; i < log.lh.n; i++) {
    8000431e:	02f05563          	blez	a5,80004348 <initlog+0x74>
    80004322:	05c50713          	addi	a4,a0,92
    80004326:	0089d697          	auipc	a3,0x89d
    8000432a:	37a68693          	addi	a3,a3,890 # 808a16a0 <log+0x30>
    8000432e:	37fd                	addiw	a5,a5,-1
    80004330:	1782                	slli	a5,a5,0x20
    80004332:	9381                	srli	a5,a5,0x20
    80004334:	078a                	slli	a5,a5,0x2
    80004336:	06050613          	addi	a2,a0,96
    8000433a:	97b2                	add	a5,a5,a2
    log.lh.block[i] = lh->block[i];
    8000433c:	4310                	lw	a2,0(a4)
    8000433e:	c290                	sw	a2,0(a3)
  for (i = 0; i < log.lh.n; i++) {
    80004340:	0711                	addi	a4,a4,4
    80004342:	0691                	addi	a3,a3,4
    80004344:	fef71ce3          	bne	a4,a5,8000433c <initlog+0x68>
  brelse(buf);
    80004348:	fffff097          	auipc	ra,0xfffff
    8000434c:	f8c080e7          	jalr	-116(ra) # 800032d4 <brelse>

static void
recover_from_log(void)
{
  read_head();
  install_trans(1); // if committed, copy from log to disk
    80004350:	4505                	li	a0,1
    80004352:	00000097          	auipc	ra,0x0
    80004356:	ebe080e7          	jalr	-322(ra) # 80004210 <install_trans>
  log.lh.n = 0;
    8000435a:	0089d797          	auipc	a5,0x89d
    8000435e:	3407a123          	sw	zero,834(a5) # 808a169c <log+0x2c>
  write_head(); // clear the log
    80004362:	00000097          	auipc	ra,0x0
    80004366:	e34080e7          	jalr	-460(ra) # 80004196 <write_head>
}
    8000436a:	70a2                	ld	ra,40(sp)
    8000436c:	7402                	ld	s0,32(sp)
    8000436e:	64e2                	ld	s1,24(sp)
    80004370:	6942                	ld	s2,16(sp)
    80004372:	69a2                	ld	s3,8(sp)
    80004374:	6145                	addi	sp,sp,48
    80004376:	8082                	ret

0000000080004378 <begin_op>:
}

// called at the start of each FS system call.
void
begin_op(void)
{
    80004378:	1101                	addi	sp,sp,-32
    8000437a:	ec06                	sd	ra,24(sp)
    8000437c:	e822                	sd	s0,16(sp)
    8000437e:	e426                	sd	s1,8(sp)
    80004380:	e04a                	sd	s2,0(sp)
    80004382:	1000                	addi	s0,sp,32
  acquire(&log.lock);
    80004384:	0089d517          	auipc	a0,0x89d
    80004388:	2ec50513          	addi	a0,a0,748 # 808a1670 <log>
    8000438c:	ffffd097          	auipc	ra,0xffffd
    80004390:	ac2080e7          	jalr	-1342(ra) # 80000e4e <acquire>
  while(1){
    if(log.committing){
    80004394:	0089d497          	auipc	s1,0x89d
    80004398:	2dc48493          	addi	s1,s1,732 # 808a1670 <log>
      sleep(&log, &log.lock);
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    8000439c:	4979                	li	s2,30
    8000439e:	a039                	j	800043ac <begin_op+0x34>
      sleep(&log, &log.lock);
    800043a0:	85a6                	mv	a1,s1
    800043a2:	8526                	mv	a0,s1
    800043a4:	ffffe097          	auipc	ra,0xffffe
    800043a8:	f3e080e7          	jalr	-194(ra) # 800022e2 <sleep>
    if(log.committing){
    800043ac:	50dc                	lw	a5,36(s1)
    800043ae:	fbed                	bnez	a5,800043a0 <begin_op+0x28>
    } else if(log.lh.n + (log.outstanding+1)*MAXOPBLOCKS > LOGSIZE){
    800043b0:	509c                	lw	a5,32(s1)
    800043b2:	0017871b          	addiw	a4,a5,1
    800043b6:	0007069b          	sext.w	a3,a4
    800043ba:	0027179b          	slliw	a5,a4,0x2
    800043be:	9fb9                	addw	a5,a5,a4
    800043c0:	0017979b          	slliw	a5,a5,0x1
    800043c4:	54d8                	lw	a4,44(s1)
    800043c6:	9fb9                	addw	a5,a5,a4
    800043c8:	00f95963          	bge	s2,a5,800043da <begin_op+0x62>
      // this op might exhaust log space; wait for commit.
      sleep(&log, &log.lock);
    800043cc:	85a6                	mv	a1,s1
    800043ce:	8526                	mv	a0,s1
    800043d0:	ffffe097          	auipc	ra,0xffffe
    800043d4:	f12080e7          	jalr	-238(ra) # 800022e2 <sleep>
    800043d8:	bfd1                	j	800043ac <begin_op+0x34>
    } else {
      log.outstanding += 1;
    800043da:	0089d517          	auipc	a0,0x89d
    800043de:	29650513          	addi	a0,a0,662 # 808a1670 <log>
    800043e2:	d114                	sw	a3,32(a0)
      release(&log.lock);
    800043e4:	ffffd097          	auipc	ra,0xffffd
    800043e8:	b1e080e7          	jalr	-1250(ra) # 80000f02 <release>
      break;
    }
  }
}
    800043ec:	60e2                	ld	ra,24(sp)
    800043ee:	6442                	ld	s0,16(sp)
    800043f0:	64a2                	ld	s1,8(sp)
    800043f2:	6902                	ld	s2,0(sp)
    800043f4:	6105                	addi	sp,sp,32
    800043f6:	8082                	ret

00000000800043f8 <end_op>:

// called at the end of each FS system call.
// commits if this was the last outstanding operation.
void
end_op(void)
{
    800043f8:	7139                	addi	sp,sp,-64
    800043fa:	fc06                	sd	ra,56(sp)
    800043fc:	f822                	sd	s0,48(sp)
    800043fe:	f426                	sd	s1,40(sp)
    80004400:	f04a                	sd	s2,32(sp)
    80004402:	ec4e                	sd	s3,24(sp)
    80004404:	e852                	sd	s4,16(sp)
    80004406:	e456                	sd	s5,8(sp)
    80004408:	0080                	addi	s0,sp,64
  int do_commit = 0;

  acquire(&log.lock);
    8000440a:	0089d497          	auipc	s1,0x89d
    8000440e:	26648493          	addi	s1,s1,614 # 808a1670 <log>
    80004412:	8526                	mv	a0,s1
    80004414:	ffffd097          	auipc	ra,0xffffd
    80004418:	a3a080e7          	jalr	-1478(ra) # 80000e4e <acquire>
  log.outstanding -= 1;
    8000441c:	509c                	lw	a5,32(s1)
    8000441e:	37fd                	addiw	a5,a5,-1
    80004420:	0007891b          	sext.w	s2,a5
    80004424:	d09c                	sw	a5,32(s1)
  if(log.committing)
    80004426:	50dc                	lw	a5,36(s1)
    80004428:	efb9                	bnez	a5,80004486 <end_op+0x8e>
    panic("log.committing");
  if(log.outstanding == 0){
    8000442a:	06091663          	bnez	s2,80004496 <end_op+0x9e>
    do_commit = 1;
    log.committing = 1;
    8000442e:	0089d497          	auipc	s1,0x89d
    80004432:	24248493          	addi	s1,s1,578 # 808a1670 <log>
    80004436:	4785                	li	a5,1
    80004438:	d0dc                	sw	a5,36(s1)
    // begin_op() may be waiting for log space,
    // and decrementing log.outstanding has decreased
    // the amount of reserved space.
    wakeup(&log);
  }
  release(&log.lock);
    8000443a:	8526                	mv	a0,s1
    8000443c:	ffffd097          	auipc	ra,0xffffd
    80004440:	ac6080e7          	jalr	-1338(ra) # 80000f02 <release>
}

static void
commit()
{
  if (log.lh.n > 0) {
    80004444:	54dc                	lw	a5,44(s1)
    80004446:	06f04763          	bgtz	a5,800044b4 <end_op+0xbc>
    acquire(&log.lock);
    8000444a:	0089d497          	auipc	s1,0x89d
    8000444e:	22648493          	addi	s1,s1,550 # 808a1670 <log>
    80004452:	8526                	mv	a0,s1
    80004454:	ffffd097          	auipc	ra,0xffffd
    80004458:	9fa080e7          	jalr	-1542(ra) # 80000e4e <acquire>
    log.committing = 0;
    8000445c:	0204a223          	sw	zero,36(s1)
    wakeup(&log);
    80004460:	8526                	mv	a0,s1
    80004462:	ffffe097          	auipc	ra,0xffffe
    80004466:	00c080e7          	jalr	12(ra) # 8000246e <wakeup>
    release(&log.lock);
    8000446a:	8526                	mv	a0,s1
    8000446c:	ffffd097          	auipc	ra,0xffffd
    80004470:	a96080e7          	jalr	-1386(ra) # 80000f02 <release>
}
    80004474:	70e2                	ld	ra,56(sp)
    80004476:	7442                	ld	s0,48(sp)
    80004478:	74a2                	ld	s1,40(sp)
    8000447a:	7902                	ld	s2,32(sp)
    8000447c:	69e2                	ld	s3,24(sp)
    8000447e:	6a42                	ld	s4,16(sp)
    80004480:	6aa2                	ld	s5,8(sp)
    80004482:	6121                	addi	sp,sp,64
    80004484:	8082                	ret
    panic("log.committing");
    80004486:	00004517          	auipc	a0,0x4
    8000448a:	28a50513          	addi	a0,a0,650 # 80008710 <syscalls+0x1f0>
    8000448e:	ffffc097          	auipc	ra,0xffffc
    80004492:	0b0080e7          	jalr	176(ra) # 8000053e <panic>
    wakeup(&log);
    80004496:	0089d497          	auipc	s1,0x89d
    8000449a:	1da48493          	addi	s1,s1,474 # 808a1670 <log>
    8000449e:	8526                	mv	a0,s1
    800044a0:	ffffe097          	auipc	ra,0xffffe
    800044a4:	fce080e7          	jalr	-50(ra) # 8000246e <wakeup>
  release(&log.lock);
    800044a8:	8526                	mv	a0,s1
    800044aa:	ffffd097          	auipc	ra,0xffffd
    800044ae:	a58080e7          	jalr	-1448(ra) # 80000f02 <release>
  if(do_commit){
    800044b2:	b7c9                	j	80004474 <end_op+0x7c>
  for (tail = 0; tail < log.lh.n; tail++) {
    800044b4:	0089da97          	auipc	s5,0x89d
    800044b8:	1eca8a93          	addi	s5,s5,492 # 808a16a0 <log+0x30>
    struct buf *to = bread(log.dev, log.start+tail+1); // log block
    800044bc:	0089da17          	auipc	s4,0x89d
    800044c0:	1b4a0a13          	addi	s4,s4,436 # 808a1670 <log>
    800044c4:	018a2583          	lw	a1,24(s4)
    800044c8:	012585bb          	addw	a1,a1,s2
    800044cc:	2585                	addiw	a1,a1,1
    800044ce:	028a2503          	lw	a0,40(s4)
    800044d2:	fffff097          	auipc	ra,0xfffff
    800044d6:	cd2080e7          	jalr	-814(ra) # 800031a4 <bread>
    800044da:	84aa                	mv	s1,a0
    struct buf *from = bread(log.dev, log.lh.block[tail]); // cache block
    800044dc:	000aa583          	lw	a1,0(s5)
    800044e0:	028a2503          	lw	a0,40(s4)
    800044e4:	fffff097          	auipc	ra,0xfffff
    800044e8:	cc0080e7          	jalr	-832(ra) # 800031a4 <bread>
    800044ec:	89aa                	mv	s3,a0
    memmove(to->data, from->data, BSIZE);
    800044ee:	40000613          	li	a2,1024
    800044f2:	05850593          	addi	a1,a0,88
    800044f6:	05848513          	addi	a0,s1,88
    800044fa:	ffffd097          	auipc	ra,0xffffd
    800044fe:	ab0080e7          	jalr	-1360(ra) # 80000faa <memmove>
    bwrite(to);  // write the log
    80004502:	8526                	mv	a0,s1
    80004504:	fffff097          	auipc	ra,0xfffff
    80004508:	d92080e7          	jalr	-622(ra) # 80003296 <bwrite>
    brelse(from);
    8000450c:	854e                	mv	a0,s3
    8000450e:	fffff097          	auipc	ra,0xfffff
    80004512:	dc6080e7          	jalr	-570(ra) # 800032d4 <brelse>
    brelse(to);
    80004516:	8526                	mv	a0,s1
    80004518:	fffff097          	auipc	ra,0xfffff
    8000451c:	dbc080e7          	jalr	-580(ra) # 800032d4 <brelse>
  for (tail = 0; tail < log.lh.n; tail++) {
    80004520:	2905                	addiw	s2,s2,1
    80004522:	0a91                	addi	s5,s5,4
    80004524:	02ca2783          	lw	a5,44(s4)
    80004528:	f8f94ee3          	blt	s2,a5,800044c4 <end_op+0xcc>
    write_log();     // Write modified blocks from cache to log
    write_head();    // Write header to disk -- the real commit
    8000452c:	00000097          	auipc	ra,0x0
    80004530:	c6a080e7          	jalr	-918(ra) # 80004196 <write_head>
    install_trans(0); // Now install writes to home locations
    80004534:	4501                	li	a0,0
    80004536:	00000097          	auipc	ra,0x0
    8000453a:	cda080e7          	jalr	-806(ra) # 80004210 <install_trans>
    log.lh.n = 0;
    8000453e:	0089d797          	auipc	a5,0x89d
    80004542:	1407af23          	sw	zero,350(a5) # 808a169c <log+0x2c>
    write_head();    // Erase the transaction from the log
    80004546:	00000097          	auipc	ra,0x0
    8000454a:	c50080e7          	jalr	-944(ra) # 80004196 <write_head>
    8000454e:	bdf5                	j	8000444a <end_op+0x52>

0000000080004550 <log_write>:
//   modify bp->data[]
//   log_write(bp)
//   brelse(bp)
void
log_write(struct buf *b)
{
    80004550:	1101                	addi	sp,sp,-32
    80004552:	ec06                	sd	ra,24(sp)
    80004554:	e822                	sd	s0,16(sp)
    80004556:	e426                	sd	s1,8(sp)
    80004558:	e04a                	sd	s2,0(sp)
    8000455a:	1000                	addi	s0,sp,32
    8000455c:	84aa                	mv	s1,a0
  int i;

  acquire(&log.lock);
    8000455e:	0089d917          	auipc	s2,0x89d
    80004562:	11290913          	addi	s2,s2,274 # 808a1670 <log>
    80004566:	854a                	mv	a0,s2
    80004568:	ffffd097          	auipc	ra,0xffffd
    8000456c:	8e6080e7          	jalr	-1818(ra) # 80000e4e <acquire>
  if (log.lh.n >= LOGSIZE || log.lh.n >= log.size - 1)
    80004570:	02c92603          	lw	a2,44(s2)
    80004574:	47f5                	li	a5,29
    80004576:	06c7c563          	blt	a5,a2,800045e0 <log_write+0x90>
    8000457a:	0089d797          	auipc	a5,0x89d
    8000457e:	1127a783          	lw	a5,274(a5) # 808a168c <log+0x1c>
    80004582:	37fd                	addiw	a5,a5,-1
    80004584:	04f65e63          	bge	a2,a5,800045e0 <log_write+0x90>
    panic("too big a transaction");
  if (log.outstanding < 1)
    80004588:	0089d797          	auipc	a5,0x89d
    8000458c:	1087a783          	lw	a5,264(a5) # 808a1690 <log+0x20>
    80004590:	06f05063          	blez	a5,800045f0 <log_write+0xa0>
    panic("log_write outside of trans");

  for (i = 0; i < log.lh.n; i++) {
    80004594:	4781                	li	a5,0
    80004596:	06c05563          	blez	a2,80004600 <log_write+0xb0>
    if (log.lh.block[i] == b->blockno)   // log absorption
    8000459a:	44cc                	lw	a1,12(s1)
    8000459c:	0089d717          	auipc	a4,0x89d
    800045a0:	10470713          	addi	a4,a4,260 # 808a16a0 <log+0x30>
  for (i = 0; i < log.lh.n; i++) {
    800045a4:	4781                	li	a5,0
    if (log.lh.block[i] == b->blockno)   // log absorption
    800045a6:	4314                	lw	a3,0(a4)
    800045a8:	04b68c63          	beq	a3,a1,80004600 <log_write+0xb0>
  for (i = 0; i < log.lh.n; i++) {
    800045ac:	2785                	addiw	a5,a5,1
    800045ae:	0711                	addi	a4,a4,4
    800045b0:	fef61be3          	bne	a2,a5,800045a6 <log_write+0x56>
      break;
  }
  log.lh.block[i] = b->blockno;
    800045b4:	0621                	addi	a2,a2,8
    800045b6:	060a                	slli	a2,a2,0x2
    800045b8:	0089d797          	auipc	a5,0x89d
    800045bc:	0b878793          	addi	a5,a5,184 # 808a1670 <log>
    800045c0:	963e                	add	a2,a2,a5
    800045c2:	44dc                	lw	a5,12(s1)
    800045c4:	ca1c                	sw	a5,16(a2)
  if (i == log.lh.n) {  // Add new block to log?
    bpin(b);
    800045c6:	8526                	mv	a0,s1
    800045c8:	fffff097          	auipc	ra,0xfffff
    800045cc:	daa080e7          	jalr	-598(ra) # 80003372 <bpin>
    log.lh.n++;
    800045d0:	0089d717          	auipc	a4,0x89d
    800045d4:	0a070713          	addi	a4,a4,160 # 808a1670 <log>
    800045d8:	575c                	lw	a5,44(a4)
    800045da:	2785                	addiw	a5,a5,1
    800045dc:	d75c                	sw	a5,44(a4)
    800045de:	a835                	j	8000461a <log_write+0xca>
    panic("too big a transaction");
    800045e0:	00004517          	auipc	a0,0x4
    800045e4:	14050513          	addi	a0,a0,320 # 80008720 <syscalls+0x200>
    800045e8:	ffffc097          	auipc	ra,0xffffc
    800045ec:	f56080e7          	jalr	-170(ra) # 8000053e <panic>
    panic("log_write outside of trans");
    800045f0:	00004517          	auipc	a0,0x4
    800045f4:	14850513          	addi	a0,a0,328 # 80008738 <syscalls+0x218>
    800045f8:	ffffc097          	auipc	ra,0xffffc
    800045fc:	f46080e7          	jalr	-186(ra) # 8000053e <panic>
  log.lh.block[i] = b->blockno;
    80004600:	00878713          	addi	a4,a5,8
    80004604:	00271693          	slli	a3,a4,0x2
    80004608:	0089d717          	auipc	a4,0x89d
    8000460c:	06870713          	addi	a4,a4,104 # 808a1670 <log>
    80004610:	9736                	add	a4,a4,a3
    80004612:	44d4                	lw	a3,12(s1)
    80004614:	cb14                	sw	a3,16(a4)
  if (i == log.lh.n) {  // Add new block to log?
    80004616:	faf608e3          	beq	a2,a5,800045c6 <log_write+0x76>
  }
  release(&log.lock);
    8000461a:	0089d517          	auipc	a0,0x89d
    8000461e:	05650513          	addi	a0,a0,86 # 808a1670 <log>
    80004622:	ffffd097          	auipc	ra,0xffffd
    80004626:	8e0080e7          	jalr	-1824(ra) # 80000f02 <release>
}
    8000462a:	60e2                	ld	ra,24(sp)
    8000462c:	6442                	ld	s0,16(sp)
    8000462e:	64a2                	ld	s1,8(sp)
    80004630:	6902                	ld	s2,0(sp)
    80004632:	6105                	addi	sp,sp,32
    80004634:	8082                	ret

0000000080004636 <initsleeplock>:
#include "proc.h"
#include "sleeplock.h"

void
initsleeplock(struct sleeplock *lk, char *name)
{
    80004636:	1101                	addi	sp,sp,-32
    80004638:	ec06                	sd	ra,24(sp)
    8000463a:	e822                	sd	s0,16(sp)
    8000463c:	e426                	sd	s1,8(sp)
    8000463e:	e04a                	sd	s2,0(sp)
    80004640:	1000                	addi	s0,sp,32
    80004642:	84aa                	mv	s1,a0
    80004644:	892e                	mv	s2,a1
  initlock(&lk->lk, "sleep lock");
    80004646:	00004597          	auipc	a1,0x4
    8000464a:	11258593          	addi	a1,a1,274 # 80008758 <syscalls+0x238>
    8000464e:	0521                	addi	a0,a0,8
    80004650:	ffffc097          	auipc	ra,0xffffc
    80004654:	76e080e7          	jalr	1902(ra) # 80000dbe <initlock>
  lk->name = name;
    80004658:	0324b023          	sd	s2,32(s1)
  lk->locked = 0;
    8000465c:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    80004660:	0204a423          	sw	zero,40(s1)
}
    80004664:	60e2                	ld	ra,24(sp)
    80004666:	6442                	ld	s0,16(sp)
    80004668:	64a2                	ld	s1,8(sp)
    8000466a:	6902                	ld	s2,0(sp)
    8000466c:	6105                	addi	sp,sp,32
    8000466e:	8082                	ret

0000000080004670 <acquiresleep>:

void
acquiresleep(struct sleeplock *lk)
{
    80004670:	1101                	addi	sp,sp,-32
    80004672:	ec06                	sd	ra,24(sp)
    80004674:	e822                	sd	s0,16(sp)
    80004676:	e426                	sd	s1,8(sp)
    80004678:	e04a                	sd	s2,0(sp)
    8000467a:	1000                	addi	s0,sp,32
    8000467c:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    8000467e:	00850913          	addi	s2,a0,8
    80004682:	854a                	mv	a0,s2
    80004684:	ffffc097          	auipc	ra,0xffffc
    80004688:	7ca080e7          	jalr	1994(ra) # 80000e4e <acquire>
  while (lk->locked) {
    8000468c:	409c                	lw	a5,0(s1)
    8000468e:	cb89                	beqz	a5,800046a0 <acquiresleep+0x30>
    sleep(lk, &lk->lk);
    80004690:	85ca                	mv	a1,s2
    80004692:	8526                	mv	a0,s1
    80004694:	ffffe097          	auipc	ra,0xffffe
    80004698:	c4e080e7          	jalr	-946(ra) # 800022e2 <sleep>
  while (lk->locked) {
    8000469c:	409c                	lw	a5,0(s1)
    8000469e:	fbed                	bnez	a5,80004690 <acquiresleep+0x20>
  }
  lk->locked = 1;
    800046a0:	4785                	li	a5,1
    800046a2:	c09c                	sw	a5,0(s1)
  lk->pid = myproc()->pid;
    800046a4:	ffffd097          	auipc	ra,0xffffd
    800046a8:	576080e7          	jalr	1398(ra) # 80001c1a <myproc>
    800046ac:	591c                	lw	a5,48(a0)
    800046ae:	d49c                	sw	a5,40(s1)
  release(&lk->lk);
    800046b0:	854a                	mv	a0,s2
    800046b2:	ffffd097          	auipc	ra,0xffffd
    800046b6:	850080e7          	jalr	-1968(ra) # 80000f02 <release>
}
    800046ba:	60e2                	ld	ra,24(sp)
    800046bc:	6442                	ld	s0,16(sp)
    800046be:	64a2                	ld	s1,8(sp)
    800046c0:	6902                	ld	s2,0(sp)
    800046c2:	6105                	addi	sp,sp,32
    800046c4:	8082                	ret

00000000800046c6 <releasesleep>:

void
releasesleep(struct sleeplock *lk)
{
    800046c6:	1101                	addi	sp,sp,-32
    800046c8:	ec06                	sd	ra,24(sp)
    800046ca:	e822                	sd	s0,16(sp)
    800046cc:	e426                	sd	s1,8(sp)
    800046ce:	e04a                	sd	s2,0(sp)
    800046d0:	1000                	addi	s0,sp,32
    800046d2:	84aa                	mv	s1,a0
  acquire(&lk->lk);
    800046d4:	00850913          	addi	s2,a0,8
    800046d8:	854a                	mv	a0,s2
    800046da:	ffffc097          	auipc	ra,0xffffc
    800046de:	774080e7          	jalr	1908(ra) # 80000e4e <acquire>
  lk->locked = 0;
    800046e2:	0004a023          	sw	zero,0(s1)
  lk->pid = 0;
    800046e6:	0204a423          	sw	zero,40(s1)
  wakeup(lk);
    800046ea:	8526                	mv	a0,s1
    800046ec:	ffffe097          	auipc	ra,0xffffe
    800046f0:	d82080e7          	jalr	-638(ra) # 8000246e <wakeup>
  release(&lk->lk);
    800046f4:	854a                	mv	a0,s2
    800046f6:	ffffd097          	auipc	ra,0xffffd
    800046fa:	80c080e7          	jalr	-2036(ra) # 80000f02 <release>
}
    800046fe:	60e2                	ld	ra,24(sp)
    80004700:	6442                	ld	s0,16(sp)
    80004702:	64a2                	ld	s1,8(sp)
    80004704:	6902                	ld	s2,0(sp)
    80004706:	6105                	addi	sp,sp,32
    80004708:	8082                	ret

000000008000470a <holdingsleep>:

int
holdingsleep(struct sleeplock *lk)
{
    8000470a:	7179                	addi	sp,sp,-48
    8000470c:	f406                	sd	ra,40(sp)
    8000470e:	f022                	sd	s0,32(sp)
    80004710:	ec26                	sd	s1,24(sp)
    80004712:	e84a                	sd	s2,16(sp)
    80004714:	e44e                	sd	s3,8(sp)
    80004716:	1800                	addi	s0,sp,48
    80004718:	84aa                	mv	s1,a0
  int r;
  
  acquire(&lk->lk);
    8000471a:	00850913          	addi	s2,a0,8
    8000471e:	854a                	mv	a0,s2
    80004720:	ffffc097          	auipc	ra,0xffffc
    80004724:	72e080e7          	jalr	1838(ra) # 80000e4e <acquire>
  r = lk->locked && (lk->pid == myproc()->pid);
    80004728:	409c                	lw	a5,0(s1)
    8000472a:	ef99                	bnez	a5,80004748 <holdingsleep+0x3e>
    8000472c:	4481                	li	s1,0
  release(&lk->lk);
    8000472e:	854a                	mv	a0,s2
    80004730:	ffffc097          	auipc	ra,0xffffc
    80004734:	7d2080e7          	jalr	2002(ra) # 80000f02 <release>
  return r;
}
    80004738:	8526                	mv	a0,s1
    8000473a:	70a2                	ld	ra,40(sp)
    8000473c:	7402                	ld	s0,32(sp)
    8000473e:	64e2                	ld	s1,24(sp)
    80004740:	6942                	ld	s2,16(sp)
    80004742:	69a2                	ld	s3,8(sp)
    80004744:	6145                	addi	sp,sp,48
    80004746:	8082                	ret
  r = lk->locked && (lk->pid == myproc()->pid);
    80004748:	0284a983          	lw	s3,40(s1)
    8000474c:	ffffd097          	auipc	ra,0xffffd
    80004750:	4ce080e7          	jalr	1230(ra) # 80001c1a <myproc>
    80004754:	5904                	lw	s1,48(a0)
    80004756:	413484b3          	sub	s1,s1,s3
    8000475a:	0014b493          	seqz	s1,s1
    8000475e:	bfc1                	j	8000472e <holdingsleep+0x24>

0000000080004760 <fileinit>:
  struct file file[NFILE];
} ftable;

void
fileinit(void)
{
    80004760:	1141                	addi	sp,sp,-16
    80004762:	e406                	sd	ra,8(sp)
    80004764:	e022                	sd	s0,0(sp)
    80004766:	0800                	addi	s0,sp,16
  initlock(&ftable.lock, "ftable");
    80004768:	00004597          	auipc	a1,0x4
    8000476c:	00058593          	mv	a1,a1
    80004770:	0089d517          	auipc	a0,0x89d
    80004774:	7e050513          	addi	a0,a0,2016 # 808a1f50 <ftable>
    80004778:	ffffc097          	auipc	ra,0xffffc
    8000477c:	646080e7          	jalr	1606(ra) # 80000dbe <initlock>
}
    80004780:	60a2                	ld	ra,8(sp)
    80004782:	6402                	ld	s0,0(sp)
    80004784:	0141                	addi	sp,sp,16
    80004786:	8082                	ret

0000000080004788 <filealloc>:

// Allocate a file structure.
struct file*
filealloc(void)
{
    80004788:	1101                	addi	sp,sp,-32
    8000478a:	ec06                	sd	ra,24(sp)
    8000478c:	e822                	sd	s0,16(sp)
    8000478e:	e426                	sd	s1,8(sp)
    80004790:	1000                	addi	s0,sp,32
  struct file *f;

  acquire(&ftable.lock);
    80004792:	0089d517          	auipc	a0,0x89d
    80004796:	7be50513          	addi	a0,a0,1982 # 808a1f50 <ftable>
    8000479a:	ffffc097          	auipc	ra,0xffffc
    8000479e:	6b4080e7          	jalr	1716(ra) # 80000e4e <acquire>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800047a2:	0089d497          	auipc	s1,0x89d
    800047a6:	7c648493          	addi	s1,s1,1990 # 808a1f68 <ftable+0x18>
    800047aa:	0089e717          	auipc	a4,0x89e
    800047ae:	75e70713          	addi	a4,a4,1886 # 808a2f08 <ftable+0xfb8>
    if(f->ref == 0){
    800047b2:	40dc                	lw	a5,4(s1)
    800047b4:	cf99                	beqz	a5,800047d2 <filealloc+0x4a>
  for(f = ftable.file; f < ftable.file + NFILE; f++){
    800047b6:	02848493          	addi	s1,s1,40
    800047ba:	fee49ce3          	bne	s1,a4,800047b2 <filealloc+0x2a>
      f->ref = 1;
      release(&ftable.lock);
      return f;
    }
  }
  release(&ftable.lock);
    800047be:	0089d517          	auipc	a0,0x89d
    800047c2:	79250513          	addi	a0,a0,1938 # 808a1f50 <ftable>
    800047c6:	ffffc097          	auipc	ra,0xffffc
    800047ca:	73c080e7          	jalr	1852(ra) # 80000f02 <release>
  return 0;
    800047ce:	4481                	li	s1,0
    800047d0:	a819                	j	800047e6 <filealloc+0x5e>
      f->ref = 1;
    800047d2:	4785                	li	a5,1
    800047d4:	c0dc                	sw	a5,4(s1)
      release(&ftable.lock);
    800047d6:	0089d517          	auipc	a0,0x89d
    800047da:	77a50513          	addi	a0,a0,1914 # 808a1f50 <ftable>
    800047de:	ffffc097          	auipc	ra,0xffffc
    800047e2:	724080e7          	jalr	1828(ra) # 80000f02 <release>
}
    800047e6:	8526                	mv	a0,s1
    800047e8:	60e2                	ld	ra,24(sp)
    800047ea:	6442                	ld	s0,16(sp)
    800047ec:	64a2                	ld	s1,8(sp)
    800047ee:	6105                	addi	sp,sp,32
    800047f0:	8082                	ret

00000000800047f2 <filedup>:

// Increment ref count for file f.
struct file*
filedup(struct file *f)
{
    800047f2:	1101                	addi	sp,sp,-32
    800047f4:	ec06                	sd	ra,24(sp)
    800047f6:	e822                	sd	s0,16(sp)
    800047f8:	e426                	sd	s1,8(sp)
    800047fa:	1000                	addi	s0,sp,32
    800047fc:	84aa                	mv	s1,a0
  acquire(&ftable.lock);
    800047fe:	0089d517          	auipc	a0,0x89d
    80004802:	75250513          	addi	a0,a0,1874 # 808a1f50 <ftable>
    80004806:	ffffc097          	auipc	ra,0xffffc
    8000480a:	648080e7          	jalr	1608(ra) # 80000e4e <acquire>
  if(f->ref < 1)
    8000480e:	40dc                	lw	a5,4(s1)
    80004810:	02f05263          	blez	a5,80004834 <filedup+0x42>
    panic("filedup");
  f->ref++;
    80004814:	2785                	addiw	a5,a5,1
    80004816:	c0dc                	sw	a5,4(s1)
  release(&ftable.lock);
    80004818:	0089d517          	auipc	a0,0x89d
    8000481c:	73850513          	addi	a0,a0,1848 # 808a1f50 <ftable>
    80004820:	ffffc097          	auipc	ra,0xffffc
    80004824:	6e2080e7          	jalr	1762(ra) # 80000f02 <release>
  return f;
}
    80004828:	8526                	mv	a0,s1
    8000482a:	60e2                	ld	ra,24(sp)
    8000482c:	6442                	ld	s0,16(sp)
    8000482e:	64a2                	ld	s1,8(sp)
    80004830:	6105                	addi	sp,sp,32
    80004832:	8082                	ret
    panic("filedup");
    80004834:	00004517          	auipc	a0,0x4
    80004838:	f3c50513          	addi	a0,a0,-196 # 80008770 <syscalls+0x250>
    8000483c:	ffffc097          	auipc	ra,0xffffc
    80004840:	d02080e7          	jalr	-766(ra) # 8000053e <panic>

0000000080004844 <fileclose>:

// Close file f.  (Decrement ref count, close when reaches 0.)
void
fileclose(struct file *f)
{
    80004844:	7139                	addi	sp,sp,-64
    80004846:	fc06                	sd	ra,56(sp)
    80004848:	f822                	sd	s0,48(sp)
    8000484a:	f426                	sd	s1,40(sp)
    8000484c:	f04a                	sd	s2,32(sp)
    8000484e:	ec4e                	sd	s3,24(sp)
    80004850:	e852                	sd	s4,16(sp)
    80004852:	e456                	sd	s5,8(sp)
    80004854:	0080                	addi	s0,sp,64
    80004856:	84aa                	mv	s1,a0
  struct file ff;

  acquire(&ftable.lock);
    80004858:	0089d517          	auipc	a0,0x89d
    8000485c:	6f850513          	addi	a0,a0,1784 # 808a1f50 <ftable>
    80004860:	ffffc097          	auipc	ra,0xffffc
    80004864:	5ee080e7          	jalr	1518(ra) # 80000e4e <acquire>
  if(f->ref < 1)
    80004868:	40dc                	lw	a5,4(s1)
    8000486a:	06f05163          	blez	a5,800048cc <fileclose+0x88>
    panic("fileclose");
  if(--f->ref > 0){
    8000486e:	37fd                	addiw	a5,a5,-1
    80004870:	0007871b          	sext.w	a4,a5
    80004874:	c0dc                	sw	a5,4(s1)
    80004876:	06e04363          	bgtz	a4,800048dc <fileclose+0x98>
    release(&ftable.lock);
    return;
  }
  ff = *f;
    8000487a:	0004a903          	lw	s2,0(s1)
    8000487e:	0094ca83          	lbu	s5,9(s1)
    80004882:	0104ba03          	ld	s4,16(s1)
    80004886:	0184b983          	ld	s3,24(s1)
  f->ref = 0;
    8000488a:	0004a223          	sw	zero,4(s1)
  f->type = FD_NONE;
    8000488e:	0004a023          	sw	zero,0(s1)
  release(&ftable.lock);
    80004892:	0089d517          	auipc	a0,0x89d
    80004896:	6be50513          	addi	a0,a0,1726 # 808a1f50 <ftable>
    8000489a:	ffffc097          	auipc	ra,0xffffc
    8000489e:	668080e7          	jalr	1640(ra) # 80000f02 <release>

  if(ff.type == FD_PIPE){
    800048a2:	4785                	li	a5,1
    800048a4:	04f90d63          	beq	s2,a5,800048fe <fileclose+0xba>
    pipeclose(ff.pipe, ff.writable);
  } else if(ff.type == FD_INODE || ff.type == FD_DEVICE){
    800048a8:	3979                	addiw	s2,s2,-2
    800048aa:	4785                	li	a5,1
    800048ac:	0527e063          	bltu	a5,s2,800048ec <fileclose+0xa8>
    begin_op();
    800048b0:	00000097          	auipc	ra,0x0
    800048b4:	ac8080e7          	jalr	-1336(ra) # 80004378 <begin_op>
    iput(ff.ip);
    800048b8:	854e                	mv	a0,s3
    800048ba:	fffff097          	auipc	ra,0xfffff
    800048be:	2a6080e7          	jalr	678(ra) # 80003b60 <iput>
    end_op();
    800048c2:	00000097          	auipc	ra,0x0
    800048c6:	b36080e7          	jalr	-1226(ra) # 800043f8 <end_op>
    800048ca:	a00d                	j	800048ec <fileclose+0xa8>
    panic("fileclose");
    800048cc:	00004517          	auipc	a0,0x4
    800048d0:	eac50513          	addi	a0,a0,-340 # 80008778 <syscalls+0x258>
    800048d4:	ffffc097          	auipc	ra,0xffffc
    800048d8:	c6a080e7          	jalr	-918(ra) # 8000053e <panic>
    release(&ftable.lock);
    800048dc:	0089d517          	auipc	a0,0x89d
    800048e0:	67450513          	addi	a0,a0,1652 # 808a1f50 <ftable>
    800048e4:	ffffc097          	auipc	ra,0xffffc
    800048e8:	61e080e7          	jalr	1566(ra) # 80000f02 <release>
  }
}
    800048ec:	70e2                	ld	ra,56(sp)
    800048ee:	7442                	ld	s0,48(sp)
    800048f0:	74a2                	ld	s1,40(sp)
    800048f2:	7902                	ld	s2,32(sp)
    800048f4:	69e2                	ld	s3,24(sp)
    800048f6:	6a42                	ld	s4,16(sp)
    800048f8:	6aa2                	ld	s5,8(sp)
    800048fa:	6121                	addi	sp,sp,64
    800048fc:	8082                	ret
    pipeclose(ff.pipe, ff.writable);
    800048fe:	85d6                	mv	a1,s5
    80004900:	8552                	mv	a0,s4
    80004902:	00000097          	auipc	ra,0x0
    80004906:	52a080e7          	jalr	1322(ra) # 80004e2c <pipeclose>
    8000490a:	b7cd                	j	800048ec <fileclose+0xa8>

000000008000490c <filestat>:

// Get metadata about file f.
// addr is a user virtual address, pointing to a struct stat.
int
filestat(struct file *f, uint64 addr)
{
    8000490c:	715d                	addi	sp,sp,-80
    8000490e:	e486                	sd	ra,72(sp)
    80004910:	e0a2                	sd	s0,64(sp)
    80004912:	fc26                	sd	s1,56(sp)
    80004914:	f84a                	sd	s2,48(sp)
    80004916:	f44e                	sd	s3,40(sp)
    80004918:	0880                	addi	s0,sp,80
    8000491a:	84aa                	mv	s1,a0
    8000491c:	89ae                	mv	s3,a1
  struct proc *p = myproc();
    8000491e:	ffffd097          	auipc	ra,0xffffd
    80004922:	2fc080e7          	jalr	764(ra) # 80001c1a <myproc>
  struct stat st;
  
  if(f->type == FD_INODE || f->type == FD_DEVICE){
    80004926:	409c                	lw	a5,0(s1)
    80004928:	37f9                	addiw	a5,a5,-2
    8000492a:	4705                	li	a4,1
    8000492c:	04f76763          	bltu	a4,a5,8000497a <filestat+0x6e>
    80004930:	892a                	mv	s2,a0
    ilock(f->ip);
    80004932:	6c88                	ld	a0,24(s1)
    80004934:	fffff097          	auipc	ra,0xfffff
    80004938:	072080e7          	jalr	114(ra) # 800039a6 <ilock>
    stati(f->ip, &st);
    8000493c:	fb840593          	addi	a1,s0,-72
    80004940:	6c88                	ld	a0,24(s1)
    80004942:	fffff097          	auipc	ra,0xfffff
    80004946:	2ee080e7          	jalr	750(ra) # 80003c30 <stati>
    iunlock(f->ip);
    8000494a:	6c88                	ld	a0,24(s1)
    8000494c:	fffff097          	auipc	ra,0xfffff
    80004950:	11c080e7          	jalr	284(ra) # 80003a68 <iunlock>
    if(copyout(p->pagetable, addr, (char *)&st, sizeof(st)) < 0)
    80004954:	46e1                	li	a3,24
    80004956:	fb840613          	addi	a2,s0,-72
    8000495a:	85ce                	mv	a1,s3
    8000495c:	05093503          	ld	a0,80(s2)
    80004960:	ffffd097          	auipc	ra,0xffffd
    80004964:	f7c080e7          	jalr	-132(ra) # 800018dc <copyout>
    80004968:	41f5551b          	sraiw	a0,a0,0x1f
      return -1;
    return 0;
  }
  return -1;
}
    8000496c:	60a6                	ld	ra,72(sp)
    8000496e:	6406                	ld	s0,64(sp)
    80004970:	74e2                	ld	s1,56(sp)
    80004972:	7942                	ld	s2,48(sp)
    80004974:	79a2                	ld	s3,40(sp)
    80004976:	6161                	addi	sp,sp,80
    80004978:	8082                	ret
  return -1;
    8000497a:	557d                	li	a0,-1
    8000497c:	bfc5                	j	8000496c <filestat+0x60>

000000008000497e <fileread>:

// Read from file f.
// addr is a user virtual address.
int
fileread(struct file *f, uint64 addr, int n)
{
    8000497e:	7179                	addi	sp,sp,-48
    80004980:	f406                	sd	ra,40(sp)
    80004982:	f022                	sd	s0,32(sp)
    80004984:	ec26                	sd	s1,24(sp)
    80004986:	e84a                	sd	s2,16(sp)
    80004988:	e44e                	sd	s3,8(sp)
    8000498a:	1800                	addi	s0,sp,48
  int r = 0;

  if(f->readable == 0)
    8000498c:	00854783          	lbu	a5,8(a0)
    80004990:	c3d5                	beqz	a5,80004a34 <fileread+0xb6>
    80004992:	84aa                	mv	s1,a0
    80004994:	89ae                	mv	s3,a1
    80004996:	8932                	mv	s2,a2
    return -1;

  if(f->type == FD_PIPE){
    80004998:	411c                	lw	a5,0(a0)
    8000499a:	4705                	li	a4,1
    8000499c:	04e78963          	beq	a5,a4,800049ee <fileread+0x70>
    r = piperead(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    800049a0:	470d                	li	a4,3
    800049a2:	04e78d63          	beq	a5,a4,800049fc <fileread+0x7e>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
      return -1;
    r = devsw[f->major].read(1, addr, n);
  } else if(f->type == FD_INODE){
    800049a6:	4709                	li	a4,2
    800049a8:	06e79e63          	bne	a5,a4,80004a24 <fileread+0xa6>
    ilock(f->ip);
    800049ac:	6d08                	ld	a0,24(a0)
    800049ae:	fffff097          	auipc	ra,0xfffff
    800049b2:	ff8080e7          	jalr	-8(ra) # 800039a6 <ilock>
    if((r = readi(f->ip, 1, addr, f->off, n)) > 0)
    800049b6:	874a                	mv	a4,s2
    800049b8:	5094                	lw	a3,32(s1)
    800049ba:	864e                	mv	a2,s3
    800049bc:	4585                	li	a1,1
    800049be:	6c88                	ld	a0,24(s1)
    800049c0:	fffff097          	auipc	ra,0xfffff
    800049c4:	29a080e7          	jalr	666(ra) # 80003c5a <readi>
    800049c8:	892a                	mv	s2,a0
    800049ca:	00a05563          	blez	a0,800049d4 <fileread+0x56>
      f->off += r;
    800049ce:	509c                	lw	a5,32(s1)
    800049d0:	9fa9                	addw	a5,a5,a0
    800049d2:	d09c                	sw	a5,32(s1)
    iunlock(f->ip);
    800049d4:	6c88                	ld	a0,24(s1)
    800049d6:	fffff097          	auipc	ra,0xfffff
    800049da:	092080e7          	jalr	146(ra) # 80003a68 <iunlock>
  } else {
    panic("fileread");
  }

  return r;
}
    800049de:	854a                	mv	a0,s2
    800049e0:	70a2                	ld	ra,40(sp)
    800049e2:	7402                	ld	s0,32(sp)
    800049e4:	64e2                	ld	s1,24(sp)
    800049e6:	6942                	ld	s2,16(sp)
    800049e8:	69a2                	ld	s3,8(sp)
    800049ea:	6145                	addi	sp,sp,48
    800049ec:	8082                	ret
    r = piperead(f->pipe, addr, n);
    800049ee:	6908                	ld	a0,16(a0)
    800049f0:	00000097          	auipc	ra,0x0
    800049f4:	5a6080e7          	jalr	1446(ra) # 80004f96 <piperead>
    800049f8:	892a                	mv	s2,a0
    800049fa:	b7d5                	j	800049de <fileread+0x60>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].read)
    800049fc:	02451783          	lh	a5,36(a0)
    80004a00:	03079693          	slli	a3,a5,0x30
    80004a04:	92c1                	srli	a3,a3,0x30
    80004a06:	4725                	li	a4,9
    80004a08:	02d76863          	bltu	a4,a3,80004a38 <fileread+0xba>
    80004a0c:	0792                	slli	a5,a5,0x4
    80004a0e:	0089d717          	auipc	a4,0x89d
    80004a12:	d0a70713          	addi	a4,a4,-758 # 808a1718 <devsw>
    80004a16:	97ba                	add	a5,a5,a4
    80004a18:	639c                	ld	a5,0(a5)
    80004a1a:	c38d                	beqz	a5,80004a3c <fileread+0xbe>
    r = devsw[f->major].read(1, addr, n);
    80004a1c:	4505                	li	a0,1
    80004a1e:	9782                	jalr	a5
    80004a20:	892a                	mv	s2,a0
    80004a22:	bf75                	j	800049de <fileread+0x60>
    panic("fileread");
    80004a24:	00004517          	auipc	a0,0x4
    80004a28:	d6450513          	addi	a0,a0,-668 # 80008788 <syscalls+0x268>
    80004a2c:	ffffc097          	auipc	ra,0xffffc
    80004a30:	b12080e7          	jalr	-1262(ra) # 8000053e <panic>
    return -1;
    80004a34:	597d                	li	s2,-1
    80004a36:	b765                	j	800049de <fileread+0x60>
      return -1;
    80004a38:	597d                	li	s2,-1
    80004a3a:	b755                	j	800049de <fileread+0x60>
    80004a3c:	597d                	li	s2,-1
    80004a3e:	b745                	j	800049de <fileread+0x60>

0000000080004a40 <filewrite>:

// Write to file f.
// addr is a user virtual address.
int
filewrite(struct file *f, uint64 addr, int n)
{
    80004a40:	715d                	addi	sp,sp,-80
    80004a42:	e486                	sd	ra,72(sp)
    80004a44:	e0a2                	sd	s0,64(sp)
    80004a46:	fc26                	sd	s1,56(sp)
    80004a48:	f84a                	sd	s2,48(sp)
    80004a4a:	f44e                	sd	s3,40(sp)
    80004a4c:	f052                	sd	s4,32(sp)
    80004a4e:	ec56                	sd	s5,24(sp)
    80004a50:	e85a                	sd	s6,16(sp)
    80004a52:	e45e                	sd	s7,8(sp)
    80004a54:	e062                	sd	s8,0(sp)
    80004a56:	0880                	addi	s0,sp,80
  int r, ret = 0;

  if(f->writable == 0)
    80004a58:	00954783          	lbu	a5,9(a0)
    80004a5c:	10078663          	beqz	a5,80004b68 <filewrite+0x128>
    80004a60:	892a                	mv	s2,a0
    80004a62:	8aae                	mv	s5,a1
    80004a64:	8a32                	mv	s4,a2
    return -1;

  if(f->type == FD_PIPE){
    80004a66:	411c                	lw	a5,0(a0)
    80004a68:	4705                	li	a4,1
    80004a6a:	02e78263          	beq	a5,a4,80004a8e <filewrite+0x4e>
    ret = pipewrite(f->pipe, addr, n);
  } else if(f->type == FD_DEVICE){
    80004a6e:	470d                	li	a4,3
    80004a70:	02e78663          	beq	a5,a4,80004a9c <filewrite+0x5c>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
      return -1;
    ret = devsw[f->major].write(1, addr, n);
  } else if(f->type == FD_INODE){
    80004a74:	4709                	li	a4,2
    80004a76:	0ee79163          	bne	a5,a4,80004b58 <filewrite+0x118>
    // and 2 blocks of slop for non-aligned writes.
    // this really belongs lower down, since writei()
    // might be writing a device like the console.
    int max = ((MAXOPBLOCKS-1-1-2) / 2) * BSIZE;
    int i = 0;
    while(i < n){
    80004a7a:	0ac05d63          	blez	a2,80004b34 <filewrite+0xf4>
    int i = 0;
    80004a7e:	4981                	li	s3,0
    80004a80:	6b05                	lui	s6,0x1
    80004a82:	c00b0b13          	addi	s6,s6,-1024 # c00 <_entry-0x7ffff400>
    80004a86:	6b85                	lui	s7,0x1
    80004a88:	c00b8b9b          	addiw	s7,s7,-1024
    80004a8c:	a861                	j	80004b24 <filewrite+0xe4>
    ret = pipewrite(f->pipe, addr, n);
    80004a8e:	6908                	ld	a0,16(a0)
    80004a90:	00000097          	auipc	ra,0x0
    80004a94:	40c080e7          	jalr	1036(ra) # 80004e9c <pipewrite>
    80004a98:	8a2a                	mv	s4,a0
    80004a9a:	a045                	j	80004b3a <filewrite+0xfa>
    if(f->major < 0 || f->major >= NDEV || !devsw[f->major].write)
    80004a9c:	02451783          	lh	a5,36(a0)
    80004aa0:	03079693          	slli	a3,a5,0x30
    80004aa4:	92c1                	srli	a3,a3,0x30
    80004aa6:	4725                	li	a4,9
    80004aa8:	0cd76263          	bltu	a4,a3,80004b6c <filewrite+0x12c>
    80004aac:	0792                	slli	a5,a5,0x4
    80004aae:	0089d717          	auipc	a4,0x89d
    80004ab2:	c6a70713          	addi	a4,a4,-918 # 808a1718 <devsw>
    80004ab6:	97ba                	add	a5,a5,a4
    80004ab8:	679c                	ld	a5,8(a5)
    80004aba:	cbdd                	beqz	a5,80004b70 <filewrite+0x130>
    ret = devsw[f->major].write(1, addr, n);
    80004abc:	4505                	li	a0,1
    80004abe:	9782                	jalr	a5
    80004ac0:	8a2a                	mv	s4,a0
    80004ac2:	a8a5                	j	80004b3a <filewrite+0xfa>
    80004ac4:	00048c1b          	sext.w	s8,s1
      int n1 = n - i;
      if(n1 > max)
        n1 = max;

      begin_op();
    80004ac8:	00000097          	auipc	ra,0x0
    80004acc:	8b0080e7          	jalr	-1872(ra) # 80004378 <begin_op>
      ilock(f->ip);
    80004ad0:	01893503          	ld	a0,24(s2)
    80004ad4:	fffff097          	auipc	ra,0xfffff
    80004ad8:	ed2080e7          	jalr	-302(ra) # 800039a6 <ilock>
      if ((r = writei(f->ip, 1, addr + i, f->off, n1)) > 0)
    80004adc:	8762                	mv	a4,s8
    80004ade:	02092683          	lw	a3,32(s2)
    80004ae2:	01598633          	add	a2,s3,s5
    80004ae6:	4585                	li	a1,1
    80004ae8:	01893503          	ld	a0,24(s2)
    80004aec:	fffff097          	auipc	ra,0xfffff
    80004af0:	266080e7          	jalr	614(ra) # 80003d52 <writei>
    80004af4:	84aa                	mv	s1,a0
    80004af6:	00a05763          	blez	a0,80004b04 <filewrite+0xc4>
        f->off += r;
    80004afa:	02092783          	lw	a5,32(s2)
    80004afe:	9fa9                	addw	a5,a5,a0
    80004b00:	02f92023          	sw	a5,32(s2)
      iunlock(f->ip);
    80004b04:	01893503          	ld	a0,24(s2)
    80004b08:	fffff097          	auipc	ra,0xfffff
    80004b0c:	f60080e7          	jalr	-160(ra) # 80003a68 <iunlock>
      end_op();
    80004b10:	00000097          	auipc	ra,0x0
    80004b14:	8e8080e7          	jalr	-1816(ra) # 800043f8 <end_op>

      if(r != n1){
    80004b18:	009c1f63          	bne	s8,s1,80004b36 <filewrite+0xf6>
        // error from writei
        break;
      }
      i += r;
    80004b1c:	013489bb          	addw	s3,s1,s3
    while(i < n){
    80004b20:	0149db63          	bge	s3,s4,80004b36 <filewrite+0xf6>
      int n1 = n - i;
    80004b24:	413a07bb          	subw	a5,s4,s3
      if(n1 > max)
    80004b28:	84be                	mv	s1,a5
    80004b2a:	2781                	sext.w	a5,a5
    80004b2c:	f8fb5ce3          	bge	s6,a5,80004ac4 <filewrite+0x84>
    80004b30:	84de                	mv	s1,s7
    80004b32:	bf49                	j	80004ac4 <filewrite+0x84>
    int i = 0;
    80004b34:	4981                	li	s3,0
    }
    ret = (i == n ? n : -1);
    80004b36:	013a1f63          	bne	s4,s3,80004b54 <filewrite+0x114>
  } else {
    panic("filewrite");
  }

  return ret;
}
    80004b3a:	8552                	mv	a0,s4
    80004b3c:	60a6                	ld	ra,72(sp)
    80004b3e:	6406                	ld	s0,64(sp)
    80004b40:	74e2                	ld	s1,56(sp)
    80004b42:	7942                	ld	s2,48(sp)
    80004b44:	79a2                	ld	s3,40(sp)
    80004b46:	7a02                	ld	s4,32(sp)
    80004b48:	6ae2                	ld	s5,24(sp)
    80004b4a:	6b42                	ld	s6,16(sp)
    80004b4c:	6ba2                	ld	s7,8(sp)
    80004b4e:	6c02                	ld	s8,0(sp)
    80004b50:	6161                	addi	sp,sp,80
    80004b52:	8082                	ret
    ret = (i == n ? n : -1);
    80004b54:	5a7d                	li	s4,-1
    80004b56:	b7d5                	j	80004b3a <filewrite+0xfa>
    panic("filewrite");
    80004b58:	00004517          	auipc	a0,0x4
    80004b5c:	c4050513          	addi	a0,a0,-960 # 80008798 <syscalls+0x278>
    80004b60:	ffffc097          	auipc	ra,0xffffc
    80004b64:	9de080e7          	jalr	-1570(ra) # 8000053e <panic>
    return -1;
    80004b68:	5a7d                	li	s4,-1
    80004b6a:	bfc1                	j	80004b3a <filewrite+0xfa>
      return -1;
    80004b6c:	5a7d                	li	s4,-1
    80004b6e:	b7f1                	j	80004b3a <filewrite+0xfa>
    80004b70:	5a7d                	li	s4,-1
    80004b72:	b7e1                	j	80004b3a <filewrite+0xfa>

0000000080004b74 <mmap>:

uint64
mmap(uint64 length, int prot, int flag, int fd){
    80004b74:	7139                	addi	sp,sp,-64
    80004b76:	fc06                	sd	ra,56(sp)
    80004b78:	f822                	sd	s0,48(sp)
    80004b7a:	f426                	sd	s1,40(sp)
    80004b7c:	f04a                	sd	s2,32(sp)
    80004b7e:	ec4e                	sd	s3,24(sp)
    80004b80:	e852                	sd	s4,16(sp)
    80004b82:	e456                	sd	s5,8(sp)
    80004b84:	e05a                	sd	s6,0(sp)
    80004b86:	0080                	addi	s0,sp,64
    80004b88:	89aa                	mv	s3,a0
    80004b8a:	8a2e                	mv	s4,a1
    80004b8c:	8ab2                	mv	s5,a2
    80004b8e:	8936                	mv	s2,a3

  struct proc *p = myproc(); 
    80004b90:	ffffd097          	auipc	ra,0xffffd
    80004b94:	08a080e7          	jalr	138(ra) # 80001c1a <myproc>
    80004b98:	84aa                	mv	s1,a0
  int i;
  struct vma *n, *act, *prev;
  uint64 psize;  //Real size of the vma based on page size

  acquire(&p->lock);
    80004b9a:	ffffc097          	auipc	ra,0xffffc
    80004b9e:	2b4080e7          	jalr	692(ra) # 80000e4e <acquire>

  if(p->nvma == MAX_VMAS){
    80004ba2:	1704a703          	lw	a4,368(s1)
    80004ba6:	47a9                	li	a5,10
    80004ba8:	06f70763          	beq	a4,a5,80004c16 <mmap+0xa2>
    release(&p->lock);
    return 0xffffffffffffffff;
  }

  acquire(&vmaslock);
    80004bac:	0089d517          	auipc	a0,0x89d
    80004bb0:	38c50513          	addi	a0,a0,908 # 808a1f38 <vmaslock>
    80004bb4:	ffffc097          	auipc	ra,0xffffc
    80004bb8:	29a080e7          	jalr	666(ra) # 80000e4e <acquire>

  //Search for a free vma in the global vma array
  for(i = 0; i < VMAS_STORED; i++){
    80004bbc:	0089d797          	auipc	a5,0x89d
    80004bc0:	bfc78793          	addi	a5,a5,-1028 # 808a17b8 <vmas>
    80004bc4:	0089d617          	auipc	a2,0x89d
    80004bc8:	37460613          	addi	a2,a2,884 # 808a1f38 <vmaslock>
    80004bcc:	0089d697          	auipc	a3,0x89d
    80004bd0:	32c68693          	addi	a3,a3,812 # 808a1ef8 <vmas+0x740>
    if(vmas[i].use == 0) break;
    80004bd4:	4398                	lw	a4,0(a5)
    80004bd6:	c719                	beqz	a4,80004be4 <mmap+0x70>
    else if(i == VMAS_STORED-1){
    80004bd8:	04d78663          	beq	a5,a3,80004c24 <mmap+0xb0>
  for(i = 0; i < VMAS_STORED; i++){
    80004bdc:	04078793          	addi	a5,a5,64
    80004be0:	fec79ae3          	bne	a5,a2,80004bd4 <mmap+0x60>
      release(&vmaslock);
      return 0xffffffffffffffff;  //No free vma was found
    }
  }

  psize = PGROUNDUP(length);
    80004be4:	6785                	lui	a5,0x1
    80004be6:	17fd                	addi	a5,a5,-1
    80004be8:	97ce                	add	a5,a5,s3
    80004bea:	777d                	lui	a4,0xfffff
    80004bec:	00e7f8b3          	and	a7,a5,a4
  act = p->vmas;
    80004bf0:	1684b783          	ld	a5,360(s1)
  prev = 0;
  n = 0;

  for(i= 0; i<=MAX_VMAS; i++){
    if(act == 0){
    80004bf4:	c3f5                	beqz	a5,80004cd8 <mmap+0x164>
  prev = 0;
    80004bf6:	4681                	li	a3,0
  for(i= 0; i<=MAX_VMAS; i++){
    80004bf8:	4801                	li	a6,0
    80004bfa:	45ad                	li	a1,11
        n->addre = prev->addre + psize; 
      }
      n->next = 0;
      goto allocated; 

    }else if(prev->addre + psize < act->addri){
    80004bfc:	7298                	ld	a4,32(a3)
    80004bfe:	9746                	add	a4,a4,a7
    80004c00:	6f90                	ld	a2,24(a5)
    80004c02:	04c76063          	bltu	a4,a2,80004c42 <mmap+0xce>
      n->addre = prev->addre + psize;
      goto allocated; 

    } 
    prev = act;
    act = act->next;
    80004c06:	7b98                	ld	a4,48(a5)
  for(i= 0; i<=MAX_VMAS; i++){
    80004c08:	2805                	addiw	a6,a6,1
    80004c0a:	0ab80c63          	beq	a6,a1,80004cc2 <mmap+0x14e>
    if(act == 0){
    80004c0e:	86be                	mv	a3,a5
    80004c10:	cf65                	beqz	a4,80004d08 <mmap+0x194>
    act = act->next;
    80004c12:	87ba                	mv	a5,a4
    80004c14:	b7e5                	j	80004bfc <mmap+0x88>
    release(&p->lock);
    80004c16:	8526                	mv	a0,s1
    80004c18:	ffffc097          	auipc	ra,0xffffc
    80004c1c:	2ea080e7          	jalr	746(ra) # 80000f02 <release>
    return 0xffffffffffffffff;
    80004c20:	557d                	li	a0,-1
    80004c22:	a04d                	j	80004cc4 <mmap+0x150>
      release(&p->lock);
    80004c24:	8526                	mv	a0,s1
    80004c26:	ffffc097          	auipc	ra,0xffffc
    80004c2a:	2dc080e7          	jalr	732(ra) # 80000f02 <release>
      release(&vmaslock);
    80004c2e:	0089d517          	auipc	a0,0x89d
    80004c32:	30a50513          	addi	a0,a0,778 # 808a1f38 <vmaslock>
    80004c36:	ffffc097          	auipc	ra,0xffffc
    80004c3a:	2cc080e7          	jalr	716(ra) # 80000f02 <release>
      return 0xffffffffffffffff;  //No free vma was found
    80004c3e:	557d                	li	a0,-1
    80004c40:	a051                	j	80004cc4 <mmap+0x150>
      n = &vmas[i];
    80004c42:	081a                	slli	a6,a6,0x6
    80004c44:	0089db17          	auipc	s6,0x89d
    80004c48:	b74b0b13          	addi	s6,s6,-1164 # 808a17b8 <vmas>
    80004c4c:	9b42                	add	s6,s6,a6
      prev->next = n;
    80004c4e:	0366b823          	sd	s6,48(a3)
      n->next = act;
    80004c52:	0089d617          	auipc	a2,0x89d
    80004c56:	ac660613          	addi	a2,a2,-1338 # 808a1718 <devsw>
    80004c5a:	9642                	add	a2,a2,a6
    80004c5c:	ea7c                	sd	a5,208(a2)
      n->addri = prev->addre;
    80004c5e:	7294                	ld	a3,32(a3)
    80004c60:	fe54                	sd	a3,184(a2)
      n->addre = prev->addre + psize;
    80004c62:	96c6                	add	a3,a3,a7
    80004c64:	e274                	sd	a3,192(a2)
  }

  return 0xffffffffffffffff; //The vma can not be allocated

  allocated:
    n->size = length;
    80004c66:	013b3423          	sd	s3,8(s6)
    n->use = 1;
    80004c6a:	4785                	li	a5,1
    80004c6c:	00fb2023          	sw	a5,0(s6)
    n->prot = prot;
    80004c70:	034b2c23          	sw	s4,56(s6)
    n->ofile = p->ofile[fd];
    80004c74:	090e                	slli	s2,s2,0x3
    80004c76:	9926                	add	s2,s2,s1
    80004c78:	0d093783          	ld	a5,208(s2)
    80004c7c:	00fb3823          	sd	a5,16(s6)
    n->offset = 0;
    80004c80:	020b3423          	sd	zero,40(s6)
    n->flag = flag;
    80004c84:	035b2e23          	sw	s5,60(s6)

    release(&vmaslock);
    80004c88:	0089d517          	auipc	a0,0x89d
    80004c8c:	2b050513          	addi	a0,a0,688 # 808a1f38 <vmaslock>
    80004c90:	ffffc097          	auipc	ra,0xffffc
    80004c94:	272080e7          	jalr	626(ra) # 80000f02 <release>

    p->ofile[fd]->ref++;  //Add a reference to the file
    80004c98:	0d093703          	ld	a4,208(s2)
    80004c9c:	435c                	lw	a5,4(a4)
    80004c9e:	2785                	addiw	a5,a5,1
    80004ca0:	c35c                	sw	a5,4(a4)
    if(p->nvma == 0)  p->vmas = n;
    80004ca2:	1704a783          	lw	a5,368(s1)
    80004ca6:	e399                	bnez	a5,80004cac <mmap+0x138>
    80004ca8:	1764b423          	sd	s6,360(s1)
    p->nvma++;
    80004cac:	2785                	addiw	a5,a5,1
    80004cae:	16f4a823          	sw	a5,368(s1)
 
    release(&p->lock);
    80004cb2:	8526                	mv	a0,s1
    80004cb4:	ffffc097          	auipc	ra,0xffffc
    80004cb8:	24e080e7          	jalr	590(ra) # 80000f02 <release>
    return n->addri; 
    80004cbc:	018b3503          	ld	a0,24(s6)
    80004cc0:	a011                	j	80004cc4 <mmap+0x150>
  return 0xffffffffffffffff; //The vma can not be allocated
    80004cc2:	557d                	li	a0,-1
}
    80004cc4:	70e2                	ld	ra,56(sp)
    80004cc6:	7442                	ld	s0,48(sp)
    80004cc8:	74a2                	ld	s1,40(sp)
    80004cca:	7902                	ld	s2,32(sp)
    80004ccc:	69e2                	ld	s3,24(sp)
    80004cce:	6a42                	ld	s4,16(sp)
    80004cd0:	6aa2                	ld	s5,8(sp)
    80004cd2:	6b02                	ld	s6,0(sp)
    80004cd4:	6121                	addi	sp,sp,64
    80004cd6:	8082                	ret
      if(((prev != 0) && (prev->addre + psize) >= TOP_ADDRESS) || ((prev == 0) && START_ADDRESS + psize >= TOP_ADDRESS)) return 0xffffffffffffffff; //The vma can not be allocated
    80004cd8:	4785                	li	a5,1
    80004cda:	1796                	slli	a5,a5,0x25
    80004cdc:	97c6                	add	a5,a5,a7
    80004cde:	fefff737          	lui	a4,0xfefff
    80004ce2:	073e                	slli	a4,a4,0xf
    80004ce4:	8369                	srli	a4,a4,0x1a
    80004ce6:	557d                	li	a0,-1
    80004ce8:	fcf76ee3          	bltu	a4,a5,80004cc4 <mmap+0x150>
        n->addri = START_ADDRESS;
    80004cec:	0089d697          	auipc	a3,0x89d
    80004cf0:	a2c68693          	addi	a3,a3,-1492 # 808a1718 <devsw>
    80004cf4:	4705                	li	a4,1
    80004cf6:	1716                	slli	a4,a4,0x25
    80004cf8:	fed8                	sd	a4,184(a3)
        n->addre = START_ADDRESS + psize;
    80004cfa:	e2fc                	sd	a5,192(a3)
  for(i= 0; i<=MAX_VMAS; i++){
    80004cfc:	4801                	li	a6,0
      n = &vmas[i];
    80004cfe:	0089db17          	auipc	s6,0x89d
    80004d02:	abab0b13          	addi	s6,s6,-1350 # 808a17b8 <vmas>
    80004d06:	a82d                	j	80004d40 <mmap+0x1cc>
      if(((prev != 0) && (prev->addre + psize) >= TOP_ADDRESS) || ((prev == 0) && START_ADDRESS + psize >= TOP_ADDRESS)) return 0xffffffffffffffff; //The vma can not be allocated
    80004d08:	7390                	ld	a2,32(a5)
    80004d0a:	01160733          	add	a4,a2,a7
    80004d0e:	fefff6b7          	lui	a3,0xfefff
    80004d12:	06be                	slli	a3,a3,0xf
    80004d14:	82e9                	srli	a3,a3,0x1a
    80004d16:	557d                	li	a0,-1
    80004d18:	fae6e6e3          	bltu	a3,a4,80004cc4 <mmap+0x150>
      n = &vmas[i];
    80004d1c:	00681693          	slli	a3,a6,0x6
    80004d20:	0089db17          	auipc	s6,0x89d
    80004d24:	a98b0b13          	addi	s6,s6,-1384 # 808a17b8 <vmas>
    80004d28:	9b36                	add	s6,s6,a3
        prev->next = n;
    80004d2a:	0367b823          	sd	s6,48(a5) # 1030 <_entry-0x7fffefd0>
        n->addri = prev->addre;
    80004d2e:	0089d717          	auipc	a4,0x89d
    80004d32:	9ea70713          	addi	a4,a4,-1558 # 808a1718 <devsw>
    80004d36:	9736                	add	a4,a4,a3
    80004d38:	ff50                	sd	a2,184(a4)
        n->addre = prev->addre + psize; 
    80004d3a:	739c                	ld	a5,32(a5)
    80004d3c:	97c6                	add	a5,a5,a7
    80004d3e:	e37c                	sd	a5,192(a4)
      n->next = 0;
    80004d40:	081a                	slli	a6,a6,0x6
    80004d42:	0089d797          	auipc	a5,0x89d
    80004d46:	9d678793          	addi	a5,a5,-1578 # 808a1718 <devsw>
    80004d4a:	97c2                	add	a5,a5,a6
    80004d4c:	0c07b823          	sd	zero,208(a5)
      goto allocated; 
    80004d50:	bf19                	j	80004c66 <mmap+0xf2>

0000000080004d52 <pipealloc>:
  int writeopen;  // write fd is still open
};

int
pipealloc(struct file **f0, struct file **f1)
{
    80004d52:	7179                	addi	sp,sp,-48
    80004d54:	f406                	sd	ra,40(sp)
    80004d56:	f022                	sd	s0,32(sp)
    80004d58:	ec26                	sd	s1,24(sp)
    80004d5a:	e84a                	sd	s2,16(sp)
    80004d5c:	e44e                	sd	s3,8(sp)
    80004d5e:	e052                	sd	s4,0(sp)
    80004d60:	1800                	addi	s0,sp,48
    80004d62:	84aa                	mv	s1,a0
    80004d64:	8a2e                	mv	s4,a1
  struct pipe *pi;

  pi = 0;
  *f0 = *f1 = 0;
    80004d66:	0005b023          	sd	zero,0(a1) # 80008768 <syscalls+0x248>
    80004d6a:	00053023          	sd	zero,0(a0)
  if((*f0 = filealloc()) == 0 || (*f1 = filealloc()) == 0)
    80004d6e:	00000097          	auipc	ra,0x0
    80004d72:	a1a080e7          	jalr	-1510(ra) # 80004788 <filealloc>
    80004d76:	e088                	sd	a0,0(s1)
    80004d78:	c551                	beqz	a0,80004e04 <pipealloc+0xb2>
    80004d7a:	00000097          	auipc	ra,0x0
    80004d7e:	a0e080e7          	jalr	-1522(ra) # 80004788 <filealloc>
    80004d82:	00aa3023          	sd	a0,0(s4)
    80004d86:	c92d                	beqz	a0,80004df8 <pipealloc+0xa6>
    goto bad;
  if((pi = (struct pipe*)kalloc()) == 0)
    80004d88:	ffffc097          	auipc	ra,0xffffc
    80004d8c:	e88080e7          	jalr	-376(ra) # 80000c10 <kalloc>
    80004d90:	892a                	mv	s2,a0
    80004d92:	c125                	beqz	a0,80004df2 <pipealloc+0xa0>
    goto bad;
  pi->readopen = 1;
    80004d94:	4985                	li	s3,1
    80004d96:	23352023          	sw	s3,544(a0)
  pi->writeopen = 1;
    80004d9a:	23352223          	sw	s3,548(a0)
  pi->nwrite = 0;
    80004d9e:	20052e23          	sw	zero,540(a0)
  pi->nread = 0;
    80004da2:	20052c23          	sw	zero,536(a0)
  initlock(&pi->lock, "pipe");
    80004da6:	00004597          	auipc	a1,0x4
    80004daa:	a0258593          	addi	a1,a1,-1534 # 800087a8 <syscalls+0x288>
    80004dae:	ffffc097          	auipc	ra,0xffffc
    80004db2:	010080e7          	jalr	16(ra) # 80000dbe <initlock>
  (*f0)->type = FD_PIPE;
    80004db6:	609c                	ld	a5,0(s1)
    80004db8:	0137a023          	sw	s3,0(a5)
  (*f0)->readable = 1;
    80004dbc:	609c                	ld	a5,0(s1)
    80004dbe:	01378423          	sb	s3,8(a5)
  (*f0)->writable = 0;
    80004dc2:	609c                	ld	a5,0(s1)
    80004dc4:	000784a3          	sb	zero,9(a5)
  (*f0)->pipe = pi;
    80004dc8:	609c                	ld	a5,0(s1)
    80004dca:	0127b823          	sd	s2,16(a5)
  (*f1)->type = FD_PIPE;
    80004dce:	000a3783          	ld	a5,0(s4)
    80004dd2:	0137a023          	sw	s3,0(a5)
  (*f1)->readable = 0;
    80004dd6:	000a3783          	ld	a5,0(s4)
    80004dda:	00078423          	sb	zero,8(a5)
  (*f1)->writable = 1;
    80004dde:	000a3783          	ld	a5,0(s4)
    80004de2:	013784a3          	sb	s3,9(a5)
  (*f1)->pipe = pi;
    80004de6:	000a3783          	ld	a5,0(s4)
    80004dea:	0127b823          	sd	s2,16(a5)
  return 0;
    80004dee:	4501                	li	a0,0
    80004df0:	a025                	j	80004e18 <pipealloc+0xc6>

 bad:
  if(pi)
    kfree((char*)pi);
  if(*f0)
    80004df2:	6088                	ld	a0,0(s1)
    80004df4:	e501                	bnez	a0,80004dfc <pipealloc+0xaa>
    80004df6:	a039                	j	80004e04 <pipealloc+0xb2>
    80004df8:	6088                	ld	a0,0(s1)
    80004dfa:	c51d                	beqz	a0,80004e28 <pipealloc+0xd6>
    fileclose(*f0);
    80004dfc:	00000097          	auipc	ra,0x0
    80004e00:	a48080e7          	jalr	-1464(ra) # 80004844 <fileclose>
  if(*f1)
    80004e04:	000a3783          	ld	a5,0(s4)
    fileclose(*f1);
  return -1;
    80004e08:	557d                	li	a0,-1
  if(*f1)
    80004e0a:	c799                	beqz	a5,80004e18 <pipealloc+0xc6>
    fileclose(*f1);
    80004e0c:	853e                	mv	a0,a5
    80004e0e:	00000097          	auipc	ra,0x0
    80004e12:	a36080e7          	jalr	-1482(ra) # 80004844 <fileclose>
  return -1;
    80004e16:	557d                	li	a0,-1
}
    80004e18:	70a2                	ld	ra,40(sp)
    80004e1a:	7402                	ld	s0,32(sp)
    80004e1c:	64e2                	ld	s1,24(sp)
    80004e1e:	6942                	ld	s2,16(sp)
    80004e20:	69a2                	ld	s3,8(sp)
    80004e22:	6a02                	ld	s4,0(sp)
    80004e24:	6145                	addi	sp,sp,48
    80004e26:	8082                	ret
  return -1;
    80004e28:	557d                	li	a0,-1
    80004e2a:	b7fd                	j	80004e18 <pipealloc+0xc6>

0000000080004e2c <pipeclose>:

void
pipeclose(struct pipe *pi, int writable)
{
    80004e2c:	1101                	addi	sp,sp,-32
    80004e2e:	ec06                	sd	ra,24(sp)
    80004e30:	e822                	sd	s0,16(sp)
    80004e32:	e426                	sd	s1,8(sp)
    80004e34:	e04a                	sd	s2,0(sp)
    80004e36:	1000                	addi	s0,sp,32
    80004e38:	84aa                	mv	s1,a0
    80004e3a:	892e                	mv	s2,a1
  acquire(&pi->lock);
    80004e3c:	ffffc097          	auipc	ra,0xffffc
    80004e40:	012080e7          	jalr	18(ra) # 80000e4e <acquire>
  if(writable){
    80004e44:	02090d63          	beqz	s2,80004e7e <pipeclose+0x52>
    pi->writeopen = 0;
    80004e48:	2204a223          	sw	zero,548(s1)
    wakeup(&pi->nread);
    80004e4c:	21848513          	addi	a0,s1,536
    80004e50:	ffffd097          	auipc	ra,0xffffd
    80004e54:	61e080e7          	jalr	1566(ra) # 8000246e <wakeup>
  } else {
    pi->readopen = 0;
    wakeup(&pi->nwrite);
  }
  if(pi->readopen == 0 && pi->writeopen == 0){
    80004e58:	2204b783          	ld	a5,544(s1)
    80004e5c:	eb95                	bnez	a5,80004e90 <pipeclose+0x64>
    release(&pi->lock);
    80004e5e:	8526                	mv	a0,s1
    80004e60:	ffffc097          	auipc	ra,0xffffc
    80004e64:	0a2080e7          	jalr	162(ra) # 80000f02 <release>
    kfree((char*)pi);
    80004e68:	8526                	mv	a0,s1
    80004e6a:	ffffc097          	auipc	ra,0xffffc
    80004e6e:	c8e080e7          	jalr	-882(ra) # 80000af8 <kfree>
  } else
    release(&pi->lock);
}
    80004e72:	60e2                	ld	ra,24(sp)
    80004e74:	6442                	ld	s0,16(sp)
    80004e76:	64a2                	ld	s1,8(sp)
    80004e78:	6902                	ld	s2,0(sp)
    80004e7a:	6105                	addi	sp,sp,32
    80004e7c:	8082                	ret
    pi->readopen = 0;
    80004e7e:	2204a023          	sw	zero,544(s1)
    wakeup(&pi->nwrite);
    80004e82:	21c48513          	addi	a0,s1,540
    80004e86:	ffffd097          	auipc	ra,0xffffd
    80004e8a:	5e8080e7          	jalr	1512(ra) # 8000246e <wakeup>
    80004e8e:	b7e9                	j	80004e58 <pipeclose+0x2c>
    release(&pi->lock);
    80004e90:	8526                	mv	a0,s1
    80004e92:	ffffc097          	auipc	ra,0xffffc
    80004e96:	070080e7          	jalr	112(ra) # 80000f02 <release>
}
    80004e9a:	bfe1                	j	80004e72 <pipeclose+0x46>

0000000080004e9c <pipewrite>:

int
pipewrite(struct pipe *pi, uint64 addr, int n)
{
    80004e9c:	7159                	addi	sp,sp,-112
    80004e9e:	f486                	sd	ra,104(sp)
    80004ea0:	f0a2                	sd	s0,96(sp)
    80004ea2:	eca6                	sd	s1,88(sp)
    80004ea4:	e8ca                	sd	s2,80(sp)
    80004ea6:	e4ce                	sd	s3,72(sp)
    80004ea8:	e0d2                	sd	s4,64(sp)
    80004eaa:	fc56                	sd	s5,56(sp)
    80004eac:	f85a                	sd	s6,48(sp)
    80004eae:	f45e                	sd	s7,40(sp)
    80004eb0:	f062                	sd	s8,32(sp)
    80004eb2:	ec66                	sd	s9,24(sp)
    80004eb4:	1880                	addi	s0,sp,112
    80004eb6:	84aa                	mv	s1,a0
    80004eb8:	8aae                	mv	s5,a1
    80004eba:	8a32                	mv	s4,a2
  int i = 0;
  struct proc *pr = myproc();
    80004ebc:	ffffd097          	auipc	ra,0xffffd
    80004ec0:	d5e080e7          	jalr	-674(ra) # 80001c1a <myproc>
    80004ec4:	89aa                	mv	s3,a0

  acquire(&pi->lock);
    80004ec6:	8526                	mv	a0,s1
    80004ec8:	ffffc097          	auipc	ra,0xffffc
    80004ecc:	f86080e7          	jalr	-122(ra) # 80000e4e <acquire>
  while(i < n){
    80004ed0:	0d405163          	blez	s4,80004f92 <pipewrite+0xf6>
    80004ed4:	8ba6                	mv	s7,s1
  int i = 0;
    80004ed6:	4901                	li	s2,0
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
      wakeup(&pi->nread);
      sleep(&pi->nwrite, &pi->lock);
    } else {
      char ch;
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004ed8:	5b7d                	li	s6,-1
      wakeup(&pi->nread);
    80004eda:	21848c93          	addi	s9,s1,536
      sleep(&pi->nwrite, &pi->lock);
    80004ede:	21c48c13          	addi	s8,s1,540
    80004ee2:	a08d                	j	80004f44 <pipewrite+0xa8>
      release(&pi->lock);
    80004ee4:	8526                	mv	a0,s1
    80004ee6:	ffffc097          	auipc	ra,0xffffc
    80004eea:	01c080e7          	jalr	28(ra) # 80000f02 <release>
      return -1;
    80004eee:	597d                	li	s2,-1
  }
  wakeup(&pi->nread);
  release(&pi->lock);

  return i;
}
    80004ef0:	854a                	mv	a0,s2
    80004ef2:	70a6                	ld	ra,104(sp)
    80004ef4:	7406                	ld	s0,96(sp)
    80004ef6:	64e6                	ld	s1,88(sp)
    80004ef8:	6946                	ld	s2,80(sp)
    80004efa:	69a6                	ld	s3,72(sp)
    80004efc:	6a06                	ld	s4,64(sp)
    80004efe:	7ae2                	ld	s5,56(sp)
    80004f00:	7b42                	ld	s6,48(sp)
    80004f02:	7ba2                	ld	s7,40(sp)
    80004f04:	7c02                	ld	s8,32(sp)
    80004f06:	6ce2                	ld	s9,24(sp)
    80004f08:	6165                	addi	sp,sp,112
    80004f0a:	8082                	ret
      wakeup(&pi->nread);
    80004f0c:	8566                	mv	a0,s9
    80004f0e:	ffffd097          	auipc	ra,0xffffd
    80004f12:	560080e7          	jalr	1376(ra) # 8000246e <wakeup>
      sleep(&pi->nwrite, &pi->lock);
    80004f16:	85de                	mv	a1,s7
    80004f18:	8562                	mv	a0,s8
    80004f1a:	ffffd097          	auipc	ra,0xffffd
    80004f1e:	3c8080e7          	jalr	968(ra) # 800022e2 <sleep>
    80004f22:	a839                	j	80004f40 <pipewrite+0xa4>
      pi->data[pi->nwrite++ % PIPESIZE] = ch;
    80004f24:	21c4a783          	lw	a5,540(s1)
    80004f28:	0017871b          	addiw	a4,a5,1
    80004f2c:	20e4ae23          	sw	a4,540(s1)
    80004f30:	1ff7f793          	andi	a5,a5,511
    80004f34:	97a6                	add	a5,a5,s1
    80004f36:	f9f44703          	lbu	a4,-97(s0)
    80004f3a:	00e78c23          	sb	a4,24(a5)
      i++;
    80004f3e:	2905                	addiw	s2,s2,1
  while(i < n){
    80004f40:	03495d63          	bge	s2,s4,80004f7a <pipewrite+0xde>
    if(pi->readopen == 0 || pr->killed){
    80004f44:	2204a783          	lw	a5,544(s1)
    80004f48:	dfd1                	beqz	a5,80004ee4 <pipewrite+0x48>
    80004f4a:	0289a783          	lw	a5,40(s3)
    80004f4e:	fbd9                	bnez	a5,80004ee4 <pipewrite+0x48>
    if(pi->nwrite == pi->nread + PIPESIZE){ //DOC: pipewrite-full
    80004f50:	2184a783          	lw	a5,536(s1)
    80004f54:	21c4a703          	lw	a4,540(s1)
    80004f58:	2007879b          	addiw	a5,a5,512
    80004f5c:	faf708e3          	beq	a4,a5,80004f0c <pipewrite+0x70>
      if(copyin(pr->pagetable, &ch, addr + i, 1) == -1)
    80004f60:	4685                	li	a3,1
    80004f62:	01590633          	add	a2,s2,s5
    80004f66:	f9f40593          	addi	a1,s0,-97
    80004f6a:	0509b503          	ld	a0,80(s3)
    80004f6e:	ffffd097          	auipc	ra,0xffffd
    80004f72:	9fa080e7          	jalr	-1542(ra) # 80001968 <copyin>
    80004f76:	fb6517e3          	bne	a0,s6,80004f24 <pipewrite+0x88>
  wakeup(&pi->nread);
    80004f7a:	21848513          	addi	a0,s1,536
    80004f7e:	ffffd097          	auipc	ra,0xffffd
    80004f82:	4f0080e7          	jalr	1264(ra) # 8000246e <wakeup>
  release(&pi->lock);
    80004f86:	8526                	mv	a0,s1
    80004f88:	ffffc097          	auipc	ra,0xffffc
    80004f8c:	f7a080e7          	jalr	-134(ra) # 80000f02 <release>
  return i;
    80004f90:	b785                	j	80004ef0 <pipewrite+0x54>
  int i = 0;
    80004f92:	4901                	li	s2,0
    80004f94:	b7dd                	j	80004f7a <pipewrite+0xde>

0000000080004f96 <piperead>:

int
piperead(struct pipe *pi, uint64 addr, int n)
{
    80004f96:	715d                	addi	sp,sp,-80
    80004f98:	e486                	sd	ra,72(sp)
    80004f9a:	e0a2                	sd	s0,64(sp)
    80004f9c:	fc26                	sd	s1,56(sp)
    80004f9e:	f84a                	sd	s2,48(sp)
    80004fa0:	f44e                	sd	s3,40(sp)
    80004fa2:	f052                	sd	s4,32(sp)
    80004fa4:	ec56                	sd	s5,24(sp)
    80004fa6:	e85a                	sd	s6,16(sp)
    80004fa8:	0880                	addi	s0,sp,80
    80004faa:	84aa                	mv	s1,a0
    80004fac:	892e                	mv	s2,a1
    80004fae:	8ab2                	mv	s5,a2
  int i;
  struct proc *pr = myproc();
    80004fb0:	ffffd097          	auipc	ra,0xffffd
    80004fb4:	c6a080e7          	jalr	-918(ra) # 80001c1a <myproc>
    80004fb8:	8a2a                	mv	s4,a0
  char ch;

  acquire(&pi->lock);
    80004fba:	8b26                	mv	s6,s1
    80004fbc:	8526                	mv	a0,s1
    80004fbe:	ffffc097          	auipc	ra,0xffffc
    80004fc2:	e90080e7          	jalr	-368(ra) # 80000e4e <acquire>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004fc6:	2184a703          	lw	a4,536(s1)
    80004fca:	21c4a783          	lw	a5,540(s1)
    if(pr->killed){
      release(&pi->lock);
      return -1;
    }
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004fce:	21848993          	addi	s3,s1,536
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004fd2:	02f71463          	bne	a4,a5,80004ffa <piperead+0x64>
    80004fd6:	2244a783          	lw	a5,548(s1)
    80004fda:	c385                	beqz	a5,80004ffa <piperead+0x64>
    if(pr->killed){
    80004fdc:	028a2783          	lw	a5,40(s4)
    80004fe0:	ebc1                	bnez	a5,80005070 <piperead+0xda>
    sleep(&pi->nread, &pi->lock); //DOC: piperead-sleep
    80004fe2:	85da                	mv	a1,s6
    80004fe4:	854e                	mv	a0,s3
    80004fe6:	ffffd097          	auipc	ra,0xffffd
    80004fea:	2fc080e7          	jalr	764(ra) # 800022e2 <sleep>
  while(pi->nread == pi->nwrite && pi->writeopen){  //DOC: pipe-empty
    80004fee:	2184a703          	lw	a4,536(s1)
    80004ff2:	21c4a783          	lw	a5,540(s1)
    80004ff6:	fef700e3          	beq	a4,a5,80004fd6 <piperead+0x40>
  }
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    80004ffa:	09505263          	blez	s5,8000507e <piperead+0xe8>
    80004ffe:	4981                	li	s3,0
    if(pi->nread == pi->nwrite)
      break;
    ch = pi->data[pi->nread++ % PIPESIZE];
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005000:	5b7d                	li	s6,-1
    if(pi->nread == pi->nwrite)
    80005002:	2184a783          	lw	a5,536(s1)
    80005006:	21c4a703          	lw	a4,540(s1)
    8000500a:	02f70d63          	beq	a4,a5,80005044 <piperead+0xae>
    ch = pi->data[pi->nread++ % PIPESIZE];
    8000500e:	0017871b          	addiw	a4,a5,1
    80005012:	20e4ac23          	sw	a4,536(s1)
    80005016:	1ff7f793          	andi	a5,a5,511
    8000501a:	97a6                	add	a5,a5,s1
    8000501c:	0187c783          	lbu	a5,24(a5)
    80005020:	faf40fa3          	sb	a5,-65(s0)
    if(copyout(pr->pagetable, addr + i, &ch, 1) == -1)
    80005024:	4685                	li	a3,1
    80005026:	fbf40613          	addi	a2,s0,-65
    8000502a:	85ca                	mv	a1,s2
    8000502c:	050a3503          	ld	a0,80(s4)
    80005030:	ffffd097          	auipc	ra,0xffffd
    80005034:	8ac080e7          	jalr	-1876(ra) # 800018dc <copyout>
    80005038:	01650663          	beq	a0,s6,80005044 <piperead+0xae>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000503c:	2985                	addiw	s3,s3,1
    8000503e:	0905                	addi	s2,s2,1
    80005040:	fd3a91e3          	bne	s5,s3,80005002 <piperead+0x6c>
      break;
  }
  wakeup(&pi->nwrite);  //DOC: piperead-wakeup
    80005044:	21c48513          	addi	a0,s1,540
    80005048:	ffffd097          	auipc	ra,0xffffd
    8000504c:	426080e7          	jalr	1062(ra) # 8000246e <wakeup>
  release(&pi->lock);
    80005050:	8526                	mv	a0,s1
    80005052:	ffffc097          	auipc	ra,0xffffc
    80005056:	eb0080e7          	jalr	-336(ra) # 80000f02 <release>
  return i;
}
    8000505a:	854e                	mv	a0,s3
    8000505c:	60a6                	ld	ra,72(sp)
    8000505e:	6406                	ld	s0,64(sp)
    80005060:	74e2                	ld	s1,56(sp)
    80005062:	7942                	ld	s2,48(sp)
    80005064:	79a2                	ld	s3,40(sp)
    80005066:	7a02                	ld	s4,32(sp)
    80005068:	6ae2                	ld	s5,24(sp)
    8000506a:	6b42                	ld	s6,16(sp)
    8000506c:	6161                	addi	sp,sp,80
    8000506e:	8082                	ret
      release(&pi->lock);
    80005070:	8526                	mv	a0,s1
    80005072:	ffffc097          	auipc	ra,0xffffc
    80005076:	e90080e7          	jalr	-368(ra) # 80000f02 <release>
      return -1;
    8000507a:	59fd                	li	s3,-1
    8000507c:	bff9                	j	8000505a <piperead+0xc4>
  for(i = 0; i < n; i++){  //DOC: piperead-copy
    8000507e:	4981                	li	s3,0
    80005080:	b7d1                	j	80005044 <piperead+0xae>

0000000080005082 <exec>:

static int loadseg(pde_t *pgdir, uint64 addr, struct inode *ip, uint offset, uint sz);

int
exec(char *path, char **argv)
{
    80005082:	df010113          	addi	sp,sp,-528
    80005086:	20113423          	sd	ra,520(sp)
    8000508a:	20813023          	sd	s0,512(sp)
    8000508e:	ffa6                	sd	s1,504(sp)
    80005090:	fbca                	sd	s2,496(sp)
    80005092:	f7ce                	sd	s3,488(sp)
    80005094:	f3d2                	sd	s4,480(sp)
    80005096:	efd6                	sd	s5,472(sp)
    80005098:	ebda                	sd	s6,464(sp)
    8000509a:	e7de                	sd	s7,456(sp)
    8000509c:	e3e2                	sd	s8,448(sp)
    8000509e:	ff66                	sd	s9,440(sp)
    800050a0:	fb6a                	sd	s10,432(sp)
    800050a2:	f76e                	sd	s11,424(sp)
    800050a4:	0c00                	addi	s0,sp,528
    800050a6:	84aa                	mv	s1,a0
    800050a8:	dea43c23          	sd	a0,-520(s0)
    800050ac:	e0b43023          	sd	a1,-512(s0)
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
  struct elfhdr elf;
  struct inode *ip;
  struct proghdr ph;
  pagetable_t pagetable = 0, oldpagetable;
  struct proc *p = myproc();
    800050b0:	ffffd097          	auipc	ra,0xffffd
    800050b4:	b6a080e7          	jalr	-1174(ra) # 80001c1a <myproc>
    800050b8:	892a                	mv	s2,a0

  begin_op();
    800050ba:	fffff097          	auipc	ra,0xfffff
    800050be:	2be080e7          	jalr	702(ra) # 80004378 <begin_op>

  if((ip = namei(path)) == 0){
    800050c2:	8526                	mv	a0,s1
    800050c4:	fffff097          	auipc	ra,0xfffff
    800050c8:	098080e7          	jalr	152(ra) # 8000415c <namei>
    800050cc:	c92d                	beqz	a0,8000513e <exec+0xbc>
    800050ce:	84aa                	mv	s1,a0
    end_op();
    return -1;
  }
  ilock(ip);
    800050d0:	fffff097          	auipc	ra,0xfffff
    800050d4:	8d6080e7          	jalr	-1834(ra) # 800039a6 <ilock>

  // Check ELF header
  if(readi(ip, 0, (uint64)&elf, 0, sizeof(elf)) != sizeof(elf))
    800050d8:	04000713          	li	a4,64
    800050dc:	4681                	li	a3,0
    800050de:	e5040613          	addi	a2,s0,-432
    800050e2:	4581                	li	a1,0
    800050e4:	8526                	mv	a0,s1
    800050e6:	fffff097          	auipc	ra,0xfffff
    800050ea:	b74080e7          	jalr	-1164(ra) # 80003c5a <readi>
    800050ee:	04000793          	li	a5,64
    800050f2:	00f51a63          	bne	a0,a5,80005106 <exec+0x84>
    goto bad;
  if(elf.magic != ELF_MAGIC)
    800050f6:	e5042703          	lw	a4,-432(s0)
    800050fa:	464c47b7          	lui	a5,0x464c4
    800050fe:	57f78793          	addi	a5,a5,1407 # 464c457f <_entry-0x39b3ba81>
    80005102:	04f70463          	beq	a4,a5,8000514a <exec+0xc8>

 bad:
  if(pagetable)
    proc_freepagetable(pagetable, sz);
  if(ip){
    iunlockput(ip);
    80005106:	8526                	mv	a0,s1
    80005108:	fffff097          	auipc	ra,0xfffff
    8000510c:	b00080e7          	jalr	-1280(ra) # 80003c08 <iunlockput>
    end_op();
    80005110:	fffff097          	auipc	ra,0xfffff
    80005114:	2e8080e7          	jalr	744(ra) # 800043f8 <end_op>
  }
  return -1;
    80005118:	557d                	li	a0,-1
}
    8000511a:	20813083          	ld	ra,520(sp)
    8000511e:	20013403          	ld	s0,512(sp)
    80005122:	74fe                	ld	s1,504(sp)
    80005124:	795e                	ld	s2,496(sp)
    80005126:	79be                	ld	s3,488(sp)
    80005128:	7a1e                	ld	s4,480(sp)
    8000512a:	6afe                	ld	s5,472(sp)
    8000512c:	6b5e                	ld	s6,464(sp)
    8000512e:	6bbe                	ld	s7,456(sp)
    80005130:	6c1e                	ld	s8,448(sp)
    80005132:	7cfa                	ld	s9,440(sp)
    80005134:	7d5a                	ld	s10,432(sp)
    80005136:	7dba                	ld	s11,424(sp)
    80005138:	21010113          	addi	sp,sp,528
    8000513c:	8082                	ret
    end_op();
    8000513e:	fffff097          	auipc	ra,0xfffff
    80005142:	2ba080e7          	jalr	698(ra) # 800043f8 <end_op>
    return -1;
    80005146:	557d                	li	a0,-1
    80005148:	bfc9                	j	8000511a <exec+0x98>
  if((pagetable = proc_pagetable(p)) == 0)
    8000514a:	854a                	mv	a0,s2
    8000514c:	ffffd097          	auipc	ra,0xffffd
    80005150:	b92080e7          	jalr	-1134(ra) # 80001cde <proc_pagetable>
    80005154:	8baa                	mv	s7,a0
    80005156:	d945                	beqz	a0,80005106 <exec+0x84>
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005158:	e7042983          	lw	s3,-400(s0)
    8000515c:	e8845783          	lhu	a5,-376(s0)
    80005160:	c7ad                	beqz	a5,800051ca <exec+0x148>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    80005162:	4901                	li	s2,0
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    80005164:	4b01                	li	s6,0
    if((ph.vaddr % PGSIZE) != 0)
    80005166:	6c85                	lui	s9,0x1
    80005168:	fffc8793          	addi	a5,s9,-1 # fff <_entry-0x7ffff001>
    8000516c:	def43823          	sd	a5,-528(s0)
    80005170:	a42d                	j	8000539a <exec+0x318>
  uint64 pa;

  for(i = 0; i < sz; i += PGSIZE){
    pa = walkaddr(pagetable, va + i);
    if(pa == 0)
      panic("loadseg: address should exist");
    80005172:	00003517          	auipc	a0,0x3
    80005176:	63e50513          	addi	a0,a0,1598 # 800087b0 <syscalls+0x290>
    8000517a:	ffffb097          	auipc	ra,0xffffb
    8000517e:	3c4080e7          	jalr	964(ra) # 8000053e <panic>
    if(sz - i < PGSIZE)
      n = sz - i;
    else
      n = PGSIZE;
    if(readi(ip, 0, (uint64)pa, offset+i, n) != n)
    80005182:	8756                	mv	a4,s5
    80005184:	012d86bb          	addw	a3,s11,s2
    80005188:	4581                	li	a1,0
    8000518a:	8526                	mv	a0,s1
    8000518c:	fffff097          	auipc	ra,0xfffff
    80005190:	ace080e7          	jalr	-1330(ra) # 80003c5a <readi>
    80005194:	2501                	sext.w	a0,a0
    80005196:	1aaa9963          	bne	s5,a0,80005348 <exec+0x2c6>
  for(i = 0; i < sz; i += PGSIZE){
    8000519a:	6785                	lui	a5,0x1
    8000519c:	0127893b          	addw	s2,a5,s2
    800051a0:	77fd                	lui	a5,0xfffff
    800051a2:	01478a3b          	addw	s4,a5,s4
    800051a6:	1f897163          	bgeu	s2,s8,80005388 <exec+0x306>
    pa = walkaddr(pagetable, va + i);
    800051aa:	02091593          	slli	a1,s2,0x20
    800051ae:	9181                	srli	a1,a1,0x20
    800051b0:	95ea                	add	a1,a1,s10
    800051b2:	855e                	mv	a0,s7
    800051b4:	ffffc097          	auipc	ra,0xffffc
    800051b8:	124080e7          	jalr	292(ra) # 800012d8 <walkaddr>
    800051bc:	862a                	mv	a2,a0
    if(pa == 0)
    800051be:	d955                	beqz	a0,80005172 <exec+0xf0>
      n = PGSIZE;
    800051c0:	8ae6                	mv	s5,s9
    if(sz - i < PGSIZE)
    800051c2:	fd9a70e3          	bgeu	s4,s9,80005182 <exec+0x100>
      n = sz - i;
    800051c6:	8ad2                	mv	s5,s4
    800051c8:	bf6d                	j	80005182 <exec+0x100>
  uint64 argc, sz = 0, sp, ustack[MAXARG], stackbase;
    800051ca:	4901                	li	s2,0
  iunlockput(ip);
    800051cc:	8526                	mv	a0,s1
    800051ce:	fffff097          	auipc	ra,0xfffff
    800051d2:	a3a080e7          	jalr	-1478(ra) # 80003c08 <iunlockput>
  end_op();
    800051d6:	fffff097          	auipc	ra,0xfffff
    800051da:	222080e7          	jalr	546(ra) # 800043f8 <end_op>
  p = myproc();
    800051de:	ffffd097          	auipc	ra,0xffffd
    800051e2:	a3c080e7          	jalr	-1476(ra) # 80001c1a <myproc>
    800051e6:	8aaa                	mv	s5,a0
  uint64 oldsz = p->sz;
    800051e8:	04853d03          	ld	s10,72(a0)
  sz = PGROUNDUP(sz);
    800051ec:	6785                	lui	a5,0x1
    800051ee:	17fd                	addi	a5,a5,-1
    800051f0:	993e                	add	s2,s2,a5
    800051f2:	757d                	lui	a0,0xfffff
    800051f4:	00a977b3          	and	a5,s2,a0
    800051f8:	e0f43423          	sd	a5,-504(s0)
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    800051fc:	6609                	lui	a2,0x2
    800051fe:	963e                	add	a2,a2,a5
    80005200:	85be                	mv	a1,a5
    80005202:	855e                	mv	a0,s7
    80005204:	ffffc097          	auipc	ra,0xffffc
    80005208:	488080e7          	jalr	1160(ra) # 8000168c <uvmalloc>
    8000520c:	8b2a                	mv	s6,a0
  ip = 0;
    8000520e:	4481                	li	s1,0
  if((sz1 = uvmalloc(pagetable, sz, sz + 2*PGSIZE)) == 0)
    80005210:	12050c63          	beqz	a0,80005348 <exec+0x2c6>
  uvmclear(pagetable, sz-2*PGSIZE);
    80005214:	75f9                	lui	a1,0xffffe
    80005216:	95aa                	add	a1,a1,a0
    80005218:	855e                	mv	a0,s7
    8000521a:	ffffc097          	auipc	ra,0xffffc
    8000521e:	690080e7          	jalr	1680(ra) # 800018aa <uvmclear>
  stackbase = sp - PGSIZE;
    80005222:	7c7d                	lui	s8,0xfffff
    80005224:	9c5a                	add	s8,s8,s6
  for(argc = 0; argv[argc]; argc++) {
    80005226:	e0043783          	ld	a5,-512(s0)
    8000522a:	6388                	ld	a0,0(a5)
    8000522c:	c535                	beqz	a0,80005298 <exec+0x216>
    8000522e:	e9040993          	addi	s3,s0,-368
    80005232:	f9040c93          	addi	s9,s0,-112
  sp = sz;
    80005236:	895a                	mv	s2,s6
    sp -= strlen(argv[argc]) + 1;
    80005238:	ffffc097          	auipc	ra,0xffffc
    8000523c:	e96080e7          	jalr	-362(ra) # 800010ce <strlen>
    80005240:	2505                	addiw	a0,a0,1
    80005242:	40a90933          	sub	s2,s2,a0
    sp -= sp % 16; // riscv sp must be 16-byte aligned
    80005246:	ff097913          	andi	s2,s2,-16
    if(sp < stackbase)
    8000524a:	13896363          	bltu	s2,s8,80005370 <exec+0x2ee>
    if(copyout(pagetable, sp, argv[argc], strlen(argv[argc]) + 1) < 0)
    8000524e:	e0043d83          	ld	s11,-512(s0)
    80005252:	000dba03          	ld	s4,0(s11)
    80005256:	8552                	mv	a0,s4
    80005258:	ffffc097          	auipc	ra,0xffffc
    8000525c:	e76080e7          	jalr	-394(ra) # 800010ce <strlen>
    80005260:	0015069b          	addiw	a3,a0,1
    80005264:	8652                	mv	a2,s4
    80005266:	85ca                	mv	a1,s2
    80005268:	855e                	mv	a0,s7
    8000526a:	ffffc097          	auipc	ra,0xffffc
    8000526e:	672080e7          	jalr	1650(ra) # 800018dc <copyout>
    80005272:	10054363          	bltz	a0,80005378 <exec+0x2f6>
    ustack[argc] = sp;
    80005276:	0129b023          	sd	s2,0(s3)
  for(argc = 0; argv[argc]; argc++) {
    8000527a:	0485                	addi	s1,s1,1
    8000527c:	008d8793          	addi	a5,s11,8
    80005280:	e0f43023          	sd	a5,-512(s0)
    80005284:	008db503          	ld	a0,8(s11)
    80005288:	c911                	beqz	a0,8000529c <exec+0x21a>
    if(argc >= MAXARG)
    8000528a:	09a1                	addi	s3,s3,8
    8000528c:	fb3c96e3          	bne	s9,s3,80005238 <exec+0x1b6>
  sz = sz1;
    80005290:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005294:	4481                	li	s1,0
    80005296:	a84d                	j	80005348 <exec+0x2c6>
  sp = sz;
    80005298:	895a                	mv	s2,s6
  for(argc = 0; argv[argc]; argc++) {
    8000529a:	4481                	li	s1,0
  ustack[argc] = 0;
    8000529c:	00349793          	slli	a5,s1,0x3
    800052a0:	f9040713          	addi	a4,s0,-112
    800052a4:	97ba                	add	a5,a5,a4
    800052a6:	f007b023          	sd	zero,-256(a5) # f00 <_entry-0x7ffff100>
  sp -= (argc+1) * sizeof(uint64);
    800052aa:	00148693          	addi	a3,s1,1
    800052ae:	068e                	slli	a3,a3,0x3
    800052b0:	40d90933          	sub	s2,s2,a3
  sp -= sp % 16;
    800052b4:	ff097913          	andi	s2,s2,-16
  if(sp < stackbase)
    800052b8:	01897663          	bgeu	s2,s8,800052c4 <exec+0x242>
  sz = sz1;
    800052bc:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    800052c0:	4481                	li	s1,0
    800052c2:	a059                	j	80005348 <exec+0x2c6>
  if(copyout(pagetable, sp, (char *)ustack, (argc+1)*sizeof(uint64)) < 0)
    800052c4:	e9040613          	addi	a2,s0,-368
    800052c8:	85ca                	mv	a1,s2
    800052ca:	855e                	mv	a0,s7
    800052cc:	ffffc097          	auipc	ra,0xffffc
    800052d0:	610080e7          	jalr	1552(ra) # 800018dc <copyout>
    800052d4:	0a054663          	bltz	a0,80005380 <exec+0x2fe>
  p->trapframe->a1 = sp;
    800052d8:	058ab783          	ld	a5,88(s5)
    800052dc:	0727bc23          	sd	s2,120(a5)
  for(last=s=path; *s; s++)
    800052e0:	df843783          	ld	a5,-520(s0)
    800052e4:	0007c703          	lbu	a4,0(a5)
    800052e8:	cf11                	beqz	a4,80005304 <exec+0x282>
    800052ea:	0785                	addi	a5,a5,1
    if(*s == '/')
    800052ec:	02f00693          	li	a3,47
    800052f0:	a039                	j	800052fe <exec+0x27c>
      last = s+1;
    800052f2:	def43c23          	sd	a5,-520(s0)
  for(last=s=path; *s; s++)
    800052f6:	0785                	addi	a5,a5,1
    800052f8:	fff7c703          	lbu	a4,-1(a5)
    800052fc:	c701                	beqz	a4,80005304 <exec+0x282>
    if(*s == '/')
    800052fe:	fed71ce3          	bne	a4,a3,800052f6 <exec+0x274>
    80005302:	bfc5                	j	800052f2 <exec+0x270>
  safestrcpy(p->name, last, sizeof(p->name));
    80005304:	4641                	li	a2,16
    80005306:	df843583          	ld	a1,-520(s0)
    8000530a:	158a8513          	addi	a0,s5,344
    8000530e:	ffffc097          	auipc	ra,0xffffc
    80005312:	d8e080e7          	jalr	-626(ra) # 8000109c <safestrcpy>
  oldpagetable = p->pagetable;
    80005316:	050ab503          	ld	a0,80(s5)
  p->pagetable = pagetable;
    8000531a:	057ab823          	sd	s7,80(s5)
  p->sz = sz;
    8000531e:	056ab423          	sd	s6,72(s5)
  p->trapframe->epc = elf.entry;  // initial program counter = main
    80005322:	058ab783          	ld	a5,88(s5)
    80005326:	e6843703          	ld	a4,-408(s0)
    8000532a:	ef98                	sd	a4,24(a5)
  p->trapframe->sp = sp; // initial stack pointer
    8000532c:	058ab783          	ld	a5,88(s5)
    80005330:	0327b823          	sd	s2,48(a5)
  proc_freepagetable(oldpagetable, oldsz);
    80005334:	85ea                	mv	a1,s10
    80005336:	ffffd097          	auipc	ra,0xffffd
    8000533a:	a44080e7          	jalr	-1468(ra) # 80001d7a <proc_freepagetable>
  return argc; // this ends up in a0, the first argument to main(argc, argv)
    8000533e:	0004851b          	sext.w	a0,s1
    80005342:	bbe1                	j	8000511a <exec+0x98>
    80005344:	e1243423          	sd	s2,-504(s0)
    proc_freepagetable(pagetable, sz);
    80005348:	e0843583          	ld	a1,-504(s0)
    8000534c:	855e                	mv	a0,s7
    8000534e:	ffffd097          	auipc	ra,0xffffd
    80005352:	a2c080e7          	jalr	-1492(ra) # 80001d7a <proc_freepagetable>
  if(ip){
    80005356:	da0498e3          	bnez	s1,80005106 <exec+0x84>
  return -1;
    8000535a:	557d                	li	a0,-1
    8000535c:	bb7d                	j	8000511a <exec+0x98>
    8000535e:	e1243423          	sd	s2,-504(s0)
    80005362:	b7dd                	j	80005348 <exec+0x2c6>
    80005364:	e1243423          	sd	s2,-504(s0)
    80005368:	b7c5                	j	80005348 <exec+0x2c6>
    8000536a:	e1243423          	sd	s2,-504(s0)
    8000536e:	bfe9                	j	80005348 <exec+0x2c6>
  sz = sz1;
    80005370:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005374:	4481                	li	s1,0
    80005376:	bfc9                	j	80005348 <exec+0x2c6>
  sz = sz1;
    80005378:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    8000537c:	4481                	li	s1,0
    8000537e:	b7e9                	j	80005348 <exec+0x2c6>
  sz = sz1;
    80005380:	e1643423          	sd	s6,-504(s0)
  ip = 0;
    80005384:	4481                	li	s1,0
    80005386:	b7c9                	j	80005348 <exec+0x2c6>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    80005388:	e0843903          	ld	s2,-504(s0)
  for(i=0, off=elf.phoff; i<elf.phnum; i++, off+=sizeof(ph)){
    8000538c:	2b05                	addiw	s6,s6,1
    8000538e:	0389899b          	addiw	s3,s3,56
    80005392:	e8845783          	lhu	a5,-376(s0)
    80005396:	e2fb5be3          	bge	s6,a5,800051cc <exec+0x14a>
    if(readi(ip, 0, (uint64)&ph, off, sizeof(ph)) != sizeof(ph))
    8000539a:	2981                	sext.w	s3,s3
    8000539c:	03800713          	li	a4,56
    800053a0:	86ce                	mv	a3,s3
    800053a2:	e1840613          	addi	a2,s0,-488
    800053a6:	4581                	li	a1,0
    800053a8:	8526                	mv	a0,s1
    800053aa:	fffff097          	auipc	ra,0xfffff
    800053ae:	8b0080e7          	jalr	-1872(ra) # 80003c5a <readi>
    800053b2:	03800793          	li	a5,56
    800053b6:	f8f517e3          	bne	a0,a5,80005344 <exec+0x2c2>
    if(ph.type != ELF_PROG_LOAD)
    800053ba:	e1842783          	lw	a5,-488(s0)
    800053be:	4705                	li	a4,1
    800053c0:	fce796e3          	bne	a5,a4,8000538c <exec+0x30a>
    if(ph.memsz < ph.filesz)
    800053c4:	e4043603          	ld	a2,-448(s0)
    800053c8:	e3843783          	ld	a5,-456(s0)
    800053cc:	f8f669e3          	bltu	a2,a5,8000535e <exec+0x2dc>
    if(ph.vaddr + ph.memsz < ph.vaddr)
    800053d0:	e2843783          	ld	a5,-472(s0)
    800053d4:	963e                	add	a2,a2,a5
    800053d6:	f8f667e3          	bltu	a2,a5,80005364 <exec+0x2e2>
    if((sz1 = uvmalloc(pagetable, sz, ph.vaddr + ph.memsz)) == 0)
    800053da:	85ca                	mv	a1,s2
    800053dc:	855e                	mv	a0,s7
    800053de:	ffffc097          	auipc	ra,0xffffc
    800053e2:	2ae080e7          	jalr	686(ra) # 8000168c <uvmalloc>
    800053e6:	e0a43423          	sd	a0,-504(s0)
    800053ea:	d141                	beqz	a0,8000536a <exec+0x2e8>
    if((ph.vaddr % PGSIZE) != 0)
    800053ec:	e2843d03          	ld	s10,-472(s0)
    800053f0:	df043783          	ld	a5,-528(s0)
    800053f4:	00fd77b3          	and	a5,s10,a5
    800053f8:	fba1                	bnez	a5,80005348 <exec+0x2c6>
    if(loadseg(pagetable, ph.vaddr, ip, ph.off, ph.filesz) < 0)
    800053fa:	e2042d83          	lw	s11,-480(s0)
    800053fe:	e3842c03          	lw	s8,-456(s0)
  for(i = 0; i < sz; i += PGSIZE){
    80005402:	f80c03e3          	beqz	s8,80005388 <exec+0x306>
    80005406:	8a62                	mv	s4,s8
    80005408:	4901                	li	s2,0
    8000540a:	b345                	j	800051aa <exec+0x128>

000000008000540c <argfd>:

// Fetch the nth word-sized system call argument as a file descriptor
// and return both the descriptor and the corresponding struct file.
static int
argfd(int n, int *pfd, struct file **pf)
{
    8000540c:	7179                	addi	sp,sp,-48
    8000540e:	f406                	sd	ra,40(sp)
    80005410:	f022                	sd	s0,32(sp)
    80005412:	ec26                	sd	s1,24(sp)
    80005414:	e84a                	sd	s2,16(sp)
    80005416:	1800                	addi	s0,sp,48
    80005418:	892e                	mv	s2,a1
    8000541a:	84b2                	mv	s1,a2
  int fd;
  struct file *f;

  if(argint(n, &fd) < 0)
    8000541c:	fdc40593          	addi	a1,s0,-36
    80005420:	ffffe097          	auipc	ra,0xffffe
    80005424:	a14080e7          	jalr	-1516(ra) # 80002e34 <argint>
    80005428:	04054063          	bltz	a0,80005468 <argfd+0x5c>
    return -1;
  if(fd < 0 || fd >= NOFILE || (f=myproc()->ofile[fd]) == 0)
    8000542c:	fdc42703          	lw	a4,-36(s0)
    80005430:	47bd                	li	a5,15
    80005432:	02e7ed63          	bltu	a5,a4,8000546c <argfd+0x60>
    80005436:	ffffc097          	auipc	ra,0xffffc
    8000543a:	7e4080e7          	jalr	2020(ra) # 80001c1a <myproc>
    8000543e:	fdc42703          	lw	a4,-36(s0)
    80005442:	01a70793          	addi	a5,a4,26
    80005446:	078e                	slli	a5,a5,0x3
    80005448:	953e                	add	a0,a0,a5
    8000544a:	611c                	ld	a5,0(a0)
    8000544c:	c395                	beqz	a5,80005470 <argfd+0x64>
    return -1;
  if(pfd)
    8000544e:	00090463          	beqz	s2,80005456 <argfd+0x4a>
    *pfd = fd;
    80005452:	00e92023          	sw	a4,0(s2)
  if(pf)
    *pf = f;
  return 0;
    80005456:	4501                	li	a0,0
  if(pf)
    80005458:	c091                	beqz	s1,8000545c <argfd+0x50>
    *pf = f;
    8000545a:	e09c                	sd	a5,0(s1)
}
    8000545c:	70a2                	ld	ra,40(sp)
    8000545e:	7402                	ld	s0,32(sp)
    80005460:	64e2                	ld	s1,24(sp)
    80005462:	6942                	ld	s2,16(sp)
    80005464:	6145                	addi	sp,sp,48
    80005466:	8082                	ret
    return -1;
    80005468:	557d                	li	a0,-1
    8000546a:	bfcd                	j	8000545c <argfd+0x50>
    return -1;
    8000546c:	557d                	li	a0,-1
    8000546e:	b7fd                	j	8000545c <argfd+0x50>
    80005470:	557d                	li	a0,-1
    80005472:	b7ed                	j	8000545c <argfd+0x50>

0000000080005474 <fdalloc>:

// Allocate a file descriptor for the given file.
// Takes over file reference from caller on success.
static int
fdalloc(struct file *f)
{
    80005474:	1101                	addi	sp,sp,-32
    80005476:	ec06                	sd	ra,24(sp)
    80005478:	e822                	sd	s0,16(sp)
    8000547a:	e426                	sd	s1,8(sp)
    8000547c:	1000                	addi	s0,sp,32
    8000547e:	84aa                	mv	s1,a0
  int fd;
  struct proc *p = myproc();
    80005480:	ffffc097          	auipc	ra,0xffffc
    80005484:	79a080e7          	jalr	1946(ra) # 80001c1a <myproc>
    80005488:	862a                	mv	a2,a0

  for(fd = 0; fd < NOFILE; fd++){
    8000548a:	0d050793          	addi	a5,a0,208 # fffffffffffff0d0 <end+0xffffffff7f7590d0>
    8000548e:	4501                	li	a0,0
    80005490:	46c1                	li	a3,16
    if(p->ofile[fd] == 0){
    80005492:	6398                	ld	a4,0(a5)
    80005494:	cb19                	beqz	a4,800054aa <fdalloc+0x36>
  for(fd = 0; fd < NOFILE; fd++){
    80005496:	2505                	addiw	a0,a0,1
    80005498:	07a1                	addi	a5,a5,8
    8000549a:	fed51ce3          	bne	a0,a3,80005492 <fdalloc+0x1e>
      p->ofile[fd] = f;
      return fd;
    }
  }
  return -1;
    8000549e:	557d                	li	a0,-1
}
    800054a0:	60e2                	ld	ra,24(sp)
    800054a2:	6442                	ld	s0,16(sp)
    800054a4:	64a2                	ld	s1,8(sp)
    800054a6:	6105                	addi	sp,sp,32
    800054a8:	8082                	ret
      p->ofile[fd] = f;
    800054aa:	01a50793          	addi	a5,a0,26
    800054ae:	078e                	slli	a5,a5,0x3
    800054b0:	963e                	add	a2,a2,a5
    800054b2:	e204                	sd	s1,0(a2)
      return fd;
    800054b4:	b7f5                	j	800054a0 <fdalloc+0x2c>

00000000800054b6 <create>:
  return -1;
}

static struct inode*
create(char *path, short type, short major, short minor)
{
    800054b6:	715d                	addi	sp,sp,-80
    800054b8:	e486                	sd	ra,72(sp)
    800054ba:	e0a2                	sd	s0,64(sp)
    800054bc:	fc26                	sd	s1,56(sp)
    800054be:	f84a                	sd	s2,48(sp)
    800054c0:	f44e                	sd	s3,40(sp)
    800054c2:	f052                	sd	s4,32(sp)
    800054c4:	ec56                	sd	s5,24(sp)
    800054c6:	0880                	addi	s0,sp,80
    800054c8:	89ae                	mv	s3,a1
    800054ca:	8ab2                	mv	s5,a2
    800054cc:	8a36                	mv	s4,a3
  struct inode *ip, *dp;
  char name[DIRSIZ];

  if((dp = nameiparent(path, name)) == 0)
    800054ce:	fb040593          	addi	a1,s0,-80
    800054d2:	fffff097          	auipc	ra,0xfffff
    800054d6:	ca8080e7          	jalr	-856(ra) # 8000417a <nameiparent>
    800054da:	892a                	mv	s2,a0
    800054dc:	12050f63          	beqz	a0,8000561a <create+0x164>
    return 0;

  ilock(dp);
    800054e0:	ffffe097          	auipc	ra,0xffffe
    800054e4:	4c6080e7          	jalr	1222(ra) # 800039a6 <ilock>

  if((ip = dirlookup(dp, name, 0)) != 0){
    800054e8:	4601                	li	a2,0
    800054ea:	fb040593          	addi	a1,s0,-80
    800054ee:	854a                	mv	a0,s2
    800054f0:	fffff097          	auipc	ra,0xfffff
    800054f4:	99a080e7          	jalr	-1638(ra) # 80003e8a <dirlookup>
    800054f8:	84aa                	mv	s1,a0
    800054fa:	c921                	beqz	a0,8000554a <create+0x94>
    iunlockput(dp);
    800054fc:	854a                	mv	a0,s2
    800054fe:	ffffe097          	auipc	ra,0xffffe
    80005502:	70a080e7          	jalr	1802(ra) # 80003c08 <iunlockput>
    ilock(ip);
    80005506:	8526                	mv	a0,s1
    80005508:	ffffe097          	auipc	ra,0xffffe
    8000550c:	49e080e7          	jalr	1182(ra) # 800039a6 <ilock>
    if(type == T_FILE && (ip->type == T_FILE || ip->type == T_DEVICE))
    80005510:	2981                	sext.w	s3,s3
    80005512:	4789                	li	a5,2
    80005514:	02f99463          	bne	s3,a5,8000553c <create+0x86>
    80005518:	0444d783          	lhu	a5,68(s1)
    8000551c:	37f9                	addiw	a5,a5,-2
    8000551e:	17c2                	slli	a5,a5,0x30
    80005520:	93c1                	srli	a5,a5,0x30
    80005522:	4705                	li	a4,1
    80005524:	00f76c63          	bltu	a4,a5,8000553c <create+0x86>
    panic("create: dirlink");

  iunlockput(dp);

  return ip;
}
    80005528:	8526                	mv	a0,s1
    8000552a:	60a6                	ld	ra,72(sp)
    8000552c:	6406                	ld	s0,64(sp)
    8000552e:	74e2                	ld	s1,56(sp)
    80005530:	7942                	ld	s2,48(sp)
    80005532:	79a2                	ld	s3,40(sp)
    80005534:	7a02                	ld	s4,32(sp)
    80005536:	6ae2                	ld	s5,24(sp)
    80005538:	6161                	addi	sp,sp,80
    8000553a:	8082                	ret
    iunlockput(ip);
    8000553c:	8526                	mv	a0,s1
    8000553e:	ffffe097          	auipc	ra,0xffffe
    80005542:	6ca080e7          	jalr	1738(ra) # 80003c08 <iunlockput>
    return 0;
    80005546:	4481                	li	s1,0
    80005548:	b7c5                	j	80005528 <create+0x72>
  if((ip = ialloc(dp->dev, type)) == 0)
    8000554a:	85ce                	mv	a1,s3
    8000554c:	00092503          	lw	a0,0(s2)
    80005550:	ffffe097          	auipc	ra,0xffffe
    80005554:	2be080e7          	jalr	702(ra) # 8000380e <ialloc>
    80005558:	84aa                	mv	s1,a0
    8000555a:	c529                	beqz	a0,800055a4 <create+0xee>
  ilock(ip);
    8000555c:	ffffe097          	auipc	ra,0xffffe
    80005560:	44a080e7          	jalr	1098(ra) # 800039a6 <ilock>
  ip->major = major;
    80005564:	05549323          	sh	s5,70(s1)
  ip->minor = minor;
    80005568:	05449423          	sh	s4,72(s1)
  ip->nlink = 1;
    8000556c:	4785                	li	a5,1
    8000556e:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005572:	8526                	mv	a0,s1
    80005574:	ffffe097          	auipc	ra,0xffffe
    80005578:	368080e7          	jalr	872(ra) # 800038dc <iupdate>
  if(type == T_DIR){  // Create . and .. entries.
    8000557c:	2981                	sext.w	s3,s3
    8000557e:	4785                	li	a5,1
    80005580:	02f98a63          	beq	s3,a5,800055b4 <create+0xfe>
  if(dirlink(dp, name, ip->inum) < 0)
    80005584:	40d0                	lw	a2,4(s1)
    80005586:	fb040593          	addi	a1,s0,-80
    8000558a:	854a                	mv	a0,s2
    8000558c:	fffff097          	auipc	ra,0xfffff
    80005590:	b0e080e7          	jalr	-1266(ra) # 8000409a <dirlink>
    80005594:	06054b63          	bltz	a0,8000560a <create+0x154>
  iunlockput(dp);
    80005598:	854a                	mv	a0,s2
    8000559a:	ffffe097          	auipc	ra,0xffffe
    8000559e:	66e080e7          	jalr	1646(ra) # 80003c08 <iunlockput>
  return ip;
    800055a2:	b759                	j	80005528 <create+0x72>
    panic("create: ialloc");
    800055a4:	00003517          	auipc	a0,0x3
    800055a8:	22c50513          	addi	a0,a0,556 # 800087d0 <syscalls+0x2b0>
    800055ac:	ffffb097          	auipc	ra,0xffffb
    800055b0:	f92080e7          	jalr	-110(ra) # 8000053e <panic>
    dp->nlink++;  // for ".."
    800055b4:	04a95783          	lhu	a5,74(s2)
    800055b8:	2785                	addiw	a5,a5,1
    800055ba:	04f91523          	sh	a5,74(s2)
    iupdate(dp);
    800055be:	854a                	mv	a0,s2
    800055c0:	ffffe097          	auipc	ra,0xffffe
    800055c4:	31c080e7          	jalr	796(ra) # 800038dc <iupdate>
    if(dirlink(ip, ".", ip->inum) < 0 || dirlink(ip, "..", dp->inum) < 0)
    800055c8:	40d0                	lw	a2,4(s1)
    800055ca:	00003597          	auipc	a1,0x3
    800055ce:	21658593          	addi	a1,a1,534 # 800087e0 <syscalls+0x2c0>
    800055d2:	8526                	mv	a0,s1
    800055d4:	fffff097          	auipc	ra,0xfffff
    800055d8:	ac6080e7          	jalr	-1338(ra) # 8000409a <dirlink>
    800055dc:	00054f63          	bltz	a0,800055fa <create+0x144>
    800055e0:	00492603          	lw	a2,4(s2)
    800055e4:	00003597          	auipc	a1,0x3
    800055e8:	20458593          	addi	a1,a1,516 # 800087e8 <syscalls+0x2c8>
    800055ec:	8526                	mv	a0,s1
    800055ee:	fffff097          	auipc	ra,0xfffff
    800055f2:	aac080e7          	jalr	-1364(ra) # 8000409a <dirlink>
    800055f6:	f80557e3          	bgez	a0,80005584 <create+0xce>
      panic("create dots");
    800055fa:	00003517          	auipc	a0,0x3
    800055fe:	1f650513          	addi	a0,a0,502 # 800087f0 <syscalls+0x2d0>
    80005602:	ffffb097          	auipc	ra,0xffffb
    80005606:	f3c080e7          	jalr	-196(ra) # 8000053e <panic>
    panic("create: dirlink");
    8000560a:	00003517          	auipc	a0,0x3
    8000560e:	1f650513          	addi	a0,a0,502 # 80008800 <syscalls+0x2e0>
    80005612:	ffffb097          	auipc	ra,0xffffb
    80005616:	f2c080e7          	jalr	-212(ra) # 8000053e <panic>
    return 0;
    8000561a:	84aa                	mv	s1,a0
    8000561c:	b731                	j	80005528 <create+0x72>

000000008000561e <sys_dup>:
{
    8000561e:	7179                	addi	sp,sp,-48
    80005620:	f406                	sd	ra,40(sp)
    80005622:	f022                	sd	s0,32(sp)
    80005624:	ec26                	sd	s1,24(sp)
    80005626:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0)
    80005628:	fd840613          	addi	a2,s0,-40
    8000562c:	4581                	li	a1,0
    8000562e:	4501                	li	a0,0
    80005630:	00000097          	auipc	ra,0x0
    80005634:	ddc080e7          	jalr	-548(ra) # 8000540c <argfd>
    return -1;
    80005638:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0)
    8000563a:	02054363          	bltz	a0,80005660 <sys_dup+0x42>
  if((fd=fdalloc(f)) < 0)
    8000563e:	fd843503          	ld	a0,-40(s0)
    80005642:	00000097          	auipc	ra,0x0
    80005646:	e32080e7          	jalr	-462(ra) # 80005474 <fdalloc>
    8000564a:	84aa                	mv	s1,a0
    return -1;
    8000564c:	57fd                	li	a5,-1
  if((fd=fdalloc(f)) < 0)
    8000564e:	00054963          	bltz	a0,80005660 <sys_dup+0x42>
  filedup(f);
    80005652:	fd843503          	ld	a0,-40(s0)
    80005656:	fffff097          	auipc	ra,0xfffff
    8000565a:	19c080e7          	jalr	412(ra) # 800047f2 <filedup>
  return fd;
    8000565e:	87a6                	mv	a5,s1
}
    80005660:	853e                	mv	a0,a5
    80005662:	70a2                	ld	ra,40(sp)
    80005664:	7402                	ld	s0,32(sp)
    80005666:	64e2                	ld	s1,24(sp)
    80005668:	6145                	addi	sp,sp,48
    8000566a:	8082                	ret

000000008000566c <sys_read>:
{
    8000566c:	7179                	addi	sp,sp,-48
    8000566e:	f406                	sd	ra,40(sp)
    80005670:	f022                	sd	s0,32(sp)
    80005672:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005674:	fe840613          	addi	a2,s0,-24
    80005678:	4581                	li	a1,0
    8000567a:	4501                	li	a0,0
    8000567c:	00000097          	auipc	ra,0x0
    80005680:	d90080e7          	jalr	-624(ra) # 8000540c <argfd>
    return -1;
    80005684:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005686:	04054163          	bltz	a0,800056c8 <sys_read+0x5c>
    8000568a:	fe440593          	addi	a1,s0,-28
    8000568e:	4509                	li	a0,2
    80005690:	ffffd097          	auipc	ra,0xffffd
    80005694:	7a4080e7          	jalr	1956(ra) # 80002e34 <argint>
    return -1;
    80005698:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    8000569a:	02054763          	bltz	a0,800056c8 <sys_read+0x5c>
    8000569e:	fd840593          	addi	a1,s0,-40
    800056a2:	4505                	li	a0,1
    800056a4:	ffffd097          	auipc	ra,0xffffd
    800056a8:	7b2080e7          	jalr	1970(ra) # 80002e56 <argaddr>
    return -1;
    800056ac:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056ae:	00054d63          	bltz	a0,800056c8 <sys_read+0x5c>
  return fileread(f, p, n);
    800056b2:	fe442603          	lw	a2,-28(s0)
    800056b6:	fd843583          	ld	a1,-40(s0)
    800056ba:	fe843503          	ld	a0,-24(s0)
    800056be:	fffff097          	auipc	ra,0xfffff
    800056c2:	2c0080e7          	jalr	704(ra) # 8000497e <fileread>
    800056c6:	87aa                	mv	a5,a0
}
    800056c8:	853e                	mv	a0,a5
    800056ca:	70a2                	ld	ra,40(sp)
    800056cc:	7402                	ld	s0,32(sp)
    800056ce:	6145                	addi	sp,sp,48
    800056d0:	8082                	ret

00000000800056d2 <sys_write>:
{
    800056d2:	7179                	addi	sp,sp,-48
    800056d4:	f406                	sd	ra,40(sp)
    800056d6:	f022                	sd	s0,32(sp)
    800056d8:	1800                	addi	s0,sp,48
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056da:	fe840613          	addi	a2,s0,-24
    800056de:	4581                	li	a1,0
    800056e0:	4501                	li	a0,0
    800056e2:	00000097          	auipc	ra,0x0
    800056e6:	d2a080e7          	jalr	-726(ra) # 8000540c <argfd>
    return -1;
    800056ea:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    800056ec:	04054163          	bltz	a0,8000572e <sys_write+0x5c>
    800056f0:	fe440593          	addi	a1,s0,-28
    800056f4:	4509                	li	a0,2
    800056f6:	ffffd097          	auipc	ra,0xffffd
    800056fa:	73e080e7          	jalr	1854(ra) # 80002e34 <argint>
    return -1;
    800056fe:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005700:	02054763          	bltz	a0,8000572e <sys_write+0x5c>
    80005704:	fd840593          	addi	a1,s0,-40
    80005708:	4505                	li	a0,1
    8000570a:	ffffd097          	auipc	ra,0xffffd
    8000570e:	74c080e7          	jalr	1868(ra) # 80002e56 <argaddr>
    return -1;
    80005712:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argint(2, &n) < 0 || argaddr(1, &p) < 0)
    80005714:	00054d63          	bltz	a0,8000572e <sys_write+0x5c>
  return filewrite(f, p, n);
    80005718:	fe442603          	lw	a2,-28(s0)
    8000571c:	fd843583          	ld	a1,-40(s0)
    80005720:	fe843503          	ld	a0,-24(s0)
    80005724:	fffff097          	auipc	ra,0xfffff
    80005728:	31c080e7          	jalr	796(ra) # 80004a40 <filewrite>
    8000572c:	87aa                	mv	a5,a0
}
    8000572e:	853e                	mv	a0,a5
    80005730:	70a2                	ld	ra,40(sp)
    80005732:	7402                	ld	s0,32(sp)
    80005734:	6145                	addi	sp,sp,48
    80005736:	8082                	ret

0000000080005738 <sys_close>:
{
    80005738:	1101                	addi	sp,sp,-32
    8000573a:	ec06                	sd	ra,24(sp)
    8000573c:	e822                	sd	s0,16(sp)
    8000573e:	1000                	addi	s0,sp,32
  if(argfd(0, &fd, &f) < 0)
    80005740:	fe040613          	addi	a2,s0,-32
    80005744:	fec40593          	addi	a1,s0,-20
    80005748:	4501                	li	a0,0
    8000574a:	00000097          	auipc	ra,0x0
    8000574e:	cc2080e7          	jalr	-830(ra) # 8000540c <argfd>
    return -1;
    80005752:	57fd                	li	a5,-1
  if(argfd(0, &fd, &f) < 0)
    80005754:	02054463          	bltz	a0,8000577c <sys_close+0x44>
  myproc()->ofile[fd] = 0;
    80005758:	ffffc097          	auipc	ra,0xffffc
    8000575c:	4c2080e7          	jalr	1218(ra) # 80001c1a <myproc>
    80005760:	fec42783          	lw	a5,-20(s0)
    80005764:	07e9                	addi	a5,a5,26
    80005766:	078e                	slli	a5,a5,0x3
    80005768:	97aa                	add	a5,a5,a0
    8000576a:	0007b023          	sd	zero,0(a5)
  fileclose(f);
    8000576e:	fe043503          	ld	a0,-32(s0)
    80005772:	fffff097          	auipc	ra,0xfffff
    80005776:	0d2080e7          	jalr	210(ra) # 80004844 <fileclose>
  return 0;
    8000577a:	4781                	li	a5,0
}
    8000577c:	853e                	mv	a0,a5
    8000577e:	60e2                	ld	ra,24(sp)
    80005780:	6442                	ld	s0,16(sp)
    80005782:	6105                	addi	sp,sp,32
    80005784:	8082                	ret

0000000080005786 <sys_fstat>:
{
    80005786:	1101                	addi	sp,sp,-32
    80005788:	ec06                	sd	ra,24(sp)
    8000578a:	e822                	sd	s0,16(sp)
    8000578c:	1000                	addi	s0,sp,32
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    8000578e:	fe840613          	addi	a2,s0,-24
    80005792:	4581                	li	a1,0
    80005794:	4501                	li	a0,0
    80005796:	00000097          	auipc	ra,0x0
    8000579a:	c76080e7          	jalr	-906(ra) # 8000540c <argfd>
    return -1;
    8000579e:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800057a0:	02054563          	bltz	a0,800057ca <sys_fstat+0x44>
    800057a4:	fe040593          	addi	a1,s0,-32
    800057a8:	4505                	li	a0,1
    800057aa:	ffffd097          	auipc	ra,0xffffd
    800057ae:	6ac080e7          	jalr	1708(ra) # 80002e56 <argaddr>
    return -1;
    800057b2:	57fd                	li	a5,-1
  if(argfd(0, 0, &f) < 0 || argaddr(1, &st) < 0)
    800057b4:	00054b63          	bltz	a0,800057ca <sys_fstat+0x44>
  return filestat(f, st);
    800057b8:	fe043583          	ld	a1,-32(s0)
    800057bc:	fe843503          	ld	a0,-24(s0)
    800057c0:	fffff097          	auipc	ra,0xfffff
    800057c4:	14c080e7          	jalr	332(ra) # 8000490c <filestat>
    800057c8:	87aa                	mv	a5,a0
}
    800057ca:	853e                	mv	a0,a5
    800057cc:	60e2                	ld	ra,24(sp)
    800057ce:	6442                	ld	s0,16(sp)
    800057d0:	6105                	addi	sp,sp,32
    800057d2:	8082                	ret

00000000800057d4 <sys_link>:
{
    800057d4:	7169                	addi	sp,sp,-304
    800057d6:	f606                	sd	ra,296(sp)
    800057d8:	f222                	sd	s0,288(sp)
    800057da:	ee26                	sd	s1,280(sp)
    800057dc:	ea4a                	sd	s2,272(sp)
    800057de:	1a00                	addi	s0,sp,304
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800057e0:	08000613          	li	a2,128
    800057e4:	ed040593          	addi	a1,s0,-304
    800057e8:	4501                	li	a0,0
    800057ea:	ffffd097          	auipc	ra,0xffffd
    800057ee:	68e080e7          	jalr	1678(ra) # 80002e78 <argstr>
    return -1;
    800057f2:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    800057f4:	10054e63          	bltz	a0,80005910 <sys_link+0x13c>
    800057f8:	08000613          	li	a2,128
    800057fc:	f5040593          	addi	a1,s0,-176
    80005800:	4505                	li	a0,1
    80005802:	ffffd097          	auipc	ra,0xffffd
    80005806:	676080e7          	jalr	1654(ra) # 80002e78 <argstr>
    return -1;
    8000580a:	57fd                	li	a5,-1
  if(argstr(0, old, MAXPATH) < 0 || argstr(1, new, MAXPATH) < 0)
    8000580c:	10054263          	bltz	a0,80005910 <sys_link+0x13c>
  begin_op();
    80005810:	fffff097          	auipc	ra,0xfffff
    80005814:	b68080e7          	jalr	-1176(ra) # 80004378 <begin_op>
  if((ip = namei(old)) == 0){
    80005818:	ed040513          	addi	a0,s0,-304
    8000581c:	fffff097          	auipc	ra,0xfffff
    80005820:	940080e7          	jalr	-1728(ra) # 8000415c <namei>
    80005824:	84aa                	mv	s1,a0
    80005826:	c551                	beqz	a0,800058b2 <sys_link+0xde>
  ilock(ip);
    80005828:	ffffe097          	auipc	ra,0xffffe
    8000582c:	17e080e7          	jalr	382(ra) # 800039a6 <ilock>
  if(ip->type == T_DIR){
    80005830:	04449703          	lh	a4,68(s1)
    80005834:	4785                	li	a5,1
    80005836:	08f70463          	beq	a4,a5,800058be <sys_link+0xea>
  ip->nlink++;
    8000583a:	04a4d783          	lhu	a5,74(s1)
    8000583e:	2785                	addiw	a5,a5,1
    80005840:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    80005844:	8526                	mv	a0,s1
    80005846:	ffffe097          	auipc	ra,0xffffe
    8000584a:	096080e7          	jalr	150(ra) # 800038dc <iupdate>
  iunlock(ip);
    8000584e:	8526                	mv	a0,s1
    80005850:	ffffe097          	auipc	ra,0xffffe
    80005854:	218080e7          	jalr	536(ra) # 80003a68 <iunlock>
  if((dp = nameiparent(new, name)) == 0)
    80005858:	fd040593          	addi	a1,s0,-48
    8000585c:	f5040513          	addi	a0,s0,-176
    80005860:	fffff097          	auipc	ra,0xfffff
    80005864:	91a080e7          	jalr	-1766(ra) # 8000417a <nameiparent>
    80005868:	892a                	mv	s2,a0
    8000586a:	c935                	beqz	a0,800058de <sys_link+0x10a>
  ilock(dp);
    8000586c:	ffffe097          	auipc	ra,0xffffe
    80005870:	13a080e7          	jalr	314(ra) # 800039a6 <ilock>
  if(dp->dev != ip->dev || dirlink(dp, name, ip->inum) < 0){
    80005874:	00092703          	lw	a4,0(s2)
    80005878:	409c                	lw	a5,0(s1)
    8000587a:	04f71d63          	bne	a4,a5,800058d4 <sys_link+0x100>
    8000587e:	40d0                	lw	a2,4(s1)
    80005880:	fd040593          	addi	a1,s0,-48
    80005884:	854a                	mv	a0,s2
    80005886:	fffff097          	auipc	ra,0xfffff
    8000588a:	814080e7          	jalr	-2028(ra) # 8000409a <dirlink>
    8000588e:	04054363          	bltz	a0,800058d4 <sys_link+0x100>
  iunlockput(dp);
    80005892:	854a                	mv	a0,s2
    80005894:	ffffe097          	auipc	ra,0xffffe
    80005898:	374080e7          	jalr	884(ra) # 80003c08 <iunlockput>
  iput(ip);
    8000589c:	8526                	mv	a0,s1
    8000589e:	ffffe097          	auipc	ra,0xffffe
    800058a2:	2c2080e7          	jalr	706(ra) # 80003b60 <iput>
  end_op();
    800058a6:	fffff097          	auipc	ra,0xfffff
    800058aa:	b52080e7          	jalr	-1198(ra) # 800043f8 <end_op>
  return 0;
    800058ae:	4781                	li	a5,0
    800058b0:	a085                	j	80005910 <sys_link+0x13c>
    end_op();
    800058b2:	fffff097          	auipc	ra,0xfffff
    800058b6:	b46080e7          	jalr	-1210(ra) # 800043f8 <end_op>
    return -1;
    800058ba:	57fd                	li	a5,-1
    800058bc:	a891                	j	80005910 <sys_link+0x13c>
    iunlockput(ip);
    800058be:	8526                	mv	a0,s1
    800058c0:	ffffe097          	auipc	ra,0xffffe
    800058c4:	348080e7          	jalr	840(ra) # 80003c08 <iunlockput>
    end_op();
    800058c8:	fffff097          	auipc	ra,0xfffff
    800058cc:	b30080e7          	jalr	-1232(ra) # 800043f8 <end_op>
    return -1;
    800058d0:	57fd                	li	a5,-1
    800058d2:	a83d                	j	80005910 <sys_link+0x13c>
    iunlockput(dp);
    800058d4:	854a                	mv	a0,s2
    800058d6:	ffffe097          	auipc	ra,0xffffe
    800058da:	332080e7          	jalr	818(ra) # 80003c08 <iunlockput>
  ilock(ip);
    800058de:	8526                	mv	a0,s1
    800058e0:	ffffe097          	auipc	ra,0xffffe
    800058e4:	0c6080e7          	jalr	198(ra) # 800039a6 <ilock>
  ip->nlink--;
    800058e8:	04a4d783          	lhu	a5,74(s1)
    800058ec:	37fd                	addiw	a5,a5,-1
    800058ee:	04f49523          	sh	a5,74(s1)
  iupdate(ip);
    800058f2:	8526                	mv	a0,s1
    800058f4:	ffffe097          	auipc	ra,0xffffe
    800058f8:	fe8080e7          	jalr	-24(ra) # 800038dc <iupdate>
  iunlockput(ip);
    800058fc:	8526                	mv	a0,s1
    800058fe:	ffffe097          	auipc	ra,0xffffe
    80005902:	30a080e7          	jalr	778(ra) # 80003c08 <iunlockput>
  end_op();
    80005906:	fffff097          	auipc	ra,0xfffff
    8000590a:	af2080e7          	jalr	-1294(ra) # 800043f8 <end_op>
  return -1;
    8000590e:	57fd                	li	a5,-1
}
    80005910:	853e                	mv	a0,a5
    80005912:	70b2                	ld	ra,296(sp)
    80005914:	7412                	ld	s0,288(sp)
    80005916:	64f2                	ld	s1,280(sp)
    80005918:	6952                	ld	s2,272(sp)
    8000591a:	6155                	addi	sp,sp,304
    8000591c:	8082                	ret

000000008000591e <sys_unlink>:
{
    8000591e:	7151                	addi	sp,sp,-240
    80005920:	f586                	sd	ra,232(sp)
    80005922:	f1a2                	sd	s0,224(sp)
    80005924:	eda6                	sd	s1,216(sp)
    80005926:	e9ca                	sd	s2,208(sp)
    80005928:	e5ce                	sd	s3,200(sp)
    8000592a:	1980                	addi	s0,sp,240
  if(argstr(0, path, MAXPATH) < 0)
    8000592c:	08000613          	li	a2,128
    80005930:	f3040593          	addi	a1,s0,-208
    80005934:	4501                	li	a0,0
    80005936:	ffffd097          	auipc	ra,0xffffd
    8000593a:	542080e7          	jalr	1346(ra) # 80002e78 <argstr>
    8000593e:	18054163          	bltz	a0,80005ac0 <sys_unlink+0x1a2>
  begin_op();
    80005942:	fffff097          	auipc	ra,0xfffff
    80005946:	a36080e7          	jalr	-1482(ra) # 80004378 <begin_op>
  if((dp = nameiparent(path, name)) == 0){
    8000594a:	fb040593          	addi	a1,s0,-80
    8000594e:	f3040513          	addi	a0,s0,-208
    80005952:	fffff097          	auipc	ra,0xfffff
    80005956:	828080e7          	jalr	-2008(ra) # 8000417a <nameiparent>
    8000595a:	84aa                	mv	s1,a0
    8000595c:	c979                	beqz	a0,80005a32 <sys_unlink+0x114>
  ilock(dp);
    8000595e:	ffffe097          	auipc	ra,0xffffe
    80005962:	048080e7          	jalr	72(ra) # 800039a6 <ilock>
  if(namecmp(name, ".") == 0 || namecmp(name, "..") == 0)
    80005966:	00003597          	auipc	a1,0x3
    8000596a:	e7a58593          	addi	a1,a1,-390 # 800087e0 <syscalls+0x2c0>
    8000596e:	fb040513          	addi	a0,s0,-80
    80005972:	ffffe097          	auipc	ra,0xffffe
    80005976:	4fe080e7          	jalr	1278(ra) # 80003e70 <namecmp>
    8000597a:	14050a63          	beqz	a0,80005ace <sys_unlink+0x1b0>
    8000597e:	00003597          	auipc	a1,0x3
    80005982:	e6a58593          	addi	a1,a1,-406 # 800087e8 <syscalls+0x2c8>
    80005986:	fb040513          	addi	a0,s0,-80
    8000598a:	ffffe097          	auipc	ra,0xffffe
    8000598e:	4e6080e7          	jalr	1254(ra) # 80003e70 <namecmp>
    80005992:	12050e63          	beqz	a0,80005ace <sys_unlink+0x1b0>
  if((ip = dirlookup(dp, name, &off)) == 0)
    80005996:	f2c40613          	addi	a2,s0,-212
    8000599a:	fb040593          	addi	a1,s0,-80
    8000599e:	8526                	mv	a0,s1
    800059a0:	ffffe097          	auipc	ra,0xffffe
    800059a4:	4ea080e7          	jalr	1258(ra) # 80003e8a <dirlookup>
    800059a8:	892a                	mv	s2,a0
    800059aa:	12050263          	beqz	a0,80005ace <sys_unlink+0x1b0>
  ilock(ip);
    800059ae:	ffffe097          	auipc	ra,0xffffe
    800059b2:	ff8080e7          	jalr	-8(ra) # 800039a6 <ilock>
  if(ip->nlink < 1)
    800059b6:	04a91783          	lh	a5,74(s2)
    800059ba:	08f05263          	blez	a5,80005a3e <sys_unlink+0x120>
  if(ip->type == T_DIR && !isdirempty(ip)){
    800059be:	04491703          	lh	a4,68(s2)
    800059c2:	4785                	li	a5,1
    800059c4:	08f70563          	beq	a4,a5,80005a4e <sys_unlink+0x130>
  memset(&de, 0, sizeof(de));
    800059c8:	4641                	li	a2,16
    800059ca:	4581                	li	a1,0
    800059cc:	fc040513          	addi	a0,s0,-64
    800059d0:	ffffb097          	auipc	ra,0xffffb
    800059d4:	57a080e7          	jalr	1402(ra) # 80000f4a <memset>
  if(writei(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    800059d8:	4741                	li	a4,16
    800059da:	f2c42683          	lw	a3,-212(s0)
    800059de:	fc040613          	addi	a2,s0,-64
    800059e2:	4581                	li	a1,0
    800059e4:	8526                	mv	a0,s1
    800059e6:	ffffe097          	auipc	ra,0xffffe
    800059ea:	36c080e7          	jalr	876(ra) # 80003d52 <writei>
    800059ee:	47c1                	li	a5,16
    800059f0:	0af51563          	bne	a0,a5,80005a9a <sys_unlink+0x17c>
  if(ip->type == T_DIR){
    800059f4:	04491703          	lh	a4,68(s2)
    800059f8:	4785                	li	a5,1
    800059fa:	0af70863          	beq	a4,a5,80005aaa <sys_unlink+0x18c>
  iunlockput(dp);
    800059fe:	8526                	mv	a0,s1
    80005a00:	ffffe097          	auipc	ra,0xffffe
    80005a04:	208080e7          	jalr	520(ra) # 80003c08 <iunlockput>
  ip->nlink--;
    80005a08:	04a95783          	lhu	a5,74(s2)
    80005a0c:	37fd                	addiw	a5,a5,-1
    80005a0e:	04f91523          	sh	a5,74(s2)
  iupdate(ip);
    80005a12:	854a                	mv	a0,s2
    80005a14:	ffffe097          	auipc	ra,0xffffe
    80005a18:	ec8080e7          	jalr	-312(ra) # 800038dc <iupdate>
  iunlockput(ip);
    80005a1c:	854a                	mv	a0,s2
    80005a1e:	ffffe097          	auipc	ra,0xffffe
    80005a22:	1ea080e7          	jalr	490(ra) # 80003c08 <iunlockput>
  end_op();
    80005a26:	fffff097          	auipc	ra,0xfffff
    80005a2a:	9d2080e7          	jalr	-1582(ra) # 800043f8 <end_op>
  return 0;
    80005a2e:	4501                	li	a0,0
    80005a30:	a84d                	j	80005ae2 <sys_unlink+0x1c4>
    end_op();
    80005a32:	fffff097          	auipc	ra,0xfffff
    80005a36:	9c6080e7          	jalr	-1594(ra) # 800043f8 <end_op>
    return -1;
    80005a3a:	557d                	li	a0,-1
    80005a3c:	a05d                	j	80005ae2 <sys_unlink+0x1c4>
    panic("unlink: nlink < 1");
    80005a3e:	00003517          	auipc	a0,0x3
    80005a42:	dd250513          	addi	a0,a0,-558 # 80008810 <syscalls+0x2f0>
    80005a46:	ffffb097          	auipc	ra,0xffffb
    80005a4a:	af8080e7          	jalr	-1288(ra) # 8000053e <panic>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a4e:	04c92703          	lw	a4,76(s2)
    80005a52:	02000793          	li	a5,32
    80005a56:	f6e7f9e3          	bgeu	a5,a4,800059c8 <sys_unlink+0xaa>
    80005a5a:	02000993          	li	s3,32
    if(readi(dp, 0, (uint64)&de, off, sizeof(de)) != sizeof(de))
    80005a5e:	4741                	li	a4,16
    80005a60:	86ce                	mv	a3,s3
    80005a62:	f1840613          	addi	a2,s0,-232
    80005a66:	4581                	li	a1,0
    80005a68:	854a                	mv	a0,s2
    80005a6a:	ffffe097          	auipc	ra,0xffffe
    80005a6e:	1f0080e7          	jalr	496(ra) # 80003c5a <readi>
    80005a72:	47c1                	li	a5,16
    80005a74:	00f51b63          	bne	a0,a5,80005a8a <sys_unlink+0x16c>
    if(de.inum != 0)
    80005a78:	f1845783          	lhu	a5,-232(s0)
    80005a7c:	e7a1                	bnez	a5,80005ac4 <sys_unlink+0x1a6>
  for(off=2*sizeof(de); off<dp->size; off+=sizeof(de)){
    80005a7e:	29c1                	addiw	s3,s3,16
    80005a80:	04c92783          	lw	a5,76(s2)
    80005a84:	fcf9ede3          	bltu	s3,a5,80005a5e <sys_unlink+0x140>
    80005a88:	b781                	j	800059c8 <sys_unlink+0xaa>
      panic("isdirempty: readi");
    80005a8a:	00003517          	auipc	a0,0x3
    80005a8e:	d9e50513          	addi	a0,a0,-610 # 80008828 <syscalls+0x308>
    80005a92:	ffffb097          	auipc	ra,0xffffb
    80005a96:	aac080e7          	jalr	-1364(ra) # 8000053e <panic>
    panic("unlink: writei");
    80005a9a:	00003517          	auipc	a0,0x3
    80005a9e:	da650513          	addi	a0,a0,-602 # 80008840 <syscalls+0x320>
    80005aa2:	ffffb097          	auipc	ra,0xffffb
    80005aa6:	a9c080e7          	jalr	-1380(ra) # 8000053e <panic>
    dp->nlink--;
    80005aaa:	04a4d783          	lhu	a5,74(s1)
    80005aae:	37fd                	addiw	a5,a5,-1
    80005ab0:	04f49523          	sh	a5,74(s1)
    iupdate(dp);
    80005ab4:	8526                	mv	a0,s1
    80005ab6:	ffffe097          	auipc	ra,0xffffe
    80005aba:	e26080e7          	jalr	-474(ra) # 800038dc <iupdate>
    80005abe:	b781                	j	800059fe <sys_unlink+0xe0>
    return -1;
    80005ac0:	557d                	li	a0,-1
    80005ac2:	a005                	j	80005ae2 <sys_unlink+0x1c4>
    iunlockput(ip);
    80005ac4:	854a                	mv	a0,s2
    80005ac6:	ffffe097          	auipc	ra,0xffffe
    80005aca:	142080e7          	jalr	322(ra) # 80003c08 <iunlockput>
  iunlockput(dp);
    80005ace:	8526                	mv	a0,s1
    80005ad0:	ffffe097          	auipc	ra,0xffffe
    80005ad4:	138080e7          	jalr	312(ra) # 80003c08 <iunlockput>
  end_op();
    80005ad8:	fffff097          	auipc	ra,0xfffff
    80005adc:	920080e7          	jalr	-1760(ra) # 800043f8 <end_op>
  return -1;
    80005ae0:	557d                	li	a0,-1
}
    80005ae2:	70ae                	ld	ra,232(sp)
    80005ae4:	740e                	ld	s0,224(sp)
    80005ae6:	64ee                	ld	s1,216(sp)
    80005ae8:	694e                	ld	s2,208(sp)
    80005aea:	69ae                	ld	s3,200(sp)
    80005aec:	616d                	addi	sp,sp,240
    80005aee:	8082                	ret

0000000080005af0 <sys_open>:

uint64
sys_open(void)
{
    80005af0:	7131                	addi	sp,sp,-192
    80005af2:	fd06                	sd	ra,184(sp)
    80005af4:	f922                	sd	s0,176(sp)
    80005af6:	f526                	sd	s1,168(sp)
    80005af8:	f14a                	sd	s2,160(sp)
    80005afa:	ed4e                	sd	s3,152(sp)
    80005afc:	0180                	addi	s0,sp,192
  int fd, omode;
  struct file *f;
  struct inode *ip;
  int n;

  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005afe:	08000613          	li	a2,128
    80005b02:	f5040593          	addi	a1,s0,-176
    80005b06:	4501                	li	a0,0
    80005b08:	ffffd097          	auipc	ra,0xffffd
    80005b0c:	370080e7          	jalr	880(ra) # 80002e78 <argstr>
    return -1;
    80005b10:	54fd                	li	s1,-1
  if((n = argstr(0, path, MAXPATH)) < 0 || argint(1, &omode) < 0)
    80005b12:	0c054163          	bltz	a0,80005bd4 <sys_open+0xe4>
    80005b16:	f4c40593          	addi	a1,s0,-180
    80005b1a:	4505                	li	a0,1
    80005b1c:	ffffd097          	auipc	ra,0xffffd
    80005b20:	318080e7          	jalr	792(ra) # 80002e34 <argint>
    80005b24:	0a054863          	bltz	a0,80005bd4 <sys_open+0xe4>

  begin_op();
    80005b28:	fffff097          	auipc	ra,0xfffff
    80005b2c:	850080e7          	jalr	-1968(ra) # 80004378 <begin_op>

  if(omode & O_CREATE){
    80005b30:	f4c42783          	lw	a5,-180(s0)
    80005b34:	2007f793          	andi	a5,a5,512
    80005b38:	cbdd                	beqz	a5,80005bee <sys_open+0xfe>
    ip = create(path, T_FILE, 0, 0);
    80005b3a:	4681                	li	a3,0
    80005b3c:	4601                	li	a2,0
    80005b3e:	4589                	li	a1,2
    80005b40:	f5040513          	addi	a0,s0,-176
    80005b44:	00000097          	auipc	ra,0x0
    80005b48:	972080e7          	jalr	-1678(ra) # 800054b6 <create>
    80005b4c:	892a                	mv	s2,a0
    if(ip == 0){
    80005b4e:	c959                	beqz	a0,80005be4 <sys_open+0xf4>
      end_op();
      return -1;
    }
  }

  if(ip->type == T_DEVICE && (ip->major < 0 || ip->major >= NDEV)){
    80005b50:	04491703          	lh	a4,68(s2)
    80005b54:	478d                	li	a5,3
    80005b56:	00f71763          	bne	a4,a5,80005b64 <sys_open+0x74>
    80005b5a:	04695703          	lhu	a4,70(s2)
    80005b5e:	47a5                	li	a5,9
    80005b60:	0ce7ec63          	bltu	a5,a4,80005c38 <sys_open+0x148>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if((f = filealloc()) == 0 || (fd = fdalloc(f)) < 0){
    80005b64:	fffff097          	auipc	ra,0xfffff
    80005b68:	c24080e7          	jalr	-988(ra) # 80004788 <filealloc>
    80005b6c:	89aa                	mv	s3,a0
    80005b6e:	10050263          	beqz	a0,80005c72 <sys_open+0x182>
    80005b72:	00000097          	auipc	ra,0x0
    80005b76:	902080e7          	jalr	-1790(ra) # 80005474 <fdalloc>
    80005b7a:	84aa                	mv	s1,a0
    80005b7c:	0e054663          	bltz	a0,80005c68 <sys_open+0x178>
    iunlockput(ip);
    end_op();
    return -1;
  }

  if(ip->type == T_DEVICE){
    80005b80:	04491703          	lh	a4,68(s2)
    80005b84:	478d                	li	a5,3
    80005b86:	0cf70463          	beq	a4,a5,80005c4e <sys_open+0x15e>
    f->type = FD_DEVICE;
    f->major = ip->major;
  } else {
    f->type = FD_INODE;
    80005b8a:	4789                	li	a5,2
    80005b8c:	00f9a023          	sw	a5,0(s3)
    f->off = 0;
    80005b90:	0209a023          	sw	zero,32(s3)
  }
  f->ip = ip;
    80005b94:	0129bc23          	sd	s2,24(s3)
  f->readable = !(omode & O_WRONLY);
    80005b98:	f4c42783          	lw	a5,-180(s0)
    80005b9c:	0017c713          	xori	a4,a5,1
    80005ba0:	8b05                	andi	a4,a4,1
    80005ba2:	00e98423          	sb	a4,8(s3)
  f->writable = (omode & O_WRONLY) || (omode & O_RDWR);
    80005ba6:	0037f713          	andi	a4,a5,3
    80005baa:	00e03733          	snez	a4,a4
    80005bae:	00e984a3          	sb	a4,9(s3)

  if((omode & O_TRUNC) && ip->type == T_FILE){
    80005bb2:	4007f793          	andi	a5,a5,1024
    80005bb6:	c791                	beqz	a5,80005bc2 <sys_open+0xd2>
    80005bb8:	04491703          	lh	a4,68(s2)
    80005bbc:	4789                	li	a5,2
    80005bbe:	08f70f63          	beq	a4,a5,80005c5c <sys_open+0x16c>
    itrunc(ip);
  }

  iunlock(ip);
    80005bc2:	854a                	mv	a0,s2
    80005bc4:	ffffe097          	auipc	ra,0xffffe
    80005bc8:	ea4080e7          	jalr	-348(ra) # 80003a68 <iunlock>
  end_op();
    80005bcc:	fffff097          	auipc	ra,0xfffff
    80005bd0:	82c080e7          	jalr	-2004(ra) # 800043f8 <end_op>

  return fd;
}
    80005bd4:	8526                	mv	a0,s1
    80005bd6:	70ea                	ld	ra,184(sp)
    80005bd8:	744a                	ld	s0,176(sp)
    80005bda:	74aa                	ld	s1,168(sp)
    80005bdc:	790a                	ld	s2,160(sp)
    80005bde:	69ea                	ld	s3,152(sp)
    80005be0:	6129                	addi	sp,sp,192
    80005be2:	8082                	ret
      end_op();
    80005be4:	fffff097          	auipc	ra,0xfffff
    80005be8:	814080e7          	jalr	-2028(ra) # 800043f8 <end_op>
      return -1;
    80005bec:	b7e5                	j	80005bd4 <sys_open+0xe4>
    if((ip = namei(path)) == 0){
    80005bee:	f5040513          	addi	a0,s0,-176
    80005bf2:	ffffe097          	auipc	ra,0xffffe
    80005bf6:	56a080e7          	jalr	1386(ra) # 8000415c <namei>
    80005bfa:	892a                	mv	s2,a0
    80005bfc:	c905                	beqz	a0,80005c2c <sys_open+0x13c>
    ilock(ip);
    80005bfe:	ffffe097          	auipc	ra,0xffffe
    80005c02:	da8080e7          	jalr	-600(ra) # 800039a6 <ilock>
    if(ip->type == T_DIR && omode != O_RDONLY){
    80005c06:	04491703          	lh	a4,68(s2)
    80005c0a:	4785                	li	a5,1
    80005c0c:	f4f712e3          	bne	a4,a5,80005b50 <sys_open+0x60>
    80005c10:	f4c42783          	lw	a5,-180(s0)
    80005c14:	dba1                	beqz	a5,80005b64 <sys_open+0x74>
      iunlockput(ip);
    80005c16:	854a                	mv	a0,s2
    80005c18:	ffffe097          	auipc	ra,0xffffe
    80005c1c:	ff0080e7          	jalr	-16(ra) # 80003c08 <iunlockput>
      end_op();
    80005c20:	ffffe097          	auipc	ra,0xffffe
    80005c24:	7d8080e7          	jalr	2008(ra) # 800043f8 <end_op>
      return -1;
    80005c28:	54fd                	li	s1,-1
    80005c2a:	b76d                	j	80005bd4 <sys_open+0xe4>
      end_op();
    80005c2c:	ffffe097          	auipc	ra,0xffffe
    80005c30:	7cc080e7          	jalr	1996(ra) # 800043f8 <end_op>
      return -1;
    80005c34:	54fd                	li	s1,-1
    80005c36:	bf79                	j	80005bd4 <sys_open+0xe4>
    iunlockput(ip);
    80005c38:	854a                	mv	a0,s2
    80005c3a:	ffffe097          	auipc	ra,0xffffe
    80005c3e:	fce080e7          	jalr	-50(ra) # 80003c08 <iunlockput>
    end_op();
    80005c42:	ffffe097          	auipc	ra,0xffffe
    80005c46:	7b6080e7          	jalr	1974(ra) # 800043f8 <end_op>
    return -1;
    80005c4a:	54fd                	li	s1,-1
    80005c4c:	b761                	j	80005bd4 <sys_open+0xe4>
    f->type = FD_DEVICE;
    80005c4e:	00f9a023          	sw	a5,0(s3)
    f->major = ip->major;
    80005c52:	04691783          	lh	a5,70(s2)
    80005c56:	02f99223          	sh	a5,36(s3)
    80005c5a:	bf2d                	j	80005b94 <sys_open+0xa4>
    itrunc(ip);
    80005c5c:	854a                	mv	a0,s2
    80005c5e:	ffffe097          	auipc	ra,0xffffe
    80005c62:	e56080e7          	jalr	-426(ra) # 80003ab4 <itrunc>
    80005c66:	bfb1                	j	80005bc2 <sys_open+0xd2>
      fileclose(f);
    80005c68:	854e                	mv	a0,s3
    80005c6a:	fffff097          	auipc	ra,0xfffff
    80005c6e:	bda080e7          	jalr	-1062(ra) # 80004844 <fileclose>
    iunlockput(ip);
    80005c72:	854a                	mv	a0,s2
    80005c74:	ffffe097          	auipc	ra,0xffffe
    80005c78:	f94080e7          	jalr	-108(ra) # 80003c08 <iunlockput>
    end_op();
    80005c7c:	ffffe097          	auipc	ra,0xffffe
    80005c80:	77c080e7          	jalr	1916(ra) # 800043f8 <end_op>
    return -1;
    80005c84:	54fd                	li	s1,-1
    80005c86:	b7b9                	j	80005bd4 <sys_open+0xe4>

0000000080005c88 <sys_mkdir>:

uint64
sys_mkdir(void)
{
    80005c88:	7175                	addi	sp,sp,-144
    80005c8a:	e506                	sd	ra,136(sp)
    80005c8c:	e122                	sd	s0,128(sp)
    80005c8e:	0900                	addi	s0,sp,144
  char path[MAXPATH];
  struct inode *ip;

  begin_op();
    80005c90:	ffffe097          	auipc	ra,0xffffe
    80005c94:	6e8080e7          	jalr	1768(ra) # 80004378 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = create(path, T_DIR, 0, 0)) == 0){
    80005c98:	08000613          	li	a2,128
    80005c9c:	f7040593          	addi	a1,s0,-144
    80005ca0:	4501                	li	a0,0
    80005ca2:	ffffd097          	auipc	ra,0xffffd
    80005ca6:	1d6080e7          	jalr	470(ra) # 80002e78 <argstr>
    80005caa:	02054963          	bltz	a0,80005cdc <sys_mkdir+0x54>
    80005cae:	4681                	li	a3,0
    80005cb0:	4601                	li	a2,0
    80005cb2:	4585                	li	a1,1
    80005cb4:	f7040513          	addi	a0,s0,-144
    80005cb8:	fffff097          	auipc	ra,0xfffff
    80005cbc:	7fe080e7          	jalr	2046(ra) # 800054b6 <create>
    80005cc0:	cd11                	beqz	a0,80005cdc <sys_mkdir+0x54>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005cc2:	ffffe097          	auipc	ra,0xffffe
    80005cc6:	f46080e7          	jalr	-186(ra) # 80003c08 <iunlockput>
  end_op();
    80005cca:	ffffe097          	auipc	ra,0xffffe
    80005cce:	72e080e7          	jalr	1838(ra) # 800043f8 <end_op>
  return 0;
    80005cd2:	4501                	li	a0,0
}
    80005cd4:	60aa                	ld	ra,136(sp)
    80005cd6:	640a                	ld	s0,128(sp)
    80005cd8:	6149                	addi	sp,sp,144
    80005cda:	8082                	ret
    end_op();
    80005cdc:	ffffe097          	auipc	ra,0xffffe
    80005ce0:	71c080e7          	jalr	1820(ra) # 800043f8 <end_op>
    return -1;
    80005ce4:	557d                	li	a0,-1
    80005ce6:	b7fd                	j	80005cd4 <sys_mkdir+0x4c>

0000000080005ce8 <sys_mknod>:

uint64
sys_mknod(void)
{
    80005ce8:	7135                	addi	sp,sp,-160
    80005cea:	ed06                	sd	ra,152(sp)
    80005cec:	e922                	sd	s0,144(sp)
    80005cee:	1100                	addi	s0,sp,160
  struct inode *ip;
  char path[MAXPATH];
  int major, minor;

  begin_op();
    80005cf0:	ffffe097          	auipc	ra,0xffffe
    80005cf4:	688080e7          	jalr	1672(ra) # 80004378 <begin_op>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005cf8:	08000613          	li	a2,128
    80005cfc:	f7040593          	addi	a1,s0,-144
    80005d00:	4501                	li	a0,0
    80005d02:	ffffd097          	auipc	ra,0xffffd
    80005d06:	176080e7          	jalr	374(ra) # 80002e78 <argstr>
    80005d0a:	04054a63          	bltz	a0,80005d5e <sys_mknod+0x76>
     argint(1, &major) < 0 ||
    80005d0e:	f6c40593          	addi	a1,s0,-148
    80005d12:	4505                	li	a0,1
    80005d14:	ffffd097          	auipc	ra,0xffffd
    80005d18:	120080e7          	jalr	288(ra) # 80002e34 <argint>
  if((argstr(0, path, MAXPATH)) < 0 ||
    80005d1c:	04054163          	bltz	a0,80005d5e <sys_mknod+0x76>
     argint(2, &minor) < 0 ||
    80005d20:	f6840593          	addi	a1,s0,-152
    80005d24:	4509                	li	a0,2
    80005d26:	ffffd097          	auipc	ra,0xffffd
    80005d2a:	10e080e7          	jalr	270(ra) # 80002e34 <argint>
     argint(1, &major) < 0 ||
    80005d2e:	02054863          	bltz	a0,80005d5e <sys_mknod+0x76>
     (ip = create(path, T_DEVICE, major, minor)) == 0){
    80005d32:	f6841683          	lh	a3,-152(s0)
    80005d36:	f6c41603          	lh	a2,-148(s0)
    80005d3a:	458d                	li	a1,3
    80005d3c:	f7040513          	addi	a0,s0,-144
    80005d40:	fffff097          	auipc	ra,0xfffff
    80005d44:	776080e7          	jalr	1910(ra) # 800054b6 <create>
     argint(2, &minor) < 0 ||
    80005d48:	c919                	beqz	a0,80005d5e <sys_mknod+0x76>
    end_op();
    return -1;
  }
  iunlockput(ip);
    80005d4a:	ffffe097          	auipc	ra,0xffffe
    80005d4e:	ebe080e7          	jalr	-322(ra) # 80003c08 <iunlockput>
  end_op();
    80005d52:	ffffe097          	auipc	ra,0xffffe
    80005d56:	6a6080e7          	jalr	1702(ra) # 800043f8 <end_op>
  return 0;
    80005d5a:	4501                	li	a0,0
    80005d5c:	a031                	j	80005d68 <sys_mknod+0x80>
    end_op();
    80005d5e:	ffffe097          	auipc	ra,0xffffe
    80005d62:	69a080e7          	jalr	1690(ra) # 800043f8 <end_op>
    return -1;
    80005d66:	557d                	li	a0,-1
}
    80005d68:	60ea                	ld	ra,152(sp)
    80005d6a:	644a                	ld	s0,144(sp)
    80005d6c:	610d                	addi	sp,sp,160
    80005d6e:	8082                	ret

0000000080005d70 <sys_chdir>:

uint64
sys_chdir(void)
{
    80005d70:	7135                	addi	sp,sp,-160
    80005d72:	ed06                	sd	ra,152(sp)
    80005d74:	e922                	sd	s0,144(sp)
    80005d76:	e526                	sd	s1,136(sp)
    80005d78:	e14a                	sd	s2,128(sp)
    80005d7a:	1100                	addi	s0,sp,160
  char path[MAXPATH];
  struct inode *ip;
  struct proc *p = myproc();
    80005d7c:	ffffc097          	auipc	ra,0xffffc
    80005d80:	e9e080e7          	jalr	-354(ra) # 80001c1a <myproc>
    80005d84:	892a                	mv	s2,a0
  
  begin_op();
    80005d86:	ffffe097          	auipc	ra,0xffffe
    80005d8a:	5f2080e7          	jalr	1522(ra) # 80004378 <begin_op>
  if(argstr(0, path, MAXPATH) < 0 || (ip = namei(path)) == 0){
    80005d8e:	08000613          	li	a2,128
    80005d92:	f6040593          	addi	a1,s0,-160
    80005d96:	4501                	li	a0,0
    80005d98:	ffffd097          	auipc	ra,0xffffd
    80005d9c:	0e0080e7          	jalr	224(ra) # 80002e78 <argstr>
    80005da0:	04054b63          	bltz	a0,80005df6 <sys_chdir+0x86>
    80005da4:	f6040513          	addi	a0,s0,-160
    80005da8:	ffffe097          	auipc	ra,0xffffe
    80005dac:	3b4080e7          	jalr	948(ra) # 8000415c <namei>
    80005db0:	84aa                	mv	s1,a0
    80005db2:	c131                	beqz	a0,80005df6 <sys_chdir+0x86>
    end_op();
    return -1;
  }
  ilock(ip);
    80005db4:	ffffe097          	auipc	ra,0xffffe
    80005db8:	bf2080e7          	jalr	-1038(ra) # 800039a6 <ilock>
  if(ip->type != T_DIR){
    80005dbc:	04449703          	lh	a4,68(s1)
    80005dc0:	4785                	li	a5,1
    80005dc2:	04f71063          	bne	a4,a5,80005e02 <sys_chdir+0x92>
    iunlockput(ip);
    end_op();
    return -1;
  }
  iunlock(ip);
    80005dc6:	8526                	mv	a0,s1
    80005dc8:	ffffe097          	auipc	ra,0xffffe
    80005dcc:	ca0080e7          	jalr	-864(ra) # 80003a68 <iunlock>
  iput(p->cwd);
    80005dd0:	15093503          	ld	a0,336(s2)
    80005dd4:	ffffe097          	auipc	ra,0xffffe
    80005dd8:	d8c080e7          	jalr	-628(ra) # 80003b60 <iput>
  end_op();
    80005ddc:	ffffe097          	auipc	ra,0xffffe
    80005de0:	61c080e7          	jalr	1564(ra) # 800043f8 <end_op>
  p->cwd = ip;
    80005de4:	14993823          	sd	s1,336(s2)
  return 0;
    80005de8:	4501                	li	a0,0
}
    80005dea:	60ea                	ld	ra,152(sp)
    80005dec:	644a                	ld	s0,144(sp)
    80005dee:	64aa                	ld	s1,136(sp)
    80005df0:	690a                	ld	s2,128(sp)
    80005df2:	610d                	addi	sp,sp,160
    80005df4:	8082                	ret
    end_op();
    80005df6:	ffffe097          	auipc	ra,0xffffe
    80005dfa:	602080e7          	jalr	1538(ra) # 800043f8 <end_op>
    return -1;
    80005dfe:	557d                	li	a0,-1
    80005e00:	b7ed                	j	80005dea <sys_chdir+0x7a>
    iunlockput(ip);
    80005e02:	8526                	mv	a0,s1
    80005e04:	ffffe097          	auipc	ra,0xffffe
    80005e08:	e04080e7          	jalr	-508(ra) # 80003c08 <iunlockput>
    end_op();
    80005e0c:	ffffe097          	auipc	ra,0xffffe
    80005e10:	5ec080e7          	jalr	1516(ra) # 800043f8 <end_op>
    return -1;
    80005e14:	557d                	li	a0,-1
    80005e16:	bfd1                	j	80005dea <sys_chdir+0x7a>

0000000080005e18 <sys_exec>:

uint64
sys_exec(void)
{
    80005e18:	7145                	addi	sp,sp,-464
    80005e1a:	e786                	sd	ra,456(sp)
    80005e1c:	e3a2                	sd	s0,448(sp)
    80005e1e:	ff26                	sd	s1,440(sp)
    80005e20:	fb4a                	sd	s2,432(sp)
    80005e22:	f74e                	sd	s3,424(sp)
    80005e24:	f352                	sd	s4,416(sp)
    80005e26:	ef56                	sd	s5,408(sp)
    80005e28:	0b80                	addi	s0,sp,464
  char path[MAXPATH], *argv[MAXARG];
  int i;
  uint64 uargv, uarg;

  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005e2a:	08000613          	li	a2,128
    80005e2e:	f4040593          	addi	a1,s0,-192
    80005e32:	4501                	li	a0,0
    80005e34:	ffffd097          	auipc	ra,0xffffd
    80005e38:	044080e7          	jalr	68(ra) # 80002e78 <argstr>
    return -1;
    80005e3c:	597d                	li	s2,-1
  if(argstr(0, path, MAXPATH) < 0 || argaddr(1, &uargv) < 0){
    80005e3e:	0c054a63          	bltz	a0,80005f12 <sys_exec+0xfa>
    80005e42:	e3840593          	addi	a1,s0,-456
    80005e46:	4505                	li	a0,1
    80005e48:	ffffd097          	auipc	ra,0xffffd
    80005e4c:	00e080e7          	jalr	14(ra) # 80002e56 <argaddr>
    80005e50:	0c054163          	bltz	a0,80005f12 <sys_exec+0xfa>
  }
  memset(argv, 0, sizeof(argv));
    80005e54:	10000613          	li	a2,256
    80005e58:	4581                	li	a1,0
    80005e5a:	e4040513          	addi	a0,s0,-448
    80005e5e:	ffffb097          	auipc	ra,0xffffb
    80005e62:	0ec080e7          	jalr	236(ra) # 80000f4a <memset>
  for(i=0;; i++){
    if(i >= NELEM(argv)){
    80005e66:	e4040493          	addi	s1,s0,-448
  memset(argv, 0, sizeof(argv));
    80005e6a:	89a6                	mv	s3,s1
    80005e6c:	4901                	li	s2,0
    if(i >= NELEM(argv)){
    80005e6e:	02000a13          	li	s4,32
    80005e72:	00090a9b          	sext.w	s5,s2
      goto bad;
    }
    if(fetchaddr(uargv+sizeof(uint64)*i, (uint64*)&uarg) < 0){
    80005e76:	00391513          	slli	a0,s2,0x3
    80005e7a:	e3040593          	addi	a1,s0,-464
    80005e7e:	e3843783          	ld	a5,-456(s0)
    80005e82:	953e                	add	a0,a0,a5
    80005e84:	ffffd097          	auipc	ra,0xffffd
    80005e88:	f16080e7          	jalr	-234(ra) # 80002d9a <fetchaddr>
    80005e8c:	02054a63          	bltz	a0,80005ec0 <sys_exec+0xa8>
      goto bad;
    }
    if(uarg == 0){
    80005e90:	e3043783          	ld	a5,-464(s0)
    80005e94:	c3b9                	beqz	a5,80005eda <sys_exec+0xc2>
      argv[i] = 0;
      break;
    }
    argv[i] = kalloc();
    80005e96:	ffffb097          	auipc	ra,0xffffb
    80005e9a:	d7a080e7          	jalr	-646(ra) # 80000c10 <kalloc>
    80005e9e:	85aa                	mv	a1,a0
    80005ea0:	00a9b023          	sd	a0,0(s3)
    if(argv[i] == 0)
    80005ea4:	cd11                	beqz	a0,80005ec0 <sys_exec+0xa8>
      goto bad;
    if(fetchstr(uarg, argv[i], PGSIZE) < 0)
    80005ea6:	6605                	lui	a2,0x1
    80005ea8:	e3043503          	ld	a0,-464(s0)
    80005eac:	ffffd097          	auipc	ra,0xffffd
    80005eb0:	f40080e7          	jalr	-192(ra) # 80002dec <fetchstr>
    80005eb4:	00054663          	bltz	a0,80005ec0 <sys_exec+0xa8>
    if(i >= NELEM(argv)){
    80005eb8:	0905                	addi	s2,s2,1
    80005eba:	09a1                	addi	s3,s3,8
    80005ebc:	fb491be3          	bne	s2,s4,80005e72 <sys_exec+0x5a>
    kfree(argv[i]);

  return ret;

 bad:
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ec0:	10048913          	addi	s2,s1,256
    80005ec4:	6088                	ld	a0,0(s1)
    80005ec6:	c529                	beqz	a0,80005f10 <sys_exec+0xf8>
    kfree(argv[i]);
    80005ec8:	ffffb097          	auipc	ra,0xffffb
    80005ecc:	c30080e7          	jalr	-976(ra) # 80000af8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ed0:	04a1                	addi	s1,s1,8
    80005ed2:	ff2499e3          	bne	s1,s2,80005ec4 <sys_exec+0xac>
  return -1;
    80005ed6:	597d                	li	s2,-1
    80005ed8:	a82d                	j	80005f12 <sys_exec+0xfa>
      argv[i] = 0;
    80005eda:	0a8e                	slli	s5,s5,0x3
    80005edc:	fc040793          	addi	a5,s0,-64
    80005ee0:	9abe                	add	s5,s5,a5
    80005ee2:	e80ab023          	sd	zero,-384(s5)
  int ret = exec(path, argv);
    80005ee6:	e4040593          	addi	a1,s0,-448
    80005eea:	f4040513          	addi	a0,s0,-192
    80005eee:	fffff097          	auipc	ra,0xfffff
    80005ef2:	194080e7          	jalr	404(ra) # 80005082 <exec>
    80005ef6:	892a                	mv	s2,a0
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005ef8:	10048993          	addi	s3,s1,256
    80005efc:	6088                	ld	a0,0(s1)
    80005efe:	c911                	beqz	a0,80005f12 <sys_exec+0xfa>
    kfree(argv[i]);
    80005f00:	ffffb097          	auipc	ra,0xffffb
    80005f04:	bf8080e7          	jalr	-1032(ra) # 80000af8 <kfree>
  for(i = 0; i < NELEM(argv) && argv[i] != 0; i++)
    80005f08:	04a1                	addi	s1,s1,8
    80005f0a:	ff3499e3          	bne	s1,s3,80005efc <sys_exec+0xe4>
    80005f0e:	a011                	j	80005f12 <sys_exec+0xfa>
  return -1;
    80005f10:	597d                	li	s2,-1
}
    80005f12:	854a                	mv	a0,s2
    80005f14:	60be                	ld	ra,456(sp)
    80005f16:	641e                	ld	s0,448(sp)
    80005f18:	74fa                	ld	s1,440(sp)
    80005f1a:	795a                	ld	s2,432(sp)
    80005f1c:	79ba                	ld	s3,424(sp)
    80005f1e:	7a1a                	ld	s4,416(sp)
    80005f20:	6afa                	ld	s5,408(sp)
    80005f22:	6179                	addi	sp,sp,464
    80005f24:	8082                	ret

0000000080005f26 <sys_pipe>:

uint64
sys_pipe(void)
{
    80005f26:	7139                	addi	sp,sp,-64
    80005f28:	fc06                	sd	ra,56(sp)
    80005f2a:	f822                	sd	s0,48(sp)
    80005f2c:	f426                	sd	s1,40(sp)
    80005f2e:	0080                	addi	s0,sp,64
  uint64 fdarray; // user pointer to array of two integers
  struct file *rf, *wf;
  int fd0, fd1;
  struct proc *p = myproc();
    80005f30:	ffffc097          	auipc	ra,0xffffc
    80005f34:	cea080e7          	jalr	-790(ra) # 80001c1a <myproc>
    80005f38:	84aa                	mv	s1,a0

  if(argaddr(0, &fdarray) < 0)
    80005f3a:	fd840593          	addi	a1,s0,-40
    80005f3e:	4501                	li	a0,0
    80005f40:	ffffd097          	auipc	ra,0xffffd
    80005f44:	f16080e7          	jalr	-234(ra) # 80002e56 <argaddr>
    return -1;
    80005f48:	57fd                	li	a5,-1
  if(argaddr(0, &fdarray) < 0)
    80005f4a:	0e054063          	bltz	a0,8000602a <sys_pipe+0x104>
  if(pipealloc(&rf, &wf) < 0)
    80005f4e:	fc840593          	addi	a1,s0,-56
    80005f52:	fd040513          	addi	a0,s0,-48
    80005f56:	fffff097          	auipc	ra,0xfffff
    80005f5a:	dfc080e7          	jalr	-516(ra) # 80004d52 <pipealloc>
    return -1;
    80005f5e:	57fd                	li	a5,-1
  if(pipealloc(&rf, &wf) < 0)
    80005f60:	0c054563          	bltz	a0,8000602a <sys_pipe+0x104>
  fd0 = -1;
    80005f64:	fcf42223          	sw	a5,-60(s0)
  if((fd0 = fdalloc(rf)) < 0 || (fd1 = fdalloc(wf)) < 0){
    80005f68:	fd043503          	ld	a0,-48(s0)
    80005f6c:	fffff097          	auipc	ra,0xfffff
    80005f70:	508080e7          	jalr	1288(ra) # 80005474 <fdalloc>
    80005f74:	fca42223          	sw	a0,-60(s0)
    80005f78:	08054c63          	bltz	a0,80006010 <sys_pipe+0xea>
    80005f7c:	fc843503          	ld	a0,-56(s0)
    80005f80:	fffff097          	auipc	ra,0xfffff
    80005f84:	4f4080e7          	jalr	1268(ra) # 80005474 <fdalloc>
    80005f88:	fca42023          	sw	a0,-64(s0)
    80005f8c:	06054863          	bltz	a0,80005ffc <sys_pipe+0xd6>
      p->ofile[fd0] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005f90:	4691                	li	a3,4
    80005f92:	fc440613          	addi	a2,s0,-60
    80005f96:	fd843583          	ld	a1,-40(s0)
    80005f9a:	68a8                	ld	a0,80(s1)
    80005f9c:	ffffc097          	auipc	ra,0xffffc
    80005fa0:	940080e7          	jalr	-1728(ra) # 800018dc <copyout>
    80005fa4:	02054063          	bltz	a0,80005fc4 <sys_pipe+0x9e>
     copyout(p->pagetable, fdarray+sizeof(fd0), (char *)&fd1, sizeof(fd1)) < 0){
    80005fa8:	4691                	li	a3,4
    80005faa:	fc040613          	addi	a2,s0,-64
    80005fae:	fd843583          	ld	a1,-40(s0)
    80005fb2:	0591                	addi	a1,a1,4
    80005fb4:	68a8                	ld	a0,80(s1)
    80005fb6:	ffffc097          	auipc	ra,0xffffc
    80005fba:	926080e7          	jalr	-1754(ra) # 800018dc <copyout>
    p->ofile[fd1] = 0;
    fileclose(rf);
    fileclose(wf);
    return -1;
  }
  return 0;
    80005fbe:	4781                	li	a5,0
  if(copyout(p->pagetable, fdarray, (char*)&fd0, sizeof(fd0)) < 0 ||
    80005fc0:	06055563          	bgez	a0,8000602a <sys_pipe+0x104>
    p->ofile[fd0] = 0;
    80005fc4:	fc442783          	lw	a5,-60(s0)
    80005fc8:	07e9                	addi	a5,a5,26
    80005fca:	078e                	slli	a5,a5,0x3
    80005fcc:	97a6                	add	a5,a5,s1
    80005fce:	0007b023          	sd	zero,0(a5)
    p->ofile[fd1] = 0;
    80005fd2:	fc042503          	lw	a0,-64(s0)
    80005fd6:	0569                	addi	a0,a0,26
    80005fd8:	050e                	slli	a0,a0,0x3
    80005fda:	9526                	add	a0,a0,s1
    80005fdc:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80005fe0:	fd043503          	ld	a0,-48(s0)
    80005fe4:	fffff097          	auipc	ra,0xfffff
    80005fe8:	860080e7          	jalr	-1952(ra) # 80004844 <fileclose>
    fileclose(wf);
    80005fec:	fc843503          	ld	a0,-56(s0)
    80005ff0:	fffff097          	auipc	ra,0xfffff
    80005ff4:	854080e7          	jalr	-1964(ra) # 80004844 <fileclose>
    return -1;
    80005ff8:	57fd                	li	a5,-1
    80005ffa:	a805                	j	8000602a <sys_pipe+0x104>
    if(fd0 >= 0)
    80005ffc:	fc442783          	lw	a5,-60(s0)
    80006000:	0007c863          	bltz	a5,80006010 <sys_pipe+0xea>
      p->ofile[fd0] = 0;
    80006004:	01a78513          	addi	a0,a5,26
    80006008:	050e                	slli	a0,a0,0x3
    8000600a:	9526                	add	a0,a0,s1
    8000600c:	00053023          	sd	zero,0(a0)
    fileclose(rf);
    80006010:	fd043503          	ld	a0,-48(s0)
    80006014:	fffff097          	auipc	ra,0xfffff
    80006018:	830080e7          	jalr	-2000(ra) # 80004844 <fileclose>
    fileclose(wf);
    8000601c:	fc843503          	ld	a0,-56(s0)
    80006020:	fffff097          	auipc	ra,0xfffff
    80006024:	824080e7          	jalr	-2012(ra) # 80004844 <fileclose>
    return -1;
    80006028:	57fd                	li	a5,-1
}
    8000602a:	853e                	mv	a0,a5
    8000602c:	70e2                	ld	ra,56(sp)
    8000602e:	7442                	ld	s0,48(sp)
    80006030:	74a2                	ld	s1,40(sp)
    80006032:	6121                	addi	sp,sp,64
    80006034:	8082                	ret

0000000080006036 <sys_mmap>:

//We assume the kernel decides where the file is mapped and the offset is 0
uint64
sys_mmap(void)
{
    80006036:	7179                	addi	sp,sp,-48
    80006038:	f406                	sd	ra,40(sp)
    8000603a:	f022                	sd	s0,32(sp)
    8000603c:	1800                	addi	s0,sp,48
  uint64 length, prot, flag, fd;

  if(argaddr(1, &length) < 0) 
    8000603e:	fe840593          	addi	a1,s0,-24
    80006042:	4505                	li	a0,1
    80006044:	ffffd097          	auipc	ra,0xffffd
    80006048:	e12080e7          	jalr	-494(ra) # 80002e56 <argaddr>
    return -1;
    8000604c:	57fd                	li	a5,-1
  if(argaddr(1, &length) < 0) 
    8000604e:	04054e63          	bltz	a0,800060aa <sys_mmap+0x74>
  if(argaddr(2, &prot) < 0)
    80006052:	fe040593          	addi	a1,s0,-32
    80006056:	4509                	li	a0,2
    80006058:	ffffd097          	auipc	ra,0xffffd
    8000605c:	dfe080e7          	jalr	-514(ra) # 80002e56 <argaddr>
    return -1;
    80006060:	57fd                	li	a5,-1
  if(argaddr(2, &prot) < 0)
    80006062:	04054463          	bltz	a0,800060aa <sys_mmap+0x74>
  if(argaddr(3, &flag) < 0)
    80006066:	fd840593          	addi	a1,s0,-40
    8000606a:	450d                	li	a0,3
    8000606c:	ffffd097          	auipc	ra,0xffffd
    80006070:	dea080e7          	jalr	-534(ra) # 80002e56 <argaddr>
    return -1;
    80006074:	57fd                	li	a5,-1
  if(argaddr(3, &flag) < 0)
    80006076:	02054a63          	bltz	a0,800060aa <sys_mmap+0x74>
  if(argaddr(4, &fd) < 0)
    8000607a:	fd040593          	addi	a1,s0,-48
    8000607e:	4511                	li	a0,4
    80006080:	ffffd097          	auipc	ra,0xffffd
    80006084:	dd6080e7          	jalr	-554(ra) # 80002e56 <argaddr>
    80006088:	06054863          	bltz	a0,800060f8 <sys_mmap+0xc2>
    return -1;

  if(length < 1)  //Map at least 1 byte
    8000608c:	fe843703          	ld	a4,-24(s0)
    return -1;
    80006090:	57fd                	li	a5,-1
  if(length < 1)  //Map at least 1 byte
    80006092:	cf01                	beqz	a4,800060aa <sys_mmap+0x74>
  if(prot != PROT_READ && prot != PROT_WRITE && prot != PROT_READ_WRITE)
    80006094:	fe043703          	ld	a4,-32(s0)
    80006098:	ffb77693          	andi	a3,a4,-5
    8000609c:	4789                	li	a5,2
    8000609e:	00f68b63          	beq	a3,a5,800060b4 <sys_mmap+0x7e>
    800060a2:	4691                	li	a3,4
    return -1;
    800060a4:	57fd                	li	a5,-1
  if(prot != PROT_READ && prot != PROT_WRITE && prot != PROT_READ_WRITE)
    800060a6:	00d70763          	beq	a4,a3,800060b4 <sys_mmap+0x7e>
  if(fd < 0 || fd >= NOFILE)
    return -1;

  printf("Continua\n");
  return mmap(length, prot, flag, fd);
}
    800060aa:	853e                	mv	a0,a5
    800060ac:	70a2                	ld	ra,40(sp)
    800060ae:	7402                	ld	s0,32(sp)
    800060b0:	6145                	addi	sp,sp,48
    800060b2:	8082                	ret
  if(flag != MAP_PRIVATE && flag != MAP_SHARED)
    800060b4:	fd843703          	ld	a4,-40(s0)
    800060b8:	177d                	addi	a4,a4,-1
    800060ba:	4685                	li	a3,1
    return -1;
    800060bc:	57fd                	li	a5,-1
  if(flag != MAP_PRIVATE && flag != MAP_SHARED)
    800060be:	fee6e6e3          	bltu	a3,a4,800060aa <sys_mmap+0x74>
  if(fd < 0 || fd >= NOFILE)
    800060c2:	fd043683          	ld	a3,-48(s0)
    800060c6:	473d                	li	a4,15
    800060c8:	fed761e3          	bltu	a4,a3,800060aa <sys_mmap+0x74>
  printf("Continua\n");
    800060cc:	00002517          	auipc	a0,0x2
    800060d0:	78450513          	addi	a0,a0,1924 # 80008850 <syscalls+0x330>
    800060d4:	ffffa097          	auipc	ra,0xffffa
    800060d8:	4b4080e7          	jalr	1204(ra) # 80000588 <printf>
  return mmap(length, prot, flag, fd);
    800060dc:	fd042683          	lw	a3,-48(s0)
    800060e0:	fd842603          	lw	a2,-40(s0)
    800060e4:	fe042583          	lw	a1,-32(s0)
    800060e8:	fe843503          	ld	a0,-24(s0)
    800060ec:	fffff097          	auipc	ra,0xfffff
    800060f0:	a88080e7          	jalr	-1400(ra) # 80004b74 <mmap>
    800060f4:	87aa                	mv	a5,a0
    800060f6:	bf55                	j	800060aa <sys_mmap+0x74>
    return -1;
    800060f8:	57fd                	li	a5,-1
    800060fa:	bf45                	j	800060aa <sys_mmap+0x74>

00000000800060fc <sys_munmap>:


uint64
sys_munmap(void)
{
    800060fc:	1141                	addi	sp,sp,-16
    800060fe:	e422                	sd	s0,8(sp)
    80006100:	0800                	addi	s0,sp,16
  return 0;
}
    80006102:	4501                	li	a0,0
    80006104:	6422                	ld	s0,8(sp)
    80006106:	0141                	addi	sp,sp,16
    80006108:	8082                	ret
    8000610a:	0000                	unimp
    8000610c:	0000                	unimp
	...

0000000080006110 <kernelvec>:
    80006110:	7111                	addi	sp,sp,-256
    80006112:	e006                	sd	ra,0(sp)
    80006114:	e40a                	sd	sp,8(sp)
    80006116:	e80e                	sd	gp,16(sp)
    80006118:	ec12                	sd	tp,24(sp)
    8000611a:	f016                	sd	t0,32(sp)
    8000611c:	f41a                	sd	t1,40(sp)
    8000611e:	f81e                	sd	t2,48(sp)
    80006120:	fc22                	sd	s0,56(sp)
    80006122:	e0a6                	sd	s1,64(sp)
    80006124:	e4aa                	sd	a0,72(sp)
    80006126:	e8ae                	sd	a1,80(sp)
    80006128:	ecb2                	sd	a2,88(sp)
    8000612a:	f0b6                	sd	a3,96(sp)
    8000612c:	f4ba                	sd	a4,104(sp)
    8000612e:	f8be                	sd	a5,112(sp)
    80006130:	fcc2                	sd	a6,120(sp)
    80006132:	e146                	sd	a7,128(sp)
    80006134:	e54a                	sd	s2,136(sp)
    80006136:	e94e                	sd	s3,144(sp)
    80006138:	ed52                	sd	s4,152(sp)
    8000613a:	f156                	sd	s5,160(sp)
    8000613c:	f55a                	sd	s6,168(sp)
    8000613e:	f95e                	sd	s7,176(sp)
    80006140:	fd62                	sd	s8,184(sp)
    80006142:	e1e6                	sd	s9,192(sp)
    80006144:	e5ea                	sd	s10,200(sp)
    80006146:	e9ee                	sd	s11,208(sp)
    80006148:	edf2                	sd	t3,216(sp)
    8000614a:	f1f6                	sd	t4,224(sp)
    8000614c:	f5fa                	sd	t5,232(sp)
    8000614e:	f9fe                	sd	t6,240(sp)
    80006150:	b17fc0ef          	jal	ra,80002c66 <kerneltrap>
    80006154:	6082                	ld	ra,0(sp)
    80006156:	6122                	ld	sp,8(sp)
    80006158:	61c2                	ld	gp,16(sp)
    8000615a:	7282                	ld	t0,32(sp)
    8000615c:	7322                	ld	t1,40(sp)
    8000615e:	73c2                	ld	t2,48(sp)
    80006160:	7462                	ld	s0,56(sp)
    80006162:	6486                	ld	s1,64(sp)
    80006164:	6526                	ld	a0,72(sp)
    80006166:	65c6                	ld	a1,80(sp)
    80006168:	6666                	ld	a2,88(sp)
    8000616a:	7686                	ld	a3,96(sp)
    8000616c:	7726                	ld	a4,104(sp)
    8000616e:	77c6                	ld	a5,112(sp)
    80006170:	7866                	ld	a6,120(sp)
    80006172:	688a                	ld	a7,128(sp)
    80006174:	692a                	ld	s2,136(sp)
    80006176:	69ca                	ld	s3,144(sp)
    80006178:	6a6a                	ld	s4,152(sp)
    8000617a:	7a8a                	ld	s5,160(sp)
    8000617c:	7b2a                	ld	s6,168(sp)
    8000617e:	7bca                	ld	s7,176(sp)
    80006180:	7c6a                	ld	s8,184(sp)
    80006182:	6c8e                	ld	s9,192(sp)
    80006184:	6d2e                	ld	s10,200(sp)
    80006186:	6dce                	ld	s11,208(sp)
    80006188:	6e6e                	ld	t3,216(sp)
    8000618a:	7e8e                	ld	t4,224(sp)
    8000618c:	7f2e                	ld	t5,232(sp)
    8000618e:	7fce                	ld	t6,240(sp)
    80006190:	6111                	addi	sp,sp,256
    80006192:	10200073          	sret
    80006196:	00000013          	nop
    8000619a:	00000013          	nop
    8000619e:	0001                	nop

00000000800061a0 <timervec>:
    800061a0:	34051573          	csrrw	a0,mscratch,a0
    800061a4:	e10c                	sd	a1,0(a0)
    800061a6:	e510                	sd	a2,8(a0)
    800061a8:	e914                	sd	a3,16(a0)
    800061aa:	6d0c                	ld	a1,24(a0)
    800061ac:	7110                	ld	a2,32(a0)
    800061ae:	6194                	ld	a3,0(a1)
    800061b0:	96b2                	add	a3,a3,a2
    800061b2:	e194                	sd	a3,0(a1)
    800061b4:	4589                	li	a1,2
    800061b6:	14459073          	csrw	sip,a1
    800061ba:	6914                	ld	a3,16(a0)
    800061bc:	6510                	ld	a2,8(a0)
    800061be:	610c                	ld	a1,0(a0)
    800061c0:	34051573          	csrrw	a0,mscratch,a0
    800061c4:	30200073          	mret
	...

00000000800061ca <plicinit>:
// the riscv Platform Level Interrupt Controller (PLIC).
//

void
plicinit(void)
{
    800061ca:	1141                	addi	sp,sp,-16
    800061cc:	e422                	sd	s0,8(sp)
    800061ce:	0800                	addi	s0,sp,16
  // set desired IRQ priorities non-zero (otherwise disabled).
  *(uint32*)(PLIC + UART0_IRQ*4) = 1;
    800061d0:	0c0007b7          	lui	a5,0xc000
    800061d4:	4705                	li	a4,1
    800061d6:	d798                	sw	a4,40(a5)
  *(uint32*)(PLIC + VIRTIO0_IRQ*4) = 1;
    800061d8:	c3d8                	sw	a4,4(a5)
}
    800061da:	6422                	ld	s0,8(sp)
    800061dc:	0141                	addi	sp,sp,16
    800061de:	8082                	ret

00000000800061e0 <plicinithart>:

void
plicinithart(void)
{
    800061e0:	1141                	addi	sp,sp,-16
    800061e2:	e406                	sd	ra,8(sp)
    800061e4:	e022                	sd	s0,0(sp)
    800061e6:	0800                	addi	s0,sp,16
  int hart = cpuid();
    800061e8:	ffffc097          	auipc	ra,0xffffc
    800061ec:	a06080e7          	jalr	-1530(ra) # 80001bee <cpuid>
  
  // set uart's enable bit for this hart's S-mode. 
  *(uint32*)PLIC_SENABLE(hart)= (1 << UART0_IRQ) | (1 << VIRTIO0_IRQ);
    800061f0:	0085171b          	slliw	a4,a0,0x8
    800061f4:	0c0027b7          	lui	a5,0xc002
    800061f8:	97ba                	add	a5,a5,a4
    800061fa:	40200713          	li	a4,1026
    800061fe:	08e7a023          	sw	a4,128(a5) # c002080 <_entry-0x73ffdf80>

  // set this hart's S-mode priority threshold to 0.
  *(uint32*)PLIC_SPRIORITY(hart) = 0;
    80006202:	00d5151b          	slliw	a0,a0,0xd
    80006206:	0c2017b7          	lui	a5,0xc201
    8000620a:	953e                	add	a0,a0,a5
    8000620c:	00052023          	sw	zero,0(a0)
}
    80006210:	60a2                	ld	ra,8(sp)
    80006212:	6402                	ld	s0,0(sp)
    80006214:	0141                	addi	sp,sp,16
    80006216:	8082                	ret

0000000080006218 <plic_claim>:

// ask the PLIC what interrupt we should serve.
int
plic_claim(void)
{
    80006218:	1141                	addi	sp,sp,-16
    8000621a:	e406                	sd	ra,8(sp)
    8000621c:	e022                	sd	s0,0(sp)
    8000621e:	0800                	addi	s0,sp,16
  int hart = cpuid();
    80006220:	ffffc097          	auipc	ra,0xffffc
    80006224:	9ce080e7          	jalr	-1586(ra) # 80001bee <cpuid>
  int irq = *(uint32*)PLIC_SCLAIM(hart);
    80006228:	00d5179b          	slliw	a5,a0,0xd
    8000622c:	0c201537          	lui	a0,0xc201
    80006230:	953e                	add	a0,a0,a5
  return irq;
}
    80006232:	4148                	lw	a0,4(a0)
    80006234:	60a2                	ld	ra,8(sp)
    80006236:	6402                	ld	s0,0(sp)
    80006238:	0141                	addi	sp,sp,16
    8000623a:	8082                	ret

000000008000623c <plic_complete>:

// tell the PLIC we've served this IRQ.
void
plic_complete(int irq)
{
    8000623c:	1101                	addi	sp,sp,-32
    8000623e:	ec06                	sd	ra,24(sp)
    80006240:	e822                	sd	s0,16(sp)
    80006242:	e426                	sd	s1,8(sp)
    80006244:	1000                	addi	s0,sp,32
    80006246:	84aa                	mv	s1,a0
  int hart = cpuid();
    80006248:	ffffc097          	auipc	ra,0xffffc
    8000624c:	9a6080e7          	jalr	-1626(ra) # 80001bee <cpuid>
  *(uint32*)PLIC_SCLAIM(hart) = irq;
    80006250:	00d5151b          	slliw	a0,a0,0xd
    80006254:	0c2017b7          	lui	a5,0xc201
    80006258:	97aa                	add	a5,a5,a0
    8000625a:	c3c4                	sw	s1,4(a5)
}
    8000625c:	60e2                	ld	ra,24(sp)
    8000625e:	6442                	ld	s0,16(sp)
    80006260:	64a2                	ld	s1,8(sp)
    80006262:	6105                	addi	sp,sp,32
    80006264:	8082                	ret

0000000080006266 <free_desc>:
}

// mark a descriptor as free.
static void
free_desc(int i)
{
    80006266:	1141                	addi	sp,sp,-16
    80006268:	e406                	sd	ra,8(sp)
    8000626a:	e022                	sd	s0,0(sp)
    8000626c:	0800                	addi	s0,sp,16
  if(i >= NUM)
    8000626e:	479d                	li	a5,7
    80006270:	06a7c963          	blt	a5,a0,800062e2 <free_desc+0x7c>
    panic("free_desc 1");
  if(disk.free[i])
    80006274:	0089d797          	auipc	a5,0x89d
    80006278:	d8c78793          	addi	a5,a5,-628 # 808a3000 <disk>
    8000627c:	00a78733          	add	a4,a5,a0
    80006280:	6789                	lui	a5,0x2
    80006282:	97ba                	add	a5,a5,a4
    80006284:	0187c783          	lbu	a5,24(a5) # 2018 <_entry-0x7fffdfe8>
    80006288:	e7ad                	bnez	a5,800062f2 <free_desc+0x8c>
    panic("free_desc 2");
  disk.desc[i].addr = 0;
    8000628a:	00451793          	slli	a5,a0,0x4
    8000628e:	0089f717          	auipc	a4,0x89f
    80006292:	d7270713          	addi	a4,a4,-654 # 808a5000 <disk+0x2000>
    80006296:	6314                	ld	a3,0(a4)
    80006298:	96be                	add	a3,a3,a5
    8000629a:	0006b023          	sd	zero,0(a3) # fffffffffefff000 <end+0xffffffff7e759000>
  disk.desc[i].len = 0;
    8000629e:	6314                	ld	a3,0(a4)
    800062a0:	96be                	add	a3,a3,a5
    800062a2:	0006a423          	sw	zero,8(a3)
  disk.desc[i].flags = 0;
    800062a6:	6314                	ld	a3,0(a4)
    800062a8:	96be                	add	a3,a3,a5
    800062aa:	00069623          	sh	zero,12(a3)
  disk.desc[i].next = 0;
    800062ae:	6318                	ld	a4,0(a4)
    800062b0:	97ba                	add	a5,a5,a4
    800062b2:	00079723          	sh	zero,14(a5)
  disk.free[i] = 1;
    800062b6:	0089d797          	auipc	a5,0x89d
    800062ba:	d4a78793          	addi	a5,a5,-694 # 808a3000 <disk>
    800062be:	97aa                	add	a5,a5,a0
    800062c0:	6509                	lui	a0,0x2
    800062c2:	953e                	add	a0,a0,a5
    800062c4:	4785                	li	a5,1
    800062c6:	00f50c23          	sb	a5,24(a0) # 2018 <_entry-0x7fffdfe8>
  wakeup(&disk.free[0]);
    800062ca:	0089f517          	auipc	a0,0x89f
    800062ce:	d4e50513          	addi	a0,a0,-690 # 808a5018 <disk+0x2018>
    800062d2:	ffffc097          	auipc	ra,0xffffc
    800062d6:	19c080e7          	jalr	412(ra) # 8000246e <wakeup>
}
    800062da:	60a2                	ld	ra,8(sp)
    800062dc:	6402                	ld	s0,0(sp)
    800062de:	0141                	addi	sp,sp,16
    800062e0:	8082                	ret
    panic("free_desc 1");
    800062e2:	00002517          	auipc	a0,0x2
    800062e6:	57e50513          	addi	a0,a0,1406 # 80008860 <syscalls+0x340>
    800062ea:	ffffa097          	auipc	ra,0xffffa
    800062ee:	254080e7          	jalr	596(ra) # 8000053e <panic>
    panic("free_desc 2");
    800062f2:	00002517          	auipc	a0,0x2
    800062f6:	57e50513          	addi	a0,a0,1406 # 80008870 <syscalls+0x350>
    800062fa:	ffffa097          	auipc	ra,0xffffa
    800062fe:	244080e7          	jalr	580(ra) # 8000053e <panic>

0000000080006302 <virtio_disk_init>:
{
    80006302:	1101                	addi	sp,sp,-32
    80006304:	ec06                	sd	ra,24(sp)
    80006306:	e822                	sd	s0,16(sp)
    80006308:	e426                	sd	s1,8(sp)
    8000630a:	1000                	addi	s0,sp,32
  initlock(&disk.vdisk_lock, "virtio_disk");
    8000630c:	00002597          	auipc	a1,0x2
    80006310:	57458593          	addi	a1,a1,1396 # 80008880 <syscalls+0x360>
    80006314:	0089f517          	auipc	a0,0x89f
    80006318:	e1450513          	addi	a0,a0,-492 # 808a5128 <disk+0x2128>
    8000631c:	ffffb097          	auipc	ra,0xffffb
    80006320:	aa2080e7          	jalr	-1374(ra) # 80000dbe <initlock>
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006324:	100017b7          	lui	a5,0x10001
    80006328:	4398                	lw	a4,0(a5)
    8000632a:	2701                	sext.w	a4,a4
    8000632c:	747277b7          	lui	a5,0x74727
    80006330:	97678793          	addi	a5,a5,-1674 # 74726976 <_entry-0xb8d968a>
    80006334:	0ef71163          	bne	a4,a5,80006416 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    80006338:	100017b7          	lui	a5,0x10001
    8000633c:	43dc                	lw	a5,4(a5)
    8000633e:	2781                	sext.w	a5,a5
  if(*R(VIRTIO_MMIO_MAGIC_VALUE) != 0x74726976 ||
    80006340:	4705                	li	a4,1
    80006342:	0ce79a63          	bne	a5,a4,80006416 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    80006346:	100017b7          	lui	a5,0x10001
    8000634a:	479c                	lw	a5,8(a5)
    8000634c:	2781                	sext.w	a5,a5
     *R(VIRTIO_MMIO_VERSION) != 1 ||
    8000634e:	4709                	li	a4,2
    80006350:	0ce79363          	bne	a5,a4,80006416 <virtio_disk_init+0x114>
     *R(VIRTIO_MMIO_VENDOR_ID) != 0x554d4551){
    80006354:	100017b7          	lui	a5,0x10001
    80006358:	47d8                	lw	a4,12(a5)
    8000635a:	2701                	sext.w	a4,a4
     *R(VIRTIO_MMIO_DEVICE_ID) != 2 ||
    8000635c:	554d47b7          	lui	a5,0x554d4
    80006360:	55178793          	addi	a5,a5,1361 # 554d4551 <_entry-0x2ab2baaf>
    80006364:	0af71963          	bne	a4,a5,80006416 <virtio_disk_init+0x114>
  *R(VIRTIO_MMIO_STATUS) = status;
    80006368:	100017b7          	lui	a5,0x10001
    8000636c:	4705                	li	a4,1
    8000636e:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006370:	470d                	li	a4,3
    80006372:	dbb8                	sw	a4,112(a5)
  uint64 features = *R(VIRTIO_MMIO_DEVICE_FEATURES);
    80006374:	4b94                	lw	a3,16(a5)
  features &= ~(1 << VIRTIO_RING_F_INDIRECT_DESC);
    80006376:	c7ffe737          	lui	a4,0xc7ffe
    8000637a:	75f70713          	addi	a4,a4,1887 # ffffffffc7ffe75f <end+0xffffffff4775875f>
    8000637e:	8f75                	and	a4,a4,a3
  *R(VIRTIO_MMIO_DRIVER_FEATURES) = features;
    80006380:	2701                	sext.w	a4,a4
    80006382:	d398                	sw	a4,32(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006384:	472d                	li	a4,11
    80006386:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_STATUS) = status;
    80006388:	473d                	li	a4,15
    8000638a:	dbb8                	sw	a4,112(a5)
  *R(VIRTIO_MMIO_GUEST_PAGE_SIZE) = PGSIZE;
    8000638c:	6705                	lui	a4,0x1
    8000638e:	d798                	sw	a4,40(a5)
  *R(VIRTIO_MMIO_QUEUE_SEL) = 0;
    80006390:	0207a823          	sw	zero,48(a5) # 10001030 <_entry-0x6fffefd0>
  uint32 max = *R(VIRTIO_MMIO_QUEUE_NUM_MAX);
    80006394:	5bdc                	lw	a5,52(a5)
    80006396:	2781                	sext.w	a5,a5
  if(max == 0)
    80006398:	c7d9                	beqz	a5,80006426 <virtio_disk_init+0x124>
  if(max < NUM)
    8000639a:	471d                	li	a4,7
    8000639c:	08f77d63          	bgeu	a4,a5,80006436 <virtio_disk_init+0x134>
  *R(VIRTIO_MMIO_QUEUE_NUM) = NUM;
    800063a0:	100014b7          	lui	s1,0x10001
    800063a4:	47a1                	li	a5,8
    800063a6:	dc9c                	sw	a5,56(s1)
  memset(disk.pages, 0, sizeof(disk.pages));
    800063a8:	6609                	lui	a2,0x2
    800063aa:	4581                	li	a1,0
    800063ac:	0089d517          	auipc	a0,0x89d
    800063b0:	c5450513          	addi	a0,a0,-940 # 808a3000 <disk>
    800063b4:	ffffb097          	auipc	ra,0xffffb
    800063b8:	b96080e7          	jalr	-1130(ra) # 80000f4a <memset>
  *R(VIRTIO_MMIO_QUEUE_PFN) = ((uint64)disk.pages) >> PGSHIFT;
    800063bc:	0089d717          	auipc	a4,0x89d
    800063c0:	c4470713          	addi	a4,a4,-956 # 808a3000 <disk>
    800063c4:	00c75793          	srli	a5,a4,0xc
    800063c8:	2781                	sext.w	a5,a5
    800063ca:	c0bc                	sw	a5,64(s1)
  disk.desc = (struct virtq_desc *) disk.pages;
    800063cc:	0089f797          	auipc	a5,0x89f
    800063d0:	c3478793          	addi	a5,a5,-972 # 808a5000 <disk+0x2000>
    800063d4:	e398                	sd	a4,0(a5)
  disk.avail = (struct virtq_avail *)(disk.pages + NUM*sizeof(struct virtq_desc));
    800063d6:	0089d717          	auipc	a4,0x89d
    800063da:	caa70713          	addi	a4,a4,-854 # 808a3080 <disk+0x80>
    800063de:	e798                	sd	a4,8(a5)
  disk.used = (struct virtq_used *) (disk.pages + PGSIZE);
    800063e0:	0089e717          	auipc	a4,0x89e
    800063e4:	c2070713          	addi	a4,a4,-992 # 808a4000 <disk+0x1000>
    800063e8:	eb98                	sd	a4,16(a5)
    disk.free[i] = 1;
    800063ea:	4705                	li	a4,1
    800063ec:	00e78c23          	sb	a4,24(a5)
    800063f0:	00e78ca3          	sb	a4,25(a5)
    800063f4:	00e78d23          	sb	a4,26(a5)
    800063f8:	00e78da3          	sb	a4,27(a5)
    800063fc:	00e78e23          	sb	a4,28(a5)
    80006400:	00e78ea3          	sb	a4,29(a5)
    80006404:	00e78f23          	sb	a4,30(a5)
    80006408:	00e78fa3          	sb	a4,31(a5)
}
    8000640c:	60e2                	ld	ra,24(sp)
    8000640e:	6442                	ld	s0,16(sp)
    80006410:	64a2                	ld	s1,8(sp)
    80006412:	6105                	addi	sp,sp,32
    80006414:	8082                	ret
    panic("could not find virtio disk");
    80006416:	00002517          	auipc	a0,0x2
    8000641a:	47a50513          	addi	a0,a0,1146 # 80008890 <syscalls+0x370>
    8000641e:	ffffa097          	auipc	ra,0xffffa
    80006422:	120080e7          	jalr	288(ra) # 8000053e <panic>
    panic("virtio disk has no queue 0");
    80006426:	00002517          	auipc	a0,0x2
    8000642a:	48a50513          	addi	a0,a0,1162 # 800088b0 <syscalls+0x390>
    8000642e:	ffffa097          	auipc	ra,0xffffa
    80006432:	110080e7          	jalr	272(ra) # 8000053e <panic>
    panic("virtio disk max queue too short");
    80006436:	00002517          	auipc	a0,0x2
    8000643a:	49a50513          	addi	a0,a0,1178 # 800088d0 <syscalls+0x3b0>
    8000643e:	ffffa097          	auipc	ra,0xffffa
    80006442:	100080e7          	jalr	256(ra) # 8000053e <panic>

0000000080006446 <virtio_disk_rw>:
  return 0;
}

void
virtio_disk_rw(struct buf *b, int write)
{
    80006446:	7159                	addi	sp,sp,-112
    80006448:	f486                	sd	ra,104(sp)
    8000644a:	f0a2                	sd	s0,96(sp)
    8000644c:	eca6                	sd	s1,88(sp)
    8000644e:	e8ca                	sd	s2,80(sp)
    80006450:	e4ce                	sd	s3,72(sp)
    80006452:	e0d2                	sd	s4,64(sp)
    80006454:	fc56                	sd	s5,56(sp)
    80006456:	f85a                	sd	s6,48(sp)
    80006458:	f45e                	sd	s7,40(sp)
    8000645a:	f062                	sd	s8,32(sp)
    8000645c:	ec66                	sd	s9,24(sp)
    8000645e:	e86a                	sd	s10,16(sp)
    80006460:	1880                	addi	s0,sp,112
    80006462:	892a                	mv	s2,a0
    80006464:	8d2e                	mv	s10,a1
  uint64 sector = b->blockno * (BSIZE / 512);
    80006466:	00c52c83          	lw	s9,12(a0)
    8000646a:	001c9c9b          	slliw	s9,s9,0x1
    8000646e:	1c82                	slli	s9,s9,0x20
    80006470:	020cdc93          	srli	s9,s9,0x20

  acquire(&disk.vdisk_lock);
    80006474:	0089f517          	auipc	a0,0x89f
    80006478:	cb450513          	addi	a0,a0,-844 # 808a5128 <disk+0x2128>
    8000647c:	ffffb097          	auipc	ra,0xffffb
    80006480:	9d2080e7          	jalr	-1582(ra) # 80000e4e <acquire>
  for(int i = 0; i < 3; i++){
    80006484:	4981                	li	s3,0
  for(int i = 0; i < NUM; i++){
    80006486:	4c21                	li	s8,8
      disk.free[i] = 0;
    80006488:	0089db97          	auipc	s7,0x89d
    8000648c:	b78b8b93          	addi	s7,s7,-1160 # 808a3000 <disk>
    80006490:	6b09                	lui	s6,0x2
  for(int i = 0; i < 3; i++){
    80006492:	4a8d                	li	s5,3
  for(int i = 0; i < NUM; i++){
    80006494:	8a4e                	mv	s4,s3
    80006496:	a051                	j	8000651a <virtio_disk_rw+0xd4>
      disk.free[i] = 0;
    80006498:	00fb86b3          	add	a3,s7,a5
    8000649c:	96da                	add	a3,a3,s6
    8000649e:	00068c23          	sb	zero,24(a3)
    idx[i] = alloc_desc();
    800064a2:	c21c                	sw	a5,0(a2)
    if(idx[i] < 0){
    800064a4:	0207c563          	bltz	a5,800064ce <virtio_disk_rw+0x88>
  for(int i = 0; i < 3; i++){
    800064a8:	2485                	addiw	s1,s1,1
    800064aa:	0711                	addi	a4,a4,4
    800064ac:	25548063          	beq	s1,s5,800066ec <virtio_disk_rw+0x2a6>
    idx[i] = alloc_desc();
    800064b0:	863a                	mv	a2,a4
  for(int i = 0; i < NUM; i++){
    800064b2:	0089f697          	auipc	a3,0x89f
    800064b6:	b6668693          	addi	a3,a3,-1178 # 808a5018 <disk+0x2018>
    800064ba:	87d2                	mv	a5,s4
    if(disk.free[i]){
    800064bc:	0006c583          	lbu	a1,0(a3)
    800064c0:	fde1                	bnez	a1,80006498 <virtio_disk_rw+0x52>
  for(int i = 0; i < NUM; i++){
    800064c2:	2785                	addiw	a5,a5,1
    800064c4:	0685                	addi	a3,a3,1
    800064c6:	ff879be3          	bne	a5,s8,800064bc <virtio_disk_rw+0x76>
    idx[i] = alloc_desc();
    800064ca:	57fd                	li	a5,-1
    800064cc:	c21c                	sw	a5,0(a2)
      for(int j = 0; j < i; j++)
    800064ce:	02905a63          	blez	s1,80006502 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800064d2:	f9042503          	lw	a0,-112(s0)
    800064d6:	00000097          	auipc	ra,0x0
    800064da:	d90080e7          	jalr	-624(ra) # 80006266 <free_desc>
      for(int j = 0; j < i; j++)
    800064de:	4785                	li	a5,1
    800064e0:	0297d163          	bge	a5,s1,80006502 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800064e4:	f9442503          	lw	a0,-108(s0)
    800064e8:	00000097          	auipc	ra,0x0
    800064ec:	d7e080e7          	jalr	-642(ra) # 80006266 <free_desc>
      for(int j = 0; j < i; j++)
    800064f0:	4789                	li	a5,2
    800064f2:	0097d863          	bge	a5,s1,80006502 <virtio_disk_rw+0xbc>
        free_desc(idx[j]);
    800064f6:	f9842503          	lw	a0,-104(s0)
    800064fa:	00000097          	auipc	ra,0x0
    800064fe:	d6c080e7          	jalr	-660(ra) # 80006266 <free_desc>
  int idx[3];
  while(1){
    if(alloc3_desc(idx) == 0) {
      break;
    }
    sleep(&disk.free[0], &disk.vdisk_lock);
    80006502:	0089f597          	auipc	a1,0x89f
    80006506:	c2658593          	addi	a1,a1,-986 # 808a5128 <disk+0x2128>
    8000650a:	0089f517          	auipc	a0,0x89f
    8000650e:	b0e50513          	addi	a0,a0,-1266 # 808a5018 <disk+0x2018>
    80006512:	ffffc097          	auipc	ra,0xffffc
    80006516:	dd0080e7          	jalr	-560(ra) # 800022e2 <sleep>
  for(int i = 0; i < 3; i++){
    8000651a:	f9040713          	addi	a4,s0,-112
    8000651e:	84ce                	mv	s1,s3
    80006520:	bf41                	j	800064b0 <virtio_disk_rw+0x6a>
  // qemu's virtio-blk.c reads them.

  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];

  if(write)
    buf0->type = VIRTIO_BLK_T_OUT; // write the disk
    80006522:	20058713          	addi	a4,a1,512
    80006526:	00471693          	slli	a3,a4,0x4
    8000652a:	0089d717          	auipc	a4,0x89d
    8000652e:	ad670713          	addi	a4,a4,-1322 # 808a3000 <disk>
    80006532:	9736                	add	a4,a4,a3
    80006534:	4685                	li	a3,1
    80006536:	0ad72423          	sw	a3,168(a4)
  else
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
  buf0->reserved = 0;
    8000653a:	20058713          	addi	a4,a1,512
    8000653e:	00471693          	slli	a3,a4,0x4
    80006542:	0089d717          	auipc	a4,0x89d
    80006546:	abe70713          	addi	a4,a4,-1346 # 808a3000 <disk>
    8000654a:	9736                	add	a4,a4,a3
    8000654c:	0a072623          	sw	zero,172(a4)
  buf0->sector = sector;
    80006550:	0b973823          	sd	s9,176(a4)

  disk.desc[idx[0]].addr = (uint64) buf0;
    80006554:	7679                	lui	a2,0xffffe
    80006556:	963e                	add	a2,a2,a5
    80006558:	0089f697          	auipc	a3,0x89f
    8000655c:	aa868693          	addi	a3,a3,-1368 # 808a5000 <disk+0x2000>
    80006560:	6298                	ld	a4,0(a3)
    80006562:	9732                	add	a4,a4,a2
    80006564:	e308                	sd	a0,0(a4)
  disk.desc[idx[0]].len = sizeof(struct virtio_blk_req);
    80006566:	6298                	ld	a4,0(a3)
    80006568:	9732                	add	a4,a4,a2
    8000656a:	4541                	li	a0,16
    8000656c:	c708                	sw	a0,8(a4)
  disk.desc[idx[0]].flags = VRING_DESC_F_NEXT;
    8000656e:	6298                	ld	a4,0(a3)
    80006570:	9732                	add	a4,a4,a2
    80006572:	4505                	li	a0,1
    80006574:	00a71623          	sh	a0,12(a4)
  disk.desc[idx[0]].next = idx[1];
    80006578:	f9442703          	lw	a4,-108(s0)
    8000657c:	6288                	ld	a0,0(a3)
    8000657e:	962a                	add	a2,a2,a0
    80006580:	00e61723          	sh	a4,14(a2) # ffffffffffffe00e <end+0xffffffff7f75800e>

  disk.desc[idx[1]].addr = (uint64) b->data;
    80006584:	0712                	slli	a4,a4,0x4
    80006586:	6290                	ld	a2,0(a3)
    80006588:	963a                	add	a2,a2,a4
    8000658a:	05890513          	addi	a0,s2,88
    8000658e:	e208                	sd	a0,0(a2)
  disk.desc[idx[1]].len = BSIZE;
    80006590:	6294                	ld	a3,0(a3)
    80006592:	96ba                	add	a3,a3,a4
    80006594:	40000613          	li	a2,1024
    80006598:	c690                	sw	a2,8(a3)
  if(write)
    8000659a:	140d0063          	beqz	s10,800066da <virtio_disk_rw+0x294>
    disk.desc[idx[1]].flags = 0; // device reads b->data
    8000659e:	0089f697          	auipc	a3,0x89f
    800065a2:	a626b683          	ld	a3,-1438(a3) # 808a5000 <disk+0x2000>
    800065a6:	96ba                	add	a3,a3,a4
    800065a8:	00069623          	sh	zero,12(a3)
  else
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
  disk.desc[idx[1]].flags |= VRING_DESC_F_NEXT;
    800065ac:	0089d817          	auipc	a6,0x89d
    800065b0:	a5480813          	addi	a6,a6,-1452 # 808a3000 <disk>
    800065b4:	0089f517          	auipc	a0,0x89f
    800065b8:	a4c50513          	addi	a0,a0,-1460 # 808a5000 <disk+0x2000>
    800065bc:	6114                	ld	a3,0(a0)
    800065be:	96ba                	add	a3,a3,a4
    800065c0:	00c6d603          	lhu	a2,12(a3)
    800065c4:	00166613          	ori	a2,a2,1
    800065c8:	00c69623          	sh	a2,12(a3)
  disk.desc[idx[1]].next = idx[2];
    800065cc:	f9842683          	lw	a3,-104(s0)
    800065d0:	6110                	ld	a2,0(a0)
    800065d2:	9732                	add	a4,a4,a2
    800065d4:	00d71723          	sh	a3,14(a4)

  disk.info[idx[0]].status = 0xff; // device writes 0 on success
    800065d8:	20058613          	addi	a2,a1,512
    800065dc:	0612                	slli	a2,a2,0x4
    800065de:	9642                	add	a2,a2,a6
    800065e0:	577d                	li	a4,-1
    800065e2:	02e60823          	sb	a4,48(a2)
  disk.desc[idx[2]].addr = (uint64) &disk.info[idx[0]].status;
    800065e6:	00469713          	slli	a4,a3,0x4
    800065ea:	6114                	ld	a3,0(a0)
    800065ec:	96ba                	add	a3,a3,a4
    800065ee:	03078793          	addi	a5,a5,48
    800065f2:	97c2                	add	a5,a5,a6
    800065f4:	e29c                	sd	a5,0(a3)
  disk.desc[idx[2]].len = 1;
    800065f6:	611c                	ld	a5,0(a0)
    800065f8:	97ba                	add	a5,a5,a4
    800065fa:	4685                	li	a3,1
    800065fc:	c794                	sw	a3,8(a5)
  disk.desc[idx[2]].flags = VRING_DESC_F_WRITE; // device writes the status
    800065fe:	611c                	ld	a5,0(a0)
    80006600:	97ba                	add	a5,a5,a4
    80006602:	4809                	li	a6,2
    80006604:	01079623          	sh	a6,12(a5)
  disk.desc[idx[2]].next = 0;
    80006608:	611c                	ld	a5,0(a0)
    8000660a:	973e                	add	a4,a4,a5
    8000660c:	00071723          	sh	zero,14(a4)

  // record struct buf for virtio_disk_intr().
  b->disk = 1;
    80006610:	00d92223          	sw	a3,4(s2)
  disk.info[idx[0]].b = b;
    80006614:	03263423          	sd	s2,40(a2)

  // tell the device the first index in our chain of descriptors.
  disk.avail->ring[disk.avail->idx % NUM] = idx[0];
    80006618:	6518                	ld	a4,8(a0)
    8000661a:	00275783          	lhu	a5,2(a4)
    8000661e:	8b9d                	andi	a5,a5,7
    80006620:	0786                	slli	a5,a5,0x1
    80006622:	97ba                	add	a5,a5,a4
    80006624:	00b79223          	sh	a1,4(a5)

  __sync_synchronize();
    80006628:	0ff0000f          	fence

  // tell the device another avail ring entry is available.
  disk.avail->idx += 1; // not % NUM ...
    8000662c:	6518                	ld	a4,8(a0)
    8000662e:	00275783          	lhu	a5,2(a4)
    80006632:	2785                	addiw	a5,a5,1
    80006634:	00f71123          	sh	a5,2(a4)

  __sync_synchronize();
    80006638:	0ff0000f          	fence

  *R(VIRTIO_MMIO_QUEUE_NOTIFY) = 0; // value is queue number
    8000663c:	100017b7          	lui	a5,0x10001
    80006640:	0407a823          	sw	zero,80(a5) # 10001050 <_entry-0x6fffefb0>

  // Wait for virtio_disk_intr() to say request has finished.
  while(b->disk == 1) {
    80006644:	00492703          	lw	a4,4(s2)
    80006648:	4785                	li	a5,1
    8000664a:	02f71163          	bne	a4,a5,8000666c <virtio_disk_rw+0x226>
    sleep(b, &disk.vdisk_lock);
    8000664e:	0089f997          	auipc	s3,0x89f
    80006652:	ada98993          	addi	s3,s3,-1318 # 808a5128 <disk+0x2128>
  while(b->disk == 1) {
    80006656:	4485                	li	s1,1
    sleep(b, &disk.vdisk_lock);
    80006658:	85ce                	mv	a1,s3
    8000665a:	854a                	mv	a0,s2
    8000665c:	ffffc097          	auipc	ra,0xffffc
    80006660:	c86080e7          	jalr	-890(ra) # 800022e2 <sleep>
  while(b->disk == 1) {
    80006664:	00492783          	lw	a5,4(s2)
    80006668:	fe9788e3          	beq	a5,s1,80006658 <virtio_disk_rw+0x212>
  }

  disk.info[idx[0]].b = 0;
    8000666c:	f9042903          	lw	s2,-112(s0)
    80006670:	20090793          	addi	a5,s2,512
    80006674:	00479713          	slli	a4,a5,0x4
    80006678:	0089d797          	auipc	a5,0x89d
    8000667c:	98878793          	addi	a5,a5,-1656 # 808a3000 <disk>
    80006680:	97ba                	add	a5,a5,a4
    80006682:	0207b423          	sd	zero,40(a5)
    int flag = disk.desc[i].flags;
    80006686:	0089f997          	auipc	s3,0x89f
    8000668a:	97a98993          	addi	s3,s3,-1670 # 808a5000 <disk+0x2000>
    8000668e:	00491713          	slli	a4,s2,0x4
    80006692:	0009b783          	ld	a5,0(s3)
    80006696:	97ba                	add	a5,a5,a4
    80006698:	00c7d483          	lhu	s1,12(a5)
    int nxt = disk.desc[i].next;
    8000669c:	854a                	mv	a0,s2
    8000669e:	00e7d903          	lhu	s2,14(a5)
    free_desc(i);
    800066a2:	00000097          	auipc	ra,0x0
    800066a6:	bc4080e7          	jalr	-1084(ra) # 80006266 <free_desc>
    if(flag & VRING_DESC_F_NEXT)
    800066aa:	8885                	andi	s1,s1,1
    800066ac:	f0ed                	bnez	s1,8000668e <virtio_disk_rw+0x248>
  free_chain(idx[0]);

  release(&disk.vdisk_lock);
    800066ae:	0089f517          	auipc	a0,0x89f
    800066b2:	a7a50513          	addi	a0,a0,-1414 # 808a5128 <disk+0x2128>
    800066b6:	ffffb097          	auipc	ra,0xffffb
    800066ba:	84c080e7          	jalr	-1972(ra) # 80000f02 <release>
}
    800066be:	70a6                	ld	ra,104(sp)
    800066c0:	7406                	ld	s0,96(sp)
    800066c2:	64e6                	ld	s1,88(sp)
    800066c4:	6946                	ld	s2,80(sp)
    800066c6:	69a6                	ld	s3,72(sp)
    800066c8:	6a06                	ld	s4,64(sp)
    800066ca:	7ae2                	ld	s5,56(sp)
    800066cc:	7b42                	ld	s6,48(sp)
    800066ce:	7ba2                	ld	s7,40(sp)
    800066d0:	7c02                	ld	s8,32(sp)
    800066d2:	6ce2                	ld	s9,24(sp)
    800066d4:	6d42                	ld	s10,16(sp)
    800066d6:	6165                	addi	sp,sp,112
    800066d8:	8082                	ret
    disk.desc[idx[1]].flags = VRING_DESC_F_WRITE; // device writes b->data
    800066da:	0089f697          	auipc	a3,0x89f
    800066de:	9266b683          	ld	a3,-1754(a3) # 808a5000 <disk+0x2000>
    800066e2:	96ba                	add	a3,a3,a4
    800066e4:	4609                	li	a2,2
    800066e6:	00c69623          	sh	a2,12(a3)
    800066ea:	b5c9                	j	800065ac <virtio_disk_rw+0x166>
  struct virtio_blk_req *buf0 = &disk.ops[idx[0]];
    800066ec:	f9042583          	lw	a1,-112(s0)
    800066f0:	20058793          	addi	a5,a1,512
    800066f4:	0792                	slli	a5,a5,0x4
    800066f6:	0089d517          	auipc	a0,0x89d
    800066fa:	9b250513          	addi	a0,a0,-1614 # 808a30a8 <disk+0xa8>
    800066fe:	953e                	add	a0,a0,a5
  if(write)
    80006700:	e20d11e3          	bnez	s10,80006522 <virtio_disk_rw+0xdc>
    buf0->type = VIRTIO_BLK_T_IN; // read the disk
    80006704:	20058713          	addi	a4,a1,512
    80006708:	00471693          	slli	a3,a4,0x4
    8000670c:	0089d717          	auipc	a4,0x89d
    80006710:	8f470713          	addi	a4,a4,-1804 # 808a3000 <disk>
    80006714:	9736                	add	a4,a4,a3
    80006716:	0a072423          	sw	zero,168(a4)
    8000671a:	b505                	j	8000653a <virtio_disk_rw+0xf4>

000000008000671c <virtio_disk_intr>:

void
virtio_disk_intr()
{
    8000671c:	1101                	addi	sp,sp,-32
    8000671e:	ec06                	sd	ra,24(sp)
    80006720:	e822                	sd	s0,16(sp)
    80006722:	e426                	sd	s1,8(sp)
    80006724:	e04a                	sd	s2,0(sp)
    80006726:	1000                	addi	s0,sp,32
  acquire(&disk.vdisk_lock);
    80006728:	0089f517          	auipc	a0,0x89f
    8000672c:	a0050513          	addi	a0,a0,-1536 # 808a5128 <disk+0x2128>
    80006730:	ffffa097          	auipc	ra,0xffffa
    80006734:	71e080e7          	jalr	1822(ra) # 80000e4e <acquire>
  // we've seen this interrupt, which the following line does.
  // this may race with the device writing new entries to
  // the "used" ring, in which case we may process the new
  // completion entries in this interrupt, and have nothing to do
  // in the next interrupt, which is harmless.
  *R(VIRTIO_MMIO_INTERRUPT_ACK) = *R(VIRTIO_MMIO_INTERRUPT_STATUS) & 0x3;
    80006738:	10001737          	lui	a4,0x10001
    8000673c:	533c                	lw	a5,96(a4)
    8000673e:	8b8d                	andi	a5,a5,3
    80006740:	d37c                	sw	a5,100(a4)

  __sync_synchronize();
    80006742:	0ff0000f          	fence

  // the device increments disk.used->idx when it
  // adds an entry to the used ring.

  while(disk.used_idx != disk.used->idx){
    80006746:	0089f797          	auipc	a5,0x89f
    8000674a:	8ba78793          	addi	a5,a5,-1862 # 808a5000 <disk+0x2000>
    8000674e:	6b94                	ld	a3,16(a5)
    80006750:	0207d703          	lhu	a4,32(a5)
    80006754:	0026d783          	lhu	a5,2(a3)
    80006758:	06f70163          	beq	a4,a5,800067ba <virtio_disk_intr+0x9e>
    __sync_synchronize();
    int id = disk.used->ring[disk.used_idx % NUM].id;
    8000675c:	0089d917          	auipc	s2,0x89d
    80006760:	8a490913          	addi	s2,s2,-1884 # 808a3000 <disk>
    80006764:	0089f497          	auipc	s1,0x89f
    80006768:	89c48493          	addi	s1,s1,-1892 # 808a5000 <disk+0x2000>
    __sync_synchronize();
    8000676c:	0ff0000f          	fence
    int id = disk.used->ring[disk.used_idx % NUM].id;
    80006770:	6898                	ld	a4,16(s1)
    80006772:	0204d783          	lhu	a5,32(s1)
    80006776:	8b9d                	andi	a5,a5,7
    80006778:	078e                	slli	a5,a5,0x3
    8000677a:	97ba                	add	a5,a5,a4
    8000677c:	43dc                	lw	a5,4(a5)

    if(disk.info[id].status != 0)
    8000677e:	20078713          	addi	a4,a5,512
    80006782:	0712                	slli	a4,a4,0x4
    80006784:	974a                	add	a4,a4,s2
    80006786:	03074703          	lbu	a4,48(a4) # 10001030 <_entry-0x6fffefd0>
    8000678a:	e731                	bnez	a4,800067d6 <virtio_disk_intr+0xba>
      panic("virtio_disk_intr status");

    struct buf *b = disk.info[id].b;
    8000678c:	20078793          	addi	a5,a5,512
    80006790:	0792                	slli	a5,a5,0x4
    80006792:	97ca                	add	a5,a5,s2
    80006794:	7788                	ld	a0,40(a5)
    b->disk = 0;   // disk is done with buf
    80006796:	00052223          	sw	zero,4(a0)
    wakeup(b);
    8000679a:	ffffc097          	auipc	ra,0xffffc
    8000679e:	cd4080e7          	jalr	-812(ra) # 8000246e <wakeup>

    disk.used_idx += 1;
    800067a2:	0204d783          	lhu	a5,32(s1)
    800067a6:	2785                	addiw	a5,a5,1
    800067a8:	17c2                	slli	a5,a5,0x30
    800067aa:	93c1                	srli	a5,a5,0x30
    800067ac:	02f49023          	sh	a5,32(s1)
  while(disk.used_idx != disk.used->idx){
    800067b0:	6898                	ld	a4,16(s1)
    800067b2:	00275703          	lhu	a4,2(a4)
    800067b6:	faf71be3          	bne	a4,a5,8000676c <virtio_disk_intr+0x50>
  }

  release(&disk.vdisk_lock);
    800067ba:	0089f517          	auipc	a0,0x89f
    800067be:	96e50513          	addi	a0,a0,-1682 # 808a5128 <disk+0x2128>
    800067c2:	ffffa097          	auipc	ra,0xffffa
    800067c6:	740080e7          	jalr	1856(ra) # 80000f02 <release>
}
    800067ca:	60e2                	ld	ra,24(sp)
    800067cc:	6442                	ld	s0,16(sp)
    800067ce:	64a2                	ld	s1,8(sp)
    800067d0:	6902                	ld	s2,0(sp)
    800067d2:	6105                	addi	sp,sp,32
    800067d4:	8082                	ret
      panic("virtio_disk_intr status");
    800067d6:	00002517          	auipc	a0,0x2
    800067da:	11a50513          	addi	a0,a0,282 # 800088f0 <syscalls+0x3d0>
    800067de:	ffffa097          	auipc	ra,0xffffa
    800067e2:	d60080e7          	jalr	-672(ra) # 8000053e <panic>
	...

0000000080007000 <_trampoline>:
    80007000:	14051573          	csrrw	a0,sscratch,a0
    80007004:	02153423          	sd	ra,40(a0)
    80007008:	02253823          	sd	sp,48(a0)
    8000700c:	02353c23          	sd	gp,56(a0)
    80007010:	04453023          	sd	tp,64(a0)
    80007014:	04553423          	sd	t0,72(a0)
    80007018:	04653823          	sd	t1,80(a0)
    8000701c:	04753c23          	sd	t2,88(a0)
    80007020:	f120                	sd	s0,96(a0)
    80007022:	f524                	sd	s1,104(a0)
    80007024:	fd2c                	sd	a1,120(a0)
    80007026:	e150                	sd	a2,128(a0)
    80007028:	e554                	sd	a3,136(a0)
    8000702a:	e958                	sd	a4,144(a0)
    8000702c:	ed5c                	sd	a5,152(a0)
    8000702e:	0b053023          	sd	a6,160(a0)
    80007032:	0b153423          	sd	a7,168(a0)
    80007036:	0b253823          	sd	s2,176(a0)
    8000703a:	0b353c23          	sd	s3,184(a0)
    8000703e:	0d453023          	sd	s4,192(a0)
    80007042:	0d553423          	sd	s5,200(a0)
    80007046:	0d653823          	sd	s6,208(a0)
    8000704a:	0d753c23          	sd	s7,216(a0)
    8000704e:	0f853023          	sd	s8,224(a0)
    80007052:	0f953423          	sd	s9,232(a0)
    80007056:	0fa53823          	sd	s10,240(a0)
    8000705a:	0fb53c23          	sd	s11,248(a0)
    8000705e:	11c53023          	sd	t3,256(a0)
    80007062:	11d53423          	sd	t4,264(a0)
    80007066:	11e53823          	sd	t5,272(a0)
    8000706a:	11f53c23          	sd	t6,280(a0)
    8000706e:	140022f3          	csrr	t0,sscratch
    80007072:	06553823          	sd	t0,112(a0)
    80007076:	00853103          	ld	sp,8(a0)
    8000707a:	02053203          	ld	tp,32(a0)
    8000707e:	01053283          	ld	t0,16(a0)
    80007082:	00053303          	ld	t1,0(a0)
    80007086:	18031073          	csrw	satp,t1
    8000708a:	12000073          	sfence.vma
    8000708e:	8282                	jr	t0

0000000080007090 <userret>:
    80007090:	18059073          	csrw	satp,a1
    80007094:	12000073          	sfence.vma
    80007098:	07053283          	ld	t0,112(a0)
    8000709c:	14029073          	csrw	sscratch,t0
    800070a0:	02853083          	ld	ra,40(a0)
    800070a4:	03053103          	ld	sp,48(a0)
    800070a8:	03853183          	ld	gp,56(a0)
    800070ac:	04053203          	ld	tp,64(a0)
    800070b0:	04853283          	ld	t0,72(a0)
    800070b4:	05053303          	ld	t1,80(a0)
    800070b8:	05853383          	ld	t2,88(a0)
    800070bc:	7120                	ld	s0,96(a0)
    800070be:	7524                	ld	s1,104(a0)
    800070c0:	7d2c                	ld	a1,120(a0)
    800070c2:	6150                	ld	a2,128(a0)
    800070c4:	6554                	ld	a3,136(a0)
    800070c6:	6958                	ld	a4,144(a0)
    800070c8:	6d5c                	ld	a5,152(a0)
    800070ca:	0a053803          	ld	a6,160(a0)
    800070ce:	0a853883          	ld	a7,168(a0)
    800070d2:	0b053903          	ld	s2,176(a0)
    800070d6:	0b853983          	ld	s3,184(a0)
    800070da:	0c053a03          	ld	s4,192(a0)
    800070de:	0c853a83          	ld	s5,200(a0)
    800070e2:	0d053b03          	ld	s6,208(a0)
    800070e6:	0d853b83          	ld	s7,216(a0)
    800070ea:	0e053c03          	ld	s8,224(a0)
    800070ee:	0e853c83          	ld	s9,232(a0)
    800070f2:	0f053d03          	ld	s10,240(a0)
    800070f6:	0f853d83          	ld	s11,248(a0)
    800070fa:	10053e03          	ld	t3,256(a0)
    800070fe:	10853e83          	ld	t4,264(a0)
    80007102:	11053f03          	ld	t5,272(a0)
    80007106:	11853f83          	ld	t6,280(a0)
    8000710a:	14051573          	csrrw	a0,sscratch,a0
    8000710e:	10200073          	sret
	...
