###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddMissingCaFieldsFromQa < ActiveRecord::Migration[6.1]
  def change
    add_column :hca_assessments, :address, :string
  end
end
