class AddUpdatedByToFiles < ActiveRecord::Migration[6.1]
  def change
    add_reference :files, :updated_by, null: true
  end
end
