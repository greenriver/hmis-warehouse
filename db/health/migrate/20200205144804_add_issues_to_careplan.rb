class AddIssuesToCareplan < ActiveRecord::Migration[5.2]
  def change
    remove_column :careplans, :issues, :text
    (0..10).each do |i|
      add_column :careplans, "future_issues_#{i}", :string
    end
  end
end
