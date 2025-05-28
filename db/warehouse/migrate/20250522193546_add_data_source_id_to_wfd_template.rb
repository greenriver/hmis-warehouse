###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddDataSourceIdToWfdTemplate < ActiveRecord::Migration[7.0]
  def change
    safety_assured do # not yet used in prod, so safety_assured is ok
      add_reference :wfd_templates, :data_source, foreign_key: true, null: true
    end
  end
end
