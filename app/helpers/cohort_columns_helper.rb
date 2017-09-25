module CohortColumnsHelper
  def input_for(column, default_value:, client_id:)
    name = column.column
    content_tag(:div, class: "form-group #{column.input_type} optional #{column}") do
      case column.input_type
      when 'string'
        content_tag(:input, nil, value: default_value, name: name)
      when 'select'
        select_tag(name, options_for_select(column.available_options, default_value), class: 'select2', include_blank: true, data: {placeholder: column.title})
      end
    end
  end
end