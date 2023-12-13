#!/bin/bash
export $(cat .env | xargs)

forge create --rpc-url https://polygon-mainnet.g.alchemy.com/v2/3FBkWF2fDhkZkZLp9-2YTgRFRf8NSRc5 \
    --constructor-args 0x400Af0980E528BA42750A73C43BaDcf16c158ab6 \
    --private-key "$PRIVATE_KEY" \
    --etherscan-api-key "$POLYGONSCAN_API_KEY" \
    --verify \
    src/nftMinter.sol:nftMinter  --legacy
