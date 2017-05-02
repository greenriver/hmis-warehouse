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
