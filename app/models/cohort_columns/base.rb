module CohortColumns
  class Base < ::ModelForm
    include ActionView::Helpers::TagHelper
    attr_accessor :column, :title, :hint, :visible
    attribute :visible, Boolean, lazy: false, default: true
    attribute :input_type, String, lazy: true, default: -> (r,_) { r.default_input_type }

    def default_input_type
      :string
    end
    
  end
end
