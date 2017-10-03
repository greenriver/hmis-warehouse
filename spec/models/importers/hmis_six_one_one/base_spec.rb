require 'rails_helper'

RSpec.describe Importers::HMISSixOneOne::Base, type: :model do
    let(:data_source) {create :grda_warehouse_data_source}
    let(:file_path) { 'spec/fixtures/files/importers/hmis_six_on_one/enrollment_test_files' }
    let(:source_file_path) { File.join(file_path, 'source')}
    let(:import_path) {File.join(file_path, data_source.id.to_s)}
  describe 'When importing' do
    it 'will have three clients' do
      # duplicate the fixture file as it gets manipulated
      FileUtils.cp_r(source_file_path, import_path)
      importer = Importers::HMISSixOneOne::Base.new(file_path: file_path, data_source_id: data_source.id, remove_files: false)
      importer.import!
      FileUtils.rm_rf(import_path)
      expect(GrdaWarehouse::Hud::Client.count).to eq(3)
      
    end
    
  end
#   let(:existing_export) {build :existing_export}
#   let(:new_export_same_id_different_start) {build :new_export_same_id_different_start}
#   let(:new_export_same_id_later_end) {build :new_export_same_id_later_end}
#   let(:new_export_same_id_earlier_end) {build :new_export_same_id_earlier_end}
#   let(:new_export_different_id) {build :new_export_different_id}

#   describe 'When export ids match, but start date is different' do
#     it 'Raise an exception' do
#       base_importer = Importers::Base.new
#       expect { base_importer.stop_if_export_is_invalid(existing_export: existing_export, new_export: new_export_same_id_different_start) }.to raise_exception(RuntimeError, /Refusing to process export/)
#     end
#   end

#   describe 'When export ids match, but new end date is before old end date' do
#     it 'Raise an exception' do
#       base_importer = Importers::Base.new
#       expect { base_importer.stop_if_export_is_invalid(existing_export: existing_export, new_export: new_export_same_id_earlier_end) }.to raise_exception(RuntimeError, /Refusing to process export/)
#     end
#   end

#   describe 'When export ids match, but new end date is after old end date' do
#     it 'return true' do
#       base_importer = Importers::Base.new
#       expect(base_importer.stop_if_export_is_invalid(existing_export: existing_export, new_export: new_export_same_id_later_end)).to be true
#     end
#   end

#   describe 'When export ids are different' do
#     it 'return true' do
#       base_importer = Importers::Base.new
#       expect(base_importer.stop_if_export_is_invalid(existing_export: existing_export, new_export: new_export_different_id)).to be true
#     end
#   end
end
