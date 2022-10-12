# The core app (or other drivers) can check the presence of the
# MaYyaReport driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:ma_yya_report)
#
# use with caution!
RailsDrivers.loaded << :ma_yya_report

Rails.application.config.synthetic_youth_education_status_types << 'MaYyaReport::Synthetic::YouthEducationStatus'
