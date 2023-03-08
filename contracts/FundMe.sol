// SPDX-License-Identifier: MIT
pragma solidity ^0.8.8;

// Uncomment this line to use console.log
// import "hardhat/console.sol";
import "@chainlink/contracts/src/v0.8/interfaces/AggregatorV3Interface.sol";
import "./PriceConverter.sol";

error FundMe__NotOwner();

contract FundMe {
    using PriceConverter for uint256;

    uint256 public constant MINIMUN_USD = 50 * 10 ** 18;
    address private immutable owner;
    address[] private funders;
    mapping(address => uint256) private fundersToAmountFunded;
    AggregatorV3Interface private priceFeed;

    constructor(address priceFeedAddress) {
        priceFeed = AggregatorV3Interface(priceFeedAddress);
        owner = msg.sender;
    }

    modifier onlyOwner() {
        if (msg.sender != owner) revert FundMe__NotOwner();
        _;
    }

    function fund() public payable {
        require(
            msg.value.getConversionRate(priceFeed) >= MINIMUN_USD,
            "You need to spend more ETH"
        );
        fundersToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function withdraw() public onlyOwner {
        for (uint256 index = 0; index < funders.length; index++) {
            address funder = funders[index];
            fundersToAmountFunded[funder] = 0;
        }
        funders = new address[](0);
        (bool callSuccess, ) = payable(msg.sender).call{
            value: address(this).balance
        }("");
        require(callSuccess, "Call failed");
    }

    function getFundersToAmountFunded(
        address funderAddress
    ) public view returns (uint256) {
        return fundersToAmountFunded[funderAddress];
    }

    function getFunder(uint256 index) public view returns (address) {
        return funders[index];
    }

    function getOwner() public view returns (address) {
        return owner;
    }

    function getPriceFeed() public view returns (AggregatorV3Interface) {
        return priceFeed;
    }

    receive() external payable {
        fund();
    }

    fallback() external payable {
        fund();
    }
}
