#!/bin/bash
export $(cat .env | xargs)

forge create --rpc-url https://polygon-mainnet.g.alchemy.com/v2/3FBkWF2fDhkZkZLp9-2YTgRFRf8NSRc5 \
    --constructor-args 0x232804231dE32551F13A57Aa3984900428aDf990 \
    --private-key "$PRIVATE_KEY" \
    --etherscan-api-key "$POLYGONSCAN_API_KEY" \
    --verify \
    src/tokenDropVesting.sol:tokenDropVesting  --legacy
