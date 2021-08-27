class AddUserToAdHoc < ActiveRecord::Migration[5.2]
  def change
    add_reference :ad_hoc_data_sources, :user, index: true
  end
end
