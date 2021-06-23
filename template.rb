require 'time'

module Template
  class << self
    def new(games)
      text = String.new
      games.each do |game|

        message = <<~MESSAGE
          Текущая раздача от ЕГС с #{format game.start_date} по #{format game.end_date}:

          <strong>Название:</strong> #{game.title}

          <strong>Издатель / Разработчик:</strong> #{game.pubs_n_devs}

          <strong>Описание:</strong>
          #{game.short_description.length < 10 ? game.full_description : game.short_description}
          <a href='#{game.game_uri}'>...</a>
          \n
        MESSAGE
        text << message
      end
      text
    end

    def format(date)
      parsed_date = Time.parse(date)
      day = parsed_date.strftime('%-d')
      month_idx = parsed_date.strftime('%m').to_i - 1
      month = %w[января февраля марта апреля мая июня июля августа сентября октября ноября декабря][month_idx]
      "#{day} #{month}"
    end
  end
end
