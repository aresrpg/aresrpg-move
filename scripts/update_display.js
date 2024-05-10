import { TransactionBlock } from '@mysten/sui.js/transactions'
import { sdk, keypair } from './client.js'
import { ITEM_CATEGORY } from '@aresrpg/aresrpg-sdk/items'

const DISPLAY = '0x261de0a1d4c5239e1b2a4974d343268a44e9b082de93b9c3646e935bc7b7a418'
const DISPLAY_TYPE =
  '0xaddc2335cf9b67c69def6bc8cfb71192cc864e34ca71bf9eddb4a76c252800bc::character::Character'

const txb = new TransactionBlock()

console.log('Updating display...', keypair.getPublicKey().toSuiAddress())

txb.moveCall({
  target: '0x2::display::edit',
  typeArguments: [DISPLAY_TYPE],
  arguments: [
    txb.object(DISPLAY),
    txb.pure.string('link'),
    txb.pure.string('https://aresrpg.world/classe/{classe}'),
  ],
})

txb.moveCall({
  target: '0x2::display::edit',
  typeArguments: [DISPLAY_TYPE],
  arguments: [
    txb.object(DISPLAY),
    txb.pure.string('image_url'),
    txb.pure.string(
      'https://raw.githubusercontent.com/aresrpg/aresrpg-dapp/master/src/assets/classe/{classe}_{sex}.jpg'
    ),
  ],
})

const result = await sdk.sui_client.signAndExecuteTransactionBlock({
  transactionBlock: txb,
  signer: keypair,
})

console.dir(result, { depth: Infinity })
