verdiWindowResize -win $_Verdi_1 "510" "157" "900" "700"
verdiSetActWin -dock widgetDock_<Message>
verdiWindowResize -win $_Verdi_1 "510" "157" "900" "700"
verdiSetActWin -dock widgetDock_MTB_SOURCE_TAB_1
verdiWindowResize -win $_Verdi_1 "170" "67" "900" "700"
simSetSimulator "-vcssv" -exec \
           "/home/dungpc/projects/cpu_fx1/ibex/dv/uvm/core_ibex/out/build/tb/vcs_simv" \
           -args \
           "+vcs+lic+wait +ntb_random_seed=1 +UVM_TESTNAME=core_ibex_base_test +UVM_VERBOSITY=UVM_LOW +bin=/home/dungpc/projects/cpu_fx1/ibex/dv/uvm/core_ibex/out/run/tests/riscv_arithmetic_basic_test.1/test.bin +ibex_tracer_file_base=/home/dungpc/projects/cpu_fx1/ibex/dv/uvm/core_ibex/out/run/tests/riscv_arithmetic_basic_test.1/trace_core_manual +cosim_log_file=/home/dungpc/projects/cpu_fx1/ibex/dv/uvm/core_ibex/out/run/tests/riscv_arithmetic_basic_test.1/cosim_manual.log +signature_addr=8ffffffc +test_timeout_s=1800 -ucli"
debImport "-dbdir" \
          "/home/dungpc/projects/cpu_fx1/ibex/dv/uvm/core_ibex/out/build/tb/vcs_simv.daidir"
debLoadSimResult \
           /home/dungpc/projects/cpu_fx1/ibex/dv/uvm/core_ibex/out/run/tests/riscv_arithmetic_basic_test.1/waves.fsdb
wvCreateWindow
verdiSetActWin -win $_nWave2
verdiDockWidgetMaximize -dock windowDock_nWave_2
wvGetSignalOpen -win $_nWave2
wvGetSignalSetScope -win $_nWave2 "/core_ibex_tb_top"
wvSelectGroup -win $_nWave2 {G1}
wvGetSignalSetScope -win $_nWave2 "/core_ibex_tb_top/dut"
wvGetSignalSetScope -win $_nWave2 "/core_ibex_tb_top/ifetch_if"
wvSetPosition -win $_nWave2 {("G1" 8)}
wvSetPosition -win $_nWave2 {("G1" 8)}
wvAddSignal -win $_nWave2 -clear
wvAddSignal -win $_nWave2 -group {"G1" \
{/core_ibex_tb_top/ifetch_if/clk} -height 16 \
{/core_ibex_tb_top/ifetch_if/fetch_addr\[31:0\]} -height 16 \
{/core_ibex_tb_top/ifetch_if/fetch_err} -height 16 \
{/core_ibex_tb_top/ifetch_if/fetch_err_plus2} -height 16 \
{/core_ibex_tb_top/ifetch_if/fetch_rdata\[31:0\]} -height 16 \
{/core_ibex_tb_top/ifetch_if/fetch_ready} -height 16 \
{/core_ibex_tb_top/ifetch_if/fetch_valid} -height 16 \
{/core_ibex_tb_top/ifetch_if/reset} -height 16 \
}
wvAddSignal -win $_nWave2 -group {"G2" \
}
wvSelectSignal -win $_nWave2 {( "G1" 1 2 3 4 5 6 7 8 )} 
wvSetPosition -win $_nWave2 {("G1" 8)}
wvZoom -win $_nWave2 184022.427343 1932235.487103
wvZoom -win $_nWave2 195507.038685 270795.046368
wvZoomIn -win $_nWave2
wvZoomIn -win $_nWave2
wvZoomIn -win $_nWave2
wvZoomIn -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomIn -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoom -win $_nWave2 202233.480492 310384.428755
wvZoomOut -win $_nWave2
wvZoom -win $_nWave2 221258.574310 239731.072043
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvSelectGroup -win $_nWave2 {G2}
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoom -win $_nWave2 5834530.312993 35979603.596788
wvZoom -win $_nWave2 11027404.250931 14129926.391818
wvZoom -win $_nWave2 11439564.126581 11677348.670225
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvZoomOut -win $_nWave2
wvSelectAll -win $_nWave2
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G1" 0)}
wvSelectGroup -win $_nWave2 {G2}
wvSelectGroup -win $_nWave2 {G1}
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G2" 0)}
wvSelectGroup -win $_nWave2 {G2}
wvCut -win $_nWave2
wvSetPosition -win $_nWave2 {("G1" 0)}
wvSelectGroup -win $_nWave2 {G1}
wvSelectGroup -win $_nWave2 {G1}
wvZoomAll -win $_nWave2
wvRestoreSignal -win $_nWave2 \
           "/home/dungpc/projects/cpu_fx1/ibex/doc/dungpc_doc/verdi/ibex_opentitan.rc" \
           -overWriteAutoAlias on -appendSignals on
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollDown -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvScrollUp -win $_nWave2 1
wvZoom -win $_nWave2 0.000000 6369893.636339
wvZoom -win $_nWave2 91371.425111 487314.267261
wvZoom -win $_nWave2 194954.832586 231736.408087
