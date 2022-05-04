###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module GrdaWarehouse::Hud
  class IncomeBenefit < Base
    include HudSharedScopes
    include ::HMIS::Structure::IncomeBenefit
    include RailsDrivers::Extensions

    attr_accessor :source_id

    self.table_name = 'IncomeBenefits'
    self.sequence_name = "public.\"#{table_name}_id_seq\""

    belongs_to :enrollment, **hud_enrollment_belongs, inverse_of: :income_benefits, optional: true
    belongs_to :direct_client, **hud_assoc(:PersonalID, 'Client'), inverse_of: :direct_income_benefits, optional: true
    belongs_to :export, **hud_assoc(:ExportID, 'Export'), inverse_of: :income_benefits, optional: true
    belongs_to :user, **hud_assoc(:UserID, 'User'), inverse_of: :income_benefits, optional: true
    belongs_to :data_source
    # Setup an association to enrollment that allows us to pull the records even if the
    # enrollment has been deleted
    belongs_to :enrollment_with_deleted, class_name: 'GrdaWarehouse::Hud::WithDeleted::Enrollment', primary_key: [:EnrollmentID, :PersonalID, :data_source_id], foreign_key: [:EnrollmentID, :PersonalID, :data_source_id], optional: true

    has_one :client, through: :enrollment, inverse_of: :income_benefits
    has_one :project, through: :enrollment

    scope :any_benefits, -> {
      at = arel_table
      conditions = SOURCES.keys.map { |k| at[k].eq 1 }
      condition = conditions.shift
      condition = condition.or(conditions.shift) while conditions.any?
      where(condition)
    }

    scope :at_entry, -> do
      where(DataCollectionStage: 1)
    end

    scope :at_exit, -> do
      where(DataCollectionStage: 3)
    end

    scope :at_annual_update, -> do
      where(DataCollectionStage: 5)
    end

    scope :at_update, -> do
      where(DataCollectionStage: 2)
    end

    scope :all_sources_missing, -> do
      ib_t = arel_table
      # data not collected, or you claimed it was but there was no value
      where(
        ib_t[:IncomeFromAnySource].in([99, nil, '']).
        or(ib_t[:TotalMonthlyIncome].eq(nil).
          and(ib_t[:IncomeFromAnySource].in([0, 1]))),
      )
    end

    scope :all_sources_refused, -> do
      where(IncomeFromAnySource: 9)
    end

    scope :with_earned_income, -> do
      where(Earned: 1)
    end

    scope :with_any_income, -> do
      where(IncomeFromAnySource: 1)
    end

    scope :with_unearned_income, -> do
      where(IncomeFromAnySource: 1).where.not(Earned: 1)
    end

    # NOTE: at the moment this is Postgres only
    # Arguments:
    #   an optional scope which is passed to the sub query that determines which record to return
    scope :only_most_recent_by_enrollment, ->(scope: nil) do
      one_for_column(:InformationDate, source_arel_table: arel_table, group_on: :EnrollmentID, direction: :desc, scope: scope)
    end

    scope :only_earliest_by_enrollment, ->(scope: nil) do
      one_for_column(:InformationDate, source_arel_table: arel_table, group_on: :EnrollmentID, direction: :asc, scope: scope)
    end

    # produced by eliminating those columns matching /id|date|amount|reason|stage/i
    SOURCES = {
      Alimony: :AlimonyAmount,
      ChildSupport: :ChildSupportAmount,
      Earned: :EarnedAmount,
      GA: :GAAmount,
      OtherIncomeSource: :OtherIncomeAmount,
      Pension: :PensionAmount,
      PrivateDisability: :PrivateDisabilityAmount,
      SSDI: :SSDIAmount,
      SSI: :SSIAmount,
      SocSecRetirement: :SocSecRetirementAmount,
      TANF: :TANFAmount,
      Unemployment: :UnemploymentAmount,
      VADisabilityNonService: :VADisabilityNonServiceAmount,
      VADisabilityService: :VADisabilityServiceAmount,
      WorkersComp: :WorkersCompAmount,
    }.freeze

    NON_CASH_BENEFIT_TYPES = [
      :SNAP,
      :WIC,
      :TANFChildCare,
      :TANFTransportation,
      :OtherTANF,
      :OtherBenefitsSource,
    ].freeze

    INSURANCE_TYPES = [
      :Medicaid,
      :Medicare,
      :SCHIP,
      :VAMedicalServices,
      :EmployerProvided,
      :COBRA,
      :PrivatePay,
      :StateHealthIns,
      :IndianHealthServices,
      :OtherInsurance,
    ].freeze

    def sources
      @sources ||= SOURCES.keys.select { |c| send(c) == 1 }
    end

    def sources_and_amounts
      @sources_and_amounts ||= sources.map { |s| [s, send(SOURCES[s])] }.to_h
    end

    def amounts
      sources_and_amounts.values
    end

    def self.income_ranges
      {
        no_income: { name: 'No income (less than $150)', range: (0..150) },
        one_fifty: { name: '$151 to $250', range: (151..250) },
        two_fifty: { name: '$251 to $500', range: (251..500) },
        five_hundred: { name: '$501 to $750', range: (501..750) },
        seven_fifty: { name: '$751 to $1000', range: (751..1000) },
        one_thousand: { name: '$1001 to $1500', range: (1001..1500) },
        fifteen_hundred: { name: '$1501 to $2000', range: (1501..2000) },
        two_thousand: { name: 'Over $2001', range: (2001..Float::INFINITY) },
        missing: { name: 'Missing', range: [nil] },
      }
    end

    def self.related_item_keys
      [
        :PersonalID,
        :EnrollmentID,
      ]
    end

    # This is the logic described in "Determining Total Income and Earned Income on a Specific Record"
    # in the APR spec
    def hud_total_monthly_income
      return self.TotalMonthlyIncome if self.TotalMonthlyIncome&.positive?

      calculated = amounts&.compact&.sum
      return calculated if calculated.positive?
      return 0.0 if self.IncomeFromAnySource.in?([1, nil])
      return 0.0 if self.IncomeFromAnySource.zero?

      nil
    end
  end
end
