class AddFileToCareplan < ActiveRecord::Migration
  def change
    add_reference :careplans, :health_file
  end
end
