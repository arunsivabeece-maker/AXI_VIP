class slave_base_sequence extends uvm_sequence #(axi_xtn);

    `uvm_object_utils(slave_base_sequence)

    extern function new(string name="slave_base_sequence");

endclass : slave_base_sequence

    function slave_base_sequence::new(string name="slave_base_sequence");
        super.new(name);
    endfunction : new

class slave_seq1 extends slave_base_sequence;
`uvm_object_utils(slave_seq1)

    extern function new(string name="slave_seq1");
    extern task body();
endclass

function slave_seq1::new(string name = "slave_seq1");
super.new(name);
endfunction

task slave_seq1::body();
   begin
        req = axi_xtn::type_id::create("req");
        start_item(req);
        assert(req.randomize())
        finish_item(req);
  end
endtask

