###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class CreateHmisCsvRowProcessingNotes < ActiveRecord::Migration[7.2]
  def change
    create_table :hmis_csv_row_processing_notes do |t|
      t.bigint :loader_log_id, null: false
      t.string :file_name, null: false
      t.string :row
      t.string :reason
    end
  end
end
