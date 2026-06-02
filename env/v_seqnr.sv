class virtual_sequencer extends uvm_sequencer #(uvm_sequence_item);
     `uvm_component_utils(virtual_sequencer)

     ma_sequencer mst_seqrh[];
     slave_sequencer slv_seqr_h[];

     env_config env_cfg_h;

     extern function new(string name="virtual_sequencer",uvm_component parent);
     extern function void build_phase(uvm_phase phase);
endclass

    function virtual_sequencer::new(string name="virtual_sequencer",uvm_component parent);
          super.new(name,parent);
    endfunction


    function void virtual_sequencer::build_phase(uvm_phase phase);
        super.build_phase(phase);
      if(!uvm_config_db#(env_config)::get(this,"","env_config",env_cfg_h))
              `uvm_fatal("router_virtual_sequencer","unable to get router_env_config, have you set it?")
      super.build_phase(phase);
      mst_seqrh=new[env_cfg_h.no_of_master];
      slv_seqr_h=new[env_cfg_h.no_of_slave];
    endfunction

