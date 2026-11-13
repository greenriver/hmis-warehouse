###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class CreateMhxSubmissions < ActiveRecord::Migration[6.1]
  def change
    create_table :mhx_submissions do |t|
      t.integer :total_records
      t.binary :zip_file

      t.timestamps
    end

    create_table :mhx_submission_external_ids do |t|
      t.belongs_to :submission
      t.belongs_to :external_id
    end
  end
end
