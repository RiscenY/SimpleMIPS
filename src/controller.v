module controller (
    input                               clk                        ,
    input                               reset                      ,
    input              [   5:0]         op                         ,// instr_in interface
    input              [   5:0]         funct                      ,
    input                               zero                       ,// pc interface
    output wire                         pcen                       ,
    output reg         [   1:0]         pcsrc                      ,
    output reg                          iord                       ,
    output reg                          memwrite                   ,// mem_reg interface
    output reg         [   3:0]         irwrite                    ,
    output reg                          regdst                     ,
    output reg                          memtoreg                   ,
    output reg                          regwrite                   ,// alu interface
    output reg                          alusrca                    ,
    output reg         [   1:0]         alusrcb                    ,
    output reg         [   2:0]         alucontrol                  
);

reg                                     pcwrite, branch            ;
reg                    [   1:0]         aluop                      ;

assign pcen = pcwrite|(branch&zero);

//****** define op 
localparam                              LB = 6'b100000             ;
localparam                              SB = 6'b101000             ;
localparam                              RTYPE = 6'b000000          ;
localparam                              BEQ = 6'b000100            ;
localparam                              ADDI = 6'b001000           ;
localparam                              J = 6'b000010              ;

//****** output logic, determined by state machine
localparam                              FETCH0 = 4'b0000           ;
localparam                              FETCH1 = 4'b0001           ;
localparam                              FETCH2 = 4'b0011           ;
localparam                              FETCH3 = 4'b0010           ;
localparam                              DECODE = 4'b0110           ;
localparam                              MEMADDR = 4'b0111          ;
localparam                              EXE = 4'b0101              ;
localparam                              EXEI = 4'b0100             ;
localparam                              BRACOM = 4'b1100           ;
localparam                              JUMCOM = 4'b1101           ;
localparam                              MEMLB = 4'b1111            ;
localparam                              MEMSB = 4'b1110            ;
localparam                              EXECOM = 4'b1010           ;
localparam                              EXEICOM = 4'b1011          ;
//localparam                              WRIBCK = 4'b1001           ;

reg                    [   3:0]         state                      ;
reg                    [   3:0]         nextstate                  ;

//paragraph 1: state jump sequence logic
always @(posedge clk or posedge reset) begin
    if (reset) begin
        state <= FETCH0;
    end
    else begin
        state <= nextstate;
    end
end
//paragraph 2: next state combination logic
always @(*) begin
    case (state)
        FETCH0: nextstate = FETCH1;
        FETCH1: nextstate = FETCH2;
        FETCH2: nextstate = FETCH3;
        FETCH3: nextstate = DECODE;
        DECODE: case (op)
            LB:     nextstate = MEMADDR;
            SB:     nextstate = MEMADDR;
            RTYPE:  nextstate = EXE;
            ADDI:   nextstate = EXEI;
            BEQ:    nextstate = BRACOM;
            J:      nextstate = JUMCOM;
            default: nextstate = FETCH0;                            // should never happen
        endcase
        MEMADDR: case (op)
            LB:     nextstate = MEMLB;
            SB:     nextstate = MEMSB;
            default: nextstate = FETCH0;                            //should never happen
        endcase
        EXE: nextstate = EXECOM;
        EXEI: nextstate = EXEICOM;
        BRACOM: nextstate = FETCH0;
        JUMCOM: nextstate = FETCH0;
        MEMLB: nextstate = FETCH0;
        MEMSB: nextstate = FETCH0;
        EXECOM:  nextstate = FETCH0;
        EXEICOM: nextstate = FETCH0;
//        WRIBCK: nextstate = FETCH0;
        default: nextstate = FETCH0;
    endcase
