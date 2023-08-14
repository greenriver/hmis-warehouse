###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# track assignments of units to enrollments / households
module HmisExternalApis::AcHmis::Importers::Loaders
  class ProjectUnitTracker
    attr_reader :assignments, :unoccupied_units_by, :enrollment_lookup, :today

    def initialize(data_source)
      projects = Hmis::Hud::Project.where(data_source: data_source)
      @today = Date.today

      @enrollment_lookup = Hmis::Hud::Enrollment.joins(:project)
        .where(data_source: data_source)
        .pluck(:id, 'Project.id', :household_id)
        .to_h { |pk, project_id, household_id| [pk, [project_id, household_id]] }

      @assignments = {}

      @unoccupied_units_by = Hmis::Unit.unoccupied_on(today)
        .where(project_id: projects.select(:id))
        .preload(unit_type: :mper_id)
        .to_a
        .group_by { |u| [u.project_id, u.unit_type.mper_id.value] }
        .transform_values { |v| v.map(&:id) }
    end

    # gives enrollments with same household id the same unit
    def assign_next_unit(enrollment_pk:, unit_type_mper_id:, start_date: nil)
      return nil unless enrollment_pk && unit_type_mper_id

      assignment_key = enrollment_lookup.fetch(enrollment_pk)
      project_id, = assignment_key
      return assignments[assignment_key] if assignments.key?(assignment_key)

      pool = unoccupied_units_by[[project_id, unit_type_mper_id]]
      unit_id = pool&.pop
      assignments[assignment_key] = { enrollment_id: enrollment_pk, unit_id: unit_id, start_date: start_date }
    end
  end
end
