###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module Filters
  class UiControlSection
    attr_accessor :id, :title, :controls

    def initialize(id:, title: nil)
      self.id = id
      self.title = title || id.humanize.titleize
      self.controls = []
      @control_ids = Set.new
    end

    def add_control(args)
      control_id = args.fetch(:id)
      raise "duplicate ID for control #{control_id}" if control_id.in?(@control_ids)

      @control_ids.add(control_id)

      controls.push(
        ::Filters::UiControl.new(**args),
      )
    end
  end

  class UiControl
    attr_accessor :id, :label, :short_label, :value, :required, :hint

    def initialize(id:, value:, label: nil, short_label: nil, required: false, hint: nil) # rubocop:disable Metrics/ParameterLists
      self.id = id
      self.label = label || id.humanize.titleize
      self.short_label = short_label || self.label
      self.required = required
      self.hint = hint
      self.value = value
    end

    def report_period?
      id =~ /_period\z/
    end

    def summary_partial_path
      "/filters/filter_controls/#{id}/summary"
    end

    def input_partial_path
      "/filters/filter_controls/#{id}/input"
    end
  end
end
