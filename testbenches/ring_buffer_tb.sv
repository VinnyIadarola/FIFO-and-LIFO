
`default_nettype none
import testing_pkg::*;

module ring_buffer_tb;

/**************************************************************************
***                            Pre Suite Setup                          ***
**************************************************************************/
// Compile-time suite selector
parameter int SUITE = 1;

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
    logic  [DATA_WIDTH-1:0]       entry;
    logic                   insert, pop;

    //Outputs
    logic  [DATA_WIDTH-1:0]        head;
    logic                   full, empty;

    /**************************************************************************
    ***                            Devices Under Testing                     ***
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



    task automatic checkQueueState (
        // Clock signal
        ref logic                     clk,

        // Watching
        ref logic [DATA_WIDTH-1:0] head,
        ref logic                  full,
        ref logic                 empty

        // Expected
        input logic [DATA_WIDTH-1:0] exp_head,
        input logic                  exp_full,
        input logic                 exp_empty
        input real                  test_num
    );
        fork
            // Head test
            checkValues8(
                .refclk(clk),
                .sig2watch(head),
                .goal_value(exp_head),
                .clks2wait(1),
                .testnum(test_num),
                .valHold(1'b1)
            );

            // Full test
            checkValues1(
                .refclk(clk),
                .sig2watch(full),
                .goal_value(exp_full),
                .clks2wait(1),
                .testnum(2),
                .valHold(1'b1)
            );

            // Empty test
            checkValues1(
                .refclk(clk),
                .sig2watch(empty),
                .goal_value(exp_empty),
                .clks2wait(1),
                .testnum(2),
                .valHold(1'b1)
            );
        join
    endtask



    initial begin
        clk    = 1'b0;



        // Test 1: On reset head='0, full is low, and empty is high
        rst_n  = 1'b0;
        insert = 1'bx;
        pop    = 1'bx;
        entry  =   'X;

        checkQueueState(
            .clk(clk),
            //Watching
            .head(head),
            .full(full),
            .empty(empty),
            //Expected
            .exp_head(8'h00),
            .exp_full(1'b0),
            .exp_empty(1'b1)
        );

        @(posedge clk);
        rst_n = 1'b1;


        // Test 2: Inserting 1 entry into the fifo 
        @(negedge clk);
        insert = 1'b1;
        pop    = 1'b0;
        entry  =   'F;

            
        fork //turning off insert so we only get one entry in the queue 
            checkQueueState(
                .clk(clk),
                //Watching
                .head(head),
                .full(full),
                .empty(empty),
                //Expected
                .exp_head(8'hFF),
                .exp_full(1'b0),
                .exp_empty(1'b0)
            );

            @(negedge clk) insert = 1'b0;
        join



        // Test 3: Only popping an entry off
        @(negedge clk);
        insert = 1'b0;
        pop    = 1'b1;
        entry  =   'E;

            
        fork //turning off insert so we only get one entry in the queue 
            checkQueueState(
                .clk(clk),
                //Watching
                .head(head),
                .full(full),
                .empty(empty),
                //Expected
                .exp_head(8'hFF), //Remember head should remain as we dont clear only overwritten
                .exp_full(1'b0),
                .exp_empty(1'b1)
            );

            @(negedge clk) insert = 1'b0;
        join




        // Test 4: Inserting max amount of elements then popping each off
        @(negedge clk);
        insert = 1'b1;
        pop    = 1'b0;
        entry  =   'F;

        @(negedge clk);
        entry  =   'E;

        @(negedge clk);
        entry  =   'D;

        @(negedge clk);
        entry  =   'C;

        @(negedge clk);
        entry  =   'B;


        fork //turning off insert so we only get one entry in the queue 
            checkQueueState(
                .clk(clk),
                //Watching
                .head(head),
                .full(full),
                .empty(empty),
                //Expected
                .exp_head(8'hFF), 
                .exp_full(1'b1),
                .exp_empty(1'b0)
            );

            @(negedge clk) insert = 1'b0;
        join


        @(negedge clk);
        pop = 1'b1;
        
        fork //turning off insert so we only get one entry in the queue 
            checkQueueState(
                .clk(clk),
                //Watching
                .head(head),
                .full(full),
                .empty(empty),
                //Expected
                .exp_head(8'hEE), 
                .exp_full(1'b0),
                .exp_empty(1'b0)
            );

            @(negedge clk) pop = 1'b0;
        join



        @(negedge clk);
        pop = 1'b1;
        
        fork //turning off pop so we only pop one entry in the queue 
            checkQueueState(
                .clk(clk),
                //Watching
                .head(head),
                .full(full),
                .empty(empty),
                //Expected
                .exp_head(8'hDD), 
                .exp_full(1'b0),
                .exp_empty(1'b0)
            );

            @(negedge clk) pop = 1'b0;
        join


        @(negedge clk);
        pop = 1'b1;
        
        fork
            checkQueueState(
                .clk(clk),
                //Watching
                .head(head),
                .full(full),
                .empty(empty),
                //Expected
                .exp_head(8'hCC), 
                .exp_full(1'b0),
                .exp_empty(1'b0)
            );

            @(negedge clk) pop = 1'b0;
        join


        @(negedge clk);
        pop = 1'b1;
        
        fork 
            checkQueueState(
                .clk(clk),
                //Watching
                .head(head),
                .full(full),
                .empty(empty),
                //Expected
                .exp_head(8'hBB), 
                .exp_full(1'b0),
                .exp_empty(1'b0)
            );

            @(negedge clk) pop = 1'b0;
        join
    

        @(negedge clk);
        pop = 1'b1;
        
        fork  //final pop should be empty
            checkQueueState(
                .clk(clk),
                //Watching
                .head(head),
                .full(full),
                .empty(empty),
                //Expected
                .exp_head(8'hBB), 
                .exp_full(1'b0),
                .exp_empty(1'b1)
            );

            @(negedge clk) pop = 1'b0;
        join
    
    

        // Test 5: Ensuring if we are full we dont overwrite data
        @(negedge clk);
        insert = 1'b1;
        pop    = 1'b0;
        entry  =   'A;
        @(posedge full);
        @(negedge clk);

        entry  =   '0;

        repeat (20) @(negedge clk);

        checkQueueState(
            .clk(clk),
            //Watching
            .head(head),
            .full(full),
            .empty(empty),
            //Expected
            .exp_head(8'hAA), 
            .exp_full(1'b1),
            .exp_empty(1'b0)
        );

        @(negedge clk);
        pop = 1'b1;

        repeat (5) checkValues8(
            .refclk(clk),
            .sig2watch(head),

            //Expected
            .test_num(5); 
            .valHold(1'b1),
            .clks2wait(1),
            .goal_value(8'hAA)

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
    ***  Width = 8  Size = 20 ***
    ****************************/
    localparam int DATA_WIDTH = 8;
    localparam int FIFO_SIZE  = 20;

    // DUT I/O (scoped to this suite)
    logic  [DATA_WIDTH-1:0] entry;
    logic                   insert, pop;
    logic  [DATA_WIDTH-1:0] head;
    logic                   full, empty;

    /**************************************************************************
    ***                            Devices Under Testing                     ***
    **************************************************************************/
    ring_buffer #(
        .DATA_WIDTH (DATA_WIDTH),
        .FIFO_SIZE  (FIFO_SIZE)
    ) iDUT (
        .clk        (clk),
        .rst_n      (rst_n),
        .entry      (entry),
        .insert     (insert),
        .pop        (pop),
        .head       (head),
        .full       (full),
        .empty      (empty)
    );

    // Minimal checks to illustrate second config
    task automatic expect_bit2(string name, logic got, logic exp);
    if (got !== exp) begin
        $error("[S2] %s: got=%b exp=%b @%0t", name, got, exp, $time);
        $fatal;
    end
    endtask

    initial begin
        /**************************************************************************
        ***                                Test Suite 2                          ***
        **************************************************************************/
        clk = 1'b0; rst_n = 1'b0; insert=0; pop=0; entry='0;
        repeat (2) @(negedge clk);
        rst_n = 1'b1;
        @(negedge clk);
        expect_bit2("Reset->empty=1", empty, 1'b1);

        // Quick smoke: push one then pop one
        @(negedge clk); insert=1'b1; entry=8'hA5;
        @(negedge clk); insert=1'b0; entry='0;
        @(negedge clk);
        expect_bit2("After 1 push -> empty=0", empty, 1'b0);

        @(negedge clk); pop=1'b1;
        @(negedge clk); pop=1'b0;
        @(negedge clk);
        expect_bit2("After pop -> empty=1", empty, 1'b1);

        $display("\n[S2] Smoke tests passed.\n");
        $finish;
    end
end endgenerate




endmodule

`default_nettype wire
