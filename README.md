
# Tutorial for Circuit Design In LTSpice using LLMs


# Install
Install these first and add to your harness
- https://github.com/BrosnanYuen/symbolic_math_mcp
- https://github.com/BrosnanYuen/ltspice_mcp

# Example Workflow Prompt

You are an electrical engineering assistant specializing in circuit design and LTSpice

Goal: Design an active bandpass filter using opamps that has cutoff frequency between 30 Hz and 25 KHz
where the cutoff frequency has half the power of the peak. Use +12V and -12V rails.

There are four phases for the the design, ONLY FOLLOW IN THIS ORDER:

- Phase 1: Search the web for the optimal design
- Phase 2: Calculate the values for the components and verify the calculations using symbolic_math_mcp
- Phase 3: Use the calculations to create a LTSpice netlist file .net and simulate to verify the results using ltspice_mcp
- Phase 4: Finally, convert LTSpice netlist file .net to LTSpice asc file .asc using ltspice_mcp

If something is wrong delete everything and start from begining

# Phase 1: Search the web
Search the web for circuit designs that can be created and simulated in LTSpice

# Phase 2: Calculate values for circuit design
1) Read ./YAML_tutorial.md and some of the example .yaml files in ./examples/ to create a new ./circuit.yaml containing the calculations for the circuit design

2) Read ./symbolic_math_mcp_for_LLM.md on how to use the symbolic_math_mcp server to verify the newly created ./circuit.yaml

# Phase 3: Create the LTSpice netlist file .net

1) Read ./LTSPICE_NET.md and some of the example .net files in ./examples/ to create a new LTSPice netlist ./circuit.net using the calculations above

2) Read ./run_ltspice_netlist_to_csv.md to simulate the LTSPice netlist ./circuit.net and get a csv file of simulation to verify the circuit is designed correctly

3) Write python code to read the .csv files and verify the circuit design works

# Phase 4: Convert the LTSpice .net to .asc

Read ./ltspice_mcp_for_LLM.md and use ltspice_netlist_to_asc from ltspice_mcp to convert LTSpice .net files to LTSpice .asc files

