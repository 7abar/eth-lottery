# eth-lottery

> Trustless, on-chain lottery on Base. 0.001 ETH per ticket. 7-day rounds. Winner takes 90%.

No backend. No admin panel. No shady randomness server. Just a smart contract running on Ethereum.

## How It Works

1. **Buy tickets** — 0.001 ETH each, any amount
2. **Wait 7 days** — round closes automatically
3. **Owner draws** — winner selected via block hash pseudo-randomness
4. **Winner gets 90%** — 10% goes to the house (deployer)
5. **New round starts automatically**

## Deploy

```bash
forge install foundry-rs/forge-std
forge build

forge script script/Deploy.s.sol --rpc-url https://mainnet.base.org --broadcast --private-key $PK
```

## Buy a Ticket

```bash
# Buy 1 ticket
cast send $CONTRACT "buyTickets(uint256)" 1 \
  --value 0.001ether \
  --rpc-url https://mainnet.base.org \
  --private-key $PK

# Buy 5 tickets
cast send $CONTRACT "buyTickets(uint256)" 5 \
  --value 0.005ether \
  --rpc-url https://mainnet.base.org \
  --private-key $PK
```

## Draw Winner (Owner Only)

```bash
cast send $CONTRACT "drawWinner()" \
  --rpc-url https://mainnet.base.org \
  --private-key $OWNER_PK
```

## Read State

```bash
# Get current round info
cast call $CONTRACT "getCurrentRound()" --rpc-url https://mainnet.base.org

# Check your ticket count
cast call $CONTRACT "ticketsByRound(uint256,address)" 0 $YOUR_ADDRESS --rpc-url https://mainnet.base.org

# Get participants in a round
cast call $CONTRACT "getParticipants(uint256)" 0 --rpc-url https://mainnet.base.org

# Total rounds played
cast call $CONTRACT "totalRounds()" --rpc-url https://mainnet.base.org
```

## Test

```bash
forge test -vv
```

## Contract

| Function | Access | Description |
|---|---|---|
| `buyTickets(count)` | Anyone | Buy N tickets for 0.001 ETH each |
| `drawWinner()` | Owner | Draw winner after 7 days |
| `getCurrentRound()` | View | Current round state |
| `getRound(id)` | View | Historical round data |
| `getParticipants(roundId)` | View | All participants in a round |

## ⚠️ Randomness Warning

> ⚠️ Uses block hash for randomness. Fine for low-stakes fun, not suitable for high-value draws.

Block hash randomness can be influenced by miners/validators on high-value pots. For serious money, use Chainlink VRF.

---

> *The house always wins... 10% of it anyway.*
