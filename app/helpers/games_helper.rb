module GamesHelper
  class ::Integer
    def to_card_number = Games::Card.new(id: self).numbers
  end

  def shorten_uuid(uuid)
    Digest::MD5.hexdigest(uuid).to_i(16).modulo(9999).to_s.rjust(4, '0').prepend('#')
  end
end
