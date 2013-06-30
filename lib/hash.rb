class Hash
  #take keys of hash and transform those to a symbols
  def self.transform_keys_to_string(value)
    return value if not value.is_a?(Hash)
    hash = value.inject({}){|memo,(k,v)| memo[k.to_s] = Hash.transform_keys_to_string(v); memo}
    return hash
  end
  def transform_keys_to_string
    self.inject({}){|memo,(k,v)| memo[k.to_s] = Hash.transform_keys_to_string(v); memo}
  end
end