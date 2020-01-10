###
# Copyright 2016 - 2020 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module Talentlms
  class Facade

    def initialize
      @api = Config.first
    end

    # Login user to TalentLMS
    #
    # @@param user [User] the user
    # @return [String] URL to redirect user to
    def login(user)
      login = Login.find_by(user: user)
      if login.nil?
        result = create_account(user) if login.nil?
      else
        result = @api.post('userlogin', {login: login.login, password: password})
      end
      result['login_key']
    end

    # Create an account in TalentLMS for a user
    #
    # @param user [User] the user
    # @return [String] URL to redirect the user to to login
    def create_account(user)
      login = "user_#{user.id}"
      password = SecureRandom.hex(8)
      server_domain = ENV['HOSTNAME']
      account = {
        first_name: user.first_name,
        last_name: user.last_name,
        email: "#{login}@#{server_domain}",
        login: login,
        password: password,
        restrict_email: 'on',
      }
      result = @api.post('usersignup', account)
      Login.create(user: user, login: login, password: password)

      result['login_key']
    end
  end
end