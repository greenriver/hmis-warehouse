###
# Copyright 2016 - 2019 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/master/LICENSE.md
###

module PasswordRules
  extend ActiveSupport::Concern
  include ActionView::Helpers::TextHelper

  def password_rules
    @password_rules ||= begin
      rules = []
      rules += password_length_rules
      rules += complexity_rules
      rules += password_reuse_rules
      rules += password_pwned_rules
      rules
    end
  end

  private def password_length_rules
    [
      "Passwords must be at least #{minimum_password_length} characters in length",
    ]
  end

  private def minimum_password_length
    Devise.password_length.first
  end

  private def complexity_rules
    rules = []
    Devise.password_complexity.each do |k, v|
      case k
      when :digit
        rules << "Passwords must contain at least #{pluralize(v, 'number')} (e.g., 1, 2, 3)"
      when :lower
        rules << "Passwords must contain at least #{pluralize(v, 'lower case letter')} (e.g., a, b, c)"
      when :symbol
        rules << "Passwords must contain at least #{pluralize(v, 'symbol')} (e.g., ‘, %, $, #)"
      when :upper
        rules << "Passwords must contain at least #{pluralize(v, 'upper case letter')}  (e.g., A, B, C)"
      end
    end
    rules
  end

  private def password_reuse_rules
    return [] if Devise.deny_old_passwords == false

    if Devise.deny_old_passwords == true
      [
        'Passwords cannot be reused',
      ]
    elsif Devise.deny_old_passwords == 1
      [
        'You cannot reuse your most recent password',
      ]
    else
      [
        "You cannot reuse any of the previous #{Devise.deny_old_passwords} passwords",
      ]
    end
  end

  private def password_pwned_rules
    [
      'Passwords that are included in a publicly available password list are not allowed',
    ]
  end
end
