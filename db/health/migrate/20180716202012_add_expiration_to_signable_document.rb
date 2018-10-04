class AddExpirationToSignableDocument < ActiveRecord::Migration
  def change
    add_column :signable_documents, :expires_at, :datetime
    add_reference :signable_documents, :health_file
  end
end
