//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "@openzeppelin/contracts/math/SafeMath.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";
import "@openzeppelin/contracts-upgradeable/token/ERC721/ERC721Upgradeable.sol";


contract LongNftV2 is OwnableUpgradeable, ERC721Upgradeable {
    // using SafeMath for uint256;
    using StringsUpgradeable for uint256;

    uint256 public constant MAX_SUPPLY = 500_000;

    bool    public openMysteryBox;
    string  private mysteryURI;

    address public longToken;
    address public longVault;

    uint256 public longBurnAmount;
    
    mapping(address => bool) public listContract;

    uint256 public totalLocked;

    mapping(address => uint256) public userLocked;

    function initialize(
        address _longToken,
        address _longVault,
        uint256 _longBurnAmount
    )
        initializer 
        public
    {
        __Ownable_init();
        __ERC721_init("LONG", "LONG");

        longToken = _longToken;
        longVault = _longVault;
        longBurnAmount = _longBurnAmount;
    }

    function setVault(address _vault) external onlyOwner {
        longVault = _vault;
    }

    function mintInList(address to, uint256 amount) external {
        require(listContract[msg.sender], "Only in list");

        _mintBatch(to,  amount);
    }

    function burn(uint256[] memory tokenIds) public {
        for (uint256 index = 0; index < tokenIds.length; index++) {
            address owner = ERC721Upgradeable.ownerOf(tokenIds[index]); // internal owner
            require(owner == msg.sender, "not owner");
            _burn(tokenIds[index]);    
        }
        IERC20(longToken).transfer(msg.sender, tokenIds.length * longBurnAmount );
    }

    function burnAll() public {
        uint256 bal = balanceOf(msg.sender);
        if(bal == 0) { return; }

        totalLocked += bal;
        userLocked[msg.sender] += bal;

        IERC20(longToken).transfer(msg.sender, bal * longBurnAmount );
    }

    function balanceOf(address owner) public view virtual override returns (uint256) { 
        return super.balanceOf(owner) - userLocked[owner];
    }

    function totalSupply() public view virtual override returns (uint256) {
        return super.totalSupply() - totalLocked;
    }

    function burnBatch(uint256 amount) external {
        uint256 bal = balanceOf(msg.sender);
        require(amount <= bal, "Amount over balance");
        
        uint256[] memory tokenIds = new uint256[](amount);
        for (uint256 index = 0; index < amount; index++) {
            tokenIds[index] = tokenOfOwnerByIndex(msg.sender, index);
        }

        burn(tokenIds);
    }

    function _mintBatch(address to, uint256 amount) private {
        for (uint256 index = 0; index < amount; index++) {
            uint256 tokenId =  totalSupply();
            _mint(to, tokenId);
        }
    }

    function withdrawTokensSelf(address token, address to) external onlyOwner {

        if(token == address(0)) {
            payable(to).transfer( address(this).balance);
        } else {
            uint256 bal = IERC20(token).balanceOf(address(this));
            IERC20(token).transfer(to, bal);
        }
    }

    function setTokenURI(uint256 tokenId, string memory _tokenURI) external onlyOwner {
        _setTokenURI(tokenId,  _tokenURI);
    }

    function setBaseURI(string memory baseURI_) external onlyOwner {
        _setBaseURI(baseURI_);
    }

    function setMysteryURI(string memory baseURI_) external onlyOwner {
        mysteryURI = baseURI_;
    }
    
    function openBox(bool open) external onlyOwner {
        openMysteryBox = open;
    }

    function setWhiteList(address addr, bool inList) external onlyOwner {
        listContract[addr] = inList;
    }

    function userTokenIds(address user) external view returns (uint256[] memory ) {

        uint256 bal = balanceOf(user);
        uint256[] memory tokenIds = new uint256[](bal);
        for (uint256 index = 0; index < bal; index++) {
            tokenIds[index] = tokenOfOwnerByIndex(user, index);
        }

        return tokenIds;
    }

    function tokenURI(uint256 tokenId) public view virtual override returns (string memory) {
        if(openMysteryBox) {
            string memory superURI = super.tokenURI(tokenId);
            if (bytes(superURI).length == 0) {
                return mysteryURI;
            } else {
                return superURI;
            }
        } else {
            return mysteryURI;
        }
    }

    function _mint(address to, uint256 tokenId) internal override virtual {

        require(totalSupply() < MAX_SUPPLY, "Over mint");

        super._mint(to, tokenId);
    }

    function _beforeTokenTransfer(address from, address to, uint256 tokenId) internal override virtual {
        require(userLocked[from]  == 0, "Token from had locked");
        require(userLocked[to]    == 0, "Token to had locked");
    }

}