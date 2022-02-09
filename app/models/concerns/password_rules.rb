###
# Copyright 2016 - 2022 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

module PasswordRules
  extend ActiveSupport::Concern
  include ActionView::Helpers::TextHelper

  def password_rules
    @password_rules ||= begin
      rules = []
      rules += password_expiration_rules
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

  private def password_expiration_rules
    # if false, passwords don't expire
    # if true, passwords can be expired, but it must be done by calling `user.need_password_change!`
    return [] if [true, false].include?(Devise.expire_password_after)

    note = "Passwords expire every #{pluralize(password_expiration_in_days, 'day')}"
    note += "; your password was last changed #{pluralize((Date.current - password_changed_at.to_date).to_i, 'day')} ago" if password_changed_at.present?
    [note]
  end

  private def password_expiration_in_days
    Devise.expire_password_after.to_i / 60 / 60 / 24
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

    rules << 'Passwords cannot contain three or more sequential letters or numbers (abc, 432, etc.)' if password_sequential_characters_enforced?

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

  private def password_sequential_characters_enforced?
    ENV['PASSWORD_SEQUENTIAL_CHARACTERS_ENFORCED'] == 'true'
  end

  private def password_cannot_be_sequential
    return false unless password_sequential_characters_enforced? && changing_password?
    return unless sequential?(password) || repeating?(password)

    errors.add(:password, 'has a sequential set of characters or digits')
  end

  # Returns true if the password contains sequential characters or numbers, forward or revers
  # No abcd, hgfe, 5432, or 6789
  private def sequential?(password)
    return false unless password.present?

    count = 3
    regex = Regexp.new(/(?:(?:0(?=1)|1(?=2)|2(?=3)|3(?=4)|4(?=5)|5(?=6)|6(?=7)|7(?=8)|8(?=9)){#{count},}\d|(?:a(?=b)|b(?=c)|c(?=d)|d(?=e)|e(?=f)|f(?=g)|g(?=h)|h(?=i)|i(?=j)|j(?=k)|k(?=l)|l(?=m)|m(?=n)|n(?=o)|o(?=p)|p(?=q)|q(?=r)|r(?=s)|s(?=t)|t(?=u)|u(?=v)|v(?=w)|w(?=x)|x(?=y)|y(?=z)){#{count},}[a-z])/i)
    password.match?(regex) || password.reverse.match?(regex)
  end

  # Returns true if any characters repeat 4 or more times
  private def repeating?(password)
    return false unless password.present?

    count = 3
    regex = Regexp.new(/(.)\1{#{count},}/)
    password.match?(regex)
  end

  private def changing_password?
    changes&.keys&.include?('encrypted_password')
  end
end
