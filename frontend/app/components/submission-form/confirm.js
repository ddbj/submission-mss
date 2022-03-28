import Component from '@glimmer/component';
import { action } from '@ember/object';
import { service } from '@ember/service';

import {
  handleAdapterError,
  handleAppAuthHTTPError,
  handleUploadError
} from 'mssform/utils/error-handler';

export default class SubmissionFormConfirmComponent extends Component {
  @service session;

  @action async submit(uploadProgressModal) {
    const {state, model, nav} = this.args;

    let blobs;

    try {
      blobs = await uploadProgressModal.performUpload(state.files);
    } catch (e) {
      handleUploadError(e, this.session);
      return;
    }

    model.files = blobs.map(({signed_id}) => signed_id);

    try {
      await this.session.renewToken();
    } catch (e) {
      handleAppAuthHTTPError(e, this.session);
      return;
    }

    try {
      await model.save();
    } catch (e) {
      handleAdapterError(e, this.session);
      return;
    }

    nav.goNext();
  }
}
