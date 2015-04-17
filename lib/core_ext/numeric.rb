class Numeric

  def sigfig(figs)
    num = Float("%.#{figs}g" % self)
    str = num.to_s.gsub(/\.[0]+$/,'')
    return str.to_f if str['.']
    return str.to_i
  end

end
