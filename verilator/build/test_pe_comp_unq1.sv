//
//--------------------------------------------------------------------------------
//          THIS FILE WAS AUTOMATICALLY GENERATED BY THE GENESIS2 ENGINE        
//  FOR MORE INFORMATION: OFER SHACHAM (CHIP GENESIS INC / STANFORD VLSI GROUP)
//    !! THIS VERSION OF GENESIS2 IS NOT FOR ANY COMMERCIAL USE !!
//     FOR COMMERCIAL LICENSE CONTACT SHACHAM@ALUMNI.STANFORD.EDU
//--------------------------------------------------------------------------------
//
//  
//	-----------------------------------------------
//	|            Genesis Release Info             |
//	|  $Change: 11879 $ --- $Date: 2013/06/11 $   |
//	-----------------------------------------------
//	
//
//  Source file: /Users/hanrahan/git/CGRAGenerator/hardware/generator_z/pe_new/pe/rtl/test_pe_comp.svp
//  Source template: test_pe_comp
//
// --------------- Begin Pre-Generation Parameters Status Report ---------------
//
//	From 'generate' statement (priority=5):
// Parameter mult_mode 	= 1
// Parameter use_div 	= 0
// Parameter en_double 	= 0
// Parameter use_add 	= 1
// Parameter debug 	= 0
// Parameter is_msb 	= 0
// Parameter use_shift 	= 1
// Parameter use_cntr 	= 0
// Parameter use_bool 	= 1
//
//		---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ----
//
//	From Command Line input (priority=4):
//
//		---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ----
//
//	From XML input (priority=3):
//
//		---- ---- ---- ---- ---- ---- ---- ---- ---- ---- ----
//
//	From Config File input (priority=2):
//
// ---------------- End Pre-Generation Pramameters Status Report ----------------

// use_add (_GENESIS2_INHERITANCE_PRIORITY_) = 1
//
// use_cntr (_GENESIS2_INHERITANCE_PRIORITY_) = 0
//
// use_bool (_GENESIS2_INHERITANCE_PRIORITY_) = 1
//
// use_shift (_GENESIS2_INHERITANCE_PRIORITY_) = 1
//
// mult_mode (_GENESIS2_INHERITANCE_PRIORITY_) = 1
//
// use_div (_GENESIS2_INHERITANCE_PRIORITY_) = 0
//
// is_msb (_GENESIS2_INHERITANCE_PRIORITY_) = 0
//
// en_double (_GENESIS2_INHERITANCE_PRIORITY_) = 0
//
// debug (_GENESIS2_INHERITANCE_PRIORITY_) = 0
//
module   test_pe_comp_unq1  #(
  parameter DataWidth = 16
) (
  input [8:0]                   op_code,

  input  [DataWidth-1:0]        op_a,
  input  [DataWidth-1:0]        op_a_shift,
  input  [DataWidth-1:0]        op_b,
  input                         op_d_p,


  output [DataWidth-1:0]  res,
  output                  res_p
);

localparam DATA_MSB = DataWidth - 1;

localparam PE_ADD_OP     = 6'h0;
localparam PE_SUB_OP     = 6'h1;

localparam PE_ABS_OP     = 6'h3;

localparam PE_GTE_MAX_OP = 6'h4;
localparam PE_LTE_MIN_OP = 6'h5;
localparam PE_EQ_OP      = 6'h6;

localparam PE_SEL_OP     = 6'h8;

localparam PE_RSHFT_OP   = 6'hF;
localparam PE_RSHFT_S_OP = 6'h10;
localparam PE_LSHFT_OP   = 6'h11;

localparam PE_MULT_0_OP  = 6'hB;
localparam PE_MULT_1_OP  = 6'hC;
localparam PE_MULT_2_OP  = 6'hD;

localparam PE_OR_OP      = 6'h12;
localparam PE_AND_OP     = 6'h13;
localparam PE_XOR_OP     = 6'h14;
localparam PE_INV_OP     = 6'h15;

localparam PE_CNTR_OP    = 6'h18;

localparam PE_DIV_OP    = 6'h19;

logic [2*DataWidth-1:0] mult_res;


logic [DataWidth-1:0] res_w;
logic                 res_p_w;

logic                 is_signed;
logic                 dual_mode;
logic                 double_mode;

logic                 cmpr_lte;
logic                 cmpr_gte;
logic                 cmpr_eq;


localparam NUM_ADDERS = 1;
localparam ADD_MSB = NUM_ADDERS - 1;

