defmodule FieldHub.Billing.InvoicePDF do
  @moduledoc """
  Generates branded PDF invoices using ChromicPDF.
  """

  @doc """
  Generates a PDF for the given invoice.
  Returns {:ok, binary} on success.
  """
  def generate(invoice, org) do
    html = render_invoice_html(invoice, org)

    ChromicPDF.print_to_pdf({:html, html},
      print_to_pdf: %{
        marginTop: 0.5,
        marginBottom: 0.5,
        marginLeft: 0.5,
        marginRight: 0.5,
        printBackground: true
      }
    )
  end

  defp render_invoice_html(invoice, org) do
    logo_url = if org.logo_url, do: org.logo_url, else: "/images/logo.svg"
    primary_color = org.primary_color || "#0d9488"

    """
    <!DOCTYPE html>
    <html lang="en">
    <head>
      <meta charset="UTF-8">
      <meta name="viewport" content="width=device-width, initial-scale=1.0">
      <title>Invoice #{invoice.number}</title>
      <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
          font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
          color: #18181b;
          line-height: 1.5;
          background: white;
          padding: 40px;
        }
        .header {
          display: flex;
          justify-content: space-between;
          align-items: flex-start;
          padding-bottom: 32px;
          border-bottom: 3px solid #{primary_color};
          margin-bottom: 32px;
        }
        .logo { height: 48px; }
        .invoice-title {
          font-size: 32px;
          font-weight: 800;
          color: #{primary_color};
          letter-spacing: -1px;
        }
        .invoice-number {
          font-size: 14px;
          color: #71717a;
          margin-top: 4px;
        }
        .details-grid {
          display: grid;
          grid-template-columns: 1fr 1fr;
          gap: 40px;
          margin-bottom: 40px;
        }
        .detail-section h3 {
          font-size: 10px;
          font-weight: 700;
          text-transform: uppercase;
          letter-spacing: 1px;
          color: #a1a1aa;
          margin-bottom: 8px;
        }
        .detail-section p {
          font-size: 14px;
          color: #3f3f46;
        }
        .detail-section .name {
          font-weight: 700;
          font-size: 16px;
          color: #18181b;
        }
        table {
          width: 100%;
          border-collapse: collapse;
          margin-bottom: 32px;
        }
        th {
          text-align: left;
          font-size: 10px;
          font-weight: 700;
          text-transform: uppercase;
          letter-spacing: 1px;
          color: #a1a1aa;
          padding: 12px 16px;
          background: #f4f4f5;
          border-bottom: 1px solid #e4e4e7;
        }
        td {
          padding: 16px;
          font-size: 14px;
          border-bottom: 1px solid #f4f4f5;
        }
        .amount { text-align: right; font-weight: 600; }
        .totals {
          display: flex;
          justify-content: flex-end;
        }
        .totals-table {
          width: 280px;
        }
        .totals-row {
          display: flex;
          justify-content: space-between;
          padding: 8px 0;
          font-size: 14px;
        }
        .totals-row.final {
          border-top: 2px solid #18181b;
          margin-top: 8px;
          padding-top: 12px;
          font-size: 18px;
          font-weight: 800;
        }
        .totals-row.final .value { color: #{primary_color}; }
        .status-badge {
          display: inline-block;
          padding: 4px 12px;
          border-radius: 6px;
          font-size: 11px;
          font-weight: 700;
          text-transform: uppercase;
        }
        .status-paid { background: #dcfce7; color: #166534; }
        .status-sent { background: #dbeafe; color: #1e40af; }
        .status-draft { background: #f4f4f5; color: #71717a; }
        .status-overdue { background: #fee2e2; color: #b91c1c; }
        .footer {
          margin-top: 48px;
          padding-top: 24px;
          border-top: 1px solid #e4e4e7;
          font-size: 12px;
          color: #71717a;
          text-align: center;
        }
        .notes {
          background: #f4f4f5;
          padding: 16px;
          border-radius: 8px;
          font-size: 13px;
          color: #52525b;
          margin-bottom: 32px;
        }
      </style>
    </head>
    <body>
      <div class="header">
        <div>
          <img src="#{logo_url}" alt="Logo" class="logo" onerror="this.style.display='none'">
          <div class="name" style="font-weight: 800; font-size: 20px; margin-top: 8px;">#{org.name}</div>
        </div>
        <div style="text-align: right;">
          <div class="invoice-title">INVOICE</div>
          <div class="invoice-number">#{invoice.number}</div>
          <div class="status-badge status-#{String.downcase(invoice.status || "draft")}" style="margin-top: 8px;">
            #{String.upcase(invoice.status || "DRAFT")}
          </div>
        </div>
      </div>

      <div class="details-grid">
        <div class="detail-section">
          <h3>Bill To</h3>
          <p class="name">#{invoice.customer && invoice.customer.name || "—"}</p>
          <p>#{invoice.customer && invoice.customer.address_line1 || ""}</p>
          <p>#{invoice.customer && "#{invoice.customer.city}, #{invoice.customer.state} #{invoice.customer.zip}" || ""}</p>
          <p>#{invoice.customer && invoice.customer.email || ""}</p>
        </div>
        <div class="detail-section" style="text-align: right;">
          <h3>Invoice Details</h3>
          <p><strong>Issue Date:</strong> #{format_date(invoice.issue_date)}</p>
          <p><strong>Due Date:</strong> #{format_date(invoice.due_date)}</p>
          #{if invoice.job, do: "<p><strong>Job:</strong> #{invoice.job.number} - #{invoice.job.title}</p>", else: ""}
        </div>
      </div>

      <table>
        <thead>
          <tr>
            <th>Description</th>
            <th>Qty</th>
            <th>Unit Price</th>
            <th class="amount">Amount</th>
          </tr>
        </thead>
        <tbody>
          #{render_labor_row(invoice)}
          #{render_parts_row(invoice)}
          #{render_line_items(invoice.line_items || [])}
        </tbody>
      </table>

      #{if invoice.notes && String.trim(invoice.notes) != "", do: "<div class=\"notes\"><strong>Notes:</strong><br/>#{String.replace(invoice.notes, "\n", "<br/>")}</div>", else: ""}

      <div class="totals">
        <div class="totals-table">
          <div class="totals-row">
            <span>Subtotal</span>
            <span>$#{format_money(invoice.subtotal_amount)}</span>
          </div>
          #{if invoice.discount_amount && Decimal.gt?(invoice.discount_amount, 0), do: "<div class=\"totals-row\"><span>Discount</span><span>-$#{format_money(invoice.discount_amount)}</span></div>", else: ""}
          <div class="totals-row">
            <span>Tax (#{format_money(invoice.tax_rate)}%)</span>
            <span>$#{format_money(invoice.tax_amount)}</span>
          </div>
          <div class="totals-row final">
            <span>Total Due</span>
            <span class="value">$#{format_money(invoice.total_amount)}</span>
          </div>
        </div>
      </div>

      <div class="footer">
        <p>Thank you for your business!</p>
        <p style="margin-top: 8px;">#{org.name} • #{org.email || ""} • #{org.phone || ""}</p>
      </div>
    </body>
    </html>
    """
  end

  defp render_labor_row(invoice) do
    if invoice.labor_hours && Decimal.gt?(invoice.labor_hours, 0) do
      """
      <tr>
        <td>Labor</td>
        <td>#{format_money(invoice.labor_hours)} hrs</td>
        <td>$#{format_money(invoice.labor_rate)}/hr</td>
        <td class="amount">$#{format_money(invoice.labor_amount)}</td>
      </tr>
      """
    else
      ""
    end
  end

  defp render_parts_row(invoice) do
    if invoice.parts_amount && Decimal.gt?(invoice.parts_amount, 0) do
      """
      <tr>
        <td>Parts & Materials</td>
        <td>—</td>
        <td>—</td>
        <td class="amount">$#{format_money(invoice.parts_amount)}</td>
      </tr>
      """
    else
      ""
    end
  end

  defp render_line_items(line_items) do
    Enum.map(line_items, fn item ->
      """
      <tr>
        <td>#{item.description}</td>
        <td>#{item.quantity}</td>
        <td>$#{format_money(item.unit_price)}</td>
        <td class="amount">$#{format_money(item.total_amount)}</td>
      </tr>
      """
    end)
    |> Enum.join("")
  end

  defp format_date(nil), do: "—"
  defp format_date(date), do: Calendar.strftime(date, "%B %d, %Y")

  defp format_money(nil), do: "0.00"
  defp format_money(%Decimal{} = amount), do: Decimal.to_string(Decimal.round(amount, 2), :normal)
  defp format_money(amount) when is_number(amount), do: :erlang.float_to_binary(amount / 1, decimals: 2)
  defp format_money(_), do: "0.00"
end
