import { execSync } from 'child_process'

import { Transaction } from '@mysten/sui/transactions'

import { NETWORK, keypair, sui_client } from './client.js'

const tx = new Transaction()

console.log('==================== [ PUBLISHING PACKAGE ] ====================')
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

const { modules, dependencies } = JSON.parse(cli_result)

const [upgrade_cap] = tx.publish({
  modules,
  dependencies,
})

tx.transferObjects([upgrade_cap], keypair.getPublicKey().toSuiAddress())

console.log('publishing package...')

const result = await sui_client.signAndExecuteTransaction({
  signer: keypair,
  transaction: tx,
  options: {
    showEffects: true,
  },
})

if (!result.digest) throw new Error('Failed to publish package.')

await sui_client.waitForTransaction({ digest: result.digest })

console.log('package published:', result.digest)
console.log('==================== [ x ] ====================')
