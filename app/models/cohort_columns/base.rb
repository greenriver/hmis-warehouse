module CohortColumns
  class Base < ::ModelForm
    include ActionView::Helpers::TagHelper
    attr_accessor :column, :title, :hint, :visible
    attribute :visible, Boolean, lazy: false, default: true
    attribute :editable, Boolean, lazy: false, default: true 
    attribute :input_type, String, lazy: true, default: -> (r,_) { r.default_input_type }
    attribute :cohort
    attribute :cohort_names

    def display_for_user user
      if user.can_manage_cohorts?
        input_type
      else
        if editable
          input_type
        else
          :read_only
        end
      end
    end

    def default_input_type
      :string
    end

    def has_default_value?
      false
    end

    def default_value client_id
      nil
    end    

    def value cohort_client
      cohort_client.send(column)
    end
  end
end
