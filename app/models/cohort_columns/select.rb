module CohortColumns
  class Select < Base

    
    def default_input_type
      :select2
    end
    
    def display_for user
      if display_as_editable?(user, cohort_client)
        select(form_group, column, available_options, {include_blank: true, selected: value(cohort_client)}, {class: ['select2', input_class]})
      else
        display_read_only(user)
      end
    end

    def renderer
      'dropdown'
    end

    def display_read_only user
      value(cohort_client)
    end
    
    def available_options
      Rails.cache.fetch("available_options_for_#{self.title}", expires_in: 5.minutes) do
        GrdaWarehouse::CohortColumnOption.where(cohort_column: self.title, active: true).map {|x| x.value}
      end
    end
    
  end
end
