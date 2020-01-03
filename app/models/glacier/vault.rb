###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Glacier
  class Vault < ActiveRecord::Base
    has_many :archives, foreign_key: 'glacier_vault_id'
  end
end
