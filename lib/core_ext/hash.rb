class Hash

  def symbolize!
    self.keys.each { |key| self[(key.to_sym rescue key) || key] = self.delete(key) }
  end

  def symbolize
    new = self.dup
    new.symbolize!
    return new
  end

end
