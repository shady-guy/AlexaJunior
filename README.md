A hardware acclerator for a Keyword Detection ML Model
A Lenet5 model is trained on python and the weights of the convolutional and fully connected layers are exported as hex files.
The weights are stored in the BRAM of an FPGA and the mathematically heavy ML algorithms are run on the FPGA.
The hardware acclerator provides significant speedup compared to the python script.
