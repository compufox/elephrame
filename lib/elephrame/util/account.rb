module Mastodon
  class Account
    NoBotRegex = /#?NoBot/i
    
    ##
    # Checks to see if a user has some form of "#NoBot" in their bio or in
    # their profile fields (so we can make making friendly bots easier!)
    #
    # @return [Bool]
    
    def no_bot?
      note =~ NoBotRegex ||
        fields.any? {|f| f.name =~ NoBotRegex || f.value =~ NoBotRegex}
    end
  end
end
