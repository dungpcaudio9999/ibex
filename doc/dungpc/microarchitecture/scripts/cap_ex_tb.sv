`timescale 1ns/1ps
module cap_ex_tb;
  import ibex_pkg::*;
  import ibex_cheriot_pkg::*;
  logic clk=0,rst=0;
  always #5 clk=~clk;
  cap_t cap;
  logic [31:0] addr;
  logic iscap=0, err, req, is_cap_out;
  cheriot_op_t op;
  assign op = cheriot_op_t'{CLOAD_CAP:iscap, default:'0};
  ibex_cheriot_ex dut (
    .clk_i(clk),
    .rst_ni(rst),
    .cheriot_enable_i(IbexMuBiOn),
    .debug_mode_i('0),
    .fwd_we_i('0),
    .fwd_waddr_i('0),
    .fwd_wdata_i('0),
    .fwd_wcap_i(cap_t'('0)),
    .rf_raddr_a_i(5'd1),
    .rf_rdata_a_i(addr),
    .rf_rcap_a_i(cap),
    .rf_raddr_b_i(5'd2),
    .rf_rdata_b_i('0),
    .rf_rcap_b_i(cap_t'('0)),
    .rf_waddr_i('0),
    .pcc_cap_i(ROOT_DECODED_CAP_TX),
    .pc_id_i('0),
    .cheriot_exec_id_i(1'b1),
    .instr_first_cycle_i(1'b1),
    .instr_valid_i(1'b1),
    .instr_is_cheriot_i(iscap),
    .instr_is_rv32lsu_i(!iscap),
    .instr_is_compressed_i('0),
    .cheriot_imm12_i('0),
    .cheriot_imm20_i('0),
    .cheriot_imm21_i('0),
    .cheriot_cs2_dec_i('0),
    .cheriot_operator_i(op),
    .cheriot_cap_field_sel_i(cheriot_cap_field_e'('0)),
    .cheriot_adder_a_sel_i(cheriot_adder_a_sel_e'('0)),
    .cheriot_adder_b_sel_i(cheriot_adder_b_sel_e'('0)),
    .cheriot_setaddr_sel_i(cheriot_setaddr_sel_e'('0)),
    .cheriot_setbounds_sel_i(cheriot_setbounds_sel_e'('0)),
    .addr_incr_req_i('0),
    .addr_last_i('0),
    .rv32_lsu_req_i(!iscap),
    .rv32_lsu_we_i('0),
    .rv32_lsu_type_i('0),
    .rv32_lsu_wdata_i('0),
    .rv32_lsu_sign_ext_i('0),
    .rv32_lsu_addr_i(addr),
    .csr_rdata_i('0),
    .csr_rcap_i(cap_t'('0)),
    .csr_mstatus_mie_i('0),
    .csr_mshwm_i('0),
    .csr_mshwmb_i('0),
    .ztop_rdata_i('0),
    .ztop_rcap_i(cap_t'('0)),
    .csr_dbg_tclr_fault_i('0),
    .lsu_cheriot_err_o(err),
    .lsu_req_o(req),
    .lsu_is_cap_o(is_cap_out));
  task automatic check(input string name,input bit expected);
    #2;
    if(err !== expected || !req) $fatal(1,"%s expected err=%0d got=%0d req=%0d",name,expected,err,req);
    $display("PASS %s err=%0d",name,err);
  endtask
  initial begin
    #2; rst=1; cap=ROOT_CAP_TM; addr=32'h80;
    check("root_word_load",0);
    cap.valid=0; check("untagged_word_load",1);
    cap=ROOT_CAP_TS; check("no_load_permission",1);
    cap=ROOT_CAP_TM; cap.cexp=0; cap.base=0; cap.top=9'h100; cap.cap_cor=0;
    addr=32'hfc; check("last_in_bounds_word",0);
    addr=32'hfd; check("word_crosses_top",1);
    addr=32'h80; iscap=1;
    check("aligned_capability_load",0);
    addr=32'h83; check("misaligned_capability_load",1);
    addr=32'h100; check("capability_at_top",1);
    $display("FINISH cap_ex 8 checks"); $finish;
  end
endmodule
