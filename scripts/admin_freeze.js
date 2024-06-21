import { Transaction } from '@mysten/sui/transactions'
import { NETWORK, keypair, sdk } from './client.js'

console.log('==================== [ FREEZING CONTRACT ] ====================')
console.log('network:', NETWORK)
console.log(' ')

const tx = new Transaction()

tx.moveCall({
  target: `${sdk.LATEST_PACKAGE_ID}::version::admin_freeze`,
  arguments: [tx.object(sdk.VERSION), tx.object(sdk.ADMIN_CAP)],
})

const { digest } = await sdk.sui_client.signAndExecuteTransaction({
  transaction: tx,
  signer: keypair,
})

console.log('digest:', digest)
