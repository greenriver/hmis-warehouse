
###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module StaticPagesHelper
  def render_form_input(label:, input_type: 'text', name: nil, required: false)
    name ||= name_from_label(label)
    render 'static_pages/form/field', label: label, input_type: input_type, name: name, required: required, html_id: next_html_id
  end

  def render_form_textarea(label:, name: nil, required: false, rows: 2)
    name ||= name_from_label(label)
    render 'static_pages/form/textarea', label: label, name: name, required: required, rows: rows, html_id: next_html_id
  end

  def render_form_select(label:, input_type: 'text', name: nil, required: false, options: )
    name ||= name_from_label(label)
    options = expand_options([{label: "-- Select", value: ''}] + options)

    render 'static_pages/form/select', label: label, options: options, name: name, required: required, html_id: next_html_id
  end

  def render_form_radio_group(legend:, name: nil, required: false, options: )
    name ||= name_from_label(legend)
    render 'static_pages/form/radio_group', legend: legend, options: expand_options(options), name: name, required: required, html_id: next_html_id
  end

  def render_form_actions
    render 'static_pages/form/actions'
  end

  def render_form_checkboxes(legend:, name: nil, options:)
    name ||= name_from_label(legend)
    render 'static_pages/form/checkboxes', legend: legend, name: name, options: expand_options(options), html_id: next_html_id
  end

  def yes_no_options
    ['Yes', 'No']
  end

  def next_html_id
    @field_id ||= 0
    @field_id +=1
    html_id = "field-#{@field_id}"
  end

  def name_from_label(label)
    label.downcase.gsub(/[^0-9a-z]+/, ' ').squeeze.gsub(' ', '_')
  end

  def expand_options(opts)
    opts.map do |option|
      case option
      when String
        {value: name_from_label(option), label: option}
      when Hash
        option
      else
        raise
      end
    end
  end
end
