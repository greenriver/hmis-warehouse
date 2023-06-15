###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module CohortColumns
  class Base < ::ModelForm
    include ActionView::Helpers
    include ActionView::Context
    include ApplicationHelper
    include Rails.application.routes.url_helpers
    include ArelHelper
    attr_accessor :column, :translation_key, :title, :hint, :visible

    attribute :visible, Boolean, lazy: false, default: true
    attribute :input_type, String, lazy: true, default: ->(r, _) { r.default_input_type }
    attribute :cohort
    attribute :cohort_names
    attribute :cohort_client
    attribute :editable, Boolean, lazy: false, default: true
    attribute :current_user

    def available_for_rules?
      true
    end

    def cast_value(val)
      val.to_s
    end

    def arel_col
      c_client_t[column]
    end

    def display_as_editable?(user, _cohort_client, on_cohort: cohort)
      on_cohort.user_can_edit_cohort_clients(user) && (user.can_manage_cohort_data? || (editable && user.can_participate_in_cohorts?))
    end

    def column_editable?
      true
    end

    def default_input_type
      :string
    end

    def default_value?
      false
    end

    def default_value(_client_id)
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

    # momentjs compatible
    def date_format
      nil
    end

    def width
      100
    end

    def description
      ''
    end

    def form_group
      "cohort_client[#{cohort_client.id}]"
    end

    def value(cohort_client)
      cohort_client.send(column)
    end

    def value_requires_user?
      false
    end

    def input_class
      'jCohortClientInput'
    end

    private def effective_date
      cohort.effective_date || Date.current
    end
  end
end
