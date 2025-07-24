###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Mutations
  class BulkAssignService < CleanBaseMutation
    description 'Assign services for a set of Clients. If any client is not enrolled, the client will be enrolled in the project as well.'
    argument :input, Types::HmisSchema::BulkAssignServiceInput, required: true
    field :success, Boolean, null: true

    def resolve(input:)
      project = Hmis::Hud::Project.viewable_by(current_user).find_by(id: input.project_id)
      access_denied! unless project
      access_denied! unless current_user.permissions_for?(project, :can_edit_enrollments, :can_view_enrollment_details, mode: :all)

      clients = Hmis::Hud::Client.viewable_by(current_user).where(id: input.client_ids)
      access_denied! unless clients.count == input.client_ids.uniq.length

      cst = Hmis::Hud::CustomServiceType.find(input.service_type_id)
      hud_user_id = Hmis::Hud::User.from_user(current_user).user_id

      # Evaluate perm, but don't raise an exception unless the operation actually needs to perform an enrollment
      can_enroll_clients = current_permission?(permission: :can_enroll_clients, entity: project)

      # Determine and validate CoC Code, which is needed for creating new Enrollments
      coc_code = project.determine_coc_code(coc_code_arg: input.coc_code)

      project_has_units = project.units.exists?
      available_units = project.units.available_for_occupancy_on(input.date_provided).order(updated_at: :desc).to_a

      # async record load must be called outside of a db transaction to avoid deadlocks
      enrollment_by_client = clients.to_h do |client|
        enrollment = load_open_enrollment_for_client(
          client,
          project_id: project.id,
          open_on_date: input.date_provided,
        )
        [client.id, enrollment]
      end

      errors = HmisErrors::Errors.new

      Hmis::Hud::Service.transaction do
        clients.each do |client|
          # Look for Enrollment at the project that is open on the service date
          enrollment = enrollment_by_client[client.id]

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
            access_denied! unless can_enroll_clients
            raise 'bulk service assignment generated invalid enrollment' unless enrollment.valid?

            entry_date_errors = Hmis::Hud::Validators::EnrollmentValidator.validate_entry_date(enrollment)
            # Ignore informational warnings (e.g. >30 days ago). Keep out-of-range warnings (e.g. existing overlapping enrollment)
            entry_date_errors.reject! { |e| e.warning? && e.type == :information }
            errors.push(*entry_date_errors)
            raise ActiveRecord::Rollback if errors.any?

            # Attempt to assign this enrollment to a unit if this project has units. This is AC-specific for now, and does
            # not support specifying the unit type. Needs improvement if/when we expand unit capabilities.
            if project_has_units
              errors.add :base, :invalid, full_message: 'Failed to enroll client because there are no available units' if available_units.empty?
              raise ActiveRecord::Rollback if errors.any?

              enrollment.assign_unit(unit: available_units.pop, start_date: input.date_provided, user: current_user)
            end

            enrollment.save_new_enrollment!
          end

          # Based on the CustomServiceType, initialize a Hmis::Hud::Service or Hmis::Hud::CustomService
          attrs = {
            client: client,
            enrollment: enrollment,
            date_provided: input.date_provided,
            user_id: hud_user_id,
          }
          service = if cst.hud_service?
            Hmis::Hud::Service.new(record_type: cst.hud_record_type, type_provided: cst.hud_type_provided, **attrs)
          else
            Hmis::Hud::CustomService.new(custom_service_type: cst, **attrs)
          end

          # validate with form_submission context to check bed night uniqueness constraint
          is_valid = service.valid?(:form_submission)

          # If the validation failed because this Enrollment already has a Bed Night on the requested date, just skip saving it and proceed.
          # This allows retries to be successful if the service is re-submitted. It also gracefully handles case where the user is looking at a stale
          # list of clients, so the client appears to be unassigned but is actually already assigned.
          next if service.errors.full_messages == ['Enrollment has already been taken']

          # if validation failed for some other reason, raise
          raise "Invalid service: #{service.errors.full_messages.join(', ')}" unless is_valid

          service.save!
        end
      end

      return { success: false, errors: errors } if errors.any?

      { success: true }
    end
  end
end
