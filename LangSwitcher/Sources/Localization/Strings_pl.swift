import Foundation

// MARK: - Polish Strings (Polski)
// Tłumaczenie wszystkich ciągów interfejsu LangSwitcher na język polski.

enum Strings_pl {

    static let strings: [String: String] = [

        // ── Menu (StatusBarController) ──────────────────────────────
        "menu.header":                   "⌨ LangSwitcher",
        "menu.convertText":              "Konwertuj tekst",
        "menu.activeLayouts":            "Aktywne układy:",
        "menu.conversions":              "Konwersje:",
        "menu.settings":                 "Ustawienia...",
        "menu.about":                    "O LangSwitcher",
        "menu.quit":                     "Zakończ LangSwitcher",
        "menu.tooltip":                  "LangSwitcher — %@, aby konwertować",

        // ── Okno ustawień ───────────────────────────────────────────
        "settings.windowTitle":          "Ustawienia LangSwitcher",
        "settings.tab.general":          "Ogólne",
        "settings.tab.layouts":          "Układy",
        "settings.tab.hotkey":           "Skrót",
        "settings.tab.permissions":      "Uprawnienia",
        "settings.tab.log":              "Dziennik",

        // ── Karta „Ogólne" ──────────────────────────────────────────
        "general.language":              "Język",
        "general.launchAtLogin":         "Uruchamiaj przy logowaniu",
        "general.playSound":             "Dźwięk przy konwersji",
        "general.showNotifications":     "Pokazuj powiadomienia",
        "general.smartConversion":       "Inteligentna konwersja (bez zaznaczenia)",
        "general.autoCorrectOnSpace":      "Autokorekta przy spacji",
        "general.autoCorrectOnSpaceHint":  "Automatycznie konwertuje ostatnie słowo po naciśnięciu spacji, jeśli wygląda na wpisane w niewłaściwym układzie.",
        "general.mode":                  "Tryb:",
        "general.layoutSwitch":          "Zmiana układu po konwersji",
        "general.howItWorks":            "Jak to działa",
        "general.howItWorksText":        "Jeśli tekst jest zaznaczony, skrót konwertuje zaznaczenie.\nJeśli nie, działanie zależy od trybu inteligentnej konwersji powyżej.",
        "general.statistics":            "Statystyki",
        "general.totalConversions":      "Wszystkich konwersji:",

        // ── Tryby inteligentnej konwersji ───────────────────────────
        "smartMode.lastWord.name":       "Tylko ostatnie słowo",
        "smartMode.greedyLine.name":     "Zachłanny (cała fraza)",
        "smartMode.disabled.name":       "Wyłączony",
        "smartMode.lastWord.desc":       "Konwertuje tylko ostatnie wpisane słowo przed kursorem.",
        "smartMode.greedyLine.desc":     "Zaznacza tekst do początku wiersza, znajduje, gdzie zaczyna się niewłaściwy układ, i konwertuje całą frazę.",
        "smartMode.disabled.desc":       "Inteligentna konwersja jest wyłączona. Przed naciśnięciem skrótu należy ręcznie zaznaczyć tekst.",

        // ── Tryby zmiany układu ─────────────────────────────────────
        "layoutSwitchMode.always.name":          "Zawsze zmieniaj układ",
        "layoutSwitchMode.ifLastWord.name":      "Zmień, jeśli ostatnie słowo zostało skonwertowane",
        "layoutSwitchMode.ifAnyWord.name":       "Zmień, jeśli dowolne słowo wymagało konwersji",
        "layoutSwitchMode.always.desc":          "Zawsze zmienia układ klawiatury po naciśnięciu skrótu, niezależnie od tego, czy tekst został skonwertowany.",
        "layoutSwitchMode.ifLastWord.desc":      "Zmienia układ tylko wtedy, gdy ostatnie słowo przed kursorem było wpisane w niewłaściwym układzie i zostało skonwertowane.",
        "layoutSwitchMode.ifAnyWord.desc":       "Zmienia układ, jeśli dowolne słowo w skonwertowanym tekście wymagało konwersji.",

        // ── Karta „Układy" ──────────────────────────────────────────
        "layouts.title":                 "Aktywne układy klawiatury",
        "layouts.description":           "Te układy są wykrywane z ustawień klawiatury systemu. Konwerter mapuje znaki między nimi na podstawie fizycznych pozycji klawiszy.",
        "layouts.refresh":               "Odśwież z systemu",
        "layouts.count":                 "Wykryto układów: %d",

        // ── Karta „Skrót" ───────────────────────────────────────────
        "hotkey.title":                  "Skrót klawiszowy",
        "hotkey.description":            "Naciśnij ten skrót, aby skonwertować tekst. Jeśli tekst jest zaznaczony — konwertowane jest zaznaczenie; w przeciwnym razie automatycznie zaznaczane jest ostatnie słowo.",
        "hotkey.current":                "Bieżący skrót:",
        "hotkey.useDoubleShift":         "Dwukrotne naciśnięcie modyfikatora",
        "hotkey.doubleShiftMode":        "Podwójny Shift (⇧⇧)",
        "hotkey.doubleOptionMode":       "Podwójny Option (⌥⌥)",
        "hotkey.customMode":             "Własny skrót",
        "hotkey.doubleShiftHint":        "Szybko naciśnij Shift dwukrotnie, aby skonwertować. To zalecany skrót — szybki i nie koliduje z innymi aplikacjami.",
        "hotkey.doubleOptionHint":       "Szybko naciśnij Option dwukrotnie, aby skonwertować. Skróty Option+klawisz (⌥+klawisz) są ignorowane i nie wywołują konwersji.",
        "hotkey.customTitle":            "Własny skrót",

        // ── Nagrywanie skrótu ───────────────────────────────────────
        "hotkeyRecorder.prompt":         "Kliknij „Nagraj” i naciśnij żądane połączenie klawiszy:",
        "hotkeyRecorder.pressKey":       "Naciśnij połączenie klawiszy...",
        "hotkeyRecorder.cancel":         "Anuluj",
        "hotkeyRecorder.record":         "Nagraj",

        // ── Karta „Uprawnienia" ─────────────────────────────────────
        "permissions.title":             "Uprawnienia",
        "permissions.description":       "LangSwitcher potrzebuje dostępu do funkcji ułatwień dostępności, aby odczytywać i zastępować zaznaczony tekst w innych aplikacjach.",
        "permissions.accessibilityTitle":"Dostępność (Accessibility)",
        "permissions.granted":           "Przyznane — LangSwitcher może konwertować tekst",
        "permissions.notGranted":        "Nieprzyznane — włącz w Ustawieniach systemowych",
        "permissions.inputMonitoringTitle":   "Monitorowanie wejścia",
        "permissions.inputMonitoringGranted": "Przyznane — skróty działają w całym systemie",
        "permissions.inputMonitoringNotGranted": "Nieprzyznane — skróty mogą nie działać w innych aplikacjach",
        "permissions.crossAppTitle":     "Bieżąca aplikacja",
        "permissions.crossAppFrontmost": "Aktywna aplikacja:",
        "permissions.crossAppFull":      "Konwersja w tej aplikacji powinna działać",
        "permissions.crossAppLimited":   "W tej aplikacji (np. terminalu) konwersja może działać ograniczenie — sprawdzaj wynik",
        "permissions.grantAccess":       "Przyznaj dostęp",
        "permissions.howToEnable":       "Jak włączyć:",
        "permissions.step1":             "1. Otwórz Ustawienia systemowe > Prywatność i bezpieczeństwo > Dostępność",
        "permissions.step2":             "2. Kliknij ikonę kłódki, aby wprowadzić zmiany",
        "permissions.step3":             "3. Włącz LangSwitcher na liście",
        "permissions.step4":             "4. W razie potrzeby uruchom ponownie LangSwitcher",
        "permissions.openSettings":      "Otwórz Ustawienia systemowe",

        // ── Karta „Dziennik konwersji" ──────────────────────────────
        "log.title":                     "Dziennik konwersji",
        "log.entries":                   "wpisów: %d",
        "log.exportJSON":                "Eksport JSON",
        "log.clearAll":                  "Wyczyść wszystko",
        "log.ratingHint":                "Oceniaj każdą konwersję jako poprawną lub niepoprawną, aby budować dane treningowe. Klikaj: bez oceny -> poprawna -> niepoprawna -> bez oceny.",
        "log.emptyTitle":                "Brak konwersji w dzienniku.",
        "log.emptyHint":                 "Użyj skrótu, aby skonwertować tekst, a wpisy pojawią się tutaj.",
        "log.clearConfirmTitle":         "Wyczyścić cały dziennik?",
        "log.clearConfirmMessage":       "Wszystkie wpisy dziennika konwersji zostaną trwale usunięte. Tej operacji nie można cofnąć.",
        "log.cancel":                    "Anuluj",
        "log.deleteEntry":               "Usuń ten wpis",
        "log.exportPanelTitle":          "Eksport dziennika konwersji",
        "log.ratingUnrated":             "Bez oceny — kliknij, aby oznaczyć jako poprawną",
        "log.ratingCorrect":             "Poprawna — kliknij, aby oznaczyć jako niepoprawną",
        "log.ratingIncorrect":           "Niepoprawna — kliknij, aby wyczyścić ocenę",

        // ── Ustawienia dziennika (karta „Ogólne") ───────────────────
        "general.logging":               "Dziennik konwersji",
        "general.loggingEnabled":        "Włącz dziennik konwersji",
        "general.loggingDisabledNote":   "Dziennik jest domyślnie wyłączony dla Twojej prywatności. Po włączeniu konwersje są zapisywane lokalnie na Twoim Macu.",
        "general.logMaxEntries":         "Maksymalna liczba wpisów",
        "general.logUnlimited":          "0 = bez limitu",

        // ── Dziennik wyłączony (karta „Dziennik") ───────────────────
        "log.unlimited":                 "Bez limitu",
        "log.disabledTitle":             "Dziennik jest wyłączony",
        "log.disabledHint":              "Włącz dziennik powyżej, aby rozpocząć rejestrowanie konwersji.",

        // ── Okno „O programie" ──────────────────────────────────────
        "about.windowTitle":             "O programie LangSwitcher",
        "about.appName":                 "LangSwitcher",
        "about.version":                 "Wersja 1.0.0",
        "about.tagline":                 "Konwerter tekstu między układami klawiatury dla macOS o otwartym kodzie",
        "about.howToUse":                "Jak używać:",
        "about.step1":                   "Zaznacz tekst wpisany w niewłaściwym układzie",
        "about.step2":                   "Naciśnij ⇧⇧ (podwójny Shift)",
        "about.step3":                   "Tekst zostanie automatycznie skonwertowany!",
        "about.github":                  "GitHub",
        "about.license":                 "Licencja MIT",

        // ── Alerty (AppDelegate) ────────────────────────────────────
        "alert.accessibilityTitle":      "Wymagany dostęp do funkcji ułatwień dostępności",
        "alert.accessibilityMessage":    """
LangSwitcher potrzebuje uprawnienia Dostępność, aby odczytywać i zastępować tekst.

Otwórz Ustawienia systemowe → Prywatność i bezpieczeństwo → Dostępność i włącz LangSwitcher.

Przy uruchamianiu z Xcode: dodaj zbudowaną aplikację z DerivedData lub samego Xcode.

Jeśli uprawnienie zostało już nadane, ale nadal nie działa:
1. Usuń LangSwitcher z listy Dostępność
2. Dodaj go ponownie
3. Uruchom ponownie aplikację

Sprawdź też: Prywatność i bezpieczeństwo → Monitorowanie wejścia — LangSwitcher może być tam również potrzebny.
""",
        "alert.openSystemSettings":      "Otwórz Ustawienia systemowe",
        "alert.continueAnyway":          "Kontynuuj mimo to",

        // ── Wspólne ─────────────────────────────────────────────────
        "common.cancel":                 "Anuluj",
    ]

    @MainActor static func register() {
        LocalizationManager.shared.register(language: "pl", strings: strings)
    }
}
