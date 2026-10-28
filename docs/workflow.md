# ReadRecall — Main Application Workflow

ReadRecall is a Flutter app for active-recall reading. The user reads a random Wikipedia article within a timed session, then writes a summary from memory. An LLM (`qwen/qwen3.8-27b`, run on the Groq cloud API) scores the summary against the original text, and the result is saved to Cloud Firestore.

This document covers the main user flow, the external integrations, and the Firestore schema. It is written to support the project report and the presentation.

---

## 1. High-Level Screen Flow

The app has five main screens:

```
AuthScreen (Login / Register)
  → HomeScreen (Study Logs: Read & Delete)
    → ReadingScreen (Focus Timer + Wikipedia REST API)
      → SummaryScreen (Form Validation + LLM API + Create / Update)
        → back to HomeScreen

ProfileScreen (Preferences via SharedPreferences, Logout) — reachable from HomeScreen
```

---

## 2. Step-by-Step Workflow

### Step 1: Authentication (`AuthScreen`)

**User action:** The user opens the app. They choose **Register** to create an account, or **Login** if they already have one. Both modes ask for an email and a password.

**Validation (client-side, before any network call):**
- Email must contain `@` and a domain.
- Password must be at least 6 characters.
- Show inline error messages under each field.

**Firebase Authentication (asynchronous):**
- Login calls `signInWithEmailAndPassword`.
- Register calls `createUserWithEmailAndPassword`.
- While the request runs, show a loading indicator and disable the submit button to prevent double submission.
- Map Firebase error codes (for example `wrong-password`, `email-already-in-use`) to readable messages.

**Navigation:** On success, read the user's `uid` and go to `HomeScreen`. The auth state stream also keeps the user signed in across app restarts.

---

### Step 2: Dashboard and History (`HomeScreen`, CRUD: Read & Delete)

**User action:** The user sees their past study logs. They can tap **Start New Session** to begin a new reading session.

**Read (real-time):**
- Query the `study_logs` collection where `userId == currentUser.uid`, then sort by `createdAt` descending in the app (sorting in Firestore with `orderBy` on a different field would need a composite index).
- Render the results with a `StreamBuilder`, so the list updates live.

**Delete:**
- The user can swipe a log to dismiss it, or tap a trash icon.
- Show a confirmation dialog before deleting, because the action cannot be undone.
- Call `delete()` on the document in Firestore.

**Navigation:**
- Tap an existing log → `SummaryScreen` in **Edit Mode**, pre-filled with the saved summary.
- Tap **Start New Session** → `ReadingScreen`.
- Tap the profile icon → `ProfileScreen`.

---

### Step 3: Random Article and Focus Timer (`ReadingScreen`, External APIs and Local Storage)

**User action:** The user reads the random article within the time limit (default 30 minutes). They can start or pause the timer, or tap **Skip to Summary** when they finish early.

**Local storage (`SharedPreferences`):**
- Read the default reading time (`defaultTimerMinutes`, one of 15, 30, or 45; default 30).
- Use it as the starting value of the countdown timer.

**REST API #1 (Wikipedia REST API):**
- Send an asynchronous HTTP GET to `https://th.wikipedia.org/w/api.php?action=query&generator=random&grnlimit=50&prop=info` to get 50 random articles with their lengths, and pick one that is long enough to read (Thai Wikipedia has many stub articles; `/api/rest_v1/page/random/summary` only returns the first paragraph).
- Send a second GET with `prop=extracts&explaintext=1` to get the full plain-text content, and display `title` and content.
- Show a loading state while the requests run.
- Handle failures: show an error message with a **Retry** button. If the real content is too short (for example, a page that is mostly tables), try the next candidate automatically, up to 3 articles.
- Keep the fetched `title` and `extract` in state. They are passed to the next screen.

- A **Search more** button opens Google or the original Wikipedia page with `url_launcher`.

**Navigation:** When the timer reaches zero, or the user taps **Finish Reading & Summarize**, send `articleTitle`, `articleUrl`, and `originalContent` (the first 3,000 characters) to `SummaryScreen`. Also send the actual time spent, so it can be saved as `readingTimeMinutes`.

---

### Step 4: Active Recall Summary and LLM Evaluation (`SummaryScreen`, Form, LLM API, CRUD: Create & Update)

**User action:** The user writes a summary of the article from memory, without looking at the original text. They tap **Evaluate & Save**.

**Form validation:**
- Use a `Form` with a `GlobalKey<FormState>`.
- The summary must not be empty.
- The summary must be at least 50 characters, to prevent very short submissions.
- Show the error inline and do not call the API if validation fails.

**REST API #2 (LLM on Groq: `qwen/qwen3.8-27b`):**
- Show a `CircularProgressIndicator` and disable the button while the request runs.
- Send an asynchronous HTTP POST to `https://api.groq.com/openai/v1/chat/completions` with `originalContent` and `userSummary`. The app names the model in the request (`GROQ_MODEL` in `.env`), and the response's `model` field confirms which model answered; the app shows it under the score.
- Ask the model to return JSON with two fields:
  - `aiScore`: an understanding score from 0 to 100.
  - `aiFeedback`: feedback on what the summary covered well and what it missed.
- Parse the JSON defensively. If the response is malformed or the request times out, show an error and keep the draft so the user does not lose their text. The user can retry, or save without a score (`aiScore = null`) and evaluate later.

