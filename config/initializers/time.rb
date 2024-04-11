Rails.configuration.to_prepare do
  TodoOrDie('Remove deprecated date/time.to_s', by: '2024-07-01')
end
# FIXME: Using a :default format for Date#to_s is deprecated
Date::DATE_FORMATS[:default] = '%b %e, %Y'
Time::DATE_FORMATS[:default] = '%b %e, %Y %l:%M %P'
