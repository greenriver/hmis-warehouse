###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Glacier
  class Archive < ApplicationRecord
    belongs_to :vault, foreign_key: 'glacier_vault_id', optional: true
  end
end
