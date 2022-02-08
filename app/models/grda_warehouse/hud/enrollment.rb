###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Hud
  class Enrollment < Base
    include ArelHelper
    include HudSharedScopes
    include TsqlImport
    include NotifierConfig
    include ::HMIS::Structure::Enrollment

    attr_accessor :source_id

    self.table_name = 'Enrollment'
    self.sequence_name = "public.\"#{table_name}_id_seq\""

    alias_attribute :date, :EntryDate

    belongs_to :data_source, inverse_of: :enrollments, autosave: false
    belongs_to :client, **hud_assoc(:PersonalID, 'Client'), inverse_of: :enrollments, optional: true
    belongs_to :export, **hud_assoc(:ExportID, 'Export'), inverse_of: :enrollments, optional: true
    belongs_to :project, **hud_assoc(:ProjectID, 'Project'), inverse_of: :enrollments, optional: true
    has_one :organization, through: :project, autosave: false

    has_many :enrollment_extras, class_name: 'GrdaWarehouse::EnrollmentExtra', dependent: :destroy, inverse_of: :enrollment

    # Destination client
    has_one :destination_client, through: :client, autosave: false

    # Client-Enrollment related relationships
    has_one :exit, **hud_enrollment_belongs('Exit'), inverse_of: :enrollment
    has_many :disabilities, **hud_enrollment_belongs('Disability'), inverse_of: :enrollment
    has_many :health_and_dvs, **hud_enrollment_belongs('HealthAndDv'), inverse_of: :enrollment
    has_many :income_benefits, **hud_enrollment_belongs('IncomeBenefit'), inverse_of: :enrollment
    has_many :services, **hud_enrollment_belongs('Service'), inverse_of: :enrollment
    has_many :enrollment_cocs, **hud_enrollment_belongs('EnrollmentCoc'), inverse_of: :enrollment
    has_many :employment_educations, **hud_enrollment_belongs('EmploymentEducation'), inverse_of: :enrollment
    has_many :events, **hud_enrollment_belongs('Event'), inverse_of: :enrollment
    has_many :assessments, **hud_enrollment_belongs('Assessment'), inverse_of: :enrollment
    has_many :direct_assessment_questions, **hud_enrollment_belongs('AssessmentQuestion'), inverse_of: :enrollment
    has_many :assessment_questions, through: :assessments
    has_many :direct_assessment_results, **hud_enrollment_belongs('AssessmentResult'), inverse_of: :enrollment
    has_many :assessment_results, through: :assessments
    has_many :current_living_situations, **hud_enrollment_belongs('CurrentLivingSituation'), inverse_of: :enrollment
    has_many :youth_education_statuses, **hud_enrollment_belongs('YouthEducationStatus'), inverse_of: :enrollment

    has_one :enrollment_coc_at_entry, -> do
      where(DataCollectionStage: 1)
    end, **hud_enrollment_belongs('EnrollmentCoc')

    # Income benefits at various stages
    has_one :income_benefits_at_entry, -> do
      at_entry
    end, **hud_enrollment_belongs('IncomeBenefit')
    has_one :income_benefits_at_entry_all_sources_refused, -> do
      at_entry.all_sources_refused
    end, **hud_enrollment_belongs('IncomeBenefit')
    has_one :income_benefits_at_entry_all_sources_missing, -> do
      at_entry.all_sources_missing
    end, **hud_enrollment_belongs('IncomeBenefit')

    has_one :income_benefits_at_exit, -> do
      GrdaWarehouse::Hud::IncomeBenefit.at_exit
    end, **hud_enrollment_belongs('IncomeBenefit')
    has_one :income_benefits_at_exit_all_sources_refused, -> do
      GrdaWarehouse::Hud::IncomeBenefit.at_exit.all_sources_refused
    end, **hud_enrollment_belongs('IncomeBenefit')
    has_one :income_benefits_at_exit_all_sources_missing, -> do
      GrdaWarehouse::Hud::IncomeBenefit.at_exit.all_sources_missing
    end, **hud_enrollment_belongs('IncomeBenefit')
    has_many :income_benefits_annual_update, -> do
      at_annual_update
    end, **hud_enrollment_belongs('IncomeBenefit')
    has_many :income_benefits_annual_update_all_sources_refused, -> do
      at_annual_update.all_sources_refused
    end, **hud_enrollment_belongs('IncomeBenefit')
    has_many :income_benefits_annual_update_all_sources_missing, -> do
      at_annual_update.all_sources_missing
    end, **hud_enrollment_belongs('IncomeBenefit')
    has_many :income_benefits_update, -> do
      at_update
    end, **hud_enrollment_belongs('IncomeBenefit')
    has_many :income_benefits_update_all_sources_refused, -> do
      at_update.all_sources_refused
    end, **hud_enrollment_belongs('IncomeBenefit')
    has_many :income_benefits_update_all_sources_missing, -> do
      at_update.all_sources_missing
    end, **hud_enrollment_belongs('IncomeBenefit')

    # NOTE: you will want to limit this to a particular record_type
    has_one :service_history_enrollment, -> { where(record_type: :entry) }, class_name: 'GrdaWarehouse::ServiceHistoryEnrollment', foreign_key: [:data_source_id, :enrollment_group_id, :project_id], primary_key: [:data_source_id, :EnrollmentID, :ProjectID], autosave: false

    # Cached chronically homeless at entry
    has_one :ch_enrollment, class_name: 'GrdaWarehouse::ChEnrollment'

    scope :residential, -> do
      joins(:project).merge(Project.residential)
    end
    scope :hud_residential, -> do
      joins(:project).merge(Project.hud_residential)
    end
    scope :chronic, -> do
      joins(:project).merge(Project.chronic)
    end
    scope :hud_chronic, -> do
      joins(:project).merge(Project.hud_chronic)
    end
    scope :homeless, -> do
      joins(:project).merge(Project.homeless)
    end
    scope :homeless_sheltered, -> do
      joins(:project).merge(Project.homeless_sheltered)
    end
    scope :homeless_unsheltered, -> do
      joins(:project).merge(Project.homeless_unsheltered)
    end
    scope :residential_non_homeless, -> do
      joins(:project).merge(Project.residential_non_homeless)
    end
    scope :hud_residential_non_homeless, -> do
      joins(:project).merge(Project.hud_residential_non_homeless)
    end
    scope :non_residential, -> do
      joins(:project).merge(Project.non_residential)
    end
    scope :hud_non_residential, -> do
      joins(:project).merge(Project.hud_non_residential)
    end
    scope :with_project_type, ->(project_types) do
      joins(:project).merge(Project.with_project_type(project_types))
    end
    scope :in_project, ->(project_ids) do
      joins(:project).where(p_t[:id].in(project_ids))
    end

    scope :visible_in_window_to, ->(user) do
      visible_to(user)
    end

    scope :visible_to, ->(_user) do
      none
    end

    scope :open_during_range, ->(range) do
      # convert the range into a standard range for backwards compatability
      range = (range.start..range.end) if range.is_a?(::Filters::DateRange)
      d_1_start = range.first
      d_1_end = range.last
      d_2_start = e_t[:EntryDate]
      d_2_end = ex_t[:ExitDate]
      # Currently does not count as an overlap if one starts on the end of the other
      joins(e_t.join(ex_t, Arel::Nodes::OuterJoin).
        on(e_t[:EnrollmentID].eq(ex_t[:EnrollmentID]).
        and(e_t[:PersonalID].eq(ex_t[:PersonalID]).
        and(e_t[:data_source_id].eq(ex_t[:data_source_id])))).
        join_sources).
        where(d_2_end.gteq(d_1_start).or(d_2_end.eq(nil)).and(d_2_start.lteq(d_1_end)))
    end

    scope :open_on_date, ->(date = Date.current) do
      open_during_range(date..date)
    end

    scope :opened_during_range, ->(range) do
      where(EntryDate: range)
    end

    scope :with_permanent_exit, ->(range) do
      joins(:exit).merge(GrdaWarehouse::Hud::Exit.permanent.closed_within_range(range))
    end

    scope :housed, ->(range) do
      residential_non_homeless.where(MoveInDate: range)
    end

    scope :heads_of_households, -> do
      where(RelationshipToHoH: 1)
    end

    ADDRESS_FIELDS = [
      :LastPermanentStreet,
      :LastPermanentCity,
      :LastPermanentState,
      :LastPermanentZIP,
    ].freeze

    scope :any_address, -> {
      at = arel_table
      conditions = ADDRESS_FIELDS.map { |f| at[f].not_eq(nil).and(at[f].not_eq('')) }
      condition = conditions.reduce(conditions.shift) { |c1, c2| c1.or c2 }
      where condition
    }

    scope :unprocessed, -> do
      where(processed_as: nil)
    end

    scope :processed, -> do
      where.not(processed_as: nil)
    end

    scope :unassigned, -> do
      jobs = GrdaWarehouse::Tasks::ServiceHistory::Enrollment.batch_job_ids
      return current_scope unless jobs.present?

      where(e_t[:service_history_processing_job_id].eq(nil).or(e_t[:service_history_processing_job_id].not_in(jobs)))
    end

    def self.related_item_keys
      [
        :PersonalID,
        :ProjectID,
      ]
    end

    def self.youth_columns
      {
        personal_id: :PersonalID,
        project_id: :ProjectID,
        household_id: :HouseholdID,
        data_source_id: :data_source_id,
        client_id: c_t[:id].as('client_id').to_sql,
      }.freeze
    end

    def self.lengths_of_stay
      {
        one_week_or_less: (0..7),
        one_week_to_one_month: (8..31),
        one_to_three_months: (32..90),
        three_to_six_months: (91..180),
        six_months_to_one_year: (181..365),
        one_year_to_eighteen_months: (366..548),
        eighteen_months_to_two_years: (548..730),
        two_to_three_years: (731..1095),
        more_than_three_years: (1096..Float::INFINITY),
      }
    end

    def self.invalidate_processing!
      update_all(processed_as: nil, processed_hash: nil)
    end

    # attempt to collect something like an address out of the LastX fields
    def address
      @address ||= begin
        street, city, state, zip = ADDRESS_FIELDS.map { |f| send f }.map(&:presence)
        prezip = [street, city, state].compact.join(', ').presence
        zip = zip.try(:rjust, 5, '0')
        if Rails.env.production?
          if prezip
            if zip
              "#{prezip} #{zip}"
            else
              prezip
            end
          else
            zip
          end
        else # just use zip in development and staging, data is faked
          zip
        end
      end
    end

    NominatimApiPaused = Class.new(StandardError)

    def address_lat_lon
      return unless address.present?

      begin
        result = Rails.cache.fetch(['Nominatim', address.to_s], expires_in: 6.weeks) do
          raise(NominatimApiPaused, 'Nominatim Paused') if Rails.cache.read(['Nominatim', 'API PAUSE'])

          sleep(0.75)
          begin
            Nominatim.search(address).country_codes('us').first
          rescue Faraday::ConnectionFailed
            # we've probably been banned, let the API cool off
            Rails.cache.write(['Nominatim', 'API PAUSE'], true, expires_in: 1.hours)
            raise(NominatimApiPaused, 'Nominatim Paused')
          end
        end
        return { address: address, lat: result.lat, lon: result.lon, boundingbox: result.boundingbox } if result.present?
      rescue NominatimApiPaused
        # Ignore errors if we are paused
      rescue StandardError
        setup_notifier('NominatimWarning')
        @notifier.ping("Error contacting the OSM Nominatim API. Looking address for enrollment id: #{id}") if @send_notifications
      end
      return nil
    end

    # Removed 8/14/2019
    # def days_served
    #   client.destination_client.service_history_enrollment.entry.
    #     joins(:service_history_services).
    #     where(enrollment_group_id: self.EnrollmentID).
    #     merge(GrdaWarehouse::ServiceHistoryservice.where(record_type: 'service')).
    #     select(:date).distinct
    # end
    # If another enrollment with the same project type starts before this ends,
    # Only count days in this enrollment that occurred before the other starts
    # Removed 8/14/2019
    # def adjusted_days
    #   non_overlapping_days( Project.arel_table[:ProjectType].eq self.project.ProjectType )
    # end

    # days served for this enrollment that will not be assigned to some other enrollment as selected by the condition parameter
    # Removed 8/14/2019
    # def non_overlapping_days(condition)
    #   ds = days_served
    #   et = Enrollment.arel_table
    #   st = ds.engine.arel_table
    #   conflicting_enrollments = client.destination_client.source_enrollments.joins(:project).
    #     where(condition).
    #     where( et[:id].not_eq self.id ).
    #     where(
    #       et[:EntryDate].between( self.EntryDate + 1.day .. exit_date ).
    #       or(
    #         et[:EntryDate].eq(self.EntryDate).and( et[:id].lt self.id )   # if they start on the same day, the earlier-id enrollments get to count the day
    #       )
    #     )
    #   ds.where.not(
    #     date: ds.engine.service.joins(:enrollment).merge(conflicting_enrollments).select(st[:date])
    #   )
    # end

    def exit_date
      @exit_date ||= if exit.present?
        exit.ExitDate
      else
        Date.current
      end
    end

    # If we haven't been in a literally homeless project type (ES, SH, SO) in the last 30 days, this is a new episode
    # You aren't currently housed in PH, and you've had at least a week of being housed in the last 90 days
    def new_episode?
      return false unless GrdaWarehouse::Hud::Project::CHRONIC_PROJECT_TYPES.include?(project.ProjectType)

      thirty_days_ago = self.EntryDate - 30.days
      ninety_days_ago = self.EntryDate - 90.days

      non_homeless_residential = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPE_IDS - GrdaWarehouse::Hud::Project::CHRONIC_PROJECT_TYPES
      currently_housed = client.destination_client.service_history_enrollments.
        joins(:service_history_services).
        merge(
          GrdaWarehouse::ServiceHistoryService.where(
            record_type: 'service', date: self.EntryDate,
          ),
        ).
        where(project_type: non_homeless_residential).exists?

      housed_for_week_in_past_90_days = client.destination_client.service_history_enrollments.
        joins(:service_history_services).
        merge(
          GrdaWarehouse::ServiceHistoryService.where(
            record_type: 'service', date: (ninety_days_ago...self.EntryDate),
          ),
        ).
        where(project_type: non_homeless_residential).
        count >= 7

      other_homeless = client.destination_client.service_history_enrollments.
        joins(:service_history_services).
        merge(
          GrdaWarehouse::ServiceHistoryService.where(
            record_type: 'service',
            date: thirty_days_ago...self.EntryDate,
          ),
        ).
        where(project_type: GrdaWarehouse::Hud::Project::CHRONIC_PROJECT_TYPES).
        where.not(enrollment_group_id: self.EnrollmentID).
        exists?
      return true if ! currently_housed && housed_for_week_in_past_90_days && ! other_homeless

      return ! other_homeless
    end

    def chronically_homeless_at_start?
      chronically_homeless_at_start == :yes
    end

    # Was the client chronically homeless at the start of this enrollment?
    #
    # @return [Symbol] :yes, :no, :dk_or_r, or :missing
    def chronically_homeless_at_start
      # Line 1
      return :no if is_no?(self.DisablingCondition)
      return dk_or_r_or_missing(self.DisablingCondition) if dk_or_r_or_missing(self.DisablingCondition)

      # Line 3
      if Project::CHRONIC_PROJECT_TYPES.include?(project.ProjectType)
        # Lines 4 - 6
        return homeless_duration_sufficient if homeless_duration_sufficient
      end

      # Line 9
      if HUD.homeless_situations(as: :prior).include?(self.LivingSituation)
        # Lines 10 - 12
        return homeless_duration_sufficient if homeless_duration_sufficient
      end

      # Line 14
      if HUD.institutional_situations(as: :prior).include?(self.LivingSituation)
        # Line 15
        return :no if is_no?(self.LOSUnderThreshold)
        # Line 16
        return :no if is_no?(self.PreviousStreetESSH)
        # Lines 17 - 19
        return homeless_duration_sufficient if homeless_duration_sufficient
      end

      # Line 21
      if (HUD.temporary_and_permanent_housing_situations(as: :prior) + HUD.other_situations(as: :prior)).include?(self.LivingSituation)
        # Line 22
        return :no if is_no?(self.LOSUnderThreshold)
        # Line 23
        return :no if is_no?(self.PreviousStreetESSH)
        # Lines 24 - 26
        return homeless_duration_sufficient if homeless_duration_sufficient
      end

      return :no # Not included in flow -- added as fail safe
    end

    def is_no?(value) # rubocop:disable Naming/PredicateName
      return :no if value&.zero?
    end

    def dk_or_r_or_missing(value)
      return :dk_or_r if [8, 9].include?(value)
      return :missing if value == 99
    end

    def homeless_duration_sufficient
      return :yes if self.DateToStreetESSH.present? && self.DateToStreetESSH <= self.EntryDate - 365.days

      @three_or_fewer_times_homeless ||= [1, 2, 3].freeze
      return :no if @three_or_fewer_times_homeless.include?(self.TimesHomelessPastThreeYears)
      return dk_or_r_or_missing(self.TimesHomelessPastThreeYears) if dk_or_r_or_missing(self.TimesHomelessPastThreeYears)

      @twelve_or_more_months_homeless ||= [112, 113].freeze # 112 = 12 months, 113 = 13+ months
      return :yes if @twelve_or_more_months_homeless.include?(self.MonthsHomelessPastThreeYears)

      return dk_or_r_or_missing(self.MonthsHomelessPastThreeYears) if dk_or_r_or_missing(self.MonthsHomelessPastThreeYears)
    end
    # NOTE: this must be included at the end of the class so that scopes can override correctly
    include RailsDrivers::Extensions
  end # End Enrollment
end
