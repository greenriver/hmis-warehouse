module Mutations
  class UpdateProject < BaseMutation
    argument :id, ID, required: true
    argument :input, Types::HmisSchema::ProjectInput, required: true
    argument :confirmed, Boolean, required: true

    field :project, Types::HmisSchema::Project, null: true
    field :errors, [Types::HmisSchema::ValidationError], null: false

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

    def create_warnings(project, input)
      return [] unless project.operating_end_date.blank? && input.operating_end_date.present?

      funder_count = project.funders.where(end_date: nil).count
      inventory_count = project.inventories.where(inventory_end_date: nil).count
      open_enrollments = Hmis::Hud::Enrollment.open_on_date.in_project(project.id)
      warnings = []
      warnings << InputConfirmationWarning.new("#{open_enrollments.count} open #{'enrollment'.pluralize(open_enrollments.count)} exist.", attribute: 'id') if open_enrollments.present?
      warnings << InputConfirmationWarning.new("#{funder_count} open #{'funder'.pluralize(funder_count)} will be closed.", attribute: 'id') if funder_count.positive?
      warnings << InputConfirmationWarning.new("#{inventory_count} open inventory #{'record'.pluralize(inventory_count)} will be closed.", attribute: 'id') if inventory_count.positive?
      warnings
    end

    def close_related_records(project)
      project.funders.where(end_date: nil).update_all(end_date: project.operating_end_date)
      project.inventories.where(inventory_end_date: nil).update_all(inventory_end_date: project.operating_end_date)
    end
  end
end
