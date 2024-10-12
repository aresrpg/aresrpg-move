import { Transaction } from '@mysten/sui/transactions'
import { NETWORK, keypair, sdk } from './client.js'
import { ITEM_CATEGORY } from '@aresrpg/aresrpg-sdk/items'
import { MIST_PER_SUI } from '@mysten/sui/utils'

const ADDRESS = keypair.getPublicKey().toSuiAddress()

console.log('==================== [ CREATING SALES ] ====================')
console.log('network:', NETWORK)
console.log('address:', ADDRESS)
console.log(' ')

const tx = new Transaction()
const to_mists = sui => sui * MIST_PER_SUI

const ITEMS = {
  suicunio: {
    name: 'El Suicunio',
    item_category: ITEM_CATEGORY.HAT,
    item_set: 'hsui',
    item_type: 'suicunio',
    level: 7,
    stats_min: {
      vitality: 0,
      chance: 10,
      water_resistance: 2,
      air_resistance: 0,
      agility: 0,
      raw_damage: 0,
      intelligence: 0,
    },
    stats_max: {
      vitality: 40,
      chance: 25,
      water_resistance: 5,
      air_resistance: 5,
      agility: 25,
      raw_damage: 4,
      intelligence: 15,
    },
    damages: [],
  },
}

sdk.add_header(tx)

sdk.admin_create_sale({
  tx,
  template: ITEMS.suicunio,
  admin_cap: sdk.ADMIN_CAP,
  price: to_mists(5n),
  stock: 10,
})

const { digest } = await sdk.sui_client.signAndExecuteTransaction({
  transaction: tx,
  signer: keypair,
})

console.log('digest:', digest)
