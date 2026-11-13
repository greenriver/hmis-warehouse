###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Date picker with a 12-hour clock shown beside the calendar. Values render and parse in the app
# time zone. Two-digit `hh` rather than `h`: Tempus Dominus computes `h` by hand and shows
# midnight as 0:00, while `hh` goes through Intl and shows 12:00 AM.
class DatetimePickerInput < DatePickerInput
  private

  def display_pattern
    I18n.t('datepicker.dtformat', default: '%b %-d, %Y %I:%M %p')
  end

  def picker_pattern
    I18n.t('datepicker.dtpformat', default: 'MMM d, yyyy hh:mm T')
  end

  def date_options_base
    super.deep_merge(
      display: {
        sideBySide: true,
        components: { clock: true, hours: true, minutes: true },
      },
      localization: { hourCycle: 'h12' },
    )
  end
end
