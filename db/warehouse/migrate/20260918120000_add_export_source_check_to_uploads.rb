###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class AddExportSourceCheckToUploads < ActiveRecord::Migration[7.2]
  def change
    add_column :uploads, :export_source_check, :jsonb, if_not_exists: true
  end
end
