-- Повернення коштів після завершення запису (← Appointment.refundAmount, refundReason, refundedAt).
-- Запускати в SQL Editor після попередніх міграцій. Потрібно для синхронізації (S5), до того — не обов'язково.

alter table public.appointments
    add column if not exists refund_amount numeric(12, 2) check (refund_amount is null or refund_amount >= 0),
    add column if not exists refund_reason text,
    add column if not exists refunded_at   timestamptz;
