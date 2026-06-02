class base_seqs extends uvm_sequence #(uvm_sequence_item);
      `uvm_object_utils(base_seqs)

      env_config env_cfg_h;
      virtual_sequencer vseqr_h;

      ma_sequencer m_seqrh[];
      slave_sequencer slv_seqrh[];

      extern function new(string name="base_seqs");
      extern task body();
endclass


     function base_seqs::new(string name="base_seqs");
          super.new(name);
     endfunction

     task base_seqs::body();
         if(!uvm_config_db#(env_config)::get(null,get_full_name(),"env_config",env_cfg_h))
             `uvm_fatal("axi base sequence","Unable to get axi env config, have you set it?")
         assert($cast(vseqr_h,m_sequencer))
             else
                 `uvm_error("axi base seqs task body","ma_sequencer and axi sequencer are of different types")
         m_seqrh=new[env_cfg_h.no_of_master];
         slv_seqrh=new[env_cfg_h.no_of_slave];

         foreach(m_seqrh[i])
             m_seqrh=vseqr_h.mst_seqrh;

         foreach(slv_seqrh[i])
             slv_seqrh=vseqr_h.slv_seqr_h;
     endtask



class v_fixed extends base_seqs;
    `uvm_object_utils(v_fixed)

     master_seq_fixed m_seq;
     extern function new(string name="v_fixed");
     extern task body();
endclass

    function v_fixed::new(string name="v_fixed");
        super.new(name);
    endfunction

    task v_fixed::body();
        super.body();
        m_seq=master_seq_fixed::type_id::create("m_seq");
        fork
           m_seq.start(m_seqrh[0]);
        join
    endtask
	

class v_incr extends base_seqs;
    `uvm_object_utils(v_incr)

     master_seq_incr m_seq;
     extern function new(string name="v_incr");
     extern task body();
endclass

    function v_incr::new(string name="v_incr");
        super.new(name);
    endfunction

    task v_incr::body();
        super.body();
        m_seq=master_seq_incr::type_id::create("m_seq");
        fork
           m_seq.start(m_seqrh[0]);
        join
    endtask
	class v_wrap extends base_seqs;
    `uvm_object_utils(v_wrap)

     master_seq_wrap m_seq;
     extern function new(string name="v_wrap");
     extern task body();
endclass

    function v_wrap::new(string name="v_wrap");
        super.new(name);
    endfunction

    task v_wrap::body();
        super.body();
        m_seq=master_seq_wrap::type_id::create("m_seq");
        fork
           m_seq.start(m_seqrh[0]);
        join
    endtask
	
class v_random extends base_seqs;
    `uvm_object_utils(v_random)

     master_seq_random m_seq;
     extern function new(string name="v_random");
     extern task body();
endclass

    function v_random::new(string name="v_random");
        super.new(name);
    endfunction

    task v_random::body();
        super.body();
        m_seq=master_seq_random::type_id::create("m_seq");
        fork
           m_seq.start(m_seqrh[0]);
        join
    endtask


