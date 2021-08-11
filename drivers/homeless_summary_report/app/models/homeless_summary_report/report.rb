###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HomelessSummaryReport
  class Report < SimpleReports::ReportInstance
    include Filter::ControlSections
    include Filter::FilterScopes
    include Reporting::Status
    include Rails.application.routes.url_helpers
    include ActionView::Helpers::NumberHelper
    include ArelHelper

    acts_as_paranoid

    belongs_to :user
    has_many :clients

    after_initialize :filter

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
      start
      create_universe
      complete
    end

    def start
      update(started_at: Time.current)
    end

    def complete
      update(completed_at: Time.current)
    end

    def filter=(filter_object)
      self.options = filter_object.to_h
      # force reset the filter cache
      @filter = nil
      filter
    end

    def filter
      @filter ||= begin
        f = ::Filters::FilterBase.new(user_id: user_id)
        f.update(options.with_indifferent_access) if options.present?
        f
      end
    end

    def self.viewable_by(user)
      GrdaWarehouse::WarehouseReports::ReportDefinition.where(url: url).
        viewable_by(user).exists?
    end

    def self.url
      'homeless_summary_report/warehouse_reports/report'
    end

    def url
      homeless_summary_report_warehouse_reports_report_url(host: ENV.fetch('FQDN'), id: id, protocol: 'https')
    end

    def title
      _('Homeless Summary Report')
    end

    def multiple_project_types?
      true
    end

    private def build_control_sections
      # ensure filter has been set
      filter
      [
        build_general_control_section(include_comparison_period: false),
        build_hoh_control_section,
        build_coc_control_section(true),
      ]
    end

    def report_path_array
      [
        :homeless_summary_report,
        :warehouse_reports,
        :reports,
      ]
    end

    private def available_support
      {
        clients_served: {
          title: _('Clients Served'),
          clients_served: {
            scope: :served,
            title: '',
          },
        },
        returns: {
          title: _('Returns to Homelessness'),
          in_outflow: {
            scope: :did_not_return_in_two_years,
            title: 'Did Not Return Within 2 Years',
          },
          returned_in_two_years: {
            scope: :returned_in_two_years,
            title: 'Returned to Homelessness Within 2 Years',
          },
        },
        entering_housing: {
          title: _('Clients moving into permanent housing'),
          entering_housing: {
            scope: :entering_housing,
            title: '',
          },
        },
        income: {
          title: _('Percentage of clients with increased income'),
          with_increased_earned_income: {
            scope: :with_increased_earned_income,
            title: 'Employment Income',
          },
          with_increased_other_income: {
            scope: :with_increased_other_income,
            title: 'Non-Employment Income',
          },
        },
        average_stay_length: {
          title: _('Average length of stay'),
          with_es_stay: {
            scope: :with_es_stay,
            title: 'Emergency Shelter',
          },
          with_rrh_stay: {
            scope: :with_rrh_stay,
            title: 'Rapid Rehousing',
          },
          with_psh_stay: {
            scope: :with_psh_stay,
            title: 'PSH',
          },
        },
        inflow_outflow: {
          title: _('Inflow / Outflow'),
          in_inflow: {
            scope: :in_inflow,
            title: 'Inflow',
          },
          in_outflow: {
            scope: :in_outflow,
            title: 'Outflow',
          },
          first_time: {
            scope: :first_time,
            title: 'First Time',
          },
          reentering: {
            scope: :reentering,
            title: 'Re-entering',
          },
          entered_housing: {
            scope: :entered_housing,
            title: 'Entered Housing',
          },
          inactive: {
            scope: :inactive,
            title: 'Inactive',
          },
        },
      }.freeze
    end

    def support_title(key)
      support = available_support[key.to_sym]
      return unless support

      support[:title]
    end

    def detail_scope(key, sub_key)
      support = available_support[key.to_sym]
      return clients.none unless support

      sub_support = support[sub_key.to_sym]
      return unless sub_support

      period = :current

      clients.send(sub_support[:scope], period)
    end

    def header_for(key, sub_key)
      support = available_support[key.to_sym]
      return unless support

      sub_support = support[sub_key.to_sym]
      return unless sub_support

      sub_support[:title]
    end

    # @return filtered scope
    def report_scope
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
      # TODO: I wonder if a filter is missing here for times homeless in last three years
      scope = filter_for_project_type(scope)
      scope = filter_for_data_sources(scope)
      scope = filter_for_organizations(scope)
      scope = filter_for_projects(scope)
      scope = filter_for_funders(scope)
      filter_for_ca_homeless(scope)
    end

    def enrollment_scope
      report_scope.preload(:client, enrollment: :income_benefits)
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

    def report_labels
      {
        'People Served' => {
          'Clients' => :enrolled_clients,
        },
      }.freeze
    end

    private def create_universe
      report_clients = {}
      add_clients(report_clients)
    end

    private def add_clients(report_clients)
      spm_reports = run_spm

      # Work through all the SPM report variants, building up the `report_clients` as we go.
      spm_reports.each do |variant_name, report|
        self.class.spm_fields.each do |spm_field, cells|
          cells.each do |cell|
            spm_clients = answer_clients(report[:report], *cell)
            spm_clients.each do |spm_client|
              report_client = report_clients[spm_client[:client_id]] || Client.new
              report_client[:client_id] = spm_client[:client_id]
              report_client[:first_name] = spm_client[:first_name]
              report_client[:last_name] = spm_client[:last_name]
              report_client[:report_id] = id
              report_client["spm_#{spm_field}"] = spm_client[spm_field]
              if spm_field.start_with?('m7')
                field_name = "spm_m#{cell.join('_')}".delete('.').downcase.to_sym
                report_client[field_name] = true
              end
              report_client["spm_#{variant_name}"] = report[:report].id
              report_clients[spm_client[:client_id]] = report_client
            end
          end
        end
      end

      Client.import(
        report_clients.values,
        on_duplicate_key_update: {
          conflict_target: [:id],
          columns: Client.attribute_names.map(&:to_sym),
        },
      )
      universe.add_universe_members(report_clients)
    end

    private def answer(report, table, cell)
      report.answer(question: table, cell: cell).summary
    end

    private def answer_clients(report, table, cell)
      report.answer(question: table, cell: cell).universe_members.map(&:universe_membership)
    end

    private def destination_client_column(report)
      return :destination_client_id if report.report_name == 'Consolidated Annual Performance and Evaluation Report - FY 2020'

      :client_id
    end

    private def run_spm
      # puts 'Running SPM'
      questions = [
        'Measure 1',
        'Measure 2',
        'Measure 7',
      ]
      # NOTE: we need to include all homeless projects visible to this user, plus the chosen scope,
      # so that the returns calculation will work.
      options = filter.to_h
      options[:project_type_codes] ||= []
      options[:project_type_codes] += [:es, :so, :sh, :th]
      generator = HudSpmReport::Generators::Fy2020::Generator
      self.class.report_variants.map do |variant, spec|
        # TODO: clear out this dev stuff
        extra_filters = spec[:extra_filters] || {}
        processed_filter = HudSpmReport::Filters::SpmFilter.new(user_id: filter.user_id)
        # TODO: remove demographics filters and household_type from UI. Keep HoH
        processed_filter.update(options.deep_merge(extra_filters))
        report = HudReports::ReportInstance.from_filter(
          processed_filter,
          generator.title,
          build_for_questions: questions,
        )
        generator.new(report).run!(email: false)
        [variant, spec.merge(report: report)]
      end.to_h
    end

    def self.spm_fields
      {
        m1a_es_sh_days: [['1a', 'C2']],
        m1a_es_sh_th_days: [['1a', 'C3']],
        m1b_es_sh_ph_days: [['1b', 'C2']],
        m1b_es_sh_th_ph_days: [['1b', 'C3']],

        m2_reentry_days: [['2', 'B7']],

        m7a1_destination: [
          ['7a.1', 'C2'],
          ['7a.1', 'C3'],
          ['7a.1', 'C4'],
        ],
        m7b1_destination: [
          ['7b.1', 'C2'],
          ['7b.1', 'C3'],
        ],
        m7b2_destination: [
          ['7b.2', 'C2'],
          ['7b.2', 'C3'],
        ],
      }.freeze
    end

    def self.report_variants
      {
        all_persons: {
          name: 'All Persons',
          extra_filters: {
            household_type: :all,
          },
        },
        without_children: {
          name: 'Persons in Adult Only Households',
          extra_filters: {
            household_type: :without_children,
          },
        },
        with_children: {
          name: 'Persons in Adult/Child Households',
          extra_filters: {
            household_type: :with_children,
          },
        },
        only_children: {
          name: 'Persons in Child Only Households',
          extra_filters: {
            household_type: :only_children,
          },
        },
        without_children_and_fifty_five_plus: {
          name: 'Persons in Adult Only Households who are Age 55+',
          extra_filters: {
            household_type: :without_children,
            age_ranges: [
              :fifty_five_to_fifty_nine,
              :sixty_to_sixty_one,
              :over_sixty_one,
            ],
          },
        },
        # adults_with_children_where_parenting_adult_18_to_24: {
        #   name: 'Adults in Adult/Child Households where the Parenting Adult is 18-24',
        #   extra_filters: {
        #     # TODO: define these filters
        #   },
        # }
        white_non_hispanic_latino: {
          name: 'White Non Hispanic/Latino Persons',
          extra_filters: {
            ethnicities: [HUD.ethnicity('Non-Hispanic/Non-Latino', true)],
            races: ['White'],
          },
        },
        hispanic_latino: {
          name: 'Hispanic/Latino Persons (Regardless of Race)',
          extra_filters: {
            ethnicities: [HUD.ethnicity('Hispanic/Latino', true)],
          },
        },
        black_african_american: {
          name: 'Black/African American Persons',
          extra_filters: {
            races: ['BlackAfAmerican'],
          },
        },
        asian: {
          name: 'Asian Persons',
          extra_filters: {
            races: ['Asian'],
          },
        },
        american_indian_alaskan_native: {
          name: 'American Indian/Alaskan Native Persons',
          extra_filters: {
            races: ['AmIndAKNative'],
          },
        },
        native_hawaiian_other_pacific_islander: {
          name: 'Native Hawaiian/Other Pacific Islander',
          extra_filters: {
            races: ['NativeHIOtherPacific'],
          },
        },
        multi_racial: {
          name: 'Multiracial',
          extra_filters: {
            races: ['MultiRacial'],
          },
        },
        #### TODO:  unimplemented Filters
        # fleeing_dv
        # veteran
        # has_disability
        # has_rrh_move_in_date
        # has_psh_move_in_date
        # first_time_homeless
        # returned_to_homelessness_from_permanent_destination
      }.freeze
    end

    private def run_inflow
      inflow_filter = ::Filters::FilterBase.new(
        user_id: filter.user_id,
        enforce_one_year_range: false,
      )
      # FIXME: need to send symbolic project_types in addition to numeric
      # filter[:project_type_codes] =
      options = filter.to_h
      inflow_filter.update(options)
      Reporting::MonthlyReports::Base.class_for(inflow_filter.sub_population).new(
        user: inflow_filter.user,
        filter: inflow_filter,
      )
    end
  end
end
