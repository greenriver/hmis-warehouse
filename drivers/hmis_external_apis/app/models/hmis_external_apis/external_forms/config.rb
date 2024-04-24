###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::ExternalForms
  class Config
    PROPERTIES = [:site_logo_alt, :site_logo_url, :site_logo_width, :site_logo_height, :recaptcha_key, :presign_url, :sentry_sdk_url].freeze
    private_constant :PROPERTIES
    attr_reader(*PROPERTIES)

    def initialize
      # This could be dryed up if we repeat this pattern
      attr_keys = PROPERTIES.map { |attr| "external_forms/#{attr}" }
      settings = AppConfigProperty.where(key: attr_keys).index_by(&:key)
      PROPERTIES.zip(attr_keys).each do |attr, key|
        instance_variable_set(:"@#{attr}", settings[key]&.value&.freeze)
      end
      # for local development use:
      # AppConfigProperty.create!(key: "external_forms/presign_url", value: "/hmis_external_api/external_forms/presign")
      raise 'Missing AppConfigProperty for presign url' if presign_url.blank?
    end

    def csp_content
      <<~CSP
        default-src 'self';
        script-src 'self' 'unsafe-inline' https://www.google.com https://www.gstatic.com https://code.jquery.com https://cdn.jsdelivr.net https://js.sentry-cdn.com;
        style-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net;
        img-src 'self' data:;
        connect-src 'self' #{Rails.env.development? ? nil : presign_url} https://sentry.io;
        frame-src https://www.google.com;
        font-src 'self';
      CSP
    end

    def js_config
      {
        recaptchaKey: recaptcha_key,
        presignUrl: presign_url,
      }
    end
  end
end
