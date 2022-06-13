module GameHelper
  def latest_release
    EGS::Models::Release.last || EGS::Models::Release.init
  end

  def latest_games
    latest_release.free_games
  end

  def formatted_latest_games
    games = latest_games
    games.empty? ? I18n.t(:release_unknown) : EGS::Template.new(games)
  end
end
