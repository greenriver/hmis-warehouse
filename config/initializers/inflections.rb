# Be sure to restart your server when you modify this file.

# Add new inflection rules using the following format. Inflections
# are locale specific, and you may define rules for as many different
# locales as you wish. All of these examples are active by default:
# ActiveSupport::Inflector.inflections(:en) do |inflect|
#   inflect.plural /^(ox)$/i, '\1en'
#   inflect.singular /^(ox)en/i, '\1'
#   inflect.irregular 'person', 'people'
#   inflect.uncountable %w( fish sheep )
# end

# These inflection rules are supported but not enabled by default:
# ActiveSupport::Inflector.inflections(:en) do |inflect|
#   inflect.acronym 'RESTful'
# end
ActiveSupport::Inflector.inflections(:en) do |inflect|
  inflect.irregular 'census', 'censuses'
  inflect.irregular 'supplemental_enrollment_data', 'supplemental_enrollment_data'

  inflect.acronym 'SSN'
  inflect.acronym 'DOB'
  inflect.acronym 'DND'
  inflect.acronym 'CoC'
  inflect.acronym 'DHCD'
  inflect.acronym 'LGBTQ'
end
