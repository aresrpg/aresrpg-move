import { sdk, keypair, NETWORK } from './client.js'
import { Transaction } from '@mysten/sui/transactions'
import { execSync } from 'child_process'
import { find_types } from '../../aresrpg-sdk/src/types-parser.js'

const txb = new Transaction()

console.log('==================== [ PUBLISHING PACKAGE ] ====================')
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

const { modules, dependencies } = JSON.parse(cli_result)

const [upgrade_cap] = txb.publish({
  modules,
  dependencies,
})

txb.transferObjects([upgrade_cap], keypair.getPublicKey().toSuiAddress())

console.log('publishing package...')

const result = await sdk.sui_client.signAndExecuteTransaction({
  signer: keypair,
  transaction: txb,
  options: {
    showEffects: true,
  },
})

if (!result.digest) throw new Error('Failed to publish package.')

const types = await find_types(
  {
    publish_digest: result.digest,
    policies_digest: '',
    upgrade_digest: '',
  },
  sdk.sui_client
)

console.log('package published:', result.digest)
console.log('package_id', types.PACKAGE_ID)
console.log('==================== [ x ] ====================')
