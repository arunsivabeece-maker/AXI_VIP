class slave_monitor extends uvm_monitor;
    `uvm_component_utils(slave_monitor)

        virtual axi_if.SLV_MON sif;
        slave_config slv_cfg_h;

        axi_xtn xtn,xtn1,xtn2,xtn3,xtn4;
        axi_xtn q1[$],q2[$];
        semaphore sem_awdc = new();
        semaphore sem_wdrc = new();
        semaphore sem_wdc = new(1);
        semaphore sem_awc = new(1);
        semaphore sem_wrc = new(1);

        semaphore sem_ardc = new();
        semaphore sem_arc = new(1);
        semaphore sem_rdc = new(1);


        uvm_analysis_port#(axi_xtn) slv_mon_port;

        extern function new(string name = "slave_monitor", uvm_component parent);
        extern function void build_phase(uvm_phase phase);
        extern function void connect_phase(uvm_phase phase);
        extern task run_phase(uvm_phase phase);
        extern task collect_data();
        extern task collect_awaddr();
        extern task collect_wdata(axi_xtn xtn);
        extern task collect_bresp();
        extern task collect_raddr();
        extern task collect_rdata(axi_xtn xtn);

endclass: slave_monitor

    function slave_monitor::new(string name = "slave_monitor", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void slave_monitor::build_phase(uvm_phase phase);
        if(!uvm_config_db#(slave_config)::get(this, "", "slave_config", slv_cfg_h))
            `uvm_fatal("slave Driver", "getting config failed");
            super.build_phase(phase);
            slv_mon_port=new("slv_mon_port",this);
    endfunction

    function void slave_monitor::connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        sif=slv_cfg_h.sif;
    endfunction

    task  slave_monitor::run_phase(uvm_phase phase);
               forever
                collect_data();
    endtask

        task slave_monitor::collect_data();
        fork
                begin
                        sem_awc.get(1);
                        collect_awaddr();
                        sem_awdc.put(1);
                        sem_awc.put(1);
                end

                begin
                        sem_awdc.get(1);
                        sem_wdc.get(1);
                        collect_wdata(q1.pop_front());
                        sem_wdc.put(1);
                        sem_wdrc.put(1);
                end

                begin
                        sem_wdrc.get(1);
                        sem_wrc.get(1);
                        collect_bresp();
                        sem_wrc.put(1);
                end

                begin
                        sem_arc.get(1);
                        collect_raddr();
                        sem_arc.put(1);
                        sem_ardc.put(1);
                end

                begin
                        sem_ardc.get(1);
                        sem_rdc.get(1);
                        collect_rdata(q2.pop_front());
                        sem_rdc.put(1);
                end

        join_any
      endtask

        task slave_monitor::collect_awaddr();
            xtn=axi_xtn::type_id::create("xtn");
                while(!sif.slv_mon_cb.awvalid || !sif.slv_mon_cb.awready)
		@(sif.slv_mon_cb);	

//while(!sif.slv_mon_cb.awready)
//		@(sif.slv_mon_cb);	
                     xtn.awvalid= sif.slv_mon_cb.awvalid;
                     xtn.awaddr = sif.slv_mon_cb.awaddr;
                     xtn.awsize = sif.slv_mon_cb.awsize;
                     xtn.awid = sif.slv_mon_cb.awid;
                     xtn.awlen=sif.slv_mon_cb.awlen;
                     xtn.awburst=sif.slv_mon_cb.awburst;
                  q1.push_back(xtn);
                slv_mon_port.write(xtn);
    
                 `uvm_info("slv_monitor",$sformatf("printing from slave monitor collect_awaddr \n %s", xtn.sprint()),UVM_LOW)
                @(sif.slv_mon_cb);
        endtask

        task slave_monitor::collect_wdata(axi_xtn xtn);
        xtn1=axi_xtn::type_id::create("xtn1");
        xtn1=xtn;
        xtn.cal_addr();
        xtn1.wdata=new[xtn.awlen+1];
        xtn1.wstrb=new[xtn.wdata.size()];
                foreach(xtn1.wdata[i])
                        begin
                           while(!sif.slv_mon_cb.wvalid || !sif.slv_mon_cb.wready)
	                	@(sif.slv_mon_cb);	

//while(!sif.slv_mon_cb.wready)
	        //        	@(sif.slv_mon_cb);	
                            xtn1.wstrb[i]=sif.slv_mon_cb.wstrb;
                                  if(sif.slv_mon_cb.wstrb==15)
                                           xtn1.wdata[i]=sif.slv_mon_cb.wdata;

                              if(sif.slv_mon_cb.wstrb==8)
                                           xtn1.wdata[i]=sif.slv_mon_cb.wdata[31:24];

                                  if(sif.slv_mon_cb.wstrb==4)
                                           xtn1.wdata[i]=sif.slv_mon_cb.wdata[23:16];

                                  if(sif.slv_mon_cb.wstrb==2)
                                           xtn1.wdata[i]=sif.slv_mon_cb.wdata[15:8];

                                  if(sif.slv_mon_cb.wstrb==1)
                                           xtn1.wdata[i]=sif.slv_mon_cb.wdata[7:0];

                                  if(sif.slv_mon_cb.wstrb==7)
                                                 xtn1.wdata[i]=sif.slv_mon_cb.wdata[23:0];

                                  if(sif.slv_mon_cb.wstrb==14)
                                                xtn1.wdata[i]=sif.slv_mon_cb.wdata[31:8];

                                  if(sif.slv_mon_cb.wstrb==12)
                                                xtn1.wdata[i]=sif.slv_mon_cb.wdata[31:16];

                                  if(sif.slv_mon_cb.wstrb==3)
                                                xtn1.wdata[i]=sif.slv_mon_cb.wdata[15:0];

                                xtn1.wid=sif.slv_mon_cb.wid;
                                xtn1.wlast=sif.slv_mon_cb.wlast;
                                xtn1.wvalid=sif.slv_mon_cb.wvalid;
                                @(sif.slv_mon_cb);
                        end
                        slv_mon_port.write(xtn1);
                       `uvm_info("slv_monitor",$sformatf("printing from slave monitor collect_wdata \n %s", xtn1.sprint()),UVM_LOW)
        
        endtask

        task slave_monitor::collect_bresp();
             xtn2=axi_xtn::type_id::create("xtn2");
             while(!sif.slv_mon_cb.bready)
		@(sif.slv_mon_cb);	

