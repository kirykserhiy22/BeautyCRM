-- =====================================================================
-- Beauty Base — схема бази на сервері (крок S1)
--
-- Дзеркало моделей SwiftData. Усі бізнес-дані належать робочому простору
-- (workspace), а не окремій людині: майстер-одинак — простір з одним
-- учасником (owner), салон — з кількома (owner / admin / master).
--
-- Правила:
--   • Кожна таблиця під Row Level Security: рядок видно й можна змінити,
--     лише якщо ти учасник його workspace.
--   • Жорсткого видалення через додаток немає — лише deleted_at
--     (як у додатку). Стирає все тільки видалення акаунта (крок S4).
--   • updated_at ставить телефон (час зміни, «перемагає новіша»),
--     server_updated_at — сервер (курсор «що змінилось з минулого разу»).
--   • Гроші — numeric(12,2), як Decimal у додатку.
--
-- Як застосувати: Supabase → SQL Editor → New query → вставити весь файл → Run.
-- Файл можна запускати лише один раз на порожньому проєкті.
-- =====================================================================


-- ---------------------------------------------------------------------
-- 1. Робочі простори й учасники
-- ---------------------------------------------------------------------

create type public.workspace_role as enum ('owner', 'admin', 'master');

create table public.workspaces (
    id                uuid primary key,              -- генерується на телефоні при реєстрації
    name              text,
    created_at        timestamptz not null default now(),
    server_updated_at timestamptz not null default now()
);

create table public.workspace_members (
    workspace_id uuid not null references public.workspaces (id) on delete cascade,
    user_id      uuid not null references auth.users (id) on delete cascade,
    role         public.workspace_role not null default 'owner',
    created_at   timestamptz not null default now(),
    primary key (workspace_id, user_id)
);

create index workspace_members_user_idx on public.workspace_members (user_id);


