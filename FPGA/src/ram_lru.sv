module ram_lru (
    input clk,
    input nrst,

    // Video stream input
    input [31:0] write_addr,
    input [23:0] write_data,
    input write_enab,

    // Ram access
    input  [31:0] ub0d0_ram_addr,
    input  [31:0] ub0d1_ram_addr,
    input  [31:0] ub0d2_ram_addr,
    input  [31:0] ub1d0_ram_addr,
    input  [31:0] ub1d1_ram_addr,
    input  [31:0] ub1d2_ram_addr,
    input  [31:0] ub2d0_ram_addr,
    input  [31:0] ub2d1_ram_addr,
    input  [31:0] ub2d2_ram_addr,
    input  [31:0] ub3d0_ram_addr,
    input  [31:0] ub3d1_ram_addr,
    input  [31:0] ub3d2_ram_addr,
    input  [31:0] ub4d0_ram_addr,
    input  [31:0] ub4d1_ram_addr,
    input  [31:0] ub4d2_ram_addr,

    output [23:0] ub0d0_ram_data,
    output [23:0] ub0d1_ram_data,
    output [23:0] ub0d2_ram_data,
    output [23:0] ub1d0_ram_data,
    output [23:0] ub1d1_ram_data,
    output [23:0] ub1d2_ram_data,
    output [23:0] ub2d0_ram_data,
    output [23:0] ub2d1_ram_data,
    output [23:0] ub2d2_ram_data,
    output [23:0] ub3d0_ram_data,
    output [23:0] ub3d1_ram_data,
    output [23:0] ub3d2_ram_data,
    output [23:0] ub4d0_ram_data,
    output [23:0] ub4d1_ram_data,
    output [23:0] ub4d2_ram_data,
);

// Internal RAM signals
logic [23:0] ub0d0_internal_ram_data [2:0];
logic [23:0] ub0d1_internal_ram_data [2:0];
logic [23:0] ub0d2_internal_ram_data [2:0];
logic [23:0] ub1d0_internal_ram_data [2:0];
logic [23:0] ub1d1_internal_ram_data [2:0];
logic [23:0] ub1d2_internal_ram_data [2:0];
logic [23:0] ub2d0_internal_ram_data [2:0];
logic [23:0] ub2d1_internal_ram_data [2:0];
logic [23:0] ub2d2_internal_ram_data [2:0];
logic [23:0] ub3d0_internal_ram_data [2:0];
logic [23:0] ub3d1_internal_ram_data [2:0];
logic [23:0] ub3d2_internal_ram_data [2:0];
logic [23:0] ub4d0_internal_ram_data [2:0];
logic [23:0] ub4d1_internal_ram_data [2:0];
logic [23:0] ub4d2_internal_ram_data [2:0];
logic        ub0d0_internal_ram_write_enab [2:0];
logic        ub0d1_internal_ram_write_enab [2:0];
logic        ub0d1_internal_ram_write_enab [2:0];
logic        ub1d0_internal_ram_write_enab [2:0];
logic        ub1d1_internal_ram_write_enab [2:0];
logic        ub1d2_internal_ram_write_enab [2:0];
logic        ub2d0_internal_ram_write_enab [2:0];
logic        ub2d1_internal_ram_write_enab [2:0];
logic        ub2d2_internal_ram_write_enab [2:0];
logic        ub3d0_internal_ram_write_enab [2:0];
logic        ub3d1_internal_ram_write_enab [2:0];
logic        ub3d2_internal_ram_write_enab [2:0];
logic        ub4d0_internal_ram_write_enab [2:0];
logic        ub4d1_internal_ram_write_enab [2:0];
logic        ub4d2_internal_ram_write_enab [2:0];

// RAM blocks instanciation 
ram ub0d0_ram0 (.clock(clk),
   .data(write_data), .wraddress(write_addr), .wren(ub0d0_internal_ram_write_enab[0]),
   .q(ub0d0_internal_ram_data[0]), .rdaddress(ub0d0_ram_addr));
