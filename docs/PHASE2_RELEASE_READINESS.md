# Phase 2 release readiness — 22 October 2026

**Ready for user release approval within the verification scope below. No GitHub push or Railway deployment has been performed.** No feature, Phase3, AI-customer integration, model fallback or provider was added. All application, sales-rule, authentication, schema, database configuration and dependency sources remain identical to the preserved Phase2 snapshot.

Baseline commit: `63184c6420deafc18029d09b164f9b91d20283df`, branch `phase2/page-agent`, initially clean. This review adds documentation/evidence and bounded opt-in test-harness configuration only. The final local commit is the commit introducing this report. Obtain its full SHA with `git log -1 --format=%H -- docs/PHASE2_RELEASE_READINESS.md`; the delivered release manifest/report and ZIP filename/comment contain that exact resolved SHA. A document cannot contain the hash of its own commit.

## Verification results

| Check | Measured result |
|---|---|
| Rails domain/model/HTTP | 139 tests, 1820 assertions; seed38868; 0 failures/errors/skips |
| Actual headless Edge/Turbo/official Page Agent | 27 tests, 385 assertions; seed5144; 0 failures/errors/skips; mocked provider HTTP |
| Automated total | 166 tests, 2205 assertions PASS |
| Limited real Groq + browser | 8/8 selected scenarios; 1 test, 105 assertions PASS; separate from automated total |
| Node22 locked install/build | `npm ci --ignore-scripts`, `npm run build` PASS; authentic Alibaba packages pinned1.12.4 |
| JavaScript / Ruby syntax | 12 JS and 120 Ruby files PASS |
| Autoload / production assets | `rails zeitwerk:check` and production `assets:precompile` PASS; no host DB operations |
| Static security | Brakeman8.1.0: 0 warnings/errors |
| Dependency security | npm audit: 0 vulnerabilities; bundler-audit0.9.3: no vulnerabilities, 1266 advisories, database commit `5fd86bbd406995ea4ed2df84651b209e28072031` |
| Actual production Docker/Node build | PASS on Docker29.8.1 Linux engine; final image built with Node22 asset stage and Ruby3.4.7 |
| Isolated production container | `/up`200/DB connected, `/login`200, CSP without unsafe-eval, Page Agent JS200/537726 bytes, UID1000, writable db/log/tmp |
| Existing development smoke/data | Actual login, dashboard, Leads/Opportunities/Tasks/Analytics, both customer profiles, four Phase1 AI controls and Copilot open/close/logout PASS; all 11 non-session table fingerprints unchanged |

The production container used a uniquely named, disposable PostgreSQL17 database/network with no host database access. The existing entrypoint applied three existing migrations to that empty database; users/leads remained zero, no seed. Both temporary containers and their network were removed. Runtime image had no `.local`, `.git`, `config/master.key` or node_modules. The tested image ID and check details are in [structured evidence](evidence/phase2-release-preparation-2026-10-22.json); application/build sources match this release.

Two initial container-checker attempts failed (port publishing on an internal network; case-sensitive header lookup). The corrected checker passed without a product change. Initial advisory execution needed an explicit executable bindir. Windows emitted Ruby fiddle deprecation and Brakeman Ractor/fork fallback diagnostics; command exits and reports passed. Failed attempts remain recorded and are not counted as passing tests.

## Limited real Groq acceptance

One run only, **2026-10-22T15:14:30Z–15:18:10Z**, fictional rollback fixtures in the test database, actual official Page Agent/DOM and real `openai/gpt-oss-20b`. **16 real requests/completions**, **26290 prompt +1436 completion =27726 metered tokens**, no provider errors/429, no blocked request, no CRM-table writes, no CSP violations. No more live requests were made.

| Natural request | Verified result |
|---|---|
| Tell me how I can use the system. | AI explanation, no DOM execution |
| How many users are in my team? | Actual scoped 3-member fixture, including requester; 1 manager/2 salespeople, online unknown |
| How many of them are salespeople? | Correct follow-up context and scoped role counts |
| Which leads are overdue? | Two authorized overdue fixture leads with actual links |
| Which one needs attention first? | Prior overdue subset, official NBA priority100 |
| Show my opportunities in negotiation. | Actual Opportunities page, current-user owner and Negotiation filters, one matching row |
| Open Atlas Industries. | Visible DOM controls navigate from filtered Opportunities to the correct Lead |
| Prepare a follow-up note for this customer. | Editable note prepared, note kind selected, follow-up empty, no submit or persistence |

