import { getFullnodeUrl, SuiClient } from '@mysten/sui.js/client'
import { Ed25519Keypair } from '@mysten/sui.js/keypairs/ed25519'
import { decodeSuiPrivateKey } from '@mysten/sui.js/cryptography'

const { PRIVATE_KEY = '', NETWORK = 'mainnet' } = process.env

const client = new SuiClient({ url: getFullnodeUrl(NETWORK) })
const keypair = Ed25519Keypair.fromSecretKey(decodeSuiPrivateKey(PRIVATE_KEY).secretKey)

export { NETWORK, client, keypair }
