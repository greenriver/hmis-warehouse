class AddHmisFormProcessor < ActiveRecord::Migration[6.1]
  def change
    create_table :hmis_assessment_processors do |t|
      t.references :assessment_detail
    end
  end
end
