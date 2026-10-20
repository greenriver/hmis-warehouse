###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

require 'rails_helper'
require 'rake'

# The class is defined in the rake file, which Zeitwerk doesn't autoload. Load it once here;
# re-loading per example would redefine its constants.
load Rails.root.join('drivers/hmis/lib/tasks/one_time_scan_card_migration_20261020.rake')

RSpec.describe OneTimeScanCardMigration20261020 do
  let!(:data_source) { create(:hmis_primary_data_source) }
  let!(:cded) do
    create(:hmis_custom_data_element_definition, data_source: data_source, owner_type: 'Hmis::Hud::Client', key: 'legacy_card_id', repeats: true)
  end
  let!(:client) { create(:hmis_hud_client, data_source: data_source) }
  let!(:other_client) { create(:hmis_hud_client, data_source: data_source) }

  def add_value(client, value, definition: cded)
    create(:hmis_custom_data_element, data_source: data_source, data_element_definition: definition, owner: client, value_string: value)
  end

  def run!(dry_run: false, cded_key: cded.key)
    described_class.new(cded_key: cded_key, dry_run: dry_run).run!
  end

  def codes_for(client)
    Hmis::ScanCardCode.where(client: client).pluck(:value)
  end

  it 'left-pads short values to 7 digits and keeps longer values as-is' do
    add_value(client, '12345')
    add_value(other_client, '123456789')
    run!
    expect(codes_for(client)).to contain_exactly('0012345')
    expect(codes_for(other_client)).to contain_exactly('123456789')
  end

  it 'creates one active code per distinct value, including multiple values on one client' do
    add_value(client, '1')
    add_value(client, '2')
    add_value(client, '0000002')
    summary = run!
    expect(codes_for(client)).to contain_exactly('0000001', '0000002')
    expect(Hmis::ScanCardCode.where(client: client).active.count).to eq(2)
    expect(summary.created).to eq(2)
  end

  it 'leaves source custom data elements unchanged' do
    cde = add_value(client, ' 42 ')
    run!
    expect(cde.reload.value_string).to eq(' 42 ')
    expect(codes_for(client)).to contain_exactly('0000042')
  end

  it 'skips and reports blank and non-numeric values' do
    blank = add_value(client, ' ')
    alpha = add_value(other_client, 'abc12')
    summary = nil
    expect { summary = run! }.to output(/Invalid: CDE #{alpha.id}/).to_stdout
    expect(Hmis::ScanCardCode.count).to eq(0)
    expect(summary.invalid.map(&:custom_data_element_id)).to contain_exactly(blank.id, alpha.id)
  end

  it 'is a no-op on re-run' do
    add_value(client, '12345')
    run!
    expect { run! }.not_to(change { Hmis::ScanCardCode.with_deleted.count })
  end

  it 'does not restore a code that was soft-deleted on the same client' do
    add_value(client, '12345')
    create(:hmis_scan_card_code, client: client, value: '0012345').destroy!
    summary = run!
    expect(Hmis::ScanCardCode.where(client: client)).to be_empty
    expect(summary.already_present).to eq(1)
  end

  it 'reports a collision with an existing code on another client' do
    add_value(client, '12345')
    create(:hmis_scan_card_code, client: other_client, value: '0012345')
    summary = run!
    expect(codes_for(client)).to be_empty
    expect(summary.collisions.map(&:client_id)).to contain_exactly(client.id)
  end

  it 'reports a value shared by two clients in the source data and creates neither' do
    add_value(client, '12345')
    add_value(other_client, '0012345')
    summary = run!
    expect(Hmis::ScanCardCode.count).to eq(0)
    expect(summary.collisions.map(&:client_id)).to contain_exactly(client.id, other_client.id)
  end

  it 'ignores deleted clients and other custom data elements' do
    add_value(client, '1')
    other_cded = create(:hmis_custom_data_element_definition, data_source: data_source, owner_type: 'Hmis::Hud::Client', key: 'something_else')
    add_value(client, '2', definition: other_cded)
    add_value(other_client, '3')
    other_client.destroy!
    run!
    expect(Hmis::ScanCardCode.pluck(:value)).to contain_exactly('0000001')
  end

  it 'writes nothing on a dry run' do
    add_value(client, '12345')
    summary = run!(dry_run: true)
    expect(Hmis::ScanCardCode.count).to eq(0)
    expect(summary.created).to eq(1)
  end

  it 'raises when the custom data element definition does not exist' do
    expect { run!(cded_key: 'missing') }.to raise_error(ActiveRecord::RecordNotFound)
  end
end

RSpec.describe 'one_time_scan_card_migration_20261020 rake task', type: :task do
  let(:task_name) { 'one_time_scan_card_migration_20261020' }
  let(:migration) { instance_double(OneTimeScanCardMigration20261020, run!: nil) }

  before do
    Rake::Task.clear
    Rake.application = Rake::Application.new
    # Other rake specs clear the task list, so redefine the task; silence the constant redefinition warnings.
    silence_warnings { load Rails.root.join('drivers/hmis/lib/tasks/one_time_scan_card_migration_20261020.rake') }
    Rake::Task.define_task(:environment)
    allow(OneTimeScanCardMigration20261020).to receive(:new).and_return(migration)
  end

  def run_task(*args)
    Rake::Task[task_name].reenable
    Rake::Task[task_name].invoke(*args)
  end

  it 'defaults to a dry run' do
    run_task('legacy_card_id')
    expect(OneTimeScanCardMigration20261020).to have_received(:new).with(cded_key: 'legacy_card_id', dry_run: true)
    expect(migration).to have_received(:run!)
  end

  it 'applies when dry_run is false' do
    run_task('legacy_card_id', 'false')
    expect(OneTimeScanCardMigration20261020).to have_received(:new).with(cded_key: 'legacy_card_id', dry_run: false)
  end

  it 'requires a cded_key' do
    expect { run_task }.to raise_error(/cded_key is required/)
  end

  it 'rejects an unrecognized dry_run value' do
    expect { run_task('legacy_card_id', 'yes') }.to raise_error(/dry_run must be true or false/)
  end
end
