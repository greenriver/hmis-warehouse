class MigrateHmisFormData < ActiveRecord::Migration[7.0]
  def up
    raise unless Hmis::Form::FormProcessor.column_names.include?('backup_values')
    raise unless Hmis::Form::Definition.column_names.include?('backup_definition')

    # Rake::Task.clear # clear previously loaded tasks
    # Rails.application.load_tasks # reload tasks from the application

    Rake::Task['driver:hmis:migrate_hmis_link_ids'].invoke
  end

  def down
    safety_assured do
      execute %(UPDATE hmis_form_definitions SET definition = backup_definition)
      execute %(UPDATE hmis_form_processors SET values = backup_values)
    end
  end
end
