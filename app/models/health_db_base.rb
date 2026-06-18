###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class HealthDbBase < ActiveRecord::Base
  self.abstract_class = true
  connects_to database: { writing: :health, reading: :health }
end
