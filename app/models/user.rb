class User < ApplicationRecord
    has_many :microposts, dependent: :destroy
    attr_accessor :remember_token, :activation_token, :reset_token
    before_save :downcase_email
    before_create :create_activation_digest

    #before_save { email.downcase! }
    validates :name, presence: true, length: { maximum: 50 }
    VALID_EMAIL_REGEX = /\A[\w+\-.]+@[a-z\d\-]+(\.[a-z\d\-]+)*\.[a-z]+\z/i
    validates :email, presence: true, length: { maximum: 255 },
                    format: {with: VALID_EMAIL_REGEX},
                    uniqueness: true

    has_secure_password
    validates :password, presence: true, length: { minimum: 6 }, allow_nil: true
    
    
    # returns the hash digest of the given string
    def User.digest(string)
        cost = ActiveModel::SecurePassword.min_cost ? BCrypt::Engine::MIN_COST :
                                                      BCrypt::Engine.cost
        BCrypt::Password.create(string, cost: cost)
    end

    # returns a random token
    def User.new_token
        SecureRandom.urlsafe_base64
    end
   

    def remember
        self.remember_token = User.new_token
        update_attribute(:remember_digest, User.digest(remember_token))
        remember_digest
    end

    def authenticated?(attribute, token)
        digest = send("#{attribute}_digest") # attribute = activation or remember
        return false if digest.nil?
        BCrypt::Password.new(digest).is_password?(token)
    end

    # forgets a user
    def forget
        update_attribute(:remember_digest, nil)
    end

    # returns a session token to prevent session hijacking
    # we reuse the remember digest for convenience
    def session_token
        remember_digest || remember
    end

    # activates an account
    def activate
        update_columns(activated: true, activated_at: Time.zone.now)
    end

    # sends activation email
    def send_activation_email
        UserMailer.account_activation(self).deliver_now
    end

    # sets the password reset attributes
    def create_reset_digest
        self.reset_token = User.new_token
        update_columns(reset_digest:  User.digest(reset_token), reset_sent_at: Time.zone.now)
    end

    # sends password reset email
    def send_password_reset_email
        UserMailer.password_reset(self).deliver_now
    end

    # returns true if password reset has expired
    def password_reset_expired?
        reset_sent_at < 2.hours.ago # password reset sent earlier than two hours ago ?
    end

    private

        # converts email to all lowercase
        def downcase_email
            email.downcase!
        end

        # creates and assigns the activation token and digest
        def create_activation_digest
            self.activation_token = User.new_token
            self.activation_digest = User.digest(activation_token)
        end
    

end
