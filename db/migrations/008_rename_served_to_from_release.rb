Sequel.migration do
  change do
    alter_table :releases do
      rename_column :served_to, :chat_ids_not_served
    end
  end
end
