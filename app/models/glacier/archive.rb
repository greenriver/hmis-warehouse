###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Glacier
  class Archive < ApplicationRecord
    belongs_to :vault, foreign_key: 'glacier_vault_id'
  end
end
