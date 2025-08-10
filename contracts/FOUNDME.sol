// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";

contract BeggingContract {
    AggregatorV3Interface internal dataFeed;
    mapping(address => uint256) public fundersToAmount;
    address[] public funders;
    address private owner;
    event Donation(address indexed sender, uint256 amount);
    uint256 public startTime;
    uint256 public ENDTIME = 30;

    /**
     * Network: Sepolia
     * Aggregator: ETH/USD
     * Address: 0x694AA1769357215DE4FAC081bf1f309aDC325306
     */
    constructor(address _owner) {
        owner = _owner;
        startTime = block.timestamp;
        dataFeed = AggregatorV3Interface(
            0x694AA1769357215DE4FAC081bf1f309aDC325306
        );
    }

    function getChainlinkDataFeedLatestAnswer() public view returns (int256) {
        (, int256 answer, , uint256 updatedAt, ) = dataFeed.latestRoundData();
        require(updatedAt >= block.timestamp - 1 hours, "Data is too old");
        return answer;
    }

    function convertEthToUsd() internal view returns (uint256) {
        uint256 ethPrice = uint256(getChainlinkDataFeedLatestAnswer()); // 2000 * 1e8
        return (msg.value * ethPrice) / 1e8; // Convert to USD (18 decimals)
    }

    function donate() external payable returns (uint256) {
        require(block.timestamp < startTime + ENDTIME, "not in donate time");
        fundersToAmount[msg.sender] += msg.value;
        if (fundersToAmount[msg.sender] == 0) {
            funders.push(msg.sender); // 仅首次捐赠时记录
        }
        emit Donation(msg.sender, msg.value);
        return msg.value;
    }

    function withdraw(uint256 _value) public {
        require(msg.sender == owner, "you are not owner");
        require(_value <= address(this).balance, "Insufficient balance");
        (bool success, ) = payable(msg.sender).call{value: _value}("");
        require(success, "Transfer failed");
    }

    function getBalance() public view returns (uint256) {
        return address(this).balance;
    }

    function getDonation() public view returns (uint256) {
        return fundersToAmount[msg.sender];
    }

    /**
     * 获取金额最大的三个资助者地址（降序排列）
     * @return 包含最大资助者的地址数组
     */
    function getTopThree() public view returns (address[] memory) {
        uint256 funderCount = funders.length;

        // 处理空数组情况
        if (funderCount == 0) {
            return new address[](0);
        }

        // 初始化结果数组（长度为实际数量）
        uint256 resultSize = funderCount < 3 ? funderCount : 3;
        address[] memory result = new address[](resultSize);

        // 直接处理小数组情况（≤3个元素）
        if (funderCount <= 3) {
            for (uint256 i = 0; i < funderCount; i++) {
                result[i] = funders[i];
            }
            return _sortByAmount(result);
        }

        // 初始化三个候选位置
        address[3] memory candidates = [funders[0], funders[1], funders[2]];

        // 初始排序
        _sortThree(candidates);

        // 遍历剩余资助者
        for (uint256 i = 3; i < funderCount; i++) {
            address current = funders[i];
            uint256 currentAmount = fundersToAmount[current];

            // 只比较比当前最小值大的候选者
            if (currentAmount > fundersToAmount[candidates[2]]) {
                candidates[2] = current;

                // 单次冒泡排序（优化）
                if (
                    fundersToAmount[candidates[2]] >
                    fundersToAmount[candidates[1]]
                ) {
                    (candidates[1], candidates[2]) = (
                        candidates[2],
                        candidates[1]
                    );

                    if (
                        fundersToAmount[candidates[1]] >
                        fundersToAmount[candidates[0]]
                    ) {
                        (candidates[0], candidates[1]) = (
                            candidates[1],
                            candidates[0]
                        );
                    }
                }
            }
        }

        // 转换为动态数组
        result[0] = candidates[0];
        result[1] = candidates[1];
        result[2] = candidates[2];

        return result;
    }

    /**
     * 对三个地址按金额降序排序（高效实现）
     */
    function _sortThree(address[3] memory arr) private view {
        // 第一步：比较前两个元素
        if (fundersToAmount[arr[0]] < fundersToAmount[arr[1]]) {
            (arr[0], arr[1]) = (arr[1], arr[0]);
        }

        // 第二步：比较后两个元素
        if (fundersToAmount[arr[1]] < fundersToAmount[arr[2]]) {
            (arr[1], arr[2]) = (arr[2], arr[1]);
        }

        // 第三步：重新比较前两个元素
        if (fundersToAmount[arr[0]] < fundersToAmount[arr[1]]) {
            (arr[0], arr[1]) = (arr[1], arr[0]);
        }
    }

    /**
     * 对小数组（≤3）按金额降序排序
     */
    function _sortByAmount(address[] memory arr)
        private
        view
        returns (address[] memory)
    {
        uint256 len = arr.length;

        if (len == 2) {
            if (fundersToAmount[arr[0]] < fundersToAmount[arr[1]]) {
                (arr[0], arr[1]) = (arr[1], arr[0]);
            }
        } else if (len == 3) {
            address[3] memory fixedArr = [arr[0], arr[1], arr[2]];
            _sortThree(fixedArr);
            arr[0] = fixedArr[0];
            arr[1] = fixedArr[1];
            arr[2] = fixedArr[2];
        }

        return arr;
    }
}
