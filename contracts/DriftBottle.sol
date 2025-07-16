// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

// 接口合约
interface IDriftBottleToken {
    function mint(address to, uint256 amount) external;
}

// 漂流瓶合约
contract DriftBottle {
    // 漂流瓶结构体
    struct Bottle {
        // 包含所有经手过的 hash 值
        string[] ipfsHash;
        // 当前 bottle 接收者
        address receiver;
        // 所有发送者的列表（漂流瓶转手过的用户列表）
        address[] senderList;
    }

    // 一共有多少个 bottle
    // 即使是 private 在链上还是公开的
    Bottle[] private bottles;

    // 计数器（还有多少个bottle漂着的，可供打捞的）
    uint256 public bottlesLeft;

    // 管理员
    address internal admin;

    // 奖励数量
    uint256 public rewardAmount;

    // 每个调用合约的用户接收的漂流瓶
    mapping(address => uint256[])
        private receiveBottles; /* 用户addr 映射 bottleId */

    // 每个调用合约的用户发出的漂流瓶
    mapping(address => uint256[]) private sentBottles;

    // 添加 3 个事件
    event BottleAdded(
        uint256 indexed _bottleId,
        address indexed _sender,
        string _ipfsHash
    );
    event BottleCatched(uint256 indexed _bottleId, address indexed _receiver);
    event BottleUpdated(
        uint256 indexed _bottleId,
        address indexed _sender,
        string ipfsHash
    );

    // 声明一个接口合约状态变量
    IDriftBottleToken public tokenContract;

    // 构造函数
    // _initReward: 初始化奖励金额
    constructor(address _tokenAddress, uint256 _initReward) {
        tokenContract = IDriftBottleToken(_tokenAddress);
        // 将部署合约的用户设置为 admin
        admin = msg.sender;
        // 设置初始的奖励
        rewardAmount = _initReward;
    }

    // 扔出一个漂流瓶
    function addBottle(string memory _ipfsHash) public {
        // 0. 校验漂流瓶是否超出了上限（每个用户最多可以扔 100 个 bottles
        require(sentBottles[msg.sender].length <= 100, "Exceed sent bottles");

        // 1. 向 sentBottles 中加一个瓶子
        uint256 bottleId = bottles.length;
        // 键是当前合约调用者的地址, 值是当前扔出的 bottle 的 bottleId
        sentBottles[msg.sender].push(bottleId);

        // 2.
        string[] memory __ipfsHash = new string[](1);
        __ipfsHash[0] = _ipfsHash;

        // 3.
        address[] memory _senderList = new address[](1);
        _senderList[0] = msg.sender;

        // 4. 创建一个 bottle 并且把该 bottle 添加到 bottles 列表中
        bottles.push(Bottle(__ipfsHash, address(0), _senderList));

        // 更新瓶子的数量
        bottlesLeft++;

        emit BottleAdded(bottleId, msg.sender, _ipfsHash);

        // 每次扔出一个漂流瓶给 token 奖励, 奖励数量为 rewardAmount
        tokenContract.mint(msg.sender, rewardAmount);
    }

    // 抓漂流瓶
    function catchBottle() public {
        // 判断仍然有没有捕获的漂流瓶
        require(bottlesLeft > 0, "no bottles left.");

        // 每个用户可以抓10个漂流瓶
        require(
            receiveBottles[msg.sender].length <= 10,
            "exceed received bottles."
        );

        // 生成一个伪随机数（不安全，要用外部真随机数）
        uint256 randomBottleId = uint256(
            keccak256(abi.encodePacked(block.timestamp, msg.sender))
        ) % bottles.length;

        // 如果已经存在该 bottleId 了, 则循环重新生成 bottleId
        while (bottles[randomBottleId].receiver != address(0)) {
            randomBottleId = (randomBottleId + 1) % bottles.length;
        }

        // 当前调用合约者与 randomBottleId 相关联
        receiveBottles[msg.sender].push(randomBottleId);
        bottles[randomBottleId].receiver = msg.sender;
        bottlesLeft--;

        emit BottleCatched(randomBottleId, msg.sender);
    }

    // 更新
    function updateBottle(uint256 _bottleId, string memory _ipfsHash) public {
        // 判断 bottleId 是存在的
        require(_bottleId < bottles.length, "Id not exists.");

        // 判断 bottleId receiver 是否是你自己
        require(
            bottles[_bottleId].receiver == msg.sender,
            "bottle id not catched."
        );

        // 减少 receiveBottles
        uint len = receiveBottles[msg.sender].length;
        for (uint i = 0; i < len; i++) {
            if (receiveBottles[msg.sender][i] == _bottleId) {
                receiveBottles[msg.sender][i] = receiveBottles[msg.sender][
                    len - 1
                ];
                receiveBottles[msg.sender].pop();
                break;
            }
        }

        // 增加 sentBottles
        sentBottles[msg.sender].push(_bottleId);
        bottles[_bottleId].ipfsHash.push(_ipfsHash);
        bottles[_bottleId].receiver = address(0); /* 更新接收者地址为 0 */
        bottles[_bottleId].senderList.push(msg.sender);
        bottlesLeft++;

        emit BottleUpdated(_bottleId, msg.sender, _ipfsHash);
    }

    // 重新设置 rewardAmount 奖励数量
    function setRewardAmount(uint256 _newReward) public onlyAdmin {
        rewardAmount = _newReward;
    }

    modifier onlyAdmin() {
        require(msg.sender == admin, "only admin can invoke.");
        _;
    }
}
