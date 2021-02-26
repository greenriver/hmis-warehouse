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
      t.string :household_id
      t.boolean :head_of_household
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
      t.references :client, null: false, index: true
      t.references :income_benefits, null: false
      t.string :stage
      t.date :InformationDate, null: false
      t.integer :IncomeFromAnySource, index: true
      t.decimal :TotalMonthlyIncome
      t.integer :Earned, index: true
      t.decimal :EarnedAmount
      t.integer :Unemployment
      t.decimal :UnemploymentAmount
      t.integer :SSI
      t.decimal :SSIAmount
      t.integer :SSDI
      t.decimal :SSDIAmount
      t.integer :VADisabilityService
      t.decimal :VADisabilityServiceAmount
      t.integer :VADisabilityNonService
      t.decimal :VADisabilityNonServiceAmount
      t.integer :PrivateDisability
      t.decimal :PrivateDisabilityAmount
      t.integer :WorkersComp
      t.decimal :WorkersCompAmount
      t.integer :TANF
      t.decimal :TANFAmount
      t.integer :GA
      t.decimal :GAAmount
      t.integer :SocSecRetirement
      t.decimal :SocSecRetirementAmount
      t.integer :Pension
      t.decimal :PensionAmount
      t.integer :ChildSupport
      t.decimal :ChildSupportAmount
      t.integer :Alimony
      t.decimal :AlimonyAmount
      t.integer :OtherIncomeSource
      t.decimal :OtherIncomeAmount
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
