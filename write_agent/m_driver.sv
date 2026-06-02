class m_driver extends uvm_driver#(axi_xtn);
    `uvm_component_utils(m_driver)

    virtual axi_if.MST_DRV mif;
    master_config mst_cfg_h;

    axi_xtn xtn;
        axi_xtn q1[$], q2[$],q3[$],q4[$],q5[$];
        semaphore sem_awc = new(1);  //semaphore for write address channel
        semaphore sem_wdc = new();  //semaphore for write data channel
        semaphore sem_wrc = new();  //semaphore for write response

    
       semaphore sem_arc = new(1); //semaphore for read address channel

       semaphore sem_rdc = new(); //sempahore for read data channel 

     //semaphores are used to control access and ensures synchronization b/w axi xtns
     //each semaphore is acquired (get(1)) before a xtn and release (put(1)) after completion

    extern function new(string name = "m_driver", uvm_component parent);
    extern function void build_phase(uvm_phase phase);
    extern function void connect_phase(uvm_phase phase);
        extern task  run_phase(uvm_phase phase);
        extern task drive(axi_xtn xtn);
        extern task drive_awaddr(axi_xtn xtn);
        extern task drive_wdata(axi_xtn xtn);
        extern task drive_bresp(axi_xtn xtn);

        extern task drive_raddr(axi_xtn xtn);
        extern task drive_rdata(axi_xtn xtn);
endclass: m_driver

    function m_driver::new(string name = "m_driver", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void m_driver::build_phase(uvm_phase phase);
        if(!uvm_config_db#(master_config)::get(this, "", "master_config", mst_cfg_h))
            `uvm_fatal("Master Driver", "getting config failed");
            super.build_phase(phase);
    endfunction

    function void m_driver::connect_phase(uvm_phase phase);
        super.connect_phase(phase);
     mif=mst_cfg_h.mif;
    endfunction

        task m_driver::run_phase(uvm_phase phase);
             
                forever
                begin
                        seq_item_port.get_next_item(req);
                        drive(req);
                        seq_item_port.item_done();
               		req.print();
                end
        endtask

        task m_driver::drive(axi_xtn xtn);
        q1.push_back(xtn);  //queue will follow first in first out manner the same transaction (xtn) is pushed to
        q2.push_back(xtn);  //q2,q3,q4 and q5 which means multiple components such as driver threads might access same transaction
        q3.push_back(xtn);  //if xtn is not cloned before pushing, all queues may reference the same object leads to unintended
        q4.push_back(xtn);  //modifications if xtns is altered later
	q5.push_back(xtn);
           fork
               begin
                        sem_awc.get(1);    //here wr_addr channel process start ensuring that wr_addr xtns happens at a time
                        drive_awaddr(q1.pop_front());     //wr_addr is retrived from q1 and sent to drive_awaddr
                        sem_wdc.put(1);   //wr_data is released signaling that wr_data can proceed for multiple transactions 
                        sem_awc.put(1);   //then awc is released so that it allows for another wr_addr transaction     
                end

               begin
                        sem_wdc.get(1);   //waits for wdc ensuring that wr_addr has been sent
                        drive_wdata(q2.pop_front());    //wr_data is retrived from q2 and sent to drive_wdata
                        sem_wrc.put(1);  //write response is released signaling that wr_rsp
                        sem_wdc.put(1);    //wdc is released 
                end

                begin
                        sem_wrc.get(1);      //wr_resp happens only after wr_data wrc.get ensuring that write data has been sent
                        drive_bresp(q3.pop_front());  //write response is retrived from q3 and sent to drive_bresp
                        sem_wrc.put(1);   //wrc is released
                end

                begin
                        sem_arc.get(1);     //ensuring that only one rd_addr transaction happens at a time waits for arc.get ensuring exclusive access 
                        drive_raddr(q4.pop_front());   //rd_addr is retrived from q4 and sent to drive_raddr
                        sem_rdc.put(1);     //rdc is released signaling that rd data can proceed
                        sem_arc.put(1);    //arc is released  ensure that is allows for another rd_addr transaction
                     end
                begin
                        sem_arc.get(1);      //waits for arc.get(1) ensuring rd_addr has been sent
                        drive_rdata(q5.pop_front());    //rd_data retrived from q5 and sent to drive_rdata
                        sem_arc.put(1);    //arc is released
                end  
           join_any
      endtask

