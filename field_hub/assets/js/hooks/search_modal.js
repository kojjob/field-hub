/**
 * SearchModal Hook
 * Global search with Cmd+K keyboard shortcut
 */
const SearchModal = {
  mounted() {
    this.modal = this.el;
    this.backdrop = this.el.querySelector('[data-backdrop]');
    this.panel = this.el.querySelector('[data-panel]');
    this.input = this.el.querySelector('[data-input]');
    this.resultsContainer = this.el.querySelector('[data-results]');
    this.loadingEl = this.el.querySelector('[data-loading]');
    this.emptyEl = this.el.querySelector('[data-empty]');
    this.noResultsEl = this.el.querySelector('[data-no-results]');
    
    this.selectedIndex = -1;
    this.results = [];
    this.debounceTimer = null;

    // Keyboard shortcut listener (Cmd+K / Ctrl+K)
    this.keydownHandler = (e) => {
      if ((e.metaKey || e.ctrlKey) && e.key === 'k') {
        e.preventDefault();
        this.toggle();
      }
      if (e.key === 'Escape' && this.isOpen()) {
        this.close();
      }
    };
    document.addEventListener('keydown', this.keydownHandler);

    // Close on backdrop click
    this.backdrop.addEventListener('click', () => this.close());

    // Input handling
    this.input.addEventListener('input', (e) => this.handleInput(e.target.value));
    this.input.addEventListener('keydown', (e) => this.handleInputKeydown(e));

    // Connect search bar in sidebar to this modal
    const searchTrigger = document.querySelector('#search-field');
    if (searchTrigger) {
      searchTrigger.addEventListener('focus', (e) => {
        e.preventDefault();
        searchTrigger.blur();
        this.open();
      });
    }
  },

  destroyed() {
    document.removeEventListener('keydown', this.keydownHandler);
  },

  isOpen() {
    return !this.modal.classList.contains('hidden');
  },

  open() {
    this.modal.classList.remove('hidden');
    this.input.value = '';
    this.input.focus();
    this.resetResults();
    document.body.style.overflow = 'hidden';
  },

  close() {
    this.modal.classList.add('hidden');
    this.input.value = '';
    this.resetResults();
    document.body.style.overflow = '';
  },

  toggle() {
    if (this.isOpen()) {
      this.close();
    } else {
      this.open();
    }
  },

  resetResults() {
    this.results = [];
    this.selectedIndex = -1;
    this.showState('empty');
    // Remove any dynamic results
    const dynamicResults = this.resultsContainer.querySelectorAll('[data-result]');
    dynamicResults.forEach(el => el.remove());
  },

  showState(state) {
    this.loadingEl.classList.add('hidden');
    this.emptyEl.classList.add('hidden');
    this.noResultsEl.classList.add('hidden');

    if (state === 'loading') this.loadingEl.classList.remove('hidden');
    if (state === 'empty') this.emptyEl.classList.remove('hidden');
    if (state === 'no-results') this.noResultsEl.classList.remove('hidden');
  },

  hideAllStates() {
    this.loadingEl.classList.add('hidden');
    this.emptyEl.classList.add('hidden');
    this.noResultsEl.classList.add('hidden');
  },

  handleInput(query) {
    clearTimeout(this.debounceTimer);

    if (query.length < 2) {
      this.resetResults();
      return;
    }

    this.showState('loading');

    this.debounceTimer = setTimeout(() => {
      this.search(query);
    }, 200);
  },

  async search(query) {
    try {
      const response = await fetch(`/api/search?q=${encodeURIComponent(query)}`, {
        headers: { 'Accept': 'application/json' }
      });
      const data = await response.json();

      if (data.success && data.results) {
        this.renderResults(data.results);
      } else {
        this.showState('no-results');
      }
    } catch (error) {
      console.error('Search error:', error);
      this.showState('no-results');
    }
  },

  renderResults(results) {
    // Remove old results
    const oldResults = this.resultsContainer.querySelectorAll('[data-result]');
    oldResults.forEach(el => el.remove());

    const allItems = [
      ...results.jobs,
      ...results.customers,
      ...results.invoices
    ];

    if (allItems.length === 0) {
      this.showState('no-results');
      return;
    }

    this.hideAllStates();
    this.results = allItems;
    this.selectedIndex = 0;

    // Group by type
    const groups = {
      job: { label: 'Jobs', icon: 'briefcase', items: results.jobs },
      customer: { label: 'Customers', icon: 'users', items: results.customers },
      invoice: { label: 'Invoices', icon: 'banknotes', items: results.invoices }
    };

    Object.entries(groups).forEach(([type, group]) => {
      if (group.items.length === 0) return;

      // Group header
      const header = document.createElement('div');
      header.className = 'px-2 py-1 text-xs font-semibold text-zinc-400 uppercase tracking-wider';
      header.textContent = group.label;
      header.setAttribute('data-result', 'header');
      this.resultsContainer.appendChild(header);

      // Items
      group.items.forEach((item, idx) => {
        const el = this.createResultItem(item, idx);
        this.resultsContainer.appendChild(el);
      });
    });

    this.updateSelection();
  },

  createResultItem(item, index) {
    const el = document.createElement('a');
    el.href = item.url;
    el.setAttribute('data-result', 'item');
    el.setAttribute('data-index', index);
    el.className = 'flex items-center gap-3 px-3 py-2 rounded-lg cursor-pointer transition-colors hover:bg-zinc-100 dark:hover:bg-zinc-800';

    const iconMap = {
      job: 'hero-briefcase',
      customer: 'hero-users',
      invoice: 'hero-banknotes'
    };

    const statusColors = {
      scheduled: 'bg-blue-100 text-blue-700',
      in_progress: 'bg-amber-100 text-amber-700',
      completed: 'bg-green-100 text-green-700',
      draft: 'bg-zinc-100 text-zinc-600',
      sent: 'bg-blue-100 text-blue-700',
      paid: 'bg-green-100 text-green-700'
    };

    el.innerHTML = `
      <div class="w-8 h-8 rounded-lg bg-teal-50 dark:bg-teal-500/10 flex items-center justify-center shrink-0">
        <svg class="w-4 h-4 text-teal-600 dark:text-teal-400" fill="none" stroke="currentColor" viewBox="0 0 24 24">
          ${this.getIconPath(item.type)}
        </svg>
      </div>
      <div class="flex-1 min-w-0">
        <div class="text-sm font-medium text-zinc-900 dark:text-zinc-100 truncate">${item.title}</div>
        ${item.subtitle ? `<div class="text-xs text-zinc-500 truncate">${item.subtitle}</div>` : ''}
      </div>
      ${item.status ? `<span class="text-xs px-2 py-0.5 rounded-full ${statusColors[item.status] || 'bg-zinc-100 text-zinc-600'}">${item.status}</span>` : ''}
    `;

    el.addEventListener('click', (e) => {
      // Let default navigation happen
      this.close();
    });

    return el;
  },

  getIconPath(type) {
    const paths = {
      job: '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M21 13.255A23.931 23.931 0 0112 15c-3.183 0-6.22-.62-9-1.745M16 6V4a2 2 0 00-2-2h-4a2 2 0 00-2 2v2m4 6h.01M5 20h14a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />',
      customer: '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />',
      invoice: '<path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M2.25 18.75a60.07 60.07 0 0115.797 2.101c.727.198 1.453-.342 1.453-1.096V18.75M3.75 4.5v.75A.75.75 0 013 6h-.75m0 0v-.375c0-.621.504-1.125 1.125-1.125H20.25M2.25 6v9m18-10.5v.75c0 .414.336.75.75.75h.75m-1.5-1.5h.375c.621 0 1.125.504 1.125 1.125v9.75c0 .621-.504 1.125-1.125 1.125h-.375m1.5-1.5H21a.75.75 0 00-.75.75v.75m0 0H3.75m0 0h-.375a1.125 1.125 0 01-1.125-1.125V15m1.5 1.5v-.75A.75.75 0 003 15h-.75M15 10.5a3 3 0 11-6 0 3 3 0 016 0zm3 0h.008v.008H18V10.5zm-12 0h.008v.008H6V10.5z" />'
    };
    return paths[type] || paths.job;
  },

  handleInputKeydown(e) {
    const items = this.resultsContainer.querySelectorAll('[data-result="item"]');
    
    if (e.key === 'ArrowDown') {
      e.preventDefault();
      this.selectedIndex = Math.min(this.selectedIndex + 1, items.length - 1);
      this.updateSelection();
    } else if (e.key === 'ArrowUp') {
      e.preventDefault();
      this.selectedIndex = Math.max(this.selectedIndex - 1, 0);
      this.updateSelection();
    } else if (e.key === 'Enter' && this.selectedIndex >= 0) {
      e.preventDefault();
      const selected = items[this.selectedIndex];
      if (selected) {
        window.location.href = selected.href;
        this.close();
      }
    }
  },

  updateSelection() {
    const items = this.resultsContainer.querySelectorAll('[data-result="item"]');
    items.forEach((el, idx) => {
      if (idx === this.selectedIndex) {
        el.classList.add('bg-zinc-100', 'dark:bg-zinc-800');
        el.scrollIntoView({ block: 'nearest' });
      } else {
        el.classList.remove('bg-zinc-100', 'dark:bg-zinc-800');
      }
    });
  }
};

export default SearchModal;
