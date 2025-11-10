//SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/access/Ownable.sol";

contract MysteryBoxNFT is ERC721, Ownable {
    uint256 public constant BOX_PRICE = 0.01 ether;
    uint256 public constant MAX_SUPPLY = 1000;

    uint256 public totalMinted;
    uint256 private _tokenIdCounter;

    mapping(address => uint256) public boxesOwned;
    mapping(uint256 => string) private _tokenURIs;

    event BoxBought(address indexed user, uint256 amount);
    event BoxOpened(address indexed user, uint256 indexed tokenId, string rarity);

    constructor() ERC721("MysteryBoxNFT", "MBX") Ownable(msg.sender) {}

    function buyBox(uint256 amount) external payable {
        require(amount > 0, "Amount must be > 0");
        require(msg.value == BOX_PRICE * amount, "Incorrect ETH sent");
        require(totalMinted + amount <= MAX_SUPPLY, "Exceeds supply");

        boxesOwned[msg.sender] += amount;
        emit BoxBought(msg.sender, amount);
    }

    function openBox() public {
        require(boxesOwned[msg.sender] > 0, "No upopened boxes");
        boxesOwned[msg.sender] -= 1;
        _mintRandomNFT(msg.sender);
    }

    function openMultipleBoxes(uint256 count) external {
        require(count > 0, "Count must be > 0");
        require(boxesOwned[msg.sender] >= count, "Not enough boxes");
        boxesOwned[msg.sender] -= count;

        for(uint256 i = 0; i < count; i++) {
            _mintRandomNFT(msg.sender);
        }
    }

    function _mintRandomNFT(address user) internal {
        uint256 newTokenId = _tokenIdCounter++;
        totalMinted += 1;

        uint256 rand = uint256(keccak256(abi.encodePacked(block.timestamp, user, totalMinted) )) % 100;

         string memory rarity;
        string memory uri;

        if (rand < 80) {
            rarity = "Common";
            uri = "ipfs://QmCommon";
        } else if (rand < 95) {
            rarity = "Rare";
            uri = "ipfs://QmRare";
        } else {
            rarity = "Legendary";
            uri = "ipfs://QmLegendary";
        }

        _safeMint(user, newTokenId);
        _tokenURIs[newTokenId] = uri;

        emit BoxOpened(user, newTokenId, rarity);
    }

      function tokenURI(uint256 tokenId) public view override returns (string memory) {
        require(_ownerOf(tokenId) != address(0), "Nonexistent token");
        return _tokenURIs[tokenId];
    }

     function withdraw() external onlyOwner {
        payable(owner()).transfer(address(this).balance);
    }

     function boxesLeft() external view returns (uint256) {
        return MAX_SUPPLY - totalMinted;
    }


}
