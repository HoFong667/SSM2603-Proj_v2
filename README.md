# SSM2603-Proj_v2

Previous:
Target device: SSM2603 from Analog Device, Audio Codec Target board: Zybo Z7, Zynq-7000 ARM/FPGA SoC Development Board

Description: Direct input and output of audio including ADC and DAC operation. The audio codec is initialized using I2C and once the SW0 switch is turned on, I2S will be preformed for data capture or placement. All is done by VHDL. To facilitate these operations, two clocks need to be generated: one at 24.576MHz for I2S and another at 5MHz for I2C.

Line IN: Audio in HPH Out: Audio out SW0: Direct input/output activation BTN3: Reset, re-initialize

Update:
The I2C module has been split into separate components and now includes a record mode and play back mode, each lasting for 5 seconds. Additionally, the 'clip' effect has been incorporated, but unfortunately, the codec automatically adjusts the changes I made. To support these functionalities, an IP block memory with a width of 16 bits and a size of 288000 depth needs to be added to the project.

BTN0: record for 5 sec BTN1: playback 5 sec and SW1: 'clip' effect.
