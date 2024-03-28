import { getFullnodeUrl, SuiClient } from '@mysten/sui.js/client'
import { TransactionBlock } from '@mysten/sui.js/transactions'
import { Ed25519Keypair } from '@mysten/sui.js/keypairs/ed25519'
import { decodeSuiPrivateKey } from '@mysten/sui.js/cryptography'

const { PRIVATE_KEY = '' } = process.env
const NETWORK = 'mainnet'
const DISPLAY = '0x6d1c81038bee76beeb94e10549eec1e4bd57eab44b49d8fddddab41c7434ae79'
const DISPLAY_TYPE =
  '0x3602db18a9fad3b46ebef9de35934b0f2ed0d72bd6fc59f6301d32d8a4da8e42::character::Character'

const client = new SuiClient({ url: getFullnodeUrl(NETWORK) })
const keypair = Ed25519Keypair.fromSecretKey(decodeSuiPrivateKey(PRIVATE_KEY).secretKey)
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
    txb.pure.string('https://aresrpg.world/classe/{classe}_{male}.png'),
  ],
})

const result = await client.signAndExecuteTransactionBlock({
  transactionBlock: txb,
  signer: keypair,
})

console.dir(result, { depth: Infinity })
