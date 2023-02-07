module EGS
  class DefaultTemplate
    def self.new(games)
      info = ''
      expiration_date = ''

      show_idx = ->(idx) { format('%i. ', idx + 1) }
      show_no_idx = proc { '' }
      game_idx = games.count > 1 ? show_idx : show_no_idx

      games.each_with_index do |game, idx|
        header = I18n.t(:header, start_date: stringify(game.start_date), end_date: stringify(game.end_date))
        header = '' if expiration_date == game.end_date
        expiration_date = game.end_date
        info << header << game_idx.call(idx) << message(game)
      end
      info << banned_message
    end

    def self.stringify(date)
      day = date.strftime('%-d')
      month_idx = date.strftime('%m').to_i
      month = I18n.t(:month_names)[month_idx]
      "#{day} #{month}"
    end

    def self.message(game)
      <<~MESSAGE
        #{I18n.t(:title)}: #{game.title}

        #{I18n.t(:devs)}: #{[game.publisher, game.developer].compact.uniq.join(' - ')}

        #{I18n.t(:description)}:
        #{game.description.truncate(300, separator: '.')}

      MESSAGE
    end

    def self.banned_message
      I18n.t(:banned_message)
    end
  end

  class TelegramTemplate < DefaultTemplate
    def self.message(game)
      <<~MESSAGE
        <strong>#{I18n.t(:title)}:</strong> <a href="#{game.uri}">#{game.title}</a>

        <strong>#{I18n.t(:devs)}:</strong> #{[game.publisher, game.developer].compact.uniq.join(' - ')}

        <strong>#{I18n.t(:description)}:</strong>
        #{game.description.truncate(300, separator: '.')}

      MESSAGE
    end
  end
end
