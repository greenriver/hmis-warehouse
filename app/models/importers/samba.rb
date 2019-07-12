###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

# Current locations
# NECHV - /mnt/hmis/nechv
# BPHC - /mnt/hmis/bphc
# DND - /mnt/hmis/dnd
# MA - /mnt/hmis/ma
require 'zip'
require 'csv'
require 'charlock_holmes'
require 'faker'
require 'newrelic_rpm'
# require 'temping'
# Work around a faker bug: https://github.com/stympy/faker/issues/278
I18n.reload!

module Importers
  class Samba < Base
    
  end
end
