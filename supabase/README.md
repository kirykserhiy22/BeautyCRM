# Supabase для Beauty Base

Сервер: Supabase, регіон **Central EU (Frankfurt)**. План і порядок кроків (S1–S7) — артефакт «План Supabase».

- `migrations/` — SQL-файли схеми бази. Кожен файл запускається **один раз**, по черзі за датою в назві.
  Що вже запущено, а що ні — у «Журналі міграцій» нижче.
- Ключі й паролі сюди **не** потрапляють: адреса проєкту й публічний ключ — у `Secrets.xcconfig` (поза git),
  пароль бази — лише в менеджері паролів Сергія, службовий ключ `service_role` / `secret` — нікуди не копіюється.

## Крок 1. Створити проєкт (робить Сергій)

1. supabase.com → **Sign in** → «Continue with GitHub».
2. **New organization**: назва `Beauty Base`, план **Free**.
3. **New project**:
   - Name: `beauty-base`
   - Database Password: **Generate a password** → зберегти в менеджері паролів (Claude його не потрібен).
   - Region: **Central EU (Frankfurt)**.
   - **Create new project** — 1–2 хвилини.

## Крок 2. Створити таблиці (S1)

1. Ліве меню → **SQL Editor** → **New query**.
2. Відкрити в Xcode файл `supabase/migrations/20261123120000_initial_schema.sql`, виділити все (⌘A), скопіювати (⌘C).
3. Вставити в SQL Editor → **Run**. Має бути «Success. No rows returned».
   Якщо Supabase попередить «destructive operation» — це через `revoke` (зняття прав з гостя), натиснути **Run this query**.
4. Перевірити:
   - **Table Editor**: 9 таблиць — `appointment_services`, `appointments`, `client_photos`, `clients`, `day_offs`,
     `profiles`, `services`, `workspace_members`, `workspaces`. Біля кожної **без** червоної позначки «Unrestricted»
     (значить, правила доступу RLS увімкнені).
   - **Storage**: є сховище `client-photos` з позначкою **Private**.

Якщо щось пішло не так — скрін помилки Claude, нічого не виправляти вручну.

## Крок 3. Налаштування входу

**Authentication → Sign In / Providers → Email**:
- Enable Email provider — увімкнено.
- **Confirm email** — увімкнено (вхід лише після коду з листа).

Решту (лист із 6-значним кодом, відновлення пароля, поштовий сервіс) налаштуємо на кроці S3.

## Крок 4. Ключі в додаток (S2)

**Project Settings → API Keys** (або **Connect** вгорі):
- **Project URL** — `https://<щось>.supabase.co`
- **Publishable key** (`sb_publishable_…`) або, у старому вигляді, **anon public**.

У Finder: `BeautyCRM/Config/` → скопіювати `Secrets.example.xcconfig` у `Secrets.xcconfig` (у тій самій папці)
і вписати значення:

```
SUPABASE_URL = https:/$()/<щось>.supabase.co
SUPABASE_ANON_KEY = sb_publishable_…
```

`Secrets.xcconfig` у `.gitignore` — у git і в PR не потрапить. Публічний ключ безпечний для додатка: доступ
обмежують правила RLS. **Secret / service_role** ключ не копіювати нікуди, і в чат теж.

## Крок S4. Видалення акаунта

SQL Editor → New query → вставити `migrations/20261124150000_delete_my_account.sql` → Run («Success. No rows returned»).
Перевірка: **Database → Functions** — є `delete_my_account`.

## Журнал міграцій

Кожен новий файл у `migrations/` дописується сюди (автотест `MigrationsJournalTests` падає, якщо забули).
Коли Сергій запускає файл у SQL Editor — у колонці «Запущено» ставимо дату.

| Файл | Що робить | Запущено в Supabase |
|---|---|---|
| `20261123120000_initial_schema.sql` | 9 таблиць, правила доступу RLS, приватне сховище фото | ✅ 23.11.2026 |
| `20261124150000_delete_my_account.sql` | функція «Видалити акаунт» | ✅ 24.11.2026 |
| `20261127120000_appointment_refunds.sql` | поля повернення коштів у записах | ⏳ ще ні — перед синхронізацією (S5) |

**Перед S5 (синхронізація):** запустити всі рядки з ⏳ по черзі, зверху вниз.
