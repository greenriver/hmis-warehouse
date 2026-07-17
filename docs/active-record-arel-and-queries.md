# ActiveRecord, Arel, and Query Best Practices

This document describes how we prefer to build database queries in this
application, and the hazards that motivate those preferences. It expands on the
[Database Queries](code_patterns_and_conventions.md#database-queries) section of
the code patterns guide.

## Table of Contents

- [The preference ladder](#the-preference-ladder)
- [Prefer range syntax over string comparisons](#prefer-range-syntax-over-string-comparisons)
- [Bulk updates: never pass raw SQL to `update_all`](#bulk-updates-never-pass-raw-sql-to-update_all)
- [The `Queries/UnsafeBulkUpdateSql` cop](#the-queriesunsafebulkupdatesql-cop)

## The preference ladder

When expressing a query, prefer the highest rung that cleanly does the job:

1. **Standard ActiveRecord** — finders, scopes, hash conditions, and `merge`.
   This is the default. It is the most readable, composable, and database
   agnostic option.

   ```ruby
   GrdaWarehouse::Hud::Enrollment.joins(:client).merge(GrdaWarehouse::Hud::Client.veteran)
   ```

2. **Arel** — for complex conditions that the hash form can't express cleanly
   (OR groups, comparisons, function calls, case-insensitive matches). Arel
   keeps us database agnostic and quotes identifiers correctly.

   Arel is *specifically* preferred over the hash form when a query touches the
   case-sensitive column and table names in the HUD tables — the nested hash
   syntax has had incompatibilities there.

   ```ruby
   c_t = GrdaWarehouse::Hud::Client.arel_table
   scope.where(c_t[:VeteranStatus].eq(1))
   ```

3. **Raw SQL strings** — a last resort. String interpolation and hard-coded SQL
   fragments bypass identifier quoting, are not database agnostic, and are
   easy to get wrong (SQL injection, ambiguous columns, quoting bugs). If you
   truly need a raw fragment, wrap it in `Arel.sql(...)`, qualify **every**
   column with its table name, and leave a comment explaining why the
   structured forms don't work.

The short version: **structured (ActiveRecord/Arel) over strings, always.**

## Prefer range syntax over string comparisons

For date/time (and other) comparisons, use Ruby range syntax instead of a raw
SQL string. It is safer (no interpolation), reads better, and stays database
agnostic.

```ruby
# good
scope.where(updated_at: old_date..)          # updated_at >= old_date
scope.where(created_at: ..cutoff)            # created_at <= cutoff
scope.where(effective_date: start..finish)   # BETWEEN start AND finish

# avoid
scope.where('updated_at >= ?', old_date)
```

## Bulk updates: never pass raw SQL to `update_all`

`update_all("col = ...")` embeds the string verbatim as the UPDATE statement's
`SET` clause. This is dangerous, and since **Rails 8.1** it is actively broken
on joined relations.

Rails 8.1 added support for `joins` in `update_all` / `delete_all` on
PostgreSQL and SQLite. When the relation carries a join — directly, or through a
scope such as `.hmis` (which does `joins(:data_source)`) — the PostgreSQL
adapter now rewrites the statement to alias the target table and re-add the real
table in a `FROM`:

```sql
UPDATE "Client" AS "__active_record_update_alias"
SET "RaceNone" = CASE WHEN "RaceNone" = 99 THEN 0 ELSE "RaceNone" END  -- ambiguous!
FROM "Client" INNER JOIN "data_sources" ON ...
WHERE "Client"."id" = "__active_record_update_alias"."id"
```

Because the table is now in scope twice (the alias and the `FROM`), a bare,
unqualified column reference in the raw string is **ambiguous**, and Postgres
raises `PG::AmbiguousColumn`. This is not configurable — the aliasing is
hard-coded in the Arel PostgreSQL visitor and fires whenever the relation has a
join and no `LIMIT` / `OFFSET` / `ORDER BY` / `GROUP BY`.

**The Hash form is always safe.** ActiveRecord qualifies the `SET` columns and
binds the right-hand-side values, so nothing is ambiguous:

```ruby
# good
clients.hmis.update_all(RaceNone: 99)

# good - conditional per-field update, still Hash form
fields.each do |field|
  clients.hmis.where(field => 99).update_all(field => 0)
end

# bad - raw SQL string; breaks on the joined `.hmis` scope
clients.hmis.update_all("RaceNone = CASE WHEN RaceNone = 99 THEN 0 ELSE RaceNone END")

# bad - the same hazard, just harder to spot (string built up first)
update_sql = fields.map { |f| "#{f} = CASE WHEN #{f} = 99 THEN 0 ELSE #{f} END" }.join(', ')
clients.hmis.update_all(update_sql)
```

If a raw SQL expression is genuinely unavoidable (e.g. a PostGIS function that
has no ActiveRecord equivalent), qualify every column explicitly and disable the
cop on that line with a comment:

```ruby
# rubocop:disable Queries/UnsafeBulkUpdateSql -- PostGIS expression, no join on this scope
scope.update_all(Arel.sql('simplified_geom = ST_MakeValid(geom)'))
# rubocop:enable Queries/UnsafeBulkUpdateSql
```

## The `Queries/UnsafeBulkUpdateSql` cop

A custom cop (`lib/rubocop/cop/queries/unsafe_bulk_update_sql.rb`) enforces the
rule above. It flags `update_all`, `delete_all`, and `update_counters` when the
argument is (or resolves to) a raw SQL string — including strings built by
interpolation, concatenation, `Arel.sql`, `.to_s`, `format`, or `.join`, and the
common case of a string assigned to a local variable and then passed in.

Hash arguments never trip the cop. Run it on its own with:

```sh
docker compose run --rm shell bundle exec rubocop --only Queries/UnsafeBulkUpdateSql
```
