class AddTimestampsToSsMs < ActiveRecord::Migration[4.2][4.2]
  def change
    add_timestamps :self_sufficiency_matrix_forms
  end
end
