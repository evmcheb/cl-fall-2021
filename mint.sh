#!/bin/bash

NFT_CONTRACT=0xB2C7C58eD50cDD635cb2CB25336BF529e0B37599
MINT="mint(address)(uint256)"
ME=0x4A9BffAB0b3758D0c03055Ff37d7D1E1B23fb849
seth send --status --password password.txt $NFT_CONTRACT $MINT $ME 
