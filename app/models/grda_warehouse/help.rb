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
    []
  end

  # Allow drivers to inject their help files
  def self.active_defaults
    known_defaults + Rails.application.config.help_links
  end

  def self.setup_default_links
    existing = where(controller_path: active_defaults.map { |m| m[:controller_path] }).pluck(:controller_path, :action_name).to_h
    batch = []
    active_defaults.each do |help|
      next if existing[help[:controller_path]] == help[:action_name]

      batch << new(
        location: :external,
        controller_path: help[:controller_path],
        action_name: help[:action_name],
        external_url: help[:external_url],
        title: '',
        content: '',
      )
    end

    import(batch)
  end
end
