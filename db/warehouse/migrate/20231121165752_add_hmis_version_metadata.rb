class AddHmisVersionMetadata < ActiveRecord::Migration[6.1]
  def change
    add_reference :versions, :true_user, index: false
    add_reference :versions, :client, index: false
    add_reference :versions, :enrollment, index: false
    add_reference :versions, :project, index: false
  end
end
