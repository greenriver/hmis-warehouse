###
# Copyright 2016 - 2024 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module HmisExternalApis::StaticPagesHelper
  def partial_path(partial)
    "hmis_external_apis/static_pages/#{partial}"
  end

  def register_field(name:, label:, type:, options: nil)
    @seen ||= Set.new
    raise "duplicate field name \"#{name}\", (#{label})" if name.in?(@seen)
    @seen.add(name)

    @field_collection.push({ name: name, label: label, type: type, options: options })
  end

  def render_form_input(label:, input_type: 'text', name: nil, input_pattern: nil, input_mode: nil, required: false, input_placeholder: nil)
    name ||= name_from_label(label)
    register_field(name: name, label: label, type: input_type)
    render partial_path('form/input'), label: label, input_type: input_type, name: name, required: required, input_pattern: input_pattern, html_id: next_html_id, input_mode: input_mode, input_placeholder: input_placeholder
  end

  def render_form_textarea(label:, name: nil, required: false, rows: 2)
    name ||= name_from_label(label)
    register_field(name: name, label: label, type: 'textarea')
    render partial_path('form/textarea'), label: label, name: name, required: required, rows: rows, html_id: next_html_id
  end

  def render_numeric_input(label:, name: nil, required: false, input_placeholder: nil, input_pattern: '\d*')
    render_form_input(label: label, name: name, required: required, input_pattern: input_pattern, input_mode: 'numeric', input_placeholder: input_placeholder)
  end

  def render_form_date(legend:, name: nil, required: false)
    name ||= name_from_label(legend)
    register_field(name: name, label: legend, type: 'date')
    render_form_fieldset(legend: legend, required: required) do
      render partial_path('form/date'), legend: legend, required: required, name: name
    end
  end

  def render_form_select(label:, name: nil, required: false, options:, &block)
    name ||= name_from_label(label)
    options = expand_options([{ label: '-- Select', value: '' }] + options)
    register_field(name: name, label: label, type: 'select', options: options)
    render partial_path('form/select'), label: label, options: options, name: name, required: required, html_id: next_html_id
  end

  def render_form_radio_group(legend:, name: nil, required: false, options:, &block)
    name ||= name_from_label(legend)
    options = expand_options(options)
    register_field(name: name, label: legend, type: 'radio', options: options)
    render_form_fieldset(legend: legend, required: required) do
      radios = render(partial_path('form/radio_group_options'), options: options, name: name, required: required, html_id: next_html_id)
      extra = capture(&block) if block
      safe_join([radios, extra].compact_blank, "\n")
    end
  end

  def render_form_actions
    render partial_path('form/actions')
  end

  def render_form_fieldset(legend:, required: false, &block)
    tag.fieldset do
      safe_join([
        tag.legend(legend, class: required && 'required'),
        capture(&block),
      ],"\n")
    end
  end

  def render_form_group(&block)
    tag.div(capture(&block), class: 'form-group')
  end

  def render_form_checkbox(label:, name: nil, required: false)
    name ||= name_from_label(legend)
    register_field(name: name, label: label, type: 'checkbox')
    render partial_path('form/checkbox'), label: label, name: name, html_id: next_html_id, required: required
  end

  def render_dependent_block(input_name:, input_value:, &block)
    content = capture(&block)
    content_tag(:div, content, class: 'dependent-form-group fade-effect')
    render partial_path('form/dependent_group'), content: content, html_id: next_html_id, input_name: input_name, input_value: input_value
  end

  def yes_no_options
    ['Yes', 'No']
  end

  def next_html_id
    @field_id ||= 0
    @field_id += 1
    "field-#{@field_id}"
  end

  def name_from_label(label)
    result = label.gsub(/\(.*?\)/, '').downcase.gsub(/[^0-9a-z]+/, ' ').squeeze(' ').strip.gsub(' ', '_')
    raise "label too long: \"#{label}\"" if result.length > 100

    result
  end

  def expand_options(opts)
    opts.map do |option|
      case option
      when String
        { value: name_from_label(option), label: option }
      when Hash
        option
      else
        raise
      end
    end
  end

  def page_config
    @page_config ||= HmisExternalApis::StaticPages::Config.new(
      site_title: 'Tarrant County Homeless Coalition',
      site_logo_url: 'https://ahomewithhope.org/wp-content/themes/tchc/assets/images/logo.png',
      site_logo_dimensions: [110, 60],
    )
  end
end
