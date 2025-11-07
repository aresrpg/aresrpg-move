/**
 * Signature Verification Integration Tests
 *
 * Tests Ed25519 signature verification with keccak256 hashing against
 * deployed AresRPG Move contract on Sui testnet.
 *
 * Requirements:
 * - @mysten/sui SDK
 * - @noble/ed25519 (Ed25519 signing)
 * - @noble/hashes (keccak256)
 * - Deployed contract on testnet
 */

import { SuiClient } from '@mysten/sui/client';
import { Transaction } from '@mysten/sui/transactions';
import { Ed25519Keypair } from '@mysten/sui/keypairs/ed25519';
import { bcs } from '@mysten/sui/bcs';
import { ed25519 } from '@noble/curves/ed25519.js';
import { keccak_256 } from '@noble/hashes/sha3.js';
import crypto from 'crypto';
import 'dotenv/config';

// Test configuration
const NETWORK = process.env.NETWORK || 'testnet';
const PACKAGE_ID = process.env.PACKAGE_ID || '0xa6360a2815e0fa7fba981625a62c912c5a32aafc93904f439a51b9062598bbae';

// Initialize Sui client
const client = new SuiClient({
  url: NETWORK === 'testnet'
    ? 'https://fullnode.testnet.sui.io:443'
    : 'https://fullnode.mainnet.sui.io:443'
});

// Test utilities
function hexToBytes(hex) {
  return Uint8Array.from(Buffer.from(hex, 'hex'));
}

function bytesToHex(bytes) {
  return Buffer.from(bytes).toString('hex');
}

/**
 * Sign a message using Ed25519 with keccak256 hashing
 * This matches the on-chain implementation:
 *   1. BCS-encode message
 *   2. keccak256 hash
 *   3. Ed25519 sign the hash
 */
function signMessage(privateKey, message) {
  // Hash message with keccak256
  const messageHash = keccak_256(message);

  // Sign the hash with Ed25519
  const signature = ed25519.sign(messageHash, privateKey);

  return signature;
}

/**
 * Test 1: Empty message signature verification
 */
async function testEmptyMessage() {
  console.log('\n=== Test 1: Empty Message Signature ===');

  // Generate Ed25519 keypair
  const privateKeyHex = crypto.randomBytes(32);
  const publicKey = ed25519.getPublicKey(privateKeyHex);

  console.log(`Private key: ${bytesToHex(privateKeyHex)}`);
  console.log(`Public key: ${bytesToHex(publicKey)}`);

  // Sign empty message
  const emptyMessage = new Uint8Array(0);
  const signature = signMessage(privateKeyHex, emptyMessage);

  console.log(`Signature: ${bytesToHex(signature)}`);

  // Create transaction to verify signature on-chain
  const tx = new Transaction();

  // Create verifier and store result
  const verifier = tx.moveCall({
    target: `${PACKAGE_ID}::auth::verifier`,
    arguments: [],
  });

  // Verify signature
  tx.moveCall({
    target: `${PACKAGE_ID}::auth::verify`,
    arguments: [
      verifier,
      tx.pure.vector('u8', Array.from(publicKey)),
      tx.pure.vector('u8', Array.from(signature)),
    ],
  });

  try {
    // Dev-inspect to test without committing
    const result = await client.devInspectTransactionBlock({
      sender: '0x0000000000000000000000000000000000000000000000000000000000000000',
      transactionBlock: tx,
    });

    if (result.effects.status.status === 'success') {
      console.log('✅ Empty message signature verified successfully');
      return true;
    } else {
      console.error('❌ Signature verification failed:', result.effects.status);
      return false;
    }
  } catch (error) {
    console.error('❌ Test failed with error:', error.message);
    return false;
  }
}

/**
 * Test 2: Single field message (u64)
 */
