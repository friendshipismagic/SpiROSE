module ram_lru (
    input clk,
    input nrst,

    // Video stream input
    input write_addr,
    input write_data,
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

    output [15:0] ub0d0_ram_data,
    output [15:0] ub0d1_ram_data,
    output [15:0] ub0d2_ram_data,
    output [15:0] ub1d0_ram_data,
    output [15:0] ub1d1_ram_data,
    output [15:0] ub1d2_ram_data,
    output [15:0] ub2d0_ram_data,
    output [15:0] ub2d1_ram_data,
    output [15:0] ub2d2_ram_data,
    output [15:0] ub3d0_ram_data,
    output [15:0] ub3d1_ram_data,
    output [15:0] ub3d2_ram_data,
    output [15:0] ub4d0_ram_data,
    output [15:0] ub4d1_ram_data,
    output [15:0] ub4d2_ram_data,
);

endmodule
