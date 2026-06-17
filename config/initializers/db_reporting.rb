###
# Copyright Green River Data Group, Inc.
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

DB_REPORTING = YAML.load(ERB.new(File.read(Rails.root.join("config","database.yml"))).result, aliases: true)[Rails.env]['reporting']
