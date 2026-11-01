// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get tagline => '阅读 · 回忆 · 反思';

  @override
  String get cancel => '取消';

  @override
  String get retry => '重试';

  @override
  String get save => '保存';

  @override
  String get discard => '放弃';

  @override
  String get delete => '删除';

  @override
  String get continueLabel => '继续';

  @override
  String minutesValue(int count) {
    return '$count 分钟';
  }

  @override
  String get login => '登录';

  @override
  String get register => '注册';

  @override
  String get email => 'Email';

  @override
  String get password => '密码';

  @override
  String get confirmPassword => '确认密码';

  @override
  String get showPassword => '显示密码';

  @override
  String get hidePassword => '隐藏密码';

  @override
  String get haveAccount => '已有账号？登录';

  @override
  String get noAccount => '还没有账号？注册';

  @override
  String get vEmailRequired => '请输入 Email';

  @override
  String get vEmailInvalid => 'Email 格式不正确';

  @override
  String get vPasswordRequired => '请输入密码';

  @override
  String vPasswordMin(int min) {
    return '密码至少需要 $min 个字符';
  }

  @override
  String get vConfirmRequired => '请确认密码';

  @override
  String get vPasswordMismatch => '两次密码不一致';

  @override
  String get vSummaryRequired => '请写下要点';

  @override
  String vSummaryMin(int min, int count) {
    return '太短了，至少 $min 个字符（当前 $count）';
  }

  @override
  String get vNicknameRequired => '请输入昵称';

  @override
  String vNicknameLength(int min, int max) {
    return '昵称需为 $min–$max 个字符';
  }

  @override
  String get errNoInternet => '没有网络连接';

  @override
  String get errTimeout => '连接超时，请重试';

  @override
  String get errGeneric => '出错了，请重试';

  @override
  String errGenericCode(String code) {
    return '出错了（$code）';
  }

  @override
  String get errUserDisabled => '该账号已被停用';

  @override
  String get errWrongCredentials => 'Email 或密码不正确';

  @override
  String get errEmailInUse => '该 Email 已被注册';

  @override
  String get errWeakPassword => '密码太简单';

  @override
  String get errTooManyRequests => '尝试次数过多，请稍候';

  @override
  String get errAuthNotEnabled => 'Firebase Console 未启用 Email/Password 登录';

  @override
  String get errPermissionDenied => '没有权限访问此数据';

  @override
  String get errDbUnavailable => '无法连接数据库，请检查网络';

  @override
  String errSaveFailed(String code) {
    return '保存失败（$code）';
  }

  @override
  String get errDbTimeout => '数据库响应太慢，请重试';

  @override
  String get errArticleEmpty => '这篇文章没有内容，请换一篇';

  @override
  String get errNoArticle => '没有找到文章，请重试';

  @override
  String get errWikiTimeout => 'Wikipedia 响应太慢，请重试';

  @override
  String get errWikiLoad => '文章加载失败，请重试';

  @override
  String get errWikiRateLimit => '请求太频繁，请稍后再试';

  @override
  String errWikiStatus(String code) {
    return 'Wikipedia 返回错误（$code）';
  }

  @override
  String get errAiNotConfigured => '尚未设置 AI（请在 .env 中填写 GROQ_API_KEY）';

  @override
  String get errAiBadKey => 'Groq 的 API key 无效';

  @override
  String errAiModelNotFound(String model) {
    return 'Groq 上找不到模型 $model（请检查 .env 中的 GROQ_MODEL）';
  }

  @override
  String get errAiRateLimit => 'AI 使用太频繁，请稍后再试';

  @override
  String errAiStatus(String code) {
    return 'AI 返回错误（$code）';
  }

  @override
  String get errAiTimeout => 'AI 响应超时，请重试';

  @override
  String get errAiConnect => '无法连接 AI，请检查网络';

  @override
  String get errAiRead => '无法读取 AI 结果，请重试';

  @override
  String get errAiBadFormat => 'AI 返回的格式无法读取';

  @override
  String get errAiNoScore => 'AI 没有返回分数';

  @override
  String get aiNoFeedback => '没有 Feedback';

  @override
  String errTtsNoVoice(String language) {
    return '此设备没有 $language 语音';
  }

  @override
  String get errImageTooLarge => '图片太大，请选择其他图片';

  @override
  String get errLoginAgain => '请重新登录';

  @override
  String get errProfilePermission => '没有权限保存个人资料';

  @override
  String errProfileSave(String code) {
    return '个人资料保存失败（$code）';
  }

  @override
  String errFirebaseInit(String message) {
    return '无法连接 Firebase\n\n$message';
  }

  @override
  String helloName(String name) {
    return '你好，$name';
  }

  @override
  String get greetingFallback => '今天会学到什么呢？';

  @override
  String get profileSettingsTooltip => '个人资料与设置';

  @override
  String get randomArticle => '随机文章';

  @override
  String get finishCurrentFirst => '先完成当前文章';

  @override
  String get sessionLockedMessage => '还有未完成的文章，请先完成总结再开始新的文章';

  @override
  String get sessionReading => '阅读中 · 已暂停';

  @override
  String get sessionSummarizing => '已读完 · 等待总结';

  @override
  String timeLeft(String time) {
    return '剩余 $time';
  }

  @override
  String readForMinutes(int count) {
    return '阅读 $count 分钟';
  }

  @override
  String get tapToResume => '点按继续阅读';

  @override
  String get tapToSummarize => '点按继续写总结';

  @override
  String get options => '选项';

  @override
  String get discardArticle => '放弃这篇文章';

  @override
  String get discardSessionTitle => '放弃未完成的文章？';

  @override
  String discardSessionMessage(String title) {
    return '\"$title\" 和总结草稿将被删除，之后才能开始新文章。';
  }

  @override
  String get statRead => '已读文章';

  @override
  String get statAvgScore => '平均分';

  @override
  String get statTotalTime => '总阅读时间';

  @override
  String get unitArticles => '篇';

  @override
  String get unitMinutes => '分钟';

  @override
  String get statAllTime => '全部';

  @override
  String get emptyTitle => '还没有阅读记录';

  @override
  String get emptyBody => '点按\"随机文章\"开始阅读，然后凭记忆写总结。';

  @override
  String get deleteLogTitle => '删除这条记录？';

  @override
  String deleteLogMessage(String title) {
    return '\"$title\" 将被永久删除。';
  }

  @override
  String deletedMessage(String title) {
    return '已删除\"$title\"';
  }

  @override
  String get notEvaluated => '未评分';

  @override
  String historyLoadError(String error) {
    return '无法加载阅读记录\n$error';
  }

  @override
  String get readingTitle => '阅读文章';

  @override
  String get searchMore => '搜索更多';

  @override
  String get pauseForLater => '暂停，稍后再读';

  @override
  String get pausedMessage => '已暂停阅读，点按首页的卡片继续。';

  @override
  String get timeUpTitle => '阅读时间到了';

  @override
  String get timeUpBody => '请凭记忆总结要点，不要回看文章。';

  @override
  String get goSummarize => '去写总结';

  @override
  String get finishedReading => '读完了，去写总结';

  @override
  String get loadingArticle => '正在从 Wikipedia 随机选取文章...';

  @override
  String charCount(int count) {
    return '$count 个字符';
  }

  @override
  String get timerRunning => '计时中';

  @override
  String get timerPaused => '已暂停';

  @override
  String get pauseTimer => '暂停';

  @override
  String get resumeTimer => '继续计时';

  @override
  String get ttsPlay => '收听朗读';

  @override
  String get ttsPause => '暂停朗读';

  @override
  String get ttsStop => '停止朗读';

  @override
  String ttsReading(int current, int total) {
    return '正在朗读第 $current/$total 段';
  }

  @override
  String ttsPausedAt(int current, int total) {
    return '暂停于第 $current/$total 段';
  }

  @override
  String get ttsIdle => '收听这篇文章';

  @override
  String get ttsError => '无法开始朗读';

  @override
  String get linkError => '无法打开链接';

  @override
  String get searchGoogle => '在 Google 搜索';

  @override
  String get openWikipedia => '打开 Wikipedia 原文';

  @override
  String get openWikipediaSub => '查看图片、表格和参考资料';

  @override
  String get writeSummaryTitle => '写总结';

  @override
  String get editSummaryTitle => '编辑总结';

  @override
  String get recallHint => '凭记忆总结要点，不要回看文章。';

  @override
  String get editHint => '修改总结后可以让 AI 重新评分。';

  @override
  String get summaryHint => '这篇文章讲了什么？主要观点有哪些？';

  @override
  String summaryCounter(int count, int min) {
    return '$count 个字符（至少 $min）';
  }

  @override
  String get aiEvaluating => 'AI 正在评分...';

  @override
  String get saving => '正在保存...';

  @override
  String get evaluateAndSave => '用 AI 评分并保存';

  @override
  String get reevaluateAndSave => '重新评分并保存';

  @override
  String earnedMinutes(int count) {
    return '+$count 分钟已计入总时间';
  }

  @override
  String get viewOriginal => '查看原文';

  @override
  String get viewOriginalSub => 'AI 评分时对照的部分';

  @override
  String get doneBackHome => '完成，返回首页';

  @override
  String get staleScore => '这是修改前文本的分数，请重新评分。';

  @override
  String get scoreLabel => '理解得分';

  @override
  String get notEvaluatedYet => '尚未评分';

  @override
  String scoreOutOf(int score) {
    return '$score / 100';
  }

  @override
  String evaluatedBy(String model) {
    return '由 Groq · $model 评分';
  }

  @override
  String get aiFeedbackTitle => 'AI Feedback';

  @override
  String get aiFailed => 'AI 评分失败';

  @override
  String get saveWithoutScore => '先保存（暂无分数）';

  @override
  String get savedMessage => '已保存';

  @override
  String get removeScoreTitle => '删除原来的分数？';

  @override
  String get removeScoreMessage => '原来的分数属于修改前的文本，现在保存会变为\"未评分\"。';

  @override
  String get discardDraftTitle => '放弃已写的内容？';

  @override
  String get discardDraftMessage => '未保存的总结将会丢失。';

  @override
  String get tagsTitle => '标签（最多 3 个）';

  @override
  String get tagsHint => 'AI 评分后会推荐标签，点按可修改。';

  @override
  String get tagsLimit => '最多只能选 3 个标签';

  @override
  String get tagTechnology => 'Technology';

  @override
  String get tagScience => '科学';

  @override
  String get tagHistory => '历史';

  @override
  String get tagBiographies => '人物传记';

  @override
  String get tagCulture => '文化';

  @override
  String get chooseTopicTitle => '想读什么？';

  @override
  String get popularTopics => '热门主题';

  @override
  String get anyTopic => '随便来一篇';

  @override
  String get searchTopic => '或搜索想看的主题';

  @override
  String get searchTopicHint => '例如：太空、咖啡、罗马帝国';

  @override
  String readingFrom(String source, String language) {
    return '来自 $source · $language';
  }

  @override
  String get startReading => '开始阅读';

  @override
  String topicExhausted(String topic, String source, String language) {
    return '$source（$language）中关于\"$topic\"的文章你已经全部读完了。';
  }

  @override
  String get noNewArticles => '这次没有找到未读文章，请重试。';

  @override
  String get settingsTitle => '个人资料与设置';

  @override
  String get editNickname => '修改昵称';

  @override
  String get nickname => '昵称';

  @override
  String get changePhoto => '更换头像';

  @override
  String get chooseAnimal => '选择一个小动物';

  @override
  String get useMyPhoto => '或使用自己的照片';

  @override
  String get fromGallery => '从相册选择';

  @override
  String get takePhoto => '拍照';

  @override
  String get cameraHint => '需在真机上使用（Simulator 没有相机）';

  @override
  String get removePhoto => '删除我的照片';

  @override
  String photoUpdated(int size) {
    return '头像已更新（$size KB）';
  }

  @override
  String get photoRemoved => '已删除你的照片';

  @override
  String get photoError => '无法打开照片，请在设置中允许访问。';

  @override
  String get languageSection => '语言';

  @override
  String get appLanguage => 'App 语言';

  @override
  String get appLanguageHint => '菜单、提示和 AI Feedback';

  @override
  String get articleLanguage => '随机文章语言';

  @override
  String get articleLanguageHint => '新文章来自哪个语言的 Wikipedia';

  @override
  String get ttsLanguage => '朗读 (TTS) 语言';

  @override
  String get ttsLanguageHint => 'AUTO = 按文章语言朗读';

  @override
  String get sourcesSection => '数据来源';

  @override
  String get sourceWikipediaDesc => '自由的百科全书，支持 English、Chinese、Thai';

  @override
  String get sourcesMore => '更多来源';

  @override
  String get sourcesMoreHint => '将在后续更新中加入新的来源或 plugin';

  @override
  String get comingSoon => '即将推出';

  @override
  String get applyLanguage => '确认语言';

  @override
  String get restartTitle => '重启 App？';

  @override
  String get restartMessage => '需要重启 App 才能使用新语言，现在重启吗？';

  @override
  String get restartNow => '立即重启';

  @override
  String get restartLater => '稍后';

  @override
  String get languageSavedForLater => '已保存，下次打开 App 时生效。';

  @override
  String get languagePending => '已保存，重启后生效';

  @override
  String get readingSection => '阅读';

  @override
  String get readingTimePerRound => '每次阅读时长';

  @override
  String get displaySection => '显示';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get logout => '退出登录';

  @override
  String get logoutTitle => '退出登录？';

  @override
  String get logoutMessage => '需要重新登录才能查看阅读记录。';

  @override
  String get setupTitle => '开始设置';

  @override
  String get setupSubtitle => '开始阅读前先完成几项基本设置，之后可在设置中修改。';

  @override
  String get setupProfilePicture => '头像';

  @override
  String get setupStart => '开始使用';

  @override
  String get navLibrary => '书库';

  @override
  String get navReview => '复习';

  @override
  String get navStats => '统计';

  @override
  String get reviewComingSoonBody => '间隔复习会把你快要忘记的文章重新带回来。';

  @override
  String get statsComingSoonBody => '你的阅读时间和回忆得分图表将显示在这里。';

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '连续 $count 天',
    );
    return '$_temp0';
  }

  @override
  String get streakStart => '开始连续阅读';

  @override
  String todayGoal(int done, int goal) {
    return '今天 $done / $goal 分钟';
  }

  @override
  String get todayGoalMet => '今日目标已完成';

  @override
  String randomArticleSubtitle(String language) {
    return 'Wikipedia · $language · 可选主题';
  }

  @override
  String get historyTitle => '阅读记录';

  @override
  String get scoreMastered => '掌握牢固';

  @override
  String get scoreGood => '记得不错';

  @override
  String get scoreReview => '需要复习';

  @override
  String scoreSemantics(int score, String level) {
    return '得分 $score，$level';
  }

  @override
  String get tipTitle => '记忆小贴士';

  @override
  String get recallTip1 => '合上文章，先写下你记得的内容再核对。努力回想正是让记忆牢固的关键。';

  @override
  String get recallTip2 => '像讲给朋友听一样解释。简单的话最能体现你是否真正理解。';

  @override
  String get recallTip3 => '每天短读胜过一次长读。连续阅读让记忆保持温热。';

  @override
  String get recallTip4 => '漏掉了要点？明天只重读那一部分，然后再回想一次。';

  @override
  String get close => '关闭';

  @override
  String get topicSheetHint => '计时结束后，你将凭记忆写下内容，不能回看文章。';

  @override
  String get recallNoteTitle => '主动回忆提示';

  @override
  String get recallNoteLoading => '正在想一个阅读时记在心里的问题…';

  @override
  String get recallNoteFallback => '边读边问自己：主要观点是什么？为什么重要？';

  @override
  String get recallNoteHint => '写总结时凭记忆回答它。';

  @override
  String get bookmarkAdd => '收藏文章';

  @override
  String get bookmarkRemove => '取消收藏';

  @override
  String get bookmarkSaved => '已收藏文章';

  @override
  String get bookmarkRemoved => '已取消收藏';

  @override
  String readMinutesEstimate(int minutes) {
    return '约 $minutes 分钟';
  }

  @override
  String readingProgress(int percent) {
    return '已读 $percent%';
  }

  @override
  String get keyPointsTitle => '要点';

  @override
  String keyPointsCovered(int count) {
    return '已涵盖（$count）';
  }

  @override
  String keyPointsMissed(int count) {
    return '遗漏（$count）';
  }

  @override
  String keyPointsSummary(int covered, int total) {
    return '涵盖 $covered/$total 个要点';
  }

  @override
  String get keyPointCore => '核心';

  @override
  String get accuracyTitle => '请核对这些内容';

  @override
  String get readAnother => '再读一篇';

  @override
  String get statusActive => '活跃读者';

  @override
  String get statusReader => '读者';

  @override
  String memberSince(String month) {
    return '$month 加入';
  }

  @override
  String get statLogsSaved => '已保存';

  @override
  String get statReviewSuccess => '复习成功率';

  @override
  String get statStreak => '连续天数';

  @override
  String get launchSound => '启动音效';

  @override
  String get launchSoundHint => '打开 KEEP 时台灯轻轻闪烁的声音。手机静音时不会响。';

  @override
  String versionLabel(String version) {
    return '版本 $version';
  }

  @override
  String get authStatusPill => '主动回忆阅读';

  @override
  String get authFooter => '你的阅读记录仅你本人账号可见。';

  @override
  String get forgotPassword => '忘记密码？';

  @override
  String get resetTitle => '重置密码';

  @override
  String get resetBody => '我们会发送一封邮件，帮你设置新密码。';

  @override
  String get resetSend => '发送链接';

  @override
  String resetSent(String email) {
    return '如果 $email 有账号，重置链接已发送。';
  }

  @override
  String stepOf(int current, int total) {
    return '第 $current 步，共 $total 步';
  }

  @override
  String get next => '下一步';

  @override
  String get back => '上一步';

  @override
  String get setupStep1Title => '谁在阅读？';

  @override
  String get setupStep2Title => '你喜欢怎样阅读？';

  @override
  String get selectedLabel => '已选择';

  @override
  String ttsSpeed(String rate) {
    return '朗读速度 $rate×，点按切换';
  }

  @override
  String get timeAlmostUp => '时间快到了';

  @override
  String get skipIntro => '跳过开场';

  @override
  String get noData => '暂无数据';

  @override
  String get range7 => '7 天';

  @override
  String get range30 => '30 天';

  @override
  String get rangeAll => '全部';

  @override
  String get statsMinutesTitle => '阅读时间';

  @override
  String get statsScoresTitle => '回忆得分';

  @override
  String get statsCalendarTitle => '阅读日历';

  @override
  String get statsTopicsTitle => '阅读主题';

  @override
  String get statsEmpty => '这段时间还没有阅读。去书库标签随机读一篇吧。';

  @override
  String changeUp(String value) {
    return '比上期 ↑ $value';
  }

  @override
  String changeDown(String value) {
    return '比上期 ↓ $value';
  }

  @override
  String get changeSame => '与上期持平';

  @override
  String get showTable => '以表格显示';

  @override
  String get showChart => '以图表显示';

  @override
  String get chartTapHint => '点按图表查看数值';

  @override
  String get legendLess => '少';

  @override
  String get legendMore => '多';

  @override
  String weekOf(String date) {
    return '$date 那周';
  }

  @override
  String minutesSummary(int total, int max, String day) {
    return '共 $total 分钟，最多 $max 分钟（$day）。';
  }

  @override
  String scoresSummary(int count, int latest, int average) {
    return '$count 篇有得分，最新 $latest，平均 $average。';
  }

  @override
  String calendarSummary(int days, int longest) {
    return '过去 12 周读了 $days 天，最长连续 $longest 天。';
  }

  @override
  String topicsSummary(String topic, int count) {
    return '读得最多：$topic，$count 篇。';
  }

  @override
  String longestStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '最长连续 $count 天',
    );
    return '$_temp0';
  }

  @override
  String topicValue(int count, int score) {
    return '$count · 平均 $score';
  }

  @override
  String get otherTopics => '其他';

  @override
  String get noScoresYet => '这段时间还没有得分';

  @override
  String reviewDueTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '今天要复习 $count 篇',
      zero: '今天没有要复习的',
    );
    return '$_temp0';
  }

  @override
  String get reviewDueSub => '先凭记忆回想，再看要点。';

  @override
  String reviewNextOn(String date) {
    return '下次复习：$date';
  }

  @override
  String get reviewBoxesTitle => '记忆盒';

  @override
  String get reviewBoxesHint => '记得就移到间隔更长的盒子，忘了就回到第 1 盒。';

  @override
  String boxLabel(int box) {
    return '第 $box 盒';
  }

  @override
  String everyDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '每 $count 天',
      one: '每天',
    );
    return '$_temp0';
  }

  @override
  String get dueToday => '今天到期';

  @override
  String overdueDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '逾期 $count 天',
    );
    return '$_temp0';
  }

  @override
  String get comingUp => '即将复习';

  @override
  String dueOn(String date) {
    return '$date 到期';
  }

  @override
  String get startReview => '复习';

  @override
  String get reviewEmptyAll => '先读一篇文章并保存总结，第二天就可以复习了。';

  @override
  String reviewAllDone(String date) {
    return '都复习完了，$date 再来。';
  }

  @override
  String get recallPromptGeneric => '关于这篇文章你还记得什么？先从主旨想起。';

  @override
  String get recallJotHint => '写下你记得的内容（可选，不保存）';

  @override
  String get reveal => '显示要点';

  @override
  String get reviewYourSummary => '你之前的总结';

  @override
  String get rateTitle => '你记得多少？';

  @override
  String get rateAgain => '忘了';

  @override
  String get rateHard => '困难';

  @override
  String get rateGood => '记得';

  @override
  String get rateEasy => '简单';

  @override
  String nextInDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 天后',
      one: '1 天后',
    );
    return '$_temp0';
  }

  @override
  String reviewSaved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count 天后再复习',
      one: '明天再复习',
    );
    return '$_temp0';
  }

  @override
  String reviewSuccessCaption(int passed, int total) {
    return '$total 次中记得 $passed 次';
  }

  @override
  String get deleteAccount => '删除账号';

  @override
  String get deleteAccountTitle => '删除你的账号？';

  @override
  String get deleteAccountBody => '这将永久删除你的阅读记录、总结、复习进度和个人资料，且无法恢复。';

  @override
  String get deleteAccountPassword => '输入密码以确认';

  @override
  String get deleteAccountConfirm => '永久删除';

  @override
  String get accountDeleted => '账号已删除';

  @override
  String get continueWithGoogle => '使用 Google 继续';

  @override
  String get orDivider => '或';

  @override
  String get errGoogleSetup => '此应用尚未设置 Google 登录。';

  @override
  String get errGoogleFailed => 'Google 登录失败，请重试。';

  @override
  String get errAccountOtherProvider => '此邮箱已使用其他登录方式，请用密码登录。';

  @override
  String get deleteAccountGoogle => '需要再次登录 Google 以确认。';

  @override
  String get continueWithApple => '通过 Apple 继续';

  @override
  String get appleComingSoon => 'Apple 登录即将推出';
}
