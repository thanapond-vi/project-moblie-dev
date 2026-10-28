import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_th.dart';
import 'app_localizations_zh.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('zh'),
    Locale('th'),
  ];

  /// No description provided for @tagline.
  ///
  /// In en, this message translates to:
  /// **'Read · Recall · Summarize — practice with Active Recall'**
  String get tagline;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @retry.
  ///
  /// In en, this message translates to:
  /// **'Try again'**
  String get retry;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @discard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get discard;

  /// No description provided for @delete.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get delete;

  /// No description provided for @continueLabel.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get continueLabel;

  /// No description provided for @minutesValue.
  ///
  /// In en, this message translates to:
  /// **'{count} min'**
  String minutesValue(int count);

  /// No description provided for @login.
  ///
  /// In en, this message translates to:
  /// **'Login'**
  String get login;

  /// No description provided for @register.
  ///
  /// In en, this message translates to:
  /// **'Register'**
  String get register;

  /// No description provided for @email.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get email;

  /// No description provided for @password.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get password;

  /// No description provided for @confirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get confirmPassword;

  /// No description provided for @showPassword.
  ///
  /// In en, this message translates to:
  /// **'Show password'**
  String get showPassword;

  /// No description provided for @hidePassword.
  ///
  /// In en, this message translates to:
  /// **'Hide password'**
  String get hidePassword;

  /// No description provided for @haveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Login'**
  String get haveAccount;

  /// No description provided for @noAccount.
  ///
  /// In en, this message translates to:
  /// **'Don\'t have an account? Register'**
  String get noAccount;

  /// No description provided for @vEmailRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your email'**
  String get vEmailRequired;

  /// No description provided for @vEmailInvalid.
  ///
  /// In en, this message translates to:
  /// **'Invalid email format'**
  String get vEmailInvalid;

  /// No description provided for @vPasswordRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter your password'**
  String get vPasswordRequired;

  /// No description provided for @vPasswordMin.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least {min} characters'**
  String vPasswordMin(int min);

  /// No description provided for @vConfirmRequired.
  ///
  /// In en, this message translates to:
  /// **'Please confirm your password'**
  String get vConfirmRequired;

  /// No description provided for @vPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match'**
  String get vPasswordMismatch;

  /// No description provided for @vSummaryRequired.
  ///
  /// In en, this message translates to:
  /// **'Please write the key points'**
  String get vSummaryRequired;

  /// No description provided for @vSummaryMin.
  ///
  /// In en, this message translates to:
  /// **'Too short — at least {min} characters (now {count})'**
  String vSummaryMin(int min, int count);

  /// No description provided for @vNicknameRequired.
  ///
  /// In en, this message translates to:
  /// **'Please enter a nickname'**
  String get vNicknameRequired;

  /// No description provided for @vNicknameLength.
  ///
  /// In en, this message translates to:
  /// **'Nickname must be {min}–{max} characters'**
  String vNicknameLength(int min, int max);

  /// No description provided for @errNoInternet.
  ///
  /// In en, this message translates to:
  /// **'No internet connection'**
  String get errNoInternet;

  /// No description provided for @errTimeout.
  ///
  /// In en, this message translates to:
  /// **'The connection took too long. Please try again.'**
  String get errTimeout;

  /// No description provided for @errGeneric.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong. Please try again.'**
  String get errGeneric;

  /// No description provided for @errGenericCode.
  ///
  /// In en, this message translates to:
  /// **'Something went wrong ({code})'**
  String errGenericCode(String code);

  /// No description provided for @errUserDisabled.
  ///
  /// In en, this message translates to:
  /// **'This account has been disabled'**
  String get errUserDisabled;

  /// No description provided for @errWrongCredentials.
  ///
  /// In en, this message translates to:
  /// **'Incorrect email or password'**
  String get errWrongCredentials;

  /// No description provided for @errEmailInUse.
  ///
  /// In en, this message translates to:
  /// **'This email is already registered'**
  String get errEmailInUse;

  /// No description provided for @errWeakPassword.
  ///
  /// In en, this message translates to:
  /// **'Password is too weak'**
  String get errWeakPassword;

  /// No description provided for @errTooManyRequests.
  ///
  /// In en, this message translates to:
  /// **'Too many attempts. Please wait a moment.'**
  String get errTooManyRequests;

  /// No description provided for @errAuthNotEnabled.
  ///
  /// In en, this message translates to:
  /// **'Email/Password sign-in is not enabled in Firebase Console'**
  String get errAuthNotEnabled;

  /// No description provided for @errPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to access this data'**
  String get errPermissionDenied;

  /// No description provided for @errDbUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach the database. Check your internet.'**
  String get errDbUnavailable;

  /// No description provided for @errSaveFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not save ({code})'**
  String errSaveFailed(String code);

  /// No description provided for @errDbTimeout.
  ///
  /// In en, this message translates to:
  /// **'The database is responding slowly. Please try again.'**
  String get errDbTimeout;

  /// No description provided for @errArticleEmpty.
  ///
  /// In en, this message translates to:
  /// **'This article has no content. Please try another.'**
  String get errArticleEmpty;

  /// No description provided for @errNoArticle.
  ///
  /// In en, this message translates to:
  /// **'No article found. Please try again.'**
  String get errNoArticle;

  /// No description provided for @errWikiTimeout.
  ///
  /// In en, this message translates to:
  /// **'Wikipedia is responding slowly. Please try again.'**
  String get errWikiTimeout;

  /// No description provided for @errWikiLoad.
  ///
  /// In en, this message translates to:
  /// **'Could not load the article. Please try again.'**
  String get errWikiLoad;

  /// No description provided for @errWikiRateLimit.
  ///
  /// In en, this message translates to:
  /// **'Too many requests. Please wait a moment and try again.'**
  String get errWikiRateLimit;

  /// No description provided for @errWikiStatus.
  ///
  /// In en, this message translates to:
  /// **'Wikipedia returned an error ({code})'**
  String errWikiStatus(String code);

  /// No description provided for @errAiNotConfigured.
  ///
  /// In en, this message translates to:
  /// **'AI is not set up (add GROQ_API_KEY to .env)'**
  String get errAiNotConfigured;

  /// No description provided for @errAiBadKey.
  ///
  /// In en, this message translates to:
  /// **'The Groq API key is invalid'**
  String get errAiBadKey;

  /// No description provided for @errAiModelNotFound.
  ///
  /// In en, this message translates to:
  /// **'Model {model} was not found on Groq (check GROQ_MODEL in .env)'**
  String errAiModelNotFound(String model);

  /// No description provided for @errAiRateLimit.
  ///
  /// In en, this message translates to:
  /// **'AI is being used too often. Please wait and try again.'**
  String get errAiRateLimit;

  /// No description provided for @errAiStatus.
  ///
  /// In en, this message translates to:
  /// **'AI returned an error ({code})'**
  String errAiStatus(String code);

  /// No description provided for @errAiTimeout.
  ///
  /// In en, this message translates to:
  /// **'AI took too long. Please try again.'**
  String get errAiTimeout;

  /// No description provided for @errAiConnect.
  ///
  /// In en, this message translates to:
  /// **'Can\'t reach the AI. Check your internet.'**
  String get errAiConnect;

  /// No description provided for @errAiRead.
  ///
  /// In en, this message translates to:
  /// **'Could not read the AI result. Please try again.'**
  String get errAiRead;

  /// No description provided for @errAiBadFormat.
  ///
  /// In en, this message translates to:
  /// **'The AI replied in an unreadable format'**
  String get errAiBadFormat;

  /// No description provided for @errAiNoScore.
  ///
  /// In en, this message translates to:
  /// **'The AI did not return a score'**
  String get errAiNoScore;

  /// No description provided for @aiNoFeedback.
  ///
  /// In en, this message translates to:
  /// **'No feedback'**
  String get aiNoFeedback;

  /// No description provided for @errTtsNoVoice.
  ///
  /// In en, this message translates to:
  /// **'This device has no {language} voice'**
  String errTtsNoVoice(String language);

  /// No description provided for @errImageTooLarge.
  ///
  /// In en, this message translates to:
  /// **'The image is too large. Please choose another one.'**
  String get errImageTooLarge;

  /// No description provided for @errLoginAgain.
  ///
  /// In en, this message translates to:
  /// **'Please log in again'**
  String get errLoginAgain;

  /// No description provided for @errProfilePermission.
  ///
  /// In en, this message translates to:
  /// **'You don\'t have permission to save this profile'**
  String get errProfilePermission;

  /// No description provided for @errProfileSave.
  ///
  /// In en, this message translates to:
  /// **'Could not save your profile ({code})'**
  String errProfileSave(String code);

  /// No description provided for @errFirebaseInit.
  ///
  /// In en, this message translates to:
  /// **'Could not connect to Firebase\n\n{message}'**
  String errFirebaseInit(String message);

  /// No description provided for @helloName.
  ///
  /// In en, this message translates to:
  /// **'Hello, {name}'**
  String helloName(String name);

  /// No description provided for @greetingFallback.
  ///
  /// In en, this message translates to:
  /// **'What will you learn today?'**
  String get greetingFallback;

  /// No description provided for @profileSettingsTooltip.
  ///
  /// In en, this message translates to:
  /// **'Profile & Settings'**
  String get profileSettingsTooltip;

  /// No description provided for @randomArticle.
  ///
  /// In en, this message translates to:
  /// **'Random article'**
  String get randomArticle;

  /// No description provided for @finishCurrentFirst.
  ///
  /// In en, this message translates to:
  /// **'Finish the current one'**
  String get finishCurrentFirst;

  /// No description provided for @sessionLockedMessage.
  ///
  /// In en, this message translates to:
  /// **'You have an article in progress. Finish its summary before starting a new one.'**
  String get sessionLockedMessage;

  /// No description provided for @sessionReading.
  ///
  /// In en, this message translates to:
  /// **'Reading · Paused'**
  String get sessionReading;

  /// No description provided for @sessionSummarizing.
  ///
  /// In en, this message translates to:
  /// **'Finished · Awaiting summary'**
  String get sessionSummarizing;

  /// No description provided for @timeLeft.
  ///
  /// In en, this message translates to:
  /// **'{time} left'**
  String timeLeft(String time);

  /// No description provided for @readForMinutes.
  ///
  /// In en, this message translates to:
  /// **'Read {count} min'**
  String readForMinutes(int count);

  /// No description provided for @tapToResume.
  ///
  /// In en, this message translates to:
  /// **'Tap to keep reading'**
  String get tapToResume;

  /// No description provided for @tapToSummarize.
  ///
  /// In en, this message translates to:
  /// **'Tap to continue your summary'**
  String get tapToSummarize;

  /// No description provided for @options.
  ///
  /// In en, this message translates to:
  /// **'Options'**
  String get options;

  /// No description provided for @discardArticle.
  ///
  /// In en, this message translates to:
  /// **'Discard this article'**
  String get discardArticle;

  /// No description provided for @discardSessionTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard the article in progress?'**
  String get discardSessionTitle;

  /// No description provided for @discardSessionMessage.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" and your draft summary will be removed. Then you can start a new article.'**
  String discardSessionMessage(String title);

  /// No description provided for @statRead.
  ///
  /// In en, this message translates to:
  /// **'Articles read'**
  String get statRead;

  /// No description provided for @statAvgScore.
  ///
  /// In en, this message translates to:
  /// **'Average score'**
  String get statAvgScore;

  /// No description provided for @statTotalTime.
  ///
  /// In en, this message translates to:
  /// **'Total reading'**
  String get statTotalTime;

  /// No description provided for @unitArticles.
  ///
  /// In en, this message translates to:
  /// **'articles'**
  String get unitArticles;

  /// No description provided for @unitMinutes.
  ///
  /// In en, this message translates to:
  /// **'min'**
  String get unitMinutes;

  /// No description provided for @statAllTime.
  ///
  /// In en, this message translates to:
  /// **'All time'**
  String get statAllTime;

  /// No description provided for @emptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No reading history yet'**
  String get emptyTitle;

  /// No description provided for @emptyBody.
  ///
  /// In en, this message translates to:
  /// **'Tap \"Random article\" to start, then summarize it from memory.'**
  String get emptyBody;

  /// No description provided for @deleteLogTitle.
  ///
  /// In en, this message translates to:
  /// **'Delete this entry?'**
  String get deleteLogTitle;

  /// No description provided for @deleteLogMessage.
  ///
  /// In en, this message translates to:
  /// **'\"{title}\" will be deleted permanently.'**
  String deleteLogMessage(String title);

  /// No description provided for @deletedMessage.
  ///
  /// In en, this message translates to:
  /// **'Deleted \"{title}\"'**
  String deletedMessage(String title);

  /// No description provided for @notEvaluated.
  ///
  /// In en, this message translates to:
  /// **'Not evaluated'**
  String get notEvaluated;

  /// No description provided for @historyLoadError.
  ///
  /// In en, this message translates to:
  /// **'Could not load your history\n{error}'**
  String historyLoadError(String error);

  /// No description provided for @readingTitle.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get readingTitle;

  /// No description provided for @searchMore.
  ///
  /// In en, this message translates to:
  /// **'Search for more'**
  String get searchMore;

  /// No description provided for @pauseForLater.
  ///
  /// In en, this message translates to:
  /// **'Pause and read later'**
  String get pauseForLater;

  /// No description provided for @pausedMessage.
  ///
  /// In en, this message translates to:
  /// **'Reading paused. Tap the card on the home screen to continue.'**
  String get pausedMessage;

  /// No description provided for @timeUpTitle.
  ///
  /// In en, this message translates to:
  /// **'Time\'s up'**
  String get timeUpTitle;

  /// No description provided for @timeUpBody.
  ///
  /// In en, this message translates to:
  /// **'Now summarize the key points from memory, without looking back at the article.'**
  String get timeUpBody;

  /// No description provided for @goSummarize.
  ///
  /// In en, this message translates to:
  /// **'Write summary'**
  String get goSummarize;

  /// No description provided for @finishedReading.
  ///
  /// In en, this message translates to:
  /// **'Done reading — write summary'**
  String get finishedReading;

  /// No description provided for @loadingArticle.
  ///
  /// In en, this message translates to:
  /// **'Picking a random article from Wikipedia...'**
  String get loadingArticle;

  /// No description provided for @charCount.
  ///
  /// In en, this message translates to:
  /// **'{count} characters'**
  String charCount(int count);

  /// No description provided for @timerRunning.
  ///
  /// In en, this message translates to:
  /// **'Timer running'**
  String get timerRunning;

  /// No description provided for @timerPaused.
  ///
  /// In en, this message translates to:
  /// **'Paused'**
  String get timerPaused;

  /// No description provided for @pauseTimer.
  ///
  /// In en, this message translates to:
  /// **'Pause'**
  String get pauseTimer;

  /// No description provided for @resumeTimer.
  ///
  /// In en, this message translates to:
  /// **'Resume timer'**
  String get resumeTimer;

  /// No description provided for @ttsPlay.
  ///
  /// In en, this message translates to:
  /// **'Listen'**
  String get ttsPlay;

  /// No description provided for @ttsPause.
  ///
  /// In en, this message translates to:
  /// **'Pause voice'**
  String get ttsPause;

  /// No description provided for @ttsStop.
  ///
  /// In en, this message translates to:
  /// **'Stop voice'**
  String get ttsStop;

  /// No description provided for @ttsReading.
  ///
  /// In en, this message translates to:
  /// **'Reading paragraph {current}/{total}'**
  String ttsReading(int current, int total);

  /// No description provided for @ttsPausedAt.
  ///
  /// In en, this message translates to:
  /// **'Paused at paragraph {current}/{total}'**
  String ttsPausedAt(int current, int total);

  /// No description provided for @ttsIdle.
  ///
  /// In en, this message translates to:
  /// **'Listen to this article'**
  String get ttsIdle;

  /// No description provided for @ttsError.
  ///
  /// In en, this message translates to:
  /// **'Could not start the voice reader'**
  String get ttsError;

  /// No description provided for @linkError.
  ///
  /// In en, this message translates to:
  /// **'Could not open the link'**
  String get linkError;

  /// No description provided for @searchGoogle.
  ///
  /// In en, this message translates to:
  /// **'Search on Google'**
  String get searchGoogle;

  /// No description provided for @openWikipedia.
  ///
  /// In en, this message translates to:
  /// **'Open the Wikipedia page'**
  String get openWikipedia;

  /// No description provided for @openWikipediaSub.
  ///
  /// In en, this message translates to:
  /// **'See images, tables and references'**
  String get openWikipediaSub;

  /// No description provided for @writeSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Write summary'**
  String get writeSummaryTitle;

  /// No description provided for @editSummaryTitle.
  ///
  /// In en, this message translates to:
  /// **'Edit summary'**
  String get editSummaryTitle;

  /// No description provided for @recallHint.
  ///
  /// In en, this message translates to:
  /// **'Summarize the key points from memory — no peeking at the article.'**
  String get recallHint;

  /// No description provided for @editHint.
  ///
  /// In en, this message translates to:
  /// **'Edit your summary, then let the AI evaluate it again.'**
  String get editHint;

  /// No description provided for @summaryHint.
  ///
  /// In en, this message translates to:
  /// **'What is this article about? What are the main points?'**
  String get summaryHint;

  /// No description provided for @summaryCounter.
  ///
  /// In en, this message translates to:
  /// **'{count} characters (at least {min})'**
  String summaryCounter(int count, int min);

  /// No description provided for @aiEvaluating.
  ///
  /// In en, this message translates to:
  /// **'AI is evaluating...'**
  String get aiEvaluating;

  /// No description provided for @saving.
  ///
  /// In en, this message translates to:
  /// **'Saving...'**
  String get saving;

  /// No description provided for @evaluateAndSave.
  ///
  /// In en, this message translates to:
  /// **'Evaluate with AI & save'**
  String get evaluateAndSave;

  /// No description provided for @reevaluateAndSave.
  ///
  /// In en, this message translates to:
  /// **'Re-evaluate & save'**
  String get reevaluateAndSave;

  /// No description provided for @earnedMinutes.
  ///
  /// In en, this message translates to:
  /// **'+{count} min added to your total'**
  String earnedMinutes(int count);

  /// No description provided for @viewOriginal.
  ///
  /// In en, this message translates to:
  /// **'View the original article'**
  String get viewOriginal;

  /// No description provided for @viewOriginalSub.
  ///
  /// In en, this message translates to:
  /// **'The part the AI compared against'**
  String get viewOriginalSub;

  /// No description provided for @doneBackHome.
  ///
  /// In en, this message translates to:
  /// **'Done — back to home'**
  String get doneBackHome;

  /// No description provided for @staleScore.
  ///
  /// In en, this message translates to:
  /// **'This score is for your previous text. Evaluate again to update it.'**
  String get staleScore;

  /// No description provided for @scoreLabel.
  ///
  /// In en, this message translates to:
  /// **'Understanding score'**
  String get scoreLabel;

  /// No description provided for @notEvaluatedYet.
  ///
  /// In en, this message translates to:
  /// **'Not evaluated yet'**
  String get notEvaluatedYet;

  /// No description provided for @scoreOutOf.
  ///
  /// In en, this message translates to:
  /// **'{score} / 100'**
  String scoreOutOf(int score);

  /// No description provided for @evaluatedBy.
  ///
  /// In en, this message translates to:
  /// **'Evaluated by Groq · {model}'**
  String evaluatedBy(String model);

  /// No description provided for @aiFeedbackTitle.
  ///
  /// In en, this message translates to:
  /// **'AI Feedback'**
  String get aiFeedbackTitle;

  /// No description provided for @aiFailed.
  ///
  /// In en, this message translates to:
  /// **'AI evaluation failed'**
  String get aiFailed;

  /// No description provided for @saveWithoutScore.
  ///
  /// In en, this message translates to:
  /// **'Save for now (no score)'**
  String get saveWithoutScore;

  /// No description provided for @savedMessage.
  ///
  /// In en, this message translates to:
  /// **'Saved'**
  String get savedMessage;

  /// No description provided for @removeScoreTitle.
  ///
  /// In en, this message translates to:
  /// **'Remove the old score?'**
  String get removeScoreTitle;

  /// No description provided for @removeScoreMessage.
  ///
  /// In en, this message translates to:
  /// **'The old score belongs to your previous text. Saving now will mark it as \"not evaluated\".'**
  String get removeScoreMessage;

  /// No description provided for @discardDraftTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard your text?'**
  String get discardDraftTitle;

  /// No description provided for @discardDraftMessage.
  ///
  /// In en, this message translates to:
  /// **'Your unsaved summary will be lost.'**
  String get discardDraftMessage;

  /// No description provided for @tagsTitle.
  ///
  /// In en, this message translates to:
  /// **'Tags (up to 3)'**
  String get tagsTitle;

  /// No description provided for @tagsHint.
  ///
  /// In en, this message translates to:
  /// **'The AI suggests tags after evaluating. Tap to change.'**
  String get tagsHint;

  /// No description provided for @tagsLimit.
  ///
  /// In en, this message translates to:
  /// **'You can pick up to 3 tags'**
  String get tagsLimit;

  /// No description provided for @tagTechnology.
  ///
  /// In en, this message translates to:
  /// **'Technology'**
  String get tagTechnology;

  /// No description provided for @tagScience.
  ///
  /// In en, this message translates to:
  /// **'Science'**
  String get tagScience;

  /// No description provided for @tagHistory.
  ///
  /// In en, this message translates to:
  /// **'History'**
  String get tagHistory;

  /// No description provided for @tagBiographies.
  ///
  /// In en, this message translates to:
  /// **'Biographies'**
  String get tagBiographies;

  /// No description provided for @tagCulture.
  ///
  /// In en, this message translates to:
  /// **'Culture'**
  String get tagCulture;

  /// No description provided for @chooseTopicTitle.
  ///
  /// In en, this message translates to:
  /// **'What do you want to read?'**
  String get chooseTopicTitle;

  /// No description provided for @popularTopics.
  ///
  /// In en, this message translates to:
  /// **'Popular topics'**
  String get popularTopics;

  /// No description provided for @anyTopic.
  ///
  /// In en, this message translates to:
  /// **'Surprise me'**
  String get anyTopic;

  /// No description provided for @searchTopic.
  ///
  /// In en, this message translates to:
  /// **'Or search for a topic'**
  String get searchTopic;

  /// No description provided for @searchTopicHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. space, coffee, Roman Empire'**
  String get searchTopicHint;

  /// No description provided for @readingFrom.
  ///
  /// In en, this message translates to:
  /// **'From {source} · {language}'**
  String readingFrom(String source, String language);

  /// No description provided for @startReading.
  ///
  /// In en, this message translates to:
  /// **'Start reading'**
  String get startReading;

  /// No description provided for @topicExhausted.
  ///
  /// In en, this message translates to:
  /// **'You have read every article about \"{topic}\" on {source} ({language}).'**
  String topicExhausted(String topic, String source, String language);

  /// No description provided for @noNewArticles.
  ///
  /// In en, this message translates to:
  /// **'No unread articles found this time. Please try again.'**
  String get noNewArticles;

  /// No description provided for @settingsTitle.
  ///
  /// In en, this message translates to:
  /// **'Profile & Settings'**
  String get settingsTitle;

  /// No description provided for @editNickname.
  ///
  /// In en, this message translates to:
  /// **'Edit nickname'**
  String get editNickname;

  /// No description provided for @nickname.
  ///
  /// In en, this message translates to:
  /// **'Nickname'**
  String get nickname;

  /// No description provided for @changePhoto.
  ///
  /// In en, this message translates to:
  /// **'Change profile picture'**
  String get changePhoto;

  /// No description provided for @chooseAnimal.
  ///
  /// In en, this message translates to:
  /// **'Choose an animal'**
  String get chooseAnimal;

  /// No description provided for @useMyPhoto.
  ///
  /// In en, this message translates to:
  /// **'Or use your own photo'**
  String get useMyPhoto;

  /// No description provided for @fromGallery.
  ///
  /// In en, this message translates to:
  /// **'Choose from gallery'**
  String get fromGallery;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get takePhoto;

  /// No description provided for @cameraHint.
  ///
  /// In en, this message translates to:
  /// **'Works on a real device (the Simulator has no camera)'**
  String get cameraHint;

  /// No description provided for @removePhoto.
  ///
  /// In en, this message translates to:
  /// **'Remove my photo'**
  String get removePhoto;

  /// No description provided for @photoUpdated.
  ///
  /// In en, this message translates to:
  /// **'Profile picture updated ({size} KB)'**
  String photoUpdated(int size);

  /// No description provided for @photoRemoved.
  ///
  /// In en, this message translates to:
  /// **'Your photo was removed'**
  String get photoRemoved;

  /// No description provided for @photoError.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t open photos. Please allow access in Settings.'**
  String get photoError;

  /// No description provided for @languageSection.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get languageSection;

  /// No description provided for @appLanguage.
  ///
  /// In en, this message translates to:
  /// **'App language'**
  String get appLanguage;

  /// No description provided for @appLanguageHint.
  ///
  /// In en, this message translates to:
  /// **'Menus, messages and AI feedback'**
  String get appLanguageHint;

  /// No description provided for @articleLanguage.
  ///
  /// In en, this message translates to:
  /// **'Random article language'**
  String get articleLanguage;

  /// No description provided for @articleLanguageHint.
  ///
  /// In en, this message translates to:
  /// **'Which Wikipedia new articles come from'**
  String get articleLanguageHint;

  /// No description provided for @ttsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Voice (TTS) language'**
  String get ttsLanguage;

  /// No description provided for @ttsLanguageHint.
  ///
  /// In en, this message translates to:
  /// **'AUTO reads in the language of each article'**
  String get ttsLanguageHint;

  /// No description provided for @sourcesSection.
  ///
  /// In en, this message translates to:
  /// **'Data sources'**
  String get sourcesSection;

  /// No description provided for @sourceWikipediaDesc.
  ///
  /// In en, this message translates to:
  /// **'Free encyclopedia in English, Chinese and Thai'**
  String get sourceWikipediaDesc;

  /// No description provided for @sourcesMore.
  ///
  /// In en, this message translates to:
  /// **'More sources'**
  String get sourcesMore;

  /// No description provided for @sourcesMoreHint.
  ///
  /// In en, this message translates to:
  /// **'Coming in future updates — new sources or plugins'**
  String get sourcesMoreHint;

  /// No description provided for @comingSoon.
  ///
  /// In en, this message translates to:
  /// **'Soon'**
  String get comingSoon;

  /// No description provided for @applyLanguage.
  ///
  /// In en, this message translates to:
  /// **'Apply language'**
  String get applyLanguage;

  /// No description provided for @restartTitle.
  ///
  /// In en, this message translates to:
  /// **'Restart the app?'**
  String get restartTitle;

  /// No description provided for @restartMessage.
  ///
  /// In en, this message translates to:
  /// **'The new language takes effect after the app restarts. Restart now?'**
  String get restartMessage;

  /// No description provided for @restartNow.
  ///
  /// In en, this message translates to:
  /// **'Restart now'**
  String get restartNow;

  /// No description provided for @restartLater.
  ///
  /// In en, this message translates to:
  /// **'Later'**
  String get restartLater;

  /// No description provided for @languageSavedForLater.
  ///
  /// In en, this message translates to:
  /// **'Saved. The new language will be used next time you open the app.'**
  String get languageSavedForLater;

  /// No description provided for @languagePending.
  ///
  /// In en, this message translates to:
  /// **'Saved — applies after restart'**
  String get languagePending;

  /// No description provided for @readingSection.
  ///
  /// In en, this message translates to:
  /// **'Reading'**
  String get readingSection;

  /// No description provided for @readingTimePerRound.
  ///
  /// In en, this message translates to:
  /// **'Reading time per session'**
  String get readingTimePerRound;

  /// No description provided for @displaySection.
  ///
  /// In en, this message translates to:
  /// **'Display'**
  String get displaySection;

  /// No description provided for @darkMode.
  ///
  /// In en, this message translates to:
  /// **'Dark Mode'**
  String get darkMode;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @logoutTitle.
  ///
  /// In en, this message translates to:
  /// **'Log out?'**
  String get logoutTitle;

  /// No description provided for @logoutMessage.
  ///
  /// In en, this message translates to:
  /// **'You\'ll need to log in again to see your history.'**
  String get logoutMessage;

  /// No description provided for @setupTitle.
  ///
  /// In en, this message translates to:
  /// **'Let\'s set things up'**
  String get setupTitle;

  /// No description provided for @setupSubtitle.
  ///
  /// In en, this message translates to:
  /// **'A few basics before your first read. You can change these later in Settings.'**
  String get setupSubtitle;

  /// No description provided for @setupProfilePicture.
  ///
  /// In en, this message translates to:
  /// **'Profile picture'**
  String get setupProfilePicture;

  /// No description provided for @setupStart.
  ///
  /// In en, this message translates to:
  /// **'Start reading'**
  String get setupStart;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'th', 'zh'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'th':
      return AppLocalizationsTh();
    case 'zh':
      return AppLocalizationsZh();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
