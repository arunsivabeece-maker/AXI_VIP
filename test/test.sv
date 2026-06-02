class test extends uvm_test;


    `uvm_component_utils(test)

    env_config env_cfg_h;
    master_config mst_cfg_h;
    slave_config slv_cfg_h;

    int no_of_master=1;
    int no_of_slave=1;

    bit has_master_agent=1;
    bit has_slave_agent=1;
    bit has_scoreboard=1;
        bit has_virtual_sequencer=1;
    env env_h;


    extern function new(string name="test",uvm_component parent);
    extern function void build_phase(uvm_phase phase);
    extern function void end_of_elaboration();
endclass

    function test::new(string name="test",uvm_component parent);
        super.new(name,parent);
    endfunction

    function void test::build_phase(uvm_phase phase);

         env_cfg_h=env_config::type_id::create("env_cfg_h");
         if(has_master_agent)
             begin
                 mst_cfg_h=master_config::type_id::create("mst_cfg_h");
                 mst_cfg_h.is_active=UVM_ACTIVE;
                 if(!uvm_config_db #(virtual axi_if)::get(this,"","axi_if",mst_cfg_h.mif))
                     `uvm_fatal("test","Unable to get axi interface, have you set it?")
                 env_cfg_h.mst_cfg_h=mst_cfg_h;
             end

        if(has_slave_agent)
            begin
                slv_cfg_h=slave_config::type_id::create("slv_cfg_h");
                slv_cfg_h.is_active=UVM_ACTIVE;
                if(!uvm_config_db #(virtual axi_if)::get(this,"","axi_if",slv_cfg_h.sif))
                    `uvm_fatal("test","Unable to get axi interface, have you set it?")
                env_cfg_h.slv_cfg_h=slv_cfg_h;
            end
         env_cfg_h.has_master_agent=has_master_agent;
         env_cfg_h.has_slave_agent=has_slave_agent;
         env_cfg_h.has_scoreboard=has_scoreboard;
         slv_cfg_h.no_of_slave=no_of_slave;
         mst_cfg_h.no_of_master=no_of_master;
         uvm_config_db#(env_config)::set(this,"*","env_config",env_cfg_h);
         super.build_phase(phase);
         env_h=env::type_id::create("env_h",this);
    endfunction

function void test:: end_of_elaboration();
	uvm_top.print_topology();
endfunction

class fixed_test extends test;
    `uvm_component_utils(fixed_test)
    v_fixed vseq;
    extern function new(string name="fixed_test",uvm_component parent);
    extern function void  build_phase(uvm_phase phase);
    extern task run_phase(uvm_phase phase);
endclass

    function fixed_test::new(string name="fixed_test",uvm_component parent);
        super.new(name,parent);
    endfunction

    function void fixed_test::build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction

    task fixed_test::run_phase(uvm_phase phase);
        phase.raise_objection(this);
            vseq=v_fixed::type_id::create("vseq");
            vseq.start(env_h.vseqr_h);
          #2000;
        phase.drop_objection(this);
    endtask
	
class incr_test extends test;
    `uvm_component_utils(incr_test)
    v_incr vseq;
    extern function new(string name="incr_test",uvm_component parent);
    extern function void  build_phase(uvm_phase phase);
    extern task run_phase(uvm_phase phase);
endclass

    function incr_test::new(string name="incr_test",uvm_component parent);
        super.new(name,parent);
    endfunction

    function void incr_test::build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction

    task incr_test::run_phase(uvm_phase phase);
        phase.raise_objection(this);
            vseq=v_incr::type_id::create("vseq");
            vseq.start(env_h.vseqr_h);
           #2000;
        phase.drop_objection(this);
    endtask

class wrap_test extends test;
    `uvm_component_utils(wrap_test)
    v_wrap vseq;
    extern function new(string name="wrap_test",uvm_component parent);
    extern function void  build_phase(uvm_phase phase);
    extern task run_phase(uvm_phase phase);
endclass

    function wrap_test::new(string name="wrap_test",uvm_component parent);
        super.new(name,parent);
    endfunction

    function void wrap_test::build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction

    task wrap_test::run_phase(uvm_phase phase);
        phase.raise_objection(this);
            vseq=v_wrap::type_id::create("vseq");
            vseq.start(env_h.vseqr_h);
           #2000;
        phase.drop_objection(this);
    endtask
	
	
class random_test extends test;
    `uvm_component_utils(random_test)
    v_random vseq;
    extern function new(string name="random_test",uvm_component parent);
    extern function void  build_phase(uvm_phase phase);
    extern task run_phase(uvm_phase phase);
endclass

    function random_test::new(string name="random_test",uvm_component parent);
        super.new(name,parent);
    endfunction

    function void random_test::build_phase(uvm_phase phase);
        super.build_phase(phase);
    endfunction

    task random_test::run_phase(uvm_phase phase);
        phase.raise_objection(this);
            vseq=v_random::type_id::create("vseq");
            vseq.start(env_h.vseqr_h);
           #2000;
        phase.drop_objection(this);
    endtask


