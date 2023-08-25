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

      # { [project_pk, household_id] => unit_id }
      @household_assignments = {}
      # { enrollment_pk => { unit_id, enrollment_pk, start_date } }
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

      project_household = @enrollment_lookup[enrollment_pk]
      return unless project_household

      unit_pk = unit_pk_for_enrollment_pk(project_household, unit_type_mper_id)
      return unless unit_pk

      assignments[enrollment_pk] ||= {
        unit_id: unit_pk,
        enrollment_id: enrollment_pk,
        start_date: @enrollment_entry_dates[enrollment_pk] || fallback_start_date,
      }
      unit_pk
    end

    def assign_next_unit_to_new_enrollment(enrollment:, project_pk:, unit_type_mper_id:)
      project_household = [project_pk, enrollment.household_id]
      unit_pk = unit_pk_for_enrollment_pk(project_household, unit_type_mper_id)
      enrollment.unit_occupancies.build(
        unit_id: unit_pk,
        occupancy_period_attributes: {
          start_date: enrollment.entry_date,
          end_date: nil,
          user_id: system_user_pk,
        },
      )
    end

    protected

    # 'project_household' is [project_pk, household_id]
    # gives enrollments with same household id the same unit
    def unit_pk_for_enrollment_pk(project_household, unit_type_mper_id)
      project_pk, = project_household
      @household_assignments[project_household] ||= @unit_lookup[[project_pk, unit_type_mper_id]]&.pop
    end

    def enrollment_scope
      # include exited enrollments in the scope because they happen to be coming up
      # its fine to assign to exited enrollments, the assignment will have an end date equal to the exit date
      # TEMP! exclude CE project enrollments because the project is deleted but the enrollment deletion is still in progress
      Hmis::Hud::Enrollment.where(data_source: data_source).where.not(project_id: '1234')
    end

    def system_user_pk
      @system_user_pk ||= Hmis::User.system_user.id
    end
  end
end
