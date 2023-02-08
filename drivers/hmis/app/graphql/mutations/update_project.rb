module Mutations
  class UpdateProject < BaseMutation
    argument :id, ID, required: true
    argument :input, Types::HmisSchema::ProjectInput, required: true
    argument :confirmed, Boolean, required: true

    field :project, Types::HmisSchema::Project, null: true
    field :errors, [Types::HmisSchema::ValidationError], null: false, resolver: Resolvers::ValidationErrors

    def resolve(id:, input:, confirmed:)
      record = Hmis::Hud::Project.editable_by(current_user).find_by(id: id)
      closes_project = record.present? && record.operating_end_date.blank? && input.operating_end_date.present?
      response = default_update_record(
        record: record,
        field_name: :project,
        input: input,
        confirmed: confirmed,
      )
      close_related_records(record) if closes_project && response[:project].present?
      response
    end

    def create_errors(project, input)
      return [] unless project.operating_end_date.blank? && input.operating_end_date.present?

      errors = HmisErrors::Errors.new

      funder_count = project.funders.where(end_date: nil).count
      inventory_count = project.inventories.where(inventory_end_date: nil).count
      open_enrollments = Hmis::Hud::Enrollment.open_on_date.in_project_including_wip(project.id, project.project_id)

      errors.add :base, :information, severity: :warning, full_message: "Project has #{open_enrollments.count} open #{'enrollment'.pluralize(open_enrollments.count)}." if open_enrollments.present?
      errors.add :base, :information, severity: :warning, full_message: "#{funder_count} open #{'funder'.pluralize(funder_count)} will be closed." if funder_count.positive?
      errors.add :base, :information, severity: :warning, full_message: "#{inventory_count} open inventory #{'record'.pluralize(inventory_count)} will be closed." if inventory_count.positive?

      errors.errors
    end

    def close_related_records(project)
      project.funders.where(end_date: nil).update_all(end_date: project.operating_end_date)
      project.inventories.where(inventory_end_date: nil).update_all(inventory_end_date: project.operating_end_date)
    end
  end
end
