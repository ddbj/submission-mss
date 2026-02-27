import { fn, concat } from '@ember/helper';
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
          <li class="nav-item dropdown">
            <a
              class="nav-link dropdown-toggle"
              href="#"
              id="navbarLang"
              role="button"
              data-bs-toggle="dropdown"
              aria-expanded="false"
            >
              {{t "application.language"}}:
              {{t (concat "application.locale." @controller.locale)}}
            </a>

            <ul class="dropdown-menu" aria-labelledby="navbarLang">
              <li>
                <button type="button" class="dropdown-item" {{on "click" (fn @controller.changeLocale "ja")}}>{{t
                    "application.locale.ja"
                  }}</button>
                <button type="button" class="dropdown-item" {{on "click" (fn @controller.changeLocale "en")}}>{{t
                    "application.locale.en"
                  }}</button>
              </li>
            </ul>
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
