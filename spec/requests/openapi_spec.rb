require 'rails_helper'

RSpec.describe 'OpenAPI Document', type: :request do
  example do
    expect(skooma_openapi_schema).to be_valid_document
  end
end
