class sb extends uvm_scoreboard;
        `uvm_component_utils(sb)

        uvm_tlm_analysis_fifo#(axi_xtn) mst_fifo_h[];
        uvm_tlm_analysis_fifo#(axi_xtn) slv_fifo_h[];

        env_config env_cfg_h;
        axi_xtn wr_xtn,rd_xtn;
        axi_xtn mst_xtn,slv_xtn;
	static int pkt_rcvd,pkt_cmprd;	
		covergroup write_cg;
		    option.per_instance=1;	
			awaddr_cp:   coverpoint  wr_xtn.awaddr{bins awaddr_bin={[0:32'hffff_ffff]};}
			awburst_cp:   coverpoint wr_xtn.awburst{bins awburst_bin[]={[0:2]};}
			awsize_cp :   coverpoint wr_xtn.awsize{bins awsize_bin[]={[0:2]};}
			awlen_cp  :   coverpoint wr_xtn.awlen{bins awlen_bin={[0:15]};}
			bresp_cp  :   coverpoint wr_xtn.bresp{bins bresp_bin={0};}
 
                       WRITE_ADDR: cross awburst_cp,awsize_cp,awlen_cp;
                endgroup
		
		covergroup write_cg1 with function sample(int i);
		   option.per_instance=1;
			wdata_cp  :   coverpoint wr_xtn.wdata[i]{bins wdata_bin={[0:32'hffff_ffff]};}
			wstrb_cp  :   coverpoint wr_xtn.wstrb[i]{bins wstrobe_bin0={4'b1111};
                                                                 bins wstrobe_bin1={4'b1100};
                                                                 bins wstrobe_bin2={4'b0011};
                                                                 bins wstrobe_bin3={4'b1000};
                                                                 bins wstrobe_bin4={4'b0100};
                                                                 bins wstrobe_bin5={4'b0010};
                                                                 bins wstrobe_bin6={4'b0001};
                                                                 bins wstrobe_bin7={4'b1110};
                                                                }
                        WRITE_DATA: cross wdata_cp,wstrb_cp;
                endgroup
		
		covergroup read_cg;
		    option.per_instance=1;
			araddr_cp:   coverpoint  rd_xtn.araddr{bins araddr_bin={[0:'hffff_ffff]};}
			arburst_cp:   coverpoint rd_xtn.arburst{bins arburst_bin[]={[0:2]};}
			arsize_cp :   coverpoint rd_xtn.arsize{bins arsize_bin[]={[0:2]};}
			arlen_cp  :   coverpoint rd_xtn.arlen{bins arlen_bin={[0:15]};}
	
                        READ_ADDR: cross arburst_cp,arsize_cp,arlen_cp;
                endgroup
		
		covergroup read_cg1 with function sample(int i);
		   option.per_instance=1;
			rdata_cp  :   coverpoint rd_xtn.rdata[i]{bins rdata_bin={[0:'hffff_ffff]};}
			rresp_cp  :   coverpoint rd_xtn.rresp[i]{bins rresp_bin={0};}
	
                endgroup
		
		
        extern function new(string name="sb",uvm_component parent);
        extern function void build_phase(uvm_phase phase);
        extern task run_phase(uvm_phase phase);
        extern function void report_phase(uvm_phase phase);
endclass

    function sb::new(string name="sb",uvm_component parent);
       super.new(name,parent);
	   write_cg=new();
	   write_cg1=new();
	   read_cg=new();
	   read_cg1=new();
    endfunction

    function void sb::build_phase(uvm_phase phase);
        if(!uvm_config_db #(env_config)::get(this,"","env_config",env_cfg_h))
                `uvm_fatal("Scoreboard","cannot get env config, have you set it?");

         mst_fifo_h=new[env_cfg_h.no_of_master];
         slv_fifo_h=new[env_cfg_h.no_of_slave];

         foreach(mst_fifo_h[i])
             mst_fifo_h[i]=new($sformatf("mst_fifo_h[%0d]",i),this);

         foreach(slv_fifo_h[i])
             slv_fifo_h[i]=new($sformatf("slv_fifo_h[%0d]",i),this);
        super.build_phase(phase);
    endfunction
	
	task sb::run_phase(uvm_phase phase);
	    forever
		    begin
			    mst_fifo_h[0].get(mst_xtn);
			    slv_fifo_h[0].get(slv_xtn);
                            pkt_rcvd++;
				if(mst_xtn.compare(slv_xtn))
				    begin
					    wr_xtn=mst_xtn;
					    rd_xtn=mst_xtn;
                                          pkt_cmprd++;
						write_cg.sample();
						read_cg.sample();
						if(mst_xtn.wvalid)
							begin
						            foreach(mst_xtn.wdata[i])
                                                                begin
							             write_cg1.sample(i);
                                                                end
							end
						if(mst_xtn.rvalid)
							begin
							    foreach(mst_xtn.rdata[i])
                                                               begin
							           read_cg1.sample(i);
                                                               end
							end 
					end
				else
				   `uvm_error("Scoreboard","Master and Slave Packet Mismatch");
			 end		    
	endtask


        function void sb::report_phase(uvm_phase phase);
            `uvm_info("SCOREBOARD",$sformatf("No. of packets received:%0d",pkt_rcvd),UVM_LOW);
            `uvm_info("SCOREBOARD",$sformatf("No. of packets compared:%0d",pkt_cmprd),UVM_LOW);
        endfunction

