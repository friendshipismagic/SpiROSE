module spi_iff(
    input  nrst,
    input  clk,

    input  spi_clk,
    input  spi_ss,
    input  spi_mosi,
    output spi_miso,

    output [55:0] cmd_read,
    input  [47:0] cmd_write,

    output valid
);

logic [55:0] in_reg;
logic [55:0] out_reg;

logic sync_mosi, sync_sck, sync_ss;
logic last_sck, last_ss;
logic posedge_sck, posedge_ss, negedge_ss;

assign posedge_sck = ~last_sck & sync_sck;
assign posedge_ss = ~last_ss & sync_ss;
assign negedge_ss = last_ss & ~sync_ss;

/*
* Synchronize input signal from SPI
*/
sync_sig sync_sig_mosi (
    .clk(clk),
    .nrst(nrst),
    .in_sig(spi_mosi),
    .out_sig(sync_mosi)
);

sync_sig sync_sig_clk (
    .clk(clk),
    .nrst(nrst),
    .in_sig(spi_clk),
    .out_sig(sync_sck)
);

sync_sig sync_sig_ss (
    .clk(clk),
    .nrst(nrst),
    .in_sig(spi_ss),
    .out_sig(sync_ss)
);

/*
*  Synchronize last sck state to detect posedge
*/
always @(posedge clk or negedge nrst)
    if(~nrst) begin 
        last_sck <= '0;
    end else begin
        last_sck <= sync_sck;
    end

/*
*  Synchronize last ss state to detect edges
*/
always @(posedge clk or negedge nrst)
    if(~nrst) begin 
        last_ss <= '0;
    end else begin
        last_ss <= sync_ss;
    end

/*
*  Read mosi each time a clock is detected
*/
always @(posedge clk or negedge nrst)
    if(~nrst) begin
        in_reg <= '0;
    end else begin
        if(~sync_ss && posedge_sck) begin
            in_reg <= { in_reg[54:0], sync_mosi };
        end
        if(negedge_ss) begin
            in_reg <= '0;
        end
    end

/*
*  Shift register to master each time a clock is detected
*/
always @(posedge clk or negedge nrst)
    if(~nrst) begin
        out_reg <= '0;
    end else begin
        if(posedge_ss) begin
            out_reg <= cmd_write;
        end else if (negedge_ss) begin
            out_reg <= '0;
        end else if (posedge_sck) begin
            out_reg <= { out_reg[46:0], 1'b0 };
        end
    end

/*
*  Save our data when ss is lost
*/
always @(posedge clk or negedge nrst)
    if(~nrst) begin
        cmd_read <= '0;
    end else if (posedge_ss) begin
        cmd_read <= in_reg;
    end

endmodule
