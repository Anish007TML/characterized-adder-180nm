// =====================================================================
// adder_cells.v -- Verilog models of the transistor cells, with delays
// back-annotated from T-Spice characterization (rtl/fa_timing.vh).
//
// The logic equations match the transistor networks in
// spice/fa_mirror28.sp, so the gate model and the silicon agree.
// Delays live in specify blocks: Icarus needs -gspecify; ModelSim and
// other simulators honour specify blocks by default.
// =====================================================================
`include "fa_timing.vh"

// 28T mirror full adder: true outputs co, s
module fa_mirror28 (input a, b, ci, output co, s);
    wire cob = ~((a & b) | (ci & (a | b)));          // carry stage
    wire sb  = ~((a & b & ci) | (cob & (a | b | ci))); // sum stage reuses cob
    assign co = ~cob;
    assign s  = ~sb;
    specify
        (ci => co) = (`T_FA_CO_R, `T_FA_CO_F);
        (a  => co) = (`T_FA_CO_R, `T_FA_CO_F);  // simplification: a/b arcs
        (b  => co) = (`T_FA_CO_R, `T_FA_CO_F);  // take the ci numbers
        (ci => s)  = (`T_FA_S_R,  `T_FA_S_F);
        (a  => s)  = (`T_FA_S_R,  `T_FA_S_F);
        (b  => s)  = (`T_FA_S_R,  `T_FA_S_F);
    endspecify
endmodule

// 24T core only: inverted outputs cob = ~co, sb = ~s
module fa_core24 (input a, b, ci, output cob, sb);
    assign cob = ~((a & b) | (ci & (a | b)));
    assign sb  = ~((a & b & ci) | (cob & (a | b | ci)));
    specify
        (ci => cob) = (`T_CORE_CO_R, `T_CORE_CO_F);
        (a  => cob) = (`T_CORE_CO_R, `T_CORE_CO_F);
        (b  => cob) = (`T_CORE_CO_R, `T_CORE_CO_F);
        (ci => sb)  = (`T_CORE_S_R,  `T_CORE_S_F);
        (a  => sb)  = (`T_CORE_S_R,  `T_CORE_S_F);
        (b  => sb)  = (`T_CORE_S_R,  `T_CORE_S_F);
    endspecify
endmodule

module inv_cell (input in, output out);
    assign out = ~in;
    specify
        (in => out) = (`T_INV_R, `T_INV_F);
    endspecify
endmodule

// Transmission-gate 2:1 mux: y = sel ? d1 : d0
module mux2_tg (input d0, d1, sel, output y);
    assign y = sel ? d1 : d0;
    specify
        (sel => y) = (`T_MUX_R, `T_MUX_F);
        (d0  => y) = (`T_MUX_R, `T_MUX_F);
        (d1  => y) = (`T_MUX_R, `T_MUX_F);
    endspecify
endmodule
