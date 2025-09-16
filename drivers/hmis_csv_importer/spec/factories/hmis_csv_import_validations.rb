# frozen_string_literal: true

FactoryBot.define do
  factory :hmis_csv_import_validation, class: 'HmisCsvValidation::Validation' do
    importer_log_id { create(:hmis_csv_importer_log).id }
    source_type { 'HmisCsvTwentyTwentyFour::Loader::Enrollment' }
    source_id { '1' }
    status { 'warning' }
    validated_column { 'test_column' }
  end

  factory :hmis_csv_import_length_validation, parent: :hmis_csv_import_validation, class: 'HmisCsvImporter::HmisCsvValidation::Length' do
  end

  factory :hmis_csv_import_inclusion_validation, parent: :hmis_csv_import_validation, class: 'HmisCsvImporter::HmisCsvValidation::InclusionInSet' do
  end
end
