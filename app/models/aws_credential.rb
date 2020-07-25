class AwsCredential < ApplicationRecord
  belongs_to :user
  VALID_IDENT = /\A[a-z0-9+-=.@-]{6,64}+\z/i
  INVALID_CHARS = /[^a-z0-9+-=.@-]/i

  validates :account_id, presence: {strict: true}
  validates :username, format: { with: VALID_IDENT, strict: true, message: "must match #{VALID_IDENT.to_s}" }
  validates :access_key_id, presence: {strict: true}
  validates :secret_access_key, presence: {strict: true}

  attr_encrypted :secret_access_key, key: ENV['ENCRYPTION_KEY'][0..31], encode: false, encode_iv: false

  def default_username!
    self.username ||= user.email.downcase.gsub(INVALID_CHARS,'')[0,64]
  end


  def arn
    "arn:aws:iam::#{account_id}:user/#{username}"
  end

  before_validation :default_username!
  before_save :default_username!
end
