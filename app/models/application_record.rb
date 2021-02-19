###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class ApplicationRecord < ActiveRecord::Base
  include Efind
  include ArelHelper
  self.abstract_class = true

  connects_to database: { writing: :primary, reading: :primary }
end
