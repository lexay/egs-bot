module EGS
  class Formatter
    def self.format(games:, template: DefaultTemplate)
      template.new(games)
    end
  end
end