//if you don't use get(1) before accessing a process it may execute at anytime leading to race conditions and incorrect behaviour
//if you don't use get(1) process will execute without waiting for correct order leading to protocol violations
//for ex: drive_wdata(q2.pop_front()) might execute before corresponding drive_awaddr(q1.pop_front()) breaking the axi write sequence
//if we use only get(1) but forget put(1) the process will block indefinitely coz semaphores will never released
//if we use only put(1) semaphores lose their purpose coz no process is waiting for access
//axi protocol ensures that wr_addr is sent before wr_data,wr_data is sent before receiving wr_resp 
   //rd_addr(ar) is sent before rd_data(r) semaphores helps in enforcing the correct order of transactions
        task m_driver::drive_awaddr(axi_xtn xtn);
                mif.mst_drv_cb.awvalid <= 1;  //indicating a valid wr_addr                       
                mif.mst_drv_cb.awaddr <= xtn.awaddr;
                mif.mst_drv_cb.awsize <= xtn.awsize;
                mif.mst_drv_cb.awid <= xtn.awid;
                mif.mst_drv_cb.awlen <= xtn.awlen;
                mif.mst_drv_cb.awburst <= xtn.awburst;

                @(mif.mst_drv_cb);  //after one clk delay task waits for awready signal from slave
                while(!mif.mst_drv_cb.awready)
		@(mif.mst_drv_cb);  //loop continuously waits until ready is high
                mif.mst_drv_cb.awvalid <= 0;  //once ready is high awvalid deasserts 

                repeat($urandom_range(1,5))
                        @(mif.mst_drv_cb);

        endtask

        task m_driver::drive_wdata(axi_xtn xtn);
 
        foreach(xtn.wdata[i]) //axi burst contain multiple data beats, task iterates over each data item in xtn.wdata
   
                        begin
                                mif.mst_drv_cb.wvalid <= 1;  //indicating there is a valid data
                                mif.mst_drv_cb.wdata <= xtn.wdata[i];   //wdata is sent from corresponding tn.wdata[i] beat
                                mif.mst_drv_cb.wstrb <= xtn.wstrb[i];   //wr_strb is set from xtn.strb[i] specifying valid byte lanes
                                mif.mst_drv_cb.wid <= xtn.wid;   //id is driven
                                if(i==(xtn.awlen))   //last beat is the awlen  if awlen=3 means transactions has 4 beats(awlen+1)
                                        mif.mst_drv_cb.wlast <= 1;  //last signal indicates only for the last data beat in a burst transaction
                                else
                                        mif.mst_drv_cb.wlast <= 0;

                                @(mif.mst_drv_cb);
                                while(!mif.mst_drv_cb.wready)
				@(mif.mst_drv_cb);
                                    mif.mst_drv_cb.wvalid <= 0;
                                    mif.mst_drv_cb.wlast <= 0;

                                repeat($urandom_range(1,5))   //
                                        @(mif.mst_drv_cb);
                        end

           endtask

        task m_driver::drive_bresp(axi_xtn xtn);
                 mif.mst_drv_cb.bready<=1;  //indicating master is ready to receive wr_resp from slave
           @(mif.mst_drv_cb)
           while(!mif.mst_drv_cb.bvalid)
		@(mif.mst_drv_cb);  //once handshaking process complete(bvalid & bready as high) bready is deasserted
              mif.mst_drv_cb.bready<=0;
           repeat($urandom_range(1,5))
               @(mif.mst_drv_cb);  //the delay indicates random cycles before moving to next transaction
        endtask

      task m_driver:: drive_raddr(axi_xtn xtn);
            repeat($urandom_range(1,5))
                  @(mif.mst_drv_cb);
           mif.mst_drv_cb.arid<=xtn.arid;     //here why non-blocking means mst drives signals to interface 
           mif.mst_drv_cb.arlen<=xtn.arlen;   //which ensures that all signals are updated simultaneously at the end of currrent
           mif.mst_drv_cb.arsize<=xtn.arsize; //simulation time which prevents race conditions 
           mif.mst_drv_cb.arburst<=xtn.arburst;  //mst initiates transaction so it must write values from transaction object to interface
           mif.mst_drv_cb.araddr<=xtn.araddr;  //which means taking data from xtn and assigning to interface
           mif.mst_drv_cb.arvalid<=1;   //mst fetches transaction details and drives them onto axibus               
                 @(mif.mst_drv_cb);
                  while(!mif.mst_drv_cb.arready)
		@(mif.mst_drv_cb);

                    mif.mst_drv_cb.arvalid<=0;
              repeat($urandom_range(1,5))
                    @(mif.mst_drv_cb);

           endtask

        task m_driver::drive_rdata(axi_xtn xtn);
         int mem[int];  //a local memory to store read data
          xtn.cal_raddr();
         xtn.strb_rcal();
           for(int i=0;i<(xtn.arlen+1);i++)
                 begin
                      mif.mst_drv_cb.rready<=1;   //indicates master is ready to receive read data
                      @(mif.mst_drv_cb);  //waits for any change in interface
                      while(!mif.mst_drv_cb.rvalid) //loop keeps checking until rvalid is asserted means that the slave has sent valid read data
		      @(mif.mst_drv_cb);
                                 
                                 if(xtn.rstrb[i]==15)  //rstrb == 4'b1111 means all 4 bytes(32 bits) are valid
                                         mem[xtn.raddr[i]]=mif.mst_drv_cb.rdata;  //entire read data stored in a memory

                                 if(xtn.rstrb[i]==8)
                                         mem[xtn.raddr[i]]=mif.mst_drv_cb.rdata[31:24];

                                  if(xtn.rstrb[i]==4)
                                         mem[xtn.raddr[i]]=mif.mst_drv_cb.rdata[23:16];

                                  if(xtn.rstrb[i]==2)
                                         mem[xtn.raddr[i]]=mif.mst_drv_cb.rdata[15:8];

                                  if(xtn.rstrb[i]==1)
                                         mem[xtn.raddr[i]]=mif.mst_drv_cb.rdata[7:0];

                                  if(xtn.rstrb[i]==14)   //for unaligned
                                         mem[xtn.raddr[i]]=mif.mst_drv_cb.rdata[31:8];

                                  if(xtn.rstrb[i]==12)
                                         mem[xtn.raddr[i]]=mif.mst_drv_cb.rdata[31:16];

                                  if(xtn.rstrb[i]==3)
                                         mem[xtn.raddr[i]]=mif.mst_drv_cb.rdata[15:0];
                                              mif.mst_drv_cb.rready<=0;
                        		 repeat($urandom_range(1,5))
                          			@(mif.mst_drv_cb);

                   end
             $displayh("master received address:%p",xtn.raddr);
             $displayh("memory received in master driver is %p",mem);

endtask


