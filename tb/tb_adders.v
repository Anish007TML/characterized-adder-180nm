// =====================================================================
// tb_adders.v -- self-checking testbench
//   Part 1: exhaustive functional check, all 2^17 = 131072 input
//           combinations, every architecture against a + b + cin.
//   Part 2: worst-case carry ripple timing with the back-annotated
//           delays: a = 8'hFF, b = 0, cin toggles, so the carry has to
//           travel through every stage.
// Run (Icarus):
//   iverilog -gspecify -I rtl -o sim tb/tb_adders.v rtl/adder_cells.v rtl/adders.v
//   vvp sim
// =====================================================================
`timescale 1ns/1ps
module tb_adders;
    reg  [7:0] a, b;
    reg        cin;
    wire [7:0] s_rca, s_inv, s_csa;
    wire       c_rca, c_inv, c_csa;

    rca8     u_rca (.a(a), .b(b), .cin(cin), .sum(s_rca), .cout(c_rca));
    rca8_inv u_inv (.a(a), .b(b), .cin(cin), .sum(s_inv), .cout(c_inv));
    csa8     u_csa (.a(a), .b(b), .cin(cin), .sum(s_csa), .cout(c_csa));

    integer i, errors;
    reg [8:0] golden;

    // ---- Part 2 helpers: time-stamp the last change of each cout ----
    realtime t0, t_rca, t_inv, t_csa;
    always @(c_rca) t_rca = $realtime;
    always @(c_inv) t_inv = $realtime;
    always @(c_csa) t_csa = $realtime;

    task carry_ripple(input new_cin, input [8*5-1:0] label);
        begin
            a = 8'hFF; b = 8'h00; cin = ~new_cin;
            #5;                                // let everything settle
            t0 = $realtime; cin = new_cin;     // launch the edge
            #5;
            $display("  cin %s : RCA %6.1f ps | RCA-inv %6.1f ps | CSA %6.1f ps",
                     label, (t_rca - t0) * 1000.0, (t_inv - t0) * 1000.0, (t_csa - t0) * 1000.0);
        end
    endtask

    initial begin
        $dumpfile("adders.vcd");
        $dumpvars(0, tb_adders);
        $dumpoff;                              // keep the VCD small during Part 1
        errors = 0;

        // ---------------- Part 1 ----------------
        for (i = 0; i < (1 << 17); i = i + 1) begin
            {cin, a, b} = i[16:0];
            #3;                                // > worst-case delay
            golden = a + b + cin;
            if ({c_rca, s_rca} !== golden || {c_inv, s_inv} !== golden || {c_csa, s_csa} !== golden) begin
                errors = errors + 1;
                if (errors <= 10)
                    $display("MISMATCH a=%h b=%h cin=%b exp=%h rca=%h inv=%h csa=%h",
                             a, b, cin, golden, {c_rca, s_rca}, {c_inv, s_inv}, {c_csa, s_csa});
            end
        end
        $display("Functional: %0d vectors, %0d errors -> %s",
                 1 << 17, errors, errors == 0 ? "PASS" : "FAIL");

        // ---------------- Part 2 ----------------
        $dumpon;
        $display("Worst-case carry ripple (cin -> cout), back-annotated delays:");
        carry_ripple(1'b1, " rise");
        carry_ripple(1'b0, " fall");
        $finish;
    end
endmodule