**Create / Update (`Cloud Firestore`):**
- **Create** (new session): write a new document to `study_logs` with `userId`, `articleTitle`, `articleUrl`, `originalContent`, `userSummary`, `readingTimeMinutes`, `aiScore`, `aiFeedback`, and `createdAt` set to a server timestamp. The document ID is generated in the app when the screen opens, so retrying after a timeout overwrites the same document instead of creating a duplicate.
- **Update** (edit mode): update only `userSummary`, `aiScore`, `aiFeedback`, and `updatedAt` on the existing document. Do not change `createdAt`, `originalContent`, or `articleTitle`.
- Use the document ID from the previous screen when editing.

**Navigation:** Show the score and feedback on screen. When the user taps **Done**, return to `HomeScreen`. The list refreshes automatically through the stream.

---

### Step 5: Preferences and Account (`ProfileScreen`, Local Storage and Logout)

**User action:** The user changes the default reading time (15, 30, or 45 minutes), toggles **Dark Mode**, or taps **Logout**.

**Local storage (`SharedPreferences`):**
- Save `defaultTimerMinutes` with `setInt`.
- Save `isDarkMode` with `setBool`.
- Load both values at app startup, before the first screen is built, so the theme and timer default are correct from the start.

**Logout:**
- Call `FirebaseAuth.instance.signOut()`.
- Navigate to `AuthScreen` and clear the navigation stack, so the back button cannot return to protected screens.

---

## 3. Cloud Firestore Schema (`study_logs` Collection)

| Field Name | Data Type | Description |
| --- | --- | --- |
| `logId` | `String` | Firestore document ID, generated automatically. Not stored as a field. |
| `userId` | `String` | Firebase Authentication UID. Used to separate each user's data. |
| `articleTitle` | `String` | Article title from the Wikipedia API. |
| `articleUrl` | `String` | Link to the original Wikipedia page. |
| `originalContent` | `String` | First 3,000 characters of the article, used as the reference for evaluation. |
| `userSummary` | `String` | The user's own summary. Passes form validation (at least 50 characters). |
| `readingTimeMinutes` | `Number` | Time spent reading. Starts from the `SharedPreferences` default and is updated to the actual time spent. |
| `aiScore` | `Number` or `null` | Completeness score from the LLM (0–100). `null` means not evaluated yet. |
| `aiFeedback` | `String` or `null` | Feedback from the LLM on covered and missed points. |
| `createdAt` | `Timestamp` | When the log was first created. Set once and never changed. |
| `updatedAt` | `Timestamp` | When the summary was last edited. Set only in edit mode. |

### Security Rules (recommended)

Restrict reads, updates, and deletes to the owner:

```
match /study_logs/{logId} {
  allow read, delete: if request.auth != null
                      && resource.data.userId == request.auth.uid;
  allow create: if request.auth != null
                && request.resource.data.userId == request.auth.uid;
  allow update: if request.auth != null
                && resource.data.userId == request.auth.uid
                && request.resource.data.userId == resource.data.userId;
}
```

---

## 4. Summary of Requirements Covered

| Requirement | Where it is used |
| --- | --- |
| Authentication | Step 1: Firebase Authentication (email and password) |
| Asynchronous operations | Steps 1, 3, 4: auth calls, Wikipedia GET, LLM POST |
| External API #1 | Step 3: Wikipedia REST API |
| External API #2 | Step 4: LLM via the Groq cloud API |
| External package | Step 3: `url_launcher` for search links |
| Local storage | Steps 3 and 5: SharedPreferences |
| Form validation | Steps 1 and 4 |
| CRUD on Cloud Firestore | Read and Delete (Step 2), Create and Update (Step 4) |
| Real-time UI | Step 2: StreamBuilder over `study_logs` |

---

## 5. Additional Features (updated 26 Oct 2026)

| Feature | Where | Notes |
| --- | --- | --- |
| First-run setup | `OnboardingScreen` | After registering: nickname, profile picture (5 animal characters or own photo), app language, article language, reading time. Cannot be skipped. |
| Three language settings | Settings, `SettingsService` | App language (UI + AI feedback + greeting), random-article language, TTS language (AUTO = article language). Shown as language names English / Chinese / Thai, English first and default. Confirming asks to restart the app; "Later" keeps the current language until the next launch. |
| Daily greeting | `HomeScreen`, `GreetingService` | "Hello, {nickname}" plus one line written by the AI once per day per language; cached in SharedPreferences, falls back to a fixed line. |
| Topics & search | start sheet, `WikipediaSource` | 5 popular topics (`articletopic:` + random) or a typed topic (search engine, relevance). Already-read articles are excluded; when every article in a topic is read, the app says so for that source and language. |
| Tags (max 3) | `SummaryScreen`, `HomeScreen` | The chosen topic plus AI-suggested tags; the user can edit them before saving. Stored as `tags` in `study_logs` and shown on each history card. No separate category filter. |
| Data sources | Settings, `ArticleSource` | Wikipedia today; new sources or plugins can be added by implementing `ArticleSource`. |
| Pause / resume session | `ReadingScreen`, `HomeScreen`, `SessionService` | Stored per user in SharedPreferences; random is locked until the summary is saved or the session is discarded. |
| Text-to-speech | `ReadingScreen`, `TtsService` | Play / pause / stop / speed with paragraph highlight. |
| Warm Reading Lamp | `ReadingLampBackground` | Soft spotlight that follows touch and breathes while idle. |
| Stat reveal effect | `StatRevealCard` | Card pops in, label types out, number counts up (ease-out) — replays every time Home is shown. |

See [architecture.md](architecture.md) for the code-level explanation, Firestore schema, and security rules.
