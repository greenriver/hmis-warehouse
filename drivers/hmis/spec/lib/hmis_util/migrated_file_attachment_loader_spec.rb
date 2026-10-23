###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'

RSpec.describe HmisUtil::MigratedFileAttachmentLoader do
  let(:source) { 'migrated_files_spec' }
  let(:tracking) { 'migrated_file_statuses_spec' }
  let(:connection) { GrdaWarehouseBase.connection }
  let!(:data_source) { create(:hmis_data_source) }
  let!(:roi_tag) { create(:available_file_tag, name: 'ROI') }
  let!(:case_plan_tag) { create(:available_file_tag, name: 'Case Plan') }
  let!(:migrated_tag) { create(:available_file_tag, name: 'Migrated from WellSky') }
  let!(:user) { create(:hmis_user, data_source: data_source) }
  let!(:client) { create(:hmis_hud_client, data_source: data_source) }
  let!(:enrollment) { create(:hmis_hud_enrollment, data_source: data_source, client: client) }
  let(:stats) { {} }
  let(:stat_calls) { [] }
  let(:object_stat) do
    lambda do |key|
      stat_calls << key
      stats[key]
    end
  end

  before do
    connection.execute(<<~SQL)
      CREATE TEMP TABLE #{source} (
        client_id bigint NOT NULL, enrollment_id bigint, name varchar, note text, s3_key text,
        entity_name text, type text, user_id bigint, updated_by_id bigint, checksum text, size bigint,
        created_at timestamp, updated_at timestamp
      )
    SQL
  end

  def add_row(**overrides)
    attrs = {
      client_id: client.id, enrollment_id: enrollment.id, name: 'ROI.pdf', note: 'ROI',
      s3_key: "migration/mar/#{SecureRandom.hex(6)}", entity_name: 'ROI', type: 'Hmis::File',
      user_id: user.id, updated_by_id: user.id, checksum: 'h1B+rsMhta5QIRYTLrRk4A==', size: 4_389_645,
      created_at: Time.zone.parse('2026-10-08 22:33:02'), updated_at: Time.zone.parse('2026-10-08 22:33:02')
    }.merge(overrides)
    connection.execute("INSERT INTO #{source} (#{attrs.keys.join(', ')}) VALUES (#{attrs.values.map { |v| connection.quote(v) }.join(', ')})")
    attrs
  end

  def status(key)
    connection.select_one("SELECT * FROM #{tracking} WHERE s3_key = #{connection.quote(key)}")
  end

  def loader(**opts)
    described_class.new(source_table: source, tracking_table: tracking, dry_run: false, object_stat: object_stat, **opts)
  end

  it 'creates an attached HMIS file on the enrollment, tagged from its entity_name plus the migration tag, and records completion' do
    row = add_row(entity_name: ' ROI ')

    summary = loader.run!

    file = Hmis::File.find_by!(client_id: client.id)
    blob = file.client_file.blob
    expect(file).to have_attributes(
      enrollment_id: enrollment.id,
      user_id: user.id,
      updated_by_id: user.id,
      name: 'ROI.pdf',
      note: 'ROI',
      confidential: false,
      created_at: row[:created_at],
    )
    expect(blob).to have_attributes(
      key: row[:s3_key],
      filename: ActiveStorage::Filename.new('ROI.pdf'),
      content_type: 'application/pdf',
      byte_size: 4_389_645,
      checksum: 'h1B+rsMhta5QIRYTLrRk4A==',
      service_name: ActiveStorage::Blob.service.name.to_s,
    )
    expect(file.tags).to contain_exactly(roi_tag, migrated_tag)
    expect(status(row[:s3_key])).to include('active_storage_blob_id' => blob.id, 'errors' => nil)
    expect(status(row[:s3_key])['active_storage_completed_at']).not_to be_nil
    expect(summary.loaded).to eq(1)
  end

  it 'loads a headshot row as the client photo HMIS displays, ignoring its enrollment and entity_name' do
    add_row(entity_name: 'ROI', type: 'GrdaWarehouse::ClientFile', name: 'photo.jpg', enrollment_id: enrollment.id)

    summary = loader.run!

    photo = Hmis::Hud::Client.find(client.id).client_files.client_photos.newest_first.first
    expect(photo).to have_attributes(type: 'GrdaWarehouse::ClientFile', name: 'Client Headshot', enrollment_id: nil, visible_in_window: false)
    expect(photo.client_file.blob).to have_attributes(filename: ActiveStorage::Filename.new('photo.jpg'), content_type: 'image/jpeg')
    expect(photo.tag_list).to contain_exactly('Client Headshot', migrated_tag.id.to_s)
    expect(Hmis::File.where(client_id: client.id)).to be_empty
    expect(summary.headshots).to eq(1)
  end

  it 'tags Goal, Case Plans, and Action Step entities as Case Plan' do
    rows = ['Goal', 'Case Plans', 'Action Step'].map { |entity| add_row(entity_name: entity) }

    loader.run!

    rows.each do |row|
      file = GrdaWarehouse::File.find(ActiveStorage::Blob.find_by!(key: row[:s3_key]).attachments.sole.record_id)
      expect(file.tags).to contain_exactly(case_plan_tag, migrated_tag)
    end
  end

  it 'raises before writing anything when a required available tag is missing' do
    add_row
    migrated_tag.destroy!

    expect { loader.run! }.to raise_error(described_class::MissingAvailableFileTags, 'Missing available file tags: Migrated from WellSky')
    expect(GrdaWarehouse::File.count).to eq(0)
  end

  it 'raises before writing anything when an s3_key appears twice in the source' do
    row = add_row
    add_row(s3_key: row[:s3_key])

    expect { loader.run! }.to raise_error(described_class::DuplicateSourceKeys, "1 s3_keys appear more than once in #{source}")
    expect(GrdaWarehouse::File.count).to eq(0)
  end

  it 'records an error and loads nothing for an enrollment belonging to another client or a missing enrollment' do
    other_enrollment = create(:hmis_hud_enrollment, data_source: data_source, client: create(:hmis_hud_client, data_source: data_source))
    good = add_row
    wrong_person = add_row(enrollment_id: other_enrollment.id)
    no_enrollment = add_row(enrollment_id: nil)

    loader.run!

    expect(Hmis::File.pluck(:client_id, :enrollment_id)).to contain_exactly([client.id, enrollment.id])
    expect(status(wrong_person[:s3_key])).to include('errors' => "enrollment #{other_enrollment.id} not found for client #{client.id}", 'active_storage_completed_at' => nil)
    expect(status(no_enrollment[:s3_key])).to include('errors' => 'no enrollment_id', 'active_storage_completed_at' => nil)
    expect(status(good[:s3_key])['errors']).to be_nil
  end

  it 'records an error for a client id that is not in the HMIS data source' do
    warehouse_client = create(:grda_warehouse_hud_client) # different data source
    bad = add_row(client_id: warehouse_client.id)
    add_row

    loader.run!

    expect(Hmis::File.pluck(:client_id)).to contain_exactly(client.id)
    expect(status(bad[:s3_key])['errors']).to eq("client #{warehouse_client.id} not in HMIS data source")
  end

  it 'gives an unmapped, blank, or null entity_name only the migration tag' do
    rows = ['Client Profile', '  ', nil].map { |entity| add_row(entity_name: entity) }

    loader.run!

    rows.each do |row|
      file = GrdaWarehouse::File.find(ActiveStorage::Blob.find_by!(key: row[:s3_key]).attachments.sole.record_id)
      expect(file.tags).to contain_exactly(migrated_tag)
      expect(status(row[:s3_key])['errors']).to be_nil
    end
  end

  it 'records an error for an unknown type' do
    unknown_type = add_row(type: 'GrdaWarehouse::Upload')
    add_row

    loader.run!

    expect(GrdaWarehouse::File.pluck(:type)).to contain_exactly('Hmis::File')
    expect(status(unknown_type[:s3_key])['errors']).to eq('unknown type GrdaWarehouse::Upload')
  end

  it 'does not duplicate anything when run again' do
    add_row
    loader.run!

    expect { loader.run! }.not_to(change { [GrdaWarehouse::File.count, ActiveStorage::Blob.count, ActiveStorage::Attachment.count, ActsAsTaggableOn::Tagging.count] })
  end

  it 'replaces an attachment left behind for a file that was never committed' do
    row = add_row
    blob = ActiveStorage::Blob.create!(key: row[:s3_key], filename: 'ROI.pdf', byte_size: 4_389_645, checksum: row[:checksum], service_name: ActiveStorage::Blob.service.name)
    ActiveStorage::Attachment.insert_all!([{ name: 'client_file', record_type: 'GrdaWarehouse::File', record_id: GrdaWarehouse::File.maximum(:id).to_i + 1_000, blob_id: blob.id, created_at: Time.current }])

    loader.run!

    file = Hmis::File.find_by!(client_id: client.id)
    expect(ActiveStorage::Attachment.where(blob_id: blob.id).pluck(:record_id)).to contain_exactly(file.id)
  end

  it 'records a missing S3 object, then loads and clears the error once the object exists' do
    row = add_row(size: nil)
    loader.run!
    expect(status(row[:s3_key])).to include('errors' => 'S3 object not found', 'active_storage_completed_at' => nil)

    stats[row[:s3_key]] = described_class::ObjectStat.new(byte_size: 789)
    loader.run!

    expect(ActiveStorage::Blob.find_by!(key: row[:s3_key])).to have_attributes(byte_size: 789, checksum: row[:checksum])
    expect(status(row[:s3_key])['errors']).to be_nil
  end

  it 'leaves rows with no checksum out of the run' do
    no_checksum = add_row(checksum: nil, size: nil)
    blank_checksum = add_row(checksum: ' ')
    good = add_row
    stats[no_checksum[:s3_key]] = described_class::ObjectStat.new(byte_size: 789)

    summary = loader.run!

    expect(ActiveStorage::Blob.pluck(:key)).to contain_exactly(good[:s3_key])
    expect([status(no_checksum[:s3_key]), status(blank_checksum[:s3_key])]).to eq([nil, nil])
    expect(stat_calls).to be_empty
    expect(summary).to have_attributes(loaded: 1, errored: {})
  end

  it 'moves past an errored row in the middle of a batch' do
    keys = ['a', 'b', 'c'].map { |k| "migration/mar/#{k}" }
    add_row(s3_key: keys[0])
    add_row(s3_key: keys[1], type: 'GrdaWarehouse::Upload')
    add_row(s3_key: keys[2])

    summary = loader(batch_size: 1).run!

    expect(summary.loaded).to eq(2)
    expect(ActiveStorage::Blob.pluck(:key)).to contain_exactly(keys[0], keys[2])
  end

  it 'writes nothing in a dry run but reports what it would load' do
    add_row
    no_enrollment = add_row(enrollment_id: nil)

    summary = loader(dry_run: true).run!

    expect([GrdaWarehouse::File.count, ActiveStorage::Blob.count]).to eq([0, 0])
    expect(status(no_enrollment[:s3_key])).to be_nil
    expect(summary).to have_attributes(loaded: 1, dry_run: true, errored: { 'no enrollment_id' => 1 })
  end

  it 'loads with a blank user and a warning when the user does not exist' do
    missing_id = user.id + 10_000
    row = add_row(user_id: missing_id)

    summary = loader.run!

    expect(Hmis::File.pluck(:user_id, :updated_by_id)).to contain_exactly([nil, user.id])
    expect(status(row[:s3_key])['errors']).to eq("user #{missing_id} not found, left blank")
    expect(summary.warned).to eq(1)
  end

  it 'keeps the id of an uploader whose user account was soft-deleted' do
    deleted_user = create(:hmis_user, data_source: data_source)
    deleted_user.destroy!
    add_row(user_id: deleted_user.id)

    loader.run!

    expect(Hmis::File.pluck(:user_id)).to contain_exactly(deleted_user.id)
  end

  it 'records an error for a row with no name and still loads the rest of its batch' do
    nameless = add_row(name: '  ')
    good = add_row

    loader.run!

    expect(status(nameless[:s3_key])).to include('errors' => 'no name', 'active_storage_completed_at' => nil)
    expect(ActiveStorage::Blob.pluck(:key)).to contain_exactly(good[:s3_key])
  end

  it 'reports only its own work when one instance runs twice' do
    add_row
    instance = loader
    instance.run!
    add_row

    summary = instance.run!

    expect(summary.loaded).to eq(1)
  end

  it 'refuses to start while another run holds the loader lock' do
    add_row
    # A separate session: transactional tests hand every pool checkout the same one.
    config = GrdaWarehouseBase.connection_db_config.configuration_hash
    other = PG.connect(host: config[:host], port: config[:port], dbname: config[:database], user: config[:username], password: config[:password])
    other.exec_params('SELECT pg_advisory_lock(hashtext($1))', [described_class::LOCK_NAME])

    expect { loader.run! }.to raise_error(described_class::AlreadyRunning)
    expect(GrdaWarehouse::File.count).to eq(0)
  ensure
    other&.close
  end

  describe described_class::S3ObjectStat do
    let(:s3_client) { Aws::S3::Client.new(stub_responses: true, region: 'us-east-1', credentials: Aws::Credentials.new('key', 'secret')) }
    let(:stat) { described_class.new(client: s3_client, bucket_name: 'bucket') }

    it 'returns the object size' do
      s3_client.stub_responses(:head_object, content_length: 4_389_645)

      expect(stat.call('k')).to eq(HmisUtil::MigratedFileAttachmentLoader::ObjectStat.new(byte_size: 4_389_645))
    end

    it 'returns nil when the object is missing or not readable' do
      s3_client.stub_responses(:head_object, 'NotFound')
      expect(stat.call('k')).to be_nil

      s3_client.stub_responses(:head_object, 'Forbidden')
      expect(stat.call('k')).to be_nil
    end
  end
end
