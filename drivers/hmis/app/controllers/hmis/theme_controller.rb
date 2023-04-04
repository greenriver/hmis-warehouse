###
# Copyright 2016 - 2023 Green River Data Analysis, LLC
#
# License detail: https://github.com/greenriver/hmis-warehouse/blob/production/LICENSE.md
###

class Hmis::ThemeController < Hmis::BaseController
  skip_before_action :authenticate_user!
  prepend_before_action :skip_timeout

  # TODO: This is just placeholder pending other theming work, after which this should rolled in with that and be moved to the DB
  THEMES = {
    'christmas' => {
      palette: {
        primary: {
          main: "#00aa00"
        },
        secondary: {
          main: "#ff0000"
        },
      },
    },
    'halloween' => {
      palette: {
        mode: 'dark',
        common: {
          black: '#fff',
          white: '#000'
        },
        primary: {
          main: '#ff9900'
        },
        secondary: {
          main: "#00aa00"
        },
        background: {
          default: '#000',
          paper: '#333'
        }
      },
      components: {
        MuiOutlinedInput: {
          styleOverrides: {
            root: {
              backgroundColor: 'black',
            },
          },
        },
        MuiAppBar: {
          styleOverrides: {
            root: {
              backgroundColor: 'black !important'
            }
          }
        }
      }
    }
  }.freeze

  def index
    which_theme = params[:ds]
    render json: THEMES[which_theme] || {}
  end

  def list
    render json: THEMES.keys
  end
end
