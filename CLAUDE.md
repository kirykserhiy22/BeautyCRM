# BeautyCRM — пам'ять проєкту для Claude

## Про проєкт
iOS-додаток для майстрів б'юті-сфери (перукарі, колористи, лешмейкери, бровисти, манікюр/педикюр):
записи, клієнтська база з фото, послуги, вихідні дні, базова аналітика.
Ринок: Європа (мови: uk, en, de, pl, cs; валюти: EUR, USD, UAH, CZK, PLN, GBP).

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
- `Auth/` — вхід, реєстрація (`SignUp/`, 4 кроки), сесія, профіль користувача (`User/`), валюта
- `Client/` — моделі `Client`, `ClientPhoto`; фото зберігаються файлами в Documents/client_photos
- `Appointment/` — модель `Appointment`, `AppointmentEngine` (конфлікти часу, створення)
- `Services/` — модель `Service` (fixed/variable ціна), `AppointmentServiceItem`
- `Home/`, `Calendar/`, `Analytics/`, `Settings/`, `MainTabBar/`
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
- Гроші — `Decimal` (не `Double`). Показ — тільки `CurrencyManager.format`, ввід — `AppFormatting.parseMoney`.
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

## Відомі проблеми (станом на 23.10.2026)
- `LocalAuthService` зберігає email і пароль відкритим текстом в UserDefaults — замінити на Supabase Auth.
- Сесія (`SessionManager`) — userID в UserDefaults, без токена.
- `AuthValidationError` і `AuthUser` ніде не використовуються (мертвий код); `AuthValidationError` має англійські тексти напряму.
- `AppointmentServiceItem.isDeleted` — назва збігається з вбудованою властивістю SwiftData; перейменувати при нагоді.
- Перевірка «email уже зайнятий» на 1-му кроці реєстрації зараз локальна; із Supabase її треба робити обережно (не розкривати чужі email).

## Правила роботи
- Одна задача з Kanban = одна гілка `feature/<назва>`. Перед змінами — коміт.
- Будь-який новий текст в UI — ключем у всі 5 файлів `Localizable.strings`.
- Не редагувати `project.pbxproj` вручну, якщо можна зробити в Xcode.
- Секрети (ключі Supabase тощо) — не в коді й не в git; через xcconfig, доданий у `.gitignore`.
- Claude збирає проєкт і запускає тести сам через `xcodebuild` (Xcode встановлено). Сергій перевіряє
  поведінку руками в додатку. Після зміни типу поля в моделі (як Double → Decimal) старі дані не відкриються —
  попереджати, що треба перевстановити додаток.
- Git: Сергій пушить з Xcode (Integrate → Push…, перевірити, що гілка не `main`); Claude відкриває PR через
  браузер; після Merge Claude перемикає локальну копію на оновлений `main`.

## Поточна фаза / план
1. ✅ Прибирання: мертвий код, назви файлів, показ помилок реєстрації.
2. ✅ Гроші як `Decimal`; підготовка моделей: `workspaceID`, `updatedAt`, `deletedAt`, м'яке видалення.
3. Supabase: проєкт у ЄС, схема БД, RLS-політики.
4. Авторизація: email + пароль, Sign in with Apple, відновлення пароля, Keychain, видалення акаунта.
5. Синхронізація: push/pull змін, фото в Storage, перший вхід на новому телефоні.
6. Юридичне: політика конфіденційності, умови, App Privacy в App Store Connect.
