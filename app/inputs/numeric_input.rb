class NumericInput < SimpleForm::Inputs::NumericInput
  def input(wrapper_options = nil)
    if @builder.options[:wrapper] == :readonly
      display_value = object.send(attribute_name)
      if has_hint?
        template.content_tag(:p, display_value, label_html_options)
      else
        template.content_tag(:p, display_value, label_html_options)
      end
    else
      super(wrapper_options)
    end
  end
end
