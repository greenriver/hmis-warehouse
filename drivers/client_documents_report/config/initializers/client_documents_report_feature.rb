# The core app (or other drivers) can check the presence of the
# ClientDocumentsReport driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:client_documents_report)
#
# use with caution!
RailsDrivers.loaded << :client_documents_report
