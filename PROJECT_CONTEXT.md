# PROJECT_CONTEXT.md

## 1. Project

Name: Crypto Wallet
Type: diploma project
Platform: mobile
Framework: Flutter
Language: Dart

The application is a non-custodial cryptocurrency wallet.

Core principle:
- private key and seed phrase remain on the user's device;
- transaction signing happens locally;
- backend must never receive seed phrase or private key.

Main user flow:

Create/Restore Wallet
→ Secure Storage
→ Unlock
→ Home
→ Balance / Assets
→ Receive / Send
→ Transaction History

---

## 2. Goals

MVP:
1. Create wallet.
2. Generate BIP-39 seed phrase.
3. Restore wallet from seed phrase.
4. Securely store wallet secrets.
5. PIN / biometric unlock.
6. Display wallet address.
7. Display native asset balance.
8. Receive cryptocurrency.
9. Generate QR code.
10. Send transaction.
11. Estimate gas.
12. Sign transaction locally.
13. Broadcast transaction.
14. Track transaction status.
15. Transaction history.
16. Testnet support.
17. Unit/widget/integration tests.

After MVP:
- ERC-20 tokens;
- multiple EVM networks;
- market prices;
- portfolio value;
- notifications;
- multiple accounts;
- address book;
- additional UI features.

Do not implement optional features before MVP is stable.

---

## 3. Stack

### Flutter
- Flutter
- Dart
- Material 3
- Riverpod
- GoRouter

### Architecture
- Clean Architecture
- Feature-first structure
- Repository Pattern
- Dependency Injection through Riverpod

Layers:
Presentation → Domain
Data → Domain

Domain must not depend on Flutter UI or concrete API implementations.

### Blockchain
Initial target: EVM-compatible blockchain.

Preferred development target:
- Sepolia testnet

Possible networks later:
- Ethereum
- Polygon
- BNB Chain

Protocols:
- JSON-RPC
- ERC-20
- blockchain explorer/indexer API

Possible providers:
- Alchemy
- Infura
- QuickNode
- Etherscan API

Do not add a provider dependency until the exact implementation requires it.

### Wallet / cryptography
- BIP-39
- BIP-32
- BIP-44
- secp256k1
- Keccak-256

EVM derivation path:
m/44'/60'/0'/0/0

### Security
- flutter_secure_storage
- Android Keystore
- iOS Keychain
- local_auth / biometric authentication

Never store seed phrase or private key in:
- SharedPreferences;
- plain SQLite;
- ordinary unencrypted storage;
- logs;
- backend database.

### Backend
Backend is auxiliary and does not own the wallet.

- Python
- FastAPI
- PostgreSQL
- Redis
- Docker
- Nginx
- JWT if backend authentication is required
- Firebase Cloud Messaging if notifications are implemented

Backend may handle:
- market data;
- API proxy;
- rate limiting;
- notifications;
- user settings;
- cached/public transaction data.

Backend must never receive:
- seed phrase;
- private key;
- decrypted wallet;
- wallet password/PIN.

### Testing
Flutter:
- flutter_test
- integration_test
- mocktail if mocking is needed

Backend:
- pytest

### CI/CD
- Git
- GitHub
- GitHub Actions
- Docker

---

## 4. Project structure

```text
crypto_wallet/
├── android/
├── ios/
├── web/
├── assets/
│   ├── images/
│   ├── icons/
│   └── tokens/
├── lib/
│   ├── main.dart
│   ├── app.dart
│   ├── core/
│   │   ├── constants/
│   │   ├── errors/
│   │   ├── network/
│   │   ├── security/
│   │   ├── storage/
│   │   ├── utils/
│   │   └── router/
│   ├── features/
│   │   ├── onboarding/
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   ├── authentication/
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   ├── wallet/
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   ├── assets/
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   ├── transactions/
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   ├── send/
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   ├── receive/
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   ├── market/
│   │   │   ├── data/
│   │   │   ├── domain/
│   │   │   └── presentation/
│   │   └── settings/
│   │       ├── data/
│   │       ├── domain/
│   │       └── presentation/
│   └── shared/
│       ├── widgets/
│       ├── models/
│       └── extensions/
├── test/
│   ├── unit/
│   ├── widget/
│   └── integration/
├── pubspec.yaml
├── analysis_options.yaml
└── README.md
```

---

## 5. Feature structure

Each feature follows:

```text
feature/
├── data/
│   ├── datasources/
│   ├── models/
│   └── repositories/
├── domain/
│   ├── entities/
│   ├── repositories/
│   └── usecases/
└── presentation/
    ├── providers/
    ├── pages/
    └── widgets/
```

Example wallet:

```text
wallet/
├── data/
│   ├── datasources/
│   │   ├── wallet_local_datasource.dart
│   │   └── blockchain_datasource.dart
│   ├── models/
│   │   └── wallet_model.dart
│   └── repositories/
│       └── wallet_repository_impl.dart
├── domain/
│   ├── entities/
│   │   └── wallet.dart
│   ├── repositories/
│   │   └── wallet_repository.dart
│   └── usecases/
│       ├── create_wallet.dart
│       ├── restore_wallet.dart
│       ├── get_wallet_address.dart
│       └── export_wallet.dart
└── presentation/
    ├── providers/
    │   └── wallet_provider.dart
    ├── pages/
    └── widgets/
```

