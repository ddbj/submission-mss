import Component from '@glimmer/component';

import { AnnotationFile, SequenceFile } from 'mssform/models/submission-file';

export default class SupportedFileTypes extends Component {
  extensions = {
    annotation: AnnotationFile.extensions,
    sequence:   SequenceFile.extensions
  };
}
