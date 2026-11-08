// =====================================================================
// adders.v -- three 8-bit adder architectures built from the
// characterized cells in adder_cells.v
//
//   rca8      : plain ripple carry, 8 x fa_mirror28
//   rca8_inv  : ripple carry using the full adder's INVERSION PROPERTY,
//               no inverter anywhere on the carry path
//   csa8      : carry-select, low 4 bits ripple, high 4 bits computed
//               twice (cin=0 and cin=1) and picked by a mux
// =====================================================================

// ---------------------------------------------------------------------
// Generic N-bit ripple of fa_mirror28 cells (used by rca8 and csa8)
// ---------------------------------------------------------------------
module rca_n #(parameter N = 4) (
    input  [N-1:0] a, b,
    input          cin,
    output [N-1:0] sum,
    output         cout
);
    wire [N:0] c;
    assign c[0] = cin;
    genvar i;
    generate
        for (i = 0; i < N; i = i + 1) begin : stage
            fa_mirror28 fa (.a(a[i]), .b(b[i]), .ci(c[i]), .co(c[i+1]), .s(sum[i]));
        end
    endgenerate
    assign cout = c[N];
endmodule

module rca8 (input [7:0] a, b, input cin, output [7:0] sum, output cout);
    rca_n #(8) u (.a(a), .b(b), .cin(cin), .sum(sum), .cout(cout));
endmodule

// ---------------------------------------------------------------------
// Inversion property:  FA(~a, ~b, ~c) = ~FA(a, b, c)  (for both s and co)
//
// Even stages get true inputs and produce cob = ~carry  (no inverter).
// Odd stages receive that INVERTED carry, so they are fed ~a, ~b too;
// their 'inverted' outputs then come out with TRUE polarity.
// Inverters move from the carry path onto a/b and the even-stage sums,
// which are not on the critical path (a and b are ready at t = 0).
// ---------------------------------------------------------------------
module rca8_inv (input [7:0] a, b, input cin, output [7:0] sum, output cout);
    wire [8:0] c;        // c[i] = carry INTO stage i; inverted on odd i
    assign c[0] = cin;
    genvar i;
    generate
        for (i = 0; i < 8; i = i + 1) begin : stage
            if (i % 2 == 0) begin : even
                wire sb;
                fa_core24 fa (.a(a[i]), .b(b[i]), .ci(c[i]), .cob(c[i+1]), .sb(sb));
                inv_cell  is (.in(sb), .out(sum[i]));          // restore sum
            end else begin : odd
                wire an, bn;
                inv_cell  ia (.in(a[i]), .out(an));             // off critical path
                inv_cell  ib (.in(b[i]), .out(bn));
                fa_core24 fa (.a(an), .b(bn), .ci(c[i]), .cob(c[i+1]), .sb(sum[i]));
            end
        end
    endgenerate
    assign cout = c[8];  // stage 7 is odd -> true polarity
endmodule

// ---------------------------------------------------------------------
// Carry-select: delay ~ 4 x t(ci->co) + t(mux) instead of 8 x t(ci->co)
// Cost: an extra 4-bit adder + 5 muxes (area and power)
// ---------------------------------------------------------------------
module csa8 (input [7:0] a, b, input cin, output [7:0] sum, output cout);
    wire       c4;
    wire [3:0] s_hi0, s_hi1;
    wire       c_hi0, c_hi1;

    rca_n #(4) lo  (.a(a[3:0]), .b(b[3:0]), .cin(cin),  .sum(sum[3:0]), .cout(c4));
    rca_n #(4) hi0 (.a(a[7:4]), .b(b[7:4]), .cin(1'b0), .sum(s_hi0),   .cout(c_hi0));
    rca_n #(4) hi1 (.a(a[7:4]), .b(b[7:4]), .cin(1'b1), .sum(s_hi1),   .cout(c_hi1));

    genvar i;
    generate
        for (i = 0; i < 4; i = i + 1) begin : smux
            mux2_tg m (.d0(s_hi0[i]), .d1(s_hi1[i]), .sel(c4), .y(sum[4+i]));
        end
    endgenerate
    mux2_tg mc (.d0(c_hi0), .d1(c_hi1), .sel(c4), .y(cout));
endmodule