ram ub0d0_ram1 (.clock(clk),
   .data(write_data), .wraddress(write_addr), .wren(ub0d0_internal_ram_write_enab[1]),
   .q(ub0d0_internal_ram_data[1]), .rdaddress(ub0d0_ram_addr));
ram ub0d0_ram2 (.clock(clk),
   .data(write_data), .wraddress(write_addr), .wren(ub0d0_internal_ram_write_enab[2]),
   .q(ub0d0_internal_ram_data[2]), .rdaddress(ub0d0_ram_addr));
ram ub0d1_ram0 (.clock(clk),
   .data(write_data), .wraddress(write_addr), .wren(ub0d1_internal_ram_write_enab[0]),
   .q(ub0d1_internal_ram_data[0]), .rdaddress(ub0d1_ram_addr));
ram ub0d1_ram1 (.clock(clk),
   .data(write_data), .wraddress(write_addr), .wren(ub0d1_internal_ram_write_enab[1]),
   .q(ub0d1_internal_ram_data[1]), .rdaddress(ub0d1_ram_addr));
ram ub0d1_ram2 (.clock(clk),
   .data(write_data), .wraddress(write_addr), .wren(ub0d1_internal_ram_write_enab[2]),
   .q(ub0d1_internal_ram_data[2]), .rdaddress(ub0d1_ram_addr));
ram ub0d2_ram0 (.clock(clk),
   .data(write_data), .wraddress(write_addr), .wren(ub0d2_internal_ram_write_enab[0]),
   .q(ub0d2_internal_ram_data[0]), .rdaddress(ub0d2_ram_addr));
ram ub0d2_ram1 (.clock(clk),
   .data(write_data), .wraddress(write_addr), .wren(ub0d2_internal_ram_write_enab[1]),
   .q(ub0d2_internal_ram_data[1]), .rdaddress(ub0d2_ram_addr));
ram ub0d2_ram2 (.clock(clk),
   .data(write_data), .wraddress(write_addr), .wren(ub0d2_internal_ram_write_enab[2]),
   .q(ub0d2_internal_ram_data[2]), .rdaddress(ub0d2_ram_addr));

ram ub1d0_ram0 (.clock(clk),
   .data(write_data), .wraddress(write_addr), .wren(ub1d0_internal_ram_write_enab[0]),
   .q(ub1d0_internal_ram_data[0]), .rdaddress(ub1d0_ram_addr));
ram ub1d0_ram1 (.clock(clk),
   .data(write_data), .wraddress(write_addr), .wren(ub1d0_internal_ram_write_enab[1]),
   .q(ub1d0_internal_ram_data[1]), .rdaddress(ub1d0_ram_addr));
ram ub1d0_ram2 (.clock(clk),
   .data(write_data), .wraddress(write_addr), .wren(ub1d0_internal_ram_write_enab[2]),
   .q(ub1d0_internal_ram_data[2]), .rdaddress(ub1d0_ram_addr));
ram ub1d1_ram0 (.clock(clk),
   .data(write_data), .wraddress(write_addr), .wren(ub1d1_internal_ram_write_enab[0]),
   .q(ub1d1_internal_ram_data[0]), .rdaddress(ub1d1_ram_addr));
ram ub1d1_ram1 (.clock(clk),
   .data(write_data), .wraddress(write_addr), .wren(ub1d1_internal_ram_write_enab[1]),
   .q(ub1d1_internal_ram_data[1]), .rdaddress(ub1d1_ram_addr));
ram ub1d1_ram2 (.clock(clk),
   .data(write_data), .wraddress(write_addr), .wren(ub1d1_internal_ram_write_enab[2]),
   .q(ub1d1_internal_ram_data[2]), .rdaddress(ub1d1_ram_addr));
ram ub1d2_ram0 (.clock(clk),
   .data(write_data), .wraddress(write_addr), .wren(ub1d2_internal_ram_write_enab[0]),
   .q(ub1d2_internal_ram_data[0]), .rdaddress(ub1d2_ram_addr));
