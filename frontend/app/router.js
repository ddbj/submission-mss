import EmberRouter from '@ember/routing/router';
import config from 'mssform-web/config/environment';

export default class Router extends EmberRouter {
  location = config.locationType;
  rootURL = config.rootURL;
}

Router.map(function () {
  this.route('auth', function () {
    this.route('callback');
  });

  this.route('submissions', function () {
    this.route('new');
  });
});
