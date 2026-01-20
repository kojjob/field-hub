// Print Invoice Hook
// Triggers browser print dialog for invoice PDF generation

const PrintInvoice = {
  mounted() {
    this.handleEvent("print_invoice", () => {
      // Add print styles
      document.body.classList.add("printing");
      
      // Trigger browser print after a brief delay for rendering
      setTimeout(() => {
        window.print();
        document.body.classList.remove("printing");
      }, 300);
    });
  }
};

export default PrintInvoice;
