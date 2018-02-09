require 'restclient'
module GrdaWarehouse::Hud
  class Client < Base
    include Rails.application.routes.url_helpers
    include RandomScope
    include ArelHelper   # also included by RandomScope, but this makes dependencies clear
    include HealthCharts
    include ApplicationHelper
    include HudSharedScopes
    include HudChronicDefinition

    has_many :client_files
    has_many :vispdats, class_name: 'GrdaWarehouse::Vispdat::Base'
    has_one :cas_project_client, class_name: 'Cas::ProjectClient', foreign_key: :id_in_data_source
    has_one :cas_client, class_name: 'Cas::Client', through: :cas_project_client, source: :client

    self.table_name = 'Client'
    self.hud_key = 'PersonalID'
    acts_as_paranoid(column: :DateDeleted)

    CACHE_EXPIRY = if Rails.env.production? then 4.hours else 2.minutes end


    def self.hud_csv_headers(version: nil)
      [
        "PersonalID",
        "FirstName",
        "MiddleName",
        "LastName",
        "NameSuffix",
        "NameDataQuality",
        "SSN",
        "SSNDataQuality",
        "DOB",
        "DOBDataQuality",
        "AmIndAKNative",
        "Asian",
        "BlackAfAmerican",
        "NativeHIOtherPacific",
        "White",
        "RaceNone",
        "Ethnicity",
        "Gender",
        "OtherGender",
        "VeteranStatus",
        "YearEnteredService",
        "YearSeparated",
        "WorldWarII",
        "KoreanWar",
        "VietnamWar",
        "DesertStorm",
        "AfghanistanOEF",
        "IraqOIF",
        "IraqOND",
        "OtherTheater",
        "MilitaryBranch",
        "DischargeStatus",
        "DateCreated",
        "DateUpdated",
        "UserID",
        "DateDeleted",
        "ExportID"
      ].freeze
    end

    has_paper_trail
    include ArelHelper

    belongs_to :data_source, inverse_of: :clients
    belongs_to :export, **hud_belongs(Export), inverse_of: :clients

    has_one :warehouse_client_source, class_name: GrdaWarehouse::WarehouseClient.name, foreign_key: :source_id, inverse_of: :source
    has_many :warehouse_client_destination, class_name: GrdaWarehouse::WarehouseClient.name, foreign_key: :destination_id, inverse_of: :destination
    has_one :destination_client, through: :warehouse_client_source, source: :destination, inverse_of: :source_clients
    has_many :source_clients, through: :warehouse_client_destination, source: :source, inverse_of: :destination_client
    has_many :window_source_clients, -> {visible_in_window}, through: :warehouse_client_destination, source: :source, inverse_of: :destination_client

    has_one :processed_service_history, -> { where(routine: 'service_history')}, class_name: 'GrdaWarehouse::WarehouseClientsProcessed'
    has_one :first_service_history, -> { where record_type: 'first' }, class_name: GrdaWarehouse::ServiceHistoryEnrollment.name

    has_one :api_id, class_name: GrdaWarehouse::ApiClientDataSourceId.name
    has_one :hmis_client, class_name: GrdaWarehouse::HmisClient.name

    has_many :service_history, class_name: GrdaWarehouse::ServiceHistory.name, inverse_of: :client
    has_many :service_history_enrollments
    has_many :service_history_entries, -> { entry }, class_name: GrdaWarehouse::ServiceHistoryEnrollment.name
    has_many :service_history_entry_in_last_three_years, -> {
      entry_in_last_three_years
    }, class_name: GrdaWarehouse::ServiceHistoryEnrollment.name

    has_many :enrollments, class_name: GrdaWarehouse::Hud::Enrollment.name, foreign_key: [:PersonalID, :data_source_id], primary_key: [:PersonalID, :data_source_id], inverse_of: :client
    has_many :exits, through: :enrollments, source: :exit, inverse_of: :client
    has_many :enrollment_cocs, through: :enrollments, source: :enrollment_cocs, inverse_of: :client
    has_many :services, through: :enrollments, source: :services, inverse_of: :client
    has_many :disabilities, through: :enrollments, source: :disabilities, inverse_of: :client
    has_many :health_and_dvs, through: :enrollments, source: :health_and_dvs, inverse_of: :client
    has_many :income_benefits, through: :enrollments, source: :income_benefits, inverse_of: :client
    has_many :employment_educations, through: :enrollments, source: :employment_educations, inverse_of: :client

    # The following scopes are provided for data cleanup, but should generally not be
    # used, as these relationships should go through enrollments
    has_many :direct_exits, **hud_many(Exit), inverse_of: :direct_client
    has_many :direct_enrollment_cocs, **hud_many(EnrollmentCoc), inverse_of: :direct_client
    has_many :direct_services, **hud_many(Service), inverse_of: :direct_client
    has_many :direct_disabilities, **hud_many(Disability), inverse_of: :direct_client
    has_many :direct_health_and_dvs, **hud_many(HealthAndDv), inverse_of: :direct_client
    has_many :direct_income_benefits, **hud_many(IncomeBenefit), inverse_of: :direct_client
    has_many :direct_employment_educations, **hud_many(EmploymentEducation), inverse_of: :direct_client
    # End cleanup relationships

    has_many :client_attributes_defined_text, class_name: GrdaWarehouse::HMIS::ClientAttributeDefinedText.name, inverse_of: :client
    has_many :hmis_forms, class_name: GrdaWarehouse::HmisForm.name
    has_many :non_confidential_hmis_forms, -> do
      joins(:hmis_forms).where(id: GrdaWarehouse::HmisForm.window.non_confidential.select(:id))
    end, class_name: GrdaWarehouse::HmisForm.name

    has_many :organizations, -> { order(:OrganizationName).uniq }, through: :enrollments
    has_many :source_services, through: :source_clients, source: :services
    has_many :source_enrollments, through: :source_clients, source: :enrollments
    has_many :source_enrollment_cocs, through: :source_clients, source: :enrollment_cocs
    has_many :source_disabilities, through: :source_clients, source: :disabilities
    has_many :source_enrollment_disabilities, through: :source_enrollments, source: :disabilities
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
    has_many :staff_x_clients, class_name: GrdaWarehouse::HMIS::StaffXClient.name, inverse_of: :client
    has_many :staff, class_name: GrdaWarehouse::HMIS::Staff.name, through: :staff_x_clients
    has_many :source_api_ids, through: :source_clients, source: :api_id
    has_many :source_hmis_clients, through: :source_clients, source: :hmis_client
    has_many :source_hmis_forms, through: :source_clients, source: :hmis_forms
    has_many :source_non_confidential_hmis_forms, through: :source_clients, source: :non_confidential_hmis_forms
    has_many :self_sufficiency_assessments, -> { where(name: 'Self-Sufficiency Matrix')}, class_name: GrdaWarehouse::HmisForm.name, through: :source_clients, source: :hmis_forms
    has_many :case_management_notes, -> { where(name: 'SDH Case Management Note')}, class_name: GrdaWarehouse::HmisForm.name, through: :source_clients, source: :hmis_forms
    has_many :health_touch_points, -> do
      f_t = GrdaWarehouse::HmisForm.arel_table
      where(f_t[:collection_location].matches('Social Determinants of Health%'))
    end, class_name: GrdaWarehouse::HmisForm.name, through: :source_clients, source: :hmis_forms
    has_many :cas_reports, class_name: 'GrdaWarehouse::CasReport', inverse_of: :client

    has_many :chronics, class_name: GrdaWarehouse::Chronic.name, inverse_of: :client
    
    has_many :chronics_in_range, -> (range) do
      where(date: range)
    end, class_name: GrdaWarehouse::Chronic.name, inverse_of: :client
    has_one :patient, class_name: Health::Patient.name

    has_many :notes, class_name: GrdaWarehouse::ClientNotes::Base.name, inverse_of: :client
    has_many :chronic_justifications, class_name: GrdaWarehouse::ClientNotes::ChronicJustification.name
    has_many :window_notes, class_name: GrdaWarehouse::ClientNotes::WindowNote.name
    has_many :anomaly_notes, class_name: GrdaWarehouse::ClientNotes::AnomalyNote.name

    has_many :anomalies, class_name: GrdaWarehouse::Anomaly.name
    has_many :cas_houseds, class_name: GrdaWarehouse::CasHoused.name

    has_many :user_clients, class_name: GrdaWarehouse::UserClient.name
    has_many :users, through: :user_clients, inverse_of: :clients, dependent: :destroy

    # Delegations
    delegate :first_homeless_date, to: :processed_service_history
    delegate :last_homeless_date, to: :processed_service_history
    delegate :first_chronic_date, to: :processed_service_history
    delegate :last_chronic_date, to: :processed_service_history
    delegate :first_date_served, to: :processed_service_history
    delegate :last_date_served, to: :processed_service_history
    

    scope :destination, -> do
      where(data_source: GrdaWarehouse::DataSource.destination)
    end
    scope :source, -> do
      where(data_source: GrdaWarehouse::DataSource.importable)
    end

    scope :searchable, -> do
      where(data_source: GrdaWarehouse::DataSource.source)
    end
    # For now, this is way to slow, calculate in ruby
    # scope :unmatched, -> do
    #   source.where.not(id: GrdaWarehouse::WarehouseClient.select(:source_id))
    # end
    # 
         
    scope :child, -> (on: Date.today) do
      where(c_t[:DOB].gt(on - 18.years))
    end
    
    scope :youth, -> (on: Date.today) do
      where(DOB: (on - 24.years .. on - 18.years))
    end
    
    scope :adult, -> (on: Date.today) do
      where(c_t[:DOB].lteq(on - 18.years))
    end
    
    #################################
    # Standard Cohort Scopes    
         
    scope :individual_adult, -> (start_date: Date.today, end_date: Date.today) do
      adult(on: start_date).
      where(id: GrdaWarehouse::ServiceHistoryEnrollment.entry.open_between(start_date: start_date, end_date: end_date).distinct.individual_adult.select(:client_id))
    end

    scope :unaccompanied_youth, -> (start_date: Date.today, end_date: Date.today) do
      youth(on: start_date).
      where(id: GrdaWarehouse::ServiceHistoryEnrollment.entry.open_between(start_date: start_date, end_date: end_date).distinct.unaccompanied_youth.select(:client_id))
    end

    scope :children_only, -> (start_date: Date.today, end_date: Date.today) do
      child(on: start_date).
      where(id: GrdaWarehouse::ServiceHistoryEnrollment.entry.open_between(start_date: start_date, end_date: end_date).distinct.children_only.select(:client_id))
    end

    scope :parenting_youth, -> (start_date: Date.today, end_date: Date.today) do
      youth(on: start_date).
      where(id: GrdaWarehouse::ServiceHistoryEnrollment.entry.open_between(start_date: start_date, end_date: end_date).distinct.parenting_youth.select(:client_id))
    end
    
    scope :parenting_juvenile, -> (start_date: Date.today, end_date: Date.today) do
      youth(on: start_date).
      where(id: GrdaWarehouse::ServiceHistoryEnrollment.entry.open_between(start_date: start_date, end_date: end_date).distinct.parenting_juvenile.select(:client_id))
    end

    scope :family, -> (start_date: Date.today, end_date: Date.today) do
      where(id: GrdaWarehouse::ServiceHistoryEnrollment.entry.open_between(start_date: start_date, end_date: end_date).distinct.family.select(:client_id))
    end
      
    scope :veteran, -> do
      where(VeteranStatus: 1)
    end

    scope :non_veteran, -> do
      where(c_t[:VeteranStatus].not_eq(1).or(c_t[:VeteranStatus].eq(nil)))
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
    scope :disabled, -> do
      dt = Disability.arel_table
      where Disability.where( dt[:data_source_id].eq c_t[:data_source_id] ).where( dt[:PersonalID].eq c_t[:PersonalID] ).exists
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

    scope :visible_in_window, -> do
      joins(:data_source).where(data_sources: {visible_in_window: true})
    end

    scope :has_homeless_service_after_date, -> (date: 31.days.ago) do
      where(id:
        GrdaWarehouse::ServiceHistory.service.homeless(chronic_types_only: true).
        where(sh_t[:date].gt(date)).
        select(:client_id).distinct
      )
    end

    scope :has_homeless_service_between_dates, -> (start_date: 31.days.ago, end_date: Date.today) do
      where(id:
        GrdaWarehouse::ServiceHistory.service.homeless(chronic_types_only: true).
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

    def self.consent_validity_period
      1.years
    end

    def self.revoke_expired_consent
      if release_duration == 'One Year'
        clients_with_consent = self.where.not(consent_form_signed_on: nil)
        clients_with_consent.each do |client|
          if client.consent_form_signed_on < consent_validity_period.ago
            client.update_columns(housing_release_status: nil)
          end
        end
      end
    end

    def alternate_names
      names = client_names.map do |m|
        m[:name]
      end.uniq
      names -= [full_name]
      names.join(',')
    end

    def client_names window: true
      client_scope = if window
        source_clients.visible_in_window
      else
        source_clients
      end
      client_scope.includes(:data_source).map do |m|
        {
          ds: m.data_source.short_name,
          name: m.full_name,
        }
      end
    end

    def deceased?
      deceased_on.present?
    end
    def deceased_on
      @deceased_on ||= source_exits.where(Destination: ::HUD.valid_destinations.invert['Deceased']).pluck(:ExitDate).last
    end

    def active_in_cas?
      case GrdaWarehouse::Config.get(:cas_available_method).to_sym
      when :cas_flag
        sync_with_cas
      when :chronic
        chronics.where(chronics: {date: GrdaWarehouse::Chronic.most_recent_day}).exists?
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
      residential
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

    def window_link_for? user
      if show_window_demographic_to?(user)
        window_client_path(self)
      elsif GrdaWarehouse::Vispdat::Base.any_visible_by?(user)
        window_client_vispdats_path(self)
      elsif GrdaWarehouse::ClientFile.any_visible_by?(user)
        window_client_files_path(self)
      end
    end

    def show_health_for?(user)
      patient.present? && patient.accessible_by_user(user).present?  && GrdaWarehouse::Config.get(:healthcare_available)
    end

    def show_window_demographic_to?(user)
      visible_because_of_permission?(user) || visible_because_of_relationship?(user)
    end

    def visible_because_of_permission?(user)
      (release_valid? || ! GrdaWarehouse::Config.get(:window_access_requires_release)) && user.can_view_client_window?
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

    # Some file tags represent client attributes, 
    # Never trigger the full-release with just a file
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
      # Only convert blank to limited cas and limited to blank, full has been 
      # confirmed by a human
      if self.housing_release_status != self.class.full_release_string
        if client_files.tagged_with(cas_attributes_file_tag_map[:limited_cas_release], any: true).exists?
          self.housing_release_status = self.class.partial_release_string
        else
          self.housing_release_status = nil
        end
      end
      save
    end

    def cas_attributes_file_tag_map
      {
        ha_eligible: [
          'BHA Eligibility',
          'Housing Authority Eligibility',
        ],
        disability_verified_on: [
          'Disability Verification',
        ],
        limited_cas_release: [
          'Limited CAS Release'
        ],
      }
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

    def release_current_status
      if housing_release_status.blank?
        'None on file'
      elsif release_duration == 'One Year'
        if consent_form_valid?
          "Valid Until #{consent_form_signed_on + self.class.consent_validity_period}"
        else
          'Expired'
        end
      else
        _(housing_release_status)
      end
    end

    def release_duration
      @release_duration ||= GrdaWarehouse::Config.get(:release_duration)
    end

    def self.release_duration
      @release_duration ||= GrdaWarehouse::Config.get(:release_duration)
    end
    
    def release_valid?
      housing_release_status == self.class.full_release_string
    end

    def consent_form_valid?
      if release_duration == 'One Year'
        release_valid? && consent_form_signed_on.present? && consent_form_signed_on >= self.class.consent_validity_period.ago
      else
        release_valid?
      end
    end


    # End Release information
    ##############################

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

    def domestic_violence?
      source_health_and_dvs.where(DomesticViolenceVictim: 1).exists?
    end

    def chronic?(on: nil)
      on ||= GrdaWarehouse::Chronic.most_recent_day
      chronics.where(date: on).present?
    end

    def longterm_stayer?
      days = chronics.order(date: :asc)&.last&.days_in_last_three_years || 0
      days >= 365
    end

    def ever_chronic?
      chronics.any?
    end


    def households
      @households ||= begin
        hids = service_history_entries.where.not(household_id: [nil, '']).pluck(:household_id, :data_source_id).uniq
        if hids.any?
          columns = {
            household_id: she_t[:household_id].as('household_id').to_sql,
            date: she_t[:date].as('date').to_sql,
            client_id: she_t[:client_id].as('client_id').to_sql,
            age: she_t[:age].as('age').to_sql,
            enrollment_group_id: she_t[:enrollment_group_id].as('enrollment_group_id').to_sql,
            FirstName: c_t[:FirstName].as('FirstName').to_sql,
            LastName: c_t[:LastName].as('LastName').to_sql,
            last_date_in_program: she_t[:last_date_in_program].as('last_date_in_program').to_sql,
          }
          hh_where = hids.map{|hh_id, ds_id| "(household_id = '#{hh_id}' and #{GrdaWarehouse::ServiceHistoryEnrollment.quoted_table_name}.data_source_id = #{ds_id})"}.join(' or ')
          entries = GrdaWarehouse::ServiceHistoryEnrollment.entry
            .joins(:client)
            .where(hh_where)
            .where.not(client_id: id )
            .pluck(*columns.values).map do |row|
              Hash[columns.keys.zip(row)]
            end.uniq
          entries = entries.map(&:with_indifferent_access).group_by{|m| [m['household_id'], m['date']]}
        end
      end
    end

    def household household_id, date
      households[[household_id, date]] if households.present?
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
        hh.with_indifferent_access.each do |k, h|
          _, date = k
          # client life stage
          child = self.DOB.present? && age_on(date) < 18
          adult = self.DOB.blank? || age_on(date) >= 18
          h.map{|m| m['age']}.uniq.each do |a|
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

    # finds an image for the client. there may be more then one availabe but this
    # method will select one more or less at random. returns no_image_on_file_image
    # if none is found. returns that actual image bytes
    # FIXME: invalidate the cached image if any aspect of the client changes
    def image(cache_for=10.minutes)
      return nil unless GrdaWarehouse::Config.get(:eto_api_available)
      ActiveSupport::Cache::FileStore.new(Rails.root.join('tmp/client_images')).fetch(self.cache_key, expires_in: cache_for) do
        logger.debug "Client#image id:#{self.id} cache_for:#{cache_for} fetching via api"
        image_data = nil
        if Rails.env.production?
          source_api_ids.detect do |api_id|
            api ||= EtoApi::Base.new.tap{|api| api.connect}
            image_data = api.client_image(
              client_id: api_id.id_in_data_source, 
              site_id: api_id.site_id_in_data_source
            ) rescue nil
            (image_data && image_data.length > 0)
          end
        else
          if [0,1].include?(self[:Gender])
            num = id % 99
            gender = if self[:Gender] == 1
              'men'
            else
              'women'
            end
            response = RestClient.get "https://randomuser.me/api/portraits/#{gender}/#{num}.jpg"
            image_data = response.body
          end
        end
        image_data || self.class.no_image_on_file_image
      end
    end

    def image_for_source_client(cache_for=10.minutes)
      return unless GrdaWarehouse::Config.get(:eto_api_available) && source?
      ActiveSupport::Cache::FileStore.new(Rails.root.join('tmp/client_images')).fetch([self.cache_key, self.id], expires_in: cache_for) do
        logger.debug "Client#image id:#{self.id} cache_for:#{cache_for} fetching via api"
        image_data = nil
        if Rails.env.production?
          api ||= EtoApi::Base.new.tap{|api| api.connect}
          image_data = api.client_image(
            client_id: api_id.id_in_data_source,
            site_id: api_id.site_id_in_data_source
          ) rescue nil
          return image_data
        else
          if [0,1].include?(self[:Gender])
            num = id % 99
            gender = if self[:Gender] == 1
              'men'
            else
              'women'
            end
            response = RestClient.get "https://randomuser.me/api/portraits/#{gender}/#{num}.jpg"
            image_data = response.body
          end
        end
        image_data || self.class.no_image_on_file_image
      end
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
        Importing::RunEtoApiUpdateForClientJob.perform_later(destination_id: id, client_ids: client_ids)
      end
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
    def caseworkers
      @caseworkers ||= [].tap do |m|
        source_hmis_clients.each do |c|
          staff_types.each do |staff_type|
            staff_name = c["#{staff_type}_name"]
            staff_attributes = c["#{staff_type}_attributes"]

            if staff_name.present?
              m << {
                title: staff_type.to_s.titleize,
                name: staff_name,
                phone: staff_attributes.try(:[], 'GeneralPhoneNumber'),
              }
            end
          end
        end
      end
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
      }
    end

    def self.housing_release_options
      options = [full_release_string]
      options << partial_release_string if GrdaWarehouse::Config.get(:allow_partial_release)
      options
    end

    def self.cas_readiness_parameters
      cas_columns.keys + [:housing_assistance_network_released_on, :vispdat_prioritization_days_homeless]
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

    def service_date_range
      @service_date_range ||= begin
        at = service_history.arel_table
        query = service_history.service.select( at[:date].minimum, at[:date].maximum )
        service_history.connection.select_rows(query.to_sql).first.map{ |m| m.try(:to_date) }
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
      service_history.homeless(chronic_types_only: true).
        from(GrdaWarehouse::ServiceHistory.quoted_table_name).
        maximum(:date)
    end

    def confidential_project_ids
      @confidential_project_ids ||= GrdaWarehouse::Hud::Project.confidential.pluck(:ProjectID, :data_source_id)
    end

    def project_confidential?(project_id:, data_source_id:)
      confidential_project_ids.include?([project_id, data_source_id])
    end

    def last_projects_served_by(include_confidential_names: false)
      sh = service_history.service.
        pluck(:date, :project_name, :data_source_id, :project_id).
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
      # service_history.where( date: processed_service_history.select(:last_date_served) ).order(:project_name).distinct.pluck(:project_name)
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
        sh.where( sht[:client_id].eq arel_table[:id] ).exists.not
      )
    end

    def total_days_of_service
      ((date_of_last_service - date_of_first_service).to_i + 1) rescue 'unknown'
    end

    def service_dates_for_display service_scope:, start_date:
      @service_dates_for_display ||= begin
        st = service_history.arel_table
        query = self.service_history.merge(service_scope).joins(:project).
          select( :date, :record_type, :project_id, :enrollment_group_id, :first_date_in_program, :last_date_in_program, :data_source_id, st[GrdaWarehouse::ServiceHistory.project_type_column].as('project_type').to_sql).
          where( st[:date].gt start_date.beginning_of_week ).
          where( st[:date].lteq start_date.end_of_month.end_of_week ).
          order( date: :asc ).
          distinct
        ungrouped_services = query.each_with_index.map do |m,i|
          day = {
            id: i,
            service_type: m.service_type_brief,
            program_id: m.project_id,
            class: "service-type__#{m.record_type} program-group_#{m.enrollment_group_id} client__service_type_#{m.project_type}",
            record_type: m.record_type,
            database_id: m.data_source_id,
          }
          if m.enrollment_group_id.present?
            day[:group] = "#{m.enrollment_group_id}"
          end
          if service_types.include?(m.record_type)
            day[:start] = m.date.to_date
          elsif m.record_type == 'exit'
            day[:start] = if m.last_date_in_program.present?
              then
              m.last_date_in_program.to_date
            else
              date_of_last_service
            end
          else
            day[:start] = m.first_date_in_program.to_date
            day[:end] = if m.last_date_in_program.present?
              then
              m.last_date_in_program.to_date
            else
              date_of_last_service
            end
          end
          day
        end
        ungrouped_services.group_by{ |m| m[:start] }
      end
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
      client_ids = client_scope.
        joins(:warehouse_client_source).searchable.
        where(where).
        preload(:destination_client).
        map{|m| m.destination_client.id}
      
      client_ids << text if numeric && self.destination.where(id: text).exists?
      where(id: client_ids)
    end

    def self.age date:, dob:
      return nil unless date.present? && dob.present?
      age = date.year - dob.year
      age -= 1 if dob > date.years_ago(age)
      return age
    end

    def age date=Date.today
      return unless attributes['DOB'].present?
      date = date.to_date
      dob = attributes['DOB'].to_date
      self.class.age(date: date, dob: dob)
    end
    alias_method :age_on, :age

    def uuid
      @uuid ||= if data_source.munged_personal_id
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

    def previous_permanent_locations_for_display
      labels = ('A'..'Z').to_a
      seen_addresses = {}
      source_enrollments.
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
            zip: enrollment.LastPermanentZIP.try(:rjust, 5, '0')
          }
          if lat_lon.present?
            address.merge!(lat_lon)
          end
          address
      end
    end

    # takes an array of tags representing the types of documents needed to be document ready
    # returns an array of hashes representing the state of each required document
    def document_readiness(required_documents)
      return [] unless required_documents.any?
      @document_readiness ||= begin
        @document_readiness = []
        required_documents.each do |tag|
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
      @document_ready ||= required_documents.size == document_readiness(required_documents).select{|m| m.available}.size 
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
          prev_destination_client.delete if prev_destination_client.source_clients(true).empty?

          # move any client notes
          GrdaWarehouse::ClientNotes::Base.where(client_id: prev_destination_client.id).update_all(client_id: self.id)

          # move any client files
          GrdaWarehouse::ClientFile.where(client_id: prev_destination_client.id).update_all(client_id: self.id)

          # move any patients
          Health::Patient.where(client_id: prev_destination_client.id).update_all(client_id: self.id)

          # move any vi-spdats
          GrdaWarehouse::Vispdat::Base.where(client_id: prev_destination_client.id).update_all(client_id: self.id)
        end
        # and invaldiate our own service history
        force_full_service_history_rebuild
        # and invalidate any cache for these clients
        self.class.clear_view_cache(prev_destination_client.id)
      end
      self.class.clear_view_cache(self.id)
      self.class.clear_view_cache(other_client.id)
      # un-match anyone who we just moved so they don't show up in the matching again until they'be been checked
      moved.each do |m|
        GrdaWarehouse::ClientMatch.where(source_client_id: m.id).destroy_all
        GrdaWarehouse::ClientMatch.where(destination_client_id: m.id).destroy_all
      end
      moved
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

    def most_recent_vispdat_score
      vispdats.completed.scores.first&.score || 0
    end

    def most_recent_vispdat_length_homeless_in_days
      begin
        vispdats.completed.order(submitted_at: :desc).first&.days_homeless || 0
      rescue
        0
      end
    end

    def days_homeless_for_vispdat_prioritization
      vispdat_prioritization_days_homeless || days_homeless_in_last_three_years
    end

    def self.days_homeless_in_last_three_years(client_id:, on_date: Date.today)
      dates_homeless_in_last_three_years_scope(client_id: client_id, on_date: on_date).count
    end
    def days_homeless_in_last_three_years(on_date: Date.today)
      self.class.days_homeless_in_last_three_years(client_id: id, on_date: on_date)
    end

    def self.dates_homeless_scope(client_id:, on_date: Date.today)
      GrdaWarehouse::ServiceHistoryService.where(client_id: client_id).
        homeless.
        where(shs_t[:date].lteq(on_date)).
        where.not(date: dates_housed_scope(client_id: client_id)).
        select(:date).distinct
    end

    def self.dates_in_hud_chronic_homeless_last_three_years_scope(client_id:, on_date: Date.today, chronic_only: true)
      Rails.cache.fetch([client_id, "dates_in_hud_chronic_homeless_last_three_years_scope", on_date], expires_at: CACHE_EXPIRY) do
        end_date = on_date.to_date
        start_date = end_date - 3.years
        GrdaWarehouse::ServiceHistoryService.service.
          where(client_id: client_id).
          hud_homeless(chronic_types_only: true).
          where(date: start_date..end_date).
          where.not(date: dates_hud_non_chronic_residential_last_three_years_scope(client_id: client_id, on_date: end_date)).
          select(:date).distinct
      end
    end

    def self.dates_homeless_in_last_three_years_scope(client_id:, on_date: Date.today)
      Rails.cache.fetch([client_id, "dates_homeless_in_last_three_years_scope", on_date], expires_at: CACHE_EXPIRY) do
        end_date = on_date.to_date
        start_date = end_date - 3.years
        GrdaWarehouse::ServiceHistoryService.where(client_id: client_id).
          homeless.
          where(date: start_date..end_date).
          where.not(date: dates_hud_non_chronic_residential_scope(client_id: client_id)).
          select(:date).distinct
      end
    end

    def self.dates_hud_non_chronic_residential_last_three_years_scope client_id:, on_date:
      end_date = on_date.to_date
      start_date = end_date - 3.years
      GrdaWarehouse::ServiceHistoryService.hud_residential_non_homeless.
        where(date: start_date..end_date).
        where(client_id: client_id).
        select(:date).distinct
    end

    def self.dates_hud_non_chronic_residential_scope client_id:
      GrdaWarehouse::ServiceHistoryService.hud_residential_non_homeless.
      where(client_id: client_id).
        select(:date).distinct
    end

    def homeless_months_in_last_three_years(on_date: Date.today)
      self.class.dates_homeless_in_last_three_years_scope(client_id: id, on_date: on_date).
        pluck(:date).
        map{ |date| [date.month, date.year]}.uniq
    end

    def months_homeless_in_last_three_years(on_date: Date.today)
      homeless_months_in_last_three_years(on_date: on_date).count
    end

    def self.dates_housed_scope(client_id:, on_date: Date.today)
      GrdaWarehouse::ServiceHistoryService.residential_non_homeless.
        where(client_id: client_id).select(:date).distinct
    end

    def self.dates_homeless(client_id:, on_date: Date.today)
      Rails.cache.fetch([client_id, "dates_homeless", on_date], expires_at: CACHE_EXPIRY) do
        dates_homeless_scope(client_id: client_id, on_date: on_date).pluck(:date)
      end
    end

    def self.days_homeless(client_id:, on_date: Date.today)
      Rails.cache.fetch([client_id, "days_homeless", on_date], expires_at: CACHE_EXPIRY) do
        dates_homeless_scope(client_id: client_id, on_date: on_date).count
      end
    end

    def days_homeless(on_date: Date.today)
      self.class.days_homeless(client_id: id, on_date: on_date)
    end

    # Pull the maximum total monthly income from any open enrollments, looking
    # only at the most recent assessment per enrollment
    def max_current_total_monthly_income
      source_enrollments.open_on_date(Date.today).map do |enrollment|
        enrollment.income_benefits.limit(1).
          order(InformationDate: :desc).
          pluck(:TotalMonthlyIncome).first
        end.compact.max || 0
    end

    def homeless_dates_for_chronic_in_past_three_years(date: Date.today)
      GrdaWarehouse::Tasks::ChronicallyHomeless.new(
        date: date.to_date, 
        dry_run: true, 
        client_ids: [id]
        ).residential_history_for_client(client_id: id)
    end

    # Add one to the number of new episodes
    def homeless_episodes_since date:
      start_date = date.to_date
      end_date = Date.today
      enrollments = service_history_enrollments.entry.
        open_between(start_date: start_date, end_date: end_date)
      chronic_enrollments = service_history_enrollments.entry.
        hud_homeless(chronic_types_only: true)
      chronic_enrollments.map do |enrollment|
        new_episode?(enrollments: enrollments, enrollment: enrollment)
      end.count(true)
    end

    def homeless_episodes_between start_date:, end_date:
      enrollments = service_history_enrollments.entry.
        open_between(start_date: start_date, end_date: end_date)
      chronic_enrollments = service_history_enrollments.entry.
        hud_homeless(chronic_types_only: true)
      chronic_enrollments.map do |enrollment|
        new_episode?(enrollments: enrollments, enrollment: enrollment)
      end.count(true)
    end

    # def months_served_since date:
    #   service_history.
    #     service
    #     .homeless
    #     .where(date: date..Date.today)
    #     .order(date: :asc)
    #     .pluck(:date)
    #     .map{|m| [m.month, m.year]}
    #     .uniq
    #     .count
    # end

    def months_served_between start_date:, end_date:
      days_chronic_in_last_three_years = self.class.dates_in_hud_chronic_homeless_last_three_years_scope(client_id: id, on_date: Date.today, chronic_only: true).pluck(:date)
      days_chronic_in_last_three_years.select{|date| (start_date.to_date..end_date.to_date).include?(date.to_date)}.
        map{|m| [m.month, m.year]}.
        uniq.
        count
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
      Rails.cache.fetch("clients/#{id}/enrollments_for/#{en_scope.to_sql}/#{include_confidential_names}", expires_at: CACHE_EXPIRY) do

        enrollments = en_scope.
          includes(:service_history_services, :project, :organization, :source_client).
          order(first_date_in_program: :desc)
        enrollments.
        map do |entry|
          project = entry.project
          organization = entry.organization
          services = entry.service_history_services
          project_name = if project.confidential? && ! include_confidential_names
             project.safe_project_name
          else
            "#{entry.project_name} < #{organization.OrganizationName}"
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
            living_situation: entry.enrollment.ResidencePrior,
            exit_date: entry.last_date_in_program,
            destination: entry.destination,
            days: dates_served.count,
            homeless: entry.computed_project_type.in?(Project::HOMELESS_PROJECT_TYPES),
            homeless_days: homeless_dates_for_enrollment.count,
            adjusted_days: adjusted_dates_for_similar_programs.count,
            months_served: adjusted_months_served(dates: adjusted_dates_for_similar_programs),
            household: self.household(entry.household_id, entry.first_date_in_program),
            project_type: ::HUD::project_type_brief(entry.computed_project_type),
            project_type_id: entry.computed_project_type,
            class: "client__service_type_#{entry.computed_project_type}",
            most_recent_service: most_recent_service,
            new_episode: new_episode,
            # support: dates_served,
          }
        end
      end
    end

    def enrollments_for_rollup en_scope: scope, include_confidential_names: false, only_ongoing: false
      Rails.cache.fetch("clients/#{id}/enrollments_for_rollup/#{en_scope.to_sql}/#{include_confidential_names}/#{only_ongoing}", expires_in: CACHE_EXPIRY) do
        enrollments = enrollments_for(en_scope, include_confidential_names: include_confidential_names)
        enrollments = enrollments.select{|m| m[:exit_date].blank?} if only_ongoing
        enrollments || []
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
      dates.select{|date| date < stop_date}
    end

    private def residential_dates enrollments:
      @non_homeless_types ||= GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPE_IDS - GrdaWarehouse::Hud::Project::HOMELESS_PROJECT_TYPES
      @residential_dates ||= enrollments.select do |e|
        @non_homeless_types.include?(e.computed_project_type)
      end.map do |e|
        e.service_history_services.map(&:date)
     end.flatten.compact.uniq
    end

    private def homeless_dates enrollments:
      @homeless_dates ||= enrollments.select do |e|
        e.computed_project_type.in? GrdaWarehouse::Hud::Project::CHRONIC_PROJECT_TYPES
      end.map do |e|
       e.service_history_services.map(&:date)
      end.flatten.compact.uniq
   end

    private def adjusted_months_served dates:
      dates.group_by{ |d| [d.year, d.month] }.keys
    end

    # If we haven't been in a homeless project type in the last 30 days, this is a new episode
    # If we dont' currently have a non-homeless residential and we have had one for the past 90 days
    private def new_episode? enrollments:, enrollment:
      return false unless GrdaWarehouse::Hud::Project::CHRONIC_PROJECT_TYPES.include?(enrollment.computed_project_type)
      entry_date = enrollment.first_date_in_program
      thirty_days_ago = entry_date - 30.days
      ninety_days_ago = entry_date - 90.days
      res_dates = residential_dates(enrollments: enrollments)
      no_other_homeless = (homeless_dates(enrollments: enrollments) & (thirty_days_ago...entry_date).to_a).empty?
      current_residential = res_dates.include?(entry_date)
      residential_for_past_90_days = (res_dates & (ninety_days_ago...entry_date).to_a).present?
      no_other_homeless || (! current_residential && residential_for_past_90_days)
    end
  end
end
