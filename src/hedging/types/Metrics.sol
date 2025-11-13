
// import "./types/Metrics.sol";

// concatentation of uint48 block_timestamp
// and uint32 block_number;
type PackedTimeData is uint80;

struct Metrics{
    // uint32 block_number;
    // uint48 block_timeStamp;
    bytes data;
}

using PackedTimeDataLib for PackedTimeData global;

library PackedTimeDataLib{

    function build(uint48 _block_timeStamp, uint32 _block_number) internal pure returns(uint80){
        return uint80(0x34); //placeholder
    }
    function block_number(PackedTimeData) internal pure returns(uint32){
        return uint32(0x56); //placeholder
    }

    function block_timeStamp(PackedTimeData) internal pure returns(uint48){
        return uint48(0x12); // placeholder
    }

}



