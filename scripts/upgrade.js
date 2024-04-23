import { client, keypair, NETWORK } from './client.js'
import { TransactionBlock, UpgradePolicy } from '@mysten/sui.js/transactions'
import { MIST_PER_SUI } from '@mysten/sui.js/utils'
import BigNumber from 'bignumber.js'
import { execSync } from 'child_process'
import { writeFileSync } from 'fs'

const PACKAGE_ID = '0xa92996f84219ac98ae614da404382d37089d2fd9a4714f9fbd6e663b74cd20af'
const UPGRADE_CAP = '0x625b418432dd89c5c96dcbadadb407509feb225d3d63f52d9e3a886c72d6516a'
const CHARACTER_ADMIN_CAP = '0x46f2df7e5383e55e8b71b72d62c46ad0e5c7365d6119e20d7ab32c9bcf46c5eb'
const NAME_REGISTRY = '0xdeba19cc5a661263c3b2e15fb7c98c5eec817260b6e17e95992381f553798d61'

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
