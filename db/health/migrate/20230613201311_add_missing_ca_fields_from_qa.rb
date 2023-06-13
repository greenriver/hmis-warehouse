class AddMissingCaFieldsFromQa < ActiveRecord::Migration[6.1]
  def change
    add_column :hca_assessments, :address, :string
  end
end
