import Foundation

// MARK: - Ukrainian Strings (Українська)
// Переклад усіх рядків інтерфейсу LangSwitcher українською мовою.

enum Strings_ua {

    static let strings: [String: String] = [

        // ── Меню (StatusBarController) ──────────────────────────────
        "menu.header":                   "⌨ LangSwitcher",
        "menu.convertText":              "Конвертувати текст",
        "menu.activeLayouts":            "Активні розкладки:",
        "menu.conversions":              "Конвертацій:",
        "menu.settings":                 "Налаштування...",
        "menu.about":                    "Про LangSwitcher",
        "menu.quit":                     "Завершити LangSwitcher",
        "menu.tooltip":                  "LangSwitcher — %@ для конвертації",

        // ── Вікно налаштувань ───────────────────────────────────────
        "settings.windowTitle":          "Налаштування LangSwitcher",
        "settings.tab.general":          "Основні",
        "settings.tab.layouts":          "Розкладки",
        "settings.tab.hotkey":           "Гаряча клавіша",
        "settings.tab.permissions":      "Дозволи",
        "settings.tab.log":              "Журнал",

        // ── Вкладка «Основні» ───────────────────────────────────────
        "general.language":              "Мова",
        "general.launchAtLogin":         "Запускати при вході в систему",
        "general.playSound":             "Звук при конвертації",
        "general.showNotifications":     "Показувати повідомлення",
        "general.smartConversion":       "Розумна конвертація (без виділення)",
        "general.autoCorrectOnSpace":      "Автокорекція за пробілом",
        "general.autoCorrectOnSpaceHint":  "Автоматично конвертує останнє слово після натискання пробілу, якщо воно виглядає набраним не в тій розкладці.",
        "general.mode":                  "Режим:",
        "general.layoutSwitch":          "Перемикання розкладки після конвертації",
        "general.howItWorks":            "Як це працює",
        "general.howItWorksText":        "Якщо текст виділено, гаряча клавіша конвертує виділення.\nЯкщо ні — поведінка визначається режимом розумної конвертації вище.",
        "general.statistics":            "Статистика",
        "general.totalConversions":      "Усього конвертацій:",

        // ── Режими розумної конвертації ─────────────────────────────
        "smartMode.lastWord.name":       "Лише останнє слово",
        "smartMode.greedyLine.name":     "Жадібний (уся фраза)",
        "smartMode.disabled.name":       "Вимкнено",
        "smartMode.lastWord.desc":       "Конвертує лише останнє набране слово перед курсором.",
        "smartMode.greedyLine.desc":     "Виділяє текст до початку рядка, знаходить, де починається неправильна розкладка, і конвертує всю фразу.",
        "smartMode.disabled.desc":       "Розумну конвертацію вимкнено. Перед натисканням гарячої клавіші потрібно вручну виділити текст.",

        // ── Режими перемикання розкладки ────────────────────────────
        "layoutSwitchMode.always.name":          "Завжди перемикати розкладку",
        "layoutSwitchMode.ifLastWord.name":      "Перемикати, якщо останнє слово було конвертовано",
        "layoutSwitchMode.ifAnyWord.name":       "Перемикати, якщо будь-яке слово потребувало конвертації",
        "layoutSwitchMode.always.desc":          "Завжди перемикати розкладку клавіатури після натискання гарячої клавіші, незалежно від того, чи було конвертовано текст.",
        "layoutSwitchMode.ifLastWord.desc":      "Перемикати розкладку лише тоді, коли останнє слово перед курсором було набрано не в тій розкладці й було конвертовано.",
        "layoutSwitchMode.ifAnyWord.desc":       "Перемикати розкладку, якщо хоча б одне слово в конвертованому тексті потребувало перетворення.",

        // ── Вкладка «Розкладки» ─────────────────────────────────────
        "layouts.title":                 "Активні розкладки клавіатури",
        "layouts.description":           "Ці розкладки визначено з налаштувань системної клавіатури. Конвертер зіставляє символи між ними за фізичними позиціями клавіш.",
        "layouts.refresh":               "Оновити з системи",
        "layouts.count":                 "Виявлено розкладок: %d",

        // ── Вкладка «Гаряча клавіша» ────────────────────────────────
        "hotkey.title":                  "Сполучення клавіш",
        "hotkey.description":            "Натисніть це сполучення для конвертації тексту. Якщо текст виділено — конвертується виділення; інакше автоматично виділяється останнє слово.",
        "hotkey.current":                "Поточне сполучення:",
        "hotkey.useDoubleShift":         "Подвійне натискання модифікатора",
        "hotkey.doubleShiftMode":        "Подвійний Shift (⇧⇧)",
        "hotkey.doubleOptionMode":       "Подвійний Option (⌥⌥)",
        "hotkey.customMode":             "Власне сполучення",
        "hotkey.doubleShiftHint":        "Швидко натисніть Shift двічі для конвертації. Рекомендоване сполучення — швидке і не конфліктує з іншими застосунками.",
        "hotkey.doubleOptionHint":       "Швидко натисніть Option двічі для конвертації. Сполучення Option+клавіша (⌥+клавіша) ігноруються і не викликають конвертацію.",
        "hotkey.customTitle":            "Власне сполучення",

        // ── Запис гарячої клавіші ───────────────────────────────────
        "hotkeyRecorder.prompt":         "Натисніть «Записати» і наберіть потрібне сполучення клавіш:",
        "hotkeyRecorder.pressKey":       "Натисніть сполучення клавіш...",
        "hotkeyRecorder.cancel":         "Скасувати",
        "hotkeyRecorder.record":         "Записати",

        // ── Вкладка «Дозволи» ───────────────────────────────────────
        "permissions.title":             "Дозволи",
        "permissions.description":       "LangSwitcher потребує доступу до Універсального доступу, щоб читати й замінювати виділений текст в інших застосунках.",
        "permissions.accessibilityTitle":"Універсальний доступ (Accessibility)",
        "permissions.granted":           "Надано — LangSwitcher може конвертувати текст",
        "permissions.notGranted":        "Не надано — увімкніть у Системних параметрах",
        "permissions.inputMonitoringTitle":   "Моніторинг введення",
        "permissions.inputMonitoringGranted": "Надано — гарячі клавіші працюють по всій системі",
        "permissions.inputMonitoringNotGranted": "Не надано — гарячі клавіші можуть не спрацьовувати в інших застосунках",
        "permissions.crossAppTitle":     "Поточний застосунок",
        "permissions.crossAppFrontmost": "Активний застосунок:",
        "permissions.crossAppFull":      "Конвертація в цьому застосунку має працювати",
        "permissions.crossAppLimited":   "У цьому застосунку (наприклад, терміналі) конвертація може працювати обмежено — перевіряйте результат",
        "permissions.grantAccess":       "Надати доступ",
        "permissions.howToEnable":       "Як увімкнути:",
        "permissions.step1":             "1. Відкрийте Системні параметри > Конфіденційність і безпека > Універсальний доступ",
        "permissions.step2":             "2. Натисніть значок замка, щоб внести зміни",
        "permissions.step3":             "3. Увімкніть LangSwitcher у списку",
        "permissions.step4":             "4. За потреби перезапустіть LangSwitcher",
        "permissions.openSettings":      "Відкрити Системні параметри",

        // ── Вкладка «Журнал конвертацій» ────────────────────────────
        "log.title":                     "Журнал конвертацій",
        "log.entries":                   "записів: %d",
        "log.exportJSON":                "Експорт JSON",
        "log.clearAll":                  "Очистити все",
        "log.ratingHint":                "Оцінюйте кожну конвертацію як правильну чи неправильну, щоб збирати навчальні дані. Натискайте: без оцінки -> правильно -> неправильно -> без оцінки.",
        "log.emptyTitle":                "Конвертацій ще немає.",
        "log.emptyHint":                 "Скористайтеся гарячою клавішею для конвертації тексту, і записи з'являться тут.",
        "log.clearConfirmTitle":         "Очистити весь журнал?",
        "log.clearConfirmMessage":       "Усі записи журналу конвертацій буде безповоротно видалено. Цю дію не можна скасувати.",
        "log.cancel":                    "Скасувати",
        "log.deleteEntry":               "Видалити цей запис",
        "log.exportPanelTitle":          "Експорт журналу конвертацій",
        "log.ratingUnrated":             "Без оцінки — натисніть, щоб позначити як правильну",
        "log.ratingCorrect":             "Правильно — натисніть, щоб позначити як неправильну",
        "log.ratingIncorrect":           "Неправильно — натисніть, щоб скинути оцінку",

        // ── Налаштування журналювання (вкладка «Основні») ───────────
        "general.logging":               "Журнал конвертацій",
        "general.loggingEnabled":        "Увімкнути журнал конвертацій",
        "general.loggingDisabledNote":   "Журнал типово вимкнено заради вашої приватності. Після ввімкнення конвертації зберігаються локально на вашому Mac.",
        "general.logMaxEntries":         "Максимум записів у журналі",
        "general.logUnlimited":          "0 = без обмежень",

        // ── Журнал вимкнено (вкладка «Журнал») ──────────────────────
        "log.unlimited":                 "Без обмежень",
        "log.disabledTitle":             "Журнал вимкнено",
        "log.disabledHint":              "Увімкніть журнал вище, щоб почати запис конвертацій.",

        // ── Вікно «Про програму» ────────────────────────────────────
        "about.windowTitle":             "Про програму LangSwitcher",
        "about.appName":                 "LangSwitcher",
        "about.version":                 "Версія 1.0.0",
        "about.tagline":                 "Конвертер тексту між розкладками клавіатури для macOS з відкритим кодом",
        "about.howToUse":                "Як користуватися:",
        "about.step1":                   "Виділіть текст, набраний не в тій розкладці",
        "about.step2":                   "Натисніть ⇧⇧ (подвійний Shift)",
        "about.step3":                   "Текст буде автоматично конвертовано!",
        "about.github":                  "GitHub",
        "about.license":                 "Ліцензія MIT",

        // ── Сповіщення (AppDelegate) ────────────────────────────────
        "alert.accessibilityTitle":      "Потрібен доступ до Універсального доступу",
        "alert.accessibilityMessage":    """
LangSwitcher потрібен дозвіл Універсального доступу, щоб читати й замінювати текст.

Відкрийте Системні параметри → Конфіденційність і безпека → Універсальний доступ і увімкніть LangSwitcher.

Під час запуску з Xcode: додайте зібраний застосунок із DerivedData або сам Xcode.

Якщо дозвіл уже надано, але це не працює:
1. Вилучіть LangSwitcher зі списку Універсального доступу
2. Додайте його знову
3. Перезапустіть застосунок

Також перевірте: Конфіденційність і безпека → Моніторинг введення — LangSwitcher може бути потрібен і там.
""",
        "alert.openSystemSettings":      "Відкрити Системні параметри",
        "alert.continueAnyway":          "Усе одно продовжити",

        // ── Загальне ────────────────────────────────────────────────
        "common.cancel":                 "Скасувати",
    ]

    @MainActor static func register() {
        LocalizationManager.shared.register(language: "ua", strings: strings)
    }
}
