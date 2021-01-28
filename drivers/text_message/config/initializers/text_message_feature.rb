# The core app (or other drivers) can check the presence of the
# TextMessage driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:text_message)
#
# use with caution!
RailsDrivers.loaded << :text_message
