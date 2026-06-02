module top;

import uvm_pkg::*;

import axi_pkg::*;

bit clk;

always #5 clk= ~clk;

axi_if axi_if0(clk);

initial
	begin
			`ifdef VCS
         		$fsdbDumpvars(0,top);
        		`endif	

	uvm_config_db #(virtual axi_if)::set(null,"*","axi_if",axi_if0);
	run_test();

	end

endmodule
