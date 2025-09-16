###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'memery'
module GrdaWarehouse::Hud
  class IncomeBenefit < Base
    include ArelHelper
    include HudSharedScopes
    include ::HmisStructure::IncomeBenefit
    include ::HmisStructure::Shared
    include Memery
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
    belongs_to :enrollment_with_deleted, class_name: 'GrdaWarehouse::Hud::WithDeleted::Enrollment', primary_key: [:EnrollmentID, :PersonalID, :data_source_id], query_constraints: [:EnrollmentID, :PersonalID, :data_source_id], optional: true

    has_one :client, through: :enrollment, inverse_of: :income_benefits
    has_one :project, through: :enrollment
    has_one :exit, through: :enrollment

    scope :any_benefits, -> {
      at = arel_table
      conditions = SOURCES.keys.map { |k| at[k].eq 1 }
      condition = conditions.shift
      condition = condition.or(conditions.shift) while conditions.any?
      where(condition)
    }

    scope :at_entry, -> do
      # NOTE: the join enrollment here seems to work only sometimes, so it is also in Enrollment
      where(DataCollectionStage: 1).joins(:enrollment).where(ib_t[:InformationDate].eq(e_t[:EntryDate]))
    end

    # hide previous declaration of :at_exit, we'll use this one
    replace_scope :at_exit, -> do
      where(DataCollectionStage: 3).joins(:exit).where(ib_t[:InformationDate].eq(ex_t[:ExitDate]))
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
      :VHAServices,
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

    def all_sources
      @all_sources ||= SOURCES.keys
    end

    def all_sources_and_amounts
      @all_sources_and_amounts ||= all_sources.map { |s| [s, send(SOURCES[s])] }.to_h
    end

    def all_sources_and_responses
      @all_sources_and_responses ||= all_sources.map { |s| [s, send(s)] }.to_h
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

    # Implements the Determining Total and Earned Income logic from the HMIS Glossary
    # This will be changing subtly in 2027, but the gist is that we should rely on the values
    # if they are present, and only use the response to IncomeFromAnySource if all values are missing
    # Assumption: Total income is not auto calculated
    memoize def hud_total_monthly_income
      # rows 1 & 2
      return self.TotalMonthlyIncome if self.TotalMonthlyIncome&.positive?

      calculated = income_total_from_sources
      # row 3
      return calculated if amounts.any? && (calculated.zero? || calculated.positive?)
      # row 4
      return 0.0 if self.IncomeFromAnySource&.zero?
      # row 5
      return 0.0 if self.TotalMonthlyIncome.present? && self.IncomeFromAnySource.in?([1, nil])

      # row 6 & 7
      # return nil if self.IncomeFromAnySource.in?([8, 9, 99])
      nil
    end

    # Returns an equivalent to IncomeFromAnySource, but keeps it in sync with hud_total_monthly_income
    memoize def hud_income_from_any_source
      return 1 if hud_total_monthly_income&.positive?
      return 0 if hud_total_monthly_income&.zero?
      return self.IncomeFromAnySource if self.IncomeFromAnySource.in?([8, 9, 99])

      99
    end

    # Total from income sources that are indicated as being collected AND have a value
    private def income_total_from_sources
      incomes = []
      # Find any source that is indicated as being collected AND has a value, sum the values
      SOURCES.each do |source, amount|
        income_specified = send(source)
        next unless income_specified == 1

        income_amount = send(amount)
        next unless income_amount.present? && income_amount.positive?

        incomes << income_amount
      end
      incomes.sum(&:to_f)
    end
  end
end