logic [DataWidth-1:0]  add_a     [ADD_MSB:0];
logic [DataWidth-1:0]  add_b     [ADD_MSB:0];
logic                  add_c_in  [ADD_MSB:0];

logic [DataWidth-1:0]  add_res   [ADD_MSB:0];
logic                  add_c_out [ADD_MSB:0];



genvar ggg;

generate
  for(ggg=0;ggg<NUM_ADDERS;ggg=ggg+1) begin
  test_full_add #(.DataWidth(DataWidth)) full_add
    (
      .a     (add_a[ggg]),
      .b     (add_b[ggg]),
      .c_in  (add_c_in[ggg]),

//      .dual_mode (dual_mode),

      .res   (add_res[ggg]),
      .c_out (add_c_out[ggg])
    );

  end

endgenerate

logic [DataWidth-1:0]  add_res_0;
assign add_res_0 = add_res[0];


assign cmpr_eq   =  ~|(op_a ^ op_b);



test_cmpr  cmpr
(
  .a_msb     (op_a[DataWidth-1]),
  .b_msb     (op_b[DataWidth-1]),
  .diff_msb  (add_res[0][DataWidth-1]),
  .is_signed (is_signed),
  .eq        (cmpr_eq),

  .lte       (cmpr_lte),
  .gte       (cmpr_gte)
);



logic                 mult_c_out;

test_mult_add #(.DataWidth(DataWidth)) test_mult_add
(
  .a  (op_a),
  .b  (op_b),

//  .dual_mode(dual_mode),

  .res   (mult_res),
  .c_out (mult_c_out)
);





assign is_signed   = op_code[6];
assign double_mode = op_code[7];
assign dual_mode   = op_code[8]; //Save the OP code bit for half precision support

  assign cmpr_eq_out = cmpr_eq;

logic diff_sign;

assign diff_sign = add_res_0[DataWidth-1];


always_comb begin : proc_alu
  add_a[0] = op_a;
  add_b[0] = op_b;
  add_c_in[0] = 1'b0;


  res_w   = add_res[ADD_MSB];
  res_p_w = add_c_out[ADD_MSB];


  case (op_code[5:0])
    PE_ADD_OP: begin
        add_c_in[0] = op_d_p;
        res_p_w     = add_c_out[0];
      end
    PE_SUB_OP: begin
        add_b[0]    = ~op_b;
        add_c_in[0] = 1'b1;
      end
    PE_ABS_OP: begin
        add_a[0]    = ~op_a;
        add_c_in[0] = diff_sign;
        res_w       = diff_sign ? add_res[0] : op_a;

        res_p_w     = op_a[DataWidth-1];
    end

    PE_GTE_MAX_OP: begin
        add_b[0]    = ~op_b;
        add_c_in[0] = 1'b1;
        res_p_w     = cmpr_gte;
        res_w       = res_p_w ? op_a : op_b;

      end
    PE_LTE_MIN_OP: begin
        add_b[0]    = ~op_b;
        add_c_in[0] = 1'b1;
        res_p_w     = cmpr_lte;
        res_w       = res_p_w ? op_a : op_b;
      end
    PE_EQ_OP: begin
        res_p_w = cmpr_eq;
        res_w   = op_b;
      end
    PE_SEL_OP: begin
        res_w = op_d_p ? op_a : op_b;
      end
    PE_RSHFT_OP: begin
        res_w = op_a >> op_b[3:0];
      end
    PE_RSHFT_S_OP: begin
        res_w = $signed(op_a) >>> op_b[3:0];
      end
    PE_LSHFT_OP: begin
        res_w = op_a << op_b[3:0];
      end
    PE_MULT_0_OP: begin
        res_w   = mult_res[DataWidth-1:0];
        res_p_w = mult_c_out;
      end
    PE_MULT_1_OP: begin
        res_w   = mult_res[3*DataWidth/2-1:DataWidth/2];
        res_p_w = mult_c_out;
      end
    PE_MULT_2_OP: begin
        res_w   = mult_res[2*DataWidth-1:DataWidth];
        res_p_w = mult_c_out;
      end
    PE_OR_OP: begin
        res_w = op_a | op_b;
      end
    PE_AND_OP: begin
        res_w = op_a & op_b;
      end
    PE_XOR_OP: begin
        res_w = op_a ^ op_b;
      end
    PE_INV_OP: begin
        res_w = ~op_a;
      end


    default: begin
        res_w   = op_a;
        res_p_w = op_d_p;
      end
  endcase
end


assign res   = res_w;
assign res_p = res_p_w;

endmodule




