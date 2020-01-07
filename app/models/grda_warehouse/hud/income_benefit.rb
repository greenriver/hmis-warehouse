###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module GrdaWarehouse::Hud
  class IncomeBenefit < Base
    include HudSharedScopes
    self.table_name = 'IncomeBenefits'
    self.hud_key = :IncomeBenefitsID
    acts_as_paranoid column: :DateDeleted

    def self.hud_csv_headers(version: nil)
      case version
      when '5.1'
        [
          :IncomeBenefitsID,
          :ProjectEntryID,
          :PersonalID,
          :InformationDate,
          :IncomeFromAnySource,
          :TotalMonthlyIncome,
          :Earned,
          :EarnedAmount,
          :Unemployment,
          :UnemploymentAmount,
          :SSI,
          :SSIAmount,
          :SSDI,
          :SSDIAmount,
          :VADisabilityService,
          :VADisabilityServiceAmount,
          :VADisabilityNonService,
          :VADisabilityNonServiceAmount,
          :PrivateDisability,
          :PrivateDisabilityAmount,
          :WorkersComp,
          :WorkersCompAmount,
          :TANF,
          :TANFAmount,
          :GA,
          :GAAmount,
          :SocSecRetirement,
          :SocSecRetirementAmount,
          :Pension,
          :PensionAmount,
          :ChildSupport,
          :ChildSupportAmount,
          :Alimony,
          :AlimonyAmount,
          :OtherIncomeSource,
          :OtherIncomeAmount,
          :OtherIncomeSourceIdentify,
          :BenefitsFromAnySource,
          :SNAP,
          :WIC,
          :TANFChildCare,
          :TANFTransportation,
          :OtherTANF,
          :RentalAssistanceOngoing,
          :RentalAssistanceTemp,
          :OtherBenefitsSource,
          :OtherBenefitsSourceIdentify,
          :InsuranceFromAnySource,
          :Medicaid,
          :NoMedicaidReason,
          :Medicare,
          :NoMedicareReason,
          :SCHIP,
          :NoSCHIPReason,
          :VAMedicalServices,
          :NoVAMedReason,
          :EmployerProvided,
          :NoEmployerProvidedReason,
          :COBRA,
          :NoCOBRAReason,
          :PrivatePay,
          :NoPrivatePayReason,
          :StateHealthIns,
          :NoStateHealthInsReason,
          :IndianHealthServices,
          :NoIndianHealthServicesReason,
          :OtherInsurance,
          :OtherInsuranceIdentify,
          :HIVAIDSAssistance,
          :NoHIVAIDSAssistanceReason,
          :ADAP,
          :NoADAPReason,
          :ConnectionWithSOAR,
          :DataCollectionStage,
          :DateCreated,
          :DateUpdated,
          :UserID,
          :DateDeleted,
          :ExportID
        ].freeze
      when '6.11', '6.12'
        [
          :IncomeBenefitsID,
          :EnrollmentID,
          :PersonalID,
          :InformationDate,
          :IncomeFromAnySource,
          :TotalMonthlyIncome,
          :Earned,
          :EarnedAmount,
          :Unemployment,
          :UnemploymentAmount,
          :SSI,
          :SSIAmount,
          :SSDI,
          :SSDIAmount,
          :VADisabilityService,
          :VADisabilityServiceAmount,
          :VADisabilityNonService,
          :VADisabilityNonServiceAmount,
          :PrivateDisability,
          :PrivateDisabilityAmount,
          :WorkersComp,
          :WorkersCompAmount,
          :TANF,
          :TANFAmount,
          :GA,
          :GAAmount,
          :SocSecRetirement,
          :SocSecRetirementAmount,
          :Pension,
          :PensionAmount,
          :ChildSupport,
          :ChildSupportAmount,
          :Alimony,
          :AlimonyAmount,
          :OtherIncomeSource,
          :OtherIncomeAmount,
          :OtherIncomeSourceIdentify,
          :BenefitsFromAnySource,
          :SNAP,
          :WIC,
          :TANFChildCare,
          :TANFTransportation,
          :OtherTANF,
          :OtherBenefitsSource,
          :OtherBenefitsSourceIdentify,
          :InsuranceFromAnySource,
          :Medicaid,
          :NoMedicaidReason,
          :Medicare,
          :NoMedicareReason,
          :SCHIP,
          :NoSCHIPReason,
          :VAMedicalServices,
          :NoVAMedReason,
          :EmployerProvided,
          :NoEmployerProvidedReason,
          :COBRA,
          :NoCOBRAReason,
          :PrivatePay,
          :NoPrivatePayReason,
          :StateHealthIns,
          :NoStateHealthInsReason,
          :IndianHealthServices,
          :NoIndianHealthServicesReason,
          :OtherInsurance,
          :OtherInsuranceIdentify,
          :HIVAIDSAssistance,
          :NoHIVAIDSAssistanceReason,
          :ADAP,
          :NoADAPReason,
          :ConnectionWithSOAR,
          :DataCollectionStage,
          :DateCreated,
          :DateUpdated,
          :UserID,
          :DateDeleted,
          :ExportID,
        ].freeze
      when '2020'
        [
          :IncomeBenefitsID,
          :EnrollmentID,
          :PersonalID,
          :InformationDate,
          :IncomeFromAnySource,
          :TotalMonthlyIncome,
          :Earned,
          :EarnedAmount,
          :Unemployment,
          :UnemploymentAmount,
          :SSI,
          :SSIAmount,
          :SSDI,
          :SSDIAmount,
          :VADisabilityService,
          :VADisabilityServiceAmount,
          :VADisabilityNonService,
          :VADisabilityNonServiceAmount,
          :PrivateDisability,
          :PrivateDisabilityAmount,
          :WorkersComp,
          :WorkersCompAmount,
          :TANF,
          :TANFAmount,
          :GA,
          :GAAmount,
          :SocSecRetirement,
          :SocSecRetirementAmount,
          :Pension,
          :PensionAmount,
          :ChildSupport,
          :ChildSupportAmount,
          :Alimony,
          :AlimonyAmount,
          :OtherIncomeSource,
          :OtherIncomeAmount,
          :OtherIncomeSourceIdentify,
          :BenefitsFromAnySource,
          :SNAP,
          :WIC,
          :TANFChildCare,
          :TANFTransportation,
          :OtherTANF,
          :OtherBenefitsSource,
          :OtherBenefitsSourceIdentify,
          :InsuranceFromAnySource,
          :Medicaid,
          :NoMedicaidReason,
          :Medicare,
          :NoMedicareReason,
          :SCHIP,
          :NoSCHIPReason,
          :VAMedicalServices,
          :NoVAMedReason,
          :EmployerProvided,
          :NoEmployerProvidedReason,
          :COBRA,
          :NoCOBRAReason,
          :PrivatePay,
          :NoPrivatePayReason,
          :StateHealthIns,
          :NoStateHealthInsReason,
          :IndianHealthServices,
          :NoIndianHealthServicesReason,
          :OtherInsurance,
          :OtherInsuranceIdentify,
          :HIVAIDSAssistance,
          :NoHIVAIDSAssistanceReason,
          :ADAP,
          :NoADAPReason,
          :ConnectionWithSOAR,
          :DataCollectionStage,
          :DateCreated,
          :DateUpdated,
          :UserID,
          :DateDeleted,
          :ExportID,
        ].freeze
      else
        [
          :IncomeBenefitsID,
          :EnrollmentID,
          :PersonalID,
          :InformationDate,
          :IncomeFromAnySource,
          :TotalMonthlyIncome,
          :Earned,
          :EarnedAmount,
          :Unemployment,
          :UnemploymentAmount,
          :SSI,
          :SSIAmount,
          :SSDI,
          :SSDIAmount,
          :VADisabilityService,
          :VADisabilityServiceAmount,
          :VADisabilityNonService,
          :VADisabilityNonServiceAmount,
          :PrivateDisability,
          :PrivateDisabilityAmount,
          :WorkersComp,
          :WorkersCompAmount,
          :TANF,
          :TANFAmount,
          :GA,
          :GAAmount,
          :SocSecRetirement,
          :SocSecRetirementAmount,
          :Pension,
          :PensionAmount,
          :ChildSupport,
          :ChildSupportAmount,
          :Alimony,
          :AlimonyAmount,
          :OtherIncomeSource,
          :OtherIncomeAmount,
          :OtherIncomeSourceIdentify,
          :BenefitsFromAnySource,
          :SNAP,
          :WIC,
          :TANFChildCare,
          :TANFTransportation,
          :OtherTANF,
          :OtherBenefitsSource,
          :OtherBenefitsSourceIdentify,
          :InsuranceFromAnySource,
          :Medicaid,
          :NoMedicaidReason,
          :Medicare,
          :NoMedicareReason,
          :SCHIP,
          :NoSCHIPReason,
          :VAMedicalServices,
          :NoVAMedReason,
          :EmployerProvided,
          :NoEmployerProvidedReason,
          :COBRA,
          :NoCOBRAReason,
          :PrivatePay,
          :NoPrivatePayReason,
          :StateHealthIns,
          :NoStateHealthInsReason,
          :IndianHealthServices,
          :NoIndianHealthServicesReason,
          :OtherInsurance,
          :OtherInsuranceIdentify,
          :HIVAIDSAssistance,
          :NoHIVAIDSAssistanceReason,
          :ADAP,
          :NoADAPReason,
          :ConnectionWithSOAR,
          :DataCollectionStage,
          :DateCreated,
          :DateUpdated,
          :UserID,
          :DateDeleted,
          :ExportID,
        ].freeze
      end
    end

    belongs_to :enrollment, **hud_enrollment_belongs, inverse_of: :income_benefits
    has_one :client, through: :enrollment, inverse_of: :income_benefits
    belongs_to :direct_client, **hud_assoc(:PersonalID, 'Client'), inverse_of: :direct_income_benefits
    has_one :project, through: :enrollment
    belongs_to :export, **hud_assoc(:ExportID, 'Export'), inverse_of: :income_benefits, optional: true
    belongs_to :data_source

    scope :any_benefits, -> {
      at = arel_table
      conditions = SOURCES.keys.map{ |k| at[k].eq 1 }
      condition = conditions.shift
      condition = condition.or( conditions.shift ) while conditions.any?
      where( condition )
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
          and(ib_t[:IncomeFromAnySource].in([0, 1]))
        )
      )
    end

    scope :all_sources_refused, -> do
      where(IncomeFromAnySource: 9)
    end

    # produced by eliminating those columns matching /id|date|amount|reason|stage/i
    SOURCES = {
      Alimony:                :AlimonyAmount,
      ChildSupport:           :ChildSupportAmount,
      Earned:                 :EarnedAmount,
      GA:                     :GAAmount,
      OtherIncomeSource:      :OtherIncomeAmount,
      Pension:                :PensionAmount,
      PrivateDisability:      :PrivateDisabilityAmount,
      SSDI:                   :SSDIAmount,
      SSI:                    :SSIAmount,
      SocSecRetirement:       :SocSecRetirementAmount,
      TANF:                   :TANFAmount,
      Unemployment:           :UnemploymentAmount,
      VADisabilityNonService: :VADisabilityNonServiceAmount,
      VADisabilityService:    :VADisabilityServiceAmount,
      WorkersComp:            :WorkersCompAmount,
    }.freeze

    def sources
      @sources ||= SOURCES.keys.select{ |c| send(c) == 1 }
    end

    def sources_and_amounts
      @sources_and_amounts ||= sources.map{ |s| [ s, send(SOURCES[s]) ] }.to_h
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

  end
end