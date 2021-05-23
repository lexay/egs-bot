class FreeGame
  attr_accessor :id, :title, :full_description, :short_description, :game_uri,
                :start_date, :end_date, :pubs_n_devs, :timestamp

  def initialize(**params)
    %w[
      id
      title
      full_description
      short_description
      game_uri
      start_date
      end_date
      pubs_n_devs
      timestamp
    ].each do |m|
      instance_variable_set('@' << m, params[m.to_sym])
    end
  end
end
