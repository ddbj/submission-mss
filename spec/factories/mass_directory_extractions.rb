FactoryBot.define do
  factory :mass_directory_extraction do
    user
  end

  factory :mass_directory_extraction_file do
    extraction factory: :mass_directory_extraction

    parsing { false }
  end
end
