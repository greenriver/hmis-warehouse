class CreateHmisProjectCollectionMembers < ActiveRecord::Migration[7.1]
  def change
    create_view 'hmis_project_access_group_members'
    create_trigger(:hmis_project_access_group_members, sql_definition: <<~SQL)
      CREATE TRIGGER attempt_hmis_project_access_group_members_del
      INSTEAD OF DELETE ON hmis_project_access_group_members
      FOR EACH ROW EXECUTE FUNCTION prevent_modification();
    SQL
    create_trigger(:hmis_project_access_group_members, sql_definition: <<~SQL)
      CREATE TRIGGER attempt_hmis_project_access_group_members_up
      INSTEAD OF UPDATE ON hmis_project_access_group_members
      FOR EACH ROW EXECUTE FUNCTION prevent_modification();
    SQL
   end
end
