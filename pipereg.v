module pipereg(
    input  wire        clk,
    input  wire        reset, 
    input  wire        en,    // Stall
    input  wire        clr,   // Flush
    input  wire [31:0] d,     // Dato que entra (de la etapa anterior)
    output reg  [31:0] q      // Dato que sale (hacia la etapa actual)
);

    always @(posedge clk or posedge reset) begin
        if (reset) begin
            q <= 32'b0; 
        end else if (clr) begin
            q <= 32'b0;     // Flush, pone todo 0's
        end else if (en) begin
            q <= d;         // Avanza de manera normal
        end
        // Si 'en' es 0 y 'clr' es 0, no entra a ningún lado.
        // El registro mantiene su valor produciendo un stall.
    end

endmodule