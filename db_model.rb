class FreeGame
  attr_accessor :title, :full_description, :short_description, :game_uri,
                :start_date, :end_date, :pubs_n_devs, :price, :hardware,
                :videos, :languages, :rating, :available

  def initialize(**args)
    %w[ title full_description short_description game_uri start_date end_date
        pubs_n_devs price hardware videos languages rating available].each do |m|
          instance_variable_set('@' << m, args[m.to_sym])
        end
  end
end
