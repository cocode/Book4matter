// Use the original landmarks so chapter anchors and authored site links stay intact.
(() => {
  const toolbar = document.createElement('div');
  toolbar.className = 'book-navigation';
  const menus = [];

  function addMenu(panel, label, hamburger = false) {
    if (!panel) return;
    const marker = document.createComment(label);
    panel.before(marker);
    if (!panel.id) {
      let id = 'book-site-navigation';
      while (document.getElementById(id)) id += '-menu';
      panel.id = id;
    }

    const button = document.createElement('button');
    button.type = 'button';
    button.textContent = label;
    if (hamburger) {
      const icon = document.createElement('span');
      icon.setAttribute('aria-hidden', 'true');
      icon.textContent = '☰ ';
      button.prepend(icon);
    }
    button.setAttribute('aria-controls', panel.id);
    button.addEventListener('click', () => {
      const opening = panel.hidden;
      closeMenus();
      if (opening) {
        panel.hidden = false;
        button.setAttribute('aria-expanded', 'true');
      }
    });
    menus.push({ panel, button, marker });
  }

  function closeMenus() {
    for (const { panel, button } of menus) {
      panel.hidden = true;
      button.setAttribute('aria-expanded', 'false');
    }
  }

  addMenu(document.querySelector('nav.site-nav'), 'Menu', true);
  addMenu(document.querySelector('nav#TOC'), 'Contents');
  if (!menus.length) return;

  toolbar.addEventListener('keydown', event => {
    const open = menus.find(menu => !menu.panel.hidden);
    if (event.key === 'Escape' && open) {
      closeMenus();
      open.button.focus();
    }
  });
  toolbar.addEventListener('click', event => {
    if (event.target.closest('a[href]')) closeMenus();
  });

  const narrow = window.matchMedia('screen and (max-width: 900px)');
  function updateLayout() {
    if (narrow.matches) {
      closeMenus();
      for (const { panel, button } of menus) toolbar.append(button, panel);
      document.body.prepend(toolbar);
    } else if (toolbar.isConnected) {
      for (const { panel, marker } of menus) {
        marker.after(panel);
        panel.hidden = false;
      }
      toolbar.remove();
    }
  }
  narrow.addEventListener('change', updateLayout);
  updateLayout();
})();
