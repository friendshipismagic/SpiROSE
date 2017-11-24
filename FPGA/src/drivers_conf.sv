/*
 * Default configuration for drivers
 * This configuration is written at the beginning, after reset, and replaces the
 * default configuration given in Application Note SLVUAF0 p.11
 */

/*
 * Default stucture for drivers configuration.
 * See Application Note SLVUAF0 p.11 for details about this configuration
 */
typedef struct {
   logic [1:0] LODVTH,
   logic [1:0] SEL_TD0,
   logic       SEL_GDLY,
   logic       XREFRESH,
   logic       SEL_GCK_EDGE,
   logic       SEL_PCHG,
   logic       ESPWM,
   logic       LGSE3,
   logic       SEL_SCK_EDGE,
   logic [2:0] LGSE1,
   logic [8:0] CCB,
   logic [8:0] CCG,
   logic [8:0] CCR,
   logic [2:0] BC,
   logic       POKER_TRANS_MODE,
   logic [2:0] LGSE2,
} drivers_conf_t;

/*
 * Drivers configuration.
 * Change this to change boot-time configuration.
 */
drivers_conf_t drivers_conf = '{
   LODVTH: 2'b01,
   SEL_TD0: 2'b01,
   SEL_GDLY: 1'b1,
   XREFRESH: 1'b1,
   SEL_GCK_EDGE: 1'b0,
   SEL_PCHG: 1'b0,
   ESPWM: 1'b1,
   LGSE3: 1'b0,
   SEL_SCK_EDGE: 1'b0,
   LGSE1: 3'b000,
   CCB: 9'b1_0000_0000,
   CCG: 9'b1_0000_0000,
   CCR: 9'b1_0000_0000,
   BC: 3'b100,
   POKER_TRANS_MODE: 1'b1,
   LGSE2: 3'b000,
};

// Serialization of the configuration, used for sending the data to SIN.
logic [47:0] serialized_conf;
serialized_conf[1:0]   = drivers_conf.LODVTH;
serialized_conf[3:2]   = drivers_conf.SEL_TD0;
serialized_conf[4]     = drivers_conf.SEL_GDLY;
serialized_conf[5]     = drivers_conf.XREFRESH;
serialized_conf[6]     = drivers_conf.SEL_GCK_EDGE;
serialized_conf[7]     = drivers_conf.SEL_PCHG;
serialized_conf[8]     = drivers_conf.ESPWM;
serialized_conf[9]     = drivers_conf.LGSE3;
serialized_conf[10]    = drivers_conf.SEL_SCK_EDGE;
serialized_conf[13:11] = drivers_conf.LGSE1;
serialized_conf[22:14] = drivers_conf.CCB;
serialized_conf[31:23] = drivers_conf.CCG;
serialized_conf[40:32] = drivers_conf.CCR;
serialized_conf[43:41] = drivers_conf.BC;
serialized_conf[44]    = drivers_conf.POKER_TRANS_MODE;
serialized_conf[47:45] = drivers_conf.LGSE2;
