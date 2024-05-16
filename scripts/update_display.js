import { TransactionBlock } from '@mysten/sui.js/transactions'
import { sdk, keypair } from './client.js'

const txb = new TransactionBlock()

console.log('Updating display...', keypair.getPublicKey().toSuiAddress())

txb.moveCall({
  target: '0x2::display::edit',
  typeArguments: [`${sdk.PACKAGE_ID}::item::Item`],
  arguments: [
    txb.object(sdk.DISPLAY_ITEM),
    txb.pure.string('image_url'),
    txb.pure.string('http://assets.aresrpg.world/item/{item_type}.jpg'),
  ],
})

txb.moveCall({
  target: '0x2::display::edit',
  typeArguments: [`${sdk.PACKAGE_ID}::character::Character`],
  arguments: [
    txb.object(sdk.DISPLAY_CHARACTER),
    txb.pure.string('image_url'),
    txb.pure.string('http://assets.aresrpg.world/classe/{classe}_{sex}.jpg'),
  ],
})

const result = await sdk.sui_client.signAndExecuteTransactionBlock({
  transactionBlock: txb,
  signer: keypair,
})

console.dir(result, { depth: Infinity })
