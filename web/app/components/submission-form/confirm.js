import Component from '@glimmer/component';
import { action } from '@ember/object';

export default class SubmissionFormConfirmComponent extends Component {
  @action async submit(uploadProgressModal) {
    const { state, model, nav } = this.args;
    const { uploadVia } = model;

    if (uploadVia === 'webui') {
      const blobs = await uploadProgressModal.performUpload(state.files);

      model.files = blobs.map(({ signed_id }) => signed_id);
    }

    await model.save();

    nav.goNext();
  }
}
