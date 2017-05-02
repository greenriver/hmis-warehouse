class CreateSimilarityMetricTable < ActiveRecord::Migration
  def up
    enable_extension 'hstore'
    unless ActiveRecord::Base.connection.tables.include?('similarity_metrics')
      create_table :similarity_metrics do |t|
        t.string :type, null: false
        t.float :mean, null: false, default: 0
        t.float :standard_deviation, null: false, default: 0
        t.float :weight, null: false, default: 1
        t.integer :n, null: false, default: 0
        t.hstore :other_state, null: false, default: {}
        
        t.timestamps
      end
      add_index :similarity_metrics, [:type], unique: true
    end
  end

  def down
    drop_table :similarity_metrics
  end
end
