require 'telegram/bot'
require 'dotenv/load'
require 'time'
require_relative 'sql_controller'


class EBot
  attr_reader :message, :db
  attr_reader :from_now, :upto_now, :description_now, :game_uris_now, :titles_now
  attr_reader :from_next, :upto_next, :description_next, :game_uris_next, :titles_next

  def initialize
    @bot = Telegram::Bot::Client.new(ENV['T_TOKEN'])
    @message = nil

    controller = DBController.new
    db_info_now = DBController.instance_methods(false)
                              .select { |m| m[/_db_/] }.sort
                              .map { |m| controller.method(m).call('now').flatten }

    @from_now, @upto_now, @description_now, @game_uris_now,
      @pictures_url_now, @timestamp_now, @titles_now = db_info_now

    db_info_next = DBController.instance_methods(false)
                               .select { |m| m[/_db_/] }.sort
                               .map { |m| controller.method(m).call('soon').flatten }

    @from_next, @upto_next, @description_next, @game_uris_next,
      @pictures_url_next, @timestamp, @titles_next = db_info_next
  end

  def bot_runner
    @bot.run do |current_bot|
      current_bot.listen do |current_message|
        @message = current_message
        mini_logger(current_message)
        commands
      end
    end
  end

  def commands
    method_name = %w[now soon help text].find do |command|
      message.text == '/' + command
    end

    method_name.nil? ? command_missing : self.method(method_name).call
  end

  def message_sender(**args)
    chat_id = args[:chat_id] || message.chat.id
    @bot.api.send_message(**args, chat_id: chat_id, parse_mode: 'HTML')
  end

  def command_missing
    message_sender(text: "#{message.from.first_name}, не понял команду ! Повторите!")
    help
  end

  def now
    from_to_now = time_convert(from_now, upto_now)
    template = text_prepare(titles_now, game_uris_now, from_to_now, description_now)
    complete_message = text_format(template, 'текущую')
    message_sender(text: complete_message, disable_web_page_preview: true)
  end

  def soon
    from_to_next = time_convert(from_next, upto_next)
    template = text_prepare(titles_next, game_uris_next, from_to_next, description_next)
    complete_message = text_format(template, 'следующую')
    message_sender(text: complete_message, disable_web_page_preview: true)
  end

  def text
    str = File.new('./full_description', 'r').read
    str.gsub!(/^\*\*(.+)\*\*/, '<strong>\1</strong>')
    str.gsub!(/^#\s(.+)/, '<strong>\1</strong>')
    str.gsub!(/^(-.+)$/, '\1' + "\n")
    str.gsub!(/^!?\[.*\]\(.*\)/, '')
    message_sender(text: str)
  end

  def time_convert(*dates)
    to_msk = proc { |str| (Time.parse(str) + 60 * 60 * 3).strftime('%d/%m/%Y %H:%M MSK') }
    from, upto = dates.map { |date| date.map(&to_msk) }
    [from, upto].transpose.map { |e| e.join(' - ') }
  end

  def text_prepare(titles, game_uris, from_to, description)
    titles.map.with_index do |title, i|
      "<b>Название:</b> <a href='#{game_uris[i]}'>#{title}</a>\n\n"\
        "<b>Доступно:</b> #{from_to[i]}\n\n"\
        "<b>Описание:</b>\n\n#{description[i]}\n"
    end
  end

  def text_format(template, week)
    <<~MESSAGE
      <strong>А вот и список на #{week} неделю:</strong>\n
      #{template.join("\n")}
    MESSAGE
  end

  def help
    message_sender(text: help_message)
  end

  def help_message
    <<~MESSAGE
      <strong>Команды:</strong>

      /help - справочная информация (это меню)
      /now - релизы текущей недели
      /soon - релизы следующей недели
    MESSAGE
  end

  def mini_logger(current_message)
    puts "Username: #{current_message.from.username}, Command: #{current_message.text}"
    puts "Date: #{Time.at(current_message.date)}"
  end
end

EBot.new.bot_runner
# p EBot.new.message
# Bot name: epic_4f_bot

# e = EBot.new
#
# DBController.instance_methods(false)[1..-1].each do |m|
#   e.set_instance_variable(('@' << m.to_s[/[a-z]+_[a-z]/]).to_sym, e.db.method(m).call)
# end
#
# e.bot_runner

# def timezone_set(message_date)
#   tz = Time.at(message_date).strftime('%:z').split(':').map(&:to_i).reverse
#   tz.map.with_index { |t, i| t * (60**(i + 1)) }.reduce(:+)
# end
#
# def show...
  # from = avail_from.map { |e| Time.parse(e) + timezone_set(message.date) }
  #   .map { |e| e.strftime('%d/%m/%Y %H:%M') }
  # upto = avail_upto.map { |e| Time.parse(e) + timezone_set(message.date) }
  #   .map { |e| e.strftime('%d/%m/%Y %H:%M') }
# end

# Ratings
# Remove urls from titles, add them to titles instead.

# location = Telegram::Bot::Types::KeyboardButton.new(text: 'Gimme your location', request_location: true)
# markup = Telegram::Bot::Types::ReplyKeyboardMarkup.new(keyboard: location)
# @bot.api.send_message(chat_id: message.chat.id, text: 'Whatup', reply_markup: markup)

# p pictures_url_now.first[/[^?]+/]
# @bot.api.send_photo(media: pictures_url_now.first[/[^?]+/])
