module datapath #(
    parameter WIDTH = 8,
    parameter REGBITS = 3
) (
    input                               clk                        ,
    input                               reset                      ,
    output             [WIDTH-1:0]      addr                       ,//exmemory interface
    output             [WIDTH-1:0]      writedata                  ,
    input              [WIDTH-1:0]      memdata                    ,
    output             [  31:0]         instr                      ,// instr_in interface
    output                              zero                       ,// pc interface
    input                               pcen                       ,
    input              [   1:0]         pcsrc                      ,
    input                               iord                       ,
    input              [   3:0]         irwrite                    ,// mem_reg interface
    input                               regdst                     ,
    input                               memtoreg                   ,
    input                               regwrite                   ,// alu interface
    input                               alusrca                    ,
    input              [   1:0]         alusrcb                    ,
    input              [   2:0]         alucontrol                  
);

wire                   [WIDTH-1:0]      pc, pcnext                 ;
wire                   [WIDTH-1:0]      data                       ;
wire                   [WIDTH-1:0]      rd1, rd2, rd1_lc, rd2_lc   ;
wire                   [REGBITS-1:0]    ra1, ra2, ra3              ;
wire                   [WIDTH-1:0]      rw3                        ;
wire                   [WIDTH-1:0]      srca, srcb                 ;
wire                   [WIDTH-1:0]      aluresult, aluout          ;
wire                   [WIDTH-1:0]      imm, immx4                 ;

assign writedata = rd2_lc;

assign imm = instr[WIDTH-1:0];
assign immx4 = {instr[WIDTH-3:0], 2'b00};

flopenr #(WIDTH) pc_ff(.clk(clk), .reset(reset), .en(pcen), .d_in(pcnext), .d_out(pc));

mux2 #(WIDTH)   addr_s(.s(iord), .d0(pc), .d1(aluout), .y(addr));

flopen #(WIDTH) ir0_ff(.clk(clk), .en(irwrite[0]), .d_in(memdata), .d_out(instr[7:0]));
flopen #(WIDTH) ir1_ff(.clk(clk), .en(irwrite[1]), .d_in(memdata), .d_out(instr[15:8]));
flopen #(WIDTH) ir2_ff(.clk(clk), .en(irwrite[2]), .d_in(memdata), .d_out(instr[23:16]));
flopen #(WIDTH) ir3_ff(.clk(clk), .en(irwrite[3]), .d_in(memdata), .d_out(instr[31:24]));

//flop #(WIDTH) data_ff(.clk(clk), .d_in(memdata), .d_out(data));
assign data = memdata;

mux2 #(REGBITS) ra3_s(.s(regdst), .d0(instr[REGBITS+15:16]),.d1(instr[REGBITS+10:11]), .y(ra3));
mux2 #(WIDTH) rw3_s(.s(memtoreg), .d0(aluout), .d1(data), .y(rw3));

flop #(WIDTH) rd1_ff(.clk(clk), .d_in(rd1), .d_out(rd1_lc)); 
flop #(WIDTH) rd2_ff(.clk(clk), .d_in(rd2), .d_out(rd2_lc));

mux2 #(WIDTH) srca_s(.s(alusrca), .d0(pc), .d1(rd1_lc), .y(srca));
mux4 #(WIDTH) srcb_s(.s(alusrcb), .d0(rd2_lc), .d1(1), .d2(imm), .d3(immx4), .y(srcb));

flop #(WIDTH) aluout_ff(.clk(clk), .d_in(aluresult), .d_out(aluout)); 

mux3 #(WIDTH) pcnext_s(.s(pcsrc), .d0(aluresult), .d1(aluout), .d2(immx4), .y(pcnext));

assign ra1 = instr[REGBITS+20:21];
assign ra2 = instr[REGBITS+15:16];
regfile #(WIDTH, REGBITS) regfile_unit(
    .clk(clk),
    .a1(ra1),
    .a2(ra2),
    .a3(ra3),
    .we3(regwrite),
    .wd3(rw3),
    .rd1(rd1),
    .rd2(rd2)
);

alu #(WIDTH) alu_unit(
    .ctl(alucontrol),
    .a(srca),
    .b(srcb),
    .zero(zero),
    .out(aluresult)
);
    
endmodule

