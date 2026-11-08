* =====================================================================
* fa_func_tb.sp  --  Truth-table check of FA_MIRROR28 in T-Spice
* a, b, ci count through all 8 input combinations (one every 2 ns).
* Open the result in Waveform Viewer and check s and co against:
*   s = a xor b xor ci      co = majority(a, b, ci)
* =====================================================================
* --- pick ONE model line ---
.include "demo_models_level1.lib"
* .lib "<path to your 180nm model library>" TT

.include "fa_mirror28.sp"

Vdd  vdd 0 DC 1.8
* ci toggles fastest, a slowest -> 000,001,...,111
Vci ci 0 PULSE(0 1.8 2n 50p 50p 1.95n 4n)
Vb  b  0 PULSE(0 1.8 4n 50p 50p 3.95n 8n)
Va  a  0 PULSE(0 1.8 8n 50p 50p 7.95n 16n)

Xfa a b ci co s cob sb vdd 0 FA_MIRROR28
* load each output with roughly one gate input
Cco co 0 5f
Cs  s  0 5f

.tran 5p 16n
.print tran v(a) v(b) v(ci) v(s) v(co)

* Self-check at the middle of each 2 ns slot (expected values in comments)
.measure tran s_011 find v(s)  at=7n
.measure tran co_011 find v(co) at=7n
.measure tran s_111 find v(s)  at=15n
.measure tran co_111 find v(co) at=15n
* expected: s_011 ~ 0, co_011 ~ 1.8, s_111 ~ 1.8, co_111 ~ 1.8
.end
