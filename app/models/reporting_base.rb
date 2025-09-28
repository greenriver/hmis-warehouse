###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: false

class ReportingBase < ActiveRecord::Base
  include CustomApplicationRecord

  self.abstract_class = true
  connects_to database: { writing: :reporting, reading: :reporting }
end
