require 'time'

module Template
  class << self
    def new(games)
      a_game = games.first
      text = "Текущая раздача от ЕГС с #{stringify a_game.start_date} по #{stringify a_game.end_date}:\n\n"

      games.each_with_index do |game, idx|
        game_idx = format('%i. ', idx + 1)
        message = <<~MESSAGE
          <strong>Название:</strong> <a href='#{game.game_uri}'>#{game.title}</a>

          <strong>Издатель / Разработчик:</strong> #{game.pubs_n_devs}

          <strong>Описание:</strong>
          #{game.short_description.length < 10 ? game.full_description : game.short_description}
          <a href='#{game.game_uri}'>...</a>

        MESSAGE
        text << game_idx << message
      end
      text
    end

    def stringify(date)
      day = date.strftime('%-d')
      month_idx = date.strftime('%m').to_i
      month = %w[января февраля марта апреля мая июня июля августа сентября октября ноября декабря][month_idx - 1]
      "#{day} #{month}"
    end
  end
end
