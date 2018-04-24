class CreateGrdaWarehouseEnrollmentExtras < ActiveRecord::Migration
  def change
    create_table :enrollment_extras do |t|
      t.references :enrollment, null: false, delete: :cascade
      t.integer    :vispdat_grand_total
      t.datetime   :vispdat_added_at
      t.datetime   :vispdat_started_at
      t.datetime   :vispdat_ended_at
      t.string     :source_tab
      t.timestamps
    end
  end
end
