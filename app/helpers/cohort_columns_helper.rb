module CohortColumnsHelper
  def input_for(column, default_value:, client_id:)
    name = "cohort_client[#{column.column}]"
    content_tag(:div, class: "form-group #{column.input_type} optional #{column.column} jCohortClientInput") do
      case column.input_type
      when 'string'
        content_tag(:input, nil, value: default_value, name: name)
      when 'integer'
        content_tag(:input, nil, value: default_value, name: name, type: :number)
      when 'select'
        select_tag(name, options_for_select(column.available_options, default_value), include_blank: true)
      when 'select2_input'
        select_tag(name, options_for_select(column.available_options, default_value), class: 'select2', include_blank: true, data: {placeholder: column.title})
      when 'datetime'
        content_tag(:div, 
                    class: "input-group date optional #{column.column}",
                    data: {provide: :datepicker}
                   ) do
          concat content_tag(:input, nil, class: "form-control", value: default_value, name: name, style: 'width:115px')
          concat content_tag(:span, nil, class: 'input-group-addon icon-calendar')
        end
      when 'radio'
        content_tag(:div, nil, class: "form-group string optional #{column.column}") do
          column.available_options.each do |option|
            kebab_case = option.downcase.gsub(/\s/, '-')
            concat content_tag(:input, nil, type: :radio, value: option, 
                               name: name, checked: default_value == option, id: "#{client_id}-#{kebab_case}-choice"
            )
            concat content_tag(:label, option, for: "#{client_id}-#{kebab_case}-choice")
            concat '&nbsp;&nbsp;'.html_safe
          end
        end
      end
    end
  end
end
