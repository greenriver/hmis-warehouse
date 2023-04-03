class AddUploadedByToFiles < ActiveRecord::Migration[6.1]
  def change
    add_reference :files, :uploaded_by, to_table: :User, null: true, index: true
  end
end
