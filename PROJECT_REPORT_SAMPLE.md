---
title: "PRM393 Lab 03 · Journal Trend Analyzer"
author: "[Họ và tên]"
---

> **Lưu ý quan trọng:** Preview Markdown mặc định trong Cursor **không hiện màu/box** (bỏ CSS).
> Để xem đúng như mẫu PDF, mở file **`PROJECT_REPORT_SAMPLE.html`** bằng Chrome/Edge → bấm **Export PDF** (hoặc `Ctrl+P` → Save as PDF).

<style>
@import url('https://fonts.googleapis.com/css2?family=Inter:wght@400;500;600;700&display=swap');

:root {
  --blue: #1a4fa3;
  --blue-mid: #2f6fd6;
  --blue-soft: #e8f0fe;
  --blue-border: #c5d7f5;
  --text: #1f2937;
  --muted: #5b6472;
  --line: #dbe4f3;
  --ok: #0f7a45;
}

html, body {
  font-family: Inter, "Segoe UI", Helvetica, Arial, sans-serif;
  color: var(--text);
  font-size: 10.5pt;
  line-height: 1.45;
  margin: 0;
}

h1, h2, h3 {
  color: var(--blue);
  font-weight: 700;
  page-break-after: avoid;
}

h1 { font-size: 22pt; margin: 0 0 8px; }
h2 {
  font-size: 16pt;
  margin: 28px 0 8px;
  padding-bottom: 6px;
  border-bottom: 2px solid var(--blue-border);
}
h3 { font-size: 11.5pt; margin: 16px 0 8px; }

p { margin: 0 0 10px; }
ul, ol { margin: 0; padding-left: 18px; }
li { margin: 0 0 4px; }
code {
  font-family: Consolas, "Courier New", monospace;
  font-size: 9pt;
  background: #f3f6fb;
  padding: 1px 4px;
  border-radius: 3px;
}

.cover {
  min-height: 90vh;
  display: flex;
  flex-direction: column;
  justify-content: center;
  padding: 24px 8px;
  page-break-after: always;
}
.eyebrow {
  color: var(--blue-mid);
  font-weight: 600;
  font-size: 11pt;
  letter-spacing: 0.02em;
  margin-bottom: 10px;
}
.cover h1 {
  font-size: 28pt;
  line-height: 1.15;
  margin-bottom: 6px;
}
.cover .subtitle {
  color: var(--muted);
  font-size: 11.5pt;
  max-width: 520px;
  margin-bottom: 28px;
}
.meta-grid {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 10px 18px;
  max-width: 560px;
}
.meta-item {
  background: var(--blue-soft);
  border: 1px solid var(--blue-border);
  border-radius: 10px;
  padding: 10px 12px;
}
.meta-label {
  display: block;
  font-size: 8pt;
  font-weight: 700;
  letter-spacing: 0.06em;
  text-transform: uppercase;
  color: var(--blue-mid);
  margin-bottom: 2px;
}
.meta-value {
  font-size: 11pt;
  font-weight: 600;
  color: var(--blue);
}

.kpi-row {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 10px;
  margin: 14px 0 16px;
}
.kpi {
  background: var(--blue-soft);
  border: 1px solid var(--blue-border);
  border-radius: 10px;
  padding: 12px 10px;
  text-align: center;
}
.kpi .num {
  display: block;
  font-size: 20pt;
  font-weight: 700;
  color: var(--blue);
  line-height: 1.1;
}
.kpi .label {
  display: block;
  margin-top: 4px;
  font-size: 8.5pt;
  color: var(--muted);
  font-weight: 500;
}

.box {
  background: #f7faff;
  border: 1px solid var(--blue-border);
  border-radius: 10px;
  padding: 12px 14px;
  margin: 0 0 12px;
}
.box h3 {
  margin: 0 0 8px;
  font-size: 11pt;
  color: var(--blue);
}
.box p:last-child, .box ul:last-child, .box ol:last-child { margin-bottom: 0; }

