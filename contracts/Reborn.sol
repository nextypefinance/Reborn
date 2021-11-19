pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";


contract Reborn is Ownable, ReentrancyGuard{
    using SafeMath for uint256;

    address public poolToken = 0x7D39b9C548b4d8140C958a56AD6ca7D7b82a863F;
    address public feeReceiver = 0x30Be031A6F3A07F7B8Bb383FD47c89b0D6F7607a;
    uint256 public poolAmount = 0;
    uint256 public withdrawingAmount = 0;

    address[] public adminList;

    // address > amount
    mapping(address => uint256) public withdrawBalance;
    mapping(uint256 => uint256) public startOrderList;
    mapping(uint256 => uint256) public endOrderList;


    event StartLife(uint256 min_poolAmount, uint256 max_poolAmount, uint256 ticketAmount, uint256 feeRate, uint256 orderId);
    event EndLife(uint256 min_poolAmount, uint256 max_poolAmount, uint256 lifeLevel, uint256 feeRate, address userAddress, uint256 orderId, uint256 tmpAmount);
    event ClaimTokens(address userAddress, uint256 claimAmount);


    constructor() public {
        adminList.push(msg.sender);
    }

    function startLife(uint256 min_poolAmount, uint256 max_poolAmount, uint256 ticketAmount, uint256 feeRate, uint256 orderId) public nonReentrant {
        require(poolAmountRange(min_poolAmount, max_poolAmount), "poolAmount exceeded");
        require(feeRate < 5000000000, "feeRate exceeded");
        require(ticketAmount > 0, "ticketAmount cannot be 0");
        require(orderId > 0, "orderId cannot be 0");
        require(startOrderList[orderId] <= 0, "orderId is exists");

        startOrderList[orderId] = 1;

        if(feeRate > 0){
            uint256 tmpFee = ticketAmount.mul(feeRate).div(10000000000);
            ticketAmount = ticketAmount.sub(tmpFee);

            IERC20(poolToken).transferFrom(msg.sender, feeReceiver, tmpFee);
        }

        IERC20(poolToken).transferFrom(msg.sender, address(this), ticketAmount);
        poolAmount = poolAmount.add(ticketAmount);

        emit StartLife(min_poolAmount, max_poolAmount, ticketAmount, feeRate, orderId);
    }


    function endLife(uint256 min_poolAmount, uint256 max_poolAmount, uint256 lifeLevel, uint256 feeRate, address userAddress, uint256 orderId) public nonReentrant {
        require(onlyAdmin(msg.sender), "endLift is onlyAdmin");
        require(poolAmountRange(min_poolAmount, max_poolAmount), "poolAmount exceeded");

        require(feeRate < 5000000000 && feeRate > 0, "feeRate exceeded");
        require(lifeLevel > 0, "lifeLevel cannot be 0");

        require(orderId > 0, "orderId cannot be 0");
        require(endOrderList[orderId] <= 0, "orderId is exists");

        endOrderList[orderId] = 1;

        uint256 tmpAmount = poolAmount.mul(feeRate).div(10000000000);
        poolAmount = poolAmount.sub(tmpAmount);

        withdrawingAmount = withdrawingAmount.add(tmpAmount);
        withdrawBalance[userAddress] = withdrawBalance[userAddress].add(tmpAmount);

        emit EndLife(min_poolAmount, max_poolAmount, lifeLevel, feeRate, userAddress, orderId, tmpAmount);
    }


    // Claim Tokens
    function claimTokens() public nonReentrant {

        uint256 balance = withdrawBalance[msg.sender];
        require(balance > 0, "balance cannot be 0");

        withdrawBalance[msg.sender] = 0;
        withdrawingAmount = withdrawingAmount.sub(balance);
        IERC20(poolToken).transfer(msg.sender, balance);
        
        emit ClaimTokens(msg.sender, balance);
    }


    function setPoolToken(address _erc20) public onlyOwner nonReentrant{
        require(_erc20 != address(0), "poolToken is empty");
        poolToken = _erc20;
    }

    function setFeeReceiver(address _receiver) public onlyOwner nonReentrant{
        require(_receiver != address(0), "receiver is empty");
        feeReceiver = _receiver;
    }

    function setAdminList(address[] memory _list) external onlyOwner nonReentrant{
        require(_list.length > 0, "_list is empty");
        
        for ( uint256 nIndex = 0; nIndex < _list.length; nIndex++){
            require(_list[nIndex] != address(0), "admin is empty");
        }
        adminList = _list;
    }

    function poolAmountRange(uint256 min_poolAmount, uint256 max_poolAmount) internal view returns (bool) {
        if(poolAmount > 0){
            if(min_poolAmount < poolAmount && poolAmount <= max_poolAmount){
                return true;
            }else{
                return false;
            }
        }else{
            if(min_poolAmount == poolAmount && poolAmount < max_poolAmount){
                return true;
            }else{
                return false;
            }
        }
    }

    function onlyAdmin(address token) internal view returns (bool) {
        for ( uint256 nIndex = 0; nIndex < adminList.length; nIndex++){
            if (adminList[nIndex] == token) {
                return true;
            }
        }
        return false;
    }

}



