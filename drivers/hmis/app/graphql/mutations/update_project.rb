module Mutations
  class UpdateProject < BaseMutation
    argument :id, ID, required: true
    argument :input, Types::HmisSchema::ProjectInput, required: true
    argument :confirmed, Boolean, required: true

    field :project, Types::HmisSchema::Project, null: true

    def resolve(id:, input:, confirmed:)
      record = Hmis::Hud::Project.viewable_by(current_user).find_by(id: id)
      closes_project = record.present? && record.operating_end_date.blank? && input.operating_end_date.present?
      response = default_update_record(
        record: record,
        field_name: :project,
        input: input,
        confirmed: confirmed,
        permissions: [:can_edit_project_details],
      )
      close_related_records(record) if closes_project && response[:project].present?
      response
    end

    def create_errors(project, input)
      errors = HmisErrors::Errors.new

      # If project end date is changing
      if input.operating_end_date.present? && project.operating_end_date != input.operating_end_date
        open_enrollments = Hmis::Hud::Enrollment.open_on_date(input.operating_end_date).in_project_including_wip(project.id, project.project_id)
        errors.add :base, :information, severity: :warning, full_message: "Project has #{open_enrollments.count} open #{'enrollment'.pluralize(open_enrollments.count)} on the selected end date." if open_enrollments.present?
      end

      # If project is being "closed" for the first time
      if project.operating_end_date.blank? && input.operating_end_date.present?
        funder_count = project.funders.where(end_date: nil).count
        inventory_count = project.inventories.where(inventory_end_date: nil).count
        errors.add :base, :information, severity: :warning, full_message: "#{funder_count} open #{'funder'.pluralize(funder_count)} will be closed." if funder_count.positive?
        errors.add :base, :information, severity: :warning, full_message: "#{inventory_count} open inventory #{'record'.pluralize(inventory_count)} will be closed." if inventory_count.positive?
      end

      errors.errors
    end

    def close_related_records(project)
      project.funders.where(end_date: nil).update_all(end_date: project.operating_end_date)
      project.inventories.where(inventory_end_date: nil).update_all(inventory_end_date: project.operating_end_date)
    end
  end
end
