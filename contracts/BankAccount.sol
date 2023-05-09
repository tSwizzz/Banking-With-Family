pragma solidity ^0.8.19;

contract BankAccount {
    
    event Deposit(
        address indexed user,
        uint256 indexed accountId,
        uint256 value, 
        uint256 timestamp
    );
    event WithdrawRequested(
        address indexed user,
        uint256 indexed accountId, 
        uint256 indexed withdrawId, 
        uint256 amount, 
        uint256 timestamp
    );
    event Withdraw(uint indexed withdrawId, uint timestamp);
    event AccountCreated(address[] owners, uint indexed id, uint timestamp);

    struct Account {
        address[] owners;
        uint balance;
        mapping(uint => WithdrawRequest) withdrawRequests;
    }

    struct WithdrawRequest {
        address user;
        uint amount;
        uint approvals;
        mapping(address => bool) ownersApproved;
        bool approved;
    }

    mapping(uint => Account) accounts;
    mapping(address => uint[]) userAccounts;

    uint nextAccountId;
    uint nextWithdrawId;

    modifier accountOwner(uint accountId) {
        bool isOwner;
        for(uint k; k < accounts[accountId].owners.length; k++) {
            if(msg.sender == accounts[accountId].owners[k]) {
                isOwner = true;
                break;
            }
        }
        require(isOwner, "you are not an owner of this account");
        _;
    }

    modifier validOwners(address[] calldata owners) {
        require(owners.length + 1 <= 4, "maximum of 4 owners per account");
        for(uint k; k < owners.length; k++) {
            for(uint f = k + 1; f < owners.length; f++) {
                if(owners[k] = owners[f]) {
                    revert("no duplicate owners");
                }
            }
        }
        _;
    }

    function deposit(uint accountId) external payable accountOwner(accountId) {
        accounts[accountId].balance += msg.value;
    }

    function createAccount(address[] calldata otherOwners) external {
        address[] memory owners = new address[](otherOwners.length + 1);
        owners[otherOwners.length] = msg.sender;

        uint id = nextAccountId;

        for(uint k; k < owners.length; k++) {
            if(k < owners.length - 1) {
                owners[k] = otherOwners[k];
            }

            if(userAccounts[owners[k]].length > 2) {
                revert("each user can have a max of 3 accounts");
            }
            userAccounts[owners[k]].push(id);
        }

        accounts[id].owners = owners;
        nextAccountId++;
        emit AccountCreated(owners, id, block.timestamp);
    }

    function requestWithdrawal(uint accountId, uint amount) external {

    }

    function approveWithdrawal(uint accountId, uint withdrawId) external {

    }

    function withdraw(uint accountId, uint withdrawId) external {

    }

    function getBalance(uint accountId) public view returns(uint) {

    }

    function getOwners(uint accountId) public view returns(address[] memory) {

    }

    function getApprovals(uint accountId, uint withdrawId) public view returns(uint) {

    }

    function getAccounts() public view returns(uint[] memory) {

    }
}