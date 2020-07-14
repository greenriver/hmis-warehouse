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
      if control_id.in?(@control_ids)
        raise "duplicate ID for control #{control_id}"
      end
      @control_ids.add(control_id)

      self.controls.push(
        ::Filters::UiControl.new(**args)
      )
    end
  end

  class UiControl
    attr_accessor :id, :label, :required

    def initialize(id:, label: nil, required: false)
      self.id = id
      self.label = label || id.humanize.titleize
      self.required = required
    end

    def summary_partial_path
      "/performance_dashboards/filter_controls/#{id}/summary"
    end

    def input_partial_path
      "/performance_dashboards/filter_controls/#{id}/input"
    end

  end

end

