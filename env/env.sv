class env extends uvm_env;
    `uvm_component_utils(env) 
    env_config env_cfg_h;
    master_agent_top mst_agt_top;  
    slave_agent_top slv_agt_top;
    virtual_sequencer vseqr_h;
    sb sb_h;	


    	function new(string name="env",uvm_component parent);
	super.new(name,parent); 
	endfunction

    function void build_phase(uvm_phase phase);
if(!uvm_config_db#(env_config)::get(this,"","env_config",env_cfg_h))
`uvm_fatal("Env","Unable to get axi env config, have you set it in test?")
    
	if(env_cfg_h.has_master_agent) begin 
                uvm_config_db#(master_config)::set(this,"mst_agt_top*","master_config",env_cfg_h.mst_cfg_h);
                mst_agt_top=master_agent_top::type_id::create("mst_agt_top",this);
	    end

        if(env_cfg_h.has_slave_agent)
            begin
                uvm_config_db#(slave_config)::set(this,"slv_agt_top*","slave_config",env_cfg_h.slv_cfg_h);
                slv_agt_top=slave_agent_top::type_id::create("slv_agt_top",this);
            end

        if(env_cfg_h.has_virtual_sequencer)
            begin
            vseqr_h=virtual_sequencer::type_id::create("vseqr_h",this);
            end
        if(env_cfg_h.has_scoreboard)
            sb_h=sb::type_id::create("sb_h",this);

        super.build_phase(phase);

    endfunction

    function void connect_phase(uvm_phase phase);
        
	if(env_cfg_h.has_virtual_sequencer)
            begin
                if(env_cfg_h.has_master_agent)
                    begin
                        foreach(mst_agt_top.m_agth[i])
                            vseqr_h.mst_seqrh[i]=mst_agt_top.m_agth[i].m_seqrh;
                    end

                if(env_cfg_h.has_slave_agent)
                    begin
                        foreach(slv_agt_top.slv_agt_h[i])
                            vseqr_h.slv_seqr_h[i]=slv_agt_top.slv_agt_h[i].slv_seqr_h;
                    end				   					
            end
			
        if(env_cfg_h.has_scoreboard)
            begin
                foreach(mst_agt_top.m_agth[i])
                    mst_agt_top.m_agth[i].m_monh.mst_mon_port.connect(sb_h.mst_fifo_h[i].analysis_export);
                foreach(slv_agt_top.slv_agt_h[i])
                    slv_agt_top.slv_agt_h[i].slv_mon_h.slv_mon_port.connect(sb_h.slv_fifo_h[i].analysis_export);
            end   
     endfunction
endclass
