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
  # @param destination_ids [Array<Integer>, nil] nil evaluates every destination with links
  # @param global_years [Integer] the site-wide window (GrdaWarehouse::Config
  #   client_retention_years); the fallback for any data source without its own override
  # @param expiring_within [Integer, nil] when set, only rollups whose window ends within this
  #   many days from today
  # @return [Array<Hash>] :destination_id, :last_activity_on (Date), :retention_years,
  #   :source_clients ([{ 'client_id', 'data_source_id', 'personal_id' }])
  def self.rollup_activity(destination_ids:, global_years:, expiring_within: nil)
    return [] if destination_ids && destination_ids.empty?

    sql = sanitize_sql_array([ROLLUP_ACTIVITY_SQL, global_years: global_years, within: expiring_within])
    id_filter = destination_ids.nil? ? '' : sanitize_sql_array(['AND wc.destination_id IN (:ids)', ids: destination_ids])
    having = expiring_within.nil? ? '' : sanitize_sql_array([EXPIRING_HAVING_SQL, global_years: global_years, within: expiring_within])
    sql = sql.sub('/*ID_FILTER*/', id_filter).sub('/*HAVING*/', having)

    result = connection.select_all(sql)
    result.cast_values.map do |values|
      row = result.columns.zip(values).to_h
      {
        destination_id: row['destination_id'],
        last_activity_on: row['last_activity_on'],
        retention_years: row['retention_years'],
        source_clients: row['source_clients'],
      }
    end
  end

  # Each UNION ALL arm yields (destination_id, activity date) from data attached to a source
  # client. HUD and HMIS custom tables are keyed by PersonalID + data_source_id like their
  # models. Soft-deleted rows are skipped everywhere: deleting a record is not serving the
  # client.
  ROLLUP_ACTIVITY_SQL = <<~SQL.squish
    WITH links AS (
      SELECT wc.destination_id, wc.source_id, c."PersonalID", c.data_source_id
      FROM warehouse_clients wc
      JOIN "Client" c ON c.id = wc.source_id
      WHERE wc.deleted_at IS NULL /*ID_FILTER*/
    ),
    activity AS (
      SELECT destination_id, MAX(activity_on) AS last_activity_on FROM (
        SELECT l.destination_id, GREATEST(c."DateUpdated", c."DateCreated")::date AS activity_on
          FROM links l JOIN "Client" c ON c.id = l.source_id
        UNION ALL
        SELECT l.destination_id, GREATEST(e."EntryDate", e."DateUpdated"::date)
          FROM links l JOIN "Enrollment" e ON e."PersonalID" = l."PersonalID" AND e.data_source_id = l.data_source_id AND e."DateDeleted" IS NULL
        UNION ALL
        SELECT l.destination_id, GREATEST(x."ExitDate", x."DateUpdated"::date)
          FROM links l JOIN "Exit" x ON x."PersonalID" = l."PersonalID" AND x.data_source_id = l.data_source_id AND x."DateDeleted" IS NULL
        UNION ALL
        SELECT l.destination_id, GREATEST(s."DateProvided", s."DateUpdated"::date)
          FROM links l JOIN "Services" s ON s."PersonalID" = l."PersonalID" AND s.data_source_id = l.data_source_id AND s."DateDeleted" IS NULL
        UNION ALL
        SELECT l.destination_id, GREATEST(cls."InformationDate", cls."DateUpdated"::date)
          FROM links l JOIN "CurrentLivingSituation" cls ON cls."PersonalID" = l."PersonalID" AND cls.data_source_id = l.data_source_id AND cls."DateDeleted" IS NULL
        UNION ALL
        SELECT l.destination_id, GREATEST(ev."EventDate", ev."DateUpdated"::date)
          FROM links l JOIN "Event" ev ON ev."PersonalID" = l."PersonalID" AND ev.data_source_id = l.data_source_id AND ev."DateDeleted" IS NULL
        UNION ALL
        SELECT l.destination_id, GREATEST(a."AssessmentDate", a."DateUpdated"::date)
          FROM links l JOIN "Assessment" a ON a."PersonalID" = l."PersonalID" AND a.data_source_id = l.data_source_id AND a."DateDeleted" IS NULL
        UNION ALL
        SELECT l.destination_id, GREATEST(cs."DateProvided", cs."DateUpdated"::date)
          FROM links l JOIN "CustomServices" cs ON cs."PersonalID" = l."PersonalID" AND cs.data_source_id = l.data_source_id AND cs."DateDeleted" IS NULL
        UNION ALL
        SELECT l.destination_id, GREATEST(ca."AssessmentDate", ca."DateUpdated"::date)
          FROM links l JOIN "CustomAssessments" ca ON ca."PersonalID" = l."PersonalID" AND ca.data_source_id = l.data_source_id AND ca."DateDeleted" IS NULL
        UNION ALL
        SELECT l.destination_id, GREATEST(cn.information_date, cn."DateUpdated"::date)
          FROM links l JOIN "CustomCaseNote" cn ON cn."PersonalID" = l."PersonalID" AND cn.data_source_id = l.data_source_id AND cn."DateDeleted" IS NULL
        UNION ALL
        SELECT l.destination_id, r.updated_at::date
          FROM links l JOIN ce_referrals r ON r.client_id = l.source_id AND r.deleted_at IS NULL
        UNION ALL
        SELECT l.destination_id, al.created_at::date
          FROM links l JOIN hmis_client_alerts al ON al.client_id = l.source_id AND al.deleted_at IS NULL
      ) u
      WHERE activity_on IS NOT NULL
      GROUP BY destination_id
    )
    SELECT l.destination_id,
      a.last_activity_on,
      MAX(COALESCE(ds.client_retention_years, :global_years)) AS retention_years,
      jsonb_agg(jsonb_build_object('client_id', l.source_id, 'data_source_id', l.data_source_id, 'personal_id', l."PersonalID")) AS source_clients
    FROM links l
    JOIN activity a ON a.destination_id = l.destination_id
    JOIN data_sources ds ON ds.id = l.data_source_id
    GROUP BY l.destination_id, a.last_activity_on
    /*HAVING*/
  SQL

  EXPIRING_HAVING_SQL = <<~SQL.squish
    HAVING a.last_activity_on + make_interval(years => MAX(COALESCE(ds.client_retention_years, :global_years)))
      BETWEEN CURRENT_DATE AND CURRENT_DATE + :within
  SQL
end
