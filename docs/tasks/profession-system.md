# Задача: система професій майстра (епік, issues #6–#11)

Гілка: `feature/profession-system`. Прочитай також `CLAUDE.md`, там загальні правила проєкту.

## Мета
Під час реєстрації майстер обирає свою спеціалізацію. Додаток її запам'ятовує і через один
шар налаштувань (`ProfessionConfig`) підлаштовує іконки, підказки, а в майбутньому і функції.
Нова професія додається одним `case` в enum і одним блоком конфігурації. Решту коду не чіпаємо.

Функціонал (записи, клієнти, послуги, аналітика) для всіх професій ОДНАКОВИЙ.
Відрізняється лише оформлення та підказки. Окремих моделей чи полів під професію НЕ робимо.

## Поза межами цієї задачі
- Візуальний редизайн екранів входу й реєстрації. Він буде окремою задачею ПІСЛЯ цієї.
  Тому UI тут має бути простим, акуратним і робочим, а вся логіка винесена з View,
  щоб під час редизайну мінялися тільки View-файли.
- Сервер (Supabase). Але значення, які зберігаємо, мають бути готові до синхронізації (див. нижче).

## Професії v1
| case | rawValue (НЕ МІНЯТИ НІКОЛИ) | Приклади (підзаголовок картки) |
|---|---|---|
| `hairStylist` | `"hair_stylist"` | перукар, колорист, стиліст |
| `nailArtist` | `"nail_artist"` | манікюр, педикюр, нігтьовий сервіс |
| `lashBrowArtist` | `"lash_brow_artist"` | лешмейкер, бровист |

`rawValue` іде в базу, а пізніше і на сервер. Перейменовувати можна `case`, але не `rawValue`.

## Архітектура
Нова папка `Profession/`:

1. **`Profession.swift`**: `enum Profession: String, CaseIterable, Identifiable, Codable`.
   - `id` = `rawValue`.
   - `var config: ProfessionConfig`: ОДИН вичерпний `switch` (без `default:`), щоб компілятор
     сам вимагав конфігурацію для кожної нової професії.
2. **`ProfessionIcon.swift`**: `enum ProfessionIcon { case system(String); case asset(String) }`
   і `var image: Image`. Зараз використовуємо SF Symbols. Пізніше їх замінять власні іконки
   в стилі логотипа (`.asset`), і View при цьому не зміняться.
3. **`ProfessionConfig.swift`**: `struct ProfessionConfig` з полями:
   - `titleKey`, `descriptionKey`, `examplesKey`: ключі `Localizable.strings`;
   - `icon: ProfessionIcon`: головна іконка професії (картка вибору, налаштування);
   - `serviceIcon: ProfessionIcon`: іконка «послуг» для цієї професії;
   - `suggestedServiceKeys: [String]`: ключі назв типових послуг (поки лише дані, без UI);
   - `static let generic`: нейтральна конфігурація, коли професію не обрано
     (іконки як зараз: послуги = `scissors`).
   Майбутні параметри (аналітика, фічі, категорії послуг) додаються сюди новими полями.
4. **`ProfessionManager.swift`**: `final class ProfessionManager: ObservableObject`.
   - `@Published private(set) var current: Profession?`
   - `var config: ProfessionConfig { current?.config ?? .generic }`
   - `func apply(_ profession: Profession?)`, `func reset()`.
   - Підключається в `BeautyCRMApp` як `.environmentObject`, так само як `ThemeManager` і `CurrencyManager`.
   - View НІКОЛИ не перевіряють `if profession == .nailArtist`. Вони беруть значення з `professionManager.config`.

Іконки v1 (усі доступні в iOS 17; якщо якоїсь немає, підбери найближчу і скажи Сергію):
| | `icon` | `serviceIcon` |
|---|---|---|
| hairStylist | `scissors` | `scissors` |
| nailArtist | `hand.raised.fingers.spread` | `paintbrush.pointed` |
| lashBrowArtist | `eye` | `eyebrow` |
| generic | `sparkles` | `scissors` |

## Збереження
- `UserProfile`: додати `var professionRaw: String? = nil` (обов'язково зі значенням за
  замовчуванням `nil`, щоб у старих користувачів база відкрилась без втрати даних) і
  обчислювану властивість `profession: Profession?` (get/set через `rawValue`).
  Невідоме значення читається як `nil` і не ламає додаток.
- Зміна професії = зміна профілю, тому має оновлювати `updatedAt` так само, як інші зміни
  (див. `SyncTrackable`).
