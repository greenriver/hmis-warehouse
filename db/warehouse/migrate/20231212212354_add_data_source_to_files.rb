class AddDataSourceToFiles < ActiveRecord::Migration[6.1]
  def change
    safety_assured do
      add_reference :files, :data_source, null: true
    end
  end
end
