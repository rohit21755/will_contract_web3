// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;


contract WillContractFactory {
    address[] public deployedContracts;
    mapping(address => address[]) public userContracts;

    event ContractDeployed(
        address indexed owner, 
        address indexed recipient, 
        address contractAddress
    );

    function createWillContract(address _recipient) external returns (address) {
        WillContract newContract = new WillContract(_recipient, msg.sender);
        address contractAddress = address(newContract);
        
        deployedContracts.push(contractAddress);
        userContracts[msg.sender].push(contractAddress);
        
        emit ContractDeployed(msg.sender, _recipient, contractAddress);
        
        return contractAddress;
    }

    function getUserContracts(address _user) external view returns (address[] memory) {
        return userContracts[_user];
    }

    function getTotalDeployedContracts() external view returns (uint256) {
        return deployedContracts.length;
    }
}
contract WillContract {
    address public owner;
    address public recipient;
    uint256 public lastPingTimestamp;
    uint256 constant INACTIVITY_PERIOD = 365 days;

    event RecipientChanged(address indexed previousRecipient, address indexed newRecipient);
    event Pinged(address indexed owner, uint256 timestamp);
    event FundsDrained(address indexed recipient, uint256 amount);
    event Withdrawal(address indexed owner, uint256 amount);

    constructor(address _recipient, address _owner) {
        owner = _owner;
        recipient = _recipient;
        lastPingTimestamp = block.timestamp;
    }

    modifier onlyOwner() {
        require(msg.sender == owner, "Not the contract owner");
        _;
    }

    function changeRecipient(address _newRecipient) external onlyOwner {
        require(_newRecipient != address(0), "Invalid recipient address");
        address previousRecipient = recipient;
        recipient = _newRecipient;
        emit RecipientChanged(previousRecipient, _newRecipient);
    }

    function ping() external onlyOwner {
        lastPingTimestamp = block.timestamp;
        emit Pinged(msg.sender, lastPingTimestamp);
    }

    function withdraw() external onlyOwner {
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "No funds to withdraw");

        (bool success, ) = owner.call{value: contractBalance}("");
        require(success, "Transfer failed");

        emit Withdrawal(owner, contractBalance);
    }

    function drain() external {
        require(msg.sender == recipient, "Only recipient can drain");
        require(block.timestamp > lastPingTimestamp + INACTIVITY_PERIOD, "Owner is still active");
        
        uint256 contractBalance = address(this).balance;
        require(contractBalance > 0, "No funds to drain");

        (bool success, ) = recipient.call{value: contractBalance}("");
        require(success, "Transfer failed");

        emit FundsDrained(recipient, contractBalance);
    }

    // Allow contract to receive ETH
    receive() external payable {}
}
