###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class HmisCsvImporter::HmisCsvValidation::Base < GrdaWarehouseBase
  self.table_name = 'hmis_csv_import_validations'
  belongs_to :source, -> { with_deleted }, polymorphic: true, optional: true

  def skip_row?
    false
  end

  def self.validation_classes
    [
      HmisCsvImporter::HmisCsvValidation::EntryAfterExit,
      HmisCsvImporter::HmisCsvValidation::InclusionInSet,
      HmisCsvImporter::HmisCsvValidation::NonBlankValidation,
      HmisCsvImporter::HmisCsvValidation::OneHeadOfHousehold,
      HmisCsvImporter::HmisCsvValidation::ValidFormat,
    ].freeze
  end

  def self.error_classes
    [
      HmisCsvImporter::HmisCsvValidation::Length,
      HmisCsvImporter::HmisCsvValidation::NonBlank,
      HmisCsvImporter::HmisCsvValidation::UniqueHudKey,
    ].freeze
  end
end
