import { client, keypair, NETWORK } from './client.js'
import { TransactionBlock, UpgradePolicy } from '@mysten/sui.js/transactions'
import { MIST_PER_SUI } from '@mysten/sui.js/utils'
import BigNumber from 'bignumber.js'
import { execSync } from 'child_process'
import { writeFileSync } from 'fs'

const PACKAGE_ID = '0xd975e94c12abf56154cce5d92e0961c21b77adb4cde0b8c974b8aa5ec8cbdddc'
const UPGRADE_CAP = '0xd35b5d61a3558949f704500f37d3e95adaf4c83c13105fc36b2bbd8dbe587cf1'
const CHARACTER_ADMIN_CAP = '0x56b0460486f2767f66b4cbf1ca0af9504d762fc8bd8d7442aaf7b2f1cc6a3cce'
const NAME_REGISTRY = '0x737873d66fec1ade650b4a31d6d4df71e136a1dfebf8029b06dfe106d5cbc485'

const txb = new TransactionBlock()

console.log('==================== [ UPGRADING PACKAGE ] ====================')
console.log('network:', NETWORK)
console.log('public key:', keypair.getPublicKey().toSuiAddress())
console.log(' ')

const [, cli_result] = execSync(
  `
  sui client switch --env ${NETWORK} && \
  sui move build --dump-bytecode-as-base64 --path ./`,
  {
    encoding: 'utf-8',
  }
).split('\n')

const { modules, dependencies, digest: build_digest } = JSON.parse(cli_result)

const ticket = txb.moveCall({
  target: '0x2::package::authorize_upgrade',
  arguments: [txb.object(UPGRADE_CAP), txb.pure(UpgradePolicy.COMPATIBLE), txb.pure(build_digest)],
})

const receipt = txb.upgrade({
  modules,
  dependencies,
  packageId: PACKAGE_ID,
  ticket,
})

txb.moveCall({
  target: '0x2::package::commit_upgrade',
  arguments: [txb.object(UPGRADE_CAP), receipt],
})

console.log('upgrading package...')

const result = await client
  .signAndExecuteTransactionBlock({
    signer: keypair,
    transactionBlock: txb,
    options: {
      showEffects: true,
    },
  })
  .catch(error => {
    console.error(error)
  })

const {
  digest,
  effects: {
    gasUsed: { computationCost, storageCost, storageRebate, nonRefundableStorageFee },
    created,
  },
} = result

const objects = await client.multiGetObjects({
  ids: created.map(({ reference: { objectId } }) => objectId),
  options: {
    showType: true,
  },
})

function find_type(value) {
  return objects.find(({ data: { type } }) => {
    const [, module_name, raw_type] = type.split('::')
    return type === value || `${module_name}::${raw_type}` == value
  })?.data?.objectId
}

function find_display(value) {
  return objects.find(({ data, data: { type } }) => {
    const [, display, Display, submodule, subtype] = type.split('::')
    const wanted = `${submodule}::${subtype}`.slice(0, -1)
    return display === 'display' && Display.split('<')[0] === 'Display' && wanted === value
  })?.data?.objectId
}

const gas = new BigNumber(computationCost)
  .plus(new BigNumber(storageCost))
  .minus(new BigNumber(storageRebate))
  .plus(new BigNumber(nonRefundableStorageFee))
  .div(MIST_PER_SUI.toString())
  .toString()

const upgrade_object = {
  NETWORK,
  digest,
  gas,
  previous_package: PACKAGE_ID,
  package: find_type('package'),
}

console.dir(upgrade_object, { depth: Infinity })

const file_name = `./published/upgrade_report_${new Date()
  .toISOString()
  .replace(/:/g, '-')}_${NETWORK}.json`

writeFileSync(file_name, JSON.stringify(upgrade_object, null, 2))

console.log('==================== [ x ] ====================')

console.log('==================== [ MIGRATING OBJECTS ] ====================')

const tx = new TransactionBlock()

tx.moveCall({
  target: `${upgrade_object.package}::character::migrate`,
  arguments: [tx.object(CHARACTER_ADMIN_CAP), tx.object(NAME_REGISTRY)],
})

const migrate_result = await client.signAndExecuteTransactionBlock({
  signer: keypair,
  transactionBlock: tx,
  options: {
    showEffects: true,
  },
})

if (migrate_result.effects?.status.error) {
  console.error(migrate_result.effects.status.error)
  console.dir(migrate_result, { depth: Infinity })
  process.exit(1)
}

console.log('objects migrated! 🎉')

console.log('==================== [ x ] ====================')
