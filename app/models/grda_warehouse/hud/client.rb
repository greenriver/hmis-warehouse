###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'memery'
require 'restclient'

module GrdaWarehouse::Hud
  class Client < Base
    self.primary_key = :id
    include Rails.application.routes.url_helpers
    include Memery
    include RandomScope
    include ArelHelper
    include HealthCharts
    include ApplicationHelper
    include ::HudConcerns::Client
    include ::HmisStructure::Client
    include ::HmisStructure::Shared
    include HudSharedScopes
    include HudChronicDefinition
    include SiteChronic
    include ClientHealthEmergency
    include ::Youth::Intake
    include CasClientData
    include ClientSearch
    include ClientImageConsumer
    include VeteranStatusCalculator
    include NotifierConfig
    has_paper_trail

    attr_accessor :source_id

    self.table_name = :Client
    self.sequence_name = "public.\"#{table_name}_id_seq\""

    CACHE_EXPIRY = if Rails.env.production? then 4.hours else 30.seconds end

    has_many :client_files
    has_many :health_files
    has_many :vispdats, class_name: 'GrdaWarehouse::Vispdat::Base', inverse_of: :client
    has_many :ce_assessments, class_name: 'GrdaWarehouse::CoordinatedEntryAssessment::Base', inverse_of: :client
    has_one :ce_assessment, -> do
      merge(GrdaWarehouse::CoordinatedEntryAssessment::Base.active)
    end, class_name: 'GrdaWarehouse::CoordinatedEntryAssessment::Base', inverse_of: :client

    # operates on source_clients only
    has_one :most_recent_ce_assessment, -> do
      one_for_column(
        :AssessmentDate,
        source_arel_table: as_t,
        group_on: [:PersonalID, :data_source_id],
      )
    end, **hud_assoc(:PersonalID, 'Assessment')

    # operates on source_clients only
    has_one :most_recent_pathways_or_rrh_assessment, -> do
      one_for_column(
        :AssessmentDate,
        source_arel_table: as_t,
        group_on: [:PersonalID, :data_source_id],
        scope: pathways_or_rrh,
      )
    end, **hud_assoc(:PersonalID, 'Assessment')

    # operates on source_clients only
    has_one :most_recent_2023_pathways_assessment, -> do
      one_for_column(
        :AssessmentDate,
        source_arel_table: as_t,
        group_on: [:PersonalID, :data_source_id],
        scope: pathways,
      )
    end, **hud_assoc(:PersonalID, 'Assessment')

    # operates on source_clients only
    has_one :most_recent_2023_transfer_assessment, -> do
      one_for_column(
        :AssessmentDate,
        source_arel_table: as_t,
        group_on: [:PersonalID, :data_source_id],
        scope: transfer,
      )
    end, **hud_assoc(:PersonalID, 'Assessment')

    # operates on source_clients only
    has_one :most_recent_current_living_situation, -> do
      one_for_column(
        :InformationDate,
        source_arel_table: cls_t,
        group_on: [:PersonalID, :data_source_id],
      )
    end, **hud_assoc(:PersonalID, 'CurrentLivingSituation')

    has_one :cas_project_client, class_name: 'CasAccess::ProjectClient', foreign_key: :id_in_data_source
    has_one :cas_client, class_name: 'CasAccess::Client', through: :cas_project_client, source: :client

    has_many :splits_to, class_name: 'GrdaWarehouse::ClientSplitHistory', foreign_key: :split_from
    has_many :splits_from, class_name: 'GrdaWarehouse::ClientSplitHistory', foreign_key: :split_into

    belongs_to :data_source, inverse_of: :clients
    belongs_to :export, **hud_assoc(:ExportID, 'Export'), inverse_of: :clients, optional: true
    # The "HUD user" that most recently updated the client record
    belongs_to :user, **hud_assoc(:UserID, 'User'), inverse_of: :clients, optional: true

    has_one :warehouse_client_source, class_name: 'GrdaWarehouse::WarehouseClient', foreign_key: :source_id, inverse_of: :source
    has_many :warehouse_client_destination, class_name: 'GrdaWarehouse::WarehouseClient', foreign_key: :destination_id, inverse_of: :destination
    has_one :destination_client, through: :warehouse_client_source, source: :destination, inverse_of: :source_clients
    has_many :source_clients, through: :warehouse_client_destination, source: :source, inverse_of: :destination_client
    has_many :window_source_clients, through: :warehouse_client_destination, source: :source, inverse_of: :destination_client

    # Must be included after source_clients is defined...
    include Eto::TouchPoints

    has_one :processed_service_history, -> { where(routine: 'service_history') }, class_name: 'GrdaWarehouse::WarehouseClientsProcessed'
    has_one :first_service_history, -> { where record_type: 'first' }, class_name: 'GrdaWarehouse::ServiceHistoryEnrollment'

    has_many :eto_client_lookups, class_name: 'GrdaWarehouse::EtoQaaws::ClientLookup'
    has_many :eto_touch_point_lookups, class_name: 'GrdaWarehouse::EtoQaaws::TouchPointLookup'
    has_one :hmis_client, class_name: 'GrdaWarehouse::HmisClient'

    has_many :service_history_enrollments
    has_many :service_history_services
    has_many :service_history_entries, -> { entry }, class_name: 'GrdaWarehouse::ServiceHistoryEnrollment'
    has_many :service_history_entry_in_last_three_years, -> {
      entry_in_last_three_years
    }, class_name: 'GrdaWarehouse::ServiceHistoryEnrollment'
    has_many :service_history_entry_ongoing, -> {
      ongoing
    }, class_name: 'GrdaWarehouse::ServiceHistoryEnrollment'

    has_many :enrollments, class_name: 'GrdaWarehouse::Hud::Enrollment', foreign_key: [:PersonalID, :data_source_id], primary_key: [:PersonalID, :data_source_id], inverse_of: :client
    has_many :exits, through: :enrollments, source: :exit, inverse_of: :client
    has_many :enrollment_cocs, through: :enrollments, source: :enrollment_cocs, inverse_of: :client
    has_many :services, through: :enrollments, source: :services, inverse_of: :client
    has_many :disabilities, through: :enrollments, source: :disabilities, inverse_of: :client
    has_many :health_and_dvs, through: :enrollments, source: :health_and_dvs, inverse_of: :client
    has_many :income_benefits, through: :enrollments, source: :income_benefits, inverse_of: :client
    has_many :employment_educations, through: :enrollments, source: :employment_educations, inverse_of: :client
    has_many :current_living_situations, through: :enrollments
    has_many :events, through: :enrollments
    has_many :assessments, through: :enrollments, source: :assessments, inverse_of: :client
    has_many :assessment_questions, through: :assessments, source: :assessment_questions
    has_many :assessment_results, through: :assessments, source: :assessment_results
    has_many :youth_education_statuses, through: :enrollments

    # The following scopes are provided for data cleanup, but should generally not be
    # used, as these relationships should go through enrollments
    has_many :direct_exits, **hud_assoc(:PersonalID, 'Exit'), inverse_of: :direct_client
    has_many :direct_enrollment_cocs, **hud_assoc(:PersonalID, 'EnrollmentCoc'), inverse_of: :direct_client
    has_many :direct_services, **hud_assoc(:PersonalID, 'Service'), inverse_of: :direct_client
    has_many :direct_disabilities, **hud_assoc(:PersonalID, 'Disability'), inverse_of: :direct_client
    has_many :direct_health_and_dvs, **hud_assoc(:PersonalID, 'HealthAndDv'), inverse_of: :direct_client
    has_many :direct_income_benefits, **hud_assoc(:PersonalID, 'IncomeBenefit'), inverse_of: :direct_client
    has_many :direct_employment_educations, **hud_assoc(:PersonalID, 'EmploymentEducation'), inverse_of: :direct_client
    has_many :direct_events, **hud_assoc(:PersonalID, 'Event'), inverse_of: :direct_client
    has_many :direct_current_living_situations, **hud_assoc(:PersonalID, 'CurrentLivingSituation'), inverse_of: :direct_client
    has_many :direct_assessments, **hud_assoc(:PersonalID, 'Assessment'), inverse_of: :direct_client
    has_many :direct_assessment_questions, **hud_assoc(:PersonalID, 'AssessmentQuestion'), inverse_of: :enrollment
    has_many :direct_assessment_results, **hud_assoc(:PersonalID, 'AssessmentResult'), inverse_of: :enrollment
    has_many :direct_youth_education_statuses, **hud_assoc(:PersonalID, 'YouthEducationStatus'), inverse_of: :direct_client
    # End cleanup relationships

    has_many :organizations, -> { order(:OrganizationName).distinct }, through: :enrollments
    has_many :source_services, through: :source_clients, source: :services
    has_many :source_enrollments, through: :source_clients, source: :enrollments
    has_many :source_enrollment_cocs, through: :source_clients, source: :enrollment_cocs
    has_many :source_disabilities, through: :source_clients, source: :disabilities
    has_many :source_enrollment_disabilities, through: :source_enrollments, source: :disabilities
    has_many :source_employment_educations, through: :source_enrollments, source: :employment_educations
    has_many :source_current_living_situations, through: :source_enrollments, source: :current_living_situations
    has_many :source_events, through: :source_enrollments, source: :events
    has_many :source_assessments, through: :source_enrollments, source: :assessments
    has_many :source_assessment_questions, through: :source_enrollments, source: :direct_assessment_questions
    has_many :source_assessment_results, through: :source_enrollments, source: :assessment_results
    has_many :source_exits, through: :source_enrollments, source: :exit
    has_many :source_projects, through: :source_enrollments, source: :project
    has_many :permanent_source_exits, -> do
      permanent
    end, through: :source_enrollments, source: :exit
    has_many :permanent_source_exits_from_homelessness, -> do
      permanent.joins(:project).merge(GrdaWarehouse::Hud::Project.homeless)
    end, through: :source_enrollments, source: :exit

    has_many :source_health_and_dvs, through: :source_clients, source: :health_and_dvs
    has_many :source_enrollment_health_and_dvs, through: :source_enrollments, source: :health_and_dvs
    has_many :source_income_benefits, through: :source_clients, source: :income_benefits
    has_many :source_enrollment_income_benefits, through: :source_enrollments, source: :income_benefits
    has_many :source_enrollment_services, through: :source_enrollments, source: :services
    has_many :source_client_attributes_defined_text, through: :source_clients, source: :client_attributes_defined_text
    has_many :staff_x_clients, class_name: 'GrdaWarehouse::Hmis::StaffXClient', inverse_of: :client
    has_many :staff, class_name: 'GrdaWarehouse::Hmis::Staff', through: :staff_x_clients
    has_many :source_eto_client_lookups, through: :source_clients, source: :eto_client_lookups
    has_many :source_eto_touch_point_lookups, through: :source_clients, source: :eto_touch_point_lookups
    has_many :source_hmis_clients, through: :source_clients, source: :hmis_client
    has_many :source_hmis_forms, through: :source_clients, source: :hmis_forms
    has_many :source_non_confidential_hmis_forms, through: :source_clients, source: :non_confidential_hmis_forms

    has_many :cas_reports, class_name: 'GrdaWarehouse::CasReport', inverse_of: :client

    has_many :chronics, class_name: 'GrdaWarehouse::Chronic', inverse_of: :client

    has_many :chronics_in_range, ->(range) do
      where(date: range)
    end, class_name: 'GrdaWarehouse::Chronic', inverse_of: :client
    has_one :patient, class_name: 'Health::Patient'

    has_many :notes, class_name: 'GrdaWarehouse::ClientNotes::Base', inverse_of: :client
    has_many :chronic_justifications, class_name: 'GrdaWarehouse::ClientNotes::ChronicJustification'
    has_many :window_notes, class_name: 'GrdaWarehouse::ClientNotes::WindowNote'
    has_many :anomaly_notes, class_name: 'GrdaWarehouse::ClientNotes::AnomalyNote'
    has_many :cohort_notes, class_name: 'GrdaWarehouse::ClientNotes::CohortNote'
    has_many :alert_notes, class_name: 'GrdaWarehouse::ClientNotes::Alert'

    has_many :anomalies, class_name: 'GrdaWarehouse::Anomaly'
    has_many :cas_houseds, class_name: 'GrdaWarehouse::CasHoused'

    has_many :user_clients, class_name: 'GrdaWarehouse::UserClient'
    has_many :users, through: :user_clients, inverse_of: :clients
    has_many :non_confidential_user_clients, -> do
      merge(GrdaWarehouse::UserClient.non_confidential)
    end, class_name: 'GrdaWarehouse::UserClient'
    has_many :non_confidential_users, through: :non_confidential_user_clients

    has_many :cohort_clients, dependent: :destroy
    has_many :cohorts, through: :cohort_clients, class_name: 'GrdaWarehouse::Cohort'

    has_many :enrollment_change_histories

    has_many :verification_sources, class_name: 'GrdaWarehouse::VerificationSource'
    has_many :disability_verification_sources, class_name: 'GrdaWarehouse::VerificationSource::Disability'

    has_one :active_consent_form, class_name: 'GrdaWarehouse::ClientFile', primary_key: :consent_form_id, foreign_key: :id

    has_many :client_contacts, class_name: 'GrdaWarehouse::ClientContact'
    has_many :generic_services, class_name: 'GrdaWarehouse::Generic::Service'

    # Delegations
    delegate :first_homeless_date, to: :processed_service_history, allow_nil: true
    delegate :last_homeless_date, to: :processed_service_history, allow_nil: true
    delegate :first_chronic_date, to: :processed_service_history, allow_nil: true
    delegate :last_chronic_date, to: :processed_service_history, allow_nil: true
    delegate :first_date_served, to: :processed_service_history, allow_nil: true
    delegate :last_date_served, to: :processed_service_history, allow_nil: true

    # User access control, override in extensions
    scope :destination_visible_to, ->(_user, source_client_ids: nil) do # rubocop:disable Lint/UnusedBlockArgument
      none
    end

    scope :source_visible_to, ->(_user, client_ids: nil) do # rubocop:disable Lint/UnusedBlockArgument
      none
    end

    scope :searchable_to, ->(_user, client_ids: nil) do # rubocop:disable Lint/UnusedBlockArgument
      # FIXME: add doc as to why scopes are in an extension
      none
    end
    # End User access control

    scope :destination, -> do
      where(data_source_id: GrdaWarehouse::DataSource.destination_data_source_ids)
    end
    scope :source, -> do
      where(data_source_id: GrdaWarehouse::DataSource.source_data_source_ids)
    end

    scope :searchable, -> do
      where(data_source_id: GrdaWarehouse::DataSource.source_data_source_ids)
    end
    # For now, this is way to slow, calculate in ruby
    # scope :unmatched, -> do
    #   source.where.not(id: GrdaWarehouse::WarehouseClient.select(:source_id))
    # end
    #

    scope :verified_non_veteran, -> do
      where verified_veteran_status: :non_veteran
    end

    scope :individual, ->(on_date: Date.current) do
      where(
        id: GrdaWarehouse::ServiceHistoryEnrollment.entry.
          ongoing(on_date: on_date).
          distinct.
          individual.select(:client_id),
      )
    end

    scope :homeless_individual, ->(on_date: Date.current, chronic_types_only: false) do
      where(
        id: GrdaWarehouse::ServiceHistoryEnrollment.entry.
          currently_homeless(date: on_date, chronic_types_only: chronic_types_only).
          distinct.
          individual.select(:client_id),
      )
    end

    scope :homeless_on_date, ->(on_date: Date.current, chronic_types_only: false) do
      where(
        id: GrdaWarehouse::ServiceHistoryEnrollment.entry.
          currently_homeless(date: on_date, chronic_types_only: chronic_types_only).
          distinct.
          with_service.
          select(:client_id),
      )
    end

    scope :currently_homeless, ->(chronic_types_only: false) do
      # this is somewhat involved in order to make it composable and somewhat efficient
      # more efficient is a join + distinct, but the distinct makes it less composable
      # clearer and composable but less efficient would be to use an exists subquery

      if chronic_types_only
        project_types = HudUtility2024.chronic_project_types
      else
        project_types = HudUtility2024.homeless_project_types
      end

      inner_table = sh_t.
        project(sh_t[:client_id]).
        group(sh_t[:client_id]).
        where(sh_t[:record_type].eq 'entry').
        where(sh_t[:project_type].in(project_types)).
        where(sh_t[:last_date_in_program].eq nil).
        as('sh_t')
      joins "INNER JOIN #{inner_table.to_sql} ON #{c_t[:id].eq(inner_table[:client_id]).to_sql}"
    end

    # clients whose first residential service record is within the given date range
    scope :entered_in_range, ->(range) do
      end_date = if range.exclude_end?
        sht[:date].lt(range.last)
      else
        sht[:date].lteq(range.last)
      end
      sh  = GrdaWarehouse::ServiceHistoryEnrollment
      sht = sh.arel_table
      joins(:first_service_history).
        where(sht[:date].gteq(range.first)).
        where(end_date)
    end

    scope :in_data_source, ->(data_source_id) do
      where(data_source_id: data_source_id)
    end

    scope :cas_active, -> do
      scope = case GrdaWarehouse::Config.get(:cas_available_method).to_sym
      when :cas_flag
        # Short circuit if we're using manual flag setting
        return where(sync_with_cas: true)
      when :chronic
        joins(:chronics).where(chronics: { date: GrdaWarehouse::Chronic.most_recent_day })
      when :hud_chronic
        joins(:hud_chronics).where(hud_chronics: { date: GrdaWarehouse::HudChronic.most_recent_day })
      when :release_present
        where(housing_release_status: [full_release_string, partial_release_string])
      when :active_clients
        range = GrdaWarehouse::Config.cas_sync_range

        # Homeless and Coordinated Entry Projects
        homeless_ce_project_ids = GrdaWarehouse::Hud::Project.with_project_type(HudUtility2024.homeless_project_types + [14]).pluck(:id)
        # Projects with override to consider enrolled clients as actively homeless for CAS and Cohorts
        override_project_ids = GrdaWarehouse::Hud::Project.where(active_homeless_status_override: true).pluck(:id)

        service_options = { start_date: range.first, end_date: range.last }
        service_options[:service_scope] = GrdaWarehouse::ServiceHistoryService.service_excluding_extrapolated unless GrdaWarehouse::Config.get(:ineligible_uses_extrapolated_days)
        enrollment_scope = GrdaWarehouse::ServiceHistoryEnrollment.in_project(homeless_ce_project_ids + override_project_ids).
          with_service_between(**service_options)
        where(id: enrollment_scope.select(:client_id))
      when :project_group
        project_ids = GrdaWarehouse::Config.cas_sync_project_group&.projects&.ids
        return none if project_ids.blank?

        enrollment_scope = GrdaWarehouse::ServiceHistoryEnrollment.ongoing.in_project(project_ids)
        where(id: enrollment_scope.select(:client_id))
      when :boston
        # Release on file
        scope = where(housing_release_status: [full_release_string, partial_release_string])
        # enrolled in the chosen project group
        project_ids = GrdaWarehouse::Config.cas_sync_project_group&.projects&.ids
        if project_ids.present?
          enrollment_scope = GrdaWarehouse::ServiceHistoryEnrollment.ongoing.in_project(project_ids)
          scope = scope.where(id: enrollment_scope.select(:client_id))
        end
        # with a Pathways assessment (removed by request 11/23/23)
        # scope.where(id: joins(source_clients: :most_recent_pathways_or_rrh_assessment).select(:id))
        scope
      when :ce_with_assessment
        enrollment_scope = GrdaWarehouse::ServiceHistoryEnrollment.entry.
          in_project_type(HudUtility2024.performance_reporting[:ce]).
          ongoing.
          joins(enrollment: :assessments)
        where(id: enrollment_scope.select(:client_id))
      else
        raise NotImplementedError
      end

      # Include anyone who should be included by virtue of their data, and anyone who has the checkbox checked
      scope.or(where(sync_with_cas: true))
    end

    scope :full_housing_release_on_file, -> do
      where(housing_release_status: full_release_string)
    end

    scope :limited_cas_release_on_file, -> do
      where(housing_release_status: partial_release_string)
    end

    scope :no_release_on_file, -> do
      where(housing_release_status: nil)
    end

    scope :desiring_rrh, -> do
      where(rrh_desired: true)
    end

    scope :verified_disability, -> do
      where.not(disability_verified_on: nil)
    end

    scope :has_homeless_service_after_date, ->(date: 31.days.ago) do
      where(id:
        GrdaWarehouse::ServiceHistoryService.homeless(chronic_types_only: true).
        where(sh_t[:date].gt(date)).
        select(:client_id).distinct)
    end

    scope :has_homeless_service_between_dates, ->(start_date: 31.days.ago, end_date: Date.current, include_extrapolated: true) do
      shs_query = GrdaWarehouse::ServiceHistoryService.homeless(chronic_types_only: true).
        where(date: (start_date..end_date)).
        distinct
      shs_query = shs_query.service_excluding_extrapolated unless include_extrapolated
      where(id: shs_query.select(:client_id))
    end

    scope :full_text_search, ->(text) do
      text_search(text, client_scope: current_scope, sorted: false)
    end

    scope :needs_history_pdf, -> do
      destination.where(generate_history_pdf: true)
    end

    scope :with_unconfirmed_consent, -> do
      # The acts as taggable gem doesn't quite get the scope correct
      # we'll need to pluck
      joins(:client_files).
        where(id: GrdaWarehouse::ClientFile.consent_forms.unconfirmed.pluck(:client_id))
    end

    scope :with_confirmed_consent, -> do
      # The acts as taggable gem doesn't quite get the scope correct
      # we'll need to pluck
      joins(:client_files).
        where(id: GrdaWarehouse::ClientFile.consent_forms.confirmed.pluck(:client_id))
    end

    scope :with_unconfirmed_consent_or_disability_verification, -> do
      unconfirmed_consent = GrdaWarehouse::ClientFile.consent_forms.unconfirmed.distinct.pluck(:client_id)
      unconfirmed_disability = GrdaWarehouse::ClientFile.verification_of_disability.unconfirmed.
        joins(:client).merge(GrdaWarehouse::Hud::Client.where(disability_verified_on: nil)).
        distinct.pluck(:client_id)
      joins(:client_files).
        where(id: (unconfirmed_consent + unconfirmed_disability).uniq)
    end

    def hmis_source_visible_by?(user)
      return false unless user.can_upload_hud_zips?
      return false unless GrdaWarehouse::DataSource.editable_by(user).source.exists?

      self.class.hmis_source_visible_by(user).where(id: source_client_ids).exists?
    end

    scope :active_confirmed_consent_in_cocs, ->(coc_codes) do
      coc_codes = Array.wrap(coc_codes) + ['All CoCs']
      # if the client has a release in "my" cocs, or all cocs
      query = "#{quoted_table_name}.consented_coc_codes ?| array[#{coc_codes.map { |s| connection.quote(s) }.join(',')}]"
      # or if the cocs haven't been set
      query += " or #{quoted_table_name}.consented_coc_codes = '[]' "
      # and the release is valid
      consent_form_valid.where(Arel.sql(query))
    end

    scope :consent_form_valid, -> do
      case release_duration
      when 'One Year', 'Two Years'
        where(
          arel_table[:housing_release_status].matches("%#{full_release_string}").
            and(arel_table[:consent_form_signed_on].gteq(consent_validity_period.ago)),
        )
      when 'Use Expiration Date'
        where(
          arel_table[:housing_release_status].matches("%#{full_release_string}").
            and(arel_table[:consent_expires_on].gteq(Date.current)),
        )
      else
        where(arel_table[:housing_release_status].matches("%#{full_release_string}"))
      end
    end

    # Race scopes
    # Return destination client where any source clients meet the requirement
    scope :race_am_ind_ak_native, -> do
      where(
        id: GrdaWarehouse::WarehouseClient.joins(:source).
          where(c_t[:AmIndAKNative].eq(1)).
          select(:destination_id),
      )
    end

    scope :race_asian, -> do
      where(
        id: GrdaWarehouse::WarehouseClient.joins(:source).
          where(c_t[:Asian].eq(1)).
          select(:destination_id),
      )
    end

    scope :race_black_af_american, -> do
      where(
        id: GrdaWarehouse::WarehouseClient.joins(:source).
          where(c_t[:BlackAfAmerican].eq(1)).
          select(:destination_id),
      )
    end

    scope :race_native_hi_other_pacific, -> do
      race_native_hi_pacific
    end

    scope :race_native_hi_pacific, -> do
      where(
        id: GrdaWarehouse::WarehouseClient.joins(:source).
          where(c_t[:NativeHIPacific].eq(1)).
          select(:destination_id),
      )
    end

    scope :race_white, -> do
      where(
        id: GrdaWarehouse::WarehouseClient.joins(:source).
          where(c_t[:White].eq(1)).
          select(:destination_id),
      )
    end

    scope :race_hispanic_latinaeo, -> do
      where(
        id: GrdaWarehouse::WarehouseClient.joins(:source).
          where(c_t[:HispanicLatinaeo].eq(1)).
          select(:destination_id),
      )
    end

    scope :race_mid_east_n_african, -> do
      where(
        id: GrdaWarehouse::WarehouseClient.joins(:source).
          where(c_t[:MidEastNAfrican].eq(1)).
          select(:destination_id),
      )
    end

    scope :race_none, -> do
      where(
        id: GrdaWarehouse::WarehouseClient.joins(:source).
          where(c_t[:RaceNone].eq(1)).
          select(:destination_id),
      )
    end

    scope :race_doesnt_know, -> do
      where(
        id: GrdaWarehouse::WarehouseClient.joins(:source).
          where(c_t[:RaceNone].eq(8)).
          select(:destination_id),
      )
    end

    scope :race_refused, -> do
      where(
        id: GrdaWarehouse::WarehouseClient.joins(:source).
          where(c_t[:RaceNone].eq(9)).
          select(:destination_id),
      )
    end

    scope :race_not_collected, -> do
      where(
        id: GrdaWarehouse::WarehouseClient.joins(:source).
          where(c_t[:RaceNone].eq(99)).
          select(:destination_id),
      )
    end

    scope :multi_racial, -> do
      columns = [
        c_t[:AmIndAKNative],
        c_t[:Asian],
        c_t[:BlackAfAmerican],
        c_t[:NativeHIPacific],
        c_t[:HispanicLatinaeo],
        c_t[:MidEastNAfrican],
        c_t[:White],
      ]
      # anyone with no unknowns and at least two yeses
      where(Arel.sql(columns.map(&:to_sql).join(' + ')).between(2..98))
    end

    # races should be an array of valid races from race_fields
    scope :with_races, ->(races) do
      return current_scope unless races&.compact&.present?

      where(Arel.sql('1').in(races.map { |race| c_t[race] }))
    end

    # a scope where no race was chosen
    # potentially this should include RaceNone: [8, 9, 99], but if all others are 0 or 99, then
    # we really don't know the race
    scope :with_race_none, -> do
      not_race = [0, 99]
      where(
        AmIndAKNative: not_race,
        Asian: not_race,
        BlackAfAmerican: not_race,
        NativeHIPacific: not_race,
        White: not_race,
        HispanicLatinaeo: not_race,
        MidEastNAfrican: not_race,
      )
    end

    scope :gender_woman, -> do
      where(Woman: 1).where(arel_table[:NonBinary].not_eq(1).or(arel_table[:NonBinary].eq(nil)))
    end

    scope :gender_female, -> do
      gender_woman
    end

    scope :gender_man, -> do
      where(Man: 1).where(arel_table[:NonBinary].not_eq(1).or(arel_table[:NonBinary].eq(nil)))
    end

    scope :gender_male, -> do
      gender_man
    end

    scope :gender_mtf, -> do
      gender_transgender.where(Woman: 1)
    end

    scope :gender_ftm, -> do
      gender_transgender.where(Man: 1)
    end

    scope :no_single_gender, -> do
      gender_non_binary
    end

    scope :gender_non_binary, -> do
      where(NonBinary: 1)
    end

    scope :questioning, -> do
      where(Questioning: 1)
    end

    scope :gender_questioning, -> do
      where(Questioning: 1)
    end

    scope :gender_transgender, -> do
      where(Transgender: 1)
    end

    scope :gender_unknown, -> do
      where(GenderNone: [8, 9, 99])
    end

    scope :gender_culturally_specific, -> do
      where(CulturallySpecific: 1)
    end

    scope :gender_different_identity, -> do
      where(DifferentIdentity: 1)
    end

    ####################
    # Callbacks
    ####################
    after_create :notify_users
    attr_accessor :send_notifications

    # do not include ineligible clients for Sync with CAS
    def active_cohorts
      active_cohort_clients.map(&:cohort).compact.uniq
    end

    def active_cohort_clients
      cohort_clients.select do |cc|
        # meta.inactive is related to days of inactivity in HMIS
        meta = CohortColumns::Meta.new(cohort: cc.cohort, cohort_client: cc)
        cc.active? && cc.cohort&.active? && (cc.housed_date.blank? || cc.destination.blank?) && ! meta.inactive && ! cc.ineligible?
      end
    end

    # do not include ineligible clients for Sync with CAS
    def active_cohort_ids
      active_cohorts.map(&:id)
    end

    def homeless_service_in_last_n_days?(num = 90)
      return false unless date_of_last_homeless_service

      date_of_last_homeless_service > num.to_i.days.ago
    end

    # Do we have any declines that make us ineligible
    # that occurred more recently than our most-recent pathways
    # assessment?
    def pathways_ineligible?
      most_recent_pathways_ineligible_cas_response.present?
    end

    def most_recent_pathways_ineligible_cas_response
      @most_recent_pathways_ineligible_cas_response ||= cas_reports.ineligible_in_warehouse.
        declined.
        match_closed.
        match_failed.
        where(updated_at: most_recent_pathways_assessment_collected_on..Time.current).
        order(updated_at: :desc)&.first
    end

    def pathways_ineligible_on
      return false unless pathways_ineligible?

      most_recent_pathways_ineligible_cas_response.updated_at&.to_date
    end

    # do include ineligible clients for client dashboard, but don't include cohorts excluded from
    # client dashboard
    def cohorts_for_dashboard(user)
      viewable_cohort_ids = GrdaWarehouse::Cohort.viewable_by(user).pluck(:id)
      cohort_clients.map do |cc|
        cohort = cc.cohort
        meta = CohortColumns::Meta.new(cohort: cohort, cohort_client: cc)
        # cc.active? && cc.cohort&.active? && cc.cohort&.show_on_client_dashboard? && ! meta.inactive
        next nil unless cohort&.active? && cohort&.show_on_client_dashboard?

        OpenStruct.new(
          id: cohort.id,
          name: cohort.name,
          active: cc.active?,
          recent_activity: ! meta.inactive,
          link: viewable_cohort_ids.include?(cohort.id),
        )
      end.compact.uniq
    end

    def demographic_calculation_logic_description(attribute)
      case attribute
      when :veteran_status
        'Veteran status will be yes if any source clients provided a yes response.  This can be overridden by setting the verified veteran status under CAS readiness.'
      when :race
        'Race reflects the most-recent response where the client answered the question.'
      when :gender
        'Gender reflects the most-recent response where the client answered the question.'
      when :ssn
        'SSN reflects the earliest response where SSN Data Quality was full or partial.'
      when :dob
        'DOB reflects the earliest response where DOB Data Quality was full or partial.'
      when :name
        'Name reflects the earliest response where the Name Data Quality was full or partial.'
      end
    end

    def notify_users
      NotifyUser.client_added(id).deliver_later if send_notifications
    end

    def self.ahar_age_groups
      {
        range_0_to_1: { name: '< 1 yr old', start_age: 0, end_age: 1 },
        range_1_to_5: { name: '1 - 5 yrs old', start_age: 1, end_age: 6 },
        range_6_to_12: { name: '6 - 12 yrs old', start_age: 6, end_age: 13 },
        range_13_to_17: { name: '13 - 17 yrs old', start_age: 13, end_age: 18 },
        range_18_to_24: { name: '18 - 24 yrs old', start_age: 18, end_age: 25 },
        range_25_to_30: { name: '25 - 30 yrs old', start_age: 25, end_age: 31 },
        range_31_to_50: { name: '31 - 50 yrs old', start_age: 31, end_age: 51 },
        range_51_to_61: { name: '51 - 61 yrs old', start_age: 51, end_age: 61 },
        range_62_to_nil: { name: '62+ yrs old', start_age: 62, end_age: nil },
      }
    end

    def self.extended_age_groups
      {
        range_0_to_1: { name: '< 1 yr old', range: (0..0) },
        range_1_to_5: { name: '1 - 5 yrs old', range: (1..5) },
        range_6_to_13: { name: '6 - 13 yrs old', range: (6..13) },
        range_14_to_17: { name: '14 - 17 yrs old', range: (14..17) },
        range_18_to_21: { name: '18 - 21 yrs old', range: (18..21) },
        range_19_to_24: { name: '19 - 24 yrs old', range: (19..24) },
        range_25_to_30: { name: '25 - 30 yrs old', range: (25..30) },
        range_31_to_35: { name: '31 - 35 yrs old', range: (31..35) },
        range_36_to_40: { name: '36 - 40 yrs old', range: (36..40) },
        range_41_to_45: { name: '41 - 45 yrs old', range: (41..45) },
        range_44_to_50: { name: '46 - 50 yrs old', range: (46..50) },
        range_51_to_55: { name: '51 - 55 yrs old', range: (51..55) },
        range_55_to_60: { name: '56 - 60 yrs old', range: (56..60) },
        range_61_to_62: { name: '61 - 62 yrs old', range: (61..62) },
        range_62_plus: { name: '63+ yrs old', range: (63..Float::INFINITY) },
        missing: { name: 'Missing', range: [nil] },
      }
    end

    def source_clients_searchable_to(user)
      # FIXME: looks like we intended to memoize this but this is not memoizing, needs conditional assignment
      @source_clients_searchable_to = {}.tap do |clients|
        clients[user.id] ||= if source_client_ids.present?
          self.class.searchable_to(user, client_ids: source_client_ids).preload(:data_source).to_a
        else
          []
        end
      end
      @source_clients_searchable_to[user.id]
    end

    def alternate_names
      names = source_clients.map(&:full_name).uniq
      names -= [full_name]
      names.join(',')
    end

    def client_names(user:, health: false)
      names = source_clients_searchable_to(user).map do |client|
        {
          ds: client.data_source&.short_name,
          ds_id: client.data_source&.id,
          name: client.pii(user: user).full_name,
          health: client.data_source&.authoritative_type == 'health',
        }
      end

      if health && names.none? { |name| name[:health].present? } && patient.present?
        names << {
          ds: 'Health',
          ds_id: GrdaWarehouse::DataSource.health_authoritative_id,
          name: pii(user.auth_policy_provider).brief_name,
        }
      end
      names.uniq
    end

    # client has a disability response in the affirmative
    # where they don't have a subsequent affirmative or negative
    def currently_disabled?
      self.class.disabled_client_scope(client_ids: id).where(id: id).exists?
    end

    def self.disabled_client_scope(client_ids: nil)
      # This should be equivalent, but in testing has been significantly slower than the pluck
      # destination.where(id: disabling_condition_client_scope.select(:id)).
      #   or(destination.where(id: disabled_client_because_disability_scope.select(:id)))
      ids = if client_ids.present?
        client_ids = Array.wrap(client_ids)
        disabling_condition_ids = disabling_condition_client_scope(client_ids: client_ids).where(id: client_ids).pluck(:id)
        # If everyone is disabled, short circuit as we don't have to check disabilities
        return destination.where(id: disabling_condition_ids) if Array.wrap(client_ids).sort == disabling_condition_ids.sort

        client_ids -= disabling_condition_ids
        (
          disabling_condition_ids +
          disabled_client_because_disability_scope.where(id: client_ids).pluck(:id)
        ).uniq
      else
        (
          disabling_condition_client_scope.pluck(:id) +
          disabled_client_because_disability_scope.pluck(:id)
        ).uniq
      end
      destination.where(id: ids)
    end

    # client has a disability response in the affirmative
    # where they don't have a subsequent affirmative or negative
    def self.disabled_client_because_disability_scope
      d_t1 = GrdaWarehouse::Hud::Disability.arel_table
      d_t2 = d_t1.dup
      d_t2.table_alias = 'disability2'
      c_t1 = GrdaWarehouse::Hud::Client.arel_table
      c_t2 = c_t1.dup
      c_t2.table_alias = 'source_clients'
      GrdaWarehouse::Hud::Client.destination.
        joins(:source_enrollment_disabilities).
        where(Disabilities: { DisabilityType: [5, 6, 7, 8, 9, 10], DisabilityResponse: [1, 2, 3] }).
        where(
          d_t2.project(Arel.star).where(
            d_t2[:DateDeleted].eq(nil),
          ).where(
            d_t2[:DisabilityType].eq(d_t1[:DisabilityType]),
          ).where(
            d_t2[:InformationDate].gt(d_t1[:InformationDate]),
          ).where(
            d_t2[:DisabilityResponse].in([0, 1, 2, 3]),
          ).
          join(e_t).on(
            e_t[:PersonalID].eq(d_t2[:PersonalID]).
            and(e_t[:data_source_id].eq(d_t2[:data_source_id])).
            and(e_t[:EnrollmentID].eq(d_t2[:EnrollmentID])).
            and(e_t[:DateDeleted].eq(nil)),
          ).join(c_t2).on(
            e_t[:PersonalID].eq(c_t2[:PersonalID]).
            and(e_t[:data_source_id].eq(c_t2[:data_source_id])),
          ).join(wc_t).on(
            c_t2[:id].eq(wc_t[:source_id]).
            and(wc_t[:deleted_at].eq(nil)),
          ).where(
            wc_t[:destination_id].eq(c_t1[:id]),
          ).
          exists.not,
        ).distinct
    end

    # client has a disability response in the affirmative
    # where they don't have a subsequent affirmative or negative
    def self.disabled_client_ids
      disabled_client_scope.pluck(:id)
    end

    def self.disabling_condition_client_scope(client_ids: nil)
      mre_t = Arel::Table.new(:most_recent_enrollments)
      join = she_t.join(mre_t).on(she_t[:id].eq(mre_t[:current_id]))

      most_recent_enrollment_scope = GrdaWarehouse::ServiceHistoryEnrollment.
        joins(:enrollment).
        define_window(:client_by_start_date).partition_by(:client_id, order_by: { she_t[:first_date_in_program] => :desc }).
        select_window(:first_value, she_t[:id], over: :client_by_start_date, as: :current_id).
        where(e_t[:DisablingCondition].in([0, 1]))
      if client_ids.present?
        most_recent_enrollment_scope = most_recent_enrollment_scope.
          where(she_t[:client_id].in(client_ids))
      end

      destination.where(
        id: GrdaWarehouse::ServiceHistoryEnrollment.
        with(most_recent_enrollments: most_recent_enrollment_scope).
          joins(join.join_sources, :enrollment).
          where(e_t[:DisablingCondition].eq(1)).
          select(:client_id),
      )
    end

    # Include clients with an indefinite and impairing disability
    # and those who have had their disability verified manually
    scope :chronically_disabled, ->(end_date = Date.current) do
      start_date = end_date - 3.years
      where(
        id: joins(:source_enrollment_disabilities).
          merge(GrdaWarehouse::Hud::Enrollment.open_during_range(start_date..end_date)).
          merge(GrdaWarehouse::Hud::Disability.chronically_disabled.where(information_date: ..end_date)).select(:id),
      ).or(
        where(id: where.not(disability_verified_on: nil).select(:id)),
      )
    end

    def chronically_disabled?
      self.class.chronically_disabled.where(id: id).exists?
    end

    def deceased?
      deceased_on.present?
    end

    def deceased_on
      # To allow preload(:source_exits) do the calculation in memory
      @deceased_on ||= source_exits.
        select do |m|
          m.Destination == ::HudUtility2024.valid_destinations.invert['Deceased']
        end&.
        max_by(&:ExitDate)&.ExitDate
    end

    def moved_in_with_ph?
      enrollments.
        open_on_date.
        with_project_type(HudUtility2024.residential_project_type_numbers_by_code[:ph]).
        where(GrdaWarehouse::Hud::Enrollment.arel_table[:MoveInDate].lt(Date.current)).exists?
    end

    def self.show_last_seen_info?
      GrdaWarehouse::Config.get(:show_client_last_seen_info_in_client_details)
    end

    def scope_for_ongoing_residential_enrollments
      service_history_enrollments.
        entry.
        residential.
        ongoing
    end

    def scope_for_other_enrollments(user)
      active_consent_model.scope_for_other_enrollments(user)
    end

    def scope_for_residential_enrollments(user)
      active_consent_model.scope_for_residential_enrollments(user)
    end

    def active_consent_model
      @active_consent_model ||= GrdaWarehouse::Config.active_consent_class.new(client: self)
    end

    attr_accessor :merge
    attr_accessor :unmerge
    attr_accessor :bypass_search # Used for creating new clients

    def appropriate_path_for?(user)
      return false if user.blank?

      if show_demographics_to?(user)
        client_path(self)
      elsif GrdaWarehouse::Vispdat::Base.any_visible_by?(user)
        client_vispdats_path(self)
      elsif GrdaWarehouse::ClientFile.any_visible_by?(user)
        if user.can_use_separated_consent?
          client_releases_path(self)
        else
          client_files_path(self)
        end
      elsif GrdaWarehouse::YouthIntake::Base.any_visible_by?(user)
        client_youth_intakes_path(self)
      elsif GrdaWarehouse::CoordinatedEntryAssessment::Base.any_visible_by?(user)
        client_coordinated_entry_assessments_path(self)
      end
    end

    def show_health_pilot_for?(user)
      patient.present? && patient.accessible_by_user(user).present? && patient.pilot_patient? && GrdaWarehouse::Config.get(:healthcare_available)
    end

    def show_health_hpc_for?(user)
      patient.present? && patient.hpc_patient? && user.has_some_patient_access? && GrdaWarehouse::Config.get(:healthcare_available)
    end

    ##############################
    # NOTE: this section deals with the release/consent form as uploaded
    # and maintained in the warehouse
    def self.full_release_string
      # Return the untranslated string, but force the translator to see it
      release_string = GrdaWarehouse::Config.active_consent_class.full_release_string
      Translation.translate(release_string)
      release_string
    end

    def self.partial_release_string
      # Return the untranslated string, but force the translator to see it
      release_string = GrdaWarehouse::Config.active_consent_class.partial_release_string
      Translation.translate(release_string)
      release_string
    end

    def self.revoked_consent_string
      GrdaWarehouse::Config.active_consent_class.revoked_consent_string
    end

    def self.no_release_string
      GrdaWarehouse::Config.active_consent_class.no_release_string
    end

    def self.consent_validity_period
      if release_duration == 'One Year'
        1.years
      elsif release_duration == 'Two Years'
        2.years
      elsif release_duration == 'Indefinite'
        100.years
      else
        raise 'Unknown Release Duration'
      end
    end

    def self.revoke_expired_consent
      if release_duration.in?(['One Year', 'Two Years'])
        # This doesn't trigger callbacks (e.g., papertrail)
        where(c_t[:consent_form_signed_on].lteq(consent_validity_period.ago.to_date)).
          update_all(
            housing_release_status: nil,
            consented_coc_codes: [],
          )
      elsif release_duration == 'Use Expiration Date'
        destination.where(
          arel_table[:consent_expires_on].lt(Date.current),
        ).update_all(
          housing_release_status: nil,
          consented_coc_codes: [],
        )
      end
    end

    def release_current_status
      active_consent_model.release_current_status
    end

    def release_duration
      @release_duration ||= GrdaWarehouse::Config.get(:release_duration)
    end

    def self.release_duration
      @release_duration = GrdaWarehouse::Config.get(:release_duration)
    end

    def release_valid?(coc_codes: nil)
      return self.class.where(id: id).active_confirmed_consent_in_cocs(coc_codes).exists? unless coc_codes.nil?

      housing_release_status&.starts_with?(self.class.full_release_string) || false
    end

    def partial_release?
      housing_release_status&.starts_with?(self.class.partial_release_string) || false
    end

    def full_or_partial_release?
      release_valid? || partial_release?
    end

    def consent_form_valid?
      if release_duration.in?(['One Year', 'Two Years'])
        release_valid? && consent_form_signed_on.present? && consent_form_signed_on >= self.class.consent_validity_period.ago
      elsif release_duration == 'Use Expiration Date'
        release_valid? && consent_expires_on.present? && consent_expires_on >= Date.current
      else
        release_valid?
      end
    end

    def consent_confirmed?
      if release_duration == 'Use Expiration Date'
        consent_form_signed_on.present? && consent_form_valid?
      elsif GrdaWarehouse::Config.get(:auto_confirm_consent)
        client_files.consent_forms.signed.exists?
      else
        client_files.consent_forms.signed.confirmed.exists?
      end
    end

    def newest_consent_form
      # Regardless of confirmation status
      client_files.consent_forms.order(updated_at: :desc)&.first
    end

    def invalidate_consent!
      update_columns(
        consent_form_id: nil,
        housing_release_status: nil,
        consent_form_signed_on: nil,
        consent_expires_on: nil,
        consented_coc_codes: [],
      )
    end

    def apply_housing_release_status
      return unless GrdaWarehouse::Config.implied_consent?

      self.housing_release_status = GrdaWarehouse::Hud::Client.full_release_string
    end

    # End Release information
    ##############################
    def most_recent_verification_of_disability
      client_files.verification_of_disability.order(updated_at: :desc)&.first
    end

    # cas needs a simplified version of this
    def cas_substance_response
      response = source_disabilities.detect(&:substance?).try(:response)
      nos = [
        'No',
        'Client doesn\'t know',
        'Client refused',
        'Data not collected',
      ]
      return nil unless response.present?
      return 'Yes' unless nos.include?(response)

      response
    end

    def cas_substance_response?
      cas_substance_response == 'Yes'
    end

    def disabling_condition?
      currently_disabled?
    end

    # Define a bunch of disability methods we can use to get the response needed
    # for CAS integration
    # This generates methods like: substance_response()
    GrdaWarehouse::Hud::Disability.disability_types.each_value do |disability_type|
      define_method "#{disability_type}_response".to_sym do
        disability_check = "#{disability_type}?".to_sym
        # To allow this to work in batches where we preload source_disabilities, this needs to happen in RAM
        source_disabilities.
          select { |d| d.DisabilityResponse.in?([0, 1, 2, 3]) }.
          sort_by(&:InformationDate).
          reverse.
          detect(&disability_check)&.DisabilityResponse
      end
    end

    GrdaWarehouse::Hud::Disability.disability_types.each_value do |disability_type|
      define_method "#{disability_type}_response?".to_sym do
        send("#{disability_type}_response".to_sym).in?([1, 2, 3])
      end
    end

    # Use the Pathways answer if available, otherwise, HMIS
    def domestic_violence
      # To allow preload(:source_health_and_dvs) do the calculation in memory
      dv_scope = source_health_and_dvs.select { |m| m.DomesticViolenceSurvivor == 1 }
      lookback_days = GrdaWarehouse::Config.get(:domestic_violence_lookback_days)
      if lookback_days&.positive?
        any_dv_in_range = dv_scope.select do |m|
          m.InformationDate.present? && m.InformationDate > lookback_days.days.ago.to_date && # Limit report date to a reasonable range
          m.WhenOccurred == 1 # Limit to within 3 months of report date
        end.present?
        return 1 if any_dv_in_range
      elsif dv_scope.present?
        return 1
      end
    end

    def chronic?(on: nil) # rubocop:disable Naming/MethodParameterName
      on ||= site_chronic_source.most_recent_day
      site_chronics.where(date: on).present?
    end

    def longterm_stayer?
      days = site_chronics.order(date: :asc)&.last&.days_in_last_three_years || 0
      days >= 365
    end

    def ever_chronic?
      site_chronics.any?
    end

    def potentially_chronic?(on_date:)
      GrdaWarehouse::Tasks::ChronicallyHomeless.new(date: on_date, dry_run: true, client_ids: [id]).chronic_on_date(id)
    end

    # Households are people entering with the same HouseholdID to the same project, regardless of time
    def households
      @households ||= begin
        hids = service_history_entries.where.not(household_id: [nil, '']).pluck(:household_id, :data_source_id, :project_id).uniq
        if hids.any?
          columns = {
            household_id: she_t[:household_id],
            date: she_t[:date],
            client_id: she_t[:client_id],
            age: she_t[:age],
            enrollment_group_id: she_t[:enrollment_group_id],
            FirstName: c_t[:FirstName],
            LastName: c_t[:LastName],
            first_date_in_program: she_t[:first_date_in_program],
            last_date_in_program: she_t[:last_date_in_program],
            move_in_date: she_t[:move_in_date],
            data_source_id: she_t[:data_source_id],
            head_of_household: she_t[:head_of_household],
          }

          hh_where = hids.map do |hh_id, ds_id, p_id|
            she_t[:household_id].eq(hh_id).
              and(she_t[:data_source_id].eq(ds_id)).
              and(she_t[:project_id].eq(p_id)).to_sql
          end.join(' or ')

          entries = GrdaWarehouse::ServiceHistoryEnrollment.entry.
            joins(:client).
            where(Arel.sql(hh_where)).
            where.not(client_id: id).
            pluck(*columns.values).map do |row|
              Hash[columns.keys.zip(row)]
            end.uniq
          entries.map(&:with_indifferent_access).group_by do |m|
            [
              m['household_id'],
              m['data_source_id'],
            ]
          end
        end
      end
    end

    def household(household_id, data_source_id)
      households[[household_id, data_source_id]] if households.present?
    end

    def self.dashboard_family_warning
      if GrdaWarehouse::Config.get(:infer_family_from_household_id)
        'Clients presenting as families enrolled in homeless projects (ES, SH, SO, TH). ' + family_composition_warning
      else # uses project serves families
        'Clients enrolled in homeless projects (ES, SH, SO, TH) where the enrollment is at a project with inventory for families. ' + family_composition_warning
      end
    end

    def self.report_family_warning
      if GrdaWarehouse::Config.get(:infer_family_from_household_id)
        'Clients are limited to those where the household includes at least two people.' + family_composition_warning
      else # uses project serves families
        'Clients are limited to clients enrolled in a project with inventory for families.' + family_composition_warning
      end
    end

    def self.dashboard_parents_warning
      dashboard_family_warning + family_hoh_warning
    end

    def self.report_parents_warning
      report_family_warning + family_hoh_warning
    end

    def self.dashboard_youth_families_warning
      if GrdaWarehouse::Config.get(:infer_family_from_household_id)
        'Clients presenting as families with a head of household between the ages of 18 and 25 enrolled in homeless projects (ES, SH, SO, TH). ' + family_composition_warning
      else # uses project serves families
        'Clients enrolled in homeless projects (ES, SH, SO, TH) with a head of household between the ages of 18 and 25 where the enrollment is at a project with inventory for families. ' + family_composition_warning
      end
    end

    def self.report_youth_families_warning
      if GrdaWarehouse::Config.get(:infer_family_from_household_id)
        'Clients are limited to those presenting as families with a head of household between the ages of 18 and 25. ' + family_composition_warning
      else # uses project serves families
        'Clients are limited to clients enrolled in a project with inventory for families with a head of household between the ages of 18 and 25. ' + family_composition_warning
      end
    end

    def self.dashboard_youth_parents_warning
      dashboard_youth_families_warning + family_hoh_warning
    end

    def self.report_youth_parents_warning
      report_youth_families_warning + family_hoh_warning
    end

    def self.family_composition_warning
      if GrdaWarehouse::Config.get(:family_calculation_method) == :adult_child
        'Families are made up of at least two clients where the head of household is an adult (18+) who presented with a client under 18. '
      else
        'Families are made up of at least two clients regardless of age. '
      end
    end

    def self.family_hoh_warning
      'Clients are further limited to only Heads of Household. '
    end

    # after and before take dates, or something like 3.years.ago
    def presented_with_family?(after: nil, before: nil)
      return false unless households.present?
      raise 'After required if before specified.' if before.present? && ! after.present?

      hh = if before.present? && after.present?
        recent_households = households.select do |_, entries| # rubocop:disable Lint/UselessAssignment
          # return true if this client presented with family during the range in question
          # all entries will have the same date and last_date_in_program
          entry = entries.first
          (entry_date, exit_date) = entry.with_indifferent_access.values_at('date', 'last_date_in_program')
          en_1_start = entry_date # rubocop:disable Lint/UselessAssignment
          en_1_end = exit_date # rubocop:disable Lint/UselessAssignment
          en_2_start = after # rubocop:disable Lint/UselessAssignment
          en_2_end = before # rubocop:disable Lint/UselessAssignment

          # Excellent discussion of why this works:
          # http://stackoverflow.com/questions/325933/determine-whether-two-date-ranges-overlap
          # en_1_start < en_2_end && en_1_end > en_2_start rescue true # this catches empty exit dates
          dates_overlap(entry_date, exit_date, after, before)
        end
      elsif after.present?
        recent_households = households.select do |_, entries| # rubocop:disable Lint/UselessAssignment
          # all entries will have the same date and last_date_in_program
          entry = entries.first
          (entry_date, exit_date) = entry.with_indifferent_access.values_at('date', 'last_date_in_program')
          # If we entered the program after the date in question
          # or we exited the program after the date in question
          # or we haven't exited the program
          entry_date > after || exit_date.blank? || exit_date > after
        end
      else
        households
      end
      if GrdaWarehouse::Config.get(:family_calculation_method) == 'multiple_people' # rubocop:disable Style/GuardClause
        return hh.values.select { |m| m.size >= 1 }.any?
      else
        child = false
        adult = false
        hh.with_indifferent_access.each do |_, household|
          date = household.first[:date]
          # client life stage
          child = self.DOB.present? && age_on(date) < 18
          adult = self.DOB.blank? || age_on(date) >= 18
          # household members life stage
          household.map { |m| m['age'] }.uniq.each do |a|
            adult = true if a.present? && a >= 18
            child = true if a.blank? || a < 18
          end
          return true if child && adult
        end
        return child && adult
      end
    end

    memoize def pii(user:)
      GrdaWarehouse::ClientPii.new(self, policy: user.client_auth_policy(self))
    end

    def name
      "#{self.FirstName} #{self.LastName}"
    end
    deprecate :name, 'Use client.pii(user: current_user).brief_name instead'

    def names
      source_clients.map { |n| "#{n.data_source.short_name} #{n.full_name}" }
    end

    def hmis_client_response
      @hmis_client_response ||= JSON.parse(hmis_client.response).with_indifferent_access if hmis_client.present?
    end

    def email
      # Fetch the data from the source clients if we are a destination client
      return source_clients.map(&:email).reject(&:blank?).first if destination?

      # Look for value from OP HMIS
      value = most_recent_email_hmis if HmisEnforcement.hmis_enabled?
      # Look for value from other HMIS integrations
      value ||= hmis_client_response['Email'] if hmis_client_response.present?
      value ||= hmis_client.processed_fields['email'] if hmis_client&.processed_fields
      value
    end

    def home_phone
      # Fetch the data from the source clients if we are a destination client
      return source_clients.map(&:home_phone).reject(&:blank?).first if destination?

      value = most_recent_home_phone_hmis if HmisEnforcement.hmis_enabled?
      value ||= hmis_client_response['HomePhone'] if hmis_client_response.present?
      value
    end

    def cell_phone
      # Fetch the data from the source clients if we are a destination client
      return source_clients.map(&:cell_phone).reject(&:blank?).first if destination?

      value = most_recent_cell_or_other_phone_hmis if HmisEnforcement.hmis_enabled?
      value ||= hmis_client_response['CellPhone'] if hmis_client_response.present?
      value ||= hmis_client.processed_fields['phone'] if hmis_client&.processed_fields
      value
    end

    def work_phone
      # Fetch the data from the source clients if we are a destination client
      return source_clients.map(&:work_phone).reject(&:blank?).first if destination?

      value = most_recent_work_or_school_phone_hmis if HmisEnforcement.hmis_enabled?
      return value if value
      return unless hmis_client_response.present?

      work_phone = hmis_client_response['WorkPhone']
      work_phone += " x #{hmis_client_response['WorkPhoneExtension']}" if hmis_client_response['WorkPhoneExtension'].present?
      work_phone
    end

    def self.no_image_on_file_image
      return File.read(Rails.root.join('public', 'no_photo_on_file.jpg'))
    end

    def image_for_source_client(cache_for = 10.minutes) # rubocop:disable Lint/UnusedMethodArgument
      return '' unless GrdaWarehouse::Config.get(:eto_api_available) && source?

      image_data = nil
      return fake_client_image_data || self.class.no_image_on_file_image unless Rails.env.production?
      return nil unless GrdaWarehouse::Config.get(:eto_api_available)

      api_configs = EtoApi::Base.api_configs
      eto_client_lookups.detect do |c_lookup|
        api_key = api_configs.select { |_k, v| v['data_source_id'] == c_lookup.data_source_id }&.keys&.first
        return nil unless api_key.present?

        api ||= EtoApi::Base.new(api_connection: api_key).tap(&:connect)
        image_data = api.client_image( # rubocop:disable Style/RescueModifier
          client_id: c_lookup.participant_site_identifier,
          site_id: c_lookup.site_id,
        ) rescue nil
        image_data&.length&.positive?
      end
      set_local_client_image_cache(image_data)
      image_data || self.class.no_image_on_file_image
    end

    def accessible_via_qaaws?
      GrdaWarehouse::Config.get(:eto_api_available) && source_eto_client_lookups.exists?
    end

    def fetch_updated_source_hmis_clients(save: false)
      return nil unless accessible_via_qaaws?

      source_eto_client_lookups.map do |api_client|
        api_config = EtoApi::Base.api_configs.detect { |_, m| m['data_source_id'] == api_client.data_source_id }
        next unless api_config

        key = api_config.first
        api = EtoApi::Detail.new(api_connection: key)
        options = {
          api: api,
          client_id: api_client.client_id,
          participant_site_identifier: api_client.participant_site_identifier,
          site_id: api_client.site_id,
          subject_id: api_client.subject_id,
          data_source_id: api_client.data_source_id,
        }
        if save
          EtoApi::Tasks::UpdateEtoData.new.save_demographics(options)
        else
          EtoApi::Tasks::UpdateEtoData.new.fetch_demographics(options)
        end
      end.compact
    end

    # Note:
    def fetch_updated_source_hmis_forms(save: false)
      return nil unless accessible_via_qaaws?

      source_eto_touch_point_lookups.map do |api_touch_point|
        api_config = EtoApi::Base.api_configs.detect { |_, m| m['data_source_id'] == api_touch_point.data_source_id }
        next unless api_config

        key = api_config.first
        api = EtoApi::Detail.new(api_connection: key)
        options = {
          api: api,
          client_id: api_touch_point.client_id,
          touch_point_id: api_touch_point.assessment_id,
          site_id: api_touch_point.site_id,
          subject_id: api_touch_point.subject_id,
          response_id: api_touch_point.response_id,
          data_source_id: api_touch_point.data_source_id,
        }
        if save
          EtoApi::Tasks::UpdateEtoData.new.save_touch_point(options)
        else
          EtoApi::Tasks::UpdateEtoData.new.fetch_touch_point(options)
        end
      end.compact
    end

    # A useful array of hashes from API data
    def caseworkers(can_view_client_user_assignments: false)
      @caseworkers ||= [].tap do |m|
        # Caseworkers from HMIS
        source_hmis_clients.each do |c|
          staff_types.each do |staff_type|
            staff_name = c["#{staff_type}_name"]
            staff_attributes = c["#{staff_type}_attributes"]

            next unless staff_name.present?

            m << {
              title: staff_type.to_s.titleize,
              name: staff_name,
              phone: staff_attributes.try(:[], 'GeneralPhoneNumber'),
              source: 'HMIS',
            }
          end
        end
        return m unless can_view_client_user_assignments

        # Caseworkers from Warehouse
        user_clients.each do |uc|
          # next if uc.confidential? # should we ever not show confidential relationships
          m << {
            title: uc.relationship,
            name: uc.user.name,
            phone: uc.user.phone,
            source: 'Warehouse',
          }
        end
      end
    end

    def es_so_enrollments_with_service_since(user, date)
      service_history_entries.visible_in_window_to(user).joins(:project).
        hud_homeless.
        service_within_date_range(start_date: date, end_date: Date.current).distinct
    end

    def cas_pregnancy_status
      one_year_ago = 1.years.ago.to_date
      in_last_year = one_year_ago .. Date.current
      # To allow preload(:source_health_and_dvs) do the calculation in memory
      hmis_pregnancy = source_health_and_dvs.detect do |m|
        m.PregnancyStatus == 1 &&
        (
          (m.InformationDate.present? && m.InformationDate > one_year_ago) ||
          (m.DueDate.present? && m.DueDate > Date.current - 3.months)
        )
      end.present?
      vispdat_pregnancy = false
      eto_pregnancy = false
      unless cas_calculator_instance.unrelated_columns.include?(:vispdat_score)
        vispdat_pregnancy = vispdats.completed.where(pregnant_answer: 1, submitted_at: in_last_year).exists?
        eto_pregnancy = source_hmis_forms.vispdat.
          vispdat_pregnant.
          where(collected_at: in_last_year).
          exists?
      end

      hmis_pregnancy || vispdat_pregnancy || eto_pregnancy
    end

    def staff_types
      [:case_manager, :assigned_staff, :counselor, :outreach_counselor]
    end

    SORT_OPTIONS = {
      best_match: 'Most Relevant',
      last_name_a_to_z: 'Last name A-Z',
      last_name_z_to_a: 'Last name Z-A',
      first_name_a_to_z: 'First name A-Z',
      first_name_z_to_a: 'First name Z-A',
      age_youngest_to_oldest: 'Youngest to Oldest',
      age_oldest_to_youngest: 'Oldest to Youngest',
    }.freeze

    def self.sort_by_option(option)
      option = option&.to_sym

      case option
      when :best_match
        current_scope # no order, use text search rank
      when :last_name_a_to_z
        order(arel_table[:LastName].asc.nulls_last)
      when :last_name_z_to_a
        order(arel_table[:LastName].desc.nulls_last)
      when :first_name_a_to_z
        order(arel_table[:FirstName].asc.nulls_last)
      when :first_name_z_to_a
        order(arel_table[:FirstName].desc.nulls_last)
      when :age_youngest_to_oldest
        order(arel_table[:DOB].desc.nulls_last)
      when :age_oldest_to_youngest
        order(arel_table[:DOB].asc.nulls_last)
      else
        raise ArgumentError, "invalid sort option #{option.inspect}"
      end
    end

    def self.housing_release_options
      options = [full_release_string]
      options << partial_release_string if GrdaWarehouse::Config.get(:allow_partial_release)
      options
    end

    def invalidate_service_history
      return unless processed_service_history.present?

      processed_service_history.destroy
    end

    def service_history_invalidated?
      processed_service_history.blank?
    end

    def destination?
      source_clients.size.positive?
    end

    def source?
      destination_client.present?
    end

    # Determine the date of the most-recent change to: Enrollment, Exit, Service
    def last_service_updated_at
      if source_clients.any?
        source_clients.map(&:last_service_updated_at).max
      else
        [exits.maximum('DateUpdated'), enrollments.maximum('DateUpdated'), services.maximum('DateUpdated')].compact.max
      end
    end

    def full_name
      [self.FirstName, self.MiddleName, self.LastName].select(&:present?).join(' ')
    end
    deprecate :full_name, 'Use client.pii(user: current_user).full_name instead'

    ########################
    # NOTE: this section deals with the consent form as seen in ETO via the API
    def consent_form_status
      @consent_form_status ||= source_hmis_clients.joins(:client).
        where.not(consent_form_status: nil).
        merge(Client.order(DateUpdated: :desc)).
        pluck(:consent_form_status).first
    end

    # Find the most-recently updated source_hmis_client with a non-null consent_form
    def signed_consent_form_fully?
      consent_form_status == 'Signed fully'
    end
    # End NOTE
    #############################

    def sexual_orientation_from_hmis
      source_hmis_clients.where.not(sexual_orientation: nil)&.order(updated_at: :desc)&.first&.sexual_orientation
    end

    def service_date_range
      @service_date_range ||= begin
        query = service_history_services.select(shs_t[:date].minimum, shs_t[:date].maximum)
        service_history_services.connection.select_rows(query.to_sql).first.map { |m| m.try(:to_date) }
      end
    end

    def date_of_first_service
      # service_date_range.first
      processed_service_history.try(:first_date_served)
    end

    def date_of_last_service
      # service_date_range.last
      processed_service_history.try(:last_date_served)
    end

    def date_of_last_homeless_service
      processed_service_history&.last_homeless_date
    end

    def services_for_rollup
      custom_services.
        preload(:warehouse_project, enrollment: [:project, :client], custom_service_type: [:custom_service_category]).
        order(date_provided: :desc).
        order(id: :desc)
    end

    def confidential_project_ids
      @confidential_project_ids ||= Rails.cache.fetch('confidential_project_ids', expires_in: 2.minutes) do
        GrdaWarehouse::Hud::Project.confidential.pluck(:ProjectID, :data_source_id)
      end
    end

    def project_confidential?(project_id:, data_source_id:)
      confidential_project_ids.include?([project_id, data_source_id])
    end

    def last_homeless_visits include_confidential_names: false # rubocop:disable Lint/UnusedMethodArgument
      last_seen_in_type(:homeless, include_confidential_names: false)
    end

    def last_seen_in_type(type, include_confidential_names: false)
      return nil unless type.in?(HudUtility2024.residential_project_type_numbers_by_code.keys + [:homeless])

      service_history_enrollments.ongoing.
        joins(:service_history_services, :project, :organization).
        merge(GrdaWarehouse::Hud::Project.public_send(type)).
        # FIXME confidentialize by organization too
        group(:project_name, p_t[:id], bool_or(p_t[:confidential], o_t[:confidential])).
        maximum("#{GrdaWarehouse::ServiceHistoryService.quoted_table_name}.date").
        map do |(project_name, project_id, confidential), date|
          unless include_confidential_names
            project_name = GrdaWarehouse::Hud::Project.confidential_project_name if confidential
          end
          {
            project_name: project_name,
            date: date,
            project_id: project_id,
          }
        end
    end

    def last_projects_served_by(include_confidential_names: false)
      shs = service_history_services.
        where(date: date_of_last_service).
        joins(:service_history_enrollment)
      return [] unless shs.present?

      shs.map do |sh|
        en = sh.service_history_enrollment
        next unless en

        project_id = en.project_id
        data_source_id = en.data_source_id
        project_name = en.project_name
        confidential = project_confidential?(project_id: project_id, data_source_id: data_source_id)
        if ! confidential || include_confidential_names
          project_name
        else
          GrdaWarehouse::Hud::Project.confidential_project_name
        end
      end.uniq.sort
    end

    def last_intentional_contacts(user, include_confidential_names: false, skip_confidential_projects: false, include_dates: false)
      contacts = processed_service_history&.last_intentional_contacts
      return [] unless contacts.present?

      visible_projects = user.visible_projects_by_id
      visible_project_ids = user.visible_project_ids_enrollment_context
      contacts = JSON.parse(contacts)

      contacts.sort_by { |c| c['date']&.to_date || 5.years.ago }.reverse.map do |contact|
        project_id = contact['project_id']
        next if project_id.present? && !project_id.in?(visible_project_ids)

        project = visible_projects[project_id]
        next if project&.confidential? && skip_confidential_projects

        name = project&.name(ignore_confidential_status: include_confidential_names) || contact['project_name']
        name += ': ' + contact['date']&.to_date.to_s if include_dates
        name
      end.compact.uniq
    end

    def weeks_of_service
      total_days_of_service / 7 rescue 'unknown' # rubocop:disable Style/RescueModifier
    end

    def days_of_service
      processed_service_history.try(:days_served)
    end

    def months_served
      return [] unless date_of_first_service.present?

      [].tap do |i|
        (date_of_first_service.year..date_of_last_service.year).each do |y|
          start_month = if date_of_first_service.year == y then date_of_first_service.month else 1 end
          end_month = if date_of_last_service.year == y then date_of_last_service.month else 12 end
          (start_month..end_month).each do |m|
            i << { start: "#{y}-#{m}-01" }
          end
        end
      end
    end

    def self.without_service_history
      sh  = GrdaWarehouse::WarehouseClientsProcessed
      sht = sh.arel_table
      where(
        sh.where(sht[:client_id].eq arel_table[:id]).arel.exists.not,
      )
    end

    def total_days_of_service
      ((date_of_last_service - date_of_first_service).to_i + 1) rescue 'unknown' # rubocop:disable Style/RescueModifier
    end

    # @param client_scope [GrdaWarehouse::Hud::Client.source] source clients to search in
    # @param sorted [Boolean] order results by closest match to text
    def self.text_search(text, client_scope: nil, sorted: false)
      # Get search results from client scope. Then return the unique destination client records that map to those matching source records
      relation = (client_scope || self)
      # with resolve_for_join_query, results are client.scope.select(:client_id, :score) suitable for subquery
      results = relation.searchable.text_searcher(text, sorted: sorted, resolve_for_join_query: true)
      return relation.none if results.nil?

      grouped = GrdaWarehouse::WarehouseClient.
        # join warehouse client to results subquery
        joins(%(JOIN (#{results.to_sql}) src_search_results ON "warehouse_clients"."source_id" = "src_search_results"."client_id")).
        # group warehouse clients to avoid duplicate results
        select(Arel.sql(%("warehouse_clients"."destination_id" AS client_id, MAX(src_search_results.score) AS score))).
        group(Arel.sql('1'))

      # now join the results, mapped through the WarehouseClient, to the current scope
      mapped = joins(%(JOIN (#{grouped.to_sql}) AS dst_search_results ON dst_search_results.client_id = "Client".id))
      mapped = mapped.order(Arel.sql('dst_search_results.score DESC'), :id) if sorted
      mapped
    end

    # Must match 3 of four First Name, Last Name, SSN, DOB
    # SSN can be full 9 or last 4
    # Names can potentially be switched.
    def self.strict_search(criteria, client_scope: none)
      first_name = criteria[:first_name]&.strip
      last_name = criteria[:last_name]&.strip
      dob = criteria[:dob]&.to_date
      ssn = criteria[:ssn]&.gsub(/[^0-9]/i, '')
      ssn = nil if ssn.present? && ssn.length < 4
      sufficient_criteria = [
        first_name.present?,
        last_name.present?,
        ssn.present?,
        dob.present?,
      ].count(true) >= 3
      return none unless sufficient_criteria

      first_name_ids = []
      last_name_ids = []
      dob_ids = []
      ssn_ids = []

      if first_name.present?
        first_name_ids = source.where(
          nf('LOWER', [arel_table[:FirstName]]).eq(first_name.downcase),
        ).pluck(:id)
      end

      if last_name.present?
        last_name_ids = source.where(
          nf('LOWER', [arel_table[:LastName]]).eq(last_name.downcase),
        ).pluck(:id)
      end

      if dob.present?
        dob_ids = source.where(
          arel_table[:DOB].eq(dob),
        ).pluck(:id)
      end

      if ssn.length == 9
        ssn_ids = source.where(
          arel_table[:SSN].eq(ssn),
        ).pluck(:id)
      elsif ssn.length == 4
        ssn_ids = source.where(
          arel_table[:SSN].matches("%#{ssn}"),
        ).pluck(:id)
      end

      all_ids = first_name_ids + last_name_ids + dob_ids + ssn_ids
      matching_ids = all_ids.each_with_object(Hash.new(0)) { |id, counts| counts[id] += 1 }.select { |_, counts| counts >= 3 }&.keys

      ids = client_scope.
        joins(:warehouse_client_source).searchable.
        where(id: matching_ids).
        preload(:destination_client).
        map { |m| m.destination_client.id }
      where(id: ids)
    end

    def gender
      gender_multi.map { |k| ::HudUtility2024.gender(k) }.join(', ')
    end

    # while the entire warehouse is updated to accept and use the new gender setup, this will provide
    # a single value that roughly represents the client's gender
    def gender_binary
      self.class.gender_binary(self)
    end

    # Accepts a hash containing the gender columns and values
    # Returns a single value that roughly represents the client's gender
    def self.gender_binary(genders)
      return 4 if genders[:NonBinary] == 1
      return 5 if genders[:Transgender] == 1
      return 6 if genders[:Questioning] == 1
      return 4 if [genders[:Woman], genders[:Man], genders[:CulturallySpecific], genders[:DifferentIdentity]].compact.sum > 1
      return 2 if genders[:CulturallySpecific] == 1
      return 3 if genders[:DifferentIdentity] == 1
      return 0 if genders[:Woman] == 1
      return 1 if genders[:Man] == 1

      genders[:GenderNone]
    end

    def self.gender_binary_sql_case
      acase(
        [
          [arel_table[:NonBinary].eq(1), 4],
          [arel_table[:Transgender].eq(1), 5],
          [arel_table[:Questioning].eq(1), 6],
          [(arel_table[:Man] + arel_table[:Woman] + arel_table[:CulturallySpecific] + arel_table[:DifferentIdentity]).gt(1)],
          [arel_table[:Woman].eq(1), 0],
          [arel_table[:Man].eq(1), 1],
        ],
        elsewise: arel_table[:GenderNone],
      )
    end

    def self.age(date:, dob:)
      return nil unless date.present? && dob.present?

      age = date.year - dob.year
      age -= 1 if dob > date.years_ago(age)
      age
    end

    def age(date = Date.current)
      return unless attributes['DOB'].present? && date.present?

      date = date.to_date
      dob = attributes['DOB'].to_date
      self.class.age(date: date, dob: dob)
    end
    alias age_on age

    def youth_on?(date = Date.current)
      (18..24).cover?(age(date))
    end

    def uuid
      @uuid ||= if data_source&.munged_personal_id
        self.PersonalID.split(/(\w{8})(\w{4})(\w{4})(\w{4})(\w{12})/).reject do |c|
          c.empty? || c == '__#'
        end.join('-')
      else
        self.PersonalID
      end
    end

    def self.uuid(personal_id)
      personal_id.split(/(\w{8})(\w{4})(\w{4})(\w{4})(\w{12})/).reject do |c|
        c.empty? || c == '__#'
      end.join('-')
    end

    def ever_veteran?
      va_verified_veteran? || source_clients.map(&:veteran?).include?(true)
    end

    def adjust_veteran_status
      self.VeteranStatus = calculate_best_veteran_status(verified_veteran_status, va_verified_veteran, source_clients)
      save
      self.class.clear_view_cache(self.id) # rubocop:disable Style/RedundantSelf
    end

    def race_description(include_missing_reason: false)
      description = race_fields.map { |f| ::HudUtility2024.race f }.join ', '
      return description if description.present?
      return '' unless include_missing_reason
      return '' unless self.RaceNone.in?(HudUtility2024.race_gender_none_options.keys)

      HudUtility2024.race_none(self.RaceNone)
    end

    def pit_gender
      gm = gender_multi.map { |k| ::HudUtility2024.gender(k) }
      return 'GenderNone' if gm.count.zero?
      return 'More Than One Gender' if gm.count > 1

      return HudUtility2024.gender(gm.first)
    end

    def pit_race
      return 'RaceNone' if race_fields.count.zero?

      race_fields_minus_latin = race_fields.reject { |x| x.include?('HispanicLatinaeo') }

      return 'Hispanic/Latina/e/o (only)' if race_fields_minus_latin.count.zero? && race_fields.include?('HispanicLatinaeo')

      # if the race fields didn't include latinx add "only", otherwise note that the client also falls into the latinx category
      suffix = race_fields == race_fields_minus_latin ? ' (only)' : ' & Hispanic/Latina/e/o'
      # if latinx wasn't one of the races, and there were more than two races, the client will be in the multi-racial category
      suffix = ' (all other)' if race_fields == race_fields_minus_latin && race_fields_minus_latin.count > 1

      return 'Multi-Racial' + suffix if race_fields_minus_latin.count > 1

      return HudUtility2024.race(race_fields_minus_latin.first) + suffix
    end

    # call this on GrdaWarehouse::Hud::Client.new() instead of self, to take
    # advantage of caching
    def race_string(destination_id:, include_none_reason: false, scope_limit: self.class.destination)
      @limited_scope ||= self.class.destination.merge(scope_limit)

      @race_am_ind_ak_native ||= @limited_scope.where(id: self.class.race_am_ind_ak_native.select(:id)).distinct.pluck(:id).to_set
      @race_asian ||= @limited_scope.where(id: self.class.race_asian.select(:id)).distinct.pluck(:id).to_set
      @race_black_af_american ||= @limited_scope.where(id: self.class.race_black_af_american.select(:id)).distinct.pluck(:id).to_set
      @race_native_hi_other_pacific ||= @limited_scope.where(id: self.class.race_native_hi_other_pacific.select(:id)).distinct.pluck(:id).to_set
      @race_white ||= @limited_scope.where(id: self.class.race_white.select(:id)).distinct.pluck(:id).to_set
      @race_hispanic_latinaeo ||= @limited_scope.where(id: self.class.race_hispanic_latinaeo.select(:id)).distinct.pluck(:id).to_set
      @race_mid_east_n_african ||= @limited_scope.where(id: self.class.race_mid_east_n_african.select(:id)).distinct.pluck(:id).to_set
      @multiracial ||= begin
        multi = @race_am_ind_ak_native.to_a +
        @race_asian.to_a +
        @race_black_af_american.to_a +
        @race_native_hi_other_pacific.to_a +
        @race_white.to_a +
        @race_hispanic_latinaeo.to_a +
        @race_mid_east_n_african.to_a

        multi.duplicates.to_set
      end

      return 'MultiRacial' if @multiracial.include?(destination_id)
      return 'AmIndAKNative' if @race_am_ind_ak_native.include?(destination_id)
      return 'Asian' if @race_asian.include?(destination_id)
      return 'BlackAfAmerican' if @race_black_af_american.include?(destination_id)

      return 'NativeHIPacific' if @race_native_hi_other_pacific.include?(destination_id)
      return 'White' if @race_white.include?(destination_id)
      return 'HispanicLatinaeo' if @race_hispanic_latinaeo.include?(destination_id)
      return 'MidEastNAfrican' if @race_mid_east_n_african.include?(destination_id)

      if include_none_reason
        @doesnt_know ||= @limited_scope.where(id: self.class.race_doesnt_know.select(:id)).distinct.pluck(:id).to_set
        @refused ||= @limited_scope.where(id: self.class.race_refused.select(:id)).distinct.pluck(:id).to_set

        return 'Does Not Know' if @doesnt_know.include?(destination_id)
        return 'Refused' if @refused.include?(destination_id)

        return 'Not Collected'
      end
      'RaceNone'
    end

    def cas_race_am_ind_ak_native
      self.AmIndAKNative == 1
    end

    def cas_race_asian
      self.Asian == 1
    end

    def cas_race_black_af_american
      self.BlackAfAmerican == 1
    end

    def cas_race_native_hi_pacific
      self.NativeHIPacific == 1
    end

    def cas_race_white
      self.White == 1
    end

    def cas_race_hispanic_latinaeo
      self.HispanicLatinaeo == 1
    end

    def cas_race_mid_east_n_african
      self.MidEastNAfrican == 1
    end

    def cas_gender_woman
      self.Woman == 1
    end

    def cas_gender_female
      cas_gender_woman
    end

    def cas_gender_man
      self.Man == 1
    end

    def cas_gender_male
      cas_gender_man
    end

    def cas_gender_no_single_gender
      self.NonBinary == 1
    end

    def cas_gender_transgender
      self.Transgender == 1
    end

    def cas_gender_questioning
      self.Questioning == 1
    end

    def self_and_sources
      if destination?
        [self, *self.source_clients] # rubocop:disable Style/RedundantSelf
      else
        [self]
      end
    end

    def primary_caseworkers
      staff.merge(GrdaWarehouse::Hmis::StaffXClient.primary_caseworker)
    end

    # convert all clients to the appropriate destination client
    def normalize_to_destination
      if destination?
        self
      else
        self.destination_client # rubocop:disable Style/RedundantSelf
      end
    end

    def previous_permanent_locations
      source_enrollments.any_address.sort_by(&:EntryDate).map(&:address_lat_lon).uniq
    end

    def previous_permanent_locations_for_display(user)
      labels = ('A'..'Z').to_a
      seen_addresses = {}
      addresses_from_enrollments = source_enrollments.visible_to(user, client_ids: source_client_ids).
        any_address.
        order(EntryDate: :desc).
        preload(:client).map do |enrollment|
          lat_lon = enrollment.address_lat_lon # rubocop:disable Layout/IndentationWidth
          address = {
            year: enrollment.EntryDate.year,
            client_id: enrollment.client&.id,
            label: seen_addresses[enrollment.address] ||= labels.shift,
            city: enrollment.LastPermanentCity,
            state: enrollment.LastPermanentState,
            zip: enrollment.LastPermanentZIP.try(:rjust, 5, '0'),
          }
          address.merge!(lat_lon) if lat_lon.present?
          address
      end

      addresses_from_hmis_clients = source_hmis_clients.map do |hmis_client|
        lat_lon = hmis_client.address_lat_lon
        next unless lat_lon.present?

        address = {
          year: 'Unknown',
          client_id: hmis_client.client_id,
          label: seen_addresses[hmis_client.last_permanent_zip] ||= labels.shift,
          city: '',
          state: '',
          zip: hmis_client.last_permanent_zip.try(:rjust, 5, '0'),
        }
        address.merge!(lat_lon)
        address
      end.compact
      Array.wrap(addresses_from_enrollments) + Array.wrap(addresses_from_hmis_clients)
    end

    # takes an array of tags representing the types of documents needed to be document ready
    # returns an array of hashes representing the state of each required document
    def document_readiness(required_documents)
      return [] unless required_documents.any?

      @document_readiness ||= begin
        @document_readiness = []
        required_documents.each do |tag|
          next unless tag.required_by?(self)

          file_added = client_files.tagged_with(tag.name).maximum(:updated_at)
          file = OpenStruct.new(
            {
              updated_at: file_added,
              available: file_added.present?,
              name: tag.name,
            },
          )
          @document_readiness << file
        end
        @document_readiness.sort_by!(&:name)
      end
    end

    def document_ready?(required_documents)
      @document_ready ||= document_readiness(required_documents).all?(&:available)
    end

    # Build a set of potential client matches grouped by criteria
    # FIXME: consolidate this logic with merge_candidates below
    def potential_matches
      @potential_matches ||= {}.tap do |m|
        c_arel = self.class.arel_table
        # Find anyone with a nickname match
        nicks = Nickname.for(self.FirstName).map(&:name)

        if nicks.any?
          nicks_for_search = nicks.map { |m| GrdaWarehouse::Hud::Client.connection.quote(m) }.join(',') # rubocop:disable Lint/ShadowingOuterLocalVariable
          similar_destinations = self.class.destination.where(
            nf('LOWER', [c_arel[:FirstName]]).in(nicks_for_search),
          ).where(c_arel['LastName'].matches("%#{self.LastName.downcase}%")).
            where.not(id: self.id) # rubocop:disable Style/RedundantSelf
          m[:by_nickname] = similar_destinations if similar_destinations.any?
        end
        # Find anyone with similar sounding names
        alt_first_names = UniqueName.where(double_metaphone: Text::Metaphone.double_metaphone(self.FirstName).to_s).map(&:name)
        alt_last_names = UniqueName.where(double_metaphone: Text::Metaphone.double_metaphone(self.LastName).to_s).map(&:name)
        alt_names = alt_first_names + alt_last_names
        if alt_names.any?
          alt_names_for_search = alt_names.map { |m| GrdaWarehouse::Hud::Client.connection.quote(m) }.join(',') # rubocop:disable Lint/ShadowingOuterLocalVariable
          similar_destinations = self.class.destination.where(
            nf('LOWER', [c_arel[:FirstName]]).in(alt_names_for_search).
              and(nf('LOWER', [c_arel[:LastName]]).matches("#{self.LastName.downcase}%")).
            or(nf('LOWER', [c_arel[:LastName]]).in(alt_names_for_search).
              and(nf('LOWER', [c_arel[:FirstName]]).matches("#{self.FirstName.downcase}%"))),
          ).where.not(id: self.id) # rubocop:disable Style/RedundantSelf
          m[:where_the_name_sounds_similar] = similar_destinations if similar_destinations.any?
        end
        # Find anyone with similar sounding names
        # similar_destinations = self.class.where(id: GrdaWarehouse::WarehouseClient.where(source_id:  self.class.source.where("difference(?, FirstName) > 1", self.FirstName).where('LastName': self.class.source.where('soundex(LastName) = soundex(?)', self.LastName).select('LastName')).where.not(id: source_clients.pluck(:id)).pluck(:id)).pluck(:destination_id))
        # m[:where_the_name_sounds_similar] = similar_destinations if similar_destinations.any?
      end

      # TODO
      # Soundex on names
      # William/Bill/Will

      # Others
    end

    # find other clients with similar names
    def merge_candidates(scope = self.class.source)
      # skip self and anyone already known to be related
      scope = scope.where.not(id: source_clients.map(&:id) + [id, destination_client.try(&:id)])

      # some convenience stuff to clean the code up
      at = self.class.arel_table

      diff_full = nf(
        'DIFFERENCE', [
          ct(cl(at[:FirstName], ''), cl(at[:MiddleName], ''), cl(at[:LastName], '')),
          name,
        ],
        'diff_full'
      )
      diff_last  = nf('DIFFERENCE', [cl(at[:LastName], ''), last_name || ''], 'diff_last')
      diff_first = nf('DIFFERENCE', [cl(at[:LastName], ''), first_name || ''], 'diff_first')

      # return a scope return clients plus their "difference" from this client
      scope.select(Arel.star, diff_full, diff_first, diff_last).order('diff_full DESC, diff_last DESC, diff_first DESC')
    end

    def split(client_ids, hmis_receiver_id, health_receiver_id, current_user)
      client_names = []
      dnd_warehouse_data_source = GrdaWarehouse::DataSource.destination.first

      GrdaWarehouse::Hud::Base.transaction do
        client_ids.each do |client_id|
          c = self.class.find(client_id)
          c.warehouse_client_source.destroy if c.warehouse_client_source.present?
          destination_client = c.dup
          destination_client.data_source = dnd_warehouse_data_source
          destination_client.save

          receive_hmis = hmis_receiver_id == client_id
          receive_health = health_receiver_id == client_id

          GrdaWarehouse::ClientSplitHistory.create(
            split_from: id,
            split_into: destination_client.id,
            receive_hmis: receive_hmis,
            receive_health: receive_health,
          )

          GrdaWarehouse::WarehouseClient.create(
            id_in_source: c.PersonalID,
            source_id: c.id,
            destination_id: destination_client.id,
            data_source_id: c.data_source_id,
            proposed_at: Time.now,
            reviewed_at: Time.now,
            reviewd_by: current_user.id,
            approved_at: Time.now,
          )

          destination_client.move_dependent_hmis_items(id, destination_client.id) if receive_hmis
          destination_client.move_dependent_health_items(id, destination_client.id) if receive_health

          client_names << c.full_name
        end
      end

      client_names
    end

    # Move source clients to this destination client
    # other_client can be a single source record or a destination record
    # if it's a destination record, all of its sources will move and it will be deleted
    #
    # returns the source client records that moved
    def merge_from(other_client, reviewed_by:, reviewed_at:, client_match_id: nil)
      raise 'only works for destination_clients' unless self.destination? # rubocop:disable Style/RedundantSelf

      setup_notifier('PatientMerger') unless @notifier
      moved = []
      transaction do
        # get the existing destination client for other_client
        prev_destination_client = if other_client.destination_client
          other_client.destination_client
        elsif other_client.destination?
          other_client
        end
        # if it had sources then move those over to us
        # and say who made the decision and when
        other_client.source_clients.each do |m|
          m.warehouse_client_source.update!(
            destination_id: self.id, # rubocop:disable Style/RedundantSelf
            reviewed_at: reviewed_at,
            reviewd_by: reviewed_by.id,
            client_match_id: client_match_id,
          )
          moved << m
        end
        # if we are a source, move us
        if other_client.warehouse_client_source
          other_client.warehouse_client_source.update!(
            destination_id: self.id, # rubocop:disable Style/RedundantSelf
            reviewed_at: reviewed_at,
            reviewd_by: reviewed_by.id,
            client_match_id: client_match_id,
          )
          moved << other_client
        end
        # clean up the previous destination
        if prev_destination_client
          # move any CAS column data
          previous_cas_columns = prev_destination_client.attributes.slice(*self.class.cas_columns.keys.map(&:to_s))
          current_cas_columns = self.attributes.slice(*self.class.cas_columns.keys.map(&:to_s)) # rubocop:disable Style/RedundantSelf
          current_cas_columns.merge!(previous_cas_columns) { |_k, old, new| old.presence || new }
          self.update(current_cas_columns) # rubocop:disable Style/RedundantSelf
          self.save # rubocop:disable Style/RedundantSelf

          prev_destination_client.force_full_service_history_rebuild
          prev_destination_client.source_clients.reload
          if prev_destination_client.source_clients.empty?
            # Create a client_merge_history record so we can keep links working
            GrdaWarehouse::ClientMergeHistory.create(merged_into: id, merged_from: prev_destination_client.id)
            prev_destination_client.delete
          end

          move_dependent_items(prev_destination_client.id, self.id) # rubocop:disable Style/RedundantSelf
        end
        # and invalidate our own service history
        force_full_service_history_rebuild
        # and invalidate any cache for these clients
        self.class.clear_view_cache(prev_destination_client.id) if prev_destination_client.present?
      end
      self.class.clear_view_cache(self.id) # rubocop:disable Style/RedundantSelf
      self.class.clear_view_cache(other_client.id)
      # un-match anyone who we just moved so they don't show up in the matching again until they've been checked
      moved.each do |m|
        GrdaWarehouse::ClientMatch.processed_or_candidate.
          where(source_client_id: m.id).destroy_all
        GrdaWarehouse::ClientMatch.processed_or_candidate.
          where(destination_client_id: m.id).destroy_all
      end
      moved
    rescue Health::MedicaidIdConflict => e
      @notifier.ping(
        'Non-matching Medicaid IDs on patient merge',
        {
          exception: e,
        },
      )
    end

    def move_dependent_hmis_items(previous_id, new_id)
      return if previous_id == new_id

      hmis_dependent_items.each do |klass|
        klass.where(client_id: previous_id).
          update_all(client_id: new_id)
      end
    end

    def move_dependent_health_items(previous_id, new_id)
      return if previous_id == new_id

      # If we are merging 2 existing patients...
      previous_patient = Health::Patient.find_by(client_id: previous_id)
      new_patient = Health::Patient.find_by(client_id: new_id)
      if previous_patient.present? && new_patient.present?
        # Confirm their MedicaidIDs match
        raise Health::MedicaidIdConflict, "Cannot merge #{previous_patient.id} and #{new_patient.id}" if previous_patient.medicaid_id != new_patient.medicaid_id

        # Move the referrals
        previous_patient.patient_referrals.update_all(patient_id: new_patient.id)
        new_patient.cleanup_referrals

        # There can only be one patient with an client_id, so clean up the old one
        previous_patient.destroy
      end

      health_dependent_items.each do |klass|
        klass.where(client_id: previous_id).
          update_all(client_id: new_id)
      end
    end

    def move_dependent_items previous_id, new_id
      move_dependent_hmis_items(previous_id, new_id)
      move_dependent_health_items(previous_id, new_id)
    end

    private def hmis_dependent_items
      [
        GrdaWarehouse::ClientNotes::Base,
        GrdaWarehouse::ClientFile,
        GrdaWarehouse::Vispdat::Base,
        GrdaWarehouse::CohortClient,
        GrdaWarehouse::Chronic,
        GrdaWarehouse::HudChronic,
        GrdaWarehouse::UserClient,
        GrdaWarehouse::EnrollmentChangeHistory,
        GrdaWarehouse::CasAvailability,
        GrdaWarehouse::YouthIntake::Base,
        GrdaWarehouse::Youth::DirectFinancialAssistance,
        GrdaWarehouse::Youth::YouthCaseManagement,
        GrdaWarehouse::Youth::YouthReferral,
        GrdaWarehouse::Youth::YouthFollowUp,
        GrdaWarehouse::HealthEmergency::AmaRestriction,
        GrdaWarehouse::HealthEmergency::Test,
        GrdaWarehouse::HealthEmergency::ClinicalTriage,
        GrdaWarehouse::HealthEmergency::Isolation,
        GrdaWarehouse::HealthEmergency::Quarantine,
        GrdaWarehouse::HealthEmergency::UploadedTest,
        GrdaWarehouse::HealthEmergency::Vaccination,
        GrdaWarehouse::Anomaly,
      ]
    end

    private def health_dependent_items
      items = [
        Health::Patient,
        Health::HealthFile,
        Health::Tracing::Case,
        Health::Vaccination,
      ]
      items << HealthFlexibleService::Vpr if RailsDrivers.loaded.include?(:health_flexible_service)

      items
    end

    def force_full_service_history_rebuild
      # If we're already forcing a rebuild, we don't need to clear things again
      self.class.with_advisory_lock([__method__, self.class.name, id].join('_'), timeout_seconds: 0) do
        service_history_enrollments.where(record_type: [:entry, :exit, :service, :extrapolated]).delete_all
        source_enrollments.update_all(processed_as: nil)
        invalidate_service_history
      end
    end

    def self.clear_view_cache(id)
      return if Rails.env.test?

      Rails.cache.delete_matched("*clients/#{id}/*")
    end

    def clear_view_cache
      self.class.clear_view_cache(id)
    end

    def most_recent_vispdat
      return if cas_calculator_instance.unrelated_columns.include?(:vispdat_score)

      vispdats.completed.first
    end

    # Fetch most recent VI-SPDAT from the warehouse,
    # if not available use the most recent ETO VI-SPDAT
    # The ETO VI-SPDAT are prioritized by max score on the most recent assessment
    # NOTE: if we have more than one VI-SPDAT on the same day, the calculation is complicated
    def most_recent_vispdat_score
      return if cas_calculator_instance.unrelated_columns.include?(:vispdat_score)

      vispdats.completed.scores.first&.score ||
        source_hmis_forms.vispdat.newest_first.
          pluck(
            :collected_at,
            :vispdat_total_score,
            :vispdat_youth_score,
            :vispdat_family_score,
          )&.
          group_by(&:first)&.
          first&.
          last&.
          map { |m| m.drop(1) }&.
          flatten&.
          compact&.
          max
    end

    # NOTE: if we have more than one VI-SPDAT on the same day, the calculation is complicated
    def most_recent_vispdat_length_homeless_in_days
      return if cas_calculator_instance.unrelated_columns.include?(:vispdat_score)

      vispdats.completed.order(submitted_at: :desc).limit(1).first&.days_homeless ||
        source_hmis_forms.vispdat.newest_first.
          map { |m| [m.collected_at, m.vispdat_days_homeless] }&.
          group_by(&:first)&.
          first&.
          last&.
          map { |m| m.drop(1) }&.
          flatten&.
          compact&.
          max || 0
    rescue # rubocop:disable Style/RescueStandardError
      0
    end

    # Determine which vi-spdat to use based on dates
    def most_recent_vispdat_object
      return if cas_calculator_instance.unrelated_columns.include?(:vispdat_score)

      internal = most_recent_vispdat
      external = source_hmis_forms.vispdat.newest_first.first
      vispdats = []
      vispdats << [internal.submitted_at, internal] if internal
      vispdats << [external.collected_at, external] if external
      # return the newest vispdat
      vispdats.sort_by(&:first)&.last&.last
    end

    def most_recent_vispdat_family_vispdat?
      return if cas_calculator_instance.unrelated_columns.include?(:vispdat_score)

      # From local warehouse VI-SPDAT
      return most_recent_vispdat_object.family? if most_recent_vispdat_object.respond_to?(:family?)

      # From ETO VI-SPDAT, this is pre-calculated GrdaWarehouse::HmisForm.set_part_of_a_family
      return family_member
    end

    def calculate_vispdat_priority_score
      return if cas_calculator_instance.unrelated_columns.include?(:vispdat_score)

      vispdat_score = most_recent_vispdat_score
      return nil unless vispdat_score.present?

      if GrdaWarehouse::Config.get(:vispdat_prioritization_scheme) == 'veteran_status'
        prioritization_bump = 0
        prioritization_bump += 100 if veteran?
        vispdat_score + prioritization_bump
      elsif GrdaWarehouse::Config.get(:vispdat_prioritization_scheme) == 'vets_family_youth'
        prioritization_bump = 0
        prioritization_bump += 100 if veteran?
        prioritization_bump += 50 if most_recent_vispdat_family_vispdat?
        prioritization_bump += 25 if youth_on?

        vispdat_score + prioritization_bump
      else # Default GrdaWarehouse::Config.get(:vispdat_prioritization_scheme) == 'length_of_time'
        vispdat_length_homeless_in_days = days_homeless_for_vispdat_prioritization || 0
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

    def self.days_homeless_in_last_three_years(client_id:, on_date: Date.current)
      dates_homeless_in_last_three_years_scope(client_id: client_id, on_date: on_date).count
    end

    def days_homeless_in_last_three_years(on_date: Date.current)
      self.class.days_homeless_in_last_three_years(client_id: id, on_date: on_date)
    end

    def max_days_homeless_in_last_three_years(on_date: Date.current) # rubocop:disable Lint/UnusedMethodArgument
      days = [days_homeless_in_last_three_years(on_date: Date.current)]
      days += cohort_clients.where(cohort_id: active_cohort_ids).where.not(adjusted_days_homeless_last_three_years: nil).
        pluck(:adjusted_days_homeless_last_three_years)
      days.compact.max
    end

    def self.literally_homeless_last_three_years(client_id:, on_date: Date.current)
      dates_literally_homeless_in_last_three_years_scope(client_id: client_id, on_date: on_date).count
    end

    def literally_homeless_last_three_years(on_date: Date.current)
      self.class.literally_homeless_last_three_years(client_id: id, on_date: on_date)
    end

    def max_literally_homeless_last_three_years(on_date: Date.current) # rubocop:disable Lint/UnusedMethodArgument
      days = [literally_homeless_last_three_years(on_date: Date.current)]
      days += cohort_clients.where(cohort_id: active_cohort_ids).where.not(adjusted_days_literally_homeless_last_three_years: nil).
        pluck(:adjusted_days_literally_homeless_last_three_years)
      days.compact.max
    end

    def self.dates_homeless_scope client_id:, on_date: Date.current
      GrdaWarehouse::ServiceHistoryService.where(client_id: client_id).
        homeless.
        where(shs_t[:date].lteq(on_date)).
        where.not(date: dates_housed_scope(client_id: client_id)).
        select(:date).distinct
    end

    # ES, SO, SH, or TH with no overlapping PH
    def self.dates_homeless_in_last_three_years_scope client_id:, on_date: Date.current
      Rails.cache.fetch([client_id, 'dates_homeless_in_last_three_years_scope', on_date], expires_in: CACHE_EXPIRY) do
        end_date = on_date.to_date
        start_date = end_date - 3.years
        GrdaWarehouse::ServiceHistoryService.where(client_id: client_id).
          homeless.
          where(date: start_date..end_date).
          where.not(date: dates_in_ph_last_three_years_scope(client_id: client_id, on_date: on_date)).
          select(:date).distinct
      end
    end

    # ES, SO, or SH with no overlapping TH or PH
    def self.dates_literally_homeless_in_last_three_years_scope client_id:, on_date: Date.current
      Rails.cache.fetch([client_id, 'dates_literally_homeless_in_last_three_years_scope', on_date], expires_in: CACHE_EXPIRY) do
        end_date = on_date.to_date
        start_date = end_date - 3.years
        GrdaWarehouse::ServiceHistoryService.where(client_id: client_id).
          literally_homeless.
          where(date: start_date..end_date).
          where.not(date: dates_hud_non_chronic_residential_last_three_years_scope(client_id: client_id)).
          select(:date).distinct
      end
    end

    # ES, SO, SH, or TH with no overlapping PH
    def self.dates_homeless_in_last_year_scope client_id:, on_date: Date.current
      Rails.cache.fetch([client_id, 'dates_homeless_in_last_year_scope', on_date], expires_in: CACHE_EXPIRY) do
        end_date = on_date.to_date
        start_date = end_date - 1.years
        GrdaWarehouse::ServiceHistoryService.where(client_id: client_id).
          homeless.
          where(date: start_date..end_date).
          where.not(date: dates_in_ph_last_three_years_scope(client_id: client_id, on_date: on_date)).
          select(:date).distinct
      end
    end

    # ES, SO, or SH with no overlapping TH or PH
    def self.dates_literally_homeless_in_last_year_scope client_id:, on_date: Date.current
      Rails.cache.fetch([client_id, 'dates_literally_homeless_in_last_year_scope', on_date], expires_in: CACHE_EXPIRY) do
        end_date = on_date.to_date
        start_date = end_date - 1.years
        GrdaWarehouse::ServiceHistoryService.where(client_id: client_id).
          homeless.
          where(date: start_date..end_date).
          where.not(date: dates_hud_non_chronic_residential_last_three_years_scope(client_id: client_id)).
          select(:date).distinct
      end
    end

    def sheltered_days_homeless_last_three_years
      end_date = Date.current
      start_date = end_date - 3.years
      sheltered_homeless_dates(start_date: start_date, end_date: end_date).count
    end

    def sheltered_homeless_dates(start_date:, end_date:)
      service_history_services.
        homeless_sheltered.
        where(date: start_date..end_date).
        where.not(date: service_history_services.non_homeless.where(date: start_date..end_date).select(:date).distinct).
        select(:date).
        distinct
    end

    def unsheltered_days_homeless_last_three_years
      end_date = Date.current
      start_date = end_date - 3.years
      service_history_services.
        homeless_unsheltered.
        where(date: start_date..end_date).
        where.not(date: service_history_services.non_homeless.where(date: start_date..end_date).select(:date).distinct).
        where.not(date: sheltered_homeless_dates(start_date: start_date, end_date: end_date)).
        select(:date).
        distinct.
        count
    end

    # TH or PH
    def self.dates_hud_non_chronic_residential_last_three_years_scope client_id:, on_date: Date.current
      end_date = on_date.to_date
      start_date = end_date - 3.years

      dates_hud_non_chronic_residential_scope(client_id: client_id).
        where(date: start_date..end_date)
    end

    # TH or PH
    def self.dates_hud_non_chronic_residential_scope client_id:
      GrdaWarehouse::ServiceHistoryService.non_literally_homeless.
        where(client_id: client_id).
        select(:date).distinct
    end

    # PH
    def self.dates_in_ph_last_three_years_scope client_id:, on_date:
      end_date = on_date.to_date
      start_date = end_date - 3.years

      dates_in_ph_residential_scope(client_id: client_id).
        where(date: start_date..end_date)
    end

    # PH
    def self.dates_in_ph_residential_scope client_id:
      GrdaWarehouse::ServiceHistoryService.non_homeless.
        where(client_id: client_id).
        select(:date).distinct
    end

    def homeless_months_in_last_three_years(on_date: Date.current)
      self.class.dates_homeless_in_last_three_years_scope(client_id: id, on_date: on_date).
        pluck(:date).
        map { |date| [date.month, date.year] }.uniq
    end

    def months_homeless_in_last_three_years(on_date: Date.current)
      homeless_months_in_last_three_years(on_date: on_date).count
    end

    def homeless_months_in_last_year(on_date: Date.current)
      self.class.dates_homeless_in_last_year_scope(client_id: id, on_date: on_date).
        pluck(:date).
        map { |date| [date.month, date.year] }.uniq
    end

    def months_homeless_in_last_year(on_date: Date.current)
      homeless_months_in_last_year(on_date: on_date).count
    end

    def literally_homeless_months_in_last_three_years(on_date: Date.current)
      self.class.dates_literally_homeless_in_last_three_years_scope(client_id: id, on_date: on_date).
        pluck(:date).
        map { |date| [date.month, date.year] }.uniq
    end

    def months_literally_homeless_in_last_three_years(on_date: Date.current)
      literally_homeless_months_in_last_three_years(on_date: on_date).count
    end

    def literally_homeless_months_in_last_year(on_date: Date.current)
      self.class.dates_literally_homeless_in_last_year_scope(client_id: id, on_date: on_date).
        pluck(:date).
        map { |date| [date.month, date.year] }.uniq
    end

    def months_literally_homeless_in_last_year(on_date: Date.current)
      literally_homeless_months_in_last_year(on_date: on_date).count
    end

    def self.dates_housed_scope(client_id:, on_date: Date.current) # rubocop:disable Lint/UnusedMethodArgument
      GrdaWarehouse::ServiceHistoryService.non_homeless.
        where(client_id: client_id).select(:date).distinct
    end

    def self.dates_homeless(client_id:, on_date: Date.current)
      Rails.cache.fetch([client_id, 'dates_homeless', on_date], expires_in: CACHE_EXPIRY) do
        dates_homeless_scope(client_id: client_id, on_date: on_date).pluck(:date)
      end
    end

    def self.days_homeless(client_id:, on_date: Date.current)
      Rails.cache.fetch([client_id, 'days_homeless', on_date], expires_in: CACHE_EXPIRY) do
        dates_homeless_scope(client_id: client_id, on_date: on_date).count
      end
    end

    def days_homeless(on_date: Date.current)
      # attempt to pull this from previously calculated data
      processed_service_history&.homeless_days&.presence || self.class.days_homeless(client_id: id, on_date: on_date)
    end

    def max_days_homeless(on_date: Date.current) # rubocop:disable Lint/UnusedMethodArgument
      days = [days_homeless(on_date: Date.current)]
      days += cohort_clients.where(cohort_id: active_cohort_ids).where.not(adjusted_days_homeless: nil).
        pluck(:adjusted_days_homeless)
      days.compact.max
    end

    def homeless_dates_for_chronic_in_past_three_years(date: Date.current)
      GrdaWarehouse::Tasks::ChronicallyHomeless.new(
        date: date.to_date,
        dry_run: true,
        client_ids: [id],
      ).residential_history_for_client(client_id: id)
    end

    # NOTE: if you are calculating these in batches, you should pass in arrays of enrollments and chronic enrollments
    def homeless_episodes_between start_date:, end_date:, residential_enrollments: nil, chronic_enrollments: nil
      residential_enrollments ||= service_history_enrollments.residential.entry.order(first_date_in_program: :asc)
      return 0 unless residential_enrollments.any?

      chronic_enrollments ||= service_history_enrollments.entry.
        open_between(start_date: start_date, end_date: end_date).
        hud_homeless(chronic_types_only: true).
        order(first_date_in_program: :asc).to_a
      return 0 unless chronic_enrollments.any?

      # Need to add one to the count of new episodes if the first enrollment in
      # chronic_enrollments doesn't count as a new episode.
      # It is equivalent to always count that first enrollment
      # and then ignore it for the calculation
      episode_count = 1
      chronic_enrollments.drop(1).map do |enrollment|
        new_episode?(enrollments: residential_enrollments, enrollment: enrollment)
      end.count(true) + episode_count
    end

    def length_of_episodes start_date:, end_date:, residential_enrollments: nil, chronic_enrollments: nil
      residential_enrollments ||= service_history_enrollments.residential.entry.order(first_date_in_program: :asc)
      return [] unless residential_enrollments.any?

      chronic_enrollments ||= service_history_enrollments.entry.
        open_between(start_date: start_date, end_date: end_date).
        hud_homeless(chronic_types_only: true).
        order(first_date_in_program: :asc, last_date_in_program: :asc).to_a
      return [] unless chronic_enrollments.any?

      episodes = []
      initial_chronic_enrollment = chronic_enrollments.first
      current_start = initial_chronic_enrollment.first_date_in_program
      chronic_enrollments.drop(1).map do |enrollment|
        if new_episode?(enrollments: residential_enrollments, enrollment: enrollment) # rubocop:disable Style/Next
          days_served = chronic_enrollments.
            select do |e|
              e.last_date_in_program.blank? ||
              e.last_date_in_program < enrollment.first_date_in_program
            end.map do |e|
              e.service_history_services.map(&:date)
            end.flatten.compact
          current_end = days_served.max
          # current_end = chronic_enrollments.
          #   select do |e|
          #     e.last_date_in_program.present? && e.last_date_in_program < enrollment.first_date_in_program
          #   end.
          #   map(&:last_date_in_program).
          #   max
          current_end = [current_end, end_date].compact.min
          episodes << {
            start_date: current_start,
            end_date: current_end,
            days: days_served.count,
            months: (current_start..current_end).map(&:month).uniq.count,
          }
          current_start = enrollment.first_date_in_program
        end
      end
      final_chronic_enrollment = chronic_enrollments.last
      days_served = final_chronic_enrollment.service_history_services.map(&:date)
      current_end = [days_served.max, end_date].compact.min
      episodes << {
        start_date: current_start,
        end_date: current_end,
        days: days_served.count,
        months: (current_start..current_end).map(&:month).uniq.count,
      }
      episodes
    end

    def self.service_types
      @service_types ||= begin
        service_types = ['service']
        service_types << 'extrapolated' if GrdaWarehouse::Config.get(:so_day_as_month)
        service_types
      end
    end

    def service_types
      self.class.service_types
    end

    def total_days enrollments
      enrollments.map { |m| m[:days] }.sum
    end

    def total_homeless enrollments
      enrollments.select do |enrollment|
        enrollment[:homeless]
      end.map { |m| m[:homeless_days] }.sum
    end

    def total_adjusted_days enrollments
      enrollments.map { |m| m[:adjusted_days] }.sum
    end

    def total_months enrollments
      enrollments.map { |e| e[:months_served] }.flatten(1).uniq.size
    end

    private def affiliated_residential_projects(enrollment, user)
      @residential_affiliations ||= GrdaWarehouse::Hud::Affiliation.preload(:project, :residential_project).map do |affiliation|
        [
          [affiliation.project&.ProjectID, affiliation.project&.data_source_id],
          affiliation.residential_project&.name(user),
        ]
      end.group_by(&:first)
      @residential_affiliations[[enrollment[:ProjectID], enrollment[:data_source_id]]].map(&:last) rescue [] # rubocop:disable Style/RescueModifier
    end

    private def affiliated_projects(enrollment, user)
      @project_affiliations ||= GrdaWarehouse::Hud::Affiliation.preload(:project, :residential_project).
        map do |affiliation|
        [
          [affiliation.residential_project&.ProjectID, affiliation.residential_project&.data_source_id],
          affiliation.project&.name(user),
        ]
      end.group_by(&:first)
      @project_affiliations[[enrollment[:ProjectID], enrollment[:data_source_id]]].map(&:last) rescue [] # rubocop:disable Style/RescueModifier
    end

    private def affiliated_projects_str_for_enrollment(enrollment, user)
      project_names = affiliated_projects(enrollment, user)
      return nil unless project_names.any?

      "Affiliated with #{project_names.to_sentence}"
    end

    private def residential_projects_str_for_enrollment(enrollment, user)
      project_names = affiliated_residential_projects(enrollment, user)
      return nil unless project_names.any?

      "Affiliated with #{project_names.to_sentence}"
    end

    def program_tooltip_data_for_enrollment(enrollment, user)
      affiliated_projects_str = affiliated_projects_str_for_enrollment(enrollment, user)
      residential_projects_str = residential_projects_str_for_enrollment(enrollment, user)
      # only show tooltip if there are projects to list
      if affiliated_projects_str.present? || residential_projects_str.present?
        title = [affiliated_projects_str, residential_projects_str].compact.join("\n")
        {
          toggle: :tooltip,
          title: title,
        }
      else
        {}
      end
    end

    private def calculated_end_of_enrollment enrollment:, enrollments:
      if enrollment.project.street_outreach_and_acts_as_bednight? && GrdaWarehouse::Config.get(:so_day_as_month)
        enrollment.last_date_in_program&.end_of_month
      elsif enrollment.project.bed_night_tracking?
        enrollment.last_date_in_program
      else
        enrollments.select do |m|
          m.project_type == enrollment.project_type &&
            m.first_date_in_program > enrollment.first_date_in_program
        end.
          sort_by(&:first_date_in_program)&.first&.first_date_in_program || enrollment.last_date_in_program
      end
    end

    private def adjusted_dates(dates:, stop_date:)
      return dates if stop_date.nil?

      dates.select { |date| date <= stop_date }
    end

    private def residential_dates enrollments:
      @non_homeless_types ||= HudUtility2024.residential_project_type_numbers_by_code[:ph]
      @residential_dates ||= enrollments.select do |e|
        @non_homeless_types.include?(e.project_type)
      end.map do |e|
        # Use select to allow for preloading
        e.service_history_services.select do |s|
          s.homeless == false
        end.map(&:date)
      end.flatten.compact.uniq
    end

    private def homeless_dates enrollments:
      @homeless_dates ||= enrollments.select do |e|
        e.project_type.in?(HudUtility2024.residential_project_type_ids)
      end.map do |e|
        # Use select to allow for preloading
        e.service_history_services.select do |s|
          # Exclude extrapolated dates
          s.record_type == 'service' && s.homeless == true
        end.map(&:date)
      end.flatten.compact.uniq
    end

    private def adjusted_months_served dates:
      dates.group_by { |d| [d.year, d.month] }.keys
    end

    # If we haven't been in a literally homeless project type (ES, SH, SO) in the last 30 days, this is a new episode
    # You aren't currently housed in PH, and you've had at least a week of being housed in the last 90 days
    def new_episode? enrollments:, enrollment:
      return false unless HudUtility2024.chronic_project_types.include?(enrollment.project_type)

      entry_date = enrollment.first_date_in_program
      thirty_days_ago = entry_date - 30.days
      ninety_days_ago = entry_date - 90.days

      housed_dates = residential_dates(enrollments: enrollments)
      currently_housed = housed_dates.include?(entry_date)
      housed_for_week_in_past_90_days = (housed_dates & (ninety_days_ago...entry_date).to_a).count > 7

      other_homeless = (homeless_dates(enrollments: enrollments) & (thirty_days_ago...entry_date).to_a).present?

      return true if ! currently_housed && housed_for_week_in_past_90_days && ! other_homeless

      return ! other_homeless
    end

    # Include extensions at the end so they can override default behavior
    include RailsDrivers::Extensions
  end
end
