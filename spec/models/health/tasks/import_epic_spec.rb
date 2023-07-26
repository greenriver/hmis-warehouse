require 'rails_helper'

RSpec.describe Health::Tasks::ImportEpic, type: :model do
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
      OpenStruct.new(
        data_source_name: 'BHCHP EPIC',
        destination: 'var/health/testing',
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

    describe 'After the initial import' do
      Health::DataSource.create!(name: 'BHCHP EPIC')
      dest_path = configs.first.destination
      FileUtils.mkdir_p(dest_path) unless Dir.exist?(dest_path)
      FileUtils.cp(Dir.glob('spec/fixtures/files/health/epic/simple/*.csv'), dest_path)
      Health::Tasks::ImportEpic.new(load_locally: true, configs: configs).run!
      Health.models_by_health_filename.each do |file_name, klass|
        record_count = File.readlines(File.join(dest_path, file_name)).size - 1
        record_count -= 1 if klass.name == 'Health::Vaccination' # Ignoring duplicate
        count = klass.count
        it "#{klass.name} contains #{record_count} records" do
          expect(count).to eq(record_count)
        end
      end
    end

    describe 'After a subsequent import, the numbers haven\'t changed' do
      dest_path = 'var/health/'
      FileUtils.cp(Dir.glob('spec/fixtures/files/health/epic/simple/*.csv'), dest_path)
      Health::Tasks::ImportEpic.new(load_locally: true, configs: configs).run!
      Health.models_by_health_filename.each do |file_name, klass|
        record_count = File.readlines(File.join(dest_path, file_name)).size - 1
        record_count -= 1 if klass.name == 'Health::Vaccination' # Ignoring duplicate
        count = klass.count
        it "#{klass.name} contains #{record_count} records" do
          expect(count).to eq(record_count)
        end
      end
    end

    describe 'Files with only one row each do not import, and do not change the counts' do
      dest_path = configs.first.destination
      FileUtils.cp(Dir.glob('spec/fixtures/files/health/epic/simple/*.csv'), dest_path)
      counts = {}
      Health.models_by_health_filename.each do |file_name, klass|
        source = File.join(dest_path, file_name)
        counts[klass.name] = File.readlines(source).size - 1
        lines = File.foreach(source).first(2)
        File.open(source, 'wb') do |file|
          lines.each do |line|
            file.write(line)
          end
        end
      end
      Health::Tasks::ImportEpic.new(load_locally: true, configs: configs).run!
      Health.models_by_health_filename.each do |file_name, klass|
        file_path = File.join(dest_path, file_name)
        count = klass.count
        counts[klass.name] -= 1 if klass.name == 'Health::Vaccination' # Ignoring duplicate
        it "#{klass.name} contains #{counts[klass.name]} records" do
          expect(count).to eq(counts[klass.name])
        end
        FileUtils.rm_r(file_path)
      end
    end

    describe 'Files with one fewer row decrease the counts by 1' do
      dest_path = configs.first.destination
      FileUtils.cp(Dir.glob('spec/fixtures/files/health/epic/simple/*.csv'), dest_path)
      counts = {}
      Health.models_by_health_filename.each do |file_name, klass|
        source = File.join(dest_path, file_name)
        counts[klass.name] = File.readlines(source).size - 2 # ignore header and one line
        lines = File.foreach(source).first(counts[klass.name] + 1)
        File.open(source, 'wb') do |file|
          lines.each do |line|
            file.write(line)
          end
        end
      end
      Health::Tasks::ImportEpic.new(load_locally: true, configs: configs).run!
      Health.models_by_health_filename.each do |file_name, klass|
        file_path = File.join(dest_path, file_name)
        count = klass.count
        counts[klass.name] -= 1 if klass.name == 'Health::Vaccination' # Ignoring duplicate
        it "#{klass.name} contains #{counts[klass.name]} records" do
          expect(counts[klass.name]).to eq(count)
        end
        FileUtils.rm_r(file_path)
      end
    end
  end
end
