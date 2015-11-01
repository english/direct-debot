module DB
  # Interface to the database
  class Store
    # @param db [Sequel::Database]
    def initialize(db)
      @db = db
    end

    def create_slack_user!(attrs)
      @db.from(:slack_users).insert(attrs)
    end

    def count_slack_users!
      @db.from(:slack_users).count
    end
  end
end
