###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# generic key value store for db-managed config
class AppConfigProperty < ApplicationRecord
  validates :key, presence: true, uniqueness: true
end
