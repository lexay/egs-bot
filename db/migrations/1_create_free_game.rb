Sequel.migration do
  change do
    create_table(:free_games) do
      primary_key :id
      String :title, :size=>255
      String :full_description, text: true
      String :short_description, :size=>255
      String :pubs_n_devs, :size=>255
      String :game_uri, :size=>255
      DateTime :start_date
      DateTime :end_date
      DateTime :timestamp
    end
  end
end
