module TimeHelper
  def time_to_next_release
    EGS::Models::FreeGame.next_date - Time.now
  rescue NoMethodError
    -1
  end

  def release_date_ahead?
    time_to_next_release.positive?
  end
end
