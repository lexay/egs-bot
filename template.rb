require 'time'

module Template
  class << self
    def new(games)
      a_game = games.first
      text = "Текущая раздача от ЕГС с #{format a_game.start_date} по #{format a_game.end_date}:\n\n"

      games.each do |game|
        message = <<~MESSAGE
          <strong>Название:</strong> <a href='#{game.game_uri}'>#{game.title}</a>

          <strong>Издатель / Разработчик:</strong> #{game.pubs_n_devs}

          <strong>Описание:</strong>
          #{game.short_description.length < 10 ? game.full_description : game.short_description}
          <a href='#{game.game_uri}'>...</a>

        MESSAGE
        text << message
      end
      text
    end

    def format(date)
      day = date.strftime('%-d')
      month_idx = date.strftime('%m').to_i - 1
      month = %w[января февраля марта апреля мая июня июля августа сентября октября ноября декабря][month_idx]
      "#{day} #{month}"
    end
  end
end
