class ExtractionError < StandardError
  def initialize(id, **data)
    @id   = id
    @data = data
  end

  attr_reader :id, :data
end
