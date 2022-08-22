###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
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
    include IncomeBenefitsReport::Summary
    include IncomeBenefitsReport::StayerHouseholds
    include IncomeBenefitsReport::LeaverHouseholds
    include IncomeBenefitsReport::StayerSources
    include IncomeBenefitsReport::LeaverSources
    include IncomeBenefitsReport::Details

    attr_accessor :project_type_codes

    acts_as_paranoid

    belongs_to :user, optional: true
    has_many :clients
    has_many :incomes

    after_initialize :filter, :set_project_types

    # NOTE: this differs from viewable_by which looks at the report definitions
    scope :visible_to, ->(user) do
      return all if user.can_view_all_reports?
      return where(user_id: user.id) if user.can_view_assigned_reports?

      none
    end

    scope :ordered, -> do
      order(updated_at: :desc)
    end

    def default_project_types
      [:ph]
    end

    def run_and_save!
      update(started_at: Time.current)
      begin
        populate_report_clients!
        populate_comparison_clients! if include_comparison?
        assign_attributes(completed_at: Time.current)
        save
      rescue Exception => e
        assign_attributes(failed_at: Time.current, processing_errors: [e.message, e.backtrace].to_json)
        save
        raise e
      end
    end

    def filter=(filter_object)
      self.options = filter_object.for_params
      # force reset the filter cache
      @filter = nil
      filter
    end

    def filter
      @filter ||= begin
        f = ::Filters::FilterBase.new(user_id: user_id, enforce_one_year_range: false)
        f.set_from_params(options['filters'].with_indifferent_access) if options.try(:[], 'filters')
        f
      end
    end

    def to_comparison
      comparison = dup
      comparison.filter = filter.to_comparison
      comparison.report_date_range = comparison_date_range
      comparison.id = id
      comparison
    end

    def earlier_income_records
      incomes.earlier.
        date_range(report_date_range).
        where(client_id: clients.select(:id))
    end

    def later_income_records
      incomes.later.
        date_range(report_date_range).
        where(client_id: clients.select(:id))
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

    def url
      income_benefits_report_warehouse_reports_report_url(host: ENV.fetch('FQDN'), id: id, protocol: 'https')
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
      scope = filter_for_user_access(scope)
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
      scope = filter_for_chronic_at_entry(scope)
      scope = filter_for_ca_homeless(scope)
      scope = filter_for_ce_cls_homeless(scope)
      scope = filter_for_cohorts(scope)
      scope = filter_for_times_homeless(scope)

      # Limit to most recently started enrollment per client
      scope.only_most_recent_by_client(scope: scope)
    end

    def report_scope_source
      GrdaWarehouse::ServiceHistoryEnrollment.entry
    end

    def can_see_client_details?(user)
      user.can_access_some_version_of_clients?
    end

    def yn(boolean)
      boolean ? 'Yes' : 'No'
    end

    def calc_percent(numerator, denominator)
      return 0 unless numerator.positive? && denominator.positive?

      (numerator / denominator.to_f).round(2) * 100
    end

    def hero_counts_data
      {
        total_clients: {
          count: total_client_count,
          scope: total_client_scope,
          income_relation: :earlier_income_record,
          title: 'Unique Clients',
        },
        total_hoh: {
          count: hoh_count,
          scope: total_hoh_scope,
          income_relation: :earlier_income_record,
          title: 'Households',
          description: 'Households are counted as the number of unique clients marked as Heads of Households.  This differs from HUDs definition of a household, which is counted as each distinct group of people presenting together for an enrollment.',
        },
      }
    end

    def total_client_count
      total_client_scope.count
    end

    private def total_client_scope
      clients.date_range(report_date_range)
    end

    def hoh_count
      total_hoh_scope.count
    end

    private def total_hoh_scope
      clients.date_range(report_date_range).heads_of_household
    end

    def household_count
      clients.date_range(report_date_range).select(:household_id).distinct.count
    end

    # Stayers
    private def stayers_scope
      clients.stayers(filter.end_date).date_range(report_date_range)
    end

    private def stayers_hoh
      stayers_scope.heads_of_household
    end

    private def stayers_adults
      stayers_scope.adults
    end

    private def stayers_hoh_count
      @stayers_hoh_count ||= stayers_hoh.count
    end

    private def stayers_adults_count
      @stayers_adults_count ||= stayers_adults.count
    end
    # End Stayers

    # Leavers
    private def leavers_scope
      clients.leavers(filter.end_date).date_range(report_date_range)
    end

    private def leavers_hoh
      leavers_scope.heads_of_household
    end

    private def leavers_adults
      leavers_scope.adults
    end

    private def leavers_hoh_count
      @leavers_hoh_count ||= leavers_hoh.count
    end

    private def leavers_adults_count
      @leavers_adults_count ||= leavers_adults.count
    end
    # End Leavers

    private def populate_report_clients!
      populate_clients!(report_date_range)
    end

    # Swap out the filter temporarily for the comparison filter
    private def populate_comparison_clients!
      original_filter = filter
      self.filter = original_filter.to_comparison
      populate_clients!(comparison_date_range)
      self.filter = original_filter
    end

    private def populate_clients!(range)
      report_scope.preload(:client, project: :organization, enrollment: :income_benefits).find_in_batches do |batch|
        report_clients = []
        race_cache = GrdaWarehouse::Hud::Client.new
        client_ids = batch.map(&:client_id)
        batch.each do |enrollment|
          race_string = race_cache.race_string(
            destination_id: enrollment.client_id,
            scope_limit: race_cache.class.where(id: client_ids),
          )
          report_client = client_from(enrollment, race_string, range)
          earlier_income = enrollment.enrollment.income_benefits.min_by(&:InformationDate)
          later_income = enrollment.enrollment.income_benefits.select do |m|
            m.InformationDate < filter.end_date &&
            m.InformationDate > earlier_income.InformationDate
          end.max_by(&:InformationDate)
          if earlier_income.present?
            income_record_from(report_client, :earlier, earlier_income, range)
            income_record_from(report_client, :later, later_income, range) if later_income.present?
          end
          report_clients << report_client
        end
        IncomeBenefitsReport::Client.import(report_clients, recursive: true)
      end
    end

    private def client_from(enrollment, race_string, range)
      client = enrollment.client
      # Save age based on the start of the report or the start of the enrollment, whichever is later
      age_date = [filter.start_date, enrollment.first_date_in_program].max
      # Use EnrollmentID if there is no household, append data_source_id since HouseholdID is not unique across data sources
      household_id = "#{enrollment.household_id.presence || enrollment.enrollment_group_id}_#{enrollment.data_source_id}"

      IncomeBenefitsReport::Client.new(
        report: self,
        client: client,
        date_range: range,
        first_name: client.FirstName,
        middle_name: client.MiddleName,
        last_name: client.LastName,
        ethnicity: client.Ethnicity,
        race: race_string,
        dob: client.DOB,
        age: client.age_on(age_date),
        household_id: household_id,
        head_of_household: enrollment[:head_of_household],
        enrollment: enrollment.enrollment,
        entry_date: enrollment.first_date_in_program,
        exit_date: enrollment.last_date_in_program,
        move_in_date: enrollment.move_in_date,
        project_name: enrollment.project&.name(filter.user),
        project: enrollment.project,
      )
    end

    private def income_record_from(client, stage, income, range)
      client.incomes.build(
        report: self,
        income_benefits_id: income.id,
        date_range: range,
        stage: stage,
        InformationDate: income.InformationDate,
        IncomeFromAnySource: income.IncomeFromAnySource,
        TotalMonthlyIncome: income.TotalMonthlyIncome,
        Earned: income.Earned,
        EarnedAmount: income.EarnedAmount,
        Unemployment: income.Unemployment,
        UnemploymentAmount: income.UnemploymentAmount,
        SSI: income.SSI,
        SSIAmount: income.SSIAmount,
        SSDI: income.SSDI,
        SSDIAmount: income.SSDIAmount,
        VADisabilityService: income.VADisabilityService,
        VADisabilityServiceAmount: income.VADisabilityServiceAmount,
        VADisabilityNonService: income.VADisabilityNonService,
        VADisabilityNonServiceAmount: income.VADisabilityNonServiceAmount,
        PrivateDisability: income.PrivateDisability,
        PrivateDisabilityAmount: income.PrivateDisabilityAmount,
        WorkersComp: income.WorkersComp,
        WorkersCompAmount: income.WorkersCompAmount,
        TANF: income.TANF,
        TANFAmount: income.TANFAmount,
        GA: income.GA,
        GAAmount: income.GAAmount,
        SocSecRetirement: income.SocSecRetirement,
        SocSecRetirementAmount: income.SocSecRetirementAmount,
        Pension: income.Pension,
        PensionAmount: income.PensionAmount,
        ChildSupport: income.ChildSupport,
        ChildSupportAmount: income.ChildSupportAmount,
        Alimony: income.Alimony,
        AlimonyAmount: income.AlimonyAmount,
        OtherIncomeSource: income.OtherIncomeSource,
        OtherIncomeAmount: income.OtherIncomeAmount,
        OtherIncomeSourceIdentify: income.OtherIncomeSourceIdentify,
        BenefitsFromAnySource: income.BenefitsFromAnySource,
        SNAP: income.SNAP,
        WIC: income.WIC,
        TANFChildCare: income.TANFChildCare,
        TANFTransportation: income.TANFTransportation,
        OtherTANF: income.OtherTANF,
        OtherBenefitsSource: income.OtherBenefitsSource,
        OtherBenefitsSourceIdentify: income.OtherBenefitsSourceIdentify,
        InsuranceFromAnySource: income.InsuranceFromAnySource,
        Medicaid: income.Medicaid,
        NoMedicaidReason: income.NoMedicaidReason,
        Medicare: income.Medicare,
        NoMedicareReason: income.NoMedicareReason,
        SCHIP: income.SCHIP,
        NoSCHIPReason: income.NoSCHIPReason,
        VAMedicalServices: income.VAMedicalServices,
        NoVAMedReason: income.NoVAMedReason,
        EmployerProvided: income.EmployerProvided,
        NoEmployerProvidedReason: income.NoEmployerProvidedReason,
        COBRA: income.COBRA,
        NoCOBRAReason: income.NoCOBRAReason,
        PrivatePay: income.PrivatePay,
        NoPrivatePayReason: income.NoPrivatePayReason,
        StateHealthIns: income.StateHealthIns,
        NoStateHealthInsReason: income.NoStateHealthInsReason,
        IndianHealthServices: income.IndianHealthServices,
        NoIndianHealthServicesReason: income.NoIndianHealthServicesReason,
        OtherInsurance: income.OtherInsurance,
        OtherInsuranceIdentify: income.OtherInsuranceIdentify,
        HIVAIDSAssistance: income.HIVAIDSAssistance,
        NoHIVAIDSAssistanceReason: income.NoHIVAIDSAssistanceReason,
        ADAP: income.ADAP,
        NoADAPReason: income.NoADAPReason,
        ConnectionWithSOAR: income.ConnectionWithSOAR,
        DataCollectionStage: income.DataCollectionStage,
      )
    end

    private def r_income_t
      IncomeBenefitsReport::Income.arel_table
    end

    private def r_client_t
      IncomeBenefitsReport::Client.arel_table
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
