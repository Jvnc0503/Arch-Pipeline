module testbench;
  reg          clk;
  reg          reset;
  wire [31:0]  WriteData;
  wire [31:0]  DataAdr;
  wire         MemWrite;
  
  // instantiate device to be tested
  top dut(
    .clk(clk), 
    .reset(reset), 
    .WriteData(WriteData), 
    .DataAdr(DataAdr), 
    .MemWrite(MemWrite)
  );

  // initialize test
  initial begin
    reset = 1; # 22;
    reset = 0;
  end

  // generate clock to sequence tests
  always begin
    clk = 1; # 5; 
    clk = 0; # 5;
  end

  // check results
  always @(negedge clk) begin
    if(MemWrite) begin
      if(DataAdr === 100 & WriteData === 15) begin
        $display("¡EXITO! El Pipeline Base funciona perfecto.");
        $finish;
      end else if (DataAdr !== 0) begin // ¡NUEVO! Ignora las escrituras en la dir 0
        $display("Fallo: Escribio %d en la direccion %d", WriteData, DataAdr);
        $finish;
      end
    end
  end
endmodule