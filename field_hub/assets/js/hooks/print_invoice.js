// Print Invoice Hook
// Triggers browser print dialog and handles PDF file downloads

const PrintInvoice = {
  mounted() {
    // Handle print event (legacy fallback)
    this.handleEvent("print_invoice", () => {
      // Add print styles
      document.body.classList.add("printing");
      
      // Trigger browser print after a brief delay for rendering
      setTimeout(() => {
        window.print();
        document.body.classList.remove("printing");
      }, 300);
    });

    // Handle PDF download event
    this.handleEvent("download_file", ({ data, filename, content_type }) => {
      try {
        // Decode base64 data
        const binaryString = atob(data);
        const bytes = new Uint8Array(binaryString.length);
        for (let i = 0; i < binaryString.length; i++) {
          bytes[i] = binaryString.charCodeAt(i);
        }
        
        // Create blob and download
        const blob = new Blob([bytes], { type: content_type });
        const url = window.URL.createObjectURL(blob);
        const link = document.createElement("a");
        link.href = url;
        link.download = filename;
        document.body.appendChild(link);
        link.click();
        document.body.removeChild(link);
        window.URL.revokeObjectURL(url);
      } catch (error) {
        console.error("Error downloading file:", error);
      }
    });
  }
};

export default PrintInvoice;
