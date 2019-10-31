class AddFileToCareplan < ActiveRecord::Migration[4.2]
  def change
    add_reference :careplans, :health_file
  end
end
