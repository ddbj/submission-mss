import { fn } from '@ember/helper';
import { on } from '@ember/modifier';
import { LinkTo } from '@ember/routing';
import { t } from 'ember-intl';
import pageTitle from 'ember-page-title/helpers/page-title';

import ErrorMessage from 'mssform/components/error-message';

import type { TOC } from '@ember/component/template-only';
import type ApplicationController from 'mssform/controllers/application';

interface Signature {
  Args: {
    controller: ApplicationController;
  };
}

<template>
  {{pageTitle (t "application.title")}}

  <nav class="navbar navbar-expand navbar-dark bg-dark">
    <div class="container">
      <LinkTo @route="index" class="navbar-brand">{{t "application.title"}}</LinkTo>

      <div class="navbar-collapse" id="navbarNav">
        <ul class="navbar-nav ms-auto">
          <li class="nav-item">
            <div class="btn-group btn-group-sm my-1" role="group" aria-label="{{t 'application.language'}}">
              <button
                type="button"
                class="btn {{if (isLocale @controller 'ja') 'btn-light' 'btn-outline-light'}}"
                {{on "click" (fn @controller.changeLocale "ja")}}
              >{{t "application.locale.ja"}}</button>

              <button
                type="button"
                class="btn {{if (isLocale @controller 'en') 'btn-light' 'btn-outline-light'}}"
                {{on "click" (fn @controller.changeLocale "en")}}
              >{{t "application.locale.en"}}</button>
            </div>
          </li>
        </ul>
      </div>
    </div>
  </nav>

  <div class="container">
    {{outlet}}
  </div>

  <div class="modal fade" tabindex="-1" {{@controller.setErrorModal}}>
    <div class="modal-dialog modal-dialog-centered modal-dialog-scrollable">
      <div class="modal-content">
        <div class="modal-header">
          <h5 class="modal-title">Error</h5>
          <button type="button" class="btn-close" data-bs-dismiss="modal" aria-label="Close"></button>
        </div>

        <div class="modal-body">
          {{#if @controller.error}}
            <ErrorMessage @error={{@controller.error}} />
          {{/if}}
        </div>
      </div>
    </div>
  </div>
</template> satisfies TOC<Signature>;

function isLocale(controller: ApplicationController, locale: string) {
  return controller.locale === locale;
}
