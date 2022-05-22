`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2021/10/24 22:05:19
// Design Name: 
// Module Name: tb_mips
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module tb_mips #(
    parameter WIDTH = 8,
    parameter REGBITS = 3
)();
reg                     clk;
reg                     reset;
wire                    memwrite;
wire    [WIDTH-1:0]     addr;
wire    [WIDTH-1:0]     writedata;
wire    [WIDTH-1:0]     memdata;

mips #(
    .WIDTH   ( WIDTH ),
    .REGBITS ( REGBITS ))
 u_mips (
    .clk                     ( clk         ),
    .reset                   ( reset       ),
    .memdata                 ( memdata     ),
    .memwrite                ( memwrite    ),
    .addr                    ( addr        ),
    .writedata               ( writedata   )
);

exmemory #(
    .WIDTH ( WIDTH ))
 u_exmemory (
    .clk                     ( clk         ),
    .memwrite                ( memwrite    ),
    .addr                    ( addr        ),
    .writedata               ( writedata   ),
    .memdata                 ( memdata     )
);

initial begin
    $display($time, " << Starting the Simulation >>");
    reset <= 1;
    clk <= 0;
    #22 reset <= 0;
end

always #5 clk <= ~clk; 

always @(negedge clk) begin
    if(memwrite) begin
        if(addr == 76 & writedata == 7)
        $display("Simulation completely successful");
    end
end

endmodule

module exmemory #(
    parameter                           WIDTH = 8                   
) (
    input                               clk                        ,
    input                               memwrite                   ,
    input              [WIDTH-1:0]      addr                       ,
    input              [WIDTH-1:0]      writedata                  ,
    output reg         [WIDTH-1:0]      memdata                     
);
 
reg                    [31:0]           mem[2**(WIDTH-2)-1:0]      ;
wire                   [  31:0]         word                       ;
wire                   [   1:0]         bytesel                    ;
wire                   [WIDTH-1:2]      wordaddr                   ;

// for testbench
initial
    $readmemh("memfile.dat", mem);

assign wordaddr = addr[WIDTH-1:2];
assign bytesel = addr[1:0];

// read and write bytes from 32-bit word
always @(posedge clk) begin
    if(memwrite) begin
        case (bytesel)
            2'b00: mem[wordaddr][7:0] <= writedata;
            2'b01: mem[wordaddr][15:8] <= writedata;
            2'b10: mem[wordaddr][23:16] <= writedata;
            2'b11: mem[wordaddr][31:24] <= writedata;
        endcase
    end
end

assign word = mem[wordaddr];

always @(*) begin
    case (bytesel)
        2'b00: memdata = word[7:0];
        2'b01: memdata = word[15:8];
        2'b10: memdata = word[23:16];
        2'b11: memdata = word[31:24];
    endcase
end

endmodule