async function testSingleFieldMessage() {
  console.log('\n=== Test 2: Single Field Message (u64) ===');

  const privateKeyHex = crypto.randomBytes(32);
  const publicKey = ed25519.getPublicKey(privateKeyHex);

  // BCS-encode a u64 value
  const value = 42n;
  const encodedValue = bcs.u64().serialize(value);

  console.log(`Value: ${value}`);
  console.log(`BCS-encoded: ${bytesToHex(encodedValue.toBytes())}`);

  // Sign the encoded message
  const signature = signMessage(privateKeyHex, encodedValue.toBytes());

  // Create transaction
  const tx = new Transaction();
  const verifier = tx.moveCall({
    target: `${PACKAGE_ID}::auth::verifier`,
    arguments: [],
  });

  // Add u64 value
  tx.moveCall({
    target: `${PACKAGE_ID}::auth::add`,
    arguments: [verifier, tx.pure.u64(value)],
    typeArguments: ['u64'],
  });

  // Verify signature
  tx.moveCall({
    target: `${PACKAGE_ID}::auth::verify`,
    arguments: [
      verifier,
      tx.pure.vector('u8', Array.from(publicKey)),
      tx.pure.vector('u8', Array.from(signature)),
    ],
  });

  try {
    const result = await client.devInspectTransactionBlock({
      sender: '0x0000000000000000000000000000000000000000000000000000000000000000',
      transactionBlock: tx,
    });

    if (result.effects.status.status === 'success') {
      console.log('✅ Single field message verified successfully');
      return true;
    } else {
      console.error('❌ Verification failed:', result.effects.status);
      return false;
    }
  } catch (error) {
    console.error('❌ Test failed:', error.message);
    return false;
  }
}

/**
 * Test 3: Multiple fields (ID + string + u64)
 */
async function testMultipleFields() {
  console.log('\n=== Test 3: Multiple Fields Message ===');

  const privateKeyHex = crypto.randomBytes(32);
  const publicKey = ed25519.getPublicKey(privateKeyHex);

  // Build message with multiple fields
  const objectId = '0x0000000000000000000000000000000000000000000000000000000000000001';
  const stringValue = 'hello';
  const numberValue = 42n;

  // BCS-encode each field and concatenate
  const encodedId = bcs.Address.serialize(objectId).toBytes();
  const encodedString = bcs.string().serialize(stringValue).toBytes();
  const encodedNumber = bcs.u64().serialize(numberValue).toBytes();

  const fullMessage = new Uint8Array([
    ...encodedId,
    ...encodedString,
    ...encodedNumber
  ]);

  console.log(`Message length: ${fullMessage.length} bytes`);

  const signature = signMessage(privateKeyHex, fullMessage);

  // Create transaction
  const tx = new Transaction();
  const verifier = tx.moveCall({
    target: `${PACKAGE_ID}::auth::verifier`,
    arguments: [],
  });

  // Add ID
  tx.moveCall({
    target: `${PACKAGE_ID}::auth::add`,
    arguments: [verifier, tx.pure.address(objectId)],
    typeArguments: ['address'],
  });

  // Add string
  tx.moveCall({
    target: `${PACKAGE_ID}::auth::add_string`,
    arguments: [verifier, tx.pure.string(stringValue)],
  });

  // Add number
  tx.moveCall({
    target: `${PACKAGE_ID}::auth::add`,
    arguments: [verifier, tx.pure.u64(numberValue)],
    typeArguments: ['u64'],
  });

  // Verify
  tx.moveCall({
    target: `${PACKAGE_ID}::auth::verify`,
    arguments: [
      verifier,
      tx.pure.vector('u8', Array.from(publicKey)),
      tx.pure.vector('u8', Array.from(signature)),
    ],
  });

  try {
    const result = await client.devInspectTransactionBlock({
      sender: '0x0000000000000000000000000000000000000000000000000000000000000000',
      transactionBlock: tx,
    });

    if (result.effects.status.status === 'success') {
      console.log('✅ Multiple fields verified successfully');
      return true;
    } else {
      console.error('❌ Verification failed:', result.effects.status);
      return false;
    }
  } catch (error) {
    console.error('❌ Test failed:', error.message);
    return false;
  }
}

/**
 * Test 4: Invalid signature (should fail)
 */
