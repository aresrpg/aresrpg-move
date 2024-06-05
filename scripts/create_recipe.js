import { Transaction } from '@mysten/sui/transactions'
import { NETWORK, keypair, sdk } from './client.js'
import { ITEM_CATEGORY } from '@aresrpg/aresrpg-sdk/items'

const ADDRESS = keypair.getPublicKey().toSuiAddress()

console.log('==================== [ CREATING RECIPES ] ====================')
console.log('network:', NETWORK)
console.log('address:', ADDRESS)
console.log(' ')

const tx = new Transaction()

sdk.add_header(tx)

sdk.admin_create_recipe({
  tx,
  admin_cap: sdk.ADMIN_CAP,
  level: 1,
  ingredients: [
    {
      name: 'AfSui',
      item_type: '0x02264251ff808fbf55c06f60fd1174814fd787bd32dc539531894deb497029c7::afsui::AFSUI',
      amount: 25,
    },
    {
      name: 'Canine Skull',
      item_type: 'canine_skull',
      amount: 1,
    },
  ],
  template: {
    name: 'Mighty Fud Skull',
    item_category: ITEM_CATEGORY.HAT,
    item_set: 'fud',
    item_type: 'fud_hat',
    level: 1,
    stats_min: {
      vitality: 0,
      chance: 3,
      range: 0,
    },
    stats_max: {
      vitality: 20,
      chance: 5,
      range: 1,
    },
    damages: [],
  },
})

const { digest } = await sdk.sui_client.signAndExecuteTransaction({
  transaction: tx,
  signer: keypair,
})

console.log('digest:', digest)
