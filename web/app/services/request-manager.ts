import { Fetch, RequestManager } from '@warp-drive/core';
import { getOwner, setOwner } from '@ember/owner';

import AuthHandler from 'mssform/request-handlers/auth';
import BaseURLHandler from 'mssform/request-handlers/base-url';
import ErrorModalHandler from 'mssform/request-handlers/error-modal';
import JsonBodyHandler from 'mssform/request-handlers/json-body';

export default {
  create(args: object) {
    const owner = getOwner(args)!;

    const errorModalHandler = new ErrorModalHandler();
    setOwner(errorModalHandler, owner);

    const authHandler = new AuthHandler();
    setOwner(authHandler, owner);

    return new RequestManager().use([
      errorModalHandler,
      new JsonBodyHandler(),
      new BaseURLHandler(),
      authHandler,
      Fetch,
    ]);
  },
};
