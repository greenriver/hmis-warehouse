class AddCovidTracingConfig < ActiveRecord::Migration[5.2]
  def change
    add_column :configs, :health_emergency_tracing, :string
  end
end
