class Block
  extend ElMixin
  def self.value
    res = []
    with(:save_excursion) do
      found = re_search_backward "^ *$", nil, 1
      if found
        end_of_line
        forward_char
      end
      res << point
      re_search_forward "^ *$", nil, 1
      beginning_of_line
      res << point
    end
  end

  def self.do_as_wrap
    if Keys.prefix_u?
      Line.to_left
      View.insert "> "
      fill_paragraph nil
      txt = Clipboard.paragraph(:delete => true)
      View.insert txt.gsub(/^  /, '> ')
      return
    end
    fill_paragraph nil
  end
end
