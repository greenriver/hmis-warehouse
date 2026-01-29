###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module HmisExternalApis::ExternalForms
  class Config
    PROPERTIES = [:site_logo_alt, :site_logo_url, :site_logo_width, :site_logo_height, :recaptcha_key, :presign_url, :sentry_sdk_url, :csp_content].freeze
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
    end

    def js_config
      {
        recaptchaKey: recaptcha_key,
        presignUrl: presign_url,
      }
    end

    # Validate that all necessary creds and config are present to support publishing
    # external forms and consuming external form submissions.
    # See https://docs.google.com/document/d/1gV_naB47tUd0xB57EZFyWPjybbOMj2TKm2T1UDC2FU4/edit?tab=t.0#heading=h.58f9u5u7aj7f for more details on setup.
    def self.validate_external_forms_setup
      logger = Rails.logger
      missing = []

      logger.info('Validating External Forms setup...')

      # validate: public bucket credential (for serving published HTML forms)
      public_bucket = GrdaWarehouse::RemoteCredentials::S3.where(slug: 'public_bucket').first
      if public_bucket.nil?
        missing << 'remote_credential:S3 slug=public_bucket (for published HTML forms)'
        logger.warn('missing RemoteCredentials::S3 with slug=public_bucket  ')
      else
        logger.info("public_bucket credential found: active=#{public_bucket.active?} bucket=#{public_bucket.bucket.inspect}")
        logger.warn('public_bucket credential is inactive') unless public_bucket.active?
      end

      # validate: hmis_external_form_submissions credential (for storing incoming submissions)
      submissions_bucket = GrdaWarehouse::RemoteCredentials::S3.where(slug: 'hmis_external_form_submissions').first
      if submissions_bucket.nil?
        missing << 'remote_credential:S3 slug=hmis_external_form_submissions (for incoming submissions)'
        logger.warn('missing RemoteCredentials::S3 with slug=hmis_external_form_submissions')
      else
        logger.info("hmis_external_form_submissions credential found: active=#{submissions_bucket.active?} bucket=#{submissions_bucket.bucket.inspect}")
        logger.warn('hmis_external_form_submissions credential is inactive') unless submissions_bucket.active?
      end

      # validate: hmis_external_forms_shared_key (for encrypting submission data)
      encryption_key = GrdaWarehouse::RemoteCredentials::SymmetricEncryptionKey.where(slug: 'hmis_external_forms_shared_key').first
      if encryption_key.nil?
        missing << 'remote_credential:SymmetricEncryptionKey slug=hmis_external_forms_shared_key (for captcha score / submission data)'
        logger.warn('missing RemoteCredentials::SymmetricEncryptionKey with slug=hmis_external_forms_shared_key')
      else
        logger.info("hmis_external_forms_shared_key found: active=#{encryption_key.active?}")
        logger.warn('hmis_external_forms_shared_key credential is inactive') unless encryption_key.active?
      end

      # validate: required app config properties (for configuring the external form)
      [:presign_url, :recaptcha_key, :sentry_sdk_url].each do |key|
        key = "external_forms/#{key}"
        value = AppConfigProperty.find_by(key: key)&.value
        if value.blank?
          missing << "AppConfigProperty key=#{key}"
          logger.warn("missing AppConfigProperty key=#{key}")
        else
          logger.info("AppConfigProperty #{key} present (value=#{value.inspect})")
        end
      end

      if missing.any?
        logger.warn("❌ External Forms setup validation complete: missing/misconfigured=#{missing.join(' | ')}")
      else
        logger.info('✅ External Forms setup validation complete: no missing items detected')
      end

      missing
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