end
//paragraph 3: output sequence logic
always @(posedge clk or posedge reset) begin
    if (reset) begin
        pcwrite <= 1'b1;
        branch <= 1'b0;
        pcsrc <= 2'b00;
        iord <= 1'b0;
        memwrite <= 1'b0;
        irwrite <= 4'b0001;
        regdst <= 1'b0;
        memtoreg <= 1'b0;
        regwrite <= 1'b0;
        alusrca <= 1'b0;
        alusrcb <= 2'b01;
        aluop <= 2'b0;
    end
    else begin
        case (nextstate)
            FETCH0: begin
                pcwrite <= 1'b1;
                branch <= 1'b0;
                pcsrc <= 2'b00;
                iord <= 1'b0;
                memwrite <= 1'b0;
                irwrite <= 4'b0001;
                regdst <= 1'b0;
                memtoreg <= 1'b0;
                regwrite <= 1'b0;
                alusrca <= 1'b0;
                alusrcb <= 2'b01;
                aluop <= 2'b0;
            end
            FETCH1: begin
                pcwrite <= 1'b1;
                alusrcb <= 2'b01;
                irwrite <= 4'b0010;                
            end
            FETCH2: begin
                pcwrite <= 1'b1;
                alusrcb <= 2'b01;
                irwrite <= 4'b0100;
            end
            FETCH3: begin
                pcwrite <= 1'b1;
                alusrcb <= 2'b01;
                irwrite <= 4'b1000;
            end
            DECODE: begin
                pcwrite <= 1'b0;
                irwrite <= 4'b0000;
                alusrcb <= 2'b11;
            end
            MEMADDR:begin
                alusrca <= 1'b1;
                alusrcb <= 2'b10;
                iord <= 1'b1;
            end
            EXE:begin
                alusrca <= 1'b1;
                alusrcb <= 2'b00;
                aluop <= 2'b10;
            end
            EXEI:begin
                alusrca <= 1'b1;
                alusrcb <= 2'b10;
                aluop <= 2'b00;
            end
            BRACOM: begin
                alusrca <= 1'b1;
                alusrcb <= 2'b00;
                aluop <= 2'b01;
                branch <= 1'b1;
                pcsrc <= 2'b01;
            end
            JUMCOM: begin
                pcsrc <= 2'b10;
                pcwrite <= 1'b1;
            end
            MEMLB:begin
                regwrite <= 1'b1;
                memtoreg <= 1'b1;
                regdst <= 1'b0;
            end
            MEMSB:begin
                memwrite <= 1'b1;
            end
            EXECOM:begin
                regdst <= 1'b1;
                regwrite <= 1'b1;
                memtoreg <= 1'b0;
            end
            EXEICOM:begin
                regdst <= 1'b0;
                regwrite <= 1'b1;
                memtoreg <= 1'b0;
            end
 //           WRIBCK:;
            default: begin
                pcwrite <= 1'b1;
                branch <= 1'b0;
                pcsrc <= 2'b00;
                iord <= 1'b0;
                memwrite <= 1'b0;
                irwrite <= 4'b0001;
                regdst <= 1'b0;
                memtoreg <= 1'b0;
                regwrite <= 1'b0;
                alusrca <= 1'b0;
                alusrcb <= 2'b01;
                aluop <= 2'b0;
            end
        endcase
    end
    
end

//****** ALU decode/control logic
localparam                              ADD = 3'b010               ;
localparam                              SUB = 3'b110               ;
localparam                              AND = 3'b000               ;
localparam                              OR = 3'b001                ;
localparam                              SLT = 3'b111               ;

always @(*) begin
   case (aluop)
       2'b00: alucontrol = ADD;
       2'b01: alucontrol = SUB;
       2'b10: begin
           case(funct)
                6'b100000: alucontrol = ADD;
                6'b100010: alucontrol = SUB;
                6'b100100: alucontrol = AND;
                6'b100101: alucontrol = OR;
                6'b101010: alucontrol = SLT;
                default: alucontrol = ADD;
           endcase
       end
       default: alucontrol = ADD;
   endcase
end

    
endmodule
