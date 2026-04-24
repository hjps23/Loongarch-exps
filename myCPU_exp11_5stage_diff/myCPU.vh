`ifndef MYCPU_VH
    `define MYCPU_VH

    `define BR_BUS          33
    // Pipeline bus widths
    `define FS_TO_DS_BUS_WD 64
    `define DS_TO_ES_BUS_WD 192+32
    `define ES_TO_MS_BUS_WD 107+96+32-1
    `define MS_TO_WS_BUS_WD 70+96
    `define WS_TO_RF_BUS_WD 38
    
    // Forwarding bus widths
    `define ES_TO_DS_FORWARD_BUS 38
    `define MS_TO_DS_FORWARD_BUS 38
    `define WS_TO_DS_FORWARD_BUS 38

    // Hazard detection bus widths
    `define DS_TO_HAZARD_BUS_WD 12
    `define ES_TO_HAZARD_BUS_WD 7

`endif