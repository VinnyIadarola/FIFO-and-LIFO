`default_nettype none
import testing_pkg::*;
module stack_tb;

/**************************************************************************
***                            Pre Suite Setup                          ***
**************************************************************************/
parameter int SUITE = 1;

// Shared basic inputs
logic clk;
logic rst_n;

// Clock
always #5 clk = ~clk;



generate if (SUITE == 1) begin
    /**************************************************************************
    ***                              Test Suite 1                           ***
    **************************************************************************/

    /****************************
    ***  Width = 8  Size = 5  ***
    ****************************/
    localparam int DATA_WIDTH = 8;
    localparam int LIFO_SIZE  = 5;

    //Inputs
    logic  [DATA_WIDTH-1:0] entry;
    logic             insert, pop;

    //Outputs (signed to match checkValues8 ref formal)
    logic signed [DATA_WIDTH-1:0] top;
    logic                  full, empty;

    /**************************************************************************
    ***                            Device Under Testing                     ***
    **************************************************************************/
    stack #(
        .DATA_WIDTH (DATA_WIDTH),
        .LIFO_SIZE  (LIFO_SIZE)
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
        .top       (top),

        // Control Outputs
        .full       (full),
        .empty      (empty)
    );

    // Helper task: checks top/full/empty together with a single test number
    task automatic checkStackState (
        // Clock signal
        ref  logic                         clk,
        // Watching
        ref  logic signed [DATA_WIDTH-1:0] top,
        ref  logic                         full,
        ref  logic                         empty,
        // Expected
        input logic       [DATA_WIDTH-1:0] exp_top,
        input logic                        exp_full,
        input logic                        exp_empty,
        input real                         test_num
    );
        fork
            // top test (8-bit)
            checkValues8(
                .refclk     (clk),
                .sig2watch  (top),
                .testnum    (test_num),
                .valHold    (1'b1),
                .clks2wait  (1),
                .goal_value (exp_top)
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

        // Test 1.0: On reset top='0, full=0, empty=1
        rst_n  = 1'b0;
        insert = 1'bx;
        pop    = 1'bx;
        entry  = 8'hXX;

        checkStackState(
            .test_num (1.0),
            .clk      (clk),
            .top      (top),
            .full     (full),
            .empty    (empty),
            .exp_top  (8'h00),
            .exp_full (1'b0),
            .exp_empty(1'b1)
        );

        @(posedge clk);
        rst_n = 1'b1;

        // Test 2.0: Insert one entry
        @(negedge clk);
        insert = 1'b1;
        pop    = 1'b0;
        entry  = 8'hFF;

        fork // turn off insert so we only get one entry
            checkStackState(
                .test_num (2.0),
                .clk      (clk),
                .top     (top),
                .full     (full),
                .empty    (empty),
                .exp_top (8'hFF),
                .exp_full (1'b0),
                .exp_empty(1'b0)
            );
            @(negedge clk) insert = 1'b0;
        join

        // Test 3.0: Pop the single entry (top goes to next unit value)
        @(negedge clk);
        insert = 1'b0;
        pop    = 1'b1;
        entry  = 8'hEE; 

        fork // pop exactly one entry
            checkStackState(
                .test_num (3.0),
                .clk      (clk),
                .top      (top),
                .full     (full),
                .empty    (empty),
                .exp_top  (8'hFF), // should remain unchanged as 
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
            checkStackState(
                .test_num (4.0),
                .clk      (clk),
                .top     (top),
                .full     (full),
                .empty    (empty),
                .exp_top (8'hBB),
                .exp_full (1'b1),
                .exp_empty(1'b0)
            );
            @(negedge clk) insert = 1'b0; // stop inserting
        join

        // 1st pop -> top CC
        @(negedge clk) pop = 1'b1;
        fork
            checkStackState(
                .test_num (4.1),
                .clk      (clk),
                .top     (top),
                .full     (full),
                .empty    (empty),
                .exp_top (8'hCC),
                .exp_full (1'b0),
                .exp_empty(1'b0)
            );
            @(negedge clk) pop = 1'b0;
        join

        // 2nd pop -> top DD
        @(negedge clk) pop = 1'b1;
        fork
            checkStackState(
                .test_num (4.2),
                .clk      (clk),
                .top     (top),
                .full     (full),
                .empty    (empty),
                .exp_top (8'hDD),
                .exp_full (1'b0),
                .exp_empty(1'b0)
            );
            @(negedge clk) pop = 1'b0;
        join

        // 3rd pop -> top EE
        @(negedge clk) pop = 1'b1;
        fork
            checkStackState(
                .test_num (4.3),
                .clk      (clk),
                .top     (top),
                .full     (full),
                .empty    (empty),
                .exp_top (8'hEE),
                .exp_full (1'b0),
                .exp_empty(1'b0)
            );
            @(negedge clk) pop = 1'b0;
        join

        // 4th pop -> top FF
        @(negedge clk) pop = 1'b1;
        fork
            checkStackState(
                .test_num (4.4),
                .clk      (clk),
                .top     (top),
                .full     (full),
                .empty    (empty),
                .exp_top (8'hFF),
                .exp_full (1'b0),
                .exp_empty(1'b0)
            );
            @(negedge clk) pop = 1'b0;
        join

        // 5th pop -> becomes empty (top remains previous top but empty)
        @(negedge clk) pop = 1'b1;
        fork
            checkStackState(
                .test_num (4.5),
                .clk      (clk),
                .top     (top),
                .full     (full),
                .empty    (empty),
                .exp_top (8'hFF),
                .exp_full (1'b0),
                .exp_empty(1'b1)
            );
            @(negedge clk) pop = 1'b0;
        join

        // Test 5.x: Full should not allow overwrite (keep top=AA while full)
        @(negedge clk);
        insert = 1'b1; pop = 1'b0; entry = 8'hAA;
        @(posedge full);
        @(negedge clk);
        entry = 8'h00; // attempt to overwrite while full
        repeat (20) @(negedge clk);

        checkStackState(
            .test_num (5.0),
            .clk      (clk),
            .top     (top),
            .full     (full),
            .empty    (empty),
            .exp_top (8'hAA),
            .exp_full (1'b1),
            .exp_empty(1'b0)
        );

        // Drain exactly LIFO_SIZE entries; empty must assert
        @(negedge clk);
        insert = 1'b0; 
        pop = 1'b1;
        checkValues8(.refclk(clk), .sig2watch(top), .testnum(5.1), .valHold(1'b1), .clks2wait(1), .goal_value(8'hAA));
        checkValues8(.refclk(clk), .sig2watch(top), .testnum(5.2), .valHold(1'b1), .clks2wait(1), .goal_value(8'hAA));
        checkValues8(.refclk(clk), .sig2watch(top), .testnum(5.3), .valHold(1'b1), .clks2wait(1), .goal_value(8'hAA));
        checkValues8(.refclk(clk), .sig2watch(top), .testnum(5.4), .valHold(1'b1), .clks2wait(1), .goal_value(8'hAA));
        checkValues8(.refclk(clk), .sig2watch(top), .testnum(5.5), .valHold(1'b1), .clks2wait(1), .goal_value(8'hAA));
        @(negedge clk) pop = 1'b0;

        checkValues1(
            .refclk     (clk),
            .sig2watch  (empty),
            .testnum    (5.6),
            .valHold    (1'b1),
            .clks2wait  (1),
            .goal_value (1'b1)
        );

        // Test 6.x: Fill to max with AA then insert and pop to replace with 00 ensure it stays full
        @(negedge clk);
        insert = 1'b1; 
        pop = 1'b0; 
        entry = 8'hAA;
        @(posedge full);
        @(negedge clk);
        pop = 1'b1;
        entry = 8'h00;


        checkValues8(.refclk(clk), .sig2watch(top), .testnum(6.5), .valHold(1'b0), .clks2wait(1), .goal_value(8'h00));
        checkValues8(.refclk(clk), .sig2watch(top), .testnum(6.6), .valHold(1'b0), .clks2wait(1), .goal_value(8'h00));
        checkValues8(.refclk(clk), .sig2watch(top), .testnum(6.7), .valHold(1'b0), .clks2wait(1), .goal_value(8'h00));
        checkValues8(.refclk(clk), .sig2watch(top), .testnum(6.8), .valHold(1'b0), .clks2wait(1), .goal_value(8'h00));
        checkValues8(.refclk(clk), .sig2watch(top), .testnum(6.9), .valHold(1'b0), .clks2wait(1), .goal_value(8'h00));
        checkValues1(.refclk(clk), .sig2watch(full), .testnum(6.10), .valHold(1'b1), .clks2wait(1), .goal_value(1'b1));

        @(negedge clk);
        insert = 1'b0;
        checkValues8(.refclk(clk), .sig2watch(top), .testnum(6.1), .valHold(1'b0), .clks2wait(1), .goal_value(8'hAA));
        checkValues8(.refclk(clk), .sig2watch(top), .testnum(6.2), .valHold(1'b0), .clks2wait(1), .goal_value(8'hAA));
        checkValues8(.refclk(clk), .sig2watch(top), .testnum(6.3), .valHold(1'b0), .clks2wait(1), .goal_value(8'hAA));
        checkValues8(.refclk(clk), .sig2watch(top), .testnum(6.4), .valHold(1'b0), .clks2wait(1), .goal_value(8'hAA));


        // Test 7.x: Empty then add 1 element and ensure inserting and popping stays non empty

        // First, drain to empty (we ended Test 6 full)
        @(negedge clk);
        insert = 1'b0;
        pop    = 1'b1;
        repeat (LIFO_SIZE) @(negedge clk);
        @(negedge clk) pop = 1'b0;

        checkValues1(
            .refclk     (clk),
            .sig2watch  (empty),
            .testnum    (7.0),
            .valHold    (1'b1),
            .clks2wait  (1),
            .goal_value (1'b1)
        );

        // Insert exactly one element -> becomes non-empty
        @(negedge clk);
        insert = 1'b1; 
        pop    = 1'b0; 
        entry  = 8'h5A;
        @(negedge clk) insert = 1'b0;

        checkValues1(
            .refclk     (clk),
            .sig2watch  (empty),
            .testnum    (7.1),
            .valHold    (1'b1),
            .clks2wait  (1),
            .goal_value (1'b0)
        );

        // Now keep queue at depth 1 by asserting insert & pop together.
        // The top value may change by design, but empty must remain deasserted.
        @(negedge clk);
        insert = 1'b1; pop = 1'b1; entry = 8'h11;
        checkValues1(.refclk(clk), .sig2watch(empty), .testnum(7.2), .valHold(1'b0), .clks2wait(1), .goal_value(1'b0));

        @(negedge clk) entry = 8'h22;
        checkValues1(.refclk(clk), .sig2watch(empty), .testnum(7.3), .valHold(1'b0), .clks2wait(1), .goal_value(1'b0));

        @(negedge clk) entry = 8'h33;
        checkValues1(.refclk(clk), .sig2watch(empty), .testnum(7.4), .valHold(1'b0), .clks2wait(1), .goal_value(1'b0));

        @(negedge clk) entry = 8'h44;
        checkValues1(.refclk(clk), .sig2watch(empty), .testnum(7.5), .valHold(1'b0), .clks2wait(1), .goal_value(1'b0));

        @(negedge clk) entry = 8'h55;
        checkValues1(.refclk(clk), .sig2watch(empty), .testnum(7.6), .valHold(1'b0), .clks2wait(1), .goal_value(1'b0));

        @(negedge clk) entry = 8'h66;
        checkValues1(.refclk(clk), .sig2watch(empty), .testnum(7.7), .valHold(1'b0), .clks2wait(1), .goal_value(1'b0));

        @(negedge clk) entry = 8'h77;
        checkValues1(.refclk(clk), .sig2watch(empty), .testnum(7.8), .valHold(1'b0), .clks2wait(1), .goal_value(1'b0));

        @(negedge clk) entry = 8'h88;
        fork
            checkValues1(.refclk(clk), .sig2watch(empty), .testnum(7.9), .valHold(1'b0), .clks2wait(1), .goal_value(1'b0));
            checkValues8(.refclk(clk), .sig2watch(top), .testnum(7.10), .valHold(1'b0), .clks2wait(1), .goal_value(8'h88));
            @(negedge clk) begin insert = 1'b0; pop = 1'b0; end
        join 

        print_all_passed_banner();
        $stop();
    end
end endgenerate

generate if (SUITE == 2) begin
    /**************************************************************************
    ***                              Test Suite 2                           ***
    **************************************************************************/

    /*******************************
    ***  Width = 16  Size = 20   ***
    *******************************/
    localparam int DATA_WIDTH = 16;
    localparam int LIFO_SIZE  = 20;

    //Inputs
    logic  [DATA_WIDTH-1:0] entry;
    logic             insert, pop;

    //Outputs (signed to match checkValues16 ref formal)
    logic signed [DATA_WIDTH-1:0] top;
    logic                  full, empty;

    /**************************************************************************
    ***                            Device Under Testing                     ***
    **************************************************************************/
    stack #(
        .DATA_WIDTH (DATA_WIDTH),
        .LIFO_SIZE  (LIFO_SIZE)
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
        .top        (top),

        // Control Outputs
        .full       (full),
        .empty      (empty)
    );

    // Helper task: checks top/full/empty together with a single test number (16-bit top)
    task automatic checkStackState16 (
        // Clock signal
        ref  logic                         clk,
        // Watching
        ref  logic signed [DATA_WIDTH-1:0] top,
        ref  logic                         full,
        ref  logic                         empty,
        // Expected
        input logic       [DATA_WIDTH-1:0] exp_top,
        input logic                        exp_full,
        input logic                        exp_empty,
        input real                         test_num
    );
        fork
            // top test (16-bit)
            checkValues16(
                .refclk     (clk),
                .sig2watch  (top),
                .testnum    (test_num),
                .valHold    (1'b1),
                .clks2wait  (1),
                .goal_value (exp_top)
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

        // Test 1.0: On reset top='0, full=0, empty=1
        rst_n  = 1'b0;
        insert = 1'bx;
        pop    = 1'bx;
        entry  = 16'hXXXX;

        checkStackState16(
            .test_num (1.0),
            .clk      (clk),
            .top      (top),
            .full     (full),
            .empty    (empty),
            .exp_top  (16'h0000),
            .exp_full (1'b0),
            .exp_empty(1'b1)
        );

        @(posedge clk);
        rst_n = 1'b1;

        // Test 2.0: Insert one entry
        @(negedge clk);
        insert = 1'b1;
        pop    = 1'b0;
        entry  = 16'hFFFF;

        fork // turn off insert so we only get one entry
            checkStackState16(
                .test_num (2.0),
                .clk      (clk),
                .top      (top),
                .full     (full),
                .empty    (empty),
                .exp_top  (16'hFFFF),
                .exp_full (1'b0),
                .exp_empty(1'b0)
            );
            @(negedge clk) insert = 1'b0;
        join

        // Test 3.0: Pop the single entry (top holds last value, becomes empty)
        @(negedge clk);
        insert = 1'b0;
        pop    = 1'b1;
        entry  = 16'hEEEE; 

        fork // pop exactly one entry
            checkStackState16(
                .test_num (3.0),
                .clk      (clk),
                .top      (top),
                .full     (full),
                .empty    (empty),
                .exp_top  (16'hFFFF), // should remain unchanged as last value
                .exp_full (1'b0),
                .exp_empty(1'b1)
            );
            @(negedge clk) pop = 1'b0;
        join

        // Test 4.x: Fill to max with a known last element then pop down step-by-step
        // Fill with 19 placeholders, then final sentinel 16'hBEEF
        @(negedge clk);
        insert = 1'b1; 
        pop    = 1'b0; 
        entry  = 16'h1111;
        repeat (LIFO_SIZE-1) @(negedge clk) entry = entry + 16'h0001; // push 20 values

        fork
            checkStackState16(
                .test_num (4.0),
                .clk      (clk),
                .top      (top),
                .full     (full),
                .empty    (empty),
                .exp_top  (16'h1124),
                .exp_full (1'b1),
                .exp_empty(1'b0)
            );
            @(negedge clk) insert = 1'b0; // stop inserting
        join

        // 1st pop -> top becomes previous value 1123
        @(negedge clk) pop = 1'b1;
        fork
            checkStackState16(
                .test_num (4.1),
                .clk      (clk),
                .top      (top),
                .full     (full),
                .empty    (empty),
                .exp_top  (16'h1123),
                .exp_full (1'b0),
                .exp_empty(1'b0)
            );
            @(negedge clk) pop = 1'b0;
        join

        // 2nd pop -> top 1122
        @(negedge clk) pop = 1'b1;
        fork
            checkStackState16(
                .test_num (4.2),
                .clk      (clk),
                .top      (top),
                .full     (full),
                .empty    (empty),
                .exp_top  (16'h1122),
                .exp_full (1'b0),
                .exp_empty(1'b0)
            );
            @(negedge clk) pop = 1'b0;
        join

        // 3rd pop -> top 1121
        @(negedge clk) pop = 1'b1;
        fork
            checkStackState16(
                .test_num (4.3),
                .clk      (clk),
                .top      (top),
                .full     (full),
                .empty    (empty),
                .exp_top  (16'h1121),
                .exp_full (1'b0),
                .exp_empty(1'b0)
            );
            @(negedge clk) pop = 1'b0;
        join

        // 4th pop -> top 1120
        @(negedge clk) pop = 1'b1;
        fork
            checkStackState16(
                .test_num (4.4),
                .clk      (clk),
                .top      (top),
                .full     (full),
                .empty    (empty),
                .exp_top  (16'h1120),
                .exp_full (1'b0),
                .exp_empty(1'b0)
            );
            @(negedge clk) pop = 1'b0;
        join

        // Test 5.x: Full should not allow overwrite (keep top=00AA while full)
        // Refill to full with 0x00AA and ensure attempted overwrite doesn't change top
        @(negedge clk);
        insert = 1'b1; pop = 1'b0; entry = 16'h00AA;
        @(posedge full);
        @(negedge clk);
        entry = 16'h0000; // attempt to overwrite while full
        repeat (20) @(negedge clk);

        checkStackState16(
            .test_num (5.0),
            .clk      (clk),
            .top      (top),
            .full     (full),
            .empty    (empty),
            .exp_top  (16'h00AA),
            .exp_full (1'b1),
            .exp_empty(1'b0)
        );

        // Drain exactly LIFO_SIZE entries; empty must assert
        @(negedge clk);
        insert = 1'b0; 
        pop    = 1'b1;
        // observe top during first few drains (optional), then finish draining
        checkValues16(.refclk(clk), .sig2watch(top), .testnum(5.1), .valHold(1'b1), .clks2wait(1), .goal_value(16'h00AA));
        repeat (LIFO_SIZE-1) @(negedge clk);
        @(negedge clk) pop = 1'b0;

        checkValues1(
            .refclk     (clk),
            .sig2watch  (empty),
            .testnum    (5.2),
            .valHold    (1'b1),
            .clks2wait  (1),
            .goal_value (1'b1)
        );

        // Test 6.x: Fill to max with 00AA then insert and pop to replace top with 0000; ensure it stays full
        @(negedge clk);
        insert = 1'b1; 
        pop    = 1'b0; 
        entry  = 16'h00AA;
        @(posedge full);

        // Now replace top while staying full: simultaneous pop+insert new 0000
        @(negedge clk);
        pop   = 1'b1;
        entry = 16'h0000;

        checkValues16(.refclk(clk), .sig2watch(top), .testnum(6.1), .valHold(1'b0), .clks2wait(1), .goal_value(16'h0000));
        checkValues16(.refclk(clk), .sig2watch(top), .testnum(6.2), .valHold(1'b0), .clks2wait(1), .goal_value(16'h0000));
        checkValues1 (.refclk(clk), .sig2watch(full), .testnum(6.3), .valHold(1'b1), .clks2wait(1), .goal_value(1'b1));

        // Stop inserting; queue depth drops on next pop edge, so deassert both
        @(negedge clk);
        insert = 1'b0; pop = 1'b0;

        // Test 7.x: Empty then add 1 element and ensure inserting and popping stays non-empty

        // First, drain to empty (we ended Test 6 full)
        @(negedge clk);
        insert = 1'b0;
        pop    = 1'b1;
        repeat (LIFO_SIZE) @(negedge clk);
        @(negedge clk) pop = 1'b0;

        checkValues1(
            .refclk     (clk),
            .sig2watch  (empty),
            .testnum    (7.0),
            .valHold    (1'b1),
            .clks2wait  (1),
            .goal_value (1'b1)
        );

        // Insert exactly one element -> becomes non-empty
        @(negedge clk);
        insert = 1'b1; 
        pop    = 1'b0; 
        entry  = 16'h5A5A;
        @(negedge clk) insert = 1'b0;

        checkValues1(
            .refclk     (clk),
            .sig2watch  (empty),
            .testnum    (7.1),
            .valHold    (1'b1),
            .clks2wait  (1),
            .goal_value (1'b0)
        );

        // Now keep depth ~1 by asserting insert & pop together.
        // The top value may change by design, but empty must remain deasserted.
        @(negedge clk);
        insert = 1'b1; pop = 1'b1; entry = 16'h1111;
        checkValues1(.refclk(clk), .sig2watch(empty), .testnum(7.2), .valHold(1'b0), .clks2wait(1), .goal_value(1'b0));

        @(negedge clk) entry = 16'h2222;
        checkValues1(.refclk(clk), .sig2watch(empty), .testnum(7.3), .valHold(1'b0), .clks2wait(1), .goal_value(1'b0));

        @(negedge clk) entry = 16'h3333;
        checkValues1(.refclk(clk), .sig2watch(empty), .testnum(7.4), .valHold(1'b0), .clks2wait(1), .goal_value(1'b0));

        @(negedge clk) entry = 16'h4444;
        checkValues1(.refclk(clk), .sig2watch(empty), .testnum(7.5), .valHold(1'b0), .clks2wait(1), .goal_value(1'b0));

        @(negedge clk) entry = 16'h5555;
        checkValues1(.refclk(clk), .sig2watch(empty), .testnum(7.6), .valHold(1'b0), .clks2wait(1), .goal_value(1'b0));

        @(negedge clk) entry = 16'h6666;
        checkValues1(.refclk(clk), .sig2watch(empty), .testnum(7.7), .valHold(1'b0), .clks2wait(1), .goal_value(1'b0));

        @(negedge clk) entry = 16'h7777;
        checkValues1(.refclk(clk), .sig2watch(empty), .testnum(7.8), .valHold(1'b0), .clks2wait(1), .goal_value(1'b0));

        @(negedge clk) entry = 16'h8888;
        fork
            checkValues1 (.refclk(clk), .sig2watch(empty), .testnum(7.9),  .valHold(1'b0), .clks2wait(1), .goal_value(1'b0));
            checkValues16(.refclk(clk), .sig2watch(top),   .testnum(7.10), .valHold(1'b0), .clks2wait(1), .goal_value(16'h8888));
            @(negedge clk) begin insert = 1'b0; pop = 1'b0; end
        join 

        print_all_passed_banner();
        $stop();
    end
end endgenerate



endmodule

`default_nettype wire
