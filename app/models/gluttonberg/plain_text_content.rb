module Gluttonberg
  class PlainTextContent  < ActiveRecord::Base
    self.table_name = "gb_plain_text_contents"

    attr_accessible :text

    include Content::Block

    is_localized do
      attr_accessible :text
    end

  end
end