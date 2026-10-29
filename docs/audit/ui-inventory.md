# Інвентар UI: підготовка до дизайн-системи

Стан на 28.10.2026: коміт `eb8d241`.

Тут описано, з чого зараз складається інтерфейс: які є кнопки, картки, поля, кольори, шрифти й відступи. Для кожного елемента вказано, де він у коді (`файл:рядок`), і чи він повторюється. Мета — побачити, що варто звести в один спільний компонент.

**Висновок наперед.** Спільних компонентів майже немає. Одна й та сама «картка» чи «кнопка» намальована вручну в 5–10 місцях, і щоразу трохи по-іншому: інший радіус, тінь, відступ або колір. Тому перший крок дизайн-системи — 6–8 базових компонентів (розділ 9).

## 1. Кнопки

| # | Різновид | Як виглядає | Де використовується | Повтор |
|---|---|---|---|---|
| B1 | Головна суцільна | Текст `.headline` білим, фон `colors.buttonPrimary`, ширина на весь екран, радіус 16–18 | `Auth/WelcomeView.swift:95` (радіус 18), `Services/CreateServiceView.swift:124` (16), `Home/DayOffPickerView.swift:59` (16) | 3 копії з різними радіусами |
| B1′ | Головна суцільна, колір задано напряму | Те саме, але колір обходить тему | `Auth/LoginView.swift:142` (`.pink`, радіус 14), `Appointment/Views/AppointmentFormView.swift:511` (`.blue` / `.gray`, 16), `Appointment/Views/AppointmentRow.swift:430` (`.green`, 14) | 3 копії, кожна свого кольору |
| B2 | Другорядна | Текст `colors.accent` на фоні `colors.card`, радіус 18 | `Auth/WelcomeView.swift:110` | 1 |
| B3 | Системна `.borderedProminent` | Стандартна кнопка iOS з заливкою | `Auth/SignUp/SignUpFlowView.swift:147` (без кольору теми), `AppointmentRow.swift:225` (`.green`), `Profession/ProfessionPromptView.swift:45` (`colors.accent`) | 3, у кожної свій колір |
| B4 | Системна `.bordered` | Стандартна кнопка з обведенням | `AppointmentRow.swift:239` (Редагувати), `:262` (Скасувати, `.red`), `:279` (Приховати, `.gray`) | 3 |
| B5 | Плаваюча «+» | Коло з іконкою `plus`, фон `colors.floatingButton`, тінь radius 8, y 4 | `Client/Views/ClientsListView.swift:140`, `Calendar/CalendarScreen.swift:120`, `Services/ServicesListView.swift:79` | 3 однакові копії |
| B6 | Капсула | Текст на `colors.accent` у капсулі | `CalendarScreen.swift:163` («Додати запис») | 1 |
| B7 | Текстова | Системний синій текст | `LoginView.swift:153`, `SignUpFlowView.swift:134` («Назад») | 2 |
| B8 | Знищувальна | `Button(role: .destructive)` | `ClientsListView.swift:126`, `ServicesListView.swift:222` (`colors.buttonDestructive`) | 2 |
| B9 | Чип-меню | Текст і `chevron.down`, фон `colors.card`, радіус 12 або капсула | `Analytics/AnalyticsView.swift:500` (місяць), `:563` (рік), `WelcomeView.swift:41` (мова, капсула) | 3 |

## 2. Картки

| # | Різновид | Як виглядає | Де | Повтор |
|---|---|---|---|---|
| C1 | Рядок налаштувань | Іконка, текст, значення, `chevron.right`; фон `card`, тінь radius 4, y 2 | `Settings/SettingsView.swift:126` | 1 функція, 5 рядків |
| C2 | Швидка дія | Іконка над текстом, фон `card` | `Home/QuickActionsSection.swift:87` | 4 |
| C3 | Статистика дня | Три числа в рядок; радіус 18, обведення й тінь | `Home/TodayStatsCard.swift:54` | 1 |
| C4 | Головна картка «зараз» | Заголовок, ім'я, час, кольорова крапка статусу; радіус 20, тінь | `Home/DashboardAppointmentCard.swift:109` | 1 компонент, 3 стани |
| C5 | Запис | Ім'я, послуги, час, бейдж статусу; розгортається; радіус 18, обведення, тінь radius 6, y 2 | `Appointment/Views/AppointmentRow.swift:300` | 1 |
| C6 | Клієнт у списку | Кружок з першою літерою, ім'я, телефон; радіус 18 | `ClientsListView.swift:77`, `Client/Views/ClientRowView.swift` | 1 |
| C7 | Послуга | Назва, ціна, кнопки при розгортанні; радіус **22**, тінь radius 6, y 3 | `ServicesListView.swift:122` | 1, плюс мертва копія `Services/ServiceRow.swift` |
| C8 | Показник клієнта | Іконка, число `.title2.bold`, підпис; радіус 20 | `Client/Components/ClientStatCard.swift:38` | у кількох місцях |
| C9 | Показник аналітики | Те саме, що C8, але свій код | `Analytics/AnalyticsView.swift:873` | дублює C8 |
| C10 | Спеціалізація | Іконка в колі, назва, приклади, галочка; радіус 18; вибрана має обведення 2 пт і масштаб 1.02 | `Profession/ProfessionPickerView.swift:56` | 1 |
| C11 | Мініатюра теми | Справжні кольори теми в мініатюрі | `Settings/ThemeSettingsView.swift:67` | 1 |
| C12 | Послуга у виборі | Назва, ціна, галочка | `Appointment/Views/ServicePickerView.swift:191` | 1 |

