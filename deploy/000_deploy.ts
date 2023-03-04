import { HardhatRuntimeEnvironment } from 'hardhat/types'
import { DeployFunction } from 'hardhat-deploy/types'
import { testnets } from '../src/utils/constants'

const func: DeployFunction = async function (hre: HardhatRuntimeEnvironment) {
  const { deployments, getNamedAccounts } = hre

  const { deploy, get } = deployments
  const { deployer } = await getNamedAccounts()

  const nftubeManagerDeploy = await deploy('NFTubeManager', {
    from: deployer,
    log: true,
    args: [100, deployer],
  })
  console.log('NFTubeManager: ', nftubeManagerDeploy.address)
}

func.tags = ['local', 'seed', 'main']
export default func
