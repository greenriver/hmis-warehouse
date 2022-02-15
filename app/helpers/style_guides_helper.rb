###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module StyleGuidesHelper
  def detail_block title:, value:, wrapper_classes: [], tooltip: nil
    base_class = "c-detail-block"
    title_el = tag.div(title, class: "#{base_class}__title")
    value_tooltip_attrs = {}
    if tooltip
      value_tooltip_attrs = {
        title: tooltip,
        data: { toggle: "tooltip", html: "true" }
      }
    end
    value_el = tag.div(value, class: "#{base_class}__value")
    attrs = value_tooltip_attrs.merge( class: [ base_class ] + wrapper_classes.map{ |c| "#{base_class}--#{c}" })
    tag.div title_el + value_el, **attrs
  end

  def details_title_attr(metadata)
    return "" unless metadata
    title = nil
    details = metadata.map { |k, v| "<li>#{k.to_s.titleize}: <b>#{v}</b></li>" }
    title = "<ul class='list-unstyled mb-0'>#{details.join('')}</ul>"
    title
  end
end
