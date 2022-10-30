Sequel.migration do
  change do
    create_table(:free_games) do
      primary_key :id
      String :title, :size=>255
      String :description, text: true
      String :pubs_n_devs, :size=>255
      String :game_uri, :size=>255
      DateTime :start_date
      DateTime :end_date
      DateTime :timestamp, default: Sequel::CURRENT_TIMESTAMP
      foreign_key :release_id, :releases
    end
  end
end
