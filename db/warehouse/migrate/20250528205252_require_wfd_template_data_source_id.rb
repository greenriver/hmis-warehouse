###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class RequireWfdTemplateDataSourceId < ActiveRecord::Migration[7.1]
  def change
    safety_assured do
      change_column_null :wfd_templates, :data_source_id, false
    end
  end
end
