class Company < ActiveRecord::Base
    belongs_to :user

    validates :name, presence: true, uniqueness: true, length: { in: 3..40 }

end
