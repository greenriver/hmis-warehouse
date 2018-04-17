module GrdaWarehouse::Hud
  class IncomeBenefit < Base
    include HudSharedScopes
    self.table_name = 'IncomeBenefits'
    self.hud_key = 'IncomeBenefitsID'
    acts_as_paranoid column: :DateDeleted

    def self.hud_csv_headers(version: nil)
      [
        "IncomeBenefitsID",
        "ProjectEntryID",
        "PersonalID",
        "InformationDate",
        "IncomeFromAnySource",
        "TotalMonthlyIncome",
        "Earned",
        "EarnedAmount",
        "Unemployment",
        "UnemploymentAmount",
        "SSI",
        "SSIAmount",
        "SSDI",
        "SSDIAmount",
        "VADisabilityService",
        "VADisabilityServiceAmount",
        "VADisabilityNonService",
        "VADisabilityNonServiceAmount",
        "PrivateDisability",
        "PrivateDisabilityAmount",
        "WorkersComp",
        "WorkersCompAmount",
        "TANF",
        "TANFAmount",
        "GA",
        "GAAmount",
        "SocSecRetirement",
        "SocSecRetirementAmount",
        "Pension",
        "PensionAmount",
        "ChildSupport",
        "ChildSupportAmount",
        "Alimony",
        "AlimonyAmount",
        "OtherIncomeSource",
        "OtherIncomeAmount",
        "OtherIncomeSourceIdentify",
        "BenefitsFromAnySource",
        "SNAP",
        "WIC",
        "TANFChildCare",
        "TANFTransportation",
        "OtherTANF",
        "RentalAssistanceOngoing",
        "RentalAssistanceTemp",
        "OtherBenefitsSource",
        "OtherBenefitsSourceIdentify",
        "InsuranceFromAnySource",
        "Medicaid",
        "NoMedicaidReason",
        "Medicare",
        "NoMedicareReason",
        "SCHIP",
        "NoSCHIPReason",
        "VAMedicalServices",
        "NoVAMedReason",
        "EmployerProvided",
        "NoEmployerProvidedReason",
        "COBRA",
        "NoCOBRAReason",
        "PrivatePay",
        "NoPrivatePayReason",
        "StateHealthIns",
        "NoStateHealthInsReason",
        "IndianHealthServices",
        "NoIndianHealthServicesReason",
        "OtherInsurance",
        "OtherInsuranceIdentify",
        "HIVAIDSAssistance",
        "NoHIVAIDSAssistanceReason",
        "ADAP",
        "NoADAPReason",
        "ConnectionWithSOAR",
        "DataCollectionStage",
        "DateCreated",
        "DateUpdated",
        "UserID",
        "DateDeleted",
        "ExportID"
      ]
    end

    has_one :client, through: :enrollment, inverse_of: :income_benefits
    belongs_to :direct_client, **hud_belongs(Client), inverse_of: :direct_income_benefits
    belongs_to :enrollment, class_name: GrdaWarehouse::Hud::Enrollment.name, primary_key: [:ProjectEntryID, :PersonalID, :data_source_id], foreign_key: [:ProjectEntryID, :PersonalID, :data_source_id], inverse_of: :income_benefits
    has_one :project, through: :enrollment
    belongs_to :export, **hud_belongs(Export), inverse_of: :income_benefits

    scope :any_benefits, -> {
      at = arel_table
      conditions = SOURCES.keys.map{ |k| at[k].eq 1 }
      condition = conditions.shift
      condition = condition.or( conditions.shift ) while conditions.any?
      where( condition )
    }

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

    def self.income_csv(start_date: 3.years.ago, end_date: DateTime.current, coc_code:)
      spec = {
        entry_exit_uid:          e_t[:ProjectEntryID],
        entry_exit_client_id:    she_t[:client_id],
        earned_income:           ib_t[:Earned],
        ssi_ssdi:                ib_t[:SSI],
        tanf:                    ib_t[:TANF],
        source_of_income:        ib_t[:SSDI], # ???
        receiving_income_source: ib_t[:SSI],  # ??? -- repeat for sake of simplicity
        start_date:              she_t[:first_date_in_program],
        end_date:                she_t[:last_date_in_program],
      }
      incomes = self.
        joins( enrollment: [ :enrollment_coc_at_entry, :service_history_enrollment ] ).
        merge( she_t.engine.open_between start_date: start_date, end_date: end_date ).
        where( ec_t[:CoCCode].eq coc_code )
      spec.each do |header, selector|
        incomes = incomes.select selector.as(header.to_s)
      end
 
      csv = CSV.generate headers: true do |csv|
        headers = spec.keys
        csv << headers

        last = []
        connection.select_all(incomes.to_sql).each do |income|
          row = []
          ssi, ssdi, tanf, earned_income = %w( ssi_ssdi source_of_income tanf earned_income ).map{ |f| income[f].presence&.to_i == 1 }
          headers.each do |h|
            value = income[h.to_s].presence
            value = case h
            when :start_date, :end_date
              value && DateTime.parse(value).strftime('%Y-%m-%d %H:%M')
            when :earned_income
              earned_income ? 'Yes' : 'No'
            when :tanf
              tanf ? 'Yes' : 'No'
            when :ssi_ssdi
              if ssi || ssdi
                'Yes'
              else
                'No'
              end
            when :source_of_income
              # pure guessword
              source = if earned_income
                'Earned Income'
              elsif ssi
                'SSI'
              elsif ssdi
                'SSDI'
              elsif tanf
                'TANF'
              end
              "#{source} (HUD)" if source
            when :receiving_income_source
              ssi || ssdi || tanf || earned_income ? 'Yes' : 'No'
            else
              value
            end
            row << value
          end
          next if row == last
          last = row
          csv << row
        end
       end
    end
  end
end