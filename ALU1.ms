// Don't change signature of existing functions. You may write additional helper functions if you want.
import ProcTypes;

// Description: 32-bit right barrel shifter
// Arguments: in (value to be shifted); sftSz (shift size); sft_in (the bit shifted in)
// Return: {sft_in's, in[31:sftSz]}
function Bit#(32) barrelRShift(Bit#(32) in, Bit#(5) sftSz, Bit#(1) sft_in);
Bit #(32) ret = in;
    Bit #(16) s16=signExtend(sft_in);
    if(sftSz[4]==1) ret={s16,ret[31:16]};

    Bit #(8) s8=truncate(s16);
    if(sftSz[3]==1) ret={s8,ret[31:8]};

    Bit #(4) s4=truncate(s8);
    if(sftSz[2]==1) ret={s4,ret[31:4]};

    Bit #(2) s2=truncate(s4);
    if(sftSz[1]==1) ret={s2,ret[31:2]};

    Bit #(1) s1=truncate(s2);
    if(sftSz[0]==1) ret={s1,ret[31:1]};

    return ret;
   endfunction

// Description: 32-bit arithmetic/logic right shifter
// Arguments: in (value to be shifted); sftSz (shift size); arith (1 = arithmetic, 0 = logic)
// Return: in >> sftSz
function Bit#(32) sr32(Bit#(32) in, Bit#(5) sftSz, Bit#(1) arith);
   Bit #(32) ret = 0;
   Bit #(1) sft_in=0;
   if(arith[0]==1 && in[31]==1) sft_in=1;
   ret=barrelRShift(in, sftSz, sft_in);
   return ret;
   endfunction


//Description: 32-bit logic left shifter
//Arguments: in (values to be shifted); sftSz (shift size)
//Return: a << b
function Bit#(32) sll32(Bit#(32) in, Bit#(5) sftSz);
Bit #(32) ret=0;
   in=reverseBits(in);
   ret=barrelRShift(in, sftSz, 0);
   ret=reverseBits(ret);
   return ret;
   endfunction


//Description: 32-bit FULL shifter
//Arguments: in (value to be shifted); sftSz (shift size);
//ShiftTypes:
//LogicalRightShift
//ArithmeticRightShift
//LeftShift
//
//Return: in >> sftSz when right shift; in << sftSz otherwise
   typedef enum {LogicalRightShift, ArithmeticRightShift, LeftShift} ShiftType;

   function Bit#(32) sft32(Bit#(32) in, Bit#(5) sftSz, ShiftType shiftType);
   Bit#(32) ret = 0;
       Bit#(1) sft_in=0;
       if(shiftType==ArithmeticRightShift) if(in[31]==1) sft_in=1;
       if(shiftType==LeftShift) in=reverseBits(in);
       ret=barrelRShift(in, sftSz, sft_in);
       if(shiftType==LeftShift) ret=reverseBits(ret);
       return ret;
       endfunction



   // Description: one-bit less-than comparator
   // Arguments: a, b (1-bit values), eq, lt (eq and lt from previous comparator)
   // Return: {eq_i, lt_i}
   function Bit#(2) cmp(Bit#(1) a, Bit#(1) b, Bit#(1) eq, Bit#(1) lt);
       return {eq&(~(a^b)), lt|(eq&~a&b)};
   endfunction

   function Bit#(2) cmp2#(Integer n)(Bit#(n) a, Bit#(n) b);
       if(n==1) return cmp(a,b,1,0);
       else begin
           let left=cmp2#(n-n/2)(a[n-1:n/2],b[n-1:n/2]);
           let right=cmp2#(n/2)(a[n/2-1:0],b[n/2-1:0]);
           return {left[1]&right[1],left[0]|(left[1]&right[0])};
       end
   endfunction
// Description: unsigned 32-bit less-than comparator
// Arguments: a, b unsigned 32-bit values
// Return: 1 if a < b
function Bit#(1) ltu32(Bit#(32) a, Bit#(32) b);
    Bit#(2) ret = 0;
    ret=cmp2#(32)(a,b);
    return ret[0];
endfunction

// Description: Signed/Unsigned 32-bit less-than comparator
// Arguments: a b (32-bit values); isSigned (signed comparator when 1, unsigned otherwise)
// Return: 1 if a < b
function Bit#(1) lt32(Bit#(32) a, Bit#(32) b, Bit#(1) isSigned);
    a=reverseBits(a);
    b=reverseBits(b);
    if((isSigned[0]&(a[0]^b[0]))==1) return a[0];
    else begin
        if((isSigned[0]&a[0]&b[0])==1) begin
            a[0]=0; b[0]=0;
        end
        a=reverseBits(a);
        b=reverseBits(b);
        return ltu32(a,b);
    end
endfunction

