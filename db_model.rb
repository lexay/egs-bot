class FreeGame
  attr_accessor :id, :title, :full_description, :short_description, :game_uri,
                :start_date, :end_date, :pubs_n_devs, :price, :hardware,
                :videos, :languages, :rating, :available, :timestamp

  def initialize(**args)
    %w[
      id
      title
      full_description
      short_description
      game_uri
      start_date
      end_date
      pubs_n_devs
      price
      hardware
      videos
      languages
      rating
      available
      timestamp
    ].each do |m|
      instance_variable_set('@' << m, args[m.to_sym])
    end
  end
end
