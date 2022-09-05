###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class GrdaWarehouse::Help < GrdaWarehouseBase
  has_paper_trail

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
        external_url: 'https://github.com/greenriver/hmis-warehouse/wiki/Report-Guide',
      },
      {
        controller_path: 'warehouse_reports/project/data_qualities',
        action_name: 'show',
        external_url: 'https://github.com/greenriver/hmis-warehouse/wiki/Project-Data-Quality-Report',
      },
      {
        controller_path: 'data_quality_reports',
        action_name: 'show',
        external_url: 'https://github.com/greenriver/hmis-warehouse/wiki/Project-Data-Quality-Report',
      },
      {
        controller_path: 'warehouse_reports/project/data_qualities',
        action_name: 'history',
        external_url: 'https://github.com/greenriver/hmis-warehouse/wiki/Project-Data-Quality-Report',
      },
      {
        controller_path: 'performance_dashboards/overview',
        action_name: 'index',
        external_url: 'https://github.com/greenriver/hmis-warehouse/wiki/Client-Performance',
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
