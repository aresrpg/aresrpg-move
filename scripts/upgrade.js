import { keypair, NETWORK, sdk } from './client.js'
import { Transaction, UpgradePolicy } from '@mysten/sui/transactions'
import { execSync } from 'child_process'
import { setTimeout } from 'timers/promises'
import { find_types } from '../../aresrpg-sdk/src/types-parser.js'
import { writeFileSync } from 'fs'

const txb = new Transaction()

console.log('==================== [ UPGRADING PACKAGE ] ====================')
console.log('network:', NETWORK)
console.log('public key:', keypair.getPublicKey().toSuiAddress())
console.log(' ')

const [, cli_result] = execSync(
  `
  sui client switch --env ${NETWORK} && \
  sui move build ${NETWORK === 'mainnet' ? '' : '--dev'} --dump-bytecode-as-base64 --path ./`,
  {
    encoding: 'utf-8',
  }
).split('\n')

const { modules, dependencies, digest: build_digest } = JSON.parse(cli_result)

const ticket = txb.moveCall({
  target: '0x2::package::authorize_upgrade',
  arguments: [
    txb.object(sdk.UPGRADE_CAP),
    txb.pure.u8(UpgradePolicy.COMPATIBLE),
    txb.pure.vector('u8', build_digest),
  ],
})

const receipt = txb.upgrade({
  modules,
  dependencies,
  package: sdk.LATEST_PACKAGE_ID,
  ticket,
})

txb.moveCall({
  target: '0x2::package::commit_upgrade',
  arguments: [txb.object(sdk.UPGRADE_CAP), receipt],
})

console.log('upgrading package...')

const result = await sdk.sui_client.signAndExecuteTransaction({
  signer: keypair,
  transaction: txb,
  options: {
    showEffects: true,
  },
})

// @ts-ignore
const package_id = result.effects?.created[0].reference.objectId

console.log('package upgraded:', result.digest)
console.log('package id:', package_id)
console.log('==================== [ x ] ====================')

await setTimeout(3000)

console.log('==================== [ UPDATING VERSION ] ====================')

const tx = new Transaction()

tx.moveCall({
  target: `${package_id}::version::admin_update`,
  arguments: [tx.object(sdk.VERSION), tx.object(sdk.ADMIN_CAP)],
})

const migrate_result = await sdk.sui_client.signAndExecuteTransaction({
  signer: keypair,
  transaction: tx,
  options: {
    showEffects: true,
  },
})

await sdk.sui_client.waitForTransaction({ digest: migrate_result.digest })

if (migrate_result.effects?.status.error) {
  console.error(migrate_result.effects.status.error)
  console.dir(migrate_result, { depth: Infinity })
  process.exit(1)
}

console.log('version updated! 🎉')
console.log('digest:', migrate_result.digest)

const types = await find_types(
  {
    digest: result.digest,
    package_id: sdk.PACKAGE_ID,
  },
  sdk.sui_client
)

console.log('package published:', result.digest)
console.dir(types, { depth: Infinity })

writeFileSync('./types-upgrade.json', JSON.stringify(types))

console.log('==================== [ x ] ====================')
