const { expect } = require('chai')
const { ethers } = require('hardhat')
const {
    loadFixture,
} = require('@nomicfoundation/hardhat-toolbox/network-helpers')

describe('DriftBottle System', function () {
    async function setupFixture() {
        const [owner, user1] = await ethers.getSigners()
        const driftBottleToken = await ethers.deployContract('DriftBottleToken')
        await driftBottleToken.waitForDeployment()
        const driftBottleTokenAddr = await driftBottleToken.getAddress()

        const driftBottle = await ethers.deployContract('DriftBottle', [
            driftBottleAddr,
            '10000000000000000000',
        ])
        await driftBottle.waitForDeployment()
        const driftBottleAddr = await driftBottle.getAddress()

        await driftBottleToken.grantMinterRole(driftBottleAddr)

        return {
            driftBottleToken,
            driftBottle,
            owner,
            user1,
            driftBottleAddr,
            driftBottleTokenAddr,
        }
    }

    // 编写测试用例
    it('allow adding a bottle', async () => {
        const { driftBottle, user1 } = await loadFixture(setupFixture)
        await expect(driftBottle.connect(user1).addBottle('ipfs://xxxHash'))
            .to.emit(driftBottle, 'BottleAdded')
            .withArgs(0, user1.address, 'ipfs://xxxHash')
    })
})
