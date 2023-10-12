class RelaxEthnicityRequirement < ActiveRecord::Migration[6.1]
  def change
    change_column_null :youth_intakes, :client_ethnicity, true
  end
end
