`default_nettype none
module ram_lru (
                input logic         clk,
                input logic         nrst,

                // Video stream input
                input logic [6:0]   write_addr,
                input logic [23:0]  write_data,
                input logic         write_ena,
                input logic         write_eof,

                // Ram access
                input logic [6:0]   read_addr,
                output logic [23:0] read_data,
                input logic         read_eof,

                // Whether to bypass the whole LRU thing
                input logic         bypass_lru
                );

   // MUX signals to discriminate the read and write ram. Those two should always
   // be different
   logic [1:0]                      write_ram;
   logic [1:0]                      read_ram;
   // This is the next ram to use (i.e. the least recently used)
   logic [1:0]                      free_ram;

   // Internal RAM signals
   wire                             internal_write_ena [2:0];
   wire [23:0]                      internal_read_data [2:0];

   // Route signals to the proper RAMs
   assign read_data = internal_read_data[bypass_lru ? write_ram : read_ram];
   assign internal_write_ena[0] = write_ena & (write_ram == 0);
   assign internal_write_ena[1] = write_ena & (write_ram == 1);
   assign internal_write_ena[2] = write_ena & (write_ram == 2);

   // RAM blocks instanciation
   ram ram0 (
             .clock(clk),
             .wren(internal_write_ena[0]),
             .data(write_data), .wraddress(write_addr),
             .q(internal_read_data[0]), .rdaddress(read_addr)
             );
   ram ram1 (
             .clock(clk),
             .wren(internal_write_ena[1]),
             .data(write_data), .wraddress(write_addr),
             .q(internal_read_data[1]), .rdaddress(read_addr)
             );
   ram ram2 (
             .clock(clk),
             .wren(internal_write_ena[2]),
             .data(write_data), .wraddress(write_addr),
             .q(internal_read_data[2]), .rdaddress(read_addr)
             );

   // RAM switching logic
   logic                            read_eof_r, write_eof_r;
   always_ff @(posedge clk or negedge nrst)
     if (~nrst) begin
        write_ram <= 0;
        read_ram <= 1;
        free_ram <= 2;
        read_eof_r <= 0;
        write_eof_r <= 0;
     end else begin
        read_eof_r <= read_eof;
        write_eof_r <= write_eof;

        if (~read_eof_r && read_eof && ~write_eof_r && write_eof) begin
           // When both finished at the same time, the free RAM is outdated.o
           // Thus, we only need to swap the read and write RAM
           read_ram <= write_ram;
           write_ram <= read_ram;
        end else if (~read_eof_r && read_eof) begin
           // Swap free buffer and read buffer
           read_ram <= free_ram;
           free_ram <= read_ram;
        end else if (~write_eof_r && write_eof) begin
           // Swap free buffer and write buffer
           write_ram <= free_ram;
           free_ram <= write_ram;
        end
     end

endmodule
