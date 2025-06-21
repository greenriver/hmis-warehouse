# frozen_string_literal: true

class CreateHmisProjectCollectionMembers < ActiveRecord::Migration[7.1]
  def change
    view = 'hmis_project_access_group_members'
    create_view view
    create_trigger(:hmis_project_access_group_members, on: view, sql_definition: <<~SQL)
      CREATE TRIGGER attempt_hmis_project_access_group_members_del
      INSTEAD OF DELETE ON hmis_project_access_group_members
      FOR EACH ROW EXECUTE FUNCTION prevent_modification();
    SQL
    create_trigger(:hmis_project_access_group_members, on: view, sql_definition: <<~SQL)
      CREATE TRIGGER attempt_hmis_project_access_group_members_up
      INSTEAD OF UPDATE ON hmis_project_access_group_members
      FOR EACH ROW EXECUTE FUNCTION prevent_modification();
    SQL
  end
end
