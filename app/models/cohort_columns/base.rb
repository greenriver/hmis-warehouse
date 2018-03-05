module CohortColumns
  class Base < ::ModelForm
    include ActionView::Helpers
    include ActionView::Context
    include Rails.application.routes.url_helpers
    attr_accessor :column, :title, :hint, :visible
    attribute :visible, Boolean, lazy: false, default: true
    attribute :input_type, String, lazy: true, default: -> (r,_) { r.default_input_type }
    attribute :cohort
    attribute :cohort_names
    attribute :cohort_client

    def display_as_editable? user, cohort_client
      cohort.user_can_edit_cohort_clients(user) && (user.can_manage_cohorts? || ! cohort_client.ineligible?)
    end

    def editable?
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

    def form_group
      "cohort_client[#{cohort_client.id}]"
    end  

    def value cohort_client
      cohort_client.send(column)
    end
  end
end
