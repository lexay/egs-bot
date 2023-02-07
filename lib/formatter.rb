module EGS
  class Formatter
    def self.format(new_games:, template: DefaultTemplate)
      template.new(new_games)
    end
  end
end
