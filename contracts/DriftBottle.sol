// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.28;

// 漂流瓶合约
contract DriftBottle {
    // 漂流瓶结构体
    struct Bottle {
        string[] ipfsHash;
        // 当前 bottle 所有者
        address receiver;
        // 所有发送者的列表
        address[] senderList;
    }

    // 一共有多少个 bottle
    // 即使是 private 在链上还是公开的
    Bottle[] private bottles;

    // 计数器（大海里现在还有多少个bottle漂着的）
    uint256 public bottlesLeft;

    address internal admin;

    mapping(address => uint256[]) private receiveBottles;
    mapping(address => uint256[]) private sentBottles;

    constructor() {
        admin = msg.sender;
    }

    // 扔出一个漂流瓶
    function addBottle(string memory _ipfsHash) public {
        // 0. 校验漂流瓶是否超出了上限
        require(sentBottles[msg.sender].length <= 100, "Exceed sent bottles");

        // 1. 向 sentBottles 中加一个瓶子
        uint256 bottleId = bottles.length;
        sentBottles[msg.sender].push(bottleId);

        // 2.
        string[] memory __ipfsHash = new string[](1);
        __ipfsHash[0] = _ipfsHash;

        // 3.
        address[] memory _senderList = new address[](1);
        _senderList[0] = msg.sender;
        bottles.push(Bottle(__ipfsHash, address(0), _senderList));

        // 更新瓶子的数量
        bottlesLeft++;
    }

    // 抓漂流瓶
    function catchBottle() public {
        uint256 randomBottleId = uint256(
            keccak256(abi.encodePacked(block.timestamp, msg.sender))
        ) % bottles.length;

        while (bottles[randomBottleId].receiver != address(0)) {
            randomBottleId = (randomBottleId + 1) % bottles.length;
        }
        receiveBottles[msg.sender].push(randomBottleId);
        bottles[randomBottleId].receiver = msg.sender;
        bottlesLeft--;
    }
}
