###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddPreMergeMappingsToClientMergeAudits < ActiveRecord::Migration[7.1]
  def change
    add_column :hmis_client_merge_audits, :pre_merge_mappings, :jsonb, default: {}, null: false
  end
end
