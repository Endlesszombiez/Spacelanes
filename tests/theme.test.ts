import { describe, expect, test } from 'bun:test';
import { normalizeTheme, useThemeStore } from '@/stores/useThemeStore';

describe('Spacelanes theme preferences', () => {
  test('uses the new product and theme names in every locale', async () => {
    for (const locale of ['en', 'zh-CN', 'zh-TW', 'ru', 'vi', 'ko', 'tr']) {
      const copy = await Bun.file(`src/i18n/locales/${locale}.json`).json();
      expect(copy.title.login).toBe('Spacelanes Proxy');
      expect(copy.system_info.about_title).toBe('Spacelanes Proxy');
      expect(copy.theme.light).toBe('Paper Red');
      expect(copy.theme.dark).toBe('Mono Slate');
      expect(copy.theme.white).toBeUndefined();
    }
  });

  test('starts in light mode even before browser preferences are read', () => {
    expect(useThemeStore.getInitialState().theme).toBe('light');
    expect(useThemeStore.getInitialState().resolvedTheme).toBe('light');
  });

  test('migrates retired white and unknown preferences to light, preserving dark and auto', () => {
    for (const old of ['white', 'light', null, undefined, 'invalid', {}]) {
      expect(normalizeTheme(old)).toBe('light');
    }
    expect(normalizeTheme('dark')).toBe('dark');
    expect(normalizeTheme('auto')).toBe('auto');
  });

  test('system changes affect auto mode only and the listener is cleaned up', () => {
    const oldWindow = Object.getOwnPropertyDescriptor(globalThis, 'window');
    const oldDocument = Object.getOwnPropertyDescriptor(globalThis, 'document');
    const oldState = useThemeStore.getState();
    let dark = true;
    let applied: string | undefined;
    let listener: (() => void) | undefined;
    const media = {
      get matches() {
        return dark;
      },
      addEventListener: (_: string, callback: () => void) => {
        listener = callback;
      },
      removeEventListener: (_: string, callback: () => void) => {
        expect(callback).toBe(listener);
        listener = undefined;
      },
    };
    Object.defineProperty(globalThis, 'window', {
      configurable: true,
      value: { matchMedia: () => media },
    });
    Object.defineProperty(globalThis, 'document', {
      configurable: true,
      value: {
        documentElement: {
          setAttribute: (_: string, value: string) => {
            applied = value;
          },
          removeAttribute: () => {
            applied = undefined;
          },
        },
      },
    });
    try {
      useThemeStore.getState().setTheme('light');
      const cleanup = useThemeStore.getState().initializeTheme();
      expect(applied).toBeUndefined();
      listener?.();
      expect(useThemeStore.getState().resolvedTheme).toBe('light');
      useThemeStore.getState().setTheme('auto');
      expect(applied).toBe('dark');
      dark = false;
      listener?.();
      expect(useThemeStore.getState().resolvedTheme).toBe('light');
      expect(applied).toBeUndefined();
      useThemeStore.getState().setTheme('dark');
      listener?.();
      expect(applied).toBe('dark');
      cleanup();
      expect(listener).toBeUndefined();
    } finally {
      useThemeStore.setState(oldState);
      for (const [key, descriptor] of [
        ['window', oldWindow],
        ['document', oldDocument],
      ] as const) {
        if (descriptor) Object.defineProperty(globalThis, key, descriptor);
        else Reflect.deleteProperty(globalThis, key);
      }
    }
  });
});
