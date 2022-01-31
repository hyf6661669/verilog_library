
This is a highly-optimized integer divider that supports 32/64-bit signed unsigned operands. You can change the ```D_W``` parameter based on your need.

The algorithm used in this module is "Retimied Radix-4 SRT", 2 R4 blocks are overlapped to form a single R16 block, which means it can generate 4-bit quotient every
cycle.

It should be very easy to make this module only support ```I16``` with very little modfication. But I'm just lazy and I think a I16 divider is rarely used in recent design.

## Latency

I32: 3 ~ 11

I64: 3 ~ 19


