module TimeHelper
  def convert_to_human_readable(time_in_seconds)
    days, hours_in_sec = time_in_seconds.divmod(24 * 60 * 60)
    hours, minutes_in_sec = hours_in_sec.divmod(60 * 60)
    minutes, seconds = minutes_in_sec.divmod(60)
    I18n.t(:time_table, days:, hours:, minutes:, seconds:)[/ [1-9].+/][1..]
  end
end
