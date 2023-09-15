class CreateClientSearchableNames < ActiveRecord::Migration[6.1]
  def change
    view_name = :client_searchable_names
    create_view view_name
    reversible do |dir|
      dir.up do
        safety_assured do
          execute("CREATE RULE attempt_#{view_name}_del AS ON DELETE TO #{view_name} DO INSTEAD NOTHING")
          execute("CREATE RULE attempt_#{view_name}_up AS ON UPDATE TO #{view_name} DO INSTEAD NOTHING")
        end
      end
    end
  end
end
