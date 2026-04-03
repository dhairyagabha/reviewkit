# frozen_string_literal: true

# Dummy-app request specs use a top-level Current separate from Reviewkit::Current.
class Current < ActiveSupport::CurrentAttributes
  attribute :reviewer
end
