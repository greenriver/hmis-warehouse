# The core app (or other drivers) can check the presence of the
# CustomImportsBostonCommunityOfOrigin driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:custom_imports_boston_community_of_origin)
#
# use with caution!
RailsDrivers.loaded << :custom_imports_boston_community_of_origin

Rails.application.config.custom_imports << 'CustomImportsBostonCommunityOfOrigin::ImportFile'
Rails.application.config.location_processors << 'CustomImportsBostonCommunityOfOrigin::ProcessLocationDataJob'
Rails.application.config.location_processors << 'CustomImportsBostonCommunityOfOrigin::MaintainLocationHistoryJob'
