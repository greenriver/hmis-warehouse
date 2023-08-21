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
