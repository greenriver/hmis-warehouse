###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# For now, this only deals with RRH projects
# require 'get_process_mem'
module Reporting
  class Housed < ReportingBase
    include RailsDrivers::Extensions

    self.table_name = :warehouse_houseds
    include ArelHelper

    scope :viewable_by, ->(user) do
      # need to pluck project ids from the warehouse database
      where(project_id: GrdaWarehouse::Hud::Project.viewable_by(user).pluck(:id))
    end

    scope :rrh, -> do
      where(project_type: 13)
    end

    scope :psh, -> do
      where(project_type: [3, 9, 10])
    end

    scope :es, -> do
      where(project_type: 1)
    end

    scope :th, -> do
      where(project_type: 2)
    end

    scope :sh, -> do
      where(project_type: 8)
    end

    scope :youth, -> do
      where(dob: 24.years.ago..18.years.ago)
    end

    scope :youth_at_search_start, -> do
      where(age_at_search_start: 18..24)
    end

    scope :youth_at_search_end, -> do
      where(age_at_search_end: 18..24)
    end

    scope :youth_at_housed_date, -> do
      where(age_at_housed_date: 18..24)
    end

    scope :youth_at_housing_exit, -> do
      where(age_at_housing_exit: 18..24)
    end

    scope :veteran, -> do
      where(veteran_status: 1)
    end

    scope :individual, -> do
      where(presented_as_individual: true)
    end

    scope :family, -> do
      where(presented_as_individual: false)
    end

    scope :children_only, -> do
      where(children_only: true)
    end

    scope :ph_destinations, -> do
      where(destination: ::HUD.permanent_destinations)
    end

    # Pre-placement
    scope :enrolled_pre_placement, ->(start_date:, end_date:) do
      where.not(service_project: 'No Service Enrollment').
        where(
          arel_table[:search_start].lteq(end_date).
          and(
            arel_table[:search_end].gteq(start_date).
            or(arel_table[:search_end].eq(nil)),
          ),
        )
    end

    scope :exiting_pre_placement, ->(start_date:, end_date:) do
      where(search_end: start_date..end_date).
        where.not(service_project: 'No Service Enrollment')
    end

    scope :entering_pre_placement, ->(start_date:, end_date:) do
      where(search_start: start_date..end_date).
        where.not(service_project: 'No Service Enrollment')
    end

    scope :stayers_pre_placement, ->(start_date:, end_date:) do
      where(client_id: enrolled_pre_placement(start_date: start_date, end_date: end_date).select(:client_id)).
        where.not(client_id: exiting_pre_placement(start_date: start_date, end_date: end_date).select(:client_id))
    end

    scope :leavers_pre_placement, ->(start_date:, end_date:) do
      enrolled_pre_placement(start_date: start_date, end_date: end_date).
        exiting_pre_placement(start_date: start_date, end_date: end_date)
    end

    scope :exited_pre_placement_to_stabilization, ->(start_date:, end_date:) do
      leavers_pre_placement(start_date: start_date, end_date: end_date).
        where.not(housed_date: nil)
    end

    scope :exited_pre_placement_no_stabilization, ->(start_date:, end_date:) do
      leavers_pre_placement(start_date: start_date, end_date: end_date).
        where(housed_date: nil)
    end

    # Stabilization
    scope :enrolled_stabilization, ->(start_date:, end_date:) do
      where(
        arel_table[:housed_date].lteq(end_date).
        and(
          arel_table[:housing_exit].gteq(start_date).
          or(arel_table[:housing_exit].eq(nil)),
        ),
      )
    end

    scope :exiting_stabilization, ->(start_date:, end_date:) do
      where(housing_exit: start_date..end_date)
    end

    scope :entering_stabilization, ->(start_date:, end_date:) do
      where(housed_date: start_date..end_date)
    end

    scope :stayers_stabilization, ->(start_date:, end_date:) do
      where(
        client_id: enrolled_stabilization(start_date: start_date, end_date: end_date).select(:client_id),
      ).
        where.not(client_id: exiting_stabilization(start_date: start_date, end_date: end_date).select(:client_id))
    end

    scope :leavers_stabilization, ->(start_date:, end_date:) do
      enrolled_stabilization(start_date: start_date, end_date: end_date).
        exiting_stabilization(start_date: start_date, end_date: end_date)
    end

    # Combined
    scope :enrolled, ->(start_date:, end_date:) do
      where(
        arel_table[:search_start].lteq(end_date).
        and(
          arel_table[:housing_exit].gteq(start_date).
          or(arel_table[:housing_exit].eq(nil)),
        ),
      )
    end

    scope :stayers, ->(start_date:, end_date:) do
      enrolled(start_date: start_date, end_date: end_date).
        where(
          arel_table[:housing_exit].gt(end_date).
            or(arel_table[:housing_exit].eq(nil)),
        )
    end

    scope :leavers, ->(start_date:, end_date:) do
      enrolled(start_date: start_date, end_date: end_date).
        where(arel_table[:housing_exit].lteq(end_date))
    end

    scope :heads_of_households, -> do
      where(head_of_household: true)
    end

    def self.available_household_types
      {
        individual: 'Individuals',
        family: 'Families',
        children_only: 'Children only',
      }.freeze
    end

    def self.available_races
      ::HUD.races(multi_racial: true)
    end

    def self.available_ethnicities
      ::HUD.ethnicities
    end

    def self.available_genders
      ::HUD.genders
    end

    def self.available_veteran_stati
      ::HUD.no_yes_reasons_for_missing_data_options
    end

    def self.household_type(key)
      if available_household_types[key].present?
        key
      else
        :current_scope
      end
    end

    def self.race(key)
      return :current_scope if key == :all
      return key if available_races[key&.to_s].present?

      :current_scope
    end

    def self.ethnicity(key)
      return :current_scope if key == :all
      return key if available_ethnicities[key&.to_s&.to_i].present?

      :current_scope
    end

    def self.gender(key)
      return :current_scope if key == :all
      return key if available_genders[key&.to_s&.to_i].present?

      :current_scope
    end

    def self.veteran_status(key)
      return :current_scope if key == :all
      return key if available_veteran_stati[key&.to_s&.to_i].present?

      :current_scope
    end

    def populate!
      remove_no_longer_used
      client_ids.each_slice(1_000) do |client_id_batch|
        cache_client = GrdaWarehouse::Hud::Client.new
        client_race_scope_limit = GrdaWarehouse::Hud::Client.where(id: client_id_batch)

        current_client_details = client_details(client_id_batch)
        data = enrollment_data(client_id_batch).map do |en|
          client = current_client_details[en[:client_id]]
          next unless client.present?

          client.delete(:id)
          en.merge!(client)
          en[:month_year] = en[:housed_date]&.strftime('%Y-%m-01')
          if HUD.permanent_destinations.include?(en[:destination])
            en[:ph_destination] = :ph
          else
            en[:ph_destination] = :not_ph
          end
          en[:race] = cache_client.race_string(scope_limit: client_race_scope_limit, destination_id: en[:client_id])

          en[:age_at_search_start] = GrdaWarehouse::Hud::Client.age(date: en[:search_start], dob: en[:dob])
          en[:age_at_search_end] = GrdaWarehouse::Hud::Client.age(date: en[:search_end], dob: en[:dob])
          en[:age_at_housed_date] = GrdaWarehouse::Hud::Client.age(date: en[:housed_date], dob: en[:dob])
          en[:age_at_housing_exit] = GrdaWarehouse::Hud::Client.age(date: en[:housing_exit], dob: en[:dob])
          en
        end
        next unless data.present?

        headers = data.first.keys

        transaction do
          self.class.where(client_id: client_id_batch).delete_all
          self.class.import(headers, data.map(&:values))
        end
      end
    end

    # Remove any we aren't going to cleanup in batches
    def remove_no_longer_used
      # Note we're plucking this to avoid having a massive where not in
      unused_client_ids = self.class.distinct.pluck(:client_id) - client_ids
      self.class.where(client_id: unused_client_ids).delete_all
    end

    def two_project_ids
      @two_project_ids ||= affiliated_projects.keys
    end

    def one_project_ids
      GrdaWarehouse::Hud::Project.ph.
        or(GrdaWarehouse::Hud::Project.th).
        or(GrdaWarehouse::Hud::Project.es).
        or(GrdaWarehouse::Hud::Project.sh).
        where.not(id: two_project_ids).
        distinct.
        pluck(:id)
    end

    def lookback_date
      Reporting::MonthlyReports::Base.lookback_start
    end

    def enrollment_data(client_id_batch)
      future_cutoff = 1.years.from_now.to_date
      (one_project_data(client_id_batch) + two_project_data(client_id_batch)).map do |row|
        # Throw out any records where the start date is more than one year in the future
        next if row[:search_start].present? && row[:search_start] > future_cutoff

        # Wipe any future dates from the other fields since they aren't valid
        row[:search_end] = nil if row[:search_end].present? && row[:search_end] > future_cutoff
        row[:housed_date] = nil if row[:housed_date].present? && row[:housed_date] > future_cutoff
        row[:housing_exit] = nil if row[:housing_exit].present? && row[:housing_exit] > future_cutoff
        row
      end.compact
    end

    def default_row
      @default_row ||= {
        search_start: nil,
        search_end: nil,
        housed_date: nil,
        housing_exit: nil,
        project_type: nil,
        destination: nil,
        service_project: nil,
        residential_project: nil,
        client_id: nil,
        presented_as_individual: nil,
        children_only: nil,
        individual_adult: nil,
        dob: nil,
        race: nil,
        ethnicity: nil,
        veteran_status: nil,
        month_year: nil,
        ph_destination: nil,
        project_id: nil,
        hmis_project_id: nil,
        age_at_search_start: nil,
        age_at_search_end: nil,
        age_at_housed_date: nil,
        age_at_housing_exit: nil,
        head_of_household: nil,
      }
    end

    # fetch residential RRH data
    # fetch all enrollments for associated pre-placement enrollments
    # comparing by client_id, loop over rrh data and add pre-placement data for record immediately preceding
    #
    def two_project_data(client_id_batch)
      processed_service_enrollments = Set.new
      service_data = two_project_service_data(client_id_batch)
      from_residential_enrollments = two_project_residential_data(client_id_batch).map do |residential_enrollment|
        case residential_enrollment[:project_type]
        when *GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:ph]
          key = [
            residential_enrollment[:client_id],
            residential_enrollment[:residential_project_id],
          ]
          en = default_row.merge(residential_enrollment.slice(*default_row.keys))
          en[:project_id] = residential_enrollment[:residential_project_id]
          service_enrollments_for_client = service_data[key]
          if service_enrollments_for_client.present?
            related_service_enrollment = service_enrollments_for_client.detect do |ser_en|
              ser_en[:search_start] <= en[:housed_date]
            end
            if related_service_enrollment
              residential_enrollment[:project_type]
              processed_service_enrollments << related_service_enrollment[:enrollment_id]
              en[:search_start] = related_service_enrollment[:search_start]
              en[:search_end] = related_service_enrollment[:search_end]
              en[:service_project] = related_service_enrollment[:service_project]
            else
              en[:search_start] = residential_enrollment[:housed_date]
              en[:search_end] = residential_enrollment[:housed_date]
              en[:service_project] = 'No Service Enrollment'
            end
          else
            en[:search_start] = residential_enrollment[:housed_date]
            en[:search_end] = residential_enrollment[:housed_date]
            en[:service_project] = 'No Service Enrollment'
          end
          en[:source] = 'enrollment_based'
          en
        else
          # affiliations don't apply to ES/TH/SH, so ignore them
          next
        end
      end.compact

      from_service_enrollments = service_data.values.flatten(1).map do |ser_en|
        next if processed_service_enrollments.include? ser_en[:enrollment_id]

        ser_en[:project_id] = residential_project_id_for(ser_en[:service_project_id])
        en = default_row.merge(ser_en.slice(*default_row.keys))
        en[:source] = 'enrollment_based'
        en
      end.compact

      from_residential_enrollments + from_service_enrollments
    end

    def two_project_residential_data(client_id_batch)
      GrdaWarehouse::ServiceHistoryEnrollment.entry.
        where(client_id: client_id_batch).
        joins(:project, :enrollment, :client).
        merge(GrdaWarehouse::Hud::Project.where(id: two_project_ids)).
        where(
          she_t[:first_date_in_program].lt(Date.current).
          and(
            she_t[:last_date_in_program].gt(lookback_date).
            or(she_t[:last_date_in_program].eq(nil)),
          ),
        ).
        pluck(*two_project_residential_columns.values).
        map do |row|
          Hash[two_project_residential_columns.keys.zip(row)]
        end
    end

    def two_project_residential_columns
      @two_project_residential_columns ||= {
        residential_project_id: p_t[:id].as('residential_project_id'),
        housed_date: she_t[:first_date_in_program].as('housed_date'),
        housing_exit: she_t[:last_date_in_program],
        project_type: she_t[GrdaWarehouse::ServiceHistoryEnrollment.project_type_column],
        destination: she_t[:destination],
        residential_project: she_t[:project_name].as('residential_project'),
        client_id: she_t[:client_id],
        presented_as_individual: she_t[:presented_as_individual],
        children_only: she_t[:children_only],
        individual_adult: she_t[:individual_adult],
        project_id: p_t[:id],
        hmis_project_id: p_t[:ProjectID],
        head_of_household: she_t[:head_of_household],
      }.freeze
    end

    def two_project_service_data(client_id_batch)
      GrdaWarehouse::ServiceHistoryEnrollment.entry.
        where(client_id: client_id_batch).
        joins(:project, :enrollment, :client).
        merge(GrdaWarehouse::Hud::Project.where(id: affiliated_projects.values)).
        open_between(start_date: lookback_date, end_date: Date.current).
        order(she_t[:first_date_in_program].desc).
        pluck(*two_project_service_columns.values).
        map do |row|
          Hash[two_project_service_columns.keys.zip(row)]
        end.group_by do |row|
          [
            row[:client_id],
            residential_project_id_for(row[:service_project_id]),
          ]
        end
    end

    def residential_project_id_for(service_project_id)
      @inverse_affiliated_projects ||= affiliated_projects.invert
      @inverse_affiliated_projects[service_project_id]
    end

    def two_project_service_columns
      @two_project_service_columns ||= {
        service_project_id: p_t[:id],
        search_start: she_t[:first_date_in_program],
        search_end: she_t[:last_date_in_program].as('search_end'),
        service_project: she_t[:project_name].as('service_project'),
        client_id: she_t[:client_id],
        enrollment_id: she_t[:id],
      }.freeze
    end

    def affiliation_columns
      @affiliation_columns ||= {
        p_id: p_t[:id],
        res_id: :ResProjectID,
        ser_id: :ProjectID,
        data_source_id: :data_source_id,
      }.freeze
    end

    # Lookup for residential and service only projects in the form
    # { residential_project_id: service_project_id }
    def affiliated_projects
      @affiliated_projects ||= begin
        residential_projects = GrdaWarehouse::Hud::Affiliation.
          joins(:residential_project).
          merge(GrdaWarehouse::Hud::Project.ph.
            or(GrdaWarehouse::Hud::Project.th).
            or(GrdaWarehouse::Hud::Project.es).
            or(GrdaWarehouse::Hud::Project.sh)).
          pluck(*affiliation_columns.values).map do |row|
            Hash[affiliation_columns.keys.zip(row)]
          end

        service_projects = GrdaWarehouse::Hud::Affiliation.
          joins(:project).
          pluck(*affiliation_columns.values).map do |row|
            Hash[affiliation_columns.keys.zip(row)]
          end.index_by do |row|
            [
              row[:data_source_id],
              row[:res_id],
            ]
          end

        residential_projects.map do |residential_project|
          key = [
            residential_project[:data_source_id],
            residential_project[:res_id],
          ]
          service_project = service_projects[key]
          [
            residential_project[:p_id],
            service_project[:p_id],
          ]
        end.to_h
      end
    end

    def one_project_data(client_id_batch)
      GrdaWarehouse::ServiceHistoryEnrollment.entry.
        where(client_id: client_id_batch).
        joins(:project, :enrollment, :client).
        merge(GrdaWarehouse::Hud::Project.where(id: one_project_ids)).
        open_between(start_date: lookback_date, end_date: Date.current).
        pluck(*one_project_columns.values).
        map do |row|
          residential_enrollment = Hash[one_project_columns.keys.zip(row)]
          case residential_enrollment[:project_type]
          when *GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:ph]
            # if exit but no move-in-date, set search end to exit and blank exit, no stabilization, only pre-placement
            if residential_enrollment[:housing_exit].present? && residential_enrollment[:search_end].blank?
              residential_enrollment[:search_end] = residential_enrollment[:housing_exit]
              residential_enrollment[:housing_exit] = nil
            end
            # if the move-in-date is after the housing exit, set the move-in-date to the housing exit
            residential_enrollment[:housed_date] = residential_enrollment[:housing_exit] if residential_enrollment[:housed_date].present? && residential_enrollment[:housing_exit].present? && residential_enrollment[:housed_date] > residential_enrollment[:housing_exit]
            residential_enrollment[:source] = 'move-in-date'
          else
            # ES, TH, and SH don't have two phases, we are using housed to represent time in program
            residential_enrollment[:housed_date] = residential_enrollment[:search_start]
            residential_enrollment[:search_start] = nil
            residential_enrollment[:search_end] = nil
            residential_enrollment[:source] = 'enrollment_based'
          end
          default_row.merge(residential_enrollment)
        end
    end

    def one_project_columns
      @one_project_columns ||= {
        search_start: she_t[:first_date_in_program],
        search_end: she_t[:move_in_date].as('search_end'),
        housed_date: she_t[:move_in_date].as('housed_date'),
        housing_exit: she_t[:last_date_in_program],
        project_type: she_t[GrdaWarehouse::ServiceHistoryEnrollment.project_type_column],
        destination: she_t[:destination],
        service_project: she_t[:project_name].as('service_project'),
        residential_project: she_t[:project_name].as('residential_project'),
        client_id: she_t[:client_id],
        presented_as_individual: she_t[:presented_as_individual],
        children_only: she_t[:children_only],
        individual_adult: she_t[:individual_adult],
        project_id: p_t[:id],
        hmis_project_id: p_t[:ProjectID],
        head_of_household: she_t[:head_of_household],
      }.freeze
    end

    def client_ids
      @client_ids ||= GrdaWarehouse::ServiceHistoryEnrollment.entry.
        open_between(start_date: lookback_date, end_date: Date.current).
        joins(:project).
        merge(
          GrdaWarehouse::Hud::Project.ph.
          or(GrdaWarehouse::Hud::Project.th).
          or(GrdaWarehouse::Hud::Project.es).
          or(GrdaWarehouse::Hud::Project.sh),
        ).distinct.pluck(:client_id)
    end

    def client_columns
      {
        id: :id,
        # FirstName: :first_name,
        # LastName: :last_name,
        # SSN: :ssn,
        DOB: :dob,
        Ethnicity: :ethnicity,
        Female: :female,
        Male: :male,
        NoSingleGender: :nosinglegender,
        Transgender: :transgender,
        Questioning: :questioning,
        GenderNone: :gendernone,
        VeteranStatus: :veteran_status,
      }.freeze
    end

    def client_details(client_id_batch)
      GrdaWarehouse::Hud::Client.where(id: client_id_batch).
        pluck(*client_columns.keys).map do |row|
          Hash[client_columns.values.zip(row)]
        end.index_by { |m| m[:id] }
    end
  end
end
