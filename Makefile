### fifo

fifo: fifo.smt2
	yosys-smtbmc -t 25 --dump-vcd fifo_bmc.vcd --dump-smt2 fifoSMT2.log fifo.smt2 
	yosys-smtbmc -t 25 -i --dump-vcd fifo.vcd fifo.smt2 

fifo.smt2: fifo.sv  
	yosys -ql fifo.yslog \
		-p 'read_verilog -sv -formal fifo.sv' \
		-p 'prep -top fifo -nordff' \
		-p 'techmap -autoproc -map cells_sim.v' \
		-p 'techmap -map adff2dff.v' \
		-p 'hierarchy -check; proc; opt; check -assert' \
		-p 'write_smt2 -verbose -wires fifo.smt2'

clean::
	rm -f fifo.yslog fifo.smt2 fifo.vcd
