###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

module Types
  class HmisSchema::CeSwimlane < Types::BaseObject
    field :id, ID, null: false
    field :name, String, null: false
    field :template_name, String, null: false
    field :template_identifier, String, null: false
    field :task_names, [String], null: false

    def template_name
      template.name
    end

    def template_identifier
      template.identifier
    end

    def task_names
      tasks = load_ar_association(object, :tasks)
      tasks.sort_by(&:id).map(&:name)
    end

    private def template
      load_ar_association(object, :template)
    end
  end
end
