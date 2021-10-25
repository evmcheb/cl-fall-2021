pragma solidity ^0.8.6;

import "ds-test/test.sol";

import "./Hevm.sol";
import "../Candle.sol";
import "../TestNFT.sol";

interface WETH {
    function balanceOf(address) external returns (uint);
    function deposit() external payable;
    function approve(address,uint) external;
}

contract NFTSeller{
}
contract Bidder {
	Candle candle;
	uint auctionId;
	WETH weth;

	constructor(Candle _candle, uint _auctionId) payable {
		auctionId = _auctionId;
		candle = _candle;
		weth = WETH(0xd0A1E359811322d97991E03f863a0C30C2cF029C);
		weth.deposit{value: 10 ether}();
		weth.approve(address(candle), 2**256 - 1);
	}
	function increaseAuctionBid(uint bidAmount) public {
		candle.addToBid(auctionId, bidAmount);
	}

	function withdrawBid() public {
		candle.withdraw(auctionId);
	}
}

contract CandleTest is DSTest {
    Hevm internal constant hevm = Hevm(HEVM_ADDRESS);

    Candle candle;
    TestNFT nft;
    WETH weth;
    Bidder Alice;
    Bidder Bob;
    //NFTSeller Candice;

    struct Auction {
        address tokenAddress;
        uint tokenId;
        address seller;
        uint closingBlock;
        uint finalBlock;
        address bidToken;
        address currentHighestBidder;
        mapping (uint => address) highestBidderAtIndex;
        mapping (address => uint) cumululativeBidFromBidder;
    }
    
    function setUp() public {
        candle = new Candle();
        nft = new TestNFT();
        weth = WETH(0xd0A1E359811322d97991E03f863a0C30C2cF029C);
    }

    function testFail_basic_sanity() public {
        assertTrue(false);
    }

    function test_basic_sanity() public {
        assertTrue(true);
    }

    function test_create_nft() public {
        nft.mint(address(this));
    }

    function test_create_auction() public {
        uint tokenId = nft.mint(address(this));
        nft.approve(address(candle), tokenId);
        candle.createAuction(address(nft), tokenId, block.number + 100, block.number + 150, address(weth));
    }

    function test_create_and_bid() public {
        uint tokenId = nft.mint(address(this));
        nft.approve(address(candle), tokenId);
        uint aid = candle.createAuction(address(nft), tokenId, block.number + 100, block.number + 150, address(weth));
	Alice = new Bidder{value: 10 ether}(candle, aid);
	Bob = new Bidder{value: 10 ether}(candle, aid);
	address highest;
	uint amount;

	Alice.increaseAuctionBid(1 ether);
	(highest, amount) = candle.getHighestBid(aid);
	assertEq(highest, address(Alice));
	assertEq(amount, 1 ether);

	hevm.roll(block.number + 1);

	Bob.increaseAuctionBid(1.2 ether);
	(highest, amount) = candle.getHighestBid(aid);
	assertEq(highest, address(Bob));
	assertEq(amount, 1.2 ether);

	hevm.roll(block.number + 1);

	Alice.increaseAuctionBid(1 ether);
	(highest, amount) = candle.getHighestBid(aid);
	assertEq(highest, address(Alice));
	assertEq(amount, 2 ether);
    }

    function testFail_bid_after_finalised() public {
        uint tokenId = nft.mint(address(this));
        nft.approve(address(candle), tokenId);
        uint aid = candle.createAuction(address(nft), tokenId, block.number + 100, block.number + 150, address(weth));
	Alice = new Bidder{value: 10 ether}(candle, aid);
	Bob = new Bidder{value: 10 ether}(candle, aid);
	Alice.increaseAuctionBid(1 ether);
	hevm.roll(block.number + 200);
	// should fail as past last block
	Bob.increaseAuctionBid(2 ether);
    }
    function testFail_finalise_early() public {
        uint tokenId = nft.mint(address(this));
        nft.approve(address(candle), tokenId);
        uint aid = candle.createAuction(address(nft), tokenId, block.number + 100, block.number + 150, address(weth));
	hevm.roll(block.number + 105);
	candle.manualFulfil(aid);
    }

    function test_finalise_auction() public {
        uint tokenId = nft.mint(address(this));
        nft.approve(address(candle), tokenId);
        uint aid = candle.createAuction(address(nft), tokenId, block.number + 100, block.number + 150, address(weth));
	Alice = new Bidder{value: 10 ether}(candle, aid);
	Bob = new Bidder{value: 10 ether}(candle, aid);
	Alice.increaseAuctionBid(1 ether);
	hevm.roll(block.number + 1);
	Bob.increaseAuctionBid(2 ether);
	hevm.roll(block.number + 152);
	candle.manualFulfil(aid);
    }

    function test_finalise_withdraw() public {
        uint tokenId = nft.mint(address(this));
        nft.approve(address(candle), tokenId);
        uint aid = candle.createAuction(address(nft), tokenId, block.number + 100, block.number + 150, address(weth));
	Alice = new Bidder{value: 10 ether}(candle, aid);
	Bob = new Bidder{value: 10 ether}(candle, aid);
    }

}