Wall time **220.083s**, including **191.059s explicit quota pacing**. This is not a speed comparison. The harness's optional `LEADCURRENT_LIVE_RELEASE_SMOKE=1` selects these eight cases, caps real transport attempts at16, stops after40000 successfully metered tokens or a provider failure, and preserves production limits. The final in-flight response may cross the token threshold. Default full acceptance is unchanged. Paid cost, human hours, rejected/unmetered account activity and future quota availability are not measured.

The **21 October TPD block remains historical evidence**, not an active error in this selected run. Full13 acceptance was deliberately not repeated. Lead-count/tasks were not rerun live today, and the three extra team paraphrases remain unverified live; those read tools have automated coverage. Eight selected passes must not be advertised as a full13-scenario pass or a deployed release.

Optional bounded reproduction, only when quota is available; do not rerun routinely:

```powershell
Set-Location D:\LeadCurrent
$env:GROQ_API_KEY = [Environment]::GetEnvironmentVariable('GROQ_API_KEY','User')
$env:LEADCURRENT_LIVE_AGENT = '1'
$env:LEADCURRENT_LIVE_SCENARIOS = $null
$env:LEADCURRENT_LIVE_RELEASE_SMOKE = '1'
bundle exec ruby script/verify_copilot_finalization.rb
```

Normal tests require none of those live variables or a real key. Test mode refuses CI/production and rolls fixtures back. Do not seed/reset the existing database for acceptance.

## Security, preservation and limitations

Automated model/HTTP/browser cases verify workspace scoping, cross-login/session replay refusal, mandatory password/CSRF, closed query arguments, unsafe output refusal, bounded reads and no agent CRM submissions. Real DOM execution checks actual filters/destination independently of model done. Note contents are browser observation, not server proof of persistence. Agent cannot contact customers, save activity, change stages/ownership, finish tasks, delete, change credentials or send email. Human Save action remains separate. Existing 24h contact, 4h warning and 72h inactivity rules and Phase1 transport are unchanged.

Fresh development counts: 2 users,7 leads,4 opportunities,7 companies,7 contacts,4 activities,36 audit events,0 tasks,1 organization,3 schema migrations. All 11 non-session tables were hashed before and after; session-only login/logout is expected. Local master key was fingerprinted and stayed unchanged. No host reset/drop/seed/migration occurred; the old project was untouched.

Remaining limitations: model intent/paraphrase errors and provider availability/quota/latency are possible; no online-team measurement. Lists expose at most10 linked records, narrower NBA searches at most8 candidates per record type; not exhaustive global ranking. Process-local rate limits and conversation cache require **one serving process/replica**; multiworker scaling requires central coordination, outside this release. User text/visible titles may contain sensitive information despite masking. No new fallback/provider was introduced; default remains `openai/gpt-oss-20b`. No production Railway settings, remote CI run, deployment ID/SHA, backup or postdeploy business flow was verified today.

Final review passed the package policy on **272 source files**, including exact local credential matching and forbidden-path checks. Gitleaks found exactly **two unchanged, reviewed false positives** in the redacted source-only scan (raw exit1): public commit SHA at docs/VERIFICATION_TR.md:39 and synthetic password fixture at test/integration/authentication_test.rb:46; zero confirmed credentials and no blanket suppression. Documentation checks passed 29 Markdown files,282 links,41 tables,19 required README sections and16 ignore checks. All267 other previously tracked files,164 protected runtime/config/build files,10 historical evidence files and the historical CHALLENGE_LOG prefix are preserved. The final delivered manifest records the actual SHA, ZIP hash/file count and clean status. `.local`, secret env files, master key, logs, database files, generated assets, node_modules and Git metadata are excluded from the review archive.

