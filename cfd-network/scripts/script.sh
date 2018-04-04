#!/bin/bash

echo
echo " ____    _____      _      ____    _____ "
echo "/ ___|  |_   _|    / \    |  _ \  |_   _|"
echo "\___ \    | |     / _ \   | |_) |   | |  "
echo " ___) |   | |    / ___ \  |  _ <    | |  "
echo "|____/    |_|   /_/   \_\ |_| \_\   |_|  "
echo
echo "Certified Fabric Developer Network (CFDN)"
echo
CHANNEL_NAME="$1"
DELAY="$2"
LANGUAGE="$3"
TIMEOUT="$4"
: ${CHANNEL_NAME:="mychannel"}
: ${DELAY:="3"}
: ${LANGUAGE:="golang"}
: ${TIMEOUT:="10"}
LANGUAGE=`echo "$LANGUAGE" | tr [:upper:] [:lower:]`
COUNTER=1
MAX_RETRY=5
ORDERER_CA=/opt/gopath/src/github.com/hyperledger/fabric/peer/crypto/ordererOrganizations/example.com/orderers/orderer.example.com/msp/tlscacerts/tlsca.example.com-cert.pem

CC_SRC_PATH="github.com/chaincode/chaincode_example02/go/"
if [ "$LANGUAGE" = "node" ]; then
	CC_SRC_PATH="/opt/gopath/src/github.com/chaincode/chaincode_example02/node/"
fi

echo "Channel name : "$CHANNEL_NAME

# import utils
. scripts/utils.sh

createChannel() {
	setGlobals 0 1

	if [ -z "$CORE_PEER_TLS_ENABLED" -o "$CORE_PEER_TLS_ENABLED" = "false" ]; then
                set -x
		peer channel create -o orderer.example.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx >&log.txt
		res=$?
                set +x
	else
				set -x
		peer channel create -o orderer.example.com:7050 -c $CHANNEL_NAME -f ./channel-artifacts/channel.tx --tls $CORE_PEER_TLS_ENABLED --cafile $ORDERER_CA >&log.txt
		res=$?
				set +x
	fi
	cat log.txt
	verifyResult $res "Channel creation failed"
	echo "===================== Channel \"$CHANNEL_NAME\" is created successfully ===================== "
	echo
}

joinChannel () {
	for org in 1 2; do
	    for peer in 0 1; do
		joinChannelWithRetry $peer $org
		echo "===================== peer${peer}.comp${org} joined on the channel \"$CHANNEL_NAME\" ===================== "
		sleep $DELAY
		echo
	    done
	done
}

## Create channel
echo "Creating channel..."
createChannel

## Join all the peers to the channel
echo "Having all peers join the channel..."
joinChannel

## Set the anchor peers for each org in the channel
echo "Updating anchor peers for comp1..."
updateAnchorPeers 0 1
echo "Updating anchor peers for comp2..."
updateAnchorPeers 0 2

## Install chaincode on peer0.comp1 and peer0.comp2
echo "Installing chaincode on peer0.comp1..."
installChaincode 0 1
echo "Install chaincode on peer0.comp2..."
installChaincode 0 2

# Instantiate chaincode on peer0.comp2
echo "Instantiating chaincode on peer0.comp2..."
instantiateChaincode 0 2

# Query chaincode on peer0.comp1
echo "Querying chaincode on peer0.comp1..."
chaincodeQuery 0 1 100

# Invoke chaincode on peer0.comp1
echo "Sending invoke transaction on peer0.comp1..."
chaincodeInvoke 0 1

## Install chaincode on peer1.comp2
echo "Installing chaincode on peer1.comp2..."
installChaincode 1 2

# Query on chaincode on peer1.comp2, check if the result is 90
echo "Querying chaincode on peer1.comp2..."
chaincodeQuery 1 2 90

echo
echo "========= All GOOD, CFDN execution completed =========== "
echo

echo
echo " _____   _   ___   _     "
echo "| ____| | | |   \ | |    "
echo "| |_    | | | |\ \| |    "
echo "|  _|   | | | | \   |    "
echo "| |     | | | |  \  |  _ "
echo "|_|     |_| |_|   \_| |_|"
echo

exit 0
