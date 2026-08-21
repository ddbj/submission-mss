require 'test_helper'

class DirectUploadsTest < ActionDispatch::IntegrationTest
  # Not described by the schema: the shape is Active Storage's own.
  def post_blob(headers: {})
    post '/api/direct_uploads', headers:, as: :json, params: {
      blob: {
        filename:     'test.ann',
        byte_size:    1,
        checksum:     Digest::MD5.base64digest('x'),
        content_type: 'text/plain'
      }
    }
  end

  test 'create without the token' do
    sign_in users(:alice)

    default_headers.delete 'X-CSRF-Token'

    # A plain form post from a sibling under ddbj.nig.ac.jp carries the cookie
    # and needs no preflight, so the token is all that stands between it and a
    # blob minted in this submitter's name.
    post_blob

    assert_response :unprocessable_content
    assert_equal 0, ActiveStorage::Blob.count
  end

  test 'create by nobody' do
    post_blob

    assert_response :unauthorized
  end
end
