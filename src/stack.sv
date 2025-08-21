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
    output logic [DATA_WIDTH-1:0] top,

    // Control Outputs
    output logic full, empty
);

    localparam int LIFO_IDX_WIDTH = (LIFO_SIZE > 1) ?   $clog2(LIFO_SIZE) : 1;  // 0..LIFO_SIZE-1
    localparam int LIFO_CNT_WIDTH = (LIFO_SIZE > 1) ? $clog2(LIFO_SIZE+1) : 1;  // 0..LIFO_SIZE


    /**********************************************************************
    ******                      Instantiations                       ******
    **********************************************************************/
    logic [LIFO_IDX_WIDTH-1:0] head_index;
    logic [LIFO_CNT_WIDTH-1:0]      count;
    wire                         inc, dec;

    logic     [DATA_WIDTH-1:0] lifo [0:LIFO_SIZE-1];
    wire  [LIFO_IDX_WIDTH-1:0] write_idx;
    wire                        write_en;


    /**********************************************************************
    ******                    General Assignments                    ******
    **********************************************************************/
    assign full       = (count == LIFO_SIZE[LIFO_CNT_WIDTH-1:0]);
    assign empty      = (count == '0);

    assign head_index = (~empty) ? (count - 1'b1)   : '0; // Ensures we dont underflow and go out of bounds
    assign top        =  lifo[head_index] ;




    /**********************************************************************
    ******                    Index Counter & Logic                  ******
    **********************************************************************/
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) 
            count <= '0;
        else 
            count <= count + inc - dec;
    end

    //insert and pop appear in both to ensure if we do both at the same time nothing changes
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



    assign write_en = insert & (~full | pop);
    assign write_idx = (pop) ? head_index : count;

    





endmodule
`default_nettype wire
