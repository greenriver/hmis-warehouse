# NOTE: This provides an unscoped duplicate of Project for use with exports
# that should ignore acts as paranoid completely
module GrdaWarehouse::Hud::WithDeleted
  class Enrollment < GrdaWarehouse::Hud::Enrollment
    default_scope {unscope where: paranoia_column}

    belongs_to :project_with_deleted, class_name: GrdaWarehouse::Hud::WithDeleted::Project.name, foreign_key: [:ProjectID, :data_source_id], primary_key: [:ProjectID, :data_source_id], inverse_of: :enrollments
  end
end