class ReplaceRulesWithTriggers < ActiveRecord::Migration[7.0]
  def up
    [
      'DROP RULE attempt_client_searchable_names_del ON public.client_searchable_names',
      'DROP RULE attempt_client_searchable_names_up ON public.client_searchable_names',
    ].each do |statement|
      safely_execute(statement)
    end

    create_function :prevent_modification
    create_trigger :prevent_delete_client_searchable_names,
      on: :client_searchable_names,
      events: :delete,
      timing: :before,
      function: :prevent_modification
    create_trigger :prevent_update_client_searchable_names,
      on: :client_searchable_names,
      events: :update,
      timing: :before,
      function: :prevent_modification
  end

  def down
    drop_trigger :prevent_delete_client_searchable_names, on: :client_searchable_names
    drop_trigger :prevent_update_client_searchable_names, on: :client_searchable_names
    drop_function :prevent_modification

    [
      'CREATE RULE attempt_client_searchable_names_del AS ON DELETE TO public.client_searchable_names DO INSTEAD NOTHING',
      'CREATE RULE attempt_client_searchable_names_up AS ON UPDATE TO public.client_searchable_names DO INSTEAD NOTHING',
    ].each do |statement|
      safely_execute(statement)
    end
  end

  def safely_execute(statement)
    safety_assured {execute(statement)}
  end
end
