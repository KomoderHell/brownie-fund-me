// SPDX-License_Identifier: MIT

pragma solidity ^0.6.6;

import "@chainlink/contracts/src/v0.6/interfaces/AggregatorV3Interface.sol";
// solidity version less than 0.8.0 wrap around int when over flow
// => uint8(256) = 0
// we can use the following library to help us check for such overflows
import "@chainlink/contracts/src/v0.6/vendor/SafeMathChainlink.sol";

contract FundMe {
    // deploying safe math for uint256 to check for overflow
    using SafeMathChainlink for uint256;

    address public owner;
    mapping(address => uint256) public addressToAmountFunded;
    address[] public funders;
    AggregatorV3Interface public priceFeed;

    constructor(address _priceFeed) public {
        priceFeed = AggregatorV3Interface(_priceFeed);
        owner = msg.sender;
    }

    // payable indicates that this function can be used for paying
    function fund() public payable {
        // setting a threshold for $50
        uint256 minimumUSD = 50 * 10**18;
        // used to check conditions, if not met returns with an optional error msg,
        // the amount is returned back to the sender along with any gas used
        require(
            getConvertionRate(msg.value) >= minimumUSD,
            "You need to spend more ETH"
        );
        addressToAmountFunded[msg.sender] += msg.value;
        funders.push(msg.sender);
    }

    function getVersion() public view returns (uint256) {
        return priceFeed.version();
    }

    function getPrice() public view returns (uint256) {
        // returning tuple without values
        (, int256 answer, , , ) = priceFeed.latestRoundData();
        // multiplication converts everything to WEI
        return uint256(answer * 10000000000);
        //3362.71476192
    }

    function getConvertionRate(uint256 ethAmount)
        public
        view
        returns (uint256)
    {
        uint256 ethPrice = getPrice();
        uint256 ethAmountIntUsd = (ethPrice * ethAmount) / 1000000000000000000;
        return ethAmountIntUsd;
    }

    function getEntranceFee() public view returns (uint256) {
        // mimimumUSD
        uint256 mimimumUSD = 50 * 10**18;
        uint256 price = getPrice();
        uint256 precision = 1 * 10**18;
        return (mimimumUSD * precision) / price;
    }

    modifier onlyOwner() {
        require(msg.sender == owner);
        _;
    }

    // to get back the money
    // Modifier will be used to make sure that not everybody can withdraw the money
    function withdraw() public payable onlyOwner {
        msg.sender.transfer(address(this).balance);

        // updating all the mapping of all the funders
        for (
            uint256 funderIndex = 0;
            funderIndex < funders.length;
            funderIndex++
        ) {
            address funder = funders[funderIndex];
            addressToAmountFunded[funder] = 0;
        }

        // reinitialize the funder array
        funders = new address[](0);
    }
}
