import { Transaction } from '@mysten/sui/transactions'
import { NETWORK, keypair, sdk } from './client.js'

const DEPLOYER = keypair.getPublicKey().toSuiAddress()
const RECIPIENT = '0x37cf46b499f740e653644bd2f7a8ed97f248e8b3c69d5d12c97d7845a54c0cd8'

console.log('==================== [ PROMOTING ADMIN ] ====================')
console.log('network:', NETWORK)
console.log('super admin:', DEPLOYER)
console.log('recipient:', RECIPIENT)
console.log(' ')

const tx = new Transaction()

sdk.add_header(tx)
sdk.admin_promote({ tx, recipient: RECIPIENT })

const { digest } = await sdk.sui_client.signAndExecuteTransaction({
  transaction: tx,
  signer: keypair,
})

console.log('digest:', digest)
