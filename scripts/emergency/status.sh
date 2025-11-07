#!/bin/bash
#
# Contract Status Check
#
# Purpose: Quick health check of deployed contract
# Usage: ./status.sh <network>
# Networks: testnet, mainnet
#

set -e

NETWORK=${1:-testnet}

# Colors
BLUE='\033[0;34m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${BLUE}📊 AresRPG Contract Status${NC}"
echo "======================================"
echo "Network: $NETWORK"
echo "Time: $(date)"
echo ""

# Switch to network
sui client switch --env $NETWORK > /dev/null 2>&1

# Get active address
ACTIVE_ADDR=$(sui client active-address 2>/dev/null)
echo "Active address: $ACTIVE_ADDR"

# Get gas balance
echo ""
echo "Gas balance:"
sui client gas 2>/dev/null | head -5

# Check if contract objects exist
echo ""
echo "Checking contract objects..."

# Try to get package ID from types.json if it exists
if [ -f "types.json" ]; then
  PACKAGE_ID=$(jq -r '.PACKAGE_ID' types.json 2>/dev/null || echo "unknown")
  echo "Package ID: $PACKAGE_ID"
else
  echo -e "${YELLOW}⚠️  types.json not found${NC}"
fi

echo ""
echo -e "${GREEN}✅ Status check complete${NC}"
