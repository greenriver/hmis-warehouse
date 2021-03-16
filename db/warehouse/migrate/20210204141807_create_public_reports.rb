class CreatePublicReports < ActiveRecord::Migration[5.2]
  def change
    create_table :public_report_settings do |t|
      t.string :s3_region
      t.string :s3_region
      t.string :s3_bucket
      t.string :s3_prefix
      t.string :encrypted_s3_access_key_id
      t.string :encrypted_s3_access_key_id_iv
      t.string :encrypted_s3_secret
      t.string :encrypted_s3_secret_iv
      t.string :color_0
      t.string :color_1
      t.string :color_2
      t.string :color_3
      t.string :color_4
      t.string :color_5
      t.string :color_6
      t.string :color_7
      t.string :color_8
      t.string :color_9
      t.string :color_10
      t.string :color_11
      t.string :color_12
      t.string :color_13
      t.string :color_14
      t.string :color_15
      t.string :color_16
      t.string :font_url
      t.timestamps
    end

    create_table :public_report_reports do |t|
      t.references :user
      t.string :type
      t.date :start_date
      t.date :end_date
      t.jsonb :filter
      t.string :state
      t.text :html
      t.string :published_url
      t.string :embed_code
      t.datetime :started_at
      t.datetime :completed_at
      t.timestamps index: true, null: false
      t.datetime :deleted_at
    end
  end
end
