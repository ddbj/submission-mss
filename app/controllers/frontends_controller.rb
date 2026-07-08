class FrontendsController < ActionController::Base
  # Serve the pre-built SPA shell, injecting the runtime configuration that must
  # not be baked into the environment-agnostic build (so a single image can be
  # promoted across environments). The frontend reads these <meta> tags on boot.
  def show
    html = Rails.root.join('public/index.html').read
    meta = helpers.safe_join([
      helpers.tag.meta(name: 'sentry-dsn',         content: Rails.application.config_for(:app).sentry_dsn),
      helpers.tag.meta(name: 'sentry-environment', content: Rails.env)
    ])

    render html: html.sub('</head>', "#{meta}</head>").html_safe
  end
end
