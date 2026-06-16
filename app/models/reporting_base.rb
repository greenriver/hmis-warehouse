###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class ReportingBase < ActiveRecord::Base
  include CustomApplicationRecord

  self.abstract_class = true
  connects_to database: { writing: :reporting, reading: :reporting }
end
