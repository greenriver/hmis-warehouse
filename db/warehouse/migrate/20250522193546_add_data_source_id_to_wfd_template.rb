###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddDataSourceIdToWfdTemplate < ActiveRecord::Migration[7.1]
  def change
    safety_assured do # not yet used in prod, so safety_assured is ok
      add_reference :wfd_templates, :data_source, foreign_key: true, null: true
    end
  end
end