-- Чи є поточний користувач учасником простору.
-- security definer — щоб правило не впиралося саме в себе (RLS на workspace_members).
create function public.is_workspace_member(ws uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    select exists (
        select 1
        from public.workspace_members m
        where m.workspace_id = ws
          and m.user_id = (select auth.uid())
    );
$$;

-- Чи має поточний користувач одну з ролей у просторі (для керування простором)
create function public.has_workspace_role(ws uuid, roles public.workspace_role[])
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
    select exists (
        select 1
        from public.workspace_members m
        where m.workspace_id = ws
          and m.user_id = (select auth.uid())
          and m.role = any (roles)
    );
$$;


-- Створити простір при реєстрації (або підтвердити, що він уже твій).
-- id приходить з телефона — так працює офлайн. Повторний виклик безпечний.
create function public.create_workspace(p_id uuid, p_name text default null)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
    if (select auth.uid()) is null then
        raise exception 'not authenticated';
    end if;

    if exists (select 1 from public.workspaces w where w.id = p_id) then
        if not public.is_workspace_member(p_id) then
            raise exception 'workspace belongs to another account';
        end if;
        return;
    end if;

    insert into public.workspaces (id, name) values (p_id, p_name);
    insert into public.workspace_members (workspace_id, user_id, role)
    values (p_id, (select auth.uid()), 'owner');
end;
$$;


-- ---------------------------------------------------------------------
-- 2. Службове: server_updated_at ставить сам сервер при кожній зміні
-- ---------------------------------------------------------------------

create function public.touch_server_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
    new.server_updated_at := now();
    return new;
end;
$$;

create trigger workspaces_touch
    before update on public.workspaces
    for each row execute function public.touch_server_updated_at();


-- ---------------------------------------------------------------------
-- 3. Профіль майстра  ← UserProfile
--    Пароля тут немає: ним займається Supabase Auth.
-- ---------------------------------------------------------------------

create table public.profiles (
    user_id            uuid primary key references auth.users (id) on delete cascade,
    id                 uuid not null unique,         -- UserProfile.id з телефона
    workspace_id       uuid not null references public.workspaces (id) on delete cascade,
    first_name         text not null default '',
    last_name          text not null default '',
    business_name      text,
    currency_code      text not null default 'EUR',
    language_code      text not null default 'en',
    profession         text,                          -- rawValue: hair_stylist, nail_artist, lash_brow_artist
    work_start_minute  integer check (work_start_minute between 0 and 1440),
    work_end_minute    integer check (work_end_minute between 0 and 1440),
    reminder_address   text,
    reminder_template  text,
    reminder_signature text,
    created_at         timestamptz not null default now(),
    updated_at         timestamptz not null default now(),
    deleted_at         timestamptz,
    server_updated_at  timestamptz not null default now()
);


-- ---------------------------------------------------------------------
-- 4. Клієнти  ← Client
-- ---------------------------------------------------------------------

create table public.clients (
    id                uuid primary key,
    workspace_id      uuid not null references public.workspaces (id) on delete cascade,
    created_by        uuid references auth.users (id) on delete set null default auth.uid(),
    name              text not null,
    phone             text,
    instagram         text,
    telegram          text,
    whatsapp          text,
    viber             text,
    messenger         text,
    notes             text,
    created_at        timestamptz not null default now(),
    updated_at        timestamptz not null default now(),
    deleted_at        timestamptz,
    server_updated_at timestamptz not null default now()
);


-- ---------------------------------------------------------------------
-- 5. Фото клієнтів  ← ClientPhoto
--    Сам файл — у сховищі client-photos, тут лише шлях до нього.
-- ---------------------------------------------------------------------

create table public.client_photos (
    id                uuid primary key,
    workspace_id      uuid not null references public.workspaces (id) on delete cascade,
    client_id         uuid not null references public.clients (id) on delete cascade,
    created_by        uuid references auth.users (id) on delete set null default auth.uid(),
    storage_path      text,                           -- workspace_id/client_id/photo_id.jpg; порожньо, поки файл не завантажено
    caption           text,
    stage             text check (stage in ('before', 'after')),
    post_id           uuid,                           -- кілька фото одного допису (карусель)
    created_at        timestamptz not null default now(),
    updated_at        timestamptz not null default now(),
    deleted_at        timestamptz,
    server_updated_at timestamptz not null default now()
);


-- ---------------------------------------------------------------------
-- 6. Послуги  ← Service
-- ---------------------------------------------------------------------

create table public.services (
    id                uuid primary key,
    workspace_id      uuid not null references public.workspaces (id) on delete cascade,
    created_by        uuid references auth.users (id) on delete set null default auth.uid(),
    name              text not null,
    pricing_type      text not null check (pricing_type in ('fixed', 'variable')),
    price             numeric(12, 2) check (price >= 0),   -- лише для fixed
    created_at        timestamptz not null default now(),
    updated_at        timestamptz not null default now(),
    deleted_at        timestamptz,
    server_updated_at timestamptz not null default now()
);


-- ---------------------------------------------------------------------
-- 7. Записи  ← Appointment
-- ---------------------------------------------------------------------

create table public.appointments (
    id                      uuid primary key,
    workspace_id            uuid not null references public.workspaces (id) on delete cascade,
    created_by              uuid references auth.users (id) on delete set null default auth.uid(),
    master_id               uuid references auth.users (id) on delete set null default auth.uid(),  -- для салону: чий запис
    client_id               uuid not null references public.clients (id) on delete cascade,
    client_name             text not null,           -- копія імені, як у додатку
    start_at                timestamptz not null,
    duration_minutes        integer not null check (duration_minutes > 0),
    status                  text not null check (status in ('active', 'completed', 'cancelled', 'archived')),
    notes                   text,
    completed_at            timestamptz,
    final_price             numeric(12, 2),
    client_reminder_sent_at timestamptz,
    reschedule_requested_at timestamptz,             -- «Перенести пізніше»
    reschedule_notified_at  timestamptz,             -- клієнта повідомили про перенесення
    created_at              timestamptz not null default now(),
    updated_at              timestamptz not null default now(),
    deleted_at              timestamptz,
    server_updated_at       timestamptz not null default now()
);

-- Послуги запису  ← AppointmentServiceItem (їздять разом зі своїм записом)
create table public.appointment_services (
    id                uuid primary key,
    workspace_id      uuid not null references public.workspaces (id) on delete cascade,
    appointment_id    uuid not null references public.appointments (id) on delete cascade,
    service_id        uuid not null,                 -- без зв'язку: послугу могли прибрати з прайсу, назва збережена
    service_name      text not null,
    planned_price     numeric(12, 2) not null,
    final_price       numeric(12, 2),
    duration_minutes  integer,
    position          integer not null default 0,
    server_updated_at timestamptz not null default now()
);


-- ---------------------------------------------------------------------
-- 8. Вихідні  ← DayOff
--    День рядком «2026-11-07» — не залежить від часового поясу.
-- ---------------------------------------------------------------------

create table public.day_offs (
    id                uuid primary key,
    workspace_id      uuid not null references public.workspaces (id) on delete cascade,
    user_id           uuid references auth.users (id) on delete cascade default auth.uid(),  -- чий вихідний (для салону)
    day_key           text not null check (day_key ~ '^\d{4}-\d{2}-\d{2}$'),
    created_at        timestamptz not null default now(),
    updated_at        timestamptz not null default now(),
    deleted_at        timestamptz,
    server_updated_at timestamptz not null default now()
);


-- ---------------------------------------------------------------------
-- 9. Індекси: для синхронізації («що змінилось у просторі після …»)
-- ---------------------------------------------------------------------

create index profiles_sync_idx             on public.profiles             (workspace_id, server_updated_at);
create index clients_sync_idx              on public.clients              (workspace_id, server_updated_at);
create index client_photos_sync_idx        on public.client_photos        (workspace_id, server_updated_at);
create index services_sync_idx             on public.services             (workspace_id, server_updated_at);
create index appointments_sync_idx         on public.appointments         (workspace_id, server_updated_at);
create index appointment_services_sync_idx on public.appointment_services (workspace_id, server_updated_at);
create index day_offs_sync_idx             on public.day_offs             (workspace_id, server_updated_at);

create index client_photos_client_idx        on public.client_photos        (client_id);
create index appointments_client_idx         on public.appointments         (client_id);
create index appointments_start_idx          on public.appointments         (workspace_id, start_at);
create index appointment_services_appt_idx   on public.appointment_services (appointment_id);


-- server_updated_at — на кожну зміну
create trigger profiles_touch             before insert or update on public.profiles             for each row execute function public.touch_server_updated_at();
create trigger clients_touch              before insert or update on public.clients              for each row execute function public.touch_server_updated_at();
create trigger client_photos_touch        before insert or update on public.client_photos        for each row execute function public.touch_server_updated_at();
create trigger services_touch             before insert or update on public.services             for each row execute function public.touch_server_updated_at();
create trigger appointments_touch         before insert or update on public.appointments         for each row execute function public.touch_server_updated_at();
create trigger appointment_services_touch before insert or update on public.appointment_services for each row execute function public.touch_server_updated_at();
create trigger day_offs_touch             before insert or update on public.day_offs             for each row execute function public.touch_server_updated_at();


-- ---------------------------------------------------------------------
-- 10. Row Level Security — правила доступу
-- ---------------------------------------------------------------------

alter table public.workspaces           enable row level security;
alter table public.workspace_members    enable row level security;
alter table public.profiles             enable row level security;
alter table public.clients              enable row level security;
alter table public.client_photos        enable row level security;
alter table public.services             enable row level security;
alter table public.appointments         enable row level security;
alter table public.appointment_services enable row level security;
alter table public.day_offs             enable row level security;

-- Простори: бачить учасник; назву міняє власник чи адмін; створення — лише через create_workspace()
create policy "members read workspace" on public.workspaces
    for select to authenticated
    using (public.is_workspace_member(id));

create policy "owner or admin renames workspace" on public.workspaces
    for update to authenticated
    using (public.has_workspace_role(id, array['owner', 'admin']::public.workspace_role[]))
    with check (public.has_workspace_role(id, array['owner', 'admin']::public.workspace_role[]));

-- Учасники: видно всіх учасників свого простору; додавання людей — пізніше, разом із салонами
create policy "members read members" on public.workspace_members
    for select to authenticated
    using (public.is_workspace_member(workspace_id));

-- Профіль: свій — читати й змінювати; профілі колег по простору — лише читати
create policy "read own or workspace profiles" on public.profiles
    for select to authenticated
    using (user_id = (select auth.uid()) or public.is_workspace_member(workspace_id));

create policy "insert own profile" on public.profiles
    for insert to authenticated
    with check (user_id = (select auth.uid()) and public.is_workspace_member(workspace_id));

create policy "update own profile" on public.profiles
    for update to authenticated
    using (user_id = (select auth.uid()))
    with check (user_id = (select auth.uid()) and public.is_workspace_member(workspace_id));

-- Бізнес-дані: читати, додавати й змінювати — учасникам простору.
-- Політики на delete немає навмисно: видалення лише через deleted_at.
create policy "members read"   on public.clients for select to authenticated using (public.is_workspace_member(workspace_id));
create policy "members insert" on public.clients for insert to authenticated with check (public.is_workspace_member(workspace_id));
create policy "members update" on public.clients for update to authenticated using (public.is_workspace_member(workspace_id)) with check (public.is_workspace_member(workspace_id));

create policy "members read"   on public.client_photos for select to authenticated using (public.is_workspace_member(workspace_id));
create policy "members insert" on public.client_photos for insert to authenticated with check (public.is_workspace_member(workspace_id));
create policy "members update" on public.client_photos for update to authenticated using (public.is_workspace_member(workspace_id)) with check (public.is_workspace_member(workspace_id));

create policy "members read"   on public.services for select to authenticated using (public.is_workspace_member(workspace_id));
create policy "members insert" on public.services for insert to authenticated with check (public.is_workspace_member(workspace_id));
create policy "members update" on public.services for update to authenticated using (public.is_workspace_member(workspace_id)) with check (public.is_workspace_member(workspace_id));

create policy "members read"   on public.appointments for select to authenticated using (public.is_workspace_member(workspace_id));
create policy "members insert" on public.appointments for insert to authenticated with check (public.is_workspace_member(workspace_id));
create policy "members update" on public.appointments for update to authenticated using (public.is_workspace_member(workspace_id)) with check (public.is_workspace_member(workspace_id));

-- Послуги запису замінюються разом із записом, тому тут delete дозволено
create policy "members read"   on public.appointment_services for select to authenticated using (public.is_workspace_member(workspace_id));
create policy "members insert" on public.appointment_services for insert to authenticated with check (public.is_workspace_member(workspace_id));
create policy "members update" on public.appointment_services for update to authenticated using (public.is_workspace_member(workspace_id)) with check (public.is_workspace_member(workspace_id));
create policy "members delete" on public.appointment_services for delete to authenticated using (public.is_workspace_member(workspace_id));

create policy "members read"   on public.day_offs for select to authenticated using (public.is_workspace_member(workspace_id));
create policy "members insert" on public.day_offs for insert to authenticated with check (public.is_workspace_member(workspace_id));
create policy "members update" on public.day_offs for update to authenticated using (public.is_workspace_member(workspace_id)) with check (public.is_workspace_member(workspace_id));


-- ---------------------------------------------------------------------
-- 11. Права: гість (anon) не бачить нічого; увійшов (authenticated) — лише через правила вище
-- ---------------------------------------------------------------------

revoke all on public.workspaces, public.workspace_members, public.profiles, public.clients,
              public.client_photos, public.services, public.appointments,
              public.appointment_services, public.day_offs
    from anon;

grant select, insert, update on public.profiles, public.clients, public.client_photos,
                                public.services, public.appointments, public.day_offs
    to authenticated;
grant select, insert, update, delete on public.appointment_services to authenticated;
grant select, update on public.workspaces to authenticated;
grant select on public.workspace_members to authenticated;

revoke execute on function public.is_workspace_member(uuid) from public, anon;
revoke execute on function public.has_workspace_role(uuid, public.workspace_role[]) from public, anon;
revoke execute on function public.create_workspace(uuid, text) from public, anon;
revoke execute on function public.touch_server_updated_at() from public, anon, authenticated;
grant execute on function public.is_workspace_member(uuid) to authenticated;
grant execute on function public.has_workspace_role(uuid, public.workspace_role[]) to authenticated;
grant execute on function public.create_workspace(uuid, text) to authenticated;


-- ---------------------------------------------------------------------
-- 12. Сховище фото клієнтів — приватне
--     Шлях файлу: <workspace_id>/<client_id>/<photo_id>.jpg
-- ---------------------------------------------------------------------

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('client-photos', 'client-photos', false, 10485760, array['image/jpeg', 'image/heic', 'image/png']);

-- Перша папка шляху як workspace_id; якщо це не uuid — null (доступу не буде)
create function public.storage_workspace_id(object_name text)
returns uuid
language plpgsql
immutable
set search_path = ''
as $$
declare
    first_folder text := split_part(object_name, '/', 1);
begin
    if first_folder ~ '^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$' then
        return first_folder::uuid;
    end if;
    return null;
end;
$$;

grant execute on function public.storage_workspace_id(text) to authenticated;

create policy "members read client photos" on storage.objects
    for select to authenticated
    using (bucket_id = 'client-photos' and public.is_workspace_member(public.storage_workspace_id(name)));

create policy "members upload client photos" on storage.objects
    for insert to authenticated
    with check (bucket_id = 'client-photos' and public.is_workspace_member(public.storage_workspace_id(name)));

create policy "members replace client photos" on storage.objects
    for update to authenticated
    using (bucket_id = 'client-photos' and public.is_workspace_member(public.storage_workspace_id(name)))
    with check (bucket_id = 'client-photos' and public.is_workspace_member(public.storage_workspace_id(name)));

create policy "members delete client photos" on storage.objects
    for delete to authenticated
    using (bucket_id = 'client-photos' and public.is_workspace_member(public.storage_workspace_id(name)));
