module ActiveRecord
  module ConnectionAdapters
    module CockroachDB
      module SchemaStatements
        include ActiveRecord::ConnectionAdapters::PostgreSQL::SchemaStatements

        DEFAULT_PRIMARY_KEY = "rowid"

        def add_index(table_name, column_name, options = {})
          super
        rescue ActiveRecord::StatementInvalid => error
          if debugging? && error.cause.class == PG::FeatureNotSupported
            warn "#{error}\n\nThis error will be ignored and the index will not be created.\n\n"
          else
            raise error
          end
        end

        # ActiveRecord allows for tables to exist without primary keys.
        # Databases like PostgreSQL support this behavior, but CockroachDB does
        # not. If a table is created without a primary key, CockroachDB will add
        # a rowid column to serve as its primary key. This breaks a lot of
        # ActiveRecord's assumptions so we'll treat tables with rowid primary
        # keys as if they didn't have primary keys at all.
        # https://www.cockroachlabs.com/docs/v19.2/create-table.html#create-a-table
        # https://api.rubyonrails.org/v5.2.4/classes/ActiveRecord/ConnectionAdapters/SchemaStatements.html#method-i-create_table
        def primary_key(table_name)
          pk = super

          if pk == DEFAULT_PRIMARY_KEY
            nil
          else
            pk
          end
        end

        # CockroachDB uses unique_rowid() for primary keys, not sequences. It's
        # possible to force a table to use sequences, but since it's not the
        # default behavior we'll always return nil for default_sequence_name.
        def default_sequence_name(table_name, pk = "id")
          nil
        end
      end
    end
  end
end
