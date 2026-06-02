interface axi_if(input logic clock);

    //Declaration of Write Address Channel Signals
    logic aresetn;
	logic [3:0] awid;     //awaddr,awid,awsize,awlength,awvalid,awready,awburst
	logic [31:0] awaddr;
	logic [7:0] awlen;
	logic [2:0] awsize;
	logic [1:0] awburst;
	bit awvalid; 
	bit awready;         // comes from slave
	
	//Declaration of Write Data Channel Signals
	logic  [3:0] wid;   //wdata,wid,wstrb,wlast,wvalid,wready
	logic [31:0] wdata;
	logic [3:0] wstrb;
	bit wlast;
	bit wvalid;
	bit wready;         //from slave
	
	//Declaration of Write Response Channel Signals
	logic [3:0] bid;      //bid,bresp,bvalid,bready
	logic [1:0] bresp;   //after awaddr and wdata slave will process wrt transa. and slave sends bresp along with bvalid 
	bit bvalid;
	bit bready;  //comes from master
	
	//Declaration of Read Address Channel Signals
	logic [3:0] arid;        //araddr,arid,arsize,arlength,arvalid,arready,arburst
	logic [31:0] araddr;    //master iniitiates rd transa. alomg with arvalid 
	logic [7:0] arlen;
	logic [2:0] arsize;
	logic [1:0] arburst;
	bit arvalid;
	bit arready;       //from slave when its ready to accept rd address
	
	//Declaration of Read Data Channel Signals
	logic [3:0] rid;          //rdata,rid,rresp,rlast,rvalid,rready
	logic [31:0] rdata;
	logic [1:0] rresp;        //slave senfds rdata also rresp indicates read was success  and master checks rresp
	bit rlast;
	bit rvalid;
	bit rready;         //comes from master
	
	
	//Master Driver Clocking Block
	clocking mst_drv_cb@(posedge clock);
	    default input #1 output #1;
		
		//input signals from Write Address Channel
		input awready;
		//input signals from Write Data Channel
		input wready;
		//input signals from Write Response Channel
		input bid,bresp,bvalid;
		//input signals from Read Address Channel
		input arready;
		//input signals from Read Data Channel
		input rid,rdata,rresp,rlast,rvalid;
		
		//output from Write Address Channel
		output aresetn, awid,awaddr,awlen,awsize,awburst,awvalid;
		//ouput from Write Data Channel
		output wid,wdata,wstrb,wlast,wvalid;
		//output from Write Response Channel
		output bready;
		//output from Read Address Channel
		output arid,araddr,arlen,arsize,arburst,arvalid;
		//output from Read Data Channel
		output rready;  
	endclocking
	
	
	//Master Monitor Clocking Block
	clocking mst_mon_cb@(posedge clock);
	    default input #1 output #1;
		
		//input signals from Write Address Channel
		input aresetn, awid,awaddr,awlen,awsize,awburst,awvalid,awready;
		//input signals from Write Data Channel
		input wid,wdata,wstrb,wlast,wvalid,wready;
		//input signals from Write Response Channel
		input bid,bresp,bvalid,bready;
		//input signals from Read Address Channel
		input arid,araddr,arlen,arsize,arburst,arvalid,arready;
		//input signals from Read Data Channel
		input rid,rdata,rresp,rlast,rvalid,rready;
	endclocking
	
	//Slave Driver Clocking Block
	clocking slv_drv_cb@(posedge clock);
	    default input #1 output #1;
		
		//input from Write Address Channel
		input aresetn, awid,awaddr,awlen,awsize,awburst,awvalid;
		//ouput from Write Data Channel
		input wid,wdata,wstrb,wlast,wvalid;
		//input from Write Response Channel
		input bready;
		//input from Read Address Channel
		input arid,araddr,arlen,arsize,arburst,arvalid;
		//input from Read Data Channel
		input rready;
		
		//output signals from Write Address Channel
		output awready;
		//output signals from Write Data Channel
		output wready;
		//output signals from Write Response Channel
		output bid,bresp,bvalid;
		//output signals from Read Address Channel
		output arready;
		//output signals from Read Data Channel
		output rid,rdata,rresp,rlast,rvalid;
	endclocking
	
		//Slave Monitor Clocking Block
	clocking slv_mon_cb@(posedge clock);
	    default input #1 output #1;
		
		//input signals from Write Address Channel
		input aresetn, awid,awaddr,awlen,awsize,awburst,awvalid,awready;
		//input signals from Write Data Channel
		input wid,wdata,wstrb,wlast,wvalid,wready;
		//input signals from Write Response Channel
		input bid,bresp,bvalid,bready;
		//input signals from Read Address Channel
		input arid,araddr,arlen,arsize,arburst,arvalid,arready;
		//input signals from Read Data Channel
		input rid,rdata,rresp,rlast,rvalid,rready;
	endclocking
	
	
	modport MST_DRV(clocking mst_drv_cb);
	modport MST_MON(clocking mst_mon_cb);
	modport SLV_DRV(clocking slv_drv_cb);
	modport SLV_MON(clocking slv_mon_cb);





      property AWVALID;
      @(posedge clock) $rose(awvalid) |-> $stable(awid) && $stable (awlen) && $stable (awburst) && $stable (awsize) && (awaddr) until awready[->1];
      endproperty
      
     property VALID;
     @(posedge clock) $rose(wvalid) |-> $stable(wid) && $stable(wdata) && $stable (wstrb) && $stable(wlast) until wready[->1];
     endproperty
  
 
   property ARVALID;
    @(posedge clock) $rose(arvalid) |-> $stable(arid) && $stable (arlen) && $stable (arburst) && $stable (arsize) && (araddr) until arready[->1];
   endproperty


   assert property (AWVALID);
   assert property (VALID);
   assert property (ARVALID);

 property BVALID;
    @(posedge clock) $rose(bvalid) |-> $stable(bid) && $stable (bresp) until bready[->1];
    endproperty
 
      
   property RVALID;
    @(posedge clock) $rose(rvalid) |-> $stable(rid) && $stable (rdata) && $stable (rlast)  && (rresp) until rready[->1];
   endproperty

   assert property (BVALID);
   assert property (RVALID);



   property AWVALID_AWREADY;
   @(posedge clock) awvalid && !awready |=> awvalid;
   endproperty 
   
   property WVALID_WREADY;
   @(posedge clock) wvalid && !wready |=> wvalid;
   endproperty 
   
   property ARVALID_ARREADY;
   @(posedge clock) arvalid && !arready |=> arvalid;
   endproperty 


   assert property (AWVALID_AWREADY);
   assert property (WVALID_WREADY);
   assert property (ARVALID_ARREADY);

   property BVALID_BREADY;
   @(posedge clock) bvalid && !bready |=> bvalid;
   endproperty 


   property RVALID_RREADY;
   @(posedge clock) rvalid && !rready |=> rvalid;
   endproperty 

   assert property (BVALID_BREADY);
   assert property (RVALID_RREADY);
