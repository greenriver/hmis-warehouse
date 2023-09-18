class CreateTaskQueue < ActiveRecord::Migration[6.1]
  def change
    create_table :task_queues do |t|
      t.string :rake_task
      t.boolean :active, default: true, null: false
      t.datetime :queued_at
      t.datetime :started_at
      t.datetime :completed_at
      t.timestamps
    end
  end
end
