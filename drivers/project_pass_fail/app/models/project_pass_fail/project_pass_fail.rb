###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module ProjectPassFail
  class ProjectPassFail < GrdaWarehouseBase
    self.table_name = :project_pass_fails
    include Filter::ControlSections
    include Filter::FilterScopes
    include Reporting::Status

    belongs_to :user
    has_many :projects, inverse_of: :project_pass_fail
    has_many :clients, inverse_of: :project_pass_fail

    scope :viewable_by, ->(user) do
      return all if user.can_view_all_reports?
      return where(user_id: user.id) if user.can_view_assigned_reports?

      none
    end

    scope :ordered, -> do
      order(updated_at: :desc)
    end

    def filter
      @filter ||= begin
        f = ::Filters::FilterBase.new
        f.set_from_params(options['filters'].with_indifferent_access)
        f
      end
    end

    def title
      'Project Pass/Fail Report'
    end

    def url
      project_pass_fail_warehouse_reports_project_pass_fail_url(host: ENV.fetch('FQDN'))
    end

    def run_and_save!
      populate_projects
      populate_clients
      run_calculations
    end

    private def run_calculations
      # The following methods set the appropriate data, but don't save so we can save in a batch
      calculate_utilization_rates
      calculate_universal_data_element_rates

      projects.each(&:save!)
    end

    private def calculate_universal_data_element_rates
      projects.each(&:calculate_universal_data_element_rates)
    end

    private def calculate_utilization_rates
      projects.each(&:calculate_utilization_rate)
    end

    private def populate_projects
      projects = []
      hmis_projects.find_each do |project|
        average_bed_count = project.inventories.within_range(filter.range).map do |i|
          i.average_daily_inventory(range: filter.range, field: :BedInventory)
        end.sum
        p = Project.new(
          project_pass_fail_id: id,
          project_id: project.id,
          available_beds: average_bed_count,
        )
        projects << p
      end

      Project.import(projects) if projects.any?
    end

    private def populate_clients
      projects.each do |project|
        clients = []
        project.apr = run_apr(project.project_id)
        project.apr.universe('Question 6').universe_members.preload(:universe_membership).find_each do |member|
          apr_client = member.universe_membership
          clients << Client.new(
            project_pass_fail_id: id,
            project_pass_fails_project_id: project.id,
            client_id: apr_client.client_id,
            first_name: apr_client.first_name,
            last_name: apr_client.last_name,
            first_date_in_program: apr_client.first_date_in_program,
            last_date_in_program: apr_client.last_date_in_program,
            disabling_condition: apr_client.disabling_condition,
            dob: apr_client.dob,
            dob_quality: apr_client.dob_quality,
            ethnicity: apr_client.ethnicity,
            gender: apr_client.gender,
            name_quality: apr_client.name_quality,
            race: apr_client.race,
            ssn_quality: apr_client.ssn_quality,
            ssn: apr_client.ssn,
            veteran_status: apr_client.veteran_status,
            relationship_to_hoh: apr_client.relationship_to_hoh,
            enrollment_created: apr_client.enrollment_created,
            enrollment_coc: apr_client.enrollment_coc,
          )
        end

        Client.import(clients) if clients.any?
      end
    end

    private def run_apr(p_id)
      return unless RailsDrivers.loaded.include?(:hud_apr)

      apr_filter = ::Filters::FilterBase.new(
        start: filter.start,
        end: filter.end,
        user_id: user_id,
        project_ids: [p_id],
      )

      questions = [
        'Question 6',
      ]
      generator = HudApr::Generators::Apr::Fy2020::Generator
      apr = HudReports::ReportInstance.from_filter(apr_filter, generator.title, build_for_questions: questions)
      # FIXME: figure out how to make this run without emailing
      generator.new(apr).run!
      apr
    end

    private def hmis_projects
      GrdaWarehouse::Hud::Project.where(id: filter.effective_project_ids)
    end

    def key_for_display(key)
      label = self.class.option_labels[key.to_sym]
      return label if label

      key.humanize
    end

    def value_for_display(key, value)
      case key.to_sym
      when :start, :end
        Date.parse(value)
      when :coc_codes
        filter.chosen(key.to_sym)
      when :project_type_numbers, :data_source_ids, :organization_ids, :project_ids, :project_group_ids
        filter.chosen(key.to_sym).join(', ')
      else
        value
      end
    end

    def self.option_labels
      {
        coc_code: 'CoCs',
        organization_ids: 'Organizations',
        project_ids: 'Projects',
        data_source_ids: 'Data Sources',
        project_type_numbers: 'Project Types',
      }
    end
  end
end
