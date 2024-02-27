###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Mutations
  class BulkAssignService < CleanBaseMutation
    argument :project_id, ID, required: true
    argument :client_ids, [ID], required: true, description: 'Clients that should receive service. Clients that are unenrolled in the project will be enrolled in the project.'
    argument :service_type_id, ID, required: true
    argument :date_provided, GraphQL::Types::ISO8601Date, required: true

    field :success, Boolean, null: true # should this return a bumped enrollment lock version?

    def resolve(project_id:, client_ids:, service_type_id:, date_provided:)
      project = Hmis::Hud::Project.viewable_by(current_user).find(project_id)
      raise 'unauthorized' unless current_permission?(permission: :can_edit_enrollments, entity: project)

      clients = Hmis::Hud::Client.viewable_by(current_user).where(id: client_ids).preload(:enrollments)
      raise 'clients not found' unless clients.count == client_ids.uniq.length

      cst = Hmis::Hud::CustomServiceType.find(service_type_id)
      hud_user_id = Hmis::Hud::User.from_user(current_user).user_id

      # Evaluate perm, but don't raise an exception unless the operation actually needs to perform an enrollment
      can_enroll_clients = current_permission?(permission: :can_enroll_clients, entity: project)

      Hmis::Hud::Service.transaction do
        services = clients.map do |client|
          # Look for Enrollment at the project that is open on the service date
          enrollment = client.enrollments.
            open_on_date(date_provided).
            with_project(project_id).
            order(entry_date: :desc, date_created: :asc).last # Tie-break: newest entry date; oldest record

          # If no Enrollment was found, create one
          unless enrollment
            enrollment = Hmis::Hud::Enrollment.new(
              client: client,
              project: project,
              entry_date: date_provided,
              user_id: hud_user_id,
            )
            raise 'unauthorized' unless can_enroll_clients

            # TODO: check Hmis::ProjectAutoEnterConfig to decide whether to save in progress or not
            enrollment.save_in_progress
          end

          service = Hmis::Hud::HmisService.new(
            client: client,
            enrollment: enrollment,
            custom_service_type: cst,
            date_provided: date_provided,
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
  end
end
