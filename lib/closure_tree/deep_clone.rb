module ClosureTree
  module DeepClone
    extend ActiveSupport::Concern

    # Returns a persisted dup of self that has a dup of all descendant nodes.
    # The dup's parent is set to the current parent.
    # Use dup_options if you're using https://github.com/moiristo/deep_cloneable
    def deep_dup(dup_options = nil)
      duplicate = _ct.duplicate(self, dup_options)
      duplicate.save!
      children.each do |ea|
        dolly.children << ea.deep_dup(dup_options)
      end
      dolly
    end
  end
end

