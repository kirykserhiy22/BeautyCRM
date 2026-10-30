# Beauty Base (репозиторій BeautyCRM) — пам'ять проєкту для Claude

## Про проєкт
**Beauty Base** — iOS-додаток для майстрів б'юті-сфери (перукарі, колористи, лешмейкери, бровисти, манікюр/педикюр):
записи, клієнтська база з фото, послуги, вихідні дні, базова аналітика.
Ринок: Європа (мови: uk, en, de, pl, cs; валюти: EUR, USD, UAH, CZK, PLN, GBP).
Назва для користувача — тільки з `Constants.appName`; внутрішні імена (`BeautyCRM`, бандл `Kiryk.BeautyCRM`) не міняти.

Власник проєкту — Сергій. Код читає і розуміє, але сам не пише.
Тому Claude завжди:
- пояснює простими словами, що змінює і навіщо;
- дає зміни маленькими кроками, які можна зібрати й перевірити в Xcode;
- не переписує робочі частини без потреби;
- на великих задачах спершу показує план і чекає погодження.

## Стек
- SwiftUI, SwiftData (локальне сховище), Combine (`ObservableObject` + `@EnvironmentObject`)
- iOS 17.6+, Swift 5
- Без сторонніх бібліотек (поки що)
- Xcode-проєкт: файли поза папкою `BeautyCRM/` додані в target вручну (не synchronized group).
  Новий файл у Auth/, Client/ тощо треба додати в target в Xcode, інакше він не скомпілюється.
  Папки `BeautyCRM/` і `BeautyCRMTests/` — synchronized groups: нові файли там потрапляють у target самі.

