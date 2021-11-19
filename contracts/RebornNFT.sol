pragma solidity ^0.6.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

contract Talent is ERC721, Ownable, ReentrancyGuard {
    using Counters for Counters.Counter;
    using SafeMath for uint256;
    
    address[] public adminList;

    mapping(uint256 => uint256) public mintOrderList;
    mapping(uint256 => uint256) public burnOrderList;

    Counters.Counter private _tokenIds;

    event Burn(uint256 tokenId, uint256 orderId);
    event BurnMulti(uint256[] _ids, uint256 orderId);
    event MintItems(address recipient, uint256 numberOfTokens, uint256 orderId);
    event MintMulti(address[] recipient, uint256 orderId);
    event MintMultiByOrderIds(address[] recipient, uint256[] orderIds);

    constructor() public ERC721("Talent", "Talent") {
        adminList.push(msg.sender);
    }
  
    function setBaseURI(string memory baseURI) public onlyOwner {
        _setBaseURI(baseURI);
    }
    
    function tokensOfOwner(address _owner) external view returns(uint256[] memory ) {
        uint256 tokenCount = balanceOf(_owner);
        if (tokenCount == 0) {
            // Return an empty array
            return new uint256[](0);
        } else {
            uint256[] memory result = new uint256[](tokenCount);
            uint256 index;
            for (index = 0; index < tokenCount; index++) {
                result[index] = tokenOfOwnerByIndex(_owner, index);
            }
            return result;
        }
    }
    
    function mintItems(address recipient, uint256 numberOfTokens, uint256 orderId) public nonReentrant {
        require(onlyAdmin(msg.sender), "Only administrators can operate");
        require(recipient != address(0), "recipient is zero address");
        require(numberOfTokens > 0, "numberOfTokens cannot be 0");
        require(orderId > 0, "orderId cannot be 0");
        require(mintOrderList[orderId] <= 0, "orderId is exists");

        mintOrderList[orderId] = numberOfTokens;

        for(uint256 i = 0; i < numberOfTokens; i++) {
            _tokenIds.increment();
            uint256 mintIndex = _tokenIds.current();

            _safeMint(recipient, mintIndex);
        }
        emit MintItems(recipient, numberOfTokens, orderId);
    }

    function mintMulti(address[] memory recipient, uint256 orderId) external nonReentrant {
        require(onlyAdmin(msg.sender), "Only administrators can operate");
        require(recipient.length > 0, "Receiver is empty");
        require(orderId > 0, "orderId cannot be 0");
        require(mintOrderList[orderId] <= 0, "orderId is exists");

        mintOrderList[orderId] = recipient.length;

        uint256 len = recipient.length;

        for(uint256 i = 0; i < len; i++) {
            _tokenIds.increment();
            uint256 mintIndex = _tokenIds.current();
            _safeMint(recipient[i], mintIndex);
        }

        emit MintMulti(recipient, orderId);
    }

    function mintMultiByOrderIds(address[] memory recipient, uint256[] memory orderIds) external nonReentrant {
        require(onlyAdmin(msg.sender), "Only administrators can operate");
        require(recipient.length > 0, "Receiver is empty");
        require(recipient.length == orderIds.length, "Inconsistent array length");

        uint256 len = recipient.length;

        for(uint256 i = 0; i < len; i++) {
            uint256 orderId = orderIds[i];
            require(orderId > 0, "orderId cannot be 0");
            require(mintOrderList[orderId] <= 0, "orderId is exists");

            mintOrderList[orderId] = 1;
            _tokenIds.increment();
            uint256 mintIndex = _tokenIds.current();
            _safeMint(recipient[i], mintIndex);
        }

        emit MintMultiByOrderIds(recipient, orderIds);
    }

    function burn(uint256 tokenId, uint256 orderId) public virtual  {
        require(orderId > 0, "orderId cannot be 0");
        require(burnOrderList[orderId] <= 0, "orderId is exists");

        burnOrderList[orderId] = tokenId;

        require(_isApprovedOrOwner(_msgSender(), tokenId), "ERC721Burnable: caller is not owner nor approved");
        _burn(tokenId);

        emit Burn(tokenId, orderId);
    }


    function burnMulti(uint256[] memory _ids, uint256 orderId) external nonReentrant {
        require(orderId > 0, "orderId cannot be 0");
        require(burnOrderList[orderId] <= 0, "orderId is exists");

        burnOrderList[orderId] = _ids.length;

        for ( uint256 ind = 0; ind < _ids.length; ind++ ) {
            require(_isApprovedOrOwner(_msgSender(), _ids[ind]), "ERC721Burnable: caller is not owner nor approved");
            _burn(_ids[ind]);
        }
        
        emit BurnMulti(_ids, orderId);
    }

    function setAdminList(address[] memory _list) public onlyOwner nonReentrant{
        require(_list.length > 0, "_list is empty");
        
        for ( uint256 nIndex = 0; nIndex < _list.length; nIndex++){
            require(_list[nIndex] != address(0), "admin is empty");
        }
        adminList = _list;
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



