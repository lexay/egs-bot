class GameDB
  attr_accessor :title, :description, :short_description, :game_uri, :pic_url
  attr_accessor :date_from, :date_upto, :avail

  def initialize(**args)
    %w[
      title
      description
      short_description
      game_uri
      pic_url
      date_from
      date_upto
      avail
    ].each { |m| instance_variable_set('@' << m, args[m.to_sym]) }
  end
end
