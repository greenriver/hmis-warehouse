# Translation

The translation system provides site-wide string customization backed by a database table and a Rails cache layer. It is not a locale/i18n system — it has no concept of language — but rather a way for each deployment to override display strings without code changes.

## How it works

`Translation` records have a `key` and a `text` column. The key is the default string shown to users; the text column holds the deployment-specific override. When `text` is blank the key itself is returned as-is.

Lookups go through `Rails.cache` keyed by an MD5 digest of the key string. The cache is populated in bulk by `BuildTranslationCacheJob` and individual entries are invalidated on save via `after_commit` callbacks. Unknown keys are auto-created in the database on first lookup so they can be translated later.

```
Translation.translate(key)          # returns text or key
Translation.translate_if_present(key)  # returns text or nil
```

## Entry points

| Layer | Location |
|---|---|
| View helper `_(text)` | `app/helpers/application_helper.rb` |
| Model class methods | `app/models/translation.rb` |
| Cache warm-up job | `app/jobs/build_translation_cache_job.rb` |
| Admin UI | `Admin::TranslationKeysController`, `Admin::TranslationTextController` |

`_(text)` in views is a thin wrapper around `Translation.translate`. The `translated?(text)` helper checks whether a key has been overridden.

## Admin interface

`/admin/translation_keys` lists all keys with inline editable text areas. Changes are saved via AJAX through `Admin::TranslationTextController#update`, which also invalidates the cache entry for that key. Filtering supports keyword search, missing-translation display, and a `common` flag subset.

## Key registry

`Translation.known_translations` holds a static array of all keys used in the app. `Translation.maintain_keys` seeds the database from this array, used in initial setup and deployments. `default_translations` holds a hash of keys that ship with pre-filled override text (primarily CAS assessment field labels that differ from the keys).

The bulk of the registered keys cover:
- UI labels for report names, CAS/CE workflow fields, and navigation
- CHA (Comprehensive Health Assessment) form questions and answer options, keyed as `CHA <SECTION>_<QUESTION>[_<ANSWER>]`
- CAS client attribute labels (prefixed `c_`)

## Cache behavior

- Cache entries use MD5 digests of the key as identifiers: `translations/<digest>`
- Default expiration: 8 hours in production, 5 minutes in development
- `BuildTranslationCacheJob` pre-warms the entire cache in batches of 500 using `write_multi`
- Individual invalidation happens on record save; bulk invalidation via `invalidate_translations_cache` clears all `translations/*` entries

## Schema history

The system originally used separate `translation_keys` and `translation_texts` tables. These were consolidated into a single `translations` table (migration `20241203185952`), and the old tables were dropped (`20241205185449`).
