// Stub module to be able to lint ram.v

/* verilator lint_off UNUSED */
module ram (
    input         clock,
    input  [23:0] data,
    input   [6:0] rdaddress,
    input   [6:0] wraddress,
    input         wren,
    output [23:0] q
);

endmodule
