# mailer that just adds rows to database -- cron job or some other mechanism will turn these into notifications of some sort
class DatabaseMailer < ApplicationMailer
  self.delivery_method = :db
  layout nil
end
