import { execSync } from 'child_process'
import { setTimeout } from 'timers/promises'

import { Transaction, UpgradePolicy } from '@mysten/sui/transactions'

import { NETWORK, keypair, sui_client } from './client.js'

const { UPGRADE_CAP, PACKAGE_ID } = process.env

if (!UPGRADE_CAP) {
  throw new Error('UPGRADE_CAP environment variable is required')
}

if (!PACKAGE_ID) {
  throw new Error('PACKAGE_ID environment variable is required')
}

const tx = new Transaction()

console.log('==================== [ UPGRADING PACKAGE ] ====================')
console.log('network:', NETWORK)
console.log('public key:', keypair.getPublicKey().toSuiAddress())
console.log(' ')

const [, cli_result] = execSync(
  `
  sui client switch --env ${NETWORK} && \\
  sui move build ${NETWORK === 'mainnet' ? '' : '--dev'} --dump-bytecode-as-base64 --path ./`,
  {
    encoding: 'utf-8',
  }
).split('\n')

const { modules, dependencies, digest: build_digest } = JSON.parse(cli_result)

const ticket = tx.moveCall({
  target: '0x2::package::authorize_upgrade',
  arguments: [
    tx.object(UPGRADE_CAP),
    tx.pure.u8(UpgradePolicy.COMPATIBLE),
    tx.pure.vector('u8', build_digest),
  ],
})

const receipt = tx.upgrade({
  modules,
  dependencies,
  package: PACKAGE_ID,
  ticket,
})

tx.moveCall({
  target: '0x2::package::commit_upgrade',
  arguments: [tx.object(UPGRADE_CAP), receipt],
})

console.log('upgrading package...', PACKAGE_ID)

const result = await sui_client.signAndExecuteTransaction({
  signer: keypair,
  transaction: tx,
  options: {
    showEffects: true,
  },
})

const package_id = result.effects?.created[0].reference.objectId

console.log('package upgraded:', result.digest)
console.log('package id:', package_id)
console.log('==================== [ x ] ====================')

await setTimeout(3000)

console.log('==================== [ UPDATING VERSION ] ====================')

const version_tx = new Transaction()

version_tx.moveCall({
  target: `${package_id}::version::admin_update`,
  arguments: [
    version_tx.object(process.env.VERSION),
    version_tx.object(process.env.ADMIN_CAP),
  ],
})

const migrate_result = await sui_client.signAndExecuteTransaction({
  signer: keypair,
  transaction: version_tx,
  options: {
    showEffects: true,
  },
})

await sui_client.waitForTransaction({ digest: migrate_result.digest })

if (migrate_result.effects?.status.error) {
  console.error(migrate_result.effects.status.error)
  console.dir(migrate_result, { depth: Infinity })
  process.exit(1)
}

console.log('version updated! 🎉')
console.log('digest:', migrate_result.digest)
console.log('==================== [ x ] ====================')
