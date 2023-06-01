import logging
from superset.security import SupersetSecurityManager

class DoorkeeperSsoSecurityManager(SupersetSecurityManager):
    def oauth_user_info(self, provider, response=None):
        logging.debug("Oauth2 provider: {0}.".format(provider))
        if provider == 'WarehouseSSO':
            # As example, this line request a GET to base_url + '/' + userDetails with Bearer  Authentication,
            # and expects that authorization server checks the token, and response with user details
            fluf = self.appbuilder.sm.oauth_remotes[provider].get('oauth/token/info')
            logging.debug("fluf: {0}".format(fluf))

            me = self.appbuilder.sm.oauth_remotes[provider].get('oauth/token/info').data
            logging.debug("user_data: {0}".format(me))
            return { 'name' : me['name'], 'email' : me['email'], 'id' : me['user_name'], 'username' : me['user_name'], 'first_name':'', 'last_name':''}
