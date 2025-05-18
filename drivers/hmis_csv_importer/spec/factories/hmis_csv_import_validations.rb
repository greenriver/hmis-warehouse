# frozen_string_literal: true

FactoryBot.define do
  factory :hmis_csv_import_validation, class: 'HmisCsvImporter::HmisCsvValidation::Length' do
    importer_log_id { create(:hmis_csv_importer_log).id }
    source_type { 'HmisCsvTwentyTwentyFour::Loader::Enrollment' }
    source_id { '1' }
    status { 'warning' }
    validated_column { 'test_column' }
  end
end
