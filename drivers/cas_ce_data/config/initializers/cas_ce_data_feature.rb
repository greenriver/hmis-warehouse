# The core app (or other drivers) can check the presence of the
# CasCeData driver with the following code snippet
#
#   do_something if RailsDrivers.loaded.include(:cas_ce_data)
#
# use with caution!
RailsDrivers.loaded << :cas_ce_data

GrdaWarehouse::Synthetic.add_event_type('CasCeData::Synthetic::Event')
GrdaWarehouse::Synthetic.add_event_type('CasCeData::Synthetic::Assessment')
