import Component from '@glimmer/component';
import { A } from '@ember/array';
import { action } from '@ember/object';
import { service } from '@ember/service';
import { tracked } from '@glimmer/tracking';

class State {
  @tracked determinedByOwnStudy = null;
  @tracked submissionFileType   = null;
  @tracked files                = A([]);
  @tracked releaseImmediately   = true;
}

class Steps {
  names = [
    'prerequisite',
    'files',
    'metadata',
    'confirm',
    'submit'
  ];

  @tracked currentIndex = 0;

  get currentName() {
    return this.names[this.currentIndex];
  }

  @action goNext() {
    this.currentIndex = Math.min(this.currentIndex + 1, this.names.length);
  }

  @action goPrev() {
    this.currentIndex = Math.max(0, this.currentIndex - 1);
  }
}

export default class SubmissionFormComponent extends Component {
  @service router;
  @service session;

  state = new State();
  steps = new Steps();
}
