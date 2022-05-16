module tb_threshold_compress;
  timeunit 1ns;
  timeprecision 1ps;

  localparam time T_CLK_HI   = 5ns;                 // set clock high time
  localparam time T_CLK_LO   = 5ns;                 // set clock low time
  localparam time T_CLK      = T_CLK_HI + T_CLK_LO; // calculate clock period
  localparam time T_APPL_DEL = 2ns;                 // set stimuli application delay
  localparam time T_ACQ_DEL  = 8ns;                 // set response aquisition delay

  localparam int OUTPUT_WIDTH = 8;
  localparam int COMPREG_WIDTH = int'(OUTPUT_WIDTH * 1.25);
  localparam int COUNTER_MAX = COMPREG_WIDTH / 2;
  localparam int COUNTER_WIDTH = $clog2(COUNTER_MAX);

  localparam string STIMULI_FILE   = "./stimuli/stimuli.txt";
  localparam string RESPONSE_FILE  = "./stimuli/exp_responses.txt";

  //-------------------- Testbench signals --------------------
  logic                     EndOfSim_S;
  logic [31:0]              thresholds_tmp;
  logic [OUTPUT_WIDTH-1:0]  exp_response;
  logic [OUTPUT_WIDTH-1:0]  acq_response;
  logic                     clk;

  integer                   error_counter;
  integer                   total_counter;

  //---------------- Signals connecting to MUT ----------------
  logic [COUNTER_WIDTH-1:0] mut_counter_d, mut_counter_q;
  logic [COMPREG_WIDTH-1:0] precompressed_d, precompressed_q;
  logic [OUTPUT_WIDTH-1:0]  compressed_d, compressed_q;
  logic [31:0]              preactivation;
  logic [31:0]              thresholds;
  logic                     enable, rst_n, compreg_full;

  //--------------------- Instantiate MUT ---------------------
  threshold_compress
  #(
    .OUTPUT_WIDTH    (OUTPUT_WIDTH)
  )
  i_mut
  (
    .preactivation_i ( preactivation   ),
    .thresholds_i    ( thresholds      ),
    .counter_i       ( mut_counter_q   ),
    .precompressed_i ( precompressed_q ),
    .compressed_i    ( compressed_q    ),
    .enable_i        ( enable          ),
    .rst_ni          ( rst_n           ),
    .clk_i           ( clk             ),
    .counter_o       ( mut_counter_d   ),
    .precompressed_o ( precompressed_d ),
    .compressed_o    ( compressed_d    ),
    .compreg_full_o  ( compreg_full    )
  );

  //------------------ Models the src/dst GPR ------------------
  always_ff @(posedge clk, negedge rst_n) begin
    if (!rst_n) begin
      mut_counter_q   <= '0;
      precompressed_q <= '0;
      compressed_q    <= '0;
    end else if (enable) begin
      mut_counter_q   <= mut_counter_d;
      precompressed_q <= precompressed_d;
      compressed_q    <= compressed_d;
    end
  end

  //------------------ Generate clock signal ------------------
  initial begin
    do begin
      clk = 1'b1; #T_CLK_HI;
      clk = 1'b0; #T_CLK_LO;
    end while (EndOfSim_S == 1'b0);
  end

  //------------------- Stimuli Application -------------------
  initial begin: application_block
    int stim_fd;
    int ret_code;
    EndOfSim_S = 0;
    preactivation = '0;
    thresholds = '0;
    enable = 1'b0;
    rst_n = 1'b0;
    //Read stimuli from file
    stim_fd = $fopen(STIMULI_FILE, "r");
    if (stim_fd == 0) begin
      $fatal("Could not open stimuli file!");
    end
    //Wait for one clock cycle
    @(posedge clk);
    rst_n = 1'b1;
    enable = 1'b1;
    //Apply the stimuli
    while(!$feof(stim_fd)) begin
      ret_code = $fscanf(stim_fd, "%32b\n", thresholds_tmp);
      for (int i=0; i<COMPREG_WIDTH/2 && !$feof(stim_fd); i++) begin
        #T_APPL_DEL;
        thresholds = thresholds_tmp;
        ret_code = $fscanf(stim_fd, "%32b\n", preactivation);
        //Wait for one clock cycle
        @(posedge clk);
      end
    end
    $fclose(stim_fd);

    //Terminate simulation by stoping the clock
    EndOfSim_S = 1;
  end // initial begin

  //------------------- Response Acquisition -------------------
  initial begin: acquisition_block
    int exp_fd;
    int ret_code;
    //Read expected responses
    exp_fd = $fopen(RESPONSE_FILE, "r");
    if (exp_fd == 0) begin
      $fatal("Could not open response file!");
    end
    error_counter = 0;
    total_counter = 0;

    //Compare responses in each cycle
    while (!$feof(exp_fd)) begin
      //Wait for two clock cycles
      @(posedge clk);
      @(posedge clk);
      wait (mut_counter_q == COUNTER_MAX-1) begin // for COMPREG_WIDTH=10, acquire output every 5 cycles
        //Delay response acquistion by the stimuli acquistion delay
        #T_ACQ_DEL;

        //Sample the output of the MUT
        acq_response = compressed_d;
        ret_code = $fscanf(exp_fd, "%8b\n", exp_response); // Todo: '8' in the format specifier is hard-coded. Parametrize using OUTPUT_WIDTH

        // Compare results
        // The ==? operator treats 'x' as don't care values wheras the normal == would result with 'x'
        if(acq_response  !=? exp_response) begin
          $error("Mismatch between expected and actual response. Was %b but should be %b, stimuli %d", acq_response, exp_response, total_counter);
          error_counter = error_counter + 1;
        end
        total_counter = total_counter + 1;
      end
    end

    $fclose(exp_fd);
    $display("Tested %d outputs", total_counter);
    if(error_counter == 0) begin
      $display("No errors in testbench");
    end else begin
      $display("%d errors in testbench", error_counter);
    end

    $info("Simulation finished");
  end

endmodule : tb_threshold_compress

