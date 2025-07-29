Rails.application.config.after_initialize do
  enums = YAML.load_file(Rails.root.join('config/enums.yml')).deep_symbolize_keys

  enums.fetch(:locales).each do |locale|
    key, label = locale.fetch_values(:key, :label)

    %i[en ja].each do |locale|
      I18n.backend.store_translations locale, mssform: {
        locales: {
          key => label.fetch(locale)
        }
      }
    end
  end

  enums.fetch(:data_types).each do |type|
    key, label, ddbj_page_url = type.fetch_values(:key, :label, :ddbj_page_url)

    %i[en ja].each do |locale|
      I18n.backend.store_translations locale, mssform: {
        data_types: {
          key => label
        },

        data_type_ddbj_page_urls: {
          key => ddbj_page_url.fetch(locale)
        }
      }
    end
  end

  enums.fetch(:sequencers).each do |sequencer|
    key, label = sequencer.fetch_values(:key, :label)

    %i[en ja].each do |locale|
      I18n.backend.store_translations locale, mssform: {
        sequencers: {
          key => label
        }
      }
    end
  end
end
