module EGS
  class Schedule
    include BotHelper
    include GameHelper
    include TimeHelper

    def run
      Thread.new do
        loop do
          prepare_new_release
          serve_games_to_users
          wait 'next_release'
        end
      end
    end

    private

    def prepare_new_release
      current_games = query_release.free_games
      return EGS::LOG.info('No new release yet! Skipping...') if fetch_time_left(current_games).positive?

      new_games = EGS::Promotion::Scraper.run
      return EGS::LOG.info('No games! Skipping...') if new_games.empty?
      return EGS::LOG.info('New games can not have expired date! Skipping...') if fetch_time_left(new_games).negative?

      if current_games == new_games
        current_games.each { |game| game.update(end_date: new_games.last.end_date) }
        EGS::LOG.info('Old release has been prolongated!')
      else
        new_release = EGS::Models::Release.init
        new_games.map { |game| game.release_id = new_release.id }
        store(new_games)
      end
    end

    def store(games)
      games.each(&:save)
      EGS::LOG.info 'Games have been successfully saved to Database!'
    end

    def serve_games_to_users
      current_release = query_release

      chat_ids = current_release.chat_ids_not_served
      return EGS::LOG.info 'No release has ever been created!' if chat_ids.nil?

      chat_ids = JSON.parse(chat_ids)
      return EGS::LOG.info 'No queued users! Skipping...' if chat_ids.empty?

      dispatch(format(current_release.free_games), chat_ids)
    end

    def dispatch(games, chat_ids)
      chat_ids.reverse_each do |chat_id|
        send_message(games, chat_id)
        EGS::LOG.info "Games have been dispatched to #{chat_id}!"
        dequeue_and_update(chat_ids)

      # Telegram::Bot::Exceptions::ResponseError
      # Telegram API has returned the error. (ok: "false", error_code: "403",
      # description: "Forbidden: bot was blocked by the user")

      rescue => exception
        EGS::LOG.error exception.message

        if parse(exception)[:error_code] == '403'
          EGS::LOG.info "Invalid user(#{chat_id}). Unsubscribing..."
          EGS::Models::User.unsubscribe chat_id
          dequeue_and_update(chat_ids)
        end
      end
      EGS::LOG.info 'All users have received the current games!'
    end

    def parse(exception)
      message = exception.message.match(/(?<=\().+(?=\))/).to_s
      message
        .split(',')
        .to_h { |k_v_pair| [k_v_pair[/\w+[^:]/], k_v_pair[/(?<=\").+[^"]/]] }
        .transform_keys(&:to_sym)
    end

    def dequeue_and_update(chat_ids)
      chat_ids.pop
      query_release.update(chat_ids_not_served: chat_ids.to_json)
    end

    def wait(date)
      that_much = case date
                  when '5 mins'
                    60 * 5
                  when 'day'
                    60 * 60 * 24
                  when 'next_release'
                    current_games = query_release.free_games
                    time = fetch_time_left(current_games)
                    time.positive? ? time + 30 : 60 * 60 * 5
                  end
      EGS::LOG.info "Sleeping for: #{convert_seconds_to_human_readable(that_much)}..."
      sleep that_much
    end
  end
end
