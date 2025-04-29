import Component from '@glimmer/component';
import { action } from '@ember/object';
import { service } from '@ember/service';

import type RequestService from 'mssform/services/request';
import type Submission from 'mssform/models/submission';
import type UploadProgressModalComponent from 'mssform/components/upload-progress-modal';
import type { Navigation } from 'mssform/components/submission-form';
import type SubmissionFile from 'mssform/models/submission-file';

interface Signature {
  Args: {
    state: {
      files: SubmissionFile[];
    };

    model: Submission;
    nav: Navigation;
  };
}

export default class SubmissionFormConfirmComponent extends Component<Signature> {
  @service declare request: RequestService;

  @action async submit(uploadProgressModal: UploadProgressModalComponent) {
    const { state, model, nav } = this.args;
    const { uploadVia } = model;

    if (uploadVia === 'webui') {
      const blobs = await uploadProgressModal.performUpload(state.files);

      model.files = blobs.map(({ signed_id }) => signed_id);
    }

    const res = await this.request.fetch('/submissions', {
      method: 'POST',

      headers: {
        'Content-Type': 'application/json',
      },

      body: JSON.stringify({
        submission: {
          tpa: model.tpa,
          upload_via: model.uploadVia,
          files: model.files,
          extraction_id: model.extractionId,
          entries_count: model.entriesCount,
          hold_date: model.holdDate,
          sequencer: model.sequencer,
          data_type: model.dataType,
          description: model.description,
          email_language: model.emailLanguage,

          contact_person: {
            email: model.contactPerson.email,
            full_name: model.contactPerson.fullName,
            affiliation: model.contactPerson.affiliation,
          },

          other_people: model.otherPeople.map((person) => {
            return {
              email: person.email,
              full_name: person.fullName,
            };
          }),
        },
      }),
    });

    const { id } = ((await res.json()) as { submission: { id: string } }).submission;

    model.id = id;

    nav.goNext();
  }
}
