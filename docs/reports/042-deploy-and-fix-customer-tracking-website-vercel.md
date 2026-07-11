# Prompt 042 — Deploy and Fix Customer Tracking Website on Vercel

## Summary

Prepared and fixed the public customer tracking website for correct Vercel deployment as a Next.js app under `web/`.

The local Next production build now serves:

- `/` as the visible home page
- `/track/[token]` as an app-handled dynamic route that renders the safe tracking UI instead of a platform/static-file 404

No Flutter Desktop behavior, local SQLite schema, Supabase backend APIs, Edge Functions, or QR generation logic was changed.

## Production Issue Observed

Reported production behavior:

- `https://nova-repair.vercel.app/` opened a blank page
- `https://nova-repair.vercel.app/track/<trackingToken>` returned Vercel `404 NOT_FOUND`
- production logs were empty or not useful

## Root Cause

Local inspection showed the Next.js app itself was valid:

- `web/package.json` exists
- `web/app/page.tsx` exists and renders visible text
- `web/app/track/[token]/page.tsx` exists and exports a valid page
- `web/next.config.ts` does not use `output: "export"`
- local `next build` reports `/track/[token]` as a dynamic server route

The deployment symptoms matched Vercel serving the old Flutter web shell/static files instead of the Next.js app:

- `web/index.html` was still the Flutter bootstrap page
- that page loads `flutter_bootstrap.js`, which is not produced by this Next.js app
- serving that stale static file explains the blank `/`
- serving static files instead of Next routing explains the platform `404` for `/track/<token>`

The likely production configuration issue is that Vercel was not using `web` as a Next.js project root with the default Next output.

## Fix Applied

Removed stale Flutter web shell files from the `web/` Next app root:

- `web/index.html`
- `web/manifest.json`
- `web/icons/Icon-192.png`
- `web/icons/Icon-512.png`
- `web/icons/Icon-maskable-192.png`
- `web/icons/Icon-maskable-512.png`

Added:

- `web/vercel.json`
- `npm run start` script in `web/package.json`

`web/vercel.json` keeps the intended Vercel commands explicit for the `web` project root:

```json
{
  "buildCommand": "npm run build",
  "installCommand": "npm install"
}
```

No `output: "export"` setting was added. The output directory must remain Vercel default/empty.

## Validation Run

Commands run:

- `npm run lint`
- `npm run build`
- `npm run start`
- `curl -i http://localhost:3000/`
- `curl -i http://localhost:3000/track/local-route-check-token`
- `git status --short`
- `git remote -v`
- `git branch --show-current`
- `git add ...`
- `git commit -m "Fix Vercel tracking website deployment"`
- `git push origin main`
- `vercel --version`
- `curl -i https://nova-repair.vercel.app/`
- `curl -i https://nova-repair.vercel.app/track/local-route-check-token`

No Flutter tests, Flutter build, Supabase deployment commands, or Edge Function changes were run.

## Validation Results

`npm run lint` passed.

`npm run build` passed. Build output confirmed:

- `/` is static
- `/track/[token]` is dynamic/server-rendered on demand

`npm run start` initially failed in the sandbox with:

```text
listen EPERM: operation not permitted 0.0.0.0:3000
```

After running with approved escalation, the local production server started on:

```text
http://localhost:3000
```

Local route checks:

- `GET /` returned `200 OK` and visible Next-rendered home page HTML.
- `GET /track/local-route-check-token` returned `200 OK` and the app's safe `Repair not found` UI, not a platform/static 404.

`vercel --version` failed because the Vercel CLI is not installed in this environment.

Git commit and push succeeded for the latest `main` commit:

```text
Fix Vercel tracking website deployment
```

Pushed:

```text
main -> origin/main
```

Production URL checks after push:

- `https://nova-repair.vercel.app/` returned Vercel platform `404 NOT_FOUND`
- `https://nova-repair.vercel.app/track/local-route-check-token` returned Vercel platform `404 NOT_FOUND`

