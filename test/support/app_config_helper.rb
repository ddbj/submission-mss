module AppConfigHelper
  # Runs the block with config_for(:app) answering the given settings in place
  # of the ones the test environment reads.
  def with_app_config(**overrides, &)
    config = Rails.application.config_for(:app).tap {|c|
      overrides.each {|k, v| c[k] = v }
    }

    original_config_for = Rails.application.method(:config_for)

    Rails.application.stub :config_for, ->(name, **opts) { name == :app ? config : original_config_for.call(name, **opts) }, &
  end
end
