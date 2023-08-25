###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# track assignments of units to enrollments / households
module HmisExternalApis::AcHmis::Importers::Loaders
  class ProjectUnitTracker
    attr_reader :assignments, :data_source

    def initialize(data_source)
      @data_source = data_source
      projects = Hmis::Hud::Project.where(data_source: data_source)

      # {enrollment_pk => [project_pk, household_id]}
      @enrollment_lookup = {}
      # {enrollment_pk => hoh_entry_date}
      @enrollment_entry_dates = {}
      enrollment_scope.preload(:project).preload(wip: :project).find_each do |enrollment|
        project_pk = enrollment.project_id ? enrollment.project.id : enrollment.wip&.project&.id
        @enrollment_lookup[enrollment.id] = [project_pk, enrollment.household_id] if project_pk
        @enrollment_entry_dates[enrollment.id] ||= enrollment.entry_date if enrollment.head_of_household?
      end

      @household_assignments = {}
      @assignments = {}

      # we don't check if the unit is occupied, assumption is that all unit occupancies
      # are deleted before import
      # { [project_id, mper_id] => [unit_ids...] }
      @unit_lookup = Hmis::Unit
        .where(project_id: projects.select(:id))
        .preload(unit_type: :mper_id)
        .to_a
        .group_by { |u| [u.project_id, u.unit_type.mper_id.value] }
        .transform_values { |v| v.map(&:id) }
    end

    def assign_next_unit(enrollment_pk:, unit_type_mper_id:, fallback_start_date: nil)
      raise 'missing enrollment' if enrollment_pk.nil?
      return assignments[enrollment_pk][:unit_id] if assignments[enrollment_pk].present?
      return if unit_type_mper_id.blank?

      unit_pk = unit_pk_for_enrollment_pk(enrollment_pk, unit_type_mper_id)
      return unless unit_pk

      assignments[enrollment_pk] ||= {
        unit_id: unit_pk,
        enrollment_id: enrollment_pk,
        start_date: @enrollment_entry_dates[enrollment_pk] || fallback_start_date,
      }
      unit_pk
    end

    protected

    # gives enrollments with same household id the same unit
    def unit_pk_for_enrollment_pk(enrollment_pk, unit_type_mper_id)
      project_household = @enrollment_lookup[enrollment_pk]
      return unless project_household

      project_pk, = project_household
      @household_assignments[project_household] ||= @unit_lookup[[project_pk, unit_type_mper_id]]&.pop
    end

    def enrollment_scope
      # .open_including_wip
      # include exited enrollments in the scope because they happen to be coming up
      # its fine to assign to exited enrollments, the assignment will have an end date equal to the exit date
      Hmis::Hud::Enrollment.where(data_source: data_source)
    end
  end
end
