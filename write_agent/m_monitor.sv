class m_monitor extends uvm_monitor;
    `uvm_component_utils(m_monitor)

	uvm_analysis_port#(axi_xtn) mst_mon_port;

    virtual axi_if.MST_MON mif;
    master_config mst_cfg_h;
  
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
        static int pkt_sent;	
	
    
    extern function new(string name = "m_monitor", uvm_component parent);
    extern function void build_phase(uvm_phase phase);
    extern function void connect_phase(uvm_phase phase);
	extern task run_phase(uvm_phase phase);
	extern task collect_data();
	extern task collect_awaddr();
	extern task collect_wdata(axi_xtn xtn);
	extern task collect_bresp();
	extern task collect_raddr();
	extern task collect_rdata(axi_xtn xtn);
    extern function void report_phase(uvm_phase phase); 
endclass: m_monitor

    function m_monitor::new(string name = "m_monitor", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void m_monitor::build_phase(uvm_phase phase);
        if(!uvm_config_db#(master_config)::get(this, "", "master_config", mst_cfg_h))
            `uvm_fatal("Master Driver", "getting config failed");
            super.build_phase(phase);
            mst_mon_port=new("mst_mon_port",this);
    endfunction

    function void m_monitor::connect_phase(uvm_phase phase);
        super.connect_phase(phase);
        mif=mst_cfg_h.mif; //copies interface handle from configuration object (m_cfg)to local handle(mif)
    endfunction
	
    task  m_monitor::run_phase(uvm_phase phase);
      
              forever
		collect_data();
    endtask
	
	task m_monitor::collect_data();
	fork
		begin
			sem_awc.get(1);  //acquire semaphore before collecting awdata
			collect_awaddr(); //collect address write data
			sem_awdc.put(1);  //indicates that awdata collection is done
			sem_awc.put(1);  //release semaphore for next transaction,put(1) on sem_awc might signal another thread like wdata thread to proceed
		end
		
		begin
			sem_awdc.get(1);  //wait until awdata is collected
			sem_wdc.get(1);   //acquire semaphore for wdata collection
			collect_wdata(q1.pop_front());  //wdata is collect fom q1 and sent to collect_wdata
			sem_wdc.put(1);   //release wdata sequence
			sem_wdrc.put(1);  //signal bresp to  proceed
		end
		
		begin
			sem_wdrc.get(1);  //wait until wdata is collected
			sem_wrc.get(1);   //acquire bresp semaphore
			collect_bresp();  //collect write response
			sem_wrc.put(1);    //release bresp semaphore
		end
		
		begin
			sem_arc.get(1);   //acquire semaphore for read address
			collect_raddr();  //collect read address data
			sem_arc.put(1);  //release read address semaphore
			sem_ardc.put(1); //signal the read data thread
		end
		
		begin
			sem_ardc.get(1);  //waits for read addr collection to complete
			sem_rdc.get(1);   //waits for ongoing rdata collection to finish
			collect_rdata(q2.pop_front());  //collects the next available read data
			sem_rdc.put(1);   //release the semaphore to allow next rdata transaction
		end
    
	join_any
      endtask
	
	task m_monitor::collect_awaddr();
	    xtn=axi_xtn::type_id::create("xtn");
		while(!mif.mst_mon_cb.awvalid) //monitor waits until awvalid asserted by master
		@(mif.mst_mon_cb);

		while(!mif.mst_mon_cb.awready)  //monitor waits until awready is asserted by slave
		@(mif.mst_mon_cb);	
		     xtn.awvalid= mif.mst_mon_cb.awvalid;  //copies wraddr signals into xtn object
		     xtn.awaddr = mif.mst_mon_cb.awaddr;
		     xtn.awsize = mif.mst_mon_cb.awsize;
		     xtn.awid = mif.mst_mon_cb.awid;
		     xtn.awlen=mif.mst_mon_cb.awlen;
		     xtn.awburst=mif.mst_mon_cb.awburst;
                  q1.push_back(xtn);  //captured xtn is pushed into q1
		mst_mon_port.write(xtn); //captured xtn is then pass to sb for verification
                pkt_sent++;  //incrementing a counter that keeps track of number of packets or transactions have been captured by monitor
                 `uvm_info("MST_MONITOR",$sformatf("printing from master monitor collect_awaddr \n %s", xtn.sprint()),UVM_LOW)
		@(mif.mst_mon_cb);
	endtask
	
	task m_monitor::collect_wdata(axi_xtn xtn);
	xtn1=axi_xtn::type_id::create("xtn1");
	xtn1=xtn;
	xtn.cal_addr();
	xtn1.wdata=new[xtn.awlen+1];
	xtn1.wstrb=new[xtn.wdata.size()];
		foreach(xtn1.wdata[i])  //loops for all data beats in transaction
			begin
			   while(!mif.mst_mon_cb.wvalid || !mif.mst_mon_cb.wready)
			@(mif.mst_mon_cb);

			    xtn1.wstrb[i]=mif.mst_mon_cb.wstrb;
				  if(mif.mst_mon_cb.wstrb==15)
					   xtn1.wdata[i]=mif.mst_mon_cb.wdata;

			          if(mif.mst_mon_cb.wstrb==8)
					   xtn1.wdata[i]=mif.mst_mon_cb.wdata[31:24];

				  if(mif.mst_mon_cb.wstrb==4)
					   xtn1.wdata[i]=mif.mst_mon_cb.wdata[23:16];

				  if(mif.mst_mon_cb.wstrb==2)
					   xtn1.wdata[i]=mif.mst_mon_cb.wdata[15:8];

				  if(mif.mst_mon_cb.wstrb==1)
					   xtn1.wdata[i]=mif.mst_mon_cb.wdata[7:0];

				  if(mif.mst_mon_cb.wstrb==7)
						 xtn1.wdata[i]=mif.mst_mon_cb.wdata[23:0];

				  if(mif.mst_mon_cb.wstrb==14)
						xtn1.wdata[i]=mif.mst_mon_cb.wdata[31:8];

				  if(mif.mst_mon_cb.wstrb==12)
						xtn1.wdata[i]=mif.mst_mon_cb.wdata[31:16];

				  if(mif.mst_mon_cb.wstrb==3)
						xtn1.wdata[i]=mif.mst_mon_cb.wdata[15:0];

				xtn1.wid=mif.mst_mon_cb.wid;
				xtn1.wlast=mif.mst_mon_cb.wlast;
                      xtn1.wvalid=mif.mst_mon_cb.wvalid;
				@(mif.mst_mon_cb);
			end
		       mst_mon_port.write(xtn1);
                       pkt_sent++;
                       `uvm_info("MST_MONITOR",$sformatf("printing from master monitor collect_wdata \n %s", xtn1.sprint()),UVM_LOW)
			
	endtask
	
	task m_monitor::collect_bresp();
	     xtn2=axi_xtn::type_id::create("xtn2");
	     while(!mif.mst_mon_cb.bready || !mif.mst_mon_cb.bvalid)
		@(mif.mst_mon_cb);
 //while(!mif.mst_mon_cb.bvalid)
		//@(mif.mst_mon_cb);

		 xtn2.bresp=mif.mst_mon_cb.bresp;
		 mst_mon_port.write(xtn2);
	        
                 pkt_sent++;
                 `uvm_info("MST_MONITOR",$sformatf("printing from master monitor collect_bresp \n %s", xtn2.sprint()),UVM_LOW)
		 @(mif.mst_mon_cb);
	endtask
	
	task m_monitor::collect_raddr();
	    xtn3=axi_xtn::type_id::create("xtn3");
		while(!mif.mst_mon_cb.arvalid || !mif.mst_mon_cb.arready)
		@(mif.mst_mon_cb);

//while(!mif.mst_mon_cb.arready)
//		@(mif.mst_mon_cb);

		     xtn3.arvalid= mif.mst_mon_cb.arvalid;
		     xtn3.araddr = mif.mst_mon_cb.araddr;
		     xtn3.arsize = mif.mst_mon_cb.arsize;
		     xtn3.arid = mif.mst_mon_cb.arid;
		     xtn3.arlen=mif.mst_mon_cb.arlen;
		     xtn3.arburst=mif.mst_mon_cb.arburst;
                     q2.push_back(xtn3);
		@(mif.mst_mon_cb);
		mst_mon_port.write(xtn3);
                pkt_sent++;
	      
               `uvm_info("MST_MONITOR",$sformatf("printing from master monitor collect_raddr \n %s", xtn3.sprint()),UVM_LOW)
	endtask
	
	task m_monitor::collect_rdata(axi_xtn xtn);
		xtn4=axi_xtn::type_id::create("xtn4");
		xtn4=xtn;
		xtn4.cal_raddr();
		xtn4.rdata=new[xtn.arlen+1];
		xtn4.rstrb=new[xtn.rdata.size()];
		xtn4.strb_rcal();
		foreach(xtn4.rdata[i])
			begin
			   while(!mif.mst_mon_cb.rvalid || !mif.mst_mon_cb.rready)
			@(mif.mst_mon_cb);

		              xtn4.rresp[i] = mif.mst_mon_cb.rresp;  //response signal is captured
			      if(xtn4.rstrb[i]==15)  //if rstrb is 4'b1111 the full rdata is stored
			         begin
                                    xtn4.rdata[i]=mif.mst_mon_cb.rdata;
                                 end
					  
			      if(xtn4.rstrb[i]==8)  //if rstrb is 4'b1000 data from[[31:24] is stored
                                 begin
			             xtn4.rdata[i] = mif.mst_mon_cb.rdata[31:24];
                                 end
					 
			      if(xtn4.rstrb[i]==4)
			         begin
			             xtn4.rdata[i]=mif.mst_mon_cb.rdata[23:16];
                                 end
					 
			      if(xtn4.rstrb[i]==2)
			         begin
				     xtn4.rdata[i]=mif.mst_mon_cb.rdata[15:8];
                                 end
					 
			      if(xtn4.rstrb[i]==1)
				 begin
				     xtn4.rdata[i]=mif.mst_mon_cb.rdata[7:0];
                                 end
					 
 
		              if(xtn4.rstrb[i]==14)
				 begin
				     xtn4.rdata[i]=mif.mst_mon_cb.rdata[31:8];
                                 end
					 
			      if(xtn4.rstrb[i]==12)
				 begin
				     xtn4.rdata[i]=mif.mst_mon_cb.rdata[31:16];
                                 end
					 
			      if(xtn4.rstrb[i]==3)
				 begin
				     xtn4.rdata[i]=mif.mst_mon_cb.rdata[15:0];
			         end
					 
			      xtn4.rid=mif.mst_mon_cb.rid;
			      xtn4.rlast=mif.mst_mon_cb.rlast;
                              xtn4.rvalid=mif.mst_mon_cb.rvalid;
			      @(mif.mst_mon_cb);
			end
			mst_mon_port.write(xtn4);
                        pkt_sent++;
                       `uvm_info("MST_MONITOR",$sformatf("printing from master monitor monitor_rdata \n %s", xtn4.sprint()),UVM_LOW)
		
	endtask


        function void m_monitor::report_phase(uvm_phase phase); 
            `uvm_info("MASTER MONITOR",$sformatf("no of packet sent are:%0d",pkt_sent),UVM_LOW);
        endfunction
