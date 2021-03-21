require 'time'

module Template
  class << self
    def make(games)
      text = String.new
      games.each do |game|
        availability = game.available == 'now' ? 'Текущая' : 'Следующая'

        message = <<~MESSAGE
          #{availability} раздача от ЕГС с #{format game.start_date} по #{format game.end_date}:

          <strong>Название:</strong> <a href='#{game.game_uri}'>#{game.title}</a>

          <strong>Издатель / Разработчик:</strong> #{game.pubs_n_devs}

          <strong>Описание:</strong>
          #{game.short_description}
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
