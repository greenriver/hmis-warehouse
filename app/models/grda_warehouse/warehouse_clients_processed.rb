###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'util/hud'

class GrdaWarehouse::WarehouseClientsProcessed < GrdaWarehouseBase
  include RandomScope
  include ArelHelper

  self.table_name = :warehouse_clients_processed

  belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client'
  belongs_to :warehouse_client, class_name: 'GrdaWarehouse::WarehouseClient', foreign_key: :client_id, primary_key: :destination_id
  has_many :service_history_enrollments, class_name: 'GrdaWarehouse::ServiceHistoryEnrollment', primary_key: :client_id, foreign_key: :client_id

  scope :service_history, -> { where(routine: 'service_history') }

  def self.update_cached_counts client_ids: []
    existing_by_client_id = where(
      client_id: client_ids,
      routine: :service_history,
    ).index_by(&:client_id)

    cohort_client_ids = GrdaWarehouse::CohortClient.joins(:cohort, :client).distinct.pluck(:client_id).to_set
    assessment_client_ids = GrdaWarehouse::Hud::Client.distinct.joins(:coc_assessment_touch_points).pluck(:id)

    calcs = StatsCalculator.new(client_ids: client_ids)
    client_ids.each do |client_id|
      processed = existing_by_client_id[client_id] || where(
        client_id: client_id,
        routine: :service_history,
      ).first_or_initialize

      processed.assign_attributes(
        last_service_updated_at: Date.current,
        first_homeless_date: calcs.first_homeless_dates[client_id],
        last_homeless_date: calcs.most_recent_homeless_dates[client_id],
        homeless_days: calcs.homeless_counts[client_id] || 0,
        first_chronic_date: calcs.first_chronic_dates[client_id],
        last_chronic_date: calcs.most_recent_chronic_dates[client_id],
        chronic_days: calcs.chronic_counts[client_id],
        first_date_served: calcs.first_total_dates[client_id],
        last_date_served: calcs.most_recent_total_dates[client_id],
        days_served: calcs.total_counts[client_id],
        days_homeless_last_three_years: calcs.all_homeless_in_last_three_years[client_id] || 0,
        literally_homeless_last_three_years: calcs.all_literally_homeless_last_three_years[client_id] || 0,
        days_homeless_plus_overrides: calcs.homeless_counts_plus_overrides[client_id] || 0,
      )
      if client_id.in?(cohort_client_ids + assessment_client_ids)
        processed.assign_attributes(
          CohortCalcs.new(processed.client).as_hash,
        )
      end
      processed.save if processed.changed?
      GrdaWarehouse::Hud::Client.destination.clear_view_cache(client_id)
    end
    nil
  end

  class StatsCalculator
    include ArelHelper

    def initialize(client_ids:)
      @client_ids = client_ids
    end

    def most_recent_homeless_dates
      @most_recent_homeless_dates ||= begin
        dates = GrdaWarehouse::ServiceHistoryServiceMaterialized.homeless.
          in_project_type(GrdaWarehouse::Hud::Project::HOMELESS_PROJECT_TYPES). # for index hinting
          where(client_id: @client_ids).
          group(:client_id).
          maximum(:date)

        GrdaWarehouse::ServiceHistoryServiceMaterialized.
          joins(service_history_enrollment: :project).
          merge(GrdaWarehouse::Hud::Project.overrides_homeless_active_status).
          where(client_id: @client_ids).
          group(:client_id).
          maximum(:date).each do |client_id, date|
            dates[client_id] = [dates[client_id], date].compact.max
          end

        dates
      end
    end

    def first_homeless_dates
      @first_homeless_dates ||= GrdaWarehouse::ServiceHistoryServiceMaterialized.homeless.
        in_project_type(GrdaWarehouse::Hud::Project::HOMELESS_PROJECT_TYPES). # for index hinting
        where(client_id: @client_ids).
        group(:client_id).
        minimum(:date)
    end

    def homeless_counts
      @homeless_counts ||= begin
        shsm_table_name = GrdaWarehouse::ServiceHistoryServiceMaterialized.table_name
        shsm = GrdaWarehouse::ServiceHistoryServiceMaterialized.arel_table
        shsm_a = shsm.alias('a')
        shsm_b = shsm.alias('b')
        shsm_c = shsm.alias('c')

        non_homeless_sql = GrdaWarehouse::ServiceHistoryServiceMaterialized.
          where(shsm_a[:homeless].eq(false)).
          where(shsm_a[:project_type].in(GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:ph])). # for index hinting
          where(shsm_a[:client_id].in(@client_ids)).
          where(shsm_a[:date].eq(shsm_b[:date])).
          where(shsm_a[:client_id].eq(shsm_b[:client_id])).
          select(shsm_a[:client_id], shsm_a[:date]).
          arel.exists.not.
          to_sql.
          sub("\"#{shsm_table_name}\"", "\"#{shsm_table_name}\" as a")

        homeless_sql = GrdaWarehouse::ServiceHistoryServiceMaterialized.
          where(shsm_b[:homeless].eq(true)).
          where(shsm_b[:project_type].in(GrdaWarehouse::Hud::Project::HOMELESS_PROJECT_TYPES)). # for index hinting
          where(shsm_b[:client_id].in(@client_ids)).
          where(non_homeless_sql).
          select(shsm_b[:client_id], shsm_b[:date]).
          to_sql.
          sub("\"#{shsm_table_name}\"", "\"#{shsm_table_name}\" as b")

        GrdaWarehouse::ServiceHistoryServiceMaterialized.
          from("(#{homeless_sql}) as c").
          distinct.
          group(shsm_c[:client_id]).
          count('c.date')
      end
    end

    def homeless_counts_plus_overrides
      @homeless_counts_plus_overrides ||= begin
        shsm_table_name = GrdaWarehouse::ServiceHistoryServiceMaterialized.table_name
        shsm_t = GrdaWarehouse::ServiceHistoryServiceMaterialized.arel_table
        shsm_o = shsm_t.alias('o')
        shsm_a = shsm_t.alias('a')
        shsm_b = shsm_t.alias('b')
        shsm_c = shsm_t.alias('c')

        override_sql = GrdaWarehouse::ServiceHistoryServiceMaterialized.
          joins(shsm_t.join(she_t).on(shsm_o[:service_history_enrollment_id].eq(she_t[:id])).join_sources).
          joins(she_t.join(p_t).on(she_t[:data_source_id].eq(p_t[:data_source_id]).and(she_t[:project_id].eq(p_t[:ProjectID]))).join_sources).
          merge(GrdaWarehouse::Hud::Project.includes_verified_days_homeless).
          where(shsm_o[:client_id].in(@client_ids)).
          select(shsm_o[:client_id], shsm_o[:date]).
          to_sql.
          sub("\"#{shsm_table_name}\"", "\"#{shsm_table_name}\" as o")

        non_homeless_sql = GrdaWarehouse::ServiceHistoryServiceMaterialized.
          where(shsm_a[:homeless].eq(false)).
          where(shsm_a[:project_type].in(GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:ph])). # for index hinting
          where(shsm_a[:client_id].in(@client_ids)).
          where(shsm_a[:date].eq(shsm_b[:date])).
          where(shsm_a[:client_id].eq(shsm_b[:client_id])).
          select(shsm_a[:client_id], shsm_a[:date]).
          arel.exists.not.
          to_sql.
          sub("\"#{shsm_table_name}\"", "\"#{shsm_table_name}\" as a")

        homeless_sql = GrdaWarehouse::ServiceHistoryServiceMaterialized.
          where(shsm_b[:homeless].eq(true)).
          where(shsm_b[:project_type].in(GrdaWarehouse::Hud::Project::HOMELESS_PROJECT_TYPES)). # for index hinting
          where(shsm_b[:client_id].in(@client_ids)).
          where(non_homeless_sql).
          select(shsm_b[:client_id], shsm_b[:date]).
          to_sql.
          sub("\"#{shsm_table_name}\"", "\"#{shsm_table_name}\" as b")

        GrdaWarehouse::ServiceHistoryServiceMaterialized.
          from("(#{homeless_sql} union #{override_sql}) as c").
          distinct.
          group(shsm_c[:client_id]).
          count('c.date')
      end
    end

    # days in ES, SO, SH, or TH that don't overlap with PH
    def all_literally_homeless_last_three_years
      @all_literally_homeless_last_three_years ||= begin
        shsm_table_name = GrdaWarehouse::ServiceHistoryServiceMaterialized.table_name
        shsm = GrdaWarehouse::ServiceHistoryServiceMaterialized.arel_table
        shsm_a = shsm.alias('a')
        shsm_b = shsm.alias('b')
        shsm_c = shsm.alias('c')

        non_homeless_sql = GrdaWarehouse::ServiceHistoryServiceMaterialized.
          where(shsm_a[:literally_homeless].eq(false)).
          where(shsm_a[:project_type].in(GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:ph] + GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:th])). # for index hinting
          where(shsm_a[:date].between(3.years.ago.to_date..Date.current)).
          where(shsm_a[:client_id].in(@client_ids)).
          where(shsm_a[:date].eq(shsm_b[:date])).
          where(shsm_a[:client_id].eq(shsm_b[:client_id])).
          select(shsm_a[:client_id], shsm_a[:date]).
          arel.exists.not.
          to_sql.
          sub("\"#{shsm_table_name}\"", "\"#{shsm_table_name}\" as a")

        homeless_sql = GrdaWarehouse::ServiceHistoryServiceMaterialized.
          where(shsm_b[:literally_homeless].eq(true)).
          where(shsm_b[:project_type].in(GrdaWarehouse::Hud::Project::LITERALLY_HOMELESS_PROJECT_TYPES)). # for index hinting
          where(shsm_b[:date].between(3.years.ago.to_date..Date.current)).
          where(shsm_b[:client_id].in(@client_ids)).
          where(non_homeless_sql).
          select(shsm_b[:client_id], shsm_b[:date]).
          to_sql.
          sub("\"#{shsm_table_name}\"", "\"#{shsm_table_name}\" as b")

        GrdaWarehouse::ServiceHistoryServiceMaterialized.
          from("(#{homeless_sql}) as c").
          distinct.
          group(shsm_c[:client_id]).
          count('c.date')
      end
    end

    # days in ES, SO, or SH that don't overlap with TH or PH
    def all_homeless_in_last_three_years
      @all_homeless_in_last_three_years ||= begin
        shsm_table_name = GrdaWarehouse::ServiceHistoryServiceMaterialized.table_name
        shsm = GrdaWarehouse::ServiceHistoryServiceMaterialized.arel_table
        shsm_a = shsm.alias('a')
        shsm_b = shsm.alias('b')
        shsm_c = shsm.alias('c')

        non_homeless_sql = GrdaWarehouse::ServiceHistoryServiceMaterialized.
          where(shsm_a[:homeless].eq(false)).
          where(shsm_a[:project_type].in(GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:ph])). # for index hinting
          where(shsm_a[:date].between(3.years.ago.to_date..Date.current)).
          where(shsm_a[:client_id].in(@client_ids)).
          where(shsm_a[:date].eq(shsm_b[:date])).
          where(shsm_a[:client_id].eq(shsm_b[:client_id])).
          select(shsm_a[:client_id], shsm_a[:date]).
          arel.exists.not.
          to_sql.
          sub("\"#{shsm_table_name}\"", "\"#{shsm_table_name}\" as a")

        homeless_sql = GrdaWarehouse::ServiceHistoryServiceMaterialized.
          where(shsm_b[:homeless].eq(true)).
          where(shsm_b[:project_type].in(GrdaWarehouse::Hud::Project::HOMELESS_PROJECT_TYPES)). # for index hinting
          where(shsm_b[:date].between(3.years.ago.to_date..Date.current)).
          where(shsm_b[:client_id].in(@client_ids)).
          where(non_homeless_sql).
          select(shsm_b[:client_id], shsm_b[:date]).
          to_sql.
          sub("\"#{shsm_table_name}\"", "\"#{shsm_table_name}\" as b")

        GrdaWarehouse::ServiceHistoryServiceMaterialized.
          from("(#{homeless_sql}) as c").
          distinct.
          group(shsm_c[:client_id]).
          count('c.date')
      end
    end

    def most_recent_chronic_dates
      @most_recent_chronic_dates ||= GrdaWarehouse::ServiceHistoryServiceMaterialized.literally_homeless.
        in_project_type(GrdaWarehouse::Hud::Project::LITERALLY_HOMELESS_PROJECT_TYPES). # for index hinting
        where(client_id: @client_ids).
        group(:client_id).
        maximum(:date)
    end

    def first_chronic_dates
      @first_chronic_dates ||= GrdaWarehouse::ServiceHistoryServiceMaterialized.literally_homeless.
        in_project_type(GrdaWarehouse::Hud::Project::LITERALLY_HOMELESS_PROJECT_TYPES). # for index hinting
        where(client_id: @client_ids).
        group(:client_id).
        minimum(:date)
    end

    def chronic_counts
      @chronic_counts ||= begin
        shsm_table_name = GrdaWarehouse::ServiceHistoryServiceMaterialized.table_name
        shsm = GrdaWarehouse::ServiceHistoryServiceMaterialized.arel_table
        shsm_a = shsm.alias('a')
        shsm_b = shsm.alias('b')
        shsm_c = shsm.alias('c')

        non_homeless_sql = GrdaWarehouse::ServiceHistoryServiceMaterialized.
          where(shsm_a[:literally_homeless].eq(false)).
          where(shsm_a[:project_type].in(GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:ph] + GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:th])). # for index hinting
          where(shsm_a[:date].between(3.years.ago.to_date..Date.current)).
          where(shsm_a[:client_id].in(@client_ids)).
          where(shsm_a[:date].eq(shsm_b[:date])).
          where(shsm_a[:client_id].eq(shsm_b[:client_id])).
          select(shsm_a[:client_id], shsm_a[:date]).
          arel.exists.not.
          to_sql.
          sub("\"#{shsm_table_name}\"", "\"#{shsm_table_name}\" as a")

        homeless_sql = GrdaWarehouse::ServiceHistoryServiceMaterialized.
          where(shsm_b[:literally_homeless].eq(true)).
          where(shsm_b[:project_type].in(GrdaWarehouse::Hud::Project::LITERALLY_HOMELESS_PROJECT_TYPES)). # for index hinting
          where(shsm_b[:date].between(3.years.ago.to_date..Date.current)).
          where(shsm_b[:client_id].in(@client_ids)).
          where(non_homeless_sql).
          select(shsm_b[:client_id], shsm_b[:date]).
          to_sql.
          sub("\"#{shsm_table_name}\"", "\"#{shsm_table_name}\" as b")

        GrdaWarehouse::ServiceHistoryServiceMaterialized.
          from("(#{homeless_sql}) as c").
          distinct.
          group(shsm_c[:client_id]).
          count('c.date')
      end
    end

    def most_recent_total_dates
      @most_recent_total_dates ||= GrdaWarehouse::ServiceHistoryServiceMaterialized.
        where(client_id: @client_ids).
        group(:client_id).
        maximum(:date)
    end

    def first_total_dates
      @first_total_dates ||= GrdaWarehouse::ServiceHistoryServiceMaterialized.
        where(client_id: @client_ids).
        group(:client_id).
        minimum(:date)
    end

    def total_counts
      @total_counts ||= GrdaWarehouse::ServiceHistoryServiceMaterialized.
        where(client_id: @client_ids).
        group(:client_id).
        distinct.
        count(:date)
    end
  end

  # stats used by Cohort reports --
  # FIXME: these are N+1 on client *and then some* so ideally
  # thy get rewritten as batched versions
  # like StatsCalculator
  class CohortCalcs
    attr_reader :client

    def initialize(client)
      @client = client
    end

    def as_hash
      {
        enrolled_homeless_shelter: client.service_history_enrollments.homeless_sheltered.ongoing.exists?,
        enrolled_homeless_unsheltered: client.service_history_enrollments.homeless_unsheltered.ongoing.exists?,
        enrolled_permanent_housing: client.service_history_enrollments.permanent_housing.ongoing.exists?,
        eto_coordinated_entry_assessment_score: client.most_recent_coc_assessment_score,
        household_members: household_members,
        last_homeless_visit: last_homeless_visit,
        open_enrollments: open_enrollments,
        rrh_desired: client.rrh_desired,
        vispdat_priority_score: client.calculate_vispdat_priority_score,
        vispdat_score: client.most_recent_vispdat_score,
        active_in_cas_match: client.cas_reports.where(active_match: true).exists?,
        last_exit_destination: client.last_exit_destination,
        last_cas_match_date: client.cas_reports.maximum(:match_started_at),
        lgbtq_from_hmis: client.sexual_orientation_from_hmis,
        cohorts_ongoing_enrollments_es: client.last_seen_in_type(:es),
        cohorts_ongoing_enrollments_sh: client.last_seen_in_type(:sh),
        cohorts_ongoing_enrollments_th: client.last_seen_in_type(:th),
        cohorts_ongoing_enrollments_so: client.last_seen_in_type(:so),
        cohorts_ongoing_enrollments_psh: client.last_seen_in_type(:psh),
        cohorts_ongoing_enrollments_rrh: client.last_seen_in_type(:rrh),
      }
    end

    private def household_members
      households = client.households
      return unless households.present?

      households.values.flatten.map do |member|
        "#{member['FirstName']} #{member['LastName']} (#{member['age']} in #{member['date'].year})"
      end.uniq.join('; ')
    end

    private def last_homeless_visit
      client.last_homeless_visits.to_json
    end

    private def open_enrollments
      client.service_history_enrollments.ongoing.
        distinct.residential.
        pluck(:project_type).map do |project_type|
          if project_type == 13
            [project_type, 'RRH']
          else
            [project_type, ::HUD.project_type_brief(project_type)]
          end
        end
    end
  end
end