ram ub1d2_ram1 (.clock(clk),
   .data(write_data), .wraddress(write_addr), .wren(ub1d2_internal_ram_write_enab[1]),
   .q(ub1d2_internal_ram_data[1]), .rdaddress(ub1d2_ram_addr));
ram ub1d2_ram2 (.clock(clk),
   .data(write_data), .wraddress(write_addr), .wren(ub1d2_internal_ram_write_enab[2]),
   .q(ub1d2_internal_ram_data[2]), .rdaddress(ub1d2_ram_addr));

ram ub2d0_ram0 (.clock(clk),
   .data(write_data), .wraddress(write_addr), .wren(ub2d0_internal_ram_write_enab[0]),
   .q(ub2d0_internal_ram_data[0]), .rdaddress(ub2d0_ram_addr));
ram ub2d0_ram1 (.clock(clk),
   .data(write_data), .wraddress(write_addr), .wren(ub2d0_internal_ram_write_enab[1]),
   .q(ub2d0_internal_ram_data[1]), .rdaddress(ub2d0_ram_addr));
ram ub2d0_ram2 (.clock(clk),
   .data(write_data), .wraddress(write_addr), .wren(ub2d0_internal_ram_write_enab[2]),
   .q(ub2d0_internal_ram_data[2]), .rdaddress(ub2d0_ram_addr));
ram ub2d1_ram0 (.clock(clk),
   .data(write_data), .wraddress(write_addr), .wren(ub2d1_internal_ram_write_enab[0]),
   .q(ub2d1_internal_ram_data[0]), .rdaddress(ub2d1_ram_addr));
ram ub2d1_ram1 (.clock(clk),
   .data(write_data), .wraddress(write_addr), .wren(ub2d1_internal_ram_write_enab[1]),
   .q(ub2d1_internal_ram_data[1]), .rdaddress(ub2d1_ram_addr));
ram ub2d1_ram2 (.clock(clk),
   .data(write_data), .wraddress(write_addr), .wren(ub2d1_internal_ram_write_enab[2]),
   .q(ub2d1_internal_ram_data[2]), .rdaddress(ub2d1_ram_addr));
ram ub2d2_ram0 (.clock(clk),
   .data(write_data), .wraddress(write_addr), .wren(ub2d2_internal_ram_write_enab[0]),
   .q(ub2d2_internal_ram_data[0]), .rdaddress(ub2d2_ram_addr));
ram ub2d2_ram1 (.clock(clk),
   .data(write_data), .wraddress(write_addr), .wren(ub2d2_internal_ram_write_enab[1]),
   .q(ub2d2_internal_ram_data[1]), .rdaddress(ub2d2_ram_addr));
ram ub2d2_ram2 (.clock(clk),
   .data(write_data), .wraddress(write_addr), .wren(ub2d2_internal_ram_write_enab[2]),
   .q(ub2d2_internal_ram_data[2]), .rdaddress(ub2d2_ram_addr));

ram ub3d0_ram0 (.clock(clk),
   .data(write_data), .wraddress(write_addr), .wren(ub3d0_internal_ram_write_enab[0]),
   .q(ub3d0_internal_ram_data[0]), .rdaddress(ub3d0_ram_addr));
ram ub3d0_ram1 (.clock(clk),
   .data(write_data), .wraddress(write_addr), .wren(ub3d0_internal_ram_write_enab[1]),
   .q(ub3d0_internal_ram_data[1]), .rdaddress(ub3d0_ram_addr));
ram ub3d0_ram2 (.clock(clk),
   .data(write_data), .wraddress(write_addr), .wren(ub3d0_internal_ram_write_enab[2]),
   .q(ub3d0_internal_ram_data[2]), .rdaddress(ub3d0_ram_addr));
