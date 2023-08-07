class CreateAnyCareplans < ActiveRecord::Migration[6.1]
  def change
    create_table :any_careplans do |t|
      t.references :patient
      t.references :instrument, polymorphic: true

      t.datetime :deleted_at
      t.timestamps
    end
  end
end
