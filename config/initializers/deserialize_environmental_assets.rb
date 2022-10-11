Rails.application.reloader.to_prepare do
  # This is a way to have assets in the asset pipeline that are different per environment
  SerializedAsset.init
end
