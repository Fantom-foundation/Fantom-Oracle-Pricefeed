pragma solidity ^0.5.0;

// AggregatorInterface specifies ChainLink aggregator interface.
import "./AggregatorInterface.sol";

// PriceOracleProxy implements proxy for set of ChainLink
// reference price oracles redirecting price requests to their target price
// oracle based on the token address.
contract PriceOracleProxy {
    // owner represents the manager address of the oracle aggregator.
    address public owner;

    // ChainLink aggregator interface references by token address.
    mapping(address => AggregatorInterface) public aggregators;

    // AggregatorChanged event is emitted when a new price oracle aggregator is set for a token.
    event AggregatorChanged(address indexed token, address aggregator, uint timestamp);

    // install new aggregator instance
    constructor() public {
        owner = msg.sender;
    }

    // -----------------------------------------------
    // aggregators per token address management
    // -----------------------------------------------

    // setAggregator sets a new aggregator reference for the given token.
    function setAggregator(address token, address aggregator) external {
        // only owner can make the change
        require(msg.sender == owner, "access restricted");

        // make the change
        aggregators[token] = AggregatorInterface(aggregator);

        // emit notification to express the change
        emit AggregatorChanged(token, aggregator, now);
    }

    // -----------------------------------------------
    // current price and time stamp
    // -----------------------------------------------

    // getPrice returns the latest price available for the token specified.
    function getPrice(address token) public view returns (int256) {
        // the price oracle must be set for the token
        require(aggregators[token] != AggregatorInterface(0), "oracle not available");

        // get the latest answer from the aggregator of the given token
        return aggregators[token].latestAnswer();
    }

    // getTimeStamp returns the time stamp the latest price was made available
    // by the ChainLink aggregator oracle for the token specified.
    function getTimeStamp(address token) public view returns (uint256) {
        // the price oracle must be set for the token
        require(aggregators[token] != AggregatorInterface(0), "oracle not available");

        // get the latest answer from the aggregator of the given token
        return aggregators[token].latestTimestamp();
    }

    // -----------------------------------------------
    // prices and time stamps history
    // -----------------------------------------------

    // getPreviousPrice returns the price available for the token specified
    // from the ChainLink aggregator oracle <_back> update cycles before the most recent one.
    function getPreviousPrice(address token, uint256 _back) public view returns (int256) {
        // the price oracle must be set for the token
        require(aggregators[token] != AggregatorInterface(0), "oracle not available");

        // get the latest answer round from the aggregator of the given token
        // we make sure the requested round is valid
        uint256 latest = aggregators[token].latestRound();
        require(_back <= latest, "not enough history");

        // get the price back then
        return aggregators[token].getAnswer(latest - _back);
    }

    // getTimeStamp returns the time stamp the price was made available
    // by the ChainLink aggregator oracle <_back> update cycles before the most recent one.
    function getPreviousTimeStamp(address token, uint256 _back) public view returns (uint256) {
        // the price oracle must be set for the token
        require(aggregators[token] != AggregatorInterface(0), "oracle not available");

        // get the latest answer round from the aggregator of the given token
        // we make sure the requested round is valid
        uint256 latest = aggregators[token].latestRound();
        require(_back <= latest, "not enough history");

        // get the time stamp back then
        return aggregators[token].getTimestamp(latest - _back);
    }
}
