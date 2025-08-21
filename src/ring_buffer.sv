`default_nettype none
module ring_buffer #(
    parameter int DATA_WIDTH = 8,
    parameter int FIFO_SIZE  = 20
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

    /**********************************************************************
    ******                       Localparams                        ******
    **********************************************************************/
    localparam int FIFO_IDX_WIDTH = (FIFO_SIZE > 1) ? $clog2(FIFO_SIZE)   : 1;  // 0..FIFO_SIZE-1
    localparam int FIFO_CNT_WIDTH = (FIFO_SIZE > 0) ? $clog2(FIFO_SIZE+1) : 1;  // 0..FIFO_SIZE



    /**********************************************************************
    ******                      Instantiations                       ******
    **********************************************************************/
    //Index Counter & Logic
    logic [FIFO_IDX_WIDTH-1:0] head_index;
    wire  [FIFO_IDX_WIDTH-1:0] nxt_head_idx;

    //Item Counter & Logic
    logic [FIFO_CNT_WIDTH-1:0] current_entries;
    wire                       inc, dec;

    //FIFO Register 
    logic [DATA_WIDTH-1:0]     fifo [0:FIFO_SIZE-1];
    wire  [FIFO_IDX_WIDTH-1:0] write_idx;
    wire  [FIFO_IDX_WIDTH:0]   sum; //1 larger to avoid overflow
    wire                       write_en;



    /**********************************************************************
    ******                    General Assignments                    ******
    **********************************************************************/
    assign full  = (current_entries == FIFO_SIZE[FIFO_CNT_WIDTH-1:0]);
    assign empty = (current_entries == '0);
    assign head  = fifo[head_index];


    /**********************************************************************
    ******                    Index Counter & Logic                  ******
    **********************************************************************/
    always_ff @(posedge clk or negedge rst_n) begin //I could just remove the rst and let it be but idk
        if (~rst_n) 
            head_index <= '0;
        else if (pop & ~empty) 
            head_index <= nxt_head_idx;
    end

    // wraps around if needed 
    assign nxt_head_idx = (head_index != FIFO_SIZE - 1'b1) ? head_index + 1'b1 : '0;



    /**********************************************************************
    ******                    Item Counter & Logic                   ******
    **********************************************************************/
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)
            current_entries <= '0;
        else 
            current_entries <= current_entries + inc - dec;
    end
    
    //insert and pop are in both to ensure nothing changes if they both are active
    assign inc =  insert & ~pop & ~full;
    assign dec = ~insert &  pop & ~empty;

          

    /**********************************************************************
    ******                       FIFO Register                       ******
    **********************************************************************/
    integer i;
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n)
            for (i = 0; i < FIFO_SIZE; i++) fifo[i] <= '0;
        else if (write_en)
            fifo[write_idx] <= entry;
    end


    assign write_en = insert & (~full | pop);
    // Psuedo modulo to avoid synthesis freaking out if theydont have it
    assign sum = head_index + current_entries[FIFO_IDX_WIDTH-1:0];
    assign write_idx = (sum >= FIFO_SIZE) ? sum - FIFO_SIZE : sum[FIFO_IDX_WIDTH-1:0];



endmodule
`default_nettype wire
