-- GMA backend hardening patch
-- Apply only AFTER the initial schema in supabase-schema.sql.
-- This patch is already applied to the live project dgyvsuofnbshzilrwjrs.
-- It is retained here for reproducibility; review against the live database before reuse.

create schema if not exists private;
revoke all on schema private from public, anon, authenticated;
grant usage on schema private to authenticated;

do $$
begin
  if to_regprocedure('public.gma_is_admin()') is not null then
    alter function public.gma_is_admin() set schema private;
  end if;
  if to_regprocedure('public.gma_new_profile()') is not null then
    alter function public.gma_new_profile() set schema private;
  end if;
end $$;

revoke all on function private.gma_is_admin() from public, anon, authenticated;
grant execute on function private.gma_is_admin() to authenticated;
revoke all on function private.gma_new_profile() from public, anon, authenticated;

-- Least-privilege Data API grants: no anonymous table access and no delete/truncate.
revoke all on all tables in schema public from public, anon, authenticated;
grant select, update on public.profiles to authenticated;
grant select, insert, update on public.payments to authenticated;
grant select, insert, update on public.campaigns to authenticated;
grant select, insert on public.campaign_assignments to authenticated;
grant select, insert, update on public.submissions to authenticated;
grant select, update on public.referrals to authenticated;
grant select, insert, update on public.withdrawals to authenticated;
revoke update on public.campaign_assignments from authenticated;
grant update(downloaded_at) on public.campaign_assignments to authenticated;
alter default privileges in schema public revoke all on tables from anon, authenticated;
alter default privileges in schema public revoke all on tables from public;

-- Index foreign-key and frequent user lookups.
create index if not exists idx_profiles_referred_by on public.profiles(referred_by);
create index if not exists idx_payments_user_id on public.payments(user_id);
create index if not exists idx_payments_verified_by on public.payments(verified_by);
create index if not exists idx_campaigns_created_by on public.campaigns(created_by);
create index if not exists idx_campaign_assignments_user_id on public.campaign_assignments(user_id);
create index if not exists idx_submissions_campaign_id on public.submissions(campaign_id);
create index if not exists idx_submissions_user_id on public.submissions(user_id);
create index if not exists idx_submissions_reviewed_by on public.submissions(reviewed_by);
create index if not exists idx_referrals_referrer_id on public.referrals(referrer_id);
create index if not exists idx_withdrawals_user_id on public.withdrawals(user_id);
create index if not exists idx_withdrawals_processed_by on public.withdrawals(processed_by);
create unique index if not exists idx_payments_unique_reference
  on public.payments(lower(payment_reference))
  where payment_reference is not null and length(trim(payment_reference)) > 0;

-- Rebuild policies using the private admin helper and active-account checks.
drop policy if exists "profile read self or admin" on public.profiles;
drop policy if exists "admin update profiles" on public.profiles;
drop policy if exists "payments read own or admin" on public.payments;
drop policy if exists "payments submit own" on public.payments;
drop policy if exists "payments admin update" on public.payments;
drop policy if exists "campaigns authenticated read" on public.campaigns;
drop policy if exists "campaigns active advertiser or admin read" on public.campaigns;
drop policy if exists "campaigns admin insert" on public.campaigns;
drop policy if exists "campaigns admin update" on public.campaigns;
drop policy if exists "assignments own or admin read" on public.campaign_assignments;
drop policy if exists "assignments own insert" on public.campaign_assignments;
drop policy if exists "assignments own update" on public.campaign_assignments;
drop policy if exists "submissions own or admin read" on public.submissions;
drop policy if exists "submissions own insert" on public.submissions;
drop policy if exists "submissions admin update" on public.submissions;
drop policy if exists "referrals read related or admin" on public.referrals;
drop policy if exists "referral self create not allowed" on public.referrals;
drop policy if exists "referrals admin update" on public.referrals;
drop policy if exists "withdrawals own or admin read" on public.withdrawals;
drop policy if exists "withdrawals own request" on public.withdrawals;
drop policy if exists "withdrawals admin update" on public.withdrawals;
drop policy if exists "admin manage campaign media" on storage.objects;
drop policy if exists "authenticated read campaign media" on storage.objects;
drop policy if exists "active advertisers read active campaign media" on storage.objects;
drop policy if exists "advertiser upload own proof" on storage.objects;
drop policy if exists "advertiser read own proof or admin" on storage.objects;