---

## 6. Entities

### Wallet

```text
id
address
network
createdAt
```

Do not put private key or seed phrase into the normal Wallet UI/domain entity.

### Asset

```text
id
symbol
name
contractAddress
decimals
balance
price
priceChange24h
logo
```

### Transaction

```text
hash
from
to
amount
asset
fee
status
timestamp
type
```

### Network

```text
id
name
chainId
rpcUrl
explorerUrl
nativeCurrency
```

---

## 7. Main use cases

Wallet:
- CreateWallet
- RestoreWallet
- GetWallet
- GetAddress
- ExportWallet
- DeleteWallet

Assets:
- GetAssets
- GetBalance
- GetTokenBalance
- RefreshBalances

Transactions:
- GetTransactions
- GetTransaction
- EstimateGas
- SendTransaction
- TrackTransaction

Receive:
- GetReceiveAddress
- GenerateQrCode

Market:
- GetTokenPrice
- GetMarketData

Settings:
- ChangeNetwork
- ChangeCurrency
- ChangeTheme
- EnableBiometric

---

## 8. Important pipelines

### Create wallet

```text
User
→ Create Wallet
→ cryptographically secure entropy
→ BIP-39 mnemonic
→ mnemonic → seed
→ BIP-32/BIP-44
→ derive account
→ private/public key
→ wallet address
→ show seed phrase
→ backup confirmation
→ encrypt sensitive data
→ Secure Storage
→ Wallet Ready
```

### Restore

```text
User
→ seed phrase
→ validate BIP-39
→ seed
→ derive wallet
→ address
→ encrypt
→ Secure Storage
→ wallet loaded
```

### Balance

```text
UI
→ Riverpod
→ GetBalanceUseCase
→ Repository
→ Blockchain DataSource
→ JSON-RPC
→ blockchain node
→ raw balance
→ convert units
→ entity
→ provider
→ UI
```

### Send

```text
User
→ recipient
→ amount
→ validate address
→ validate amount
→ check balance
→ estimate gas
→ calculate fee
→ confirmation
→ local authentication
→ decrypt private key locally
→ create transaction
→ sign locally
→ send signed raw transaction
→ blockchain RPC
→ transaction hash
→ pending
→ monitor
→ confirmed/failed
→ update history
→ refresh balance
```

Critical rule:

```text
PRIVATE KEY
→ DEVICE ONLY
→ LOCAL SIGNING
→ SIGNED TRANSACTION
→ BLOCKCHAIN
```

### Receive

```text
Receive
→ wallet address
→ QR
→ user shares address
→ external transaction
→ blockchain
→ refresh
→ balance/history
```

### Transaction history

```text
wallet address
→ explorer/indexer API
→ transactions
→ DTO/model
→ repository
→ entity
→ provider
→ UI
```

### Market data

```text
Flutter
→ FastAPI
→ Redis cache
→ market API
→ FastAPI
→ Flutter
```

---

## 9. Security rules

These rules have highest priority.

1. Seed phrase is generated locally.
2. Private key is generated locally.
3. Private key never leaves the device.
4. Seed phrase never leaves the device.
5. Transactions are signed locally.
6. Backend never receives private key.
7. Backend never receives seed phrase.
8. Never print secrets in logs.
9. Never store secrets in ordinary local storage.
10. Do not expose secrets in analytics/crash reports.
11. Show seed phrase only when necessary for backup/restore.
12. Use PIN/biometric authentication for critical operations.
13. Clear sensitive data from memory when practical.

---

## 10. Navigation

```text
/
├── onboarding
│   ├── welcome
│   ├── create-wallet
│   └── restore-wallet
├── auth
│   ├── pin
│   └── biometric
└── wallet
    ├── home
    ├── assets
    ├── asset-details
    ├── send
    ├── receive
    ├── transactions
    ├── transaction-details
    └── settings
```

---

## 11. Startup flow

```text
App start
→ initialize Flutter
→ initialize dependencies
→ initialize secure storage
→ check local wallet
→ wallet exists?
   NO → onboarding
   YES → authentication
→ unlock
→ home
```

---

## 12. Error architecture

```text
DataSource
→ Exception
→ Repository
→ Failure
→ UseCase
→ Provider
→ UI
```

Possible failures:
- NetworkFailure
- WalletFailure
- InvalidAddressFailure
- InsufficientBalanceFailure
- TransactionFailure
- GasEstimationFailure
- AuthenticationFailure
- StorageFailure

UI should show human-readable messages.

---

## 13. Caching

Use local cache for:
- balances;
- transactions;
- asset metadata;
- market data when appropriate.

Secrets are NOT normal cache data.

Possible cache:
- Hive
- Isar
- Drift

