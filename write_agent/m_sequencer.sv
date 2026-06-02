class ma_sequencer extends uvm_sequencer #(axi_xtn);

`uvm_component_utils(ma_sequencer)

extern function new(string name = "ma_sequencer", uvm_component parent);

endclass

function ma_sequencer::new(string name = "ma_sequencer", uvm_component parent);
super.new(name,parent);
endfunction
