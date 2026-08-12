# KnowBase complete bilingual localization design

## Goal

Make the Chinese and English language modes complete and predictable across the customer-facing KnowBase desktop experience. Switching to Chinese must not leave ordinary interface copy in English, and switching to English must not leave ordinary interface copy in Chinese.

## Scope

- Localize the home dashboard, sidebar, authentication, API Key dialog, knowledge-base workspace, document management, chat, citations, Analysis workbench, empty states, loading states, errors, dialogs, tooltips, and accessibility labels.
- Preserve the existing Chinese and English switch and the stored language preference.
- Localize dynamic labels such as relative times, counts, file status, result summaries, and interpolated names.
- Add automated checks for dictionary parity, missing translation keys, and known user-visible hardcoded copy.
- Verify both languages with production builds and desktop/mobile viewport screenshots.

## Non-goals

- Visual redesign or navigation changes.
- Translating product and technical names such as KnowBase, API Key, CSV, SQL, DuckDB, model names, or provider names.
- Translating arbitrary text returned by uploaded documents, SQL result data, an LLM, or a backend diagnostic response.
- Adding a third language or a localization framework dependency.

## Translation architecture

Keep the existing lightweight Zustand language store and local TypeScript dictionary. Split the dictionary into a canonical Chinese object and an English object constrained to the same key type. `TranslationKey` is derived from the canonical dictionary, so a missing or extra English key fails TypeScript compilation.

The translation function accepts a typed key and optional interpolation values. Templates use named placeholders such as `{count}` and `{name}`. Unknown placeholders remain visible during development rather than being silently deleted.

Runtime fallback remains defensive for corrupted persisted state, but normal code cannot request an unknown key. Chinese mode no longer uses the English dictionary as a missing-key fallback because compile-time parity and repository checks make missing keys a build failure.

## Component migration

All user-visible copy in the scoped frontend files must come from `useI18nStore`. Components should read both `lang` and `t` when locale-sensitive date or number formatting is required. Low-level API code may continue returning backend diagnostics; components provide localized action labels, generic fallbacks, and surrounding messages.

Relative time and date helpers accept the active language explicitly. They use localized templates and locale-aware formatting instead of hardcoded English abbreviations or a fixed `zh-CN` locale.

The migration keeps technical tokens unchanged where translation would reduce clarity. Examples include CSV column types, SQL keywords, DuckDB, API Key, file extensions, and provider identifiers.

## Coverage enforcement

Add a repository check that:

- extracts Chinese and English dictionary keys and requires exact parity;
- extracts literal `t("...")` calls and requires every key to exist;
- rejects duplicate dictionary keys;
- scans customer-facing app and component files for a curated set of known hardcoded Chinese and English interface copy;
- allows technical strings, route names, CSS classes, test data, and backend-provided content through a narrow allowlist.

The existing frontend text check remains responsible for encoding regressions and offline font safety. The localization check is added to release preflight and CI so future changes cannot silently reintroduce partial translation.

## Error handling

User-authored validation, empty-state, loading, and action errors are localized. Backend error details remain available because they can contain actionable provider or model diagnostics. When no useful detail is returned, the UI uses a localized generic failure message.

## Verification

- Run the localization coverage check in its failing state before migration.
- Run the localization and existing frontend text checks after migration.
- Run `npm run build` in `frontend`.
- Exercise Chinese and English at desktop and mobile viewport sizes, including the dashboard, a knowledge-base workspace, and Analysis.
- Run release preflight to verify the new check is part of the publish path.

## Success criteria

- The approved screens contain no untranslated ordinary interface copy in either language.
- Chinese and English dictionaries have identical keys.
- Every literal translation call references an existing key.
- Dynamic dates, counts, statuses, errors, and accessibility labels follow the active language.
- The frontend production build and release preflight pass.
