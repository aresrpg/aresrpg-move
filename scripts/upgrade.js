import { client, keypair, NETWORK } from './client.js'
import { TransactionBlock, UpgradePolicy } from '@mysten/sui.js/transactions'
import { MIST_PER_SUI } from '@mysten/sui.js/utils'
import BigNumber from 'bignumber.js'
import { execSync } from 'child_process'
import { writeFileSync } from 'fs'

const PACKAGE_ID = '0x0c27b8da5a304e5cc1862a664379e039584ab5dee0988ef4e54e53f7f5c6970b'
const UPGRADE_CAP = '0x6b8167c5eef9db736f295f4f89f56be64f70136b9227c9cf47230b6019dad06f'
const ADMIN_CAP = '0xf7f83fa7f90bf4bcff4dd06a1cc3b8e08eb8f6a04ecf02a431614dc36bd989d3'
const VERSION = '0xcbebec478bfa2556feb97eef6d12a783578b6cfae1e6341f11617f32e33ead59'

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
  ...Object.fromEntries(
    objects.map(({ data }) => {
      // @ts-ignore
      const { type, objectId } = data

      if (type === '0x2::package::Publisher')
        return [`publisher (${objectId.slice(0, 4)})`, objectId]

      if (type.startsWith('0x2::display::Display<')) {
        const [, , , submodule, subtype] = type.split('::')
        const extracted_type = `${submodule}::${subtype}`.slice(0, -1)
        return [`Display<${extracted_type}>`, objectId]
      }

      if (type === 'package') return ['package', objectId]

      const [, module_name, raw_type] = type.split('::')

      return [`${module_name}::${raw_type}`, objectId]
    })
  ),
}

console.dir(upgrade_object, { depth: Infinity })

const file_name = `./reports/upgrade_${NETWORK}_${new Date().toISOString().replace(/:/g, '-')}.json`

writeFileSync(file_name, JSON.stringify(upgrade_object, null, 2))

console.log('==================== [ x ] ====================')

console.log('==================== [ UPDATING VERSION ] ====================')

const tx = new TransactionBlock()

tx.moveCall({
  target: `${upgrade_object.package}::version::update`,
  arguments: [tx.object(VERSION), tx.object(ADMIN_CAP)],
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

console.log('version updated! 🎉')
console.log('digest:', migrate_result.digest)

console.log('==================== [ x ] ====================')
