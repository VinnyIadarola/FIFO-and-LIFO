`default_nettype none

module stack #(
    parameter int DATA_WIDTH = 8,
    parameter int LIFO_SIZE  = 20
) (
    // Basic Inputs
    input  wire clk,
    input  wire rst_n,

    // Data Inputs
    input  wire [DATA_WIDTH-1:0] entry, 

    // Control Inputs
    input  wire insert, pop, // no edge detection will activate every cycle

    //Data Outputs
    output logic [DATA_WIDTH-1:0] head,

    // Control Outputs
    output logic full, empty
);

    localparam int LIFO_IDX_WIDTH = (LIFO_SIZE > 1) ? $clog2(LIFO_SIZE) : 1;  // 0..LIFO_SIZE-1

    /**********************************************************************
    ******                      Instantiations                       ******
    **********************************************************************/
    logic [LIFO_IDX_WIDTH-1:0] head_index;
    wire inc, dec;

    logic [DATA_WIDTH-1:0] lifo [0:LIFO_SIZE-1];
    wire [LIFO_IDX_WIDTH-1:0] write_idx;
    wire write_en;


    /**********************************************************************
    ******                    General Assignments                    ******
    **********************************************************************/
    assign full  = (head_index == LIFO_SIZE[LIFO_IDX_WIDTH-1:0]);
    assign empty = (head_index == '0);
    assign head  = lifo[head_index];



    /**********************************************************************
    ******                    Index Counter & Logic                  ******
    **********************************************************************/
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) 
            head_index <= '0;
        else
            head_index <= head_index + inc - dec;
    end


    assign inc =  insert & ~pop & ~full;   
    assign dec = ~insert &  pop & ~empty; 



    /**********************************************************************
    ******                       LIFO Register                       ******
    **********************************************************************/
    integer i;
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) 
            for (i = 0; i < LIFO_SIZE; i++) lifo[i] <= '0;
        else if (write_en) 
            lifo[write_idx] <= entry;
    end


    assign write_idx = (pop) ? head_index : head_index + 1'b1;
    assign write_en = insert | (~full | pop);



endmodule
`default_nettype wire
