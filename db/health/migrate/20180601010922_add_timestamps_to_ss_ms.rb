class AddTimestampsToSsMs < ActiveRecord::Migration
  def change
    add_timestamps :self_sufficiency_matrix_forms
  end
end