ram ub3d1_ram0 (.clock(clk),
   .data(write_data), .wraddress(write_addr), .wren(ub3d1_internal_ram_write_enab[0]),
   .q(ub3d1_internal_ram_data[0]), .rdaddress(ub3d1_ram_addr));
ram ub3d1_ram1 (.clock(clk),
   .data(write_data), .wraddress(write_addr), .wren(ub3d1_internal_ram_write_enab[1]),
   .q(ub3d1_internal_ram_data[1]), .rdaddress(ub3d1_ram_addr));
ram ub3d1_ram2 (.clock(clk),
   .data(write_data), .wraddress(write_addr), .wren(ub3d1_internal_ram_write_enab[2]),
   .q(ub3d1_internal_ram_data[2]), .rdaddress(ub3d1_ram_addr));
ram ub3d2_ram0 (.clock(clk),
   .data(write_data), .wraddress(write_addr), .wren(ub3d2_internal_ram_write_enab[0]),
   .q(ub3d2_internal_ram_data[0]), .rdaddress(ub3d2_ram_addr));
ram ub3d2_ram1 (.clock(clk),
   .data(write_data), .wraddress(write_addr), .wren(ub3d2_internal_ram_write_enab[1]),
   .q(ub3d2_internal_ram_data[1]), .rdaddress(ub3d2_ram_addr));
ram ub3d2_ram2 (.clock(clk),
   .data(write_data), .wraddress(write_addr), .wren(ub3d2_internal_ram_write_enab[2]),
   .q(ub3d2_internal_ram_data[2]), .rdaddress(ub3d2_ram_addr));

ram ub4d0_ram0 (.clock(clk),
   .data(write_data), .wraddress(write_addr), .wren(ub4d0_internal_ram_write_enab[0]),
   .q(ub4d0_internal_ram_data[0]), .rdaddress(ub4d0_ram_addr));
ram ub4d0_ram1 (.clock(clk),
   .data(write_data), .wraddress(write_addr), .wren(ub4d0_internal_ram_write_enab[1]),
   .q(ub4d0_internal_ram_data[1]), .rdaddress(ub4d0_ram_addr));
ram ub4d0_ram2 (.clock(clk),
   .data(write_data), .wraddress(write_addr), .wren(ub4d0_internal_ram_write_enab[2]),
   .q(ub4d0_internal_ram_data[2]), .rdaddress(ub4d0_ram_addr));
ram ub4d1_ram0 (.clock(clk),
   .data(write_data), .wraddress(write_addr), .wren(ub4d1_internal_ram_write_enab[0]),
   .q(ub4d1_internal_ram_data[0]), .rdaddress(ub4d1_ram_addr));
ram ub4d1_ram1 (.clock(clk),
   .data(write_data), .wraddress(write_addr), .wren(ub4d1_internal_ram_write_enab[1]),
   .q(ub4d1_internal_ram_data[1]), .rdaddress(ub4d1_ram_addr));
ram ub4d1_ram2 (.clock(clk),
   .data(write_data), .wraddress(write_addr), .wren(ub4d1_internal_ram_write_enab[2]),
   .q(ub4d1_internal_ram_data[2]), .rdaddress(ub4d1_ram_addr));
ram ub4d2_ram0 (.clock(clk),
   .data(write_data), .wraddress(write_addr), .wren(ub4d2_internal_ram_write_enab[0]),
   .q(ub4d2_internal_ram_data[0]), .rdaddress(ub4d2_ram_addr));
ram ub4d2_ram1 (.clock(clk),
   .data(write_data), .wraddress(write_addr), .wren(ub4d2_internal_ram_write_enab[1]),
   .q(ub4d2_internal_ram_data[1]), .rdaddress(ub4d2_ram_addr));
ram ub4d2_ram2 (.clock(clk),
   .data(write_data), .wraddress(write_addr), .wren(ub4d2_internal_ram_write_enab[2]),
   .q(ub4d2_internal_ram_data[2]), .rdaddress(ub4d2_ram_addr));

endmodule
