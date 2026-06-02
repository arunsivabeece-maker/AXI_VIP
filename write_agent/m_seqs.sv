class master_base_sequence extends uvm_sequence #(axi_xtn);

    `uvm_object_utils(master_base_sequence);

    extern function new(string name="master_base_sequence");

endclass : master_base_sequence

    function master_base_sequence::new(string name="master_base_sequence");
        super.new(name);
    endfunction : new

class master_seq_fixed extends master_base_sequence;
`uvm_object_utils(master_seq_fixed);

    extern function new(string name="master_seq_fixed");
    extern task body();
endclass

    function master_seq_fixed::new(string name = "master_seq_fixed");
        super.new(name);
    endfunction

    task master_seq_fixed::body();
	     repeat(5)
			begin
				req = axi_xtn::type_id::create("req");
				start_item(req);
				assert(req.randomize()with{awburst==0;arburst==0;})
				finish_item(req);
			end 
    endtask
	
class master_seq_incr extends master_base_sequence;
`uvm_object_utils(master_seq_incr);

    extern function new(string name="master_seq_incr");
    extern task body();
endclass

    function master_seq_incr::new(string name = "master_seq_incr");
        super.new(name);
    endfunction

    task master_seq_incr::body();
	        repeat(5)
			begin
				req = axi_xtn::type_id::create("req");
				start_item(req);
				assert(req.randomize()with{awburst==1;arburst==1;})
				finish_item(req);
			end 
    endtask
	
class master_seq_wrap extends master_base_sequence;
`uvm_object_utils(master_seq_wrap);

    extern function new(string name="master_seq_wrap");
    extern task body();
endclass

    function master_seq_wrap::new(string name = "master_seq_wrap");
        super.new(name);
    endfunction

    task master_seq_wrap::body();
		repeat(5)
			begin
				req = axi_xtn::type_id::create("req");
				start_item(req);
				assert(req.randomize()with{awburst==2;arburst==2;})
				finish_item(req);
			end 
    endtask

class master_seq_random extends master_base_sequence;
`uvm_object_utils(master_seq_random);

    extern function new(string name="master_seq_random");
    extern task body();
endclass

    function master_seq_random::new(string name = "master_seq_random");
        super.new(name);
    endfunction

    task master_seq_random::body();
		repeat(50)
			begin
				req = axi_xtn::type_id::create("req");
				start_item(req);
				assert(req.randomize())
				finish_item(req);
			end 
		 repeat(50)
                        begin
                                req = axi_xtn::type_id::create("req");
                                start_item(req);
                                assert(req.randomize()with{awsize==0;arsize==0;})
                                finish_item(req);
                        end
		repeat(50)
                        begin
                                req = axi_xtn::type_id::create("req");
                                start_item(req);
                                assert(req.randomize()with{awsize==1;arsize==1;})
                                finish_item(req);
                        end

		repeat(50)
                        begin
                                req = axi_xtn::type_id::create("req");
                                start_item(req);
                                assert(req.randomize()with{awsize==2;arsize==2;})
                                finish_item(req);
                        end


    endtask

