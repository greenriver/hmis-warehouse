class AddDataSourceIdToHmisTables < ActiveRecord::Migration[4.2]
  def change
    %w( Assessment Staff ).each do |cz|
      cz = "GrdaWarehouse::HMIS::#{cz}".constantize
      add_column cz.table_name, :data_source_id, :integer
    end
  end
end
