###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

# mailer that just adds rows to database -- cron job or some other mechanism will turn these into notifications of some sort
class DatabaseMailer < ApplicationMailer
  self.delivery_method = :db
  layout nil
end
