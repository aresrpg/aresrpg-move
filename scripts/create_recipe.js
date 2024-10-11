import { Transaction } from '@mysten/sui/transactions'
import { NETWORK, keypair, sdk } from './client.js'
import { ITEM_CATEGORY } from '@aresrpg/aresrpg-sdk/items'

const ADDRESS = keypair.getPublicKey().toSuiAddress()

console.log('==================== [ CREATING RECIPES ] ====================')
console.log('network:', NETWORK)
console.log('address:', ADDRESS)
console.log(' ')

const Token = name =>
  `0x02a56d35041b2974ec23aff7889d8f7390b53b08e8d8bb91aa55207a0d5dd723::${name.toLowerCase()}::${name.toUpperCase()}`

const tx = new Transaction()

const RECIPES = {
  suicunio: {
    level: 1,
    ingredients: [
      {
        name: 'hsui',
        item_type: Token('hsui'),
        amount: 25000000000n,
      },
      {
        name: 'afsui',
        item_type: Token('afsui'),
        amount: 14000000000n,
      },
      {
        name: 'Rune de Sui',
        item_type: 'sui_rune',
        amount: 1,
      },
      {
        name: 'Canine Skull',
        item_type: 'canine_skull',
        amount: 5,
      },
    ],
    template: {
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
  },
}

sdk.add_header(tx)

sdk.admin_create_recipe({
  tx,
  ...RECIPES.suicunio,
  admin_cap: sdk.ADMIN_CAP,
})

const { digest } = await sdk.sui_client.signAndExecuteTransaction({
  transaction: tx,
  signer: keypair,
})

console.log('digest:', digest)
