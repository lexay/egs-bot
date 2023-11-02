module TimeHelper
  def convert_to_human_readable(time_in_seconds)
    days, hours_in_sec = time_in_seconds.divmod(24 * 60 * 60)
    hours, minutes_in_sec = hours_in_sec.divmod(60 * 60)
    minutes, seconds = minutes_in_sec.divmod(60)
    { days:, hours:, minutes:, seconds: }
  end
end
