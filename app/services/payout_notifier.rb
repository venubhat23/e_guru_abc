class PayoutNotifier
  def self.call(payout)
    amount = Inr.format(payout.amount_paise)
    case payout.status
    when "due" then Notifier.notify(Notifier.finance, kind: "payout", title: "#{payout.kind.capitalize} payout due: #{amount}", body: payout.vendor.name, url: "/admin/payouts")
    when "paid" then Notifier.notify(payout.vendor.users.active, kind: "payout", title: "#{payout.kind.capitalize} payout of #{amount} sent", body: "UTR #{payout.utr}", url: "/vendor", email: true)
    when "received" then Notifier.notify(Notifier.finance, kind: "payout", title: "#{payout.vendor.name} confirmed receipt of #{amount}", url: "/admin/payouts")
    end
  end
end
