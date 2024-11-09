interface alu_int;
  logic clk;
  logic rst;
  logic [1:0]oper;
  logic [3:0]in1,in2;
  logic [4:0]out;
endinterface

class transaction;
  bit clk;
  bit rst;
  rand bit [1:0]oper;
  rand bit [3:0]in1;
  rand bit [3:0]in2;
  bit [4:0]out;
  function void display(string name,bit rst=0,bit clk=0);
    $display("[%s] clk:%d rst:%d oper:%d in1:%d in2:%d out:%d",name,clk,rst,oper,in1,in2,out);
  endfunction
endclass

//GENERATOR
class generator;
  transaction trans;
  int count;
  mailbox gen2drv;
  event done;
  function new(mailbox gen2drv,event done);
    this.gen2drv=gen2drv;
    this.done=done;
  endfunction
  task run();
    begin
      repeat(count)
        begin
          trans=new();
          trans.randomize();
          gen2drv.put(trans);
          trans.display("GEN");
          #1;
          ->done;
          #55;
        end
    end
  endtask
endclass

//DRIVER
class driver;
  transaction trans;
  mailbox gen2drv;
  event done;
  event ready_mon;
  virtual alu_int inf;
  function new(mailbox gen2drv,event done,virtual alu_int inf,event ready_mon);
    this.gen2drv=gen2drv;
    this.done=done;
    this.ready_mon=ready_mon;
    this.inf=inf;
  endfunction
  task reset();
    begin
      inf.rst=1;
      @(posedge inf.clk);
      inf.rst=0;
      $display("DUT RESET DONE");
      $display("------------------------------------------------");
    end
  endtask
  task run();
    forever
      begin
        @(done);
        @(posedge inf.clk);
        trans=new();
        gen2drv.get(trans);
        inf.rst<=0;
        inf.in1<=trans.in1;
        inf.in2<=trans.in2;
        inf.oper<=trans.oper;
        trans.display("DRV",inf.rst,inf.clk);
        #2;
        ->ready_mon;
        #10;
      end
  endtask
endclass

//MONITOR
class monitor;
  transaction trans;
  mailbox mon2scb;
  virtual alu_int inf;
  event ready_mon;
  event ready_sco;
  function new(mailbox mon2scb,virtual alu_int inf,event ready_mon,event ready_sco);
    this.mon2scb=mon2scb;
    this.inf=inf;
    this.ready_mon=ready_mon;
    this.ready_sco=ready_sco;
  endfunction
  task run();
    forever
      begin
        @(ready_mon);
        #1;
        @(posedge inf.clk);
        trans=new();
        trans.rst=inf.rst;
        trans.in1=inf.in1;
        trans.in2=inf.in2;
        trans.oper=inf.oper;
        #1;
        trans.out=inf.out;
        mon2scb.put(trans);
        trans.display("MON",inf.rst,inf.clk);
        #10;
        ->ready_sco;
      end
  endtask
endclass
        
//SCOREBOARD
class scoreboard;
  transaction trans;
  mailbox mon2scb;
  event ready_sco;
  function new(mailbox mon2scb,event ready_sco);
    this.mon2scb=mon2scb;
    this.ready_sco=ready_sco;
  endfunction
  
  task run();
    forever
      begin
        @(ready_sco);
        trans=new();
        mon2scb.get(trans);
        if(trans.oper==0)
          begin
            if((trans.in1+trans.in2)==trans.out)
              begin
                $display("DATA MATCHED");
                $display("---------------------------------------------------------------------------------------------------------------------------------");
              end
            else
              $display("DATA MISMATCH");
          end
        else if(trans.oper==1)
          begin
            if((trans.in1*trans.in2)==trans.out)
              begin
                $display("DATA MATCHED");
                $display("---------------------------------------------------------------------------------------------------------------------------------");
              end
            else
              $display("DATA MISMATCH");
          end
        else if(trans.oper==2)
          begin
            if((trans.in1-trans.in2)==trans.out)
              begin
                $display("DATA MATCHED");
                $display("---------------------------------------------------------------------------------------------------------------------------------");
              end
            else
              $display("DATA MISMATCH");
          end
        else if(trans.oper==3)
          begin
            if((trans.in1/trans.in2)==trans.out)
              begin
                $display("DATA MATCHED");
                $display("---------------------------------------------------------------------------------------------------------------------------------");
              end
            else
              $display("DATA MISMATCH");
          end
      end
  endtask
endclass

//ENVIRONMENT
class environment;
  generator gen;
  driver drv;
  monitor mon;
  scoreboard sco;
  mailbox gen2drv;
  mailbox mon2scb;
  event done;
  event ready_mon;
  event ready_sco;
  function new(virtual alu_int inf);
    gen2drv=new();
    mon2scb=new();
    gen=new(gen2drv,done);
    drv=new(gen2drv,done,inf,ready_mon);
    mon=new(mon2scb,inf,ready_mon,ready_sco);
    sco=new(mon2scb,ready_sco);
  endfunction
  task pretest();
    drv.reset();
  endtask
  task main();
    fork
      gen.run();
      drv.run();
      mon.run();
      sco.run();
    join
  endtask
  task run();
    pretest();
    main();
  endtask  
endclass

module tb;
  environment env;
  alu_int inf();
  ALU dut(inf.oper,inf.rst,inf.clk,inf.in1,inf.in2,inf.out);
  initial
    begin
      inf.clk=0;
    end
  always
    #10 inf.clk=~inf.clk;
  initial
    begin
      env=new(inf);
      env.gen.count=10;
      env.run();
    end
  initial
    begin
      #570 $finish();
    end
endmodule
                        