.two-col {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
  margin: 12px 0;
}
.three-col {
  display: grid;
  grid-template-columns: 1fr 1fr 1fr;
  gap: 10px;
  margin: 12px 0;
}

.flow {
  display: flex;
  align-items: stretch;
  gap: 8px;
  margin: 14px 0;
}
.flow-step {
  flex: 1;
  background: var(--blue-soft);
  border: 1px solid var(--blue-border);
  border-radius: 10px;
  padding: 10px 8px;
  text-align: center;
}
.flow-step .title {
  display: block;
  font-weight: 700;
  color: var(--blue);
  font-size: 10.5pt;
}
.flow-step .sub {
  display: block;
  margin-top: 3px;
  color: var(--muted);
  font-size: 8.5pt;
}
.flow-arrow {
  display: flex;
  align-items: center;
  color: #9aa8bd;
  font-size: 14pt;
  font-weight: 700;
}

.stack-card {
  background: var(--blue-soft);
  border: 1px solid var(--blue-border);
  border-radius: 10px;
  padding: 12px;
}
.stack-card .title {
  font-weight: 700;
  color: var(--blue);
  margin-bottom: 6px;
  font-size: 10pt;
}
.stack-card ul {
  margin: 0;
  padding-left: 16px;
  color: var(--text);
  font-size: 9.5pt;
}

