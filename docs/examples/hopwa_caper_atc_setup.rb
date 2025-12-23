# frozen_string_literal: true

###
# Sample Ruby code to setup AppConfigProperty records for HOPWA CAPER ATC tab
#
# This can be run in Rails console or as a rake task
###

# ============================================================================
# Option 1: Direct AppConfigProperty setup (Rails console)
# ============================================================================

# Enable the ATC tab
AppConfigProperty.find_or_create_by(key: 'hopwa_caper/atc_tab_enabled') do |prop|
  prop.value = 'true'
end

# Set custom field names for Charlotte installation
AppConfigProperty.find_or_create_by(key: 'hopwa_caper/atc_maintained_contact_field_name') do |prop|
  prop.value = 'charlotte_hopwa_intake_maintained_contact'
end

AppConfigProperty.find_or_create_by(key: 'hopwa_caper/atc_housing_plan_field_name') do |prop|
  prop.value = 'charlotte_hopwa_intake_housing_plan'
end

AppConfigProperty.find_or_create_by(key: 'hopwa_caper/atc_primary_health_contact_field_name') do |prop|
  prop.value = 'charlotte_hopwa_intake_primary_health_contact'
end

# ============================================================================
# Option 2: Using update_or_create (more concise)
# ============================================================================

[
  ['hopwa_caper/atc_tab_enabled', 'true'],
  ['hopwa_caper/atc_maintained_contact_field_name', 'charlotte_hopwa_intake_maintained_contact'],
  ['hopwa_caper/atc_housing_plan_field_name', 'charlotte_hopwa_intake_housing_plan'],
  ['hopwa_caper/atc_primary_health_contact_field_name', 'charlotte_hopwa_intake_primary_health_contact'],
].each do |key, value|
  AppConfigProperty.find_or_initialize_by(key: key).tap do |prop|
    prop.value = value
    prop.save!
  end
end

# ============================================================================
# Option 3: Using the Configuration class pattern (recommended)
# ============================================================================

def setup_hopwa_caper_atc_config(
  enabled: true,
  maintained_contact_field: 'charlotte_hopwa_intake_maintained_contact',
  housing_plan_field: 'charlotte_hopwa_intake_housing_plan',
  primary_health_contact_field: 'charlotte_hopwa_intake_primary_health_contact'
)
  config = {
    'hopwa_caper/atc_tab_enabled' => enabled.to_s,
    'hopwa_caper/atc_maintained_contact_field_name' => maintained_contact_field,
    'hopwa_caper/atc_housing_plan_field_name' => housing_plan_field,
    'hopwa_caper/atc_primary_health_contact_field_name' => primary_health_contact_field,
  }

  config.each do |key, value|
    AppConfigProperty.find_or_initialize_by(key: key).tap do |prop|
      prop.value = value
      prop.save!
      puts "Set #{key} = #{value}"
    end
  end
end

# Usage:
# setup_hopwa_caper_atc_config

# ============================================================================
# Option 4: Verify configuration
# ============================================================================

def verify_hopwa_caper_atc_config
  config = HopwaCaper::Configuration.new

  puts "ATC Tab Enabled: #{config.atc_tab_enabled?}"
  puts "Maintained Contact Field: #{config.atc_maintained_contact_field_name}"
  puts "Housing Plan Field: #{config.atc_housing_plan_field_name}"
  puts "Primary Health Contact Field: #{config.atc_primary_health_contact_field_name}"
end

# Usage:
# verify_hopwa_caper_atc_config

# ============================================================================
# Option 5: Disable ATC tab
# ============================================================================

def disable_hopwa_caper_atc
  AppConfigProperty.find_or_initialize_by(key: 'hopwa_caper/atc_tab_enabled').tap do |prop|
    prop.value = 'false'
    prop.save!
    puts 'ATC tab disabled'
  end
end

# Usage:
# disable_hopwa_caper_atc


