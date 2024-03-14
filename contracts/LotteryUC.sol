//SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.9;

import "./base/UniversalChanIbcApp.sol";

contract LotteryUC is UniversalChanIbcApp {
    // application specific state
    address public deployer;

    enum LotteryBridgeDirection {
        None,
        Optimism,
        Base
    }

    // round => user => boolean for checking if user has already bridged
    mapping(uint8 => mapping(address => bool)) public userBridges;

    // userBridges should be stored in an array as we need to iterate over it
    // the structure would be: {address, round, direction, timestamp}
    struct Bridge {
        address user;
        uint8 round;
        LotteryBridgeDirection direction;
        uint256 timestamp;
    }

    // create an array of Bridge structs
    Bridge[] public bridges;

    // round => direction
    mapping(uint8 => LotteryBridgeDirection) public roundDirections;

    // if startTime is 0, the lottery is not started
    uint256 public startTime = 0;

    // maximum rounds
    uint8 MAX_ROUNDS = 4;

    // 2 hours per round
    // Debug: 300 seconds per round
    uint32 PER_ROUND_SECONDS = 300;

    // events
    event LotteryStarted(uint256 startTime);
    event BridgeStarted(
        address user,
        uint8 round,
        LotteryBridgeDirection direction
    );
    event BridgeReceived(
        address user,
        uint8 round,
        LotteryBridgeDirection direction
    );
    event BridgeAcknowledged(
        address user,
        uint8 round,
        LotteryBridgeDirection direction
    );

    constructor(address _middleware) UniversalChanIbcApp(_middleware) {
        deployer = msg.sender;

        // set the start time to the current block timestamp
        startTime = block.timestamp;

        // set the start direction to Optimism
        roundDirections[0] = LotteryBridgeDirection.Optimism;
    }

    function currentDirection() public view returns (LotteryBridgeDirection) {
        return roundDirections[determineRound()];
    }

    function setStartTime(uint256 _startTime) public {
        if (msg.sender != deployer) {
            revert("Only deployer can set start time");
        }

        startTime = _startTime;

        emit LotteryStarted(startTime);
    }

    function determineRound() public view returns (uint8) {
        return uint8((block.timestamp - startTime) / PER_ROUND_SECONDS);
    }

    function _determindDirection() internal returns (LotteryBridgeDirection) {
        // generate a random number
        uint256 randomNumber = uint256(
            keccak256(
                abi.encodePacked(
                    block.timestamp,
                    block.prevrandao,
                    msg.sender,
                    determineRound()
                )
            )
        );

        // if the number is even, return Optimism
        if (randomNumber % 2 == 0) {
            // save direction
            roundDirections[determineRound()] = LotteryBridgeDirection.Optimism;
            return LotteryBridgeDirection.Optimism;
        } else {
            // save direction
            roundDirections[determineRound()] = LotteryBridgeDirection.Base;
            return LotteryBridgeDirection.Base;
        }
    }

    function isLotteryOver() public view returns (bool) {
        return determineRound() >= MAX_ROUNDS;
    }

    function getAllBridges() public view returns (Bridge[] memory) {
        return bridges;
    }

    // IBC logic

    /**
     * @dev Sends a packet with the caller's address over the universal channel.
     * @param destPortAddr The address of the destination application.
     * @param channelId The ID of the channel to send the packet to.
     * @param timeoutSeconds The timeout in seconds (relative).
     */
    function bridge(
        address destPortAddr,
        bytes32 channelId,
        uint64 timeoutSeconds
    ) external {
        require(startTime != 0, "Lottery is not started");
        require(!isLotteryOver(), "Lottery is over");
        require(startTime < block.timestamp, "Lottery is not started");

        uint8 round = determineRound();
        require(round < MAX_ROUNDS, "Lottery is over");

        // if user has already bridged
        require(
            userBridges[round][msg.sender] == false,
            "You have already bridged"
        );

        // save user bridge to prevent double bridging
        userBridges[round][msg.sender] = true;

        // if direction is not set, set it
        if (roundDirections[round] == LotteryBridgeDirection.None) {
            roundDirections[round] = _determindDirection();
        }

        // user address, timestamp
        bytes memory payload = abi.encode(
            msg.sender,
            round,
            roundDirections[round]
        );

        uint64 timeoutTimestamp = uint64(
            (block.timestamp + timeoutSeconds) * 1000000000
        );

        IbcUniversalPacketSender(mw).sendUniversalPacket(
            channelId,
            IbcUtils.toBytes32(destPortAddr),
            payload,
            timeoutTimestamp
        );

        emit BridgeStarted(msg.sender, round, roundDirections[round]);
    }

    /**
     * @dev Packet lifecycle callback that implements packet receipt logic and returns and acknowledgement packet.
     *      MUST be overriden by the inheriting contract.
     *
     * @param channelId the ID of the channel (locally) the packet was received on.
     * @param packet the Universal packet encoded by the source and relayed by the relayer.
     */
    function onRecvUniversalPacket(
        bytes32 channelId,
        UniversalPacket calldata packet
    ) external override onlyIbcMw returns (AckPacket memory ackPacket) {
        recvedPackets.push(UcPacketWithChannel(channelId, packet));

        (address _sender, uint8 _round, uint8 _direction) = abi.decode(
            packet.appData,
            (address, uint8, uint8)
        );

        // push bridge to array
        bridges.push(
            Bridge(
                _sender,
                _round,
                LotteryBridgeDirection(_direction),
                block.timestamp
            )
        );

        // also need to update the status of the user bridge in the destination contract
        userBridges[_round][_sender] = true;

        // also the direction, if it's not set
        if (roundDirections[_round] == LotteryBridgeDirection.None) {
            roundDirections[_round] = LotteryBridgeDirection(_direction);
        }

        emit BridgeReceived(
            _sender,
            _round,
            LotteryBridgeDirection(_direction)
        );

        return
            AckPacket(
                true,
                abi.encode(_sender, _round, _direction, block.timestamp)
            );
    }

    /**
     * @dev Packet lifecycle callback that implements packet acknowledgment logic.
     *      MUST be overriden by the inheriting contract.
     *
     * @param channelId the ID of the channel (locally) the ack was received on.
     * @param packet the Universal packet encoded by the source and relayed by the relayer.
     * @param ack the acknowledgment packet encoded by the destination and relayed by the relayer.
     */
    function onUniversalAcknowledgement(
        bytes32 channelId,
        UniversalPacket memory packet,
        AckPacket calldata ack
    ) external override onlyIbcMw {
        ackPackets.push(UcAckWithChannel(channelId, packet, ack));

        // decode the counter from the ack packet
        (
            address _sender,
            uint8 _round,
            uint8 _direction,
            uint256 _timestamp
        ) = abi.decode(ack.data, (address, uint8, uint8, uint256));

        //
        emit BridgeAcknowledged(
            _sender,
            _round,
            LotteryBridgeDirection(_direction)
        );
    }

    /**
     * @dev Packet lifecycle callback that implements packet receipt logic and return and acknowledgement packet.
     *      MUST be overriden by the inheriting contract.
     *      NOT SUPPORTED YET
     *
     * @param channelId the ID of the channel (locally) the timeout was submitted on.
     * @param packet the Universal packet encoded by the counterparty and relayed by the relayer
     */
    function onTimeoutUniversalPacket(
        bytes32 channelId,
        UniversalPacket calldata packet
    ) external override onlyIbcMw {
        timeoutPackets.push(UcPacketWithChannel(channelId, packet));
        // do logic
    }
}