create policy "profile read self or admin" on public.profiles
for select to authenticated
using (id = (select auth.uid()) or private.gma_is_admin());
create policy "admin update profiles" on public.profiles
for update to authenticated
using (private.gma_is_admin()) with check (private.gma_is_admin());

create policy "payments read own or admin" on public.payments
for select to authenticated
using (user_id = (select auth.uid()) or private.gma_is_admin());
create policy "payments submit own" on public.payments
for insert to authenticated
with check (
  user_id = (select auth.uid()) and status = 'pending' and amount = 200
  and method = 'KCB Paybill' and paybill = '522522'
  and account_number = '1343698359' and verified_by is null and verified_at is null
);
create policy "payments admin update" on public.payments
for update to authenticated
using (private.gma_is_admin()) with check (private.gma_is_admin());

create policy "campaigns active advertiser or admin read" on public.campaigns
for select to authenticated
using (
  private.gma_is_admin()
  or (
    active = true and starts_at <= now() and expires_at > now()
    and exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.status = 'active')
  )
);
create policy "campaigns admin insert" on public.campaigns
for insert to authenticated
with check (private.gma_is_admin() and created_by = (select auth.uid()));
create policy "campaigns admin update" on public.campaigns
for update to authenticated
using (private.gma_is_admin()) with check (private.gma_is_admin());

create policy "assignments own or admin read" on public.campaign_assignments
for select to authenticated
using (user_id = (select auth.uid()) or private.gma_is_admin());
create policy "assignments own insert" on public.campaign_assignments
for insert to authenticated
with check (
  user_id = (select auth.uid())
  and exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.status = 'active')
  and exists (
    select 1 from public.campaigns c where c.id = campaign_id
      and c.active = true and c.starts_at <= now() and c.expires_at > now()
  )
);
create policy "assignments own update" on public.campaign_assignments
for update to authenticated
using (user_id = (select auth.uid()) or private.gma_is_admin())
with check (user_id = (select auth.uid()) or private.gma_is_admin());

create policy "submissions own or admin read" on public.submissions
for select to authenticated
using (user_id = (select auth.uid()) or private.gma_is_admin());
create policy "submissions own insert" on public.submissions
for insert to authenticated
with check (
  user_id = (select auth.uid()) and status = 'pending' and approved_views = 0
  and reviewed_by is null and reviewed_at is null
  and (storage.foldername(screenshot_path))[1] = (select auth.uid())::text
  and exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.status = 'active')
  and exists (
    select 1 from public.campaigns c where c.id = submissions.campaign_id
      and c.active = true and c.starts_at <= now() and c.expires_at > now()
  )
  and exists (
    select 1 from public.campaign_assignments a
    where a.campaign_id = submissions.campaign_id and a.user_id = (select auth.uid())
  )
);
create policy "submissions admin update" on public.submissions
for update to authenticated
using (private.gma_is_admin()) with check (private.gma_is_admin());

create policy "referrals read related or admin" on public.referrals
for select to authenticated
using (
  referrer_id = (select auth.uid()) or referred_user_id = (select auth.uid()) or private.gma_is_admin()
);
create policy "referrals admin update" on public.referrals
for update to authenticated
using (private.gma_is_admin()) with check (private.gma_is_admin());

create policy "withdrawals own or admin read" on public.withdrawals
for select to authenticated
using (user_id = (select auth.uid()) or private.gma_is_admin());
create policy "withdrawals own request" on public.withdrawals
for insert to authenticated
with check (
  user_id = (select auth.uid()) and status = 'pending'
  and processed_by is null and processed_at is null
  and exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.status = 'active')
);
create policy "withdrawals admin update" on public.withdrawals
for update to authenticated
using (private.gma_is_admin()) with check (private.gma_is_admin());

