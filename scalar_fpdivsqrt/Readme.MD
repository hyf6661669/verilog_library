

This is a high performance ***SCALAR*** floating point divider/square rooter.



# Latency Details (Measured in cycles)

|Operands Combination|Normalization|Scaling|SRT_ITER|Denormalization|Rounding|Total|
|------|------|------|------|------|------|------|
|normal inputs, normal result|0|1.8|F64: 9; F32: 4; F16: 2|0|1|F64: 12; F32: 7; F16: 5|
|denormal inputs, normal result|1.2|1.8|F64: 9; F32: 4; F16: 2|0|1|F64: 13; F32: 8; F16: 6|
|normal inputs, denormal result|0|1.8|F64: 9; F32: 4; F16: 2|1|1|F64: 13; F32: 8; F16: 6|
|denormal inputs, denormal result|1.2|1.8|F64: 9; F32: 4; F16: 2|1|1|F64: 14; F32: 9; F16: 7|




