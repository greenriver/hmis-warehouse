require 'rails_helper'

RSpec.describe 'Import GPG Epic', type: :model do
  # We're doing inserts that somehow avoid the uber transaction, cleanup the files at the end
  before do
    Health.models_by_health_filename.each do |_, klass|
      klass.delete_all
    end
    Health::DataSource.delete_all
  end

  after(:all) do
    Health.models_by_health_filename.each do |_, klass|
      klass.delete_all
    end
    Health::DataSource.delete_all
  end

  it 'Decrypts and imports the data' do
    configs = [
      Health::ImportConfig.new(
        data_source_name: 'GPG EPIC',
        destination: 'var/health/testing',
        passphrase: 'test key',
        secret_key: File.read('spec/fixtures/files/health/secret.key'),
        encryption_key_name: 'test@greenriver.org',
      ),
    ]

    # Make sure there is no data
    expect(Health::Appointment.count).to eq(0)

    # Run the importer
    Health::DataSource.create!(name: 'GPG EPIC')
    dest_path = configs.first.destination
    FileUtils.rm_rf(dest_path) if Dir.exist?(dest_path)
    FileUtils.mkdir_p(dest_path)
    FileUtils.cp(Dir.glob('spec/fixtures/files/health/epic/gpg/*.gpg'), dest_path)
    Health::Tasks::ImportEpic.new(load_locally: true, configs: configs).run!

    # Confirm data was imported
    expect(Health::Appointment.count).to eq(30)
  end
end