// Description: one-bit full adder
//Description: one-bit full adder
//Arguments: a, b, carry in
//Return: {carry out, sum}
function Bit#(2) fullAdder(Bit#(1) a, Bit#(1) b, Bit#(1) carryIn);
 Bit#(2) ret = 0;
 ret[0]=a^b^carryIn;
 ret[1]=(a&b)|(a&carryIn)|(b&carryIn);
 return ret;
endfunction

function Bit#(n+1) rca2#(Integer n)(Bit#(n) a, Bit#(n) b, Bit#(1) carryIn);
Bit#(n) s=0;
Bit#(n+1) c={0,carryIn};
for(Integer i=0; i<n;i=i+1) begin
     Bit#(2) sc=fullAdder(a[i],b[i],c[i]);
     s[i]=sc[0];
     c[i+1]=sc[1];
end
return {c[n],s};
endfunction


//Description: n-bit ripple-carry adder with a carry-in
//Arguments: a, b, carryIn
//Return: sum of a, b, and carryIni
function Bit#(n) rca#(Integer n)(Bit#(n) a, Bit#(n) b, Bit#(1) carryIn);
Bit#(n+1) ret=rca2#(n)(a,b,carryIn);
return ret[(n-1):0];
endfunction
//Description: n-bit ripple-carry adder/subractor
//Arguments: a, b (n-bit operands); isSub (1 => subtract, 0 => add)
//Return: isSub == 0 ? a + b : a - b
function Bit#(n) addSub#(Integer n)(Bit#(n) a, Bit#(n) b, Bit#(1) isSub);
 Bit#(n) ret = 0;
 if(isSub[0]==1) b=~b;
 ret=fastAdd#(n)(a,b,isSub);
 return ret;
endfunction

//Alu Functions:
//Add: 32-bit Addition         (a + b)
//Sub: 32-bit Subtraction      (a - b)
//And: 32-bit Bitwise And      (a & b)
//Or: 32-bit Bitwise Or        (a | b)
//Xor: 32-bit Bitwise Xor      (a ^ b)
//Slt: Set less than           (a <u b ? 1 : 0)
//Sltu: Set less than unsigned (a <s b ? 1:0)
//Sll: Left logic shfit        (a << b)
//Srl: Right logic shift       (a >>u b)
//Sra: Right arithmetic shift  (a >>s b)
//typedef enum {Add, Sub, And, Or, Xor, Slt, Sltu, Sll, Srl, Sra} AluFunc;

//Description: Arithmetic Logic Unit (ALU)
//Arguments: a, operand a; b, operand b; func, ALU operation
//Return: output of ALU
function Bit#(32) alu(Bit#(32) a, Bit#(32) b, IType func);
Bit#(32) ret=0;
if(func==Add || func==Sub) begin
    Bit#(1) isSub=(func==Sub)?1:0;
    ret=addSub#(32)(a,b,isSub);
end
if(func==And) ret=a&b;
if(func==Or) ret=a|b;
if(func==Xor) ret=a^b;
if(func==Slt || func==Sltu) begin
    Bit#(1) isSigned=(func==Slt)?1:0;
    ret=zeroExtend(lt32(a,b,isSigned));
end
if(func==Sll || func==Srl || func==Sra) begin
    ShiftType sT=LogicalRightShift;
    if(func==Sra) sT=ArithmeticRightShift;
    if(func==Sll) sT=LeftShift;
    Bit#(5) b5=truncate(b);
    ret=sft32(a,b5,sT);
end
return ret;
endfunction

//Description: Alternative shifter implementation (Discussion Question)
function Bit#(32) sft32_alt(Bit#(32) in, Bit#(5) sftSz, ShiftType shiftType);
return (shiftType == LeftShift) ? sft32(in, sftSz, LeftShift) : ((shiftType == ArithmeticRightShift)? sft32(in, sftSz, ArithmeticRightShift) : sft32(in, sftSz, LogicalRightShift));
endfunction
//Description: N-bit fast adder with a carry-in (Design Exercise)
//Arguments: a, b, carryIn
//Return: sum of a, b, and carryIn
function Bit#(n) fastAdd#(Integer n)(Bit#(n) a, Bit#(n) b, Bit#(1) carryIn);
 Bit#(n) ret = 0;
 Bit#(2*n) top=0;
 for(Integer i=0;i<n;i=i+1) begin
     top[2*i+1]=a[i]&b[i];
     top[2*i]=a[i]|b[i];
 end
 for(Integer s=0;(1<<s)<n;s=s+1) begin
     for(Integer i=n-1;i>=(1<<s);i=i-1) begin
         top[2*i+1]=top[2*i+1]|(top[2*i]&top[2*(i-(1<<s))+1]);
         top[2*i]=top[2*i]&top[2*(i-(1<<s))];
     end
 end
 ret[0]=a[0]^b[0]^carryIn;
 for(Integer i=1;i<n;i=i+1) ret[i]=a[i]^b[i]^(top[2*i-1]|(top[2*i-2]&carryIn));
 return ret;
endfunction




