###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class BulkAssignService < CleanBaseMutation
    argument :input, Types::HmisSchema::BulkAssignServiceInput, required: true
    field :success, Boolean, null: true

    def resolve(input:)
      project = Hmis::Hud::Project.viewable_by(current_user).find(input.project_id)
      raise 'unauthorized' unless current_permission?(permission: :can_edit_enrollments, entity: project)

      clients = Hmis::Hud::Client.viewable_by(current_user).where(id: input.client_ids).preload(:enrollments)
      raise 'clients not found' unless clients.count == input.client_ids.uniq.length

      cst = Hmis::Hud::CustomServiceType.find(input.service_type_id)
      hud_user_id = Hmis::Hud::User.from_user(current_user).user_id

      # Evaluate perm, but don't raise an exception unless the operation actually needs to perform an enrollment
      can_enroll_clients = current_permission?(permission: :can_enroll_clients, entity: project)

      # Determine and validate CoC Code, which is needed for creating new Enrollments
      coc_code = determine_coc_code(coc_code_arg: input.coc_code, project: project)

      project_has_units = project.units.exists?
      available_units = project.units.unoccupied_on(input.date_provided).order(updated_at: :desc).to_a

      Hmis::Hud::Service.transaction do
        services = clients.map do |client|
          # Look for Enrollment at the project that is open on the service date
          enrollment = client.enrollments.
            open_on_date(input.date_provided).
            with_project(project.id).
            order(entry_date: :desc, date_created: :asc).last # Tie-break: newest entry date; oldest record

          # If no Enrollment was found, create one
          unless enrollment
            enrollment = Hmis::Hud::Enrollment.new(
              client: client,
              project: project,
              entry_date: input.date_provided,
              user_id: hud_user_id,
              household_id: Hmis::Hud::Base.generate_uuid,
              enrollment_coc: coc_code,
              relationship_to_hoh: 1, # Head of Household
            )
            raise 'unauthorized' unless can_enroll_clients
            raise 'bulk service assignment generated invalid enrollment' unless enrollment.valid?

            # Attempt to assign this enrollment to a unit if this project has units. This is AC-specific for now, and does
            # not support specifying the unit type. Needs improvement if/when we expand unit capabilities.
            if project_has_units
              raise 'cannot enroll client because there are no units available' if available_units.empty?

              enrollment.assign_unit(unit: available_units.pop, start_date: input.date_provided, user: current_user)
            end

            enrollment.save_new_enrollment!
          end

          service = Hmis::Hud::HmisService.new(
            client: client,
            enrollment: enrollment,
            custom_service_type: cst,
            date_provided: input.date_provided,
            user_id: hud_user_id,
          )
          if cst.hud_service?
            service.owner.assign_attributes(
              record_type: cst.hud_record_type,
              type_provided: cst.hud_type_provided,
            )
          end
          service
        end

        services.each do |service|
          service.owner.save!(context: :form_submission)
        end
      end

      { success: true }
    end

    # Determine and validate CoC Code, which is needed for creating new Enrollments
    def determine_coc_code(coc_code_arg:, project:)
      # If project has exactly 1 CoC code, always use that
      return project.uniq_coc_codes.first if project.uniq_coc_codes.size == 1

      raise 'CoC code required for project' unless coc_code_arg
      raise "Invalid CoC Code #{coc_code_arg} for project" unless project.uniq_coc_codes.include?(coc_code_arg)

      coc_code_arg
    end
  end
end
