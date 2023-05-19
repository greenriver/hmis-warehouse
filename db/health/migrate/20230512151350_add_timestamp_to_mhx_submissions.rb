class AddTimestampToMhxSubmissions < ActiveRecord::Migration[6.1]
  def change
    add_column :mhx_submissions, :timestamp, :string
  end
end
