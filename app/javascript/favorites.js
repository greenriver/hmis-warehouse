import FavoriteController from './controllers/favorite_controller.js'

// This file is a specific entrypoint for the favorites manager.
// It assumes that `window.application` has been initialized by `application_esbuild.js`
if (window.Stimulus) {
  window.Stimulus.register("favorite", FavoriteController)
}
