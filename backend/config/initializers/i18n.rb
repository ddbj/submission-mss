Rails.application.config.after_initialize do
  enums = YAML.load_file(Rails.root.join('config/enums.yml')).deep_symbolize_keys

  enums[:data_types].each do |type, data|
    %i(en ja).each do |locale|
      I18n.backend.store_translations locale, mssform: {
        data_types: {
          type => data[:label]
        },
        data_type_ddbj_page_urls: {
          type => data[:ddbj_page_url][locale]
        }
      }
    end
  end
end
