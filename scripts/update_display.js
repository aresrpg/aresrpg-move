import { Transaction } from '@mysten/sui/transactions'
import { sdk, keypair } from './client.js'

const txb = new Transaction()

console.log('Updating display...', keypair.getPublicKey().toSuiAddress())

txb.moveCall({
  target: '0x2::display::edit',
  typeArguments: [`${sdk.PACKAGE_ID}::item::Item`],
  arguments: [
    txb.object(sdk.DISPLAY_ITEM),
    txb.pure.string('image_url'),
    txb.pure.string('https://assets.aresrpg.world/item/{item_type}.png'),
  ],
})

txb.moveCall({
  target: '0x2::display::edit',
  typeArguments: [`${sdk.PACKAGE_ID}::character::Character`],
  arguments: [
    txb.object(sdk.DISPLAY_CHARACTER),
    txb.pure.string('image_url'),
    txb.pure.string('https://assets.aresrpg.world/classe/{classe}_{sex}.jpg'),
  ],
})

const result = await sdk.sui_client.signAndExecuteTransaction({
  transaction: txb,
  signer: keypair,
})

console.dir(result, { depth: Infinity })
