EDIT=srcSim/*.v srcDesign/*.v makefile Readme.md
SIMTOP=srcSim/top.v
VINCLUDES=-IsrcSim -IsrcDesign

EDITOR_EXE=/c/Emacs/emacs-29.1/bin/runemacs.exe
IVERILOG_EXE=/c/iverilog/bin/iverilog.exe
IVVP_EXE=/c/iverilog/bin/vvp.exe
GTKWAVE_EXE=/c/iverilog/gtkwave/bin/gtkwave.exe
IVERILOG_OUT=a.out
VVP_OUT=a.vcd
all: help
help:
	@echo "targets:"
	@echo "  help		shows this message"
	@echo "  edit		opens selected files in editor"
	@echo "  sim		run iverilog simulation (baseline)"
	@echo "  view		view simulation results (baseline)"
	@echo "  clean		remove generated files"
	@echo "  cleaner	remove more"

	@echo "  simAxiReadyValid		run specific iverilog simulation"

edit:
	${EDITOR_EXE} ${EDIT}

sim:
	${IVERILOG_EXE} -g2005-sv ${VINCLUDES} -o ${IVERILOG_OUT} -DSIM ${SIMTOP}
	${IVVP_EXE} ${IVERILOG_OUT}

simAxiReadyValid:
	${IVERILOG_EXE} -g2005-sv ${VINCLUDES} -o ${IVERILOG_OUT} -DSIM -s simTop srcSim/simAxiToReadyValid.v
	${IVVP_EXE} ${IVERILOG_OUT}

view:
	@echo "splash_disable 1" > .gtkwave_tmp
	${GTKWAVE_EXE} -r .gtkwave_tmp ${VVP_OUT} &	

clean:
	rm -f ${IVERILOG_OUT} ${VVP_OUT} .gtkwave_tmp
cleaner: clean
	find . -name "*~" -exec rm -f {} \;

.PHONY: help edit sim view clean simAxiReadyValid
