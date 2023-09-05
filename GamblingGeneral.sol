// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract ImprovedSimpleGamesBetting {
    enum Game { None, Chess, RockPaperScissors, TicTacToe }
    enum State { BettingOpen, BettingClosed, GameOver }
    enum Winner { None, Player1, Player2 }
    
    address public owner;
    address public player1;
    address public player2;
    State public currentState;
    Game public currentGame;
    Winner public winningPlayer;
    
    mapping(address => uint256) public betsOnPlayer1;
    mapping(address => uint256) public betsOnPlayer2;
    
    uint256 public totalBetsPlayer1;
    uint256 public totalBetsPlayer2;
    
    event BetPlaced(address indexed bettor, Winner player, uint256 amount);
    event GameOver(Winner winningPlayer);
    event StateChanged(State newState);
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the owner can call this function");
        _;
    }
    
    modifier inState(State _state) {
        require(currentState == _state, "Invalid state for this operation");
        _;
    }
    
    constructor() {
        owner = msg.sender;
        currentState = State.BettingOpen;
    }
    
    function setGame(Game _game, address _player1, address _player2) public onlyOwner inState(State.BettingOpen) {
        currentGame = _game;
        player1 = _player1;
        player2 = _player2;
    }
    
    function placeBet(Winner _player) public payable inState(State.BettingOpen) {
        require(_player != Winner.None, "Invalid player");
        require(msg.value > 0, "Bet amount must be greater than zero");
        
        if (_player == Winner.Player1) {
            betsOnPlayer1[msg.sender] += msg.value;
            totalBetsPlayer1 += msg.value;
        } else {
            betsOnPlayer2[msg.sender] += msg.value;
            totalBetsPlayer2 += msg.value;
        }
        
        emit BetPlaced(msg.sender, _player, msg.value);
    }
    
    function closeBetting() public onlyOwner inState(State.BettingOpen) {
        currentState = State.BettingClosed;
        emit StateChanged(State.BettingClosed);
    }
    
    function setWinner(Winner _winningPlayer) public onlyOwner inState(State.BettingClosed) {
        require(_winningPlayer != Winner.None, "Invalid player");
        
        winningPlayer = _winningPlayer;
        currentState = State.GameOver;
        
        emit GameOver(_winningPlayer);
        emit StateChanged(State.GameOver);
    }
    
    function withdrawWinnings() public inState(State.GameOver) {
        require(winningPlayer != Winner.None, "No winning player set");
        
        uint256 betAmount;
        uint256 totalBets;
        
        if (winningPlayer == Winner.Player1) {
            betAmount = betsOnPlayer1[msg.sender];
            totalBets = totalBetsPlayer1;
        } else {
            betAmount = betsOnPlayer2[msg.sender];
            totalBets = totalBetsPlayer2;
        }
        
        require(betAmount > 0, "No winnings to claim");
        
        uint256 totalPool = totalBetsPlayer1 + totalBetsPlayer2;
        uint256 winnings = (betAmount * totalPool) / totalBets;
        
        payable(msg.sender).transfer(winnings);
    }
}
