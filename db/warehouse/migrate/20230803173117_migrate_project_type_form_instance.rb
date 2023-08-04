class MigrateProjectTypeFormInstance < ActiveRecord::Migration[6.1]
  def up
    Hmis::Form::Instance.where(entity_type: 'ProjectType').update_all('project_type=entity_id')
    Hmis::Form::Instance.where(entity_type: 'ProjectType').update_all(entity_type: nil, entity_id: nil)
  end
end
