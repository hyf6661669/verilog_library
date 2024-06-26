

This is a high performance ```Vector``` floating point square-rooter, which is in compliance with riscv-spec.

The width of input/output data is 64, which could represent "1 F64"/"2 F32"/"4 F16", based on your requirement.


# Latency Details (Measured in cycles)

## Scalar Mode
|Operand|Normalization|Initialization|SRT_ITER|Rounding|Total|
|------|------|------|------|------|------|
|normal input|0|0.8|F64: 13; F32: 6; F16: 3|1|F64: 15, F32: 8, F16: 5|
|denormal input|1.2|0.8|F64: 13; F32: 6; F16: 3|1|F64: 16, F32: 9, F16: 6|

_When the operand is a normal number and is a power of 2, the "SRT_ITER" step could be skipped._

_So the latency could be reduced by 13/6/3 for F64/F32/F16._

## Vector Mode
|Normalization|Initialization|SRT_ITER|Rounding|Total|
|------|------|------|------|------|
|1.2|0.8|F64: 13; F32: 6; F16: 3|1|F64: 16, F32: 9, F16: 6|

_Although I can check whether all the operands are ```normal numbers```, or ```a power of 2``` in vector mode, in order to reduce the latency,_
_I think the condition would be difficult to meet._

_For example, for F16 in vector mode, you can only skip the iter when the 4 input operands are all a power of 2._

_So I choose to never skip the iter, and always do normalization in vector mode._

# Performance Comparison with Other CPUs (Normal Input in Scalar Mode)

|CPU|F16|F32|F64|
|------|------|------|------|
|**This design**|**5**|**8**|**15**|
|Intel Coffee Lake[^coffee]|x|12|15 ~ 16|
|AMD Zen3/Zen2[^amd]|x|14|20|
|AMD Jaguar[^Jaguar]|x|16|27|
|ARM Cortex A55, and other "small cores"[^arm]|8|12|22|
|ARM Cortex A76, and its successors[^arm]|7|7 ~ 10|7 ~ 17|
|ARM Cortex A75[^arm]|6 ~ 7|6 ~ 11|6 ~ 18|
|ARM Cortex A72[^arm]|x|6 ~ 17|6 ~ 32|
|IBM Z13[^ibm]|x|22|37|
|HAL Sparc[^HAL]|x|22|27|
|OpenC910[^c910]|4 ~ 7|4 ~ 10|4 ~ 17|


[^coffee]: https://www.agner.org/optimize/instruction_tables.pdf
[^amd]: https://www.amd.com/en/support/tech-docs
[^Jaguar]: http://ieeexplore.ieee.org/document/6545886?arnumber=6545886
[^arm]: https://developer.arm.com/documentation
[^ibm]: https://ieeexplore.ieee.org/abstract/document/7563276/
[^HAL]: http://ieeexplore.ieee.org/abstract/document/930117/similar
[^c910]: https://github.com/T-head-Semi/openc910
