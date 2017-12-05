module GrdaWarehouse::Hud
  class Enrollment < Base
    include ArelHelper
    include HudSharedScopes
    self.table_name = 'Enrollment'
    self.hud_key = 'ProjectEntryID'
    acts_as_paranoid column: :DateDeleted

    def self.hud_csv_headers(version: nil)
      [
        "ProjectEntryID",
        "PersonalID",
        "ProjectID",
        "EntryDate",
        "HouseholdID",
        "RelationshipToHoH",
        "ResidencePrior",
        "OtherResidencePrior",
        "ResidencePriorLengthOfStay",
        "LOSUnderThreshold",
        "PreviousStreetESSH",
        "DateToStreetESSH",
        "TimesHomelessPastThreeYears",
        "MonthsHomelessPastThreeYears",
        "DisablingCondition",
        "HousingStatus",
        "DateOfEngagement",
        "ResidentialMoveInDate",
        "DateOfPATHStatus",
        "ClientEnrolledInPATH",
        "ReasonNotEnrolled",
        "WorstHousingSituation",
        "PercentAMI",
        "LastPermanentStreet",
        "LastPermanentCity",
        "LastPermanentState",
        "LastPermanentZIP",
        "AddressDataQuality",
        "DateOfBCPStatus",
        "FYSBYouth",
        "ReasonNoServices",
        "SexualOrientation",
        "FormerWardChildWelfare",
        "ChildWelfareYears",
        "ChildWelfareMonths",
        "FormerWardJuvenileJustice",
        "JuvenileJusticeYears",
        "JuvenileJusticeMonths",
        "HouseholdDynamics",
        "SexualOrientationGenderIDYouth",
        "SexualOrientationGenderIDFam",
        "HousingIssuesYouth",
        "HousingIssuesFam",
        "SchoolEducationalIssuesYouth",
        "SchoolEducationalIssuesFam",
        "UnemploymentYouth",
        "UnemploymentFam",
        "MentalHealthIssuesYouth",
        "MentalHealthIssuesFam",
        "HealthIssuesYouth",
        "HealthIssuesFam",
        "PhysicalDisabilityYouth",
        "PhysicalDisabilityFam",
        "MentalDisabilityYouth",
        "MentalDisabilityFam",
        "AbuseAndNeglectYouth",
        "AbuseAndNeglectFam",
        "AlcoholDrugAbuseYouth",
        "AlcoholDrugAbuseFam",
        "InsufficientIncome",
        "ActiveMilitaryParent",
        "IncarceratedParent",
        "IncarceratedParentStatus",
        "ReferralSource",
        "CountOutreachReferralApproaches",
        "ExchangeForSex",
        "ExchangeForSexPastThreeMonths",
        "CountOfExchangeForSex",
        "AskedOrForcedToExchangeForSex",
        "AskedOrForcedToExchangeForSexPastThreeMonths",
        "WorkPlaceViolenceThreats",
        "WorkplacePromiseDifference",
        "CoercedToContinueWork",
        "LaborExploitPastThreeMonths",
        "UrgentReferral",
        "TimeToHousingLoss",
        "ZeroIncome",
        "AnnualPercentAMI",
        "FinancialChange",
        "HouseholdChange",
        "EvictionHistory",
        "SubsidyAtRisk",
        "LiteralHomelessHistory",
        "DisabledHoH",
        "CriminalRecord",
        "SexOffender",
        "DependentUnder6",
        "SingleParent",
        "HH5Plus",
        "IraqAfghanistan",
        "FemVet",
        "HPScreeningScore",
        "ThresholdScore",
        "VAMCStation",
        "ERVisits",
        "JailNights",
        "HospitalNights",
        "DateCreated",
        "DateUpdated",
        "UserID",
        "DateDeleted",
        "ExportID"
      ]
    end

    alias_attribute :date, :EntryDate

    belongs_to :data_source, inverse_of: :enrollments
    belongs_to :client, class_name: GrdaWarehouse::Hud::Client.name, foreign_key: [:PersonalID, :data_source_id], primary_key: [:PersonalID, :data_source_id], inverse_of: :enrollments
    belongs_to :export, **hud_belongs(Export), inverse_of: :enrollments
    belongs_to :project, class_name: GrdaWarehouse::Hud::Project.name, foreign_key: [:ProjectID, :data_source_id], primary_key: [:ProjectID, :data_source_id], inverse_of: :enrollments
    has_one :organization, through: :project, autosave: false
    
    # Destination client
    has_one :destination_client, through: :client, autosave: false

    # Client-Enrollment related relationships
    has_one :exit,  class_name: GrdaWarehouse::Hud::Exit.name, foreign_key: [:ProjectEntryID, :PersonalID, :data_source_id], primary_key: [:ProjectEntryID, :PersonalID, :data_source_id], inverse_of: :enrollment, autosave: false
    has_many :disabilities, class_name: GrdaWarehouse::Hud::Disability.name, primary_key: [:ProjectEntryID, :PersonalID, :data_source_id], foreign_key: [:ProjectEntryID, :PersonalID, :data_source_id], inverse_of: :enrollment
    has_many :health_and_dvs, class_name: GrdaWarehouse::Hud::HealthAndDv.name, primary_key: [:ProjectEntryID, :PersonalID, :data_source_id], foreign_key: [:ProjectEntryID, :PersonalID, :data_source_id], inverse_of: :enrollment
    has_many :income_benefits, class_name: GrdaWarehouse::Hud::IncomeBenefit.name, primary_key: [:ProjectEntryID, :PersonalID, :data_source_id], foreign_key: [:ProjectEntryID, :PersonalID, :data_source_id], inverse_of: :enrollment
    has_many :services, class_name: GrdaWarehouse::Hud::Service.name, foreign_key: [:ProjectEntryID, :PersonalID, :data_source_id], primary_key: [:ProjectEntryID, :PersonalID, :data_source_id], inverse_of: :enrollment
    has_many :enrollment_cocs, class_name: GrdaWarehouse::Hud::EnrollmentCoc.name, primary_key: [:ProjectEntryID, :PersonalID, :data_source_id], foreign_key: [:ProjectEntryID, :PersonalID, :data_source_id], inverse_of: :enrollment
    has_many :employment_educations, class_name: GrdaWarehouse::Hud::EmploymentEducation.name, primary_key: [:ProjectEntryID, :PersonalID, :data_source_id], foreign_key: [:ProjectEntryID, :PersonalID, :data_source_id], inverse_of: :enrollment

    has_one :enrollment_coc_at_entry, -> {where(DataCollectionStage: 1)}, primary_key: [:ProjectEntryID, :PersonalID, :data_source_id], foreign_key: [:ProjectEntryID, :PersonalID, :data_source_id], autosave: false
    has_one :income_benefits_at_entry, -> {where(DataCollectionStage: 1)}, class_name: GrdaWarehouse::Hud::IncomeBenefit.name, primary_key: [:ProjectEntryID, :PersonalID, :data_source_id], foreign_key: [:ProjectEntryID, :PersonalID, :data_source_id], autosave: false
    has_one :income_benefits_at_exit, -> {where(DataCollectionStage: 3)}, class_name: GrdaWarehouse::Hud::IncomeBenefit.name, primary_key: [:ProjectEntryID, :PersonalID, :data_source_id], foreign_key: [:ProjectEntryID, :PersonalID, :data_source_id], autosave: false
    has_many :income_benefits_annual_update, -> {where(DataCollectionStage: 5)}, class_name: GrdaWarehouse::Hud::IncomeBenefit.name, primary_key: [:ProjectEntryID, :PersonalID, :data_source_id], foreign_key: [:ProjectEntryID, :PersonalID, :data_source_id]
    has_many :income_benefits_update, -> {where(DataCollectionStage: 2)}, class_name: GrdaWarehouse::Hud::IncomeBenefit.name, primary_key: [:ProjectEntryID, :PersonalID, :data_source_id], foreign_key: [:ProjectEntryID, :PersonalID, :data_source_id]
    belongs_to :service_histories, class_name: GrdaWarehouse::ServiceHistory.name, primary_key: [:data_source_id, :enrollment_group_id, :project_id], foreign_key: [:data_source_id, :ProjectEntryID, :ProjectID], inverse_of: :enrollment

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

    scope :visible_in_window, -> do
      joins(:data_source).where(data_sources: {visible_in_window: true})
    end

    scope :open_during_range, -> (range) do
      d_1_start = range.start
      d_1_end = range.end
      d_2_start = e_t[:EntryDate]
      d_2_end = ex_t[:ExitDate]
      # Currently does not count as an overlap if one starts on the end of the other
      joins(e_t.join(ex_t, Arel::Nodes::OuterJoin).
        on(e_t[:ProjectEntryID].eq(ex_t[:ProjectEntryID]).
        and(e_t[:PersonalID].eq(ex_t[:PersonalID]).
        and(e_t[:data_source_id].eq(ex_t[:data_source_id])))).
        join_sources).
      where(d_2_end.gt(d_1_start).or(d_2_end.eq(nil)).and(d_2_start.lt(d_1_end)))
    end

    ADDRESS_FIELDS = %w( LastPermanentStreet LastPermanentCity LastPermanentState LastPermanentZIP ).map(&:to_sym).freeze

    scope :any_address, -> {
      at = arel_table
      conditions = ADDRESS_FIELDS.map{ |f| at[f].not_eq(nil).and( at[f].not_eq '' ) }
      condition = conditions.reduce(conditions.shift){ |c1, c2| c1.or c2 }
      where condition
    }

    #################################
    # Standard Cohort Scopes
    scope :veteran, -> do
      joins(:destination_client).merge(GrdaWarehouse::Hud::Client.veteran)
    end

    scope :non_veteran, -> do
      joins(:destination_client).merge(GrdaWarehouse::Hud::Client.non_veteran)
    end

    # End Standard Cohort Scopes
    #################################

    # attempt to collect something like an address out of the LastX fields
    def address
      @address ||= begin
        street, city, state, zip = ADDRESS_FIELDS.map{ |f| send f }.map(&:presence)
        prezip = [ street, city, state ].compact.join(', ').presence
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

    def address_lat_lon
      result = Nominatim.search(address).country_codes('us').first
      if result.present?
        {address: address, lat: result.lat, lon: result.lon, boundingbox: result.boundingbox}
      else
        nil
      end
    end

    def days_served
      client.destination_client.service_history.where(record_type: 'service', enrollment_group_id: self.ProjectEntryID).select(:date).distinct
    end
    # If another enrollment with the same project type starts before this ends, 
    # Only count days in this enrollment that occured before the other starts
    def adjusted_days
      non_overlapping_days( Project.arel_table[:ProjectType].eq self.project.ProjectType )
    end

    # days served for this enrollment that will not be assigned to some other enrollment as selected by the condition parameter
    def non_overlapping_days(condition)
      ds = days_served
      et = Enrollment.arel_table
      st = ds.engine.arel_table
      conflicting_enrollments = client.destination_client.source_enrollments.joins(:project).
        where(condition).
        where( et[:id].not_eq self.id ).
        where(
          et[:EntryDate].between( self.EntryDate + 1.day .. exit_date ).
          or(
            et[:EntryDate].eq(self.EntryDate).and( et[:id].lt self.id )   # if they start on the same day, the earlier-id enrollments get to count the day
          )
        )
      ds.where.not(
        date: ds.engine.service.joins(:enrollment).merge(conflicting_enrollments).select(st[:date])
      )
    end

    def exit_date
      @exit_date ||= if exit.present?
        exit.ExitDate
      else
        Date.today
      end
    end

    def homeless?
      project.ProjectType.in? Project::CHRONIC_PROJECT_TYPES
    end

    # days when the user is in a homeless project and *not* in a residential project
    # an enrollment gets credit for its days preceding the beginning of another enrollment regardless
    # of overlap with a preceding enrollment
    def days_homeless
      if homeless?
        non_overlapping_days( Project.arel_table[:ProjectType].in Project::RESIDENTIAL_PROJECT_TYPE_IDS )
      else
        self.class.none
      end
    end

    def most_recent_service_date
      days_served.maximum(:date)
    end

    # If we haven't been in a homeless project type in the last 30 days, this is a new episode
    # If we don't currently have a non-homeless residential enrollment and we have had one for the past 90 days, this is a new episode
    def new_episode?
      return false unless GrdaWarehouse::Hud::Project::CHRONIC_PROJECT_TYPES.include?(self.project.ProjectType)
      thirty_days_ago = self.EntryDate - 30.days
      ninety_days_ago = self.EntryDate - 90.days
      no_other_homeless = ! client.destination_client.service_history
        .where(record_type: 'service')
        .where(date: thirty_days_ago...self.EntryDate)
        .where(project_type: GrdaWarehouse::Hud::Project::CHRONIC_PROJECT_TYPES)
        .where.not(enrollment_group_id: self.ProjectEntryID)
        .exists?

      non_homeless_residential = GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPE_IDS - GrdaWarehouse::Hud::Project::CHRONIC_PROJECT_TYPES
      current_residential = client.destination_client.service_history
        .where(record_type: 'service')
        .where(date: self.EntryDate)
        .where(project_type: non_homeless_residential).exists?
      residential_for_past_90_days = client.destination_client.service_history
        .where(record_type: 'service')
        .where(date: ninety_days_ago...self.EntryDate)
        .where(project_type: non_homeless_residential)
        .count >= 90
      no_other_homeless || (! current_residential && residential_for_past_90_days)
    end
  end # End Enrollment
end
