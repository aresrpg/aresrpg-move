import { Ed25519Keypair } from '@mysten/sui/keypairs/ed25519'
import { SuiClient, getFullnodeUrl } from '@mysten/sui/client'
import { decodeSuiPrivateKey } from '@mysten/sui/cryptography'

const { PRIVATE_KEY, NETWORK = 'testnet', SUI_RPC } = process.env

if (!PRIVATE_KEY) {
  throw new Error('PRIVATE_KEY environment variable is required')
}

const keypair = Ed25519Keypair.fromSecretKey(decodeSuiPrivateKey(PRIVATE_KEY).secretKey)

const sui_client = new SuiClient({
  url: SUI_RPC || getFullnodeUrl(NETWORK),
})

export { NETWORK, keypair, sui_client }