## 3. Поля вводу

| # | Різновид | Як виглядає | Де |
|---|---|---|---|
| I1 | Системне `.roundedBorder` | Тонка рамка iOS | `Auth/SignUp/*Step.swift` (усі кроки реєстрації), `AppointmentRow.swift:382` (фінальна ціна), `AppointmentFormView.swift:372` (змінна ціна) |
| I2 | Поле-картка | `.padding()`, фон `card` або `.white`, радіус 14 | `LoginView.swift:110` (фон `.white` напряму), `AppointmentFormView.swift:186` і `:476`, `CreateServiceView.swift:68` і `:94` |
| I3 | Пошук | Лупа й поле, фон `inputBackground`, радіус 18 | `ClientsListView.swift:192` |
| I4 | Системна `Form` | Сірі секції iOS | `Client/Views/ClientFormView.swift`, `Services/EditServiceView.swift`, `SettingsView.swift:204` (робочі години) |
| I5 | Вибір дати й кроковий лічильник | `DatePicker`, `Stepper` | `AppointmentFormView.swift:420, 425` |
| I6 | Сегменти | `Picker(.segmented)` | `AnalyticsView.swift:389` |

На екранах «Новий клієнт» (I4), «Вхід» (I2) і «Реєстрація» (I1) поля вводу намальовані трьома різними способами.

## 4. Бейджі, чипи, позначки

| Різновид | Як виглядає | Де |
|---|---|---|
| Статус запису | Великими літерами `.caption.bold`, кольоровий текст на `card`, радіус 10. Кольори задані напряму: активний `.blue`, виконано `.green`, скасовано `.red`, архів `.gray` | `AppointmentRow.swift:129, 480` |
| VIP | Зірка й «VIP», фон кольоровий | `Client/Views/Profile/Sections/ClientHeaderSection.swift:31` (ніколи не показується) |
| Аватар-ініціал | Коло 46 пт або велике коло з літерою `.system(size: 34)` білим | `ClientRowView.swift:26`, `ClientHeaderSection.swift:53` |
| Крапка статусу | Маленьке коло кольору стану | `DashboardAppointmentCard.swift:84` |
| Вихідний у календарі | Фон дня `.green.opacity(0.20)` (напряму, не з теми) | `Calendar/CalendarDayCell.swift:110–116` |
| Смужка зайнятості | Сегменти записів у межах дня | `Calendar/DayOccupancyBar.swift:130` |

## 5. Порожні стани

| Екран | Що бачить майстер | Де |
|---|---|---|
| Календар, вільний день | Іконка `calendar.badge.plus`, текст, кнопка-капсула | `CalendarScreen.swift:151` ✅ |
| Головна, немає записів | Картка «Немає записів / Сьогодні вільно 🎉» | `HomeView.swift:88` ✅ |
| Картка клієнта без візитів | «Ще немає візитів» | `ClientAnalyticsSection.swift` ✅ |
| **Клієнти: список порожній** | Порожній екран без підказки | `ClientsListView.swift` ❌ |
| **Послуги: прайс порожній** | Порожній екран без підказки | `ServicesListView.swift` ❌ |
| **Аналітика без даних** | Нулі й порожній графік без пояснення | `AnalyticsView.swift` ❌ |
| **Пошук нічого не знайшов** | Порожній список | `ClientsListView.swift` ❌ |

## 6. Алерти й діалоги

