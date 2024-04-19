require 'rails_helper'

RSpec.describe 'Import GPG Epic', type: :model do
  # We're doing inserts that somehow avoid the uber transaction, cleanup the files at the end
  before(:all) do
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

  describe 'Importing' do
    configs = [
      Health::ImportConfig.new(
        data_source_name: 'GPG EPIC',
        destination: 'var/health/testing',
        passphrase: 'test key',
        secret_key: File.read('spec/fixtures/files/health/secret.key'),
        encryption_key_name: 'test@greenriver.org',
      ),
    ]

    describe 'None of the associated models contain any initial data' do
      Health.models_by_health_filename.each do |_, klass|
        count = klass.count
        it "#{klass.name} contains no records" do
          expect(count).to eq(0)
        end
      end
    end

    it 'Imports encrypted data' do
      Health::DataSource.create!(name: 'GPG EPIC')
      dest_path = configs.first.destination
      FileUtils.mkdir_p(dest_path) unless Dir.exist?(dest_path)
      FileUtils.cp(Dir.glob('spec/fixtures/files/health/epic/gpg/*.gpg'), dest_path)
      Health::Tasks::ImportEpic.new(load_locally: true, configs: configs).run!

      expect(Health::Appointment.count).to eq(30)
    end
  end
end
