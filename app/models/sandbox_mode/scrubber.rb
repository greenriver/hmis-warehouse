###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Neutralizes external-integration credentials and queued work in a database
# restored from a production snapshot. Internal integrations (CAS, Superset,
# identity providers, inbound OAuth) are left as they are, except that identity
# providers stop managing users.
class SandboxMode::Scrubber
  class Refused < StandardError; end

  SECRET = 'sandbox-scrubbed'
  UNREACHABLE_HOST = 'sandbox.invalid'
  SKIPPED = 'skipped'

  def self.authorize!(env:, confirm:, sandbox_mode:)
    raise Refused, 'sandbox:scrub never runs in production' if env == 'production'
    raise Refused, 'sandbox:scrub requires SANDBOX_MODE=true' unless sandbox_mode
    raise Refused, "sandbox:scrub requires SANDBOX_SCRUB_CONFIRM=#{env}" unless confirm == env

    nil
  end

  # @return [Hash{String => Integer, String}] table name => rows changed, or 'skipped'
  def run!
    log_databases
    result = {}
    GrdaWarehouseBase.transaction { scrub_warehouse(result) }
    ApplicationRecord.transaction { scrub_app(result) }
    if health_database_configured?
      HealthBase.transaction { scrub_health(result) }
    else
      result['import_configs'] = SKIPPED
      result['soap_configs'] = SKIPPED
    end
    GrdaWarehouse::Config.invalidate_cache
    result.each { |table, count| Rails.logger.warn("SandboxMode::Scrubber #{table}: #{count}") }
    result
  end

  private

  def scrub_warehouse(result)
    scrub(
      result, 'remote_credentials', GrdaWarehouse::RemoteCredential,
      secrets: [:password],
      active: false, endpoint: nil, bucket: 'disabled', path: nil, region: nil, additional_headers: {}, username: SECRET
    )
    scrub(result, 'remote_configs', GrdaWarehouse::RemoteConfig, active: false)
    scrub(
      result, 'hmis_import_configs', GrdaWarehouse::HmisImportConfig,
      secrets: [:s3_secret_access_key, :zip_file_password],
      active: false, s3_access_key_id: SECRET, s3_bucket_name: nil, s3_role_arn: nil, s3_external_id: nil
    )
    scrub(
      result, 'custom_imports_config', GrdaWarehouse::CustomImports::Config,
      secrets: [:s3_access_key_id, :s3_secret_access_key],
      active: false, s3_bucket: nil
    )
    scrub(result, 'eto_api_configs', GrdaWarehouse::EtoApiConfig, secrets: [:password], active: false, email: nil)
    scrub(result, 'eccovia_fetches', EccoviaData::Fetch, active: false)
    scrub(result, 'bo_configs', Bo::Config, secrets: [:pass], url: nil, server: nil, user: nil)
    scrub(result, 'hmis_supplemental_data_sets', HmisSupplemental::DataSet, sync_enabled: false)
    scrub(result, 'external_hmis_configurations', GrdaWarehouse::ExternalHmisConfiguration, base_url: nil)
    scrub(result, 'talentlms_configs', Talentlms::Config, secrets: [:api_key], subdomain: UNREACHABLE_HOST)
    scrub(result, 'public_report_settings', PublicReports::Setting, secrets: [:s3_access_key_id, :s3_secret], s3_bucket: nil)
    scrub(result, 'talentlms_logins', Talentlms::Login, secrets: [:password])
    scrub(result, 'text_message_topics', TextMessage::Topic, active_topic: false, arn: nil)
    scrub(result, 'lftp_s3_syncs', GrdaWarehouse::LftpS3Sync, secrets: [:ftp_pass], ftp_host: UNREACHABLE_HOST, ftp_user: SECRET)
    scrub(
      result, 'recurring_hmis_exports', GrdaWarehouse::RecurringHmisExport,
      secrets: [:s3_access_key_id, :s3_secret_access_key, :zip_password],
      s3_bucket: nil
    )
    scrub(result, 'data_sources', GrdaWarehouse::DataSource, import_paused: true)
    scrub(result, 'configs', GrdaWarehouse::Config, eto_api_available: false, send_sms_for_covid_reminders: false, rds_s3_integration_role_arn: nil)
  end

  def scrub_app(result)
    presign = AppConfigProperty.where(key: 'external_forms/presign_url').update_all(value: 'https://sandbox.invalid/')
    recaptcha = AppConfigProperty.where(key: 'external_forms/recaptcha_key').delete_all
    result['app_config_properties'] = presign + recaptcha
    result['delayed_jobs'] = Delayed::Job.delete_all
    scrub(result, 'idp_service_configs', Idp::ServiceConfig, manage_users: false)
  end

  def scrub_health(result)
    scrub(
      result, 'import_configs', Health::ImportConfig,
      secrets: [:password, :passphrase, :secret_key],
      active: false, host: nil, username: nil
    )
    scrub(result, 'soap_configs', Health::Soap::Config, secrets: [:pass], production_url: nil, test_url: nil, user: nil)
  end

  # Soft-deleted rows are included so a restored row cannot bring back working credentials.
  def scrub(result, table, model, secrets: [], **plain)
    rows = model.respond_to?(:with_deleted) ? model.with_deleted : model.unscoped
    count = plain.any? ? rows.update_all(plain) : rows.count
    scrub_secrets(rows, model, secrets) if secrets.any?
    result[table] = count
  end

  # Secrets go through the attr_encrypted writer so they stay decryptable.
  def scrub_secrets(rows, model, attributes)
    columns = attributes.flat_map do |attribute|
      encrypted = model.attr_encrypted_encrypted_attributes.fetch(attribute).fetch(:attribute).to_s
      [encrypted, "#{encrypted}_iv"].select { |column| model.column_names.include?(column) }
    end
    rows.find_each do |row|
      attributes.each { |attribute| row.public_send("#{attribute}=", SECRET) }
      row.update_columns(row.attributes.slice(*columns))
    end
  end

  def health_database_configured?
    HealthDbBase.connection_db_config.database.present? && HealthBase.connection.table_exists?('import_configs')
  rescue ActiveRecord::NoDatabaseError, ActiveRecord::ConnectionNotEstablished
    false
  end

  def log_databases
    names = {
      warehouse: GrdaWarehouseBase,
      app: ApplicationRecord,
      health: HealthDbBase,
    }.transform_values { |base| base.connection_db_config.database }
    Rails.logger.warn("SandboxMode::Scrubber scrubbing databases #{names.map { |k, v| "#{k}=#{v}" }.join(', ')}")
  end
end