| Що | Тип | Де |
|---|---|---|
| Дублікат клієнта | `.alert` з кнопкою «OK» (не перекладено) | `ClientFormView.swift:86` |
| Видалити фото? | `.alert` | `ClientPhotoGridSection.swift:59` |
| Видалити вибраних клієнтів? | `.confirmationDialog` | `ClientsListView.swift:165` |
| Змінити мову? | `.alert` | `Settings/LanguageSettingsView.swift:90` |
| Нотатки запису | `.alert` (мертвий: ніколи не відкривається) | `AppointmentRow.swift:312` |
| Помилка запису | Червоний текст під формою (текст системний англійський) | `AppointmentFormView.swift:493` |
| Помилки входу й реєстрації | Червоний `.caption` під формою | `LoginView.swift:57`, `SignUpFlowView.swift:90` |
| Скасування запису | **Без підтвердження** | `AppointmentRow.swift:248` |

## 7. Кольори

### 7.1 `ThemeColors`: 22 кольори й де вони використовуються

Кількість — це скільки разів колір згадано в коді екранів (`colors.<назва>`).

| Колір | Classic | Graphite | Pearl Ivory | Використань | Примітка |
|---|---|---|---|---|---|
| `background` | системний `systemGroupedBackground` | сірий 175/180/187 | слонова кістка 247/246/242 | багато | |
| `secondaryBackground` | `systemGray6` | 190/194/200 | 235/233/228 | 3 | |
| `card` | `.white` | **`systemGray5`** | 255/255/252 | багато | Graphite: системний колір, у темному режимі iPhone стає темним |
| `cardSecondary` | `systemGray5` | 247/247/248 | 241/239/234 | 5 | |
| `textPrimary` | `.black` | 35/38/42 | 45/43/38 | багато | |
| `textSecondary` | `.gray` | 96/101/108 | 110/105/95 | багато | |
| `textMuted` | **`systemGray6`** (майже білий) | 150/154/160 | 160/155/145 | 4 | Classic: сірий на білому майже не видно, наприклад порожні кружечки вибору спеціалізації |
| `accent` | `.blue` | 84/92/104 | 145/120/80 | багато | |
| `buttonPrimary` | `.blue` | 84/92/104 | 135/110/75 | 3 | |
| `buttonSecondary` | `systemGray4` | 210/214/220 | 225/220/210 | **0** | не використовується |
| `buttonDestructive` | `.red` | `.red` | `.red` | 2 | однаковий у всіх темах |
| `success` | `.green` | `.green` | `.green` | 13 | однаковий |
| `warning` | `.orange` | `.orange` | `.orange` | **0** | не використовується (на Головній `.orange` написано напряму) |
| `danger` | `.red` | `.red` | `.red` | 2 | однаковий |
| `divider` | чорний 6% | 5% | 4% | 1 | |
| `border` | чорний 5% | 6% | 215/210/200 | кілька | |
| `shadow` | чорний 8% | 6% | 5% | багато | |
| `inputBackground` | `.white` | `.white` | 252/250/245 | 2 | |
| `floatingButton` | `.black` | 65/72/82 | 125/100/65 | 3 | |
| `tabBarBackground` | `.white` | 232/234/237 | 250/249/246 | **0** | таббар не фарбується темою |
| `tabBarInactive` | сірий 70% | `.gray` | 135/130/120 | **0** | не використовується |

### 7.2 Кольори, задані напряму в обхід теми

Усього 44 місця в 20 файлах. Найбільше:

| Файл | Скільки | Що саме |
|---|---|---|
| `Appointment/Views/AppointmentRow.swift` | 9 | статуси `.blue/.green/.red/.gray`, кнопки `.green/.red/.gray`, `Color.green` + `.white` у кнопці підтвердження |
| `Auth/LoginView.swift` | 8 | `.pink` (іконка, кнопка), `.white` (поля, текст), `.red` (помилка), `Color(.systemGroupedBackground)` |
| `Appointment/Views/AppointmentFormView.swift` | 5 | `Color.blue`, `Color.gray.opacity(0.3)`, `.white`, `.red` |
| `Calendar/CalendarDayCell.swift` | 3 | `.green.opacity(...)` для вихідних |
| `Home/HomeView.swift` | 2 | `.orange`, `.green` для стану картки |
| `Auth/SignUp/SignUpFlowView.swift`, `SignUpAccountStep.swift` | 3 | `.red`, `.gray`, `.secondary` |
| Ще 14 файлів | по 1 | здебільшого `.white` як колір тексту на кнопці |

Екрани **Вхід**, **Реєстрація** і **Splash** взагалі не використовують тему, тому виглядають однаково в усіх трьох темах.

