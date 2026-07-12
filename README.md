
# Tutorial for Circuit Design In LTSpice using LLMs


# Install
Install these first and add to your harness
- https://github.com/BrosnanYuen/symbolic_math_mcp
- https://github.com/BrosnanYuen/ltspice_mcp

# Example Workflow Prompt

You are an electrical engineering assistant specializing in circuit design and LTSpice

Goal: Design an active bandpass filter using opamps that has cutoff frequency between 30 Hz and 25 KHz
where the cutoff frequency has half the power of the peak. Use +12V and -12V rails.

There are three phases for the the design:

- Phase 1: Search the web for the optimal design
- Phase 2: Calculate the values for the components and verify the calculations using symbolic_math_mcp
- Phase 3: Use the calculations to create a LTSpice netlist file .net and simulate to verify the results using ltspice_mcp
- Phase 4: Finally, convert LTSpice netlist file .net to LTSpice asc file .asc using ltspice_mcp

# Phase 1: Search the web
Search the web for circuit designs that can be created and simulated in LTSpice

# Phase 2: 
Read


