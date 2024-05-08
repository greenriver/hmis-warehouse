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

      return if Rails.env.development? || Rails.env.test?

      raise 'Missing AppConfigProperty for presign url' if presign_url.blank?
      raise 'Missing submission bucket' if submission_s3_url.blank?
    end

    def submission_s3_url
      GrdaWarehouse::RemoteCredentials::S3.for_active_slug('public_bucket')&.s3&.bucket&.url
    end

    def csp_content
      <<~CSP
        default-src 'self';
        script-src 'self' 'unsafe-inline' https://www.google.com https://www.gstatic.com https://code.jquery.com https://cdn.jsdelivr.net https://js.sentry-cdn.com;
        style-src 'self' 'unsafe-inline' https://cdn.jsdelivr.net;
        img-src 'self' data:;
        connect-src 'self' #{base_url(presign_url)} #{base_url(submission_s3_url)} https://sentry.io;
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

    protected

    # remove the path of a url (for inclusion in CSP)
    def base_url(url)
      return if url.blank?
      return if url =~ /\A\// # is a relative url, like might be used in development

      URI.join(url, '/').to_s
    end
  end
end
