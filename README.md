# Transistor-to-RTL Characterized 8-bit Adder

Characterize a 28-transistor mirror full adder at transistor level with the Tanner tools, then feed the measured
delays back into a Verilog model. That model is used to compare three 8-bit adder architectures:

| Architecture | Idea | Critical path |
|---|---|---|
| `rca8` | plain ripple carry, 8 × 28T cell | 8 × t(ci→co) |
| `rca8_inv` | ripple carry using the full adder's inversion property; no inverter on the carry path | 8 × t(ci→cob) |
| `csa8` | carry-select: low nibble ripples, high nibble computed for cin = 0 and 1, then a mux picks one | 4 × t(ci→co) + t(mux) |

## Folder layout

```
rtl/adder_cells.v     Verilog cell models (logic matches the transistors) + specify delays
rtl/adders.v          rca8, rca8_inv, csa8
rtl/fa_timing.vh      GENERATED delays (from scripts/parse_char.py)
tb/tb_adders.v        exhaustive check (131072 vectors) + worst-case carry timing
spice/fa_mirror28.sp  transistor netlists: FA_CORE24, INV, FA_MIRROR28, MUX2_TG
spice/fa_func_tb.sp   truth-table simulation for T-Spice / Waveform Viewer
spice/demo_models_level1.lib   TOY models, only to check things run
scripts/gen_char_netlist.py    builds the characterization netlist (slew × load grid)
scripts/parse_char.py          .measure results -> CSV + Liberty-style .lib + fa_timing.vh
char/                 generated tables
```

> The `fa_timing.vh` and `char/` files shipped here came from the **toy level-1 models** (run in ngspice).
> Before quoting numbers, re-run step 4 with real 180 nm models.

## 1. Verilog quick start

```
iverilog -gspecify -I rtl -o sim tb/tb_adders.v rtl/adder_cells.v rtl/adders.v
vvp sim
```
`-gspecify` makes Icarus apply the specify-block delays. ModelSim and Questa apply them by default
(`vlog +incdir+rtl ...`). On EDA Playground, paste the `fa_timing.vh` contents at the top of `adder_cells.v`.
Expected output: `Functional: 131072 vectors, 0 errors -> PASS`, then the cin→cout delay of each architecture.
Open `adders.vcd` in GTKWave to watch the carry ripple.

## 2. S-Edit: schematics

1. Create a new design/library, e.g. `ADDER180`.
2. For each `.subckt` in `spice/fa_mirror28.sp`, create a cell with a schematic view: `FA_CORE24`, `INV`,
   `MUX2_TG`, then `FA_MIRROR28` (built from one `FA_CORE24` and two `INV` symbols).
3. Use the NMOS/PMOS devices from the Tanner `Devices` library. Copy W/L from the netlist; L = 0.18u everywhere.
   The carry stage is sized 1.0u/2.0u and the sum stage is smaller.
4. Add ports with the same names (`a b ci cob sb vdd gnd`), generate a symbol for each cell, and check-save.
5. Export the SPICE netlist and compare it against `spice/fa_mirror28.sp`. The two should match device-for-device.

## 3. T-Spice: functional simulation

1. In `spice/fa_func_tb.sp`, comment out the demo `.include` and point `.lib` at your real model file.
   If your model names are not `nch`/`pch`, rename them in `fa_mirror28.sp`.
2. Run it in T-Spice. Waveform Viewer shows a, b, ci, s, co stepping through all 8 input combinations.
3. Check the four `.measure` values in the output (expected values are in the file's comments).

## 4. T-Spice: characterization (the core of the project)

From the `spice/` folder:
```
python ../scripts/gen_char_netlist.py --lib "C:/path/to/your_180nm.lib" --corner TT --nmos nch --pmos pch
```
(Use `--lib file.lib` without `--corner` if the file is a plain `.include` model file.)
This writes `fa_char.sp`. It holds 9 copies of each cell, one per (input slew, load) point, with
20/50/100 ps slews × 2/5/10 fF loads, plus about 135 `.measure` statements.

Run `fa_char.sp` in T-Spice, then:
```
python ../scripts/parse_char.py fa_char.out --root ..
```
Use whichever output file T-Spice wrote the measurement results to (normally the `.out` listing next to the netlist).
The script prints a delay table and writes:
- `char/char_table.csv`: every arc at every point, plus average power
- `char/adder_cells.lib`: Liberty-style NLDM tables (cell_rise/cell_fall vs input_net_transition × load)
- `rtl/fa_timing.vh`: delays at the nominal point (50 ps, 5 fF) for the Verilog specify blocks

Re-run step 1 and the Verilog delays now come from your silicon models.

## 5. L-Edit: layout of FA_CORE24 (or the full 28T cell)

1. Open L-Edit IC with your technology setup (the lab's 180 nm setup, or Tanner's sample lambda-rule setup).
2. Use the gate order **A-B-C-A-B** for the carry stage. That order is an Euler path of both the NMOS and the
   PMOS network, so each network fits on one unbroken diffusion strip. Only internal node n2 (NMOS) and p2 (PMOS)
   need a short metal strap.
3. Put VDD and GND rails on top and bottom with a fixed cell height, so cells can abut in a row of 8.
4. Run DRC until it is clean.

## 6. LVS and post-layout simulation

1. Extract the layout to a SPICE netlist with parasitic capacitances.
2. Run LVS v2019.2: compare the extracted netlist against the S-Edit netlist. It should report that the netlists
   match (28 devices, same connectivity and sizes).
3. Re-run the characterization netlist using the extracted cell in place of the schematic subcircuit. Record
   the pre- vs post-layout delay difference; this comes from wire and junction capacitance.

## Notes and limits

- Characterized arcs use a = 1, b = 0 (propagate mode, the ripple-critical case). The a/b → co arcs reuse the
  ci numbers. This simplification is flagged in `adder_cells.v`.
- Verilog specify delays are fixed numbers at one (slew, load) point. The `.lib` holds the full table; a real STA
  tool interpolates in it.
