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

const CONTACT_PERSON_QUALIFIERS = ['contact', 'email', 'institute'];

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
    const [entry, , , qualifier, rawValue] = line.split('\t');

    // The same whitespace as the server's parser strips, so that the two agree
    // on what is blank.
    const value = rawValue?.replace(/^[\s\u0085]+|[\s\u0085]+$/g, '') || undefined;

    if (entry) {
      inCommon = entry === 'COMMON';
    }

    // Templates, and DFAST jobs run without metadata, leave the contact
    // person's qualifiers with no value. Such a line says no more than a
    // missing one would.
    if (!value && CONTACT_PERSON_QUALIFIERS.includes(qualifier)) continue;

    if (inCommon) {
      switch (qualifier) {
        case 'contact':
          if (contactPerson.fullName) {
            errors.push(new ParseError('error', 'annotation-file-parser.duplicate-contact-person-information'));
            break;
          }

          contactPerson.fullName = value;
          break;
        case 'email':
          if (!email_re.test(value)) {
            errors.push(new ParseError('error', 'annotation-file-parser.invalid-email-address', value));
            break;
          }

          if (contactPerson.email) {
            errors.push(new ParseError('error', 'annotation-file-parser.duplicate-contact-person-information'));
            break;
          }

          contactPerson.email = value;
          break;
        case 'institute':
          if (contactPerson.affiliation) {
            errors.push(new ParseError('error', 'annotation-file-parser.duplicate-contact-person-information'));
            break;
          }

          contactPerson.affiliation = value;
          break;
        case 'hold_date':
          // A blank or impossible date is not taken for none: that would publish
          // the data as soon as it is accepted, which cannot be taken back.
          holdDate = parseHoldDate(value);

          if (!holdDate) {
            errors.push(new ParseError('error', 'annotation-file-parser.invalid-hold-date', value));
          } else if (holdDate < today()) {
            // Allowed, but most likely not meant: the data is published as soon
            // as it has been processed.
            errors.push(new ParseError('warning', 'annotation-file-parser.past-hold-date', value));
          }

          break;
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

// YYYYMMDD, of a day that exists, as YYYY-MM-DD.
function parseHoldDate(value) {
  const m = value?.match(/^(\d{4})(\d{2})(\d{2})$/);

  if (!m) return null;

  const [, year, month, day] = m.map(Number);
  const date = new Date(0);

  date.setUTCFullYear(year, month - 1, day);

  if (date.getUTCFullYear() !== year || date.getUTCMonth() !== month - 1 || date.getUTCDate() !== day) return null;

  return m.slice(1).join('-');
}

// Today as YYYY-MM-DD, in Japan wherever the submitter is: DDBJ, and the server
// that checks imported files, count days there. Japan keeps UTC+9 all year, so
// shifting the clock is enough -- and, unlike a locale's date format, cannot
// change under us.
function today() {
  return new Date(Date.now() + 9 * 60 * 60 * 1000).toISOString().slice(0, 10);
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
