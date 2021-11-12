require 'rails_helper'

RSpec.describe Health::Tasks::ImportEpic, type: :model do
  ### TEMP_OUT # We're doing inserts that somehow avoid the uber transaction, cleanup the files at the end
  ### TEMP_OUT before(:all) do
  ### TEMP_OUT   Health.models_by_health_filename.each do |_, klass|
  ### TEMP_OUT     klass.delete_all
  ### TEMP_OUT   end
  ### TEMP_OUT   Health::DataSource.delete_all
  ### TEMP_OUT end

  ### TEMP_OUT after(:all) do
  ### TEMP_OUT   Health.models_by_health_filename.each do |_, klass|
  ### TEMP_OUT     klass.delete_all
  ### TEMP_OUT   end
  ### TEMP_OUT   Health::DataSource.delete_all
  ### TEMP_OUT end

  ### TEMP_OUT describe 'Importing' do
  ### TEMP_OUT   configs = [
  ### TEMP_OUT     OpenStruct.new(
  ### TEMP_OUT       data_source_name: 'BHCHP EPIC',
  ### TEMP_OUT       destination: 'var/health/testing',
  ### TEMP_OUT     ),
  ### TEMP_OUT   ]

  ### TEMP_OUT   describe 'None of the associated models contain any initial data' do
  ### TEMP_OUT     Health.models_by_health_filename.each do |_, klass|
  ### TEMP_OUT       count = klass.count
  ### TEMP_OUT       it "#{klass.name} contains no records" do
  ### TEMP_OUT         expect(count).to eq(0)
  ### TEMP_OUT       end
  ### TEMP_OUT     end
  ### TEMP_OUT   end

  ### TEMP_OUT   describe 'After the initial import' do
  ### TEMP_OUT     Health::DataSource.create!(name: 'BHCHP EPIC')
  ### TEMP_OUT     dest_path = configs.first.destination
  ### TEMP_OUT     FileUtils.mkdir_p(dest_path) unless Dir.exist?(dest_path)
  ### TEMP_OUT     FileUtils.cp(Dir.glob('spec/fixtures/files/health/epic/simple/*.csv'), dest_path)
  ### TEMP_OUT     Health::Tasks::ImportEpic.new(load_locally: true, configs: configs).run!
  ### TEMP_OUT     Health.models_by_health_filename.each do |file_name, klass|
  ### TEMP_OUT       record_count = File.readlines(File.join(dest_path, file_name)).size - 1
  ### TEMP_OUT       record_count -= 1 if klass.name == 'Health::Vaccination' # Ignoring duplicate
  ### TEMP_OUT       count = klass.count
  ### TEMP_OUT       it "#{klass.name} contains #{record_count} records" do
  ### TEMP_OUT         expect(count).to eq(record_count)
  ### TEMP_OUT       end
  ### TEMP_OUT     end
  ### TEMP_OUT   end

  ### TEMP_OUT   describe 'After a subsequent import, the numbers haven\'t changed' do
  ### TEMP_OUT     dest_path = 'var/health/'
  ### TEMP_OUT     FileUtils.cp(Dir.glob('spec/fixtures/files/health/epic/simple/*.csv'), dest_path)
  ### TEMP_OUT     Health::Tasks::ImportEpic.new(load_locally: true, configs: configs).run!
  ### TEMP_OUT     Health.models_by_health_filename.each do |file_name, klass|
  ### TEMP_OUT       record_count = File.readlines(File.join(dest_path, file_name)).size - 1
  ### TEMP_OUT       record_count -= 1 if klass.name == 'Health::Vaccination' # Ignoring duplicate
  ### TEMP_OUT       count = klass.count
  ### TEMP_OUT       it "#{klass.name} contains #{record_count} records" do
  ### TEMP_OUT         expect(count).to eq(record_count)
  ### TEMP_OUT       end
  ### TEMP_OUT     end
  ### TEMP_OUT   end

  ### TEMP_OUT   describe 'Files with only one row each do not import, and do not change the counts' do
  ### TEMP_OUT     dest_path = configs.first.destination
  ### TEMP_OUT     FileUtils.cp(Dir.glob('spec/fixtures/files/health/epic/simple/*.csv'), dest_path)
  ### TEMP_OUT     counts = {}
  ### TEMP_OUT     Health.models_by_health_filename.each do |file_name, klass|
  ### TEMP_OUT       source = File.join(dest_path, file_name)
  ### TEMP_OUT       counts[klass.name] = File.readlines(source).size - 1
  ### TEMP_OUT       lines = File.foreach(source).first(2)
  ### TEMP_OUT       File.open(source, 'wb') do |file|
  ### TEMP_OUT         lines.each do |line|
  ### TEMP_OUT           file.write(line)
  ### TEMP_OUT         end
  ### TEMP_OUT       end
  ### TEMP_OUT     end
  ### TEMP_OUT     Health::Tasks::ImportEpic.new(load_locally: true, configs: configs).run!
  ### TEMP_OUT     Health.models_by_health_filename.each do |file_name, klass|
  ### TEMP_OUT       file_path = File.join(dest_path, file_name)
  ### TEMP_OUT       count = klass.count
  ### TEMP_OUT       counts[klass.name] -= 1 if klass.name == 'Health::Vaccination' # Ignoring duplicate
  ### TEMP_OUT       it "#{klass.name} contains #{counts[klass.name]} records" do
  ### TEMP_OUT         expect(count).to eq(counts[klass.name])
  ### TEMP_OUT       end
  ### TEMP_OUT       FileUtils.rm_r(file_path)
  ### TEMP_OUT     end
  ### TEMP_OUT   end

  ### TEMP_OUT   describe 'Files with one fewer row decrease the counts by 1' do
  ### TEMP_OUT     dest_path = configs.first.destination
  ### TEMP_OUT     FileUtils.cp(Dir.glob('spec/fixtures/files/health/epic/simple/*.csv'), dest_path)
  ### TEMP_OUT     counts = {}
  ### TEMP_OUT     Health.models_by_health_filename.each do |file_name, klass|
  ### TEMP_OUT       source = File.join(dest_path, file_name)
  ### TEMP_OUT       counts[klass.name] = File.readlines(source).size - 2 # ignore header and one line
  ### TEMP_OUT       lines = File.foreach(source).first(counts[klass.name] + 1)
  ### TEMP_OUT       File.open(source, 'wb') do |file|
  ### TEMP_OUT         lines.each do |line|
  ### TEMP_OUT           file.write(line)
  ### TEMP_OUT         end
  ### TEMP_OUT       end
  ### TEMP_OUT     end
  ### TEMP_OUT     Health::Tasks::ImportEpic.new(load_locally: true, configs: configs).run!
  ### TEMP_OUT     Health.models_by_health_filename.each do |file_name, klass|
  ### TEMP_OUT       file_path = File.join(dest_path, file_name)
  ### TEMP_OUT       count = klass.count
  ### TEMP_OUT       counts[klass.name] -= 1 if klass.name == 'Health::Vaccination' # Ignoring duplicate
  ### TEMP_OUT       it "#{klass.name} contains #{counts[klass.name]} records" do
  ### TEMP_OUT         expect(counts[klass.name]).to eq(count)
  ### TEMP_OUT       end
  ### TEMP_OUT       FileUtils.rm_r(file_path)
  ### TEMP_OUT     end
  ### TEMP_OUT   end
  ### TEMP_OUT end
end
