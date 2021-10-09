# The core app (or other drivers) can check the presence of the
# CustomImports driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:custom_imports)
#
# use with caution!
RailsDrivers.loaded << :custom_imports
