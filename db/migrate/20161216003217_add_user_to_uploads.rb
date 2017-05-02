class AddUserToUploads < ActiveRecord::Migration
  def change
    add_reference :uploads, :user
  end
end
