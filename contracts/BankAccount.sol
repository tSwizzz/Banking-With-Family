pragma solidity >=0.4.22 <=0.8.19;

contract BankAccount {
    event AccountCreated(
        address[] owners, 
        uint256 indexed id, 
        uint256 timestamp
    );
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
    event Withdraw(
        uint256 indexed withdrawId, 
        uint256 timestamp
    );

    struct Account {
        address[] owners;
        uint256 balance;
        mapping(uint256 => WithdrawRequest) withdrawRequests;
    }
    struct WithdrawRequest {
        address user;
        uint256 amount;
        uint256 approvals;
        mapping(address => bool) ownersApproved;
        bool approved;
    }

    mapping(uint256 => Account) accounts; //an accountID that points to Account
    mapping(address => uint256[]) userAccounts; //list of different accounts user may have

    uint256 nextAccountId;
    uint256 nextWithdrawId;

    modifier accountOwner(uint256 accountId) {
        bool isOwner;
        for(uint256 k; k < accounts[accountId].owners.length; k++) {
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
        for(uint256 k; k < owners.length; k++) {
            for(uint256 f = k + 1; f < owners.length; f++) {
                if(owners[k] == owners[f]) {
                    revert("no duplicate owners allowed");
                }
            }
        }
        _;
    }

    modifier sufficientBalance(uint256 accountId, uint256 amount) {
        require(accounts[accountId].balance >= amount, "insufficient balance");
        _;
    }

    modifier canApprove(uint256 accountId, uint256 withdrawId) {
        require(!accounts[accountId].withdrawRequests[withdrawId].approved, "this request is already approved");
        require(accounts[accountId].withdrawRequests[withdrawId].user != msg.sender, "you cannot approve this request");
        require(accounts[accountId].withdrawRequests[withdrawId].user != address(0), "this request does not exist");
        require(!accounts[accountId].withdrawRequests[withdrawId].ownersApproved[msg.sender], "you have already approved this request");
        _;
    }

    modifier canWithdraw(uint accountId, uint withdrawId) {
        require(accounts[accountId].withdrawRequests[withdrawId].user == msg.sender, "you did not create this request");
        require(accounts[accountId].withdrawRequests[withdrawId].approved, "this request is not approved");
        _;
    }

    function deposit(uint256 accountId) 
        external 
        payable 
        accountOwner(accountId) 
    {
        accounts[accountId].balance += msg.value;
    }

    function createAccount(address[] calldata otherOwners) 
        external 
        validOwners(otherOwners) 
    {
        address[] memory owners = new address[](otherOwners.length + 1);
        owners[otherOwners.length] = msg.sender;

        uint256 id = nextAccountId;

        for(uint256 k; k < owners.length; k++) {
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

    function requestWithdrawal(uint256 accountId, uint256 amount)
        external 
        accountOwner(accountId)
        sufficientBalance(accountId, amount) 
    {
        uint256 id = nextWithdrawId;
        WithdrawRequest storage request = accounts[accountId].withdrawRequests[id];

        //updates WithdrawRequest struct with appropriate values and then emits
        request.user = msg.sender;
        request.amount = amount;
        nextWithdrawId++;
        emit WithdrawRequested(msg.sender, accountId, id, amount, block.timestamp);
    }

    function approveWithdrawal(uint256 accountId, uint256 withdrawId) 
        external 
        accountOwner(accountId) 
        canApprove(accountId, withdrawId)
        {
            WithdrawRequest storage request = accounts[accountId].withdrawRequests[withdrawId];
            request.approvals++;
            request.ownersApproved[msg.sender] = true;

            if(request.approvals == accounts[accountId].owners.length - 1) {
                request.approved = true;
            }
        }

    function withdraw(uint256 accountId, uint256 withdrawId) 
        external 
        canWithdraw(accountId, withdrawId) 
    {
        uint amount = accounts[accountId].withdrawRequests[withdrawId].amount;
        require(accounts[accountId].balance >= amount, "insufficient balance");

        accounts[accountId].balance -= amount;

        //resets all values in WithdrawRequest struct
        delete accounts[accountId].withdrawRequests[withdrawId];

        (bool sent, ) = payable(msg.sender).call{value: amount}("");
        require(sent);

        emit Withdraw(withdrawId, block.timestamp);
    }

    function getBalance(uint256 accountId) 
        public 
        view 
        returns(uint256) 
    {
        return accounts[accountId].balance;
    }

    function getOwners(uint256 accountId) 
        public 
        view 
        returns(address[] memory) 
    {
        return accounts[accountId].owners;
    }

    function getApprovals(uint256 accountId, uint256 withdrawId) 
        public 
        view 
        returns(uint256) 
    {
        return accounts[accountId].withdrawRequests[withdrawId].approvals;
    }

    function getAccounts() 
        public 
        view 
        returns(uint256[] memory) 
    {
        return userAccounts[msg.sender];
    }
}