# PERSONAL TEST: CATEGORY SPEED 4 - true single-pass category planner/writer
# PERSONAL TEST: CATEGORY SPEED 3 - surgical changed-entry writes for category UPDATE mode
# PERSONAL TEST: CATEGORY SPEED 2 - skip redundant fleet-scope scans during category batches
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
Add-Type -AssemblyName System.IO.Compression
Add-Type -AssemblyName System.IO.Compression.FileSystem

[System.Windows.Forms.Application]::EnableVisualStyles()

$script:AppName = 'WL Simplistic SnowRunner Mod Editor v1.2.0L'
$script:AppRoot = if ($env:WL_SSME_ROOT) { $env:WL_SSME_ROOT } else { $PSScriptRoot }
$script:SettingsPath = Join-Path $script:AppRoot 'WL-Settings.json'
$script:Fields = @{}
$script:Combos = @{}
$script:Checks = @{}
$script:UpdateDetected = $false
$script:TruckTargets = @{}
$script:wlDamageCapHits = 0
$script:wlDamageMultHits = 0
$script:AllModsPreviewLabel = '[MOD] Compatibility Scan - PREVIEW ONLY'
$script:RefreshingTruckTargets = $false

$script:LanguagePath = Join-Path $script:AppRoot 'WL-Language.txt'
$script:Language = 'en-US'
$script:Translations = @{}
# RC10: Localize the All Trucks display entry while preserving the canonical internal All Trucks token.
# RC5: Full main-interface localization for all advertised languages.
# RC9: final scan-button width cleanup for long Russian/Ukrainian labels; editing engine remains unchanged.
# RC6: multilingual layout widened for long translated labels/buttons; editing engine remains unchanged.
# RC4: Localization literals use double-quoted PowerShell strings so apostrophes and ampersands cannot break parsing.
$script:Translations["ru-RU"] = @{
    "All Trucks"="Все грузовики"
    "Select initial.pak to scan trucks"="Выберите initial.pak для сканирования грузовиков"
'Game file'='Файл игры'; 'Browse...'='Обзор...'; 'Truck target'='Выбор грузовика'; 'Scan Trucks'='Сканировать грузовики'; 'Scan Mods'='Сканировать моды'
'POWER & FUEL'='МОЩНОСТЬ И ТОПЛИВО'; 'Engine torque'='Крутящий момент двигателя'; 'Engine responsiveness'='Отклик двигателя'; 'Engine fuel consumption'='Расход топлива двигателя'; 'Truck fuel capacity'='Объём топливного бака'; 'Maximum steering angle'='Макс. угол поворота'; 'Steering response'='Скорость рулевого управления'
'GEARBOX'='КОРОБКА ПЕРЕДАЧ'; 'Gearbox fuel consumption'='Расход топлива КПП'; 'AWD fuel penalty'='Расход топлива полного привода'; 'Idle fuel use'='Расход топлива на холостом ходу'; 'Always AWD'='Постоянный полный привод'; 'Always differential lock (unchecked = default)'='Постоянная блокировка дифференциала (снято = по умолчанию)'; 'Extreme durability (GLOBAL)'='Экстремальная прочность (ГЛОБАЛЬНО)'
'TIRES'='ШИНЫ'; 'Tire asphalt grip'='Сцепление шин с асфальтом'; 'Tire off-road grip'='Сцепление шин на бездорожье'; 'Tire mud grip'='Сцепление шин в грязи'; 'All tires ignore ice'='Все шины игнорируют лёд'
'SUSPENSION'='ПОДВЕСКА'; 'Suspension strength'='Жёсткость подвески'; 'Suspension height'='Высота подвески'; 'Suspension damping'='Демпфирование подвески'; 'Suspension durability'='Прочность подвески'
'RECOVERY & CRANES'='ЭВАКУАЦИЯ И КРАНЫ'; 'Winch strength'='Мощность лебёдки'; 'Winch length'='Длина лебёдки'; 'Crane strength'='Мощность крана'; 'Crane speed'='Скорость крана'; 'Autonomous winches'='Автономные лебёдки'
'TRUCK ACCESS'='ДОСТУП К ГРУЗОВИКАМ'; 'Unlock all trucks'='Разблокировать все грузовики'; 'All trucks in all regions'='Все грузовики во всех регионах'
'MORE PERFORMANCE & DURABILITY'='ДОП. МОЩНОСТЬ И ПРОЧНОСТЬ'; 'Gear tuning'='Настройка передач'; 'Engine durability'='Прочность двигателя'; 'Gearbox durability'='Прочность КПП'; 'Tire durability'='Прочность шин'; 'Fuel tank durability'='Прочность топливного бака'
'SERVICE & CARGO'='СЕРВИС И ГРУЗ'; 'Service fuel capacity'='Запас сервисного топлива'; 'Service water capacity'='Запас воды'; 'Service repair points'='Очки ремонта'; 'Service spare wheels'='Запасные колёса'; 'Cargo mass'='Масса груза'
'ECONOMY & UPGRADES'='ЭКОНОМИКА И УЛУЧШЕНИЯ'; 'Truck prices'='Цены грузовиков'; 'Upgrade/addon prices'='Цены улучшений/аддонов'; 'Unlock all upgrades/addons'='Разблокировать все улучшения/аддоны'
'STABILITY'='УСТОЙЧИВОСТЬ'; 'Truck center-of-gravity drop'='Понижение центра тяжести грузовика'; 'Addon/trailer center-of-gravity drop'='Понижение центра тяжести аддона/прицепа'
'QUICK PRESETS'='БЫСТРЫЕ ПРЕСЕТЫ'; 'Vanilla / Reset'='Стандарт / Сброс'; 'Enhanced'='Улучшенный'; 'Overpowered'='Сверхмощный'; 'Your last applied values are saved automatically.'='Последние применённые значения сохраняются автоматически.'
'Preview Changes'='Предпросмотр изменений'; 'Restore Original'='Восстановить оригинал'; 'Check for Updates'='Проверить обновления'; 'APPLY MODS'='ПРИМЕНИТЬ МОДЫ'; 'Ready.'='Готово.'
"Global adjustments use the clean baseline; individual truck applies accumulate until Restore Original"="Глобальные изменения используют чистую базу; изменения отдельных грузовиков накапливаются до восстановления оригинала"
"1.00 = original value   |   1.50 = +50%   |   0.50 = half"="1.00 = исходное значение   |   1.50 = +50%   |   0.50 = половина"
'All Trucks - full global adjustment mode'='Все грузовики — полный глобальный режим'; 'Individual official truck - shared component scope is reported in Preview'='Отдельный официальный грузовик — общие компоненты показаны в предпросмотре'; 'Third-party mod truck - protected per-mod Preview / Apply'='Сторонний мод-грузовик — защищённые предпросмотр / применение'; 'Mod compatibility scan - Preview only; batch Apply disabled'='Проверка совместимости модов — только предпросмотр; пакетное применение отключено'
    "Language"="Язык"
    "Checking updates..."="Проверка обновлений..."
    "Language saved. Restart the editor to apply the interface translation."="Язык сохранён. Перезапустите редактор, чтобы применить перевод интерфейса."
    "Stock"="Стандарт"
    "Mild"="Умеренный"
    "Performance"="Производительность"
    "High Performance"="Высокая производительность"
    "Extreme"="Экстремальный"

}
$script:Translations["de-DE"] = @{
    "All Trucks"="Alle Lkw"
    "Select initial.pak to scan trucks"="Wählen Sie initial.pak, um Lkw zu scannen"
    "Language"="Sprache"
    "Game file"="Spieldatei"
    "Browse..."="Durchsuchen..."
    "Truck target"="Lkw-Ziel"
    "Scan Trucks"="Lkw scannen"
    "Scan Mods"="Mods scannen"
    "POWER & FUEL"="LEISTUNG & KRAFTSTOFF"
    "Engine torque"="Motordrehmoment"
    "Engine responsiveness"="Motoransprechverhalten"
    "Engine fuel consumption"="Motorverbrauch"
    "Truck fuel capacity"="Kraftstofftank"
    "Maximum steering angle"="Maximaler Lenkwinkel"
    "Steering response"="Lenkansprechen"
    "GEARBOX"="GETRIEBE"
    "Gearbox fuel consumption"="Getriebeverbrauch"
    "AWD fuel penalty"="AWD-Verbrauchsnachteil"
    "Idle fuel use"="Leerlaufverbrauch"
    "Always AWD"="Permanenter AWD"
    "Always differential lock (unchecked = default)"="Permanente Differenzialsperre (deaktiviert = Standard)"
    "Extreme durability (GLOBAL)"="Extreme Haltbarkeit (GLOBAL)"
    "TIRES"="REIFEN"
    "Tire asphalt grip"="Asphalt-Grip"
    "Tire off-road grip"="Offroad-Grip"
    "Tire mud grip"="Schlamm-Grip"
    "All tires ignore ice"="Alle Reifen ignorieren Eis"
    "SUSPENSION"="FEDERUNG"
    "Suspension strength"="Federungsstärke"
    "Suspension height"="Federungshöhe"
    "Suspension damping"="Federungsdämpfung"
    "Suspension durability"="Federungshaltbarkeit"
    "RECOVERY & CRANES"="BERGUNG & KRÄNE"
    "Winch strength"="Windenstärke"
    "Winch length"="Windenlänge"
    "Crane strength"="Kranstärke"
    "Crane speed"="Krangeschwindigkeit"
    "Autonomous winches"="Autonome Winden"
    "TRUCK ACCESS"="LKW-ZUGANG"
    "Unlock all trucks"="Alle Lkw freischalten"
    "All trucks in all regions"="Alle Lkw in allen Regionen"
    "MORE PERFORMANCE & DURABILITY"="MEHR LEISTUNG & HALTBARKEIT"
    "Gear tuning"="Getriebeabstimmung"
    "Engine durability"="Motorhaltbarkeit"
    "Gearbox durability"="Getriebehaltbarkeit"
    "Tire durability"="Reifenhaltbarkeit"
    "Fuel tank durability"="Tankhaltbarkeit"
    "SERVICE & CARGO"="SERVICE & LADUNG"
    "Service fuel capacity"="Service-Kraftstoffkapazität"
    "Service water capacity"="Service-Wasserkapazität"
    "Service repair points"="Reparaturpunkte"
    "Service spare wheels"="Ersatzräder"
    "Cargo mass"="Ladungsmasse"
    "ECONOMY & UPGRADES"="WIRTSCHAFT & UPGRADES"
    "Truck prices"="Lkw-Preise"
    "Upgrade/addon prices"="Upgrade-/Addon-Preise"
    "Unlock all upgrades/addons"="Alle Upgrades/Addons freischalten"
    "STABILITY"="STABILITÄT"
    "Truck center-of-gravity drop"="Lkw-Schwerpunkt absenken"
    "Addon/trailer center-of-gravity drop"="Addon-/Anhänger-Schwerpunkt absenken"
    "QUICK PRESETS"="SCHNELLE VOREINSTELLUNGEN"
    "Vanilla / Reset"="Standard / Zurücksetzen"
    "Enhanced"="Verbessert"
    "Overpowered"="Übermächtig"
    "Your last applied values are saved automatically."="Zuletzt angewendete Werte werden automatisch gespeichert."
    "Preview Changes"="Änderungen anzeigen"
    "Restore Original"="Original wiederherstellen"
    "Check for Updates"="Nach Updates suchen"
    "APPLY MODS"="MODS ANWENDEN"
    "Ready."="Bereit."
    "Checking updates..."="Suche nach Updates..."
    "Language saved. Restart the editor to apply the interface translation."="Sprache gespeichert. Starten Sie den Editor neu, um die Übersetzung anzuwenden."
    "Stock"="Standard"
    "Mild"="Mild"
    "Performance"="Leistung"
    "High Performance"="Hohe Leistung"
    "Extreme"="Extrem"
}
$script:Translations["fr-FR"] = @{
    "All Trucks"="Tous les camions"
    "Select initial.pak to scan trucks"="Sélectionnez initial.pak pour analyser les camions"
    "Language"="Langue"
    "Game file"="Fichier du jeu"
    "Browse..."="Parcourir..."
    "Truck target"="Camion cible"
    "Scan Trucks"="Analyser les camions"
    "Scan Mods"="Analyser les mods"
    "POWER & FUEL"="PUISSANCE & CARBURANT"
    "Engine torque"="Couple moteur"
    "Engine responsiveness"="Réactivité du moteur"
    "Engine fuel consumption"="Consommation moteur"
    "Truck fuel capacity"="Capacité du réservoir"
    "Maximum steering angle"="Angle de braquage maximal"
    "Steering response"="Réactivité de la direction"
    "GEARBOX"="BOÎTE DE VITESSES"
    "Gearbox fuel consumption"="Consommation de la boîte"
    "AWD fuel penalty"="Pénalité carburant AWD"
    "Idle fuel use"="Consommation au ralenti"
    "Always AWD"="AWD permanent"
    "Always differential lock (unchecked = default)"="Blocage de différentiel permanent (décoché = défaut)"
    "Extreme durability (GLOBAL)"="Durabilité extrême (GLOBAL)"
    "TIRES"="PNEUS"
    "Tire asphalt grip"="Adhérence sur asphalte"
    "Tire off-road grip"="Adhérence hors route"
    "Tire mud grip"="Adhérence dans la boue"
    "All tires ignore ice"="Tous les pneus ignorent la glace"
    "SUSPENSION"="SUSPENSION"
    "Suspension strength"="Force de suspension"
    "Suspension height"="Hauteur de suspension"
    "Suspension damping"="Amortissement de suspension"
    "Suspension durability"="Durabilité de suspension"
    "RECOVERY & CRANES"="DÉPANNAGE & GRUES"
    "Winch strength"="Force du treuil"
    "Winch length"="Longueur du treuil"
    "Crane strength"="Force de la grue"
    "Crane speed"="Vitesse de la grue"
    "Autonomous winches"="Treuils autonomes"
    "TRUCK ACCESS"="ACCÈS AUX CAMIONS"
    "Unlock all trucks"="Déverrouiller tous les camions"
    "All trucks in all regions"="Tous les camions dans toutes les régions"
    "MORE PERFORMANCE & DURABILITY"="PERFORMANCES & DURABILITÉ"
    "Gear tuning"="Réglage de boîte"
    "Engine durability"="Durabilité du moteur"
    "Gearbox durability"="Durabilité de la boîte"
    "Tire durability"="Durabilité des pneus"
    "Fuel tank durability"="Durabilité du réservoir"
    "SERVICE & CARGO"="SERVICE & CARGAISON"
    "Service fuel capacity"="Capacité carburant de service"
    "Service water capacity"="Capacité eau de service"
    "Service repair points"="Points de réparation"
    "Service spare wheels"="Roues de secours"
    "Cargo mass"="Masse du chargement"
    "ECONOMY & UPGRADES"="ÉCONOMIE & AMÉLIORATIONS"
    "Truck prices"="Prix des camions"
    "Upgrade/addon prices"="Prix des améliorations/addons"
    "Unlock all upgrades/addons"="Déverrouiller toutes les améliorations/addons"
    "STABILITY"="STABILITÉ"
    "Truck center-of-gravity drop"="Abaissement du centre de gravité du camion"
    "Addon/trailer center-of-gravity drop"="Abaissement du centre de gravité addon/remorque"
    "QUICK PRESETS"="PRÉRÉGLAGES RAPIDES"
    "Vanilla / Reset"="Standard / Réinitialiser"
    "Enhanced"="Amélioré"
    "Overpowered"="Surpuissant"
    "Your last applied values are saved automatically."="Les dernières valeurs appliquées sont enregistrées automatiquement."
    "Preview Changes"="Aperçu des modifications"
    "Restore Original"="Restaurer l’original"
    "Check for Updates"="Rechercher des mises à jour"
    "APPLY MODS"="APPLIQUER LES MODS"
    "Ready."="Prêt."
    "Checking updates..."="Recherche de mises à jour..."
    "Language saved. Restart the editor to apply the interface translation."="Langue enregistrée. Redémarrez l’éditeur pour appliquer la traduction de l’interface."
    "Stock"="Standard"
    "Mild"="Léger"
    "Performance"="Performance"
    "High Performance"="Haute performance"
    "Extreme"="Extrême"
}
$script:Translations["es-ES"] = @{
    "All Trucks"="Todos los camiones"
    "Select initial.pak to scan trucks"="Selecciona initial.pak para buscar camiones"
    "Language"="Idioma"
    "Game file"="Archivo del juego"
    "Browse..."="Examinar..."
    "Truck target"="Camión objetivo"
    "Scan Trucks"="Buscar camiones"
    "Scan Mods"="Buscar mods"
    "POWER & FUEL"="POTENCIA Y COMBUSTIBLE"
    "Engine torque"="Par motor"
    "Engine responsiveness"="Respuesta del motor"
    "Engine fuel consumption"="Consumo de combustible del motor"
    "Truck fuel capacity"="Capacidad de combustible"
    "Maximum steering angle"="Ángulo máximo de dirección"
    "Steering response"="Respuesta de la dirección"
    "GEARBOX"="CAJA DE CAMBIOS"
    "Gearbox fuel consumption"="Consumo de la caja de cambios"
    "AWD fuel penalty"="Penalización de combustible AWD"
    "Idle fuel use"="Consumo al ralentí"
    "Always AWD"="AWD permanente"
    "Always differential lock (unchecked = default)"="Bloqueo diferencial permanente (desmarcado = predeterminado)"
    "Extreme durability (GLOBAL)"="Durabilidad extrema (GLOBAL)"
    "TIRES"="NEUMÁTICOS"
    "Tire asphalt grip"="Agarre en asfalto"
    "Tire off-road grip"="Agarre todoterreno"
    "Tire mud grip"="Agarre en barro"
    "All tires ignore ice"="Todos los neumáticos ignoran el hielo"
    "SUSPENSION"="SUSPENSIÓN"
    "Suspension strength"="Resistencia de suspensión"
    "Suspension height"="Altura de suspensión"
    "Suspension damping"="Amortiguación de suspensión"
    "Suspension durability"="Durabilidad de suspensión"
    "RECOVERY & CRANES"="RESCATE Y GRÚAS"
    "Winch strength"="Fuerza del cabrestante"
    "Winch length"="Longitud del cabrestante"
    "Crane strength"="Fuerza de la grúa"
    "Crane speed"="Velocidad de la grúa"
    "Autonomous winches"="Cabrestantes autónomos"
    "TRUCK ACCESS"="ACCESO A CAMIONES"
    "Unlock all trucks"="Desbloquear todos los camiones"
    "All trucks in all regions"="Todos los camiones en todas las regiones"
    "MORE PERFORMANCE & DURABILITY"="MÁS RENDIMIENTO Y DURABILIDAD"
    "Gear tuning"="Ajuste de marchas"
    "Engine durability"="Durabilidad del motor"
    "Gearbox durability"="Durabilidad de la caja"
    "Tire durability"="Durabilidad de neumáticos"
    "Fuel tank durability"="Durabilidad del depósito"
    "SERVICE & CARGO"="SERVICIO Y CARGA"
    "Service fuel capacity"="Capacidad de combustible de servicio"
    "Service water capacity"="Capacidad de agua de servicio"
    "Service repair points"="Puntos de reparación"
    "Service spare wheels"="Ruedas de repuesto"
    "Cargo mass"="Masa de carga"
    "ECONOMY & UPGRADES"="ECONOMÍA Y MEJORAS"
    "Truck prices"="Precios de camiones"
    "Upgrade/addon prices"="Precios de mejoras/addons"
    "Unlock all upgrades/addons"="Desbloquear todas las mejoras/addons"
    "STABILITY"="ESTABILIDAD"
    "Truck center-of-gravity drop"="Bajar centro de gravedad del camión"
    "Addon/trailer center-of-gravity drop"="Bajar centro de gravedad de addon/remolque"
    "QUICK PRESETS"="AJUSTES RÁPIDOS"
    "Vanilla / Reset"="Original / Restablecer"
    "Enhanced"="Mejorado"
    "Overpowered"="Potenciado"
    "Your last applied values are saved automatically."="Los últimos valores aplicados se guardan automáticamente."
    "Preview Changes"="Vista previa"
    "Restore Original"="Restaurar original"
    "Check for Updates"="Buscar actualizaciones"
    "APPLY MODS"="APLICAR MODS"
    "Ready."="Listo."
    "Checking updates..."="Buscando actualizaciones..."
    "Language saved. Restart the editor to apply the interface translation."="Idioma guardado. Reinicia el editor para aplicar la traducción de la interfaz."
    "Stock"="Original"
    "Mild"="Suave"
    "Performance"="Rendimiento"
    "High Performance"="Alto rendimiento"
    "Extreme"="Extremo"
}
$script:Translations["pl-PL"] = @{
    "All Trucks"="Wszystkie ciężarówki"
    "Select initial.pak to scan trucks"="Wybierz initial.pak, aby skanować ciężarówki"
    "Language"="Język"
    "Game file"="Plik gry"
    "Browse..."="Przeglądaj..."
    "Truck target"="Wybrana ciężarówka"
    "Scan Trucks"="Skanuj ciężarówki"
    "Scan Mods"="Skanuj mody"
    "POWER & FUEL"="MOC I PALIWO"
    "Engine torque"="Moment obrotowy silnika"
    "Engine responsiveness"="Reakcja silnika"
    "Engine fuel consumption"="Zużycie paliwa silnika"
    "Truck fuel capacity"="Pojemność zbiornika paliwa"
    "Maximum steering angle"="Maksymalny kąt skrętu"
    "Steering response"="Reakcja układu kierowniczego"
    "GEARBOX"="SKRZYNIA BIEGÓW"
    "Gearbox fuel consumption"="Zużycie paliwa skrzyni"
    "AWD fuel penalty"="Kara paliwowa AWD"
    "Idle fuel use"="Zużycie paliwa na biegu jałowym"
    "Always AWD"="Stały AWD"
    "Always differential lock (unchecked = default)"="Stała blokada dyferencjału (odznaczone = domyślne)"
    "Extreme durability (GLOBAL)"="Ekstremalna wytrzymałość (GLOBALNA)"
    "TIRES"="OPONY"
    "Tire asphalt grip"="Przyczepność na asfalcie"
    "Tire off-road grip"="Przyczepność terenowa"
    "Tire mud grip"="Przyczepność w błocie"
    "All tires ignore ice"="Wszystkie opony ignorują lód"
    "SUSPENSION"="ZAWIESZENIE"
    "Suspension strength"="Siła zawieszenia"
    "Suspension height"="Wysokość zawieszenia"
    "Suspension damping"="Tłumienie zawieszenia"
    "Suspension durability"="Wytrzymałość zawieszenia"
    "RECOVERY & CRANES"="HOLOWANIE I DŹWIGI"
    "Winch strength"="Siła wyciągarki"
    "Winch length"="Długość wyciągarki"
    "Crane strength"="Siła dźwigu"
    "Crane speed"="Prędkość dźwigu"
    "Autonomous winches"="Autonomiczne wyciągarki"
    "TRUCK ACCESS"="DOSTĘP DO CIĘŻARÓWEK"
    "Unlock all trucks"="Odblokuj wszystkie ciężarówki"
    "All trucks in all regions"="Wszystkie ciężarówki we wszystkich regionach"
    "MORE PERFORMANCE & DURABILITY"="WIĘCEJ OSIĄGÓW I WYTRZYMAŁOŚCI"
    "Gear tuning"="Strojenie biegów"
    "Engine durability"="Wytrzymałość silnika"
    "Gearbox durability"="Wytrzymałość skrzyni"
    "Tire durability"="Wytrzymałość opon"
    "Fuel tank durability"="Wytrzymałość zbiornika"
    "SERVICE & CARGO"="SERWIS I ŁADUNEK"
    "Service fuel capacity"="Pojemność paliwa serwisowego"
    "Service water capacity"="Pojemność wody serwisowej"
    "Service repair points"="Punkty napraw"
    "Service spare wheels"="Koła zapasowe"
    "Cargo mass"="Masa ładunku"
    "ECONOMY & UPGRADES"="EKONOMIA I ULEPSZENIA"
    "Truck prices"="Ceny ciężarówek"
    "Upgrade/addon prices"="Ceny ulepszeń/dodatków"
    "Unlock all upgrades/addons"="Odblokuj wszystkie ulepszenia/dodatki"
    "STABILITY"="STABILNOŚĆ"
    "Truck center-of-gravity drop"="Obniżenie środka ciężkości ciężarówki"
    "Addon/trailer center-of-gravity drop"="Obniżenie środka ciężkości dodatku/przyczepy"
    "QUICK PRESETS"="SZYBKIE USTAWIENIA"
    "Vanilla / Reset"="Standard / Reset"
    "Enhanced"="Ulepszony"
    "Overpowered"="Wzmocniony"
    "Your last applied values are saved automatically."="Ostatnio zastosowane wartości są zapisywane automatycznie."
    "Preview Changes"="Podgląd zmian"
    "Restore Original"="Przywróć oryginał"
    "Check for Updates"="Sprawdź aktualizacje"
    "APPLY MODS"="ZASTOSUJ MODY"
    "Ready."="Gotowe."
    "Checking updates..."="Sprawdzanie aktualizacji..."
    "Language saved. Restart the editor to apply the interface translation."="Język zapisany. Uruchom edytor ponownie, aby zastosować tłumaczenie interfejsu."
    "Stock"="Standard"
    "Mild"="Łagodny"
    "Performance"="Wydajność"
    "High Performance"="Wysoka wydajność"
    "Extreme"="Ekstremalny"
}
$script:Translations["pt-BR"] = @{
    "All Trucks"="Todos os caminhões"
    "Select initial.pak to scan trucks"="Selecione initial.pak para verificar caminhões"
    "Language"="Idioma"
    "Game file"="Arquivo do jogo"
    "Browse..."="Procurar..."
    "Truck target"="Caminhão alvo"
    "Scan Trucks"="Verificar caminhões"
    "Scan Mods"="Verificar mods"
    "POWER & FUEL"="POTÊNCIA E COMBUSTÍVEL"
    "Engine torque"="Torque do motor"
    "Engine responsiveness"="Resposta do motor"
    "Engine fuel consumption"="Consumo de combustível do motor"
    "Truck fuel capacity"="Capacidade de combustível"
    "Maximum steering angle"="Ângulo máximo de direção"
    "Steering response"="Resposta da direção"
    "GEARBOX"="CÂMBIO"
    "Gearbox fuel consumption"="Consumo de combustível do câmbio"
    "AWD fuel penalty"="Penalidade de combustível AWD"
    "Idle fuel use"="Consumo em marcha lenta"
    "Always AWD"="AWD permanente"
    "Always differential lock (unchecked = default)"="Bloqueio diferencial permanente (desmarcado = padrão)"
    "Extreme durability (GLOBAL)"="Durabilidade extrema (GLOBAL)"
    "TIRES"="PNEUS"
    "Tire asphalt grip"="Aderência no asfalto"
    "Tire off-road grip"="Aderência fora de estrada"
    "Tire mud grip"="Aderência na lama"
    "All tires ignore ice"="Todos os pneus ignoram gelo"
    "SUSPENSION"="SUSPENSÃO"
    "Suspension strength"="Força da suspensão"
    "Suspension height"="Altura da suspensão"
    "Suspension damping"="Amortecimento da suspensão"
    "Suspension durability"="Durabilidade da suspensão"
    "RECOVERY & CRANES"="RESGATE E GUINDASTES"
    "Winch strength"="Força do guincho"
    "Winch length"="Comprimento do guincho"
    "Crane strength"="Força do guindaste"
    "Crane speed"="Velocidade do guindaste"
    "Autonomous winches"="Guinchos autônomos"
    "TRUCK ACCESS"="ACESSO A CAMINHÕES"
    "Unlock all trucks"="Desbloquear todos os caminhões"
    "All trucks in all regions"="Todos os caminhões em todas as regiões"
    "MORE PERFORMANCE & DURABILITY"="MAIS DESEMPENHO E DURABILIDADE"
    "Gear tuning"="Ajuste de marchas"
    "Engine durability"="Durabilidade do motor"
    "Gearbox durability"="Durabilidade do câmbio"
    "Tire durability"="Durabilidade dos pneus"
    "Fuel tank durability"="Durabilidade do tanque"
    "SERVICE & CARGO"="SERVIÇO E CARGA"
    "Service fuel capacity"="Capacidade de combustível de serviço"
    "Service water capacity"="Capacidade de água de serviço"
    "Service repair points"="Pontos de reparo"
    "Service spare wheels"="Rodas sobressalentes"
    "Cargo mass"="Massa da carga"
    "ECONOMY & UPGRADES"="ECONOMIA E MELHORIAS"
    "Truck prices"="Preços dos caminhões"
    "Upgrade/addon prices"="Preços de melhorias/addons"
    "Unlock all upgrades/addons"="Desbloquear todas as melhorias/addons"
    "STABILITY"="ESTABILIDADE"
    "Truck center-of-gravity drop"="Rebaixamento do centro de gravidade do caminhão"
    "Addon/trailer center-of-gravity drop"="Rebaixamento do centro de gravidade de addon/reboque"
    "QUICK PRESETS"="PREDEFINIÇÕES RÁPIDAS"
    "Vanilla / Reset"="Padrão / Redefinir"
    "Enhanced"="Aprimorado"
    "Overpowered"="Superpotente"
    "Your last applied values are saved automatically."="Os últimos valores aplicados são salvos automaticamente."
    "Preview Changes"="Visualizar alterações"
    "Restore Original"="Restaurar original"
    "Check for Updates"="Verificar atualizações"
    "APPLY MODS"="APLICAR MODS"
    "Ready."="Pronto."
    "Checking updates..."="Verificando atualizações..."
    "Language saved. Restart the editor to apply the interface translation."="Idioma salvo. Reinicie o editor para aplicar a tradução da interface."
    "Stock"="Padrão"
    "Mild"="Leve"
    "Performance"="Desempenho"
    "High Performance"="Alto desempenho"
    "Extreme"="Extremo"
}
$script:Translations["zh-CN"] = @{
    "All Trucks"="所有卡车"
    "Select initial.pak to scan trucks"="选择 initial.pak 以扫描卡车"
    "Language"="语言"
    "Game file"="游戏文件"
    "Browse..."="浏览..."
    "Truck target"="目标卡车"
    "Scan Trucks"="扫描卡车"
    "Scan Mods"="扫描模组"
    "POWER & FUEL"="动力与燃油"
    "Engine torque"="发动机扭矩"
    "Engine responsiveness"="发动机响应"
    "Engine fuel consumption"="发动机油耗"
    "Truck fuel capacity"="卡车燃油容量"
    "Maximum steering angle"="最大转向角"
    "Steering response"="转向响应"
    "GEARBOX"="变速箱"
    "Gearbox fuel consumption"="变速箱油耗"
    "AWD fuel penalty"="AWD油耗惩罚"
    "Idle fuel use"="怠速油耗"
    "Always AWD"="始终启用AWD"
    "Always differential lock (unchecked = default)"="始终锁定差速器（未勾选=默认）"
    "Extreme durability (GLOBAL)"="极限耐久（全局）"
    "TIRES"="轮胎"
    "Tire asphalt grip"="沥青抓地力"
    "Tire off-road grip"="越野抓地力"
    "Tire mud grip"="泥地抓地力"
    "All tires ignore ice"="所有轮胎忽略冰面"
    "SUSPENSION"="悬挂"
    "Suspension strength"="悬挂强度"
    "Suspension height"="悬挂高度"
    "Suspension damping"="悬挂阻尼"
    "Suspension durability"="悬挂耐久"
    "RECOVERY & CRANES"="救援与起重机"
    "Winch strength"="绞盘强度"
    "Winch length"="绞盘长度"
    "Crane strength"="起重机强度"
    "Crane speed"="起重机速度"
    "Autonomous winches"="自动绞盘"
    "TRUCK ACCESS"="卡车访问"
    "Unlock all trucks"="解锁所有卡车"
    "All trucks in all regions"="所有地区可用所有卡车"
    "MORE PERFORMANCE & DURABILITY"="更多性能与耐久"
    "Gear tuning"="挡位调校"
    "Engine durability"="发动机耐久"
    "Gearbox durability"="变速箱耐久"
    "Tire durability"="轮胎耐久"
    "Fuel tank durability"="油箱耐久"
    "SERVICE & CARGO"="维修与货物"
    "Service fuel capacity"="维修燃油容量"
    "Service water capacity"="维修用水容量"
    "Service repair points"="维修点数"
    "Service spare wheels"="备用轮胎"
    "Cargo mass"="货物质量"
    "ECONOMY & UPGRADES"="经济与升级"
    "Truck prices"="卡车价格"
    "Upgrade/addon prices"="升级/附件价格"
    "Unlock all upgrades/addons"="解锁所有升级/附件"
    "STABILITY"="稳定性"
    "Truck center-of-gravity drop"="降低卡车重心"
    "Addon/trailer center-of-gravity drop"="降低附件/拖车重心"
    "QUICK PRESETS"="快速预设"
    "Vanilla / Reset"="原版 / 重置"
    "Enhanced"="增强"
    "Overpowered"="超强"
    "Your last applied values are saved automatically."="上次应用的数值会自动保存。"
    "Preview Changes"="预览更改"
    "Restore Original"="恢复原始文件"
    "Check for Updates"="检查更新"
    "APPLY MODS"="应用模组"
    "Ready."="就绪。"
    "Checking updates..."="正在检查更新..."
    "Language saved. Restart the editor to apply the interface translation."="语言已保存。请重新启动编辑器以应用界面翻译。"
    "Stock"="原版"
    "Mild"="轻度"
    "Performance"="性能"
    "High Performance"="高性能"
    "Extreme"="极限"
}
$script:Translations["ja-JP"] = @{
    "All Trucks"="すべてのトラック"
    "Select initial.pak to scan trucks"="トラックをスキャンするには initial.pak を選択"
    "Language"="言語"
    "Game file"="ゲームファイル"
    "Browse..."="参照..."
    "Truck target"="対象トラック"
    "Scan Trucks"="トラックをスキャン"
    "Scan Mods"="MODをスキャン"
    "POWER & FUEL"="パワー＆燃料"
    "Engine torque"="エンジントルク"
    "Engine responsiveness"="エンジン応答性"
    "Engine fuel consumption"="エンジン燃料消費"
    "Truck fuel capacity"="トラック燃料容量"
    "Maximum steering angle"="最大ステアリング角"
    "Steering response"="ステアリング応答"
    "GEARBOX"="ギアボックス"
    "Gearbox fuel consumption"="ギアボックス燃料消費"
    "AWD fuel penalty"="AWD燃料ペナルティ"
    "Idle fuel use"="アイドル燃料消費"
    "Always AWD"="常時AWD"
    "Always differential lock (unchecked = default)"="常時デフロック（未選択＝標準）"
    "Extreme durability (GLOBAL)"="極限耐久性（グローバル）"
    "TIRES"="タイヤ"
    "Tire asphalt grip"="アスファルトグリップ"
    "Tire off-road grip"="オフロードグリップ"
    "Tire mud grip"="マッドグリップ"
    "All tires ignore ice"="すべてのタイヤで氷を無視"
    "SUSPENSION"="サスペンション"
    "Suspension strength"="サスペンション強度"
    "Suspension height"="サスペンション高さ"
    "Suspension damping"="サスペンション減衰"
    "Suspension durability"="サスペンション耐久性"
    "RECOVERY & CRANES"="リカバリー＆クレーン"
    "Winch strength"="ウインチ強度"
    "Winch length"="ウインチ長さ"
    "Crane strength"="クレーン強度"
    "Crane speed"="クレーン速度"
    "Autonomous winches"="自律ウインチ"
    "TRUCK ACCESS"="トラックアクセス"
    "Unlock all trucks"="すべてのトラックを解除"
    "All trucks in all regions"="全地域ですべてのトラックを使用"
    "MORE PERFORMANCE & DURABILITY"="追加性能＆耐久性"
    "Gear tuning"="ギア調整"
    "Engine durability"="エンジン耐久性"
    "Gearbox durability"="ギアボックス耐久性"
    "Tire durability"="タイヤ耐久性"
    "Fuel tank durability"="燃料タンク耐久性"
    "SERVICE & CARGO"="サービス＆貨物"
    "Service fuel capacity"="サービス燃料容量"
    "Service water capacity"="サービス水容量"
    "Service repair points"="修理ポイント"
    "Service spare wheels"="スペアタイヤ"
    "Cargo mass"="貨物重量"
    "ECONOMY & UPGRADES"="経済＆アップグレード"
    "Truck prices"="トラック価格"
    "Upgrade/addon prices"="アップグレード/アドオン価格"
    "Unlock all upgrades/addons"="すべてのアップグレード/アドオンを解除"
    "STABILITY"="安定性"
    "Truck center-of-gravity drop"="トラック重心を下げる"
    "Addon/trailer center-of-gravity drop"="アドオン/トレーラー重心を下げる"
    "QUICK PRESETS"="クイックプリセット"
    "Vanilla / Reset"="標準 / リセット"
    "Enhanced"="強化"
    "Overpowered"="オーバーパワー"
    "Your last applied values are saved automatically."="最後に適用した値は自動保存されます。"
    "Preview Changes"="変更をプレビュー"
    "Restore Original"="オリジナルを復元"
    "Check for Updates"="アップデートを確認"
    "APPLY MODS"="MODを適用"
    "Ready."="準備完了。"
    "Checking updates..."="アップデートを確認中..."
    "Language saved. Restart the editor to apply the interface translation."="言語を保存しました。インターフェース翻訳を適用するにはエディターを再起動してください。"
    "Stock"="標準"
    "Mild"="マイルド"
    "Performance"="パフォーマンス"
    "High Performance"="ハイパフォーマンス"
    "Extreme"="エクストリーム"
}
$script:Translations["ko-KR"] = @{
    "All Trucks"="모든 트럭"
    "Select initial.pak to scan trucks"="트럭을 검색하려면 initial.pak을 선택하세요"
    "Language"="언어"
    "Game file"="게임 파일"
    "Browse..."="찾아보기..."
    "Truck target"="대상 트럭"
    "Scan Trucks"="트럭 검색"
    "Scan Mods"="모드 검색"
    "POWER & FUEL"="출력 및 연료"
    "Engine torque"="엔진 토크"
    "Engine responsiveness"="엔진 반응성"
    "Engine fuel consumption"="엔진 연료 소비"
    "Truck fuel capacity"="트럭 연료 용량"
    "Maximum steering angle"="최대 조향각"
    "Steering response"="조향 반응"
    "GEARBOX"="기어박스"
    "Gearbox fuel consumption"="기어박스 연료 소비"
    "AWD fuel penalty"="AWD 연료 페널티"
    "Idle fuel use"="공회전 연료 소비"
    "Always AWD"="항상 AWD"
    "Always differential lock (unchecked = default)"="항상 차동 잠금(선택 해제=기본값)"
    "Extreme durability (GLOBAL)"="극한 내구성(전체)"
    "TIRES"="타이어"
    "Tire asphalt grip"="아스팔트 접지력"
    "Tire off-road grip"="오프로드 접지력"
    "Tire mud grip"="진흙 접지력"
    "All tires ignore ice"="모든 타이어가 얼음 무시"
    "SUSPENSION"="서스펜션"
    "Suspension strength"="서스펜션 강도"
    "Suspension height"="서스펜션 높이"
    "Suspension damping"="서스펜션 감쇠"
    "Suspension durability"="서스펜션 내구성"
    "RECOVERY & CRANES"="구난 및 크레인"
    "Winch strength"="윈치 강도"
    "Winch length"="윈치 길이"
    "Crane strength"="크레인 강도"
    "Crane speed"="크레인 속도"
    "Autonomous winches"="자동 윈치"
    "TRUCK ACCESS"="트럭 접근"
    "Unlock all trucks"="모든 트럭 잠금 해제"
    "All trucks in all regions"="모든 지역에서 모든 트럭 사용"
    "MORE PERFORMANCE & DURABILITY"="추가 성능 및 내구성"
    "Gear tuning"="기어 튜닝"
    "Engine durability"="엔진 내구성"
    "Gearbox durability"="기어박스 내구성"
    "Tire durability"="타이어 내구성"
    "Fuel tank durability"="연료 탱크 내구성"
    "SERVICE & CARGO"="서비스 및 화물"
    "Service fuel capacity"="서비스 연료 용량"
    "Service water capacity"="서비스 물 용량"
    "Service repair points"="수리 포인트"
    "Service spare wheels"="예비 타이어"
    "Cargo mass"="화물 질량"
    "ECONOMY & UPGRADES"="경제 및 업그레이드"
    "Truck prices"="트럭 가격"
    "Upgrade/addon prices"="업그레이드/애드온 가격"
    "Unlock all upgrades/addons"="모든 업그레이드/애드온 잠금 해제"
    "STABILITY"="안정성"
    "Truck center-of-gravity drop"="트럭 무게중심 낮추기"
    "Addon/trailer center-of-gravity drop"="애드온/트레일러 무게중심 낮추기"
    "QUICK PRESETS"="빠른 프리셋"
    "Vanilla / Reset"="기본 / 초기화"
    "Enhanced"="강화"
    "Overpowered"="고성능"
    "Your last applied values are saved automatically."="마지막 적용 값은 자동 저장됩니다."
    "Preview Changes"="변경 미리보기"
    "Restore Original"="원본 복원"
    "Check for Updates"="업데이트 확인"
    "APPLY MODS"="모드 적용"
    "Ready."="준비됨."
    "Checking updates..."="업데이트 확인 중..."
    "Language saved. Restart the editor to apply the interface translation."="언어가 저장되었습니다. 인터페이스 번역을 적용하려면 편집기를 다시 시작하세요."
    "Stock"="기본"
    "Mild"="마일드"
    "Performance"="성능"
    "High Performance"="고성능"
    "Extreme"="극한"
}
$script:Translations["it-IT"] = @{
    "All Trucks"="Tutti i camion"
    "Select initial.pak to scan trucks"="Seleziona initial.pak per scansionare i camion"
    "Language"="Lingua"
    "Game file"="File di gioco"
    "Browse..."="Sfoglia..."
    "Truck target"="Camion di destinazione"
    "Scan Trucks"="Scansiona camion"
    "Scan Mods"="Scansiona mod"
    "POWER & FUEL"="POTENZA E CARBURANTE"
    "Engine torque"="Coppia motore"
    "Engine responsiveness"="Risposta del motore"
    "Engine fuel consumption"="Consumo carburante motore"
    "Truck fuel capacity"="Capacità carburante"
    "Maximum steering angle"="Angolo massimo di sterzata"
    "Steering response"="Risposta dello sterzo"
    "GEARBOX"="CAMBIO"
    "Gearbox fuel consumption"="Consumo carburante cambio"
    "AWD fuel penalty"="Penalità carburante AWD"
    "Idle fuel use"="Consumo al minimo"
    "Always AWD"="AWD permanente"
    "Always differential lock (unchecked = default)"="Blocco differenziale permanente (deselezionato = predefinito)"
    "Extreme durability (GLOBAL)"="Durabilità estrema (GLOBALE)"
    "TIRES"="PNEUMATICI"
    "Tire asphalt grip"="Aderenza su asfalto"
    "Tire off-road grip"="Aderenza fuoristrada"
    "Tire mud grip"="Aderenza nel fango"
    "All tires ignore ice"="Tutti i pneumatici ignorano il ghiaccio"
    "SUSPENSION"="SOSPENSIONE"
    "Suspension strength"="Forza sospensione"
    "Suspension height"="Altezza sospensione"
    "Suspension damping"="Smorzamento sospensione"
    "Suspension durability"="Durabilità sospensione"
    "RECOVERY & CRANES"="RECUPERO E GRU"
    "Winch strength"="Forza verricello"
    "Winch length"="Lunghezza verricello"
    "Crane strength"="Forza gru"
    "Crane speed"="Velocità gru"
    "Autonomous winches"="Verricelli autonomi"
    "TRUCK ACCESS"="ACCESSO AI CAMION"
    "Unlock all trucks"="Sblocca tutti i camion"
    "All trucks in all regions"="Tutti i camion in tutte le regioni"
    "MORE PERFORMANCE & DURABILITY"="PIÙ PRESTAZIONI E DURABILITÀ"
    "Gear tuning"="Regolazione marce"
    "Engine durability"="Durabilità motore"
    "Gearbox durability"="Durabilità cambio"
    "Tire durability"="Durabilità pneumatici"
    "Fuel tank durability"="Durabilità serbatoio"
    "SERVICE & CARGO"="SERVIZIO E CARICO"
    "Service fuel capacity"="Capacità carburante di servizio"
    "Service water capacity"="Capacità acqua di servizio"
    "Service repair points"="Punti riparazione"
    "Service spare wheels"="Ruote di scorta"
    "Cargo mass"="Massa carico"
    "ECONOMY & UPGRADES"="ECONOMIA E MIGLIORAMENTI"
    "Truck prices"="Prezzi camion"
    "Upgrade/addon prices"="Prezzi miglioramenti/addon"
    "Unlock all upgrades/addons"="Sblocca tutti i miglioramenti/addon"
    "STABILITY"="STABILITÀ"
    "Truck center-of-gravity drop"="Abbassamento baricentro camion"
    "Addon/trailer center-of-gravity drop"="Abbassamento baricentro addon/rimorchio"
    "QUICK PRESETS"="PRESET RAPIDI"
    "Vanilla / Reset"="Standard / Ripristina"
    "Enhanced"="Migliorato"
    "Overpowered"="Potenziato"
    "Your last applied values are saved automatically."="Gli ultimi valori applicati vengono salvati automaticamente."
    "Preview Changes"="Anteprima modifiche"
    "Restore Original"="Ripristina originale"
    "Check for Updates"="Controlla aggiornamenti"
    "APPLY MODS"="APPLICA MOD"
    "Ready."="Pronto."
    "Checking updates..."="Controllo aggiornamenti..."
    "Language saved. Restart the editor to apply the interface translation."="Lingua salvata. Riavvia l’editor per applicare la traduzione dell’interfaccia."
    "Stock"="Standard"
    "Mild"="Leggero"
    "Performance"="Prestazioni"
    "High Performance"="Alte prestazioni"
    "Extreme"="Estremo"
}
$script:Translations["tr-TR"] = @{
    "All Trucks"="Tüm kamyonlar"
    "Select initial.pak to scan trucks"="Kamyonları taramak için initial.pak seçin"
    "Language"="Dil"
    "Game file"="Oyun dosyası"
    "Browse..."="Gözat..."
    "Truck target"="Hedef kamyon"
    "Scan Trucks"="Kamyonları tara"
    "Scan Mods"="Modları tara"
    "POWER & FUEL"="GÜÇ VE YAKIT"
    "Engine torque"="Motor torku"
    "Engine responsiveness"="Motor tepkisi"
    "Engine fuel consumption"="Motor yakıt tüketimi"
    "Truck fuel capacity"="Kamyon yakıt kapasitesi"
    "Maximum steering angle"="Maksimum direksiyon açısı"
    "Steering response"="Direksiyon tepkisi"
    "GEARBOX"="ŞANZIMAN"
    "Gearbox fuel consumption"="Şanzıman yakıt tüketimi"
    "AWD fuel penalty"="AWD yakıt cezası"
    "Idle fuel use"="Rölanti yakıt tüketimi"
    "Always AWD"="Sürekli AWD"
    "Always differential lock (unchecked = default)"="Sürekli diferansiyel kilidi (işaretli değil = varsayılan)"
    "Extreme durability (GLOBAL)"="Aşırı dayanıklılık (GLOBAL)"
    "TIRES"="LASTİKLER"
    "Tire asphalt grip"="Asfalt tutuşu"
    "Tire off-road grip"="Arazi tutuşu"
    "Tire mud grip"="Çamur tutuşu"
    "All tires ignore ice"="Tüm lastikler buzu yok sayar"
    "SUSPENSION"="SÜSPANSİYON"
    "Suspension strength"="Süspansiyon gücü"
    "Suspension height"="Süspansiyon yüksekliği"
    "Suspension damping"="Süspansiyon sönümleme"
    "Suspension durability"="Süspansiyon dayanıklılığı"
    "RECOVERY & CRANES"="KURTARMA VE VİNÇLER"
    "Winch strength"="Vinç gücü"
    "Winch length"="Vinç uzunluğu"
    "Crane strength"="Kran gücü"
    "Crane speed"="Kran hızı"
    "Autonomous winches"="Otonom vinçler"
    "TRUCK ACCESS"="KAMYON ERİŞİMİ"
    "Unlock all trucks"="Tüm kamyonların kilidini aç"
    "All trucks in all regions"="Tüm bölgelerde tüm kamyonlar"
    "MORE PERFORMANCE & DURABILITY"="DAHA FAZLA PERFORMANS VE DAYANIKLILIK"
    "Gear tuning"="Vites ayarı"
    "Engine durability"="Motor dayanıklılığı"
    "Gearbox durability"="Şanzıman dayanıklılığı"
    "Tire durability"="Lastik dayanıklılığı"
    "Fuel tank durability"="Yakıt deposu dayanıklılığı"
    "SERVICE & CARGO"="SERVİS VE YÜK"
    "Service fuel capacity"="Servis yakıt kapasitesi"
    "Service water capacity"="Servis su kapasitesi"
    "Service repair points"="Onarım puanları"
    "Service spare wheels"="Yedek tekerlekler"
    "Cargo mass"="Yük kütlesi"
    "ECONOMY & UPGRADES"="EKONOMİ VE YÜKSELTMELER"
    "Truck prices"="Kamyon fiyatları"
    "Upgrade/addon prices"="Yükseltme/eklenti fiyatları"
    "Unlock all upgrades/addons"="Tüm yükseltme/eklentilerin kilidini aç"
    "STABILITY"="DENGE"
    "Truck center-of-gravity drop"="Kamyon ağırlık merkezini düşür"
    "Addon/trailer center-of-gravity drop"="Eklenti/römork ağırlık merkezini düşür"
    "QUICK PRESETS"="HIZLI ÖN AYARLAR"
    "Vanilla / Reset"="Standart / Sıfırla"
    "Enhanced"="Geliştirilmiş"
    "Overpowered"="Aşırı Güçlü"
    "Your last applied values are saved automatically."="Son uygulanan değerler otomatik olarak kaydedilir."
    "Preview Changes"="Değişiklikleri önizle"
    "Restore Original"="Orijinali geri yükle"
    "Check for Updates"="Güncellemeleri denetle"
    "APPLY MODS"="MODLARI UYGULA"
    "Ready."="Hazır."
    "Checking updates..."="Güncellemeler denetleniyor..."
    "Language saved. Restart the editor to apply the interface translation."="Dil kaydedildi. Arayüz çevirisini uygulamak için düzenleyiciyi yeniden başlatın."
    "Stock"="Standart"
    "Mild"="Hafif"
    "Performance"="Performans"
    "High Performance"="Yüksek Performans"
    "Extreme"="Aşırı"
}
$script:Translations["uk-UA"] = @{
    "All Trucks"="Усі вантажівки"
    "Select initial.pak to scan trucks"="Виберіть initial.pak для сканування вантажівок"
    "Language"="Мова"
    "Game file"="Файл гри"
    "Browse..."="Огляд..."
    "Truck target"="Цільова вантажівка"
    "Scan Trucks"="Сканувати вантажівки"
    "Scan Mods"="Сканувати моди"
    "POWER & FUEL"="ПОТУЖНІСТЬ І ПАЛИВО"
    "Engine torque"="Крутний момент двигуна"
    "Engine responsiveness"="Відгук двигуна"
    "Engine fuel consumption"="Витрата палива двигуна"
    "Truck fuel capacity"="Об’єм паливного бака"
    "Maximum steering angle"="Максимальний кут керма"
    "Steering response"="Відгук кермування"
    "GEARBOX"="КОРОБКА ПЕРЕДАЧ"
    "Gearbox fuel consumption"="Витрата палива КПП"
    "AWD fuel penalty"="Штраф витрати палива AWD"
    "Idle fuel use"="Витрата палива на холостому ходу"
    "Always AWD"="Постійний AWD"
    "Always differential lock (unchecked = default)"="Постійне блокування диференціала (не позначено = стандарт)"
    "Extreme durability (GLOBAL)"="Екстремальна міцність (ГЛОБАЛЬНО)"
    "TIRES"="ШИНИ"
    "Tire asphalt grip"="Зчеплення з асфальтом"
    "Tire off-road grip"="Зчеплення на бездоріжжі"
    "Tire mud grip"="Зчеплення в багнюці"
    "All tires ignore ice"="Усі шини ігнорують лід"
    "SUSPENSION"="ПІДВІСКА"
    "Suspension strength"="Міцність підвіски"
    "Suspension height"="Висота підвіски"
    "Suspension damping"="Демпфування підвіски"
    "Suspension durability"="Довговічність підвіски"
    "RECOVERY & CRANES"="ЕВАКУАЦІЯ ТА КРАНИ"
    "Winch strength"="Сила лебідки"
    "Winch length"="Довжина лебідки"
    "Crane strength"="Сила крана"
    "Crane speed"="Швидкість крана"
    "Autonomous winches"="Автономні лебідки"
    "TRUCK ACCESS"="ДОСТУП ДО ВАНТАЖІВОК"
    "Unlock all trucks"="Розблокувати всі вантажівки"
    "All trucks in all regions"="Усі вантажівки в усіх регіонах"
    "MORE PERFORMANCE & DURABILITY"="БІЛЬШЕ ПРОДУКТИВНОСТІ ТА МІЦНОСТІ"
    "Gear tuning"="Налаштування передач"
    "Engine durability"="Міцність двигуна"
    "Gearbox durability"="Міцність КПП"
    "Tire durability"="Міцність шин"
    "Fuel tank durability"="Міцність паливного бака"
    "SERVICE & CARGO"="СЕРВІС І ВАНТАЖ"
    "Service fuel capacity"="Запас сервісного палива"
    "Service water capacity"="Запас сервісної води"
    "Service repair points"="Очки ремонту"
    "Service spare wheels"="Запасні колеса"
    "Cargo mass"="Маса вантажу"
    "ECONOMY & UPGRADES"="ЕКОНОМІКА ТА ПОКРАЩЕННЯ"
    "Truck prices"="Ціни вантажівок"
    "Upgrade/addon prices"="Ціни покращень/аддонів"
    "Unlock all upgrades/addons"="Розблокувати всі покращення/аддони"
    "STABILITY"="СТІЙКІСТЬ"
    "Truck center-of-gravity drop"="Зниження центру ваги вантажівки"
    "Addon/trailer center-of-gravity drop"="Зниження центру ваги аддона/причепа"
    "QUICK PRESETS"="ШВИДКІ ПРЕСЕТИ"
    "Vanilla / Reset"="Стандарт / Скинути"
    "Enhanced"="Покращений"
    "Overpowered"="Надпотужний"
    "Your last applied values are saved automatically."="Останні застосовані значення зберігаються автоматично."
    "Preview Changes"="Перегляд змін"
    "Restore Original"="Відновити оригінал"
    "Check for Updates"="Перевірити оновлення"
    "APPLY MODS"="ЗАСТОСУВАТИ МОДИ"
    "Ready."="Готово."
    "Checking updates..."="Перевірка оновлень..."
    "Language saved. Restart the editor to apply the interface translation."="Мову збережено. Перезапустіть редактор, щоб застосувати переклад інтерфейсу."
    "Stock"="Стандарт"
    "Mild"="Помірний"
    "Performance"="Продуктивність"
    "High Performance"="Висока продуктивність"
    "Extreme"="Екстремальний"
}
$script:Translations["cs-CZ"] = @{
    "All Trucks"="Všechny nákladní vozy"
    "Select initial.pak to scan trucks"="Vyberte initial.pak pro skenování vozů"
    "Language"="Jazyk"
    "Game file"="Soubor hry"
    "Browse..."="Procházet..."
    "Truck target"="Cílový vůz"
    "Scan Trucks"="Skenovat vozy"
    "Scan Mods"="Skenovat mody"
    "POWER & FUEL"="VÝKON A PALIVO"
    "Engine torque"="Točivý moment motoru"
    "Engine responsiveness"="Odezva motoru"
    "Engine fuel consumption"="Spotřeba paliva motoru"
    "Truck fuel capacity"="Kapacita paliva"
    "Maximum steering angle"="Maximální úhel řízení"
    "Steering response"="Odezva řízení"
    "GEARBOX"="PŘEVODOVKA"
    "Gearbox fuel consumption"="Spotřeba paliva převodovky"
    "AWD fuel penalty"="Palivová penalizace AWD"
    "Idle fuel use"="Spotřeba na volnoběh"
    "Always AWD"="Trvalé AWD"
    "Always differential lock (unchecked = default)"="Trvalá uzávěrka diferenciálu (nezaškrtnuto = výchozí)"
    "Extreme durability (GLOBAL)"="Extrémní odolnost (GLOBÁLNÍ)"
    "TIRES"="PNEUMATIKY"
    "Tire asphalt grip"="Přilnavost na asfaltu"
    "Tire off-road grip"="Přilnavost v terénu"
    "Tire mud grip"="Přilnavost v blátě"
    "All tires ignore ice"="Všechny pneumatiky ignorují led"
    "SUSPENSION"="ODPRUŽENÍ"
    "Suspension strength"="Síla odpružení"
    "Suspension height"="Výška odpružení"
    "Suspension damping"="Tlumení odpružení"
    "Suspension durability"="Odolnost odpružení"
    "RECOVERY & CRANES"="VYPROŠŤOVÁNÍ A JEŘÁBY"
    "Winch strength"="Síla navijáku"
    "Winch length"="Délka navijáku"
    "Crane strength"="Síla jeřábu"
    "Crane speed"="Rychlost jeřábu"
    "Autonomous winches"="Autonomní navijáky"
    "TRUCK ACCESS"="PŘÍSTUP K VOZŮM"
    "Unlock all trucks"="Odemknout všechny vozy"
    "All trucks in all regions"="Všechny vozy ve všech regionech"
    "MORE PERFORMANCE & DURABILITY"="VÍCE VÝKONU A ODOLNOSTI"
    "Gear tuning"="Ladění převodů"
    "Engine durability"="Odolnost motoru"
    "Gearbox durability"="Odolnost převodovky"
    "Tire durability"="Odolnost pneumatik"
    "Fuel tank durability"="Odolnost palivové nádrže"
    "SERVICE & CARGO"="SERVIS A NÁKLAD"
    "Service fuel capacity"="Kapacita servisního paliva"
    "Service water capacity"="Kapacita servisní vody"
    "Service repair points"="Body oprav"
    "Service spare wheels"="Náhradní kola"
    "Cargo mass"="Hmotnost nákladu"
    "ECONOMY & UPGRADES"="EKONOMIKA A VYLEPŠENÍ"
    "Truck prices"="Ceny vozů"
    "Upgrade/addon prices"="Ceny vylepšení/addonů"
    "Unlock all upgrades/addons"="Odemknout všechna vylepšení/addony"
    "STABILITY"="STABILITA"
    "Truck center-of-gravity drop"="Snížení těžiště vozu"
    "Addon/trailer center-of-gravity drop"="Snížení těžiště addonu/přívěsu"
    "QUICK PRESETS"="RYCHLÉ PŘEDVOLBY"
    "Vanilla / Reset"="Výchozí / Reset"
    "Enhanced"="Vylepšené"
    "Overpowered"="Přehnaně výkonné"
    "Your last applied values are saved automatically."="Poslední použité hodnoty se ukládají automaticky."
    "Preview Changes"="Náhled změn"
    "Restore Original"="Obnovit originál"
    "Check for Updates"="Zkontrolovat aktualizace"
    "APPLY MODS"="POUŽÍT MODY"
    "Ready."="Připraveno."
    "Checking updates..."="Kontrola aktualizací..."
    "Language saved. Restart the editor to apply the interface translation."="Jazyk uložen. Restartujte editor, aby se použil překlad rozhraní."
    "Stock"="Výchozí"
    "Mild"="Mírné"
    "Performance"="Výkon"
    "High Performance"="Vysoký výkon"
    "Extreme"="Extrémní"
}
$script:Translations["hi-IN"] = @{
    "All Trucks"="सभी ट्रक"
    "Select initial.pak to scan trucks"="ट्रक स्कैन करने के लिए initial.pak चुनें"
    "Language"="भाषा"
    "Game file"="गेम फ़ाइल"
    "Browse..."="ब्राउज़..."
    "Truck target"="लक्षित ट्रक"
    "Scan Trucks"="ट्रक स्कैन करें"
    "Scan Mods"="मॉड स्कैन करें"
    "POWER & FUEL"="पावर और ईंधन"
    "Engine torque"="इंजन टॉर्क"
    "Engine responsiveness"="इंजन प्रतिक्रिया"
    "Engine fuel consumption"="इंजन ईंधन खपत"
    "Truck fuel capacity"="ट्रक ईंधन क्षमता"
    "Maximum steering angle"="अधिकतम स्टीयरिंग कोण"
    "Steering response"="स्टीयरिंग प्रतिक्रिया"
    "GEARBOX"="गियरबॉक्स"
    "Gearbox fuel consumption"="गियरबॉक्स ईंधन खपत"
    "AWD fuel penalty"="AWD ईंधन दंड"
    "Idle fuel use"="आइडल ईंधन खपत"
    "Always AWD"="हमेशा AWD"
    "Always differential lock (unchecked = default)"="हमेशा डिफरेंशियल लॉक (अनचेक = डिफ़ॉल्ट)"
    "Extreme durability (GLOBAL)"="अत्यधिक टिकाऊपन (वैश्विक)"
    "TIRES"="टायर"
    "Tire asphalt grip"="डामर पकड़"
    "Tire off-road grip"="ऑफ-रोड पकड़"
    "Tire mud grip"="कीचड़ पकड़"
    "All tires ignore ice"="सभी टायर बर्फ को अनदेखा करें"
    "SUSPENSION"="सस्पेंशन"
    "Suspension strength"="सस्पेंशन मजबूती"
    "Suspension height"="सस्पेंशन ऊँचाई"
    "Suspension damping"="सस्पेंशन डैम्पिंग"
    "Suspension durability"="सस्पेंशन टिकाऊपन"
    "RECOVERY & CRANES"="रिकवरी और क्रेन"
    "Winch strength"="विंच मजबूती"
    "Winch length"="विंच लंबाई"
    "Crane strength"="क्रेन मजबूती"
    "Crane speed"="क्रेन गति"
    "Autonomous winches"="स्वचालित विंच"
    "TRUCK ACCESS"="ट्रक एक्सेस"
    "Unlock all trucks"="सभी ट्रक अनलॉक करें"
    "All trucks in all regions"="सभी क्षेत्रों में सभी ट्रक"
    "MORE PERFORMANCE & DURABILITY"="अधिक प्रदर्शन और टिकाऊपन"
    "Gear tuning"="गियर ट्यूनिंग"
    "Engine durability"="इंजन टिकाऊपन"
    "Gearbox durability"="गियरबॉक्स टिकाऊपन"
    "Tire durability"="टायर टिकाऊपन"
    "Fuel tank durability"="ईंधन टैंक टिकाऊपन"
    "SERVICE & CARGO"="सर्विस और कार्गो"
    "Service fuel capacity"="सर्विस ईंधन क्षमता"
    "Service water capacity"="सर्विस पानी क्षमता"
    "Service repair points"="मरम्मत अंक"
    "Service spare wheels"="अतिरिक्त पहिए"
    "Cargo mass"="कार्गो द्रव्यमान"
    "ECONOMY & UPGRADES"="अर्थव्यवस्था और अपग्रेड"
    "Truck prices"="ट्रक कीमतें"
    "Upgrade/addon prices"="अपग्रेड/ऐडऑन कीमतें"
    "Unlock all upgrades/addons"="सभी अपग्रेड/ऐडऑन अनलॉक करें"
    "STABILITY"="स्थिरता"
    "Truck center-of-gravity drop"="ट्रक गुरुत्व-केंद्र नीचे करें"
    "Addon/trailer center-of-gravity drop"="ऐडऑन/ट्रेलर गुरुत्व-केंद्र नीचे करें"
    "QUICK PRESETS"="त्वरित प्रीसेट"
    "Vanilla / Reset"="मूल / रीसेट"
    "Enhanced"="उन्नत"
    "Overpowered"="अत्यधिक शक्तिशाली"
    "Your last applied values are saved automatically."="अंतिम लागू मान अपने आप सहेजे जाते हैं।"
    "Preview Changes"="बदलाव देखें"
    "Restore Original"="मूल बहाल करें"
    "Check for Updates"="अपडेट जाँचें"
    "APPLY MODS"="मॉड लागू करें"
    "Ready."="तैयार।"
    "Checking updates..."="अपडेट जाँचे जा रहे हैं..."
    "Language saved. Restart the editor to apply the interface translation."="भाषा सहेजी गई। इंटरफ़ेस अनुवाद लागू करने के लिए एडिटर को पुनः शुरू करें।"
    "Stock"="मूल"
    "Mild"="हल्का"
    "Performance"="प्रदर्शन"
    "High Performance"="उच्च प्रदर्शन"
    "Extreme"="अत्यधिक"
}
# Startup-safe language catalog.  Keep this as a simple array rather than an OrderedDictionary
# so Windows PowerShell 5.1 does not depend on collection-specific key methods during startup.
$script:LanguageList = @(
    [PSCustomObject]@{ Code='en-US'; Name='English' },
    [PSCustomObject]@{ Code='ru-RU'; Name='Русский' },
    [PSCustomObject]@{ Code='de-DE'; Name='Deutsch' },
    [PSCustomObject]@{ Code='fr-FR'; Name='Français' },
    [PSCustomObject]@{ Code='es-ES'; Name='Español' },
    [PSCustomObject]@{ Code='pl-PL'; Name='Polski' },
    [PSCustomObject]@{ Code='pt-BR'; Name='Português (Brasil)' },
    [PSCustomObject]@{ Code='zh-CN'; Name='简体中文' },
    [PSCustomObject]@{ Code='ja-JP'; Name='日本語' },
    [PSCustomObject]@{ Code='ko-KR'; Name='한국어' },
    [PSCustomObject]@{ Code='it-IT'; Name='Italiano' },
    [PSCustomObject]@{ Code='tr-TR'; Name='Türkçe' },
    [PSCustomObject]@{ Code='uk-UA'; Name='Українська' },
    [PSCustomObject]@{ Code='cs-CZ'; Name='Čeština' },
    [PSCustomObject]@{ Code='hi-IN'; Name='हिन्दी' }
)
function L([string]$Text) {
    if ($script:Language -ne 'en-US' -and
        $script:Translations.ContainsKey($script:Language) -and
        $script:Translations[$script:Language].ContainsKey($Text)) {
        return [string]$script:Translations[$script:Language][$Text]
    }
    return $Text
}
function Save-Language {
    try { [IO.File]::WriteAllText($script:LanguagePath, $script:Language, [Text.UTF8Encoding]::new($false)) } catch {}
}
function Load-Language {
    try {
        if (Test-Path -LiteralPath $script:LanguagePath) {
            $v = (Get-Content -LiteralPath $script:LanguagePath -Raw).Trim()
            if (@($script:LanguageList | ForEach-Object { $_.Code }) -contains $v) { $script:Language = $v }
        }
    } catch {}
}
Load-Language

function Format-Number([double]$Value) {
    return $Value.ToString('0.############', [Globalization.CultureInfo]::InvariantCulture)
}

function Read-Multiplier([string]$Name) {
    $raw = $script:Fields[$Name].Text.Trim()
    $value = 0.0
    if (-not [double]::TryParse($raw, [Globalization.NumberStyles]::Float, [Globalization.CultureInfo]::InvariantCulture, [ref]$value)) {
        throw "'$raw' is not a valid value for $Name. Use a number such as 1.25."
    }
    if ($value -lt 0 -or $value -gt 100) {
        throw "$Name must be between 0 and 100."
    }
    return $value
}

function Read-Offset([string]$Name) {
    $value = Read-Multiplier $Name
    if ($value -gt 5) { throw "$Name must be between 0.00 and 5.00 meters." }
    return $value
}

function Get-Settings {
    $selectedTruckText = if ($cmbTruck.SelectedItem) { [string]$cmbTruck.SelectedItem } else { (L 'All Trucks') }
    if ($selectedTruckText -eq (L 'All Trucks')) { $selectedTruckText = 'All Trucks' }
    $isCategoryTarget = ($script:CategoryTargets -and $script:CategoryTargets.ContainsKey($selectedTruckText))
    $categoryIds = $(if ($isCategoryTarget) { @($script:CategoryTargets[$selectedTruckText]) } else { @() })
    $isModTarget = ($selectedTruckText -like '[[]MOD[]]*')
    $modTarget = $null
    if ($isModTarget) {
        if (-not $script:ModTruckTargets -or -not $script:ModTruckTargets.ContainsKey($selectedTruckText)) {
            throw 'v1.2.0 safety stop: the selected mod truck is no longer mapped to an installed mod PAK. Run Scan Mods again.'
        }
        $modTarget = $script:ModTruckTargets[$selectedTruckText]
        if (-not (Test-Path -LiteralPath $modTarget.Source -PathType Leaf)) {
            throw 'v1.2.0 safety stop: the selected mod PAK is no longer installed. Run Scan Mods again.'
        }
    }
    return [ordered]@{
        SettingsVersion = 2
        PakPath = $txtPak.Text.Trim()
        IsModTarget = [bool]$isModTarget
        IsCategoryTarget = [bool]$isCategoryTarget
        TargetTruckIds = @($categoryIds)
        ModPakPath = $(if ($isModTarget) { [string]$modTarget.Source } else { '' })
        TargetTruck = $selectedTruckText
        TargetTruckId = $(
            if ($selectedTruckText -eq 'All Trucks' -or $isCategoryTarget) { '' }
            elseif ($isModTarget) { [string]$modTarget.Id }
            elseif ($script:TruckTargets.ContainsKey($selectedTruckText)) { [string]$script:TruckTargets[$selectedTruckText] }
            elseif ($selectedTruckText -match '\[([^\[\]]+)\]\s*$') { [string]$Matches[1] }
            else { throw "v1.2.0 safety stop: a specific truck is selected, but its internal truck ID could not be resolved. No modifications were made." }
        )
        TargetTruckEntry = $(if ($isModTarget) { [string]$modTarget.Entry } else { '' })
        IndividualServiceAddonEntries = @()
        IndividualCraneAddonEntries = @()
        CategoryUpgradeEntries = @()
        IndividualEngineSourceEntry = ''
        IndividualEngineSourceEntries = @()
        IndividualEngineTypes = @()
        IndividualEngineCloneEntry = ''
        IndividualEngineCloneType = ''
        SharedEngineType = ''
        SharedEngineTruckUsers = 0
        SharedGearboxType = ''
        SharedGearboxTypes = @()
        IndividualGearboxSourceEntries = @()
        SharedGearboxDefault = ''
        SharedGearboxTruckUsers = 0
        SkippedUnsupportedGearTuning = ''
        SkippedInheritedGearboxTypes = @()
        SkippedInheritedEngineTypes = @()
        SkippedUnsupportedEngine = ''
        SkippedInheritedWheelType = ''
        SkippedUnsupportedTires = ''
        SkippedInheritedSuspensionTypes = @()
        SkippedUnsupportedSuspension = ''
        SkippedUnsupportedServiceEquipment = ''
        SkippedUnsupportedCrane = ''
        SkippedUnsupportedWinch = ''
        SkippedUnsupportedGearbox = ''
        IndividualTireSourceEntry = ''
        IndividualTireDefault = ''
        IndividualTireWheelType = ''
        IndividualTirePrivateName = ''
        IndividualWheelSourceEntry = ''
        IndividualWheelType = ''
        IndividualWheelPrivateType = ''
        IndividualWheelPrivateEntry = ''
        TestStockWheelSwap = [bool]$chkStockWheelSwap.Checked
        TestStockWheelSwapType = ''
        TestStockWheelSwapTire = ''
        EngineTorque = Read-Multiplier 'Engine torque'
        EngineResponse = Read-Multiplier 'Engine responsiveness'
        EngineFuel = Read-Multiplier 'Engine fuel consumption'
        EngineDurability = Read-Multiplier 'Engine durability'
        GearboxFuel = Read-Multiplier 'Gearbox fuel consumption'
        GearTuning = if ($script:Combos.ContainsKey('Gear tuning') -and $script:Combos['Gear tuning'].SelectedItem) { [string]$script:Combos['Gear tuning'].SelectedItem } else { 'Stock' }
        GearSpeed = Get-GearTuningFactor $(if ($script:Combos.ContainsKey('Gear tuning') -and $script:Combos['Gear tuning'].SelectedItem) { [string]$script:Combos['Gear tuning'].SelectedItem } else { 'Stock' })
        GearboxDurability = Read-Multiplier 'Gearbox durability'
        AwdFuel = Read-Multiplier 'AWD fuel penalty'
        IdleFuel = Read-Multiplier 'Idle fuel use'
        SteeringAngle = Read-Multiplier 'Maximum steering angle'
        SteeringResponse = Read-Multiplier 'Steering response'
        TireAsphalt = Read-Multiplier 'Tire asphalt grip'
        TireOffroad = Read-Multiplier 'Tire off-road grip'
        TireMud = Read-Multiplier 'Tire mud grip'
        TireDurability = Read-Multiplier 'Tire durability'
        AllTiresIgnoreIce = $script:Checks['All tires ignore ice'].Checked
        SuspensionStrength = Read-Multiplier 'Suspension strength'
        SuspensionHeight = Read-Multiplier 'Suspension height'
        SuspensionDamping = Read-Multiplier 'Suspension damping'
        SuspensionDurability = Read-Multiplier 'Suspension durability'
        FuelCapacity = Read-Multiplier 'Truck fuel capacity'
        FuelTankDurability = Read-Multiplier 'Fuel tank durability'
        WinchStrength = Read-Multiplier 'Winch strength'
        WinchLength = Read-Multiplier 'Winch length'
        CraneStrength = Read-Multiplier 'Crane strength'
        CraneSpeed = Read-Multiplier 'Crane speed'
        ServiceFuel = Read-Multiplier 'Service fuel capacity'
        ServiceWater = Read-Multiplier 'Service water capacity'
        ServiceRepairs = Read-Multiplier 'Service repair points'
        ServiceWheels = Read-Multiplier 'Service spare wheels'
        CargoMass = Read-Multiplier 'Cargo mass'
        TruckPrice = Read-Multiplier 'Truck prices'
        UpgradePrice = Read-Multiplier 'Upgrade/addon prices'
        TruckCgDrop = Read-Offset 'Truck center-of-gravity drop'
        AddonCgDrop = Read-Offset 'Addon/trailer center-of-gravity drop'
        AlwaysAWD = $script:Checks['Always AWD'].Checked
        AlwaysDiff = $script:Checks['Always differential lock (unchecked = default)'].Checked
        DisableAllDamage = $script:Checks['Extreme durability (GLOBAL)'].Checked
        AutonomousWinches = $script:Checks['Autonomous winches'].Checked
        UnlockTrucks = $script:Checks['Unlock all trucks'].Checked
        AllRegions = $script:Checks['All trucks in all regions'].Checked
        UnlockUpgrades = $script:Checks['Unlock all upgrades/addons'].Checked
    }
}

function Save-Settings($Settings) {
    $Settings | ConvertTo-Json | Set-Content -LiteralPath $script:SettingsPath -Encoding UTF8
}

function Load-Settings {
    if (-not (Test-Path -LiteralPath $script:SettingsPath)) { return }
    try {
        $s = Get-Content -LiteralPath $script:SettingsPath -Raw | ConvertFrom-Json
        if ($s.PakPath) { $txtPak.Text = $s.PakPath }
        $map = @{
            'Engine torque'='EngineTorque'; 'Engine responsiveness'='EngineResponse'; 'Engine fuel consumption'='EngineFuel'
            'Engine durability'='EngineDurability'; 'Gearbox fuel consumption'='GearboxFuel'; 'Gearbox durability'='GearboxDurability'; 'AWD fuel penalty'='AwdFuel'; 'Idle fuel use'='IdleFuel'
            'Maximum steering angle'='SteeringAngle'; 'Steering response'='SteeringResponse'
            'Tire asphalt grip'='TireAsphalt'; 'Tire off-road grip'='TireOffroad'; 'Tire mud grip'='TireMud'; 'Tire durability'='TireDurability'
            'Suspension strength'='SuspensionStrength'; 'Suspension height'='SuspensionHeight'; 'Suspension damping'='SuspensionDamping'
            'Suspension durability'='SuspensionDurability'; 'Truck fuel capacity'='FuelCapacity'; 'Fuel tank durability'='FuelTankDurability'
            'Winch strength'='WinchStrength'; 'Winch length'='WinchLength'; 'Crane strength'='CraneStrength'; 'Crane speed'='CraneSpeed'
            'Service fuel capacity'='ServiceFuel'; 'Service water capacity'='ServiceWater'; 'Service repair points'='ServiceRepairs'; 'Service spare wheels'='ServiceWheels'
            'Cargo mass'='CargoMass'; 'Truck prices'='TruckPrice'; 'Upgrade/addon prices'='UpgradePrice'
            'Truck center-of-gravity drop'='TruckCgDrop'; 'Addon/trailer center-of-gravity drop'='AddonCgDrop'
        }
        foreach ($name in $map.Keys) {
            $prop = $map[$name]
            if ($null -ne $s.$prop) { $script:Fields[$name].Text = Format-Number ([double]$s.$prop) }
        }
        if ($script:Combos.ContainsKey('Gear tuning')) {
            $gp = if ($s.GearTuning) { [string]$s.GearTuning } else { 'Stock' }
            if ($script:Combos['Gear tuning'].Items.Contains($gp)) { $script:Combos['Gear tuning'].SelectedItem = $gp } else { $script:Combos['Gear tuning'].SelectedItem = 'Stock' }
        }
        $checks = @{'Always AWD'='AlwaysAWD';'Always differential lock (unchecked = default)'='AlwaysDiff';'Extreme durability (GLOBAL)'='DisableAllDamage';'Autonomous winches'='AutonomousWinches';'Unlock all trucks'='UnlockTrucks';'All trucks in all regions'='AllRegions';'Unlock all upgrades/addons'='UnlockUpgrades';'All tires ignore ice'='AllTiresIgnoreIce'}
        foreach ($name in $checks.Keys) {
            $prop = $checks[$name]
            # Do not carry legacy differential settings into this format.
            if ($prop -eq 'AlwaysDiff' -and ([int]$s.SettingsVersion -lt 2)) { continue }
            if ($null -ne $s.$prop) { $script:Checks[$name].Checked = [bool]$s.$prop }
        }
    } catch {
        $lblStatus.Text = 'Could not load saved settings; defaults are active.'
    }
}

function Add-Count($Counts, [string]$Name, [int]$Amount) {
    if ($Amount -le 0) { return }
    if (-not $Counts.ContainsKey($Name)) { $Counts[$Name] = 0 }
    $Counts[$Name] += $Amount
}

function Replace-NumericAttribute([string]$Text, [string]$Attribute, [double]$Multiplier, $Counts, [string]$Label) {
    if ([math]::Abs($Multiplier - 1.0) -lt 0.0000001) { return $Text }
    $pattern = '(?i)(\b' + [regex]::Escape($Attribute) + '=")(-?\d+(?:\.\d+)?)(")'
    $hits = 0
    $result = [regex]::Replace($Text, $pattern, {
        param($m)
        $scriptValue = [double]::Parse($m.Groups[2].Value, [Globalization.CultureInfo]::InvariantCulture)
        $newValue = Format-Number ($scriptValue * $Multiplier)
        $script:hitsForReplacement++
        return $m.Groups[1].Value + $newValue + $m.Groups[3].Value
    })
    # Evaluators execute in a child scope, so count matches independently.
    $hits = [regex]::Matches($Text, $pattern).Count
    Add-Count $Counts $Label $hits
    return $result
}



# CATEGORY PRESERVATION FIX 2E:
# Force a numeric attribute to the value derived from the pristine baseline, while
# preserving every other byte/value in the current-live XML. This is deliberately
# occurrence-based because these SnowRunner resource files can contain repeated
# capacities. It prevents category overlap from multiplying an already-modified
# live value a second (or fifth) time.
function Set-NumericAttributeFromBaseline([string]$BaselineText,[string]$CurrentText,[string]$Attribute,[double]$Multiplier,$Counts,[string]$Label) {
    if ([math]::Abs($Multiplier - 1.0) -lt 0.0000001) { return $CurrentText }
    $pattern='(?i)(\b'+[regex]::Escape($Attribute)+'=")(-?\d+(?:\.\d+)?)(")'
    $bm=[regex]::Matches($BaselineText,$pattern)
    $cm=[regex]::Matches($CurrentText,$pattern)
    # FIX 2E: PowerShell single-quoted regex strings need ONE backslash for regex tokens.
    # FIX 2D accidentally used \\b / \\d, which searched for literal backslashes and
    # silently produced zero matches. The baseline lock therefore never touched the four
    # overlapping WheelRepairsCapacity values. Fail closed if baseline has the attribute
    # but our matcher somehow cannot see it.
    if($BaselineText -match ('(?i)\b'+[regex]::Escape($Attribute)+'\s*=') -and $bm.Count -lt 1){throw "CATEGORY PRESERVATION FIX 2E safety stop: baseline contains '$Attribute' but the baseline-lock matcher found zero occurrences. Live PAK was NOT replaced."}
    if($bm.Count -ne $cm.Count){throw "CATEGORY PRESERVATION FIX 2E safety stop: baseline/current '$Attribute' occurrence count differs ($($bm.Count) vs $($cm.Count)). Live PAK was NOT replaced."}
    $result=$CurrentText;$changed=0
    for($i=$cm.Count-1;$i -ge 0;$i--){
        $base=[double]::Parse($bm[$i].Groups[2].Value,[Globalization.CultureInfo]::InvariantCulture)
        $expected=Format-Number ($base*$Multiplier)
        if($cm[$i].Groups[2].Value -cne $expected){$changed++}
        $start=$cm[$i].Groups[2].Index;$len=$cm[$i].Groups[2].Length
        $result=$result.Substring(0,$start)+$expected+$result.Substring($start+$len)
    }
    Add-Count $Counts $Label $changed
    return $result
}

function Set-WheelFrictionIgnoreIce([string]$Text, $Counts, [string]$Label) {
    # DEV43: SnowRunner's chained-tire behavior uses IsIgnoreIce="true" on
    # WheelFriction definitions. Preserve every existing friction value and
    # only add/normalize this native boolean on actual <WheelFriction> tags.
    $changed = 0
    $result = [regex]::Replace($Text, '(?is)<WheelFriction\b[^>]*>', {
        param($m)
        $tag = $m.Value
        if ($tag -match '(?i)\bIsIgnoreIce\s*=\s*"true"') { return $tag }
        if ($tag -match '(?i)\bIsIgnoreIce\s*=\s*"(?:false|0|1)"') {
            $script:wlIgnoreIceHits++
            return [regex]::Replace($tag, '(?i)(\bIsIgnoreIce\s*=\s*")[^"]*(")', '${1}true${2}')
        }
        $script:wlIgnoreIceHits++
        if ($tag.EndsWith('/>')) { return $tag.Substring(0,$tag.Length-2) + ' IsIgnoreIce="true" />' }
        return $tag.Substring(0,$tag.Length-1) + ' IsIgnoreIce="true">'
    })
    $changed=[int]$script:wlIgnoreIceHits; $script:wlIgnoreIceHits=0
    Add-Count $Counts $Label $changed
    return $result
}

function Compensate-SuspensionCamberForHeight([string]$Text, [double]$HeightMultiplier, $Counts) {
    # v1.1.2 RC4 EXPERIMENTAL:
    # Some trucks (notably the Tatra suspension architecture) intentionally couple
    # rendered wheel camber to suspension position through CamberSuspensionMultiplier.
    # When Suspension Height is multiplied, preserve the stock suspension-to-camber
    # contribution by inversely scaling ONLY existing CamberSuspensionMultiplier values.
    # Do not inject camber attributes and do not touch CamberAngleRender/Physics.
    if ([math]::Abs($HeightMultiplier - 1.0) -lt 0.0000001 -or $HeightMultiplier -le 0) { return $Text }
    $pattern = '(?i)(\bCamberSuspensionMultiplier=")(-?\d+(?:\.\d+)?)(")'
    $hits = [regex]::Matches($Text, $pattern).Count
    if ($hits -lt 1) { return $Text }
    $result = [regex]::Replace($Text, $pattern, {
        param($m)
        $v = [double]::Parse($m.Groups[2].Value, [Globalization.CultureInfo]::InvariantCulture)
        $newValue = Format-Number ($v / $HeightMultiplier)
        return $m.Groups[1].Value + $newValue + $m.Groups[3].Value
    })
    Add-Count $Counts 'Suspension-height camber compensation (EXPERIMENTAL)' $hits
    return $result
}

function Replace-SuspensionTravelAttribute([string]$Text, [string]$Attribute, [double]$Multiplier, $Counts, [string]$Label) {
    # v1.1.2 RC3: Strength/Damping are wheel-suspension physics controls.
    # Fleet audit found a second class of articulated/zero-travel suspension entries
    # where SuspensionMax is omitted (for example CAT CT680).  The common structural
    # signature is Height="0" + SuspensionMin="0".  Do not multiply Strength/Damping
    # on those entries; normal/traveling Suspension entries remain tunable.
    # Never inject attributes.
    if ([math]::Abs($Multiplier - 1.0) -lt 0.0000001) { return $Text }
    $suspensionPattern = '(?is)<Suspension\b[^>]*>'
    $attrPattern = '(?i)(\b' + [regex]::Escape($Attribute) + '=")(-?\d+(?:\.\d+)?)(")'
    $result = [regex]::Replace($Text, $suspensionPattern, {
        param($m)
        $tag = $m.Value
        $height = [regex]::Match($tag, '(?i)\bHeight="\s*(-?\d+(?:\.\d+)?)\s*"')
        $min = [regex]::Match($tag, '(?i)\bSuspensionMin="\s*(-?\d+(?:\.\d+)?)\s*"')
        if ($height.Success -and $min.Success) {
            $heightValue = [double]::Parse($height.Groups[1].Value, [Globalization.CultureInfo]::InvariantCulture)
            $minValue = [double]::Parse($min.Groups[1].Value, [Globalization.CultureInfo]::InvariantCulture)
            if ([math]::Abs($heightValue) -lt 0.0000001 -and [math]::Abs($minValue) -lt 0.0000001) {
                return $tag
            }
        }
        return [regex]::Replace($tag, $attrPattern, {
            param($a)
            $scriptValue = [double]::Parse($a.Groups[2].Value, [Globalization.CultureInfo]::InvariantCulture)
            $newValue = Format-Number ($scriptValue * $Multiplier)
            return $a.Groups[1].Value + $newValue + $a.Groups[3].Value
        })
    })
    # Count only eligible Suspension tags containing the requested attribute.
    $changed = 0
    foreach ($m in [regex]::Matches($Text, $suspensionPattern)) {
        $tag = $m.Value
        $height = [regex]::Match($tag, '(?i)\bHeight="\s*(-?\d+(?:\.\d+)?)\s*"')
        $min = [regex]::Match($tag, '(?i)\bSuspensionMin="\s*(-?\d+(?:\.\d+)?)\s*"')
        $skip = $false
        if ($height.Success -and $min.Success) {
            $heightValue = [double]::Parse($height.Groups[1].Value, [Globalization.CultureInfo]::InvariantCulture)
            $minValue = [double]::Parse($min.Groups[1].Value, [Globalization.CultureInfo]::InvariantCulture)
            $skip = ([math]::Abs($heightValue) -lt 0.0000001 -and [math]::Abs($minValue) -lt 0.0000001)
        }
        if (-not $skip -and [regex]::IsMatch($tag, $attrPattern)) { $changed++ }
    }
    Add-Count $Counts $Label $changed
    return $result
}


# CATEGORY PRESERVATION FIX 2C / SUSPENSION DAMPING:
# Dedicated literal-safe damping transformer.  The generic suspension helper correctly
# handled Strength, but the final PAK audit proved Damping was being counted without
# surviving into installed XML.  This routine edits only existing Damping attributes on
# eligible traveling <Suspension> tags and verifies every intended value before returning.
function Replace-SuspensionDampingVerified([string]$Text, [double]$Multiplier, $Counts, [string]$Label) {
    if ([math]::Abs($Multiplier - 1.0) -lt 0.0000001) { return $Text }
    $tagPattern='(?is)<Suspension\b[^>]*>'
    $dampPattern='(?i)\bDamping\s*=\s*"(-?\d+(?:\.\d+)?)"'
    $changed=0
    $result=[regex]::Replace($Text,$tagPattern,{
        param($tm)
        $tag=[string]$tm.Value
        $height=[regex]::Match($tag,'(?i)\bHeight="\s*(-?\d+(?:\.\d+)?)\s*"')
        $min=[regex]::Match($tag,'(?i)\bSuspensionMin="\s*(-?\d+(?:\.\d+)?)\s*"')
        if($height.Success -and $min.Success){
            $hv=[double]::Parse($height.Groups[1].Value,[Globalization.CultureInfo]::InvariantCulture)
            $mv=[double]::Parse($min.Groups[1].Value,[Globalization.CultureInfo]::InvariantCulture)
            if([math]::Abs($hv) -lt 0.0000001 -and [math]::Abs($mv) -lt 0.0000001){return $tag}
        }
        $dm=[regex]::Match($tag,$dampPattern)
        if(-not $dm.Success){return $tag}
        $old=[double]::Parse($dm.Groups[1].Value,[Globalization.CultureInfo]::InvariantCulture)
        $want=Format-Number ($old*$Multiplier)
        $literal='Damping="'+$want+'"'
        $tag=$tag.Substring(0,$dm.Index)+$literal+$tag.Substring($dm.Index+$dm.Length)
        $script:wlDamping2CHits++
        return $tag
    })
    $changed=[int]$script:wlDamping2CHits; $script:wlDamping2CHits=0
    if($changed -gt 0){
        # Fail closed if the transformer claimed work but returned byte-identical text.
        if($result -ceq $Text){throw 'CATEGORY PRESERVATION FIX 2C safety stop: suspension damping was counted but no XML value changed. Live PAK was NOT replaced.'}
        Add-Count $Counts $Label $changed
    }
    return $result
}

function Get-GearTuningFactor([string]$Profile) {
    switch ($Profile) {
        'Mild' { return 1.20 }
        'Performance' { return 1.35 }
        'High Performance' { return 1.50 }
        'Extreme' { return 1.75 }
        default { return 1.00 }
    }
}

function Tune-GearboxProgression([string]$Text, [double]$TopFactor, $Counts, [string]$Label) {
    # RC3.5: Gear Tuning is a bounded transmission profile, not a raw multiplier.
    # Each gearbox variant keeps its original first gear, gains ONE forward gear,
    # and its intermediate forward gears are re-sampled from the stock progression.
    # This preserves launch ability while tightening the ratios and mildly extending top end.
    if ([math]::Abs($TopFactor - 1.0) -lt 0.0000001) { return $Text }
    $gearboxPattern='(?is)<Gearbox\b[^>]*\bName="[^"]+"[^>]*>.*?</Gearbox>'
    $gearPattern='(?is)<Gear\b[^>]*/?>'
    $angPattern='(?i)(\bAngVel=")(-?\d*\.?\d+)(")'
    $fuelPattern='(?i)(\bFuelModifier=")(-?\d*\.?\d+)(")'
    $variants=[regex]::Matches($Text,$gearboxPattern)
    if($variants.Count -lt 1){throw 'RC3.5 Gear Tuning safety stop: no gearbox variants were found.'}
    $changedVariants=0; $newGearCount=0; $retuned=0
    $result=[regex]::Replace($Text,$gearboxPattern,{
        param($gb)
        $block=$gb.Value
        $gm=[regex]::Matches($block,$gearPattern)
        $n=$gm.Count
        if($n -lt 2){return $block}
        $vals=New-Object Collections.Generic.List[double]
        $fuels=New-Object Collections.Generic.List[string]
        foreach($g in $gm){
            $am=[regex]::Match($g.Value,$angPattern); if(-not $am.Success){return $block}
            $vals.Add([double]::Parse($am.Groups[2].Value,[Globalization.CultureInfo]::InvariantCulture))
            $fm=[regex]::Match($g.Value,$fuelPattern); $fuels.Add($(if($fm.Success){$fm.Groups[2].Value}else{'1.0'}))
        }
        $newVals=New-Object Collections.Generic.List[double]
        # N stock gears become N+1. Sample the original curve at N+1 positions;
        # the final point is the bounded extended top gear.
        for($i=0;$i -le $n;$i++){
            if($i -eq $n){$newVals.Add($vals[$n-1]*$TopFactor);continue}
            $pos=([double]$i*($n-1))/$n
            $lo=[int][math]::Floor($pos); $hi=[int][math]::Ceiling($pos)
            if($hi -ge $n){$hi=$n-1}
            $frac=$pos-$lo
            $v=$vals[$lo]+(($vals[$hi]-$vals[$lo])*$frac)
            $newVals.Add($v)
        }
        $sb=New-Object Text.StringBuilder
        $cursor=0
        for($i=0;$i -lt $n;$i++){
            $g=$gm[$i]
            [void]$sb.Append($block.Substring($cursor,$g.Index-$cursor))
            $gv=$g.Value
            $fmt=Format-Number $newVals[$i]
            $gv=[regex]::Replace($gv,$angPattern,{param($m)$m.Groups[1].Value+$fmt+$m.Groups[3].Value},1)
            [void]$sb.Append($gv); $cursor=$g.Index+$g.Length
        }
        # append one extra top gear after the last stock gear position
        $last=$gm[$n-1]; $newTop=Format-Number $newVals[$n]; $fuel=$fuels[$n-1]
        [void]$sb.Append("`r`n`t`t")
        [void]$sb.Append(('<Gear AngVel="'+$newTop+'" FuelModifier="'+$fuel+'" />'))
        [void]$sb.Append($block.Substring($cursor))
        return $sb.ToString()
    })
    foreach($gb in $variants){$n=[regex]::Matches($gb.Value,$gearPattern).Count;if($n -ge 2){$changedVariants++;$newGearCount++;$retuned += ($n-1)}}
    if($changedVariants -lt 1 -or $result -ceq $Text){throw 'RC3.5 Gear Tuning safety stop: no gearbox progressions were changed.'}
    Add-Count $Counts $Label $changedVariants
    Add-Count $Counts 'Extra forward gears added' $newGearCount
    Add-Count $Counts 'Intermediate forward gears re-spaced' $retuned
    Add-Count $Counts 'Launch gears preserved stock' $changedVariants
    return $result
}

function Replace-InverseNumericAttribute([string]$Text, [string]$Attribute, [double]$Multiplier, $Counts, [string]$Label) {
    if ([math]::Abs($Multiplier - 1.0) -lt 0.0000001) { return $Text }
    if ($Multiplier -le 0) { throw "$Label must be greater than zero." }
    $pattern = '(?i)(\b' + [regex]::Escape($Attribute) + '=")(-?\d*\.?\d+)(")'
    $hits = [regex]::Matches($Text, $pattern).Count
    $result = [regex]::Replace($Text, $pattern, {
        param($m)
        $value = [double]::Parse($m.Groups[2].Value, [Globalization.CultureInfo]::InvariantCulture)
        return $m.Groups[1].Value + (Format-Number ($value / $Multiplier)) + $m.Groups[3].Value
    })
    Add-Count $Counts $Label $hits
    return $result
}

function Lower-CenterOfMass([string]$Text, [double]$Drop, $Counts, [string]$Label) {
    if ($Drop -le 0) { return $Text }
    # SnowRunner vectors are (forward/back; vertical; left/right).
    # Current files contain both semicolon and legacy comma vector separators.
    $pattern = '(?i)(\bCenterOfMassOffset="\(\s*[^;,"]+\s*[;,]\s*)(-?\d*\.?\d+)(\s*[;,][^"]+\)")'
    $hits = [regex]::Matches($Text, $pattern).Count
    $result = [regex]::Replace($Text, $pattern, {
        param($m)
        $vertical = [double]::Parse($m.Groups[2].Value, [Globalization.CultureInfo]::InvariantCulture)
        return $m.Groups[1].Value + (Format-Number ($vertical - $Drop)) + $m.Groups[3].Value
    })
    Add-Count $Counts $Label $hits
    return $result
}


function Lower-AddonTrailerPrimaryCenterOfMass([string]$Text, [double]$Drop, $Counts, [string]$Label) {
    if ([math]::Abs($Drop) -lt 0.0000001) { return $Text }
    # v1.1.2 hotfix: addon/trailer COG must never move nested articulated bodies.
    # Modify only the first (primary) <Body> directly inside <PhysicsModel>, and only
    # when that body already defines CenterOfMassOffset. Never inject a new COG.
    $pm = [regex]::Match($Text, '(?is)<PhysicsModel\b[^>]*>')
    if (-not $pm.Success) { return $Text }
    $searchStart = $pm.Index + $pm.Length
    $tail = $Text.Substring($searchStart)
    $bodyRel = [regex]::Match($tail, '(?is)<Body\b[^>]*>')
    if (-not $bodyRel.Success) { return $Text }
    $body = $bodyRel
    $bodyAbsoluteIndex = $searchStart + $bodyRel.Index
    $com = [regex]::Match($body.Value, '(?i)(\bCenterOfMassOffset="\(\s*[^;,"]+\s*[;,]\s*)(-?\d*\.?\d+)(\s*[;,][^"]+\)")')
    if (-not $com.Success) { return $Text }
    $old = [double]::Parse($com.Groups[2].Value, [Globalization.CultureInfo]::InvariantCulture)
    $new = Format-Number ($old - $Drop)
    $newTag = $body.Value.Substring(0,$com.Index) + $com.Groups[1].Value + $new + $com.Groups[3].Value + $body.Value.Substring($com.Index + $com.Length)
    Add-Count $Counts $Label 1
    return $Text.Substring(0,$bodyAbsoluteIndex) + $newTag + $Text.Substring($bodyAbsoluteIndex + $body.Length)
}

function Lower-TruckPrimaryCenterOfMass([string]$Text, [double]$Drop, $Counts, [string]$Label) {
    if ($Drop -le 0) { return $Text }

    # v1.1.2 RC1 SAFETY FIX:
    # "Truck COG" must affect only the primary/root Body of the truck's PhysicsModel.
    # v1.1.1 used a file-wide CenterOfMassOffset replacement, which also moved nested
    # cabin/articulation/constraint body COGs and can destabilize certain trucks.
    $physics = [regex]::Match($Text, '(?is)<PhysicsModel\b[^>]*>.*?</PhysicsModel>')
    if (-not $physics.Success) { return $Text }

    $body = [regex]::Match($physics.Value, '(?is)<Body\b[^>]*>')
    if (-not $body.Success) { return $Text }

    $com = [regex]::Match($body.Value, '(?i)(\bCenterOfMassOffset="\(\s*[^;,"]+\s*[;,]\s*)(-?\d*\.?\d+)(\s*[;,][^"]+\)")')
    if (-not $com.Success) { return $Text }

    $vertical = [double]::Parse($com.Groups[2].Value, [Globalization.CultureInfo]::InvariantCulture)
    $replacement = $com.Groups[1].Value + (Format-Number ($vertical - $Drop)) + $com.Groups[3].Value

    $absolute = $physics.Index + $body.Index + $com.Index
    $result = $Text.Remove($absolute, $com.Length).Insert($absolute, $replacement)
    Add-Count $Counts $Label 1
    return $result
}

function Repoint-TestStockWheelFamily([string]$Text,$S,$Counts) {
    if(-not $S.TargetTruckId -or -not $S.TestStockWheelSwap){return $Text}
    if(([string]$S.TargetTruckId).ToLowerInvariant() -ne 'freightliner_114sd'){
        throw 'TEST 6.18 safety stop: stock wheel-family substitution is intentionally limited to Freightliner 114SD.'
    }
    $newType=[string]$S.TestStockWheelSwapType
    $newTire=[string]$S.TestStockWheelSwapTire
    if(-not $newType -or -not $newTire){throw 'TEST 6.18 safety stop: stock wheel-family test plan was not resolved.'}
    $wheels=[regex]::Matches($Text,'(?is)<Wheels\b[^>]*>')
    if($wheels.Count -ne 1){throw "TEST 6.18 safety stop: expected exactly one <Wheels> tag; found $($wheels.Count)."}
    $oldTag=$wheels[0].Value
    $oldType=[regex]::Match($oldTag,'(?i)\bDefaultWheelType="([^"]+)"')
    $oldTire=[regex]::Match($oldTag,'(?i)\bDefaultTire="([^"]+)"')
    if(-not $oldType.Success -or -not $oldTire.Success){throw 'TEST 6.18 safety stop: current DefaultWheelType/DefaultTire could not be resolved.'}
    $newTag=[regex]::Replace($oldTag,'(?i)(\bDefaultWheelType=")[^"]+(" )?',{param($m) if($m.Groups[2].Success){$m.Groups[1].Value+$newType+$m.Groups[2].Value}else{$m.Groups[1].Value+$newType+'"'}})
    # Simpler exact attribute replacements after the guarded parse.
    $newTag=[regex]::Replace($oldTag,'(?i)(\bDefaultWheelType=")[^"]+(" )?',{param($m) $suffix=if($m.Groups[2].Success){$m.Groups[2].Value}else{'"'}; $m.Groups[1].Value+$newType+$suffix})
    $newTag=[regex]::Replace($newTag,'(?i)(\bDefaultTire=")[^"]+(" )?',{param($m) $suffix=if($m.Groups[2].Success){$m.Groups[2].Value}else{'"'}; $m.Groups[1].Value+$newTire+$suffix})
    if($newTag -ceq $oldTag){throw 'TEST 6.18 safety stop: wheel substitution produced no XML change.'}
    $Text=$Text.Remove($wheels[0].Index,$wheels[0].Length).Insert($wheels[0].Index,$newTag)
    Add-Count $Counts 'TEST stock DefaultWheelType substitutions' 1
    Add-Count $Counts 'TEST stock DefaultTire substitutions' 1
    return $Text
}


function Get-ExtremeDurabilityExpectedChanges([string]$PakPath) {
    # DEV27: discover what Extreme Durability can actually change in THIS source PAK.
    # Unknown third-party mods may legitimately omit a local gearbox/engine/wheel family
    # and inherit it from the base game. Do not require a component class that is not
    # represented locally, but do fail closed when a locally-applicable value was expected
    # to change and did not.
    $expected = [ordered]@{
        'GLOBAL extreme durability - engine capacities maxed' = 0
        'GLOBAL extreme durability - gearbox capacities maxed' = 0
        'GLOBAL extreme durability - suspension capacities maxed' = 0
        'GLOBAL extreme durability - wheel capacities maxed' = 0
        'GLOBAL extreme durability - fuel tank capacities maxed' = 0
    }
    $fs=$null; $zip=$null
    try {
        $fs=[IO.File]::OpenRead($PakPath)
        $zip=New-Object IO.Compression.ZipArchive($fs,[IO.Compression.ZipArchiveMode]::Read)
        foreach($e in $zip.Entries){
            if(-not $e.FullName.ToLowerInvariant().EndsWith('.xml')){continue}
            $n=$e.FullName.Replace('/','\').ToLowerInvariant()
            $r=New-Object IO.StreamReader($e.Open(),[Text.Encoding]::UTF8,$true)
            try{$t=$r.ReadToEnd()}finally{$r.Dispose()}
            if($n -match '(?:^|\\)classes\\engines\\[^\\]+\.xml$') {
                $expected['GLOBAL extreme durability - engine capacities maxed'] += [regex]::Matches($t,'(?i)\bDamageCapacity="(?!64000(?:\.0+)?")-?\d+(?:\.\d+)?"').Count
                continue
            }
            if($n -match '(?:^|\\)classes\\gearboxes\\[^\\]+\.xml$') {
                $expected['GLOBAL extreme durability - gearbox capacities maxed'] += [regex]::Matches($t,'(?i)\bDamageCapacity="(?!64000(?:\.0+)?")-?\d+(?:\.\d+)?"').Count
                continue
            }
            if($n -match '(?:^|\\)classes\\wheels\\[^\\]+\.xml$') {
                foreach($m in [regex]::Matches($t,'(?is)<TruckWheels?\b[^>]*>')){
                    if($m.Value -match '(?i)\bDamageCapacity="-?\d+(?:\.\d+)?"' -and $m.Value -notmatch '(?i)\bDamageCapacity="64000(?:\.0+)?"'){
                        $expected['GLOBAL extreme durability - wheel capacities maxed']++
                    }
                }
                continue
            }
            if($n -match '(?:^|\\)classes\\suspensions\\[^\\]+\.xml$') {
                foreach($m in [regex]::Matches($t,'(?is)<SuspensionSet\b[^>]*>')){
                    if($m.Value -notmatch '(?i)\bDamageCapacity="64000(?:\.0+)?"'){
                        $expected['GLOBAL extreme durability - suspension capacities maxed']++
                    }
                }
                continue
            }
            if($n -match '(?:^|\\)classes\\trucks\\[^\\]+\.xml$') {
                foreach($m in [regex]::Matches($t,'(?is)<FuelTank\b[^>]*\bDamageCapacity="-?\d+(?:\.\d+)?"[^>]*>')){
                    if($m.Value -notmatch '(?i)\bDamageCapacity="64000(?:\.0+)?"'){
                        $expected['GLOBAL extreme durability - fuel tank capacities maxed']++
                    }
                }
            }
        }
    } finally {if($zip){$zip.Dispose()};if($fs){$fs.Dispose()}}
    return $expected
}

function Disable-GlobalComponentDamage([string]$Name, [string]$Text, $Counts) {
    # RC3.9.7: preserve the proven RC3.9.3 extreme-durability behavior exactly.
    # FuelTank fix only: max the existing DamageCapacity on the real <FuelTank>
    # element. FuelTank DamageArea definitions are deliberately left untouched.
    $lower = $Name.ToLowerInvariant().Replace('/', '\')

    # RC3.9.7 FuelTank fix. Fuel-tank durability belongs on the actual
    # <FuelTank DamageCapacity="..." /> element in base truck XML. Do NOT add
    # DamageCapacity to <DamageArea Type="FuelTank">; that invalidates truck definitions.
    if ($lower -match '(?:^|\\)classes\\trucks\\[^\\]+\.xml$') {
        $script:wlFuelTankHits = 0
        $Text = [regex]::Replace($Text, '(?is)<FuelTank\b[^>]*\bDamageCapacity="-?\d+(?:\.\d+)?"[^>]*>', {
            param($m)
            $tag = $m.Value
            if ($tag -notmatch '(?i)\bDamageCapacity="64000(?:\.0+)?"') { $script:wlFuelTankHits++ }
            return [regex]::Replace($tag, '(?i)(\bDamageCapacity=")-?\d+(?:\.\d+)?(")', '${1}64000${2}')
        })
        Add-Count $Counts 'GLOBAL extreme durability - fuel tank capacities maxed' ([int]$script:wlFuelTankHits)
        $script:wlFuelTankHits = 0
        return $Text
    }

    if ($lower -match '(?:^|\\)classes\\engines\\[^\\]+\.xml$') {
        $hits = [regex]::Matches($Text, '(?i)\bDamageCapacity="(?!64000(?:\.0+)?")-?\d+(?:\.\d+)?"').Count
        $Text = [regex]::Replace($Text, '(?i)(\bDamageCapacity=")-?\d+(?:\.\d+)?(")', '${1}64000${2}')
        Add-Count $Counts 'GLOBAL extreme durability - engine capacities maxed' $hits
        return $Text
    }

    if ($lower -match '(?:^|\\)classes\\gearboxes\\[^\\]+\.xml$') {
        $hits = [regex]::Matches($Text, '(?i)\bDamageCapacity="(?!64000(?:\.0+)?")-?\d+(?:\.\d+)?"').Count
        $Text = [regex]::Replace($Text, '(?i)(\bDamageCapacity=")-?\d+(?:\.\d+)?(")', '${1}64000${2}')
        Add-Count $Counts 'GLOBAL extreme durability - gearbox capacities maxed' $hits
        return $Text
    }

    if ($lower -match '(?:^|\\)classes\\wheels\\[^\\]+\.xml$') {
        # DamageCapacity is documented on the root <TruckWheel> / <TruckWheels>
        # tags, not on individual <TruckTire> entries. Touch only those roots.
        $hits = 0
        $Text = [regex]::Replace($Text, '(?is)<TruckWheels?\b[^>]*>', {
            param($m)
            $tag=$m.Value
            if($tag -match '(?i)\bDamageCapacity="-?\d+(?:\.\d+)?"'){
                if($tag -notmatch '(?i)\bDamageCapacity="64000(?:\.0+)?"'){ $script:wlWheelHits++ }
                return [regex]::Replace($tag, '(?i)(\bDamageCapacity=")-?\d+(?:\.\d+)?(")', '${1}64000${2}')
            }
            return $tag
        })
        $hits=[int]$script:wlWheelHits; $script:wlWheelHits=0
        Add-Count $Counts 'GLOBAL extreme durability - wheel capacities maxed' $hits
        return $Text
    }

    if ($lower -match '(?:^|\\)classes\\suspensions\\[^\\]+\.xml$') {
        # Both attributes belong on <SuspensionSet>, not child <Suspension>.
        $capHits=0; $multHits=0; $multAdded=0
        $Text = [regex]::Replace($Text, '(?is)<SuspensionSet\b[^>]*>', {
            param($m)
            $tag=$m.Value
            if($tag -match '(?i)\bDamageCapacity="-?\d+(?:\.\d+)?"'){
                if($tag -notmatch '(?i)\bDamageCapacity="64000(?:\.0+)?"'){ $script:wlSuspCapHits++ }
                $tag=[regex]::Replace($tag, '(?i)(\bDamageCapacity=")-?\d+(?:\.\d+)?(")', '${1}64000${2}')
            } else {
                $script:wlSuspCapHits++
                $tag=$tag.Substring(0,$tag.Length-1)+' DamageCapacity="64000">'
            }
            if($tag -match '(?i)\bBrokenWheelDamageMultiplier="-?\d+(?:\.\d+)?"'){
                if($tag -notmatch '(?i)\bBrokenWheelDamageMultiplier="0(?:\.0+)?"'){ $script:wlSuspMultHits++ }
                $tag=[regex]::Replace($tag, '(?i)(\bBrokenWheelDamageMultiplier=")-?\d+(?:\.\d+)?(")', '${1}0${2}')
            } else {
                $script:wlSuspMultAdded++
                $tag=$tag.Substring(0,$tag.Length-1)+' BrokenWheelDamageMultiplier="0">'
            }
            return $tag
        })
        $capHits=[int]$script:wlSuspCapHits; $script:wlSuspCapHits=0
        $multHits=[int]$script:wlSuspMultHits; $script:wlSuspMultHits=0
        $multAdded=[int]$script:wlSuspMultAdded; $script:wlSuspMultAdded=0
        Add-Count $Counts 'GLOBAL extreme durability - suspension capacities maxed' $capHits
        Add-Count $Counts 'GLOBAL extreme durability - broken-wheel multipliers disabled' $multHits
        Add-Count $Counts 'GLOBAL extreme durability - broken-wheel multipliers added' $multAdded
        return $Text
    }

    return $Text
}

function Set-BaseTruckUnlocked([string]$Text, $Counts) {
    # UNLOCK ALL TRUCKS FIX 1 (2026-09-14)
    # Some official/DLC trucks inherit one or more GameData unlock attributes instead of
    # declaring them locally. The old routine only REPLACED attributes that already existed,
    # so inherited UnlockByExploration/UnlockByRank values could remain active in-game.
    # Force explicit local values on the base Truck's GameData opening tag.
    $truck = [regex]::Match($Text, '(?is)<Truck(?:\s|>).*?</Truck>')
    if (-not $truck.Success) { return $Text }

    $gdRel = [regex]::Match($truck.Value, '(?is)<GameData\b[^>]*>')
    if (-not $gdRel.Success) { return $Text }

    $tag = $gdRel.Value
    $newTag = $tag
    $changed = 0

    if ([regex]::IsMatch($newTag, '(?i)\bUnlockByRank="[^"]*"')) {
        $tmp = [regex]::Replace($newTag, '(?i)(\bUnlockByRank=")[^"]*(")', '${1}1${2}', 1)
        if ($tmp -cne $newTag) { $changed++ }
        $newTag = $tmp
    } else {
        $newTag = $newTag.Substring(0,$newTag.Length-1) + ' UnlockByRank="1">'
        $changed++
    }

    if ([regex]::IsMatch($newTag, '(?i)\bUnlockByExploration="[^"]*"')) {
        $tmp = [regex]::Replace($newTag, '(?i)(\bUnlockByExploration=")[^"]*(")', '${1}false${2}', 1)
        if ($tmp -cne $newTag) { $changed++ }
        $newTag = $tmp
    } else {
        $newTag = $newTag.Substring(0,$newTag.Length-1) + ' UnlockByExploration="false">'
        $changed++
    }

    # Defensive handling for newer/alternate lock metadata when it is explicitly present.
    # Do not invent objective fields; only neutralize an existing one.
    if ([regex]::IsMatch($newTag, '(?i)\bLockedUnconditionally="[^"]*"')) {
        $tmp = [regex]::Replace($newTag, '(?i)(\bLockedUnconditionally=")[^"]*(")', '${1}false${2}', 1)
        if ($tmp -cne $newTag) { $changed++ }
        $newTag = $tmp
    }
    # UNLOCK ALL TRUCKS FIX 2 (2026-09-14): objective-gated trucks such as the
    # Tayga 6455B carry UnlockByObjective directly on the base Truck GameData.
    # Remove that attribute entirely so the store no longer waits for the objective reward.
    if ([regex]::IsMatch($newTag, '(?i)\bUnlockByObjective="[^"]*"')) {
        $tmp = [regex]::Replace($newTag, '(?i)\s+UnlockByObjective="[^"]*"', '', 1)
        if ($tmp -cne $newTag) {
            $changed++
            Add-Count $Counts 'Truck objective locks removed' 1
        }
        $newTag = $tmp
    }

    $absolute = $truck.Index + $gdRel.Index
    if ($newTag -cne $tag) {
        $Text = $Text.Substring(0,$absolute) + $newTag + $Text.Substring($absolute + $tag.Length)
        Add-Count $Counts 'Truck definitions explicitly unlocked' 1
        Add-Count $Counts 'Truck unlock fields corrected/added' $changed
    } else {
        Add-Count $Counts 'Truck definitions already explicitly unlocked' 1
    }
    return $Text
}

# CATEGORY PRESERVATION FIX 2:
# Category calculations intentionally start from the protected pristine backup so multipliers
# never stack.  Before writing, convert the pristine->requested XML delta into an attribute-only
# semantic patch and apply that patch to the CURRENT live XML.  This preserves every existing WL
# value that the current category operation did not intentionally request.
function Merge-CategoryRequestedXml([string]$BaselineText, [string]$RequestedText, [string]$CurrentText, $Counts) {
    if ($RequestedText -ceq $BaselineText) { return $CurrentText }

    $tagPattern='(?s)<([A-Za-z_][A-Za-z0-9_:.-]*)(?:\s[^<>]*?)?/?>'
    $baseTags=@([regex]::Matches($BaselineText,$tagPattern))
    $reqTags=@([regex]::Matches($RequestedText,$tagPattern))
    $curTags=@([regex]::Matches($CurrentText,$tagPattern))
    $attrPattern='(?i)([A-Za-z_][A-Za-z0-9_:.-]*)\s*=\s*"([^"]*)"'

    # FIX 2A: Gear Tuning legitimately materializes one additional <Gear/> element.
    # The first FIX 2 guard required identical tag counts, so it rejected our own known-safe
    # structural edit after All Trucks had already added that Gear to LIVE. Align baseline tags
    # to requested/live by name while allowing ONLY editor-owned extra <Gear/> tags. Everything
    # else still fails closed.
    function Get-WLCategoryTagAlignment($Base,$Side,[string]$SideName) {
        $map=@{}; $extras=@{}; $i=0; $j=0
        while($i -lt $Base.Count){
            if($j -ge $Side.Count){ throw "CATEGORY PRESERVATION FIX 2B safety stop: $SideName XML ended before baseline while preparing a category merge. Live PAK was NOT replaced." }
            $bn=[string]$Base[$i].Groups[1].Value; $sn=[string]$Side[$j].Groups[1].Value
            if($bn.Equals($sn,[StringComparison]::OrdinalIgnoreCase)){ $map[$i]=$j; $i++; $j++; continue }
            if($sn.Equals('Gear',[StringComparison]::OrdinalIgnoreCase)){
                if(-not $extras.ContainsKey($i)){$extras[$i]=New-Object System.Collections.Generic.List[int]}
                [void]$extras[$i].Add($j); $j++; continue
            }
            throw "CATEGORY PRESERVATION FIX 2B safety stop: unexpected XML element '$sn' in $SideName while baseline expected '$bn'. Live PAK was NOT replaced."
        }
        while($j -lt $Side.Count){
            $sn=[string]$Side[$j].Groups[1].Value
            if(-not $sn.Equals('Gear',[StringComparison]::OrdinalIgnoreCase)){ throw "CATEGORY PRESERVATION FIX 2B safety stop: unexpected trailing XML element '$sn' in $SideName. Live PAK was NOT replaced." }
            if(-not $extras.ContainsKey($Base.Count)){$extras[$Base.Count]=New-Object System.Collections.Generic.List[int]}
            [void]$extras[$Base.Count].Add($j); $j++
        }
        return [pscustomobject]@{Map=$map;Extras=$extras}
    }

    $reqAlign=Get-WLCategoryTagAlignment $baseTags $reqTags 'requested'
    $curAlign=Get-WLCategoryTagAlignment $baseTags $curTags 'current-live'
    $patches=New-Object System.Collections.Generic.List[object]

    function Get-WLAttrMap([string]$Tag){$h=@{};foreach($m in [regex]::Matches($Tag,$attrPattern)){$h[$m.Groups[1].Value.ToLowerInvariant()]=@($m.Groups[1].Value,$m.Groups[2].Value)};return $h}
    function Add-WLAttrPatch($bt,$rt,$ct){
        $ba=Get-WLAttrMap $bt.Value; $ra=Get-WLAttrMap $rt.Value
        $changes=New-Object System.Collections.Generic.List[object]
        $keys=New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
        foreach($k in $ba.Keys){[void]$keys.Add($k)}; foreach($k in $ra.Keys){[void]$keys.Add($k)}
        foreach($k in $keys){
            $bHas=$ba.ContainsKey($k);$rHas=$ra.ContainsKey($k)
            if($bHas -and $rHas -and ([string]$ba[$k][1] -ceq [string]$ra[$k][1])){continue}
            $display=if($rHas){[string]$ra[$k][0]}else{[string]$ba[$k][0]};$value=if($rHas){[string]$ra[$k][1]}else{$null}
            [void]$changes.Add([pscustomobject]@{Name=$display;Value=$value;Remove=(-not $rHas)})
        }
        if($changes.Count -gt 0){[void]$patches.Add([pscustomobject]@{Index=$ct.Index;Length=$ct.Length;Tag=$ct.Value;Changes=$changes})}
    }

    for($i=0;$i -lt $baseTags.Count;$i++){
        Add-WLAttrPatch $baseTags[$i] $reqTags[[int]$reqAlign.Map[$i]] $curTags[[int]$curAlign.Map[$i]]
    }

    # If pristine->requested added editor-owned Gear tags, LIVE must either already contain the
    # same number in the same alignment slot (normal after All Trucks) or we safely insert the
    # exact self-closing requested Gear. Existing live Gear values are updated from requested.
    $insertions=New-Object System.Collections.Generic.List[object]
    foreach($slotObj in @($reqAlign.Extras.Keys)){
        $slot=[int]$slotObj; $rq=@($reqAlign.Extras[$slot]); $cq=if($curAlign.Extras.ContainsKey($slot)){@($curAlign.Extras[$slot])}else{@()}
        if($cq.Count -gt $rq.Count){ throw "CATEGORY PRESERVATION FIX 2B safety stop: current-live contains more editor-owned Gear elements than requested at alignment slot $slot. Live PAK was NOT replaced." }
        for($x=0;$x -lt $rq.Count;$x++){
            $rt=$reqTags[[int]$rq[$x]]
            if(-not $rt.Value.TrimEnd().EndsWith('/>')){ throw 'CATEGORY PRESERVATION FIX 2B safety stop: an added Gear element was not self-closing. Live PAK was NOT replaced.' }
            if($x -lt $cq.Count){
                $ct=$curTags[[int]$cq[$x]]
                # Added Gear has no pristine counterpart: all requested attributes define it.
                $fake=[regex]::Match('<Gear/>',$tagPattern)
                Add-WLAttrPatch $fake $rt $ct
            } else {
                $pos=if($slot -lt $baseTags.Count){$curTags[[int]$curAlign.Map[$slot]].Index}else{$CurrentText.Length}
                [void]$insertions.Add([pscustomobject]@{Index=$pos;Text=$rt.Value})
            }
        }
    }

    $result=$CurrentText
    $ops=New-Object System.Collections.Generic.List[object]
    foreach($p in $patches){[void]$ops.Add([pscustomobject]@{Index=[int]$p.Index;Kind='patch';Obj=$p})}
    foreach($ins in $insertions){[void]$ops.Add([pscustomobject]@{Index=[int]$ins.Index;Kind='insert';Obj=$ins})}
    foreach($op in @($ops | Sort-Object Index -Descending)){
        if($op.Kind -eq 'insert'){$result=$result.Insert([int]$op.Obj.Index,[string]$op.Obj.Text);continue}
        $p=$op.Obj;$tag=[string]$p.Tag
        foreach($c in $p.Changes){
            $n=[regex]::Escape([string]$c.Name);$existing='(?i)(\s+)'+$n+'\s*=\s*"[^"]*"'
            if($c.Remove){$tag=[regex]::Replace($tag,$existing,'',1)}else{
                $escaped=[string]$c.Value
                if([regex]::IsMatch($tag,$existing)){
                    # FIX 2B: NEVER build a regex replacement string from capture tokens + a
                    # numeric value.  Values such as 1530 made "$1" + "1530" become "$11530",
                    # which .NET interpreted as a capture reference and wrote literal corruption.
                    # Replace the matched attribute as a literal string operation instead.
                    $valuePattern='(?i)'+$n+'\s*=\s*"[^"]*"'
                    $vm=[regex]::Match($tag,$valuePattern)
                    if(-not $vm.Success){throw "CATEGORY PRESERVATION FIX 2B safety stop: could not locate attribute '$($c.Name)' for literal-safe merge. Live PAK was NOT replaced."}
                    $literal=[string]$c.Name+'="'+[string]$c.Value+'"'
                    $tag=$tag.Substring(0,$vm.Index)+$literal+$tag.Substring($vm.Index+$vm.Length)
                }else{
                    $insert=' '+[string]$c.Name+'="'+[string]$c.Value+'"';if($tag.EndsWith('/>')){$tag=$tag.Insert($tag.Length-2,$insert)}else{$tag=$tag.Insert($tag.Length-1,$insert)}
                }
            }
        }
        $result=$result.Substring(0,[int]$p.Index)+$tag+$result.Substring([int]$p.Index+[int]$p.Length)
    }
    Add-Count $Counts 'CATEGORY FIX 2D semantic XML merges' 1
    Add-Count $Counts 'CATEGORY FIX 2D requested XML attributes merged' (($patches | ForEach-Object {$_.Changes.Count} | Measure-Object -Sum).Sum)
    Add-Count $Counts 'CATEGORY FIX 2D editor-owned Gear elements inserted' $insertions.Count
    return $result
}

# CATEGORY PRESERVATION FIX 2B FINAL GUARD:
# A category temp PAK must never contain regex-capture artifacts from the semantic merger.
# This scans every XML entry before the atomic live swap.  The known FIX 2A failure produced
# literal "$1" fragments (for example Back$10.035 / $11530), so any occurrence is fatal.
function Assert-NoCategoryMergeArtifacts([string]$PakPath) {
    $fs=$null;$zip=$null
    try{
        $fs=[IO.File]::Open($PakPath,[IO.FileMode]::Open,[IO.FileAccess]::Read,[IO.FileShare]::Read)
        $zip=New-Object IO.Compression.ZipArchive($fs,[IO.Compression.ZipArchiveMode]::Read,$false)
        $bad=New-Object System.Collections.Generic.List[string]
        foreach($e in $zip.Entries){
            if(-not $e.FullName.EndsWith('.xml',[StringComparison]::OrdinalIgnoreCase)){continue}
            $r=New-Object IO.StreamReader($e.Open(),[Text.Encoding]::UTF8,$true)
            try{$t=$r.ReadToEnd()}finally{$r.Dispose()}
            if($t.Contains('$1')){[void]$bad.Add($e.FullName);if($bad.Count -ge 10){break}}
        }
        if($bad.Count -gt 0){
            throw ("CATEGORY PRESERVATION FIX 2B FINAL SAFETY STOP: detected forbidden regex-capture artifact '$1' in generated XML. Live PAK was NOT replaced. First affected entry: "+$bad[0])
        }
    } finally {if($null -ne $zip){$zip.Dispose()};if($null -ne $fs){$fs.Dispose()}}
}

function Modify-Entry([string]$Name, [string]$Text, $S, $Counts) {
    $lower = $Name.ToLowerInvariant().Replace('/', '\')

    # v1.1.0 TEST individual-truck scope. A selected truck is intentionally
    # limited to its base truck definition so shared engines/gearboxes/tires/etc.
    # cannot accidentally change other trucks that use the same component XML.
    if ($S.TargetTruckId) {
        if ($S.CategorySinglePassMode) {
            $targets=@($S.TargetTruckEntries | ForEach-Object { ([string]$_).ToLowerInvariant().Replace('/', '\') })
            if($targets.Count -eq 0 -or -not ($targets -contains $lower)){ return $Text }
        } else {
            if (-not $S.TargetTruckEntry) { return $Text }
            $targetBase = ([string]$S.TargetTruckEntry).ToLowerInvariant().Replace('/', '\')
            # TEST 6.2 resolves the real archive entry before modification, then uses
            # exact equality here. No fuzzy matching is allowed during the write pass.
            if (-not $lower.Equals($targetBase, [StringComparison]::OrdinalIgnoreCase)) { return $Text }
        }
    }

    if ($S.TargetTruckId) {
        # TEST 6.23.1: engine settings keep the stock EngineSocket identifiers unchanged.
        # The selected stock/default engine variant is edited in place.
        # TEST 6.23.1: gearbox identifiers remain stock; no private variant repoint.
        $Text = Repoint-IndividualTire $Text $S $Counts
        $Text = Repoint-TestStockWheelFamily $Text $S $Counts
    }

    if ($lower -match '(?:^|\\)classes\\engines\\[^\\]+\.xml$') {
        $Text = Replace-NumericAttribute $Text 'Torque' $S.EngineTorque $Counts 'Engine torque'
        $Text = Replace-NumericAttribute $Text 'EngineResponsiveness' $S.EngineResponse $Counts 'Engine responsiveness'
        $Text = Replace-NumericAttribute $Text 'FuelConsumption' $S.EngineFuel $Counts 'Engine fuel consumption'
        $Text = Replace-NumericAttribute $Text 'DamageCapacity' $S.EngineDurability $Counts 'Engine durability'
    }
    elseif ($lower -match '(?:^|\\)classes\\gearboxes\\[^\\]+\.xml$') {
        $Text = Replace-NumericAttribute $Text 'FuelConsumption' $S.GearboxFuel $Counts 'Gearbox fuel consumption'
        $Text = Replace-NumericAttribute $Text 'AWDConsumptionModifier' $S.AwdFuel $Counts 'AWD fuel penalty'
        $Text = Replace-NumericAttribute $Text 'IdleFuelModifier' $S.IdleFuel $Counts 'Idle fuel use'
        # RC3.9.7: All Trucks traverses every gearbox-class XML, including helper/template files
        # that contain no named <Gearbox> variants. Only tune files that actually contain variants.
        # Individual-truck mode keeps its stricter resolved-family safety stop in the dedicated path.
        if ([math]::Abs([double]$S.GearSpeed - 1.0) -ge 0.0000001 -and [regex]::IsMatch($Text, '(?is)<Gearbox\b[^>]*\bName="[^"]+"[^>]*>')) {
            $Text = Tune-GearboxProgression $Text $S.GearSpeed $Counts 'Gearbox variants tuned'
        }
        $Text = Replace-NumericAttribute $Text 'DamageCapacity' $S.GearboxDurability $Counts 'Gearbox durability'
    }
    elseif ($lower -match '(?:^|\\)classes\\wheels\\[^\\]+\.xml$') {
        $Text = Replace-NumericAttribute $Text 'BodyFrictionAsphalt' $S.TireAsphalt $Counts 'Tire asphalt grip'
        $Text = Replace-NumericAttribute $Text 'BodyFriction' $S.TireOffroad $Counts 'Tire off-road grip'
        $Text = Replace-NumericAttribute $Text 'SubstanceFriction' $S.TireMud $Counts 'Tire mud grip'
        $Text = Replace-NumericAttribute $Text 'DamageCapacity' $S.TireDurability $Counts 'Tire durability'
        if ($S.AllTiresIgnoreIce) { $Text = Set-WheelFrictionIgnoreIce $Text $Counts 'All tires ignore ice' }
    }
    elseif ($lower -match '(?:^|\\)classes\\suspensions\\[^\\]+\.xml$') {
        $Text = Replace-SuspensionTravelAttribute $Text 'Strength' $S.SuspensionStrength $Counts 'Suspension strength'
        $Text = Replace-NumericAttribute $Text 'Height' $S.SuspensionHeight $Counts 'Suspension height'
        $Text = Replace-SuspensionDampingVerified $Text $S.SuspensionDamping $Counts 'Suspension damping'
        $Text = Replace-NumericAttribute $Text 'DamageCapacity' $S.SuspensionDurability $Counts 'Suspension durability'
    }
    elseif ($lower -match '(?:^|\\)classes\\winches\\[^\\]+\.xml$' -and $lower -notmatch 'winch_ui_draw') {
        $Text = Replace-NumericAttribute $Text 'StrengthMult' $S.WinchStrength $Counts 'Winch strength'
        $Text = Replace-NumericAttribute $Text 'Length' $S.WinchLength $Counts 'Winch length'
        if ($S.AutonomousWinches) {
            $pattern = '(?i)IsEngineIgnitionRequired="(?:true|false)"'
            $n = [regex]::Matches($Text, $pattern).Count
            $Text = [regex]::Replace($Text, $pattern, 'IsEngineIgnitionRequired="false"')
            Add-Count $Counts 'Autonomous winches' $n
        }
    }
    elseif ($lower -match '(?:^|\\)classes\\trucks\\addons\\[^\\]+\.xml$' -and (
        $lower -match '(?:crane|loglift)' -or
        $Text -match '(?is)<AddonType\s+Name="Crane"\s*/?>' -or
        $Text -match '(?is)<ControlledConstraints>.*?BelongToCategorie="(?:crane_control|tow_control)"'
    )) {
        # v1.1.3: discover mechanical equipment by XML semantics, not filename alone.
        # Existing crane/loglift behavior stays intact. This also reaches crane-equipped service modules,
        # telehandlers/manipulators, and towing platforms whose filenames do not contain "crane".
        if ($S.TargetTruckId) { return $Text }
        $Text = Replace-CraneHingeMotorForce $Text ([double]$S.CraneStrength) $Counts
        $Text = Replace-CraneControlledIKSpeed $Text ([double]$S.CraneSpeed) $Counts
        $Text = Replace-ControlledConstraintMotorForce $Text ([double]$S.CraneStrength) $Counts
        $Text = Replace-ControlledConstraintSpeed $Text ([double]$S.CraneSpeed) $Counts
    }

    # DEV22: third-party PAKs commonly store component XML at archive-root classes/...; path regexes must accept archive root or nested prefixes.
    # Older matching required a leading backslash, so root-level mod truck XML was resolved
    # as the selected target but never classified as a base truck for truck-local settings.
    $isBaseTruck = ($lower -match '(^|\\)classes\\trucks\\[^\\]+\.xml$' -and $Text -match '<Truck>')
    $isTruckXml = ($lower -match '(^|\\)classes\\trucks\\.*\.xml$')
    $isUpgrade = ($lower -match '(?:^|\\)classes\\(?:engines|gearboxes|suspensions|wheels|winches)\\[^\\]+\.xml$' -or $lower -match '(?:^|\\)classes\\trucks\\(?!cargo\\|trailers\\)[^\\]+\\[^\\]+\.xml$')

    if ($isTruckXml -and -not $isBaseTruck) {
        $Text = Replace-NumericAttribute $Text 'FuelCapacity' $S.ServiceFuel $Counts 'Service fuel capacity'
        $Text = Replace-NumericAttribute $Text 'WaterCapacity' $S.ServiceWater $Counts 'Service water capacity'
        $Text = Replace-NumericAttribute $Text 'RepairsCapacity' $S.ServiceRepairs $Counts 'Service repair points'
        $Text = Replace-NumericAttribute $Text 'WheelRepairsCapacity' $S.ServiceWheels $Counts 'Service spare wheels'
        if ($lower -notmatch '(?:^|\\)classes\\trucks\\cargo\\') {
            $Text = Lower-AddonTrailerPrimaryCenterOfMass $Text $S.AddonCgDrop $Counts 'Addon/trailer center of gravity (primary body only)'
        }
    }

    if (-not $S.TargetTruckId -and (($lower -match '(?:^|\\)classes\\models\\[^\\]+\.xml$' -and $Text -match '\bLoadType="') -or $lower -match '(?:^|\\)classes\\trucks\\cargo\\[^\\]+\.xml$')) {
        # Cargo definitions are shared/global resources; Cargo Mass is All-Trucks-only.
        $Text = Replace-NumericAttribute $Text 'Mass' $S.CargoMass $Counts 'Cargo physical mass'
    }

    if ($isUpgrade) {
        $Text = Replace-NumericAttribute $Text 'Price' $S.UpgradePrice $Counts 'Upgrade/addon prices'
        if ($S.UnlockUpgrades) {
            $p1 = '(?i)(\bUnlockByRank=")\d+(?:\.\d+)?(")'
            $p2 = '(?i)(\bUnlockByExploration=")(?:true|false)(")'
            $n = [regex]::Matches($Text, $p1).Count + [regex]::Matches($Text, $p2).Count
            $Text = [regex]::Replace($Text, $p1, '${1}1${2}')
            $Text = [regex]::Replace($Text, $p2, '${1}false${2}')
            Add-Count $Counts 'Upgrade/addon unlock requirements' $n
        }
    }

    # Only base truck definitions: exclude tuning, addons and trailers.
    if ($isBaseTruck) {
        # TEST 6.20.4: EngineSocket is already repointed once in the individual-target
        # block above. Calling Repoint-IndividualEngine a second time here searched
        # for the old Default after it had already been replaced, producing the
        # false TEST 6.9 "0 matching EngineSocket" safety stop.
        $Text = Replace-NumericAttribute $Text 'FuelCapacity' $S.FuelCapacity $Counts 'Truck fuel capacity'
        if ([math]::Abs([double]$S.FuelTankDurability - 1.0) -ge 0.0000001) {
            $ftPattern = '(?is)<FuelTank\b[^>]*\bDamageCapacity="(-?\d+(?:\.\d+)?)"[^>]*>'
            $ftHits = [regex]::Matches($Text, $ftPattern).Count
            $Text = [regex]::Replace($Text, $ftPattern, {
                param($m)
                $tag = $m.Value
                return [regex]::Replace($tag, '(?i)(\bDamageCapacity=")(-?\d+(?:\.\d+)?)(")', {
                    param($a)
                    $v = [double]::Parse($a.Groups[2].Value, [Globalization.CultureInfo]::InvariantCulture)
                    return $a.Groups[1].Value + (Format-Number ($v * [double]$S.FuelTankDurability)) + $a.Groups[3].Value
                })
            })
            Add-Count $Counts 'Fuel tank durability' $ftHits
        }
        if ([math]::Abs([double]$S.TruckPrice - 1.0) -ge 0.0000001) {
            $Text = Replace-NumericAttribute $Text 'Price' $S.TruckPrice $Counts 'Truck prices'
        }
        $Text = Lower-TruckPrimaryCenterOfMass $Text $S.TruckCgDrop $Counts 'Truck center of gravity'
        $Text = Replace-NumericAttribute $Text 'SteeringAngle' $S.SteeringAngle $Counts 'Maximum steering angle'
        $Text = Replace-NumericAttribute $Text 'SteerSpeed' $S.SteeringResponse $Counts 'Steering response'
        $Text = Replace-NumericAttribute $Text 'BackSteerSpeed' $S.SteeringResponse $Counts 'Return steering response'
        # RC4 experimental visual-geometry compensation. This only changes truck XMLs
        # that already define CamberSuspensionMultiplier, and only when Height is changed.
        $Text = Compensate-SuspensionCamberForHeight $Text ([double]$S.SuspensionHeight) $Counts
        if ($S.AlwaysAWD) {
            # Keep the normal driven axle as "default". Only convert an axle
            # that is connectable or disabled into an always-driven axle.
            # Some trucks call the axle Front/MiddleAxle instead of FrontWheel.
            # Symbolic connectable/none torque values only occur on drive nodes.
            $pattern = '(?is)(<[A-Za-z0-9_]+\b[^>]*?\bTorque=")(?:connectable|none)(")'
            $n = [regex]::Matches($Text, $pattern).Count
            $Text = [regex]::Replace($Text, $pattern, '${1}full${2}')
            Add-Count $Counts 'Always AWD wheel definitions' $n
        }
        if ($S.AlwaysDiff) {
            # PRIVATE TEST DIFF LOCK FIX 1:
            # SnowRunner only treats DiffLockType="Always" as a permanent diff lock.
            # Installed/Uninstalled are bookkeeping states for engageable/addon-based diffs.
            # Force the value specifically on the BASE <TruckData> opening tag (or add it
            # when a truck omits the attribute) instead of doing a broad XML-wide replace.
            $truckDataPattern = '(?is)<TruckData\b[^>]*>'
            $td = [regex]::Match($Text, $truckDataPattern)
            if ($td.Success) {
                $tag = $td.Value
                $oldType = ''
                $dm = [regex]::Match($tag, '(?i)\bDiffLockType="([^"]*)"')
                if ($dm.Success) { $oldType = $dm.Groups[1].Value } else { $oldType = '(missing)' }
                if ($dm.Success) {
                    $newTag = [regex]::Replace($tag, '(?i)(\bDiffLockType=")[^"]*(")', '${1}Always${2}', 1)
                } else {
                    $newTag = $tag.Substring(0,$tag.Length-1) + ' DiffLockType="Always">'
                }
                if ($newTag -cne $tag) {
                    $Text = $Text.Substring(0,$td.Index) + $newTag + $Text.Substring($td.Index + $td.Length)
                    Add-Count $Counts 'Always differential lock forced on base TruckData' 1
                } elseif ($oldType -ieq 'Always') {
                    Add-Count $Counts 'Always differential lock already enabled' 1
                }
            }
        }
        if ($S.UnlockTrucks) {
            # FIX 1: explicitly stamp unlock values onto the base Truck GameData, including
            # attributes inherited/omitted by official and DLC truck definitions.
            $Text = Set-BaseTruckUnlocked $Text $Counts
        }
        if ($S.AllRegions) {
            $pattern = '(?i)(\bCountry=")[^"]*(")'
            $n = [regex]::Matches($Text, $pattern).Count
            $Text = [regex]::Replace($Text, $pattern, '${1}US,RU,NE,CAS,CE,WA${2}')
            Add-Count $Counts 'Truck region availability' $n
        }
    }
    return $Text
}

function Assert-ModPak([string]$Path, [string]$TruckEntry = '') {
    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path -LiteralPath $Path -PathType Leaf)) { throw 'Choose an installed mod truck again with Scan Mods.' }
    $stream = [IO.File]::OpenRead($Path)
    try {
        $zip = New-Object IO.Compression.ZipArchive($stream, [IO.Compression.ZipArchiveMode]::Read)
        try {
            if ($zip.Entries.Count -lt 1) { throw 'The selected mod PAK is empty.' }
            if (-not [string]::IsNullOrWhiteSpace($TruckEntry)) {
                $want = $TruckEntry.Replace('\','/')
                $entry = $zip.Entries | Where-Object { $_.FullName.Replace('\','/').Equals($want,[StringComparison]::OrdinalIgnoreCase) } | Select-Object -First 1
                if (-not $entry) { throw 'The selected truck XML is no longer present in this mod PAK. The mod may have updated; run Scan Mods again.' }
                $reader = New-Object IO.StreamReader($entry.Open(), [Text.Encoding]::UTF8, $true)
                try { $xml = $reader.ReadToEnd() } finally { $reader.Dispose() }
                if ($xml -notmatch '<Truck\b') { throw 'The mapped mod entry is no longer a SnowRunner Truck XML. No modifications were made.' }
            }
        } finally { $zip.Dispose() }
    } finally { $stream.Dispose() }
}
function Get-ModBackupRoot {
    # DEV19: Never store a backup ending in .pak anywhere inside SnowRunner's mod tree.
    # SnowRunner scans those files too, which can create duplicate truck definitions and
    # make the selected truck disappear from the Truck Store.
    $root = Join-Path $env:LOCALAPPDATA 'WL Simplistic SnowRunner Mod Editor\Mod Backups'
    if (-not (Test-Path -LiteralPath $root)) { [IO.Directory]::CreateDirectory($root) | Out-Null }
    return $root
}
function Get-ModBackupKey([string]$PakPath) {
    $full=[IO.Path]::GetFullPath($PakPath).ToLowerInvariant()
    $sha=[Security.Cryptography.SHA256]::Create()
    try { $bytes=[Text.Encoding]::UTF8.GetBytes($full); return ([BitConverter]::ToString($sha.ComputeHash($bytes))).Replace('-','').Substring(0,24) }
    finally { $sha.Dispose() }
}
function Get-ModBackupDir([string]$PakPath) { return (Join-Path (Get-ModBackupRoot) (Get-ModBackupKey $PakPath)) }
function Get-ModBackupPath([string]$PakPath) { return (Join-Path (Get-ModBackupDir $PakPath) 'original.wlbak') }
function Get-ModBackupMetaPath([string]$PakPath) { return (Join-Path (Get-ModBackupDir $PakPath) 'backup.wlmeta.json') }
function Move-LegacyModBackupOutOfGameTree([string]$Pak,[string]$TruckEntry) {
    $legacyBackup=$Pak+'.wl-original.pak'; $legacyMeta=$Pak+'.wl-original.pak.wlmeta.json'
    if (-not (Test-Path -LiteralPath $legacyBackup)) { return }
    if (-not (Test-Path -LiteralPath $legacyMeta)) { throw 'DEV19 found a legacy WL .pak backup beside this mod, but its safety record is missing. Move/delete that legacy backup manually before launching SnowRunner.' }
    Assert-ModPak $legacyBackup $TruckEntry
    $lm=Get-Content -LiteralPath $legacyMeta -Raw | ConvertFrom-Json
    $lh=Get-FileSha256 $legacyBackup
    if ($lm.BackupHash -ne $lh) { throw 'DEV19 found a legacy WL .pak backup beside this mod, but its hash does not match its safety record. It was not migrated or deleted.' }
    $dir=Get-ModBackupDir $Pak
    if (-not (Test-Path -LiteralPath $dir)) { [IO.Directory]::CreateDirectory($dir) | Out-Null }
    $backup=Get-ModBackupPath $Pak; $metaPath=Get-ModBackupMetaPath $Pak
    if (-not (Test-Path -LiteralPath $backup)) { [IO.File]::Copy($legacyBackup,$backup,$false) }
    if ((Get-FileSha256 $backup) -ne $lh) { throw 'DEV19 legacy backup migration verification failed. The legacy files were left untouched.' }
    if (-not (Test-Path -LiteralPath $metaPath)) { [IO.File]::Copy($legacyMeta,$metaPath,$false) }
    Remove-Item -LiteralPath $legacyBackup -Force
    Remove-Item -LiteralPath $legacyMeta -Force
}
function Initialize-ModBackup([string]$Pak, [string]$TruckEntry) {
    Assert-ModPak $Pak $TruckEntry
    Move-LegacyModBackupOutOfGameTree $Pak $TruckEntry
    $backup=Get-ModBackupPath $Pak; $metaPath=Get-ModBackupMetaPath $Pak; $currentHash=Get-FileSha256 $Pak
    $dir=Get-ModBackupDir $Pak
    if (-not (Test-Path -LiteralPath $dir)) { [IO.Directory]::CreateDirectory($dir) | Out-Null }
    if (-not (Test-Path -LiteralPath $backup)) {
        [IO.File]::Copy($Pak,$backup,$false)
        [ordered]@{BackupHash=$currentHash;LastEditorOutputHash=$null;CreatedUtc=[DateTime]::UtcNow.ToString('o');Kind='ThirdPartyModPak';SourcePak=[IO.Path]::GetFullPath($Pak)} | ConvertTo-Json | Set-Content -LiteralPath $metaPath -Encoding UTF8
        return $backup
    }
    if (-not (Test-Path -LiteralPath $metaPath)) { throw 'A mod backup exists without its WL safety record. The editor will not trust it automatically.' }
    Assert-ModPak $backup $TruckEntry
    $meta=Get-Content -LiteralPath $metaPath -Raw | ConvertFrom-Json; $backupHash=Get-FileSha256 $backup
    if ($meta.BackupHash -ne $backupHash) { throw 'The mod backup no longer matches its WL safety record. No modifications were made.' }
    if ($currentHash -ne $meta.BackupHash -and $currentHash -ne $meta.LastEditorOutputHash) {
        # DEV14 BASELINE PROTECTION:
        # Never silently promote an unknown live third-party PAK to the trusted WL baseline.
        # A Mod.io update, manual replacement, stale DEV output, or an older editor bug can all
        # produce this state. Promoting it automatically can permanently turn an edited PAK into
        # the so-called "original" and cause multiplier compounding on every later Apply.
        #
        # Fail closed instead. The user must deliberately establish a new baseline from a known-
        # fresh Mod.io copy by resetting WL's external backup after deliberate user action.
        throw ("DEV19 mod baseline safety stop: the live mod PAK is neither the verified WL baseline nor the last output recorded by this editor. WL will NOT promote it to 'original' automatically.`r`n`r`n" +
               "If the mod was freshly re-downloaded/updated from Mod.io, the external WL backup must be deliberately reset before a new baseline is established.`r`n`r`n" +
               "External backup location:`r`n" + $backup + "`r`n`r`nThe live mod PAK itself was not changed.")
    }
    return $backup
}
function Assert-ModPakStructurePreserved([string]$OriginalPak,[string]$RebuiltPak) {
    $a=[IO.File]::OpenRead($OriginalPak);$b=[IO.File]::OpenRead($RebuiltPak)
    try{
        $za=New-Object IO.Compression.ZipArchive($a,[IO.Compression.ZipArchiveMode]::Read)
        $zb=New-Object IO.Compression.ZipArchive($b,[IO.Compression.ZipArchiveMode]::Read)
        try{
            $an=@($za.Entries|ForEach-Object{$_.FullName})
            $bn=@($zb.Entries|ForEach-Object{$_.FullName})
            if($an.Count -ne $bn.Count){throw "DEV7 mod PAK safety stop: archive entry count changed ($($an.Count) -> $($bn.Count))."}
            for($i=0;$i -lt $an.Count;$i++){
                if($an[$i] -cne $bn[$i]){
                    throw "DEV7 mod PAK safety stop: archive entry order changed at index $i ('$($an[$i])' -> '$($bn[$i])')."
                }
            }
        }finally{$za.Dispose();$zb.Dispose()}
    }finally{$a.Dispose();$b.Dispose()}
}

function Match-ModPakChangedXmlCompressedSize([string]$OriginalPak,[string]$RebuiltPak) {
    # DEV10 experiment:
    # DEV9 proved the untouched ZIP entries are byte-for-byte preserved, but a one-byte
    # growth in the edited Cat MT700 engine DEFLATE stream shifted every later local-header
    # offset. Before the surgical writer runs, try harmless XML whitespace variants until
    # each changed XML entry has the SAME compressed size it had in the pristine mod PAK.
    # This lets the surgical writer preserve all following local-header offsets exactly.
    #
    # Fail closed: content other than insignificant XML whitespace is never invented or
    # removed, and if no equal-size representation can be found the editor stops rather
    # than installing a structurally shifted test PAK.

    function Read-EntryMap([string]$Pak) {
        $fs=[IO.File]::OpenRead($Pak)
        try {
            $za=New-Object IO.Compression.ZipArchive($fs,[IO.Compression.ZipArchiveMode]::Read)
            try {
                $map=@{}
                foreach($e in $za.Entries){
                    $ms=New-Object IO.MemoryStream
                    $st=$e.Open()
                    try { $st.CopyTo($ms) } finally { $st.Dispose() }
                    $map[$e.FullName]=[pscustomobject]@{
                        Bytes=$ms.ToArray(); CompressedLength=[int64]$e.CompressedLength;
                        Length=[int64]$e.Length; LastWriteTime=$e.LastWriteTime
                    }
                    $ms.Dispose()
                }
                return $map
            } finally { $za.Dispose() }
        } finally { $fs.Dispose() }
    }

    function Bytes-Equal([byte[]]$A,[byte[]]$B) {
        if($A.Length -ne $B.Length){ return $false }
        for($i=0;$i -lt $A.Length;$i++){ if($A[$i] -ne $B[$i]){ return $false } }
        return $true
    }

    function Rewrite-Entry([string]$SourcePak,[string]$DestPak,[string]$EntryName,[byte[]]$NewBytes,$SavedTime) {
        [IO.File]::Copy($SourcePak,$DestPak,$true)
        $fs=[IO.File]::Open($DestPak,[IO.FileMode]::Open,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
        try {
            $za=New-Object IO.Compression.ZipArchive($fs,[IO.Compression.ZipArchiveMode]::Update)
            try {
                $old=$za.GetEntry($EntryName)
                if(-not $old){ throw "DEV10 mod PAK safety stop: candidate entry '$EntryName' disappeared." }
                $old.Delete()
                $ne=$za.CreateEntry($EntryName,[IO.Compression.CompressionLevel]::Optimal)
                $ne.LastWriteTime=$SavedTime
                $st=$ne.Open()
                try { $st.Write($NewBytes,0,$NewBytes.Length) } finally { $st.Dispose() }
            } finally { $za.Dispose() }
        } finally { $fs.Dispose() }
    }

    function Get-EntryCompressedLength([string]$Pak,[string]$EntryName) {
        $fs=[IO.File]::OpenRead($Pak)
        try {
            $za=New-Object IO.Compression.ZipArchive($fs,[IO.Compression.ZipArchiveMode]::Read)
            try {
                $e=$za.GetEntry($EntryName)
                if(-not $e){ throw "DEV10 mod PAK safety stop: candidate entry '$EntryName' was not found." }
                return [int64]$e.CompressedLength
            } finally { $za.Dispose() }
        } finally { $fs.Dispose() }
    }

    $origMap=Read-EntryMap $OriginalPak
    $editMap=Read-EntryMap $RebuiltPak
    $changed=New-Object Collections.Generic.List[string]
    foreach($name in $origMap.Keys){
        if(-not $editMap.ContainsKey($name)){ throw "DEV10 mod PAK safety stop: rebuilt archive is missing '$name'." }
        if(-not (Bytes-Equal $origMap[$name].Bytes $editMap[$name].Bytes)){ [void]$changed.Add($name) }
    }
    if($changed.Count -lt 1){ throw 'DEV10 mod PAK safety stop: no changed archive entries were detected.' }

    foreach($name in $changed){
        $target=[int64]$origMap[$name].CompressedLength
        $current=[int64](Get-EntryCompressedLength $RebuiltPak $name)
        if($current -eq $target){ continue }
        if(-not $name.EndsWith('.xml',[StringComparison]::OrdinalIgnoreCase)){
            throw "DEV10 mod PAK safety stop: changed non-XML entry '$name' changed compressed size ($current -> target $target)."
        }

        $base=[byte[]]$editMap[$name].Bytes
        $candidates=New-Object Collections.Generic.List[byte[]]

        # XML 1.0 normalizes CR, CRLF and LF as line endings. Replacing exactly one
        # CRLF with CR or LF is therefore semantically insignificant to the XML parser,
        # while it can alter DEFLATE packing enough to recover the original byte count.
        for($i=0;$i -lt $base.Length-1;$i++){
            if($base[$i] -eq 13 -and $base[$i+1] -eq 10){
                foreach($replacement in @(13,10)){
                    $cand=New-Object byte[] ($base.Length-1)
                    if($i -gt 0){ [Array]::Copy($base,0,$cand,0,$i) }
                    $cand[$i]=[byte]$replacement
                    if($i+2 -lt $base.Length){ [Array]::Copy($base,$i+2,$cand,$i+1,$base.Length-($i+2)) }
                    [void]$candidates.Add($cand)
                }
            }
        }

        # Secondary harmless candidates: remove one indentation TAB that occurs directly
        # after a line break. Whitespace between XML elements is insignificant here.
        for($i=1;$i -lt $base.Length;$i++){
            if($base[$i] -eq 9 -and ($base[$i-1] -eq 10 -or $base[$i-1] -eq 13 -or $base[$i-1] -eq 9)){
                $cand=New-Object byte[] ($base.Length-1)
                if($i -gt 0){ [Array]::Copy($base,0,$cand,0,$i) }
                if($i+1 -lt $base.Length){ [Array]::Copy($base,$i+1,$cand,$i,$base.Length-($i+1)) }
                [void]$candidates.Add($cand)
            }
        }

        $matched=$false
        $candidatePath=$RebuiltPak+'.dev10candidate'
        try {
            foreach($cand in $candidates){
                Rewrite-Entry $RebuiltPak $candidatePath $name $cand $editMap[$name].LastWriteTime
                $size=Get-EntryCompressedLength $candidatePath $name
                if($size -eq $target){
                    [IO.File]::Copy($candidatePath,$RebuiltPak,$true)
                    $matched=$true
                    break
                }
                Remove-Item -LiteralPath $candidatePath -Force -ErrorAction SilentlyContinue
            }
        } finally {
            Remove-Item -LiteralPath $candidatePath -Force -ErrorAction SilentlyContinue
        }
        if(-not $matched){
            throw "DEV10 mod PAK safety stop: '$name' compressed size changed from $target to $current bytes and no harmless equal-size XML representation was found. No live PAK was replaced."
        }
    }
}

function Assert-ModChangedEntryCompressedSizesMatch([string]$OriginalPak,[string]$RebuiltPak) {
    # DEV11 hard gate: the equal-size experiment is only valid if it is STILL true
    # after every archive surgery step. Never install a mod PAK if a changed entry's
    # compressed length differs from the pristine backup.
    function Get-Map([string]$Pak) {
        $fs=[IO.File]::OpenRead($Pak)
        try {
            $z=New-Object IO.Compression.ZipArchive($fs,[IO.Compression.ZipArchiveMode]::Read)
            try {
                $m=@{}
                foreach($e in $z.Entries){
                    $ms=New-Object IO.MemoryStream; $st=$e.Open()
                    try{$st.CopyTo($ms)}finally{$st.Dispose()}
                    $m[$e.FullName]=[pscustomobject]@{ Bytes=$ms.ToArray(); CompressedLength=[int64]$e.CompressedLength }
                    $ms.Dispose()
                }
                return $m
            } finally {$z.Dispose()}
        } finally {$fs.Dispose()}
    }
    function Same([byte[]]$A,[byte[]]$B){
        if($A.Length -ne $B.Length){return $false}
        for($i=0;$i -lt $A.Length;$i++){if($A[$i] -ne $B[$i]){return $false}}
        return $true
    }
    $a=Get-Map $OriginalPak; $b=Get-Map $RebuiltPak
    foreach($name in $a.Keys){
        if(-not $b.ContainsKey($name)){throw "DEV11 mod PAK safety stop: rebuilt archive lost '$name'."}
        if(-not (Same $a[$name].Bytes $b[$name].Bytes)){
            if([int64]$a[$name].CompressedLength -ne [int64]$b[$name].CompressedLength){
                throw "DEV11 mod PAK safety stop: changed entry '$name' is $($b[$name].CompressedLength) compressed bytes; pristine baseline is $($a[$name].CompressedLength). The live mod was NOT replaced."
            }
        }
    }
}

function Assert-ModEngineTorqueMatchesBaseline($S,[string]$BaselinePak,[string]$CandidatePak) {
    # DEV11 regression guard: a 2.00 request must be exactly 2x the PRISTINE backup,
    # never 4x an already-edited value. Match named Engine variants by Name.
    if(-not $S.IsModTarget){return}
    if([math]::Abs([double]$S.EngineTorque-1.0) -lt 0.0000001){return}
    $entries=@($S.IndividualEngineSourceEntries)
    if($entries.Count -lt 1){return}

    function Get-TorqueMap([string]$Pak,[string]$EntryName){
        $fs=[IO.File]::OpenRead($Pak)
        try{
            $z=New-Object IO.Compression.ZipArchive($fs,[IO.Compression.ZipArchiveMode]::Read)
            try{
                $want=$EntryName.Replace('\\','/')
                $e=$z.Entries|Where-Object{$_.FullName.Replace('\\','/').Equals($want,[StringComparison]::OrdinalIgnoreCase)}|Select-Object -First 1
                if(-not $e){throw "DEV11 torque safety stop: engine entry '$EntryName' was not found."}
                $r=New-Object IO.StreamReader($e.Open(),[Text.Encoding]::UTF8,$true)
                try{$t=$r.ReadToEnd()}finally{$r.Dispose()}
                $map=@{}
                $ms=[regex]::Matches($t,'(?is)<Engine\b(?=[^>]*\bName="([^"]+)")[^>]*>.*?</Engine>')
                foreach($m in $ms){
                    $name=$m.Groups[1].Value
                    $tm=[regex]::Match($m.Value,'(?i)\bTorque="(-?\d+(?:\.\d+)?)"')
                    if($tm.Success){$map[$name]=[double]::Parse($tm.Groups[1].Value,[Globalization.CultureInfo]::InvariantCulture)}
                }
                return $map
            }finally{$z.Dispose()}
        }finally{$fs.Dispose()}
    }

    foreach($entry in $entries){
        $base=Get-TorqueMap $BaselinePak ([string]$entry)
        $cand=Get-TorqueMap $CandidatePak ([string]$entry)
        foreach($name in $base.Keys){
            if(-not $cand.ContainsKey($name)){throw "DEV11 torque safety stop: engine variant '$name' disappeared."}
            $expected=[double]$base[$name]*[double]$S.EngineTorque
            $actual=[double]$cand[$name]
            if([math]::Abs($actual-$expected) -gt [math]::Max(0.000001,[math]::Abs($expected)*0.000000001)){
                throw ("DEV11 torque safety stop: '{0}' requested {1}x from pristine baseline {2}, expected {3}, but candidate contains {4}. The live mod was NOT replaced." -f $name,$S.EngineTorque,$base[$name],$expected,$actual)
            }
        }
    }
}


function Rebuild-ModPakWithWinRAR([string]$OriginalPak,[string]$CandidatePak,[string]$DestinationBasePak=$null) {
    # DEV33: candidate changes are still calculated against the immutable pristine backup,
    # but XML is merged ATTRIBUTE-BY-ATTRIBUTE onto the current trusted live PAK.
    # This prevents a later sibling-truck Apply from restoring earlier sibling values merely
    # because both operations touched the same XML entry.
    $rarCandidates = New-Object Collections.Generic.List[string]
    [void]$rarCandidates.Add('C:\Program Files\WinRAR\WinRAR.exe')
    if($env:ProgramFiles){ [void]$rarCandidates.Add((Join-Path $env:ProgramFiles 'WinRAR\WinRAR.exe')) }
    if(${env:ProgramFiles(x86)}){ [void]$rarCandidates.Add((Join-Path ${env:ProgramFiles(x86)} 'WinRAR\WinRAR.exe')) }
    if($env:LOCALAPPDATA){ [void]$rarCandidates.Add((Join-Path $env:LOCALAPPDATA 'Programs\WinRAR\WinRAR.exe')) }
    $rar=$null
    foreach($r in $rarCandidates){if($r -and (Test-Path -LiteralPath $r -PathType Leaf)){$rar=[IO.Path]::GetFullPath([string]$r);break}}
    if(-not $rar){throw ('DEV48 WinRAR safety stop: WinRAR.exe was not found. Checked: '+(($rarCandidates|Select-Object -Unique)-join '; '))}

    function Get-ZipEntryBytes([string]$Pak,[string]$Name){
        $fs=[IO.File]::OpenRead($Pak);$z=$null
        try{$z=New-Object IO.Compression.ZipArchive($fs,[IO.Compression.ZipArchiveMode]::Read);$e=$z.Entries|Where-Object{$_.FullName.Equals($Name,[StringComparison]::Ordinal)}|Select-Object -First 1;if(-not $e){return $null};$st=$e.Open();$ms=New-Object IO.MemoryStream;try{$st.CopyTo($ms);return $ms.ToArray()}finally{$ms.Dispose();$st.Dispose()}}finally{if($z){$z.Dispose()};$fs.Dispose()}
    }
    function Get-Hash([byte[]]$Bytes){$sha=[Security.Cryptography.SHA256]::Create();try{return [BitConverter]::ToString($sha.ComputeHash($Bytes)).Replace('-','')}finally{$sha.Dispose()}}
    function Get-EntryContentMap([string]$PakPath){
        $map=@{};$fs=[IO.File]::OpenRead($PakPath);$z=$null
        try{$z=New-Object IO.Compression.ZipArchive($fs,[IO.Compression.ZipArchiveMode]::Read);foreach($en in $z.Entries){$st=$en.Open();$ms=New-Object IO.MemoryStream;try{$st.CopyTo($ms);$b=$ms.ToArray()}finally{$ms.Dispose();$st.Dispose()};$map[$en.FullName]=[pscustomobject]@{Hash=(Get-Hash $b);Length=[long]$b.Length}}}finally{if($z){$z.Dispose()};$fs.Dispose()};return $map
    }
    function Convert-SnowRunnerXmlFragment([byte[]]$Bytes){
        # SnowRunner class XML is commonly an XML FRAGMENT, not a standards-compliant
        # one-root XML document (for example <_templates>...</_templates> followed by
        # <EngineVariants>...</EngineVariants>).  DEV33 fed those files directly to
        # XmlDocument.LoadXml(), so every such file failed with "multiple root elements".
        # Wrap the fragment in a private synthetic root solely for the three-way merge.
        $txt=[Text.Encoding]::UTF8.GetString($Bytes)
        # DEV48 cleanup: DEV36-44 Gear Tuning accidentally emitted the characters `r`n`t`t
        # literally before its generated <Gear>. Normalize only that exact legacy token
        # when it immediately precedes a Gear element.
        $txt=[regex]::Replace($txt,'`r`n`t`t(?=<Gear\b)',"`r`n`t`t")
        if($txt.Length -gt 0 -and $txt[0] -eq [char]0xFEFF){$txt=$txt.Substring(1)}
        if([regex]::IsMatch($txt,'(?is)^\s*<\?xml\b')){
            throw 'DEV50 XML-fragment merge safety stop: XML declarations inside SnowRunner fragments are not yet supported.'
        }

        # DEV48: SnowRunner also tolerates comments that are illegal under strict XML
        # (for example a comment body containing "--" or ending in "-").  Comments are
        # non-semantic for WL edits, but XmlDocument refuses to parse them.  Encode every
        # source comment into a legal, reversible base64 marker for the temporary DOM.
        # Merge-XmlBytes restores the exact original comment bytes before writing the PAK.
        $commentRx = New-Object Text.RegularExpressions.Regex('<!--[\s\S]*?-->',[Text.RegularExpressions.RegexOptions]::Singleline)
        $txt = $commentRx.Replace($txt, [Text.RegularExpressions.MatchEvaluator]{
            param($cm)
            $raw=[string]$cm.Value
            $b64=[Convert]::ToBase64String([Text.Encoding]::UTF8.GetBytes($raw))
            return ('<!--WLDEV48COMMENTB64:{0}-->' -f $b64)
        })

        # DEV49: SnowRunner tolerates malformed third-party XML that strict XmlDocument
        # rejects. Preserve semantics instead of choosing a winner:
        #   * bare '&' characters are replaced with a reversible temporary marker;
        #   * second/subsequent duplicate attributes are temporarily renamed to unique
        #     legal attribute names while retaining their original values and order.
        # After the DOM merge, Merge-XmlBytes restores the exact duplicate attribute
        # names and bare ampersands. This lets conflicting duplicate values survive
        # without WL guessing whether the first or last value is authoritative.
        $txt=[regex]::Replace($txt,'&(?!(?:amp|lt|gt|quot|apos);|#\d+;|#x[0-9A-Fa-f]+;)','WLDEV49BAREAMP')

        $tagRx = New-Object Text.RegularExpressions.Regex('<[A-Za-z_][^<>]*>',[Text.RegularExpressions.RegexOptions]::Singleline)
        $attrRx = New-Object Text.RegularExpressions.Regex('(?s)\s+([A-Za-z_:][A-Za-z0-9_:.-]*)\s*=\s*("[^"]*"|''[^'']*'')')
        $txt = $tagRx.Replace($txt, [Text.RegularExpressions.MatchEvaluator]{
            param($tm)
            $tag=[string]$tm.Value
            $matches=@($attrRx.Matches($tag))
            if($matches.Count -lt 2){ return $tag }
            $seen=@{}; $dups=New-Object Collections.Generic.List[object]
            foreach($am in $matches){
                $name=[string]$am.Groups[1].Value
                if($seen.ContainsKey($name)){
                    $ord=[int]$seen[$name]
                    $seen[$name]=$ord+1
                    $hex=([BitConverter]::ToString([Text.Encoding]::UTF8.GetBytes($name))).Replace('-','')
                    $synthetic=('WLDEV49DUPATTR_{0}_{1}' -f $ord,$hex)
                    [void]$dups.Add([pscustomobject]@{Index=$am.Groups[1].Index;Length=$am.Groups[1].Length;Name=$synthetic})
                } else { $seen[$name]=1 }
            }
            for($ri=$dups.Count-1;$ri -ge 0;$ri--){
                $d=$dups[$ri]
                $tag=$tag.Remove($d.Index,$d.Length).Insert($d.Index,$d.Name)
            }
            return $tag
        })
        $doc=New-Object Xml.XmlDocument;$doc.PreserveWhitespace=$true
        try{$doc.LoadXml('<WL_DEV48_FRAGMENT_ROOT>'+$txt+'</WL_DEV48_FRAGMENT_ROOT>')}
        catch{throw ('DEV50 XML-fragment merge safety stop: an edited SnowRunner XML entry could not be parsed: '+$_.Exception.Message)}
        return $doc
    }
    function Merge-XmlNode([Xml.XmlNode]$Base,[Xml.XmlNode]$Cand,[Xml.XmlNode]$Live,[string]$Path){
        if($Base.NodeType -ne $Cand.NodeType -or $Base.NodeType -ne $Live.NodeType -or $Base.Name -ne $Cand.Name -or $Base.Name -ne $Live.Name){throw "DEV50 XML-fragment merge safety stop: structure mismatch at $Path."}
        if($Base.NodeType -eq [Xml.XmlNodeType]::Element){
            $names=New-Object Collections.Generic.HashSet[string]
            foreach($a in @($Base.Attributes)){[void]$names.Add($a.Name)};foreach($a in @($Cand.Attributes)){[void]$names.Add($a.Name)}
            foreach($n in $names){
                $ba=$Base.Attributes[$n];$ca=$Cand.Attributes[$n]
                $bv=if($ba){$ba.Value}else{$null};$cv=if($ca){$ca.Value}else{$null}
                if($bv -cne $cv){if($ca){$Live.SetAttribute($n,$cv)}else{$Live.RemoveAttribute($n)}}
            }
        } elseif($Base.NodeType -in @([Xml.XmlNodeType]::Text,[Xml.XmlNodeType]::CDATA)) {
            if($Base.Value -cne $Cand.Value){$Live.Value=$Cand.Value}
            return
        }

        # DEV48: SnowRunner Gear Tuning intentionally adds ONE extra <Gear> child to a
        # gearbox variant.  DEV35's original three-way merger correctly refused every
        # child-count change, which protected shared PAKs but also blocked this known-safe
        # editor-owned structural edit during real Apply.  Permit ONLY trailing element
        # additions that can be proven to come from pristine -> candidate, while keeping
        # all pre-existing baseline children aligned and recursively merged into live.
        # Unexpected insertions/reorders/removals still fail closed.
        $be=@($Base.ChildNodes | Where-Object {$_.NodeType -eq [Xml.XmlNodeType]::Element})
        $ce=@($Cand.ChildNodes | Where-Object {$_.NodeType -eq [Xml.XmlNodeType]::Element})
        $le=@($Live.ChildNodes | Where-Object {$_.NodeType -eq [Xml.XmlNodeType]::Element})

        if($be.Count -eq 0 -and $ce.Count -eq 0 -and $le.Count -eq 0){
            $bc=@($Base.ChildNodes);$cc=@($Cand.ChildNodes);$lc=@($Live.ChildNodes)
            if($bc.Count -ne $cc.Count -or $bc.Count -ne $lc.Count){throw "DEV50 XML-fragment merge safety stop: non-element child structure changed at $Path."}
            for($i=0;$i -lt $bc.Count;$i++){Merge-XmlNode $bc[$i] $cc[$i] $lc[$i] ($Path+'/'+$bc[$i].Name+'['+$i+']')}
            return
        }

        if($ce.Count -lt $be.Count){throw "DEV50 XML-fragment merge safety stop: candidate removed element children at $Path."}

        # DEV48: Gear Tuning owns exactly one structural edit: it adds one extra
        # direct <Gear> after the stock forward-gear run.  Do NOT make the generic
        # XML merger guess child positions.  Recognize this operation by keyed child
        # type counts instead: candidate must contain exactly one more direct Gear,
        # while every non-Gear direct child remains identical in name/order.
        # Live may be pristine-shaped (first Apply) or candidate-shaped (safe re-Apply).
        $baseGears=@($be | Where-Object {$_.Name -ceq 'Gear'})
        $candGears=@($ce | Where-Object {$_.Name -ceq 'Gear'})
        $liveGears=@($le | Where-Object {$_.Name -ceq 'Gear'})

        # DEV50: sibling truck definitions can share one physical gearbox family.
        # If an earlier WL Apply already added the single editor-owned forward Gear
        # to LIVE, a later sibling may legitimately SKIP Gear Tuning, leaving its
        # pristine->candidate structure unchanged. Preserve that proven live Gear
        # instead of treating the trusted cumulative WL state as a foreign conflict.
        if($baseGears.Count -ge 2 -and $candGears.Count -eq $baseGears.Count -and $liveGears.Count -eq ($baseGears.Count+1)){
            $baseNon=@($be | Where-Object {$_.Name -cne 'Gear'})
            $candNon=@($ce | Where-Object {$_.Name -cne 'Gear'})
            $liveNon=@($le | Where-Object {$_.Name -cne 'Gear'})
            $nonOk=($baseNon.Count -eq $candNon.Count -and $baseNon.Count -eq $liveNon.Count)
            if($nonOk){
                for($k=0;$k -lt $baseNon.Count;$k++){
                    if($baseNon[$k].Name -cne $candNon[$k].Name -or $baseNon[$k].Name -cne $liveNon[$k].Name){$nonOk=$false;break}
                }
            }
            if($nonOk){
                $lastBaseGearIndex=-1
                for($k=0;$k -lt $be.Count;$k++){if($be[$k].Name -ceq 'Gear'){$lastBaseGearIndex=$k}}
                $expectedExtraIndex=$lastBaseGearIndex+1
                if($lastBaseGearIndex -ge 0 -and $le.Count -eq ($be.Count+1) -and $expectedExtraIndex -lt $le.Count -and $le[$expectedExtraIndex].Name -ceq 'Gear'){
                    $seqOk=$true
                    for($k=0;$k -lt $be.Count;$k++){
                        $li=if($k -le $lastBaseGearIndex){$k}else{$k+1}
                        if($li -ge $le.Count -or $be[$k].Name -cne $ce[$k].Name -or $be[$k].Name -cne $le[$li].Name){$seqOk=$false;break}
                    }
                    if($seqOk){
                        for($k=0;$k -lt $be.Count;$k++){
                            $li=if($k -le $lastBaseGearIndex){$k}else{$k+1}
                            Merge-XmlNode $be[$k] $ce[$k] $le[$li] ($Path+'/'+$be[$k].Name+'['+$k+']')
                        }
                        return
                    }
                }
            }
        }

        if($baseGears.Count -ge 2 -and $candGears.Count -eq ($baseGears.Count+1)){
            $baseNon=@($be | Where-Object {$_.Name -cne 'Gear'})
            $candNon=@($ce | Where-Object {$_.Name -cne 'Gear'})
            $liveNon=@($le | Where-Object {$_.Name -cne 'Gear'})
            $nonOk=($baseNon.Count -eq $candNon.Count -and $baseNon.Count -eq $liveNon.Count)
            if($nonOk){
                for($k=0;$k -lt $baseNon.Count;$k++){
                    if($baseNon[$k].Name -cne $candNon[$k].Name -or $baseNon[$k].Name -cne $liveNon[$k].Name){$nonOk=$false;break}
                }
            }
            if($nonOk -and ($liveGears.Count -eq $baseGears.Count -or $liveGears.Count -eq $candGears.Count)){
                # Prove the full direct-child sequence differs only by ONE extra Gear
                # located after the final stock Gear.  This catches Gearbox variants
                # regardless of the surrounding element/tag naming convention.
                $lastBaseGearIndex=-1
                for($k=0;$k -lt $be.Count;$k++){if($be[$k].Name -ceq 'Gear'){$lastBaseGearIndex=$k}}
                $lastCandGearIndex=-1
                for($k=0;$k -lt $ce.Count;$k++){if($ce[$k].Name -ceq 'Gear'){$lastCandGearIndex=$k}}
                if($lastBaseGearIndex -ge 0 -and $lastCandGearIndex -eq ($lastBaseGearIndex+1)){
                    $seqOk=$true
                    for($k=0;$k -lt $be.Count;$k++){
                        $ci=if($k -le $lastBaseGearIndex){$k}else{$k+1}
                        if($be[$k].Name -cne $ce[$ci].Name){$seqOk=$false;break}
                    }
                    if($seqOk){
                        # Merge every pristine child against its corresponding candidate
                        # and live child, skipping only the editor-owned extra Gear.
                        for($k=0;$k -lt $be.Count;$k++){
                            $ci=if($k -le $lastBaseGearIndex){$k}else{$k+1}
                            $li=$k
                            if($liveGears.Count -eq $candGears.Count -and $k -gt $lastBaseGearIndex){$li=$k+1}
                            if($li -ge $le.Count -or $be[$k].Name -cne $le[$li].Name){throw "DEV50 XML-fragment merge safety stop: keyed Gear child alignment mismatch at $Path."}
                            Merge-XmlNode $be[$k] $ce[$ci] $le[$li] ($Path+'/'+$be[$k].Name+'['+$k+']')
                        }

                        $extraCand=$ce[$lastCandGearIndex]
                        $clone=$Live.OwnerDocument.ImportNode($extraCand,$true)
                        if($liveGears.Count -eq $baseGears.Count){
                            # First Apply: insert immediately after the last live stock Gear.
                            $liveElements=@($Live.ChildNodes | Where-Object {$_.NodeType -eq [Xml.XmlNodeType]::Element})
                            $anchor=$null
                            $insertElementIndex=$lastBaseGearIndex+1
                            if($insertElementIndex -lt $liveElements.Count){$anchor=$liveElements[$insertElementIndex]}
                            if($anchor){[void]$Live.InsertBefore($clone,$anchor)}else{[void]$Live.AppendChild($clone)}
                        } else {
                            # Re-Apply: replace only the editor-owned final forward Gear.
                            $liveElements=@($Live.ChildNodes | Where-Object {$_.NodeType -eq [Xml.XmlNodeType]::Element})
                            $extraLiveIndex=$lastBaseGearIndex+1
                            if($extraLiveIndex -ge $liveElements.Count -or $liveElements[$extraLiveIndex].Name -cne 'Gear'){
                                throw "DEV50 XML-fragment merge safety stop: existing editor-owned Gear could not be proven at $Path."
                            }
                            [void]$Live.ReplaceChild($clone,$liveElements[$extraLiveIndex])
                        }
                        return
                    }
                }
            }
        }

        # Generic structure path remains strict. Trailing additions are still supported
        # for any previously-proven editor-owned case; mid-structure edits remain blocked.
        if($le.Count -ne $be.Count -and $le.Count -ne $ce.Count){throw "DEV50 XML-fragment merge safety stop: live element structure conflicts at $Path."}

        for($i=0;$i -lt $be.Count;$i++){
            if($be[$i].Name -cne $ce[$i].Name -or $be[$i].Name -cne $le[$i].Name){throw "DEV50 XML-fragment merge safety stop: unsupported child insertion/reorder at $Path."}
            Merge-XmlNode $be[$i] $ce[$i] $le[$i] ($Path+'/'+$be[$i].Name+'['+$i+']')
        }

        $extra=$ce.Count-$be.Count
        if($extra -gt 0){
            if($le.Count -eq $be.Count){
                for($i=$be.Count;$i -lt $ce.Count;$i++){
                    $clone=$Live.OwnerDocument.ImportNode($ce[$i],$true)
                    $anchor=$null
                    foreach($ch in @($Live.ChildNodes)){
                        if($ch.NodeType -eq [Xml.XmlNodeType]::Text -and [string]::IsNullOrWhiteSpace($ch.Value)){$anchor=$ch}
                    }
                    if($anchor){[void]$Live.InsertBefore($clone,$anchor)}else{[void]$Live.AppendChild($clone)}
                }
            } else {
                for($i=$be.Count;$i -lt $ce.Count;$i++){
                    if($le[$i].Name -cne $ce[$i].Name){throw "DEV50 XML-fragment merge safety stop: editor-owned trailing child mismatch at $Path."}
                    $clone=$Live.OwnerDocument.ImportNode($ce[$i],$true)
                    [void]$Live.ReplaceChild($clone,$le[$i])
                }
            }
        }
    }
    function Merge-XmlBytes([byte[]]$BaseBytes,[byte[]]$CandBytes,[byte[]]$LiveBytes){
        $b=Convert-SnowRunnerXmlFragment $BaseBytes;$c=Convert-SnowRunnerXmlFragment $CandBytes;$l=Convert-SnowRunnerXmlFragment $LiveBytes
        Merge-XmlNode $b.DocumentElement $c.DocumentElement $l.DocumentElement '/fragment'
        # Emit only the synthetic root's contents.  The wrapper must NEVER enter the PAK.
        $outText=$l.DocumentElement.InnerXml
        # Restore comments byte-for-byte from the reversible temporary DOM markers.
        $outText=[regex]::Replace($outText,'<!--WLDEV48COMMENTB64:([A-Za-z0-9+/=]+)-->',[Text.RegularExpressions.MatchEvaluator]{
            param($m)
            try{return [Text.Encoding]::UTF8.GetString([Convert]::FromBase64String($m.Groups[1].Value))}
            catch{throw 'DEV50 XML-fragment merge safety stop: a temporary encoded comment marker could not be restored.'}
        })
        # DEV49: restore temporarily renamed duplicate attribute names and raw ampersands.
        $outText=[regex]::Replace($outText,'WLDEV49DUPATTR_\d+_([0-9A-F]+)',[Text.RegularExpressions.MatchEvaluator]{
            param($m)
            try{
                $hex=$m.Groups[1].Value
                $bytes=New-Object byte[] ($hex.Length/2)
                for($i=0;$i -lt $bytes.Length;$i++){$bytes[$i]=[Convert]::ToByte($hex.Substring($i*2,2),16)}
                return [Text.Encoding]::UTF8.GetString($bytes)
            } catch { throw 'DEV49 XML-fragment merge safety stop: a temporary duplicate-attribute marker could not be restored.' }
        })
        $outText=$outText.Replace('WLDEV49BAREAMP','&')
        return (New-Object Text.UTF8Encoding($false)).GetBytes($outText)
    }

    $origMap=Get-EntryContentMap $OriginalPak;$candMap=Get-EntryContentMap $CandidatePak
    $changed=New-Object Collections.Generic.List[string]
    foreach($name in $origMap.Keys){if(-not $candMap.ContainsKey($name)){throw "DEV48 safety stop: candidate is missing '$name'."};if($origMap[$name].Hash -ne $candMap[$name].Hash -or $origMap[$name].Length -ne $candMap[$name].Length){[void]$changed.Add([string]$name)}}
    foreach($name in $candMap.Keys){if(-not $origMap.ContainsKey($name)){throw "DEV48 safety stop: candidate unexpectedly added '$name'."}}
    if($changed.Count -lt 1){throw 'DEV48 safety stop: no changed entries were detected.'}

    $rebuildBase=if([string]::IsNullOrWhiteSpace($DestinationBasePak)){$OriginalPak}else{$DestinationBasePak}
    $stage=Join-Path ([IO.Path]::GetTempPath()) ('WL-DEV48-Merge-'+[guid]::NewGuid().ToString('N'));New-Item -ItemType Directory -Path $stage -Force|Out-Null
    $expected=@{}
    try{
        foreach($name in $changed){
            $bb=Get-ZipEntryBytes $OriginalPak $name;$cb=Get-ZipEntryBytes $CandidatePak $name;$lb=Get-ZipEntryBytes $rebuildBase $name
            if($null -eq $bb -or $null -eq $cb -or $null -eq $lb){throw "DEV48 safety stop: could not read '$name' from all three PAK states."}
            if($name.EndsWith('.xml',[StringComparison]::OrdinalIgnoreCase)){$out=Merge-XmlBytes $bb $cb $lb}else{$out=$cb}
            $dest=Join-Path $stage ($name.Replace('/','\'));$dir=[IO.Path]::GetDirectoryName($dest);if($dir){New-Item -ItemType Directory -Path $dir -Force|Out-Null};[IO.File]::WriteAllBytes($dest,$out);$expected[$name]=Get-Hash $out
        }
        Copy-Item -LiteralPath $rebuildBase -Destination $CandidatePak -Force
        foreach($name in $changed){
            $rel=$name.Replace('/','\');$f=Join-Path $stage $rel;$fileName=[IO.Path]::GetFileName($f);$archiveDir=([IO.Path]::GetDirectoryName($rel).Replace('\','/'))
            $psi=New-Object Diagnostics.ProcessStartInfo;$psi.FileName=$rar;$psi.WorkingDirectory=[IO.Path]::GetDirectoryName($f);$psi.UseShellExecute=$false;$psi.CreateNoWindow=$true;$psi.WindowStyle=[Diagnostics.ProcessWindowStyle]::Hidden;$psi.RedirectStandardOutput=$true;$psi.RedirectStandardError=$true
            if([string]::IsNullOrWhiteSpace($archiveDir)){$psi.Arguments=('a -afzip -o+ -inul "{0}" "{1}"' -f $CandidatePak,$fileName)}else{$psi.Arguments=('a -afzip -o+ -inul -ap"{0}" "{1}" "{2}"' -f $archiveDir,$CandidatePak,$fileName)}
            $pr=[Diagnostics.Process]::Start($psi);$null=$pr.StandardOutput.ReadToEnd();$null=$pr.StandardError.ReadToEnd();$pr.WaitForExit();if($pr.ExitCode -ne 0){throw "DEV48 WinRAR safety stop: exit code $($pr.ExitCode) replacing '$name'."}
        }
        $finalMap=Get-EntryContentMap $CandidatePak
        foreach($name in $changed){if(-not $finalMap.ContainsKey($name) -or $finalMap[$name].Hash -ne $expected[$name]){throw "DEV48 merge safety stop: final '$name' does not match merged bytes."}}
    }finally{if(Test-Path -LiteralPath $stage){Remove-Item -LiteralPath $stage -Recurse -Force -ErrorAction SilentlyContinue}}
}
function Preserve-ModPakHybridReplacementLayout([string]$OriginalPak,[string]$RebuiltPak) {
    # DEV14: match the successful MANUAL replacement behavior as closely as possible.
    #
    # The working Cat MT700 control proved SnowRunner accepts a hybrid ZIP where:
    # - untouched entries retain the original PAK records/metadata
    # - only changed XML entries are freshly deflated/replaced
    # - logical entry order is preserved (the changed engine stayed at index 1)
    # - the changed entry is allowed to keep the NEW writer's central-directory metadata
    #   instead of forcing the original Unix metadata back onto it
    # - no artificial same-size, original-offset, 4096-alignment, or trailing-padding rule
    #   is imposed.
    #
    # This function therefore takes the changed local record AND changed central record
    # from the .NET Update candidate, while copying untouched records byte-for-byte from
    # the pristine baseline. It then emits the central directory in the ORIGINAL logical
    # order with all local-header offsets patched to the newly written positions.
    # Standard non-ZIP64, single-disk archives only; anything else fails closed.

    $orig=[IO.File]::ReadAllBytes($OriginalPak)
    $edit=[IO.File]::ReadAllBytes($RebuiltPak)

    function Find-Eocd14([byte[]]$b) {
        for($i=$b.Length-22; $i -ge [Math]::Max(0,$b.Length-65557); $i--) {
            if($b[$i]-eq 0x50 -and $b[$i+1]-eq 0x4b -and $b[$i+2]-eq 0x05 -and $b[$i+3]-eq 0x06) { return $i }
        }
        throw 'DEV14 mod PAK safety stop: ZIP end-of-central-directory record was not found.'
    }

    function Read-Central14([byte[]]$b) {
        $eocd=Find-Eocd14 $b
        $disk=[BitConverter]::ToUInt16($b,$eocd+4)
        $cdDisk=[BitConverter]::ToUInt16($b,$eocd+6)
        $count=[BitConverter]::ToUInt16($b,$eocd+10)
        $cdSize=[BitConverter]::ToUInt32($b,$eocd+12)
        $cdOff=[BitConverter]::ToUInt32($b,$eocd+16)
        $commentLen=[BitConverter]::ToUInt16($b,$eocd+20)
        if($disk -ne 0 -or $cdDisk -ne 0 -or $count -eq 0xFFFF -or $cdOff -eq 0xFFFFFFFF -or $cdSize -eq 0xFFFFFFFF) {
            throw 'DEV14 mod PAK safety stop: ZIP64 or multi-disk mod PAKs are not supported.'
        }
        if($eocd+22+$commentLen -gt $b.Length){ throw 'DEV14 mod PAK safety stop: invalid ZIP comment length.' }
        $list=New-Object Collections.Generic.List[object]
        $seen=@{}
        $p=[int]$cdOff
        for($n=0;$n -lt $count;$n++) {
            if($p+46 -gt $b.Length -or $b[$p]-ne 0x50 -or $b[$p+1]-ne 0x4b -or $b[$p+2]-ne 0x01 -or $b[$p+3]-ne 0x02) {
                throw "DEV14 mod PAK safety stop: invalid central-directory entry at index $n."
            }
            $flags=[BitConverter]::ToUInt16($b,$p+8)
            $crc=[BitConverter]::ToUInt32($b,$p+16)
            $csize=[BitConverter]::ToUInt32($b,$p+20)
            $usize=[BitConverter]::ToUInt32($b,$p+24)
            $nl=[BitConverter]::ToUInt16($b,$p+28)
            $xl=[BitConverter]::ToUInt16($b,$p+30)
            $cl=[BitConverter]::ToUInt16($b,$p+32)
            $lo=[BitConverter]::ToUInt32($b,$p+42)
            $recLen=46+$nl+$xl+$cl
            if($p+$recLen -gt $b.Length){ throw 'DEV14 mod PAK safety stop: truncated central-directory record.' }
            $enc=if(($flags -band 0x0800) -ne 0){[Text.Encoding]::UTF8}else{[Text.Encoding]::GetEncoding(437)}
            $name=$enc.GetString($b,$p+46,$nl)
            if($seen.ContainsKey($name)){ throw "DEV14 mod PAK safety stop: duplicate ZIP entry '$name' is not supported." }
            $seen[$name]=$true
            [void]$list.Add([pscustomobject]@{
                Name=$name; CentralOffset=[int]$p; CentralLength=[int]$recLen;
                LocalOffset=[int]$lo; CRC=[uint32]$crc; CompressedSize=[uint32]$csize; UncompressedSize=[uint32]$usize
            })
            $p += $recLen
        }
        if($p -ne ([int]$cdOff+[int]$cdSize)){ throw 'DEV14 mod PAK safety stop: central-directory size does not match parsed records.' }
        return [pscustomobject]@{Entries=[object[]]$list.ToArray();CdOffset=[int]$cdOff;CdSize=[int]$cdSize;Eocd=[int]$eocd;CommentLength=[int]$commentLen}
    }

    function Add-LocalEnds14([byte[]]$b,$info) {
        $physical=@($info.Entries | Sort-Object LocalOffset)
        for($i=0;$i -lt $physical.Count;$i++) {
            $end=if($i+1 -lt $physical.Count){[int]$physical[$i+1].LocalOffset}else{[int]$info.CdOffset}
            if($end -le [int]$physical[$i].LocalOffset){ throw 'DEV14 mod PAK safety stop: invalid local-record ordering.' }
            Add-Member -InputObject $physical[$i] -NotePropertyName LocalEnd -NotePropertyValue $end -Force
        }
    }

    $o=Read-Central14 $orig
    $e=Read-Central14 $edit
    if($o.Entries.Count -ne $e.Entries.Count){ throw 'DEV14 mod PAK safety stop: edited archive entry count differs from baseline.' }
    Add-LocalEnds14 $orig $o
    Add-LocalEnds14 $edit $e

    $emap=@{}
    foreach($x in $e.Entries){ $emap[$x.Name]=$x }
    foreach($x in $o.Entries){ if(-not $emap.ContainsKey($x.Name)){ throw "DEV14 mod PAK safety stop: edited archive is missing '$($x.Name)'." } }

    $changed=@{}
    foreach($x in $o.Entries){
        $y=$emap[$x.Name]
        if($x.CRC -ne $y.CRC -or $x.CompressedSize -ne $y.CompressedSize -or $x.UncompressedSize -ne $y.UncompressedSize){ $changed[$x.Name]=$true }
    }
    if($changed.Count -lt 1){ throw 'DEV14 mod PAK safety stop: no changed ZIP entries were detected.' }

    $ms=New-Object IO.MemoryStream
    $newOffsets=@{}
    try {
        # Local records: original logical order; changed records come from the Update candidate.
        foreach($x in $o.Entries){
            $srcInfo=if($changed.ContainsKey($x.Name)){$emap[$x.Name]}else{$x}
            $srcBytes=if($changed.ContainsKey($x.Name)){$edit}else{$orig}
            $start=[int]$srcInfo.LocalOffset
            $len=[int]$srcInfo.LocalEnd-$start
            $newOffsets[$x.Name]=[uint32]$ms.Position
            $ms.Write($srcBytes,$start,$len)
        }

        $newCdOffset=[uint32]$ms.Position

        # Central directory: untouched entries use original metadata; changed entries use
        # the NEW writer's metadata. Only the local-header offset is patched.
        foreach($x in $o.Entries){
            $srcInfo=if($changed.ContainsKey($x.Name)){$emap[$x.Name]}else{$x}
            $srcBytes=if($changed.ContainsKey($x.Name)){$edit}else{$orig}
            $record=New-Object byte[] $srcInfo.CentralLength
            [Array]::Copy($srcBytes,$srcInfo.CentralOffset,$record,0,$srcInfo.CentralLength)
            [Array]::Copy([BitConverter]::GetBytes([uint32]$newOffsets[$x.Name]),0,$record,42,4)
            $ms.Write($record,0,$record.Length)
        }

        $newCdSize=[uint32]($ms.Position-$newCdOffset)

        # Write a conventional EOCD copied from the candidate, with patched CD size/offset.
        # DEV14 intentionally does NOT restore old post-EOCD padding/alignment.
        $eocdLen=22+$e.CommentLength
        $eocd=New-Object byte[] $eocdLen
        [Array]::Copy($edit,$e.Eocd,$eocd,0,$eocdLen)
        [Array]::Copy([BitConverter]::GetBytes([uint32]$newCdSize),0,$eocd,12,4)
        [Array]::Copy([BitConverter]::GetBytes([uint32]$newCdOffset),0,$eocd,16,4)
        $ms.Write($eocd,0,$eocd.Length)

        [IO.File]::WriteAllBytes($RebuiltPak,$ms.ToArray())
    } finally { $ms.Dispose() }
}

function Preserve-ModPakOriginalEntryOrder([string]$OriginalPak,[string]$RebuiltPak) {
    # DEV7:
    # .NET ZipArchive Update appends a replaced entry to the end of the archive.
    # SnowRunner rejected that layout on the Cat MT700.
    #
    # Rebuild the ZIP at RECORD level:
    # - untouched local records come byte-for-byte from the pristine backup
    # - changed local records come from the edited temp PAK
    # - original entry order is preserved
    # - original central-directory metadata is preserved
    # - only CRC/sizes/offsets are patched for changed entries
    #
    # Standard non-ZIP64, single-disk archives only. Anything else fails closed.

    $orig=[IO.File]::ReadAllBytes($OriginalPak)
    $edit=[IO.File]::ReadAllBytes($RebuiltPak)

    function Find-Eocd([byte[]]$b) {
        for($i=$b.Length-22; $i -ge [Math]::Max(0,$b.Length-65557); $i--) {
            if($b[$i]-eq 0x50 -and $b[$i+1]-eq 0x4b -and $b[$i+2]-eq 0x05 -and $b[$i+3]-eq 0x06) { return $i }
        }
        throw 'DEV7 mod PAK safety stop: ZIP end-of-central-directory record was not found.'
    }

    function Read-Central([byte[]]$b) {
        $eocd=Find-Eocd $b
        $disk=[BitConverter]::ToUInt16($b,$eocd+4)
        $cdDisk=[BitConverter]::ToUInt16($b,$eocd+6)
        $count=[BitConverter]::ToUInt16($b,$eocd+10)
        $cdSize=[BitConverter]::ToUInt32($b,$eocd+12)
        $cdOff=[BitConverter]::ToUInt32($b,$eocd+16)
        $commentLen=[BitConverter]::ToUInt16($b,$eocd+20)
        if($disk -ne 0 -or $cdDisk -ne 0 -or $count -eq 0xFFFF -or $cdOff -eq 0xFFFFFFFF -or $cdSize -eq 0xFFFFFFFF) {
            throw 'DEV7 mod PAK safety stop: ZIP64 or multi-disk mod PAKs are not supported by the surgical writer.'
        }
        if($eocd+22+$commentLen -gt $b.Length) { throw 'DEV7 mod PAK safety stop: invalid ZIP comment length.' }

        $list=New-Object Collections.Generic.List[object]
        $seen=@{}
        $p=[int]$cdOff
        for($n=0;$n -lt $count;$n++) {
            if($p+46 -gt $b.Length -or $b[$p]-ne 0x50 -or $b[$p+1]-ne 0x4b -or $b[$p+2]-ne 0x01 -or $b[$p+3]-ne 0x02) {
                throw "DEV7 mod PAK safety stop: invalid central-directory entry at index $n."
            }
            $flags=[BitConverter]::ToUInt16($b,$p+8)
            $crc=[BitConverter]::ToUInt32($b,$p+16)
            $csize=[BitConverter]::ToUInt32($b,$p+20)
            $usize=[BitConverter]::ToUInt32($b,$p+24)
            $nl=[BitConverter]::ToUInt16($b,$p+28)
            $xl=[BitConverter]::ToUInt16($b,$p+30)
            $cl=[BitConverter]::ToUInt16($b,$p+32)
            $lo=[BitConverter]::ToUInt32($b,$p+42)
            $recLen=46+$nl+$xl+$cl
            if($p+$recLen -gt $b.Length) { throw 'DEV7 mod PAK safety stop: truncated central-directory record.' }
            $enc=if(($flags -band 0x0800) -ne 0){[Text.Encoding]::UTF8}else{[Text.Encoding]::GetEncoding(437)}
            $name=$enc.GetString($b,$p+46,$nl)
            if($seen.ContainsKey($name)){ throw "DEV7 mod PAK safety stop: duplicate ZIP entry '$name' is not supported." }
            $seen[$name]=$true
            [void]$list.Add([pscustomobject]@{
                Name=$name; CentralOffset=[int]$p; CentralLength=[int]$recLen;
                LocalOffset=[int]$lo; CRC=[uint32]$crc; CompressedSize=[uint32]$csize; UncompressedSize=[uint32]$usize
            })
            $p += $recLen
        }
        if($p -ne ([int]$cdOff+[int]$cdSize)){ throw 'DEV7 mod PAK safety stop: central-directory size does not match parsed records.' }
        return [pscustomobject]@{ Entries=[object[]]$list.ToArray(); CdOffset=[int]$cdOff; CdSize=[int]$cdSize; Eocd=[int]$eocd; CommentLength=[int]$commentLen }
    }

    function Add-LocalEnds([byte[]]$b,$info) {
        $physical=@($info.Entries | Sort-Object LocalOffset)
        for($i=0;$i -lt $physical.Count;$i++) {
            $end=if($i+1 -lt $physical.Count){[int]$physical[$i+1].LocalOffset}else{[int]$info.CdOffset}
            if($end -le [int]$physical[$i].LocalOffset){throw 'DEV7 mod PAK safety stop: invalid local-record ordering.'}
            Add-Member -InputObject $physical[$i] -NotePropertyName LocalEnd -NotePropertyValue $end -Force
        }
    }

    $o=Read-Central $orig
    $e=Read-Central $edit
    if($o.Entries.Count -ne $e.Entries.Count){throw 'DEV7 mod PAK safety stop: edited archive entry count differs from original.'}
    Add-LocalEnds $orig $o
    Add-LocalEnds $edit $e

    $emap=@{}
    foreach($x in $e.Entries){$emap[$x.Name]=$x}
    foreach($x in $o.Entries){if(-not $emap.ContainsKey($x.Name)){throw "DEV7 mod PAK safety stop: edited archive is missing '$($x.Name)'."}}

    $changed=@{}
    foreach($x in $o.Entries){
        $y=$emap[$x.Name]
        if($x.CRC -ne $y.CRC -or $x.CompressedSize -ne $y.CompressedSize -or $x.UncompressedSize -ne $y.UncompressedSize){
            $changed[$x.Name]=$true
        }
    }
    if($changed.Count -lt 1){throw 'DEV7 mod PAK safety stop: no changed ZIP entries were detected.'}

    $ms=New-Object IO.MemoryStream
    $newOffsets=@{}
    try {
        # Write local records in ORIGINAL logical order.
        foreach($x in $o.Entries){
            $srcInfo=if($changed.ContainsKey($x.Name)){$emap[$x.Name]}else{$x}
            $srcBytes=if($changed.ContainsKey($x.Name)){$edit}else{$orig}
            $start=[int]$srcInfo.LocalOffset
            $len=[int]$srcInfo.LocalEnd-$start
            $newOffsets[$x.Name]=[uint32]$ms.Position
            $ms.Write($srcBytes,$start,$len)
        }

        $newCdOffset=[uint32]$ms.Position

        # Central directory remains in ORIGINAL order and uses ORIGINAL metadata.
        foreach($x in $o.Entries){
            $record=New-Object byte[] $x.CentralLength
            [Array]::Copy($orig,$x.CentralOffset,$record,0,$x.CentralLength)
            if($changed.ContainsKey($x.Name)){
                $y=$emap[$x.Name]
                [Array]::Copy([BitConverter]::GetBytes([uint32]$y.CRC),0,$record,16,4)
                [Array]::Copy([BitConverter]::GetBytes([uint32]$y.CompressedSize),0,$record,20,4)
                [Array]::Copy([BitConverter]::GetBytes([uint32]$y.UncompressedSize),0,$record,24,4)
            }
            [Array]::Copy([BitConverter]::GetBytes([uint32]$newOffsets[$x.Name]),0,$record,42,4)
            $ms.Write($record,0,$record.Length)
        }

        $newCdSize=[uint32]($ms.Position-$newCdOffset)

        # DEV9: Preserve the EOCD/comment, then preserve the ORIGINAL ALIGNMENT RULE.
        # DEV8 copied the original padding length literally. That was wrong when the
        # edited compressed entry changed size: Cat MT700 grew by one byte, so copying
        # the same 440 zero bytes produced 311297 bytes instead of the original 4096-byte
        # aligned 311296-byte layout. SnowRunner still skipped the truck.
        #
        # If the original post-EOCD bytes are all zero padding and the original archive
        # is 4096-byte aligned, dynamically re-pad the edited archive to the NEXT 4096
        # boundary. Otherwise preserve the original post-EOCD bytes exactly.
        $eocdLen=22+$o.CommentLength
        if($o.Eocd+$eocdLen -gt $orig.Length){ throw 'DEV9 mod PAK safety stop: original ZIP EOCD/comment exceeds archive length.' }

        $eocd=New-Object byte[] $eocdLen
        [Array]::Copy($orig,$o.Eocd,$eocd,0,$eocdLen)
        [Array]::Copy([BitConverter]::GetBytes([uint32]$newCdSize),0,$eocd,12,4)
        [Array]::Copy([BitConverter]::GetBytes([uint32]$newCdOffset),0,$eocd,16,4)
        $ms.Write($eocd,0,$eocd.Length)

        $postStart=$o.Eocd+$eocdLen
        $postLen=$orig.Length-$postStart
        $allZero=$true
        if($postLen -gt 0){
            for($zi=$postStart;$zi -lt $orig.Length;$zi++){ if($orig[$zi] -ne 0){ $allZero=$false; break } }
        }

        if($postLen -gt 0 -and $allZero -and (($orig.Length % 4096) -eq 0)){
            $rem=[int]($ms.Position % 4096)
            $pad=if($rem -eq 0){0}else{4096-$rem}
            if($pad -gt 0){
                $zeros=New-Object byte[] $pad
                $ms.Write($zeros,0,$zeros.Length)
            }
        } elseif($postLen -gt 0) {
            $post=New-Object byte[] $postLen
            [Array]::Copy($orig,$postStart,$post,0,$postLen)
            $ms.Write($post,0,$post.Length)
        }

        [IO.File]::WriteAllBytes($RebuiltPak,$ms.ToArray())
    } finally {
        $ms.Dispose()
    }
}

function Restore-ModZipCentralDirectoryMetadata([string]$OriginalPak, [string]$RebuiltPak) {
    # DEV5: ZipArchive.Create strips the original host-system/external attributes.
    # Preserve those central-directory fields from the untouched mod backup.
    $orig=[IO.File]::ReadAllBytes($OriginalPak); $reb=[IO.File]::ReadAllBytes($RebuiltPak)
    function Read-Central([byte[]]$b){
        $map=@{};$i=0
        while($i -le $b.Length-46){
            if($b[$i]-eq 0x50 -and $b[$i+1]-eq 0x4b -and $b[$i+2]-eq 0x01 -and $b[$i+3]-eq 0x02){
                $nl=[BitConverter]::ToUInt16($b,$i+28);$xl=[BitConverter]::ToUInt16($b,$i+30);$cl=[BitConverter]::ToUInt16($b,$i+32)
                if($i+46+$nl+$xl+$cl -gt $b.Length){break}
                $name=[Text.Encoding]::UTF8.GetString($b,$i+46,$nl)
                $map[$name]=[pscustomobject]@{MadeBy=[BitConverter]::ToUInt16($b,$i+4);External=[BitConverter]::ToUInt32($b,$i+38)}
                $i+=46+$nl+$xl+$cl
            }else{$i++}
        };return $map
    }
    $meta=Read-Central $orig;$i=0;$patched=0
    while($i -le $reb.Length-46){
        if($reb[$i]-eq 0x50 -and $reb[$i+1]-eq 0x4b -and $reb[$i+2]-eq 0x01 -and $reb[$i+3]-eq 0x02){
            $nl=[BitConverter]::ToUInt16($reb,$i+28);$xl=[BitConverter]::ToUInt16($reb,$i+30);$cl=[BitConverter]::ToUInt16($reb,$i+32)
            if($i+46+$nl+$xl+$cl -gt $reb.Length){break}
            $name=[Text.Encoding]::UTF8.GetString($reb,$i+46,$nl)
            if($meta.ContainsKey($name)){
                [Array]::Copy([BitConverter]::GetBytes([uint16]$meta[$name].MadeBy),0,$reb,$i+4,2)
                [Array]::Copy([BitConverter]::GetBytes([uint32]$meta[$name].External),0,$reb,$i+38,4)
                $patched++
            }
            $i+=46+$nl+$xl+$cl
        }else{$i++}
    }
    if($patched -ne $meta.Count){throw "DEV5 mod PAK metadata safety stop: restored $patched of $($meta.Count) entries."}
    [IO.File]::WriteAllBytes($RebuiltPak,$reb)
}

function Set-LastModEditorOutputHash([string]$Pak) {
    $metaPath=Get-ModBackupMetaPath $Pak
    if(Test-Path -LiteralPath $metaPath){$meta=Get-Content -LiteralPath $metaPath -Raw|ConvertFrom-Json;$meta.LastEditorOutputHash=Get-FileSha256 $Pak;$meta|ConvertTo-Json|Set-Content -LiteralPath $metaPath -Encoding UTF8}
}

function Get-BackupPath([string]$PakPath) {
    return Join-Path ([IO.Path]::GetDirectoryName($PakPath)) 'initial.original.pak'
}

function Get-BackupMetaPath([string]$PakPath) {
    return Join-Path ([IO.Path]::GetDirectoryName($PakPath)) 'initial.original.pak.wlmeta.json'
}

function Get-FileSha256([string]$Path) {
    return (Get-FileHash -LiteralPath $Path -Algorithm SHA256).Hash
}

function Assert-SnowRunnerClosed {
    $running = Get-Process -Name 'SnowRunner' -ErrorAction SilentlyContinue
    if ($running) {
        throw 'SnowRunner is currently running. Close SnowRunner completely before applying or restoring mods.'
    }
}


function Test-PakCompatibility([string]$Path) {
    # This is intentionally independent of the user's selected multipliers.
    # It verifies the SnowRunner structures this editor knows how to modify
    # before a backup is promoted or the live PAK is ever replaced.
    $stats = [ordered]@{ Xml=0; Engines=0; Gearboxes=0; Wheels=0; Suspensions=0; Winches=0; BaseTrucks=0 }
    $stream = [IO.File]::OpenRead($Path)
    try {
        $zip = New-Object IO.Compression.ZipArchive($stream, [IO.Compression.ZipArchiveMode]::Read)
        try {
            foreach ($entry in $zip.Entries) {
                $name = $entry.FullName.ToLowerInvariant()
                if (-not $name.EndsWith('.xml')) { continue }
                $stats.Xml++
                if ($name -match '(?:^|\\)classes\\engines\\[^\\]+\.xml$') { $stats.Engines++ }
                elseif ($name -match '(?:^|\\)classes\\gearboxes\\[^\\]+\.xml$') { $stats.Gearboxes++ }
                elseif ($name -match '(?:^|\\)classes\\wheels\\[^\\]+\.xml$') { $stats.Wheels++ }
                elseif ($name -match '(?:^|\\)classes\\suspensions\\[^\\]+\.xml$') { $stats.Suspensions++ }
                elseif ($name -match '(?:^|\\)classes\\winches\\[^\\]+\.xml$') { $stats.Winches++ }
                elseif ($name -match '(?:^|\\)classes\\trucks\\[^\\]+\.xml$') {
                    $reader = New-Object IO.StreamReader($entry.Open(), [Text.Encoding]::UTF8, $true)
                    try { $text = $reader.ReadToEnd() } finally { $reader.Dispose() }
                    if ($text -match '<Truck>') { $stats.BaseTrucks++ }
                }
            }
        } finally { $zip.Dispose() }
    } finally { $stream.Dispose() }

    # Broad lower bounds, not exact version numbers. Routine DLC/content updates
    # should sail through; a major archive/layout change should fail closed.
    $problems = New-Object Collections.Generic.List[string]
    if ($stats.Xml -lt 1000) { $problems.Add("only $($stats.Xml) XML files were found") }
    if ($stats.Engines -lt 10) { $problems.Add("engine definitions are missing/relocated ($($stats.Engines) found)") }
    if ($stats.Gearboxes -lt 5) { $problems.Add("gearbox definitions are missing/relocated ($($stats.Gearboxes) found)") }
    if ($stats.Wheels -lt 20) { $problems.Add("wheel definitions are missing/relocated ($($stats.Wheels) found)") }
    if ($stats.Suspensions -lt 20) { $problems.Add("suspension definitions are missing/relocated ($($stats.Suspensions) found)") }
    if ($stats.Winches -lt 5) { $problems.Add("winch definitions are missing/relocated ($($stats.Winches) found)") }
    if ($stats.BaseTrucks -lt 50) { $problems.Add("base truck definitions are missing/relocated ($($stats.BaseTrucks) found)") }
    if ($problems.Count -gt 0) {
        throw ("Compatibility preflight FAILED. This SnowRunner update may have changed initial.pak in a way this editor does not understand. NO MODIFICATIONS WERE MADE. Use Epic Games Verify if needed and wait for an editor update. Details: " + ($problems -join '; '))
    }
    return [pscustomobject]$stats
}

function Initialize-Backup([string]$Pak) {
    $script:UpdateDetected = $false
$script:TruckTargets = @{}
$script:wlDamageCapHits = 0
$script:wlDamageMultHits = 0
    $backup = Get-BackupPath $Pak
    $metaPath = Get-BackupMetaPath $Pak
    $currentHash = Get-FileSha256 $Pak

    # v1.0.0 backups have no metadata and may belong to an older SnowRunner update.
    # Never trust them automatically. Archive the legacy backup and establish the
    # current verified initial.pak as the new baseline.
    if ((Test-Path -LiteralPath $backup) -and -not (Test-Path -LiteralPath $metaPath)) {
        $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
        $legacy = Join-Path ([IO.Path]::GetDirectoryName($Pak)) ("initial.original.legacy-$stamp.pak")
        Move-Item -LiteralPath $backup -Destination $legacy -Force
    }

    if (-not (Test-Path -LiteralPath $backup)) {
        [IO.File]::Copy($Pak, $backup, $false)
        $meta = [ordered]@{ BackupHash = $currentHash; LastEditorOutputHash = $null; CreatedUtc = [DateTime]::UtcNow.ToString('o') }
        $meta | ConvertTo-Json | Set-Content -LiteralPath $metaPath -Encoding UTF8
        return $backup
    }

    Assert-Pak $backup
    $meta = Get-Content -LiteralPath $metaPath -Raw | ConvertFrom-Json
    $backupHash = Get-FileSha256 $backup
    if ($meta.BackupHash -ne $backupHash) {
        throw 'The editor backup no longer matches its safety record. Use Epic Games Verify, then delete initial.original.pak and its .wlmeta.json file before trying again.'
    }

    # If current PAK is neither our known clean backup nor our last editor output,
    # SnowRunner/Epic changed it. Promote that new official PAK to the baseline.
    if ($currentHash -ne $meta.BackupHash -and $currentHash -ne $meta.LastEditorOutputHash) {
        $stamp = Get-Date -Format 'yyyyMMdd-HHmmss'
        $archived = Join-Path ([IO.Path]::GetDirectoryName($Pak)) ("initial.original.preupdate-$stamp.pak")
        Move-Item -LiteralPath $backup -Destination $archived -Force
        [IO.File]::Copy($Pak, $backup, $false)
        $meta = [ordered]@{ BackupHash = $currentHash; LastEditorOutputHash = $null; CreatedUtc = [DateTime]::UtcNow.ToString('o') }
        $meta | ConvertTo-Json | Set-Content -LiteralPath $metaPath -Encoding UTF8
        $script:UpdateDetected = $true
    }
    return $backup
}

function Set-LastEditorOutputHash([string]$Pak) {
    $metaPath = Get-BackupMetaPath $Pak
    if (Test-Path -LiteralPath $metaPath) {
        $meta = Get-Content -LiteralPath $metaPath -Raw | ConvertFrom-Json
        $meta.LastEditorOutputHash = Get-FileSha256 $Pak
        $meta | ConvertTo-Json | Set-Content -LiteralPath $metaPath -Encoding UTF8
    }
}

function Assert-Pak([string]$Path, [bool]$RequireInitialName = $false) {
    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path -LiteralPath $Path -PathType Leaf)) {
        throw 'Choose a valid initial.pak file first.'
    }
    if ($RequireInitialName -and [IO.Path]::GetFileName($Path).ToLowerInvariant() -ne 'initial.pak') {
        throw 'The selected file must be named initial.pak.'
    }
    $stream = [IO.File]::OpenRead($Path)
    try {
        $zip = New-Object IO.Compression.ZipArchive($stream, [IO.Compression.ZipArchiveMode]::Read)
        try {
            if (-not ($zip.Entries | Where-Object { $_.FullName -eq 'pak.load_list' } | Select-Object -First 1)) {
                throw 'This does not appear to be a valid SnowRunner initial.pak.'
            }
        } finally { $zip.Dispose() }
    } finally { $stream.Dispose() }
}

function Get-TruckTargets([string]$PakPath) {
    Assert-Pak $PakPath $true
    $items = New-Object Collections.Generic.List[object]
    # TEST 7: A truck ID can appear in more than one classes\trucks path inside
    # initial.pak (base/DLC/reference copies).  The target selector is keyed by
    # canonical truck ID, so expose each ID exactly once instead of duplicating it.
    $seenTruckIds = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
    $stream = [IO.File]::OpenRead($PakPath)
    try {
        $zip = New-Object IO.Compression.ZipArchive($stream, [IO.Compression.ZipArchiveMode]::Read)
        try {
            $utf8 = New-Object Text.UTF8Encoding($false)
            foreach ($entry in $zip.Entries) {
                $name = $entry.FullName.ToLowerInvariant()
                if ($name -notmatch '(?:^|\\)classes\\trucks\\([^\\]+)\.xml$') { continue }
                $es = $entry.Open()
                try {
                    $reader = New-Object IO.StreamReader($es, $utf8, $true)
                    try { $text = $reader.ReadToEnd() } finally { $reader.Dispose() }
                } finally { $es.Dispose() }
                if ($text -notmatch '<Truck\b') { continue }
                $id = [IO.Path]::GetFileNameWithoutExtension($entry.FullName)
                if (-not $seenTruckIds.Add($id)) { continue }
                $friendly = [Globalization.CultureInfo]::InvariantCulture.TextInfo.ToTitleCase((($id -replace '[_-]+',' ').ToLowerInvariant()))

                # Personal category test: SnowRunner stores the vehicle class as TruckType.
                # Read it directly from each live truck XML so future DLC can sort itself.
                $category = 'OTHER'
                $m = [regex]::Match($text, '(?i)\bTruckType\s*=\s*"([^"]+)"')
                if ($m.Success) {
                    $raw = $m.Groups[1].Value.Trim().ToUpperInvariant().Replace('_','').Replace(' ','')
                    switch -Regex ($raw) {
                        '^SCOUT' { $category='SCOUT'; break }
                        '^HIGHWAY' { $category='HIGHWAY'; break }
                        '^HEAVYDUTY' { $category='HEAVY DUTY'; break }
                        '^OFFROAD' { $category='OFFROAD'; break }
                        '^HEAVY' { $category='HEAVY'; break }
                    }
                }
                $items.Add([pscustomobject]@{ Id=$id; Display=("$friendly  [$id]"); Category=$category })
            }
        } finally { $zip.Dispose() }
    } finally { $stream.Dispose() }
    return $items | Sort-Object Category,Display
}

function Refresh-TruckTargets {
    $previous = if ($cmbTruck.SelectedItem) { [string]$cmbTruck.SelectedItem } else { (L 'All Trucks') }
    $script:RefreshingTruckTargets = $true
    try {
        $cmbTruck.BeginUpdate()
        try {
            $cmbTruck.Items.Clear()
            $script:TruckTargets = @{}
            $script:CategoryTargets = @{}
            $script:CategoryHeadingLabels = @()
            $script:wlDamageCapHits = 0
            $script:wlDamageMultHits = 0
            [void]$cmbTruck.Items.Add((L 'All Trucks'))
            $pakPath = $txtPak.Text.Trim()
            $truckCount = 0
            if ($pakPath -and (Test-Path -LiteralPath $pakPath)) {
                $trucks = @(Get-TruckTargets $pakPath)
                $truckCount = $trucks.Count
                foreach ($cat in @('SCOUT','HIGHWAY','HEAVY DUTY','OFFROAD','HEAVY','OTHER')) {
                    $members = @($trucks | Where-Object { $_.Category -eq $cat } | Sort-Object Display)
                    if ($members.Count -eq 0) { continue }
                    $pretty = switch ($cat) { 'SCOUT' {'Scouts'} 'HIGHWAY' {'Highway'} 'HEAVY DUTY' {'Heavy Duty'} 'OFFROAD' {'Offroad'} 'HEAVY' {'Heavy'} default {'Other'} }
                    $heading = "──────── $pretty ($($members.Count)) ────────"
                    [void]$cmbTruck.Items.Add($heading)
                    $script:CategoryHeadingLabels += $heading
                    $allLabel = "★ All $pretty"
                    [void]$cmbTruck.Items.Add($allLabel)
                    $script:CategoryTargets[$allLabel] = @($members | ForEach-Object { $_.Id })
                    foreach ($truck in $members) {
                        $label = "    " + $truck.Display
                        $script:TruckTargets[$label] = $truck.Id
                        [void]$cmbTruck.Items.Add($label)
                    }
                }
            }
            $idx = $cmbTruck.Items.IndexOf($previous)
            if ($idx -lt 0) { $idx = 0 }
            $cmbTruck.SelectedIndex = $idx
            $lblTruckCount.Text = if ($truckCount -gt 0) { [string]$truckCount } else { '' }
        }
        finally { $cmbTruck.EndUpdate() }
    }
    finally { $script:RefreshingTruckTargets = $false }
    Set-TruckModeUi
}

function Copy-WLSettings($S) {
    $c=[ordered]@{}
    foreach($k in $S.Keys){
        $v=$S[$k]
        if($v -is [Array]){$c[$k]=@($v)} else {$c[$k]=$v}
    }
    return $c
}

function Invoke-CategoryBatch($BaseSettings,[bool]$WriteOutput) {
    $ids=@($BaseSettings.TargetTruckIds)
    if($ids.Count -eq 0){throw 'Category safety stop: this category contains no resolved truck IDs.'}

    # PERSONAL TEST CATEGORY SPEED 4 - TRUE SINGLE-PASS CATEGORY ENGINE
    # Build one union plan for the entire selected category from the pristine WL backup,
    # then traverse/write initial.pak ONCE.  This replaces the old one-Process-Pak-per-truck
    # loop that made All Scouts take ~1:34 even after surgical ZIP writes.
    #
    # The live/current initial.pak is still used as the OUTPUT base so edits to trucks outside
    # this category are preserved.  Requested category resources are calculated from the clean
    # backup, making a repeated identical category Apply non-stacking/idempotent.
    Assert-Pak $BaseSettings.PakPath $true
    $pak=[IO.Path]::GetFullPath([string]$BaseSettings.PakPath)
    $backup=Initialize-Backup $pak
    Assert-Pak $backup

    # PERSONAL TEST CATEGORY SPEED 10 - planner archive cache.
    # Keep the pristine backup ZIP open once while resolving the entire category instead of
    # reopening initial.pak for every truck/component helper.  Helpers below reuse this handle
    # only when the requested PAK path exactly matches this category backup.
    $script:WLCategoryPlannerPakPath=[IO.Path]::GetFullPath([string]$backup)
    $script:WLCategoryPlannerStream=[IO.File]::OpenRead($backup)
    $script:WLCategoryPlannerZip=New-Object IO.Compression.ZipArchive($script:WLCategoryPlannerStream,[IO.Compression.ZipArchiveMode]::Read)

    $s=Copy-WLSettings $BaseSettings
    $s.IsCategoryTarget=$false
    $s.CategoryBatchMode=$true
    $s.CategorySinglePassMode=$true
    $s.TargetTruckId='__WL_CATEGORY_BATCH__'
    $s.TargetTruckEntry=''
    $s.TargetTruckEntries=@()
    $s.TargetTruckIds=@($ids)

    $truckEntries=New-Object Collections.Generic.List[string]
    $engineByEntry=@{}
    $gearEntries=@{}
    $wheelEntries=@{}
    $winchEntries=@{}
    $suspByEntry=@{}
    $serviceEntries=@{}
    $craneEntries=@{}
    $skipCounts=@{}

    $engineChange = ([math]::Abs([double]$s.EngineTorque-1.0) -ge 0.0000001) -or ([math]::Abs([double]$s.EngineResponse-1.0) -ge 0.0000001) -or ([math]::Abs([double]$s.EngineFuel-1.0) -ge 0.0000001) -or ([math]::Abs([double]$s.EngineDurability-1.0) -ge 0.0000001)
    $gearboxChange = ([math]::Abs([double]$s.GearSpeed-1.0)-ge 0.0000001) -or ([math]::Abs([double]$s.GearboxFuel-1.0)-ge 0.0000001) -or ([math]::Abs([double]$s.AwdFuel-1.0)-ge 0.0000001) -or ([math]::Abs([double]$s.IdleFuel-1.0)-ge 0.0000001) -or ([math]::Abs([double]$s.GearboxDurability-1.0)-ge 0.0000001)
    $tireChange = ([math]::Abs([double]$s.TireAsphalt-1.0) -ge 0.0000001) -or ([math]::Abs([double]$s.TireOffroad-1.0) -ge 0.0000001) -or ([math]::Abs([double]$s.TireMud-1.0) -ge 0.0000001) -or ([math]::Abs([double]$s.TireDurability-1.0) -ge 0.0000001) -or [bool]$s.AllTiresIgnoreIce
    $suspChange = ([math]::Abs([double]$s.SuspensionStrength-1.0) -ge 0.0000001) -or ([math]::Abs([double]$s.SuspensionHeight-1.0) -ge 0.0000001) -or ([math]::Abs([double]$s.SuspensionDamping-1.0) -ge 0.0000001) -or ([math]::Abs([double]$s.SuspensionDurability-1.0) -ge 0.0000001)
    $winchChange = ([math]::Abs([double]$s.WinchStrength-1.0) -ge 0.0000001) -or ([math]::Abs([double]$s.WinchLength-1.0) -ge 0.0000001) -or [bool]$s.AutonomousWinches
    $serviceChange = ([math]::Abs([double]$s.ServiceFuel-1.0) -ge 0.0000001) -or ([math]::Abs([double]$s.ServiceWater-1.0) -ge 0.0000001) -or ([math]::Abs([double]$s.ServiceRepairs-1.0) -ge 0.0000001) -or ([math]::Abs([double]$s.ServiceWheels-1.0) -ge 0.0000001)
    $craneChange = ([math]::Abs([double]$s.CraneStrength-1.0) -ge 0.0000001) -or ([math]::Abs([double]$s.CraneSpeed-1.0) -ge 0.0000001)

    # SPEED 10: exact XML filename index for official truck resolution. Building this once
    # avoids 28 repeated full-archive scans in All Scouts and proportionally more in larger classes.
    $truckLeafIndex=@{}
    foreach($pe in $script:WLCategoryPlannerZip.Entries){
        if(-not $pe.FullName.EndsWith('.xml',[StringComparison]::OrdinalIgnoreCase)){continue}
        $leaf=$pe.Name.ToLowerInvariant()
        if(-not $truckLeafIndex.ContainsKey($leaf)){$truckLeafIndex[$leaf]=New-Object Collections.Generic.List[object]}
        [void]$truckLeafIndex[$leaf].Add($pe)
    }

    $clock=[Diagnostics.Stopwatch]::StartNew()
    $n=0
    foreach($id in $ids){
        $n++
        $lblStatus.Text=("Planning category {0}/{1}: {2}   |   elapsed {3:mm\:ss}" -f $n,$ids.Count,$id,$clock.Elapsed)
        [Windows.Forms.Application]::DoEvents()
        $wantedLeaf=(([string]$id).ToLowerInvariant()+'.xml')
        $candidates=if($truckLeafIndex.ContainsKey($wantedLeaf)){[object[]]$truckLeafIndex[$wantedLeaf].ToArray()}else{[object[]]@()}
        $verified=New-Object Collections.Generic.List[object]
        foreach($cand in $candidates){
            $cr=New-Object IO.StreamReader($cand.Open(),[Text.Encoding]::UTF8,$true)
            try{$ctx=$cr.ReadToEnd()}finally{$cr.Dispose()}
            if($ctx -match '(?is)<Truck(?:\s|>)'){[void]$verified.Add($cand)}
        }
        if($verified.Count -ne 1){throw "SPEED 10 category safety stop: truck ID '$id' resolved to $($verified.Count) verified Truck XML entries; expected exactly 1."}
        $entry=[string]$verified[0].FullName
        if(-not $truckEntries.Contains([string]$entry)){$truckEntries.Add([string]$entry)}

        if($engineChange){
            try{
                $ep=Get-IndividualEnginePlan $backup ([string]$entry) ([string]$id)
                for($i=0;$i -lt @($ep.SourceEntries).Count;$i++){
                    $ee=[string]$ep.SourceEntries[$i]
                    if($ee -and -not $engineByEntry.ContainsKey($ee.ToLowerInvariant())){
                        $et=if($i -lt @($ep.Types).Count){[string]$ep.Types[$i]}else{[IO.Path]::GetFileNameWithoutExtension($ee)}
                        $engineByEntry[$ee.ToLowerInvariant()]=[pscustomobject]@{Entry=$ee;Type=$et}
                    }
                }
            }catch{ $skipCounts['Engine plan skips']=1+[int]$(if($skipCounts.ContainsKey('Engine plan skips')){$skipCounts['Engine plan skips']}else{0}) }
        }
        if($gearboxChange){
            try{
                $gp=Get-IndividualGearboxPlan $backup ([string]$entry) ([string]$id)
                foreach($ge in @($gp.SourceEntries)){if($ge){$gearEntries[([string]$ge).ToLowerInvariant()]=[string]$ge}}
            }catch{ $skipCounts['Gearbox plan skips']=1+[int]$(if($skipCounts.ContainsKey('Gearbox plan skips')){$skipCounts['Gearbox plan skips']}else{0}) }
        }
        if($tireChange){
            try{
                $tp=Get-IndividualTirePlan $backup ([string]$entry) ([string]$id)
                if($tp -and -not [bool]$tp.Inherited){
                    foreach($we in @($tp.SourceEntries)){if($we){$wheelEntries[([string]$we).ToLowerInvariant()]=[string]$we}}
                }
            }catch{ $skipCounts['Tire plan skips']=1+[int]$(if($skipCounts.ContainsKey('Tire plan skips')){$skipCounts['Tire plan skips']}else{0}) }
        }
        if($suspChange){
            try{
                $sp=Get-IndividualSuspensionPlan $backup ([string]$entry) ([string]$id)
                foreach($f in @($sp.Families)){if($f -and $f.SourceEntry){$suspByEntry[([string]$f.SourceEntry).ToLowerInvariant()]=$f}}
            }catch{ $skipCounts['Suspension plan skips']=1+[int]$(if($skipCounts.ContainsKey('Suspension plan skips')){$skipCounts['Suspension plan skips']}else{0}) }
        }
        if($winchChange){
            try{
                $wp=Get-IndividualWinchPlan $backup ([string]$entry) ([string]$id)
                if($wp -and -not [bool]$wp.Inherited -and $wp.SourceEntry){$winchEntries[([string]$wp.SourceEntry).ToLowerInvariant()]=[string]$wp.SourceEntry}
            }catch{ $skipCounts['Winch plan skips']=1+[int]$(if($skipCounts.ContainsKey('Winch plan skips')){$skipCounts['Winch plan skips']}else{0}) }
        }
        # SPEED 10: service/crane addon discovery is intentionally deferred. Both old helpers
        # scanned every truck/addon XML once PER selected truck.  We now union the category's
        # socket vocabulary and scan the addon XMLs once for the whole category below.
    }

    $s.TargetTruckEntries=$truckEntries.ToArray()
    $engRows=@($engineByEntry.Values)
    $s.IndividualEngineSourceEntries=@($engRows | ForEach-Object {$_.Entry})
    $s.IndividualEngineTypes=@($engRows | ForEach-Object {$_.Type})
    $s.IndividualEngineSourceEntry=if($s.IndividualEngineSourceEntries.Count){[string]$s.IndividualEngineSourceEntries[0]}else{''}
    $s.IndividualEngineType=if($s.IndividualEngineTypes.Count){[string]$s.IndividualEngineTypes[0]}else{''}
    $s.IndividualGearboxSourceEntries=@($gearEntries.Values)
    $s.SharedWheelSourceEntries=@($wheelEntries.Values)
    $s.SharedWheelSourceEntry=if($s.SharedWheelSourceEntries.Count){[string]$s.SharedWheelSourceEntries[0]}else{''}
    $s.SharedWinchSourceEntries=@($winchEntries.Values)
    $s.SharedWinchSourceEntry=if($s.SharedWinchSourceEntries.Count){[string]$s.SharedWinchSourceEntries[0]}else{''}
    $s.CompatibleSuspensionFamilies=[object[]]@($suspByEntry.Values)
    $s.IndividualServiceAddonEntries=@($serviceEntries.Values)
    $s.IndividualCraneAddonEntries=@($craneEntries.Values)

    # PERSONAL TEST CATEGORY SPEED 5: category-scoped economy/unlock support.
    # Build a SAFE whitelist of upgrade XMLs belonging to this category.  It includes the
    # component families already resolved for the selected trucks plus truck-specific addon
    # XMLs stored beneath classes/trucks/<truck-id>/.  Shared/global trailer definitions are
    # deliberately excluded, so Addon/Trailer COG remains disabled for category targets.
    $categoryUpgrade=@{}
    foreach($ue in @($s.IndividualEngineSourceEntries)+@($s.IndividualGearboxSourceEntries)+@($s.SharedWheelSourceEntries)+@($s.SharedWinchSourceEntries)+@($s.IndividualServiceAddonEntries)+@($s.IndividualCraneAddonEntries)){
        if($ue){$categoryUpgrade[([string]$ue).Replace('\','/').ToLowerInvariant()]=[string]$ue}
    }
    foreach($sf in @($s.CompatibleSuspensionFamilies)){if($sf -and $sf.SourceEntry){$categoryUpgrade[([string]$sf.SourceEntry).Replace('\','/').ToLowerInvariant()]=[string]$sf.SourceEntry}}
    $idSet=@{}; foreach($cid in $ids){$idSet[([string]$cid).ToLowerInvariant()]=$true}
    $cf=[IO.File]::OpenRead($backup); $cz=New-Object IO.Compression.ZipArchive($cf,[IO.Compression.ZipArchiveMode]::Read)
    $explorationFound=0
    try{
        # PERSONAL TEST CATEGORY SPEED 7: collect the selected category's addon-socket vocabulary.
        # Exploration upgrades are not consistently stored directly under classes/trucks/<truck-id>/;
        # many live in *_tuning folders. SPEED 5 therefore missed valid AWD/Diff Lock exploration XMLs.
        $categorySockets=New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
        foreach($teName in @($s.TargetTruckEntries)){
            $te=$cz.Entries | Where-Object { $_.FullName.Replace('/','\').Equals(([string]$teName).Replace('/','\'),[StringComparison]::OrdinalIgnoreCase) } | Select-Object -First 1
            if(-not $te){continue}
            $tr=New-Object IO.StreamReader($te.Open(),[Text.Encoding]::UTF8,$true)
            try{$tx=$tr.ReadToEnd()}finally{$tr.Dispose()}
            foreach($sm in [regex]::Matches($tx,'(?i)\bNames(?:Block|Shift)?="([^"]+)"')){
                foreach($sv in ($sm.Groups[1].Value -split '[,;\s]+')){if($sv.Trim()){[void]$categorySockets.Add($sv.Trim())}}
            }
        }

        foreach($ce in $cz.Entries){
            if(-not $ce.FullName.EndsWith('.xml',[StringComparison]::OrdinalIgnoreCase)){continue}
            $cn=$ce.FullName.Replace('\','/').ToLowerInvariant()
            if($cn -match '(^|/)classes/trucks/([^/]+)/[^/]+\.xml$'){
                $folder=[string]$Matches[2]
                if($idSet.ContainsKey($folder)){$categoryUpgrade[$cn]=[string]$ce.FullName}
            }
            if($cn -notmatch '(^|/)classes/(?:engines|gearboxes|suspensions|wheels|winches|trucks)/'){continue}
            $er=New-Object IO.StreamReader($ce.Open(),[Text.Encoding]::UTF8,$true)
            try{$ex=$er.ReadToEnd()}finally{$er.Dispose()}

            # SPEED 10: one category-wide relationship scan replaces the old per-truck service
            # and crane scans. An addon belongs to the category when any InstallSocket Type
            # intersects the union of socket identifiers exposed by the selected trucks.
            $socketMatch=$false
            if($categorySockets.Count -gt 0){
                foreach($im0 in [regex]::Matches($ex,'(?is)<InstallSocket\b[^>]*\bType\s*=\s*"([^"]+)"[^>]*/?>')){
                    foreach($tv00 in ($im0.Groups[1].Value -split '[,;\s]+')){
                        $tv0=$tv00.Trim(); if($tv0 -and $categorySockets.Contains($tv0)){$socketMatch=$true;break}
                    }
                    if($socketMatch){break}
                }
            }
            if($socketMatch -and $serviceChange -and $ex -match '(?i)\b(?:FuelCapacity|WaterCapacity|RepairsCapacity|WheelRepairsCapacity)\s*='){
                $serviceEntries[$cn]=[string]$ce.FullName
                $categoryUpgrade[$cn]=[string]$ce.FullName
            }
            if($socketMatch -and $craneChange -and $ex -match '(?is)<AddonType\b[^>]*\bName\s*=\s*"(?:Crane|LogCrane)"[^>]*/?>'){
                $craneEntries[$cn]=[string]$ce.FullName
                $categoryUpgrade[$cn]=[string]$ce.FullName
            }

            if($ex -notmatch '(?i)\bUnlockByExploration="true"'){continue}

            $belongs=$false
            # Truck-specific naming catches e.g. ford_f750_tuning/ford_f750_transferbox_allwheels.xml.
            foreach($cid in $ids){
                $tid=([string]$cid).ToLowerInvariant()
                if($cn -match ('(?i)(^|[/_])'+[regex]::Escape($tid)+'(?:[/_\.]|$)')){$belongs=$true;break}
            }
            # Generic/shared addon names are accepted only when InstallSocket matches a socket
            # actually exposed by a truck in the selected category.
            if(-not $belongs -and $categorySockets.Count -gt 0){
                foreach($im in [regex]::Matches($ex,'(?is)<InstallSocket\b[^>]*\bType\s*=\s*"([^"]+)"[^>]*/?>')){
                    foreach($tv0 in ($im.Groups[1].Value -split '[,;\s]+')){
                        $tv=$tv0.Trim(); if($tv -and $categorySockets.Contains($tv)){$belongs=$true;break}
                    }
                    if($belongs){break}
                }
            }
            if($belongs){
                if(-not $categoryUpgrade.ContainsKey($cn)){$explorationFound++}
                $categoryUpgrade[$cn]=[string]$ce.FullName
            }
        }
    }finally{if($cz){$cz.Dispose()};if($cf){$cf.Dispose()}}
    # SPEED 10: finalize deferred category-wide service/crane discovery.
    $s.IndividualServiceAddonEntries=@($serviceEntries.Values)
    $s.IndividualCraneAddonEntries=@($craneEntries.Values)
    $s.CategoryUpgradeEntries=@($categoryUpgrade.Values)
    # SPEED 7: actual exploration-gated upgrade/addon XMLs are now whitelisted. Base truck XMLs
    # remain unlock-only as a fallback; Upgrade/addon Price can never alter truck purchase Price.
    $s.CategoryDiscoveryEntries=@($s.TargetTruckEntries)
    $s.CategoryExplorationUpgradeCount=$explorationFound
    $s.SharedEngineTruckUsers=0;$s.SharedGearboxTruckUsers=0;$s.SharedWheelTruckUsers=0;$s.SharedSuspensionTruckUsers=0;$s.SharedWinchTruckUsers=0

    # If an entire category had no resolvable local family for a requested feature, disable only
    # that feature for the write pass instead of falling through into broad/global matching.
    if($engineChange -and $s.IndividualEngineSourceEntries.Count -eq 0){$s.EngineTorque=1.0;$s.EngineResponse=1.0;$s.EngineFuel=1.0;$s.EngineDurability=1.0}
    if($gearboxChange -and $s.IndividualGearboxSourceEntries.Count -eq 0){$s.GearSpeed=1.0;$s.GearboxFuel=1.0;$s.AwdFuel=1.0;$s.IdleFuel=1.0;$s.GearboxDurability=1.0}
    if($tireChange -and $s.SharedWheelSourceEntries.Count -eq 0){$s.TireAsphalt=1.0;$s.TireOffroad=1.0;$s.TireMud=1.0;$s.TireDurability=1.0;$s.AllTiresIgnoreIce=$false}
    if($suspChange -and $s.CompatibleSuspensionFamilies.Count -eq 0){$s.SuspensionStrength=1.0;$s.SuspensionHeight=1.0;$s.SuspensionDamping=1.0;$s.SuspensionDurability=1.0}
    if($winchChange -and $s.SharedWinchSourceEntries.Count -eq 0){$s.WinchStrength=1.0;$s.WinchLength=1.0;$s.AutonomousWinches=$false}
    if($serviceChange -and $s.IndividualServiceAddonEntries.Count -eq 0){$s.ServiceFuel=1.0;$s.ServiceWater=1.0;$s.ServiceRepairs=1.0;$s.ServiceWheels=1.0}
    if($craneChange -and $s.IndividualCraneAddonEntries.Count -eq 0){$s.CraneStrength=1.0;$s.CraneSpeed=1.0}

    # Release the shared planner archive before Process-Pak opens the backup/current PAK for
    # the actual single write/preview pass. Clear script state so individual-truck operations
    # can never accidentally reuse a stale ZIP handle.
    if($script:WLCategoryPlannerZip){$script:WLCategoryPlannerZip.Dispose();$script:WLCategoryPlannerZip=$null}
    if($script:WLCategoryPlannerStream){$script:WLCategoryPlannerStream.Dispose();$script:WLCategoryPlannerStream=$null}
    $script:WLCategoryPlannerPakPath=''

    $lblStatus.Text=("Writing {0} as one category batch...   |   planned in {1:mm\:ss}" -f [string]$BaseSettings.TargetTruck,$clock.Elapsed)
    [Windows.Forms.Application]::DoEvents()
    $r=Process-Pak $s $WriteOutput
    $clock.Stop()
    foreach($k in $skipCounts.Keys){if(-not $r.Counts.ContainsKey($k)){$r.Counts[$k]=0};$r.Counts[$k]+=[int]$skipCounts[$k]}
    $r.Counts['Category trucks planned']=$ids.Count
    $r.Counts['Unique engine families']=$s.IndividualEngineSourceEntries.Count
    $r.Counts['Unique gearbox families']=$s.IndividualGearboxSourceEntries.Count
    $r.Counts['Unique wheel families']=$s.SharedWheelSourceEntries.Count
    $r.Counts['Unique suspension families']=$s.CompatibleSuspensionFamilies.Count
    $r.Counts['Unique winch families']=$s.SharedWinchSourceEntries.Count
    $r.Counts['Unique service addon XMLs']=$s.IndividualServiceAddonEntries.Count
    $r.Counts['Unique crane addon XMLs']=$s.IndividualCraneAddonEntries.Count
    $r.Counts['Category-scoped upgrade/addon XMLs']=$s.CategoryUpgradeEntries.Count
    $r.Counts['Category base-truck discovery XMLs']=$s.CategoryDiscoveryEntries.Count
    $r.Counts['Exploration-locked upgrade XMLs discovered']=$s.CategoryExplorationUpgradeCount
    $r.Counts['Category batch elapsed seconds']=[int][math]::Round($clock.Elapsed.TotalSeconds)
    $r.TargetTruck=([string]$BaseSettings.TargetTruck+' ('+$ids.Count+' trucks)')
    return $r
}


function Get-ModPackageDisplayName([string]$PakPath) {
    # DEV20: Prefer the human-readable Mod.io package name from the subscription
    # metadata beside the PAK. This is the name the player is most likely to
    # recognize from SnowRunner's Mod Browser. Internal truck ID remains visible
    # in brackets so multi-truck/variant packages stay unambiguous.
    try {
        $dir=[IO.Path]::GetDirectoryName($PakPath)
        $jsonPath=Join-Path $dir 'modio.json'
        if(Test-Path -LiteralPath $jsonPath -PathType Leaf){
            # RC2: mod.io metadata is UTF-8. Windows PowerShell 5.1 Get-Content can
            # decode BOM-less UTF-8 using the active ANSI code page, producing mojibake
            # such as "â€“". Read it explicitly as UTF-8 while still honoring a BOM.
            $sr=New-Object IO.StreamReader($jsonPath,[Text.Encoding]::UTF8,$true)
            try{$raw=$sr.ReadToEnd()}finally{$sr.Dispose()}
            $j=$raw | ConvertFrom-Json -ErrorAction Stop
            $candidates=New-Object Collections.Generic.List[string]
            foreach($prop in @('name','title','display_name','mod_name')){
                if($j.PSObject.Properties.Name -contains $prop){
                    $v=[string]$j.$prop
                    if(-not [string]::IsNullOrWhiteSpace($v)){[void]$candidates.Add($v.Trim())}
                }
            }
            if($j.PSObject.Properties.Name -contains 'mod' -and $null -ne $j.mod){
                foreach($prop in @('name','title','display_name')){
                    if($j.mod.PSObject.Properties.Name -contains $prop){
                        $v=[string]$j.mod.$prop
                        if(-not [string]::IsNullOrWhiteSpace($v)){[void]$candidates.Add($v.Trim())}
                    }
                }
            }
            if($candidates.Count -gt 0){ return [string]$candidates[0] }
        }
    } catch { }
    return ''
}

function Find-InstalledModTruckSources {
    # DEV20: scan only actual third-party truck PAKs. Never expose an initial.pak
    # found under the Mod.io subscription tree as an editable mod target: those
    # archives can contain copied/stock game definitions and previously inflated
    # the dropdown by dozens of bogus "mods".
    $docs = [Environment]::GetFolderPath('MyDocuments')
    $modRoot = Join-Path $docs 'My Games\SnowRunner\base\Mods\.modio\mods'
    $results = New-Object Collections.Generic.List[object]
    $archives = New-Object Collections.Generic.List[object]
    $seen = @{}

    if (-not (Test-Path -LiteralPath $modRoot -PathType Container)) {
        return [pscustomobject]@{ Root=$modRoot; Trucks=[object[]]@(); Archives=[object[]]@() }
    }

    $utf8 = New-Object Text.UTF8Encoding($false)
    foreach ($f in (Get-ChildItem -LiteralPath $modRoot -Recurse -File -Filter '*.pak' | Where-Object {
        $n=$_.Name.ToLowerInvariant()
        ($n -ne 'initial.pak') -and
        ($n -ne 'mod.pak') -and
        ($n -notlike '*.wl-original.pak') -and
        ($n -notlike '*.wl-original.pak.preupdate-*') -and
        ($n -notlike '*.wl-original.pak.*')
    } -ErrorAction SilentlyContinue)) {
        try {
            $packageName=Get-ModPackageDisplayName $f.FullName
            $fs = [IO.File]::OpenRead($f.FullName)
            try {
                $z = New-Object IO.Compression.ZipArchive($fs, [IO.Compression.ZipArchiveMode]::Read)
                try {
                    $truckCount=0
                    foreach ($e in $z.Entries) {
                        $entryName = ($e.FullName -replace '\\','/').ToLowerInvariant()
                        if ($entryName -notmatch '(^|/)classes/trucks/([^/]+)\.xml$') { continue }
                        $es=$e.Open()
                        try {
                            $reader=New-Object IO.StreamReader($es,$utf8,$true)
                            try { $text=$reader.ReadToEnd() } finally { $reader.Dispose() }
                        } finally { $es.Dispose() }
                        if ($text -notmatch '<Truck\b') { continue }

                        $id=[IO.Path]::GetFileNameWithoutExtension($e.FullName)
                        $key=($id + '|' + $f.FullName).ToLowerInvariant()
                        if ($seen[$key]) { continue }; $seen[$key]=$true
                        $fallback=[Globalization.CultureInfo]::InvariantCulture.TextInfo.ToTitleCase((($id -replace '[_-]+',' ').ToLowerInvariant()))
                        $friendly=if(-not [string]::IsNullOrWhiteSpace($packageName)){$packageName}else{$fallback}
                        $display="[MOD] $friendly  [$id]"
                        $results.Add([pscustomobject]@{ Id=$id; Display=$display; Friendly=$friendly; Source=$f.FullName; Entry=$e.FullName; Kind='mod.io PAK' })
                        $truckCount++
                    }
                    if ($truckCount -gt 0) { $archives.Add([pscustomobject]@{Path=$f.FullName; Trucks=$truckCount; Name=$packageName}) }
                } finally { $z.Dispose() }
            } finally { $fs.Dispose() }
        } catch { }
    }
    [object[]]$truckArray=@($results.ToArray() | Sort-Object Display)
    [object[]]$archiveArray=$archives.ToArray()
    return [pscustomobject]@{ Root=$modRoot; Trucks=$truckArray; Archives=$archiveArray }
}

function Refresh-ModTruckTargets {
    $scan=Find-InstalledModTruckSources
    # Remove only entries previously inserted by Scan Mods.
    for ($i=$cmbTruck.Items.Count-1; $i -ge 0; $i--) {
        if ([string]$cmbTruck.Items[$i] -like '[[]MOD[]]*') { $cmbTruck.Items.RemoveAt($i) }
    }
    if (-not $script:ModTruckTargets) { $script:ModTruckTargets=@{} } else { $script:ModTruckTargets.Clear() }

    # DEV3: de-duplicate exact discoveries. A truck is identical only when
    # source PAK + XML entry + internal truck ID are all the same.
    $seen=@{}
    $unique=New-Object Collections.Generic.List[object]
    foreach ($truck in $scan.Trucks) {
        $source=[IO.Path]::GetFullPath([string]$truck.Source).ToLowerInvariant()
        $entry=([string]$truck.Entry).Replace('\','/').ToLowerInvariant()
        $id=([string]$truck.Id).ToLowerInvariant()
        $identity=$source+'|'+$entry+'|'+$id
        if($seen.ContainsKey($identity)){ continue }
        $seen[$identity]=$true
        [void]$unique.Add($truck)
    }

    # Count IDs after exact de-duplication so genuinely different sources
    # with the same internal ID can be shown distinctly.
    $idCounts=@{}
    foreach($truck in $unique){
        $id=([string]$truck.Id).ToLowerInvariant()
        if(-not $idCounts.ContainsKey($id)){$idCounts[$id]=0}
        $idCounts[$id]=[int]$idCounts[$id]+1
    }

    foreach ($truck in $unique) {
        $id=([string]$truck.Id).ToLowerInvariant()
        $label=[string]$truck.Display
        if($idCounts[$id] -gt 1){
            $pakName=[IO.Path]::GetFileName([string]$truck.Source)
            $label="$label <$pakName>"
        }
        $base=$label; $n=2
        while($script:ModTruckTargets.ContainsKey($label)){ $label="$base #$n"; $n++ }
        $script:ModTruckTargets[$label]=$truck
        [void]$cmbTruck.Items.Add($label)
    }

    # DEV29: one-click compatibility sweep target. This is PREVIEW ONLY and is not mapped
    # as a normal mod truck, so it can never enter the single-PAK Apply pipeline.
    if ($unique.Count -gt 0) { [void]$cmbTruck.Items.Add($script:AllModsPreviewLabel) }

    # Return the de-duplicated list so diagnostics report what the UI actually contains.
    $scan.Trucks=[object[]]$unique.ToArray()
    return $scan
}

function Show-ModScanDiagnostic {
    # RC2: Scan Mods is an in-app discovery action. Do not leave a diagnostic TXT
    # on the user's Desktop during normal use.
    $scan=Refresh-ModTruckTargets
    [Windows.Forms.MessageBox]::Show(("Mod truck scan complete.`r`n`r`nFound " + $scan.Trucks.Count + " editable third-party truck definition(s) in " + $scan.Archives.Count + " mod PAK(s).`r`n`r`nFriendly Mod.io names are shown first; internal truck IDs remain in brackets for exact targeting.`r`n`r`nThey were added to the Truck target dropdown as editable [MOD] targets."),$script:AppName,'OK','Information') | Out-Null
    return $scan.Trucks.Count
}

function Resolve-OfficialTruckEntryPath([string]$PakPath, [string]$TruckId) {
    if ([string]::IsNullOrWhiteSpace($TruckId)) { return '' }

    $report = Join-Path ([Environment]::GetFolderPath('Desktop')) 'WL-SnowRunner-TEST6.3-TruckResolver.txt'
    $lines = New-Object Collections.Generic.List[string]
    $lines.Add('WL Simplistic SnowRunner Mod Editor v1.1.0 TEST 6.10 - TRUCK RESOLVER')
    $lines.Add(('Generated: ' + (Get-Date).ToString('yyyy-MM-dd HH:mm:ss')))
    $lines.Add('NO FILES WERE MODIFIED BY THIS DIAGNOSTIC.')
    $lines.Add('')
    $lines.Add(('Selected Truck ID: ' + $TruckId))
    $lines.Add(('Baseline PAK: ' + $PakPath))
    $lines.Add('')

    $idLower = $TruckId.ToLowerInvariant()
    $fileName = $idLower + '.xml'
    $candidates = New-Object Collections.Generic.List[object]
    $fs = $null; $zip = $null
    try {
        $fs = [IO.File]::OpenRead($PakPath)
        $zip = New-Object IO.Compression.ZipArchive($fs, [IO.Compression.ZipArchiveMode]::Read)
        $lines.Add(('Archive entries: ' + $zip.Entries.Count))
        foreach ($entry in $zip.Entries) {
            if (-not $entry.FullName.EndsWith('.xml', [StringComparison]::OrdinalIgnoreCase)) { continue }
            $norm = $entry.FullName.Replace('\','/').TrimStart('/').ToLowerInvariant()
            $leaf = [IO.Path]::GetFileName($norm)
            $pathHit = ($leaf -eq $fileName) -or ($norm -like ('*' + $idLower + '*'))
            if (-not $pathHit) { continue }

            $isTruck = $false
            $readError = ''
            try {
                $stream = $entry.Open()
                try {
                    $reader = New-Object IO.StreamReader($stream, [Text.Encoding]::UTF8, $true)
                    try { $text = $reader.ReadToEnd() } finally { $reader.Dispose() }
                } finally { $stream.Dispose() }
                $isTruck = ($text -match '(?is)<Truck(?:\s|>)')
            } catch { $readError = $_.Exception.Message }

            $candidates.Add([pscustomobject]@{ Entry=$entry.FullName; Leaf=$leaf; IsTruck=$isTruck; Error=$readError })
        }
    } finally {
        if ($null -ne $zip) { $zip.Dispose() }
        if ($null -ne $fs) { $fs.Dispose() }
    }

    $lines.Add(('Candidate entries containing ID / matching filename: ' + $candidates.Count))
    foreach ($c in $candidates) {
        $lines.Add(('  Entry: ' + $c.Entry))
        $lines.Add(('    Filename: ' + $c.Leaf))
        $lines.Add(('    Contains <Truck>: ' + $c.IsTruck))
        if ($c.Error) { $lines.Add(('    Read error: ' + $c.Error)) }
    }

    # Resolve by exact XML filename + verified <Truck>, regardless of archive folder layout.
    $verified = @($candidates | Where-Object { $_.Leaf -eq $fileName -and $_.IsTruck })
    $lines.Add('')
    $lines.Add(('Verified exact-filename Truck matches: ' + $verified.Count))
    foreach ($v in $verified) { $lines.Add(('  ' + $v.Entry)) }

    if ($verified.Count -eq 1) {
        $lines.Add(('RESOLVED: ' + $verified[0].Entry))
        return [string]$verified[0].Entry
    }

    $lines.Add('RESOLUTION FAILED.')
    if ($verified.Count -eq 0) {
        throw ("TEST 6.9 safety stop: no verified exact XML filename match was found for truck ID '" + $TruckId + "'. No modifications were made.`r`n`r`nResolver report:`r`n" + $report)
    }
    throw ("TEST 6.9 safety stop: truck ID '" + $TruckId + "' matched " + $verified.Count + " verified Truck XML entries. Refusing an ambiguous edit.`r`n`r`nResolver report:`r`n" + $report)
}


function Write-SelectedTruckComponentDiagnostic([string]$PakPath, [string]$TruckEntry, [string]$TruckId) {
    if ([string]::IsNullOrWhiteSpace($TruckEntry)) { return }
    $desktop = [Environment]::GetFolderPath('Desktop')
    $report = Join-Path $desktop 'WL-SnowRunner-TEST6.6-ComponentMap.txt'
    $xmlOut = Join-Path $desktop 'WL-SnowRunner-TEST6.6-SelectedTruck.xml'
    $fs=$null; $zip=$null
    try {
        $fs=[IO.File]::OpenRead($PakPath)
        $zip=New-Object IO.Compression.ZipArchive($fs,[IO.Compression.ZipArchiveMode]::Read)
        $targetNorm=$TruckEntry.Replace('/','\')
        $entry=@($zip.Entries | Where-Object { $_.FullName.Replace('/','\').Equals($targetNorm,[StringComparison]::OrdinalIgnoreCase) })
        if ($entry.Count -ne 1) { throw "Expected one selected truck entry, found $($entry.Count)." }
        $st=$entry[0].Open()
        try { $rd=New-Object IO.StreamReader($st,[Text.Encoding]::UTF8,$true); try { $text=$rd.ReadToEnd() } finally { $rd.Dispose() } } finally { $st.Dispose() }
        $text | Set-Content -LiteralPath $xmlOut -Encoding UTF8
        $lines=New-Object Collections.Generic.List[string]
        $lines.Add('WL Simplistic SnowRunner Mod Editor v1.1.0 TEST 6.10 - COMPONENT MAP')
        $lines.Add(('Generated: '+(Get-Date).ToString('yyyy-MM-dd HH:mm:ss')))
        $lines.Add('DIAGNOSTIC. TEST 6.8 diagnostic only; no private engine clone is installed.')
        $lines.Add('')
        $lines.Add(('Truck ID: '+$TruckId)); $lines.Add(('Truck entry: '+$TruckEntry)); $lines.Add('')
        $lines.Add('Lines/tags containing likely component references:')
        foreach($line in ($text -split "`r?`n")) {
            if($line -match '(?i)engine|gearbox|suspension|wheel|tire|winch|socket|template') { $lines.Add(('  '+$line.Trim())) }
        }
        $lines.Add('')
        $lines.Add('Quoted values containing likely component keywords:')
        $seen=@{}
        foreach($m in [regex]::Matches($text,'"([^"\r\n]+)"')) {
            $v=$m.Groups[1].Value
            if($v -match '(?i)engine|gearbox|susp|wheel|tire|winch' -and -not $seen.ContainsKey($v)) { $seen[$v]=$true; $lines.Add(('  '+$v)) }
        }
        $lines.Add(''); $lines.Add(('Full selected truck XML copy: '+$xmlOut))
        $lines | Set-Content -LiteralPath $report -Encoding UTF8
    } finally { if($null-ne $zip){$zip.Dispose()}; if($null-ne $fs){$fs.Dispose()} }
}

function Write-TireFamilyDiagnostic([string]$PakPath, [string]$TruckEntry, [string]$TruckId) {
    if ([string]::IsNullOrWhiteSpace($TruckEntry)) { return }
    $desktop=[Environment]::GetFolderPath('Desktop')
    $report=Join-Path $desktop 'WL-SnowRunner-TEST6.13.1-WheelResolution.txt'
    $fs=$null; $zip=$null
    try {
        $fs=[IO.File]::OpenRead($PakPath)
        $zip=New-Object IO.Compression.ZipArchive($fs,[IO.Compression.ZipArchiveMode]::Read)
        $truck=@($zip.Entries | Where-Object { $_.FullName.Replace('/','\').Equals($TruckEntry.Replace('/','\'),[StringComparison]::OrdinalIgnoreCase) })
        if($truck.Count -ne 1){throw "TEST 6.13 wheel diagnostic: expected one selected truck XML, found $($truck.Count)."}
        $st=$truck[0].Open(); try{$rd=New-Object IO.StreamReader($st,[Text.Encoding]::UTF8,$true);try{$truckText=$rd.ReadToEnd()}finally{$rd.Dispose()}}finally{$st.Dispose()}
        $wm=[regex]::Match($truckText,'(?is)<Wheels\b[^>]*>')
        if(-not $wm.Success){throw 'TEST 6.13 wheel diagnostic: selected truck has no resolvable <Wheels> tag.'}
        $dt=[regex]::Match($wm.Value,'(?i)\bDefaultTire="([^"]+)"'); $dw=[regex]::Match($wm.Value,'(?i)\bDefaultWheelType="([^"]+)"')
        $defaultTire=if($dt.Success){$dt.Groups[1].Value}else{''}; $wheelType=if($dw.Success){$dw.Groups[1].Value}else{''}
        $exact=@($zip.Entries | Where-Object { $_.Name.Equals(($wheelType+'.xml'),[StringComparison]::OrdinalIgnoreCase) -and $_.FullName.Replace('/','\') -match '(?i)(?:^|\\)classes\\wheels\\[^\\]+\.xml$' })
        $lines=New-Object Collections.Generic.List[string]
        $lines.Add('WL Simplistic SnowRunner Mod Editor v1.1.0 TEST 6.21.3 - WHEEL FAMILY RESOLUTION')
        $lines.Add(('Generated: '+(Get-Date).ToString('yyyy-MM-dd HH:mm:ss')))
        $lines.Add('READ-ONLY DIAGNOSTIC. NO TIRE/WHEEL MODIFICATION IS PERFORMED BY TEST 6.13.')
        $lines.Add(''); $lines.Add(('Truck ID: '+$TruckId)); $lines.Add(('Truck entry: '+$TruckEntry)); $lines.Add(('Wheels tag: '+$wm.Value.Trim()))
        $lines.Add(('DefaultTire: '+$defaultTire)); $lines.Add(('DefaultWheelType: '+$wheelType)); $lines.Add(('Exact wheel-family filename matches: '+$exact.Count));
        foreach($e in $exact){$lines.Add(('  EXACT FAMILY: '+$e.FullName))}
        $lines.Add(''); $lines.Add('TRUCK XMLs USING THIS DefaultWheelType:')
        $truckHits=0
        foreach($e in $zip.Entries){
            $n=$e.FullName.Replace('/','\'); if($n -notmatch '(?i)(?:^|\\)classes\\trucks\\[^\\]+\.xml$'){continue}
            $es=$e.Open(); try{$r=New-Object IO.StreamReader($es,[Text.Encoding]::UTF8,$true);try{$t=$r.ReadToEnd()}finally{$r.Dispose()}}finally{$es.Dispose()}
            if($t -match ('(?i)\bDefaultWheelType="'+[regex]::Escape($wheelType)+'"')){
                $truckHits++; $dm=[regex]::Match($t,'(?is)<Wheels\b[^>]*\bDefaultWheelType="'+[regex]::Escape($wheelType)+'"[^>]*>')
                $lines.Add(('  '+$e.FullName)); if($dm.Success){$lines.Add(('    '+$dm.Value.Trim()))}
            }
        }
        $lines.Add(('Truck references found: '+$truckHits))
        $lines.Add(''); $lines.Add('EXACT WHEEL FAMILY CONTENT (wheel/tire structure):')
        foreach($e in $exact){
            $lines.Add(('  ENTRY: '+$e.FullName)); $es=$e.Open(); try{$r=New-Object IO.StreamReader($es,[Text.Encoding]::UTF8,$true);try{$t=$r.ReadToEnd()}finally{$r.Dispose()}}finally{$es.Dispose()}
            foreach($line in ($t -split "`r?`n")){if($line -match '(?i)<TruckWheels|</TruckWheels|<TruckTire|</TruckTire|<TruckRim|<WheelFriction|<WheelSoftness|<WheelTracks|_template=|Name=|BodyFriction|SubstanceFriction|DamageCapacity'){$lines.Add(('    '+$line.Trim()))}}
        }
        $lines.Add(''); $lines.Add('OTHER XML REFERENCES TO THIS WHEEL FAMILY TOKEN (excluding selected truck):')
        $refs=0
        foreach($e in $zip.Entries){
            if(-not $e.FullName.EndsWith('.xml',[StringComparison]::OrdinalIgnoreCase)){continue}; if($e.FullName.Replace('/','\').Equals($TruckEntry.Replace('/','\'),[StringComparison]::OrdinalIgnoreCase)){continue}
            $es=$e.Open(); try{$r=New-Object IO.StreamReader($es,[Text.Encoding]::UTF8,$true);try{$t=$r.ReadToEnd()}finally{$r.Dispose()}}finally{$es.Dispose()}
            if($t.IndexOf($wheelType,[StringComparison]::OrdinalIgnoreCase) -ge 0){$refs++; $lines.Add(('  '+$e.FullName)); foreach($line in ($t -split "`r?`n")){if($line.IndexOf($wheelType,[StringComparison]::OrdinalIgnoreCase) -ge 0){$lines.Add(('    '+$line.Trim()))}}}
        }
        $lines.Add(('Other XML reference files: '+$refs))
        $lines.Add(''); $lines.Add('PURPOSE: determine whether DefaultWheelType is a filename/class token that can safely be isolated, and identify all stock trucks that share the selected wheel family before TEST 6.14.')
        $lines | Set-Content -LiteralPath $report -Encoding UTF8
        $localReport = Join-Path $PSScriptRoot 'WL-SnowRunner-TEST6.13.1-WheelResolution.txt'
        $lines | Set-Content -LiteralPath $localReport -Encoding UTF8
    } finally {if($zip){$zip.Dispose()};if($fs){$fs.Dispose()}}
}

function Get-IndividualEnginePlan([string]$PakPath, [string]$TruckEntry, [string]$TruckId) {
    $input = $null; $zip = $null; $usePlannerCache=$false
    try {
        $fullPak=[IO.Path]::GetFullPath([string]$PakPath)
        if($script:WLCategoryPlannerZip -and $script:WLCategoryPlannerPakPath -and $fullPak.Equals([string]$script:WLCategoryPlannerPakPath,[StringComparison]::OrdinalIgnoreCase)){
            $zip=$script:WLCategoryPlannerZip; $usePlannerCache=$true
        } else {
            $input = [IO.File]::OpenRead($PakPath)
            $zip = New-Object IO.Compression.ZipArchive($input, [IO.Compression.ZipArchiveMode]::Read)
        }
        $truck = $zip.Entries | Where-Object { $_.FullName.Replace('/', '\').Equals($TruckEntry.Replace('/', '\'), [StringComparison]::OrdinalIgnoreCase) } | Select-Object -First 1
        if (-not $truck) { throw 'RC3.6 engine safety stop: selected truck XML could not be reopened. No modifications were made.' }
        $reader = New-Object IO.StreamReader($truck.Open(), [Text.Encoding]::UTF8, $true)
        try { $text = $reader.ReadToEnd() } finally { $reader.Dispose() }
        $m = [regex]::Match($text, '(?is)<EngineSocket\b(?=[^>]*\bDefault="([^"]+)")(?=[^>]*\bType="([^"]+)")[^>]*/?>')
        if (-not $m.Success) { throw 'RC3.6 engine safety stop: EngineSocket Default/Type could not be resolved. No modifications were made.' }
        $engineDefault=$m.Groups[1].Value; $engineTypeRaw=$m.Groups[2].Value
        # RC3.6: every token in EngineSocket Type is a compatible engine family for this truck.
        # Modify all existing compatible family XMLs in place; never clone/repoint identifiers.
        $engineTypes = @($engineTypeRaw -split '\s*,\s*' | ForEach-Object { $_.Trim() } | Where-Object { $_ } | Select-Object -Unique)
        if($engineTypes.Count -lt 1){ throw 'RC3.6 engine safety stop: no compatible engine-family tokens were resolved.' }
        $families = @()
        foreach($candidateType in $engineTypes){
            $wanted = ($candidateType + '.xml').ToLowerInvariant()

            # v1.2.0 DEV7:
            # Official initial.pak families normally live under classes/engines.
            # Third-party PAK authors are not required to preserve that exact archive layout.
            # Resolve by exact filename first, then validate the XML CONTENT as an engine family.
            # This remains fail-closed: zero valid families or multiple valid families are rejected.
            $nameMatches = @($zip.Entries | Where-Object {
                $_.Name.ToLowerInvariant() -eq $wanted -and
                $_.FullName.EndsWith('.xml',[StringComparison]::OrdinalIgnoreCase)
            })

            $validEntries = @()
            foreach($candidateEntry in $nameMatches){
                $er=New-Object IO.StreamReader($candidateEntry.Open(),[Text.Encoding]::UTF8,$true)
                try{$candidateText=$er.ReadToEnd()}finally{$er.Dispose()}
                $candidateVariants=[regex]::Matches($candidateText,'(?is)<Engine\b(?=[^>]*\bName="[^"]+")[^>]*>.*?</Engine>').Count
                if($candidateVariants -gt 0){
                    $validEntries += [pscustomobject]@{
                        Entry=$candidateEntry
                        Text=$candidateText
                        VariantCount=[int]$candidateVariants
                    }
                }
            }

            if($validEntries.Count -eq 0){
                # DEV30: a declared engine family may be inherited from vanilla/another package.
                # Never touch initial.pak for a MOD target; mark only this family unsupported locally.
                $families += [pscustomobject]@{Type=[string]$candidateType; Entry=''; VariantCount=0; Inherited=$true}
                continue
            }
            if($validEntries.Count -ne 1){
                $paths=($validEntries | ForEach-Object {$_.Entry.FullName}) -join '; '
                throw "v1.2.0 DEV7 engine safety stop: compatible engine family '$candidateType' resolved to $($validEntries.Count) valid engine XML files inside this mod PAK ($paths). Expected exactly 1. No modifications were made."
            }

            $chosen=$validEntries[0]
            $variantCount=[int]$chosen.VariantCount
            $families += [pscustomobject]@{Type=[string]$candidateType; Entry=[string]$chosen.Entry.FullName; VariantCount=$variantCount; Inherited=$false}
        }
        # The stock/default engine must exist in at least one declared compatible family.
        $defaultHits=0
        $localFamilies=@($families | Where-Object {-not $_.Inherited})
        $inheritedFamilies=@($families | Where-Object {$_.Inherited})
        foreach($fam in $localFamilies){
            $e=$zip.Entries | Where-Object {$_.FullName -eq $fam.Entry} | Select-Object -First 1
            $rr=New-Object IO.StreamReader($e.Open(),[Text.Encoding]::UTF8,$true); try{$tt=$rr.ReadToEnd()}finally{$rr.Dispose()}
            if([regex]::IsMatch($tt,('(?is)<Engine\b(?=[^>]*\bName="'+[regex]::Escape($engineDefault)+'")[^>]*>'))){$defaultHits++}
        }
        # If inherited families exist, the default may legitimately live there. Only reject a
        # missing default when every declared family is local and therefore fully inspectable.
        if($defaultHits -lt 1 -and $inheritedFamilies.Count -eq 0){ throw "RC3.6 engine safety stop: stock/default engine '$engineDefault' was not found in any declared compatible engine family. No modifications were made." }
        return [pscustomobject]@{ Default=[string]$engineDefault; Types=[string[]]@($localFamilies | ForEach-Object {[string]$_.Type}); SourceEntries=[string[]]@($localFamilies | ForEach-Object {[string]$_.Entry}); Families=[object[]]@($localFamilies); InheritedTypes=[string[]]@($inheritedFamilies | ForEach-Object {[string]$_.Type}) }
    } finally { if (-not $usePlannerCache -and $zip) {$zip.Dispose()}; if ($input) {$input.Dispose()} }
}

function Write-EngineFamilyDiagnostic([string]$PakPath, $Plan, [string]$TruckId) {
    if (-not $Plan) { return }
    $desktop=[Environment]::GetFolderPath('Desktop')
    $report=Join-Path $desktop 'WL-SnowRunner-TEST6.8-EngineFamilyMap.txt'
    $xmlOut=Join-Path $desktop 'WL-SnowRunner-TEST6.8-EngineFamily.xml'
    $fs=$null; $zip=$null
    try {
        $fs=[IO.File]::OpenRead($PakPath); $zip=New-Object IO.Compression.ZipArchive($fs,[IO.Compression.ZipArchiveMode]::Read)
        $src=@($zip.Entries | Where-Object { $_.FullName.Replace('/','\').Equals(([string]$Plan.SourceEntry).Replace('/','\'),[StringComparison]::OrdinalIgnoreCase) })
        if($src.Count -ne 1){ throw "TEST 6.8 diagnostic: expected one engine-family source, found $($src.Count)." }
        $st=$src[0].Open(); try{$rd=New-Object IO.StreamReader($st,[Text.Encoding]::UTF8,$true);try{$engineText=$rd.ReadToEnd()}finally{$rd.Dispose()}}finally{$st.Dispose()}
        $engineText | Set-Content -LiteralPath $xmlOut -Encoding UTF8
        $refs=New-Object Collections.Generic.List[string]
        foreach($e in $zip.Entries){
            if(-not $e.FullName.EndsWith('.xml',[StringComparison]::OrdinalIgnoreCase)){continue}
            $es=$e.Open(); try{$r=New-Object IO.StreamReader($es,[Text.Encoding]::UTF8,$true);try{$t=$r.ReadToEnd()}finally{$r.Dispose()}}finally{$es.Dispose()}
            if($t -match ('(?i)Type="'+[regex]::Escape([string]$Plan.Type)+'"') -or $t -match ('(?i)Default="'+[regex]::Escape([string]$Plan.Default)+'"')){$refs.Add($e.FullName)}
        }
        $lines=New-Object Collections.Generic.List[string]
        $lines.Add('WL Simplistic SnowRunner Mod Editor v1.1.0 TEST 6.10 - ENGINE FAMILY MAP')
        $lines.Add(('Generated: '+(Get-Date).ToString('yyyy-MM-dd HH:mm:ss')))
        $lines.Add('DIAGNOSTIC REPORT. TEST 6.9 Apply may add a private engine variant; this report itself modifies nothing.')
        $lines.Add(''); $lines.Add(('Truck ID: '+$TruckId)); $lines.Add(('Engine default: '+$Plan.Default)); $lines.Add(('Engine type/family: '+$Plan.Type)); $lines.Add(('Engine family XML: '+$Plan.SourceEntry)); $lines.Add(('6.7 failed family-clone entry was: '+$Plan.CloneEntry));
        $lines.Add(''); $lines.Add(('XML entries referencing this family/default: '+$refs.Count)); foreach($x in $refs){$lines.Add(('  '+$x))}
        $lines.Add(''); $lines.Add('Engine-family XML structure:');
        foreach($line in ($engineText -split "`r?`n")){if($line -match '(?i)<Engine|_template|Include=|Name=|Torque=|FuelConsumption=|DamageCapacity=|CriticalDamageThreshold='){$lines.Add(('  '+$line.Trim()))}}
        $lines.Add(''); $lines.Add(('Full engine-family XML copy: '+$xmlOut)); $lines | Set-Content -LiteralPath $report -Encoding UTF8
    } finally {if($zip){$zip.Dispose()};if($fs){$fs.Dispose()}}
}

function Repoint-IndividualEngine([string]$Text, $S, $Counts) {
    if (-not $S.TargetTruckId) { return $Text }
    $engineChange = ([math]::Abs([double]$S.EngineTorque-1.0) -ge 0.0000001) -or ([math]::Abs([double]$S.EngineResponse-1.0) -ge 0.0000001) -or ([math]::Abs([double]$S.EngineFuel-1.0) -ge 0.0000001) -or ([math]::Abs([double]$S.EngineDurability-1.0) -ge 0.0000001)
    if (-not $engineChange) { return $Text }
    if (-not $S.IndividualEnginePrivateName) { throw 'TEST 6.9 engine-variant safety stop: private engine variant was not prepared.' }
    $oldDefault = [string]$S.IndividualEngineDefault
    $engineType = [string]$S.IndividualEngineType
    # TEST 6.20.4: match the EngineSocket tag independent of attribute order.
    # SnowRunner truck XML commonly stores Default before Type; the old repoint regex
    # incorrectly required Type to appear before Default and therefore reported 0 hits.
    $tagPattern = '(?is)<EngineSocket\b(?=[^>]*\bType="' + [regex]::Escape($engineType) + '")(?=[^>]*\bDefault="' + [regex]::Escape($oldDefault) + '")[^>]*/?>'
    $tagMatches = [regex]::Matches($Text, $tagPattern)
    $hits = $tagMatches.Count
    if ($hits -ne 1) { throw "TEST 6.9 engine-variant safety stop: selected truck contains $hits matching EngineSocket Default references; expected exactly 1." }
    $newName = [string]$S.IndividualEnginePrivateName
    $tag = $tagMatches[0].Value
    $newTag = [regex]::Replace($tag, '(?i)(\bDefault=")' + [regex]::Escape($oldDefault) + '(")', { param($m) $m.Groups[1].Value + $newName + $m.Groups[2].Value }, 1)
    if ($newTag -eq $tag) { throw 'TEST 6.20.4 engine-variant safety stop: EngineSocket was resolved but its Default value could not be repointed. No modifications were made.' }
    $Text = $Text.Substring(0,$tagMatches[0].Index) + $newTag + $Text.Substring($tagMatches[0].Index + $tagMatches[0].Length)
    Add-Count $Counts 'Individual engine variant reference' 1
    return $Text
}

function Add-PrivateEngineVariant([string]$Text, $S, $Counts) {
    $defaultName = [regex]::Escape([string]$S.IndividualEngineDefault)
    $privateName = [string]$S.IndividualEnginePrivateName
    if (-not $defaultName -or -not $privateName) { throw 'TEST 6.9 engine-variant safety stop: engine variant names are missing.' }
    if ($Text -match ('(?i)\bName="' + [regex]::Escape($privateName) + '"')) { throw 'TEST 6.9 engine-variant safety stop: private engine variant already exists in baseline unexpectedly.' }
    $pattern = '(?is)<Engine\b(?=[^>]*\bName="' + $defaultName + '")[^>]*>.*?</Engine>'
    $matches = [regex]::Matches($Text, $pattern)
    if ($matches.Count -ne 1) { throw "TEST 6.9 engine-variant safety stop: default engine '$($S.IndividualEngineDefault)' matched $($matches.Count) variant blocks; expected exactly 1." }
    $block = $matches[0].Value
    $clone = [regex]::Replace($block, '(?i)(\bName=")' + $defaultName + '(")', { param($m) $m.Groups[1].Value + $privateName + $m.Groups[2].Value }, 1)
    # TEST 6.21.1: all individual engine controls modify only the selected truck's
    # private variant inside the existing stock engine family. The stock family
    # Type remains unchanged, preserving the proven TEST 6.9 architecture.
    # TEST 6.21.2: each private-engine control is independent. A stock 1.00
    # multiplier means leave that attribute untouched; it is not a safety failure.
    if ([math]::Abs([double]$S.EngineTorque-1.0) -ge 0.0000001) {
        $before = if ($Counts.ContainsKey('Engine torque')) { [int]$Counts['Engine torque'] } else { 0 }
        $clone = Replace-NumericAttribute $clone 'Torque' ([double]$S.EngineTorque) $Counts 'Engine torque'
        $after = if ($Counts.ContainsKey('Engine torque')) { [int]$Counts['Engine torque'] } else { 0 }
        if (($after-$before) -ne 1) { throw "TEST 6.21.2 engine-variant safety stop: Torque was requested but expected exactly 1 Torque value in cloned engine variant; changed $($after-$before)." }
    }

    # TEST 6.21.1: EngineResponsiveness can be inherited from the engine template.
    # If the selected variant does not explicitly carry it, resolve the template value
    # and write an explicit override into only the private variant.
    if ([math]::Abs([double]$S.EngineResponse-1.0) -ge 0.0000001) {
        if ([regex]::IsMatch($clone,'(?i)\bEngineResponsiveness="[^"]+"')) {
            $clone = Replace-NumericAttribute $clone 'EngineResponsiveness' ([double]$S.EngineResponse) $Counts 'Engine responsiveness'
        } else {
            $baseResponse = $null
            $tm = [regex]::Match($block,'(?i)\b_template="([^"]+)"')
            if ($tm.Success) {
                $templateName=[regex]::Escape($tm.Groups[1].Value)
                $templateTag=[regex]::Match($Text,('(?is)<' + $templateName + '\b[^>]*>'))
                if (-not $templateTag.Success) { $templateTag=[regex]::Match($Text,('(?is)<' + $templateName + '\b[^>]*/>')) }
                if ($templateTag.Success) {
                    $rm=[regex]::Match($templateTag.Value,'(?i)\bEngineResponsiveness="([0-9eE+\-.]+)"')
                    if ($rm.Success) { $baseResponse=[double]::Parse($rm.Groups[1].Value,[Globalization.CultureInfo]::InvariantCulture) }
                }
            }
            # Saber documentation defines 0.04 as the EngineResponsiveness default.
            # Use it only when neither the variant nor its template provides a value.
            if ($null -eq $baseResponse) { $baseResponse=0.04 }
            $newResponse=$baseResponse * [double]$S.EngineResponse
            if ($newResponse -gt 1.0) { $newResponse=1.0 }
            if ($newResponse -lt 0.01) { $newResponse=0.01 }
            $formatted=$newResponse.ToString('0.######',[Globalization.CultureInfo]::InvariantCulture)
            $open=[regex]::Match($clone,'(?is)<Engine\b[^>]*>')
            if (-not $open.Success) { throw 'TEST 6.21.1 engine responsiveness safety stop: private Engine opening tag could not be found.' }
            $newOpen=$open.Value.Insert($open.Value.Length-1,(' EngineResponsiveness="'+$formatted+'"'))
            $clone=$clone.Substring(0,$open.Index)+$newOpen+$clone.Substring($open.Index+$open.Length)
            Add-Count $Counts 'Engine responsiveness' 1
        }
    }
    $clone = Replace-NumericAttribute $clone 'FuelConsumption' ([double]$S.EngineFuel) $Counts 'Engine fuel consumption'
    $clone = Replace-NumericAttribute $clone 'DamageCapacity' ([double]$S.EngineDurability) $Counts 'Engine durability'
    $close = [regex]::Matches($Text, '(?i)</EngineVariants>')
    if ($close.Count -ne 1) { throw "TEST 6.9 engine-variant safety stop: expected exactly 1 </EngineVariants> tag; found $($close.Count)." }
    $insert = "`r`n`t<!-- WL private engine variant for $($S.TargetTruckId) -->`r`n" + $clone + "`r`n"
    $Text = $Text.Insert($close[0].Index, $insert)
    Add-Count $Counts 'Private engine variants added' 1
    return $Text
}

function Get-IndividualGearboxPlan([string]$PakPath, [string]$TruckEntry, [string]$TruckId) {
    $input=$null; $zip=$null; $usePlannerCache=$false
    try {
        $fullPak=[IO.Path]::GetFullPath([string]$PakPath)
        if($script:WLCategoryPlannerZip -and $script:WLCategoryPlannerPakPath -and $fullPak.Equals([string]$script:WLCategoryPlannerPakPath,[StringComparison]::OrdinalIgnoreCase)){
            $zip=$script:WLCategoryPlannerZip; $usePlannerCache=$true
        } else {
            $input=[IO.File]::OpenRead($PakPath); $zip=New-Object IO.Compression.ZipArchive($input,[IO.Compression.ZipArchiveMode]::Read)
        }
        $truck=$zip.Entries | Where-Object { $_.FullName.Replace('/','\').Equals($TruckEntry.Replace('/','\'),[StringComparison]::OrdinalIgnoreCase) } | Select-Object -First 1
        if(-not $truck){throw 'TEST 6.10 gearbox safety stop: selected truck XML could not be reopened.'}
        $reader=New-Object IO.StreamReader($truck.Open(),[Text.Encoding]::UTF8,$true); try{$text=$reader.ReadToEnd()}finally{$reader.Dispose()}
        $m=[regex]::Match($text,'(?is)<GearboxSocket\b(?=[^>]*\bDefault="([^"]+)")(?=[^>]*\bType="([^"]+)")[^>]*/?>')
        if(-not $m.Success){throw 'TEST 6.10 gearbox safety stop: GearboxSocket Default/Type could not be resolved.'}
        $def=$m.Groups[1].Value
        # DEV24: SnowRunner allows GearboxSocket Type to declare multiple compatible families
        # as a comma-separated list. Resolve each family independently instead of treating the
        # complete list as one literal filename. This is structural discovery, not a truck whitelist.
        $types=@($m.Groups[2].Value -split '\s*,\s*' | ForEach-Object {$_.Trim()} | Where-Object {$_})
        if($types.Count -lt 1){throw 'DEV25 gearbox safety stop: GearboxSocket Type resolved to no usable family identifiers.'}
        $sourceEntries=New-Object System.Collections.Generic.List[string]
        $resolvedTypes=New-Object System.Collections.Generic.List[string]
        $inheritedTypes=New-Object System.Collections.Generic.List[string]
        foreach($type in $types){
            $wanted=($type+'.xml').ToLowerInvariant()
            $matches=@($zip.Entries | Where-Object { $_.Name.ToLowerInvariant() -eq $wanted -and $_.FullName.Replace('/','\').ToLowerInvariant() -match '(?:^|\\)classes\\gearboxes\\[^\\]+\.xml$' })
            if($matches.Count -gt 1){throw "DEV25 gearbox safety stop: gearbox family '$type' matched $($matches.Count) local XML entries; expected at most 1."}
            if($matches.Count -eq 1){
                # DEV25: Type can list several compatible gearbox families, but Default names the
                # gearbox variant actually selected by this truck. Only promote a local family to
                # the editable plan when its XML contains that exact named default variant.
                $gr=New-Object IO.StreamReader($matches[0].Open(),[Text.Encoding]::UTF8,$true)
                try{$gx=$gr.ReadToEnd()}finally{$gr.Dispose()}
                $defPattern='(?is)<Gearbox\b(?=[^>]*\bName="'+[regex]::Escape($def)+'")[^>]*>.*?</Gearbox>'
                $defHits=[regex]::Matches($gx,$defPattern).Count
                if($defHits -gt 1){throw "DEV25 gearbox safety stop: default gearbox '$def' matched $defHits variants inside family '$type'; expected at most 1."}
                if($defHits -eq 1){$resolvedTypes.Add($type);$sourceEntries.Add($matches[0].FullName)}
                # A compatible local family that does not contain Default is valid, but it is not
                # the truck's active gearbox and must not be tuned merely because Type lists it.
            } else {$inheritedTypes.Add($type)}
        }
        if($sourceEntries.Count -lt 1){
            # Preserve DEV23 inherited-component behavior: a valid reference with no local family
            # is not a reason to touch global initial.pak. The caller may safely skip this feature.
            return [pscustomobject]@{Default=$def;Type=($types -join ',');Types=@($types);SourceEntry='';SourceEntries=@();InheritedTypes=@($inheritedTypes)}
        }
        return [pscustomobject]@{Default=$def;Type=($resolvedTypes -join ',');Types=@($resolvedTypes);SourceEntry=$sourceEntries[0];SourceEntries=@($sourceEntries);InheritedTypes=@($inheritedTypes)}
    } finally {if(-not $usePlannerCache -and $zip){$zip.Dispose()};if($input){$input.Dispose()}}
}


function Repoint-IndividualGearbox([string]$Text,$S,$Counts) {
    if(-not $S.TargetTruckId){return $Text}
    $gearboxChange = ([math]::Abs([double]$S.GearSpeed-1.0)-ge 0.0000001) -or ([math]::Abs([double]$S.GearboxFuel-1.0)-ge 0.0000001) -or ([math]::Abs([double]$S.AwdFuel-1.0)-ge 0.0000001) -or ([math]::Abs([double]$S.IdleFuel-1.0)-ge 0.0000001) -or ([math]::Abs([double]$S.GearboxDurability-1.0)-ge 0.0000001)
    if(-not $gearboxChange){return $Text}
    if(-not $S.IndividualGearboxPrivateName){throw 'TEST 6.10 gearbox safety stop: private gearbox variant was not prepared.'}
    $old=[regex]::Escape([string]$S.IndividualGearboxDefault)
    $pattern='(?is)(<GearboxSocket\b(?=[^>]*\bType="'+[regex]::Escape([string]$S.IndividualGearboxType)+'")[^>]*\bDefault=")'+$old+'("[^>]*/?>)'
    $hits=[regex]::Matches($Text,$pattern).Count
    if($hits-ne 1){throw "TEST 6.10 gearbox safety stop: selected truck contains $hits matching GearboxSocket references; expected 1."}
    $new=[string]$S.IndividualGearboxPrivateName
    $Text=[regex]::Replace($Text,$pattern,{param($m)$m.Groups[1].Value+$new+$m.Groups[2].Value},1)
    Add-Count $Counts 'Individual gearbox variant reference' 1
    return $Text
}

function Add-PrivateGearboxVariant([string]$Text,$S,$Counts) {
    $def=[regex]::Escape([string]$S.IndividualGearboxDefault); $private=[string]$S.IndividualGearboxPrivateName
    if(-not $def-or-not $private){throw 'TEST 6.10 gearbox safety stop: gearbox variant names are missing.'}
    if($Text-match('(?i)\bName="'+[regex]::Escape($private)+'"')){throw 'TEST 6.10 gearbox safety stop: private gearbox variant already exists unexpectedly.'}
    $pattern='(?is)<Gearbox\b(?=[^>]*\bName="'+$def+'")[^>]*>.*?</Gearbox>'
    $ms=[regex]::Matches($Text,$pattern)
    if($ms.Count-ne 1){throw "TEST 6.10 gearbox safety stop: default gearbox '$($S.IndividualGearboxDefault)' matched $($ms.Count) blocks; expected 1."}
    $clone=$ms[0].Value
    $clone=[regex]::Replace($clone,'(?i)(\bName=")'+$def+'(")',{param($m)$m.Groups[1].Value+$private+$m.Groups[2].Value},1)
    # TEST 6.23.1: legacy private gearbox helper retained but no longer used by the active individual path.
    if([math]::Abs([double]$S.GearSpeed-1.0)-ge 0.0000001){
        $before=if($Counts.ContainsKey('Gear speed')){[int]$Counts['Gear speed']}else{0}
        $clone=Replace-NumericAttribute $clone 'AngVel' ([double]$S.GearSpeed) $Counts 'Gear speed'
        $after=if($Counts.ContainsKey('Gear speed')){[int]$Counts['Gear speed']}else{0}
        if(($after-$before)-lt 1){throw 'TEST 6.23.1 gearbox safety stop: cloned gearbox contained no AngVel values to modify.'}
    }
    if([math]::Abs([double]$S.GearboxFuel-1.0)-ge 0.0000001){
        $clone=Replace-NumericAttribute $clone 'FuelConsumption' ([double]$S.GearboxFuel) $Counts 'Gearbox fuel consumption'
    }
    if([math]::Abs([double]$S.AwdFuel-1.0)-ge 0.0000001){
        $clone=Replace-NumericAttribute $clone 'AWDConsumptionModifier' ([double]$S.AwdFuel) $Counts 'AWD fuel penalty'
    }
    if([math]::Abs([double]$S.IdleFuel-1.0)-ge 0.0000001){
        $clone=Replace-NumericAttribute $clone 'IdleFuelModifier' ([double]$S.IdleFuel) $Counts 'Idle fuel use'
    }
    if([math]::Abs([double]$S.GearboxDurability-1.0)-ge 0.0000001){
        $clone=Replace-NumericAttribute $clone 'DamageCapacity' ([double]$S.GearboxDurability) $Counts 'Gearbox durability'
    }
    $close=[regex]::Matches($Text,'(?i)</GearboxVariants>')
    if($close.Count-ne 1){throw "TEST 6.10 gearbox safety stop: expected exactly 1 </GearboxVariants>; found $($close.Count)."}
    $insert="`r`n`t<!-- WL private gearbox variant for $($S.TargetTruckId) -->`r`n"+$clone+"`r`n"
    $Text=$Text.Insert($close[0].Index,$insert); Add-Count $Counts 'Private gearbox variants added' 1; return $Text
}

function Get-IndividualTirePlan([string]$PakPath,[string]$TruckEntry,[string]$TruckId) {
    # SPEED 8: resolve EVERY official wheel family the selected truck can use, not only
    # DefaultWheelType.  JAT / Ultima and other official DLC tire sets are commonly exposed
    # through <CompatibleWheels Type="..."> and carry their own <TruckTire><WheelFriction>
    # overrides.  Editing only the default family leaves those tires at vanilla grip.
    $input=$null; $zip=$null; $usePlannerCache=$false
    try {
        $fullPak=[IO.Path]::GetFullPath([string]$PakPath)
        if($script:WLCategoryPlannerZip -and $script:WLCategoryPlannerPakPath -and $fullPak.Equals([string]$script:WLCategoryPlannerPakPath,[StringComparison]::OrdinalIgnoreCase)){
            $zip=$script:WLCategoryPlannerZip; $usePlannerCache=$true
        } else {
            $input=[IO.File]::OpenRead($PakPath); $zip=New-Object IO.Compression.ZipArchive($input,[IO.Compression.ZipArchiveMode]::Read)
        }
        $truck=$zip.Entries | Where-Object { $_.FullName.Replace('/','\\').Equals($TruckEntry.Replace('/','\\'),[StringComparison]::OrdinalIgnoreCase) } | Select-Object -First 1
        if(-not $truck){throw 'TEST 6.12 tire safety stop: selected truck XML could not be reopened.'}
        $reader=New-Object IO.StreamReader($truck.Open(),[Text.Encoding]::UTF8,$true); try{$text=$reader.ReadToEnd()}finally{$reader.Dispose()}
        $wm=[regex]::Match($text,'(?is)<Wheels\b[^>]*>')
        if(-not $wm.Success){throw 'TEST 6.12 tire safety stop: selected truck has no resolvable <Wheels> tag.'}
        $dt=[regex]::Match($wm.Value,'(?i)\bDefaultTire="([^"]+)"'); $dw=[regex]::Match($wm.Value,'(?i)\bDefaultWheelType="([^"]+)"')
        if(-not $dt.Success -or -not $dw.Success){throw 'TEST 6.12 tire safety stop: DefaultTire/DefaultWheelType could not be resolved.'}
        $def=$dt.Groups[1].Value; $defaultType=$dw.Groups[1].Value

        $types=New-Object Collections.Generic.List[string]
        $seenTypes=@{}
        $addType={param([string]$v)
            if(-not $v){return}
            foreach($piece in @($v -split '\s*,\s*')){
                $t=$piece.Trim(); if(-not $t){continue}
                $k=$t.ToLowerInvariant()
                if(-not $seenTypes.ContainsKey($k)){$seenTypes[$k]=$true;$types.Add($t)}
            }
        }
        & $addType $defaultType
        foreach($cm in [regex]::Matches($text,'(?is)<CompatibleWheels\b[^>]*\bType\s*=\s*"([^"]+)"[^>]*>')){ & $addType $cm.Groups[1].Value }

        $entries=New-Object Collections.Generic.List[string]
        $resolvedTypes=New-Object Collections.Generic.List[string]
        foreach($type in $types){
            $wanted=($type+'.xml').ToLowerInvariant()
            $matches=@($zip.Entries | Where-Object { $_.Name.ToLowerInvariant() -eq $wanted -and $_.FullName.Replace('/','\\').ToLowerInvariant() -match '(?:^|\\)classes\\wheels\\[^\\]+\.xml$' })
            if($matches.Count -gt 1){throw "SPEED 8 tire safety stop: wheel family '$type' matched $($matches.Count) local XML entries; expected at most 1."}
            if($matches.Count -eq 1){$entries.Add($matches[0].FullName);$resolvedTypes.Add($type)}
        }
        if($entries.Count -eq 0){return [pscustomobject]@{Default=$def;WheelType=$defaultType;SourceEntry='';SourceEntries=@();Types=@();Inherited=$true}}
        return [pscustomobject]@{
            Default=$def
            WheelType=$defaultType
            SourceEntry=[string]$entries[0]
            SourceEntries=$entries.ToArray()
            Types=$resolvedTypes.ToArray()
            Inherited=$false
        }
    } finally {if(-not $usePlannerCache -and $zip){$zip.Dispose()};if($input){$input.Dispose()}}
}

function Repoint-IndividualTire([string]$Text,$S,$Counts) {
    # TEST 6.14 does NOT invent a new tire Name. Keep DefaultTire unchanged.
    return $Text
}

function Repoint-IndividualWheelFamily([string]$Text,$S,$Counts) {
    $script:WLWheelDefaultHits=0
    if(-not $S.TargetTruckId -or [math]::Abs([double]$S.TireMud-1.0)-lt 0.0000001){return $Text}
    if(-not $S.IndividualWheelType -or -not $S.IndividualWheelPrivateType){throw 'TEST 6.14.1 wheel safety stop: private wheel family was not prepared.'}

    $old=[string]$S.IndividualWheelType
    $new=[string]$S.IndividualWheelPrivateType
    $wheelsPattern='(?is)<Wheels\b[^>]*>'
    $wheels=[regex]::Matches($Text,$wheelsPattern)
    if($wheels.Count -lt 1){throw 'TEST 6.14.1 wheel safety stop: selected truck contains no <Wheels> tag.'}

    $defaultHits=0
    $Text=[regex]::Replace($Text,$wheelsPattern,{
        param($m)
        $tag=$m.Value
        $p='(?i)(\bDefaultWheelType\s*=\s*")'+[regex]::Escape($old)+'(")'
        $n=[regex]::Matches($tag,$p).Count
        if($n -gt 0){
            $script:WLWheelDefaultHits += $n
            $tag=[regex]::Replace($tag,$p,{param($x)$x.Groups[1].Value+$new+$x.Groups[2].Value})
        }
        return $tag
    })
    $defaultHits=[int]$script:WLWheelDefaultHits
    $script:WLWheelDefaultHits=0
    if($defaultHits -ne 1){throw "TEST 6.14.1 wheel safety stop: selected truck contained $defaultHits DefaultWheelType references to '$old'; expected exactly 1."}

    # Also repoint CompatibleWheels/WheelType references in this selected truck only.
    $extraHits=0
    $patterns=@(
        '(?i)(<CompatibleWheels\b[^>]*\bType\s*=\s*")'+[regex]::Escape($old)+'(")',
        '(?i)(\bWheelType\s*=\s*")'+[regex]::Escape($old)+'(")'
    )
    foreach($pat in $patterns){
        $n=[regex]::Matches($Text,$pat).Count
        if($n -gt 0){
            $Text=[regex]::Replace($Text,$pat,{param($m)$m.Groups[1].Value+$new+$m.Groups[2].Value})
            $extraHits += $n
        }
    }
    Add-Count $Counts 'Individual wheel family references' ($defaultHits+$extraHits)
    return $Text
}

function Modify-PrivateWheelFamily([string]$Text,$S,$Counts) {
    # Keep all stock tire/rim names and meshes. Only scale mud grip in this cloned family.
    $before=if($Counts.ContainsKey('Tire mud grip')){[int]$Counts['Tire mud grip']}else{0}
    $Text=Replace-NumericAttribute $Text 'SubstanceFriction' ([double]$S.TireMud) $Counts 'Tire mud grip'
    $after=if($Counts.ContainsKey('Tire mud grip')){[int]$Counts['Tire mud grip']}else{0}
    if(($after-$before)-lt 1){throw 'TEST 6.14.1 wheel safety stop: private wheel family contained no SubstanceFriction values.'}
    Add-Count $Counts 'Private wheel families added' 1
    return $Text
}


function Write-StockWheelFamilyDiagnostic([string]$PakPath,[string]$TruckEntry,[string]$TruckId) {
    $desktop=[Environment]::GetFolderPath('Desktop')
    $report=Join-Path $desktop 'WL-SnowRunner-TEST6.17-StockWheelFamilyCandidates.txt'
    $lines=New-Object Collections.Generic.List[string]
    $lines.Add('WL Simplistic SnowRunner Mod Editor v1.1.0 TEST 6.21.3 - WHEEL/TIRE OVERRIDE MAP')
    $lines.Add(('Generated: '+(Get-Date).ToString('yyyy-MM-dd HH:mm:ss')))
    $lines.Add('READ-ONLY DIAGNOSTIC. NO FILES ARE MODIFIED BY THIS REPORT.')
    $lines.Add('')
    $lines.Add(('Selected truck: '+$TruckId))
    $lines.Add(('Truck entry: '+$TruckEntry))
    $lines.Add('')

    $fs=$null;$zip=$null
    try {
        $fs=[IO.File]::OpenRead($PakPath)
        $zip=New-Object IO.Compression.ZipArchive($fs,[IO.Compression.ZipArchiveMode]::Read)
        $utf8=New-Object Text.UTF8Encoding($false)

        $truck=$zip.Entries | Where-Object {$_.FullName.Replace('/','\').Equals($TruckEntry.Replace('/','\'),[StringComparison]::OrdinalIgnoreCase)} | Select-Object -First 1
        if(-not $truck){throw 'TEST 6.18 diagnostic: selected truck XML could not be reopened.'}
        $r=New-Object IO.StreamReader($truck.Open(),[Text.Encoding]::UTF8,$true)
        try{$truckText=$r.ReadToEnd()}finally{$r.Dispose()}

        $lines.Add('SELECTED TRUCK WHEEL-RELATED XML:')
        foreach($m in [regex]::Matches($truckText,'(?is)<Wheels\b.*?</Wheels>|<CompatibleWheels\b[^>]*/>|<Wheel\b[^>]*>|<WheelType\b[^>]*>')){
            $lines.Add($m.Value.Trim())
        }
        $lines.Add('')

        $wm=[regex]::Match($truckText,'(?is)<Wheels\b[^>]*>')
        $dw=[regex]::Match($wm.Value,'(?i)\bDefaultWheelType="([^"]+)"')
        $dt=[regex]::Match($wm.Value,'(?i)\bDefaultTire="([^"]+)"')
        $wheelType=if($dw.Success){$dw.Groups[1].Value}else{''}
        $defaultTire=if($dt.Success){$dt.Groups[1].Value}else{''}
        $lines.Add(('DefaultWheelType: '+$wheelType))
        $lines.Add(('DefaultTire: '+$defaultTire))
        $lines.Add('')

        $lines.Add('STOCK TRUCKS WITH WHEEL/TIRE ATTRIBUTES OUTSIDE THE NORMAL <Wheels> DEFAULTS:')
        $interesting=0
        foreach($e in $zip.Entries){
            $norm=$e.FullName.Replace('/','\').ToLowerInvariant()
            if($norm -notmatch '(?:^|\\)classes\\trucks\\[^\\]+\.xml$'){continue}
            $rr=New-Object IO.StreamReader($e.Open(),[Text.Encoding]::UTF8,$true)
            try{$x=$rr.ReadToEnd()}finally{$rr.Dispose()}
            if($x -notmatch '<Truck>'){continue}
            $hits=New-Object Collections.Generic.List[string]
            foreach($m in [regex]::Matches($x,'(?im)^.*(?:BodyFrictionAsphalt|BodyFriction|SubstanceFriction|WheelFriction|DefaultWheelType|DefaultTire|CompatibleWheels|WheelType).*?$')){
                $v=$m.Value.Trim()
                if($v){$hits.Add($v)}
            }
            $frictionOutsideWheels=($x -match '(?i)BodyFrictionAsphalt|BodyFriction|SubstanceFriction|WheelFriction')
            $specialWheelRefs=($x -match '(?i)\bWheelType="' -or ([regex]::Matches($x,'(?i)<CompatibleWheels\b').Count -gt 0))
            if($frictionOutsideWheels -or $specialWheelRefs){
                $interesting++
                $lines.Add(('  FILE: '+$e.FullName))
                foreach($h in $hits){$lines.Add(('    '+$h))}
            }
        }
        $lines.Add(('Interesting base truck files: '+$interesting))
        $lines.Add('')

        $lines.Add('DIRECT FRICTION ATTRIBUTES FOUND IN BASE TRUCK XMLs:')
        $direct=0
        foreach($e in $zip.Entries){
            $norm=$e.FullName.Replace('/','\').ToLowerInvariant()
            if($norm -notmatch '(?:^|\\)classes\\trucks\\[^\\]+\.xml$'){continue}
            $rr=New-Object IO.StreamReader($e.Open(),[Text.Encoding]::UTF8,$true)
            try{$x=$rr.ReadToEnd()}finally{$rr.Dispose()}
            if($x -notmatch '<Truck>'){continue}
            $ms=[regex]::Matches($x,'(?im)^.*(?:BodyFrictionAsphalt|BodyFriction|SubstanceFriction|WheelFriction).*?$')
            if($ms.Count -gt 0){
                $direct++
                $lines.Add(('  FILE: '+$e.FullName))
                foreach($m in $ms){$lines.Add(('    '+$m.Value.Trim()))}
            }
        }
        $lines.Add(('Base truck XMLs containing direct friction attributes: '+$direct))
        $lines.Add('')

        $lines.Add('WHEEL FAMILY INVENTORY / UNIQUENESS:')
        $usage=@{}
        foreach($e in $zip.Entries){
            $norm=$e.FullName.Replace('/','\').ToLowerInvariant()
            if($norm -notmatch '(?:^|\\)classes\\trucks\\[^\\]+\.xml$'){continue}
            $rr=New-Object IO.StreamReader($e.Open(),[Text.Encoding]::UTF8,$true)
            try{$x=$rr.ReadToEnd()}finally{$rr.Dispose()}
            if($x -notmatch '<Truck>'){continue}
            $m=[regex]::Match($x,'(?is)<Wheels\b[^>]*\bDefaultWheelType="([^"]+)"')
            if($m.Success){
                $key=$m.Groups[1].Value
                if(-not $usage.ContainsKey($key)){$usage[$key]=New-Object Collections.Generic.List[string]}
                $usage[$key].Add($e.FullName)
            }
        }
        foreach($key in ($usage.Keys | Sort-Object)){
            $lines.Add(('  '+$key+' : '+$usage[$key].Count+' truck(s)'))
            if($usage[$key].Count -le 2){
                foreach($u in $usage[$key]){$lines.Add(('      '+$u))}
            }
        }
        $lines.Add('')
        
        $lines.Add('STOCK RECOGNIZED FAMILY CANDIDATES FOR SELECTED TRUCK:')
        $lines.Add('Criteria: family exists in initial.pak, is used as DefaultWheelType by <= 1 base truck, and contains selected DefaultTire name.')
        $candidateCount=0
        foreach($key in ($usage.Keys | Sort-Object)){
            if($usage[$key].Count -gt 1){continue}
            $family=$zip.Entries | Where-Object {
                $_.FullName.Replace('/','\').ToLowerInvariant() -match ('(?:^|\\)classes\\wheels\\'+[regex]::Escape($key.ToLowerInvariant())+'\.xml$')
            } | Select-Object -First 1
            if(-not $family){continue}
            $rr=New-Object IO.StreamReader($family.Open(),[Text.Encoding]::UTF8,$true)
            try{$fx=$rr.ReadToEnd()}finally{$rr.Dispose()}
            $hasTire=$false
            if($defaultTire){
                $hasTire=[regex]::IsMatch($fx,('(?i)<TruckTire\b[^>]*\bName="'+[regex]::Escape($defaultTire)+'"'))
            }
            if(-not $hasTire){continue}
            $candidateCount++
            $tireCount=[regex]::Matches($fx,'(?i)<TruckTire\b').Count
            $rimCount=[regex]::Matches($fx,'(?i)<TruckRim\b').Count
            $sfCount=[regex]::Matches($fx,'(?i)\bSubstanceFriction="').Count
            $bfCount=[regex]::Matches($fx,'(?i)\bBodyFriction="').Count
            $baCount=[regex]::Matches($fx,'(?i)\bBodyFrictionAsphalt="').Count
            $lines.Add(('  CANDIDATE: '+$key))
            $lines.Add(('    Entry: '+$family.FullName))
            $lines.Add(('    Default users: '+$usage[$key].Count))
            foreach($u in $usage[$key]){$lines.Add(('      User: '+$u))}
            $lines.Add(('    Contains tire "'+$defaultTire+'": YES'))
            $lines.Add(('    TruckTire definitions: '+$tireCount+' | TruckRim definitions: '+$rimCount))
            $lines.Add(('    Explicit friction attrs: Substance='+$sfCount+' Body='+$bfCount+' Asphalt='+$baCount))
        }
        $lines.Add(('Candidate count: '+$candidateCount))
        $lines.Add('')

        $lines.Add('UNUSED STOCK WHEEL FAMILY FILES:')
        $lines.Add('These exist in initial.pak but are not used as DefaultWheelType by any base truck. They are especially interesting because the identifier is stock/recognized and may avoid collateral changes.')
        $unusedCount=0
        foreach($e in $zip.Entries){
            $norm=$e.FullName.Replace('/','\').ToLowerInvariant()
            if($norm -notmatch '(?:^|\\)classes\\wheels\\([^\\]+)\.xml$'){continue}
            $familyId=$matches[1]
            if($usage.ContainsKey($familyId)){continue}
            $rr=New-Object IO.StreamReader($e.Open(),[Text.Encoding]::UTF8,$true)
            try{$fx=$rr.ReadToEnd()}finally{$rr.Dispose()}
            if($fx -notmatch '(?i)<TruckTire\b'){continue}
            $hasSelected=$false
            if($defaultTire){$hasSelected=[regex]::IsMatch($fx,('(?i)<TruckTire\b[^>]*\bName="'+[regex]::Escape($defaultTire)+'"'))}
            $unusedCount++
            $lines.Add(('  UNUSED: '+$familyId+' | selected tire present: '+$hasSelected+' | '+$e.FullName))
        }
        $lines.Add(('Unused stock wheel-family files: '+$unusedCount))
        $lines.Add('')

        $lines.Add('SELECTED TRUCK COMPATIBLE-WHEEL FAMILY DETAILS:')
        foreach($m in [regex]::Matches($truckText,'(?is)<CompatibleWheels\b[^>]*>')){
            $tag=$m.Value
            $tm=[regex]::Match($tag,'(?i)\bType="([^"]+)"')
            if(-not $tm.Success){continue}
            $cid=$tm.Groups[1].Value
            $family=$zip.Entries | Where-Object {
                $_.FullName.Replace('/','\').ToLowerInvariant() -match ('(?:^|\\)classes\\wheels\\'+[regex]::Escape($cid.ToLowerInvariant())+'\.xml$')
            } | Select-Object -First 1
            $lines.Add(('  '+$tag.Trim()))
            if($family){
                $rr=New-Object IO.StreamReader($family.Open(),[Text.Encoding]::UTF8,$true)
                try{$fx=$rr.ReadToEnd()}finally{$rr.Dispose()}
                $hasSelected=if($defaultTire){[regex]::IsMatch($fx,('(?i)<TruckTire\b[^>]*\bName="'+[regex]::Escape($defaultTire)+'"'))}else{$false}
                $lines.Add(('    Family exists: YES | selected tire present: '+$hasSelected+' | Entry: '+$family.FullName))
            } else {
                $lines.Add('    Family exists: NO')
            }
        }
        $lines.Add('')
        $lines.Add('PURPOSE: identify an already-recognized STOCK wheel family that could isolate the selected truck without inventing a new DefaultWheelType or DefaultTire identifier.')

    } finally {
        if($zip){$zip.Dispose()}
        if($fs){$fs.Dispose()}
    }
    $lines | Set-Content -LiteralPath $report -Encoding UTF8
    return $report
}

function Get-IndividualSuspensionPlan([string]$PakPath,[string]$TruckEntry,[string]$TruckId) {
    $input=$null; $zip=$null; $usePlannerCache=$false
    try {
        $fullPak=[IO.Path]::GetFullPath([string]$PakPath)
        if($script:WLCategoryPlannerZip -and $script:WLCategoryPlannerPakPath -and $fullPak.Equals([string]$script:WLCategoryPlannerPakPath,[StringComparison]::OrdinalIgnoreCase)){
            $zip=$script:WLCategoryPlannerZip; $usePlannerCache=$true
        } else {
            $input=[IO.File]::OpenRead($PakPath); $zip=New-Object IO.Compression.ZipArchive($input,[IO.Compression.ZipArchiveMode]::Read)
        }
        $truck=$zip.Entries | Where-Object { $_.FullName.Replace('/','\').Equals($TruckEntry.Replace('/','\'),[StringComparison]::OrdinalIgnoreCase) } | Select-Object -First 1
        if(-not $truck){throw 'RC3.7 suspension safety stop: selected truck XML could not be reopened. No modifications were made.'}
        $reader=New-Object IO.StreamReader($truck.Open(),[Text.Encoding]::UTF8,$true); try{$text=$reader.ReadToEnd()}finally{$reader.Dispose()}
        $m=[regex]::Match($text,'(?is)<SuspensionSocket\b(?=[^>]*\bDefault="([^"]+)")(?=[^>]*\bType="([^"]+)")[^>]*/?>')
        if(-not $m.Success){throw 'RC3.7 suspension safety stop: SuspensionSocket Default/Type could not be resolved. No modifications were made.'}
        $def=$m.Groups[1].Value
        # As with engines, Type can declare more than one compatible suspension family.
        $types=@($m.Groups[2].Value -split '[,;\s]+' | ForEach-Object {$_.Trim()} | Where-Object {$_} | Select-Object -Unique)
        if($types.Count -lt 1){throw 'RC3.7 suspension safety stop: no compatible suspension-family tokens were resolved. No modifications were made.'}
        $plans=@()
        $inheritedTypes=@()
        $defaultHits=0
        foreach($type in $types){
            $wanted=($type+'.xml').ToLowerInvariant()
            $matches=@($zip.Entries | Where-Object { $_.Name.ToLowerInvariant() -eq $wanted -and $_.FullName.Replace('/','\').ToLowerInvariant() -match '(?:^|\\)classes\\suspensions\\[^\\]+\.xml$' })
            if($matches.Count -eq 0){$inheritedTypes += [string]$type; continue}
            if($matches.Count -ne 1){throw "RC3.7 suspension safety stop: compatible suspension family '$type' matched $($matches.Count) XML entries; expected exactly 1. No modifications were made."}
            $rr=New-Object IO.StreamReader($matches[0].Open(),[Text.Encoding]::UTF8,$true); try{$fx=$rr.ReadToEnd()}finally{$rr.Dispose()}
            # Count named suspension variants for Preview/safety. SnowRunner suspension-family XMLs expose variants as named elements.
            $variantNames=@([regex]::Matches($fx,'(?is)<(?:Suspension|SuspensionSet)\b[^>]*\bName="([^"]+)"') | ForEach-Object {$_.Groups[1].Value} | Select-Object -Unique)
            if($variantNames.Count -lt 1){
                # Some families use a different wrapper; fall back to unique Name attributes in the family rather than failing a valid stock family.
                $variantNames=@([regex]::Matches($fx,'(?i)\bName="([^"]+)"') | ForEach-Object {$_.Groups[1].Value} | Select-Object -Unique)
            }
            if($variantNames.Count -lt 1){throw "RC3.7 suspension safety stop: compatible suspension family '$type' contains no named variants. No modifications were made."}
            if($variantNames -contains $def){$defaultHits++}
            $plans += [pscustomobject]@{Type=[string]$type;SourceEntry=[string]$matches[0].FullName;VariantCount=[int]$variantNames.Count;VariantNames=[string[]]$variantNames}
        }
        # Default can be inherited/aliased in some stock families, so require it only when it is directly named somewhere if discoverable.
        return [pscustomobject]@{Default=[string]$def;Types=[string[]]@($plans | ForEach-Object {[string]$_.Type});Families=[object[]]$plans;InheritedTypes=[string[]]$inheritedTypes;DefaultHits=[int]$defaultHits}
    } finally {if(-not $usePlannerCache -and $zip){$zip.Dispose()};if($input){$input.Dispose()}}
}

function Get-IndividualWinchPlan([string]$PakPath,[string]$TruckEntry,[string]$TruckId) {
    $input=$null; $zip=$null; $usePlannerCache=$false
    try {
        $fullPak=[IO.Path]::GetFullPath([string]$PakPath)
        if($script:WLCategoryPlannerZip -and $script:WLCategoryPlannerPakPath -and $fullPak.Equals([string]$script:WLCategoryPlannerPakPath,[StringComparison]::OrdinalIgnoreCase)){
            $zip=$script:WLCategoryPlannerZip; $usePlannerCache=$true
        } else {
            $input=[IO.File]::OpenRead($PakPath); $zip=New-Object IO.Compression.ZipArchive($input,[IO.Compression.ZipArchiveMode]::Read)
        }
        $truck=$zip.Entries | Where-Object { $_.FullName.Replace('/','\').Equals($TruckEntry.Replace('/','\'),[StringComparison]::OrdinalIgnoreCase) } | Select-Object -First 1
        if(-not $truck){throw 'TEST 6.20.4 winch safety stop: selected truck XML could not be reopened.'}
        $reader=New-Object IO.StreamReader($truck.Open(),[Text.Encoding]::UTF8,$true); try{$text=$reader.ReadToEnd()}finally{$reader.Dispose()}
        $m=[regex]::Match($text,'(?is)<WinchUpgradeSocket\b(?=[^>]*\bDefault="([^"]+)")(?=[^>]*\bType="([^"]+)")[^>]*/?>')
        if(-not $m.Success){throw 'TEST 6.20.4 winch safety stop: WinchUpgradeSocket Default/Type could not be resolved.'}
        $def=$m.Groups[1].Value; $type=$m.Groups[2].Value; $wanted=($type+'.xml').ToLowerInvariant()
        $matches=@($zip.Entries | Where-Object { $_.Name.ToLowerInvariant() -eq $wanted -and $_.FullName.Replace('/','\').ToLowerInvariant() -match '(?:^|\\)classes\\winches\\[^\\]+\.xml$' })
        # DEV23: a third-party truck may legally reference a vanilla/base-game winch family
        # without carrying that family XML inside its own PAK. Zero local matches is therefore
        # an inherited component, not archive corruption. Skip only the winch tuning for this
        # mod target; NEVER reach into global initial.pak on behalf of a [MOD] target.
        if($matches.Count -eq 0){
            return [pscustomobject]@{Default=$def;Type=$type;SourceEntry='';Inherited=$true}
        }
        if($matches.Count -ne 1){throw "DEV23 winch safety stop: winch family '$type' matched $($matches.Count) local XML entries; expected at most 1. Multiple matches are ambiguous."}
        return [pscustomobject]@{Default=$def;Type=$type;SourceEntry=$matches[0].FullName;Inherited=$false}
    } finally {if(-not $usePlannerCache -and $zip){$zip.Dispose()};if($input){$input.Dispose()}}
}

function Get-ServiceEquipmentDiagnostic([string]$PakPath,[string]$TruckEntry) {
    $input=$null; $zip=$null; $usePlannerCache=$false
    try {
        $fullPak=[IO.Path]::GetFullPath([string]$PakPath)
        if($script:WLCategoryPlannerZip -and $script:WLCategoryPlannerPakPath -and $fullPak.Equals([string]$script:WLCategoryPlannerPakPath,[StringComparison]::OrdinalIgnoreCase)){
            $zip=$script:WLCategoryPlannerZip; $usePlannerCache=$true
        } else {
            $input=[IO.File]::OpenRead($PakPath); $zip=New-Object IO.Compression.ZipArchive($input,[IO.Compression.ZipArchiveMode]::Read)
        }
        $truck=$zip.Entries | Where-Object { $_.FullName.Replace('/','\').Equals($TruckEntry.Replace('/','\'),[StringComparison]::OrdinalIgnoreCase) } | Select-Object -First 1
        if(-not $truck){throw 'TEST 6.25.1 diagnostic safety stop: selected truck XML was not found.'}
        $r=New-Object IO.StreamReader($truck.Open(),[Text.Encoding]::UTF8,$true); try{$text=$r.ReadToEnd()}finally{$r.Dispose()}
        $socketLines=New-Object 'System.Collections.Generic.List[string]'
        foreach($m in [regex]::Matches($text,'(?is)<AddonSocket\b[^>]*>')){$tag=([regex]::Replace($m.Value,'\s+',' ')).Trim();if($tag.Length -gt 220){$tag=$tag.Substring(0,220)+'...'};[void]$socketLines.Add($tag)}
        $nameTokens=New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
        foreach($m in [regex]::Matches($text,'(?i)\bNames(?:Block|Shift)?="([^"]+)"')){foreach($n in ($m.Groups[1].Value -split '[,;\s]+')){if($n){[void]$nameTokens.Add($n.Trim())}}}
        $service=New-Object 'System.Collections.Generic.List[string]'
        foreach($e in $zip.Entries){
            $ep=$e.FullName.Replace('/','\'); if($ep -notmatch '(?i)(?:^|\\)classes\\trucks\\.*\.xml$'){continue}
            $rr=New-Object IO.StreamReader($e.Open(),[Text.Encoding]::UTF8,$true); try{$x=$rr.ReadToEnd()}finally{$rr.Dispose()}
            if($x -notmatch '(?i)\b(?:FuelCapacity|WaterCapacity|RepairsCapacity|WheelRepairsCapacity)\s*='){continue}
            $base=[IO.Path]::GetFileNameWithoutExtension($e.Name); $attrs=@()
            foreach($a in @('FuelCapacity','WaterCapacity','RepairsCapacity','WheelRepairsCapacity')){$am=[regex]::Match($x,('(?i)\b'+$a+'\s*=\s*"([^"]+)"'));if($am.Success){$attrs+=($a+'='+$am.Groups[1].Value)}}
            $ref='not direct-matched';if($nameTokens.Contains($base)){$ref='DIRECT-NAME-MATCH'}
            [void]$service.Add(($base+' ['+($attrs -join ', ')+'] - '+$ref))
        }
        $o=New-Object Text.StringBuilder
        [void]$o.AppendLine('TEST 6.25.1 SERVICE EQUIPMENT DIAGNOSTIC');[void]$o.AppendLine('')
        [void]$o.AppendLine(('Truck entry: '+$TruckEntry));[void]$o.AppendLine(('AddonSocket tags found: '+$socketLines.Count));[void]$o.AppendLine(('Names/NamesBlock/NamesShift tokens: '+$nameTokens.Count));[void]$o.AppendLine(('Service-capacity addon XMLs in archive: '+$service.Count));[void]$o.AppendLine('')
        [void]$o.AppendLine('ADDON SOCKETS ON SELECTED TRUCK:');if($socketLines.Count -eq 0){[void]$o.AppendLine('  (none found)')}else{foreach($v in $socketLines | Select-Object -First 10){[void]$o.AppendLine(('  '+$v))}}
        [void]$o.AppendLine('');[void]$o.AppendLine('SERVICE ADDON CANDIDATES:');if($service.Count -eq 0){[void]$o.AppendLine('  (none found)')}else{foreach($v in $service | Select-Object -First 18){[void]$o.AppendLine(('  '+$v))}}
        if($service.Count -gt 18){[void]$o.AppendLine(('  ... '+($service.Count-18)+' more'))};[void]$o.AppendLine('');[void]$o.AppendLine('No diagnostic TXT file was written to the Desktop.');return $o.ToString()
    } finally {if(-not $usePlannerCache -and $zip){$zip.Dispose()};if($input){$input.Dispose()}}
}

function Get-IndividualServiceAddonEntries([string]$PakPath,[string]$TruckEntry) {
    $input=$null; $zip=$null; $usePlannerCache=$false
    try {
        $fullPak=[IO.Path]::GetFullPath([string]$PakPath)
        if($script:WLCategoryPlannerZip -and $script:WLCategoryPlannerPakPath -and $fullPak.Equals([string]$script:WLCategoryPlannerPakPath,[StringComparison]::OrdinalIgnoreCase)){
            $zip=$script:WLCategoryPlannerZip; $usePlannerCache=$true
        } else {
            $input=[IO.File]::OpenRead($PakPath)
            $zip=New-Object IO.Compression.ZipArchive($input,[IO.Compression.ZipArchiveMode]::Read)
        }
        $truck=$zip.Entries | Where-Object { $_.FullName.Replace('/','\').Equals($TruckEntry.Replace('/','\'),[StringComparison]::OrdinalIgnoreCase) } | Select-Object -First 1
        if(-not $truck){throw 'TEST 6.25.5 service-equipment safety stop: selected truck XML was not found.'}
        $r=New-Object IO.StreamReader($truck.Open(),[Text.Encoding]::UTF8,$true); try{$text=$r.ReadToEnd()}finally{$r.Dispose()}

        # DEV42: SnowRunner's selected-truck socket vocabulary is spread across Names, NamesBlock,
        # and NamesShift attributes. Resolve all three token sets, then exact-match InstallSocket Type.
        # Capacity equipment may live under addons/, *_tuning/, tuning/, custom addon folders, etc.;
        # discover by service-capacity XML semantics + compatible socket, never by filename alone.
        $socketNames=New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
        foreach($m in [regex]::Matches($text,'(?i)\bNames(?:Block|Shift)?="([^"]+)"')){
            foreach($n in ($m.Groups[1].Value -split '[,;\s]+')){
                $v=$n.Trim(); if($v){[void]$socketNames.Add($v)}
            }
        }
        if($socketNames.Count -eq 0){throw 'TEST 6.25.5 service-equipment safety stop: selected truck exposes no addon Socket Names identifiers.'}

        $hits=New-Object 'System.Collections.Generic.List[string]'
        foreach($e in $zip.Entries){
            $ep=$e.FullName.Replace('/','\')
            if($ep -notmatch '(?i)(?:^|\\)classes\\trucks\\.*\.xml$'){continue}
            $rr=New-Object IO.StreamReader($e.Open(),[Text.Encoding]::UTF8,$true); try{$x=$rr.ReadToEnd()}finally{$rr.Dispose()}
            if($x -notmatch '(?i)\b(?:FuelCapacity|WaterCapacity|RepairsCapacity|WheelRepairsCapacity)\s*='){continue}

            $compatible=$false
            foreach($im in [regex]::Matches($x,'(?is)<InstallSocket\b[^>]*\bType\s*=\s*"([^"]+)"[^>]*/?>')){
                foreach($t in ($im.Groups[1].Value -split '[,;\s]+')){
                    $tv=$t.Trim()
                    if($tv -and $socketNames.Contains($tv)){$compatible=$true;break}
                }
                if($compatible){break}
            }
            if($compatible){[void]$hits.Add($e.FullName)}
        }
        return @($hits)
    } finally {if(-not $usePlannerCache -and $zip){$zip.Dispose()}; if($input){$input.Dispose()}}
}


function Get-FuelAddonDiagnostic([string]$PakPath,[string]$TruckEntry) {
    $input=$null; $zip=$null; $usePlannerCache=$false
    try {
        $fullPak=[IO.Path]::GetFullPath([string]$PakPath)
        if($script:WLCategoryPlannerZip -and $script:WLCategoryPlannerPakPath -and $fullPak.Equals([string]$script:WLCategoryPlannerPakPath,[StringComparison]::OrdinalIgnoreCase)){
            $zip=$script:WLCategoryPlannerZip; $usePlannerCache=$true
        } else {
            $input=[IO.File]::OpenRead($PakPath)
            $zip=New-Object IO.Compression.ZipArchive($input,[IO.Compression.ZipArchiveMode]::Read)
        }
        $truck=$zip.Entries | Where-Object { $_.FullName.Replace('/','\').Equals($TruckEntry.Replace('/','\'),[StringComparison]::OrdinalIgnoreCase) } | Select-Object -First 1
        if(-not $truck){throw 'TEST 6.25.6 diagnostic safety stop: selected truck XML was not found.'}
        $r=New-Object IO.StreamReader($truck.Open(),[Text.Encoding]::UTF8,$true); try{$text=$r.ReadToEnd()}finally{$r.Dispose()}
        $socketNames=New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
        foreach($m in [regex]::Matches($text,'(?i)\bNames(?:Block|Shift)?="([^"]+)"')){
            foreach($n in ($m.Groups[1].Value -split '[,;\s]+')){ $v=$n.Trim(); if($v){[void]$socketNames.Add($v)} }
        }

        $hits=New-Object 'System.Collections.Generic.List[string]'
        $capacityRows=New-Object 'System.Collections.Generic.List[string]'
        foreach($e in $zip.Entries){
            $ep=$e.FullName.Replace('/','\')
            if($ep -notmatch '(?i)(?:^|\\)classes\\trucks\\addons\\[^\\]+\.xml$'){continue}
            $rr=New-Object IO.StreamReader($e.Open(),[Text.Encoding]::UTF8,$true); try{$x=$rr.ReadToEnd()}finally{$rr.Dispose()}
            $base=[IO.Path]::GetFileNameWithoutExtension($e.Name)
            $types=@()
            foreach($im in [regex]::Matches($x,'(?is)<InstallSocket\b[^>]*\bType\s*=\s*"([^"]+)"[^>]*/?>')){
                foreach($t in ($im.Groups[1].Value -split '[,;\s]+')){if($t.Trim()){$types += $t.Trim()}}
            }
            $matched=@($types | Where-Object {$socketNames.Contains($_)} | Select-Object -Unique)
            $state=if($matched.Count){'MATCH='+($matched -join ',')}else{'UNMATCHED'}

            # Show any literal 9000/2000/1800 occurrence with local XML context. This catches non-FuelCapacity tank systems.
            if($x -match '(?i)(9000|2000|1800)'){
                foreach($m in [regex]::Matches($x,'(?is).{0,90}(?:9000|2000|1800).{0,120}')){
                    $ctx=($m.Value -replace '[\r\n\t]+',' ' -replace '\s{2,}',' ').Trim()
                    if($ctx.Length -gt 230){$ctx=$ctx.Substring(0,230)}
                    [void]$hits.Add(('  '+$base+' | '+$state+' | InstallSocket='+($types -join ',')+' | '+$ctx))
                    break
                }
            }

            # Enumerate every capacity/volume/fluid/cargo/tank-related numeric attribute so we can identify the 9000-L display source.
            $attrs=New-Object 'System.Collections.Generic.List[string]'
            foreach($am in [regex]::Matches($x,'(?i)\b([A-Za-z0-9_]*(?:Capacity|Volume|Fuel|Fluid|Cargo|Tank)[A-Za-z0-9_]*)\s*=\s*"([^"]+)"')){
                $pair=$am.Groups[1].Value+'='+$am.Groups[2].Value
                if(-not $attrs.Contains($pair)){[void]$attrs.Add($pair)}
            }
            if($attrs.Count){[void]$capacityRows.Add(('  '+$base+' | '+$state+' | '+($attrs -join '; ')))}
        }

        $o=New-Object Text.StringBuilder
        [void]$o.AppendLine('TEST 6.25.6 TANK / FLUID CAPACITY DIAGNOSTIC');[void]$o.AppendLine('')
        [void]$o.AppendLine(('Truck entry: '+$TruckEntry))
        [void]$o.AppendLine(('Selected-truck socket tokens: '+$socketNames.Count));[void]$o.AppendLine('')
        [void]$o.AppendLine('KNOWN IN-GAME US CAPACITY FINGERPRINTS:')
        [void]$o.AppendLine('  2378 gal ~= 9000 L')
        [void]$o.AppendLine('   529 gal ~= 2000 L')
        [void]$o.AppendLine('   476 gal ~= 1800 L');[void]$o.AppendLine('')
        [void]$o.AppendLine('ADDON XMLs CONTAINING LITERAL 9000 / 2000 / 1800 (with context):')
        if($hits.Count -eq 0){[void]$o.AppendLine('  (none)')} else {foreach($v in $hits | Select-Object -First 35){[void]$o.AppendLine($v)}; if($hits.Count -gt 35){[void]$o.AppendLine(('  ... '+($hits.Count-35)+' more'))}}
        [void]$o.AppendLine('');[void]$o.AppendLine('CAPACITY / VOLUME / FLUID / CARGO / TANK ATTRIBUTES (first 45 addon XMLs):')
        foreach($v in $capacityRows | Select-Object -First 45){[void]$o.AppendLine($v)}
        if($capacityRows.Count -gt 45){[void]$o.AppendLine(('  ... '+($capacityRows.Count-45)+' more'))}
        [void]$o.AppendLine('');[void]$o.AppendLine('Goal: identify the XML mechanism behind the 2378-gal Fuel Tank and distinguish service FuelCapacity from fluid/cargo tank capacity.')
        [void]$o.AppendLine('Diagnostic only. No diagnostic TXT file was written to the Desktop.')
        return $o.ToString()
    } finally { if($zip){$zip.Dispose()}; if($input){$input.Dispose()} }
}

function Get-IndividualCraneAddonEntries([string]$PakPath,[string]$TruckEntry) {
    $input=$null; $zip=$null; $usePlannerCache=$false
    try {
        $fullPak=[IO.Path]::GetFullPath([string]$PakPath)
        if($script:WLCategoryPlannerZip -and $script:WLCategoryPlannerPakPath -and $fullPak.Equals([string]$script:WLCategoryPlannerPakPath,[StringComparison]::OrdinalIgnoreCase)){
            $zip=$script:WLCategoryPlannerZip; $usePlannerCache=$true
        } else {
            $input=[IO.File]::OpenRead($PakPath)
            $zip=New-Object IO.Compression.ZipArchive($input,[IO.Compression.ZipArchiveMode]::Read)
        }
        $truck=$zip.Entries | Where-Object { $_.FullName.Replace('/','\').Equals($TruckEntry.Replace('/','\'),[StringComparison]::OrdinalIgnoreCase) } | Select-Object -First 1
        if(-not $truck){throw 'TEST 6.26.2 crane safety stop: selected truck XML was not found.'}
        $r=New-Object IO.StreamReader($truck.Open(),[Text.Encoding]::UTF8,$true); try{$text=$r.ReadToEnd()}finally{$r.Dispose()}
        $socketNames=New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
        foreach($m in [regex]::Matches($text,'(?i)\bNames(?:Block|Shift)?="([^"]+)"')){
            foreach($n in ($m.Groups[1].Value -split '[,;\s]+')){$v=$n.Trim();if($v){[void]$socketNames.Add($v)}}
        }
        if($socketNames.Count -eq 0){throw 'TEST 6.26.2 crane safety stop: selected truck exposes no addon socket identifiers.'}
        $hits=New-Object 'System.Collections.Generic.List[string]'
        foreach($e in $zip.Entries){
            # DEV41: third-party cranes are not required to live under classes/trucks/addons/
            # and their filenames are not required to contain crane/loglift. Discover any mod-local
            # truck XML that explicitly declares a Crane/LogCrane AddonType, then require its
            # InstallSocket Type to match a socket exposed by the selected truck. This keeps
            # discovery relationship-based rather than filename/vendor-specific.
            $ep=$e.FullName.Replace('/','\')
            if($ep -notmatch '(?i)(?:^|\\)classes\\trucks\\.+\.xml$'){continue}
            $rr=New-Object IO.StreamReader($e.Open(),[Text.Encoding]::UTF8,$true);try{$x=$rr.ReadToEnd()}finally{$rr.Dispose()}
            if($x -notmatch '(?is)<AddonType\b[^>]*\bName\s*=\s*"(?:Crane|LogCrane)"[^>]*/?>'){continue}
            $compatible=$false
            foreach($im in [regex]::Matches($x,'(?is)<InstallSocket\b[^>]*\bType\s*=\s*"([^"]+)"[^>]*/?>')){
                foreach($t in ($im.Groups[1].Value -split '[,;\s]+')){$tv=$t.Trim();if($tv -and $socketNames.Contains($tv)){$compatible=$true;break}}
                if($compatible){break}
            }
            if($compatible){[void]$hits.Add($e.FullName)}
        }
        return @($hits)
    } finally {if(-not $usePlannerCache -and $zip){$zip.Dispose()};if($input){$input.Dispose()}}
}

function Get-ControlledMechanicalConstraintNames([string]$Text) {
    $names = New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
    foreach($block in [regex]::Matches($Text,'(?is)<ControlledConstraints\b[^>]*>(.*?)</ControlledConstraints>')) {
        foreach($cm in [regex]::Matches($block.Groups[1].Value,'(?is)<Constraint\b[^>]*\bBelongToCategorie="(?:crane_control|tow_control)"[^>]*/?>')) {
            $nm=[regex]::Match($cm.Value,'(?i)\bName="([^"]+)"')
            if($nm.Success -and $nm.Groups[1].Value){[void]$names.Add($nm.Groups[1].Value)}
        }
    }
    return $names
}

function Replace-ControlledConstraintMotorForce([string]$Text,[double]$Multiplier,$Counts) {
    if([math]::Abs($Multiplier-1.0) -lt 0.0000001){return $Text}
    $names=Get-ControlledMechanicalConstraintNames $Text
    if($names.Count -eq 0){return $Text}
    $edits=New-Object 'System.Collections.Generic.List[object]'
    foreach($cm in [regex]::Matches($Text,'(?is)<Constraint\b[^>]*\bName="([^"]+)"[^>]*>.*?</Constraint>')) {
        if(-not $names.Contains($cm.Groups[1].Value)){continue}
        foreach($mm in [regex]::Matches($cm.Value,'(?is)<Motor\b[^>]*\bForce="(-?(?:\d+(?:\.\d+)?|\.\d+))"[^>]*\bType="Position"[^>]*/?>')) {
            $fm=[regex]::Match($mm.Value,'(?i)\bForce="(-?(?:\d+(?:\.\d+)?|\.\d+))"')
            if(-not $fm.Success){continue}
            $old=[double]::Parse($fm.Groups[1].Value,[Globalization.CultureInfo]::InvariantCulture)
            $new=Format-Number ($old*$Multiplier)
            $absolute=$cm.Index+$mm.Index+$fm.Groups[1].Index
            [void]$edits.Add([pscustomobject]@{Index=$absolute;Length=$fm.Groups[1].Length;Value=$new})
        }
    }
    for($i=$edits.Count-1;$i -ge 0;$i--){$e=$edits[$i];$Text=$Text.Remove($e.Index,$e.Length).Insert($e.Index,$e.Value)}
    if($edits.Count -gt 0){Add-Count $Counts 'Mechanical strength (controlled Position motors)' $edits.Count}
    return $Text
}

function Replace-ControlledConstraintSpeed([string]$Text,[double]$Multiplier,$Counts) {
    if([math]::Abs($Multiplier-1.0) -lt 0.0000001){return $Text}
    if($Multiplier -le 0){throw 'RC5.2 mechanical speed safety stop: speed multiplier must be greater than zero.'}

    # RC5.2 EXPERIMENTAL: ControlledConstraints without an explicit SpeedMult use the game's
    # stock/default control speed.  For crane/tow controls only, materialize that stock default
    # as SpeedMult=1 and then apply the requested multiplier. Existing SpeedMult values are still
    # multiplied in place. This is required by CAT TH357 Shaft/Fork: Crane has SpeedMult=.5,
    # while Shaft and Fork intentionally omit the attribute.
    $existing=0
    $materialized=0
    $pattern='(?is)<Constraint\b[^>]*\bBelongToCategorie="(?:crane_control|tow_control)"[^>]*/?>'
    $Text=[regex]::Replace($Text,$pattern,{param($m)
        $tag=$m.Value
        $sm=[regex]::Match($tag,'(?i)\bSpeedMult="(-?(?:\d+(?:\.\d+)?|\.\d+))"')
        if($sm.Success){
            $old=[double]::Parse($sm.Groups[1].Value,[Globalization.CultureInfo]::InvariantCulture)
            $new=Format-Number ($old*$Multiplier)
            $script:RC52ExistingSpeedCount++
            return $tag.Remove($sm.Groups[1].Index,$sm.Groups[1].Length).Insert($sm.Groups[1].Index,$new)
        }
        # No SpeedMult in stock XML: default is 1.0; inject only on an already controlled
        # crane/tow Constraint. Never inject on physics Constraint/Motor elements.
        $new=Format-Number $Multiplier
        $script:RC52MaterializedSpeedCount++
        if($tag -match '/>\s*$'){ return [regex]::Replace($tag,'/>\s*$',(' SpeedMult="'+$new+'"/>')) }
        return $tag
    })
    $existing=[int]$script:RC52ExistingSpeedCount
    $materialized=[int]$script:RC52MaterializedSpeedCount
    $script:RC52ExistingSpeedCount=0
    $script:RC52MaterializedSpeedCount=0
    if($existing -gt 0){Add-Count $Counts 'Mechanical speed (existing ControlledConstraints SpeedMult)' $existing}
    if($materialized -gt 0){Add-Count $Counts 'Mechanical speed (stock-default SpeedMult materialized)' $materialized}
    return $Text
}

function Replace-CraneHingeMotorForce([string]$Text,[double]$Multiplier,$Counts) {
    if([math]::Abs($Multiplier-1.0) -lt 0.0000001){return $Text}
    $matches=[regex]::Matches($Text,'(?is)<Motor\b[^>]*/?>')
    $edits=New-Object 'System.Collections.Generic.List[object]'
    foreach($mm in $matches){
        $fm=[regex]::Match($mm.Value,'(?i)\bForce="(-?\d+(?:\.\d+)?)"')
        if(-not $fm.Success){continue}
        # Use the same nearest-context rule that produced the successful TEST 6.26.2 motor map.
        $start=[Math]::Max(0,$mm.Index-220); $len=[Math]::Min(220,$mm.Index-$start); $before=$Text.Substring($start,$len)
        $cm=[regex]::Matches($before,'(?is)<(?:Mechanism|Constraint|Body)\b[^>]*(?:Name|Type|BodyFrame|ModelFrame)="([^"]+)"[^>]*>')
        if($cm.Count -eq 0 -or $cm[$cm.Count-1].Groups[1].Value -ne 'Hinge'){continue}
        $old=[double]::Parse($fm.Groups[1].Value,[Globalization.CultureInfo]::InvariantCulture)
        $new=Format-Number ($old*$Multiplier)
        $absolute=$mm.Index+$fm.Groups[1].Index
        [void]$edits.Add([pscustomobject]@{Index=$absolute;Length=$fm.Groups[1].Length;Value=$new})
    }
    for($i=$edits.Count-1;$i -ge 0;$i--){$e=$edits[$i];$Text=$Text.Remove($e.Index,$e.Length).Insert($e.Index,$e.Value)}
    if($edits.Count -gt 0){Add-Count $Counts 'Crane lifting strength (Hinge Position motors only)' $edits.Count}
    return $Text
}

function Replace-CraneControlledIKSpeed([string]$Text,[double]$Multiplier,$Counts) {
    if([math]::Abs($Multiplier-1.0) -lt 0.0000001){return $Text}
    if($Multiplier -le 0){throw 'TEST 6.26.7 crane speed safety stop: speed multiplier must be greater than zero.'}
    # TEST 6.26.7: crane end-effector movement speed is exposed on <ControlledIK>.
    # SnowRunner crane XML commonly uses leading-decimal values such as .65/.5/.8/.6.
    # Accept both normal decimals (1.0) and leading decimals (.65) so ALL compatible cranes are reached.
    # Do NOT touch Motor Tau, Force, Constraint SpeedMult, or any other physics/control value here.
    $tags=[regex]::Matches($Text,'(?is)<ControlledIK\b[^>]*>')
    $edits=New-Object 'System.Collections.Generic.List[object]'
    foreach($tag in $tags){
        foreach($am in [regex]::Matches($tag.Value,'(?i)\b(CoeffEndMovementSpeed[A-Za-z0-9_]*)="(-?(?:\d+(?:\.\d+)?|\.\d+))"')){
            $old=[double]::Parse($am.Groups[2].Value,[Globalization.CultureInfo]::InvariantCulture)
            $new=Format-Number ($old*$Multiplier)
            $absolute=$tag.Index+$am.Groups[2].Index
            [void]$edits.Add([pscustomobject]@{Index=$absolute;Length=$am.Groups[2].Length;Value=$new})
        }
    }
    for($i=$edits.Count-1;$i -ge 0;$i--){$e=$edits[$i];$Text=$Text.Remove($e.Index,$e.Length).Insert($e.Index,$e.Value)}
    if($edits.Count -gt 0){Add-Count $Counts 'Crane movement speed (ControlledIK coefficients only)' $edits.Count}
    return $Text
}

function Get-CraneMotorDiagnostic([string]$PakPath,[string]$TruckEntry) {
    $input=$null; $zip=$null; $usePlannerCache=$false
    try {
        $fullPak=[IO.Path]::GetFullPath([string]$PakPath)
        if($script:WLCategoryPlannerZip -and $script:WLCategoryPlannerPakPath -and $fullPak.Equals([string]$script:WLCategoryPlannerPakPath,[StringComparison]::OrdinalIgnoreCase)){
            $zip=$script:WLCategoryPlannerZip; $usePlannerCache=$true
        } else {
            $input=[IO.File]::OpenRead($PakPath)
            $zip=New-Object IO.Compression.ZipArchive($input,[IO.Compression.ZipArchiveMode]::Read)
        }
        $truck=$zip.Entries | Where-Object { $_.FullName.Replace('/','\').Equals($TruckEntry.Replace('/','\'),[StringComparison]::OrdinalIgnoreCase) } | Select-Object -First 1
        if(-not $truck){throw 'TEST 6.26.2 crane diagnostic safety stop: selected truck XML was not found.'}
        $r=New-Object IO.StreamReader($truck.Open(),[Text.Encoding]::UTF8,$true); try{$text=$r.ReadToEnd()}finally{$r.Dispose()}
        $socketNames=New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
        foreach($m in [regex]::Matches($text,'(?i)\bNames(?:Block|Shift)?="([^"]+)"')){
            foreach($n in ($m.Groups[1].Value -split '[,;\s]+')){$v=$n.Trim();if($v){[void]$socketNames.Add($v)}}
        }
        $rows=New-Object 'System.Collections.Generic.List[string]'; $cranes=0; $motors=0
        foreach($e in $zip.Entries){
            $ep=$e.FullName.Replace('/','\'); if($ep -notmatch '(?i)(?:^|\\)classes\\trucks\\.+\.xml$'){continue}
            $rr=New-Object IO.StreamReader($e.Open(),[Text.Encoding]::UTF8,$true);try{$x=$rr.ReadToEnd()}finally{$rr.Dispose()}
            $compatible=$false; $install=@()
            foreach($im in [regex]::Matches($x,'(?is)<InstallSocket\b[^>]*\bType\s*=\s*"([^"]+)"[^>]*/?>')){
                foreach($t in ($im.Groups[1].Value -split '[,;\s]+')){$tv=$t.Trim();if($tv){$install+=$tv;if($socketNames.Contains($tv)){$compatible=$true}}}
            }
            if(-not $compatible){continue}; $cranes++
            [void]$rows.Add(('=== '+[IO.Path]::GetFileNameWithoutExtension($e.Name)+' | InstallSocket='+($install -join ',')+' ==='))
            $idx=0
            foreach($mm in [regex]::Matches($x,'(?is)<Motor\b[^>]*/?>')){
                $idx++;$motors++;$tag=$mm.Value
                $attrs=@();foreach($a in @('Name','Type','Force','Tau','MinLimit','MaxLimit','MotorForce','AngVel','Speed','Spring','Damping')){$am=[regex]::Match($tag,('(?i)\b'+$a+'="([^"]+)"'));if($am.Success){$attrs+=($a+'='+$am.Groups[1].Value)}}
                $start=[Math]::Max(0,$mm.Index-220);$len=[Math]::Min(220,$mm.Index-$start);$before=$x.Substring($start,$len)
                $ctx='';$cm=[regex]::Matches($before,'(?is)<(?:Mechanism|Constraint|Body)\b[^>]*(?:Name|Type|BodyFrame|ModelFrame)="([^"]+)"[^>]*>');if($cm.Count -gt 0){$ctx=$cm[$cm.Count-1].Groups[1].Value}
                [void]$rows.Add(('  Motor '+$idx+($(if($ctx){' | context='+$ctx}else{''}))+' | '+($attrs -join ' | ')))
            }
        }
        $o=New-Object Text.StringBuilder
        [void]$o.AppendLine('TEST 6.26.2 CRANE MOTOR DIAGNOSTIC');[void]$o.AppendLine('')
        [void]$o.AppendLine(('Truck entry: '+$TruckEntry));[void]$o.AppendLine(('Selected-truck socket tokens: '+$socketNames.Count));[void]$o.AppendLine(('Compatible crane/loglift XMLs: '+$cranes));[void]$o.AppendLine(('Motor tags mapped: '+$motors));[void]$o.AppendLine('')
        [void]$o.AppendLine('COMPATIBLE CRANE MOTOR MAP:');foreach($v in $rows | Select-Object -First 95){[void]$o.AppendLine($v)};if($rows.Count -gt 95){[void]$o.AppendLine(('... '+($rows.Count-95)+' more rows'))}
        [void]$o.AppendLine('');[void]$o.AppendLine('Diagnostic only: TEST 6.26 broad Motor Force/Tau editing is NOT active here.');[void]$o.AppendLine('No diagnostic TXT file was written to the Desktop.')
        return $o.ToString()
    } finally {if(-not $usePlannerCache -and $zip){$zip.Dispose()};if($input){$input.Dispose()}}
}

function Get-CraneSpeedDiagnostic([string]$PakPath,[string]$TruckEntry) {
    $input=$null; $zip=$null
    try {
        $entries=@(Get-IndividualCraneAddonEntries $PakPath $TruckEntry)
        $wanted=New-Object 'System.Collections.Generic.HashSet[string]' ([StringComparer]::OrdinalIgnoreCase)
        foreach($v in $entries){[void]$wanted.Add($v.Replace('/','\'))}
        $input=[IO.File]::OpenRead($PakPath)
        $zip=New-Object IO.Compression.ZipArchive($input,[IO.Compression.ZipArchiveMode]::Read)
        $rows=New-Object 'System.Collections.Generic.List[string]'
        $cranes=0; $motors=0; $candidateTags=0
        foreach($e in $zip.Entries){
            $ep=$e.FullName.Replace('/','\'); if(-not $wanted.Contains($ep)){continue}
            $cranes++
            $rr=New-Object IO.StreamReader($e.Open(),[Text.Encoding]::UTF8,$true);try{$x=$rr.ReadToEnd()}finally{$rr.Dispose()}
            [void]$rows.Add(('=== '+[IO.Path]::GetFileNameWithoutExtension($e.Name)+' ==='))
            $idx=0
            foreach($mm in [regex]::Matches($x,'(?is)<Motor\b[^>]*/?>')){
                $idx++;$motors++;$tag=$mm.Value
                $attrs=New-Object 'System.Collections.Generic.List[string]'
                foreach($am in [regex]::Matches($tag,'(?i)\b([A-Za-z_][A-Za-z0-9_]*)="([^"]*)"')){[void]$attrs.Add(($am.Groups[1].Value+'='+$am.Groups[2].Value))}
                $start=[Math]::Max(0,$mm.Index-320);$len=[Math]::Min(320,$mm.Index-$start);$before=$x.Substring($start,$len)
                $ctx='';$cm=[regex]::Matches($before,'(?is)<(?:Mechanism|Constraint|Body)\b[^>]*(?:Name|Type|BodyFrame|ModelFrame)="([^"]+)"[^>]*>');if($cm.Count -gt 0){$ctx=$cm[$cm.Count-1].Groups[1].Value}
                [void]$rows.Add(('  Motor '+$idx+($(if($ctx){' | context='+$ctx}else{''}))+' | '+($attrs -join ' | ')))
            }
            [void]$rows.Add('  SPEED/RATE/VELOCITY CANDIDATE TAGS:')
            $local=0
            foreach($tm in [regex]::Matches($x,'(?is)<[A-Za-z_][A-Za-z0-9_]*\b[^>]*(?:Speed|Velocity|Vel|Rate|Tau|Time|Force|Damping|Spring|Limit)[^>]*>')){
                $tag=($tm.Value -replace '\s+',' ').Trim()
                if($tag.Length -gt 300){$tag=$tag.Substring(0,300)+'...'}
                [void]$rows.Add(('    '+$tag));$local++;$candidateTags++
                if($local -ge 24){break}
            }
            if($local -eq 0){[void]$rows.Add('    (none found)')}
        }
        $o=New-Object Text.StringBuilder
        [void]$o.AppendLine('TEST 6.26.4 CRANE SPEED DIAGNOSTIC');[void]$o.AppendLine('')
        [void]$o.AppendLine(('Truck entry: '+$TruckEntry));[void]$o.AppendLine(('Compatible crane/loglift XMLs: '+$cranes));[void]$o.AppendLine(('Motor tags mapped: '+$motors));[void]$o.AppendLine(('Speed/rate/velocity candidate tags sampled: '+$candidateTags));[void]$o.AppendLine('')
        [void]$o.AppendLine('FULL MOTOR ATTRIBUTES + NEARBY SPEED/RATE/VELOCITY CANDIDATES:')
        foreach($v in $rows | Select-Object -First 180){[void]$o.AppendLine($v)}
        if($rows.Count -gt 180){[void]$o.AppendLine(('... '+($rows.Count-180)+' more rows'))}
        [void]$o.AppendLine('');[void]$o.AppendLine('Diagnostic only: Crane Speed makes NO XML edits in TEST 6.26.4. Proven hinge-only Crane Strength remains intact.')
        [void]$o.AppendLine('No diagnostic TXT file was written to the Desktop.')
        return $o.ToString()
    } finally {if(-not $usePlannerCache -and $zip){$zip.Dispose()};if($input){$input.Dispose()}}
}

function Invoke-AllModCompatibilityPreview {
    if (-not $script:ModTruckTargets -or $script:ModTruckTargets.Count -eq 0) {
        throw 'Compatibility scan: no editable mod trucks are loaded. Click Scan Mods first.'
    }
    $labels=@($script:ModTruckTargets.Keys | Sort-Object)
    $rows=New-Object Collections.Generic.List[object]
    $originalSelection=$cmbTruck.SelectedItem
    $i=0
    foreach($label in $labels){
        $i++
        $lblStatus.Text="Compatibility scan $i/$($labels.Count): $label"
        [Windows.Forms.Application]::DoEvents()
        try {
            $cmbTruck.SelectedItem=$label
            [Windows.Forms.Application]::DoEvents()
            $s=Get-Settings
            $r=Process-Pak $s $false
            $skipKeys=@($r.Counts.Keys | Where-Object { [string]$_ -like 'SKIPPED*' })
            $status=if($skipKeys.Count -gt 0){'PASS WITH SKIPS'}else{'PASS'}
            $detail=if($skipKeys.Count -gt 0){$skipKeys -join ' | '}else{''}
            [void]$rows.Add([pscustomobject]@{Status=$status;Truck=$label;Detail=$detail;Files=[int]$r.ModifiedFiles})
        } catch {
            [void]$rows.Add([pscustomobject]@{Status='FAIL';Truck=$label;Detail=$_.Exception.Message;Files=0})
        }
    }
    $cmbTruck.SelectedItem=$script:AllModsPreviewLabel
    [Windows.Forms.Application]::DoEvents()

    $pass=@($rows | Where-Object {$_.Status -eq 'PASS'}).Count
    $skip=@($rows | Where-Object {$_.Status -eq 'PASS WITH SKIPS'}).Count
    $fail=@($rows | Where-Object {$_.Status -eq 'FAIL'}).Count
    $handled=$pass+$skip
    $pct=if($rows.Count -gt 0){[math]::Round((100.0*$handled/$rows.Count),1)}else{0}
    $lines=New-Object Collections.Generic.List[string]
    $lines.Add('WL Simplistic SnowRunner Mod Editor v1.2.0 - MOD COMPATIBILITY REPORT')
    $lines.Add(('Generated: '+(Get-Date)))
    $lines.Add('PREVIEW ONLY - NO LIVE MOD PAKS WERE REPLACED.')
    $lines.Add('')
    $lines.Add(('Mod truck definitions tested: '+$rows.Count))
    $lines.Add(('PASS: '+$pass))
    $lines.Add(('PASS WITH SKIPS: '+$skip+' (safe: unsupported or inherited features remain stock)'))
    $lines.Add(('FAIL: '+$fail))
    $lines.Add(('Safely handled: '+$handled+'/'+$rows.Count+' ('+$pct+'%)'))
    $lines.Add('')
    $lines.Add('FAILURES')
    $lines.Add('========')
    foreach($x in @($rows | Where-Object {$_.Status -eq 'FAIL'})){$lines.Add(('[FAIL] '+$x.Truck));$lines.Add(('  '+$x.Detail));$lines.Add('')}
    $lines.Add('PASS WITH SKIPS')
    $lines.Add('===============')
    foreach($x in @($rows | Where-Object {$_.Status -eq 'PASS WITH SKIPS'})){$lines.Add(('[PASS WITH SKIPS] '+$x.Truck));$lines.Add(('  '+$x.Detail));$lines.Add('')}
    $lines.Add('ALL RESULTS')
    $lines.Add('===========')
    foreach($x in $rows){$lines.Add(('['+$x.Status+'] '+$x.Truck+' | XML files: '+$x.Files));if($x.Detail){$lines.Add(('  '+$x.Detail))}}
    $dir=Join-Path $env:LOCALAPPDATA 'WL Simplistic SnowRunner Mod Editor'
    if(-not(Test-Path -LiteralPath $dir)){New-Item -ItemType Directory -Path $dir -Force | Out-Null}
    $report=Join-Path $dir 'WL-SnowRunner-Mod-Compatibility.txt'
    [IO.File]::WriteAllLines($report,$lines,(New-Object Text.UTF8Encoding($false)))
    return [pscustomobject]@{Rows=$rows;Pass=$pass;Skip=$skip;Fail=$fail;Handled=$handled;Percent=$pct;Report=$report}
}

# CATEGORY PRESERVATION FIX 1 (2026-09-14)
# Category Apply is intentionally calculated from the pristine WL backup so numeric multipliers
# never stack.  However, replacing a selected category truck XML from that pristine source can
# erase an Always Diff Lock that was already present in the CURRENT live PAK from an earlier
# All Trucks/category Apply.  Snapshot the live Always state before a category pass, then restore
# that state onto the completed temporary PAK before it can replace the live file.
function Get-LiveAlwaysDiffTruckEntries([string]$PakPath) {
    $set=@{}
    $fs=$null; $zip=$null
    try {
        $fs=[IO.File]::OpenRead($PakPath)
        $zip=New-Object IO.Compression.ZipArchive($fs,[IO.Compression.ZipArchiveMode]::Read)
        foreach($e in $zip.Entries){
            $key=$e.FullName.Replace('/','\\').ToLowerInvariant()
            if($key -notmatch '(?:^|\\)classes\\trucks\\[^\\]+\.xml$'){continue}
            $r=New-Object IO.StreamReader($e.Open(),[Text.Encoding]::UTF8,$true)
            try{$t=$r.ReadToEnd()}finally{$r.Dispose()}
            if($t -notmatch '(?is)<Truck(?:\s|>)'){continue}
            $td=[regex]::Match($t,'(?is)<TruckData\b[^>]*>')
            if($td.Success -and $td.Value -match '(?i)\bDiffLockType="Always"'){$set[$key]=$true}
        }
    } finally {if($zip){$zip.Dispose()};if($fs){$fs.Dispose()}}
    return $set
}

function Restore-And-Verify-PreservedAlwaysDiff([string]$PakPath,$PreserveSet,$Counts) {
    if(-not $PreserveSet -or $PreserveSet.Count -eq 0){return}
    $utf8=New-Object Text.UTF8Encoding($false)
    $restored=0
    $fs=$null;$zip=$null
    try{
        $fs=[IO.File]::Open($PakPath,[IO.FileMode]::Open,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
        $zip=New-Object IO.Compression.ZipArchive($fs,[IO.Compression.ZipArchiveMode]::Update)
        foreach($e in @($zip.Entries)){
            $key=$e.FullName.Replace('/','\\').ToLowerInvariant()
            if(-not $PreserveSet.ContainsKey($key)){continue}
            $r=New-Object IO.StreamReader($e.Open(),[Text.Encoding]::UTF8,$true)
            try{$t=$r.ReadToEnd()}finally{$r.Dispose()}
            $td=[regex]::Match($t,'(?is)<TruckData\b[^>]*>')
            if(-not $td.Success){throw "CATEGORY PRESERVATION safety stop: preserved truck '$($e.FullName)' has no TruckData tag."}
            if($td.Value -match '(?i)\bDiffLockType="Always"'){continue}
            $tag=$td.Value
            if($tag -match '(?i)\bDiffLockType="[^"]*"'){$nt=[regex]::Replace($tag,'(?i)(\bDiffLockType=")[^"]*(")','${1}Always${2}',1)}
            else{$nt=$tag.Substring(0,$tag.Length-1)+' DiffLockType="Always">'}
            $new=$t.Substring(0,$td.Index)+$nt+$t.Substring($td.Index+$td.Length)
            $name=$e.FullName;$time=$e.LastWriteTime;$e.Delete()
            $ne=$zip.CreateEntry($name,[IO.Compression.CompressionLevel]::Optimal);$ne.LastWriteTime=$time
            $d=$ne.Open();try{$b=$utf8.GetBytes($new);$d.Write($b,0,$b.Length)}finally{$d.Dispose()}
            $restored++
        }
    } finally {if($zip){$zip.Dispose()};if($fs){$fs.Dispose()}}

    # Re-open and prove that a category Apply did not lose even one pre-existing Always diff.
    $missing=New-Object Collections.Generic.List[string]
    $fs=$null;$zip=$null
    try{
        $fs=[IO.File]::OpenRead($PakPath);$zip=New-Object IO.Compression.ZipArchive($fs,[IO.Compression.ZipArchiveMode]::Read)
        foreach($key in @($PreserveSet.Keys)){
            $e=$zip.Entries | Where-Object {$_.FullName.Replace('/','\\').ToLowerInvariant() -eq $key} | Select-Object -First 1
            if(-not $e){$missing.Add($key);continue}
            $r=New-Object IO.StreamReader($e.Open(),[Text.Encoding]::UTF8,$true);try{$t=$r.ReadToEnd()}finally{$r.Dispose()}
            $td=[regex]::Match($t,'(?is)<TruckData\b[^>]*>')
            if(-not $td.Success -or $td.Value -notmatch '(?i)\bDiffLockType="Always"'){$missing.Add($key)}
        }
    } finally {if($zip){$zip.Dispose()};if($fs){$fs.Dispose()}}
    if($missing.Count -gt 0){throw "CATEGORY PRESERVATION safety stop: category Apply would remove Always Diff Lock from $($missing.Count) previously-modified truck(s). Live PAK was NOT replaced. First: $($missing[0])"}
    Add-Count $Counts 'CATEGORY PRESERVED existing Always differential locks' $PreserveSet.Count
    if($restored -gt 0){Add-Count $Counts 'CATEGORY RESTORED Always differential locks protected from revert' $restored}
}

function Process-Pak($S, [bool]$WriteOutput) {
    $categoryPreservedAlwaysDiff = $null
    if ($S.TargetTruck -and $S.TargetTruck -ne 'All Trucks' -and -not $S.TargetTruckId -and -not $S.IsCategoryTarget) {
        throw 'TEST 6.9 safety stop: individual-truck mode has no resolved internal truck ID. No modifications were made.'
    }
    if ($S.IsModTarget) {
        $pak=[IO.Path]::GetFullPath([string]$S.ModPakPath)
        Assert-ModPak $pak ([string]$S.TargetTruckEntry)
        $compat=[pscustomobject]@{Mode='Third-party mod PAK';Truck=[string]$S.TargetTruckId}
        $backup=Initialize-ModBackup $pak ([string]$S.TargetTruckEntry)
        Assert-ModPak $backup ([string]$S.TargetTruckEntry)
    } else {
        Assert-Pak $S.PakPath $true
        $pak=[IO.Path]::GetFullPath($S.PakPath)
        $compat=Test-PakCompatibility $pak
        $backup=Initialize-Backup $pak
        Assert-Pak $backup
    }
    if($WriteOutput -and -not $S.IsModTarget -and $S.CategorySinglePassMode){
        $categoryPreservedAlwaysDiff=Get-LiveAlwaysDiffTruckEntries $pak
    }
    # RC3.8.1 cumulative Individual Apply:
    # - The trusted original backup remains immutable and is used only as the clean baseline/Restore source.
    # - Individual truck Preview/Apply starts from the CURRENT live initial.pak so previously applied
    #   individual trucks remain modified when another truck is applied.
    # - All Trucks mode intentionally continues to rebuild from the untouched original baseline.
    # Initialize-Backup's LastEditorOutputHash record distinguishes our current modified PAK from a
    # genuine SnowRunner/Epic update, preventing an editor-modified PAK from being promoted to backup.
    # DEV5: calculate third-party mod changes from the pristine WL backup.
    # This prevents repeated Apply runs from multiplying already-edited values.
    # v1.2.0L / INDIVIDUAL BASELINE LOCK:
    # Calculate official individual-truck edits from the immutable pristine WL backup too.
    # The current live PAK is preserved as the OUTPUT base below, then only the requested
    # pristine->requested XML delta is merged into it. This makes All Trucks -> Individual
    # and repeated Individual Apply idempotent instead of multiplying already-edited values.
    $sourcePath = $backup
    if ($S.IsModTarget) { Assert-ModPak $sourcePath ([string]$S.TargetTruckEntry) } else { Assert-Pak $sourcePath }
    if ($S.TargetTruckId -and -not $S.CategorySinglePassMode) {
        if (-not $S.IsModTarget) { $S.TargetTruckEntry = Resolve-OfficialTruckEntryPath $sourcePath ([string]$S.TargetTruckId) }
        $serviceChange = ([math]::Abs([double]$S.ServiceFuel-1.0) -ge 0.0000001) -or ([math]::Abs([double]$S.ServiceWater-1.0) -ge 0.0000001) -or ([math]::Abs([double]$S.ServiceRepairs-1.0) -ge 0.0000001) -or ([math]::Abs([double]$S.ServiceWheels-1.0) -ge 0.0000001)
        if($serviceChange){
            try { $S.IndividualServiceAddonEntries = @(Get-IndividualServiceAddonEntries $sourcePath ([string]$S.TargetTruckEntry)) }
            catch {
                if($_.Exception.Message -like '*exposes no addon Socket Names identifiers*'){
                    $S.SkippedUnsupportedServiceEquipment='selected truck exposes no addon Socket Names identifiers'
                    $S.ServiceFuel=1.0; $S.ServiceWater=1.0; $S.ServiceRepairs=1.0; $S.ServiceWheels=1.0
                } else { throw }
            }
        }
        if(([math]::Abs([double]$S.CraneStrength-1.0) -ge 0.0000001) -or ([math]::Abs([double]$S.CraneSpeed-1.0) -ge 0.0000001)){
            try { $S.IndividualCraneAddonEntries = @(Get-IndividualCraneAddonEntries $sourcePath ([string]$S.TargetTruckEntry)) }
            catch {
                if($_.Exception.Message -like '*selected truck exposes no addon socket identifiers*'){
                    # DEV31: crane capability is independent. A truck with no resolvable addon
                    # socket identifiers may still safely accept every other supported edit.
                    $S.SkippedUnsupportedCrane='selected truck exposes no addon socket identifiers'
                    $S.CraneStrength=1.0; $S.CraneSpeed=1.0
                    $S.IndividualCraneAddonEntries=@()
                } else { throw }
            }
        }
        if ($S.TestStockWheelSwap) {
            if(([string]$S.TargetTruckId).ToLowerInvariant() -ne 'freightliner_114sd'){throw 'TEST 6.18 safety stop: select Freightliner 114SD for this controlled experiment.'}
            $testType='wheels_medium_highway_double'
            $fs=[IO.File]::OpenRead($sourcePath); $zz=New-Object IO.Compression.ZipArchive($fs,[IO.Compression.ZipArchiveMode]::Read)
            try {
                $truck=$zz.Entries | Where-Object { $_.FullName.Replace('\','/').Equals(([string]$S.TargetTruckEntry).Replace('\','/'),[StringComparison]::OrdinalIgnoreCase) } | Select-Object -First 1
                $rr=New-Object IO.StreamReader($truck.Open(),[Text.Encoding]::UTF8,$true); try{$tx=$rr.ReadToEnd()}finally{$rr.Dispose()}
                if(-not [regex]::IsMatch($tx,('(?is)<CompatibleWheels\b[^>]*\bType\s*=\s*["'']'+[regex]::Escape($testType)+'["'']'))){throw "TEST 6.18 safety stop: 114SD does not declare '$testType' as CompatibleWheels."}
                $fam=$zz.Entries | Where-Object { $_.FullName.Replace('\','/').ToLowerInvariant().EndsWith(('/classes/wheels/'+$testType.ToLowerInvariant()+'.xml'),[StringComparison]::OrdinalIgnoreCase) } | Select-Object -First 1
                if(-not $fam){throw "TEST 6.18 safety stop: recognized stock family '$testType' was not found."}
                $rr=New-Object IO.StreamReader($fam.Open(),[Text.Encoding]::UTF8,$true); try{$fx=$rr.ReadToEnd()}finally{$rr.Dispose()}
                $tm=[regex]::Match($fx,'(?is)<TruckTire\b[^>]*\bName\s*=\s*"([^"]+)"')
                if(-not $tm.Success){throw "TEST 6.18 safety stop: '$testType' contains no named TruckTire."}
                $S.TestStockWheelSwapType=$testType
                $S.TestStockWheelSwapTire=$tm.Groups[1].Value
            } finally {if($zz){$zz.Dispose()};if($fs){$fs.Dispose()}}
        }
        $engineChange = ([math]::Abs([double]$S.EngineTorque-1.0) -ge 0.0000001) -or ([math]::Abs([double]$S.EngineResponse-1.0) -ge 0.0000001) -or ([math]::Abs([double]$S.EngineFuel-1.0) -ge 0.0000001) -or ([math]::Abs([double]$S.EngineDurability-1.0) -ge 0.0000001)
        if ($engineChange) {
            try { $enginePlan = Get-IndividualEnginePlan $sourcePath ([string]$S.TargetTruckEntry) ([string]$S.TargetTruckId) }
            catch {
                if($_.Exception.Message -like '*EngineSocket Default/Type could not be resolved*'){
                    $S.SkippedUnsupportedEngine='EngineSocket Default/Type could not be resolved'
                    $S.EngineTorque=1.0; $S.EngineResponse=1.0; $S.EngineFuel=1.0; $S.EngineDurability=1.0
                    $enginePlan=$null
                } else { throw }
            }
            if($enginePlan){
            $S.IndividualEngineSourceEntries = @($enginePlan.SourceEntries)
            $S.IndividualEngineSourceEntry = if($S.IndividualEngineSourceEntries.Count -gt 0){[string]$S.IndividualEngineSourceEntries[0]}else{''}
            $S.IndividualEngineDefault = [string]$enginePlan.Default
            $S.IndividualEngineTypes = @($enginePlan.Types)
            $S.IndividualEngineType = if($S.IndividualEngineTypes.Count -gt 0){[string]$S.IndividualEngineTypes[0]}else{''}
            $S.IndividualEnginePrivateName = ''
            $S.SharedEngineType = ($S.IndividualEngineTypes -join ', ')
            # Engine edits are intentionally in-place. Count base trucks that use the same
            # engine family so Preview/Apply can clearly disclose the shared scope.
            if(-not $S.CategoryBatchMode){
            $fsE=[IO.File]::OpenRead($sourcePath); $zzE=New-Object IO.Compression.ZipArchive($fsE,[IO.Compression.ZipArchiveMode]::Read)
            try {
                $users=0
                foreach($te in $zzE.Entries){
                    $nn=$te.FullName.Replace('/','\').ToLowerInvariant()
                    if($nn -notmatch '(?:^|\\)classes\\trucks\\[^\\]+\.xml$'){continue}
                    $rE=New-Object IO.StreamReader($te.Open(),[Text.Encoding]::UTF8,$true); try{$xt=$rE.ReadToEnd()}finally{$rE.Dispose()}
                    $usesFamily=$false
                    $sm=[regex]::Match($xt,'(?is)<EngineSocket\b[^>]*\bType="([^"]+)"')
                    if($sm.Success){$decl=@($sm.Groups[1].Value -split '\s*,\s*' | ForEach-Object {$_.Trim()}); foreach($et in @($S.IndividualEngineTypes)){if($decl -contains [string]$et){$usesFamily=$true;break}}}
                    if($usesFamily){$users++}
                }
                $S.SharedEngineTruckUsers=$users
            } finally {if($zzE){$zzE.Dispose()};if($fsE){$fsE.Dispose()}}
            } else { $S.SharedEngineTruckUsers=0 }
            if(@($enginePlan.InheritedTypes).Count -gt 0){$S.SkippedInheritedEngineTypes=@($enginePlan.InheritedTypes)}
            if(@($enginePlan.SourceEntries).Count -eq 0){$S.EngineTorque=1.0; $S.EngineResponse=1.0; $S.EngineFuel=1.0; $S.EngineDurability=1.0}
            }
        }
        $gearboxChange = ([math]::Abs([double]$S.GearSpeed-1.0)-ge 0.0000001) -or ([math]::Abs([double]$S.GearboxFuel-1.0)-ge 0.0000001) -or ([math]::Abs([double]$S.AwdFuel-1.0)-ge 0.0000001) -or ([math]::Abs([double]$S.IdleFuel-1.0)-ge 0.0000001) -or ([math]::Abs([double]$S.GearboxDurability-1.0)-ge 0.0000001)
        if ($gearboxChange) {
            try { $gearPlan = Get-IndividualGearboxPlan $sourcePath ([string]$S.TargetTruckEntry) ([string]$S.TargetTruckId) }
            catch {
                if($_.Exception.Message -like '*GearboxSocket Default/Type could not be resolved*'){
                    $S.SkippedUnsupportedGearbox='GearboxSocket Default/Type could not be resolved'
                    $S.GearSpeed=1.0; $S.GearboxFuel=1.0; $S.AwdFuel=1.0; $S.IdleFuel=1.0; $S.GearboxDurability=1.0
                    $gearPlan=$null
                } else { throw }
            }
            if($gearPlan){
            $S.IndividualGearboxSourceEntries=@($gearPlan.SourceEntries)
            $S.IndividualGearboxSourceEntry=if($S.IndividualGearboxSourceEntries.Count -gt 0){[string]$S.IndividualGearboxSourceEntries[0]}else{''}
            $S.IndividualGearboxDefault=[string]$gearPlan.Default
            $S.IndividualGearboxType=[string]$gearPlan.Type
            $S.IndividualGearboxPrivateName=''
            $S.SharedGearboxTypes=@($gearPlan.Types)
            $S.SharedGearboxType=[string]$gearPlan.Type
            $S.SharedGearboxDefault=[string]$gearPlan.Default
            if(@($gearPlan.InheritedTypes).Count -gt 0){$S.SkippedInheritedGearboxTypes=@($gearPlan.InheritedTypes)}

            # DEV26: Gear Tuning requires an inline, concrete progression (at least two <Gear>
            # elements with AngVel) in one of the mod-local gearbox families selected for this truck.
            # Some mods expose a valid gearbox through templates/inheritance instead. Those gearboxes
            # may still accept ordinary durability/economy edits, but inventing a progression here
            # would be unsafe. Skip ONLY Gear Tuning and disclose it; never fall through to global data.
            if([math]::Abs([double]$S.GearSpeed-1.0)-ge 0.0000001){
                $tunable=$false
                if(@($S.IndividualGearboxSourceEntries).Count -gt 0){
                    $fg=[IO.File]::OpenRead($sourcePath); $zg=New-Object IO.Compression.ZipArchive($fg,[IO.Compression.ZipArchiveMode]::Read)
                    try {
                        foreach($src in @($S.IndividualGearboxSourceEntries)){
                            $ge=$zg.Entries | Where-Object {$_.FullName.Replace('/','\').Equals(([string]$src).Replace('/','\'),[StringComparison]::OrdinalIgnoreCase)} | Select-Object -First 1
                            if(-not $ge){continue}
                            $rg=New-Object IO.StreamReader($ge.Open(),[Text.Encoding]::UTF8,$true); try{$gt=$rg.ReadToEnd()}finally{$rg.Dispose()}
                            $blocks=[regex]::Matches($gt,'(?is)<Gearbox\b[^>]*\bName="[^"]+"[^>]*>.*?</Gearbox>')
                            foreach($b in $blocks){
                                $angs=[regex]::Matches($b.Value,'(?is)<Gear\b(?=[^>]*\bAngVel="-?\d*\.?\d+")[^>]*/?>').Count
                                if($angs -ge 2){$tunable=$true;break}
                            }
                            if($tunable){break}
                        }
                    } finally {if($zg){$zg.Dispose()};if($fg){$fg.Dispose()}}
                }
                if(-not $tunable){
                    $S.SkippedUnsupportedGearTuning = ('default '+[string]$S.IndividualGearboxDefault+' uses no safe inline gear progression in the mod-local gearbox XML')
                    $S.GearSpeed = 1.0
                }
            }
            # TEST 6.23.1: edit the existing/default gearbox variant in place. Count base
            # trucks that reference this exact Type+Default so Preview discloses scope.
            if(-not $S.CategoryBatchMode){
            $fsG=[IO.File]::OpenRead($sourcePath); $zzG=New-Object IO.Compression.ZipArchive($fsG,[IO.Compression.ZipArchiveMode]::Read)
            try {
                $users=0
                foreach($te in $zzG.Entries){
                    $nn=$te.FullName.Replace('/','\').ToLowerInvariant()
                    if($nn -notmatch '(?:^|\\)classes\\trucks\\[^\\]+\.xml$'){continue}
                    $rG=New-Object IO.StreamReader($te.Open(),[Text.Encoding]::UTF8,$true); try{$xt=$rG.ReadToEnd()}finally{$rG.Dispose()}
                    $gm=[regex]::Match($xt,'(?is)<GearboxSocket\b(?=[^>]*\bDefault="'+[regex]::Escape([string]$S.SharedGearboxDefault)+'")(?=[^>]*\bType="([^"]+)")[^>]*/?>')
                    if($gm.Success){$decl=@($gm.Groups[1].Value -split '\s*,\s*' | ForEach-Object {$_.Trim()});$uses=$false;foreach($gt in @($S.SharedGearboxTypes)){if($decl -contains [string]$gt){$uses=$true;break}};if($uses){$users++}}
                }
                $S.SharedGearboxTruckUsers=$users
            } finally {if($zzG){$zzG.Dispose()};if($fsG){$fsG.Dispose()}}
            } else { $S.SharedGearboxTruckUsers=0 }
            }
        }
        $tireChange = ([math]::Abs([double]$S.TireAsphalt-1.0) -ge 0.0000001) -or ([math]::Abs([double]$S.TireOffroad-1.0) -ge 0.0000001) -or ([math]::Abs([double]$S.TireMud-1.0) -ge 0.0000001) -or ([math]::Abs([double]$S.TireDurability-1.0) -ge 0.0000001) -or [bool]$S.AllTiresIgnoreIce
        if ($tireChange) {
            # TEST 6.18.1: tires deliberately edit the existing shared stock wheel family in-place.
            # Never prepare, clone, repoint, or invent wheel/tire identifiers here.
            $S.IndividualWheelSourceEntry=''
            $S.IndividualWheelType=''
            $S.IndividualWheelPrivateType=''
            $S.IndividualWheelPrivateEntry=''
            try { $tirePlan=Get-IndividualTirePlan $sourcePath ([string]$S.TargetTruckEntry) ([string]$S.TargetTruckId) }
            catch {
                if($_.Exception.Message -like '*DefaultTire/DefaultWheelType could not be resolved*' -or $_.Exception.Message -like '*selected truck has no resolvable <Wheels> tag*'){
                    $S.SkippedUnsupportedTires=$_.Exception.Message
                    $S.TireAsphalt=1.0; $S.TireOffroad=1.0; $S.TireMud=1.0; $S.TireDurability=1.0
                    $tirePlan=$null
                } else { throw }
            }
            if($tirePlan){
            $S.SharedWheelSourceEntry=[string]$tirePlan.SourceEntry
            $S.SharedWheelSourceEntries=@($tirePlan.SourceEntries)
            $S.SharedWheelType=[string]$tirePlan.WheelType
            $S.SharedWheelTypes=@($tirePlan.Types)
            if([bool]$tirePlan.Inherited){
                $S.SkippedInheritedWheelType=[string]$tirePlan.WheelType
                $S.TireAsphalt=1.0; $S.TireOffroad=1.0; $S.TireMud=1.0; $S.TireDurability=1.0
                $S.SharedWheelSourceEntry=''
            }
            # Count base trucks whose DefaultWheelType uses this same family. This is informational only.
            if(-not $S.CategoryBatchMode){
            $fs2=[IO.File]::OpenRead($sourcePath); $zz2=New-Object IO.Compression.ZipArchive($fs2,[IO.Compression.ZipArchiveMode]::Read)
            try {
                $users=0
                foreach($te in $zz2.Entries){
                    $nn=$te.FullName.Replace('/','\').ToLowerInvariant()
                    if($nn -notmatch '(?:^|\\)classes\\trucks\\[^\\]+\.xml$'){continue}
                    $r2=New-Object IO.StreamReader($te.Open(),[Text.Encoding]::UTF8,$true); try{$xt=$r2.ReadToEnd()}finally{$r2.Dispose()}
                    if([regex]::IsMatch($xt,('(?is)<Wheels\b[^>]*\bDefaultWheelType="'+[regex]::Escape([string]$S.SharedWheelType)+'"'))){$users++}
                }
                $S.SharedWheelTruckUsers=$users
            } finally {if($zz2){$zz2.Dispose()};if($fs2){$fs2.Dispose()}}
            } else { $S.SharedWheelTruckUsers=0 }
            }
        }
        $suspChange = ([math]::Abs([double]$S.SuspensionStrength-1.0) -ge 0.0000001) -or ([math]::Abs([double]$S.SuspensionHeight-1.0) -ge 0.0000001) -or ([math]::Abs([double]$S.SuspensionDamping-1.0) -ge 0.0000001) -or ([math]::Abs([double]$S.SuspensionDurability-1.0) -ge 0.0000001)
        if($suspChange){
            try { $sp=Get-IndividualSuspensionPlan $sourcePath ([string]$S.TargetTruckEntry) ([string]$S.TargetTruckId) }
            catch {
                if($_.Exception.Message -like '*SuspensionSocket Default/Type could not be resolved*' -or $_.Exception.Message -like '*contains no named variants*'){
                    # DEV31: an unusual/template-only suspension family blocks only suspension
                    # tuning. Other independently-resolved features remain eligible.
                    $S.SkippedUnsupportedSuspension=$_.Exception.Message
                    $S.SuspensionStrength=1.0; $S.SuspensionHeight=1.0; $S.SuspensionDamping=1.0; $S.SuspensionDurability=1.0
                    $sp=$null
                } else { throw }
            }
            if($sp){
            $S.CompatibleSuspensionFamilies=[object[]]@($sp.Families)
            $S.CompatibleSuspensionTypes=[string[]]@($sp.Types)
            if(@($sp.InheritedTypes).Count -gt 0){$S.SkippedInheritedSuspensionTypes=@($sp.InheritedTypes)}
            if(@($sp.Families).Count -eq 0){$S.SuspensionStrength=1.0; $S.SuspensionHeight=1.0; $S.SuspensionDamping=1.0; $S.SuspensionDurability=1.0}
            if(-not $S.CategoryBatchMode){
            $fs3=[IO.File]::OpenRead($sourcePath); $zz3=New-Object IO.Compression.ZipArchive($fs3,[IO.Compression.ZipArchiveMode]::Read)
            try {
                $users=0
                foreach($te in $zz3.Entries){
                    $nn=$te.FullName.Replace('/','\').ToLowerInvariant()
                    if($nn -notmatch '(?:^|\\)classes\\trucks\\[^\\]+\.xml$'){continue}
                    $r3=New-Object IO.StreamReader($te.Open(),[Text.Encoding]::UTF8,$true); try{$xt=$r3.ReadToEnd()}finally{$r3.Dispose()}
                    $tm=[regex]::Match($xt,'(?is)<SuspensionSocket\b[^>]*\bType="([^"]+)"')
                    if(-not $tm.Success){continue}
                    $tt=@($tm.Groups[1].Value -split '[,;\s]+' | ForEach-Object {$_.Trim()} | Where-Object {$_})
                    if(@($tt | Where-Object {$S.CompatibleSuspensionTypes -contains $_}).Count -gt 0){$users++}
                }
                $S.SharedSuspensionTruckUsers=$users
            } finally {if($zz3){$zz3.Dispose()};if($fs3){$fs3.Dispose()}}
            } else { $S.SharedSuspensionTruckUsers=0 }
            }
        }
        $winchChange = ([math]::Abs([double]$S.WinchStrength-1.0) -ge 0.0000001) -or ([math]::Abs([double]$S.WinchLength-1.0) -ge 0.0000001) -or [bool]$S.AutonomousWinches
        if($winchChange){
            try { $wp=Get-IndividualWinchPlan $sourcePath ([string]$S.TargetTruckEntry) ([string]$S.TargetTruckId) }
            catch {
                if($_.Exception.Message -like '*WinchUpgradeSocket Default/Type could not be resolved*'){
                    # DEV31: unresolved/absent winch socket structure blocks only winch tuning.
                    $S.SkippedUnsupportedWinch='WinchUpgradeSocket Default/Type could not be resolved'
                    $S.WinchStrength=1.0; $S.WinchLength=1.0; $S.AutonomousWinches=$false
                    $wp=$null
                } else { throw }
            }
            if($wp){
                $S.SharedWinchSourceEntry=[string]$wp.SourceEntry
                $S.SharedWinchType=[string]$wp.Type
                if([bool]$wp.Inherited){
                    # Record this in Preview/Apply instead of aborting the entire preset.
                    # The rest of OVERPOWERED can safely apply; this inherited winch remains stock.
                    $S.SkippedInheritedWinchType=[string]$wp.Type
                    $S.SharedWinchTruckUsers=0
                } else {
                    if(-not $S.CategoryBatchMode){
                    $fs4=[IO.File]::OpenRead($sourcePath); $zz4=New-Object IO.Compression.ZipArchive($fs4,[IO.Compression.ZipArchiveMode]::Read)
                    try {
                        $users=0
                        foreach($te in $zz4.Entries){
                            $nn=$te.FullName.Replace('/','\').ToLowerInvariant()
                            if($nn -notmatch '(?:^|\\)classes\\trucks\\[^\\]+\.xml$'){continue}
                            $r4=New-Object IO.StreamReader($te.Open(),[Text.Encoding]::UTF8,$true); try{$xt=$r4.ReadToEnd()}finally{$r4.Dispose()}
                            if([regex]::IsMatch($xt,('(?is)<WinchUpgradeSocket\b[^>]*\bType="'+[regex]::Escape([string]$S.SharedWinchType)+'"'))){$users++}
                        }
                        $S.SharedWinchTruckUsers=$users
                    } finally {if($zz4){$zz4.Dispose()};if($fs4){$fs4.Dispose()}}
                    } else { $S.SharedWinchTruckUsers=0 }
                }
            }
        }
    }
    $counts = @{}
    if($S.SkippedInheritedWinchType){ Add-Count $counts ('SKIPPED inherited winch family '+[string]$S.SkippedInheritedWinchType+' (not local to mod PAK)') 1 }
    if(@($S.SkippedInheritedGearboxTypes).Count -gt 0){ Add-Count $counts ('SKIPPED inherited gearbox families '+(@($S.SkippedInheritedGearboxTypes) -join ', ')+' (not local to mod PAK)') @($S.SkippedInheritedGearboxTypes).Count }
    if($S.SkippedUnsupportedGearTuning){ Add-Count $counts ('SKIPPED Gear Tuning - '+[string]$S.SkippedUnsupportedGearTuning) 1 }
    if(@($S.SkippedInheritedEngineTypes).Count -gt 0){ Add-Count $counts ('SKIPPED inherited engine families '+(@($S.SkippedInheritedEngineTypes) -join ', ')+' (not local to mod PAK)') @($S.SkippedInheritedEngineTypes).Count }
    if($S.SkippedUnsupportedEngine){ Add-Count $counts ('SKIPPED Engine tuning - '+[string]$S.SkippedUnsupportedEngine) 1 }
    if($S.SkippedInheritedWheelType){ Add-Count $counts ('SKIPPED inherited wheel family '+[string]$S.SkippedInheritedWheelType+' (not local to mod PAK)') 1 }
    if($S.SkippedUnsupportedTires){ Add-Count $counts ('SKIPPED Tire tuning - '+[string]$S.SkippedUnsupportedTires) 1 }
    # PERSONAL TEST FIX 2: de-duplicate shared resources across a category batch.
    # The individual-truck planner still resolves each truck normally; only archive
    # entries already changed earlier in THIS SAME category Apply are removed here.
    if($S.CategoryBatchMode -and $S.CategoryBatchSeen){
        $seen=$S.CategoryBatchSeen
        $norm={param($x) ([string]$x).Replace('\\','/').ToLowerInvariant()}

        $keepE=New-Object Collections.Generic.List[string]; $keepET=New-Object Collections.Generic.List[string]
        for($i=0;$i -lt @($S.IndividualEngineSourceEntries).Count;$i++){
            $e=[string]$S.IndividualEngineSourceEntries[$i]; $k=&$norm $e
            if(-not $seen.Engine.ContainsKey($k)){$seen.Engine[$k]=$true;$keepE.Add($e);if($i -lt @($S.IndividualEngineTypes).Count){$keepET.Add([string]$S.IndividualEngineTypes[$i])}}
        }
        $S.IndividualEngineSourceEntries=$keepE.ToArray(); $S.IndividualEngineTypes=$keepET.ToArray()
        if($S.IndividualEngineSourceEntries.Count -eq 0){$S.EngineTorque=1.0;$S.EngineResponse=1.0;$S.EngineFuel=1.0;$S.EngineDurability=1.0}

        $keepG=New-Object Collections.Generic.List[string]
        foreach($e in @($S.IndividualGearboxSourceEntries)){ $k=&$norm $e;if(-not $seen.Gearbox.ContainsKey($k)){$seen.Gearbox[$k]=$true;$keepG.Add([string]$e)} }
        $S.IndividualGearboxSourceEntries=$keepG.ToArray()
        if($S.IndividualGearboxSourceEntries.Count -eq 0){$S.GearSpeed=1.0;$S.GearboxFuel=1.0;$S.AwdFuel=1.0;$S.IdleFuel=1.0;$S.GearboxDurability=1.0}

        if($S.SharedWheelSourceEntry){$k=&$norm $S.SharedWheelSourceEntry;if($seen.Wheel.ContainsKey($k)){$S.SharedWheelSourceEntry='';$S.TireAsphalt=1.0;$S.TireOffroad=1.0;$S.TireMud=1.0;$S.TireDurability=1.0;$S.AllTiresIgnoreIce=$false}else{$seen.Wheel[$k]=$true}}
        if($S.SharedWinchSourceEntry){$k=&$norm $S.SharedWinchSourceEntry;if($seen.Winch.ContainsKey($k)){$S.SharedWinchSourceEntry='';$S.WinchStrength=1.0;$S.WinchLength=1.0;$S.AutonomousWinches=$false}else{$seen.Winch[$k]=$true}}

        $keepS=New-Object Collections.Generic.List[object]
        foreach($f in @($S.CompatibleSuspensionFamilies)){ $k=&$norm $f.SourceEntry;if(-not $seen.Suspension.ContainsKey($k)){$seen.Suspension[$k]=$true;$keepS.Add($f)} }
        $S.CompatibleSuspensionFamilies=$keepS.ToArray()
        if($S.CompatibleSuspensionFamilies.Count -eq 0){$S.SuspensionStrength=1.0;$S.SuspensionHeight=1.0;$S.SuspensionDamping=1.0;$S.SuspensionDurability=1.0}

        $keepSvc=New-Object Collections.Generic.List[string]
        foreach($e in @($S.IndividualServiceAddonEntries)){ $k=&$norm $e;if(-not $seen.Service.ContainsKey($k)){$seen.Service[$k]=$true;$keepSvc.Add([string]$e)} }
        $S.IndividualServiceAddonEntries=$keepSvc.ToArray()
        if($S.IndividualServiceAddonEntries.Count -eq 0){$S.ServiceFuel=1.0;$S.ServiceWater=1.0;$S.ServiceRepairs=1.0;$S.ServiceWheels=1.0}

        $keepCr=New-Object Collections.Generic.List[string]
        foreach($e in @($S.IndividualCraneAddonEntries)){ $k=&$norm $e;if(-not $seen.Crane.ContainsKey($k)){$seen.Crane[$k]=$true;$keepCr.Add([string]$e)} }
        $S.IndividualCraneAddonEntries=$keepCr.ToArray()
        if($S.IndividualCraneAddonEntries.Count -eq 0){$S.CraneStrength=1.0;$S.CraneSpeed=1.0}
    }

    if(@($S.SkippedInheritedSuspensionTypes).Count -gt 0){ Add-Count $counts ('SKIPPED inherited suspension families '+(@($S.SkippedInheritedSuspensionTypes) -join ', ')+' (not local to mod PAK)') @($S.SkippedInheritedSuspensionTypes).Count }
    if($S.SkippedUnsupportedSuspension){ Add-Count $counts ('SKIPPED Suspension tuning - '+[string]$S.SkippedUnsupportedSuspension) 1 }
    if($S.SkippedUnsupportedServiceEquipment){ Add-Count $counts ('SKIPPED Service equipment - '+[string]$S.SkippedUnsupportedServiceEquipment) 1 }
    if($S.SkippedUnsupportedCrane){ Add-Count $counts ('SKIPPED Crane tuning - '+[string]$S.SkippedUnsupportedCrane) 1 }
    if($S.SkippedUnsupportedWinch){ Add-Count $counts ('SKIPPED Winch tuning - '+[string]$S.SkippedUnsupportedWinch) 1 }
    if($S.SkippedUnsupportedGearbox){ Add-Count $counts ('SKIPPED Gearbox tuning - '+[string]$S.SkippedUnsupportedGearbox) 1 }
    $modifiedFiles = 0
    $tempPath = $null
    $input = $null
    $output = $null
    $sourceZip = $null
    $targetZip = $null
    try {
        $input = [IO.File]::OpenRead($sourcePath)
        $sourceZip = New-Object IO.Compression.ZipArchive($input, [IO.Compression.ZipArchiveMode]::Read)
        if ($WriteOutput) {
            $tempPath = Join-Path ([IO.Path]::GetDirectoryName($pak)) ('initial.editor.' + [guid]::NewGuid().ToString('N') + '.tmp')
            if ($S.IsModTarget -or $S.CategoryBatchMode -or ($S.TargetTruckId -and -not $S.IsModTarget)) {
                # PERSONAL TEST CATEGORY SPEED 1:
                # Category mode used to rebuild/recompress the ENTIRE initial.pak once per truck.
                # That made All Scouts take ~5 minutes.  Start each category step as an exact
                # copy of the current working PAK and open it in UPDATE mode instead.  Untouched
                # archive entries remain byte-for-byte in place; only XML entries actually changed
                # for this category step are replaced/recompressed.  The existing atomic swap,
                # backup validation, and batch-wide de-duplication protections remain unchanged.
                # v1.2.0L: official category/individual targets MUST start from the CURRENT live PAK.
                # TEST 8 calculated requested values from the pristine backup correctly, but official
                # single-truck UPDATE mode mistakenly copied $sourcePath (the pristine backup) as the
                # output base. That silently reverted thousands of unrelated All Trucks/category edits.
                # Third-party mod targets intentionally continue to start from their pristine mod backup.
                $copyBase = if($S.IsModTarget){$sourcePath}else{$pak}
                [IO.File]::Copy($copyBase,$tempPath,$false)
                $output = [IO.File]::Open($tempPath,[IO.FileMode]::Open,[IO.FileAccess]::ReadWrite,[IO.FileShare]::None)
                $targetZip = New-Object IO.Compression.ZipArchive($output, [IO.Compression.ZipArchiveMode]::Update)
            } else {
                $output = [IO.File]::Create($tempPath)
                $targetZip = New-Object IO.Compression.ZipArchive($output, [IO.Compression.ZipArchiveMode]::Create)
            }
        }
        $utf8 = New-Object Text.UTF8Encoding($false)
        foreach ($entry in $sourceZip.Entries) {
            $isXml = $entry.FullName.EndsWith('.xml', [StringComparison]::OrdinalIgnoreCase)
            $bytes = $null
            $newText = $null
            $changed = $false
            $entryStream = $entry.Open()
            try {
                $memory = New-Object IO.MemoryStream
                $entryStream.CopyTo($memory)
                $bytes = $memory.ToArray()
                $memory.Dispose()
            } finally { $entryStream.Dispose() }
            if ($isXml) {
                $text = $utf8.GetString($bytes)
                $originalText = $text
                $liveText = $null
                # RC3.9.9: SnowRunner tire grip has two data layers that must stay in sync.
                # 1) [media]/_templates/trucks.xml contains the shared WheelFriction templates.
                # 2) [media]/classes/wheels/*.xml contains wheel/tire-specific friction overrides.
                # Modify ONLY friction attributes that already exist; never inject missing attributes,
                # never change wheel IDs/templates/default tire identities.  The wheel-class layer is
                # still handled by the existing All Trucks / selected compatible-family paths below.
                $entryNorm = $entry.FullName.Replace('\','/').ToLowerInvariant()
                $tireGripRequested = ([math]::Abs([double]$S.TireAsphalt - 1.0) -ge 0.0000001 -or
                                      [math]::Abs([double]$S.TireOffroad - 1.0) -ge 0.0000001 -or
                                      [math]::Abs([double]$S.TireMud - 1.0) -ge 0.0000001)
                if ($tireGripRequested -and $entryNorm -match '(^|/)_templates/trucks\.xml$') {
                    $templateKey=$entryNorm
                    if($S.CategoryBatchMode -and $S.CategoryBatchSeen -and $S.CategoryBatchSeen.Template.ContainsKey($templateKey)){
                        $newText=$text
                    } else {
                        if($S.CategoryBatchMode -and $S.CategoryBatchSeen){$S.CategoryBatchSeen.Template[$templateKey]=$true}
                        $newText = Replace-NumericAttribute $text 'BodyFrictionAsphalt' $S.TireAsphalt $counts 'Tire asphalt grip (trucks.xml templates)'
                        $newText = Replace-NumericAttribute $newText 'BodyFriction' $S.TireOffroad $counts 'Tire off-road grip (trucks.xml templates)'
                        $newText = Replace-NumericAttribute $newText 'SubstanceFriction' $S.TireMud $counts 'Tire mud grip (trucks.xml templates)'
                    }
                } elseif ($S.TargetTruckId -and (($S.SharedWinchSourceEntry -and $entry.FullName.Replace('/', '\').Equals(([string]$S.SharedWinchSourceEntry).Replace('/', '\'), [StringComparison]::OrdinalIgnoreCase)) -or (@($S.SharedWinchSourceEntries | ForEach-Object { ([string]$_).Replace('/', '\').ToLowerInvariant() }) -contains $entry.FullName.Replace('/', '\').ToLowerInvariant()))) {
                    $newText = Replace-NumericAttribute $text 'StrengthMult' $S.WinchStrength $counts 'Winch strength (component family)'
                    $newText = Replace-NumericAttribute $newText 'Length' $S.WinchLength $counts 'Winch length (component family)'
                    if($S.AutonomousWinches){
                        $n=0
                        $newText=[regex]::Replace($newText,'(?i)IsEngineIgnitionRequired="true"',{param($m) $script:n=$script:n+1; 'IsEngineIgnitionRequired="false"'})
                        if($script:n){ Add-Count $counts 'Autonomous winches (component family)' $script:n }; $script:n=0
                    }
                    if($newText -cne $text){ Add-Count $counts ('Winch family '+[string]$S.SharedWinchType+' - base trucks using family') ([int]$S.SharedWinchTruckUsers) }
                } elseif ($S.TargetTruckId -and $S.CompatibleSuspensionFamilies -and (@($S.CompatibleSuspensionFamilies | ForEach-Object { ([string]$_.SourceEntry).Replace('\','/').ToLowerInvariant() }) -contains $entry.FullName.Replace('\','/').ToLowerInvariant())) {
                    $sf=@($S.CompatibleSuspensionFamilies | Where-Object { ([string]$_.SourceEntry).Replace('\','/').Equals($entry.FullName.Replace('\','/'),[StringComparison]::OrdinalIgnoreCase) }) | Select-Object -First 1
                    $newText = Replace-SuspensionTravelAttribute $text 'Strength' $S.SuspensionStrength $counts 'Suspension strength (all compatible suspension variants)'
                    $newText = Replace-NumericAttribute $newText 'Height' $S.SuspensionHeight $counts 'Suspension height (all compatible suspension variants)'
                    $newText = Replace-SuspensionDampingVerified $newText $S.SuspensionDamping $counts 'Suspension damping (all compatible suspension variants)'
                    $newText = Replace-NumericAttribute $newText 'DamageCapacity' $S.SuspensionDurability $counts 'Suspension durability (all compatible suspension variants)'
                    if($newText -cne $text){
                        Add-Count $counts ('Compatible suspension variants - family '+[string]$sf.Type) ([int]$sf.VariantCount)
                        Add-Count $counts ('SHARED compatible suspension families - base trucks using one or more') ([int]$S.SharedSuspensionTruckUsers)
                    }
                } elseif ($S.TargetTruckId -and (($S.SharedWheelSourceEntry -and $entry.FullName.Replace('/', '\').Equals(([string]$S.SharedWheelSourceEntry).Replace('/', '\'), [StringComparison]::OrdinalIgnoreCase)) -or (@($S.SharedWheelSourceEntries | ForEach-Object { ([string]$_).Replace('/', '\').ToLowerInvariant() }) -contains $entry.FullName.Replace('/', '\').ToLowerInvariant()))) {
                    $newText = Replace-NumericAttribute $text 'BodyFrictionAsphalt' $S.TireAsphalt $counts 'Tire asphalt grip (shared wheel family)'
                    $newText = Replace-NumericAttribute $newText 'BodyFriction' $S.TireOffroad $counts 'Tire off-road grip (shared wheel family)'
                    $newText = Replace-NumericAttribute $newText 'SubstanceFriction' $S.TireMud $counts 'Tire mud grip (shared wheel family)'
                    $newText = Replace-NumericAttribute $newText 'DamageCapacity' $S.TireDurability $counts 'Tire durability (shared wheel family)'
                    if ($S.AllTiresIgnoreIce) { $newText = Set-WheelFrictionIgnoreIce $newText $counts 'All tires ignore ice (selected wheel family)' }
                    if($newText -cne $text){
                        Add-Count $counts ('SHARED wheel family '+[string]$S.SharedWheelType+' - base trucks using as default') ([int]$S.SharedWheelTruckUsers)
                    }
                } elseif ($S.TargetTruckId -and @($S.IndividualCraneAddonEntries | ForEach-Object { $_.Replace('\','/').ToLowerInvariant() }) -contains $entry.FullName.Replace('\','/').ToLowerInvariant()) {
                    # DEV41 stabilization: mod-local custom crane strength is proven safe and remains enabled.
                    # Custom crane speed is deliberately skipped: testing showed architecture-dependent, load-only behavior,
                    # while experimental Tau / no-load / explicit SpeedMult paths could destabilize crane physics.
                    $newText = Replace-CraneHingeMotorForce $text ([double]$S.CraneStrength) $counts
                    if($S.IsModTarget -and [math]::Abs([double]$S.CraneSpeed-1.0) -ge 0.0000001){
                        Add-Count $counts 'SKIPPED Custom crane speed - no known-safe universal free-movement control; crane strength remains supported' 1
                    } elseif(-not $S.IsModTarget){
                        $newText = Replace-CraneControlledIKSpeed $newText ([double]$S.CraneSpeed) $counts
                    }
                } elseif ($S.TargetTruckId -and $S.IndividualServiceAddonEntries -contains $entry.FullName) {
                    # DEV42: selected-truck compatible resource equipment supports Fuel / Water / Repairs / Wheels.
                    # Fuel can be stored in two places:
                    # ordinary addon FuelCapacity and nested <TruckData FuelCapacity="..."> tank data.
                    # Keep exact selected-truck socket targeting; do not broaden to unrelated addons.
                    $newText=$text
                    if([math]::Abs([double]$S.ServiceFuel-1.0) -ge 0.0000001){
                        $mult=[double]$S.ServiceFuel
                        $truckDataPattern='(?is)(<TruckData\b[^>]*?\bFuelCapacity=")(-?\d+(?:\.\d+)?)(")'
                        $tdn=[regex]::Matches($newText,$truckDataPattern).Count
                        if($tdn -gt 0){
                            $newText=[regex]::Replace($newText,$truckDataPattern,{param($m)
                                $v=[double]::Parse($m.Groups[2].Value,[Globalization.CultureInfo]::InvariantCulture)
                                $m.Groups[1].Value + (Format-Number ($v*$mult)) + $m.Groups[3].Value
                            })
                            Add-Count $counts 'Service fuel capacity (compatible nested TruckData tanks)' $tdn
                        }
                        # Modify remaining FuelCapacity attributes, excluding those already handled inside TruckData tags,
                        # so nested tanks are not multiplied twice.
                        $fuelPattern='(?is)(<(?!TruckData\b)[^>]+?\bFuelCapacity=")(-?\d+(?:\.\d+)?)(")'
                        $fn=[regex]::Matches($newText,$fuelPattern).Count
                        if($fn -gt 0){
                            $newText=[regex]::Replace($newText,$fuelPattern,{param($m)
                                $v=[double]::Parse($m.Groups[2].Value,[Globalization.CultureInfo]::InvariantCulture)
                                $m.Groups[1].Value + (Format-Number ($v*$mult)) + $m.Groups[3].Value
                            })
                            Add-Count $counts 'Service fuel capacity (selected-truck compatible addons)' $fn
                        }
                    }
                    $newText=Replace-NumericAttribute $newText 'WaterCapacity' $S.ServiceWater $counts 'Service water capacity (selected-truck compatible addons)'
                    $newText=Replace-NumericAttribute $newText 'RepairsCapacity' $S.ServiceRepairs $counts 'Service repair points (selected-truck compatible addons)'
                    $newText=Replace-NumericAttribute $newText 'WheelRepairsCapacity' $S.ServiceWheels $counts 'Service spare wheels (selected-truck compatible addons)'
                    if($newText -cne $text){ Add-Count $counts 'Selected-truck compatible service addon XMLs affected' 1 }
                } elseif ($S.TargetTruckId -and @($S.IndividualEngineSourceEntries).Count -gt 0 -and (@($S.IndividualEngineSourceEntries | ForEach-Object {$_.Replace('/', '\')}) -contains $entry.FullName.Replace('/', '\'))) {
                    # RC3.6: modify EVERY named engine variant in every engine family declared compatible
                    # by the selected truck's EngineSocket Type. Identifiers remain untouched.
                    $familyType=''
                    for($ei=0;$ei -lt @($S.IndividualEngineSourceEntries).Count;$ei++){
                        if(([string]$S.IndividualEngineSourceEntries[$ei]).Replace('/','\').Equals($entry.FullName.Replace('/','\'),[StringComparison]::OrdinalIgnoreCase)){$familyType=[string]$S.IndividualEngineTypes[$ei];break}
                    }
                    $pattern='(?is)<Engine\b(?=[^>]*\bName="[^"]+")[^>]*>.*?</Engine>'
                    $ms=[regex]::Matches($text,$pattern)
                    if($ms.Count -lt 1){throw "RC3.6 engine safety stop: compatible family '$familyType' contains no named engine variants."}
                    $sb=New-Object Text.StringBuilder; $pos=0; $changedVariants=0
                    foreach($em in $ms){
                        [void]$sb.Append($text.Substring($pos,$em.Index-$pos)); $block=$em.Value; $mod=$block
                        $mod=Replace-NumericAttribute $mod 'Torque' $S.EngineTorque $counts 'Engine torque (all compatible engine variants)'
                        $mod=Replace-NumericAttribute $mod 'EngineResponsiveness' $S.EngineResponse $counts 'Engine responsiveness (all compatible engine variants)'
                        $mod=Replace-NumericAttribute $mod 'FuelConsumption' $S.EngineFuel $counts 'Engine fuel consumption (all compatible engine variants)'
                        $mod=Replace-NumericAttribute $mod 'DamageCapacity' $S.EngineDurability $counts 'Engine durability (all compatible engine variants)'
                        if([math]::Abs([double]$S.EngineResponse-1.0) -ge 0.0000001 -and -not [regex]::IsMatch($mod,'(?i)\bEngineResponsiveness="[^"]+"')){
                            $baseResponse=0.04; $tm=[regex]::Match($block,'(?i)\b_template="([^"]+)"')
                            if($tm.Success){$tn=[regex]::Escape($tm.Groups[1].Value);$tt=[regex]::Match($text,('(?is)<' + $tn + '\b[^>]*>'));if(-not $tt.Success){$tt=[regex]::Match($text,('(?is)<' + $tn + '\b[^>]*/>'))};if($tt.Success){$rm=[regex]::Match($tt.Value,'(?i)\bEngineResponsiveness="([0-9eE+\-.]+)"');if($rm.Success){$baseResponse=[double]::Parse($rm.Groups[1].Value,[Globalization.CultureInfo]::InvariantCulture)}}}
                            $v=$baseResponse*[double]$S.EngineResponse;if($v -gt 1){$v=1};if($v -lt .01){$v=.01};$fmt=$v.ToString('0.######',[Globalization.CultureInfo]::InvariantCulture)
                            $op=[regex]::Match($mod,'(?is)<Engine\b[^>]*>');if(-not $op.Success){throw 'RC3.6 engine responsiveness safety stop.'};$nop=$op.Value.Insert($op.Value.Length-1,(' EngineResponsiveness="'+$fmt+'"'));$mod=$mod.Substring(0,$op.Index)+$nop+$mod.Substring($op.Index+$op.Length);Add-Count $counts 'Engine responsiveness (all compatible engine variants)' 1
                        }
                        if($mod -cne $block){$changedVariants++};[void]$sb.Append($mod);$pos=$em.Index+$em.Length
                    }
                    [void]$sb.Append($text.Substring($pos));$newText=$sb.ToString()
                    if($newText -cne $text){Add-Count $counts ('Compatible engine variants modified - family '+$familyType) $changedVariants; Add-Count $counts ('SHARED compatible engine families - base trucks using one or more') ([int]$S.SharedEngineTruckUsers)}
                } elseif ($S.TargetTruckId -and @($S.IndividualGearboxSourceEntries).Count -gt 0 -and (@($S.IndividualGearboxSourceEntries | ForEach-Object {$_.Replace('/', '\')}) -contains $entry.FullName.Replace('/', '\'))) {
                    # TEST 6.25: permanent individual gearbox path uses the same attribute transformations as
                    # working All Trucks mode to the ENTIRE resolved stock gearbox family XML.
                    # This is intentionally a shared-family test: no cloning, renaming, or socket repointing.
                    $mod=$text
                    if([math]::Abs([double]$S.GearboxFuel-1.0)-ge 0.0000001){$mod=Replace-NumericAttribute $mod 'FuelConsumption' $S.GearboxFuel $counts 'Gearbox fuel consumption (shared gearbox family)'}
                    if([math]::Abs([double]$S.AwdFuel-1.0)-ge 0.0000001){$mod=Replace-NumericAttribute $mod 'AWDConsumptionModifier' $S.AwdFuel $counts 'AWD fuel penalty (shared gearbox family)'}
                    if([math]::Abs([double]$S.IdleFuel-1.0)-ge 0.0000001){$mod=Replace-NumericAttribute $mod 'IdleFuelModifier' $S.IdleFuel $counts 'Idle fuel use (shared gearbox family)'}
                    if([math]::Abs([double]$S.GearSpeed-1.0)-ge 0.0000001){$mod=Tune-GearboxProgression $mod $S.GearSpeed $counts 'Gearbox variants tuned (shared gearbox family)'}
                    if([math]::Abs([double]$S.GearboxDurability-1.0)-ge 0.0000001){$mod=Replace-NumericAttribute $mod 'DamageCapacity' $S.GearboxDurability $counts 'Gearbox durability (shared gearbox family)'}
                    $newText=$mod
                    if($newText -cne $text){
                        $thisType=[IO.Path]::GetFileNameWithoutExtension($entry.Name)
                        Add-Count $counts ('SHARED gearbox FAMILY '+$thisType+' - base trucks using selected default') ([int]$S.SharedGearboxTruckUsers)
                    }
                } else {
                    $newText = Modify-Entry $entry.FullName $text $S $counts
                }
                # PERSONAL TEST CATEGORY SPEED 5: Upgrade/addon prices and unlocks are now
                # category-scoped.  Only XMLs on the category whitelist are touched; this prevents
                # All Scouts (for example) from changing unrelated Heavy/Offroad upgrade definitions.
                if($S.CategorySinglePassMode -and $S.CategoryUpgradeEntries){
                    $econKey=$entry.FullName.Replace('\','/').ToLowerInvariant()
                    $econSet=@($S.CategoryUpgradeEntries | ForEach-Object { ([string]$_).Replace('\','/').ToLowerInvariant() })
                    if($econSet -contains $econKey){
                        # FIX 2D: a category upgrade whitelist can include a base-truck XML for
                        # discovery/unlock metadata. Never apply UpgradePrice to that truck's own
                        # Price; TruckPrice is the sole owner of base-truck purchase price.
                        $baseKeySet=@($S.TargetTruckEntries | ForEach-Object { ([string]$_).Replace('\','/').ToLowerInvariant() })
                        if(($baseKeySet -notcontains $econKey) -and [math]::Abs([double]$S.UpgradePrice-1.0) -ge 0.0000001){
                            $newText=Replace-NumericAttribute $newText 'Price' $S.UpgradePrice $counts 'Upgrade/addon prices (selected category)'
                        }
                        if($S.UnlockUpgrades){
                            $p1='(?i)(\bUnlockByRank=")\d+(?:\.\d+)?(")'
                            $p2='(?i)(\bUnlockByExploration=")(?:true|false)(")'
                            $un=[regex]::Matches($newText,$p1).Count+[regex]::Matches($newText,$p2).Count
                            $newText=[regex]::Replace($newText,$p1,'${1}1${2}')
                            $newText=[regex]::Replace($newText,$p2,'${1}false${2}')
                            Add-Count $counts 'Upgrade/addon unlock requirements (selected category)' $un
                        }
                    }
                    # SPEED 6: category base-truck XMLs are unlock-only. This catches AWD/Diff Lock
                    # exploration gates such as Ford F750 AWD and Gor BY-4 Diff Lock without applying
                    # Upgrade/addon Price to the truck's own Price attribute.
                    if($S.UnlockUpgrades -and $S.CategoryDiscoveryEntries){
                        $discSet=@($S.CategoryDiscoveryEntries | ForEach-Object { ([string]$_).Replace('\','/').ToLowerInvariant() })
                        if($discSet -contains $econKey){
                            $p1='(?i)(\bUnlockByRank=")\d+(?:\.\d+)?(")'
                            $p2='(?i)(\bUnlockByExploration=")(?:true|false)(")'
                            $du=[regex]::Matches($newText,$p1).Count+[regex]::Matches($newText,$p2).Count
                            $newText=[regex]::Replace($newText,$p1,'${1}1${2}')
                            $newText=[regex]::Replace($newText,$p2,'${1}false${2}')
                            Add-Count $counts 'Map-discovery upgrade unlock requirements (selected category)' $du
                        }
                    }
                }
                # RC3.9.7: extreme durability is the final override so ordinary durability
                # multipliers cannot push the documented 64000 maximum higher or undo it.
                if ($S.DisableAllDamage) { $newText = Disable-GlobalComponentDamage $entry.FullName $newText $counts }

                # v1.2.0L: official individual-truck edits use the same proven
                # pristine-calculates / current-live-preserves rule as category targets.
                # This fixes the reproduced F750 sequence 40 -> 52 -> 67.6 by ensuring the
                # requested 1.30 multiplier is always calculated from pristine 40, while
                # unrelated edits already present in the live PAK remain untouched.
                if($WriteOutput -and $S.TargetTruckId -and -not $S.IsModTarget -and -not $S.CategorySinglePassMode -and ($newText -cne $originalText)){
                    $liveEntry=$targetZip.GetEntry($entry.FullName)
                    if(-not $liveEntry){throw "INDIVIDUAL BASELINE LOCK safety stop: current live entry '$($entry.FullName)' is missing. Live PAK was NOT replaced."}
                    $lr=New-Object IO.StreamReader($liveEntry.Open(),[Text.Encoding]::UTF8,$true)
                    try{$liveText=$lr.ReadToEnd()}finally{$lr.Dispose()}
                    $newText=Merge-CategoryRequestedXml $originalText $newText $liveText $counts
                }

                # CATEGORY PRESERVATION FIX 2: the requested values above were calculated from
                # pristine $originalText. Merge ONLY those requested attribute deltas into the
                # current live entry already present in the copied target PAK. This is the key
                # non-stacking + preservation rule: pristine calculates; current live preserves.
                if($WriteOutput -and $S.CategorySinglePassMode -and ($newText -cne $originalText)){
                    $liveEntry=$targetZip.GetEntry($entry.FullName)
                    if(-not $liveEntry){throw "CATEGORY PRESERVATION FIX 2 safety stop: current live entry '$($entry.FullName)' is missing. Live PAK was NOT replaced."}
                    $lr=New-Object IO.StreamReader($liveEntry.Open(),[Text.Encoding]::UTF8,$true)
                    try{$liveText=$lr.ReadToEnd()}finally{$lr.Dispose()}
                    $newText=Merge-CategoryRequestedXml $originalText $newText $liveText $counts

                    # FIX 2E baseline locks (regex-token correction) for the overlap defects proven by the full
                    # All Trucks -> Scouts -> Highway -> Heavy Duty -> Offroad -> Heavy audit.
                    # 1) Base-truck Price must ALWAYS equal pristine Price * TruckPrice.
                    #    Category upgrade whitelists can overlap base-truck XMLs, so never let
                    #    UpgradePrice or a prior live Price become the next multiplication base.
                    $entryKey=$entry.FullName.Replace('\','/').ToLowerInvariant()
                    $baseTruckSet=@($S.TargetTruckEntries | ForEach-Object { ([string]$_).Replace('\','/').ToLowerInvariant() })
                    if($baseTruckSet -contains $entryKey -and [math]::Abs([double]$S.TruckPrice-1.0) -ge 0.0000001){
                        $newText=Set-NumericAttributeFromBaseline $originalText $newText 'Price' ([double]$S.TruckPrice) $counts 'CATEGORY FIX 2E baseline-locked truck prices'
                    }

                    # 2) Shared service addons can be compatible with trucks in several classes.
                    #    Lock every service capacity handled by this category to pristine * requested
                    #    so repeated category membership can never compound the live value.
                    $svcSet=@($S.IndividualServiceAddonEntries | ForEach-Object { ([string]$_).Replace('\','/').ToLowerInvariant() })
                    if($svcSet -contains $entryKey){
                        $newText=Set-NumericAttributeFromBaseline $originalText $newText 'FuelCapacity' ([double]$S.ServiceFuel) $counts 'CATEGORY FIX 2E baseline-locked service fuel'
                        $newText=Set-NumericAttributeFromBaseline $originalText $newText 'WaterCapacity' ([double]$S.ServiceWater) $counts 'CATEGORY FIX 2E baseline-locked service water'
                        $newText=Set-NumericAttributeFromBaseline $originalText $newText 'RepairsCapacity' ([double]$S.ServiceRepairs) $counts 'CATEGORY FIX 2E baseline-locked service repairs'
                        $newText=Set-NumericAttributeFromBaseline $originalText $newText 'WheelRepairsCapacity' ([double]$S.ServiceWheels) $counts 'CATEGORY FIX 2E baseline-locked service spare wheels'
                    }
                }
                $changed = ($newText -cne $originalText)
                if($WriteOutput -and ($S.CategorySinglePassMode -or ($S.TargetTruckId -and -not $S.IsModTarget))){
                    # Category and official individual modes both merge pristine-derived requests
                    # into CURRENT live XML, so replacement is controlled against live bytes.
                    if($null -ne $liveText){$changed=($newText -cne $liveText)}
                }
                if ($changed) { $modifiedFiles++ }
            }
            if ($WriteOutput) {
                if ($S.IsModTarget -or $S.CategoryBatchMode -or ($S.TargetTruckId -and -not $S.IsModTarget)) {
                    # v1.2.0L: official individual-truck mode uses the surgical UPDATE writer.
                    # TEST 5 correctly opened a byte-for-byte live PAK copy in ZipArchive Update mode,
                    # but then fell through to the full CreateEntry writer below. That appended a second
                    # copy of every archive entry (11,719 -> 23,438) and made SnowRunner read stock/old
                    # definitions unpredictably. Replace ONLY changed XML entries for individual targets,
                    # exactly as category/mod UPDATE mode already does. This preserves one unique entry per
                    # path while retaining TEST 5's pristine-baseline/non-stacking calculation.
                    # PERSONAL TEST CATEGORY SPEED 3:
                    # Category batches already operate on a byte-for-byte copy opened in UPDATE mode.
                    # Replace ONLY XML entries that actually changed, exactly like the proven surgical
                    # mod-PAK path.  SPEED 1 still fell through to the full-archive writer here, causing
                    # thousands of needless CreateEntry calls on every truck pass.
                    # Untouched entries remain exactly as stored in the copied archive.
                    # DEV6 surgical mod edit: untouched entries remain exactly as stored in the
                    # byte-for-byte copied original archive. Replace ONLY an XML that actually changed.
                    if ($changed) {
                        $existing = $targetZip.GetEntry($entry.FullName)
                        if (-not $existing) { throw "DEV6 mod PAK safety stop: target entry '$($entry.FullName)' disappeared before replacement." }
                        $savedTime = $existing.LastWriteTime
                        $existing.Delete()
                        $newEntry = $targetZip.CreateEntry($entry.FullName, [IO.Compression.CompressionLevel]::Optimal)
                        $newEntry.LastWriteTime = $savedTime
                        $dest = $newEntry.Open()
                        try {
                            $newBytes = $utf8.GetBytes($newText)
                            $dest.Write($newBytes,0,$newBytes.Length)
                        } finally { $dest.Dispose() }
                    }
                } else {
                    $newEntry = $targetZip.CreateEntry($entry.FullName, [IO.Compression.CompressionLevel]::Optimal)
                    $newEntry.LastWriteTime = $entry.LastWriteTime
                    $dest = $newEntry.Open()
                    try {
                        if ($changed) {
                            $newBytes = $utf8.GetBytes($newText)
                            $dest.Write($newBytes, 0, $newBytes.Length)
                        } else {
                            $dest.Write($bytes, 0, $bytes.Length)
                        }
                    } finally { $dest.Dispose() }
                }
            }
        }

    } finally {
        if ($null -ne $targetZip) { $targetZip.Dispose() }
        if ($null -ne $output) { $output.Dispose() }
        if ($null -ne $sourceZip) { $sourceZip.Dispose() }
        if ($null -ne $input) { $input.Dispose() }
    }
    if($WriteOutput -and -not $S.IsModTarget -and $S.CategorySinglePassMode){
        Restore-And-Verify-PreservedAlwaysDiff $tempPath $categoryPreservedAlwaysDiff $counts
    }

    # Individual-truck mode must prove that exactly the intended truck XML
    # actually changed BEFORE a rebuilt archive is ever installed over the live PAK.
    if ($WriteOutput -and $S.TargetTruckId -and $modifiedFiles -eq 0) {
        if ($tempPath -and (Test-Path -LiteralPath $tempPath)) { Remove-Item -LiteralPath $tempPath -Force }
        throw ("No applicable values were found: the selected truck '" + $S.TargetTruck + "' resolved correctly, but none of the selected settings apply to its truck-local XML. The live PAK was NOT replaced.")
    }

    # RC3.9.7: if Gear Tuning was requested, prove that at least one gearbox variant
    # was actually tuned before any live PAK replacement. All Trucks may legitimately scan
    # template/helper gearbox XMLs with no named variants, but the overall operation may not
    # silently succeed with zero tuned variants.
    if ([math]::Abs([double]$S.GearSpeed - 1.0) -ge 0.0000001) {
        $gearCount = 0
        if ($counts.ContainsKey('Gearbox variants tuned')) { $gearCount += [int]$counts['Gearbox variants tuned'] }
        if ($counts.ContainsKey('Gearbox variants tuned (shared gearbox family)')) { $gearCount += [int]$counts['Gearbox variants tuned (shared gearbox family)'] }
        if ($gearCount -lt 1) {
            if ($WriteOutput -and $tempPath -and (Test-Path -LiteralPath $tempPath)) { Remove-Item -LiteralPath $tempPath -Force }
            throw 'RC3.9.7 Gear Tuning safety stop: Gear Tuning was requested, but no gearbox variants were tuned. The live PAK was NOT replaced.'
        }
    }

    # DEV27: validate Extreme Durability BEFORE any live replacement. For a selected
    # third-party mod, require only locally-applicable component changes discovered in
    # that mod PAK; inherited/absent component families are safely skipped and disclosed.
    if ($S.DisableAllDamage) {
        $expectedDurability = Get-ExtremeDurabilityExpectedChanges $sourcePath
        foreach($dk in @($expectedDurability.Keys)) {
            # DEV30: durability validation follows feature capability, not unrelated XML merely
            # present elsewhere in the package. If this selected truck's component is inherited
            # or structurally unresolved, that component is intentionally skipped.
            if($S.IsModTarget){
                if($dk -like '*engine*' -and ($S.SkippedUnsupportedEngine -or (@($S.SkippedInheritedEngineTypes).Count -gt 0 -and @($S.IndividualEngineSourceEntries).Count -eq 0))){continue}
                if($dk -like '*wheel*' -and ($S.SkippedUnsupportedTires -or $S.SkippedInheritedWheelType)){continue}
                if($dk -like '*suspension*' -and ($S.SkippedUnsupportedSuspension -or (@($S.SkippedInheritedSuspensionTypes).Count -gt 0 -and @($S.CompatibleSuspensionFamilies).Count -eq 0))){continue}
                if($dk -like '*gearbox*' -and $S.SkippedUnsupportedGearbox){continue}
            }
            $need=[int]$expectedDurability[$dk]
            $got=if($counts.ContainsKey($dk)){[int]$counts[$dk]}else{0}
            if($need -gt 0 -and $got -lt $need){
                if ($WriteOutput -and $tempPath -and (Test-Path -LiteralPath $tempPath)) { Remove-Item -LiteralPath $tempPath -Force }
                throw "DEV27 safety stop: Extreme durability expected $need local change(s) for '$dk', but verified only $got. The live PAK was NOT replaced."
            }
            if($S.IsModTarget -and $need -eq 0){
                $label = switch -Wildcard ($dk) {
                    '*engine*' {'SKIPPED Extreme durability - no applicable local engine DamageCapacity values'}
                    '*gearbox*' {'SKIPPED Extreme durability - no applicable local gearbox DamageCapacity values'}
                    '*suspension*' {'SKIPPED Extreme durability - no applicable local suspension DamageCapacity changes'}
                    '*wheel*' {'SKIPPED Extreme durability - no applicable local wheel DamageCapacity values'}
                    '*fuel tank*' {'SKIPPED Extreme durability - no applicable local fuel-tank DamageCapacity values'}
                }
                if($label){ Add-Count $counts $label 1 }
            }
        }
    }

    if ($WriteOutput) {
        $rollbackPath = Join-Path ([IO.Path]::GetDirectoryName($pak)) ('initial.editor.rollback.' + [guid]::NewGuid().ToString('N') + '.pak')
        try {
            if ($S.IsModTarget) {
                # DEV11: every mod Apply is computed from the immutable pristine backup,
                # then independently verified against that SAME baseline before install.
                Assert-ModEngineTorqueMatchesBaseline $S $backup $tempPath
                Rebuild-ModPakWithWinRAR $backup $tempPath $pak
                Assert-ModPakStructurePreserved $backup $tempPath
                Assert-ModEngineTorqueMatchesBaseline $S $backup $tempPath
                Assert-ModPak $tempPath ([string]$S.TargetTruckEntry)
            } else {
                if($S.CategorySinglePassMode){Assert-NoCategoryMergeArtifacts $tempPath}
                Assert-Pak $tempPath; [void](Test-PakCompatibility $tempPath)
            }
            # Same-volume atomic replacement. If replacement fails, Windows leaves
            # the current live PAK intact; rollback is retained only during swap.
            [IO.File]::Replace($tempPath, $pak, $rollbackPath, $true)
            $tempPath = $null
            if ($S.IsModTarget) { Assert-ModPak $pak ([string]$S.TargetTruckEntry); Set-LastModEditorOutputHash $pak } else { Assert-Pak $pak; Set-LastEditorOutputHash $pak }
        } catch {
            if ((Test-Path -LiteralPath $rollbackPath) -and -not (Test-Path -LiteralPath $pak)) {
                Move-Item -LiteralPath $rollbackPath -Destination $pak -Force
            }
            throw
        } finally {
            if ($tempPath -and (Test-Path -LiteralPath $tempPath)) { Remove-Item -LiteralPath $tempPath -Force }
            if (Test-Path -LiteralPath $rollbackPath) { Remove-Item -LiteralPath $rollbackPath -Force }
        }
    }
    return [pscustomobject]@{ ModifiedFiles=$modifiedFiles; Counts=$counts; Backup=$backup; UpdateDetected=$script:UpdateDetected; Compatibility=$compat; TargetTruck=$S.TargetTruck; ExtremeDurabilityEnabled=[bool]$S.DisableAllDamage }
}

$script:CurrentVersion = [version]'1.2.0'
$script:DisplayVersion = '1.2.0L'
# IMPORTANT: use the revision-less Raw Gist URL so future edits are visible to already-installed copies.
$script:UpdateInfoUrl = 'https://gist.githubusercontent.com/WickedLord69/3c76989aaf94db0a829da18e01e4c49e/raw/gistfile1.txt'
$script:DefaultDownloadPage = 'https://mod.io/g/snowrunner/m/wl-simplistic-snowrunner-mod-editor#description'

function Get-OnlineUpdateInfo {
    $response = $null
    $reader = $null
    try {
        # HttpWebRequest is available in the .NET Framework runtime used by the packaged EXE.
        # Avoid System.Net.Http/HttpClient so the EXE does not depend on an extra assembly.
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
        $request = [Net.HttpWebRequest]::Create($script:UpdateInfoUrl)
        $request.Method = 'GET'
        $request.Timeout = 3000
        $request.ReadWriteTimeout = 3000
        $request.UserAgent = 'WL-Simplistic-SnowRunner-Mod-Editor/1.2.0'
        $request.CachePolicy = New-Object Net.Cache.RequestCachePolicy([Net.Cache.RequestCacheLevel]::NoCacheNoStore)
        $response = $request.GetResponse()
        $reader = New-Object IO.StreamReader($response.GetResponseStream())
        $text = $reader.ReadToEnd()
        $remoteVersionText = $null
        $downloadPage = $script:DefaultDownloadPage
        foreach ($line in ($text -split "`r?`n")) {
            if ($line -match '^\s*Version\s*=\s*(.+?)\s*$') { $remoteVersionText = $Matches[1].Trim() }
            elseif ($line -match '^\s*DownloadPage\s*=\s*(.+?)\s*$') { $downloadPage = $Matches[1].Trim() }
        }
        if ([string]::IsNullOrWhiteSpace($remoteVersionText)) { throw 'The update information did not contain a Version value.' }
        # v1.2.0L hotfix: accept an optional trailing release label (for example 1.2.0L)
        # while keeping numeric System.Version comparison semantics.
        $remoteVersionNumeric = $remoteVersionText
        if ($remoteVersionText -match '^([0-9]+(?:\.[0-9]+){1,3})[A-Za-z]*$') { $remoteVersionNumeric = $Matches[1] }
        try { $remoteVersion = [version]$remoteVersionNumeric } catch { throw "The online version '$remoteVersionText' is not valid." }
        if ([string]::IsNullOrWhiteSpace($downloadPage)) { $downloadPage = $script:DefaultDownloadPage }
        [pscustomobject]@{ Version=$remoteVersion; VersionText=$remoteVersionText; DownloadPage=$downloadPage }
    }
    finally {
        if ($reader) { $reader.Dispose() }
        if ($response) { $response.Dispose() }
    }
}

function Open-UpdateDownloadPage([string]$Url) {
    if ([string]::IsNullOrWhiteSpace($Url)) { $Url = $script:DefaultDownloadPage }
    Start-Process $Url
}

function Test-ForEditorUpdate([bool]$Manual = $false) {
    try {
        $info = Get-OnlineUpdateInfo
        if ($info.Version -gt $script:CurrentVersion) {
            $message = "A newer version of WL Simplistic SnowRunner Mod Editor is available.`r`n`r`nInstalled: v$($script:DisplayVersion)`r`nLatest: v$($info.VersionText)`r`n`r`nOpen the official mod.io download page?"
            $answer = [Windows.Forms.MessageBox]::Show($message, 'Update Available', 'YesNo', 'Information')
            if ($answer -eq 'Yes') { Open-UpdateDownloadPage $info.DownloadPage }
            return 'UpdateAvailable'
        }
        if ($Manual) {
            [Windows.Forms.MessageBox]::Show("You're up to date.`r`n`r`nInstalled: v$($script:DisplayVersion)`r`nLatest: v$($info.VersionText)", 'Check for Updates', 'OK', 'Information') | Out-Null
        }
        return 'Current'
    }
    catch {
        if ($Manual) {
            [Windows.Forms.MessageBox]::Show("Could not check for updates right now.`r`n`r`nThe editor can still be used normally.`r`n`r`n$($_.Exception.Message)", 'Check for Updates', 'OK', 'Warning') | Out-Null
        }
        # Startup checks fail silently by design; offline/update-server issues never block the editor.
        return 'Unavailable'
    }
}

function Format-Summary($Result, [string]$Heading) {
    # v1.2.0L: concise Preview/Apply summary.
    # Keep shared-component scope explicit, but collapse the raw per-rule wall of text
    # into readable system groups. This changes display only; edit/apply logic is untouched.
    $lines = New-Object Collections.Generic.List[string]
    $lines.Add($Heading)
    if ($Result.TargetTruck) { $lines.Add("Target: $($Result.TargetTruck)") }
    if ($Result.UpdateDetected) {
        $lines.Add('')
        $lines.Add('SnowRunner update detected. Compatibility passed and a new current-version original backup was created automatically.')
    }

    $lines.Add('')
    $lines.Add("XML files changed: $($Result.ModifiedFiles)")
    $lines.Add("Extreme durability (GLOBAL): $(if ($Result.ExtremeDurabilityEnabled) { 'ON' } else { 'OFF' })")

    $shared = New-Object Collections.Generic.List[string]
    $groups = [ordered]@{
        'ENGINE / GEARBOX' = @{ Values = 0; Rules = 0 }
        'DRIVETRAIN' = @{ Values = 0; Rules = 0 }
        'STEERING / SUSPENSION / STABILITY' = @{ Values = 0; Rules = 0 }
        'TIRES / WHEELS' = @{ Values = 0; Rules = 0 }
        'RECOVERY / CRANES' = @{ Values = 0; Rules = 0 }
        'SERVICE / CARGO' = @{ Values = 0; Rules = 0 }
        'DURABILITY' = @{ Values = 0; Rules = 0 }
        'ACCESS / ECONOMY' = @{ Values = 0; Rules = 0 }
        'OTHER' = @{ Values = 0; Rules = 0 }
    }

    foreach ($key in ($Result.Counts.Keys | Sort-Object)) {
        $value = [int]$Result.Counts[$key]
        $friendly = $null
        if ($key -like 'SHARED compatible engine families*') {
            $scopeText = if ($value -eq 1) { '1 other base truck' } else { "$value other base trucks" }
            $friendly = "Engine family - shared by $scopeText"
        } elseif ($key -like 'SHARED compatible suspension families*') {
            $scopeText = if ($value -eq 1) { '1 other base truck' } else { "$value other base trucks" }
            $friendly = "Suspension family - shared by $scopeText"
        } elseif ($key -like 'SHARED gearbox FAMILY *') {
            $family = ($key -replace '^SHARED gearbox FAMILY ','') -replace ' - base trucks using selected default$',''
            $scopeText = if ($value -eq 1) { '1 other base truck' } else { "$value other base trucks" }
            $friendly = "Gearbox family $family - shared by $scopeText"
        } elseif ($key -like 'SHARED wheel family *') {
            $family = ($key -replace '^SHARED wheel family ','') -replace ' - base trucks using as default$',''
            $scopeText = if ($value -eq 1) { '1 other base truck' } else { "$value other base trucks" }
            $friendly = "Wheel family $family - shared by $scopeText"
        } elseif ($key -like 'Winch family * - base trucks using family') {
            $family = ($key -replace '^Winch family ','') -replace ' - base trucks using family$',''
            $scopeText = if ($value -eq 1) { '1 other base truck' } else { "$value other base trucks" }
            $friendly = "Winch family $family - shared by $scopeText"
        }
        if ($friendly) {
            $shared.Add($friendly)
            continue
        }

        $group = 'OTHER'
        if ($key -match '(?i)engine|gearbox|gear |fuel use|fuel penalty|launch gear|forward gear') {
            $group = 'ENGINE / GEARBOX'
        } elseif ($key -match '(?i)AWD|differential|diff lock') {
            $group = 'DRIVETRAIN'
        } elseif ($key -match '(?i)steer|suspension|center of gravity') {
            $group = 'STEERING / SUSPENSION / STABILITY'
        } elseif ($key -match '(?i)tire|wheel') {
            $group = 'TIRES / WHEELS'
        } elseif ($key -match '(?i)winch|crane|mechanical speed|mechanical strength') {
            $group = 'RECOVERY / CRANES'
        } elseif ($key -match '(?i)service|cargo mass|truck fuel capacity|fuel capacity|water capacity|repair points|spare wheels') {
            $group = 'SERVICE / CARGO'
        } elseif ($key -match '(?i)durability|capacity maxed|broken-wheel') {
            $group = 'DURABILITY'
        } elseif ($key -match '(?i)unlock|price|region availability|discovery|exploration') {
            $group = 'ACCESS / ECONOMY'
        }
        $groups[$group].Values += $value
        $groups[$group].Rules += 1
    }

    if ($shared.Count -gt 0) {
        $lines.Add('')
        $lines.Add('SHARED COMPONENT SCOPE')
        $lines.Add('These edits also affect other trucks that use the same SnowRunner component family:')
        foreach ($item in $shared) { $lines.Add("  - $item") }
    }

    $lines.Add('')
    $lines.Add('CHANGES BY SYSTEM')
    foreach ($name in $groups.Keys) {
        $g = $groups[$name]
        if ($g.Rules -gt 0) {
            $lines.Add("$name`: $($g.Values) values across $($g.Rules) rules")
        }
    }

    $lines.Add('')
    $lines.Add('Preview/Apply uses the active settings shown in the editor. Shared SnowRunner component families can affect more than the selected truck.')
    $lines.Add('')
    $lines.Add("Original backup: $($Result.Backup)")
    return $lines -join [Environment]::NewLine
}

$form = New-Object Windows.Forms.Form
$form.Text = $script:AppName
$iconCandidate = if ($env:WL_SSME_ICON) { $env:WL_SSME_ICON } else { Join-Path $script:AppRoot 'assets\WL-icon.ico' }
if (Test-Path -LiteralPath $iconCandidate) { $form.Icon = New-Object Drawing.Icon($iconCandidate) }
$form.StartPosition = 'CenterScreen'
$form.Size = New-Object Drawing.Size(1040, 790)
$form.MinimumSize = New-Object Drawing.Size(1040, 790)
$form.Font = New-Object Drawing.Font('Segoe UI', 9)
$form.BackColor = [Drawing.Color]::FromArgb(245,247,250)

$title = New-Object Windows.Forms.Label
$title.Text = 'WL Simplistic SnowRunner Mod Editor'
$title.Font = New-Object Drawing.Font('Segoe UI Semibold', 18)
$title.Location = New-Object Drawing.Point(22, 16)
$title.AutoSize = $true
$form.Controls.Add($title)

# RC8: branded header logo. The public EXE embeds this PNG and exposes a temporary path via WL_SSME_LOGO.
$headerLogoCandidate = if ($env:WL_SSME_LOGO) { $env:WL_SSME_LOGO } else { Join-Path $script:AppRoot 'assets\WL-header-logo.png' }
if (Test-Path -LiteralPath $headerLogoCandidate) {
    try {
        $logoSource = [Drawing.Image]::FromFile($headerLogoCandidate)
        $logoImage = New-Object Drawing.Bitmap($logoSource)
        $logoSource.Dispose()
        $picLogo = New-Object Windows.Forms.PictureBox
        $picLogo.Location = New-Object Drawing.Point(525, 4)
        $picLogo.Size = New-Object Drawing.Size(82, 82)
        $picLogo.SizeMode = 'Zoom'
        $picLogo.BackColor = [Drawing.Color]::Transparent
        $picLogo.Image = $logoImage
        $form.Controls.Add($picLogo)
    } catch { }
}

$lblLanguage = New-Object Windows.Forms.Label
$lblLanguage.Text = L 'Language'
$lblLanguage.Location = New-Object Drawing.Point(765, 20)
$lblLanguage.AutoSize = $true
$form.Controls.Add($lblLanguage)
$cmbLanguage = New-Object Windows.Forms.ComboBox
$cmbLanguage.DropDownStyle = 'DropDownList'
$cmbLanguage.Location = New-Object Drawing.Point(835, 16)
$cmbLanguage.Size = New-Object Drawing.Size(170,25)
foreach($lang in $script:LanguageList){ [void]$cmbLanguage.Items.Add([string]$lang.Name) }
$langCodes = @($script:LanguageList | ForEach-Object { [string]$_.Code })
$currentLangIndex = [Array]::IndexOf([object[]]$langCodes, [object]$script:Language)
if($currentLangIndex -lt 0){$currentLangIndex=0}
$cmbLanguage.SelectedIndex = $currentLangIndex
$form.Controls.Add($cmbLanguage)

$lblPak = New-Object Windows.Forms.Label
$lblPak.Text = L 'Game file'
$lblPak.Location = New-Object Drawing.Point(25, 84)
$lblPak.AutoSize = $true
$form.Controls.Add($lblPak)

$txtPak = New-Object Windows.Forms.TextBox
$txtPak.Location = New-Object Drawing.Point(25, 105)
$txtPak.Size = New-Object Drawing.Size(865, 25)
$form.Controls.Add($txtPak)

$btnBrowse = New-Object Windows.Forms.Button
$btnBrowse.Text = L 'Browse...'
$btnBrowse.Location = New-Object Drawing.Point(900, 103)
$btnBrowse.Size = New-Object Drawing.Size(105, 28)
$form.Controls.Add($btnBrowse)

$lblTruck = New-Object Windows.Forms.Label
$lblTruck.Text = L 'Truck target'
$lblTruck.Location = New-Object Drawing.Point(25, 139)
$lblTruck.AutoSize = $true
$form.Controls.Add($lblTruck)

$cmbTruck = New-Object Windows.Forms.ComboBox
$cmbTruck.DropDownStyle = 'DropDownList'
$cmbTruck.Location = New-Object Drawing.Point(175, 135)
$cmbTruck.Size = New-Object Drawing.Size(340, 25)
[void]$cmbTruck.Items.Add((L 'All Trucks'))
$cmbTruck.SelectedIndex = 0
$form.Controls.Add($cmbTruck)

$btnScanTrucks = New-Object Windows.Forms.Button
$btnScanTrucks.Text = L 'Scan Trucks'
$btnScanTrucks.Location = New-Object Drawing.Point(525, 134)
$btnScanTrucks.Size = New-Object Drawing.Size(170, 28)
$form.Controls.Add($btnScanTrucks)

$btnScanMods = New-Object Windows.Forms.Button
$btnScanMods.Text = L 'Scan Mods'
$btnScanMods.Location = New-Object Drawing.Point(700, 134)
$btnScanMods.Size = New-Object Drawing.Size(170, 28)
$form.Controls.Add($btnScanMods)

$lblTruckCount = New-Object Windows.Forms.Label
$lblTruckCount.Text = L 'Select initial.pak to scan trucks'
$lblTruckCount.ForeColor = [Drawing.Color]::DimGray
$lblTruckCount.Location = New-Object Drawing.Point(880, 136)
$lblTruckCount.Size = New-Object Drawing.Size(115, 44)
$form.Controls.Add($lblTruckCount)

$chkStockWheelSwap = New-Object Windows.Forms.CheckBox
$chkStockWheelSwap.Text = 'TEST 6.18: retired wheel-family substitution test'
$chkStockWheelSwap.Visible = $false
$chkStockWheelSwap.Location = New-Object Drawing.Point(105, 164)
$chkStockWheelSwap.Size = New-Object Drawing.Size(430, 24)
$chkStockWheelSwap.Checked = $false
$chkStockWheelSwap.Enabled = $false
$form.Controls.Add($chkStockWheelSwap)

$panel = New-Object Windows.Forms.Panel
$panel.Location = New-Object Drawing.Point(20, 190)
$panel.Size = New-Object Drawing.Size(990, 455)
$panel.AutoScroll = $true
$panel.BackColor = [Drawing.Color]::White
$panel.BorderStyle = 'FixedSingle'
$form.Controls.Add($panel)

function Add-Section([string]$Text, [int]$X, [int]$Y) {
    $label = New-Object Windows.Forms.Label
    $label.Text = L $Text
    $label.Font = New-Object Drawing.Font('Segoe UI Semibold', 11)
    $label.ForeColor = [Drawing.Color]::FromArgb(35,75,125)
    $label.Location = New-Object Drawing.Point($X,$Y)
    $label.AutoSize = $true
    $panel.Controls.Add($label)
}
function Add-Field([string]$Name, [string]$Default, [int]$X, [int]$Y) {
    $label = New-Object Windows.Forms.Label
    $label.Text = L $Name
    $label.Location = New-Object Drawing.Point($X,$Y)
    $label.Size = New-Object Drawing.Size(315,28)
    $panel.Controls.Add($label)
    $box = New-Object Windows.Forms.TextBox
    $box.Text = $Default
    $box.TextAlign = 'Right'
    $box.Location = New-Object Drawing.Point(($X+325),($Y-3))
    $box.Size = New-Object Drawing.Size(75,25)
    $panel.Controls.Add($box)
    $script:Fields[$Name] = $box
}
function Add-Combo([string]$Name, [string[]]$Items, [string]$Default, [int]$X, [int]$Y) {
    $label=New-Object Windows.Forms.Label; $label.Text=(L $Name); $label.Location=New-Object Drawing.Point($X,$Y); $label.Size=New-Object Drawing.Size(315,28); $panel.Controls.Add($label)
    $box=New-Object Windows.Forms.ComboBox; $box.DropDownStyle='DropDownList'; $box.Location=New-Object Drawing.Point(($X+325),($Y-3)); $box.Size=New-Object Drawing.Size(145,25)
    [void]$box.Items.AddRange($Items); $box.SelectedItem=$Default; $panel.Controls.Add($box); $script:Combos[$Name]=$box
}

function Add-Check([string]$Name, [bool]$Default, [int]$X, [int]$Y) {
    $box = New-Object Windows.Forms.CheckBox
    $box.Text = L $Name
    $box.Checked = $Default
    $box.Location = New-Object Drawing.Point($X,$Y)
    $box.Size = New-Object Drawing.Size(455,28)
    $panel.Controls.Add($box)
    $script:Checks[$Name] = $box
}

function Set-TruckModeUi {
    $allModsPreview = ($cmbTruck.SelectedItem -and ([string]$cmbTruck.SelectedItem -eq $script:AllModsPreviewLabel))
    $selectedText=if($cmbTruck.SelectedItem){[string]$cmbTruck.SelectedItem}else{''}
    $category=($script:CategoryTargets -and $script:CategoryTargets.ContainsKey($selectedText))
    $individual = ($cmbTruck.SelectedIndex -gt 0) -and (-not ($script:CategoryHeadingLabels -contains $selectedText))
    $supportedFields = @('Engine torque','Engine responsiveness','Engine fuel consumption','Engine durability','Gearbox fuel consumption','AWD fuel penalty','Idle fuel use','Gearbox durability','Tire asphalt grip','Tire off-road grip','Tire mud grip','Tire durability','Suspension strength','Suspension height','Suspension damping','Suspension durability','Winch strength','Winch length','Truck fuel capacity','Maximum steering angle','Steering response','Fuel tank durability','Truck prices','Truck center-of-gravity drop','Service fuel capacity','Service water capacity','Service repair points','Service spare wheels','Crane strength','Crane speed')
    foreach ($name in $script:Fields.Keys) {
        $script:Fields[$name].Enabled = (-not $individual -or $supportedFields -contains $name -or ($category -and $name -eq 'Upgrade/addon prices'))
    }
    if ($script:Combos.ContainsKey('Gear tuning')) { $script:Combos['Gear tuning'].Enabled = $true }
    if ($btnApply) { $btnApply.Enabled = (-not $allModsPreview) }
    $supportedChecks = @('Always AWD','Always differential lock (unchecked = default)','Extreme durability (GLOBAL)','Autonomous winches','Unlock all trucks','All trucks in all regions','Unlock all upgrades/addons','All tires ignore ice')
    foreach ($name in $script:Checks.Keys) {
        $script:Checks[$name].Enabled = (-not $individual -or $supportedChecks -contains $name -or ($category -and $name -eq 'Unlock all upgrades/addons'))
    }
    $selectedId = if($cmbTruck.SelectedItem -and $script:TruckTargets.ContainsKey([string]$cmbTruck.SelectedItem)){[string]$script:TruckTargets[[string]$cmbTruck.SelectedItem]}else{''}
    $chkStockWheelSwap.Enabled = $false
    $chkStockWheelSwap.Checked = $false
    if ($individual) {
        # Shared/global economy and cargo controls intentionally stay All-Trucks-only.
        # Reset them when entering Individual Truck mode so a preset cannot leave a hidden global value behind.
        $script:Fields['Cargo mass'].Text = '1.00'
        if(-not $category){
            $script:Fields['Upgrade/addon prices'].Text = '1.00'
            # v1.2.0L: Unlock all upgrades/addons is intentionally GLOBAL.
            # Preserve its checked state when moving from All Trucks to an individual truck.
            # An individual Apply may re-assert this global safety/economy unlock, but it must
            # never silently clear a previously requested All Trucks unlock state.
        }
        $script:Fields['Addon/trailer center-of-gravity drop'].Text = '0.00'
        # v1.2.0L RC12: the old subtitle control was removed from the current UI.
        # Do not write to the obsolete $subtitle variable when truck mode changes.
    } else {
        # All-Trucks mode requires no subtitle update in the current UI.
    }
}

function Set-Preset([string]$Name) {
    foreach ($field in $script:Fields.Values) { $field.Text = '1.00' }
    $script:Fields['Truck center-of-gravity drop'].Text = '0.00'
    $script:Fields['Addon/trailer center-of-gravity drop'].Text = '0.00'
    foreach ($check in $script:Checks.Values) { $check.Checked = $false }
    $values = @{}
    $enabled = @()
    if ($Name -eq 'Enhanced') {
        $values = @{
            'Engine torque'='1.25'; 'Engine responsiveness'='1.20'; 'Engine fuel consumption'='0.80'; 'Engine durability'='1.50'
            'Gearbox durability'='1.50'; 'Gearbox fuel consumption'='0.80'; 'AWD fuel penalty'='0.50'
            'Tire asphalt grip'='1.15'; 'Tire off-road grip'='1.35'; 'Tire mud grip'='1.50'; 'Tire durability'='1.50'
            'Suspension strength'='1.25'; 'Suspension height'='1.05'; 'Suspension durability'='1.50'
            'Truck fuel capacity'='1.25'; 'Fuel tank durability'='1.50'; 'Winch strength'='1.50'; 'Winch length'='1.25'
            'Crane strength'='1.50'; 'Crane speed'='1.25'; 'Service fuel capacity'='1.50'; 'Service water capacity'='1.50'; 'Service repair points'='1.50'
            'Service spare wheels'='1.50'; 'Cargo mass'='0.80'; 'Truck prices'='0.75'; 'Upgrade/addon prices'='0.75'
            'Maximum steering angle'='1.15'; 'Steering response'='1.20'
            'Truck center-of-gravity drop'='0.25'; 'Addon/trailer center-of-gravity drop'='0.30'
        }
        $enabled = @('Always AWD','Autonomous winches','Unlock all trucks','All trucks in all regions','Unlock all upgrades/addons')
    }
    elseif ($Name -eq 'Overpowered') {
        $values = @{
            'Engine torque'='2.00'; 'Engine responsiveness'='2.00'; 'Engine fuel consumption'='0.25'; 'Engine durability'='5.00'
            'Gearbox durability'='5.00'; 'Gearbox fuel consumption'='0.25'; 'AWD fuel penalty'='0.00'; 'Idle fuel use'='0.25'
            'Tire asphalt grip'='4.00'; 'Tire off-road grip'='4.00'; 'Tire mud grip'='4.00'; 'Tire durability'='5.00'
            'Suspension strength'='3.00'; 'Suspension durability'='5.00'; 'Truck fuel capacity'='3.00'; 'Fuel tank durability'='5.00'
            'Winch strength'='5.00'; 'Winch length'='3.00'; 'Crane strength'='3.00'; 'Crane speed'='2.00'
            'Service fuel capacity'='5.00'; 'Service water capacity'='5.00'; 'Service repair points'='5.00'; 'Service spare wheels'='5.00'; 'Cargo mass'='0.25'
            'Truck prices'='0.10'; 'Upgrade/addon prices'='0.10'; 'Maximum steering angle'='1.30'; 'Steering response'='1.75'
            'Truck center-of-gravity drop'='0.50'; 'Addon/trailer center-of-gravity drop'='0.60'
        }
        $enabled = @('Always AWD','Autonomous winches','Unlock all trucks','All trucks in all regions','Unlock all upgrades/addons')
    }
    foreach ($key in $values.Keys) { if ($script:Fields.ContainsKey($key)) { $script:Fields[$key].Text = $values[$key] } }
    if ($script:Combos.ContainsKey('Gear tuning')) { $script:Combos['Gear tuning'].SelectedIndex = $(if($Name -eq 'Vanilla'){0}elseif($Name -eq 'Enhanced'){1}else{3}) }
    foreach ($key in $enabled) { if ($script:Checks.ContainsKey($key)) { $script:Checks[$key].Checked = $true } }
    $lblStatus.Text = "$Name preset loaded. Click Preview or Apply when ready."
}

Add-Section 'POWER & FUEL' 18 16
Add-Field 'Engine torque' '1.00' 18 50
Add-Field 'Engine responsiveness' '1.00' 18 80
Add-Field 'Engine fuel consumption' '1.00' 18 110
Add-Field 'Truck fuel capacity' '1.00' 500 50
Add-Field 'Maximum steering angle' '1.00' 500 80
Add-Field 'Steering response' '1.00' 500 110

Add-Section 'GEARBOX' 18 155
Add-Field 'Gearbox fuel consumption' '1.00' 18 190
Add-Field 'AWD fuel penalty' '1.00' 18 220
Add-Field 'Idle fuel use' '1.00' 18 250
Add-Check 'Always AWD' $false 500 190
Add-Check 'Always differential lock (unchecked = default)' $false 500 220
Add-Check 'Extreme durability (GLOBAL)' $false 500 250

Add-Section 'TIRES' 18 295
Add-Field 'Tire asphalt grip' '1.00' 18 330
Add-Field 'Tire off-road grip' '1.00' 18 360
Add-Field 'Tire mud grip' '1.00' 18 390
Add-Check 'All tires ignore ice' $false 18 420

Add-Section 'SUSPENSION' 500 295
Add-Field 'Suspension strength' '1.00' 500 330
Add-Field 'Suspension height' '1.00' 500 360
Add-Field 'Suspension damping' '1.00' 500 390
Add-Field 'Suspension durability' '1.00' 500 420

Add-Section 'RECOVERY & CRANES' 18 458
Add-Field 'Winch strength' '1.00' 18 493
Add-Field 'Winch length' '1.00' 18 523
Add-Field 'Crane strength' '1.00' 18 553
Add-Field 'Crane speed' '1.00' 18 583
Add-Check 'Autonomous winches' $false 500 493

Add-Section 'TRUCK ACCESS' 500 525
Add-Check 'Unlock all trucks' $false 500 560
Add-Check 'All trucks in all regions' $false 500 590

Add-Section 'MORE PERFORMANCE & DURABILITY' 18 630
Add-Combo 'Gear tuning' @((L 'Stock'),(L 'Mild'),(L 'Performance'),(L 'High Performance'),(L 'Extreme')) (L 'Stock') 18 665
Add-Field 'Engine durability' '1.00' 18 695
Add-Field 'Gearbox durability' '1.00' 18 725
Add-Field 'Tire durability' '1.00' 18 755
Add-Field 'Fuel tank durability' '1.00' 18 785

Add-Section 'SERVICE & CARGO' 500 630
Add-Field 'Service fuel capacity' '1.00' 500 665
Add-Field 'Service water capacity' '1.00' 500 695
Add-Field 'Service repair points' '1.00' 500 725
Add-Field 'Service spare wheels' '1.00' 500 755
Add-Field 'Cargo mass' '1.00' 500 785

Add-Section 'ECONOMY & UPGRADES' 18 835
Add-Field 'Truck prices' '1.00' 18 870
Add-Field 'Upgrade/addon prices' '1.00' 18 900
Add-Check 'Unlock all upgrades/addons' $false 500 870

Add-Section 'STABILITY' 500 900
Add-Field 'Truck center-of-gravity drop' '0.00' 500 935
Add-Field 'Addon/trailer center-of-gravity drop' '0.00' 500 965

Add-Section 'QUICK PRESETS' 18 1010
$btnVanilla = New-Object Windows.Forms.Button
$btnVanilla.Text = L 'Vanilla / Reset'
$btnVanilla.Location = New-Object Drawing.Point(18,1045)
$btnVanilla.Size = New-Object Drawing.Size(145,36)
$panel.Controls.Add($btnVanilla)
$btnEnhanced = New-Object Windows.Forms.Button
$btnEnhanced.Text = L 'Enhanced'
$btnEnhanced.Location = New-Object Drawing.Point(173,1045)
$btnEnhanced.Size = New-Object Drawing.Size(135,36)
$panel.Controls.Add($btnEnhanced)
$btnOverpowered = New-Object Windows.Forms.Button
$btnOverpowered.Text = L 'Overpowered'
$btnOverpowered.Location = New-Object Drawing.Point(318,1045)
$btnOverpowered.Size = New-Object Drawing.Size(145,36)
$panel.Controls.Add($btnOverpowered)
$presetNote = New-Object Windows.Forms.Label
$presetNote.Text = L 'Your last applied values are saved automatically.'
$presetNote.ForeColor = [Drawing.Color]::DimGray
$presetNote.Location = New-Object Drawing.Point(500,1051)
$presetNote.AutoSize = $true
$panel.Controls.Add($presetNote)
$panel.AutoScrollMinSize = New-Object Drawing.Size(0,1095)

$btnVanilla.Add_Click({ Set-Preset 'Vanilla' })
$btnEnhanced.Add_Click({ Set-Preset 'Enhanced' })
$btnOverpowered.Add_Click({ Set-Preset 'Overpowered' })

$lblHint = New-Object Windows.Forms.Label
$lblHint.Text = L '1.00 = original value   |   1.50 = +50%   |   0.50 = half'
$lblHint.ForeColor = [Drawing.Color]::DimGray
$lblHint.Location = New-Object Drawing.Point(25, 655)
$lblHint.AutoSize = $true
$form.Controls.Add($lblHint)

$btnPreview = New-Object Windows.Forms.Button
$btnPreview.Text = L 'Preview Changes'
$btnPreview.Location = New-Object Drawing.Point(25, 688)
$btnPreview.Size = New-Object Drawing.Size(140, 35)
$form.Controls.Add($btnPreview)

$btnRestore = New-Object Windows.Forms.Button
$btnRestore.Text = L 'Restore Original'
$btnRestore.Location = New-Object Drawing.Point(175, 688)
$btnRestore.Size = New-Object Drawing.Size(140, 35)
$form.Controls.Add($btnRestore)

$btnUpdates = New-Object Windows.Forms.Button
$btnUpdates.Text = L 'Check for Updates'
$btnUpdates.Location = New-Object Drawing.Point(325, 688)
$btnUpdates.Size = New-Object Drawing.Size(130, 35)
$form.Controls.Add($btnUpdates)

$btnApply = New-Object Windows.Forms.Button
$btnApply.Text = L 'APPLY MODS'
$btnApply.Font = New-Object Drawing.Font('Segoe UI Semibold', 10)
$btnApply.BackColor = [Drawing.Color]::FromArgb(45,125,75)
$btnApply.ForeColor = [Drawing.Color]::White
$btnApply.FlatStyle = 'Flat'
$btnApply.Location = New-Object Drawing.Point(802, 688)
$btnApply.Size = New-Object Drawing.Size(200, 35)
$form.Controls.Add($btnApply)

$lblStatus = New-Object Windows.Forms.Label
$lblStatus.Text = L 'Ready.'
$lblStatus.Location = New-Object Drawing.Point(465, 696)
$lblStatus.Size = New-Object Drawing.Size(325, 25)
$lblStatus.TextAlign = 'MiddleLeft'
$form.Controls.Add($lblStatus)

$cmbLanguage.Add_SelectedIndexChanged({
    $codes = @($script:LanguageList | ForEach-Object { [string]$_.Code })
    if($cmbLanguage.SelectedIndex -ge 0 -and $cmbLanguage.SelectedIndex -lt $codes.Count){
        $newLang = [string]$codes[$cmbLanguage.SelectedIndex]
        if($newLang -ne $script:Language){
            $script:Language=$newLang; Save-Language
            [Windows.Forms.MessageBox]::Show((L 'Language saved. Restart the editor to apply the interface translation.'),$script:AppName,'OK','Information') | Out-Null
        }
    }
})

$btnUpdates.Add_Click({
    $oldStatus = $lblStatus.Text
    try {
        $form.UseWaitCursor = $true
        $lblStatus.Text = L 'Checking updates...'
        [Windows.Forms.Application]::DoEvents()
        [void](Test-ForEditorUpdate $true)
    }
    finally {
        $form.UseWaitCursor = $false
        $lblStatus.Text = $oldStatus
    }
})

$btnBrowse.Add_Click({
    $dialog = New-Object Windows.Forms.OpenFileDialog
    $dialog.Title = 'Select SnowRunner initial.pak'
    $dialog.Filter = 'SnowRunner initial.pak|initial.pak|PAK files|*.pak|All files|*.*'
    if ($txtPak.Text -and (Test-Path -LiteralPath $txtPak.Text)) { $dialog.InitialDirectory = [IO.Path]::GetDirectoryName($txtPak.Text) }
    if ($dialog.ShowDialog() -eq 'OK') { $txtPak.Text = $dialog.FileName; try { Refresh-TruckTargets } catch { $lblStatus.Text = 'Truck scan failed.' } }
})

$btnScanTrucks.Add_Click({ try { Refresh-TruckTargets; $lblStatus.Text = "Official truck list refreshed: $($lblTruckCount.Text) found and categorized." } catch { [Windows.Forms.MessageBox]::Show($_.Exception.Message, $script:AppName, 'OK', 'Error') | Out-Null; $lblStatus.Text='Truck scan failed.' } })
$btnScanMods.Add_Click({ try { $n = Show-ModScanDiagnostic; $lblStatus.Text = "Installed-mod scan complete: $n editable truck definition(s) found." } catch { [Windows.Forms.MessageBox]::Show($_.Exception.Message, $script:AppName, 'OK', 'Error') | Out-Null; $lblStatus.Text='Mod scan failed.' } })

$cmbTruck.Add_SelectedIndexChanged({
    if ($script:RefreshingTruckTargets) { return }
    $sel=if($cmbTruck.SelectedItem){[string]$cmbTruck.SelectedItem}else{''}
    if($script:CategoryHeadingLabels -contains $sel){
        $script:RefreshingTruckTargets=$true
        try{$cmbTruck.SelectedIndex=0}finally{$script:RefreshingTruckTargets=$false}
        $lblStatus.Text='Choose All in a category or an individual truck.'
        Set-TruckModeUi
        return
    }
    if ($script:CategoryTargets -and $script:CategoryTargets.ContainsKey($sel)) {
        $lblStatus.Text = "Category mode: $sel targets $(@($script:CategoryTargets[$sel]).Count) trucks. Preview before Apply."
    } elseif ($cmbTruck.SelectedIndex -gt 0) {
        $lblStatus.Text = 'Individual truck mode: Preview changes before Apply; shared component scope is reported.'
    } else { $lblStatus.Text = 'All Trucks mode: edits the base-game initial.pak.' }
    Set-TruckModeUi
})

$btnPreview.Add_Click({
    try {
        $form.UseWaitCursor = $true
        $lblStatus.Text = 'Scanning original values...'
        [Windows.Forms.Application]::DoEvents()
        if ($cmbTruck.SelectedItem -and ([string]$cmbTruck.SelectedItem -eq $script:AllModsPreviewLabel)) {
            $b=Invoke-AllModCompatibilityPreview
            $msg="Mod compatibility Preview complete.`r`n`r`nTested: $($b.Rows.Count)`r`nPASS: $($b.Pass)`r`nPASS WITH SKIPS: $($b.Skip)`r`nFAIL: $($b.Fail)`r`nSafely handled: $($b.Handled)/$($b.Rows.Count) ($($b.Percent)%)`r`n`r`nNo live mod PAKs were replaced.`r`n`r`nReport:`r`n$($b.Report)"
            [Windows.Forms.MessageBox]::Show($msg,$script:AppName,'OK','Information') | Out-Null
            $lblStatus.Text="Compatibility Preview: $($b.Handled)/$($b.Rows.Count) safely handled; $($b.Fail) failed."
        } else {
            $s = Get-Settings
            Save-Settings $s
            $r = if ($s.IsCategoryTarget) { Invoke-CategoryBatch $s $false } else { Process-Pak $s $false }
            [Windows.Forms.MessageBox]::Show((Format-Summary $r 'Preview complete - no files were changed.'), $script:AppName, 'OK', 'Information') | Out-Null
            $lblStatus.Text = "Preview: $($r.ModifiedFiles) XML files"
        }
    } catch { [Windows.Forms.MessageBox]::Show($_.Exception.Message, $script:AppName, 'OK', 'Error') | Out-Null; $lblStatus.Text='Preview failed.' }
    finally { $form.UseWaitCursor = $false }
})

$btnApply.Add_Click({
    try {
        if ($cmbTruck.SelectedItem -and ([string]$cmbTruck.SelectedItem -eq $script:AllModsPreviewLabel)) { throw 'Safety stop: the mod compatibility scan is Preview-only. Batch Apply is disabled.' }
        $s = Get-Settings
        if ($s.IsModTarget) { Assert-ModPak $s.ModPakPath $s.TargetTruckEntry } else { Assert-Pak $s.PakPath $true }
        Assert-SnowRunnerClosed
        $targetNote = if ($s.IsModTarget) { "Third-party MOD target: $($s.TargetTruck)`r`n`r`nOnly this selected mod PAK will be edited. Shared component families inside this same mod package may affect multiple variants contained by the mod. The pristine per-mod WL backup remains the calculation and Restore baseline.`r`n`r`nApply now?" } elseif ($s.IsCategoryTarget) { "CATEGORY TARGET: $($s.TargetTruck)`r`n`r`nThis will apply the current supported individual-truck settings to all $(@($s.TargetTruckIds).Count) trucks in this category in one optimized batch while preserving prior edits outside the category.`r`n`r`nShared component families may also affect other trucks that use the same definitions. Upgrade/addon prices and unlocks are scoped to this category. Other global-only controls remain disabled in category mode.`r`n`r`nApply now?" } elseif ($s.TargetTruckId) { "Target ONLY: $($s.TargetTruck)`r`n`r`nIndividual mode modifies the selected truck plus any EXISTING shared component families reported by Preview. Other trucks using those same engine/gearbox/tire/suspension/winch definitions may also be affected. Extreme Durability is always GLOBAL and affects the full base-game fleet.`r`n`r`nCargo Mass, Upgrade/Addon Prices, and Addon/Trailer COG remain global-only and disabled here. Unlock All Upgrades/Addons remains available because it is a GLOBAL toggle and its checked state is preserved across truck-target changes.`r`n`r`nApply now?" } else { 'Target: All Trucks`r`n`r`nSnowRunner is closed. Apply these settings to initial.pak now?' }
        $answer = [Windows.Forms.MessageBox]::Show($targetNote, $script:AppName, 'YesNo', 'Question')
        if ($answer -ne 'Yes') { return }
        $form.UseWaitCursor = $true
        $lblStatus.Text = if ($s.IsModTarget) { 'Building modified mod PAK...' } else { 'Building modified initial.pak...' }
        [Windows.Forms.Application]::DoEvents()
        Save-Settings $s
        $r = if ($s.IsCategoryTarget) { Invoke-CategoryBatch $s $true } else { Process-Pak $s $true }
        [Windows.Forms.MessageBox]::Show((Format-Summary $r 'Mods applied successfully.'), $script:AppName, 'OK', 'Information') | Out-Null
        $lblStatus.Text = "Applied: $($r.ModifiedFiles) XML files"
    } catch { [Windows.Forms.MessageBox]::Show($_.Exception.Message, $script:AppName, 'OK', 'Error') | Out-Null; $lblStatus.Text='Apply failed; original is safe.' }
    finally { $form.UseWaitCursor = $false }
})

$btnRestore.Add_Click({
    try {
        $s = Get-Settings
        Assert-SnowRunnerClosed
        if ($s.IsModTarget) {
            $pak=[IO.Path]::GetFullPath([string]$s.ModPakPath)
            Assert-ModPak $pak ([string]$s.TargetTruckEntry)
            $backup=Get-ModBackupPath $pak
            $metaPath=Get-ModBackupMetaPath $pak
            if(-not (Test-Path -LiteralPath $backup) -or -not (Test-Path -LiteralPath $metaPath)){
                throw 'No trusted pristine backup exists yet for this selected mod. Preview/Apply once after a fresh mod install to establish it.'
            }
            $meta=Get-Content -LiteralPath $metaPath -Raw | ConvertFrom-Json
            $backupHash=Get-FileSha256 $backup
            if($backupHash -ne $meta.BackupHash){throw 'The selected mod backup failed its WL hash check. Restore was cancelled.'}
            Assert-ModPak $backup ([string]$s.TargetTruckEntry)
            $answer=[Windows.Forms.MessageBox]::Show(("Restore this third-party mod PAK from its verified pristine WL backup?`r`n`r`n"+$pak),$script:AppName,'YesNo','Warning')
            if($answer -eq 'Yes'){
                $rollback=$pak+'.wl-restore-rollback'
                try{
                    [IO.File]::Copy($pak,$rollback,$true)
                    [IO.File]::Copy($backup,$pak,$true)
                    Assert-ModPak $pak ([string]$s.TargetTruckEntry)
                    if((Get-FileSha256 $pak) -ne $backupHash){throw 'Post-restore hash verification failed.'}
                    # The live file is now the pristine baseline; clear LastEditorOutputHash so a future
                    # Apply cannot mistake a stale edited output for the current live state.
                    $meta.LastEditorOutputHash=$null
                    $meta | ConvertTo-Json | Set-Content -LiteralPath $metaPath -Encoding UTF8
                    $lblStatus.Text='Selected mod restored from pristine backup.'
                    [Windows.Forms.MessageBox]::Show('The selected third-party mod PAK has been restored from its verified pristine backup.',$script:AppName,'OK','Information')|Out-Null
                }catch{
                    if(Test-Path -LiteralPath $rollback){[IO.File]::Copy($rollback,$pak,$true)}
                    throw
                }finally{Remove-Item -LiteralPath $rollback -Force -ErrorAction SilentlyContinue}
            }
        } else {
            Assert-Pak $txtPak.Text.Trim() $true
            $pak = [IO.Path]::GetFullPath($txtPak.Text.Trim())
            $backup = Get-BackupPath $pak
            $metaPath = Get-BackupMetaPath $pak
            if (-not (Test-Path -LiteralPath $backup) -or -not (Test-Path -LiteralPath $metaPath)) { throw 'No trusted current-version backup exists yet. Use Epic Games Verify, then run Preview once to establish a fresh backup.' }
            $meta = Get-Content -LiteralPath $metaPath -Raw | ConvertFrom-Json
            if ((Get-FileSha256 $backup) -ne $meta.BackupHash) { throw 'Backup safety check failed. Do not restore this backup. Use Epic Games Verify instead.' }
            $answer = [Windows.Forms.MessageBox]::Show('Replace initial.pak with the verified current-version original backup?', $script:AppName, 'YesNo', 'Warning')
            if ($answer -eq 'Yes') {
                [IO.File]::Copy($backup, $pak, $true)
                $lblStatus.Text = 'Original initial.pak restored.'
                [Windows.Forms.MessageBox]::Show('The original initial.pak has been restored.', $script:AppName, 'OK', 'Information') | Out-Null
            }
        }
    } catch { [Windows.Forms.MessageBox]::Show($_.Exception.Message, $script:AppName, 'OK', 'Error') | Out-Null }
})

Load-Settings
if ($txtPak.Text -and (Test-Path -LiteralPath $txtPak.Text)) { try { Refresh-TruckTargets } catch {} }
$script:StartupUpdateCheckDone = $false
$form.Add_Shown({
    if (-not $script:StartupUpdateCheckDone) {
        $script:StartupUpdateCheckDone = $true
        [Windows.Forms.Application]::DoEvents()
        [void](Test-ForEditorUpdate $false)
    }
})
[void]$form.ShowDialog()
