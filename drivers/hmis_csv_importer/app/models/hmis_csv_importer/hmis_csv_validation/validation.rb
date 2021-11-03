###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class HmisCsvImporter::HmisCsvValidation::Validation < HmisCsvImporter::HmisCsvValidation::Base
  def self.type_name
    'Validation'
  end
end
