# frozen_string_literal: true

FactoryBot.define do
  factory :hmis_csv_import_error, class: 'HmisCsvImporter::Importer::ImportError' do
    importer_log_id { create(:hmis_csv_importer_log).id }
    source_type { 'HmisCsvTwentyTwentyFour::Loader::Enrollment' }
    source_id { '1' }
    message { 'Test error message' }
    details { 'Test error details' }
  end
end
