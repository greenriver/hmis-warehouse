###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class BooleanInput < SimpleForm::Inputs::BooleanInput
  def input(wrapper_options = nil)
    if @builder.options[:wrapper] == :readonly || input_options[:readonly] == true
      display_value = object.send(attribute_name)
      if display_value
        template.content_tag(:span, nil, label_html_options.merge(class: 'icon-checkmark o-color--positive mr-2'))
      else
        template.content_tag(:span, nil, label_html_options.merge(class: 'icon-cross o-color--warning mr-2'))
      end
    else
      super(wrapper_options)
    end
  end
end
