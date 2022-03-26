import Component from '@glimmer/component';
import { action } from '@ember/object';
import { service } from '@ember/service';

export default class SubmissionFormConfirmComponent extends Component {
  @service session;
  @service router;

  @action async submit(uploadProgressModal) {
    const {state, model, nav} = this.args;

    const blobs = await uploadProgressModal.performUpload(state.files);
    model.files = blobs.map(({signed_id}) => signed_id);

    if (!(await this.session.renewToken())) {
      alert('Your session has been expired. Please re-login.');

      this.router.transitionTo('index');
    }
    await model.save();

    nav.goNext();
  }
}
