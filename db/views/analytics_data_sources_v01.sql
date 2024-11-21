SELECT
  id, name, short_name, last_imported_at, source_type, visible_in_window, authoritative, authoritative_type, obey_consent
FROM
  data_sources
WHERE
  deleted_at IS NULL
