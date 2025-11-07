`ifndef MYCPU_VH
    `define MYCPU_VH

    `define BR_BUS          33
    // Pipeline bus widths
    `define FS_TO_DS_BUS_WD 64
    `define DS_TO_ES_BUS_WD 192
    `define ES_TO_MS_BUS_WD 107
    `define MS_TO_WS_BUS_WD 70
    `define WS_TO_RF_BUS_WD 38
    
    // Forwarding bus widths
    `define ES_TO_DS_FORWARD_BUS 38
    `define MS_TO_DS_FORWARD_BUS 38
    `define WS_TO_DS_FORWARD_BUS 38
    `define MS_TO_ES_FORWARD_BUS 33

    // Hazard detection bus widths
    `define DS_TO_HAZARD_BUS_WD 13
    `define ES_TO_HAZARD_BUS_WD 7
    `define MS_TO_HAZARD_BUS_WD 1

`endif