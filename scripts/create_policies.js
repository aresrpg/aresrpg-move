import { Transaction } from '@mysten/sui/transactions'
import { NETWORK, keypair, sdk } from './client.js'
import { TransferPolicyTransaction, percentageToBasisPoints } from '@mysten/kiosk'
import { find_types } from '../../aresrpg-sdk/src/types-parser.js'
import { writeFileSync } from 'fs'

const ROYALTY = 10
const MIN_TRANSFER_FEE = 100_000_000 // (0.1 sui)
const DEPLOYER = keypair.getPublicKey().toSuiAddress()
const ARESRPG = '0x37cf46b499f740e653644bd2f7a8ed97f248e8b3c69d5d12c97d7845a54c0cd8'

console.log('==================== [ CREATING POLICIES ] ====================')
console.log('network:', NETWORK)
console.log('public key:', DEPLOYER)
console.log('policy owner:', ARESRPG)
console.log(' ')

const tx = new Transaction()
const character_policy = new TransferPolicyTransaction({
  kioskClient: sdk.kiosk_client,
  transaction: tx,
})
const item_policy = new TransferPolicyTransaction({
  kioskClient: sdk.kiosk_client,
  transaction: tx,
})

await character_policy.create({
  type: `${sdk.PACKAGE_ID}::character::Character`,
  publisher: sdk.PUBLISHER_CHARACTER,
})

await item_policy.create({
  type: `${sdk.PACKAGE_ID}::item::Item`,
  publisher: sdk.PUBLISHER_ITEM,
})

character_policy
  .addLockRule()
  .addRoyaltyRule(percentageToBasisPoints(ROYALTY), MIN_TRANSFER_FEE)
  .addPersonalKioskRule()
  .shareAndTransferCap(ARESRPG)

tx.moveCall({
  target: `${sdk.LATEST_PACKAGE_ID}::amount_rule::add`,
  // @ts-ignore
  arguments: [item_policy.getPolicy(), item_policy.getPolicyCap()],
})

item_policy
  .addLockRule()
  .addRoyaltyRule(percentageToBasisPoints(ROYALTY), MIN_TRANSFER_FEE)
  .addPersonalKioskRule()
  .shareAndTransferCap(ARESRPG)

tx.moveCall({
  target: `${sdk.PACKAGE_ID}::protected_policy::mint_and_share_aresrpg_policy`,
  typeArguments: [`${sdk.PACKAGE_ID}::character::Character`],
  arguments: [tx.object(sdk.PUBLISHER_CHARACTER), tx.object(sdk.VERSION)],
})

tx.moveCall({
  target: `${sdk.PACKAGE_ID}::protected_policy::mint_and_share_aresrpg_policy`,
  typeArguments: [`${sdk.PACKAGE_ID}::item::Item`],
  arguments: [tx.object(sdk.PUBLISHER_ITEM), tx.object(sdk.VERSION)],
})

// Sign and execute transaction block.
const result = await sdk.sui_client.signAndExecuteTransaction({
  transaction: tx,
  signer: keypair,
  options: { showEffects: true },
})

await sdk.sui_client.waitForTransaction({ digest: result.digest })

console.log('policies created:', result.digest)

const types = await find_types(
  {
    digest: result.digest,
    package_id: sdk.PACKAGE_ID,
  },
  sdk.sui_client
)

console.dir(types, { depth: Infinity })

writeFileSync('./types-policies.json', JSON.stringify(types))

console.log('==================== [ x ] ====================')
