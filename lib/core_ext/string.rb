class String

  def is_i?
    !!(self =~ /^[\d]+$/)
  end

  def to_i_if_numeric
    self.is_i? ? self.to_i : self
  end

end
