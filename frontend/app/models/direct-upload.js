import { BlobRecord } from "@rails/activestorage/src/blob_record"
import { BlobUpload } from "@rails/activestorage/src/blob_upload"

let id = 0

export class DirectUpload {
  constructor(file, url, delegate, checksum) {
    this.id = ++id
    this.file = file
    this.url = url
    this.delegate = delegate
    this.checksum = checksum
  }

  async create(callback) {
    const blob = new BlobRecordWithError(this.file, await this.checksum, this.url)
    notify(this.delegate, "directUploadWillCreateBlobWithXHR", blob.xhr)

    blob.create(error => {
      if (error) {
        callback(error)
      } else {
        const upload = new BlobUploadWithError(blob)
        notify(this.delegate, "directUploadWillStoreFileWithXHR", upload.xhr)
        upload.create(error => {
          if (error) {
            callback(error)
          } else {
            callback(null, blob.toJSON())
          }
        })
      }
    })
  }
}

function notify(object, methodName, ...messages) {
  if (object && typeof object[methodName] == "function") {
    return object[methodName](...messages)
  }
}

export class UploadError extends Error {
  constructor(_, target) {
    super(...arguments)

    this.target = target
  }

  get status() {
    return this.target.xhr.status
  }
}

class BlobRecordWithError extends BlobRecord  {
  requestDidError() {
    this.callback(new UploadError(`Error creating Blob for "${this.file.name}". Status: ${this.xhr.status}`, this))
  }
}

class BlobUploadWithError extends BlobUpload {
  requestDidError() {
    this.callback(new UploadError(`Error storing "${this.file.name}". Status: ${this.xhr.status}`, this))
  }
}
