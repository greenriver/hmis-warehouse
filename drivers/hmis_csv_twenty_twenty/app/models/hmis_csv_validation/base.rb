###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

class HmisCsvValidation::Base < GrdaWarehouseBase
  self.table_name = 'hmis_csv_import_validations'
  belongs_to :source, polymorphic: true

  def skip_row?
    false
  end

  def self.validation_classes
    [
      HmisCsvValidation::EntryAfterExit,
      HmisCsvValidation::InclusionInSet,
      HmisCsvValidation::NonBlankValidation,
      HmisCsvValidation::OneHeadOfHousehold,
      HmisCsvValidation::ValidFormat,
    ].freeze
  end

  def self.error_classes
    [
      HmisCsvValidation::Length,
      HmisCsvValidation::NonBlank,
    ].freeze
  end
end
