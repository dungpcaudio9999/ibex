`timescale 1ns/1ps
module trvk_tb;
  logic clk=0,rst=0;
  always #5 clk=~clk;
  logic req=0,gnt,valid,tag;
  logic [31:0] addr=0,udata;
  logic dsreq,dsv=0,dstag=0;
  logic [31:0] dsdata=0;
  logic bmreq,bmgnt=0,bmv=0,bmerr=0;
  logic [31:0] bmaddr,bmdata=0;
  logic device_err;
  int returned=0;
  logic last_tag;
  ibex_trvk #(.NumOutstanding(2),.MemECC(0)) dut (
    .clk_i(clk),.rst_ni(rst),.heap_base_addr_i(32'h1000),
    .upstream_req_i(req),.upstream_gnt_o(gnt),.upstream_rvalid_o(valid),
    .upstream_we_i(1'b0),.upstream_be_i(4'hf),.upstream_addr_i(addr),
    .upstream_wdata_i(0),.upstream_wdata_intg_i(0),.upstream_tag_i(1'b0),
    .upstream_rdata_o(udata),.upstream_tag_o(tag),
    .downstream_req_o(dsreq),.downstream_gnt_i(dsreq),.downstream_rvalid_i(dsv),
    .downstream_rdata_i(dsdata),.downstream_rdata_intg_i(0),.downstream_err_i(1'b0),
    .downstream_tag_i(dstag),.revbm_req_o(bmreq),.revbm_gnt_i(bmgnt),
    .revbm_rvalid_i(bmv),.revbm_addr_o(bmaddr),.revbm_rdata_i(bmdata),
    .revbm_rdata_intg_i(0),.revbm_err_i(bmerr),.revbm_device_error_o(device_err)
  );
  always @(posedge clk) if(rst && valid) begin
    returned++; last_tag=tag;
    $display("RESPONSE %0t data=%08x tag=%0d",$time,udata,tag);
  end
  task automatic send(input logic [31:0] a,input logic [31:0] data,input bit t);
    @(negedge clk); addr=a; req=1;
    do @(posedge clk); while(!gnt);
    @(negedge clk); req=0; dsv=1; dsdata=data; dstag=t;
    @(negedge clk); dsv=0;
  endtask
  task automatic run_case(input string name,input bit revoked,input bit error_bit,
                          input bit ptrtag,input bit seal,input bit outside);
    int before_count;
    bit lookup;
    @(negedge clk); rst=0; req=0; dsv=0; bmv=0; bmgnt=0; bmerr=0;
    @(negedge clk); rst=1;
    before_count=returned;
    send(32'h200, outside ? 32'h90000 : 32'h1000,ptrtag);
    // exponent=0, base=0, top=0x100. Memory-root permissions except sealing test.
    send(32'h204,(seal ? 32'h4e020000 : 32'h7e020000),1);
    lookup=ptrtag && !seal && !outside;
    if(lookup) begin
      if(!bmreq || bmaddr!=0) $fatal(1,"%s missing lookup/address",name);
      repeat(3) begin
        @(negedge clk);
        if(returned!=before_count+1 || !bmreq) $fatal(1,"%s metadata escaped before bitmap",name);
      end
      bmgnt=1;
      @(negedge clk); bmgnt=0;
      repeat(3) begin
        @(negedge clk);
        if(bmreq || returned!=before_count+1) $fatal(1,"%s repeated request/early response",name);
      end
      bmdata=revoked ? 1 : 0; bmerr=error_bit; bmv=1;
      #1; if(device_err!==error_bit) $fatal(1,"device error qualification");
      @(negedge clk); bmv=0; bmerr=0;
    end else begin
      repeat(2) @(negedge clk);
      if(bmreq) $fatal(1,"%s unexpected lookup",name);
    end
    if(returned!=before_count+2 || last_tag !== !(lookup && (revoked || error_bit)))
      $fatal(1,"%s response count/tag",name);
    $display("PASS %s",name);
  endtask
  initial begin
    run_case("live",0,0,1,0,0);
    run_case("revoked",1,0,1,0,0);
    run_case("bitmap_device_error",0,1,1,0,0);
    run_case("untagged_pointer",0,0,0,0,0);
    run_case("sealing_cap",0,0,1,1,0);
    run_case("outside_heap",0,0,1,0,1);
    if($test$plusargs("negative")) $fatal(1,"checker activation negative control");
    $display("FINISH trvk 6 checks"); $finish;
  end
  initial begin #10000; $fatal(1,"timeout"); end
endmodule
