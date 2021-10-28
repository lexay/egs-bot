module TimeHelper
  def time_to_next_release
    next_date = EGS::Models::FreeGame.next_date
    return -1 if next_date.nil? 

    (next_date - Time.now).round
  end

  def release_date_ahead?
    time_to_next_release.positive?
  end

  def seconds_to_human_readable(time_in_seconds)
    return 'Неизвестно!' if time_in_seconds.negative?

    EGS::LOG.info time_in_seconds
    days, hours_in_sec = time_in_seconds.divmod(60 * 60 * 24)
    hours, minutes_in_sec = hours_in_sec.divmod(60 * 60)
    minutes, seconds = minutes_in_sec.divmod(60)
    " #{days} дн. : #{hours} ч. : #{minutes} мин. : #{seconds} с."[/ [1-9].+/][1..]
  end
end
