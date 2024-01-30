//SPDX-License-Identifier: Unlicense
pragma solidity 0.6.12;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts-upgradeable/access/OwnableUpgradeable.sol";

interface IMintInList {
    function mintInList(address to, uint256 amount) external;
    function balanceOf(address user) external view returns (uint256);

    function longBurnAmount() external view returns (uint256);
}

contract LongFactory is OwnableUpgradeable {

    uint256 public constant MAX_SUPPLY = 250_000;

    address public longNFT;
    address public longToken;

    uint256 public totalMint;
    uint256 public mintPrice;

    uint256 public totalInvest;
    mapping (address => uint256) public userDeposit;

    mapping (address => address) public referral;
    mapping (address => uint256) public referralReward;
    uint256 public startAt;
    uint256 public endAt;

    event Invest(address indexed account, uint256 amount);

    function initialize(
        address _longNFT,
        address _longToken,
        uint256 _mintPrice
    )
        initializer 
        public
    {
        __Ownable_init();
        longNFT =  _longNFT;
        longToken = _longToken;
        mintPrice = _mintPrice;
    }

    function setStartEnd(uint256 _startAt, uint256 _endAt) external {
        startAt = _startAt;
        endAt   = _endAt;
    }

    function setMintPrice(uint256 _mintPrice) external {
        mintPrice = _mintPrice;
    }

    function invest(uint256 amount, address _referralBy) external payable {
        require(block.timestamp >= startAt , "not start");
        require(block.timestamp <= endAt, "had end");

        uint256 mintable = min(amount, MAX_SUPPLY - totalMint);
        require(mintable > 0, "Mint over");
        uint256 mintFee = mintPrice * mintable;
        require(msg.value >= mintFee, "Vaule incification");

        if(userDeposit[msg.sender] == 0) {
            totalInvest++;
        } 
        
        if(
            _referralBy != address(0) &&        // set referral
            userDeposit[_referralBy] > 0 &&     // referral had deposit
            referral[msg.sender] == address(0)    // first
        ) { 
                referral[msg.sender] = _referralBy;
                referralReward[msg.sender] += 1;
                referralReward[_referralBy] += 1;
        }

        userDeposit[msg.sender] +=  mintFee;

        totalMint += mintable;
        IMintInList(longNFT).mintInList(msg.sender, amount);

        if(msg.value > mintFee) {
            payable(msg.sender).transfer(msg.value - mintFee);
        }

        emit Invest(msg.sender, mintable);
    }

    function userInfo(address user) external view returns (
        uint256 holders, 
        uint256 yourAmount, 
        uint256 yourTotem, 
        uint256 willReceive,
        uint256 referralRewardAmount,
        address referralBy
        ) {
        uint256 nftBal = IMintInList(longNFT).balanceOf(user);
        return (
            totalInvest,
            userDeposit[user],
            nftBal,
            nftBal * IMintInList(longNFT).longBurnAmount(),
            referralReward[user],
            referral[user]
        );
    }

    function min(uint256 a, uint256 b) internal pure returns(uint256) {
        return a<b ? a : b;
    }

    function withdrawTokensSelf(address token, address to) external onlyOwner {

        if(token == address(0)) {
            payable(to).transfer( address(this).balance);
        } else {
            uint256 bal = IERC20(token).balanceOf(address(this));
            IERC20(token).transfer(to, bal);
        }
    }

}