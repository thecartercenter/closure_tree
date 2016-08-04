module ClosureTree
  module HashTreeSupport
    def default_tree_scope(limit_depth = nil)
        # Deepest generation, within limit, for each descendant
        # NOTE: Postgres requires HAVING clauses to always contains aggregate functions (!!)
        having_clause = limit_depth ? "HAVING MAX(generations) <= #{limit_depth - 1}" : ''
        add_depth_order(model_class, having_clause)
      end

    def hash_tree(tree_scope, limit_depth = nil)
      limited_scope = if tree_scope
        tree_scope = tree_scope.where("#{quoted_hierarchy_table_name}.generations <= #{limit_depth - 1}") if limit_depth
        add_depth_order(tree_scope)
      else
        default_tree_scope(limit_depth)
      end
      build_hash_tree(limited_scope)
    end

    def add_depth_order(scope, having_clause = '')
      generation_depth = <<-SQL.strip_heredoc
        INNER JOIN (
          SELECT descendant_id, MAX(generations) as depth
          FROM #{quoted_hierarchy_table_name}
          GROUP BY descendant_id
          #{having_clause}
        ) AS generation_depth
          ON #{quoted_table_name}.#{model_class.primary_key} = generation_depth.descendant_id
      SQL
      scope_with_order(scope.joins(generation_depth), 'generation_depth.depth')
    end

    # Builds nested hash structure using the scope returned from the passed in scope
    def build_hash_tree(tree_scope)
      tree = ActiveSupport::OrderedHash.new
      id_to_hash = {}

      tree_scope.each do |ea|
        h = id_to_hash[ea.id] = ActiveSupport::OrderedHash.new
        (id_to_hash[ea._ct_parent_id] || tree)[ea] = h
      end
      tree
    end
  end
end