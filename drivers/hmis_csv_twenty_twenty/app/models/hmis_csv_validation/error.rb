###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class HmisCsvValidation::Error < HmisCsvValidation::Base
  def self.type_name
    'Error'
  end

  def skip_row?
    true
  end
end
