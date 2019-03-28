class VispdatPrioritizationConfig < ActiveRecord::Migration
  def change
    add_column :configs, :vispdat_prioritization_scheme, :string, null: false, default: :length_of_time
  end
end
