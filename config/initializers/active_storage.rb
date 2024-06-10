silence_warnings do
  OpenSSL::SSL::VERIFY_PEER = OpenSSL::SSL::VERIFY_NONE if Rails.env.development?
end
Rails.application.reloader.to_prepare do
  # ActiveStorage::Blob::INVALID_VARIABLE_CONTENT_TYPES_DEPRECATED_IN_RAILS_7 = ActiveStorage::Blob::INVALID_VARIABLE_CONTENT_TYPES_DEPRECATED_IN_RAILS_7 - ['image/bmp']
  class ActiveStorage::Blob
    types = remove_const(:INVALID_VARIABLE_CONTENT_TYPES_DEPRECATED_IN_RAILS_7) - ['image/bmp']
    INVALID_VARIABLE_CONTENT_TYPES_DEPRECATED_IN_RAILS_7 = types
  end
end
