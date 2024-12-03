module EGS
  class DefaultTemplate
    def self.new(games)
      message = ''
      prev_game_end_date = nil

      games.each_with_index do |g, i|
        next_game_end_date = g.end_date.to_date
        header =
          if prev_game_end_date == next_game_end_date
            ''
          else
            I18n.t(:header, start_date: stringify(g.start_date),
                            end_date: stringify(g.end_date))
          end
        game_idx = games.count == 1 ? '' : "#{i + 1}. "
        message << header << game_idx << describe(g)
        prev_game_end_date = next_game_end_date
      end
      message << I18n.t(:banned_message)
    end

    def self.stringify(date)
      day = date.strftime('%-d')
      month_idx = date.strftime('%m').to_i
      month = I18n.t(:month_names)[month_idx]
      "#{day} #{month}"
    end

    def self.describe(game)
      <<~INFO
        #{I18n.t(:title)}: #{game.title}

      INFO
    end
  end

  class TelegramTemplate < DefaultTemplate
    def self.describe(game)
      <<~INFO
        <a href="#{game.uri}">#{game.title}</a>

      INFO
    end
  end
end
