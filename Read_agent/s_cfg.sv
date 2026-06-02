class slave_config extends uvm_object;
    `uvm_object_utils(slave_config)
    virtual axi_if sif;
    uvm_active_passive_enum is_active;
    int no_of_slave;
    extern function new(string name="slave_config");
endclass

    function slave_config::new(string name="slave_config");
        super.new(name);
    endfunction

