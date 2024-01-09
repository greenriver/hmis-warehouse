class HmisActivityLogViews < ActiveRecord::Migration[6.1]
  def change
    client_view
    enrollment_view
  end

  def client_view
    view_name = :hmis_user_client_activity_log_summaries
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

  def enrollment_view
    view_name = :hmis_user_enrollment_activity_log_summaries
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
