class CreateIncomeBenefitsReports < ActiveRecord::Migration[5.2]
  def change
    create_table :income_benefits_reports do |t|
      t.references :user, index: true
      t.jsonb :options
      t.string :processing_errors
      t.datetime :started_at
      t.datetime :completed_at
      t.datetime :failed_at
      t.timestamps index: true, null: false
      t.datetime :deleted_at, index: true
    end

    create_table :income_benefits_report_clients do |t|
      t.references :report, null: false, index: true
      t.references :client, null: false
      t.string :first_name
      t.string :middle_name
      t.string :last_name
      t.integer :ethnicity
      t.string :race
      t.date :dob
      t.integer :age
      t.integer :gender
      t.references :enrollment
      t.date :entry_date
      t.date :exit_date
      t.date :move_in_date
      t.string :project_name
      t.references :project

      t.references :earlier_income_record, index: { name: :index_income_benefits_report_clients_earlier }
      t.references :later_income_record, index: { name: :index_income_benefits_report_clients_later }
      t.timestamps index: true, null: false
    end

    create_table :income_benefits_report_incomes do |t|
      t.references :report, null: false, index: true
      t.references :report_client, null: false, index: true
      t.references :income_benefits, null: false
      t.string :stage
      t.date :InformationDate, null: false
      t.integer :IncomeFromAnySource, index: true
      t.string :TotalMonthlyIncome
      t.integer :Earned, index: true
      t.string :EarnedAmount
      t.integer :Unemployment
      t.string :UnemploymentAmount
      t.integer :SSI
      t.string :SSIAmount
      t.integer :SSDI
      t.string :SSDIAmount
      t.integer :VADisabilityService
      t.string :VADisabilityServiceAmount
      t.integer :VADisabilityNonService
      t.string :VADisabilityNonServiceAmount
      t.integer :PrivateDisability
      t.string :PrivateDisabilityAmount
      t.integer :WorkersComp
      t.string :WorkersCompAmount
      t.integer :TANF
      t.string :TANFAmount
      t.integer :GA
      t.string :GAAmount
      t.integer :SocSecRetirement
      t.string :SocSecRetirementAmount
      t.integer :Pension
      t.string :PensionAmount
      t.integer :ChildSupport
      t.string :ChildSupportAmount
      t.integer :Alimony
      t.string :AlimonyAmount
      t.integer :OtherIncomeSource
      t.string :OtherIncomeAmount
      t.string :OtherIncomeSourceIdentify
      t.integer :BenefitsFromAnySource
      t.integer :SNAP
      t.integer :WIC
      t.integer :TANFChildCare
      t.integer :TANFTransportation
      t.integer :OtherTANF
      t.integer :OtherBenefitsSource
      t.string :OtherBenefitsSourceIdentify
      t.integer :InsuranceFromAnySource
      t.integer :Medicaid
      t.integer :NoMedicaidReason
      t.integer :Medicare
      t.integer :NoMedicareReason
      t.integer :SCHIP
      t.integer :NoSCHIPReason
      t.integer :VAMedicalServices
      t.integer :NoVAMedReason
      t.integer :EmployerProvided
      t.integer :NoEmployerProvidedReason
      t.integer :COBRA
      t.integer :NoCOBRAReason
      t.integer :PrivatePay
      t.integer :NoPrivatePayReason
      t.integer :StateHealthIns
      t.integer :NoStateHealthInsReason
      t.integer :IndianHealthServices
      t.integer :NoIndianHealthServicesReason
      t.integer :OtherInsurance
      t.string :OtherInsuranceIdentify
      t.integer :HIVAIDSAssistance
      t.integer :NoHIVAIDSAssistanceReason
      t.integer :ADAP
      t.integer :NoADAPReason
      t.integer :ConnectionWithSOAR
      t.integer :DataCollectionStage
    end
  end
end
