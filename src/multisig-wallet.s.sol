// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

contract multiSigWallet{
    address[] private owners;
    mapping(address => bool)public isOwner;
    uint public numOfconfirmations;
    uint256 private count=0;

    
    struct transaction{
        address payable to;
        uint value;
        bytes data;
        bool executed;
        uint numOfconfirms; 
        mapping(address=>bool) isConfirmed;
    }
    // transaction[] transactions;

   mapping(uint256 => transaction)public transactions;
    modifier onlyOwner() {
        require(isOwner[msg.sender],"Invalid owner");
        _;
    }

    modifier txExist(uint _txIndex){
        require(_txIndex <= count,"Invalid Transation Index");
        _;
    }

    modifier txexecuted(uint _txIndex){
        require(!transactions[_txIndex].executed,"Transaction allready Executed");
        _;
    }

    modifier isConfirmed(uint _txIndex){
        require(!transactions[_txIndex].isConfirmed[msg.sender],"Allready confirmed");
        _;
    }

    event Deposit(address indexed sender, uint amount, uint balance);

    event TransactionSubmited(
        address to,
        uint value,
        uint txIndex,
        address caller
    );

    event TransactionConfirmed(
        address caller,
        uint txIndex
    );

    event TransactionExecuted(
        address to,
        uint value,
        uint txIndex,
        address caller
    );

    constructor(address[] memory owner,uint _numOfconfirmation){
        uint len = owner.length;
        require(owner.length >0,"Empty array of Owner");
        require(_numOfconfirmation > 0 && _numOfconfirmation <= owner.length,"incorrect number of confirmation");
        for(uint i=0;i<len;i++){
            require(owner[i] != address(0),"Inavlid owner address");
            require(!isOwner[owner[i]],"Allready Owner");
            isOwner[owner[i]]=true;
            owners.push(owner[i]);
        }
        numOfconfirmations=_numOfconfirmation;
    }


    function submitTransaction(address _to, uint _value,bytes memory data)
        public
        payable
        onlyOwner
    {
        count=count+1;
        transactions[count].to= payable(_to);
        transactions[count].value=_value;
        transactions[count].executed=false;
        transactions[count].numOfconfirms=0;
        transactions[count].data=data;
        emit TransactionSubmited(_to,_value,count,msg.sender);
    }

    function confirmTransaction(uint _txIndex) onlyOwner
    txexecuted(_txIndex)
    isConfirmed(_txIndex)
    external{
        transaction storage _tx = transactions[_txIndex];
        _tx.numOfconfirms +=1;
        _tx.isConfirmed[msg.sender]=true;

    emit TransactionConfirmed(msg.sender,_txIndex);
    }

    function executeTransaction(uint _txIndex)
    onlyOwner
    external{
        transaction storage _tx = transactions[_txIndex];
        require(_tx.numOfconfirms >= numOfconfirmations,"not confirmed");
        _tx.executed=true;
        // _tx.to.transfer(_tx.value);
        (bool success,) = _tx.to.call{value:_tx.value}(_tx.data); 
        require(success,"Transaction execution failed");
        emit TransactionExecuted(_tx.to,_tx.value,_txIndex,msg.sender);
    }


    function getOwners() external view returns(address[] memory){
        return owners;
    }

    function getTransactionCount() external view returns(uint){
        return count;
    }

    function getTrnsaction(uint _txIndex) external view returns(address,uint,bool,uint){
        transaction storage _tx = transactions[_txIndex];
        return(
            _tx.to,
            _tx.value,
            _tx.executed,
            _tx.numOfconfirms
        );
    }
    // fallback will recive ether with data 
   fallback() payable external  {
      emit Deposit(msg.sender, msg.value, address(this).balance);
   }
    // receive will recive ether with data 
    receive() payable external   { 
    emit Deposit(msg.sender, msg.value, address(this).balance);
    }

    function deposit()payable public{
        payable(address(this)).transfer(msg.value);
    }
}



