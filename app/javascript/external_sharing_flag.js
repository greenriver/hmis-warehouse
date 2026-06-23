import { application } from './controllers/application';
import ExternalSharingFlagController from './controllers/external_sharing_flag_controller.js';

if (window.Stimulus) {
  window.Stimulus.register('external-sharing-flag', ExternalSharingFlagController)
}

application.register('external-sharing-flag', ExternalSharingFlagController);
