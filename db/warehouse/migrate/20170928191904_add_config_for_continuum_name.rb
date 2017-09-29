class AddConfigForContinuumName < ActiveRecord::Migration
  def change
    add_column :configs, :continuum_name, :string
  end
end
