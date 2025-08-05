###
# Copyright 2016 - 2025 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

# frozen_string_literal: true

# Be sure to restart your server when you modify this file.

# Version of your assets, change this if you want to expire all your assets.
Rails.application.config.assets.version = '1.0'

# Add additional assets to the asset load path.
# Rails.application.config.assets.paths << Emoji.images_path
# Add Yarn node_modules folder to the asset load path.
Rails.application.config.assets.paths << Rails.root.join('node_modules')

# Precompile additional assets.
# application.js, application.css, and all non-JS/CSS in the app/assets
# folder are already added.
# Rails.application.config.assets.precompile += %w( admin.js admin.css )
Rails.application.config.assets.precompile += ['bootstrap.min.js', 'popper.js']
Rails.application.config.assets.precompile += ['print.css']
Rails.application.config.assets.precompile += ['dashboard_pdf.css']
Rails.application.config.assets.precompile += ['roi_pdf.css']
Rails.application.config.assets.precompile += ['chart.js']
Rails.application.config.assets.precompile += ['pdf.js']
Rails.application.config.assets.precompile += ['theme/styles/*.css']
