###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class BulkAssignService < CleanBaseMutation
    description 'Assign services for a set of Clients. If any client is not enrolled, the client will be enrolled in the project as well.'
    argument :input, Types::HmisSchema::BulkAssignServiceInput, required: true
    field :success, Boolean, null: true

    def resolve(input:)
      project = Hmis::Hud::Project.viewable_by(current_user).find_by(id: input.project_id)
      raise 'unauthorized' unless project
      raise 'unauthorized' unless current_permission?(permission: :can_edit_enrollments, entity: project)

      clients = Hmis::Hud::Client.viewable_by(current_user).where(id: input.client_ids).preload(:enrollments)
      raise 'unauthorized' unless clients.count == input.client_ids.uniq.length

      cst = Hmis::Hud::CustomServiceType.find(input.service_type_id)
      hud_user_id = Hmis::Hud::User.from_user(current_user).user_id

      # Evaluate perm, but don't raise an exception unless the operation actually needs to perform an enrollment
      can_enroll_clients = current_permission?(permission: :can_enroll_clients, entity: project)

      # Determine and validate CoC Code, which is needed for creating new Enrollments
      coc_code = determine_coc_code(coc_code_arg: input.coc_code, project: project)

      project_has_units = project.units.exists?
      available_units = project.units.unoccupied_on(input.date_provided).order(updated_at: :desc).to_a

      Hmis::Hud::Service.transaction do
        clients.each do |client|
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
              error_out('Failed to enroll client because there are no available units.') if available_units.empty?

              enrollment.assign_unit(unit: available_units.pop, start_date: input.date_provided, user: current_user)
            end

            enrollment.save_new_enrollment!
          end

          # Initialize using the HmisService view. Based on the CustomServiceType, the class will initialize
          # either a Hmis::Hud::Service or Hmis::Hud::CustomService as the `owner`
          service = Hmis::Hud::HmisService.new(
            client: client,
            enrollment: enrollment,
            custom_service_type: cst,
            date_provided: input.date_provided,
            user_id: hud_user_id,
          )

          # If this is a HUD Service, set the HUD RecordType and TypeProvided on the owner
          service.owner.assign_attributes(record_type: cst.hud_record_type, type_provided: cst.hud_type_provided) if cst.hud_service?

          # Pass form_submission context to validate uniqueness of bed nights per day.
          # Note: an improvement would be to raise a user-facing error if any service(s) were duplicates for bed nights,
          # and let other changes save successfully.
          service.owner.save!(context: :form_submission)
        end
      end

      { success: true }
    end

    # Determine and validate CoC Code, which is needed for creating new Enrollments
    def determine_coc_code(coc_code_arg:, project:)
      # If project has exactly 1 CoC code, always use that
      return project.uniq_coc_codes.first if project.uniq_coc_codes.size == 1

      raise 'CoC Code required for project' unless coc_code_arg
      raise "Invalid CoC Code #{coc_code_arg} for project" unless project.uniq_coc_codes.include?(coc_code_arg)

      coc_code_arg
    end

    def error_out(msg)
      # error out with user-facing error message
      raise HmisErrors::ApiError.new(msg, display_message: msg)
    end
  end
end