//wrapping type unaligned address not happen
property R_wrap_type;
 @(posedge clock) (arburst==2)|->(arsize==1) |-> araddr%2==0;
endproperty

property R_wrap_type1;
 @(posedge clock)  (arburst==2)|->(arsize==2) |-> araddr%4==0;
endproperty

property W_wrap_type;
 @(posedge clock)  (awburst==2)|->(awsize==1) |-> awaddr%2==0;
endproperty 

property W_wrap_type1;
 @(posedge clock) (awburst==2)|-> (awsize==2) |-> awaddr%4==0;
endproperty

assert property (R_wrap_type);
assert property (R_wrap_type1);
assert property (W_wrap_type);
assert property (W_wrap_type1);

property ar_size;
@(posedge clock) awvalid |-> (awsize<3);
endproperty

property aw_size;
@(posedge clock) arvalid |-> (arsize<3);
endproperty

assert property (ar_size);
assert property (aw_size);


property W_burst_type_wrap;
 @(posedge clock) (awburst==2)|-> ((awlen==1)||(awlen==3)||(awlen==7)||(awlen==15));
endproperty

property R_burst_type_wrap;
 @(posedge clock) (arburst==2)|-> ((arlen==1)||(arlen==3)||(arlen==7)||(arlen==15));
endproperty

assert property (R_burst_type_wrap);
assert property (W_burst_type_wrap);


property WBURST;
 @(posedge clock) awvalid |-> (awburst!==3);
endproperty

property RBURST;
 @(posedge clock) arvalid |-> (arburst!==3);
endproperty

assert property (WBURST);
assert property (RBURST);

property WLAST;
@(posedge clock) wlast |-> (wvalid)&&(!wready) |=> wvalid;
endproperty

property RLAST;
@(posedge clock) rlast |-> (rvalid)&&(!rready) |=> rvalid;
endproperty

assert property (WLAST);
assert property (RLAST);
	
endinterface

