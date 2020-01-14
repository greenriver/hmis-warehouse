require File.expand_path('../../lib/util/mail/database_delivery', __dir__)

ActionMailer::Base.add_delivery_method :db, Mail::DatabaseDelivery