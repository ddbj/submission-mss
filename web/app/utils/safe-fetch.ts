import type ErrorModalService from 'mssform/services/error-modal';

export default async function safeFetch(url: RequestInfo | URL, init?: RequestInit) {
  const res = await fetch(url, init);

  if (!res.ok) throw new FetchFailed(res);

  return res;
}

export async function safeFetchWithModal(
  url: RequestInfo | URL,
  init: RequestInit | undefined,
  modal: ErrorModalService,
) {
  const res = await fetch(url, init);

  if (!res.ok) modal.show(new FetchFailed(res));

  return res;
}

export class FetchFailed extends Error {
  response: Response;

  constructor(res: Response) {
    super(res.statusText);

    this.response = res;
  }
}
