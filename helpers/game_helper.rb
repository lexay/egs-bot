module GameHelper
  def query_release
    EGS::Models::Release.last || EGS::Models::Release.new
  end

  def format(games)
    games.empty? ? I18n.t(:release_unknown) : EGS::Template.new(games)
  end
end
