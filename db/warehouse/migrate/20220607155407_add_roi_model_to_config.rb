class AddRoiModelToConfig < ActiveRecord::Migration[6.1]
  def change
    add_column :configs, :roi_model, :string, default: :explicit
  end
end
