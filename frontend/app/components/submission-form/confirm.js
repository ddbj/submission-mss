import Component from '@glimmer/component';
import { action } from '@ember/object';
import { service } from '@ember/service';

export default class SubmissionFormConfirmComponent extends Component {
  @service session;

  @action async submit(uploadProgressModal) {
    const {state, model, nav} = this.args;

    const blobs = await uploadProgressModal.performUpload(state.files);
    model.files = blobs.map(({signed_id}) => signed_id);

    await this.session.renewToken();
    await model.save();

    nav.goNext();
  }
}
