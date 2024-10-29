

A simplified version of "scalar_fpdivsqrt".


F32_DIV: 2 ~ 10
F64_DIV: 2 ~ 17
F32_SQRT: 2 ~ 10
F64_SQRT: 2 ~ 17

// TODO

**Latency Details For Division**

|Situation|F64|F32|F16|
|------|------|------|------|
|Normal inputs, normal result|11|6|4|
|Normal inputs, denormal result|12|7|5|
|1 or 2 deormal inputs, normal result|12|7|5|
|1 or 2 deormal inputs, denormal result|13|8|6|
|Result is Overflow/Inf/NaN|2|2|2|
|Normal inputs, normal result, divisor is power of 2|2|2|2|
|1 or 2 deormal inputs, normal result, divisor is power of 2|3|3|3|
|1 or 2 deormal inputs, denormal result, divisor is power of 2|4|4|4|


**Latency Details For Square Root**

|Situation|F64|F32|F16|
|------|------|------|------|
|Normal input|15|8|5|
|Denormal input|16|9|6|
|Result is Inf/NaN|2|2|2|
|Normal input, op is power of 2|2|2|2|
|Denormal input, op is power of 2|3|3|3|
