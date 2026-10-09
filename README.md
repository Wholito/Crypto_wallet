# Crypto Wallet

Дипломный проект: некастодиальный криптокошелёк для Android/iOS на Flutter.

Seed phrase и приватный ключ хранятся только на устройстве. Подпись транзакций выполняется локально. Backend не получает секреты кошелька.

## Возможности

- Создание и восстановление кошелька (BIP-39)
- PIN и биометрическая разблокировка
- Шифрование seed (AES-GCM) с ключом из PIN
- Сети: Sepolia (тестнет), Ethereum, Polygon, BNB Chain
- Баланс нативных монет и USDT (BEP-20) на BNB Chain
- Получение (QR) и отправка native / USDT
- Оценка комиссии (EIP-1559), история транзакций
- Светлая / тёмная тема (бело-жёлтая и чёрно-жёлтая)
- Вспомогательный backend (прокси истории, rate limit)

## Стек

| Слой | Технологии |
|------|------------|
| Клиент | Flutter, Dart, Material 3 |
| State / DI | Riverpod |
| Навигация | GoRouter |
| Архитектура | Clean Architecture, feature-first |
| Блокчейн | web3dart, JSON-RPC, ERC-20 |
| Крипто | bip39, bip32, pointycastle, package:crypto |
| Хранение | flutter_secure_storage, Hive |
| Backend | FastAPI, PostgreSQL, Redis, Docker |

Путь деривации EVM: `m/44'/60'/0'/0/0`.

## Структура

```text
lib/
  core/           # тема, роутер, security, константы
  features/       # authentication, wallet, send, receive, ...
  shared/         # общие виджеты и модели
backend/          # FastAPI (опционально)
test/             # unit / widget / integration
```

## Требования

- Flutter SDK (проект на Dart `^3.12.2`)
- Android SDK / эмулятор или устройство
- Для backend: Python 3.11+, Docker (опционально)

## Запуск клиента

```bash
flutter pub get
flutter run
```

Debug на телефоне заметно медленнее. Для проверки UX:

```bash
flutter run --release
```

Сборка APK:

```bash
flutter build apk --debug
# или
flutter build apk --release
```

### Dart-defines (опционально)

```bash
flutter run --dart-define=ETHERSCAN_API_KEY=... --dart-define=BACKEND_URL=https://...
```

## Тесты

```bash
flutter test
flutter analyze
```

Backend:

```bash
cd backend
python -m venv .venv
# Windows: .venv\Scripts\activate
pip install -r requirements.txt
pytest
```

## Backend (опционально)

Backend вспомогательный: кэш/прокси публичных данных, auth для API, rate limiting. Он **не** хранит seed и не подписывает транзакции.

```bash
cd backend
# задайте POSTGRES_PASSWORD и JWT_SECRET
docker compose up --build
```

Локально без Docker — см. `backend/app/config.py` и `requirements.txt`.

## Безопасность

- Seed / private key не уходят на сервер и не пишутся в логи
- Секреты в secure storage (Keystore / Keychain)
- Простые PIN отклоняются при создании (не при входе)
- Автоблокировка сессии, privacy overlay
- Биометрия: флаг + `local_auth` (не жёсткая привязка Keystore user-auth)

## Сети и токены

| Сеть | Chain ID | Заметки |
|------|----------|---------|
| Sepolia | 11155111 | Тестнет по умолчанию |
| Ethereum | 1 | Mainnet |
| Polygon | 137 | Native POL |
| BNB Chain | 56 | Native BNB + USDT |

Комиссия сети всегда в нативной монете (для USDT на BNB нужен небольшой баланс BNB на gas).

## Лицензия

Дипломный учебный проект.
