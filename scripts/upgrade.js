import { keypair, NETWORK, sdk } from './client.js'
import { TransactionBlock, UpgradePolicy } from '@mysten/sui.js/transactions'
import { execSync } from 'child_process'

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
  arguments: [
    txb.object(sdk.UPGRADE_CAP),
    txb.pure(UpgradePolicy.COMPATIBLE),
    txb.pure(build_digest),
  ],
})

const receipt = txb.upgrade({
  modules,
  dependencies,
  packageId: sdk.LATEST_PACKAGE_ID,
  ticket,
})

txb.moveCall({
  target: '0x2::package::commit_upgrade',
  arguments: [txb.object(sdk.UPGRADE_CAP), receipt],
})

console.log('upgrading package...')

const result = await sdk.sui_client.signAndExecuteTransactionBlock({
  signer: keypair,
  transactionBlock: txb,
  options: {
    showEffects: true,
  },
})

// @ts-ignore
const package_id = result.effects?.created[0].reference.objectId

console.log('package upgraded:', result.digest)
console.log('package id:', package_id)
console.log('==================== [ x ] ====================')

console.log('==================== [ UPDATING VERSION ] ====================')

const tx = new TransactionBlock()

tx.moveCall({
  target: `${package_id}::version::admin_update`,
  arguments: [tx.object(sdk.VERSION), tx.object(sdk.ADMIN_CAP)],
})

const migrate_result = await sdk.sui_client.signAndExecuteTransactionBlock({
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
