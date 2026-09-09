###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Date picker with an hours/minutes clock. Values render and parse in the app time zone.
class DatetimePickerInput < DatePickerInput
  private

  def display_pattern
    I18n.t('datepicker.dtformat', default: '%b %-d, %Y %-l:%M %p')
  end

  def picker_pattern
    I18n.t('datepicker.dtpformat', default: 'MMM d, yyyy h:mm T')
  end

  def date_options_base
    super.deep_merge(display: { components: { clock: true, hours: true, minutes: true } })
  end
end
