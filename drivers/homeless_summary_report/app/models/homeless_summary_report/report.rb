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
      begin
        create_universe
      rescue Exception => e
        update(failed_at: Time.current)
        raise e
      end
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

    def default_project_types
      [:ph, :es, :th, :sh, :so]
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

    # @return filtered scope
    def report_scope
      # Report range
      scope = report_scope_source
      scope = filter_for_user_access(scope)
      scope = filter_for_range(scope)
      scope = filter_for_cocs(scope)
      scope = filter_for_head_of_household(scope)
      scope = filter_for_project_type(scope)
      scope = filter_for_data_sources(scope)
      scope = filter_for_organizations(scope)
      scope = filter_for_projects(scope)
      scope = filter_for_funders(scope)
      scope = filter_for_ca_homeless(scope)
      scope
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

    private def create_universe
      report_clients = {}
      add_clients(report_clients)
    end

    private def add_clients(report_clients)
      spm_reports = run_spm

      # Work through all the SPM report variants, building up the `report_clients` as we go.
      spm_reports.each do |variant_name, report|
        spm_fields.each do |spm_field, parts|
          cells = parts[:cells]
          cells.each do |cell|
            spm_clients = answer_clients(report[:report], *cell)
            spm_clients.each do |spm_client|
              report_client = report_clients[spm_client[:client_id]] || Client.new
              report_client[:client_id] = spm_client[:client_id]
              report_client[:first_name] = spm_client[:first_name]
              report_client[:last_name] = spm_client[:last_name]
              report_client[:report_id] = id
              report_client["spm_#{spm_field}"] = spm_client[spm_field]
              if field_measure(spm_field) == 7
                field_name = "spm_m#{cell.join('_')}".delete('.').downcase.to_sym
                report_client[field_name] = true
              end
              report_client["spm_#{variant_name}"] = report[:report].id
              report_clients[spm_client[:client_id]] = report_client
            end
          end
        end
      end

      # With all the fields populated we need to process `exited_from_homeless_system`
      report_clients = report_clients.transform_values! do |client|
        client.spm_exited_from_homeless_system = (
            client.spm_m7a1_c3 ||
            client.spm_m7a1_c4 ||
            client.spm_m7b1_c3
          ) && !client.spm_m7b2_c3
        client
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
      variants.map do |variant, spec|
        extra_filters = spec[:extra_filters] || {}
        processed_filter = ::Filters::HudFilterBase.new(user_id: filter.user_id)
        processed_filter.update(options.deep_merge(extra_filters))
        report = HudReports::ReportInstance.from_filter(
          processed_filter,
          generator.title,
          build_for_questions: questions,
        )
        generator.new(report).run!(email: false, manual: false)
        [variant, spec.merge(report: report)]
      end.to_h
    end

    def measures
      {
        'Measure 1' => {
          fields: m1_fields,
          headers: [
            'Client Count',
            'Average Days',
            'Median Days',
          ],
        },
        'Measure 2' => {
          fields: m2_fields,
          headers: [
            'Client Count',
            '% in Category',
          ],
        },
        'Measure 7' => {
          fields: {
            exited_from_homeless_system: {
              title: 'Clients',
              calculations: [:count, :count_destinations],
            },
          },
          headers: [
            'Client Count',
            'Permanent Destinations',
            'Temporary Destinations',
            'Institutional Destinations',
          ] + ::HUD.valid_destinations.map { |id, d| "#{d} (#{id})" },
        },
      }
      # Measure 1 is table with Client Count, Average Days, Median Days
      # Measure 2 is table with Client Count, % in each category
      # Measure 7 is table with Client Count, Permanent Destination Count, Temporary Destination Count, Permanent Unknown count,
      # Measure 7 is table with Client Count, column for count of every destination
    end

    def destinations
      [
        HUD.permanent_destinations,
        HUD.temporary_destinations,
        HUD.institutional_destinations,
      ] + HUD.valid_destinations.keys
    end

    def field_measure(field)
      return 1 if field.start_with?('m1')
      return 2 if field.start_with?('m2')
      return 7 if field.start_with?('m7') || field.start_with?('exited')
    end

    def m1_fields
      spm_fields.filter { |f, _| field_measure(f) == 1 }
    end

    def m2_fields
      {
        m2_reentry_days: {
          title: 'Clients exiting to Permanent Destinations',
          calculations: [:count, :percent],
          total: :spm_m2_reentry_days,
        },
        m2_reentry_0_to_180_days: {
          title: 'Re-entering within 6 months',
          calculations: [:count, :percent],
          total: :spm_m2_reentry_days,
        },
        m2_reentry_181_to_365_days: {
          title: 'Re-entering within 6-12 months',
          calculations: [:count, :percent],
          total: :spm_m2_reentry_days,
        },
        m2_reentry_366_to_730_days: {
          title: 'Re-entering within 1-2 years',
          calculations: [:count, :percent],
          total: :spm_m2_reentry_days,
        },
      }
    end

    def m7_fields
      spm_fields.keys.filter { |f| field_measure(f) == 7 }.concat(
        [
          :m7a1_c2,
          :m7a1_c3,
          :m7a1_c4,
          :m7b1_c2,
          :m7b1_c3,
          :m7b2_c2,
          :m7b2_c3,
          :exited_from_homeless_system,
        ],
      )
    end

    def spm_fields
      {
        m1a_es_sh_days: {
          cells: [['1a', 'C2']],
          title: 'Clients with ES or SH stays',
          calculations: [:count, :average, :median],
        },
        m1a_es_sh_th_days: {
          cells: [['1a', 'C3']],
          title: 'Clients with ES, SH, or TH stays',
          calculations: [:count, :average, :median],
        },
        m1b_es_sh_ph_days: {
          cells: [['1b', 'C2']],
          title: 'Clients with ES, SH, or PH stays',
          calculations: [:count, :average, :median],
        },
        m1b_es_sh_th_ph_days: {
          cells: [['1b', 'C3']],
          title: 'Clients with ES, SH, TH, or PH stays',
          calculations: [:count, :average, :median],
        },
        m2_reentry_days: {
          cells: [['2', 'B7']],
          title: 'Clients Re-Entering Homelessness',
        },
        m7a1_destination: {
          cells: [
            ['7a.1', 'C2'],
            ['7a.1', 'C3'],
            ['7a.1', 'C4'],
          ],
          title: 'Exiting SO',
        },
        m7b1_destination: {
          cells: [
            ['7b.1', 'C2'],
            ['7b.1', 'C3'],
          ],
          title: 'ES, SH, TH, and PH-RRH who exited',
        },
        m7b2_destination: {
          cells: [
            ['7b.2', 'C2'],
            ['7b.2', 'C3'],
          ],
          title: 'PH projects except PH-RRH who exited after moving into housing',
        },
      }.freeze
    end

    def variants
      @variants ||= self.class.report_variants
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
        adults_with_children_where_parenting_adult_18_to_24: {
          name: 'Adults in Adult/Child Households where the Parenting Adult is 18-24',
          extra_filters: {
            household_type: :with_children,
            hoh_only: true,
            age_ranges: [
              :eighteen_to_twenty_four,
            ],
          },
        },
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
        fleeing_dv: {
          name: 'Currently Fleeing DV',
          extra_filters: {
            currently_fleeing: [1],
          },
        },
        veteran: {
          name: 'Veterans',
          extra_filters: {
            veteran_statuses: [1],
          },
        },
        has_disability: {
          name: 'With Indefinite and Impairing Disability',
          extra_filters: {
            indefinite_disabilities: [1],
          },
        },
        has_rrh_move_in_date: {
          name: 'Moved in to RRH',
          extra_filters: {
            rrh_move_in: true,
          },
        },
        has_psh_move_in_date: {
          name: 'Moved in to PSH',
          extra_filters: {
            psh_move_in: true,
          },
        },
        first_time_homeless: {
          name: 'First Time Homeless in Past Two Years',
          extra_filters: {
            first_time_homeless: true,
          },
        },
        # NOTE: only display this on Measure 1 (it will never work on Measure 2)
        returned_to_homelessness_from_permanent_destination: {
          name: 'Returned to Homelessness from Permanent Destination',
          extra_filters: {
            returned_to_homelessness_from_permanent_destination: true,
          },
        },
      }.freeze
    end

    def exclude_variants(measure_name, variant)
      @exclude_variants ||= {
        'Measure 2' => [:returned_to_homelessness_from_permanent_destination],
        'Measure 7' => [:returned_to_homelessness_from_permanent_destination],
      }
      @exclude_variants[measure_name.to_s]&.include?(variant)
    end

    def calculate(variant, field, calculation, options)
      cell = "spm_#{field}"
      scope = clients.send(variant).send(cell)

      value = case calculation

      when :count
        scope.count
      when :average
        scope.average(cell)
      when :median
        scope.median(cell)
      when :percent
        denominator = clients.send(variant).send(options[:total]).count
        (scope.count / denominator.to_f) * 100 unless denominator.zero?
      when :count_destinations
        # spm_m7a1_destination
        rc_t = Client.arel_table
        scope.where(
          rc_t[:spm_m7a1_destination].in(Array.wrap(options[:destination])).
          or(rc_t[:spm_m7b1_destination].in(Array.wrap(options[:destination]))),
        ).count
      end
      value&.round(1) || 0
    end
  end
end
