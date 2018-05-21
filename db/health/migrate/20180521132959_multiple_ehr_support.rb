class MultipleEhrSupport < ActiveRecord::Migration
  def change
    create_table :data_sources do |t|
      t.string :name
      t.datetime :deleted_at
      t.timestamps
    end
  end
end
