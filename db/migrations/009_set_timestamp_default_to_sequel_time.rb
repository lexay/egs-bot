Sequel.migration do
  change do
    %i[free_games users releases].each do |t|
      alter_table t do
        set_column_default :timestamp, Sequel::CURRENT_TIMESTAMP
      end
    end
  end
end
