###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe SandboxMode::Scrubber do
  describe '.authorize!' do
    it 'refuses production even when confirmed and in sandbox mode' do
      expect { described_class.authorize!(env: 'production', confirm: 'production', sandbox_mode: true) }.to raise_error(described_class::Refused)
    end

    it 'refuses when sandbox mode is off' do
      expect { described_class.authorize!(env: 'staging', confirm: 'staging', sandbox_mode: false) }.to raise_error(described_class::Refused)
    end

    it 'refuses when the confirmation is missing' do
      expect { described_class.authorize!(env: 'staging', confirm: nil, sandbox_mode: true) }.to raise_error(described_class::Refused)
    end

    it 'refuses when the confirmation names another environment' do
      expect { described_class.authorize!(env: 'staging', confirm: 'development', sandbox_mode: true) }.to raise_error(described_class::Refused)
    end

    it 'returns nil when confirmed, in sandbox mode, outside production' do
      expect(described_class.authorize!(env: 'staging', confirm: 'staging', sandbox_mode: true)).to be_nil
    end
  end

  describe '#run!' do
    subject(:result) { described_class.new.run! }

    let!(:credential) do
      create(:grda_remote_s3, active: true, endpoint: 'https://s3.partner.example', bucket: 'partner-bucket', path: 'in', password: 'live-secret', additional_headers: { 'x-key' => 'live' })
    end

    it 'blanks a remote credential and makes its secret decrypt to the placeholder' do
      result

      credential.reload
      expect(credential).to have_attributes(
        active: false,
        endpoint: nil,
        bucket: 'disabled',
        path: nil,
        region: nil,
        additional_headers: {},
        username: 'sandbox-scrubbed',
        password: 'sandbox-scrubbed',
      )
    end

    it 'scrubs soft-deleted credentials' do
      deleted = create(:grda_remote_s3, active: true, password: 'live-secret')
      deleted.destroy

      result

      scrubbed = GrdaWarehouse::RemoteCredential.with_deleted.find(deleted.id)
      expect(scrubbed).to have_attributes(active: false, password: 'sandbox-scrubbed')
    end

    it 'reports rows changed per table, including soft-deleted rows' do
      create(:grda_remote_s3).destroy

      expect(result['remote_credentials']).to eq(2)
    end

    it 'is idempotent' do
      described_class.new.run!
      first = credential.reload.attributes.except('updated_at', 'encrypted_password', 'encrypted_password_iv')

      described_class.new.run!

      expect(credential.reload.attributes.except('updated_at', 'encrypted_password', 'encrypted_password_iv')).to eq(first)
      expect(credential.password).to eq('sandbox-scrubbed')
    end

    it 'deletes every delayed job' do
      2.times { Delayed::Job.create!(handler: '--- {}') }

      result

      expect(Delayed::Job.count).to eq(0)
    end

    it 'deactivates HMIS import configs and pauses data sources' do
      import_config = create(:grda_warehouse_hmis_import_config, active: true, s3_bucket_name: 'b', s3_role_arn: 'arn:aws:iam::1:role/x', s3_secret_access_key: 'live', zip_file_password: 'live-zip', s3_external_id: 'live-external-id')
      data_source = create(:source_data_source)
      data_source.update_columns(import_paused: false)

      result

      expect(import_config.reload).to have_attributes(active: false, s3_bucket_name: nil, s3_role_arn: nil, s3_access_key_id: 'sandbox-scrubbed', s3_secret_access_key: 'sandbox-scrubbed', zip_file_password: 'sandbox-scrubbed', s3_external_id: nil)
      expect(GrdaWarehouse::DataSource.with_deleted.find(data_source.id).import_paused).to be(true)
    end

    it 'blanks recurring export and LFTP sync secrets' do
      export = create(:recurring_hmis_export, :with_s3_settings, :with_zip_encryption)
      export.update!(s3_access_key_id: 'live-id', s3_secret_access_key: 'live-secret')
      sync = GrdaWarehouse::LftpS3Sync.create!(ftp_host: 'ftp.partner.example', ftp_user: 'someone', ftp_pass: 'live', ftp_path: '/in', data_source: create(:source_data_source))

      result

      expect(export.reload).to have_attributes(s3_bucket: nil, s3_access_key_id: 'sandbox-scrubbed', s3_secret_access_key: 'sandbox-scrubbed', zip_password: 'sandbox-scrubbed')
      expect(sync.reload).to have_attributes(ftp_host: 'sandbox.invalid', ftp_user: 'sandbox-scrubbed', ftp_pass: 'sandbox-scrubbed')
    end

    it 'blanks the remaining warehouse integration tables' do
      eto = GrdaWarehouse::EtoApiConfig.create!(email: 'x@partner.example', password: 'live', active: true, data_source: create(:source_data_source))
      bo = Bo::Config.create!(url: 'https://bo.example', server: 'bo', user: 'someone', pass: 'live')
      lms = Talentlms::Config.new(subdomain: 'partner', api_key: 'live').tap { |config| config.save!(validate: false) }
      topic = TextMessage::Topic.create!(arn: 'arn:aws:sns:us-east-1:1:t', active_topic: true)
      hmis = GrdaWarehouse::ExternalHmisConfiguration.create!(base_url: 'https://hmis.partner.example', data_source: create(:source_data_source))

      result

      expect(eto.reload).to have_attributes(active: false, email: nil, password: 'sandbox-scrubbed')
      expect(bo.reload).to have_attributes(url: nil, server: nil, user: nil, pass: 'sandbox-scrubbed')
      expect(lms.reload).to have_attributes(subdomain: 'sandbox.invalid', api_key: 'sandbox-scrubbed')
      expect(topic.reload).to have_attributes(active_topic: false, arn: nil)
      expect(hmis.reload.base_url).to be_nil
    end

    it 'replaces public report S3 credentials and bucket, and training logins, with decryptable placeholders' do
      settings = PublicReports::Setting.create!(s3_bucket: 'live-bucket', s3_access_key_id: 'live-key', s3_secret: 'live-secret')
      lms = Talentlms::Config.new(subdomain: 'partner', api_key: 'live').tap { |config| config.save!(validate: false) }
      login = Talentlms::Login.create!(login: 'someone', password: 'live-password', user: create(:user), config: lms)

      result

      expect(settings.reload).to have_attributes(s3_bucket: nil, s3_access_key_id: 'sandbox-scrubbed', s3_secret: 'sandbox-scrubbed')
      expect(login.reload).to have_attributes(login: 'someone', password: 'sandbox-scrubbed')
      expect(result).to include('public_report_settings' => 1, 'talentlms_logins' => 1)
    end

    it 'turns off remote configs, custom imports, supplemental syncs, and Eccovia fetches' do
      remote_config = GrdaWarehouse::RemoteConfig.create!(type: 'GrdaWarehouse::RemoteConfig', active: true, remote_credential: credential)
      custom = GrdaWarehouse::CustomImports::Config.create!(user: create(:user), active: true, s3_bucket: 'b', s3_access_key_id: 'live', s3_secret_access_key: 'live', data_source: create(:source_data_source))
      supplemental = create(:hmis_supplemental_data_set, sync_enabled: true, data_source: create(:source_data_source), remote_credential: credential)
      fetch = EccoviaData::Fetch.create!(credentials: EccoviaData::Credential.create!(username: 'u', password: 'p', active: true), active: true)

      result

      expect(remote_config.reload.active).to be(false)
      expect(custom.reload).to have_attributes(active: false, s3_bucket: nil, s3_access_key_id: 'sandbox-scrubbed', s3_secret_access_key: 'sandbox-scrubbed')
      expect(supplemental.reload.sync_enabled).to be(false)
      expect(fetch.reload.active).to be(false)
    end

    it 'turns off integration flags in configs, keeps the CAS URL, and drops the cached config' do
      config = GrdaWarehouse::Config.first_or_create
      config.update!(eto_api_available: true, send_sms_for_covid_reminders: true, rds_s3_integration_role_arn: 'arn:aws:iam::1:role/x', cas_url: 'https://cas.internal.example')
      expect(GrdaWarehouse::Config.get(:eto_api_available)).to be(true)

      result

      expect(config.reload).to have_attributes(eto_api_available: false, send_sms_for_covid_reminders: false, rds_s3_integration_role_arn: nil, cas_url: 'https://cas.internal.example')
      expect(GrdaWarehouse::Config.get(:eto_api_available)).to be(false)
    end

    it 'repoints external form presigning, drops the recaptcha key, and leaves other properties' do
      AppConfigProperty.create!(key: 'external_forms/presign_url', value: 'https://live.example/presign')
      AppConfigProperty.create!(key: 'external_forms/recaptcha_key', value: 'live-key')
      other = AppConfigProperty.create!(key: 'something/else', value: 'kept')

      result

      expect(AppConfigProperty.find_by(key: 'external_forms/presign_url').value).to eq('https://sandbox.invalid/')
      expect(AppConfigProperty.find_by(key: 'external_forms/recaptcha_key')).to be_nil
      expect(other.reload.value).to eq('kept')
    end

    it 'keeps identity providers active but stops them managing users, including soft-deleted ones' do
      idp = create(:idp_service_config, active: true, manage_users: true)
      deleted_idp = create(:idp_service_config, active: true, manage_users: true, connector_id: 'other', name: 'Other')
      deleted_idp.destroy

      result

      expect(idp.reload).to have_attributes(active: true, manage_users: false)
      expect(Idp::ServiceConfig.with_deleted.find(deleted_idp.id).manage_users).to be(false)
    end

    it 'leaves identity provider columns other than manage_users unchanged' do
      idp = create(:idp_service_config, active: true, manage_users: true)
      before_attributes = idp.reload.attributes.except('manage_users', 'updated_at')

      result

      expect(idp.reload.attributes.except('manage_users', 'updated_at')).to eq(before_attributes)
      expect(idp.service_token).to eq('test-token-secret-key')
    end

    it 'leaves inbound API configurations alone' do
      inbound = HmisExternalApis::InboundApiConfiguration.create!(external_system_name: 'partner', hashed_api_key: 'hashed', plain_text_reminder: 'abcd', internal_system: create(:internal_system))

      expect { result }.not_to(change { inbound.reload.attributes })
    end

    it 'leaves inbound OAuth applications alone' do
      app = Doorkeeper::Application.create!(name: 'inbound', redirect_uri: 'https://app.internal.example/cb')

      expect { result }.not_to(change { app.reload.attributes })
    end

    context 'when the health database is configured' do
      it 'blanks health import and SOAP configs' do
        import = Health::ImportConfig.create!(active: true, host: 'sftp.partner.example', username: 'someone', password: 'live', passphrase: 'live', secret_key: 'live')
        soap = Health::Soap::Config.create!(name: 'masshealth', production_url: 'https://p.example', test_url: 'https://t.example', user: 'someone', pass: 'live')

        result

        expect(import.reload).to have_attributes(active: false, host: nil, username: nil, password: 'sandbox-scrubbed', passphrase: 'sandbox-scrubbed', secret_key: 'sandbox-scrubbed')
        expect(soap.reload).to have_attributes(production_url: nil, test_url: nil, user: nil, pass: 'sandbox-scrubbed')
      end
    end

    context 'when the health database is not configured' do
      before do
        unconfigured = instance_double(ActiveRecord::DatabaseConfigurations::HashConfig, database: nil)
        allow(HealthDbBase).to receive(:connection_db_config).and_return(unconfigured)
      end

      it 'reports the health tables as skipped and still scrubs the warehouse' do
        expect(result).to include('import_configs' => 'skipped', 'soap_configs' => 'skipped')
        expect(credential.reload.active).to be(false)
      end
    end

    context 'when the health database does not exist' do
      before { allow(HealthBase).to receive(:connection).and_raise(ActiveRecord::NoDatabaseError) }

      it 'reports the health tables as skipped and still scrubs the warehouse' do
        expect(result).to include('import_configs' => 'skipped', 'soap_configs' => 'skipped')
        expect(credential.reload.active).to be(false)
      end
    end

    context 'when the health connection is not established' do
      before { allow(HealthBase).to receive(:connection).and_raise(ActiveRecord::ConnectionNotEstablished) }

      it 'reports the health tables as skipped and still scrubs the warehouse' do
        expect(result).to include('import_configs' => 'skipped', 'soap_configs' => 'skipped')
        expect(credential.reload.active).to be(false)
      end
    end

    context 'when the health database has no import_configs table' do
      before do
        connection = HealthBase.connection
        allow(HealthBase).to receive(:connection).and_return(connection)
        allow(connection).to receive(:table_exists?).and_call_original
        allow(connection).to receive(:table_exists?).with('import_configs').and_return(false)
      end

      it 'reports the health tables as skipped and still scrubs the warehouse' do
        expect(result).to include('import_configs' => 'skipped', 'soap_configs' => 'skipped')
        expect(credential.reload.active).to be(false)
      end
    end

    it 'logs database names and per-table counts at warn without secret values' do
      messages = []
      allow(Rails.logger).to receive(:warn) { |message| messages << message.to_s }

      result

      expect(messages).to include(a_string_matching(/#{Regexp.escape(GrdaWarehouseBase.connection_db_config.database)}/))
      expect(messages).to include(a_string_matching(/remote_credentials.*1/))
      expect(messages.join).not_to include('live-secret')
    end
  end
end
