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
          fields_container,
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
    input_html_options[:value] ||= display_value
    input_html_options[:autocomplete] ||= 'off'
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
      options.delete(:required)
      options
    end
  end

  def fields_container
    template.content_tag(:div, class: fields_container_classes) do
      template.safe_join([month_field, day_field, year_field])
    end
  end

  def fields_container_classes
    %w[row gx-2 gy-1 align-items-end datepicker2__fields].join(' ')
  end

  def month_field
    segment(
      label: I18n.t('date_picker2.month_label', default: 'Month'),
      id_suffix: 'month',
      placeholder: 'MM',
      maxlength: 2,
      pattern: '(0?[1-9]|1[0-2])',
      target: 'month',
      value: padded_value(value_parts[:month], 2),
    )
  end

  def day_field
    segment(
      label: I18n.t('date_picker2.day_label', default: 'Day'),
      id_suffix: 'day',
      placeholder: 'DD',
      maxlength: 2,
      pattern: '(0?[1-9]|[12][0-9]|3[01])',
      target: 'day',
      value: padded_value(value_parts[:day], 2),
    )
  end

  def year_field
    segment(
      label: I18n.t('date_picker2.year_label', default: 'Year'),
      id_suffix: 'year',
      placeholder: 'YYYY',
      maxlength: 4,
      pattern: '(19|20)\d{2}',
      target: 'year',
      value: padded_value(value_parts[:year], 4),
    )
  end

  def segment(label:, id_suffix:, placeholder:, maxlength:, pattern:, target:, value: nil)
    template.content_tag(:div, class: 'col-auto datepicker2__segment') do
      template.safe_join(
        [
          template.label_tag(segment_id(id_suffix), label, class: 'form-label'),
          template.text_field_tag(
            nil,
            value,
            segment_html_options(
              id_suffix:,
              placeholder:,
              maxlength:,
              pattern:,
              target:,
            ),
          ),
        ],
      )
    end
  end

  def segment_html_options(id_suffix:, placeholder:, maxlength:, pattern:, target:)
    {
      id: segment_id(id_suffix),
      class: 'form-control datepicker2__input',
      placeholder:,
      maxlength:,
      inputmode: 'numeric',
      pattern:,
      'aria-describedby': validation_message_id,
      'aria-invalid': 'false',
      autocomplete: 'off',
      required: required?,
      data: {
        datepicker2_target: target,
        action: 'input->datepicker2#handleSegmentInput blur->datepicker2#handleSegmentBlur keydown->datepicker2#handleSegmentKeydown',
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
    classes = %w[input-group flex-wrap align-items-start w-auto datepicker2]
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

  def segment_id(id_suffix)
    [base_dom_id, id_suffix].compact.join('_')
  end

  def base_dom_id
    hidden_input_html_options[:id] || [@builder.object_name, attribute_name].compact.join('_')
  end

  def validation_message_id
    @validation_message_id ||= [base_dom_id, 'validation'].join('_')
  end

  def value_parts
    return @value_parts if defined?(@value_parts)

    raw_date = extract_date_from_value
    if raw_date
      @value_parts = {
        month: raw_date.month,
        day: raw_date.day,
        year: raw_date.year,
      }
    else
      @value_parts = { month: nil, day: nil, year: nil }
    end
  end

  def extract_date_from_value
    value = input_html_options[:value]
    return unless value.present?

    return value.to_date if value.respond_to?(:to_date)

    Date.parse(value.to_s)
  rescue ArgumentError
    nil
  end

  def padded_value(number, length)
    return unless number.present?

    format("%0#{length}d", number)
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
end