## Структура
- `BeautyCRM/` — точка входу (`BeautyCRMApp`), `RootView`, `AppRouter` (enum екранів), `AppState`
- `BeautyCRM/SyncTracking.swift` — протокол `SyncTrackable`, автозаповнення `updatedAt`/`workspaceID` перед кожним save, `markDeleted()`
- `BeautyCRM/SaveErrorReporter.swift` — `context.saveReportingErrors()`: збереження з показом помилки
- `BeautyCRM/MoneyField.swift` — поле суми з підсвіткою неправильного вводу
- `BeautyCRM/AnalyticsEngine.swift` — усі розрахунки аналітики (екран лише показує `AnalyticsSummary`)
- `Auth/` — вхід, реєстрація (`SignUp/`, 5 кроків: акаунт, ім'я, спеціалізація, салон, валюта), сесія,
  профіль (`User/`, `UserProfileManager.update`), валюта
- `Profession/` — спеціалізації майстра (`Profession`, `ProfessionConfig`, `ProfessionManager`)
- `Client/` — моделі `Client`, `ClientPhoto`; фото — файлами в Documents/client_photos;
  `ClientManager.possibleDuplicate` — перевірка дублікатів (ім'я + телефон/Instagram/Telegram)
- `Appointment/` — модель `Appointment` (`AppointmentStatus.canChange(to:)` — дозволені переходи статусів),
  `AppointmentEngine` (конфлікти, створення, редагування зі збереженням погоджених цін, завершення,
  скасування, відновлення, приховування)
- `Services/` — модель `Service` (fixed/variable ціна), `AppointmentServiceItem`
- `Home/`, `Calendar/`, `Analytics/`, `Settings/` (+ екрани Профіль, Робочі години, Спеціалізація), `MainTabBar/`
- `Theme/` — `ThemeManager`, кольори брати тільки через `theme.colors(for:)`
- `Language/` — `LocalizationManager`, `Localizable.strings` для 5 мов
- `Utils/AppFormatting.swift` — формати дат і грошей (`parseMoney`, `moneyInput`)

## Моделі SwiftData
`UserProfile`, `Client`, `ClientPhoto`, `Appointment`, `AppointmentServiceItem`, `Service`, `DayOff`.
- Усі мають `id: UUID` (генерується на пристрої — добре для офлайн-синхронізації).
- Власник даних зараз — поле `userID: String`; плюс `workspaceID` (створюється при реєстрації, старим записам дописується при вході).
- Синхронізовані моделі (`SyncTrackable`): усі, крім `AppointmentServiceItem` — він їде разом зі своїм `Appointment`.
- `updatedAt` і `workspaceID` проставляє `SyncTracking` сам (через `ModelContext.willSave`) — вручну в екранах не ставити.
- Видалення тільки м'яке: `record.markDeleted()`, не `context.delete`. Кожен `@Query`/`FetchDescriptor`
  для клієнтів, фото, послуг, вихідних фільтрує `deletedAt == nil`. Записи на прийом не видаляються (статуси).
- Гроші — `Decimal` (не `Double`). Показ — тільки `CurrencyManager.format`, ввід — `MoneyField`
  або `AppFormatting.parseMoney` (суворий: «12abc» → nil, «1.234,50» → 1234,50). Невалідна сума ≠ 0.
- Зберігати тільки через `context.saveReportingErrors()` — не `try? context.save()`.
- Статус запису змінювати тільки через `AppointmentEngine` (він перевіряє `canChange`), не напряму.
- `Appointment` посилається на клієнта через `clientID: UUID` + копію `clientName`.

## Ключові архітектурні рішення (не відходити без обговорення)
1. **Бекенд: Supabase** (PostgreSQL, сервери в ЄС, Row Level Security). Той самий бекенд
   пізніше обслуговуватиме веб-версію. Android не планується.
2. **Робочий простір (workspace).** Усі бізнес-дані належать workspace, а не користувачу.
   Майстер-одинак = workspace з одним учасником, роль `owner`.
   Ролі: `owner`, `admin`, `master`. Салонні функції в UI з'являються пізніше,
   але модель даних закладається одразу.
3. **Offline-first.** SwiftData лишається локальним джерелом правди для UI.
   Синхронізація з сервером — окремий шар. Для цього кожна синхронізована модель має
   `workspaceID`, `updatedAt`, `deletedAt` (м'яке видалення замість `context.delete`).
4. **Фото клієнтів** — у Supabase Storage (приватний bucket), локально кеш.
5. **Безпека:** паролі ніколи не зберігаються на пристрої; токени сесії — тільки в Keychain;
   жодних персональних даних клієнтів у `print`/логах.
6. **App Store:** обов'язкові «Sign in with Apple» поруч з email-входом і видалення акаунта в додатку.

## Відомі проблеми (станом на 30.10.2026)
- Відкриті знахідки аудиту — у GitHub Issues (критичні #21, #22; дрібниці #37–#63), подробиці — `docs/audit/REPORT.md`.
- `LocalAuthService` зберігає email і пароль відкритим текстом в UserDefaults — замінити на Supabase Auth (#21).
- Сесія (`SessionManager`) — userID в UserDefaults, без токена. Видалення акаунта й Sign in with Apple немає (#22).
- `AppointmentServiceItem.isDeleted` — назва збігається з вбудованою властивістю SwiftData (#59).
- Перевірка «email уже зайнятий» на 1-му кроці реєстрації зараз локальна; із Supabase її треба робити обережно (не розкривати чужі email).
- Темний режим iPhone вимкнено (`.preferredColorScheme(.light)` у `BeautyCRMApp`), поки в тем немає темних палітр.
- **Unit-тести падають на iOS 18.x і 26.2** (`malloc: pointer being freed was not allocated` у
  `swift_task_deinitOnExecutorMainActorBackDeploy` → `TaskLocal::StopLookupScope`): вада рантайму Swift,
  коли об'єкт з ізоляцією MainActor знищується всередині XCTest (той ставить task-local значення).
  Сам додаток на iOS 18.6 і 26.2 перевірено руками (реєстрація, вихід, вхід) — не падає (#25, 30.10.2026).
  Тому тести запускати на симуляторі **iOS 26.4+**. `@MainActor` на тестових класах не допомагає.

## Беклог ідей
Ідеї та доробки (салони, підписки, бренд, редизайн, нагадування) — у `BACKLOG.md`.
Коли Сергій каже «додай в беклог: …» — записати в розділ «Вхідні» або одразу у відповідний розділ.

## Правила роботи
- Одна задача з Kanban = одна гілка `feature/<назва>`. Перед змінами — коміт.
- Будь-який новий текст в UI — ключем у всі 5 файлів `Localizable.strings`.
- Не редагувати `project.pbxproj` вручну, якщо можна зробити в Xcode.
- Секрети (ключі Supabase тощо) — не в коді й не в git; через xcconfig, доданий у `.gitignore`.
- Claude збирає проєкт і запускає тести сам через `xcodebuild` (Xcode встановлено) — на симуляторі iOS 26.4+.
  Щоб зібрати під iOS 18 (симулятор «Audit iPhone 16 (iOS 18.6)»), додати `IPHONEOS_DEPLOYMENT_TARGET=17.6`
  в команду: у тестового target мінімальна iOS 26.2, у додатку — 17.6. Сергій перевіряє
  поведінку руками в додатку. Після зміни типу поля в моделі (як Double → Decimal) старі дані не відкриються —
  попереджати, що треба перевстановити додаток.
- Git: Сергій пушить з Xcode (Integrate → Push…, перевірити, що гілка не `main`); Claude відкриває PR через
  браузер; після Merge Claude перемикає локальну копію на оновлений `main`.

## Поточна фаза / план
1. ✅ Прибирання: мертвий код, назви файлів, показ помилок реєстрації.
2. ✅ Гроші як `Decimal`; підготовка моделей: `workspaceID`, `updatedAt`, `deletedAt`, м'яке видалення.
   ✅ Спеціалізації майстра (PR #19). ✅ Аудит (PR #20) і виправлення всіх важливих знахідок (PR #64–#73).
   Далі за бажанням — дрібниці аудиту пачками (#37–#63).
3. Supabase: проєкт у ЄС, схема БД, RLS-політики.
4. Авторизація: email + пароль, Sign in with Apple, відновлення пароля, Keychain, видалення акаунта.
5. Синхронізація: push/pull змін, фото в Storage, перший вхід на новому телефоні.
6. Юридичне: політика конфіденційності, умови, App Privacy в App Store Connect.
