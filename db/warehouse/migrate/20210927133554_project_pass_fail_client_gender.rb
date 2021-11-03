class ProjectPassFailClientGender < ActiveRecord::Migration[5.2]
  def change
    add_column :project_pass_fails_clients, :gender_multi, :string
  end
end