while(!sif.slv_mon_cb.bvalid)
		@(sif.slv_mon_cb);	
                 xtn2.bresp=sif.slv_mon_cb.bresp;
                 slv_mon_port.write(xtn2);
                 `uvm_info("slv_monitor",$sformatf("printing from slave monitor collect_bresp \n %s", xtn2.sprint()),UVM_LOW)
                 @(sif.slv_mon_cb);
        endtask

        task slave_monitor::collect_raddr();
            xtn3=axi_xtn::type_id::create("xtn3");
                while(!sif.slv_mon_cb.arvalid || !sif.slv_mon_cb.arready)
		@(sif.slv_mon_cb);	

//while(!sif.slv_mon_cb.arready)
//		@(sif.slv_mon_cb);	
                     xtn3.arvalid= sif.slv_mon_cb.arvalid;
                     xtn3.araddr = sif.slv_mon_cb.araddr;
                     xtn3.arsize = sif.slv_mon_cb.arsize;
                     xtn3.arid = sif.slv_mon_cb.arid;
                     xtn3.arlen=sif.slv_mon_cb.arlen;
                     xtn3.arburst=sif.slv_mon_cb.arburst;
                     q2.push_back(xtn3);
                @(sif.slv_mon_cb);
                slv_mon_port.write(xtn3);
               `uvm_info("slv_monitor",$sformatf("printing from slave monitor collect_raddr \n %s", xtn3.sprint()),UVM_LOW)
        endtask

        task slave_monitor::collect_rdata(axi_xtn xtn);
                xtn4=axi_xtn::type_id::create("xtn4");
                xtn4=xtn;
                xtn4.cal_raddr();
                xtn4.rdata=new[xtn.arlen+1];
                xtn4.rstrb=new[xtn.rdata.size()];
                xtn4.strb_rcal();
                foreach(xtn4.rdata[i])
                        begin
                           while(!sif.slv_mon_cb.rvalid || !sif.slv_mon_cb.rready)
			@(sif.slv_mon_cb);	

//while(!sif.slv_mon_cb.rready)
		//	@(sif.slv_mon_cb);	
                              xtn4.rresp[i] = sif.slv_mon_cb.rresp;
                              if(xtn4.rstrb[i]==15)
                                 begin
                                    xtn4.rdata[i]=sif.slv_mon_cb.rdata;
                                 end

                              if(xtn4.rstrb[i]==8)
                                 begin
                                     xtn4.rdata[i]=sif.slv_mon_cb.rdata[31:24];
                                 end

                              if(xtn4.rstrb[i]==4)
                                 begin
                                     xtn4.rdata[i]=sif.slv_mon_cb.rdata[23:16];
                                 end

                              if(xtn4.rstrb[i]==2)
                                 begin
                                     xtn4.rdata[i]=sif.slv_mon_cb.rdata[15:8];
                                 end

                              if(xtn4.rstrb[i]==1)
                                 begin
                                     xtn4.rdata[i]=sif.slv_mon_cb.rdata[7:0];
                                 end

                           
                              if(xtn4.rstrb[i]==14)
                                 begin
                                     xtn4.rdata[i]=sif.slv_mon_cb.rdata[31:8];
                                 end

                              if(xtn4.rstrb[i]==12)
                                 begin
                                     xtn4.rdata[i]=sif.slv_mon_cb.rdata[31:16];
                                 end

                              if(xtn4.rstrb[i]==3)
                                 begin
                                     xtn4.rdata[i]=sif.slv_mon_cb.rdata[15:0];
                                 end

                              xtn4.rid=sif.slv_mon_cb.rid;
                              xtn4.rlast=sif.slv_mon_cb.rlast;
                              xtn4.rvalid=sif.slv_mon_cb.rvalid;
                              @(sif.slv_mon_cb);
                        end
                        slv_mon_port.write(xtn4);
                       `uvm_info("slv_monitor",$sformatf("printing from slave monitor monitor_rdata \n %s", xtn4.sprint()),UVM_LOW)
               
        endtask

