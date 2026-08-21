import Component from '@glimmer/component';
import { getOwner } from '@ember/application';
import { service } from '@ember/service';
import { modifier } from 'ember-modifier';
import { tracked } from '@glimmer/tracking';

import ExtractedFiles from 'mssform/components/extracted-files';
import SubmissionFileItem from 'mssform/components/submission-file-item';
import Extraction from 'mssform/models/extraction';

import type { ExtractionPayload } from 'mssform/models/extraction';
import type ErrorModalService from 'mssform/services/error-modal';
import type { SubmissionFileData, SubmissionError } from 'mssform/models/submission-file';

export interface Signature {
  Args: {
    onPoll: (payload: ExtractionPayload) => void;
    crossoverErrors: Map<SubmissionFileData, SubmissionError[]>;
  };
}

export default class MassDirectoryExtractorComponent extends Component<Signature> {
  @service declare errorModal: ErrorModalService;

  @tracked files: SubmissionFileData[] = [];

  fetchFiles = modifier(() => {
    const abort = new AbortController();

    void (async () => {
      const extraction = await Extraction.create(getOwner(this)!, '/mass_directory_extractions');

      await extraction.pollForResult(
        (payload) => {
          this.files = payload.files;

          this.args.onPoll(payload);
        },
        (error) => {
          this.errorModal.show(new Error(error.reason ?? error.id));
        },
        abort.signal,
      );
    })().catch((e) => {
      if (e instanceof DOMException && e.name === 'AbortError') return;
      throw e;
    });

    return () => abort.abort();
  });

  <template>
    <div {{this.fetchFiles}} class="card">
      <ExtractedFiles @files={{this.files}} @crossoverErrors={{@crossoverErrors}} as |file errors|>
        <SubmissionFileItem @file={{file}} @errors={{errors}} />
      </ExtractedFiles>
    </div>
  </template>
}
