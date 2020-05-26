Rails.logger.debug "Running initializer in #{__FILE__}"

# This is a way to have assets in the asset pipeline that are different per environment
SerializedAsset.init
