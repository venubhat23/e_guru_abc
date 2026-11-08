class BookingMailer < ApplicationMailer
  def completed(booking)
    @booking = booking
    invoice = booking.tax_invoice
    attachments["#{invoice.number.tr('/', '-')}.pdf"] = Pdf::InvoicePdf.new(invoice).render if invoice
    attachments["delivery-report-#{booking.number}.csv"] = Reports::DeliveryReport.csv(booking)
    to = ([ booking.created_by ] + booking.company.hr_admins.to_a).compact.map(&:email_address).uniq
    mail to:, subject: "#{booking.number} completed — tax invoice & delivery report"
  end
end
