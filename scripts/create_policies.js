import { TransactionBlock } from '@mysten/sui.js/transactions'
import { NETWORK, keypair, sdk } from './client.js'
import { TransferPolicyTransaction, percentageToBasisPoints } from '@mysten/kiosk'

const CHARACTER_ROYALTY = 10
const ITEM_ROYALTY = 5
const MIN_TRANSFER_FEE = 100_000_000 // (0.1 sui)
const DEPLOYER = keypair.getPublicKey().toSuiAddress()

console.log('==================== [ CREATING POLICIES ] ====================')
console.log('network:', NETWORK)
console.log('public key:', DEPLOYER)
console.log(' ')

const tx = new TransactionBlock()
const character_policy = new TransferPolicyTransaction({
  kioskClient: sdk.kiosk_client,
  transactionBlock: tx,
})
const item_policy = new TransferPolicyTransaction({
  kioskClient: sdk.kiosk_client,
  transactionBlock: tx,
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
  .addRoyaltyRule(percentageToBasisPoints(CHARACTER_ROYALTY), MIN_TRANSFER_FEE)
  .addPersonalKioskRule()
  .shareAndTransferCap(DEPLOYER)

item_policy
  .addLockRule()
  .addRoyaltyRule(percentageToBasisPoints(ITEM_ROYALTY), MIN_TRANSFER_FEE)
  .addPersonalKioskRule()
  .shareAndTransferCap(DEPLOYER)

tx.moveCall({
  target: `${sdk.PACKAGE_ID}::extension::mint_and_share_aresrpg_policy`,
  typeArguments: [`${sdk.PACKAGE_ID}::character::Character`],
  arguments: [tx.object(sdk.PUBLISHER_CHARACTER), tx.object(sdk.VERSION)],
})

tx.moveCall({
  target: `${sdk.PACKAGE_ID}::extension::mint_and_share_aresrpg_policy`,
  typeArguments: [`${sdk.PACKAGE_ID}::item::Item`],
  arguments: [tx.object(sdk.PUBLISHER_ITEM), tx.object(sdk.VERSION)],
})

// Sign and execute transaction block.
const result = await sdk.sui_client.signAndExecuteTransactionBlock({
  transactionBlock: tx,
  signer: keypair,
  options: { showEffects: true },
})

console.log('policies created:', result.digest)

console.log('==================== [ x ] ====================')
