import { action } from '@ember/object';
import { tracked } from '@glimmer/tracking';

export default class FileSet {
  @tracked files = [];

  @action add(file) {
    this.files = [...this.files, file];
  }

  @action remove(file) {
    this.files = this.files.filter(f => f !== file);
  }
}
