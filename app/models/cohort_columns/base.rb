module CohortColumns
  class Base < ::ModelForm
    include ActionView::Helpers::TagHelper
    attr_accessor :column, :title, :hint, :visible
    attribute :visible, Boolean, lazy: false, default: true
    attribute :input_type, String, lazy: true, default: -> (r,_) { r.default_input_type }

    def default_input_type
      :string
    end
    
    def as_input default_value:, client_id:
      content_tag(:div, content_tag(:input, nil, value: default_value, name: "#{column}[#{client_id}]"), class: "form-group string optional #{column}")
    end
  end
end