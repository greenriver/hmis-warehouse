###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

require 'memoist'

module PerformanceMeasurement
  class Report < SimpleReports::ReportInstance
    extend Memoist
    include Filter::ControlSections
    include Filter::FilterScopes
    include Reporting::Status
    include Rails.application.routes.url_helpers
    include ActionView::Helpers::NumberHelper
    include ArelHelper
    include PerformanceMeasurement::ResultCalculation

    acts_as_paranoid

    belongs_to :user
    has_many :clients
    has_many :projects
    has_many :results

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
        save_results
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
        f.update((options || {}).with_indifferent_access)
        f.update(start: f.end - 1.years)
        f
      end
    end

    def self.viewable_by(user)
      GrdaWarehouse::WarehouseReports::ReportDefinition.where(url: url).
        viewable_by(user).exists?
    end

    def self.url
      'performance_measurement/warehouse_reports/report'
    end

    def url
      performance_measurement_warehouse_reports_report_url(host: ENV.fetch('FQDN'), id: id, protocol: 'https')
    end

    def title
      _('CoC Performance Measurement Dashboard')
    end

    def report_sections
      @report_sections ||= build_control_sections
    end

    protected def build_control_sections
      [
        build_simple_control_section,
      ]
    end

    private def build_simple_control_section
      ::Filters::UiControlSection.new(id: 'general').tap do |section|
        section.add_control(
          id: 'start',
          required: true,
          value: filter.start,
        )
        section.add_control(
          id: 'coc_codes',
          label: 'CoC Codes',
          short_label: 'CoC',
          value: filter.chosen_coc_codes,
        )
      end
    end

    def multiple_project_types?
      true
    end

    def default_project_types
      [:ph, :es, :th, :sh, :so]
    end

    def report_path_array
      [
        :performance_measurement,
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
      scope
    end

    def report_scope_source
      GrdaWarehouse::ServiceHistoryEnrollment.entry
    end

    def can_see_client_details?(user)
      user.can_access_some_version_of_clients?
    end

    private def create_universe
      report_clients = {}
      add_clients(report_clients)
    end

    private def add_clients(report_clients)
      # Run CoC-wide SPMs for year prior to selected date and period 2 years prior
      # add records for each client to indicate which projects they were enrolled in within the report window
      project_clients = Set.new
      involved_projects = Set.new
      run_spm.each do |variant_name, spec|
        spm_fields.each do |parts|
          cells = parts[:cells]
          cells.each do |cell|
            spm_clients = answer_clients(spec[:report], *cell)
            spm_clients.each do |spm_client|
              report_client = report_clients[spm_client[:client_id]] || Client.new(report_id: id)
              report_client[:client_id] = spm_client[:client_id]
              report_client[:dob] = spm_client[:dob]
              # report_client["#{variant_name}_stayer"] = spm_client[:m3_active_project_types].present? # This is from 3.1 C6, which we don't calculate
              question = parts[:question]
              report_client["#{variant_name}_#{question[:name]}"] = question[:value_calculation].call(spm_client)
              spm_client[question[:history_source]].each do |row|
                involved_projects << row['project_id']
                project_clients << {
                  report_id: id,
                  client_id: spm_client[:client_id],
                  project_id: row['project_id'],
                  for_question: question[:name], # allows limiting for a specific response
                  period: variant_name,
                }
              end
              report_client["#{variant_name}_spm_id"] = spec[:report].id
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
      Project.import([:report_id, :project_id], involved_projects.map { |p_id| [id, p_id] })
      ClientProject.import(project_clients.first.keys, project_clients.map(&:values))
      universe.add_universe_members(report_clients)
    end

    private def answer(report, table, cell)
      report.answer(question: table, cell: cell).summary
    end

    private def answer_clients(report, table, cell)
      report.answer(question: table, cell: cell).universe_members.preload(:universe_membership).map(&:universe_membership)
    end

    private def run_spm
      # puts 'Running SPM'
      questions = [
        'Measure 1',
        'Measure 2',
        'Measure 3',
        'Measure 4',
        'Measure 5',
        'Measure 7',
      ]
      # NOTE: we need to include all homeless projects visible to this user, plus the chosen scope,
      # so that the returns calculation will work.
      # For now, we're using a fixed set of project types
      options = filter.to_h
      options[:project_type_codes] = [:es, :so, :sh, :th, :ph]
      # Because we want data back for all projects in the CoC we need to run this as the System User who will have access to everything
      options[:user_id] = User.setup_system_user.id

      # TODO: re-enable this
      # generator = HudSpmReport::Generators::Fy2020::Generator
      # variants.each do |_, spec|
      #   processed_filter = ::Filters::HudFilterBase.new(user_id: options[:user_id])
      #   processed_filter.update(options.deep_merge(spec[:options]))
      #   report = HudReports::ReportInstance.from_filter(
      #     processed_filter,
      #     generator.title,
      #     build_for_questions: questions,
      #   )
      #   generator.new(report).run!(email: false, manual: false)
      #   spec[:report] = report
      # end

      # for testing
      variants.values.reverse.each.with_index do |spec, i|
        spec[:report] = HudReports::ReportInstance.order(id: :desc).first(2)[i]
      end
      # return @variants with reports for each question
      variants
    end

    def variants
      @variants ||= {
        reporting: {
          options: {},
        },
        comparison: {
          options: {
            start: filter.start - 1.years,
            end: filter.end - 1.years,
          },
        },
      }
    end

    def spm_fields
      [
        {
          cells: [['3.2', 'C2']],
          title: 'Sheltered Clients',
          question: {
            name: :served_on_pit_date,
            value_calculation: ->(spm_client) { spm_client[:m3_active_project_types].present? },
            history_source: :m3_history,
          },
        },
        {
          cells: [['5.1', 'C4']],
          title: 'First Time',
          question: {
            name: :first_time,
            value_calculation: ->(spm_client) { spm_client[:m5_active_project_types].present? && spm_client[:m5_recent_project_types].blank? },
            history_source: :m5_history,
          },
        },
        {
          cells: [['1a', 'B2']],
          title: 'Length of Time Homeless in ES, SH, TH',
          question: {
            name: :days_homeless_es_sh_th,
            value_calculation: ->(spm_client) { spm_client[:m1a_es_sh_th_days] },
            history_source: :m1_history,
          },
        },
        {
          cells: [['1b', 'B2']],
          title: 'Length of Time Homeless in ES, SH, TH, PH',
          question: {
            name: :days_homeless_es_sh_th_ph,
            value_calculation: ->(spm_client) { spm_client[:m1b_es_sh_th_ph_days] },
            history_source: :m1_history,
          },
        },
        {
          cells: [['7a', 'C2']],
          title: 'Exits from SO',
          question: {
            name: :so_destination,
            value_calculation: ->(spm_client) { spm_client[:m7a1_destination] },
            history_source: :m7_history,
          },
        },
        {
          cells: [['7b.1', 'C2']],
          title: 'Exits from ES, SH, TH, RRH, PH with No Move-in',
          question: {
            name: :es_sh_th_rrh_destination,
            value_calculation: ->(spm_client) { spm_client[:m7b1_destination] },
            history_source: :m7_history,
          },
        },
        {
          cells: [['7b.2', 'C2']],
          title: 'RRH, PH with Move-in or Permanent Exit',
          questions: {
            name: :moved_in_destination, # NOTE: destination 0 == stayer in the SPM
            value_calculation: ->(spm_client) { spm_client[:m7b2_destination] },
            history_source: :m7_history,
          },
        },
      ]
    end

    # def calculate(variant, field, calculation, options)
    #   cell = "spm_#{field}"
    #   scope = clients.send(variant).send(cell)

    #   value = case calculation

    #   when :count
    #     scope.count
    #   when :average
    #     scope.average(cell)
    #   when :median
    #     scope.median(cell)
    #   when :percent
    #     # denominator should always be the "all" variant
    #     denominator = clients.send('spm_all_persons__all').send(options[:total]).count
    #     (scope.count / denominator.to_f) * 100 unless denominator.zero?
    #   when :count_destinations
    #     # spm_m7a1_destination
    #     rc_t = Client.arel_table
    #     scope.where(
    #       rc_t[:spm_m7a1_destination].in(Array.wrap(options[:destination])).
    #       or(rc_t[:spm_m7b1_destination].in(Array.wrap(options[:destination]))),
    #     ).count
    #   end
    #   value&.round(1) || 0
    # end
    # memoize :calculate
  end
end
