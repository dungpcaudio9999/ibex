`timescale 1ns/1ps
module core_tb;
  import ibex_pkg::*;
  import ibex_cheriot_pkg::*;
  parameter bit WB = 0;
  parameter bit BT = 0;
  parameter int M = 2;
  logic clk = 0, rst = 0;
  always #5 clk = ~clk;
  logic ir, ig, iv = 0, dr, dg, dv = 0, dw, de = 0;
  logic [31:0] ia, idata = 0, da, wd, rd = 0;
  logic [3:0] be;
  logic [4:0] ra, rb, wa;
  logic [31:0] qa, qb, wq;
  logic [REGCAP_W-1:0] ca, cb, wc;
  logic we, dummy_id, dummy_wb;
  logic rv, trap;
  logic [63:0] order;
  logic [31:0] rpc, rinsn;
  logic irq = 0, debug_req = 0;
  logic [31:0] imem[1024], dmem[1024], shadow[32];
  integer cycle = 0, latency = 1, ilatency = 1, grant_period = 1;
  integer err_addr = -1, event_kind = 0;
  bit fired = 0, grant_open = 1;
  string program_file, wave_file;
  typedef struct packed {int due; logic [31:0] data; bit err;} rsp_t;
  rsp_t iq[$], dq[$], response_tmp;
  assign ig = ir && grant_open;
  assign dg = dr && grant_open;
  ibex_core #(.BaseIsa(BaseIsaRV32I), .RV32ZC(RV32Zca),
    .WritebackStage(WB), .BranchTargetALU(BT), .RV32M(rv32m_e'(M)),
    .DmHaltAddr(32'h40), .DmExceptionAddr(32'h40)) dut (
    .clk_i(clk), .rst_ni(rst), .hart_id_i(0), .boot_addr_i(0),
    .cheriot_enable_i(IbexMuBiOff), .fetch_enable_i(IbexMuBiOn),
    .mcounteren_writable_i(IbexMuBiOff),
    .instr_req_o(ir), .instr_gnt_i(ig), .instr_rvalid_i(iv), .instr_addr_o(ia),
    .instr_rdata_i(idata), .instr_err_i(1'b0),
    .data_req_o(dr), .data_gnt_i(dg), .data_rvalid_i(dv), .data_we_o(dw),
    .data_be_o(be), .data_addr_o(da), .data_wdata_o(wd), .data_rdata_i(rd),
    .data_tag_i(1'b0), .data_err_i(de),
    .rf_raddr_a_o(ra), .rf_raddr_b_o(rb), .rf_waddr_wb_o(wa), .rf_we_wb_o(we),
    .rf_wdata_wb_ecc_o(wq), .rf_rdata_a_ecc_i(qa), .rf_rdata_b_ecc_i(qb),
    .rf_wcap_ecc_wb_o(wc), .rf_rcap_a_ecc_i(ca), .rf_rcap_b_ecc_i(cb),
    .dummy_instr_id_o(dummy_id), .dummy_instr_wb_o(dummy_wb),
    .ic_tag_rdata_i('{default:'0}), .ic_data_rdata_i('{default:'0}),
    .ic_scr_key_valid_i(1'b0), .irq_software_i(1'b0), .irq_timer_i(irq),
    .irq_external_i(1'b0), .irq_fast_i('0), .irq_nm_i(1'b0), .debug_req_i(debug_req),
    .rvfi_valid(rv), .rvfi_order(order), .rvfi_pc_rdata(rpc),
    .rvfi_insn(rinsn), .rvfi_trap(trap)
  );
  ibex_register_file_ff rf (
    .clk_i(clk), .rst_ni(rst), .test_en_i(1'b0),
    .dummy_instr_id_i(dummy_id), .dummy_instr_wb_i(dummy_wb),
    .cheriot_enable_i(IbexMuBiOff), .raddr_a_i(ra), .raddr_b_i(rb),
    .rdata_a_o(qa), .rdata_b_o(qb), .rcap_a_o(ca), .rcap_b_o(cb),
    .waddr_a_i(wa), .wdata_a_i(wq), .wcap_a_i(wc), .we_a_i(we)
  );
  initial begin
    foreach (imem[i]) imem[i] = 32'h0000006f;
    foreach (dmem[i]) dmem[i] = 32'h44332211;
    foreach (shadow[i]) shadow[i] = 0;
    if (!$value$plusargs("program=%s", program_file)) $fatal(1, "Missing program");
    $readmemh(program_file, imem);
    void'($value$plusargs("latency=%d", latency));
    void'($value$plusargs("ilatency=%d", ilatency));
    void'($value$plusargs("grant_period=%d", grant_period));
    void'($value$plusargs("err_addr=%d", err_addr));
    void'($value$plusargs("event=%d", event_kind));
    if ($value$plusargs("wave=%s", wave_file)) begin
      $dumpfile(wave_file); $dumpvars(0, core_tb);
    end
    $display("CONFIG WB=%0d BT=%0d M=%0d latency=%0d ilatency=%0d grant_period=%0d", WB,BT,M,latency,ilatency,grant_period);
    #22 rst = 1;
  end
  // Responses are driven on falling edges and consumed on the next rising edge.
  // Accepted requests enter ordered queues; data is sampled at grant, writes apply at grant.
  always @(negedge clk) if (rst) begin
    grant_open = (cycle % grant_period == 0);
    iv = 0; dv = 0; de = 0;
    if (iq.size() > 0 && iq[0].due <= cycle) begin
      response_tmp = iq.pop_front(); iv = 1; idata = response_tmp.data;
    end
    if (dq.size() > 0 && dq[0].due <= cycle) begin
      response_tmp = dq.pop_front(); dv = 1; rd = response_tmp.data; de = response_tmp.err;
    end
  end
  always @(posedge clk) if (rst) begin
    $display("C %0d %08x %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %0d %08x %0d %0d %08x %0d %0d %0d %0d",cycle,
      dut.pc_id,dut.instr_valid_id,dut.id_stage_i.id_fsm_q,
      dut.id_stage_i.stall_mem,dut.id_stage_i.stall_ld_hz,dut.id_stage_i.stall_multdiv,
      dut.id_stage_i.stall_branch,dut.id_stage_i.stall_jump,dut.id_stage_i.instr_done,
      dut.id_stage_i.ready_wb_i,dr,dg,da,dv,de,dut.pc_if,ir,ig,iv,dut.pc_set);
    if (ir && ig) iq.push_back(rsp_t'{cycle + ilatency, imem[ia[11:2]], 1'b0});
    if (dr && dg) begin
      dq.push_back(rsp_t'{cycle + latency, dmem[da[11:2]], da == 32'(err_addr)});
      $display("D %0d %0d %08x %x %08x",cycle,dw,da,be,wd);
      if (dw && da != 32'(err_addr))
        for (int i=0;i<4;i++) if(be[i]) dmem[da[11:2]][i*8+:8] = wd[i*8+:8];
    end
    if (we && wa != 0) begin
      shadow[wa] = wq; $display("W %0d %0d %08x",cycle,wa,wq);
    end
    if (rv) $display("R %0d %0d %08x %08x %0d",cycle,order,rpc,rinsn,trap);
    if (!fired && ((event_kind inside {1,2}) && dq.size() > 0 ||
                  (event_kind inside {3,4}) && dut.id_stage_i.stall_multdiv)) begin
      fired = 1;
      if (event_kind inside {1,3}) irq <= 1; else debug_req <= 1;
      $display("EVENT %0d %0d", cycle,event_kind);
    end
    // Explicit procedural checker, independent of the disabled prim_assert macros.
    if (dut.id_stage_i.instr_done && dut.id_stage_i.stall_id)
      $fatal(1,"Done during stall");
    if (cycle == 399) begin
      foreach(shadow[i]) $display("REG %0d %08x",i,shadow[i]);
      for(int i=128;i<133;i++) $display("MEM %08x %08x",i*4,dmem[i]);
      $display("FINISH"); $finish;
    end
    cycle = cycle + 1;
  end
endmodule
