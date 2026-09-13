`timescale 1ns/1ps
module opentitan_tb;
  import ibex_pkg::*;
  import ibex_cheriot_pkg::*;
  localparam bit SEC=1,CACHE=1,PRED=0,DUAL=1,SCR=1,ICECC=1,PMP=1;
  localparam int ZC=3,OFFSET=1;
  int mode_select=0, trigger_program=0;
  logic clk=0,rst=1;
  always #5 clk=~clk;
  ibex_mubi_t mode,fetch_en;
  assign mode = (fault==5 && cycle>=100) ? ibex_mubi_t'(0) : (mode_select ? IbexMuBiOn : IbexMuBiOff);
  assign fetch_en = IbexMuBiOn;
  logic ir,ig,iv=0,ie=0,dr,dg,dv=0,de=0,dw,dtag=0,wtag;
  logic [31:0] ia,idata=0,da,wd,rd=0;
  logic [3:0] be;
  logic [38:0] ienc,denc,bmenc;
  prim_secded_inv_39_32_enc iecc(.data_i(idata),.data_o(ienc));
  prim_secded_inv_39_32_enc decc(.data_i(rd),.data_o(denc));
  prim_secded_inv_39_32_enc becc(.data_i(bmdata),.data_o(bmenc));
  logic irq=0,nmi=0,dbg=0,sleeping,amin,aint,abus,rv;
  logic [31:0] rpc,insn;
  logic [63:0] order;
  logic bmreq,bmv=0,keyreq,keyvalid=0;
  logic [31:0] bmaddr,bmdata=0;
  logic [127:0] key=128'h1234;
  logic [63:0] nonce=64'h5678;
  logic [31:0] imem[1024],dmem[1024],shadow[32];
  logic tags[1024];
  int cycle=0,latency=2,ev=0,iferr=-1,fault=0,revoked=0,reset_at=0;
  bit fired=0,grant_open=1;
  int key_wait=0,bm_wait=0,key_responses=0;
  int sleep_cycles=0,clock_edges=0,alerts_i=0,alerts_b=0,alerts_m=0;
  int if_grants=0,data_grants=0,bm_grants=0,cache_hits=0,cache_misses=0,dummies=0,expanded=0,predicts=0,mispredicts=0;
  string program_file,wave,debug_file;
  logic [31:0] debugmem[1024];
  int err_addr=-1;
  function automatic logic [31:0] fetch_word(input logic [31:0] addr);
    if(addr<4096)return imem[addr[11:2]];
    if(addr>=32'h1a110000 && addr<32'h1a111000)return debugmem[addr[11:2]];
    return 32'h0000006f;
  endfunction
  function automatic bit fetch_mapped(input logic [31:0] addr);
    return addr<4096 || (addr>=32'h1a110000 && addr<32'h1a111000);
  endfunction
  typedef struct packed {int due; logic [31:0] data; bit tag; bit err;} rsp_t;
  rsp_t iq[$],dq[$],tmp;
  assign ig=ir && grant_open;
  assign dg=dr && grant_open;
  ibex_top #(
    `include "opentitan_params.svh"
  ) dut (
    .clk_i(clk),
    .rst_ni(rst),
    .test_en_i('0),
    .ram_cfg_icache_tag_i('0),
    .ram_cfg_icache_data_i('0),
    .cheriot_enable_i(mode),
    .hart_id_i('0),
    .boot_addr_i('0),
    .trvk_heap_base_addr_i(32'h1000),
    .instr_gnt_i(ig),
    .instr_rvalid_i(iv),
    .instr_rdata_i(idata ^ ((fault==1 && iv) ? 32'h1 : 0)),
    .instr_rdata_intg_i(ienc[38:32]),
    .instr_err_i(ie),
    .data_gnt_i(dg),
    .data_rvalid_i(dv | (fault==7 && cycle==100)),
    .data_rdata_i(rd ^ ((fault==2 && dv) ? 32'h1 : 0)),
    .data_rdata_intg_i(denc[38:32]),
    .data_tag_i(dtag),
    .data_err_i(de),
    .trvk_revbm_gnt_i(bmreq),
    .trvk_revbm_rvalid_i(bmv),
    .trvk_revbm_rdata_i(bmdata ^ ((fault==9 && bmv) ? 32'h1 : 0)),
    .trvk_revbm_rdata_intg_i(bmenc[38:32]),
    .trvk_revbm_err_i('0),
    .irq_software_i('0),
    .irq_timer_i(irq),
    .irq_external_i('0),
    .irq_fast_i('0),
    .irq_nm_i(nmi),
    .scramble_key_valid_i(keyvalid),
    .scramble_key_i(key),
    .scramble_nonce_i(nonce),
    .debug_req_i(dbg),
    .fetch_enable_i(fetch_en),
    .mcounteren_writable_i(IbexMuBiOff),
    .scan_rst_ni(rst),
    .instr_req_o(ir),
    .instr_addr_o(ia),
    .data_req_o(dr),
    .data_we_o(dw),
    .data_addr_o(da),
    .data_wdata_o(wd),
    .data_be_o(be),
    .data_tag_o(wtag),
    .trvk_revbm_req_o(bmreq),
    .trvk_revbm_addr_o(bmaddr),
    .scramble_req_o(keyreq),
    .alert_minor_o(amin),
    .alert_major_internal_o(aint),
    .alert_major_bus_o(abus),
    .core_sleep_o(sleeping),
    .rvfi_valid(rv),
    .rvfi_pc_rdata(rpc),
    .rvfi_insn(insn),
    .rvfi_order(order));
  initial begin
    foreach(debugmem[i])debugmem[i]=32'h0000006f;
    debugmem[512]=32'h07600693;debugmem[513]=32'h7b200073;
    foreach(imem[i])imem[i]=32'h0000006f;
    foreach(dmem[i])begin dmem[i]=32'h44332211;tags[i]=0;end
    dmem[128]=32'h1000;dmem[129]=32'h7e020000;tags[128]=1;tags[129]=1;
    foreach(shadow[i])shadow[i]=0;
    if(!$value$plusargs("program=%s",program_file))$fatal(1,"program required");
    $readmemh(program_file,imem);
    if($value$plusargs("debug_program=%s",debug_file))$readmemh(debug_file,debugmem);
    void'($value$plusargs("mode=%d",mode_select));
    void'($value$plusargs("err_addr=%d",err_addr));
    void'($value$plusargs("latency=%d",latency));
    void'($value$plusargs("event=%d",ev));
    void'($value$plusargs("iferr=%d",iferr));
    void'($value$plusargs("fault=%d",fault));
    void'($value$plusargs("revoked=%d",revoked));
    void'($value$plusargs("reset_at=%d",reset_at));
    if($value$plusargs("wave=%s",wave))begin $dumpfile(wave);$dumpvars(0,opentitan_tb);end
    $display("CONFIG SEC=%0d CACHE=%0d PRED=%0d DUAL=%0d MODE=%0d ZC=%0d SCR=%0d ICECC=%0d OFFSET=%0d PMP=%0d",SEC,CACHE,PRED,DUAL,mode_select,ZC,SCR,ICECC,OFFSET,PMP);
    #1;rst=0; #21;rst=1;
  end
  always @(negedge clk) begin
    if(reset_at!=0 && cycle==reset_at)begin
      rst=0;iq.delete();dq.delete();iv=0;dv=0;irq=0;dbg=0;nmi=0;
      foreach(shadow[i])shadow[i]=0;
      $display("RESET %0d pending requests cancelled by memory epoch contract",cycle);
    end
    if(reset_at!=0 && cycle==reset_at+2)rst=1;
    if(rst)begin
      grant_open=(latency==1 || cycle%3==0);
      iv=0;dv=0;ie=0;de=0;bmv=0;keyvalid=0;
      if(iq.size()>0 && iq[0].due<=cycle)begin tmp=iq.pop_front();iv=1;idata=tmp.data;ie=tmp.err;end
      if(dq.size()>0 && dq[0].due<=cycle)begin tmp=dq.pop_front();dv=1;rd=tmp.data;dtag=tmp.tag;de=tmp.err;end
      if(keyreq && key_wait==0)key_wait=6;
      if(key_wait>0)begin key_wait--;if(key_wait==1)begin keyvalid=1;key_responses++;$display("KEY %0d response",cycle);key=key+1;nonce=nonce+1;end end
      if(bm_wait>0)begin bm_wait--;if(bm_wait==1)begin bmv=1;bmdata=revoked ? 1 : 0;end end
      if(!fired && ((ev==1 && sleeping && sleep_cycles>=20) || (ev inside {2,3,4} && dq.size()>0) ||
          (ev==5 && dut.u_ibex_core.id_stage_i.stall_multdiv) ||
          (ev inside {6,9} && dut.u_ibex_core.instr_gets_expanded_id!=INSTR_NOT_EXPANDED && dq.size()>0) ||
          (ev==7 && bm_wait>2) || (ev==8 && keyreq)))begin
        fired=1;
        if(ev inside {1,4,9})irq=1;
        if(ev inside {2,4,5,6,7,8})dbg=1;
        if(ev==3)nmi=1;
        $display("EVENT %0d %0d",cycle,ev);
      end
      if(dut.u_ibex_core.id_stage_i.controller_i.debug_mode_q)dbg=0;
      if(dut.u_ibex_core.id_stage_i.controller_i.nmi_mode_q)nmi=0;
      if(fault!=0 && cycle==100)$display("INJECT %0d fault=%0d",cycle,fault);
      if(fault==8 && cycle==100)force dut.rf_rcap_a=35'h0;
      if(fault==8 && cycle==110)release dut.rf_rcap_a;
      if(fault==6 && cycle==100)force dut.u_ibex_core.if_stage_i.pc_if_o=32'hdeadbeee;
      if(fault==6 && cycle==110)release dut.u_ibex_core.if_stage_i.pc_if_o;
      if(fault==3 && cycle==100)force dut.rf_rdata_a=32'hdeadbeef;
      if(fault==3 && cycle==110)release dut.rf_rdata_a;
      if(fault==4 && cycle==100)force dut.u_ibex_core.result_ex=32'hcafef00d;
      if(fault==4 && cycle==110)release dut.u_ibex_core.result_ex;
    end
  end
  if(CACHE)begin
    if(SCR)begin : inject_scrambled_ram_read
      logic [(ICECC?78:64)-1:0] saved_cache_word;
      always @(negedge clk) begin
        if(fault==10 && cycle==350)begin
          saved_cache_word=dut.gen_rams.gen_rams_inner[0].gen_scramble_rams.data_bank.rdata_o ^ 1;
          force dut.gen_rams.gen_rams_inner[0].gen_scramble_rams.data_bank.rdata_o=saved_cache_word;
          $display("INJECT %0d cache-RAM-read-way0",cycle);
        end
        if(fault==10 && cycle==354)release dut.gen_rams.gen_rams_inner[0].gen_scramble_rams.data_bank.rdata_o;
      end
    end
    always @(posedge dut.clk) if(rst)begin
      if(dut.u_ibex_core.if_stage_i.gen_icache.icache_i.lookup_valid_ic1)begin
        if(dut.u_ibex_core.if_stage_i.gen_icache.icache_i.tag_hit_ic1)cache_hits++;
        else cache_misses++;
      end
    end
  end
  if(SEC)begin
    // Stable sample after falling-edge stimuli settle; cycle is unchanged here.
    always @(negedge clk) begin
      #1;
      if(rst && (cycle<120 || (cycle>=345 && cycle<=360)))$display("SAMPLE %0d ai=%b ab=%b am=%b pc=%b mismatch=%b rf=%b mode=%b",cycle,aint,abus,amin,dut.u_ibex_core.pc_mismatch_alert,dut.gen_lockstep.u_ibex_lockstep.outputs_mismatch,dut.gen_lockstep.u_ibex_lockstep.u_shadow_core.rf_ecc_err_comb,dut.u_ibex_core.cheriot_enable_mubi_err);
    end
    always @(posedge dut.clk) if(rst && cycle<120)
      $display("LOCK %0d rst=%b cmp=%x mismatch=%b rf=%b cap=%b",cycle,dut.gen_lockstep.u_ibex_lockstep.rst_shadow_n,dut.gen_lockstep.u_ibex_lockstep.enable_cmp_q,dut.gen_lockstep.u_ibex_lockstep.outputs_mismatch,dut.gen_lockstep.u_ibex_lockstep.u_shadow_core.rf_ecc_err_comb,dut.gen_lockstep.u_ibex_lockstep.u_shadow_core.cheriot_enable_mubi_err);
  end
  always @(posedge dut.clk) if(rst)begin
    clock_edges++;
    if(cycle<1200)$display("T %0d %08x %b %b %b %b %b %b %b %b %b %b %b %b %b %0d",($time/10),dut.u_ibex_core.pc_id,dut.u_ibex_core.instr_valid_id,dut.u_ibex_core.id_in_ready,dut.u_ibex_core.id_stage_i.stall_mem,dut.u_ibex_core.id_stage_i.stall_ld_hz,dut.u_ibex_core.id_stage_i.stall_multdiv,dut.u_ibex_core.id_stage_i.stall_branch,dut.u_ibex_core.id_stage_i.stall_jump,dut.u_ibex_core.id_stage_i.stall_alu,dut.u_ibex_core.ready_wb,dut.u_ibex_core.outstanding_load_wb,dut.u_ibex_core.pc_set,dut.u_ibex_core.instr_new_id,dut.dummy_instr_id,dut.u_ibex_core.instr_gets_expanded_id);

    if(dut.dummy_instr_id && dut.u_ibex_core.instr_new_id)dummies++;
    if(dut.u_ibex_core.instr_gets_expanded_id!=INSTR_NOT_EXPANDED && dut.u_ibex_core.instr_new_id)expanded++;
    if(dut.u_ibex_core.if_stage_i.predict_branch_taken)predicts++;
    if(dut.u_ibex_core.nt_branch_mispredict)mispredicts++;
    if(dut.rf_we_wb && dut.rf_waddr_wb!=0 && !dut.dummy_instr_wb)begin
      shadow[dut.rf_waddr_wb]=dut.rf_wdata_wb;
      $display("W %0d %0d %08x %x",cycle,dut.rf_waddr_wb,dut.rf_wdata_wb,dut.rf_wcap);
    end
    if(cycle<80 && dut.u_ibex_core.instr_valid_id)$display("CSRDBG %0d addr=%x priv=%x dec=%b csr=%b raw=%b pw=%b dbg=%b op=%x",cycle,dut.u_ibex_core.cs_registers_i.csr_addr,dut.u_ibex_core.cs_registers_i.priv_lvl_q,dut.u_ibex_core.id_stage_i.illegal_insn_dec,dut.u_ibex_core.cs_registers_i.illegal_csr_insn_o,dut.u_ibex_core.cs_registers_i.illegal_csr,dut.u_ibex_core.cs_registers_i.illegal_csr_priv,dut.u_ibex_core.cs_registers_i.illegal_csr_dbg,dut.u_ibex_core.cs_registers_i.csr_op_i);
    if(SEC && cycle<120)begin
      $display("SECDET %0d pc=%b rf=%b intg=%b",cycle,dut.u_ibex_core.pc_mismatch_alert,dut.u_ibex_core.rf_ecc_err_comb,dut.u_ibex_core.instr_intg_err);
    end
    if(rv)$display("R %0d %0d %08x %08x",cycle,order,rpc,insn);
    if(cycle<1200)$display("C %0d %08x %0d %0d %0d %0d %0d %0d",cycle,dut.u_ibex_core.pc_id,dut.u_ibex_core.instr_valid_id,dut.u_ibex_core.id_stage_i.stall_mem,dut.u_ibex_core.id_stage_i.stall_multdiv,dut.u_ibex_core.pc_set,dut.u_ibex_core.id_stage_i.controller_i.ctrl_fsm_cs,dut.u_ibex_core.id_stage_i.controller_i.debug_mode_q);
  end
  bit held_i=0,held_d=0;
  logic [31:0] last_ia,last_da,last_wd;
  logic [3:0] last_be;
  bit last_we,last_tag;
  int pending_i=0,pending_d=0,protocol_checks=0;
  always @(posedge clk)begin
    if(!rst)begin held_i=0;held_d=0;pending_i=0;pending_d=0;end
    else begin
      if(held_i && (!ir || ia!=last_ia))$fatal(1,"instruction request changed before grant");
      if(held_d && (!dr || {da,wd,be,dw,wtag}!={last_da,last_wd,last_be,last_we,last_tag}))$fatal(1,"data request changed before grant");
      pending_i+=int'(ir&&ig)-int'(iv);
      pending_d+=int'(dr&&dg)-int'(dv);
      if(pending_i<0 || pending_d<0)$fatal(1,"response without accepted request");
      held_i=ir&&!ig;held_d=dr&&!dg;
      last_ia=ia;last_da=da;last_wd=wd;last_be=be;last_we=dw;last_tag=wtag;
      protocol_checks++;
    end
  end
  always @(posedge clk)begin
    if(rst)begin
      if(sleeping)sleep_cycles++;
      if(aint)begin alerts_i++;if(alerts_i==1)$display("ALERT internal %0d",cycle);end
      if(abus)begin alerts_b++;if(alerts_b==1)$display("ALERT bus %0d",cycle);end
      if(amin)begin alerts_m++;if(alerts_m==1)$display("ALERT minor %0d",cycle);end
      if(ir && ig)begin iq.push_back(rsp_t'{cycle+latency,fetch_word(ia),1'b0,ia==32'(iferr) || !fetch_mapped(ia)});if_grants++;end
      if(dr && dg)begin
        dq.push_back(rsp_t'{cycle+latency,dmem[da[11:2]],tags[da[11:2]],da==32'(err_addr) || da>=4096});data_grants++;
        $display("D %0d %0d %08x %x %08x tag=%0d",cycle,dw,da,be,wd,wtag);
        if(dw && da!=32'(err_addr) && da<4096)begin
          for(int j=0;j<4;j++)if(be[j])dmem[da[11:2]][8*j+:8]=wd[8*j+:8];
          tags[da[11:2]]=wtag;
        end
      end
      if(bmreq)begin bm_wait=7;bm_grants++;$display("B %0d %08x",cycle,bmaddr);end
    end
    if(cycle==1199)begin
      foreach(shadow[i])$display("REG %0d %08x",i,shadow[i]);
      $display("COUNTS sleep=%0d clocks=%0d ai=%0d ab=%0d am=%0d ifetch=%0d data=%0d bitmap=%0d hit=%0d miss=%0d dummy=%0d expanded=%0d predict=%0d mispredict=%0d keys=%0d",sleep_cycles,clock_edges,alerts_i,alerts_b,alerts_m,if_grants,data_grants,bm_grants,cache_hits,cache_misses,dummies,expanded,predicts,mispredicts,key_responses);
      $display("PROTOCOL_CHECKS %0d",protocol_checks);$display("FINISH");$finish;
    end
    cycle++;
  end
endmodule
