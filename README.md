# Global Marketing Agency

A gold-and-black digital campaign platform for Kenya. GitHub Pages hosts the frontend; Supabase provides authentication, database access and private file storage.

## Live project
- Website: https://dayvie-tech.github.io/GLOBAL-MARKETS-254/
- Repository: https://github.com/Dayvie-tech/GLOBAL-MARKETS-254
- Supabase project: **GLOBAL MARKETING AGENCY**
- Supabase reference: `dgyvsuofnbshzilrwjrs`
- Supabase organisation: **DAYVIE MERCHANTS COMPANY**

## Backend status (verified 8 November 2026)
- Supabase project status: **ACTIVE_HEALTHY**
- Frontend config points to the correct project URL and public publishable key.
- Seven public tables exist: profiles, payments, campaigns, campaign_assignments, submissions, referrals and withdrawals.
- Row Level Security is enabled on all seven tables.
- Proof screenshots and campaign media use separate private Storage buckets.
- Anonymous table access has been revoked; authenticated table privileges are limited to required operations.
- Admin helper and signup trigger functions are in a non-exposed `private` schema.
- Submission validation checks account status, campaign window, campaign assignment and campaign rate server-side.
- Withdrawal requests are checked against approved submission earnings and eligible referral bonuses, with pending/approved/paid withdrawals reserved against the available balance.
- Supabase security and health advisors returned no findings after the hardening work. Performance advisor reports only unused-index notices on this newly restored, empty project; indexes were retained to support foreign-key lookups.

## Current account state
The project currently has **zero Auth users**. The first intended owner account must register through the website. The project owner must then promote that exact account to admin from the Supabase SQL Editor. Do not let users self-assign admin privileges.

Example owner-only bootstrap command (replace the email with the exact email used for the first account):
```sql
update public.profiles
set role = 'admin', status = 'active'
where lower(email) = lower('YOUR_ADMIN_EMAIL');
```

Run this only as the trusted project owner after confirming the account exists. Future admin assignment should remain restricted to authorised administrators.

## Current platform workflow
- Email/password registration, login and password reset
- KSh 200 registration payment reference submission and manual admin review
- Admin account approval and suspension
- Campaign creation with campaign-specific start and expiry times (the interface currently offers a 20-hour example)
- Private campaign media and campaign assignment records
- Screenshot proof submission and manual review
- Referral code and KSh 25 referral workflow
- Withdrawal requests, balance validation and admin review

Campaign availability, rates, eligibility and any compensation must be clearly stated in each campaign. No income, views or approval are guaranteed.

## Security notes
- Never put a Supabase service-role or secret key in browser code. `config.js` contains only the public publishable key.
- Keep proof screenshots private; advertisers can read their own proof and administrators can review submissions.
- Only active advertisers can access current campaigns and campaign media.
- Submission rate is assigned from the campaign record, not trusted from the browser.
- Withdrawal requests cannot exceed the available approved balance as calculated by the database guard.
- Before real launch, test using separate advertiser and admin accounts, verify the payment destination, and publish privacy, terms, refund/dispute and campaign policies.

## Schema and backend maintenance
- `supabase-schema.sql` is the initial schema reference. Do not blindly rerun it against an existing database.
- `gma-backend-hardening.sql` documents the security hardening already applied to the live backend. Review it against the target database before reusing it elsewhere.
- Review RLS, Storage policies, Auth redirect settings and advisor findings after future schema changes.

## GitHub Pages
The repository uses the `main` branch and root directory. In GitHub Settings → Pages, select **Deploy from a branch → main → /(root)**.

## Files
- `index.html` — public website structure
- `styles.css` — responsive gold/black styling
- `app.js` — authentication, advertiser workspace and admin controls
- `config.js` — confirmed Supabase URL and public publishable key
- `config.js.example` — safe configuration template
- `supabase-schema.sql` — initial schema reference
- `gma-backend-hardening.sql` — backend permissions, RLS, triggers and validation hardening
