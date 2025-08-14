package testing_pkg;

  // ------------------------------------------------------------
  // Parameters
  // ------------------------------------------------------------



  // ------------------------------------------------------------
  // Typedefs
  // ------------------------------------------------------------


/**************************************************************************
***                             Functions                               ***
**************************************************************************/

function automatic void print_all_passed_banner();
    $display("\n\n");
    $display("YYYY   YYYY   AA      H   H   OOOOO   OOOOO   OOOOO   !!");
    $display(" YYY   YYY   AAAA     H   H   O   O   O   O   O   O   !!");
    $display("  YYY YYY   AA  AA    H   H   O   O   O   O   O   O   !!");
    $display("   YYYYY   AA    AA   HHHHH   O   O   O   O   O   O   !!");
    $display("    YYY    AAAAAAAA   H   H   O   O   O   O   O   O      ");
    $display("    YYY    AA    AA   H   H   OOOOO   OOOOO   OOOOO   !!");
    $display("\n");
    $display("ALL TESTS PASSED!");
    $stop();
  endfunction

/**************************************************************************
***                                Tasks                                ***
**************************************************************************/
task automatic checkValues1 (
    ref   logic     refclk,
    ref   logic     sig2watch,   // ref so we see live changes
    input logic     goal_value,
    input int       clks2wait,
    input real       testnum,
    input bit       valHold
);
    reg signalAsserted;
    signalAsserted = 0;

    $display("Running test %.3g", testnum);

    fork
        begin : TRACK
            wait (sig2watch === goal_value);
            signalAsserted = 1;
        end
        begin : TIMEOUT
            repeat (clks2wait) @(negedge refclk);
            disable TRACK;
        end
    join

    @(negedge refclk)
    if (sig2watch === goal_value)
        $display("Passed.");
    else if (signalAsserted & valHold) begin
        $error("Flaked: reached goal but did not hold. sig=%0d, goal=%0d", sig2watch, goal_value);
        $stop();
    end
    else begin
        $error("Timeout after %0d cycles: sig=%0d, goal=%0d", clks2wait, sig2watch, goal_value);
        $stop();
    end

endtask



task automatic checkValues6 (
    ref   logic     refclk,
    ref   logic signed [5:0]    sig2watch,   // ref so we see live changes
    input logic signed [5:0]     goal_value,
    input int       clks2wait,
    input real       testnum,
    input bit       valHold
);
    reg signalAsserted;
    signalAsserted = 0;

    $display("Running test %.3g", testnum);

    fork
        begin : TRACK
            wait (sig2watch === goal_value);
            signalAsserted = 1;
        end
        begin : TIMEOUT
            repeat (clks2wait) @(negedge refclk);
            disable TRACK;
        end
    join

    @(negedge refclk)
    if (sig2watch === goal_value) begin
        $display("Passed.");
    end
    else if (signalAsserted & valHold) begin
                $error("Flaked: reached goal but did not hold. sig=%0d, goal=%0d", sig2watch, goal_value);

        $stop();
    end
    else begin
        $error("Timeout after %0d cycles: sig=%0d, goal=%0d", clks2wait, sig2watch, goal_value);
        $stop();
    end

endtask


task automatic checkValues8 (
    ref   logic                  refclk,
    ref   logic signed [7:0]  sig2watch,   

    input real                  testnum,
    input bit                   valHold,
    input int                 clks2wait,
    input logic signed [7:0] goal_value


);
    reg signalAsserted;
    signalAsserted = 0;

    $display("Running test %.3g", testnum);

    fork
        begin : TRACK
            wait (sig2watch === goal_value);
            signalAsserted = 1;
        end
        begin : TIMEOUT
            repeat (clks2wait) @(negedge refclk);
            disable TRACK;
        end
    join

    @(negedge refclk)
    if (sig2watch === goal_value) begin
        $display("Passed.");
    end
    else if (signalAsserted & valHold) begin
                $error("Flaked: reached goal but did not hold. sig=%0d, goal=%0d", sig2watch, goal_value);

        $stop();
    end
    else begin
        $error("Timeout after %0d cycles: sig=%0d, goal=%0d", clks2wait, sig2watch, goal_value);
        $stop();
    end

endtask


task automatic checkValues16 (
    ref   logic         refclk,
    ref   logic signed [15:0]    sig2watch,   // ref so we see live changes
    input logic signed [15:0]    goal_value,
    input int       clks2wait,
    input real       testnum,
    input bit       valHold
);
    reg signalAsserted;
    signalAsserted = 0;

    $display("Running test %.3g", testnum);

    fork
        begin : TRACK
            wait (sig2watch == goal_value);
            signalAsserted = 1;
        end
        begin : TIMEOUT
            repeat (clks2wait) @(negedge refclk);
            disable TRACK;
        end
    join

    @(negedge refclk)
    if (sig2watch === goal_value) begin
        $display("Passed.");
    end
    else if (signalAsserted & valHold) begin
                $error("Flaked: reached goal but did not hold. sig=%0d, goal=%0d", sig2watch, goal_value);

        $stop();
    end
    else begin
        $error("Timeout after %0d cycles: sig=%0d, goal=%0d", clks2wait, sig2watch, goal_value);
        $stop();
    end

endtask


endpackage 
