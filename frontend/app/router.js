import EmberRouter from '@ember/routing/router';
import config from 'mss-form-web/config/environment';

export default class Router extends EmberRouter {
  location = config.locationType;
  rootURL = config.rootURL;
}

Router.map(function () {
  this.route('submissions', function () {
    this.route('new');
  });
});
