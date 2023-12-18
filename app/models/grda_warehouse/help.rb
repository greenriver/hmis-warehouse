###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class GrdaWarehouse::Help < GrdaWarehouseBase
  has_paper_trail

  DEFAULT_HELP_URL = 'https://github.com/greenriver/hmis-warehouse/wiki'.freeze

  scope :sorted, -> do
    order(title: :asc)
  end

  validates_presence_of :controller_path, :action_name
  validates_presence_of :title, :content, if: :internal?
  validates :external_url, url: { no_local: true, allow_blank: true }
  validates_presence_of :external_url, if: :external?

  def self.cleaned_path controller_path:, action_name:
    "#{controller_path}/#{action_name}"
  end

  def self.for_path controller_path:, action_name:
    find_by(controller_path: controller_path, action_name: action_name)
  end

  def internal?
    location.to_sym == :internal
  end

  def external?
    location.to_sym == :external
  end

  def available_locations
    {
      'Pop-up window (add title and content below)' => :internal,
      'Link to an external site (add a url)' => :external,
    }
  end

  def self.known_defaults
    [
      {
        controller_path: 'warehouse_reports',
        action_name: 'index',
        external_url: "#{DEFAULT_HELP_URL}/Report-Guide",
      },
      {
        controller_path: 'warehouse_reports/project/data_qualities',
        action_name: 'show',
        external_url: "#{DEFAULT_HELP_URL}/Project-Data-Quality-Report",
      },
      {
        controller_path: 'data_quality_reports',
        action_name: 'show',
        external_url: "#{DEFAULT_HELP_URL}/Project-Data-Quality-Report",
      },
      {
        controller_path: 'warehouse_reports/project/data_qualities',
        action_name: 'history',
        external_url: "#{DEFAULT_HELP_URL}/Project-Data-Quality-Report",
      },
      {
        controller_path: 'performance_dashboards/overview',
        action_name: 'index',
        external_url: "#{DEFAULT_HELP_URL}/Client-Performance",
      },
      {
        controller_path: 'warehouse_reports/health/eligibility',
        action_name: 'index',
        external_url: "#{DEFAULT_HELP_URL}/Eligibility-Determination-and-ACO-Status-Changes-(270-and-271)",
      },
      {
        controller_path: 'warehouse_reports/chronic',
        action_name: 'index',
        external_url: "#{DEFAULT_HELP_URL}/Potentially-Chronic-Clients",
      },
      {
        controller_path: 'warehouse_reports/client_in_project_during_date_range',
        action_name: 'index',
        external_url: "#{DEFAULT_HELP_URL}/Clients-in-a-project-for-a-given-date-range",
      },
      {
        controller_path: 'warehouse_reports/hud_chronics',
        action_name: 'index',
        external_url: "#{DEFAULT_HELP_URL}/HUD-Chronic",
      },
      {
        controller_path: 'warehouse_reports/first_time_homeless',
        action_name: 'index',
        external_url: "#{DEFAULT_HELP_URL}/First-Time-Homeless",
      },
      {
        controller_path: 'project_pass_fail/warehouse_reports/project_pass_fail',
        action_name: 'index',
        external_url: "#{DEFAULT_HELP_URL}/Project-Pass-Fail",
      },
      {
        controller_path: 'inactive_client_report/warehouse_reports/reports',
        action_name: 'index',
        external_url: "#{DEFAULT_HELP_URL}/Client-Activity-Report",
      },
      {
        controller_path: 'client_documents_report/warehouse_reports/reports',
        action_name: 'index',
        external_url: "#{DEFAULT_HELP_URL}/Client-Documents-Report",
      },
      {
        controller_path: 'core_demographics_report/warehouse_reports/core',
        action_name: 'index',
        external_url: "#{DEFAULT_HELP_URL}/Core-Demographics",
      },
      {
        controller_path: 'core_demographics_report/warehouse_reports/demographic_summary',
        action_name: 'index',
        external_url: "#{DEFAULT_HELP_URL}/Demographic-Summary-Report",
      },
      {
        controller_path: 'homeless_summary_report/warehouse_reports/reports',
        action_name: 'index',
        external_url: "#{DEFAULT_HELP_URL}/System-Performance-Measures-by-Sub-Population",
      },
      {
        controller_path: 'performance_measurement/warehouse_reports/reports',
        action_name: 'index',
        external_url: "#{DEFAULT_HELP_URL}/CoC-Performance-Measurement-Dashboard",
      },
      {
        controller_path: 'boston_reports/warehouse_reports/community_of_origins',
        action_name: 'index',
        external_url: "#{DEFAULT_HELP_URL}/Community-of-Origin",
      },
      {
        controller_path: 'system_pathways/warehouse_reports/reports',
        action_name: 'index',
        external_url: "#{DEFAULT_HELP_URL}/System-Pathways-Report",
      },
      {
        controller_path: 'clients_sub_pop/dashboards/clients',
        action_name: 'index',
        external_url: "#{DEFAULT_HELP_URL}/Population-Dashboards",
      },
      {
        controller_path: 'adults_with_children_sub_pop/dashboards/adults_with_children',
        action_name: 'index',
        external_url: "#{DEFAULT_HELP_URL}/Population-Dashboards",
      },
      {
        controller_path: 'adult_only_households_sub_pop/dashboards/adult_only_households',
        action_name: 'index',
        external_url: "#{DEFAULT_HELP_URL}/Population-Dashboards",
      },
      {
        controller_path: 'child_only_households_sub_pop/dashboards/child_only_households',
        action_name: 'index',
        external_url: "#{DEFAULT_HELP_URL}/Population-Dashboards",
      },
      {
        controller_path: 'non_veterans_sub_pop/dashboards/non_veterans',
        action_name: 'index',
        external_url: "#{DEFAULT_HELP_URL}/Population-Dashboards",
      },
      {
        controller_path: 'veterans_sub_pop/dashboards/veterans',
        action_name: 'index',
        external_url: "#{DEFAULT_HELP_URL}/Population-Dashboards",
      },
    ]
  end

  # Allow drivers to inject their help files
  def self.active_defaults
    known_defaults + Rails.application.config.help_links
  end

  def self.setup_default_links
    existing = where(controller_path: active_defaults.map { |m| m[:controller_path] }).pluck(:controller_path, :action_name)

    batch = []
    active_defaults.each do |record|
      next if existing.include?([record[:controller_path], record[:action_name]])

      batch << new(
        location: :external,
        controller_path: record[:controller_path],
        action_name: record[:action_name],
        external_url: record[:external_url],
        title: '',
        content: '',
      )
    end

    import(batch)
  end
end
