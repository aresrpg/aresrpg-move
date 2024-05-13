import { TransactionBlock } from '@mysten/sui.js/transactions'
import { sdk, keypair } from './client.js'

const DISPLAY = '0x10ba2e9c4743fc326d6254b43fdafedd982652541d079d51f72db9a683bfb91b'
const DISPLAY_TYPE =
  '0x1f9fb79fdc911702b57f1bad2d1230ceb242e0ca517c5dd52fd51b20c1b0605b::item::Item'

const txb = new TransactionBlock()

console.log('Updating display...', keypair.getPublicKey().toSuiAddress())

txb.moveCall({
  target: '0x2::display::edit',
  typeArguments: [DISPLAY_TYPE],
  arguments: [
    txb.object(DISPLAY),
    txb.pure.string('image_url'),
    txb.pure.string('https://app.aresrpg.world/item/{item_type}.jpg'),
  ],
})

// txb.moveCall({
//   target: '0x2::display::edit',
//   typeArguments: [DISPLAY_TYPE],
//   arguments: [
//     txb.object(DISPLAY),
//     txb.pure.string('image_url'),
//     txb.pure.string(
//       'https://raw.githubusercontent.com/aresrpg/aresrpg-dapp/master/src/assets/classe/{classe}_{sex}.jpg'
//     ),
//   ],
// })

const result = await sdk.sui_client.signAndExecuteTransactionBlock({
  transactionBlock: txb,
  signer: keypair,
})

console.dir(result, { depth: Infinity })
