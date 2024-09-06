###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::ExternalFormsHelper
  def partial_path(partial)
    "hmis_external_apis/external_forms/#{partial}"
  end

  def render_form_input(label:, input_type: 'text', name:, input_pattern: nil, input_mode: 'text', required: false, input_placeholder: nil, input_class: nil, input_html_id: next_html_id, input_helper: nil, input_invalid_feedback: nil) # rubocop:disable Metrics/ParameterLists
    input_invalid_feedback ||= required ? 'This is required' : nil
    render partial_path('form/input'), label: label, input_type: input_type, name: name, required: required, input_pattern: input_pattern, html_id: input_html_id, input_mode: input_mode, input_placeholder: input_placeholder, input_class: input_class, input_helper: input_helper, input_invalid_feedback: input_invalid_feedback
  end

  def render_form_textarea(label:, name:, required: false, rows: 2, input_invalid_feedback: nil, input_helper: nil)
    input_invalid_feedback ||= required ? 'This is required' : nil
    render partial_path('form/textarea'), label: label, name: name, required: required, rows: rows, html_id: next_html_id, input_invalid_feedback: input_invalid_feedback, input_helper: input_helper
  end

  def render_numeric_input(label:, name:, required: false, input_placeholder: nil, input_pattern: '\d*', input_html_id: next_html_id, input_helper: nil, input_invalid_feedback: 'Must be a number')
    render_form_input(label: label, name: name, required: required, input_pattern: input_pattern, input_mode: 'numeric', input_placeholder: input_placeholder, input_html_id: input_html_id, input_helper: input_helper, input_invalid_feedback: input_invalid_feedback)
  end

  def render_form_date(legend:, name: nil, required: false)
    name ||= name_from_label(legend)
    render_form_fieldset(legend: legend, required: required) do
      render partial_path('form/date'), legend: legend, required: required, name: name
    end
  end

  def render_form_select(label:, name:, required: false, options:)
    render partial_path('form/select'), label: label, options: options, name: name, required: required, html_id: next_html_id
  end

  def render_form_radio_group(legend:, name:, required: false, options:, &block)
    render_form_fieldset(legend: legend, required: required) do
      radios = render(partial_path('form/radio_group_options'), options: options, name: name, required: required, html_id: next_html_id)
      extra = capture(&block) if block
      safe_join([radios, extra].compact_blank, "\n")
    end
  end

  def render_section(title:, &block)
    tag.section do
      safe_join(
        [tag.h2(title, class: 'h4 mb-3'), capture(&block)],
        "\n",
      )
    end
  end

  def render_form_actions
    render partial_path('form/actions')
  end

  def render_form_fieldset(legend:, required: false, &block)
    tag.fieldset do
      safe_join(
        [tag.legend(legend, class: required && 'required'), capture(&block)],
        "\n",
      )
    end
  end

  def render_form_group(needs_validation: false, &block)
    tag.div(capture(&block), class: "form-group #{needs_validation ? 'needs-validation' : nil}")
  end

  def render_form_checkbox(label:, name: nil, required: false)
    name ||= name_from_label(legend)
    render partial_path('form/checkbox'), label: label, name: name, html_id: next_html_id, required: required
  end

  def render_dependent_block(conditions:, &block)
    content = capture(&block)
    content_tag(:div, content, class: 'dependent-form-group fade-effect')
    render partial_path('form/dependent_group'), content: content, html_id: next_html_id, conditions: conditions
  end

  def next_html_id
    @field_id ||= 0
    @field_id += 1
    "field-#{@field_id}"
  end

  def render_modal(title:, html_id: next_html_id, blocker: false, &block)
    content = capture(&block)
    render partial_path('modal'), content: content, html_id: html_id, title: title, blocker: blocker
  end

  def page_config
    @page_config ||= HmisExternalApis::ExternalForms::Config.new
  end
end
