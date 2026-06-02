class m_agent extends uvm_agent;
    
	`uvm_component_utils(m_agent)


    m_driver m_drvh;
    m_monitor m_monh;
    ma_sequencer m_seqrh;
    master_config m_cfgh;



     function new(string name ="master_agent", uvm_component parent);
         super.new(name,parent);
     endfunction


     function void build_phase(uvm_phase phase);
	 
         if(!uvm_config_db #(master_config)::get(this," ","master_config",m_cfgh))
             `uvm_fatal("master_agent","no response from config, have you set it in env")

         m_monh=m_monitor::type_id::create("m_monh",this);
        
		 if(m_cfgh.is_active==UVM_ACTIVE)
             begin
                 m_drvh=m_driver::type_id::create("m_drvh",this);
                 m_seqrh=ma_sequencer::type_id::create("m_seqrh",this);
             end
			 
         super.build_phase(phase);
    endfunction

    function void connect_phase(uvm_phase phase);
        if(m_cfgh.is_active==UVM_ACTIVE)
            begin
                m_drvh.seq_item_port.connect(m_seqrh.seq_item_export);
            end
        super.connect_phase(phase);
    endfunction
 endclass

