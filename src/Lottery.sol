// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/// @title ETH Lottery
/// @notice Pay 0.001 ETH to enter. Owner draws winner after deadline. Winner takes 90%, 10% fee.
/// @dev Uses block hash for randomness — good enough for low-stakes fun, not for high-value draws.
contract Lottery {
    address public owner;
    uint256 public constant TICKET_PRICE = 0.001 ether;
    uint256 public constant DURATION = 7 days;
    uint256 public constant FEE_BPS = 1000; // 10%

    struct Round {
        uint256 id;
        uint256 startTime;
        uint256 endTime;
        address[] participants;
        address winner;
        uint256 prize;
        bool drawn;
    }

    Round[] public rounds;
    mapping(uint256 => mapping(address => uint256)) public ticketsByRound;

    event RoundStarted(uint256 indexed roundId, uint256 endTime);
    event TicketPurchased(uint256 indexed roundId, address indexed buyer, uint256 count);
    event WinnerDrawn(uint256 indexed roundId, address indexed winner, uint256 prize);

    error NotOwner();
    error WrongAmount();
    error RoundNotOver();
    error RoundAlreadyDrawn();
    error NoParticipants();
    error ActiveRoundExists();
    error NoActiveRound();

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotOwner();
        _;
    }

    constructor() {
        owner = msg.sender;
        _startRound();
    }

    function _startRound() internal {
        uint256 id = rounds.length;
        rounds.push(Round({
            id: id,
            startTime: block.timestamp,
            endTime: block.timestamp + DURATION,
            participants: new address[](0),
            winner: address(0),
            prize: 0,
            drawn: false
        }));
        emit RoundStarted(id, block.timestamp + DURATION);
    }

    /// @notice Buy tickets for the current round
    function buyTickets(uint256 count) external payable {
        if (rounds.length == 0) revert NoActiveRound();
        Round storage round = rounds[rounds.length - 1];
        if (round.drawn) revert NoActiveRound();
        if (msg.value != TICKET_PRICE * count) revert WrongAmount();

        for (uint256 i = 0; i < count; i++) {
            round.participants.push(msg.sender);
        }
        ticketsByRound[round.id][msg.sender] += count;
        emit TicketPurchased(round.id, msg.sender, count);
    }

    /// @notice Owner draws the winner after round ends
    function drawWinner() external onlyOwner {
        Round storage round = rounds[rounds.length - 1];
        if (block.timestamp < round.endTime) revert RoundNotOver();
        if (round.drawn) revert RoundAlreadyDrawn();
        if (round.participants.length == 0) revert NoParticipants();

        uint256 rand = uint256(keccak256(abi.encodePacked(
            blockhash(block.number - 1),
            block.timestamp,
            round.participants.length
        )));
        uint256 winnerIndex = rand % round.participants.length;
        address winner = round.participants[winnerIndex];

        uint256 pot = address(this).balance;
        uint256 fee = (pot * FEE_BPS) / 10000;
        uint256 prize = pot - fee;

        round.winner = winner;
        round.prize = prize;
        round.drawn = true;

        (bool feeOk,) = owner.call{value: fee}("");
        require(feeOk);

        (bool prizeOk,) = winner.call{value: prize}("");
        require(prizeOk);

        emit WinnerDrawn(round.id, winner, prize);
        _startRound();
    }

    function getCurrentRound() external view returns (Round memory) {
        return rounds[rounds.length - 1];
    }

    function getRound(uint256 id) external view returns (Round memory) {
        return rounds[id];
    }

    function totalRounds() external view returns (uint256) {
        return rounds.length;
    }

    function getParticipants(uint256 roundId) external view returns (address[] memory) {
        return rounds[roundId].participants;
    }
}
