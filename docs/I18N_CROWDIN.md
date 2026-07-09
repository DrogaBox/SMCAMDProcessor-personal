# Internationalization & Crowdin

AMD Power Gadget ships many `*.lproj` localizations. English is the **source of truth**.

---

## App-side language model

| Piece | Detail |
|-------|--------|
| Source strings | `AMD Power Gadget/en.lproj/Localizable.strings` |
| Runtime override | `AppLanguage` (`AppLanguage.swift`) |
| Preference key | `app_language_code` (empty = system default) |
| Apple API | `UserDefaults` key `AppleLanguages` set at launch |
| UI | **Themes & Appearance → Language** |
| Apply | **Apply & Restart** (full process relaunch; not live switch) |

Supported picker entries mirror bundled short codes: `en`, `es`, `de`, `it`, `fr`, `pt`, `nl`, `pl`, `ru`, `ja`, `ko`, `zh`, `cs`, `da`, `fi`, `el`, `hu`, `no`, `ro`, `sv`, `tr`, `uk`, `vi`, `ar`, `he`, `ca`, `af`, `sr`, plus **System Default**.

Xcode **knownRegions** and the `Localizable.strings` variant group must list every `*.lproj` so they are copied into the app bundle (see commit packaging all languages).

---

## Crowdin project

| Setting | Value / notes |
|---------|----------------|
| Config file | `crowdin.yml` (repo root) |
| Source file | `/AMD Power Gadget/en.lproj/Localizable.strings` |
| Translation path | `/AMD Power Gadget/%two_letters_code%.lproj/Localizable.strings` |
| Env vars | `CROWDIN_PROJECT_ID`, `CROWDIN_PERSONAL_TOKEN` |
| Local secrets | `.crowdin-credentials` (**gitignored**) |

### Language mapping (important)

Crowdin uses regional codes; the repo uses short folder names:

| Crowdin | Folder |
|---------|--------|
| `es-ES`, `es-419` | `es.lproj` |
| `zh-CN`, `zh-TW` | `zh.lproj` |
| `pt-PT`, `pt-BR` | `pt.lproj` |
| `sv-SE` | `sv.lproj` |

Without this mapping, Spanish can appear “missing” or split across dual files at partial progress.

CI: `.github/workflows/crowdin.yml` (when present) uploads/downloads against the same `crowdin.yml`.

---

## Local CLI scripts

| Script | Role |
|--------|------|
| `scripts/crowdin-env.sh` | Loads `.crowdin-credentials` into the environment |
| `scripts/crowdin-status.sh` | Translation progress |
| `scripts/crowdin-push-es.sh` | Convenience push for Spanish workflow |

Credentials file format:

```bash
CROWDIN_PROJECT_ID=<numeric>
CROWDIN_PERSONAL_TOKEN=<token>
# optional:
# CROWDIN_BASE_URL=https://api.crowdin.com
```

Never commit tokens. Prefer Crowdin personal access tokens with minimum scopes.

Typical flow:

```bash
source scripts/crowdin-env.sh
# then crowdin CLI upload sources / download translations
# (requires Crowdin CLI installed: brew install crowdin)
```

---

## Quality notes

- **EN** is edited in-repo; other languages preferably via Crowdin then download.
- Machine translation bulk is acceptable for coverage; prioritize **es**, **de**, **it** for human review.
- After downloading, rebuild the app so new strings land in the bundle.
- New UI strings: add to `en.lproj` first, then upload to Crowdin.

---

## Related

- [FEATURES.md](FEATURES.md) — language picker UX
- [INSTALLATION.md](INSTALLATION.md)
- Root `crowdin.yml`
