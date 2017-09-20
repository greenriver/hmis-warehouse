# require 'rails_helper'

# RSpec.describe Importers::Base, type: :model do
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
# end
