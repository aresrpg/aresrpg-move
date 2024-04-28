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

const gas = new BigNumber(computationCost)
  .plus(new BigNumber(storageCost))
  .minus(new BigNumber(storageRebate))
  .plus(new BigNumber(nonRefundableStorageFee))
  .div(MIST_PER_SUI.toString())
  .toString()

const publish_object = {
  date: new Date().toISOString(),
  network: NETWORK,
  digest,
  gas,
  ...Object.fromEntries(
    objects.map(({ data }) => {
      // @ts-ignore
      const { type, objectId } = data

      if (type === '0x2::package::Publisher')
        return [`publisher (${objectId.slice(0, 4)})`, objectId]

      if (type.startsWith('0x2::display::Display<')) {
        const [, , , submodule, subtype] = type.split('::')
        const extracted_type = `${submodule}::${subtype}`.slice(0, -1)
        return [`Display<${extracted_type}>`, objectId]
      }

      if (type === 'package') return ['package', objectId]

      const [, module_name, raw_type] = type.split('::')

      return [`${module_name}::${raw_type}`, objectId]
    })
  ),
}

console.dir(publish_object, { depth: Infinity })

const file_name = `./reports/publish_${NETWORK}_${new Date()
  .toISOString()
  .replace(/:/g, '-')}.json`

writeFileSync(file_name, JSON.stringify(publish_object, null, 2))

console.log('==================== [ x ] ====================')
