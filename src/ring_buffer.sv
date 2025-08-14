`default_nettype none

module ring_buffer #(
    parameter int DATA_WIDTH = 8,
    parameter int FIFO_SIZE  = 20
) (
    // Basic Inputs
    input  wire clk,
    input  wire rst_n,

    // Data Inputs
    input  wire [DATA_WIDTH-1:0] entry, //The data to be inputt

    // Control Inputs
    input  wire insert, pop, // no edge detection will activate every cycle

    //Data Outputs
    output logic [DATA_WIDTH-1:0] head,

    // Control Outputs
    output logic full, empty
);

    localparam int FIFO_IDX_W   = (FIFO_SIZE > 1) ? $clog2(FIFO_SIZE)   : 1;  // 0..FIFO_SIZE-1
    localparam int FIFO_COUNT_W = (FIFO_SIZE > 0) ? $clog2(FIFO_SIZE+1) : 1;  // 0..FIFO_SIZE

    /**********************************************************************
    ******                      Instantiations                       ******
    **********************************************************************/
    logic [DATA_WIDTH-1:0]   fifo [0:FIFO_SIZE-1];

    //Index Tracking
    logic [FIFO_IDX_W-1:0]   head_index;
    logic [FIFO_IDX_W-1:0]   new_entry_index;
    logic [FIFO_COUNT_W-1:0] current_entries;


    /**********************************************************************
    ******                    General Assignments                    ******
    **********************************************************************/
    assign full  = (current_entries == FIFO_SIZE[FIFO_COUNT_W-1:0]);
    assign empty = (current_entries == '0);
    assign head  = fifo[head_index];



    always_comb begin
        //for further reference automatic stops it from being static (like C) and will be a temp varaible for scope
        automatic logic [FIFO_IDX_W:0] sum = head_index + current_entries[FIFO_IDX_W-1:0];

        new_entry_index = (sum >= FIFO_SIZE) ? sum - FIFO_SIZE : sum[FIFO_IDX_W-1:0];
    end

    /**********************************************************************
    ******                    Index Counter & Logic                  ******
    **********************************************************************/
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            head_index <= '0;
        end else if (pop & ~empty) begin
            head_index <= (head_index != FIFO_size - 1'b1) ? head_index +1'b1 : '0;
        end
    end

    /**********************************************************************
    ******                 Total items Index Counter                 ******
    **********************************************************************/
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            current_entries <= '0;
        end else begin
            case ({insert & ~full, pop & ~empty})
                2'b10: current_entries <= current_entries + 1'b1; // insert only
                2'b01: current_entries <= current_entries - 1'b1; // pop only
                default: current_entries <= current_entries; // either we do nothing or inserting and popping
            endcase
        end
    end

    /**********************************************************************
    ******                       FIFO Register                       ******
    **********************************************************************/
    integer i;
    always_ff @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            for (i = 0; i < FIFO_SIZE; i++) fifo[i] <= '0;
        end else if (insert & (~full | pop)) begin
            fifo[new_entry_index] <= entry;
        end
    end



endmodule

`default_nettype wire
