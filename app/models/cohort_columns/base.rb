module CohortColumns
  class Base < ::ModelForm
    include ActionView::Helpers
    include ActionView::Context
    include ApplicationHelper
    include Rails.application.routes.url_helpers
    attr_accessor :column, :title, :hint, :visible
    attribute :visible, Boolean, lazy: false, default: true
    attribute :input_type, String, lazy: true, default: -> (r,_) { r.default_input_type }
    attribute :cohort
    attribute :cohort_names
    attribute :cohort_client
    attribute :editable, Boolean, lazy: false, default: true

    def display_as_editable? user, cohort_client
      cohort.user_can_edit_cohort_clients(user) && (user.can_manage_cohorts? || ! cohort_client.ineligible? && editable)
    end

    def column_editable?
      true
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

    def comments
      nil
    end

    def available_options
      nil
    end

    def renderer
      'text'
    end

    def width
      100
    end

    def form_group
      "cohort_client[#{cohort_client.id}]"
    end  

    def value cohort_client
      cohort_client.send(column)
    end

    def input_class
      'jCohortClientInput'
    end
  end
end
