addEventListener('message', async ({ data: { file } }) => {
  try {
    const [errors, payload] = await parse(file);

    postMessage([errors.length ? errors : null, payload]);
  } catch (err) {
    console.error(err);

    postMessage([err.message, null]);
  }
});

// https://html.spec.whatwg.org/#email-state-(type=email)
const email_re =
  /^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$/;

class ParseError {
  constructor(severity, id, value) {
    this.severity = severity;
    this.id = id;
    this.value = value;
  }
}

async function parse(file) {
  const errors = [];
  const contactPerson = new ContactPerson();
  let holdDate = null;

  let inCommon;

  for await (const line of lines(file)) {
    const [entry, , , qualifier, value] = line.split('\t');

    if (entry) {
      inCommon = entry === 'COMMON';
    }

    if (inCommon) {
      switch (qualifier) {
        case 'contact':
          if (contactPerson.fullName) {
            errors.push(new ParseError('error', 'annotation-file-parser.duplicate-contact-person-information'));
            break;
          }

          contactPerson.fullName = value?.trim();
          break;
        case 'email': {
          const trimmedEmail = value?.trim();

          if (!email_re.test(trimmedEmail)) {
            errors.push(new ParseError('error', 'annotation-file-parser.invalid-email-address', value));
            break;
          }

          if (contactPerson.email) {
            errors.push(new ParseError('error', 'annotation-file-parser.duplicate-contact-person-information'));
            break;
          }

          contactPerson.email = trimmedEmail;
          break;
        }
        case 'institute':
          if (contactPerson.affiliation) {
            errors.push(new ParseError('error', 'annotation-file-parser.duplicate-contact-person-information'));
            break;
          }

          contactPerson.affiliation = value?.trim();
          break;
        case 'hold_date': {
          const m = value.match(/^(\d{4})(\d{2})(\d{2})$/);

          if (!m) {
            errors.push(new ParseError('error', 'annotation-file-parser.invalid-hold-date', value));
            break;
          }

          holdDate = m.slice(1).join('-');
          break;
        }
        default:
        // do nothing
      }
    } else {
      if (qualifier === 'locus_tag' && /^locus_/i.test(value)) {
        errors.push(new ParseError('warning', 'annotation-file-parser.temporary-locus-tag', value));
      }
    }
  }

  const hasErrors = errors.some((e) => e.severity === 'error');

  if (!hasErrors) {
    if (contactPerson.isBlank) {
      errors.push(new ParseError('error', 'annotation-file-parser.missing-contact-person'));
    } else if (!contactPerson.isFulfilled) {
      errors.push(new ParseError('error', 'annotation-file-parser.invalid-contact-person'));
    }
  }

  return [errors, hasErrors ? null : { contactPerson, holdDate }];
}

async function* lines(file) {
  const reader = file.stream().pipeThrough(new TextDecoderStream()).getReader();

  let pending = '';

  for (let { value, done } = await reader.read(); !done; { value, done } = await reader.read()) {
    const parts = (pending + value).split(/\r\n|\n|\r/);

    pending = parts.pop();

    yield* parts;
  }

  if (pending) {
    yield pending;
  }
}

class ContactPerson {
  get isFulfilled() {
    return this.fullName && this.email && this.affiliation;
  }

  get isBlank() {
    return !this.fullName && !this.email && !this.affiliation;
  }
}
