import 'package:flutter/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_localizations_de.dart';
import 'app_localizations_en.dart';

/// Application localizations.
///
/// Provides all user-facing strings for the app. Two locales are supported:
/// German (`de`) and English (`en`). English is used as the fallback for any
/// unsupported system language.
///
/// This is a hand-written implementation (no code generation) so it works
/// without an external build step.
abstract class AppLocalizations {
  AppLocalizations(this.localeName);

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// Delegates required to fully localize the app, including the Material,
  /// Widgets and Cupertino built-in localizations.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
  ];

  /// The locales this app supports.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('de'),
  ];

  // ---- Common ----
  String get cancel;
  String get save;
  String get ok;
  String get delete;
  String get remove;
  String get done;
  String get edit;
  String error(Object details);

  // ---- Device list ----
  String get appTitle;
  String get multiPcProReason;
  String get removeDeviceTitle;
  String removeDeviceConfirm(String name);
  String get neverSeen;
  String get onlineJustNow;
  String onlineMinutesAgo(int minutes);
  String onlineHoursAgo(int hours);
  String onlineDaysAgo(int days);
  String get refreshStatus;
  String get upgradeProReason;
  String get buyPro;
  String get addDevice;
  String get noDevicesConfigured;
  String get notPaired;
  String get settings;
  String get downloadPcAgent;

  // ---- Setup ----
  String get connecting;
  String get pairCodeInvalid;
  String connectionFailed(Object details);
  String get enterPairCode;
  String get searchingDevices;
  String get noAgentFound;
  String get tryingToPair;
  String searchError(Object details);
  String get deviceSettings;
  String get name;
  String get myPcHint;
  String get macAddress;
  String get ipAddress;
  String get port;
  String get repairOptional;
  String get pairDevice;
  String get repairHint;
  String get pairHint;
  String get pairCode;
  String get enterCode;
  String get connect;

  // ---- Home ----
  String get wolSent;
  String runScriptTitle(String name);
  String get runScriptConfirm;
  String get run;
  String scriptRunning(String name);
  String scriptSuccess(String name);
  String exitCode(Object code);
  String scriptFailed(String name);
  String get connectionError;
  String get editGroup;
  String get newGroup;
  String get groupName;
  String get scriptsLabel;
  String groupPrefix(String group);
  String chainDone(String name);
  String chainFailedSteps(String name, int count);
  String get errorTitle;
  String get pairCodeInvalidExpired;
  String get pairedSuccess;
  String get darkMode;
  String get pinLock;
  String get active;
  String get inactive;
  String get pinLockProReason;
  String get setPin;
  String get pinDigits;
  String get pinSet;
  String get changeOrder;
  String get thisSystem;
  String get allSystems;
  String get globalScriptsProReason;
  String get reorderProReason;
  String get wakeOnLan;
  String get wolHint;
  String get mouseKeyboard;
  String get volume;
  String get clipboard;
  String get screen;
  String get screenProReason;
  String get files;
  String get filesProReason;
  String get history;
  String get historyProReason;
  String get scripts;
  String get chains;
  String get categories;
  String sectionProReason(String section);
  String get dragToReorder;
  String get unlimitedScriptsReason;
  String get noGlobalScripts;
  String get noSystemScripts;
  String get noScriptsConfigured;
  String stepCount(int count);
  String get noChainsConfigured;
  String get noCategoriesConfigured;
  String scriptCount(int count);
  String get pcOffline;
  String get repair;
  String get repairCodeHint;
  String get pair;
  String get language;
  String get languageSystem;

  // ---- History ----
  String get clearHistory;
  String get clearHistoryConfirm;
  String get scriptHistory;
  String get noHistory;
  String get unknown;
  String get noOutput;

  // ---- File explorer ----
  String get fileOpeningOnPc;
  String downloading(String name);
  String serverError(Object code);
  String savedAs(String name);
  String downloadFailed(Object details);
  String get folder;
  String get download;
  String get openOnPc;
  String get openFolder;
  String get pcFiles;
  String get empty;

  // ---- Input control ----
  String get touchpad;
  String get touchpadHint;
  String get left;
  String get right;
  String get scroll;
  String get typeText;

  // ---- Paywall ----
  String get purchaseCancelled;
  String get storeUnavailable;
  String get productNotFound;
  String get pcConnectorPro;
  String get featureUnlimitedScripts;
  String get featureChains;
  String get featureCategories;
  String get featureMultiPc;
  String get featureGlobalScripts;
  String get featureReorder;
  String get unlockPro;
  String get restorePurchase;

  // ---- Clipboard ----
  String get copiedToPcClipboard;
  String get copiedToPhoneClipboard;
  String get clipboardTitle;
  String get pcClipboard;
  String get emptyParens;
  String get copyToPhone;
  String get sendToPcLabel;
  String get enterTextHint;
  String get paste;
  String get sendToPc;

  // ---- Screen view ----
  String get quality;
  String get qualityLow;
  String get qualityMedium;
  String get qualityHigh;
  String get noImage;

  // ---- Script result ----
  String get successful;
  String get failed;
  String exitCodeLabel(Object code);
  String get outputStdout;
  String get errorStderr;

  // ---- PIN lock ----
  String get wrongPin;
  String get enterPin;

  // ---- Storage ----
  String duplicatePc(String address, String name);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) async {
    switch (locale.languageCode) {
      case 'de':
        return AppLocalizationsDe();
      case 'en':
      default:
        return AppLocalizationsEn();
    }
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'de'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