module flop #(
    parameter                           WIDTH = 8                   
) (
    input                               clk                        ,
    input              [WIDTH-1:0]      d_in                       ,
    output reg         [WIDTH-1:0]      d_out                       
);

always @(posedge clk) d_out <= d_in;

endmodule

module flopen #(
    parameter                           WIDTH = 8                   
) (
    input                               clk                        ,
    input                               en                         ,
    input              [WIDTH-1:0]      d_in                       ,
    output reg         [WIDTH-1:0]      d_out                       
);

always @(posedge clk) begin
    if (en) d_out <= d_in;
end
    
endmodule

module flopenr #(
    parameter                           WIDTH = 8                   
) (
    input                               clk                        ,
    input                               reset                      ,
    input                               en                         ,
    input              [WIDTH-1:0]      d_in                       ,
    output reg         [WIDTH-1:0]      d_out                       
);

always @(posedge clk) begin
    if (reset) d_out <= 0;
    else if(en) d_out <= d_in;
end
    
endmodule

module mux2 #(
    parameter                           WIDTH = 8                   
) (
    input                               s                          ,
    input              [WIDTH-1:0]      d0                         ,
    input              [WIDTH-1:0]      d1                         ,
    output             [WIDTH-1:0]      y                           
);

assign y =     s? d1:d0;
    
endmodule

module mux3 #(
    parameter                           WIDTH = 8                   
) (
    input              [   1:0]         s                          ,
    input              [WIDTH-1:0]      d0                         ,
    input              [WIDTH-1:0]      d1                         ,
    input              [WIDTH-1:0]      d2                         ,
    output reg         [WIDTH-1:0]      y                           
);

always @(*) begin
    casez (s)
        2'b00: y = d0;
        2'b01: y = d1;
        2'b1?: y = d2;
    endcase
end

endmodule

module mux4 #(
    parameter                           WIDTH = 8                   
) (
    input              [   1:0]         s                          ,
    input              [WIDTH-1:0]      d0                         ,
    input              [WIDTH-1:0]      d1                         ,
    input              [WIDTH-1:0]      d2                         ,
    input              [WIDTH-1:0]      d3                         ,
    output reg         [WIDTH-1:0]      y                           
);

always @(*) begin
    case (s)
        2'b00: y = d0;
        2'b01: y = d1;
        2'b10: y = d2;
        2'b11: y = d3;
    endcase
end
    
endmodule

module regfile #(
    parameter                           WIDTH = 8                  ,
    parameter                           REGBITS = 3                 
) (
    input                               clk                        ,
    input              [REGBITS-1:0]    a1                         ,
    input              [REGBITS-1:0]    a2                         ,
    input              [REGBITS-1:0]    a3                         ,
    input                               we3                        ,
    input              [WIDTH-1:0]      wd3                        ,
    output             [WIDTH-1:0]      rd1                        ,
    output             [WIDTH-1:0]      rd2                         
);

reg [WIDTH-1:0] ram[2**REGBITS-1:0];

always @(posedge clk) begin
    if (we3) ram[a3] <= wd3;
end

//register 0 hardwired to 0
assign rd1 = a1? ram[a1] : 0;
assign rd2 = a2? ram[a2] : 0;

endmodule

module alu #(
    parameter                           WIDTH = 8                   
) (
    input              [   2:0]         ctl                        ,
    input              [WIDTH-1:0]      a                          ,
    input              [WIDTH-1:0]      b                          ,
    output                              zero                       ,
    output             [WIDTH-1:0]      out                         
);

wire                   [WIDTH-1:0]      result_and                 ;
wire                   [WIDTH-1:0]      result_or                  ;
wire                   [WIDTH-1:0]      result_add                 ;
wire                                    result_carry               ;
wire                   [WIDTH-1:0]      result_slt                 ;
wire                   [WIDTH-1:0]      b_coninv                   ;

assign result_and = a & b;
assign result_or = a | b;

assign b_coninv = ctl[2]? ~b : b;
assign {result_carry, result_add} = a + b_coninv + ctl[2];
assign result_slt = result_carry ? 0 : 1;

mux4 #(WIDTH) alu_result(.s(ctl[1:0]), .d0(result_and), .d1(result_or), .d2(result_add), .d3(result_slt), .y(out));

assign  zero = (out == 0) ;

endmodule