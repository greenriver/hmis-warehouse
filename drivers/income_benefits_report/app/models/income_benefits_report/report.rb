###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# NOTE: This report runs all calculations against the most-recently started enrollment
# that matches the filter scope for a given client
module IncomeBenefitsReport
  class Report < GrdaWarehouseBase
    self.table_name = 'income_benefits_reports'
    include Filter::ControlSections
    include Filter::FilterScopes
    include Reporting::Status
    include Rails.application.routes.url_helpers
    include ActionView::Helpers::NumberHelper
    include ArelHelper
    include IncomeBenefitsReport::Details
    include IncomeBenefitsReport::Summary
    include IncomeBenefitsReport::StayerHouseholds

    attr_accessor :project_type_codes

    acts_as_paranoid

    belongs_to :user

    after_initialize :filter, :set_project_types

    # def initialize(args)
    #   super(args)
    #   # Force set the filter so it is available
    #   filter
    #   # @project_types = filter.project_type_ids || GrdaWarehouse::Hud::Project::HOMELESS_PROJECT_TYPES
    #   # @comparison_pattern = filter.comparison_pattern
    #   # self.options = filter.for_params
    # end

    # NOTE: this differs from viewable_by which looks at the report definitions
    scope :visible_to, ->(user) do
      return all if user.can_view_all_reports?
      return where(user_id: user.id) if user.can_view_assigned_reports?

      none
    end

    scope :ordered, -> do
      order(updated_at: :desc)
    end

    def run_and_save!
      # FIXME: add begin/rescue and shove the errors into the model
      update(started_at: Time.current)
      populate_clients!
      assign_attributes(completed_at: Time.current)
      save
    end

    def filter=(filter_object)
      self.options = filter_object.for_params
      # force reset the filter cache
      @filter = nil
      filter
    end

    def filter
      @filter ||= begin
        f = ::Filters::FilterBase.new(user_id: user_id)
        f.set_from_params(options['filters'].with_indifferent_access) if options.try(:[], 'filters')
        f
      end
    end

    private def set_project_types
      @project_types = filter.project_type_ids || GrdaWarehouse::Hud::Project::HOMELESS_PROJECT_TYPES
    end

    def comparison_pattern
      @comparison_pattern ||= filter.comparison_pattern
    end

    def self.comparison_patterns
      {
        no_comparison_period: 'None',
        prior_year: 'Same period, prior year',
        prior_period: 'Prior Period',
      }.invert.freeze
    end

    def self.viewable_by(user)
      GrdaWarehouse::WarehouseReports::ReportDefinition.where(url: url).
        viewable_by(user).exists?
    end

    def self.url
      'income_benefits_report/warehouse_reports/report'
    end

    def self.available_section_types
      [
        'summary',
        'stayers_households',
        'leavers_households',
        'stayers_income_sources',
        'stayers_non_cash_benefits_sources',
        'stayers_insurance_sources',
        'leavers_income_sources',
        'leavers_non_cash_benefits_sources',
        'leavers_insurance_sources',
      ]
    end

    def title
      _('Income, Non-Cash Benefits, Health Insurance Report')
    end

    def section_ready?(section)
      return true unless section.in?(['summary', 'stayers_households'])

      Rails.cache.exist?(cache_key_for_section(section))
    end

    private def cache_key_for_section(section)
      [self.class.name, cache_slug, section]
    end

    def multiple_project_types?
      true
    end

    protected def build_control_sections
      # ensure filter has been set
      filter
      [
        build_general_control_section,
        build_coc_control_section,
        build_household_control_section,
        add_demographic_disabilities_control_section,
      ]
    end

    def report_path_array
      [
        :income_benefits_report,
        :warehouse_reports,
        :report,
        :index,
      ]
    end

    def filter_path_array
      [:filters] + report_path_array
    end

    def include_comparison?
      comparison_pattern != :no_comparison_period
    end

    # @return filtered scope
    def report_scope(all_project_types: false)
      # Report range
      scope = report_scope_source
      scope = filter_for_range(scope)
      scope = filter_for_cocs(scope)
      scope = filter_for_sub_population(scope)
      scope = filter_for_household_type(scope)
      scope = filter_for_head_of_household(scope)
      scope = filter_for_age(scope)
      scope = filter_for_gender(scope)
      scope = filter_for_race(scope)
      scope = filter_for_ethnicity(scope)
      scope = filter_for_veteran_status(scope)
      scope = filter_for_project_type(scope, all_project_types: all_project_types)
      scope = filter_for_data_sources(scope)
      scope = filter_for_organizations(scope)
      scope = filter_for_projects(scope)
      scope = filter_for_funders(scope)
      scope = filter_for_disabilities(scope)
      scope = filter_for_indefinite_disabilities(scope)
      scope = filter_for_dv_status(scope)
      scope = filter_for_chronic_status(scope)
      scope = filter_for_ca_homeless(scope)

      # Limit to most recently started enrollment per client
      scope.only_most_recent_by_client(scope: scope)
    end

    def report_scope_source
      GrdaWarehouse::ServiceHistoryEnrollment.entry
    end

    def yn(boolean)
      boolean ? 'Yes' : 'No'
    end

    def total_client_count
      @total_client_count ||= Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        distinct_client_ids.count
      end
    end

    def hoh_count
      @hoh_count ||= Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        hoh_scope.select(:client_id).distinct.count
      end
    end

    def household_count
      @household_count ||= Rails.cache.fetch([self.class.name, cache_slug, __method__], expires_in: expiration_length) do
        report_scope.select(:household_id).distinct.count
      end
    end

    private def hoh_scope
      report_scope.where(she_t[:head_of_household].eq(true))
    end

    # Anyone with at least one open enrollment on the last day of the report
    private def filter_for_stayers(scope)
      scope.where(client_id: report_scope.open_between(start_date: @filter.end_date, end_date: @filter.end_date).select(:client_id))
    end

    # Anyone who doesn't have at least one open enrollment on the last day of the report
    private def filter_for_leavers(scope)
      scope.where.not(client_id: report_scope.open_between(start_date: @filter.end_date, end_date: @filter.end_date).select(:client_id))
    end

    private def filter_for_adults(scope)
      scope.joins(:client).where(c_t[:DOB].lt(Arel.sql("GREATEST('#{(@filter.start_date - 18.years).to_s(:db)}', #{she_t[:first_date_in_program].to_sql} - interval '18 years')")))
    end

    private def filter_for_children(scope)
      scope.joins(:client).where(c_t[:DOB].gteq(Arel.sql("GREATEST('#{(@filter.start_date - 18.years).to_s(:db)}', #{she_t[:first_date_in_program].to_sql} - interval '18 years')")))
    end

    private def distinct_client_ids
      report_scope.select(:client_id).distinct
    end

    private def populate_clients! # rubocop:disable Metrics/AbcSize
      report_scope.preload(:client, :project, enrollment: :income_benefits).find_in_batches do |batch|
        report_clients = []
        race_cache = GrdaWarehouse::Hud::Client.new
        client_ids = batch.map(&:client_id)
        batch.each do |enrollment|
          client = enrollment.client
          race_string = race_cache.race_string(
            destination_id: enrollment.client_id,
            scope_limit: race_cache.class.where(id: client_ids),
          )
          # Save age based on the start of the report or the start of the enrollment, whichever is later
          age_date = [filter.start_date, enrollment.first_date_in_program].max
          report_client = IncomeBenefitsReport::Client.new(
            report: self,
            client: enrollment.client_id,
            first_name: client.FirstName,
            middle_name: client.MiddleName,
            last_name: client.LastName,
            ethnicity: client.Ethnicity,
            race: race_string,
            dob: client.DOB,
            age: client.age_on(age_date),
            gender: client.Gender,
            household_id: "#{enrollment.household_id}_#{enrollment.data_source_id}",
            head_of_household: enrollment[:head_of_household],
            enrollment: enrollment.enrollment.id,
            entry_date: enrollment.first_date_in_program,
            exit_date: enrollment.last_date_in_program,
            move_in_date: enrollment.move_in_date,
            project_name: enrollment.project_name,
            project: enrollment.project.id,
          )
          earlier_income = enrollment.enrollment.income_benefits.min_by(&:InformationDate)
          later_income = enrollment.enrollment.income_benefits.select { |m| m.InformationDate < filter.end_date }.max_by(&:InformationDate)
          report_client.earlier_income_record.build(
            report: self,
            income_benefits_id: earlier_income.id,
            stage: :earlier,
            InformationDate: earlier_income.InformationDate,
            IncomeFromAnySource: earlier_income.IncomeFromAnySource,
            TotalMonthlyIncome: earlier_income.TotalMonthlyIncome,
            Earned: earlier_income.Earned,
            EarnedAmount: earlier_income.EarnedAmount,
            Unemployment: earlier_income.Unemployment,
            UnemploymentAmount: earlier_income.UnemploymentAmount,
            SSI: earlier_income.SSI,
            SSIAmount: earlier_income.SSIAmount,
            SSDI: earlier_income.SSDI,
            SSDIAmount: earlier_income.SSDIAmount,
            VADisabilityService: earlier_income.VADisabilityService,
            VADisabilityServiceAmount: earlier.VADisabilityServiceAmount,
            VADisabilityNonService: earlier_income.VADisabilityNonService,
            VADisabilityNonServiceAmount: earlier_income.VADisabilityNonServiceAmount,
            PrivateDisability: earlier_income.PrivateDisability,
            PrivateDisabilityAmount: earlier_income.PrivateDisabilityAmount,
            WorkersComp: earlier_income.WorkersComp,
            WorkersCompAmount: earlier_income.WorkersCompAmount,
            TANF: earlier_income.TANF,
            TANFAmount: earlier_income.TANFAmount,
            GA: earlier_income.GA,
            GAAmount: earlier_income.GAAmount,
            SocSecRetirement: earlier_income.SocSecRetirement,
            SocSecRetirementAmount: earlier_income.SocSecRetirementAmount,
            Pension: earlier_income.Pension,
            PensionAmount: earlier_income.PensionAmount,
            ChildSupport: earlier_income.ChildSupport,
            ChildSupportAmount: earlier_income.ChildSupportAmount,
            Alimony: earlier_income.Alimony,
            AlimonyAmount: earlier_income.AlimonyAmount,
            OtherIncomeSource: earlier_income.OtherIncomeSource,
            OtherIncomeAmount: earlier_income.OtherIncomeAmount,
            OtherIncomeSourceIdentify: earlier_income.OtherIncomeSourceIdentify,
            BenefitsFromAnySource: earlier_income.BenefitsFromAnySource,
            SNAP: earlier_income.SNAP,
            WIC: earlier_income.WIC,
            TANFChildCare: earlier_income.TANFChildCare,
            TANFTransportation: earlier_income.TANFTransportation,
            OtherTANF: earlier_income.OtherTANF,
            OtherBenefitsSource: earlier_income.OtherBenefitsSource,
            OtherBenefitsSourceIdentify: earlier_income.OtherBenefitsSourceIdentify,
            InsuranceFromAnySource: earlier_income.InsuranceFromAnySource,
            Medicaid: earlier_income.Medicaid,
            NoMedicaidReason: earlier_income.NoMedicaidReason,
            Medicare: earlier_income.Medicare,
            NoMedicareReason: earlier_income.NoMedicareReason,
            SCHIP: earlier_income.SCHIP,
            NoSCHIPReason: earlier_income.NoSCHIPReason,
            VAMedicalServices: earlier_income.VAMedicalServices,
            NoVAMedReason: earlier_income.NoVAMedReason,
            EmployerProvided: earlier_income.EmployerProvided,
            NoEmployerProvidedReason: earlier_income.NoEmployerProvidedReason,
            COBRA: earlier_income.COBRA,
            NoCOBRAReason: earlier_income.NoCOBRAReason,
            PrivatePay: earlier_income.PrivatePay,
            NoPrivatePayReason: earlier_income.NoPrivatePayReason,
            StateHealthIns: earlier_income.StateHealthIns,
            NoStateHealthInsReason: earlier_income.NoStateHealthInsReason,
            IndianHealthServices: earlier_income.IndianHealthServices,
            NoIndianHealthServicesReason: earlier_income.NoIndianHealthServicesReason,
            OtherInsurance: earlier_income.OtherInsurance,
            OtherInsuranceIdentify: earlier_income.OtherInsuranceIdentify,
            HIVAIDSAssistance: earlier_income.HIVAIDSAssistance,
            NoHIVAIDSAssistanceReason: earlier_income.NoHIVAIDSAssistanceReason,
            ADAP: earlier_income.ADAP,
            NoADAPReason: earlier_income.NoADAPReason,
            ConnectionWithSOAR: earlier_income.ConnectionWithSOAR,
            DataCollectionStage: earlier_income.DataCollectionStage,
          )
          report_client.later_income_record.build(
            report: self,
            income_benefits_id: later_income.id,
            stage: :later,
            InformationDate: later_income.InformationDate,
            IncomeFromAnySource: later_income.IncomeFromAnySource,
            TotalMonthlyIncome: later_income.TotalMonthlyIncome,
            Earned: later_income.Earned,
            EarnedAmount: later_income.EarnedAmount,
            Unemployment: later_income.Unemployment,
            UnemploymentAmount: later_income.UnemploymentAmount,
            SSI: later_income.SSI,
            SSIAmount: later_income.SSIAmount,
            SSDI: later_income.SSDI,
            SSDIAmount: later_income.SSDIAmount,
            VADisabilityService: later_income.VADisabilityService,
            VADisabilityServiceAmount: earlier.VADisabilityServiceAmount,
            VADisabilityNonService: later_income.VADisabilityNonService,
            VADisabilityNonServiceAmount: later_income.VADisabilityNonServiceAmount,
            PrivateDisability: later_income.PrivateDisability,
            PrivateDisabilityAmount: later_income.PrivateDisabilityAmount,
            WorkersComp: later_income.WorkersComp,
            WorkersCompAmount: later_income.WorkersCompAmount,
            TANF: later_income.TANF,
            TANFAmount: later_income.TANFAmount,
            GA: later_income.GA,
            GAAmount: later_income.GAAmount,
            SocSecRetirement: later_income.SocSecRetirement,
            SocSecRetirementAmount: later_income.SocSecRetirementAmount,
            Pension: later_income.Pension,
            PensionAmount: later_income.PensionAmount,
            ChildSupport: later_income.ChildSupport,
            ChildSupportAmount: later_income.ChildSupportAmount,
            Alimony: later_income.Alimony,
            AlimonyAmount: later_income.AlimonyAmount,
            OtherIncomeSource: later_income.OtherIncomeSource,
            OtherIncomeAmount: later_income.OtherIncomeAmount,
            OtherIncomeSourceIdentify: later_income.OtherIncomeSourceIdentify,
            BenefitsFromAnySource: later_income.BenefitsFromAnySource,
            SNAP: later_income.SNAP,
            WIC: later_income.WIC,
            TANFChildCare: later_income.TANFChildCare,
            TANFTransportation: later_income.TANFTransportation,
            OtherTANF: later_income.OtherTANF,
            OtherBenefitsSource: later_income.OtherBenefitsSource,
            OtherBenefitsSourceIdentify: later_income.OtherBenefitsSourceIdentify,
            InsuranceFromAnySource: later_income.InsuranceFromAnySource,
            Medicaid: later_income.Medicaid,
            NoMedicaidReason: later_income.NoMedicaidReason,
            Medicare: later_income.Medicare,
            NoMedicareReason: later_income.NoMedicareReason,
            SCHIP: later_income.SCHIP,
            NoSCHIPReason: later_income.NoSCHIPReason,
            VAMedicalServices: later_income.VAMedicalServices,
            NoVAMedReason: later_income.NoVAMedReason,
            EmployerProvided: later_income.EmployerProvided,
            NoEmployerProvidedReason: later_income.NoEmployerProvidedReason,
            COBRA: later_income.COBRA,
            NoCOBRAReason: later_income.NoCOBRAReason,
            PrivatePay: later_income.PrivatePay,
            NoPrivatePayReason: later_income.NoPrivatePayReason,
            StateHealthIns: later_income.StateHealthIns,
            NoStateHealthInsReason: later_income.NoStateHealthInsReason,
            IndianHealthServices: later_income.IndianHealthServices,
            NoIndianHealthServicesReason: later_income.NoIndianHealthServicesReason,
            OtherInsurance: later_income.OtherInsurance,
            OtherInsuranceIdentify: later_income.OtherInsuranceIdentify,
            HIVAIDSAssistance: later_income.HIVAIDSAssistance,
            NoHIVAIDSAssistanceReason: later_income.NoHIVAIDSAssistanceReason,
            ADAP: later_income.ADAP,
            NoADAPReason: later_income.NoADAPReason,
            ConnectionWithSOAR: later_income.ConnectionWithSOAR,
            DataCollectionStage: later_income.DataCollectionStage,
          )
          report_clients << report_client
        end
        IncomeBenefitsReport::Client.import(report_clients, recursive: true)
      end
    end

    private def cache_slug
      @filter.attributes
    end

    private def expiration_length
      return 300.seconds if Rails.env.development?

      30.minutes
    end
  end
end
