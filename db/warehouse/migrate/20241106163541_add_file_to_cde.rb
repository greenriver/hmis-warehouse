#  Copyright 2016 - 2024 Green River Data Analysis, LLC
#
#  License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
#

class AddFileToCde < ActiveRecord::Migration[7.0]
  def change
    # todo @martha - fix safety assured
    # todo @martha - would rather call this value_file_id;
    # add_column :custom_data_elements, :value_file_id, :bigint
    # add_foreign_key :custom_data_elements, :files, column: :value_file_id
    safety_assured { add_reference :CustomDataElements, :file, null: true }
  end
end
