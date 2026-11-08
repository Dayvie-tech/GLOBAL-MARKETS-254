# Global Marketing Agency

A responsive gold-and-black marketing campaign website for Kenya. GitHub Pages hosts the frontend; Supabase provides authentication, database and private file storage.

## Live website and source
- Website: https://dayvie-tech.github.io/GLOBAL-MARKETS-254/
- Repository: https://github.com/Dayvie-tech/GLOBAL-MARKETS-254
- Supabase project: **GLOBAL MARKETING AGENCY**
- Supabase project reference: `dgyvsuofnbshzilrwjrs`
- Supabase organisation currently connected: **DAYVIE MERCHANTS COMPANY**

## Website sections
- Home / hero and primary calls to action
- About GMA
- How it works
- Campaign access overview
- Transparency, authenticity and privacy principles
- Frequently asked questions
- Registration details
- Account registration and login
- Advertiser dashboard and administrator control centre

## Existing platform workflow
- Email/password registration, login and password reset
- KSh 200 registration payment reference submission and manual admin review
- Admin account approval and suspension
- Campaign creation and 20-hour example campaign window
- Campaign media download and assignment record
- Screenshot proof submission and manual review
- Referral code display and KSh 25 referral workflow
- Withdrawal requests and admin review

The public website explains the process. Campaign availability, rates, eligibility and any compensation must be clearly stated in each actual campaign. No income, views or approval are guaranteed.

## Confirmed project connection — IMPORTANT
The correct Supabase project is `dgyvsuofnbshzilrwjrs`. The previous GitHub configuration pointed to a different project and has been corrected to the confirmed project URL.

**The Supabase project is currently INACTIVE/PAUSED.** The connected Supabase account refused to restore it because the organisation has reached its maximum of two active free projects. Do not create a replacement project or delete/pause another project without the owner's decision.

To resume backend work:
1. In Supabase, decide which existing project can be paused or whether to upgrade the organisation so this GMA project can be restored.
2. Restore **GLOBAL MARKETING AGENCY** (reference `dgyvsuofnbshzilrwjrs`).
3. Obtain its public anon/publishable key from Project Settings → API.
4. Add that key to `config.js` as `supabaseAnonKey`. Keep service_role/secret keys out of browser code.
5. Confirm the existing database tables, migrations, Storage buckets and Auth settings before applying any schema changes.

Until the project is restored and its correct public key is supplied, authentication and dashboards intentionally remain disconnected. The public website sections can still be viewed.

## Existing schema file
`supabase-schema.sql` is a starter schema only. It must be compared against the live database before applying it. Do not blindly re-run it on an existing database. Review and test RLS policies, storage policies, role assignment, referral eligibility and earnings/withdrawal logic before launch.

## GitHub Pages
The repository uses the `main` branch and root directory. In GitHub Settings → Pages, use Deploy from a branch → `main` → `/(root)`.

## Before accepting real users or payments
- Verify paybill/account ownership and payment process independently.
- Publish terms, privacy notice, campaign conditions, withdrawal eligibility and dispute/refund policies.
- Use separate advertiser and admin accounts to test all access rules.
- Ensure advertisers cannot edit their own role, approval status, approved views or earnings.
- Keep evidence private and restrict admin access.
- Use a server-side ledger and validation for any approved earnings; screenshots alone do not prove genuine reach.
- Complete a security review before real launch.

## Files
- `index.html` — semantic website structure and public sections
- `styles.css` — responsive gold/black design
- `app.js` — authentication, advertiser portal and admin UI
- `config.js` — confirmed Supabase URL and public key placeholder
- `config.js.example` — safe configuration template
- `supabase-schema.sql` — starter database schema and policies
