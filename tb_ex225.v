`timescale 1ns / 1ps

// Verilog testbench for a single-stage RISC-V processor
// Made by Choi, Young-kyu, Inha University, Computer Engineering, ykc@inha.ac.kr
// Last Updated: May 28, 2022
// Tests: Exercise 2.25 of Computer Organization & Design, RISCV 2nd edition 
//        (made by Lee, Chae Yeon, Inha CE'19)
//for(i = 0; i < a; i++)
//  for(j = 0; j < b; j++)
//    D[4*j] = i + j;


`define INST_MEMSIZE 12
`define DATA_MEMSIZE 1024

`define A_SIZE 3
`define B_SIZE 4
`define RUN_INST 90


module tb_ex225;

	reg CLK;
	reg RST;
	
	wire [31:0] InstMemRAddr;
	wire [31:0] InstMemRData;
		
	wire [31:0] DataMemAddr;
	wire DataMemRead;
	wire DataMemWrite;		
	wire [31:0] DataMemRData;
	wire [31:0] DataMemWData;
	
	localparam  [0:32*`INST_MEMSIZE-1] InstMem  = {
		32'h00000393, //addi x7, x0, 0 (assumes the baseaddr of D is 0)
		32'h02538663, //LOOPI : beq x7, x5, 44 (ENDI)
		32'h00000513, //addi x30, x10, 0
		32'h00000E93, //addi x29, x0, 0
		32'h006E8C63, //LOOPJ : beq x29, x6, 24(ENDJ)
		32'h01D38FB3, //add x31, x7, x29
		32'h01F52023,	//sw x31, 0(x30)
		32'h01050513, //addi x30, x30, 16
		32'h001E8E93, //addi x29, x29, 1
		32'hFEDFF06F, //jal x0, -20(LOOPJ)
		32'h00138393, //ENDJ : addi x7, x7, 1
		32'hFD9FF06F  //jal x0, -40(LOOPI)
		//ENDI:
	};
	
	RISCV u_RISCV( 
		.CLK(CLK),
		.RST(RST),
		
		.InstMemRAddr(InstMemRAddr),
		.InstMemRData(InstMemRData),
		
		.DataMemAddr(DataMemAddr),
		.DataMemRead(DataMemRead),
		.DataMemWrite(DataMemWrite),
		.DataMemRData(DataMemRData),
		.DataMemWData(DataMemWData)
   );
	
	reg [31:0] DataMem [`DATA_MEMSIZE-1:0];
	
	assign InstMemRData = (InstMemRAddr < `INST_MEMSIZE*4) ? InstMem[InstMemRAddr*8 +:32] : 0;
	
	assign DataMemRData = (DataMemRead == 1) ? DataMem[DataMemAddr] : 32'hX;
	
	always @(posedge CLK) begin
		if( DataMemWrite == 1 ) begin
			DataMem[DataMemAddr] = DataMemWData;
		end
	end	
	
	always begin
		#5 CLK = ~CLK;
	end
   
	integer i, j, error_cnt;
	initial begin
		// Initialize Inputs
		CLK = 1;
		RST = 1;
		
		#5; RST = 0;
		#20; RST = 1;
		u_RISCV.u_RegFiles.Registers[1] = 100; //set return address of init func call to 100
		u_RISCV.u_RegFiles.Registers[2] = `DATA_MEMSIZE; //set SP to the data mem size
		u_RISCV.u_RegFiles.Registers[5] = `A_SIZE;
		u_RISCV.u_RegFiles.Registers[6] = `B_SIZE;
		
		#10;
		
		#(10 * `RUN_INST);
		
		#20;			
		
		error_cnt = 0;
		//note: only check when i== `A_SIZE -1, since the rest is overwritten
		i = `A_SIZE-1;
		for(j = 0; j < `B_SIZE; j = j + 1) begin
			if(DataMem[16*j] != i + j) begin
				$display("error detected at j = %d. Expected %d, but obtained %d", j, i + j, DataMem[16*j]);
				error_cnt = error_cnt + 1;
			end
		end
		$display("error cnt: %d ", error_cnt);	
		$finish;
	end
      
endmodule