async function testInvalidSignature() {
  console.log('\n=== Test 4: Invalid Signature (Expected Failure) ===');

  const privateKeyHex = crypto.randomBytes(32);
  const publicKey = ed25519.getPublicKey(privateKeyHex);

  // Create invalid signature (all zeros)
  const invalidSignature = new Uint8Array(64);

  const tx = new Transaction();
  const verifier = tx.moveCall({
    target: `${PACKAGE_ID}::auth::verifier`,
    arguments: [],
  });

  tx.moveCall({
    target: `${PACKAGE_ID}::auth::verify`,
    arguments: [
      verifier,
      tx.pure.vector('u8', Array.from(publicKey)),
      tx.pure.vector('u8', Array.from(invalidSignature)),
    ],
  });

  try {
    const result = await client.devInspectTransactionBlock({
      sender: '0x0000000000000000000000000000000000000000000000000000000000000000',
      transactionBlock: tx,
    });

    if (result.effects.status.status === 'failure') {
      console.log('✅ Invalid signature correctly rejected');
      return true;
    } else {
      console.error('❌ Invalid signature should have failed!');
      return false;
    }
  } catch (error) {
    // Expected to fail
    console.log('✅ Invalid signature correctly rejected (error thrown)');
    return true;
  }
}

/**
 * Test 5: Message field ordering matters
 */
async function testFieldOrdering() {
  console.log('\n=== Test 5: Field Ordering Matters ===');

  const privateKeyHex = crypto.randomBytes(32);
  const publicKey = ed25519.getPublicKey(privateKeyHex);

  // Build two messages with different field ordering
  const stringValue = 'test';
  const numberValue = 123n;

  // Message A: string then number
  const encodedStringA = bcs.string().serialize(stringValue).toBytes();
  const encodedNumberA = bcs.u64().serialize(numberValue).toBytes();
  const messageA = new Uint8Array([...encodedStringA, ...encodedNumberA]);

  // Message B: number then string
  const encodedNumberB = bcs.u64().serialize(numberValue).toBytes();
  const encodedStringB = bcs.string().serialize(stringValue).toBytes();
  const messageB = new Uint8Array([...encodedNumberB, ...encodedStringB]);

  // Sign message A
  const signatureA = signMessage(privateKeyHex, messageA);

  // Try to verify message A's signature with message B's ordering
  const tx = new Transaction();
  const verifier = tx.moveCall({
    target: `${PACKAGE_ID}::auth::verifier`,
    arguments: [],
  });

  // Add fields in B's order (number then string)
  tx.moveCall({
    target: `${PACKAGE_ID}::auth::add`,
    arguments: [verifier, tx.pure.u64(numberValue)],
    typeArguments: ['u64'],
  });

  tx.moveCall({
    target: `${PACKAGE_ID}::auth::add_string`,
    arguments: [verifier, tx.pure.string(stringValue)],
  });

  // Verify with signature A (which was for A's ordering)
  tx.moveCall({
    target: `${PACKAGE_ID}::auth::verify`,
    arguments: [
      verifier,
      tx.pure.vector('u8', Array.from(publicKey)),
      tx.pure.vector('u8', Array.from(signatureA)),
    ],
  });

  try {
    const result = await client.devInspectTransactionBlock({
      sender: '0x0000000000000000000000000000000000000000000000000000000000000000',
      transactionBlock: tx,
    });

    if (result.effects.status.status === 'failure') {
      console.log('✅ Field ordering correctly matters (signature rejected)');
      return true;
    } else {
      console.error('❌ Signature should have failed with different ordering!');
      return false;
    }
  } catch (error) {
    console.log('✅ Field ordering correctly matters (error thrown)');
    return true;
  }
}

/**
 * Run all tests
 */
async function runAllTests() {
  console.log('==============================================');
  console.log('  AresRPG Signature Verification Tests');
  console.log('==============================================');
  console.log(`Network: ${NETWORK}`);
  console.log(`Package ID: ${PACKAGE_ID}`);
  console.log('==============================================');

  const results = [];

  results.push(await testEmptyMessage());
  results.push(await testSingleFieldMessage());
  results.push(await testMultipleFields());
  results.push(await testInvalidSignature());
  results.push(await testFieldOrdering());

  console.log('\n==============================================');
  console.log('  Test Results');
  console.log('==============================================');
  console.log(`Total tests: ${results.length}`);
  console.log(`Passed: ${results.filter(r => r).length}`);
  console.log(`Failed: ${results.filter(r => !r).length}`);
  console.log('==============================================\n');

  process.exit(results.every(r => r) ? 0 : 1);
}

// Run tests
runAllTests().catch(error => {
  console.error('Fatal error:', error);
  process.exit(1);
});
