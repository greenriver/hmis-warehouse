###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# A source client whose warehouse identity has aged out of the retention window. One row per
# source client, written all-or-none per identity by ClientRetentionJob; destination clients
# are resolved through warehouse_clients (GrdaWarehouse::HiddenClients). Presence here redacts
# the identity the same way an HMIS restriction does
# (see docs/features/warehouse/client-data-retention.md).
class GrdaWarehouse::InactiveClient < GrdaWarehouseBase
  # Newest activity date and applicable retention window for each destination client, rolled
  # up across every source client linked through a live warehouse_clients row.
  #
  # The window is the longest of the source data sources' windows, each falling back to
  # global_years, so a longer policy anywhere keeps the whole person.
  #
  # @param destination_ids [Array<Integer>]
  # @param global_years [Integer] the site-wide window (GrdaWarehouse::Config
  #   client_retention_years); the fallback for any data source without its own override
  # @return [Array<Hash>] :destination_id, :last_activity_on (Date), :retention_years,
  #   :basis ('exited' or 'open_enrollment'),
  #   :source_clients ([{ 'client_id', 'data_source_id', 'personal_id' }])
  def self.rollup_activity(destination_ids:, global_years:)
    return [] if destination_ids.empty?

    result = connection.select_all(rollup_activity_sql(destination_ids: destination_ids, global_years: global_years))
    result.cast_values.map do |values|
      row = result.columns.zip(values).to_h
      {
        destination_id: row['destination_id'],
        last_activity_on: row['last_activity_on'],
        retention_years: row['retention_years'],
        basis: row['basis'],
        source_clients: row['source_clients'],
      }
    end
  end

  # The assembled statement behind rollup_activity.
  # @param explain [Boolean] prefix with EXPLAIN (ANALYZE, BUFFERS)
  # @return [String]
  def self.rollup_activity_sql(destination_ids:, global_years:, explain: false)
    statement = explain ? "EXPLAIN (ANALYZE, BUFFERS) #{ROLLUP_ACTIVITY_SQL}" : ROLLUP_ACTIVITY_SQL
    sanitize_sql_array([statement, global_years: global_years, today: Date.current, ids: destination_ids])
  end

  # Two rules, chosen per identity. An identity with no open enrollment is judged on its
  # latest exit date and client row update: nothing else after an exit is service. An identity
  # with an open enrollment is judged on the HUD fields every project type keeps writing during
  # a stay, plus exit dates from its other enrollments. Soft-deleted rows and dates after today
  # are skipped everywhere. :today is bound from Date.current so callers comparing in Ruby use
  # the same day as the SQL.
  ROLLUP_ACTIVITY_SQL = <<~SQL.squish
    WITH links AS (
      SELECT wc.destination_id, wc.source_id, c."PersonalID", c.data_source_id
      FROM warehouse_clients wc
      JOIN "Client" c ON c.id = wc.source_id AND c."DateDeleted" IS NULL
      WHERE wc.deleted_at IS NULL AND wc.destination_id IN (:ids)
    ),
    enrollments AS (
      SELECT l.destination_id, e."EnrollmentID", e."PersonalID", e.data_source_id,
        e."EntryDate", e."DateUpdated", x."ExitDate"
      FROM links l
      JOIN "Enrollment" e ON e."PersonalID" = l."PersonalID" AND e.data_source_id = l.data_source_id AND e."DateDeleted" IS NULL
      LEFT JOIN "Exit" x ON x."EnrollmentID" = e."EnrollmentID" AND x."PersonalID" = e."PersonalID" AND x.data_source_id = e.data_source_id AND x."DateDeleted" IS NULL
    ),
    status AS (
      SELECT destination_id,
        BOOL_OR("ExitDate" IS NULL) AS has_open,
        MAX("ExitDate") FILTER (WHERE "ExitDate" <= :today::date) AS last_exit_on
      FROM enrollments
      GROUP BY destination_id
    ),
    client_activity AS (
      SELECT l.destination_id, MAX(c."DateUpdated"::date) FILTER (WHERE c."DateUpdated"::date <= :today::date) AS activity_on
      FROM links l JOIN "Client" c ON c.id = l.source_id
      GROUP BY l.destination_id
    ),
    open_activity AS (
      SELECT destination_id, MAX(activity_on) AS activity_on FROM (
        SELECT destination_id, GREATEST("EntryDate", "DateUpdated"::date, "ExitDate") AS activity_on FROM enrollments
        UNION ALL
        SELECT l.destination_id, s."DateProvided"
          FROM links l JOIN "Services" s ON s."PersonalID" = l."PersonalID" AND s.data_source_id = l.data_source_id AND s."DateDeleted" IS NULL
        UNION ALL
        SELECT l.destination_id, cls."InformationDate"
          FROM links l JOIN "CurrentLivingSituation" cls ON cls."PersonalID" = l."PersonalID" AND cls.data_source_id = l.data_source_id AND cls."DateDeleted" IS NULL
        UNION ALL
        SELECT l.destination_id, ib."InformationDate"
          FROM links l JOIN "IncomeBenefits" ib ON ib."PersonalID" = l."PersonalID" AND ib.data_source_id = l.data_source_id AND ib."DateDeleted" IS NULL
      ) u
      WHERE activity_on IS NOT NULL AND activity_on <= :today::date
      GROUP BY destination_id
    ),
    activity AS (
      SELECT ca.destination_id,
        CASE
          WHEN s.has_open THEN GREATEST(oa.activity_on, ca.activity_on)
          ELSE GREATEST(s.last_exit_on, ca.activity_on)
        END AS last_activity_on,
        CASE WHEN s.has_open THEN 'open_enrollment' ELSE 'exited' END AS basis
      FROM client_activity ca
      LEFT JOIN status s ON s.destination_id = ca.destination_id
      LEFT JOIN open_activity oa ON oa.destination_id = ca.destination_id
    )
    SELECT l.destination_id,
      a.last_activity_on,
      a.basis,
      MAX(COALESCE(ds.client_retention_years, :global_years)) AS retention_years,
      jsonb_agg(jsonb_build_object('client_id', l.source_id, 'data_source_id', l.data_source_id, 'personal_id', l."PersonalID")) AS source_clients
    FROM links l
    JOIN activity a ON a.destination_id = l.destination_id
    JOIN data_sources ds ON ds.id = l.data_source_id
    WHERE a.last_activity_on IS NOT NULL
    GROUP BY l.destination_id, a.last_activity_on, a.basis
  SQL
end
