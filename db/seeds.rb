###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

###
# 🚨🚨 WARNING:
# db:seed is called on every deploy. This seed script will be run on
# production. Ensure operations are idempotent. Seeds for testing or
# development should be conditional on Rails.env or equiv.
###

require_relative 'seed_maker'

SeedMaker.new.run_all
