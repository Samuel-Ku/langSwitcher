# LangSwitcher

[English](README.md) | **Українська**

**Конвертер тексту з відкритим кодом, що виправляє неправильну розкладку клавіатури на macOS.**

Набрали текст не в тій розкладці? Виділіть його, натисніть гарячу клавішу — і LangSwitcher миттєво його перетворить. Більше не потрібно нічого перенабирати — більше ніколи не бачите `ghbdtn` замість `привет`.

Відкрита альтернатива [Caramba Switcher](https://caramba-switcher.com/mac) та [Punto Switcher](https://yandex.ru/soft/punto/).

[![Build](https://github.com/reg2005/langSwitcher/actions/workflows/build.yml/badge.svg)](https://github.com/reg2005/langSwitcher/actions/workflows/build.yml)
[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![macOS 13+](https://img.shields.io/badge/macOS-13%2B-brightgreen.svg)](https://www.apple.com/macos/)
[![Swift 5](https://img.shields.io/badge/Swift-5-orange.svg)](https://swift.org/)
[![Mentioned in Awesome](https://awesome.re/mentioned-badge.svg)](https://github.com/jaywcjlove/awesome-mac)

> Якщо LangSwitcher вам корисний, [підтримайте проєкт](#підтримати-проєкт) — будь-який внесок цінується!

**[Документація (EN)](https://reg2005.github.io/langSwitcher/en)** | **[Документація (RU)](https://reg2005.github.io/langSwitcher/ru)**

## Демо

https://github.com/reg2005/langSwitcher/raw/main/screenshots/langSwitch.mp4

## Скриншот

![Налаштування LangSwitcher — вкладка General](screenshots/general.png)

## Ключові можливості

- **Миттєва конвертація тексту** — виділіть текст і натисніть гарячу клавішу, щоб конвертувати його між розкладками
- **Режими розумної конвертації** — працює навіть без ручного виділення тексту:
  - **Жадібний рядок (типово)** — виділяє до початку рядка, знаходить, де починається неправильна розкладка, і конвертує всю фразу, набрану не в тій розкладці
  - **Останнє слово** — автоматично виділяє та конвертує лише останнє набране слово
  - **Вимкнено** — працює лише з явним виділенням тексту
- **Автовизначення** — автоматично визначає, в якій розкладці набрано текст
- **Інтеграція з системними розкладками** — використовує встановлені у системі розкладки клавіатури
- **Гаряча клавіша «подвійний Shift / подвійний Option»** — натисніть `⇧⇧` або `⌥⌥` (модифікатор двічі швидко) для конвертації, або налаштуйте власне сполучення
- **Журнал конвертацій** — опціонально зберігає конвертації в локальну базу SQLite (типово вимкнено заради приватності). Переглядайте записи та оцінюйте їх (правильно/неправильно) для майбутнього навчання ML
- **Експорт JSON** — експорт журналу конвертацій для аналізу даних або навчання моделей
- **Додаток у рядку меню** — тихо живе в рядку стану, завжди готовий до роботи
- **Кілька розкладок** — англійська, російська, українська, польська, німецька, французька, іспанська (8 розкладок)
- **Збереження пунктуації** — `?`, `!`, `/` та інші знаки не змінюються під час конвертації
- **Нуль залежностей** — чистий Swift, без зовнішніх бібліотек і словників
- **Приватність понад усе** — дані не залишають ваш Mac, жодної аналітики, жодного доступу до мережі
- **Відкритий код** — ліцензія MIT, внески вітаються

## Як це працює

```
1. Ви набираєте "ghbdtn" (хотіли "привет", але була активна англійська розкладка)
2. Виділіть текст із помилкою (або просто натисніть гарячу клавішу — Розумна конвертація все зробить сама)
3. Натисніть ⇧⇧ (подвійний Shift) або ⌥⌥ (подвійний Option)
4. Текст замінюється на "привет"
```

LangSwitcher зіставляє символи за **фізичними позиціями клавіш** на клавіатурі. Одна й та сама клавіша дає різні символи залежно від активної розкладки — LangSwitcher обертає це відображення.

## Завантаження

### DMG (рекомендовано)

Перейдіть до [Releases](https://github.com/reg2005/langSwitcher/releases/latest) і завантажте:

| Архітектура | Файл |
|---|---|
| **Apple Silicon (M1/M2/M3/M4)** | `LangSwitcher-*-arm64.dmg` |
| **Intel** | `LangSwitcher-*-x86_64.dmg` |
| **Universal (обидві)** | `LangSwitcher-*-universal.dmg` |

1. Відкрийте DMG і перетягніть **LangSwitcher** до **Програм**
2. Запустіть LangSwitcher
3. Надайте дозвіл **Універсальний доступ**, коли з'явиться запит

### Збірка з вихідного коду

#### Вимоги

- macOS 13.0 (Ventura) або новіша
- Xcode 15.0 або новіший

#### Кроки

```bash
# Клонуйте репозиторій
git clone https://github.com/reg2005/langSwitcher.git
cd langSwitcher

# Запустіть тести
xcodebuild test \
  -project LangSwitcher.xcodeproj \
  -scheme LangSwitcher \
  -destination 'platform=macOS' \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO

# Зберіть (універсальний бінарник)
xcodebuild -project LangSwitcher.xcodeproj \
  -scheme LangSwitcher \
  -configuration Release \
  -derivedDataPath build \
  -arch arm64 -arch x86_64 \
  ONLY_ACTIVE_ARCH=NO \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO \
  build

# Додаток буде в build/Build/Products/Release/LangSwitcher.app
```

Або відкрийте `LangSwitcher.xcodeproj` у Xcode і натисніть `⌘R`.

## Використання

### Базовий процес

1. **Наберіть текст** у будь-якому застосунку
2. **Помітьте**, що була активна не та розкладка
3. **Натисніть** `⇧⇧` (подвійний Shift) або `⌥⌥` (подвійний Option) — Розумна конвертація сама виділить і конвертує
4. Або **виділіть** текст із помилкою вручну, а потім натисніть гарячу клавішу
5. Текст **миттєво конвертується** у правильну розкладку

### Режими розумної конвертації

| Режим | Поведінка |
|-------|-----------|
| **Жадібний рядок** (типово) | Виділяє до початку рядка, знаходить, де починається неправильна розкладка, і конвертує всю фразу з помилками. Обробляє `"ghbdtn rfr ltkf lheu"` -> `"привет как дела друг"` |
| **Останнє слово** | Виділяє лише останнє слово перед курсором і конвертує його, якщо воно виглядає набраним не в тій розкладці |
| **Вимкнено** | Працює лише з явним ручним виділенням тексту |

### Рядок меню

LangSwitcher живе в рядку меню з іконкою клавіатури. Натисніть на неї, щоб:

- Вручну конвертувати виділений текст
- Переглянути активні розкладки
- Переглянути статистику конвертацій
- Відкрити налаштування
- Вийти з додатка

### Налаштування

Відкриваються з іконки в рядку меню -> **Settings** (або `⌘,`):

| Вкладка | Опис |
|---------|------|
| **General** | Запуск при вході, звуки, сповіщення, режим Розумної конвертації, режим перемикання розкладки |
| **Layouts** | Перегляд і оновлення виявлених розкладок |
| **Hotkey** | Виберіть подвійний Shift ⇧⇧, подвійний Option ⌥⌥ або запишіть власне сполучення |
| **Permissions** | Перевірте та надайте доступ Універсального доступу |
| **Log** | Перегляньте історію конвертацій, оцініть записи як правильні/неправильні, експортуйте в JSON |

### Журнал конвертацій

Ведення журналу конвертацій **типово вимкнено** заради вашої приватності. Увімкнути його можна в **Settings -> General -> Conversion Logging**.

Коли журнал увімкнено, конвертації зберігаються в локальну базу SQLite (`~/Library/Application Support/LangSwitcher/conversion_log.sqlite`). Можна налаштувати максимальну кількість записів (типово: 100, або 0 — без обмежень). У вкладці **Log** можна:

- Переглядати всі минулі конвертації (вхід -> вихід, розкладки, режим, час)
- Оцінювати кожну конвертацію як правильну чи неправильну (три стани: без оцінки / правильно / неправильно)
- Експортувати розмічені дані в JSON для ML-навчання або аналізу
- Видаляти окремі записи або очистити весь журнал

**Дані ніколи не залишають ваш Mac.** Журнал конвертацій зберігається суто локально і нікуди не передається.

## Підтримувані розкладки

LangSwitcher визначає розкладки з ваших **Системних параметрів > Клавіатура > Джерела введення**. Наразі підтримуються:

| Розкладка | Код мови | Фізична розкладка |
|-----------|----------|-------------------|
| U.S. (QWERTY) | `en` | QWERTY |
| ABC | `en` | QWERTY |
| Russian | `ru` | ЙЦУКЕН |
| Ukrainian | `uk` | ЙЦУКЕН (українська) |
| Polish | `pl` | QWERTY (Polish Pro) |
| Polish – QWERTZ | `pl` | QWERTZ (Polish) |
| German | `de` | QWERTZ |
| French | `fr` | AZERTY |
| Spanish | `es` | QWERTY (іспанська) |

Додати нову розкладку просто — дивіться [Внесок](#внесок).

## Архітектура

```
LangSwitcher/
├── Sources/
│   ├── App/
│   │   ├── LangSwitcherApp.swift       # Точка входу SwiftUI App
│   │   ├── AppDelegate.swift           # Життєвий цикл, гарячі клавіші, оркестрація
│   │   └── StatusBarController.swift   # Іконка та меню в рядку меню
│   ├── Views/
│   │   ├── SettingsView.swift          # Вікно налаштувань (5 вкладок)
│   │   ├── ConversionLogView.swift     # Журнал конвертацій з розмічуванням
│   │   ├── HotkeyRecorderView.swift    # Записувач власних гарячих клавіш
│   │   ├── AboutView.swift             # Вікно «Про програму»
│   │   └── PermissionsView.swift       # Дозволи Універсального доступу
│   ├── Services/
│   │   ├── LayoutMapper.swift          # Рушій зіставлення символів
│   │   ├── KeyboardLayoutDetector.swift # Визначення системних розкладок (Carbon TIS)
│   │   ├── TextConverter.swift         # Оркестратор конвертації + жадібний алгоритм
│   │   ├── ConversionLogStore.swift    # Сховище журналу на SQLite
│   │   ├── HotkeyManager.swift         # Глобальні гарячі клавіші (подвійне натискання + власні)
│   │   ├── AccessibilityService.swift  # Заміна тексту через буфер обміну
│   │   └── SettingsManager.swift       # Збереження налаштувань у UserDefaults
│   ├── Localization/
│   │   ├── LocalizationManager.swift   # Runtime i18n рушій
│   │   ├── Strings_en.swift            # Англійські рядки (~113 ключів)
│   │   └── Strings_ru.swift            # Російські рядки
│   └── Models/
│       ├── KeyboardLayout.swift        # Модель розкладки та мапи символів
│       └── ConversionLog.swift         # Модель запису журналу
├── Resources/
│   └── Assets.xcassets                 # Іконки та кольори
├── LangSwitcherTests/
│   ├── LayoutMapperTests.swift         # 58 тестів мапінгу
│   └── TextConverterTests.swift        # 35 тестів конвертера
├── .github/workflows/
│   ├── build.yml                       # CI: тести + збірка DMG (Intel/ARM/Universal) + реліз
│   └── pages.yml                       # Розгортання GitHub Pages
├── screenshots/
│   ├── general.png                     # Скриншот вкладки General
│   └── langSwitch.mp4                  # Демо-відео
└── docs/                              # Сайт документації (Docus v4)
    ├── nuxt.config.ts                  # Конфігурація Nuxt/Docus з i18n
    ├── app.config.ts                   # Конфігурація додатка (header, SEO, соцмережі)
    ├── package.json                    # Залежності Docus
    └── content/
        ├── en/                         # Англійська документація
        └── ru/                         # Російська документація
```

### Як працює конвертація

```
Вхід: "ghbdtn" (набрано на розкладці US, коли мала бути російська)

1. Визначаємо вихідну розкладку -> "US" (символи збігаються з мапою US)
2. Для кожного символа знаходимо фізичну позицію клавіші:
   g -> клавіша [0x05]
   h -> клавіша [0x04]
   ...
3. Зіставляємо фізичну клавішу з цільовою розкладкою (російською):
   [0x05] -> п
   [0x04] -> р
   ...
4. Застосовуємо збереження пунктуації (не-буква -> не-буква залишається як є)
5. Результат: "привет"
```

### Ключові рішення дизайну

- **Заміна через буфер обміну**: використовує підхід `⌘C` -> перетворення -> `⌘V` для максимальної сумісності із застосунками. Працює практично в будь-якому текстовому полі.
- **Без CGEvent tap**: уникає `CGEventTap`, який потребує спеціальних entitlements. Замість нього використовує `NSEvent.addGlobalMonitorForEvents` для гарячих клавіш і `CGEvent` з `.hidSystemState` для емуляції клавіатури.
- **Мапінг за фізичними клавішами**: символи зіставляються через фізичну позицію клавіші, а не через таблиці Unicode. Це надійніше для нестандартних розкладок.
- **Без sandbox**: додатку потрібен доступ Універсального доступу, несумісний з App Sandbox.
- **SQLite для журналу**: прямий SQLite3 C API — без зовнішніх залежностей. Дані залишаються локальними заради приватності.
- **Жадібний двопрохідний алгоритм**: прохід 1 перевіряє, чи весь рядок у неправильній розкладці (усі слова змінюють скрипт). Прохід 2 сканує справа наліво для змішаних рядків. Поріг 70% обробляє неоднозначні випадки.

## Технологічний стек

| Компонент | Технологія |
|-----------|------------|
| **Мова** | Swift 5 |
| **UI фреймворк** | SwiftUI |
| **Платформа** | macOS 13+ (Ventura) |
| **Визначення вводу** | Carbon (TISInputSource) |
| **Робота з текстом** | Accessibility API + Pasteboard |
| **Гарячі клавіші** | NSEvent глобальний монітор + CGEvent |
| **Налаштування** | UserDefaults |
| **Журнал конвертацій** | SQLite3 (C API, без залежностей) |
| **Локалізація** | Власний runtime i18n (англійська, російська, польська, українська) |
| **CI/CD** | GitHub Actions |
| **Дистрибуція** | DMG (Intel + ARM + Universal) через GitHub Releases |
| **Вебсайт** | GitHub Pages |
| **Тести** | XCTest (93 тести) |

## Дозволи

LangSwitcher потребує доступ **Універсального доступу** для:
- Зчитування виділеного тексту (через емуляцію `⌘C`)
- Заміни тексту (через емуляцію `⌘V`)

Надайте доступ у **Системні параметри -> Конфіденційність і безпека -> Універсальний доступ**.

Додаток **не**:
- Логує натискання клавіш
- Надсилає дані на сервери — **усі дані залишаються на вашому Mac**
- Звертається до файлів чи мережі
- Працює у фоні після виходу
- Збирає аналітику чи телеметрію

**Журнал конвертацій типово вимкнено.** Якщо ви його увімкнете, усі дані зберігаються локально в `~/Library/Application Support/LangSwitcher/`. Нічого нікуди не завантажується та не передається.

## Внесок

Внески вітаються! Ось як додати нову розкладку клавіатури:

1. Відкрийте `LangSwitcher/Sources/Models/KeyboardLayout.swift`
2. Додайте нову статичну властивість до `LayoutCharacterMap` із мапою символів
3. Додайте шаблон до масиву `allMaps` (**порядок має значення** — специфічні шаблони перед загальними)
4. Додайте тести в `LangSwitcherTests/LayoutMapperTests.swift`
5. Запустіть тести: усі 93+ мають пройти

```swift
// Приклад: додавання італійської розкладки
static let italian: [Character: Character] = {
    let qwerty  = Array("`1234567890-=qwertyuiop[]\\asdfghjkl;'zxcvbnm,./...")
    let italian = Array("\\1234567890'ìqwertyuiopè+ùasdfghjklòàzxcvbnm,.-...")
    var map: [Character: Character] = [:]
    for i in 0..<min(qwerty.count, italian.count) {
        map[qwerty[i]] = italian[i]
    }
    return map
}()
```

### Додавання нової мови (i18n)

LangSwitcher використовує власну систему локалізації — без `.lproj` / `.strings` файлів. Мову можна перемикати під час роботи без перезапуску додатка.

1. **Скопіюйте англійський шаблон**:
   ```bash
   cp LangSwitcher/Sources/Localization/Strings_en.swift \
      LangSwitcher/Sources/Localization/Strings_xx.swift
   ```
   Замініть `xx` на код мови (наприклад, `de`, `fr`, `es`).

2. **Перекладіть** кожне значення в словнику `strings`. Ключі залишаються незмінними — змінюються лише значення.

3. **Оновіть `register()`** унизу нового файлу:
   ```swift
   @MainActor static func register() {
       LocalizationManager.shared.register(language: "xx", strings: strings)
   }
   ```

4. **Зареєструйте новий файл** у `LangSwitcherApp.swift`:
   ```swift
   private func initializeLocalization() {
       Strings_en.register()
       Strings_ru.register()
       Strings_pl.register()
       Strings_ua.register()
       Strings_xx.register()  // <-- додайте це
   }
   ```

5. **Додайте до списку мов** у `LocalizationManager.swift`:
   ```swift
   let availableLanguages: [(code: String, name: String)] = [
       ("en", "English"),
       ("ru", "Русский"),
       ("pl", "Polski"),
       ("ua", "Українська"),
       ("xx", "Ваша мова"),  // <-- додайте це
   ]
   ```

6. **Додайте файл до проєкту Xcode** — додайте `PBXBuildFile`, `PBXFileReference`, додайте до групи Localization та до `PBXSourcesBuildPhase` у `project.pbxproj`. Дотримуйтеся наявного формату PBX ID `E1000001...`.

7. **Запустіть тести** — усі мають пройти.

Ключі рядків використовують префікси просторів імен: `menu.*`, `settings.*`, `general.*`, `smartMode.*`, `layouts.*`, `hotkey.*`, `permissions.*`, `log.*`, `about.*`, `alert.*`, `common.*`.

### Підпис і нотарізація коду (CI/CD)

Релізні збірки можуть бути підписані сертифікатом Apple Developer ID і нотарізовані через GitHub Actions. Без налаштованих секретів збірки використовують ad-hoc підпис (працює для локального використання, але macOS Gatekeeper попереджатиме користувачів).

**Обов'язкові секрети** (Settings > Secrets and variables > Actions):

| Секрет | Опис |
|---|---|
| `MACOS_CERTIFICATE_P12` | Сертифікат Developer ID Application, експортований як `.p12`, потім base64: `base64 -i cert.p12 \| pbcopy` |
| `MACOS_CERTIFICATE_PASSWORD` | Пароль, використаний при експорті `.p12` |
| `MACOS_KEYCHAIN_PASSWORD` | Будь-який випадковий рядок (для тимчасового CI keychain) |
| `MACOS_SIGNING_IDENTITY` | Повний рядок ідентичності, напр. `Developer ID Application: Your Name (TEAMID)` |

**Опціональні секрети** (для нотарізації — рекомендовано для публічного поширення):

| Секрет | Опис |
|---|---|
| `MACOS_NOTARIZATION_APPLE_ID` | Email вашого Apple ID |
| `MACOS_NOTARIZATION_PASSWORD` | Пароль для конкретного застосунку ([appleid.apple.com](https://appleid.apple.com) > Sign-In and Security > App-Specific Password) |
| `MACOS_NOTARIZATION_TEAM_ID` | Ваш 10-символьний Apple Developer Team ID |

**Як отримати сертифікат:**

1. Відкрийте Keychain Access на вашому Mac
2. У зв'язці login знайдіть сертифікат «Developer ID Application»
3. Правий клік > Export Items > збережіть як `.p12` з паролем
4. Закодуйте в base64: `base64 -i DeveloperID.p12 | pbcopy`
5. Вставте результат у секрет `MACOS_CERTIFICATE_P12` на GitHub

**Поведінка:**
- Якщо `MACOS_CERTIFICATE_P12` задано: збірки підписуються вашим Developer ID + hardened runtime
- Якщо секрети нотарізації також задано: DMG надсилаються до Apple для нотарізації та stapling
- Якщо секретів немає: ad-hoc підпис (форки та PR працюють без налаштування)

### Розробка

```bash
# Клонуйте
git clone https://github.com/reg2005/langSwitcher.git
cd langSwitcher

# Запустіть тести (обов'язково після кожної зміни коду)
xcodebuild test \
  -project LangSwitcher.xcodeproj \
  -scheme LangSwitcher \
  -destination 'platform=macOS' \
  CODE_SIGN_IDENTITY="-" \
  CODE_SIGNING_REQUIRED=NO \
  CODE_SIGNING_ALLOWED=NO

# Відкрийте в Xcode
open LangSwitcher.xcodeproj
```

Дивіться [AGENTS.md](AGENTS.md) для настанов щодо AI-агентів і контриб'юторів.

## Підтримати проєкт

LangSwitcher — безкоштовний застосунок з відкритим кодом. Якщо він вам корисний, будь-який внесок вітається та допомагає розвивати проєкт. Дякуємо за підтримку!

| Мережа | Адреса |
|--------|--------|
| **Ethereum** | `0x30c8b011AF68a963694Ce1E5f54A545442acFEfA` |
| **Tron** | `TDAyNkS36eKyqv9s4KQpu4ebWciQ2bqdW3` |
| **Bitcoin** | `bc1qtqm7rgma8dcgqc50lmzmyxn729yqrtf9zs7asx` |
| **Solana** | `A4jzTGxP7tbhyDFrcWJKdsA8v5xUwF6UzvC7RFmDRrfi` |
| **Linea** | `0x30c8b011AF68a963694Ce1E5f54A545442acFEfA` |
| **Base** | `0x30c8b011AF68a963694Ce1E5f54A545442acFEfA` |
| **BNB Chain** | `0x30c8b011AF68a963694Ce1E5f54A545442acFEfA` |
| **Sei** | `0x30c8b011AF68a963694Ce1E5f54A545442acFEfA` |
| **Polygon** | `0x30c8b011AF68a963694Ce1E5f54A545442acFEfA` |
| **OP (Optimism)** | `0x30c8b011AF68a963694Ce1E5f54A545442acFEfA` |
| **Arbitrum** | `0x30c8b011AF68a963694Ce1E5f54A545442acFEfA` |
| **Fantom** | `0x30c8b011AF68a963694Ce1E5f54A545442acFEfA` |

## Ліцензія

[Ліцензія MIT](LICENSE) — безкоштовно для особистого та комерційного використання.

## Подяки

Натхненний [Caramba Switcher](https://caramba-switcher.com/mac) та [Punto Switcher](https://yandex.ru/soft/punto/). Створений як безкоштовна альтернатива з відкритим кодом.
