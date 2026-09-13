`timescale 1ns/1ps
module cap_lsu_tb;
  import ibex_pkg::*;
  import ibex_cheriot_pkg::*;
  logic clk=0,rst=0,req=0,rv=0,err=0,tag=0,incr,dr,done,response,readvalid,loaderr;
  logic [31:0] rdata=0,address,result;
  cap_t resultcap;
  cap_clrperm_t clr='0;
  int count=0;
  ibex_load_store_unit #(.BaseIsa(BaseIsaRV32IorCHERIoT)) dut (
    .clk_i(clk),.rst_ni(rst),.cheriot_enable_i(IbexMuBiOn),
    .data_req_o(dr),.data_gnt_i(dr),.data_rvalid_i(rv),.data_bus_err_i(err),
    .data_pmp_err_i(1'b0),.data_addr_o(address),.data_rdata_i(rdata),.data_tag_i(tag),
    .lsu_we_i(1'b0),.lsu_is_cap_i(1'b1),.lsu_cheriot_err_i(1'b0),
    .lsu_type_i(2'b00),.lsu_wdata_i(0),.lsu_wcap_i(NULL_CAP),.lsu_lc_clrperm_i(clr),
    .lsu_sign_ext_i(1'b0),.lsu_rcap_o(resultcap),.lsu_rdata_o(result),
    .lsu_rdata_valid_o(readvalid),.lsu_req_i(req),.adder_result_ex_i(incr ? 32'h204 : 32'h200),
    .addr_incr_req_o(incr),.lsu_req_done_o(done),.lsu_resp_valid_o(response),.load_err_o(loaderr)
  );
  always #5 clk=~clk;
  always @(posedge clk) if(rst && dr) begin
    if(address !== (count==0 ? 32'h200 : 32'h204)) $fatal(1,"capability transaction address");
    count++;
  end
  task automatic run_case(input string name,input bit taglo,input bit taghi,
                          input bit errlo,input bit errhi,input bit cleartag);
    @(negedge clk); rst=0;req=0;rv=0;err=0;count=0;clr='0;
    @(negedge clk); rst=1;req=1;clr.CTAG=cleartag;
    @(negedge clk); req=0;
    @(negedge clk);
    if(count!=2) $fatal(1,"expected exactly two grants");
    repeat(2) @(negedge clk);
    rv=1;rdata=32'h1000;tag=taglo;err=errlo;
    #1;if(response || readvalid) $fatal(1,"first word completed architectural load");
    @(negedge clk);rv=0;
    repeat(2) @(negedge clk);
    rv=1;rdata=32'h7e020000;tag=taghi;err=errhi;
    #1;
    if(!response || loaderr !== (errlo|errhi) || readvalid !== !(errlo|errhi))
      $fatal(1,"%s completion/error",name);
    if(!(errlo|errhi) && (result!=32'h1000 || resultcap.valid !== (taglo&taghi&!cleartag)))
      $fatal(1,"%s data/tag assembly",name);
    $display("PASS %s grants=%0d result=%08x tag=%0d error=%0d",name,count,result,resultcap.valid,loaderr);
    @(negedge clk);rv=0;err=0;
  endtask
  initial begin
    run_case("tagged",1,1,0,0,0);
    run_case("low_tag_zero",0,1,0,0,0);
    run_case("high_tag_zero",1,0,0,0,0);
    run_case("CTAG",1,1,0,0,1);
    run_case("first_error",1,1,1,0,0);
    run_case("second_error",1,1,0,1,0);
    $display("FINISH cap_lsu 6 checks");$finish;
  end
  initial begin #10000;$fatal(1,"timeout");end
endmodule
