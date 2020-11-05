class AddCombineEnrollmentsToProjects < ActiveRecord::Migration[5.2]
  def change
    add_column :Project, :combine_enrollments, :boolean, default: false
  end
end