- Відновлення: розширити `UserProfileLoader.load(...)`, щоб він також викликав
  `professionManager.apply(profile.profession)`. Викликати loader в усіх трьох місцях:
  1. після входу (`LoginView`);
  2. після реєстрації (`SignUpFlowView.finishRegistration`);
  3. при холодному старті, коли сесія вже збережена (`SplashView` → `.main`).
     Перевір, чи зараз там відновлюються мова й валюта. Якщо ні, виправ заодно і скажи Сергію.
- Вихід (`SettingsView` → logout): `professionManager.reset()`.

## Реєстрація
- Замінити магічні числа кроків на `enum SignUpStep: Int, CaseIterable`:
  `account, profile, profession, business, currency`.
  Прогрес «Крок X з N» брати з `SignUpStep.allCases.count`. Ключ `signup.ofFour` замінити
  форматованим `signup.stepOf` = «Крок %d з %d» у всіх 5 мовах.
- `SignUpState`: `@Published var profession: Profession?`. Крок не пускає далі, поки професію
  не обрано (помилка `signup.error.profession`).
- `finishRegistration`: записати `professionRaw` у новий `UserProfile`.

## Компонент вибору: `ProfessionPickerView`
Один компонент, який використовується в трьох місцях: крок реєстрації, екран для старих
акаунтів і Налаштування.
- Вхід: `@Binding var selection: Profession?`. Своєї логіки збереження в компоненті немає.
- Картки на всю ширину, вертикальним списком: іконка в колі, назва, приклади дрібним текстом.
- Обрана картка: рамка кольору `colors.accent`, галочка, легке збільшення (spring-анімація).
  Плюс `.sensoryFeedback(.selection, trigger:)`.
- Кольори тільки через `ThemeManager`. Кожна картка — `Button` з `.accessibilityAddTraits(.isSelected)`.
- Список карток будується з `Profession.allCases`, тому нова професія з'являється сама.

## Шар кастомізації: перше реальне використання
- Головна → швидка дія «Послуги»: іконка = `professionManager.config.serviceIcon`.
- Налаштування: новий рядок «Спеціалізація» з поточною професією. Відкриває `ProfessionPickerView`
  і зберігає вибір у профіль.
- Старі акаунти без професії: після входу / холодного старту, якщо `profile.profession == nil`,
  один раз показати повноекранний `ProfessionPickerView` із кнопкою «Продовжити»
  (закрити можна тільки після вибору).

## Локалізація
Усі нові тексти — ключами у всіх 5 файлах `Localizable.strings` (uk, en, de, pl, cs):
`profession.<rawValue>.title`, `.description`, `.examples`, `profession.picker.title`,
`profession.picker.subtitle`, `settings.profession`, `signup.stepOf`, `signup.error.profession`,
`service.suggestion.*` (назви з `suggestedServiceKeys`, 4–6 на професію).

## Тести (BeautyCRMTests)
- Кожна професія має конфігурацію з непорожніми ключами.
- `rawValue` → `Profession` → `rawValue` дає те саме значення; невідомий рядок дає `nil`.
- `UserProfile` без професії (старий користувач) читається з `profession == nil`.
- Усі нові ключі присутні в усіх 5 файлах `Localizable.strings` (тест або скрипт).

## Порядок роботи (один крок = один коміт, після кожного кроку build + тести)
1. #6: `Profession`, `ProfessionIcon`, `ProfessionConfig` + тести.
2. #8: поле в `UserProfile` + перевірка, що існуюча база відкривається.
3. #10: `ProfessionManager`, loader, холодний старт, logout.
4. #9: `ProfessionPickerView` (+ SwiftUI Preview для всіх станів).
5. #7: крок у реєстрації та рефакторинг `SignUpStep`.
6. #11: іконка на Головній, рядок у Налаштуваннях, екран для старих акаунтів.

Після кроків 4, 5 і 6 зупинись і попроси Сергія перевірити в симуляторі. Перевіряємо:
- нова реєстрація для кожної з 3 професій → правильна іконка «Послуги» на Головній;
- вихід → вхід → професія та сама;
- перезапуск додатку → професія та сама;
- старий акаунт без професії → з'являється вибір, після вибору більше не з'являється;
- зміна професії в Налаштуваннях → іконка одразу міняється.

## Як додати нову професію в майбутньому
1. Новий `case` у `Profession` з новим `rawValue`.
2. Компілятор вкаже на `switch` у `config`: заповнити конфігурацію.
3. Ключі локалізації в 5 мовах.
Більше нічого міняти не треба.
