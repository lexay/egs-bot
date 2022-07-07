module TimeHelper
  def fetch_time_left(games)
    next_date = fetch_next_date(games).to_i
    (next_date - Time.now.to_i).round
  end

  def fetch_next_date(games)
    games.last&.end_date
  end

  def convert_seconds_to_human_readable(time_in_seconds)
    days, hours_in_sec = time_in_seconds.divmod(60 * 60 * 24)
    hours, minutes_in_sec = hours_in_sec.divmod(60 * 60)
    minutes, seconds = minutes_in_sec.divmod(60)
    I18n.t(:time_table, days: days, hours: hours, minutes: minutes, seconds: seconds)[/ [1-9].+/][1..]
  end
end
