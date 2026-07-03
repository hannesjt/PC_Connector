import 'app_localizations.dart';

/// German (`de`) localization.
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([super.localeName = 'de']);

  // ---- Common ----
  @override
  String get cancel => 'Abbrechen';
  @override
  String get save => 'Speichern';
  @override
  String get ok => 'OK';
  @override
  String get delete => 'Löschen';
  @override
  String get remove => 'Entfernen';
  @override
  String get done => 'Fertig';
  @override
  String get edit => 'Bearbeiten';
  @override
  String error(Object details) => 'Fehler: $details';

  // ---- Device list ----
  @override
  String get appTitle => 'PC Connector';
  @override
  String get multiPcProReason =>
      'Mit Pro kannst du mehrere PCs verwalten (Gratis: 1 PC).';
  @override
  String get removeDeviceTitle => 'Gerät entfernen?';
  @override
  String removeDeviceConfirm(String name) =>
      'Möchtest du "$name" wirklich entfernen?';
  @override
  String get neverSeen => 'Noch nie gesehen';
  @override
  String get onlineJustNow => 'Gerade eben online';
  @override
  String onlineMinutesAgo(int minutes) => 'Vor $minutes Min. online';
  @override
  String onlineHoursAgo(int hours) => 'Vor $hours Std. online';
  @override
  String onlineDaysAgo(int days) => 'Vor $days Tag(en) online';
  @override
  String get refreshStatus => 'Status aktualisieren';
  @override
  String get upgradeProReason =>
      'Upgrade auf Pro und schalte alle Features frei.';
  @override
  String get buyPro => 'Pro kaufen';
  @override
  String get addDevice => 'Gerät hinzufügen';
  @override
  String get noDevicesConfigured => 'Keine Geräte konfiguriert.';
  @override
  String get notPaired => 'Nicht gekoppelt';
  @override
  String get settings => 'Einstellungen';
  @override
  String get downloadPcAgent =>
      'PC-Agent herunterladen  \u2192  github.com/hannesjt/PC_Connector';

  // ---- Setup ----
  @override
  String get connecting => 'Verbinde...';
  @override
  String get pairCodeInvalid => 'Kopplungscode ungültig oder abgelaufen';
  @override
  String connectionFailed(Object details) =>
      'Verbindung fehlgeschlagen: $details';
  @override
  String get enterPairCode => 'Bitte Kopplungscode eingeben';
  @override
  String get searchingDevices => 'Suche Geräte im Netzwerk...';
  @override
  String get noAgentFound =>
      'Kein PC-Agent im Netzwerk gefunden. Ist der Agent gestartet?';
  @override
  String get tryingToPair => 'Versuche Kopplung...';
  @override
  String searchError(Object details) => 'Fehler bei der Suche: $details';
  @override
  String get deviceSettings => 'Geräteeinstellungen';
  @override
  String get name => 'Name';
  @override
  String get myPcHint => 'Mein PC';
  @override
  String get macAddress => 'MAC-Adresse';
  @override
  String get ipAddress => 'IP-Adresse';
  @override
  String get port => 'Port';
  @override
  String get repairOptional => 'Erneut koppeln (optional)';
  @override
  String get pairDevice => 'Gerät koppeln';
  @override
  String get repairHint =>
      'Nur ausfüllen, wenn du das Gerät neu koppeln möchtest.';
  @override
  String get pairHint =>
      'Öffne die Web-Oberfläche auf deinem PC und generiere einen Kopplungscode.';
  @override
  String get pairCode => 'Kopplungscode';
  @override
  String get enterCode => 'Code eingeben';
  @override
  String get connect => 'Verbinden';

  // ---- Home ----
  @override
  String get wolSent => 'Wake-on-LAN Paket gesendet!';
  @override
  String runScriptTitle(String name) => '$name ausführen?';
  @override
  String get runScriptConfirm =>
      'Möchtest du dieses Skript wirklich ausführen?';
  @override
  String get run => 'Ausführen';
  @override
  String scriptRunning(String name) => '$name wird ausgeführt...';
  @override
  String scriptSuccess(String name) => '$name erfolgreich ausgeführt';
  @override
  String exitCode(Object code) => 'Exit-Code $code';
  @override
  String scriptFailed(String name) => '$name fehlgeschlagen';
  @override
  String get connectionError => 'Verbindungsfehler';
  @override
  String get editGroup => 'Gruppe bearbeiten';
  @override
  String get newGroup => 'Neue Gruppe';
  @override
  String get groupName => 'Gruppenname';
  @override
  String get scriptsLabel => 'Skripte:';
  @override
  String groupPrefix(String group) => 'Gruppe: $group';
  @override
  String chainDone(String name) => '$name abgeschlossen';
  @override
  String chainFailedSteps(String name, int count) =>
      '$name: $count Schritt(e) fehlgeschlagen';
  @override
  String get errorTitle => 'Fehler';
  @override
  String get pairCodeInvalidExpired => 'Kopplungscode ungültig oder abgelaufen';
  @override
  String get pairedSuccess => 'Erfolgreich gekoppelt!';
  @override
  String get darkMode => 'Dark Mode';
  @override
  String get pinLock => 'PIN-Sperre';
  @override
  String get active => 'Aktiv';
  @override
  String get inactive => 'Inaktiv';
  @override
  String get pinLockProReason => 'PIN-Sperre ist ein Pro-Feature.';
  @override
  String get setPin => 'PIN festlegen';
  @override
  String get pinDigits => '4-stellige PIN';
  @override
  String get pinSet => 'PIN wurde gesetzt';
  @override
  String get changeOrder => 'Reihenfolge ändern';
  @override
  String get thisSystem => 'Dieses System';
  @override
  String get allSystems => 'Alle Systeme';
  @override
  String get globalScriptsProReason => 'Globale Skripte sind ein Pro-Feature.';
  @override
  String get reorderProReason => 'Reihenfolge anpassen ist ein Pro-Feature.';
  @override
  String get wakeOnLan => 'Wake on LAN';
  @override
  String get wolHint =>
      'Wake-on-LAN muss im BIOS und in den Netzwerkadaptereinstellungen des PCs aktiviert sein.';
  @override
  String get mouseKeyboard => 'Maus & Tastatur';
  @override
  String get volume => 'Lautstärke';
  @override
  String get clipboard => 'Clipboard';
  @override
  String get screen => 'Bildschirm';
  @override
  String get screenProReason => 'Bildschirmübertragung ist ein Pro-Feature.';
  @override
  String get files => 'Dateien';
  @override
  String get filesProReason => 'Datei-Explorer ist ein Pro-Feature.';
  @override
  String get history => 'Verlauf';
  @override
  String get historyProReason => 'Skript-Verlauf ist ein Pro-Feature.';
  @override
  String get scripts => 'Skripte';
  @override
  String get chains => 'Abläufe';
  @override
  String get categories => 'Kategorien';
  @override
  String sectionProReason(String section) => '$section sind ein Pro-Feature.';
  @override
  String get dragToReorder => 'Zum Umsortieren ziehen';
  @override
  String get unlimitedScriptsReason =>
      'Mit Pro kannst du unbegrenzt viele Skripte nutzen (Gratis: 3).';
  @override
  String get noGlobalScripts =>
      'Keine systemübergreifenden Skripte konfiguriert.';
  @override
  String get noSystemScripts =>
      'Keine systemspezifischen Skripte konfiguriert.';
  @override
  String get noScriptsConfigured => 'Keine Skripte konfiguriert.';
  @override
  String stepCount(int count) => '$count Schritt${count == 1 ? '' : 'e'}';
  @override
  String get noChainsConfigured => 'Keine Abläufe konfiguriert.';
  @override
  String get noCategoriesConfigured =>
      'Keine Kategorien konfiguriert.\nGruppen können in der Web-Oberfläche vergeben werden.';
  @override
  String scriptCount(int count) => '$count Skript${count == 1 ? '' : 'e'}';
  @override
  String get pcOffline => 'PC ist offline. Sende Wake-on-LAN zum Starten.';
  @override
  String get repair => 'Neu koppeln';
  @override
  String get repairCodeHint =>
      'Gib den Kopplungscode vom PC-Agent ein, um dich zu verbinden.';
  @override
  String get pair => 'Koppeln';
  @override
  String get language => 'Sprache';
  @override
  String get languageSystem => 'System';

  // ---- History ----
  @override
  String get clearHistory => 'Verlauf löschen';
  @override
  String get clearHistoryConfirm => 'Gesamten Verlauf löschen?';
  @override
  String get scriptHistory => 'Skript-Verlauf';
  @override
  String get noHistory => 'Kein Verlauf';
  @override
  String get unknown => 'Unbekannt';
  @override
  String get noOutput => '(kein Output)';

  // ---- File explorer ----
  @override
  String get fileOpeningOnPc => 'Datei wird auf dem PC geöffnet';
  @override
  String downloading(String name) => 'Lade "$name" herunter...';
  @override
  String serverError(Object code) => 'Server-Fehler $code';
  @override
  String savedAs(String name) => 'Gespeichert: $name';
  @override
  String downloadFailed(Object details) => 'Download fehlgeschlagen: $details';
  @override
  String get folder => 'Ordner';
  @override
  String get download => 'Herunterladen';
  @override
  String get openOnPc => 'Auf PC öffnen';
  @override
  String get openFolder => 'Ordner öffnen';
  @override
  String get pcFiles => 'PC-Dateien';
  @override
  String get empty => 'Leer';

  // ---- Input control ----
  @override
  String get touchpad => 'Touchpad';
  @override
  String get touchpadHint => 'Tippen = Linksklick \u00b7 Halten = Rechtsklick';
  @override
  String get left => 'Links';
  @override
  String get right => 'Rechts';
  @override
  String get scroll => 'Scroll';
  @override
  String get typeText => 'Text tippen...';

  // ---- Paywall ----
  @override
  String get purchaseCancelled => 'Kauf abgebrochen';
  @override
  String get storeUnavailable => 'Google Play nicht verfügbar';
  @override
  String get productNotFound =>
      'Produkt nicht gefunden. Bitte später erneut versuchen.';
  @override
  String get pcConnectorPro => 'PC Connector Pro';
  @override
  String get featureUnlimitedScripts => 'Unbegrenzte Skripte (Gratis: 3)';
  @override
  String get featureChains => 'Abläufe & Script-Chains';
  @override
  String get featureCategories => 'Kategorien & Gruppen';
  @override
  String get featureMultiPc => 'Mehrere PC-Profile';
  @override
  String get featureGlobalScripts => 'Globale Skripte';
  @override
  String get featureReorder => 'Reihenfolge anpassen';
  @override
  String get unlockPro => 'Pro freischalten \u2013 3 \u20ac/Monat';
  @override
  String get restorePurchase => 'Kauf wiederherstellen';

  // ---- Clipboard ----
  @override
  String get copiedToPcClipboard => 'In PC-Zwischenablage kopiert';
  @override
  String get copiedToPhoneClipboard => 'In Handy-Zwischenablage kopiert';
  @override
  String get clipboardTitle => 'Zwischenablage';
  @override
  String get pcClipboard => 'PC-Zwischenablage:';
  @override
  String get emptyParens => '(leer)';
  @override
  String get copyToPhone => 'Auf Handy kopieren';
  @override
  String get sendToPcLabel => 'An PC senden:';
  @override
  String get enterTextHint => 'Text eingeben...';
  @override
  String get paste => 'Einfügen';
  @override
  String get sendToPc => 'An PC senden';

  // ---- Screen view ----
  @override
  String get quality => 'Qualität';
  @override
  String get qualityLow => 'Niedrig';
  @override
  String get qualityMedium => 'Mittel';
  @override
  String get qualityHigh => 'Hoch';
  @override
  String get noImage => 'Kein Bild';

  // ---- Script result ----
  @override
  String get successful => 'Erfolgreich';
  @override
  String get failed => 'Fehlgeschlagen';
  @override
  String exitCodeLabel(Object code) => 'Exit-Code: $code';
  @override
  String get outputStdout => 'Ausgabe (stdout)';
  @override
  String get errorStderr => 'Fehler (stderr)';

  // ---- PIN lock ----
  @override
  String get wrongPin => 'Falsche PIN';
  @override
  String get enterPin => 'PIN eingeben';

  // ---- Storage ----
  @override
  String duplicatePc(String address, String name) =>
      'Ein PC mit der Adresse $address ist bereits vorhanden ($name).';
}
