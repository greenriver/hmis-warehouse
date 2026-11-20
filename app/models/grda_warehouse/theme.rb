###
# Copyright Green River Data Group, Inc.
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
    has_one_attached :hmis_logo do |attachable|
      attachable.variant :thumb, resize_to_limit: [100, 100]
    end

    ALLOWED_LOGO_CONTENT_TYPES = ['image/png', 'image/jpeg', 'image/gif', 'image/webp', 'image/svg+xml'].freeze
    LOGO_SLOTS = ['logo', 'print_logo', 'hmis_logo'].freeze
    MAX_LOGO_BYTE_SIZE = 2.megabytes

    # Only slots being changed are checked, so saving the theme never fails on a stored logo that predates this check.
    validate :validate_changed_logos

    # Max 1 theme per HMIS origin
    validates_uniqueness_of :hmis_origin,
                            scope: :client,
                            if: :hmis_theme?, # only run validation if this is an HMIS theme
                            conditions: -> { where.not(hmis_value: [nil, '']) } # only validate uniqueness against other HMIS themes

    # Encapsulate the logic for getting the theme CSS
    # If the theme is not set, set it to the default and save it for the future
    def self.css_file_contents
      theme = active_theme
      return theme.sanitize_css(theme.css_file_contents) if theme.css_file_contents.present?

      theme.set_theme_default_css!
      theme.save!
      theme.sanitize_css(theme.css_file_contents)
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

    def self.hmis_logo
      theme = active_theme
      # Use the main logo unless an HMIS logo is attached and is an allowed image type
      return theme.logo unless allowed_logo?(theme.hmis_logo)

      theme.hmis_logo
    end

    def self.allowed_logo?(attachment)
      attachment.attached? && ALLOWED_LOGO_CONTENT_TYPES.include?(attachment.blob.content_type)
    end

    def logo_image?(slot)
      return false unless LOGO_SLOTS.include?(slot.to_s)

      self.class.allowed_logo?(public_send(slot))
    end

    def self.logo_for_type(type)
      case type
      when 'print_logo'
        print_logo
      when 'hmis_logo'
        hmis_logo
      else
        logo
      end
    end

    def self.active_theme
      where(client: ENV.fetch('CLIENT')).first_or_create
    end

    # Exposes the sanitized theme CSS to the IdP login screens (see Theme::CssController).
    # Currently just wraps `.css_file_contents`; kept as its own method so IdP-specific
    # CSS handling can diverge from the main site theme later without touching the
    # controller. If the configured CSS doesn't set `--op-accent`, the IdP falls back
    # to its own default accent color -- Rails doesn't need to supply one.
    def self.idp_theme_css
      css_file_contents
    end

    # Sanitize CSS entered by the user. The allowlist is the standard properties from
    # Sanitize::Config::RELAXED, plus any --custom-properties present in the input (their names
    # can't be known in advance, and they're inert without a matching var() consumer).
    # Sanitize::CSS itself filters property *values* (url(javascript:...), expression(), etc.).
    # The final `.delete('<')` guards against this CSS being embedded inside an HTML <style>
    # block (see application.html.haml) -- e.g. a "</style" breakout. It removes every "<"
    # unconditionally rather than matching a complete tag/sequence, so it can't suffer the
    # classic incomplete-sanitization bypass (CodeQL rb/incomplete-multi-character-sanitization)
    # where removing a nested match splices the surrounding text back into the original sequence.
    def sanitize_css(raw_css)
      return '' if raw_css.blank?

      custom_properties = raw_css.scan(/(--[a-zA-Z_][a-zA-Z0-9_-]*)\s*:/).flatten
      allowed_properties = (Sanitize::Config::RELAXED[:css][:properties] + custom_properties).to_set

      sanitized = Sanitize::CSS.stylesheet(
        raw_css,
        css: Sanitize::Config::DEFAULT[:css].merge(properties: allowed_properties),
      )
      sanitized.delete('<')
    end

    def set_theme_default_logo!
      return if logo.attached?

      attach_default_logo(logo, find_logo_path(ENV['LOGO']))
    end

    def set_theme_default_hmis_logo!
      return if hmis_logo.attached?

      attach_default_logo(hmis_logo, find_logo_path(ENV['LOGO']))
    end

    def set_theme_default_print_logo!
      return if print_logo.attached?

      attach_default_logo(print_logo, client_logo_path(ENV['PRINT_LOGO']) || find_logo_path(ENV['LOGO']))
    end

    def self.encoded_logo
      cached_encoded_attachment(active_theme.logo)
    end

    def self.encoded_print_logo
      cached_encoded_attachment(active_theme.print_logo)
    end

    def self.encoded_hmis_logo
      cached_encoded_attachment(active_theme.hmis_logo)
    end

    def self.cached_encoded_attachment(attachment)
      return nil unless attachment.attached?

      blob = attachment.blob
      cache_path = encoded_logo_cache_path(blob.checksum)

      if ::File.exist?(cache_path)
        ::File.read(cache_path)
      else
        encoded = Base64.strict_encode64(attachment.download)
        FileUtils.mkdir_p(::File.dirname(cache_path))
        ::File.binwrite(cache_path, encoded)
        encoded
      end
    end

    def self.encoded_logo_cache_path(checksum)
      Rails.root.join('tmp', 'theme_encoded_logo', checksum)
    end

    private def find_logo_path(logo_name)
      client_logo_path(logo_name) || logo_directory.join('open_path.svg').to_s
    end

    private def client_logo_path(logo_name)
      return if logo_name.blank?

      Dir.glob("#{logo_directory.join(logo_name)}.*").first
    end

    private def attach_default_logo(attachment, path)
      return unless ::File.exist?(path)

      attachment.attach(io: StringIO.new(::File.binread(path)), filename: ::File.basename(path))
    end

    private def logo_directory
      Rails.root.join('app', 'assets', 'images', 'theme', 'logo')
    end

    def set_theme_default_css!
      return if css_file_contents.present?

      self.css_file_contents = css_file_contents_default
    end

    def hmis_theme?
      hmis_value.present?
    end

    private def validate_changed_logos
      LOGO_SLOTS.select { |slot| attachment_changes.key?(slot) }.each do |slot|
        attachment = public_send(slot)
        next unless attachment.attached?

        errors.add(slot, 'must be a PNG, JPEG, GIF, WebP or SVG image') unless self.class.allowed_logo?(attachment)
        errors.add(slot, "must be #{MAX_LOGO_BYTE_SIZE / 1.megabyte} MB or smaller") if attachment.blob.byte_size > MAX_LOGO_BYTE_SIZE
      end
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
