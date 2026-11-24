-- =====================================================================
-- Beauty Base — видалення акаунта з додатка (крок S4, вимога App Store)
--
-- delete_my_account() видаляє акаунт ТОГО, хто її викликав (auth.uid()):
--   1) робочі простори, де він єдиний власник, — разом з усіма даними
--      (клієнти, фото, послуги, записи, вихідні — через on delete cascade);
--   2) сам акаунт у auth.users — профіль і членство в інших просторах
--      видаляються каскадом.
-- Чужі акаунти й простори, де є інший власник, функція не чіпає.
-- Файли фото в сховищі з'являться на кроці S6 — тоді функцію доповнимо.
--
-- Як застосувати: Supabase → SQL Editor → New query → вставити файл → Run.
-- =====================================================================

create function public.delete_my_account()
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
    uid uuid := (select auth.uid());
begin
    if uid is null then
        raise exception 'not authenticated';
    end if;

    delete from public.workspaces w
    where exists (
            select 1 from public.workspace_members m
            where m.workspace_id = w.id and m.user_id = uid and m.role = 'owner'
        )
      and not exists (
            select 1 from public.workspace_members m
            where m.workspace_id = w.id and m.user_id <> uid and m.role = 'owner'
        );

    delete from auth.users where id = uid;
end;
$$;

revoke execute on function public.delete_my_account() from public, anon;
grant execute on function public.delete_my_account() to authenticated;
