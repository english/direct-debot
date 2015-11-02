module GCMe
  module DB
    # Interface to the database
    class Store
      # @param db [Sequel::Database]
      def initialize(db)
        @db = db
      end

      def all_slack_users
        @db.from(:slack_users).all
      end

      def find_slack_user(slack_user_id)
        @db.from(:slack_users).where(slack_user_id: slack_user_id).first
      end

      def create_slack_user!(attrs)
        @db.transaction do
          @db.from(:slack_users).where(slack_user_id: attrs.fetch(:slack_user_id)).delete
          @db.from(:slack_users).insert(attrs)
        end
      end

      def count_slack_users!
        @db.from(:slack_users).count
      end
    end
  end
end
