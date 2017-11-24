/*
 * Default configuration for drivers
 * This configuration is written at the beginning, after reset, and replaces the
 * default configuration given in Application Note SLVUAF0 p.11
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

drivers_conf_t drivers_default_conf = '{
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
