//`timescale 1ns / 1ps
module fifo #(parameter addresswidth=5)(input logic rd, wr, rst, clk, output logic wr_en, rd_en, emp, full, output reg [addresswidth:0]rd_ptr, wr_ptr);
wire [addresswidth:0]status;

assign status = wr_ptr - rd_ptr; /* checks for FIFO full and 
                                    empty */

assume property (!(wr == 1 && rd == 1));	
	
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
	
always @(posedge clk)begin
	if($initstate)begin
/*		
		assert(!(full && emp));
		assert(!(rd && wr));

		if(status == 0)
			assert(emp == 1 && full == 0);

		if(status == 6'b100000)
			assert(full == 1 && emp == 0);
*/
		if(rst)
			assert(rd_ptr == 0);
		
	end
end
endmodule
