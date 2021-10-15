Sequel.migration do
  change do
    create_table(:releases) do
      primary_key :id
      String :served_to, text: true, default: ''
      DateTime :timestamp
    end
  end
end
