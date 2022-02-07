###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Glacier
  class Vault < ApplicationRecord
    has_many :archives, foreign_key: 'glacier_vault_id'
  end
end
