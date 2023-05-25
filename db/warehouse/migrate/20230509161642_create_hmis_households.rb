class CreateHmisHouseholds < ActiveRecord::Migration[6.1]
  def view_name
    :hmis_households
  end

  def change
    create_view view_name
  end

  # def up
  #   execute("CREATE RULE attempt_#{view_name}_del AS ON DELETE TO #{view_name} DO INSTEAD NOTHING")
  #   execute("CREATE RULE attempt_#{view_name}_up AS ON UPDATE TO #{view_name} DO INSTEAD NOTHING")
  # end
end
