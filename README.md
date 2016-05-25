## Simulating SRAM Test Bench (wip)

``` verilog
iverilog -o tb_sram.vvp sram.v tb_sram.v && vvp tb_sram.vvp && gtkwave.exe tb_sram_testcase1.vcd &
```