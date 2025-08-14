`default_nettype none
import testing_pkg::*;

module ring_buffer_tb;

/**************************************************************************
***                            Pre Suite Setup                          ***
**************************************************************************/
parameter int SUITE = 2;

// Shared basic inputs
logic clk;
logic rst_n;

// Clock
always #5 clk = ~clk;

/**************************************************************************
***                              Test Suites                            ***
**************************************************************************/

/**************************************************************************
***                              Test Suite 1                           ***
**************************************************************************/
generate if (SUITE == 1) begin : SUITE1

    /****************************
    ***  Width = 8  Size = 5  ***
    ****************************/
    localparam int DATA_WIDTH = 8;
    localparam int FIFO_SIZE  = 5;

    //Inputs
    logic  [DATA_WIDTH-1:0] entry;
    logic                   insert, pop;

    //Outputs (signed to match checkValues8 ref formal)
    logic signed [DATA_WIDTH-1:0] head;
    logic                         full, empty;

    /**************************************************************************
    ***                            Device Under Testing                     ***
    **************************************************************************/
    ring_buffer #(
        .DATA_WIDTH (DATA_WIDTH),
        .FIFO_SIZE  (FIFO_SIZE)
    ) iDUT (
        // Basic Inputs
        .clk        (clk),
        .rst_n      (rst_n),

        // Data Inputs
        .entry      (entry),

        // Control Inputs
        .insert     (insert),
        .pop        (pop),

        // Data Outputs
        .head       (head),

        // Control Outputs
        .full       (full),
        .empty      (empty)
    );

    // Helper task: checks head/full/empty together with a single test number
    task automatic checkQueueState (
        // Clock signal
        ref  logic                         clk,
        // Watching
        ref  logic signed [DATA_WIDTH-1:0] head,
        ref  logic                         full,
        ref  logic                         empty,
        // Expected
        input logic       [DATA_WIDTH-1:0] exp_head,
        input logic                         exp_full,
        input logic                         exp_empty,
        input real                          test_num
    );
        fork
            // Head test (8-bit)
            checkValues8(
                .refclk     (clk),
                .sig2watch  (head),
                .testnum    (test_num),
                .valHold    (1'b1),
                .clks2wait  (1),
                .goal_value (exp_head)
            );

            // Full test (1-bit)
            checkValues1(
                .refclk     (clk),
                .sig2watch  (full),
                .testnum    (test_num),
                .valHold    (1'b1),
                .clks2wait  (1),
                .goal_value (exp_full)
            );

            // Empty test (1-bit)
            checkValues1(
                .refclk     (clk),
                .sig2watch  (empty),
                .testnum    (test_num),
                .valHold    (1'b1),
                .clks2wait  (1),
                .goal_value (exp_empty)
            );
        join
    endtask

    initial begin
        clk    = 1'b0;

        // Test 1.0: On reset head='0, full=0, empty=1
        rst_n  = 1'b0;
        insert = 1'bx;
        pop    = 1'bx;
        entry  = 8'hxx;

        checkQueueState(
            .test_num (1.0),
            .clk      (clk),
            .head     (head),
            .full     (full),
            .empty    (empty),
            .exp_head (8'h00),
            .exp_full (1'b0),
            .exp_empty(1'b1)
        );

        @(posedge clk);
        rst_n = 1'b1;

        // Test 2.0: Insert one entry (0xFF)
        @(negedge clk);
        insert = 1'b1;
        pop    = 1'b0;
        entry  = 8'hFF;

        fork // turn off insert so we only get one entry
            checkQueueState(
                .test_num (2.0),
                .clk      (clk),
                .head     (head),
                .full     (full),
                .empty    (empty),
                .exp_head (8'hFF),
                .exp_full (1'b0),
                .exp_empty(1'b0)
            );
            @(negedge clk) insert = 1'b0;
        join

        // Test 3.0: Pop the single entry (head goes to next unit value)
        @(negedge clk);
        insert = 1'b0;
        pop    = 1'b1;
        entry  = 8'hEE; 

        fork // pop exactly one entry
            checkQueueState(
                .test_num (3.0),
                .clk      (clk),
                .head     (head),
                .full     (full),
                .empty    (empty),
                .exp_head (8'h00),
                .exp_full (1'b0),
                .exp_empty(1'b1)
            );
            @(negedge clk) pop = 1'b0;
        join

        // Test 4.x: Fill to max (FF,EE,DD,CC,BB) then pop down step-by-step
        @(negedge clk);
        insert = 1'b1; pop = 1'b0; entry = 8'hFF;
        @(negedge clk) entry = 8'hEE;
        @(negedge clk) entry = 8'hDD;
        @(negedge clk) entry = 8'hCC;
        @(negedge clk) entry = 8'hBB;

        fork
            checkQueueState(
                .test_num (4.0),
                .clk      (clk),
                .head     (head),
                .full     (full),
                .empty    (empty),
                .exp_head (8'hFF),
                .exp_full (1'b1),
                .exp_empty(1'b0)
            );
            @(negedge clk) insert = 1'b0; // stop inserting
        join

        // 1st pop -> head EE
        @(negedge clk) pop = 1'b1;
        fork
            checkQueueState(
                .test_num (4.1),
                .clk      (clk),
                .head     (head),
                .full     (full),
                .empty    (empty),
                .exp_head (8'hEE),
                .exp_full (1'b0),
                .exp_empty(1'b0)
            );
            @(negedge clk) pop = 1'b0;
        join

        // 2nd pop -> head DD
        @(negedge clk) pop = 1'b1;
        fork
            checkQueueState(
                .test_num (4.2),
                .clk      (clk),
                .head     (head),
                .full     (full),
                .empty    (empty),
                .exp_head (8'hDD),
                .exp_full (1'b0),
                .exp_empty(1'b0)
            );
            @(negedge clk) pop = 1'b0;
        join

        // 3rd pop -> head CC
        @(negedge clk) pop = 1'b1;
        fork
            checkQueueState(
                .test_num (4.3),
                .clk      (clk),
                .head     (head),
                .full     (full),
                .empty    (empty),
                .exp_head (8'hCC),
                .exp_full (1'b0),
                .exp_empty(1'b0)
            );
            @(negedge clk) pop = 1'b0;
        join

        // 4th pop -> head BB
        @(negedge clk) pop = 1'b1;
        fork
            checkQueueState(
                .test_num (4.4),
                .clk      (clk),
                .head     (head),
                .full     (full),
                .empty    (empty),
                .exp_head (8'hBB),
                .exp_full (1'b0),
                .exp_empty(1'b0)
            );
            @(negedge clk) pop = 1'b0;
        join

        // 5th pop -> becomes empty (head remains wraps to previous head but empty)
        @(negedge clk) pop = 1'b1;
        fork
            checkQueueState(
                .test_num (4.5),
                .clk      (clk),
                .head     (head),
                .full     (full),
                .empty    (empty),
                .exp_head (8'hFF),
                .exp_full (1'b0),
                .exp_empty(1'b1)
            );
            @(negedge clk) pop = 1'b0;
        join

        // Test 5.x: Full should not allow overwrite (keep head=AA while full)
        @(negedge clk);
        insert = 1'b1; pop = 1'b0; entry = 8'hAA;
        @(posedge full);
        @(negedge clk);
        entry = 8'h00; // attempt to overwrite while full
        repeat (20) @(negedge clk);

        checkQueueState(
            .test_num (5.0),
            .clk      (clk),
            .head     (head),
            .full     (full),
            .empty    (empty),
            .exp_head (8'hAA),
            .exp_full (1'b1),
            .exp_empty(1'b0)
        );

        // Drain exactly FIFO_SIZE entries; empty must assert
        @(negedge clk) begin insert = 1'b0; pop = 1'b1; end
        checkValues8(.refclk(clk), .sig2watch(head), .testnum(5.1), .valHold(1'b1), .clks2wait(1), .goal_value(8'hAA));
        checkValues8(.refclk(clk), .sig2watch(head), .testnum(5.2), .valHold(1'b1), .clks2wait(1), .goal_value(8'hAA));
        checkValues8(.refclk(clk), .sig2watch(head), .testnum(5.3), .valHold(1'b1), .clks2wait(1), .goal_value(8'hAA));
        checkValues8(.refclk(clk), .sig2watch(head), .testnum(5.4), .valHold(1'b1), .clks2wait(1), .goal_value(8'hAA));
        checkValues8(.refclk(clk), .sig2watch(head), .testnum(5.5), .valHold(1'b1), .clks2wait(1), .goal_value(8'hAA));
        @(negedge clk) pop = 1'b0;

        checkValues1(
            .refclk     (clk),
            .sig2watch  (empty),
            .testnum    (5.6),
            .valHold    (1'b1),
            .clks2wait  (1),
            .goal_value (1'b1)
        );

        print_all_passed_banner();
        $stop();
    end

end endgenerate

/**************************************************************************
***                              Test Suite 2                           ***
**************************************************************************/
generate if (SUITE == 2) begin : SUITE2

    /****************************
    ***  Width = 16 Size = 20 ***
    ****************************/
    localparam int DATA_WIDTH = 16;
    localparam int FIFO_SIZE  = 20;

    // DUT I/O (scoped to this suite)
    logic  [DATA_WIDTH-1:0] entry;
    logic                   insert, pop;
    logic signed [DATA_WIDTH-1:0] head;   // signed to match check ref
    logic                   full, empty;

    /**************************************************************************
    ***                            Device Under Testing                     ***
    **************************************************************************/
    ring_buffer #(
        .DATA_WIDTH (DATA_WIDTH),
        .FIFO_SIZE  (FIFO_SIZE)
    ) iDUT2 (
        .clk        (clk),
        .rst_n      (rst_n),
        .entry      (entry),
        .insert     (insert),
        .pop        (pop),
        .head       (head),
        .full       (full),
        .empty      (empty)
    );

    // Helper task (Suite 2): 16-bit head + flags
    task automatic checkQueueState16 (
        ref  logic                         clk,
        ref  logic signed [DATA_WIDTH-1:0] head,
        ref  logic                         full,
        ref  logic                         empty,
        input logic       [DATA_WIDTH-1:0] exp_head,
        input logic                         exp_full,
        input logic                         exp_empty,
        input real                          test_num
    );
        fork
            checkValues16(
                .refclk     (clk),
                .sig2watch  (head),
                .testnum    (test_num),
                .valHold    (1'b1),
                .clks2wait  (1),
                .goal_value (exp_head)
            );

            checkValues1(
                .refclk     (clk),
                .sig2watch  (full),
                .testnum    (test_num),
                .valHold    (1'b1),
                .clks2wait  (1),
                .goal_value (exp_full)
            );

            checkValues1(
                .refclk     (clk),
                .sig2watch  (empty),
                .testnum    (test_num),
                .valHold    (1'b1),
                .clks2wait  (1),
                .goal_value (exp_empty)
            );
        join
    endtask

    initial begin
        // >>> Declarations must precede statements in older vlog <<<
        int j;
        logic [DATA_WIDTH-1:0] exp_words [0:2]; // expected heads after first 3 pops
        // >>> End declarations <<<

        clk = 1'b0;

        // Test 1.0: Reset behavior on larger config
        rst_n  = 1'b0;
        insert = 1'bx;
        pop    = 1'bx;
        entry  = 'hx;

        checkQueueState16(
            .test_num  (1.0),
            .clk       (clk),
            .head      (head),
            .full      (full),
            .empty     (empty),
            .exp_head  (16'h0000),
            .exp_full  (1'b0),
            .exp_empty (1'b1)
        );

        @(posedge clk);
        rst_n = 1'b1;

        // Test 2.0: Single insert (0x1234) -> head must be 0x1234
        @(negedge clk);
        insert = 1'b1; 
        pop    = 1'b0; 
        entry  = 16'h1234;

        fork
            checkQueueState16(
                .test_num  (2.0),
                .clk       (clk),
                .head      (head),
                .full      (full),
                .empty     (empty),
                .exp_head  (16'h1234),
                .exp_full  (1'b0),
                .exp_empty (1'b0)
            );
            @(negedge clk) insert = 1'b0;
        join

        // Test 3.0: Pop that entry -> empty=1, head goes to unit val 0
        @(negedge clk);
        insert = 1'b0; 
        pop    = 1'b1;

        fork
            checkQueueState16(
                .test_num  (3.0),
                .clk       (clk),
                .head      (head),
                .full      (full),
                .empty     (empty),
                .exp_head  (16'h0000),
                .exp_full  (1'b0),
                .exp_empty (1'b1)
            );
            @(negedge clk) pop = 1'b0;
        join

        // Test 4.x: Fill many entries, confirm full, then partial drain checks
        // Sequence: AA00, BB11, CC22, DD33, EE44, ...
        @(negedge clk);
        insert = 1'b1; 
        pop    = 1'b0;
        entry  = 16'hAA00; @(negedge clk);
        entry  = 16'hBB11; @(negedge clk);
        entry  = 16'hCC22; @(negedge clk);
        entry  = 16'hDD33; @(negedge clk);
        entry  = 16'hEE44; @(negedge clk);

        // Bulk fill remaining to reach full for FIFO_SIZE=20
        for (integer i = 5; i < FIFO_SIZE; i++) begin
            entry = {8'hF0 + i[7:0], 8'h50 + i[7:0]}; // varying MSB/LSB
            @(negedge clk);
        end

        fork
            checkQueueState16(
                .test_num  (4.0),
                .clk       (clk),
                .head      (head),
                .full      (full),
                .empty     (empty),
                .exp_head  (16'hAA00), // first pushed
                .exp_full  (1'b1),
                .exp_empty (1'b0)
            );
            @(negedge clk) insert = 1'b0;
        join

        // Drain first 3 entries and check each head
        exp_words[0] = 16'hBB11;
        exp_words[1] = 16'hCC22;
        exp_words[2] = 16'hDD33;

        for (j = 0; j < 3; j++) begin
            @(negedge clk) pop = 1'b1;
            fork
                checkQueueState16(
                    .test_num  (4.1 + j/10.0), // 4.1, 4.2, 4.3
                    .clk       (clk),
                    .head      (head),
                    .full      (full),
                    .empty     (empty),
                    .exp_head  (exp_words[j]),
                    .exp_full  (1'b0), // not full after first pop
                    .exp_empty (1'b0)
                );
                @(negedge clk) pop = 1'b0;
            join
        end

        // Drain completely and confirm empty=1 at the end
        @(negedge clk) pop = 1'b1;
        repeat (FIFO_SIZE - 3 - 1) @(negedge clk); // already popped 3, pop is asserted now
        @(negedge clk) pop = 1'b0;

        checkValues1(
            .refclk     (clk),
            .sig2watch  (empty),
            .testnum    (4.9),
            .valHold    (1'b1),
            .clks2wait  (1),
            .goal_value (1'b1)
        );

        // Test 5.x: While full, further inserts must not overwrite
        @(negedge clk);
        insert = 1'b1; 
        pop    = 1'b0;
        // Fill to full with constant 0x77AA pattern
        for (int i2 = 0; i2 < FIFO_SIZE; i2++) begin
            entry = 16'h77AA;
            @(negedge clk);
        end

        fork
            checkQueueState16(
                .test_num  (5.0),
                .clk       (clk),
                .head      (head),
                .full      (full),
                .empty     (empty),
                .exp_head  (16'h77AA),
                .exp_full  (1'b1),
                .exp_empty (1'b0)
            );
            @(negedge clk) insert = 1'b0;
        join

        // Try to "overwrite" while full with 0x0055 (should be ignored by DUT)
        @(negedge clk);
        insert = 1'b1; 
        entry  = 16'h0055;
        repeat (3) @(negedge clk);
        insert = 1'b0;

        checkQueueState16(
            .test_num  (5.1),
            .clk       (clk),
            .head      (head),
            .full      (full),
            .empty     (empty),
            .exp_head  (16'h77AA), // unchanged
            .exp_full  (1'b1),
            .exp_empty (1'b0)
        );

        // Drain everything, confirm empty
        @(negedge clk) pop = 1'b1;
        repeat (FIFO_SIZE) @(negedge clk);
        @(negedge clk) pop = 1'b0;

        checkValues1(
            .refclk     (clk),
            .sig2watch  (empty),
            .testnum    (5.2),
            .valHold    (1'b1),
            .clks2wait  (1),
            .goal_value (1'b1)
        );

        print_all_passed_banner();
        $stop();
    end

end endgenerate

endmodule

`default_nettype wire
