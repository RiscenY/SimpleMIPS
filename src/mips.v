module mips #(
    parameter                           WIDTH = 8                  ,
    parameter                           REGBITS = 3                 
) (
    input                               clk                        ,
    input                               reset                      ,
    input              [WIDTH-1:0]      memdata                    ,
    output                              memwrite                   ,
    output             [WIDTH-1:0]      addr                       ,
    output             [WIDTH-1:0]      writedata                   
);
    
wire                   [  31:0]         instr                      ;
// signals from datapath to Control Unit
wire                   [   5:0]         op, funct                  ;
wire                                    zero                       ;
//signals from Control Unit to datapath
wire                                    pcen, iord, regdst, memtoreg, regwrite, alusrca;
wire                   [   3:0]         irwrite                    ;
wire                   [   1:0]         alusrcb                    ;
wire                   [   2:0]         alucontrol                 ;
wire                   [   1:0]         pcsrc                      ;

assign op = instr[31:26];
assign funct = instr[5:0];

controller cont(clk, reset, op, funct, zero,
                pcen, pcsrc, iord, memwrite,
                irwrite, regdst, memtoreg, regwrite,
                alusrca, alusrcb, alucontrol );

datapath #(WIDTH, REGBITS) 
            dp(clk, reset, addr, writedata, memdata,
                instr, zero,
                pcen, pcsrc, iord,
                irwrite, regdst, memtoreg, regwrite,
                alusrca, alusrcb, alucontrol);

endmodule