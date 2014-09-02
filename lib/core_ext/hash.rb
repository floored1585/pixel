class Hash

  def symbolize!
    self.keys.each { |key| self[(key.to_sym rescue key) || key] = self.delete(key) }
    return self
  end

end
