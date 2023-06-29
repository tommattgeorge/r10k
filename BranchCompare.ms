import ProcTypes;
import ALU1;

module BranchCompare;

input Word rs default=0;
input Word rt default=0;
input IType brFunc default=Unsupported;
input Word immI default=0;

Reg#(Bool) taken(False);
Reg#(Word) target(0);

method Bool mtaken(Word rs1, Word rt1, IType brFunc1, Word immI1)=tkn(rs1,rt1,brFunc1,immI1);
method Word mtarget(Word rs1, Word rt1, IType brFunc1, Word immI1)=tgt(rs1,rt1,brFunc1,immI1);

function Word tgt(Word rs1, Word rt1, IType brFunc1, Word immI1);
    Word theTarget=0;
    case(brFunc1)
        Eq: begin
            theTarget=0;
        end
        Neq: begin
            theTarget=0;
        end
        Lt: begin
            theTarget=0;
        end
        Ltu: begin
            theTarget=0;
        end
        Ge: begin
            theTarget=0;
        end
        Geu: begin
            theTarget=0;
        end
        JAL: begin
            theTarget=rs1;
        end
        JALR: begin
            theTarget = rs1 + immI1;
        end
        default: begin
            theTarget=0;
        end
    endcase
    return theTarget;
endfunction

function Bool tkn(Word rs1, Word rt1, IType brFunc1, Word immI1);
    Bool isTaken=False;
    case(brFunc1)
        Eq: begin
            isTaken=(rs1 == rt1);
        end
        Neq: begin
            isTaken=(rs1 != rt1);
        end
        Lt: begin
            isTaken=signedLT(rs1, rt1); // Built-in signed comparison
        end
        Ltu: begin
            isTaken=(rs1 < rt1);
        end
        Ge: begin
            isTaken=signedGE(rs1, rt1); // Built-in signed comparison
        end
        Geu: begin
            isTaken=(rs1 >= rt1);
        end
        JAL: begin
            isTaken=True;
        end
        JALR: begin
            isTaken=True;
        end
        default: begin
            isTaken=False;
        end
    endcase
    return isTaken;
endfunction

rule tick;
    case(brFunc)
        Eq: begin
            taken<=(rs == rt);
            target<=0;
        end
        Neq: begin
            taken<=(rs != rt);
            target<=0;
        end
        Lt: begin
            taken<=signedLT(rs, rt); // Built-in signed comparison
            target<=0;
        end
        Ltu: begin
            taken<=(rs < rt);
            target<=0;
        end
        Ge: begin
            taken<=signedGE(rs, rt); // Built-in signed comparison
            target<=0;
        end
        Geu: begin
            taken<=(rs >= rt);
            target<=0;
        end
        JAL: begin
            taken<=True;
            target<=rs;
        end
        JALR: begin
            taken<=True;
            target<=fastAdd#(32)(rs, immI,0);
        end
        default: begin
            taken<=False;
            target<=0;
        end
    endcase
endrule

endmodule

