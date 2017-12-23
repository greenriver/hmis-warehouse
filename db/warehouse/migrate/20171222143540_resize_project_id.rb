class ResizeProjectId < ActiveRecord::Migration
  def up 
    change_column :Project, :ProjectID, :string, limit: 50
    change_column :Project, :OrganizationID, :string, limit: 50
    change_column :Organization, :OrganizationID, :string, limit: 50
    change_column :Enrollment, :ProjectID, :string, limit: 50
    change_column :Enrollment, :ProjectEntryID, :string, limit: 50
  end
end
