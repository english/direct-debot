# frozen_string_literal: true

Sequel.migration do
  change do
    alter_table :users do
      add_column :organisation_id, String
      set_column_not_null :organisation_id
    end
  end
end
