`ifndef BP_DEFINE_VH
`define BP_DEFINE_VH

`define PcWidth 32

// PHT
`define PhtAddrWidth 10
`define PhtStateWidth 2
`define PhtWbusWidth (1 + `PhtAddrWidth + `PhtStateWidth) // 13

// BTB
`define BtbTagWidth 22
`define BtbAddrWidth 7
`define BtbDataWidth 55
`define BtbWbusWidth (1 + 1 + `BtbAddrWidth + `BtbTagWidth + `PcWidth) // 63

`define IStoBPWbusWidth (`PhtWbusWidth + `BtbWbusWidth) // 76
`define BpBusRd (1 + 1 + `PhtStateWidth + 1 + `PcWidth) // 37
`define IfToBpBusWidth (1+ `PcWidth) //33

// States
`define STRONG_NOT_TAKEN 2'b00
`define WEAK_NOT_TAKEN   2'b01  
`define WEAK_TAKEN       2'b10
`define STRONG_TAKEN     2'b11

`endif