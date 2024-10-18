class AddEnableAutoDeduplicationConfig < ActiveRecord::Migration[7.0]
  def change
    add_column :configs, :enable_auto_deduplication, :boolean, default: :true
  end
end
