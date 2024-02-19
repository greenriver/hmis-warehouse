
###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module StaticPagesHelper
  def render_form_input(label:, input_type: 'text', name: nil, input_pattern: nil, input_mode: nil, required: false, input_placeholder:nil)
    name ||= name_from_label(label)
    render 'static_pages/form/field', label: label, input_type: input_type, name: name, required: required, input_pattern: input_pattern, html_id: next_html_id, input_mode: input_mode, input_placeholder: input_placeholder
  end

  def render_form_textarea(label:, name: nil, required: false, rows: 2)
    name ||= name_from_label(label)
    render 'static_pages/form/textarea', label: label, name: name, required: required, rows: rows, html_id: next_html_id
  end

  def render_numeric_input(label:, name: nil, required: false, input_placeholder: nil)
    render_form_input(label: label, name: name, required: required, input_pattern: '[0-9*]', input_mode: 'numeric', input_placeholder: input_placeholder)
  end

  def render_form_date(legend:, name: nil, required: false)
    name ||= name_from_label(legend)
    render 'static_pages/form/date', legend: legend, required: required, name: name
  end

  def render_form_select(label:, input_type: 'text', name: nil, required: false, options:, footer: nil )
    name ||= name_from_label(label)
    options = expand_options([{label: "-- Select", value: ''}] + options)

    render 'static_pages/form/select', label: label, options: options, name: name, required: required, html_id: next_html_id, footer: footer
  end

  def render_form_radio_group(legend:, name: nil, required: false, options:, footer: nil, &block)
    content = capture(&block) if block
    name ||= name_from_label(legend)
    render 'static_pages/form/radio_group', legend: legend, options: expand_options(options), name: name, required: required, html_id: next_html_id, footer: content
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
    label.downcase.gsub(/[^0-9a-z]+/, ' ').squeeze.strip.gsub(' ', '_')
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

  def render_dependent_block(input_name:, input_value:,&block)
    content = capture(&block)
    content_tag(:div, content, class: "dependent-form-group fade-effect")
    render 'static_pages/form/dependent_group', content: content, html_id: next_html_id, input_name: input_name, input_value: input_value
  end
end
