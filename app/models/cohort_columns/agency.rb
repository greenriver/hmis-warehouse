module CohortColumns
  class Agency < Base
    attribute :column, String, lazy: true, default: :agency
    attribute :title, String, lazy: true, default: 'Agency'

    def available_options
      GrdaWarehouse::Hud::Project.distinct.order(ProjectName: :asc).pluck(:ProjectName)
    end

    def default_input_type
      :select
    end

    def as_input default_value:, client_id:
      options = options_for_select(available_options, default_value)
      content_tag(:div, content_tag(:select, options, value: default_value, name: "#{column}[#{client_id}]"), class: "form-group string optional #{column}")
    end

  end
end