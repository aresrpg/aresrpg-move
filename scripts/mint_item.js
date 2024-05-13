import { TransactionBlock } from '@mysten/sui.js/transactions'
import { NETWORK, keypair, sdk } from './client.js'
import { ITEM_CATEGORY } from '@aresrpg/aresrpg-sdk/items'

const ADDRESS = keypair.getPublicKey().toSuiAddress()
const RECIPIENT = '0xb1329007ab91c20209db03bf4126bb7b002b7de4fca20b576ac3ad48b5e88224'

console.log('==================== [ MINTING ITEM ] ====================')
console.log('network:', NETWORK)
console.log('address:', ADDRESS)
console.log('recipient:', RECIPIENT)
console.log(' ')

const tx = new TransactionBlock()

sdk.admin_mint_item({
  tx,
  recipient_kiosk: '0xa7b9d490972387e9fc40f08c5c30ccb573098428153154a052d41d75ca80c629',
  name: 'Dagues de Seti',
  item_category: ITEM_CATEGORY.DAGGER,
  item_set: 'Pharaoh',
  item_type: 'seti_dagger',
  level: 1,
  amount: 145,
  // stats: {
  //   vitality: 30,
  //   wisdom: 30,
  //   strength: 0,
  //   intelligence: 0,
  //   chance: 0,
  //   agility: 0,
  //   range: 0,
  //   movement: 1,
  //   action: 0,
  //   critical: 0,
  //   raw_damage: 5,
  //   critical_chance: 1,
  //   critical_outcomes: 50,

  //   earth_resistance: 0,
  //   fire_resistance: 5,
  //   water_resistance: 0,
  //   air_resistance: 0,
  // },
  // damages: [
  //   {
  //     from: 12,
  //     to: 14,
  //     damage_type: 'damage',
  //     element: 'air',
  //   },
  //   {
  //     from: 3,
  //     to: 5,
  //     damage_type: 'life_steal',
  //     element: 'water',
  //   },
  // ],
})

const { digest } = await sdk.sui_client.signAndExecuteTransactionBlock({
  transactionBlock: tx,
  signer: keypair,
})

console.log('digest:', digest)
