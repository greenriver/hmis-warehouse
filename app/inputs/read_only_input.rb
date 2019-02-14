class ReadOnlyInput < SimpleForm::Inputs::StringInput
  def input(wrapper_options = nil)
    if @builder.options[:wrapper] == :readonly
      display_value = object.send(attribute_name)
      if has_hint?
        template.content_tag(:p, display_value, label_html_options)
      else
        existing_classes = label_html_options.try(:[], :class)
        existing_classes << 'd-block'
        existing_classes << 'readonly-value'
        template.content_tag(:p, display_value, label_html_options.merge({class: existing_classes}))
      end
    else
      super(wrapper_options)
    end
  end
end