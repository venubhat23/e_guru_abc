# Remaining weekly capacity for an offer = capacity_per_week − live reservations that week.
class Assignment
  class CapacityChecker
    def self.week_for(date) = date.to_date.beginning_of_week

    def self.reserved(offer, week_start) = offer.capacity_reservations.where(week_start:).sum(:quantity)

    def self.remaining(offer, date)
      offer.capacity_per_week - reserved(offer, week_for(date))
    end

    def self.available?(offer, date, quantity) = remaining(offer, date) >= quantity
  end
end
