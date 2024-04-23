import { client, keypair, NETWORK } from './client.js'
import { TransactionBlock } from '@mysten/sui.js/transactions'
import { MIST_PER_SUI } from '@mysten/sui.js/utils'
import BigNumber from 'bignumber.js'
import { execSync } from 'child_process'
import { writeFileSync } from 'fs'

const txb = new TransactionBlock()

console.log('==================== [ PUBLISHING PACKAGE ] ====================')
console.log('network:', NETWORK)
console.log('public key:', keypair.getPublicKey().toSuiAddress())
console.log(' ')

const [, cli_result] = execSync(
  `
  sui client switch --env ${NETWORK} && \
  sui move build --dump-bytecode-as-base64 --path ./`,
  {
    encoding: 'utf-8',
  }
).split('\n')

const { modules, dependencies } = JSON.parse(cli_result)

const [upgrade_cap] = txb.publish({
  modules,
  dependencies,
})

txb.transferObjects([upgrade_cap], keypair.getPublicKey().toSuiAddress())

console.log('publishing package...')

const result = await client.signAndExecuteTransactionBlock({
  signer: keypair,
  transactionBlock: txb,
  options: {
    showEffects: true,
  },
})

if (!result.digest) throw new Error('Failed to publish package.')

const {
  digest,
  effects: {
    // @ts-ignore
    gasUsed: { computationCost, storageCost, storageRebate, nonRefundableStorageFee },
    // @ts-ignore
    created,
  },
} = result

const objects = await client.multiGetObjects({
  ids: created.map(({ reference: { objectId } }) => objectId),
  options: {
    showType: true,
  },
})

function find_type(value) {
  return objects.find(({ data: { type } }) => {
    const [, module_name, raw_type] = type.split('::')
    return type === value || `${module_name}::${raw_type}` == value
  })?.data?.objectId
}

function find_display(value) {
  return objects.find(({ data, data: { type } }) => {
    const [, display, Display, submodule, subtype] = type.split('::')
    const wanted = `${submodule}::${subtype}`.slice(0, -1)
    return display === 'display' && Display.split('<')[0] === 'Display' && wanted === value
  })?.data?.objectId
}

const gas = new BigNumber(computationCost)
  .plus(new BigNumber(storageCost))
  .minus(new BigNumber(storageRebate))
  .plus(new BigNumber(nonRefundableStorageFee))
  .div(MIST_PER_SUI.toString())
  .toString()

const publish_object = {
  NETWORK,
  digest,
  gas,
  package: find_type('package'),
  upgrade_cap: find_type('package::UpgradeCap'),
  character_admin_cap: find_type('character::AdminCap'),
  name_registry: find_type('character::CharacterNameRegistry'),
  server_admin_cap: find_type('server::AdminCap'),
  item_mint_cap: find_type('item::ItemMintCap'),
  item_display: find_display('item::Item'),
  character_display: find_display('character::Character'),
}
console.dir(publish_object, { depth: Infinity })

const file_name = `./published/publish_report_${new Date()
  .toISOString()
  .replace(/:/g, '-')}_${NETWORK}.json`

writeFileSync(file_name, JSON.stringify(publish_object, null, 2))

console.log('==================== [ x ] ====================')
