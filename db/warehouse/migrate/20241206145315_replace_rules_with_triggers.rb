class ReplaceRulesWithTriggers < ActiveRecord::Migration[7.0]
  VIEWS = [
    'client_searchable_names',
    'hmis_households',
    'project_access_group_members',
    'project_collection_members',
  ].freeze

  def up
    create_function :prevent_modification

    VIEWS.each do |view|
      [
        "DROP RULE attempt_#{view}_del ON public.#{view}",
        "DROP RULE attempt_#{view}_up ON public.#{view}",
        "CREATE TRIGGER no_modify_#{view} INSTEAD OF UPDATE OR DELETE ON public.#{view} FOR EACH ROW EXECUTE FUNCTION prevent_modification()",
      ].each { |statement| safely_execute(statement) }
    end
  end

  def down
    VIEWS.each do |view|
      [
        "DROP TRIGGER no_modify_#{view} ON public.#{view}",
        "CREATE RULE attempt_#{view}_up AS ON UPDATE TO public.#{view} DO INSTEAD NOTHING",
        "CREATE RULE attempt_#{view}_del AS ON DELETE TO public.#{view} DO INSTEAD NOTHING",
      ].each { |statement| safely_execute(statement) }
    end

    drop_function :prevent_modification
  end

  protected

  def safely_execute(statement)
    safety_assured { execute(statement) }
  end
end
