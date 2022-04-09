###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'util/hud'

class GrdaWarehouse::WarehouseClientsProcessed < GrdaWarehouseBase
  include RandomScope
  include ArelHelper
  include NotifierConfig

  self.table_name = :warehouse_clients_processed

  belongs_to :client, class_name: 'GrdaWarehouse::Hud::Client'
  belongs_to :warehouse_client, class_name: 'GrdaWarehouse::WarehouseClient', foreign_key: :client_id, primary_key: :destination_id
  has_many :service_history_enrollments, class_name: 'GrdaWarehouse::ServiceHistoryEnrollment', primary_key: :client_id, foreign_key: :client_id

  scope :service_history, -> { where(routine: 'service_history') }

  private def default_client_ids
    range = ::Filters::DateRange.new(start: 1.years.ago, end: Date.current)
    GrdaWarehouse::Hud::Client.destination.joins(source_enrollments: :project).
      merge(GrdaWarehouse::Hud::Enrollment.open_during_range(range)).
      distinct.
      pluck(:id)
  end

  def self.update_cached_counts(client_ids: [])
    new.update_cached_counts(client_ids: client_ids)
  end

  def update_cached_counts(client_ids: [])
    setup_notifier('WarehouseClientsProcessed')
    extra_data = []
    limited_data = []
    # If we passed any client_ids in, then use them, otherwise,
    # process anyone active in the past year, or who is on a cohort or active in CAS
    if client_ids.blank?
      client_ids = default_client_ids
      cohort_client_ids = GrdaWarehouse::CohortClient.joins(:cohort, :client).distinct.pluck(:client_id)
      cas_active_client_ids = GrdaWarehouse::Hud::Client.cas_active.pluck(:id)
      extra_data = (cohort_client_ids + cas_active_client_ids).uniq
      limited_data = client_ids - extra_data
    else
      extra_data = client_ids
    end

    existing_by_client_id = self.class.where(
      client_id: extra_data + limited_data,
      routine: :service_history,
    ).index_by(&:client_id)

    @notifier.ping("Updating Cache Details for #{limited_data.uniq.count} active clients #{Time.current}")
    limited_data.uniq.each_slice(5_000) do |client_id_batch|
      # puts "starting batch #{Time.current}"
      calcs = StatsCalculator.new(client_ids: client_id_batch)

      processed_batch = []
      client_id_batch.each do |client_id|
        processed = existing_by_client_id[client_id] || self.class.where(
          client_id: client_id,
          routine: :service_history,
        ).first_or_initialize

        # TODO: convert hash lookpus to method arguments (move into methods)
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
          # enrolled_homeless_shelter: calcs.enrolled_homeless_shelter(client_id),
          # enrolled_homeless_unsheltered: calcs.enrolled_homeless_unsheltered(client_id),
          # enrolled_permanent_housing: calcs.enrolled_permanent_housing(client_id),
          # household_members: calcs.household_members(client_id),
          # open_enrollments: calcs.open_enrollments(client_id),
          # rrh_desired: calcs.rrh_desired(client_id),
          # last_homeless_visit: calcs.last_homeless_visit(client_id),
          # cohorts_ongoing_enrollments_es: calcs.last_es_visit(client_id),
          # cohorts_ongoing_enrollments_sh: calcs.last_sh_visit(client_id),
          # cohorts_ongoing_enrollments_th: calcs.last_th_visit(client_id),
          # cohorts_ongoing_enrollments_so: calcs.last_so_visit(client_id),
          # cohorts_ongoing_enrollments_psh: calcs.last_psh_visit(client_id),
          # cohorts_ongoing_enrollments_rrh: calcs.last_rrh_visit(client_id),
          # active_in_cas_match: calcs.active_in_cas_match(client_id),
          # last_cas_match_date: calcs.last_cas_match_date(client_id),
          # lgbtq_from_hmis: calcs.sexual_orientation_from_hmis(client_id),
          # last_exit_destination: calcs.last_exit_destination(client_id),
          # vispdat_score: calcs.vispdat_score(client_id),
          # vispdat_priority_score: calcs.vispdat_priority_score(client_id),
        )
        processed_batch << processed if processed.changed?
      end
      if processed_batch.present?
        self.class.import(
          processed_batch,
          on_duplicate_key_update: {
            columns: [
              :last_service_updated_at,
              :first_homeless_date,
              :last_homeless_date,
              :homeless_days,
              :first_chronic_date,
              :last_chronic_date,
              :chronic_days,
              :first_date_served,
              :last_date_served,
              :days_served,
              :days_homeless_last_three_years,
              :literally_homeless_last_three_years,
              :days_homeless_plus_overrides,
              # :enrolled_homeless_shelter,
              # :enrolled_homeless_unsheltered,
              # :enrolled_permanent_housing,
              # :household_members,
              # :open_enrollments,
              # :rrh_desired,
              # :last_homeless_visit,
              # :cohorts_ongoing_enrollments_es,
              # :cohorts_ongoing_enrollments_sh,
              # :cohorts_ongoing_enrollments_th,
              # :cohorts_ongoing_enrollments_so,
              # :cohorts_ongoing_enrollments_psh,
              # :cohorts_ongoing_enrollments_rrh,
              # :active_in_cas_match,
              # :last_cas_match_date,
              # :lgbtq_from_hmis,
              # :last_exit_destination,
              # :vispdat_score,
              # :vispdat_priority_score,
            ],
          },
        )
      end
      client_id_batch.each do |client_id|
        GrdaWarehouse::Hud::Client.destination.clear_view_cache(client_id)
      end
    end

    # Anyone on a cohort, or who will sync with CAS gets some extra data
    # This is more expensive to calculate, so we limit who is included
    @notifier.ping("Updating Cache Details for #{extra_data.uniq.count} clients on cohorts or in CAS #{Time.current}")
    extra_data.uniq.each_slice(1_000) do |client_id_batch|
      # puts "starting extra batch #{Time.current}"
      calcs = StatsCalculator.new(client_ids: client_id_batch)
      processed_batch = []
      client_id_batch.each do |client_id|
        processed = existing_by_client_id[client_id] || self.class.where(
          client_id: client_id,
          routine: :service_history,
        ).first_or_initialize

        # TODO: convert hash lookpus to method arguments (move into methods)
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
          enrolled_homeless_shelter: calcs.enrolled_homeless_shelter(client_id),
          enrolled_homeless_unsheltered: calcs.enrolled_homeless_unsheltered(client_id),
          enrolled_permanent_housing: calcs.enrolled_permanent_housing(client_id),
          household_members: calcs.household_members(client_id),
          open_enrollments: calcs.open_enrollments(client_id),
          rrh_desired: calcs.rrh_desired(client_id),
          last_homeless_visit: calcs.last_homeless_visit(client_id),
          cohorts_ongoing_enrollments_es: calcs.last_es_visit(client_id),
          cohorts_ongoing_enrollments_sh: calcs.last_sh_visit(client_id),
          cohorts_ongoing_enrollments_th: calcs.last_th_visit(client_id),
          cohorts_ongoing_enrollments_so: calcs.last_so_visit(client_id),
          cohorts_ongoing_enrollments_psh: calcs.last_psh_visit(client_id),
          cohorts_ongoing_enrollments_rrh: calcs.last_rrh_visit(client_id),
          active_in_cas_match: calcs.active_in_cas_match(client_id),
          last_cas_match_date: calcs.last_cas_match_date(client_id),
          lgbtq_from_hmis: calcs.sexual_orientation_from_hmis(client_id),
          last_exit_destination: calcs.last_exit_destination(client_id),
          vispdat_score: calcs.vispdat_score(client_id),
          vispdat_priority_score: calcs.vispdat_priority_score(client_id),
        )
        processed_batch << processed if processed.changed?
      end
      if processed_batch.present?
        self.class.import(
          processed_batch,
          on_duplicate_key_update: {
            columns: [
              :last_service_updated_at,
              :first_homeless_date,
              :last_homeless_date,
              :homeless_days,
              :first_chronic_date,
              :last_chronic_date,
              :chronic_days,
              :first_date_served,
              :last_date_served,
              :days_served,
              :days_homeless_last_three_years,
              :literally_homeless_last_three_years,
              :days_homeless_plus_overrides,
              :enrolled_homeless_shelter,
              :enrolled_homeless_unsheltered,
              :enrolled_permanent_housing,
              :household_members,
              :open_enrollments,
              :rrh_desired,
              :last_homeless_visit,
              :cohorts_ongoing_enrollments_es,
              :cohorts_ongoing_enrollments_sh,
              :cohorts_ongoing_enrollments_th,
              :cohorts_ongoing_enrollments_so,
              :cohorts_ongoing_enrollments_psh,
              :cohorts_ongoing_enrollments_rrh,
              :active_in_cas_match,
              :last_cas_match_date,
              :lgbtq_from_hmis,
              :last_exit_destination,
              :vispdat_score,
              :vispdat_priority_score,
            ],
          },
        )
      end
      client_id_batch.each do |client_id|
        GrdaWarehouse::Hud::Client.destination.clear_view_cache(client_id)
      end
    end
    @notifier.ping("Done Updating Cache Details #{Time.current}")
    nil
  end

  class StatsCalculator
    include ArelHelper

    def initialize(client_ids:)
      @client_ids = client_ids
    end

    def most_recent_homeless_dates
      @most_recent_homeless_dates ||= begin
        source = GrdaWarehouse::ServiceHistoryServiceMaterialized
        source = source.service_excluding_extrapolated unless GrdaWarehouse::Config.get(:ineligible_uses_extrapolated_days)

        dates = source.homeless.
          in_project_type(GrdaWarehouse::Hud::Project::HOMELESS_PROJECT_TYPES). # for index hinting
          where(client_id: @client_ids).
          group(:client_id).
          maximum(:date)

        source.joins(service_history_enrollment: :project).
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

    def enrolled_homeless_shelter(client_id)
      @enrolled_homeless_shelter ||= ongoing_enrollments.homeless_sheltered.pluck(:client_id).to_set
      @enrolled_homeless_shelter.include?(client_id)
    end

    def enrolled_homeless_unsheltered(client_id)
      @enrolled_homeless_unsheltered ||= ongoing_enrollments.homeless_unsheltered.pluck(:client_id).to_set
      @enrolled_homeless_unsheltered.include?(client_id)
    end

    def enrolled_permanent_housing(client_id)
      @enrolled_permanent_housing ||= ongoing_enrollments.permanent_housing.pluck(:client_id).to_set
      @enrolled_permanent_housing.include?(client_id)
    end

    private def ongoing_enrollments
      GrdaWarehouse::ServiceHistoryEnrollment.entry.
        ongoing.
        where(client_id: @client_ids)
    end

    def household_members(client_id)
      @household_columns ||= {
        household_id: she_t[:household_id],
        data_source_id: she_t[:data_source_id],
        project_id: she_t[:project_id],
        first_date_in_program: she_t[:first_date_in_program],
        client_id: she_t[:client_id],
        age: she_t[:age],
        first_name: c_t[:FirstName],
        last_name: c_t[:LastName],
        # enrollment_group_id: she_t[:enrollment_group_id],
        # first_date_in_program: she_t[:first_date_in_program],
        # last_date_in_program: she_t[:last_date_in_program],
        # move_in_date: she_t[:move_in_date],
        # head_of_household: she_t[:head_of_household],
      }

      @client_household_ids ||= GrdaWarehouse::ServiceHistoryEnrollment.entry.
        enrollments_open_in_last_three_years.
        distinct.
        joins(:client).
        where.not(household_id: [nil, '']).
        pluck(:client_id, :household_id, :data_source_id, :project_id).
        group_by(&:shift)
      return unless @client_household_ids.key?(client_id)

      @households ||= GrdaWarehouse::ServiceHistoryEnrollment.entry.
        joins(:client).
        enrollments_open_in_last_three_years.
        where.not(household_id: [nil, '']).
        pluck(*@household_columns.values).map do |row|
          Hash[@household_columns.keys.zip(row)]
        end.uniq.group_by do |m|
          [
            m[:household_id],
            m[:data_source_id],
            m[:project_id],
          ]
        end
      @client_household_ids[client_id].map do |household_key|
        @households[household_key]&.flatten&.map do |member|
          next if member[:client_id] == client_id

          "#{member[:first_name]} #{member[:last_name]} (#{member[:age]} in #{member[:first_date_in_program]&.year})"
        end&.compact
      end.flatten.compact.uniq.join('; ').presence
    end

    def last_homeless_visit(client_id)
      @last_homeless_visit ||= last_seen_in_type(:homeless)
      (@last_homeless_visit[client_id] || []).to_json
    end

    def last_es_visit(client_id)
      @last_es_visit ||= last_seen_in_type(:es)
      @last_es_visit[client_id] || []
    end

    def last_sh_visit(client_id)
      @last_sh_visit ||= last_seen_in_type(:sh)
      @last_sh_visit[client_id] || []
    end

    def last_th_visit(client_id)
      @last_th_visit ||= last_seen_in_type(:th)
      @last_th_visit[client_id] || []
    end

    def last_so_visit(client_id)
      @last_so_visit ||= last_seen_in_type(:so)
      @last_so_visit[client_id] || []
    end

    def last_psh_visit(client_id)
      @last_psh_visit ||= last_seen_in_type(:psh)
      @last_psh_visit[client_id] || []
    end

    def last_rrh_visit(client_id)
      @last_rrh_visit ||= last_seen_in_type(:rrh)
      @last_rrh_visit[client_id] || []
    end

    # NOTE: this should be cached in the calling method since this will return different results based on type provided
    private def last_seen_in_type(type)
      lsit = {}
      GrdaWarehouse::ServiceHistoryEnrollment.entry.ongoing.
        merge(GrdaWarehouse::Hud::Project.public_send(type)).
        where(client_id: @client_ids).
        joins(:service_history_services, :project).
        group(:client_id, :project_name, p_t[:confidential], p_t[:id]).
        maximum(shs_t[:date]).
        each do |(client_id, project_name, confidential, project_id), date|
          project_name = GrdaWarehouse::Hud::Project.confidential_project_name if confidential
          lsit[client_id] ||= []
          lsit[client_id] << {
            project_name: project_name,
            date: date,
            project_id: project_id,
          }
        end
      lsit
    end

    def open_enrollments(client_id)
      @open_enrollments ||= {}.tap do |oe|
        GrdaWarehouse::ServiceHistoryEnrollment.entry.ongoing.
          distinct.
          residential.
          where(client_id: @client_ids).
          pluck(:client_id, :project_type).each do |id, project_type|
            oe[id] ||= []
            oe[id] << if project_type == 13
              [project_type, 'RRH']
            else
              [project_type, ::HUD.project_type_brief(project_type)]
            end
          end
      end
      @open_enrollments[client_id] || []
    end

    def rrh_desired(client_id)
      @rrh_desired ||= GrdaWarehouse::Hud::Client.where(id: @client_ids).pluck(:id, :rrh_desired).to_h
      @rrh_desired[client_id]
    end

    def active_in_cas_match(client_id)
      @active_in_cas_match ||= GrdaWarehouse::CasReport.where(active_match: true).pluck(:client_id).to_set
      @active_in_cas_match.include?(client_id)
    end

    def last_cas_match_date(client_id)
      @last_cas_match_date ||= GrdaWarehouse::CasReport.group(:client_id).maximum(:match_started_at)
      @last_cas_match_date[client_id]
    end

    def sexual_orientation_from_hmis(client_id)
      @sexual_orientation_from_hmis ||= {}.tap do |orientation|
        GrdaWarehouse::Hud::Client.destination.
          where(id: @client_ids).
          joins(:source_hmis_clients).
          merge(GrdaWarehouse::HmisClient.where.not(sexual_orientation: nil)).
          order(hmis_c_t[:updated_at].desc).
          pluck(c_t[:id], hmis_c_t[:sexual_orientation], hmis_c_t[:updated_at]).
          each do |id, value, _|
            orientation[id] ||= value
          end
      end
      @sexual_orientation_from_hmis[client_id]
    end

    def last_exit_destination(client_id)
      @last_exit_destination ||= {}.tap do |destinations|
        GrdaWarehouse::ServiceHistoryEnrollment.where(client_id: @client_ids).
          distinct.
          exit_within_date_range(start_date: 3.years.ago.to_date, end_date: Date.current).
          joins(enrollment: :exit).
          order(last_date_in_program: :desc).
          pluck(:client_id, :destination, ex_t[:OtherDestination], :last_date_in_program).
          each do |id, destination, other_destination, last_date_in_program|
            destination_code = destination || 99
            destination_string = if destination_code == 17
              other_destination
            else
              ::HUD.destination(destination_code)
            end
            destinations[id] ||= "#{destination_string} (#{last_date_in_program})"
          end
      end
      @last_exit_destination[client_id] || 'None'
    end

    # Fetch most recent VI-SPDAT from the warehouse,
    # if not available use the most recent ETO VI-SPDAT
    # The ETO VI-SPDAT are prioritized by max score on the most recent assessment
    # NOTE: if we have more than one VI-SPDAT on the same day, the calculation is complicated

    def vispdat_score(client_id)
      @vispdat_scores ||= GrdaWarehouse::Vispdat::Base.where(client_id: @client_ids).
        completed.
        scores.
        pluck(:client_id, :score).
        reverse.to_h # scores scope forces most recent first, to_h return the last one

      score = @vispdat_scores[client_id]
      return score if score.present?

      @hmis_vispdat_scores ||= {}.tap do |hvs|
        GrdaWarehouse::Hud::Client.destination.
          where(id: @client_ids).
          joins(:source_hmis_forms).
          merge(GrdaWarehouse::HmisForm.vispdat.newest_first).
          pluck(
            :id,
            hmis_form_t[:vispdat_total_score],
            hmis_form_t[:vispdat_youth_score],
            hmis_form_t[:vispdat_family_score],
            hmis_form_t[:collected_at],
          ).each do |id, total_score, youth_score, family_score, _|
            hvs[id] ||= [total_score, youth_score, family_score].compact.max
          end
      end
      @hmis_vispdat_scores[client_id]
    end

    def vispdat_priority_score(client_id)
      # get internal vispdat (most recent per client)
      # get hmis vispdat (most recent for client)
      # get all clients who are in the above sets

      vispdat_score = vispdat_score(client_id)
      return nil unless vispdat_score.present?

      client = vispdat_clients[client_id]
      vispdat = vispdat(client_id)

      if GrdaWarehouse::Config.get(:vispdat_prioritization_scheme) == 'veteran_status'
        prioritization_bump = 0
        prioritization_bump += 100 if client.veteran?
        vispdat_score + prioritization_bump
      elsif GrdaWarehouse::Config.get(:vispdat_prioritization_scheme) == 'vets_family_youth'
        prioritization_bump = 0
        prioritization_bump += 100 if client.veteran?
        prioritization_bump += 50 if family_vispdat?(vispdat, client)
        prioritization_bump += 25 if client.youth_on?

        vispdat_score + prioritization_bump
      else # Default GrdaWarehouse::Config.get(:vispdat_prioritization_scheme) == 'length_of_time'
        vispdat_length_homeless_in_days = days_homeless_for_vispdat_prioritization(vispdat, client)
        vispdat_prioritized_days_score = if vispdat_length_homeless_in_days >= 1095
          1095
        elsif vispdat_length_homeless_in_days >= 730
          730
        elsif vispdat_length_homeless_in_days >= 365 && vispdat_score >= 8
          365
        else
          0
        end
        vispdat_score + vispdat_prioritized_days_score
      end
    end

    private def days_homeless_for_vispdat_prioritization(_vispdat, client)
      client.vispdat_prioritization_days_homeless || all_homeless_in_last_three_years[client.id] || 0
    end

    private def vispdat_clients
      return unless internal_vispdats.present? || hmis_vispdats.present?

      ids = internal_vispdats.keys + hmis_vispdats.keys
      @vispdat_clients ||= GrdaWarehouse::Hud::Client.where(id: ids).index_by(&:id)
    end

    private def family_vispdat?(vispdat, client)
      # From local warehouse VI-SPDAT
      return vispdat.family? if vispdat.respond_to?(:family?)

      # From ETO VI-SPDAT, this is pre-calculated GrdaWarehouse::HmisForm.set_part_of_a_family
      return client.family_member
    end

    private def vispdat(client_id)
      internal = internal_vispdats[client_id]
      external = hmis_vispdats[client_id]

      vispdats = []
      vispdats << [internal.submitted_at, internal] if internal
      vispdats << [external.collected_at, external] if external
      # return the newest vispdat
      vispdats.sort_by(&:first)&.last&.last
    end

    private def internal_vispdats
      # Sometimes we don't have any VI-SPDAT.  ||= still wants to do the queries, short circuit
      return @internal_vispdats if @internal_vispdats_attempted

      @internal_vispdats ||= {}.tap do |internal|
        @internal_vispdats_attempted = true
        GrdaWarehouse::Vispdat::Base.where(client_id: @client_ids).completed.scores.
          each do |vi|
            internal[vi.client_id] ||= vi
          end
      end
    end

    private def hmis_vispdats
      # Sometimes we don't have any VI-SPDAT.  ||= still wants to do the queries, short circuit
      return @hmis_vispdats if @hmis_vispdats_attempted

      @hmis_vispdats ||= {}.tap do |internal|
        @hmis_vispdats_attempted = true
        GrdaWarehouse::HmisForm.vispdat.newest_first.joins(:destination_client).
          merge(GrdaWarehouse::Hud::Client.destination.where(id: @client_ids)).
          each do |vi|
            internal[vi.destination_client.id] ||= vi
          end
      end
    end
  end
end
