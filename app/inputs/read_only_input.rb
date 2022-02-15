###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class ReadOnlyInput < SimpleForm::Inputs::StringInput
  def input(wrapper_options = nil)
    if @builder.options[:wrapper] == :readonly || input_options.dig(:as) == :read_only || input_options[:readonly] == true
      display_value = object.send(attribute_name)

      if has_hint?
        template.content_tag(:p, display_value, label_html_options)
      else
        existing_classes = label_html_options.try(:[], :class)
        existing_classes << 'd-block'
        if display_value.in?([true, false])

        elsif display_value.present?
          template.content_tag(:p, display_value, label_html_options.merge(class: existing_classes))
        else
          template.content_tag(:em, 'Blank', label_html_options.merge(class: existing_classes))
        end
      end
    else
      super(wrapper_options)
    end
  end
end
