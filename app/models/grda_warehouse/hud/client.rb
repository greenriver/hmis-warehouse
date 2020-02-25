###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

require 'restclient'
module GrdaWarehouse::Hud
  class Client < Base
    include Rails.application.routes.url_helpers
    include RandomScope
    include ArelHelper
    include HealthCharts
    include ApplicationHelper
    include HudSharedScopes
    include HudChronicDefinition
    include SiteChronic

    self.table_name = :Client
    self.hud_key = :PersonalID
    acts_as_paranoid(column: :DateDeleted)

    has_many :client_files
    has_many :health_files
    has_many :vispdats, class_name: 'GrdaWarehouse::Vispdat::Base', inverse_of: :client
    has_many :youth_intakes, class_name: 'GrdaWarehouse::YouthIntake::Base', inverse_of: :client
    has_many :ce_assessments, class_name: 'GrdaWarehouse::CoordinatedEntryAssessment::Base', inverse_of: :client
    has_many :case_managements, class_name: 'GrdaWarehouse::Youth::YouthCaseManagement', inverse_of: :client
    has_many :direct_financial_assistances, class_name: 'GrdaWarehouse::Youth::DirectFinancialAssistance', inverse_of: :client
    has_many :youth_referrals, class_name: 'GrdaWarehouse::Youth::YouthReferral', inverse_of: :client
    has_many :youth_follow_ups, class_name: 'GrdaWarehouse::Youth::YouthFollowUp', inverse_of: :client

    has_one :cas_project_client, class_name: 'Cas::ProjectClient', foreign_key: :id_in_data_source
    has_one :cas_client, class_name: 'Cas::Client', through: :cas_project_client, source: :client

    has_many :splits_to, class_name: GrdaWarehouse::ClientSplitHistory.name, foreign_key: :split_from
    has_many :splits_from, class_name: GrdaWarehouse::ClientSplitHistory.name, foreign_key: :split_into

    CACHE_EXPIRY = if Rails.env.production? then 4.hours else 30.minutes end


    def self.hud_csv_headers(version: nil)
      [
        :PersonalID,
        :FirstName,
        :MiddleName,
        :LastName,
        :NameSuffix,
        :NameDataQuality,
        :SSN,
        :SSNDataQuality,
        :DOB,
        :DOBDataQuality,
        :AmIndAKNative,
        :Asian,
        :BlackAfAmerican,
        :NativeHIOtherPacific,
        :White,
        :RaceNone,
        :Ethnicity,
        :Gender,
        :VeteranStatus,
        :YearEnteredService,
        :YearSeparated,
        :WorldWarII,
        :KoreanWar,
        :VietnamWar,
        :DesertStorm,
        :AfghanistanOEF,
        :IraqOIF,
        :IraqOND,
        :OtherTheater,
        :MilitaryBranch,
        :DischargeStatus,
        :DateCreated,
        :DateUpdated,
        :UserID,
        :DateDeleted,
        :ExportID
      ].freeze
    end

    has_paper_trail
    include ArelHelper

    belongs_to :data_source, inverse_of: :clients
    belongs_to :export, **hud_assoc(:ExportID, 'Export'), inverse_of: :clients, optional: true

    has_one :warehouse_client_source, class_name: 'GrdaWarehouse::WarehouseClient', foreign_key: :source_id, inverse_of: :source
    has_many :warehouse_client_destination, class_name: 'GrdaWarehouse::WarehouseClient', foreign_key: :destination_id, inverse_of: :destination
    has_one :destination_client, through: :warehouse_client_source, source: :destination, inverse_of: :source_clients
    has_many :source_clients, through: :warehouse_client_destination, source: :source, inverse_of: :destination_client
    has_many :window_source_clients, through: :warehouse_client_destination, source: :source, inverse_of: :destination_client

    # Must be included after source_clients is defined...
    include Eto::TouchPoints

    has_one :processed_service_history, -> { where(routine: 'service_history') }, class_name: 'GrdaWarehouse::WarehouseClientsProcessed'
    has_one :first_service_history, -> { where record_type: 'first' }, class_name: 'GrdaWarehouse::ServiceHistoryEnrollment'

    has_one :api_id, class_name: 'GrdaWarehouse::ApiClientDataSourceId'
    has_many :eto_client_lookups, class_name: 'GrdaWarehouse::EtoQaaws::ClientLookup'
    has_many :eto_touch_point_lookups, class_name: 'GrdaWarehouse::EtoQaaws::TouchPointLookup'
    has_one :hmis_client, class_name: 'GrdaWarehouse::HmisClient'

    has_many :service_history_enrollments
    has_many :service_history_services
    has_many :service_history_entries, -> { entry }, class_name: 'GrdaWarehouse::ServiceHistoryEnrollment'
    has_many :service_history_entry_in_last_three_years, -> {
      entry_in_last_three_years
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
    # End cleanup relationships

    has_many :organizations, -> { order(:OrganizationName).distinct }, through: :enrollments
    has_many :source_services, through: :source_clients, source: :services
    has_many :source_enrollments, through: :source_clients, source: :enrollments
    has_many :source_enrollment_cocs, through: :source_clients, source: :enrollment_cocs
    has_many :source_disabilities, through: :source_clients, source: :disabilities
    has_many :source_enrollment_disabilities, through: :source_enrollments, source: :disabilities
    has_many :source_employment_educations, through: :source_enrollments, source: :employment_educations
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
    has_many :staff_x_clients, class_name: 'GrdaWarehouse::HMIS::StaffXClient', inverse_of: :client
    has_many :staff, class_name: 'GrdaWarehouse::HMIS::Staff', through: :staff_x_clients
    has_many :source_api_ids, through: :source_clients, source: :api_id
    has_many :source_eto_client_lookups, through: :source_clients, source: :eto_client_lookups
    has_many :source_eto_touch_point_lookups, through: :source_clients, source: :eto_touch_point_lookups
    has_many :source_hmis_clients, through: :source_clients, source: :hmis_client
    has_many :source_hmis_forms, through: :source_clients, source: :hmis_forms
    has_many :source_non_confidential_hmis_forms, through: :source_clients, source: :non_confidential_hmis_forms

    has_many :cas_reports, class_name: 'GrdaWarehouse::CasReport', inverse_of: :client

    has_many :chronics, class_name: 'GrdaWarehouse::Chronic', inverse_of: :client

    has_many :chronics_in_range, -> (range) do
      where(date: range)
    end, class_name: 'GrdaWarehouse::Chronic', inverse_of: :client
    has_one :patient, class_name: 'Health::Patient'

    has_many :notes, class_name: 'GrdaWarehouse::ClientNotes::Base', inverse_of: :client
    has_many :chronic_justifications, class_name: 'GrdaWarehouse::ClientNotes::ChronicJustification'
    has_many :window_notes, class_name: 'GrdaWarehouse::ClientNotes::WindowNote'
    has_many :anomaly_notes, class_name: 'GrdaWarehouse::ClientNotes::AnomalyNote'
    has_many :cohort_notes, class_name: 'GrdaWarehouse::ClientNotes::CohortNote'

    has_many :anomalies, class_name: 'GrdaWarehouse::Anomaly'
    has_many :cas_houseds, class_name: 'GrdaWarehouse::CasHoused'

    has_many :user_clients, class_name: 'GrdaWarehouse::UserClient'
    has_many :users, through: :user_clients, inverse_of: :clients

    has_many :cohort_clients, dependent: :destroy
    has_many :cohorts, through: :cohort_clients, class_name: 'GrdaWarehouse::Cohort'

    has_many :enrollment_change_histories

    has_many :verification_sources, class_name: 'GrdaWarehouse::VerificationSource'
    has_many :disability_verification_sources, class_name: 'GrdaWarehouse::VerificationSource::Disability'

    # do not include ineligible clients for Sync with CAS
    def active_cohorts
      cohort_clients.select do |cc|
        # meta.inactive is related to days of inactivity in HMIS
        meta = CohortColumns::Meta.new(cohort: cc.cohort, cohort_client: cc)
        cc.active? && cc.cohort&.active? && (cc.housed_date.blank? || cc.destination.blank?) && ! meta.inactive && ! cc.ineligible?
      end.map(&:cohort).compact.uniq
    end

    # do not include ineligible clients for Sync with CAS
    def active_cohort_ids
      active_cohorts.map(&:id)
    end

    # This prevents leaking involvement in confidential cohorts
    def cohort_ids_for_cas
      GrdaWarehouse::Cohort.visible_in_cas.where(id: active_cohort_ids).pluck(:id)
    end

    def neighborhood_ids_for_cas
      neighborhood_interests.map(&:to_i)
    end

    # Should be in the format {tag_id: min_rank}
    # and returns the lowest rank for an individual for each tag
    def cas_tags
      @cas_tags = {}
      cohort_clients.joins(:cohort).
        merge(GrdaWarehouse::Cohort.where(id: cohort_ids_for_cas)).
        each do |cc|
          tag_id = cc.cohort.tag_id
          if tag_id.present?
            @cas_tags[tag_id] ||= cc.rank
            @cas_tags[tag_id] = cc.rank if cc.rank.present? && (cc.rank < @cas_tags[tag_id])
          end
        end
      # Are any tags that should be added based on HmisForms
      Cas::Tag.where(rrh_assessment_trigger: true).each do |tag|
        @cas_tags[tag.id] = assessment_score_for_cas
      end
      @cas_tags
    end

    def default_shelter_agency_contacts
      source_hmis_forms.rrh_assessment.with_staff_contact.pluck(:staff_email)
    end

    # do include ineligible clients for client dashboard, but don't include cohorts excluded from
    # client dashboard
    def cohorts_for_dashboard
      cohort_clients.select do |cc|
        meta = CohortColumns::Meta.new(cohort: cc.cohort, cohort_client: cc)
        cc.active? && cc.cohort&.active? && cc.cohort.show_on_client_dashboard? && ! meta.inactive
      end.map(&:cohort).compact.uniq
    end

    def last_exit_destination
      last_exit = source_exits.order(ExitDate: :desc).first
      if last_exit
        destination_code = last_exit.Destination || 99
        if destination_code == 17
          destination_string = last_exit.OtherDestination
        else
          destination_string = HUD.destination(destination_code)
        end
        return "#{destination_string} (#{last_exit.ExitDate})"
      else
        return "None"
      end
    end

    has_one :active_consent_form, class_name: GrdaWarehouse::ClientFile.name, primary_key: :consent_form_id, foreign_key: :id

    # Delegations
    delegate :first_homeless_date, to: :processed_service_history, allow_nil: true
    delegate :last_homeless_date, to: :processed_service_history, allow_nil: true
    delegate :first_chronic_date, to: :processed_service_history, allow_nil: true
    delegate :last_chronic_date, to: :processed_service_history, allow_nil: true
    delegate :first_date_served, to: :processed_service_history, allow_nil: true
    delegate :last_date_served, to: :processed_service_history, allow_nil: true


    scope :destination, -> do
      where(data_source: GrdaWarehouse::DataSource.destination)
    end
    scope :source, -> do
      where(data_source: GrdaWarehouse::DataSource.source)
    end

    scope :searchable, -> do
      where(data_source: GrdaWarehouse::DataSource.source)
    end
    # For now, this is way to slow, calculate in ruby
    # scope :unmatched, -> do
    #   source.where.not(id: GrdaWarehouse::WarehouseClient.select(:source_id))
    # end
    #

    scope :child, -> (on: Date.current) do
      where(c_t[:DOB].gt(on - 18.years))
    end

    scope :youth, -> (on: Date.current) do
      where(DOB: (on - 24.years .. on - 18.years))
    end

    scope :adult, -> (on: Date.current) do
      where(c_t[:DOB].lteq(on - 18.years))
    end

    #################################
    # Standard Cohort Scopes

    scope :individual_adult, -> (start_date: Date.current, end_date: Date.current) do
      adult(on: start_date).
      where(
        id: GrdaWarehouse::ServiceHistoryEnrollment.entry.
          open_between(start_date: start_date, end_date: end_date).
          distinct.
          individual_adult.
          select(:client_id)
      )
    end

    scope :unaccompanied_youth, -> (start_date: Date.current, end_date: Date.current) do
      youth(on: start_date).
      where(
        id: GrdaWarehouse::ServiceHistoryEnrollment.entry.
          open_between(start_date: start_date, end_date: end_date).
          distinct.
          unaccompanied_youth.
          select(:client_id)
      )
    end

    scope :children_only, -> (start_date: Date.current, end_date: Date.current) do
      child(on: start_date).
      where(
        id: GrdaWarehouse::ServiceHistoryEnrollment.entry.
          open_between(start_date: start_date, end_date: end_date).
          distinct.
          children_only.
          select(:client_id)
      )
    end

    scope :parenting_youth, -> (start_date: Date.current, end_date: Date.current) do
      youth(on: start_date).
      where(
        id: GrdaWarehouse::ServiceHistoryEnrollment.entry.
          open_between(start_date: start_date, end_date: end_date).
          distinct.
          parenting_youth.
          select(:client_id)
      )
    end

    scope :parenting_juvenile, -> (start_date: Date.current, end_date: Date.current) do
      youth(on: start_date).
      where(
        id: GrdaWarehouse::ServiceHistoryEnrollment.entry.
          open_between(start_date: start_date, end_date: end_date).
          distinct.
          parenting_juvenile.
          select(:client_id)
      )
    end

    scope :unaccompanied_minors, -> (start_date: Date.current, end_date: Date.current) do
      youth(on: start_date).
      where(
        id: GrdaWarehouse::ServiceHistoryEnrollment.entry.
          open_between(start_date: start_date, end_date: end_date).
          distinct.
          unaccompanied_minors.
          select(:client_id)
      )
    end

    scope :family, -> (start_date: Date.current, end_date: Date.current) do
      where(
        id: GrdaWarehouse::ServiceHistoryEnrollment.entry.
          open_between(start_date: start_date, end_date: end_date).
          distinct.
          family.
          select(:client_id)
      )
    end

    scope :veteran, -> do
      where(VeteranStatus: 1)
    end

    scope :non_veteran, -> do
      where(c_t[:VeteranStatus].not_eq(1).or(c_t[:VeteranStatus].eq(nil)))
    end

    scope :verified_non_veteran, -> do
      where verified_veteran_status: :non_veteran
    end

    # Some aliases for our inconsistencies
    class << self
      alias_method :individual_adults, :individual_adult
      alias_method :all_clients, :all
      alias_method :children, :children_only
      alias_method :parenting_children, :parenting_juvenile
    end

    # End Standard Cohorts
    #################################
    scope :individual, -> (on_date: Date.current) do
      where(
        id: GrdaWarehouse::ServiceHistoryEnrollment.entry.
          ongoing(on_date: on_date).
          distinct.
          individual.select(:client_id)
      )
    end

    scope :homeless_individual, -> (on_date: Date.current, chronic_types_only: false) do
      where(
        id: GrdaWarehouse::ServiceHistoryEnrollment.entry.
          currently_homeless(date: on_date, chronic_types_only: chronic_types_only).
          distinct.
          individual.select(:client_id)
      )

    end

    scope :currently_homeless, -> (chronic_types_only: false) do
      # this is somewhat involved in order to make it composable and somewhat efficient
      # more efficient is a join + distinct, but the distinct makes it less composable
      # clearer and composable but less efficient would be to use an exists subquery

      if chronic_types_only
        project_types = GrdaWarehouse::Hud::Project::CHRONIC_PROJECT_TYPES
      else
        project_types = GrdaWarehouse::Hud::Project::HOMELESS_PROJECT_TYPES
      end

      inner_table = sh_t.
        project(sh_t[:client_id]).
        group(sh_t[:client_id]).
        where( sh_t[:record_type].eq 'entry' ).
        where( sh_t[:project_type].in(project_types)).
        where( sh_t[:last_date_in_program].eq nil ).
        as('sh_t')
      joins "INNER JOIN #{inner_table.to_sql} ON #{c_t[:id].eq(inner_table[:client_id]).to_sql}"
    end

    # clients whose first residential service record is within the given date range
    scope :entered_in_range, -> (range) do
      s, e, exclude = range.first, range.last, range.exclude_end?   # the exclusion bit's a little pedantic...
      sh  = GrdaWarehouse::ServiceHistoryEnrollment
      sht = sh.arel_table
      joins(:first_service_history).
        where( sht[:date].gteq s ).
        where( exclude ? sht[:date].lt(e) : sht[:date].lteq(e) )
    end

    scope :in_data_source, -> (data_source_id) do
      where(data_source_id: data_source_id)
    end

    scope :cas_active, -> do
      case GrdaWarehouse::Config.get(:cas_available_method).to_sym
      when :cas_flag
        where(sync_with_cas: true)
      when :chronic
        joins(:chronics).where(chronics: {date: GrdaWarehouse::Chronic.most_recent_day})
      when :hud_chronic
        joins(:hud_chronics).where(hud_chronics: {date: GrdaWarehouse::HudChronic.most_recent_day})
      when :release_present
        where(housing_release_status: [full_release_string, partial_release_string])
      else
        raise NotImplementedError
      end
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

    scope :dmh_eligible, -> do
      where.not(dmh_eligible: false)
    end

    scope :va_eligible, -> do
      where.not(va_eligible: false)
    end

    scope :hues_eligible, -> do
      where.not(hues_eligible: false)
    end

    scope :hiv_positive, -> do
      where.not(hiv_positive: false)
    end

    scope :visible_in_window_to, -> (user) do
      joins(:data_source).merge(GrdaWarehouse::DataSource.visible_in_window_to(user))
    end

    scope :visible_by_project_to, -> (user) do
      joins(enrollments: :project).merge(GrdaWarehouse::Hud::Project.viewable_by(user))
    end

    scope :has_homeless_service_after_date, -> (date: 31.days.ago) do
      where(id:
        GrdaWarehouse::ServiceHistoryService.homeless(chronic_types_only: true).
        where(sh_t[:date].gt(date)).
        select(:client_id).distinct
      )
    end

    scope :has_homeless_service_between_dates, -> (start_date: 31.days.ago, end_date: Date.current) do
      where(id:
        GrdaWarehouse::ServiceHistoryService.homeless(chronic_types_only: true).
        where(date: (start_date..end_date)).
        select(:client_id).distinct
      )
    end

    scope :full_text_search, -> (text) do
      text_search(text, client_scope: current_scope)
    end

    scope :age_group, -> (start_age: 0, end_age: nil) do
      start_age = 0 unless start_age.is_a?(Integer)
      end_age   = nil unless end_age.is_a?(Integer)
      if end_age.present?
        where(DOB: end_age.years.ago..start_age.years.ago)
      else
        where(arel_table[:DOB].lteq(start_age.years.ago))
      end
    end

    scope :age_group_within_range, -> (start_age: 0, end_age: nil, start_date: Date.current, end_date: Date.current) do
      start_age = 0 unless start_age.is_a?(Integer)
      end_age   = nil unless end_age.is_a?(Integer)
      if end_age.present?
        where(DOB: (start_date - end_age.years)..(end_date - start_age.years))
      else
        where(arel_table[:DOB].lteq(start_date - start_age.years))
      end
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

    def self.exists_with_inner_clients(inner_scope)
      inner_scope = inner_scope.to_sql.gsub('"Client".', '"inner_clients".').gsub('"Client"', '"Client" as "inner_clients"')
      Arel.sql("EXISTS (#{inner_scope} and \"Client\".\"id\" = \"inner_clients\".\"id\")")
    end

    scope :searchable_by, -> (user) do
      if user.can_edit_anything_super_user?
        current_scope
      elsif user.can_view_clients_with_roi_in_own_coc?
        current_scope
      elsif user.can_view_clients? || user.can_edit_clients?
        current_scope
      else
        ds_ids = user.data_sources.pluck(:id)
        project_query = exists_with_inner_clients(visible_by_project_to(user))
        window_query = exists_with_inner_clients(visible_in_window_to(user))

        if user&.can_see_clients_in_window_for_assigned_data_sources? && ds_ids.present?
          where(
            arel_table[:data_source_id].in(ds_ids).
            or(project_query).
            or(window_query)
          )

          where(
            arel_table[:data_source_id].in(ds_ids).
            or(project_query).
            or(window_query)
          )
        else
          where(
            arel_table[:id].eq(0). # no client should have a 0 id
            or(project_query).
            or(window_query)
          )
        end
      end
    end

    scope :viewable_by, -> (user) do
      if user.can_edit_anything_super_user?
        current_scope
      else
        project_query = exists_with_inner_clients(visible_by_project_to(user))
        window_query = exists_with_inner_clients(visible_in_window_to(user))
        active_consent_query = exists_with_inner_clients(active_confirmed_consent_in_cocs(user.coc_codes))

        if user.can_view_clients_with_roi_in_own_coc?
          # At a high level if you can see clients with ROI in your COC, you need to be able
          # to see everyone for searching purposes.
          # limits will be imposed on accessing the actual client dashboard pages
          # current_scope

          # If the user has coc-codes specified, this will limit to users
          # with a valid consent form in the coc or with no-coc specified
          # If the user does not have a coc-code specified, only clients with a full (CoC not specified) release
          # are included.
          if user&.can_see_clients_in_window_for_assigned_data_sources?
            ds_ids = user.data_sources.pluck(:id)
            sql = arel_table[:data_source_id].in(ds_ids).
              or(active_consent_query).
              or(project_query)
            unless GrdaWarehouse::Config.get(:window_access_requires_release)
              sql = sql.or(window_query)
            end

            where(sql)
          else
            active_confirmed_consent_in_cocs(user.coc_codes)
          end
        elsif user.can_view_clients? || user.can_edit_clients?
          current_scope
        else
          ds_ids = user.data_sources.pluck(:id)
          if user&.can_see_clients_in_window_for_assigned_data_sources? && ds_ids.present?
            sql = arel_table[:data_source_id].in(ds_ids)
            sql = sql.or(project_query)
            if GrdaWarehouse::Config.get(:window_access_requires_release)
              sql = sql.or(active_consent_query)
            else
              sql = sql.or(window_query)
            end
            where(sql)
          else
            sql = arel_table[:id].eq(0) # no client should have a 0 id
            sql = sql.or(project_query)
            if GrdaWarehouse::Config.get(:window_access_requires_release)
              sql = sql.or(active_consent_query)
            else
              sql = sql.or(window_query)
            end

            where(sql)
          end
        end
      end
    end


    scope :active_confirmed_consent_in_cocs, -> (coc_codes) do
      if coc_codes.present?
        consent_form_valid.where(
          Arel.sql("consented_coc_codes='[]'::jsonb OR " +
          "#{quoted_table_name}.consented_coc_codes ?| array[#{coc_codes.map {|s| connection.quote(s)}.join(',')}]")
        )
      else
        consent_form_valid.where("consented_coc_codes='[]'::jsonb")
      end
    end

    scope :consent_form_valid, -> do
      case(release_duration)
      when 'One Year'
        where(
          arel_table[:housing_release_status].matches("%#{full_release_string}").
          and(
            arel_table[:consent_form_signed_on].gteq(consent_validity_period.ago)
          ))
      when 'Use Expiration Date'
        where(
          arel_table[:housing_release_status].matches("%#{full_release_string}").
          and(
            arel_table[:consent_expires_on].gteq(Date.current)
          ))
      else
        where(arel_table[:housing_release_status].matches("%#{full_release_string}"))
      end
    end

    # Race & Ethnicity scopes
    scope :race_am_ind_ak_native, -> do
      where(
        id: GrdaWarehouse::WarehouseClient.joins(:source).
          where(c_t[:AmIndAKNative].eq(1)).
          select(:destination_id)
      )
    end

    scope :race_asian, -> do
      where(
        id: GrdaWarehouse::WarehouseClient.joins(:source).
          where(c_t[:Asian].eq(1)).
          select(:destination_id)
      )
    end

    scope :race_black_af_american, -> do
      where(
        id: GrdaWarehouse::WarehouseClient.joins(:source).
          where(c_t[:BlackAfAmerican].eq(1)).
          select(:destination_id)
      )
    end

    scope :race_native_hi_other_pacific, -> do
      where(
        id: GrdaWarehouse::WarehouseClient.joins(:source).
          where(c_t[:NativeHIOtherPacific].eq(1)).
          select(:destination_id)
      )
    end

    scope :race_white, -> do
      where(
        id: GrdaWarehouse::WarehouseClient.joins(:source).
          where(c_t[:White].eq(1)).
          select(:destination_id)
      )
    end

    scope :race_none, -> do
      where(
        id: GrdaWarehouse::WarehouseClient.joins(:source).
          where(c_t[:RaceNone].eq(1)).
          select(:destination_id)
      )
    end

    scope :ethnicity_non_hispanic_non_latino, -> do
      where(
        id: GrdaWarehouse::WarehouseClient.joins(:source).
          where(c_t[:Ethnicity].eq(0)).
          select(:destination_id)
      )
    end

    scope :ethnicity_hispanic_latino, -> do
      where(
        id: GrdaWarehouse::WarehouseClient.joins(:source).
          where(c_t[:Ethnicity].eq(1)).
          select(:destination_id)
      )
    end

    scope :ethnicity_unknown, -> do
      where(
        id: GrdaWarehouse::WarehouseClient.joins(:source).
          where(c_t[:Ethnicity].eq(8)).
          select(:destination_id)
      )
    end

    scope :ethnicity_refused, -> do
      where(
        id: GrdaWarehouse::WarehouseClient.joins(:source).
          where(c_t[:Ethnicity].eq(9)).
          select(:destination_id)
      )
    end

    scope :ethnicity_not_collected, -> do
      where(
        id: GrdaWarehouse::WarehouseClient.joins(:source).
          where(c_t[:Ethnicity].eq(99)).
          select(:destination_id)
      )
    end

    ####################
    # Callbacks
    ####################
    after_create :notify_users
    attr_accessor :send_notifications

    def notify_users
      NotifyUser.client_added( id ).deliver_later if send_notifications
    end

    def self.ahar_age_groups
      {
        range_0_to_1: { name: "< 1 yr old", start_age: 0, end_age: 1},
        range_1_to_5: { name: "1 - 5 yrs old", start_age: 1, end_age: 6},
        range_6_to_12: { name: "6 - 12 yrs old", start_age: 6, end_age: 13},
        range_13_to_17: { name: "13 - 17 yrs old", start_age: 13, end_age: 18},
        range_18_to_24: { name: "18 - 24 yrs old", start_age: 18, end_age: 25},
        range_25_to_30: { name: "25 - 30 yrs old", start_age: 25, end_age: 31},
        range_31_to_50: { name: "31 - 50 yrs old", start_age: 31, end_age: 51},
        range_51_to_61: { name: "51 - 61 yrs old", start_age: 51, end_age: 62},
        range_62_to_nil: { name: "62+ yrs old", start_age: 62, end_age: nil }
      }
    end

    def self.extended_age_groups
      {
        range_0_to_1: { name: "< 1 yr old", range: (0..0)},
        range_1_to_5: { name: "1 - 5 yrs old", range: (1..5)},
        range_6_to_13: { name: "6 - 13 yrs old", range: (6..13)},
        range_14_to_17: { name: "14 - 17 yrs old", range: (14..17)},
        range_18_to_21: { name: "18 - 21 yrs old", range: (18..21)},
        range_19_to_24: { name: "19 - 24 yrs old", range: (19..24)},
        range_25_to_30: { name: "25 - 30 yrs old", range: (25..30)},
        range_31_to_35: { name: "31 - 35 yrs old", range: (31..35)},
        range_36_to_40: { name: "36 - 40 yrs old", range: (36..40)},
        range_41_to_45: { name: "41 - 45 yrs old", range: (41..45)},
        range_44_to_50: { name: "45 - 50 yrs old", range: (45..50)},
        range_51_to_55: { name: "51 - 55 yrs old", range: (51..55)},
        range_55_to_60: { name: "56 - 60 yrs old", range: (55..60)},
        range_61_to_62: { name: "61 - 62 yrs old", range: (61..62)},
        range_62_plus: { name: "62+ yrs old", range: (62..Float::INFINITY)},
        missing: {name: "Missing", range: [nil]}
      }
    end

    def alternate_names
      names = source_clients.map(&:full_name).uniq
      names -= [full_name]
      names.join(',')
    end

    def client_names user: nil, health: false
      client_scope = source_clients.searchable_by(user)
      names = client_scope.includes(:data_source).map do |m|
        {
          ds: m.data_source&.short_name,
          ds_id: m.data_source&.id,
          name: m.full_name,
          health: m.data_source&.authoritative_type == 'health'
        }
      end
      if health && patient.present? && names.detect { |name| name[:health] }.blank?
        names << { ds: 'Health', ds_id: 'health', name: patient.name }
      end
      return names
    end

    # client has a disability response in the affirmative
    # where they don't have a subsequent affirmative or negative
    def currently_disabled?
      self.class.disabled_client_scope.where(id: id).exists?
    end

    # client has a disability response in the affirmative
    # where they don't have a subsequent affirmative or negative
    def self.disabled_client_scope
      d_t1 = GrdaWarehouse::Hud::Disability.arel_table
      d_t2 = d_t1.dup
      d_t2.table_alias = 'disability2'
      c_t1 = GrdaWarehouse::Hud::Client.arel_table
      c_t2 = c_t1.dup
      c_t2.table_alias = 'source_clients'
      GrdaWarehouse::Hud::Client.destination.
        joins(:source_enrollment_disabilities).
        where(Disabilities: {DisabilityType: [5, 6, 7, 8, 9, 10], DisabilityResponse: [1, 2, 3]}).
        where(
          d_t2.project(Arel.star).where(
            d_t2[:DateDeleted].eq(nil)
          ).where(
            d_t2[:DisabilityType].eq(d_t1[:DisabilityType])
          ).where(
            d_t2[:InformationDate].gt(d_t1[:InformationDate])
          ).where(
            d_t2[:DisabilityResponse].in([0, 1, 2, 3])
          ).
          join(e_t).on(
            e_t[:PersonalID].eq(d_t2[:PersonalID]).
            and(e_t[:data_source_id].eq(d_t2[:data_source_id])).
            and(e_t[:EnrollmentID].eq(d_t2[:EnrollmentID])).
            and(e_t[:DateDeleted].eq(nil))
          ).join(c_t2).on(
             e_t[:PersonalID].eq(c_t2[:PersonalID]).
             and(e_t[:data_source_id].eq(c_t2[:data_source_id]))
          ).join(wc_t).on(
            c_t2[:id].eq(wc_t[:source_id]).
            and(wc_t[:deleted_at].eq(nil))
          ).where(
            wc_t[:destination_id].eq(c_t1[:id])
          ).
          exists.not
        ).distinct
    end

    # client has a disability response in the affirmative
    # where they don't have a subsequent affirmative or negative
    def self.disabled_client_ids
      disabled_client_scope.pluck(:id)
    end

    scope :chronically_disabled, -> (end_date=Date.current) do
      start_date = end_date - 3.years
      joins(:source_enrollment_disabilities).
        merge(GrdaWarehouse::Hud::Enrollment.open_during_range(start_date..end_date)).
        merge(GrdaWarehouse::Hud::Disability.chronically_disabled)
    end

    def chronically_disabled?
      self.class.chronically_disabled.where(id: id).exists?
    end

    def deceased?
      deceased_on.present?
    end
    def deceased_on
      @deceased_on ||= source_exits.where(Destination: ::HUD.valid_destinations.invert['Deceased']).pluck(:ExitDate).last
    end

    def moved_in_with_ph?
      enrollments.
        open_on_date.
        with_project_type(GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:ph]).
        where(GrdaWarehouse::Hud::Enrollment.arel_table[:MoveInDate].lt(Date.current)).exists?
    end

    def active_in_cas?
      return false if deceased? || moved_in_with_ph?
      case GrdaWarehouse::Config.get(:cas_available_method).to_sym
      when :cas_flag
        sync_with_cas
      when :chronic
        chronics.where(chronics: {date: GrdaWarehouse::Chronic.most_recent_day}).exists?
      when :hud_chronic
        hud_chronics.where(hud_chronics: {date: GrdaWarehouse::HudChronic.most_recent_day}).exists?
      when :release_present
        [self.class.full_release_string, self.class.partial_release_string].include?(housing_release_status)
      else
        raise NotImplementedError
      end
    end

    def inactivate_in_cas
      update(sync_with_cas: false)
    end

    def scope_for_ongoing_residential_enrollments
      service_history_enrollments.
      entry.
      residential.
      ongoing
    end

    def scope_for_other_enrollments
      service_history_enrollments.
      entry.
      hud_non_residential
    end

    def scope_for_residential_enrollments
      service_history_enrollments.
      entry.
      hud_residential
    end

    attr_accessor :merge
    attr_accessor :unmerge
    attr_accessor :bypass_search # Used for creating new clients

    alias_attribute :last_name, :LastName
    alias_attribute :first_name, :FirstName
    alias_attribute :dob, :DOB
    alias_attribute :ssn, :SSN

    def window_link_for? user
      return false if user.blank?

      if show_window_demographic_to?(user)
        client_path(self)
      elsif GrdaWarehouse::Vispdat::Base.any_visible_by?(user)
        client_vispdats_path(self)
      elsif GrdaWarehouse::ClientFile.any_visible_by?(user)
        client_files_path(self)
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

    def show_window_demographic_to?(user)
      visible_because_of_permission?(user) || visible_because_of_relationship?(user)
    end

    def visible_because_of_permission?(user)
        user.can_view_clients? ||
        visible_because_of_release?(user) ||
        visible_because_of_assigned_data_source?(user) ||
        visible_because_of_coc_association?(user)
    end

    def visible_because_of_release?(user)
      user.can_view_client_window? &&
      (release_valid? || ! GrdaWarehouse::Config.get(:window_access_requires_release))
    end

    def visible_because_of_assigned_data_source?(user)
      user.can_see_clients_in_window_for_assigned_data_sources? &&
        (source_clients.pluck(:data_source_id) & user.data_sources.pluck(:id)).present?
    end

    def visible_because_of_coc_association?(user)
      user.can_view_clients_with_roi_in_own_coc? &&
      release_valid? &&
      (
        consented_coc_codes == [] ||
        (consented_coc_codes & user.coc_codes).present?
      )
    end

    def visible_because_of_relationship?(user)
      self.user_clients.pluck(:user_id).include?(user.id) && release_valid? && user.can_search_window?
    end
    # Define a bunch of disability methods we can use to get the response needed
    # for CAS integration
    # This generates methods like: substance_response()
    GrdaWarehouse::Hud::Disability.disability_types.each do |hud_key, disability_type|
      define_method "#{disability_type}_response".to_sym do
        disability_check = "#{disability_type}?".to_sym
        source_disabilities.detect(&disability_check).try(:response)
      end
    end

    GrdaWarehouse::Hud::Disability.disability_types.each do |hud_key, disability_type|
      define_method "#{disability_type}_response?".to_sym do
        self.send("#{disability_type}_response".to_sym) == 'Yes'
      end
    end

    def sync_cas_attributes_with_files
      return unless GrdaWarehouse::Config.get(:cas_flag_method) == 'file'
      self.ha_eligible = client_files.tagged_with(cas_attributes_file_tag_map[:ha_eligible], any: true).exists?
      if client_files.tagged_with(cas_attributes_file_tag_map[:disability_verified_on], any: true).exists?
        # set this to the most recent updated date
        self.disability_verified_on = client_files.tagged_with(cas_attributes_file_tag_map[:disability_verified_on], any: true).
          order(updated_at: :desc).
          pluck(:updated_at).first
      else
        self.disability_verified_on = nil
      end
      save
    end

    def cas_attributes_file_tag_map
      {
        ha_eligible: [
          'BHA Eligibility',
          'Housing Authority Eligibility',
        ],
        disability_verified_on: GrdaWarehouse::AvailableFileTag.tag_includes('Verification of Disability').map(&:name),
        limited_cas_release: [
          'Limited CAS Release'
        ],
      }
    end

    def contact_info_for_rrh_assessment
      rrh_assessment_contact_info if consent_form_valid?
    end

    def score_for_rrh_assessment
      processed_service_history&.eto_coordinated_entry_assessment_score || 0
    end

    # Pathways and RRH assessment scores get stored in rrh_assessment_score
    # If we don't have that, use highest assessment score from any cohort clients
    def assessment_score_for_cas
      return rrh_assessment_score if rrh_assessment_score.present? && rrh_assessment_score.positive?

      assessment_score_from_cohort_clients
    end

    def assessment_score_from_cohort_clients
      cohort_clients.pluck(:assessment_score)&.compact&.max || 0
    end

    ##############################
    # NOTE: this section deals with the release/consent form as uploaded
    # and maintained in the warehouse
    def self.full_release_string
      # Return the untranslated string, but force the translator to see it
      _('Full HAN Release')
      'Full HAN Release'
    end

    def self.partial_release_string
      # Return the untranslated string, but force the translator to see it
      _('Limited CAS Release')
      'Limited CAS Release'
    end

    def self.consent_validity_period
      if release_duration == 'One Year'
        1.years
      elsif release_duration == 'Indefinite'
        100.years
      else
        raise 'Unknown Release Duration'
      end
    end

    def self.revoke_expired_consent
      if release_duration == 'One Year'
        clients_with_consent = self.where.not(consent_form_signed_on: nil)
        clients_with_consent.each do |client|
          if client.consent_form_signed_on < consent_validity_period.ago
            client.update_columns(housing_release_status: nil)
          end
        end
      elsif release_duration == 'Use Expiration Date'
        self.destination.where(
          arel_table[:consent_expires_on].lt(Date.current)
        ).update_all(housing_release_status: nil)
      end
    end

    def release_current_status
      consent_text = if housing_release_status.blank?
        'None on file'
      elsif release_duration == 'One Year'
        if consent_form_valid?
          "Valid Until #{consent_form_signed_on + self.class.consent_validity_period}"
        else
          'Expired'
        end
      elsif release_duration == 'Use Expiration Date'
        if consent_form_valid?
          "Valid Until #{consent_expires_on}"
        else
          'Expired'
        end
      else
        _(housing_release_status)
      end
      if consented_coc_codes&.any?
        consent_text += " in #{consented_coc_codes.to_sentence}"
      end
      consent_text
    end

    def release_duration
      @release_duration ||= GrdaWarehouse::Config.get(:release_duration)
    end

    def self.release_duration
      @release_duration = GrdaWarehouse::Config.get(:release_duration)
    end

    def release_valid?
      housing_release_status&.starts_with?(self.class.full_release_string) || false
    end

    def consent_form_valid?
      if release_duration == 'One Year'
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
      else
        client_files.consent_forms.signed.confirmed.exists?
      end
    end

    def newest_consent_form
      # Regardless of confirmation status
      client_files.consent_forms.order(updated_at: :desc)&.first
    end

    def release_status_for_cas
      if housing_release_status.blank?
        return 'None on file'
      end
      if release_duration.in?(['One Year', 'Use Expiration Date'])
        if ! (consent_form_valid? && consent_confirmed?)
          return 'Expired'
        end
      end
      return _(housing_release_status)
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
        'Client doesn’t know',
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
      [
        cas_substance_response,
        physical_response,
        developmental_response,
        chronic_response,
        hiv_response,
        mental_response,
      ].include?('Yes')
    end

    # Use the Pathways answer if available, otherwise, HMIS
    def domestic_violence?
      return pathways_domestic_violence if pathways_domestic_violence

      source_health_and_dvs.where(DomesticViolenceVictim: 1).exists?
    end

    def chronic?(on: nil)
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

    # Households are people entering with the same HouseholdID to the same project, regardless of time
    def households
      @households ||= begin
        hids = service_history_entries.where.not(household_id: [nil, '']).pluck(:household_id, :data_source_id, :project_id).uniq
        if hids.any?
          columns = {
            household_id: she_t[:household_id].to_sql,
            date: she_t[:date].to_sql,
            client_id: she_t[:client_id].to_sql,
            age: she_t[:age].to_sql,
            enrollment_group_id: she_t[:enrollment_group_id].to_sql,
            FirstName: c_t[:FirstName].to_sql,
            LastName: c_t[:LastName].to_sql,
            last_date_in_program: she_t[:last_date_in_program].to_sql,
            data_source_id: she_t[:data_source_id].to_sql,
          }

          hh_where = hids.map do |hh_id, ds_id, p_id|
            she_t[:household_id].eq(hh_id).
            and(
              she_t[:data_source_id].eq(ds_id)
            ).
            and(
              she_t[:project_id].eq(p_id)
            ).to_sql
          end.join(' or ')

          entries = GrdaWarehouse::ServiceHistoryEnrollment.entry
            .joins(:client)
            .where(hh_where)
            .where.not(client_id: id )
            .pluck(*columns.values.map{|v| Arel.sql(v)}).map do |row|
              Hash[columns.keys.zip(row)]
            end.uniq
          entries = entries.map(&:with_indifferent_access).group_by{|m| [m['household_id'], m['data_source_id']]}
        end
      end
    end

    def household household_id, data_source_id
      households[[household_id, data_source_id]] if households.present?
    end

    def self.dashboard_family_warning
      if GrdaWarehouse::Config.get(:infer_family_from_household_id)
        warning = 'Clients presenting as families enrolled in homeless projects (ES, SH, SO, TH).'
      else # uses project serves families
        warning = 'Clients enrolled in homeless projects (ES, SH, SO, TH) where the enrollment is at a project with inventory for families.'
      end
      return warning if GrdaWarehouse::Config.get(:family_calculation_method) == 'multiple_people'

      warning + ' ' + family_means_adult_child_warning
    end

    def self.report_family_warning
      if GrdaWarehouse::Config.get(:infer_family_from_household_id)
        warning = 'Clients are limited to those presenting as families.'
      else # uses project serves families
        warning = 'Clients are limited to clients enrolled in a project with inventory for families.'
      end
      return warning if GrdaWarehouse::Config.get(:family_calculation_method) == 'multiple_people'

      warning + ' ' + family_means_adult_child_warning
    end

    def self.family_means_adult_child_warning
      'Clients are further limited to only Heads of Household who presented with children.'
    end

    # after and before take dates, or something like 3.years.ago
    def presented_with_family?(after: nil, before: nil)
      return false unless households.present?
      raise 'After required if before specified.' if before.present? && ! after.present?
      hh = if before.present? && after.present?
        recent_households = households.select do |_, entries|
          # return true if this client presented with family during the range in question
          # all entries will have the same date and last_date_in_program
          entry = entries.first
          (entry_date, exit_date) = entry.with_indifferent_access.values_at('date', 'last_date_in_program')
          en_1_start = entry_date
          en_1_end = exit_date
          en_2_start = after
          en_2_end = before

          # Excellent discussion of why this works:
          # http://stackoverflow.com/questions/325933/determine-whether-two-date-ranges-overlap
          # en_1_start < en_2_end && en_1_end > en_2_start rescue true # this catches empty exit dates
          dates_overlap(entry_date, exit_date, after, before)
        end
      elsif after.present?
        recent_households = households.select do |_, entries|
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
      if GrdaWarehouse::Config.get(:family_calculation_method) == 'multiple_people'
        return hh.values.select{|m| m.size >= 1}.any?
      else
        child = false
        adult = false
        hh.with_indifferent_access.each do |_, household|
          date = household.first[:date]
          # client life stage
          child = self.DOB.present? && age_on(date) < 18
          adult = self.DOB.blank? || age_on(date) >= 18
          # household members life stage
          household.map{|m| m['age']}.uniq.each do |a|
            adult = true if a.present? && a >= 18
            child = true if a.blank? || a < 18
          end
          return true if child && adult
        end
        return child && adult
      end
    end

    def name
      "#{self.FirstName} #{self.LastName}"
    end

    def names
      source_clients.map{ |n| "#{n.data_source.short_name} #{n.full_name}" }
    end

    def hmis_client_response
      @hmis_client_response ||= JSON.parse(hmis_client.response).with_indifferent_access if hmis_client.present?
    end

    def email
      return unless hmis_client_response.present?
      hmis_client_response['Email']
    end

    def home_phone
      return unless hmis_client_response.present?
      hmis_client_response['HomePhone']
    end

    def cell_phone
      return unless hmis_client_response.present?
      hmis_client_response['CellPhone']
    end

    def work_phone
      return unless hmis_client_response.present?
      work_phone = hmis_client_response['WorkPhone']
      work_phone += " x #{hmis_client_response['WorkPhoneExtension']}" if hmis_client_response['WorkPhoneExtension'].present?
      work_phone
    end

    def self.no_image_on_file_image
      return File.read(Rails.root.join("public", "no_photo_on_file.jpg"))
    end

    # finds an image for the client. there may be more then one available but this
    # method will select one more or less at random. returns no_image_on_file_image
    # if none is found. returns that actual image bytes
    # FIXME: invalidate the cached image if any aspect of the client changes
    def image(cache_for=10.minutes)
      ActiveSupport::Cache::FileStore.new(Rails.root.join('tmp/client_images')).fetch(self.cache_key, expires_in: cache_for) do
        logger.debug "Client#image id:#{self.id} cache_for:#{cache_for} fetching via api"
        image_data = nil
        if Rails.env.production?
          # Use the uploaded client image if available, otherwise use the API, if we have access
          unless image_data = local_client_image_data()
            return nil unless GrdaWarehouse::Config.get(:eto_api_available)
            api_configs = EtoApi::Base.api_configs
            source_api_ids.detect do |api_id|
              api_key = api_configs.select{|k,v| v['data_source_id'] == api_id.data_source_id}&.keys&.first
              return nil unless api_key.present?
              api ||= EtoApi::Base.new(api_connection: api_key).tap{|api| api.connect} rescue nil
              image_data = api.client_image(
                client_id: api_id.id_in_data_source,
                site_id: api_id.site_id_in_data_source
              ) rescue nil
              (image_data && image_data.length > 0)
            end
          end
        else
          unless image_data = local_client_image_data()
            return nil unless GrdaWarehouse::Config.get(:eto_api_available)
            image_data = fake_client_image_data
          end
        end
        image_data
      end
    end

    def image_for_source_client(cache_for=10.minutes)
      return '' unless GrdaWarehouse::Config.get(:eto_api_available) && source?
      ActiveSupport::Cache::FileStore.new(Rails.root.join('tmp/client_images')).fetch([self.cache_key, self.id], expires_in: cache_for) do
        logger.debug "Client#image id:#{self.id} cache_for:#{cache_for} fetching via api"
        image_data = nil
        if Rails.env.production?
          return nil unless GrdaWarehouse::Config.get(:eto_api_available)
          api_configs = EtoApi::Base.api_configs
          api_key = api_configs.select{|k,v| v['data_source_id'] == api_id.data_source_id}&.keys&.first
          return nil unless api_key.present?
          api ||= EtoApi::Base.new(api_connection: api_key).tap{|api| api.connect}
          image_data = api.client_image(
            client_id: api_id.id_in_data_source,
            site_id: api_id.site_id_in_data_source
          ) rescue nil
          return image_data
        else
          image_data = fake_client_image_data
        end
        image_data || self.class.no_image_on_file_image
      end
    end

    def fake_client_image_data
      gender = if self[:Gender].in?([1,3]) then 'male' else 'female' end
      age_group = if age.blank? || age > 18 then 'adults' else 'children' end
      image_directory = File.join('public', 'fake_photos', age_group, gender)
      available = Dir[File.join(image_directory, '*.jpg')]
      image_id = "#{self.FirstName}#{self.LastName}".sum % available.count
      logger.debug "Client#image id:#{self.id} faked #{self.PersonalID} #{available.count} #{available[image_id]}"
      image_data = File.read(available[image_id])
    end

    # These need to be flagged as available in the Window. Since we cache these
    # in the file-system, we'll only show those that would be available to people
    # with window access
    def local_client_image_data
      headshot = client_files.window.tagged_with('Client Headshot').order(updated_at: :desc).limit(1)&.first rescue nil
      headshot.as_thumb if headshot
    end

    def accessible_via_api?
      GrdaWarehouse::Config.get(:eto_api_available) && source_api_ids.exists?
    end
    # If we have source_api_ids, but are lacking hmis_clients
    # or our hmis_clients are out of date
    def requires_api_update?(check_period: 1.day)
      return false unless accessible_via_api?
      api_ids = source_api_ids.count
      return true if api_ids > source_hmis_clients.count
      last_updated = source_hmis_clients.pluck(:updated_at).max
      if last_updated.present?
        return last_updated < check_period.ago
      end
      true
    end

    def update_via_api
      return nil unless accessible_via_api?
      client_ids = source_api_ids.pluck(:client_id)
      if client_ids.any?
        Importing::RunEtoApiUpdateForClientJob.perform_later(destination_id: id, client_ids: client_ids.uniq)
      end
    end

    def accessible_via_qaaws?
      GrdaWarehouse::Config.get(:eto_api_available) && source_eto_client_lookups.exists?
    end

    def fetch_updated_source_hmis_clients
      return nil unless accessible_via_qaaws?
      source_eto_client_lookups.map do |api_client|
        api_config = EtoApi::Base.api_configs.detect{|_, m| m['data_source_id'] == api_client.data_source_id}
        next unless api_config
        key = api_config.first
        api = EtoApi::Detail.new(api_connection: key)
        EtoApi::Tasks::UpdateEtoData.new.fetch_demographics(
          api: api,
          client_id: api_client.client_id,
          participant_site_identifier: api_client.participant_site_identifier,
          site_id: api_client.site_id,
          subject_id: api_client.subject_id,
          data_source_id: api_client.data_source_id,
        )
      end.compact
    end

    def fetch_updated_source_hmis_forms
      return nil unless accessible_via_qaaws?
      source_eto_touch_point_lookups.map do |api_touch_point|
        api_config = EtoApi::Base.api_configs.detect{|_, m| m['data_source_id'] == api_touch_point.data_source_id}
        next unless api_config
        key = api_config.first
        api = EtoApi::Detail.new(api_connection: key)
        EtoApi::Tasks::UpdateEtoData.new.fetch_touch_point(
          api: api,
          client_id: api_touch_point.client_id,
          touch_point_id: api_touch_point.assessment_id,
          site_id: api_touch_point.site_id,
          subject_id: api_touch_point.subject_id,
          response_id: api_touch_point.response_id,
          data_source_id: api_touch_point.data_source_id,
        )
      end.compact
    end

    def api_status
      return nil unless accessible_via_api?
      most_recent_update = (source_hmis_clients.pluck(:updated_at) + [api_last_updated_at]).compact.max
      updating = api_update_in_process
      # if we think we're updating, but we've been at it for more than 15 minutes
      # something probably got stuck
      if updating
        updating = api_update_started_at > 15.minutes.ago
      end
      {
        started_at: api_update_started_at,
        updated_at: most_recent_update,
        updating: updating,
      }
    end

    # A useful array of hashes from API data
    def caseworkers(can_view_client_user_assignments: false)
      @caseworkers ||= [].tap do |m|
        # Caseworkers from HMIS
        source_hmis_clients.each do |c|
          staff_types.each do |staff_type|
            staff_name = c["#{staff_type}_name"]
            staff_attributes = c["#{staff_type}_attributes"]

            if staff_name.present?
              m << {
                title: staff_type.to_s.titleize,
                name: staff_name,
                phone: staff_attributes.try(:[], 'GeneralPhoneNumber'),
                source: 'HMIS',
              }
            end
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
      hmis_pregnancy = source_health_and_dvs.where(PregnancyStatus: 1).
        where(hdv_t[:InformationDate].gt(one_year_ago).
          or(hdv_t[:DueDate].gt(Date.current - 3.months))).exists?
      vispdat_pregnancy = vispdats.completed.where(pregnant_answer: 1, submitted_at: in_last_year).exists?
      eto_pregnancy = source_hmis_forms.vispdat.
        vispdat_pregnant.
        where(collected_at: in_last_year).
        exists?

      hmis_pregnancy || vispdat_pregnancy || eto_pregnancy
    end

    def staff_types
      [:case_manager, :assigned_staff, :counselor, :outreach_counselor]
    end

    def self.sort_options
      [
        {title: 'Last name A-Z', column: 'LastName', direction: 'asc'},
        {title: 'Last name Z-A', column: 'LastName', direction: 'desc'},
        {title: 'First name A-Z', column: 'FirstName', direction: 'asc'},
        {title: 'First name Z-A', column: 'FirstName', direction: 'desc'},
        {title: 'Youngest to Oldest', column: 'DOB', direction: 'desc'},
        {title: 'Oldest to Youngest', column: 'DOB', direction: 'asc'},
        {title: 'Most served', column: 'days_served', direction: 'desc'},
        {title: 'Recently added', column: 'first_date_served', direction: 'desc'},
        {title: 'Longest standing', column: 'first_date_served', direction: 'asc'},
        {title: 'Most recently served', column: 'last_date_served', direction: 'desc'},
      ]
    end

    def self.cas_columns
      @cas_columns ||= {
        disability_verified_on: _('Disability Verification on File'),
        housing_release_status: _('Housing Release Status'),
        full_housing_release: _('Full HAN Release on File'),
        limited_cas_release: _('Limited CAS Release on File'),
        sync_with_cas: _('Available for matching in CAS'),
        dmh_eligible: _('DMH Eligible'),
        va_eligible: _('VA Eligible'),
        hues_eligible: _('HUES Eligible'),
        hiv_positive: _('HIV+'),
        chronically_homeless_for_cas: _('Chronically Homeless for CAS'),
        us_citizen: _('U.S Citizen or Permanent Resident'),
        asylee: _('Asylee, Refugee'),
        ineligible_immigrant: _('Ineligible Immigrant (Including Undocumented)'),
        lifetime_sex_offender: _('Life-Time Sex Offender'),
        meth_production_conviction: _('Meth Production Conviction'),
        family_member: _('Part of a family'),
        child_in_household: _('Children under age 18 in household'),
        ha_eligible: _('Housing Authority Eligible'),
        cspech_eligible: _('CSPECH Eligible'),
        congregate_housing: _('Willing to live in congregate housing'),
        sober_housing: _('Appropriate for sober supportive housing'),
        requires_wheelchair_accessibility: _('Requires wheelchair accessible unit'),
        required_number_of_bedrooms: _('Minimum number of bedrooms'),
        required_minimum_occupancy: _('Minimum occupancy'),
        requires_elevator_access: _('Requires ground floor unit or elevator access'),
        cas_match_override: _('Override CAS Match Date'),
        vash_eligible: _('VASH Eligible'),
      }
    end

    def self.manual_cas_columns
      cas_columns.except(:hiv_positive, :dmh_eligible, :chronically_homeless_for_cas, :full_housing_release, :limited_cas_release, :housing_release_status, :sync_with_cas, :hues_eligible, :disability_verified_on, :required_number_of_bedrooms, :required_minimum_occupancy, :cas_match_override).
        keys
    end

    def self.file_cas_columns
      cas_columns.except(:hiv_positive, :dmh_eligible, :chronically_homeless_for_cas, :full_housing_release, :limited_cas_release, :housing_release_status, :sync_with_cas, :hues_eligible, :disability_verified_on, :ha_eligible, :required_number_of_bedrooms, :required_minimum_occupancy, :cas_match_override).
        keys
    end

    def self.housing_release_options
      options = [full_release_string]
      options << partial_release_string if GrdaWarehouse::Config.get(:allow_partial_release)
      options
    end

    def self.cas_readiness_parameters
      cas_columns.keys + [
        :housing_assistance_network_released_on,
        :vispdat_prioritization_days_homeless,
        :verified_veteran_status,
        :interested_in_set_asides,
        :rrh_desired,
        :youth_rrh_desired,
        :neighborhood_interests => [],
      ]
    end

    def invalidate_service_history
      if processed_service_history.present?
        processed_service_history.destroy
      end
    end

    def service_history_invalidated?
      processed_service_history.blank?
    end

    def destination?
      source_clients.size > 0
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
      [self.FirstName,self.MiddleName,self.LastName].select(&:present?).join(' ')
    end

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
        query = service_history_services.select( shs_t[:date].minimum, shs_t[:date].maximum )
        service_history_services.connection.select_rows(query.to_sql).first.map{ |m| m.try(:to_date) }
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
      service_history_services.homeless(chronic_types_only: true).
        from(GrdaWarehouse::ServiceHistoryService.quoted_table_name).
        maximum(:date)
    end

    def confidential_project_ids
      @confidential_project_ids ||= GrdaWarehouse::Hud::Project.confidential.pluck(:ProjectID, :data_source_id)
    end

    def project_confidential?(project_id:, data_source_id:)
      confidential_project_ids.include?([project_id, data_source_id])
    end

    def last_homeless_visits include_confidential_names: false
      service_history_enrollments.homeless.ongoing.
        joins(:service_history_services, :project).
        group(:project_name, p_t[:confidential]).
        maximum("#{GrdaWarehouse::ServiceHistoryService.quoted_table_name}.date").
        map do |(project_name, confidential), date|
          unless include_confidential_names
            project_name = GrdaWarehouse::Hud::Project.confidential_project_name if confidential
          end
          [project_name, date]
        end
    end

    def last_projects_served_by(include_confidential_names: false)
      sh = service_history_services.joins(:service_history_enrollment).
        pluck(:date, Arel.sql(she_t[:project_name].to_sql), Arel.sql(she_t[:data_source_id].to_sql), :project_id).
        group_by(&:first).
        max_by(&:first)
      return [] unless sh.present?
      sh.last.map do |_,project_name, data_source_id, project_id|
        confidential = project_confidential?(project_id: project_id, data_source_id: data_source_id)
        if ! confidential || include_confidential_names
          project_name
        else
          GrdaWarehouse::Hud::Project.confidential_project_name
        end
      end.uniq.sort
    end

    def weeks_of_service
      total_days_of_service / 7 rescue 'unknown'
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
            i << {start: "#{y}-#{m}-01"}
          end
        end
      end
    end

    def self.without_service_history
      sh  = GrdaWarehouse::WarehouseClientsProcessed
      sht = sh.arel_table
      where(
        sh.where( sht[:client_id].eq arel_table[:id] ).arel.exists.not
      )
    end

    def total_days_of_service
      ((date_of_last_service - date_of_first_service).to_i + 1) rescue 'unknown'
    end

    def self.ransackable_scopes(auth_object = nil)
      [:full_text_search]
    end

    def self.text_search(text, client_scope:)
      return none unless text.present?
      text.strip!
      sa = source.arel_table
      alpha_numeric = /[[[:alnum:]]-]+/.match(text).try(:[], 0) == text
      numeric = /[\d-]+/.match(text).try(:[], 0) == text
      date = /\d\d\/\d\d\/\d\d\d\d/.match(text).try(:[], 0) == text
      social = /\d\d\d-\d\d-\d\d\d\d/.match(text).try(:[], 0) == text
      # Explicitly search for only last, first if there's a comma in the search
      if text.include?(',')
        last, first = text.split(',').map(&:strip)
        if last.present?
          where = sa[:LastName].lower.matches("#{last.downcase}%")
        end
        if last.present? && first.present?
          where = where.and(sa[:FirstName].lower.matches("#{first.downcase}%"))
        elsif first.present?
          where = sa[:FirstName].lower.matches("#{first.downcase}%")
        end
      # Explicity search for "first last"
      elsif text.include?(' ')
        first, last = text.split(' ').map(&:strip)
        where = sa[:FirstName].lower.matches("#{first.downcase}%")
          .and(sa[:LastName].lower.matches("#{last.downcase}%"))
      # Explicitly search for a PersonalID
      elsif alpha_numeric && (text.size == 32 || text.size == 36)
        where = sa[:PersonalID].matches(text.gsub('-', ''))
      elsif social
        where = sa[:SSN].eq(text.gsub('-',''))
      elsif date
        (month, day, year) = text.split('/')
        where = sa[:DOB].eq("#{year}-#{month}-#{day}")
      elsif numeric
        where = sa[:PersonalID].eq(text).or(sa[:id].eq(text))
      else
        query = "%#{text}%"
        alt_names = UniqueName.where(double_metaphone: Text::Metaphone.double_metaphone(text).to_s).map(&:name)
        nicks = Nickname.for(text).map(&:name)
        where = sa[:FirstName].matches(query)
          .or(sa[:LastName].matches(query))
        if nicks.any?
          nicks_for_search = nicks.map{|m| GrdaWarehouse::Hud::Client.connection.quote(m)}.join(",")
          where = where.or(nf('LOWER', [arel_table[:FirstName]]).in(nicks_for_search))
        end
        if alt_names.present?
          alt_names_for_search = alt_names.map{|m| GrdaWarehouse::Hud::Client.connection.quote(m)}.join(",")
          where = where.or(nf('LOWER', [arel_table[:FirstName]]).in(alt_names_for_search)).
            or(nf('LOWER', [arel_table[:LastName]]).in(alt_names_for_search))
        end
      end
      begin
        client_ids = client_scope.
          joins(:warehouse_client_source).searchable.
          where(where).
          preload(:destination_client).
          map{|m| m.destination_client.id}
      rescue RangeError => e
        return none
      end

      client_ids << text if numeric && self.destination.where(id: text).exists?
      where(id: client_ids)
    end

    # Must match 3 of four First Name, Last Name, SSN, DOB
    # SSN can be full 9 or last 4
    # Names can potentially be switched.
    def self.strict_search(criteria, client_scope: none)
      first_name = criteria[:first_name]&.strip&.gsub(/[^a-z0-9]/i, '')
      last_name = criteria[:last_name]&.strip&.gsub(/[^a-z0-9]/i, '')
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

      first_name_ids = source.where(
        nf('LOWER', [arel_table[:FirstName]]).eq(first_name.downcase)
      ).pluck(:id) if first_name.present?

      last_name_ids = source.where(
        nf('LOWER', [arel_table[:LastName]]).eq(last_name.downcase)
      ).pluck(:id) if last_name.present?

      dob_ids = source.where(
        arel_table[:DOB].eq(dob)
      ).pluck(:id) if dob.present?

      if ssn.length == 9
        ssn_ids = source.where(
          arel_table[:SSN].eq(ssn)
        ).pluck(:id)
      elsif ssn.length == 4
        ssn_ids = source.where(
          arel_table[:SSN].matches("%#{ssn}")
        ).pluck(:id)
      end

      all_ids = first_name_ids + last_name_ids + dob_ids + ssn_ids
      matching_ids = all_ids.each_with_object(Hash.new(0)) { |id, counts| counts[id] += 1 }.select{|_, counts| counts >= 3}&.keys

      begin
        ids = client_scope.
          joins(:warehouse_client_source).searchable.
          where(id: matching_ids).
          preload(:destination_client).
          map{|m| m.destination_client.id}
        where(id: ids)
      rescue RangeError => e
        return none
      end
    end

    def gender
      ::HUD.gender(self.Gender)
    end

    def self.age date:, dob:
      return nil unless date.present? && dob.present?
      age = date.year - dob.year
      age -= 1 if dob > date.years_ago(age)
      return age
    end

    def age date=Date.current
      return unless attributes['DOB'].present?
      date = date.to_date
      dob = attributes['DOB'].to_date
      self.class.age(date: date, dob: dob)
    end
    alias_method :age_on, :age

    def uuid
      @uuid ||= if data_source&.munged_personal_id
        self.PersonalID.split(/(\w{8})(\w{4})(\w{4})(\w{4})(\w{12})/).reject{ |c| c.empty? || c == '__#' }.join('-')
      else
        self.PersonalID
      end
    end

    def self.uuid personal_id
      personal_id.split(/(\w{8})(\w{4})(\w{4})(\w{4})(\w{12})/).reject{ |c| c.empty? || c == '__#' }.join('-')
    end

    def veteran?
      self.VeteranStatus == 1
    end

    def ever_veteran?
      source_clients.map(&:veteran?).include?(true)
    end

    def adjust_veteran_status
      self.VeteranStatus = if verified_veteran_status == 'non_veteran'
        0
      elsif ever_veteran?
        1
      else
        source_clients.order(DateUpdated: :desc).limit(1).pluck(:VeteranStatus).first
      end
      save()
      self.class.clear_view_cache(self.id)
    end

    # those columns that relate to race
    def self.race_fields
      %w( AmIndAKNative Asian BlackAfAmerican NativeHIOtherPacific White RaceNone )
    end

    # those race fields which are marked as pertinent to the client
    def race_fields
      self.class.race_fields.select{ |f| send(f).to_i == 1 }
    end

    def race_description
      race_fields.map{ |f| ::HUD::race f }.join ', '
    end

    def cas_primary_race_code
      race_text = ::HUD::race(race_fields.first)
      Cas::PrimaryRace.find_by_text(race_text).try(:numeric)
    end

    # call this on GrdaWarehouse::Hud::Client.new() instead of self, to take
    # advantage of caching
    def race_string scope_limit: self.class.destination, destination_id:
      limited_scope = self.class.destination.merge(scope_limit)

      @race_am_ind_ak_native ||= limited_scope.where(
        id: self.class.race_am_ind_ak_native.select(:id)
      ).distinct.pluck(:id)
      @race_asian ||= limited_scope.where(
        id: self.class.race_asian.select(:id)
      ).distinct.pluck(:id)
      @race_black_af_american ||= limited_scope.where(
        id: self.class.race_black_af_american.select(:id)
      ).distinct.pluck(:id)
      @race_native_hi_other_pacific ||= limited_scope.where(
        id: self.class.race_native_hi_other_pacific.select(:id)
      ).distinct.pluck(:id)
      @race_white ||= limited_scope.where(
        id: self.class.race_white.select(:id)
      ).distinct.pluck(:id)
      if (@race_am_ind_ak_native + @race_asian + @race_black_af_american + @race_native_hi_other_pacific + @race_white).count(destination_id) > 1
        return 'MultiRacial'
      end
      return 'AmIndAKNative' if @race_am_ind_ak_native.include?(destination_id)
      return 'Asian' if @race_asian.include?(destination_id)
      return 'BlackAfAmerican' if @race_black_af_american.include?(destination_id)
      return 'NativeHIOtherPacific' if @race_native_hi_other_pacific.include?(destination_id)
      return 'White' if @race_white.include?(destination_id)
      return 'RaceNone'
    end

    def self_and_sources
      if destination?
        [ self, *self.source_clients ]
      else
        [self]
      end
    end

    def primary_caseworkers
      staff.merge(GrdaWarehouse::HMIS::StaffXClient.primary_caseworker)
    end

    # convert all clients to the appropriate destination client
    def normalize_to_destination
      if destination?
        self
      else
        self.destination_client
      end
    end

    def previous_permanent_locations
      source_enrollments.any_address.sort_by(&:EntryDate).map(&:address_lat_lon).uniq
    end

    def previous_permanent_locations_for_display(user)
      labels = ('A'..'Z').to_a
      seen_addresses = {}
      addresses_from_enrollments = source_enrollments.visible_in_window_to(user).
        any_address.
        order(EntryDate: :desc).
        preload(:client).
        map do |enrollment|
          lat_lon = enrollment.address_lat_lon
          address = {
            year: enrollment.EntryDate.year,
            client_id: enrollment.client.id,
            label: seen_addresses[enrollment.address] ||= labels.shift,
            city: enrollment.LastPermanentCity,
            state: enrollment.LastPermanentState,
            zip: enrollment.LastPermanentZIP.try(:rjust, 5, '0'),
          }
          if lat_lon.present?
            address.merge!(lat_lon)
          end
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
          file = OpenStruct.new({
            updated_at: file_added,
            available: file_added.present?,
            name: tag.name,
          })
          @document_readiness << file
        end
        @document_readiness.sort_by!(&:name)
      end
    end

    def document_ready?(required_documents)
      @document_ready ||= document_readiness(required_documents).all?{|m| m.available}
    end

    # Build a set of potential client matches grouped by criteria
    # FIXME: consolidate this logic with merge_candidates below
    def potential_matches
      @potential_matches ||= begin
        {}.tap do |m|
          c_arel = self.class.arel_table
          # Find anyone with a nickname match
          nicks = Nickname.for(self.FirstName).map(&:name)

          if nicks.any?
            nicks_for_search = nicks.map{|m| GrdaWarehouse::Hud::Client.connection.quote(m)}.join(",")
            similar_destinations = self.class.destination.where(
              nf('LOWER', [c_arel[:FirstName]]).in(nicks_for_search)
            ).where(c_arel['LastName'].matches("%#{self.LastName.downcase}%")).
            where.not(id: self.id)
            m[:by_nickname] = similar_destinations if similar_destinations.any?
          end
          # Find anyone with similar sounding names
          alt_first_names = UniqueName.where(double_metaphone: Text::Metaphone.double_metaphone(self.FirstName).to_s).map(&:name)
          alt_last_names = UniqueName.where(double_metaphone: Text::Metaphone.double_metaphone(self.LastName).to_s).map(&:name)
          alt_names = alt_first_names + alt_last_names
          if alt_names.any?
            alt_names_for_search = alt_names.map{|m| GrdaWarehouse::Hud::Client.connection.quote(m)}.join(",")
            similar_destinations = self.class.destination.where(
              nf('LOWER', [c_arel[:FirstName]]).in(alt_names_for_search).
                and(nf('LOWER', [c_arel[:LastName]]).matches('#{self.LastName.downcase}%')).
              or(nf('LOWER', [c_arel[:LastName]]).in(alt_names_for_search).
                and(nf('LOWER', [c_arel[:FirstName]]).matches('#{self.FirstName.downcase}%'))
              )
            ).where.not(id: self.id)
            m[:where_the_name_sounds_similar] = similar_destinations if similar_destinations.any?
          end
          # Find anyone with similar sounding names
          # similar_destinations = self.class.where(id: GrdaWarehouse::WarehouseClient.where(source_id:  self.class.source.where("difference(?, FirstName) > 1", self.FirstName).where('LastName': self.class.source.where('soundex(LastName) = soundex(?)', self.LastName).select('LastName')).where.not(id: source_clients.pluck(:id)).pluck(:id)).pluck(:destination_id))
          # m[:where_the_name_sounds_similar] = similar_destinations if similar_destinations.any?
        end
      end

      # TODO
      # Soundex on names
      # William/Bill/Will

      # Others
    end

    # find other clients with similar names
    def merge_candidates(scope=self.class.source)

      # skip self and anyone already known to be related
      scope = scope.where.not( id: source_clients.map(&:id) + [ id, destination_client.try(&:id) ] )

      # some convenience stuff to clean the code up
      at = self.class.arel_table

      diff_full = nf(
        'DIFFERENCE', [
          ct( cl( at[:FirstName], '' ), cl( at[:MiddleName], '' ), cl( at[:LastName], '' ) ),
          name
        ],
        'diff_full'
      )
      diff_last  = nf( 'DIFFERENCE', [ cl( at[:LastName], '' ), last_name || '' ], 'diff_last' )
      diff_first = nf( 'DIFFERENCE', [ cl( at[:LastName], '' ), first_name || '' ], 'diff_first' )

      # return a scope return clients plus their "difference" from this client
      scope.select( Arel.star, diff_full, diff_first, diff_last ).order('diff_full DESC, diff_last DESC, diff_first DESC')
    end

    # Move source clients to this destination client
    # other_client can be a single source record or a destination record
    # if it's a destination record, all of its sources will move and it will be deleted
    #
    # returns the source client records that moved
    def merge_from(other_client, reviewed_by:, reviewed_at: , client_match_id: nil)
      raise 'only works for destination_clients' unless self.destination?
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
          m.warehouse_client_source.update_attributes!(
            destination_id: self.id,
            reviewed_at: reviewed_at,
            reviewd_by: reviewed_by.id,
            client_match_id: client_match_id,
          )
          moved << m
        end
        # if we are a source, move us
        if other_client.warehouse_client_source
          other_client.warehouse_client_source.update_attributes!(
            destination_id: self.id,
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
          current_cas_columns = self.attributes.slice(*self.class.cas_columns.keys.map(&:to_s))
          current_cas_columns.merge!(previous_cas_columns){ |k, old, new| old.presence || new}
          self.update(current_cas_columns)
          self.save()
          prev_destination_client.force_full_service_history_rebuild
          prev_destination_client.source_clients.reload
          if prev_destination_client.source_clients.empty?
            # Create a client_merge_history record so we can keep links working
            GrdaWarehouse::ClientMergeHistory.create(merged_into: id, merged_from: prev_destination_client.id)
            prev_destination_client.delete
          end

          move_dependent_items(prev_destination_client.id, self.id)

        end
        # and invalidate our own service history
        force_full_service_history_rebuild
        # and invalidate any cache for these clients
        self.class.clear_view_cache(prev_destination_client.id)
      end
      self.class.clear_view_cache(self.id)
      self.class.clear_view_cache(other_client.id)
      # un-match anyone who we just moved so they don't show up in the matching again until they've been checked
      moved.each do |m|
        GrdaWarehouse::ClientMatch.processed_or_candidate.
          where(source_client_id: m.id).destroy_all
        GrdaWarehouse::ClientMatch.processed_or_candidate.
          where(destination_client_id: m.id).destroy_all
      end
      moved
    end

    def move_dependent_items previous_id, new_id
      move_dependent_hmis_items previous_id, new_id
      move_dependent_health_items previous_id, new_id
    end

    def move_dependent_hmis_items previous_id, new_id
      # move any client notes
      GrdaWarehouse::ClientNotes::Base.where(client_id: previous_id).
        update_all(client_id: new_id)

      # move any client files
      GrdaWarehouse::ClientFile.where(client_id: previous_id).
        update_all(client_id: new_id)

      # move any patients
      Health::Patient.where(client_id: previous_id).
        update_all(client_id: new_id)

      # move any health files (these should really be attached to patients)
      Health::HealthFile.where(client_id: previous_id).
        update_all(client_id: new_id)

      # move any vi-spdats
      GrdaWarehouse::Vispdat::Base.where(client_id: previous_id).
        update_all(client_id: new_id)

      # move any cohort_clients
      GrdaWarehouse::CohortClient.where(client_id: previous_id).
        update_all(client_id: new_id)

      # Chronics
      GrdaWarehouse::Chronic.where(client_id: previous_id).
        update_all(client_id: new_id)
      GrdaWarehouse::HudChronic.where(client_id: previous_id).
        update_all(client_id: new_id)

      # Relationships
      GrdaWarehouse::UserClient.where(client_id: previous_id).
        update_all(client_id: new_id)

      # Enrollment Histories
      GrdaWarehouse::EnrollmentChangeHistory.where(client_id: previous_id).
        update_all(client_id: new_id)

      # CAS activity
      GrdaWarehouse::CasAvailability.where(client_id: previous_id).
        update_all(client_id: new_id)

      # Youth Intakes
      GrdaWarehouse::YouthIntake::Base.where(client_id: previous_id).
        update_all(client_id: new_id)
      GrdaWarehouse::Youth::DirectFinancialAssistance.where(client_id: previous_id).
        update_all(client_id: new_id)
      GrdaWarehouse::Youth::YouthCaseManagement.where(client_id: previous_id).
        update_all(client_id: new_id)
      GrdaWarehouse::Youth::YouthReferral.where(client_id: previous_id).
        update_all(client_id: new_id)
      GrdaWarehouse::Youth::YouthFollowUp.where(client_id: previous_id).
        update_all(client_id: new_id)
    end

    def move_dependent_health_items previous_id, new_id
      # move any patients
      Health::Patient.where(client_id: previous_id).
        update_all(client_id: new_id)

      # move any health files (these should really be attached to patients)
      Health::HealthFile.where(client_id: previous_id).
        update_all(client_id: new_id)
    end

    def force_full_service_history_rebuild
      service_history_enrollments.where(record_type: [:entry, :exit, :service, :extrapolated]).delete_all
      source_enrollments.update_all(processed_as: nil)
      invalidate_service_history
    end

    def self.clear_view_cache(id)
      return if Rails.env.test?
      Rails.cache.delete_matched("*clients/#{id}/*")
    end

    def most_recent_vispdat
      vispdats.completed.first
    end

    # Fetch most recent VI-SPDAT from the warehouse,
    # if not available use the most recent ETO VI-SPDAT
    # The ETO VI-SPDAT are prioritized by max score on the most recent assessment
    # NOTE: if we have more than one VI-SPDAT on the same day, the calculation is complicated
    def most_recent_vispdat_score
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
          map{|m| m.drop(1)}&.
          flatten&.
          compact&.
          max
    end

    # NOTE: if we have more than one VI-SPDAT on the same day, the calculation is complicated
    def most_recent_vispdat_length_homeless_in_days
      begin
        vispdats.completed.order(submitted_at: :desc).limit(1).first&.days_homeless ||
         source_hmis_forms.vispdat.newest_first.
          map{|m| [m.collected_at, m.vispdat_days_homeless]}&.
          group_by(&:first)&.
          first&.
          last&.
          map{|m| m.drop(1)}&.
          flatten&.
          compact&.
          max || 0
      rescue
        0
      end
    end

    def days_homeless_for_vispdat_prioritization
      vispdat_prioritization_days_homeless || days_homeless_in_last_three_years
    end

    def calculate_vispdat_priority_score
      vispdat_score = most_recent_vispdat_score
      return nil unless vispdat_score.present?
      if GrdaWarehouse::Config.get(:vispdat_prioritization_scheme) == 'veteran_status'
        prioritization_bump = 0
        if veteran?
          prioritization_bump = 100
        end
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

    def max_days_homeless_in_last_three_years(on_date: Date.current)
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

    def max_literally_homeless_last_three_years(on_date: Date.current)
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
      Rails.cache.fetch([client_id, "dates_homeless_in_last_three_years_scope", on_date], expires_in: CACHE_EXPIRY) do
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
      Rails.cache.fetch([client_id, "dates_literally_homeless_in_last_three_years_scope", on_date], expires_in: CACHE_EXPIRY) do
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
      Rails.cache.fetch([client_id, "dates_homeless_in_last_year_scope", on_date], expires_in: CACHE_EXPIRY) do
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
      Rails.cache.fetch([client_id, "dates_literally_homeless_in_last_year_scope", on_date], expires_in: CACHE_EXPIRY) do
        end_date = on_date.to_date
        start_date = end_date - 1.years
        GrdaWarehouse::ServiceHistoryService.where(client_id: client_id).
          homeless.
          where(date: start_date..end_date).
          where.not(date: dates_hud_non_chronic_residential_last_three_years_scope(client_id: client_id)).
          select(:date).distinct
      end
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
        map{ |date| [date.month, date.year]}.uniq
    end

    def months_homeless_in_last_three_years(on_date: Date.current)
      homeless_months_in_last_three_years(on_date: on_date).count
    end

    def homeless_months_in_last_year(on_date: Date.current)
      self.class.dates_homeless_in_last_year_scope(client_id: id, on_date: on_date).
        pluck(:date).
        map{ |date| [date.month, date.year]}.uniq
    end

    def months_homeless_in_last_year(on_date: Date.current)
      homeless_months_in_last_year(on_date: on_date).count
    end

    def literally_homeless_months_in_last_three_years(on_date: Date.current)
      self.class.dates_literally_homeless_in_last_three_years_scope(client_id: id, on_date: on_date).
        pluck(:date).
        map{ |date| [date.month, date.year]}.uniq
    end

    def months_literally_homeless_in_last_three_years(on_date: Date.current)
      literally_homeless_months_in_last_three_years(on_date: on_date).count
    end

    def literally_homeless_months_in_last_year(on_date: Date.current)
      self.class.dates_literally_homeless_in_last_year_scope(client_id: id, on_date: on_date).
        pluck(:date).
        map{ |date| [date.month, date.year]}.uniq
    end

    def months_literally_homeless_in_last_year(on_date: Date.current)
      literally_homeless_months_in_last_year(on_date: on_date).count
    end

    def self.dates_housed_scope(client_id:, on_date: Date.current)
      GrdaWarehouse::ServiceHistoryService.non_homeless.
        where(client_id: client_id).select(:date).distinct
    end

    def self.dates_homeless(client_id:, on_date: Date.current)
      Rails.cache.fetch([client_id, "dates_homeless", on_date], expires_in: CACHE_EXPIRY) do
        dates_homeless_scope(client_id: client_id, on_date: on_date).pluck(:date)
      end
    end

    def self.days_homeless(client_id:, on_date: Date.current)
      Rails.cache.fetch([client_id, "days_homeless", on_date], expires_in: CACHE_EXPIRY) do
        dates_homeless_scope(client_id: client_id, on_date: on_date).count
      end
    end

    def days_homeless(on_date: Date.current)
      # attempt to pull this from previously calculated data
      processed_service_history&.homeless_days&.presence || self.class.days_homeless(client_id: id, on_date: on_date)
    end

    def max_days_homeless(on_date: Date.current)
      days = [days_homeless(on_date: Date.current)]
      days += cohort_clients.where(cohort_id: active_cohort_ids).where.not(adjusted_days_homeless: nil).
        pluck(:adjusted_days_homeless)
      days.compact.max
    end

    # Use the Pathways value if it is present and non-zero
    # Otherwise, pull the maximum total monthly income from any open enrollments, looking
    # only at the most recent assessment per enrollment
    def max_current_total_monthly_income
      return income_total_monthly if income_total_monthly.present? && income_total_monthly.positive?

      source_enrollments.open_on_date(Date.current).map do |enrollment|
        enrollment.income_benefits.limit(1).
          order(InformationDate: :desc).
          pluck(:TotalMonthlyIncome).first
        end.compact.max || 0
    end

    def homeless_dates_for_chronic_in_past_three_years(date: Date.current)
      GrdaWarehouse::Tasks::ChronicallyHomeless.new(
        date: date.to_date,
        dry_run: true,
        client_ids: [id]
        ).residential_history_for_client(client_id: id)
    end

    def homeless_episodes_between start_date:, end_date:
      enrollments = service_history_enrollments.residential.entry.order(first_date_in_program: :asc)
      return 0 unless enrollments.any?
      chronic_enrollments = service_history_enrollments.entry.
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
        new_episode?(enrollments: enrollments, enrollment: enrollment)
      end.count(true) + episode_count
    end

    def self.service_types
      @service_types ||= begin
        service_types = ['service']
        if GrdaWarehouse::Config.get(:so_day_as_month)
          service_types << 'extrapolated'
        end
        service_types
      end
    end

    def service_types
      self.class.service_types
    end

    # build an array of useful hashes for the enrollments roll-ups
    def enrollments_for en_scope, include_confidential_names: false
      Rails.cache.fetch("clients/#{id}/enrollments_for/#{en_scope.to_sql}/#{include_confidential_names}", expires_in: CACHE_EXPIRY) do

        enrollments = en_scope.joins(:project).
          includes(:service_history_services, :project, :organization, :source_client, enrollment: :enrollment_cocs).
          order(first_date_in_program: :desc)
        enrollments.
        map do |entry|
          project = entry.project
          organization = entry.organization
          services = entry.service_history_services
          project_name = if project.confidential? && ! include_confidential_names
             project.safe_project_name
          else
            cocs = ''
            if GrdaWarehouse::Config.get(:expose_coc_code)
              cocs = entry.enrollment.enrollment_cocs.map(&:CoCCode).uniq.join(', ')
              cocs = " (#{cocs})" if cocs.present?
            end
            "#{entry.project_name} < #{organization.OrganizationName} #{cocs}"
          end
          dates_served = services.select{|m| service_types.include?(m.record_type)}.map(&:date).uniq
          count_until = calculated_end_of_enrollment(enrollment: entry, enrollments: enrollments)
          # days included in adjusted days that are not also served by a residential project
          adjusted_dates_for_similar_programs = adjusted_dates(dates: dates_served, stop_date: count_until)
          homeless_dates_for_enrollment = adjusted_dates_for_similar_programs - residential_dates(enrollments: enrollments)
          most_recent_service = services.sort_by(&:date)&.last&.date
          new_episode = new_episode?(enrollments: enrollments, enrollment: entry)
          {
            client_source_id: entry.source_client.id,
            project_id: project.id,
            ProjectID: project.ProjectID,
            project_name: project_name,
            confidential_project: project.confidential,
            entry_date: entry.first_date_in_program,
            living_situation: entry.enrollment.LivingSituation,
            exit_date: entry.last_date_in_program,
            destination: entry.destination,
            move_in_date_inherited: entry.enrollment.MoveInDate.blank? && entry.move_in_date.present?,
            move_in_date: entry.move_in_date,
            days: dates_served.count,
            homeless: entry.computed_project_type.in?(Project::HOMELESS_PROJECT_TYPES),
            homeless_days: homeless_dates_for_enrollment.count,
            adjusted_days: adjusted_dates_for_similar_programs.count,
            months_served: adjusted_months_served(dates: adjusted_dates_for_similar_programs),
            household: self.household(entry.household_id, entry.enrollment.data_source_id),
            project_type: ::HUD::project_type_brief(entry.computed_project_type),
            project_type_id: entry.computed_project_type,
            class: "client__service_type_#{entry.computed_project_type}",
            most_recent_service: most_recent_service,
            new_episode: new_episode,
            enrollment_id: entry.enrollment.EnrollmentID,
            data_source_id: entry.enrollment.data_source_id,
            created_at: entry.enrollment.DateCreated,
            updated_at: entry.enrollment.DateUpdated,
            hmis_id: entry.enrollment.id,
            # support: dates_served,
          }
        end
      end
    end

    def ongoing_enrolled_project_ids
      service_history_enrollments.ongoing.joins(:project).distinct.pluck(p_t[:id].to_sql)
    end

    def ongoing_enrolled_project_types
      @ongoing_enrolled_project_types ||= service_history_enrollments.ongoing.distinct.pluck(GrdaWarehouse::ServiceHistoryEnrollment.project_type_column)
    end

    def enrolled_in_th
     (GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:th] & ongoing_enrolled_project_types).present?
    end
    def enrolled_in_sh
      (GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:sh] & ongoing_enrolled_project_types).present?
    end
    def enrolled_in_so
      (GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:so] & ongoing_enrolled_project_types).present?
    end
    def enrolled_in_es
      (GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:es] & ongoing_enrolled_project_types).present?
    end

    def enrollments_for_rollup en_scope: scope, include_confidential_names: false, only_ongoing: false
      Rails.cache.fetch("clients/#{id}/enrollments_for_rollup/#{en_scope.to_sql}/#{include_confidential_names}/#{only_ongoing}", expires_in: CACHE_EXPIRY) do
        if en_scope.count == 0
          []
        else
          enrollments = enrollments_for(en_scope, include_confidential_names: include_confidential_names)
          enrollments = enrollments.select{|m| m[:exit_date].blank?} if only_ongoing
          enrollments || []
        end
      end
    end

    def total_days enrollments
      enrollments.map{|m| m[:days]}.sum
    end

    def total_homeless enrollments
      enrollments.select do |enrollment|
        enrollment[:homeless]
      end.map{ |m| m[:homeless_days] }.sum
    end

    def total_adjusted_days enrollments
      enrollments.map{|m| m[:adjusted_days]}.sum
    end

    def total_months enrollments
      enrollments.map{|e| e[:months_served]}.flatten(1).uniq.size
    end

    def affiliated_residential_projects enrollment
      @residential_affiliations ||= GrdaWarehouse::Hud::Affiliation.preload(:project, :residential_project).map do |affiliation|
        [
          [affiliation.project&.ProjectID, affiliation.project&.data_source_id],
          affiliation.residential_project&.ProjectName,
        ]
      end.group_by(&:first)
      @residential_affiliations[[enrollment[:ProjectID], enrollment[:data_source_id]]].map(&:last) rescue []
    end

    def affiliated_projects enrollment
      @project_affiliations ||= GrdaWarehouse::Hud::Affiliation.preload(:project, :residential_project).
        map do |affiliation|
        [
          [affiliation.residential_project&.ProjectID, affiliation.residential_project&.data_source_id],
          affiliation.project&.ProjectName,
        ]
      end.group_by(&:first)
      @project_affiliations[[enrollment[:ProjectID], enrollment[:data_source_id]]].map(&:last) rescue []
    end

    def affiliated_projects_str_for_enrollment enrollment
      project_names = affiliated_projects(enrollment)
      if project_names.any?
        "Affiliated with #{project_names.to_sentence}"
      else
        nil
      end
    end

    def residential_projects_str_for_enrollment enrollment
      project_names = affiliated_residential_projects(enrollment)
      if project_names.any?
        "Affiliated with #{project_names.to_sentence}"
      else
        nil
      end
    end

    def program_tooltip_data_for_enrollment enrollment
      affiliated_projects_str = affiliated_projects_str_for_enrollment(enrollment)
      residential_projects_str = residential_projects_str_for_enrollment(enrollment)

      #only show tooltip if there are projects to list
      if affiliated_projects_str.present? || residential_projects_str.present?
        title = [affiliated_projects_str, residential_projects_str].compact.join("\n")
        {toggle: :tooltip, title: "#{title}"}
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
          m.computed_project_type == enrollment.computed_project_type &&
            m.first_date_in_program > enrollment.first_date_in_program
        end.
        sort_by(&:first_date_in_program)&.first&.first_date_in_program || enrollment.last_date_in_program
      end
    end

    private def adjusted_dates dates:, stop_date:
      return dates if stop_date.nil?
      dates.select{|date| date <= stop_date}
    end

    private def residential_dates enrollments:
      @non_homeless_types ||= GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPES[:ph]
      @residential_dates ||= enrollments.select do |e|
        @non_homeless_types.include?(e.computed_project_type)
      end.map do |e|
        e.service_history_services.non_homeless.map(&:date)
     end.flatten.compact.uniq
    end

    private def homeless_dates enrollments:
      @homeless_dates ||= enrollments.select do |e|
        e.computed_project_type.in? GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPE_IDS
      end.map do |e|
       e.service_history_services.homeless.where(record_type: :service).map(&:date)
      end.flatten.compact.uniq
   end

    private def adjusted_months_served dates:
      dates.group_by{ |d| [d.year, d.month] }.keys
    end

    # If we haven't been in a literally homeless project type (ES, SH, SO) in the last 30 days, this is a new episode
    # You aren't currently housed in PH, and you've had at least a week of being housed in the last 90 days
    def new_episode? enrollments:, enrollment:
      return false unless GrdaWarehouse::Hud::Project::CHRONIC_PROJECT_TYPES.include?(enrollment.computed_project_type)
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

  end
end
