#!/bin/bash
export $(cat .env | xargs)

forge create --rpc-url "$BASE_MAINNET_RPC_URL" \
    --constructor-args 0xb36a0e830bd92e7aa5d959c17a20d7656976dd98 \
    --private-key "$PRIVATE_KEY" \
    --etherscan-api-key "$BASESCAN_API_KEY" \
    --verify \
    src/Faucet.sol:Faucet  --legacy
