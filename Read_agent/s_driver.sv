class slave_driver extends uvm_driver#(axi_xtn);
        `uvm_component_utils(slave_driver)

    virtual axi_if.SLV_DRV sif;
    slave_config slv_cfg_h;
    axi_xtn xtn,xtn1;
    axi_xtn q1[$],q2[$],q3[$];
    int count,ending;
        semaphore sem_wad = new(1); //semaphore for write address
        semaphore sem_wd = new(); // sempahore for write data
        semaphore sem_wr = new(); //semaphore for write response
        semaphore sem_ara = new(1); //semphore for read address
        semaphore sem_rd = new();   //semaphore for read data
  
    extern function new(string name = "slave_driver", uvm_component parent);
    extern function void build_phase(uvm_phase phase);
    extern function void connect_phase(uvm_phase phase);
    extern task  run_phase(uvm_phase phase);

    extern task drive();
    extern task read_awaddr(axi_xtn xtn);
    extern task read_data(axi_xtn xtn);
    extern task drive_wresp(axi_xtn xtn);

        extern task slave_rdata(axi_xtn xtn1);
        extern task slave_raddr();

endclass

    function slave_driver::new(string name = "slave_driver", uvm_component parent);
        super.new(name, parent);
    endfunction

    function void slave_driver::build_phase(uvm_phase phase);
        if(!uvm_config_db#(slave_config)::get(this,"","slave_config",slv_cfg_h))
            `uvm_fatal("slave Driver", "getting config failed");
            super.build_phase(phase);
    endfunction

    function void slave_driver::connect_phase(uvm_phase phase);
        super.connect_phase(phase);
      sif=slv_cfg_h.sif;
    endfunction

     task slave_driver::run_phase(uvm_phase phase);
          forever
                drive();
     endtask

         task slave_driver::drive();

       xtn=axi_xtn::type_id::create("xtn");
           fork
            begin
                   sem_wad.get(1);
                   read_awaddr(xtn);
                   sem_wd.put(1);
	           sem_wad.put(1);
                 end
                 begin
                        sem_wd.get(1);
                    read_data(q1.pop_front());
                        sem_wr.put(1);
                        sem_wd.put(1);
                 end
                  begin
                    sem_wr.get(1);
                    drive_wresp(q2.pop_front());
                    sem_wr.put(1);
                 end
               begin
                        sem_ara.get(1);
                        slave_raddr();
                        sem_rd.put(1);
                        sem_ara.put(1);
                end

                begin
                        sem_rd.get(1);
                        slave_rdata(q3.pop_front());
                        sem_rd.put(1);
                end
          join_any


         endtask

         task slave_driver::read_awaddr(axi_xtn xtn);
           
            repeat($urandom_range(1,5))
                    @(sif.slv_drv_cb);
                          sif.slv_drv_cb.awready<=1;  //indicates it's ready to receive address
                     @(sif.slv_drv_cb);
                 while(!sif.slv_drv_cb.awvalid) //slv waits until awvalid is asserted by mst
                     @(sif.slv_drv_cb);

                        xtn.awid=sif.slv_drv_cb.awid;  //in why blocking means slave is sampling signals from interface 
                        xtn.awlen=sif.slv_drv_cb.awlen; //it must capture values as soon as awvalid is asserted by mst
                        xtn.awsize=sif.slv_drv_cb.awsize;  //blocking ensures that values are updated immediately within same cycle
                        xtn.awburst=sif.slv_drv_cb.awburst;  //slv doesn't initiate transaction instead it waits for req and captures data
                        xtn.awvalid=sif.slv_drv_cb.awvalid;  //which means reading values from interface and sorting them in  transaction obj
                        xtn.awaddr=sif.slv_drv_cb.awaddr;   //slv observes axi bus extracts the values and storesthem in xtn 
                q1.push_back(xtn);  //captured xtns is pushed into q1 and q2
                q2.push_back(xtn);

          repeat($urandom_range(1,5))
                 @(sif.slv_drv_cb);
                 sif.slv_drv_cb.awready<=0;

         endtask

        task slave_driver::read_data(axi_xtn xtn);
           int mem[int];

	xtn=axi_xtn::type_id::create("xtn");

             xtn.cal_addr();

        $displayh("aligned:%h",xtn.aligned_addr);
           $displayh("addresses calculated in slave side are %p",xtn.addr);
          for(int i=0;i<(xtn.awlen+1);i++)
                 begin
                      sif.slv_drv_cb.wready<=1;
                      @(sif.slv_drv_cb);
                          while(!sif.slv_drv_cb.wvalid)
                      @(sif.slv_drv_cb);


            $display("slave driver start of awvalid");
                                  $display("wstrb in slave driver is:%p",sif.slv_drv_cb.wstrb);
                                 if(sif.slv_drv_cb.wstrb==15)
                                        mem[xtn.addr[i]]=sif.slv_drv_cb.wdata;

                               if(sif.slv_drv_cb.wstrb==8)
                                         mem[xtn.addr[i]]=sif.slv_drv_cb.wdata[31:24];

                                  if(sif.slv_drv_cb.wstrb==4)
                                         mem[xtn.addr[i]]=sif.slv_drv_cb.wdata[23:16];

                                  if(sif.slv_drv_cb.wstrb==2)
                                         mem[xtn.addr[i]]=sif.slv_drv_cb.wdata[15:8];

                                  if(sif.slv_drv_cb.wstrb==1)
                                         mem[xtn.addr[i]]=sif.slv_drv_cb.wdata[7:0];

   
                                  if(sif.slv_drv_cb.wstrb==14)
                                         mem[xtn.addr[i]]=sif.slv_drv_cb.wdata[31:8];

                                  if(sif.slv_drv_cb.wstrb==12)
                                         mem[xtn.addr[i]]=sif.slv_drv_cb.wdata[31:16];

                                  if(sif.slv_drv_cb.wstrb==3)
                                         mem[xtn.addr[i]]=sif.slv_drv_cb.wdata[15:0];



                           $displayh("value inside mem is: %p",mem[xtn.addr[i]]);
                           sif.slv_drv_cb.wready<=0;
                          repeat($urandom_range(1,5))
                          @(sif.slv_drv_cb);
                          count=1;
                   end
        
        endtask

        task slave_driver::drive_wresp(axi_xtn xtn);
	xtn=axi_xtn::type_id::create("xtn");
                          sif.slv_drv_cb.bvalid<=1;   //slv asserts bvalid indicating a valid write response
                          sif.slv_drv_cb.bresp<=0;    //if bresp is 0 then wr operation is successful
                          sif.slv_drv_cb.bid<=xtn.bid;
                         @(sif.slv_drv_cb);
                      while(!sif.slv_drv_cb.bready) //slv waits until mst asserts bready when bready is 1 mst has accepted wrt resp
                      @(sif.slv_drv_cb);
                         sif.slv_drv_cb.bvalid<=0;  //bvalid deasserts indicating resp is no longer valid
                          sif.slv_drv_cb.bresp<='hx;  //bresp is set to x to avoid driving stable values


         repeat($urandom_range(1,5))
                      @(sif.slv_drv_cb);
        endtask


          task slave_driver::slave_raddr();
            xtn1=axi_xtn::type_id::create("xtn");
            repeat($urandom_range(1,5))
                  @(sif.slv_drv_cb);
            sif.slv_drv_cb.arready <= 1;

            while(!sif.slv_drv_cb.arvalid)
                     @(sif.slv_drv_cb);
                   xtn1.arid=sif.slv_drv_cb.arid;
                   xtn1.arlen=sif.slv_drv_cb.arlen;
                   xtn1.arsize=sif.slv_drv_cb.arsize;
                   xtn1.arburst=sif.slv_drv_cb.arburst;
                   xtn1.arid=sif.slv_drv_cb.arid;

                  q3.push_back(xtn1);
                   repeat($urandom_range(1,5))
                    @(sif.slv_drv_cb);

            sif.slv_drv_cb.arready <= 0;

           endtask

        task slave_driver::slave_rdata(axi_xtn xtn1);
	int length;
	xtn1=axi_xtn::type_id::create("xtn1");
       length = xtn1.arlen;  //arlen determine no of beats in burst
        for(int i=0; i<length+1; i++)  
        begin
                sif.slv_drv_cb.rdata<= $urandom;

                sif.slv_drv_cb.rvalid<= 1;  //indicates valid rd data is available
                sif.slv_drv_cb.rid<= xtn1.arid;  //ensures resp id matches the req id
                sif.slv_drv_cb.rresp <= 0;   //indicates a successful read(okay) resp
                if(i==(length))
                        sif.slv_drv_cb.rlast <= 1; //rlast indicates end of burst
                else
                        sif.slv_drv_cb.rlast <= 0;

                @(sif.slv_drv_cb);
                while(!sif.slv_drv_cb.rready)  //slv waits for mst to assert rready which signals that mst is ready to accept the data
                     @(sif.slv_drv_cb);

                sif.slv_drv_cb.rvalid <= 0;  //marks rd data as invalid after mst accepts it
                sif.slv_drv_cb.rlast <= 0;   //reset the last beat flag
                sif.slv_drv_cb.rresp <= 'hz;  //avoid driving stable value
         
                repeat($urandom_range(1,5))
                  @(sif.slv_drv_cb);
               count=1;
        end

          endtask