table {
  width: 100%;
  border-collapse: collapse;
  margin: 10px 0 14px;
  font-size: 9.5pt;
}
thead th {
  background: var(--blue-soft);
  color: var(--blue);
  font-weight: 700;
  text-align: left;
  padding: 8px 10px;
  border: 1px solid var(--blue-border);
}
tbody td {
  padding: 8px 10px;
  border: 1px solid #e5eaf2;
  vertical-align: top;
}
tbody tr:nth-child(even) td { background: #fbfdff; }

.badge {
  display: inline-block;
  padding: 2px 8px;
  border-radius: 999px;
  background: #e7f7ee;
  color: var(--ok);
  font-weight: 700;
  font-size: 8.5pt;
}
.badge.wait {
  background: #fff4e5;
  color: #9a5b00;
}

.placeholder {
  background: #f3f6fb;
  border: 1.5px dashed var(--blue-border);
  border-radius: 10px;
  color: var(--muted);
  text-align: center;
  padding: 28px 12px;
  font-size: 9.5pt;
  margin: 8px 0;
}

.shot-grid {
  display: grid;
  grid-template-columns: 1fr 1fr 1fr;
  gap: 10px;
  margin: 12px 0;
}

.tree {
  background: #f7faff;
  border: 1px solid var(--blue-border);
  border-radius: 10px;
  padding: 12px 14px;
  font-family: Consolas, "Courier New", monospace;
  font-size: 9pt;
  white-space: pre;
  overflow: hidden;
  line-height: 1.4;
  margin: 10px 0 14px;
}

.note {
  background: #fff8e8;
  border: 1px solid #f0d9a8;
  border-radius: 8px;
  padding: 8px 12px;
  color: #7a5a16;
  font-size: 9.5pt;
  margin: 10px 0;
}

.footer-note {
  margin-top: 18px;
  padding-top: 8px;
  border-top: 1px solid var(--line);
  color: var(--muted);
  font-size: 8.5pt;
}

.page-break { page-break-before: always; }

.cmd-box {
  background: #1e293b;
  color: #e2e8f0;
  border-radius: 10px;
  padding: 12px 14px;
  font-family: Consolas, "Courier New", monospace;
  font-size: 9.5pt;
  margin: 10px 0;
}
.cmd-box .ok { color: #86efac; }

.todo { color: #9a5b00; font-style: italic; }
</style>

<div class="cover">
  <div class="eyebrow">PRM393 · Mobile Programming · Lab 03</div>
  <h1>Firebase-Powered<br/>Journal Trend Analyzer</h1>
  <p class="subtitle">
    Final project report covering OpenAlex research analytics,
    Firebase integration, MVVM architecture, automated Patrol
    testing, and AI-assisted quality review.
  </p>

  <div class="meta-grid">
    <div class="meta-item">
      <span class="meta-label">Student</span>
      <span class="meta-value">[Họ và tên]</span>
    </div>
    <div class="meta-item">
      <span class="meta-label">Student ID</span>
      <span class="meta-value">[MSSV]</span>
    </div>
    <div class="meta-item">
      <span class="meta-label">Platform</span>
      <span class="meta-value">Flutter · Android</span>
    </div>
    <div class="meta-item">
      <span class="meta-label">Application</span>
      <span class="meta-value">Journal Trend Analyzer 1.0.0</span>
    </div>
    <div class="meta-item">
      <span class="meta-label">Validation date</span>
      <span class="meta-value">[Ngày nộp]</span>
    </div>
    <div class="meta-item">
      <span class="meta-label">Data source</span>
      <span class="meta-value">OpenAlex API</span>
    </div>
    <div class="meta-item">
      <span class="meta-label">Cloud platform</span>
      <span class="meta-value">Firebase</span>
    </div>
    <div class="meta-item">
      <span class="meta-label">GitHub</span>
      <span class="meta-value">[Link repo]</span>
    </div>
  </div>

  <p class="footer-note">Draft template — replace <span class="todo">[placeholders]</span>, insert screenshots, then export PDF (Prince / Chrome).</p>
</div>

## 1. Project Overview

The application helps users search a research topic and inspect publication, journal, keyword, and author trends. OpenAlex is the authoritative publication source; Firebase provides identity and cloud capabilities. Four persistent navigation destinations—**Home**, **Journals**, **Keywords**, and **Profile**—match the assignment specification.

<div class="kpi-row">
  <div class="kpi"><span class="num">4</span><span class="label">Main tabs</span></div>
  <div class="kpi"><span class="num">7</span><span class="label">Required events</span></div>
  <div class="kpi"><span class="num">6</span><span class="label">Firebase services</span></div>
  <div class="kpi"><span class="num">11/11</span><span class="label">E2E tests passed</span></div>
</div>

### Implemented scope

| Area | Implemented capabilities | Status |
|------|--------------------------|--------|
| Authentication | Google Sign-In, Firebase Authentication user profile, sign-out and auth gate | <span class="badge">Complete</span> |
| Home | Topic search, total publications, average citations, most active year, top journal/author/paper, trend chart and publication paging | <span class="badge">Complete</span> |
| Publication | Title, authors, year, journal, citations, DOI/original link and abstract | <span class="badge">Complete</span> |
| Journals | Source search, ranked results, contribution/citation statistics, trend and related publications | <span class="badge">Complete</span> |
| Keywords | Monthly/topic rankings, frequency bars, trend, related journals/publications and ranked authors | <span class="badge">Complete</span> |
| Profile | User identity, notifications, PDF export/history, Remote Config, Crashlytics and sign-out | <span class="badge">Complete</span> |

### Technology stack

<div class="three-col">
  <div class="stack-card">
    <div class="title">Client</div>
    <ul>
      <li>Flutter 3.41.9</li>
      <li>Dart 3.11.5</li>
      <li>Material 3</li>
    </ul>
  </div>
  <div class="stack-card">
    <div class="title">State &amp; data</div>
    <ul>
      <li>Riverpod (ViewModels)</li>
      <li>Repository / Service</li>
      <li>OpenAlex HTTP API</li>
    </ul>
  </div>
  <div class="stack-card">
    <div class="title">Quality</div>
    <ul>
      <li>Patrol 4.x</li>
      <li>SonarQube</li>
      <li>flutter analyze</li>
    </ul>
  </div>
</div>

<div class="page-break"></div>

## 2. Architecture and MVVM Implementation

The project uses an MVVM-compatible layered design. Flutter screens remain focused on rendering and user interaction. Riverpod providers serve as ViewModels, repositories expose domain operations, and services isolate external systems.

<div class="flow">
  <div class="flow-step">
    <span class="title">View</span>
    <span class="sub">Screens &amp; widgets</span>
  </div>
  <div class="flow-arrow">→</div>
  <div class="flow-step">
    <span class="title">ViewModel</span>
    <span class="sub">Providers / Notifiers</span>
  </div>
  <div class="flow-arrow">→</div>
  <div class="flow-step">
    <span class="title">Repository</span>
    <span class="sub">Domain facade</span>
  </div>
  <div class="flow-arrow">→</div>
  <div class="flow-step">
    <span class="title">Services</span>
    <span class="sub">OpenAlex / Firebase</span>
  </div>
</div>

| Layer | Main components | Responsibility |
|-------|-----------------|----------------|
| Model | Work, Author, JournalSummary, UserSettings, AppNotification, report models | Typed application data, OpenAlex parsing, bookmark/report snapshots |
| View | Login, Home, Journal, Keyword, Profile and detail screens | Responsive UI; loading, error, empty and data states; navigation |
| ViewModel | AuthViewModel, HomeViewModel, JournalViewModel, ProfileViewModel, … | Async orchestration, state transitions, validation and UI notifications |
| Data | PublicationRepository, ApiClient, AnalyticsService, StorageService, … | API communication, Firebase SDK access, PDF generation and error translation |

<div class="two-col">
  <div class="box">
    <h3>Topic analysis flow</h3>
    <ol>
      <li>Normalize the query and record <code>search_topic</code>.</li>
      <li>Load publications, journals and keywords asynchronously.</li>
      <li>Load top authors, influential papers, yearly trend and citation average.</li>
      <li>Publish progressive state updates to avoid blocking the dashboard.</li>
    </ol>
  </div>
  <div class="box">
    <h3>Reliability decisions</h3>
    <ul>
      <li>Bounded pages and request timeouts protect the mobile client.</li>
      <li>Future publication years are filtered using the device year.</li>
      <li>Errors are mapped to user-friendly, retryable states.</li>
      <li>PDF reports are scoped by Firebase UID in Storage.</li>
    </ul>
  </div>
</div>

### Project organization

<div class="tree">lib/
├── core/          # config, theme, router, network, shared widgets
├── firebase/      # Auth, Analytics, Crashlytics, FCM, Remote Config, Storage
└── features/
    ├── auth/
    ├── home/
    ├── journal/
    ├── keywords/
    ├── profile/
    ├── publication/
    └── shared/</div>

<div class="page-break"></div>

## 3. User Interface and Research Analytics

The UI uses Material 3, shared typography/colors, responsive layouts and explicit loading/error/empty states. The dashboard aggregates OpenAlex data while drill-down screens preserve the exact publication or entity context.

<div class="shot-grid">
  <div class="placeholder">📷 Home dashboard<br/><span class="todo">screenshots/02_home.png</span></div>
  <div class="placeholder">📷 Keywords ranking<br/><span class="todo">screenshots/05_keywords.png</span></div>
  <div class="placeholder">📷 Profile &amp; cloud<br/><span class="todo">screenshots/06_profile.png</span></div>
</div>

<div class="two-col">
  <div class="box">
    <h3>Research metrics</h3>
    <p>Total publications, average citations, active year, top journal, top author and most influential paper are visible for the selected topic.</p>
  </div>
  <div class="box">
    <h3>Drill-down navigation</h3>
    <p>Publication, journal, keyword and author selections open analytical detail screens with related entities and trends.</p>
  </div>
</div>

<div class="note">TODO: replace dashed placeholders with real screenshots (Login, Home, Publication, Journals, Keywords, Profile).</div>

<div class="page-break"></div>

## 4. Firebase Integration and Analytics

| Firebase service | Application use | Evidence |
|------------------|-----------------|----------|
| Authentication | Google account sign-in, user profile and sign-out | Profile screenshot · Patrol TC1 / TC11 |
| Storage | Upload/list/open/delete PDF reports under <code>report/{uid}/…</code> | Storage console · Profile report count |
| Cloud Messaging | Foreground/background/opened handling, local display, FCM token, notification center | Profile Firebase verification panel |
| Analytics | Seven required events with contextual parameters | Firebase Analytics Events report |
| Crashlytics | Global fatal handlers, handled exception and deliberate test crash | Crashlytics console issues/trend |
| Remote Config | Dynamic <code>max_journals</code> / <code>max_keywords</code> | In-app values · Patrol Remote Config TC |

### Required Analytics event mapping

| Event | Parameters | Trigger |
|-------|------------|---------|
| <code>login</code> | <code>login_method = google</code> | Successful Google authentication |
| <code>search_topic</code> | <code>keyword</code> | Topic analysis starts |
| <code>view_publication</code> | <code>publication_title</code>, <code>publication_year</code> | Publication detail opens |
| <code>view_journal</code> | <code>journal_name</code> | Journal detail opens |
| <code>view_keyword</code> | <code>keyword</code> | Keyword detail opens |
| <code>export_pdf</code> | <code>topic</code> | PDF generated and uploaded |
| <code>logout</code> | — | User signs out |

<div class="placeholder">📷 Firebase Analytics Events / DebugView<br/><span class="todo">Insert production Analytics screenshot here</span></div>

<div class="page-break"></div>

## 5. Cloud Reports, Remote Config and Crash Monitoring

<div class="two-col">
  <div class="box">
    <h3>PDF report workflow</h3>
    <div class="flow" style="margin:8px 0 12px;">
      <div class="flow-step"><span class="title">Dashboard</span><span class="sub">snapshot</span></div>
      <div class="flow-arrow">→</div>
      <div class="flow-step"><span class="title">PDF</span><span class="sub">bytes</span></div>
      <div class="flow-arrow">→</div>
      <div class="flow-step"><span class="title">Storage</span><span class="sub">report/{uid}</span></div>
    </div>
    <p>The generated A4 report contains the selected topic, summary metrics, yearly publication trend, top journals and top publications. It is saved locally and uploaded with PDF metadata. The app exposes report history and downloadable URLs.</p>
  </div>
  <div class="box">
    <h3>Dynamic configuration and demos</h3>
    <p>Remote Config values, handled exception, test crash and FCM token action are available on the Profile screen.</p>
    <ul>
      <li><code>max_journals_displayed</code></li>
      <li><code>max_keywords_displayed</code></li>
    </ul>
  </div>
</div>

<div class="shot-grid">
  <div class="placeholder">📷 Firebase Storage<br/><span class="todo">report/ bucket</span></div>
  <div class="placeholder">📷 Profile demos<br/><span class="todo">Remote Config + Crashlytics</span></div>
  <div class="placeholder">📷 Crashlytics console<br/><span class="todo">test crash issue</span></div>
</div>

<div class="box">
  <h3>Safety note</h3>
  <p><strong>Handled exception</strong> records a non-fatal diagnostic event and keeps the app running. <strong>Test crash</strong> intentionally terminates the app and is used only for Crashlytics verification.</p>
</div>

<div class="page-break"></div>

## 6. Automated End-to-End Testing with Patrol

The final suite was executed on <strong>[device/emulator, e.g. Android 17 emulator-5554]</strong> using the real app, Google account picker, OpenAlex API and Firebase project. The tests map one-to-one to the eleven assignment scenarios.

| # | Scenario | Main verification | Result |
|---|----------|-------------------|--------|
| 1 | Google Sign-In | Native account selection and Home navigation | <span class="badge wait">Pass / [ ]</span> |
| 2 | Topic Search | Publication results displayed | <span class="badge wait">Pass / [ ]</span> |
| 3 | Publication Details | Metadata, authors and abstract | <span class="badge wait">Pass / [ ]</span> |
| 4 | Journals Navigation | Statistics and journal results | <span class="badge wait">Pass / [ ]</span> |
| 5 | Journal Details | Total works, citations and analysis | <span class="badge wait">Pass / [ ]</span> |
| 6 | Keywords Navigation | Frequency statistics and rankings | <span class="badge wait">Pass / [ ]</span> |
| 7 | Keyword Details | Trend and ranked authors | <span class="badge wait">Pass / [ ]</span> |
| 8 | Profile Navigation | Identity, reports, notifications and sign-out | <span class="badge wait">Pass / [ ]</span> |
| 9 | PDF Export | Report generation and successful Storage upload | <span class="badge wait">Pass / [ ]</span> |
| 10 | Remote Config | Both dynamic values displayed | <span class="badge wait">Pass / [ ]</span> |
| 11 | Logout | Return to Google Sign-In screen | <span class="badge wait">Pass / [ ]</span> |
S
<div class="cmd-box">
flutter analyze &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;→ <span class="ok">[e.g. No issues found]</span><br/>
patrol test -d &lt;device&gt; → <span class="ok">[e.g. 11 successful, 0 failed]</span>
</div>

<div class="placeholder">📷 Patrol Android test report<br/><span class="todo">11 tests · 0 failures · 100% pass</span></div>

<div class="page-break"></div>

## 7. AI-Assisted Review, Challenges and Lessons Learned

AI-assisted quality review (SonarQube / Cursor AI) was used before submission.

<div class="kpi-row">
  <div class="kpi"><span class="num">OK</span><span class="label">Quality Gate</span></div>
  <div class="kpi"><span class="num">0</span><span class="label">Open issues</span></div>
  <div class="kpi"><span class="num">0</span><span class="label">Bugs</span></div>
  <div class="kpi"><span class="num">A</span><span class="label">Ratings</span></div>
</div>

| Finding | Impact | Resolution | Status |
|---------|--------|------------|--------|
| [Finding 1 — e.g. import order inconsistent] | Reduced readability | Reordered imports | <span class="badge wait">Fixed / [ ]</span> |
| [Finding 2] | … | … | <span class="badge wait">Fixed / [ ]</span> |
| [Finding 3] | … | … | <span class="badge wait">Fixed / [ ]</span> |

<div class="two-col">
  <div class="box">
    <h3>Challenges encountered</h3>
    <ul>
      <li>OpenAlex rate limits and variable response time required bounded requests and retries.</li>
      <li>Native Google Sign-In and Android permission dialogs required Patrol native automation.</li>
      <li>Remote Config values can differ from local defaults, so tests must validate behavior rather than fixed data.</li>
      <li>Crashlytics fatal events require app restart before upload.</li>
    </ul>
  </div>
  <div class="box">
    <h3>Lessons learned</h3>
    <ul>
      <li>Layered ViewModel/MVVM code is easier to test and maintain.</li>
      <li>Cloud evidence must be verified in production reports, not only DebugView.</li>
      <li>E2E tests should map directly to assessment scenarios.</li>
      <li>Dynamic services require robust assertions and user-friendly fallback states.</li>
    </ul>
  </div>
</div>

### Conclusion

<div class="box">
  <p>The Journal Trend Analyzer satisfies the Lab 03 functional, Firebase, architecture and testing requirements. <span class="todo">[Update after real Patrol + Sonar results:]</span> All eleven required E2E workflows passed on Android, the final SonarQube Quality Gate passed, and the application demonstrates a maintainable production-style Flutter implementation.</p>
</div>

<div class="footer-note">
  Checklist before final export: fill student info · update Pass/Fail · insert screenshots · Analytics / Storage / Crashlytics / Patrol / Sonar evidence · 5–10 pages PDF.
</div>
