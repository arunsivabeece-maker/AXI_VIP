class axi_xtn extends uvm_sequence_item;
    `uvm_object_utils(axi_xtn);

	//Write address channel
        rand bit [3:0] awid;
        rand bit [31:0] awaddr;
        rand bit [7:0] awlen;//[3:0] only four bits for axi3
        rand bit [2:0] awsize;
        rand bit [1:0] awburst;
        logic awready;
        bit awvalid;           

        //Write Data Channel
        rand bit [3:0] wid;
        rand bit [31:0] wdata[];
        bit [3:0] wstrb[];
        bit wlast;
        bit wvalid;
        logic wready;

        //Write Response Channel
        rand bit [3:0] bid;
        bit [1:0] bresp;
        bit bvalid;
        logic bready;

	//read address channel
        rand bit [3:0] arid;
        rand bit [31:0] araddr;
        rand bit [7:0] arlen;
        rand bit [2:0] arsize;
        rand bit [1:0] arburst;     
        logic arready;
        bit arvalid;

	//read data channel
        rand bit [3:0] rid;
        rand bit [31:0] rdata[];
        bit[1:0] rresp;
        bit rlast;
        logic rready;
        bit rvalid;



       //LOCAL VARIABLES
        bit [31:0]addr[];
        int no_of_bytes;
        int aligned_addr;
        int start_addr;


        bit [3:0]rstrb[];
        bit [31:0]raddr[];
        int no_of_rdbytes;
        int aligned_raddr;
        int start_raddr;



        constraint wdac        {wdata.size()==(awlen+1);}     //wdata size should be length+1
        constraint ardac       {rdata.size()==(arlen+1);}    //same for rdata
        constraint awb         {awburst dist{0:=10,1:=10,2:=10};}  
	constraint arb         {arburst dist{0:=10,1:=10,2:=10};} 
        constraint write_id_c  {awid == wid; bid==wid;}      //All the id's should be equal
        constraint read_id_c   {rid == arid;}
        constraint aws  {awsize dist{0:=10,1:=10,2:=10};} 
        constraint ar  {arsize dist{0:=10,1:=10,2:=10};}
 //
        
constraint c1   {((awburst == 2'b10) && awsize == 1) -> awaddr%2 == 0;} //alignment for wrap type of transfer                                                                          
 constraint c2  {(awburst == 2'b10 && awsize == 2) -> awaddr%4 == 0;}       
constraint c3   {(arburst == 2'b10 && arsize == 1) -> araddr%2 == 0;} //alignment for wrap       
constraint c4   {(arburst == 2'b10 && arsize == 2) -> araddr%4 == 0;}       
constraint c5   {awaddr<4096;}    //4kb boundary
        
constraint c6   {araddr<4096;}    //Can be excluded

constraint c7 { awlen inside {[0:15]};}
constraint c8 {arlen inside {[0:15]};}

        function new(string name = "axi_xtn");
                super.new(name);
        endfunction:new

        function void post_randomize();
           wstrb=new[awlen+1];
           rstrb=new[arlen+1];
           cal_addr();
           strb_cal();                                                                                      
           cal_raddr();
	   strb_rcal();
        endfunction

        function void cal_addr();
            bit wb;
            int burst_length=awlen+1;
               // int N=burst_length;
	//	int nb = (no_of_bytes*burst_length);
                int wrap_boundary=(int'(awaddr/(no_of_bytes*burst_length)))*(no_of_bytes*burst_length);
                int addr_n=wrap_boundary+(no_of_bytes*burst_length);
	//	$display("===================================================nnnnnnnnnnnbbbbbbbbbbbbbbbbbbbbb %d",nb);
                addr=new[awlen+1];
                addr[0]=awaddr;

                no_of_bytes=2**awsize;
                aligned_addr= (int'(awaddr/no_of_bytes))*no_of_bytes;
                start_addr=awaddr;
      
                for(int i=1;i<(burst_length+1);i++)
                   begin
                      if(awburst==0)
                           addr[i]=awaddr;

                      if(awburst==1)
                           begin
                               addr[i]=aligned_addr+(i)*no_of_bytes;
                           end

                      if(awburst==2)
                           begin
                               if(wb==0)
                                   begin
                                       addr[i]=aligned_addr+(i)*no_of_bytes;
                                       if(addr[i]==(wrap_boundary+(no_of_bytes*burst_length)))
                                       begin
                                           addr[i]=wrap_boundary;
                                           wb++;
                                       end
                                   end

                               else
                                   addr[i]=start_addr+((i)*no_of_bytes)-(no_of_bytes*burst_length);
                           end
                  end
        endfunction

        function void strb_cal();
        int data_bus_bytes=4;
        int lower_byte_lane,upper_byte_lane;


        int lower_byte_lane_0=start_addr-((int'(start_addr/data_bus_bytes))*data_bus_bytes);
        int upper_byte_lane_0=(aligned_addr+(no_of_bytes-1))-((int'(start_addr/data_bus_bytes))*data_bus_bytes);


        for(int j=lower_byte_lane_0;j<=upper_byte_lane_0;j++)
        begin
                wstrb[0][j]=1;
        end


        for(int i=1;i<(awlen+1);i++)
                begin
                                lower_byte_lane=addr[i]-(int'(addr[i]/data_bus_bytes))*data_bus_bytes;
                                        upper_byte_lane=lower_byte_lane+no_of_bytes-1;
                                        for(int j=lower_byte_lane;j<=upper_byte_lane;j++)
                                                wstrb[i][j]=1;
            end
        endfunction

        function void cal_raddr();
          	bit wb;
           	int burst_length=arlen+1;
                int N=burst_length;
                int wrap_boundary=(int'(araddr/(no_of_rdbytes*burst_length)))*(no_of_rdbytes*burst_length);
                int raddr_n=wrap_boundary+(no_of_rdbytes*burst_length);
                raddr=new[arlen+1];
                raddr[0]=araddr;


                no_of_rdbytes=2**arsize;
                aligned_raddr= (int'(araddr/no_of_rdbytes))*no_of_rdbytes;
                start_raddr=araddr;


                for(int i=2;i<(burst_length+1);i++)
                   begin
                      if(arburst==0)
                           raddr[i-1]=araddr;

                      if(arburst==1)
                           begin
                               raddr[i-1]=aligned_raddr+(i-1)*no_of_rdbytes;
                           end

                      if(arburst==2)
                           begin
                               if(wb==0)
                                   begin
                                       raddr[i-1]=aligned_raddr+(i-1)*no_of_rdbytes;
                                       if(raddr[i-1]==(wrap_boundary+(no_of_rdbytes*burst_length)))
                                       begin
                                           raddr[i-1]=wrap_boundary;
                                           wb++;
                                       end
                                   end

                               else
                                   raddr[i-1]=start_raddr+((i-1)*no_of_rdbytes)-(no_of_rdbytes*burst_length);
                           end
                  end
        endfunction

        function void strb_rcal();
        int data_bus_bytes=4;
        int lower_byte_lane,upper_byte_lane;


        int lower_byte_lane_0=start_raddr-((int'(start_raddr/data_bus_bytes))*data_bus_bytes);
        int upper_byte_lane_0=(aligned_raddr+(no_of_rdbytes-1))-((int'(start_raddr/data_bus_bytes))*data_bus_bytes);


        for(int j=lower_byte_lane_0;j<=upper_byte_lane_0;j++)
        begin
                rstrb[0][j]=1;
        end


        for(int i=1;i<(arlen+1);i++)
                begin
                                lower_byte_lane=raddr[i]-(int'(raddr[i]/data_bus_bytes))*data_bus_bytes;
                                        upper_byte_lane=lower_byte_lane+no_of_rdbytes-1;
                                        for(int j=lower_byte_lane;j<=upper_byte_lane;j++)
                                                rstrb[i][j]=1;
            end
        endfunction



         function void  do_print (uvm_printer printer); 
                super.do_print(printer);
                printer.print_field( "awid",                this.awid,         04,           UVM_DEC);
                printer.print_field( "awaddr",              this.awaddr,       32,           UVM_HEX);
                printer.print_field( "awlen",               this.awlen,        04,           UVM_DEC);
                printer.print_field( "awsize",              this.awsize,       03,           UVM_DEC);
                printer.print_field( "awburst",             this.awburst,      02,           UVM_DEC);
                 printer.print_field( "wid",                this.wid,          04,           UVM_DEC);
                foreach(this.wdata[i])
                    begin
                printer.print_field( "wdata",               this.wdata[i],     32 ,          UVM_HEX);
                printer.print_field( "wstrb",               this.wstrb[i],     4,            UVM_BIN);
                printer.print_field( "wlast",               this.wlast,        1,            UVM_DEC);
                    end
                printer.print_field( "bid",                 this.bid,          04,           UVM_DEC);
                printer.print_field( "bresp",               this.bresp,        02,           UVM_DEC);
                printer.print_field( "arid",                this.arid,         04,           UVM_DEC);
                printer.print_field( "araddr",              this.araddr,       32,           UVM_HEX);
                printer.print_field( "arlen",               this.arlen,        08,           UVM_DEC);
                printer.print_field( "arsize",              this.arsize,       03,           UVM_DEC);
                printer.print_field( "arburst",             this.arburst,      02,           UVM_DEC);
                printer.print_field( "rid",                 this.rid,          04,           UVM_DEC);
                foreach(this.rdata[i])
                    begin
                printer.print_field( "rdata",               this.rdata[i],     32,           UVM_HEX);
                printer.print_field( "rresp",               this.rresp[i],     02,           UVM_DEC);
                    end
         endfunction:do_print


////////////////////////////////////////////////////Compare_Method//////////////////////////////////////////////////////////
function bit do_compare (uvm_object rhs,uvm_comparer comparer);
     axi_xtn rhs_;
    if(!$cast(rhs_,rhs))
                begin
                 `uvm_fatal("do_compare","failed")
                  return 0;
                end
         return super.do_compare(rhs,comparer) &&
        awid==rhs_.awid  &&
        awaddr==rhs_.awaddr &&
        awlen==rhs_.awlen &&
        awsize==rhs_.awsize &&
        awburst==rhs_.awburst &&

        wid==rhs_.wid &&
        wdata==rhs_.wdata &&
        wstrb==rhs_.wstrb &&
        bid==rhs_.bid &&
        bresp==rhs_.bresp &&

        arid==rhs_.arid  &&
        araddr==rhs_.araddr &&
        arlen==rhs_.arlen &&
        arsize==rhs_.arsize &&
        arburst==rhs_.arburst &&

        rid==rhs_.rid &&
        rdata==rhs_.rdata &&
        rresp==rhs_.rresp;

endfunction

endclass



