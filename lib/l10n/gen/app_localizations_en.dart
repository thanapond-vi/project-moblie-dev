// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get tagline =>
      'Read · Recall · Summarize — practice with Active Recall';

  @override
  String get cancel => 'Cancel';

  @override
  String get retry => 'Try again';

  @override
  String get save => 'Save';

  @override
  String get discard => 'Discard';

  @override
  String get delete => 'Delete';

  @override
  String get continueLabel => 'Continue';

  @override
  String minutesValue(int count) {
    return '$count min';
  }

  @override
  String get login => 'Login';

  @override
  String get register => 'Register';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get confirmPassword => 'Confirm password';

  @override
  String get showPassword => 'Show password';

  @override
  String get hidePassword => 'Hide password';

  @override
  String get haveAccount => 'Already have an account? Login';

  @override
  String get noAccount => 'Don\'t have an account? Register';

  @override
  String get vEmailRequired => 'Please enter your email';

  @override
  String get vEmailInvalid => 'Invalid email format';

  @override
  String get vPasswordRequired => 'Please enter your password';

  @override
  String vPasswordMin(int min) {
    return 'Password must be at least $min characters';
  }

  @override
  String get vConfirmRequired => 'Please confirm your password';

  @override
  String get vPasswordMismatch => 'Passwords do not match';

  @override
  String get vSummaryRequired => 'Please write the key points';

  @override
  String vSummaryMin(int min, int count) {
    return 'Too short — at least $min characters (now $count)';
  }

  @override
  String get vNicknameRequired => 'Please enter a nickname';

  @override
  String vNicknameLength(int min, int max) {
    return 'Nickname must be $min–$max characters';
  }

  @override
  String get errNoInternet => 'No internet connection';

  @override
  String get errTimeout => 'The connection took too long. Please try again.';

  @override
  String get errGeneric => 'Something went wrong. Please try again.';

  @override
  String errGenericCode(String code) {
    return 'Something went wrong ($code)';
  }

  @override
  String get errUserDisabled => 'This account has been disabled';

  @override
  String get errWrongCredentials => 'Incorrect email or password';

  @override
  String get errEmailInUse => 'This email is already registered';

  @override
  String get errWeakPassword => 'Password is too weak';

  @override
  String get errTooManyRequests => 'Too many attempts. Please wait a moment.';

  @override
  String get errAuthNotEnabled =>
      'Email/Password sign-in is not enabled in Firebase Console';

  @override
  String get errPermissionDenied =>
      'You don\'t have permission to access this data';

  @override
  String get errDbUnavailable =>
      'Can\'t reach the database. Check your internet.';

  @override
  String errSaveFailed(String code) {
    return 'Could not save ($code)';
  }

  @override
  String get errDbTimeout =>
      'The database is responding slowly. Please try again.';

  @override
  String get errArticleEmpty =>
      'This article has no content. Please try another.';

  @override
  String get errNoArticle => 'No article found. Please try again.';

  @override
  String get errWikiTimeout =>
      'Wikipedia is responding slowly. Please try again.';

  @override
  String get errWikiLoad => 'Could not load the article. Please try again.';

  @override
  String get errWikiRateLimit =>
      'Too many requests. Please wait a moment and try again.';

  @override
  String errWikiStatus(String code) {
    return 'Wikipedia returned an error ($code)';
  }

  @override
  String get errAiNotConfigured =>
      'AI is not set up (add GROQ_API_KEY to .env)';

  @override
  String get errAiBadKey => 'The Groq API key is invalid';

  @override
  String errAiModelNotFound(String model) {
    return 'Model $model was not found on Groq (check GROQ_MODEL in .env)';
  }

  @override
  String get errAiRateLimit =>
      'AI is being used too often. Please wait and try again.';

  @override
  String errAiStatus(String code) {
    return 'AI returned an error ($code)';
  }

  @override
  String get errAiTimeout => 'AI took too long. Please try again.';

  @override
  String get errAiConnect => 'Can\'t reach the AI. Check your internet.';

  @override
  String get errAiRead => 'Could not read the AI result. Please try again.';

  @override
  String get errAiBadFormat => 'The AI replied in an unreadable format';

  @override
  String get errAiNoScore => 'The AI did not return a score';

  @override
  String get aiNoFeedback => 'No feedback';

  @override
  String errTtsNoVoice(String language) {
    return 'This device has no $language voice';
  }

  @override
  String get errImageTooLarge =>
      'The image is too large. Please choose another one.';

  @override
  String get errLoginAgain => 'Please log in again';

  @override
  String get errProfilePermission =>
      'You don\'t have permission to save this profile';

  @override
  String errProfileSave(String code) {
    return 'Could not save your profile ($code)';
  }

  @override
  String errFirebaseInit(String message) {
    return 'Could not connect to Firebase\n\n$message';
  }

  @override
  String helloName(String name) {
    return 'Hello, $name';
  }

  @override
  String get greetingFallback => 'What will you learn today?';

  @override
  String get profileSettingsTooltip => 'Profile & Settings';

  @override
  String get randomArticle => 'Random article';

  @override
  String get finishCurrentFirst => 'Finish the current one';

  @override
  String get sessionLockedMessage =>
      'You have an article in progress. Finish its summary before starting a new one.';

  @override
  String get sessionReading => 'Reading · Paused';

  @override
  String get sessionSummarizing => 'Finished · Awaiting summary';

  @override
  String timeLeft(String time) {
    return '$time left';
  }

  @override
  String readForMinutes(int count) {
    return 'Read $count min';
  }

  @override
  String get tapToResume => 'Tap to keep reading';

  @override
  String get tapToSummarize => 'Tap to continue your summary';

  @override
  String get options => 'Options';

  @override
  String get discardArticle => 'Discard this article';

  @override
  String get discardSessionTitle => 'Discard the article in progress?';

  @override
  String discardSessionMessage(String title) {
    return '\"$title\" and your draft summary will be removed. Then you can start a new article.';
  }

  @override
  String get statRead => 'Articles read';

  @override
  String get statAvgScore => 'Average score';

  @override
  String get statTotalTime => 'Total reading';

  @override
  String get unitArticles => 'articles';

  @override
  String get unitMinutes => 'min';

  @override
  String get statAllTime => 'All time';

  @override
  String get emptyTitle => 'No reading history yet';

  @override
  String get emptyBody =>
      'Tap \"Random article\" to start, then summarize it from memory.';

  @override
  String get deleteLogTitle => 'Delete this entry?';

  @override
  String deleteLogMessage(String title) {
    return '\"$title\" will be deleted permanently.';
  }

  @override
  String deletedMessage(String title) {
    return 'Deleted \"$title\"';
  }

  @override
  String get notEvaluated => 'Not evaluated';

  @override
  String historyLoadError(String error) {
    return 'Could not load your history\n$error';
  }

  @override
  String get readingTitle => 'Reading';

  @override
  String get searchMore => 'Search for more';

  @override
  String get pauseForLater => 'Pause and read later';

  @override
  String get pausedMessage =>
      'Reading paused. Tap the card on the home screen to continue.';

  @override
  String get timeUpTitle => 'Time\'s up';

  @override
  String get timeUpBody =>
      'Now summarize the key points from memory, without looking back at the article.';

  @override
  String get goSummarize => 'Write summary';

  @override
  String get finishedReading => 'Done reading — write summary';

  @override
  String get loadingArticle => 'Picking a random article from Wikipedia...';

  @override
  String charCount(int count) {
    return '$count characters';
  }

  @override
  String get timerRunning => 'Timer running';

  @override
  String get timerPaused => 'Paused';

  @override
  String get pauseTimer => 'Pause';

  @override
  String get resumeTimer => 'Resume timer';

  @override
  String get ttsPlay => 'Listen';

  @override
  String get ttsPause => 'Pause voice';

  @override
  String get ttsStop => 'Stop voice';

  @override
  String ttsReading(int current, int total) {
    return 'Reading paragraph $current/$total';
  }

  @override
  String ttsPausedAt(int current, int total) {
    return 'Paused at paragraph $current/$total';
  }

  @override
  String get ttsIdle => 'Listen to this article';

  @override
  String get ttsError => 'Could not start the voice reader';

  @override
  String get linkError => 'Could not open the link';

  @override
  String get searchGoogle => 'Search on Google';

  @override
  String get openWikipedia => 'Open the Wikipedia page';

  @override
  String get openWikipediaSub => 'See images, tables and references';

  @override
  String get writeSummaryTitle => 'Write summary';

  @override
  String get editSummaryTitle => 'Edit summary';

  @override
  String get recallHint =>
      'Summarize the key points from memory — no peeking at the article.';

  @override
  String get editHint =>
      'Edit your summary, then let the AI evaluate it again.';

  @override
  String get summaryHint =>
      'What is this article about? What are the main points?';

  @override
  String summaryCounter(int count, int min) {
    return '$count characters (at least $min)';
  }

  @override
  String get aiEvaluating => 'AI is evaluating...';

  @override
  String get saving => 'Saving...';

  @override
  String get evaluateAndSave => 'Evaluate with AI & save';

  @override
  String get reevaluateAndSave => 'Re-evaluate & save';

  @override
  String earnedMinutes(int count) {
    return '+$count min added to your total';
  }

  @override
  String get viewOriginal => 'View the original article';

  @override
  String get viewOriginalSub => 'The part the AI compared against';

  @override
  String get doneBackHome => 'Done — back to home';

  @override
  String get staleScore =>
      'This score is for your previous text. Evaluate again to update it.';

  @override
  String get scoreLabel => 'Understanding score';

  @override
  String get notEvaluatedYet => 'Not evaluated yet';

  @override
  String scoreOutOf(int score) {
    return '$score / 100';
  }

  @override
  String evaluatedBy(String model) {
    return 'Evaluated by Groq · $model';
  }

  @override
  String get aiFeedbackTitle => 'AI Feedback';

  @override
  String get aiFailed => 'AI evaluation failed';

  @override
  String get saveWithoutScore => 'Save for now (no score)';

  @override
  String get savedMessage => 'Saved';

  @override
  String get removeScoreTitle => 'Remove the old score?';

  @override
  String get removeScoreMessage =>
      'The old score belongs to your previous text. Saving now will mark it as \"not evaluated\".';

  @override
  String get discardDraftTitle => 'Discard your text?';

  @override
  String get discardDraftMessage => 'Your unsaved summary will be lost.';

  @override
  String get tagsTitle => 'Tags (up to 3)';

  @override
  String get tagsHint =>
      'The AI suggests tags after evaluating. Tap to change.';

  @override
  String get tagsLimit => 'You can pick up to 3 tags';

  @override
  String get tagTechnology => 'Technology';

  @override
  String get tagScience => 'Science';

  @override
  String get tagHistory => 'History';

  @override
  String get tagBiographies => 'Biographies';

  @override
  String get tagCulture => 'Culture';

  @override
  String get chooseTopicTitle => 'What do you want to read?';

  @override
  String get popularTopics => 'Popular topics';

  @override
  String get anyTopic => 'Surprise me';

  @override
  String get searchTopic => 'Or search for a topic';

  @override
  String get searchTopicHint => 'e.g. space, coffee, Roman Empire';

  @override
  String readingFrom(String source, String language) {
    return 'From $source · $language';
  }

  @override
  String get startReading => 'Start reading';

  @override
  String topicExhausted(String topic, String source, String language) {
    return 'You have read every article about \"$topic\" on $source ($language).';
  }

  @override
  String get noNewArticles =>
      'No unread articles found this time. Please try again.';

  @override
  String get settingsTitle => 'Profile & Settings';

  @override
  String get editNickname => 'Edit nickname';

  @override
  String get nickname => 'Nickname';

  @override
  String get changePhoto => 'Change profile picture';

  @override
  String get chooseAnimal => 'Choose an animal';

  @override
  String get useMyPhoto => 'Or use your own photo';

  @override
  String get fromGallery => 'Choose from gallery';

  @override
  String get takePhoto => 'Take a photo';

  @override
  String get cameraHint =>
      'Works on a real device (the Simulator has no camera)';

  @override
  String get removePhoto => 'Remove my photo';

  @override
  String photoUpdated(int size) {
    return 'Profile picture updated ($size KB)';
  }

  @override
  String get photoRemoved => 'Your photo was removed';

  @override
  String get photoError =>
      'Couldn\'t open photos. Please allow access in Settings.';

  @override
  String get languageSection => 'Language';

  @override
  String get appLanguage => 'App language';

  @override
  String get appLanguageHint => 'Menus, messages and AI feedback';

  @override
  String get articleLanguage => 'Random article language';

  @override
  String get articleLanguageHint => 'Which Wikipedia new articles come from';

  @override
  String get ttsLanguage => 'Voice (TTS) language';

  @override
  String get ttsLanguageHint => 'AUTO reads in the language of each article';

  @override
  String get sourcesSection => 'Data sources';

  @override
  String get sourceWikipediaDesc =>
      'Free encyclopedia in English, Chinese and Thai';

  @override
  String get sourcesMore => 'More sources';

  @override
  String get sourcesMoreHint =>
      'Coming in future updates — new sources or plugins';

  @override
  String get comingSoon => 'Soon';

  @override
  String get applyLanguage => 'Apply language';

  @override
  String get restartTitle => 'Restart the app?';

  @override
  String get restartMessage =>
      'The new language takes effect after the app restarts. Restart now?';

  @override
  String get restartNow => 'Restart now';

  @override
  String get restartLater => 'Later';

  @override
  String get languageSavedForLater =>
      'Saved. The new language will be used next time you open the app.';

  @override
  String get languagePending => 'Saved — applies after restart';

  @override
  String get readingSection => 'Reading';

  @override
  String get readingTimePerRound => 'Reading time per session';

  @override
  String get displaySection => 'Display';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get logout => 'Logout';

  @override
  String get logoutTitle => 'Log out?';

  @override
  String get logoutMessage =>
      'You\'ll need to log in again to see your history.';

  @override
  String get setupTitle => 'Let\'s set things up';

  @override
  String get setupSubtitle =>
      'A few basics before your first read. You can change these later in Settings.';

  @override
  String get setupProfilePicture => 'Profile picture';

  @override
  String get setupStart => 'Start reading';
}
