module GrdaWarehouse::Hud
  class Enrollment < Base
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
    belongs_to :client, class_name: GrdaWarehouse::Hud::Client.name, foreign_key: ['PersonalID', 'data_source_id'], primary_key: ['PersonalID', 'data_source_id'], inverse_of: :enrollments
    belongs_to :export, **hud_belongs(Export), inverse_of: :enrollments
    has_one :exit, **hud_one(Exit), inverse_of: :enrollment
    belongs_to :project, class_name: GrdaWarehouse::Hud::Project.name, foreign_key: ['ProjectID', :data_source_id], primary_key: ['ProjectID', :data_source_id], inverse_of: :enrollments
    has_one :organization, through: :project
    has_many :disabilities, class_name: GrdaWarehouse::Hud::Disability.name, primary_key: ['ProjectEntryID',  :data_source_id], foreign_key: ['ProjectEntryID', :data_source_id], inverse_of: :enrollment
    has_many :health_and_dvs, class_name: GrdaWarehouse::Hud::HealthAndDv.name, primary_key: ['ProjectEntryID',  :data_source_id], foreign_key: ['ProjectEntryID', :data_source_id], inverse_of: :enrollment
    has_many :income_benefits, class_name: GrdaWarehouse::Hud::IncomeBenefit.name, primary_key: ['ProjectEntryID',  :data_source_id], foreign_key: ['ProjectEntryID', :data_source_id], inverse_of: :enrollment
    has_many :services, class_name: GrdaWarehouse::Hud::Service.name, foreign_key: ['ProjectEntryID', 'data_source_id'], primary_key: ['ProjectEntryID', 'data_source_id'], inverse_of: :enrollment
    has_many :enrollment_cocs, **hud_many(EnrollmentCoc), inverse_of: :enrollment
    has_one :enrollment_coc_at_entry, -> {where(DataCollectionStage: 1)}, **hud_one(EnrollmentCoc)
    has_one :income_benefits_at_entry, -> {where(DataCollectionStage: 1)}, class_name: GrdaWarehouse::Hud::IncomeBenefit.name, primary_key: ['ProjectEntryID',  :data_source_id], foreign_key: ['ProjectEntryID', :data_source_id]
    has_one :income_benefits_at_exit, -> {where(DataCollectionStage: 3)}, class_name: GrdaWarehouse::Hud::IncomeBenefit.name, primary_key: ['ProjectEntryID',  :data_source_id], foreign_key: ['ProjectEntryID', :data_source_id]
    has_many :income_benefits_annual_update, -> {where(DataCollectionStage: 5)}, class_name: GrdaWarehouse::Hud::IncomeBenefit.name, primary_key: ['ProjectEntryID',  :data_source_id], foreign_key: ['ProjectEntryID', :data_source_id]
    has_many :income_benefits_update, -> {where(DataCollectionStage: 2)}, class_name: GrdaWarehouse::Hud::IncomeBenefit.name, primary_key: ['ProjectEntryID',  :data_source_id], foreign_key: ['ProjectEntryID', :data_source_id]
    has_many :employment_educations, **hud_many(EmploymentEducation), inverse_of: :enrollment
    belongs_to :service_histories, class_name: GrdaWarehouse::ServiceHistory.name, primary_key: [:data_source_id, :enrollment_group_id, :project_id], foreign_key: [:data_source_id, :ProjectEntryID, :ProjectID], inverse_of: :enrollment

    scope :residential, -> {
      joins(:project).where(Project: {ProjectType: GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPE_IDS})
    }
    scope :homeless, -> {
      joins(:project).where(Project: {ProjectType: GrdaWarehouse::Hud::Project::CHRONIC_PROJECT_TYPES})
    }
    scope :residential_non_homeless, -> {
      joins(:project).where(Project: {ProjectType: GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPE_IDS - GrdaWarehouse::Hud::Project::CHRONIC_PROJECT_TYPES})
    }
    scope :non_residential, -> {
      joins(:project).where.not(Project: {ProjectType: GrdaWarehouse::Hud::Project::RESIDENTIAL_PROJECT_TYPE_IDS})
    }

    ADDRESS_FIELDS = %w( LastPermanentStreet LastPermanentCity LastPermanentState LastPermanentZIP ).map(&:to_sym).freeze

    scope :any_address, -> {
      at = arel_table
      conditions = ADDRESS_FIELDS.map{ |f| at[f].not_eq(nil).and( at[f].not_eq '' ) }
      condition = conditions.reduce(conditions.shift){ |c1, c2| c1.or c2 }
      where condition
    }

    # attempt to collect something like an address out of the LastX fields
    def address
      @address ||= begin
        street, city, state, zip = ADDRESS_FIELDS.map{ |f| send f }.map(&:presence)
        prezip = [ street, city, state ].compact.join(', ').presence
        zip = zip.try(:rjust, 5, '0')
        if prezip
          if zip
            "#{prezip} #{zip}"
          else
            prezip
          end
        else
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
