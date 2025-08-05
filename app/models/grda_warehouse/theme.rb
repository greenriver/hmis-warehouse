###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Example for testing:
# GrdaWarehouse::Theme.create!(
#   client: 'myclient', # should match ENV['CLIENT']
#   hmis_value: {
#     palette: {
#       primary: {
#         main: '#0D394E',
#       },
#       secondary: {
#         main: '#357650',
#       },
#     },
#   }
# )

module GrdaWarehouse
  class Theme < GrdaWarehouseBase
    has_one_attached :logo do |attachable|
      attachable.variant :thumb, resize_to_limit: [100, 100]
    end
    has_one_attached :print_logo do |attachable|
      attachable.variant :thumb, resize_to_limit: [100, 100]
    end
    has_one_attached :careplan_logo do |attachable|
      attachable.variant :thumb, resize_to_limit: [100, 100]
    end

    # Max 1 theme per HMIS origin
    validates_uniqueness_of :hmis_origin,
                            scope: :client,
                            if: :hmis_theme?, # only run validation if this is an HMIS theme
                            conditions: -> { where.not(hmis_value: [nil, '']) } # only validate uniqueness against other HMIS themes

    # Encapsulate the logic for getting the theme CSS
    # If the theme is not set, set it to the default and save it for the future
    def self.css_file_contents
      theme = active_theme
      return theme.css_file_contents if theme.css_file_contents.present?

      theme.set_theme_default_css!
      theme.save!
      theme.css_file_contents
    end

    def self.logo
      theme = active_theme
      theme.set_theme_default_logo! unless theme.logo.attached?
      theme.logo
    end

    def self.print_logo
      theme = active_theme
      theme.set_theme_default_print_logo! unless theme.print_logo.attached?
      theme.print_logo
    end

    def self.careplan_logo
      active_theme.careplan_logo
    end

    def self.active_theme
      where(client: ENV.fetch('CLIENT')).first_or_create
    end

    def set_theme_default_logo!
      return if logo.attached?
      return unless logo_file_exists?

      logo.attach(logo_default)
    end

    def set_theme_default_print_logo!
      return if print_logo.attached?

      print_logo.attach(print_logo_default) if print_logo_file_exists?
      print_logo.attach(logo_default) if logo_file_exists?
    end

    def logo_default
      find_and_open_logo(ENV['LOGO'])
    end

    def print_logo_default
      find_and_open_logo(ENV['PRINT_LOGO'])
    end

    def self.encoded_logo
      Base64.strict_encode64(active_theme.logo.download)
    end

    def self.encoded_print_logo
      Base64.strict_encode64(active_theme.print_logo.download)
    end

    def self.encoded_careplan_logo
      Base64.strict_encode64(active_theme.careplan_logo.download)
    end

    private def find_logo_path(logo_name)
      default_logo = 'open_path.svg'
      return logo_directory.join(default_logo) if logo_name.blank?

      logo_base_path = logo_directory.join(logo_name)
      found_path = Dir.glob(logo_base_path.to_s + '.*').first
      return logo_directory.join(default_logo) if found_path.blank?

      found_path
    end

    private def find_and_open_logo(logo_name)
      ::File.open(find_logo_path(logo_name))
    end

    private def logo_directory
      Rails.root.join('app', 'assets', 'images', 'theme', 'logo')
    end
    private def logo_file_exists?
      ::File.exist?(find_logo_path(ENV['LOGO']))
    end

    private def print_logo_file_exists?
      ::File.exist?(find_logo_path(ENV['PRINT_LOGO']))
    end

    def set_theme_default_css!
      return if css_file_contents.present?

      self.css_file_contents = css_file_contents_default
    end

    def hmis_theme?
      hmis_value.present?
    end

    def self.hmis_theme_for_origin(origin)
      hmis_themes = GrdaWarehouse::Theme.where(client: ENV['CLIENT']&.to_sym).filter(&:hmis_theme?)

      # Look for theme that matches this HMIS origin. The origin is the value of field `hmis` on the DataSource
      theme = hmis_themes.find { |t| t.hmis_origin == origin }
      return theme if theme

      # Use 'default' theme if there is one (default=no origin specified)
      hmis_themes.find { |t| !t.hmis_origin.present? }
    end

    private def css_file_contents_default
      # Select the correct theme stylesheet based on ENV['CLIENT']
      client_theme_name = ENV['CLIENT'].presence
      sheet_name = client_specific_css_file_exists? ? client_theme_name : 'default'
      ::File.read(Rails.root.join(::File.join(*self.class.css_path, "#{sheet_name}.css")))
    end

    def self.css_path
      ['app', 'assets', 'stylesheets', 'application', '_custom']
    end

    private def client_specific_css_file_exists?
      client_theme_name = ENV['CLIENT'].presence
      css_file = Rails.root.join(::File.join(*self.class.css_path, "#{client_theme_name}.css"))
      client_theme_name && ::File.exist?(css_file)
    end
  end
end