## Exact deployment steps — only after explicit approval

1. Review this report, dated evidence and the delivered source-only ZIP. Confirm the final commit SHA from the delivery manifest. Do not deploy a dirty workspace or a different commit. Obtain/verify a current Railway PostgreSQL backup and record the currently deployed SHA/release for rollback. This work has not created or verified that backup.
2. Before publishing main, inspect the existing Railway **web service**: source `Montaserissa20/leadcurrent`, branch `main`, root repository directory, Dockerfile build. Keep automatic deployment disabled until the reviewed commit's **LeadCurrent CI** succeeds, or verify **Wait for CI** is enabled. Railway settings were not changed here. [Official branch/CI trigger documentation](https://docs.railway.com/deployments/github-autodeploys).
3. Preserve existing production `DATABASE_URL` and `SECRET_KEY_BASE`; verify server-only `GROQ_API_KEY` is configured and `GROQ_MODEL=openai/gpt-oss-20b`. Do not use the local master key/development DB/demo credentials. Use one replica and one serving process (`WEB_CONCURRENCY=0` for single-mode Puma); keep existing Rails thread/pool sizing. Ensure no `LEADCURRENT_LIVE_*`/test variables are configured.
4. Leave the Dockerfile's default ENTRYPOINT/CMD in effect (clear any incompatible custom start command after inspecting it). The entrypoint runs `./bin/rails db:prepare` then `./bin/rails server`; do not add a seed/reset command. Existing Puma reads Railway's `PORT`. Phase2 adds no migrations relative to Phase1. A custom Docker start command can override ENTRYPOINT, so verify the existing service actually uses the tested startup path. [Official start-command behavior](https://docs.railway.com/deployments/start-command).
5. After approval, publish the pinned local release with the following PowerShell commands. Stop if the worktree is dirty, main diverges, or the delivered SHA differs; review changes instead of forcing/resetting. These commands were **not executed**:

```powershell
Set-Location D:\LeadCurrent
git status --short
$release = git log -1 --format=%H -- docs/PHASE2_RELEASE_READINESS.md
git show --no-patch --format=fuller $release
git fetch origin
git switch main
git pull --ff-only origin main
git merge --ff-only $release
git rev-parse HEAD
git push origin main
```

6. Confirm `origin/main` and **LeadCurrent CI** are for the exact approved SHA, not an older or Dependabot run. Wait for domain, browser, security and production-asset jobs to pass. If automatic deployment is disabled, choose **Deploy Latest Commit** only after confirming the service's connected branch and latest SHA. If Wait for CI was verified, watch its waiting/build/deploy states. Do not use Redeploy blindly: it may rerun the previously deployed source. [Official deploy actions](https://docs.railway.com/integrations/api/manage-services).
7. Verify build logs show Node22 `npm ci`/bundle build, Ruby assets and final mkdir/chown. Configure the service healthcheck path `/up`; Rails must listen on `PORT`. Wait for the deployment health result and record its deployment ID and SHA. [Official healthcheck behavior](https://docs.railway.com/deployments/healthchecks).
8. At the actual production URL, verify `/up` HTTP200/database connected and login. In an authorized fictional QA workspace verify Phase1 customer advice and core sales workflow, tenant denial, team count against Settings, overdue facts, follow-up context, opportunity filters, visible record navigation and an **unsaved** note. Verify no activity/task/stage was changed by Copilot; avoid repetitive free-tier calls. Record actual pass/failure/429 and rollback on a material regression. Do not infer success from a green build alone.
9. If needed, restore the previously recorded successful deployment using Railway's deployment rollback action and recheck `/up`/login/business flow. Do not reset the database. This release has no new migration, but inspect schema compatibility before any rollback; a code rollback is not a database restore. Keep a verified backup for a separate, deliberate recovery if required.

The public URL in older documentation is historical Phase1 evidence. Deployment success will only be reported after the approved SHA and actual public behavior are verified. [Turkish presentation guide](FINAL_PRESENTATION_TR.md), [architecture and historical finalization](COPILOT_PHASE2_FINAL_TR.md), [complete challenge history](../CHALLENGE_LOG.md).
