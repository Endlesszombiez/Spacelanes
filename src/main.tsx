import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import '@/styles/global.scss';
import { APP_NAME, getBrandLogo } from '@/assets/branding';
import { useThemeStore } from '@/stores/useThemeStore';
import App from './App.tsx';

// Apply the saved palette before the first React render.
const themeStore = useThemeStore.getState();
themeStore.setTheme(themeStore.theme);

document.title = APP_NAME;
document.documentElement.setAttribute('translate', 'no');
document.documentElement.classList.add('notranslate');

const updateFavicon = () => {
  const faviconEl = document.querySelector<HTMLLinkElement>('link[rel="icon"]');
  if (faviconEl) {
    faviconEl.href = getBrandLogo(useThemeStore.getState().resolvedTheme);
    faviconEl.type = 'image/svg+xml';
  } else {
    const newFavicon = document.createElement('link');
    newFavicon.rel = 'icon';
    newFavicon.type = 'image/svg+xml';
    newFavicon.href = getBrandLogo(useThemeStore.getState().resolvedTheme);
    document.head.appendChild(newFavicon);
  }
};
updateFavicon();
useThemeStore.subscribe((state, previous) => {
  if (state.resolvedTheme !== previous.resolvedTheme) updateFavicon();
});

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <App />
  </StrictMode>
);
