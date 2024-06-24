import { Transaction } from '@mysten/sui/transactions'
import { NETWORK, keypair, sdk } from './client.js'
import { ITEM_CATEGORY } from '@aresrpg/aresrpg-sdk/items'

const ADDRESS = keypair.getPublicKey().toSuiAddress()
const RECIPIENT = '0xb1329007ab91c20209db03bf4126bb7b002b7de4fca20b576ac3ad48b5e88224'

console.log('==================== [ MINTING ITEM ] ====================')
console.log('network:', NETWORK)
console.log('address:', ADDRESS)
console.log('recipient:', RECIPIENT)
console.log(' ')

const tx = new Transaction()

const ITEMS = [
  // {
  //   name: 'Golden ring',
  //   item_category: ITEM_CATEGORY.RING,
  //   item_set: 'none',
  //   item_type: 'golden_ring',
  //   level: 12,
  //   amount: 1,
  //   stats: {
  //     action: 1,
  //   },
  // },
  // {
  //   name: 'Minotron',
  //   item_category: ITEM_CATEGORY.HAT,
  //   item_set: 'none',
  //   item_type: 'minotron',
  //   level: 23,
  //   amount: 1,
  //   stats: {
  //     vitality: 50,
  //     strength: 40,
  //   },
  // },
  // {
  //   name: 'Dague de Seti',
  //   item_category: ITEM_CATEGORY.DAGGER,
  //   item_set: 'Pharaoh',
  //   item_type: 'seti_dagger',
  //   level: 1,
  //   stats: {
  //     wisdom: 5,
  //     intelligence: 25,
  //     agility: 10,
  //     raw_damage: 5,
  //     water_resistance: 5,
  //     air_resistance: 5,
  //   },
  //   damages: [
  //     {
  //       from: 12,
  //       to: 14,
  //       damage_type: 'damage',
  //       element: 'air',
  //     },
  //     {
  //       from: 3,
  //       to: 5,
  //       damage_type: 'life_steal',
  //       element: 'water',
  //     },
  //   ],
  // },
  // {
  //   name: 'Mighty early Access key',
  //   item_category: ITEM_CATEGORY.KEY,
  //   item_set: 'none',
  //   item_type: 'early_access_key',
  //   level: 1,
  // },
  // {
  //   name: 'Prime Machin #3101',
  //   item_category: ITEM_CATEGORY.TITLE,
  //   item_set: 'Mirai',
  //   item_type: 'primemachin',
  //   level: 10,
  //   stats: {
  //     strength: 40,
  //     intelligence: 40,
  //     raw_damage: 3,
  //   },
  // },
  // {
  //   name: 'Canine Skull',
  //   item_category: ITEM_CATEGORY.RESOURCE,
  //   item_type: 'canine_skull',
  //   level: 1,
  //   amount: 450,
  // },
  // {
  //   name: 'Rune de Sui',
  //   item_category: ITEM_CATEGORY.RUNE,
  //   item_type: 'sui_rune',
  //   level: 1,
  //   amount: 200,
  // },
  // {
  //   name: 'Vaporeon',
  //   item_category: ITEM_CATEGORY.PET,
  //   item_set: 'none',
  //   item_type: 'vaporeon',
  //   level: 1,
  //   stackable: false,
  // },
  // {
  //   name: 'Suicune #0001',
  //   item_category: ITEM_CATEGORY.PET,
  //   item_set: 'hsui',
  //   item_type: 'suicune',
  //   level: 1,
  //   stackable: false,
  // },
]

ITEMS.forEach(item => {
  sdk.admin_mint_item({
    tx,
    recipient_kiosk: '0xa7b9d490972387e9fc40f08c5c30ccb573098428153154a052d41d75ca80c629',
    ...item,
  })
})

const { digest } = await sdk.sui_client.signAndExecuteTransaction({
  transaction: tx,
  signer: keypair,
})

console.log('digest:', digest)
