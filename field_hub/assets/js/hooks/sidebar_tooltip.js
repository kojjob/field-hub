import { computePosition, autoUpdate, flip, shift, offset, arrow } from '@floating-ui/dom';

export default {
  mounted() {
    this.tooltip = null;
    this.cleanup = null;
    this.initTooltip();
  },

  updated() {
    // Re-initialize if content/label changes
    this.destroyTooltip();
    this.initTooltip();
  },

  destroyed() {
    this.destroyTooltip();
  },

  initTooltip() {
    const label = this.el.dataset.tooltip;
    if (!label) return;

    this.el.addEventListener('mouseenter', this.showTooltip.bind(this));
    this.el.addEventListener('mouseleave', this.hideTooltip.bind(this));
    this.el.addEventListener('focus', this.showTooltip.bind(this));
    this.el.addEventListener('blur', this.hideTooltip.bind(this));
  },

  showTooltip() {
    const label = this.el.dataset.tooltip;
    if (!label) return;

    // Create tooltip element
    this.tooltip = document.createElement('div');
    this.tooltip.textContent = label;
    this.tooltip.className = 'absolute z-[60] px-2 py-1 text-sm font-medium text-white bg-indigo-900 rounded shadow-sm opacity-0 transition-opacity duration-200 pointer-events-none whitespace-nowrap';
    document.body.appendChild(this.tooltip);

    // Compute position
    this.cleanup = autoUpdate(this.el, this.tooltip, () => {
      computePosition(this.el, this.tooltip, {
        placement: 'right',
        middleware: [
          offset(10),
          flip(),
          shift({ padding: 5 })
        ],
      }).then(({ x, y }) => {
        Object.assign(this.tooltip.style, {
          left: `${x}px`,
          top: `${y}px`,
          opacity: '1',
        });
      });
    });
  },

  hideTooltip() {
    if (this.cleanup) {
      this.cleanup();
      this.cleanup = null;
    }
    if (this.tooltip) {
      this.tooltip.remove();
      this.tooltip = null;
    }
  },
  
  destroyTooltip() {
    this.hideTooltip();
    this.el.removeEventListener('mouseenter', this.showTooltip);
    this.el.removeEventListener('mouseleave', this.hideTooltip);
    this.el.removeEventListener('focus', this.showTooltip);
    this.el.removeEventListener('blur', this.hideTooltip);
  }
};
