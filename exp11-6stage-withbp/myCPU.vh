`ifndef MYCPU_VH
    `define MYCPU_VH

    // Branch Defines
    `define BR_BUS             66
    `define DEFAULT_BRANCH_TYPE 0
    `define BRANCH_TYPE_LEN    4
    `define BRANCH_BEQ         1
    `define BRANCH_BNE         2
    `define BRANCH_BLT         3
    `define BRANCH_BGE         4
    `define BRANCH_BLTU        5
    `define BRANCH_BGEU        6
    `define BRANCH_B           7
    `define BRANCH_BL          8
    `define BRANCH_JIRL        9
    
    `define BP_INFO_WIDTH      37  // predict_valid(1) + predict_taken(1) + predict_state(2) + btb_hit(1) + predict_target(32)
    // Pipeline bus widths
    `define FS_TO_DS_BUS_WD (64)  
    `define DS_TO_IS_BUS_WD (175 + `BP_INFO_WIDTH) // 210
    `define IS_TO_ES_BUS_WD 192
    `define ES_TO_MS_BUS_WD 107
    `define MS_TO_WS_BUS_WD 70
    `define WS_TO_RF_BUS_WD 38
    
    // Fifo Defines
   `define LAUNCH_QUEUE_WIDTEH 2                                          // queue width
   `define LAUNCH_QUEUE_POINTER_WIDTEH 1                                  // queue pointer width 
   `define LAUNCH_QUEUE_MAX_LEN `LAUNCH_QUEUE_WIDTEH                      // queue max lenth 
   `define LAUNCH_QUEUE_LEN_WIDTH 2                                       // queue lenth counter width 
   `define LAUNCH_QUEUE_ALLOWIN_CRITICAL_VALUE 1
   `define DOUBLE_LAUNCH         0                  
   `define LINE_FIFO_DATA_BUS_WD `DS_TO_IS_BUS_WD            
   `define FIFO_DATA_BUS_WD      (2 * `LINE_FIFO_DATA_BUS_WD) 
    
    // Forwarding bus widths
    `define ES_TO_IS_FORWARD_BUS 38
    `define MS_TO_IS_FORWARD_BUS 38
    `define WS_TO_IS_FORWARD_BUS 38
    `define MS_TO_ES_FORWARD_BUS 33

    // Hazard detection bus widths
    `define IS_TO_HAZARD_BUS_WD 11
    `define ES_TO_HAZARD_BUS_WD 7
    `define MS_TO_HAZARD_BUS_WD 1

`endif