class AddExpirationToSignableDocument < ActiveRecord::Migration[4.2][4.2]
  def change
    add_column :signable_documents, :expires_at, :datetime
    add_reference :signable_documents, :health_file
  end
end
