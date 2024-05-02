import { Ed25519Keypair } from '@mysten/sui.js/keypairs/ed25519'
import { getFullnodeUrl } from '@mysten/sui.js/client'
import { decodeSuiPrivateKey } from '@mysten/sui.js/cryptography'
import { SDK } from '@aresrpg/aresrpg-sdk/sui'
import { Network } from '@mysten/kiosk'

const { PRIVATE_KEY = '', NETWORK = 'testnet' } = process.env

const keypair = Ed25519Keypair.fromSecretKey(decodeSuiPrivateKey(PRIVATE_KEY).secretKey)
const sdk = await SDK({
  // @ts-ignore
  rpc_url: getFullnodeUrl(NETWORK),
  // @ts-ignore
  wss_url: getFullnodeUrl(NETWORK),
  network: NETWORK === 'testnet' ? Network.TESTNET : Network.MAINNET,
})

export { NETWORK, keypair, sdk }
