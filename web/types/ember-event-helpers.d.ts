declare module 'ember-event-helpers/helpers/prevent-default' {
  export default function preventDefault(handler: (...args: unknown[]) => unknown): (event: Event) => void;
}
