class VispdatPrioritizationConfig < ActiveRecord::Migration[4.2]
  def change
    add_column :configs, :vispdat_prioritization_scheme, :string, null: false, default: :length_of_time
  end
end
