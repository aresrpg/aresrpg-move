---
applyTo: '**'
---

# AresRPG Move Contracts

## Purpose

Smart contracts written in Sui Move that define all on-chain game mechanics and state for AresRPG. This is the source of truth for all persistent game data.

## Architecture Role

**Position in Stack:** Blockchain Layer (Sui Network)

- **Writes to:** Sui blockchain (on-chain state)
- **Read by:** aresrpg-rust-indexer → RedisGraph → aresrpg-server
- **Dependencies:** Sui framework, kiosk module, other Sui packages

## Core Modules

### Character System

- `character/` - Character NFT creation, deletion, updates
- `character_registry.move` - Name uniqueness, character lookup
- `character_inventory.move` - Equipment management (equip/unequip items)

### Item System

- `item/` - Item NFT creation, minting, destruction
- `item_statistics.move` - Item stats (vitality, strength, etc.)
- `item_damages.move` - Item damage types and elements
- Items are stored in Kiosks (Sui's NFT marketplace standard)

### Trading & Economy

- `kiosk/` - Personal kiosk integration for character/item trading
- Items can be listed/purchased through kiosk marketplace
- Price set to 0 for internal transfers (equip/unequip)

### Administrative

- `admin.move` - Admin capabilities for game management
- `auth.move` - Authentication and authorization
- `version.move` - Contract version tracking for upgrades

### Events

- `events.move` - All game events emitted on-chain:
  - ItemEquipEvent, ItemUnequipEvent
  - ItemMintEvent, ItemDestroyEvent, ItemMergeEvent, ItemSplitEvent
  - CharacterCreateEvent, CharacterUpdateEvent, CharacterDeleteEvent
  - SaleCreateEvent, SaleDeleteEvent
  - PetFeedEvent

## What's On-Chain vs Off-Chain

### On-Chain (Move Contracts)

- ✅ Character ownership & core attributes
- ✅ Item ownership & statistics
- ✅ Equipment state (what's equipped)
- ✅ Marketplace listings/purchases
- ✅ Item creation/destruction
- ✅ Character name registry

### Off-Chain (Server-Side)

- ❌ Combat mechanics
- ❌ Experience/leveling calculations
- ❌ Real-time position/movement
- ❌ Mob spawning/AI
- ❌ Temporary combat state

**Why?** On-chain transactions are expensive and slow. Server handles real-time gameplay, then commits results (experience gains, loot) to blockchain.

## Deployment Flow

### Publishing New Package

1. Update `rev` in `Move.toml` for target network
2. Run `npm run publish::<network>` (testnet/mainnet)
3. Update `published-at` in `Move.toml`
4. Update package address in dependent services:
   - aresrpg-sdk (env config)
   - aresrpg-server
   - aresrpg-rust-indexer
   - Frontend dapp

### Upgrading Existing Package

1. Verify `rev` in `Move.toml` is correct
2. Update `PACKAGE_VERSION` in `sources/version.move`
3. Run `npm run upgrade::<network>`
4. Update aresrpg-sdk with new types/interfaces

## Transaction Sponsoring

- Players initiate transactions (character creation, equipment changes)
- Server creates transaction with latest state
- Client signs with wallet
- Server sponsors gas fees
- Transaction submitted to Sui network

## Key Constraints

### Move Language Rules

- Objects must have `key` ability to be owned
- Events must have `copy` + `drop` abilities
- Shared objects for concurrent access
- Object wrapping for composability

### Sui Specifics

- Kiosk is mandatory for NFT trading
- Dynamic fields for extensible object storage
- Programmable Transaction Blocks (PTBs) for complex operations
- Object versioning for upgrades

## Integration Points

### With aresrpg-rust-indexer

- Indexer reads all events from this package
- Parses character/item state changes
- Builds RedisGraph representation

### With aresrpg-server

- Server reads state from RedisGraph (not directly from chain)
- Creates unsigned transactions for player actions
- Uses aresrpg-sdk to build transaction blocks

### With aresrpg-sdk

- SDK provides TypeScript wrappers for Move functions
- Used by both server and frontend
- Handles BCS serialization/deserialization

## Development Notes

- **Network:** Testnet for development, Mainnet for production
- **Gas:** All transactions sponsored by server (gas station)
- **State Changes:** Must emit events for indexer to track
- **Upgrades:** Use capability-based upgrade pattern
- **Testing:** Move has built-in testing framework (`sui move test`)

## Common Tasks

### Adding New Event Type

1. Define struct in `events.move` with `copy, drop` abilities
2. Emit event in relevant module function
3. Rebuild and upgrade package
4. Update aresrpg-rust-indexer to parse new event
5. Update aresrpg-server if server needs to react

### Modifying Object Structure

1. Update Move struct definition
2. Handle upgrade migration if needed
3. Rebuild package
4. Update SDK type definitions
5. Update indexer parsing logic
6. Update server logic if applicable

### Debugging

- Use `sui client` CLI for testing
- Check transaction effects on Sui explorer
- Verify events are emitted correctly
- Test on testnet before mainnet deployment

## Important Reminders

- ⚠️ On-chain data is permanent - design carefully
- ⚠️ Gas costs matter - batch operations when possible
- ⚠️ Events are the indexer's only data source
- ⚠️ Package address changes require full redeployment of services
- ⚠️ Sui upgrades every 2 weeks - test compatibility
