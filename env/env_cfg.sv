class env_config extends uvm_object;

    `uvm_object_utils(env_config);
    bit has_scoreboard=1;
    bit has_virtual_sequencer=1;                             
    bit has_slave_agent=1;
    bit has_master_agent=1;

    int no_of_master=1;
    int no_of_slave=1;

    master_config mst_cfg_h;
    slave_config slv_cfg_h;

    function new(string name="env_config");
        super.new(name);
    endfunction : new

endclass