Before this prompt, `/` served the stale Flutter bootstrap `index.html`. After removing that stale static file and pushing, production changed to platform 404. This confirms Vercel is still not running the Next.js app from `web/` as a Next.js project. The remaining required fix is in Vercel project settings: root directory must be `web`, framework preset must be `Next.js`, and output directory must be empty/default.

## Vercel Project Settings

Expected Vercel settings:

- Project root: `web`
- Framework preset: `Next.js`
- Install command: `npm install`
- Build command: `npm run build`
- Output directory: leave empty / Vercel default

Do not set output directory to a literal value such as `default`.

Do not use static export for this app. `/track/[token]` must be handled by Next/Vercel server rendering.

## Vercel Environment Variables

Set these in the Vercel project:

```text
NOVA_PUBLIC_TRACKING_FUNCTION_URL=https://nkskvskdoetridrujtjv.supabase.co/functions/v1/get-public-repair-tracking
NEXT_PUBLIC_APP_NAME=Nova Repair
```

Do not add:

- Supabase service role key
- Supabase secret key
- Installation Secret
- database password
- Flutter secure credential

## Deployment Steps

1. Push the latest `main` branch to GitHub.
2. Open the Vercel project for `nova-repair.vercel.app`.
3. Confirm project root directory is `web`.
4. Confirm framework preset is `Next.js`.
5. Confirm output directory is empty/default.
6. Confirm environment variables are set.
7. Redeploy the latest commit.
8. Test:
   - `https://nova-repair.vercel.app/`
   - `https://nova-repair.vercel.app/track/<known trackingToken>`

The Vercel CLI was not available locally, so direct CLI deployment was not performed from this environment.

The latest commit has been pushed to GitHub. Vercel still needs its project settings corrected and then redeployed.

## Production Flutter QR Configuration

Flutter must be run or built with:

```text
--dart-define=NOVA_TRACKING_WEB_BASE_URL=https://nova-repair.vercel.app
```

Development run example:

```text
flutter run -d linux --dart-define=NOVA_TRACKING_WEB_BASE_URL=https://nova-repair.vercel.app
```

Production build note:

```text
flutter build windows --dart-define=NOVA_TRACKING_WEB_BASE_URL=https://nova-repair.vercel.app
```

The production build command above was not run in this prompt.

## End-to-End Manual Test Plan

1. Ensure Desktop Online Tracking is connected.
2. Create or update a repair.
3. Wait for the desktop publisher to update Supabase.
4. Confirm the row exists in `public_repair_tracking`.
5. Open:

   ```text
   https://nova-repair.vercel.app/track/<trackingToken>
   ```

6. Confirm the page displays:
   - shop name
   - repair code
   - device name
   - current status
   - received date
   - last updated date
7. Run Flutter with the production base URL.
8. Open Customer Ticket preview.
9. Scan Customer Ticket QR.
10. Confirm QR opens the tracking page.
11. Confirm Device Label QR remains repair-code-only.

## Security Checklist

- Vercel receives only the public lookup function URL and public app name.
- Website calls only the public Edge Function.
- Website does not query Supabase tables directly.
- Website does not display the tracking token.
- Website does not display customer name, customer phone, reported problem, internal notes, device access information, or price.
- QR uses the opaque token URL.
- Installation Secret remains only in Desktop secure storage.

## Limitations

- Vercel CLI is not installed, so direct CLI deployment was not performed locally.
- Latest commit was pushed to GitHub, but production still returned Vercel platform 404 after push.
- Vercel project settings still need to be corrected in the Vercel dashboard.
- Public production URL verification cannot pass until Vercel runs the `web/` directory as a Next.js app.
- No Flutter tests or Windows build were run, per prompt instruction.
- No Supabase backend or Edge Function deployment commands were run.

## Next Step

Prompt 043 — Production Build and Installer Configuration
