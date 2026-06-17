###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class HmisCsvImporter::HmisCsvValidation::Validation < HmisCsvImporter::HmisCsvValidation::Base
  def self.type_name
    'Validation'
  end
end
