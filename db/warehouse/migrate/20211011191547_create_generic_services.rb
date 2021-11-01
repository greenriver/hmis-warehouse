class CreateGenericServices < ActiveRecord::Migration[5.2]
  def change
    create_table :generic_services do |t|
      t.references :client
      t.references :source, polymorphic: true, index: false
      t.date :date
      t.string :title
    end
    add_index :generic_services, [:source_id, :source_type], unique: true, name: :gs_source_id_source_type_uniq
  end
end