## 8. Шрифти, відступи, радіуси

### Шрифти
Скрізь системний шрифт (SF Pro), власного шрифту немає. Найчастіші стилі:

| Стиль | Разів | Типове місце |
|---|---|---|
| `.headline` | 33 | заголовки карток, кнопки |
| `.caption` | 21 | підписи |
| `.subheadline` | 15 | другорядний текст |
| `.title2.bold()` | 14 | заголовки кроків, числа |
| `.caption.bold()` / `.caption.weight(.bold)` | 11 | бейджі (два записи одного й того самого) |
| `.title3` | 6 | іконки |
| `.largeTitle.bold()` | 4 | заголовки Вхід, Реєстрація, Тема |
| `.system(size: 34, weight: .bold)` | 3 | великі суми, аватар |
| `.system(size: 70)`, `(50)`, `(32)` | 3 | логотипи-іконки |

Зафіксованих розмірів текстів немає, тож динамічний розмір шрифту iOS (Dynamic Type) працює для більшості текстів. Виняток — фіксовані `.system(size:)`.

### Радіуси заокруглень
`4` ×3, `8` ×2, `10` ×1, `12` ×7, `14` ×10, `16` ×7, `18` ×20, `20` ×7, `22` ×2, `24` ×1. Це **10 різних значень**; для дизайн-системи досить 3–4: 8, 12, 16, 20.

### Відступи (`spacing` у стеках)
0, 2, 4, 5, 6, 8, 9, 10, 12, 14, 16, 18, 20, 24, 28, 32, 40. Найчастіші: 14 (22 рази), 12 (19), 6 (16), 10 (12), 8 (11). Сітки немає, тож варто звести до шкали 4 / 8 / 12 / 16 / 24 / 32.

### Тіні
4 варіанти: radius 4 / y 2 (налаштування), 6 / 2 (запис), 6 / 3 (послуга), 8 / 4 (плаваюча кнопка). Колір усюди `colors.shadow` ✅.

## 9. Як влаштовані теми і чим вони насправді відрізняються

**Як влаштовано.** `Theme/ThemeManager.swift` повертає структуру `ThemeColors` з 22 кольорів для кожної з тем `classic`, `graphite` і `pearlivory`. Обрана тема зберігається на пристрої (`UserDefaults["app_theme"]`), а не в профілі, тож на іншому телефоні майстер побачить Classic. Кожен екран бере кольори через `theme.colors(for: theme.currentTheme)`; цей рядок скопійований у ~36 View.

**Що насправді відрізняється:**
- фон, картки, текст, акцент, плаваюча кнопка: так, це основна різниця між темами;
- статуси, успіх, небезпека, червоні кнопки: **однакові в усіх темах**;
- таббар: **не залежить від теми**; змінюється лише колір активної вкладки (`.tint(colors.accent)`);
- шрифти, радіуси, тіні, відступи: **однакові в усіх темах**;
- Вхід, Реєстрація, Splash: **тема не застосовується зовсім**.

**Темний режим iPhone.** Додаток його не вимикає (`preferredColorScheme` ніде не задано) і окремої темної палітри не має. Classic складено з частково системних кольорів (`systemGroupedBackground`, `systemGray6`) і частково жорстких (`.white`, `.black`), Graphite має системний `systemGray5` для карток. Коли iPhone у темному режимі, ці кольори перемикаються, а жорсткі ні, і виходить мішанина: темний фон з білими картками, або темна картка з темним текстом у Graphite. Скріншоти в папках `*-dark` це показують.

## 10. Пропозиція базових компонентів

1. `PrimaryButton` / `SecondaryButton` / `DestructiveButton`: замінять B1, B1′, B2, B3, B8 (~12 місць).
2. `FloatingAddButton`: замінить 3 копії B5.
3. `CardContainer(style:)`: фон, радіус, обведення й тінь для C1–C12.
4. `StatTile`: об'єднає C8 і C9.
5. `TextInput` / `SearchField` / `MoneyField`: один вигляд для I1–I3, а `MoneyField` одразу через `parseMoney`.
6. `StatusBadge(status:)`: з кольорами з теми (`success` / `danger` / `warning` / `accent`).
7. `EmptyState(icon:title:action:)`: для 4 екранів без порожнього стану.
8. Токени: `Radius` (8/12/16/20), `Spacing` (4/8/12/16/24/32), `Typography` (6–7 стилів), а також `@Environment(\.themeColors)` замість рядка, скопійованого в ~36 View.
