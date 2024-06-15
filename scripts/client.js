import { Ed25519Keypair } from '@mysten/sui/keypairs/ed25519'
import { getFullnodeUrl } from '@mysten/sui/client'
import { decodeSuiPrivateKey } from '@mysten/sui/cryptography'
import { SDK } from '@aresrpg/aresrpg-sdk/sui'
import { Network } from '@mysten/kiosk'

const { PRIVATE_KEY = '', NETWORK = 'testnet', SUI_RPC } = process.env

const keypair = Ed25519Keypair.fromSecretKey(decodeSuiPrivateKey(PRIVATE_KEY).secretKey)
const sdk = await SDK({
  // @ts-ignore
  rpc_url: SUI_RPC || getFullnodeUrl(NETWORK),
  // @ts-ignore
  wss_url: SUI_RPC || getFullnodeUrl(NETWORK),
  network: NETWORK === 'testnet' ? Network.TESTNET : Network.MAINNET,
})

export { NETWORK, keypair, sdk }
