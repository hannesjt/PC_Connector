import 'app_localizations.dart';

/// English (`en`) localization — also the fallback for unsupported languages.
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([super.localeName = 'en']);

  // ---- Common ----
  @override
  String get cancel => 'Cancel';
  @override
  String get save => 'Save';
  @override
  String get ok => 'OK';
  @override
  String get delete => 'Delete';
  @override
  String get remove => 'Remove';
  @override
  String get done => 'Done';
  @override
  String get edit => 'Edit';
  @override
  String error(Object details) => 'Error: $details';

  // ---- Device list ----
  @override
  String get appTitle => 'PC Connector';
  @override
  String get multiPcProReason =>
      'With Pro you can manage multiple PCs (Free: 1 PC).';
  @override
  String get removeDeviceTitle => 'Remove device?';
  @override
  String removeDeviceConfirm(String name) =>
      'Do you really want to remove "$name"?';
  @override
  String get neverSeen => 'Never seen';
  @override
  String get onlineJustNow => 'Online just now';
  @override
  String onlineMinutesAgo(int minutes) => 'Online $minutes min ago';
  @override
  String onlineHoursAgo(int hours) => 'Online $hours h ago';
  @override
  String onlineDaysAgo(int days) =>
      'Online $days ${days == 1 ? 'day' : 'days'} ago';
  @override
  String get refreshStatus => 'Refresh status';
  @override
  String get upgradeProReason => 'Upgrade to Pro and unlock all features.';
  @override
  String get buyPro => 'Buy Pro';
  @override
  String get addDevice => 'Add device';
  @override
  String get noDevicesConfigured => 'No devices configured.';
  @override
  String get notPaired => 'Not paired';
  @override
  String get settings => 'Settings';
  @override
  String get downloadPcAgent =>
      'Download PC Agent  \u2192  github.com/hannesjt/PC_Connector';

  // ---- Setup ----
  @override
  String get connecting => 'Connecting...';
  @override
  String get pairCodeInvalid => 'Pairing code invalid or expired';
  @override
  String connectionFailed(Object details) => 'Connection failed: $details';
  @override
  String get enterPairCode => 'Please enter a pairing code';
  @override
  String get searchingDevices => 'Searching for devices on the network...';
  @override
  String get noAgentFound =>
      'No PC Agent found on the network. Is the agent running?';
  @override
  String get tryingToPair => 'Trying to pair...';
  @override
  String searchError(Object details) => 'Error during search: $details';
  @override
  String get deviceSettings => 'Device settings';
  @override
  String get name => 'Name';
  @override
  String get myPcHint => 'My PC';
  @override
  String get macAddress => 'MAC address';
  @override
  String get ipAddress => 'IP address';
  @override
  String get port => 'Port';
  @override
  String get repairOptional => 'Re-pair (optional)';
  @override
  String get pairDevice => 'Pair device';
  @override
  String get repairHint =>
      'Only fill this in if you want to re-pair the device.';
  @override
  String get pairHint =>
      'Open the web interface on your PC and generate a pairing code.';
  @override
  String get pairCode => 'Pairing code';
  @override
  String get enterCode => 'Enter code';
  @override
  String get connect => 'Connect';

  // ---- Home ----
  @override
  String get wolSent => 'Wake-on-LAN packet sent!';
  @override
  String runScriptTitle(String name) => 'Run $name?';
  @override
  String get runScriptConfirm => 'Do you really want to run this script?';
  @override
  String get run => 'Run';
  @override
  String scriptRunning(String name) => 'Running $name...';
  @override
  String scriptSuccess(String name) => '$name ran successfully';
  @override
  String exitCode(Object code) => 'Exit code $code';
  @override
  String scriptFailed(String name) => '$name failed';
  @override
  String get connectionError => 'Connection error';
  @override
  String get editGroup => 'Edit group';
  @override
  String get newGroup => 'New group';
  @override
  String get groupName => 'Group name';
  @override
  String get scriptsLabel => 'Scripts:';
  @override
  String groupPrefix(String group) => 'Group: $group';
  @override
  String chainDone(String name) => '$name completed';
  @override
  String chainFailedSteps(String name, int count) =>
      '$name: $count ${count == 1 ? 'step' : 'steps'} failed';
  @override
  String get errorTitle => 'Error';
  @override
  String get pairCodeInvalidExpired => 'Pairing code invalid or expired';
  @override
  String get pairedSuccess => 'Paired successfully!';
  @override
  String get darkMode => 'Dark Mode';
  @override
  String get pinLock => 'PIN lock';
  @override
  String get active => 'Active';
  @override
  String get inactive => 'Inactive';
  @override
  String get pinLockProReason => 'PIN lock is a Pro feature.';
  @override
  String get setPin => 'Set PIN';
  @override
  String get pinDigits => '4-digit PIN';
  @override
  String get pinSet => 'PIN has been set';
  @override
  String get changeOrder => 'Change order';
  @override
  String get thisSystem => 'This system';
  @override
  String get allSystems => 'All systems';
  @override
  String get globalScriptsProReason => 'Global scripts are a Pro feature.';
  @override
  String get reorderProReason => 'Reordering is a Pro feature.';
  @override
  String get wakeOnLan => 'Wake on LAN';
  @override
  String get wolHint =>
      'Wake-on-LAN must be enabled in the BIOS and the PC network adapter settings.';
  @override
  String get mouseKeyboard => 'Mouse & keyboard';
  @override
  String get volume => 'Volume';
  @override
  String get clipboard => 'Clipboard';
  @override
  String get screen => 'Screen';
  @override
  String get screenProReason => 'Screen streaming is a Pro feature.';
  @override
  String get files => 'Files';
  @override
  String get filesProReason => 'The file explorer is a Pro feature.';
  @override
  String get history => 'History';
  @override
  String get historyProReason => 'Script history is a Pro feature.';
  @override
  String get scripts => 'Scripts';
  @override
  String get chains => 'Chains';
  @override
  String get categories => 'Categories';
  @override
  String sectionProReason(String section) => '$section are a Pro feature.';
  @override
  String get dragToReorder => 'Drag to reorder';
  @override
  String get unlimitedScriptsReason =>
      'With Pro you can use unlimited scripts (Free: 3).';
  @override
  String get noGlobalScripts => 'No cross-system scripts configured.';
  @override
  String get noSystemScripts => 'No system-specific scripts configured.';
  @override
  String get noScriptsConfigured => 'No scripts configured.';
  @override
  String stepCount(int count) => '$count ${count == 1 ? 'step' : 'steps'}';
  @override
  String get noChainsConfigured => 'No chains configured.';
  @override
  String get noCategoriesConfigured =>
      'No categories configured.\nGroups can be assigned in the web interface.';
  @override
  String scriptCount(int count) =>
      '$count ${count == 1 ? 'script' : 'scripts'}';
  @override
  String get pcOffline => 'PC is offline. Send Wake-on-LAN to start it.';
  @override
  String get repair => 'Re-pair';
  @override
  String get repairCodeHint =>
      'Enter the pairing code from the PC Agent to connect.';
  @override
  String get pair => 'Pair';
  @override
  String get language => 'Language';
  @override
  String get languageSystem => 'System';

  // ---- History ----
  @override
  String get clearHistory => 'Clear history';
  @override
  String get clearHistoryConfirm => 'Clear entire history?';
  @override
  String get scriptHistory => 'Script history';
  @override
  String get noHistory => 'No history';
  @override
  String get unknown => 'Unknown';
  @override
  String get noOutput => '(no output)';

  // ---- File explorer ----
  @override
  String get fileOpeningOnPc => 'Opening file on the PC';
  @override
  String downloading(String name) => 'Downloading "$name"...';
  @override
  String serverError(Object code) => 'Server error $code';
  @override
  String savedAs(String name) => 'Saved: $name';
  @override
  String downloadFailed(Object details) => 'Download failed: $details';
  @override
  String get folder => 'Folder';
  @override
  String get download => 'Download';
  @override
  String get openOnPc => 'Open on PC';
  @override
  String get openFolder => 'Open folder';
  @override
  String get pcFiles => 'PC files';
  @override
  String get empty => 'Empty';

  // ---- Input control ----
  @override
  String get touchpad => 'Touchpad';
  @override
  String get touchpadHint => 'Tap = left click \u00b7 Hold = right click';
  @override
  String get left => 'Left';
  @override
  String get right => 'Right';
  @override
  String get scroll => 'Scroll';
  @override
  String get typeText => 'Type text...';

  // ---- Paywall ----
  @override
  String get purchaseCancelled => 'Purchase cancelled';
  @override
  String get storeUnavailable => 'Google Play not available';
  @override
  String get productNotFound => 'Product not found. Please try again later.';
  @override
  String get pcConnectorPro => 'PC Connector Pro';
  @override
  String get featureUnlimitedScripts => 'Unlimited scripts (Free: 3)';
  @override
  String get featureChains => 'Chains & script chains';
  @override
  String get featureCategories => 'Categories & groups';
  @override
  String get featureMultiPc => 'Multiple PC profiles';
  @override
  String get featureGlobalScripts => 'Global scripts';
  @override
  String get featureReorder => 'Reordering';
  @override
  String get unlockPro => 'Unlock Pro \u2013 \u20ac3/month';
  @override
  String get restorePurchase => 'Restore purchase';

  // ---- Clipboard ----
  @override
  String get copiedToPcClipboard => 'Copied to PC clipboard';
  @override
  String get copiedToPhoneClipboard => 'Copied to phone clipboard';
  @override
  String get clipboardTitle => 'Clipboard';
  @override
  String get pcClipboard => 'PC clipboard:';
  @override
  String get emptyParens => '(empty)';
  @override
  String get copyToPhone => 'Copy to phone';
  @override
  String get sendToPcLabel => 'Send to PC:';
  @override
  String get enterTextHint => 'Enter text...';
  @override
  String get paste => 'Paste';
  @override
  String get sendToPc => 'Send to PC';

  // ---- Screen view ----
  @override
  String get quality => 'Quality';
  @override
  String get qualityLow => 'Low';
  @override
  String get qualityMedium => 'Medium';
  @override
  String get qualityHigh => 'High';
  @override
  String get noImage => 'No image';

  // ---- Script result ----
  @override
  String get successful => 'Successful';
  @override
  String get failed => 'Failed';
  @override
  String exitCodeLabel(Object code) => 'Exit code: $code';
  @override
  String get outputStdout => 'Output (stdout)';
  @override
  String get errorStderr => 'Error (stderr)';

  // ---- PIN lock ----
  @override
  String get wrongPin => 'Wrong PIN';
  @override
  String get enterPin => 'Enter PIN';

  // ---- Storage ----
  @override
  String duplicatePc(String address, String name) =>
      'A PC with the address $address already exists ($name).';
}
