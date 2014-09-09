class Object

  def to_i_if_numeric
    # This is sort of a hack, but gets shit converted to int
    begin
      ('%.0f' % self.to_s).to_i
    rescue ArgumentError, TypeError
      self
    end
  end

end
