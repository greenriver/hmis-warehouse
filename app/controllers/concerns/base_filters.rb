###
# Copyright 2016 - 2021 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module BaseFilters
  extend ActiveSupport::Concern
  included do
    before_action :set_filter

    def filters
      return unless @report

      @sections = @report.control_sections
      @chosen_section = @sections.detect do |section|
        section.id == params[:filter_section_id]
      end

      @modal_size = :xxl if @chosen_section.nil?
    end

    private def set_filter
      @filter = filter_class.new(user_id: current_user.id)
      @filter.set_from_params(filter_params[:filters]) if filter_params[:filters].present?
      @comparison_filter = @filter.to_comparison
    end

    private def filter_item_selection_summary(value, default = 'All')
      render_to_string partial: '/filters/filter_controls/helpers/items_selection_summary', locals: { value: value, default: default }
    end
    helper_method :filter_item_selection_summary

    def breakdown
      @breakdown ||= params[:breakdown]&.to_sym || :none
    end
    helper_method :breakdown
  end
end
