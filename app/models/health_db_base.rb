# frozen_string_literal: true

###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class HealthDbBase < ActiveRecord::Base
  self.abstract_class = true
  connects_to database: { writing: :health, reading: :health }
end
