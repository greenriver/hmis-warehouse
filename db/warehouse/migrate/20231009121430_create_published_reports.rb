class CreatePublishedReports < ActiveRecord::Migration[6.1]
  def change
    create_table :published_reports do |t|
      t.references :report, null: false, polymorphic: true
      t.references :user, null: false
      t.string :state
      t.string :published_url
      t.string :path
      t.text :embed_code
      t.text :html

      t.timestamps
      t.datetime :deleted_at
    end

    add_column :simple_report_instances, :path, :string
  end
end
