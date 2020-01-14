class AddConfigForContinuumName < ActiveRecord::Migration[4.2]
  def change
    add_column :configs, :continuum_name, :string
  end
end