Secure Storage remains separate for secrets.

Preferred behavior:

```text
cached data
→ display quickly
→ remote refresh
→ update cache
→ update UI
```

---

## 14. Testing

Unit:
- wallet creation;
- mnemonic validation;
- address generation;
- amount conversion;
- transaction calculation;
- gas calculation;
- repositories;
- use cases;
- validators.

Widget:
- onboarding;
- wallet;
- send;
- receive;
- transactions;
- settings.

Integration:
- create wallet;
- unlock;
- view balance;
- receive;
- send;
- transaction history.

Use testnet for blockchain integration tests.

---

## 15. Git

Branches:

```text
main
develop
feature/*
```

Examples:

```text
feature/wallet
feature/send
feature/transactions
feature/market
feature/auth
```

Commit style:

```text
feat: add wallet generation
feat: implement transaction history
fix: handle insufficient balance
refactor: separate blockchain repository
test: add wallet use case tests
```

---

## 16. Development priority

Always follow:

1. Correctness
2. Security
3. Compatibility with existing architecture
4. Testability
5. Readability
6. Optimization
7. Optional features

MVP before extras.

---

## 17. Agent working rules

This section is specifically for AI agents working on the project.

### Token efficiency

The agent MUST minimize unnecessary token usage.

Rules:
- Do not repeat project context.
- Do not explain architecture unless asked.
- Do not output unchanged code.
- Do not output entire files for small changes.
- Do not generate long introductions.
- Do not provide multiple solutions unless there is a meaningful architectural/security tradeoff.
- Do not rewrite working code.
- Do not refactor unrelated code.
- Do not implement future features automatically.
- Do not create unnecessary abstractions.
- Do not add dependencies without a concrete need.
- Inspect the existing project before making assumptions.
- Reuse existing code whenever possible.
- Keep responses concise.

### Code changes

For a normal task:

```text
1. Inspect relevant files.
2. Identify the smallest correct change.
3. Implement only that change.
4. Check affected dependencies.
5. Run only relevant tests/analyze checks.
6. Report briefly.
```

Do not print full files unless:
- explicitly requested;
- the file is very small;
- a full file is necessary to avoid ambiguity.

Prefer:
- exact file path;
- exact class/method;
- minimal patch/change;
- short explanation.

### Scope control

If asked to implement one feature:
- implement that feature only;
- do not implement the next features;
- do not redesign the architecture;
- do not add unrelated improvements.

### Questions

Before asking the user:
1. inspect available files;
2. inspect current implementation;
3. infer from existing conventions.

Ask only if the missing information genuinely blocks implementation.

Ask one focused question at a time.

### Existing code is the source of truth

Do not assume that the project exactly matches this document.

Priority:

```text
actual project code
>
current user instruction
>
PROJECT_CONTEXT.md
>
general assumptions
```

If the actual project differs from this document, preserve the working project unless the user explicitly asks to change it.

### Security

Never weaken wallet security to make implementation easier.

If a requested implementation would expose seed/private key:
- do not implement the insecure approach;
- use a secure local alternative.

### Response format

Default response:

```text
DONE:
- short description

CHANGED:
- path/file.dart — short description
- path/file.dart — short description

IMPORTANT:
- only if necessary

NEXT:
- one logical next step
```

If the user asks for code only, provide only the necessary code.

If the task is trivial, use an even shorter response.

### Development loop

Use:

```text
TASK
→ INSPECT
→ MINIMAL CHANGE
→ VERIFY
→ SHORT REPORT
```

Do not automatically continue to the next task.

---

## 18. Current project status

Update this section during development.

```text
STATUS: MVP IMPLEMENTED

Completed:
- MVP features: create/restore wallet, PIN/biometric unlock, balance, receive/QR, send with local signing, history, pending/confirmed tracking, settings, network switch
- market prices via backend, FastAPI backend (backend/), GitHub Actions workflows
- flutter analyze clean, flutter test 41 passed, backend pytest 10 passed
- project concept defined
- architecture defined
- stack defined
- security principles defined
- MVP defined
- Flutter project created in repo root (android, ios)
- dependencies configured (riverpod, go_router, secure storage, local_auth, bip39, bip32, web3dart, http, hive, qr_flutter, equatable, mocktail, integration_test)
- feature-first folder skeleton created
- base app, router (placeholder pages), Failure classes

Current task:
- none

Next:
- manual testnet run on device (Sepolia faucet → send)
- optional: ERC-20, multiple accounts, address book
```

When the agent completes a task, update only the relevant status information.

---

## 19. MVP demonstration scenario

The final diploma demonstration should be:

```text
Create Wallet
→ Backup Seed Phrase
→ Unlock Wallet
→ Show Receive Address
→ Receive Testnet Funds
→ Balance Appears
→ Enter Recipient
→ Enter Amount
→ Estimate Fee
→ Confirm
→ Local Transaction Signing
→ Broadcast
→ Blockchain Confirmation
→ Transaction History
→ Updated Balance
```

This is the primary end-to-end acceptance scenario.
