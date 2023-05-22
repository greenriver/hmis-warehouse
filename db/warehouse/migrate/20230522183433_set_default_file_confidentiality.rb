class SetDefaultFileConfidentiality < ActiveRecord::Migration[6.1]
  def up
    change_column_default :files, :confidential, false
  end
end
