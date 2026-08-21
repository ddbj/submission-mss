import Component from '@glimmer/component';
import { action } from '@ember/object';
import { service } from '@ember/service';

import { t } from 'ember-intl';
import { task } from 'ember-concurrency';

import FileChooser from 'mssform/components/file-chooser';
import leavingConfirmation from 'mssform/modifiers/leaving-confirmation';
import OtherPerson from 'mssform/models/other-person';

import type { paths } from 'schema/openapi';
import type Submission from 'mssform/models/submission';
import type { Navigation, State } from 'mssform/components/submission-form';
import type { RequestManager } from '@warp-drive/core';

export interface Signature {
  Args: {
    model: Submission;
    state: State;
    nav: Navigation;
  };
}

export default class SubmissionFormFilesComponent extends Component<Signature> {
  @service declare requestManager: RequestManager;

  @action handleSubmit(event: Event) {
    event.preventDefault();
    void this.goNext.perform();
  }

  goNext = task({ drop: true }, async () => {
    await this.fillDataFromLastSubmission();
    this.fillDataFromSubmissionFiles();

    this.args.nav.goNext();
  });

  async fillDataFromLastSubmission() {
    type LastSubmitted = paths['/submissions/last_submitted']['get']['responses']['200']['content']['application/json'];

    let last: LastSubmitted['submission'] | undefined;

    try {
      const { content } = await this.requestManager.request<LastSubmitted>({
        url: '/submissions/last_submitted',
        options: { suppressErrorModal: true },
      });

      last = content.submission;
    } catch {
      // do nothing
    }

    if (!last) return;

    const { model } = this.args;

    model.contactPerson.email = last.contact_person.email;
    model.contactPerson.fullName = last.contact_person.full_name;
    model.contactPerson.affiliation = last.contact_person.affiliation;

    model.otherPeople = last.other_people.map(({ email, full_name }) => {
      const person = new OtherPerson();

      return Object.assign(person, { email, fullName: full_name });
    });

    if (!model.sequencer) {
      model.sequencer = last.sequencer;
    }

    if (!model.emailLanguage) {
      model.emailLanguage = last.email_language;
    }
  }

  fillDataFromSubmissionFiles() {
    const { state, model } = this.args;
    const { files } = state.selection;

    const annotationFile = files.find((file) => file.fileType === 'annotation');

    const { contactPerson, holdDate } = annotationFile?.parsedData ?? {};

    Object.assign(model.contactPerson, contactPerson ?? {});

    model.holdDate = holdDate ?? undefined;

    model.entriesCount = files
      .filter((file) => file.fileType === 'sequence')
      .reduce((acc, file) => {
        return acc + (file.parsedData?.entriesCount ?? 0);
      }, 0);
  }

  <template>
    <form {{on "submit" this.handleSubmit}} {{leavingConfirmation}}>
      <FileChooser @selection={{@state.selection}}>
        <:question>{{t "submission-form.files.q-html" htmlSafe=true}}</:question>
        <:instructions>{{t "submission-form.files.instructions-html" htmlSafe=true}}</:instructions>
      </FileChooser>

      <hr />

      <div class="hstack gap-3 justify-content-end">
        <button type="button" class="btn btn-outline-primary px-4" {{on "click" @nav.goPrev}}>
          {{t "submission-form.nav.back"}}
        </button>

        <button
          type="submit"
          class="btn btn-primary px-5"
          disabled={{not (and @state.selection.isSubmittable this.goNext.isIdle)}}
        >{{t "submission-form.nav.next"}}</button>
      </div>
    </form>
  </template>
}
