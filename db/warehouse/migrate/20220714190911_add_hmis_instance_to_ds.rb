class AddHmisInstanceToDs < ActiveRecord::Migration[6.1]
  def change
    add_column :data_sources, :hmis, :string
  end
end