create policy "advertiser upload own proof" on storage.objects
for insert to authenticated
with check (
  bucket_id = 'proof-screenshots'
  and (storage.foldername(name))[1] = (select auth.uid())::text
  and exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.status = 'active')
);
create policy "advertiser read own proof or admin" on storage.objects
for select to authenticated
using (
  bucket_id = 'proof-screenshots'
  and ((storage.foldername(name))[1] = (select auth.uid())::text or private.gma_is_admin())
);
create policy "admin manage campaign media" on storage.objects
for all to authenticated
using (bucket_id = 'campaign-media' and private.gma_is_admin())
with check (bucket_id = 'campaign-media' and private.gma_is_admin());
create policy "active advertisers read active campaign media" on storage.objects
for select to authenticated
using (
  bucket_id = 'campaign-media'
  and (
    private.gma_is_admin()
    or (
      exists (select 1 from public.profiles p where p.id = (select auth.uid()) and p.status = 'active')
      and exists (
        select 1 from public.campaigns c where c.media_path = storage.objects.name
          and c.active = true and c.starts_at <= now() and c.expires_at > now()
      )
    )
  )
);

-- Server-side submission validation: never trust a rate or approval status sent by the browser.
create or replace function private.gma_validate_submission()
returns trigger language plpgsql security definer set search_path = ''
as $$
declare campaign_rate numeric(12,2);
begin
  if new.user_id is distinct from auth.uid() and not private.gma_is_admin() then
    raise exception 'You may only submit work for your own account.';
  end if;
  if (storage.foldername(new.screenshot_path))[1] is distinct from new.user_id::text then
    raise exception 'Screenshot path must belong to the submitting account.';
  end if;
  select c.rate_per_view into campaign_rate
  from public.campaigns c
  where c.id = new.campaign_id and c.active = true
    and c.starts_at <= now() and c.expires_at > now();
  if campaign_rate is null then raise exception 'This campaign is not currently accepting submissions.'; end if;
  if not exists (select 1 from public.profiles p where p.id = new.user_id and p.status = 'active') then
    raise exception 'Your account must be active before submitting campaign proof.';
  end if;
  if not exists (
    select 1 from public.campaign_assignments a
    where a.campaign_id = new.campaign_id and a.user_id = new.user_id
  ) then raise exception 'Open the campaign media before submitting proof.'; end if;
  new.rate_per_view := campaign_rate;
  new.approved_views := 0;
  new.status := 'pending';
  new.reviewer_note := null;
  new.reviewed_by := null;
  new.reviewed_at := null;
  return new;
end;
$$;
revoke all on function private.gma_validate_submission() from public, anon, authenticated;
drop trigger if exists gma_validate_submission_before_insert on public.submissions;
create trigger gma_validate_submission_before_insert
before insert on public.submissions
for each row execute function private.gma_validate_submission();

-- Reserve pending and approved withdrawals and reject requests above approved earnings.
create or replace function private.gma_validate_withdrawal()
returns trigger language plpgsql security definer set search_path = ''
as $$
declare available_balance numeric(14,2);
begin
  if new.user_id is distinct from auth.uid() then
    raise exception 'You may only request a withdrawal from your own account.';
  end if;
  if new.status <> 'pending' or new.processed_by is not null or new.processed_at is not null then
    raise exception 'New withdrawal requests must start as pending.';
  end if;
  perform pg_advisory_xact_lock(hashtextextended(new.user_id::text, 0));
  if not exists (select 1 from public.profiles p where p.id = new.user_id and p.status = 'active') then
    raise exception 'Your account must be active to request a withdrawal.';
  end if;
  select
    coalesce((select sum(s.approved_views * s.rate_per_view) from public.submissions s
      where s.user_id = new.user_id and s.status = 'approved'), 0)
    + coalesce((select sum(r.bonus) from public.referrals r
      where r.referrer_id = new.user_id and r.eligible = true and r.paid = false), 0)
    - coalesce((select sum(w.amount) from public.withdrawals w
      where w.user_id = new.user_id and w.status in ('pending','approved','paid')), 0)
  into available_balance;
  if new.amount <= 0 or new.amount > greatest(available_balance, 0) then
    raise exception 'Requested amount exceeds your currently available approved balance.';
  end if;
  return new;
end;
$$;
revoke all on function private.gma_validate_withdrawal() from public, anon, authenticated;
drop trigger if exists gma_validate_withdrawal_before_insert on public.withdrawals;
create trigger gma_validate_withdrawal_before_insert
before insert on public.withdrawals
for each row execute function private.gma_validate_withdrawal();
