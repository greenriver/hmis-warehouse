###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

class DatePicker2Input < SimpleForm::Inputs::StringInput
  def input(wrapper_options)
    prepare_html_options

    if readonly?
      return readonly_display
    end

    template.content_tag(:div, wrapper_html_options) do
      template.safe_join(
        [
          hidden_field(wrapper_options),
          masked_input_field,
          validation_message_container,
        ],
      )
    end
  end

  private

  def readonly?
    @builder.options[:wrapper] == :readonly || truthy?(input_options[:readonly])
  end

  def truthy?(value)
    value.present? && value != false
  end

  def prepare_html_options
    input_html_options[:data] ||= {}
    @date_options ||= input_html_options[:data][:date_options] || input_html_options[:data]['date_options']
    input_html_options[:id] ||= masked_dom_id
    input_html_options[:value] ||= display_value
    input_html_options[:autocomplete] ||= 'off'
    label_html_options[:for] ||= masked_dom_id
  end

  def readonly_display
    display_value = input_html_options[:value]

    if display_value.present?
      template.content_tag(:p, display_value, label_html_options)
    else
      template.content_tag(:em, 'Blank', label_html_options)
    end
  end

  def hidden_field(wrapper_options)
    options = merge_wrapper_options(hidden_input_html_options, wrapper_options)
    @builder.hidden_field(attribute_name, options)
  end

  def hidden_input_html_options
    @hidden_input_html_options ||= begin
      options = input_html_options.deep_dup

      options[:data] ||= {}
      options[:data][:datepicker2_target] = 'hiddenInput'
      options[:data].delete(:date_options)
      options[:data].delete('date_options')
      options[:aria] ||= {}
      options[:aria][:describedby] = validation_message_id
      options[:id] = hidden_dom_id
      options.delete(:required)
      options
    end
  end

  def masked_input_field
    template.text_field_tag(nil, masked_input_value, masked_input_html_options)
  end

  def masked_input_html_options
    {
      id: masked_dom_id,
      class: 'form-control datepicker2__input',
      placeholder: 'MM/DD/YYYY',
      maxlength: 10,
      inputmode: 'numeric',
      pattern: '(0[1-9]|1[0-2])/(0[1-9]|[12][0-9]|3[01])/(19|20)\d{2}',
      autocomplete: 'off',
      required: required_field?,
      'aria-describedby': validation_message_id,
      'aria-invalid': 'false',
      data: {
        datepicker2_target: 'maskedInput',
        action: 'input->datepicker2#handleMaskedInput blur->datepicker2#handleMaskedBlur',
      },
    }
  end

  def validation_message_container
    template.content_tag(
      :div,
      '',
      id: validation_message_id,
      class: 'form-text text-danger small mt-1 d-none datepicker2__message',
      role: 'alert',
      data: { datepicker2_target: 'validationMessage' },
    )
  end

  def wrapper_html_options
    classes = %w[datepicker2]
    classes.concat(Array(wrapper_classes))

    existing_controller = input_html_options[:data][:controller] || input_html_options[:data]['controller']
    controller_value = [existing_controller, 'datepicker2'].compact.join(' ').strip

    data_attributes = {
      controller: controller_value,
      'datepicker2-display-pattern-value': display_pattern,
      'datepicker2-locale-value': I18n.locale.to_s,
    }

    if (options = @date_options || date_options).present?
      data_attributes['date-options'] = options.to_json
    end

    { class: classes.join(' '), data: data_attributes }
  end

  def wrapper_classes
    Array(input_options[:wrapper_html_class])
  end

  def date_options
    data = input_html_options[:data]
    return unless data

    data[:date_options] || data['date_options']
  end

  def hidden_dom_id
    [base_dom_id, 'hidden'].join('_')
  end

  def masked_dom_id
    base_dom_id
  end

  def validation_message_id
    @validation_message_id ||= [base_dom_id, 'validation'].join('_')
  end

  def extract_date_from_value
    value = input_html_options[:value]
    return unless value.present?

    return value.to_date if value.respond_to?(:to_date)

    Date.parse(value.to_s)
  rescue ArgumentError
    nil
  end

  def masked_input_value
    date = extract_date_from_value
    return unless date

    date.strftime('%m/%d/%Y')
  end

  def display_value
    return input_html_options[:value] if input_html_options[:value].present?

    object_value = value
    return unless object_value.present?

    if object_value.is_a?(String)
      parsed = parse_string_date(object_value)
      return localize_date(parsed) if parsed

      object_value
    else
      localize_date(object_value.to_date)
    end
  end

  def value
    object.send(attribute_name) if object.respond_to?(attribute_name)
  end

  def display_pattern
    I18n.t('datepicker.dformat', default: '%b %-d, %Y')
  end

  def localize_date(date)
    I18n.localize(date, format: display_pattern)
  end

  def parse_string_date(value)
    Date.parse(value)
  rescue ArgumentError
    nil
  end

  def base_dom_id
    @base_dom_id ||= begin
      id = input_html_options[:id] || input_html_options['id']
      id.presence || [@builder.object_name, attribute_name].compact.join('_')
    end
  end
end
