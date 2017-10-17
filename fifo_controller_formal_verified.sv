// ##############################################################################
/*
fifo.sv - Module includes design of fifo and formal verification code to verify it with Yosys-SMTBMC

Created By: Aditya Pawar

Design Description:
The FIFO is a type of memory that stores data serially, where the first word read is the first word that
was stored. The FIFO is a two-port RAM array having separate read and write data buses, separate read and write
address buses, a write signal and a read signal. The size of the RAM array is 32 x 8 bits. Data is read from and written into the FIFO at 
the same rate (a very trivial case of the FIFO).
The FIFO controller has the following input and output signals:

rst 	Input / 1 bit 	Active high 	Asynch global reset

clk 	Input		  ----		Controller clock

wr  	Input / 1 bit   Active high	From external device wanting to write data into FIFO	

rd 	Input / 1 bit 	Active high 	From external device wanting to read data from FIFO

wr_en 	Output / 1 bit 	Active high 	To FIFO as write signal

rd_en 	Output / 1 bit 	Active high 	To FIFO as read signal

rd_ptr	Output / 5 bits	   ----		read address bus to FIFO

wr_ptr	Output / 5 bits	   ----		write address bus to FIFO

emp 	Output / 1 bit	Active high 	Indicates that FIFO is empty

full 	Output / 1 bit 	Active high 	Indicates that FIFO is full

The read pointer rd_ptr contains the address of the next FIFO location to be read while the write pointer
wr_ptr contains the address of the next FIFO location to be written. At reset, both pointers are initialized to
point to the first location of the FIFO, emp is made high and full is made low. If an external device wishes
to read data from the FIFO by asserting rd, then the controller asserts rd_en only if emp is deasserted. A
similar logic exists for the write operation. The crux of this design is in determining the conditions which
lead to the assertion/deassertion of the emp and full signals.

*/
module fifo_contrller #(parameter addresswidth=5)(input logic rd, wr, rst, clk, output logic wr_en, rd_en, emp, full, output reg [addresswidth:0]rd_ptr, wr_ptr);
wire [addresswidth:0]status;

assign status = wr_ptr - rd_ptr; /* checks for FIFO full and 
                                    empty */

always_ff @(posedge clk, posedge rst)
begin

	if(rst == 1)
		begin
   			rd_ptr <=0; // Initialize to zero
   			wr_ptr <=0;
		end

	else
		begin
    			if(rd==1 && emp!=1) // read if not empty
    				begin
      	  				rd_en <= 1;
      	  				rd_ptr <= rd_ptr + 1;        
    				end

    			else
    				begin
        				rd_en<=0;
        				rd_ptr<=rd_ptr; /* don't increment read pointer if FIFO
                           				is empty */
    				end

    			if(wr==1 && full!=1) // write if not full
    				begin
        				wr_en<=1;
        				wr_ptr<=wr_ptr+1;
    				end

    			else
    				begin
        				wr_en<=0;
        				wr_ptr<=wr_ptr;   /* don't increment write pointer if FIFO
                           				is full */
    				end
		end

end

always_comb // @(emp,full,status)
begin

emp = 0;
full = 0;

if(status == 0) // check for FIFO empty
	begin
   		emp = 1;
	end
else 
	begin
   		if(status == 1<<addresswidth)  // check for FIFO full
   		full = 1;
	end

end



// ###########################################################################

// Verification Block 

// ##########################################################################
`ifdef FORMAL
// 1. FIFO full condition properties:
//	a. Full and empty will not be 1 at the same time. 
//	b. Empty signal should be asserted when the status equals zero.
//	   Full should be deasserted at same time.
//	c. FIFO full condtion i.e. when status is greater than [1 << addresswidth -1]
//	   the full flag should be asserted.
//	d. Full signal should be deasserted when status is less than [1 << addresswidth]

assume property (status <= 6'b100000);		// constrains that status will be always less than [1<<addresswidth]

always @(posedge clk)begin
	if(!$initstate)begin
		if(!rst)begin

			assert(!(full && emp)); 

			if(status == 0)
				assert(emp == 1 && full == 0);

			if(status > 6'b011111)
				assert(full == 1);
			
			if(status < 6'b100000)
				assert(full == 0);
		end
	end	
end

// ############################################
// 2. FIFO full condition properties:
//	c. The full output should remain 1, even after the FIFO is full and a write
//	   is attempted without read

reg past_full_flag;
initial past_full_flag = 0;
always @(posedge clk)begin
	past_full_flag = 1;
end
assume property (wr_ptr < 6'b100001);
assume property (rd_ptr < 6'b100001);

always @(posedge clk)begin
	assume(rst == 0);
	if(past_full_flag && $past(full) && wr && (!rd))
		assert(full);
end

// 2. FIFO full condition properties:
//	d. The write pointer should remain constant after full is asserted and write is
//	   attempted

reg past_wr_ptr_flag;
initial past_wr_ptr_flag = 0;
always @(posedge clk)begin
	past_wr_ptr_flag = 1;
end
assume property (wr_ptr < 6'b100001);
assume property (rd_ptr < 6'b100001);

always @(posedge clk)begin
	assume(rst == 0);
	if(past_wr_ptr_flag && $past(full) && wr && (!rd) && full)
		assert($stable(wr_ptr));
end

// #############################################
// 2. Asynchronous Reset Property: Read pointer, Write pointer, Empty, Full and
//				   Status should be zero on reset.				    

reg past_is_valid;
initial past_is_valid = 0;
always @(posedge clk) begin
    past_is_valid <= 1'b1;
end

always @(posedge clk)
    if ((past_is_valid)&&($past(rst)))
    begin
        assert(rd_ptr == 0 && wr_ptr == 0 && emp == 1 && full == 0 && status == 0);
    end

`endif

// ###########################################################################

endmodule
