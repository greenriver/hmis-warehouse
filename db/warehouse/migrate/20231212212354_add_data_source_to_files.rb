class AddDataSourceToFiles < ActiveRecord::Migration[6.1]
  disable_ddl_transaction!
  def change
    add_reference :files, :data_source, null: true, index: {algorithm: :concurrently}
  end
end
