#!/bin/bash
export $(cat .env | xargs)

forge create --rpc-url https://polygon-mainnet.g.alchemy.com/v2/3FBkWF2fDhkZkZLp9-2YTgRFRf8NSRc5 \
    --constructor-args 0x28C043116B7E11776Bd27a945E8d9700222B8804 0xc2132d05d31c914a87c6611c10748aeb04b58e8f 0xc59456f40E0d6fB484b0e83502f07fa7B9A75f37\
    --private-key "$PRIVATE_KEY" \
    --etherscan-api-key "$POLYGONSCAN_API_KEY" \
    --verify \
    src/tokenDirectSale.sol:tokenDirectSale  --legacy
