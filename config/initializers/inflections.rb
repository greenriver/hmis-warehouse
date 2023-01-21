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
# zeitwerk overrides
Rails.autoloaders.main.inflector.inflect('dob' => 'Dob')
Rails.autoloaders.main.inflector.inflect('lgbtq' => 'Lgbtq')
Rails.autoloaders.main.inflector.inflect('lgbtq_from_hmis' => 'LgbtqFromHmis')
Rails.autoloaders.main.inflector.inflect('ssn' => 'Ssn')
Rails.autoloaders.main.inflector.inflect('coc' => 'Coc')
Rails.autoloaders.main.inflector.inflect('overlapping_coc' => 'OverlappingCoc')
Rails.autoloaders.main.inflector.inflect('overlapping_coc_by_project_type' => 'OverlappingCocByProjectType')
Rails.autoloaders.main.inflector.inflect('project_coc' => 'ProjectCoc')
Rails.autoloaders.main.inflector.inflect('enrollment_coc' => 'EnrollmentCoc')
Rails.autoloaders.main.inflector.inflect('project_coc_extension' => 'ProjectCocExtension')
Rails.autoloaders.main.inflector.inflect('enrollment_coc_extension' => 'EnrollmentCocExtension')
Rails.autoloaders.main.inflector.inflect('coc_code' => 'CocCode')
Rails.autoloaders.main.inflector.inflect('coc_agg' => 'CocAgg')
Rails.autoloaders.main.inflector.inflect('project_coc_validator' => 'ProjectCocValidator')
Rails.autoloaders.main.inflector.inflect('create_project_coc' => 'CreateProjectCoc')
Rails.autoloaders.main.inflector.inflect('project_coc_input' => 'ProjectCocInput')
Rails.autoloaders.main.inflector.inflect('update_project_coc' => 'UpdateProjectCoc')
Rails.autoloaders.main.inflector.inflect('delete_project_coc' => 'DeleteProjectCoc')
Rails.autoloaders.main.inflector.inflect('force_project_enrollment_coc' => 'ForceProjectEnrollmentCoc')
Rails.autoloaders.main.inflector.inflect('force_valid_enrollment_coc' => 'ForceValidEnrollmentCoc')
