###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class RemoveCoCCodesFromCollections < ActiveRecord::Migration[7.1]
  def change
    safety_assured { remove_column :collections, :coc_codes, :jsonb }
  end
end
