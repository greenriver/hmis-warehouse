###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module ProjectPassFail
  class ProjectPassFail < GrdaWarehouseBase
    self.table_name = :project_pass_fails
    include Filter::ControlSections
    include Filter::FilterScopes
    include Reporting::Status
    include Rails.application.routes.url_helpers

    belongs_to :user, optional: true
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
        f = ::Filters::FilterBase.new(user_id: user_id)
        f.set_from_params(options['filters'].with_indifferent_access)
        f
      end
    end

    def title
      'Project Pass/Fail Report'
    end

    def self.url
      'project_pass_fail/warehouse_reports/project_pass_fail'
    end

    def url
      project_pass_fail_warehouse_reports_project_pass_fail_url(host: ENV.fetch('FQDN'), id: id, protocol: 'https')
    end

    def run_and_save!
      update(started_at: Time.current)
      store_thresholds
      populate_projects
      populate_clients
      calculate_utilization_rates
      calculate_universal_data_element_rates
      calculate_timeliness
      projects.each(&:save!)
      assign_attributes(completed_at: Time.current)
      save
    end

    def utilization_rate_as_percent
      ((utilization_rate || 0) * 100).round(2)
    end

    def unit_utilization_rate_as_percent
      ((unit_utilization_rate || 0) * 100).round(2)
    end

    def within_utilization_threshold?
      utilization_rate.in?(utilization_range)
    end

    def within_unit_utilization_threshold?
      unit_utilization_rate.in?(utilization_range)
    end

    def within_timeliness_threshold?
      average_days_to_enter_entry_date <= timeliness_threshold
    end

    # Data quality acceptable error rates
    def universal_data_element_threshold
      value = (thresholds['universal_data_element_threshold'] || GrdaWarehouse::Config.get(:pf_universal_data_element_threshold))
      value / 100.0
    end

    # Acceptable utilization rates
    def utilization_range
      min = (thresholds['utilization_range_min'] || GrdaWarehouse::Config.get(:pf_utilization_min)) / 100.0
      max = (thresholds['utilization_range_max'] || GrdaWarehouse::Config.get(:pf_utilization_max)) / 100.0
      (min..max)
    end

    # Days allowed for entering entry assessments
    def timeliness_threshold
      thresholds['timeliness_threshold'] || GrdaWarehouse::Config.get(:pf_timeliness_threshold)
    end

    private def calculate_utilization_rates
      projects.each(&:calculate_utilization_rate)
      capacity = projects.sum(:available_beds)
      rate = if capacity.positive? && clients.exists?
        clients.sum(:days_served).to_f / filter.range.count / capacity
      else
        0
      end
      assign_attributes(utilization_rate: rate)
      capacity = projects.sum(:available_units)
      rate = if capacity.positive? && clients.heads_of_household.exists?
        clients.heads_of_household.sum(:days_served).to_f / filter.range.count / capacity
      else
        0
      end
      assign_attributes(unit_utilization_rate: rate)
    end

    private def calculate_universal_data_element_rates
      projects.each(&:calculate_universal_data_element_rates)

      outside_threshold = projects.map(&:within_universal_data_element_threshold?).count(false)
      assign_attributes(projects_failing_universal_data_elements: outside_threshold)
    end

    private def calculate_timeliness
      projects.each(&:calculate_timeliness)

      self.average_days_to_enter_entry_date = if clients.where(first_date_in_program: filter.range).exists?
        clients.where(first_date_in_program: filter.range).sum(:days_to_enter_entry_date) / clients.where(first_date_in_program: filter.range).count.to_f
      else
        0
      end
    end

    private def populate_projects
      projects = []
      hmis_projects.find_each do |project|
        average_unit_count = project.inventories.within_range(filter.as_date_range).map do |i|
          i.average_daily_inventory(range: filter.as_date_range, field: :UnitInventory)
        end.sum
        average_bed_count = project.inventories.within_range(filter.as_date_range).map do |i|
          i.average_daily_inventory(range: filter.as_date_range, field: :BedInventory)
        end.sum
        p = Project.new(
          project_pass_fail_id: id,
          project_id: project.id,
          available_units: average_unit_count,
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
          client = Client.new(
            project_pass_fail_id: id,
            project_id: project.id,
            days_served: days_of_service_for(apr_client.client_id, project),
          )
          client.calculate_universal_data_elements(apr_client)
          client.calculate_time_to_enter
          clients << client
        end

        Client.import(clients) if clients.any?
      end
    end

    private def days_of_service_for(source_client_id, project)
      destination_client_id = destination_client_id_for(source_client_id, project.project.data_source_id)
      project.service_counts_for(destination_client_id)
    end

    private def destination_client_id_for(source_client_id, data_source_id)
      source_client_lookup[[source_client_id, data_source_id]]
    end

    private def source_client_lookup
      @source_client_lookup ||= begin
        lookup = {}
        GrdaWarehouse::WarehouseClient.
          pluck(:source_id, :data_source_id, :destination_id).
          each do |row|
            lookup[[row.first, row.second]] = row.last
          end
        lookup
      end
    end

    private def run_apr(p_id)
      return unless RailsDrivers.loaded.include?(:hud_apr)

      apr_filter = ::Filters::HudFilterBase.new(
        start: filter.start,
        end: filter.end,
        user_id: user_id,
        project_ids: [p_id],
      )

      questions = [
        'Question 6',
      ]
      generator = HudApr::Generators::Apr::Fy2021::Generator
      apr = HudReports::ReportInstance.from_filter(apr_filter, generator.title, build_for_questions: questions)
      generator.new(apr).run!(email: false, manual: false)
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

    def projects_failing_universal_data_elements_percent
      return 0 unless projects.any?
      return 0 if projects_failing_universal_data_elements.zero?

      (projects_failing_universal_data_elements.to_f / projects.count * 100).round
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

    private def store_thresholds
      update(
        thresholds: {
          universal_data_element_threshold: GrdaWarehouse::Config.get(:pf_universal_data_element_threshold),
          utilization_range_min: GrdaWarehouse::Config.get(:pf_utilization_min),
          utilization_range_max: GrdaWarehouse::Config.get(:pf_utilization_max),
          timeliness_threshold: GrdaWarehouse::Config.get(:pf_timeliness_threshold),
        },
      )
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
