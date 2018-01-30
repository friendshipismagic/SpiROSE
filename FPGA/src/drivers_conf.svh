/*
 * Default configuration for drivers
 * This configuration is written at the beginning, after reset, and replaces the
 * default configuration given in Application Note SLVUAF0 p.11
 */

/*
 * Default stucture for drivers configuration.
 * See Application Note SLVUAF0 p.11 for details about this configuration
 */
typedef struct packed {
   bit [1:0] LODVTH;
   bit [1:0] SEL_TD0;
   bit       SEL_GDLY;
   bit       XREFRESH;
   bit       SEL_GCK_EDGE;
   bit       SEL_PCHG;
   bit       ESPWM;
   bit       LGSE3;
   bit       SEL_SCK_EDGE;
   bit [2:0] LGSE1;
   bit [8:0] CCB;
   bit [8:0] CCG;
   bit [8:0] CCR;
   bit [2:0] BC;
   bit       POKER_TRANS_MODE;
   bit [2:0] LGSE2;
} drivers_conf_t;

/*
 * Drivers configuration.
 * Change this to change boot-time configuration.
 */
localparam drivers_conf_t drivers_conf = '{
   LODVTH: 2'b01,
   SEL_TD0: 2'b01,
   SEL_GDLY: 1'b1,
   XREFRESH: 1'b1,
   SEL_GCK_EDGE: 1'b0,
   SEL_PCHG: 1'b1,
   ESPWM: 1'b1,
   LGSE3: 1'b1,
   SEL_SCK_EDGE: 1'b0,
   LGSE1: 3'b100,
   CCB: 9'b1_0000_0000,
   CCG: 9'b1_0000_0000,
   CCR: 9'b1_0000_0000,
   BC: 3'b000,
   POKER_TRANS_MODE: 1'b1,
   LGSE2: 3'b101
};

// Serialization of the configuration, used for sending the data to SIN.
wire [47:0] serialized_conf;
// TODO Use sv streaming operators like {>>{}} = ;
assign serialized_conf[1:0]   = drivers_conf.LODVTH;
assign serialized_conf[3:2]   = drivers_conf.SEL_TD0;
assign serialized_conf[4]     = drivers_conf.SEL_GDLY;
assign serialized_conf[5]     = drivers_conf.XREFRESH;
assign serialized_conf[6]     = drivers_conf.SEL_GCK_EDGE;
assign serialized_conf[7]     = drivers_conf.SEL_PCHG;
assign serialized_conf[8]     = drivers_conf.ESPWM;
assign serialized_conf[9]     = drivers_conf.LGSE3;
assign serialized_conf[10]    = drivers_conf.SEL_SCK_EDGE;
assign serialized_conf[13:11] = drivers_conf.LGSE1;
assign serialized_conf[22:14] = drivers_conf.CCB;
assign serialized_conf[31:23] = drivers_conf.CCG;
assign serialized_conf[40:32] = drivers_conf.CCR;
assign serialized_conf[43:41] = drivers_conf.BC;
assign serialized_conf[44]    = drivers_conf.POKER_TRANS_MODE;
assign serialized_conf[47:45] = drivers_conf.LGSE2;
