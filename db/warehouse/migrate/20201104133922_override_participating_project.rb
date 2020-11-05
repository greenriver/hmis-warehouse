class OverrideParticipatingProject < ActiveRecord::Migration[5.2]
  def change
    add_column :Project, :hmis_participating_project_override, :integer
  end
end
