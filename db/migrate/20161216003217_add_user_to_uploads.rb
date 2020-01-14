class AddUserToUploads < ActiveRecord::Migration[4.2]
  def change
    add_reference :uploads, :user
  end
end
